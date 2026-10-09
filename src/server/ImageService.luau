-- Fetches decoded image pixels from the API so clients can draw them with EditableImage.
local ApiClient = require(script.Parent.ApiClient)
local CatalogService = require(script.Parent.CatalogService)

local MAX_CONCURRENT = 4
local CACHE_LIMIT = 160
local FAIL_TTL = 60
local RATE_WINDOW = 10
local RATE_LIMIT = 60

local ImageService = {}

local cache = {}
local order = {}
local failed = {}
local inflight = {}
local active = 0
local waiting = {}
local usage = {}

local function remember(key, entry)
	cache[key] = entry
	table.insert(order, key)
	if #order > CACHE_LIMIT then
		cache[table.remove(order, 1)] = nil
	end
end

local function acquire()
	if active >= MAX_CONCURRENT then
		table.insert(waiting, coroutine.running())
		coroutine.yield()
	else
		active += 1
	end
end

local function release()
	local nextThread = table.remove(waiting, 1)
	if nextThread then
		task.spawn(nextThread)
	else
		active -= 1
	end
end

local function allowed(player: Player)
	local now = os.clock()
	local record = usage[player]
	if not record or now - record.start > RATE_WINDOW then
		record = { start = now, count = 0 }
		usage[player] = record
	end
	record.count += 1
	return record.count <= RATE_LIMIT
end

-- Only images that belong to the configured store's catalog are ever requested.
local function exists(kind: string, id: string?)
	local catalog = CatalogService.get()
	local store = catalog and catalog.store
	if not store then
		return false
	end
	if kind == "logo" then
		return store.logoUrl ~= nil
	end
	if kind == "banner" then
		return store.bannerUrl ~= nil
	end
	if kind ~= "product" or type(id) ~= "string" then
		return false
	end
	for _, product in store.products do
		if product.id == id then
			return product.hasImage == true
		end
	end
	return false
end

function ImageService.get(player: Player, kind: any, id: any)
	if type(kind) ~= "string" or (id ~= nil and (type(id) ~= "string" or #id > 60)) then
		return nil
	end
	if not allowed(player) or not exists(kind, id) then
		return nil
	end

	local key = `{kind}:{id or ""}`
	local hit = cache[key]
	if hit then
		return hit.pixels, hit.width, hit.height
	end
	if failed[key] and os.clock() - failed[key] < FAIL_TTL then
		return nil
	end

	if inflight[key] then
		table.insert(inflight[key], coroutine.running())
		coroutine.yield()
		local entry = cache[key]
		if entry then
			return entry.pixels, entry.width, entry.height
		end
		return nil
	end

	inflight[key] = {}
	acquire()
	local pixels, width, height = ApiClient.getImage(kind, id)
	release()
	if pixels then
		remember(key, { pixels = pixels, width = width, height = height })
	else
		failed[key] = os.clock()
	end
	local waiters = inflight[key]
	inflight[key] = nil
	for _, thread in waiters do
		task.spawn(thread)
	end
	return pixels, width, height
end

function ImageService.start()
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		usage[player] = nil
	end)
end

return ImageService

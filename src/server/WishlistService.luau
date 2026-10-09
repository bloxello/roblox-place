local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local Config = require(script.Parent.Config)

local MAX_ITEMS = 200
local SAVE_INTERVAL = 6

local store = DataStoreService:GetDataStore("bloxello-wishlist-v1")
local cache: { [number]: { string } } = {}
local dirty: { [number]: boolean } = {}
local lastSave: { [number]: number } = {}

local WishlistService = {}

local function key(userId: number)
	return `{Config.StoreId}:{userId}`
end

local function sanitize(value: any): { string }
	local result, seen = {}, {}
	if type(value) ~= "table" then return result end
	for _, id in value do
		if type(id) == "string" and #id > 0 and #id <= 64 and not seen[id] and #result < MAX_ITEMS then
			seen[id] = true
			table.insert(result, id)
		end
	end
	return result
end

local function flush(userId: number)
	if not dirty[userId] then return end
	dirty[userId] = nil
	lastSave[userId] = os.clock()
	local list = cache[userId]
	pcall(store.SetAsync, store, key(userId), list)
end

function WishlistService.get(player: Player): { string }
	local userId = player.UserId
	if cache[userId] then return cache[userId] end
	local ok, stored = pcall(store.GetAsync, store, key(userId))
	cache[userId] = if ok then sanitize(stored) else {}
	return cache[userId]
end

function WishlistService.set(player: Player, ids: any)
	local userId = player.UserId
	cache[userId] = sanitize(ids)
	dirty[userId] = true
	if os.clock() - (lastSave[userId] or 0) >= SAVE_INTERVAL then
		task.spawn(flush, userId)
	else
		task.delay(SAVE_INTERVAL, flush, userId)
	end
end

function WishlistService.start()
	Players.PlayerRemoving:Connect(function(player)
		flush(player.UserId)
		cache[player.UserId] = nil
		lastSave[player.UserId] = nil
	end)
	game:BindToClose(function()
		for userId in dirty do flush(userId) end
	end)
end

return WishlistService

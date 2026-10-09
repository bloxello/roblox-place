-- Seller and reviewer text is only filtered here, in the Hub, using Roblox text filtering.
-- Anything that cannot be filtered is withheld rather than shown.
local TextService = game:GetService("TextService")

local CACHE_LIMIT = 1500
local MAX_LENGTH = 2000
local MAX_ATTEMPTS = 2

local FilterService = {}

local cache = {}
local order = {}
local inflight = {}

local function remember(text: string, filtered: string)
	if cache[text] == nil then
		table.insert(order, text)
		if #order > CACHE_LIMIT then
			cache[table.remove(order, 1)] = nil
		end
	end
	cache[text] = filtered
end

local function request(player: Player, text: string): string?
	for attempt = 1, MAX_ATTEMPTS do
		local ok, filtered = pcall(function()
			local result = TextService:FilterStringAsync(text, player.UserId, Enum.TextFilterContext.PublicChat)
			return result:GetNonChatStringForBroadcastAsync()
		end)
		if ok and type(filtered) == "string" then
			return filtered
		end
		if attempt < MAX_ATTEMPTS then
			task.wait(0.5)
		end
	end
	return nil
end

-- Returns the filtered text, or nil when filtering failed (callers must not fall back to the original).
function FilterService.filter(player: Player, text: any): string?
	if type(text) ~= "string" then
		return nil
	end
	if string.match(text, "^%s*$") then
		return ""
	end
	if #text > MAX_LENGTH then
		text = string.sub(text, 1, MAX_LENGTH)
	end
	local hit = cache[text]
	if hit then
		return hit
	end
	if inflight[text] then
		table.insert(inflight[text], coroutine.running())
		coroutine.yield()
		return cache[text]
	end

	inflight[text] = {}
	local filtered = request(player, text)
	if filtered then
		remember(text, filtered)
	end
	local waiters = inflight[text]
	inflight[text] = nil
	for _, thread in waiters do
		task.spawn(thread)
	end
	return filtered
end

-- Filters many strings concurrently. Returns a map from original text to filtered text (missing when withheld).
function FilterService.filterAll(player: Player, texts: { any }): { [string]: string }
	local results = {}
	local seen = {}
	local pending = 0
	local caller = coroutine.running()
	local waiting = false
	for _, text in texts do
		if type(text) == "string" and not seen[text] then
			seen[text] = true
			pending += 1
			task.spawn(function()
				local filtered = FilterService.filter(player, text)
				results[text] = filtered
				pending -= 1
				if pending == 0 and waiting then
					task.spawn(caller)
				end
			end)
		end
	end
	if pending > 0 then
		waiting = true
		coroutine.yield()
	end
	return table.clone(results)
end

return FilterService

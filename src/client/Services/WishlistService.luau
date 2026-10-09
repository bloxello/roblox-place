-- Saved items, persisted per player on the server (DataStore) and mirrored here.
local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local Promise = require(Core.Promise)
local Sfx = require(Core.Sfx)
local peek = Fusion.peek

local SAVE_DELAY = 1

local WishlistService = {}

function WishlistService.new(scope, remotes, toasts)
	local set = scope:Value({})
	local loaded = scope:Value(false)
	local saveToken = 0
	local self = { set = set, loaded = loaded }

	self.count = scope:Computed(function(use)
		local total = 0
		for _ in use(set) do
			total += 1
		end
		return total
	end)

	local function persist()
		saveToken += 1
		local token = saveToken
		task.delay(SAVE_DELAY, function()
			if token ~= saveToken then
				return
			end
			local ids = {}
			for id in peek(set) do
				table.insert(ids, id)
			end
			remotes.SetWishlist:FireServer(ids)
		end)
	end

	function self.load()
		return Promise.new(function(resolve)
			local ok, ids = pcall(function()
				return remotes.GetWishlist:InvokeServer()
			end)
			local map = {}
			if ok and type(ids) == "table" then
				for _, id in ids do
					map[id] = true
				end
			end
			resolve(map)
		end):andThen(function(map)
			-- Keep anything the player saved while the request was in flight.
			for id in peek(set) do
				map[id] = true
			end
			set:set(map)
			loaded:set(true)
		end)
	end

	function self.has(scopeForState, id: string)
		return scopeForState:Computed(function(use)
			return use(set)[id] == true
		end)
	end

	function self.toggle(entry)
		local updated = table.clone(peek(set))
		if updated[entry.id] then
			updated[entry.id] = nil
			Sfx.play("trash")
			toasts.push("info", `Removed {entry.name} from saved`, 2.5)
		else
			updated[entry.id] = true
			toasts.push("success", `Saved {entry.name}`, 2.5)
		end
		set:set(updated)
		persist()
	end

	return self
end

return WishlistService

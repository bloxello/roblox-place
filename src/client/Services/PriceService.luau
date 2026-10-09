-- Live Roblox prices, icons and ownership, layered over the cached catalog prices.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Fusion = require(script.Parent.Parent.Core.Fusion)
local peek = Fusion.peek

local WORKERS = 3

local PriceService = {}

function PriceService.new(scope)
	local prices = scope:Value({})
	local icons = scope:Value({})
	local owned = scope:Value({})
	local forSale = scope:Value({})
	local localPlayer = Players.LocalPlayer
	local self = { prices = prices, icons = icons, owned = owned, forSale = forSale }

	local function patch(state, key, value)
		local updated = table.clone(peek(state))
		updated[key] = value
		state:set(updated)
	end

	function self.refreshOwned(entry)
		if entry.kind ~= "pass" then return end
		local ok, result = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(localPlayer.UserId, entry.assetId)
		end)
		if ok and result then patch(owned, entry.id, true) end
	end

	function self.markOwned(entry)
		patch(owned, entry.id, true)
	end

	local function resolve(entry)
		local infoType = if entry.kind == "pass" then Enum.InfoType.GamePass else Enum.InfoType.Product
		local ok, info = pcall(function()
			return MarketplaceService:GetProductInfoAsync(entry.assetId, infoType)
		end)
		if ok and type(info) == "table" then
			if type(info.PriceInRobux) == "number" then patch(prices, entry.id, info.PriceInRobux) end
			if type(info.IconImageAssetId) == "number" and info.IconImageAssetId > 0 then
				patch(icons, entry.id, `rbxassetid://{info.IconImageAssetId}`)
			end
			if info.IsForSale == false then patch(forSale, entry.id, false) end
		end
		self.refreshOwned(entry)
	end

	function self.load(entries)
		local initial = {}
		for _, entry in entries do
			initial[entry.id] = entry.robux
		end
		prices:set(initial)
		local cursor = 0
		for _ = 1, WORKERS do
			task.spawn(function()
				while true do
					cursor += 1
					local entry = entries[cursor]
					if not entry then return end
					resolve(entry)
				end
			end)
		end
	end

	function self.priceOf(scopeForState, entry)
		return scopeForState:Computed(function(use)
			return use(prices)[entry.id] or entry.robux
		end)
	end

	function self.isOwned(scopeForState, entry)
		return scopeForState:Computed(function(use)
			return use(owned)[entry.id] == true
		end)
	end

	function self.iconOf(scopeForState, entry)
		return scopeForState:Computed(function(use)
			return entry.image or use(icons)[entry.id] or ""
		end)
	end

	return self
end

return PriceService

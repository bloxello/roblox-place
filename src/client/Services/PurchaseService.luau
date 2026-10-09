-- Robux purchases through Roblox's own prompts. Nothing here leaves the platform.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Fusion = require(script.Parent.Parent.Core.Fusion)
local peek = Fusion.peek

local PurchaseService = {}

function PurchaseService.new(scope, deps)
	local catalog, prices, toasts, remotes, deliveries = deps.catalog, deps.prices, deps.toasts, deps.remotes, deps.deliveries
	local localPlayer = Players.LocalPlayer
	local pending = scope:Value({})
	local self = { pending = pending }

	local function setPending(id: string, value: boolean?)
		local updated = table.clone(peek(pending))
		updated[id] = value
		pending:set(updated)
	end

	function self.isPending(scopeForState, entry)
		return scopeForState:Computed(function(use)
			return use(pending)[entry.id] == true
		end)
	end

	function self.buy(entry)
		if peek(prices.owned)[entry.id] then
			toasts.push("info", "You already own this item.")
			return
		end
		if peek(pending)[entry.id] then
			return
		end
		setPending(entry.id, true)
		local ok = pcall(function()
			if entry.kind == "pass" then
				MarketplaceService:PromptGamePassPurchase(localPlayer, entry.assetId)
			else
				MarketplaceService:PromptProductPurchase(localPlayer, entry.assetId)
			end
		end)
		if not ok then
			setPending(entry.id, nil)
			toasts.push("error", "Roblox couldn't open the purchase prompt. Try again.")
		end
	end

	local function finished(entry, purchased: boolean)
		if not entry then
			return
		end
		setPending(entry.id, nil)
		if purchased then
			toasts.push("success", `Purchased {entry.name}! Find it under "My items".`, 6)
			deliveries.refreshAfterPurchase(entry.id)
		end
	end

	table.insert(
		scope,
		MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
			if player ~= localPlayer then
				return
			end
			local entry = catalog.findByAsset("pass", passId)
			if purchased then
				remotes.ReportGamePass:FireServer(passId)
				if entry then
					prices.markOwned(entry)
				end
			end
			finished(entry, purchased)
		end)
	)
	table.insert(
		scope,
		MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, purchased)
			if userId ~= localPlayer.UserId then
				return
			end
			finished(catalog.findByAsset("product", productId), purchased)
		end)
	)

	return self
end

return PurchaseService

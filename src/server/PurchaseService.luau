local MarketplaceService = game:GetService("MarketplaceService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ApiClient = require(script.Parent.ApiClient)

local receipts = MemoryStoreService:GetHashMap("bloxello-receipts-v1")
local PurchaseService = {}

function PurchaseService.start()
	MarketplaceService.ProcessReceipt = function(receiptInfo)
		local key = tostring(receiptInfo.PurchaseId)
		local cachedOk, processed = pcall(receipts.GetAsync, receipts, key)
		if cachedOk and processed then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end

		local accepted = ApiClient.reportReceipt({
			purchaseId = key,
			playerId = tostring(receiptInfo.PlayerId),
			productId = tostring(receiptInfo.ProductId),
			placeId = tostring(game.PlaceId),
			universeId = tostring(game.GameId),
		})
		if not accepted then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local stored = pcall(receipts.SetAsync, receipts, key, true, 60 * 60 * 24 * 30)
		return if stored
			then Enum.ProductPurchaseDecision.PurchaseGranted
			else Enum.ProductPurchaseDecision.NotProcessedYet
	end
end

function PurchaseService.ownsGamePass(userId: number, gamePassId: number): boolean
	local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, userId, gamePassId)
	return ok and owns
end

function PurchaseService.processGamePass(player: Player, gamePassId: number)
	if not PurchaseService.ownsGamePass(player.UserId, gamePassId) then
		return false
	end
	local accepted = ApiClient.reportReceipt({
		purchaseId = `gamepass:{player.UserId}:{gamePassId}`,
		playerId = tostring(player.UserId),
		productId = tostring(gamePassId),
		placeId = tostring(game.PlaceId),
		universeId = tostring(game.GameId),
	})
	return accepted
end

return PurchaseService

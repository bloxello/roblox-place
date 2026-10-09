-- A player's purchased deliverables, fetched through the experience server so nothing leaves Roblox.
local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local peek = Fusion.peek

local RETRY_DELAYS = { 2, 3, 5, 8, 12 }

local DeliveryService = {}

function DeliveryService.new(scope, remotes)
	local list = scope:Value({})
	local status = scope:Value("idle")
	local self = { list = list, status = status }
	local fetching = false

	local function fetch()
		if fetching then return false end
		fetching = true
		if peek(status) == "idle" then status:set("loading") end
		local ok, result = pcall(function()
			return remotes.GetDeliveries:InvokeServer()
		end)
		fetching = false
		if ok and type(result) == "table" then
			list:set(result)
			status:set("ready")
			return true
		end
		if peek(status) ~= "ready" then status:set("error") end
		return false
	end

	function self.refresh()
		task.spawn(fetch)
	end

	function self.has(productId: string): boolean
		for _, delivery in peek(list) do
			if delivery.productId == productId then return true end
		end
		return false
	end

	-- The server records the receipt asynchronously, so poll briefly until the new delivery shows up.
	function self.refreshAfterPurchase(productId: string)
		task.spawn(function()
			for _, delay in RETRY_DELAYS do
				task.wait(delay)
				fetch()
				if self.has(productId) then return end
			end
		end)
	end

	function self.itemsFor(productId: string)
		for _, delivery in peek(list) do
			if delivery.productId == productId then return delivery end
		end
		return nil
	end

	return self
end

return DeliveryService

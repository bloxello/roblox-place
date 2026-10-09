local Players = game:GetService("Players")
local ApiClient = require(script.Parent.ApiClient)

local MIN_INTERVAL = 4

local lastFetch: { [number]: number } = {}
local cached: { [number]: any } = {}
local DeliveryService = {}

-- Deliverable content (files, links, keys) is deliberately never sent to the client.
local function sanitize(deliveries)
	if type(deliveries) ~= "table" then return deliveries end
	local out = {}
	for _, delivery in deliveries do
		table.insert(out, {
			productId = delivery.productId,
			productName = delivery.productName,
			status = delivery.status,
			purchasedAt = delivery.purchasedAt,
			items = {},
		})
	end
	return out
end

-- Only ever returns the calling player's own deliveries; rate limited to protect the API.
function DeliveryService.get(player: Player)
	local userId = player.UserId
	local now = os.clock()
	if lastFetch[userId] and now - lastFetch[userId] < MIN_INTERVAL then return cached[userId] end
	lastFetch[userId] = now
	local deliveries = ApiClient.getDeliveries(userId)
	if deliveries then cached[userId] = sanitize(deliveries) end
	return cached[userId]
end

function DeliveryService.start()
	Players.PlayerRemoving:Connect(function(player)
		lastFetch[player.UserId] = nil
		cached[player.UserId] = nil
	end)
end

return DeliveryService

local Players = game:GetService("Players")
local ApiClient = require(script.Parent.ApiClient)

local MIN_INTERVAL = 4

local lastFetch: { [number]: number } = {}
local cached: { [number]: any } = {}
local DeliveryService = {}

-- Only ever returns the calling player's own deliveries; rate limited to protect the API.
function DeliveryService.get(player: Player)
	local userId = player.UserId
	local now = os.clock()
	if lastFetch[userId] and now - lastFetch[userId] < MIN_INTERVAL then return cached[userId] end
	lastFetch[userId] = now
	local deliveries = ApiClient.getDeliveries(userId)
	if deliveries then cached[userId] = deliveries end
	return cached[userId]
end

function DeliveryService.start()
	Players.PlayerRemoving:Connect(function(player)
		lastFetch[player.UserId] = nil
		cached[player.UserId] = nil
	end)
end

return DeliveryService

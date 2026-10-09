local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- UI-only hub: there is no world, so a spawned character would fall into the void and respawn forever.
Players.CharacterAutoLoads = false
for _, player in Players:GetPlayers() do
	if player.Character then player.Character:Destroy() end
end

local CatalogService = require(script.CatalogService)
local PurchaseService = require(script.PurchaseService)
local WishlistService = require(script.WishlistService)
local DeliveryService = require(script.DeliveryService)
local ApiClient = require(script.ApiClient)
local ImageService = require(script.ImageService)

local remotes = Instance.new("Folder")
remotes.Name = "BloxelloRemotes"
remotes.Parent = ReplicatedStorage
local getCatalog = Instance.new("RemoteFunction")
getCatalog.Name = "GetCatalog"
getCatalog.Parent = remotes
getCatalog.OnServerInvoke = function()
	local catalog, catalogError = CatalogService.get()
	return catalog, catalogError
end
local reportGamePass = Instance.new("RemoteEvent")
reportGamePass.Name = "ReportGamePass"
reportGamePass.Parent = remotes
reportGamePass.OnServerEvent:Connect(function(player, gamePassId)
	if type(gamePassId) ~= "number" then
		return
	end
	PurchaseService.processGamePass(player, gamePassId)
end)

local getWishlist = Instance.new("RemoteFunction")
getWishlist.Name = "GetWishlist"
getWishlist.Parent = remotes
getWishlist.OnServerInvoke = function(player)
	return WishlistService.get(player)
end
local setWishlist = Instance.new("RemoteEvent")
setWishlist.Name = "SetWishlist"
setWishlist.Parent = remotes
setWishlist.OnServerEvent:Connect(function(player, ids)
	WishlistService.set(player, ids)
end)

local getDeliveries = Instance.new("RemoteFunction")
getDeliveries.Name = "GetDeliveries"
getDeliveries.Parent = remotes
getDeliveries.OnServerInvoke = function(player)
	return DeliveryService.get(player)
end

local getImage = Instance.new("RemoteFunction")
getImage.Name = "GetImage"
getImage.Parent = remotes
getImage.OnServerInvoke = function(player, kind, id)
	return ImageService.get(player, kind, id)
end

ImageService.start()
DeliveryService.start()
WishlistService.start()
PurchaseService.start()
task.spawn(function()
	if game.PlaceId == 0 then
		warn("[Bloxello] Unpublished place (Studio test): reporting runs, but Robux buy links need a published place or a manual Place ID in the dashboard.")
	end
	for attempt = 1, 5 do
		if ApiClient.reportConnection() then
			print("[Bloxello] Hub connected to Bloxello")
			return
		end
		task.wait(5 * attempt)
	end
end)
task.spawn(function()
	while task.wait(120) do
		CatalogService.refresh()
	end
end)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

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
local StoreView = require(script.StoreView)
local SupportService = require(script.SupportService)
local analyticsSessionId = if game.JobId ~= "" then game.JobId else HttpService:GenerateGUID(false)

local remotes = Instance.new("Folder")
remotes.Name = "BloxelloRemotes"
remotes.Parent = ReplicatedStorage
local getCatalog = Instance.new("RemoteFunction")
getCatalog.Name = "GetCatalog"
getCatalog.Parent = remotes
getCatalog.OnServerInvoke = function(player)
	local catalog, catalogError = CatalogService.get()
	if not catalog then
		return nil, catalogError
	end
	return StoreView.catalog(player, catalog)
end
local getProductDetails = Instance.new("RemoteFunction")
getProductDetails.Name = "GetProductDetails"
getProductDetails.Parent = remotes
getProductDetails.OnServerInvoke = function(player, productId)
	return StoreView.details(player, productId)
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
getImage.OnServerInvoke = function(player, kind, id, index)
	return ImageService.get(player, kind, id, index)
end

local getSupportTickets = Instance.new("RemoteFunction")
getSupportTickets.Name = "GetSupportTickets"
getSupportTickets.Parent = remotes
getSupportTickets.OnServerInvoke = function(player)
	return SupportService.list(player)
end

local createSupportTicket = Instance.new("RemoteFunction")
createSupportTicket.Name = "CreateSupportTicket"
createSupportTicket.Parent = remotes
createSupportTicket.OnServerInvoke = function(player, subject, message)
	return SupportService.create(player, subject, message)
end

local replySupportTicket = Instance.new("RemoteFunction")
replySupportTicket.Name = "ReplySupportTicket"
replySupportTicket.Parent = remotes
replySupportTicket.OnServerInvoke = function(player, ticketId, message)
	return SupportService.reply(player, ticketId, message)
end

StoreView.start()

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
local function reportHubPlay(player)
	task.spawn(function()
		for attempt = 1, 3 do
			if ApiClient.reportHubPlay(player.UserId, analyticsSessionId) then return end
			task.wait(attempt * 3)
		end
	end)
end
Players.PlayerAdded:Connect(reportHubPlay)
for _, player in Players:GetPlayers() do
	reportHubPlay(player)
end
task.spawn(function()
	while task.wait(120) do
		CatalogService.refresh()
	end
end)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CatalogService = require(script.CatalogService)
local PurchaseService = require(script.PurchaseService)
local WishlistService = require(script.WishlistService)
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

local getImage = Instance.new("RemoteFunction")
getImage.Name = "GetImage"
getImage.Parent = remotes
getImage.OnServerInvoke = function(player, kind, id)
	return ImageService.get(player, kind, id)
end

ImageService.start()
WishlistService.start()
PurchaseService.start()
task.spawn(function()
	if game.PlaceId > 0 then
		ApiClient.reportConnection()
	end
end)
task.spawn(function()
	while task.wait(120) do
		CatalogService.refresh()
	end
end)

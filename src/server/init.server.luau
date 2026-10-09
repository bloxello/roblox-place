local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CatalogService = require(script.CatalogService)
local PurchaseService = require(script.PurchaseService)
local ApiClient = require(script.ApiClient)

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
	if type(gamePassId) ~= "number" then return end
	PurchaseService.processGamePass(player, gamePassId)
end)

PurchaseService.start()
task.spawn(function()
	if game.PlaceId > 0 then ApiClient.reportConnection() end
end)
task.spawn(function()
	while task.wait(120) do CatalogService.refresh() end
end)


local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local scope = Fusion.scoped(Fusion)
local New = scope.New
local Children = scope.Children
local catalog, catalogError = ReplicatedStorage.BloxelloRemotes.GetCatalog:InvokeServer()
local localPlayer = Players.LocalPlayer
local launchProductId = nil
local launchData = localPlayer:GetJoinData().LaunchData
if type(launchData) == "string" and #launchData <= 200 then
	local ok, decoded = pcall(game:GetService("HttpService").JSONDecode, game:GetService("HttpService"), launchData)
	if ok and type(decoded) == "table" and type(decoded.bloxelloProductId) == "string" then launchProductId = decoded.bloxelloProductId end
end

local function prompt(mapping)
	local assetId = tonumber(mapping.robloxAssetId)
	if not assetId then return end
	if mapping.type == "DEVELOPER_PRODUCT" then MarketplaceService:PromptProductPurchase(localPlayer, assetId) else MarketplaceService:PromptGamePassPurchase(localPlayer, assetId) end
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, purchased)
	if player == localPlayer and purchased then ReplicatedStorage.BloxelloRemotes.ReportGamePass:FireServer(gamePassId) end
end)

local rows = {}
if catalog then
	for _, product in catalog.store.products do
		local mapping = product.mappings[1]
		local displayPrice = if mapping then mapping.robuxPrice else nil
		if mapping then
			local assetId = tonumber(mapping.robloxAssetId)
			local infoType = if mapping.type == "DEVELOPER_PRODUCT" then Enum.InfoType.Product else Enum.InfoType.GamePass
			local ok, productInfo = pcall(MarketplaceService.GetProductInfoAsync, MarketplaceService, assetId, infoType)
			if ok and type(productInfo) == "table" and type(productInfo.PriceInRobux) == "number" then
				displayPrice = productInfo.PriceInRobux
			end
		end
		table.insert(rows, New "TextButton" {
			Size = UDim2.new(1, -24, 0, 68),
			BackgroundColor3 = Color3.fromRGB(35, 35, 42),
			TextColor3 = Color3.new(1, 1, 1),
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = `  {if product.id == launchProductId then "▶ " else ""}{product.name}\n  {if displayPrice then `{utf8.char(0xE002)} {displayPrice}` else "Unavailable"}`,
			[scope.OnEvent "Activated"] = function()
				if not mapping then return end
				prompt(mapping)
			end,
		})
		if product.id == launchProductId and mapping then task.delay(1.5, prompt, mapping) end
	end
end

New "ScreenGui" {
	Name = "BloxelloCatalog",
	ResetOnSpawn = false,
	Parent = Players.LocalPlayer:WaitForChild("PlayerGui"),
	[Children] = { New "Frame" { Size = UDim2.fromOffset(440, 520), Position = UDim2.new(.5, -220, .5, -260), BackgroundColor3 = Color3.fromRGB(22, 22, 27), [Children] = {
		New "TextLabel" { Size = UDim2.new(1, 0, 0, 62), BackgroundTransparency = 1, TextColor3 = Color3.new(1,1,1), TextSize = 24, Text = if catalog then catalog.store.name else "Store unavailable" },
		New "UIListLayout" { Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Center },
		if catalogError then New "TextLabel" { Size = UDim2.new(1,-24,0,80), BackgroundTransparency=1, TextColor3=Color3.fromRGB(235,120,120), TextWrapped=true, Text=catalogError } else rows,
	} } }
}


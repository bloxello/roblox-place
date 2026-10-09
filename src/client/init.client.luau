local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local Children, OnEvent, OnChange = Fusion.Children, Fusion.OnEvent, Fusion.OnChange
local scope = Fusion.scoped(Fusion)
local peek = Fusion.peek

local remotes = ReplicatedStorage:WaitForChild("BloxelloRemotes")
local localPlayer = Players.LocalPlayer
local ROBUX = utf8.char(0xE002)

local BG = Color3.fromRGB(22, 22, 27)
local CARD = Color3.fromRGB(35, 35, 42)
local MUTED = Color3.fromRGB(160, 160, 172)
local WHITE = Color3.new(1, 1, 1)

local catalog, catalogError = remotes.GetCatalog:InvokeServer()
local store = if catalog then catalog.store else nil
local accent = Color3.fromRGB(88, 101, 242)
if store and type(store.accentColor) == "string" then
	local ok, color = pcall(Color3.fromHex, store.accentColor)
	if ok then accent = color end
end

-- Only Robux-purchasable products are ever listed; the Hub never links off-platform.
local products = {}
if store then
	for _, product in store.products do
		local mapping = product.mappings and product.mappings[1]
		if mapping and tonumber(mapping.robloxAssetId) then table.insert(products, product) end
	end
end

local categories = {}
do
	local seen = {}
	for _, product in products do
		for _, entry in product.categories or {} do
			local category = entry.category
			if category and not seen[category.slug] then
				seen[category.slug] = true
				table.insert(categories, category)
			end
		end
	end
	table.sort(categories, function(a, b) return a.name < b.name end)
end

local search = scope:Value("")
local activeCategory = scope:Value(nil)
local selected = scope:Value(nil)
local prices = scope:Value({})
local notice = scope:Value("")

local function inCategory(product, slug)
	for _, entry in product.categories or {} do
		if entry.category and entry.category.slug == slug then return true end
	end
	return false
end

local filtered = scope:Computed(function(use)
	local query = string.lower(use(search))
	local slug = use(activeCategory)
	local result = {}
	for _, product in products do
		local text = string.lower(`{product.name} {product.summary or ""}`)
		if (query == "" or string.find(text, query, 1, true)) and (slug == nil or inCategory(product, slug)) then
			table.insert(result, product)
		end
	end
	return result
end)

local function prompt(mapping)
	local assetId = tonumber(mapping.robloxAssetId)
	if not assetId then return end
	if mapping.type == "DEVELOPER_PRODUCT" then
		MarketplaceService:PromptProductPurchase(localPlayer, assetId)
	else
		MarketplaceService:PromptGamePassPurchase(localPlayer, assetId)
	end
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, purchased)
	if player == localPlayer and purchased then
		remotes.ReportGamePass:FireServer(gamePassId)
		notice:set("Purchase complete! Your item is being delivered.")
	end
end)
MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, _, purchased)
	if userId == localPlayer.UserId and purchased then
		notice:set("Purchase complete! Your item is being delivered.")
	end
end)

-- Show cached catalog prices immediately, then prefer live Roblox prices.
do
	local initial = {}
	for _, product in products do initial[product.id] = product.mappings[1].robuxPrice end
	prices:set(initial)
end
for _, product in products do
	local mapping = product.mappings[1]
	task.spawn(function()
		local infoType = if mapping.type == "DEVELOPER_PRODUCT" then Enum.InfoType.Product else Enum.InfoType.GamePass
		local ok, info = pcall(MarketplaceService.GetProductInfoAsync, MarketplaceService, tonumber(mapping.robloxAssetId), infoType)
		if ok and type(info) == "table" and type(info.PriceInRobux) == "number" then
			local updated = table.clone(peek(prices))
			updated[product.id] = info.PriceInRobux
			prices:set(updated)
		end
	end)
end

local function corner(s, radius)
	return s:New "UICorner" { CornerRadius = UDim.new(0, radius) }
end

local function padding(s, amount)
	return s:New "UIPadding" {
		PaddingTop = UDim.new(0, amount),
		PaddingBottom = UDim.new(0, amount),
		PaddingLeft = UDim.new(0, amount),
		PaddingRight = UDim.new(0, amount),
	}
end

local function thumbnail(s, product, size)
	local url = product.thumbnailUrl
	local usable = type(url) == "string"
		and (string.find(url, "^rbxassetid://") ~= nil or string.find(url, "^rbxthumb://") ~= nil)
	return s:New "ImageLabel" {
		Size = size,
		BackgroundColor3 = Color3.fromRGB(48, 48, 58),
		Image = if usable then url else "",
		ScaleType = Enum.ScaleType.Crop,
		[Children] = {
			corner(s, 8),
			if usable
				then nil
				else s:New "TextLabel" {
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					TextColor3 = MUTED,
					TextSize = 36,
					Font = Enum.Font.GothamBold,
					Text = string.upper(string.sub(product.name, 1, 1)),
				},
		},
	}
end

local function chip(label, slug)
	return scope:New "TextButton" {
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 30),
		BackgroundColor3 = scope:Computed(function(use)
			return if use(activeCategory) == slug then accent else CARD
		end),
		TextColor3 = WHITE,
		TextSize = 14,
		Font = Enum.Font.GothamMedium,
		Text = label,
		[OnEvent "Activated"] = function() activeCategory:set(slug) end,
		[Children] = {
			corner(scope, 15),
			scope:New "UIPadding" { PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) },
		},
	}
end

local chips = { chip("All", nil) }
for _, category in categories do table.insert(chips, chip(category.name, category.slug)) end
table.insert(chips, scope:New "UIListLayout" {
	FillDirection = Enum.FillDirection.Horizontal,
	Padding = UDim.new(0, 8),
	VerticalAlignment = Enum.VerticalAlignment.Center,
})

local cards = scope:ForValues(filtered, function(use, s, product)
	local price = use(prices)[product.id]
	return s:New "TextButton" {
		BackgroundColor3 = CARD,
		Text = "",
		[OnEvent "Activated"] = function() selected:set(product) end,
		[Children] = {
			corner(s, 10),
			padding(s, 8),
			thumbnail(s, product, UDim2.new(1, 0, 1, -50)),
			s:New "TextLabel" {
				Position = UDim2.new(0, 0, 1, -46),
				Size = UDim2.new(1, 0, 0, 22),
				BackgroundTransparency = 1,
				TextColor3 = WHITE,
				TextSize = 15,
				Font = Enum.Font.GothamMedium,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Text = product.name,
			},
			s:New "TextLabel" {
				Position = UDim2.new(0, 0, 1, -22),
				Size = UDim2.new(1, 0, 0, 20),
				BackgroundTransparency = 1,
				TextColor3 = accent,
				TextSize = 14,
				Font = Enum.Font.GothamBold,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = if price then `{ROBUX} {price}` else "Unavailable",
			},
		},
	}
end)

local emptyText = scope:Computed(function(use)
	if catalogError then return tostring(catalogError) end
	if #use(filtered) == 0 then
		return if #products == 0 then "No items are available for Robux yet." else "No items match your search."
	end
	return ""
end)

local detail = scope:Computed(function(use, s)
	local product = use(selected)
	if not product then return nil end
	local mapping = product.mappings[1]
	local price = use(prices)[product.id]
	return s:New "Frame" {
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = BG,
		ZIndex = 5,
		[Children] = {
			corner(s, 14),
			padding(s, 20),
			s:New "TextButton" {
				Size = UDim2.fromOffset(90, 32),
				BackgroundColor3 = CARD,
				TextColor3 = WHITE,
				TextSize = 14,
				Font = Enum.Font.GothamMedium,
				Text = "< Back",
				[OnEvent "Activated"] = function() selected:set(nil) end,
				[Children] = { corner(s, 8) },
			},
			s:New "Frame" {
				Position = UDim2.fromOffset(0, 48),
				Size = UDim2.new(1, 0, 1, -48),
				BackgroundTransparency = 1,
				[Children] = {
					thumbnail(s, product, UDim2.fromScale(0.4, 0.7)),
					s:New "Frame" {
						Position = UDim2.fromScale(0.44, 0),
						Size = UDim2.fromScale(0.56, 1),
						BackgroundTransparency = 1,
						[Children] = {
							s:New "UIListLayout" { Padding = UDim.new(0, 10) },
							s:New "TextLabel" {
								Size = UDim2.new(1, 0, 0, 34),
								BackgroundTransparency = 1,
								TextColor3 = WHITE,
								TextSize = 26,
								Font = Enum.Font.GothamBold,
								TextXAlignment = Enum.TextXAlignment.Left,
								TextTruncate = Enum.TextTruncate.AtEnd,
								Text = product.name,
							},
							s:New "TextLabel" {
								Size = UDim2.new(1, 0, 0, 120),
								BackgroundTransparency = 1,
								TextColor3 = MUTED,
								TextSize = 15,
								Font = Enum.Font.Gotham,
								TextWrapped = true,
								TextXAlignment = Enum.TextXAlignment.Left,
								TextYAlignment = Enum.TextYAlignment.Top,
								Text = product.summary or "",
							},
							s:New "TextButton" {
								Size = UDim2.new(1, 0, 0, 44),
								BackgroundColor3 = if price then accent else CARD,
								TextColor3 = WHITE,
								TextSize = 18,
								Font = Enum.Font.GothamBold,
								Text = if price then `Buy for {ROBUX} {price}` else "Unavailable",
								[OnEvent "Activated"] = function()
									if price then prompt(mapping) end
								end,
								[Children] = { corner(s, 10) },
							},
						},
					},
				},
			},
		},
	}
end)

local hasCategories = #categories > 0

scope:New "ScreenGui" {
	Name = "BloxelloHub",
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = localPlayer:WaitForChild("PlayerGui"),
	[Children] = scope:New "Frame" {
		Size = UDim2.fromOffset(720, 520),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = BG,
		[Children] = {
			corner(scope, 14),
			padding(scope, 20),
			scope:New "TextLabel" {
				Size = UDim2.new(1, -260, 0, 36),
				BackgroundTransparency = 1,
				TextColor3 = WHITE,
				TextSize = 26,
				Font = Enum.Font.GothamBold,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Text = if store then store.name else "Store unavailable",
			},
			scope:New "TextBox" {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.fromScale(1, 0),
				Size = UDim2.fromOffset(240, 34),
				BackgroundColor3 = CARD,
				TextColor3 = WHITE,
				PlaceholderText = "Search items",
				PlaceholderColor3 = MUTED,
				TextSize = 14,
				Font = Enum.Font.Gotham,
				ClearTextOnFocus = false,
				Text = "",
				[OnChange "Text"] = function(text) search:set(text) end,
				[Children] = { corner(scope, 8), scope:New "UIPadding" { PaddingLeft = UDim.new(0, 10) } },
			},
			scope:New "ScrollingFrame" {
				Position = UDim2.fromOffset(0, 48),
				Size = UDim2.new(1, 0, 0, 34),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ScrollBarThickness = 0,
				CanvasSize = UDim2.fromScale(0, 0),
				AutomaticCanvasSize = Enum.AutomaticSize.X,
				ScrollingDirection = Enum.ScrollingDirection.X,
				Visible = hasCategories,
				[Children] = chips,
			},
			scope:New "ScrollingFrame" {
				Position = UDim2.fromOffset(0, if hasCategories then 92 else 52),
				Size = UDim2.new(1, 0, 1, if hasCategories then -122 else -82),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ScrollBarThickness = 6,
				CanvasSize = UDim2.fromScale(0, 0),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				[Children] = {
					scope:New "UIGridLayout" {
						CellSize = UDim2.fromOffset(160, 190),
						CellPadding = UDim2.fromOffset(12, 12),
					},
					cards,
				},
			},
			scope:New "TextLabel" {
				Position = UDim2.fromOffset(0, 140),
				Size = UDim2.new(1, 0, 0, 60),
				BackgroundTransparency = 1,
				TextColor3 = MUTED,
				TextWrapped = true,
				TextSize = 16,
				Font = Enum.Font.Gotham,
				Text = emptyText,
			},
			scope:New "TextLabel" {
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.fromScale(0, 1),
				Size = UDim2.new(1, 0, 0, 24),
				BackgroundTransparency = 1,
				TextColor3 = accent,
				TextSize = 14,
				Font = Enum.Font.GothamMedium,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = notice,
			},
			detail,
		},
	},
}

local launchData = localPlayer:GetJoinData().LaunchData
if type(launchData) == "string" and #launchData <= 200 then
	local ok, decoded = pcall(HttpService.JSONDecode, HttpService, launchData)
	if ok and type(decoded) == "table" and type(decoded.bloxelloProductId) == "string" then
		for _, product in products do
			if product.id == decoded.bloxelloProductId then
				selected:set(product)
				task.delay(1.5, prompt, product.mappings[1])
				break
			end
		end
	end
end

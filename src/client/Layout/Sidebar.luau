local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local Theme = require(Core.Theme)
local UI = require(Core.UI)
local Children = Fusion.Children
local Components = script.Parent.Parent.Components
local Label = require(Components.Label)
local RemoteImage = require(Components.RemoteImage)
local NavItem = require(Components.NavItem)
local Avatar = require(Components.Avatar)
local Nav = require(script.Parent.Nav)
local Players = game:GetService("Players")

return function(ctx, scope)
	local theme = ctx.theme
	local items = {}
	for index, item in Nav.items do
		table.insert(
			items,
			NavItem(ctx, scope, {
				LayoutOrder = index,
				Icon = item.icon,
				Text = item.label,
				Count = if item.name == "Saved" then ctx.wishlist.count else nil,
				Selected = scope:Computed(function(use)
					return use(ctx.activeTab) == item.name
				end),
				OnClick = function()
					ctx.router.tab(item.name)
				end,
			})
		)
	end

	return scope:New "Frame" {
		Name = "Sidebar",
		BackgroundColor3 = theme.sidebar,
		BorderSizePixel = 0,
		Size = UDim2.new(0, Theme.layout.sidebarWidth, 1, 0),
		Visible = scope:Computed(function(use)
			return not use(ctx.compact)
		end),
		[Children] = {
			scope:New "Frame" {
				Name = "Divider",
				BackgroundColor3 = theme.border,
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.fromScale(1, 0),
				Size = UDim2.new(0, 1, 1, 0),
			},
			scope:New "Frame" {
				Name = "Body",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				[Children] = {
					UI.padding(scope, 16),
					scope:New "Frame" {
						Name = "Brand",
						BackgroundTransparency = 1,
						Size = UDim2.new(1, 0, 0, 52),
						[Children] = {
							scope:New "TextLabel" {
								Name = "Logo",
								BackgroundColor3 = theme.accent,
								Size = UDim2.fromOffset(44, 44),
								AnchorPoint = Vector2.new(0, 0.5),
								Position = UDim2.fromScale(0, 0.5),
								Text = scope:Computed(function(use)
									return string.upper(string.sub(use(ctx.catalog.store).name or "S", 1, 1))
								end),
								FontFace = Theme.fonts.heavy,
								TextSize = 22,
								TextColor3 = theme.onAccent,
								[Children] = {
									UI.corner(scope, Theme.radius.md),
									UI.gradient(scope, Color3.new(1, 1, 1), Color3.fromRGB(190, 190, 200), 135),
									RemoteImage(ctx, scope, { Name = "LogoImage", Content = ctx.logo, ZIndex = 2, Radius = Theme.radius.md }),
								},
							},
							Label(ctx, scope, {
								Text = scope:Computed(function(use)
									return use(ctx.catalog.store).name or "Store"
								end),
								Variant = "subheading",
								Truncate = true,
								Size = UDim2.new(1, -56, 0, 20),
								AnchorPoint = Vector2.new(0, 1),
								Position = UDim2.new(0, 56, 0.5, 1),
							}),
							Label(ctx, scope, {
								Text = "Robux Store",
								Variant = "caption",
								Color = theme.robux,
								AnchorPoint = Vector2.new(0, 0),
								Position = UDim2.new(0, 56, 0.5, 3),
							}),
						},
					},
					scope:New "Frame" {
						Name = "Nav",
						BackgroundTransparency = 1,
						Position = UDim2.fromOffset(0, 76),
						Size = UDim2.new(1, 0, 1, -76 - 84),
						[Children] = {
							UI.list(scope, { Gap = 4 }),
							Label(ctx, scope, { LayoutOrder = 0, Text = "MENU", Variant = "tiny", Color = theme.textFaint, Size = UDim2.new(1, 0, 0, 22) }),
							items,
						},
					},
					scope:New "Frame" {
						Name = "Footer",
						BackgroundColor3 = theme.surface,
						BorderSizePixel = 0,
						AnchorPoint = Vector2.new(0, 1),
						Position = UDim2.fromScale(0, 1),
						Size = UDim2.new(1, 0, 0, 68),
						[Children] = {
							UI.corner(scope, Theme.radius.md),
							UI.stroke(scope, theme.border, 1),
							UI.padding(scope, 12),
							Avatar(ctx, scope, { Dimension = 40 }),
							Label(ctx, scope, {
								Text = Players.LocalPlayer.DisplayName,
								Variant = "bodyStrong",
								Truncate = true,
								Size = UDim2.new(1, -52, 0, 18),
								Position = UDim2.fromOffset(52, 2),
							}),
							Label(ctx, scope, {
								Text = "Purchases use Robux",
								Variant = "caption",
								Color = theme.textMuted,
								Truncate = true,
								Size = UDim2.new(1, -52, 0, 16),
								Position = UDim2.fromOffset(52, 22),
							}),
						},
					},
				},
			},
		},
	}
end

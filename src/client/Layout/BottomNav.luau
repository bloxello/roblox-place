local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local Theme = require(Core.Theme)
local UI = require(Core.UI)
local Children = Fusion.Children
local Components = script.Parent.Parent.Components
local NavItem = require(Components.NavItem)
local Nav = require(script.Parent.Nav)

return function(ctx, scope)
	local theme = ctx.theme
	local items = {}
	for index, item in Nav.items do
		table.insert(
			items,
			NavItem(ctx, scope, {
				Layout = "tab",
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
		Name = "BottomNav",
		BackgroundColor3 = theme.sidebar,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.new(1, 0, 0, Theme.layout.bottomNavHeight),
		Visible = ctx.compact,
		[Children] = {
			scope:New "Frame" {
				Name = "Divider",
				BackgroundColor3 = theme.border,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 1),
			},
			scope:New "Frame" {
				Name = "Items",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				[Children] = {
					UI.padding(scope, 6, 8),
					UI.list(scope, { Direction = "Horizontal" }),
					items,
				},
			},
		},
	}
end

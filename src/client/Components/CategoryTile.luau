local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local Theme = require(Core.Theme)
local UI = require(Core.UI)
local Children, OnEvent = Fusion.Children, Fusion.OnEvent
-- Home page category entry. props: Category ({ name, slug, count }), OnClick
local Label = require(script.Parent.Label)
local Util = require(Core.Util)

return function(ctx, scope, props)
	local theme = ctx.theme
	local category = props.Category
	local hovering, pressed, events = UI.interact(scope)
	local hue = Util.hueFor(category.slug)
	local top = Color3.fromHSV(hue, 0.55, 0.38)
	local bottom = Color3.fromHSV((hue + 0.1) % 1, 0.6, 0.2)
	events[OnEvent "Activated"] = function()
		if props.OnClick then props.OnClick() end
	end
	return scope:New "TextButton"(UI.merge(events, {
		Name = "CategoryTile",
		AutoButtonColor = false,
		Text = "",
		BackgroundColor3 = top,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		LayoutOrder = props.LayoutOrder,
		[Children] = {
			UI.corner(scope, Theme.radius.lg),
			UI.gradient(scope, top, bottom, 120),
			UI.padding(scope, 16),
			scope:New "UIStroke" {
				Thickness = 1.5,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = theme.accent,
				Transparency = scope:Spring(
					scope:Computed(function(use)
						return if use(hovering) then 0 else 1
					end),
					45,
					1
				),
			},
			scope:New "UIScale" {
				Scale = scope:Spring(
					scope:Computed(function(use)
						return if use(pressed) then 0.97 else 1
					end),
					45,
					0.8
				),
			},
			Label(ctx, scope, {
				Text = Util.firstLetter(category.name),
				TextSize = 54,
				Font = Theme.fonts.heavy,
				Color = Color3.new(1, 1, 1),
				Transparency = 0.82,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, 0, 0, -8),
			}),
			Label(ctx, scope, {
				Text = category.name,
				Variant = "subheading",
				Color = Color3.new(1, 1, 1),
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.new(0, 0, 1, -18),
				Truncate = true,
				Size = UDim2.new(1, 0, 0, 20),
			}),
			Label(ctx, scope, {
				Text = Util.plural(category.count, "item"),
				Variant = "caption",
				Color = Color3.fromRGB(220, 224, 236),
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.fromScale(0, 1),
			}),
		},
	}))
end

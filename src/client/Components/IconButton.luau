local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local Theme = require(Core.Theme)
local UI = require(Core.UI)
local Children, OnEvent = Fusion.Children, Fusion.OnEvent
-- Square glyph button. Active highlights it (e.g. a saved heart).
-- props: Icon, OnClick, Active, ActiveColor, Dimension, Variant ("surface" | "ghost" | "overlay")
return function(ctx, scope, props)
	local theme = ctx.theme
	local hovering, pressed, events = UI.interact(scope)
	local active = props.Active or false
	local variant = props.Variant or "surface"
	local dimension = props.Dimension or 36

	local background = scope:Spring(
		scope:Computed(function(use)
			if use(pressed) then return theme.border end
			if use(hovering) then return theme.surfaceHover end
			return if variant == "overlay" then theme.overlay else theme.surfaceHigh
		end),
		45,
		1
	)
	local transparency = scope:Spring(
		scope:Computed(function(use)
			if variant == "ghost" and not use(hovering) then return 1 end
			return if variant == "overlay" then 0.35 else 0
		end),
		45,
		1
	)
	events[OnEvent "Activated"] = function()
		if props.OnClick then props.OnClick() end
	end
	return scope:New "TextButton"(UI.merge(events, {
		Name = props.Name or "IconButton",
		AutoButtonColor = false,
		BorderSizePixel = 0,
		BackgroundColor3 = background,
		BackgroundTransparency = transparency,
		Text = props.Icon,
		FontFace = Theme.fonts.bold,
		TextSize = props.TextSize or math.floor(dimension * 0.5),
		TextColor3 = scope:Computed(function(use)
			if use(active) then return props.ActiveColor or theme.danger end
			return if use(hovering) then theme.text else theme.textMuted
		end),
		Size = UDim2.fromOffset(dimension, dimension),
		LayoutOrder = props.LayoutOrder,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		Visible = props.Visible,
		ZIndex = props.ZIndex,
		[Children] = {
			UI.corner(scope, Theme.radius.md),
			scope:New "UIScale" {
				Scale = scope:Spring(
					scope:Computed(function(use)
						return if use(pressed) then 0.9 else 1
					end),
					45,
					0.7
				),
			},
		},
	}))
end

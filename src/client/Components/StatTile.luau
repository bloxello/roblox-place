local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local Theme = require(Core.Theme)
local UI = require(Core.UI)
local Children = Fusion.Children
-- props: Value (string or state), Label
local Label = require(script.Parent.Label)

return function(ctx, scope, props)
	local theme = ctx.theme
	return scope:New("Frame")({
		Name = "StatTile",
		BackgroundColor3 = theme.bg,
		BackgroundTransparency = 0.35,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(0, 0),
		AutomaticSize = Enum.AutomaticSize.XY,
		LayoutOrder = props.LayoutOrder,
		[Children] = {
			UI.corner(scope, Theme.radius.md),
			UI.stroke(scope, theme.border, 1, 0.4),
			UI.padding(scope, 10, 16),
			UI.list(scope, { Gap = 2 }),
			Label(ctx, scope, { LayoutOrder = 1, Text = props.Value, Variant = "heading" }),
			Label(ctx, scope, { LayoutOrder = 2, Text = props.Label, Variant = "caption", Color = theme.textMuted }),
		},
	})
end

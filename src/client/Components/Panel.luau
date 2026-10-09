local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local Theme = require(Core.Theme)
local UI = require(Core.UI)
local Children = Fusion.Children
-- Rounded surface with optional stroke, padding and list layout.
return function(ctx, scope, props)
	local theme = ctx.theme
	return scope:New "Frame" {
		Name = props.Name or "Panel",
		BackgroundColor3 = props.Color or theme.surface,
		BackgroundTransparency = props.Transparency or 0,
		BorderSizePixel = 0,
		Size = props.Size or UDim2.fromScale(1, 0),
		AutomaticSize = props.AutomaticSize or (if props.Size then Enum.AutomaticSize.None else Enum.AutomaticSize.Y),
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		LayoutOrder = props.LayoutOrder,
		ClipsDescendants = props.Clip or false,
		Visible = props.Visible,
		ZIndex = props.ZIndex,
		[Children] = {
			UI.corner(scope, props.Radius or Theme.radius.lg),
			if props.Stroke ~= false then UI.stroke(scope, props.StrokeColor or theme.border, 1) else nil,
			if props.Padding then UI.padding(scope, props.Padding) else nil,
			if props.List then UI.list(scope, props.List) else nil,
			props.Children,
		},
	}
end

local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local Children = Fusion.Children
-- Label / value line inside detail panels. props: Label, Value
local Label = require(script.Parent.Label)

return function(ctx, scope, props)
	local theme = ctx.theme
	return scope:New("Frame")({
		Name = "InfoRow",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 24),
		LayoutOrder = props.LayoutOrder,
		[Children] = {
			Label(ctx, scope, {
				Text = props.Label,
				Variant = "body",
				Color = theme.textMuted,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.fromScale(0, 0.5),
			}),
			Label(ctx, scope, {
				Text = props.Value,
				Variant = "bodyStrong",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.fromScale(1, 0.5),
				Align = Enum.TextXAlignment.Right,
			}),
		},
	})
end

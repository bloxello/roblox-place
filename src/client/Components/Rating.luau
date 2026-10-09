local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local UI = require(Core.UI)
local Util = require(Core.Util)
local Icons = require(Core.Icons)
local Children = Fusion.Children
-- Compact "★ 4.8 (12)" summary. Renders nothing visible when there are no ratings unless EmptyText is set.
-- props: Average, Count, EmptyText, Variant
local Label = require(script.Parent.Label)

return function(ctx, scope, props)
	local theme = ctx.theme
	local variant = props.Variant or "caption"
	local rated = props.Count > 0
	if not rated and not props.EmptyText then
		return scope:New("Frame")({
			Name = "Rating",
			LayoutOrder = props.LayoutOrder,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(0, 0),
			Visible = false,
		})
	end
	return scope:New("Frame")({
		Name = "Rating",
		LayoutOrder = props.LayoutOrder,
		AnchorPoint = props.AnchorPoint,
		Position = props.Position,
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.fromOffset(0, 0),
		[Children] = {
			UI.list(scope, { Direction = "Horizontal", Gap = 4, VAlign = Enum.VerticalAlignment.Center }),
			if rated then Label(ctx, scope, { LayoutOrder = 1, Text = Icons.star, Variant = variant, Color = theme.warning }) else nil,
			Label(ctx, scope, {
				LayoutOrder = 2,
				Text = if rated
					then string.format("%.1f", props.Average)
					else props.EmptyText,
				Variant = if rated then "bodyStrong" else variant,
				TextSize = if rated and variant == "caption" then 12 else nil,
				Color = if rated then theme.text else theme.textFaint,
			}),
			if rated
				then Label(ctx, scope, {
					LayoutOrder = 3,
					Text = `({Util.compact(props.Count)})`,
					Variant = variant,
					Color = theme.textFaint,
				})
				else nil,
		},
	})
end

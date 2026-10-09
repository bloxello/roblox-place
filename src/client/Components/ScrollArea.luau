local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local Theme = require(Core.Theme)
local UI = require(Core.UI)
local Children = Fusion.Children
-- Scrolling page body with a centred, width-limited content column.
return function(ctx, scope, props)
	local theme = ctx.theme
	local pad = scope:Computed(function(use)
		return if use(ctx.compact) then 14 else 28
	end)
	return scope:New("ScrollingFrame")({
		Name = props.Name or "ScrollArea",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		CanvasSize = UDim2.fromScale(0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 5,
		ScrollBarImageColor3 = theme.border,
		ScrollBarImageTransparency = 0.2,
		VerticalScrollBarInset = Enum.ScrollBarInset.None,
		[Children] = scope:New("Frame")({
			Name = "Content",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0),
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			[Children] = {
				UI.maxWidth(scope, Theme.layout.maxContent),
				scope:New("UIPadding")({
					PaddingTop = UDim.new(0, 24),
					PaddingBottom = UDim.new(0, 40),
					PaddingLeft = scope:Computed(function(use)
						return UDim.new(0, use(pad))
					end),
					PaddingRight = scope:Computed(function(use)
						return UDim.new(0, use(pad))
					end),
				}),
				UI.list(scope, { Gap = props.Gap or 28 }),
				props.Children,
			},
		}),
	})
end

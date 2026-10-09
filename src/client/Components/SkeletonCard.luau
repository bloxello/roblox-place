local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local Theme = require(Core.Theme)
local UI = require(Core.UI)
local Children = Fusion.Children
local Skeleton = require(script.Parent.Skeleton)

return function(ctx, scope, order)
	local theme = ctx.theme
	return scope:New("Frame")({
		Name = "SkeletonCard",
		LayoutOrder = order,
		BackgroundColor3 = theme.surface,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		[Children] = {
			UI.corner(scope, Theme.radius.lg),
			UI.stroke(scope, theme.border, 1),
			UI.padding(scope, 12),
			UI.list(scope, { Gap = 10 }),
			Skeleton(ctx, scope, { LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 110), Radius = Theme.radius.md }),
			Skeleton(ctx, scope, { LayoutOrder = 2, Size = UDim2.new(0.4, 0, 0, 12) }),
			Skeleton(ctx, scope, { LayoutOrder = 3, Size = UDim2.new(0.8, 0, 0, 16) }),
			Skeleton(ctx, scope, { LayoutOrder = 4, Size = UDim2.new(1, 0, 0, 12) }),
			Skeleton(ctx, scope, { LayoutOrder = 5, Size = UDim2.new(0.3, 0, 0, 24) }),
		},
	})
end

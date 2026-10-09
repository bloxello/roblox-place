local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local Theme = require(Core.Theme)
local UI = require(Core.UI)
local Children = Fusion.Children
-- Square headshot of the local player. props: Dimension
local Players = game:GetService("Players")

return function(ctx, scope, props)
	local theme = ctx.theme
	local dimension = props.Dimension or 36
	return scope:New("ImageLabel")({
		Name = "Avatar",
		BackgroundColor3 = theme.surfaceHigh,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(dimension, dimension),
		LayoutOrder = props.LayoutOrder,
		Image = `rbxthumb://type=AvatarHeadShot&id={Players.LocalPlayer.UserId}&w=150&h=150`,
		[Children] = UI.corner(scope, Theme.radius.full),
	})
end

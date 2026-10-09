local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local UI = require(Core.UI)
local Sfx = require(Core.Sfx)
local Children, Out = Fusion.Children, Fusion.Out
-- Fade/slide-in wrapper that every page returns. props: Children
return function(ctx, scope, props)
	local shown = UI.appear(scope)
	Sfx.play("appear")
	local info = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	return scope:New("CanvasGroup")({
		Name = props.Name or "Page",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		GroupTransparency = scope:Tween(
			scope:Computed(function(use)
				return if use(shown) then 0 else 1
			end),
			info
		),
		Position = scope:Tween(
			scope:Computed(function(use)
				return if use(shown) then UDim2.fromOffset(0, 0) else UDim2.fromOffset(0, 14)
			end),
			info
		),
		[Children] = props.Children,
	})
end

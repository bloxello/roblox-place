--# selene: allow(undefined_variable)
local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local Children = Fusion.Children

-- Image drawn from an EditableImage. Fades in once Content (a state from ImageService) arrives.
-- props: Content (state), Size, Position, AnchorPoint, ZIndex, ScaleType, Radius
return function(_ctx, scope, props)
	local loaded = scope:Computed(function(use)
		return use(props.Content).SourceType ~= Enum.ContentSourceType.None
	end)
	return scope:New "ImageLabel" {
		Name = props.Name or "RemoteImage",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = props.Size or UDim2.fromScale(1, 1),
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		ZIndex = props.ZIndex,
		LayoutOrder = props.LayoutOrder,
		ScaleType = props.ScaleType or Enum.ScaleType.Crop,
		ImageContent = props.Content,
		ImageTransparency = scope:Tween(
			scope:Computed(function(use)
				return if use(loaded) then props.Opacity or 0 else 1
			end),
			TweenInfo.new(0.25)
		),
		[Children] = if props.Radius then scope:New "UICorner" { CornerRadius = UDim.new(0, props.Radius) } else nil,
	}
end



local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local Theme = require(Core.Theme)
local UI = require(Core.UI)
local Children = Fusion.Children
-- Product artwork: Roblox icon when available, otherwise a generated gradient + initial.
-- props: Product, Ratio (width / height), Radius
local Util = require(Core.Util)
local RemoteImage = require(script.Parent.RemoteImage)

return function(ctx, scope, props)
	local product = props.Product
	local hue = Util.hueFor(product.id)
	local top = Color3.fromHSV(hue, 0.55, 0.42)
	local bottom = Color3.fromHSV((hue + 0.08) % 1, 0.6, 0.22)
	local image = ctx.prices.iconOf(scope, product)
	local content = ctx.images.product(product)

	return scope:New("Frame")({
		Name = props.Name or "Thumbnail",
		BackgroundColor3 = top,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Size = props.Size or UDim2.fromScale(1, 0),
		LayoutOrder = props.LayoutOrder,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		ZIndex = props.ZIndex,
		[Children] = {
			UI.corner(scope, props.Radius or Theme.radius.md),
			UI.gradient(scope, top, bottom, 135),
			if props.Ratio then UI.aspect(scope, props.Ratio) else nil,
			scope:New("TextLabel")({
				Name = "Initial",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Text = Util.firstLetter(product.name),
				FontFace = Theme.fonts.heavy,
				TextScaled = true,
				TextColor3 = Color3.new(1, 1, 1),
				TextTransparency = 0.7,
				[Children] = scope:New("UIPadding")({
					PaddingTop = UDim.new(0.18, 0),
					PaddingBottom = UDim.new(0.18, 0),
					PaddingLeft = UDim.new(0.18, 0),
					PaddingRight = UDim.new(0.18, 0),
				}),
			}),
			scope:New("ImageLabel")({
				Name = "Artwork",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
				Image = image,
				ScaleType = Enum.ScaleType.Crop,
				ZIndex = 2,
			}),
			if content then RemoteImage(ctx, scope, { Name = "Uploaded", Content = content, ZIndex = 3 }) else nil,
		},
	})
end

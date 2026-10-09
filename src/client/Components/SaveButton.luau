local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local Icons = require(Core.Icons)
-- Heart toggle bound to the wishlist. props: Product, Variant, Dimension, Position, AnchorPoint, ZIndex
local IconButton = require(script.Parent.IconButton)

return function(ctx, scope, props)
	local product = props.Product
	local saved = ctx.wishlist.has(scope, product.id)
	return IconButton(ctx, scope, {
		Name = "SaveButton",
		Icon = scope:Computed(function(use)
			return if use(saved) then Icons.heart else Icons.heartOutline
		end),
		Active = saved,
		Variant = props.Variant or "overlay",
		Dimension = props.Dimension or 34,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		ZIndex = props.ZIndex,
		LayoutOrder = props.LayoutOrder,
		OnClick = function()
			ctx.wishlist.toggle(product)
		end,
	})
end

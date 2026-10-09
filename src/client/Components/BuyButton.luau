local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local Icons = require(Core.Icons)
-- Robux purchase button that reflects owned / pending state. props: Product, Size, Fill
local Button = require(script.Parent.Button)
local Badge = require(script.Parent.Badge)

return function(ctx, scope, props)
	local product = props.Product
	local owned = ctx.prices.isOwned(scope, product)
	local pending = ctx.purchase.isPending(scope, product)
	return scope:Computed(function(use, inner)
		if use(owned) then
			return Badge(ctx, inner, { Text = Icons.check .. " Owned", Kind = "success", LayoutOrder = props.LayoutOrder })
		end
		return Button(ctx, inner, {
			Text = props.Text or "Buy",
			Variant = "success",
			Size = props.Size or "sm",
			Fill = props.Fill,
			Loading = pending,
			LayoutOrder = props.LayoutOrder,
			OnClick = function()
				ctx.purchase.buy(product)
			end,
		})
	end)
end

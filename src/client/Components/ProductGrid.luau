local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
-- The standard product grid, with loading skeletons. props: Items (state), Skeleton (bool)
local ResponsiveGrid = require(script.Parent.ResponsiveGrid)
local ProductCard = require(script.Parent.ProductCard)
local SkeletonCard = require(script.Parent.SkeletonCard)

return function(ctx, scope, props)
	if props.Skeleton then
		local placeholders = {}
		for index = 1, 8 do
			table.insert(placeholders, { id = `skeleton-{index}` })
		end
		return ResponsiveGrid(ctx, scope, {
			Items = scope:Value(placeholders),
			MinWidth = 230,
			CellHeight = ProductCard.heightFor,
			LayoutOrder = props.LayoutOrder,
			Render = function(inner, _, order)
				return SkeletonCard(ctx, inner, order)
			end,
		})
	end
	return ResponsiveGrid(ctx, scope, {
		Items = props.Items,
		MinWidth = 230,
		CellHeight = ProductCard.heightFor,
		LayoutOrder = props.LayoutOrder,
		Render = function(inner, item, order)
			return ProductCard(ctx, inner, { Product = item, LayoutOrder = order })
		end,
	})
end

local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local Icons = require(Core.Icons)
local Util = require(Core.Util)
local Children = Fusion.Children
local Components = script.Parent.Parent.Components
local PageShell = require(Components.PageShell)
local ScrollArea = require(Components.ScrollArea)
local SectionHeader = require(Components.SectionHeader)
local ProductGrid = require(Components.ProductGrid)
local EmptyState = require(Components.EmptyState)
local AsyncBoundary = require(Components.AsyncBoundary)
return function(ctx, scope)
	local function ready(inner)
		local saved = inner:Computed(function(use)
			local set = use(ctx.wishlist.set)
			local out = {}
			for _, product in use(ctx.catalog.products) do
				if set[product.id] then table.insert(out, product) end
			end
			return out
		end)
		return {
			SectionHeader(ctx, inner, {
				Title = "Saved items",
				Subtitle = inner:Computed(function(use)
					local total = #use(saved)
					return `{total} {Util.plural(total, "item")} saved to your wishlist`
				end),
			}),
			inner:Computed(function(use, cell)
				if #use(saved) == 0 then
					return EmptyState(ctx, cell, {
						Icon = Icons.heartOutline,
						Title = "No saved items yet",
						Message = "Tap the heart on any item to keep it here for later.",
						ActionText = "Browse items",
						OnAction = function()
							ctx.router.tab("Browse")
						end,
					})
				end
				return ProductGrid(ctx, cell, { Items = saved })
			end),
		}
	end
	return PageShell(ctx, scope, {
		Name = "Saved",
		Children = ScrollArea(ctx, scope, {
			Children = AsyncBoundary(ctx, scope, {
				Loading = function(inner)
					return ProductGrid(ctx, inner, { Skeleton = true })
				end,
				Ready = ready,
			}),
		}),
	})
end

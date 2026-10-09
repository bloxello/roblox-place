local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local Theme = require(Core.Theme)
local Icons = require(Core.Icons)
local UI = require(Core.UI)
local Util = require(Core.Util)
local Children = Fusion.Children
local Components = script.Parent.Parent.Components
local Label = require(Components.Label)
local Panel = require(Components.Panel)
local PageShell = require(Components.PageShell)
local ScrollArea = require(Components.ScrollArea)
local SectionHeader = require(Components.SectionHeader)
local ProductGrid = require(Components.ProductGrid)
local EmptyState = require(Components.EmptyState)
local AsyncBoundary = require(Components.AsyncBoundary)

local Badge = require(Components.Badge)
local Price = require(Components.Price)
local Thumbnail = require(Components.Thumbnail)
local SaveButton = require(Components.SaveButton)
local BuyButton = require(Components.BuyButton)
local InfoRow = require(Components.InfoRow)

local function infoPanel(ctx, scope, title: string, children)
	return Panel(ctx, scope, {
		Padding = 18,
		List = { Gap = 8 },
		Children = {
			Label(ctx, scope, { LayoutOrder = 0, Text = title, Variant = "subheading" }),
			children,
		},
	})
end

return function(ctx, scope, params)
	local theme = ctx.theme

	local function ready(inner)
		local product = ctx.catalog.find(params.id)
		if not product then
			return EmptyState(ctx, inner, {
				Icon = Icons.info,
				Title = "Item not found",
				Message = "This item may have been removed from the store.",
				ActionText = "Browse items",
				OnAction = function()
					ctx.router.tab("Browse")
				end,
			})
		end

		local price = ctx.prices.priceOf(inner, product)
		local badges = {
			Badge(ctx, inner, {
				LayoutOrder = 0,
				Text = if product.kind == "pass" then "GAME PASS" else "DEVELOPER PRODUCT",
				Kind = "accent",
			}),
		}
		for index, category in product.categories do
			table.insert(badges, Badge(ctx, inner, { LayoutOrder = index, Text = category.name }))
		end

		local related = inner:Computed(function(use)
			local out = {}
			local first = product.categories[1]
			for _, other in use(ctx.catalog.products) do
				if other.id ~= product.id then
					local matches = first == nil
					for _, category in other.categories do
						if first and category.slug == first.slug then
							matches = true
						end
					end
					if matches then
						table.insert(out, other)
					end
				end
			end
			table.sort(out, function(a, b)
				return a.popularity > b.popularity
			end)
			while #out > 4 do
				table.remove(out)
			end
			return out
		end)

		local details = inner:New("Frame")({
			Name = "Details",
			LayoutOrder = 2,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			[Children] = {
				UI.list(inner, { Gap = 14 }),
				inner:New("Frame")({
					LayoutOrder = 1,
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					[Children] = { UI.list(inner, { Direction = "Horizontal", Gap = 6, Wrap = true }), badges },
				}),
				Label(ctx, inner, { LayoutOrder = 2, Text = product.name, Variant = "display", Wrap = true }),
				Price(ctx, inner, { LayoutOrder = 3, Amount = price, Size = "xl" }),
				inner:New("Frame")({
					LayoutOrder = 4,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 48),
					[Children] = {
						UI.list(inner, { Direction = "Horizontal", Gap = 10, VAlign = Enum.VerticalAlignment.Center }),
						BuyButton(ctx, inner, { LayoutOrder = 1, Product = product, Size = "lg" }),
						SaveButton(
							ctx,
							inner,
							{ LayoutOrder = 2, Product = product, Variant = "surface", Dimension = 48 }
						),
					},
				}),
				infoPanel(ctx, inner, "About this item", {
					Label(ctx, inner, {
						LayoutOrder = 1,
						Text = if product.description ~= ""
							then product.description
							else "The seller has not added a description.",
						Variant = "body",
						Color = theme.textMuted,
						Wrap = true,
					}),
				}),
				infoPanel(ctx, inner, "Details", {
					InfoRow(ctx, inner, {
						LayoutOrder = 1,
						Label = "Type",
						Value = if product.kind == "pass" then "Game pass" else "Developer product",
					}),
					InfoRow(ctx, inner, { LayoutOrder = 2, Label = "Added", Value = Util.timeAgo(product.createdAt) }),
					InfoRow(ctx, inner, {
						LayoutOrder = 3,
						Label = "Saved by",
						Value = `{Util.compact(product.popularity)} {Util.plural(product.popularity, "player")}`,
					}),
				}),
				infoPanel(ctx, inner, "How delivery works", {
					Label(ctx, inner, {
						LayoutOrder = 1,
						Text = "Items are Roblox developer assets (game passes and developer products) from creators. Checkout happens in Roblox's official purchase prompt, paid with your own Robux. Everything the creator includes then appears under My items, right here in the experience. Bloxello never asks for your password or sells Robux.",
						Variant = "caption",
						Color = theme.textMuted,
						Wrap = true,
					}),
				}),
			},
		})

		local media = inner:New("Frame")({
			Name = "Media",
			LayoutOrder = 1,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 0),
			[Children] = {
				UI.aspect(inner, 1),
				Thumbnail(ctx, inner, { Product = product, Size = UDim2.fromScale(1, 1), Radius = Theme.radius.xl }),
			},
		})

		local top = inner:Computed(function(use, cell)
			if use(ctx.compact) then
				return {
					UI.list(cell, { Gap = 18 }),
					media,
					details,
				}
			end
			return {
				UI.list(cell, { Direction = "Horizontal", Gap = 28 }),
				cell:New("Frame")({
					LayoutOrder = 1,
					BackgroundTransparency = 1,
					Size = UDim2.new(0.42, -14, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					[Children] = { UI.list(cell, {}), media },
				}),
				cell:New("Frame")({
					LayoutOrder = 2,
					BackgroundTransparency = 1,
					Size = UDim2.new(0.58, -14, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					[Children] = { UI.list(cell, {}), details },
				}),
			}
		end)

		return {
			inner:New("Frame")({
				Name = "Top",
				LayoutOrder = 1,
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				[Children] = top,
			}),
			inner:New("Frame")({
				Name = "Related",
				LayoutOrder = 2,
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Visible = inner:Computed(function(use)
					return #use(related) > 0
				end),
				[Children] = {
					UI.list(inner, { Gap = 14 }),
					SectionHeader(ctx, inner, { Title = "You might also like" }),
					ProductGrid(ctx, inner, { Items = related }),
				},
			}),
		}
	end

	return PageShell(ctx, scope, {
		Name = "Product",
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

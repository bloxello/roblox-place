local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local Theme = require(Core.Theme)
local Icons = require(Core.Icons)
local UI = require(Core.UI)
local Util = require(Core.Util)
local Children, OnChange = Fusion.Children, Fusion.OnChange
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
local Gallery = require(Components.Gallery)
local Rating = require(Components.Rating)
local Reviews = require(Components.Reviews)
local Skeleton = require(Components.Skeleton)
local SaveButton = require(Components.SaveButton)
local BuyButton = require(Components.BuyButton)
local InfoRow = require(Components.InfoRow)

local function infoPanel(ctx, scope, order: number, title: string, children)
	return Panel(ctx, scope, {
		LayoutOrder = order,
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
		local discountCode = inner:Value("")
		ctx.recent.add(product.id)

		-- Description and reviews are filtered by the server and fetched separately from the catalog.
		local details = inner:Value({ status = "loading" })
		local alive = true
		table.insert(inner, function()
			alive = false
		end)
		ctx.catalog
			.details(product.id)
			:andThen(function(data)
				if alive then
					details:set({ status = "ready", data = data })
				end
			end)
			:catch(function()
				if alive then
					details:set({ status = "error" })
				end
			end)

		local description = inner:Computed(function(use, cell)
			local state = use(details)
			if state.status == "loading" then
				return {
					Skeleton(ctx, cell, { LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 14) }),
					Skeleton(ctx, cell, { LayoutOrder = 2, Size = UDim2.new(0.8, 0, 0, 14) }),
				}
			end
			local data = state.data
			local text = if data and data.description ~= "" then data.description else nil
			return Label(ctx, cell, {
				LayoutOrder = 1,
				Text = text or (if state.status == "error" or (data and data.descriptionWithheld)
					then "The description is unavailable right now."
					else "The seller has not added a description."),
				Variant = "body",
				Color = if text then theme.textMuted else theme.textFaint,
				Wrap = true,
			})
		end)

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

		local detailsColumn = inner:New("Frame")({
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
				Rating(ctx, inner, {
					LayoutOrder = 3,
					Average = product.rating.average,
					Count = product.rating.count,
					EmptyText = "No reviews yet",
					Variant = "body",
				}),
				Price(ctx, inner, { LayoutOrder = 4, Amount = price, Size = "xl" }),
				inner:New("Frame")({
					LayoutOrder = 5,
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
				Panel(ctx, inner, {
					LayoutOrder = 6,
					Padding = 12,
					Children = {
						UI.list(inner, { Direction = "Horizontal", Gap = 8, VAlign = Enum.VerticalAlignment.Center }),
						inner:New("TextBox")({ LayoutOrder = 1, BackgroundColor3 = theme.surfaceHigh, BorderSizePixel = 0, Size = UDim2.new(1, -105, 0, 38), ClearTextOnFocus = false, Text = discountCode, PlaceholderText = "Discount code", PlaceholderColor3 = theme.textFaint, TextColor3 = theme.text, FontFace = Theme.fonts.medium, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, [OnChange("Text")] = function(text) discountCode:set(text) end, [Children] = { UI.corner(inner, Theme.radius.md), UI.padding(inner, 0, 12) } }),
						Button(ctx, inner, { LayoutOrder = 2, Text = "Apply", Width = 88, Variant = "secondary", OnClick = function() ctx.purchase.buyWithDiscount(product, Fusion.peek(discountCode)) end }),
					},
				}),
				infoPanel(ctx, inner, 7, "About this item", { description }),
								infoPanel(ctx, inner, 8, "Details", {
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
				infoPanel(ctx, inner, 9, "How delivery works", {
					Label(ctx, inner, {
						LayoutOrder = 1,
						Text = "Items are Roblox developer assets (game passes and developer products) from creators. Checkout happens in Roblox's official purchase prompt, paid with your own Robux. Everything you buy is listed under My items, right here in the experience. Bloxello never asks for your password or sells Robux.",
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
			AutomaticSize = Enum.AutomaticSize.Y,
			[Children] = {
				UI.maxWidth(inner, 960),
				Gallery(ctx, inner, { Product = product }),
			},
		})

		local top = inner:Computed(function(use, cell)
			if use(ctx.compact) then
				return {
					UI.list(cell, { Gap = 18, HAlign = Enum.HorizontalAlignment.Center }),
					media,
					detailsColumn,
				}
			end
			return {
				UI.list(cell, { Direction = "Horizontal", Gap = 28, VAlign = Enum.VerticalAlignment.Top }),
				cell:New("Frame")({
					LayoutOrder = 1,
					BackgroundTransparency = 1,
					Size = UDim2.new(0.5, -14, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					[Children] = { UI.list(cell, { HAlign = Enum.HorizontalAlignment.Center }), media },
				}),
				cell:New("Frame")({
					LayoutOrder = 2,
					BackgroundTransparency = 1,
					Size = UDim2.new(0.5, -14, 0, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					[Children] = { UI.list(cell, {}), detailsColumn },
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
			Reviews(ctx, inner, { LayoutOrder = 2, Details = details }),
			inner:New("Frame")({
				Name = "Related",
				LayoutOrder = 3,
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

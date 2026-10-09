local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local Theme = require(Core.Theme)
local UI = require(Core.UI)
local Util = require(Core.Util)
local Children = Fusion.Children
local Components = script.Parent.Parent.Components
local Label = require(Components.Label)
local Button = require(Components.Button)
local PageShell = require(Components.PageShell)
local ScrollArea = require(Components.ScrollArea)
local SectionHeader = require(Components.SectionHeader)
local ProductGrid = require(Components.ProductGrid)
local ResponsiveGrid = require(Components.ResponsiveGrid)
local AsyncBoundary = require(Components.AsyncBoundary)
local StatTile = require(Components.StatTile)
local RemoteImage = require(Components.RemoteImage)
local CategoryTile = require(Components.CategoryTile)

local function section(ctx, scope, props)
	return scope:New "Frame" {
		Name = props.Name,
		LayoutOrder = props.LayoutOrder,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		[Children] = {
			UI.list(scope, { Gap = 14 }),
			SectionHeader(ctx, scope, {
				Title = props.Title,
				Subtitle = props.Subtitle,
				ActionText = "See all",
				OnAction = props.OnAction,
			}),
			props.Body,
		},
	}
end

local function topBy(ctx, scope, field: string, limit: number)
	return scope:Computed(function(use)
		local list = table.clone(use(ctx.catalog.products))
		table.sort(list, function(a, b)
			if a[field] ~= b[field] then return a[field] > b[field] end
			return a.order < b.order
		end)
		local out = {}
		for index = 1, math.min(limit, #list) do
			table.insert(out, list[index])
		end
		return out
	end)
end

return function(ctx, scope)
	local theme = ctx.theme
	local catalog = ctx.catalog

	local function ready(inner)
		local popular = topBy(ctx, inner, "popularity", 4)
		local newest = topBy(ctx, inner, "createdAt", 4)
		local count = inner:Computed(function(use)
			return #use(catalog.products)
		end)
		local heroContent = inner:New "Frame" {
			Name = "HeroContent",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			ZIndex = 3,
			[Children] = {
				UI.padding(inner, 28),
				UI.list(inner, { Gap = 10 }),
				Label(ctx, inner, {
					LayoutOrder = 1,
					Text = "BLOXELLO · DEVELOPER ASSETS",
					Variant = "tiny",
					Color = theme.onAccent,
					Transparency = 0.25,
				}),
				Label(ctx, inner, {
					LayoutOrder = 2,
					Text = inner:Computed(function(use)
						return use(catalog.store).name or "Store"
					end),
					Variant = "display",
					Color = theme.onAccent,
					Wrap = true,
				}),
				Label(ctx, inner, {
					LayoutOrder = 3,
					Text = inner:Computed(function(use)
						local text = use(catalog.store).description
						if text and text ~= "" then return text end
						return "Bloxello is a hub for buying Roblox developer assets: game passes and developer products made by creators. Every purchase goes through Roblox's own purchase prompt. Bloxello does not sell or give away Robux."
					end),
					Variant = "body",
					Color = theme.onAccent,
					Transparency = 0.15,
					Wrap = true,
				}),
				inner:New "Frame" {
					LayoutOrder = 4,
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					[Children] = {
						UI.list(inner, { Direction = "Horizontal", Gap = 10, Wrap = true, VAlign = Enum.VerticalAlignment.Center }),
						Button(ctx, inner, {
							LayoutOrder = 1,
							Text = "Browse all items",
							Variant = "ghost",
							Size = "lg",
							OnClick = function()
								ctx.browse.reset()
								ctx.router.tab("Browse")
							end,
						}),
						StatTile(ctx, inner, {
							LayoutOrder = 2,
							Value = inner:Computed(function(use)
								return Util.formatNumber(use(count))
							end),
							Label = "Items",
						}),
						StatTile(ctx, inner, {
							LayoutOrder = 3,
							Value = inner:Computed(function(use)
								return Util.formatNumber(#use(catalog.categories))
							end),
							Label = "Categories",
						}),
					},
				},
			},
		}
		local hero = inner:New "Frame" {
			Name = "Hero",
			LayoutOrder = 1,
			BackgroundColor3 = theme.accent,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			[Children] = {
				UI.corner(inner, Theme.radius.xl),
				UI.gradient(inner, theme.accent, theme.accent:Lerp(Color3.new(0, 0, 0), 0.65), 120),
				RemoteImage(ctx, inner, { Name = "Banner", Content = ctx.banner, Opacity = 0.35, ZIndex = 1 }),
				heroContent,
			},
		}

		local categories = section(ctx, inner, {
			Name = "Categories",
			LayoutOrder = 2,
			Title = "Shop by category",
			Subtitle = "Jump straight to what you need",
			OnAction = function()
				ctx.browse.reset()
				ctx.router.tab("Browse")
			end,
			Body = ResponsiveGrid(ctx, inner, {
				Items = catalog.categories,
				MinWidth = 200,
				Gap = 12,
				CellHeight = function()
					return 92
				end,
				Render = function(cell, category)
					return CategoryTile(ctx, cell, {
						Category = category,
						OnClick = function()
							ctx.browse.showCategory(category.slug)
							ctx.router.tab("Browse")
						end,
					})
				end,
			}),
		})
		local function toBrowse(sort)
			return function()
				ctx.browse.reset()
				ctx.browse.sort:set(sort)
				ctx.router.tab("Browse")
			end
		end

		return {
			hero,
			categories,
			section(ctx, inner, {
				Name = "Popular",
				LayoutOrder = 3,
				Title = "Most saved",
				Subtitle = "What other players keep coming back to",
				OnAction = toBrowse("popular"),
				Body = ProductGrid(ctx, inner, { Items = popular }),
			}),
			section(ctx, inner, {
				Name = "New",
				LayoutOrder = 4,
				Title = "New arrivals",
				Subtitle = "Fresh in the store",
				OnAction = toBrowse("newest"),
				Body = ProductGrid(ctx, inner, { Items = newest }),
			}),
		}
	end

	return PageShell(ctx, scope, {
		Name = "Home",
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


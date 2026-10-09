local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local Icons = require(Core.Icons)
local UI = require(Core.UI)
local Util = require(Core.Util)
local Children = Fusion.Children
local Components = script.Parent.Parent.Components
local Label = require(Components.Label)
local PageShell = require(Components.PageShell)
local ScrollArea = require(Components.ScrollArea)
local ProductGrid = require(Components.ProductGrid)
local EmptyState = require(Components.EmptyState)
local AsyncBoundary = require(Components.AsyncBoundary)
local Chip = require(Components.Chip)
local Dropdown = require(Components.Dropdown)
local BrowseState = require(script.Parent.Parent.Services.BrowseState)

local function chipRow(ctx, scope, order, children)
	return scope:New "Frame" {
		LayoutOrder = order,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		[Children] = { UI.list(scope, { Direction = "Horizontal", Gap = 8, Wrap = true }), children },
	}
end

return function(ctx, scope)
	local browse = ctx.browse
	local catalog = ctx.catalog

	local function ready(inner)
		local categoryChips = { Chip(ctx, inner, {
			LayoutOrder = 0,
			Text = "All",
			Selected = inner:Computed(function(use)
				return use(browse.category) == nil
			end),
			OnClick = function()
				browse.category:set(nil)
			end,
		}) }
		local chips = inner:ForValues(catalog.categories, function(use, cell, category)
			return Chip(ctx, cell, {
				Text = category.name,
				Count = browse.countFor(category.slug),
				LayoutOrder = category.order or 1,
				Selected = cell:Computed(function(use2)
					return use2(browse.category) == category.slug
				end),
				OnClick = function()
					browse.category:set(category.slug)
				end,
			})
		end)
		local bandChips = {}
		for index, band in BrowseState.bands do
			table.insert(
				bandChips,
				Chip(ctx, inner, {
					LayoutOrder = index,
					Text = band.label,
					Selected = inner:Computed(function(use)
						return use(browse.band) == band.id
					end),
					OnClick = function()
						browse.band:set(band.id)
					end,
				})
			)
		end

		local hasResults = inner:Computed(function(use)
			return #use(browse.results) > 0
		end)
		local summary = inner:Computed(function(use)
			local total = #use(browse.results)
			return `{Util.formatNumber(total)} {Util.plural(total, "item")}`
		end)
		local options = {}
		for _, option in BrowseState.sorts do
			table.insert(options, option)
		end

		return {
			chipRow(ctx, inner, 1, { categoryChips, chips }),
			chipRow(ctx, inner, 2, bandChips),
			inner:New "Frame" {
				Name = "Toolbar",
				LayoutOrder = 3,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 40),
				[Children] = {
					Label(ctx, inner, {
						Text = summary,
						Variant = "bodyStrong",
						Color = ctx.theme.textMuted,
						AnchorPoint = Vector2.new(0, 0.5),
						Position = UDim2.fromScale(0, 0.5),
					}),
					inner:New "Frame" {
						BackgroundTransparency = 1,
						AnchorPoint = Vector2.new(1, 0.5),
						Position = UDim2.fromScale(1, 0.5),
						Size = UDim2.fromOffset(190, 40),
						[Children] = Dropdown(ctx, inner, {
							Label = browse.sortLabel(inner),
							Options = options,
							Selected = browse.sort,
							Width = 190,
							OnSelect = function(id)
								browse.sort:set(id)
							end,
						}),
					},
				},
			},
			inner:Computed(function(use, results)
				if not use(hasResults) then
					return EmptyState(ctx, results, {
						LayoutOrder = 4,
						Icon = Icons.search,
						Title = "Nothing matches",
						Message = "Try a different search or clear your filters.",
						ActionText = if use(browse.isFiltered) then "Clear filters" else nil,
						OnAction = function()
							browse.reset()
						end,
					})
				end
				return ProductGrid(ctx, results, { Items = browse.results, LayoutOrder = 4 })
			end),
		}
	end

	return PageShell(ctx, scope, {
		Name = "Browse",
		Children = ScrollArea(ctx, scope, {
			Gap = 16,
			Children = AsyncBoundary(ctx, scope, {
				Loading = function(inner)
					return ProductGrid(ctx, inner, { Skeleton = true })
				end,
				Ready = ready,
			}),
		}),
	})
end

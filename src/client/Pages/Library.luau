local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local Theme = require(Core.Theme)
local Icons = require(Core.Icons)
local UI = require(Core.UI)
local Children = Fusion.Children
local Components = script.Parent.Parent.Components
local PageShell = require(Components.PageShell)
local ScrollArea = require(Components.ScrollArea)
local SectionHeader = require(Components.SectionHeader)
local Panel = require(Components.Panel)
local Label = require(Components.Label)
local EmptyState = require(Components.EmptyState)
local Badge = require(Components.Badge)

-- Ownership list only: no links, files or keys are ever shown inside the experience.
local function itemRow(ctx, scope, delivery, order: number)
	return Panel(ctx, scope, {
		Name = "Owned",
		LayoutOrder = order,
		Padding = 16,
		Children = {
			UI.list(scope, { Direction = "Horizontal", Gap = 10, VAlign = Enum.VerticalAlignment.Center }),
			Label(ctx, scope, {
				LayoutOrder = 1,
				Text = delivery.productName,
				Variant = "bodyStrong",
				Size = UDim2.new(1, -90, 0, 20),
				Truncate = true,
			}),
			Badge(ctx, scope, { LayoutOrder = 2, Text = "OWNED", Kind = "accent" }),
		},
	})
end

return function(ctx, scope)
	ctx.deliveries.refresh()

	return PageShell(ctx, scope, {
		Name = "Library",
		Children = ScrollArea(ctx, scope, {
			Children = {
				SectionHeader(ctx, scope, {
					LayoutOrder = 1,
					Title = "My items",
					Subtitle = "The developer assets you've bought through this Hub",
					ActionText = "Refresh",
					OnAction = ctx.deliveries.refresh,
				}),
				scope:Computed(function(use, inner)
					local status = use(ctx.deliveries.status)
					local list = use(ctx.deliveries.list)
					if status == "idle" or status == "loading" then
						return Label(ctx, inner, { LayoutOrder = 2, Text = "Loading your items…", Color = ctx.theme.textMuted })
					end
					if status == "error" then
						return EmptyState(ctx, inner, {
							LayoutOrder = 2,
							Icon = Icons.warning,
							Title = "We couldn't load your items",
							Message = "Your purchases are safe. Try again in a moment.",
							ActionText = "Try again",
							OnAction = ctx.deliveries.refresh,
						})
					end
					if #list == 0 then
						return EmptyState(ctx, inner, {
							LayoutOrder = 2,
							Icon = Icons.bag,
							Title = "Nothing here yet",
							Message = "Items you buy appear here.",
							ActionText = "Browse items",
							OnAction = function()
								ctx.router.tab("Browse")
							end,
						})
					end
					local rows = { UI.list(inner, { Gap = 10 }) }
					for index, delivery in list do
						table.insert(rows, itemRow(ctx, inner, delivery, index))
					end
					return inner:New "Frame" {
						LayoutOrder = 2,
						BackgroundTransparency = 1,
						Size = UDim2.fromScale(1, 0),
						AutomaticSize = Enum.AutomaticSize.Y,
						[Children] = rows,
					}
				end),
			},
		}),
	})
end

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

local TYPE_LABELS = {
	DOWNLOAD = "FILE",
	LINK = "LINK",
	CODE = "CODE",
	LICENSE_KEY = "LICENSE KEY",
	INSTRUCTIONS = "INSTRUCTIONS",
}

-- Read-only but selectable, so players can copy the content with the platform's own text selection.
local function valueBox(ctx, scope, value: string, order: number)
	local theme = ctx.theme
	return scope:New "ScrollingFrame" {
		Name = "Value",
		LayoutOrder = order,
		BackgroundColor3 = theme.bg,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.fromScale(0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = theme.border,
		[Children] = {
			UI.corner(scope, Theme.radius.md),
			UI.stroke(scope, theme.border, 1),
			scope:New "UISizeConstraint" { MaxSize = Vector2.new(math.huge, 240) },
			UI.padding(scope, 12),
			scope:New "TextBox" {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				Text = value,
				TextEditable = false,
				ClearTextOnFocus = false,
				MultiLine = true,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				FontFace = Font.fromEnum(Enum.Font.RobotoMono),
				TextSize = 13,
				TextColor3 = theme.text,
			},
		},
	}
end

local function deliverableCard(ctx, scope, item, order: number)
	local theme = ctx.theme
	local children = {
		UI.list(scope, { Gap = 8 }),
		scope:New "Frame" {
			LayoutOrder = 1,
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			[Children] = {
				UI.list(scope, { Direction = "Horizontal", Gap = 8, VAlign = Enum.VerticalAlignment.Center }),
				Badge(ctx, scope, { LayoutOrder = 1, Text = TYPE_LABELS[item.type] or "ITEM", Kind = "accent" }),
				Label(ctx, scope, { LayoutOrder = 2, Text = item.title, Variant = "bodyStrong", Truncate = true }),
			},
		},
	}
	if item.description and item.description ~= "" then
		table.insert(
			children,
			Label(ctx, scope, { LayoutOrder = 2, Text = item.description, Variant = "caption", Color = theme.textMuted, Wrap = true })
		)
	end
	if item.value and item.value ~= "" then
		table.insert(children, valueBox(ctx, scope, item.value, 3))
		if item.type == "LINK" then
			table.insert(
				children,
				Label(ctx, scope, {
					LayoutOrder = 4,
					Text = "Select the text above to copy it.",
					Variant = "caption",
					Color = theme.textFaint,
				})
			)
		end
	elseif item.note then
		table.insert(
			children,
			Label(ctx, scope, { LayoutOrder = 3, Text = item.note, Variant = "caption", Color = theme.warning, Wrap = true })
		)
	end
	return Panel(ctx, scope, {
		Name = "Deliverable",
		LayoutOrder = order,
		Color = theme.surfaceHigh,
		Radius = Theme.radius.md,
		Padding = 14,
		Children = children,
	})
end

local function deliveryPanel(ctx, scope, delivery, order: number)
	local children = {
		UI.list(scope, { Gap = 12 }),
		Label(ctx, scope, { LayoutOrder = 1, Text = delivery.productName, Variant = "heading", Wrap = true }),
	}
	if #delivery.items == 0 then
		table.insert(
			children,
			Label(ctx, scope, {
				LayoutOrder = 2,
				Text = "The creator hasn't added any deliverables to this item yet.",
				Variant = "body",
				Color = ctx.theme.textMuted,
				Wrap = true,
			})
		)
	end
	for index, item in delivery.items do
		table.insert(children, deliverableCard(ctx, scope, item, index + 1))
	end
	return Panel(ctx, scope, { Name = "Delivery", LayoutOrder = order, Padding = 18, Children = children })
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
					Subtitle = "Everything you've bought here, with the files, keys and instructions that come with it",
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
							Message = "Items you buy appear here with everything the creator included.",
							ActionText = "Browse items",
							OnAction = function()
								ctx.router.tab("Browse")
							end,
						})
					end
					local panels = { UI.list(inner, { Gap = 16 }) }
					for index, delivery in list do
						table.insert(panels, deliveryPanel(ctx, inner, delivery, index))
					end
					return inner:New "Frame" {
						LayoutOrder = 2,
						BackgroundTransparency = 1,
						Size = UDim2.fromScale(1, 0),
						AutomaticSize = Enum.AutomaticSize.Y,
						[Children] = panels,
					}
				end),
			},
		}),
	})
end

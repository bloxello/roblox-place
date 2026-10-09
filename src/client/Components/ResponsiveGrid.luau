local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local Children, Out = Fusion.Children, Fusion.Out
-- Card grid that picks its column count from the available width.
-- props: Items (state of arrays), MinWidth, Gap, CellHeight(width) -> number, Render(scope, item, order)
return function(ctx, scope, props)
	local size = scope:Value(Vector2.zero)
	local gap = props.Gap or 16
	local minWidth = props.MinWidth or 220

	local order = scope:Computed(function(use)
		local map = {}
		for index, item in use(props.Items) do
			map[item.id] = index
		end
		return map
	end)
	local cell = scope:Computed(function(use)
		local available = use(size).X
		if available <= 0 then
			return Vector2.new(minWidth, props.CellHeight(minWidth))
		end
		local columns = math.max(1, (available + gap) // (minWidth + gap))
		local cellWidth = math.floor((available - gap * (columns - 1)) / columns)
		return Vector2.new(cellWidth, props.CellHeight(cellWidth))
	end)

	return scope:New("Frame")({
		Name = props.Name or "Grid",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = props.LayoutOrder,
		[Out("AbsoluteSize")] = size,
		[Children] = {
			scope:New("UIGridLayout")({
				SortOrder = Enum.SortOrder.LayoutOrder,
				CellPadding = UDim2.fromOffset(gap, gap),
				CellSize = scope:Computed(function(use)
					local dimensions = use(cell)
					return UDim2.fromOffset(dimensions.X, dimensions.Y)
				end),
			}),
			scope:ForValues(props.Items, function(use, inner, item)
				local position = inner:Computed(function(use2)
					return use2(order)[item.id] or 0
				end)
				return props.Render(inner, item, position)
			end),
		},
	})
end

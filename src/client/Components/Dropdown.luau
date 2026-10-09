local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local Theme = require(Core.Theme)
local Icons = require(Core.Icons)
local UI = require(Core.UI)
local Children, OnEvent = Fusion.Children, Fusion.OnEvent
-- props: Label (state string), Options ({ { id, label } }), Selected (state id), OnSelect(id), Width
return function(ctx, scope, props)
	local theme = ctx.theme
	local open = scope:Value(false)
	local hovering, pressed, events = UI.interact(scope)
	local optionHeight = 34
	local width = props.Width or 200

	local items = {}
	for index, option in props.Options do
		local optionHover = scope:Value(false)
		table.insert(
			items,
			scope:New "TextButton" {
				Name = option.id,
				LayoutOrder = index,
				AutoButtonColor = false,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, optionHeight),
				BackgroundColor3 = theme.surfaceHover,
				BackgroundTransparency = scope:Computed(function(use)
					return if use(optionHover) then 0 else 1
				end),
				Text = option.label,
				FontFace = Theme.fonts.medium,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = scope:Computed(function(use)
					return if use(props.Selected) == option.id then theme.accent else theme.text
				end),
				[OnEvent "MouseEnter"] = function() optionHover:set(true) end,
				[OnEvent "MouseLeave"] = function() optionHover:set(false) end,
				[OnEvent "Activated"] = function()
					open:set(false)
					props.OnSelect(option.id)
				end,
				[Children] = { UI.corner(scope, Theme.radius.sm), UI.padding(scope, 0, 10) },
			}
		)
	end

	events[OnEvent "Activated"] = function()
		open:set(not Fusion.peek(open))
	end

	return scope:New "Frame" {
		Name = props.Name or "Dropdown",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(width, 38),
		LayoutOrder = props.LayoutOrder,
		ZIndex = 20,
		[OnEvent "MouseLeave"] = function() open:set(false) end,
		[Children] = {
			scope:New "TextButton"(UI.merge(events, {
				Name = "Toggle",
				AutoButtonColor = false,
				BorderSizePixel = 0,
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = scope:Spring(
					scope:Computed(function(use)
						if use(pressed) then return theme.border end
						return if use(hovering) then theme.surfaceHover else theme.surfaceHigh
					end),
					45,
					1
				),
				Text = scope:Computed(function(use)
					return `{use(props.Label)}  {Icons.chevronDown}`
				end),
				FontFace = Theme.fonts.semibold,
				TextSize = 13,
				TextColor3 = theme.text,
				[Children] = { UI.corner(scope, Theme.radius.md), UI.stroke(scope, theme.border, 1) },
			})),
			scope:New "Frame" {
				Name = "Menu",
				Visible = open,
				ZIndex = 30,
				Position = UDim2.new(0, 0, 1, 6),
				Size = UDim2.fromOffset(width, #props.Options * optionHeight + 12),
				BackgroundColor3 = theme.surfaceHigh,
				BorderSizePixel = 0,
				[Children] = {
					UI.corner(scope, Theme.radius.md),
					UI.stroke(scope, theme.border, 1),
					UI.padding(scope, 6),
					UI.list(scope, {}),
					items,
				},
			},
		},
	}
end

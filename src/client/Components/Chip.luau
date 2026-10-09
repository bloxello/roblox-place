local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local Theme = require(Core.Theme)
local UI = require(Core.UI)
local Children, OnEvent = Fusion.Children, Fusion.OnEvent
-- Selectable pill. props: Text, Selected, OnClick, Count
return function(ctx, scope, props)
	local theme = ctx.theme
	local hovering, pressed, events = UI.interact(scope)
	local selected = props.Selected or false

	events[OnEvent "Activated"] = function()
		if props.OnClick then props.OnClick() end
	end
	return scope:New "TextButton"(UI.merge(events, {
		Name = props.Name or "Chip",
		AutoButtonColor = false,
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 32),
		LayoutOrder = props.LayoutOrder,
		BackgroundColor3 = scope:Spring(
			scope:Computed(function(use)
				if use(selected) then return theme.accentSoft end
				if use(pressed) then return theme.border end
				return if use(hovering) then theme.surfaceHover else theme.surfaceHigh
			end),
			45,
			1
		),
		Text = scope:Computed(function(use)
			local text = use(props.Text)
			if props.Count then return `{text}  {props.Count}` end
			return text
		end),
		FontFace = Theme.fonts.semibold,
		TextSize = 13,
		TextColor3 = scope:Computed(function(use)
			return if use(selected) then theme.accent else theme.textMuted
		end),
		[Children] = {
			UI.corner(scope, Theme.radius.full),
			UI.padding(scope, 0, 14),
			scope:New "UIStroke" {
				Thickness = 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = scope:Spring(
					scope:Computed(function(use)
						return if use(selected) then theme.accent else theme.border
					end),
					45,
					1
				),
			},
		},
	}))
end

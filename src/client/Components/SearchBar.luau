local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local Theme = require(Core.Theme)
local Icons = require(Core.Icons)
local UI = require(Core.UI)
local Children, OnEvent, OnChange = Fusion.Children, Fusion.OnEvent, Fusion.OnChange
-- props: Value (Value<string>), Placeholder, Height
return function(ctx, scope, props)
	local theme = ctx.theme
	local focused = scope:Value(false)
	local hovering = scope:Value(false)
	local hasText = scope:Computed(function(use)
		return use(props.Value) ~= ""
	end)

	return scope:New "Frame" {
		Name = props.Name or "SearchBar",
		BackgroundColor3 = theme.surface,
		BorderSizePixel = 0,
		Size = props.Size or UDim2.new(1, 0, 0, props.Height or 44),
		LayoutOrder = props.LayoutOrder,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		[OnEvent "MouseEnter"] = function() hovering:set(true) end,
		[OnEvent "MouseLeave"] = function() hovering:set(false) end,
		[Children] = {
			UI.corner(scope, Theme.radius.md),
			scope:New "UIStroke" {
				Thickness = 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = scope:Spring(
					scope:Computed(function(use)
						if use(focused) then return theme.accent end
						return if use(hovering) then theme.textFaint else theme.border
					end),
					50,
					1
				),
			},
			scope:New "TextLabel" {
				Name = "Icon",
				BackgroundTransparency = 1,
				Size = UDim2.new(0, 40, 1, 0),
				Text = Icons.search,
				FontFace = Theme.fonts.bold,
				TextSize = 20,
				TextColor3 = scope:Computed(function(use)
					return if use(focused) then theme.accent else theme.textFaint
				end),
			},
			scope:New "TextBox" {
				Name = "Input",
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(40, 0),
				Size = UDim2.new(1, -80, 1, 0),
				ClearTextOnFocus = false,
				Text = props.Value,
				PlaceholderText = props.Placeholder or "Search",
				PlaceholderColor3 = theme.textFaint,
				TextColor3 = theme.text,
				FontFace = Theme.fonts.medium,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				[OnEvent "Focused"] = function() focused:set(true) end,
				[OnEvent "FocusLost"] = function() focused:set(false) end,
				[OnChange "Text"] = function(text)
					props.Value:set(text)
				end,
			},
			scope:New "TextButton" {
				Name = "Clear",
				AutoButtonColor = false,
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -8, 0.5, 0),
				Size = UDim2.fromOffset(28, 28),
				Text = Icons.close,
				FontFace = Theme.fonts.bold,
				TextSize = 13,
				TextColor3 = theme.textMuted,
				Visible = hasText,
				[OnEvent "Activated"] = function()
					props.Value:set("")
				end,
			},
		},
	}
end

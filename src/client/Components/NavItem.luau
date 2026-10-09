local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local Theme = require(Core.Theme)
local UI = require(Core.UI)
local Children, OnEvent = Fusion.Children, Fusion.OnEvent
-- Navigation entry used by the sidebar ("side") and the bottom bar ("tab").
-- props: Icon, Text, Selected, Count (state), OnClick, Layout
local Label = require(script.Parent.Label)

return function(ctx, scope, props)
	local theme = ctx.theme
	local hovering, pressed, events = UI.interact(scope)
	local selected = props.Selected or false
	local tab = props.Layout == "tab"
	events[OnEvent "Activated"] = function()
		props.OnClick()
	end

	local tone = scope:Computed(function(use)
		if use(selected) then return theme.accent end
		return if use(hovering) then theme.text else theme.textMuted
	end)
	local badge = if props.Count
		then scope:New "TextLabel" {
			Name = "Count",
			Visible = scope:Computed(function(use)
				return use(props.Count) > 0
			end),
			AnchorPoint = if tab then Vector2.new(0, 0) else Vector2.new(1, 0.5),
			Position = if tab then UDim2.new(0.5, 8, 0, 6) else UDim2.new(1, 0, 0.5, 0),
			Size = UDim2.fromOffset(20, 18),
			BackgroundColor3 = theme.accent,
			Text = props.Count,
			TextColor3 = theme.onAccent,
			FontFace = Theme.fonts.bold,
			TextSize = 11,
			[Children] = UI.corner(scope, Theme.radius.full),
		}
		else nil

	return scope:New "TextButton"(UI.merge(events, {
		Name = props.Name or "NavItem",
		AutoButtonColor = false,
		Text = "",
		BorderSizePixel = 0,
		LayoutOrder = props.LayoutOrder,
		Size = if tab then UDim2.new(1 / 3, 0, 1, 0) else UDim2.new(1, 0, 0, 42),
		BackgroundColor3 = theme.surfaceHigh,
		BackgroundTransparency = scope:Spring(
			scope:Computed(function(use)
				if use(selected) then return 0.0 end
				if use(pressed) then return 0.2 end
				return if use(hovering) then 0.5 else 1
			end),
			45,
			1
		),
		[Children] = {
			UI.corner(scope, Theme.radius.md),
			if tab then nil else UI.padding(scope, 0, 12),
			Label(ctx, scope, {
				Text = props.Icon,
				TextSize = if tab then 22 else 18,
				Font = Theme.fonts.bold,
				Color = tone,
				AnchorPoint = if tab then Vector2.new(0.5, 0) else Vector2.new(0, 0.5),
				Position = if tab then UDim2.new(0.5, 0, 0, 8) else UDim2.new(0, 0, 0.5, 0),
				Size = if tab then UDim2.new(1, 0, 0, 24) else UDim2.fromOffset(24, 24),
				Align = if tab then Enum.TextXAlignment.Center else Enum.TextXAlignment.Left,
			}),
			Label(ctx, scope, {
				Text = props.Text,
				Variant = if tab then "tiny" else "bodyStrong",
				Color = tone,
				AnchorPoint = if tab then Vector2.new(0.5, 1) else Vector2.new(0, 0.5),
				Position = if tab then UDim2.new(0.5, 0, 1, -6) else UDim2.new(0, 34, 0.5, 0),
				Size = if tab then UDim2.new(1, 0, 0, 14) else UDim2.new(1, -70, 0, 20),
				Align = if tab then Enum.TextXAlignment.Center else Enum.TextXAlignment.Left,
			}),
			badge,
		},
	}))
end

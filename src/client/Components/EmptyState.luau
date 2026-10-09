local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local Theme = require(Core.Theme)
local Icons = require(Core.Icons)
local UI = require(Core.UI)
local Children = Fusion.Children
-- props: Icon, Title, Message, ActionText, OnAction
local Label = require(script.Parent.Label)
local Button = require(script.Parent.Button)

return function(ctx, scope, props)
	local theme = ctx.theme
	return scope:New("Frame")({
		Name = props.Name or "EmptyState",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = props.LayoutOrder,
		[Children] = {
			UI.padding(scope, 48, 16),
			UI.list(scope, { Gap = 12, HAlign = Enum.HorizontalAlignment.Center }),
			scope:New("TextLabel")({
				Name = "Icon",
				LayoutOrder = 1,
				BackgroundColor3 = theme.surfaceHigh,
				Size = UDim2.fromOffset(64, 64),
				Text = props.Icon or Icons.bag,
				FontFace = Theme.fonts.bold,
				TextSize = 28,
				TextColor3 = theme.textMuted,
				[Children] = UI.corner(scope, Theme.radius.xl),
			}),
			Label(ctx, scope, {
				LayoutOrder = 2,
				Text = props.Title,
				Variant = "heading",
				Align = Enum.TextXAlignment.Center,
			}),
			Label(ctx, scope, {
				LayoutOrder = 3,
				Text = props.Message,
				Variant = "body",
				Color = theme.textMuted,
				Wrap = true,
				Align = Enum.TextXAlignment.Center,
			}),
			if props.ActionText
				then Button(
					ctx,
					scope,
					{ LayoutOrder = 4, Text = props.ActionText, Variant = "secondary", OnClick = props.OnAction }
				)
				else nil,
		},
	})
end

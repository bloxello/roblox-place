local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local UI = require(Core.UI)
local Children = Fusion.Children
-- props: Title, Subtitle, ActionText, OnAction
local Label = require(script.Parent.Label)
local Button = require(script.Parent.Button)

return function(ctx, scope, props)
	local theme = ctx.theme
	return scope:New "Frame" {
		Name = props.Name or "SectionHeader",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		LayoutOrder = props.LayoutOrder,
		[Children] = {
			UI.list(scope, { Direction = "Horizontal", Gap = 12, VAlign = Enum.VerticalAlignment.Center }),
			scope:New "Frame" {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, if props.ActionText then -110 else 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				[Children] = {
					UI.list(scope, { Gap = 2 }),
					Label(ctx, scope, { LayoutOrder = 1, Text = props.Title, Variant = "heading", Wrap = true }),
					if props.Subtitle
						then Label(ctx, scope, { LayoutOrder = 2, Text = props.Subtitle, Variant = "caption", Color = theme.textMuted, Wrap = true })
						else nil,
				},
			},
			if props.ActionText
				then Button(ctx, scope, { LayoutOrder = 2, Text = props.ActionText, Variant = "ghost", Size = "sm", OnClick = props.OnAction })
				else nil,
		},
	}
end

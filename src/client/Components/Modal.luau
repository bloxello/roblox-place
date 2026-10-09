local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local Theme = require(Core.Theme)
local UI = require(Core.UI)
local Children = Fusion.Children
-- Centered dialog card. props: Spec ({ title, body, confirmText, cancelText, tone })
local Label = require(script.Parent.Label)
local Button = require(script.Parent.Button)

return function(ctx, scope, props)
	local theme = ctx.theme
	local spec = props.Spec
	local shown = UI.appear(scope)
	return scope:New "Frame" {
		Name = "Dialog",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(400, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = theme.surface,
		BorderSizePixel = 0,
		[Children] = {
			UI.corner(scope, Theme.radius.xl),
			UI.stroke(scope, theme.border, 1),
			UI.padding(scope, 22),
			UI.list(scope, { Gap = 12 }),
			scope:New "UISizeConstraint" { MaxSize = Vector2.new(440, math.huge) },
			scope:New "UIScale" {
				Scale = scope:Spring(
					scope:Computed(function(use)
						return if use(shown) then 1 else 0.92
					end),
					50,
					0.8
				),
			},
			Label(ctx, scope, { LayoutOrder = 1, Text = spec.title, Variant = "heading", Wrap = true }),
			Label(ctx, scope, { LayoutOrder = 2, Text = spec.body, Variant = "body", Color = theme.textMuted, Wrap = true }),
			scope:New "Frame" {
				LayoutOrder = 3,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 44),
				[Children] = {
					UI.list(scope, {
						Direction = "Horizontal",
						Gap = 10,
						HAlign = Enum.HorizontalAlignment.Right,
						VAlign = Enum.VerticalAlignment.Bottom,
					}),
					Button(ctx, scope, {
						LayoutOrder = 1,
						Text = spec.cancelText or "Cancel",
						Variant = "secondary",
						OnClick = function()
							ctx.modal.close()
						end,
					}),
					if spec.confirmText
						then Button(ctx, scope, {
							LayoutOrder = 2,
							Text = spec.confirmText,
							Variant = spec.tone or "primary",
							OnClick = function()
								ctx.modal.confirm()
							end,
						})
						else nil,
				},
			},
		},
	}
end

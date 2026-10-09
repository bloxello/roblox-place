local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local Theme = require(Core.Theme)
local Icons = require(Core.Icons)
-- Robux price with the currency glyph. props: Amount (number or state), Size ("sm" | "md" | "lg" | "xl")
local SIZES = { sm = 13, md = 16, lg = 20, xl = 30 }
local Util = require(Core.Util)

return function(ctx, scope, props)
	local theme = ctx.theme
	local hex = theme.robux:ToHex()
	return scope:New("TextLabel")({
		Name = props.Name or "Price",
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.fromOffset(0, 0),
		RichText = true,
		FontFace = Theme.fonts.bold,
		TextSize = SIZES[props.Size or "md"],
		TextColor3 = theme.text,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = props.LayoutOrder,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		Text = scope:Computed(function(use)
			return `<font color="#{hex}">{Icons.robux}</font> {Util.formatNumber(use(props.Amount))}`
		end),
	})
end

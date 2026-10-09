local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local Theme = require(Core.Theme)
-- Themed text. Variants come from Theme.text; Color may be a Color3 or a state.
return function(ctx, scope, props)
	local style = Theme.text[props.Variant or "body"]
	local sized = props.Size ~= nil
	local size = props.Size
	local automatic = props.AutomaticSize
	if not sized then
		if props.Wrap then
			size = UDim2.fromScale(1, 0)
			automatic = automatic or Enum.AutomaticSize.Y
		else
			size = UDim2.fromScale(0, 0)
			automatic = automatic or Enum.AutomaticSize.XY
		end
	end
	return scope:New("TextLabel")({
		Name = props.Name or "Label",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Text = props.Text,
		RichText = props.RichText or false,
		TextColor3 = props.Color or ctx.theme.text,
		TextTransparency = props.Transparency or 0,
		FontFace = props.Font or style.font,
		TextSize = props.TextSize or style.size,
		LineHeight = style.line,
		TextXAlignment = props.Align or Enum.TextXAlignment.Left,
		TextYAlignment = props.VAlign or Enum.TextYAlignment.Center,
		TextWrapped = props.Wrap or props.MaxLines ~= nil or false,
		TextTruncate = if props.MaxLines or props.Truncate then Enum.TextTruncate.AtEnd else Enum.TextTruncate.None,
		MaxLines = props.MaxLines,
		Size = size,
		AutomaticSize = automatic or Enum.AutomaticSize.None,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		LayoutOrder = props.LayoutOrder,
		ZIndex = props.ZIndex,
	})
end

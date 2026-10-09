local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local Theme = require(Core.Theme)
local UI = require(Core.UI)
local Children = Fusion.Children
-- Small status pill. props: Text, Kind ("neutral" | "accent" | "success" | "warning" | "danger")
return function(ctx, scope, props)
	local theme = ctx.theme
	local kind = props.Kind or "neutral"
	local tone = if kind == "accent" then theme.accent
		elseif kind == "success" then theme.success
		elseif kind == "warning" then theme.warning
		elseif kind == "danger" then theme.danger
		else theme.textMuted
	return scope:New "TextLabel" {
		Name = props.Name or "Badge",
		BackgroundColor3 = theme.bg:Lerp(tone, 0.18),
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 22),
		Text = props.Text,
		FontFace = Theme.fonts.bold,
		TextSize = 11,
		TextColor3 = tone,
		LayoutOrder = props.LayoutOrder,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		ZIndex = props.ZIndex,
		[Children] = { UI.corner(scope, Theme.radius.full), UI.padding(scope, 0, 9) },
	}
end

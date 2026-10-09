local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local Theme = require(Core.Theme)
local Icons = require(Core.Icons)
local UI = require(Core.UI)
local Children, OnEvent = Fusion.Children, Fusion.OnEvent
local SIZES = {
	sm = { height = 30, pad = 12, text = 13 },
	md = { height = 38, pad = 16, text = 14 },
	lg = { height = 48, pad = 22, text = 16 },
}

local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)

local function colorsFor(theme, variant: string)
	if variant == "primary" then
		return {
			idle = theme.accent,
			hover = theme.accentHover,
			press = theme.accentPress,
			text = theme.onAccent,
			textHover = theme.onAccent,
			idleT = 0,
		}
	elseif variant == "success" then
		return {
			idle = theme.robux,
			hover = theme.robux:Lerp(WHITE, 0.12),
			press = theme.robux:Lerp(BLACK, 0.2),
			text = WHITE,
			textHover = WHITE,
			idleT = 0,
		}
	elseif variant == "danger" then
		return {
			idle = theme.danger,
			hover = theme.danger:Lerp(WHITE, 0.12),
			press = theme.danger:Lerp(BLACK, 0.2),
			text = BLACK,
			textHover = BLACK,
			idleT = 0,
		}
	elseif variant == "ghost" then
		return {
			idle = theme.surfaceHigh,
			hover = theme.surfaceHigh,
			press = theme.surfaceHover,
			text = theme.textMuted,
			textHover = theme.text,
			idleT = 1,
		}
	end
	return {
		idle = theme.surfaceHigh,
		hover = theme.surfaceHover,
		press = theme.border,
		text = theme.text,
		textHover = theme.text,
		idleT = 0,
		stroke = theme.border,
	}
end

-- props: Text, Icon, Variant, Size ("sm" | "md" | "lg"), OnClick, Disabled, Loading, Fill, Width
return function(ctx, scope, props)
	local theme = ctx.theme
	local size = SIZES[props.Size or "md"]
	local colors = colorsFor(theme, props.Variant or "primary")
	local hovering, pressed, events = UI.interact(scope)
	local disabled = props.Disabled or false
	local loading = props.Loading or false

	local background = scope:Spring(
		scope:Computed(function(use)
			if use(disabled) or use(loading) then
				return theme.surfaceHigh
			end
			if use(pressed) then
				return colors.press
			end
			if use(hovering) then
				return colors.hover
			end
			return colors.idle
		end),
		45,
		1
	)
	local transparency = scope:Spring(
		scope:Computed(function(use)
			if use(disabled) or use(loading) then
				return 0
			end
			if use(hovering) or use(pressed) then
				return 0
			end
			return colors.idleT
		end),
		45,
		1
	)
	local textColor = scope:Computed(function(use)
		if use(disabled) or use(loading) then
			return theme.textFaint
		end
		if use(hovering) then
			return colors.textHover
		end
		return colors.text
	end)
	local label = scope:Computed(function(use)
		if use(loading) then
			return "Please wait" .. Icons.ellipsis
		end
		local text = use(props.Text) or ""
		if props.Icon then
			return `{props.Icon}  {text}`
		end
		return text
	end)

	local dimension
	local automatic = Enum.AutomaticSize.None
	if props.Fill then
		dimension = UDim2.new(1, 0, 0, size.height)
	elseif props.Width then
		dimension = UDim2.fromOffset(props.Width, size.height)
	else
		dimension = UDim2.fromOffset(0, size.height)
		automatic = Enum.AutomaticSize.X
	end

	events[OnEvent("Activated")] = function()
		if props.OnClick and not Fusion.peek(disabled) and not Fusion.peek(loading) then
			props.OnClick()
		end
	end

	return scope:New("TextButton")(UI.merge(events, {
		Name = props.Name or "Button",
		AutoButtonColor = false,
		BorderSizePixel = 0,
		BackgroundColor3 = background,
		BackgroundTransparency = transparency,
		Text = label,
		TextColor3 = textColor,
		FontFace = Theme.fonts.semibold,
		TextSize = size.text,
		Size = dimension,
		AutomaticSize = automatic,
		LayoutOrder = props.LayoutOrder,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		Visible = props.Visible,
		ZIndex = props.ZIndex,
		[Children] = {
			UI.corner(scope, Theme.radius.md),
			if colors.stroke then UI.stroke(scope, colors.stroke, 1) else nil,
			if automatic ~= Enum.AutomaticSize.None then UI.padding(scope, 0, size.pad) else nil,
			scope:New("UIScale")({
				Scale = scope:Spring(
					scope:Computed(function(use)
						return if use(pressed) and not use(disabled) then 0.97 else 1
					end),
					40,
					0.8
				),
			}),
		},
	}))
end

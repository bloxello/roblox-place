-- Tiny helpers for the instances every component needs (corners, strokes, layouts...).
local Core = script.Parent
local Fusion = require(Core.Fusion)
local Util = require(Core.Util)
local OnEvent = Fusion.OnEvent

local UI = {}

UI.merge = Util.merge

function UI.corner(scope, radius: number)
	return scope:New("UICorner")({ CornerRadius = UDim.new(0, radius) })
end

function UI.stroke(scope, color, thickness: number?, transparency: any?)
	return scope:New("UIStroke")({
		Color = color,
		Thickness = thickness or 1,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

function UI.padding(scope, top: number, right: number?, bottom: number?, left: number?)
	right = right or top
	return scope:New("UIPadding")({
		PaddingTop = UDim.new(0, top),
		PaddingRight = UDim.new(0, right),
		PaddingBottom = UDim.new(0, bottom or top),
		PaddingLeft = UDim.new(0, left or right),
	})
end

function UI.list(scope, props)
	props = props or {}
	return scope:New("UIListLayout")({
		FillDirection = if props.Direction == "Horizontal"
			then Enum.FillDirection.Horizontal
			else Enum.FillDirection.Vertical,
		Padding = UDim.new(0, props.Gap or 0),
		HorizontalAlignment = props.HAlign or Enum.HorizontalAlignment.Left,
		VerticalAlignment = props.VAlign or Enum.VerticalAlignment.Top,
		Wraps = props.Wrap or false,
		SortOrder = props.Sort or Enum.SortOrder.LayoutOrder,
	})
end

function UI.gradient(scope, from: Color3, to: Color3, rotation: number?)
	return scope:New("UIGradient")({
		Color = ColorSequence.new(from, to),
		Rotation = rotation or 0,
	})
end

function UI.aspect(scope, ratio: number)
	return scope:New("UIAspectRatioConstraint")({ AspectRatio = ratio })
end

function UI.maxWidth(scope, width: number)
	return scope:New("UISizeConstraint")({ MaxSize = Vector2.new(width, math.huge) })
end

-- Hover/press tracking shared by every interactive component.
function UI.interact(scope)
	local hovering = scope:Value(false)
	local pressed = scope:Value(false)
	local events = {
		[OnEvent("MouseEnter")] = function()
			hovering:set(true)
		end,
		[OnEvent("MouseLeave")] = function()
			hovering:set(false)
			pressed:set(false)
		end,
		[OnEvent("MouseButton1Down")] = function()
			pressed:set(true)
		end,
		[OnEvent("MouseButton1Up")] = function()
			pressed:set(false)
		end,
	}
	return hovering, pressed, events
end

-- A boolean state that flips to true on the next frame; drives enter animations.
function UI.appear(scope, delay: number?)
	local shown = scope:Value(false)
	task.defer(function()
		if delay then
			task.wait(delay)
		end
		shown:set(true)
	end)
	return shown
end

return UI

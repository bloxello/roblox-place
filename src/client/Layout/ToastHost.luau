local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local Theme = require(Core.Theme)
local Icons = require(Core.Icons)
local UI = require(Core.UI)
local Children = Fusion.Children
local Components = script.Parent.Parent.Components
local Label = require(Components.Label)

local COLORS = { success = "success", error = "danger", info = "accent" }
local ICONS = { success = Icons.check, error = Icons.warning, info = Icons.info }

return function(ctx, scope)
	local theme = ctx.theme
	local function render(use, inner, toast)
		local tone = theme[COLORS[toast.kind] or "accent"]
		local shown = UI.appear(inner)
		task.delay(toast.duration, function()
			ctx.toasts.remove(toast.id)
		end)
		return inner:New("CanvasGroup")({
			Name = "Toast",
			LayoutOrder = toast.id,
			BackgroundColor3 = theme.surfaceHigh,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, 48),
			GroupTransparency = inner:Tween(
				inner:Computed(function(use2)
					return if use2(shown) then 0 else 1
				end),
				TweenInfo.new(0.2)
			),
			[Children] = {
				UI.corner(inner, Theme.radius.md),
				UI.stroke(inner, tone, 1, 0.5),
				inner:New("Frame")({
					Name = "Bar",
					BackgroundColor3 = tone,
					BorderSizePixel = 0,
					Size = UDim2.new(0, 4, 1, 0),
				}),
				Label(ctx, inner, {
					Text = ICONS[toast.kind] or Icons.info,
					Font = Theme.fonts.bold,
					TextSize = 18,
					Color = tone,
					Size = UDim2.fromOffset(22, 22),
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 16, 0.5, 0),
					Align = Enum.TextXAlignment.Center,
				}),
				Label(ctx, inner, {
					Text = toast.message,
					Variant = "bodyStrong",
					Size = UDim2.new(1, -56, 1, 0),
					Position = UDim2.fromOffset(46, 0),
					MaxLines = 2,
				}),
			},
		})
	end

	return scope:New("Frame")({
		Name = "ToastHost",
		BackgroundTransparency = 1,
		ZIndex = 50,
		AnchorPoint = Vector2.new(1, 1),
		Position = scope:Computed(function(use)
			local bottom = if use(ctx.compact) then Theme.layout.bottomNavHeight + 16 else 20
			return UDim2.new(1, -20, 1, -bottom)
		end),
		Size = UDim2.fromOffset(320, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		[Children] = {
			UI.list(scope, { Gap = 8, VAlign = Enum.VerticalAlignment.Bottom }),
			scope:ForValues(ctx.toasts.items, render),
		},
	})
end

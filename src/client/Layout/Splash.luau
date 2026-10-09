local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local Theme = require(Core.Theme)
local UI = require(Core.UI)
local Children = Fusion.Children
local Components = script.Parent.Parent.Components
local Label = require(Components.Label)

-- Shown before the catalog (and therefore the store theme) is available.
return function(scope, name: string?)
	local palette = Theme.palette(Color3.fromRGB(88, 101, 242))
	local ctx = { theme = palette }
	local pulse = scope:Value(0)
	local connection = game:GetService("RunService").Heartbeat:Connect(function()
		pulse:set((math.sin(os.clock() * 3) + 1) / 2)
	end)
	table.insert(scope, connection)
	return scope:New "Frame" {
		Name = "Splash",
		BackgroundColor3 = palette.bg,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 100,
		[Children] = scope:New "Frame" {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(240, 120),
			[Children] = {
				scope:New "TextLabel" {
					AnchorPoint = Vector2.new(0.5, 0),
					Position = UDim2.fromScale(0.5, 0),
					Size = UDim2.fromOffset(64, 64),
					BackgroundColor3 = palette.accent,
					Text = string.upper(string.sub(name or "B", 1, 1)),
					FontFace = Theme.fonts.heavy,
					TextSize = 32,
					TextColor3 = palette.onAccent,
					[Children] = UI.corner(scope, Theme.radius.lg),
				},
				Label(ctx, scope, {
					Text = "Loading store",
					Variant = "body",
					Color = palette.textMuted,
					AnchorPoint = Vector2.new(0.5, 0),
					Position = UDim2.new(0.5, 0, 0, 84),
					Transparency = scope:Computed(function(use)
						return 0.6 * use(pulse)
					end),
					Align = Enum.TextXAlignment.Center,
				}),
			},
		},
	}
end

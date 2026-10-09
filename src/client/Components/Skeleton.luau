local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local Theme = require(Core.Theme)
local UI = require(Core.UI)
local Children = Fusion.Children
-- Pulsing placeholder block shown while data loads.
local RunService = game:GetService("RunService")

return function(ctx, scope, props)
	local theme = ctx.theme
	local pulse = scope:Value(0)
	table.insert(
		scope,
		RunService.Heartbeat:Connect(function()
			pulse:set((math.sin(os.clock() * 3) + 1) / 2)
		end)
	)
	return scope:New("Frame")({
		Name = props.Name or "Skeleton",
		BackgroundColor3 = theme.surfaceHigh,
		BackgroundTransparency = scope:Computed(function(use)
			return 0.1 + use(pulse) * 0.45
		end),
		BorderSizePixel = 0,
		Size = props.Size or UDim2.new(1, 0, 0, 16),
		LayoutOrder = props.LayoutOrder,
		Position = props.Position,
		[Children] = UI.corner(scope, props.Radius or Theme.radius.sm),
	})
end

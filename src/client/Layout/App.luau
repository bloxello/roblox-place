local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local Theme = require(Core.Theme)
local Children = Fusion.Children
local Components = script.Parent.Parent.Components
local Sidebar = require(script.Parent.Sidebar)
local BottomNav = require(script.Parent.BottomNav)
local TopBar = require(script.Parent.TopBar)
local PageHost = require(script.Parent.PageHost)
local ToastHost = require(script.Parent.ToastHost)
local ModalHost = require(script.Parent.ModalHost)

return function(ctx, scope)
	return {
		Sidebar(ctx, scope),
		scope:New "Frame" {
			Name = "Main",
			BackgroundTransparency = 1,
			Position = scope:Computed(function(use)
				return UDim2.fromOffset(if use(ctx.compact) then 0 else Theme.layout.sidebarWidth, 0)
			end),
			Size = scope:Computed(function(use)
				return UDim2.new(1, if use(ctx.compact) then 0 else -Theme.layout.sidebarWidth, 1, 0)
			end),
			[Children] = {
				PageHost(ctx, scope),
				TopBar(ctx, scope),
				BottomNav(ctx, scope),
			},
		},
		ToastHost(ctx, scope),
		ModalHost(ctx, scope),
	}
end

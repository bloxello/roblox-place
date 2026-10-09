local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local Theme = require(Core.Theme)
local Children = Fusion.Children
local Components = script.Parent.Parent.Components
local Pages = script.Parent.Parent.Pages

local registry = {}
for _, page in Pages:GetChildren() do
	registry[page.Name] = require(page)
end

-- Rebuilds the page whenever the route changes; the old page is destroyed with its inner scope.
return function(ctx, scope)
	return scope:New("Frame")({
		Name = "PageHost",
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Position = UDim2.fromOffset(0, Theme.layout.topBarHeight),
		Size = scope:Computed(function(use)
			local reserved = Theme.layout.topBarHeight + (if use(ctx.compact) then Theme.layout.bottomNavHeight else 0)
			return UDim2.new(1, 0, 1, -reserved)
		end),
		[Children] = scope:Computed(function(use, inner)
			local route = use(ctx.router.route)
			local page = registry[route.name] or registry.Home
			return page(ctx, inner, route.params)
		end),
	})
end

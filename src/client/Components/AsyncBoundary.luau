local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local Icons = require(Core.Icons)
local Children = Fusion.Children
-- Renders Loading / Error / Ready depending on the catalog status. Returns a state for [Children].
-- props: Loading(scope) -> Instance, Ready(scope) -> Instance
local EmptyState = require(script.Parent.EmptyState)

return function(ctx, scope, props)
	return scope:Computed(function(use, inner)
		local status = use(ctx.catalog.status)
		if status == "ready" then return props.Ready(inner) end
		if status == "error" then
			return EmptyState(ctx, inner, {
				Icon = Icons.warning,
				Title = "We couldn't load this store",
				Message = use(ctx.catalog.errorMessage),
				ActionText = "Try again",
				OnAction = function()
					ctx.reload()
				end,
			})
		end
		return props.Loading(inner)
	end)
end

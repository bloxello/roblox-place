-- Minimal history-based router. Pages are looked up by name in Layout/PageHost.
local Fusion = require(script.Parent.Fusion)
local peek = Fusion.peek

local Router = {}

local MAX_HISTORY = 24

function Router.new(scope, initial: string)
	local route = scope:Value({ name = initial, params = {} })
	local canBack = scope:Value(false)
	local history = {}
	local self = { route = route, canBack = canBack }

	local function publish(next)
		route:set(next)
		canBack:set(#history > 0)
	end

	function self.navigate(name: string, params: { [string]: any }?)
		local current = peek(route)
		params = params or {}
		if current.name == name and current.params.id == params.id then return end
		table.insert(history, current)
		if #history > MAX_HISTORY then table.remove(history, 1) end
		publish({ name = name, params = params })
	end

	-- Top-level tabs reset history so Back never walks across sections.
	function self.tab(name: string)
		table.clear(history)
		publish({ name = name, params = {} })
	end

	function self.back()
		local previous = table.remove(history)
		if previous then publish(previous) end
	end

	return self
end

return Router

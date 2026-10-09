local Fusion = require(script.Parent.Parent.Core.Fusion)
local peek = Fusion.peek

local MAX_VISIBLE = 4

local ToastService = {}

function ToastService.new(scope)
	local items = scope:Value({})
	local nextId = 0
	local self = { items = items }

	function self.remove(id: number)
		local updated = {}
		for _, toast in peek(items) do
			if toast.id ~= id then table.insert(updated, toast) end
		end
		items:set(updated)
	end

	-- kind: "success" | "error" | "info"
	function self.push(kind: string, message: string, duration: number?)
		nextId += 1
		local updated = table.clone(peek(items))
		table.insert(updated, { id = nextId, kind = kind, message = message, duration = duration or 4 })
		while #updated > MAX_VISIBLE do
			table.remove(updated, 1)
		end
		items:set(updated)
		return nextId
	end

	return self
end

return ToastService

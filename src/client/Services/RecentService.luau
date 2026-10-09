-- Products the player opened this session, newest first.
local Fusion = require(script.Parent.Parent.Core.Fusion)
local Sfx = require(script.Parent.Parent.Core.Sfx)
local peek = Fusion.peek

local MAX = 8

local RecentService = {}

function RecentService.new(scope)
	local ids = scope:Value({})
	local self = { ids = ids }

	function self.add(productId: string)
		local list = { productId }
		for _, id in peek(ids) do
			if id ~= productId and #list < MAX then
				table.insert(list, id)
			end
		end
		ids:set(list)
	end

	function self.clear()
		Sfx.play("trash")
		ids:set({})
	end

	return self
end

return RecentService

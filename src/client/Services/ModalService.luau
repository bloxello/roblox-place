-- A single modal slot: open({ title, body, confirmText, cancelText, onConfirm, tone }).
local Fusion = require(script.Parent.Parent.Core.Fusion)
local Sfx = require(script.Parent.Parent.Core.Sfx)
local peek = Fusion.peek

local ModalService = {}

function ModalService.new(scope)
	local current = scope:Value(nil)
	local self = { current = current }

	function self.open(spec)
		current:set(spec)
		Sfx.play(if spec and spec.tone == "danger" then "alert" else "pop")
	end

	function self.close()
		current:set(nil)
	end

	function self.confirm()
		local spec = peek(current)
		current:set(nil)
		if spec and spec.onConfirm then
			spec.onConfirm()
		end
	end

	return self
end

return ModalService

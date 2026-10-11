local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local peek = Fusion.peek

local SupportService = {}

function SupportService.new(scope, remotes, toasts)
	local tickets = scope:Value({})
	local status = scope:Value("idle")
	local sending = scope:Value(false)
	local self = { tickets = tickets, status = status, sending = sending }

	local function invoke(remote, ...)
		local arguments = table.pack(...)
		local ok, result = pcall(function()
			return remote:InvokeServer(table.unpack(arguments, 1, arguments.n))
		end)
		if not ok or type(result) ~= "table" or result.ok ~= true then
			return nil, if ok and type(result) == "table" then result.error else "Support is unavailable right now"
		end
		return result, nil
	end

	function self.refresh()
		if peek(status) == "loading" then return end
		status:set("loading")
		task.spawn(function()
			local result, requestError = invoke(remotes.GetSupportTickets)
			if result then
				tickets:set(result.tickets or {})
				status:set("ready")
			else
				status:set("error")
				toasts.push("error", requestError or "Could not load support tickets")
			end
		end)
	end

	function self.create(subject: string, message: string, onSuccess)
		if peek(sending) then return end
		sending:set(true)
		task.spawn(function()
			local result, requestError = invoke(remotes.CreateSupportTicket, subject, message)
			sending:set(false)
			if not result then
				toasts.push("error", requestError or "Could not open ticket")
				return
			end
			toasts.push("success", "Support ticket opened")
			if onSuccess then
				onSuccess(result.ticket)
			end
			self.refresh()
		end)
	end

	function self.reply(ticketId: string, message: string, onSuccess)
		if peek(sending) then return end
		sending:set(true)
		task.spawn(function()
			local result, requestError = invoke(remotes.ReplySupportTicket, ticketId, message)
			sending:set(false)
			if not result then
				toasts.push("error", requestError or "Could not send reply")
				return
			end
			toasts.push("success", "Reply sent to the storefront")
			if onSuccess then
				onSuccess()
			end
			self.refresh()
		end)
	end

	return self
end

return SupportService

local TextService = game:GetService("TextService")
local ApiClient = require(script.Parent.ApiClient)

local SupportService = {}
local lastWrite = {}

local function filter(player, text: string, broadcast: boolean)
	local ok, result = pcall(function()
		local filtered = TextService:FilterStringAsync(text, player.UserId)
		return if broadcast then filtered:GetNonChatStringForBroadcastAsync() else filtered:GetNonChatStringForUserAsync(player.UserId)
	end)
	return if ok then result else nil
end

local function readyToWrite(player)
	local now = os.clock()
	if now - (lastWrite[player.UserId] or 0) < 2 then return false end
	lastWrite[player.UserId] = now
	return true
end

local function safeString(value, maximum: number)
	return type(value) == "string" and #value > 0 and #value <= maximum
end

function SupportService.list(player)
	local tickets, requestError = ApiClient.getSupportTickets(player.UserId)
	if not tickets then return { ok = false, error = requestError or "Could not load support tickets" } end
	-- Staff replies originate outside Roblox. Filter every user-visible string again before it reaches a client.
	for _, ticket in tickets do
		ticket.subject = filter(player, tostring(ticket.subject or "Support request"), false) or "Support request"
		ticket.requesterName = filter(player, tostring(ticket.requesterName or "Customer"), false) or "Customer"
		for _, message in ticket.messages or {} do
			message.body = filter(player, tostring(message.body or ""), false) or "[Message unavailable]"
			message.authorName = filter(player, tostring(message.authorName or "Support"), false) or "Support"
		end
	end
	return { ok = true, tickets = tickets }
end

function SupportService.create(player, subject, message)
	if not readyToWrite(player) then return { ok = false, error = "Please wait before sending another message" } end
	if not safeString(subject, 160) or #subject < 4 then return { ok = false, error = "Enter a subject with at least 4 characters" } end
	if not safeString(message, 5000) or #message < 10 then return { ok = false, error = "Enter at least 10 characters in your message" } end
	local filteredSubject = filter(player, subject, true)
	local filteredMessage = filter(player, message, true)
	if not filteredSubject or not filteredMessage then return { ok = false, error = "Roblox could not filter this message. Try different wording." } end
	local result, requestError = ApiClient.createSupportTicket(player.UserId, player.DisplayName, filteredSubject, filteredMessage)
	if not result then return { ok = false, error = requestError or "Could not open ticket" } end
	return { ok = true, ticket = result.ticket }
end

function SupportService.reply(player, ticketId, message)
	if not readyToWrite(player) then return { ok = false, error = "Please wait before sending another message" } end
	if not safeString(ticketId, 64) or not safeString(message, 5000) then return { ok = false, error = "That reply is invalid" } end
	local filteredMessage = filter(player, message, true)
	if not filteredMessage then return { ok = false, error = "Roblox could not filter this message. Try different wording." } end
	local result, requestError = ApiClient.replySupportTicket(player.UserId, player.DisplayName, ticketId, filteredMessage)
	if not result then return { ok = false, error = requestError or "Could not send reply" } end
	return { ok = true }
end

return SupportService

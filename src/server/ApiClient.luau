local HttpService = game:GetService("HttpService")
local Config = require(script.Parent.Config)

local ApiClient = {}

function ApiClient.getCatalog()
	local ok, response = pcall(function()
		return HttpService:RequestAsync({
			Url = `{Config.ApiBaseUrl}/roblox/stores/{Config.StoreId}/catalog`,
			Method = "GET",
			Headers = { ["Accept"] = "application/json" },
		})
	end)
	if not ok or not response.Success then
		return nil, if ok then `Catalog request failed ({response.StatusCode})` else tostring(response)
	end
	local decodedOk, body = pcall(HttpService.JSONDecode, HttpService, response.Body)
	if not decodedOk or type(body) ~= "table" or type(body.store) ~= "table" then
		return nil, "Catalog response was invalid"
	end
	return body, nil
end

-- Returns raw RGBA pixels (cover-cropped by the API) as a buffer plus its dimensions.
function ApiClient.getImage(kind: string, id: string?, index: number?)
	local suffix = if id then `/{HttpService:UrlEncode(id)}` else ""
	local query = if index then `?i={index}` else ""
	local ok, response = pcall(function()
		return HttpService:RequestAsync({
			Url = `{Config.ApiBaseUrl}/roblox/stores/{Config.StoreId}/image/{kind}{suffix}{query}`,
			Method = "GET",
		})
	end)
	if not ok or not response.Success then
		return nil
	end
	local width = tonumber(response.Headers["x-image-width"])
	local height = tonumber(response.Headers["x-image-height"])
	if not width or not height or #response.Body ~= width * height * 4 then
		return nil
	end
	return buffer.fromstring(response.Body), width, height
end

-- Raw (unfiltered) rating summary and latest reviews for one product.
function ApiClient.getReviews(productId: string)
	local ok, response = pcall(function()
		return HttpService:RequestAsync({
			Url = `{Config.ApiBaseUrl}/roblox/stores/{Config.StoreId}/products/{HttpService:UrlEncode(productId)}/reviews`,
			Method = "GET",
			Headers = { ["Accept"] = "application/json" },
		})
	end)
	if not ok or not response.Success then
		return nil
	end
	local decodedOk, body = pcall(HttpService.JSONDecode, HttpService, response.Body)
	if not decodedOk or type(body) ~= "table" or type(body.summary) ~= "table" or type(body.reviews) ~= "table" then
		return nil
	end
	return body
end

function ApiClient.getDeliveries(userId: number)
	local ok, response = pcall(function()
		return HttpService:RequestAsync({
			Url = `{Config.ApiBaseUrl}/roblox/deliveries/{userId}`,
			Method = "GET",
			Headers = {
				["Accept"] = "application/json",
				["Authorization"] = `Bearer {Config.HubApiKey}`,
				["X-Bloxello-Store-Id"] = Config.StoreId,
			},
		})
	end)
	if not ok or not response.Success then return nil end
	local decodedOk, body = pcall(HttpService.JSONDecode, HttpService, response.Body)
	if not decodedOk or type(body) ~= "table" or type(body.deliveries) ~= "table" then return nil end
	return body.deliveries
end

function ApiClient.reportReceipt(payload)
	local ok, response = pcall(function()
		return HttpService:RequestAsync({
			Url = `{Config.ApiBaseUrl}/roblox/receipts`,
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json",
				["Authorization"] = `Bearer {Config.HubApiKey}`,
				["X-Bloxello-Store-Id"] = Config.StoreId,
			},
			Body = HttpService:JSONEncode(payload),
		})
	end)
	if not ok or not response.Success then
		return false, if ok then `Receipt rejected ({response.StatusCode})` else tostring(response)
	end
	local decodedOk, body = pcall(HttpService.JSONDecode, HttpService, response.Body)
	return decodedOk and body.accepted == true, if decodedOk then body else "Invalid receipt response"
end

function ApiClient.redeemDiscount(userId: number, productId: string, code: string)
	local ok, response = pcall(function()
		return HttpService:RequestAsync({
			Url = `{Config.ApiBaseUrl}/roblox/discounts/redeem`,
			Method = "POST",
			Headers = { ["Accept"] = "application/json", ["Content-Type"] = "application/json", ["Authorization"] = `Bearer {Config.HubApiKey}`, ["X-Bloxello-Store-Id"] = Config.StoreId },
			Body = HttpService:JSONEncode({ robloxUserId = tostring(userId), productId = productId, code = code }),
		})
	end)
	if not ok then return nil, "Bloxello could not be reached." end
	local decodedOk, body = pcall(HttpService.JSONDecode, HttpService, response.Body)
	if not response.Success then
		return nil, if decodedOk and body.error and body.error.message then body.error.message else "That discount code could not be applied."
	end
	if not decodedOk or type(body.assetId) ~= "string" or type(body.price) ~= "number" then return nil, "The discounted purchase response was invalid." end
	return body, nil
end

function ApiClient.reportConnection()
	local ok, response = pcall(function()
		return HttpService:RequestAsync({
			Url = `{Config.ApiBaseUrl}/roblox/hub/connect`,
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json",
				["Authorization"] = `Bearer {Config.HubApiKey}`,
				["X-Bloxello-Store-Id"] = Config.StoreId,
			},
			Body = HttpService:JSONEncode({
				placeId = tostring(game.PlaceId),
				universeId = tostring(game.GameId),
			}),
		})
	end)
	if not ok then
		warn(`[Bloxello] Could not reach the API (enable HTTP requests in Game Settings > Security): {response}`)
		return false
	end
	if not response.Success then
		warn(`[Bloxello] Hub connect failed ({response.StatusCode}): {response.Body}`)
		return false
	end
	return true
end

function ApiClient.reportHubPlay(userId: number, sessionId: string)
	local ok, response = pcall(function()
		return HttpService:RequestAsync({
			Url = `{Config.ApiBaseUrl}/roblox/analytics/play`,
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json",
				["Authorization"] = `Bearer {Config.HubApiKey}`,
				["X-Bloxello-Store-Id"] = Config.StoreId,
			},
			Body = HttpService:JSONEncode({
				robloxUserId = tostring(userId),
				sessionId = sessionId,
				placeId = tostring(game.PlaceId),
				universeId = tostring(game.GameId),
			}),
		})
	end)
	return ok and response.Success
end

local function supportRequest(method: string, path: string, payload)
	local ok, response = pcall(function()
		return HttpService:RequestAsync({
			Url = `{Config.ApiBaseUrl}/roblox/support{path}`,
			Method = method,
			Headers = {
				["Accept"] = "application/json",
				["Content-Type"] = "application/json",
				["Authorization"] = `Bearer {Config.HubApiKey}`,
				["X-Bloxello-Store-Id"] = Config.StoreId,
			},
			Body = if payload then HttpService:JSONEncode(payload) else nil,
		})
	end)
	if not ok or not response.Success then
		return nil, if ok then `Support request failed ({response.StatusCode})` else tostring(response)
	end
	local decodedOk, body = pcall(HttpService.JSONDecode, HttpService, response.Body)
	if not decodedOk or type(body) ~= "table" then return nil, "Support response was invalid" end
	return body, nil
end

function ApiClient.getSupportTickets(userId: number)
	local body, requestError = supportRequest("GET", `/tickets/{userId}`, nil)
	if not body or type(body.tickets) ~= "table" then return nil, requestError or "Tickets were unavailable" end
	return body.tickets, nil
end

function ApiClient.createSupportTicket(userId: number, requesterName: string, subject: string, message: string)
	return supportRequest("POST", "/tickets", {
		robloxUserId = tostring(userId),
		requesterName = requesterName,
		subject = subject,
		category = "PRODUCT_HELP",
		message = message,
	})
end

function ApiClient.replySupportTicket(userId: number, requesterName: string, ticketId: string, message: string)
	return supportRequest("POST", `/tickets/{HttpService:UrlEncode(ticketId)}/messages`, {
		robloxUserId = tostring(userId),
		requesterName = requesterName,
		message = message,
	})
end

return ApiClient

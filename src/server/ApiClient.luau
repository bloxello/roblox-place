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
function ApiClient.getImage(kind: string, id: string?)
	local suffix = if id then `/{HttpService:UrlEncode(id)}` else ""
	local ok, response = pcall(function()
		return HttpService:RequestAsync({
			Url = `{Config.ApiBaseUrl}/roblox/stores/{Config.StoreId}/image/{kind}{suffix}`,
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
	return ok and response.Success
end

return ApiClient

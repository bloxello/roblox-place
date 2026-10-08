local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Bloxello.Config)

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

return ApiClient


local Util = {}

function Util.formatNumber(value: number): string
	local text = tostring(math.floor(value + 0.5))
	local reversed = string.reverse(text)
	reversed = string.gsub(reversed, "(%d%d%d)", "%1,")
	reversed = string.reverse(reversed)
	reversed = string.gsub(reversed, "^,", "")
	return reversed
end

function Util.compact(value: number): string
	if value >= 1e6 then return string.format("%.1fM", value / 1e6) end
	if value >= 1e3 then return string.format("%.1fK", value / 1e3) end
	return tostring(math.floor(value))
end

function Util.hexToColor(hex: any, fallback: Color3): Color3
	if type(hex) ~= "string" then return fallback end
	local ok, color = pcall(Color3.fromHex, hex)
	return if ok then color else fallback
end

function Util.luminance(color: Color3): number
	return 0.2126 * color.R + 0.7152 * color.G + 0.0722 * color.B
end

function Util.clamp(value: number, low: number, high: number): number
	return math.max(low, math.min(high, value))
end

function Util.merge(...)
	local out = {}
	for _, source in { ... } do
		for key, value in source do
			out[key] = value
		end
	end
	return out
end

function Util.plural(count: number, singular: string, plural: string?): string
	return if count == 1 then `{count} {singular}` else `{count} {plural or singular .. "s"}`
end

function Util.timeAgo(unix: number?): string
	if not unix then return "" end
	local seconds = os.time() - unix
	if seconds < 60 then return "just now" end
	local minutes = seconds // 60
	if minutes < 60 then return Util.plural(minutes, "minute") .. " ago" end
	local hours = minutes // 60
	if hours < 24 then return Util.plural(hours, "hour") .. " ago" end
	local days = hours // 24
	if days < 30 then return Util.plural(days, "day") .. " ago" end
	local months = days // 30
	if months < 12 then return Util.plural(months, "month") .. " ago" end
	return Util.plural(months // 12, "year") .. " ago"
end

function Util.parseIso(iso: any): number?
	if type(iso) ~= "string" then return nil end
	local ok, stamp = pcall(DateTime.fromIsoDate, iso)
	if ok and stamp then return stamp.UnixTimestamp end
	return nil
end

-- Roblox ImageLabels can only load Roblox-hosted content, so anything else is ignored.
function Util.robloxImage(url: any): string?
	if type(url) ~= "string" then return nil end
	if string.match(url, "^rbxassetid://%d+$") or string.match(url, "^rbxthumb://") then return url end
	local id = string.match(url, "^https?://www%.roblox%.com/asset/?%?id=(%d+)")
	if id then return `rbxassetid://{id}` end
	return nil
end

function Util.hueFor(text: string): number
	local sum = 0
	for index = 1, #text do
		sum = (sum * 31 + string.byte(text, index)) % 360
	end
	return sum / 360
end

function Util.firstLetter(text: string): string
	local letter = string.match(text, "%w")
	return if letter then string.upper(letter) else "?"
end

return Util

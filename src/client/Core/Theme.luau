-- Design tokens: palette, typography, spacing. Everything visual comes from here.
local Util = require(script.Parent.Util)

local Theme = {}

local FAMILY = "rbxasset://fonts/families/GothamSSm.json"
local function face(weight: Enum.FontWeight)
	return Font.new(FAMILY, weight)
end

Theme.fonts = {
	regular = face(Enum.FontWeight.Regular),
	medium = face(Enum.FontWeight.Medium),
	semibold = face(Enum.FontWeight.SemiBold),
	bold = face(Enum.FontWeight.Bold),
	heavy = face(Enum.FontWeight.ExtraBold),
}

Theme.text = {
	display = { size = 40, font = Theme.fonts.heavy, line = 1.05 },
	title = { size = 26, font = Theme.fonts.bold, line = 1.1 },
	heading = { size = 18, font = Theme.fonts.bold, line = 1.15 },
	subheading = { size = 15, font = Theme.fonts.semibold, line = 1.2 },
	body = { size = 14, font = Theme.fonts.regular, line = 1.3 },
	bodyStrong = { size = 14, font = Theme.fonts.semibold, line = 1.3 },
	caption = { size = 12, font = Theme.fonts.medium, line = 1.25 },
	tiny = { size = 11, font = Theme.fonts.semibold, line = 1.2 },
}

Theme.radius = { sm = 6, md = 10, lg = 14, xl = 20, full = 999 }
Theme.space = { xs = 4, sm = 8, md = 12, lg = 16, xl = 24, xxl = 32 }
Theme.layout = { sidebarWidth = 248, topBarHeight = 64, bottomNavHeight = 64, maxContent = 1200, compactBreakpoint = 760 }

local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)

function Theme.palette(accent: Color3)
	-- Keep the accent readable on dark surfaces regardless of the seller's colour.
	if Util.luminance(accent) < 0.2 then accent = accent:Lerp(WHITE, 0.4) end
	local bg = Color3.fromRGB(12, 13, 18)
	return {
		bg = bg,
		sidebar = Color3.fromRGB(16, 17, 23),
		surface = Color3.fromRGB(22, 24, 32),
		surfaceHigh = Color3.fromRGB(30, 33, 43),
		surfaceHover = Color3.fromRGB(39, 43, 55),
		border = Color3.fromRGB(44, 48, 62),
		text = Color3.fromRGB(241, 243, 248),
		textMuted = Color3.fromRGB(160, 166, 183),
		textFaint = Color3.fromRGB(106, 112, 131),
		accent = accent,
		accentHover = accent:Lerp(WHITE, 0.15),
		accentPress = accent:Lerp(BLACK, 0.2),
		accentSoft = bg:Lerp(accent, 0.2),
		onAccent = if Util.luminance(accent) > 0.55 then Color3.fromRGB(14, 15, 20) else WHITE,
		success = Color3.fromRGB(52, 211, 153),
		warning = Color3.fromRGB(251, 191, 36),
		danger = Color3.fromRGB(248, 113, 113),
		robux = Color3.fromRGB(0, 201, 125),
		overlay = Color3.fromRGB(4, 5, 8),
	}
end

return Theme

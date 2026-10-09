local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local Core = script.Parent.Parent.Core
local Theme = require(Core.Theme)
local Branding = require(Core.Branding)
local Sfx = require(Core.Sfx)

local Splash = {}

-- Returns the wordmark image content, or nil when no decal id is configured.
function Splash.wordmark(): string?
	local id = tonumber(Branding.WordmarkDecalId)
	if id and id > 0 then
		return `rbxassetid://{math.floor(id)}`
	end
	return nil
end

-- Builds the intro splash inside `gui`. Returns { finish = function() } which waits for the
-- minimum display time, then fades the splash out and removes the gui.
function Splash.show(gui: ScreenGui)
	local palette = Theme.palette(Branding.Accent)
	local startedAt = os.clock()
	local content = Splash.wordmark()

	local root = Instance.new("Frame")
	root.Name = "Splash"
	root.BackgroundColor3 = palette.bg
	root.BorderSizePixel = 0
	root.Size = UDim2.fromScale(1, 1)
	root.ZIndex = 100
	root.Parent = gui

	local glow = Instance.new("Frame")
	glow.Name = "Glow"
	glow.AnchorPoint = Vector2.new(0.5, 0.5)
	glow.Position = UDim2.fromScale(0.5, 0.45)
	glow.Size = UDim2.fromOffset(420, 420)
	glow.BackgroundColor3 = palette.accent
	glow.BackgroundTransparency = 1
	glow.BorderSizePixel = 0
	glow.ZIndex = 101
	glow.Parent = root
	Instance.new("UICorner", glow).CornerRadius = UDim.new(1, 0)

	local holder = Instance.new("Frame")
	holder.Name = "Holder"
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.Position = UDim2.fromScale(0.5, 0.45)
	holder.Size = UDim2.fromOffset(360, 120)
	holder.BackgroundTransparency = 1
	holder.ZIndex = 102
	holder.Parent = root
	local scale = Instance.new("UIScale")
	scale.Scale = 0.85
	scale.Parent = holder

	local markFade: { Instance } = {}
	local markProperty: string
	if content then
		local image = Instance.new("ImageLabel")
		image.Name = "Wordmark"
		image.BackgroundTransparency = 1
		image.Image = content
		image.ScaleType = Enum.ScaleType.Fit
		image.Size = UDim2.fromScale(1, 1)
		image.ImageTransparency = 1
		image.ZIndex = 103
		image.Parent = holder
		table.insert(markFade, image)
		markProperty = "ImageTransparency"
		task.spawn(function()
			pcall(ContentProvider.PreloadAsync, ContentProvider, { image })
		end)
	else
		local text = Instance.new("TextLabel")
		text.Name = "Wordmark"
		text.BackgroundTransparency = 1
		text.Size = UDim2.fromScale(1, 1)
		text.Text = "bloxello"
		text.FontFace = Theme.fonts.heavy
		text.TextSize = 72
		text.TextColor3 = palette.text
		text.TextTransparency = 1
		text.ZIndex = 103
		text.Parent = holder
		table.insert(markFade, text)
		markProperty = "TextTransparency"
	end

	local tagline = Instance.new("TextLabel")
	tagline.Name = "Tagline"
	tagline.AnchorPoint = Vector2.new(0.5, 0)
	tagline.Position = UDim2.new(0.5, 0, 0.45, 86)
	tagline.Size = UDim2.fromOffset(420, 24)
	tagline.BackgroundTransparency = 1
	tagline.Text = Branding.Tagline
	tagline.FontFace = Theme.fonts.medium
	tagline.TextSize = 16
	tagline.TextColor3 = palette.textMuted
	tagline.TextTransparency = 1
	tagline.ZIndex = 102
	tagline.Parent = root

	local track = Instance.new("Frame")
	track.Name = "ProgressTrack"
	track.AnchorPoint = Vector2.new(0.5, 0)
	track.Position = UDim2.new(0.5, 0, 0.45, 130)
	track.Size = UDim2.fromOffset(180, 4)
	track.BackgroundColor3 = palette.surfaceHigh
	track.BackgroundTransparency = 1
	track.BorderSizePixel = 0
	track.ZIndex = 102
	track.Parent = root
	Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
	local bar = Instance.new("Frame")
	bar.Name = "Bar"
	bar.Size = UDim2.fromScale(0, 1)
	bar.BackgroundColor3 = palette.accent
	bar.BorderSizePixel = 0
	bar.ZIndex = 103
	bar.Parent = track
	Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)

	local function tween(instance: Instance, info: TweenInfo, goal)
		TweenService:Create(instance, info, goal):Play()
	end

	local intro = TweenInfo.new(0.7, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	tween(scale, intro, { Scale = 1 })
	tween(glow, TweenInfo.new(1.2, Enum.EasingStyle.Sine), {
		BackgroundTransparency = 0.88,
		Size = UDim2.fromOffset(560, 560),
	})
	for _, instance in markFade do
		tween(instance, intro, { [markProperty] = 0 })
	end
	tween(tagline, intro, { TextTransparency = 0.15 })
	tween(track, intro, { BackgroundTransparency = 0 })
	-- The bar eases toward 90% while loading, then completes on finish.
	tween(bar, TweenInfo.new(Branding.SplashMinSeconds, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		Size = UDim2.fromScale(0.9, 1),
	})

	local self = {}
	function self.finish()
		local remaining = Branding.SplashMinSeconds - (os.clock() - startedAt)
		if remaining > 0 then
			task.wait(remaining)
		end
		tween(bar, TweenInfo.new(0.25), { Size = UDim2.fromScale(1, 1) })
		task.wait(0.3)
		local out = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		Sfx.play("swoosh")
		tween(scale, out, { Scale = 1.08 })
		tween(root, out, { BackgroundTransparency = 1 })
		tween(glow, out, { BackgroundTransparency = 1 })
		tween(track, out, { BackgroundTransparency = 1 })
		tween(bar, out, { BackgroundTransparency = 1 })
		tween(tagline, out, { TextTransparency = 1 })
		for _, instance in markFade do
			tween(instance, out, { [markProperty] = 1 })
		end
		task.wait(0.55)
		gui:Destroy()
	end
	return self
end

return Splash

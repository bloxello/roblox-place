-- UI sound effects. Replace the ids here to retune the hub; set an id to 0 to mute that sound.
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")

local SOUNDS = {
	hover = { id = 107511012621133, volume = 0.25 },
	click = { id = 6895079853, volume = 0.5 },
	pop = { id = 72264591133889, volume = 0.5 },
	notify = { id = 135869563808171, volume = 0.5 },
	alert = { id = 15675055424, volume = 0.5 },
	purchase = { id = 10066947742, volume = 0.6 },
	trash = { id = 15675075163, volume = 0.5 },
	appear = { id = 10066968815, volume = 0.35 },
	swoosh = { id = 121730291891328, volume = 0.4 },
}

local MIN_GAP = 0.04

local Sfx = {}

local group = Instance.new("SoundGroup")
group.Name = "BloxelloSfx"
group.Volume = 1
group.Parent = SoundService

local sounds: { [string]: Sound } = {}
local lastPlayed: { [string]: number } = {}
for name, spec in SOUNDS do
	if spec.id ~= 0 then
		local sound = Instance.new("Sound")
		sound.Name = name
		sound.SoundId = `rbxassetid://{spec.id}`
		sound.Volume = spec.volume
		sound.SoundGroup = group
		sound.Parent = group
		sounds[name] = sound
	end
end

task.spawn(function()
	pcall(ContentProvider.PreloadAsync, ContentProvider, group:GetChildren())
end)

function Sfx.play(name: string)
	local sound = sounds[name]
	if not sound then
		return
	end
	local now = os.clock()
	if now - (lastPlayed[name] or 0) < MIN_GAP then
		return
	end
	lastPlayed[name] = now
	-- Clone so rapid repeats overlap instead of cutting each other off.
	local copy = sound:Clone()
	copy.Parent = group
	copy.Ended:Once(function()
		copy:Destroy()
	end)
	copy:Play()
end

return Sfx

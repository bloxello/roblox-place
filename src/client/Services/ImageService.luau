--# selene: allow(undefined_variable)
-- Draws server-delivered pixel data with EditableImage, so any hosted image can be shown in-experience.
local AssetService = game:GetService("AssetService")

local MAX_CONCURRENT = 3

local ImageService = {}

function ImageService.new(scope, remotes)
	local self = {}
	local states = {}
	local images = {}
	local queue = {}
	local active = 0

	local function build(kind: string, id: string?)
		local ok, pixels, width, height = pcall(function()
			return remotes.GetImage:InvokeServer(kind, id)
		end)
		if not ok or typeof(pixels) ~= "buffer" or type(width) ~= "number" or type(height) ~= "number" then
			return nil
		end
		if buffer.len(pixels) ~= width * height * 4 then
			return nil
		end
		local created, image = pcall(function()
			local editable = AssetService:CreateEditableImage({ Size = Vector2.new(width, height) })
			editable:WritePixelsBuffer(Vector2.zero, Vector2.new(width, height), pixels)
			return editable
		end)
		return if created then image else nil
	end

	local function pump()
		while active < MAX_CONCURRENT and #queue > 0 do
			local job = table.remove(queue, 1)
			active += 1
			task.spawn(function()
				local image = build(job.kind, job.id)
				if image then
					table.insert(images, image)
					job.state:set(Content.fromObject(image))
				end
				active -= 1
				pump()
			end)
		end
	end

	-- Returns a state holding Content.none until the pixels arrive (and forever if they never do).
	function self.of(kind: string, id: string?)
		local key = `{kind}:{id or ""}`
		local state = states[key]
		if state then
			return state
		end
		state = scope:Value(Content.none)
		states[key] = state
		table.insert(queue, { kind = kind, id = id, key = key, state = state })
		pump()
		return state
	end

	function self.product(entry)
		if not entry.hasImage then
			return nil
		end
		return self.of("product", entry.id)
	end

	table.insert(scope, function()
		for _, image in images do
			image:Destroy()
		end
	end)
	return self
end

return ImageService

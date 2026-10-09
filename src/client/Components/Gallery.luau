local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local Theme = require(Core.Theme)
local Icons = require(Core.Icons)
local UI = require(Core.UI)
local Children, OnEvent = Fusion.Children, Fusion.OnEvent
-- Product media viewer: the cover art followed by uploaded gallery images, with arrows and a thumbnail strip.
-- props: Product
local RemoteImage = require(script.Parent.RemoteImage)
local Thumbnail = require(script.Parent.Thumbnail)
local IconButton = require(script.Parent.IconButton)
local Label = require(script.Parent.Label)
local Util = require(Core.Util)
local Sfx = require(Core.Sfx)

local TILE_WIDTH, TILE_HEIGHT = 76, 43

return function(ctx, scope, props)
	local theme = ctx.theme
	local product = props.Product
	local total = 1 + product.galleryCount
	local index = scope:Value(1)

	local function go(step: number)
		local nextIndex = (Fusion.peek(index) - 1 + step) % total + 1
		index:set(nextIndex)
		Sfx.play("swoosh")
		-- Warm the slide after this one so it is ready when the player flips again.
		ctx.images.gallery(product, nextIndex % total)
	end

	-- Slide 1 is the cover; slide n+1 is gallery image n.
	local function slide(inner, position: number, size, radius)
		if position == 1 then
			return Thumbnail(ctx, inner, {
				Product = product,
				Size = size,
				Radius = radius,
			})
		end
		return RemoteImage(ctx, inner, {
			Content = ctx.images.gallery(product, position - 1),
			Size = size,
			Radius = radius,
		})
	end

	-- Height is derived from the measured width; aspect ratios inside AutomaticSize parents collapse to zero.
	local width = scope:Value(0)
	local hue = Util.hueFor(product.id)
	local viewer = scope:New("Frame")({
		Name = "Viewer",
		LayoutOrder = 1,
		BackgroundColor3 = Color3.fromHSV(hue, 0.55, 0.42),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		Size = scope:Computed(function(use)
			return UDim2.new(1, 0, 0, math.floor(use(width) * 9 / 16))
		end),
		[Children] = {
			UI.corner(scope, Theme.radius.xl),
			UI.stroke(scope, theme.border, 1),
			UI.gradient(scope, Color3.fromHSV(hue, 0.55, 0.42), Color3.fromHSV((hue + 0.08) % 1, 0.6, 0.22), 135),
			scope:Computed(function(use, inner)
				local position = use(index)
				if position == 1 then
					-- The square cover sits centred so it is never cropped.
					return Thumbnail(ctx, inner, {
						Product = product,
						Size = UDim2.fromScale(1, 1),
						Ratio = 1,
						Position = UDim2.fromScale(0.5, 0.5),
						AnchorPoint = Vector2.new(0.5, 0.5),
						Radius = Theme.radius.lg,
					})
				end
				return RemoteImage(ctx, inner, {
					Name = "Slide",
					Content = ctx.images.gallery(product, position - 1),
					ScaleType = Enum.ScaleType.Crop,
				})
			end),
			if total > 1
				then IconButton(ctx, scope, {
					Name = "Previous",
					Icon = Icons.back,
					Variant = "overlay",
					Dimension = 36,
					TextSize = 26,
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 10, 0.5, 0),
					ZIndex = 10,
					OnClick = function()
						go(-1)
					end,
				})
				else nil,
			if total > 1
				then IconButton(ctx, scope, {
					Name = "Next",
					Icon = Icons.next,
					Variant = "overlay",
					Dimension = 36,
					TextSize = 26,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -10, 0.5, 0),
					ZIndex = 10,
					OnClick = function()
						go(1)
					end,
				})
				else nil,
			if total > 1
				then scope:New("Frame")({
					Name = "Counter",
					BackgroundColor3 = theme.overlay,
					BackgroundTransparency = 0.3,
					BorderSizePixel = 0,
					AutomaticSize = Enum.AutomaticSize.XY,
					AnchorPoint = Vector2.new(1, 1),
					Position = UDim2.new(1, -10, 1, -10),
					ZIndex = 10,
					[Children] = {
						UI.corner(scope, Theme.radius.full),
						UI.padding(scope, 3, 10),
						Label(ctx, scope, {
							Text = scope:Computed(function(use)
								return `{use(index)} / {total}`
							end),
							Variant = "tiny",
							ZIndex = 11,
						}),
					},
				})
				else nil,
		},
	})

	local tiles = {}
	if total > 1 then
		for position = 1, total do
			local selected = scope:Computed(function(use)
				return use(index) == position
			end)
			local hovering, _, events = UI.interact(scope)
			events[OnEvent("Activated")] = function()
				index:set(position)
			end
			tiles[position] = scope:New("TextButton")(UI.merge(events, {
				Name = `Tile{position}`,
				LayoutOrder = position,
				AutoButtonColor = false,
				Text = "",
				BackgroundColor3 = theme.surfaceHigh,
				BorderSizePixel = 0,
				ClipsDescendants = true,
				Size = UDim2.fromOffset(TILE_WIDTH, TILE_HEIGHT),
				[Children] = {
					UI.corner(scope, Theme.radius.sm),
					slide(scope, position, UDim2.fromScale(1, 1), 0),
					scope:New("Frame")({
						Name = "Dim",
						BackgroundColor3 = theme.overlay,
						BackgroundTransparency = scope:Spring(
							scope:Computed(function(use)
								if use(selected) then
									return 1
								end
								return if use(hovering) then 0.55 else 0.4
							end),
							45,
							1
						),
						BorderSizePixel = 0,
						Size = UDim2.fromScale(1, 1),
						ZIndex = 5,
					}),
					scope:New("UIStroke")({
						Thickness = 2,
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
						Color = theme.accent,
						Transparency = scope:Spring(
							scope:Computed(function(use)
								return if use(selected) then 0 else 1
							end),
							45,
							1
						),
					}),
				},
			}))
		end
	end

	return scope:New("Frame")({
		Name = "Gallery",
		LayoutOrder = props.LayoutOrder,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		[Fusion.OnChange("AbsoluteSize")] = function(size)
			width:set(size.X)
		end,
		[Children] = {
			UI.list(scope, { Gap = 10 }),
			viewer,
			if total > 1
				then scope:New("Frame")({
					Name = "Strip",
					LayoutOrder = 2,
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 0),
					AutomaticSize = Enum.AutomaticSize.Y,
					[Children] = { UI.list(scope, { Direction = "Horizontal", Gap = 8, Wrap = true }), tiles },
				})
				else nil,
		},
	})
end

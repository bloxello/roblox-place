local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local Theme = require(Core.Theme)
local UI = require(Core.UI)
local Util = require(Core.Util)
local Children = Fusion.Children
-- Read-only reviews. Text arrives already filtered by the server (Roblox text filtering).
-- props: Details (state: { status = "loading" | "ready" | "error", data = details? })
local Label = require(script.Parent.Label)
local Panel = require(script.Parent.Panel)
local Skeleton = require(script.Parent.Skeleton)

local function distribution(ctx, scope, reviews)
	local theme = ctx.theme
	local rows = {}
	local peak = 1
	for star = 1, 5 do
		peak = math.max(peak, reviews.distribution[star])
	end
	for star = 5, 1, -1 do
		local share = reviews.distribution[star] / peak
		table.insert(
			rows,
			scope:New("Frame")({
				Name = `Bar{star}`,
				LayoutOrder = 6 - star,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 16),
				[Children] = {
					UI.list(scope, { Direction = "Horizontal", Gap = 8, VAlign = Enum.VerticalAlignment.Center }),
					Label(ctx, scope, {
						LayoutOrder = 1,
						Text = tostring(star),
						Variant = "caption",
						Color = theme.textMuted,
						Size = UDim2.fromOffset(10, 14),
					}),
					scope:New("Frame")({
						Name = "Track",
						LayoutOrder = 2,
						BackgroundColor3 = theme.surfaceHigh,
						BorderSizePixel = 0,
						Size = UDim2.new(1, -62, 0, 8),
						[Children] = {
							UI.corner(scope, Theme.radius.full),
							scope:New("Frame")({
								Name = "Fill",
								BackgroundColor3 = theme.warning,
								BorderSizePixel = 0,
								Size = UDim2.fromScale(share, 1),
								[Children] = UI.corner(scope, Theme.radius.full),
							}),
						},
					}),
					Label(ctx, scope, {
						LayoutOrder = 3,
						Text = Util.compact(reviews.distribution[star]),
						Variant = "caption",
						Color = theme.textFaint,
						Size = UDim2.fromOffset(28, 14),
						Align = Enum.TextXAlignment.Right,
					}),
				},
			})
		)
	end
	return rows
end

local function summary(ctx, scope, reviews)
	local theme = ctx.theme
	return scope:New("Frame")({
		Name = "Summary",
		LayoutOrder = 1,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		[Children] = {
			UI.list(scope, { Direction = "Horizontal", Gap = 18, VAlign = Enum.VerticalAlignment.Center }),
			scope:New("Frame")({
				LayoutOrder = 1,
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(104, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				[Children] = {
					UI.list(scope, { Gap = 2, HAlign = Enum.HorizontalAlignment.Center }),
					Label(ctx, scope, {
						LayoutOrder = 1,
						Text = string.format("%.1f", reviews.average),
						Variant = "display",
					}),
					Label(ctx, scope, {
						LayoutOrder = 2,
						Text = Util.stars(reviews.average),
						Variant = "subheading",
						Color = theme.warning,
					}),
					Label(ctx, scope, {
						LayoutOrder = 3,
						Text = Util.plural(reviews.count, "review"),
						Variant = "caption",
						Color = theme.textMuted,
					}),
				},
			}),
			scope:New("Frame")({
				LayoutOrder = 2,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, -122, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				[Children] = { UI.list(scope, { Gap = 4 }), distribution(ctx, scope, reviews) },
			}),
		},
	})
end

local function reviewCard(ctx, scope, review, order: number)
	local theme = ctx.theme
	return Panel(ctx, scope, {
		Name = "Review",
		LayoutOrder = order,
		Color = theme.surfaceHigh,
		Stroke = false,
		Radius = Theme.radius.md,
		Padding = 12,
		List = { Gap = 6 },
		Children = {
			scope:New("Frame")({
				LayoutOrder = 1,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 18),
				[Children] = {
					Label(ctx, scope, {
						Text = review.author,
						Variant = "bodyStrong",
						Size = UDim2.new(1, -90, 1, 0),
						Truncate = true,
					}),
					Label(ctx, scope, {
						Text = Util.stars(review.rating),
						Variant = "caption",
						Color = theme.warning,
						AnchorPoint = Vector2.new(1, 0.5),
						Position = UDim2.fromScale(1, 0.5),
						Align = Enum.TextXAlignment.Right,
					}),
				},
			}),
			if review.createdAt
				then Label(ctx, scope, {
					LayoutOrder = 2,
					Text = Util.timeAgo(review.createdAt),
					Variant = "tiny",
					Color = theme.textFaint,
				})
				else nil,
			Label(ctx, scope, {
				LayoutOrder = 3,
				Text = if review.body and review.body ~= "" then review.body else "No written review.",
				Variant = if review.body and review.body ~= "" then "body" else "caption",
				Color = if review.body and review.body ~= "" then theme.textMuted else theme.textFaint,
				Wrap = true,
			}),
		},
	})
end

return function(ctx, scope, props)
	local theme = ctx.theme

	local body = scope:Computed(function(use, inner)
		local state = use(props.Details)
		if state.status == "loading" then
			return {
				Skeleton(ctx, inner, { LayoutOrder = 1, Size = UDim2.new(0.5, 0, 0, 18) }),
				Skeleton(ctx, inner, { LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 64), Radius = Theme.radius.md }),
				Skeleton(ctx, inner, { LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 64), Radius = Theme.radius.md }),
			}
		end
		local reviews = state.data and state.data.reviews
		if state.status == "error" or not reviews then
			return Label(ctx, inner, {
				LayoutOrder = 1,
				Text = "Reviews couldn't be loaded right now.",
				Variant = "body",
				Color = theme.textMuted,
				Wrap = true,
			})
		end
		if reviews.count == 0 or #reviews.items == 0 then
			return Label(ctx, inner, {
				LayoutOrder = 1,
				Text = "No reviews yet. Verified buyers can leave reviews on Bloxello.",
				Variant = "body",
				Color = theme.textMuted,
				Wrap = true,
			})
		end
		local out = { summary(ctx, inner, reviews) }
		for index, review in reviews.items do
			table.insert(out, reviewCard(ctx, inner, review, index + 1))
		end
		if reviews.count > #reviews.items then
			table.insert(
				out,
				Label(ctx, inner, {
					LayoutOrder = #reviews.items + 2,
					Text = `Showing the {#reviews.items} most recent reviews.`,
					Variant = "caption",
					Color = theme.textFaint,
				})
			)
		end
		return out
	end)

	return Panel(ctx, scope, {
		Name = "Reviews",
		LayoutOrder = props.LayoutOrder,
		Padding = 18,
		List = { Gap = 12 },
		Children = {
			Label(ctx, scope, { LayoutOrder = 0, Text = "Reviews", Variant = "subheading" }),
			scope:New("Frame")({
				Name = "Body",
				LayoutOrder = 1,
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				[Children] = { UI.list(scope, { Gap = 10 }), body },
			}),
			Label(ctx, scope, {
				LayoutOrder = 2,
				Text = "Read-only. Review text is filtered for Roblox.",
				Variant = "caption",
				Color = theme.textFaint,
				Wrap = true,
			}),
		},
	})
end

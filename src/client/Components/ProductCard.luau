local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local Theme = require(Core.Theme)
local UI = require(Core.UI)
local Children, OnEvent = Fusion.Children, Fusion.OnEvent
-- Fixed-height card used inside ResponsiveGrid. See ProductCard.heightFor.
local Label = require(script.Parent.Label)
local Price = require(script.Parent.Price)
local Badge = require(script.Parent.Badge)
local Thumbnail = require(script.Parent.Thumbnail)
local SaveButton = require(script.Parent.SaveButton)
local BuyButton = require(script.Parent.BuyButton)

local INFO_HEIGHT = 146
local RATIO = 1.6

local function ProductCard(ctx, scope, props)
	local theme = ctx.theme
	local product = props.Product
	local hovering, pressed, events = UI.interact(scope)
	local price = ctx.prices.priceOf(scope, product)
	local category = product.categories[1]
	events[OnEvent("Activated")] = function()
		ctx.router.navigate("Product", { id = product.id })
	end

	return scope:New("TextButton")(UI.merge(events, {
		Name = "ProductCard",
		AutoButtonColor = false,
		Text = "",
		BackgroundColor3 = scope:Spring(
			scope:Computed(function(use)
				return if use(hovering) then theme.surfaceHigh else theme.surface
			end),
			45,
			1
		),
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		LayoutOrder = props.LayoutOrder,
		ClipsDescendants = true,
		[Children] = {
			UI.corner(scope, Theme.radius.lg),
			scope:New("UIStroke")({
				Thickness = 1,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = scope:Spring(
					scope:Computed(function(use)
						return if use(hovering) then theme.accent else theme.border
					end),
					45,
					1
				),
			}),
			scope:New("UIScale")({
				Scale = scope:Spring(
					scope:Computed(function(use)
						if use(pressed) then
							return 0.98
						end
						return if use(hovering) then 1.012 else 1
					end),
					40,
					0.8
				),
			}),
			UI.list(scope, {}),
			scope:New("Frame")({
				Name = "Media",
				LayoutOrder = 1,
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 0),
				[Children] = {
					UI.aspect(scope, RATIO),
					Thumbnail(ctx, scope, { Product = product, Size = UDim2.fromScale(1, 1), Radius = 0 }),
					SaveButton(ctx, scope, {
						Product = product,
						AnchorPoint = Vector2.new(1, 0),
						Position = UDim2.new(1, -8, 0, 8),
						ZIndex = 5,
					}),
					if product.kind == "pass"
						then Badge(
							ctx,
							scope,
							{ Text = "GAME PASS", Kind = "accent", Position = UDim2.fromOffset(8, 8), ZIndex = 5 }
						)
						else nil,
				},
			}),
			scope:New("Frame")({
				Name = "Info",
				LayoutOrder = 2,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, INFO_HEIGHT),
				[Children] = {
					UI.padding(scope, 12),
					UI.list(scope, { Gap = 6 }),
					Label(ctx, scope, {
						LayoutOrder = 1,
						Text = if category then string.upper(category.name) else "ITEM",
						Variant = "tiny",
						Color = theme.accent,
						Size = UDim2.new(1, 0, 0, 14),
						Truncate = true,
					}),
					Label(ctx, scope, {
						LayoutOrder = 2,
						Text = product.name,
						Variant = "bodyStrong",
						TextSize = 15,
						Size = UDim2.new(1, 0, 0, 18),
						Truncate = true,
					}),
					Label(ctx, scope, {
						LayoutOrder = 3,
						Text = if product.summary ~= "" then product.summary else "No description yet.",
						Variant = "caption",
						Color = theme.textMuted,
						Size = UDim2.new(1, 0, 0, 30),
						MaxLines = 2,
						VAlign = Enum.TextYAlignment.Top,
					}),
					scope:New("Frame")({
						Name = "Footer",
						LayoutOrder = 4,
						BackgroundTransparency = 1,
						Size = UDim2.new(1, 0, 0, 32),
						[Children] = {
							Price(
								ctx,
								scope,
								{
									Amount = price,
									Size = "md",
									AnchorPoint = Vector2.new(0, 0.5),
									Position = UDim2.fromScale(0, 0.5),
								}
							),
							scope:New("Frame")({
								BackgroundTransparency = 1,
								AutomaticSize = Enum.AutomaticSize.X,
								Size = UDim2.fromOffset(0, 30),
								AnchorPoint = Vector2.new(1, 0.5),
								Position = UDim2.fromScale(1, 0.5),
								[Children] = {
									UI.list(
										scope,
										{ Direction = "Horizontal", VAlign = Enum.VerticalAlignment.Center }
									),
									BuyButton(ctx, scope, { Product = product }),
								},
							}),
						},
					}),
				},
			}),
		},
	}))
end

-- Total card height for a given card width.
local function heightFor(width: number): number
	return math.floor(width / RATIO) + INFO_HEIGHT
end

return setmetatable({
	heightFor = heightFor,
}, {
	__call = function(_, ctx, scope, props)
		return ProductCard(ctx, scope, props)
	end,
})

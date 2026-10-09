local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local Theme = require(Core.Theme)
local Icons = require(Core.Icons)
local Children = Fusion.Children
local Components = script.Parent.Parent.Components
local Label = require(Components.Label)
local IconButton = require(Components.IconButton)
local SearchBar = require(Components.SearchBar)
local Nav = require(script.Parent.Nav)

return function(ctx, scope)
	local theme = ctx.theme
	local backWidth = scope:Computed(function(use)
		return if use(ctx.router.canBack) then 44 else 0
	end)

	-- Typing in the global search jumps to Browse so results are visible.
	local observer = scope:Observer(ctx.browse.query)
	table.insert(
		scope,
		observer:onChange(function()
			local route = Fusion.peek(ctx.router.route)
			if route.name ~= "Browse" and Fusion.peek(ctx.browse.query) ~= "" then
				ctx.router.navigate("Browse")
			end
		end)
	)

	return scope:New "Frame" {
		Name = "TopBar",
		BackgroundColor3 = theme.bg,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, Theme.layout.topBarHeight),
		ZIndex = 5,
		[Children] = {
			scope:New "Frame" {
				Name = "Divider",
				BackgroundColor3 = theme.border,
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.fromScale(0, 1),
				Size = UDim2.new(1, 0, 0, 1),
			},
			IconButton(ctx, scope, {
				Name = "Back",
				Icon = Icons.back,
				TextSize = 26,
				Dimension = 38,
				Variant = "surface",
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 16, 0.5, 0),
				Visible = ctx.router.canBack,
				OnClick = function()
					ctx.router.back()
				end,
			}),
			Label(ctx, scope, {
				Name = "Title",
				Text = scope:Computed(function(use)
					return Nav.titles[use(ctx.router.route).name] or ""
				end),
				Variant = "title",
				TextSize = 22,
				Visible = nil,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = scope:Computed(function(use)
					return UDim2.new(0, 20 + use(backWidth), 0.5, 0)
				end),
			}),
			SearchBar(ctx, scope, {
				Value = ctx.browse.query,
				Placeholder = "Search items",
				Height = 40,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -16, 0.5, 0),
				Size = scope:Computed(function(use)
					if use(ctx.compact) then
						local reserved = 32 + use(backWidth)
						return UDim2.new(1, -reserved - 4, 0, 40)
					end
					return UDim2.fromOffset(320, 40)
				end),
			}),
		},
	}
end

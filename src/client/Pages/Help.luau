local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local UI = require(Core.UI)
local Util = require(Core.Util)
local Children = Fusion.Children
local Components = script.Parent.Parent.Components
local PageShell = require(Components.PageShell)
local ScrollArea = require(Components.ScrollArea)
local SectionHeader = require(Components.SectionHeader)
local Panel = require(Components.Panel)
local Label = require(Components.Label)
local InfoRow = require(Components.InfoRow)

local FAQ = {
	{ "What is Bloxello?", "Bloxello is a hub for buying Roblox developer assets: game passes and developer products made by creators. It does not sell or give away Robux, and it is not a Robux generator." },
	{ "How do I buy an item?", "Open an item and press Buy. Roblox shows its own purchase prompt, and you confirm it with your own Robux. Bloxello never asks for your password." },
	{ "Where do my purchases go?", "Items you buy are listed under My items, right here in the experience. The Hub never shows links, files or keys. Whatever the creator includes with a purchase is handled by the creator through the Bloxello platform." },
	{ "What does the heart do?", "It saves the item to your wishlist so you can find it again under Saved." },
	{ "Prices look wrong or out of date", "Prices refresh automatically. If something still looks off, reopen the experience." },
}

return function(ctx, scope)
	local theme = ctx.theme
	local children = {
		SectionHeader(ctx, scope, { Title = "Help", Subtitle = "Answers to common questions" }),
		Panel(ctx, scope, {
			Name = "StoreInfo",
			Padding = 16,
			List = { Gap = 6 },
			Children = {
				InfoRow(ctx, scope, {
					LayoutOrder = 1,
					Label = "Store",
					Value = scope:Computed(function(use)
						return use(ctx.catalog.store).name or "Store"
					end),
				}),
				InfoRow(ctx, scope, {
					LayoutOrder = 2,
					Label = "Items",
					Value = scope:Computed(function(use)
						return Util.formatNumber(#use(ctx.catalog.products))
					end),
				}),
				InfoRow(ctx, scope, {
					LayoutOrder = 3,
					Label = "Saved",
					Value = scope:Computed(function(use)
						local count = 0
						for _ in use(ctx.wishlist.set) do
							count += 1
						end
						return Util.formatNumber(count)
					end),
				}),
			},
		}),
	}
	for index, entry in FAQ do
		table.insert(
			children,
			Panel(ctx, scope, {
				Name = "Faq",
				Padding = 16,
				List = { Gap = 6 },
				Children = {
					Label(ctx, scope, { LayoutOrder = 1, Text = entry[1], Variant = "bodyStrong", Wrap = true }),
					Label(ctx, scope, {
						LayoutOrder = 2,
						Text = entry[2],
						Variant = "body",
						Color = theme.textMuted,
						Wrap = true,
					}),
				},
			})
		)
	end
	for index, child in children do
		if index > 2 then child.LayoutOrder = index end
	end
	children[1].LayoutOrder = 1
	children[2].LayoutOrder = 2

	return PageShell(ctx, scope, {
		Name = "Help",
		Children = ScrollArea(ctx, scope, { Children = children }),
	})
end

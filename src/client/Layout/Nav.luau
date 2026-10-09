local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local Components = script.Parent.Parent.Components
local Icons = require(Core.Icons)

-- Top-level destinations, shared by the sidebar and bottom bar.
return {
	items = {
		{ name = "Home", label = "Home", icon = Icons.home },
		{ name = "Browse", label = "Browse", icon = Icons.browse },
		{ name = "Saved", label = "Saved", icon = Icons.heart },
		{ name = "Library", label = "My items", icon = Icons.bag },
		{ name = "Help", label = "Help", icon = Icons.info },
	},
	-- Detail pages highlight the tab they belong to.
	tabFor = { Home = "Home", Browse = "Browse", Product = "Browse", Saved = "Saved", Library = "Library", Help = "Help" },
	titles = {
		Home = "Home",
		Browse = "Browse items",
		Product = "Item details",
		Saved = "Saved items",
		Library = "My items",
		Help = "Help",
	},
}

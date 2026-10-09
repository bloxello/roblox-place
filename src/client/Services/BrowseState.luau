-- Search / category / price / sort state shared by Home and Browse.
local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local peek = Fusion.peek

local BrowseState = {}

BrowseState.sorts = {
	{ id = "featured", label = "Featured" },
	{ id = "popular", label = "Most saved" },
	{ id = "newest", label = "Newest" },
	{ id = "priceAsc", label = "Price: low to high" },
	{ id = "priceDesc", label = "Price: high to low" },
	{ id = "name", label = "Name: A to Z" },
}

BrowseState.bands = {
	{ id = "any", label = "Any price", min = 0, max = math.huge },
	{ id = "low", label = "Under 100", min = 0, max = 99 },
	{ id = "mid", label = "100 - 499", min = 100, max = 499 },
	{ id = "high", label = "500 - 1,999", min = 500, max = 1999 },
	{ id = "premium", label = "2,000+", min = 2000, max = math.huge },
}

local function bandFor(id: string)
	for _, band in BrowseState.bands do
		if band.id == id then
			return band
		end
	end
	return BrowseState.bands[1]
end

function BrowseState.new(scope, catalog, prices)
	local query = scope:Value("")
	local category = scope:Value(nil)
	local sort = scope:Value("featured")
	local band = scope:Value("any")
	local self = { query = query, category = category, sort = sort, band = band }

	self.results = scope:Computed(function(use)
		local text = string.lower((string.gsub(use(query), "^%s+", "")))
		local slug = use(category)
		local range = bandFor(use(band))
		local livePrices = use(prices.prices)
		local list = {}
		for _, entry in use(catalog.products) do
			local price = livePrices[entry.id] or entry.robux
			local matchesText = text == "" or string.find(entry.searchText, text, 1, true) ~= nil
			local matchesCategory = true
			if slug then
				matchesCategory = false
				for _, entryCategory in entry.categories do
					if entryCategory.slug == slug then
						matchesCategory = true
						break
					end
				end
			end
			if matchesText and matchesCategory and price >= range.min and price <= range.max then
				table.insert(list, entry)
			end
		end
		local mode = use(sort)
		local function priceOf(entry)
			return livePrices[entry.id] or entry.robux
		end
		table.sort(list, function(a, b)
			if mode == "popular" and a.popularity ~= b.popularity then
				return a.popularity > b.popularity
			end
			if mode == "newest" and a.createdAt ~= b.createdAt then
				return a.createdAt > b.createdAt
			end
			if mode == "priceAsc" and priceOf(a) ~= priceOf(b) then
				return priceOf(a) < priceOf(b)
			end
			if mode == "priceDesc" and priceOf(a) ~= priceOf(b) then
				return priceOf(a) > priceOf(b)
			end
			if mode == "name" and a.name ~= b.name then
				return string.lower(a.name) < string.lower(b.name)
			end
			return a.order < b.order
		end)
		return list
	end)

	self.isFiltered = scope:Computed(function(use)
		return use(query) ~= "" or use(category) ~= nil or use(band) ~= "any"
	end)

	function self.reset()
		query:set("")
		category:set(nil)
		band:set("any")
		sort:set("featured")
	end

	function self.showCategory(slug: string?)
		self.reset()
		category:set(slug)
	end

	function self.sortLabel(scopeForState)
		return scopeForState:Computed(function(use)
			local current = use(sort)
			for _, option in BrowseState.sorts do
				if option.id == current then
					return option.label
				end
			end
			return "Featured"
		end)
	end

	function self.countFor(slug: string): number
		local total = 0
		for _, entry in peek(catalog.products) do
			for _, entryCategory in entry.categories do
				if entryCategory.slug == slug then
					total += 1
					break
				end
			end
		end
		return total
	end

	return self
end

return BrowseState

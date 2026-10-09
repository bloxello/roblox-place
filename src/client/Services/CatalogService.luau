-- Loads the seller catalog from the server and normalises it into Robux-only entries.
local Core = script.Parent.Parent.Core
local Promise = require(Core.Promise)
local Util = require(Core.Util)

local CatalogService = {}

local function normalize(raw)
	local store = raw.store
	local entries, categoryMap, byId, byAsset = {}, {}, {}, {}
	for index, product in store.products or {} do
		local mapping = product.mappings and product.mappings[1]
		local assetId = mapping and tonumber(mapping.robloxAssetId)
		-- The Hub only ever lists items purchasable with Robux.
		if mapping and assetId and type(mapping.robuxPrice) == "number" and type(product.name) == "string" then
			local categories, names = {}, {}
			for _, entry in product.categories or {} do
				local category = entry.category
				if category and category.slug then
					table.insert(categories, category)
					table.insert(names, category.name)
					local info = categoryMap[category.slug]
					if info then
						info.count += 1
					else
						categoryMap[category.slug] =
							{ id = category.slug, name = category.name, slug = category.slug, count = 1 }
					end
				end
			end
			local kind = if mapping.type == "GAME_PASS" then "pass" else "product"
			local entry = {
				id = product.id,
				name = product.name,
				summary = product.summary or "",
				createdAt = Util.parseIso(product.createdAt) or 0,
				popularity = if product._count then product._count.favorites or 0 else 0,
				rating = {
					average = if product.rating then product.rating.average or 0 else 0,
					count = if product.rating then product.rating.count or 0 else 0,
				},
				categories = categories,
				kind = kind,
				assetId = assetId,
				robux = mapping.robuxPrice,
				image = Util.robloxImage(product.thumbnailUrl),
				hasImage = product.hasImage == true,
				galleryCount = product.galleryCount or 0,
				searchText = string.lower(`{product.name} {product.summary or ""} {table.concat(names, " ")}`),
				order = index,
			}
			table.insert(entries, entry)
			byId[entry.id] = entry
			byAsset[`{kind}:{assetId}`] = entry
		end
	end
	local categories = {}
	for _, info in categoryMap do
		table.insert(categories, info)
	end
	table.sort(categories, function(a, b)
		return a.name < b.name
	end)
	return {
		info = {
			id = store.id,
			name = store.name or "Store",
			description = store.description,
			accentHex = store.accentColor,
			hasLogo = store.logoUrl ~= nil,
			hasBanner = store.bannerUrl ~= nil,
		},
		entries = entries,
		categories = categories,
		byId = byId,
		byAsset = byAsset,
	}
end

function CatalogService.new(scope, remotes)
	local status = scope:Value("loading")
	local errorMessage = scope:Value("")
	local store = scope:Value({ name = "Store", description = nil })
	local products = scope:Value({})
	local categories = scope:Value({})
	local lookup = { byId = {}, byAsset = {} }

	local self = {
		status = status,
		errorMessage = errorMessage,
		store = store,
		products = products,
		categories = categories,
	}

	function self.find(id: string)
		return lookup.byId[id]
	end

	function self.findByAsset(kind: string, assetId: number)
		return lookup.byAsset[`{kind}:{assetId}`]
	end

	-- Filtered description and read-only reviews for a product (cached per session; failures are not cached).
	local detailsCache = {}
	function self.details(id: string)
		local cached = detailsCache[id]
		if cached then
			return Promise.resolve(cached)
		end
		return Promise.new(function(resolve, reject)
			local ok, details = pcall(function()
				return remotes.GetProductDetails:InvokeServer(id)
			end)
			if ok and type(details) == "table" then
				if details.reviews then
					for _, review in details.reviews.items do
						review.createdAt = Util.parseIso(review.createdAt)
					end
				end
				detailsCache[id] = details
				resolve(details)
			else
				reject("Details unavailable")
			end
		end)
	end

	function self.fetch()
		status:set("loading")
		return Promise.new(function(resolve, reject)
			local ok, catalog, failure = pcall(function()
				return remotes.GetCatalog:InvokeServer()
			end)
			if ok and type(catalog) == "table" and type(catalog.store) == "table" then
				resolve(catalog)
			else
				reject(if ok then failure or "The store could not be loaded." else tostring(catalog))
			end
		end)
			:andThen(function(catalog)
				local data = normalize(catalog)
				lookup = data
				store:set(data.info)
				products:set(data.entries)
				categories:set(data.categories)
				errorMessage:set("")
				status:set("ready")
				return data
			end)
			:catch(function(reason)
				errorMessage:set(tostring(reason))
				status:set("error")
			end)
	end

	return self
end

return CatalogService

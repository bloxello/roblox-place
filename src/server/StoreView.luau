-- Builds what clients are allowed to see: the catalog and product details with every piece of
-- seller/reviewer text passed through Roblox text filtering (see FilterService).
local Players = game:GetService("Players")
local ApiClient = require(script.Parent.ApiClient)
local CatalogService = require(script.Parent.CatalogService)
local FilterService = require(script.Parent.FilterService)

local REVIEWS_TTL = 120
local DETAILS_WINDOW = 10
local DETAILS_LIMIT = 20
local MAX_REVIEWS = 20

local StoreView = {}

local catalogViews = setmetatable({}, { __mode = "k" })
local reviewCache = {}
local detailsUsage = {}

local function number(value: any, fallback: number)
	return if type(value) == "number" and value == value then value else fallback
end

function StoreView.catalog(player: Player, raw: any)
	local cached = catalogViews[player]
	if cached and cached.source == raw then
		return cached.view
	end

	local store = raw.store
	local texts = { store.name, store.description }
	for _, product in store.products or {} do
		table.insert(texts, product.name)
		table.insert(texts, product.summary)
		for _, entry in product.categories or {} do
			if entry.category then
				table.insert(texts, entry.category.name)
			end
		end
	end
	local filtered = FilterService.filterAll(player, texts)

	local products = {}
	for _, product in store.products or {} do
		local categories = {}
		for _, entry in product.categories or {} do
			local category = entry.category
			local name = category and filtered[category.name]
			if name and name ~= "" then
				table.insert(categories, { category = { name = name, slug = category.slug } })
			end
		end
		table.insert(products, {
			id = product.id,
			name = filtered[product.name] or "Item",
			summary = filtered[product.summary] or "",
			thumbnailUrl = product.thumbnailUrl,
			hasImage = product.hasImage,
			galleryCount = math.clamp(math.floor(number(product.galleryCount, 0)), 0, 8),
			rating = if type(product.rating) == "table"
				then {
					average = math.clamp(number(product.rating.average, 0), 0, 5),
					count = math.max(0, math.floor(number(product.rating.count, 0))),
				}
				else { average = 0, count = 0 },
			createdAt = product.createdAt,
			_count = product._count,
			categories = categories,
			mappings = product.mappings,
		})
	end

	local view = {
		store = {
			id = store.id,
			name = filtered[store.name] or "Store",
			slug = store.slug,
			description = filtered[store.description],
			accentColor = store.accentColor,
			logoUrl = store.logoUrl,
			bannerUrl = store.bannerUrl,
			products = products,
		},
	}
	catalogViews[player] = { source = raw, view = view }
	return view
end

local function allowed(player: Player)
	local now = os.clock()
	local record = detailsUsage[player]
	if not record or now - record.start > DETAILS_WINDOW then
		record = { start = now, count = 0 }
		detailsUsage[player] = record
	end
	record.count += 1
	return record.count <= DETAILS_LIMIT
end

local function reviewsFor(productId: string)
	local hit = reviewCache[productId]
	if hit and os.clock() - hit.at < REVIEWS_TTL then
		return hit.body
	end
	local body = ApiClient.getReviews(productId)
	if body then
		reviewCache[productId] = { body = body, at = os.clock() }
	end
	return body
end

local function findProduct(raw: any, productId: string)
	for _, product in raw.store.products or {} do
		if product.id == productId then
			return product
		end
	end
	return nil
end

-- Description and read-only reviews for one product. Returns nil for unknown products.
function StoreView.details(player: Player, productId: any)
	if type(productId) ~= "string" or #productId > 60 or not allowed(player) then
		return nil
	end
	local raw = CatalogService.get()
	local product = raw and findProduct(raw, productId)
	if not product then
		return nil
	end

	local reviews = reviewsFor(productId)
	local texts = { product.description }
	local rows = {}
	if reviews then
		for index, review in reviews.reviews do
			if index > MAX_REVIEWS then
				break
			end
			if type(review) == "table" and type(review.rating) == "number" then
				table.insert(rows, review)
				table.insert(texts, review.body)
				table.insert(texts, review.author)
			end
		end
	end
	local filtered = FilterService.filterAll(player, texts)

	local out = {
		description = filtered[product.description] or "",
		descriptionWithheld = type(product.description) == "string"
			and product.description ~= ""
			and filtered[product.description] == nil,
	}
	if reviews then
		local distribution = {}
		for star = 1, 5 do
			distribution[star] = math.max(0, math.floor(number(reviews.summary.distribution and reviews.summary.distribution[star], 0)))
		end
		local items = {}
		for _, review in rows do
			table.insert(items, {
				id = tostring(review.id),
				rating = math.clamp(math.floor(review.rating), 1, 5),
				body = filtered[review.body],
				author = filtered[review.author] or "Player",
				createdAt = review.createdAt,
			})
		end
		out.reviews = {
			average = math.clamp(number(reviews.summary.average, 0), 0, 5),
			count = math.max(0, math.floor(number(reviews.summary.count, 0))),
			distribution = distribution,
			items = items,
		}
	end
	return out
end

function StoreView.start()
	Players.PlayerRemoving:Connect(function(player)
		detailsUsage[player] = nil
		catalogViews[player] = nil
	end)
end

return StoreView

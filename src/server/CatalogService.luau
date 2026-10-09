local MemoryStoreService = game:GetService("MemoryStoreService")
local Config = require(script.Parent.Config)
local ApiClient = require(script.Parent.ApiClient)

local cache = MemoryStoreService:GetHashMap(`bloxello-catalog-{Config.StoreId}`)
local CatalogService = {}
local inMemory = nil

function CatalogService.get()
	if inMemory then return inMemory end
	local cachedOk, cached = pcall(cache.GetAsync, cache, "current")
	if cachedOk and cached then inMemory = cached return cached end
	return CatalogService.refresh()
end

function CatalogService.refresh()
	local catalog, requestError = ApiClient.getCatalog()
	if not catalog then return nil, requestError end
	inMemory = catalog
	pcall(cache.SetAsync, cache, "current", catalog, Config.CatalogRefreshSeconds)
	return catalog
end

return CatalogService


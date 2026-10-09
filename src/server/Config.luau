-- This file is replaced by the authenticated Bloxello place generator.
return table.freeze({
	ApiBaseUrl = "http://localhost:4000/v1",
	StoreId = "development-store",
	-- Anyone with edit access to the experience can extract this key and grant products.
	-- Only trust necessary collaborators and rotate the key after access changes.
	HubApiKey = "development-only-replace-me",
	CatalogRefreshSeconds = 120,
	RequestTimeoutSeconds = 10,
})


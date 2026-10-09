export type PurchaseMapping = {
	id: string,
	type: "DEVELOPER_PRODUCT" | "GAME_PASS",
	robuxPrice: number,
	robloxAssetId: string,
	universeId: string,
}

export type Category = { name: string, slug: string }

export type Product = {
	id: string,
	name: string,
	summary: string,
	description: string?,
	thumbnailUrl: string?,
	hasImage: boolean?,
	createdAt: string?,
	_count: { favorites: number }?,
	categories: { { category: Category } }?,
	mappings: { PurchaseMapping },
}

export type Catalog = {
	store: {
		id: string,
		name: string,
		slug: string,
		description: string?,
		accentColor: string,
		logoUrl: string?,
		bannerUrl: string?,
		products: { Product },
	},
}

return {}

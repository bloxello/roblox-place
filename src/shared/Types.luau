export type PurchaseMapping = {
	id: string,
	type: "DEVELOPER_PRODUCT" | "GAME_PASS",
	robuxPrice: number,
	robloxAssetId: string,
	universeId: string,
}

export type Product =
	{ id: string, name: string, summary: string, thumbnailUrl: string?, categories: { { category: { name: string, slug: string } } }?, mappings: { PurchaseMapping } }

export type Catalog = {
	store: { id: string, name: string, slug: string, accentColor: string, products: { Product } },
}

return {}

# Bloxello Roblox Hub

Install [Rojo](https://rojo.space/) and [Wally](https://wally.run/), then run `wally install` and `rojo serve`. Enable HTTP requests in Roblox Studio for local catalog testing.

The generated Hub contains a private per-store API key (stored in `ServerScriptService`, never replicated to clients) used to grant entitlements after its server handles a Developer Product receipt or verifies Game Pass ownership. **Anyone with Studio edit access can extract and abuse this key.** Only give edit access to trusted collaborators, and rotate the key from Bloxello whenever access changes. Receipt IDs remain idempotent and `ProcessReceipt` returns `NotProcessedYet` when Bloxello cannot accept the receipt.


## Client UI architecture

The Hub UI is a Robux-only Fusion 0.3 app under `src/client` (nothing links off-platform):

- `Core/` - Fusion/Promise re-exports, `Theme` (palette from the store accent), `UI` helpers, `Router`, `Icons`, `Util`.
- `Services/` - state and logic: `CatalogService`, `PriceService` (live Robux prices/ownership), `WishlistService`, `PurchaseService`, `BrowseState`, `ToastService`, `ModalService`.
- `Components/` - reusable widgets (`Button`, `ProductCard`, `ResponsiveGrid`, `Dropdown`, `Modal`, ...). Signature: `(ctx, scope, props)`.
- `Layout/` - `App` shell: `Sidebar` / `BottomNav` (responsive), `TopBar`, `PageHost`, `ToastHost`, `ModalHost`, `Splash`.
- `Pages/` - `Home`, `Browse`, `Product`, `Saved`; looked up by name from the router.
- `init.client.luau` - bootstrap that builds services and the shared `ctx`.

Saved items persist per player in the DataStore `bloxello-wishlist-v1` (server `WishlistService`), so the place needs
DataStore access (Studio API access enabled for testing). Run `wally install` to fetch Fusion and Promise.

### Images via EditableImage

Product images, the store logo and banner are drawn with `EditableImage` instead of Roblox asset ids:
the API (`GET /roblox/stores/:id/image/:kind/:productId?`) decodes the hosted image with `sharp` into raw RGBA
(256x256 product, 480x270 gallery via `?i=<index>`, 128x128 logo, 384x144 banner), the server's `ImageService` fetches and caches it (rate limited,
catalog-validated) and the client's `ImageService` writes it into an `EditableImage` shown by `RemoteImage`.
The place needs HTTP requests enabled and EditableImage access for the experience.

### Product gallery and reviews

The product page shows a `Gallery` (cover art plus up to 8 uploaded images, arrows and a thumbnail strip) and a
read-only `Reviews` panel (rating summary, distribution and the 20 latest reviews). Ratings also appear on product
cards and Browse can sort by "Top rated". Posting reviews is not possible in the Hub.

### Text filtering (Hub only)

The API returns seller and reviewer text unfiltered; filtering happens only here. The server's `FilterService`
runs `TextService:FilterStringAsync` on store name/description, product names, summaries, category names,
product descriptions, review text and reviewer names before `StoreView` sends anything to clients
(`GetCatalog` and `GetProductDetails` remotes). Text that cannot be filtered is withheld, never shown raw.

## Branding and splash

Set `WordmarkDecalId` in `src/client/Core/Branding.luau` to your Bloxello wordmark's Roblox image asset id (use the Image id, not the Decal id, if they differ). The hub plays an animated intro splash with it (falls back to a text wordmark while the id is 0) and shows it in the sidebar. Home also gains Recently viewed, Top rated and Budget picks; cards show an Owned badge; Esc/Backspace/B goes back.

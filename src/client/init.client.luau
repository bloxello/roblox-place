--# selene: allow(undefined_variable)
-- Bloxello Hub client entry point: wires services, theme and the root layout.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Core = script.Core
local Services = script.Services
local Fusion = require(Core.Fusion)
local Theme = require(Core.Theme)
local Util = require(Core.Util)
local Router = require(Core.Router)

local CatalogService = require(Services.CatalogService)
local PriceService = require(Services.PriceService)
local ToastService = require(Services.ToastService)
local ModalService = require(Services.ModalService)
local WishlistService = require(Services.WishlistService)
local PurchaseService = require(Services.PurchaseService)
local BrowseState = require(Services.BrowseState)
local ImageService = require(Services.ImageService)

local App = require(script.Layout.App)
local Splash = require(script.Layout.Splash)
local Nav = require(script.Layout.Nav)

local peek = Fusion.peek
local scope = Fusion.scoped(Fusion)
local remotes = ReplicatedStorage:WaitForChild("BloxelloRemotes")
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local function newGui(name: string, order: number)
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = order
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui
	return gui
end

local catalog = CatalogService.new(scope, remotes)
local prices = PriceService.new(scope)

local splashScope = Fusion.scoped(Fusion)
local splashGui = newGui("BloxelloSplash", 11)
Splash(splashScope, nil).Parent = splashGui

catalog.fetch():await()

local toasts = ToastService.new(scope)
local modal = ModalService.new(scope)
local wishlist = WishlistService.new(scope, remotes, toasts)
local purchase = PurchaseService.new(scope, { catalog = catalog, prices = prices, toasts = toasts, remotes = remotes })
local browse = BrowseState.new(scope, catalog, prices)
local router = Router.new(scope, "Home")
local images = ImageService.new(scope, remotes)

local viewport = scope:Value(workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720))
local accent = Util.hexToColor(peek(catalog.store).accentHex, Color3.fromRGB(88, 101, 242))

local ctx = {
	theme = Theme.palette(accent),
	router = router,
	viewport = viewport,
	catalog = catalog,
	prices = prices,
	wishlist = wishlist,
	purchase = purchase,
	toasts = toasts,
	modal = modal,
	browse = browse,
	images = images,
	logo = if peek(catalog.store).hasLogo then images.of("logo") else scope:Value(Content.none),
	banner = if peek(catalog.store).hasBanner then images.of("banner") else scope:Value(Content.none),
}
ctx.compact = scope:Computed(function(use)
	return use(viewport).X < Theme.layout.compactBreakpoint
end)
ctx.activeTab = scope:Computed(function(use)
	return Nav.tabFor[use(router.route).name] or "Home"
end)

function ctx.reload()
	catalog.fetch():andThen(function()
		if peek(catalog.status) == "ready" then
			prices.load(peek(catalog.products))
		end
	end)
end

local gui = newGui("BloxelloHub", 10)
local root = scope:New("Frame")({
	Name = "Root",
	BackgroundColor3 = ctx.theme.bg,
	BorderSizePixel = 0,
	Size = UDim2.fromScale(1, 1),
	[Fusion.Out("AbsoluteSize")] = viewport,
	[Fusion.Children] = App(ctx, scope),
})
root.Parent = gui

if peek(catalog.status) == "ready" then
	prices.load(peek(catalog.products))
	wishlist.load()
end

splashGui:Destroy()
splashScope:doCleanup()

-- Deep link: a teleport can open a specific product via launch data { productId = "..." }.
local joinData = Players.LocalPlayer:GetJoinData()
local launch = joinData and joinData.TeleportData
if type(launch) == "table" and type(launch.productId) == "string" and catalog.find(launch.productId) then
	router.navigate("Product", { id = launch.productId })
end

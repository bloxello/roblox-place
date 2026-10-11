--# selene: allow(undefined_variable)
-- Bloxello Hub client entry point: wires services, theme and the root layout.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StarterGui = game:GetService("StarterGui")
local TextChatService = game:GetService("TextChatService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

-- Hide all default Roblox UI (chat, player list, health, backpack, emotes).
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
task.spawn(function()
	for _ = 1, 10 do
		if pcall(StarterGui.SetCore, StarterGui, "ResetButtonCallback", false) then break end
		task.wait(0.5)
	end
end)
for _, name in { "ChatWindowConfiguration", "ChatInputBarConfiguration", "BubbleChatConfiguration" } do
	local config = TextChatService:FindFirstChild(name)
	if config then config.Enabled = false end
end

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
local DeliveryService = require(Services.DeliveryService)
local RecentService = require(Services.RecentService)
local SupportService = require(Services.SupportService)

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

local splash = Splash.show(newGui("BloxelloSplash", 11))

catalog.fetch():await()

local toasts = ToastService.new(scope)
local support = SupportService.new(scope, remotes, toasts)
local deliveries = DeliveryService.new(scope, remotes)
local modal = ModalService.new(scope)
local wishlist = WishlistService.new(scope, remotes, toasts)
local purchase = PurchaseService.new(scope, { catalog = catalog, prices = prices, toasts = toasts, remotes = remotes, deliveries = deliveries })
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
	deliveries = deliveries,
	purchase = purchase,
	toasts = toasts,
	modal = modal,
	browse = browse,
	images = images,
	recent = RecentService.new(scope),
	support = support,
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

-- Keep content below the Roblox top bar (menu button, etc.), which overlaps an inset-ignoring gui.
local topInset = scope:Value(GuiService.TopbarInset.Height)
table.insert(
	scope,
	GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(function()
		topInset:set(GuiService.TopbarInset.Height)
	end)
)

local gui = newGui("BloxelloHub", 10)
local root = scope:New("Frame")({
	Name = "Root",
	BackgroundColor3 = ctx.theme.bg,
	BorderSizePixel = 0,
	Size = UDim2.fromScale(1, 1),
	[Fusion.Out("AbsoluteSize")] = viewport,
	[Fusion.Children] = {
		scope:New("UIPadding")({
			PaddingTop = scope:Computed(function(use)
				return UDim.new(0, use(topInset))
			end),
		}),
		App(ctx, scope),
	},
})
root.Parent = gui

if peek(catalog.status) == "ready" then
	prices.load(peek(catalog.products))
	wishlist.load()
	deliveries.refresh()
	support.refresh()
end

task.spawn(splash.finish)

-- Back shortcut: Escape / Backspace / gamepad B steps back when no modal is open.
UserInputService.InputBegan:Connect(function(input, processed)
	if processed or peek(modal.current) then return end
	local key = input.KeyCode
	if key == Enum.KeyCode.Escape or key == Enum.KeyCode.Backspace or key == Enum.KeyCode.ButtonB then
		if peek(router.canBack) then router.back() end
	end
end)

-- Deep link: a teleport can open a specific product via launch data { productId = "..." }.
local joinData = Players.LocalPlayer:GetJoinData()
local launch = joinData and joinData.TeleportData
if type(launch) == "table" and type(launch.productId) == "string" and catalog.find(launch.productId) then
	router.navigate("Product", { id = launch.productId })
end

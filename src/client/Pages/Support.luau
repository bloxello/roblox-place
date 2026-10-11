local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local Theme = require(Core.Theme)
local Icons = require(Core.Icons)
local UI = require(Core.UI)
local Children, OnChange = Fusion.Children, Fusion.OnChange
local Components = script.Parent.Parent.Components
local PageShell = require(Components.PageShell)
local ScrollArea = require(Components.ScrollArea)
local SectionHeader = require(Components.SectionHeader)
local Panel = require(Components.Panel)
local Label = require(Components.Label)
local Button = require(Components.Button)
local EmptyState = require(Components.EmptyState)

local function input(ctx, scope, props)
	return scope:New("Frame")({
		Name = props.Name or "Field",
		LayoutOrder = props.LayoutOrder,
		BackgroundColor3 = ctx.theme.surfaceHigh,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, props.Height or 44),
		[Children] = {
			UI.corner(scope, Theme.radius.md),
			UI.stroke(scope, ctx.theme.border, 1),
			scope:New("TextBox")({
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(12, 8),
				Size = UDim2.new(1, -24, 1, -16),
				ClearTextOnFocus = false,
				MultiLine = props.MultiLine or false,
				TextWrapped = props.MultiLine or false,
				Text = props.Value,
				PlaceholderText = props.Placeholder,
				PlaceholderColor3 = ctx.theme.textFaint,
				TextColor3 = ctx.theme.text,
				FontFace = Theme.fonts.regular,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				[OnChange("Text")] = function(text) props.Value:set(text) end,
			}),
		},
	})
end

local function statusText(value: string)
	return string.gsub(value, "_", " ")
end

local function ticketList(ctx, scope, selectedId)
	return scope:Computed(function(use, inner)
		local status = use(ctx.support.status)
		local tickets = use(ctx.support.tickets)
		if status == "loading" or status == "idle" then
			return Label(ctx, inner, { Text = "Loading your support conversations…", Color = ctx.theme.textMuted })
		end
		if status == "error" then
			return EmptyState(ctx, inner, { Icon = Icons.warning, Title = "Support is unavailable", Message = "Try again in a moment.", ActionText = "Retry", OnAction = ctx.support.refresh })
		end
		if #tickets == 0 then
			return EmptyState(ctx, inner, { Icon = Icons.info, Title = "No tickets yet", Message = "Use the form above to ask this storefront for help." })
		end
		local rows = { UI.list(inner, { Gap = 8 }) }
		for index, ticket in tickets do
			table.insert(rows, Panel(ctx, inner, {
				LayoutOrder = index,
				Padding = 14,
				List = { Gap = 6 },
				Color = if use(selectedId) == ticket.id then ctx.theme.accentSoft else ctx.theme.surface,
				Children = {
					Label(ctx, inner, { LayoutOrder = 1, Text = ticket.subject or "Support request", Variant = "bodyStrong", Wrap = true }),
					Label(ctx, inner, { LayoutOrder = 2, Text = `{statusText(ticket.status or "OPEN")}  ·  {ticket.category or "HELP"}`, Variant = "tiny", Color = ctx.theme.textMuted }),
					Button(ctx, inner, { LayoutOrder = 3, Text = "Open conversation", Size = "sm", Variant = "secondary", OnClick = function() selectedId:set(ticket.id) end }),
				},
			}))
		end
		return inner:New("Frame")({ BackgroundTransparency = 1, Size = UDim2.fromScale(1, 0), AutomaticSize = Enum.AutomaticSize.Y, [Children] = rows })
	end)
end

local function conversation(ctx, scope, selectedId, reply)
	return scope:Computed(function(use, inner)
		local id = use(selectedId)
		if id == "" then return nil end
		local selected
		for _, ticket in use(ctx.support.tickets) do
			if ticket.id == id then
				selected = ticket
				break
			end
		end
		if not selected then return nil end
		local rows = {
			Label(ctx, inner, { LayoutOrder = 1, Text = selected.subject, Variant = "heading", Wrap = true }),
			Label(ctx, inner, { LayoutOrder = 2, Text = statusText(selected.status or "OPEN"), Variant = "tiny", Color = ctx.theme.accent }),
		}
		for index, message in selected.messages or {} do
			table.insert(rows, Panel(ctx, inner, {
				LayoutOrder = index + 2,
				Padding = 12,
				Color = if message.authorType == "CUSTOMER" then ctx.theme.accentSoft else ctx.theme.surfaceHigh,
				List = { Gap = 4 },
				Children = {
					Label(ctx, inner, { LayoutOrder = 1, Text = if message.authorType == "CUSTOMER" then "You" else message.authorName or "Store support", Variant = "tiny", Color = ctx.theme.textMuted }),
					Label(ctx, inner, { LayoutOrder = 2, Text = message.body, Variant = "body", Wrap = true }),
				},
			}))
		end
		local closed = selected.status == "CLOSED"
		table.insert(rows, input(ctx, inner, { LayoutOrder = 1000, Value = reply, Placeholder = if closed then "This ticket is closed" else "Write a reply…", Height = 92, MultiLine = true }))
		table.insert(rows, Button(ctx, inner, {
			LayoutOrder = 1001,
			Text = "Send reply",
			Icon = Icons.next,
			Disabled = scope:Computed(function(use2) return closed or use2(reply) == "" end),
			Loading = ctx.support.sending,
			OnClick = function()
				ctx.support.reply(selected.id, Fusion.peek(reply), function()
					reply:set("")
				end)
			end,
		}))
		return Panel(ctx, inner, { LayoutOrder = 4, Padding = 16, List = { Gap = 8 }, Children = rows })
	end)
end

return function(ctx, scope)
	ctx.support.refresh()
	local subject = scope:Value("")
	local message = scope:Value("")
	local reply = scope:Value("")
	local selectedId = scope:Value("")
	return PageShell(ctx, scope, {
		Name = "Support",
		Children = ScrollArea(ctx, scope, { Children = {
			SectionHeader(ctx, scope, { LayoutOrder = 1, Title = "Store support", Subtitle = "Private help from this storefront's team", ActionText = "Refresh", OnAction = ctx.support.refresh }),
			Panel(ctx, scope, { LayoutOrder = 2, Padding = 16, List = { Gap = 10 }, Children = {
				Label(ctx, scope, { LayoutOrder = 1, Text = "Open a support ticket", Variant = "heading" }),
				Label(ctx, scope, { LayoutOrder = 2, Text = "Describe the product, order, delivery, or license problem. Roblox filters your message before it is sent.", Variant = "caption", Color = ctx.theme.textMuted, Wrap = true }),
				input(ctx, scope, { LayoutOrder = 3, Value = subject, Placeholder = "Short subject", Height = 44 }),
				input(ctx, scope, { LayoutOrder = 4, Value = message, Placeholder = "How can the storefront help?", Height = 110, MultiLine = true }),
				Button(ctx, scope, {
					LayoutOrder = 5,
					Text = "Open ticket",
					Icon = Icons.next,
					Loading = ctx.support.sending,
					Disabled = scope:Computed(function(use)
						return #use(subject) < 4 or #use(message) < 10
					end),
					OnClick = function()
						ctx.support.create(Fusion.peek(subject), Fusion.peek(message), function(ticket)
							subject:set("")
							message:set("")
							if ticket then
								selectedId:set(ticket.id)
							end
						end)
					end,
				}),
			} }),
			Panel(ctx, scope, { LayoutOrder = 3, Padding = 16, List = { Gap = 10 }, Children = {
				Label(ctx, scope, { LayoutOrder = 1, Text = "Your conversations", Variant = "heading" }),
				ticketList(ctx, scope, selectedId),
			} }),
			conversation(ctx, scope, selectedId, reply),
		} }),
	})
end

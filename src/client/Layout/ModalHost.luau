local Core = script.Parent.Parent.Core
local Fusion = require(Core.Fusion)
local Children, OnEvent = Fusion.Children, Fusion.OnEvent
local Components = script.Parent.Parent.Components
local Modal = require(Components.Modal)

return function(ctx, scope)
	return scope:New("TextButton")({
		Name = "ModalHost",
		AutoButtonColor = false,
		Text = "",
		BackgroundColor3 = Color3.new(0, 0, 0),
		BorderSizePixel = 0,
		ZIndex = 40,
		Size = UDim2.fromScale(1, 1),
		Visible = scope:Computed(function(use)
			return use(ctx.modal.current) ~= nil
		end),
		BackgroundTransparency = scope:Tween(
			scope:Computed(function(use)
				return if use(ctx.modal.current) then 0.45 else 1
			end),
			TweenInfo.new(0.18)
		),
		[OnEvent("Activated")] = function()
			ctx.modal.close()
		end,
		[Children] = scope:Computed(function(use, inner)
			local spec = use(ctx.modal.current)
			if not spec then
				return nil
			end
			return Modal(ctx, inner, { Spec = spec })
		end),
	})
end

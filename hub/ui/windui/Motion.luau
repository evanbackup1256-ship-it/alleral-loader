-- Alleral V11 — lightweight TweenService motion (no Noble/Spr)
return function()
	local TweenService = game:GetService("TweenService")
	local Motion = {}

	local function findGui(el)
		if typeof(el) == "Instance" and el:IsA("GuiObject") then
			return el
		end
		if type(el) == "table" then
			for _, key in ipairs({ "Frame", "UIElements", "Object", "Instance", "Button", "Root", "Holder" }) do
				local v = el[key]
				if typeof(v) == "Instance" and v:IsA("GuiObject") then
					return v
				end
			end
		end
		return nil
	end

	function Motion.tween(inst, props, duration, style, dir)
		if typeof(inst) ~= "Instance" then return end
		duration = duration or 0.18
		style = style or Enum.EasingStyle.Quint
		dir = dir or Enum.EasingDirection.Out
		local tw = TweenService:Create(inst, TweenInfo.new(duration, style, dir), props)
		tw:Play()
		return tw
	end

	function Motion.bindHover(el, opts)
		opts = opts or {}
		local gui = findGui(el)
		if not gui or not gui:IsA("GuiButton") then return end
		local scale = gui:FindFirstChildOfClass("UIScale")
		if not scale then
			scale = Instance.new("UIScale")
			scale.Parent = gui
		end
		local hover = opts.hoverScale or 1.02
		local press = opts.pressScale or 0.97
		local baseTrans = gui.BackgroundTransparency
		gui.MouseEnter:Connect(function()
			Motion.tween(scale, { Scale = hover }, 0.14)
			if opts.brighten and (gui:IsA("ImageButton") or gui:IsA("TextButton")) then
				Motion.tween(gui, { BackgroundTransparency = math.max(0, baseTrans - 0.06) }, 0.14)
			end
		end)
		gui.MouseLeave:Connect(function()
			Motion.tween(scale, { Scale = 1 }, 0.16)
			if opts.brighten and (gui:IsA("ImageButton") or gui:IsA("TextButton")) then
				Motion.tween(gui, { BackgroundTransparency = baseTrans }, 0.16)
			end
		end)
		gui.MouseButton1Down:Connect(function()
			Motion.tween(scale, { Scale = press }, 0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		end)
		gui.MouseButton1Up:Connect(function()
			Motion.tween(scale, { Scale = hover }, 0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		end)
	end

	function Motion.bindSidebarItem(el)
		local gui = findGui(el)
		if not gui then return end
		local stroke = gui:FindFirstChildOfClass("UIStroke")
		gui.MouseEnter:Connect(function()
			if stroke then
				Motion.tween(stroke, { Transparency = 0.45 }, 0.16)
			end
			Motion.tween(gui, { BackgroundTransparency = math.max(0, (gui.BackgroundTransparency or 0) - 0.04) }, 0.16)
		end)
		gui.MouseLeave:Connect(function()
			if stroke then
				Motion.tween(stroke, { Transparency = 0.82 }, 0.18)
			end
			Motion.tween(gui, { BackgroundTransparency = gui:GetAttribute("AlleralBaseTrans") or gui.BackgroundTransparency }, 0.18)
		end)
	end

	function Motion.openWindow(WindUI)
		pcall(function()
			local scaleObj = WindUI and WindUI.UIScaleObj
			if scaleObj then
				scaleObj.Scale = 0.96
				Motion.tween(scaleObj, { Scale = 1 }, 0.38, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
			end
		end)
	end

	function Motion.fadeIn(gui, duration)
		if typeof(gui) ~= "Instance" or not gui:IsA("GuiObject") then return end
		local target = gui:GetAttribute("AlleralBaseTrans")
		if target == nil then
			target = gui.BackgroundTransparency
			gui:SetAttribute("AlleralBaseTrans", target)
		end
		gui.BackgroundTransparency = 1
		Motion.tween(gui, { BackgroundTransparency = target }, duration or 0.22)
	end

	function Motion.staggerIn(elements, delay)
		delay = delay or 0.03
		for i, el in ipairs(elements or {}) do
			task.delay((i - 1) * delay, function()
				Motion.fadeIn(findGui(el), 0.22)
			end)
		end
	end

	return Motion
end
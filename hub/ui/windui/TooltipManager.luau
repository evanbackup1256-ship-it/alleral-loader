-- Alleral V11.2 — premium dynamic tooltips
return function(Bootstrap, Motion, Text)
	local TooltipManager = {}
	local UserInputService = game:GetService("UserInputService")
	local Players = game:GetService("Players")

	local HOVER_DELAY = 0.25
	local FADE_OUT = 0.08
	local MAX_WIDTH = 280

	local gui
	local card
	local titleLabel
	local bodyLabel
	local accent
	local activeGui
	local showThread
	local hideThread
	local visible = false
	local stats = { attached = 0, shown = 0 }

	local COLORS = {
		bg = Color3.fromHex("#101624"),
		border = Color3.fromHex("#25304A"),
		accent = Color3.fromHex("#8B5CF6"),
		text = Color3.fromHex("#F8FAFC"),
		muted = Color3.fromHex("#94A3B8"),
	}

	local function ensureGui()
		if gui and gui.Parent then
			return
		end
		local player = Players.LocalPlayer
		if not player then
			return
		end
		local pg = player:FindFirstChildOfClass("PlayerGui")
		if not pg then
			return
		end

		gui = Instance.new("ScreenGui")
		gui.Name = "AlleralTooltips"
		gui.ResetOnSpawn = false
		gui.DisplayOrder = 999
		gui.IgnoreGuiInset = true
		gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		gui.Parent = pg

		card = Instance.new("Frame")
		card.Name = "TooltipCard"
		card.BackgroundColor3 = COLORS.bg
		card.BackgroundTransparency = 0.06
		card.BorderSizePixel = 0
		card.Size = UDim2.fromOffset(MAX_WIDTH, 80)
		card.Visible = false
		card.Parent = gui

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = card

		local stroke = Instance.new("UIStroke")
		stroke.Color = COLORS.border
		stroke.Transparency = 0.35
		stroke.Thickness = 1
		stroke.Parent = card

		accent = Instance.new("Frame")
		accent.Name = "Accent"
		accent.BackgroundColor3 = COLORS.accent
		accent.BorderSizePixel = 0
		accent.Size = UDim2.new(1, 0, 0, 2)
		accent.Position = UDim2.fromOffset(0, 0)
		accent.Parent = card

		local pad = Instance.new("UIPadding")
		pad.PaddingTop = UDim.new(0, 10)
		pad.PaddingBottom = UDim.new(0, 10)
		pad.PaddingLeft = UDim.new(0, 12)
		pad.PaddingRight = UDim.new(0, 12)
		pad.Parent = card

		titleLabel = Instance.new("TextLabel")
		titleLabel.BackgroundTransparency = 1
		titleLabel.Font = Enum.Font.GothamMedium
		titleLabel.TextSize = 14
		titleLabel.TextColor3 = COLORS.text
		titleLabel.TextXAlignment = Enum.TextXAlignment.Left
		titleLabel.TextWrapped = true
		titleLabel.Size = UDim2.new(1, 0, 0, 18)
		titleLabel.Parent = card

		bodyLabel = Instance.new("TextLabel")
		bodyLabel.BackgroundTransparency = 1
		bodyLabel.Font = Enum.Font.Gotham
		bodyLabel.TextSize = 12
		bodyLabel.TextColor3 = COLORS.muted
		bodyLabel.TextXAlignment = Enum.TextXAlignment.Left
		bodyLabel.TextWrapped = true
		bodyLabel.Position = UDim2.fromOffset(0, 22)
		bodyLabel.Size = UDim2.new(1, 0, 0, 40)
		bodyLabel.Parent = card

		local scale = Instance.new("UIScale")
		scale.Scale = 0.96
		scale.Parent = card
		card:SetAttribute("TooltipScale", true)
	end

	local function cancelThreads()
		if showThread then
			task.cancel(showThread)
			showThread = nil
		end
		if hideThread then
			task.cancel(hideThread)
			hideThread = nil
		end
	end

	function TooltipManager.resolve(meta, controlType, sectionName, label)
		meta = type(meta) == "table" and meta or {}
		local title = Bootstrap.sanitize(meta.title or meta.Title or label or controlType or "Control", 80)
		local lines = {}
		local desc = Bootstrap.sanitize(meta.description or meta.Description or meta.Desc or meta.Tooltip or "", 200)
		if desc ~= "" then
			table.insert(lines, desc)
		end
		local value = meta.value
		if type(value) == "function" then
			local ok, res = pcall(value)
			if ok and res ~= nil then
				table.insert(lines, "Value: " .. Bootstrap.sanitize(res, 80))
			end
		elseif value ~= nil then
			table.insert(lines, "Value: " .. Bootstrap.sanitize(value, 80))
		end
		if meta.hotkey and tostring(meta.hotkey) ~= "" and tostring(meta.hotkey) ~= "None" then
			table.insert(lines, "Hotkey: " .. Bootstrap.sanitize(meta.hotkey, 32))
		end
		if meta.configKey and tostring(meta.configKey) ~= "" then
			table.insert(lines, "Config: " .. Bootstrap.sanitize(meta.configKey, 64))
		end
		if meta.warning and tostring(meta.warning) ~= "" then
			table.insert(lines, "Warning: " .. Bootstrap.sanitize(meta.warning, 120))
		end
		if meta.state and tostring(meta.state) ~= "" then
			table.insert(lines, "State: " .. Bootstrap.sanitize(meta.state, 40))
		end
		if #lines == 0 and sectionName then
			table.insert(lines, "Section: " .. Bootstrap.sanitize(sectionName, 64))
		end
		if #lines == 0 then
			table.insert(lines, "Type: " .. Bootstrap.sanitize(controlType or "control", 32))
		end
		return title, table.concat(lines, "\n")
	end

	local function placeNear(guiObj, followMouse)
		if not card or not guiObj then
			return
		end
		local cam = workspace.CurrentCamera
		if not cam then
			return
		end
		local vp = cam.ViewportSize
		local pos
		if followMouse then
			pos = UserInputService:GetMouseLocation()
		else
			local abs = guiObj.AbsolutePosition
			local size = guiObj.AbsoluteSize
			pos = Vector2.new(abs.X + size.X + 12, abs.Y + 4)
		end
		local w = card.AbsoluteSize.X > 0 and card.AbsoluteSize.X or MAX_WIDTH
		local h = card.AbsoluteSize.Y > 0 and card.AbsoluteSize.Y or 80
		if pos.X + w > vp.X - 8 then
			pos = Vector2.new(vp.X - w - 8, pos.Y)
		end
		if pos.Y + h > vp.Y - 8 then
			pos = Vector2.new(pos.X, vp.Y - h - 8)
		end
		if pos.X < 8 then pos = Vector2.new(8, pos.Y) end
		if pos.Y < 8 then pos = Vector2.new(pos.X, 8) end
		card.Position = UDim2.fromOffset(pos.X, pos.Y)
	end

	function TooltipManager.hide()
		cancelThreads()
		if not card then
			return
		end
		if Motion and visible then
			local scale = card:FindFirstChildOfClass("UIScale")
			if scale then
				Motion.tween(scale, { Scale = 0.96 }, FADE_OUT)
			end
			Motion.tween(card, { BackgroundTransparency = 1 }, FADE_OUT)
			hideThread = task.delay(FADE_OUT, function()
				card.Visible = false
				card.BackgroundTransparency = 0.06
				visible = false
				activeGui = nil
			end)
		else
			card.Visible = false
			visible = false
			activeGui = nil
		end
	end

	function TooltipManager.show(guiObj, title, body, opts)
		opts = opts or {}
		TooltipManager.hide()
		ensureGui()
		if not card or not guiObj then
			return
		end
		title = Bootstrap.sanitize(title, 80)
		body = Bootstrap.sanitize(body, 240)
		if title == "" and body == "" then
			return
		end
		titleLabel.Text = title
		bodyLabel.Text = body
		local lines = 1
		for _ in body:gmatch("\n") do
			lines = lines + 1
		end
		bodyLabel.Size = UDim2.new(1, 0, 0, math.clamp(lines * 16, 20, 120))
		card.Size = UDim2.fromOffset(MAX_WIDTH, 34 + bodyLabel.Size.Y.Offset)
		placeNear(guiObj, opts.followMouse == true)
		card.Visible = true
		visible = true
		activeGui = guiObj
		stats.shown = stats.shown + 1
		local scale = card:FindFirstChildOfClass("UIScale")
		if scale and Motion then
			scale.Scale = 0.96
			card.BackgroundTransparency = 1
			Motion.tween(scale, { Scale = 1 }, 0.14)
			Motion.tween(card, { BackgroundTransparency = 0.06 }, 0.14)
		end
	end

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

	function TooltipManager.attach(el, meta, controlType, sectionName, label)
		local guiObj = findGui(el)
		if not guiObj or guiObj:GetAttribute("AlleralTooltipBound") then
			return
		end
		guiObj:SetAttribute("AlleralTooltipBound", true)
		stats.attached = stats.attached + 1

		guiObj.MouseEnter:Connect(function()
			cancelThreads()
			local token = {}
			showThread = task.delay(HOVER_DELAY, function()
				if not guiObj.Parent then
					return
				end
				local title, body = TooltipManager.resolve(meta, controlType, sectionName, label)
				TooltipManager.show(guiObj, title, body, meta)
			end)
		end)
		guiObj.MouseLeave:Connect(function()
			cancelThreads()
			TooltipManager.hide()
		end)
	end

	function TooltipManager.init()
		ensureGui()
		warn("[WindUI] TooltipManager ready")
	end

	function TooltipManager.getStats()
		return {
			attached = stats.attached,
			shown = stats.shown,
			visible = visible,
		}
	end

	return TooltipManager
end
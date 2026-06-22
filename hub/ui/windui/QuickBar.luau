-- Alleral V11.5.2 — status strip + quick actions (deferred, low overhead)
return function(Bootstrap, Theme)
	local QuickBar = {}
	local RunService = game:GetService("RunService")
	local Stats = game:GetService("Stats")
	local bound = {}

	local function getRoot(windWindow)
		local root = windWindow and windWindow.UIElements and windWindow.UIElements.Main
		if typeof(root) == "Instance" then
			return root
		end
		return nil
	end

	local function findTopbar(root)
		for _, name in ipairs({ "Topbar", "TopBar", "TitleBar", "Header" }) do
			local bar = root:FindFirstChild(name, true)
			if bar and bar:IsA("GuiObject") then
				return bar
			end
		end
		return root
	end

	local function pingMs()
		local ok, val = pcall(function()
			return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
		end)
		if ok and type(val) == "number" then
			return math.floor(val)
		end
		return nil
	end

	function QuickBar.stripBackdrop(windWindow)
		pcall(function()
			if type(windWindow) == "table" then
				windWindow.Transparent = false
			end
		end)

		local player = game:GetService("Players").LocalPlayer
		if not player then
			return
		end
		local gui = player:FindFirstChildOfClass("PlayerGui")
		if not gui then
			return
		end

		local names = {
			overlay = true,
			backdrop = true,
			backgrounddim = true,
			dim = true,
			blur = true,
			acrylic = true,
			shade = true,
			darken = true,
		}

		for _, inst in ipairs(gui:GetDescendants()) do
			if inst:IsA("Frame") or inst:IsA("ImageLabel") then
				local key = inst.Name:lower():gsub("[%s_%-]", "")
				if names[key] or key:find("backdrop", 1, true) or key:find("overlay", 1, true) then
					if inst.BackgroundTransparency < 0.95 or (inst:IsA("ImageLabel") and inst.ImageTransparency < 0.95) then
						inst.Visible = false
						inst.BackgroundTransparency = 1
						if inst:IsA("ImageLabel") then
							inst.ImageTransparency = 1
						end
					end
				end
			end
		end
	end

	function QuickBar.bind(windWindow, handlers)
		handlers = type(handlers) == "table" and handlers or {}
		if not windWindow or bound[windWindow] then
			return
		end

		task.defer(function()
			local root = getRoot(windWindow)
			if not root then
				return
			end
			bound[windWindow] = true

			QuickBar.stripBackdrop(windWindow)

			if root:FindFirstChild("AlleralQuickBar") then
				return
			end

			local topbar = findTopbar(root)
			local bar = Instance.new("Frame")
			bar.Name = "AlleralQuickBar"
			bar.AnchorPoint = Vector2.new(1, 0.5)
			bar.Position = UDim2.new(1, -88, 0.5, 0)
			bar.Size = UDim2.fromOffset(220, 28)
			bar.BackgroundTransparency = 1
			bar.BorderSizePixel = 0
			bar.ZIndex = (topbar.ZIndex or 1) + 5
			bar.Parent = topbar

			local layout = Instance.new("UIListLayout")
			layout.FillDirection = Enum.FillDirection.Horizontal
			layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
			layout.VerticalAlignment = Enum.VerticalAlignment.Center
			layout.Padding = UDim.new(0, 6)
			layout.Parent = bar

			local status = Instance.new("TextLabel")
			status.Name = "Status"
			status.BackgroundTransparency = 1
			status.Size = UDim2.fromOffset(110, 20)
			status.Font = Enum.Font.GothamMedium
			status.TextSize = 11
			status.TextColor3 = Color3.fromHex("#94A3B8")
			status.TextXAlignment = Enum.TextXAlignment.Right
			status.Text = "FPS --  Ping --"
			status.Parent = bar

			local function makeBtn(name, text, callback)
				local btn = Instance.new("TextButton")
				btn.Name = name
				btn.Size = UDim2.fromOffset(28, 22)
				btn.BackgroundColor3 = Color3.fromHex("#111827")
				btn.BackgroundTransparency = 0.2
				btn.BorderSizePixel = 0
				btn.Font = Enum.Font.GothamBold
				btn.TextSize = 11
				btn.TextColor3 = Color3.fromHex("#22D3EE")
				btn.Text = text
				btn.AutoButtonColor = false
				btn.Parent = bar
				local c = Instance.new("UICorner")
				c.CornerRadius = UDim.new(0, 6)
				c.Parent = btn
				btn.MouseButton1Click:Connect(function()
					if callback then pcall(callback) end
				end)
				return btn
			end

			makeBtn("SearchBtn", "S", handlers.onSearch)
			makeBtn("ReloadBtn", "R", handlers.onReload)
			makeBtn("ThemeBtn", "T", handlers.onTheme)

			local frames = 0
			local accum = 0
			local conn = RunService.Heartbeat:Connect(function(dt)
				frames = frames + 1
				accum = accum + dt
				if accum < 0.5 then
					return
				end
				local fps = math.floor(frames / accum)
				frames = 0
				accum = 0
				local ping = pingMs()
				status.Text = "FPS " .. tostring(fps) .. "  Ping " .. (ping and tostring(ping) or "--")
			end)

			if type(windWindow) == "table" then
				windWindow._alleralQuickBarConn = conn
			end
		end)
	end

	function QuickBar.cleanup(windWindow)
		if type(windWindow) == "table" and windWindow._alleralQuickBarConn then
			pcall(function() windWindow._alleralQuickBarConn:Disconnect() end)
			windWindow._alleralQuickBarConn = nil
		end
		bound[windWindow] = nil
	end

	return QuickBar
end
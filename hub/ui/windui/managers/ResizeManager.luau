-- Alleral V12 — bottom bar + corner resize (smooth, persisted)
return function(EventBus, ConnectionTracker, PerformanceManager, Theme)
	local UserInputService = game:GetService("UserInputService")
	local ResizeManager = {}

	local MIN_W, MIN_H = 720, 480
	local MAX_W, MAX_H = 1400, 900
	local states = {}

	local ACCENT = Color3.fromHex("#8B5CF6")
	local CYAN = Color3.fromHex("#06B6D4")

	if Theme then
		pcall(function()
			if Theme.accent then ACCENT = Theme.accent() end
			if Theme.cyan then CYAN = Theme.cyan() end
		end)
	end

	local function getRoot(windWindow)
		if type(windWindow) == "table" then
			local root = windWindow.UIElements and windWindow.UIElements.Main
			if typeof(root) == "Instance" then
				return root
			end
		end
		return nil
	end

	local function sizeKey(gameId)
		return "Alleral_WindowSize_" .. tostring(gameId or "default")
	end

	local function loadSize(gameId)
		local env = getgenv and getgenv() or {}
		local saved = env[sizeKey(gameId)]
		if type(saved) == "table" then
			local w = tonumber(saved.w)
			local h = tonumber(saved.h)
			if w and h then
				return w, h
			end
		end
		return nil, nil
	end

	local function saveSize(gameId, w, h)
		local env = getgenv and getgenv() or {}
		env[sizeKey(gameId)] = { w = w, h = h }
	end

	local function ensureHandles(root, owner)
		if root:FindFirstChild("AlleralResizeBottom") then
			return
		end

		local bottom = Instance.new("TextButton")
		bottom.Name = "AlleralResizeBottom"
		bottom.AnchorPoint = Vector2.new(0.5, 1)
		bottom.Position = UDim2.new(0.5, 0, 1, -4)
		bottom.Size = UDim2.new(0, 120, 0, 6)
		bottom.BackgroundColor3 = ACCENT
		bottom.BackgroundTransparency = 0.55
		bottom.BorderSizePixel = 0
		bottom.AutoButtonColor = false
		bottom.Text = ""
		bottom.ZIndex = (root.ZIndex or 1) + 20
		bottom.Parent = root

		local bottomCorner = Instance.new("UICorner")
		bottomCorner.CornerRadius = UDim.new(1, 0)
		bottomCorner.Parent = bottom

		local bottomStroke = Instance.new("UIStroke")
		bottomStroke.Color = CYAN
		bottomStroke.Thickness = 1
		bottomStroke.Transparency = 0.6
		bottomStroke.Parent = bottom

		local corner = Instance.new("TextButton")
		corner.Name = "AlleralResizeCorner"
		corner.AnchorPoint = Vector2.new(1, 1)
		corner.Position = UDim2.new(1, -6, 1, -6)
		corner.Size = UDim2.new(0, 14, 0, 14)
		corner.BackgroundColor3 = ACCENT
		corner.BackgroundTransparency = 0.35
		corner.BorderSizePixel = 0
		corner.AutoButtonColor = false
		corner.Text = ""
		corner.ZIndex = (root.ZIndex or 1) + 21
		corner.Parent = root

		local gripCorner = Instance.new("UICorner")
		gripCorner.CornerRadius = UDim.new(0, 4)
		gripCorner.Parent = corner

		local gripStroke = Instance.new("UIStroke")
		gripStroke.Color = CYAN
		gripStroke.Thickness = 1
		gripStroke.Transparency = 0.45
		gripStroke.Parent = corner

		bottom.MouseEnter:Connect(function()
			bottom.BackgroundTransparency = 0.25
		end)
		bottom.MouseLeave:Connect(function()
			bottom.BackgroundTransparency = 0.55
		end)
		corner.MouseEnter:Connect(function()
			corner.BackgroundTransparency = 0.1
		end)
		corner.MouseLeave:Connect(function()
			corner.BackgroundTransparency = 0.35
		end)
	end

	function ResizeManager.cleanup(owner)
		local st = states[owner]
		if not st then
			return
		end
		if ConnectionTracker then
			ConnectionTracker.disconnect(owner, "resize-move")
			ConnectionTracker.disconnect(owner, "resize-end")
		end
		st.active = false
		states[owner] = nil
		if EventBus then
			EventBus.emit("resize:end", owner)
		end
	end

	function ResizeManager.bind(windWindow, options)
		options = type(options) == "table" and options or {}
		local owner = windWindow
		if states[owner] then
			return true
		end

		local root = getRoot(windWindow)
		if not root then
			return false
		end

		local gameId = options.gameId or "default"
		local savedW, savedH = loadSize(gameId)
		if savedW and savedH then
			pcall(function()
				root.Size = UDim2.fromOffset(
					math.clamp(savedW, MIN_W, MAX_W),
					math.clamp(savedH, MIN_H, MAX_H)
				)
			end)
		end

		ensureHandles(root, owner)

		local bottom = root:FindFirstChild("AlleralResizeBottom")
		local grip = root:FindFirstChild("AlleralResizeCorner")
		if not bottom or not grip then
			return false
		end

		local st = {
			active = false,
			mode = nil,
			root = root,
			start = nil,
			origin = nil,
			inputType = nil,
		}
		states[owner] = st

		local function beginResize(handle, mode, input)
			if st.active then
				return
			end
			if PerformanceManager and PerformanceManager.isBusy("drag") then
				return
			end
			st.active = true
			if PerformanceManager and PerformanceManager.setBusy then
				PerformanceManager.setBusy("resize", true)
			end
			st.mode = mode
			st.start = input.Position
			st.origin = root.Size
			st.inputType = input.UserInputType

			if EventBus then
				EventBus.emit("resize:start", owner, mode)
			end

			if ConnectionTracker then
				ConnectionTracker.track(owner, UserInputService.InputChanged:Connect(function(changed)
					if not st.active or changed.UserInputType ~= st.inputType then
						return
					end
					local delta = changed.Position - st.start
					local w = st.origin.X.Offset
					local h = st.origin.Y.Offset
					if st.mode == "corner" then
						w = math.clamp(w + delta.X, MIN_W, MAX_W)
						h = math.clamp(h + delta.Y, MIN_H, MAX_H)
					else
						h = math.clamp(h + delta.Y, MIN_H, MAX_H)
					end
					root.Size = UDim2.fromOffset(w, h)
				end), "resize-move")
			end

			ConnectionTracker.track(owner, input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					st.active = false
					if PerformanceManager and PerformanceManager.setBusy then
						PerformanceManager.setBusy("resize", false)
					end
					saveSize(gameId, root.Size.X.Offset, root.Size.Y.Offset)
					if ConnectionTracker then
						ConnectionTracker.disconnect(owner, "resize-move")
					end
					if EventBus then
						EventBus.emit("resize:end", owner)
					end
				end
			end), "resize-end")
		end

		local bottomConn = bottom.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				beginResize(bottom, "bottom", input)
			end
		end)
		local gripConn = grip.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				beginResize(grip, "corner", input)
			end
		end)

		if ConnectionTracker then
			ConnectionTracker.track(owner, bottomConn, "resize-bottom")
			ConnectionTracker.track(owner, gripConn, "resize-corner")
		end

		return true
	end

	function ResizeManager.logReady()
		pcall(function()
			local Log = getgenv and getgenv().Alleral_Log
			if Log and Log.info then
				Log.info("Resize manager active (bottom bar + corner grip)")
			end
		end)
	end

	return ResizeManager
end
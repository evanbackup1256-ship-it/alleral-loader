-- Alleral UI layer — v6.5.0 Linoria Enhanced
--[[
	ALLERAL UI LAYER v6.5.0 - ENHANCED EDITION
	Complete rewrite with animations, notification stacking, advanced features
	Built on top of Linoria UI Library with modern visual enhancements
]]

return function(Core)
	local TweenService = game:GetService("TweenService")
	local UserInputService = game:GetService("UserInputService")

	local CONFIG = {
		VERSION = "6.5.0",
		LIB_NAME = "Alleral UI Enhanced",
		DEFAULT_ICON = "18821914323",
		CACHE_FOLDER = ".alleral/cache",
		LINORIA_REPO = "https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua",
		FETCH_TIMEOUT = 3,
		CACHE_MIN_SIZE = 1000,
		NOTIFICATION = { DURATION = 4, MAX_STACK = 5, ANIMATION_DURATION = 0.3, FADE_OUT_DURATION = 0.5, SLIDE_OFFSET = 40 },
		ANIMATION = { BUTTON_HOVER_SCALE = 1.05, BUTTON_CLICK_DURATION = 0.15, TOGGLE_DURATION = 0.2, FADE_IN_DURATION = 0.25, WINDOW_SCALE_IN = 0.35, DROPDOWN_DURATION = 0.25 },
		THEME = {
			PRIMARY = Color3.fromRGB(66, 150, 255),
			PRIMARY_DARK = Color3.fromRGB(40, 120, 220),
			SUCCESS = Color3.fromRGB(76, 175, 80),
			WARNING = Color3.fromRGB(255, 193, 7),
			ERROR = Color3.fromRGB(244, 67, 54),
			INFO = Color3.fromRGB(33, 150, 243),
			SECONDARY = Color3.fromRGB(158, 158, 158),
			ACCENT = Color3.fromRGB(255, 87, 34),
			BACKGROUND = Color3.fromRGB(18, 18, 22),
			BACKGROUND_ALT = Color3.fromRGB(28, 28, 35),
			SURFACE = Color3.fromRGB(35, 35, 45),
			SURFACE_HOVER = Color3.fromRGB(45, 45, 55),
			TEXT = Color3.fromRGB(220, 220, 230),
			TEXT_DIM = Color3.fromRGB(140, 140, 155),
			BORDER = Color3.fromRGB(50, 50, 60),
			SCROLLBAR = Color3.fromRGB(60, 60, 75),
			TAB_ACTIVE = Color3.fromRGB(45, 45, 55),
			TAB_INACTIVE = Color3.fromRGB(28, 28, 35),
		},
	}

	local ENV = (function()
		local ok, env = pcall(function() return getgenv and getgenv() or getfenv() end)
		return ok and env or {}
	end)()

	local STATE = { linoriaInstance = nil, libraryBundle = nil, tabCount = 0, groupboxCount = 0, controlCount = 0, windowCount = 0, missingBindings = {}, errorLog = {}, notificationQueue = {}, activeNotifications = {}, notificationIndex = 0, notificationContainer = nil, activeTweens = {} }

	-- =============================
	--  UTILITY FUNCTIONS
	-- =============================

	local function log(level, message)
		if type(Core.say) == "function" then Core.say("[" .. level .. "] " .. message) end
		table.insert(STATE.errorLog, { level = level, message = message, time = os.date("%H:%M:%S") })
	end

	local function safeCall(name, fn, fallback)
		if type(fn) ~= "function" then return fallback or nil end
		local ok, result = pcall(fn)
		if not ok then log("WARN", name .. ": " .. tostring(result)); return fallback or nil end
		return result
	end

	local function textOf(value)
		if value == nil then return "" end
		if type(value) == "table" then for _, key in ipairs({ "Text", "Content", "Description", "Message", "Title", "Name" }) do if value[key] ~= nil then return textOf(value[key]) end end end
		return tostring(value)
	end

	local function deepClone(value, seen)
		if type(value) ~= "table" then return value end
		seen = seen or {}; if seen[value] then return seen[value] end
		local copy = {}; seen[value] = copy
		for k, v in pairs(value) do copy[deepClone(k, seen)] = deepClone(v, seen) end
		return copy
	end

	local function tryReadLocal(path)
		local fn = ENV.readfile; local isf = ENV.isfile
		if type(fn) ~= "function" or type(isf) ~= "function" then return nil end
		local ok, exists = pcall(isf, path); if not ok or not exists then return nil end
		local okRead, data = pcall(fn, path); return okRead and data or nil
	end

	local function tryWriteLocal(path, data)
		if type(ENV.writefile) ~= "function" then return false end
		if ENV.makefolder then pcall(ENV.makefolder, CONFIG.CACHE_FOLDER) end
		return pcall(ENV.writefile, path, data)
	end

	local function fetchUrl(url)
		if type(game.HttpGet) == "function" then
			local ok, b = pcall(game.HttpGet, game, url, true)
			if ok and type(b) == "string" and #b > CONFIG.CACHE_MIN_SIZE then return b end
			ok, b = pcall(game.HttpGet, game, url)
			if ok and type(b) == "string" and #b > CONFIG.CACHE_MIN_SIZE then return b end
		end
		if type(ENV.request) == "function" then
			local ok, res = pcall(ENV.request, { Url = url, Method = "GET" })
			if ok and type(res) == "table" then local body = res.Body or res.body; if type(body) == "string" and #body > CONFIG.CACHE_MIN_SIZE then return body end end
		end
		if type(ENV.Alleral_HTTP) == "table" and type(ENV.Alleral_HTTP.get) == "function" then return ENV.Alleral_HTTP.get(url) end
		return nil
	end

	local function parseNotificationInfo(info, fallbackTime)
		local text, duration = "", CONFIG.NOTIFICATION.DURATION
		if type(info) == "string" then text = info
		elseif type(info) == "table" then
			local title = textOf(info.Title or info.Name or "")
			local body = textOf(info.Description or info.Content or info.Text or info.Message or "")
			if title ~= "" and body ~= "" then text = title .. "\n" .. body else text = title ~= "" and title or body end
			duration = tonumber(info.Duration or info.Lifetime or info.Time or fallbackTime or CONFIG.NOTIFICATION.DURATION)
		else text = textOf(info) end
		return text, math.max(1, duration)
	end

	-- =============================
	--  ANIMATION ENGINE
	-- =============================

	local Animation = {}

	function Animation.createTween(instance, properties, duration, style, direction, reverse)
		duration = duration or 0.3
		style = style or Enum.EasingStyle.Quad
		direction = direction or Enum.EasingDirection.Out
		reverse = reverse or false
		local tweenInfo = TweenInfo.new(duration, style, direction, 0, reverse, 0)
		local tween = TweenService:Create(instance, tweenInfo, properties)
		tween:Play()
		return tween
	end

	function Animation.springValue(current, goal, speed)
		speed = speed or 12
		local dt = math.min((tick() - (Animation._lastSpringTick or tick())), 0.1)
		Animation._lastSpringTick = tick()
		local diff = goal - current
		local damping = math.exp(-speed * dt)
		local velocity = (Animation._lastVelocity or 0) * damping
		velocity = velocity + diff * (1 - damping)
		Animation._lastVelocity = velocity
		local newValue = current + velocity * math.min(speed * dt, 1)
		if math.abs(newValue - goal) < 0.0005 then
			Animation._lastVelocity = 0
			return goal, true
		end
		return newValue, false
	end

	function Animation.scaleIn(instance, duration)
		duration = duration or CONFIG.ANIMATION.WINDOW_SCALE_IN
		instance.Visible = true
		if instance:IsA("GuiObject") and not instance:FindFirstChild("_animOriginalScale") then
			local s = Instance.new("NumberValue")
			s.Name = "_animOriginalScale"
			s.Value = 0
			instance.Scale = UDim2.new(0.85, 0, 0.85, 0)
			s.Parent = instance
		end
		instance.Scale = UDim2.new(0.85, 0, 0.85, 0)
		local tween = Animation.createTween(instance, {
			Scale = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = instance.BackgroundTransparency or 0,
		}, duration, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		return tween
	end

	function Animation.fadeIn(instance, duration)
		duration = duration or CONFIG.ANIMATION.FADE_IN_DURATION
		instance.Visible = true
		if instance:IsA("GuiObject") then
			instance.BackgroundTransparency = 1
			instance.TextTransparency = 1
		end
		local props = {}
		if instance:IsA("GuiObject") then
			props.BackgroundTransparency = 0
		end
		if instance:IsA("TextLabel") or instance:IsA("TextButton") then
			props.TextTransparency = 0
		end
		return Animation.createTween(instance, props, duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end

	function Animation.fadeOut(instance, duration, hideAfter)
		duration = duration or 0.25
		hideAfter = hideAfter ~= false
		local props = {}
		if instance:IsA("GuiObject") then
			props.BackgroundTransparency = 1
		end
		if instance:IsA("TextLabel") or instance:IsA("TextButton") then
			props.TextTransparency = 1
		end
		local tween = Animation.createTween(instance, props, duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		if hideAfter then
			tween.Completed:Connect(function()
				instance.Visible = false
			end)
		end
		return tween
	end

	function Animation.slideIn(instance, fromOffset, duration)
		duration = duration or 0.25
		local origPos = instance.Position
		instance.Position = UDim2.new(origPos.X.Scale, origPos.X.Offset + fromOffset.X, origPos.Y.Scale, origPos.Y.Offset + fromOffset.Y)
		instance.Visible = true
		return Animation.createTween(instance, { Position = origPos }, duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end

	function Animation.buttonHover(button, scaleAmount, duration)
		scaleAmount = scaleAmount or CONFIG.ANIMATION.BUTTON_HOVER_SCALE
		duration = duration or 0.15
		local hoverIn = TweenService:Create(button, TweenInfo.new(duration, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(1, 0, 1, 4),
		})
		local hoverOut = TweenService:Create(button, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(1, 0, 1, 0),
		})
		local clickIn = TweenService:Create(button, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(1, 0, 1, -3),
		})
		local clickOut = TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(1, 0, 1, 4),
		})

		local mouseEnter, mouseLeave, mouseDown, mouseUp
		local inputBegan, inputEnded

		mouseEnter = button.MouseEnter:Connect(function()
			hoverOut:Cancel(); clickIn:Cancel(); clickOut:Cancel()
			hoverIn:Play()
		end)
		mouseLeave = button.MouseLeave:Connect(function()
			hoverIn:Cancel(); clickIn:Cancel(); clickOut:Cancel()
			hoverOut:Play()
		end)

		if UserInputService then
			inputBegan = UserInputService.InputBegan:Connect(function(input, gameProcessed)
				if gameProcessed then return end
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					local pos = input.Position
					if button.AbsolutePosition and button.AbsoluteSize then
						local gMin = button.AbsolutePosition
						local gMax = gMin + button.AbsoluteSize
						if pos.X >= gMin.X and pos.X <= gMax.X and pos.Y >= gMin.Y and pos.Y <= gMax.Y then
							hoverIn:Cancel(); hoverOut:Cancel(); clickOut:Cancel()
							clickIn:Play()
						end
					end
				end
			end)
			inputEnded = UserInputService.InputEnded:Connect(function(input, gameProcessed)
				if gameProcessed then return end
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					clickIn:Cancel()
					clickOut:Play()
				end
			end)
		end

		return function()
			if mouseEnter then mouseEnter:Disconnect() end
			if mouseLeave then mouseLeave:Disconnect() end
			if inputBegan then inputBegan:Disconnect() end
			if inputEnded then inputEnded:Disconnect() end
		end
	end

	function Animation.toggleThumb(thumb, enabled, duration)
		duration = duration or CONFIG.ANIMATION.TOGGLE_DURATION
		local goalX = enabled and 1 or 0
		return Animation.createTween(thumb, {
			Position = UDim2.new(goalX, enabled and -4 or 0, 0.5, 0),
		}, duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end

	function Animation.sliderFill(fill, fraction, duration)
		duration = duration or 0.2
		return Animation.createTween(fill, {
			Size = UDim2.new(math.clamp(fraction, 0, 1), 0, 1, 0),
		}, duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end

	function Animation.dropdownExpand(frame, content, open, duration)
		duration = duration or CONFIG.ANIMATION.DROPDOWN_DURATION
		if open then
			frame.Visible = true
			local targetHeight = content.AbsoluteContentSize.Y
			local tween = Animation.createTween(frame, {
				Size = UDim2.new(1, 0, 0, targetHeight + 10),
				BackgroundTransparency = 0,
			}, duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			if content:FindFirstChildOfClass("UIListLayout") then
				for i, child in ipairs(content:GetChildren()) do
					if child:IsA("GuiObject") then
						child.Visible = true
						Animation.createTween(child, {
							Position = UDim2.new(0, 0, 0, (i - 1) * 28),
						}, duration * 0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
					end
				end
			end
			return tween
		else
			local tween = Animation.createTween(frame, {
				Size = UDim2.new(1, 0, 0, 0),
				BackgroundTransparency = 1,
			}, duration * 0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			tween.Completed:Connect(function() frame.Visible = false end)
			return tween
		end
	end

	function Animation.stopAll()
		for _, tween in pairs(STATE.activeTweens) do
			if tween then pcall(function() tween:Cancel() end) end
		end
		STATE.activeTweens = {}
	end

	-- =============================
	--  VISUAL ENHANCER
	-- =============================

	local VisualEnhancer = {}

	function VisualEnhancer.applyRoundedCorners(instance, radius)
		radius = radius or 6
		pcall(function()
			if instance:FindFirstChild("_alleralCorner") then
				instance._alleralCorner:Destroy()
			end
			local corner = Instance.new("UICorner")
			corner.Name = "_alleralCorner"
			corner.CornerRadius = UDim.new(0, radius)
			corner.Parent = instance
		end)
	end

	function VisualEnhancer.applyGradient(instance, fromColor, toColor, rotation)
		rotation = rotation or 90
		pcall(function()
			if instance:FindFirstChild("_alleralGradient") then
				instance._alleralGradient:Destroy()
			end
			local gradient = Instance.new("UIGradient")
			gradient.Name = "_alleralGradient"
			gradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, fromColor),
				ColorSequenceKeypoint.new(1, toColor),
			})
			gradient.Rotation = rotation
			gradient.Parent = instance
		end)
	end

	function VisualEnhancer.applyTextGradient(instance, fromColor, toColor, rotation)
		rotation = rotation or 90
		pcall(function()
			if not instance:IsA("TextLabel") and not instance:IsA("TextButton") then return end
			if instance:FindFirstChild("_alleralTextGradient") then
				instance._alleralTextGradient:Destroy()
			end
			local gradient = Instance.new("UIGradient")
			gradient.Name = "_alleralTextGradient"
			gradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, fromColor),
				ColorSequenceKeypoint.new(1, toColor),
			})
			gradient.Rotation = rotation
			gradient.Parent = instance
		end)
	end

	function VisualEnhancer.applyStroke(instance, color, thickness, transparency)
		thickness = thickness or 1
		transparency = transparency or 0.5
		pcall(function()
			if instance:FindFirstChild("_alleralStroke") then
				instance._alleralStroke:Destroy()
			end
			local stroke = Instance.new("UIStroke")
			stroke.Name = "_alleralStroke"
			stroke.Color = color or CONFIG.THEME.BORDER
			stroke.Thickness = thickness
			stroke.Transparency = transparency
			stroke.Parent = instance
		end)
	end

	function VisualEnhancer.enhanceButton(button)
		pcall(function()
			if not button:IsA("TextButton") and not button:IsA("ImageButton") then return end
			if button:FindFirstChild("_alleralEnhanced") then return end

			local marker = Instance.new("BoolValue")
			marker.Name = "_alleralEnhanced"
			marker.Value = true
			marker.Parent = button

			button.BackgroundColor3 = CONFIG.THEME.SURFACE
			button.BorderSizePixel = 0
			button.AutoButtonColor = false
			VisualEnhancer.applyRoundedCorners(button, 6)
			VisualEnhancer.applyStroke(button, CONFIG.THEME.BORDER, 1, 0.6)

			local hoverBc = button:FindFirstChild("_hoverBc") or Instance.new("BoolValue")
			hoverBc.Name = "_hoverBc"
			hoverBc.Parent = button

			local connectHover = button.MouseEnter:Connect(function()
				hoverBc.Value = true
				Animation.createTween(button, { BackgroundColor3 = CONFIG.THEME.SURFACE_HOVER }, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			end)
			local connectLeave = button.MouseLeave:Connect(function()
				hoverBc.Value = false
				Animation.createTween(button, { BackgroundColor3 = CONFIG.THEME.SURFACE }, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			end)
			local connectDown = button.MouseButton1Down:Connect(function()
				Animation.createTween(button, { BackgroundColor3 = CONFIG.THEME.PRIMARY_DARK }, 0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			end)
			local connectUp = button.MouseButton1Up:Connect(function()
				Animation.createTween(button, { BackgroundColor3 = hoverBc.Value and CONFIG.THEME.SURFACE_HOVER or CONFIG.THEME.SURFACE }, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			end)

			button._alleralConnections = { connectHover, connectLeave, connectDown, connectUp }
		end)
	end

	function VisualEnhancer.enhanceToggle(toggle)
		pcall(function()
			if toggle:FindFirstChild("_alleralEnhanced") then return end
			local marker = Instance.new("BoolValue")
			marker.Name = "_alleralEnhanced"
			marker.Value = true
			marker.Parent = toggle

			local frame = toggle:FindFirstChildWhichIsA("Frame") or toggle
			if frame then
				frame.BorderSizePixel = 0
				VisualEnhancer.applyRoundedCorners(frame, 4)
			end
		end)
	end

	function VisualEnhancer.enhanceSlider(slider)
		pcall(function()
			if slider:FindFirstChild("_alleralEnhanced") then return end
			local marker = Instance.new("BoolValue")
			marker.Name = "_alleralEnhanced"
			marker.Value = true
			marker.Parent = slider

			local fill = slider:FindFirstChild("Fill") or slider:FindFirstChild("Bar")
			if fill then
				VisualEnhancer.applyRoundedCorners(fill, 4)
				VisualEnhancer.applyGradient(fill, CONFIG.THEME.PRIMARY, CONFIG.THEME.PRIMARY_DARK, 0)
			end
			local thumb = slider:FindFirstChild("Thumb") or slider:FindFirstChild("Dot")
			if thumb then
				VisualEnhancer.applyRoundedCorners(thumb, 8)
				thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				VisualEnhancer.applyStroke(thumb, CONFIG.THEME.PRIMARY, 2, 0)
			end
		end)
	end

	function VisualEnhancer.enhanceInput(input)
		pcall(function()
			if not input:IsA("TextBox") then return end
			if input:FindFirstChild("_alleralEnhanced") then return end
			local marker = Instance.new("BoolValue")
			marker.Name = "_alleralEnhanced"
			marker.Value = true
			marker.Parent = input

			input.BorderSizePixel = 0
			input.BackgroundColor3 = CONFIG.THEME.BACKGROUND_ALT
			VisualEnhancer.applyRoundedCorners(input, 4)
			VisualEnhancer.applyStroke(input, CONFIG.THEME.BORDER, 1, 0.7)

			input.Focused:Connect(function()
				Animation.createTween(input, { BackgroundColor3 = CONFIG.THEME.SURFACE }, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				VisualEnhancer.applyStroke(input, CONFIG.THEME.PRIMARY, 2, 0)
			end)
			input.FocusLost:Connect(function(enterPressed)
				Animation.createTween(input, { BackgroundColor3 = CONFIG.THEME.BACKGROUND_ALT }, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				VisualEnhancer.applyStroke(input, CONFIG.THEME.BORDER, 1, 0.7)
			end)
		end)
	end

	function VisualEnhancer.enhanceDropdown(dropdown)
		pcall(function()
			if dropdown:FindFirstChild("_alleralEnhanced") then return end
			local marker = Instance.new("BoolValue")
			marker.Name = "_alleralEnhanced"
			marker.Value = true
			marker.Parent = dropdown

			if dropdown:IsA("TextButton") or dropdown:IsA("ImageButton") then
				dropdown.BorderSizePixel = 0
				dropdown.BackgroundColor3 = CONFIG.THEME.SURFACE
				VisualEnhancer.applyRoundedCorners(dropdown, 6)
				VisualEnhancer.applyStroke(dropdown, CONFIG.THEME.BORDER, 1, 0.6)
			end
		end)
	end

	function VisualEnhancer.enhanceWindow(windowFrame)
		pcall(function()
			if not windowFrame then return end
			if windowFrame:FindFirstChild("_alleralWindowEnhanced") then return end

			local marker = Instance.new("BoolValue")
			marker.Name = "_alleralWindowEnhanced"
			marker.Value = true
			marker.Parent = windowFrame

			if windowFrame:IsA("GuiObject") then
				windowFrame.BorderSizePixel = 0
				VisualEnhancer.applyRoundedCorners(windowFrame, 10)
				VisualEnhancer.applyStroke(windowFrame, CONFIG.THEME.BORDER, 1.5, 0.4)
			end

			-- Apply dark background
			local function walkTree(parent)
				for _, child in ipairs(parent:GetChildren()) do
					if child:IsA("Frame") and not child:FindFirstChild("_alleralEnhanced") then
						local m = Instance.new("BoolValue")
						m.Name = "_alleralEnhanced"
						m.Value = true
						m.Parent = child
						if child.BackgroundColor3 == Color3.fromRGB(255, 255, 255) or
						   child.BackgroundColor3 == Color3.fromRGB(240, 240, 240) or
						   child.BackgroundColor3 == Color3.fromRGB(245, 245, 245) then
							child.BackgroundColor3 = CONFIG.THEME.BACKGROUND
						end
						child.BorderSizePixel = 0
					end
					if child:IsA("ScrollingFrame") and not child:FindFirstChild("_alleralEnhanced") then
						local m = Instance.new("BoolValue")
						m.Name = "_alleralEnhanced"
						m.Value = true
						m.Parent = child
						child.BorderSizePixel = 0
						child.ScrollBarImageColor3 = CONFIG.THEME.SCROLLBAR
					end
					if (child:IsA("TextLabel") or child:IsA("TextButton")) and
					   (child.TextColor3 == Color3.fromRGB(0, 0, 0) or
					    child.TextColor3 == Color3.fromRGB(50, 50, 50)) then
						child.TextColor3 = CONFIG.THEME.TEXT
					end
					walkTree(child)
				end
			end
			walkTree(windowFrame)

			-- Enhance all buttons, toggles, sliders, inputs, dropdowns
			for _, child in ipairs(windowFrame:GetDescendants()) do
				if child:IsA("TextButton") or child:IsA("ImageButton") then
					VisualEnhancer.enhanceButton(child)
				elseif child:IsA("TextBox") then
					VisualEnhancer.enhanceInput(child)
				end
			end

			-- Window entry animation
			Animation.scaleIn(windowFrame, CONFIG.ANIMATION.WINDOW_SCALE_IN)
		end)
	end

	function VisualEnhancer.enhanceScrollFrame(sf)
		pcall(function()
			if not sf:IsA("ScrollingFrame") then return end
			sf.BorderSizePixel = 0
			sf.ScrollBarImageColor3 = CONFIG.THEME.SCROLLBAR
			sf.ScrollBarThickness = 4
			if sf:FindFirstChild("_alleralEnhanced") then return end
			local m = Instance.new("BoolValue")
			m.Name = "_alleralEnhanced"
			m.Value = true
			m.Parent = sf
		end)
	end

	-- =============================
	--  ANIMATED NOTIFICATION SYSTEM
	-- =============================

	local NotificationSystem = {}

	function NotificationSystem.getContainer()
		if STATE.notificationContainer and STATE.notificationContainer.Parent then
			return STATE.notificationContainer
		end
		local screen = Instance.new("ScreenGui")
		screen.Name = "AlleralNotifications"
		screen.ResetOnSpawn = false
		screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		screen.DisplayOrder = 999

		local container = Instance.new("Frame")
		container.Name = "NotificationContainer"
		container.AnchorPoint = Vector2.new(1, 0.5)
		container.Position = UDim2.new(1, -20, 0.5, 0)
		container.Size = UDim2.new(0, 280, 1, -40)
		container.BackgroundTransparency = 1
		container.BorderSizePixel = 0
		container.Parent = screen

		local list = Instance.new("UIListLayout")
		list.Name = "NotificationList"
		list.Padding = UDim.new(0, 8)
		list.HorizontalAlignment = Enum.HorizontalAlignment.Right
		list.VerticalAlignment = Enum.VerticalAlignment.Bottom
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.Parent = container

		screen.Parent = game:GetService("CoreGui"):FindFirstChild("RobloxGui") or game:GetService("CoreGui")
		STATE.notificationContainer = container
		return container
	end

	function NotificationSystem.createNotification(text, duration)
		duration = duration or CONFIG.NOTIFICATION.DURATION
		STATE.notificationIndex = STATE.notificationIndex + 1

		local container = NotificationSystem.getContainer()

		local frame = Instance.new("Frame")
		frame.Name = "Notification_" .. STATE.notificationIndex
		frame.Size = UDim2.new(1, -10, 0, 0)
		frame.BackgroundColor3 = CONFIG.THEME.SURFACE
		frame.BorderSizePixel = 0
		frame.ClipsDescendants = false
		frame.LayoutOrder = STATE.notificationIndex
		frame.Parent = container

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 8)
		corner.Parent = frame

		local stroke = Instance.new("UIStroke")
		stroke.Color = CONFIG.THEME.BORDER
		stroke.Thickness = 1
		stroke.Transparency = 0.5
		stroke.Parent = frame

		local gradient = Instance.new("UIGradient")
		gradient.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, CONFIG.THEME.PRIMARY),
			ColorSequenceKeypoint.new(1, CONFIG.THEME.PRIMARY_DARK),
		})
		gradient.Rotation = 90
		gradient.Parent = frame

		local accentBar = Instance.new("Frame")
		accentBar.Name = "Accent"
		accentBar.Size = UDim2.new(0, 3, 1, 0)
		accentBar.BackgroundColor3 = CONFIG.THEME.PRIMARY
		accentBar.BorderSizePixel = 0
		accentBar.Parent = frame

		local textLabel = Instance.new("TextLabel")
		textLabel.Name = "Content"
		textLabel.Size = UDim2.new(1, -16, 1, -12)
		textLabel.Position = UDim2.new(0, 12, 0, 6)
		textLabel.BackgroundTransparency = 1
		textLabel.Text = text
		textLabel.TextColor3 = CONFIG.THEME.TEXT
		textLabel.Font = Enum.Font.Gotham
		textLabel.TextSize = 13
		textLabel.TextWrapped = true
		textLabel.TextXAlignment = Enum.TextXAlignment.Left
		textLabel.TextYAlignment = Enum.TextYAlignment.Center
		textLabel.RichText = false
		textLabel.Parent = frame

		local uiPad = Instance.new("UIPadding")
		uiPad.PaddingTop = UDim.new(0, 6)
		uiPad.PaddingBottom = UDim.new(0, 6)
		uiPad.Parent = frame

		local autoSize = Instance.new("UITextSizeConstraint")
		autoSize.MaxTextSize = 14
		autoSize.Parent = textLabel

		task.wait(0.05)
		local contentHeight = textLabel.TextBounds.Y + 20
		contentHeight = math.max(contentHeight, 44)

		-- Slide in from right
		local tweenIn = Animation.createTween(frame, {
			Size = UDim2.new(1, -10, 0, contentHeight),
			Position = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 0,
		}, CONFIG.NOTIFICATION.ANIMATION_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

		-- Remove excess notifications
		local allNotifications = {}
		for _, child in ipairs(container:GetChildren()) do
			if child:IsA("Frame") and child.Name:find("Notification_") then
				table.insert(allNotifications, child)
			end
		end
		table.sort(allNotifications, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
		while #allNotifications > CONFIG.NOTIFICATION.MAX_STACK do
			local oldest = allNotifications[1]
			table.remove(allNotifications, 1)
			NotificationSystem.dismissNotification(oldest, true)
		end

		-- Auto dismiss
		task.delay(duration, function()
			if frame and frame.Parent then
				NotificationSystem.dismissNotification(frame, false)
			end
		end)

		-- Click to dismiss
		frame.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				NotificationSystem.dismissNotification(frame, false)
			end
		end)

		return frame
	end

	function NotificationSystem.dismissNotification(frame, instant)
		if not frame or not frame.Parent then return end
		if instant then
			frame:Destroy()
			return
		end
		local tweenOut = Animation.createTween(frame, {
			Position = UDim2.new(1, 0, 0, 0),
			BackgroundTransparency = 1,
		}, CONFIG.NOTIFICATION.FADE_OUT_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		tweenOut.Completed:Connect(function()
			if frame then frame:Destroy() end
		end)
		for _, child in ipairs(frame:GetDescendants()) do
			if child:IsA("TextLabel") then
				Animation.createTween(child, { TextTransparency = 1 }, CONFIG.NOTIFICATION.FADE_OUT_DURATION * 0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			end
		end
	end

	function NotificationSystem.notify(text, duration)
		return NotificationSystem.createNotification(text, duration)
	end

	-- =============================
	--  LINORIA LOADING & COMPILATION
	-- =============================

	local function compileLinoria(source, loadStringFn)
		if not source or #source <= 100 then return nil end
		if source:find("<!DOCTYPE", 1, true) or source:find("<html", 1, true) then return nil end
		source = source:gsub("^%s+", ""):gsub("%s+$", "")
		local chunk, err = loadStringFn(source, "@Linoria/source")
		if type(chunk) ~= "function" and type(load) == "function" then chunk, err = load(source, "@Linoria/source") end
		if type(chunk) ~= "function" then return nil end
		if setfenv then pcall(setfenv, chunk, ENV) end
		local ok, pkg = pcall(chunk); if not ok then return nil end
		if type(pkg) ~= "table" or type(pkg.CreateWindow) ~= "function" then return nil end

		-- Patch Linoria's Notify to use animated notifications
		if type(pkg.Notify) == "function" and pkg._AlleralNotifyShim ~= true then
			local orig = pkg.Notify
			function pkg:Notify(text, duration)
				local t, d = parseNotificationInfo(text, duration)
				NotificationSystem.createNotification(t, d)
				return nil
			end
			pkg._AlleralNotifyShim = true
		end

		STATE.linoriaInstance = pkg; ENV._AlleralUI = pkg
		return pkg
	end

	local function loadLinoriaSource()
		if type(STATE.linoriaInstance) == "table" and type(STATE.linoriaInstance.CreateWindow) == "function" then
			return STATE.linoriaInstance
		end
		local fn = ENV.loadstring or loadstring or load
		if type(fn) ~= "function" then return nil end
		local body = tryReadLocal("ui/linoria.luau") or tryReadLocal(CONFIG.CACHE_FOLDER .. "/linoria.lua")
		if not body then
			for attempt = 1, 3 do
				body = safeCall("FetchLinoria", function()
					return fetchUrl(CONFIG.LINORIA_REPO .. "?t=" .. tostring(tick()) .. tostring(math.random(10000, 99999)))
				end)
				if type(body) == "string" and #body > CONFIG.CACHE_MIN_SIZE then break end
				if attempt < 3 then task.wait(0.3) end
			end
			if body and #body > CONFIG.CACHE_MIN_SIZE then
				tryWriteLocal(CONFIG.CACHE_FOLDER .. "/linoria.lua", body)
			end
		end
		return compileLinoria(body, fn)
	end

	-- =============================
	--  LIBRARY BUILDER
	-- =============================

	local function buildLibrary(Linoria)
		local Library = { Version = CONFIG.VERSION, _linoria = Linoria }

		function Library:GetLayoutInfo()
			return { profile = "linoria", engine = "Linoria", version = CONFIG.VERSION }
		end

		function Library:Notification(info)
			local text, dur = parseNotificationInfo(info, nil)
			NotificationSystem.createNotification(text, dur)
		end

		function Library:Notify(text, dur)
			if type(text) == "table" then
				Library:Notification(text)
			else
				Library:Notification({ Description = text, Duration = dur })
			end
		end

		function Library:ClearNotifications()
			-- Clear active notifications
			if STATE.notificationContainer then
				for _, child in ipairs(STATE.notificationContainer:GetChildren()) do
					if child:IsA("Frame") and child.Name:find("Notification_") then
						NotificationSystem.dismissNotification(child, true)
					end
				end
			end
		end

		function Library:CreateWindow(settings)
			settings = deepClone(type(settings) == "table" and settings or {})
			local li = loadLinoriaSource()
			if not li then return nil end

			local title = settings.Title or settings.Name or "Alleral"
			local liWindow
			local winCfg = {
				Title = title,
				Center = settings.Center ~= false,
				AutoShow = settings.AutoShow ~= false,
				Size = settings.Size or UDim2.fromOffset(720, 520),
			}

			local okW, errW = pcall(function()
				liWindow = li:CreateWindow(winCfg)
			end)
			if not okW or not liWindow then return nil end

			-- Apply visual enhancements to the window
			task.wait(0.1)
			if liWindow then
				local windowGui = liWindow.Container or liWindow.Window
				if windowGui and windowGui:IsA("Instance") then
					VisualEnhancer.enhanceWindow(windowGui)
				end
			end

			local window = {
				_liWindow = liWindow,
				_linoria = li,
				_library = Library,
				_tabs = {},
				_settings = settings,
				_title = title,
			}

			function window:AddTab(name, icon)
				STATE.tabCount = STATE.tabCount + 1
				local ok, t = pcall(function() return liWindow:AddTab(name) end)

				if ok and t then
					table.insert(window._tabs, t)

					-- Apply visual enhancements to the tab content
					task.wait(0.05)
					pcall(function()
						if t.Container then
							VisualEnhancer.enhanceScrollFrame(t.Container)
						end
						-- Walk children for scroll frames
						if t.Container then
							for _, child in ipairs(t.Container:GetDescendants()) do
								if child:IsA("ScrollingFrame") then
									VisualEnhancer.enhanceScrollFrame(child)
								end
							end
						end
					end)
				else
					table.insert(STATE.missingBindings, "Tab:" .. tostring(name))
				end

				return t, window
			end

			function window:Notify(p)
				p = type(p) == "table" and p or {}
				Library:Notification(p)
			end

			function window:Unload()
				-- Fade out and destroy the window
				pcall(function()
					local windowGui = liWindow.Container or liWindow.Window
					if windowGui and windowGui:IsA("Instance") then
						Animation.fadeOut(windowGui, 0.2, true)
						task.wait(0.25)
					end
				end)
				pcall(function()
					if liWindow.Destroy then liWindow:Destroy() end
				end)
			end

			ENV.Alleral_UiWindow = window
			STATE.windowCount = STATE.windowCount + 1
			return window
		end

		return Library
	end

	-- =============================
	--  CORE API FUNCTIONS
	-- =============================

	function Core.loadUi()
		local cached = ENV.Alleral_UI
		if type(cached) == "table" and type(cached.Library) == "table" then return cached end

		local Li = loadLinoriaSource()
		if not Li then
			local s = {
				Library = { Version = CONFIG.VERSION },
				CreateWindow = function() return nil end,
				Notify = function() end,
			}
			ENV.Alleral_UI = s
			if getgenv then getgenv().Alleral_UI = s end
			return s
		end

		local Lib = buildLibrary(Li)
		ENV._AlleralUiLibrary = Lib

		local b = {
			Library = Lib,
			Alleral = Lib,
			CreateWindow = function(_, s) return Lib:CreateWindow(s) end,
			Notify = function(_, i, t) Lib:Notify(i, t) end,
			ClearNotifications = function() Lib:ClearNotifications() end,
			_linoria = Li,
		}

		ENV.Alleral_UI = b
		if getgenv then getgenv().Alleral_UI = b end
		return b
	end

	function Core.preloadUi() return Core.loadUi() end
	function Core.uiLibrary(b) if type(b) ~= "table" then return nil end; return b.Alleral or b.Library end

	function Core.uiWindowSettings(extra)
		extra = type(extra) == "table" and extra or {}
		return {
			Title = extra.Title or extra.Name or "Alleral",
			Name = extra.Title or extra.Name or "Alleral",
			Subtitle = extra.Subtitle or extra.Author or "",
			Icon = extra.Icon or "sparkles",
			Theme = extra.Theme or "Default",
			Size = extra.Size or UDim2.fromOffset(720, 520),
			TabWidth = tonumber(extra.TabWidth) or 160,
			FileSettings = {
				RootFolder = extra.configFolder or "Alleral_Configs",
				ConfigFolder = extra.FileName or "Interface",
			},
		}
	end

	-- =============================
	--  GROUPBOX CREATION
	-- =============================

	local function createGroupbox(section, uiBundle)
		section = type(section) == "table" and section or {}
		local s = 0
		local function ni(n, e) s = s + 1; return e or (Core.uiElementId and Core.uiElementId(n) or n) .. "_" .. s end
		local function wc(as, m)
			m = type(m) == "table" and m or {}; local w = { _raw = m.raw }
			function w:Set(v) if type(v) == "table" then as(v) else as({ CurrentValue = v }) end end
			if m.bindKey and Core.bindUiState then Core.bindUiState(m.bindKey, w, m.kind or "toggle", m.raw) end
			return w
		end

		local gb = {}

		function gb:CreateSection(n) return gb end

		function gb:AddLabel(t)
			if not section or type(section.AddLabel) ~= "function" then
				return { SetText = function() end, Set = function() end, Visible = true }
			end
			return safeCall("AddLabel", function() return section:AddLabel(textOf(t)) end)
				or { SetText = function() end, Set = function() end, Visible = true }
		end

		function gb:CreateLabel(st, id)
			local t = type(st) == "table" and (st.Name or st.Text) or tostring(st or "")
			local r = safeCall("Label", function() return section:AddLabel(t) end)
			STATE.controlCount = STATE.controlCount + 1
			return {
				Set = function(_, ns)
					if not r then return end
					local nt = type(ns) == "table" and (ns.Name or ns.Text) or tostring(ns or "")
					if r.SetText then pcall(r.SetText, r, nt) end
				end,
				SetText = function(_, tv)
					if r and r.SetText then pcall(r.SetText, r, textOf(tv)) end
				end,
				SetVisible = function(_, v)
					if r then pcall(function() r.Visible = v == true end) end
				end,
			}
		end

		function gb:CreateToggle(st, id)
			local cv = st.Default or st.CurrentValue or st.Value
			local fl = ni(st.Name, id)
			local r = safeCall("Toggle:" .. tostring(st.Name), function()
				return section:AddToggle(fl, {
					Text = st.Name or st.Title or "Toggle",
					Default = cv == true,
					Callback = st.Callback or function() end,
				})
			end)
			STATE.controlCount = STATE.controlCount + 1
			if not r then table.insert(STATE.missingBindings, "Toggle:" .. tostring(st.Name)) end

			-- Apply toggle animations
			if r then
				task.wait(0.02)
				pcall(function()
					if r.Container then
						VisualEnhancer.enhanceToggle(r.Container)
					end
				end)
			end

			return wc(function(n)
				if not r then return end
				local v = n.CurrentValue or n.Value
				if v == nil then v = n end
				if r.SetValue then pcall(r.SetValue, r, v == true) end
			end, { raw = r, bindKey = st.BindKey or st.StateKey, kind = "toggle" })
		end

		function gb:CreateButton(st, id)
			local nm = st.Name or st.Title or st.Text or "Button"
			local r = safeCall("Button:" .. nm, function()
				return section:AddButton({
					Text = nm,
					Func = st.Callback or function() end,
				})
			end)
			STATE.controlCount = STATE.controlCount + 1
			if not r then table.insert(STATE.missingBindings, "Button:" .. nm) end

			-- Apply button animations
			if r then
				task.wait(0.02)
				pcall(function()
					if r.Container then
						VisualEnhancer.enhanceButton(r.Container)
					end
				end)
			end

			return wc(function() end, { raw = r, kind = "button" })
		end

		function gb:CreateSlider(st, id)
			local rn = st.Range or { 0, 100 }
			local fl = ni(st.Name, id)
			local cv = tonumber(st.Default) or tonumber(st.CurrentValue) or tonumber(st.Value) or rn[1]
			local r = safeCall("Slider:" .. tostring(st.Name), function()
				return section:AddSlider(fl, {
					Text = st.Name or st.Title or "Slider",
					Default = cv,
					Min = rn[1] or 0,
					Max = rn[2] or 100,
					Suffix = st.Suffix or "",
					Rounding = tonumber(st.Increment) or 1,
					Compact = st.Compact or false,
					Callback = st.Callback or function() end,
				})
			end)
			STATE.controlCount = STATE.controlCount + 1
			if not r then table.insert(STATE.missingBindings, "Slider:" .. tostring(st.Name)) end

			-- Apply slider animations
			if r then
				task.wait(0.02)
				pcall(function()
					if r.Container then
						VisualEnhancer.enhanceSlider(r.Container)
					end
				end)
			end

			return wc(function(n)
				if not r then return end
				local v = tonumber(n.CurrentValue) or tonumber(n.Value) or tonumber(n)
				if v and r.SetValue then pcall(r.SetValue, r, v) end
			end, { raw = r, bindKey = st.BindKey or st.StateKey, kind = "slider" })
		end

		function gb:CreateInput(st, id)
			local fl = ni(st.Name, id)
			local cv = tostring(st.CurrentValue or st.Default or st.Value or "")
			local r = safeCall("Input:" .. tostring(st.Name), function()
				return section:AddInput(fl, {
					Text = st.Name or st.Title or "Input",
					Default = cv,
					Placeholder = st.PlaceholderText or st.Placeholder or "Enter...",
					Callback = st.Callback or function() end,
				})
			end)
			STATE.controlCount = STATE.controlCount + 1
			if not r then table.insert(STATE.missingBindings, "Input:" .. tostring(st.Name)) end

			-- Apply input animations
			if r then
				task.wait(0.02)
				pcall(function()
					if r.Container then
						VisualEnhancer.enhanceInput(r.Container)
					end
				end)
			end

			return wc(function(n)
				if not r then return end
				local v = tostring(n.CurrentValue or n.Value or "")
				if r.SetValue then pcall(r.SetValue, r, v) end
			end, { raw = r, bindKey = st.BindKey or st.StateKey, kind = "input" })
		end

		function gb:CreateDropdown(st, id)
			local op = st.Options or st.Values or {}
			local mu = st.MultipleOptions == true or st.Multi == true
			local cu = st.CurrentOption or (mu and {} or (op[1] or ""))
			local fl = ni(st.Name, id)
			local r = safeCall("Dropdown:" .. tostring(st.Name), function()
				return section:AddDropdown(fl, {
					Text = st.Name or st.Title or "Dropdown",
					Values = op,
					Default = mu and (type(cu) == "table" and cu[1] or cu) or (type(cu) == "table" and cu[1] or cu or op[1] or ""),
					Multi = mu,
					Callback = function(sel)
						local cb = st.Callback or function() end
						if mu then
							cb(Core.normalizeMultiSelection and Core.normalizeMultiSelection(sel) or sel)
						else
							cb(Core.normalizeDropdownValue and Core.normalizeDropdownValue(sel, op[1]) or sel)
						end
					end,
				})
			end)
			STATE.controlCount = STATE.controlCount + 1
			if not r then table.insert(STATE.missingBindings, "Dropdown:" .. tostring(st.Name)) end

			-- Apply dropdown animations
			if r then
				task.wait(0.02)
				pcall(function()
					if r.Container then
						VisualEnhancer.enhanceDropdown(r.Container)
					end
				end)
			end

			return wc(function(n)
				if not r then return end
				local nv = n.Options or n.Values
				local p = n.CurrentOption or n.CurrentOptions
				if type(nv) == "table" and r.Refresh then pcall(r.Refresh, r, nv) end
				if p ~= nil and r.SetValue then pcall(r.SetValue, r, tostring(p)) end
			end, { raw = r, bindKey = st.BindKey or st.StateKey, kind = "dropdown" })
		end

		function gb:CreateDivider()
			safeCall("Divider", function() return section:AddDivider() end)
			STATE.controlCount = STATE.controlCount + 1
			return {}
		end

		function gb:CreateStatus(settings, fields)
			local title, dfs = nil, {}
			if type(settings) == "table" then
				title = settings.Name or settings.Title or settings.Label or "Status"
				dfs = settings.Fields or settings.Values or settings.Items or settings.Stats or settings.Data
				if type(dfs) ~= "table" then
					dfs = { Status = settings.Status or settings.Text or settings.Value or "--" }
				end
			else
				title = settings or "Status"
				dfs = type(fields) == "table" and fields or { Status = fields or "--" }
			end

			local st = { Labels = {}, LastValues = {}, Summary = nil }
			if title and textOf(title) ~= "" then st.Title = gb:AddLabel(textOf(title)) end
			for k, v in pairs(dfs) do
				local r = textOf(v)
				st.LastValues[k] = r
				st.Labels[k] = gb:AddLabel(textOf(k) .. ": " .. r)
			end
			st.Summary = gb:AddLabel("")

			function st:Update(key, value)
				local r = textOf(value)
				if self.LastValues[key] == r then return end
				self.LastValues[key] = r
				local row = self.Labels[key]
				if row and row.SetText then
					pcall(row.SetText, row, textOf(key) .. ": " .. r)
				elseif row and row.Set then
					pcall(row.Set, row, { Name = textOf(key) .. ": " .. r, Text = textOf(key) .. ": " .. r })
				end
			end

			function st:SetSummary(text)
				if self.Summary and self.Summary.SetText then
					pcall(self.Summary.SetText, self.Summary, textOf(text))
				elseif self.Summary and self.Summary.Set then
					pcall(self.Summary.Set, self.Summary, { Name = textOf(text), Text = textOf(text) })
				end
			end

			function st:Set(key, value)
				if type(key) == "table" then
					for k, v in pairs(key) do self:Update(k, v) end
				else
					self:Update(key, value)
				end
			end

			return st
		end

		return gb
	end

	function Core.createUiGroupbox(section, uiBundle)
		return createGroupbox(section, uiBundle)
	end

	-- =============================
	--  UI WRAPPERS
	-- =============================

	function Core.wrapUiGroup(groupbox, callbackWrapper)
		local group = {}
		function group:CreateToggle(name, def, tip, cb, bk)
			return groupbox:CreateToggle({
				Name = name, CurrentValue = def == true, Default = def == true,
				Tooltip = tip, Callback = cb or function() end, BindKey = bk,
			}, bk)
		end
		function group:CreateSlider(name, mn, mx, def, cb, tip, inc, bk)
			return groupbox:CreateSlider({
				Name = name, Range = { mn, mx }, CurrentValue = def or mn, Default = def or mn,
				Tooltip = tip, Increment = inc, Callback = cb or function() end, BindKey = bk,
			}, bk)
		end
		function group:CreateButton(name, cb, tip)
			return groupbox:CreateButton({
				Name = name, Tooltip = tip, Callback = cb or function() end,
			})
		end
		function group:CreateInput(name, ph, a3, a4, a5)
			local icon, def, cb, tip = nil, "", nil, nil
			if type(a3) == "function" then cb, tip = a3, a4
			elseif type(a4) == "function" then icon, cb, tip = a3, a4, a5
			else
				if type(a3) == "string" or type(a3) == "number" then def = a3 end
				if type(a4) == "function" then cb = a4 end
				tip = a5
			end
			return groupbox:CreateInput({
				Name = name, PlaceholderText = ph, CurrentValue = def, Default = def,
				Tooltip = tip, Callback = cb or function() end,
			})
		end
		function group:CreateDropdown(name, op, def, cb, tip, bk)
			return groupbox:CreateDropdown({
				Name = name, Options = op, CurrentOption = def,
				Tooltip = tip, Callback = cb or function() end, BindKey = bk,
			}, bk)
		end
		function group:AddDropdown(id, cfg)
			cfg = type(cfg) == "table" and cfg or {}
			return groupbox:CreateDropdown({
				Name = cfg.Text or cfg.Name or id,
				Options = cfg.Values or cfg.Options or {},
				CurrentOption = cfg.Default or cfg.CurrentValue or cfg.CurrentOption,
				MultipleOptions = cfg.Multi or cfg.MultiSelection,
				Callback = cfg.Callback or function() end,
			}, id)
		end
		function group:CreateStatus(label, fields)
			if type(label) == "table" then return groupbox:CreateStatus(label) end
			return groupbox:CreateStatus({ Name = label or "Status", Fields = fields })
		end
		function group:AddLabel(text) return groupbox:AddLabel(text) end
		function group:CreateLabel(text) return groupbox:CreateLabel({ Name = text }) end
		function group:CreateDivider() return groupbox:CreateDivider() end
		return group
	end

	function Core.wrapUiTab(rawTab, uiBundle, window)
		local tab = { _rawTab = rawTab, _ui = uiBundle, _window = window, _columnCount = 2, _sectionIndex = 0 }
		if type(Core._UiTabRegistry) == "table" then table.insert(Core._UiTabRegistry, tab) end

		function tab:CreateGroupbox(settings)
			settings = settings or {}
			local name = settings.Name or settings.Group or "Group"
			STATE.groupboxCount = STATE.groupboxCount + 1
			if not rawTab then
				table.insert(STATE.missingBindings, "Groupbox:" .. name .. "(no tab)")
				return {}
			end
			local h = safeCall("Groupbox:" .. name, function()
				local col = tonumber(settings.Column) or 1
				if col == 2 and rawTab.AddRightGroupbox then
					return rawTab:AddRightGroupbox(name)
				elseif rawTab.AddLeftGroupbox then
					return rawTab:AddLeftGroupbox(name)
				else
					return rawTab:AddGroupbox(name)
				end
			end)
			if not h then
				table.insert(STATE.missingBindings, "Groupbox:" .. name .. "(failed)")
				return {}
			end
			tab._sectionIndex = (tab._sectionIndex or 0) + 1
			return Core.createUiGroupbox(h, uiBundle)
		end

		function tab:Select()
			if rawTab and rawTab.Select then pcall(rawTab.Select, rawTab) end
		end

		function tab:BuildThemeGroupbox(column)
			local g = Core.buildUiGroup(tab, "Appearance", column or 1)
			g:CreateLabel("Linoria UI engine.")
			return g
		end

		return tab
	end

	function Core.buildUiWindow(ui, settings)
		settings = settings or {}
		local lib = ui and ui.Library
		if not lib or type(lib.CreateWindow) ~= "function" then return nil end
		local rw = lib:CreateWindow(settings)
		if not rw then return nil end
		local w = {
			_rawWindow = rw, _ui = ui, _library = lib, _initialized = false,
			_tabGroup = rw, _alleralSettings = settings,
		}
		if type(Core.registerUiWindow) == "function" then Core.registerUiWindow(w) end
		if type(Core.flushPendingNotifications) == "function" then Core.flushPendingNotifications() end
		return w
	end

	function Core.buildUiTab(section, name, icon, columns, id)
		local w = type(Core.resolveUiWindow) == "function" and Core.resolveUiWindow(section) or nil
		if type(w) ~= "table" or not w._rawWindow then
			return Core.wrapUiTab(nil, type(section) == "table" and section._ui or nil, w)
		end
		local tg = w._tabGroup or w
		if not tg or type(tg.AddTab) ~= "function" then
			return Core.wrapUiTab(nil, w._ui, w)
		end
		local rt = tg:AddTab(name, icon)
		STATE.tabCount = STATE.tabCount + 1
		local wr = Core.wrapUiTab(rt, w._ui or (type(section) == "table" and section._ui) or nil, w)
		wr._columnCount = math.max(1, tonumber(columns) or 2)
		if not w._defaultTab then w._defaultTab = rt end
		return wr
	end

	function Core.buildUiGroup(tab, name, column, callbackWrapper, icon, id)
		name = tostring(name or "Group")
		if type(tab) ~= "table" or type(tab.CreateGroupbox) ~= "function" then return {} end
		return Core.wrapUiGroup(tab:CreateGroupbox({ Name = name, Column = column or 1, Icon = icon }), callbackWrapper)
	end

	function Core.buildUiSection(window)
		if type(window) == "table" and window._alleralTabGroup then return window._alleralTabGroup end
		if type(window) == "table" and window._rawWindow then return window end
		return window
	end

	function Core.finalizeGameUi(window, ui, options)
		options = type(options) == "table" and options or {}
		if type(window) == "table" and window._rawWindow and not window._initialized then
			window._initialized = true
			task.defer(function()
				pcall(function()
					if window._defaultTab and window._defaultTab.Select then
						window._defaultTab:Select()
					end
				end)
			end)
		end
		if type(Core.setupHubKeybinds) == "function" then
			pcall(Core.setupHubKeybinds, { window = window, ui = ui or window._ui or ENV.Alleral_UI })
		end
		if options.notify ~= false then
			Core.notifyBootReady({ Name = options.Name or "Alleral", Subtitle = options.Subtitle })
		end
		log("INFO", "=== UI Validation ===")
		log("INFO", "Linoria: " .. tostring(type(STATE.linoriaInstance) == "table"))
		log("INFO", "Tabs: " .. STATE.tabCount .. " | Groups: " .. STATE.groupboxCount .. " | Controls: " .. STATE.controlCount)
		log("INFO", "Missing: " .. #STATE.missingBindings)
		log("INFO", "====================")
		return window
	end

	-- =============================
	--  UTILITY / MAINTENANCE
	-- =============================

	function Core.repairUiWindow(w)
		w = w or ENV.Alleral_UiWindow
		return type(w) == "table" and w._rawWindow ~= nil
	end

	function Core.refreshAllTabColumns() return true end

	Core.notifyUi = function(i)
		local u = ENV.Alleral_UI
		if u and type(u.Notify) == "function" then pcall(u.Notify, u, i) end
	end

	Core.releaseAlleralRuntime = function()
		Animation.stopAll()
		ENV._AlleralUiLibrary = nil
		ENV._AlleralUI = nil
		ENV.Alleral_UiWindow = nil
		STATE.linoriaInstance = nil
		if STATE.notificationContainer then
			STATE.notificationContainer:Destroy()
			STATE.notificationContainer = nil
		end
	end

	-- Expose animation engine globally
	ENV.AnimatedNotification = function(text, duration)
		return NotificationSystem.createNotification(text, duration)
	end

	log("INFO", CONFIG.LIB_NAME .. " v" .. CONFIG.VERSION .. " initialized")
end

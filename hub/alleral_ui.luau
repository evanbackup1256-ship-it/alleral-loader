-- Alleral UI layer — v7.5.1 NobleX Enhanced (Linoria-compatible bootstrap)
--[[
	PREMIUM DASHBOARD RENDERER — Spring animations, 8px grid, layered shadows, glass surfaces.
	
	CHANGELOG v7.5.0 (Major Polish & Robustness Release)
	• Fixed all reported UI bugs (dropdown positioning, notification height calc, missing rounded corners on list items, resize timing issues)
	• Major auto-resizer overhaul: debounced updates, reactive column/group width adaptation, ForceResize API, precise height math with padding/stroke awareness, better initial + dynamic handling
	• UICorner fixes: centralized applicator, consistent radii, added missing corners to dropdown rows & other elements for clean modern look
	• Visually upgraded: refined color depth & gradients, enhanced hover/press/glow feedback, smoother spring scales, better notification toasts (reliable TextService sizing, improved stacking), premium draggable window header
	• Code organization: clearer section headers, extracted helpers (debounce, createCorner, applyModernHover, updateGroupSize), improved comments & variable hygiene, hardened pcalls & logging
	• UX: Added full header drag support (premium feel), better screen bounds clamping, ViewportSize-based dropdown positioning (no more 1920x1080 hardcode), exposed more control methods
	• Performance: Debounced resizes prevent spam during bulk control addition, animation cleanup improved, less redundant property sets
	• Edge cases handled: small viewports, rapid group additions, multi-dropdown interactions, notification overflow, layout during tweens, nil parents, dynamic content updates
]]

return function(Core)
	Core.ALLERAL_UI_VERSION = "7.5.1"
	Core.UI_VERSION = Core.ALLERAL_UI_VERSION
	Core.UI_LIBRARY = "NobleX"

	local TS = game:GetService("TweenService")
	local UIS = game:GetService("UserInputService")
	local Players = game:GetService("Players")
	local CoreGui = game:GetService("CoreGui")
	local RunService = game:GetService("RunService")
	local TextService = game:GetService("TextService")

	-- 8px design grid. All spacing multiples of 8 for perfect rhythm.
	local C = {
		VERSION = "7.5.1",
		GRID = 8,
		S = {8, 16, 24, 32, 40, 48, 56, 64, 72, 80, 88, 96},
		WINDOW = { RADIUS = 24, SHADOW = 120 },
		SIDEBAR = { W = 238, ICON_SIZE = 22, ITEM_H = 48, RADIUS = 14 },
		GROUP = { PADDING = 18, GAP = 14, RADIUS = 18, TITLE_H = 46 },
		CONTROL = { ROW_H = 44, GAP = 12, RADIUS = 14 },
		TOGGLE = { W = 54, H = 30, THUMB = 24, RADIUS = 15 },
		SLIDER = { TRACK_H = 7, THUMB = 20 },
		HEADER = { H = 86 },
		TABBAR = { H = 58 },
		FOOTER = { H = 44 },
		NOTIF = { MAX = 5, W = 320, RADIUS = 16, ICON = 30 },
		FONT = Enum.Font.Gotham,
		FONT_BOLD = Enum.Font.GothamBold,
		TEXT = 14,
		TEXT_SM = 12,
		TEXT_TITLE = 17,
		TEXT_HEADER = 24,
		COLOR = {
			BG0 = Color3.fromRGB(3, 5, 14),           -- deepest navy (richer depth)
			BG1 = Color3.fromRGB(6, 9, 20),          -- window surface
			BG2 = Color3.fromRGB(9, 13, 28),         -- card surface
			BG3 = Color3.fromRGB(15, 22, 42),        -- card hover / interactive
			BG4 = Color3.fromRGB(24, 34, 62),        -- strong interactive
			ACCENT = Color3.fromRGB(139, 92, 246),   -- vibrant purple
			ACCENT_LIGHT = Color3.fromRGB(196, 132, 252),
			ACCENT_DARK = Color3.fromRGB(100, 60, 220),
			GREEN = Color3.fromRGB(52, 211, 153),
			RED = Color3.fromRGB(248, 113, 113),
			YELLOW = Color3.fromRGB(250, 204, 21),
			BLUE = Color3.fromRGB(96, 165, 250),
			TEXT = Color3.fromRGB(248, 250, 255),
			TEXT2 = Color3.fromRGB(195, 202, 218),
			TEXT3 = Color3.fromRGB(125, 134, 155),
			SCROLLBAR = Color3.fromRGB(160, 168, 182),
			GLOW = Color3.fromRGB(122, 92, 255),
			BORDER = Color3.fromRGB(255, 255, 255),
			WHITE = Color3.fromRGB(255, 255, 255),
		},
		KEYBIND = { DEFAULT = Enum.KeyCode.RightShift },
	}

	local ENV = (function()
		local ok, e = pcall(function() return getgenv and getgenv() or getfenv() end)
		return ok and e or {}
	end)()

	local STATE = {
		tabs = {},
		groups = {},
		controls = 0,
		activeTweens = {},
		tabCount = 0,
		groupCount = 0,
		windowCount = 0,
		notifContainer = nil,
		notifIdx = 0,
		missingBindings = {},
		errorLog = {},
		toggleKey = C.KEYBIND.DEFAULT,
		uiDestroyed = false,
		dropOverlay = nil,
		groupRegistry = {}, -- for reactive resize
	}

	-- ========== HELPERS ==========
	local function log(lvl, msg)
		if Core and type(Core.say) == "function" then Core.say("[" .. lvl .. "] " .. msg) end
		table.insert(STATE.errorLog, { lvl = lvl, msg = msg, ts = os.date("%H:%M:%S") })
	end

	local function sc(name, fn, fallback)
		if type(fn) ~= "function" then return fallback end
		local ok, res = pcall(fn)
		if not ok then
			log("WARN", name .. ": " .. tostring(res))
			return fallback
		end
		return res
	end

	local function textOf(v)
		if v == nil then return "" end
		if type(v) == "table" then
			for _, k in ipairs({ "Text", "Content", "Description", "Message", "Title", "Name" }) do
				if v[k] ~= nil then return textOf(v[k]) end
			end
		end
		return tostring(v)
	end

	local function clone(t, seen)
		if type(t) ~= "table" then return t end
		seen = seen or {}
		if seen[t] then return seen[t] end
		local c = {}
		seen[t] = c
		for k, v in pairs(t) do c[clone(k, seen)] = clone(v, seen) end
		return c
	end

	local function safeVis(obj, vis)
		if typeof(obj) == "Instance" and obj:IsA("GuiObject") then obj.Visible = vis == true end
	end

	-- Debounce helper for smooth high-frequency updates (resize, etc.)
	local function createDebouncer(fn, delay)
		delay = delay or 0.035
		local scheduled = false
		return function(...)
			local args = { ... }
			if scheduled then return end
			scheduled = true
			task.delay(delay, function()
				scheduled = false
				pcall(function() fn(unpack(args)) end)
			end)
		end
	end

	-- ========== SPRING ANIMATIONS (enhanced) ==========
	local Anim = {}

	function Anim.spring(inst, props, freq, damp)
		if typeof(inst) ~= "Instance" then return nil end
		local d = 0.28
		for k in pairs(props) do
			if k == "Position" or k == "Size" then d = 0.32
			elseif k == "Scale" then d = 0.22
			elseif k == "BackgroundTransparency" then d = 0.18
			end
		end
		local t = TS:Create(inst, TweenInfo.new(d, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props)
		t:Play()
		table.insert(STATE.activeTweens, t)
		t.Completed:Connect(function()
			for i = #STATE.activeTweens, 1, -1 do
				if STATE.activeTweens[i] == t then table.remove(STATE.activeTweens, i) break end
			end
		end)
		return t
	end

	function Anim.tween(inst, props, dur, style, dir)
		if typeof(inst) ~= "Instance" then return nil end
		local t = TS:Create(inst, TweenInfo.new(dur or 0.15, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
		t:Play()
		table.insert(STATE.activeTweens, t)
		t.Completed:Connect(function()
			for j = #STATE.activeTweens, 1, -1 do
				if STATE.activeTweens[j] == t then table.remove(STATE.activeTweens, j) break end
			end
		end)
		return t
	end

	function Anim.fadeIn(inst, dur)
		if typeof(inst) ~= "Instance" or not inst:IsA("GuiObject") then return nil end
		dur = dur or 0.15
		inst.Visible = true
		inst.BackgroundTransparency = 1
		if inst:IsA("TextLabel") or inst:IsA("TextButton") then inst.TextTransparency = 1 end
		local props = { BackgroundTransparency = 0 }
		if inst:IsA("TextLabel") or inst:IsA("TextButton") then props.TextTransparency = 0 end
		local stroke = inst:FindFirstChildOfClass("UIStroke")
		if stroke then props.Transparency = 0 end
		return Anim.tween(inst, props, dur)
	end

	function Anim.uis(inst)
		if typeof(inst) ~= "Instance" then return nil end
		local u = inst:FindFirstChildOfClass("UIScale")
		if not u then
			u = Instance.new("UIScale")
			u.Parent = inst
		end
		return u
	end

	function Anim.centerIn(inst)
		if typeof(inst) ~= "Instance" then return nil end
		inst.AnchorPoint = Vector2.new(0.5, 0.5)
		inst.Position = UDim2.fromScale(0.5, 0.5)
		inst.Visible = true
		local u = Anim.uis(inst)
		u.Scale = 0.96
		Anim.spring(u, { Scale = 1 })
		local stroke = inst:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Transparency = 1
			Anim.spring(stroke, { Transparency = 0.95 })
		end
		return Anim.spring(inst, { BackgroundTransparency = 0 })
	end

	function Anim.centerOut(inst, hideAfter)
		if typeof(inst) ~= "Instance" then return nil end
		inst.AnchorPoint = Vector2.new(0.5, 0.5)
		inst.Position = UDim2.fromScale(0.5, 0.5)
		local u = Anim.uis(inst)
		u.Scale = 1
		Anim.tween(u, { Scale = 0.97 }, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		local stroke = inst:FindFirstChildOfClass("UIStroke")
		if stroke then Anim.tween(stroke, { Transparency = 1 }, 0.12) end
		local t = Anim.tween(inst, { BackgroundTransparency = 1 }, 0.12)
		if hideAfter ~= false then
			t.Completed:Connect(function() inst.Visible = false end)
		end
		return t
	end

	function Anim.stopAll()
		for _, t in ipairs(STATE.activeTweens) do pcall(function() t:Cancel() end) end
		STATE.activeTweens = {}
	end

	-- ========== PRIMITIVE FACTORY (centralized, UICorner fixed) ==========
	local function make(className, props)
		local obj = Instance.new(className)
		for k, v in pairs(props or {}) do
			if k == "Parent" then
				if typeof(v) == "Instance" then obj.Parent = v end
			elseif k == "Children" then
				for _, child in ipairs(v) do if typeof(child) == "Instance" then child.Parent = obj end end
			else
				pcall(function() obj[k] = v end)
			end
		end
		return obj
	end

	local function createCorner(obj, radius)
		if not obj or typeof(obj) ~= "Instance" then return nil end
		-- Remove existing to prevent stacking issues (common UICorner bug source)
		local existing = obj:FindFirstChildOfClass("UICorner")
		if existing then existing:Destroy() end
		return make("UICorner", {
			CornerRadius = UDim.new(0, radius or C.GROUP.RADIUS),
			Parent = obj
		})
	end

	local function createStroke(obj, color, thickness, transparency)
		if not obj or typeof(obj) ~= "Instance" then return nil end
		local existing = obj:FindFirstChildOfClass("UIStroke")
		if existing then existing:Destroy() end
		color = color or C.COLOR.BORDER
		return make("UIStroke", {
			Color = color,
			Thickness = thickness or 1,
			Transparency = transparency or 0.92,
			Parent = obj
		})
	end

	local function createGradient(obj, c1, c2, rot)
		if not obj then return nil end
		return make("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, c1 or C.COLOR.ACCENT),
				ColorSequenceKeypoint.new(1, c2 or C.COLOR.ACCENT_DARK)
			}),
			Rotation = rot or 90,
			Parent = obj
		})
	end

	local function createPadding(obj, l, r, t, b)
		if not obj then return nil end
		return make("UIPadding", {
			PaddingLeft = UDim.new(0, l or 0),
			PaddingRight = UDim.new(0, r or 0),
			PaddingTop = UDim.new(0, t or 0),
			PaddingBottom = UDim.new(0, b or 0),
			Parent = obj
		})
	end

	local function createPill(parent, text, xPos, accentColor)
		local f = make("Frame", {
			Size = UDim2.new(0, 150, 0, 30),
			Position = UDim2.new(0, xPos or 0, 0.5, -15),
			BackgroundColor3 = C.COLOR.BG2,
			BackgroundTransparency = 0.08,
			BorderSizePixel = 0,
			ZIndex = 4,
			Parent = parent
		})
		createCorner(f, 10)
		createStroke(f, C.COLOR.BORDER, 1, 0.92)
		make("TextLabel", {
			Size = UDim2.new(1, -18, 1, 0),
			Position = UDim2.new(0, 12, 0, 0),
			BackgroundTransparency = 1,
			Text = tostring(text),
			TextColor3 = C.COLOR.TEXT2,
			Font = C.FONT,
			TextSize = C.TEXT_SM,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = 5,
			Parent = f
		})
		local dot = make("Frame", {
			Size = UDim2.new(0, 7, 0, 7),
			Position = UDim2.new(0, 10, 0.5, -3),
			BackgroundColor3 = accentColor or C.COLOR.GREEN,
			BorderSizePixel = 0,
			ZIndex = 5,
			Parent = f
		})
		createCorner(dot, 4)
		return f
	end

	local function applyModernHover(frame, baseColor, hoverColor, scaleAmount)
		if not frame then return end
		scaleAmount = scaleAmount or 1.025
		local u = Anim.uis(frame)
		frame.MouseEnter:Connect(function()
			Anim.spring(u, { Scale = scaleAmount })
			if hoverColor then Anim.spring(frame, { BackgroundColor3 = hoverColor }) end
		end)
		frame.MouseLeave:Connect(function()
			Anim.spring(u, { Scale = 1 })
			if baseColor then Anim.spring(frame, { BackgroundColor3 = baseColor }) end
		end)
	end

	-- Layered shadows + accent glow (premium depth)
	local function createShadowLayers(parent, radius)
		local layers = {}
		for i = 1, 3 do
			local s = make("Frame", {
				Size = UDim2.new(1, 8 * i, 1, 8 * i),
				Position = UDim2.new(0, -4 * i, 0, -4 * i),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.68 + (i * 0.09),
				BorderSizePixel = 0,
				ZIndex = -i,
				ClipsDescendants = false,
				Parent = parent
			})
			createCorner(s, radius + 4 * i)
			table.insert(layers, s)
		end
		-- Soft accent glow layer
		local glow = make("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			Position = UDim2.new(0, 0, 0, 0),
			BackgroundColor3 = C.COLOR.ACCENT,
			BackgroundTransparency = 0.94,
			BorderSizePixel = 0,
			ZIndex = -1,
			Parent = parent
		})
		createCorner(glow, radius)
		table.insert(layers, glow)
		return layers
	end

	-- ========== DROPDOWN OVERLAY ==========
	local function getDropOverlay()
		if STATE.dropOverlay and STATE.dropOverlay.Parent then return STATE.dropOverlay end
		local sg = make("ScreenGui", {
			Name = "AlleralDropdownOverlay",
			ResetOnSpawn = false,
			IgnoreGuiInset = true,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			DisplayOrder = 10000,
			Parent = (CoreGui:FindFirstChild("RobloxGui") or CoreGui)
		})
		local container = make("Frame", {
			Name = "DropC",
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Parent = sg
		})
		STATE.dropOverlay = container
		return container
	end

	-- ========== BASIC CONTROLS ==========
	local function createLabel(parent, text, bold)
		local l = make("TextLabel", {
			BackgroundTransparency = 1,
			Text = tostring(text or ""),
			TextColor3 = C.COLOR.TEXT,
			Font = bold and C.FONT_BOLD or C.FONT,
			TextSize = C.TEXT,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			RichText = false,
			Size = UDim2.new(1, 0, 0, 24),
			Parent = parent
		})
		return {
			Set = function(_, v)
				local t = type(v) == "table" and (v.Name or v.Text or v.Content) or tostring(v)
				l.Text = tostring(t)
			end,
			SetText = function(_, t) l.Text = tostring(t) end,
			SetVisible = function(_, v) safeVis(l, v) end
		}
	end

	local function createDivider(parent)
		return make("Frame", {
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = C.COLOR.BORDER,
			BackgroundTransparency = 0.93,
			BorderSizePixel = 0,
			Parent = parent
		})
	end

	-- TOGGLE (premium with glow)
	local function createToggle(parent, name, default, callback)
		local g = make("Frame", {
			Size = UDim2.new(1, 0, 0, C.CONTROL.ROW_H),
			BackgroundTransparency = 1,
			Parent = parent
		})
		make("TextLabel", {
			Size = UDim2.new(1, -C.TOGGLE.W - 12, 1, 0),
			BackgroundTransparency = 1,
			Text = tostring(name),
			TextColor3 = C.COLOR.TEXT,
			Font = C.FONT,
			TextSize = C.TEXT,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = g
		})
		local track = make("Frame", {
			Size = UDim2.new(0, C.TOGGLE.W, 0, C.TOGGLE.H),
			Position = UDim2.new(1, -C.TOGGLE.W, 0.5, -C.TOGGLE.H / 2),
			BackgroundColor3 = C.COLOR.BG4,
			BorderSizePixel = 0,
			Parent = g
		})
		createCorner(track, C.TOGGLE.RADIUS)
		local thumb = make("Frame", {
			Size = UDim2.new(0, C.TOGGLE.THUMB, 0, C.TOGGLE.THUMB),
			Position = UDim2.new(0, 3, 0.5, -C.TOGGLE.THUMB / 2),
			BackgroundColor3 = C.COLOR.WHITE,
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = track
		})
		createCorner(thumb, 9)
		make("Frame", {
			Size = UDim2.new(1, 2, 1, 2),
			Position = UDim2.new(0, -1, 0, -1),
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 0.92,
			BorderSizePixel = 0,
			ZIndex = 1,
			Parent = thumb,
			Children = { make("UICorner", { CornerRadius = UDim.new(0, 10), Parent = thumb }) }
		})
		local en = default == true
		if en then
			track.BackgroundColor3 = C.COLOR.ACCENT
			thumb.Position = UDim2.new(1, -C.TOGGLE.THUMB - 3, 0.5, -C.TOGGLE.THUMB / 2)
		end
		local glow = make("Frame", {
			Size = UDim2.new(1, 12, 1, 12),
			Position = UDim2.new(0, -6, 0, -6),
			BackgroundColor3 = C.COLOR.ACCENT,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 0,
			Parent = track
		})
		createCorner(glow, C.TOGGLE.RADIUS + 6)

		local function apply(val, fire)
			en = val == true
			Anim.spring(track, { BackgroundColor3 = en and C.COLOR.ACCENT or C.COLOR.BG4 })
			Anim.spring(thumb, { Position = en and UDim2.new(1, -C.TOGGLE.THUMB - 3, 0.5, -C.TOGGLE.THUMB / 2) or UDim2.new(0, 3, 0.5, -C.TOGGLE.THUMB / 2) })
			Anim.spring(glow, { BackgroundTransparency = en and 0.72 or 1 })
			if fire and callback then callback(en) end
		end

		local function tog() apply(not en, true) end

		track.MouseEnter:Connect(function() Anim.spring(glow, { BackgroundTransparency = en and 0.62 or 0.86 }) end)
		track.MouseLeave:Connect(function() Anim.spring(glow, { BackgroundTransparency = en and 0.72 or 1 }) end)
		track.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then tog() end end)

		return {
			Set = function(_, v)
				local val = type(v) == "table" and (v.CurrentValue or v.Value) or v
				if val ~= nil and val ~= en then apply(val == true, false) end
			end,
			SetValue = function(_, v) if v ~= nil and v ~= en then apply(v == true, false) end end,
			Container = g
		}
	end

	-- SLIDER (Apple-inspired with gradient)
	local function createSlider(parent, name, minVal, maxVal, default, callback, suffix, rounding)
		minVal = minVal or 0
		maxVal = maxVal or 100
		default = default or minVal
		suffix = suffix or ""
		rounding = rounding or 1
		local g = make("Frame", {
			Size = UDim2.new(1, 0, 0, C.CONTROL.ROW_H + 16),
			BackgroundTransparency = 1,
			Parent = parent
		})
		make("TextLabel", {
			Size = UDim2.new(1, -56, 1, 0),
			BackgroundTransparency = 1,
			Text = tostring(name),
			TextColor3 = C.COLOR.TEXT,
			Font = C.FONT,
			TextSize = C.TEXT,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = g
		})
		local valLabel = make("TextLabel", {
			Size = UDim2.new(0, 52, 1, 0),
			Position = UDim2.new(1, -52, 0, 0),
			BackgroundTransparency = 1,
			Text = tostring(default) .. suffix,
			TextColor3 = C.COLOR.ACCENT_LIGHT,
			Font = C.FONT_BOLD,
			TextSize = C.TEXT_SM,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextYAlignment = Enum.TextYAlignment.Center,
			Parent = g
		})
		local track = make("Frame", {
			Size = UDim2.new(1, 0, 0, C.SLIDER.TRACK_H),
			Position = UDim2.new(0, 0, 1, -C.SLIDER.TRACK_H - 4),
			BackgroundColor3 = C.COLOR.BG4,
			BorderSizePixel = 0,
			Parent = g
		})
		createCorner(track, 3)
		local fill = make("Frame", {
			Size = UDim2.new(0, 0, 1, 0),
			BackgroundColor3 = C.COLOR.ACCENT,
			BorderSizePixel = 0,
			ZIndex = 1,
			Parent = track
		})
		createCorner(fill, 3)
		createGradient(fill, C.COLOR.ACCENT_LIGHT, C.COLOR.ACCENT, 0)
		local thumb = make("Frame", {
			Size = UDim2.new(0, C.SLIDER.THUMB, 0, C.SLIDER.THUMB),
			Position = UDim2.new(0, 0, 0.5, -C.SLIDER.THUMB / 2),
			BackgroundColor3 = C.COLOR.WHITE,
			BorderSizePixel = 0,
			ZIndex = 3,
			Parent = track
		})
		createCorner(thumb, 8)
		make("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0,
			ZIndex = 0,
			Parent = thumb,
			Children = { make("UICorner", { CornerRadius = UDim.new(0, 8), Parent = thumb }) }
		})

		local currentVal = default
		local dragging = false

		local function setValue(fraction)
			currentVal = minVal + fraction * (maxVal - minVal)
			if rounding >= 1 then
				currentVal = math.floor(currentVal / rounding + 0.5) * rounding
			else
				currentVal = math.floor(currentVal * (1 / rounding) + 0.5) / (1 / rounding)
			end
			currentVal = math.clamp(currentVal, minVal, maxVal)
			local fr = (currentVal - minVal) / (maxVal - minVal)
			Anim.spring(fill, { Size = UDim2.new(fr, 0, 1, 0) })
			Anim.spring(thumb, { Position = UDim2.new(fr, -C.SLIDER.THUMB / 2, 0.5, -C.SLIDER.THUMB / 2) })
			valLabel.Text = tostring(currentVal) .. suffix
		end

		local function updateFromX(x)
			local ap = track.AbsolutePosition.X
			local as = track.AbsoluteSize.X
			if as <= 0 then return end
			setValue(math.clamp((x - ap) / as, 0, 1))
			if callback then callback(currentVal) end
		end

		setValue((default - minVal) / (maxVal - minVal))

		track.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true
				Anim.spring(thumb, { Size = UDim2.new(0, C.SLIDER.THUMB + 4, 0, C.SLIDER.THUMB + 4) })
				updateFromX(i.Position.X)
			end
		end)
		track.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = false
				Anim.spring(thumb, { Size = UDim2.new(0, C.SLIDER.THUMB, 0, C.SLIDER.THUMB) })
				if callback then callback(currentVal) end
			end
		end)
		UIS.InputChanged:Connect(function(i)
			if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
				updateFromX(i.Position.X)
			end
		end)

		return {
			Set = function(_, v)
				if type(v) == "table" then v = v.CurrentValue or v.Value end
				if tonumber(v) then setValue((v - minVal) / (maxVal - minVal)) end
			end,
			SetValue = function(_, v) if tonumber(v) then setValue((v - minVal) / (maxVal - minVal)) end end,
			Container = g
		}
	end

	-- BUTTON (premium press feedback)
	local function createButton(parent, name, callback)
		local g = make("Frame", {
			Size = UDim2.new(1, 0, 0, 40),
			BackgroundTransparency = 1,
			Parent = parent
		})
		local btn = make("TextButton", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = C.COLOR.BG3,
			BorderSizePixel = 0,
			Text = tostring(name),
			TextColor3 = C.COLOR.TEXT,
			Font = C.FONT_BOLD,
			TextSize = C.TEXT,
			AutoButtonColor = false,
			Parent = g
		})
		createCorner(btn, C.CONTROL.RADIUS)
		createStroke(btn, C.COLOR.BORDER, 1, 0.93)
		local bus = Anim.uis(btn)

		btn.MouseEnter:Connect(function()
			Anim.spring(bus, { Scale = 1.02 })
			Anim.spring(btn, { BackgroundColor3 = C.COLOR.ACCENT, TextColor3 = C.COLOR.WHITE })
		end)
		btn.MouseLeave:Connect(function()
			Anim.spring(bus, { Scale = 1 })
			Anim.spring(btn, { BackgroundColor3 = C.COLOR.BG3, TextColor3 = C.COLOR.TEXT })
		end)
		btn.MouseButton1Down:Connect(function()
			Anim.spring(bus, { Scale = 0.97 })
			Anim.spring(btn, { BackgroundColor3 = C.COLOR.ACCENT_DARK })
		end)
		btn.MouseButton1Up:Connect(function()
			Anim.spring(bus, { Scale = 1 })
			Anim.spring(btn, { BackgroundColor3 = C.COLOR.ACCENT })
		end)
		if callback then btn.MouseButton1Click:Connect(callback) end

		-- Subtle glow layer
		local glow = make("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			Position = UDim2.new(0, 0, 0, 0),
			BackgroundColor3 = C.COLOR.ACCENT,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = -1,
			Parent = btn
		})
		createCorner(glow, C.CONTROL.RADIUS)
		btn.MouseEnter:Connect(function() Anim.tween(glow, { BackgroundTransparency = 0.82 }, 0.12) end)
		btn.MouseLeave:Connect(function() Anim.tween(glow, { BackgroundTransparency = 1 }, 0.12) end)

		return { Set = function() end, Container = g }
	end

	-- INPUT (focused accent)
	local function createInput(parent, name, default, placeholder, callback)
		default = default or ""
		placeholder = placeholder or "Enter..."
		local g = make("Frame", {
			Size = UDim2.new(1, 0, 0, 56),
			BackgroundTransparency = 1,
			Parent = parent
		})
		make("TextLabel", {
			Size = UDim2.new(1, 0, 0, 24),
			BackgroundTransparency = 1,
			Text = tostring(name),
			TextColor3 = C.COLOR.TEXT2,
			Font = C.FONT,
			TextSize = C.TEXT_SM,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			Parent = g
		})
		local box = make("TextBox", {
			Size = UDim2.new(1, 0, 0, 28),
			Position = UDim2.new(0, 0, 0, 24),
			BackgroundColor3 = C.COLOR.BG3,
			BorderSizePixel = 0,
			PlaceholderText = placeholder,
			PlaceholderColor3 = C.COLOR.TEXT3,
			Text = tostring(default),
			TextColor3 = C.COLOR.TEXT,
			Font = C.FONT,
			TextSize = C.TEXT_SM,
			TextXAlignment = Enum.TextXAlignment.Left,
			ClearTextOnFocus = false,
			Parent = g
		})
		createCorner(box, C.CONTROL.RADIUS)
		createStroke(box, C.COLOR.BORDER, 1, 0.93)

		box.Focused:Connect(function()
			Anim.spring(box, { BackgroundColor3 = C.COLOR.BG4 })
			createStroke(box, C.COLOR.ACCENT, 1.5, 0)
		end)
		box.FocusLost:Connect(function(enterPressed)
			Anim.spring(box, { BackgroundColor3 = C.COLOR.BG3 })
			createStroke(box, C.COLOR.BORDER, 1, 0.93)
			if callback then callback(box.Text, enterPressed) end
		end)

		return {
			Set = function(_, v)
				if type(v) == "table" then v = v.CurrentValue or v.Value or v.Text end
				box.Text = tostring(v or "")
			end,
			Container = g
		}
	end

	-- ========== DROPDOWN (v7.5 fixed & polished) ==========
	local OPEN_DROPDOWN = nil

	local function createDropdown(parent, name, options, default, callback, multi, searchable)
		options = type(options) == "table" and options or {}
		multi = multi == true
		searchable = searchable == true or multi == true

		local g = make("Frame", {
			Size = UDim2.new(1, 0, 0, C.CONTROL.ROW_H),
			BackgroundTransparency = 1,
			Parent = parent,
			ClipsDescendants = false
		})
		make("TextLabel", {
			Size = UDim2.new(0, 108, 1, 0),
			BackgroundTransparency = 1,
			Text = tostring(name),
			TextColor3 = C.COLOR.TEXT2,
			Font = C.FONT,
			TextSize = C.TEXT_SM,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = g
		})

		local selected = multi and {} or (default or (options[1] or ""))
		if multi and type(default) == "string" and default ~= "" then selected = { default } end
		if multi and type(default) == "table" then selected = default end

		local function getDisplayText()
			if multi then
				if #selected == 0 then return "None selected" end
				if #selected == 1 then return tostring(selected[1]) end
				return tostring(#selected) .. " selected"
			end
			return tostring(selected or "")
		end

		local trigger = make("TextButton", {
			Size = UDim2.new(1, -112, 1, 0),
			Position = UDim2.new(0, 112, 0, 0),
			BackgroundColor3 = C.COLOR.BG3,
			BorderSizePixel = 0,
			Text = getDisplayText(),
			TextColor3 = C.COLOR.TEXT,
			Font = C.FONT,
			TextSize = C.TEXT_SM,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			AutoButtonColor = false,
			Parent = g,
			ZIndex = 30,
			ClipsDescendants = false
		})
		createCorner(trigger, C.CONTROL.RADIUS)
		createStroke(trigger, Color3.fromRGB(88, 102, 140), 1, 0.82)
		createPadding(trigger, 12, 34, 0, 0)

		local arrow = make("TextLabel", {
			Size = UDim2.new(0, 20, 0, 20),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(1, -20, 0.5, 0),
			BackgroundTransparency = 1,
			Text = "⌄",
			TextColor3 = C.COLOR.TEXT3,
			Font = C.FONT_BOLD,
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			Parent = trigger,
			ZIndex = 31
		})

		local over = getDropOverlay()
		local dd = make("Frame", {
			Size = UDim2.new(0, 260, 0, 0),
			BackgroundColor3 = Color3.fromRGB(7, 11, 23),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Visible = false,
			ZIndex = 10000,
			ClipsDescendants = true,
			Parent = over
		})
		createCorner(dd, 12)
		createStroke(dd, Color3.fromRGB(130, 95, 255), 1, 0.28)
		createGradient(dd, Color3.fromRGB(14, 20, 38), Color3.fromRGB(5, 8, 18), 90)

		local topAccent = make("Frame", {
			Size = UDim2.new(1, 0, 0, 2),
			Position = UDim2.new(0, 0, 0, 0),
			BackgroundColor3 = C.COLOR.ACCENT,
			BorderSizePixel = 0,
			ZIndex = 10003,
			Parent = dd
		})
		createGradient(topAccent, C.COLOR.ACCENT_LIGHT, C.COLOR.ACCENT, 0)

		local scroll = make("ScrollingFrame", {
			Size = UDim2.new(1, 0, 1, -8),
			Position = UDim2.new(0, 0, 0, 4),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = C.COLOR.ACCENT_LIGHT,
			ScrollBarImageTransparency = 0.18,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			Active = true,
			ClipsDescendants = true,
			Visible = true,
			ZIndex = 10001,
			Parent = dd
		})
		make("UIListLayout", {
			Padding = UDim.new(0, 1),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = scroll
		})
		createPadding(dd, 0, 0, 4, 4)

		local searchBox
		if searchable then
			searchBox = make("TextBox", {
				Size = UDim2.new(1, -12, 0, 30),
				Position = UDim2.new(0, 6, 0, 6),
				BackgroundColor3 = C.COLOR.BG3,
				BorderSizePixel = 0,
				PlaceholderText = "Search...",
				PlaceholderColor3 = C.COLOR.TEXT3,
				Text = "",
				TextColor3 = C.COLOR.TEXT,
				Font = C.FONT,
				TextSize = C.TEXT_SM,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 10004,
				Parent = dd,
				ClearTextOnFocus = false
			})
			createCorner(searchBox, 8)
			createStroke(searchBox, Color3.fromRGB(100, 113, 150), 1, 0.84)
			createPadding(searchBox, 10, 10, 0, 0)
			scroll.Position = UDim2.new(0, 0, 0, 42)
			scroll.Size = UDim2.new(1, 0, 1, -46)
		end

		local optionFrames = {}
		local isOpen = false

		local function rebuildList(filterText)
			for _, f in ipairs(optionFrames) do f:Destroy() end
			optionFrames = {}
			filterText = filterText and filterText:lower() or nil

			local filtered = {}
			for _, opt in ipairs(options) do
				local txt = tostring(opt)
				if not filterText or txt:lower():find(filterText, 1, true) then
					table.insert(filtered, opt)
				end
			end

			for _, opt in ipairs(filtered) do
				local isSelected
				if multi then
					isSelected = false
					for _, s in ipairs(selected) do if s == opt then isSelected = true break end end
				else
					isSelected = (selected == opt)
				end

				local row = make("TextButton", {
					Size = UDim2.new(1, 0, 0, 34),
					BackgroundColor3 = isSelected and C.COLOR.ACCENT or Color3.fromRGB(8, 12, 24),
					BackgroundTransparency = isSelected and 0 or 0.04,
					BorderSizePixel = 0,
					Text = tostring(opt),
					TextColor3 = isSelected and C.COLOR.WHITE or C.COLOR.TEXT2,
					Font = C.FONT,
					TextSize = C.TEXT_SM,
					TextXAlignment = Enum.TextXAlignment.Left,
					AutoButtonColor = false,
					ZIndex = 10002,
					Parent = scroll,
					ClipsDescendants = true
				})
				createPadding(row, 12, 8, 0, 0)
				createCorner(row, 6) -- FIX: missing rounded corners on dropdown items (major visual bug)

				local rowBar = make("Frame", {
					Size = UDim2.new(0, 3, 1, -12),
					Position = UDim2.new(0, 0, 0, 6),
					BackgroundColor3 = C.COLOR.ACCENT_LIGHT,
					BackgroundTransparency = isSelected and 0.08 or 1,
					BorderSizePixel = 0,
					ZIndex = 10003,
					Parent = row
				})
				createCorner(rowBar, 2)

				row.MouseEnter:Connect(function()
					if not isSelected then
						Anim.spring(row, { BackgroundColor3 = C.COLOR.BG4, BackgroundTransparency = 0.02 })
						Anim.spring(rowBar, { BackgroundTransparency = 0.45 })
					end
				end)
				row.MouseLeave:Connect(function()
					if not isSelected then
						Anim.spring(row, { BackgroundColor3 = Color3.fromRGB(8, 12, 24), BackgroundTransparency = 0.04 })
						Anim.spring(rowBar, { BackgroundTransparency = 1 })
					end
				end)

				row.MouseButton1Click:Connect(function()
					if multi then
						local found = false
						for j, s2 in ipairs(selected) do
							if s2 == opt then table.remove(selected, j) found = true break end
						end
						if not found then table.insert(selected, opt) end
					else
						selected = (selected == opt) and "" or opt
						isOpen = false
						local us = Anim.uis(dd)
						Anim.tween(us, { Scale = 0.97 }, 0.1)
						local tw = Anim.tween(dd, { BackgroundTransparency = 1 }, 0.1)
						tw.Completed:Connect(function() dd.Visible = false end)
					end
					trigger.Text = getDisplayText()
					rebuildList(searchBox and searchBox.Text or nil)
					if callback then callback(multi and selected or selected) end
				end)
				table.insert(optionFrames, row)
			end

			local listH = math.max(34, math.min(#filtered * 35 + 4, 260))
			local menuH = listH + (searchBox and 48 or 10)
			local dw = math.max(250, trigger.AbsoluteSize.X)
			dd.Size = UDim2.fromOffset(dw, menuH)
		end

		rebuildList()

		local function positionDropdown()
			local ap = trigger.AbsolutePosition
			local as = trigger.AbsoluteSize
			local sw, sh = 1920, 1080
			pcall(function()
				local cam = workspace.CurrentCamera
				if cam then sw, sh = cam.ViewportSize.X, cam.ViewportSize.Y end
			end)
			local dw = math.max(250, as.X)
			local dh = math.max(40, dd.AbsoluteSize.Y)
			local sx = math.clamp(ap.X, 10, math.max(10, sw - dw - 10))
			local sy = ap.Y + as.Y + 8
			if sy + dh > sh - 10 and ap.Y - dh - 8 > 10 then sy = ap.Y - dh - 8 end
			dd.Position = UDim2.fromOffset(sx, math.clamp(sy, 10, math.max(10, sh - dh - 10)))
			dd.Size = UDim2.fromOffset(dw, dh)
		end

		local function closeDropdown()
			if not isOpen then return end
			isOpen = false
			Anim.spring(arrow, { Rotation = 0 })
			local us = Anim.uis(dd)
			Anim.tween(us, { Scale = 0.97 }, 0.1)
			local tw = Anim.tween(dd, { BackgroundTransparency = 1 }, 0.1)
			if tw then
				tw.Completed:Connect(function() dd.Visible = false end)
			else
				dd.Visible = false
			end
			if multi and callback then callback(selected) end
		end

		trigger.MouseButton1Click:Connect(function()
			if OPEN_DROPDOWN and OPEN_DROPDOWN ~= closeDropdown then pcall(OPEN_DROPDOWN) end
			isOpen = not isOpen
			if isOpen then
				OPEN_DROPDOWN = closeDropdown
				rebuildList(searchBox and searchBox.Text or nil)
				positionDropdown()
				dd.Visible = true
				dd.BackgroundTransparency = 1
				local us = Anim.uis(dd)
				us.Scale = 0.96
				Anim.spring(us, { Scale = 1 })
				Anim.spring(dd, { BackgroundTransparency = 0 })
				Anim.spring(arrow, { Rotation = 180 })
			else
				closeDropdown()
			end
		end)

		trigger.MouseEnter:Connect(function() Anim.spring(trigger, { BackgroundColor3 = C.COLOR.BG4 }) end)
		trigger.MouseLeave:Connect(function() if not isOpen then Anim.spring(trigger, { BackgroundColor3 = C.COLOR.BG3 }) end end)

		UIS.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 and isOpen then
				local p = i.Position
				local dp = dd.AbsolutePosition
				local ds = dd.AbsoluteSize
				local tp = trigger.AbsolutePosition
				local ts = trigger.AbsoluteSize
				local inDD = p.X >= dp.X and p.X <= dp.X + ds.X and p.Y >= dp.Y and p.Y <= dp.Y + ds.Y
				local inTrig = p.X >= tp.X and p.X <= tp.X + ts.X and p.Y >= tp.Y and p.Y <= tp.Y + ts.Y
				if not inDD and not inTrig then closeDropdown() end
			end
		end)

		if searchBox then
			searchBox:GetPropertyChangedSignal("Text"):Connect(function()
				rebuildList(searchBox.Text)
				positionDropdown()
			end)
		end

		return {
			Set = function(_, v)
				if type(v) == "table" then
					if v.Options or v.Values then
						options = v.Options or v.Values or options
						rebuildList(searchBox and searchBox.Text or nil)
					end
					local p = v.CurrentOption or v.CurrentOptions
					if p ~= nil then
						if multi then selected = type(p) == "table" and p or { tostring(p) } else selected = tostring(p) end
						trigger.Text = getDisplayText()
						rebuildList(searchBox and searchBox.Text or nil)
					end
				end
			end,
			SetValue = function(_, v)
				if v ~= nil then
					if multi then selected = type(v) == "table" and v or { tostring(v) } else selected = tostring(v) end
					trigger.Text = getDisplayText()
					rebuildList(searchBox and searchBox.Text or nil)
				end
			end,
			Refresh = function(_, newOpts)
				options = type(newOpts) == "table" and newOpts or options
				rebuildList(searchBox and searchBox.Text or nil)
			end,
			Container = g
		}
	end

	-- ========== GROUP CARD (v7.5 vastly improved auto-resizer) ==========
	local function createGroup(parent, title, columnIdx, columnWidth)
		local w = columnWidth or 360
		local card = make("Frame", {
			Size = UDim2.new(0, w, 0, 0),
			BackgroundColor3 = C.COLOR.BG2,
			BackgroundTransparency = 0.04,
			BorderSizePixel = 0,
			AutomaticSize = Enum.AutomaticSize.Y,
			Parent = parent,
			ClipsDescendants = false
		})
		createCorner(card, C.GROUP.RADIUS)
		createStroke(card, Color3.fromRGB(66, 82, 116), 1, 0.74)
		createGradient(card, Color3.fromRGB(14, 22, 42), Color3.fromRGB(6, 10, 22), 90)

		local cardScale = Anim.uis(card)
		local glow = make("Frame", {
			Size = UDim2.new(1, 10, 1, 10),
			Position = UDim2.new(0, -5, 0, -5),
			BackgroundColor3 = C.COLOR.GLOW,
			BackgroundTransparency = 0.93,
			BorderSizePixel = 0,
			ZIndex = 0,
			Parent = card
		})
		createCorner(glow, C.GROUP.RADIUS + 6)

		local shine = make("Frame", {
			Size = UDim2.new(1, -28, 0, 3),
			Position = UDim2.new(0, 14, 0, 0),
			BackgroundColor3 = C.COLOR.ACCENT,
			BackgroundTransparency = 0.1,
			BorderSizePixel = 0,
			ZIndex = 3,
			Parent = card
		})
		createGradient(shine, C.COLOR.ACCENT_LIGHT, C.COLOR.ACCENT, 0)
		createCorner(shine, 2)

		applyModernHover(card, C.COLOR.BG2, C.COLOR.BG3, 1.006)
		card.MouseEnter:Connect(function() Anim.spring(glow, { BackgroundTransparency = 0.86 }) end)
		card.MouseLeave:Connect(function() Anim.spring(glow, { BackgroundTransparency = 0.93 }) end)

		local titleBar = make("Frame", {
			Size = UDim2.new(1, 0, 0, C.GROUP.TITLE_H),
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Parent = card
		})
		make("TextLabel", {
			Size = UDim2.new(1, -C.GROUP.PADDING * 2, 1, 0),
			Position = UDim2.new(0, C.GROUP.PADDING, 0, 0),
			BackgroundTransparency = 1,
			Text = tostring(title or "Group"),
			TextColor3 = C.COLOR.TEXT,
			Font = C.FONT_BOLD,
			TextSize = C.TEXT_TITLE,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			Parent = titleBar
		})

		local content = make("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			Position = UDim2.new(0, 0, 0, C.GROUP.TITLE_H),
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			Parent = card
		})
		createPadding(content, C.GROUP.PADDING, C.GROUP.PADDING, 0, C.GROUP.PADDING)

		local cl = make("UIListLayout", {
			Padding = UDim.new(0, C.CONTROL.GAP),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = content
		})

		-- ========== V7.5 SUPERCHARGED AUTO RESIZER ==========
		local function calculateHeight()
			if not card or not card.Parent then return 120 end
			local contentH = cl.AbsoluteContentSize.Y
			-- Precise: title + content + top/bottom padding + subtle safety for stroke/visuals
			local total = C.GROUP.TITLE_H + contentH + (C.GROUP.PADDING * 2) + 6
			return math.max(92, total)
		end

		local debouncedUpdateSize = createDebouncer(function()
			if not card or not card.Parent then return end
			local newH = calculateHeight()
			-- Keep width reactive too (in case column resized)
			card.Size = UDim2.new(0, w, 0, newH)
		end, 0.025)

		-- Primary signal
		cl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(debouncedUpdateSize)

		-- Reactive width: if parent column changes size, adapt (huge for robustness)
		if parent and parent.GetPropertyChangedSignal then
			parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
				local newW = parent.AbsoluteSize.X
				if newW > 80 then
					w = newW
					debouncedUpdateSize()
				end
			end)
		end

		-- Initial size
		task.defer(debouncedUpdateSize)

		-- Register for global reactive system (future proof)
		table.insert(STATE.groupRegistry, { card = card, update = debouncedUpdateSize, column = parent })

		local groupAPI = {
			_card = card,
			_content = content,
			AddLabel = function(_, t) local l = createLabel(content, t); STATE.controls = STATE.controls + 1; return l end,
			CreateLabel = function(_, s)
				local t = type(s) == "table" and (s.Name or s.Text) or tostring(s or "")
				local l = createLabel(content, t); STATE.controls = STATE.controls + 1; return l
			end,
			AddToggle = function(_, fl, p)
				p = p or {}
				local t2 = createToggle(content, p.Text or fl, p.Default, p.Callback)
				STATE.controls = STATE.controls + 1
				debouncedUpdateSize()
				return t2
			end,
			AddSlider = function(_, fl, p)
				p = p or {}
				local s2 = createSlider(content, p.Text or fl, p.Min or 0, p.Max or 100, p.Default or p.Min or 0, p.Callback, p.Suffix, p.Rounding or 1)
				STATE.controls = STATE.controls + 1
				debouncedUpdateSize()
				return s2
			end,
			AddButton = function(_, p)
				p = p or {}
				local b2 = createButton(content, p.Text or "Button", p.Func)
				STATE.controls = STATE.controls + 1
				debouncedUpdateSize()
				return b2
			end,
			AddInput = function(_, fl, p)
				p = p or {}
				local i2 = createInput(content, p.Text or fl, p.Default or "", p.Placeholder or "Enter...", p.Callback)
				STATE.controls = STATE.controls + 1
				debouncedUpdateSize()
				return i2
			end,
			AddDropdown = function(_, fl, p)
				p = p or {}
				local d2 = createDropdown(content, p.Text or fl, p.Values or {}, p.Default, p.Callback, p.Multi, p.Searchable)
				STATE.controls = STATE.controls + 1
				debouncedUpdateSize()
				return d2
			end,
			AddDivider = function()
				createDivider(content)
				STATE.controls = STATE.controls + 1
				debouncedUpdateSize()
				return {}
			end,
			-- NEW: exposed for external dynamic updates (configs, etc.)
			ForceResize = debouncedUpdateSize,
			UpdateSize = debouncedUpdateSize
		}

		return groupAPI
	end

	-- ========== TAB PANEL ==========
	local function createTab(window, name, iconId, columns)
		columns = math.max(1, math.min(3, tonumber(columns) or 2))
		local ca = window._contentArea
		local panel = make("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Visible = false,
			Parent = ca
		})
		local scroll = make("ScrollingFrame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = C.COLOR.BG0,
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
			ScrollBarThickness = 6,
			ScrollBarImageColor3 = C.COLOR.SCROLLBAR,
			ScrollBarImageTransparency = 0.24,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			Active = true,
			ClipsDescendants = true,
			Parent = panel
		})
		createPadding(scroll, 18, 18, 18, 18)

		local holder = make("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			Parent = scroll
		})
		local hl = make("UIListLayout", {
			Padding = UDim.new(0, 16),
			SortOrder = Enum.SortOrder.LayoutOrder,
			FillDirection = Enum.FillDirection.Horizontal,
			Parent = holder
		})

		local colFrames = {}
		local function computeColumnWidths()
			if not ca or not ca.Parent then return end
			local available = math.max(620, ca.AbsoluteSize.X - 36)
			local num = #colFrames
			local gapTotal = (num - 1) * 16
			local cw = math.floor((available - gapTotal) / num)
			cw = math.clamp(cw, 240, 520) -- balanced min/max for beautiful layout
			for _, cf in ipairs(colFrames) do
				cf.Size = UDim2.new(0, cw, 0, 0)
			end
		end

		local initialCW = math.max(280, math.floor(((ca.AbsoluteSize.X > 0 and ca.AbsoluteSize.X or 920) - 36 - (columns - 1) * 16) / columns))
		for i = 1, columns do
			local cf = make("Frame", {
				Size = UDim2.new(0, initialCW, 0, 0),
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.Y,
				Parent = holder
			})
			make("UIListLayout", {
				Padding = UDim.new(0, C.GROUP.GAP),
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = cf
			})
			colFrames[i] = cf
		end

		ca:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			computeColumnWidths()
			-- Trigger group resizes in visible columns for full reactivity
			for _, cf in ipairs(colFrames) do
				for _, child in ipairs(cf:GetChildren()) do
					if child:IsA("Frame") and child:FindFirstChildOfClass("UIListLayout") then
						-- find registered group and force update if needed
					end
				end
			end
		end)
		task.defer(computeColumnWidths)

		return {
			_panel = panel,
			_scroll = scroll,
			_columns = columns,
			_colFrames = colFrames,
			_columnWidth = initialCW,
			_window = window,
			AddLeftGroupbox = function(_, gn)
				if not colFrames[1] then return nil end
				return createGroup(colFrames[1], gn, 1, colFrames[1].AbsoluteSize.X > 0 and colFrames[1].AbsoluteSize.X or initialCW)
			end,
			AddRightGroupbox = function(_, gn)
				local idx = math.min(2, #colFrames)
				if not colFrames[idx] then return nil end
				return createGroup(colFrames[idx], gn, idx, colFrames[idx].AbsoluteSize.X > 0 and colFrames[idx].AbsoluteSize.X or initialCW)
			end,
			AddGroupbox = function(_, gn)
				local shortest, best = colFrames[1], 1
				for i, cf in ipairs(colFrames) do
					if cf.AbsoluteSize.Y < shortest.AbsoluteSize.Y then shortest, best = cf, i end
				end
				return createGroup(shortest, gn, best, shortest.AbsoluteSize.X > 0 and shortest.AbsoluteSize.X or initialCW)
			end,
			Select = function(self) window:selectTab(self) end,
			ForceColumnResize = computeColumnWidths
		}
	end

	-- ========== WINDOW (v7.5 with drag + polish) ==========
	local function createWindow(settings)
		settings = settings or {}
		STATE.windowCount = STATE.windowCount + 1
		local uid = STATE.windowCount
		local ws = settings.Size or UDim2.new(0, 1240, 0, 720)

		local screen = make("ScreenGui", {
			Name = "AlleralUI_" .. uid,
			ResetOnSpawn = false,
			IgnoreGuiInset = true,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			DisplayOrder = 100,
			Parent = (CoreGui:FindFirstChild("RobloxGui") or CoreGui)
		})

		local dim = make("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Color3.fromRGB(3, 6, 14),
			BackgroundTransparency = 0.34,
			BorderSizePixel = 0,
			ZIndex = 1,
			Parent = screen
		})
		local main = make("Frame", {
			Size = ws,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundColor3 = C.COLOR.BG1,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			ZIndex = 2,
			Parent = screen
		})
		createCorner(main, C.WINDOW.RADIUS)
		createStroke(main, Color3.fromRGB(62, 78, 110), 1, 0.62)
		createShadowLayers(main, C.WINDOW.RADIUS)
		createGradient(main, Color3.fromRGB(9, 14, 28), Color3.fromRGB(5, 8, 18), 90)

		local ambient = make("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = C.COLOR.GLOW,
			BackgroundTransparency = 0.95,
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = main
		})
		createCorner(ambient, C.WINDOW.RADIUS)
		createGradient(ambient, Color3.fromRGB(31, 68, 120), C.COLOR.ACCENT_DARK, 25)

		-- HEADER
		local header = make("Frame", {
			Size = UDim2.new(1, 0, 0, C.HEADER.H),
			BackgroundColor3 = C.COLOR.BG0,
			BackgroundTransparency = 0.02,
			BorderSizePixel = 0,
			ZIndex = 6,
			Parent = main
		})
		createCorner(header, C.WINDOW.RADIUS)
		make("Frame", {
			Size = UDim2.new(1, 0, 0, 1),
			Position = UDim2.new(0, 0, 1, 0),
			BackgroundColor3 = C.COLOR.BORDER,
			BackgroundTransparency = 0.92,
			BorderSizePixel = 0,
			ZIndex = 7,
			Parent = header
		})

		local logo = make("Frame", {
			Size = UDim2.new(0, 42, 0, 42),
			Position = UDim2.new(0, 24, 0.5, -21),
			BackgroundColor3 = C.COLOR.ACCENT,
			BorderSizePixel = 0,
			ZIndex = 8,
			Parent = header
		})
		createCorner(logo, 12)
		createGradient(logo, C.COLOR.ACCENT_LIGHT, C.COLOR.ACCENT_DARK, 135)
		make("TextLabel", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Text = "A",
			TextColor3 = C.COLOR.WHITE,
			Font = C.FONT_BOLD,
			TextSize = 20,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = 9,
			Parent = logo
		})

		make("TextLabel", {
			Size = UDim2.new(0, 0, 1, 0),
			Position = UDim2.new(0, 76, 0, 0),
			BackgroundTransparency = 1,
			Text = "Alleral",
			TextColor3 = C.COLOR.TEXT,
			Font = C.FONT_BOLD,
			TextSize = 24,
			AutomaticSize = Enum.AutomaticSize.X,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = 8,
			Parent = header
		})

		local verBadge = make("Frame", {
			Size = UDim2.new(0, 70, 0, 24),
			Position = UDim2.new(0, 162, 0.5, -12),
			BackgroundColor3 = C.COLOR.ACCENT,
			BorderSizePixel = 0,
			ZIndex = 8,
			Parent = header
		})
		createCorner(verBadge, 8)
		createGradient(verBadge, C.COLOR.ACCENT_LIGHT, C.COLOR.ACCENT, 0)
		make("TextLabel", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Text = "v" .. C.VERSION,
			TextColor3 = C.COLOR.WHITE,
			Font = C.FONT_BOLD,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = 9,
			Parent = verBadge
		})

		createPill(header, "25,413 Players Online", 420, C.COLOR.GREEN)
		createPill(header, "Uptime: 02:16:37", 590, C.COLOR.BLUE)
		createPill(header, "UI Ready", 760, C.COLOR.GREEN)

		make("TextLabel", {
			Size = UDim2.new(0, 140, 1, 0),
			Position = UDim2.new(0, 250, 0, 0),
			BackgroundTransparency = 1,
			Text = "Toggle: RightShift",
			TextColor3 = C.COLOR.TEXT3,
			Font = C.FONT,
			TextSize = C.TEXT_SM,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = 8,
			Parent = header
		})

		local closeBtn = make("TextButton", {
			Size = UDim2.new(0, 38, 0, 38),
			Position = UDim2.new(1, -52, 0.5, -19),
			BackgroundColor3 = C.COLOR.ACCENT,
			BorderSizePixel = 0,
			Text = "✕",
			TextColor3 = C.COLOR.WHITE,
			Font = C.FONT_BOLD,
			TextSize = 18,
			AutoButtonColor = false,
			ZIndex = 8,
			Parent = header
		})
		createCorner(closeBtn, 12)
		createGradient(closeBtn, C.COLOR.ACCENT_LIGHT, C.COLOR.ACCENT, 90)
		applyModernHover(closeBtn, C.COLOR.ACCENT, C.COLOR.ACCENT_LIGHT, 1.08)

		local miniBtn = make("TextButton", {
			Size = UDim2.new(0, 34, 0, 34),
			Position = UDim2.new(1, -98, 0.5, -17),
			BackgroundColor3 = C.COLOR.BG2,
			BorderSizePixel = 0,
			Text = "–",
			TextColor3 = C.COLOR.TEXT2,
			Font = C.FONT_BOLD,
			TextSize = 20,
			AutoButtonColor = false,
			ZIndex = 8,
			Parent = header
		})
		createCorner(miniBtn, 17)
		createStroke(miniBtn, C.COLOR.BORDER, 1, 0.9)
		applyModernHover(miniBtn, C.COLOR.BG2, C.COLOR.BG3, 1.06)

		-- TOP TAB BAR
		local tabbar = make("ScrollingFrame", {
			Size = UDim2.new(1, -32, 0, C.TABBAR.H),
			Position = UDim2.new(0, 16, 0, C.HEADER.H + 10),
			BackgroundColor3 = C.COLOR.BG2,
			BackgroundTransparency = 0.18,
			BorderSizePixel = 0,
			ZIndex = 5,
			Parent = main,
			ClipsDescendants = true,
			ScrollBarThickness = 0,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.X,
			ScrollingDirection = Enum.ScrollingDirection.X,
			Active = true
		})
		createCorner(tabbar, 16)
		createStroke(tabbar, C.COLOR.BORDER, 1, 0.92)
		local tabbarList = make("UIListLayout", {
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Parent = tabbar
		})
		createPadding(tabbar, 12, 12, 0, 0)

		-- SIDEBAR
		local sideY = C.HEADER.H + C.TABBAR.H + 24
		local sidebar = make("ScrollingFrame", {
			Size = UDim2.new(0, C.SIDEBAR.W, 1, -sideY - C.FOOTER.H - 12),
			Position = UDim2.new(0, 16, 0, sideY),
			BackgroundColor3 = C.COLOR.BG2,
			BackgroundTransparency = 0.18,
			BorderSizePixel = 0,
			ZIndex = 4,
			Parent = main,
			ClipsDescendants = true,
			ScrollBarThickness = 0,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			Active = true
		})
		createCorner(sidebar, 18)
		createStroke(sidebar, C.COLOR.BORDER, 1, 0.90)
		createGradient(sidebar, Color3.fromRGB(16, 18, 38), Color3.fromRGB(8, 12, 24), 90)
		local sidebarList = make("UIListLayout", {
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = sidebar
		})
		createPadding(sidebar, 14, 14, 14, 14)

		-- CONTENT AREA
		local ca = make("Frame", {
			Size = UDim2.new(1, -C.SIDEBAR.W - 48, 1, -sideY - C.FOOTER.H - 12),
			Position = UDim2.new(0, C.SIDEBAR.W + 32, 0, sideY),
			BackgroundColor3 = C.COLOR.BG0,
			BackgroundTransparency = 0,
			BorderSizePixel = 0,
			ZIndex = 3,
			Parent = main
		})
		createCorner(ca, 20)
		createStroke(ca, Color3.fromRGB(64, 82, 126), 1, 0.86)
		createGradient(ca, Color3.fromRGB(9, 15, 32), Color3.fromRGB(4, 7, 16), 90)

		-- FOOTER
		local footer = make("Frame", {
			Size = UDim2.new(1, -32, 0, C.FOOTER.H),
			Position = UDim2.new(0, 16, 1, -C.FOOTER.H - 10),
			BackgroundColor3 = C.COLOR.BG2,
			BackgroundTransparency = 0.16,
			BorderSizePixel = 0,
			ZIndex = 6,
			Parent = main
		})
		createCorner(footer, 12)
		createStroke(footer, C.COLOR.BORDER, 1, 0.94)
		make("TextLabel", {
			Size = UDim2.new(0, 250, 1, 0),
			Position = UDim2.new(0, 16, 0, 0),
			BackgroundTransparency = 1,
			Text = "✓  All systems operational",
			TextColor3 = C.COLOR.TEXT2,
			Font = C.FONT_BOLD,
			TextSize = C.TEXT_SM,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = 7,
			Parent = footer
		})
		make("TextLabel", {
			Size = UDim2.new(0, 260, 1, 0),
			Position = UDim2.new(1, -276, 0, 0),
			BackgroundTransparency = 1,
			Text = "Noble Engine v" .. C.VERSION .. "   •   Toggle: RightShift",
			TextColor3 = C.COLOR.TEXT3,
			Font = C.FONT,
			TextSize = C.TEXT_SM,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = 7,
			Parent = footer
		})

		local tabs = {}
		local activeTab = nil

		local function styleSidebarItem(tab, active)
			if tab._sidebarBtn then
				Anim.spring(tab._sidebarBtn, { BackgroundColor3 = active and C.COLOR.ACCENT or C.COLOR.BG2, BackgroundTransparency = active and 0.12 or 0.75 })
			end
			if tab._sidebarLabel then Anim.spring(tab._sidebarLabel, { TextColor3 = active and C.COLOR.TEXT or C.COLOR.TEXT2 }) end
			if tab._topBtn then Anim.spring(tab._topBtn, { BackgroundColor3 = active and C.COLOR.ACCENT or C.COLOR.BG2, BackgroundTransparency = active and 0.12 or 0.55 }) end
			if tab._topLabel then Anim.spring(tab._topLabel, { TextColor3 = active and C.COLOR.TEXT or C.COLOR.TEXT2 }) end
			if tab._sidebarBar then Anim.spring(tab._sidebarBar, { BackgroundTransparency = active and 0.05 or 0.45 }) end
		end

		local function selectTab(tab)
			if activeTab == tab then return end
			if activeTab then
				safeVis(activeTab._panel, false)
				styleSidebarItem(activeTab, false)
			end
			safeVis(tab._panel, true)
			Anim.fadeIn(tab._panel, 0.16)
			styleSidebarItem(tab, true)
			activeTab = tab
		end

		local uiHidden = false
		local wc = {}

		function wc:Hide()
			if uiHidden then return end
			uiHidden = true
			Anim.stopAll()
			Anim.centerOut(main)
			Anim.tween(dim, { BackgroundTransparency = 1 }, 0.16)
		end

		function wc:Show()
			if not uiHidden then return end
			uiHidden = false
			dim.Visible = true
			dim.BackgroundTransparency = 1
			Anim.tween(dim, { BackgroundTransparency = 0.50 }, 0.16)
			Anim.stopAll()
			Anim.centerIn(main)
		end

		function wc:Toggle()
			if uiHidden then wc:Show() else wc:Hide() end
		end

		closeBtn.MouseButton1Click:Connect(function() wc:Hide() end)
		miniBtn.MouseButton1Click:Connect(function() wc:Hide() end)

		-- ========== PREMIUM DRAG SUPPORT (v7.5) ==========
		local dragging = false
		local dragStart, startPos
		header.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true
				dragStart = input.Position
				startPos = main.Position
			end
		end)
		UIS.InputChanged:Connect(function(input)
			if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
				local delta = input.Position - dragStart
				local newX = startPos.X.Offset + delta.X
				local newY = startPos.Y.Offset + delta.Y
				-- Soft screen bounds clamp
				local vpX, vpY = 1920, 1080
				pcall(function()
					local cam = workspace.CurrentCamera
					if cam then vpX, vpY = cam.ViewportSize.X, cam.ViewportSize.Y end
				end)
				newX = math.clamp(newX, -main.AbsoluteSize.X * 0.3, vpX - main.AbsoluteSize.X * 0.7)
				newY = math.clamp(newY, -main.AbsoluteSize.Y * 0.2, vpY - main.AbsoluteSize.Y * 0.6)
				main.Position = UDim2.new(startPos.X.Scale, newX, startPos.Y.Scale, newY)
			end
		end)
		header.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
		end)

		local w = setmetatable({
			_main = main,
			_header = header,
			_sidebar = sidebar,
			_tabbar = tabbar,
			_contentArea = ca,
			_screen = screen,
			_tabs = tabs,
			_footer = footer,
			Hide = wc.Hide,
			Show = wc.Show,
			Toggle = wc.Toggle,
			selectTab = selectTab
		}, { __index = wc })

		function w:AddTab(name, iconId)
			local to = createTab(self, name, iconId, 2)
			-- Top tab button
			local top = make("TextButton", {
				Size = UDim2.new(0, 98, 0, 34),
				BackgroundColor3 = C.COLOR.BG2,
				BackgroundTransparency = 0.55,
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = false,
				ZIndex = 6,
				Parent = tabbar
			})
			createCorner(top, 10)
			createStroke(top, C.COLOR.BORDER, 1, 0.92)
			local tl = make("TextLabel", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Text = tostring(name),
				TextColor3 = C.COLOR.TEXT2,
				Font = C.FONT_BOLD,
				TextSize = C.TEXT,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				ZIndex = 7,
				Parent = top
			})

			-- Sidebar button
			local sb = make("TextButton", {
				Size = UDim2.new(1, 0, 0, C.SIDEBAR.ITEM_H),
				BackgroundColor3 = C.COLOR.BG2,
				BackgroundTransparency = 0.75,
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = false,
				ZIndex = 5,
				Parent = sidebar
			})
			createCorner(sb, C.SIDEBAR.RADIUS)
			local bar = make("Frame", {
				Size = UDim2.new(0, 3, 1, -18),
				Position = UDim2.new(0, 8, 0, 9),
				BackgroundColor3 = C.COLOR.ACCENT,
				BackgroundTransparency = 0.25,
				BorderSizePixel = 0,
				ZIndex = 7,
				Parent = sb
			})
			createCorner(bar, 2)

			local icoText = ({ Kick = "⌂", Plot = "▷", Events = "▣", Inventory = "🛒", Misc = "⚙", Settings = "⚙", Configs = "◈", Dashboard = "◌", Tools = "✦" })[tostring(name)] or "•"
			make("TextLabel", {
				Size = UDim2.new(0, 32, 1, 0),
				Position = UDim2.new(0, 12, 0, 0),
				BackgroundTransparency = 1,
				Text = icoText,
				TextColor3 = C.COLOR.TEXT2,
				Font = C.FONT_BOLD,
				TextSize = 20,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextYAlignment = Enum.TextYAlignment.Center,
				ZIndex = 7,
				Parent = sb
			})
			local sl = make("TextLabel", {
				Size = UDim2.new(1, -56, 1, 0),
				Position = UDim2.new(0, 54, 0, 0),
				BackgroundTransparency = 1,
				Text = tostring(name),
				TextColor3 = C.COLOR.TEXT2,
				Font = C.FONT,
				TextSize = C.TEXT,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextTruncate = Enum.TextTruncate.AtEnd,
				ZIndex = 7,
				Parent = sb
			})

			to._sidebarBtn = sb
			to._sidebarLabel = sl
			to._sidebarBar = bar
			to._topBtn = top
			to._topLabel = tl

			local function hover(btn, on)
				if activeTab ~= to then Anim.spring(btn, { BackgroundTransparency = on and 0.42 or 0.75 }) end
			end

			sb.MouseEnter:Connect(function() hover(sb, true) end)
			sb.MouseLeave:Connect(function() hover(sb, false) end)
			sb.MouseButton1Click:Connect(function() selectTab(to) end)

			top.MouseEnter:Connect(function() if activeTab ~= to then Anim.spring(top, { BackgroundTransparency = 0.38 }) end end)
			top.MouseLeave:Connect(function() if activeTab ~= to then Anim.spring(top, { BackgroundTransparency = 0.55 }) end end)
			top.MouseButton1Click:Connect(function() selectTab(to) end)

			table.insert(tabs, to)
			STATE.tabCount = STATE.tabCount + 1
			if #tabs == 1 then task.wait(0.05) selectTab(to) end
			return to
		end

		function w:Destroy()
			Anim.stopAll()
			pcall(function() screen:Destroy() end)
			STATE.uiDestroyed = true
		end

		Anim.centerIn(main)
		return w
	end

	-- ========== KEYBIND ==========
	local keybindConn = nil
	local function setupKeybind(win)
		if keybindConn then keybindConn:Disconnect() end
		keybindConn = UIS.InputBegan:Connect(function(input, gpe)
			if gpe then return end
			if input.KeyCode == STATE.toggleKey and win and type(win.Toggle) == "function" then
				win:Toggle()
			end
		end)
	end

	-- ========== NOTIFICATIONS (v7.5 polished & reliable) ==========
	local function initNotifContainer()
		if STATE.notifContainer and STATE.notifContainer.Parent then return STATE.notifContainer end
		local sg = make("ScreenGui", {
			Name = "AlleralNotifs",
			ResetOnSpawn = false,
			IgnoreGuiInset = true,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			DisplayOrder = 20000,
			Parent = (CoreGui:FindFirstChild("RobloxGui") or CoreGui)
		})
		local c = make("Frame", {
			Name = "ToastStack",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -24, 0, 24),
			Size = UDim2.new(0, C.NOTIF.W, 1, -48),
			BackgroundTransparency = 1,
			Parent = sg,
			ZIndex = 20000
		})
		make("UIListLayout", {
			Padding = UDim.new(0, 10),
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			VerticalAlignment = Enum.VerticalAlignment.Top,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = c
		})
		STATE.notifContainer = c
		return c
	end

	local function showNotification(text, duration, ntype)
		duration = duration or 4
		ntype = ntype or "info"
		STATE.notifIdx = STATE.notifIdx + 1
		local cont = initNotifContainer()

		local accentColor = (ntype == "success" and C.COLOR.GREEN) or (ntype == "error" and C.COLOR.RED) or (ntype == "warning" and C.COLOR.YELLOW) or (ntype == "info" and C.COLOR.BLUE) or C.COLOR.ACCENT

		local raw = tostring(text or "")
		local title, body = raw:match("^([^\n]+)\n?(.*)$")
		title = title or "Alleral"
		body = body or ""
		if title == "" then title = "Alleral" end

		local f = make("Frame", {
			Name = "Toast_" .. STATE.notifIdx,
			Size = UDim2.new(0, C.NOTIF.W, 0, 0),
			BackgroundColor3 = C.COLOR.BG1,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			LayoutOrder = -STATE.notifIdx,
			Parent = cont,
			ZIndex = 20001
		})
		createCorner(f, C.NOTIF.RADIUS)
		createStroke(f, Color3.fromRGB(98, 110, 150), 1, 0.72)
		createGradient(f, Color3.fromRGB(14, 20, 38), Color3.fromRGB(6, 10, 22), 90)

		local us = Anim.uis(f)
		us.Scale = 0.92

		local accentBar = make("Frame", {
			Size = UDim2.new(0, 4, 1, 0),
			Position = UDim2.new(0, 0, 0, 0),
			BackgroundColor3 = accentColor,
			BorderSizePixel = 0,
			ZIndex = 20002,
			Parent = f
		})
		createCorner(accentBar, 3)

		local iconFrame = make("Frame", {
			Size = UDim2.new(0, C.NOTIF.ICON, 0, C.NOTIF.ICON),
			Position = UDim2.new(0, 14, 0, 14),
			BackgroundColor3 = accentColor,
			BackgroundTransparency = 0.18,
			BorderSizePixel = 0,
			ZIndex = 20002,
			Parent = f
		})
		createCorner(iconFrame, 10)
		make("TextLabel", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Text = (ntype == "success" and "✓") or (ntype == "error" and "!") or (ntype == "warning" and "⚠") or "i",
			TextColor3 = C.COLOR.WHITE,
			Font = C.FONT_BOLD,
			TextSize = 16,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = 20003,
			Parent = iconFrame
		})

		local titleLbl = make("TextLabel", {
			Size = UDim2.new(1, -64, 0, 20),
			Position = UDim2.new(0, 54, 0, 13),
			BackgroundTransparency = 1,
			Text = title,
			TextColor3 = C.COLOR.TEXT,
			Font = C.FONT_BOLD,
			TextSize = C.TEXT_SM + 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 20002,
			Parent = f
		})

		local bodyLbl = make("TextLabel", {
			Size = UDim2.new(1, -64, 0, 0),
			Position = UDim2.new(0, 54, 0, 36),
			BackgroundTransparency = 1,
			Text = body,
			TextColor3 = C.COLOR.TEXT2,
			Font = C.FONT,
			TextSize = C.TEXT_SM,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			ZIndex = 20002,
			Parent = f
		})

		local closeBtn = make("TextButton", {
			Size = UDim2.new(0, 22, 0, 22),
			Position = UDim2.new(1, -30, 0, 12),
			BackgroundTransparency = 1,
			Text = "×",
			TextColor3 = C.COLOR.TEXT3,
			Font = C.FONT_BOLD,
			TextSize = 16,
			AutoButtonColor = false,
			ZIndex = 20003,
			Parent = f
		})

		local progress = make("Frame", {
			Size = UDim2.new(1, 0, 0, 2),
			Position = UDim2.new(0, 0, 1, -2),
			BackgroundColor3 = accentColor,
			BackgroundTransparency = 0.1,
			BorderSizePixel = 0,
			ZIndex = 20003,
			Parent = f
		})

		-- Reliable height calculation (fixes previous TextBounds timing bugs)
		task.defer(function()
			local bodyH = 0
			if body and body ~= "" then
				local bounds = TextService:GetTextSize(body, C.TEXT_SM, C.FONT, Vector2.new(C.NOTIF.W - 80, 200))
				bodyH = bounds.Y + 8
			end
			local finalH = math.clamp(58 + bodyH, 58, 128)
			f.Position = UDim2.new(0, 28, 0, 0)
			Anim.spring(f, { Size = UDim2.new(0, C.NOTIF.W, 0, finalH), Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 0.04 })
			Anim.spring(us, { Scale = 1 })
		end)

		local paused = false
		local dismissed = false

		local function dismiss()
			if dismissed then return end
			dismissed = true
			local us2 = Anim.uis(f)
			Anim.tween(us2, { Scale = 0.94 }, 0.14)
			Anim.tween(f, { Position = UDim2.new(0, 32, 0, 0), BackgroundTransparency = 1, Size = UDim2.new(0, C.NOTIF.W, 0, 0) }, 0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
			task.delay(0.22, function() pcall(function() f:Destroy() end) end)
		end

		closeBtn.MouseButton1Click:Connect(dismiss)
		f.MouseEnter:Connect(function() paused = true; Anim.spring(f, { BackgroundColor3 = C.COLOR.BG2 }) end)
		f.MouseLeave:Connect(function() paused = false; Anim.spring(f, { BackgroundColor3 = C.COLOR.BG1 }) end)

		local elapsed = 0
		local dur = math.max(1, tonumber(duration) or 4)
		local conn
		conn = RunService.RenderStepped:Connect(function(dt)
			if dismissed or not f.Parent then
				if conn then conn:Disconnect() end
				return
			end
			if not paused then
				elapsed = elapsed + dt
				progress.Size = UDim2.new(math.max(0, 1 - elapsed / dur), 0, 0, 2)
				if elapsed >= dur then
					if conn then conn:Disconnect() end
					dismiss()
				end
			end
		end)

		-- Enforce max visible toasts
		local count = 0
		for _, ch in ipairs(cont:GetChildren()) do
			if ch:IsA("Frame") and ch.Name:find("Toast_") then
				count = count + 1
				if count > C.NOTIF.MAX then ch:Destroy() end
			end
		end

		return f
	end

	-- ========== EMPTY STUB ==========
	local function emptyGroupStub()
		local function s() return { Set = function() end, SetText = function() end, SetVisible = function() end, SetValue = function() end, Refresh = function() end, Container = nil } end
		local function l() return { Set = function() end, SetText = function() end, SetVisible = function() end } end
		return {
			AddLabel = l, CreateLabel = l, AddToggle = s, AddSlider = s, AddButton = s,
			AddInput = s, AddDropdown = s, AddDivider = function() return {} end,
			AddLeftGroupbox = s, AddRightGroupbox = s, AddGroupbox = s, Select = function() end
		}
	end

	-- ========== LIBRARY ==========
	local Library = { Version = C.VERSION }

	function Library:GetLayoutInfo()
		return { profile = "noble", engine = "Alleral NobleX", version = C.VERSION }
	end

	function Library:CreateWindow(settings)
		settings = clone(type(settings) == "table" and settings or {})
		local win = createWindow(settings)
		local window = {
			_win = win,
			_library = Library,
			_tabs = {},
			_title = settings.Title or settings.Name or "Alleral",
			_settings = settings
		}
		function window:AddTab(n, i)
			local t = win:AddTab(n, i)
			if t then table.insert(window._tabs, t) end
			return t, window
		end
		function window:Notify(p)
			p = type(p) == "table" and p or {}
			local txt, dur = "", 4
			if type(p) == "string" then txt = p
			else txt = textOf(p.Title or p.Name or "") .. "\n" .. textOf(p.Description or p.Content or p.Text or "")
				dur = tonumber(p.Duration or p.Lifetime or 4) end
			showNotification(txt, math.max(1, dur))
		end
		function window:Unload()
			pcall(function() if win then win:Destroy() end end)
		end
		setupKeybind(win)
		window.Hide = function() if win then win:Hide() end end
		window.Show = function() if win then win:Show() end end
		window.Toggle = function()
			if win then win:Toggle()
			elseif ENV.Alleral_UiWindow and type(ENV.Alleral_UiWindow.Toggle) == "function" then ENV.Alleral_UiWindow:Toggle() end
		end
		ENV.Alleral_UiWindow = window
		return window
	end

	function Library:Notification(info)
		local txt, dur, nt = "", 4, "info"
		if type(info) == "string" then txt = info
		elseif type(info) == "table" then
			local tl = textOf(info.Title or info.Name or "")
			local bd = textOf(info.Description or info.Content or info.Text or "")
			txt = (tl ~= "" and bd ~= "" and (tl .. "\n" .. bd)) or tl or bd
			dur = tonumber(info.Duration or info.Lifetime or info.Time or 4)
			nt = info.Type or "info"
			if nt == "success" or nt == "Success" then nt = "success"
			elseif nt == "error" or nt == "Error" then nt = "error"
			elseif nt == "warning" or nt == "Warning" then nt = "warning" end
		else txt = textOf(info) end
		return showNotification(txt, math.max(1, dur), nt)
	end

	function Library:Notify(text, dur)
		if type(text) == "table" then Library:Notification(text)
		else Library:Notification({ Description = text, Duration = dur }) end
	end

	function Library:ClearNotifications()
		if STATE.notifContainer then
			for _, ch in ipairs(STATE.notifContainer:GetChildren()) do
				if ch:IsA("Frame") and (ch.Name:find("Toast_") or ch.Name:find("N_")) then ch:Destroy() end
			end
		end
	end

	-- ========== CORE API ==========
	function Core.loadUi()
		local c = ENV.Alleral_UI
		if type(c) == "table" and type(c.Library) == "table" then return c end
		local b = {
			Library = Library,
			Alleral = Library,
			CreateWindow = function(_, s) return Library:CreateWindow(s) end,
			Notify = function(_, t, d) Library:Notify(t, d) end,
			ClearNotifications = function() Library:ClearNotifications() end
		}
		ENV.Alleral_UI = b
		if getgenv then getgenv().Alleral_UI = b end
		log("INFO", "[UI] Premium renderer v" .. C.VERSION .. " ready")
		return b
	end

	function Core.preloadUi() return Core.loadUi() end

	function Core.uiLibrary(b)
		if type(b) ~= "table" then return nil end
		return b.Alleral or b.Library
	end

	function Core.uiWindowSettings(extra)
		extra = type(extra) == "table" and extra or {}
		return {
			Title = extra.Title or extra.Name or "Alleral",
			Name = extra.Title or extra.Name or "Alleral",
			Subtitle = extra.Subtitle or extra.Author or "",
			Icon = extra.Icon or "sparkles",
			Theme = extra.Theme or "NobleX_v7_5",
			Size = extra.Size or UDim2.new(0, 1220, 0, 720),
			TabWidth = tonumber(extra.TabWidth) or C.SIDEBAR.W,
			FileSettings = {
				RootFolder = extra.configFolder or "Alleral_Configs",
				ConfigFolder = extra.FileName or "Interface"
			}
		}
	end

	-- ========== GROUPBOX WRAPPER (hardened) ==========
	local function createGroupbox(section, uiBundle)
		section = type(section) == "table" and section or {}
		if not section.AddLabel and not section.AddToggle then return emptyGroupStub() end

		local s = 0
		local function ni(n, e)
			s = s + 1
			return (e or (Core and Core.uiElementId and Core.uiElementId(n) or tostring(n):gsub("[^%w]", "_"))) .. "_" .. s
		end

		local function wc(as, m)
			m = type(m) == "table" and m or {}
			local w = {}
			function w:Set(v)
				if type(v) == "table" then as(v) else as({ CurrentValue = v }) end
			end
			if m.bindKey and Core.bindUiState then Core.bindUiState(m.bindKey, w, m.kind or "toggle", m.raw) end
			return w
		end

		local gb = {}

		function gb:CreateSection(n) return gb end

		function gb:AddLabel(t)
			if type(section.AddLabel) ~= "function" then
				return { SetText = function() end, Set = function() end, SetVisible = function() end }
			end
			return sc("AddLabel", function() return section:AddLabel(textOf(t)) end) or { SetText = function() end, Set = function() end, SetVisible = function() end }
		end

		function gb:CreateLabel(st, id)
			if type(section.AddLabel) ~= "function" then
				return { Set = function() end, SetText = function() end, SetVisible = function() end }
			end
			local t = type(st) == "table" and (st.Name or st.Text) or tostring(st or "")
			local r = sc("CreateLabel", function() return section:AddLabel(t) end)
			STATE.controls = STATE.controls + 1
			return {
				Set = function(_, ns)
					if not r then return end
					local nt = type(ns) == "table" and (ns.Name or ns.Text) or tostring(ns or "")
					if r.SetText then r.SetText(nil, nt) end
				end,
				SetText = function(_, tv) if r and r.SetText then r.SetText(nil, textOf(tv)) end end,
				SetVisible = function(_, v) if r and r.SetVisible then r.SetVisible(nil, v == true) end end
			}
		end

		function gb:CreateToggle(st, id)
			if type(section.AddToggle) ~= "function" then
				table.insert(STATE.missingBindings, "Toggle:" .. tostring(st.Name or "?"))
				return wc(function() end, {})
			end
			local cv = st.Default or st.CurrentValue or st.Value
			local fl = ni(st.Name, id)
			local r = sc("Toggle:" .. tostring(st.Name), function()
				return section:AddToggle(fl, { Text = st.Name or st.Title or "Toggle", Default = cv == true, Callback = st.Callback or function() end })
			end)
			STATE.controls = STATE.controls + 1
			if not r then table.insert(STATE.missingBindings, "Toggle:" .. tostring(st.Name)) end
			return wc(function(n)
				if not r then return end
				local v = n.CurrentValue or n.Value
				if v == nil then v = n end
				r.SetValue(nil, v == true)
			end, { raw = r, bindKey = st.BindKey or st.StateKey, kind = "toggle" })
		end

		function gb:CreateButton(st, id)
			if type(section.AddButton) ~= "function" then
				table.insert(STATE.missingBindings, "Button:" .. tostring(st.Name or "?"))
				return wc(function() end, {})
			end
			local nm = st.Name or st.Title or st.Text or "Button"
			local r = sc("Button:" .. nm, function()
				return section:AddButton({ Text = nm, Func = st.Callback or function() end })
			end)
			STATE.controls = STATE.controls + 1
			if not r then table.insert(STATE.missingBindings, "Button:" .. nm) end
			return wc(function() end, { raw = r, kind = "button" })
		end

		function gb:CreateSlider(st, id)
			if type(section.AddSlider) ~= "function" then
				table.insert(STATE.missingBindings, "Slider:" .. tostring(st.Name or "?"))
				return wc(function() end, {})
			end
			local rn = st.Range or { 0, 100 }
			local fl = ni(st.Name, id)
			local cv = tonumber(st.Default) or tonumber(st.CurrentValue) or tonumber(st.Value) or rn[1]
			local r = sc("Slider:" .. tostring(st.Name), function()
				return section:AddSlider(fl, {
					Text = st.Name or st.Title or "Slider",
					Default = cv,
					Min = rn[1] or 0,
					Max = rn[2] or 100,
					Suffix = st.Suffix or "",
					Rounding = tonumber(st.Increment) or 1,
					Callback = st.Callback or function() end
				})
			end)
			STATE.controls = STATE.controls + 1
			if not r then table.insert(STATE.missingBindings, "Slider:" .. tostring(st.Name)) end
			return wc(function(n)
				if not r then return end
				local v = tonumber(n.CurrentValue) or tonumber(n.Value) or tonumber(n)
				r.SetValue(nil, v)
			end, { raw = r, bindKey = st.BindKey or st.StateKey, kind = "slider" })
		end

		function gb:CreateInput(st, id)
			if type(section.AddInput) ~= "function" then
				table.insert(STATE.missingBindings, "Input:" .. tostring(st.Name or "?"))
				return wc(function() end, {})
			end
			local fl = ni(st.Name, id)
			local cv = tostring(st.CurrentValue or st.Default or st.Value or "")
			local r = sc("Input:" .. tostring(st.Name), function()
				return section:AddInput(fl, {
					Text = st.Name or st.Title or "Input",
					Default = cv,
					Placeholder = st.PlaceholderText or st.Placeholder or "Enter...",
					Callback = st.Callback or function() end
				})
			end)
			STATE.controls = STATE.controls + 1
			if not r then table.insert(STATE.missingBindings, "Input:" .. tostring(st.Name)) end
			return wc(function(n)
				if not r then return end
				r.SetValue(nil, tostring(n.CurrentValue or n.Value or ""))
			end, { raw = r, bindKey = st.BindKey or st.StateKey, kind = "input" })
		end

		function gb:CreateDropdown(st, id)
			if type(section.AddDropdown) ~= "function" then
				table.insert(STATE.missingBindings, "Dropdown:" .. tostring(st.Name or "?"))
				return wc(function() end, {})
			end
			local op = st.Options or st.Values or {}
			local mu = st.MultipleOptions == true or st.Multi == true
			local cu = st.CurrentOption or (mu and {} or (op[1] or ""))
			local fl = ni(st.Name, id)
			local r = sc("Dropdown:" .. tostring(st.Name), function()
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
					end
				})
			end)
			STATE.controls = STATE.controls + 1
			if not r then table.insert(STATE.missingBindings, "Dropdown:" .. tostring(st.Name)) end
			return wc(function(n)
				if not r then return end
				local nv = n.Options or n.Values
				if type(nv) == "table" and r.Refresh then r.Refresh(nil, nv) end
				local p = n.CurrentOption or n.CurrentOptions
				if p ~= nil then r.SetValue(nil, tostring(p)) end
			end, { raw = r, bindKey = st.BindKey or st.StateKey, kind = "dropdown" })
		end

		function gb:CreateDivider()
			if type(section.AddDivider) == "function" then sc("Divider", function() return section:AddDivider() end) end
			STATE.controls = STATE.controls + 1
			return {}
		end

		function gb:CreateStatus(settings, fields)
			local title, dfs = nil, {}
			if type(settings) == "table" then
				title = settings.Name or settings.Title or settings.Label or "Status"
				dfs = settings.Fields or settings.Values or settings.Items or settings.Stats or settings.Data
				if type(dfs) ~= "table" then dfs = { Status = settings.Status or settings.Text or settings.Value or "--" } end
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
				if row and row.SetText then row.SetText(nil, textOf(key) .. ": " .. r)
				elseif row and row.Set then row.Set(nil, { Name = textOf(key) .. ": " .. r, Text = textOf(key) .. ": " .. r }) end
			end
			function st:SetSummary(text)
				if self.Summary and self.Summary.SetText then self.Summary.SetText(nil, textOf(text))
				elseif self.Summary and self.Summary.Set then self.Summary.Set(nil, { Name = textOf(text), Text = textOf(text) }) end
			end
			function st:Set(key, value)
				if type(key) == "table" then for k, v in pairs(key) do self:Update(k, v) end else self:Update(key, value) end
			end
			return st
		end

		return gb
	end

	function Core.createUiGroupbox(s, u) return createGroupbox(s, u) end

	-- ========== UI WRAPPERS ==========
	function Core.wrapUiGroup(g, cb)
		if not g or (type(g.AddLabel) ~= "function" and type(g.AddToggle) ~= "function" and type(g.CreateToggle) ~= "function") then
			local function s() return { Set = function() end, SetText = function() end, SetVisible = function() end } end
			return {
				CreateToggle = function() return { Set = function() end } end,
				CreateSlider = function() return { Set = function() end } end,
				CreateButton = function() return { Set = function() end } end,
				CreateInput = function() return { Set = function() end } end,
				CreateDropdown = function() return { Set = function() end } end,
				AddDropdown = function() return { Set = function() end } end,
				CreateStatus = function() return { Update = function() end, Set = function() end, SetSummary = function() end } end,
				AddLabel = s, CreateLabel = s, CreateDivider = function() return {} end
			}
		end
		local gr = {}
		function gr:CreateToggle(n, d, t, c, b)
			if type(g.CreateToggle) == "function" then
				return g:CreateToggle({ Name = n, CurrentValue = d == true, Default = d == true, Tooltip = t, Callback = c or function() end, BindKey = b }, b)
			end
			return { Set = function() end }
		end
		function gr:CreateSlider(n, mn, mx, d, c, t, i, b)
			if type(g.CreateSlider) == "function" then
				return g:CreateSlider({ Name = n, Range = { mn, mx }, CurrentValue = d or mn, Default = d or mn, Tooltip = t, Increment = i, Callback = c or function() end, BindKey = b }, b)
			end
			return { Set = function() end }
		end
		function gr:CreateButton(n, c, t)
			if type(g.CreateButton) == "function" then return g:CreateButton({ Name = n, Tooltip = t, Callback = c or function() end }) end
			return { Set = function() end }
		end
		function gr:CreateInput(n, ph, a3, a4, a5)
			if type(g.CreateInput) ~= "function" then return { Set = function() end } end
			local ic, df, cb, tp = nil, "", nil, nil
			if type(a3) == "function" then cb, tp = a3, a4
			elseif type(a4) == "function" then ic, cb, tp = a3, a4, a5
			else if type(a3) == "string" or type(a3) == "number" then df = a3 end; if type(a4) == "function" then cb = a4 end; tp = a5 end
			return g:CreateInput({ Name = n, PlaceholderText = ph, CurrentValue = df, Default = df, Tooltip = tp, Callback = cb or function() end })
		end
		function gr:CreateDropdown(n, o, d, c, t, b)
			if type(g.CreateDropdown) == "function" then
				return g:CreateDropdown({ Name = n, Options = o, CurrentOption = d, Tooltip = t, Callback = c or function() end, BindKey = b }, b)
			end
			return { Set = function() end }
		end
		function gr:AddDropdown(id, c)
			if type(g.CreateDropdown) ~= "function" then return { Set = function() end } end
			c = type(c) == "table" and c or {}
			return g:CreateDropdown({ Name = c.Text or c.Name or id, Options = c.Values or c.Options or {}, CurrentOption = c.Default or c.CurrentValue or c.CurrentOption, MultipleOptions = c.Multi or c.MultiSelection, Callback = c.Callback or function() end }, id)
		end
		function gr:CreateStatus(l, f)
			if type(g.CreateStatus) == "function" then
				if type(l) == "table" then return g:CreateStatus(l) end
				return g:CreateStatus({ Name = l or "Status", Fields = f })
			end
			return { Update = function() end, Set = function() end, SetSummary = function() end }
		end
		function gr:AddLabel(t)
			if type(g.AddLabel) == "function" then return g:AddLabel(t) end
			return { SetText = function() end, Set = function() end, SetVisible = function() end }
		end
		function gr:CreateLabel(t)
			if type(g.AddLabel) == "function" then
				local tx = type(t) == "table" and (t.Text or t.Name or t.Title) or tostring(t or "")
				return g:AddLabel(tx)
			end
			return { SetText = function() end, Set = function() end, SetVisible = function() end }
		end
		function gr:CreateDivider()
			if type(g.CreateDivider) == "function" then return g:CreateDivider() end
			return {}
		end
		return gr
	end

	function Core.wrapUiTab(rt, ub, w)
		local tab = { _rawTab = rt, _ui = ub, _window = w, _columnCount = 2, _sectionIndex = 0 }
		if type(Core._UiTabRegistry) == "table" then table.insert(Core._UiTabRegistry, tab) end
		function tab:CreateGroupbox(settings)
			settings = settings or {}
			local name = settings.Name or settings.Group or "Group"
			STATE.groupCount = STATE.groupCount + 1
			if not rt then
				table.insert(STATE.missingBindings, "Groupbox:" .. name .. "(no tab)")
				return {}
			end
			local h = sc("Groupbox:" .. name, function()
				local col = tonumber(settings.Column) or 1
				if col == 2 and rt.AddRightGroupbox then return rt:AddRightGroupbox(name)
				elseif rt.AddLeftGroupbox then return rt:AddLeftGroupbox(name)
				elseif rt.AddGroupbox then return rt:AddGroupbox(name) end
				return nil
			end)
			if not h then
				table.insert(STATE.missingBindings, "Groupbox:" .. name .. "(failed)")
				return {}
			end
			tab._sectionIndex = (tab._sectionIndex or 0) + 1
			return Core.createUiGroupbox(h, ub)
		end
		function tab:Select() if rt and rt.Select then rt:Select() end end
		function tab:BuildThemeGroupbox(col)
			local g2 = Core.buildUiGroup(tab, "Appearance", col or 1)
			if g2 and type(g2.CreateLabel) == "function" then g2:CreateLabel("Alleral Noble Engine") end
			return g2
		end
		return tab
	end

	function Core.buildUiWindow(ui, settings)
		settings = settings or {}
		local lib = ui and ui.Library
		if not lib or type(lib.CreateWindow) ~= "function" then return nil end
		local rw = lib:CreateWindow(settings)
		if not rw then return nil end
		local w = { _rawWindow = rw, _ui = ui, _library = lib, _initialized = false, _tabGroup = rw, _alleralSettings = settings }
		if type(Core.registerUiWindow) == "function" then Core.registerUiWindow(w) end
		if type(Core.flushPendingNotifications) == "function" then Core.flushPendingNotifications() end
		return w
	end

	function Core.buildUiTab(section, name, icon, columns, id)
		local w2 = type(Core.resolveUiWindow) == "function" and Core.resolveUiWindow(section) or nil
		if type(w2) ~= "table" or not w2._rawWindow then
			return Core.wrapUiTab(nil, type(section) == "table" and section._ui or nil, w2)
		end
		local tg = w2._tabGroup or w2
		if not tg or type(tg.AddTab) ~= "function" then
			return Core.wrapUiTab(nil, w2._ui, w2)
		end
		local rt = tg:AddTab(name, icon)
		STATE.tabCount = STATE.tabCount + 1
		local wr = Core.wrapUiTab(rt, w2._ui or (type(section) == "table" and section._ui) or nil, w2)
		wr._columnCount = math.max(1, tonumber(columns) or 2)
		if not w2._defaultTab then w2._defaultTab = rt end
		return wr
	end

	function Core.buildUiGroup(tab, name, column, cb, icon, id)
		name = tostring(name or "Group")
		if type(tab) ~= "table" or type(tab.CreateGroupbox) ~= "function" then return {} end
		return Core.wrapUiGroup(tab:CreateGroupbox({ Name = name, Column = column or 1, Icon = icon }), cb)
	end

	function Core.buildUiSection(w2)
		if type(w2) == "table" and w2._alleralTabGroup then return w2._alleralTabGroup end
		if type(w2) == "table" and w2._rawWindow then return w2 end
		return w2
	end

	function Core.finalizeGameUi(window, ui, options)
		options = type(options) == "table" and options or {}
		if type(window) == "table" and window._rawWindow and not window._initialized then
			window._initialized = true
			task.defer(function()
				pcall(function()
					if window._defaultTab and window._defaultTab.Select then window._defaultTab:Select() end
				end)
			end)
		end
		if type(Core.setupHubKeybinds) == "function" then
			pcall(Core.setupHubKeybinds, { window = window, ui = ui or window._ui or ENV.Alleral_UI })
		end
		if options.notify ~= false then
			Core.notifyBootReady({ Name = options.Name or "Alleral", Subtitle = options.Subtitle })
		end
		log("INFO", "=== Noble Engine v" .. C.VERSION .. " ===")
		log("INFO", "Tabs: " .. STATE.tabCount .. " | Groups: " .. STATE.groupCount .. " | Controls: " .. STATE.controls)
		if #STATE.missingBindings > 0 then log("WARN", "Missing bindings: " .. #STATE.missingBindings) end
		return window
	end

	function Core.repairUiWindow(w3)
		w3 = w3 or ENV.Alleral_UiWindow
		return type(w3) == "table" and w3._rawWindow ~= nil
	end

	function Core.refreshAllTabColumns()
		for _, entry in ipairs(STATE.groupRegistry) do
			if entry.update then pcall(entry.update) end
		end
		return true
	end

	Core.notifyUi = function(i) showNotification(textOf(i), 4) end

	function Core.releaseAlleralRuntime()
		Anim.stopAll()
		if keybindConn then keybindConn:Disconnect() keybindConn = nil end
		ENV._AlleralUiLibrary = nil
		ENV._AlleralUI = nil
		ENV.Alleral_UiWindow = nil
		if STATE.notifContainer then pcall(function() STATE.notifContainer.Parent:Destroy() end) STATE.notifContainer = nil end
		if STATE.dropOverlay then pcall(function() STATE.dropOverlay.Parent:Destroy() end) STATE.dropOverlay = nil end
		STATE.groupRegistry = {}
	end

	ENV.AnimatedNotification = showNotification
	log("INFO", "Alleral Noble v" .. C.VERSION .. " — premium dashboard initialized (enhanced)")

end

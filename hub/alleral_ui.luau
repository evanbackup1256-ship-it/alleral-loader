-- Alleral UI layer — v7.0.0 Noble Engine
--[[
	STANDALONE GUI RENDERING ENGINE
	Zero Linoria dependency. Raw Roblox Instances.
	Dynamic framework — adapts to any game script automatically.
]]

return function(Core)
	local TS = game:GetService("TweenService")
	local UIS = game:GetService("UserInputService")
	local Players = game:GetService("Players")
	local CoreGui = game:GetService("CoreGui")

	-- ==================== CONFIG ====================
	local C = {
		VERSION = "7.0.0",
		WINDOW = { W = 780, H = 540, MIN_W = 680, MIN_H = 440, RADIUS = 12, PADDING = 16 },
		SIDEBAR = { W = 170, ICON_SIZE = 20, ITEM_H = 40, RADIUS = 8 },
		GROUP = { PADDING = 14, GAP = 12, RADIUS = 10, TITLE_H = 32 },
		CONTROL = { ROW_H = 34, GAP = 8, RADIUS = 6 },
		TOGGLE = { W = 40, H = 22, THUMB = 16, RADIUS = 11 },
		SLIDER = { TRACK_H = 6, THUMB = 14, FILL_COLOR },
		FONT = Enum.Font.Gotham,
		FONT_BOLD = Enum.Font.GothamBold,
		TEXT = 13,
		TEXT_SM = 11,
		TEXT_TITLE = 15,
		TEXT_HEADER = 18,

		COLOR = {
			BG0 = Color3.fromRGB(10, 11, 16),
			BG1 = Color3.fromRGB(16, 17, 24),
			BG2 = Color3.fromRGB(22, 24, 33),
			BG3 = Color3.fromRGB(28, 30, 40),
			BG4 = Color3.fromRGB(35, 37, 48),
			ACCENT = Color3.fromRGB(130, 80, 255),
			ACCENT_LIGHT = Color3.fromRGB(155, 110, 255),
			ACCENT_DARK = Color3.fromRGB(100, 55, 220),
			ACCENT_GLOW = Color3.fromRGB(130, 80, 255),
			GREEN = Color3.fromRGB(52, 211, 153),
			GREEN_DARK = Color3.fromRGB(30, 140, 100),
			RED = Color3.fromRGB(248, 113, 113),
			RED_DARK = Color3.fromRGB(180, 60, 60),
			YELLOW = Color3.fromRGB(250, 204, 21),
			YELLOW_DARK = Color3.fromRGB(180, 140, 10),
			BLUE = Color3.fromRGB(96, 165, 250),
			BLUE_DARK = Color3.fromRGB(50, 110, 200),
			TEXT = Color3.fromRGB(230, 232, 240),
			TEXT2 = Color3.fromRGB(156, 163, 175),
			TEXT3 = Color3.fromRGB(107, 114, 128),
			BORDER = Color3.fromRGB(45, 47, 56),
			BORDER_LIGHT = Color3.fromRGB(60, 63, 75),
			SHADOW = Color3.fromRGB(0, 0, 0),
			SCROLLBAR = Color3.fromRGB(55, 58, 70),
			WHITE = Color3.fromRGB(255, 255, 255),
			BLACK = Color3.fromRGB(0, 0, 0),
		},
		ANIM = { FAST = 0.12, NORM = 0.2, SLOW = 0.3, SPRING = 0.4, SNAPPY = 0.15 },
	}

	-- ==================== ENVIRONMENT ====================
	local ENV = (function()
		local ok, e = pcall(function() return getgenv and getgenv() or getfenv() end)
		return ok and e or {}
	end)()

	local STATE = {
		tabs = {}, groups = {}, controls = 0,
		activeTweens = {}, windows = {}, windowCount = 0,
		tabCount = 0, groupCount = 0,
		notifications = {}, notifContainer = nil, notifIdx = 0,
		missingBindings = {}, errorLog = {},
		stateBindings = {},
	}

	-- ==================== UTILITIES ====================
	local function log(lvl, msg)
		if Core and type(Core.say) == "function" then Core.say("[" .. lvl .. "] " .. msg) end
		table.insert(STATE.errorLog, { lvl = lvl, msg = msg, ts = os.date("%H:%M:%S") })
	end

	local function sc(name, fn, fb)
		if type(fn) ~= "function" then return fb end
		local ok, r = pcall(fn)
		if not ok then log("WARN", name .. ": " .. tostring(r)); return fb end
		return r
	end

	local function textOf(v)
		if v == nil then return "" end
		if type(v) == "table" then for _, k in ipairs({"Text","Content","Description","Message","Title","Name"}) do if v[k] ~= nil then return textOf(v[k]) end end end
		return tostring(v)
	end

	local function deepClone(v, seen)
		if type(v) ~= "table" then return v end
		seen = seen or {}; if seen[v] then return seen[v] end
		local c = {}; seen[v] = c
		for k, val in pairs(v) do c[deepClone(k, seen)] = deepClone(val, seen) end
		return c
	end

	-- ==================== ANIMATION ENGINE ====================
	local Anim = {}

	function Anim.tween(inst, props, dur, style, dir, rev)
		dur = dur or C.ANIM.NORM
		style = style or Enum.EasingStyle.Quad
		dir = dir or Enum.EasingDirection.Out
		rev = rev or false
		local t = TS:Create(inst, TweenInfo.new(dur, style, dir, 0, rev, 0), props)
		t:Play()
		table.insert(STATE.activeTweens, t)
		t.Completed:Connect(function()
			for i, tt in ipairs(STATE.activeTweens) do if tt == t then table.remove(STATE.activeTweens, i); break end end
		end)
		return t
	end

	function Anim.springIn(inst, dur)
		dur = dur or C.ANIM.SPRING
		local sx, sy = inst.Size.X.Scale, inst.Size.Y.Scale
		inst.Size = UDim2.new(sx * 0.92, inst.Size.X.Offset, sy * 0.92, inst.Size.Y.Offset)
		inst.BackgroundTransparency = 0.5
		return Anim.tween(inst, {
			Size = UDim2.new(sx, inst.Size.X.Offset, sy, inst.Size.Y.Offset),
			BackgroundTransparency = inst.BackgroundTransparency,
		}, dur, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	end

	function Anim.fadeIn(inst, dur)
		dur = dur or C.ANIM.NORM
		inst.Visible = true
		inst.BackgroundTransparency = 1
		if inst:IsA("TextLabel") or inst:IsA("TextButton") then inst.TextTransparency = 1 end
		local p = { BackgroundTransparency = 0 }
		if inst:IsA("TextLabel") or inst:IsA("TextButton") then p.TextTransparency = 0 end
		return Anim.tween(inst, p, dur)
	end

	function Anim.fadeOut(inst, dur, hide)
		dur = dur or C.ANIM.FAST
		hide = hide ~= false
		local p = { BackgroundTransparency = 1 }
		if inst:IsA("TextLabel") or inst:IsA("TextButton") then p.TextTransparency = 1 end
		local t = Anim.tween(inst, p, dur, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		if hide then t.Completed:Connect(function() inst.Visible = false end) end
		return t
	end

	function Anim.slideX(inst, goal, dur)
		dur = dur or C.ANIM.NORM
		return Anim.tween(inst, { Position = goal }, dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end

	function Anim.stopAll()
		for _, t in ipairs(STATE.activeTweens) do pcall(function() t:Cancel() end) end
		STATE.activeTweens = {}
	end

	-- ==================== COMPONENT FACTORY ====================
	local function make(className, props)
		local obj = Instance.new(className)
		for k, v in pairs(props or {}) do
			if k == "Parent" then obj.Parent = v
			elseif k == "Children" then for _, c in ipairs(v) do c.Parent = obj end
			else pcall(function() obj[k] = v end) end
		end
		return obj
	end

	local function corner(obj, r)
		r = r or C.WINDOW.RADIUS
		local c = make("UICorner", { CornerRadius = UDim.new(0, r), Parent = obj })
		return c
	end

	local function stroke(obj, clr, thick, trans)
		clr = clr or C.COLOR.BORDER
		thick = thick or 1
		trans = trans or 0.5
		return make("UIStroke", { Color = clr, Thickness = thick, Transparency = trans, Parent = obj })
	end

	local function gradient(obj, c1, c2, rot)
		c1 = c1 or C.COLOR.ACCENT
		c2 = c2 or C.COLOR.ACCENT_DARK
		rot = rot or 90
		return make("UIGradient", {
			Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, c1), ColorSequenceKeypoint.new(1, c2) }),
			Rotation = rot, Parent = obj,
		})
	end

	local function padding(obj, l, r, t, b)
		return make("UIPadding", {
			PaddingLeft = UDim.new(0, l or 0),
			PaddingRight = UDim.new(0, r or 0),
			PaddingTop = UDim.new(0, t or 0),
			PaddingBottom = UDim.new(0, b or 0),
			Parent = obj,
		})
	end

	-- ==================== CONTROL: LABEL ====================
	local function createLabel(parent, text, bold)
		local lbl = make("TextLabel", {
			BackgroundTransparency = 1,
			Text = tostring(text or ""),
			TextColor3 = C.COLOR.TEXT,
			Font = bold and C.FONT_BOLD or C.FONT,
			TextSize = C.TEXT,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			RichText = false,
			Parent = parent,
		})
		return {
			_raw = lbl,
			Set = function(_, v)
				local t = type(v) == "table" and (v.Name or v.Text or v.Content) or tostring(v)
				lbl.Text = tostring(t)
			end,
			SetText = function(_, t) lbl.Text = tostring(t) end,
			SetVisible = function(_, v) lbl.Visible = v == true end,
		}
	end

	-- ==================== CONTROL: DIVIDER ====================
	local function createDivider(parent)
		return make("Frame", {
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = C.COLOR.BORDER,
			BorderSizePixel = 0,
			Parent = parent,
		})
	end

	-- ==================== CONTROL: TOGGLE ====================
	local function createToggle(parent, name, default, callback)
		local group = make("Frame", {
			Size = UDim2.new(1, 0, 0, C.CONTROL.ROW_H),
			BackgroundTransparency = 1,
			Parent = parent,
		})

		local lbl = make("TextLabel", {
			Size = UDim2.new(1, -C.TOGGLE.W - 12, 1, 0),
			BackgroundTransparency = 1,
			Text = tostring(name),
			TextColor3 = C.COLOR.TEXT,
			Font = C.FONT,
			TextSize = C.TEXT,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = group,
		})

		local track = make("Frame", {
			Size = UDim2.new(0, C.TOGGLE.W, 0, C.TOGGLE.H),
			Position = UDim2.new(1, -C.TOGGLE.W, 0.5, -C.TOGGLE.H / 2),
			BackgroundColor3 = C.COLOR.BG4,
			BorderSizePixel = 0,
			Parent = group,
		})
		corner(track, C.TOGGLE.RADIUS)
		stroke(track, C.COLOR.BORDER, 1, 0.6)

		local thumb = make("Frame", {
			Size = UDim2.new(0, C.TOGGLE.THUMB, 0, C.TOGGLE.THUMB),
			Position = UDim2.new(0, 3, 0.5, -C.TOGGLE.THUMB / 2),
			BackgroundColor3 = C.COLOR.TEXT2,
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = track,
		})
		corner(thumb, 8)

		local enabled = default == true
		local function updateUI()
			if enabled then
				Anim.tween(track, { BackgroundColor3 = C.COLOR.ACCENT }, C.ANIM.FAST)
				Anim.tween(thumb, {
					Position = UDim2.new(1, -C.TOGGLE.THUMB - 3, 0.5, -C.TOGGLE.THUMB / 2),
					BackgroundColor3 = C.COLOR.WHITE,
				}, C.ANIM.FAST)
			else
				Anim.tween(track, { BackgroundColor3 = C.COLOR.BG4 }, C.ANIM.FAST)
				Anim.tween(thumb, {
					Position = UDim2.new(0, 3, 0.5, -C.TOGGLE.THUMB / 2),
					BackgroundColor3 = C.COLOR.TEXT2,
				}, C.ANIM.FAST)
			end
		end

		if enabled then
			track.BackgroundColor3 = C.COLOR.ACCENT
			thumb.Position = UDim2.new(1, -C.TOGGLE.THUMB - 3, 0.5, -C.TOGGLE.THUMB / 2)
			thumb.BackgroundColor3 = C.COLOR.WHITE
		end

		local function toggle()
			enabled = not enabled
			updateUI()
			if callback then callback(enabled) end
		end

		track.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then toggle() end
		end)
		lbl.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then toggle() end
		end)

		local trackHover = make("Frame", {
			Size = UDim2.new(1, 12, 1, 12),
			Position = UDim2.new(0, -6, 0, -6),
			BackgroundColor3 = C.COLOR.ACCENT,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ZIndex = 0,
			Parent = track,
		})
		corner(trackHover, C.TOGGLE.RADIUS + 6)

		track.MouseEnter:Connect(function()
			Anim.tween(trackHover, { BackgroundTransparency = 0.75 }, C.ANIM.FAST)
		end)
		track.MouseLeave:Connect(function()
			Anim.tween(trackHover, { BackgroundTransparency = 1 }, C.ANIM.FAST)
		end)

		local control = {
			_raw = group,
			_toggle = toggle,
			Set = function(_, v)
				local val
				if type(v) == "table" then val = v.CurrentValue or v.Value else val = v end
				if val ~= nil and val ~= enabled then toggle() end
			end,
			SetValue = function(_, v)
				if v ~= nil and v ~= enabled then toggle() end
			end,
			GetValue = function() return enabled end,
			Container = group,
		}
		return control
	end

	-- ==================== CONTROL: SLIDER ====================
	local function createSlider(parent, name, minVal, maxVal, default, callback, suffix, rounding)
		minVal = minVal or 0
		maxVal = maxVal or 100
		default = default or minVal
		suffix = suffix or ""
		rounding = rounding or 1

		local group = make("Frame", {
			Size = UDim2.new(1, 0, 0, C.CONTROL.ROW_H + 18),
			BackgroundTransparency = 1,
			Parent = parent,
		})

		local top = make("Frame", {
			Size = UDim2.new(1, 0, 0, C.CONTROL.ROW_H),
			BackgroundTransparency = 1,
			Parent = group,
		})

		local lbl = make("TextLabel", {
			Size = UDim2.new(1, -60, 1, 0),
			BackgroundTransparency = 1,
			Text = tostring(name),
			TextColor3 = C.COLOR.TEXT,
			Font = C.FONT,
			TextSize = C.TEXT,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = top,
		})

		local valLbl = make("TextLabel", {
			Size = UDim2.new(0, 56, 1, 0),
			Position = UDim2.new(1, -56, 0, 0),
			BackgroundTransparency = 1,
			Text = tostring(default) .. suffix,
			TextColor3 = C.COLOR.ACCENT_LIGHT,
			Font = C.FONT_BOLD,
			TextSize = C.TEXT_SM,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextYAlignment = Enum.TextYAlignment.Center,
			Parent = top,
		})

		local track = make("Frame", {
			Size = UDim2.new(1, 0, 0, C.SLIDER.TRACK_H),
			Position = UDim2.new(0, 0, 1, -C.SLIDER.TRACK_H - 4),
			BackgroundColor3 = C.COLOR.BG4,
			BorderSizePixel = 0,
			Parent = group,
		})
		corner(track, 3)

		local fill = make("Frame", {
			Size = UDim2.new(0, 0, 1, 0),
			BackgroundColor3 = C.COLOR.ACCENT,
			BorderSizePixel = 0,
			ZIndex = 1,
			Parent = track,
		})
		corner(fill, 3)
		gradient(fill, C.COLOR.ACCENT_LIGHT, C.COLOR.ACCENT, 0)

		local thumb = make("Frame", {
			Size = UDim2.new(0, C.SLIDER.THUMB, 0, C.SLIDER.THUMB),
			Position = UDim2.new(0, 0, 0.5, -C.SLIDER.THUMB / 2),
			BackgroundColor3 = C.COLOR.WHITE,
			BorderSizePixel = 0,
			ZIndex = 3,
			Parent = track,
		})
		corner(thumb, 7)
		stroke(thumb, C.COLOR.ACCENT, 2, 0)

		local currentValue = default
		local dragging = false

		local function setValue(fraction)
			currentValue = minVal + fraction * (maxVal - minVal)
			if rounding >= 1 then currentValue = math.floor(currentValue / rounding + 0.5) * rounding
			else currentValue = math.floor(currentValue * (1 / rounding) + 0.5) / (1 / rounding) end
			currentValue = math.clamp(currentValue, minVal, maxVal)
			local frac = (currentValue - minVal) / (maxVal - minVal)
			fill.Size = UDim2.new(frac, 0, 1, 0)
			thumb.Position = UDim2.new(frac, -C.SLIDER.THUMB / 2, 0.5, -C.SLIDER.THUMB / 2)
			valLbl.Text = tostring(currentValue) .. suffix
		end

		local function updateFromPos(x)
			local relX = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
			setValue(relX)
			if callback then callback(currentValue) end
		end

		setValue((default - minVal) / (maxVal - minVal))

		local mouse = Players.LocalPlayer:GetMouse()

		track.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true
				Anim.tween(thumb, { Size = UDim2.new(0, C.SLIDER.THUMB + 4, 0, C.SLIDER.THUMB + 4) }, C.ANIM.FAST)
			end
		end)

		track.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = false
				Anim.tween(thumb, { Size = UDim2.new(0, C.SLIDER.THUMB, 0, C.SLIDER.THUMB) }, C.ANIM.FAST)
				if callback then callback(currentValue) end
			end
		end)

		if mouse then
			mouse.Move:Connect(function()
				if dragging then updateFromPos(mouse.X) end
			end)
		end
		UIS.InputChanged:Connect(function(input)
			if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
				updateFromPos(input.Position.X)
			end
		end)

		local control = {
			_raw = group,
			Set = function(_, v)
				if type(v) == "table" then v = v.CurrentValue or v.Value end
				if tonumber(v) then setValue((v - minVal) / (maxVal - minVal)) end
			end,
			SetValue = function(_, v)
				if tonumber(v) then setValue((v - minVal) / (maxVal - minVal)) end
			end,
			GetValue = function() return currentValue end,
			Container = group,
		}
		return control
	end

	-- ==================== CONTROL: BUTTON ====================
	local function createButton(parent, name, callback)
		local group = make("Frame", {
			Size = UDim2.new(1, 0, 0, C.CONTROL.ROW_H),
			BackgroundTransparency = 1,
			Parent = parent,
		})

		local btn = make("TextButton", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = C.COLOR.BG3,
			BorderSizePixel = 0,
			Text = tostring(name),
			TextColor3 = C.COLOR.TEXT,
			Font = C.FONT_BOLD,
			TextSize = C.TEXT_SM + 1,
			AutoButtonColor = false,
			Parent = group,
		})
		corner(btn, C.CONTROL.RADIUS)
		stroke(btn, C.COLOR.BORDER, 1, 0.5)

		btn.MouseEnter:Connect(function()
			Anim.tween(btn, { BackgroundColor3 = C.COLOR.ACCENT }, C.ANIM.FAST)
			Anim.tween(btn, { TextColor3 = C.COLOR.WHITE }, C.ANIM.FAST)
		end)
		btn.MouseLeave:Connect(function()
			Anim.tween(btn, { BackgroundColor3 = C.COLOR.BG3 }, C.ANIM.FAST)
			Anim.tween(btn, { TextColor3 = C.COLOR.TEXT }, C.ANIM.FAST)
		end)
		btn.MouseButton1Down:Connect(function()
			Anim.tween(btn, { BackgroundColor3 = C.COLOR.ACCENT_DARK }, C.ANIM.SNAPPY)
		end)
		btn.MouseButton1Up:Connect(function()
			Anim.tween(btn, { BackgroundColor3 = C.COLOR.ACCENT }, C.ANIM.FAST)
		end)

		local conn
		if callback then
			conn = btn.MouseButton1Click:Connect(function()
				Anim.tween(btn, { BackgroundColor3 = C.COLOR.ACCENT }, C.ANIM.FAST)
				callback()
			end)
		end

		local control = {
			_raw = group,
			Set = function() end,
			Container = group,
		}
		return control
	end

	-- ==================== CONTROL: INPUT ====================
	local function createInput(parent, name, default, placeholder, callback)
		default = default or ""
		placeholder = placeholder or "Enter..."

		local group = make("Frame", {
			Size = UDim2.new(1, 0, 0, C.CONTROL.ROW_H + 18),
			BackgroundTransparency = 1,
			Parent = parent,
		})

		local lbl = make("TextLabel", {
			Size = UDim2.new(1, 0, 0, C.CONTROL.ROW_H),
			BackgroundTransparency = 1,
			Text = tostring(name),
			TextColor3 = C.COLOR.TEXT2,
			Font = C.FONT,
			TextSize = C.TEXT_SM,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			Parent = group,
		})

		local box = make("TextBox", {
			Size = UDim2.new(1, 0, 0, 28),
			Position = UDim2.new(0, 0, 0, C.CONTROL.ROW_H),
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
			Parent = group,
		})
		corner(box, C.CONTROL.RADIUS)
		stroke(box, C.COLOR.BORDER, 1, 0.6)

		box.Focused:Connect(function()
			Anim.tween(box, { BackgroundColor3 = C.COLOR.BG4 }, C.ANIM.FAST)
			stroke(box, C.COLOR.ACCENT, 2, 0)
		end)
		box.FocusLost:Connect(function(ep)
			Anim.tween(box, { BackgroundColor3 = C.COLOR.BG3 }, C.ANIM.FAST)
			stroke(box, C.COLOR.BORDER, 1, 0.6)
			if callback then callback(box.Text, ep) end
		end)

		local control = {
			_raw = group,
			Set = function(_, v)
				if type(v) == "table" then v = v.CurrentValue or v.Value or v.Text end
				box.Text = tostring(v or "")
			end,
			SetValue = function(_, v) box.Text = tostring(v or "") end,
			GetValue = function() return box.Text end,
			Container = group,
		}
		return control
	end

	-- ==================== CONTROL: DROPDOWN ====================
	local function createDropdown(parent, name, options, default, callback, multi, searchable)
		options = type(options) == "table" and options or {}
		multi = multi == true
		searchable = searchable == true or multi == true

		local group = make("Frame", {
			Size = UDim2.new(1, 0, 0, C.CONTROL.ROW_H),
			BackgroundTransparency = 1,
			Parent = parent,
		})

		local lbl = make("TextLabel", {
			Size = UDim2.new(0, 100, 1, 0),
			BackgroundTransparency = 1,
			Text = tostring(name),
			TextColor3 = C.COLOR.TEXT2,
			Font = C.FONT,
			TextSize = C.TEXT_SM,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			Parent = group,
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
			return tostring(selected)
		end

		local trigger = make("TextButton", {
			Size = UDim2.new(1, -104, 1, 0),
			Position = UDim2.new(0, 104, 0, 0),
			BackgroundColor3 = C.COLOR.BG3,
			BorderSizePixel = 0,
			Text = getDisplayText(),
			TextColor3 = C.COLOR.TEXT,
			Font = C.FONT,
			TextSize = C.TEXT_SM,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			AutoButtonColor = false,
			Parent = group,
		})
		corner(trigger, C.CONTROL.RADIUS)
		stroke(trigger, C.COLOR.BORDER, 1, 0.5)
		padding(trigger, 8, 24, 0, 0)

		local arrow = make("TextLabel", {
			Size = UDim2.new(0, 16, 0, 16),
			Position = UDim2.new(1, -20, 0.5, -8),
			BackgroundTransparency = 1,
			Text = "v",
			TextColor3 = C.COLOR.TEXT3,
			Font = C.FONT,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			Parent = trigger,
		})

		local dropdown = make("Frame", {
			Size = UDim2.new(1, -104, 0, 0),
			Position = UDim2.new(0, 104, 1, 4),
			BackgroundColor3 = C.COLOR.BG2,
			BorderSizePixel = 0,
			Visible = false,
			ZIndex = 100,
			Parent = group,
		})
		corner(dropdown, C.CONTROL.RADIUS)
		stroke(dropdown, C.COLOR.ACCENT, 1, 0.3)
		make("Frame", {
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = C.COLOR.ACCENT,
			BorderSizePixel = 0,
			ZIndex = 101,
			Parent = dropdown,
		})

		local scroll = make("ScrollingFrame", {
			Size = UDim2.new(1, 0, 0, 0),
			Position = UDim2.new(0, 0, 0, 2),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = C.COLOR.SCROLLBAR,
			CanvasSize = UDim2.new(0, 0, 0, #options * 32),
			Visible = true,
			ZIndex = 101,
			Parent = dropdown,
		})

		local list = make("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = scroll,
		})

		local searchBox
		if searchable then
			searchBox = make("TextBox", {
				Size = UDim2.new(1, -8, 0, 28),
				Position = UDim2.new(0, 4, 0, 2),
				BackgroundColor3 = C.COLOR.BG3,
				BorderSizePixel = 0,
				PlaceholderText = "Search...",
				PlaceholderColor3 = C.COLOR.TEXT3,
				Text = "",
				TextColor3 = C.COLOR.TEXT,
				Font = C.FONT,
				TextSize = C.TEXT_SM,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 102,
				Parent = dropdown,
			})
			corner(searchBox, 4)
			scroll.Position = UDim2.new(0, 0, 0, 34)
		end

		local optionFrames = {}
		local function rebuild(filt)
			for _, f in ipairs(optionFrames) do f:Destroy() end
			optionFrames = {}
			filt = filt and filt:lower()
			local filtered = {}
			for _, opt in ipairs(options) do
				local sop = tostring(opt)
				if not filt or sop:lower():find(filt, 1, true) then
					table.insert(filtered, opt)
				end
			end
			for i, opt in ipairs(filtered) do
				local isSel = multi and (function() for _, s in ipairs(selected) do if s == opt then return true end end end)() or (selected == opt)
				local of = make("TextButton", {
					Size = UDim2.new(1, 0, 0, 30),
					BackgroundColor3 = isSel and C.COLOR.ACCENT or C.COLOR.BG2,
					BackgroundTransparency = 0,
					BorderSizePixel = 0,
					Text = tostring(opt),
					TextColor3 = isSel and C.COLOR.WHITE or C.COLOR.TEXT,
					Font = C.FONT,
					TextSize = C.TEXT_SM,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					AutoButtonColor = false,
					ZIndex = 101,
					Parent = scroll,
				})
				padding(of, 10, 0, 0, 0)
				of.MouseEnter:Connect(function()
					if not isSel then Anim.tween(of, { BackgroundColor3 = C.COLOR.BG4 }, C.ANIM.FAST) end
				end)
				of.MouseLeave:Connect(function()
					if not isSel then Anim.tween(of, { BackgroundColor3 = C.COLOR.BG2 }, C.ANIM.FAST) end
				end)
				local function isOptionSelected() return multi and (function() for _, s in ipairs(selected) do if s == opt then return true end end end)() or (selected == opt) end
				of.MouseButton1Click:Connect(function()
					if multi then
						local found = false
						for j, s in ipairs(selected) do if s == opt then table.remove(selected, j); found = true; break end end
						if not found then table.insert(selected, opt) end
					else
						selected = (selected == opt) and "" or opt
						dropdown.Visible = false
						arrow.Text = "v"
						trigger.Text = getDisplayText()
						if callback then callback(multi and selected or selected) end
					end
					trigger.Text = getDisplayText()
					rebuild(searchBox and searchBox.Text or nil)
					if callback then callback(multi and selected or selected) end
				end)
				table.insert(optionFrames, of)
			end
			scroll.CanvasSize = UDim2.new(0, 0, 0, #filtered * 30)
		end

		rebuild()

		local open = false
		trigger.MouseButton1Click:Connect(function()
			open = not open
			if open then
				rebuild()
				dropdown.Visible = true
				local h = math.min(#optionFrames * 30 + (searchable and 38 or 6), 240)
				dropdown.Size = UDim2.new(1, -104, 0, 0)
				Anim.tween(dropdown, { Size = UDim2.new(1, -104, 0, h) }, C.ANIM.FAST)
				Anim.tween(arrow, { Rotation = 180 }, C.ANIM.FAST)
			else
				Anim.tween(dropdown, { Size = UDim2.new(1, -104, 0, 0) }, C.ANIM.FAST)
				Anim.tween(arrow, { Rotation = 0 }, C.ANIM.FAST)
				task.wait(C.ANIM.FAST + 0.02)
				dropdown.Visible = false
			end
		end)

		trigger.MouseEnter:Connect(function()
			Anim.tween(trigger, { BackgroundColor3 = C.COLOR.BG4 }, C.ANIM.FAST)
		end)
		trigger.MouseLeave:Connect(function()
			if not open then Anim.tween(trigger, { BackgroundColor3 = C.COLOR.BG3 }, C.ANIM.FAST) end
		end)

		local gio = make("Frame", {
			Size = UDim2.new(0, 0, 0, 0),
			Position = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 1,
			Visible = false,
			ZIndex = 99,
			Parent = parent,
		})
		gio.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 and open then
				if not (input.Position.X >= dropdown.AbsolutePosition.X and input.Position.X <= dropdown.AbsolutePosition.X + dropdown.AbsoluteSize.X and input.Position.Y >= dropdown.AbsolutePosition.Y and input.Position.Y <= dropdown.AbsolutePosition.Y + dropdown.AbsoluteSize.Y) then
					open = false
					Anim.tween(dropdown, { Size = UDim2.new(1, -104, 0, 0) }, C.ANIM.FAST)
					Anim.tween(arrow, { Rotation = 0 }, C.ANIM.FAST)
					task.wait(C.ANIM.FAST + 0.02)
					dropdown.Visible = false
					if multi and callback then callback(selected) end
				end
			end
		end)

		if searchBox then
			searchBox:GetPropertyChangedSignal("Text"):Connect(function()
				rebuild(searchBox.Text)
			end)
		end

		local control = {
			_raw = group,
			Set = function(_, v)
				if type(v) == "table" then
					if v.Options or v.Values then
						options = v.Options or v.Values or options
						rebuild(searchBox and searchBox.Text or nil)
					end
					local p = v.CurrentOption or v.CurrentOptions
					if p ~= nil then
						if multi then selected = type(p) == "table" and p or { tostring(p) }
						else selected = tostring(p) end
						trigger.Text = getDisplayText()
						rebuild(searchBox and searchBox.Text or nil)
					end
				end
			end,
			SetValue = function(_, v)
				if v ~= nil then
					if multi then selected = type(v) == "table" and v or { tostring(v) }
					else selected = tostring(v) end
					trigger.Text = getDisplayText()
					rebuild(searchBox and searchBox.Text or nil)
				end
			end,
			Refresh = function(_, newOpts)
				options = type(newOpts) == "table" and newOpts or options
				rebuild(searchBox and searchBox.Text or nil)
			end,
			GetValue = function() return multi and selected or selected end,
			Container = group,
		}
		return control
	end

	-- ==================== GROUP (Card) ====================
	local function createGroup(parent, title, column)
		local w = parent._columnWidth or 340
		local card = make("Frame", {
			Size = UDim2.new(0, w, 0, 0),
			BackgroundColor3 = C.COLOR.BG2,
			BorderSizePixel = 0,
			AutomaticSize = Enum.AutomaticSize.Y,
			Parent = parent,
		})
		corner(card, C.GROUP.RADIUS)
		stroke(card, C.COLOR.BORDER, 1, 0.5)

		make("Frame", {
			Size = UDim2.new(1, 0, 0, 3),
			BackgroundColor3 = C.COLOR.ACCENT,
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = card,
		})
		corner(make("Frame", { Size = UDim2.new(1, 0, 0, 3), BackgroundColor3 = C.COLOR.ACCENT, BorderSizePixel = 0, ZIndex = 2, Parent = card }), C.GROUP.RADIUS)

		local titleBar = make("Frame", {
			Size = UDim2.new(1, 0, 0, C.GROUP.TITLE_H),
			BackgroundColor3 = C.COLOR.BG3,
			BorderSizePixel = 0,
			Parent = card,
		})

		local titleLbl = make("TextLabel", {
			Size = UDim2.new(1, -C.GROUP.PADDING * 2, 1, 0),
			Position = UDim2.new(0, C.GROUP.PADDING, 0, 0),
			BackgroundTransparency = 1,
			Text = tostring(title or "Group"),
			TextColor3 = C.COLOR.TEXT,
			Font = C.FONT_BOLD,
			TextSize = C.TEXT_TITLE,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			Parent = titleBar,
		})

		local content = make("Frame", {
			Size = UDim2.new(1, 0, 0, 0),
			Position = UDim2.new(0, 0, 0, C.GROUP.TITLE_H + C.GROUP.GAP),
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			Parent = card,
		})
		padding(content, C.GROUP.PADDING, C.GROUP.PADDING, 0, C.GROUP.PADDING)

		local contentList = make("UIListLayout", {
			Padding = UDim.new(0, C.CONTROL.GAP),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = content,
		})

		local s = 0
		local function ni(n, e) s = s + 1; return e or (Core and Core.uiElementId and Core.uiElementId(n) or tostring(n):gsub("[^%w]","_")) .. "_" .. s end

		local groupObj = {
			_raw = card,
			_content = content,
			_titleLbl = titleLbl,
			_titleBar = titleBar,
			AddLabel = function(self, text)
				local lbl = createLabel(content, text)
				STATE.controls = STATE.controls + 1
				return lbl
			end,
			CreateLabel = function(self, st)
				local t = type(st) == "table" and (st.Name or st.Text) or tostring(st)
				local lbl = createLabel(content, t)
				STATE.controls = STATE.controls + 1
				return lbl
			end,
			AddToggle = function(self, flag, params)
				params = params or {}
				local ct = createToggle(content, params.Text or flag, params.Default, params.Callback)
				STATE.controls = STATE.controls + 1
				return ct
			end,
			AddSlider = function(self, flag, params)
				params = params or {}
				local ct = createSlider(content, params.Text or flag, params.Min or 0, params.Max or 100, params.Default or params.Min or 0, params.Callback, params.Suffix, params.Rounding or 1)
				STATE.controls = STATE.controls + 1
				return ct
			end,
			AddButton = function(self, params)
				params = params or {}
				local ct = createButton(content, params.Text or "Button", params.Func or function() end)
				STATE.controls = STATE.controls + 1
				return ct
			end,
			AddInput = function(self, flag, params)
				params = params or {}
				local ct = createInput(content, params.Text or flag, params.Default or "", params.Placeholder or "Enter...", params.Callback)
				STATE.controls = STATE.controls + 1
				return ct
			end,
			AddDropdown = function(self, flag, params)
				params = params or {}
				local ct = createDropdown(content, params.Text or flag, params.Values or {}, params.Default, params.Callback, params.Multi, params.Searchable)
				STATE.controls = STATE.controls + 1
				return ct
			end,
			AddDivider = function(self)
				createDivider(content)
				STATE.controls = STATE.controls + 1
				return {}
			end,
		}
		return groupObj
	end

	-- ==================== TAB (Content Panel) ====================
	local function createTab(window, name, iconId, columns)
		columns = math.max(1, math.min(3, tonumber(columns) or 2))
		local contentArea = window._contentArea
		local contentW = contentArea.AbsoluteSize.X - C.GROUP.PADDING * 2

		local panel = make("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Visible = false,
			Parent = contentArea,
		})

		local scroll = make("ScrollingFrame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = C.COLOR.SCROLLBAR,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			Parent = panel,
		})
		padding(scroll, C.GROUP.PADDING, C.GROUP.PADDING, C.GROUP.PADDING, C.GROUP.PADDING)

		local colWidth = (contentW - C.GROUP.GAP * (columns - 1) - C.GROUP.PADDING * 2) / columns
		colWidth = math.max(200, colWidth)

		local columnsFrames = {}
		local columnsLists = {}
		for i = 1, columns do
			local cf = make("Frame", {
				Size = UDim2.new(0, colWidth, 0, 0),
				Position = UDim2.new(0, (i - 1) * (colWidth + C.GROUP.GAP), 0, 0),
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.Y,
				Parent = scroll,
			})
			local cl = make("UIListLayout", {
				Padding = UDim.new(0, C.GROUP.GAP),
				SortOrder = Enum.SortOrder.LayoutOrder,
				Parent = cf,
			})
			columnsFrames[i] = cf
			columnsLists[i] = cl
		end

		local tabObj = {
			_panel = panel,
			_scroll = scroll,
			_columns = columns,
			_colFrames = columnsFrames,
			_colLists = columnsLists,
			_columnWidth = colWidth,
			_window = window,
			AddLeftGroupbox = function(self, groupName)
				if not columnsFrames[1] then return nil end
				return createGroup(columnsFrames[1], groupName, 1)
			end,
			AddRightGroupbox = function(self, groupName)
				if not columnsFrames[2] then return nil end
				return createGroup(columnsFrames[2], groupName, 2)
			end,
			AddGroupbox = function(self, groupName)
				return self:AddLeftGroupbox(groupName)
			end,
			Select = function(self)
				window:selectTab(self)
			end,
		}
		return tabObj
	end

	-- ==================== WINDOW ====================
	local function createWindow(settings)
		settings = settings or {}
		STATE.windowCount = STATE.windowCount + 1

		local screen = make("ScreenGui", {
			Name = "AlleralUI_" .. STATE.windowCount,
			ResetOnSpawn = false,
			ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
			DisplayOrder = 100,
		})

		local bg = make("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = C.COLOR.BLACK,
			BackgroundTransparency = 0.4,
			Visible = true,
			ZIndex = 0,
			Parent = screen,
		})

		local winSize = settings.Size or UDim2.fromOffset(C.WINDOW.W, C.WINDOW.H)
		if settings.Center ~= false then
			screen.Parent = CoreGui
		else
			screen.Parent = CoreGui:FindFirstChild("RobloxGui") or CoreGui
		end

		local main = make("Frame", {
			Size = winSize,
			Position = UDim2.new(0.5, -winSize.X.Offset / 2, 0.5, -winSize.Y.Offset / 2),
			BackgroundColor3 = C.COLOR.BG1,
			BorderSizePixel = 0,
			ZIndex = 1,
			Parent = screen,
		})
		corner(main, C.WINDOW.RADIUS)
		stroke(main, C.COLOR.BORDER, 1.5, 0.4)

		local shadow = make("Frame", {
			Size = UDim2.new(1, 20, 1, 20),
			Position = UDim2.new(0, -10, 0, -10),
			BackgroundColor3 = C.COLOR.BLACK,
			BackgroundTransparency = 0.7,
			BorderSizePixel = 0,
			ZIndex = 0,
			Parent = main,
		})
		corner(shadow, C.WINDOW.RADIUS + 4)

		local header = make("Frame", {
			Size = UDim2.new(1, 0, 0, 44),
			BackgroundColor3 = C.COLOR.BG0,
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = main,
		})
		corner(header, C.WINDOW.RADIUS)
		local headerBottom = make("Frame", { Size = UDim2.new(1, 0, 0, 0), Position = UDim2.new(0, 0, 1, 0), BackgroundTransparency = 1, Parent = header })
		corner(headerBottom, C.WINDOW.RADIUS)

		local headerTitle = make("TextLabel", {
			Size = UDim2.new(0, 0, 1, 0),
			Position = UDim2.new(0, 14, 0, 0),
			BackgroundTransparency = 1,
			Text = "Alleral",
			TextColor3 = C.COLOR.TEXT,
			Font = C.FONT_BOLD,
			TextSize = C.TEXT_HEADER,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Center,
			AutomaticSize = Enum.AutomaticSize.X,
			ZIndex = 3,
			Parent = header,
		})

		local verBadge = make("Frame", {
			Size = UDim2.new(0, 50, 0, 18),
			Position = UDim2.new(0, 0, 0.5, -9),
			BackgroundColor3 = C.COLOR.ACCENT,
			BorderSizePixel = 0,
			ZIndex = 3,
			Parent = header,
		})
		corner(verBadge, 4)
		local verText = make("TextLabel", {
			Size = UDim2.new(1, -6, 1, 0),
			Position = UDim2.new(0, 3, 0, 0),
			BackgroundTransparency = 1,
			Text = C.VERSION,
			TextColor3 = C.COLOR.WHITE,
			Font = C.FONT_BOLD,
			TextSize = 10,
			ZIndex = 3,
			Parent = verBadge,
		})

		local closeBtn = make("TextButton", {
			Size = UDim2.new(0, 28, 0, 28),
			Position = UDim2.new(1, -34, 0, 8),
			BackgroundColor3 = C.COLOR.BG0,
			BorderSizePixel = 0,
			Text = "x",
			TextColor3 = C.COLOR.TEXT2,
			Font = C.FONT,
			TextSize = 16,
			AutoButtonColor = false,
			ZIndex = 3,
			Parent = header,
		})
		corner(closeBtn, 6)
		closeBtn.MouseEnter:Connect(function()
			Anim.tween(closeBtn, { BackgroundColor3 = C.COLOR.RED_DARK, TextColor3 = C.COLOR.WHITE }, C.ANIM.FAST)
		end)
		closeBtn.MouseLeave:Connect(function()
			Anim.tween(closeBtn, { BackgroundColor3 = C.COLOR.BG0, TextColor3 = C.COLOR.TEXT2 }, C.ANIM.FAST)
		end)
		closeBtn.MouseButton1Click:Connect(function()
			pcall(function()
				Anim.tween(main, { Size = UDim2.new(0, 0, 0, 0) }, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				task.wait(0.22)
				screen:Destroy()
			end)
		end)

		-- Sidebar
		local sidebar = make("Frame", {
			Size = UDim2.new(0, C.SIDEBAR.W, 1, -44),
			Position = UDim2.new(0, 0, 0, 44),
			BackgroundColor3 = C.COLOR.BG0,
			BorderSizePixel = 0,
			ZIndex = 1,
			Parent = main,
		})

		local sidebarList = make("UIListLayout", {
			Padding = UDim.new(0, 2),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = sidebar,
		})
		padding(sidebar, 6, 6, 6, 6)

		-- Content area
		local contentArea = make("Frame", {
			Size = UDim2.new(1, -C.SIDEBAR.W, 1, -44),
			Position = UDim2.new(0, C.SIDEBAR.W, 0, 44),
			BackgroundColor3 = C.COLOR.BG1,
			BorderSizePixel = 0,
			ZIndex = 0,
			Parent = main,
		})

		local tabs = {}
		local activeTab = nil

		local function selectTab(tab)
			if activeTab == tab then return end
			if activeTab then
				activeTab._panel.Visible = false
				if activeTab._sidebarBtn then
					Anim.tween(activeTab._sidebarBtn, { BackgroundColor3 = C.COLOR.BG0 }, C.ANIM.FAST)
					if activeTab._sidebarLabel then
						Anim.tween(activeTab._sidebarLabel, { TextColor3 = C.COLOR.TEXT2 }, C.ANIM.FAST)
					end
				end
			end
			tab._panel.Visible = true
			Anim.fadeIn(tab._panel, C.ANIM.FAST)
			if tab._sidebarBtn then
				Anim.tween(tab._sidebarBtn, { BackgroundColor3 = C.COLOR.ACCENT }, C.ANIM.FAST)
				Anim.tween(tab._sidebarBtn:FindFirstChild("Accent") or make("Frame", { Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = C.COLOR.ACCENT_LIGHT, BorderSizePixel = 0, ZIndex = 4, Parent = tab._sidebarBtn }), {}, C.ANIM.FAST)
				if tab._sidebarLabel then
					Anim.tween(tab._sidebarLabel, { TextColor3 = C.COLOR.WHITE }, C.ANIM.FAST)
				end
			end
			activeTab = tab
		end

		local window = {
			_main = main,
			_header = header,
			_headerTitle = headerTitle,
			_sidebar = sidebar,
			_contentArea = contentArea,
			_screen = screen,
			_tabs = tabs,
			_activeTab = nil,
			selectTab = selectTab,
		}

		function window:AddTab(name, iconId)
			local tabObj = createTab(self, name, iconId, 2)

			local sidebarBtn = make("TextButton", {
				Size = UDim2.new(1, 0, 0, C.SIDEBAR.ITEM_H),
				BackgroundColor3 = C.COLOR.BG0,
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = false,
				ZIndex = 2,
				Parent = sidebar,
			})
			corner(sidebarBtn, C.SIDEBAR.RADIUS)

			local accentBar = make("Frame", {
				Size = UDim2.new(0, 0, 1, -8),
				Position = UDim2.new(0, 0, 0, 4),
				BackgroundColor3 = C.COLOR.ACCENT,
				BorderSizePixel = 0,
				ZIndex = 4,
				Parent = sidebarBtn,
			})

			local icon
			if iconId then
				icon = make("ImageLabel", {
					Size = UDim2.new(0, C.SIDEBAR.ICON_SIZE, 0, C.SIDEBAR.ICON_SIZE),
					Position = UDim2.new(0, 10, 0.5, -C.SIDEBAR.ICON_SIZE / 2),
					BackgroundTransparency = 1,
					Image = type(iconId) == "number" and ("rbxassetid://" .. iconId) or iconId,
					ZIndex = 3,
					Parent = sidebarBtn,
				})
			end

			local sidebarLabel = make("TextLabel", {
				Size = UDim2.new(1, -(icon and C.SIDEBAR.ICON_SIZE + 20 or 14), 1, 0),
				Position = UDim2.new(0, icon and C.SIDEBAR.ICON_SIZE + 16 or 10, 0, 0),
				BackgroundTransparency = 1,
				Text = tostring(name),
				TextColor3 = C.COLOR.TEXT2,
				Font = C.FONT,
				TextSize = C.TEXT,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Center,
				TextTruncate = Enum.TextTruncate.AtEnd,
				ZIndex = 3,
				Parent = sidebarBtn,
			})

			tabObj._sidebarBtn = sidebarBtn
			tabObj._sidebarLabel = sidebarLabel
			tabObj._accentBar = accentBar

			sidebarBtn.MouseEnter:Connect(function()
				if activeTab ~= tabObj then
					Anim.tween(sidebarBtn, { BackgroundColor3 = C.COLOR.BG3 }, C.ANIM.FAST)
					Anim.tween(sidebarLabel, { TextColor3 = C.COLOR.TEXT }, C.ANIM.FAST)
				end
			end)
			sidebarBtn.MouseLeave:Connect(function()
				if activeTab ~= tabObj then
					Anim.tween(sidebarBtn, { BackgroundColor3 = C.COLOR.BG0 }, C.ANIM.FAST)
					Anim.tween(sidebarLabel, { TextColor3 = C.COLOR.TEXT2 }, C.ANIM.FAST)
				end
			end)
			sidebarBtn.MouseButton1Click:Connect(function()
				selectTab(tabObj)
			end)

			table.insert(tabs, tabObj)
			STATE.tabCount = STATE.tabCount + 1

			if #tabs == 1 then
				task.wait(0.05)
				selectTab(tabObj)
			end

			return tabObj
		end

		function window:Destroy()
			Anim.stopAll()
			screen:Destroy()
		end

		-- Spring-in entrance
		Anim.springIn(main)

		return window
	end

	-- ==================== NOTIFICATION SYSTEM ====================
	local function initNotifContainer()
		if STATE.notifContainer and STATE.notifContainer.Parent then return STATE.notifContainer end
		local sg = make("ScreenGui", { Name = "AlleralNotifs", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999 })
		local c = make("Frame", {
			Name = "NotifContainer", AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -16, 0.5, 0), Size = UDim2.new(0, 280, 1, -60),
			BackgroundTransparency = 1, Parent = sg,
		})
		make("UIListLayout", { Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Right, VerticalAlignment = Enum.VerticalAlignment.Bottom, SortOrder = Enum.SortOrder.LayoutOrder, Parent = c })
		sg.Parent = CoreGui:FindFirstChild("RobloxGui") or CoreGui
		STATE.notifContainer = c
		return c
	end

	local function showNotification(text, duration)
		duration = duration or 4
		STATE.notifIdx = STATE.notifIdx + 1
		local cont = initNotifContainer()

		local frame = make("Frame", {
			Name = "N_" .. STATE.notifIdx, Size = UDim2.new(1, -4, 0, 0),
			BackgroundColor3 = C.COLOR.BG2, BorderSizePixel = 0,
			ClipsDescendants = false, LayoutOrder = STATE.notifIdx, Parent = cont,
		})
		corner(frame, 8)
		stroke(frame, C.COLOR.BORDER, 1, 0.5)

		local accent = make("Frame", { Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = C.COLOR.ACCENT, BorderSizePixel = 0, Parent = frame })

		local lbl = make("TextLabel", {
			Size = UDim2.new(1, -14, 1, -12), Position = UDim2.new(0, 10, 0, 6),
			BackgroundTransparency = 1, Text = tostring(text), TextColor3 = C.COLOR.TEXT,
			Font = C.FONT, TextSize = C.TEXT_SM + 1,
			TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
			Parent = frame,
		})

		padding(frame, 0, 0, 6, 6)

		task.wait(0.02)
		local h = math.max(lbl.TextBounds.Y + 18, 42)
		Anim.tween(frame, { Size = UDim2.new(1, -4, 0, h), BackgroundTransparency = 0 }, C.ANIM.NORM)
		Anim.slideX(frame, UDim2.new(0, 0, 0, 0), C.ANIM.NORM)

		local allFrames = {}
		for _, ch in ipairs(cont:GetChildren()) do if ch:IsA("Frame") and ch.Name:find("N_") then table.insert(allFrames, ch) end end
		table.sort(allFrames, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
		while #allFrames > 6 do
			local oldest = allFrames[1]
			table.remove(allFrames, 1)
			Anim.tween(oldest, { Size = UDim2.new(1, -4, 0, 0), BackgroundTransparency = 1 }, C.ANIM.NORM)
			task.delay(C.ANIM.NORM + 0.05, function() pcall(function() oldest:Destroy() end) end)
		end

		frame.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				Anim.tween(frame, { Size = UDim2.new(1, -4, 0, 0), BackgroundTransparency = 1 }, C.ANIM.FAST)
				task.delay(C.ANIM.FAST + 0.05, function() pcall(function() frame:Destroy() end) end)
			end
		end)

		task.delay(duration, function()
			if frame and frame.Parent then
				Anim.tween(frame, { Size = UDim2.new(1, -4, 0, 0), BackgroundTransparency = 1 }, C.ANIM.NORM)
				task.delay(C.ANIM.NORM + 0.05, function() pcall(function() frame:Destroy() end) end)
			end
		end)

		return frame
	end

	-- ==================== LIBRARY (Top-Level API) ====================
	local Library = { Version = C.VERSION }

	function Library:GetLayoutInfo()
		return { profile = "noble", engine = "Alleral Noble", version = C.VERSION }
	end

	function Library:CreateWindow(settings)
		settings = deepClone(type(settings) == "table" and settings or {})
		local title = settings.Title or settings.Name or "Alleral"

		local win = createWindow(settings)
		local window = {
			_win = win, _library = Library, _tabs = {}, _title = title, _settings = settings,
		}

		function window:AddTab(name, icon)
			local t = win:AddTab(name, icon)
			if t then table.insert(window._tabs, t) end
			return t, window
		end

		function window:Notify(p)
			p = type(p) == "table" and p or {}
			local txt, dur = "", 4
			if type(p) == "string" then txt = p
			else txt = textOf(p.Title or p.Name or p) .. "\n" .. textOf(p.Description or p.Content or p.Text or "")
			dur = tonumber(p.Duration or p.Lifetime or 4) end
			showNotification(txt, dur)
		end

		function window:Unload()
			pcall(function() win:Destroy() end)
		end

		ENV.Alleral_UiWindow = window
		return window
	end

	function Library:Notification(info)
		local txt, dur = "", 4
		if type(info) == "string" then txt = info
		elseif type(info) == "table" then
			local tl = textOf(info.Title or info.Name or "")
			local bd = textOf(info.Description or info.Content or info.Text or "")
			txt = (tl ~= "" and bd ~= "" and (tl .. "\n" .. bd)) or tl or bd
			dur = tonumber(info.Duration or info.Lifetime or info.Time or 4)
		else txt = textOf(info) end
		return showNotification(txt, math.max(1, dur))
	end

	function Library:Notify(text, dur)
		if type(text) == "table" then Library:Notification(text)
		else Library:Notification({ Description = text, Duration = dur }) end
	end

	function Library:ClearNotifications()
		if STATE.notifContainer then
			for _, ch in ipairs(STATE.notifContainer:GetChildren()) do
				if ch:IsA("Frame") and ch.Name:find("N_") then ch:Destroy() end
			end
		end
	end

	-- ==================== CORE API FUNCTIONS ====================
	function Core.loadUi()
		local cached = ENV.Alleral_UI
		if type(cached) == "table" and type(cached.Library) == "table" then return cached end

		local b = {
			Library = Library, Alleral = Library,
			CreateWindow = function(_, s) return Library:CreateWindow(s) end,
			Notify = function(_, t, d) Library:Notify(t, d) end,
			ClearNotifications = function() Library:ClearNotifications() end,
		}
		ENV.Alleral_UI = b
		if getgenv then getgenv().Alleral_UI = b end
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
			Theme = extra.Theme or "Noble",
			Size = extra.Size or UDim2.fromOffset(C.WINDOW.W, C.WINDOW.H),
			TabWidth = tonumber(extra.TabWidth) or C.SIDEBAR.W,
			FileSettings = {
				RootFolder = extra.configFolder or "Alleral_Configs",
				ConfigFolder = extra.FileName or "Interface",
			},
		}
	end

	-- ==================== GROUPBOX CREATION ====================
	local function createGroupbox(section, uiBundle)
		section = type(section) == "table" and section or {}
		local s = 0
		local function ni(n, e) s = s + 1; return e or (Core and Core.uiElementId and Core.uiElementId(n) or tostring(n):gsub("[^%w]", "_")) .. "_" .. s end
		local function wc(as, m)
			m = type(m) == "table" and m or {}; local w = { _raw = m.raw }
			function w:Set(v) if type(v) == "table" then as(v) else as({ CurrentValue = v }) end end
			if m.bindKey and Core.bindUiState then Core.bindUiState(m.bindKey, w, m.kind or "toggle", m.raw) end
			return w
		end

		local gb = {}
		function gb:CreateSection(n) return gb end

		function gb:AddLabel(t)
			if not section or type(section.AddLabel) ~= "function" then return { SetText = function() end, Set = function() end, Visible = true } end
			return sc("AddLabel", function() return section:AddLabel(textOf(t)) end) or { SetText = function() end, Set = function() end, Visible = true }
		end

		function gb:CreateLabel(st, id)
			local t = type(st) == "table" and (st.Name or st.Text) or tostring(st or "")
			local r = sc("Label", function() return section:AddLabel(t) end)
			STATE.controls = STATE.controls + 1
			return { Set = function(_, ns) if not r then return end; local nt = type(ns) == "table" and (ns.Name or ns.Text) or tostring(ns or ""); r.SetText(nil, nt) end, SetText = function(_, tv) if r then r.SetText(nil, textOf(tv)) end end, SetVisible = function(_, v) if r then r.SetVisible(nil, v == true) end end }
		end

		function gb:CreateToggle(st, id)
			local cv = st.Default or st.CurrentValue or st.Value; local fl = ni(st.Name, id)
			local r = sc("Toggle:" .. tostring(st.Name), function()
				return section:AddToggle(fl, { Text = st.Name or st.Title or "Toggle", Default = cv == true, Callback = st.Callback or function() end })
			end)
			STATE.controls = STATE.controls + 1; if not r then table.insert(STATE.missingBindings, "Toggle:" .. tostring(st.Name)) end
			return wc(function(n) if not r then return end; local v = n.CurrentValue or n.Value; if v == nil then v = n end; r.SetValue(nil, v == true) end, { raw = r, bindKey = st.BindKey or st.StateKey, kind = "toggle" })
		end

		function gb:CreateButton(st, id)
			local nm = st.Name or st.Title or st.Text or "Button"
			local r = sc("Button:" .. nm, function() return section:AddButton({ Text = nm, Func = st.Callback or function() end }) end)
			STATE.controls = STATE.controls + 1; if not r then table.insert(STATE.missingBindings, "Button:" .. nm) end
			return wc(function() end, { raw = r, kind = "button" })
		end

		function gb:CreateSlider(st, id)
			local rn = st.Range or { 0, 100 }; local fl = ni(st.Name, id)
			local cv = tonumber(st.Default) or tonumber(st.CurrentValue) or tonumber(st.Value) or rn[1]
			local r = sc("Slider:" .. tostring(st.Name), function()
				return section:AddSlider(fl, { Text = st.Name or st.Title or "Slider", Default = cv, Min = rn[1] or 0, Max = rn[2] or 100, Suffix = st.Suffix or "", Rounding = tonumber(st.Increment) or 1, Callback = st.Callback or function() end })
			end)
			STATE.controls = STATE.controls + 1; if not r then table.insert(STATE.missingBindings, "Slider:" .. tostring(st.Name)) end
			return wc(function(n) if not r then return end; local v = tonumber(n.CurrentValue) or tonumber(n.Value) or tonumber(n); r.SetValue(nil, v) end, { raw = r, bindKey = st.BindKey or st.StateKey, kind = "slider" })
		end

		function gb:CreateInput(st, id)
			local fl = ni(st.Name, id); local cv = tostring(st.CurrentValue or st.Default or st.Value or "")
			local r = sc("Input:" .. tostring(st.Name), function()
				return section:AddInput(fl, { Text = st.Name or st.Title or "Input", Default = cv, Placeholder = st.PlaceholderText or st.Placeholder or "Enter...", Callback = st.Callback or function() end })
			end)
			STATE.controls = STATE.controls + 1; if not r then table.insert(STATE.missingBindings, "Input:" .. tostring(st.Name)) end
			return wc(function(n) if not r then return end; r.SetValue(nil, tostring(n.CurrentValue or n.Value or "")) end, { raw = r, bindKey = st.BindKey or st.StateKey, kind = "input" })
		end

		function gb:CreateDropdown(st, id)
			local op = st.Options or st.Values or {}; local mu = st.MultipleOptions == true or st.Multi == true
			local cu = st.CurrentOption or (mu and {} or (op[1] or "")); local fl = ni(st.Name, id)
			local r = sc("Dropdown:" .. tostring(st.Name), function()
				return section:AddDropdown(fl, { Text = st.Name or st.Title or "Dropdown", Values = op, Default = mu and (type(cu) == "table" and cu[1] or cu) or (type(cu) == "table" and cu[1] or cu or op[1] or ""), Multi = mu, Callback = function(sel) local cb = st.Callback or function() end; if mu then cb(Core.normalizeMultiSelection and Core.normalizeMultiSelection(sel) or sel) else cb(Core.normalizeDropdownValue and Core.normalizeDropdownValue(sel, op[1]) or sel) end end })
			end)
			STATE.controls = STATE.controls + 1; if not r then table.insert(STATE.missingBindings, "Dropdown:" .. tostring(st.Name)) end
			return wc(function(n) if not r then return end; local nv = n.Options or n.Values; if type(nv) == "table" and r.Refresh then r.Refresh(nil, nv) end; local p = n.CurrentOption or n.CurrentOptions; if p ~= nil then r.SetValue(nil, tostring(p)) end end, { raw = r, bindKey = st.BindKey or st.StateKey, kind = "dropdown" })
		end

		function gb:CreateDivider()
			sc("Divider", function() return section:AddDivider() end)
			STATE.controls = STATE.controls + 1; return {}
		end

		function gb:CreateStatus(settings, fields)
			local title, dfs = nil, {}
			if type(settings) == "table" then title = settings.Name or settings.Title or settings.Label or "Status"; dfs = settings.Fields or settings.Values or settings.Items or settings.Stats or settings.Data; if type(dfs) ~= "table" then dfs = { Status = settings.Status or settings.Text or settings.Value or "--" } end
			else title = settings or "Status"; dfs = type(fields) == "table" and fields or { Status = fields or "--" } end
			local st = { Labels = {}, LastValues = {}, Summary = nil }
			if title and textOf(title) ~= "" then st.Title = gb:AddLabel(textOf(title)) end
			for k, v in pairs(dfs) do local r = textOf(v); st.LastValues[k] = r; st.Labels[k] = gb:AddLabel(textOf(k) .. ": " .. r) end
			st.Summary = gb:AddLabel("")
			function st:Update(key, value)
				local r = textOf(value); if self.LastValues[key] == r then return end; self.LastValues[key] = r; local row = self.Labels[key]
				if row and row.SetText then row.SetText(nil, textOf(key) .. ": " .. r) elseif row and row.Set then row.Set(nil, { Name = textOf(key) .. ": " .. r, Text = textOf(key) .. ": " .. r }) end
			end
			function st:SetSummary(text) if self.Summary and self.Summary.SetText then self.Summary.SetText(nil, textOf(text)) elseif self.Summary and self.Summary.Set then self.Summary.Set(nil, { Name = textOf(text), Text = textOf(text) }) end end
			function st:Set(key, value) if type(key) == "table" then for k, v in pairs(key) do self:Update(k, v) end else self:Update(key, value) end end
			return st
		end
		return gb
	end

	function Core.createUiGroupbox(section, uiBundle)
		return createGroupbox(section, uiBundle)
	end

	-- ==================== UI WRAPPERS ====================
	function Core.wrapUiGroup(groupbox, callbackWrapper)
		local group = {}
		function group:CreateToggle(name, def, tip, cb, bk)
			return groupbox:CreateToggle({ Name = name, CurrentValue = def == true, Default = def == true, Tooltip = tip, Callback = cb or function() end, BindKey = bk }, bk)
		end
		function group:CreateSlider(name, mn, mx, def, cb, tip, inc, bk)
			return groupbox:CreateSlider({ Name = name, Range = { mn, mx }, CurrentValue = def or mn, Default = def or mn, Tooltip = tip, Increment = inc, Callback = cb or function() end, BindKey = bk }, bk)
		end
		function group:CreateButton(name, cb, tip)
			return groupbox:CreateButton({ Name = name, Tooltip = tip, Callback = cb or function() end })
		end
		function group:CreateInput(name, ph, a3, a4, a5)
			local icon, def, cb, tip = nil, "", nil, nil
			if type(a3) == "function" then cb, tip = a3, a4
			elseif type(a4) == "function" then icon, cb, tip = a3, a4, a5
			else
				if type(a3) == "string" or type(a3) == "number" then def = a3 end
				if type(a4) == "function" then cb = a4 end; tip = a5
			end
			return groupbox:CreateInput({ Name = name, PlaceholderText = ph, CurrentValue = def, Default = def, Tooltip = tip, Callback = cb or function() end })
		end
		function group:CreateDropdown(name, op, def, cb, tip, bk)
			return groupbox:CreateDropdown({ Name = name, Options = op, CurrentOption = def, Tooltip = tip, Callback = cb or function() end, BindKey = bk }, bk)
		end
		function group:AddDropdown(id, cfg)
			cfg = type(cfg) == "table" and cfg or {}
			return groupbox:CreateDropdown({ Name = cfg.Text or cfg.Name or id, Options = cfg.Values or cfg.Options or {}, CurrentOption = cfg.Default or cfg.CurrentValue or cfg.CurrentOption, MultipleOptions = cfg.Multi or cfg.MultiSelection, Callback = cfg.Callback or function() end }, id)
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
			settings = settings or {}; local name = settings.Name or settings.Group or "Group"
			STATE.groupCount = STATE.groupCount + 1
			if not rawTab then table.insert(STATE.missingBindings, "Groupbox:" .. name .. "(no tab)"); return {} end
			local h = sc("Groupbox:" .. name, function()
				local col = tonumber(settings.Column) or 1
				if col == 2 and rawTab.AddRightGroupbox then return rawTab:AddRightGroupbox(name)
				elseif rawTab.AddLeftGroupbox then return rawTab:AddLeftGroupbox(name)
				else return rawTab:AddGroupbox(name) end
			end)
			if not h then table.insert(STATE.missingBindings, "Groupbox:" .. name .. "(failed)"); return {} end
			tab._sectionIndex = (tab._sectionIndex or 0) + 1
			return Core.createUiGroupbox(h, uiBundle)
		end

		function tab:Select() if rawTab and rawTab.Select then rawTab:Select() end end

		function tab:BuildThemeGroupbox(column)
			local g = Core.buildUiGroup(tab, "Appearance", column or 1)
			g:CreateLabel("Alleral Noble Engine")
			return g
		end

		return tab
	end

	function Core.buildUiWindow(ui, settings)
		settings = settings or {}; local lib = ui and ui.Library
		if not lib or type(lib.CreateWindow) ~= "function" then return nil end
		local rw = lib:CreateWindow(settings); if not rw then return nil end
		local w = { _rawWindow = rw, _ui = ui, _library = lib, _initialized = false, _tabGroup = rw, _alleralSettings = settings }
		if type(Core.registerUiWindow) == "function" then Core.registerUiWindow(w) end
		if type(Core.flushPendingNotifications) == "function" then Core.flushPendingNotifications() end
		return w
	end

	function Core.buildUiTab(section, name, icon, columns, id)
		local w = type(Core.resolveUiWindow) == "function" and Core.resolveUiWindow(section) or nil
		if type(w) ~= "table" or not w._rawWindow then return Core.wrapUiTab(nil, type(section) == "table" and section._ui or nil, w) end
		local tg = w._tabGroup or w; if not tg or type(tg.AddTab) ~= "function" then return Core.wrapUiTab(nil, w._ui, w) end
		local rt = tg:AddTab(name, icon); STATE.tabCount = STATE.tabCount + 1
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
				pcall(function() if window._defaultTab and window._defaultTab.Select then window._defaultTab:Select() end end)
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

	-- ==================== UTILITY / MAINTENANCE ====================
	function Core.repairUiWindow(w)
		w = w or ENV.Alleral_UiWindow
		return type(w) == "table" and w._rawWindow ~= nil
	end

	function Core.refreshAllTabColumns() return true end

	Core.notifyUi = function(i)
		showNotification(textOf(i), 4)
	end

	Core.releaseAlleralRuntime = function()
		Anim.stopAll()
		ENV._AlleralUiLibrary = nil; ENV._AlleralUI = nil; ENV.Alleral_UiWindow = nil
		if STATE.notifContainer then pcall(function() STATE.notifContainer.Parent:Destroy() end); STATE.notifContainer = nil end
	end

	ENV.AnimatedNotification = showNotification

	log("INFO", "Alleral Noble v" .. C.VERSION .. " — standalone rendering engine initialized")
end

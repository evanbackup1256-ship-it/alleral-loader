-- Alleral Noble V10 — compact desktop notifications
return function(deps)
	local Theme = deps.Theme
	local Util = deps.Util
	local Layout = deps.Layout
	local Janitor = deps.Janitor
	local RunService = game:GetService("RunService")
	local TextService = game:GetService("TextService")

	local NOTIF_TYPES = {
		info = { color = Theme.COLOR.Blue, icon = "i" },
		success = { color = Theme.COLOR.Green, icon = "✓" },
		error = { color = Theme.COLOR.Red, icon = "!" },
		warning = { color = Theme.COLOR.Yellow, icon = "!" },
	}

	local NotificationManager = {}
	NotificationManager.__index = NotificationManager

	local function num(v, fb, label)
		if Layout and Layout.num then return Layout.num(v, fb, label) end
		return tonumber(v) or fb
	end

	function NotificationManager.new(parent)
		assert(typeof(parent) == "Instance" and parent:IsA("ScreenGui"), "NotificationManager.new expects ScreenGui parent")
		local self = setmetatable({}, NotificationManager)
		self._janitor = Janitor.new()
		self._entries = {}
		self._nextId = 0
		self._layoutOrder = 0

		local stack = Util.make("Frame", {
			Name = "NotificationStack",
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -16, 1, -52),
			Size = UDim2.fromOffset(num(Theme.NOTIF.W, 300, "NOTIF.W"), 400),
			BackgroundTransparency = 1,
			ZIndex = 200,
			Parent = parent,
		})
		Util.make("UIListLayout", {
			Padding = UDim.new(0, num(Theme.NOTIF.GAP, 8, "NOTIF.GAP")),
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = stack,
		})
		self._stack = stack
		self._janitor:Add(stack, "Destroy")
		return self
	end

	function NotificationManager:_prune()
		local visible = {}
		for id, entry in pairs(self._entries) do
			if entry.frame and entry.frame.Parent then
				table.insert(visible, { id = id, layoutOrder = entry.layoutOrder })
			else
				self._entries[id] = nil
			end
		end
		table.sort(visible, function(a, b) return a.layoutOrder > b.layoutOrder end)
		while #visible > num(Theme.NOTIF.MAX, 4, "NOTIF.MAX") do
			self:dismiss(visible[#visible].id)
			table.remove(visible, #visible)
		end
	end

	function NotificationManager:dismiss(id)
		local entry = self._entries[id]
		if not entry or entry.dismissing then return end
		entry.dismissing = true
		if entry.tickConn then pcall(function() entry.tickConn:Disconnect() end) end
		local frame = entry.frame
		if not frame or not frame.Parent then self._entries[id] = nil return end
		local scale = Util.scale(frame)
		Util.safeSprTarget(scale, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], { Scale = 0.96 })
		Util.safeSprTarget(frame, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], {
			Position = UDim2.new(0, 40, 0, 0),
			BackgroundTransparency = 1,
		})
		task.delay(0.2, function()
			pcall(function() frame:Destroy() end)
			self._entries[id] = nil
		end)
	end

	function NotificationManager:clear()
		for id in pairs(self._entries) do self:dismiss(id) end
	end

	local function safeText(text, maxLen)
		text = Util.textOf(text)
		text = text:gsub("[%c]", " ")
		maxLen = tonumber(maxLen) or 240
		if #text > maxLen then
			text = string.sub(text, 1, maxLen - 3) .. "..."
		end
		return text
	end

	function NotificationManager:push(title, body, ntype, duration)
		title = safeText(title, 80)
		if title == "" then title = "Notification" end
		body = safeText(body, 240)
		duration = math.max(1, num(duration, 4, "duration"))

		local meta = NOTIF_TYPES[type(ntype) == "string" and ntype:lower() or "info"] or NOTIF_TYPES.info
		self._nextId = self._nextId + 1
		local id = self._nextId
		self._layoutOrder = self._layoutOrder + 1
		self:_prune()

		local notifW = num(Theme.NOTIF.W, 300, "NOTIF.W")
		local bodyBounds = TextService:GetTextSize(body, Theme.TEXT_SM, Theme.FONT, Vector2.new(notifW - 56, 80))
		local frameH = Util.clamp(num(Theme.NOTIF.H, 64, "NOTIF.H") + (body ~= "" and bodyBounds.Y + 4 or 0), 56, 120)

		local frame = Util.make("Frame", {
			Name = "Toast_" .. id,
			Size = UDim2.fromOffset(notifW, frameH),
			BackgroundColor3 = Theme.COLOR.Glass,
			BackgroundTransparency = 0.08,
			BorderSizePixel = 0,
			LayoutOrder = self._layoutOrder,
			Position = UDim2.new(0, 0, 0, 12),
			Parent = self._stack,
			ZIndex = 201,
		})
		Util.corner(frame, Theme.RADIUS.Notification)
		if Layout and Layout.shadow then Layout.shadow(frame, Theme.RADIUS.Notification, 2, 0.7) end
		Util.gradient(frame, Theme.COLOR.Glass, Theme.COLOR.Surface0, 90)

		local scale = Util.scale(frame)
		scale.Scale = 0.97

		Util.make("Frame", {
			Size = UDim2.new(0, 2, 1, -10),
			Position = UDim2.new(0, 0, 0, 5),
			BackgroundColor3 = meta.color,
			BorderSizePixel = 0,
			ZIndex = 202,
			Parent = frame,
		})

		Util.make("TextLabel", {
			Size = UDim2.fromOffset(16, 16),
			Position = UDim2.new(0, 10, 0, 10),
			BackgroundTransparency = 1,
			Text = meta.icon,
			TextColor3 = meta.color,
			Font = Theme.FONT_BOLD,
			TextSize = 12,
			ZIndex = 203,
			Parent = frame,
		})

		Util.make("TextLabel", {
			Size = UDim2.new(1, -70, 0, 16),
			Position = UDim2.new(0, 30, 0, 10),
			BackgroundTransparency = 1,
			Text = title,
			TextColor3 = Theme.COLOR.Text,
			Font = Theme.FONT_BOLD,
			TextSize = Theme.TEXT_SM,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 203,
			Parent = frame,
		})

		if body ~= "" then
			Util.make("TextLabel", {
				Size = UDim2.new(1, -36, 0, bodyBounds.Y),
				Position = UDim2.new(0, 30, 0, 28),
				BackgroundTransparency = 1,
				Text = body,
				TextColor3 = Theme.COLOR.TextMuted,
				Font = Theme.FONT,
				TextSize = Theme.TEXT_SM,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				ZIndex = 203,
				Parent = frame,
			})
		end

		Util.make("TextLabel", {
			Size = UDim2.fromOffset(40, 12),
			Position = UDim2.new(1, -44, 0, 10),
			BackgroundTransparency = 1,
			Text = os.date("%H:%M"),
			TextColor3 = Theme.COLOR.TextDim,
			Font = Theme.FONT,
			TextSize = 9,
			TextXAlignment = Enum.TextXAlignment.Right,
			ZIndex = 203,
			Parent = frame,
		})

		local closeBtn = Util.make("TextButton", {
			Size = UDim2.fromOffset(18, 18),
			Position = UDim2.new(1, -22, 0, 28),
			BackgroundTransparency = 1,
			Text = "×",
			TextColor3 = Theme.COLOR.TextDim,
			Font = Theme.FONT_BOLD,
			TextSize = 14,
			AutoButtonColor = false,
			ZIndex = 204,
			Parent = frame,
		})

		local progress = Util.make("Frame", {
			Size = UDim2.new(1, 0, 0, 2),
			Position = UDim2.new(0, 0, 1, -2),
			BackgroundColor3 = meta.color,
			BackgroundTransparency = 0.3,
			BorderSizePixel = 0,
			ZIndex = 204,
			Parent = frame,
		})

		local entry = { id = id, frame = frame, layoutOrder = self._layoutOrder, paused = false, dismissing = false, elapsed = 0, duration = duration, tickConn = nil }
		self._entries[id] = entry

		Util.safeSprTarget(frame, Theme.SPRING.SMOOTH[1], Theme.SPRING.SMOOTH[2], { Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 0.04 })
		Util.safeSprTarget(scale, Theme.SPRING.BOUNCY[1], Theme.SPRING.BOUNCY[2], { Scale = 1 })

		closeBtn.MouseButton1Click:Connect(function() self:dismiss(id) end)
		frame.MouseEnter:Connect(function() entry.paused = true end)
		frame.MouseLeave:Connect(function() entry.paused = false end)

		entry.tickConn = RunService.RenderStepped:Connect(function(dt)
			if entry.dismissing or not frame.Parent then
				if entry.tickConn then pcall(function() entry.tickConn:Disconnect() end) end
				return
			end
			if not entry.paused then
				entry.elapsed = entry.elapsed + dt
				local pct = Util.clamp(1 - entry.elapsed / entry.duration, 0, 1)
				progress.Size = UDim2.new(pct, 0, 0, 2)
				if entry.elapsed >= entry.duration then self:dismiss(id) end
			end
		end)

		self:_prune()
		return id
	end

	function NotificationManager:Destroy()
		self:clear()
		self._janitor:Destroy()
	end

	return NotificationManager
end
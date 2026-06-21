-- Alleral Noble V10 — bottom-right notification stack (glass toasts, spring motion)
return function(deps)
	local Theme = deps.Theme
	local Spr = deps.Spr
	local Util = deps.Util
	local Janitor = deps.Janitor

	local RunService = game:GetService("RunService")
	local TextService = game:GetService("TextService")

	local NOTIF_TYPES = {
		info = { color = Theme.COLOR.BLUE, icon = "i" },
		success = { color = Theme.COLOR.GREEN, icon = "✓" },
		error = { color = Theme.COLOR.RED, icon = "!" },
		warning = { color = Theme.COLOR.YELLOW, icon = "!" },
	}

	local NotificationManager = {}
	NotificationManager.__index = NotificationManager

	local function resolveType(ntype)
		ntype = type(ntype) == "string" and ntype:lower() or "info"
		return NOTIF_TYPES[ntype] or NOTIF_TYPES.info
	end

	local function sortByOrder(entries)
		table.sort(entries, function(a, b)
			return (a.layoutOrder or 0) > (b.layoutOrder or 0)
		end)
	end

	function NotificationManager.new(parent)
		assert(typeof(parent) == "Instance" and parent:IsA("ScreenGui"), "NotificationManager.new expects ScreenGui parent")

		local self = setmetatable({}, NotificationManager)
		self._janitor = Janitor.new()
		self._parent = parent
		self._entries = {}
		self._nextId = 0
		self._layoutOrder = 0

		local stack = Util.make("Frame", {
			Name = "NotificationStack",
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -20, 1, -68),
			Size = UDim2.new(0, Theme.NOTIF.W, 0, 520),
			BackgroundTransparency = 1,
			ClipsDescendants = false,
			Parent = parent,
			ZIndex = 200,
		})

		local list = Util.make("UIListLayout", {
			Padding = UDim.new(0, Theme.NOTIF.GAP),
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = stack,
		})

		self._stack = stack
		self._list = list
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
		sortByOrder(visible)
		while #visible > Theme.NOTIF.MAX do
			local oldest = visible[#visible]
			self:dismiss(oldest.id)
			table.remove(visible, #visible)
		end
	end

	function NotificationManager:_reflow()
		for _, entry in pairs(self._entries) do
			if entry.frame and entry.frame.Parent then
				Util.safeSprTarget(entry.frame, Theme.SPRING.SMOOTH[1], Theme.SPRING.SMOOTH[2], {
					Position = UDim2.new(0, 0, 0, 0),
				})
			end
		end
	end

	function NotificationManager:dismiss(id)
		local entry = self._entries[id]
		if not entry or entry.dismissing then return end
		entry.dismissing = true

		if entry.tickConn then
			pcall(function() entry.tickConn:Disconnect() end)
			entry.tickConn = nil
		end

		local frame = entry.frame
		if not frame or not frame.Parent then
			self._entries[id] = nil
			return
		end

		local scale = Util.scale(frame)
		Util.safeSprTarget(scale, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], { Scale = 0.92 })
		Util.safeSprTarget(frame, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], {
			Position = UDim2.new(0, 56, 0, 0),
			BackgroundTransparency = 1,
		})

		for _, child in ipairs(frame:GetDescendants()) do
			if child:IsA("GuiObject") then
				local props = {}
				if child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox") then
					props.TextTransparency = 1
				end
				if child.BackgroundTransparency < 1 then
					props.BackgroundTransparency = 1
				end
				if child:IsA("UIStroke") then
					props.Transparency = 1
				end
				if next(props) then
					Util.safeSprTarget(child, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], props)
				end
			end
		end

		task.delay(0.22, function()
			pcall(function() frame:Destroy() end)
			self._entries[id] = nil
		end)
	end

	function NotificationManager:clear()
		for id in pairs(self._entries) do
			self:dismiss(id)
		end
	end

	function NotificationManager:push(title, body, ntype, duration)
		title = Util.textOf(title)
		if title == "" then title = "Notification" end
		body = Util.textOf(body)
		duration = math.max(1, tonumber(duration) or 4)

		local meta = resolveType(ntype)
		self._nextId = self._nextId + 1
		local id = self._nextId
		self._layoutOrder = self._layoutOrder + 1

		self:_prune()

		local frame = Util.make("Frame", {
			Name = "Toast_" .. tostring(id),
			Size = UDim2.fromOffset(Theme.NOTIF.W, 0),
			BackgroundColor3 = Theme.COLOR.GLASS,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			LayoutOrder = self._layoutOrder,
			Parent = self._stack,
			ZIndex = 201,
		})
		Util.corner(frame, Theme.NOTIF.RADIUS)
		Util.stroke(frame, Theme.COLOR.BORDER_SOFT, 1, 0.42)

		local glass = Util.make("Frame", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Theme.COLOR.BG2,
			BackgroundTransparency = 0.14,
			BorderSizePixel = 0,
			ZIndex = 201,
			Parent = frame,
		})
		Util.corner(glass, Theme.NOTIF.RADIUS)

		local scale = Util.scale(frame)
		scale.Scale = 0.95
		frame.Position = UDim2.new(0, 0, 0, 22)

		local accentBar = Util.make("Frame", {
			Size = UDim2.new(0, 4, 1, -12),
			Position = UDim2.new(0, 0, 0, 6),
			BackgroundColor3 = meta.color,
			BorderSizePixel = 0,
			ZIndex = 203,
			Parent = frame,
		})
		Util.corner(accentBar, 2)

		local iconSize = 28
		local iconFrame = Util.make("Frame", {
			Size = UDim2.fromOffset(iconSize, iconSize),
			Position = UDim2.new(0, 14, 0, 14),
			BackgroundColor3 = meta.color,
			BackgroundTransparency = 0.24,
			BorderSizePixel = 0,
			ZIndex = 203,
			Parent = frame,
		})
		Util.corner(iconFrame, Theme.RADIUS.SEARCH)
		Util.make("TextLabel", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
			Text = meta.icon,
			TextColor3 = Theme.COLOR.WHITE,
			Font = Theme.FONT_BOLD,
			TextSize = 15,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = 204,
			Parent = iconFrame,
		})

		Util.make("TextLabel", {
			Name = "Title",
			Size = UDim2.new(1, -92, 0, 20),
			Position = UDim2.new(0, 52, 0, 12),
			BackgroundTransparency = 1,
			Text = title,
			TextColor3 = Theme.COLOR.TEXT,
			Font = Theme.FONT_BOLD,
			TextSize = Theme.TEXT_SM + 1,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			ZIndex = 203,
			Parent = frame,
		})

		local bodyLabel = Util.make("TextLabel", {
			Name = "Body",
			Size = UDim2.new(1, -92, 0, 0),
			Position = UDim2.new(0, 52, 0, 34),
			BackgroundTransparency = 1,
			Text = body,
			TextColor3 = Theme.COLOR.TEXT2,
			Font = Theme.FONT,
			TextSize = Theme.TEXT_SM,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			ZIndex = 203,
			Parent = frame,
		})

		Util.make("TextLabel", {
			Name = "Timestamp",
			Size = UDim2.fromOffset(52, 14),
			Position = UDim2.new(1, -58, 0, 14),
			BackgroundTransparency = 1,
			Text = os.date("%H:%M"),
			TextColor3 = Theme.COLOR.TEXT3,
			Font = Theme.FONT,
			TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Right,
			ZIndex = 203,
			Parent = frame,
		})

		local closeBtn = Util.make("TextButton", {
			Size = UDim2.fromOffset(22, 22),
			Position = UDim2.new(1, -30, 0, 34),
			BackgroundTransparency = 1,
			Text = "×",
			TextColor3 = Theme.COLOR.TEXT3,
			Font = Theme.FONT_BOLD,
			TextSize = 16,
			AutoButtonColor = false,
			ZIndex = 204,
			Parent = frame,
		})

		local progress = Util.make("Frame", {
			Name = "Progress",
			Size = UDim2.new(1, 0, 0, 2),
			Position = UDim2.new(0, 0, 1, -2),
			BackgroundColor3 = meta.color,
			BackgroundTransparency = 0.12,
			BorderSizePixel = 0,
			ZIndex = 204,
			Parent = frame,
		})
		Util.corner(progress, 1)

		local entry = {
			id = id,
			frame = frame,
			layoutOrder = self._layoutOrder,
			paused = false,
			dismissing = false,
			elapsed = 0,
			duration = duration,
			tickConn = nil,
		}
		self._entries[id] = entry

		local function computeHeight()
			local bodyH = 0
			if body ~= "" then
				local bounds = TextService:GetTextSize(body, Theme.TEXT_SM, Theme.FONT, Vector2.new(Theme.NOTIF.W - 92, 200))
				bodyH = bounds.Y + 6
			end
			return Util.clamp(72 + bodyH, 72, 148)
		end

		task.defer(function()
			if not frame.Parent then return end
			local finalH = computeHeight()
			bodyLabel.Size = UDim2.new(1, -92, 0, finalH - 52)
			Util.safeSprTarget(frame, Theme.SPRING.SMOOTH[1], Theme.SPRING.SMOOTH[2], {
				Size = UDim2.fromOffset(Theme.NOTIF.W, finalH),
				Position = UDim2.new(0, 0, 0, 0),
				BackgroundTransparency = 0.08,
			})
			Util.safeSprTarget(scale, Theme.SPRING.BOUNCY[1], Theme.SPRING.BOUNCY[2], { Scale = 1 })
			self:_reflow()
		end)

		closeBtn.MouseButton1Click:Connect(function()
			self:dismiss(id)
		end)

		frame.MouseEnter:Connect(function()
			entry.paused = true
			Util.safeSprTarget(glass, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], { BackgroundTransparency = 0.06 })
		end)
		frame.MouseLeave:Connect(function()
			entry.paused = false
			Util.safeSprTarget(glass, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], { BackgroundTransparency = 0.14 })
		end)

		entry.tickConn = RunService.RenderStepped:Connect(function(dt)
			if entry.dismissing or not frame.Parent then
				if entry.tickConn then
					pcall(function() entry.tickConn:Disconnect() end)
					entry.tickConn = nil
				end
				return
			end
			if not entry.paused then
				entry.elapsed = entry.elapsed + dt
				local pct = Util.clamp(1 - entry.elapsed / entry.duration, 0, 1)
				progress.Size = UDim2.new(pct, 0, 0, 2)
				if entry.elapsed >= entry.duration then
					self:dismiss(id)
				end
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
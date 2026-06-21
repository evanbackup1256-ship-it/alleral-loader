-- Alleral V12 — queued premium notifications (top-right stack)
return function(EventBus, Bootstrap)
	local NotificationManager = {}
	local TweenService = game:GetService("TweenService")
	local Players = game:GetService("Players")

	local queue = {}
	local active = {}
	local processing = false
	local MAX_STACK = 5
	local GAP = 8
	local WIDTH = 300

	local TYPE_META = {
		info = { icon = "info", color = "#6366F1" },
		success = { icon = "check", color = "#34D399" },
		warning = { icon = "alert-triangle", color = "#FBBF24" },
		error = { icon = "x", color = "#F87171" },
		loading = { icon = "loader", color = "#06B6D4" },
	}

	local debounce = {}
	local DEBOUNCE_SEC = 3

	local function sanitize(text, maxLen)
		if Bootstrap and Bootstrap.sanitize then
			return Bootstrap.sanitize(text, maxLen)
		end
		return tostring(text or "")
	end

	local function getHost()
		local player = Players.LocalPlayer
		if not player then
			return nil
		end
		local gui = player:FindFirstChildOfClass("PlayerGui")
		if not gui then
			return nil
		end
		local host = gui:FindFirstChild("AlleralNotifyHost")
		if not host then
			host = Instance.new("ScreenGui")
			host.Name = "AlleralNotifyHost"
			host.ResetOnSpawn = false
			host.DisplayOrder = 900
			host.IgnoreGuiInset = true
			host.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
			host.Parent = gui
		end
		return host
	end

	local function reposition()
		local y = 12
		for i = #active, 1, -1 do
			local card = active[i]
			if card and card.frame and card.frame.Parent then
				card.frame.Position = UDim2.new(1, -WIDTH - 12, 0, y)
				y = y + card.frame.AbsoluteSize.Y + GAP
			end
		end
	end

	local function dismiss(card)
		if not card or not card.frame then
			return
		end
		for i, c in ipairs(active) do
			if c == card then
				table.remove(active, i)
				break
			end
		end
		local frame = card.frame
		local tween = TweenService:Create(
			frame,
			TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
			{ Position = frame.Position + UDim2.fromOffset(40, 0), BackgroundTransparency = 1 }
		)
		for _, desc in ipairs(frame:GetDescendants()) do
			if desc:IsA("TextLabel") or desc:IsA("TextButton") then
				TweenService:Create(desc, TweenInfo.new(0.18), { TextTransparency = 1 }):Play()
			end
		end
		tween:Play()
		tween.Completed:Connect(function()
			pcall(function() frame:Destroy() end)
			reposition()
		end)
		if EventBus then
			EventBus.emit("notification:dismissed", card.id)
		end
	end

	local function spawnCard(entry)
		local host = getHost()
		if not host then
			return nil
		end

		local meta = TYPE_META[entry.type] or TYPE_META.info
		local frame = Instance.new("Frame")
		frame.Name = "AlleralNotify"
		frame.AnchorPoint = Vector2.new(1, 0)
		frame.Position = UDim2.new(1, -WIDTH - 12, 0, 12)
		frame.Size = UDim2.fromOffset(WIDTH, 0)
		frame.AutomaticSize = Enum.AutomaticSize.Y
		frame.BackgroundColor3 = Color3.fromHex("#0C121C")
		frame.BackgroundTransparency = 0.08
		frame.BorderSizePixel = 0
		frame.ClipsDescendants = true
		frame.Parent = host

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 12)
		corner.Parent = frame

		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromHex(meta.color)
		stroke.Thickness = 1
		stroke.Transparency = 0.5
		stroke.Parent = frame

		local pad = Instance.new("UIPadding")
		pad.PaddingTop = UDim.new(0, 10)
		pad.PaddingBottom = UDim.new(0, 10)
		pad.PaddingLeft = UDim.new(0, 12)
		pad.PaddingRight = UDim.new(0, 12)
		pad.Parent = frame

		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 4)
		layout.Parent = frame

		local title = Instance.new("TextLabel")
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.GothamBold
		title.TextSize = 14
		title.TextColor3 = Color3.fromHex("#F8FAFC")
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Text = entry.title
		title.Size = UDim2.new(1, 0, 0, 18)
		title.Parent = frame

		if entry.body ~= "" then
			local body = Instance.new("TextLabel")
			body.BackgroundTransparency = 1
			body.Font = Enum.Font.Gotham
			body.TextSize = 12
			body.TextColor3 = Color3.fromHex("#94A3B8")
			body.TextXAlignment = Enum.TextXAlignment.Left
			body.TextWrapped = true
			body.Text = entry.body
			body.Size = UDim2.new(1, 0, 0, 0)
			body.AutomaticSize = Enum.AutomaticSize.Y
			body.Parent = frame
		end

		local barBg = Instance.new("Frame")
		barBg.Name = "ProgressBg"
		barBg.BackgroundColor3 = Color3.fromHex("#1A2332")
		barBg.BackgroundTransparency = 0.3
		barBg.BorderSizePixel = 0
		barBg.Size = UDim2.new(1, 0, 0, 3)
		barBg.Parent = frame

		local barCorner = Instance.new("UICorner")
		barCorner.CornerRadius = UDim.new(1, 0)
		barCorner.Parent = barBg

		local bar = Instance.new("Frame")
		bar.Name = "Progress"
		bar.BackgroundColor3 = Color3.fromHex(meta.color)
		bar.BorderSizePixel = 0
		bar.Size = UDim2.new(1, 0, 1, 0)
		bar.Parent = barBg

		frame.Position = frame.Position + UDim2.fromOffset(50, 0)
		frame.BackgroundTransparency = 1
		title.TextTransparency = 1

		local card = { frame = frame, id = entry.id, bar = bar }
		table.insert(active, 1, card)
		reposition()

		TweenService:Create(frame, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Position = frame.Position - UDim2.fromOffset(50, 0),
			BackgroundTransparency = 0.08,
		}):Play()
		TweenService:Create(title, TweenInfo.new(0.2), { TextTransparency = 0 }):Play()

		TweenService:Create(bar, TweenInfo.new(entry.duration, Enum.EasingStyle.Linear), {
			Size = UDim2.new(0, 0, 1, 0),
		}):Play()

		task.delay(entry.duration, function()
			dismiss(card)
		end)

		if EventBus then
			EventBus.emit("notification:shown", entry.id, entry.type)
		end
		return card
	end

	local function processQueue()
		if processing then
			return
		end
		processing = true
		task.spawn(function()
			while #queue > 0 and #active < MAX_STACK do
				local entry = table.remove(queue, 1)
				spawnCard(entry)
				task.wait(0.05)
			end
			processing = false
		end)
	end

	function NotificationManager.push(WindUIRef, title, body, ntype, duration)
		title = sanitize(title, 80)
		if title == "" then
			title = "Alleral"
		end
		body = sanitize(body, 240)
		ntype = tostring(ntype or "info"):lower()
		duration = math.max(1.5, tonumber(duration) or 4)

		local key = title .. "|" .. body .. "|" .. ntype
		local now = tick()
		if debounce[key] and now - debounce[key] < DEBOUNCE_SEC then
			return nil
		end
		debounce[key] = now

		local entry = {
			id = tostring(now) .. "_" .. tostring(#queue + #active),
			title = title,
			body = body,
			type = ntype,
			duration = duration,
		}
		table.insert(queue, entry)
		processQueue()

		if WindUIRef and type(WindUIRef.Notify) == "function" then
			pcall(function()
				local meta = TYPE_META[ntype] or TYPE_META.info
				WindUIRef:Notify({
					Title = title,
					Content = body,
					Icon = meta.icon,
					IconColor = Color3.fromHex(meta.color),
					Duration = duration,
					CanClose = true,
				})
			end)
		end

		return true
	end

	function NotificationManager.clear()
		queue = {}
		for _, card in ipairs(active) do
			pcall(function()
				if card.frame then
					card.frame:Destroy()
				end
			end)
		end
		active = {}
	end

	function NotificationManager.stats()
		return { queued = #queue, active = #active }
	end

	return NotificationManager
end
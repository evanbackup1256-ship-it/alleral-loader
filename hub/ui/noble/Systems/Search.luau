-- Noble V8 — global command-palette search overlay (Arc / Raycast style)
return function(deps)
	local Theme = deps.Theme
	local Spr = deps.Spr
	local Util = deps.Util
	local Janitor = deps.Janitor
	local Signal = deps.Signal

	local UserInputService = game:GetService("UserInputService")
	local TextService = game:GetService("TextService")

	local Search = {}
	Search.__index = Search

	local function normalize(text)
		return string.lower(Util.textOf(text))
	end

	local function keyName(keyCode)
		local name = tostring(keyCode):gsub("Enum.KeyCode.", "")
		if name == "LeftControl" or name == "RightControl" then return "Ctrl" end
		if name == "LeftShift" or name == "RightShift" then return "Shift" end
		if name == "LeftAlt" or name == "RightAlt" then return "Alt" end
		return name
	end

	local function highlightRichText(text, query)
		text = Util.textOf(text)
		query = normalize(query)
		if query == "" then return text end
		local lower = normalize(text)
		local startIdx, endIdx = string.find(lower, query, 1, true)
		if not startIdx then return text end
		local before = string.sub(text, 1, startIdx - 1)
		local match = string.sub(text, startIdx, endIdx)
		local after = string.sub(text, endIdx + 1)
		local accent = Theme.COLOR.ACCENT_LIGHT
		local r = math.floor(accent.R * 255)
		local g = math.floor(accent.G * 255)
		local b = math.floor(accent.B * 255)
		return before .. '<font color="rgb(' .. r .. ',' .. g .. ',' .. b .. ')"><b>' .. match .. "</b></font>" .. after
	end

	local function matchesQuery(entry, query)
		query = normalize(query)
		if query == "" then return true end
		local hay = normalize(entry.label) .. " " .. normalize(entry.path) .. " " .. normalize(entry.keywords)
		return string.find(hay, query, 1, true) ~= nil
	end

	function Search.new(options)
		options = type(options) == "table" and options or {}
		assert(typeof(options.parent) == "Instance", "Search.new requires parent ScreenGui")

		local self = setmetatable({}, Search)
		self._janitor = Janitor.new()
		self._parent = options.parent
		self._registry = {}
		self._results = {}
		self._selected = 1
		self._open = false
		self._modifiers = options.modifiers or { Ctrl = true }
		self._keybind = options.keybind or Enum.KeyCode.K
		self._onSelect = options.onSelect
		self.Opened = Signal.new()
		self.Closed = Signal.new()
		self.Selected = Signal.new()

		local overlay = Util.make("Frame", {
			Name = "SearchOverlay",
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Color3.fromRGB(3, 6, 14),
			BackgroundTransparency = 1,
			Visible = false,
			BorderSizePixel = 0,
			ZIndex = 500,
			Parent = options.parent,
		})

		local panelScale = Util.make("UIScale", { Scale = 0.94, Parent = overlay })
		local panel = Util.make("Frame", {
			Name = "SearchPanel",
			AnchorPoint = Vector2.new(0.5, 0.18),
			Position = UDim2.fromScale(0.5, 0.18),
			Size = UDim2.fromOffset(640, 420),
			BackgroundColor3 = Theme.COLOR.BG1,
			BackgroundTransparency = 0.06,
			BorderSizePixel = 0,
			ClipsDescendants = true,
			ZIndex = 501,
			Parent = overlay,
		})
		Util.corner(panel, Theme.RADIUS.WINDOW)
		Util.stroke(panel, Theme.COLOR.BORDER_SOFT, 1, 0.35)

		local glow = Util.make("Frame", {
			Size = UDim2.new(1, 16, 1, 16),
			Position = UDim2.new(0, -8, 0, -8),
			BackgroundColor3 = Theme.COLOR.ACCENT,
			BackgroundTransparency = 0.92,
			BorderSizePixel = 0,
			ZIndex = 500,
			Parent = panel,
		})
		Util.corner(glow, Theme.RADIUS.WINDOW + 4)

		local topAccent = Util.make("Frame", {
			Size = UDim2.new(1, 0, 0, 3),
			BackgroundColor3 = Theme.COLOR.ACCENT,
			BorderSizePixel = 0,
			ZIndex = 503,
			Parent = panel,
		})
		Util.gradient(topAccent, Theme.COLOR.ACCENT_LIGHT, Theme.COLOR.ACCENT_DARK, 0)

		local searchWrap = Util.make("Frame", {
			Size = UDim2.new(1, -32, 0, 52),
			Position = UDim2.new(0, 16, 0, 16),
			BackgroundTransparency = 1,
			ZIndex = 502,
			Parent = panel,
		})

		local searchBox = Util.make("TextBox", {
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundColor3 = Theme.COLOR.SEARCH_BG,
			BackgroundTransparency = 0.08,
			BorderSizePixel = 0,
			PlaceholderText = "Search controls, tabs, actions...",
			PlaceholderColor3 = Theme.COLOR.TEXT3,
			Text = "",
			TextColor3 = Theme.COLOR.TEXT,
			Font = Theme.FONT,
			TextSize = Theme.TEXT,
			TextXAlignment = Enum.TextXAlignment.Left,
			ClearTextOnFocus = false,
			ZIndex = 503,
			Parent = searchWrap,
		})
		Util.corner(searchBox, Theme.RADIUS.SEARCH)
		local searchStroke = Util.stroke(searchBox, Theme.COLOR.SEARCH_BORDER, 1, 0.32)
		Util.padding(searchBox, 44, 14, 0, 0)

		Util.make("TextLabel", {
			Size = UDim2.fromOffset(24, 52),
			Position = UDim2.new(0, 12, 0, 0),
			BackgroundTransparency = 1,
			Text = "⌕",
			TextColor3 = Theme.COLOR.TEXT3,
			Font = Theme.FONT_BOLD,
			TextSize = 18,
			TextXAlignment = Enum.TextXAlignment.Center,
			TextYAlignment = Enum.TextYAlignment.Center,
			ZIndex = 504,
			Parent = searchWrap,
		})

		local hint = Util.make("TextLabel", {
			Size = UDim2.new(1, -32, 0, 18),
			Position = UDim2.new(0, 16, 0, 74),
			BackgroundTransparency = 1,
			Text = "Ctrl+K to open  •  ↑↓ navigate  •  Enter select  •  Esc close",
			TextColor3 = Theme.COLOR.TEXT3,
			Font = Theme.FONT,
			TextSize = Theme.TEXT_SM,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 502,
			Parent = panel,
		})

		local resultsScroll = Util.make("ScrollingFrame", {
			Size = UDim2.new(1, -32, 1, -108),
			Position = UDim2.new(0, 16, 0, 96),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ScrollBarThickness = 4,
			ZIndex = 502,
			Parent = panel,
		})
		Util.styleScroll(resultsScroll)

		local resultsList = Util.make("UIListLayout", {
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = resultsScroll,
		})

		local emptyLabel = Util.make("TextLabel", {
			Size = UDim2.new(1, 0, 0, 36),
			BackgroundTransparency = 1,
			Text = "No matches found",
			TextColor3 = Theme.COLOR.TEXT3,
			Font = Theme.FONT,
			TextSize = Theme.TEXT_SM,
			Visible = false,
			ZIndex = 503,
			Parent = resultsScroll,
		})

		self._overlay = overlay
		self._panel = panel
		self._panelScale = panelScale
		self._glow = glow
		self._searchBox = searchBox
		self._searchStroke = searchStroke
		self._resultsScroll = resultsScroll
		self._resultsList = resultsList
		self._emptyLabel = emptyLabel
		self._rowFrames = {}

		local function setSelected(idx)
			self._selected = Util.clamp(idx, 1, math.max(1, #self._results))
			for i, row in ipairs(self._rowFrames) do
				local active = i == self._selected
				Spr.target(row, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], {
					BackgroundColor3 = active and Theme.COLOR.BG4 or Theme.COLOR.BG3,
					BackgroundTransparency = active and 0.04 or 0.18,
				})
				local bar = row:FindFirstChild("AccentBar")
				if bar then
					Spr.target(bar, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], {
						BackgroundTransparency = active and 0.05 or 0.85,
					})
				end
			end
		end

		local function clearRows()
			for _, row in ipairs(self._rowFrames) do
				pcall(function() row:Destroy() end)
			end
			self._rowFrames = {}
		end

		local function activate(entry)
			if not entry then return end
			self.Selected:Fire(entry)
			if type(entry.action) == "function" then
				pcall(entry.action)
			end
			if type(self._onSelect) == "function" then
				pcall(self._onSelect, entry)
			end
			self:close()
		end

		local function rebuildResults()
			local query = searchBox.Text
			clearRows()
			self._results = {}

			for _, entry in ipairs(self._registry) do
				if matchesQuery(entry, query) then
					table.insert(self._results, entry)
				end
			end

			table.sort(self._results, function(a, b)
				local qa = normalize(query)
				if qa == "" then return a.label < b.label end
				local aStarts = string.find(normalize(a.label), qa, 1, true) == 1
				local bStarts = string.find(normalize(b.label), qa, 1, true) == 1
				if aStarts ~= bStarts then return aStarts end
				return a.label < b.label
			end)

			emptyLabel.Visible = #self._results == 0

			for idx, entry in ipairs(self._results) do
				local row = Util.make("TextButton", {
					Size = UDim2.new(1, -4, 0, 44),
					BackgroundColor3 = Theme.COLOR.BG3,
					BackgroundTransparency = 0.18,
					BorderSizePixel = 0,
					Text = "",
					AutoButtonColor = false,
					LayoutOrder = idx,
					ZIndex = 503,
					Parent = resultsScroll,
				})
				Util.corner(row, Theme.RADIUS.LIST)

				local bar = Util.make("Frame", {
					Name = "AccentBar",
					Size = UDim2.new(0, 3, 1, -12),
					Position = UDim2.new(0, 6, 0, 6),
					BackgroundColor3 = Theme.COLOR.ACCENT_LIGHT,
					BackgroundTransparency = 0.85,
					BorderSizePixel = 0,
					ZIndex = 504,
					Parent = row,
				})
				Util.corner(bar, 2)

				Util.make("TextLabel", {
					Size = UDim2.new(1, -20, 0, 20),
					Position = UDim2.new(0, 16, 0, 6),
					BackgroundTransparency = 1,
					RichText = true,
					Text = highlightRichText(entry.label, query),
					TextColor3 = Theme.COLOR.TEXT,
					Font = Theme.FONT_BOLD,
					TextSize = Theme.TEXT_SM,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					ZIndex = 504,
					Parent = row,
				})

				Util.make("TextLabel", {
					Size = UDim2.new(1, -20, 0, 16),
					Position = UDim2.new(0, 16, 0, 24),
					BackgroundTransparency = 1,
					RichText = true,
					Text = highlightRichText(entry.path or "", query),
					TextColor3 = Theme.COLOR.TEXT3,
					Font = Theme.FONT,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextTruncate = Enum.TextTruncate.AtEnd,
					ZIndex = 504,
					Parent = row,
				})

				row.MouseEnter:Connect(function()
					setSelected(idx)
				end)
				row.MouseButton1Click:Connect(function()
					activate(entry)
				end)

				table.insert(self._rowFrames, row)
			end

			self._selected = Util.clamp(self._selected, 1, math.max(1, #self._results))
			setSelected(self._selected)
		end

		self._rebuildResults = rebuildResults
		self._activate = activate
		self._setSelected = setSelected

		searchBox:GetPropertyChangedSignal("Text"):Connect(rebuildResults)

		searchBox.Focused:Connect(function()
			Spr.target(searchStroke, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], {
				Color = Theme.COLOR.ACCENT,
				Transparency = 0.08,
			})
			Spr.target(searchBox, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], {
				BackgroundColor3 = Color3.fromRGB(18, 30, 58),
			})
			Spr.target(glow, Theme.SPRING.SMOOTH[1], Theme.SPRING.SMOOTH[2], {
				BackgroundTransparency = 0.78,
			})
		end)

		searchBox.FocusLost:Connect(function(enter)
			Spr.target(searchStroke, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], {
				Color = Theme.COLOR.SEARCH_BORDER,
				Transparency = 0.32,
			})
			Spr.target(searchBox, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], {
				BackgroundColor3 = Theme.COLOR.SEARCH_BG,
			})
			Spr.target(glow, Theme.SPRING.SMOOTH[1], Theme.SPRING.SMOOTH[2], {
				BackgroundTransparency = 0.92,
			})
			if enter and self._results[self._selected] then
				activate(self._results[self._selected])
			end
		end)

		overlay.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				self:close()
			end
		end)
		panel.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				-- absorb clicks
			end
		end)

		local inputConn = UserInputService.InputBegan:Connect(function(input, gpe)
			if gpe then return end

			if self._open then
				if input.KeyCode == Enum.KeyCode.Escape then
					self:close()
					return
				end
				if input.KeyCode == Enum.KeyCode.Return then
					activate(self._results[self._selected])
					return
				end
				if input.KeyCode == Enum.KeyCode.Up then
					setSelected(self._selected - 1)
					return
				end
				if input.KeyCode == Enum.KeyCode.Down then
					setSelected(self._selected + 1)
					return
				end
			end

			if input.KeyCode == self._keybind then
				local ctrl = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
				local shift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
				local alt = UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) or UserInputService:IsKeyDown(Enum.KeyCode.RightAlt)
				local wantCtrl = self._modifiers.Ctrl == true
				local wantShift = self._modifiers.Shift == true
				local wantAlt = self._modifiers.Alt == true
				if (not wantCtrl or ctrl) and (not wantShift or shift) and (not wantAlt or alt) then
					self:toggle()
				end
			end
		end)
		self._janitor:Connect(inputConn)

		self._janitor:Add(overlay, "Destroy")
		return self
	end

	function Search:register(entry)
		if type(entry) ~= "table" then return end
		entry.id = entry.id or ("entry_" .. tostring(#self._registry + 1))
		entry.label = Util.textOf(entry.label or entry.name or "Untitled")
		entry.path = Util.textOf(entry.path or "")
		entry.keywords = Util.textOf(entry.keywords or "")
		table.insert(self._registry, entry)
		if self._open and self._rebuildResults then
			self._rebuildResults()
		end
		return entry.id
	end

	function Search:unregister(id)
		for i, entry in ipairs(self._registry) do
			if entry.id == id then
				table.remove(self._registry, i)
				break
			end
		end
		if self._open and self._rebuildResults then
			self._rebuildResults()
		end
	end

	function Search:clearRegistry()
		for i = #self._registry, 1, -1 do
			self._registry[i] = nil
		end
		if self._open and self._rebuildResults then
			self._rebuildResults()
		end
	end

	function Search:open()
		if self._open then return end
		self._open = true
		self._overlay.Visible = true
		self._searchBox.Text = ""
		self._selected = 1
		self._rebuildResults()

		Spr.target(self._overlay, Theme.SPRING.SMOOTH[1], Theme.SPRING.SMOOTH[2], {
			BackgroundTransparency = 0.42,
		})
		Spr.target(self._panelScale, Theme.SPRING.BOUNCY[1], Theme.SPRING.BOUNCY[2], {
			Scale = 1,
		})
		Spr.target(self._panel, Theme.SPRING.SMOOTH[1], Theme.SPRING.SMOOTH[2], {
			BackgroundTransparency = 0.02,
		})

		task.defer(function()
			if self._searchBox then
				self._searchBox:CaptureFocus()
			end
		end)
		self.Opened:Fire()
	end

	function Search:close()
		if not self._open then return end
		self._open = false

		if self._searchBox:IsFocused() then
			self._searchBox:ReleaseFocus()
		end

		Spr.target(self._overlay, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], {
			BackgroundTransparency = 1,
		})
		Spr.target(self._panelScale, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], {
			Scale = 0.94,
		})
		Spr.target(self._panel, Theme.SPRING.SNAPPY[1], Theme.SPRING.SNAPPY[2], {
			BackgroundTransparency = 0.2,
		})

		task.delay(0.18, function()
			if not self._open and self._overlay then
				self._overlay.Visible = false
			end
		end)
		self.Closed:Fire()
	end

	function Search:toggle()
		if self._open then self:close() else self:open() end
	end

	function Search:setKeybind(keyCode, modifiers)
		if typeof(keyCode) == "EnumItem" then
			self._keybind = keyCode
		end
		if type(modifiers) == "table" then
			self._modifiers = modifiers
		end
	end

	function Search:getKeybindLabel()
		local parts = {}
		if self._modifiers.Ctrl then table.insert(parts, "Ctrl") end
		if self._modifiers.Shift then table.insert(parts, "Shift") end
		if self._modifiers.Alt then table.insert(parts, "Alt") end
		table.insert(parts, keyName(self._keybind))
		return table.concat(parts, "+")
	end

	function Search:Destroy()
		self:close()
		self._janitor:Destroy()
		if self.Opened then self.Opened:Destroy() end
		if self.Closed then self.Closed:Destroy() end
		if self.Selected then self.Selected:Destroy() end
	end

	return Search
end
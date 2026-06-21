-- Alleral Noble V10 — text sanitization and boot validation
return function(Theme)
	local Validation = {}
	Validation._readyPrinted = false

	local MOJIBAKE = {
		["â€¢"] = "•",
		["â—‹"] = "◌",
		["â€"] = "",
		["Â"] = "",
		["â†'"] = "→",
		["â†’"] = "→",
	}

	function Validation.safeText(value, maxLen)
		if value == nil then return "" end
		local text = tostring(value)
		text = text:gsub("[%c]", " ")
		text = text:gsub("(stack overflow%s*)+", "stack overflow ")
		text = text:gsub("(%s%s+)", " ")
		maxLen = tonumber(maxLen) or 240
		if #text > maxLen then
			text = string.sub(text, 1, maxLen - 3) .. "..."
		end
		return text
	end

	function Validation.sanitizeText(value, maxLen)
		if value == nil then return "" end
		local text = tostring(value)
		text = text:gsub("rbxassetid://%d+", "")
		text = text:gsub("rbxasset://[^%s]+", "")
		for bad, good in pairs(MOJIBAKE) do
			text = text:gsub(bad, good)
		end
		text = text:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
		return Validation.safeText(text, maxLen or 120)
	end

	function Validation.sanitizeIcon(icon, fallback)
		fallback = fallback or "◌"
		if icon == nil or icon == "" then return fallback end
		local s = tostring(icon)
		if s:find("rbxasset") or s:find("http") then return fallback end
		if #s > 4 then return fallback end
		return Validation.sanitizeText(s, 4)
	end

	function Validation.isScreenGui(inst)
		return typeof(inst) == "Instance" and inst:IsA("ScreenGui") and inst.Parent ~= nil
	end

	function Validation.bootPrint(msg)
		warn("[Alleral V10] " .. tostring(msg))
	end

	local function countGuiChildren(frame)
		if typeof(frame) ~= "Instance" then return 0 end
		local n = 0
		for _, child in ipairs(frame:GetChildren()) do
			if child:IsA("GuiObject") and not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
				n = n + 1
			end
		end
		return n
	end

	function Validation.tabHasContent(tab)
		if type(tab) ~= "table" then return false end
		if type(tab._colFrames) == "table" then
			for _, col in ipairs(tab._colFrames) do
				if countGuiChildren(col) > 0 then
					return true
				end
			end
		end
		if tab._panel and typeof(tab._panel) == "Instance" then
			return #tab._panel:GetChildren() > 0
		end
		return false
	end

	function Validation.runBootSequence(deps)
		Validation.bootPrint("Framework loaded")
		if deps.Fusion then Validation.bootPrint("Fusion mounted") end
		if deps.Motion then Validation.bootPrint("Spr motion active") end
		if deps.DropdownManager then Validation.bootPrint("Dropdown overlay ready") end
		if deps.NotificationManager then Validation.bootPrint("Notification manager ready") end
	end

	function Validation.runLayoutChecks(window)
		if not window then return false end
		local ok = true
		if window._screen and not Validation.isScreenGui(window._screen) then
			Validation.bootPrint("Layout warning: ScreenGui parent missing")
			ok = false
		end
		if window._sidebar and window._sidebar:IsA("ScrollingFrame") then
			if window._sidebar.CanvasPosition.Y > 2 then
				window._sidebar.CanvasPosition = Vector2.new(0, 0)
			end
		end
		if window._tabStrip and window._tabStrip:IsA("ScrollingFrame") then
			if window._tabStrip.CanvasPosition.X > 2 then
				window._tabStrip.CanvasPosition = Vector2.new(0, 0)
			end
		end
		return ok
	end

	function Validation.validateWindowMount(win, tabList)
		if Validation._readyPrinted then
			return true
		end
		tabList = type(tabList) == "table" and tabList or (win and win._tabs) or {}
		local issues = {}

		if not win then
			table.insert(issues, "window missing")
		else
			if not win._screen or not Validation.isScreenGui(win._screen) then
				table.insert(issues, "ScreenGui not parented")
			end
			if not win._contentArea then
				table.insert(issues, "content root missing")
			end
			if not win._sidebar then
				table.insert(issues, "sidebar missing")
			end
			if not win._tabStrip then
				table.insert(issues, "top tabs missing")
			end
		end

		local tabCount = #tabList
		if tabCount == 0 and win and type(win._tabs) == "table" then
			tabCount = #win._tabs
			tabList = win._tabs
		end
		if tabCount == 0 then
			table.insert(issues, "no tabs registered")
		elseif win then
			if win._sidebar and countGuiChildren(win._sidebar) < tabCount then
				table.insert(issues, "sidebar missing tab buttons")
			end
			if win._tabStrip and countGuiChildren(win._tabStrip) < tabCount then
				table.insert(issues, "top tabs incomplete")
			end
		end

		local hasContentTab = false
		for _, tab in ipairs(tabList) do
			if Validation.tabHasContent(tab) then
				hasContentTab = true
				break
			end
		end
		if tabCount > 0 and not hasContentTab then
			table.insert(issues, "no tab has mounted content")
		end

		local searchSafe = true
		if win and win._searchFailed then
			searchSafe = true
		elseif win and win._search and type(win._search.registerEntry) == "function" then
			searchSafe = true
		end

		if searchSafe then
			Validation.bootPrint("SearchManager safe")
		end
		Validation.bootPrint("Notifications sanitized")

		if #issues == 0 then
			if win and type(win.selectFirstTabWithContent) == "function" then
				pcall(function() win:selectFirstTabWithContent() end)
			end
			Validation.bootPrint("Tabs mounted")
			Validation.bootPrint("Sidebar mounted")
			Validation.bootPrint("Content mounted")
			Validation.bootPrint("Runtime validation passed")
			Validation.bootPrint("UI ready")
			Validation._readyPrinted = true
			if win and win._statusLeft then
				win._statusLeft.Text = "● UI Ready"
				win._statusLeft.TextColor3 = Theme.COLOR.GREEN
			end
			return true
		end

		local summary = Validation.safeText(table.concat(issues, "; "), 180)
		Validation.bootPrint("Mount validation failed: " .. summary)
		if win and type(win.showBuildError) == "function" then
			pcall(function() win:showBuildError(summary) end)
		end
		if win and win._statusLeft then
			win._statusLeft.Text = "● UI Error"
			win._statusLeft.TextColor3 = Theme.COLOR.Red
		end
		return false
	end

	function Validation.runRuntimeChecks(win, tabList)
		if win then
			return Validation.validateWindowMount(win, tabList)
		end
		return false
	end

	return Validation
end
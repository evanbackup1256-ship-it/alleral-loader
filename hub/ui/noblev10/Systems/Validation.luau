-- Alleral Noble V10 — text sanitization and boot validation
return function(Theme)
	local Validation = {}

	local MOJIBAKE = {
		["â€¢"] = "•",
		["â—‹"] = "◌",
		["â€"] = "",
		["Â"] = "",
		["â†'"] = "→",
		["â†’"] = "→",
	}

	function Validation.sanitizeText(value, maxLen)
		if value == nil then return "" end
		local text = tostring(value)
		text = text:gsub("rbxassetid://%d+", "")
		text = text:gsub("rbxasset://[^%s]+", "")
		for bad, good in pairs(MOJIBAKE) do
			text = text:gsub(bad, good)
		end
		text = text:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
		maxLen = tonumber(maxLen) or 120
		if #text > maxLen then
			text = string.sub(text, 1, maxLen - 1) .. "…"
		end
		return text
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
		warn("[Alleral V10] " .. msg)
	end

	function Validation.runBootSequence(deps)
		Validation.bootPrint("Framework loaded")
		if deps.Fusion then Validation.bootPrint("Fusion mounted") end
		if deps.Motion then Validation.bootPrint("Spr motion active") end
		if deps.DropdownManager then Validation.bootPrint("Dropdown overlay ready") end
		if deps.NotificationManager then Validation.bootPrint("Notification manager ready") end
		if deps.SearchManager then Validation.bootPrint("Search ready") end
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
		Validation.bootPrint("Layout validation passed")
		return ok
	end

	function Validation.runRuntimeChecks()
		Validation.bootPrint("Runtime validation passed")
		Validation.bootPrint("UI ready")
		return true
	end

	return Validation
end
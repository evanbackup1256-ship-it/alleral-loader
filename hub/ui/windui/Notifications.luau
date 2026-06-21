-- Alleral V11 — WindUI notifications (glass, sanitized)
return function(WindUI, Bootstrap)
	local Notifications = {}
	local DEBOUNCE = {}

	local TYPE_META = {
		info = { icon = "info", color = Color3.fromHex("#8B5CF6") },
		success = { icon = "check", color = Color3.fromHex("#22C55E") },
		warning = { icon = "alert-triangle", color = Color3.fromHex("#F59E0B") },
		error = { icon = "x", color = Color3.fromHex("#EF4444") },
	}

	local function stamp()
		local t = os.date("%H:%M")
		return t or ""
	end

	function Notifications.push(WindUIRef, title, body, ntype, duration)
		if not WindUIRef or type(WindUIRef.Notify) ~= "function" then
			return nil
		end
		title = Bootstrap.sanitize(title, 80)
		if title == "" then title = "Alleral" end
		body = Bootstrap.sanitize(body, 240)
		duration = math.max(1, tonumber(duration) or 4)
		ntype = tostring(ntype or "info"):lower()
		local meta = TYPE_META[ntype] or TYPE_META.info

		local key = title .. "|" .. body
		local now = tick()
		if DEBOUNCE[key] and now - DEBOUNCE[key] < 3 then
			return nil
		end
		DEBOUNCE[key] = now

		local content = body
		if body ~= "" then
			content = body .. "\n" .. stamp()
		end

		pcall(function()
			WindUIRef:Notify({
				Title = title,
				Content = content,
				Desc = content,
				Icon = meta.icon,
				Duration = duration,
				CanClose = true,
			})
		end)
		return true
	end

	function Notifications.clear() end

	return Notifications
end
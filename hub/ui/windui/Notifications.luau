-- Alleral V11.5 — type-accented notifications (rate-limited)
return function(WindUI, Bootstrap)
	local Notifications = {}
	local DEBOUNCE = {}
	local BUSY = false
	local VISIBLE = 0
	local MAX_VISIBLE = 4
	local COOLDOWN = 5

	local TYPE_META = {
		info = { icon = "info", color = "#6366F1" },
		success = { icon = "check", color = "#34D399" },
		warning = { icon = "alert-triangle", color = "#FBBF24" },
		error = { icon = "x", color = "#F87171" },
	}

	local function stripTrace(text)
		text = Bootstrap.sanitize(text, 240)
		text = text:gsub("stack overflow", "UI error")
		text = text:gsub(":[%d]+: ", " ")
		text = text:gsub("\t", " ")
		return text
	end

	local function stamp()
		return os.date("%H:%M") or ""
	end

	function Notifications.push(WindUIRef, title, body, ntype, duration)
		if BUSY then
			return nil
		end
		if not WindUIRef or type(WindUIRef.Notify) ~= "function" then
			return nil
		end
		if VISIBLE >= MAX_VISIBLE then
			return nil
		end

		title = Bootstrap.sanitize(title, 80)
		if title == "" then
			title = "Alleral"
		end
		body = stripTrace(body)
		duration = math.max(1, tonumber(duration) or 4)
		ntype = tostring(ntype or "info"):lower()
		local meta = TYPE_META[ntype] or TYPE_META.info

		local key = title .. "|" .. body
		local now = tick()
		if DEBOUNCE[key] and now - DEBOUNCE[key] < COOLDOWN then
			return nil
		end
		DEBOUNCE[key] = now

		local content = body
		if body ~= "" then
			content = body .. "\n" .. stamp()
		end

		BUSY = true
		VISIBLE = VISIBLE + 1
		pcall(function()
			WindUIRef:Notify({
				Title = title,
				Content = content,
				Desc = content,
				Icon = meta.icon,
				IconColor = Color3.fromHex(meta.color),
				Color = Color3.fromHex(meta.color),
				Duration = duration,
				CanClose = true,
			})
		end)
		task.delay(duration + 0.5, function()
			VISIBLE = math.max(0, VISIBLE - 1)
		end)
		BUSY = false
		return true
	end

	function Notifications.clear()
		VISIBLE = 0
	end

	return Notifications
end
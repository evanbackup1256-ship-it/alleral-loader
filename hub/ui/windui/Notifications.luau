-- Alleral V11 — WindUI notifications
return function(WindUI, Bootstrap)
	local Notifications = {}

	local DEBOUNCE = {}

	function Notifications.push(WindUIRef, title, body, ntype, duration)
		if not WindUIRef or type(WindUIRef.Notify) ~= "function" then
			return nil
		end
		title = Bootstrap.safeText(title, 80)
		body = Bootstrap.safeText(body, 240)
		duration = math.max(1, tonumber(duration) or 4)
		ntype = tostring(ntype or "info"):lower()

		local key = title .. "|" .. body
		local now = tick()
		if DEBOUNCE[key] and now - DEBOUNCE[key] < 3 then
			return nil
		end
		DEBOUNCE[key] = now

		local icon = "info"
		if ntype == "success" then icon = "check"
		elseif ntype == "error" then icon = "x"
		elseif ntype == "warning" then icon = "alert-triangle"
		end

		pcall(function()
			WindUIRef:Notify({
				Title = title,
				Content = body,
				Icon = icon,
				Duration = duration,
			})
		end)
		return true
	end

	function Notifications.clear()
		-- WindUI toasts auto-dismiss; nothing to clear globally
	end

	return Notifications
end
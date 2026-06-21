-- Alleral V12 — notification shim (use NotificationManager from Init)
return function(WindUI, Bootstrap)
	local Notifications = {}

	function Notifications.push(WindUIRef, title, body, ntype, duration)
		title = Bootstrap.sanitize(title, 80)
		body = Bootstrap.sanitize(body, 240)
		if not WindUIRef or type(WindUIRef.Notify) ~= "function" then
			return nil
		end
		pcall(function()
			WindUIRef:Notify({
				Title = title ~= "" and title or "Alleral",
				Content = body,
				Duration = math.max(1, tonumber(duration) or 4),
				Type = tostring(ntype or "info"),
			})
		end)
		return true
	end

	function Notifications.clear() end

	function Notifications.stats()
		return { queued = 0, active = 0 }
	end

	return Notifications
end
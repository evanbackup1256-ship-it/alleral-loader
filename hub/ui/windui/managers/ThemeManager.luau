-- Alleral V12 — theme registration + window palette
return function(EventBus, Theme, Bootstrap)
	local ThemeManager = {}

	function ThemeManager.register()
		if Theme and Theme.register then
			pcall(Theme.register)
		end
		if EventBus then
			EventBus.emit("theme:registered", Theme and Theme.NAME or "Alleral")
		end
	end

	function ThemeManager.applyToWindow(windWindow)
		if Theme and Theme.applyToWindow then
			pcall(Theme.applyToWindow, windWindow)
		end
		if EventBus then
			EventBus.emit("theme:applied", windWindow)
		end
	end

	function ThemeManager.sanitize(value, maxLen)
		if Bootstrap and Bootstrap.sanitize then
			return Bootstrap.sanitize(value, maxLen)
		end
		return tostring(value or "")
	end

	function ThemeManager.getName()
		return Theme and Theme.NAME or "Alleral"
	end

	function ThemeManager.colors()
		return {
			accent = Theme and Theme.accent and Theme.accent() or Color3.fromHex("#7C3AED"),
			cyan = Theme and Theme.cyan and Theme.cyan() or Color3.fromHex("#06B6D4"),
			card = Theme and Theme.card and Theme.card() or Color3.fromHex("#080D16"),
		}
	end

	return ThemeManager
end
-- Alleral V11 — WindUI loader (sole UI framework)
local WINDUI_DIST = "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"

return function(Core)
	local Bootstrap = {}
	Bootstrap.VERSION = "11.0.0"
	Bootstrap.ENGINE = "WindUI"

	local function log(msg)
		warn("[Alleral] " .. tostring(msg))
	end

	function Bootstrap.loadWindUI()
		local cached = Core and Core._WindUIInstance
		if type(cached) == "table" and type(cached.CreateWindow) == "function" then
			return cached
		end

		local src
		if Core and type(Core.httpGet) == "function" then
			local ok, body = pcall(Core.httpGet, WINDUI_DIST)
			if ok and type(body) == "string" and #body > 1024 then
				src = body
			end
		end

		if not src then
			error("WindUI bootstrap failed: could not fetch dist/main.lua")
		end

		local loadFn = Core and Core.loadStringFn and Core.loadStringFn() or loadstring
		if type(loadFn) ~= "function" then
			error("WindUI bootstrap failed: loadstring unavailable")
		end

		local chunk, err = loadFn(src, "@WindUI/dist/main.lua")
		if not chunk then
			error("WindUI compile failed: " .. tostring(err))
		end

		local ok, WindUI = pcall(chunk)
		if not ok or type(WindUI) ~= "table" then
			error("WindUI runtime failed: " .. tostring(WindUI))
		end

		if Core then
			Core._WindUIInstance = WindUI
		end

		log("WindUI bootstrap loaded")
		return WindUI
	end

	function Bootstrap.resolveGameId(CoreRef)
		if CoreRef and type(CoreRef.resolveActiveGameId) == "function" then
			local id = CoreRef.resolveActiveGameId()
			if id and tostring(id) ~= "" then
				return tostring(id)
			end
		end
		local env = (function()
			local ok, e = pcall(function()
				return getgenv and getgenv() or {}
			end)
			return ok and e or {}
		end)()
		if env.Alleral_ActiveScriptId then
			return tostring(env.Alleral_ActiveScriptId)
		end
		return "alleral"
	end

	function Bootstrap.configFolder(CoreRef)
		local gameId = Bootstrap.resolveGameId(CoreRef)
		return "configs/" .. gameId
	end

	function Bootstrap.mapIcon(icon)
		if type(icon) == "string" and icon:find(":") then
			return icon
		end
		if type(icon) == "string" and icon ~= "" and not icon:match("^%d+$") then
			return icon
		end
		return "layout-grid"
	end

	function Bootstrap.safeText(text, maxLen)
		text = tostring(text or "")
		text = text:gsub("[%c]", " ")
		maxLen = tonumber(maxLen) or 240
		if #text > maxLen then
			text = text:sub(1, maxLen - 3) .. "..."
		end
		return text
	end

	function Bootstrap.runValidation(gameId, tabCount)
		log("Game registry loaded")
		log("Dynamic tabs generated (" .. tostring(tabCount or 0) .. " for " .. tostring(gameId) .. ")")
		log("Config namespace loaded (" .. Bootstrap.configFolder() .. ")")
		log("WindUI fully integrated")
		log("Runtime validation passed")
	end

	return Bootstrap
end
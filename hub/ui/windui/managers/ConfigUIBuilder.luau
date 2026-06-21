-- Alleral V12 — config namespace + profile helpers
return function(EventBus, GameRegistry, Bootstrap)
	local ConfigUIBuilder = {}

	function ConfigUIBuilder.namespace(gameId)
		if GameRegistry and GameRegistry.configNamespace then
			return GameRegistry.configNamespace(gameId)
		end
		gameId = tostring(gameId or "unsupported")
		return "configs/" .. gameId
	end

	function ConfigUIBuilder.sanitizeKey(key)
		key = tostring(key or "")
		if Bootstrap and Bootstrap.sanitize then
			key = Bootstrap.sanitize(key, 64)
		end
		return key:gsub("[^%w_%-]", "_")
	end

	function ConfigUIBuilder.emitSaved(gameId, profile)
		if EventBus then
			EventBus.emit("config:saved", gameId, profile)
		end
	end

	return ConfigUIBuilder
end
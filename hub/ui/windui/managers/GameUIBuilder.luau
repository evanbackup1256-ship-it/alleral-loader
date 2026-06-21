-- Alleral V12 — game-aware UI builder helpers
return function(EventBus, GameTabSchemas, TabManager, Bootstrap)
	local GameUIBuilder = {}

	function GameUIBuilder.getNavigation(gameId)
		if GameTabSchemas and GameTabSchemas.get then
			return GameTabSchemas.get(gameId)
		end
		return nil
	end

	function GameUIBuilder.suggestTabOrder(gameId)
		local schema = GameUIBuilder.getNavigation(gameId)
		if not schema then
			return {}
		end
		local out = {}
		for _, tab in ipairs(schema) do
			table.insert(out, {
				name = tab.name or tab.Name,
				icon = tab.icon or tab.Icon or "layout-grid",
			})
		end
		return out
	end

	function GameUIBuilder.afterTabBuild(window, gameId)
		if TabManager and TabManager.validate then
			pcall(TabManager.validate, window, gameId)
		end
		if EventBus then
			EventBus.emit("gameui:built", gameId)
		end
	end

	function GameUIBuilder.sanitize(value, maxLen)
		if Bootstrap and Bootstrap.sanitize then
			return Bootstrap.sanitize(value, maxLen)
		end
		return tostring(value or "")
	end

	return GameUIBuilder
end
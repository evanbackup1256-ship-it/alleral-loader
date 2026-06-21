-- Alleral V12 — per-game dynamic tab registry (schema-driven)
return function(GameRegistry, Cache, GameTabSchemas)
	local Tabs = {}
	Tabs._registry = {}

	function Tabs.register(gameId, tabDef)
		gameId = tostring(gameId or "unsupported")
		Tabs._registry[gameId] = Tabs._registry[gameId] or {}
		table.insert(Tabs._registry[gameId], tabDef)
		if Cache then
			Cache.tabs[gameId] = Tabs._registry[gameId]
		end
	end

	function Tabs.getForGame(gameId)
		gameId = tostring(gameId or "unsupported")
		local list = Tabs._registry[gameId]
		if type(list) == "table" and #list > 0 then
			return list
		end
		if GameTabSchemas and GameTabSchemas.get then
			local schema = GameTabSchemas.get(gameId)
			if type(schema) == "table" and #schema > 0 then
				local out = {}
				for _, tab in ipairs(schema) do
					table.insert(out, {
						Name = tab.name or tab.Name,
						Icon = tab.icon or tab.Icon or "layout-grid",
					})
				end
				return out
			end
		end
		if GameRegistry and not GameRegistry.isSupported(gameId) then
			return {
				{ Name = "Main", Icon = "home" },
				{ Name = "Settings", Icon = "settings" },
				{ Name = "Configs", Icon = "folder" },
			}
		end
		return {}
	end

	function Tabs.clear(gameId)
		if gameId then
			Tabs._registry[tostring(gameId)] = nil
		else
			Tabs._registry = {}
		end
	end

	return Tabs
end
-- Alleral V11.2 — per-game dynamic tab registry
return function(GameRegistry, Cache)
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
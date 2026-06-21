-- Alleral V11 — dynamic tab registry (runtime-built per active game)
return function()
	local Tabs = {}
	Tabs._registry = {}

	function Tabs.register(gameId, tabDef)
		gameId = tostring(gameId or "alleral")
		Tabs._registry[gameId] = Tabs._registry[gameId] or {}
		table.insert(Tabs._registry[gameId], tabDef)
	end

	function Tabs.getForGame(gameId)
		gameId = tostring(gameId or "alleral")
		local list = Tabs._registry[gameId]
		if type(list) == "table" and #list > 0 then
			return list
		end
		return {
			{ Name = "Main", Icon = "home" },
			{ Name = "Settings", Icon = "settings" },
			{ Name = "Configs", Icon = "folder" },
		}
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
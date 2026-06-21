-- Alleral V12 — game-specific tab schema validation
return function(EventBus, GameTabSchemas, Bootstrap, GameRegistry)
	local TabManager = {}
	local validated = {}

	function TabManager.getSchema(gameId)
		if GameTabSchemas and GameTabSchemas.get then
			return GameTabSchemas.get(gameId)
		end
		return nil
	end

	function TabManager.expectedNames(gameId)
		if GameTabSchemas and GameTabSchemas.names then
			return GameTabSchemas.names(gameId)
		end
		return {}
	end

	function TabManager.validate(window, gameId)
		gameId = tostring(gameId or "unsupported")
		if validated[gameId] then
			return true
		end
		validated[gameId] = true

		local schema = TabManager.getSchema(gameId)
		if not schema or #schema == 0 then
			return true
		end

		local built = {}
		if type(window) == "table" and type(window._tabs) == "table" then
			for _, tab in ipairs(window._tabs) do
				if tab and tab._name then
					built[tab._name] = true
				end
			end
		end

		local missing = {}
		for _, def in ipairs(schema) do
			local name = def.name or def.Name
			if name and not built[name] then
				table.insert(missing, name)
			end
		end

		if #missing > 0 and EventBus then
			EventBus.emit("tabs:missing", gameId, missing)
		end

		if #missing > 0 then
			pcall(function()
				local Log = getgenv and getgenv().Alleral_Log
				if Log and Log.warn then
					local msg = "Tab schema missing: " .. table.concat(missing, ", ")
					if Bootstrap and Bootstrap.sanitize then
						msg = Bootstrap.sanitize(msg, 200)
					end
					Log.warn(msg)
				end
			end)
		end

		if GameRegistry and GameRegistry.get then
			local meta = GameRegistry.get(gameId)
			if meta then
				meta.uiTabs = schema
			end
		end

		return #missing == 0
	end

	function TabManager.onTabAdded(window, tab)
		if EventBus then
			EventBus.emit("tab:added", window, tab and tab._name)
		end
	end

	function TabManager.clearCache(gameId)
		if gameId then
			validated[tostring(gameId)] = nil
		else
			validated = {}
		end
	end

	return TabManager
end
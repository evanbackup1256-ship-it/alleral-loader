-- Alleral V11.2 — per-game UI cache (tabs/pages/controls keyed by game_id)
return function()
	local Cache = {
		currentGameId = nil,
		windows = {},
		tabs = {},
		pages = {},
		controls = {},
		callbacks = {},
		dropdowns = {},
		tooltips = {},
		search = {},
	}

	function Cache.setGame(gameId)
		gameId = tostring(gameId or "unsupported")
		if Cache.currentGameId and Cache.currentGameId ~= gameId then
			Cache.clearGame(Cache.currentGameId)
		end
		Cache.currentGameId = gameId
		return gameId
	end

	function Cache.clearGame(gameId)
		gameId = tostring(gameId or "")
		if gameId == "" then
			return
		end
		local win = Cache.windows[gameId]
		if type(win) == "table" and win.Unload then
			pcall(function() win:Unload() end)
		end
		Cache.windows[gameId] = nil
		Cache.tabs[gameId] = nil
		Cache.pages[gameId] = nil
		Cache.controls[gameId] = nil
		Cache.callbacks[gameId] = nil
		Cache.dropdowns[gameId] = nil
		Cache.tooltips[gameId] = nil
		Cache.search[gameId] = nil
	end

	function Cache.clearAll()
		for gameId in pairs(Cache.windows) do
			Cache.clearGame(gameId)
		end
		Cache.currentGameId = nil
	end

	function Cache.getWindow(gameId)
		return Cache.windows[tostring(gameId or Cache.currentGameId or "")]
	end

	function Cache.setWindow(gameId, window)
		gameId = tostring(gameId or Cache.currentGameId or "unsupported")
		Cache.windows[gameId] = window
	end

	function Cache.trackTab(gameId, tab)
		gameId = tostring(gameId or Cache.currentGameId or "unsupported")
		Cache.tabs[gameId] = Cache.tabs[gameId] or {}
		table.insert(Cache.tabs[gameId], tab)
	end

	function Cache.stats()
		local gameId = Cache.currentGameId or "none"
		local tabs = Cache.tabs[gameId]
		return {
			gameId = gameId,
			windows = Cache.windows[gameId] ~= nil,
			tabs = type(tabs) == "table" and #tabs or 0,
			pages = type(Cache.pages[gameId]) == "table" and #Cache.pages[gameId] or 0,
		}
	end

	return Cache
end
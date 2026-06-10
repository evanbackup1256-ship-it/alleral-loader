local Core = {}
Core.VERSION = "1.6"

local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local STARLIGHT_REMOTE_URLS = {
	"https://raw.githubusercontent.com/evanbackup1256-ship-it/kick/main/vendor/starlight/Source.lua",
	"https://raw.githubusercontent.com/Nebula-Softworks/Starlight-Interface-Suite/master/Source.lua",
}
local STARLIGHT_LOCAL_FILES = {
	"vendor/starlight/Source.lua",
	"vendor/starlight/init.luau",
	"starlight/Source.lua",
	"kick/vendor/starlight/Source.lua",
	"kick/kick/vendor/starlight/Source.lua",
}

local function genv()
	local ok, env = pcall(function()
		return getgenv and getgenv() or getfenv()
	end)
	return ok and env or {}
end

local ENV = genv()

function Core.notify(title, text, duration)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = title or "Alleral",
			Text = text or "",
			Duration = duration or 4,
		})
	end)
end

function Core.requestFunction()
	local candidates = {
		type(ENV.syn) == "table" and ENV.syn.request or nil,
		type(ENV.fluxus) == "table" and ENV.fluxus.request or nil,
		type(ENV.http) == "table" and ENV.http.request or nil,
		type(ENV.http_service) == "table" and ENV.http_service.request or nil,
		type(ENV.Xeno) == "table" and ENV.Xeno.request or nil,
		type(ENV.Volt) == "table" and ENV.Volt.request or nil,
		type(ENV.Madium) == "table" and ENV.Madium.request or nil,
		type(ENV.Nihon) == "table" and ENV.Nihon.request or nil,
		type(ENV.Cryptic) == "table" and ENV.Cryptic.request or nil,
		type(ENV.Sentinel) == "table" and ENV.Sentinel.request or nil,
		type(ENV.Serenity) == "table" and ENV.Serenity.request or nil,
		type(ENV.Atlantis) == "table" and ENV.Atlantis.request or nil,
		type(ENV.Zorara) == "table" and ENV.Zorara.request or nil,
		type(ENV.Wave) == "table" and ENV.Wave.request or nil,
		type(ENV.Electron) == "table" and ENV.Electron.request or nil,
		type(ENV.Potassium) == "table" and ENV.Potassium.request or nil,
		type(ENV.Velocity) == "table" and ENV.Velocity.request or nil,
		type(ENV.Krnl) == "table" and ENV.Krnl.request or nil,
		type(ENV.jjsploit) == "table" and ENV.jjsploit.request or nil,
		type(ENV.Bunni) == "table" and ENV.Bunni.request or nil,
		type(ENV.Valyse) == "table" and ENV.Valyse.request or nil,
		type(ENV.Krypton) == "table" and ENV.Krypton.request or nil,
		type(ENV.Evon) == "table" and ENV.Evon.request or nil,
		type(ENV.delta) == "table" and ENV.delta.request or nil,
		type(ENV.celery) == "table" and ENV.celery.request or nil,
		ENV.http_request,
		ENV.request,
		ENV.Request,
	}
	for _, name in ipairs({ "http_request", "request", "Request" }) do
		local fn = ENV[name]
		if type(fn) == "function" then
			table.insert(candidates, 1, fn)
		end
	end
	for _, candidate in ipairs(candidates) do
		if type(candidate) == "function" then
			return candidate
		end
	end
	if type(HttpService.RequestAsync) == "function" then
		return function(opts)
			return HttpService:RequestAsync({
				Url = opts.Url,
				Method = opts.Method or "GET",
				Headers = opts.Headers,
				Body = opts.Body,
			})
		end
	end
	return nil
end

local function trimText(value)
	return tostring(value or ""):gsub("^%s*(.-)%s*$", "%1")
end

function Core.normalizeWebhookUrl(url)
	local text = trimText(url)
	if text == "" then
		return nil, "Webhook URL is empty."
	end
	if not text:find("^https://") and not text:find("^http://") then
		text = "https://" .. text
	end
	if
		not text:find("discord%.com/api/webhooks/")
		and not text:find("discordapp%.com/api/webhooks/")
	then
		return nil, "That doesn't look like a Discord webhook URL."
	end
	return text, nil
end

function Core.postWebhook(url, payload)
	local sender = Core.requestFunction()
	if not sender then
		return false, "HTTP is not available in this executor."
	end
	local postUrl, urlError = Core.normalizeWebhookUrl(url)
	if not postUrl then
		return false, urlError
	end
	local ok, response = pcall(function()
		return sender({
			Url = postUrl,
			Method = "POST",
			Headers = { ["Content-Type"] = "application/json" },
			Body = HttpService:JSONEncode(payload),
		})
	end)
	if not ok then
		return false, tostring(response)
	end
	if type(response) == "table" then
		if response.Success == false then
			local code = response.StatusCode or response.Status or response.status_code
			return false, "Webhook failed (HTTP " .. tostring(code or "?") .. ")"
		end
		local code = response.StatusCode or response.Status or response.status_code
		if type(code) == "number" and (code < 200 or code >= 300) then
			return false, "Webhook returned HTTP " .. tostring(code)
		end
	end
	return true, nil
end

function Core.loadStringFn()
	return ENV.loadstring or loadstring
end

function Core.readFile(path)
	local readFile = ENV.readfile
	local isFile = ENV.isfile
	if type(readFile) ~= "function" or type(isFile) ~= "function" or not isFile(path) then
		return nil
	end
	local ok, data = pcall(readFile, path)
	return ok and data or nil
end

function Core.writeFile(path, data)
	local writeFile = ENV.writefile
	local makeFolder = ENV.makefolder
	if type(writeFile) ~= "function" then
		return false
	end
	pcall(function()
		if type(makeFolder) == "function" then
			makeFolder("Alleral_Configs")
		end
	end)
	return pcall(writeFile, path, data)
end

function Core.patchStarlightSource(source)
	if not source or source == "" then
		return source
	end
	if source:find("Alleral%-1") or source:find("Alleral Rewrite") then
		return source
	end
	source = source:gsub(
		"function Tab:Show%(%)[\r\n]+%s*if Library%.ActiveTab then",
		"function Tab:Show()\n\t\t\tif Library.ActiveTab == Tab then\n\t\t\t\treturn\n\t\t\tend\n\t\t\tif Library.ActiveTab then"
	)
	local inputStart = source:find("function Groupbox:CreateInput", 1, true)
	local labelStart = inputStart and source:find("function Groupbox:CreateLabel", inputStart, true)
	if not inputStart or not labelStart then
		return source
	end
	local before = source:sub(1, inputStart - 1)
	local block = source:sub(inputStart, labelStart - 1)
	local after = source:sub(labelStart)
	block = block:gsub(
		"(Element%.Instance = GroupboxTemplateInstance%.Input_TEMPLATE:Clone%(%)[\r\n]+%s*Element%.Instance%.Visible = true)",
		"%1\n\t\t\t\t\t\tElement.Instance.Parent = Groupbox.ParentingItem",
		1
	)
	block = block:gsub(
		"\n%s*Element%.Instance%.Parent = Groupbox%.ParentingItem\n\n%s*(Starlight%.Window%.TabSections%[Name%]%.Tabs%[TabIndex%]%.Groupboxes%[GroupIndex%]%.Elements%[Index%] = Element)",
		"\n\n\t\t\t\t\t%1",
		1
	)
	return before .. block .. after
end

local function compileStarlightSource(source, label)
	local loadStringFn = Core.loadStringFn()
	if not loadStringFn or not source or source == "" then
		return nil, "Empty Starlight source"
	end
	local compiled, compileErr = loadStringFn(Core.patchStarlightSource(source), label)
	if not compiled then
		return nil, tostring(compileErr)
	end
	local ok, result = pcall(compiled)
	if ok and type(result) == "table" and type(result.CreateWindow) == "function" then
		return result
	end
	return nil, ok and "Invalid Starlight library" or tostring(result)
end

function Core.loadStarlight()
	if ENV.Alleral_Starlight and type(ENV.Alleral_Starlight.CreateWindow) == "function" then
		return ENV.Alleral_Starlight
	end

	local loadStringFn = Core.loadStringFn()
	if not loadStringFn then
		return nil, "loadstring unavailable"
	end

	for _, path in ipairs(STARLIGHT_LOCAL_FILES) do
		local source = Core.readFile(path)
		if source then
			local starlight, err = compileStarlightSource(source, "@Starlight/local")
			if starlight then
				ENV.Alleral_Starlight = starlight
				return starlight
			end
			warn("[Alleral] Local Starlight failed (" .. path .. "): " .. tostring(err))
		end
	end

	local function fetchRemoteSource(url)
		local sep = url:find("?") and "&" or "?"
		local fetchUrl = url .. sep .. "nocache=" .. tostring(math.random(10000, 99999))
		if type(game.HttpGet) == "function" then
			local ok, body = pcall(game.HttpGet, game, fetchUrl, true)
			if ok and body and body ~= "" and not body:find("404: Not Found") then
				return body
			end
		end
		local httpGet = Core.requestFunction()
		if httpGet then
			local ok, response = pcall(httpGet, { Url = fetchUrl, Method = "GET" })
			if ok and response then
				local body = response.Body or response.body or (type(response) == "string" and response)
				if body and body ~= "" and not body:find("404: Not Found") then
					return body
				end
			end
		end
		return nil
	end

	local lastErr = "HTTP unavailable and no local Starlight found"
	for _, url in ipairs(STARLIGHT_REMOTE_URLS) do
		local source = fetchRemoteSource(url)
		if source then
			local starlight, err = compileStarlightSource(source, "@Starlight/remote")
			if starlight then
				ENV.Alleral_Starlight = starlight
				return starlight
			end
			lastErr = err or "Invalid Starlight library"
		else
			lastErr = "Starlight download failed: " .. url
		end
	end
	return nil, lastErr
end

function Core.ensureCore()
	if ENV.Alleral_Core then
		return ENV.Alleral_Core
	end
	local loadStringFn = Core.loadStringFn()
	local isFile = ENV.isfile
	local readFile = ENV.readfile
	if type(loadStringFn) ~= "function" or type(isFile) ~= "function" or type(readFile) ~= "function" then
		return nil
	end
	for _, path in ipairs({ "core/alleral_core.luau", "src/alleral_core.luau", "alleral_core.luau" }) do
		if isFile(path) then
			local ok = pcall(loadStringFn(readFile(path), "Alleral/core")())
			if ok and ENV.Alleral_Core then
				return ENV.Alleral_Core
			end
		end
	end
	return nil
end

local function signalBootFailure(message)
	ENV.Alleral_StartupFailed = message
	if ENV.Alleral_State then
		ENV.Alleral_State.StartupFailed = message
	end
	pcall(function()
		if shared then
			shared.Alleral_StartupFailed = message
		end
	end)
	local report = ENV.Alleral_ReportError
	if type(report) == "function" then
		pcall(report, "boot", message)
	end
end

function Core.prepareGame(state)
	state = state or ENV.Alleral_State
	if not state then
		local msg = "Alleral_State missing"
		signalBootFailure(msg)
		return nil, nil, msg
	end
	local core = Core.ensureCore()
	if not core then
		local msg = "Alleral_Core missing, run loader.luau first"
		signalBootFailure(msg)
		return nil, nil, msg
	end
	state.HubRunning = state.HubRunning ~= false
	core.initAnalytics()
	if state.AntiAFK ~= false then
		core.setupAntiAfk(game:GetService("Players").LocalPlayer)
	end
	local starlight, err = core.loadStarlight()
	if not starlight then
		local msg = err or "Starlight unavailable"
		signalBootFailure(msg)
		return nil, nil, msg
	end
	return core, starlight
end

function Core.stopAutomation(state, connections, loopControllers, loops, onStop)
	state.HubRunning = false
	for name, controller in pairs(loopControllers) do
		if controller then
			controller.enabled = false
		end
		loopControllers[name] = nil
	end
	for _, loopState in pairs(loops) do
		loopState.enabled = false
	end
	for key, connection in pairs(connections) do
		if connection and connection.Disconnect then
			pcall(function()
				connection:Disconnect()
			end)
		end
		connections[key] = nil
	end
	if onStop then
		pcall(onStop)
	end
end

function Core.saveSettings(state, keys, filename)
	local payload = {}
	for _, key in ipairs(keys) do
		payload[key] = state[key]
	end
	Core.writeFile("Alleral_Configs/" .. filename, HttpService:JSONEncode(payload))
end

function Core.loadSettings(state, keys, filename)
	local raw = Core.readFile("Alleral_Configs/" .. filename)
	if not raw then
		return
	end
	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	if not ok or type(decoded) ~= "table" then
		return
	end
	for _, key in ipairs(keys) do
		if decoded[key] ~= nil then
			state[key] = decoded[key]
		end
	end
end

function Core.wrapStarlightGroup(groupbox, callbackWrapper)
	local group = {}
	local serial = 0
	local MAX_RENDERED_DROPDOWN_OPTIONS = 50

	local function nextId(name)
		serial += 1
		return tostring(name) .. "_" .. HttpService:GenerateGUID(false):sub(1, 8) .. "_" .. serial
	end

	local function wrap(label, callback)
		callback = callback or function() end
		if not callbackWrapper then
			return callback
		end
		local ok, wrapped = pcall(callbackWrapper, label, callback)
		if ok and type(wrapped) == "function" then
			return wrapped
		end
		return callbackWrapper(callback)
	end

	local function normalizeOptions(values)
		local output = {}
		local seen = {}
		for _, value in ipairs(values or {}) do
			local text = tostring(value)
			if text ~= "" and not seen[text] then
				seen[text] = true
				table.insert(output, text)
			end
		end
		return output
	end

	local function currentSelection(default, multi)
		if type(default) == "table" then
			local copy = {}
			for i, v in ipairs(default) do
				copy[i] = v
			end
			for k, v in pairs(default) do
				if type(k) ~= "number" then
					copy[k] = v
				end
			end
			return copy
		end
		if multi then
			return default and { tostring(default) } or {}
		end
		return tostring(default or "")
	end

	local function compactOptions(values, selected, limit)
		values = normalizeOptions(values)
		limit = limit or MAX_RENDERED_DROPDOWN_OPTIONS
		if #values <= limit then
			return values
		end
		local output = {}
		local seen = {}
		local selectedList = type(selected) == "table" and selected or { selected }
		for _, value in ipairs(selectedList) do
			local text = tostring(value)
			if text ~= "" and not seen[text] then
				seen[text] = true
				table.insert(output, text)
			end
		end
		for _, value in ipairs(values) do
			if #output >= limit then
				break
			end
			if not seen[value] then
				table.insert(output, value)
			end
		end
		return output
	end

	local function waitForElement(element, timeout)
		local started = tick()
		repeat
			if element and element.Instance then
				return true
			end
			task.wait()
		until tick() - started >= (timeout or 3)
		return element and element.Instance ~= nil
	end

	local function setVisible(element, visible)
		waitForElement(element, 1)
		if element and element.Instance then
			element.Instance.Visible = visible
		end
	end

	function group:CreateToggle(name, default, tooltip, callback)
		return groupbox:CreateToggle({
			Name = name,
			CurrentValue = default == true,
			Tooltip = tooltip,
			Callback = wrap(name, callback),
		}, nextId(name))
	end

	function group:CreateSlider(name, min, max, default, callback, tooltip)
		return groupbox:CreateSlider({
			Name = name,
			Range = { min, max },
			Increment = max <= 5 and 0.05 or 1,
			CurrentValue = tonumber(default) or min,
			Tooltip = tooltip,
			Callback = wrap(name, callback),
		}, nextId(name))
	end

	function group:CreateButton(name, callback, tooltip)
		return groupbox:CreateButton({
			Name = name,
			Tooltip = tooltip,
			Callback = wrap(name, callback),
		}, nextId(name))
	end

	function group:CreateInput(name, placeholder, arg3, arg4, arg5)
		local icon, default, callback, tip
		local function isIcon(value)
			local text = tostring(value or "")
			return text:find("rbxassetid") ~= nil or text:match("^%d+$") ~= nil
		end
		if type(arg3) == "function" then
			callback = arg3
			tip = arg4
		elseif type(arg4) == "function" and isIcon(arg3) then
			icon = Core.starlightIcon(arg3)
			callback = arg4
			tip = arg5
		elseif type(arg4) == "function" then
			default = tostring(arg3 or "")
			callback = arg4
			tip = arg5
		else
			icon = Core.starlightIcon(arg3)
			callback = arg4
			tip = arg5
		end
		return groupbox:CreateInput({
			Name = name,
			Icon = icon,
			Placeholder = placeholder,
			PlaceholderText = placeholder,
			CurrentValue = default or "",
			RemoveTextOnFocus = false,
			Tooltip = tip,
			Callback = wrap(name, callback),
		}, nextId(name))
	end

	function group:CreateDropdown(name, options, default, callback, tooltip)
		return groupbox:CreateDropdown({
			Name = name,
			Options = normalizeOptions(options),
			CurrentOption = default,
			Tooltip = tooltip,
			Callback = wrap(name, callback),
		}, nextId(name))
	end

	function group:AddDropdown(id, config)
		config = config or {}
		local multi = config.Multi == true or config.MultiSelection == true
		local values = normalizeOptions(config.Values or config.Options)
		local current = currentSelection(config.Default or config.CurrentValue or config.CurrentOption, multi)
		local label = groupbox:CreateLabel({
			Name = config.Text or config.Name or id,
			Tooltip = config.Tooltip or config.Description,
		}, nextId(id))
		local handle = {
			Values = values,
			Selection = current,
			Dropdown = nil,
			Label = label,
			LastSearch = "",
		}
		local function safeCallback(selection)
			handle.Selection = currentSelection(selection, multi)
			wrap(config.Text or config.Name or id, config.Callback or function() end)(selection)
		end
		local function rebuild(currentValues)
			local nextValues = currentValues or handle.Values
			if config.Searchable then
				nextValues = compactOptions(nextValues, handle.Selection)
			end
			if handle.Dropdown and handle.Dropdown.Set then
				handle.Dropdown:Set({
					Options = nextValues,
					Values = nextValues,
					CurrentOption = handle.Selection,
					CurrentOptions = type(handle.Selection) == "table" and handle.Selection or nil,
					MultipleOptions = multi,
					Placeholder = config.Placeholder or "--",
					Callback = safeCallback,
				})
			end
		end
		if not waitForElement(label, 3) or not (label.Instance and label.Instance:FindFirstChild("DropdownHolder")) then
			function handle:SetValues(newValues, newDefault)
				self.Values = normalizeOptions(newValues)
				self.Selection = currentSelection(newDefault or self.Selection, multi)
			end
			function handle:Refresh(newValues, newDefault)
				self:SetValues(newValues, newDefault)
			end
			function handle:Search(query)
				self.LastSearch = tostring(query or "")
			end
			return handle
		end
		local renderedValues = config.Searchable and compactOptions(values, current) or values
		local dropdown = label:AddDropdown({
			Options = renderedValues,
			Values = renderedValues,
			CurrentOption = current,
			CurrentOptions = multi and current or nil,
			MultipleOptions = multi,
			Placeholder = config.Placeholder or "--",
			Callback = safeCallback,
		}, nextId(id .. "_dd"))
		handle.Dropdown = dropdown
		function handle:SetValues(newValues, newDefault)
			self.Values = normalizeOptions(newValues)
			self.Selection = currentSelection(newDefault or self.Selection, multi)
			rebuild(self.Values)
		end
		function handle:Refresh(newValues, newDefault)
			self:SetValues(newValues, newDefault)
		end
		function handle:Search(query)
			self.LastSearch = tostring(query or "")
			local filtered = self.LastSearch == "" and self.Values
				or compactOptions(Core.filterDropdownOptions(self.Values, self.LastSearch), self.Selection)
			rebuild(filtered)
		end
		if config.Searchable then
			groupbox:CreateInput({
				Name = (config.Text or config.Name or id) .. " filter",
				PlaceholderText = "search...",
				RemoveTextOnFocus = false,
				Callback = wrap((config.Text or config.Name or id) .. " Search", function(text)
					handle:Search(text)
				end),
			}, nextId(id .. "_search"))
		end
		return handle
	end

	function group:CreateLabel(text)
		return groupbox:CreateLabel({
			Name = text,
		}, nextId("label"))
	end

	function group:CreateStatus(label, fields)
		local status = {
			Labels = {},
			LastValues = {},
			Visible = true,
		}
		for key, value in pairs(fields or {}) do
			local rendered = tostring(value)
			status.LastValues[key] = rendered
			status.Labels[key] = groupbox:CreateLabel({
				Name = tostring(key) .. ": " .. rendered,
			}, nextId(label .. "_" .. tostring(key)))
		end
		function status:Update(key, value)
			local rendered = tostring(value)
			if self.LastValues[key] == rendered then
				return
			end
			self.LastValues[key] = rendered
			local row = self.Labels[key]
			if row and row.Set then
				row:Set({ Name = tostring(key) .. ": " .. rendered })
			end
		end
		function status:SetVisible(visible)
			self.Visible = visible
			for _, row in pairs(self.Labels) do
				setVisible(row, visible)
			end
		end
		return status
	end

	function group:CreateDivider()
		return groupbox:CreateDivider()
	end

	return group
end

function Core.starlightIcon(icon)
	return tostring(icon or ""):match("%d+$") or ""
end

function Core.filterDropdownOptions(values, query)
	query = tostring(query or ""):lower()
	if query == "" then
		return values
	end
	local filtered = {}
	for _, value in ipairs(values or {}) do
		if tostring(value):lower():find(query, 1, true) then
			table.insert(filtered, value)
		end
	end
	return filtered
end

function Core.waitForStarlightGroupbox(groupbox, timeout)
	local started = tick()
	repeat
		if groupbox and groupbox.Instance and groupbox.ParentingItem then
			return true
		end
		task.wait()
	until tick() - started >= (timeout or 1.5)
	return groupbox and groupbox.Instance and groupbox.ParentingItem
end

function Core.makeSupervisor(state, loops, controllers, name, interval, callback)
	if controllers[name] then
		controllers[name].enabled = false
		controllers[name] = nil
	end
	local loopState = {
		enabled = true,
		token = HttpService:GenerateGUID(false),
	}
	loops[name] = loopState
	controllers[name] = loopState
	task.spawn(function()
		local token = loopState.token
		while state.HubRunning and loopState.enabled and controllers[name] == loopState and loopState.token == token do
			local ok, err = pcall(callback)
			if not ok then
				Core.reportError("Loop:" .. name, err)
				warn("[Alleral:" .. name .. "] " .. tostring(err))
				task.wait(math.min(5, interval * 2))
			else
				task.wait(interval)
			end
		end
	end)
end

function Core.setupAntiAfk(player)
	local getConnections = ENV.getconnections or ENV.get_signal_cons
	if getConnections then
		for _, connection in ipairs(getConnections(player.Idled)) do
			if connection.Disable then
				connection:Disable()
			elseif connection.Disconnect then
				connection:Disconnect()
			end
		end
	else
		local VirtualUser = game:GetService("VirtualUser")
		player.Idled:Connect(function()
			pcall(function()
				VirtualUser:CaptureController()
				VirtualUser:ClickButton2(Vector2.new(0, 0))
			end)
		end)
	end
	task.spawn(function()
		local VirtualUser = game:GetService("VirtualUser")
		while player.Parent do
			task.wait(120)
			pcall(function()
				local camera = workspace.CurrentCamera
				if not camera then
					return
				end
				VirtualUser:Button2Down(Vector2.new(100, 100), camera.CFrame)
				task.wait(0.2)
				VirtualUser:Button2Up(Vector2.new(100, 100), camera.CFrame)
			end)
		end
	end)
end

function Core.initAnalytics()
	local tracker = ENV.Alleral_Analytics
	if tracker and tracker.Track then
		tracker:Track()
	end
	return tracker
end

function Core.reportError(scope, err, details)
	local reporter = ENV.Alleral_ReportError
	if type(reporter) == "function" then
		pcall(reporter, scope, err, details)
	end
end

function Core.logEvent(category, message, data)
	local logger = ENV.Alleral_LogEvent
	if type(logger) == "function" then
		pcall(logger, category, message, data)
	end
end

ENV.Alleral_Core = Core
return Core

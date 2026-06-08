getgenv().LuxyHub_State = getgenv().LuxyHub_State or {}
local state = getgenv().LuxyHub_State
local eventConnections = {}

local isRestrictedExecutor = false
local executorName = "unknown"
if identifyexecutor then
	executorName = tostring(identifyexecutor()):lower()
	if executorName:find("yub") or executorName:find("yubx") then
		isRestrictedExecutor = true
	end
end
local safeWriteFile = not isRestrictedExecutor and writefile
local safeReadFile = not isRestrictedExecutor and readfile
local safeIsFile = not isRestrictedExecutor and isfile
local safeMakeFolder = not isRestrictedExecutor and makefolder
local safeIsFolder = not isRestrictedExecutor and isfolder
if state.LuxyHub_Unload then
	pcall(state.LuxyHub_Unload)
end

local function cloneDefaultValue(value)
	if type(value) ~= "table" then
		return value
	end
	local clone = {}
	for key, item in pairs(value) do
		clone[key] = cloneDefaultValue(item)
	end
	return clone
end
local defaultState = {
	HubRunning = true,
	AFarm = false,
	APredict = false,
	VolcanoTweenSpeed = 85,
	TBrainrot = { "All" },
	TRarity = { "All" },
	TMutation = { "All" },
	ATrain = false,
	ATrainCollect = false,
	TrainCollectDelay = 20,
	TrainAnchorCFrame = nil,
	IsFlashCollecting = false,
	FlashCollectSession = 0,
	NextFlashCollect = 0,
	NextAutoKickResetAt = 0,
	LastAutoKickMatchAt = 0,
	LastAutoKickActivityAt = 0,
	AutoKickSession = 0,
	A2xTrain = false,
	ACollect = false,
	CollectDelay = 60,
	TUpgrade = { "Any" },
	TUpgradeBase = {},
	MaxUpLevel = 75,
	PlotBrainrotList = { "Any" },
	PlotProtectedList = { "None" },
	ARebirth = false,
	APlotUpgrade = false,
	APlaceBest = false,
	TProtectedBrainrots = {},
	AProtectFilter = false,
	IsPlacingPet = false,
	ABuySpeed = false,
	ABuyWeights = false,
	ABuyBest = false,
	AAutoUpgrade = false,
	AutoUpgradeDelay = 5,
	AFPSBoost = false,
	ARTXShader = false,
	TTargetWeight = "None",
	WeightList = { "None" },
	TSSellBrainrot = { "Any" },
	TSSellRarity = { "Any" },
	TSSellMutation = { "Any" },
	WBBrainrot = { "Any" },
	WBRarity = { "Any" },
	WBMutation = { "Any" },
	WebhookURL = "",
	AWebhook = false,
	AAutoFav = false,
	TriggerFavScan = false,
	AntiAFK = false,
	TTargetWeatherEvent = "None",
	AAutoBattle = false,
	AAutoAcceptBattle = false,
	AAutoSummonWeather = false,
	AAutoMastery = false,
	TargetKickStyle = "Default",
	AAutoKickStyle = false,
	CustomKickPowerPercent = 100,
	BattleRounds = "3",
	BattleGamepass = true,
	BattleMinPlayers = 2,
	MasteryKickPower = 50,
	MasteryResetMethod = "Died",
	TargetMinigameAccuracy = "Perfect",
	KickPowerMode = "Normal",
	StatusFilterBrainrot = { "Any" },
	StatusFilterRarity = { "Any" },
	AutoStatusInterval = 15,
	AutoStatusWebhook = false,
}
for key, value in pairs(defaultState) do
	state[key] = cloneDefaultValue(value)
end
local HttpService = game:GetService("HttpService")
local function getExecutorRequest()
	if syn and syn.request then
		return syn.request
	end
	if http and http.request then
		return http.request
	end
	if http_request then
		return http_request
	end
	if request then
		return request
	end
	if fluxus and fluxus.request then
		return fluxus.request
	end
	if KRNL_LOADED and request then
		return request
	end
	return nil
end
local function trimString(value)
	return tostring(value or ""):gsub("^%s*(.-)%s*$", "%1")
end
local function normalizeWebhookUrl(webhookUrl)
	local url = trimString(webhookUrl)
	if url == "" then
		return nil, "Webhook URL is empty."
	end
	if not url:match("^https://") then
		return nil, "Webhook URL must start with https://."
	end
	if
		not (
			url:match("^https://discord%.com/api/webhooks/%d+/.+")
			or url:match("^https://discordapp%.com/api/webhooks/%d+/.+")
		)
	then
		return nil, "Webhook URL is not a Discord webhook."
	end
	return url, nil
end
local function sendWebhookPayload(webhookUrl, payload)
	local requestFunction = getExecutorRequest()
	if not requestFunction then
		return false, "Executor HTTP request function is unavailable."
	end
	local postUrl, urlError = normalizeWebhookUrl(webhookUrl)
	if not postUrl then
		return false, urlError
	end
	local ok, response = pcall(function()
		return requestFunction({
			["Url"] = postUrl,
			["Method"] = "POST",
			["Headers"] = { ["Content-Type"] = "application/json" },
			["Body"] = HttpService:JSONEncode(payload),
		})
	end)
	if not ok then
		return false, tostring(response)
	end
	local statusCode = response and (response.StatusCode or response.Status or response.status_code)
	if (type(statusCode) == "number") and (statusCode < 200 or statusCode >= 300) then
		return false, "Webhook returned HTTP " .. tostring(statusCode)
	end
	return true, nil
end
local settingsFolder = "LuxyHub_Configs"
local localPlayerForSettings = game:GetService("Players").LocalPlayer
local settingsFile = string.format("%s/KickBlox_Auto_%s.json", settingsFolder, tostring(localPlayerForSettings.UserId))

local savedSettingKeys = {
	"AFarm",
	"APredict",
	"VolcanoTweenSpeed",
	"TBrainrot",
	"TRarity",
	"TMutation",
	"ATrain",
	"ATrainCollect",
	"TrainCollectDelay",
	"A2xTrain",
	"ACollect",
	"CollectDelay",
	"TUpgrade",
	"MaxUpLevel",
	"ARebirth",
	"APlotUpgrade",
	"APlaceBest",
	"TProtectedBrainrots",
	"AProtectFilter",
	"ABuySpeed",
	"ABuyWeights",
	"ABuyBest",
	"AAutoUpgrade",
	"AutoUpgradeDelay",
	"AFPSBoost",
	"ARTXShader",
	"TTargetWeight",
	"TSSellBrainrot",
	"TSSellRarity",
	"TSSellMutation",
	"WBBrainrot",
	"WBRarity",
	"WBMutation",
	"WebhookURL",
	"AWebhook",
	"AAutoFav",
	"AntiAFK",
	"TTargetWeatherEvent",
	"AAutoBattle",
	"AAutoAcceptBattle",
	"AAutoSummonWeather",
	"TargetKickStyle",
	"AAutoKickStyle",
	"BattleRounds",
	"BattleGamepass",
	"BattleMinPlayers",
	"AAutoMastery",
	"MasteryKickPower",
	"MasteryResetMethod",
	"CustomKickPowerPercent",
	"TargetMinigameAccuracy",
	"KickPowerMode",
	"StatusFilterBrainrot",
	"StatusFilterRarity",
	"AutoStatusInterval",
	"AutoStatusWebhook",
}
local function saveSettings()
	if not safeWriteFile then
		return
	end
	local settingsToSave = {}
	for _, key in ipairs(savedSettingKeys) do
		settingsToSave[key] = state[key]
	end
	pcall(function()
		if safeIsFolder and not safeIsFolder(settingsFolder) and safeMakeFolder then
			safeMakeFolder(settingsFolder)
		end
		safeWriteFile(settingsFile, HttpService:JSONEncode(settingsToSave))
	end)
end
local function loadSettings()
	if not safeReadFile or not safeIsFile or not safeIsFile(settingsFile) then
		return
	end
	local ok, loadedSettings = pcall(function()
		local rawSettings = safeReadFile(settingsFile)
		if rawSettings and (rawSettings ~= "") then
			return HttpService:JSONDecode(rawSettings)
		end
		return nil
	end)
	if ok and loadedSettings then
		for key, value in pairs(loadedSettings) do
			if state[key] ~= nil then
				state[key] = value
			end
		end
		pcall(function()
			game:GetService("StarterGui"):SetCore(
				"SendNotification",
				{ ["Title"] = "Luxy Hub", ["Text"] = "Config Loaded Successfully!", ["Duration"] = 3 }
			)
		end)
	end
end
loadSettings()

local uiLibraryFile = "new_ui_library.lua"
local gameDataUrl = "https://raw.githubusercontent.com/Omnie7/Luxy-Core/main/Data/KickBlox.luau"
local uiLibrary, gameData = nil, nil
local function loadLuaSource(source, label)
	if not source or (source == "") then
		warn("[Luxy Hub] Empty source for " .. label .. ".")
		return nil
	end
	local chunk, compileError = loadstring(source)
	if not chunk then
		warn("[Luxy Hub] Failed to compile " .. label .. ": " .. tostring(compileError))
		return nil
	end
	local runOk, result = pcall(chunk)
	if not runOk then
		warn("[Luxy Hub] Failed to run " .. label .. ": " .. tostring(result))
		return nil
	end
	return result or (getgenv and (getgenv().LuxyLib or getgenv().Library))
end
local function loadLocalLua(path, label)
	if loadfile then
		local fileOk, fileChunk = pcall(loadfile, path)
		if fileOk and fileChunk then
			local runOk, result = pcall(fileChunk)
			if runOk then
				return result or (getgenv and (getgenv().LuxyLib or getgenv().Library))
			end
			warn("[Luxy Hub] Failed to run " .. label .. ": " .. tostring(result))
			return nil
		end
	end
	if not safeReadFile then
		return nil
	end
	if safeIsFile then
		local existsOk, exists = pcall(function()
			return safeIsFile(path)
		end)
		if not existsOk or not exists then
			return nil
		end
	end
	local readOk, source = pcall(function()
		return safeReadFile(path)
	end)
	if not readOk or not source or (source == "") then
		return nil
	end
	return loadLuaSource(source, label)
end
local function loadRemoteLua(url, label)
	local fetchOk, source = pcall(function()
		return game:HttpGet(url)
	end)
	if not fetchOk or not source or (source == "") or source:find("404: Not Found") then
		warn("[Luxy Hub] Failed to fetch " .. label .. ".")
		return nil
	end
	return loadLuaSource(source, label)
end
local function normalizeNotificationInfo(info)
	if type(info) ~= "table" then
		return info
	end
	if info.Description == nil then
		info.Description = info.Content or info.Text or info.Message
	end
	if info.Content == nil then
		info.Content = info.Description
	end
	if info.Time == nil then
		info.Time = info.Duration
	end
	if info.Duration == nil then
		info.Duration = info.Time
	end
	return info
end
local function patchUiCompatibility(library)
	if not library then
		return nil
	end
	local savedVisualState = nil
	local function snapshotVisualState()
		local Lighting = game:GetService("Lighting")
		local Terrain = workspace:FindFirstChildOfClass("Terrain")
		local visualState = { ["Lighting"] = {}, ["Terrain"] = nil }
		for _, key in ipairs({
			"GlobalShadows",
			"Brightness",
			"OutdoorAmbient",
			"Ambient",
			"ClockTime",
			"FogEnd",
			"Technology",
		}) do
			pcall(function()
				visualState.Lighting[key] = Lighting[key]
			end)
		end
		if Terrain then
			visualState.Terrain = {
				["WaterWaveSize"] = Terrain.WaterWaveSize,
				["WaterWaveSpeed"] = Terrain.WaterWaveSpeed,
				["WaterReflectance"] = Terrain.WaterReflectance,
				["WaterTransparency"] = Terrain.WaterTransparency,
			}
		end
		return visualState
	end
	local function restoreVisualState()
		if not savedVisualState then
			return
		end
		local Lighting = game:GetService("Lighting")
		for key, value in pairs(savedVisualState.Lighting or {}) do
			pcall(function()
				Lighting[key] = value
			end)
		end
		local Terrain = workspace:FindFirstChildOfClass("Terrain")
		if Terrain and savedVisualState.Terrain then
			for key, value in pairs(savedVisualState.Terrain) do
				pcall(function()
					Terrain[key] = value
				end)
			end
		end
	end
	if type(library.Notify) == "function" then
		local originalNotify = library.Notify
		library.Notify = function(selfOrInfo, infoOrTime, ...)
			if selfOrInfo == library then
				return originalNotify(library, normalizeNotificationInfo(infoOrTime), ...)
			end
			return originalNotify(library, normalizeNotificationInfo(selfOrInfo), infoOrTime, ...)
		end
	end
	if type(library.CreateNotification) == "function" then
		local originalCreateNotification = library.CreateNotification
		library.CreateNotification = function(selfOrData, maybeData, ...)
			if selfOrData == library then
				return originalCreateNotification(library, normalizeNotificationInfo(maybeData), ...)
			end
			return originalCreateNotification(library, normalizeNotificationInfo(selfOrData), maybeData, ...)
		end
	elseif type(library.Notify) == "function" then
		library.CreateNotification = function(selfOrData, maybeData)
			local data = (selfOrData == library) and maybeData or selfOrData
			return library:Notify(normalizeNotificationInfo(data))
		end
	end
	if type(library.SetRTXMode) ~= "function" then
		library.SetRTXMode = function(_, enabled)
			if enabled and not savedVisualState then
				savedVisualState = snapshotVisualState()
			elseif not enabled then
				restoreVisualState()
				savedVisualState = nil
				return
			end
			local Lighting = game:GetService("Lighting")
			pcall(function()
				settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
			end)
			pcall(function()
				Lighting.GlobalShadows = true
				Lighting.Brightness = math.max(Lighting.Brightness, 2)
				Lighting.FogEnd = 9e9
			end)
		end
	end
	if type(library.SetPotatoMode) ~= "function" then
		library.SetPotatoMode = function(_, enabled)
			if enabled and not savedVisualState then
				savedVisualState = snapshotVisualState()
			elseif not enabled then
				restoreVisualState()
				savedVisualState = nil
				return
			end
			local Lighting = game:GetService("Lighting")
			local Terrain = workspace:FindFirstChildOfClass("Terrain")
			pcall(function()
				settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
			end)
			pcall(function()
				Lighting.GlobalShadows = false
				Lighting.FogEnd = 9e9
			end)
			if Terrain then
				pcall(function()
					Terrain.WaterWaveSize = 0
					Terrain.WaterWaveSpeed = 0
					Terrain.WaterReflectance = 0
					Terrain.WaterTransparency = 1
				end)
			end
		end
	end
	if type(library.GetCustomIcon) == "function" then
		local originalGetCustomIcon = library.GetCustomIcon
		library.GetCustomIcon = function(selfOrIcon, maybeIcon)
			local icon = nil
			if (selfOrIcon == library) and (maybeIcon ~= nil) then
				icon = originalGetCustomIcon(library, maybeIcon)
			else
				icon = originalGetCustomIcon(selfOrIcon, maybeIcon)
			end
			if icon and (icon.Custom == true) then
				icon.Custom = false
			end
			return icon
		end
	end
	return library
end
uiLibrary = patchUiCompatibility(loadLocalLua(uiLibraryFile, "local UI library"))
if not uiLibrary then
	warn("[Luxy Hub] new_ui_library.lua was not available; startup aborted.")
	return
end
gameData = loadRemoteLua(gameDataUrl, "game data")
	or { ["BrainrotOptions"] = {}, ["RarityOptions"] = {}, ["MutationOptions"] = {} }
pcall(function()
	if gameData then
		local temp663 = require(game:GetService("ReplicatedStorage").Shared.Data.MutationData)
		if temp663 and temp663.ValidMutations then
			gameData.MutationOptions = temp663.ValidMutations
		end
	end
end)
local function withAllOption(options)
	local result = { "Any" }
	local seen = { ["Any"] = true, ["All"] = true, ["None"] = true, ["--"] = true }
	for _, option in ipairs(options or {}) do
		if not seen[option] then
			table.insert(result, option)
			seen[option] = true
		end
	end
	return result
end
if gameData then
	gameData.BrainrotOptions = withAllOption(gameData.BrainrotOptions)
	gameData.RarityOptions = withAllOption(gameData.RarityOptions)
	gameData.MutationOptions = withAllOption(gameData.MutationOptions)
end
local function normalizeSelectionList(selection)
	if type(selection) == "string" then
		selection = { selection }
	end
	if type(selection) ~= "table" then
		return { "Any" }
	end
	local normalized = {}
	local seen = {}
	for _, option in ipairs(selection) do
		if (option == "All") or (option == "--") or (option == "None") then
			option = "Any"
		end
		if not seen[option] then
			table.insert(normalized, option)
			seen[option] = true
		end
	end
	return normalized
end
state.TBrainrot = normalizeSelectionList(state.TBrainrot)
state.TRarity = normalizeSelectionList(state.TRarity)
state.TMutation = normalizeSelectionList(state.TMutation)
if not uiLibrary or not gameData then
	pcall(function()
		game:GetService("StarterGui"):SetCore("SendNotification", {
			["Title"] = "Luxy Hub Error",
			["Text"] = "Failed to load Core Libraries! Check F9 Console for details.",
			["Duration"] = 7,
		})
	end)
	return
end
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

state.LuxyHub_Unload = function()
	state.HubRunning = false
	if eventConnections then
		for key, connection in pairs(eventConnections) do
			if connection and connection.Disconnect then
				pcall(function()
					connection:Disconnect()
				end)
			end
			eventConnections[key] = nil
		end
	end
	for key561, item562 in pairs(state) do
		if key561:match("^A") and (type(item562) == "boolean") then
			state[key561] = false
		end
	end
	if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
		LocalPlayer.Character.Humanoid.MaxSlopeAngle = 45
	end
end
local function trackConnection(connection, key)
	if not connection then
		return nil
	end
	if key then
		if eventConnections[key] and eventConnections[key].Disconnect then
			pcall(function()
				eventConnections[key]:Disconnect()
			end)
		end
		eventConnections[key] = connection
	else
		table.insert(eventConnections, connection)
	end
	return connection
end
local function disconnectTrackedConnection(connection)
	if not connection then
		return
	end
	if connection.Disconnect then
		pcall(function()
			connection:Disconnect()
		end)
	end
	for key, trackedConnection in pairs(eventConnections) do
		if trackedConnection == connection then
			eventConnections[key] = nil
		end
	end
end
local function parseAbbreviatedNumber(value)
	if not value then
		return 0
	end
	if type(value) == "number" then
		return value
	end
	local cleanedValue = string.gsub(tostring(value), "[,%s%$]", "")
	local numberText, suffix = string.match(cleanedValue, "^([%d%.]+)(%a*)$")
	if not numberText then
		return tonumber(cleanedValue) or 0
	end
	local numberValue = tonumber(numberText) or 0
	local suffixPowers =
		{ K = 3, M = 6, B = 9, T = 12, Q = 15, ["Qi"] = 18, S = 21, ["Sp"] = 24, O = 27, N = 30, D = 33 }
	if suffix and (suffix ~= "") and suffixPowers[suffix] then
		return numberValue * (10 ^ suffixPowers[suffix])
	end
	return numberValue
end
local function parseNumberLike(value)
	if type(value) == "number" then
		return value
	end
	local textValue = tostring(value)
	local mantissa, exponent = textValue:match("^(%-?[%d%.]+)%s*,%s*(%-?%d+)$")
	if mantissa and exponent then
		return tonumber(mantissa) * (10 ^ tonumber(exponent))
	end
	return parseAbbreviatedNumber(textValue)
end
local currentCoins = 0
local KickServiceClient = nil
pcall(function()
	KickServiceClient = require(game:GetService("ReplicatedStorage").Modules.ServicesLoader.KickServiceClient)
end)
local currentKickLevel = 0
local currentRebirthLevel = 0
pcall(function()
	local balanceService = require(ReplicatedStorage.Modules.ServicesLoader.ClientBalanceService)
	local kickService = require(ReplicatedStorage.Modules.ServicesLoader.KickServiceClient)
	local rebirthService = require(ReplicatedStorage.Modules.ServicesLoader.RebirthServiceClient)
	currentCoins = parseNumberLike(balanceService.Balance)
	trackConnection(balanceService.CoinsChanged:Connect(function(coins)
		currentCoins = parseNumberLike(coins)
	end))
	if kickService.Level then
		currentKickLevel = kickService.Level
	end
	trackConnection(kickService.LevelChanged:Connect(function(level)
		currentKickLevel = level
	end))
	if rebirthService.RebirthLevel then
		currentRebirthLevel = rebirthService.RebirthLevel
	end
	trackConnection(rebirthService.RebirthChanged:Connect(function(rebirthLevel)
		currentRebirthLevel = rebirthLevel
	end))
end)
local function selectionHasWildcard(selection)
	return (not selection) or (#selection == 0) or table.find(selection, "Any") or table.find(selection, "All")
end
local function normalizeFilterText(value)
	local text = tostring(value or "")
	text = text:gsub("^%s*(.-)%s*$", "%1")
	text = text:gsub("[%[%]%(%)%{%}]", " ")
	text = text:gsub("[%s_%-]+", " ")
	text = text:gsub("^%s*(.-)%s*$", "%1")
	return text
end
local function normalizeMutationText(value)
	local text = normalizeFilterText(value)
	if text == "" then
		return "None"
	end
	local lowered = string.lower(text)
	if lowered == "none" or lowered == "nil" or lowered == "normal" or lowered == "no mutation" then
		return "None"
	end
	local eventMultiplier = lowered:match("^x%s*(%d+)$") or lowered:match("^(%d+)%s*x$")
	if eventMultiplier then
		return "x" .. eventMultiplier
	end
	return text
end
local function selectionContainsNormalized(selection, value, normalizer)
	if type(selection) == "string" then
		selection = { selection }
	end
	if selectionHasWildcard(selection) then
		return true
	end
	local normalizedValue = normalizer(value)
	for _, selectedValue in ipairs(selection or {}) do
		if string.lower(normalizer(selectedValue)) == string.lower(normalizedValue) then
			return true
		end
	end
	return false
end
local function matchesMainFilter(brainrotName, mutationName)
	state.TBrainrot = normalizeSelectionList(state.TBrainrot)
	state.TMutation = normalizeSelectionList(state.TMutation)
	local filterBrainrot = not selectionHasWildcard(state.TBrainrot)
	local filterMutation = not selectionHasWildcard(state.TMutation)
	if not filterBrainrot and not filterMutation then
		return true
	end
	local brainrotMatches = not filterBrainrot
		or selectionContainsNormalized(state.TBrainrot, brainrotName, normalizeFilterText)
	local mutationMatches = not filterMutation
		or selectionContainsNormalized(state.TMutation, mutationName, normalizeMutationText)
	if filterMutation and (normalizeMutationText(mutationName) == "None") then
		mutationMatches = false
	end
	return brainrotMatches and mutationMatches
end
local function matchesSelectionFilter(selection, value, rejectNone)
	if type(selection) == "string" then
		selection = { selection }
	end
	if selectionHasWildcard(selection) then
		return true
	end
	if table.find(selection, "None") and not rejectNone then
		return true
	end
	return selectionContainsNormalized(selection, value, rejectNone and normalizeMutationText or normalizeFilterText)
end
local function findPlayerPlot()
	local ok, plotService = pcall(function()
		return require(ReplicatedStorage.Modules.ServicesLoader.ClientPlotService)
	end)
	if ok and plotService and plotService.Model then
		return plotService.Model
	end
	local plotsFolder = Workspace:FindFirstChild("Plots")
		or Workspace:FindFirstChild("Plot")
		or workspace:FindFirstChild("Plots")
	if not plotsFolder then
		return nil
	end
	local localUserId = tostring(LocalPlayer.UserId)
	for _, plot in ipairs(plotsFolder:GetChildren()) do
		local owner = plot:GetAttribute("Owner")
		local ownerId = plot:GetAttribute("OwnerId") or plot:GetAttribute("PlayerId")
		local playerName = plot:GetAttribute("Player")
		if
			(tostring(owner) == LocalPlayer.Name)
			or (tostring(owner) == LocalPlayer.DisplayName)
			or (tostring(owner) == localUserId)
			or (tostring(ownerId) == localUserId)
			or (tostring(playerName) == LocalPlayer.Name)
			or (tostring(playerName) == localUserId)
		then
			return plot
		end
	end
	return nil
end
local function getMutationName(model)
	local mutation = model:GetAttribute("Mutation")
	if mutation and (mutation ~= "") and (mutation ~= "None") then
		return normalizeMutationText(mutation)
	end
	if model.Parent then
		local parentMutation = model.Parent:GetAttribute("Mutation")
		if parentMutation and (parentMutation ~= "") and (parentMutation ~= "None") then
			return normalizeMutationText(parentMutation)
		end
	end
	for _, child in ipairs(model:GetChildren()) do
		local childMutation = normalizeMutationText(child.Name)
		if childMutation ~= "None" and childMutation ~= "Any" then
			if
				gameData.MutationOptions
				and selectionContainsNormalized(gameData.MutationOptions, childMutation, normalizeMutationText)
			then
				return childMutation
			end
		end
	end
	return "None"
end

local networkFolder = ReplicatedStorage:FindFirstChild("Shared")
if networkFolder then
	networkFolder = networkFolder:FindFirstChild("Packages")
end
if networkFolder then
	networkFolder = networkFolder:FindFirstChild("Network")
end
local kickEventRemote = (networkFolder and networkFolder:FindFirstChild("rev_KickEvent"))
	or ReplicatedStorage:FindFirstChild("rev_KickEvent", true)
local collectCashRemote = (networkFolder and networkFolder:FindFirstChild("rev_B_Collect"))
	or ReplicatedStorage:FindFirstChild("rev_B_Collect", true)
local upgradeBrainrotRemote = (networkFolder and networkFolder:FindFirstChild("rev_B_Upgrade"))
	or ReplicatedStorage:FindFirstChild("rev_B_Upgrade", true)
local speedUpgradeRemote = (networkFolder and networkFolder:FindFirstChild("rev_SPEED_UPGRADE"))
	or ReplicatedStorage:FindFirstChild("rev_SPEED_UPGRADE", true)
local shopBuyRemote = (networkFolder and networkFolder:FindFirstChild("rev_Shop_Buy"))
	or ReplicatedStorage:FindFirstChild("rev_Shop_Buy", true)
local weightEquipRemote = (networkFolder and networkFolder:FindFirstChild("rev_WeightEquip"))
	or ReplicatedStorage:FindFirstChild("rev_WeightEquip", true)
local sellAllRemote = (networkFolder and networkFolder:FindFirstChild("ref_B_SellAll"))
	or ReplicatedStorage:FindFirstChild("ref_B_SellAll", true)
local toggleFavoriteRemote = (networkFolder and networkFolder:FindFirstChild("rev_ToggleFav"))
	or ReplicatedStorage:FindFirstChild("rev_ToggleFav", true)
local rebirthRequestRemote = (networkFolder and networkFolder:FindFirstChild("rev_RebirthRequest"))
	or ReplicatedStorage:FindFirstChild("rev_RebirthRequest", true)
local plotUpgradeRemote = (networkFolder and networkFolder:FindFirstChild("rev_bs_upgrade"))
	or ReplicatedStorage:FindFirstChild("rev_bs_upgrade", true)
local weatherSummonRemote = (networkFolder and networkFolder:FindFirstChild("rev_sbe"))
	or ReplicatedStorage:FindFirstChild("rev_sbe", true)
local weightModelsFolder = ReplicatedStorage:FindFirstChild("Objects")
	and ReplicatedStorage.Objects:FindFirstChild("WeightModels")
local function base64Decode(temp274)
	local temp275 = (syn and syn.crypt) or crypt
	if temp275 and temp275.b64decode then
		local temp669, temp670 = pcall(temp275.b64decode, temp274)
		if temp669 then
			return temp670
		end
	end
	local temp276 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	temp274 = string.gsub(temp274, "[^" .. temp276 .. "=]", "")
	return (
		string
			.gsub(temp274, ".", function(arg564)
				local temp565 = 0
				local temp566
				local temp567
				while true do
					if temp565 == 1 then
						for index909 = 6, 1, -1 do
							temp566 = temp566
								.. (
									((((temp567 % (2 ^ index909)) - (temp567 % (2 ^ (index909 - 1)))) > 0) and "1")
									or "0"
								)
						end
						return temp566
					end
					if 0 == temp565 then
						if arg564 == "=" then
							return ""
						end
						temp566, temp567 = "", temp276:find(arg564) - 1
						temp565 = 1
					end
				end
			end)
			:gsub("%d%d%d%d%d%d%d%d", function(arg568)
				local temp569 = 0
				local temp570
				while true do
					if temp569 == 0 then
						temp570 = 0
						for index910 = 1, 8 do
							temp570 = temp570
								+ (((arg568:sub(index910, index910) == "1") and (2 ^ (8 - index910))) or 0)
						end
						temp569 = 1
					end
					if 1 == temp569 then
						return string.char(temp570)
					end
				end
			end)
	)
end
local weightsDataModule = ReplicatedStorage:FindFirstChild("WeightsData", true)
local weightsData = nil
pcall(function()
	if weightsDataModule then
		weightsData = require(weightsDataModule)
	end
end)
local speedData = nil
pcall(function()
	speedData = require(ReplicatedStorage.Shared.Data.SpeedData)
end)
local rebirthData = nil
pcall(function()
	rebirthData = require(ReplicatedStorage.Shared.Data.RebirthData)
end)
local sacrificeData = nil
pcall(function()
	sacrificeData = require(ReplicatedStorage.Shared.Data.SacrificeData)
end)
local weatherServiceClient = nil
pcall(function()
	weatherServiceClient = require(ReplicatedStorage.Modules.ServicesLoader.WeatherService_Client)
end)
local serverLuckClient = nil
pcall(function()
	serverLuckClient = require(game:GetService("ReplicatedStorage").Modules.ServicesLoader.ServerLuckClient)
end)
local weatherRecipeOptions = { "Any" }
if sacrificeData and sacrificeData.Recipes then
	local recipeNames = {}
	for recipeName in pairs(sacrificeData.Recipes) do
		if recipeName then
			table.insert(recipeNames, recipeName)
		end
	end
	table.sort(recipeNames)
	for _, recipeName in ipairs(recipeNames) do
		table.insert(weatherRecipeOptions, recipeName)
	end
end
local function getRebirthKickRequirement(currentRebirth)
	if rebirthData then
		local ok, requirement = pcall(function()
			return rebirthData:GetKickRequirement(currentRebirth + 1)
		end)
		if ok and requirement then
			return parseAbbreviatedNumber(tostring(requirement))
		end
	end
	return math.huge
end
local function getWeightCost(weightName)
	if weightsData and weightsData.Weights and weightsData.Weights[weightName] then
		local cost = weightsData.Weights[weightName].Cost
		if cost then
			return (cost.first or 0) * (10 ^ (cost.second or 0))
		end
	end
	return math.huge
end
local cachedWeightList = nil
local function getSortedWeights()
	if cachedWeightList then
		return cachedWeightList
	end
	local weights = {}
	if weightModelsFolder then
		for _, weightModel in ipairs(weightModelsFolder:GetChildren()) do
			table.insert(weights, { ["name"] = weightModel.Name, ["price"] = getWeightCost(weightModel.Name) })
		end
		table.sort(weights, function(left, right)
			return left.price < right.price
		end)
		cachedWeightList = weights
	end
	return weights
end
local function coerceNumberValue(value)
	if type(value) == "number" then
		return value
	elseif type(value) == "table" then
		local first = value.First or value.first or value[1] or 0
		local second = value.Second or value.second or value[2] or 0
		return tonumber(first) * (10 ^ tonumber(second))
	end
	return parseNumberLike(value)
end
local function getSpeedUpgradeCost(tier)
	if speedData and type(speedData.GetCostForLevel) == "function" then
		local ok, cost = pcall(function()
			return speedData:GetCostForLevel(tier)
		end)
		if ok and cost ~= nil then
			return coerceNumberValue(cost)
		end
	end
	return nil
end
local entitiesData = nil
local brainrotBaseCps = {}
pcall(function()
	local temp286 = 0
	while true do
		if temp286 == 0 then
			entitiesData = require(ReplicatedStorage.Shared.Data.EntitiesData)
			if entitiesData and entitiesData.Brainrots then
				for key970, item971 in pairs(entitiesData.Brainrots) do
					if item971.CPS then
						brainrotBaseCps[key970] = coerceNumberValue(item971.CPS)
					end
				end
			end
			break
		end
	end
end)
local mutationMultiplier = {
	["Golden"] = 1.5,
	["Diamond"] = 2,
	["Plasma"] = 4,
	["Molten"] = 6,
	["Radioactive"] = 8,
	["Void"] = 10,
	["Shadow"] = 12,
	["Electrified"] = 16,
	["Rainbow"] = 30,
	["Virus"] = 10,
	["Wet"] = 16,
	["Alien"] = 22,
	["Bacon"] = 30,
	["Enchanted"] = 12,
	["Phantom"] = 35,
	["Astral"] = 35,
	["Volcanic"] = 35,
}
local function calculateBrainrotCps(brainrotName, mutationName, level)
	level = level or 1
	local baseCps = brainrotBaseCps[brainrotName]
	if not baseCps then
		local normalizedName = string.lower(string.gsub(brainrotName, "[%s%p]", ""))
		for knownName, knownCps in pairs(brainrotBaseCps) do
			if string.lower(string.gsub(knownName, "[%s%p]", "")) == normalizedName then
				baseCps = knownCps
				break
			end
		end
	end
	baseCps = baseCps or 1
	local mutationBoost = (
		mutationName
		and (mutationName ~= "None")
		and (mutationName ~= "")
		and mutationMultiplier[mutationName]
	) or 1
	local levelBoost = 1
	pcall(function()
		levelBoost = 1.25 ^ (level - 1)
	end)
	return baseCps * mutationBoost * levelBoost
end
if uiLibrary.SetTheme then
	uiLibrary:SetTheme("Slate")
end
local mainWindow = uiLibrary:CreateWindow({
	["Title"] = "Luxy Hub 3.9",
	["Footer"] = "Kick A Lucky Block - refined build",
	["Icon"] = "rbxassetid://82246802133344",
	["Size"] = UDim2.fromOffset(790, 540),
	["CornerRadius"] = 8,
	["NotifySide"] = "Left",
	["GlobalSearch"] = true,
	["EnableSidebarResize"] = true,
	["EnableCompacting"] = true,
	["MinSidebarWidth"] = 152,
	["SidebarCompactWidth"] = 54,
	["SidebarCollapseThreshold"] = 0.42,
	["CompactWidthActivation"] = 136,
	["ShowCustomCursor"] = false,
	["ToggleKeybind"] = Enum.KeyCode.RightControl,
})
local mainTab = mainWindow:CreateTab("Main", "rbxassetid://10723407389", "Main agricultural options and predictions")
local autoTab = mainWindow:CreateTab("Automatically", "rbxassetid://10734923214", "Automated accounts manager")
local eventsTab = mainWindow:CreateTab("Events", "rbxassetid://10709789407", "Minigames and weather setups")
local shopTab = mainWindow:CreateTab("Shop", "rbxassetid://10734952479", "Upgrade weights and cosmetics")
local miscTab = mainWindow:CreateTab("Misc", "rbxassetid://10734950020", "Settings and server visual features")
local kickFilterGroup = mainTab:CreateGroup("Kick & Filter", "rbxassetid://10734975692")
local trainCashGroup = mainTab:CreateGroup("Train & Cash", "rbxassetid://10734975692")
local placeBrainrotGroup = autoTab:CreateGroup("Place Brainrot", "rbxassetid://10734975692")
local upgradeBrainrotGroup = autoTab:CreateGroup("Upgrade Brainrot", "rbxassetid://10734975692")
local weightCashGroup = autoTab:CreateGroup("Weight & Cash", "rbxassetid://10734975692")
local cashCollectionGroup = autoTab:CreateGroup("Cash Collection", "rbxassetid://10734975692")
local battleMasteryGroup = eventsTab:CreateGroup("Battle & Mastery", "rbxassetid://10709789407")
local kickMasteryGroup = eventsTab:CreateGroup("Kick Mastery", "rbxassetid://10709789407")
local weatherSummonerGroup = eventsTab:CreateGroup("Weather Summoner", "rbxassetid://10709789407")
local kickingStylesGroup = shopTab:CreateGroup("Kicking Styles", "rbxassetid://10734952479")
local weightSpeedGroup = shopTab:CreateGroup("Weight & Speed", "rbxassetid://10734952479")
local sellFavoriteGroup = shopTab:CreateGroup("Sell & Favorite", "rbxassetid://10734952479")
local serverJoinerGroup = miscTab:CreateGroup("Server Joiner", "rbxassetid://10734950020")
local webhookGroup = miscTab:CreateGroup("Discord Webhook", "rbxassetid://10734950020")
local visualsPerformanceGroup = miscTab:CreateGroup("Visuals & Performance", "rbxassetid://10734950020")
local volcanoTweenConnection = nil
local volcanoTargetPart = nil
local function selectedKeysFromMap(selectionMap)
	local selected = {}
	for key, enabled in pairs(selectionMap or {}) do
		if enabled then
			table.insert(selected, key)
		end
	end
	return selected
end
kickFilterGroup:AddDropdown("FilterBrainrot", {
	["Text"] = "Filter Brainrot",
	["Values"] = gameData.BrainrotOptions,
	["Default"] = state.TBrainrot,
	["Multi"] = true,
	["Searchable"] = true,
	["Callback"] = function(arg293)
		state.TBrainrot = selectedKeysFromMap(arg293)
		saveSettings()
	end,
})
kickFilterGroup:AddDropdown("FilterMutation", {
	["Text"] = "Filter Mutation",
	["Values"] = gameData.MutationOptions,
	["Default"] = state.TMutation,
	["Multi"] = true,
	["Searchable"] = true,
	["Callback"] = function(arg296)
		state.TMutation = selectedKeysFromMap(arg296)
		saveSettings()
	end,
})
kickFilterGroup:CreateDropdown(
	"Minigame Accuracy",
	{ "Bad", "Mid", "Good", "Great", "Excellent", "Perfect", "Cosmic" },
	state.TargetMinigameAccuracy,
	function(arg299)
		state.TargetMinigameAccuracy = ((type(arg299) == "table") and arg299[1]) or tostring(arg299)
		saveSettings()
	end
)
kickFilterGroup:CreateDropdown("Power Scale Mode", { "Normal", "Micro", "Nano" }, state.KickPowerMode, function(arg301)
	state.KickPowerMode = ((type(arg301) == "table") and arg301[1]) or tostring(arg301)
	saveSettings()
end)
kickFilterGroup:CreateSlider("Set Kick Power", 0, 100, state.CustomKickPowerPercent, function(arg303)
	state.CustomKickPowerPercent = arg303
	if KickServiceClient then
		KickServiceClient.Percent = arg303 / 100
	end
	saveSettings()
end)
local predictionStatus = kickFilterGroup:CreateStatus("Prediction HUD", {
	{ ["Title"] = "Brainrot", ["Value"] = "--" },
	{ ["Title"] = "Rarity", ["Value"] = "--" },
	{ ["Title"] = "Mutation", ["Value"] = "--" },
	{ ["Title"] = "CPS Value", ["Value"] = "--" },
})
kickFilterGroup:CreateToggle("Prediction", state.APredict, "Predict your next rolls", function(arg305)
	state.APredict = arg305
	saveSettings()
	if predictionStatus and predictionStatus.SetVisible then
		predictionStatus:SetVisible(arg305)
	end
end)
kickFilterGroup:CreateToggle("Auto Kick", state.AFarm, "Automate blocks kick farm", function(arg308)
	state.AFarm = arg308
	state.AutoKickSession = (state.AutoKickSession or 0) + 1
	state.LastAutoKickActivityAt = tick()
	state.NextAutoKickResetAt = 0
	if arg308 then
		volcanoTargetPart = nil
		local character = LocalPlayer.Character
		local humanoid = character and character:FindFirstChild("Humanoid")
		if humanoid then
			Workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
			Workspace.CurrentCamera.CameraSubject = humanoid
		end
	end
	saveSettings()
	if not state.AFarm and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
		LocalPlayer.Character.Humanoid.MaxSlopeAngle = 45
		volcanoTargetPart = nil
	end
end)
trainCashGroup:CreateToggle(
	"Auto Train + Collect Cash",
	state.ATrainCollect,
	"Auto train weight and claim coins",
	function(arg310)
		state.ATrainCollect = arg310
		if arg310 then
			state.NextFlashCollect = 0
			local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			if rootPart then
				state.TrainAnchorCFrame = rootPart.CFrame
			end
		else
			state.TrainAnchorCFrame = nil
		end
		saveSettings()
	end
)
trainCashGroup:CreateSlider("Cash Collect (Delay)", 1, 60, state.TrainCollectDelay, function(arg312)
	state.TrainCollectDelay = arg312
	state.NextFlashCollect = tick() + (state.TrainCollectDelay * 60)
	saveSettings()
end)
local protectedBrainrotDropdown = placeBrainrotGroup:AddDropdown("ProtectDropdownID", {
	["Text"] = "Protected Brainrots",
	["Values"] = state.PlotProtectedList,
	["Default"] = (state.TProtectedBrainrots or {}),
	["Multi"] = true,
	["Searchable"] = true,
	["Callback"] = function(arg315)
		state.TProtectedBrainrots = selectedKeysFromMap(arg315)
		saveSettings()
	end,
})
protectedBrainrotDropdown.Refresh = function(arg318, arg319)
	arg318:SetValues(arg319)
end
task.spawn(function()
	while state.HubRunning do
		task.wait(5)
		local temp577 = findPlayerPlot()
		local list578 = {}
		if temp577 and temp577:FindFirstChild("Slots") then
			for key837, item838 in ipairs(temp577.Slots:GetChildren()) do
				local temp839 = 0
				local temp840
				while true do
					if temp839 == 0 then
						temp840 = item838:FindFirstChild("PlacedPart")
						if temp840 and temp840:GetAttribute("ID") then
							local temp1130 = temp840:GetAttribute("ID")
							local temp1131 = temp840:GetAttribute("Mutation") or "None"
							local temp1132 = temp840:GetAttribute("Level") or 1
							local temp1133 = string.format("[Lv.%s] %s [%s]", tostring(temp1132), temp1130, temp1131)
							table.insert(list578, temp1133)
						end
						break
					end
				end
			end
		end
		if #list578 == 0 then
			table.insert(list578, "None")
		end
		state.PlotProtectedList = list578
		pcall(function()
			if protectedBrainrotDropdown and protectedBrainrotDropdown.Refresh then
				protectedBrainrotDropdown:Refresh(state.PlotProtectedList)
			end
		end)
	end
end)
placeBrainrotGroup:CreateToggle(
	"Enable Protection",
	state.AProtectFilter,
	"Protect matching filter configurations",
	function(arg320)
		local temp321 = 0
		while true do
			if temp321 == 0 then
				state.AProtectFilter = arg320
				saveSettings()
				break
			end
		end
	end
)
placeBrainrotGroup:CreateToggle(
	"Auto Place Brainrot",
	state.APlaceBest,
	"Auto place best pets in plot",
	function(arg322)
		state.APlaceBest = arg322
		saveSettings()
	end
)
state.TUpgradeBase = {}
local upgradeBrainrotDropdown = upgradeBrainrotGroup:AddDropdown("UpgradeDropdownID", {
	["Text"] = "Filter Brainrot",
	["Values"] = state.PlotBrainrotList,
	["Default"] = (state.TUpgrade or { "Any" }),
	["Multi"] = true,
	["Searchable"] = true,
	["Callback"] = function(arg324)
		state.TUpgrade = selectedKeysFromMap(arg324)
		state.TUpgradeBase = {}
		for _, upgradeName in ipairs(state.TUpgrade) do
			local baseName = string.gsub(upgradeName, "^%[Lv%.%d+%]%s*", "")
			if not table.find(state.TUpgradeBase, baseName) then
				table.insert(state.TUpgradeBase, baseName)
			end
		end
		saveSettings()
	end,
})
upgradeBrainrotDropdown.Refresh = function(arg327, arg328)
	arg327:SetValues(arg328)
end
task.spawn(function()
	while state.HubRunning do
		local temp580 = 0
		local temp581
		while true do
			if 1 == temp580 then
				if temp581 and temp581:FindFirstChild("Slots") then
					local list973 = { "Any" }
					for key1031, item1032 in ipairs(temp581.Slots:GetChildren()) do
						local temp1033 = item1032:FindFirstChild("PlacedPart")
						if temp1033 then
							for key1156, item1157 in ipairs(temp1033:GetChildren()) do
								if item1157:IsA("Model") and not item1157.Name:match("Hitbox") then
									local temp1236 = 0
									local temp1237
									local temp1238
									local temp1239
									while true do
										if temp1236 == 0 then
											temp1237 = getMutationName(item1157)
											temp1238 = item1157:GetAttribute("Level")
												or temp1033:GetAttribute("Level")
												or 1
											temp1236 = 1
										end
										if temp1236 == 1 then
											temp1239 = string.format(
												"[Lv.%s] %s [%s]",
												tostring(temp1238),
												item1157.Name,
												temp1237
											)
											table.insert(list973, temp1239)
											break
										end
									end
								end
							end
						end
					end
					state.PlotBrainrotList = list973
					pcall(function()
						if upgradeBrainrotDropdown and upgradeBrainrotDropdown.Refresh then
							upgradeBrainrotDropdown:Refresh(list973)
						end
					end)
				end
				break
			end
			if 0 == temp580 then
				task.wait(5)
				temp581 = findPlayerPlot()
				temp580 = 1
			end
		end
	end
end)
upgradeBrainrotGroup:CreateSlider("Max Level", 1, 75, state.MaxUpLevel, function(arg329)
	local temp330 = 0
	while true do
		if temp330 == 0 then
			state.MaxUpLevel = arg329
			saveSettings()
			break
		end
	end
end)
upgradeBrainrotGroup:CreateSlider("Upgrade Delay", 1, 30, state.AutoUpgradeDelay, function(arg331)
	state.AutoUpgradeDelay = arg331
	saveSettings()
end)
upgradeBrainrotGroup:CreateToggle(
	"Auto Upgrade Brainrot",
	state.AAutoUpgrade,
	"Auto upgrades slot pets in plot",
	function(arg333)
		state.AAutoUpgrade = arg333
		saveSettings()
	end
)
upgradeBrainrotGroup:CreateToggle(
	"Auto Upgrade Plot",
	state.APlotUpgrade,
	"Automatically upgrade plot slots",
	function(arg335)
		state.APlotUpgrade = arg335
		saveSettings()
	end
)
weightCashGroup:CreateToggle("Auto Train", state.ATrain, "Train weight automatically", function(arg337)
	local temp338 = 0
	while true do
		if temp338 == 0 then
			state.ATrain = arg337
			saveSettings()
			break
		end
	end
end)
weightCashGroup:CreateToggle("Auto Claim 2x", state.A2xTrain, "Auto click 2x bonus rewards", function(arg339)
	local temp340 = 0
	while true do
		if temp340 == 0 then
			state.A2xTrain = arg339
			saveSettings()
			break
		end
	end
end)
weightCashGroup:CreateToggle("Auto Rebirth", state.ARebirth, "Auto rebirth when max value met", function(arg341)
	local temp342 = 0
	while true do
		if temp342 == 0 then
			state.ARebirth = arg341
			saveSettings()
			break
		end
	end
end)
cashCollectionGroup:CreateSlider("Collect Delay", 1, 600, state.CollectDelay, function(arg343)
	state.CollectDelay = arg343
	saveSettings()
end)
cashCollectionGroup:CreateToggle(
	"Auto Collect Cash",
	state.ACollect,
	"Auto collect coins in plot floors",
	function(arg345)
		local temp346 = 0
		while true do
			if temp346 == 0 then
				state.ACollect = arg345
				saveSettings()
				break
			end
		end
	end
)
battleMasteryGroup:CreateDropdown(
	"Battle Rounds",
	{ "1", "2", "3", "4", "5", "6", "7", "8", "9", "10" },
	state.BattleRounds,
	function(arg347)
		local temp348 = 0
		while true do
			if temp348 == 0 then
				if type(arg347) == "table" then
					state.BattleRounds = arg347[1] or "3"
				else
					state.BattleRounds = tostring(arg347)
				end
				saveSettings()
				break
			end
		end
	end
)
battleMasteryGroup:CreateToggle(
	"Enable Gamepass",
	state.BattleGamepass,
	"Use double rewards pass automatically",
	function(arg349)
		state.BattleGamepass = arg349
		saveSettings()
	end
)
battleMasteryGroup:CreateSlider("Min Players to Start", 2, 5, state.BattleMinPlayers, function(arg351)
	state.BattleMinPlayers = arg351
end)
battleMasteryGroup:CreateToggle(
	"Auto Battle Lobby",
	state.AAutoBattle,
	"Automate battle requests and accepts",
	function(arg353)
		state.AAutoBattle = arg353
		saveSettings()
	end
)
battleMasteryGroup:CreateToggle(
	"Auto Accept Battle Invites",
	state.AAutoAcceptBattle,
	"Automatically accept match lobby requests",
	function(arg355)
		local temp356 = 0
		while true do
			if temp356 == 0 then
				state.AAutoAcceptBattle = arg355
				saveSettings()
				break
			end
		end
	end
)
kickMasteryGroup:CreateSlider("Kick Power", 0, 100, state.MasteryKickPower, function(arg357)
	state.MasteryKickPower = arg357
end)
kickMasteryGroup:CreateDropdown("Reset Method", { "Died", "TP" }, state.MasteryResetMethod, function(arg359)
	if type(arg359) == "table" then
		state.MasteryResetMethod = arg359[1] or "Died"
	else
		state.MasteryResetMethod = tostring(arg359)
	end
end)
kickMasteryGroup:CreateToggle(
	"Auto Farm Mastery",
	state.AAutoMastery,
	"Automate mastery levels farming",
	function(arg360)
		state.AAutoMastery = arg360
	end
)
local weatherEventOptions = { "None" }
pcall(function()
	local temp362 = require(game:GetService("ReplicatedStorage").Shared.Data.SacrificeData)
	if temp362 and temp362.Recipes then
		for key738, item739 in pairs(temp362.Recipes) do
			table.insert(weatherEventOptions, key738)
		end
	end
end)
weatherSummonerGroup:CreateDropdown("Target Weather", weatherEventOptions, state.TTargetWeatherEvent, function(arg363)
	state.TTargetWeatherEvent = arg363
end)
weatherSummonerGroup:CreateToggle(
	"Auto Summon Weather",
	state.AAutoSummonWeather,
	"Summons target weather event directly",
	function(arg365)
		state.AAutoSummonWeather = arg365
	end
)
local kickStyleOptions = { "Default" }
pcall(function()
	local temp367 = 0
	local temp368
	while true do
		if 0 == temp367 then
			temp368 = game:GetService("ReplicatedStorage").Shared.Data.KickStylesData
			for key847, item848 in ipairs(temp368:GetChildren()) do
				if item848:IsA("ModuleScript") and (item848.Name ~= "Default") then
					table.insert(kickStyleOptions, item848.Name)
				end
			end
			break
		end
	end
end)
kickingStylesGroup:CreateDropdown("Target Kick Style", kickStyleOptions, state.TargetKickStyle, function(arg369)
	if type(arg369) == "table" then
		state.TargetKickStyle = arg369[1] or "Default"
	else
		state.TargetKickStyle = tostring(arg369)
	end
	saveSettings()
end)
kickingStylesGroup:CreateToggle(
	"Auto Buy & Equip Style",
	state.AAutoKickStyle,
	"Purchase and equip kick style automatically",
	function(arg370)
		state.AAutoKickStyle = arg370
		saveSettings()
	end
)
state.WeightList = { "None" }
if weightModelsFolder then
	for key684, item685 in ipairs(weightModelsFolder:GetChildren()) do
		table.insert(state.WeightList, item685.Name)
	end
end
weightSpeedGroup:CreateDropdown("Target Weight", state.WeightList, state.TTargetWeight, function(arg372)
	state.TTargetWeight = arg372
end)
weightSpeedGroup:CreateToggle(
	"Auto Buy Selected Weight",
	state.ABuyWeights,
	"Auto purchase selected weight style",
	function(arg374)
		local temp375 = 0
		while true do
			if temp375 == 0 then
				state.ABuyWeights = arg374
				saveSettings()
				break
			end
		end
	end
)
weightSpeedGroup:CreateToggle(
	"Auto Buy Best Weight",
	state.ABuyBest,
	"Unlock and purchase best weight in game",
	function(arg376)
		state.ABuyBest = arg376
		saveSettings()
	end
)
weightSpeedGroup:CreateToggle("Auto Buy Speed", state.ABuySpeed, "Automatically upgrades kick speed", function(arg378)
	local temp379 = 0
	while true do
		if temp379 == 0 then
			state.ABuySpeed = arg378
			saveSettings()
			break
		end
	end
end)
sellFavoriteGroup:AddDropdown("FavoriteBrainrot", {
	["Text"] = "Favorite Brainrot",
	["Values"] = gameData.BrainrotOptions,
	["Default"] = state.TSSellBrainrot,
	["Multi"] = true,
	["Searchable"] = true,
	["Callback"] = function(arg380)
		state.TSSellBrainrot = selectedKeysFromMap(arg380)
		saveSettings()
		if state.TriggerFavScan then
			task.spawn(state.TriggerFavScan)
		end
	end,
})
sellFavoriteGroup:AddDropdown("FavoriteRarity", {
	["Text"] = "Favorite Rarity",
	["Values"] = gameData.RarityOptions,
	["Default"] = state.TSSellRarity,
	["Multi"] = true,
	["Searchable"] = true,
	["Callback"] = function(arg383)
		state.TSSellRarity = selectedKeysFromMap(arg383)
		saveSettings()
		if state.TriggerFavScan then
			task.spawn(state.TriggerFavScan)
		end
	end,
})
sellFavoriteGroup:AddDropdown("FavoriteMutation", {
	["Text"] = "Favorite Mutation",
	["Values"] = gameData.MutationOptions,
	["Default"] = state.TSSellMutation,
	["Multi"] = true,
	["Searchable"] = true,
	["Callback"] = function(arg386)
		state.TSSellMutation = selectedKeysFromMap(arg386)
		saveSettings()
		if state.TriggerFavScan then
			task.spawn(state.TriggerFavScan)
		end
	end,
})
sellFavoriteGroup:CreateToggle(
	"Auto Favorite Filter",
	state.AAutoFav,
	"Bypasses Sell All on selected filter settings",
	function(arg389)
		local temp390 = 0
		local temp391
		while true do
			if temp390 == 0 then
				temp391 = 0
				while true do
					if temp391 == 1 then
						if arg389 and state.TriggerFavScan then
							state.TriggerFavScan()
						end
						break
					end
					if temp391 == 0 then
						state.AAutoFav = arg389
						saveSettings()
						temp391 = 1
					end
				end
				break
			end
		end
	end
)
sellFavoriteGroup:CreateButton("Sell All Brainrots", function()
	local temp392 = 0
	while true do
		if temp392 == 0 then
			if state.AAutoFav and state.TriggerFavScan then
				state.TriggerFavScan()
				task.wait(1)
			end
			if sellAllRemote then
				local temp923 = 0
				while true do
					if temp923 == 0 then
						pcall(function()
							sellAllRemote:InvokeServer()
						end)
						uiLibrary:Notify({
							["Title"] = "Sell All",
							["Content"] = "Executed! Auto-Fav synced before selling.",
							["Duration"] = 3,
						})
						break
					end
				end
			else
				uiLibrary:Notify({ ["Title"] = "Error", ["Content"] = "Sell All remote not found!", ["Duration"] = 3 })
			end
			break
		end
	end
end)
getgenv().TargetServerInput = ""
serverJoinerGroup:CreateInput("Join Server Link / JobId", "Paste JobId here", nil, function(arg393)
	getgenv().TargetServerInput = arg393
end)
serverJoinerGroup:CreateButton("Join Server Instance", function()
	local temp395 = 0
	local temp396
	while true do
		if temp395 == 1 then
			task.spawn(function()
				local temp853 = nil
				local temp854 = nil
				if temp396:find("LUXY:<") then
					local temp976 = 0
					local temp977
					while true do
						if temp976 == 0 then
							temp977 = temp396:match("LUXY:<([^>]+)>")
							if temp977 then
								local temp1189 = 0
								local temp1190
								local temp1191
								local temp1192
								while true do
									if temp1189 == 1 then
										temp1192 = nil
										while true do
											if temp1190 == 0 then
												temp1191, temp1192 = pcall(base64Decode, temp977)
												if temp1191 and temp1192 and (temp1192 ~= "") then
													temp854 = temp1192
												end
												break
											end
										end
										break
									end
									if temp1189 == 0 then
										temp1190 = 0
										temp1191 = nil
										temp1189 = 1
									end
								end
							end
							break
						end
					end
				elseif temp396:find("roblox.com") or temp396:find("placeId=") then
					local temp1089 = 0
					local temp1090
					local temp1091
					local temp1092
					while true do
						if temp1089 == 1 then
							temp1092 = nil
							while true do
								if 0 == temp1090 then
									local temp1324 = 0
									while true do
										if temp1324 == 0 then
											temp1091 = temp396:match("placeId=(%d+)")
											if temp1091 then
												temp853 = tonumber(temp1091)
											end
											temp1324 = 1
										end
										if 1 == temp1324 then
											temp1090 = 1
											break
										end
									end
								end
								if temp1090 == 1 then
									temp1092 = temp396:match("instanceId=([^&%s]+)")
									if temp1092 then
										temp854 = temp1092
									end
									break
								end
							end
							break
						end
						if temp1089 == 0 then
							temp1090 = 0
							temp1091 = nil
							temp1089 = 1
						end
					end
				end
				if not temp854 then
					temp854 = temp396:match(
						"(%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x)"
					) or temp396:match("([%w]+%-[%w]+%-[%w]+%-[%w]+%-[%w]+)") or string.gsub(
						temp396,
						"^%s*(.-)%s*$",
						"%1"
					)
				end
				if not temp853 then
					temp853 = game.PlaceId
				end
				if temp854 and (temp854 ~= "") then
					uiLibrary:Notify({
						["Title"] = "Hopping",
						["Content"] = ("Teleporting to Place: " .. tostring(temp853) .. " | Instance: " .. temp854),
						["Duration"] = 3,
					})
					task.wait(0.5)
					pcall(function()
						game:GetService("TeleportService"):TeleportToPlaceInstance(temp853, temp854, LocalPlayer)
					end)
				else
					uiLibrary:Notify({ ["Title"] = "Error", ["Content"] = "Failed to extract JobId!", ["Duration"] = 3 })
				end
			end)
			break
		end
		if 0 == temp395 then
			local temp745 = 0
			local temp746
			while true do
				if 0 == temp745 then
					temp746 = 0
					while true do
						if 1 == temp746 then
							temp395 = 1
							break
						end
						if temp746 == 0 then
							temp396 = getgenv().TargetServerInput
							if not temp396 or (temp396 == "") then
								local temp1193 = 0
								while true do
									if temp1193 == 0 then
										uiLibrary:Notify({
											["Title"] = "Error",
											["Content"] = "Input is empty!",
											["Duration"] = 3,
										})
										return
									end
								end
							end
							temp746 = 1
						end
					end
					break
				end
			end
		end
	end
end)
webhookGroup:AddDropdown("WebhookBrainrotDrop", {
	["Text"] = "Webhook Brainrot",
	["Values"] = gameData.BrainrotOptions,
	["Default"] = state.WBBrainrot,
	["Multi"] = true,
	["Searchable"] = true,
	["Callback"] = function(arg397)
		state.WBBrainrot = selectedKeysFromMap(arg397)
		saveSettings()
	end,
})
webhookGroup:AddDropdown("WebhookRarityDrop", {
	["Text"] = "Filter Rarity",
	["Values"] = gameData.RarityOptions,
	["Default"] = state.WBRarity,
	["Multi"] = true,
	["Searchable"] = true,
	["Callback"] = function(arg400)
		state.WBRarity = selectedKeysFromMap(arg400)
		saveSettings()
	end,
})
webhookGroup:AddDropdown("WebhookMutationDrop", {
	["Text"] = "Filter Mutation",
	["Values"] = gameData.MutationOptions,
	["Default"] = state.WBMutation,
	["Multi"] = true,
	["Searchable"] = true,
	["Callback"] = function(arg403)
		state.WBMutation = selectedKeysFromMap(arg403)
		saveSettings()
	end,
})
webhookGroup:CreateInput("Webhook URL", "Paste Discord webhook", nil, function(arg411)
	local normalizedUrl, urlError = normalizeWebhookUrl(arg411)
	if not normalizedUrl then
		if arg411 and (trimString(arg411) ~= "") then
			uiLibrary:Notify({ ["Title"] = "Webhook Error", ["Text"] = urlError, ["Duration"] = 4 })
		end
		return
	end
	state.WebhookURL = trimString(arg411)
	saveSettings()
	local connectionEmbed = {
		["title"] = "NEW WEBHOOK CONNECTION CHECK",
		["description"] = "Luxy Hub is now successfully connected via Hyra Relay Proxy Channel.",
		["color"] = tonumber("0x00FF00"),
		["footer"] = { ["text"] = "Luxy Hub v3.9" },
		["timestamp"] = DateTime.now():ToIsoDate(),
	}
	local sent, sendError = sendWebhookPayload(state.WebhookURL, {
		["username"] = "Luxy Hub Notifier",
		["avatar_url"] = "https://i.imgur.com/K1W0nB4.png",
		["embeds"] = {
			connectionEmbed,
		},
	})
	if sent then
		uiLibrary:Notify({
			["Title"] = "Webhook Check",
			["Description"] = "Connection check sent successfully.",
			["Duration"] = 3,
		})
	else
		uiLibrary:Notify({
			["Title"] = "Webhook Error",
			["Text"] = sendError or "Failed to send webhook.",
			["Duration"] = 4,
		})
	end
end)
webhookGroup:CreateToggle("Enable Webhook", state.AWebhook, "Active webhooks configurations", function(arg414)
	state.AWebhook = arg414
	saveSettings()
end)
local nextStatusWebhookAt = 0
webhookGroup:AddDropdown("StatusFilterBrainrot", {
	["Text"] = "Tracker Filter: Brainrot",
	["Values"] = gameData.BrainrotOptions,
	["Default"] = state.StatusFilterBrainrot,
	["Multi"] = true,
	["Searchable"] = true,
	["Callback"] = function(arg416)
		state.StatusFilterBrainrot = selectedKeysFromMap(arg416)
		if saveSettings then
			saveSettings()
		end
	end,
})
webhookGroup:AddDropdown("StatusFilterRarity", {
	["Text"] = "Tracker Filter: Rarity",
	["Values"] = gameData.RarityOptions,
	["Default"] = state.StatusFilterRarity,
	["Multi"] = true,
	["Searchable"] = true,
	["Callback"] = function(arg419)
		state.StatusFilterRarity = selectedKeysFromMap(arg419)
		if saveSettings then
			saveSettings()
		end
	end,
})
webhookGroup:CreateSlider("Auto Send Interval (Mins)", 1, 120, state.AutoStatusInterval, function(arg422)
	local temp423 = 0
	while true do
		if temp423 == 0 then
			state.AutoStatusInterval = arg422
			nextStatusWebhookAt = tick() + (arg422 * 60)
			temp423 = 1
		end
		if temp423 == 1 then
			if saveSettings then
				saveSettings()
			end
			break
		end
	end
end)
local function sendStatusWebhook(temp424)
	if not state.WebhookURL or (state.WebhookURL == "") then
		if temp424 then
			uiLibrary:Notify({ ["Title"] = "Error", ["Text"] = "Webhook URL empty!", ["Duration"] = 3 })
		end
		return
	end
	local normalizedStatusWebhookUrl, statusWebhookUrlError = normalizeWebhookUrl(state.WebhookURL)
	if not normalizedStatusWebhookUrl then
		if temp424 then
			uiLibrary:Notify({ ["Title"] = "Webhook Error", ["Text"] = statusWebhookUrlError, ["Duration"] = 4 })
		end
		return
	end
	task.spawn(function()
		local list589 = {}
		local temp590 = 0
		local list591 = {}
		if LocalPlayer.Backpack then
			for key861, item862 in ipairs(LocalPlayer.Backpack:GetChildren()) do
				table.insert(list591, item862)
			end
		end
		if LocalPlayer.Character then
			for key863, item864 in ipairs(LocalPlayer.Character:GetChildren()) do
				table.insert(list591, item864)
			end
		end
		local temp592
		pcall(function()
			temp592 = require(game:GetService("ReplicatedStorage").Shared.Data.EntitiesData)
		end)
		local function helper593(temp686, temp687)
			if not temp686 or (#temp686 == 0) or table.find(temp686, "Any") or table.find(temp686, "All") then
				return true
			end
			return table.find(temp686, temp687) ~= nil
		end
		for key688, item689 in ipairs(list591) do
			if item689:IsA("Tool") and item689:GetAttribute("GUID") then
				local temp865 = item689.Name
				local temp866 = item689:GetAttribute("Rarity")
				local temp867 = item689:GetAttribute("Mutation") or "None"
				if (not temp866 or (temp866 == "Unknown") or (temp866 == "")) and temp592 and temp592.Brainrots then
					local temp980 = temp592.Brainrots[temp865]
					if temp980 then
						temp866 = temp980.Rarity
					end
				end
				temp866 = temp866 or "Unknown"
				if helper593(state.StatusFilterBrainrot, temp865) and helper593(state.StatusFilterRarity, temp866) then
					local temp981 = 0
					while true do
						if temp981 == 0 then
							temp590 = temp590 + 1
							if not list589[temp866] then
								list589[temp866] = {}
							end
							temp981 = 1
						end
						if temp981 == 1 then
							if not list589[temp866][temp865] then
								list589[temp866][temp865] = {}
							end
							list589[temp866][temp865][temp867] = (list589[temp866][temp865][temp867] or 0) + 1
							break
						end
					end
				end
			end
		end
		local temp594 = "0"
		local temp595 = tostring(currentKickLevel or 1)
		pcall(function()
			local temp690 = 0
			local temp691
			while true do
				if temp690 == 1 then
					if currentCoins and (type(currentCoins) == "number") and (currentCoins > 0) then
						temp594 = temp691(currentCoins)
					else
						local temp1034 = LocalPlayer:FindFirstChild("leaderstats")
						if temp1034 then
							local temp1136 = temp1034:FindFirstChild("Coins") or temp1034:FindFirstChild("Cash")
							if temp1136 then
								if type(temp1136.Value) == "string" then
									temp594 = temp1136.Value
								else
									temp594 = temp691(tonumber(temp1136.Value) or 0)
								end
							end
						end
					end
					break
				end
				if temp690 == 0 then
					temp691 = nil
					function temp691(temp982)
						if type(temp982) ~= "number" then
							return tostring(temp982)
						end
						if temp982 < 1000 then
							return tostring(temp982)
						end
						local temp983 = { "K", "M", "B", "T", "Q", "Qi", "S", "Sp" }
						local temp984 = math.floor(math.log10(temp982) / 3)
						return string
							.format("%.2f%s", temp982 / (10 ^ (temp984 * 3)), temp983[temp984] or "")
							:gsub("%.00", "")
					end
					temp690 = 1
				end
			end
		end)
		local list596 = {}
		local temp597 = {
			["Unknown"] = 0,
			["Common"] = 1,
			["Uncommon"] = 2,
			["Rare"] = 3,
			["Epic"] = 4,
			["Legendary"] = 5,
			["Mythic"] = 6,
			["Mythical"] = 6,
			["Secret"] = 7,
			["Divine"] = 8,
			["Celestial"] = 9,
			["Eternal"] = 10,
		}
		local list598 = {}
		for key692, item693 in pairs(list589) do
			table.insert(list598, key692)
		end
		table.sort(list598, function(arg694, arg695)
			return (temp597[arg694] or 0) < (temp597[arg695] or 0)
		end)
		for key696, item697 in ipairs(list598) do
			local temp698 = ""
			local temp699 = true
			local list700 = {}
			for key752, item753 in pairs(list589[item697]) do
				table.insert(list700, key752)
			end
			table.sort(list700)
			for key754, item755 in ipairs(list700) do
				local temp756 = 0
				local temp757
				local temp758
				while true do
					if temp756 == 0 then
						temp757 = "**" .. item755 .. "**\n"
						temp758 = {}
						temp756 = 1
					end
					if temp756 == 3 then
						if (#temp698 + #temp757) > 950 then
							local temp1094 = (temp699 and ("-------- " .. item697:upper() .. " --------")) or "_ _"
							table.insert(list596, { ["name"] = temp1094, ["value"] = temp698, ["inline"] = false })
							temp698 = temp757
							temp699 = false
						else
							temp698 = temp698 .. temp757
						end
						break
					end
					if temp756 == 1 then
						for key1035, item1036 in pairs(list589[item697][item755]) do
							table.insert(temp758, key1035)
						end
						table.sort(temp758)
						temp756 = 2
					end
					if temp756 == 2 then
						for key1037, item1038 in ipairs(temp758) do
							local temp1039 = 0
							local temp1040
							local temp1041
							while true do
								if temp1039 == 1 then
									temp757 = temp757 .. "> Mutation ` " .. temp1041 .. " x" .. temp1040 .. " `\n"
									break
								end
								if temp1039 == 0 then
									local temp1158 = 0
									while true do
										if temp1158 == 1 then
											temp1039 = 1
											break
										end
										if temp1158 == 0 then
											temp1040 = list589[item697][item755][item1038]
											temp1041 = (((item1038 == "None") or (item1038 == "")) and "No Mutation")
												or item1038
											temp1158 = 1
										end
									end
								end
							end
						end
						temp757 = temp757 .. "\n"
						temp756 = 3
					end
				end
			end
			if temp698 ~= "" then
				local temp868 = 0
				local temp869
				while true do
					if temp868 == 0 then
						temp869 = (temp699 and ("-------- " .. item697:upper() .. " --------")) or "_ _"
						table.insert(list596, { ["name"] = temp869, ["value"] = temp698, ["inline"] = false })
						break
					end
				end
			end
		end
		if temp590 == 0 then
			table.insert(
				list596,
				{ ["name"] = "Inventory Empty", ["value"] = "No brainrots matched your filter.", ["inline"] = false }
			)
		end
		table.insert(
			list596,
			{ ["name"] = "Kick Power", ["value"] = ("```Power. " .. temp595 .. "```"), ["inline"] = true }
		)
		table.insert(
			list596,
			{ ["name"] = "Total Items", ["value"] = ("```" .. temp590 .. " Brainrot```"), ["inline"] = true }
		)
		table.insert(list596, { ["name"] = "Total Cash", ["value"] = ("```$" .. temp594 .. "```"), ["inline"] = true })
		local temp599 = {
			["title"] = "Brainrot Inventory",
			["color"] = tonumber("0xFF5500"),
			["fields"] = list596,
			["image"] = {
				["url"] = "https://cdn.discordapp.com/attachments/1512649548294651914/1512660648495157248/noFilter.jpg?ex=6a24e682&is=6a239502&hm=a9d7f1df29cdce4f615de7c53b4cbad8751e36e5df5e7de7b1228c80f60579d5&",
			},
			["footer"] = { ["text"] = "Luxy Hub AFK Reporter" },
			["timestamp"] = DateTime.now():ToIsoDate(),
		}
		local sent, sendError =
			sendWebhookPayload(state.WebhookURL, { ["username"] = "Luxy Hub Tracker", ["embeds"] = { temp599 } })
		if temp424 then
			if sent then
				uiLibrary:Notify({ ["Title"] = "Success", ["Text"] = "Inventory Report sent!", ["Duration"] = 3 })
			else
				uiLibrary:Notify({
					["Title"] = "Webhook Error",
					["Text"] = sendError or "Failed to send tracker webhook.",
					["Duration"] = 4,
				})
			end
		end
	end)
end
webhookGroup:CreateToggle(
	"Auto Send Progress",
	state.AutoStatusWebhook,
	"Sends status to Discord based on timer",
	function(arg425)
		local temp426 = 0
		while true do
			if temp426 == 1 then
				if saveSettings then
					saveSettings()
				end
				break
			end
			if temp426 == 0 then
				state.AutoStatusWebhook = arg425
				nextStatusWebhookAt = tick() + (state.AutoStatusInterval * 60)
				temp426 = 1
			end
		end
	end
)
webhookGroup:CreateButton("Send Tracker Check Now", function()
	sendStatusWebhook(true)
end)
task.spawn(function()
	while state.HubRunning do
		local temp601 = 0
		while true do
			if temp601 == 0 then
				task.wait(1)
				if state.AutoStatusWebhook and (state.WebhookURL ~= "") then
					if tick() >= nextStatusWebhookAt then
						sendStatusWebhook(false)
						nextStatusWebhookAt = tick() + (state.AutoStatusInterval * 60)
					end
				end
				break
			end
		end
	end
end)
visualsPerformanceGroup:CreateToggle(
	"FPS Boost",
	state.AFPSBoost,
	"Lower graphics for maximum optimization",
	function(arg427)
		local temp428 = 0
		while true do
			if temp428 == 1 then
				if uiLibrary then
					uiLibrary:SetPotatoMode(arg427)
					if arg427 and state.ARTXShader then
						local temp1042 = 0
						while true do
							if temp1042 == 0 then
								state.ARTXShader = false
								saveSettings()
								break
							end
						end
					end
				end
				break
			end
			if temp428 == 0 then
				state.AFPSBoost = arg427
				saveSettings()
				temp428 = 1
			end
		end
	end
)
visualsPerformanceGroup:CreateToggle("RTX Shader", state.ARTXShader, "Activate custom game shaders", function(arg429)
	local temp430 = 0
	local temp431
	while true do
		if 0 == temp430 then
			temp431 = 0
			while true do
				if temp431 == 0 then
					state.ARTXShader = arg429
					saveSettings()
					temp431 = 1
				end
				if temp431 == 1 then
					if uiLibrary then
						local temp1095 = 0
						while true do
							if temp1095 == 0 then
								uiLibrary:SetRTXMode(arg429)
								if arg429 and state.AFPSBoost then
									local temp1278 = 0
									while true do
										if 0 == temp1278 then
											state.AFPSBoost = false
											saveSettings()
											break
										end
									end
								end
								break
							end
						end
					end
					break
				end
			end
			break
		end
	end
end)
visualsPerformanceGroup:CreateToggle(
	"Anti AFK",
	state.AntiAFK,
	"Completely bypasses the 20-minute Roblox idle kick.",
	function(arg432)
		local temp433 = 0
		local temp434
		while true do
			if temp433 == 0 then
				temp434 = 0
				while true do
					if 0 == temp434 then
						state.AntiAFK = arg432
						saveSettings()
						break
					end
				end
				break
			end
		end
	end
)
task.spawn(function()
	task.wait(2)
	if state.AFPSBoost and uiLibrary then
		uiLibrary:SetPotatoMode(true)
	elseif state.ARTXShader and uiLibrary then
		uiLibrary:SetRTXMode(true)
	end
end)
local function startVolcanoTween()
	if volcanoTweenConnection then
		volcanoTweenConnection:Disconnect()
	end
	volcanoTweenConnection = trackConnection(
		RunService.Heartbeat:Connect(function(arg602)
			if not state.HubRunning or not volcanoTargetPart or not volcanoTargetPart.Parent then
				return
			end
			local temp603 = LocalPlayer.Character
			local temp604 = temp603 and temp603:FindFirstChild("HumanoidRootPart")
			local temp605 = temp603 and temp603:FindFirstChild("Humanoid")
			if not temp604 or not temp605 or (temp605.Health <= 0) then
				local temp765 = 0
				while true do
					if temp765 == 0 then
						volcanoTargetPart = nil
						return
					end
				end
			end
			local temp606 = volcanoTargetPart.Position
			local temp607 = (Vector3.new(temp606.X, 0, temp606.Z) - Vector3.new(
				temp604.Position.X,
				0,
				temp604.Position.Z
			)).Magnitude
			local temp608 = (state.VolcanoTweenSpeed or 85) * arg602
			if temp607 > 3 then
				local temp766 = (Vector3.new(temp606.X, 0, temp606.Z) - Vector3.new(
					temp604.Position.X,
					0,
					temp604.Position.Z
				)).Unit
				local temp767 = temp766 * math.min(temp608, temp607)
				local temp768 = temp604.Position + temp767
				local temp769 = temp604.Position.Y
				local temp770 = RaycastParams.new()
				temp770.FilterType = Enum.RaycastFilterType.Exclude
				temp770.FilterDescendantsInstances = { temp603 }
				local temp774 = Vector3.new(temp768.X, math.max(temp604.Position.Y, temp606.Y) + 5, temp768.Z)
				local temp775 = workspace:Raycast(temp774, Vector3.new(0, -15, 0), temp770)
				if temp775 then
					temp769 = temp775.Position.Y + 3
				end
				temp604.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
				temp604.CFrame = CFrame.new(temp768.X, temp769, temp768.Z)
			end
		end),
		"VolcanoTween"
	)
end
task.spawn(function()
	if not LocalPlayer.Character then
		LocalPlayer.CharacterAdded:Wait()
	end
	task.wait(2)
	startVolcanoTween()
end)
task.spawn(function()
	while state.HubRunning do
		local autoFarmWorkerOk = pcall(function()
			local temp437 = 0
			local temp438
			local temp439
			local temp440
			local temp441
			local temp442
			while true do
				if temp437 == 1 then
					pcall(function()
						temp439 = require(temp438.Modules.HandlerLoader.GameHandler)
					end)
					pcall(function()
						temp440 = require(temp438.Modules.ServicesLoader.SpeedServiceClient)
					end)
					temp437 = 2
				end
				if temp437 == 4 then
					while state.HubRunning do
						task.wait(0.15)
						if state.AFarm then
							state.LastAutoKickActivityAt = tick()
							if state.IsFlashCollecting then
								continue
							end
							local temp988 = nil
							pcall(function()
								temp988 = require(temp438.Modules.UILoader.KickBattlesUI).CurrentStatus
							end)
							if state.AAutoBattle then
								if temp988 ~= "Battle" then
									continue
								end
							elseif (temp988 == "Lobby") or (temp988 == "Create") then
								continue
							end
							local temp989 = temp442.Character
							if not temp989 then
								continue
							end
							local temp990 = temp989:FindFirstChild("HumanoidRootPart")
							local temp991 = temp989:FindFirstChild("Humanoid")
							local temp992 = Workspace.CurrentCamera
							if not temp990 or not temp991 or (temp991.Health <= 0) then
								continue
							end
							local temp993 = Workspace:FindFirstChild("Areas")
								and Workspace.Areas:FindFirstChild("KickReady")
							if not temp993 or (temp992.CameraSubject ~= temp991) then
								if temp992 and temp991 and temp990 then
									temp992.CameraType = Enum.CameraType.Custom
									temp992.CameraSubject = temp991
								end
								continue
							end
							local temp994 = Workspace:FindFirstChild("Waves")
							local temp995 = temp994 and (#temp994:GetChildren() > 0)
							local temp996 = temp442:FindFirstChild("PlayerGui")
							local temp997 = temp996 and temp996:FindFirstChild("HUD")
							local temp998 = temp997 and temp997:FindFirstChild("KickButton")
							local temp999 = temp991:GetAttribute("DefaultHipHeight")
							if not temp999 then
								temp999 = temp991.HipHeight
								temp991:SetAttribute("DefaultHipHeight", temp999)
							end
							local temp1000 = temp442:GetAttribute("InGame") or ""
							local temp1001 = temp995 and (temp1000 ~= "")
							if temp1001 then
								if temp1000 ~= "" then
									local temp1160 = string.split(temp1000, ",")
									local temp1161 = true
									if state.AAutoBattle then
										temp1161 = false
									else
										for index1279 = 1, #temp1160, 2 do
											local temp1280 = (
												temp1160[index1279]
												and string.gsub(temp1160[index1279], "^%s*(.-)%s*$", "%1")
											) or "Unknown"
											local temp1281 = (
												temp1160[index1279 + 1]
												and string.gsub(temp1160[index1279 + 1], "^%s*(.-)%s*$", "%1")
											) or "None"
											if (temp1280 == "Unknown") or (temp1280 == "") then
												temp1161 = false
												break
											end
											if matchesMainFilter(temp1280, temp1281) then
												state.LastAutoKickMatchAt = tick()
												temp1161 = false
												break
											end
										end
									end
									if temp1161 and (tick() < (state.NextAutoKickResetAt or 0)) then
										temp1161 = false
									end
									if temp1161 and ((tick() - (state.LastAutoKickMatchAt or 0)) < 4) then
										temp1161 = false
									end
									if temp1161 then
										temp991.HipHeight = temp999
										temp992.CameraType = Enum.CameraType.Scriptable
										temp992.CFrame = temp993.CFrame * CFrame.new(0, 15, -25)
										temp992.CFrame = CFrame.lookAt(temp992.CFrame.Position, temp993.Position)
										task.wait(0.2)
										state.NextAutoKickResetAt = tick() + 8
										temp991.Health = 0
										local temp1245 = temp442.Character
										local respawnDeadline = tick() + 8
										while
											state.AFarm
											and state.HubRunning
											and temp1245 == temp989
											and tick() < respawnDeadline
										do
											temp1245 = temp442.Character
											task.wait(0.1)
										end
										if temp1245 == temp989 then
											temp992.CameraType = Enum.CameraType.Custom
											temp992.CameraSubject = temp991
											continue
										end
										local temp1246 = temp1245:WaitForChild("HumanoidRootPart", 5)
										local temp1247 = temp1245:WaitForChild("Humanoid", 5)
										if temp1246 and temp1247 then
											local temp1325 = 0
											while true do
												if temp1325 == 1 then
													temp992.CameraType = Enum.CameraType.Custom
													temp992.CameraSubject = temp1247
													break
												end
												if 0 == temp1325 then
													temp1246.CFrame = temp993.CFrame * CFrame.new(0, 3, 0)
													task.wait(0.2)
													temp1325 = 1
												end
											end
										end
									else
										local temp1248 = temp990.Position
										local temp1249 = temp993.Position
										local temp1250 = (Vector3.new(temp1248.X, 0, temp1248.Z) - Vector3.new(
											temp1249.X,
											0,
											temp1249.Z
										)).Magnitude
										pcall(function()
											temp440:SlowMode(false)
										end)
										temp991.PlatformStand = true
										temp991.MaxSlopeAngle = 89
										while temp995 and state.AFarm and state.HubRunning do
											local temp1282 = task.wait()
											if not (temp989 and temp991 and (temp991.Health > 0) and temp990) then
												break
											end
											local temp1283 = workspace:FindFirstChild("Waves")
											if not (temp1283 and (#temp1283:GetChildren() > 0)) then
												break
											end
											local temp1284 = temp990.Position
											local temp1285 = Vector3.new(temp1249.X, 0, temp1249.Z)
												- Vector3.new(temp1284.X, 0, temp1284.Z)
											local temp1286 = temp1285.Magnitude
											if temp1286 < 3 then
												break
											end
											local temp1287 = math.clamp(1 - (temp1286 / temp1250), 0, 1)
											temp1287 = temp1287 * temp1287 * temp1287 * temp1287
											local temp1288 = math.lerp(temp1248.Y + 0.5, temp1249.Y + -5, temp1287)
											local temp1289 = math.max(temp991.WalkSpeed, state.VolcanoTweenSpeed or 85)
											local temp1290 = temp1285.Unit
											local temp1291 = temp1290 * temp1289 * temp1282
											temp990.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
											temp990.CFrame =
												CFrame.new(temp1284.X + temp1291.X, temp1288, temp1284.Z + temp1291.Z)
										end
										temp991.PlatformStand = false
										temp991.HipHeight = temp999
										temp990.CFrame = temp993.CFrame * CFrame.new(0, -1.5, 0)
										pcall(function()
											temp440:SlowMode(true)
										end)
										task.wait(0.3)
									end
								else
									local temp1162 = 0
									local temp1163
									while true do
										if temp1162 == 0 then
											temp991.WalkSpeed = 16
											temp991.MaxSlopeAngle = 89
											temp1162 = 1
										end
										if temp1162 == 1 then
											temp1163 = (temp990.Position - temp993.Position).Magnitude
											if temp1163 > 10 then
												volcanoTargetPart = temp993
											else
												volcanoTargetPart = nil
											end
											break
										end
									end
								end
							else
								local temp1099 = 0
								local temp1100
								while true do
									if temp1099 == 1 then
										volcanoTargetPart = nil
										temp1100 = Vector3.new(temp990.Position.X, 0, temp990.Position.Z)
											- Vector3.new(temp993.Position.X, 0, temp993.Position.Z)
										temp1099 = 2
									end
									if temp1099 == 2 then
										if temp1100.Magnitude > 3 then
											temp990.CFrame = temp993.CFrame * CFrame.new(0, 3, 0)
											task.wait(0.5)
										else
											local temp1298 = 0
											local temp1299
											while true do
												if temp1298 == 1 then
													if temp1299 and kickEventRemote then
														local temp1388 = 0
														while true do
															if temp1388 == 0 then
																pcall(function()
																	local temp1430 = 0
																	local temp1431
																	local temp1432
																	local temp1433
																	local temp1434
																	local temp1435
																	local temp1436
																	while true do
																		if temp1430 == 3 then
																			temp1436 = temp1434 / temp1435
																			kickEventRemote:FireServer(
																				temp1433,
																				temp1436
																			)
																			break
																		end
																		if temp1430 == 2 then
																			temp1435 = 1
																			if state.KickPowerMode == "Micro" then
																				temp1435 = 100
																			elseif state.KickPowerMode == "Nano" then
																				temp1435 = 10000
																			end
																			temp1430 = 3
																		end
																		if temp1430 == 1 then
																			temp1433 = temp1431[temp1432] or 0.98
																			temp1434 = (
																				state.CustomKickPowerPercent or 100
																			)
																				/ 100
																			temp1430 = 2
																		end
																		if 0 == temp1430 then
																			temp1431 = {
																				["Bad"] = 0.05,
																				["Mid"] = 0.25,
																				["Good"] = 0.45,
																				["Great"] = 0.55,
																				["Excellent"] = 0.75,
																				["Perfect"] = 0.98,
																				["Cosmic"] = 0.99,
																			}
																			temp1432 = state.TargetMinigameAccuracy
																				or "Perfect"
																			temp1430 = 1
																		end
																	end
																end)
																task.wait(0.5)
																break
															end
														end
													end
													break
												end
												if temp1298 == 0 then
													local temp1364 = 0
													while true do
														if temp1364 == 1 then
															temp1298 = 1
															break
														end
														if temp1364 == 0 then
															temp1299 = temp998 and temp998.Visible
															if state.AAutoBattle and (temp988 == "Battle") then
																local temp1421 = 0
																local temp1422
																local temp1423
																local temp1424
																while true do
																	if temp1421 == 1 then
																		temp1424 = nil
																		while true do
																			if temp1422 == 1 then
																				if
																					temp1424
																					and temp1424:FindFirstChild(
																						"TopFrame"
																					)
																					and temp1424.TopFrame:FindFirstChild(
																						"TimerFrame"
																					)
																				then
																					temp1423 =
																						temp1424.TopFrame.TimerFrame.Visible
																				end
																				if temp1423 then
																					temp1299 = true
																				end
																				break
																			end
																			if temp1422 == 0 then
																				local temp1458 = 0
																				while true do
																					if temp1458 == 0 then
																						temp1423 = false
																						temp1424 =
																							temp442.PlayerGui:FindFirstChild(
																								"KickBattles"
																							)
																						temp1458 = 1
																					end
																					if 1 == temp1458 then
																						temp1422 = 1
																						break
																					end
																				end
																			end
																		end
																		break
																	end
																	if 0 == temp1421 then
																		temp1422 = 0
																		temp1423 = nil
																		temp1421 = 1
																	end
																end
															end
															temp1364 = 1
														end
													end
												end
											end
										end
										break
									end
									if temp1099 == 0 then
										temp991.HipHeight = temp999
										temp991.MaxSlopeAngle = 45
										temp1099 = 1
									end
								end
							end
						end
					end
					break
				end
				if temp437 == 2 then
					temp441 = game:GetService("RunService")
					temp442 = game:GetService("Players").LocalPlayer
					temp437 = 3
				end
				if temp437 == 3 then
					if not temp442.Character then
						temp442.CharacterAdded:Wait()
					end
					task.wait(5)
					temp437 = 4
				end
				if temp437 == 0 then
					temp438 = game:GetService("ReplicatedStorage")
					temp439, temp440 = nil
					temp437 = 1
				end
			end
		end)
		if autoFarmWorkerOk then
			break
		end
		volcanoTargetPart = nil
		state.LastAutoKickActivityAt = tick()
		task.wait(1)
	end
end)
task.spawn(function()
	local temp443 = 0
	local temp444
	local temp445
	while true do
		if 0 == temp443 then
			temp444 = false
			temp445 = {}
			temp443 = 1
		end
		if temp443 == 1 then
			while state.HubRunning do
				task.wait(0.5)
				if state.APlaceBest and not temp444 then
					local temp1002 = game:GetService("ReplicatedStorage"):FindFirstChild("Shared", true)
					if temp1002 then
						temp1002 = temp1002:FindFirstChild("Packages", true)
					end
					if temp1002 then
						temp1002 = temp1002:FindFirstChild("Network", true)
					end
					if temp1002 then
						temp1002 = temp1002:FindFirstChild("rev_S_Interact", true)
					end
					if not temp1002 then
						continue
					end
					local temp1003 = LocalPlayer.Character
					local temp1004 = temp1003 and temp1003:FindFirstChild("Humanoid")
					local temp1005 = findPlayerPlot()
					if temp1005 and temp1003 and temp1004 and (temp1004.Health > 0) then
						local temp1101 = math.huge
						local temp1102 = nil
						local temp1103 = nil
						if temp1005:FindFirstChild("Slots") then
							for key1200, item1201 in ipairs(temp1005.Slots:GetChildren()) do
								local temp1202 = 0
								local temp1203
								local temp1204
								while true do
									if temp1202 == 0 then
										temp1203 = item1201:FindFirstChild("PlacedPart")
										temp1204 = tonumber(string.match(item1201.Name, "%d+"))
										temp1202 = 1
									end
									if 1 == temp1202 then
										if temp1204 then
											local temp1365 = 0
											while true do
												if temp1365 == 0 then
													if temp445[temp1204] and ((tick() - temp445[temp1204]) < 5) then
														continue
													end
													if not temp1203 then
														if not temp1103 then
															temp1103 = temp1204
														end
													elseif temp1203:GetAttribute("ID") then
														local temp1439 = temp1203:GetAttribute("ID")
														local temp1440 = temp1203:GetAttribute("Mutation") or "None"
														local temp1441 = temp1203:GetAttribute("Level") or 1
														local temp1442 = string.format("%s [%s]", temp1439, temp1440)
														local temp1443 = false
														if state.AProtectFilter and state.TProtectedBrainrots then
															for key1453, item1454 in ipairs(state.TProtectedBrainrots) do
																local temp1455 =
																	string.gsub(item1454, "^%[Lv%.%d+%]%s*", "")
																if temp1455 == temp1442 then
																	temp1443 = true
																	break
																end
															end
														end
														if not temp1443 then
															local temp1451 = 0
															local temp1452
															while true do
																if temp1451 == 0 then
																	temp1452 = calculateBrainrotCps(
																		temp1439,
																		temp1440,
																		temp1441
																	)
																	if temp1452 < temp1101 then
																		temp1101 = temp1452
																		temp1102 = temp1204
																	end
																	break
																end
															end
														end
													end
													break
												end
											end
										end
										break
									end
								end
							end
						end
						local temp1104 = nil
						local temp1105 = -1
						local list1106 = {}
						if LocalPlayer.Backpack then
							for key1205, item1206 in ipairs(LocalPlayer.Backpack:GetChildren()) do
								if item1206:IsA("Tool") then
									table.insert(list1106, item1206)
								end
							end
						end
						if temp1003 then
							local temp1164 = 0
							local temp1165
							while true do
								if temp1164 == 0 then
									temp1165 = temp1003:FindFirstChildOfClass("Tool")
									if temp1165 then
										table.insert(list1106, temp1165)
									end
									break
								end
							end
						end
						for key1137, item1138 in ipairs(list1106) do
							if
								item1138:IsA("Tool")
								and (item1138:GetAttribute("GUID") or (brainrotBaseCps[item1138.Name] ~= nil))
							then
								local temp1207 = item1138:GetAttribute("Mutation") or "None"
								local temp1208 = calculateBrainrotCps(item1138.Name, temp1207, 1)
								if temp1208 > temp1105 then
									local temp1300 = 0
									local temp1301
									while true do
										if temp1300 == 0 then
											temp1301 = 0
											while true do
												if temp1301 == 0 then
													temp1105 = temp1208
													temp1104 = item1138
													break
												end
											end
											break
										end
									end
								end
							end
						end
						local temp1107 = nil
						if temp1104 and temp1103 then
							temp1107 = temp1103
						elseif temp1104 and temp1102 and (temp1105 > temp1101) then
							temp1107 = temp1102
						end
						if temp1107 then
							local temp1166 = 0
							local temp1167
							while true do
								if temp1166 == 0 then
									temp444 = true
									state.IsPlacingPet = true
									temp1166 = 1
								end
								if temp1166 == 2 then
									while
										(temp1003:FindFirstChildOfClass("Tool") ~= temp1104) and (tick() < temp1167)
									do
										task.wait()
									end
									if temp1003:FindFirstChildOfClass("Tool") == temp1104 then
										local temp1344 = 0
										while true do
											if temp1344 == 0 then
												pcall(function()
													temp1002:FireServer(temp1107)
												end)
												temp445[temp1107] = tick()
												break
											end
										end
									end
									temp1166 = 3
								end
								if temp1166 == 4 then
									temp444 = false
									break
								end
								if temp1166 == 1 then
									temp1004:EquipTool(temp1104)
									temp1167 = tick() + 0.5
									temp1166 = 2
								end
								if temp1166 == 3 then
									task.wait(0.3)
									state.IsPlacingPet = false
									temp1166 = 4
								end
							end
						end
					end
				end
			end
			break
		end
	end
end)
task.spawn(function()
	while state.HubRunning do
		task.wait(0.5)
		if (state.ATrain or state.ATrainCollect) and not state.IsPlacingPet and not state.IsFlashCollecting then
			local temp779 = 0
			local temp780
			local temp781
			while true do
				if temp779 == 0 then
					temp780 = LocalPlayer.Character
					temp781 = temp780 and temp780:FindFirstChild("Humanoid")
					temp779 = 1
				end
				if temp779 == 1 then
					if temp781 and weightModelsFolder then
						local temp1108 = 0
						local temp1109
						local temp1110
						local temp1111
						local temp1112
						while true do
							if temp1108 == 1 then
								temp1111 = {}
								for key1255, item1256 in ipairs(LocalPlayer.Backpack:GetChildren()) do
									if item1256:IsA("Tool") then
										table.insert(temp1111, item1256)
									end
								end
								temp1108 = 2
							end
							if temp1108 == 2 then
								if temp780 then
									local temp1304 = 0
									local temp1305
									while true do
										if temp1304 == 0 then
											temp1305 = temp780:FindFirstChildOfClass("Tool")
											if temp1305 then
												table.insert(temp1111, temp1305)
											end
											break
										end
									end
								end
								temp1112 = getSortedWeights()
								temp1108 = 3
							end
							if temp1108 == 0 then
								temp1109 = nil
								temp1110 = -1
								temp1108 = 1
							end
							if temp1108 == 3 then
								for key1257, item1258 in ipairs(temp1111) do
									for key1306, item1307 in ipairs(temp1112) do
										if (item1307.name == item1258.Name) and (key1306 > temp1110) then
											temp1110 = key1306
											temp1109 = item1258
										end
									end
								end
								if temp1109 then
									local temp1308 = 0
									local temp1309
									while true do
										if temp1308 == 0 then
											temp1309 = temp780:FindFirstChildOfClass("Tool")
											if not temp1309 or (temp1309.Name ~= temp1109.Name) then
												if weightEquipRemote then
													pcall(function()
														weightEquipRemote:FireServer(temp1109.Name)
													end)
												end
												if temp1109.Parent == LocalPlayer.Backpack then
													temp781:EquipTool(temp1109)
												end
											end
											break
										end
									end
								end
								break
							end
						end
					end
					break
				end
			end
		end
	end
end)
task.spawn(function()
	local temp446 = 0
	local temp447
	while true do
		if temp446 == 0 then
			temp447 = false
			while state.HubRunning do
				task.wait(0.5)
				if state.ABuySpeed and speedUpgradeRemote then
					if not temp447 then
						local temp1113 = 0
						local temp1114
						local temp1115
						local temp1116
						while true do
							if temp1113 == 1 then
								temp1116 = nil
								while true do
									if temp1114 == 1 then
										for key1345, item1346 in ipairs(temp1116) do
											local speedUpgradeCost = getSpeedUpgradeCost(item1346)
											if speedUpgradeCost and currentCoins < speedUpgradeCost then
												continue
											end
											local temp1347 = currentCoins
											pcall(function()
												speedUpgradeRemote:FireServer(item1346)
											end)
											task.wait(0.5)
											if currentCoins < temp1347 then
												temp1115 = true
												break
											end
										end
										if not temp1115 then
											temp447 = true
											task.delay(5, function()
												temp447 = false
											end)
										end
										break
									end
									if temp1114 == 0 then
										local temp1326 = 0
										while true do
											if temp1326 == 0 then
												temp1115 = false
												temp1116 = { 3, 2, 1 }
												temp1326 = 1
											end
											if temp1326 == 1 then
												temp1114 = 1
												break
											end
										end
									end
								end
								break
							end
							if 0 == temp1113 then
								temp1114 = 0
								temp1115 = nil
								temp1113 = 1
							end
						end
					end
				else
					task.wait(1)
				end
			end
			break
		end
	end
end)
task.spawn(function()
	local temp448 = false
	local temp449 = 0
	while state.HubRunning do
		task.wait(0.5)
		local temp610 = parseAbbreviatedNumber(
			tostring(
				(
					LocalPlayer.leaderstats
					and LocalPlayer.leaderstats:FindFirstChild("Coins")
					and LocalPlayer.leaderstats.Coins.Value
				) or "0"
			)
		)
		local temp611 = nil
		if state.ABuyBest and weightModelsFolder then
			local temp782 = LocalPlayer.Character
			local temp783 = nil
			local list784 = {}
			for key870, item871 in ipairs(LocalPlayer.Backpack:GetChildren()) do
				table.insert(list784, item871)
			end
			if temp782 then
				local temp926 = temp782:FindFirstChildOfClass("Tool")
				if temp926 then
					table.insert(list784, temp926)
				end
			end
			for key872, item873 in ipairs(list784) do
				if item873:IsA("Tool") and weightModelsFolder:FindFirstChild(item873.Name) then
					temp783 = item873.Name
				end
			end
			if temp783 then
				local temp927 = getSortedWeights()
				local temp928 = 0
				for key1008, item1009 in ipairs(temp927) do
					if item1009.name == temp783 then
						temp928 = key1008
						break
					end
				end
				if (temp928 > 0) and (temp928 < #temp927) then
					temp611 = temp927[temp928 + 1].name
				elseif (temp928 == 0) and (#temp927 > 0) then
					temp611 = temp927[1].name
				end
			end
		elseif state.ABuyWeights and (state.TTargetWeight ~= "None") then
			temp611 = state.TTargetWeight
		end
		if temp611 and shopBuyRemote then
			local temp785 = 0
			local temp786
			while true do
				if temp785 == 0 then
					temp786 = getWeightCost(temp611)
					if temp610 > temp449 then
						temp448 = false
					end
					temp785 = 1
				end
				if temp785 == 1 then
					if (temp610 >= temp786) and not temp448 then
						local temp1117 = 0
						local temp1118
						local temp1119
						while true do
							if temp1117 == 0 then
								temp1118 = temp610
								pcall(function()
									shopBuyRemote:FireServer("WeightShop", temp611)
								end)
								temp1117 = 1
							end
							if temp1117 == 2 then
								if temp1119 >= temp1118 then
									local temp1310 = 0
									while true do
										if temp1310 == 0 then
											temp448 = true
											temp449 = temp1119
											break
										end
									end
								end
								break
							end
							if temp1117 == 1 then
								task.wait(1.5)
								temp1119 = parseAbbreviatedNumber(
									tostring(
										(
											LocalPlayer.leaderstats
											and LocalPlayer.leaderstats:FindFirstChild("Coins")
											and LocalPlayer.leaderstats.Coins.Value
										) or "0"
									)
								)
								temp1117 = 2
							end
						end
					end
					break
				end
			end
		end
	end
end)
task.spawn(function()
	while state.HubRunning do
		local temp612 = 0
		while true do
			if temp612 == 0 then
				task.wait(2)
				if state.APlotUpgrade and plotUpgradeRemote then
					pcall(function()
						local temp1045 = currentCoins
						pcall(function()
							plotUpgradeRemote:FireServer()
						end)
						task.wait(1)
						local temp1046 = currentCoins
						if temp1046 >= temp1045 then
							task.wait(10)
						end
					end)
				end
				break
			end
		end
	end
end)
task.spawn(function()
	while state.HubRunning do
		task.wait(1)
		if state.ARebirth and rebirthRequestRemote then
			local temp787 = 0
			local temp788
			while true do
				if temp787 == 0 then
					temp788 = getRebirthKickRequirement(currentRebirthLevel)
					if currentCoins >= temp788 then
						local temp1120 = 0
						while true do
							if temp1120 == 0 then
								pcall(function()
									rebirthRequestRemote:FireServer()
								end)
								task.wait(5)
								break
							end
						end
					else
						task.wait(5)
					end
					break
				end
			end
		end
	end
end)
task.spawn(function()
	while state.HubRunning do
		local temp613 = 0
		while true do
			if temp613 == 0 then
				task.wait(0.2)
				if (state.A2xTrain or state.ATrainCollect) and not state.IsFlashCollecting then
					local temp1010 = 0
					local temp1011
					local temp1012
					while true do
						if temp1010 == 0 then
							local temp1140 = 0
							while true do
								if temp1140 == 1 then
									temp1010 = 1
									break
								end
								if temp1140 == 0 then
									temp1011 = LocalPlayer:FindFirstChild("PlayerGui")
									temp1012 = temp1011 and temp1011:FindFirstChild("KickUpgrades")
									temp1140 = 1
								end
							end
						end
						if 1 == temp1010 then
							if temp1012 then
								for key1259, item1260 in ipairs(temp1012:GetChildren()) do
									if item1260.Name == "Bonus" then
										pcall(function()
											local temp1348 = 0
											while true do
												if temp1348 == 0 then
													for key1403, item1404 in
														pairs(getconnections(item1260.MouseButton1Click))
													do
														item1404:Fire()
													end
													for key1405, item1406 in pairs(getconnections(item1260.Activated)) do
														item1406:Fire()
													end
													break
												end
											end
										end)
									end
								end
							end
							break
						end
					end
				end
				break
			end
		end
	end
end)
task.spawn(function()
	local temp450 = 0
	while state.HubRunning do
		task.wait(1)
		if state.ACollect and collectCashRemote then
			if (tick() - temp450) >= state.CollectDelay then
				local temp930 = findPlayerPlot()
				local temp931 = LocalPlayer.Character
				local temp932 = temp931 and temp931:FindFirstChild("HumanoidRootPart")
				if temp930 and temp932 and temp930:FindFirstChild("Buttons") and temp930:FindFirstChild("Slots") then
					local temp1047 = 0
					local temp1048
					local temp1049
					while true do
						if temp1047 == 2 then
							for key1209, item1210 in pairs(temp1048) do
								table.insert(temp1049, { ["key"] = key1209, ["tier"] = item1210 })
							end
							table.sort(temp1049, function(arg1211, arg1212)
								return arg1211.key < arg1212.key
							end)
							temp1047 = 3
						end
						if temp1047 == 0 then
							temp450 = tick()
							temp1048 = {}
							temp1047 = 1
						end
						if 1 == temp1047 then
							for key1213, item1214 in ipairs(temp930.Buttons:GetChildren()) do
								if item1214:IsA("BasePart") then
									local temp1311 = 0
									local temp1312
									while true do
										if temp1311 == 0 then
											temp1312 = math.floor(item1214.Position.Y / 5)
											if not temp1048[temp1312] then
												temp1048[temp1312] = {}
											end
											temp1311 = 1
										end
										if 1 == temp1311 then
											table.insert(temp1048[temp1312], item1214)
											break
										end
									end
								end
							end
							temp1049 = {}
							temp1047 = 2
						end
						if temp1047 == 3 then
							for key1215, item1216 in ipairs(temp1049) do
								local temp1217 = item1216.tier
								local temp1218, temp1219 = 0, 0
								local temp1220 = 0
								for key1261, item1262 in ipairs(temp1217) do
									local temp1263 = 0
									while true do
										if temp1263 == 1 then
											temp1220 = temp1220 + 1
											break
										end
										if temp1263 == 0 then
											temp1218 = temp1218 + item1262.Position.X
											temp1219 = temp1219 + item1262.Position.Z
											temp1263 = 1
										end
									end
								end
								if temp1220 > 0 then
									local temp1313 = temp1218 / temp1220
									local temp1314 = temp1219 / temp1220
									local temp1315 = temp1217[1].Position.Y + 3
									temp932.CFrame = CFrame.new(temp1313, temp1315, temp1314)
									task.wait(0.15)
									for key1327, item1328 in ipairs(temp1217) do
										local temp1329 = 0
										local temp1330
										while true do
											if temp1329 == 0 then
												temp1330 = tonumber(string.match(item1328.Name, "%d+"))
												if temp1330 then
													local temp1407 = 0
													local temp1408
													while true do
														if temp1407 == 0 then
															temp1408 = temp930.Slots:FindFirstChild(item1328.Name)
															if temp1408 then
																local temp1447 = 0
																local temp1448
																while true do
																	if temp1447 == 0 then
																		temp1448 = temp1408:FindFirstChild("PlacedPart")
																		if
																			temp1448
																			and temp1448:FindFirstChildOfClass("Model")
																		then
																			local temp1464 = 0
																			while true do
																				if temp1464 == 0 then
																					pcall(function()
																						if firetouchinterest then
																							local temp1466 = 0
																							while true do
																								if 0 == temp1466 then
																									firetouchinterest(
																										temp932,
																										item1328,
																										0
																									)
																									firetouchinterest(
																										temp932,
																										item1328,
																										1
																									)
																									break
																								end
																							end
																						end
																					end)
																					pcall(function()
																						collectCashRemote:FireServer(
																							temp1330
																						)
																					end)
																					break
																				end
																			end
																		end
																		break
																	end
																end
															end
															break
														end
													end
												end
												break
											end
										end
									end
									task.wait(0.05)
								end
							end
							break
						end
					end
				end
			end
		end
	end
end)
task.spawn(function()
	while state.HubRunning do
		task.wait(0.5)
		if state.ATrainCollect and (tick() >= state.NextFlashCollect) then
			local temp789 = LocalPlayer.Character
			local temp790 = temp789 and temp789:FindFirstChild("Humanoid")
			local temp791 = temp789 and temp789:FindFirstChild("HumanoidRootPart")
			local temp792 = findPlayerPlot()
			if temp789 and temp790 and (temp790.Health > 0) and temp791 and temp792 and collectCashRemote then
				state.IsFlashCollecting = true
				state.FlashCollectSession = (state.FlashCollectSession or 0) + 1
				local flashCollectSession = state.FlashCollectSession
				task.delay(20, function()
					if state.IsFlashCollecting and (state.FlashCollectSession == flashCollectSession) then
						state.IsFlashCollecting = false
						state.NextFlashCollect = tick() + 10
					end
				end)
				local temp934 = state.TrainAnchorCFrame or temp791.CFrame
				local temp935 = temp789:FindFirstChildOfClass("Tool")
				local temp936 = (temp935 and temp935.Name) or nil
				temp790:UnequipTools()
				task.wait(0.2)
				if temp792:FindFirstChild("Slots") and temp792:FindFirstChild("Buttons") then
					local temp1050 = 0
					local temp1051
					local temp1052
					while true do
						if temp1050 == 1 then
							local temp1168 = 0
							while true do
								if temp1168 == 1 then
									temp1050 = 2
									break
								end
								if temp1168 == 0 then
									temp1052 = {}
									for key1331, item1332 in pairs(temp1051) do
										table.insert(temp1052, { ["key"] = key1331, ["tier"] = item1332 })
									end
									temp1168 = 1
								end
							end
						end
						if temp1050 == 0 then
							local temp1169 = 0
							while true do
								if temp1169 == 1 then
									temp1050 = 1
									break
								end
								if 0 == temp1169 then
									temp1051 = {}
									for key1333, item1334 in ipairs(temp792.Buttons:GetChildren()) do
										if item1334:IsA("BasePart") then
											local temp1366 = 0
											local temp1367
											while true do
												if temp1366 == 0 then
													temp1367 = temp792.Slots:FindFirstChild(item1334.Name)
													if temp1367 then
														local temp1425 = 0
														local temp1426
														while true do
															if temp1425 == 0 then
																temp1426 = temp1367:FindFirstChild("PlacedPart")
																if
																	temp1426
																	and temp1426:FindFirstChildOfClass("Model")
																then
																	local temp1456 = 0
																	local temp1457
																	while true do
																		if temp1456 == 0 then
																			temp1457 =
																				math.floor(item1334.Position.Y / 5)
																			if not temp1051[temp1457] then
																				temp1051[temp1457] = {}
																			end
																			temp1456 = 1
																		end
																		if temp1456 == 1 then
																			table.insert(temp1051[temp1457], {
																				["button"] = item1334,
																				["slotNum"] = tonumber(
																					string.match(item1334.Name, "%d+")
																				),
																			})
																			break
																		end
																	end
																end
																break
															end
														end
													end
													break
												end
											end
										end
									end
									temp1169 = 1
								end
							end
						end
						if temp1050 == 2 then
							table.sort(temp1052, function(arg1221, arg1222)
								return arg1221.key < arg1222.key
							end)
							for key1223, item1224 in ipairs(temp1052) do
								local temp1225 = item1224.tier
								local temp1226, temp1227 = 0, 0
								for key1264, item1265 in ipairs(temp1225) do
									temp1226 = temp1226 + item1265.button.Position.X
									temp1227 = temp1227 + item1265.button.Position.Z
								end
								local temp1228 = temp1226 / #temp1225
								local temp1229 = temp1227 / #temp1225
								local temp1230 = temp1225[1].button.Position.Y + 3
								temp791.CFrame = CFrame.new(temp1228, temp1230, temp1229)
								task.wait(0.15)
								for key1266, item1267 in ipairs(temp1225) do
									pcall(function()
										local temp1317 = 0
										while true do
											if temp1317 == 0 then
												if firetouchinterest then
													firetouchinterest(temp791, item1267.button, 0)
													firetouchinterest(temp791, item1267.button, 1)
												end
												collectCashRemote:FireServer(item1267.slotNum)
												break
											end
										end
									end)
								end
								task.wait(0.05)
							end
							break
						end
					end
				end
				temp791.CFrame = temp934
				task.wait(0.2)
				if temp936 and LocalPlayer.Backpack:FindFirstChild(temp936) then
					temp790:EquipTool(LocalPlayer.Backpack[temp936])
				end
				state.NextFlashCollect = tick() + (state.TrainCollectDelay * 60)
				state.IsFlashCollecting = false
			end
		end
	end
end)
task.spawn(function()
	local list451 = {}
	local list452 = {}
	local list453 = {}
	local list454 = {}
	local function helper454(temp614, temp615)
		local temp616 = 0
		while true do
			if temp616 == 1 then
				return selectionContainsNormalized(temp614, temp615, normalizeMutationText)
			end
			if temp616 == 0 then
				if type(temp614) == "string" then
					temp614 = { temp614 }
				end
				if
					not temp614
					or (#temp614 == 0)
					or table.find(temp614, "Any")
					or table.find(temp614, "--")
					or table.find(temp614, "None")
				then
					return true
				end
				temp616 = 1
			end
		end
	end
	local function helper455(temp617, temp618)
		if not temp617:IsA("Tool") then
			return
		end
		if list451[temp617] then
			local temp793 = 0
			while true do
				if temp793 == 0 then
					if temp618 then
						local temp1121 = temp617:GetAttribute("GUID")
						if temp1121 then
							local temp1170 = 0
							local temp1171
							while true do
								if temp1170 == 0 then
									temp1171 = list451[temp617]
									if type(temp1171) == "function" then
										pcall(temp1171)
									end
									break
								end
							end
						end
					end
					return
				end
			end
		end
		if not temp617:GetAttribute("GUID") then
			local temp794
			temp794 = temp617:GetAttributeChangedSignal("GUID"):Connect(function()
				if temp617:GetAttribute("GUID") then
					local temp1013 = 0
					while true do
						if temp1013 == 0 then
							if temp794 then
								temp794:Disconnect()
							end
							helper455(temp617, temp618)
							break
						end
					end
				end
			end)
			task.delay(5, function()
				if temp794 then
					temp794:Disconnect()
				end
			end)
			return
		end
		local temp619 = temp617:GetAttribute("GUID")
		local function helper620()
			local temp701 = 0
			local temp702
			local temp703
			local temp704
			local temp705
			while true do
				if temp701 == 3 then
					temp704 = temp617:GetAttribute("Mutation") or "None"
					temp705 = helper454(state.TSSellBrainrot, temp702)
						and helper454(state.TSSellRarity, temp703)
						and helper454(state.TSSellMutation, temp704)
					temp701 = 4
				end
				if temp701 == 0 then
					if not state.AAutoFav or not temp617.Parent then
						return
					end
					if list452[temp619] and ((tick() - list452[temp619]) < 0.2) then
						return
					end
					temp701 = 1
				end
				if temp701 == 4 then
					if temp705 then
						if temp617:GetAttribute("Favorite") ~= true then
							if not table.find(list453, temp619) then
								table.insert(list453, temp619)
							end
						end
					end
					break
				end
				if temp701 == 1 then
					temp702 = temp617.Name
					temp703 = temp617:GetAttribute("Rarity")
					temp701 = 2
				end
				if temp701 == 2 then
					if not temp703 or (temp703 == "") then
						pcall(function()
							if entitiesData and entitiesData.Brainrots and entitiesData.Brainrots[temp702] then
								temp703 = entitiesData.Brainrots[temp702].Rarity
							end
						end)
					end
					temp703 = temp703 or "Unknown"
					temp701 = 3
				end
			end
		end
		list451[temp617] = helper620
		list454[temp617] = {}
		local function helper621(connection)
			table.insert(list454[temp617], connection)
			return trackConnection(connection)
		end
		helper621(temp617.AncestryChanged:Connect(function()
			if not temp617.Parent then
				list451[temp617] = nil
				list452[temp619] = nil
				if list454[temp617] then
					for _, connection in ipairs(list454[temp617]) do
						disconnectTrackedConnection(connection)
					end
					list454[temp617] = nil
				end
			end
		end))
		helper620()
		helper621(temp617:GetAttributeChangedSignal("Favorite"):Connect(helper620))
		helper621(temp617:GetAttributeChangedSignal("Rarity"):Connect(helper620))
		helper621(temp617:GetAttributeChangedSignal("Mutation"):Connect(helper620))
	end
	local function helper456()
		local list622 = {}
		if LocalPlayer.Backpack then
			for key875, item876 in ipairs(LocalPlayer.Backpack:GetChildren()) do
				if item876:IsA("Tool") then
					table.insert(list622, item876)
				end
			end
		end
		if LocalPlayer.Character then
			for key877, item878 in ipairs(LocalPlayer.Character:GetChildren()) do
				if item878:IsA("Tool") then
					table.insert(list622, item878)
				end
			end
		end
		for key706, item707 in ipairs(list622) do
			task.spawn(helper455, item707, true)
		end
	end
	state.TriggerFavScan = function()
		task.spawn(helper456)
	end
	task.wait(5)
	helper456()
	trackConnection(LocalPlayer.Backpack.ChildAdded:Connect(function(arg623)
		local temp624 = 0
		while true do
			if 0 == temp624 then
				task.wait(0.2)
				task.spawn(helper455, arg623, false)
				break
			end
		end
	end))
	trackConnection(
		LocalPlayer.CharacterAdded:Connect(function(arg625)
			trackConnection(
				arg625.ChildAdded:Connect(function(arg708)
					if arg708:IsA("Tool") then
						local temp879 = 0
						while true do
							if 0 == temp879 then
								task.wait(0.2)
								task.spawn(helper455, arg708, false)
								break
							end
						end
					end
				end),
				"AutoFavCharChild"
			)
		end),
		"AutoFavCharacter"
	)
	task.spawn(function()
		while state.HubRunning do
			local temp709 = 0
			while true do
				if temp709 == 0 then
					task.wait(15)
					if state.AAutoFav then
						helper456()
					end
					break
				end
			end
		end
	end)
	task.spawn(function()
		local temp626 = 0
		local temp627
		while true do
			if temp626 == 1 then
				while state.HubRunning do
					local temp940 = 0
					while true do
						if temp940 == 0 then
							task.wait(0.55)
							if state.AAutoFav and (#list453 > 0) and temp627 then
								local temp1173 = table.remove(list453, 1)
								pcall(function()
									if toggleFavoriteRemote then
										toggleFavoriteRemote:FireServer(temp1173)
									else
										temp627.FireServer("ToggleFav", temp1173)
									end
								end)
							end
							break
						end
					end
				end
				break
			end
			if temp626 == 0 then
				temp627 = nil
				pcall(function()
					temp627 = require(game:GetService("ReplicatedStorage").Shared.Packages.Network)
				end)
				temp626 = 1
			end
		end
	end)
end)
task.spawn(function()
	local temp458 = getExecutorRequest()
	if not temp458 then
		return
	end
	local temp459 = {
		["Common"] = 7506394,
		["Uncommon"] = 32768,
		["Rare"] = 4886754,
		["Epic"] = 10181046,
		["Legendary"] = 16312092,
		["Mythical"] = 16508821,
		["Mythic"] = 16508821,
		["Secret"] = 16508821,
		["Divine"] = 16711935,
		["Hacked"] = 3066993,
		["OG"] = 9109500,
		["Celestial"] = 16763904,
		["Ethernal"] = 8092526,
		["Eternal"] = 11272192,
		["Exclusive"] = 11272192,
		["Random"] = 7506394,
	}
	local list460 = {}
	local list461 = {}
	local function helper467(guid)
		if not guid then
			return
		end
		if not list460[guid] then
			table.insert(list461, guid)
		end
		list460[guid] = true
		while #list461 > 500 do
			local oldGuid = table.remove(list461, 1)
			if oldGuid then
				list460[oldGuid] = nil
			end
		end
	end
	local function helper461(temp628)
		if not entitiesData or not entitiesData.LuckyBlocks then
			return "Unknown"
		end
		local temp629 = math.huge
		local temp630 = false
		for key710, item711 in pairs(entitiesData.LuckyBlocks) do
			if item711.Pool then
				for key941, item942 in ipairs(item711.Pool) do
					if (item942.Name == temp628) and item942.Chance then
						local temp1053 = 0
						while true do
							if temp1053 == 0 then
								temp630 = true
								if item942.Chance < temp629 then
									temp629 = item942.Chance
								end
								break
							end
						end
					end
				end
			end
		end
		if temp630 then
			if temp629 >= 1 then
				return tostring(temp629) .. "%"
			else
				return temp629 .. "% (1 in " .. math.floor(100 / temp629) .. ")"
			end
		end
		return "Exclusive / Special"
	end
	local function helper462(temp631)
		if not entitiesData or not entitiesData.Brainrots or not entitiesData.Brainrots[temp631] then
			return ""
		end
		local temp632 = entitiesData.Brainrots[temp631].Image
		if temp632 and (type(temp632) == "string") then
			local temp795 = 0
			local temp796
			while true do
				if temp795 == 0 then
					temp796 = temp632:match("rbxassetid://(%d+)")
					if temp796 then
						return "https://www.roblox.com/Thumbs/Asset.ashx?width=420&height=420&assetId=" .. temp796
					end
					break
				end
			end
		end
		return ""
	end
	local function helper463(temp633)
		if not temp633 or (temp633 == 0) then
			return "0"
		end
		if temp633 < 1000 then
			return tostring(temp633)
		end
		local temp634 = { "K", "M", "B", "T", "Q", "Qi", "S", "Sp", "O", "N", "D" }
		local temp635 = math.floor(math.log10(temp633) / 3)
		local temp636 = temp634[temp635] or ""
		local temp637 = temp633 / (10 ^ (temp635 * 3))
		return string.format("%.2f%s", temp637, temp636):gsub("%.00", "")
	end
	local function helper464(temp638)
		local temp639 = 0
		local temp640
		while true do
			if temp639 == 1 then
				if temp640.CPS then
					local temp1014 = coerceNumberValue(temp640.CPS)
					if temp1014 and (temp1014 > 0) then
						return helper463(temp1014) .. "/s"
					end
				end
				return "N/A"
			end
			if temp639 == 0 then
				if not entitiesData or not entitiesData.Brainrots or not entitiesData.Brainrots[temp638] then
					return "N/A"
				end
				temp640 = entitiesData.Brainrots[temp638]
				temp639 = 1
			end
		end
	end
	local function helper465(temp641)
		if not temp641:IsA("Tool") then
			return
		end
		local temp642 = tick()
		while temp641.Parent and ((tick() - temp642) < 3) do
			if temp641:GetAttribute("GUID") then
				break
			end
			task.wait(0.1)
		end
		local temp643 = temp641:GetAttribute("GUID")
		if not temp643 or list460[temp643] then
			return
		end
		helper467(temp643)
		task.wait(1.5)
		local temp645 = temp641.Name
		local temp646 = temp641:GetAttribute("Rarity") or "Unknown"
		local temp647 = temp641:GetAttribute("Mutation") or "None"
		if entitiesData and entitiesData.Brainrots and entitiesData.Brainrots[temp645] then
			local temp797 = 0
			local temp798
			while true do
				if temp797 == 0 then
					temp798 = entitiesData.Brainrots[temp645]
					if (temp646 == "Unknown") or (temp646 == "") then
						temp646 = temp798.Rarity or "Unknown"
					end
					break
				end
			end
		end
		local temp648 = matchesSelectionFilter(state.WBBrainrot, temp645, false)
			and matchesSelectionFilter(state.WBRarity, temp646, false)
			and matchesSelectionFilter(state.WBMutation, temp647, true)
		if temp648 and state.AWebhook and (state.WebhookURL ~= "") then
			local temp799 = 0
			local temp800
			local temp801
			local temp802
			local temp803
			local temp804
			local temp805
			while true do
				if 0 == temp799 then
					temp800 = helper461(temp645)
					temp801 = helper462(temp645)
					temp799 = 1
				end
				if temp799 == 3 then
					temp805 =
						{ ["username"] = "Luxy Hub Notifier", ["content"] = "@everyone", ["embeds"] = { temp804 } }
					task.spawn(function()
						sendWebhookPayload(state.WebhookURL, temp805)
					end)
					break
				end
				if temp799 == 2 then
					temp804 = {
						["title"] = "NEW INVENTORY BRAINROT CLAIMED!",
						["description"] = "A filtered brainrot has been successfully collected and secured in the players inventory!",
						["color"] = temp803,
						["fields"] = {
							{ ["name"] = "Brainrot", ["value"] = ("```" .. temp645 .. "```"), ["inline"] = true },
							{ ["name"] = "Rarity", ["value"] = ("```" .. temp646 .. "```"), ["inline"] = true },
							{ ["name"] = "Mutation", ["value"] = ("```" .. temp647 .. "```"), ["inline"] = true },
							{ ["name"] = "Drop Chance", ["value"] = ("```" .. temp800 .. "```"), ["inline"] = true },
							{ ["name"] = "CPS Value", ["value"] = ("```" .. temp802 .. "```"), ["inline"] = true },
							{
								["name"] = "Server JobId",
								["value"] = ("```" .. tostring(game.JobId) .. "```"),
								["inline"] = false,
							},
						},
						["footer"] = { ["text"] = "Luxy Hub v3.9 | Inventory Notifier" },
						["timestamp"] = DateTime.now():ToIsoDate(),
					}
					if temp801 ~= "" then
						temp804.thumbnail = { ["url"] = temp801 }
					end
					temp799 = 3
				end
				if temp799 == 1 then
					temp802 = helper464(temp645)
					temp803 = temp459[temp646] or 7506394
					temp799 = 2
				end
			end
		end
	end
	task.wait(10)
	pcall(function()
		local temp649 = 0
		while true do
			if temp649 == 0 then
				if LocalPlayer.Backpack then
					for key1054, item1055 in ipairs(LocalPlayer.Backpack:GetChildren()) do
						if item1055:IsA("Tool") then
							local temp1141 = 0
							local temp1142
							while true do
								if temp1141 == 0 then
									temp1142 = item1055:GetAttribute("GUID")
									if temp1142 then
										helper467(temp1142)
									end
									break
								end
							end
						end
					end
				end
				if LocalPlayer.Character then
					for key1056, item1057 in ipairs(LocalPlayer.Character:GetChildren()) do
						if item1057:IsA("Tool") then
							local temp1143 = item1057:GetAttribute("GUID")
							if temp1143 then
								helper467(temp1143)
							end
						end
					end
				end
				break
			end
		end
	end)
	trackConnection(
		LocalPlayer.Backpack.ChildAdded:Connect(function(arg650)
			local temp651 = 0
			while true do
				if 0 == temp651 then
					task.wait(0.5)
					helper465(arg650)
					break
				end
			end
		end),
		"WebhookBackpack"
	)
	local function helper466(temp652)
		if temp652:IsA("Tool") then
			local temp806 = 0
			while true do
				if temp806 == 0 then
					task.wait(0.5)
					helper465(temp652)
					break
				end
			end
		end
	end
	trackConnection(
		LocalPlayer.CharacterAdded:Connect(function(arg653)
			local temp654 = 0
			while true do
				if temp654 == 0 then
					trackConnection(arg653.ChildAdded:Connect(helper466), "WebhookCharChild")
					break
				end
			end
		end),
		"WebhookCharacter"
	)
	if LocalPlayer.Character then
		trackConnection(LocalPlayer.Character.ChildAdded:Connect(helper466), "WebhookCharChild")
	end
end)
local function formatAbbreviatedNumber(temp467)
	local temp468 = 0
	local temp469
	local temp470
	local temp471
	local temp472
	local temp473
	while true do
		if temp468 == 2 then
			temp473 = nil
			while true do
				local temp882 = 0
				while true do
					if temp882 == 1 then
						if temp469 == 2 then
							temp472 = temp470[temp471] or ""
							temp473 = temp467 / (10 ^ (temp471 * 3))
							temp469 = 3
						end
						if temp469 == 0 then
							if not temp467 or (temp467 == 0) then
								return "0"
							end
							if temp467 < 1000 then
								return tostring(temp467)
							end
							temp469 = 1
						end
						break
					end
					if temp882 == 0 then
						if 1 == temp469 then
							temp470 = { "K", "M", "B", "T", "Q", "Qi", "S", "Sp", "O", "N", "D" }
							temp471 = math.floor(math.log10(temp467) / 3)
							temp469 = 2
						end
						if 3 == temp469 then
							return string.format("%.2f%s", temp473, temp472):gsub("%.00", "")
						end
						temp882 = 1
					end
				end
			end
			break
		end
		if temp468 == 0 then
			temp469 = 0
			temp470 = nil
			temp468 = 1
		end
		if temp468 == 1 then
			temp471 = nil
			temp472 = nil
			temp468 = 2
		end
	end
end
task.spawn(function()
	local temp474 = ""
	local temp475 = 0
	if predictionStatus and predictionStatus.SetVisible then
		predictionStatus:SetVisible(state.APredict)
	end
	while state.HubRunning do
		task.wait(0.3)
		if state.APredict then
			pcall(function()
				local temp883 = 0
				local temp884
				local temp885
				local temp886
				local temp887
				local temp888
				local temp889
				while true do
					if temp883 == 1 then
						temp885 = string.split(temp884, ",")
						temp886 = (temp885[1] and string.gsub(temp885[1], "^%s*(.-)%s*$", "%1")) or "Unknown"
						temp883 = 2
					end
					if 0 == temp883 then
						local temp1058 = 0
						local temp1059
						while true do
							if temp1058 == 0 then
								temp1059 = 0
								while true do
									if temp1059 == 0 then
										temp884 = LocalPlayer:GetAttribute("InGame") or ""
										if temp884 == "" then
											local temp1349 = 0
											local temp1350
											while true do
												if temp1349 == 0 then
													temp1350 = 0
													while true do
														if temp1350 == 0 then
															if temp474 ~= "" then
																local temp1444 = 0
																while true do
																	if temp1444 == 0 then
																		temp474 = ""
																		if
																			predictionStatus
																			and predictionStatus.Update
																		then
																			predictionStatus:Update("Brainrot", "--")
																			predictionStatus:Update("Rarity", "--")
																			predictionStatus:Update("Mutation", "--")
																			predictionStatus:Update("CPS Value", "--")
																		end
																		break
																	end
																end
															end
															return
														end
													end
													break
												end
											end
										end
										temp1059 = 1
									end
									if temp1059 == 1 then
										temp883 = 1
										break
									end
								end
								break
							end
						end
					end
					if 3 == temp883 then
						temp888 = "Unknown"
						if entitiesData and entitiesData.Brainrots and entitiesData.Brainrots[temp886] then
							temp888 = entitiesData.Brainrots[temp886].Rarity or "Unknown"
						end
						temp883 = 4
					end
					if temp883 == 2 then
						local temp1060 = 0
						while true do
							if 1 == temp1060 then
								temp883 = 3
								break
							end
							if 0 == temp1060 then
								temp887 = (temp885[2] and string.gsub(temp885[2], "^%s*(.-)%s*$", "%1")) or "None"
								if temp887 == "" then
									temp887 = "None"
								end
								temp1060 = 1
							end
						end
					end
					if temp883 == 4 then
						temp889 = temp886 .. "_" .. temp887
						if (temp889 ~= temp474) or ((tick() - temp475) > 15) then
							temp474 = temp889
							temp475 = tick()
							local temp1144 = "N/A"
							if calculateBrainrotCps then
								local temp1233 = 0
								local temp1234
								while true do
									if temp1233 == 0 then
										temp1234 = calculateBrainrotCps(temp886, temp887, 1)
										if temp1234 then
											temp1144 = formatAbbreviatedNumber(temp1234) .. "/s"
										end
										break
									end
								end
							end
							if predictionStatus and predictionStatus.Update then
								local temp1235 = 0
								while true do
									if 0 == temp1235 then
										predictionStatus:Update("Brainrot", temp886)
										predictionStatus:Update("Rarity", temp888)
										temp1235 = 1
									end
									if temp1235 == 1 then
										predictionStatus:Update("Mutation", temp887)
										predictionStatus:Update("CPS Value", temp1144)
										break
									end
								end
							end
						end
						break
					end
				end
			end)
		end
	end
end)
local function resolveWeatherRecipeName(temp479)
	local temp480 = 0
	local temp481
	local temp482
	while true do
		if temp480 == 0 then
			if not sacrificeData or not sacrificeData.Recipes then
				return nil
			end
			temp481 = ""
			temp480 = 1
		end
		if 1 == temp480 then
			if type(temp479) == "table" then
				temp481 = temp479[1] or ""
			else
				temp481 = tostring(temp479)
			end
			temp482 = string.lower(temp481)
			temp480 = 2
		end
		if temp480 == 2 then
			for key892, item893 in pairs(sacrificeData.Recipes) do
				if string.lower(key892) == temp482 then
					return key892
				end
			end
			return nil
		end
	end
end
local function isWeatherEventActive(temp483)
	local temp484 = resolveWeatherRecipeName(temp483)
	if not temp484 then
		return false
	end
	if weatherServiceClient and weatherServiceClient.Events then
		local temp713 = 0
		local temp714
		while true do
			if temp713 == 0 then
				temp714 = weatherServiceClient.Events[temp484]
				if temp714 then
					local temp1061 = 0
					local temp1062
					while true do
						if temp1061 == 0 then
							temp1062 = workspace:GetServerTimeNow()
							if temp714 > temp1062 then
								return true
							end
							break
						end
					end
				end
				break
			end
		end
	end
	return false
end
local function canSummonWeatherEvent(temp485)
	local temp486 = 0
	local temp487
	local temp488
	local temp489
	local temp490
	local temp491
	local temp492
	while true do
		local temp655 = 0
		while true do
			if temp655 == 0 then
				if temp486 == 0 then
					local temp1018 = 0
					local temp1019
					while true do
						if 0 == temp1018 then
							temp1019 = 0
							while true do
								if temp1019 == 0 then
									temp487 = resolveWeatherRecipeName(temp485)
									if
										not temp487
										or not sacrificeData
										or not sacrificeData.Recipes
										or not sacrificeData.Recipes[temp487]
									then
										return false
									end
									temp1019 = 1
								end
								if temp1019 == 2 then
									temp486 = 1
									break
								end
								if temp1019 == 1 then
									temp488 = sacrificeData.Recipes[temp487]
									temp489 = {}
									temp1019 = 2
								end
							end
							break
						end
					end
				end
				if temp486 == 1 then
					for key1063, item1064 in ipairs(LocalPlayer.Backpack:GetChildren()) do
						if item1064:IsA("Tool") and item1064:GetAttribute("GUID") then
							table.insert(temp489, {
								["GUID"] = item1064:GetAttribute("GUID"),
								["Name"] = item1064.Name,
								["Mutation"] = (item1064:GetAttribute("Mutation") or "None"),
							})
						end
					end
					temp490 = LocalPlayer.Character
					if temp490 then
						for key1145, item1146 in ipairs(temp490:GetChildren()) do
							if item1146:IsA("Tool") and item1146:GetAttribute("GUID") then
								table.insert(temp489, {
									["GUID"] = item1146:GetAttribute("GUID"),
									["Name"] = item1146.Name,
									["Mutation"] = (item1146:GetAttribute("Mutation") or "None"),
								})
							end
						end
					end
					temp491 = {}
					temp486 = 2
				end
				temp655 = 1
			end
			if temp655 == 1 then
				if temp486 == 2 then
					temp492 = true
					for key1065, item1066 in ipairs(temp488) do
						local temp1067 = false
						local temp1068 = item1066.Name
						local temp1069 = item1066.Mutation or "Any"
						for key1123, item1124 in ipairs(temp489) do
							if not temp491[item1124.GUID] then
								if
									(item1124.Name == temp1068)
									and ((temp1069 == "Any") or (temp1069 == item1124.Mutation))
								then
									temp491[item1124.GUID] = true
									temp1067 = true
									break
								end
							end
						end
						if not temp1067 then
							temp492 = false
							break
						end
					end
					return temp492
				end
				break
			end
		end
	end
end
task.spawn(function()
	local temp507 = game:GetService("Players")
	local temp508 = game:GetService("VirtualUser")
	trackConnection(
		temp507.LocalPlayer.Idled:Connect(function()
			if state.AntiAFK then
				local idleConnections = getconnections or get_signal_cons
				local disabledIdleConnection = false
				if idleConnections then
					pcall(function()
						for _, connection in ipairs(idleConnections(temp507.LocalPlayer.Idled)) do
							connection:Disable()
							disabledIdleConnection = true
						end
					end)
				end
				if not disabledIdleConnection then
					pcall(function()
						temp508:CaptureController()
						temp508:ClickButton2(Vector2.new(0, 0))
					end)
				end
			end
		end),
		"AntiAfkIdle"
	)
end)
task.spawn(function()
	local temp509 = game:GetService("ReplicatedStorage"):FindFirstChild("ref_battle_create", true)
	local temp510 = game:GetService("ReplicatedStorage"):FindFirstChild("ref_battle_invite", true)
	local temp511 = game:GetService("ReplicatedStorage"):FindFirstChild("rev_battle_start", true)
	local temp512 = 0
	while state.HubRunning do
		task.wait(3)
		if state.AAutoBattle then
			pcall(function()
				local temp895 = require(game:GetService("ReplicatedStorage").Modules.UILoader.KickBattlesUI)
				if temp895 then
					local temp1021 = temp895.CurrentStatus
					if (temp1021 == nil) or (temp1021 == "None") or (temp1021 == "") then
						if temp509 then
							local temp1179 = 0
							local temp1180
							while true do
								if temp1179 == 0 then
									temp1180 =
										{ { ["GP"] = state.BattleGamepass, R = (tonumber(state.BattleRounds) or 3) } }
									task.spawn(function()
										pcall(function()
											temp509:InvokeServer(unpack(temp1180))
										end)
									end)
									break
								end
							end
						end
					elseif temp1021 == "Lobby" then
						if (tick() - temp512) >= 5 then
							local temp1272 = 0
							while true do
								if temp1272 == 0 then
									if temp510 then
										for key1396, item1397 in ipairs(game:GetService("Players"):GetPlayers()) do
											if item1397 ~= LocalPlayer then
												local temp1415 = 0
												while true do
													if 0 == temp1415 then
														task.spawn(function()
															pcall(function()
																temp510:InvokeServer(item1397)
															end)
														end)
														task.wait(0.3)
														break
													end
												end
											end
										end
									end
									temp512 = tick()
									break
								end
							end
						end
						local temp1181 = 0
						local temp1182 = LocalPlayer.PlayerGui:FindFirstChild("KickBattles")
						if temp1182 then
							for key1319, item1320 in ipairs(temp1182:GetDescendants()) do
								if item1320:IsA("TextLabel") and item1320.Visible and (item1320.Text ~= "") then
									for key1372, item1373 in ipairs(game:GetService("Players"):GetPlayers()) do
										if
											(item1373 ~= LocalPlayer)
											and (
												item1320.Text:find(item1373.DisplayName)
												or item1320.Text:find(item1373.Name)
											)
										then
											temp1181 = temp1181 + 1
											break
										end
									end
								end
							end
						end
						if temp1181 >= (state.BattleMinPlayers - 1) then
							if temp511 then
								pcall(function()
									temp511:FireServer()
								end)
							end
						end
					end
				end
			end)
		end
	end
end)
task.spawn(function()
	while state.HubRunning do
		task.wait(2)
		if state.AAutoAcceptBattle then
			pcall(function()
				local temp896 = 0
				local temp897
				while true do
					if temp896 == 0 then
						temp897 = LocalPlayer:FindFirstChild("PlayerGui")
						if temp897 then
							for key1183, item1184 in ipairs(temp897:GetDescendants()) do
								if item1184:IsA("TextButton") and item1184.Visible and item1184.Active then
									local temp1273 = 0
									local temp1274
									while true do
										if temp1273 == 0 then
											temp1274 = item1184.Text:lower()
											if
												temp1274:find("accept")
												or temp1274:find("join")
												or temp1274:find("terima")
											then
												local temp1382 = 0
												local temp1383
												local temp1384
												while true do
													if temp1382 == 1 then
														while temp1384 do
															if
																temp1384.Name:lower():find("battle")
																or temp1384.Name:lower():find("kick")
															then
																temp1383 = true
																break
															end
															temp1384 = temp1384.Parent
														end
														if temp1383 then
															pcall(function()
																local temp1445 = 0
																while true do
																	if temp1445 == 0 then
																		for key1459, item1460 in
																			ipairs(
																				getconnections(
																					item1184.MouseButton1Click
																				)
																			)
																		do
																			item1460:Fire()
																		end
																		for key1461, item1462 in
																			ipairs(getconnections(item1184.Activated))
																		do
																			item1462:Fire()
																		end
																		break
																	end
																end
															end)
														end
														break
													end
													if temp1382 == 0 then
														local temp1416 = 0
														while true do
															if 1 == temp1416 then
																temp1382 = 1
																break
															end
															if temp1416 == 0 then
																temp1383 = false
																temp1384 = item1184.Parent
																temp1416 = 1
															end
														end
													end
												end
											end
											break
										end
									end
								end
							end
						end
						break
					end
				end
			end)
		end
	end
end)
task.spawn(function()
	local temp513 = game:GetService("ReplicatedStorage"):FindFirstChild("rev_KickEvent", true)
	while state.HubRunning do
		task.wait(0.1)
		if state.AAutoMastery then
			local temp812 = 0
			local temp813
			local temp814
			local temp815
			local temp816
			while true do
				if temp812 == 1 then
					temp815 = temp813 and temp813:FindFirstChild("Humanoid")
					temp816 = workspace:FindFirstChild("Areas") and workspace.Areas:FindFirstChild("KickReady")
					temp812 = 2
				end
				if temp812 == 0 then
					temp813 = LocalPlayer.Character
					temp814 = temp813 and temp813:FindFirstChild("HumanoidRootPart")
					temp812 = 1
				end
				if temp812 == 2 then
					if temp814 and temp815 and (temp815.Health > 0) and temp816 and temp513 then
						local temp1125 = 0
						local temp1126
						local temp1127
						while true do
							if temp1125 == 1 then
								if temp1126 == "" then
									local temp1321 = 0
									local temp1322
									while true do
										if temp1321 == 0 then
											temp1322 = (temp814.Position - temp816.Position).Magnitude
											if temp1322 > 5 then
												temp814.CFrame = temp816.CFrame * CFrame.new(0, 3, 0)
											else
												local temp1399 = (state.MasteryKickPower or 50) / 100
												pcall(function()
													temp513:FireServer(0, temp1399)
												end)
											end
											break
										end
									end
								elseif temp1127 == "Died" then
									pcall(function()
										local temp1375 = 0
										local temp1376
										local temp1377
										while true do
											if temp1375 == 0 then
												local temp1409 = 0
												while true do
													if temp1409 == 1 then
														temp1375 = 1
														break
													end
													if temp1409 == 0 then
														temp1376 = LocalPlayer:FindFirstChild("PlayerGui")
														temp1377 = temp1376 and temp1376:FindFirstChild("KickMinigame")
														temp1409 = 1
													end
												end
											end
											if temp1375 == 1 then
												if temp1377 then
													local temp1428 = 0
													local temp1429
													while true do
														if temp1428 == 0 then
															temp1429 = tick() + 2.5
															while
																not temp1377.Enabled
																and (tick() < temp1429)
																and state.AAutoMastery
															do
																task.wait(0.05)
															end
															temp1428 = 1
														end
														if temp1428 == 1 then
															while
																temp1377.Enabled
																and (tick() < temp1429)
																and state.AAutoMastery
															do
																task.wait(0.05)
															end
															break
														end
													end
												else
													task.wait(1.5)
												end
												break
											end
										end
									end)
									local temp1351 = temp815:GetAttribute("DefaultHipHeight") or temp815.HipHeight
									local temp1352 = workspace.CurrentCamera
									temp815.HipHeight = temp1351
									temp1352.CameraType = Enum.CameraType.Scriptable
									temp1352.CFrame = temp816.CFrame * CFrame.new(0, 15, -25)
									temp1352.CFrame = CFrame.lookAt(temp1352.CFrame.Position, temp816.Position)
									temp815.Health = 0
									local temp1358 = LocalPlayer.CharacterAdded:Wait()
									local temp1359 = temp1358:WaitForChild("HumanoidRootPart", 5)
									local temp1360 = temp1358:WaitForChild("Humanoid", 5)
									if temp1359 and temp1360 then
										local temp1385 = 0
										while true do
											if temp1385 == 0 then
												task.wait(0.3)
												temp1359.CFrame = temp816.CFrame * CFrame.new(0, 3, 0)
												temp1385 = 1
											end
											if temp1385 == 1 then
												task.wait(0.2)
												temp1352.CameraType = Enum.CameraType.Custom
												temp1385 = 2
											end
											if temp1385 == 2 then
												temp1352.CameraSubject = temp1360
												break
											end
										end
									end
								elseif temp1127 == "TP" then
									local temp1386 = tick() + 3
									while state.HubRunning and state.AAutoMastery and (tick() < temp1386) do
										local temp1400 = LocalPlayer:GetAttribute("InGame") or ""
										if temp1400 == "" then
											break
										end
										pcall(function()
											local temp1410 = 0
											while true do
												if temp1410 == 0 then
													temp814.CFrame = temp816.CFrame * CFrame.new(0, 3, 0)
													temp814.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
													break
												end
											end
										end)
										task.wait(0.05)
									end
									temp814.CFrame = temp816.CFrame * CFrame.new(0, -5, 0)
									task.wait(0.1)
								end
								break
							end
							if temp1125 == 0 then
								temp1126 = LocalPlayer:GetAttribute("InGame") or ""
								temp1127 = state.MasteryResetMethod or "Died"
								temp1125 = 1
							end
						end
					end
					break
				end
			end
		end
	end
end)
task.spawn(function()
	while state.HubRunning do
		task.wait(0.1)
		if state.AAutoUpgrade and upgradeBrainrotRemote then
			if (#state.TUpgradeBase == 0) and state.TUpgrade and (#state.TUpgrade > 0) then
				for key1024, item1025 in ipairs(state.TUpgrade) do
					if item1025 ~= "Any" then
						local temp1128 = 0
						local temp1129
						while true do
							if temp1128 == 0 then
								temp1129 = string.gsub(item1025, "^%[Lv%.%d+%]%s*", "")
								if not table.find(state.TUpgradeBase, temp1129) then
									table.insert(state.TUpgradeBase, temp1129)
								end
								break
							end
						end
					end
				end
			end
			local temp818 = findPlayerPlot()
			local temp819 = LocalPlayer.Character
			local temp820 = temp819 and temp819:FindFirstChild("HumanoidRootPart")
			if temp818 and temp820 and temp818:FindFirstChild("Slots") then
				local temp952 = 0
				local temp953
				while true do
					if 0 == temp952 then
						temp953 = {}
						for key1149, item1150 in ipairs(temp818.Slots:GetChildren()) do
							local temp1151 = 0
							local temp1152
							while true do
								if temp1151 == 0 then
									temp1152 = item1150:FindFirstChild("PlacedPart")
									if temp1152 then
										local temp1341 = 0
										local temp1342
										while true do
											if temp1341 == 1 then
												if temp1342 then
													local temp1411 = 0
													local temp1412
													local temp1413
													local temp1414
													while true do
														if temp1411 == 1 then
															temp1414 = tonumber(string.match(item1150.Name, "%d+"))
															if temp1414 and (temp1413 < state.MaxUpLevel) then
																local temp1449 =
																	string.format("%s [%s]", temp1342.Name, temp1412)
																local temp1450 = false
																if
																	(#state.TUpgradeBase == 0)
																	or table.find(state.TUpgradeBase, "Any")
																then
																	temp1450 = true
																elseif table.find(state.TUpgradeBase, temp1449) then
																	temp1450 = true
																end
																if temp1450 then
																	table.insert(temp953, temp1414)
																end
															end
															break
														end
														if temp1411 == 0 then
															temp1412 = getMutationName(temp1342)
															temp1413 = temp1342:GetAttribute("Level")
																or temp1152:GetAttribute("Level")
																or 1
															temp1411 = 1
														end
													end
												end
												break
											end
											if temp1341 == 0 then
												temp1342 = nil
												for key1401, item1402 in ipairs(temp1152:GetChildren()) do
													if item1402:IsA("Model") and not item1402.Name:match("Hitbox") then
														temp1342 = item1402
														break
													end
												end
												temp1341 = 1
											end
										end
									end
									break
								end
							end
						end
						temp952 = 1
					end
					if temp952 == 1 then
						for key1153, item1154 in ipairs(temp953) do
							pcall(function()
								upgradeBrainrotRemote:FireServer(item1154)
							end)
							task.wait()
						end
						break
					end
				end
			end
		end
	end
end)
task.spawn(function()
	while state.HubRunning do
		local temp661 = 0
		local temp662
		while true do
			if temp661 == 0 then
				temp662 = 0
				while true do
					if temp662 == 0 then
						task.wait(2)
						if
							state.AAutoSummonWeather
							and (state.TTargetWeatherEvent ~= "None")
							and weatherSummonRemote
						then
							pcall(function()
								local temp1186 = 0
								local temp1187
								while true do
									if temp1186 == 0 then
										temp1187 = state.TTargetWeatherEvent
										if not isWeatherEventActive(temp1187) and canSummonWeatherEvent(temp1187) then
											local temp1361 = 0
											local temp1362
											while true do
												if temp1361 == 0 then
													temp1362 = resolveWeatherRecipeName(temp1187)
													if temp1362 then
														weatherSummonRemote:FireServer(temp1362)
														task.wait(5)
													end
													break
												end
											end
										end
										break
									end
								end
							end)
						end
						break
					end
				end
				break
			end
		end
	end
end)
uiLibrary:Notify({
	["Title"] = "Script Injected!",
	["Content"] = "Welcome to Luxy Hub V6. All functions loaded successfully.",
	["Duration"] = 5,
})

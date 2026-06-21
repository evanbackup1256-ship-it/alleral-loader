-- Alleral Noble V10 — runtime state bag
local State = {
	tabs = 0,
	groups = 0,
	controls = 0,
	tabCount = 0,
	groupCount = 0,
	windowCount = 0,
	notifManager = nil,
	search = nil,
	dropdownManager = nil,
	activeWindow = nil,
	missingBindings = {},
	errorLog = {},
	toggleKey = nil,
	uiDestroyed = false,
	groupRegistry = {},
	bootValidated = false,
}

function State:reset()
	self.tabs = 0
	self.groups = 0
	self.controls = 0
	self.tabCount = 0
	self.groupCount = 0
	self.notifManager = nil
	self.search = nil
	self.dropdownManager = nil
	self.activeWindow = nil
	self.missingBindings = {}
	self.uiDestroyed = false
	self.groupRegistry = {}
end

function State:log(lvl, msg, core)
	if core and type(core.say) == "function" then
		core.say("[" .. lvl .. "] " .. msg)
	end
	table.insert(self.errorLog, { lvl = lvl, msg = msg, ts = os.date("%H:%M:%S") })
end

return State
-- Alleral global text sanitizer + logging (UI, console, notifications)
local Log = {}
Log.VERSION = "1.0.0"

local TAG = "[Alleral]"

local BULLET = "\226\128\162"
local EM_DASH = "\226\128\148"
local EN_DASH = "\226\128\147"
local MULT = "\195\151"
local CHECK = "\226\156\133"
local CROSS = "\226\157\140"

local REPLACEMENTS = {
	{ "Ã¢â‚¬â€", EM_DASH },
	{ "Ã¢â‚¬â€œ", EN_DASH },
	{ "Ã¢â‚¬Å“", "\"" },
	{ "Ã¢â‚¬\157", "\"" },
	{ "Ã¢â‚¬â„¢", "'" },
	{ "Ã¢â‚¬Â", EM_DASH },
	{ "Ã¢â‚¬", EM_DASH },
	{ "Ã‚Â·", BULLET },
	{ "Â·", BULLET },
	{ "â€”", EM_DASH },
	{ "â€“", EN_DASH },
	{ "â€œ", "\"" },
	{ "â€\157", "\"" },
	{ "â€™", "'" },
	{ "â€", EM_DASH },
	{ "Ã—", MULT },
	{ "âœ…", CHECK },
	{ "âŒ", CROSS },
	{ "\195\162\226\130\172\226\128\156", EM_DASH },
	{ "\195\162\226\130\172\226\128\157", EM_DASH },
	{ "\195\162\226\130\172\194\162", BULLET },
	{ "\195\162\226\130\172\226\132\162", "'" },
	{ "\195\162\226\130\172\203\156", "'" },
	{ "\195\162\226\130\172", EM_DASH },
	{ "\226\128\162", BULLET },
	{ "\194\183", BULLET },
	{ "\226\128\148", EM_DASH },
	{ "\226\128\147", EN_DASH },
	{ "\226\128\153", "'" },
	{ "\226\128\152", "'" },
	{ "\226\128\156", "\"" },
	{ "\226\128\157", "\"" },
}

local function asciiFallback(text)
	text = text:gsub("•", " - ")
	text = text:gsub(BULLET, " - ")
	text = text:gsub(EM_DASH, "-")
	text = text:gsub(EN_DASH, "-")
	text = text:gsub(MULT, "x")
	text = text:gsub(CHECK, "[ok]")
	text = text:gsub(CROSS, "[x]")
	text = text:gsub("Â+", "")
	text = text:gsub("Ã.", "")
	text = text:gsub("â.", "")
	text = text:gsub("[^\32-\126\n\r\t]", "")
	return text
end

function Log.sanitize(value, maxLen)
	if value == nil then
		return ""
	end
	local s = tostring(value)
	for _, pair in ipairs(REPLACEMENTS) do
		s = s:gsub(pair[1], pair[2])
	end
	if s:find("Â", 1, true) or s:find("Ã", 1, true) or s:find("â", 1, true) then
		s = asciiFallback(s)
	end
	s = s:gsub("rbxassetid://%d+", "")
	s = s:gsub("rbxasset://[^%s]+", "")
	s = s:gsub("[%c]", " ")
	s = s:gsub("%s+", " ")
	s = s:gsub("^%s+", ""):gsub("%s+$", "")
	maxLen = tonumber(maxLen) or 240
	if #s > maxLen then
		s = s:sub(1, maxLen - 3) .. "..."
	end
	return s
end

function Log.pairLabel(left, right, maxLen)
	left = Log.sanitize(left, 64)
	right = Log.sanitize(right, maxLen or 120)
	if left == "" then
		return right
	end
	if right == "" then
		return left
	end
	return left .. " " .. BULLET .. " " .. right
end

function Log.info(msg)
	print(TAG .. " " .. Log.sanitize(msg, 2000))
end

function Log.warn(msg)
	warn(TAG .. " " .. Log.sanitize(msg, 2000))
end

function Log.error(msg)
	warn(TAG .. " ERROR " .. Log.sanitize(msg, 2000))
end

function Log.install(env)
	env = type(env) == "table" and env or {}
	env.Alleral_Log = Log
	env.Alleral_Text = {
		sanitize = Log.sanitize,
		pairLabel = Log.pairLabel,
	}
	return Log
end

pcall(function()
	if getgenv then
		Log.install(getgenv())
	end
end)

return Log
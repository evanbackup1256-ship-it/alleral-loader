-- Alleral V11 — global text sanitizer (shared with hub/log.luau)
return function()
	local Text = {}

	local function genv()
		local ok, env = pcall(function()
			return getgenv and getgenv() or getfenv()
		end)
		return ok and env or {}
	end

	local function sharedSanitize(value, maxLen)
		local env = genv()
		local logMod = env.Alleral_Log
		if type(logMod) == "table" and type(logMod.sanitize) == "function" then
			return logMod.sanitize(value, maxLen)
		end
		local textMod = env.Alleral_Text
		if type(textMod) == "table" and type(textMod.sanitize) == "function" then
			return textMod.sanitize(value, maxLen)
		end
		return nil
	end

	local BULLET = "\226\128\162"

	function Text.sanitize(value, maxLen)
		local shared = sharedSanitize(value, maxLen)
		if shared ~= nil then
			return shared
		end
		if value == nil then
			return ""
		end
		local s = tostring(value)
		s = s:gsub("Ã¢â‚¬â€", "\226\128\148")
		s = s:gsub("Ã¢â‚¬â€œ", "\226\128\147")
		s = s:gsub("Ã‚Â·", BULLET)
		s = s:gsub("Â·", BULLET)
		s = s:gsub("â€”", "\226\128\148")
		s = s:gsub("â€“", "\226\128\147")
		s = s:gsub("Ã—", "\195\151")
		s = s:gsub("âœ…", "\226\156\133")
		s = s:gsub("âŒ", "\226\157\140")
		s = s:gsub("Â", "")
		s = s:gsub("[%c]", " ")
		s = s:gsub("%s+", " ")
		s = s:gsub("^%s+", ""):gsub("%s+$", "")
		maxLen = tonumber(maxLen) or 240
		if #s > maxLen then
			s = s:sub(1, maxLen - 3) .. "..."
		end
		return s
	end

	function Text.sanitizeList(values)
		if type(values) ~= "table" then
			return {}
		end
		local out = {}
		for i, v in ipairs(values) do
			if type(v) == "table" then
				local copy = {}
				for k, val in pairs(v) do
					if k == "Title" or k == "Desc" or k == "Name" or k == "Text" then
						copy[k] = Text.sanitize(val, 120)
					else
						copy[k] = val
					end
				end
				out[i] = copy
			else
				out[i] = Text.sanitize(v, 120)
			end
		end
		return out
	end

	function Text.titleCasePhrase(text)
		text = Text.sanitize(text, 120)
		if text == "" then
			return text
		end
		return text:gsub("(%a)([%w_']*)", function(a, rest)
			return string.upper(a) .. string.lower(rest)
		end)
	end

	function Text.pairLabel(left, right, maxLen)
		local env = genv()
		if type(env.Alleral_Log) == "table" and type(env.Alleral_Log.pairLabel) == "function" then
			return env.Alleral_Log.pairLabel(left, right, maxLen)
		end
		left = Text.sanitize(left, 64)
		right = Text.sanitize(right, maxLen or 120)
		if left == "" then
			return right
		end
		if right == "" then
			return left
		end
		return left .. " " .. BULLET .. " " .. right
	end

	return Text
end
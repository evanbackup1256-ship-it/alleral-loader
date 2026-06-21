-- Alleral V11 — global UI text sanitizer (mojibake + truncation)
return function()
	local Text = {}

	local BULLET = "\226\128\162"
	local EM_DASH = "\226\128\148"
	local EN_DASH = "\226\128\147"

	local REPLACEMENTS = {
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
		{ "\195\151", "\195\151" },
		{ "\195\183", "\195\183" },
		{ "\226\151\143", "\226\151\143" },
		{ "\226\151\139", "\226\151\139" },
		{ "\194", "" },
	}

	function Text.sanitize(value, maxLen)
		if value == nil then return "" end
		local s = tostring(value)
		for _, pair in ipairs(REPLACEMENTS) do
			s = s:gsub(pair[1], pair[2])
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

	function Text.sanitizeList(values)
		if type(values) ~= "table" then return {} end
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
		if text == "" then return text end
		return text:gsub("(%a)([%w_']*)", function(a, rest)
			return string.upper(a) .. string.lower(rest)
		end)
	end

	function Text.pairLabel(left, right, maxLen)
		left = Text.sanitize(left, 64)
		right = Text.sanitize(right, maxLen or 120)
		if left == "" then return right end
		if right == "" then return left end
		return left .. " " .. BULLET .. " " .. right
	end

	return Text
end
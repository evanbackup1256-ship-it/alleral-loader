-- Alleral V11.1 — page build validation (no false "validation passed")
return function(Bootstrap)
	local Validate = {}

	function Validate.inspect(window, state)
		local report = {
			ok = true,
			issues = {},
			tabs = 0,
			controls = 0,
		}
		state = type(state) == "table" and state or {}
		report.controls = tonumber(state.controls) or 0

		if type(window) ~= "table" then
			report.ok = false
			table.insert(report.issues, "UI window missing")
			return report
		end

		local tabs = window._tabs
		if type(tabs) ~= "table" or #tabs < 1 then
			report.ok = false
			table.insert(report.issues, "No sidebar tabs registered")
		else
			report.tabs = #tabs
		end

		if report.controls < 1 then
			report.ok = false
			table.insert(report.issues, "No visible controls rendered")
		end

		if type(state.missingBindings) == "table" and #state.missingBindings > 8 then
			report.ok = false
			table.insert(report.issues, "Too many missing control bindings (" .. #state.missingBindings .. ")")
		end

		return report
	end

	function Validate.showError(window, issues)
		if type(window) ~= "table" or type(issues) ~= "table" then
			return
		end
		local tab = window._tabs and window._tabs[1]
		if not tab or type(tab.AddLeftGroupbox) ~= "function" then
			return
		end
		pcall(function()
			local grp = tab:AddLeftGroupbox("UI Diagnostics")
			if not grp or type(grp.AddLabel) ~= "function" then
				return
			end
			grp:AddLabel("UI validation failed")
			for _, issue in ipairs(issues) do
				grp:AddLabel(Bootstrap.sanitize("- " .. tostring(issue), 160))
			end
			grp:AddLabel("Reload the loader if this persists.")
		end)
	end

	function Validate.run(window, state)
		local report = Validate.inspect(window, state)
		if not report.ok then
			Validate.showError(window, report.issues)
			return false, report
		end
		return true, report
	end

	return Validate
end
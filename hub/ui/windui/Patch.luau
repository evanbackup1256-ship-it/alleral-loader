-- Alleral V11.3.1 — WindUI runtime patches (block native open/close lag)
return function(WindUI)
	local Patch = {}
	local patchedWindows = {}

	local function hideMain(windWindow)
		pcall(function()
			windWindow.Closed = true
			local main = windWindow.UIElements and windWindow.UIElements.Main
			if main then
				main.Visible = false
				local inner = main:FindFirstChild("Main", true)
				if inner and inner:IsA("GuiObject") then
					inner.Visible = false
				end
			end
		end)
	end

	function Patch.applyWindow(windWindow, handlers)
		if not windWindow or patchedWindows[windWindow] then
			return
		end
		handlers = type(handlers) == "table" and handlers or {}
		patchedWindows[windWindow] = true

		windWindow._AlleralNativeOpen = windWindow.Open
		windWindow._AlleralNativeClose = windWindow.Close
		windWindow._AlleralNativeToggle = windWindow.Toggle

		-- WindUI auto-spawns Open() on create — must stay noop (never animate)
		function windWindow.Open(_)
		end

		function windWindow.Close(_)
			if handlers.onHide then
				handlers.onHide()
			end
		end

		function windWindow.Toggle(_)
			if handlers.onToggle then
				handlers.onToggle()
			end
		end

		if windWindow.SetToggleKey then
			pcall(function()
				windWindow:SetToggleKey(nil)
			end)
		end

		hideMain(windWindow)
		Patch.stripBackdrop(windWindow)
	end

	function Patch.stripBackdrop(windWindow)
		pcall(function()
			if type(windWindow) == "table" then
				windWindow.Transparent = false
			end
			local main = windWindow and windWindow.UIElements and windWindow.UIElements.Main
			if typeof(main) == "Instance" then
				for _, child in ipairs(main:GetChildren()) do
					local n = child.Name:lower()
					if n:find("overlay", 1, true) or n:find("backdrop", 1, true) or n:find("dim", 1, true) then
						child.Visible = false
						if child:IsA("GuiObject") then
							child.BackgroundTransparency = 1
						end
					end
				end
			end
		end)
	end

	function Patch.applyLibrary(WindUIRef)
		if not WindUIRef or WindUIRef._AlleralLibraryPatched then
			return
		end
		WindUIRef._AlleralLibraryPatched = true

		pcall(function()
			if WindUIRef.TooltipGui then
				WindUIRef.TooltipGui.Enabled = false
				WindUIRef.TooltipGui.Visible = false
			end
		end)

		local nativeCreate = WindUIRef.CreateWindow
		if type(nativeCreate) ~= "function" then
			return
		end

		function WindUIRef.CreateWindow(self, config)
			config = type(config) == "table" and config or {}
			config.Folder = config.Folder or config.Title or "Alleral"
			local win = nativeCreate(self, config)
			if type(win) == "table" then
				win.Open = function() end
				win.Close = function() end
				win.Toggle = function() end
				win.Closed = true
				hideMain(win)
				Patch.stripBackdrop(win)
			end
			return win
		end
	end

	Patch.applyLibrary(WindUI)
	return Patch
end
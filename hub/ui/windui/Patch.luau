-- Alleral V11.3 — WindUI runtime patches (no native open/close/tooltip recursion)
return function(WindUI)
	local Patch = {}
	local patchedWindows = {}

	function Patch.applyWindow(windWindow, handlers)
		if not windWindow or patchedWindows[windWindow] then
			return
		end
		handlers = type(handlers) == "table" and handlers or {}
		patchedWindows[windWindow] = true

		windWindow._AlleralNativeOpen = windWindow.Open
		windWindow._AlleralNativeClose = windWindow.Close
		windWindow._AlleralNativeToggle = windWindow.Toggle

		function windWindow.Open(_)
			if handlers.onShow then
				handlers.onShow()
			end
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

		pcall(function()
			windWindow.Closed = true
			local main = windWindow.UIElements and windWindow.UIElements.Main
			if main then
				main.Visible = false
				local inner = main:FindFirstChild("Main")
				if inner and inner:IsA("GuiObject") then
					inner.Visible = false
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
			end
		end)
	end

	Patch.applyLibrary(WindUI)
	return Patch
end
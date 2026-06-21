-- Alleral V11.1 — premium EXE-6 / Raycast-style WindUI theme
return function(WindUI, Bootstrap)
	local Theme = {}
	Theme.NAME = "Alleral"
	Theme._registered = false

	local C = {
		Background = "#060914",
		Panel = "#0B1020",
		Card = "#101624",
		Card2 = "#151C2E",
		Border = "#25304A",
		Accent = "#8B5CF6",
		Accent2 = "#A855F7",
		Text = "#F8FAFC",
		Muted = "#94A3B8",
		Success = "#22C55E",
		Warning = "#F59E0B",
		Error = "#EF4444",
	}

	local function hex(h)
		return Color3.fromHex(h)
	end

	function Theme.register()
		if Theme._registered then
			pcall(function()
				if WindUI and WindUI.SetTheme then
					WindUI:SetTheme(Theme.NAME)
				end
			end)
			return true
		end
		if not WindUI or type(WindUI.AddTheme) ~= "function" then
			return false
		end
		local palette = {
			Name = Theme.NAME,
			Accent = hex(C.Accent),
			Primary = hex(C.Accent),
			Dialog = hex(C.Panel),
			Outline = hex(C.Border),
			Text = hex(C.Text),
			Placeholder = hex(C.Muted),
			Background = hex(C.Background),
			Button = hex(C.Accent2),
			Icon = hex(C.Accent),
			Toggle = hex(C.Accent),
			Slider = hex(C.Accent),
			Checkbox = hex(C.Accent),
			SliderIcon = hex(C.Muted),
			PanelBackground = hex(C.Panel),
			PanelBackgroundTransparency = 0.08,
			WindowBackground = hex(C.Background),
			ElementBackground = hex(C.Card),
			ElementBackgroundTransparency = 0.02,
			TabBackground = hex(C.Card),
			TabBackgroundHover = hex(C.Card2),
			TabBackgroundHoverTransparency = 0.04,
			TabBackgroundActive = hex(C.Card2),
			TabBackgroundActiveTransparency = 0.01,
			TabText = hex(C.Text),
			TabTextTransparency = 0.18,
			TabTextTransparencyActive = 0,
			TabIcon = hex(C.Accent),
			TabIconTransparency = 0.28,
			TabIconTransparencyActive = 0.03,
			TabBorderTransparency = 0.78,
			TabBorder = hex(C.Border),
			DropdownTabBackground = hex(C.Card2),
			DropdownBackground = hex(C.Panel),
			LabelBackground = hex(C.Card),
			LabelBackgroundTransparency = 0.28,
			SectionBox = hex(C.Card),
			SectionBoxTransparency = 0.02,
			SectionBoxBorder = hex(C.Border),
			SectionBoxBorderTransparency = 0.42,
			SectionBoxBackground = hex(C.Card2),
			SectionBoxBackgroundTransparency = 0.04,
			Notification = hex(C.Panel),
			NotificationTitle = hex(C.Text),
			NotificationContent = hex(C.Muted),
			NotificationBorder = hex(C.Border),
			NotificationBorderTransparency = 0.38,
		}
		pcall(function() WindUI:AddTheme(palette) end)
		pcall(function() WindUI:SetTheme(Theme.NAME) end)
		Theme._registered = true
		return true
	end

	function Theme.applyToWindow(windWindow)
		if not windWindow then
			return
		end
		pcall(function()
			if windWindow.SetPanelBackground then
				windWindow:SetPanelBackground(true)
			end
			if windWindow.HidePanelBackground ~= nil then
				windWindow.HidePanelBackground = false
			end
		end)
	end

	function Theme.colors()
		return C
	end

	return Theme
end
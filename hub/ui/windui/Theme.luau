-- Alleral V11.6 — EXE-6 dark glass theme (opaque panels, cyan/violet accents)
return function(WindUI, Bootstrap)
	local Theme = {}
	Theme.NAME = "Alleral"
	Theme._registered = false

	local C = {
		Background = "#020308",
		Panel = "#050810",
		Card = "#080D16",
		Card2 = "#0C121C",
		CardHover = "#101826",
		Border = "#1A2332",
		BorderGlow = "#2A3548",
		Accent = "#7C3AED",
		Accent2 = "#8B5CF6",
		AccentDeep = "#5B21B6",
		Cyan = "#06B6D4",
		CyanDeep = "#0891B2",
		Glow = "#6366F1",
		Text = "#F8FAFC",
		Muted = "#94A3B8",
		Success = "#34D399",
		Warning = "#FBBF24",
		Error = "#F87171",
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
			Icon = hex(C.Cyan),
			Toggle = hex(C.Accent),
			Slider = hex(C.Cyan),
			Checkbox = hex(C.Accent),
			SliderIcon = hex(C.Muted),
			PanelBackground = hex(C.Panel),
			PanelBackgroundTransparency = 0.02,
			WindowBackground = hex(C.Background),
			ElementBackground = hex(C.Card),
			ElementBackgroundTransparency = 0,
			TabBackground = hex(C.Card),
			TabBackgroundHover = hex(C.CardHover),
			TabBackgroundHoverTransparency = 0,
			TabBackgroundActive = hex(C.Card2),
			TabBackgroundActiveTransparency = 0,
			TabText = hex(C.Text),
			TabTextTransparency = 0.08,
			TabTextTransparencyActive = 0,
			TabIcon = hex(C.Cyan),
			TabIconTransparency = 0.12,
			TabIconTransparencyActive = 0,
			TabBorderTransparency = 0.55,
			TabBorder = hex(C.Accent),
			DropdownTabBackground = hex(C.Card2),
			DropdownBackground = hex(C.Panel),
			LabelBackground = hex(C.Card),
			LabelBackgroundTransparency = 0.08,
			SectionBox = hex(C.Card),
			SectionBoxTransparency = 0,
			SectionBoxBorder = hex(C.BorderGlow),
			SectionBoxBorderTransparency = 0.5,
			SectionBoxBackground = hex(C.Card2),
			SectionBoxBackgroundTransparency = 0,
			Notification = hex(C.Card2),
			NotificationTitle = hex(C.Text),
			NotificationContent = hex(C.Muted),
			NotificationBorder = hex(C.BorderGlow),
			NotificationBorderTransparency = 0.35,
			SearchBarBorder = hex(C.BorderGlow),
			SearchBarBorderTransparency = 0.45,
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
			if windWindow.Transparent ~= nil then
				windWindow.Transparent = false
			end
		end)
	end

	function Theme.colors()
		return C
	end

	function Theme.accent()
		return hex(C.Accent)
	end

	function Theme.accentBright()
		return hex(C.Accent2)
	end

	function Theme.cyan()
		return hex(C.Cyan)
	end

	function Theme.card()
		return hex(C.Card)
	end

	function Theme.card2()
		return hex(C.Card2)
	end

	return Theme
end
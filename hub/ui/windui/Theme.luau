-- Alleral V11.5 — Aurora glass theme (violet + cyan accent system)
return function(WindUI, Bootstrap)
	local Theme = {}
	Theme.NAME = "Alleral"
	Theme._registered = false

	local C = {
		Background = "#030508",
		Panel = "#080D18",
		Card = "#0C1220",
		Card2 = "#111827",
		CardHover = "#151F33",
		Border = "#1E293B",
		BorderGlow = "#334155",
		Accent = "#8B5CF6",
		Accent2 = "#A78BFA",
		AccentDeep = "#6D28D9",
		Cyan = "#22D3EE",
		CyanDeep = "#0891B2",
		Glow = "#6366F1",
		Text = "#F1F5F9",
		Muted = "#64748B",
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
			TabBackgroundHoverTransparency = 0.08,
			TabBackgroundActive = hex(C.Card2),
			TabBackgroundActiveTransparency = 0.03,
			TabText = hex(C.Text),
			TabTextTransparency = 0.14,
			TabTextTransparencyActive = 0,
			TabIcon = hex(C.Cyan),
			TabIconTransparency = 0.22,
			TabIconTransparencyActive = 0,
			TabBorderTransparency = 0.72,
			TabBorder = hex(C.BorderGlow),
			DropdownTabBackground = hex(C.Card2),
			DropdownBackground = hex(C.Panel),
			LabelBackground = hex(C.Card),
			LabelBackgroundTransparency = 0.32,
			SectionBox = hex(C.Card),
			SectionBoxTransparency = 0.05,
			SectionBoxBorder = hex(C.BorderGlow),
			SectionBoxBorderTransparency = 0.34,
			SectionBoxBackground = hex(C.Card2),
			SectionBoxBackgroundTransparency = 0.08,
			Notification = hex(C.Card2),
			NotificationTitle = hex(C.Text),
			NotificationContent = hex(C.Muted),
			NotificationBorder = hex(C.BorderGlow),
			NotificationBorderTransparency = 0.28,
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

	function Theme.accent()
		return hex(C.Accent)
	end

	function Theme.accentBright()
		return hex(C.Accent2)
	end

	function Theme.cyan()
		return hex(C.Cyan)
	end

	return Theme
end
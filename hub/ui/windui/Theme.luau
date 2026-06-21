-- Alleral V11 — premium EXE-6 / Raycast-style WindUI theme
return function(WindUI, Bootstrap)
	local Theme = {}
	Theme.NAME = "Alleral"

	local C = {
		Background = "#070B16",
		Panel = "#0D1222",
		Card = "#121827",
		CardHover = "#182033",
		Border = "#26324A",
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
			PanelBackgroundTransparency = 0.1,
			WindowBackground = hex(C.Background),
			ElementBackground = hex(C.Card),
			ElementBackgroundTransparency = 0.03,
			TabBackground = hex(C.Card),
			TabBackgroundHover = hex(C.CardHover),
			TabBackgroundHoverTransparency = 0.06,
			TabBackgroundActive = hex(C.CardHover),
			TabBackgroundActiveTransparency = 0.02,
			TabText = hex(C.Text),
			TabTextTransparency = 0.2,
			TabTextTransparencyActive = 0,
			TabIcon = hex(C.Accent),
			TabIconTransparency = 0.3,
			TabIconTransparencyActive = 0.04,
			TabBorderTransparency = 0.82,
			TabBorder = hex(C.Border),
			DropdownTabBackground = hex(C.CardHover),
			DropdownBackground = hex(C.Panel),
			LabelBackground = hex(C.Card),
			LabelBackgroundTransparency = 0.32,
			SectionBox = hex(C.Card),
			SectionBoxTransparency = 0.04,
			SectionBoxBorder = hex(C.Border),
			SectionBoxBorderTransparency = 0.5,
			SectionBoxBackground = hex(C.Card),
			SectionBoxBackgroundTransparency = 0.06,
			Notification = hex(C.Panel),
			NotificationTitle = hex(C.Text),
			NotificationContent = hex(C.Muted),
			NotificationBorder = hex(C.Border),
			NotificationBorderTransparency = 0.45,
		}
		pcall(function() WindUI:AddTheme(palette) end)
		pcall(function() WindUI:SetTheme(Theme.NAME) end)
		return true
	end

	local function polishFrame(frame)
		if typeof(frame) ~= "Instance" or not frame:IsA("GuiObject") then return end
		if frame:GetAttribute("AlleralPolished") then return end
		frame:SetAttribute("AlleralPolished", true)
		frame:SetAttribute("AlleralBaseTrans", frame.BackgroundTransparency)

		if not frame:FindFirstChildOfClass("UICorner") then
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 12)
			corner.Parent = frame
		end

		local stroke = frame:FindFirstChildOfClass("UIStroke")
		if not stroke then
			stroke = Instance.new("UIStroke")
			stroke.Parent = frame
		end
		stroke.Color = hex(C.Border)
		stroke.Transparency = 0.55
		stroke.Thickness = 1
	end

	function Theme.applyToWindow(windWindow)
		if not windWindow then return end
		pcall(function()
			if windWindow.SetPanelBackground then
				windWindow:SetPanelBackground(true)
			end
			if windWindow.HidePanelBackground ~= nil then
				windWindow.HidePanelBackground = false
			end
		end)

		pcall(function()
			local root = windWindow.UIElements and windWindow.UIElements.Main
				or windWindow.Main
				or windWindow.Frame
			if typeof(root) ~= "Instance" then return end
			for _, desc in ipairs(root:GetDescendants()) do
				if desc:IsA("Frame") and (desc.Name:lower():find("section") or desc.Name:lower():find("group") or desc.Name:lower():find("card")) then
					polishFrame(desc)
				end
			end
		end)
	end

	function Theme.colors()
		return C
	end

	return Theme
end
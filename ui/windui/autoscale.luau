--[[
	WindUI AutoScale runtime ? Footagesus WindUI (MIT)
	https://github.com/Footagesus/WindUI
	Docs: Window AutoScale fits the UI in the viewport with a 40px margin via SetUIScale.
]]

return function(WindUI)
	local Workspace = game:GetService("Workspace")

	local DEFAULTS = {
		margin = 40,
		minScale = 0.3,
		maxScale = 1.0,
		threshold = 0.05,
	}

	local viewportHooked = false

	local function computeScale(window, opts)
		opts = type(opts) == "table" and opts or DEFAULTS
		if type(window) ~= "table" or window.IsFullscreen or window.AutoScale == false then
			return nil
		end

		local camera = Workspace.CurrentCamera
		if not camera then
			return nil
		end

		local main = window.UIElements and window.UIElements.Main
		if not main or not main:IsA("GuiObject") then
			return nil
		end

		local abs = main.AbsoluteSize
		if abs.X <= 1 or abs.Y <= 1 then
			return nil
		end

		local margin = opts.margin or DEFAULTS.margin
		local vp = camera.ViewportSize
		local availX = vp.X - margin * 2
		local availY = vp.Y - margin * 2
		if availX <= 0 or availY <= 0 then
			return nil
		end

		local scale = math.min(availX / abs.X, availY / abs.Y)
		return math.clamp(scale, opts.minScale or DEFAULTS.minScale, opts.maxScale or DEFAULTS.maxScale)
	end

	local function applyScale(window, opts)
		if type(window) ~= "table" or type(window.SetUIScale) ~= "function" then
			return nil
		end

		opts = type(opts) == "table" and opts or DEFAULTS
		local base = computeScale(window, opts)
		if not base then
			return nil
		end

		local profileMul = 1
		if type(WindUI) == "table" then
			profileMul = tonumber(WindUI._AlleralUiScale) or 1
		end

		local minScale = opts.minScale or DEFAULTS.minScale
		local maxScale = opts.maxScale or DEFAULTS.maxScale
		local scale = math.clamp(base * profileMul, minScale, maxScale)
		local current = (type(window.GetUIScale) == "function" and window:GetUIScale()) or 1
		local threshold = opts.threshold or DEFAULTS.threshold

		if math.abs(scale - current) > threshold then
			pcall(function()
				window:SetUIScale(scale)
			end)
		end

		if type(WindUI) == "table" then
			WindUI._AlleralAutoScale = scale
		end
		return scale
	end

	local function bindViewport(window, opts, onRefresh)
		if type(window) ~= "table" then
			return
		end

		local function refresh()
			local scale = applyScale(window, opts)
			if type(onRefresh) == "function" then
				pcall(onRefresh, window, scale)
			end
		end

		local function hookCamera(camera)
			if not camera then
				return
			end
			pcall(function()
				camera:GetPropertyChangedSignal("ViewportSize"):Connect(refresh)
			end)
			task.defer(refresh)
			task.delay(0.08, refresh)
			task.delay(0.25, refresh)
		end

		hookCamera(Workspace.CurrentCamera)
		if not viewportHooked then
			viewportHooked = true
			Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
				hookCamera(Workspace.CurrentCamera)
			end)
		end
	end

	local api = {
		DEFAULTS = DEFAULTS,
		compute = computeScale,
		apply = applyScale,
		bind = bindViewport,
	}

	if type(WindUI) == "table" then
		WindUI.AutoScale = WindUI.AutoScale or {}
		function WindUI.AutoScale.Compute(_self, window, opts)
			return computeScale(window, opts)
		end
		function WindUI.AutoScale.Apply(_self, window, opts)
			return applyScale(window, opts)
		end
		function WindUI.AutoScale.Bind(_self, window, opts, onRefresh)
			bindViewport(window, opts, onRefresh)
		end
	end

	return api
end

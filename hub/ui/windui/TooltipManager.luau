-- Alleral V11.4 — tooltips disabled (no-op stub)
return function()
	local TooltipManager = {}

	function TooltipManager.init() end
	function TooltipManager.hide() end
	function TooltipManager.attach() end
	function TooltipManager.attachTab() end
	function TooltipManager.suppressDuringDrag() end
	function TooltipManager.getStats()
		return { connections = 0, visible = false, registry = 0 }
	end

	return TooltipManager
end
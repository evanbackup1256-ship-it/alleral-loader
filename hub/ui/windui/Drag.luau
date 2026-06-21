-- Alleral V12 — drag shim (delegates to DragManager when available)
return function(Motion, TooltipManager)
	local Drag = {}
	local delegate = nil

	function Drag.setDelegate(mgr)
		delegate = mgr
	end

	function Drag.cleanup(owner)
		if delegate and delegate.cleanup then
			pcall(delegate.cleanup, owner)
			return
		end
	end

	function Drag.isDragging(owner)
		if delegate and delegate.isDragging then
			return delegate.isDragging(owner)
		end
		return false
	end

	function Drag.bind(windWindow, handle, options)
		if delegate and delegate.bind then
			return delegate.bind(windWindow, options or { handle = handle })
		end
		return false
	end

	function Drag.logReady()
		if delegate and delegate.logReady then
			pcall(delegate.logReady)
		end
	end

	return Drag
end
-- Alleral Noble V10 — spring motion (Spr wrapper)
return function(Theme, Spr)
	local Motion = {}

	function Motion.safeSprTarget(target, damping, frequency, props)
		if typeof(target) ~= "Instance" then
			warn("[Alleral V10] Invalid Spr target:", tostring(target))
			return false
		end
		local ok, err = pcall(function()
			Spr.target(target, damping, frequency, props)
		end)
		if not ok then
			warn("[Alleral V10] Spr.target failed:", tostring(err))
			return false
		end
		return true
	end

	function Motion.spring(obj, props, preset)
		preset = preset or Theme.SPRING.SNAPPY
		return Motion.safeSprTarget(obj, preset[1], preset[2], props)
	end

	function Motion.stop(root, Spr)
		if typeof(root) ~= "Instance" then return end
		pcall(function() Spr.stop(root) end)
		for _, desc in ipairs(root:GetDescendants()) do
			pcall(function() Spr.stop(desc) end)
		end
	end

	return Motion
end
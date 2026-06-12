--[[
	Vendored third-party UI stack:
	Fusion, OnyxUI (+ ColorUtils), spr, vide, Plasma, Iris.
	Sources live under hub/ui/vendor/ — see vendor/SOURCES.md.
]]

return function(deps)
	deps = type(deps) == "table" and deps or {}
	local ModuleLoader = deps.ModuleLoader
	if not ModuleLoader then
		error("Vendor requires ModuleLoader", 0)
	end

	local loader = ModuleLoader

	local spr = loader.load("spr/spr")
	local Fusion = loader.load("Fusion")
	local ColorUtils = loader.load("ColorUtils")
	local OnyxUI = loader.load("onyx-ui")
	local Iris = loader.load("iris")
	local Plasma = loader.load("plasma")
	local vide = loader.load("vide/lib")

	return {
		spr = spr,
		Fusion = Fusion,
		ColorUtils = ColorUtils,
		OnyxUI = OnyxUI,
		Iris = Iris,
		Plasma = Plasma,
		vide = vide,
		Versions = {
			Fusion = "0.3",
			OnyxUI = "1.0.4",
			spr = "2024",
			vide = "0.4.0",
			Plasma = "main",
			Iris = "main",
			ColorUtils = "1.4",
		},
	}
end

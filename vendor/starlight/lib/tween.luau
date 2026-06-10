local TweenService = game:GetService("TweenService")
local Theme = require(script.Parent.theme)

local Tween = {}

function Tween.play(instance, goal, callback, info)
	local tween = TweenService:Create(instance, info or Theme.tweenInfo(), goal)
	if callback then
		tween.Completed:Once(callback)
	end
	tween:Play()
	return tween
end

function Tween.fade(instance, visible, callback)
	local props = {}
	if instance:IsA("GuiObject") then
		props.BackgroundTransparency = visible and (instance:GetAttribute("TargetTransparency") or 0) or 1
	end
	if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
		props.TextTransparency = visible and 0 or 1
	end
	if instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
		props.ImageTransparency = visible and 0 or 1
	end
	return Tween.play(instance, props, callback, Theme.tweenInfo(0.2))
end

return Tween

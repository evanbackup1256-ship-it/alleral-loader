-- Alleral UI layer — v7.1.0 Noble
--[[
	STANDALONE GUI RENDERING ENGINE
	UIScale-based animations. ScreenGui dropdown overlay.
	UIListLayout everywhere. Zero legacy dependencies.
]]

return function(Core)
	local TS = game:GetService("TweenService")
	local UIS = game:GetService("UserInputService")
	local Players = game:GetService("Players")
	local CoreGui = game:GetService("CoreGui")
	local RunService = game:GetService("RunService")

	-- ==================== THEME ====================
	local C = {
		VERSION = "7.1.0",
		WINDOW = { W = 780, H = 540, RADIUS = 12 },
		SIDEBAR = { W = 170, ICON_SIZE = 20, ITEM_H = 42, RADIUS = 8 },
		GROUP = { PADDING = 14, GAP = 12, RADIUS = 10, TITLE_H = 34 },
		CONTROL = { ROW_H = 36, GAP = 8, RADIUS = 6 },
		TOGGLE = { W = 40, H = 22, THUMB = 16, RADIUS = 11 },
		SLIDER = { TRACK_H = 6, THUMB = 14 },
		HEADER = { H = 48 }, FOOTER = { H = 28 },
		FONT = Enum.Font.Gotham, FONT_BOLD = Enum.Font.GothamBold,
		TEXT = 13, TEXT_SM = 11, TEXT_TITLE = 15, TEXT_HEADER = 18,
		COLOR = {
			BG0 = Color3.fromRGB(11, 16, 32), BG1 = Color3.fromRGB(17, 24, 39),
			BG2 = Color3.fromRGB(21, 27, 45), BG3 = Color3.fromRGB(30, 38, 58),
			BG4 = Color3.fromRGB(37, 47, 68),
			ACCENT = Color3.fromRGB(139, 92, 246), ACCENT_LIGHT = Color3.fromRGB(168, 95, 247),
			ACCENT_DARK = Color3.fromRGB(110, 70, 220),
			GREEN = Color3.fromRGB(34, 197, 94), GREEN_DARK = Color3.fromRGB(22, 140, 60),
			RED = Color3.fromRGB(239, 68, 68), RED_DARK = Color3.fromRGB(180, 50, 50),
			YELLOW = Color3.fromRGB(245, 158, 11), YELLOW_DARK = Color3.fromRGB(180, 115, 8),
			BLUE = Color3.fromRGB(59, 130, 246),
			TEXT = Color3.fromRGB(255, 255, 255), TEXT2 = Color3.fromRGB(161, 161, 170),
			TEXT3 = Color3.fromRGB(100, 110, 130), BORDER = Color3.fromRGB(37, 48, 68),
			WHITE = Color3.fromRGB(255, 255, 255),
			BACKDROP = Color3.fromRGB(0, 0, 0),
		},
		ANIM = { FAST = 0.12, NORM = 0.2, SPRING = 0.4 },
		NOTIF = { MAX = 6, W = 300, RADIUS = 8, TYPES = {
			success = { icon = "✓", c = Color3.fromRGB(34, 197, 94) },
			error = { icon = "✗", c = Color3.fromRGB(239, 68, 68) },
			warning = { icon = "⚠", c = Color3.fromRGB(245, 158, 11) },
			info = { icon = "ℹ", c = Color3.fromRGB(59, 130, 246) },
		}},
		KEYBIND = { DEFAULT = Enum.KeyCode.RightShift },
	}

	local ENV = (function()
		local ok, e = pcall(function() return getgenv and getgenv() or getfenv() end)
		return ok and e or {}
	end)()

	local STATE = {
		tabs = {}, groups = {}, controls = 0, activeTweens = {},
		tabCount = 0, groupCount = 0, windowCount = 0,
		notifContainer = nil, notifIdx = 0,
		missingBindings = {}, errorLog = {},
		toggleKey = C.KEYBIND.DEFAULT, uiDestroyed = false,
		dropOverlay = nil,
	}

	-- ==================== UTILITIES ====================
	local function log(l, m) if Core and type(Core.say) == "function" then Core.say("[" .. l .. "] " .. m) end; table.insert(STATE.errorLog, { lvl = l, msg = m, ts = os.date("%H:%M:%S") }) end
	local function sc(n, f, fb) if type(f) ~= "function" then return fb end; local o,r=pcall(f); if not o then log("WARN", n..": "..tostring(r)); return fb end; return r end
	local function textOf(v) if v==nil then return"" end; if type(v)=="table" then for _,k in ipairs({"Text","Content","Description","Message","Title","Name"}) do if v[k]~=nil then return textOf(v[k]) end end end; return tostring(v) end
	local function clone(v,s) if type(v)~="table" then return v end; s=s or{}; if s[v] then return s[v] end; local c={}; s[v]=c; for k,val in pairs(v) do c[clone(k,s)]=clone(val,s) end; return c end
	local function safeVis(o,v) if typeof(o)=="Instance" and o:IsA("GuiObject") then o.Visible = v==true end end

	-- ==================== ANIMATION ====================
	local Anim = {}
	function Anim.tween(i,p,d,s,dir)
		if typeof(i)~="Instance" then return nil end
		local t = TS:Create(i, TweenInfo.new(d or C.ANIM.NORM, s or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out, 0, false, 0), p)
		t:Play(); table.insert(STATE.activeTweens, t)
		t.Completed:Connect(function() for j,tt in ipairs(STATE.activeTweens) do if tt==t then table.remove(STATE.activeTweens,j); break end end end)
		return t
	end
	function Anim.fadeIn(i,d)
		if typeof(i)~="Instance" or not i:IsA("GuiObject") then return nil end
		d=d or C.ANIM.NORM; i.Visible=true; i.BackgroundTransparency=1
		if i:IsA("TextLabel") or i:IsA("TextButton") then i.TextTransparency=1 end
		local p={BackgroundTransparency=0}; if i:IsA("TextLabel") or i:IsA("TextButton") then p.TextTransparency=0 end
		return Anim.tween(i,p,d)
	end
	function Anim.fadeOut(i,d)
		if typeof(i)~="Instance" or not i:IsA("GuiObject") then return nil end
		d=d or C.ANIM.FAST
		local p={BackgroundTransparency=1}; if i:IsA("TextLabel") or i:IsA("TextButton") then p.TextTransparency=1 end
		return Anim.tween(i,p,d,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
	end

	-- UIScale-based scaling (Frames do NOT have a Scale property)
	function Anim.ensureUIScale(inst)
		local us = inst:FindFirstChildOfClass("UIScale")
		if not us then us = Instance.new("UIScale"); us.Parent = inst end
		return us
	end
	function Anim.centerIn(inst, dur)
		if typeof(inst)~="Instance" then return nil end
		inst.AnchorPoint = Vector2.new(0.5,0.5); inst.Position = UDim2.fromScale(0.5,0.5)
		inst.Visible = true
		local us = Anim.ensureUIScale(inst); us.Scale = 0.92
		Anim.tween(us, { Scale = 1 }, dur or C.ANIM.SPRING, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		return Anim.tween(inst, { BackgroundTransparency = 0 }, dur or C.ANIM.SPRING)
	end
	function Anim.centerOut(inst, dur, hide)
		if typeof(inst)~="Instance" then return nil end
		inst.AnchorPoint = Vector2.new(0.5,0.5); inst.Position = UDim2.fromScale(0.5,0.5)
		local us = Anim.ensureUIScale(inst); us.Scale = 1
		Anim.tween(us, { Scale = 0.95 }, dur or C.ANIM.FAST, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		local t = Anim.tween(inst, { BackgroundTransparency = 1 }, dur or C.ANIM.FAST)
		if hide~=false then t.Completed:Connect(function() inst.Visible = false end) end
		return t
	end

	function Anim.stopAll()
		for _,t in ipairs(STATE.activeTweens) do pcall(function() t:Cancel() end) end
		STATE.activeTweens = {}
	end

	-- ==================== COMPONENT FACTORY ====================
	local function make(c,p)
		local o=Instance.new(c)
		for k,v in pairs(p or {}) do
			if k=="Parent" then if typeof(v)=="Instance" then o.Parent=v end
			elseif k=="Children" then for _,ch in ipairs(v) do if typeof(ch)=="Instance" then ch.Parent=o end end
			else pcall(function() o[k]=v end) end
		end
		return o
	end
	local function corner(o,r) return make("UICorner",{CornerRadius=UDim.new(0,r or C.WINDOW.RADIUS),Parent=o}) end
	local function stroke(o,c,t,tr) return make("UIStroke",{Color=c or C.COLOR.BORDER,Thickness=t or 1,Transparency=tr or 0.5,Parent=o}) end
	local function gradient(o,c1,c2,r) return make("UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,c1 or C.COLOR.ACCENT),ColorSequenceKeypoint.new(1,c2 or C.COLOR.ACCENT_DARK)}),Rotation=r or 90,Parent=o}) end
	local function pad(o,l,r,t,b) return make("UIPadding",{PaddingLeft=UDim.new(0,l or 0),PaddingRight=UDim.new(0,r or 0),PaddingTop=UDim.new(0,t or 0),PaddingBottom=UDim.new(0,b or 0),Parent=o}) end

	-- ==================== DROPDOWN OVERLAY ====================
	local function getDropOverlay()
		if STATE.dropOverlay and STATE.dropOverlay.Parent then return STATE.dropOverlay end
		local sg = make("ScreenGui",{Name="AlleralDropdownOverlay",ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,DisplayOrder=200,Parent=(CoreGui:FindFirstChild("RobloxGui") or CoreGui)})
		local c = make("Frame",{Name="DropContainer",Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Parent=sg})
		STATE.dropOverlay = c; return c
	end

	-- ==================== CONTROL: LABEL ====================
	local function createLabel(parent, text, bold)
		local l=make("TextLabel",{BackgroundTransparency=1,Text=tostring(text or""),TextColor3=C.COLOR.TEXT,Font=bold and C.FONT_BOLD or C.FONT,TextSize=C.TEXT,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,RichText=false,Size=UDim2.new(1,0,0,20),Parent=parent})
		return {Set=function(_,v) local t=type(v)=="table" and (v.Name or v.Text or v.Content) or tostring(v); l.Text=tostring(t) end,SetText=function(_,t) l.Text=tostring(t) end,SetVisible=function(_,v) safeVis(l,v) end}
	end
	local function createDivider(parent) return make("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=C.COLOR.BORDER,BorderSizePixel=0,Parent=parent}) end

	-- ==================== CONTROL: TOGGLE ====================
	local function createToggle(parent, name, default, callback)
		local g=make("Frame",{Size=UDim2.new(1,0,0,C.CONTROL.ROW_H),BackgroundTransparency=1,Parent=parent})
		make("TextLabel",{Size=UDim2.new(1,-C.TOGGLE.W-12,1,0),BackgroundTransparency=1,Text=tostring(name),TextColor3=C.COLOR.TEXT,Font=C.FONT,TextSize=C.TEXT,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,TextTruncate=Enum.TextTruncate.AtEnd,Parent=g})
		local t=make("Frame",{Size=UDim2.new(0,C.TOGGLE.W,0,C.TOGGLE.H),Position=UDim2.new(1,-C.TOGGLE.W,0.5,-C.TOGGLE.H/2),BackgroundColor3=C.COLOR.BG4,BorderSizePixel=0,Parent=g}); corner(t,C.TOGGLE.RADIUS); stroke(t,C.COLOR.BORDER,1,0.6)
		local th=make("Frame",{Size=UDim2.new(0,C.TOGGLE.THUMB,0,C.TOGGLE.THUMB),Position=UDim2.new(0,3,0.5,-C.TOGGLE.THUMB/2),BackgroundColor3=C.COLOR.TEXT2,BorderSizePixel=0,ZIndex=2,Parent=t}); corner(th,8)
		local en=default==true
		if en then t.BackgroundColor3=C.COLOR.ACCENT; th.Position=UDim2.new(1,-C.TOGGLE.THUMB-3,0.5,-C.TOGGLE.THUMB/2); th.BackgroundColor3=C.COLOR.WHITE end
		local function tog() en=not en; Anim.tween(t,{BackgroundColor3=en and C.COLOR.ACCENT or C.COLOR.BG4},C.ANIM.FAST); Anim.tween(th,{Position=en and UDim2.new(1,-C.TOGGLE.THUMB-3,0.5,-C.TOGGLE.THUMB/2) or UDim2.new(0,3,0.5,-C.TOGGLE.THUMB/2),BackgroundColor3=en and C.COLOR.WHITE or C.COLOR.TEXT2},C.ANIM.FAST); if callback then callback(en) end end
		t.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then tog() end end)
		return {Set=function(_,v) local val; if type(v)=="table" then val=v.CurrentValue or v.Value else val=v end; if val~=nil and val~=en then tog() end end,SetValue=function(_,v) if v~=nil and v~=en then tog() end end,Container=g}
	end

	-- ==================== CONTROL: SLIDER ====================
	local function createSlider(parent, name, minVal, maxVal, default, callback, suffix, rounding)
		minVal=minVal or 0; maxVal=maxVal or 100; default=default or minVal; suffix=suffix or""; rounding=rounding or 1
		local g=make("Frame",{Size=UDim2.new(1,0,0,C.CONTROL.ROW_H+18),BackgroundTransparency=1,Parent=parent})
		local top=make("Frame",{Size=UDim2.new(1,0,0,C.CONTROL.ROW_H),BackgroundTransparency=1,Parent=g})
		make("TextLabel",{Size=UDim2.new(1,-60,1,0),BackgroundTransparency=1,Text=tostring(name),TextColor3=C.COLOR.TEXT,Font=C.FONT,TextSize=C.TEXT,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,TextTruncate=Enum.TextTruncate.AtEnd,Parent=top})
		local vl=make("TextLabel",{Size=UDim2.new(0,56,1,0),Position=UDim2.new(1,-56,0,0),BackgroundTransparency=1,Text=tostring(default)..suffix,TextColor3=C.COLOR.ACCENT_LIGHT,Font=C.FONT_BOLD,TextSize=C.TEXT_SM,TextXAlignment=Enum.TextXAlignment.Right,TextYAlignment=Enum.TextYAlignment.Center,Parent=top})
		local tr=make("Frame",{Size=UDim2.new(1,0,0,6),Position=UDim2.new(0,0,1,-10),BackgroundColor3=C.COLOR.BG4,BorderSizePixel=0,Parent=g}); corner(tr,3)
		local fl=make("Frame",{Size=UDim2.new(0,0,1,0),BackgroundColor3=C.COLOR.ACCENT,BorderSizePixel=0,ZIndex=1,Parent=tr}); corner(fl,3); gradient(fl,C.COLOR.ACCENT_LIGHT,C.COLOR.ACCENT,0)
		local tb=make("Frame",{Size=UDim2.new(0,C.SLIDER.THUMB,0,C.SLIDER.THUMB),Position=UDim2.new(0,0,0.5,-C.SLIDER.THUMB/2),BackgroundColor3=C.COLOR.WHITE,BorderSizePixel=0,ZIndex=3,Parent=tr}); corner(tb,7); stroke(tb,C.COLOR.ACCENT,2,0)
		local cv=default; local dr=false
		local function sv(f) cv=minVal+f*(maxVal-minVal); if rounding>=1 then cv=math.floor(cv/rounding+.5)*rounding else cv=math.floor(cv*(1/rounding)+.5)/(1/rounding) end; cv=math.clamp(cv,minVal,maxVal); local fr=(cv-minVal)/(maxVal-minVal); fl.Size=UDim2.new(fr,0,1,0); tb.Position=UDim2.new(fr,-C.SLIDER.THUMB/2,0.5,-C.SLIDER.THUMB/2); vl.Text=tostring(cv)..suffix end
		local function uf(x) local a=tr.AbsolutePosition.X; local s=tr.AbsoluteSize.X; if s<=0 then return end; sv(math.clamp((x-a)/s,0,1)); if callback then callback(cv) end end
		sv((default-minVal)/(maxVal-minVal))
		tr.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dr=true; uf(i.Position.X) end end)
		tr.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dr=false; if callback then callback(cv) end end end)
		UIS.InputChanged:Connect(function(i) if dr and i.UserInputType==Enum.UserInputType.MouseMovement then uf(i.Position.X) end end)
		return {Set=function(_,v) if type(v)=="table" then v=v.CurrentValue or v.Value end; if tonumber(v) then sv((v-minVal)/(maxVal-minVal)) end end,SetValue=function(_,v) if tonumber(v) then sv((v-minVal)/(maxVal-minVal)) end end,Container=g}
	end

	-- ==================== CONTROL: BUTTON ====================
	local function createButton(parent, name, callback)
		local g=make("Frame",{Size=UDim2.new(1,0,0,C.CONTROL.ROW_H),BackgroundTransparency=1,Parent=parent})
		local b=make("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundColor3=C.COLOR.BG3,BorderSizePixel=0,Text=tostring(name),TextColor3=C.COLOR.TEXT,Font=C.FONT_BOLD,TextSize=C.TEXT_SM+1,AutoButtonColor=false,Parent=g})
		corner(b,C.CONTROL.RADIUS); stroke(b,C.COLOR.BORDER,1,0.5)
		b.MouseEnter:Connect(function() Anim.tween(b,{BackgroundColor3=C.COLOR.ACCENT,TextColor3=C.COLOR.WHITE},C.ANIM.FAST) end)
		b.MouseLeave:Connect(function() Anim.tween(b,{BackgroundColor3=C.COLOR.BG3,TextColor3=C.COLOR.TEXT},C.ANIM.FAST) end)
		b.MouseButton1Down:Connect(function() Anim.tween(b,{BackgroundColor3=C.COLOR.ACCENT_DARK},C.ANIM.FAST) end)
		b.MouseButton1Up:Connect(function() Anim.tween(b,{BackgroundColor3=C.COLOR.ACCENT},C.ANIM.FAST) end)
		if callback then b.MouseButton1Click:Connect(function() Anim.tween(b,{BackgroundColor3=C.COLOR.ACCENT},C.ANIM.FAST); callback() end) end
		return {Set=function() end,Container=g}
	end

	-- ==================== CONTROL: INPUT ====================
	local function createInput(parent, name, default, placeholder, callback)
		default=default or""; placeholder=placeholder or"Enter..."
		local g=make("Frame",{Size=UDim2.new(1,0,0,C.CONTROL.ROW_H+18),BackgroundTransparency=1,Parent=parent})
		make("TextLabel",{Size=UDim2.new(1,0,0,C.CONTROL.ROW_H),BackgroundTransparency=1,Text=tostring(name),TextColor3=C.COLOR.TEXT2,Font=C.FONT,TextSize=C.TEXT_SM,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,Parent=g})
		local bx=make("TextBox",{Size=UDim2.new(1,0,0,28),Position=UDim2.new(0,0,0,C.CONTROL.ROW_H),BackgroundColor3=C.COLOR.BG3,BorderSizePixel=0,PlaceholderText=placeholder,PlaceholderColor3=C.COLOR.TEXT3,Text=tostring(default),TextColor3=C.COLOR.TEXT,Font=C.FONT,TextSize=C.TEXT_SM,TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false,Parent=g})
		corner(bx,C.CONTROL.RADIUS); stroke(bx,C.COLOR.BORDER,1,0.6)
		bx.Focused:Connect(function() Anim.tween(bx,{BackgroundColor3=C.COLOR.BG4},C.ANIM.FAST); stroke(bx,C.COLOR.ACCENT,2,0) end)
		bx.FocusLost:Connect(function(ep) Anim.tween(bx,{BackgroundColor3=C.COLOR.BG3},C.ANIM.FAST); stroke(bx,C.COLOR.BORDER,1,0.6); if callback then callback(bx.Text,ep) end end)
		return {Set=function(_,v) if type(v)=="table" then v=v.CurrentValue or v.Value or v.Text end; bx.Text=tostring(v or"") end,Container=g}
	end

	-- ==================== CONTROL: DROPDOWN (ScreenGui Overlay) ====================
	local function createDropdown(parent, name, options, default, callback, multi, searchable)
		options=type(options)=="table" and options or{}; multi=multi==true; searchable=searchable==true or multi==true
		local g=make("Frame",{Size=UDim2.new(1,0,0,C.CONTROL.ROW_H),BackgroundTransparency=1,Parent=parent})
		make("TextLabel",{Size=UDim2.new(0,100,1,0),BackgroundTransparency=1,Text=tostring(name),TextColor3=C.COLOR.TEXT2,Font=C.FONT,TextSize=C.TEXT_SM,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,Parent=g})
		local selected=multi and{} or(default or(options[1] or""))
		if multi and type(default)=="string" and default~="" then selected={default} end
		if multi and type(default)=="table" then selected=default end
		local function gdt() if multi then if #selected==0 then return"None selected" end; if #selected==1 then return tostring(selected[1]) end; return tostring(#selected).." selected" end; return tostring(selected) end
		local trig=make("TextButton",{Size=UDim2.new(1,-104,1,0),Position=UDim2.new(0,104,0,0),BackgroundColor3=C.COLOR.BG3,BorderSizePixel=0,Text=gdt(),TextColor3=C.COLOR.TEXT,Font=C.FONT,TextSize=C.TEXT_SM,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,AutoButtonColor=false,Parent=g})
		corner(trig,C.CONTROL.RADIUS); stroke(trig,C.COLOR.BORDER,1,0.5); pad(trig,8,24,0,0)
		make("TextLabel",{Size=UDim2.new(0,16,0,16),Position=UDim2.new(1,-20,0.5,-8),BackgroundTransparency=1,Text="v",TextColor3=C.COLOR.TEXT3,Font=C.FONT,TextSize=14,TextXAlignment=Enum.TextXAlignment.Center,TextYAlignment=Enum.TextYAlignment.Center,Parent=trig})

		-- Dropdown popup goes to ScreenGui overlay to avoid clipping
		local over = getDropOverlay()
		local dd=make("Frame",{Size=UDim2.new(0,200,0,0),BackgroundColor3=C.COLOR.BG2,BorderSizePixel=0,Visible=false,ZIndex=1000,Parent=over})
		corner(dd,C.CONTROL.RADIUS); stroke(dd,C.COLOR.ACCENT,1,0.3)
		make("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=C.COLOR.ACCENT,BorderSizePixel=0,ZIndex=1001,Parent=dd})
		local scr=make("ScrollingFrame",{Size=UDim2.new(1,0,0,0),Position=UDim2.new(0,0,0,2),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=C.COLOR.SCROLLBAR,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,Visible=true,ZIndex=1001,Parent=dd})
		local sll=make("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Parent=scr})

		local sb
		if searchable then
			sb=make("TextBox",{Size=UDim2.new(1,-8,0,24),Position=UDim2.new(0,4,0,2),BackgroundColor3=C.COLOR.BG3,BorderSizePixel=0,PlaceholderText="Search...",PlaceholderColor3=C.COLOR.TEXT3,Text="",TextColor3=C.COLOR.TEXT,Font=C.FONT,TextSize=C.TEXT_SM,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=1002,Parent=dd})
			corner(sb,4); scr.Position=UDim2.new(0,0,0,30)
		end

		local ofs={}
		local function rebuild(filt)
			for _,f in ipairs(ofs) do f:Destroy() end; ofs={}
			filt=filt and filt:lower()
			local f2={}
			for _,o in ipairs(options) do local s=tostring(o); if not filt or s:lower():find(filt,1,true) then table.insert(f2,o) end end
			for _,o in ipairs(f2) do
				local sel=multi and (function() for _,s in ipairs(selected) do if s==o then return true end end end)() or (selected==o)
				local f=make("TextButton",{Size=UDim2.new(1,0,0,30),BackgroundColor3=sel and C.COLOR.ACCENT or C.COLOR.BG2,BorderSizePixel=0,Text=tostring(o),TextColor3=sel and C.COLOR.WHITE or C.COLOR.TEXT,Font=C.FONT,TextSize=C.TEXT_SM,TextXAlignment=Enum.TextXAlignment.Left,AutoButtonColor=false,ZIndex=1001,Parent=scr}); pad(f,10,0,0,0)
				f.MouseEnter:Connect(function() if not sel then Anim.tween(f,{BackgroundColor3=C.COLOR.BG4},C.ANIM.FAST) end end)
				f.MouseLeave:Connect(function() if not sel then Anim.tween(f,{BackgroundColor3=C.COLOR.BG2},C.ANIM.FAST) end end)
				f.MouseButton1Click:Connect(function()
					if multi then local fd=false; for j,s in ipairs(selected) do if s==o then table.remove(selected,j); fd=true; break end end; if not fd then table.insert(selected,o) end
					else selected=(selected==o) and"" or o; dd.Visible=false; trig.Text=gdt() end
					trig.Text=gdt(); rebuild(sb and sb.Text or nil); if callback then callback(multi and selected or selected) end
				end)
				table.insert(ofs,f)
			end
			local contentH = #f2 * 30
			if sb then contentH = contentH + 30 end
			scr.Size = UDim2.new(1, 0, 0, math.min(contentH + 2, 240))
			dd.Size = UDim2.new(0, 200, 0, contentH + 6)
		end
		rebuild()

		-- Position dropdown in screen-space on open
		local function positionDD()
			local ap = trig.AbsolutePosition; local as = trig.AbsoluteSize
			local sx, sy = ap.X, ap.Y + as.Y + 4
			local ddH = dd.AbsoluteSize.Y
			local screenH = 1080 -- fallback
			pcall(function() screenH = UIS:GetScreenResolution().Y end)
			if sy + ddH > screenH and sy - ddH > 0 then sy = ap.Y - ddH - 4 end
			dd.Position = UDim2.fromOffset(sx, sy)
		end

		local open=false
		trig.MouseButton1Click:Connect(function()
			open=not open
			if open then
				rebuild(sb and sb.Text or nil); positionDD(); dd.Visible=true
				Anim.tween(dd,{BackgroundTransparency=0},C.ANIM.FAST)
			else dd.Visible=false end
		end)
		trig.MouseEnter:Connect(function() if not open then Anim.tween(trig,{BackgroundColor3=C.COLOR.BG4},C.ANIM.FAST) end end)
		trig.MouseLeave:Connect(function() if not open then Anim.tween(trig,{BackgroundColor3=C.COLOR.BG3},C.ANIM.FAST) end end)

		local function closeDD()
			if open then open=false; Anim.tween(dd,{BackgroundTransparency=1},C.ANIM.FAST); task.delay(C.ANIM.FAST+0.05,function() dd.Visible=false end); if multi and callback then callback(selected) end end
		end
		UIS.InputBegan:Connect(function(i)
			if i.UserInputType==Enum.UserInputType.MouseButton1 and open then
				local p=i.Position; local dp=dd.AbsolutePosition; local ds=dd.AbsoluteSize
				if not(p.X>=dp.X and p.X<=dp.X+ds.X and p.Y>=dp.Y and p.Y<=dp.Y+ds.Y) then
					local tp=trig.AbsolutePosition; local ts=trig.AbsoluteSize
					if not(p.X>=tp.X and p.X<=tp.X+ts.X and p.Y>=tp.Y and p.Y<=tp.Y+ts.Y) then closeDD() end
				end
			end
		end)
		if sb then sb:GetPropertyChangedSignal("Text"):Connect(function() rebuild(sb.Text); positionDD() end) end

		return {Set=function(_,v) if type(v)=="table" then if v.Options or v.Values then options=v.Options or v.Values or options; rebuild(sb and sb.Text or nil) end; local p=v.CurrentOption or v.CurrentOptions; if p~=nil then if multi then selected=type(p)=="table" and p or{tostring(p)} else selected=tostring(p) end; trig.Text=gdt(); rebuild(sb and sb.Text or nil) end end end,SetValue=function(_,v) if v~=nil then if multi then selected=type(v)=="table" and v or{tostring(v)} else selected=tostring(v) end; trig.Text=gdt(); rebuild(sb and sb.Text or nil) end end,Refresh=function(_,n) options=type(n)=="table" and n or options; rebuild(sb and sb.Text or nil) end,Container=g}
	end

	-- ==================== GROUP CARD ====================
	local function createGroup(parent, title, column, columnWidth)
		local w = columnWidth or 300
		local card = make("Frame",{Size=UDim2.new(0,w,0,0),BackgroundColor3=C.COLOR.BG2,BorderSizePixel=0,AutomaticSize=Enum.AutomaticSize.Y,Parent=parent})
		corner(card,C.GROUP.RADIUS); stroke(card,C.COLOR.BORDER,1,0.5)
		make("Frame",{Size=UDim2.new(1,0,0,3),BackgroundColor3=C.COLOR.ACCENT,BorderSizePixel=0,ZIndex=2,Parent=card})

		make("Frame",{Size=UDim2.new(1,0,0,C.GROUP.TITLE_H),BackgroundColor3=C.COLOR.BG3,BorderSizePixel=0,Parent=card,Children={make("TextLabel",{Size=UDim2.new(1,-C.GROUP.PADDING*2,1,0),Position=UDim2.new(0,C.GROUP.PADDING,0,0),BackgroundTransparency=1,Text=tostring(title or"Group"),TextColor3=C.COLOR.TEXT,Font=C.FONT_BOLD,TextSize=C.TEXT_TITLE,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center})}})

		local content=make("Frame",{Size=UDim2.new(1,0,0,0),Position=UDim2.new(0,0,0,C.GROUP.TITLE_H+6),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,Parent=card})
		pad(content,C.GROUP.PADDING,C.GROUP.PADDING,0,C.GROUP.PADDING)
		local cl=make("UIListLayout",{Padding=UDim.new(0,C.CONTROL.GAP),SortOrder=Enum.SortOrder.LayoutOrder,Parent=content})
		cl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() card.Size=UDim2.new(0,w,0,C.GROUP.TITLE_H+6+cl.AbsoluteContentSize.Y+C.GROUP.PADDING) end)

		return {_card=card,_content=content,
			AddLabel=function(_,t) local l=createLabel(content,t); STATE.controls=STATE.controls+1; return l end,
			CreateLabel=function(_,s) local t=type(s)=="table" and(s.Name or s.Text)or tostring(s or""); local l=createLabel(content,t); STATE.controls=STATE.controls+1; return l end,
			AddToggle=function(_,fl,p) p=p or{}; local t=createToggle(content,p.Text or fl,p.Default); STATE.controls=STATE.controls+1; return t end,
			AddSlider=function(_,fl,p) p=p or{}; local s=createSlider(content,p.Text or fl,p.Min or 0,p.Max or 100,p.Default or p.Min or 0,p.Callback,p.Suffix,p.Rounding or 1); STATE.controls=STATE.controls+1; return s end,
			AddButton=function(_,p) p=p or{}; local b=createButton(content,p.Text or"Button",p.Func); STATE.controls=STATE.controls+1; return b end,
			AddInput=function(_,fl,p) p=p or{}; local i=createInput(content,p.Text or fl,p.Default or"",p.Placeholder or"Enter...",p.Callback); STATE.controls=STATE.controls+1; return i end,
			AddDropdown=function(_,fl,p) p=p or{}; local d=createDropdown(content,p.Text or fl,p.Values or{},p.Default,p.Callback,p.Multi,p.Searchable); STATE.controls=STATE.controls+1; return d end,
			AddDivider=function() createDivider(content); STATE.controls=STATE.controls+1; return{} end,
		}
	end

	-- ==================== TAB PANEL ====================
	local function createTab(window, name, iconId, columns)
		columns=math.max(1,math.min(3,tonumber(columns) or 2))
		local ca=window._contentArea; local cw=ca.AbsoluteSize.X-C.GROUP.PADDING*2
		local panel=make("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Visible=false,Parent=ca})
		local scroll=make("ScrollingFrame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=6,ScrollBarImageColor3=C.COLOR.SCROLLBAR,AutomaticCanvasSize=Enum.AutomaticSize.Y,Parent=panel}); pad(scroll,C.GROUP.PADDING,C.GROUP.PADDING,C.GROUP.PADDING,C.GROUP.PADDING)
		local cw2=math.max(200,(cw-C.GROUP.GAP*(columns-1)-C.GROUP.PADDING*2)/columns)
		local cfs={}
		for i=1,columns do
			local cf=make("Frame",{Size=UDim2.new(0,cw2,0,0),Position=UDim2.new(0,(i-1)*(cw2+C.GROUP.GAP),0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,Parent=scroll})
			make("UIListLayout",{Padding=UDim.new(0,C.GROUP.GAP),SortOrder=Enum.SortOrder.LayoutOrder,Parent=cf}); cfs[i]=cf
		end
		return {_panel=panel,_scroll=scroll,_columns=columns,_colFrames=cfs,_columnWidth=cw2,_window=window,
			AddLeftGroupbox=function(_,gn) if not cfs[1] then return nil end; return createGroup(cfs[1],gn,1,cw2) end,
			AddRightGroupbox=function(_,gn) if not cfs[2] then return nil end; return createGroup(cfs[2],gn,2,cw2) end,
			AddGroupbox=function(_,gn) if cfs[1] then return createGroup(cfs[1],gn,1,cw2) end; return nil end,
			Select=function(self) window:selectTab(self) end,
		}
	end

	-- ==================== WINDOW ====================
	local function createWindow(settings)
		settings=settings or{}; STATE.windowCount=STATE.windowCount+1; local uid=STATE.windowCount
		local screen=make("ScreenGui",{Name="AlleralUI_"..uid,ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,DisplayOrder=100,Parent=(CoreGui:FindFirstChild("RobloxGui") or CoreGui)})
		local winSize=settings.Size or UDim2.fromOffset(C.WINDOW.W,C.WINDOW.H)

		local main=make("Frame",{Size=winSize,AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),BackgroundColor3=C.COLOR.BG1,BorderSizePixel=0,ClipsDescendants=true,ZIndex=1,Parent=screen})
		corner(main,C.WINDOW.RADIUS); stroke(main,C.COLOR.BORDER,1.5,0.4)

		-- Header
		local header=make("Frame",{Size=UDim2.new(1,0,0,C.HEADER.H),BackgroundColor3=C.COLOR.BG0,BorderSizePixel=0,ZIndex=2,Parent=main}); corner(header,C.WINDOW.RADIUS)
		make("TextLabel",{Size=UDim2.new(0,0,1,0),Position=UDim2.new(0,14,0,0),BackgroundTransparency=1,Text="Alleral",TextColor3=C.COLOR.TEXT,Font=C.FONT_BOLD,TextSize=C.TEXT_HEADER,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,AutomaticSize=Enum.AutomaticSize.X,ZIndex=3,Parent=header})
		make("Frame",{Size=UDim2.new(0,50,0,18),Position=UDim2.new(0,85,0.5,-9),BackgroundColor3=C.COLOR.ACCENT,BorderSizePixel=0,ZIndex=3,Parent=header,Children={make("TextLabel",{Size=UDim2.new(1,-6,1,0),Position=UDim2.new(0,3,0,0),BackgroundTransparency=1,Text=C.VERSION,TextColor3=C.COLOR.WHITE,Font=C.FONT_BOLD,TextSize=10,ZIndex=3})}})
		local kbLbl=make("TextLabel",{Size=UDim2.new(0,150,1,0),Position=UDim2.new(0,145,0,0),BackgroundTransparency=1,Text="",TextColor3=C.COLOR.TEXT3,Font=C.FONT,TextSize=C.TEXT_SM,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,ZIndex=3,Parent=header})
		pcall(function() local kn=tostring(STATE.toggleKey):gsub("Enum%.KeyCode%.",""):gsub("Enum%.",""); kbLbl.Text="Toggle: "..kn end)
		local closeBtn=make("TextButton",{Size=UDim2.new(0,28,0,28),Position=UDim2.new(1,-34,0,10),BackgroundColor3=C.COLOR.BG0,BorderSizePixel=0,Text="x",TextColor3=C.COLOR.TEXT2,Font=C.FONT,TextSize=16,AutoButtonColor=false,ZIndex=3,Parent=header})
		corner(closeBtn,6)
		closeBtn.MouseEnter:Connect(function() Anim.tween(closeBtn,{BackgroundColor3=C.COLOR.RED_DARK,TextColor3=C.COLOR.WHITE},C.ANIM.FAST) end)
		closeBtn.MouseLeave:Connect(function() Anim.tween(closeBtn,{BackgroundColor3=C.COLOR.BG0,TextColor3=C.COLOR.TEXT2},C.ANIM.FAST) end)

		-- Sidebar
		local sidebar=make("Frame",{Size=UDim2.new(0,C.SIDEBAR.W,1,-C.HEADER.H-C.FOOTER.H),Position=UDim2.new(0,0,0,C.HEADER.H),BackgroundColor3=C.COLOR.BG0,BorderSizePixel=0,ZIndex=1,Parent=main})
		make("UIListLayout",{Padding=UDim.new(0,2),SortOrder=Enum.SortOrder.LayoutOrder,Parent=sidebar}); pad(sidebar,6,6,6,6)

		-- Content area
		local contentH=C.HEADER.H+C.FOOTER.H
		local contentArea=make("Frame",{Size=UDim2.new(1,-C.SIDEBAR.W,1,-contentH),Position=UDim2.new(0,C.SIDEBAR.W,0,C.HEADER.H),BackgroundColor3=C.COLOR.BG1,BorderSizePixel=0,ZIndex=0,Parent=main})

		-- Footer
		local footer=make("Frame",{Size=UDim2.new(1,-C.SIDEBAR.W,0,C.FOOTER.H),Position=UDim2.new(0,C.SIDEBAR.W,1,-C.FOOTER.H),BackgroundColor3=C.COLOR.BG0,BorderSizePixel=0,ZIndex=2,Parent=main})
		make("TextLabel",{Size=UDim2.new(1,-16,1,0),Position=UDim2.new(0,8,0,0),BackgroundTransparency=1,Text="Noble Engine v"..C.VERSION,TextColor3=C.COLOR.TEXT3,Font=C.FONT,TextSize=C.TEXT_SM-1,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,ZIndex=3,Parent=footer})
		local footerKb=make("TextLabel",{Size=UDim2.new(0,150,1,0),Position=UDim2.new(1,-150,0,0),BackgroundTransparency=1,Text="",TextColor3=C.COLOR.TEXT3,Font=C.FONT,TextSize=C.TEXT_SM-1,TextXAlignment=Enum.TextXAlignment.Right,TextYAlignment=Enum.TextYAlignment.Center,ZIndex=3,Parent=footer})
		pcall(function() local kn=tostring(STATE.toggleKey):gsub("Enum%.KeyCode%.",""):gsub("Enum%.",""); footerKb.Text="Toggle: "..kn end)

		-- Tab system
		local tabs={}; local activeTab=nil
		local function selectTab(tab)
			if activeTab==tab then return end
			if activeTab then safeVis(activeTab._panel,false); if activeTab._sidebarBtn then Anim.tween(activeTab._sidebarBtn,{BackgroundColor3=C.COLOR.BG0},C.ANIM.FAST); if activeTab._sidebarLabel then Anim.tween(activeTab._sidebarLabel,{TextColor3=C.COLOR.TEXT2},C.ANIM.FAST) end end end
			safeVis(tab._panel,true); Anim.fadeIn(tab._panel,C.ANIM.FAST)
			if tab._sidebarBtn then Anim.tween(tab._sidebarBtn,{BackgroundColor3=C.COLOR.ACCENT},C.ANIM.FAST); if tab._sidebarLabel then Anim.tween(tab._sidebarLabel,{TextColor3=C.COLOR.WHITE},C.ANIM.FAST) end end
			activeTab=tab
		end

		-- Hide/Show system
		local uiHidden=false; local wc={}
		function wc:Hide() if uiHidden then return end; uiHidden=true; Anim.stopAll(); Anim.centerOut(main,0.15) end
		function wc:Show() if not uiHidden then return end; uiHidden=false; Anim.stopAll(); Anim.centerIn(main,0.25) end
		function wc:Toggle() if uiHidden then wc:Show() else wc:Hide() end end
		closeBtn.MouseButton1Click:Connect(function() wc:Hide() end)

		local w=setmetatable({_main=main,_header=header,_sidebar=sidebar,_contentArea=contentArea,_screen=screen,_tabs=tabs,_footer=footer,_kbLabel=kbLbl,_footerKb=footerKb,Hide=wc.Hide,Show=wc.Show,Toggle=wc.Toggle,selectTab=selectTab},{__index=wc})

		function w:AddTab(name,iconId)
			local to=createTab(self,name,iconId,2)
			local sb=make("TextButton",{Size=UDim2.new(1,0,0,C.SIDEBAR.ITEM_H),BackgroundColor3=C.COLOR.BG0,BorderSizePixel=0,Text="",AutoButtonColor=false,ZIndex=2,Parent=sidebar}); corner(sb,C.SIDEBAR.RADIUS)
			make("Frame",{Size=UDim2.new(0,0,1,-8),Position=UDim2.new(0,0,0,4),BackgroundColor3=C.COLOR.ACCENT,BorderSizePixel=0,ZIndex=4,Parent=sb})
			local ic; if iconId then ic=make("ImageLabel",{Size=UDim2.new(0,C.SIDEBAR.ICON_SIZE,0,C.SIDEBAR.ICON_SIZE),Position=UDim2.new(0,10,0.5,-C.SIDEBAR.ICON_SIZE/2),BackgroundTransparency=1,Image=type(iconId)=="number" and("rbxassetid://"..iconId)or iconId,ZIndex=3,Parent=sb}) end
			local sl=make("TextLabel",{Size=UDim2.new(1,-(ic and C.SIDEBAR.ICON_SIZE+20 or 14),1,0),Position=UDim2.new(0,ic and C.SIDEBAR.ICON_SIZE+16 or 10,0,0),BackgroundTransparency=1,Text=tostring(name),TextColor3=C.COLOR.TEXT2,Font=C.FONT,TextSize=C.TEXT,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=3,Parent=sb})
			to._sidebarBtn=sb; to._sidebarLabel=sl
			sb.MouseEnter:Connect(function() if activeTab~=to then Anim.tween(sb,{BackgroundColor3=C.COLOR.BG3},C.ANIM.FAST); Anim.tween(sl,{TextColor3=C.COLOR.TEXT},C.ANIM.FAST) end end)
			sb.MouseLeave:Connect(function() if activeTab~=to then Anim.tween(sb,{BackgroundColor3=C.COLOR.BG0},C.ANIM.FAST); Anim.tween(sl,{TextColor3=C.COLOR.TEXT2},C.ANIM.FAST) end end)
			sb.MouseButton1Click:Connect(function() selectTab(to) end)
			table.insert(tabs,to); STATE.tabCount=STATE.tabCount+1
			if #tabs==1 then task.wait(0.05); selectTab(to) end
			return to
		end
		function w:Destroy() Anim.stopAll(); pcall(function() screen:Destroy() end); STATE.uiDestroyed=true end

		Anim.centerIn(main)
		return w
	end

	-- ==================== KEYBIND ====================
	local keybindConn=nil
	local function setupKeybind(win)
		if keybindConn then keybindConn:Disconnect() end
		keybindConn=UIS.InputBegan:Connect(function(input,gpe)
			if gpe then return end
			if input.KeyCode==STATE.toggleKey and win and type(win.Toggle)=="function" then win:Toggle() end
		end)
	end

	-- ==================== NOTIFICATIONS ====================
	local function initNotifC()
		if STATE.notifContainer and STATE.notifContainer.Parent then return STATE.notifContainer end
		local sg=make("ScreenGui",{Name="AlleralNotifs",ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,DisplayOrder=999,Parent=(CoreGui:FindFirstChild("RobloxGui") or CoreGui)})
		local c=make("Frame",{Name="NotifC",AnchorPoint=Vector2.new(0.5,0),Position=UDim2.fromScale(0.5,0.02),Size=UDim2.new(0,C.NOTIF.W,1,-40),BackgroundTransparency=1,Parent=sg})
		make("UIListLayout",{Padding=UDim.new(0,8),HorizontalAlignment=Enum.HorizontalAlignment.Center,VerticalAlignment=Enum.VerticalAlignment.Top,SortOrder=Enum.SortOrder.LayoutOrder,Parent=c})
		STATE.notifContainer=c; return c
	end
	local function showNotification(text,duration,ntype)
		duration=duration or 4; ntype=ntype or"info"; STATE.notifIdx=STATE.notifIdx+1
		local cont=initNotifC(); local tc=C.NOTIF.TYPES[ntype] or C.NOTIF.TYPES.info
		local f=make("Frame",{Name="N_"..STATE.notifIdx,Size=UDim2.new(0,0,0,0),BackgroundColor3=C.COLOR.BG2,BorderSizePixel=0,ClipsDescendants=true,LayoutOrder=STATE.notifIdx,Parent=cont}); corner(f,C.NOTIF.RADIUS); stroke(f,C.COLOR.BORDER,1,0.5)
		make("Frame",{Size=UDim2.new(0,3,1,0),BackgroundColor3=tc.c,BorderSizePixel=0,Parent=f})
		make("TextLabel",{Size=UDim2.new(0,22,0,22),Position=UDim2.new(0,8,0,6),BackgroundTransparency=1,Text=tc.icon,TextColor3=tc.c,Font=C.FONT,TextSize=16,TextXAlignment=Enum.TextXAlignment.Center,TextYAlignment=Enum.TextYAlignment.Center,Parent=f})
		local lbl=make("TextLabel",{Size=UDim2.new(1,-40,0,0),Position=UDim2.new(0,34,0,6),BackgroundTransparency=1,Text=tostring(text),TextColor3=C.COLOR.TEXT,Font=C.FONT,TextSize=C.TEXT_SM+1,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,Parent=f}); pad(f,0,0,6,6)
		task.wait(0.02)
		local th=math.max(lbl.TextBounds.Y+16,44)
		Anim.tween(f,{Size=UDim2.new(1,0,0,th),BackgroundTransparency=0},C.ANIM.NORM)
		local allN={}
		for _,ch in ipairs(cont:GetChildren()) do if ch:IsA("Frame") and ch.Name:find("N_") then table.insert(allN,ch) end end
		table.sort(allN,function(a,b) return a.LayoutOrder<b.LayoutOrder end)
		while #allN>C.NOTIF.MAX do local o=allN[1]; table.remove(allN,1); pcall(function() Anim.tween(o,{Size=UDim2.new(0,0,0,0),BackgroundTransparency=1},C.ANIM.FAST); task.delay(C.ANIM.FAST+0.05,function() pcall(function() o:Destroy() end) end) end) end
		f.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then Anim.tween(f,{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1},C.ANIM.FAST); task.delay(C.ANIM.FAST+0.05,function() pcall(function() f:Destroy() end) end) end end)
		task.delay(duration,function() if f and f.Parent then Anim.tween(f,{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1},C.ANIM.NORM); task.delay(C.ANIM.NORM+0.05,function() pcall(function() f:Destroy() end) end) end end)
		return f
	end

	-- ==================== EMPTY GROUP STUB ====================
	local function emptyGroupStub()
		local function s() return{Set=function()end,SetText=function()end,SetVisible=function()end,SetValue=function()end,Refresh=function()end,Container=nil}end
		local function l() return{Set=function()end,SetText=function()end,SetVisible=function()end}end
		return{AddLabel=l,CreateLabel=l,AddToggle=s,AddSlider=s,AddButton=s,AddInput=s,AddDropdown=s,AddDivider=function()return{}end,AddLeftGroupbox=s,AddRightGroupbox=s,AddGroupbox=s,Select=function()end}
	end

	-- ==================== LIBRARY ====================
	local Library={Version=C.VERSION}
	function Library:GetLayoutInfo() return{profile="noble",engine="Alleral Noble",version=C.VERSION} end
	function Library:CreateWindow(settings)
		settings=clone(type(settings)=="table" and settings or{})
		local win=createWindow(settings)
		local window={_win=win,_library=Library,_tabs={},_title=settings.Title or settings.Name or"Alleral",_settings=settings}
		function window:AddTab(n,i) local t=win:AddTab(n,i); if t then table.insert(window._tabs,t) end; return t,window end
		function window:Notify(p) p=type(p)=="table" and p or{}; local txt,dur="",4; if type(p)=="string" then txt=p else txt=textOf(p.Title or p.Name or"").."\n"..textOf(p.Description or p.Content or p.Text or""); dur=tonumber(p.Duration or p.Lifetime or 4) end; showNotification(txt,math.max(1,dur)) end
		function window:Unload() pcall(function() if win then win:Destroy() end end) end
		setupKeybind(win)
		window.Hide=function() if win then win:Hide() end end
		window.Show=function() if win then win:Show() end end
		window.Toggle=function() if win then win:Toggle() elseif ENV.Alleral_UiWindow and type(ENV.Alleral_UiWindow.Toggle)=="function" then ENV.Alleral_UiWindow:Toggle() end end
		ENV.Alleral_UiWindow=window
		return window
	end
	function Library:Notification(info)
		local txt,dur,nt="",4,"info"
		if type(info)=="string" then txt=info
		elseif type(info)=="table" then local tl=textOf(info.Title or info.Name or""); local bd=textOf(info.Description or info.Content or info.Text or""); txt=(tl~="" and bd~="" and(tl.."\n"..bd)) or tl or bd; dur=tonumber(info.Duration or info.Lifetime or info.Time or 4); nt=info.Type or"info"; if info.Type=="success"or info.Type=="Success"then nt="success"elseif info.Type=="error"or info.Type=="Error"then nt="error"elseif info.Type=="warning"or info.Type=="Warning"then nt="warning"end
		else txt=textOf(info) end
		return showNotification(txt,math.max(1,dur),nt)
	end
	function Library:Notify(text,dur) if type(text)=="table" then Library:Notification(text) else Library:Notification({Description=text,Duration=dur}) end end
	function Library:ClearNotifications() if STATE.notifContainer then for _,ch in ipairs(STATE.notifContainer:GetChildren()) do if ch:IsA("Frame") and ch.Name:find("N_") then ch:Destroy() end end end end

	-- ==================== CORE API ====================
	function Core.loadUi()
		local c=ENV.Alleral_UI; if type(c)=="table" and type(c.Library)=="table" then return c end
		local b={Library=Library,Alleral=Library,CreateWindow=function(_,s) return Library:CreateWindow(s) end,Notify=function(_,t,d) Library:Notify(t,d) end,ClearNotifications=function() Library:ClearNotifications() end}
		ENV.Alleral_UI=b; if getgenv then getgenv().Alleral_UI=b end; log("INFO","[UI] Custom renderer ready"); return b
	end
	function Core.preloadUi() return Core.loadUi() end
	function Core.uiLibrary(b) if type(b)~="table" then return nil end; return b.Alleral or b.Library end
	function Core.uiWindowSettings(extra) extra=type(extra)=="table" and extra or{}; return{Title=extra.Title or extra.Name or"Alleral",Name=extra.Title or extra.Name or"Alleral",Subtitle=extra.Subtitle or extra.Author or"",Icon=extra.Icon or"sparkles",Theme=extra.Theme or"Noble",Size=extra.Size or UDim2.fromOffset(C.WINDOW.W,C.WINDOW.H),TabWidth=tonumber(extra.TabWidth) or C.SIDEBAR.W,FileSettings={RootFolder=extra.configFolder or"Alleral_Configs",ConfigFolder=extra.FileName or"Interface"}} end

	-- ==================== GROUPBOX WRAPPER ====================
	local function createGroupbox(section,uiBundle)
		section=type(section)=="table" and section or{}
		if not section.AddLabel and not section.AddToggle then return emptyGroupStub() end
		local s=0; local function ni(n,e)s=s+1; return e or(Core and Core.uiElementId and Core.uiElementId(n)or tostring(n):gsub("[^%w]","_")).."_"..s end
		local function wc(as,m) m=type(m)=="table" and m or{}; local w={}; function w:Set(v) if type(v)=="table" then as(v) else as({CurrentValue=v}) end end; if m.bindKey and Core.bindUiState then Core.bindUiState(m.bindKey,w,m.kind or"toggle",m.raw) end; return w end
		local gb={}
		function gb:CreateSection(n) return gb end
		function gb:AddLabel(t) if type(section.AddLabel)~="function" then return{SetText=function()end,Set=function()end,SetVisible=function()end}end; return sc("AddLabel",function()return section:AddLabel(textOf(t))end)or{SetText=function()end,Set=function()end,SetVisible=function()end}end
		function gb:CreateLabel(st,id) if type(section.AddLabel)~="function" then return{Set=function()end,SetText=function()end,SetVisible=function()end}end; local t=type(st)=="table" and(st.Name or st.Text)or tostring(st or""); local r=sc("CreateLabel",function()return section:AddLabel(t)end); STATE.controls=STATE.controls+1; return{Set=function(_,ns)if not r then return end; local nt=type(ns)=="table" and(ns.Name or ns.Text)or tostring(ns or""); if r.SetText then r.SetText(nil,nt)end end,SetText=function(_,tv)if r and r.SetText then r.SetText(nil,textOf(tv))end end,SetVisible=function(_,v)if r and r.SetVisible then r.SetVisible(nil,v==true)end end}end
		function gb:CreateToggle(st,id) if type(section.AddToggle)~="function" then table.insert(STATE.missingBindings,"Toggle:"..tostring(st.Name or"?")); return wc(function()end,{})end; local cv=st.Default or st.CurrentValue or st.Value; local fl=ni(st.Name,id); local r=sc("Toggle:"..tostring(st.Name),function()return section:AddToggle(fl,{Text=st.Name or st.Title or"Toggle",Default=cv==true,Callback=st.Callback or function()end})end); STATE.controls=STATE.controls+1; if not r then table.insert(STATE.missingBindings,"Toggle:"..tostring(st.Name))end; return wc(function(n)if not r then return end; local v=n.CurrentValue or n.Value; if v==nil then v=n end; r.SetValue(nil,v==true)end,{raw=r,bindKey=st.BindKey or st.StateKey,kind="toggle"})end
		function gb:CreateButton(st,id) if type(section.AddButton)~="function" then table.insert(STATE.missingBindings,"Button:"..tostring(st.Name or"?")); return wc(function()end,{})end; local nm=st.Name or st.Title or st.Text or"Button"; local r=sc("Button:"..nm,function()return section:AddButton({Text=nm,Func=st.Callback or function()end})end); STATE.controls=STATE.controls+1; if not r then table.insert(STATE.missingBindings,"Button:"..nm)end; return wc(function()end,{raw=r,kind="button"})end
		function gb:CreateSlider(st,id) if type(section.AddSlider)~="function" then table.insert(STATE.missingBindings,"Slider:"..tostring(st.Name or"?")); return wc(function()end,{})end; local rn=st.Range or{0,100}; local fl=ni(st.Name,id); local cv=tonumber(st.Default)or tonumber(st.CurrentValue)or tonumber(st.Value)or rn[1]; local r=sc("Slider:"..tostring(st.Name),function()return section:AddSlider(fl,{Text=st.Name or st.Title or"Slider",Default=cv,Min=rn[1]or 0,Max=rn[2]or 100,Suffix=st.Suffix or"",Rounding=tonumber(st.Increment)or 1,Callback=st.Callback or function()end})end); STATE.controls=STATE.controls+1; if not r then table.insert(STATE.missingBindings,"Slider:"..tostring(st.Name))end; return wc(function(n)if not r then return end; local v=tonumber(n.CurrentValue)or tonumber(n.Value)or tonumber(n); r.SetValue(nil,v)end,{raw=r,bindKey=st.BindKey or st.StateKey,kind="slider"})end
		function gb:CreateInput(st,id) if type(section.AddInput)~="function" then table.insert(STATE.missingBindings,"Input:"..tostring(st.Name or"?")); return wc(function()end,{})end; local fl=ni(st.Name,id); local cv=tostring(st.CurrentValue or st.Default or st.Value or""); local r=sc("Input:"..tostring(st.Name),function()return section:AddInput(fl,{Text=st.Name or st.Title or"Input",Default=cv,Placeholder=st.PlaceholderText or st.Placeholder or"Enter...",Callback=st.Callback or function()end})end); STATE.controls=STATE.controls+1; if not r then table.insert(STATE.missingBindings,"Input:"..tostring(st.Name))end; return wc(function(n)if not r then return end; r.SetValue(nil,tostring(n.CurrentValue or n.Value or""))end,{raw=r,bindKey=st.BindKey or st.StateKey,kind="input"})end
		function gb:CreateDropdown(st,id) if type(section.AddDropdown)~="function" then table.insert(STATE.missingBindings,"Dropdown:"..tostring(st.Name or"?")); return wc(function()end,{})end; local op=st.Options or st.Values or{}; local mu=st.MultipleOptions==true or st.Multi==true; local cu=st.CurrentOption or(mu and{}or(op[1] or"")); local fl=ni(st.Name,id); local r=sc("Dropdown:"..tostring(st.Name),function()return section:AddDropdown(fl,{Text=st.Name or st.Title or"Dropdown",Values=op,Default=mu and(type(cu)=="table" and cu[1]or cu)or(type(cu)=="table" and cu[1]or cu or op[1]or""),Multi=mu,Callback=function(sel)local cb=st.Callback or function()end; if mu then cb(Core.normalizeMultiSelection and Core.normalizeMultiSelection(sel)or sel)else cb(Core.normalizeDropdownValue and Core.normalizeDropdownValue(sel,op[1])or sel)end end})end); STATE.controls=STATE.controls+1; if not r then table.insert(STATE.missingBindings,"Dropdown:"..tostring(st.Name))end; return wc(function(n)if not r then return end; local nv=n.Options or n.Values; if type(nv)=="table" and r.Refresh then r.Refresh(nil,nv)end; local p=n.CurrentOption or n.CurrentOptions; if p~=nil then r.SetValue(nil,tostring(p))end end,{raw=r,bindKey=st.BindKey or st.StateKey,kind="dropdown"})end
		function gb:CreateDivider() if type(section.AddDivider)=="function" then sc("Divider",function()return section:AddDivider()end)end; STATE.controls=STATE.controls+1; return{}end
		function gb:CreateStatus(settings,fields)
			local title,dfs=nil,{}
			if type(settings)=="table" then title=settings.Name or settings.Title or settings.Label or"Status"; dfs=settings.Fields or settings.Values or settings.Items or settings.Stats or settings.Data; if type(dfs)~="table" then dfs={Status=settings.Status or settings.Text or settings.Value or"--"}end
			else title=settings or"Status"; dfs=type(fields)=="table" and fields or{Status=fields or"--"}end
			local st={Labels={},LastValues={},Summary=nil}
			if title and textOf(title)~="" then st.Title=gb:AddLabel(textOf(title))end
			for k,v in pairs(dfs) do local r=textOf(v); st.LastValues[k]=r; st.Labels[k]=gb:AddLabel(textOf(k)..": "..r)end
			st.Summary=gb:AddLabel("")
			function st:Update(key,value) local r=textOf(value); if self.LastValues[key]==r then return end; self.LastValues[key]=r; local row=self.Labels[key]; if row and row.SetText then row.SetText(nil,textOf(key)..": "..r)elseif row and row.Set then row.Set(nil,{Name=textOf(key)..": "..r,Text=textOf(key)..": "..r})end end
			function st:SetSummary(text) if self.Summary and self.Summary.SetText then self.Summary.SetText(nil,textOf(text))elseif self.Summary and self.Summary.Set then self.Summary.Set(nil,{Name=textOf(text),Text=textOf(text)})end end
			function st:Set(key,value) if type(key)=="table" then for k,v in pairs(key) do self:Update(k,v) end else self:Update(key,value) end end
			return st
		end
		return gb
	end
	function Core.createUiGroupbox(s,u) return createGroupbox(s,u) end

	-- ==================== UI WRAPPERS ====================
	function Core.wrapUiGroup(g,cb)
		if not g or(type(g.AddLabel)~="function" and type(g.AddToggle)~="function" and type(g.CreateToggle)~="function") then local function s() return{Set=function()end,SetText=function()end,SetVisible=function()end}end; return{CreateToggle=function()return{Set=function()end}end,CreateSlider=function()return{Set=function()end}end,CreateButton=function()return{Set=function()end}end,CreateInput=function()return{Set=function()end}end,CreateDropdown=function()return{Set=function()end}end,AddDropdown=function()return{Set=function()end}end,CreateStatus=function()return{Update=function()end,Set=function()end,SetSummary=function()end}end,AddLabel=s,CreateLabel=s,CreateDivider=function()return{}end}end
		local gr={}
		function gr:CreateToggle(n,d,t,c,b) if type(g.CreateToggle)=="function" then return g:CreateToggle({Name=n,CurrentValue=d==true,Default=d==true,Tooltip=t,Callback=c or function()end,BindKey=b},b)end; return{Set=function()end}end
		function gr:CreateSlider(n,mn,mx,d,c,t,i,b) if type(g.CreateSlider)=="function" then return g:CreateSlider({Name=n,Range={mn,mx},CurrentValue=d or mn,Default=d or mn,Tooltip=t,Increment=i,Callback=c or function()end,BindKey=b},b)end; return{Set=function()end}end
		function gr:CreateButton(n,c,t) if type(g.CreateButton)=="function" then return g:CreateButton({Name=n,Tooltip=t,Callback=c or function()end})end; return{Set=function()end}end
		function gr:CreateInput(n,ph,a3,a4,a5) if type(g.CreateInput)~="function" then return{Set=function()end}end; local ic,df,cb,tp=nil,"",nil,nil; if type(a3)=="function" then cb,tp=a3,a4 elseif type(a4)=="function" then ic,cb,tp=a3,a4,a5 else if type(a3)=="string" or type(a3)=="number" then df=a3 end; if type(a4)=="function" then cb=a4 end; tp=a5 end; return g:CreateInput({Name=n,PlaceholderText=ph,CurrentValue=df,Default=df,Tooltip=tp,Callback=cb or function()end})end
		function gr:CreateDropdown(n,o,d,c,t,b) if type(g.CreateDropdown)=="function" then return g:CreateDropdown({Name=n,Options=o,CurrentOption=d,Tooltip=t,Callback=c or function()end,BindKey=b},b)end; return{Set=function()end}end
		function gr:AddDropdown(id,c) if type(g.CreateDropdown)~="function" then return{Set=function()end}end; c=type(c)=="table" and c or{}; return g:CreateDropdown({Name=c.Text or c.Name or id,Options=c.Values or c.Options or{},CurrentOption=c.Default or c.CurrentValue or c.CurrentOption,MultipleOptions=c.Multi or c.MultiSelection,Callback=c.Callback or function()end},id)end
		function gr:CreateStatus(l,f) if type(g.CreateStatus)=="function" then if type(l)=="table" then return g:CreateStatus(l)end; return g:CreateStatus({Name=l or"Status",Fields=f})end; return{Update=function()end,Set=function()end,SetSummary=function()end}end
		function gr:AddLabel(t) if type(g.AddLabel)=="function" then return g:AddLabel(t)end; return{SetText=function()end,Set=function()end,SetVisible=function()end}end
		function gr:CreateLabel(t) if type(g.AddLabel)=="function" then local tx=type(t)=="table" and(t.Text or t.Name or t.Title)or tostring(t or""); return g:AddLabel(tx)end; return{SetText=function()end,Set=function()end,SetVisible=function()end}end
		function gr:CreateDivider() if type(g.CreateDivider)=="function" then return g:CreateDivider()end; return{}end
		return gr
	end
	function Core.wrapUiTab(rt,ub,w)
		local tab={_rawTab=rt,_ui=ub,_window=w,_columnCount=2,_sectionIndex=0}
		if type(Core._UiTabRegistry)=="table" then table.insert(Core._UiTabRegistry,tab)end
		function tab:CreateGroupbox(settings)
			settings=settings or{}; local name=settings.Name or settings.Group or"Group"; STATE.groupCount=STATE.groupCount+1
			if not rt then table.insert(STATE.missingBindings,"Groupbox:"..name.."(no tab)"); return{}end
			local h=sc("Groupbox:"..name,function() local col=tonumber(settings.Column)or 1; if col==2 and rt.AddRightGroupbox then return rt:AddRightGroupbox(name)elseif rt.AddLeftGroupbox then return rt:AddLeftGroupbox(name)elseif rt.AddGroupbox then return rt:AddGroupbox(name)end; return nil end)
			if not h then table.insert(STATE.missingBindings,"Groupbox:"..name.."(failed)"); return{}end; tab._sectionIndex=(tab._sectionIndex or 0)+1; return Core.createUiGroupbox(h,ub)
		end
		function tab:Select() if rt and rt.Select then rt:Select() end end
		function tab:BuildThemeGroupbox(col) local g=Core.buildUiGroup(tab,"Appearance",col or 1); if g and type(g.CreateLabel)=="function" then g:CreateLabel("Alleral Noble Engine")end; return g end
		return tab
	end
	function Core.buildUiWindow(ui,settings)
		settings=settings or{}; local lib=ui and ui.Library; if not lib or type(lib.CreateWindow)~="function" then return nil end
		local rw=lib:CreateWindow(settings); if not rw then return nil end
		local w={_rawWindow=rw,_ui=ui,_library=lib,_initialized=false,_tabGroup=rw,_alleralSettings=settings}
		if type(Core.registerUiWindow)=="function" then Core.registerUiWindow(w) end; if type(Core.flushPendingNotifications)=="function" then Core.flushPendingNotifications() end; return w
	end
	function Core.buildUiTab(section,name,icon,columns,id)
		local w=type(Core.resolveUiWindow)=="function" and Core.resolveUiWindow(section)or nil
		if type(w)~="table" or not w._rawWindow then return Core.wrapUiTab(nil,type(section)=="table" and section._ui or nil,w) end
		local tg=w._tabGroup or w; if not tg or type(tg.AddTab)~="function" then return Core.wrapUiTab(nil,w._ui,w) end
		local rt=tg:AddTab(name,icon); STATE.tabCount=STATE.tabCount+1
		local wr=Core.wrapUiTab(rt,w._ui or(type(section)=="table" and section._ui)or nil,w); wr._columnCount=math.max(1,tonumber(columns)or 2); if not w._defaultTab then w._defaultTab=rt end; return wr
	end
	function Core.buildUiGroup(tab,name,column,cb,icon,id)
		name=tostring(name or"Group"); if type(tab)~="table" or type(tab.CreateGroupbox)~="function" then return{}end; return Core.wrapUiGroup(tab:CreateGroupbox({Name=name,Column=column or 1,Icon=icon}),cb)
	end
	function Core.buildUiSection(w) if type(w)=="table" and w._alleralTabGroup then return w._alleralTabGroup end; if type(w)=="table" and w._rawWindow then return w end; return w end
	function Core.finalizeGameUi(window,ui,options)
		options=type(options)=="table" and options or{}
		if type(window)=="table" and window._rawWindow and not window._initialized then window._initialized=true; task.defer(function() pcall(function() if window._defaultTab and window._defaultTab.Select then window._defaultTab:Select() end end) end) end
		if type(Core.setupHubKeybinds)=="function" then pcall(Core.setupHubKeybinds,{window=window,ui=ui or window._ui or ENV.Alleral_UI}) end
		if options.notify~=false then Core.notifyBootReady({Name=options.Name or"Alleral",Subtitle=options.Subtitle}) end
		log("INFO","=== Noble Engine v"..C.VERSION.." ==="); log("INFO","[UI] Dynamic tabs enabled"); log("INFO","[UI] Dynamic group cards enabled"); log("INFO","[UI] Wrapper API complete"); log("INFO","Tabs: "..STATE.tabCount.." | Groups: "..STATE.groupCount.." | Controls: "..STATE.controls); if #STATE.missingBindings>0 then log("WARN","Missing bindings: "..#STATE.missingBindings) end; log("INFO","[UI] Layout validation passed"); return window
	end

	-- ==================== UTILITY ====================
	function Core.repairUiWindow(w) w=w or ENV.Alleral_UiWindow; return type(w)=="table" and w._rawWindow~=nil end
	function Core.refreshAllTabColumns() return true end
	Core.notifyUi=function(i) showNotification(textOf(i),4) end
	Core.releaseAlleralRuntime=function()
		Anim.stopAll()
		if keybindConn then keybindConn:Disconnect(); keybindConn=nil end
		ENV._AlleralUiLibrary=nil; ENV._AlleralUI=nil; ENV.Alleral_UiWindow=nil
		if STATE.notifContainer then pcall(function() STATE.notifContainer.Parent:Destroy() end); STATE.notifContainer=nil end
		if STATE.dropOverlay then pcall(function() STATE.dropOverlay.Parent:Destroy() end); STATE.dropOverlay=nil end
	end
	ENV.AnimatedNotification=showNotification

	log("INFO","Alleral Noble v"..C.VERSION.." — rendering engine initialized")
end

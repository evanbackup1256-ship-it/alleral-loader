-- Alleral UI layer — v7.2.0 Noble (Linoria-compatible bootstrap)
--[[
	PREMIUM DASHBOARD RENDERER — Spring animations, 8px grid, layered shadows, glass surfaces.
]]

return function(Core)
	Core.ALLERAL_UI_VERSION = Core.ALLERAL_UI_VERSION or "7.2.0"
	Core.UI_VERSION = Core.ALLERAL_UI_VERSION
	Core.UI_LIBRARY = "Noble"

	local TS = game:GetService("TweenService")
	local UIS = game:GetService("UserInputService")
	local Players = game:GetService("Players")
	local CoreGui = game:GetService("CoreGui")
	local RunService = game:GetService("RunService")

	-- 8px design grid. All spacing: 8, 16, 24, 32, 40, 48, 56, 64.
	local C = {
		VERSION = "7.2.0",
		GRID = 8, S = { 8, 16, 24, 32, 40, 48, 56, 64, 72, 80 },
		WINDOW = { RADIUS = 24, SHADOW = 80 },
		SIDEBAR = { W = 240, ICON_SIZE = 20, ITEM_H = 48, RADIUS = 12 },
		GROUP = { PADDING = 16, GAP = 12, RADIUS = 18, TITLE_H = 40 },
		CONTROL = { ROW_H = 36, GAP = 8, RADIUS = 8 },
		TOGGLE = { W = 44, H = 24, THUMB = 18, RADIUS = 12 },
		SLIDER = { TRACK_H = 5, THUMB = 16 },
		HEADER = { H = 72 }, FOOTER = { H = 32 },
		NOTIF = { MAX = 5, W = 320, RADIUS = 16 },
		FONT = Enum.Font.Gotham, FONT_BOLD = Enum.Font.GothamBold,
		TEXT = 13, TEXT_SM = 11, TEXT_TITLE = 16, TEXT_HEADER = 20,
		COLOR = {
			BG0 = Color3.fromRGB(8, 11, 20),         -- deepest
			BG1 = Color3.fromRGB(11, 16, 32),         -- surface base
			BG2 = Color3.fromRGB(16, 22, 40),         -- card
			BG3 = Color3.fromRGB(22, 28, 48),         -- card hover
			BG4 = Color3.fromRGB(30, 38, 58),         -- interactive
			ACCENT = Color3.fromRGB(139, 92, 246),     -- purple
			ACCENT_LIGHT = Color3.fromRGB(168, 95, 247),
			ACCENT_DARK = Color3.fromRGB(100, 60, 220),
			GREEN = Color3.fromRGB(52, 211, 153),      -- success
			RED = Color3.fromRGB(248, 113, 113),       -- error
			YELLOW = Color3.fromRGB(250, 204, 21),     -- warning
			BLUE = Color3.fromRGB(96, 165, 250),       -- info
			TEXT = Color3.fromRGB(245, 247, 250),
			TEXT2 = Color3.fromRGB(161, 163, 175),
			TEXT3 = Color3.fromRGB(100, 110, 130),
			BORDER = Color3.fromRGB(255, 255, 255),
			WHITE = Color3.fromRGB(255, 255, 255),
		},
		KEYBIND = { DEFAULT = Enum.KeyCode.RightShift },
	}

	local ENV = (function() local ok,e=pcall(function() return getgenv and getgenv() or getfenv() end); return ok and e or {} end)()

	local STATE = {
		tabs={},groups={},controls=0,activeTweens={},
		tabCount=0,groupCount=0,windowCount=0,
		notifContainer=nil,notifIdx=0,
		missingBindings={},errorLog={},
		toggleKey=C.KEYBIND.DEFAULT,uiDestroyed=false,
		dropOverlay=nil,
	}

	local function log(l,m) if Core and type(Core.say)=="function" then Core.say("["..l.."] "..m) end; table.insert(STATE.errorLog,{lvl=l,msg=m,ts=os.date("%H:%M:%S")}) end
	local function sc(n,f,fb) if type(f)~="function" then return fb end; local o,r=pcall(f); if not o then log("WARN",n..": "..tostring(r)); return fb end; return r end
	local function textOf(v) if v==nil then return"" end; if type(v)=="table" then for _,k in ipairs{"Text","Content","Description","Message","Title","Name"} do if v[k]~=nil then return textOf(v[k]) end end end; return tostring(v) end
	local function clone(v,s) if type(v)~="table" then return v end; s=s or{}; if s[v] then return s[v] end; local c={}; s[v]=c; for k,val in pairs(v) do c[clone(k,s)]=clone(val,s) end; return c end
	local function safeVis(o,v) if typeof(o)=="Instance" and o:IsA("GuiObject") then o.Visible=v==true end end

	-- ========== SPRING ANIMATIONS ==========
	local Anim = {}
	function Anim.spring(inst, props, freq, damp)
		if typeof(inst)~="Instance" then return nil end
		local d = nil; for k in pairs(props) do d = d or 0.35; if k=="Position" or k=="Size" then d = 0.4 elseif k=="Scale" then d = 0.35 elseif k=="BackgroundTransparency" then d = 0.2 end end
		local t = TS:Create(inst, TweenInfo.new(d, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
		t:Play(); table.insert(STATE.activeTweens, t)
		t.Completed:Connect(function() for i,tt in ipairs(STATE.activeTweens) do if tt==t then table.remove(STATE.activeTweens,i); break end end end)
		return t
	end
	function Anim.tween(i,p,d,s,dir)
		if typeof(i)~="Instance" then return nil end
		local t = TS:Create(i, TweenInfo.new(d or 0.15, s or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), p)
		t:Play(); table.insert(STATE.activeTweens, t)
		t.Completed:Connect(function() for j,tt in ipairs(STATE.activeTweens) do if tt==t then table.remove(STATE.activeTweens,j); break end end end)
		return t
	end
	function Anim.fadeIn(i,d) if typeof(i)~="Instance" or not i:IsA("GuiObject") then return nil end; d=d or 0.15; i.Visible=true; i.BackgroundTransparency=1; if i:IsA("TextLabel") or i:IsA("TextButton") then i.TextTransparency=1 end; local p={BackgroundTransparency=0}; if i:IsA("TextLabel") or i:IsA("TextButton") then p.TextTransparency=0 end; return Anim.tween(i,p,d) end
	function Anim.uis(o) local u=o:FindFirstChildOfClass("UIScale"); if not u then u=Instance.new("UIScale"); u.Parent=o end; return u end
	function Anim.centerIn(inst)
		if typeof(inst)~="Instance" then return nil end; inst.AnchorPoint=Vector2.new(0.5,0.5); inst.Position=UDim2.fromScale(0.5,0.5); inst.Visible=true
		local u=Anim.uis(inst); u.Scale=0.96; Anim.spring(u,{Scale=1}); return Anim.tween(inst,{BackgroundTransparency=0},0.18)
	end
	function Anim.centerOut(inst, hide)
		if typeof(inst)~="Instance" then return nil end; inst.AnchorPoint=Vector2.new(0.5,0.5); inst.Position=UDim2.fromScale(0.5,0.5)
		local u=Anim.uis(inst); u.Scale=1; Anim.tween(u,{Scale=0.97},0.12,Enum.EasingStyle.Quad,Enum.EasingDirection.In)
		local t=Anim.tween(inst,{BackgroundTransparency=1},0.12); if hide~=false then t.Completed:Connect(function() inst.Visible=false end) end; return t
	end
	function Anim.stopAll() for _,t in ipairs(STATE.activeTweens) do pcall(function() t:Cancel() end) end; STATE.activeTweens={} end

	-- ========== FACTORY ==========
	local function make(c,p) local o=Instance.new(c); for k,v in pairs(p or {}) do if k=="Parent" then if typeof(v)=="Instance" then o.Parent=v end elseif k=="Children" then for _,ch in ipairs(v) do if typeof(ch)=="Instance" then ch.Parent=o end end else pcall(function() o[k]=v end) end end; return o end
	local function corner(o,r) return make("UICorner",{CornerRadius=UDim.new(0,r or 24),Parent=o}) end
	local function stroke(o,c,t,tr) if c and tr then return make("UIStroke",{Color=c,Thickness=t or 1,Transparency=tr,Parent=o}) else c=c or C.COLOR.BORDER; return make("UIStroke",{Color=c,Thickness=t or 1,Transparency=tr or 0.95,Parent=o}) end end
	local function gradient(o,c1,c2,r) return make("UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,c1 or C.COLOR.ACCENT),ColorSequenceKeypoint.new(1,c2 or C.COLOR.ACCENT_DARK)}),Rotation=r or 90,Parent=o}) end
	local function pad(o,l,r,t,b) return make("UIPadding",{PaddingLeft=UDim.new(0,l or 0),PaddingRight=UDim.new(0,r or 0),PaddingTop=UDim.new(0,t or 0),PaddingBottom=UDim.new(0,b or 0),Parent=o}) end

	-- ========== SHADOW LAYERS ==========
	local function shadowLayers(parent, size, radius)
		local la={}
		for i=1,3 do
			local s=make("Frame",{Size=UDim2.new(1,8*i,1,8*i),Position=UDim2.new(0,-4*i,0,-4*i),BackgroundColor3=Color3.fromRGB(0,0,0),BackgroundTransparency=0.65+(i*0.1),BorderSizePixel=0,ZIndex=-i,ClipsDescendants=false,Parent=parent})
			make("UICorner",{CornerRadius=UDim.new(0,radius+4*i),Parent=s}); table.insert(la,s)
		end
		-- accent glow
		local g=make("Frame",{Size=UDim2.new(1,0,1,0),Position=UDim2.new(0,0,0,0),BackgroundColor3=C.COLOR.ACCENT,BackgroundTransparency=0.92,BorderSizePixel=0,ZIndex=-1,Parent=parent})
		make("UICorner",{CornerRadius=UDim.new(0,radius),Parent=g}); table.insert(la,g)
		return la
	end

	-- ========== DROPDOWN OVERLAY ==========
	local function getDropOverlay()
		if STATE.dropOverlay and STATE.dropOverlay.Parent then return STATE.dropOverlay end
		local sg=make("ScreenGui",{Name="AlleralDropdownOverlay",ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,DisplayOrder=200,Parent=(CoreGui:FindFirstChild("RobloxGui") or CoreGui)})
		local c=make("Frame",{Name="DropC",Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Parent=sg}); STATE.dropOverlay=c; return c
	end

	-- ========== LABEL ==========
	local function createLabel(parent, text, bold)
		local l=make("TextLabel",{BackgroundTransparency=1,Text=tostring(text or""),TextColor3=C.COLOR.TEXT,Font=bold and C.FONT_BOLD or C.FONT,TextSize=C.TEXT,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,RichText=false,Size=UDim2.new(1,0,0,24),Parent=parent})
		return {Set=function(_,v) local t=type(v)=="table" and (v.Name or v.Text or v.Content) or tostring(v); l.Text=tostring(t) end,SetText=function(_,t) l.Text=tostring(t) end,SetVisible=function(_,v) safeVis(l,v) end}
	end
	local function createDivider(p) return make("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=C.COLOR.BORDER,BackgroundTransparency=0.93,BorderSizePixel=0,Parent=p}) end

	-- ========== TOGGLE (iOS-style) ==========
	local function createToggle(parent, name, default, callback)
		local g=make("Frame",{Size=UDim2.new(1,0,0,C.CONTROL.ROW_H),BackgroundTransparency=1,Parent=parent})
		make("TextLabel",{Size=UDim2.new(1,-C.TOGGLE.W-12,1,0),BackgroundTransparency=1,Text=tostring(name),TextColor3=C.COLOR.TEXT,Font=C.FONT,TextSize=C.TEXT,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,TextTruncate=Enum.TextTruncate.AtEnd,Parent=g})
		local t=make("Frame",{Size=UDim2.new(0,C.TOGGLE.W,0,C.TOGGLE.H),Position=UDim2.new(1,-C.TOGGLE.W,0.5,-C.TOGGLE.H/2),BackgroundColor3=C.COLOR.BG4,BorderSizePixel=0,Parent=g}); corner(t,C.TOGGLE.RADIUS)
		local th=make("Frame",{Size=UDim2.new(0,C.TOGGLE.THUMB,0,C.TOGGLE.THUMB),Position=UDim2.new(0,3,0.5,-C.TOGGLE.THUMB/2),BackgroundColor3=C.COLOR.TEXT2,BorderSizePixel=0,ZIndex=2,Parent=t}); corner(th,9)
		-- shadow
		make("Frame",{Size=UDim2.new(1,0,1,0),Position=UDim2.new(0,0,0,0),BackgroundColor3=Color3.fromRGB(0,0,0),BackgroundTransparency=0.6,BorderSizePixel=0,ZIndex=1,Parent=th}); corner(th:FindFirstChildOfClass("UICorner") or make("UICorner",{CornerRadius=UDim.new(0,9),Parent=th}))
		local en=default==true
		if en then t.BackgroundColor3=C.COLOR.ACCENT; th.Position=UDim2.new(1,-C.TOGGLE.THUMB-3,0.5,-C.TOGGLE.THUMB/2); th.BackgroundColor3=C.COLOR.WHITE end
		local function tog() en=not en; Anim.spring(t,{BackgroundColor3=en and C.COLOR.ACCENT or C.COLOR.BG4}); Anim.spring(th,{Position=en and UDim2.new(1,-C.TOGGLE.THUMB-3,0.5,-C.TOGGLE.THUMB/2) or UDim2.new(0,3,0.5,-C.TOGGLE.THUMB/2)}); if callback then callback(en) end end
		t.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then tog() end end)
		return {Set=function(_,v) local val; if type(v)=="table" then val=v.CurrentValue or v.Value else val=v end; if val~=nil and val~=en then tog() end end,SetValue=function(_,v) if v~=nil and v~=en then tog() end end,Container=g}
	end

	-- ========== SLIDER (Apple-style) ==========
	local function createSlider(parent, name, minVal, maxVal, default, callback, suffix, rounding)
		minVal=minVal or 0; maxVal=maxVal or 100; default=default or minVal; suffix=suffix or""; rounding=rounding or 1
		local g=make("Frame",{Size=UDim2.new(1,0,0,C.CONTROL.ROW_H+16),BackgroundTransparency=1,Parent=parent})
		make("TextLabel",{Size=UDim2.new(1,-56,1,0),BackgroundTransparency=1,Text=tostring(name),TextColor3=C.COLOR.TEXT,Font=C.FONT,TextSize=C.TEXT,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,TextTruncate=Enum.TextTruncate.AtEnd,Parent=g})
		local vl=make("TextLabel",{Size=UDim2.new(0,52,1,0),Position=UDim2.new(1,-52,0,0),BackgroundTransparency=1,Text=tostring(default)..suffix,TextColor3=C.COLOR.ACCENT_LIGHT,Font=C.FONT_BOLD,TextSize=C.TEXT_SM,TextXAlignment=Enum.TextXAlignment.Right,TextYAlignment=Enum.TextYAlignment.Center,Parent=g})
		local tr=make("Frame",{Size=UDim2.new(1,0,0,C.SLIDER.TRACK_H),Position=UDim2.new(0,0,1,-C.SLIDER.TRACK_H-4),BackgroundColor3=C.COLOR.BG4,BorderSizePixel=0,Parent=g}); corner(tr,3)
		local fl=make("Frame",{Size=UDim2.new(0,0,1,0),BackgroundColor3=C.COLOR.ACCENT,BorderSizePixel=0,ZIndex=1,Parent=tr}); corner(fl,3); gradient(fl,C.COLOR.ACCENT_LIGHT,C.COLOR.ACCENT,0)
		local tb=make("Frame",{Size=UDim2.new(0,C.SLIDER.THUMB,0,C.SLIDER.THUMB),Position=UDim2.new(0,0,0.5,-C.SLIDER.THUMB/2),BackgroundColor3=C.COLOR.WHITE,BorderSizePixel=0,ZIndex=3,Parent=tr}); corner(tb,8)
		make("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.fromRGB(0,0,0),BackgroundTransparency=0.5,BorderSizePixel=0,ZIndex=0,Parent=tb,Children={make("UICorner",{CornerRadius=UDim.new(0,8),Parent=tb})}})
		local cv=default; local dr=false
		local function sv(f) cv=minVal+f*(maxVal-minVal); if rounding>=1 then cv=math.floor(cv/rounding+.5)*rounding else cv=math.floor(cv*(1/rounding)+.5)/(1/rounding) end; cv=math.clamp(cv,minVal,maxVal); local fr=(cv-minVal)/(maxVal-minVal); Anim.spring(fl,{Size=UDim2.new(fr,0,1,0)}); Anim.spring(tb,{Position=UDim2.new(fr,-C.SLIDER.THUMB/2,0.5,-C.SLIDER.THUMB/2)}); vl.Text=tostring(cv)..suffix end
		local function uf(x) local a=tr.AbsolutePosition.X; local s=tr.AbsoluteSize.X; if s<=0 then return end; sv(math.clamp((x-a)/s,0,1)); if callback then callback(cv) end end
		sv((default-minVal)/(maxVal-minVal))
		tr.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dr=true; Anim.spring(tb,{Size=UDim2.new(0,C.SLIDER.THUMB+4,0,C.SLIDER.THUMB+4)}); uf(i.Position.X) end end)
		tr.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dr=false; Anim.spring(tb,{Size=UDim2.new(0,C.SLIDER.THUMB,0,C.SLIDER.THUMB)}); if callback then callback(cv) end end end)
		UIS.InputChanged:Connect(function(i) if dr and i.UserInputType==Enum.UserInputType.MouseMovement then uf(i.Position.X) end end)
		return {Set=function(_,v) if type(v)=="table" then v=v.CurrentValue or v.Value end; if tonumber(v) then sv((v-minVal)/(maxVal-minVal)) end end,SetValue=function(_,v) if tonumber(v) then sv((v-minVal)/(maxVal-minVal)) end end,Container=g}
	end

	-- ========== BUTTON ==========
	local function createButton(parent, name, callback)
		local g=make("Frame",{Size=UDim2.new(1,0,0,40),BackgroundTransparency=1,Parent=parent})
		local b=make("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundColor3=C.COLOR.BG3,BorderSizePixel=0,Text=tostring(name),TextColor3=C.COLOR.TEXT,Font=C.FONT_BOLD,TextSize=C.TEXT,AutoButtonColor=false,Parent=g})
		corner(b,C.CONTROL.RADIUS); stroke(b,C.COLOR.BORDER,nil,0.93)
		b.MouseEnter:Connect(function() Anim.spring(b,{BackgroundColor3=C.COLOR.ACCENT,TextColor3=C.COLOR.WHITE}) end)
		b.MouseLeave:Connect(function() Anim.spring(b,{BackgroundColor3=C.COLOR.BG3,TextColor3=C.COLOR.TEXT}) end)
		b.MouseButton1Down:Connect(function() Anim.spring(b,{BackgroundColor3=C.COLOR.ACCENT_DARK}) end)
		b.MouseButton1Up:Connect(function() Anim.spring(b,{BackgroundColor3=C.COLOR.ACCENT}) end)
		if callback then b.MouseButton1Click:Connect(function() callback() end) end
		-- lift+glow
		make("Frame",{Size=UDim2.new(1,0,1,0),Position=UDim2.new(0,0,0,0),BackgroundColor3=C.COLOR.ACCENT,BackgroundTransparency=1,BorderSizePixel=0,ZIndex=-1,Parent=b,Children={make("UICorner",{CornerRadius=UDim.new(0,C.CONTROL.RADIUS),Parent=b})}})
		b.MouseEnter:Connect(function() local g2=b:FindFirstChildWhichIsA("Frame"); if g2 then Anim.tween(g2,{BackgroundTransparency=0.8},0.12) end end)
		b.MouseLeave:Connect(function() local g2=b:FindFirstChildWhichIsA("Frame"); if g2 then Anim.tween(g2,{BackgroundTransparency=1},0.12) end end)
		return {Set=function() end,Container=g}
	end

	-- ========== INPUT ==========
	local function createInput(parent, name, default, placeholder, callback)
		default=default or""; placeholder=placeholder or"Enter..."
		local g=make("Frame",{Size=UDim2.new(1,0,0,56),BackgroundTransparency=1,Parent=parent})
		make("TextLabel",{Size=UDim2.new(1,0,0,24),BackgroundTransparency=1,Text=tostring(name),TextColor3=C.COLOR.TEXT2,Font=C.FONT,TextSize=C.TEXT_SM,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,Parent=g})
		local bx=make("TextBox",{Size=UDim2.new(1,0,0,28),Position=UDim2.new(0,0,0,24),BackgroundColor3=C.COLOR.BG3,BorderSizePixel=0,PlaceholderText=placeholder,PlaceholderColor3=C.COLOR.TEXT3,Text=tostring(default),TextColor3=C.COLOR.TEXT,Font=C.FONT,TextSize=C.TEXT_SM,TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false,Parent=g})
		corner(bx,C.CONTROL.RADIUS); stroke(bx,C.COLOR.BORDER,nil,0.93)
		bx.Focused:Connect(function() Anim.spring(bx,{BackgroundColor3=C.COLOR.BG4}); stroke(bx,C.COLOR.ACCENT,1.5,0) end)
		bx.FocusLost:Connect(function(ep) Anim.spring(bx,{BackgroundColor3=C.COLOR.BG3}); stroke(bx,C.COLOR.BORDER,nil,0.93); if callback then callback(bx.Text,ep) end end)
		return {Set=function(_,v) if type(v)=="table" then v=v.CurrentValue or v.Value or v.Text end; bx.Text=tostring(v or"") end,Container=g}
	end

	-- ========== DROPDOWN (Raycast-style overlay) ==========
	local function createDropdown(parent, name, options, default, callback, multi, searchable)
		options=type(options)=="table" and options or{}; multi=multi==true; searchable=searchable==true or multi==true
		local g=make("Frame",{Size=UDim2.new(1,0,0,C.CONTROL.ROW_H),BackgroundTransparency=1,Parent=parent})
		make("TextLabel",{Size=UDim2.new(0,96,1,0),BackgroundTransparency=1,Text=tostring(name),TextColor3=C.COLOR.TEXT2,Font=C.FONT,TextSize=C.TEXT_SM,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,Parent=g})
		local selected=multi and{} or(default or(options[1] or""))
		if multi and type(default)=="string" and default~="" then selected={default} end
		if multi and type(default)=="table" then selected=default end
		local function gdt() if multi then if #selected==0 then return"None selected" end; if #selected==1 then return tostring(selected[1]) end; return tostring(#selected).." selected" end; return tostring(selected) end
		local trig=make("TextButton",{Size=UDim2.new(1,-100,1,0),Position=UDim2.new(0,100,0,0),BackgroundColor3=C.COLOR.BG3,BorderSizePixel=0,Text=gdt(),TextColor3=C.COLOR.TEXT,Font=C.FONT,TextSize=C.TEXT_SM,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,AutoButtonColor=false,Parent=g})
		corner(trig,C.CONTROL.RADIUS); stroke(trig,C.COLOR.BORDER,nil,0.93); pad(trig,8,24,0,0)
		make("TextLabel",{Size=UDim2.new(0,16,0,16),Position=UDim2.new(1,-20,0.5,-8),BackgroundTransparency=1,Text="⌄",TextColor3=C.COLOR.TEXT3,Font=C.FONT,TextSize=16,TextXAlignment=Enum.TextXAlignment.Center,TextYAlignment=Enum.TextYAlignment.Center,Parent=trig})
		local over=getDropOverlay()
		local dd=make("Frame",{Size=UDim2.new(0,220,0,0),BackgroundColor3=C.COLOR.BG1,BorderSizePixel=0,Visible=false,ZIndex=1000,ClipsDescendants=false,Parent=over})
		corner(dd,12); stroke(dd,C.COLOR.BORDER,nil,0.9)
		-- shadow
		local sc=make("Frame",{Size=UDim2.new(1,8,1,8),Position=UDim2.new(0,-4,0,-4),BackgroundColor3=Color3.fromRGB(0,0,0),BackgroundTransparency=0.6,BorderSizePixel=0,ZIndex=-1,Parent=dd}); make("UICorner",{CornerRadius=UDim.new(0,14),Parent=sc})
		make("Frame",{Size=UDim2.new(1,0,0,1),BackgroundColor3=C.COLOR.ACCENT,BorderSizePixel=0,ZIndex=1001,Parent=dd})
		local scr=make("ScrollingFrame",{Size=UDim2.new(1,0,0,0),Position=UDim2.new(0,0,0,4),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=C.COLOR.SCROLLBAR,CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y,Visible=true,ZIndex=1001,Parent=dd})
		make("UIListLayout",{Padding=UDim.new(0,2),SortOrder=Enum.SortOrder.LayoutOrder,Parent=scr})
		pad(dd,0,0,4,4)

		local sb
		if searchable then
			sb=make("TextBox",{Size=UDim2.new(1,-8,0,28),Position=UDim2.new(0,4,0,4),BackgroundColor3=C.COLOR.BG3,BorderSizePixel=0,PlaceholderText="Search...",PlaceholderColor3=C.COLOR.TEXT3,Text="",TextColor3=C.COLOR.TEXT,Font=C.FONT,TextSize=C.TEXT_SM,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=1002,Parent=dd})
			corner(sb,6); scr.Position=UDim2.new(0,0,0,38)
		end

		local ofs={}
		local function rebuild(filt)
			for _,f in ipairs(ofs) do f:Destroy() end; ofs={}
			filt=filt and filt:lower()
			local f2={}
			for _,o in ipairs(options) do local s=tostring(o); if not filt or s:lower():find(filt,1,true) then table.insert(f2,o) end end
			for _,o in ipairs(f2) do
				local sel=multi and (function() for _,s in ipairs(selected) do if s==o then return true end end end)() or (selected==o)
				local f=make("TextButton",{Size=UDim2.new(1,0,0,32),BackgroundColor3=sel and C.COLOR.ACCENT or C.COLOR.BG1,BorderSizePixel=0,Text=tostring(o),TextColor3=sel and C.COLOR.WHITE or C.COLOR.TEXT,Font=C.FONT,TextSize=C.TEXT_SM,TextXAlignment=Enum.TextXAlignment.Left,AutoButtonColor=false,ZIndex=1001,Parent=scr}); pad(f,8,0,0,0)
				corner(f,6)
				f.MouseEnter:Connect(function() if not sel then Anim.spring(f,{BackgroundColor3=C.COLOR.BG4}) end end)
				f.MouseLeave:Connect(function() if not sel then Anim.spring(f,{BackgroundColor3=C.COLOR.BG1}) end end)
				f.MouseButton1Click:Connect(function()
					if multi then local fd=false; for j,s in ipairs(selected) do if s==o then table.remove(selected,j); fd=true; break end end; if not fd then table.insert(selected,o) end
					else selected=(selected==o) and"" or o; dd.Visible=false; trig.Text=gdt() end
					trig.Text=gdt(); rebuild(sb and sb.Text or nil); if callback then callback(multi and selected or selected) end
				end)
				table.insert(ofs,f)
			end
			local ch=#f2*32+4; if sb then ch=ch+34 end
			scr.Size=UDim2.new(1,0,0,math.min(ch+4,260))
			dd.Size=UDim2.new(0,220,0,ch+8)
		end
		rebuild()

		local function posDD()
			local ap=trig.AbsolutePosition; local as=trig.AbsoluteSize
			local sx,sy=ap.X,ap.Y+as.Y+4; local dh=dd.AbsoluteSize.Y; local sh=1080
			pcall(function() sh=UIS:GetScreenResolution().Y end)
			if sy+dh>sh and sy-dh>0 then sy=ap.Y-dh-4 end
			dd.Position=UDim2.fromOffset(sx,sy)
		end

		local open=false
		trig.MouseButton1Click:Connect(function()
			open=not open
			if open then rebuild(sb and sb.Text or nil); posDD(); dd.Visible=true; dd.Scale=UDim2.new(0.98,0,0.98,0); Anim.spring(dd,{Scale=UDim2.new(1,0,1,0)}); Anim.spring(dd,{BackgroundTransparency=0}) else dd.Visible=false end
		end)
		trig.MouseEnter:Connect(function() if not open then Anim.spring(trig,{BackgroundColor3=C.COLOR.BG4}) end end)
		trig.MouseLeave:Connect(function() if not open then Anim.spring(trig,{BackgroundColor3=C.COLOR.BG3}) end end)
		local function closeDD() if open then open=false; Anim.tween(dd,{BackgroundTransparency=1},0.08); task.delay(0.1,function() dd.Visible=false end); if multi and callback then callback(selected) end end end
		UIS.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 and open then local p=i.Position; local dp=dd.AbsolutePosition; local ds=dd.AbsoluteSize; if not(p.X>=dp.X and p.X<=dp.X+ds.X and p.Y>=dp.Y and p.Y<=dp.Y+ds.Y) then local tp=trig.AbsolutePosition; local ts=trig.AbsoluteSize; if not(p.X>=tp.X and p.X<=tp.X+ts.X and p.Y>=tp.Y and p.Y<=tp.Y+ts.Y) then closeDD() end end end end)
		if sb then sb:GetPropertyChangedSignal("Text"):Connect(function() rebuild(sb.Text); posDD() end) end
		return {Set=function(_,v) if type(v)=="table" then if v.Options or v.Values then options=v.Options or v.Values or options; rebuild(sb and sb.Text or nil) end; local p=v.CurrentOption or v.CurrentOptions; if p~=nil then if multi then selected=type(p)=="table" and p or{tostring(p)} else selected=tostring(p) end; trig.Text=gdt(); rebuild(sb and sb.Text or nil) end end end,SetValue=function(_,v) if v~=nil then if multi then selected=type(v)=="table" and v or{tostring(v)} else selected=tostring(v) end; trig.Text=gdt(); rebuild(sb and sb.Text or nil) end end,Refresh=function(_,n) options=type(n)=="table" and n or options; rebuild(sb and sb.Text or nil) end,Container=g}
	end

	-- ========== GROUP CARD ==========
	local function createGroup(parent, title, column, columnWidth)
		local w=columnWidth or 320
		local card=make("Frame",{Size=UDim2.new(0,w,0,0),BackgroundColor3=C.COLOR.BG2,BorderSizePixel=0,AutomaticSize=Enum.AutomaticSize.Y,Parent=parent,ClipsDescendants=false})
		corner(card,C.GROUP.RADIUS); stroke(card,C.COLOR.BORDER,nil,0.93)
		-- card bg gradient
		gradient(card,C.COLOR.BG3,C.COLOR.BG2,180)
		-- shadows
		make("Frame",{Size=UDim2.new(1,4,1,4),Position=UDim2.new(0,-2,0,-2),BackgroundColor3=Color3.fromRGB(0,0,0),BackgroundTransparency=0.7,BorderSizePixel=0,ZIndex=-1,Parent=card,Children={make("UICorner",{CornerRadius=UDim.new(0,C.GROUP.RADIUS+2),Parent=card})}})
		-- accent top bar thin
		make("Frame",{Size=UDim2.new(0,w-32,0,2),Position=UDim2.new(0.5,-w/2+16,0,0),BackgroundColor3=C.COLOR.ACCENT,BackgroundTransparency=0.4,BorderSizePixel=0,ZIndex=2,Parent=card}); corner(card:FindFirstChildWhichIsA("Frame") or make("Frame",{Size=UDim2.new(0,60,0,2),BackgroundColor3=C.COLOR.ACCENT,BorderSizePixel=0,Parent=card}),1)

		make("Frame",{Size=UDim2.new(1,0,0,C.GROUP.TITLE_H),BackgroundColor3=Color3.fromRGB(255,255,255),BackgroundTransparency=1,BorderSizePixel=0,Parent=card,Children={make("TextLabel",{Size=UDim2.new(1,-C.GROUP.PADDING*2,1,0),Position=UDim2.new(0,C.GROUP.PADDING,0,0),BackgroundTransparency=1,Text=tostring(title or"Group"),TextColor3=C.COLOR.TEXT,Font=C.FONT_BOLD,TextSize=C.TEXT_TITLE,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center})}})

		local content=make("Frame",{Size=UDim2.new(1,0,0,0),Position=UDim2.new(0,0,0,C.GROUP.TITLE_H+4),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,Parent=card})
		pad(content,C.GROUP.PADDING,C.GROUP.PADDING,0,C.GROUP.PADDING)
		local cl=make("UIListLayout",{Padding=UDim.new(0,C.CONTROL.GAP),SortOrder=Enum.SortOrder.LayoutOrder,Parent=content})
		cl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() card.Size=UDim2.new(0,w,0,C.GROUP.TITLE_H+4+cl.AbsoluteContentSize.Y+C.GROUP.PADDING) end)

		return {_card=card,_content=content,
			AddLabel=function(_,t) local l=createLabel(content,t); STATE.controls=STATE.controls+1; return l end,
			CreateLabel=function(_,s) local t=type(s)=="table" and(s.Name or s.Text)or tostring(s or""); local l=createLabel(content,t); STATE.controls=STATE.controls+1; return l end,
			AddToggle=function(_,fl,p) p=p or{}; local t2=createToggle(content,p.Text or fl,p.Default); STATE.controls=STATE.controls+1; return t2 end,
			AddSlider=function(_,fl,p) p=p or{}; local s2=createSlider(content,p.Text or fl,p.Min or 0,p.Max or 100,p.Default or p.Min or 0,p.Callback,p.Suffix,p.Rounding or 1); STATE.controls=STATE.controls+1; return s2 end,
			AddButton=function(_,p) p=p or{}; local b2=createButton(content,p.Text or"Button",p.Func); STATE.controls=STATE.controls+1; return b2 end,
			AddInput=function(_,fl,p) p=p or{}; local i2=createInput(content,p.Text or fl,p.Default or"",p.Placeholder or"Enter...",p.Callback); STATE.controls=STATE.controls+1; return i2 end,
			AddDropdown=function(_,fl,p) p=p or{}; local d2=createDropdown(content,p.Text or fl,p.Values or{},p.Default,p.Callback,p.Multi,p.Searchable); STATE.controls=STATE.controls+1; return d2 end,
			AddDivider=function() createDivider(content); STATE.controls=STATE.controls+1; return{}end,
		}
	end

	-- ========== TAB PANEL ==========
	local function createTab(window, name, iconId, columns)
		columns=math.max(1,math.min(3,tonumber(columns) or 2))
		local ca=window._contentArea; local cw=ca.AbsoluteSize.X-24
		local panel=make("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Visible=false,Parent=ca})
		local scroll=make("ScrollingFrame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4,ScrollBarImageColor3=C.COLOR.SCROLLBAR,AutomaticCanvasSize=Enum.AutomaticSize.Y,Parent=panel,ScrollBarImageTransparency=0.5}); pad(scroll,12,12,12,12)
		local cw2=math.max(240,(cw-12*(columns-1)-24)/columns)
		local cfs={}
		for i=1,columns do
			local cf=make("Frame",{Size=UDim2.new(0,cw2,0,0),Position=UDim2.new(0,(i-1)*(cw2+12),0,0),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,Parent=scroll})
			make("UIListLayout",{Padding=UDim.new(0,C.GROUP.GAP),SortOrder=Enum.SortOrder.LayoutOrder,Parent=cf}); cfs[i]=cf
		end
		return {_panel=panel,_scroll=scroll,_columns=columns,_colFrames=cfs,_columnWidth=cw2,_window=window,
			AddLeftGroupbox=function(_,gn) if not cfs[1] then return nil end; return createGroup(cfs[1],gn,1,cw2) end,
			AddRightGroupbox=function(_,gn) if not cfs[2] then return nil end; return createGroup(cfs[2],gn,2,cw2) end,
			AddGroupbox=function(_,gn) if cfs[1] then return createGroup(cfs[1],gn,1,cw2) end; return nil end,
			Select=function(self) window:selectTab(self) end,
		}
	end

	-- ========== WINDOW ==========
	local function createWindow(settings)
		settings=settings or{}; STATE.windowCount=STATE.windowCount+1; local uid=STATE.windowCount
		local ws=settings.Size or UDim2.new(0,780,0,540)
		local screen=make("ScreenGui",{Name="AlleralUI_"..uid,ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,DisplayOrder=100,Parent=(CoreGui:FindFirstChild("RobloxGui") or CoreGui)})

		-- layered background
		make("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=C.COLOR.BG0,BorderSizePixel=0,Parent=screen})
		make("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=C.COLOR.BG1,BackgroundTransparency=0.3,BorderSizePixel=0,Parent=screen})
		local radial=make("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,BorderSizePixel=0,Parent=screen})
		make("UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,C.COLOR.ACCENT),ColorSequenceKeypoint.new(1,Color3.fromRGB(0,0,0))}),Rotation=45,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.92),NumberSequenceKeypoint.new(1,1)}),Parent=radial})
		-- noise (subtle grain overlay via semi-transparent gradient checkerboard approach)
		make("Frame",{Size=UDim2.new(1,0,1,0),BackgroundColor3=Color3.fromRGB(255,255,255),BackgroundTransparency=0.98,BorderSizePixel=0,Parent=screen})

		-- MAIN WINDOW
		local main=make("Frame",{Size=ws,AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),BackgroundColor3=C.COLOR.BG1,BorderSizePixel=0,ClipsDescendants=true,ZIndex=2,Parent=screen})
		corner(main,C.WINDOW.RADIUS); stroke(main,C.COLOR.BORDER,nil,0.95)
		shadowLayers(main,ws,C.WINDOW.RADIUS)

		-- HEADER
		local header=make("Frame",{Size=UDim2.new(1,0,0,C.HEADER.H),BackgroundColor3=C.COLOR.BG0,BorderSizePixel=0,ZIndex=3,Parent=main}); corner(header,C.WINDOW.RADIUS)
		make("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,0),BackgroundColor3=C.COLOR.BORDER,BackgroundTransparency=0.95,BorderSizePixel=0,ZIndex=3,Parent=header})
		-- logo area
		local logo=make("Frame",{Size=UDim2.new(0,36,0,36),Position=UDim2.new(0,16,0.5,-18),BackgroundColor3=C.COLOR.ACCENT,BorderSizePixel=0,ZIndex=3,Parent=header}); corner(logo,10)
		make("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="A",TextColor3=C.COLOR.WHITE,Font=C.FONT_BOLD,TextSize=18,TextXAlignment=Enum.TextXAlignment.Center,TextYAlignment=Enum.TextYAlignment.Center,ZIndex=3,Parent=logo})
		make("TextLabel",{Size=UDim2.new(0,0,1,0),Position=UDim2.new(0,60,0,0),BackgroundTransparency=1,Text="Alleral",TextColor3=C.COLOR.TEXT,Font=C.FONT_BOLD,TextSize=C.TEXT_HEADER,AutomaticSize=Enum.AutomaticSize.X,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,ZIndex=3,Parent=header})
		-- version badge
		make("Frame",{Size=UDim2.new(0,54,0,20),Position=UDim2.new(0,130,0.5,-10),BackgroundColor3=C.COLOR.ACCENT,BorderSizePixel=0,ZIndex=3,Parent=header,Children={make("UICorner",{CornerRadius=UDim.new(0,6),Parent=header}),make("TextLabel",{Size=UDim2.new(1,-6,1,0),Position=UDim2.new(0,3,0,0),BackgroundTransparency=1,Text=C.VERSION,TextColor3=C.COLOR.WHITE,Font=C.FONT_BOLD,TextSize=10,ZIndex=3})}})
		-- keybind display
		make("TextLabel",{Size=UDim2.new(0,140,1,0),Position=UDim2.new(0,200,0,0),BackgroundTransparency=1,Text="Toggle: RightShift",TextColor3=C.COLOR.TEXT3,Font=C.FONT,TextSize=C.TEXT_SM,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,ZIndex=3,Parent=header})
		-- close button
		local closeBtn=make("TextButton",{Size=UDim2.new(0,28,0,28),Position=UDim2.new(1,-36,0,22),BackgroundColor3=Color3.fromRGB(255,255,255),BackgroundTransparency=1,BorderSizePixel=0,Text="✕",TextColor3=C.COLOR.TEXT2,Font=C.FONT,TextSize=14,AutoButtonColor=false,ZIndex=3,Parent=header})
		corner(closeBtn,6)
		closeBtn.MouseEnter:Connect(function() Anim.spring(closeBtn,{BackgroundTransparency=0}) end)
		closeBtn.MouseLeave:Connect(function() Anim.spring(closeBtn,{BackgroundTransparency=1}) end)

		-- SIDEBAR
		local sidebar=make("Frame",{Size=UDim2.new(0,C.SIDEBAR.W,1,-C.HEADER.H),Position=UDim2.new(0,0,0,C.HEADER.H),BackgroundColor3=Color3.fromRGB(255,255,255),BackgroundTransparency=0.97,BorderSizePixel=0,ZIndex=2,Parent=main})
		make("UIListLayout",{Padding=UDim.new(0,2),SortOrder=Enum.SortOrder.LayoutOrder,Parent=sidebar}); pad(sidebar,8,8,8,8)

		-- CONTENT AREA
		local ca=make("Frame",{Size=UDim2.new(1,-C.SIDEBAR.W,1,-C.HEADER.H-C.FOOTER.H),Position=UDim2.new(0,C.SIDEBAR.W,0,C.HEADER.H),BackgroundColor3=Color3.fromRGB(255,255,255),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=1,Parent=main})

		-- FOOTER
		local footer=make("Frame",{Size=UDim2.new(1,-C.SIDEBAR.W,0,C.FOOTER.H),Position=UDim2.new(0,C.SIDEBAR.W,1,-C.FOOTER.H),BackgroundColor3=C.COLOR.BG0,BorderSizePixel=0,ZIndex=2,Parent=main})
		make("Frame",{Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,0,0),BackgroundColor3=C.COLOR.BORDER,BackgroundTransparency=0.95,BorderSizePixel=0,Parent=footer})
		make("TextLabel",{Size=UDim2.new(1,-16,1,0),Position=UDim2.new(0,8,0,0),BackgroundTransparency=1,Text="Noble Engine v"..C.VERSION,TextColor3=C.COLOR.TEXT3,Font=C.FONT,TextSize=C.TEXT_SM-1,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,ZIndex=3,Parent=footer})
		make("TextLabel",{Size=UDim2.new(0,140,1,0),Position=UDim2.new(1,-140,0,0),BackgroundTransparency=1,Text="Toggle: RightShift",TextColor3=C.COLOR.TEXT3,Font=C.FONT,TextSize=C.TEXT_SM-1,TextXAlignment=Enum.TextXAlignment.Right,TextYAlignment=Enum.TextYAlignment.Center,ZIndex=3,Parent=footer})

		local tabs={}; local activeTab=nil
		local function selectTab(tab)
			if activeTab==tab then return end
			if activeTab then safeVis(activeTab._panel,false); if activeTab._sidebarBtn then Anim.spring(activeTab._sidebarBtn,{BackgroundColor3=Color3.fromRGB(255,255,255),BackgroundTransparency=0.97}) end end
			safeVis(tab._panel,true); Anim.fadeIn(tab._panel,0.12)
			if tab._sidebarBtn then Anim.spring(tab._sidebarBtn,{BackgroundColor3=C.COLOR.ACCENT,BackgroundTransparency=0.85}) end
			activeTab=tab
		end

		local uiHidden=false; local wc={}
		function wc:Hide() if uiHidden then return end; uiHidden=true; Anim.stopAll(); Anim.centerOut(main) end
		function wc:Show() if not uiHidden then return end; uiHidden=false; Anim.stopAll(); Anim.centerIn(main) end
		function wc:Toggle() if uiHidden then wc:Show() else wc:Hide() end end
		closeBtn.MouseButton1Click:Connect(function() wc:Hide() end)

		local w=setmetatable({_main=main,_header=header,_sidebar=sidebar,_contentArea=ca,_screen=screen,_tabs=tabs,_footer=footer,Hide=wc.Hide,Show=wc.Show,Toggle=wc.Toggle,selectTab=selectTab},{__index=wc})

		function w:AddTab(name,iconId)
			local to=createTab(self,name,iconId,2)
			local sb=make("TextButton",{Size=UDim2.new(1,0,0,C.SIDEBAR.ITEM_H),BackgroundColor3=Color3.fromRGB(255,255,255),BackgroundTransparency=0.97,BorderSizePixel=0,Text="",AutoButtonColor=false,ZIndex=2,Parent=sidebar})
			corner(sb,C.SIDEBAR.RADIUS)
			-- active indicator bar
			make("Frame",{Size=UDim2.new(0,3,1,-12),Position=UDim2.new(0,0,0,6),BackgroundColor3=C.COLOR.ACCENT,BorderSizePixel=0,ZIndex=4,Parent=sb})
			local ic; if iconId then ic=make("ImageLabel",{Size=UDim2.new(0,C.SIDEBAR.ICON_SIZE,0,C.SIDEBAR.ICON_SIZE),Position=UDim2.new(0,12,0.5,-C.SIDEBAR.ICON_SIZE/2),BackgroundTransparency=1,Image=type(iconId)=="number" and("rbxassetid://"..iconId)or iconId,ZIndex=3,Parent=sb}) end
			local sl=make("TextLabel",{Size=UDim2.new(1,-(ic and C.SIDEBAR.ICON_SIZE+24 or 16),1,0),Position=UDim2.new(0,ic and C.SIDEBAR.ICON_SIZE+20 or 12,0,0),BackgroundTransparency=1,Text=tostring(name),TextColor3=C.COLOR.TEXT2,Font=C.FONT,TextSize=C.TEXT,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=3,Parent=sb})
			to._sidebarBtn=sb; to._sidebarLabel=sl
			sb.MouseEnter:Connect(function() if activeTab~=to then Anim.spring(sb,{BackgroundTransparency=0.94}) end end)
			sb.MouseLeave:Connect(function() if activeTab~=to then Anim.spring(sb,{BackgroundTransparency=0.97}) end end)
			sb.MouseButton1Click:Connect(function() selectTab(to) end)
			table.insert(tabs,to); STATE.tabCount=STATE.tabCount+1
			if #tabs==1 then task.wait(0.05); selectTab(to) end
			return to
		end
		function w:Destroy() Anim.stopAll(); pcall(function() screen:Destroy() end); STATE.uiDestroyed=true end
		Anim.centerIn(main)
		return w
	end

	-- ========== KEYBIND ==========
	local keybindConn=nil
	local function setupKeybind(win)
		if keybindConn then keybindConn:Disconnect() end
		keybindConn=UIS.InputBegan:Connect(function(input,gpe) if gpe then return end; if input.KeyCode==STATE.toggleKey and win and type(win.Toggle)=="function" then win:Toggle() end end)
	end

	-- ========== NOTIFICATIONS ==========
	local function initNotifC()
		if STATE.notifContainer and STATE.notifContainer.Parent then return STATE.notifContainer end
		local sg=make("ScreenGui",{Name="AlleralNotifs",ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,DisplayOrder=999,Parent=(CoreGui:FindFirstChild("RobloxGui") or CoreGui)})
		local c=make("Frame",{Name="NotifC",AnchorPoint=Vector2.new(0.5,0),Position=UDim2.fromScale(0.5,0.02),Size=UDim2.new(0,C.NOTIF.W,1,-40),BackgroundTransparency=1,Parent=sg})
		make("UIListLayout",{Padding=UDim.new(0,8),HorizontalAlignment=Enum.HorizontalAlignment.Center,VerticalAlignment=Enum.VerticalAlignment.Top,SortOrder=Enum.SortOrder.LayoutOrder,Parent=c})
		STATE.notifContainer=c; return c
	end
	local function showNotification(text,duration,ntype)
		duration=duration or 4; ntype=ntype or"info"; STATE.notifIdx=STATE.notifIdx+1
		local cont=initNotifC(); local tc=nil; if ntype=="success" then tc=C.COLOR.GREEN elseif ntype=="error" then tc=C.COLOR.RED elseif ntype=="warning" then tc=C.COLOR.YELLOW else tc=C.COLOR.ACCENT end
		local f=make("Frame",{Name="N_"..STATE.notifIdx,Size=UDim2.new(0,0,0,0),BackgroundColor3=C.COLOR.BG1,BorderSizePixel=0,ClipsDescendants=true,LayoutOrder=STATE.notifIdx,Parent=cont}); corner(f,C.NOTIF.RADIUS); stroke(f,C.COLOR.BORDER,nil,0.92)
		make("Frame",{Size=UDim2.new(1,0,0,3),Position=UDim2.new(0,0,0,0),BackgroundColor3=tc,BorderSizePixel=0,Parent=f}); make("UICorner",{CornerRadius=UDim.new(0,3),Parent=f})
		make("TextLabel",{Size=UDim2.new(0,24,0,24),Position=UDim2.new(0,8,0,8),BackgroundTransparency=1,Text="•",TextColor3=tc,Font=C.FONT_BOLD,TextSize=18,TextXAlignment=Enum.TextXAlignment.Center,TextYAlignment=Enum.TextYAlignment.Center,Parent=f})
		local lbl=make("TextLabel",{Size=UDim2.new(1,-44,0,0),Position=UDim2.new(0,36,0,8),BackgroundTransparency=1,Text=tostring(text),TextColor3=C.COLOR.TEXT,Font=C.FONT,TextSize=C.TEXT_SM+1,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,Parent=f}); pad(f,0,0,8,8)
		task.wait(0.02); local th=math.max(lbl.TextBounds.Y+20,52)
		Anim.spring(f,{Size=UDim2.new(1,0,0,th)})
		local allN={}
		for _,ch in ipairs(cont:GetChildren()) do if ch:IsA("Frame") and ch.Name:find("N_") then table.insert(allN,ch) end end
		table.sort(allN,function(a,b) return a.LayoutOrder<b.LayoutOrder end)
		while #allN>C.NOTIF.MAX do local o=allN[1]; table.remove(allN,1); pcall(function() Anim.tween(o,{Size=UDim2.new(0,0,0,0),BackgroundTransparency=1},0.12); task.delay(0.15,function() pcall(function() o:Destroy() end) end) end) end
		f.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then Anim.tween(f,{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1},0.1); task.delay(0.12,function() pcall(function() f:Destroy() end) end) end end)
		task.delay(duration,function() if f and f.Parent then Anim.tween(f,{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1},0.12); task.delay(0.15,function() pcall(function() f:Destroy() end) end) end end)
		return f
	end

	-- ========== EMPTY STUB ==========
	local function emptyGroupStub()
		local function s() return{Set=function()end,SetText=function()end,SetVisible=function()end,SetValue=function()end,Refresh=function()end,Container=nil}end
		local function l() return{Set=function()end,SetText=function()end,SetVisible=function()end}end
		return{AddLabel=l,CreateLabel=l,AddToggle=s,AddSlider=s,AddButton=s,AddInput=s,AddDropdown=s,AddDivider=function()return{}end,AddLeftGroupbox=s,AddRightGroupbox=s,AddGroupbox=s,Select=function()end}
	end

	-- ========== LIBRARY ==========
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
		window.Hide=function() if win then win:Hide() end end; window.Show=function() if win then win:Show() end end
		window.Toggle=function() if win then win:Toggle() elseif ENV.Alleral_UiWindow and type(ENV.Alleral_UiWindow.Toggle)=="function" then ENV.Alleral_UiWindow:Toggle() end end
		ENV.Alleral_UiWindow=window; return window
	end
	function Library:Notification(info)
		local txt,dur,nt="",4,"info"
		if type(info)=="string" then txt=info
		elseif type(info)=="table" then local tl=textOf(info.Title or info.Name or""); local bd=textOf(info.Description or info.Content or info.Text or""); txt=(tl~="" and bd~="" and(tl.."\n"..bd)) or tl or bd; dur=tonumber(info.Duration or info.Lifetime or info.Time or 4); nt=info.Type or"info"; if nt=="success"or nt=="Success"then nt="success"elseif nt=="error"or nt=="Error"then nt="error"elseif nt=="warning"or nt=="Warning"then nt="warning"end
		else txt=textOf(info) end; return showNotification(txt,math.max(1,dur),nt)
	end
	function Library:Notify(text,dur) if type(text)=="table" then Library:Notification(text) else Library:Notification({Description=text,Duration=dur}) end end
	function Library:ClearNotifications() if STATE.notifContainer then for _,ch in ipairs(STATE.notifContainer:GetChildren()) do if ch:IsA("Frame") and ch.Name:find("N_") then ch:Destroy() end end end end

	-- ========== CORE API ==========
	function Core.loadUi()
		local c=ENV.Alleral_UI; if type(c)=="table" and type(c.Library)=="table" then return c end
		local b={Library=Library,Alleral=Library,CreateWindow=function(_,s) return Library:CreateWindow(s) end,Notify=function(_,t,d) Library:Notify(t,d) end,ClearNotifications=function() Library:ClearNotifications() end}
		ENV.Alleral_UI=b; if getgenv then getgenv().Alleral_UI=b end; log("INFO","[UI] Premium renderer ready"); return b
	end
	function Core.preloadUi() return Core.loadUi() end
	function Core.uiLibrary(b) if type(b)~="table" then return nil end; return b.Alleral or b.Library end
	function Core.uiWindowSettings(extra) extra=type(extra)=="table" and extra or{}; return{Title=extra.Title or extra.Name or"Alleral",Name=extra.Title or extra.Name or"Alleral",Subtitle=extra.Subtitle or extra.Author or"",Icon=extra.Icon or"sparkles",Theme=extra.Theme or"Noble",Size=extra.Size or UDim2.new(0,780,0,540),TabWidth=tonumber(extra.TabWidth) or C.SIDEBAR.W,FileSettings={RootFolder=extra.configFolder or"Alleral_Configs",ConfigFolder=extra.FileName or"Interface"}} end

	-- ========== GROUPBOX WRAPPER ==========
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

	-- ========== UI WRAPPERS ==========
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
		if type(Core._UiTabRegistry)=="table" then table.insert(Core._UiTabRegistry,tab) end
		function tab:CreateGroupbox(settings)
			settings=settings or{}; local name=settings.Name or settings.Group or"Group"; STATE.groupCount=STATE.groupCount+1
			if not rt then table.insert(STATE.missingBindings,"Groupbox:"..name.."(no tab)"); return{}end
			local h=sc("Groupbox:"..name,function() local col=tonumber(settings.Column)or 1; if col==2 and rt.AddRightGroupbox then return rt:AddRightGroupbox(name)elseif rt.AddLeftGroupbox then return rt:AddLeftGroupbox(name)elseif rt.AddGroupbox then return rt:AddGroupbox(name)end; return nil end)
			if not h then table.insert(STATE.missingBindings,"Groupbox:"..name.."(failed)"); return{}end; tab._sectionIndex=(tab._sectionIndex or 0)+1; return Core.createUiGroupbox(h,ub)
		end
		function tab:Select() if rt and rt.Select then rt:Select() end end
		function tab:BuildThemeGroupbox(col) local g2=Core.buildUiGroup(tab,"Appearance",col or 1); if g2 and type(g2.CreateLabel)=="function" then g2:CreateLabel("Alleral Noble Engine") end; return g2 end
		return tab
	end
	function Core.buildUiWindow(ui,settings)
		settings=settings or{}; local lib=ui and ui.Library; if not lib or type(lib.CreateWindow)~="function" then return nil end
		local rw=lib:CreateWindow(settings); if not rw then return nil end
		local w={_rawWindow=rw,_ui=ui,_library=lib,_initialized=false,_tabGroup=rw,_alleralSettings=settings}
		if type(Core.registerUiWindow)=="function" then Core.registerUiWindow(w) end; if type(Core.flushPendingNotifications)=="function" then Core.flushPendingNotifications() end; return w
	end
	function Core.buildUiTab(section,name,icon,columns,id)
		local w2=type(Core.resolveUiWindow)=="function" and Core.resolveUiWindow(section)or nil
		if type(w2)~="table" or not w2._rawWindow then return Core.wrapUiTab(nil,type(section)=="table" and section._ui or nil,w2) end
		local tg=w2._tabGroup or w2; if not tg or type(tg.AddTab)~="function" then return Core.wrapUiTab(nil,w2._ui,w2) end
		local rt=tg:AddTab(name,icon); STATE.tabCount=STATE.tabCount+1
		local wr=Core.wrapUiTab(rt,w2._ui or(type(section)=="table" and section._ui)or nil,w2); wr._columnCount=math.max(1,tonumber(columns)or 2); if not w2._defaultTab then w2._defaultTab=rt end; return wr
	end
	function Core.buildUiGroup(tab,name,column,cb,icon,id)
		name=tostring(name or"Group"); if type(tab)~="table" or type(tab.CreateGroupbox)~="function" then return{}end; return Core.wrapUiGroup(tab:CreateGroupbox({Name=name,Column=column or 1,Icon=icon}),cb)
	end
	function Core.buildUiSection(w2) if type(w2)=="table" and w2._alleralTabGroup then return w2._alleralTabGroup end; if type(w2)=="table" and w2._rawWindow then return w2 end; return w2 end
	function Core.finalizeGameUi(window,ui,options)
		options=type(options)=="table" and options or{}
		if type(window)=="table" and window._rawWindow and not window._initialized then window._initialized=true; task.defer(function() pcall(function() if window._defaultTab and window._defaultTab.Select then window._defaultTab:Select() end end) end) end
		if type(Core.setupHubKeybinds)=="function" then pcall(Core.setupHubKeybinds,{window=window,ui=ui or window._ui or ENV.Alleral_UI}) end
		if options.notify~=false then Core.notifyBootReady({Name=options.Name or"Alleral",Subtitle=options.Subtitle}) end
		log("INFO","=== Noble Engine v"..C.VERSION.." ==="); log("INFO","Tabs: "..STATE.tabCount.." | Groups: "..STATE.groupCount.." | Controls: "..STATE.controls); if #STATE.missingBindings>0 then log("WARN","Missing: "..#STATE.missingBindings) end; return window
	end
	function Core.repairUiWindow(w3) w3=w3 or ENV.Alleral_UiWindow; return type(w3)=="table" and w3._rawWindow~=nil end
	function Core.refreshAllTabColumns() return true end
	Core.notifyUi=function(i) showNotification(textOf(i),4) end
	Core.releaseAlleralRuntime=function()
		Anim.stopAll(); if keybindConn then keybindConn:Disconnect(); keybindConn=nil end
		ENV._AlleralUiLibrary=nil; ENV._AlleralUI=nil; ENV.Alleral_UiWindow=nil
		if STATE.notifContainer then pcall(function() STATE.notifContainer.Parent:Destroy() end); STATE.notifContainer=nil end
		if STATE.dropOverlay then pcall(function() STATE.dropOverlay.Parent:Destroy() end); STATE.dropOverlay=nil end
	end
	ENV.AnimatedNotification=showNotification
	log("INFO","Alleral Noble v"..C.VERSION.." — premium dashboard initialized")
end

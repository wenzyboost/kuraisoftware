--[[
╔══════════════════════════════════════════════════════════════════════╗
║            KuraiSoftware v5.0 — COMPLETE REWORK                     ║
║            Architecture modulaire | UI Premium | Server-safe        ║
║            discord.gg/kuraishop                                     ║
╚══════════════════════════════════════════════════════════════════════╝

    ARCHITECTURE:
    ┌─ Shared/Config.lua       — Configuration centrale
    ├─ Shared/Utils.lua        — Utilitaires
    ├─ Shared/Signal.lua       — Événements
    ├─ Services/Janitor.lua    — Cleanup manager
    ├─ Services/RoleService.lua — Rôles
    ├─ Services/PlayerService.lua — Joueur local
    ├─ UI/Components.lua       — Composants UI
    └─ UI/Notifications.lua    — Notifications
]]

-- ══════════════════════════════════════════════
--  SERVICES ROBLOX
-- ══════════════════════════════════════════════
local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local UIS           = game:GetService("UserInputService")
local TweenService  = game:GetService("TweenService")
local WS            = game:GetService("Workspace")
local CoreGui       = game:GetService("CoreGui")
local Lighting      = game:GetService("Lighting")
local Debris        = game:GetService("Debris")
local HttpService   = game:GetService("HttpService")
local TS            = game:GetService("TeleportService")
local Stats         = game:GetService("Stats")

-- ══════════════════════════════════════════════
--  INLINE CONFIG (pour script monolithique)
-- ══════════════════════════════════════════════
local C = {
    Bg0        = Color3.fromRGB(8,   8,  12),
    Bg1        = Color3.fromRGB(12,  12, 18),
    Bg2        = Color3.fromRGB(18,  18, 26),
    Bg3        = Color3.fromRGB(24,  24, 34),
    Bg4        = Color3.fromRGB(32,  32, 46),
    Accent     = Color3.fromRGB(190, 28, 48),
    AccentDim  = Color3.fromRGB(110, 16, 28),
    AccentGlow = Color3.fromRGB(255, 70, 90),
    AccentSoft = Color3.fromRGB(220, 50, 70),
    TextPrim   = Color3.fromRGB(235, 235, 245),
    TextSec    = Color3.fromRGB(160, 160, 178),
    TextMuted  = Color3.fromRGB(90,  90,  110),
    TextDis    = Color3.fromRGB(55,  55,  70),
    Success    = Color3.fromRGB(60,  200, 100),
    Warning    = Color3.fromRGB(240, 180, 40),
    Error      = Color3.fromRGB(230, 60,  60),
    Info       = Color3.fromRGB(60,  140, 240),
    Murder     = Color3.fromRGB(255, 50,  70),
    Sheriff    = Color3.fromRGB(50,  150, 255),
    Innocent   = Color3.fromRGB(80,  220, 120),
    Spectator  = Color3.fromRGB(150, 150, 180),
    Unknown    = Color3.fromRGB(100, 100, 120),
    Sep        = Color3.fromRGB(30,  30,  44),
    SepLight   = Color3.fromRGB(45,  45,  62),
    TogOn      = Color3.fromRGB(190, 28,  48),
    TogOff     = Color3.fromRGB(48,  48,  65),
}

local AI_FAST   = TweenInfo.new(0.14, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)
local AI_MED    = TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local AI_SPRING = TweenInfo.new(0.38, Enum.EasingStyle.Back,  Enum.EasingDirection.Out)
local AI_LINEAR = TweenInfo.new(1.0,  Enum.EasingStyle.Linear)

-- ══════════════════════════════════════════════
--  CONFIGURATION ÉTAT
-- ══════════════════════════════════════════════
local CFG = {
    DEBUG = false,
    MENU_KEY = Enum.KeyCode.RightShift,
    WIN = {W = 700, H = 490, SideW = 172},
    ESP = {
        Enabled=false, Box=true, Names=true, Distance=true,
        Health=true, Tracer=false, Roles=true, MaxDist=1000,
        ShowMurder=true, ShowSheriff=true, ShowInnocent=true,
    },
    CAMLOCK = {Enabled=false, FOV=150, Smooth=0.12, Part="Head", ShowFOV=true, SilentAim=false, SAimPart="Head"},
    PLAYER  = {SpeedEnabled=false, SpeedVal=16, JumpEnabled=false, JumpVal=50, Noclip=false, FlyEnabled=false, FlySpeed=40, Invisible=false, AntiFling=false, InfStamina=false},
    CROSSHAIR={Enabled=false, Style="Cross", Size=8, Gap=4, Thick=1.5, Spin=false, Color=Color3.fromRGB(255,255,255)},
    COMBAT  = {AutoFarm=false, FarmMode="Nearest", AutoGrabGun=false},
    WEBHOOK = {URL="", Enabled=false, LogKills=false, LogRole=false},
    GRAPHICS= {LowGfx=false, HighGfx=false, FOV=70},
}

local STATE = {
    MenuOpen      = true,
    ActiveTab     = "Dashboard",
    TargetPlayer  = nil,
    FlingTarget   = false,
    LoopGoto      = false,
    FlingMurderer = false,
    FlingSheriff  = false,
    CrossAngle    = 0,
    FPS           = 0,
    Ping          = 0,
    FPS_t         = 0,
    Farm_t        = 0,
    Gun_t         = 0,
    Fling_t       = 0,
}

-- ══════════════════════════════════════════════
--  JANITOR
-- ══════════════════════════════════════════════
local MainJ = {}
MainJ._items = {}
function MainJ:Add(item, method)
    table.insert(self._items, {item=item, method=method})
    return item
end
function MainJ:Clean()
    for _, e in ipairs(self._items) do
        pcall(function()
            if e.method == "__call" then e.item()
            elseif e.method == "Disconnect" and e.item and e.item.Disconnect then e.item:Disconnect()
            elseif e.method == "Destroy"    and e.item and e.item.Destroy    then e.item:Destroy()
            elseif e.method == "Remove"     and e.item and e.item.Remove     then e.item:Remove()
            end
        end)
    end
    self._items = {}
end

local CharJ = {_items = {}}
setmetatable(CharJ, {__index = MainJ})
CharJ.Clean = MainJ.Clean

-- ══════════════════════════════════════════════
--  LOG
-- ══════════════════════════════════════════════
local function Log(msg)
    if CFG.DEBUG then print("[KuraiV5] " .. tostring(msg)) end
end
local function Warn(msg)
    if CFG.DEBUG then warn("[KuraiV5] " .. tostring(msg)) end
end

-- ══════════════════════════════════════════════
--  PLAYER HELPERS
-- ══════════════════════════════════════════════
local LP   = Players.LocalPlayer
local Cam  = WS.CurrentCamera
local Mouse = LP:GetMouse()

local function GetChar()  return LP.Character end
local function GetHum()   local c=GetChar(); return c and c:FindFirstChildOfClass("Humanoid") end
local function GetRoot()  local c=GetChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function Dist(a,b)  return (a-b).Magnitude end
local function W2V(pos)
    local sp, on = Cam:WorldToViewportPoint(pos)
    return Vector2.new(sp.X, sp.Y), on, sp.Z
end
local function Safe(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then Warn(tostring(err)) end
    return ok
end
local function Tween(obj, info, props)
    if not obj or not obj.Parent then return end
    TweenService:Create(obj, info, props):Play()
end

-- ══════════════════════════════════════════════
--  ROLE MODULE
-- ══════════════════════════════════════════════
local Roles = {}
Roles._cache = {}
Roles._dirty = true

function Roles:Invalidate() self._dirty = true end
function Roles:Scan()
    if not self._dirty then return end
    self._dirty = false
    self._cache = {}
    for _, p in ipairs(Players:GetPlayers()) do
        local char = p.Character
        if not char then self._cache[p]="Innocent"; continue end
        local found = false
        for _, v in ipairs(char:GetChildren()) do
            if v:IsA("Tool") then
                local n = v.Name:lower()
                if n:find("knife") then self._cache[p]="Murder"; found=true; break
                elseif n:find("gun") then self._cache[p]="Sheriff"; found=true; break end
            end
        end
        if not found then
            pcall(function()
                if p:FindFirstChild("IsMurderer") and p.IsMurderer.Value then self._cache[p]="Murder"; found=true
                elseif p:FindFirstChild("IsSheriff") and p.IsSheriff.Value then self._cache[p]="Sheriff"; found=true end
            end)
        end
        if not self._cache[p] then self._cache[p]="Innocent" end
    end
end
function Roles:GetRole(p)  self:Scan(); return self._cache[p] or "Unknown" end
function Roles:GetMurder() self:Scan(); for p,r in pairs(self._cache) do if r=="Murder" then return p end end return nil end
function Roles:GetSheriff()self:Scan(); for p,r in pairs(self._cache) do if r=="Sheriff"then return p end end return nil end
function Roles:GetColor(p)
    local r=self:GetRole(p)
    local map={Murder=C.Murder,Sheriff=C.Sheriff,Innocent=C.Innocent,Spectator=C.Spectator,Unknown=C.Unknown}
    return map[r] or C.Unknown
end
function Roles:GetLabel(p)
    local r=self:GetRole(p)
    local map={Murder="[MURDER]",Sheriff="[SHERIFF]",Innocent="[INNOCENT]",Spectator="[SPECTATOR]",Unknown="[?]"}
    return map[r] or "[?]"
end
function Roles:GetIcon(p)
    local r=self:GetRole(p)
    local map={Murder="🔪",Sheriff="⭐",Innocent="👤",Spectator="👁",Unknown="❓"}
    return map[r] or "❓"
end

-- Hook role detection
for _, p in ipairs(Players:GetPlayers()) do
    if p.Character then
        p.Character.ChildAdded:Connect(function(c) if c:IsA("Tool") then Roles:Invalidate() end end)
        p.Character.ChildRemoved:Connect(function(c) if c:IsA("Tool") then Roles:Invalidate() end end)
    end
    p.CharacterAdded:Connect(function(char)
        char.ChildAdded:Connect(function(c) if c:IsA("Tool") then Roles:Invalidate() end end)
        char.ChildRemoved:Connect(function(c) if c:IsA("Tool") then Roles:Invalidate() end end)
    end)
end
Players.PlayerRemoving:Connect(function(p) Roles._cache[p]=nil end)

-- ══════════════════════════════════════════════
--  NEAREST PLAYER
-- ══════════════════════════════════════════════
local function GetNearest(fov)
    local root=GetRoot(); if not root then return nil end
    local nearest,nearDist=nil,math.huge
    local center=Vector2.new(Cam.ViewportSize.X/2,Cam.ViewportSize.Y/2)
    for _,p in ipairs(Players:GetPlayers()) do
        if p==LP then continue end
        local char=p.Character; if not char then continue end
        local hr=char:FindFirstChild("HumanoidRootPart"); if not hr then continue end
        local sp,onSc=Cam:WorldToViewportPoint(hr.Position); if not onSc then continue end
        local d2=(Vector2.new(sp.X,sp.Y)-center).Magnitude
        if fov and d2>fov then continue end
        local dist=Dist(root.Position,hr.Position)
        if dist<nearDist then nearest=p; nearDist=dist end
    end
    return nearest
end

-- ══════════════════════════════════════════════
--  SCREEN GUI
-- ══════════════════════════════════════════════
pcall(function()
    local old=CoreGui:FindFirstChild("KuraiSoftwareV5")
    if old then old:Destroy() end
end)
pcall(function()
    local old=LP:FindFirstChild("PlayerGui") and LP.PlayerGui:FindFirstChild("KuraiSoftwareV5")
    if old then old:Destroy() end
end)

local SG = Instance.new("ScreenGui")
SG.Name           = "KuraiSoftwareV5"
SG.ResetOnSpawn   = false
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.IgnoreGuiInset = true
SG.DisplayOrder   = 999
MainJ:Add(SG, "Destroy")
pcall(function() SG.Parent = CoreGui end)
if not SG.Parent then SG.Parent = LP:WaitForChild("PlayerGui") end

-- ══════════════════════════════════════════════
--  NOTIFICATION SYSTEM
-- ══════════════════════════════════════════════
local NotifContainer = Instance.new("Frame")
NotifContainer.Name                 = "NotifContainer"
NotifContainer.BackgroundTransparency = 1
NotifContainer.Position             = UDim2.new(1,-320,1,-16)
NotifContainer.Size                 = UDim2.new(0,300,1,0)
NotifContainer.AnchorPoint          = Vector2.new(0,1)
NotifContainer.ZIndex               = 100
NotifContainer.Parent               = SG
local _notifLayout = Instance.new("UIListLayout")
_notifLayout.SortOrder         = Enum.SortOrder.LayoutOrder
_notifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
_notifLayout.Padding           = UDim.new(0,6)
_notifLayout.Parent            = NotifContainer

local _notifStack = {}
local NOTIF_COLORS = {success=C.Success,info=C.Info,warning=C.Warning,error=C.Error}
local NOTIF_ICONS  = {success="✓",info="ℹ",warning="⚠",error="✕"}

local function Notify(title, msg, ntype, dur)
    ntype = ntype or "info"
    dur   = dur   or 4
    if #_notifStack >= 5 then
        local old = table.remove(_notifStack,1)
        if old and old.Parent then old:Destroy() end
    end
    local col  = NOTIF_COLORS[ntype] or C.Info
    local icon = NOTIF_ICONS[ntype]  or "ℹ"

    local card = Instance.new("Frame")
    card.Name                 = "Notif"
    card.BackgroundColor3     = C.Bg2
    card.BorderSizePixel      = 0
    card.Size                 = UDim2.new(1,0,0,68)
    card.BackgroundTransparency = 1
    card.ZIndex               = 101
    card.Parent               = NotifContainer
    local co = Instance.new("UICorner"); co.CornerRadius=UDim.new(0,10); co.Parent=card

    -- Accent bar
    local bar=Instance.new("Frame"); bar.BackgroundColor3=col; bar.BorderSizePixel=0
    bar.Position=UDim2.new(0,0,0,0); bar.Size=UDim2.new(0,3,1,0); bar.ZIndex=102; bar.Parent=card
    local bc=Instance.new("UICorner"); bc.CornerRadius=UDim.new(0,3); bc.Parent=bar

    -- Icon bg
    local ibg=Instance.new("Frame"); ibg.BackgroundColor3=col; ibg.BorderSizePixel=0
    ibg.BackgroundTransparency=0.75; ibg.Position=UDim2.new(0,12,0.5,-14); ibg.Size=UDim2.new(0,28,0,28)
    ibg.ZIndex=102; ibg.Parent=card
    local ic2=Instance.new("UICorner"); ic2.CornerRadius=UDim.new(0,99); ic2.Parent=ibg
    local iLbl=Instance.new("TextLabel"); iLbl.BackgroundTransparency=1; iLbl.Size=UDim2.new(1,0,1,0)
    iLbl.Font=Enum.Font.GothamBold; iLbl.Text=icon; iLbl.TextColor3=col; iLbl.TextSize=14; iLbl.ZIndex=103; iLbl.Parent=ibg

    -- Title
    local tLbl=Instance.new("TextLabel"); tLbl.BackgroundTransparency=1
    tLbl.Position=UDim2.new(0,50,0,10); tLbl.Size=UDim2.new(1,-62,0,20)
    tLbl.Font=Enum.Font.GothamBold; tLbl.Text=tostring(title); tLbl.TextColor3=C.TextPrim
    tLbl.TextSize=13; tLbl.TextXAlignment=Enum.TextXAlignment.Left; tLbl.ZIndex=102; tLbl.Parent=card

    -- Message
    local mLbl=Instance.new("TextLabel"); mLbl.BackgroundTransparency=1
    mLbl.Position=UDim2.new(0,50,0,30); mLbl.Size=UDim2.new(1,-62,0,26)
    mLbl.Font=Enum.Font.Gotham; mLbl.Text=tostring(msg); mLbl.TextColor3=C.TextSec
    mLbl.TextSize=11; mLbl.TextXAlignment=Enum.TextXAlignment.Left; mLbl.TextWrapped=true
    mLbl.ZIndex=102; mLbl.Parent=card

    -- Progress bar
    local prog=Instance.new("Frame"); prog.BackgroundColor3=col; prog.BorderSizePixel=0
    prog.BackgroundTransparency=0.5; prog.Position=UDim2.new(0,4,1,-3)
    prog.Size=UDim2.new(1,-8,0,2); prog.ZIndex=102; prog.Parent=card
    local pc=Instance.new("UICorner"); pc.CornerRadius=UDim.new(0,2); pc.Parent=prog

    table.insert(_notifStack, card)
    TweenService:Create(card, AI_SPRING, {BackgroundTransparency=0}):Play()
    TweenService:Create(prog, TweenInfo.new(dur, Enum.EasingStyle.Linear), {Size=UDim2.new(0,0,0,2)}):Play()

    task.delay(dur, function()
        if not card or not card.Parent then return end
        TweenService:Create(card, AI_MED, {BackgroundTransparency=1, Position=UDim2.new(1,8,0,0)}):Play()
        task.delay(0.26, function()
            if card and card.Parent then
                local idx=table.find(_notifStack, card)
                if idx then table.remove(_notifStack, idx) end
                card:Destroy()
            end
        end)
    end)
end

-- ══════════════════════════════════════════════
--  FACTORY UI HELPERS
-- ══════════════════════════════════════════════
local function New(cls, props, parent)
    local i=Instance.new(cls)
    if parent then i.Parent=parent end
    for k,v in pairs(props or {}) do pcall(function() i[k]=v end) end
    return i
end
local function Corner(r,p) return New("UICorner",{CornerRadius=UDim.new(0,r or 8)},p) end
local function Stroke(col,th,p) return New("UIStroke",{Color=col,Thickness=th or 1,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},p) end
local function Pad(l,r,t,b,p) return New("UIPadding",{PaddingLeft=UDim.new(0,l or 0),PaddingRight=UDim.new(0,r or 0),PaddingTop=UDim.new(0,t or 0),PaddingBottom=UDim.new(0,b or 0)},p) end
local function List(sp,p) local x=New("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,sp or 4)},p); return x end
local function AutoCanvas(scroll, layout)
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+16)
    end)
end

-- Section header
local function Section(parent, title)
    local f=New("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,30)},parent)
    New("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,2,0,10),Size=UDim2.new(1,-4,0,14),
        Font=Enum.Font.GothamBold,Text=title:upper(),TextColor3=C.Accent,TextSize=10,
        TextXAlignment=Enum.TextXAlignment.Left},f)
    New("Frame",{BackgroundColor3=C.Sep,BorderSizePixel=0,Position=UDim2.new(0,0,1,-1),Size=UDim2.new(1,0,0,1)},f)
    return f
end

local function Spacer(p, h) return New("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,h or 6)},p) end

-- Toggle component
local function MkToggle(parent, title, sub, val, cb)
    local rowH = sub and 56 or 46
    local row = New("Frame",{BackgroundColor3=C.Bg3,BorderSizePixel=0,Size=UDim2.new(1,0,0,rowH)},parent)
    Corner(10,row)
    New("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,14,0,sub and 8 or 0),
        Size=UDim2.new(1,-78,0,22),Font=Enum.Font.Gotham,Text=title,TextColor3=C.TextPrim,
        TextSize=13,TextXAlignment=Enum.TextXAlignment.Left},row)
    if sub then
        New("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,14,0,30),
            Size=UDim2.new(1,-78,0,16),Font=Enum.Font.Gotham,Text=sub,TextColor3=C.TextMuted,
            TextSize=10,TextXAlignment=Enum.TextXAlignment.Left},row)
    end
    local track=New("Frame",{BackgroundColor3=val and C.TogOn or C.TogOff,BorderSizePixel=0,
        Position=UDim2.new(1,-60,0.5,-12),Size=UDim2.new(0,46,0,24)},row)
    Corner(99,track)
    local thumb=New("Frame",{BackgroundColor3=C.TextPrim,BorderSizePixel=0,
        Position=val and UDim2.new(1,-22,0.5,-10) or UDim2.new(0,2,0.5,-10),
        Size=UDim2.new(0,20,0,20)},track)
    Corner(99,thumb)
    local btn=New("TextButton",{BackgroundTransparency=1,Size=UDim2.new(1,0,1,0),Text="",ZIndex=6},row)
    local function SetV(v)
        val=v
        Tween(track,AI_FAST,{BackgroundColor3=v and C.TogOn or C.TogOff})
        Tween(thumb,AI_FAST,{Position=v and UDim2.new(1,-22,0.5,-10) or UDim2.new(0,2,0.5,-10)})
    end
    btn.MouseButton1Click:Connect(function()
        SetV(not val)
        Tween(row,AI_FAST,{BackgroundColor3=C.Bg4})
        task.delay(0.1,function() Tween(row,AI_FAST,{BackgroundColor3=C.Bg3}) end)
        if cb then Safe(cb,val) end
    end)
    btn.MouseEnter:Connect(function() Tween(row,AI_FAST,{BackgroundColor3=C.Bg4}) end)
    btn.MouseLeave:Connect(function() Tween(row,AI_FAST,{BackgroundColor3=C.Bg3}) end)
    return row, function(v) SetV(v) end
end

-- Slider component
local function MkSlider(parent, title, min, max, def, cb, suffix)
    suffix=suffix or ""
    local cur=def
    local row=New("Frame",{BackgroundColor3=C.Bg3,BorderSizePixel=0,Size=UDim2.new(1,0,0,68)},parent)
    Corner(10,row)
    New("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,14,0,8),Size=UDim2.new(0.65,0,0,22),
        Font=Enum.Font.Gotham,Text=title,TextColor3=C.TextPrim,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left},row)
    local vbg=New("Frame",{BackgroundColor3=C.Bg0,BorderSizePixel=0,Position=UDim2.new(1,-64,0,8),Size=UDim2.new(0,52,0,22)},row)
    Corner(7,vbg)
    local vLbl=New("TextLabel",{BackgroundTransparency=1,Size=UDim2.new(1,0,1,0),Font=Enum.Font.GothamBold,
        Text=tostring(def)..suffix,TextColor3=C.Accent,TextSize=12},vbg)
    local trBg=New("Frame",{BackgroundColor3=Color3.fromRGB(28,28,44),BorderSizePixel=0,
        Position=UDim2.new(0,14,0,46),Size=UDim2.new(1,-28,0,6)},row)
    Corner(99,trBg)
    local pct=(cur-min)/(max-min)
    local fill=New("Frame",{BackgroundColor3=C.Accent,BorderSizePixel=0,Size=UDim2.new(pct,0,1,0)},trBg)
    Corner(99,fill)
    local knob=New("Frame",{BackgroundColor3=C.TextPrim,BorderSizePixel=0,
        Position=UDim2.new(pct,-9,0.5,-9),Size=UDim2.new(0,18,0,18),ZIndex=4},trBg)
    Corner(99,knob)
    Stroke(C.Sep,1.5,knob)
    local dragging=false
    local function UpdateAt(x)
        local ap=trBg.AbsolutePosition.X; local as=trBg.AbsoluteSize.X
        local r=math.clamp((x-ap)/as,0,1)
        cur=math.floor(min+(max-min)*r)
        fill.Size=UDim2.new(r,0,1,0); knob.Position=UDim2.new(r,-9,0.5,-9)
        vLbl.Text=tostring(cur)..suffix
        if cb then Safe(cb,cur) end
    end
    trBg.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=true; UpdateAt(i.Position.X) end end)
    local c1=MainJ:Add(UIS.InputChanged:Connect(function(i) if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then UpdateAt(i.Position.X) end end),"Disconnect")
    local c2=MainJ:Add(UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end),"Disconnect")
    row.MouseEnter:Connect(function() Tween(row,AI_FAST,{BackgroundColor3=C.Bg4}) end)
    row.MouseLeave:Connect(function() Tween(row,AI_FAST,{BackgroundColor3=C.Bg3}) end)
    return row
end

-- Button component
local function MkButton(parent, title, sub, icon, accent, cb)
    local rowH=sub and 54 or 44
    local row=New("Frame",{BackgroundColor3=accent and C.AccentDim or C.Bg3,BorderSizePixel=0,Size=UDim2.new(1,0,0,rowH)},parent)
    Corner(10,row)
    if accent then Stroke(C.Accent,1,row) end
    if icon and icon~="" then
        New("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,12,0.5,-12),Size=UDim2.new(0,24,0,24),
            Font=Enum.Font.GothamBold,Text=icon,TextColor3=accent and C.AccentGlow or C.Accent,TextSize=18},row)
    end
    local tx=icon and icon~="" and 44 or 14
    New("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,tx,0,sub and 8 or 0),
        Size=UDim2.new(1,-(tx+14),0,22),Font=Enum.Font.Gotham,Text=title,TextColor3=C.TextPrim,
        TextSize=13,TextXAlignment=Enum.TextXAlignment.Left},row)
    if sub then
        New("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,tx,0,30),
            Size=UDim2.new(1,-(tx+14),0,16),Font=Enum.Font.Gotham,Text=sub,TextColor3=C.TextMuted,
            TextSize=10,TextXAlignment=Enum.TextXAlignment.Left},row)
    end
    New("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(1,-28,0,0),Size=UDim2.new(0,20,1,0),
        Font=Enum.Font.GothamBold,Text="›",TextColor3=C.TextMuted,TextSize=18},row)
    local btn=New("TextButton",{BackgroundTransparency=1,Size=UDim2.new(1,0,1,0),Text="",ZIndex=6},row)
    btn.MouseEnter:Connect(function() Tween(row,AI_FAST,{BackgroundColor3=accent and C.AccentDim or C.Bg4}) end)
    btn.MouseLeave:Connect(function() Tween(row,AI_FAST,{BackgroundColor3=accent and C.AccentDim or C.Bg3}) end)
    btn.MouseButton1Click:Connect(function()
        Tween(row,AI_FAST,{BackgroundColor3=C.Bg0})
        task.delay(0.12,function() Tween(row,AI_FAST,{BackgroundColor3=accent and C.AccentDim or C.Bg3}) end)
        if cb then Safe(cb) end
    end)
    return row
end

-- Picker/Dropdown
local function MkPicker(parent, title, opts, def, cb)
    local sel=def or opts[1] or ""
    local open=false
    local IH=30; local dropH=#opts*IH+8
    local container=New("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,46),ZIndex=8,ClipsDescendants=false},parent)
    local row=New("Frame",{BackgroundColor3=C.Bg3,BorderSizePixel=0,Size=UDim2.new(1,0,0,46),ZIndex=8},container)
    Corner(10,row)
    New("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,14,0,0),Size=UDim2.new(0.55,0,1,0),
        Font=Enum.Font.Gotham,Text=title,TextColor3=C.TextPrim,TextSize=13,
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=9},row)
    local selLbl=New("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0.55,0,0,0),
        Size=UDim2.new(0.45,-38,1,0),Font=Enum.Font.Gotham,Text=sel,TextColor3=C.TextSec,
        TextSize=12,TextXAlignment=Enum.TextXAlignment.Right,ZIndex=9},row)
    New("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(1,-34,0,0),Size=UDim2.new(0,24,1,0),
        Font=Enum.Font.GothamBold,Text="⌄",TextColor3=C.Accent,TextSize=18,ZIndex=9},row)
    local drop=New("Frame",{BackgroundColor3=C.Bg2,BorderSizePixel=0,Position=UDim2.new(0,0,0,48),
        Size=UDim2.new(1,0,0,dropH),Visible=false,ZIndex=20,ClipsDescendants=false},container)
    Corner(10,drop); Stroke(C.Sep,1,drop)
    List(0,drop); Pad(4,4,4,4,drop)
    for _,opt in ipairs(opts) do
        local isA=opt==sel
        local ob=New("TextButton",{BackgroundColor3=isA and C.AccentDim or Color3.new(0,0,0),
            BackgroundTransparency=isA and 0 or 1,BorderSizePixel=0,Size=UDim2.new(1,0,0,IH),
            Font=Enum.Font.Gotham,Text=opt,TextColor3=isA and C.AccentGlow or C.TextSec,
            TextSize=12,ZIndex=21},drop)
        Corner(7,ob)
        ob.MouseEnter:Connect(function() if opt~=sel then Tween(ob,AI_FAST,{BackgroundTransparency=0,BackgroundColor3=C.Bg4}) end end)
        ob.MouseLeave:Connect(function() if opt~=sel then Tween(ob,AI_FAST,{BackgroundTransparency=1}) end end)
        ob.MouseButton1Click:Connect(function()
            sel=opt; selLbl.Text=opt; open=false; drop.Visible=false
            container.Size=UDim2.new(1,0,0,46)
            if cb then Safe(cb,opt) end
        end)
    end
    local hbtn=New("TextButton",{BackgroundTransparency=1,Size=UDim2.new(1,0,1,0),Text="",ZIndex=10},row)
    hbtn.MouseEnter:Connect(function() Tween(row,AI_FAST,{BackgroundColor3=C.Bg4}) end)
    hbtn.MouseLeave:Connect(function() Tween(row,AI_FAST,{BackgroundColor3=C.Bg3}) end)
    hbtn.MouseButton1Click:Connect(function()
        open=not open; drop.Visible=open
        container.Size=UDim2.new(1,0,0,open and 46+dropH+6 or 46)
    end)
    return container
end

-- Input field
local function MkInput(parent, title, placeholder, cb)
    local row=New("Frame",{BackgroundColor3=C.Bg3,BorderSizePixel=0,Size=UDim2.new(1,0,0,62)},parent)
    Corner(10,row)
    New("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,14,0,8),Size=UDim2.new(1,-28,0,14),
        Font=Enum.Font.Gotham,Text=title,TextColor3=C.TextSec,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left},row)
    local bg=New("Frame",{BackgroundColor3=C.Bg0,BorderSizePixel=0,Position=UDim2.new(0,14,0,26),Size=UDim2.new(1,-28,0,26)},row)
    Corner(7,bg)
    local box=New("TextBox",{BackgroundTransparency=1,Size=UDim2.new(1,-12,1,0),Position=UDim2.new(0,6,0,0),
        Font=Enum.Font.Gotham,PlaceholderText=placeholder or "",PlaceholderColor3=C.TextMuted,
        Text="",TextColor3=C.TextPrim,TextSize=12,ClearTextOnFocus=false,
        TextXAlignment=Enum.TextXAlignment.Left},bg)
    box.Focused:Connect(function() Tween(bg,AI_FAST,{BackgroundColor3=C.Bg1}); Stroke(C.Accent,1,bg) end)
    box.FocusLost:Connect(function()
        Tween(bg,AI_FAST,{BackgroundColor3=C.Bg0})
        local s=bg:FindFirstChildOfClass("UIStroke"); if s then s:Destroy() end
        if cb then Safe(cb,box.Text) end
    end)
    row.MouseEnter:Connect(function() Tween(row,AI_FAST,{BackgroundColor3=C.Bg4}) end)
    row.MouseLeave:Connect(function() Tween(row,AI_FAST,{BackgroundColor3=C.Bg3}) end)
    return row, box
end

-- ══════════════════════════════════════════════
--  MAIN WINDOW
-- ══════════════════════════════════════════════
local W = CFG.WIN
local Win = New("Frame",{
    Name="KuraiWindow",BackgroundColor3=C.Bg1,BorderSizePixel=0,
    Position=UDim2.new(0,80,0,50),Size=UDim2.new(0,W.W,0,W.H),
    Active=true,Draggable=true,ClipsDescendants=false,
},SG)
Corner(14,Win)

-- Shadow
New("ImageLabel",{BackgroundTransparency=1,Position=UDim2.new(0,-28,0,-28),Size=UDim2.new(1,56,1,56),
    ZIndex=-1,Image="rbxassetid://5028857084",ImageColor3=C.Accent,ImageTransparency=0.7,
    ScaleType=Enum.ScaleType.Slice,SliceCenter=Rect.new(24,24,276,276)},Win)

-- Top accent line
local TopLine=New("Frame",{BackgroundColor3=C.Accent,BorderSizePixel=0,Position=UDim2.new(0,14,0,0),Size=UDim2.new(1,-28,0,2),ZIndex=10},Win)
Corner(2,TopLine)

-- ── HEADER ──────────────────────────────────
local Header=New("Frame",{BackgroundColor3=C.Bg2,BorderSizePixel=0,Position=UDim2.new(0,0,0,2),Size=UDim2.new(1,0,0,54)},Win)

-- Logo K
New("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,14,0,0),Size=UDim2.new(0,24,1,0),
    Font=Enum.Font.GothamBlack,Text="K",TextColor3=C.Accent,TextSize=24,
    TextXAlignment=Enum.TextXAlignment.Left},Header)
New("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,36,0,0),Size=UDim2.new(0,130,1,0),
    Font=Enum.Font.GothamBold,Text="uraiSoftware",TextColor3=C.TextPrim,TextSize=17,
    TextXAlignment=Enum.TextXAlignment.Left},Header)

-- Version badge
local vBg=New("Frame",{BackgroundColor3=C.AccentDim,BorderSizePixel=0,Position=UDim2.new(0,208,0.5,-11),Size=UDim2.new(0,46,0,22)},Header)
Corner(99,vBg)
New("TextLabel",{BackgroundTransparency=1,Size=UDim2.new(1,0,1,0),Font=Enum.Font.GothamBold,
    Text="v5.0",TextColor3=C.AccentGlow,TextSize=11},vBg)

-- Status indicator (live)
local statusDot=New("Frame",{BackgroundColor3=C.Success,BorderSizePixel=0,Position=UDim2.new(0,262,0.5,-5),Size=UDim2.new(0,10,0,10)},Header)
Corner(99,statusDot)
New("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,278,0,0),Size=UDim2.new(0,60,1,0),
    Font=Enum.Font.Gotham,Text="Active",TextColor3=C.Success,TextSize=11,
    TextXAlignment=Enum.TextXAlignment.Left},Header)

-- Close
local CloseBtn=New("TextButton",{BackgroundColor3=C.Accent,BorderSizePixel=0,
    Position=UDim2.new(1,-44,0.5,-14),Size=UDim2.new(0,28,0,28),
    Font=Enum.Font.GothamBold,Text="✕",TextColor3=C.TextPrim,TextSize=13},Header)
Corner(8,CloseBtn)
CloseBtn.MouseEnter:Connect(function() Tween(CloseBtn,AI_FAST,{BackgroundColor3=C.AccentGlow}) end)
CloseBtn.MouseLeave:Connect(function() Tween(CloseBtn,AI_FAST,{BackgroundColor3=C.Accent}) end)
CloseBtn.MouseButton1Click:Connect(function()
    Tween(Win,AI_MED,{Size=UDim2.new(0,W.W,0,0)})
    task.delay(0.28,function() Win.Visible=false; Win.Size=UDim2.new(0,W.W,0,W.H); STATE.MenuOpen=false end)
end)

-- Minimize
local MinBtn=New("TextButton",{BackgroundColor3=C.Bg3,BorderSizePixel=0,
    Position=UDim2.new(1,-78,0.5,-14),Size=UDim2.new(0,28,0,28),
    Font=Enum.Font.GothamBold,Text="—",TextColor3=C.TextSec,TextSize=13},Header)
Corner(8,MinBtn)
local _minimized=false
MinBtn.MouseEnter:Connect(function() Tween(MinBtn,AI_FAST,{BackgroundColor3=C.Bg4}) end)
MinBtn.MouseLeave:Connect(function() Tween(MinBtn,AI_FAST,{BackgroundColor3=C.Bg3}) end)
MinBtn.MouseButton1Click:Connect(function()
    _minimized=not _minimized
    Tween(Win,AI_MED,{Size=_minimized and UDim2.new(0,W.W,0,56) or UDim2.new(0,W.W,0,W.H)})
end)

-- Header separator
New("Frame",{BackgroundColor3=C.Sep,BorderSizePixel=0,Position=UDim2.new(0,0,1,-1),Size=UDim2.new(1,0,0,1)},Header)

-- ── SIDEBAR ─────────────────────────────────
local Sidebar=New("Frame",{BackgroundColor3=C.Bg2,BorderSizePixel=0,
    Position=UDim2.new(0,0,0,56),Size=UDim2.new(0,W.SideW,1,-56)},Win)
New("Frame",{BackgroundColor3=C.Sep,BorderSizePixel=0,Position=UDim2.new(1,-1,0,0),Size=UDim2.new(0,1,1,0)},Sidebar)

local TabScroll=New("ScrollingFrame",{BackgroundTransparency=1,BorderSizePixel=0,
    Position=UDim2.new(0,0,0,8),Size=UDim2.new(1,0,1,-76),
    ScrollBarThickness=0,ScrollingDirection=Enum.ScrollingDirection.Y,CanvasSize=UDim2.new(0,0,0,0)},Sidebar)
local TabLayout=List(2,TabScroll)
Pad(6,6,0,0,TabScroll)
AutoCanvas(TabScroll,TabLayout)

-- User card
New("Frame",{BackgroundColor3=C.Sep,BorderSizePixel=0,Position=UDim2.new(0,8,1,-72),Size=UDim2.new(1,-16,0,1)},Sidebar)
local UserBox=New("Frame",{BackgroundColor3=C.Bg0,BorderSizePixel=0,Position=UDim2.new(0,8,1,-66),Size=UDim2.new(1,-16,0,58)},Sidebar)
Corner(10,UserBox)
local avatarBg=New("Frame",{BackgroundColor3=C.AccentDim,BorderSizePixel=0,Position=UDim2.new(0,8,0.5,-16),Size=UDim2.new(0,32,0,32)},UserBox)
Corner(99,avatarBg)
New("ImageLabel",{BackgroundTransparency=1,Size=UDim2.new(1,0,1,0),
    Image="https://www.roblox.com/headshot-thumbnail/image?userId="..LP.UserId.."&width=48&height=48&format=png",
    ScaleType=Enum.ScaleType.Fit},avatarBg)
Corner(99,avatarBg)
New("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,48,0,9),Size=UDim2.new(1,-56,0,18),
    Font=Enum.Font.GothamBold,Text=LP.DisplayName,TextColor3=C.TextPrim,TextSize=12,
    TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},UserBox)
New("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,48,0,29),Size=UDim2.new(1,-56,0,14),
    Font=Enum.Font.Gotham,Text="@"..LP.Name,TextColor3=C.TextMuted,TextSize=10,
    TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd},UserBox)

-- ── CONTENT AREA ────────────────────────────
local ContentArea=New("Frame",{BackgroundColor3=C.Bg1,BorderSizePixel=0,
    Position=UDim2.new(0,W.SideW,0,56),Size=UDim2.new(1,-W.SideW,1,-56),ClipsDescendants=true},Win)

local ContentTitleLbl=New("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,16,0,0),
    Size=UDim2.new(1,-32,0,44),Font=Enum.Font.GothamBold,Text="Dashboard",
    TextColor3=C.TextPrim,TextSize=17,TextXAlignment=Enum.TextXAlignment.Left},ContentArea)
New("Frame",{BackgroundColor3=C.Sep,BorderSizePixel=0,Position=UDim2.new(0,0,0,43),Size=UDim2.new(1,0,0,1)},ContentArea)

local ContentScroll=New("ScrollingFrame",{BackgroundTransparency=1,BorderSizePixel=0,
    Position=UDim2.new(0,0,0,44),Size=UDim2.new(1,0,1,-44),
    ScrollBarThickness=3,ScrollBarImageColor3=C.Accent,
    CanvasSize=UDim2.new(0,0,0,0),ScrollingDirection=Enum.ScrollingDirection.Y},ContentArea)
local ContentList=List(4,ContentScroll)
Pad(12,12,8,14,ContentScroll)
AutoCanvas(ContentScroll,ContentList)

-- ── TABS ────────────────────────────────────
local Pages   = {}
local TabBtns = {}

local TABS = {
    {n="Dashboard",  ic="⬛"},
    {n="ESP",        ic="👁"},
    {n="CamLock",    ic="🔒"},
    {n="Combat",     ic="⚔"},
    {n="Target",     ic="🎯"},
    {n="Roles",      ic="🎭"},
    {n="Player",     ic="🏃"},
    {n="Crosshair",  ic="✛"},
    {n="Misc",       ic="🔧"},
    {n="Graphics",   ic="🖥"},
    {n="Skybox",     ic="🌌"},
    {n="Keybinds",   ic="⌨"},
    {n="Webhook",    ic="📡"},
    {n="Settings",   ic="⚙"},
}

local function SwitchTab(name)
    STATE.ActiveTab   = name
    ContentTitleLbl.Text = name

    -- Animate page swap
    for n, pg in pairs(Pages) do
        if n == name then
            pg.Visible = true
            pg.BackgroundTransparency = 1
            Tween(pg, AI_FAST, {BackgroundTransparency = 0})
        else
            pg.Visible = false
        end
    end

    for n, btn in pairs(TabBtns) do
        local active = (n == name)
        local ind = btn:FindFirstChild("Ind")
        if ind then ind.Visible = active end
        local lbl = btn:FindFirstChildOfClass("TextLabel")
        if lbl then
            lbl.TextColor3 = active and C.TextPrim or C.TextSec
            lbl.Font = active and Enum.Font.GothamBold or Enum.Font.Gotham
        end
        Tween(btn, AI_FAST, {
            BackgroundColor3     = active and C.Bg4 or C.Bg2,
            BackgroundTransparency = active and 0 or 1,
        })
    end

    ContentScroll.CanvasPosition = Vector2.zero
end

for i, tab in ipairs(TABS) do
    local btn = New("TextButton",{
        Name="Tab_"..tab.n,BackgroundColor3=tab.n=="Dashboard" and C.Bg4 or C.Bg2,
        BackgroundTransparency=tab.n=="Dashboard" and 0 or 1,BorderSizePixel=0,
        Size=UDim2.new(1,0,0,36),Text="",LayoutOrder=i},TabScroll)
    Corner(9,btn)

    local ind=New("Frame",{Name="Ind",BackgroundColor3=C.Accent,BorderSizePixel=0,
        Position=UDim2.new(0,0,0.2,0),Size=UDim2.new(0,3,0.6,0),Visible=tab.n=="Dashboard"},btn)
    Corner(99,ind)

    New("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,12,0,0),Size=UDim2.new(1,-14,1,0),
        Font=tab.n=="Dashboard" and Enum.Font.GothamBold or Enum.Font.Gotham,
        Text=tab.ic.."  "..tab.n,
        TextColor3=tab.n=="Dashboard" and C.TextPrim or C.TextSec,TextSize=13,
        TextXAlignment=Enum.TextXAlignment.Left},btn)

    TabBtns[tab.n]=btn

    -- Page
    local page=New("Frame",{Name="Page_"..tab.n,BackgroundTransparency=0,BorderSizePixel=0,
        Size=UDim2.new(1,0,0,0),Visible=tab.n=="Dashboard"},ContentScroll)
    local pl=List(4,page)
    pl:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.Size=UDim2.new(1,0,0,pl.AbsoluteContentSize.Y)
    end)
    Pages[tab.n]=page

    btn.MouseButton1Click:Connect(function() SwitchTab(tab.n) end)
    btn.MouseEnter:Connect(function()
        if STATE.ActiveTab~=tab.n then Tween(btn,AI_FAST,{BackgroundTransparency=0,BackgroundColor3=C.Bg3}) end
    end)
    btn.MouseLeave:Connect(function()
        if STATE.ActiveTab~=tab.n then Tween(btn,AI_FAST,{BackgroundTransparency=1}) end
    end)
end

-- ══════════════════════════════════════════════
--  DRAWING SYSTEM
-- ══════════════════════════════════════════════
local DrawStore = {}
local function NewDraw(t, props)
    local d=Drawing.new(t)
    for k,v in pairs(props or {}) do pcall(function() d[k]=v end) end
    table.insert(DrawStore, d)
    return d
end
local function CleanAllDraws()
    for _,d in ipairs(DrawStore) do pcall(function() d:Remove() end) end
    DrawStore={}
end

local FovCircle = NewDraw("Circle",{Visible=false,Thickness=1.5,Color=C.TextPrim,Filled=false,Transparency=0.4,NumSides=64})

local CH = {
    Dot    = NewDraw("Circle",{Visible=false,Filled=true,Thickness=1,NumSides=32}),
    Top    = NewDraw("Line",  {Visible=false,Thickness=1.5}),
    Bottom = NewDraw("Line",  {Visible=false,Thickness=1.5}),
    Left   = NewDraw("Line",  {Visible=false,Thickness=1.5}),
    Right  = NewDraw("Line",  {Visible=false,Thickness=1.5}),
    Circle = NewDraw("Circle",{Visible=false,Filled=false,Thickness=1.5,NumSides=48}),
}

-- ══════════════════════════════════════════════
--  ESP STORE
-- ══════════════════════════════════════════════
local ESPStore = {}
local function ESPMake(p)
    if ESPStore[p] then
        for _,d in pairs(ESPStore[p]) do pcall(function() d:Remove() end) end
    end
    ESPStore[p]={
        TL=NewDraw("Line",{Visible=false,Thickness=2}), TR=NewDraw("Line",{Visible=false,Thickness=2}),
        BL=NewDraw("Line",{Visible=false,Thickness=2}), BR=NewDraw("Line",{Visible=false,Thickness=2}),
        LT=NewDraw("Line",{Visible=false,Thickness=2}), RT=NewDraw("Line",{Visible=false,Thickness=2}),
        LB=NewDraw("Line",{Visible=false,Thickness=2}), RB=NewDraw("Line",{Visible=false,Thickness=2}),
        Name   = NewDraw("Text",  {Visible=false,Size=14,Center=true,Outline=true,Font=Drawing.Fonts.Plex}),
        Role   = NewDraw("Text",  {Visible=false,Size=11,Center=true,Outline=true,Font=Drawing.Fonts.Plex}),
        Dist   = NewDraw("Text",  {Visible=false,Size=11,Center=true,Outline=true,Font=Drawing.Fonts.Plex}),
        HpBg   = NewDraw("Square",{Visible=false,Filled=true,Color=Color3.fromRGB(0,0,0),Transparency=0.3}),
        HpFill = NewDraw("Square",{Visible=false,Filled=true}),
        Tracer = NewDraw("Line",  {Visible=false,Thickness=1,Transparency=0.6}),
    }
end
local function ESPClear(p)
    if ESPStore[p] then
        for _,d in pairs(ESPStore[p]) do pcall(function() d:Remove() end) end
        ESPStore[p]=nil
    end
end
local function ESPHide(esp)
    for _,d in pairs(esp) do d.Visible=false end
end

for _,p in ipairs(Players:GetPlayers()) do if p~=LP then ESPMake(p) end end
MainJ:Add(Players.PlayerAdded:Connect(function(p) task.wait(0.4); if p~=LP then ESPMake(p) end end),"Disconnect")
MainJ:Add(Players.PlayerRemoving:Connect(ESPClear),"Disconnect")

-- ══════════════════════════════════════════════
--  PAGE: DASHBOARD
-- ══════════════════════════════════════════════
do
    local p = Pages["Dashboard"]

    -- Live stats grid
    local statsGrid=New("Frame",{BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.new(1,0,0,160)},p)
    New("UIGridLayout",{SortOrder=Enum.SortOrder.LayoutOrder,CellSize=UDim2.new(0.5,-4,0,74),
        CellPaddingHorizontal=UDim.new(0,4),CellPaddingVertical=UDim.new(0,4)},statsGrid)

    local function StatCard(parent, icon, label, color, lo)
        local card=New("Frame",{BackgroundColor3=C.Bg3,BorderSizePixel=0,LayoutOrder=lo},parent)
        Corner(10,card)
        local ib=New("Frame",{BackgroundColor3=color,BorderSizePixel=0,BackgroundTransparency=0.8,
            Position=UDim2.new(0,10,0,10),Size=UDim2.new(0,30,0,30)},card)
        Corner(8,ib)
        New("TextLabel",{BackgroundTransparency=1,Size=UDim2.new(1,0,1,0),
            Font=Enum.Font.GothamBold,Text=icon,TextColor3=color,TextSize=16},ib)
        local vL=New("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,48,0,8),
            Size=UDim2.new(1,-58,0,24),Font=Enum.Font.GothamBold,Text="—",TextColor3=C.TextPrim,
            TextSize=18,TextXAlignment=Enum.TextXAlignment.Left},card)
        New("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,48,0,34),
            Size=UDim2.new(1,-58,0,14),Font=Enum.Font.Gotham,Text=label,TextColor3=C.TextMuted,
            TextSize=10,TextXAlignment=Enum.TextXAlignment.Left},card)
        return card, vL
    end

    local _, fpsLbl    = StatCard(statsGrid,"⚡","FPS",C.Success,1)
    local _, pingLbl   = StatCard(statsGrid,"📡","Ping",C.Info,2)
    local _, hpLbl     = StatCard(statsGrid,"❤","Health",C.Error,3)
    local _, speedLbl  = StatCard(statsGrid,"🏃","Speed",C.Warning,4)

    Spacer(p, 4)
    Section(p, "Mon Rôle")
    local roleCard=New("Frame",{BackgroundColor3=C.Bg3,BorderSizePixel=0,Size=UDim2.new(1,0,0,66)},p)
    Corner(10,roleCard)
    local roleDot=New("Frame",{BackgroundColor3=C.Unknown,BorderSizePixel=0,Position=UDim2.new(0,14,0.5,-20),Size=UDim2.new(0,40,0,40)},roleCard)
    Corner(99,roleDot)
    local roleIcon=New("TextLabel",{BackgroundTransparency=1,Size=UDim2.new(1,0,1,0),Font=Enum.Font.GothamBold,Text="❓",TextSize=22},roleDot)
    local roleNameLbl=New("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,64,0,10),Size=UDim2.new(1,-78,0,22),
        Font=Enum.Font.GothamBold,Text="UNKNOWN",TextColor3=C.TextMuted,TextSize=18,TextXAlignment=Enum.TextXAlignment.Left},roleCard)
    local roleSubLbl=New("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,64,0,32),Size=UDim2.new(1,-78,0,14),
        Font=Enum.Font.Gotham,Text="En attente du serveur...",TextColor3=C.TextMuted,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left},roleCard)

    Spacer(p, 4)
    Section(p, "Modules Rapides")
    local modGrid=New("Frame",{BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.new(1,0,0,80)},p)
    New("UIGridLayout",{SortOrder=Enum.SortOrder.LayoutOrder,CellSize=UDim2.new(0.5,-4,0,36),
        CellPaddingHorizontal=UDim.new(0,4),CellPaddingVertical=UDim.new(0,4)},modGrid)

    local modDefs={
        {name="ESP",     icon="👁",  cfg=CFG.ESP,     key="Enabled"},
        {name="CamLock", icon="🔒", cfg=CFG.CAMLOCK,  key="Enabled"},
        {name="Crosshair",icon="✛",  cfg=CFG.CROSSHAIR,key="Enabled"},
        {name="Fly",     icon="🚀", cfg=CFG.PLAYER,   key="FlyEnabled"},
    }
    local modToggles={}
    for i, md in ipairs(modDefs) do
        local mb=New("TextButton",{BackgroundColor3=md.cfg[md.key] and C.AccentDim or C.Bg3,
            BorderSizePixel=0,LayoutOrder=i,Text=""},modGrid)
        Corner(8,mb)
        if md.cfg[md.key] then Stroke(C.Accent,1,mb) end
        New("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,8,0,0),Size=UDim2.new(1,-8,1,0),
            Font=Enum.Font.Gotham,Text=md.icon.." "..md.name,
            TextColor3=md.cfg[md.key] and C.AccentGlow or C.TextSec,TextSize=12,
            TextXAlignment=Enum.TextXAlignment.Left},mb)
        modToggles[md.name]={btn=mb, md=md}
        mb.MouseButton1Click:Connect(function()
            md.cfg[md.key]=not md.cfg[md.key]
            local on=md.cfg[md.key]
            Tween(mb,AI_FAST,{BackgroundColor3=on and C.AccentDim or C.Bg3})
            local lbl=mb:FindFirstChildOfClass("TextLabel")
            if lbl then lbl.TextColor3=on and C.AccentGlow or C.TextSec end
            local st=mb:FindFirstChildOfClass("UIStroke")
            if on and not st then Stroke(C.Accent,1,mb)
            elseif not on and st then st:Destroy() end
            Notify(md.name, on and "Activé" or "Désactivé", on and "success" or "info")
        end)
    end

    Spacer(p, 4)
    Section(p, "Joueurs en Ligne")
    local playerList=New("Frame",{BackgroundColor3=C.Bg3,BorderSizePixel=0,Size=UDim2.new(1,0,0,40)},p)
    Corner(10,playerList)
    local plLayout=List(0,playerList)
    Pad(8,8,6,6,playerList)
    local plCount=New("TextLabel",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,28),
        Font=Enum.Font.Gotham,Text="Chargement...",TextColor3=C.TextSec,TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left},playerList)

    -- Live dashboard updater
    local dashT = 0
    MainJ:Add(RunService.Heartbeat:Connect(function(dt)
        dashT = dashT + dt
        if dashT < 0.5 then return end
        dashT = 0
        if STATE.ActiveTab ~= "Dashboard" then return end

        -- FPS
        STATE.FPS_t = STATE.FPS_t + dt
        if STATE.FPS_t > 0 then
            STATE.FPS = math.floor(1/dt)
            STATE.FPS_t = 0
        end
        fpsLbl.Text = tostring(STATE.FPS)
        fpsLbl.TextColor3 = STATE.FPS >= 55 and C.Success or STATE.FPS >= 30 and C.Warning or C.Error

        -- Ping
        pcall(function()
            local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
            pingLbl.Text = ping.."ms"
            pingLbl.TextColor3 = ping<80 and C.Success or ping<150 and C.Warning or C.Error
        end)

        -- Health
        local h=GetHum()
        if h then
            hpLbl.Text = math.floor(h.Health).."/"..math.floor(h.MaxHealth)
            hpLbl.TextColor3 = Color3.fromRGB(math.floor(255*(1-h.Health/h.MaxHealth)),math.floor(255*h.Health/h.MaxHealth),0)
        end

        -- Speed
        local spd = h and h.WalkSpeed or 16
        speedLbl.Text = tostring(math.floor(spd))

        -- Role
        local myRole = Roles:GetRole(LP)
        local roleCol = Roles:GetColor(LP)
        roleNameLbl.Text = myRole:upper()
        roleNameLbl.TextColor3 = roleCol
        roleDot.BackgroundColor3 = roleCol
        roleIcon.Text = Roles:GetIcon(LP)
        roleSubLbl.Text = "Rôle détecté par scan local"

        -- Players
        local count = #Players:GetPlayers()
        plCount.Text = count.." joueur(s) connecté(s)"
        playerList.Size = UDim2.new(1,0,0,28+12)
    end),"Disconnect")
end

-- ══════════════════════════════════════════════
--  PAGE: ESP
-- ══════════════════════════════════════════════
do
    local p=Pages["ESP"]
    Section(p,"Activation")
    MkToggle(p,"ESP Global","Affiche les joueurs à travers les murs",CFG.ESP.Enabled,function(v)
        CFG.ESP.Enabled=v
        if not v then for _,esp in pairs(ESPStore) do ESPHide(esp) end end
        Notify("ESP",v and "Activé" or "Désactivé",v and "success" or "info")
    end)
    Spacer(p,4); Section(p,"Éléments")
    MkToggle(p,"Corner Box",nil,CFG.ESP.Box,    function(v) CFG.ESP.Box=v end)
    MkToggle(p,"Noms",      nil,CFG.ESP.Names,  function(v) CFG.ESP.Names=v end)
    MkToggle(p,"Distance",  nil,CFG.ESP.Distance,function(v) CFG.ESP.Distance=v end)
    MkToggle(p,"Barre Vie", nil,CFG.ESP.Health, function(v) CFG.ESP.Health=v end)
    MkToggle(p,"Tracer",    nil,CFG.ESP.Tracer, function(v) CFG.ESP.Tracer=v end)
    MkToggle(p,"Rôle Label",nil,CFG.ESP.Roles,  function(v) CFG.ESP.Roles=v end)
    Spacer(p,4); Section(p,"Filtre Rôle")
    MkToggle(p,"Murderer", nil,CFG.ESP.ShowMurder,  function(v) CFG.ESP.ShowMurder=v end)
    MkToggle(p,"Sheriff",  nil,CFG.ESP.ShowSheriff, function(v) CFG.ESP.ShowSheriff=v end)
    MkToggle(p,"Innocent", nil,CFG.ESP.ShowInnocent,function(v) CFG.ESP.ShowInnocent=v end)
    Spacer(p,4); Section(p,"Distance")
    MkSlider(p,"Distance Max",50,2000,CFG.ESP.MaxDist,function(v) CFG.ESP.MaxDist=v end,"m")
end

-- ══════════════════════════════════════════════
--  PAGE: CAMLOCK
-- ══════════════════════════════════════════════
do
    local p=Pages["CamLock"]
    Section(p,"Camera Lock")
    MkToggle(p,"CamLock","Verrouille la caméra sur le joueur le plus proche",CFG.CAMLOCK.Enabled,function(v)
        CFG.CAMLOCK.Enabled=v; Notify("CamLock",v and "ON" or "OFF",v and "success" or "info")
    end)
    MkToggle(p,"Silent Aim","Redirige les tirs silencieusement",CFG.CAMLOCK.SilentAim,function(v)
        CFG.CAMLOCK.SilentAim=v; Notify("Silent Aim",v and "ON" or "OFF",v and "success" or "info")
    end)
    MkToggle(p,"Cercle FOV",nil,CFG.CAMLOCK.ShowFOV,function(v) CFG.CAMLOCK.ShowFOV=v end)
    Spacer(p,4); Section(p,"Cible")
    MkPicker(p,"Partie du Corps",{"Head","HumanoidRootPart","UpperTorso"},"Head",function(v) CFG.CAMLOCK.Part=v end)
    MkPicker(p,"Silent Aim Part",{"Head","HumanoidRootPart","UpperTorso"},"Head",function(v) CFG.CAMLOCK.SAimPart=v end)
    Spacer(p,4); Section(p,"Paramètres")
    MkSlider(p,"FOV Rayon",10,600,CFG.CAMLOCK.FOV,function(v) CFG.CAMLOCK.FOV=v; FovCircle.Radius=v end,"px")
    MkSlider(p,"Smooth (×100)",1,40,math.floor(CFG.CAMLOCK.Smooth*100),function(v) CFG.CAMLOCK.Smooth=v/100 end)
end

-- ══════════════════════════════════════════════
--  PAGE: COMBAT
-- ══════════════════════════════════════════════
do
    local p=Pages["Combat"]
    Section(p,"Auto Farm")
    MkToggle(p,"Auto Farm","Téléporte vers les pièces",CFG.COMBAT.AutoFarm,function(v)
        CFG.COMBAT.AutoFarm=v; Notify("Auto Farm",v and "ON" or "OFF",v and "success" or "info")
    end)
    MkPicker(p,"Mode Ferme",{"Nearest","Nearest + XP","Randomize"},"Nearest",function(v) CFG.COMBAT.FarmMode=v end)
    Spacer(p,4); Section(p,"Combat Outils")
    MkToggle(p,"Auto Grab Gun","Ramasse le gun automatiquement",false,function(v) CFG.COMBAT.AutoGrabGun=v end)
    MkButton(p,"Fling Murderer","Envoie le murderer voler",nil,false,function()
        local m=Roles:GetMurder()
        if not m then Notify("Fling","Aucun murderer détecté","warning"); return end
        local hr=m.Character and m.Character:FindFirstChild("HumanoidRootPart")
        if hr then
            local bv=Instance.new("BodyVelocity"); bv.Velocity=Vector3.new(0,600,0)
            bv.MaxForce=Vector3.new(1e9,1e9,1e9); bv.Parent=hr; Debris:AddItem(bv,0.15)
            Notify("Fling","Murderer flingué ✓","success")
        end
    end)
    MkButton(p,"Fling Sheriff","Envoie le sheriff voler",nil,false,function()
        local s=Roles:GetSheriff()
        if not s then Notify("Fling","Aucun sheriff détecté","warning"); return end
        local hr=s.Character and s.Character:FindFirstChild("HumanoidRootPart")
        if hr then
            local bv=Instance.new("BodyVelocity"); bv.Velocity=Vector3.new(0,600,0)
            bv.MaxForce=Vector3.new(1e9,1e9,1e9); bv.Parent=hr; Debris:AddItem(bv,0.15)
            Notify("Fling","Sheriff flingué ✓","success")
        end
    end)
    MkButton(p,"Kill Aura — Fling Tous","Fling tous les joueurs","⚡",true,function()
        for _,pl in ipairs(Players:GetPlayers()) do
            if pl==LP then continue end
            local hr=pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
            if hr then
                local bv=Instance.new("BodyVelocity")
                bv.Velocity=Vector3.new(math.random(-300,300),500,math.random(-300,300))
                bv.MaxForce=Vector3.new(1e9,1e9,1e9); bv.Parent=hr; Debris:AddItem(bv,0.2)
            end
        end
        Notify("Kill Aura","Fling all ✓","success")
    end)
end

-- ══════════════════════════════════════════════
--  PAGE: TARGET
-- ══════════════════════════════════════════════
do
    local p=Pages["Target"]
    Section(p,"Sélection")
    local plist={"Aucun"}
    for _,pl in ipairs(Players:GetPlayers()) do if pl~=LP then table.insert(plist,pl.Name) end end
    MkPicker(p,"Target",plist,"Aucun",function(v)
        STATE.TargetPlayer=v=="Aucun" and nil or Players:FindFirstChild(v)
        Notify("Target",v=="Aucun" and "Désélectionné" or "→ "..v)
    end)
    Spacer(p,4); Section(p,"Actions")
    MkToggle(p,"Loop Goto Target","Suit le target en continu",false,function(v) STATE.LoopGoto=v end)
    MkToggle(p,"Fling Target",nil,false,function(v) STATE.FlingTarget=v end)
    Spacer(p,4)
    MkButton(p,"Téléport vers Target","Teleporte instantanément","›",false,function()
        local root=GetRoot(); local tp=STATE.TargetPlayer
        if not tp then Notify("Target","Aucun target sélectionné","warning"); return end
        local tr=tp.Character and tp.Character:FindFirstChild("HumanoidRootPart")
        if root and tr then root.CFrame=tr.CFrame+Vector3.new(2,2,0); Notify("Téléport","→ "..tp.Name,"success") end
    end)
    MkButton(p,"Spectate Target","Observe la perspective du target","👁",false,function()
        local tp=STATE.TargetPlayer
        if not tp then Notify("Spectate","Aucun target","warning"); return end
        local char=tp.Character
        if char then Cam.CameraSubject=char:FindFirstChildOfClass("Humanoid") or char:FindFirstChild("HumanoidRootPart")
            Notify("Spectate","Observation: "..tp.Name,"info")
        end
    end)
    MkButton(p,"Reset Camera","Revient à son propre personnage","↺",false,function()
        local hum=GetHum(); if hum then Cam.CameraSubject=hum; Notify("Camera","Reset ✓","success") end
    end)
end

-- ══════════════════════════════════════════════
--  PAGE: ROLES
-- ══════════════════════════════════════════════
do
    local p=Pages["Roles"]
    Section(p,"Détection")
    MkButton(p,"Scanner Rôles","Force un scan complet","🔍",false,function()
        Roles:Invalidate(); Roles:Scan()
        local m=Roles:GetMurder(); local s=Roles:GetSheriff()
        Notify("Rôles","Murder: "..(m and m.Name or "?").." | Sheriff: "..(s and s.Name or "?"),nil,6)
    end)
    Spacer(p,4); Section(p,"Joueurs")
    local rlist=New("Frame",{BackgroundColor3=C.Bg3,BorderSizePixel=0,Size=UDim2.new(1,0,0,200)},p)
    Corner(10,rlist)
    local rl=List(0,rlist); Pad(8,8,6,6,rlist)
    local function RefreshRoleList()
        for _,ch in ipairs(rlist:GetChildren()) do
            if ch:IsA("TextLabel") or ch:IsA("Frame") then ch:Destroy() end
        end
        Roles:Invalidate(); Roles:Scan()
        local all=Roles:GetAll()
        local h=0
        for _, pl in ipairs(Players:GetPlayers()) do
            local row=New("Frame",{BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.new(1,0,0,32)},rlist)
            local rolCol=Roles:GetColor(pl)
            local dot2=New("Frame",{BackgroundColor3=rolCol,BorderSizePixel=0,Position=UDim2.new(0,0,0.5,-5),Size=UDim2.new(0,10,0,10)},row)
            Corner(99,dot2)
            New("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0,18,0,0),Size=UDim2.new(0.5,0,1,0),
                Font=Enum.Font.Gotham,Text=pl.Name,TextColor3=C.TextPrim,TextSize=12,
                TextXAlignment=Enum.TextXAlignment.Left},row)
            New("TextLabel",{BackgroundTransparency=1,Position=UDim2.new(0.5,0,0,0),Size=UDim2.new(0.5,0,1,0),
                Font=Enum.Font.GothamBold,Text=Roles:GetLabel(pl),TextColor3=rolCol,TextSize=11,
                TextXAlignment=Enum.TextXAlignment.Right},row)
            h=h+32
        end
        rlist.Size=UDim2.new(1,0,0,math.max(40,h+12))
    end
    MkButton(p,"Actualiser la Liste","Met à jour la liste des rôles","↺",false,RefreshRoleList)
    task.spawn(RefreshRoleList)
end

-- ══════════════════════════════════════════════
--  PAGE: PLAYER
-- ══════════════════════════════════════════════
do
    local p=Pages["Player"]
    Section(p,"Vitesse & Saut")
    MkToggle(p,"WalkSpeed Personnalisé",nil,false,function(v)
        CFG.PLAYER.SpeedEnabled=v
        local h=GetHum(); if h then h.WalkSpeed=v and CFG.PLAYER.SpeedVal or 16 end
    end)
    MkSlider(p,"Speed Valeur",1,150,16,function(v)
        CFG.PLAYER.SpeedVal=v
        if CFG.PLAYER.SpeedEnabled then local h=GetHum(); if h then h.WalkSpeed=v end end
    end)
    MkToggle(p,"JumpPower Personnalisé",nil,false,function(v)
        CFG.PLAYER.JumpEnabled=v
        local h=GetHum(); if h then h.JumpPower=v and CFG.PLAYER.JumpVal or 50 end
    end)
    MkSlider(p,"Jump Valeur",1,500,50,function(v)
        CFG.PLAYER.JumpVal=v
        if CFG.PLAYER.JumpEnabled then local h=GetHum(); if h then h.JumpPower=v end end
    end)
    Spacer(p,4); Section(p,"Mods")
    MkToggle(p,"Fly","WASD+Space/Shift pour voler",false,function(v)
        CFG.PLAYER.FlyEnabled=v; Notify("Fly",v and "ON" or "OFF",v and "success" or "info")
    end)
    MkSlider(p,"Fly Speed",5,300,40,function(v) CFG.PLAYER.FlySpeed=v end)
    MkToggle(p,"Noclip",nil,false,function(v) CFG.PLAYER.Noclip=v; Notify("Noclip",v and "ON" or "OFF") end)
    MkToggle(p,"Invisible [FE]",nil,false,function(v)
        CFG.PLAYER.Invisible=v
        local c=GetChar(); if c then
            for _,part in ipairs(c:GetDescendants()) do
                if part:IsA("BasePart") and part.Name~="HumanoidRootPart" then
                    part.LocalTransparencyModifier=v and 1 or 0
                end
            end
        end
    end)
    MkToggle(p,"Anti Fling",nil,false,function(v) CFG.PLAYER.AntiFling=v end)
    MkToggle(p,"Infinite Stamina",nil,false,function(v) CFG.PLAYER.InfStamina=v end)
    Spacer(p,4); Section(p,"Actions")
    MkButton(p,"Respawn","Recharge le personnage","↺",false,function()
        LP:LoadCharacter(); Notify("Respawn","Personnage rechargé","info")
    end)
    MkButton(p,"Reset Speed & Jump","Remet WalkSpeed=16, Jump=50","⟲",false,function()
        CFG.PLAYER.SpeedEnabled=false; CFG.PLAYER.JumpEnabled=false
        local h=GetHum(); if h then h.WalkSpeed=16; h.JumpPower=50 end
        Notify("Reset","Vitesse & Saut réinitialisés","success")
    end)
end

-- ══════════════════════════════════════════════
--  PAGE: CROSSHAIR
-- ══════════════════════════════════════════════
do
    local p=Pages["Crosshair"]
    Section(p,"Activation")
    MkToggle(p,"Crosshair Custom",nil,false,function(v)
        CFG.CROSSHAIR.Enabled=v
        if not v then for _,d in pairs(CH) do d.Visible=false end end
    end)
    MkToggle(p,"Spin",nil,false,function(v) CFG.CROSSHAIR.Spin=v end)
    Spacer(p,4); Section(p,"Style")
    MkPicker(p,"Style",{"Dot","Cross","Circle","DotCross","KillCross"},"Cross",function(v) CFG.CROSSHAIR.Style=v end)
    Spacer(p,4); Section(p,"Paramètres")
    MkSlider(p,"Taille",1,24,8,function(v) CFG.CROSSHAIR.Size=v end)
    MkSlider(p,"Gap",0,24,4,function(v) CFG.CROSSHAIR.Gap=v end)
    MkSlider(p,"Épaisseur (×10)",5,40,15,function(v) CFG.CROSSHAIR.Thick=v/10 end)
    Spacer(p,4); Section(p,"Couleur")
    MkPicker(p,"Couleur",{"Blanc","Rouge","Vert","Bleu","Cyan","Jaune","Rose","Orange"},"Blanc",function(v)
        local map={Blanc=Color3.fromRGB(255,255,255),Rouge=Color3.fromRGB(255,50,50),
            Vert=Color3.fromRGB(50,220,100),Bleu=Color3.fromRGB(50,140,255),
            Cyan=Color3.fromRGB(50,220,220),Jaune=Color3.fromRGB(240,220,50),
            Rose=Color3.fromRGB(255,100,200),Orange=Color3.fromRGB(255,150,50)}
        CFG.CROSSHAIR.Color=map[v] or Color3.fromRGB(255,255,255)
    end)
end

-- ══════════════════════════════════════════════
--  PAGE: MISC
-- ══════════════════════════════════════════════
do
    local p=Pages["Misc"]
    Section(p,"Visuel")
    MkToggle(p,"Player Chams (Neon)",nil,false,function(v)
        CFG.PLAYER.PlayerChams=v
        for _,pl in ipairs(Players:GetPlayers()) do
            if pl==LP then continue end
            local c=pl.Character; if not c then continue end
            for _,part in ipairs(c:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Material=v and Enum.Material.Neon or Enum.Material.SmoothPlastic
                end
            end
        end
    end)
    Spacer(p,4); Section(p,"Emote")
    MkPicker(p,"Emote",{"ninja","salute","wave","laugh","point","tilt"},"ninja",function(v)
        CFG.MISC_EMOTE=v
    end)
    MkButton(p,"Play Emote","Lance l'emote sélectionné","▶",false,function()
        pcall(function()
            local rs=game:GetService("ReplicatedStorage")
            local er=rs:FindFirstChild("EmoteRequest") or rs:FindFirstChild("Emote")
            if er then er:FireServer(CFG.MISC_EMOTE or "ninja") end
        end)
    end)
    Spacer(p,4); Section(p,"Utilitaire")
    MkButton(p,"Rejoin Server","Reconnecte au même serveur","↺",false,function()
        TS:Teleport(game.PlaceId,LP)
    end)
    MkButton(p,"Copy Server ID","Copie le JobId du serveur","📋",false,function()
        pcall(function() setclipboard(tostring(game.JobId)) end)
        Notify("Clipboard","Server ID copié ✓","success")
    end)
    MkButton(p,"Unload Script","Décharge complètement le script","✕",true,function()
        MainJ:Clean(); CharJ:Clean(); CleanAllDraws(); SG:Destroy()
        Notify("KuraiSoftware","Script déchargé","info")
    end)
end

-- ══════════════════════════════════════════════
--  PAGE: GRAPHICS
-- ══════════════════════════════════════════════
do
    local p=Pages["Graphics"]
    Section(p,"Qualité")
    MkToggle(p,"Low Graphics","FPS max, effets réduits",false,function(v)
        CFG.GRAPHICS.LowGfx=v
        if v then
            pcall(function() settings().Rendering.QualityLevel=Enum.QualityLevel.Level01 end)
            for _,ef in ipairs(Lighting:GetDescendants()) do
                if ef:IsA("PostEffect") then ef.Enabled=false end
            end
        else
            pcall(function() settings().Rendering.QualityLevel=Enum.QualityLevel.Automatic end)
            for _,ef in ipairs(Lighting:GetDescendants()) do
                if ef:IsA("PostEffect") then ef.Enabled=true end
            end
        end
        Notify("Graphics",v and "Low mode ON" or "Auto mode","info")
    end)
    Spacer(p,4); Section(p,"FOV")
    MkSlider(p,"FOV",30,140,70,function(v) CFG.GRAPHICS.FOV=v; Cam.FieldOfView=v end,"°")
    Spacer(p,4); Section(p,"Luminosité")
    MkSlider(p,"Brightness",0,10,2,function(v)
        pcall(function() Lighting.Brightness=v end)
    end)
    MkSlider(p,"Ambient (R)",0,255,75,function(v)
        pcall(function()
            local a=Lighting.Ambient
            Lighting.Ambient=Color3.fromRGB(v,a.G*255,a.B*255)
        end)
    end)
end

-- ══════════════════════════════════════════════
--  PAGE: SKYBOX
-- ══════════════════════════════════════════════
do
    local p=Pages["Skybox"]
    Section(p,"Presets")
    local SKYBOXES={
        {n="Default",    id=nil},
        {n="Space Noir", id="159454286"},
        {n="Nuit Étoilée",id="151454774"},
        {n="Sunrise",    id="2235302752"},
        {n="Neon Ville", id="6444884337"},
    }
    for _,sk in ipairs(SKYBOXES) do
        MkButton(p,sk.n,nil,"›",false,function()
            local old=Lighting:FindFirstChildOfClass("Sky")
            if old then old:Destroy() end
            if not sk.id then Notify("Skybox","Default restauré","info"); return end
            local ok=pcall(function()
                local sky=Instance.new("Sky")
                local asset="rbxassetid://"..sk.id
                sky.SkyboxBk=asset; sky.SkyboxDn=asset
                sky.SkyboxFt=asset; sky.SkyboxLf=asset
                sky.SkyboxRt=asset; sky.SkyboxUp=asset
                sky.Parent=Lighting
            end)
            Notify("Skybox",ok and sk.n.." ✓" or "Erreur preset",ok and "success" or "error")
        end)
    end
    Spacer(p,4)
    MkButton(p,"Supprimer Skybox","Retire le skybox actif","✕",false,function()
        local s=Lighting:FindFirstChildOfClass("Sky")
        if s then s:Destroy(); Notify("Skybox","Supprimé","info")
        else Notify("Skybox","Aucun skybox actif","warning") end
    end)
end

-- ══════════════════════════════════════════════
--  PAGE: KEYBINDS
-- ══════════════════════════════════════════════
do
    local p=Pages["Keybinds"]
    Section(p,"Touches")
    local KEY_OPTS={"RightShift","RightControl","F1","F2","F3","F4","Home","Insert","End"}
    local KEY_MAP={
        RightShift=Enum.KeyCode.RightShift,RightControl=Enum.KeyCode.RightControl,
        F1=Enum.KeyCode.F1,F2=Enum.KeyCode.F2,F3=Enum.KeyCode.F3,F4=Enum.KeyCode.F4,
        Home=Enum.KeyCode.Home,Insert=Enum.KeyCode.Insert,End=Enum.KeyCode.End,
    }
    MkPicker(p,"Toggle Menu",KEY_OPTS,"RightShift",function(v)
        CFG.MENU_KEY=KEY_MAP[v] or Enum.KeyCode.RightShift
        Notify("Keybind","Menu → "..v,"info")
    end)
    Spacer(p,4)
    New("TextLabel",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,36),
        Font=Enum.Font.Gotham,Text="D'autres keybinds seront ajoutés dans les updates.",
        TextColor3=C.TextMuted,TextSize=11,TextWrapped=true,
        TextXAlignment=Enum.TextXAlignment.Left},p)
end

-- ══════════════════════════════════════════════
--  PAGE: WEBHOOK
-- ══════════════════════════════════════════════
do
    local p=Pages["Webhook"]
    Section(p,"Discord Webhook")
    local _,wbox=MkInput(p,"URL Webhook","https://discord.com/api/webhooks/...",function(v)
        CFG.WEBHOOK.URL=v
    end)
    MkToggle(p,"Webhook Activé",nil,false,function(v) CFG.WEBHOOK.Enabled=v end)
    MkToggle(p,"Log Kills",nil,false,function(v) CFG.WEBHOOK.LogKills=v end)
    MkToggle(p,"Log Rôle par Round",nil,false,function(v) CFG.WEBHOOK.LogRole=v end)
    Spacer(p,4)
    MkButton(p,"Test Message","Envoie un message de test","📨",true,function()
        if CFG.WEBHOOK.URL=="" then Notify("Webhook","Aucune URL configurée","warning"); return end
        local ok=pcall(function()
            local payload=HttpService:JSONEncode({username="KuraiSoftware v5",
                content="✅ Test depuis **KuraiSoftware v5.0** — "..LP.Name})
            local r=(syn and syn.request) or request or http_request
            if r then r({Url=CFG.WEBHOOK.URL,Method="POST",
                Headers={["Content-Type"]="application/json"},Body=payload}) end
        end)
        Notify("Webhook",ok and "Envoyé ✓" or "Erreur — vérifiez l'URL",ok and "success" or "error")
    end)
end

-- ══════════════════════════════════════════════
--  PAGE: SETTINGS
-- ══════════════════════════════════════════════
do
    local p=Pages["Settings"]
    Section(p,"Thème Accent")
    MkPicker(p,"Couleur",{"Rouge","Bleu","Violet","Vert","Orange","Cyan","Rose"},"Rouge",function(v)
        local map={Rouge=Color3.fromRGB(190,28,48),Bleu=Color3.fromRGB(28,110,210),
            Violet=Color3.fromRGB(120,40,210),Vert=Color3.fromRGB(28,180,80),
            Orange=Color3.fromRGB(210,110,20),Cyan=Color3.fromRGB(20,180,200),
            Rose=Color3.fromRGB(220,50,150)}
        local nc=map[v] or C.Accent
        C.Accent=nc; C.TogOn=nc
        TopLine.BackgroundColor3=nc; CloseBtn.BackgroundColor3=nc
        FovCircle.Color=nc
        pcall(function() vBg.BackgroundColor3=Color3.fromRGB(nc.R*0.6,nc.G*0.6,nc.B*0.6) end)
        Notify("Thème","Accent → "..v,"info")
    end)
    Spacer(p,4); Section(p,"Debug")
    MkToggle(p,"Mode Debug","Affiche les logs dans la console",false,function(v)
        CFG.DEBUG=v; Notify("Debug",v and "ON — voir console" or "OFF","info")
    end)
    Spacer(p,4); Section(p,"Infos")
    New("TextLabel",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,18),
        Font=Enum.Font.Gotham,Text="KuraiSoftware v5.0 — Complete Rework",TextColor3=C.TextSec,TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left},p)
    New("TextLabel",{BackgroundTransparency=1,Size=UDim2.new(1,0,0,18),
        Font=Enum.Font.Gotham,Text="discord.gg/kuraishop",TextColor3=C.TextMuted,TextSize=11,
        TextXAlignment=Enum.TextXAlignment.Left},p)
end

-- ══════════════════════════════════════════════
--  FLY SYSTEM (objet isolé, pas de vars globales)
-- ══════════════════════════════════════════════
local Fly = {_bv=nil, _bg=nil}
function Fly:Enable()
    local root=GetRoot(); if not root or self._bv then return end
    self._bv=Instance.new("BodyVelocity"); self._bv.Velocity=Vector3.zero
    self._bv.MaxForce=Vector3.new(1e9,1e9,1e9); self._bv.Parent=root
    self._bg=Instance.new("BodyGyro"); self._bg.MaxTorque=Vector3.new(1e9,1e9,1e9)
    self._bg.D=60; self._bg.Parent=root
end
function Fly:Disable()
    if self._bv then self._bv:Destroy(); self._bv=nil end
    if self._bg then self._bg:Destroy(); self._bg=nil end
end
function Fly:Tick()
    if not CFG.PLAYER.FlyEnabled then self:Disable(); return end
    if not self._bv then self:Enable() end
    local root=GetRoot(); if not root or not self._bv then return end
    local cf=Cam.CFrame; local vel=Vector3.zero; local sp=CFG.PLAYER.FlySpeed
    if UIS:IsKeyDown(Enum.KeyCode.W)         then vel=vel+cf.LookVector*sp  end
    if UIS:IsKeyDown(Enum.KeyCode.S)         then vel=vel-cf.LookVector*sp  end
    if UIS:IsKeyDown(Enum.KeyCode.A)         then vel=vel-cf.RightVector*sp end
    if UIS:IsKeyDown(Enum.KeyCode.D)         then vel=vel+cf.RightVector*sp end
    if UIS:IsKeyDown(Enum.KeyCode.Space)     then vel=vel+Vector3.new(0,sp,0) end
    if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then vel=vel-Vector3.new(0,sp,0) end
    self._bv.Velocity=vel; self._bg.CFrame=cf
end

-- ══════════════════════════════════════════════
--  SILENT AIM
-- ══════════════════════════════════════════════
local SilentAim={_conn=nil}
function SilentAim:Tick()
    if CFG.CAMLOCK.SilentAim and not self._conn then
        self._conn=MainJ:Add(RunService.RenderStepped:Connect(function()
            if not CFG.CAMLOCK.SilentAim then return end
            local tgt=GetNearest(CFG.CAMLOCK.FOV)
            if not tgt or not tgt.Character then return end
            local part=tgt.Character:FindFirstChild(CFG.CAMLOCK.SAimPart) or tgt.Character:FindFirstChild("HumanoidRootPart")
            if not part then return end
            pcall(function() Mouse.Hit=CFrame.new(part.Position); Mouse.Target=part end)
        end),"Disconnect")
    elseif not CFG.CAMLOCK.SilentAim and self._conn then
        pcall(function() self._conn:Disconnect() end); self._conn=nil
    end
end

-- ══════════════════════════════════════════════
--  HEARTBEAT — systèmes throttlés
-- ══════════════════════════════════════════════
local th = {Farm=0, Gun=0, Fling=0, Noclip=0}
MainJ:Add(RunService.Heartbeat:Connect(function(dt)

    -- Walk/Jump maintain
    local h=GetHum()
    if h then
        if CFG.PLAYER.SpeedEnabled  then h.WalkSpeed=CFG.PLAYER.SpeedVal end
        if CFG.PLAYER.JumpEnabled   then h.JumpPower=CFG.PLAYER.JumpVal  end
        if CFG.PLAYER.InfStamina then
            pcall(function()
                local st=LP.Character and LP.Character:FindFirstChild("Stamina")
                if st then st.Value=st.MaxValue or 100 end
            end)
        end
    end

    -- Anti fling
    if CFG.PLAYER.AntiFling then
        local root=GetRoot()
        if root and root.AssemblyLinearVelocity.Magnitude > 260 then
            root.AssemblyLinearVelocity=Vector3.zero
        end
    end

    -- Noclip (throttled)
    th.Noclip=th.Noclip+dt
    if th.Noclip>=0.05 then
        th.Noclip=0
        if CFG.PLAYER.Noclip then
            local c=GetChar(); if c then
                for _,part in ipairs(c:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide=false end
                end
            end
        end
    end

    -- Auto Farm (throttled 8x/s)
    th.Farm=th.Farm+dt
    if th.Farm>=0.125 then
        th.Farm=0
        if CFG.COMBAT.AutoFarm then
            local root=GetRoot()
            if root then
                local nearest,nDist=nil,math.huge
                for _,obj in ipairs(WS:GetDescendants()) do
                    if obj:IsA("BasePart") then
                        local n=obj.Name:lower()
                        if n:find("coin") or n:find("gold") then
                            local d=(root.Position-obj.Position).Magnitude
                            if d<nDist then nearest=obj; nDist=d end
                        end
                    end
                end
                if nearest then
                    if CFG.COMBAT.FarmMode=="Nearest" or CFG.COMBAT.FarmMode=="Nearest + XP" then
                        root.CFrame=CFrame.new(nearest.Position+Vector3.new(0,3,0))
                    else
                        root.CFrame=CFrame.new(root.Position+Vector3.new(math.random(-20,20),0,math.random(-20,20)))
                    end
                end
            end
        end
    end

    -- Auto Grab Gun (throttled 4x/s)
    th.Gun=th.Gun+dt
    if th.Gun>=0.25 then
        th.Gun=0
        if CFG.COMBAT.AutoGrabGun then
            local root=GetRoot(); local char=GetChar(); local hum=GetHum()
            if root and char and hum then
                for _,obj in ipairs(WS:GetDescendants()) do
                    if obj:IsA("Tool") and obj.Name:lower():find("gun") then
                        local handle=obj:FindFirstChild("Handle") or obj:FindFirstChildOfClass("BasePart")
                        if handle and (root.Position-handle.Position).Magnitude<25 then
                            pcall(function() hum:EquipTool(obj) end)
                        end
                    end
                end
            end
        end
    end

    -- Fling (throttled 20x/s)
    th.Fling=th.Fling+dt
    if th.Fling>=0.05 then
        th.Fling=0
        if STATE.LoopGoto and STATE.TargetPlayer then
            local root=GetRoot()
            local tr=STATE.TargetPlayer.Character and STATE.TargetPlayer.Character:FindFirstChild("HumanoidRootPart")
            if root and tr then root.CFrame=tr.CFrame+Vector3.new(2,2,0) end
        end
        if STATE.FlingTarget and STATE.TargetPlayer then
            local hr=STATE.TargetPlayer.Character and STATE.TargetPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hr then
                local bv=Instance.new("BodyVelocity")
                bv.Velocity=Vector3.new(math.random(-200,200),300,math.random(-200,200))
                bv.MaxForce=Vector3.new(1e9,1e9,1e9); bv.Parent=hr; Debris:AddItem(bv,0.15)
            end
        end
    end

end),"Disconnect")

-- ══════════════════════════════════════════════
--  RENDER LOOP — ESP + CamLock + Crosshair + Fly
-- ══════════════════════════════════════════════
MainJ:Add(RunService.RenderStepped:Connect(function()
    Fly:Tick()
    SilentAim:Tick()
    Roles:Invalidate()

    local vp     = Cam.ViewportSize
    local cx, cy = vp.X/2, vp.Y/2
    local center = Vector2.new(cx, cy)

    -- FOV Circle
    FovCircle.Visible = CFG.CAMLOCK.ShowFOV and CFG.CAMLOCK.Enabled
    if CFG.CAMLOCK.Enabled then
        FovCircle.Position = center
        FovCircle.Radius   = CFG.CAMLOCK.FOV
        FovCircle.Color    = C.Accent
    end

    -- CamLock
    if CFG.CAMLOCK.Enabled then
        local tgt=GetNearest(CFG.CAMLOCK.FOV)
        if tgt and tgt.Character then
            local part=tgt.Character:FindFirstChild(CFG.CAMLOCK.Part) or tgt.Character:FindFirstChild("HumanoidRootPart")
            if part then
                local sp,on=W2V(part.Position)
                if on and (sp-center).Magnitude<=CFG.CAMLOCK.FOV then
                    Cam.CFrame=Cam.CFrame:Lerp(CFrame.new(Cam.CFrame.Position,part.Position),CFG.CAMLOCK.Smooth)
                end
            end
        end
    end

    -- Crosshair
    for _,d in pairs(CH) do d.Visible=false end
    if CFG.CROSSHAIR.Enabled then
        if CFG.CROSSHAIR.Spin then STATE.CrossAngle=(STATE.CrossAngle+2)%360 end
        local cc=CFG.CROSSHAIR.Color; local cs=CFG.CROSSHAIR.Size
        local cg=CFG.CROSSHAIR.Gap; local ct=CFG.CROSSHAIR.Thick
        local ang=math.rad(STATE.CrossAngle)
        local sinA,cosA=math.sin(ang),math.cos(ang)
        local function rot(dx,dy) return Vector2.new(cx+dx*cosA-dy*sinA,cy+dx*sinA+dy*cosA) end
        local style=CFG.CROSSHAIR.Style
        if style=="Dot" then
            CH.Dot.Position=center; CH.Dot.Radius=cs; CH.Dot.Color=cc; CH.Dot.Visible=true
        elseif style=="Cross" then
            CH.Top.From=rot(0,-(cg+cs)); CH.Top.To=rot(0,-cg)
            CH.Bottom.From=rot(0,cg);   CH.Bottom.To=rot(0,cg+cs)
            CH.Left.From=rot(-(cg+cs),0); CH.Left.To=rot(-cg,0)
            CH.Right.From=rot(cg,0);      CH.Right.To=rot(cg+cs,0)
            for _,ln in pairs({CH.Top,CH.Bottom,CH.Left,CH.Right}) do
                ln.Visible=true; ln.Color=cc; ln.Thickness=ct
            end
        elseif style=="Circle" then
            CH.Circle.Position=center; CH.Circle.Radius=cs+cg
            CH.Circle.Color=cc; CH.Circle.Thickness=ct; CH.Circle.Visible=true
        elseif style=="DotCross" then
            CH.Dot.Position=center; CH.Dot.Radius=2; CH.Dot.Color=cc; CH.Dot.Visible=true
            CH.Top.From=Vector2.new(cx,cy-(cg+cs)); CH.Top.To=Vector2.new(cx,cy-cg)
            CH.Bottom.From=Vector2.new(cx,cy+cg);  CH.Bottom.To=Vector2.new(cx,cy+cg+cs)
            CH.Left.From=Vector2.new(cx-(cg+cs),cy); CH.Left.To=Vector2.new(cx-cg,cy)
            CH.Right.From=Vector2.new(cx+cg,cy);      CH.Right.To=Vector2.new(cx+cg+cs,cy)
            for _,ln in pairs({CH.Top,CH.Bottom,CH.Left,CH.Right}) do
                ln.Visible=true; ln.Color=cc; ln.Thickness=ct
            end
        elseif style=="KillCross" then
            local s=cs+cg
            CH.Top.From=Vector2.new(cx-s,cy-s); CH.Top.To=Vector2.new(cx+s,cy+s)
            CH.Bottom.From=Vector2.new(cx+s,cy-s); CH.Bottom.To=Vector2.new(cx-s,cy+s)
            for _,ln in pairs({CH.Top,CH.Bottom}) do
                ln.Visible=true; ln.Color=cc; ln.Thickness=ct
            end
        end
    end

    -- ESP render
    local myRoot=GetRoot()
    for _,pl in ipairs(Players:GetPlayers()) do
        if pl==LP then continue end
        local esp=ESPStore[pl]; if not esp then continue end
        local char=pl.Character
        local hr=char and char:FindFirstChild("HumanoidRootPart")
        local hum=char and char:FindFirstChildOfClass("Humanoid")

        if not CFG.ESP.Enabled or not char or not hr or not hum then
            ESPHide(esp); continue
        end

        local role=Roles:GetRole(pl)
        local isM=role=="Murder"; local isS=role=="Sheriff"
        if (isM and not CFG.ESP.ShowMurder) or (isS and not CFG.ESP.ShowSheriff) or
           (not isM and not isS and not CFG.ESP.ShowInnocent) then
            ESPHide(esp); continue
        end
        if myRoot and (myRoot.Position-hr.Position).Magnitude>CFG.ESP.MaxDist then
            ESPHide(esp); continue
        end

        local topSP,topOn=W2V(hr.Position+Vector3.new(0,3.2,0))
        local botSP,botOn=W2V(hr.Position+Vector3.new(0,-3.2,0))
        if not topOn and not botOn then ESPHide(esp); continue end

        local roleCol=Roles:GetColor(pl)
        local h2=math.abs(botSP.Y-topSP.Y); local w2=h2*0.55
        local midX=(topSP.X+botSP.X)/2; local pad=3
        local x1=midX-w2/2-pad; local y1=topSP.Y-pad
        local x2=midX+w2/2+pad; local y2=botSP.Y+pad
        local clen=w2*0.3

        if CFG.ESP.Box then
            esp.TL.From=Vector2.new(x1,y1); esp.TL.To=Vector2.new(x1+clen,y1)
            esp.TR.From=Vector2.new(x2-clen,y1); esp.TR.To=Vector2.new(x2,y1)
            esp.BL.From=Vector2.new(x1,y2); esp.BL.To=Vector2.new(x1+clen,y2)
            esp.BR.From=Vector2.new(x2-clen,y2); esp.BR.To=Vector2.new(x2,y2)
            esp.LT.From=Vector2.new(x1,y1); esp.LT.To=Vector2.new(x1,y1+h2*0.3)
            esp.RT.From=Vector2.new(x2,y1); esp.RT.To=Vector2.new(x2,y1+h2*0.3)
            esp.LB.From=Vector2.new(x1,y2-h2*0.3); esp.LB.To=Vector2.new(x1,y2)
            esp.RB.From=Vector2.new(x2,y2-h2*0.3); esp.RB.To=Vector2.new(x2,y2)
            for _,k in ipairs({"TL","TR","BL","BR","LT","RT","LB","RB"}) do
                esp[k].Color=roleCol; esp[k].Visible=true; esp[k].Thickness=2
            end
        else
            for _,k in ipairs({"TL","TR","BL","BR","LT","RT","LB","RB"}) do esp[k].Visible=false end
        end

        if CFG.ESP.Names then
            esp.Name.Text=pl.Name; esp.Name.Position=Vector2.new(midX,y1-16)
            esp.Name.Color=roleCol; esp.Name.Visible=true
        else esp.Name.Visible=false end

        if CFG.ESP.Roles then
            esp.Role.Text=Roles:GetLabel(pl); esp.Role.Position=Vector2.new(midX,y1-28)
            esp.Role.Color=roleCol; esp.Role.Visible=true
        else esp.Role.Visible=false end

        if CFG.ESP.Distance and myRoot then
            esp.Dist.Text=math.floor((myRoot.Position-hr.Position).Magnitude).."m"
            esp.Dist.Position=Vector2.new(midX,y2+4); esp.Dist.Color=C.TextSec; esp.Dist.Visible=true
        else esp.Dist.Visible=false end

        if CFG.ESP.Health then
            local hp=math.clamp(hum.Health/math.max(hum.MaxHealth,1),0,1)
            local bx=x1-7; local bh=h2+pad*2
            esp.HpBg.Position=Vector2.new(bx,y1); esp.HpBg.Size=Vector2.new(4,bh); esp.HpBg.Visible=true
            esp.HpFill.Position=Vector2.new(bx,y1+bh*(1-hp)); esp.HpFill.Size=Vector2.new(4,bh*hp)
            esp.HpFill.Color=Color3.fromRGB(math.floor(255*(1-hp)),math.floor(255*hp),0); esp.HpFill.Visible=true
        else esp.HpBg.Visible=false; esp.HpFill.Visible=false end

        if CFG.ESP.Tracer then
            esp.Tracer.From=Vector2.new(cx,vp.Y); esp.Tracer.To=Vector2.new(midX,y2)
            esp.Tracer.Color=roleCol; esp.Tracer.Visible=true
        else esp.Tracer.Visible=false end
    end
end),"Disconnect")

-- ══════════════════════════════════════════════
--  KEYBIND
-- ══════════════════════════════════════════════
MainJ:Add(UIS.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == CFG.MENU_KEY then
        STATE.MenuOpen = not STATE.MenuOpen
        Win.Visible    = STATE.MenuOpen
        if STATE.MenuOpen then
            Win.Size = UDim2.new(0,W.W,0,0)
            Tween(Win, AI_SPRING, {Size=UDim2.new(0,W.W,0,W.H)})
        end
    end
end),"Disconnect")

-- Open button
local OpenBtn=New("TextButton",{Name="KuraiOpenV5",BackgroundColor3=C.Accent,BorderSizePixel=0,
    Position=UDim2.new(0,8,0.5,-18),Size=UDim2.new(0,36,0,36),
    Font=Enum.Font.GothamBlack,Text="K",TextColor3=C.TextPrim,TextSize=17,Visible=false},SG)
Corner(99,OpenBtn)
Stroke(C.Accent,1.5,OpenBtn)

Win:GetPropertyChangedSignal("Visible"):Connect(function() OpenBtn.Visible=not Win.Visible end)
OpenBtn.MouseEnter:Connect(function() Tween(OpenBtn,AI_FAST,{BackgroundColor3=C.AccentGlow}) end)
OpenBtn.MouseLeave:Connect(function() Tween(OpenBtn,AI_FAST,{BackgroundColor3=C.Accent}) end)
OpenBtn.MouseButton1Click:Connect(function()
    STATE.MenuOpen=true; Win.Visible=true
    Win.Size=UDim2.new(0,W.W,0,0)
    Tween(Win,AI_SPRING,{Size=UDim2.new(0,W.W,0,W.H)})
end)

-- ══════════════════════════════════════════════
--  CHARACTER RESPAWN
-- ══════════════════════════════════════════════
local function OnChar(char)
    CharJ:Clean()
    task.wait(0.8)
    local hum=char:WaitForChild("Humanoid",5); if not hum then return end
    if CFG.PLAYER.SpeedEnabled then hum.WalkSpeed=CFG.PLAYER.SpeedVal end
    if CFG.PLAYER.JumpEnabled  then hum.JumpPower=CFG.PLAYER.JumpVal  end
    if CFG.PLAYER.FlyEnabled   then task.delay(0.5,function() Fly:Enable() end) end
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP and not ESPStore[p] then ESPMake(p) end
    end
    Roles:Invalidate()
end
MainJ:Add(LP.CharacterAdded:Connect(OnChar),"Disconnect")
if LP.Character then task.spawn(OnChar,LP.Character) end

-- ══════════════════════════════════════════════
--  STARTUP
-- ══════════════════════════════════════════════
Win.Size                   = UDim2.new(0,W.W,0,0)
Win.BackgroundTransparency = 1
task.spawn(function()
    TweenService:Create(Win, AI_SPRING, {
        Size                   = UDim2.new(0,W.W,0,W.H),
        BackgroundTransparency = 0,
    }):Play()
end)

task.wait(1.2)
Notify("KuraiSoftware v5.0","Chargé ✓ — "..tostring(CFG.MENU_KEY.Name).." pour toggle","success",5)
Log("KuraiSoftware v5.0 initialized — "..LP.Name)

-- ══════════════════════════════════════════════
--  FIN v5.0
-- ══════════════════════════════════════════════

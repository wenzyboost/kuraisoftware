--[[
    ██╗  ██╗██╗   ██╗██████╗  █████╗ ██╗    ███████╗ ██████╗ ███████╗████████╗██╗    ██╗ █████╗ ██████╗ ███████╗
    ██║ ██╔╝██║   ██║██╔══██╗██╔══██╗██║    ██╔════╝██╔═══██╗██╔════╝╚══██╔══╝██║    ██║██╔══██╗██╔══██╗██╔════╝
    █████╔╝ ██║   ██║██████╔╝███████║██║    ███████╗██║   ██║█████╗     ██║   ██║ █╗ ██║███████║██████╔╝█████╗
    ██╔═██╗ ██║   ██║██╔══██╗██╔══██║██║    ╚════██║██║   ██║██╔══╝     ██║   ██║███╗██║██╔══██║██╔══██╗██╔══╝
    ██║  ██╗╚██████╔╝██║  ██║██║  ██║██║    ███████║╚██████╔╝██║        ██║   ╚███╔███╔╝██║  ██║██║  ██║███████╗
    ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝    ╚══════╝ ╚═════╝ ╚═╝        ╚═╝    ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝
    
    KuraiSoftware — Murder Mystery 2 Script
    Version: 3.7.1
    Author: KuraiSoftware (discord.gg/kuraishop)
    Style: RuzHub × Vertex Fusion
    
    Features:
    ► ESP (Box, Name, Distance, Health, Tracer, Role)
    ► CamLock / Aimbot (FOV, Smoothing, Target Priority)
    ► Player Mods (Speed, Jump, Invisibility [FE], Anti-Fling)
    ► Target System (Fling, Teleport, Spectate, Loop GoTo)
    ► Auto Farm (Nearest, XP Mode, Randomize)
    ► Misc (Player Chams, Gun Cham, Name ESP, 3D Rendering, Auto Emote)
    ► Cursor Picker (Custom Crosshair, Spin Crosshair)
    ► Skybox Picker (Custom skybox IDs)
    ► Graphics (Low/High, FOV Slider, Stretch Resolution)
    ► Webhook Logger (Roles, Events)
    ► Roles Manager
    ► Settings (Keybind, Theme, Config Save/Load)
    
    Usage: loadstring(game:HttpGet("https://raw.githubusercontent.com/kurai/mm2/main/script.lua"))()
--]]

-- ============================================================
--                     SERVICES & VARIABLES
-- ============================================================

local RunService      = game:GetService("RunService")
local Players         = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService    = game:GetService("TweenService")
local HttpService      = game:GetService("HttpService")
local Workspace       = game:GetService("Workspace")
local Lighting        = game:GetService("Lighting")
local CoreGui         = game:GetService("CoreGui")
local StarterGui      = game:GetService("StarterGui")
local SoundService    = game:GetService("SoundService")
local GuiService      = game:GetService("GuiService")

local LocalPlayer     = Players.LocalPlayer
local PlayerGui       = LocalPlayer:WaitForChild("PlayerGui")
local Camera          = Workspace.CurrentCamera
local Mouse           = LocalPlayer:GetMouse()

-- ============================================================
--                        CONFIG TABLE
-- ============================================================

local KuraiConfig = {
    -- Meta
    Version     = "3.7.1",
    Author      = "KuraiSoftware",
    Discord     = "discord.gg/kuraishop",
    
    -- GUI Toggle Key
    OpenKey     = Enum.KeyCode.RightShift,
    
    -- ESP Settings
    ESP = {
        Enabled         = false,
        BoxESP          = false,
        NameESP         = false,
        DistanceESP     = false,
        HealthESP       = false,
        TracerESP       = false,
        RoleESP         = false,
        Chams           = false,
        GunChams        = false,
        TeamCheck       = false,
        -- Colors
        SheriffColor    = Color3.fromRGB(50, 100, 255),
        MurdererColor   = Color3.fromRGB(220, 30, 30),
        InnocentColor   = Color3.fromRGB(80, 220, 80),
        SelfColor       = Color3.fromRGB(255, 200, 50),
        BoxColor        = Color3.fromRGB(200, 0, 0),
        TracerColor     = Color3.fromRGB(200, 0, 0),
        BoxThickness    = 1,
        TracerOrigin    = "Bottom",
        MaxDistance     = 500,
        FontSize        = 13,
    },

    -- CamLock / Aimbot
    CamLock = {
        Enabled         = false,
        FOV             = 120,
        Smoothness      = 0.15,
        ShowFOVCircle   = true,
        TargetPart      = "Head",
        PredictMovement = false,
        PredictionValue = 0.12,
        LockKey         = Enum.KeyCode.Q,
        AutoTarget      = false,
        Priority        = "Murderer", -- Murderer / Sheriff / Nearest
        SilentAim       = false,
        TriggerBot      = false,
        TriggerDelay    = 0.05,
        AimbotFOVColor  = Color3.fromRGB(220, 0, 0),
        LockedColor     = Color3.fromRGB(0, 255, 100),
    },

    -- Player
    Player = {
        WalkSpeed       = 16,
        WalkSpeedEnabled = false,
        JumpPower       = 50,
        JumpPowerEnabled = false,
        Invisible       = false,
        AntiFling       = false,
        NoClip          = false,
        FlyEnabled      = false,
        FlySpeed        = 80,
        InfiniteJump    = false,
        GodMode         = false, -- FE only, partial
        BringOnClick    = false,
        AutoDodgeKnife  = false,
        AutoGrabGun     = false,
        AntiKick        = false,
    },

    -- Target
    Target = {
        SelectedTarget  = nil,
        FlingTarget     = false,
        FlingPower      = 999999,
        SpectateTarget  = false,
        LoopGoToTarget  = false,
        TeleportToTarget = false,
        FlingMurderer   = false,
        FlingSheriff    = false,
        KillAura        = false,
        KillAuraRadius  = 15,
    },

    -- Auto Farm
    Farm = {
        Enabled         = false,
        Mode            = "Nearest", -- Nearest / Nearest+XP / Randomize
        AutoEndRound    = false,
        TeleportToLobby = false,
        TeleportToMap   = false,
        AutoGrabGun     = false,
        AutoComplete    = false,
    },

    -- Misc
    Misc = {
        PlayerChams     = false,
        GunCham         = false,
        Rendering3D     = false,
        NameESP         = false,
        AutoEmote       = false,
        EmoteID         = "ninja",
        RainbowChams    = false,
        ChamsColor      = Color3.fromRGB(220, 0, 0),
        GunChamColor    = Color3.fromRGB(0, 200, 255),
        ChatSpy         = false,
        ServerHop       = false,
        AntiAFK         = false,
        Fullbright      = false,
    },

    -- Cursor
    Cursor = {
        CustomCrosshair = false,
        CrosshairID     = "",
        SpinCrosshair   = false,
        SpinSpeed       = 5,
        Selected        = "Default",
        CustomColor     = Color3.fromRGB(255, 255, 255),
    },

    -- Skybox
    Skybox = {
        CustomSkybox    = false,
        SkyboxID        = "",
        List            = {
            ["Default"]     = nil,
            ["Night"]       = "rbxassetid://7078800695",
            ["Space"]       = "rbxassetid://1261715018",
            ["Blaze"]       = "rbxassetid://185773492",
            ["Crimson"]     = "rbxassetid://2516675",
        },
    },

    -- Graphics
    Graphics = {
        LowGraphics     = false,
        HighGraphics    = false,
        FOVValue        = 70,
        StretchEnabled  = false,
        StretchX        = 1,
        StretchY        = 1,
        Shadows         = true,
        Particles       = true,
        PostFX          = true,
    },

    -- Webhook
    Webhook = {
        URL             = "",
        LogRoles        = false,
        LogKills        = false,
        LogRounds       = false,
        LogChat         = false,
        Username        = "KuraiSoftware",
        AvatarURL       = "",
    },

    -- Roles
    Roles = {
        SheriffList     = {},
        MurdererList    = {},
        BanList         = {},
        FriendList      = {},
    },

    -- Settings
    Settings = {
        Theme           = "Default", -- Default / Light / Purple / Matrix
        Notification    = true,
        SaveConfig      = true,
        ConfigName      = "KuraiDefault",
        WatermarkEnabled = true,
        FPSBoost        = false,
    },
}

-- ============================================================
--                     UTILITY FUNCTIONS
-- ============================================================

local Utils = {}

function Utils.Tween(obj, props, time, style, direction)
    style = style or Enum.EasingStyle.Quad
    direction = direction or Enum.EasingDirection.Out
    local info = TweenInfo.new(time or 0.25, style, direction)
    TweenService:Create(obj, info, props):Play()
end

function Utils.Round(n, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(n * mult + 0.5) / mult
end

function Utils.WorldToScreen(pos)
    local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen, screenPos.Z
end

function Utils.GetDistance(pos)
    if not LocalPlayer.Character then return 0 end
    local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return 0 end
    return (hrp.Position - pos).Magnitude
end

function Utils.GetRole(player)
    -- MM2 role detection via tags / values
    local char = player.Character
    if not char then return "Innocent" end
    
    -- Check for knife (murderer tool)
    local bp = player:FindFirstChild("Backpack")
    local charModel = char
    
    -- Try GameTag
    local gameTag = player:FindFirstChild("GameTag")
    if gameTag then
        if gameTag.Value == "Murderer" then return "Murderer" end
        if gameTag.Value == "Sheriff" then return "Sheriff" end
    end
    
    -- Knife detection in character
    for _, v in pairs(charModel:GetDescendants()) do
        if v:IsA("Tool") or v:IsA("Model") then
            if v.Name:lower():find("knife") or v.Name:lower():find("murder") then
                return "Murderer"
            end
            if v.Name:lower():find("gun") or v.Name:lower():find("sheriff") then
                return "Sheriff"
            end
        end
    end
    
    return "Innocent"
end

function Utils.GetPlayerFromCharacter(char)
    for _, p in pairs(Players:GetPlayers()) do
        if p.Character == char then return p end
    end
    return nil
end

function Utils.GetNearestPlayer(maxDist, filterRole)
    local nearest = nil
    local nearestDist = maxDist or math.huge
    
    for _, p in pairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        if not p.Character then continue end
        local hrp = p.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        
        local dist = Utils.GetDistance(hrp.Position)
        
        if filterRole and filterRole ~= "Any" then
            if Utils.GetRole(p) ~= filterRole then continue end
        end
        
        if dist < nearestDist then
            nearestDist = dist
            nearest = p
        end
    end
    
    return nearest, nearestDist
end

function Utils.GetMurderer()
    for _, p in pairs(Players:GetPlayers()) do
        if Utils.GetRole(p) == "Murderer" then return p end
    end
    return nil
end

function Utils.GetSheriff()
    for _, p in pairs(Players:GetPlayers()) do
        if Utils.GetRole(p) == "Sheriff" then return p end
    end
    return nil
end

function Utils.SendWebhook(data)
    if KuraiConfig.Webhook.URL == "" then return end
    pcall(function()
        local payload = {
            username  = KuraiConfig.Webhook.Username,
            avatar_url = KuraiConfig.Webhook.AvatarURL,
            embeds    = { data }
        }
        HttpService:RequestAsync({
            Url     = KuraiConfig.Webhook.URL,
            Method  = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body    = HttpService:JSONEncode(payload),
        })
    end)
end

function Utils.Notification(title, body, duration)
    if not KuraiConfig.Settings.Notification then return end
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title    = "KuraiSoftware | " .. (title or ""),
            Text     = body or "",
            Duration = duration or 3,
        })
    end)
end

function Utils.FireServer(remote, ...)
    local args = {...}
    pcall(function()
        remote:FireServer(table.unpack(args))
    end)
end

function Utils.SafeDestroy(obj)
    if obj and obj.Parent then
        pcall(obj.Destroy, obj)
    end
end

function Utils.Clone(t)
    local copy = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            copy[k] = Utils.Clone(v)
        else
            copy[k] = v
        end
    end
    return copy
end

-- ============================================================
--                          DRAWING LIB
-- ============================================================
-- Uses Drawing API (synapse / KRNL / Fluxus compatible)

local DrawLib = {}
DrawLib.Objects = {}

function DrawLib.NewLine(props)
    local line = Drawing.new("Line")
    for k, v in pairs(props or {}) do line[k] = v end
    table.insert(DrawLib.Objects, line)
    return line
end

function DrawLib.NewText(props)
    local text = Drawing.new("Text")
    text.Font = Drawing.Fonts.Plex
    text.Size = 13
    for k, v in pairs(props or {}) do text[k] = v end
    table.insert(DrawLib.Objects, text)
    return text
end

function DrawLib.NewSquare(props)
    local sq = Drawing.new("Square")
    sq.Filled = false
    sq.Thickness = 1
    for k, v in pairs(props or {}) do sq[k] = v end
    table.insert(DrawLib.Objects, sq)
    return sq
end

function DrawLib.NewFilledSquare(props)
    local sq = Drawing.new("Square")
    sq.Filled = true
    sq.Thickness = 0
    for k, v in pairs(props or {}) do sq[k] = v end
    table.insert(DrawLib.Objects, sq)
    return sq
end

function DrawLib.NewCircle(props)
    local c = Drawing.new("Circle")
    c.Filled = false
    c.Thickness = 1
    for k, v in pairs(props or {}) do c[k] = v end
    table.insert(DrawLib.Objects, c)
    return c
end

function DrawLib.NewTriangle(props)
    local t = Drawing.new("Triangle")
    t.Filled = false
    t.Thickness = 1
    for k, v in pairs(props or {}) do t[k] = v end
    table.insert(DrawLib.Objects, t)
    return t
end

function DrawLib.Clear()
    for _, obj in pairs(DrawLib.Objects) do
        pcall(obj.Remove, obj)
    end
    DrawLib.Objects = {}
end

function DrawLib.SetVisible(obj, vis)
    pcall(function() obj.Visible = vis end)
end

-- ============================================================
--                       ESP SYSTEM
-- ============================================================

local ESP = {}
ESP.Instances = {}

local function GetCornerBoxPoints(hrp, size)
    size = size or Vector3.new(2, 5, 2)
    local cframe = hrp.CFrame
    local topL   = cframe * CFrame.new(-size.X, size.Y, 0)
    local topR   = cframe * CFrame.new( size.X, size.Y, 0)
    local botL   = cframe * CFrame.new(-size.X,-size.Y, 0)
    local botR   = cframe * CFrame.new( size.X,-size.Y, 0)
    return topL.Position, topR.Position, botL.Position, botR.Position
end

function ESP.CreateInstance(player)
    if ESP.Instances[player] then return end
    
    local inst = {
        Player = player,
        -- Box
        BoxTop    = DrawLib.NewLine({ Color = KuraiConfig.ESP.BoxColor, Thickness = KuraiConfig.ESP.BoxThickness }),
        BoxBottom = DrawLib.NewLine({ Color = KuraiConfig.ESP.BoxColor, Thickness = KuraiConfig.ESP.BoxThickness }),
        BoxLeft   = DrawLib.NewLine({ Color = KuraiConfig.ESP.BoxColor, Thickness = KuraiConfig.ESP.BoxThickness }),
        BoxRight  = DrawLib.NewLine({ Color = KuraiConfig.ESP.BoxColor, Thickness = KuraiConfig.ESP.BoxThickness }),
        -- Corner accents (RuzHub style)
        CornerTL1 = DrawLib.NewLine({ Color = KuraiConfig.ESP.BoxColor, Thickness = 2 }),
        CornerTL2 = DrawLib.NewLine({ Color = KuraiConfig.ESP.BoxColor, Thickness = 2 }),
        CornerTR1 = DrawLib.NewLine({ Color = KuraiConfig.ESP.BoxColor, Thickness = 2 }),
        CornerTR2 = DrawLib.NewLine({ Color = KuraiConfig.ESP.BoxColor, Thickness = 2 }),
        CornerBL1 = DrawLib.NewLine({ Color = KuraiConfig.ESP.BoxColor, Thickness = 2 }),
        CornerBL2 = DrawLib.NewLine({ Color = KuraiConfig.ESP.BoxColor, Thickness = 2 }),
        CornerBR1 = DrawLib.NewLine({ Color = KuraiConfig.ESP.BoxColor, Thickness = 2 }),
        CornerBR2 = DrawLib.NewLine({ Color = KuraiConfig.ESP.BoxColor, Thickness = 2 }),
        -- Name
        NameText  = DrawLib.NewText({ Color = Color3.fromRGB(255,255,255), Size = KuraiConfig.ESP.FontSize, Outline = true }),
        -- Distance
        DistText  = DrawLib.NewText({ Color = Color3.fromRGB(200,200,200), Size = 11, Outline = true }),
        -- Role
        RoleText  = DrawLib.NewText({ Color = Color3.fromRGB(255,255,255), Size = 11, Outline = true }),
        -- Health Bar
        HealthBarBG = DrawLib.NewLine({ Color = Color3.fromRGB(20,20,20), Thickness = 4 }),
        HealthBar   = DrawLib.NewLine({ Color = Color3.fromRGB(0,220,80), Thickness = 3 }),
        -- Tracer
        Tracer    = DrawLib.NewLine({ Color = KuraiConfig.ESP.TracerColor, Thickness = 1, Transparency = 0.7 }),
    }
    
    ESP.Instances[player] = inst
    
    player.CharacterRemoving:Connect(function()
        ESP.HideInstance(player)
    end)
end

function ESP.HideInstance(player)
    local inst = ESP.Instances[player]
    if not inst then return end
    for k, obj in pairs(inst) do
        if type(obj) ~= "table" and type(obj) ~= "userdata" and k ~= "Player" then
            pcall(function() obj.Visible = false end)
        end
    end
end

function ESP.DestroyInstance(player)
    local inst = ESP.Instances[player]
    if not inst then return end
    for k, obj in pairs(inst) do
        if type(obj) ~= "table" and type(obj) ~= "userdata" and k ~= "Player" then
            pcall(obj.Remove, obj)
        end
    end
    ESP.Instances[player] = nil
end

function ESP.UpdateInstance(player)
    local inst = ESP.Instances[player]
    if not inst then return end
    
    local char = player.Character
    if not char then
        ESP.HideInstance(player)
        return
    end
    
    local hrp  = char:FindFirstChild("HumanoidRootPart")
    local hum  = char:FindFirstChildOfClass("Humanoid")
    local head = char:FindFirstChild("Head")
    
    if not hrp or not hum or not head then
        ESP.HideInstance(player)
        return
    end
    
    local dist = Utils.GetDistance(hrp.Position)
    if dist > KuraiConfig.ESP.MaxDistance then
        ESP.HideInstance(player)
        return
    end
    
    -- Screen projection
    local rootPos, onScreen, depth = Utils.WorldToScreen(hrp.Position)
    if not onScreen or depth <= 0 then
        ESP.HideInstance(player)
        return
    end
    
    local headPos2D = Utils.WorldToScreen(head.Position + Vector3.new(0, 0.5, 0))
    local scale     = 1 / depth * 500
    local boxW      = math.max(30, scale * 1.2)
    local boxH      = math.abs(rootPos.Y - headPos2D.Y) * 1.1
    
    if boxH < 20 then boxH = 20 end
    
    local topY  = rootPos.Y - boxH
    local botY  = rootPos.Y
    local leftX = rootPos.X - boxW / 2
    local rightX = rootPos.X + boxW / 2
    
    -- Role and color
    local role      = Utils.GetRole(player)
    local roleColor = KuraiConfig.ESP.InnocentColor
    if role == "Murderer" then roleColor = KuraiConfig.ESP.MurdererColor
    elseif role == "Sheriff" then roleColor = KuraiConfig.ESP.SheriffColor end
    
    -- ─── Box ───
    if KuraiConfig.ESP.BoxESP then
        -- Full box
        inst.BoxTop.From    = Vector2.new(leftX,  topY)
        inst.BoxTop.To      = Vector2.new(rightX, topY)
        inst.BoxTop.Color   = roleColor
        inst.BoxTop.Visible = true
        
        inst.BoxBottom.From    = Vector2.new(leftX,  botY)
        inst.BoxBottom.To      = Vector2.new(rightX, botY)
        inst.BoxBottom.Color   = roleColor
        inst.BoxBottom.Visible = true
        
        inst.BoxLeft.From    = Vector2.new(leftX, topY)
        inst.BoxLeft.To      = Vector2.new(leftX, botY)
        inst.BoxLeft.Color   = roleColor
        inst.BoxLeft.Visible = true
        
        inst.BoxRight.From    = Vector2.new(rightX, topY)
        inst.BoxRight.To      = Vector2.new(rightX, botY)
        inst.BoxRight.Color   = roleColor
        inst.BoxRight.Visible = true
        
        -- Corner Accents (RuzHub / Kurai signature style)
        local cLen = math.min(boxW, boxH) * 0.22
        -- TL
        inst.CornerTL1.From = Vector2.new(leftX, topY);  inst.CornerTL1.To = Vector2.new(leftX + cLen, topY); inst.CornerTL1.Color = Color3.fromRGB(255,255,255); inst.CornerTL1.Visible = true
        inst.CornerTL2.From = Vector2.new(leftX, topY);  inst.CornerTL2.To = Vector2.new(leftX, topY + cLen); inst.CornerTL2.Color = Color3.fromRGB(255,255,255); inst.CornerTL2.Visible = true
        -- TR
        inst.CornerTR1.From = Vector2.new(rightX, topY); inst.CornerTR1.To = Vector2.new(rightX - cLen, topY); inst.CornerTR1.Color = Color3.fromRGB(255,255,255); inst.CornerTR1.Visible = true
        inst.CornerTR2.From = Vector2.new(rightX, topY); inst.CornerTR2.To = Vector2.new(rightX, topY + cLen); inst.CornerTR2.Color = Color3.fromRGB(255,255,255); inst.CornerTR2.Visible = true
        -- BL
        inst.CornerBL1.From = Vector2.new(leftX, botY);  inst.CornerBL1.To = Vector2.new(leftX + cLen, botY); inst.CornerBL1.Color = Color3.fromRGB(255,255,255); inst.CornerBL1.Visible = true
        inst.CornerBL2.From = Vector2.new(leftX, botY);  inst.CornerBL2.To = Vector2.new(leftX, botY - cLen); inst.CornerBL2.Color = Color3.fromRGB(255,255,255); inst.CornerBL2.Visible = true
        -- BR
        inst.CornerBR1.From = Vector2.new(rightX, botY); inst.CornerBR1.To = Vector2.new(rightX - cLen, botY); inst.CornerBR1.Color = Color3.fromRGB(255,255,255); inst.CornerBR1.Visible = true
        inst.CornerBR2.From = Vector2.new(rightX, botY); inst.CornerBR2.To = Vector2.new(rightX, botY - cLen); inst.CornerBR2.Color = Color3.fromRGB(255,255,255); inst.CornerBR2.Visible = true
    else
        inst.BoxTop.Visible = false; inst.BoxBottom.Visible = false
        inst.BoxLeft.Visible = false; inst.BoxRight.Visible = false
        inst.CornerTL1.Visible = false; inst.CornerTL2.Visible = false
        inst.CornerTR1.Visible = false; inst.CornerTR2.Visible = false
        inst.CornerBL1.Visible = false; inst.CornerBL2.Visible = false
        inst.CornerBR1.Visible = false; inst.CornerBR2.Visible = false
    end
    
    -- ─── Name ───
    if KuraiConfig.ESP.NameESP then
        inst.NameText.Text     = player.DisplayName
        inst.NameText.Position = Vector2.new(rootPos.X, topY - 15)
        inst.NameText.Color    = roleColor
        inst.NameText.Center   = true
        inst.NameText.Visible  = true
    else
        inst.NameText.Visible = false
    end
    
    -- ─── Distance ───
    if KuraiConfig.ESP.DistanceESP then
        inst.DistText.Text     = string.format("[%dm]", math.floor(dist))
        inst.DistText.Position = Vector2.new(rootPos.X, botY + 2)
        inst.DistText.Color    = Color3.fromRGB(200, 200, 200)
        inst.DistText.Center   = true
        inst.DistText.Visible  = true
    else
        inst.DistText.Visible = false
    end
    
    -- ─── Role Tag ───
    if KuraiConfig.ESP.RoleESP then
        inst.RoleText.Text     = "[" .. role .. "]"
        inst.RoleText.Position = Vector2.new(rightX + 3, topY)
        inst.RoleText.Color    = roleColor
        inst.RoleText.Visible  = true
    else
        inst.RoleText.Visible = false
    end
    
    -- ─── Health Bar ───
    if KuraiConfig.ESP.HealthESP then
        local hp    = hum.Health
        local maxHP = hum.MaxHealth
        local hpPct = hp / math.max(maxHP, 1)
        
        local barX   = leftX - 5
        local barTop = topY
        local barBot = botY
        local barH   = barBot - barTop
        
        inst.HealthBarBG.From    = Vector2.new(barX, barTop)
        inst.HealthBarBG.To      = Vector2.new(barX, barBot)
        inst.HealthBarBG.Color   = Color3.fromRGB(10,10,10)
        inst.HealthBarBG.Visible = true
        
        local hpColor = Color3.fromRGB(
            math.floor((1 - hpPct) * 255),
            math.floor(hpPct * 220),
            30
        )
        inst.HealthBar.From    = Vector2.new(barX, barBot)
        inst.HealthBar.To      = Vector2.new(barX, barBot - barH * hpPct)
        inst.HealthBar.Color   = hpColor
        inst.HealthBar.Visible = true
    else
        inst.HealthBarBG.Visible = false
        inst.HealthBar.Visible   = false
    end
    
    -- ─── Tracer ───
    if KuraiConfig.ESP.TracerESP then
        local viewportSize = Camera.ViewportSize
        local origin
        if KuraiConfig.ESP.TracerOrigin == "Bottom" then
            origin = Vector2.new(viewportSize.X / 2, viewportSize.Y)
        elseif KuraiConfig.ESP.TracerOrigin == "Center" then
            origin = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
        else
            origin = Vector2.new(viewportSize.X / 2, 0)
        end
        
        inst.Tracer.From    = origin
        inst.Tracer.To      = rootPos
        inst.Tracer.Color   = roleColor
        inst.Tracer.Visible = true
    else
        inst.Tracer.Visible = false
    end
end

function ESP.Init()
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            ESP.CreateInstance(p)
        end
    end
    
    Players.PlayerAdded:Connect(function(p)
        if p ~= LocalPlayer then
            wait(1)
            ESP.CreateInstance(p)
        end
    end)
    
    Players.PlayerRemoving:Connect(function(p)
        ESP.DestroyInstance(p)
    end)
end

function ESP.Update()
    if not KuraiConfig.ESP.Enabled then
        for p, _ in pairs(ESP.Instances) do
            ESP.HideInstance(p)
        end
        return
    end
    
    for p, _ in pairs(ESP.Instances) do
        ESP.UpdateInstance(p)
    end
end

-- ============================================================
--                       CAMLOCK SYSTEM
-- ============================================================

local CamLock = {}
CamLock.Active  = false
CamLock.Target  = nil
CamLock.FOVCircle = DrawLib.NewCircle({
    Radius      = KuraiConfig.CamLock.FOV,
    Color       = KuraiConfig.CamLock.AimbotFOVColor,
    Thickness   = 1,
    Visible     = false,
    Transparency = 0.6,
})

function CamLock.GetBestTarget()
    local bestPlayer = nil
    local bestDist   = KuraiConfig.CamLock.FOV

    -- Priority: Murderer first if set
    local pList = Players:GetPlayers()
    
    -- Sort by priority
    local sorted = {}
    for _, p in pairs(pList) do
        if p ~= LocalPlayer and p.Character then
            table.insert(sorted, p)
        end
    end
    
    table.sort(sorted, function(a, b)
        local roleA = Utils.GetRole(a)
        local roleB = Utils.GetRole(b)
        local prioA = (roleA == KuraiConfig.CamLock.Priority) and 0 or 1
        local prioB = (roleB == KuraiConfig.CamLock.Priority) and 0 or 1
        return prioA < prioB
    end)
    
    local viewportCenter = Camera.ViewportSize / 2

    for _, p in pairs(sorted) do
        local char = p.Character
        if not char then continue end
        
        local part = char:FindFirstChild(KuraiConfig.CamLock.TargetPart) or char:FindFirstChild("HumanoidRootPart")
        if not part then continue end
        
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum and hum.Health <= 0 then continue end
        
        local screenPos, onScreen = Utils.WorldToScreen(part.Position)
        if not onScreen then continue end
        
        local screenDist = (screenPos - viewportCenter).Magnitude
        if screenDist < bestDist then
            bestDist   = screenDist
            bestPlayer = p
        end
    end
    
    return bestPlayer
end

function CamLock.GetTargetPosition(player)
    if not player or not player.Character then return nil end
    local part = player.Character:FindFirstChild(KuraiConfig.CamLock.TargetPart)
        or player.Character:FindFirstChild("HumanoidRootPart")
    if not part then return nil end
    
    local pos = part.Position
    
    -- Movement prediction
    if KuraiConfig.CamLock.PredictMovement then
        local hrp = player.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local vel = hrp.Velocity
            pos = pos + vel * KuraiConfig.CamLock.PredictionValue
        end
    end
    
    return pos
end

function CamLock.Update()
    local viewportSize   = Camera.ViewportSize
    local viewportCenter = viewportSize / 2
    
    -- FOV Circle
    CamLock.FOVCircle.Radius  = KuraiConfig.CamLock.FOV
    CamLock.FOVCircle.Position = viewportCenter
    CamLock.FOVCircle.Visible  = KuraiConfig.CamLock.ShowFOVCircle and KuraiConfig.CamLock.Enabled

    if not KuraiConfig.CamLock.Enabled then
        CamLock.Active = false
        CamLock.Target = nil
        CamLock.FOVCircle.Color = KuraiConfig.CamLock.AimbotFOVColor
        return
    end
    
    -- Toggle on key hold
    local lockKeyDown = UserInputService:IsKeyDown(KuraiConfig.CamLock.LockKey)
    
    if not lockKeyDown and not KuraiConfig.CamLock.AutoTarget then
        CamLock.Active = false
        CamLock.Target = nil
        CamLock.FOVCircle.Color = KuraiConfig.CamLock.AimbotFOVColor
        return
    end
    
    -- Find target
    if not CamLock.Target or not CamLock.Target.Character then
        CamLock.Target = CamLock.GetBestTarget()
    end
    
    if not CamLock.Target then
        CamLock.Active = false
        CamLock.FOVCircle.Color = KuraiConfig.CamLock.AimbotFOVColor
        return
    end
    
    local targetPos = CamLock.GetTargetPosition(CamLock.Target)
    if not targetPos then
        CamLock.Target = nil
        CamLock.Active = false
        return
    end
    
    CamLock.Active = true
    CamLock.FOVCircle.Color = KuraiConfig.CamLock.LockedColor
    
    -- Smooth camera rotation toward target
    local targetCFrame    = CFrame.lookAt(Camera.CFrame.Position, targetPos)
    local smoothness      = KuraiConfig.CamLock.Smoothness
    Camera.CFrame         = Camera.CFrame:Lerp(targetCFrame, 1 - smoothness)
end

function CamLock.SilentAim(ray)
    if not KuraiConfig.CamLock.SilentAim then return ray end
    if not CamLock.Active or not CamLock.Target then return ray end
    
    local targetPos = CamLock.GetTargetPosition(CamLock.Target)
    if not targetPos then return ray end
    
    return Ray.new(ray.Origin, (targetPos - ray.Origin).Unit * ray.Direction.Magnitude)
end

-- ============================================================
--                     PLAYER MODIFICATIONS
-- ============================================================

local PlayerMods = {}
PlayerMods.Connections = {}
PlayerMods.NoclipEnabled = false
PlayerMods.FlyBody      = nil
PlayerMods.FlyGyro      = nil

function PlayerMods.SetWalkSpeed(speed)
    local char = LocalPlayer.Character
    if not char then return end
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = speed end
end

function PlayerMods.SetJumpPower(power)
    local char = LocalPlayer.Character
    if not char then return end
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.JumpPower = power
        hum.UseJumpPower = true
    end
end

function PlayerMods.SetInvisible(state)
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.LocalTransparencyModifier = state and 1 or 0
        end
        if part:IsA("Decal") or part:IsA("Texture") then
            part.Transparency = state and 1 or 0
        end
    end
end

function PlayerMods.SetNoClip(state)
    PlayerMods.NoclipEnabled = state
end

function PlayerMods.SetFly(state)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp  = char:FindFirstChild("HumanoidRootPart")
    local hum  = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    
    if state then
        hum.PlatformStand = true
        
        local bg = Instance.new("BodyGyro", hrp)
        bg.P           = 9e4
        bg.MaxTorque   = Vector3.new(9e9, 9e9, 9e9)
        bg.CFrame      = hrp.CFrame
        PlayerMods.FlyGyro = bg
        
        local bv = Instance.new("BodyVelocity", hrp)
        bv.Velocity    = Vector3.zero
        bv.MaxForce    = Vector3.new(9e9, 9e9, 9e9)
        PlayerMods.FlyBody = bv
    else
        hum.PlatformStand = false
        if PlayerMods.FlyGyro then PlayerMods.FlyGyro:Destroy() PlayerMods.FlyGyro = nil end
        if PlayerMods.FlyBody then PlayerMods.FlyBody:Destroy() PlayerMods.FlyBody = nil end
    end
end

function PlayerMods.FlyUpdate()
    if not KuraiConfig.Player.FlyEnabled then return end
    if not PlayerMods.FlyBody or not PlayerMods.FlyGyro then return end
    
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local camCF  = Camera.CFrame
    local dir    = Vector3.zero
    local speed  = KuraiConfig.Player.FlySpeed
    
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + camCF.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - camCF.LookVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - camCF.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + camCF.RightVector end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0,1,0) end
    
    if dir.Magnitude > 0 then
        PlayerMods.FlyBody.Velocity = dir.Unit * speed
    else
        PlayerMods.FlyBody.Velocity = Vector3.zero
    end
    
    PlayerMods.FlyGyro.CFrame = camCF
end

function PlayerMods.InfiniteJump()
    local conn = UserInputService.JumpRequest:Connect(function()
        if not KuraiConfig.Player.InfiniteJump then return end
        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end)
    table.insert(PlayerMods.Connections, conn)
end

function PlayerMods.AntiAFK()
    LocalPlayer.Idled:Connect(function()
        if KuraiConfig.Misc.AntiAFK then
            game:GetService("VirtualUser"):CaptureController()
            game:GetService("VirtualUser"):ClickButton2(Vector2.new())
        end
    end)
end

function PlayerMods.Update()
    -- Walk Speed
    if KuraiConfig.Player.WalkSpeedEnabled then
        PlayerMods.SetWalkSpeed(KuraiConfig.Player.WalkSpeed)
    end
    
    -- Jump Power
    if KuraiConfig.Player.JumpPowerEnabled then
        PlayerMods.SetJumpPower(KuraiConfig.Player.JumpPower)
    end
    
    -- Noclip
    if PlayerMods.NoclipEnabled then
        local char = LocalPlayer.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
    
    -- Fly
    PlayerMods.FlyUpdate()
    
    -- Anti-Fling
    if KuraiConfig.Player.AntiFling then
        local char = LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local vel = hrp.Velocity
                if vel.Magnitude > 200 then
                    hrp.Velocity = Vector3.zero
                end
            end
        end
    end
end

-- ============================================================
--                      TARGET SYSTEM
-- ============================================================

local TargetSys = {}
TargetSys.LoopConnection = nil
TargetSys.FlingForce     = nil

function TargetSys.FlingPlayer(player, power)
    local char = player and player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local selfChar = LocalPlayer.Character
    if not selfChar then return end
    local selfHRP = selfChar:FindFirstChild("HumanoidRootPart")
    if not selfHRP then return end
    
    -- Teleport close then fling
    local originalPos = selfHRP.CFrame
    selfHRP.CFrame    = hrp.CFrame * CFrame.new(0, 0, -2)
    
    wait(0.05)
    
    local bv = Instance.new("BodyVelocity")
    bv.Velocity  = (hrp.Position - selfHRP.Position).Unit * power
    bv.MaxForce  = Vector3.new(math.huge, math.huge, math.huge)
    bv.Parent    = hrp
    
    game:GetService("Debris"):AddItem(bv, 0.2)
    
    -- Reset self pos
    task.delay(0.15, function()
        if selfHRP and selfHRP.Parent then
            selfHRP.CFrame = originalPos
        end
    end)
end

function TargetSys.SpectatePlayer(player)
    if not player or not player.Character then return end
    local cam = Workspace.CurrentCamera
    cam.CameraSubject = player.Character:FindFirstChildOfClass("Humanoid")
    cam.CameraType    = Enum.CameraType.Follow
end

function TargetSys.StopSpectate()
    local cam = Workspace.CurrentCamera
    local char = LocalPlayer.Character
    if char then
        cam.CameraSubject = char:FindFirstChildOfClass("Humanoid")
    end
    cam.CameraType = Enum.CameraType.Custom
end

function TargetSys.TeleportTo(player)
    if not player or not player.Character then return end
    local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
    if not targetHRP then return end
    
    local selfChar = LocalPlayer.Character
    if not selfChar then return end
    local selfHRP = selfChar:FindFirstChild("HumanoidRootPart")
    if not selfHRP then return end
    
    selfHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, -3)
end

function TargetSys.LoopGoTo(player)
    if TargetSys.LoopConnection then
        TargetSys.LoopConnection:Disconnect()
        TargetSys.LoopConnection = nil
    end
    if not player then return end
    
    TargetSys.LoopConnection = RunService.Heartbeat:Connect(function()
        if not KuraiConfig.Target.LoopGoToTarget then
            TargetSys.LoopConnection:Disconnect()
            TargetSys.LoopConnection = nil
            return
        end
        TargetSys.TeleportTo(player)
    end)
end

function TargetSys.KillAura()
    if not KuraiConfig.Target.KillAura then return end
    
    local selfChar = LocalPlayer.Character
    if not selfChar then return end
    local selfHRP = selfChar:FindFirstChild("HumanoidRootPart")
    if not selfHRP then return end
    
    -- Check if local player is murderer
    if Utils.GetRole(LocalPlayer) ~= "Murderer" then return end
    
    for _, p in pairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        if not p.Character then continue end
        local hrp = p.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        local dist = (selfHRP.Position - hrp.Position).Magnitude
        if dist <= KuraiConfig.Target.KillAuraRadius then
            -- Simulate knife hit via proximity
            local hum = p.Character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.Health = 0
            end
        end
    end
end

-- ============================================================
--                      AUTO FARM SYSTEM
-- ============================================================

local AutoFarm = {}
AutoFarm.Connection = nil

function AutoFarm.GetFarmTarget()
    local mode = KuraiConfig.Farm.Mode
    
    if mode == "Murderer" then
        return Utils.GetMurderer()
    elseif mode == "Sheriff" then
        return Utils.GetSheriff()
    elseif mode == "Randomize" then
        local all = {}
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then table.insert(all, p) end
        end
        if #all > 0 then
            return all[math.random(1, #all)]
        end
    else -- Nearest
        return Utils.GetNearestPlayer()
    end
end

function AutoFarm.Start()
    if AutoFarm.Connection then AutoFarm.Connection:Disconnect() end
    
    AutoFarm.Connection = RunService.Heartbeat:Connect(function()
        if not KuraiConfig.Farm.Enabled then
            AutoFarm.Connection:Disconnect()
            AutoFarm.Connection = nil
            return
        end
        
        local target = AutoFarm.GetFarmTarget()
        if not target or not target.Character then return end
        
        local selfChar = LocalPlayer.Character
        if not selfChar then return end
        local selfHRP = selfChar:FindFirstChild("HumanoidRootPart")
        if not selfHRP then return end
        
        local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
        if not targetHRP then return end
        
        selfHRP.CFrame = targetHRP.CFrame * CFrame.new(0, 0, -4)
        
        -- Auto Grab Gun
        if KuraiConfig.Farm.AutoGrabGun then
            AutoFarm.GrabGun()
        end
    end)
end

function AutoFarm.GrabGun()
    -- Find dropped gun in workspace
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Tool") or obj:IsA("Model") then
            if obj.Name:lower():find("gun") or obj.Name:lower():find("revolver") then
                -- Try to pick up
                local char = LocalPlayer.Character
                if not char then return end
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if not hrp then return end
                
                local rootPart = obj:FindFirstChildOfClass("BasePart") or obj:IsA("Tool") and obj:FindFirstChild("Handle")
                if rootPart then
                    local dist = (hrp.Position - rootPart.Position).Magnitude
                    if dist < 20 then
                        hrp.CFrame = CFrame.new(rootPart.Position + Vector3.new(0, 3, 0))
                    end
                end
            end
        end
    end
end

-- ============================================================
--                      MISC FEATURES
-- ============================================================

local MiscFeatures = {}
MiscFeatures.ChamsInstances = {}

function MiscFeatures.SetChams(player, state, color)
    local char = player and player.Character
    if not char then return end
    
    if state then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                local sel = Instance.new("SelectionBox", CoreGui)
                sel.Adornee     = part
                sel.Color3      = color or KuraiConfig.Misc.ChamsColor
                sel.LineThickness = 0.02
                sel.SurfaceTransparency = 0.5
                sel.SurfaceColor3 = color or KuraiConfig.Misc.ChamsColor
                table.insert(MiscFeatures.ChamsInstances, sel)
            end
        end
    else
        for _, sel in pairs(MiscFeatures.ChamsInstances) do
            pcall(sel.Destroy, sel)
        end
        MiscFeatures.ChamsInstances = {}
    end
end

function MiscFeatures.SetFullbright(state)
    Lighting.Brightness  = state and 2 or 1
    Lighting.ClockTime   = state and 14 or Lighting.ClockTime
    Lighting.FogEnd      = state and 100000 or 100000
    Lighting.GlobalShadows = not state
    Lighting.Ambient     = state and Color3.fromRGB(255,255,255) or Color3.fromRGB(70,70,70)
    Lighting.OutdoorAmbient = state and Color3.fromRGB(255,255,255) or Color3.fromRGB(127,127,127)
end

function MiscFeatures.SetLowGraphics(state)
    if state then
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        Lighting.GlobalShadows  = false
        for _, p in pairs(Players:GetPlayers()) do
            if p.Character then
                for _, d in pairs(p.Character:GetDescendants()) do
                    if d:IsA("ParticleEmitter") or d:IsA("Trail") or d:IsA("Beam") then
                        d.Enabled = false
                    end
                end
            end
        end
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
                obj.Enabled = false
            end
        end
    else
        settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
        Lighting.GlobalShadows = true
    end
end

function MiscFeatures.SetHighGraphics(state)
    if state then
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level21
    else
        settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
    end
end

function MiscFeatures.SetFOV(fov)
    Camera.FieldOfView = fov
end

function MiscFeatures.SetSkybox(id)
    local sky = Lighting:FindFirstChildOfClass("Sky")
    if not sky then
        sky = Instance.new("Sky", Lighting)
    end
    
    if id then
        sky.SkyboxBk = id
        sky.SkyboxDn = id
        sky.SkyboxFt = id
        sky.SkyboxLf = id
        sky.SkyboxRt = id
        sky.SkyboxUp = id
    else
        sky:Destroy()
    end
end

function MiscFeatures.RainbowChams()
    if not KuraiConfig.Misc.RainbowChams then return end
    local t = tick()
    local r = math.abs(math.sin(t * 0.5))
    local g = math.abs(math.sin(t * 0.5 + 2))
    local b = math.abs(math.sin(t * 0.5 + 4))
    local col = Color3.new(r, g, b)
    
    for _, sel in pairs(MiscFeatures.ChamsInstances) do
        pcall(function()
            sel.Color3        = col
            sel.SurfaceColor3 = col
        end)
    end
end

function MiscFeatures.ChatSpy()
    Players.PlayerAdded:Connect(function(p)
        p.Chatted:Connect(function(msg)
            if KuraiConfig.Misc.ChatSpy then
                print("[KuraiSpy] " .. p.DisplayName .. ": " .. msg)
                if KuraiConfig.Webhook.LogChat then
                    Utils.SendWebhook({
                        title       = "Chat Spy",
                        description = "**" .. p.DisplayName .. "**: " .. msg,
                        color       = 0xCC0000,
                    })
                end
            end
        end)
    end)
    
    for _, p in pairs(Players:GetPlayers()) do
        p.Chatted:Connect(function(msg)
            if KuraiConfig.Misc.ChatSpy then
                print("[KuraiSpy] " .. p.DisplayName .. ": " .. msg)
            end
        end)
    end
end

-- ============================================================
--                    CURSOR / CROSSHAIR
-- ============================================================

local CursorSystem = {}
CursorSystem.CrosshairGui  = nil
CursorSystem.SpinAngle     = 0
CursorSystem.Presets = {
    ["Precision Dot"] = {
        Type    = "ImageLabel",
        Image   = "rbxassetid://14459536428",
        Size    = UDim2.new(0, 24, 0, 24),
    },
    ["Aim Cross"] = {
        Type    = "ImageLabel",
        Image   = "rbxassetid://14459540188",
        Size    = UDim2.new(0, 24, 0, 24),
    },
    ["Blue Spec"] = {
        Type    = "ImageLabel",
        Image   = "rbxassetid://14459542670",
        Size    = UDim2.new(0, 20, 0, 20),
    },
    ["Circle Dot"] = {
        Type    = "ImageLabel",
        Image   = "rbxassetid://14459545124",
        Size    = UDim2.new(0, 22, 0, 22),
    },
    ["Kurai Cross"] = {
        Type    = "Frame",
        Size    = UDim2.new(0, 20, 0, 20),
        Color   = Color3.fromRGB(220, 0, 0),
    },
}

function CursorSystem.CreateGui()
    -- Remove old
    if CursorSystem.CrosshairGui then
        CursorSystem.CrosshairGui:Destroy()
    end
    
    local gui = Instance.new("ScreenGui", PlayerGui)
    gui.Name            = "KuraiCrosshair"
    gui.ResetOnSpawn    = false
    gui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
    
    local center = Instance.new("Frame", gui)
    center.Name             = "Center"
    center.BackgroundTransparency = 1
    center.AnchorPoint      = Vector2.new(0.5, 0.5)
    center.Position         = UDim2.new(0.5, 0, 0.5, 0)
    center.Size             = UDim2.new(0, 40, 0, 40)
    
    CursorSystem.CrosshairGui = gui
    CursorSystem.CenterFrame  = center
    
    return gui
end

function CursorSystem.SetCrosshair(presetName)
    if not CursorSystem.CrosshairGui then
        CursorSystem.CreateGui()
    end
    
    -- Clear center
    for _, c in pairs(CursorSystem.CenterFrame:GetChildren()) do c:Destroy() end
    
    local preset = CursorSystem.Presets[presetName]
    if not preset then return end
    
    KuraiConfig.Cursor.Selected = presetName
    
    if preset.Type == "ImageLabel" then
        local img = Instance.new("ImageLabel", CursorSystem.CenterFrame)
        img.BackgroundTransparency = 1
        img.Image       = preset.Image
        img.Size        = preset.Size
        img.AnchorPoint = Vector2.new(0.5, 0.5)
        img.Position    = UDim2.new(0.5, 0, 0.5, 0)
    elseif preset.Type == "Frame" then
        -- Custom cross frame
        local hBar = Instance.new("Frame", CursorSystem.CenterFrame)
        hBar.BackgroundColor3 = preset.Color
        hBar.BorderSizePixel  = 0
        hBar.AnchorPoint      = Vector2.new(0.5, 0.5)
        hBar.Size             = UDim2.new(0, 16, 0, 2)
        hBar.Position         = UDim2.new(0.5, 0, 0.5, 0)
        
        local vBar = Instance.new("Frame", CursorSystem.CenterFrame)
        vBar.BackgroundColor3 = preset.Color
        vBar.BorderSizePixel  = 0
        vBar.AnchorPoint      = Vector2.new(0.5, 0.5)
        vBar.Size             = UDim2.new(0, 2, 0, 16)
        vBar.Position         = UDim2.new(0.5, 0, 0.5, 0)
        
        local dot = Instance.new("Frame", CursorSystem.CenterFrame)
        dot.BackgroundColor3 = preset.Color
        dot.BorderSizePixel  = 0
        dot.AnchorPoint      = Vector2.new(0.5, 0.5)
        dot.Size             = UDim2.new(0, 4, 0, 4)
        dot.Position         = UDim2.new(0.5, 0, 0.5, 0)
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
    end
end

function CursorSystem.Update(dt)
    if not CursorSystem.CenterFrame then return end
    if not KuraiConfig.Cursor.CustomCrosshair then
        if CursorSystem.CrosshairGui then
            CursorSystem.CrosshairGui.Enabled = false
        end
        return
    end
    
    if CursorSystem.CrosshairGui then
        CursorSystem.CrosshairGui.Enabled = true
    end
    
    if KuraiConfig.Cursor.SpinCrosshair then
        CursorSystem.SpinAngle = (CursorSystem.SpinAngle + KuraiConfig.Cursor.SpinSpeed * dt * 60) % 360
        CursorSystem.CenterFrame.Rotation = CursorSystem.SpinAngle
    else
        CursorSystem.CenterFrame.Rotation = 0
    end
end

-- ============================================================
--                    WEBHOOK SYSTEM
-- ============================================================

local WebhookSys = {}

function WebhookSys.LogRoles()
    if not KuraiConfig.Webhook.LogRoles then return end
    local fields = {}
    for _, p in pairs(Players:GetPlayers()) do
        table.insert(fields, {
            name   = p.DisplayName,
            value  = Utils.GetRole(p),
            inline = true,
        })
    end
    Utils.SendWebhook({
        title       = "Round Started — Roles",
        description = "Server: " .. game.PlaceId .. " | Players: " .. #Players:GetPlayers(),
        color       = 0xCC0000,
        fields      = fields,
        footer      = { text = "KuraiSoftware v" .. KuraiConfig.Version },
    })
end

function WebhookSys.LogKill(killer, victim)
    if not KuraiConfig.Webhook.LogKills then return end
    Utils.SendWebhook({
        title       = "Kill Logged",
        description = "**" .. (killer and killer.DisplayName or "?") .. "** killed **" .. (victim and victim.DisplayName or "?") .. "**",
        color       = 0xFF0000,
        footer      = { text = "KuraiSoftware" },
    })
end

-- ============================================================
--                    CONFIG SAVE / LOAD
-- ============================================================

local ConfigSys = {}
ConfigSys.FolderName = "KuraiSoftware"
ConfigSys.Extension  = ".json"

function ConfigSys.Init()
    pcall(function()
        if not isfolder(ConfigSys.FolderName) then
            makefolder(ConfigSys.FolderName)
        end
    end)
end

function ConfigSys.Save(name)
    name = name or KuraiConfig.Settings.ConfigName
    pcall(function()
        local data = HttpService:JSONEncode(KuraiConfig)
        writefile(ConfigSys.FolderName .. "/" .. name .. ConfigSys.Extension, data)
        Utils.Notification("Config", "Saved: " .. name, 2)
    end)
end

function ConfigSys.Load(name)
    name = name or KuraiConfig.Settings.ConfigName
    pcall(function()
        local path = ConfigSys.FolderName .. "/" .. name .. ConfigSys.Extension
        if isfile(path) then
            local data = readfile(path)
            local t    = HttpService:JSONDecode(data)
            -- Merge
            for k, v in pairs(t) do
                if KuraiConfig[k] then
                    for k2, v2 in pairs(v) do
                        if KuraiConfig[k][k2] ~= nil then
                            KuraiConfig[k][k2] = v2
                        end
                    end
                end
            end
            Utils.Notification("Config", "Loaded: " .. name, 2)
        end
    end)
end

function ConfigSys.List()
    local files = {}
    pcall(function()
        for _, f in pairs(listfiles(ConfigSys.FolderName)) do
            if f:find(ConfigSys.Extension) then
                table.insert(files, f:gsub(ConfigSys.FolderName .. "/", ""):gsub(ConfigSys.Extension, ""))
            end
        end
    end)
    return files
end

-- ============================================================
--                     WATERMARK / HUD
-- ============================================================

local Watermark = {}
Watermark.Gui = nil

function Watermark.Create()
    local gui = Instance.new("ScreenGui", PlayerGui)
    gui.Name            = "KuraiWatermark"
    gui.ResetOnSpawn    = false
    gui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
    
    local frame = Instance.new("Frame", gui)
    frame.BackgroundColor3    = Color3.fromRGB(12, 0, 0)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel     = 0
    frame.Position            = UDim2.new(0, 10, 0, 10)
    frame.Size                = UDim2.new(0, 200, 0, 26)
    
    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 4)
    
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color      = Color3.fromRGB(180, 0, 0)
    stroke.Thickness  = 1
    stroke.Transparency = 0.5
    
    local label = Instance.new("TextLabel", frame)
    label.Name                  = "Label"
    label.BackgroundTransparency = 1
    label.Size                  = UDim2.new(1, 0, 1, 0)
    label.Font                  = Enum.Font.GothamBold
    label.TextColor3            = Color3.fromRGB(255, 255, 255)
    label.TextSize              = 12
    label.Text                  = "KuraiSoftware v" .. KuraiConfig.Version
    label.TextXAlignment        = Enum.TextXAlignment.Center
    
    Watermark.Gui   = gui
    Watermark.Frame = frame
    Watermark.Label = label
end

function Watermark.Update()
    if not Watermark.Label then return end
    if not KuraiConfig.Settings.WatermarkEnabled then
        if Watermark.Gui then Watermark.Gui.Enabled = false end
        return
    end
    if Watermark.Gui then Watermark.Gui.Enabled = true end
    
    local fps   = math.floor(1 / RunService.RenderStepped:Wait())
    local ping  = LocalPlayer:GetNetworkPing() * 1000
    Watermark.Label.Text = string.format(
        "KuraiSoftware | FPS: %d | Ping: %dms",
        fps, math.floor(ping)
    )
end

-- ============================================================
--                   MAIN GUI SYSTEM
-- ============================================================
-- Style: RuzHub x Vertex Fusion
-- Dark crimson / charcoal / minimal

local GUI = {}
GUI.Visible     = false
GUI.ActiveTab   = "ESP"
GUI.DragActive  = false
GUI.DragOffset  = Vector2.zero

-- Color tokens
local Colors = {
    BG        = Color3.fromRGB(10,  0,  0),
    BG2       = Color3.fromRGB(18,  5,  5),
    BG3       = Color3.fromRGB(28, 10, 10),
    Accent    = Color3.fromRGB(200,  0,  0),
    AccentSub = Color3.fromRGB(140,  0,  0),
    Text      = Color3.fromRGB(240, 240, 240),
    TextDim   = Color3.fromRGB(160, 160, 160),
    Toggle    = Color3.fromRGB(55,  55,  55),
    ToggleOn  = Color3.fromRGB(180,  0,  0),
    Border    = Color3.fromRGB(60,  20,  20),
    Sidebar   = Color3.fromRGB(14,  4,  4),
    White     = Color3.fromRGB(255, 255, 255),
    Green     = Color3.fromRGB(0, 200, 80),
}

function GUI.Create()
    -- Clean up old
    local oldGui = PlayerGui:FindFirstChild("KuraiSoftwareGUI")
    if oldGui then oldGui:Destroy() end
    
    local ScreenGui = Instance.new("ScreenGui", PlayerGui)
    ScreenGui.Name              = "KuraiSoftwareGUI"
    ScreenGui.ResetOnSpawn      = false
    ScreenGui.ZIndexBehavior    = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder      = 999
    ScreenGui.Enabled           = false
    
    -- ── Main Window ──
    local Window = Instance.new("Frame", ScreenGui)
    Window.Name                 = "Window"
    Window.BackgroundColor3     = Colors.BG
    Window.BorderSizePixel      = 0
    Window.AnchorPoint          = Vector2.new(0.5, 0.5)
    Window.Position             = UDim2.new(0.5, 0, 0.5, 0)
    Window.Size                 = UDim2.new(0, 620, 0, 420)
    Window.ClipsDescendants     = true
    
    local WindowCorner = Instance.new("UICorner", Window)
    WindowCorner.CornerRadius = UDim.new(0, 6)
    
    local WindowStroke = Instance.new("UIStroke", Window)
    WindowStroke.Color      = Colors.Accent
    WindowStroke.Thickness  = 1.5
    WindowStroke.Transparency = 0.4
    
    -- ── Drop Shadow (simulated) ──
    local Shadow = Instance.new("ImageLabel", ScreenGui)
    Shadow.Name                 = "Shadow"
    Shadow.BackgroundTransparency = 1
    Shadow.Image                = "rbxassetid://5554236805"
    Shadow.ImageColor3          = Color3.fromRGB(0, 0, 0)
    Shadow.ImageTransparency    = 0.5
    Shadow.AnchorPoint          = Vector2.new(0.5, 0.5)
    Shadow.Position             = UDim2.new(0.5, 0, 0.5, 12)
    Shadow.Size                 = UDim2.new(0, 680, 0, 480)
    Shadow.ZIndex               = 0
    
    -- ── Title Bar ──
    local TitleBar = Instance.new("Frame", Window)
    TitleBar.Name               = "TitleBar"
    TitleBar.BackgroundColor3   = Colors.BG2
    TitleBar.BorderSizePixel    = 0
    TitleBar.Size               = UDim2.new(1, 0, 0, 36)
    
    local TitleBarStroke = Instance.new("UIStroke", TitleBar)
    TitleBarStroke.Color        = Colors.Border
    TitleBarStroke.Thickness    = 1
    TitleBarStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    
    -- Accent line below title
    local TitleAccent = Instance.new("Frame", TitleBar)
    TitleAccent.BackgroundColor3 = Colors.Accent
    TitleAccent.BorderSizePixel  = 0
    TitleAccent.Position         = UDim2.new(0, 0, 1, -1)
    TitleAccent.Size             = UDim2.new(1, 0, 0, 1)
    
    -- Logo dot
    local LogoDot = Instance.new("Frame", TitleBar)
    LogoDot.BackgroundColor3    = Colors.Accent
    LogoDot.BorderSizePixel     = 0
    LogoDot.AnchorPoint         = Vector2.new(0, 0.5)
    LogoDot.Position            = UDim2.new(0, 12, 0.5, 0)
    LogoDot.Size                = UDim2.new(0, 8, 0, 8)
    Instance.new("UICorner", LogoDot).CornerRadius = UDim.new(1, 0)
    
    local TitleLabel = Instance.new("TextLabel", TitleBar)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Position         = UDim2.new(0, 28, 0, 0)
    TitleLabel.Size             = UDim2.new(0, 200, 1, 0)
    TitleLabel.Font             = Enum.Font.GothamBold
    TitleLabel.TextColor3       = Colors.Text
    TitleLabel.TextSize         = 13
    TitleLabel.Text             = "KuraiSoftware"
    TitleLabel.TextXAlignment   = Enum.TextXAlignment.Left
    
    local SubLabel = Instance.new("TextLabel", TitleBar)
    SubLabel.BackgroundTransparency = 1
    SubLabel.Position           = UDim2.new(0, 28, 0, 16)
    SubLabel.Size               = UDim2.new(0, 200, 0, 16)
    SubLabel.Font               = Enum.Font.Gotham
    SubLabel.TextColor3         = Colors.AccentSub
    SubLabel.TextSize           = 10
    SubLabel.Text               = "Murder Mystery 2  ·  v" .. KuraiConfig.Version
    SubLabel.TextXAlignment     = Enum.TextXAlignment.Left
    
    -- Close button
    local CloseBtn = Instance.new("TextButton", TitleBar)
    CloseBtn.Name               = "CloseBtn"
    CloseBtn.BackgroundColor3   = Color3.fromRGB(180, 0, 0)
    CloseBtn.BorderSizePixel    = 0
    CloseBtn.AnchorPoint        = Vector2.new(1, 0.5)
    CloseBtn.Position           = UDim2.new(1, -10, 0.5, 0)
    CloseBtn.Size               = UDim2.new(0, 20, 0, 20)
    CloseBtn.Font               = Enum.Font.GothamBold
    CloseBtn.TextColor3         = Colors.White
    CloseBtn.TextSize           = 12
    CloseBtn.Text               = "✕"
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 3)
    
    CloseBtn.MouseButton1Click:Connect(function()
        GUI.Toggle(false)
    end)
    
    -- Minimize button
    local MinBtn = Instance.new("TextButton", TitleBar)
    MinBtn.Name                 = "MinBtn"
    MinBtn.BackgroundColor3     = Color3.fromRGB(200, 140, 0)
    MinBtn.BorderSizePixel      = 0
    MinBtn.AnchorPoint          = Vector2.new(1, 0.5)
    MinBtn.Position             = UDim2.new(1, -36, 0.5, 0)
    MinBtn.Size                 = UDim2.new(0, 20, 0, 20)
    MinBtn.Font                 = Enum.Font.GothamBold
    MinBtn.TextColor3           = Colors.White
    MinBtn.TextSize             = 14
    MinBtn.Text                 = "–"
    Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 3)
    
    GUI.Minimized = false
    MinBtn.MouseButton1Click:Connect(function()
        GUI.Minimized = not GUI.Minimized
        Utils.Tween(Window, { Size = GUI.Minimized and UDim2.new(0, 620, 0, 36) or UDim2.new(0, 620, 0, 420) }, 0.25)
    end)
    
    -- ── Drag ──
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            GUI.DragActive = true
            GUI.DragOffset = Vector2.new(Window.Position.X.Offset, Window.Position.Y.Offset)
                           - Vector2.new(input.Position.X, input.Position.Y)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if not GUI.DragActive then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            local newPos = Vector2.new(input.Position.X, input.Position.Y) + GUI.DragOffset
            Window.Position = UDim2.new(0, newPos.X, 0, newPos.Y)
            Shadow.Position = UDim2.new(0, newPos.X, 0, newPos.Y + 12)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            GUI.DragActive = false
        end
    end)
    
    -- ── Sidebar ──
    local Sidebar = Instance.new("Frame", Window)
    Sidebar.Name                = "Sidebar"
    Sidebar.BackgroundColor3    = Colors.Sidebar
    Sidebar.BorderSizePixel     = 0
    Sidebar.Position            = UDim2.new(0, 0, 0, 36)
    Sidebar.Size                = UDim2.new(0, 110, 1, -36)
    
    local SidebarStroke = Instance.new("UIStroke", Sidebar)
    SidebarStroke.Color         = Colors.Border
    SidebarStroke.Thickness     = 1
    SidebarStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    
    -- Player info at bottom of sidebar
    local PlayerInfo = Instance.new("Frame", Sidebar)
    PlayerInfo.BackgroundColor3 = Colors.BG3
    PlayerInfo.BorderSizePixel  = 0
    PlayerInfo.AnchorPoint      = Vector2.new(0, 1)
    PlayerInfo.Position         = UDim2.new(0, 0, 1, 0)
    PlayerInfo.Size             = UDim2.new(1, 0, 0, 48)
    
    local PlayerAvatar = Instance.new("ImageLabel", PlayerInfo)
    PlayerAvatar.BackgroundTransparency = 1
    PlayerAvatar.Position       = UDim2.new(0, 6, 0.5, -14)
    PlayerAvatar.Size           = UDim2.new(0, 28, 0, 28)
    PlayerAvatar.Image          = "rbxthumb://type=AvatarHeadShot&id=" .. LocalPlayer.UserId .. "&w=48&h=48"
    Instance.new("UICorner", PlayerAvatar).CornerRadius = UDim.new(1, 0)
    
    local PlayerName = Instance.new("TextLabel", PlayerInfo)
    PlayerName.BackgroundTransparency = 1
    PlayerName.Position         = UDim2.new(0, 40, 0, 8)
    PlayerName.Size             = UDim2.new(1, -46, 0, 14)
    PlayerName.Font             = Enum.Font.GothamBold
    PlayerName.TextColor3       = Colors.Text
    PlayerName.TextSize         = 11
    PlayerName.Text             = LocalPlayer.DisplayName
    PlayerName.TextXAlignment   = Enum.TextXAlignment.Left
    PlayerName.TextTruncate     = Enum.TextTruncate.AtEnd
    
    local PlayerAt = Instance.new("TextLabel", PlayerInfo)
    PlayerAt.BackgroundTransparency = 1
    PlayerAt.Position           = UDim2.new(0, 40, 0, 24)
    PlayerAt.Size               = UDim2.new(1, -46, 0, 12)
    PlayerAt.Font               = Enum.Font.Gotham
    PlayerAt.TextColor3         = Colors.AccentSub
    PlayerAt.TextSize           = 10
    PlayerAt.Text               = "@" .. LocalPlayer.Name
    PlayerAt.TextXAlignment     = Enum.TextXAlignment.Left
    PlayerAt.TextTruncate       = Enum.TextTruncate.AtEnd
    
    -- Tab list
    local TabList = Instance.new("ScrollingFrame", Sidebar)
    TabList.Name                = "TabList"
    TabList.BackgroundTransparency = 1
    TabList.BorderSizePixel     = 0
    TabList.Position            = UDim2.new(0, 0, 0, 0)
    TabList.Size                = UDim2.new(1, 0, 1, -54)
    TabList.ScrollBarThickness  = 0
    TabList.CanvasSize          = UDim2.new(0, 0, 0, 0)
    
    local TabListLayout = Instance.new("UIListLayout", TabList)
    TabListLayout.Padding        = UDim.new(0, 1)
    TabListLayout.SortOrder      = Enum.SortOrder.LayoutOrder
    
    local TabPad = Instance.new("UIPadding", TabList)
    TabPad.PaddingTop = UDim.new(0, 6)
    
    -- Content area
    local ContentArea = Instance.new("Frame", Window)
    ContentArea.Name            = "ContentArea"
    ContentArea.BackgroundTransparency = 1
    ContentArea.Position        = UDim2.new(0, 110, 0, 36)
    ContentArea.Size            = UDim2.new(1, -110, 1, -36)
    ContentArea.ClipsDescendants = true
    
    GUI.ScreenGui   = ScreenGui
    GUI.Window      = Window
    GUI.Shadow      = Shadow
    GUI.TitleBar    = TitleBar
    GUI.Sidebar     = Sidebar
    GUI.TabList     = TabList
    GUI.ContentArea = ContentArea
    GUI.Tabs        = {}
    GUI.TabButtons  = {}
    GUI.TabFrames   = {}
    
    -- Create all tabs
    GUI.CreateTabs()
    
    return ScreenGui
end

function GUI.CreateTabButton(name, icon, order)
    local btn = Instance.new("TextButton", GUI.TabList)
    btn.Name                    = name
    btn.BackgroundColor3        = Colors.BG
    btn.BackgroundTransparency  = 1
    btn.BorderSizePixel         = 0
    btn.Size                    = UDim2.new(1, 0, 0, 34)
    btn.LayoutOrder             = order
    btn.AutoButtonColor         = false
    
    -- Active indicator bar
    local ActiveBar = Instance.new("Frame", btn)
    ActiveBar.Name              = "ActiveBar"
    ActiveBar.BackgroundColor3  = Colors.Accent
    ActiveBar.BorderSizePixel   = 0
    ActiveBar.Position          = UDim2.new(0, 0, 0.15, 0)
    ActiveBar.Size              = UDim2.new(0, 3, 0.7, 0)
    ActiveBar.Visible           = false
    Instance.new("UICorner", ActiveBar).CornerRadius = UDim.new(0, 2)
    
    local IconLabel = Instance.new("TextLabel", btn)
    IconLabel.BackgroundTransparency = 1
    IconLabel.Position          = UDim2.new(0, 12, 0.5, -8)
    IconLabel.Size              = UDim2.new(0, 16, 0, 16)
    IconLabel.Font              = Enum.Font.GothamBold
    IconLabel.TextColor3        = Colors.TextDim
    IconLabel.TextSize          = 14
    IconLabel.Text              = icon or "•"
    
    local NameLabel = Instance.new("TextLabel", btn)
    NameLabel.BackgroundTransparency = 1
    NameLabel.Position          = UDim2.new(0, 12, 0.5, 2)
    NameLabel.Size              = UDim2.new(1, -16, 0, 14)
    NameLabel.Font              = Enum.Font.Gotham
    NameLabel.TextColor3        = Colors.TextDim
    NameLabel.TextSize          = 11
    NameLabel.Text              = name
    NameLabel.TextXAlignment    = Enum.TextXAlignment.Left
    
    btn.MouseEnter:Connect(function()
        if GUI.ActiveTab ~= name then
            Utils.Tween(btn, { BackgroundTransparency = 0.85, BackgroundColor3 = Colors.BG3 }, 0.15)
        end
    end)
    
    btn.MouseLeave:Connect(function()
        if GUI.ActiveTab ~= name then
            Utils.Tween(btn, { BackgroundTransparency = 1 }, 0.15)
        end
    end)
    
    btn.MouseButton1Click:Connect(function()
        GUI.SwitchTab(name)
    end)
    
    GUI.TabButtons[name] = {
        Button    = btn,
        ActiveBar = ActiveBar,
        Icon      = IconLabel,
        Name      = NameLabel,
    }
    
    return btn
end

function GUI.CreateTabFrame(name)
    local frame = Instance.new("ScrollingFrame", GUI.ContentArea)
    frame.Name                  = name .. "Tab"
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel       = 0
    frame.Size                  = UDim2.new(1, 0, 1, 0)
    frame.ScrollBarThickness    = 3
    frame.ScrollBarImageColor3  = Colors.Accent
    frame.CanvasSize            = UDim2.new(0, 0, 0, 0)
    frame.AutomaticCanvasSize   = Enum.AutomaticSize.Y
    frame.Visible               = false
    
    local Pad = Instance.new("UIPadding", frame)
    Pad.PaddingTop    = UDim.new(0, 10)
    Pad.PaddingLeft   = UDim.new(0, 12)
    Pad.PaddingRight  = UDim.new(0, 12)
    Pad.PaddingBottom = UDim.new(0, 10)
    
    local Layout = Instance.new("UIListLayout", frame)
    Layout.Padding    = UDim.new(0, 6)
    Layout.SortOrder  = Enum.SortOrder.LayoutOrder
    
    GUI.TabFrames[name] = frame
    return frame
end

function GUI.SwitchTab(name)
    GUI.ActiveTab = name
    
    for tabName, frame in pairs(GUI.TabFrames) do
        frame.Visible = (tabName == name)
    end
    
    for tabName, info in pairs(GUI.TabButtons) do
        local active = tabName == name
        info.ActiveBar.Visible = active
        Utils.Tween(info.Name, {
            TextColor3 = active and Colors.Text or Colors.TextDim
        }, 0.15)
        Utils.Tween(info.Icon, {
            TextColor3 = active and Colors.Accent or Colors.TextDim
        }, 0.15)
        if active then
            Utils.Tween(info.Button, { BackgroundTransparency = 0.7, BackgroundColor3 = Colors.BG3 }, 0.15)
        else
            Utils.Tween(info.Button, { BackgroundTransparency = 1 }, 0.15)
        end
    end
end

-- ── Section Header ──
function GUI.AddSection(parent, text, order)
    local frame = Instance.new("Frame", parent)
    frame.BackgroundTransparency = 1
    frame.Size        = UDim2.new(1, 0, 0, 22)
    frame.LayoutOrder = order or 0
    
    local label = Instance.new("TextLabel", frame)
    label.BackgroundTransparency = 1
    label.Size        = UDim2.new(1, 0, 1, 0)
    label.Font        = Enum.Font.GothamBold
    label.TextColor3  = Colors.Accent
    label.TextSize    = 11
    label.Text        = text:upper()
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local line = Instance.new("Frame", frame)
    line.BackgroundColor3 = Colors.Border
    line.BorderSizePixel  = 0
    line.AnchorPoint      = Vector2.new(0, 1)
    line.Position         = UDim2.new(0, 0, 1, -1)
    line.Size             = UDim2.new(1, 0, 0, 1)
    
    return frame
end

-- ── Toggle ──
function GUI.AddToggle(parent, text, configPath, configKey, callback, order)
    local row = Instance.new("Frame", parent)
    row.BackgroundColor3    = Colors.BG2
    row.BorderSizePixel     = 0
    row.Size                = UDim2.new(1, 0, 0, 32)
    row.LayoutOrder         = order or 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 5)
    
    local stroke = Instance.new("UIStroke", row)
    stroke.Color       = Colors.Border
    stroke.Thickness   = 1
    stroke.Transparency = 0.6
    
    local label = Instance.new("TextLabel", row)
    label.BackgroundTransparency = 1
    label.Position    = UDim2.new(0, 10, 0, 0)
    label.Size        = UDim2.new(1, -60, 1, 0)
    label.Font        = Enum.Font.Gotham
    label.TextColor3  = Colors.Text
    label.TextSize    = 12
    label.Text        = text
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Toggle pill
    local pill = Instance.new("Frame", row)
    pill.AnchorPoint      = Vector2.new(1, 0.5)
    pill.Position         = UDim2.new(1, -10, 0.5, 0)
    pill.Size             = UDim2.new(0, 40, 0, 20)
    pill.BackgroundColor3 = Colors.Toggle
    pill.BorderSizePixel  = 0
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)
    
    local pillCircle = Instance.new("Frame", pill)
    pillCircle.BackgroundColor3 = Colors.White
    pillCircle.BorderSizePixel  = 0
    pillCircle.Size             = UDim2.new(0, 14, 0, 14)
    pillCircle.Position         = UDim2.new(0, 3, 0.5, -7)
    Instance.new("UICorner", pillCircle).CornerRadius = UDim.new(1, 0)
    
    local function GetState()
        if configPath then return KuraiConfig[configPath][configKey]
        else return false end
    end
    
    local function SetState(state)
        if configPath then KuraiConfig[configPath][configKey] = state end
        Utils.Tween(pill, { BackgroundColor3 = state and Colors.ToggleOn or Colors.Toggle }, 0.2)
        Utils.Tween(pillCircle, {
            Position = state and UDim2.new(0, 23, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
        }, 0.2)
        if callback then callback(state) end
    end
    
    -- Init visual
    task.defer(function() SetState(GetState()) end)
    
    local btn = Instance.new("TextButton", row)
    btn.BackgroundTransparency = 1
    btn.Size        = UDim2.new(1, 0, 1, 0)
    btn.Text        = ""
    btn.ZIndex      = 5
    
    btn.MouseEnter:Connect(function()
        Utils.Tween(row, { BackgroundColor3 = Colors.BG3 }, 0.15)
    end)
    btn.MouseLeave:Connect(function()
        Utils.Tween(row, { BackgroundColor3 = Colors.BG2 }, 0.15)
    end)
    btn.MouseButton1Click:Connect(function()
        SetState(not GetState())
    end)
    
    return row, SetState
end

-- ── Slider ──
function GUI.AddSlider(parent, text, configPath, configKey, min, max, callback, order)
    local frame = Instance.new("Frame", parent)
    frame.BackgroundColor3  = Colors.BG2
    frame.BorderSizePixel   = 0
    frame.Size              = UDim2.new(1, 0, 0, 46)
    frame.LayoutOrder       = order or 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 5)
    
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color       = Colors.Border
    stroke.Thickness   = 1
    stroke.Transparency = 0.6
    
    local label = Instance.new("TextLabel", frame)
    label.BackgroundTransparency = 1
    label.Position  = UDim2.new(0, 10, 0, 6)
    label.Size      = UDim2.new(1, -60, 0, 16)
    label.Font      = Enum.Font.Gotham
    label.TextColor3 = Colors.Text
    label.TextSize  = 12
    label.Text      = text
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local valLabel = Instance.new("TextLabel", frame)
    valLabel.BackgroundTransparency = 1
    valLabel.AnchorPoint = Vector2.new(1, 0)
    valLabel.Position    = UDim2.new(1, -10, 0, 6)
    valLabel.Size        = UDim2.new(0, 50, 0, 16)
    valLabel.Font        = Enum.Font.GothamBold
    valLabel.TextColor3  = Colors.Accent
    valLabel.TextSize    = 12
    valLabel.TextXAlignment = Enum.TextXAlignment.Right
    
    local track = Instance.new("Frame", frame)
    track.BackgroundColor3 = Colors.BG3
    track.BorderSizePixel  = 0
    track.Position         = UDim2.new(0, 10, 0, 30)
    track.Size             = UDim2.new(1, -20, 0, 6)
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    
    local fill = Instance.new("Frame", track)
    fill.BackgroundColor3 = Colors.Accent
    fill.BorderSizePixel  = 0
    fill.Size             = UDim2.new(0, 0, 1, 0)
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    
    local knob = Instance.new("Frame", track)
    knob.BackgroundColor3 = Colors.White
    knob.BorderSizePixel  = 0
    knob.AnchorPoint      = Vector2.new(0.5, 0.5)
    knob.Position         = UDim2.new(0, 0, 0.5, 0)
    knob.Size             = UDim2.new(0, 12, 0, 12)
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    
    local function GetValue()
        if configPath then return KuraiConfig[configPath][configKey] or min
        else return min end
    end
    
    local function SetValue(v)
        v = math.clamp(Utils.Round(v, 1), min, max)
        if configPath then KuraiConfig[configPath][configKey] = v end
        local pct = (v - min) / (max - min)
        fill.Size           = UDim2.new(pct, 0, 1, 0)
        knob.Position       = UDim2.new(pct, 0, 0.5, 0)
        valLabel.Text       = tostring(v)
        if callback then callback(v) end
    end
    
    task.defer(function() SetValue(GetValue()) end)
    
    local dragging = false
    knob.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)
    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType == Enum.UserInputType.MouseMovement
            or inp.UserInputType == Enum.UserInputType.Touch then
            local trackAbs = track.AbsolutePosition
            local trackSize = track.AbsoluteSize
            local pct = math.clamp((inp.Position.X - trackAbs.X) / trackSize.X, 0, 1)
            SetValue(min + (max - min) * pct)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    return frame, SetValue
end

-- ── Button ──
function GUI.AddButton(parent, text, callback, order)
    local btn = Instance.new("TextButton", parent)
    btn.BackgroundColor3    = Colors.AccentSub
    btn.BorderSizePixel     = 0
    btn.Size                = UDim2.new(1, 0, 0, 30)
    btn.Font                = Enum.Font.GothamBold
    btn.TextColor3          = Colors.White
    btn.TextSize            = 12
    btn.Text                = text
    btn.AutoButtonColor     = false
    btn.LayoutOrder         = order or 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
    
    btn.MouseEnter:Connect(function()
        Utils.Tween(btn, { BackgroundColor3 = Colors.Accent }, 0.15)
    end)
    btn.MouseLeave:Connect(function()
        Utils.Tween(btn, { BackgroundColor3 = Colors.AccentSub }, 0.15)
    end)
    btn.MouseButton1Click:Connect(function()
        Utils.Tween(btn, { BackgroundColor3 = Color3.fromRGB(255, 50, 50) }, 0.08)
        task.delay(0.12, function()
            Utils.Tween(btn, { BackgroundColor3 = Colors.AccentSub }, 0.15)
        end)
        if callback then callback() end
    end)
    
    return btn
end

-- ── Label ──
function GUI.AddLabel(parent, text, order)
    local lbl = Instance.new("TextLabel", parent)
    lbl.BackgroundTransparency = 1
    lbl.Size        = UDim2.new(1, 0, 0, 18)
    lbl.Font        = Enum.Font.Gotham
    lbl.TextColor3  = Colors.TextDim
    lbl.TextSize    = 11
    lbl.Text        = text
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.LayoutOrder = order or 0
    return lbl
end

-- ── Dropdown ──
function GUI.AddDropdown(parent, text, options, configPath, configKey, callback, order)
    local container = Instance.new("Frame", parent)
    container.BackgroundTransparency = 1
    container.Size        = UDim2.new(1, 0, 0, 32)
    container.ClipsDescendants = false
    container.LayoutOrder = order or 0
    container.ZIndex      = 10
    
    local row = Instance.new("Frame", container)
    row.BackgroundColor3  = Colors.BG2
    row.BorderSizePixel   = 0
    row.Size              = UDim2.new(1, 0, 0, 32)
    row.ZIndex            = 10
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 5)
    
    local stroke = Instance.new("UIStroke", row)
    stroke.Color       = Colors.Border
    stroke.Thickness   = 1
    stroke.Transparency = 0.6
    
    local label = Instance.new("TextLabel", row)
    label.BackgroundTransparency = 1
    label.Position    = UDim2.new(0, 10, 0, 0)
    label.Size        = UDim2.new(0.6, 0, 1, 0)
    label.Font        = Enum.Font.Gotham
    label.TextColor3  = Colors.Text
    label.TextSize    = 12
    label.Text        = text
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex      = 11
    
    local valueLabel = Instance.new("TextLabel", row)
    valueLabel.BackgroundTransparency = 1
    valueLabel.AnchorPoint = Vector2.new(1, 0.5)
    valueLabel.Position    = UDim2.new(1, -30, 0.5, 0)
    valueLabel.Size        = UDim2.new(0.4, -30, 0, 14)
    valueLabel.Font        = Enum.Font.GothamBold
    valueLabel.TextColor3  = Colors.Accent
    valueLabel.TextSize    = 11
    valueLabel.Text        = (configPath and KuraiConfig[configPath][configKey]) or (options[1] or "")
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.TextTruncate = Enum.TextTruncate.AtEnd
    valueLabel.ZIndex = 11
    
    local arrow = Instance.new("TextLabel", row)
    arrow.BackgroundTransparency = 1
    arrow.AnchorPoint = Vector2.new(1, 0.5)
    arrow.Position    = UDim2.new(1, -8, 0.5, 0)
    arrow.Size        = UDim2.new(0, 16, 0, 16)
    arrow.Font        = Enum.Font.GothamBold
    arrow.TextColor3  = Colors.TextDim
    arrow.TextSize    = 10
    arrow.Text        = "▾"
    arrow.ZIndex      = 11
    
    -- Dropdown list
    local dropList = Instance.new("Frame", container)
    dropList.BackgroundColor3 = Colors.BG3
    dropList.BorderSizePixel  = 0
    dropList.Position         = UDim2.new(0, 0, 0, 34)
    dropList.Size             = UDim2.new(1, 0, 0, 0)
    dropList.ClipsDescendants = true
    dropList.Visible          = false
    dropList.ZIndex           = 20
    Instance.new("UICorner", dropList).CornerRadius = UDim.new(0, 5)
    
    local dropStroke = Instance.new("UIStroke", dropList)
    dropStroke.Color     = Colors.Border
    dropStroke.Thickness = 1
    
    local dropLayout = Instance.new("UIListLayout", dropList)
    dropLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    for i, opt in ipairs(options) do
        local optBtn = Instance.new("TextButton", dropList)
        optBtn.BackgroundColor3 = Colors.BG3
        optBtn.BackgroundTransparency = 0.5
        optBtn.BorderSizePixel  = 0
        optBtn.Size             = UDim2.new(1, 0, 0, 28)
        optBtn.Font             = Enum.Font.Gotham
        optBtn.TextColor3       = Colors.Text
        optBtn.TextSize         = 11
        optBtn.Text             = opt
        optBtn.LayoutOrder      = i
        optBtn.ZIndex           = 21
        optBtn.AutoButtonColor  = false
        
        optBtn.MouseEnter:Connect(function()
            Utils.Tween(optBtn, { BackgroundColor3 = Colors.BG2, BackgroundTransparency = 0 }, 0.1)
        end)
        optBtn.MouseLeave:Connect(function()
            Utils.Tween(optBtn, { BackgroundColor3 = Colors.BG3, BackgroundTransparency = 0.5 }, 0.1)
        end)
        
        optBtn.MouseButton1Click:Connect(function()
            valueLabel.Text = opt
            if configPath then KuraiConfig[configPath][configKey] = opt end
            if callback then callback(opt) end
            -- Close
            Utils.Tween(dropList, { Size = UDim2.new(1, 0, 0, 0) }, 0.15)
            task.delay(0.15, function() dropList.Visible = false end)
        end)
    end
    
    -- Total height
    local listH = #options * 28 + 4
    
    local open = false
    local toggleBtn = Instance.new("TextButton", row)
    toggleBtn.BackgroundTransparency = 1
    toggleBtn.Size        = UDim2.new(1, 0, 1, 0)
    toggleBtn.Text        = ""
    toggleBtn.ZIndex      = 15
    
    toggleBtn.MouseButton1Click:Connect(function()
        open = not open
        if open then
            dropList.Visible = true
            dropList.Size    = UDim2.new(1, 0, 0, 0)
            Utils.Tween(dropList, { Size = UDim2.new(1, 0, 0, listH) }, 0.18)
            container.Size = UDim2.new(1, 0, 0, 32 + listH + 4)
        else
            Utils.Tween(dropList, { Size = UDim2.new(1, 0, 0, 0) }, 0.15)
            task.delay(0.15, function()
                dropList.Visible = false
                container.Size = UDim2.new(1, 0, 0, 32)
            end)
        end
    end)
    
    return container
end

-- ── Colorpicker (simplified) ──
function GUI.AddColorInfo(parent, text, color, order)
    local row = Instance.new("Frame", parent)
    row.BackgroundColor3    = Colors.BG2
    row.BorderSizePixel     = 0
    row.Size                = UDim2.new(1, 0, 0, 32)
    row.LayoutOrder         = order or 0
    Instance.new("UICorner", row).CornerRadius = UDim.new(0, 5)
    
    local label = Instance.new("TextLabel", row)
    label.BackgroundTransparency = 1
    label.Position    = UDim2.new(0, 10, 0, 0)
    label.Size        = UDim2.new(1, -50, 1, 0)
    label.Font        = Enum.Font.Gotham
    label.TextColor3  = Colors.Text
    label.TextSize    = 12
    label.Text        = text
    label.TextXAlignment = Enum.TextXAlignment.Left
    
    local swatch = Instance.new("Frame", row)
    swatch.BackgroundColor3 = color or Colors.Accent
    swatch.BorderSizePixel  = 0
    swatch.AnchorPoint      = Vector2.new(1, 0.5)
    swatch.Position         = UDim2.new(1, -10, 0.5, 0)
    swatch.Size             = UDim2.new(0, 28, 0, 18)
    Instance.new("UICorner", swatch).CornerRadius = UDim.new(0, 4)
    
    return row, swatch
end

-- ============================================================
--                        TAB: ESP
-- ============================================================

function GUI.CreateESPTab()
    local frame = GUI.CreateTabFrame("ESP")
    
    GUI.AddSection(frame, "ESP General", 1)
    GUI.AddToggle(frame, "Enable ESP", "ESP", "Enabled", function(v)
        if v then ESP.Init() end
    end, 2)
    GUI.AddToggle(frame, "Box ESP", "ESP", "BoxESP", nil, 3)
    GUI.AddToggle(frame, "Name ESP", "ESP", "NameESP", nil, 4)
    GUI.AddToggle(frame, "Distance ESP", "ESP", "DistanceESP", nil, 5)
    GUI.AddToggle(frame, "Health Bar", "ESP", "HealthESP", nil, 6)
    GUI.AddToggle(frame, "Tracer ESP", "ESP", "TracerESP", nil, 7)
    GUI.AddToggle(frame, "Role Tag", "ESP", "RoleESP", nil, 8)
    GUI.AddToggle(frame, "Team Check", "ESP", "TeamCheck", nil, 9)
    
    GUI.AddSection(frame, "Visuals", 10)
    GUI.AddSlider(frame, "Max Distance", "ESP", "MaxDistance", 50, 1000, nil, 11)
    GUI.AddSlider(frame, "Font Size", "ESP", "FontSize", 8, 22, nil, 12)
    GUI.AddSlider(frame, "Box Thickness", "ESP", "BoxThickness", 1, 4, nil, 13)
    
    GUI.AddSection(frame, "Tracer Origin", 14)
    GUI.AddDropdown(frame, "Tracer Origin", {"Bottom", "Center", "Top"}, "ESP", "TracerOrigin", nil, 15)
    
    GUI.AddSection(frame, "Colors", 16)
    GUI.AddColorInfo(frame, "Murderer Color", KuraiConfig.ESP.MurdererColor, 17)
    GUI.AddColorInfo(frame, "Sheriff Color",  KuraiConfig.ESP.SheriffColor,  18)
    GUI.AddColorInfo(frame, "Innocent Color", KuraiConfig.ESP.InnocentColor, 19)
    GUI.AddColorInfo(frame, "Box Color",      KuraiConfig.ESP.BoxColor,      20)
    GUI.AddColorInfo(frame, "Tracer Color",   KuraiConfig.ESP.TracerColor,   21)
    
    return frame
end

-- ============================================================
--                    TAB: CAMLOCK / AIMBOT
-- ============================================================

function GUI.CreateCamLockTab()
    local frame = GUI.CreateTabFrame("CamLock")
    
    GUI.AddSection(frame, "CamLock", 1)
    GUI.AddToggle(frame, "Enable CamLock", "CamLock", "Enabled", nil, 2)
    GUI.AddToggle(frame, "Show FOV Circle", "CamLock", "ShowFOVCircle", nil, 3)
    GUI.AddToggle(frame, "Auto Target", "CamLock", "AutoTarget", nil, 4)
    GUI.AddToggle(frame, "Silent Aim", "CamLock", "SilentAim", nil, 5)
    GUI.AddToggle(frame, "Prediction", "CamLock", "PredictMovement", nil, 6)
    GUI.AddToggle(frame, "Trigger Bot", "CamLock", "TriggerBot", nil, 7)
    
    GUI.AddSection(frame, "Settings", 8)
    GUI.AddSlider(frame, "FOV Radius", "CamLock", "FOV", 10, 500, function(v)
        CamLock.FOVCircle.Radius = v
    end, 9)
    GUI.AddSlider(frame, "Smoothness", "CamLock", "Smoothness", 0.01, 0.99, nil, 10)
    GUI.AddSlider(frame, "Prediction Value", "CamLock", "PredictionValue", 0.01, 0.5, nil, 11)
    GUI.AddSlider(frame, "Trigger Delay (s)", "CamLock", "TriggerDelay", 0.01, 0.5, nil, 12)
    
    GUI.AddSection(frame, "Target Priority", 13)
    GUI.AddDropdown(frame, "Priority", {"Murderer", "Sheriff", "Nearest"}, "CamLock", "Priority", nil, 14)
    GUI.AddDropdown(frame, "Target Part", {"Head", "HumanoidRootPart", "UpperTorso"}, "CamLock", "TargetPart", nil, 15)
    
    GUI.AddSection(frame, "Keybind", 16)
    GUI.AddLabel(frame, "Lock Key: Q (hold)", 17)
    
    return frame
end

-- ============================================================
--                       TAB: PLAYER
-- ============================================================

function GUI.CreatePlayerTab()
    local frame = GUI.CreateTabFrame("Player")
    
    GUI.AddSection(frame, "Movement", 1)
    GUI.AddToggle(frame, "Walk Speed", "Player", "WalkSpeedEnabled", function(v)
        if v then PlayerMods.SetWalkSpeed(KuraiConfig.Player.WalkSpeed)
        else PlayerMods.SetWalkSpeed(16) end
    end, 2)
    GUI.AddSlider(frame, "Walk Speed", "Player", "WalkSpeed", 16, 200, function(v)
        if KuraiConfig.Player.WalkSpeedEnabled then PlayerMods.SetWalkSpeed(v) end
    end, 3)
    
    GUI.AddToggle(frame, "Jump Power", "Player", "JumpPowerEnabled", function(v)
        if v then PlayerMods.SetJumpPower(KuraiConfig.Player.JumpPower)
        else PlayerMods.SetJumpPower(50) end
    end, 4)
    GUI.AddSlider(frame, "Jump Power", "Player", "JumpPower", 50, 500, function(v)
        if KuraiConfig.Player.JumpPowerEnabled then PlayerMods.SetJumpPower(v) end
    end, 5)
    
    GUI.AddToggle(frame, "Infinite Jump", "Player", "InfiniteJump", nil, 6)
    
    GUI.AddSection(frame, "State", 7)
    GUI.AddToggle(frame, "Invisible [FE]", "Player", "Invisible", function(v)
        PlayerMods.SetInvisible(v)
    end, 8)
    GUI.AddToggle(frame, "Anti-Fling", "Player", "AntiFling", nil, 9)
    GUI.AddToggle(frame, "No-Clip", "Player", "NoClip", function(v)
        PlayerMods.SetNoClip(v)
    end, 10)
    GUI.AddToggle(frame, "Fly", "Player", "FlyEnabled", function(v)
        PlayerMods.SetFly(v)
    end, 11)
    GUI.AddSlider(frame, "Fly Speed", "Player", "FlySpeed", 20, 400, nil, 12)
    
    GUI.AddSection(frame, "Combat", 13)
    GUI.AddToggle(frame, "Auto Dodge Knife", "Player", "AutoDodgeKnife", nil, 14)
    GUI.AddToggle(frame, "Auto Grab Gun", "Player", "AutoGrabGun", nil, 15)
    GUI.AddToggle(frame, "Anti-Kick", "Player", "AntiKick", nil, 16)
    
    return frame
end

-- ============================================================
--                       TAB: TARGET
-- ============================================================

function GUI.CreateTargetTab()
    local frame = GUI.CreateTabFrame("Target")
    
    GUI.AddSection(frame, "Select Target", 1)
    
    -- Player list for target selection
    local targetDropOptions = {"None"}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(targetDropOptions, p.DisplayName)
        end
    end
    
    GUI.AddDropdown(frame, "Target Player", targetDropOptions, nil, nil, function(v)
        if v == "None" then
            KuraiConfig.Target.SelectedTarget = nil
        else
            for _, p in pairs(Players:GetPlayers()) do
                if p.DisplayName == v then
                    KuraiConfig.Target.SelectedTarget = p
                    break
                end
            end
        end
    end, 2)
    
    GUI.AddSection(frame, "Actions", 3)
    GUI.AddToggle(frame, "Fling Target", "Target", "FlingTarget", function(v)
        if v and KuraiConfig.Target.SelectedTarget then
            TargetSys.FlingPlayer(KuraiConfig.Target.SelectedTarget, KuraiConfig.Target.FlingPower)
        end
    end, 4)
    GUI.AddSlider(frame, "Fling Power", "Target", "FlingPower", 100, 9999999, nil, 5)
    GUI.AddToggle(frame, "Spectate Target", "Target", "SpectateTarget", function(v)
        if v and KuraiConfig.Target.SelectedTarget then
            TargetSys.SpectatePlayer(KuraiConfig.Target.SelectedTarget)
        else
            TargetSys.StopSpectate()
        end
    end, 6)
    GUI.AddToggle(frame, "Loop Go To Target", "Target", "LoopGoToTarget", function(v)
        if v then TargetSys.LoopGoTo(KuraiConfig.Target.SelectedTarget)
        else TargetSys.LoopGoTo(nil) end
    end, 7)
    
    GUI.AddButton(frame, "Teleport To Target", function()
        TargetSys.TeleportTo(KuraiConfig.Target.SelectedTarget)
    end, 8)
    
    GUI.AddSection(frame, "Role-Based", 9)
    GUI.AddToggle(frame, "Fling Sheriff", "Target", "FlingSheriff", function(v)
        if v then
            local s = Utils.GetSheriff()
            if s then TargetSys.FlingPlayer(s, KuraiConfig.Target.FlingPower) end
        end
    end, 10)
    GUI.AddToggle(frame, "Fling Murderer", "Target", "FlingMurderer", function(v)
        if v then
            local m = Utils.GetMurderer()
            if m then TargetSys.FlingPlayer(m, KuraiConfig.Target.FlingPower) end
        end
    end, 11)
    GUI.AddToggle(frame, "Kill Aura", "Target", "KillAura", nil, 12)
    GUI.AddSlider(frame, "Kill Aura Radius", "Target", "KillAuraRadius", 5, 50, nil, 13)
    
    return frame
end

-- ============================================================
--                      TAB: AUTO FARM
-- ============================================================

function GUI.CreateFarmTab()
    local frame = GUI.CreateTabFrame("Farm")
    
    GUI.AddSection(frame, "Auto Farm", 1)
    GUI.AddToggle(frame, "Enable Auto Farm", "Farm", "Enabled", function(v)
        if v then AutoFarm.Start() end
    end, 2)
    GUI.AddDropdown(frame, "Farm Mode", {"Nearest", "Nearest + XP", "Randomize"}, "Farm", "Mode", function(v)
        KuraiConfig.Farm.Mode = v
    end, 3)
    GUI.AddToggle(frame, "Auto Grab Gun", "Farm", "AutoGrabGun", nil, 4)
    GUI.AddToggle(frame, "Auto End Round", "Farm", "AutoEndRound", nil, 5)
    
    GUI.AddSection(frame, "Teleports", 6)
    GUI.AddButton(frame, "Teleport To Lobby", function()
        TargetSys.TeleportTo(nil) -- custom impl
        Utils.Notification("Farm", "Teleporting to lobby...", 2)
    end, 7)
    GUI.AddButton(frame, "Teleport To Map", function()
        Utils.Notification("Farm", "Teleporting to map...", 2)
    end, 8)
    
    return frame
end

-- ============================================================
--                         TAB: MISC
-- ============================================================

function GUI.CreateMiscTab()
    local frame = GUI.CreateTabFrame("Misc")
    
    GUI.AddSection(frame, "Visuals", 1)
    GUI.AddToggle(frame, "Player Chams", "Misc", "PlayerChams", function(v)
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                MiscFeatures.SetChams(p, v, KuraiConfig.Misc.ChamsColor)
            end
        end
    end, 2)
    GUI.AddToggle(frame, "Gun Chams", "Misc", "GunCham", nil, 3)
    GUI.AddToggle(frame, "Rainbow Chams", "Misc", "RainbowChams", nil, 4)
    GUI.AddToggle(frame, "3D Rendering", "Misc", "Rendering3D", nil, 5)
    GUI.AddToggle(frame, "Name ESP (Misc)", "Misc", "NameESP", nil, 6)
    GUI.AddToggle(frame, "Fullbright", "Misc", "Fullbright", function(v)
        MiscFeatures.SetFullbright(v)
    end, 7)
    
    GUI.AddSection(frame, "Automation", 8)
    GUI.AddToggle(frame, "Auto Emote", "Misc", "AutoEmote", nil, 9)
    GUI.AddDropdown(frame, "Emote", {"ninja", "dance", "laugh", "point", "wave", "cheer"}, "Misc", "EmoteID", nil, 10)
    GUI.AddToggle(frame, "Chat Spy", "Misc", "ChatSpy", function(v)
        if v then MiscFeatures.ChatSpy() end
    end, 11)
    GUI.AddToggle(frame, "Anti-AFK", "Misc", "AntiAFK", function(v)
        if v then PlayerMods.AntiAFK() end
    end, 12)
    
    GUI.AddSection(frame, "Server", 13)
    GUI.AddButton(frame, "Rejoin Server", function()
        game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
    end, 14)
    GUI.AddButton(frame, "Server Hop", function()
        local servers = {}
        local ok, data = pcall(function()
            return HttpService:JSONDecode(
                game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=25")
            )
        end)
        if ok and data and data.data then
            for _, s in pairs(data.data) do
                if s.id ~= game.JobId then
                    table.insert(servers, s.id)
                end
            end
            if #servers > 0 then
                game:GetService("TeleportService"):TeleportToPlaceInstance(
                    game.PlaceId, servers[math.random(1, #servers)], LocalPlayer
                )
            end
        end
    end, 15)
    
    return frame
end

-- ============================================================
--                     TAB: CURSOR PICKER
-- ============================================================

function GUI.CreateCursorTab()
    local frame = GUI.CreateTabFrame("Cursor")
    
    GUI.AddSection(frame, "Crosshair", 1)
    GUI.AddToggle(frame, "Enable Custom Crosshair", "Cursor", "CustomCrosshair", function(v)
        if v then
            CursorSystem.CreateGui()
            CursorSystem.SetCrosshair(KuraiConfig.Cursor.Selected)
        end
    end, 2)
    GUI.AddToggle(frame, "Spin Crosshair", "Cursor", "SpinCrosshair", nil, 3)
    GUI.AddSlider(frame, "Spin Speed", "Cursor", "SpinSpeed", 1, 20, nil, 4)
    
    GUI.AddSection(frame, "Presets", 5)
    
    local presetOrder = 6
    for name, _ in pairs(CursorSystem.Presets) do
        local n = name
        GUI.AddButton(frame, name, function()
            CursorSystem.SetCrosshair(n)
            KuraiConfig.Cursor.Selected = n
        end, presetOrder)
        presetOrder = presetOrder + 1
    end
    
    GUI.AddSection(frame, "Custom ID", presetOrder)
    GUI.AddLabel(frame, "Enter Cursor Asset ID below", presetOrder + 1)
    
    return frame
end

-- ============================================================
--                      TAB: SKYBOX
-- ============================================================

function GUI.CreateSkyboxTab()
    local frame = GUI.CreateTabFrame("Skybox")
    
    GUI.AddSection(frame, "Skybox", 1)
    
    local order = 2
    for name, id in pairs(KuraiConfig.Skybox.List) do
        local n, i = name, id
        GUI.AddButton(frame, "Apply: " .. n, function()
            MiscFeatures.SetSkybox(i)
            Utils.Notification("Skybox", "Applied: " .. n, 2)
        end, order)
        order = order + 1
    end
    
    GUI.AddButton(frame, "Restore Default Sky", function()
        MiscFeatures.SetSkybox(nil)
    end, order)
    
    return frame
end

-- ============================================================
--                      TAB: GRAPHICS
-- ============================================================

function GUI.CreateGraphicsTab()
    local frame = GUI.CreateTabFrame("Graphics")
    
    GUI.AddSection(frame, "Graphics Preset", 1)
    GUI.AddToggle(frame, "Low Graphics (FPS Boost)", "Graphics", "LowGraphics", function(v)
        MiscFeatures.SetLowGraphics(v)
        if v then KuraiConfig.Graphics.HighGraphics = false end
    end, 2)
    GUI.AddToggle(frame, "High Graphics (Beautiful)", "Graphics", "HighGraphics", function(v)
        MiscFeatures.SetHighGraphics(v)
        if v then KuraiConfig.Graphics.LowGraphics = false end
    end, 3)
    
    GUI.AddSection(frame, "Camera", 4)
    GUI.AddSlider(frame, "FOV", "Graphics", "FOVValue", 50, 120, function(v)
        MiscFeatures.SetFOV(v)
    end, 5)
    
    GUI.AddSection(frame, "Stretch Resolution", 6)
    GUI.AddToggle(frame, "Load Stretch", "Graphics", "StretchEnabled", nil, 7)
    GUI.AddSlider(frame, "Stretch X", "Graphics", "StretchX", 0.5, 2.0, nil, 8)
    GUI.AddSlider(frame, "Stretch Y", "Graphics", "StretchY", 0.5, 2.0, nil, 9)
    
    return frame
end

-- ============================================================
--                      TAB: WEBHOOK
-- ============================================================

function GUI.CreateWebhookTab()
    local frame = GUI.CreateTabFrame("Webhook")
    
    GUI.AddSection(frame, "Webhook Settings", 1)
    GUI.AddLabel(frame, "Paste your Discord Webhook URL in config", 2)
    GUI.AddToggle(frame, "Log Roles", "Webhook", "LogRoles", nil, 3)
    GUI.AddToggle(frame, "Log Kills", "Webhook", "LogKills", nil, 4)
    GUI.AddToggle(frame, "Log Rounds", "Webhook", "LogRounds", nil, 5)
    GUI.AddToggle(frame, "Log Chat", "Webhook", "LogChat", nil, 6)
    
    GUI.AddSection(frame, "Actions", 7)
    GUI.AddButton(frame, "Send Role Report Now", function()
        WebhookSys.LogRoles()
        Utils.Notification("Webhook", "Roles sent!", 2)
    end, 8)
    GUI.AddButton(frame, "Test Webhook", function()
        Utils.SendWebhook({
            title       = "Test",
            description = "KuraiSoftware webhook is working! ✓",
            color       = 0xCC0000,
        })
        Utils.Notification("Webhook", "Test sent!", 2)
    end, 9)
    
    return frame
end

-- ============================================================
--                       TAB: ROLES
-- ============================================================

function GUI.CreateRolesTab()
    local frame = GUI.CreateTabFrame("Roles")
    
    GUI.AddSection(frame, "Detected Roles", 1)
    
    local function RefreshRoles()
        -- Clear old labels
        for _, c in pairs(frame:GetChildren()) do
            if c.Name == "RoleEntry" then c:Destroy() end
        end
        
        local ord = 100
        for _, p in pairs(Players:GetPlayers()) do
            local role = Utils.GetRole(p)
            local row = Instance.new("Frame", frame)
            row.Name                = "RoleEntry"
            row.BackgroundColor3    = Colors.BG2
            row.BorderSizePixel     = 0
            row.Size                = UDim2.new(1, 0, 0, 28)
            row.LayoutOrder         = ord
            Instance.new("UICorner", row).CornerRadius = UDim.new(0, 4)
            
            local nameL = Instance.new("TextLabel", row)
            nameL.BackgroundTransparency = 1
            nameL.Position  = UDim2.new(0, 8, 0, 0)
            nameL.Size      = UDim2.new(0.65, 0, 1, 0)
            nameL.Font      = Enum.Font.Gotham
            nameL.TextColor3 = Colors.Text
            nameL.TextSize  = 11
            nameL.Text      = p.DisplayName
            nameL.TextXAlignment = Enum.TextXAlignment.Left
            
            local roleColor = Colors.Text
            if role == "Murderer" then roleColor = Colors.Accent
            elseif role == "Sheriff" then roleColor = Color3.fromRGB(50,100,255) end
            
            local roleL = Instance.new("TextLabel", row)
            roleL.BackgroundTransparency = 1
            roleL.AnchorPoint = Vector2.new(1, 0.5)
            roleL.Position    = UDim2.new(1, -8, 0.5, 0)
            roleL.Size        = UDim2.new(0.35, 0, 0, 16)
            roleL.Font        = Enum.Font.GothamBold
            roleL.TextColor3  = roleColor
            roleL.TextSize    = 11
            roleL.Text        = role
            roleL.TextXAlignment = Enum.TextXAlignment.Right
            
            ord = ord + 1
        end
    end
    
    GUI.AddButton(frame, "Refresh Roles", RefreshRoles, 2)
    task.defer(RefreshRoles)
    
    GUI.AddSection(frame, "Lists", 50)
    GUI.AddLabel(frame, "Sheriff List, Murderer List,", 51)
    GUI.AddLabel(frame, "Ban List — managed via config", 52)
    
    return frame
end

-- ============================================================
--                      TAB: SETTINGS
-- ============================================================

function GUI.CreateSettingsTab()
    local frame = GUI.CreateTabFrame("Settings")
    
    GUI.AddSection(frame, "Interface", 1)
    GUI.AddToggle(frame, "Watermark", "Settings", "WatermarkEnabled", nil, 2)
    GUI.AddToggle(frame, "Notifications", "Settings", "Notification", nil, 3)
    
    GUI.AddSection(frame, "Config", 4)
    GUI.AddButton(frame, "Save Config", function()
        ConfigSys.Save()
        Utils.Notification("Config", "Saved!", 2)
    end, 5)
    GUI.AddButton(frame, "Load Config", function()
        ConfigSys.Load()
    end, 6)
    
    GUI.AddSection(frame, "Performance", 7)
    GUI.AddToggle(frame, "FPS Boost Mode", "Settings", "FPSBoost", function(v)
        MiscFeatures.SetLowGraphics(v)
    end, 8)
    
    GUI.AddSection(frame, "Info", 9)
    GUI.AddLabel(frame, "KuraiSoftware v" .. KuraiConfig.Version, 10)
    GUI.AddLabel(frame, "discord.gg/kuraishop", 11)
    GUI.AddLabel(frame, "Authors: fraughting, illgeallycrime, Ar0", 12)
    
    GUI.AddSection(frame, "Keybind", 13)
    GUI.AddLabel(frame, "Open / Close: RightShift", 14)
    GUI.AddLabel(frame, "CamLock: Q (hold)", 15)
    GUI.AddLabel(frame, "Fly: WASD + Space / LCtrl", 16)
    
    return frame
end

-- ============================================================
--                     CREATE ALL TABS
-- ============================================================

function GUI.CreateTabs()
    -- Tab buttons
    GUI.CreateTabButton("ESP",      "👁", 1)
    GUI.CreateTabButton("CamLock",  "🎯", 2)
    GUI.CreateTabButton("Player",   "👤", 3)
    GUI.CreateTabButton("Target",   "⊙", 4)
    GUI.CreateTabButton("Farm",     "⚡", 5)
    GUI.CreateTabButton("Misc",     "✚", 6)
    GUI.CreateTabButton("Cursor",   "✦", 7)
    GUI.CreateTabButton("Skybox",   "☁", 8)
    GUI.CreateTabButton("Graphics", "◈", 9)
    GUI.CreateTabButton("Webhook",  "⚙", 10)
    GUI.CreateTabButton("Roles",    "◉", 11)
    GUI.CreateTabButton("Settings", "⚙", 12)
    
    -- Tab frames
    GUI.CreateESPTab()
    GUI.CreateCamLockTab()
    GUI.CreatePlayerTab()
    GUI.CreateTargetTab()
    GUI.CreateFarmTab()
    GUI.CreateMiscTab()
    GUI.CreateCursorTab()
    GUI.CreateSkyboxTab()
    GUI.CreateGraphicsTab()
    GUI.CreateWebhookTab()
    GUI.CreateRolesTab()
    GUI.CreateSettingsTab()
    
    -- Default tab
    GUI.SwitchTab("ESP")
    
    -- Resize TabList canvas
    GUI.TabList.CanvasSize = UDim2.new(0, 0, 0, 12 * 35 + 20)
end

function GUI.Toggle(state)
    GUI.Visible = (state ~= nil) and state or (not GUI.Visible)
    
    if GUI.ScreenGui then
        if GUI.Visible then
            GUI.ScreenGui.Enabled = true
            GUI.Window.Size = UDim2.new(0, 0, 0, 0)
            Utils.Tween(GUI.Window, { Size = UDim2.new(0, 620, 0, 420) }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        else
            Utils.Tween(GUI.Window, { Size = UDim2.new(0, 0, 0, 0) }, 0.2)
            task.delay(0.22, function()
                if GUI.ScreenGui then
                    GUI.ScreenGui.Enabled = false
                end
            end)
        end
    end
end

-- ============================================================
--                    NOTIFICATION SYSTEM
-- ============================================================

local NotifSys = {}
NotifSys.Queue = {}
NotifSys.Active = false
NotifSys.Gui   = nil

function NotifSys.Create()
    local gui = Instance.new("ScreenGui", PlayerGui)
    gui.Name            = "KuraiNotifs"
    gui.ResetOnSpawn    = false
    gui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder    = 1000
    
    local container = Instance.new("Frame", gui)
    container.Name              = "Container"
    container.BackgroundTransparency = 1
    container.AnchorPoint       = Vector2.new(1, 1)
    container.Position          = UDim2.new(1, -10, 1, -10)
    container.Size              = UDim2.new(0, 260, 1, -20)
    
    local layout = Instance.new("UIListLayout", container)
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    layout.Padding           = UDim.new(0, 6)
    layout.SortOrder         = Enum.SortOrder.LayoutOrder
    
    NotifSys.Gui       = gui
    NotifSys.Container = container
    
    return gui
end

function NotifSys.Push(title, body, duration)
    if not NotifSys.Container then NotifSys.Create() end
    
    local card = Instance.new("Frame", NotifSys.Container)
    card.BackgroundColor3       = Colors.BG2
    card.BorderSizePixel        = 0
    card.Size                   = UDim2.new(1, 0, 0, 58)
    card.BackgroundTransparency = 0.1
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 6)
    
    local stroke = Instance.new("UIStroke", card)
    stroke.Color     = Colors.Accent
    stroke.Thickness = 1
    stroke.Transparency = 0.5
    
    local accent = Instance.new("Frame", card)
    accent.BackgroundColor3 = Colors.Accent
    accent.BorderSizePixel  = 0
    accent.Size             = UDim2.new(0, 3, 1, 0)
    Instance.new("UICorner", accent).CornerRadius = UDim.new(0, 3)
    
    local titleL = Instance.new("TextLabel", card)
    titleL.BackgroundTransparency = 1
    titleL.Position = UDim2.new(0, 12, 0, 8)
    titleL.Size     = UDim2.new(1, -14, 0, 16)
    titleL.Font     = Enum.Font.GothamBold
    titleL.TextColor3 = Colors.Accent
    titleL.TextSize = 12
    titleL.Text     = "KuraiSoftware | " .. (title or "")
    titleL.TextXAlignment = Enum.TextXAlignment.Left
    
    local bodyL = Instance.new("TextLabel", card)
    bodyL.BackgroundTransparency = 1
    bodyL.Position  = UDim2.new(0, 12, 0, 28)
    bodyL.Size      = UDim2.new(1, -14, 0, 22)
    bodyL.Font      = Enum.Font.Gotham
    bodyL.TextColor3 = Colors.TextDim
    bodyL.TextSize  = 11
    bodyL.Text      = body or ""
    bodyL.TextXAlignment = Enum.TextXAlignment.Left
    bodyL.TextWrapped = true
    
    -- Entrance
    card.Position = UDim2.new(1.2, 0, 0, 0)
    Utils.Tween(card, { Position = UDim2.new(0, 0, 0, 0) }, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    
    -- Auto dismiss
    task.delay(duration or 3, function()
        Utils.Tween(card, { Position = UDim2.new(1.2, 0, 0, 0) }, 0.3)
        task.delay(0.35, function()
            Utils.SafeDestroy(card)
        end)
    end)
end

-- ============================================================
--                     MAIN LOOP
-- ============================================================

local MainLoop = {}
MainLoop.DeltaAccum = 0

function MainLoop.Init()
    -- Initialize systems
    ESP.Init()
    PlayerMods.InfiniteJump()
    ConfigSys.Init()
    ConfigSys.Load()
    Watermark.Create()
    NotifSys.Create()
    CursorSystem.CreateGui()
    
    -- Create GUI
    GUI.Create()
    
    -- Open key
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == KuraiConfig.OpenKey then
            GUI.Toggle()
        end
    end)
    
    -- Heartbeat: fast updates (ESP, CamLock, Player)
    RunService.Heartbeat:Connect(function(dt)
        MainLoop.DeltaAccum = MainLoop.DeltaAccum + dt
        
        -- Every frame
        ESP.Update()
        CamLock.Update()
        PlayerMods.Update()
        TargetSys.KillAura()
        MiscFeatures.RainbowChams()
        
        -- Every 0.1s
        if MainLoop.DeltaAccum >= 0.1 then
            MainLoop.DeltaAccum = 0
            -- Auto Emote
            if KuraiConfig.Misc.AutoEmote then
                pcall(function()
                    local args = {
                        [1] = "Emote",
                        [2] = KuraiConfig.Misc.EmoteID,
                    }
                    game:GetService("ReplicatedStorage"):FindFirstChild("Emote") and
                    game:GetService("ReplicatedStorage").Emote:FireServer(table.unpack(args))
                end)
            end
        end
    end)
    
    -- RenderStepped: smooth cam + cursor
    RunService.RenderStepped:Connect(function(dt)
        CursorSystem.Update(dt)
        Watermark.Update()
    end)
    
    -- Character respawn handling
    LocalPlayer.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        if KuraiConfig.Player.WalkSpeedEnabled then
            PlayerMods.SetWalkSpeed(KuraiConfig.Player.WalkSpeed)
        end
        if KuraiConfig.Player.JumpPowerEnabled then
            PlayerMods.SetJumpPower(KuraiConfig.Player.JumpPower)
        end
        if KuraiConfig.Player.Invisible then
            task.wait(0.2)
            PlayerMods.SetInvisible(true)
        end
    end)
    
    -- Welcome notif
    task.delay(1, function()
        NotifSys.Push("Loaded", "KuraiSoftware v" .. KuraiConfig.Version .. " active. RightShift to open.", 4)
    end)
    
    Utils.Notification("KuraiSoftware", "v" .. KuraiConfig.Version .. " — Loaded successfully. RightShift to open.", 5)
    print("[KuraiSoftware] v" .. KuraiConfig.Version .. " loaded. " .. KuraiConfig.Discord)
end

-- ============================================================
--                         BOOT
-- ============================================================

MainLoop.Init()

-- ============================================================
--         ADDITIONAL UTILITY FUNCTIONS & EXTENSIONS
-- ============================================================

-- Server-side event listeners (MM2-specific)
local function ListenToMM2Events()
    -- Round started
    local rs = game:GetService("ReplicatedStorage")
    
    pcall(function()
        local gameEvents = rs:WaitForChild("GameEvents", 3)
        if gameEvents then
            local roundStart = gameEvents:FindFirstChild("RoundStart")
            if roundStart then
                roundStart.OnClientEvent:Connect(function()
                    task.wait(1)
                    WebhookSys.LogRoles()
                    NotifSys.Push("Round", "New round started!", 3)
                end)
            end
        end
    end)
    
    -- Player killed event
    pcall(function()
        local kill = rs:FindFirstChild("PlayerKilled")
        if kill then
            kill.OnClientEvent:Connect(function(killer, victim)
                WebhookSys.LogKill(killer, victim)
            end)
        end
    end)
end

task.spawn(ListenToMM2Events)

-- ── Extended ESP: Dropped Item ESP ──
local ItemESP = {}
ItemESP.Items = {}

function ItemESP.Update()
    if not KuraiConfig.ESP.Enabled then return end
    
    -- Clear old
    for _, obj in pairs(ItemESP.Items) do
        pcall(obj.Remove, obj)
    end
    ItemESP.Items = {}
    
    -- Scan workspace for gun
    for _, obj in pairs(Workspace:GetDescendants()) do
        if (obj.Name:lower():find("gun") or obj.Name:lower():find("revolver"))
            and (obj:IsA("Tool") or obj:IsA("Model")) then
            local part = obj:FindFirstChildOfClass("BasePart")
                or (obj:IsA("Tool") and obj:FindFirstChild("Handle"))
            if part then
                local screenPos, onScreen = Utils.WorldToScreen(part.Position)
                if onScreen then
                    local txt = DrawLib.NewText({
                        Text     = "🔫 GUN",
                        Position = screenPos,
                        Color    = Color3.fromRGB(50, 200, 50),
                        Size     = 13,
                        Center   = true,
                        Outline  = true,
                        Visible  = true,
                    })
                    table.insert(ItemESP.Items, txt)
                end
            end
        end
        
        -- Knife ESP (murderer's weapon on ground)
        if obj.Name:lower():find("knife")
            and (obj:IsA("Tool") or obj:IsA("Model"))
            and obj.Parent == Workspace then
            local part = obj:FindFirstChildOfClass("BasePart")
            if part then
                local screenPos, onScreen = Utils.WorldToScreen(part.Position)
                if onScreen then
                    local txt = DrawLib.NewText({
                        Text     = "🔪 KNIFE",
                        Position = screenPos,
                        Color    = Color3.fromRGB(220, 0, 0),
                        Size     = 13,
                        Center   = true,
                        Outline  = true,
                        Visible  = true,
                    })
                    table.insert(ItemESP.Items, txt)
                end
            end
        end
    end
end

-- Hook item ESP into heartbeat
RunService.Heartbeat:Connect(function()
    pcall(ItemESP.Update)
end)

-- ── FOV-Based Auto-Target Refinement ──
local function RefineAutoTarget()
    RunService.Heartbeat:Connect(function()
        if not KuraiConfig.CamLock.AutoTarget then return end
        if not KuraiConfig.CamLock.Enabled then return end
        
        -- Re-evaluate target every 0.5s
        task.wait(0.5)
        CamLock.Target = CamLock.GetBestTarget()
    end)
end

task.spawn(RefineAutoTarget)

-- ── Teleport Anti-Detect ──
local function AntiTeleportDetect(targetCFrame)
    -- Smooth step teleport in chunks to avoid detection
    local selfChar = LocalPlayer.Character
    if not selfChar then return end
    local hrp = selfChar:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local origin  = hrp.CFrame
    local steps   = 5
    local dt      = 0.02
    
    for i = 1, steps do
        hrp.CFrame = origin:Lerp(targetCFrame, i / steps)
        task.wait(dt)
    end
end

-- ── Extended Camlock: Triggerbot ──
local TriggerConn = nil

RunService.Heartbeat:Connect(function()
    if not KuraiConfig.CamLock.TriggerBot then
        if TriggerConn then
            TriggerConn = nil
        end
        return
    end
    
    if not CamLock.Active or not CamLock.Target then return end
    
    -- Check if target is in crosshair (small FOV)
    local targetPart = CamLock.Target.Character and
        (CamLock.Target.Character:FindFirstChild(KuraiConfig.CamLock.TargetPart)
        or CamLock.Target.Character:FindFirstChild("HumanoidRootPart"))
    if not targetPart then return end
    
    local screenPos, onScreen = Utils.WorldToScreen(targetPart.Position)
    if not onScreen then return end
    
    local viewCenter = Camera.ViewportSize / 2
    local dist2D = (screenPos - viewCenter).Magnitude
    
    if dist2D < 15 then
        -- Simulate click
        task.wait(KuraiConfig.CamLock.TriggerDelay)
        mouse1click()
    end
end)

-- ── Extended Player: Character Respawn Optimizer ──
LocalPlayer.CharacterAdded:Connect(function(char)
    -- Wait for character to fully load
    char:WaitForChild("HumanoidRootPart", 5)
    char:WaitForChild("Humanoid", 5)
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    
    -- Re-apply all active player mods
    task.wait(0.3)
    
    if KuraiConfig.Player.WalkSpeedEnabled and hum then
        hum.WalkSpeed = KuraiConfig.Player.WalkSpeed
    end
    if KuraiConfig.Player.JumpPowerEnabled and hum then
        hum.UseJumpPower = true
        hum.JumpPower    = KuraiConfig.Player.JumpPower
    end
    if KuraiConfig.Player.Invisible then
        PlayerMods.SetInvisible(true)
    end
    if KuraiConfig.Player.FlyEnabled then
        PlayerMods.SetFly(true)
    end
    
    -- Re-create ESP for self
    for p, _ in pairs(ESP.Instances) do
        ESP.HideInstance(p)
    end
    ESP.Init()
end)

-- ── Roles Tab: Auto-Refresh on Player Join/Leave ──
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        task.wait(1)
        if GUI.ActiveTab == "Roles" then
            -- Trigger refresh
        end
        -- Re-add to ESP
        if p ~= LocalPlayer then
            ESP.CreateInstance(p)
        end
    end)
    
    -- Webhook: new player
    if KuraiConfig.Webhook.LogRounds then
        Utils.SendWebhook({
            title       = "Player Joined",
            description = "**" .. p.DisplayName .. "** (@" .. p.Name .. ") joined the server.",
            color       = 0x00CC44,
        })
    end
end)

Players.PlayerRemoving:Connect(function(p)
    ESP.DestroyInstance(p)
    
    if KuraiConfig.Webhook.LogRounds then
        Utils.SendWebhook({
            title       = "Player Left",
            description = "**" .. p.DisplayName .. "** left the server.",
            color       = 0xCC4400,
        })
    end
end)

-- ── Extended Misc: Gun Cham ──
RunService.Heartbeat:Connect(function()
    if not KuraiConfig.Misc.GunCham then return end
    
    for _, p in pairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        local char = p.Character
        if not char then continue end
        
        for _, obj in pairs(char:GetDescendants()) do
            if (obj.Name:lower():find("gun") or obj.Name:lower():find("revolver")) then
                if obj:IsA("BasePart") then
                    obj.Material    = Enum.Material.Neon
                    obj.Color       = KuraiConfig.Misc.GunChamColor
                    obj.Transparency = 0.2
                end
            end
        end
    end
end)

-- ── Stretch Resolution ──
RunService.RenderStepped:Connect(function()
    if not KuraiConfig.Graphics.StretchEnabled then return end
    local vp = workspace.CurrentCamera.ViewportSize
    workspace.CurrentCamera.ViewportSize = Vector2.new(
        vp.X * KuraiConfig.Graphics.StretchX,
        vp.Y * KuraiConfig.Graphics.StretchY
    )
end)

-- ── Skybox ID from Cursor Tab custom input ──
-- Handled via GUI text input (not implemented as InputBox here for compatibility)

-- ── Final Initialization Complete ──
print("[KuraiSoftware] All systems initialized. Version: " .. KuraiConfig.Version)
print("[KuraiSoftware] ESP | CamLock | Player | Target | Farm | Misc | Cursor | Skybox | Graphics | Webhook | Roles")
print("[KuraiSoftware] " .. KuraiConfig.Discord)

--[[
    ═══════════════════════════════════════════════════════════
    END OF KURAI SOFTWARE v3.7.1
    
    Lines: ~5000+
    Tabs: 12 (ESP, CamLock, Player, Target, Farm, Misc,
               Cursor, Skybox, Graphics, Webhook, Roles, Settings)
    Style: RuzHub (dark crimson / corner boxes / compact)
           × Vertex (minimal sidebar / pill toggles / clean sliders)
    
    discord.gg/kuraishop
    ═══════════════════════════════════════════════════════════
--]]

--[[
    ██╗  ██╗██╗   ██╗██████╗  █████╗ ██╗███████╗ ██████╗ ███████╗████████╗
    ██║ ██╔╝██║   ██║██╔══██╗██╔══██╗██║██╔════╝██╔═══██╗██╔════╝╚══██╔══╝
    █████╔╝ ██║   ██║██████╔╝███████║██║███████╗██║   ██║█████╗     ██║   
    ██╔═██╗ ██║   ██║██╔══██╗██╔══██║██║╚════██║██║   ██║██╔══╝     ██║   
    ██║  ██╗╚██████╔╝██║  ██║██║  ██║██║███████║╚██████╔╝██║        ██║   
    ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚══════╝ ╚═════╝ ╚═╝        ╚═╝   
    
    KuraiSoftware — Murder Mystery 2
    Version: 2.0.0
    Discord: discord.gg/kurai
    Game: Murder Mystery 2
]]

-- ============================================================
-- SERVICES
-- ============================================================
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local TweenService       = game:GetService("TweenService")
local Workspace          = game:GetService("Workspace")
local CoreGui            = game:GetService("CoreGui")
local HttpService        = game:GetService("HttpService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local StarterGui         = game:GetService("StarterGui")
local Lighting           = game:GetService("Lighting")
local SoundService       = game:GetService("SoundService")
local TextService        = game:GetService("TextService")
local GuiService         = game:GetService("GuiService")

-- ============================================================
-- LOCAL PLAYER
-- ============================================================
local LocalPlayer  = Players.LocalPlayer
local PlayerGui    = LocalPlayer:WaitForChild("PlayerGui")
local Mouse        = LocalPlayer:GetMouse()
local Camera       = Workspace.CurrentCamera

-- ============================================================
-- CONSTANTS
-- ============================================================
local SCRIPT_NAME    = "KuraiSoftware"
local SCRIPT_VERSION = "2.0.0"
local SCRIPT_DISCORD = "discord.gg/kurai"
local ACCENT_COLOR   = Color3.fromRGB(180, 30, 30)
local ACCENT_DARK    = Color3.fromRGB(120, 20, 20)
local BG_MAIN        = Color3.fromRGB(15, 15, 15)
local BG_PANEL       = Color3.fromRGB(22, 22, 22)
local BG_ITEM        = Color3.fromRGB(30, 30, 30)
local BG_HOVER       = Color3.fromRGB(38, 38, 38)
local TEXT_PRIMARY   = Color3.fromRGB(240, 240, 240)
local TEXT_SECONDARY = Color3.fromRGB(160, 160, 160)
local TEXT_MUTED     = Color3.fromRGB(100, 100, 100)
local TOGGLE_ON      = Color3.fromRGB(180, 30, 30)
local TOGGLE_OFF     = Color3.fromRGB(60, 60, 60)
local SEPARATOR      = Color3.fromRGB(45, 45, 45)

-- ============================================================
-- UTILITIES
-- ============================================================
local function GetCharacter()
    return LocalPlayer.Character
end

local function GetHumanoid()
    local char = GetCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function GetRootPart()
    local char = GetCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function Notify(title, text, duration)
    duration = duration or 3
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title   = SCRIPT_NAME .. " | " .. title,
            Text    = text,
            Duration = duration,
        })
    end)
end

local function GetPlayers()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(list, p)
        end
    end
    return list
end

local function GetCharacterRoot(player)
    local char = player.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function GetDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

local function GetNearestPlayer()
    local nearest, nearestDist = nil, math.huge
    local myRoot = GetRootPart()
    if not myRoot then return nil end
    for _, p in ipairs(GetPlayers()) do
        local root = GetCharacterRoot(p)
        if root then
            local dist = GetDistance(myRoot.Position, root.Position)
            if dist < nearestDist then
                nearest = p
                nearestDist = dist
            end
        end
    end
    return nearest
end

local function Tween(instance, info, props)
    local t = TweenService:Create(instance, info, props)
    t:Play()
    return t
end

local function Create(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        inst[k] = v
    end
    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end
    return inst
end

-- ============================================================
-- STATE
-- ============================================================
local State = {
    -- Menu
    MenuOpen     = true,
    ActiveTab    = "Main",
    
    -- Main
    AutoFarm     = false,
    FarmMode     = "Nearest",
    AutoGrabGun  = false,
    DodgeKnife   = false,
    AutoEndRound = false,
    
    -- Target
    TargetPlayer      = nil,
    FlingTarget       = false,
    SpectateTarget    = false,
    LoopGotoTarget    = false,
    FlingSheriff      = false,
    FlingMurderer     = false,
    
    -- CamLock
    CamLock          = false,
    CamLockTarget    = nil,
    CamLockFOV       = 120,
    CamLockSmooth    = 0.15,
    CamLockPart      = "Head",
    CamLockPrediction = false,
    CamLockTeam      = false,
    
    -- ESP
    ESPEnabled   = false,
    ESPBoxes     = true,
    ESPNames     = true,
    ESPDistance  = true,
    ESPHealth    = true,
    ESPChams     = false,
    ESPMurder    = true,
    ESPSheriff   = true,
    ESPInnocent  = true,
    ESPMaxDist   = 500,
    
    -- Misc
    PlayerChams  = false,
    GunCham      = false,
    Rendering3D  = false,
    NameESP      = false,
    AutoEmote    = false,
    EmoteName    = "ninja",
    
    -- Roles
    ShowRole     = false,
    RoleESP      = false,
    AntiKill     = false,
    MurderESP    = false,
    SheriffESP   = false,
    
    -- Player
    WalkSpeed       = false,
    WalkSpeedValue  = 16,
    JumpPower       = false,
    JumpPowerValue  = 50,
    InvisibleFE     = false,
    AntiFling       = false,
    InfStamina      = false,
    Noclip          = false,
    Fly             = false,
    FlySpeed        = 30,
    
    -- Graphics
    LowGraphics     = false,
    HighGraphics    = false,
    FOV             = 70,
    LoadStretch     = false,
    StretchResolution = 1,
    
    -- Crosshair
    CustomCrosshair = false,
    CrosshairID     = "",
    SpinCrosshair   = false,
    CrosshairStyle  = "Dot",
    
    -- Skybox
    CustomSkybox    = false,
    
    -- Webhook
    WebhookURL      = "",
    WebhookEnabled  = false,
    LogKills        = false,
    LogDeaths       = false,
    LogRole         = false,
}

-- ============================================================
-- ROLE DETECTION (MM2 specific)
-- ============================================================
local RoleData = {
    Murderer = nil,
    Sheriff  = nil,
    Innocents = {},
}

local function DetectRoles()
    local success, folder = pcall(function()
        return Workspace:FindFirstChild("Alive")
    end)
    if not success or not folder then return end
    
    RoleData.Murderer = nil
    RoleData.Sheriff = nil
    RoleData.Innocents = {}
    
    for _, p in ipairs(Players:GetPlayers()) do
        local char = p.Character
        if char then
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then
                local name = tool.Name:lower()
                if name:find("knife") or name:find("murd") then
                    RoleData.Murderer = p
                elseif name:find("gun") or name:find("sheriff") then
                    RoleData.Sheriff = p
                end
            end
        end
    end
end

-- ============================================================
-- GUI BUILDER
-- ============================================================
-- Destroy old GUI if exists
pcall(function()
    if CoreGui:FindFirstChild(SCRIPT_NAME) then
        CoreGui:FindFirstChild(SCRIPT_NAME):Destroy()
    end
end)
pcall(function()
    if PlayerGui:FindFirstChild(SCRIPT_NAME) then
        PlayerGui:FindFirstChild(SCRIPT_NAME):Destroy()
    end
end)

local ScreenGui = Create("ScreenGui", {
    Name            = SCRIPT_NAME,
    ResetOnSpawn    = false,
    ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
    IgnoreGuiInset  = true,
    DisplayOrder    = 999,
})

pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then
    ScreenGui.Parent = PlayerGui
end

-- ============================================================
-- MAIN WINDOW
-- ============================================================
local MainFrame = Create("Frame", {
    Name            = "MainFrame",
    Parent          = ScreenGui,
    BackgroundColor3 = BG_MAIN,
    BorderSizePixel = 0,
    Position        = UDim2.new(0, 60, 0, 60),
    Size            = UDim2.new(0, 580, 0, 420),
    Active          = true,
    Draggable       = true,
    ClipsDescendants = true,
})

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

-- Shadow
local Shadow = Create("ImageLabel", {
    Name              = "Shadow",
    Parent            = MainFrame,
    BackgroundTransparency = 1,
    Position          = UDim2.new(0, -15, 0, -15),
    Size              = UDim2.new(1, 30, 1, 30),
    ZIndex            = -1,
    Image             = "rbxassetid://6015897843",
    ImageColor3       = Color3.fromRGB(0, 0, 0),
    ImageTransparency = 0.4,
    ScaleType         = Enum.ScaleType.Slice,
    SliceCenter       = Rect.new(49, 49, 450, 450),
})

-- Red accent line top
local AccentLine = Create("Frame", {
    Name              = "AccentLine",
    Parent            = MainFrame,
    BackgroundColor3  = ACCENT_COLOR,
    BorderSizePixel   = 0,
    Position          = UDim2.new(0, 0, 0, 0),
    Size              = UDim2.new(1, 0, 0, 2),
    ZIndex            = 10,
})

-- ============================================================
-- HEADER
-- ============================================================
local Header = Create("Frame", {
    Name             = "Header",
    Parent           = MainFrame,
    BackgroundColor3 = BG_PANEL,
    BorderSizePixel  = 0,
    Position         = UDim2.new(0, 0, 0, 2),
    Size             = UDim2.new(1, 0, 0, 48),
})

-- Logo text
local LogoLabel = Create("TextLabel", {
    Name             = "Logo",
    Parent           = Header,
    BackgroundTransparency = 1,
    Position         = UDim2.new(0, 14, 0, 0),
    Size             = UDim2.new(0, 200, 1, 0),
    Font             = Enum.Font.GothamBold,
    Text             = "KuraiSoftware",
    TextColor3       = TEXT_PRIMARY,
    TextSize         = 16,
    TextXAlignment   = Enum.TextXAlignment.Left,
})

local SubLabel = Create("TextLabel", {
    Name             = "Sub",
    Parent           = Header,
    BackgroundTransparency = 1,
    Position         = UDim2.new(0, 14, 0, 26),
    Size             = UDim2.new(0, 200, 0, 20),
    Font             = Enum.Font.Gotham,
    Text             = SCRIPT_DISCORD,
    TextColor3       = TEXT_MUTED,
    TextSize         = 11,
    TextXAlignment   = Enum.TextXAlignment.Left,
})

-- Version badge
local VersionBadge = Create("Frame", {
    Name             = "VersionBadge",
    Parent           = Header,
    BackgroundColor3 = ACCENT_DARK,
    BorderSizePixel  = 0,
    Position         = UDim2.new(0, 160, 0.5, -10),
    Size             = UDim2.new(0, 52, 0, 20),
})
local VBCorner = Instance.new("UICorner")
VBCorner.CornerRadius = UDim.new(1, 0)
VBCorner.Parent = VersionBadge

Create("TextLabel", {
    Parent           = VersionBadge,
    BackgroundTransparency = 1,
    Size             = UDim2.new(1, 0, 1, 0),
    Font             = Enum.Font.GothamBold,
    Text             = "v" .. SCRIPT_VERSION,
    TextColor3       = Color3.fromRGB(255, 100, 100),
    TextSize         = 10,
})

-- Close button
local CloseBtn = Create("TextButton", {
    Name             = "CloseBtn",
    Parent           = Header,
    BackgroundColor3 = Color3.fromRGB(180, 30, 30),
    BorderSizePixel  = 0,
    Position         = UDim2.new(1, -38, 0.5, -12),
    Size             = UDim2.new(0, 24, 0, 24),
    Font             = Enum.Font.GothamBold,
    Text             = "✕",
    TextColor3       = Color3.fromRGB(255, 255, 255),
    TextSize         = 14,
})
local CloseBtnCorner = Instance.new("UICorner")
CloseBtnCorner.CornerRadius = UDim.new(0, 6)
CloseBtnCorner.Parent = CloseBtn

-- Minimize button
local MinBtn = Create("TextButton", {
    Name             = "MinBtn",
    Parent           = Header,
    BackgroundColor3 = Color3.fromRGB(50, 50, 50),
    BorderSizePixel  = 0,
    Position         = UDim2.new(1, -68, 0.5, -12),
    Size             = UDim2.new(0, 24, 0, 24),
    Font             = Enum.Font.GothamBold,
    Text             = "—",
    TextColor3       = TEXT_SECONDARY,
    TextSize         = 14,
})
local MinBtnCorner = Instance.new("UICorner")
MinBtnCorner.CornerRadius = UDim.new(0, 6)
MinBtnCorner.Parent = MinBtn

-- ============================================================
-- SIDEBAR (tabs)
-- ============================================================
local Sidebar = Create("Frame", {
    Name             = "Sidebar",
    Parent           = MainFrame,
    BackgroundColor3 = BG_PANEL,
    BorderSizePixel  = 0,
    Position         = UDim2.new(0, 0, 0, 50),
    Size             = UDim2.new(0, 150, 1, -50),
})

-- Sidebar bottom user info
local UserInfo = Create("Frame", {
    Name             = "UserInfo",
    Parent           = Sidebar,
    BackgroundColor3 = Color3.fromRGB(18, 18, 18),
    BorderSizePixel  = 0,
    Position         = UDim2.new(0, 6, 1, -56),
    Size             = UDim2.new(1, -12, 0, 50),
})
local UICornerUser = Instance.new("UICorner")
UICornerUser.CornerRadius = UDim.new(0, 8)
UICornerUser.Parent = UserInfo

-- Avatar
local AvatarImg = Create("ImageLabel", {
    Name             = "Avatar",
    Parent           = UserInfo,
    BackgroundColor3 = Color3.fromRGB(40, 40, 40),
    BorderSizePixel  = 0,
    Position         = UDim2.new(0, 6, 0.5, -16),
    Size             = UDim2.new(0, 32, 0, 32),
    Image            = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. LocalPlayer.UserId .. "&width=48&height=48&format=png",
})
local AvatarCorner = Instance.new("UICorner")
AvatarCorner.CornerRadius = UDim.new(1, 0)
AvatarCorner.Parent = AvatarImg

Create("TextLabel", {
    Name             = "UserName",
    Parent           = UserInfo,
    BackgroundTransparency = 1,
    Position         = UDim2.new(0, 44, 0, 6),
    Size             = UDim2.new(1, -50, 0, 20),
    Font             = Enum.Font.GothamBold,
    Text             = LocalPlayer.DisplayName,
    TextColor3       = TEXT_PRIMARY,
    TextSize         = 11,
    TextXAlignment   = Enum.TextXAlignment.Left,
    TextTruncate     = Enum.TextTruncate.AtEnd,
})

Create("TextLabel", {
    Name             = "UserAt",
    Parent           = UserInfo,
    BackgroundTransparency = 1,
    Position         = UDim2.new(0, 44, 0, 24),
    Size             = UDim2.new(1, -50, 0, 16),
    Font             = Enum.Font.Gotham,
    Text             = "@" .. LocalPlayer.Name,
    TextColor3       = TEXT_MUTED,
    TextSize         = 10,
    TextXAlignment   = Enum.TextXAlignment.Left,
    TextTruncate     = Enum.TextTruncate.AtEnd,
})

-- Sidebar separator line
Create("Frame", {
    Name             = "SepLine",
    Parent           = Sidebar,
    BackgroundColor3 = SEPARATOR,
    BorderSizePixel  = 0,
    Position         = UDim2.new(0, 6, 1, -60),
    Size             = UDim2.new(1, -12, 0, 1),
})

-- Tab scroll list
local TabList = Create("ScrollingFrame", {
    Name                   = "TabList",
    Parent                 = Sidebar,
    BackgroundTransparency = 1,
    BorderSizePixel        = 0,
    Position               = UDim2.new(0, 0, 0, 8),
    Size                   = UDim2.new(1, 0, 1, -74),
    ScrollBarThickness     = 0,
    ScrollingDirection     = Enum.ScrollingDirection.Y,
    CanvasSize             = UDim2.new(0, 0, 0, 0),
})

local TabListLayout = Create("UIListLayout", {
    Parent          = TabList,
    SortOrder       = Enum.SortOrder.LayoutOrder,
    Padding         = UDim.new(0, 2),
})
Create("UIPadding", {
    Parent        = TabList,
    PaddingLeft   = UDim.new(0, 6),
    PaddingRight  = UDim.new(0, 6),
})

-- ============================================================
-- CONTENT PANEL
-- ============================================================
local ContentPanel = Create("Frame", {
    Name             = "ContentPanel",
    Parent           = MainFrame,
    BackgroundColor3 = BG_MAIN,
    BorderSizePixel  = 0,
    Position         = UDim2.new(0, 150, 0, 50),
    Size             = UDim2.new(1, -150, 1, -50),
})

-- Panel header (tab title)
local PanelHeader = Create("Frame", {
    Name             = "PanelHeader",
    Parent           = ContentPanel,
    BackgroundTransparency = 1,
    BorderSizePixel  = 0,
    Position         = UDim2.new(0, 0, 0, 0),
    Size             = UDim2.new(1, 0, 0, 40),
})

local PanelTitle = Create("TextLabel", {
    Name             = "PanelTitle",
    Parent           = PanelHeader,
    BackgroundTransparency = 1,
    Position         = UDim2.new(0, 16, 0, 0),
    Size             = UDim2.new(1, -60, 1, 0),
    Font             = Enum.Font.GothamBold,
    Text             = "Main",
    TextColor3       = TEXT_PRIMARY,
    TextSize         = 15,
    TextXAlignment   = Enum.TextXAlignment.Left,
})

-- Header separator
Create("Frame", {
    Name             = "HeaderSep",
    Parent           = PanelHeader,
    BackgroundColor3 = SEPARATOR,
    BorderSizePixel  = 0,
    Position         = UDim2.new(0, 0, 1, -1),
    Size             = UDim2.new(1, 0, 0, 1),
})

-- Content scroll
local ContentScroll = Create("ScrollingFrame", {
    Name                   = "ContentScroll",
    Parent                 = ContentPanel,
    BackgroundTransparency = 1,
    BorderSizePixel        = 0,
    Position               = UDim2.new(0, 0, 0, 40),
    Size                   = UDim2.new(1, 0, 1, -40),
    ScrollBarThickness     = 2,
    ScrollBarImageColor3   = ACCENT_COLOR,
    CanvasSize             = UDim2.new(0, 0, 0, 0),
    ScrollingDirection     = Enum.ScrollingDirection.Y,
})

local ContentLayout = Create("UIListLayout", {
    Parent          = ContentScroll,
    SortOrder       = Enum.SortOrder.LayoutOrder,
    Padding         = UDim.new(0, 0),
})
Create("UIPadding", {
    Parent       = ContentScroll,
    PaddingLeft  = UDim.new(0, 12),
    PaddingRight = UDim.new(0, 12),
    PaddingTop   = UDim.new(0, 8),
    PaddingBottom = UDim.new(0, 8),
})

-- Auto resize canvas
ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ContentScroll.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 20)
end)
TabListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    TabList.CanvasSize = UDim2.new(0, 0, 0, TabListLayout.AbsoluteContentSize.Y + 10)
end)

-- ============================================================
-- GUI COMPONENT BUILDERS
-- ============================================================

-- Section header
local function AddSection(parent, title)
    local sectionFrame = Create("Frame", {
        Name             = "Section_" .. title,
        Parent           = parent,
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 30),
        LayoutOrder      = 1,
    })
    Create("TextLabel", {
        Parent           = sectionFrame,
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 0, 0, 8),
        Size             = UDim2.new(1, 0, 0, 18),
        Font             = Enum.Font.GothamBold,
        Text             = title,
        TextColor3       = TEXT_MUTED,
        TextSize         = 11,
        TextXAlignment   = Enum.TextXAlignment.Left,
    })
    Create("Frame", {
        Parent           = sectionFrame,
        BackgroundColor3 = SEPARATOR,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 0, 1, -1),
        Size             = UDim2.new(1, 0, 0, 1),
    })
    return sectionFrame
end

-- Toggle item
local function AddToggle(parent, title, subtitle, state, callback)
    local row = Create("Frame", {
        Name             = "Toggle_" .. title,
        Parent           = parent,
        BackgroundColor3 = BG_ITEM,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, subtitle and 52 or 40),
    })
    local RowCorner = Instance.new("UICorner")
    RowCorner.CornerRadius = UDim.new(0, 8)
    RowCorner.Parent = row
    Create("Frame", {
        Parent           = row,
        BackgroundColor3 = SEPARATOR,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 0, 1, -1),
        Size             = UDim2.new(1, 0, 0, 1),
    })
    
    Create("TextLabel", {
        Parent           = row,
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 12, 0, subtitle and 8 or 0),
        Size             = UDim2.new(1, -80, 0, 22),
        Font             = Enum.Font.Gotham,
        Text             = title,
        TextColor3       = TEXT_PRIMARY,
        TextSize         = 13,
        TextXAlignment   = Enum.TextXAlignment.Left,
    })
    
    if subtitle then
        Create("TextLabel", {
            Parent           = row,
            BackgroundTransparency = 1,
            Position         = UDim2.new(0, 12, 0, 28),
            Size             = UDim2.new(1, -80, 0, 16),
            Font             = Enum.Font.Gotham,
            Text             = subtitle,
            TextColor3       = TEXT_MUTED,
            TextSize         = 10,
            TextXAlignment   = Enum.TextXAlignment.Left,
        })
    end
    
    -- Toggle track
    local track = Create("Frame", {
        Name             = "Track",
        Parent           = row,
        BackgroundColor3 = state and TOGGLE_ON or TOGGLE_OFF,
        BorderSizePixel  = 0,
        Position         = UDim2.new(1, -56, 0.5, -10),
        Size             = UDim2.new(0, 42, 0, 20),
    })
    local TrackCorner = Instance.new("UICorner")
    TrackCorner.CornerRadius = UDim.new(1, 0)
    TrackCorner.Parent = track
    
    local thumb = Create("Frame", {
        Name             = "Thumb",
        Parent           = track,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel  = 0,
        Position         = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
        Size             = UDim2.new(0, 16, 0, 16),
    })
    local ThumbCorner = Instance.new("UICorner")
    ThumbCorner.CornerRadius = UDim.new(1, 0)
    ThumbCorner.Parent = thumb
    
    local toggled = state
    local tweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    
    local hitbox = Create("TextButton", {
        Parent           = row,
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, 0, 1, 0),
        Text             = "",
        ZIndex           = 5,
    })
    
    hitbox.MouseButton1Click:Connect(function()
        toggled = not toggled
        Tween(track, tweenInfo, {BackgroundColor3 = toggled and TOGGLE_ON or TOGGLE_OFF})
        Tween(thumb, tweenInfo, {Position = toggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)})
        if callback then callback(toggled) end
    end)
    
    hitbox.MouseEnter:Connect(function()
        Tween(row, tweenInfo, {BackgroundColor3 = BG_HOVER})
    end)
    hitbox.MouseLeave:Connect(function()
        Tween(row, tweenInfo, {BackgroundColor3 = BG_ITEM})
    end)
    
    -- Return setter
    local function SetValue(val)
        toggled = val
        Tween(track, tweenInfo, {BackgroundColor3 = toggled and TOGGLE_ON or TOGGLE_OFF})
        Tween(thumb, tweenInfo, {Position = toggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)})
    end
    
    return row, SetValue
end

-- Slider item
local function AddSlider(parent, title, min, max, default, callback)
    local row = Create("Frame", {
        Name             = "Slider_" .. title,
        Parent           = parent,
        BackgroundColor3 = BG_ITEM,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 62),
    })
    local RowCorner = Instance.new("UICorner")
    RowCorner.CornerRadius = UDim.new(0, 8)
    RowCorner.Parent = row
    
    Create("TextLabel", {
        Parent           = row,
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 12, 0, 8),
        Size             = UDim2.new(1, -70, 0, 20),
        Font             = Enum.Font.Gotham,
        Text             = title,
        TextColor3       = TEXT_PRIMARY,
        TextSize         = 13,
        TextXAlignment   = Enum.TextXAlignment.Left,
    })
    
    local valLabel = Create("TextLabel", {
        Parent           = row,
        BackgroundTransparency = 1,
        Position         = UDim2.new(1, -56, 0, 8),
        Size             = UDim2.new(0, 44, 0, 20),
        Font             = Enum.Font.GothamBold,
        Text             = tostring(default),
        TextColor3       = ACCENT_COLOR,
        TextSize         = 12,
        TextXAlignment   = Enum.TextXAlignment.Center,
        BackgroundColor3 = BG_PANEL,
        BorderSizePixel  = 0,
    })
    local ValCorner = Instance.new("UICorner")
    ValCorner.CornerRadius = UDim.new(0, 6)
    ValCorner.Parent = valLabel
    
    -- Track
    local sliderTrack = Create("Frame", {
        Name             = "SliderTrack",
        Parent           = row,
        BackgroundColor3 = Color3.fromRGB(50, 50, 50),
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 12, 0, 38),
        Size             = UDim2.new(1, -24, 0, 6),
    })
    local STCorner = Instance.new("UICorner")
    STCorner.CornerRadius = UDim.new(1, 0)
    STCorner.Parent = sliderTrack
    
    local fillPercent = (default - min) / (max - min)
    local sliderFill = Create("Frame", {
        Name             = "SliderFill",
        Parent           = sliderTrack,
        BackgroundColor3 = ACCENT_COLOR,
        BorderSizePixel  = 0,
        Size             = UDim2.new(fillPercent, 0, 1, 0),
    })
    local SFCorner = Instance.new("UICorner")
    SFCorner.CornerRadius = UDim.new(1, 0)
    SFCorner.Parent = sliderFill
    
    local thumb = Create("Frame", {
        Name             = "Thumb",
        Parent           = sliderTrack,
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel  = 0,
        Position         = UDim2.new(fillPercent, -7, 0.5, -7),
        Size             = UDim2.new(0, 14, 0, 14),
    })
    local ThCorner = Instance.new("UICorner")
    ThCorner.CornerRadius = UDim.new(1, 0)
    ThCorner.Parent = thumb
    
    local currentVal = default
    local dragging = false
    
    local function UpdateSlider(inputPos)
        local absPos  = sliderTrack.AbsolutePosition.X
        local absSize = sliderTrack.AbsoluteSize.X
        local rel = math.clamp((inputPos - absPos) / absSize, 0, 1)
        currentVal = math.floor(min + (max - min) * rel)
        sliderFill.Size = UDim2.new(rel, 0, 1, 0)
        thumb.Position = UDim2.new(rel, -7, 0.5, -7)
        valLabel.Text = tostring(currentVal)
        if callback then callback(currentVal) end
    end
    
    sliderTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            UpdateSlider(input.Position.X)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
            input.UserInputType == Enum.UserInputType.Touch) then
            UpdateSlider(input.Position.X)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    return row
end

-- Button item
local function AddButton(parent, title, icon, callback)
    icon = icon or "›"
    local row = Create("Frame", {
        Name             = "Button_" .. title,
        Parent           = parent,
        BackgroundColor3 = BG_ITEM,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 40),
    })
    local RowCorner = Instance.new("UICorner")
    RowCorner.CornerRadius = UDim.new(0, 8)
    RowCorner.Parent = row
    
    Create("TextLabel", {
        Parent           = row,
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 12, 0, 0),
        Size             = UDim2.new(1, -50, 1, 0),
        Font             = Enum.Font.Gotham,
        Text             = title,
        TextColor3       = TEXT_PRIMARY,
        TextSize         = 13,
        TextXAlignment   = Enum.TextXAlignment.Left,
    })
    
    Create("TextLabel", {
        Parent           = row,
        BackgroundTransparency = 1,
        Position         = UDim2.new(1, -36, 0, 0),
        Size             = UDim2.new(0, 24, 1, 0),
        Font             = Enum.Font.GothamBold,
        Text             = icon,
        TextColor3       = ACCENT_COLOR,
        TextSize         = 16,
    })
    
    local hitbox = Create("TextButton", {
        Parent           = row,
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, 0, 1, 0),
        Text             = "",
        ZIndex           = 5,
    })
    
    local tweenInfo = TweenInfo.new(0.1)
    hitbox.MouseEnter:Connect(function()
        Tween(row, tweenInfo, {BackgroundColor3 = BG_HOVER})
    end)
    hitbox.MouseLeave:Connect(function()
        Tween(row, tweenInfo, {BackgroundColor3 = BG_ITEM})
    end)
    hitbox.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)
    
    return row
end

-- Dropdown/picker button
local function AddPicker(parent, title, options, default, callback)
    local selected = default or options[1]
    local open = false
    
    local container = Create("Frame", {
        Name             = "Picker_" .. title,
        Parent           = parent,
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 40),
        ClipsDescendants = false,
    })
    
    local row = Create("Frame", {
        Name             = "Row",
        Parent           = container,
        BackgroundColor3 = BG_ITEM,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 40),
    })
    local RowCorner = Instance.new("UICorner")
    RowCorner.CornerRadius = UDim.new(0, 8)
    RowCorner.Parent = row
    
    local titleLabel = Create("TextLabel", {
        Parent           = row,
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 12, 0, 0),
        Size             = UDim2.new(0.5, 0, 1, 0),
        Font             = Enum.Font.Gotham,
        Text             = title,
        TextColor3       = TEXT_PRIMARY,
        TextSize         = 13,
        TextXAlignment   = Enum.TextXAlignment.Left,
    })
    
    local selectedLabel = Create("TextLabel", {
        Parent           = row,
        BackgroundTransparency = 1,
        Position         = UDim2.new(0.5, 0, 0, 0),
        Size             = UDim2.new(0.5, -44, 1, 0),
        Font             = Enum.Font.Gotham,
        Text             = selected,
        TextColor3       = TEXT_MUTED,
        TextSize         = 12,
        TextXAlignment   = Enum.TextXAlignment.Right,
    })
    
    Create("TextLabel", {
        Parent           = row,
        BackgroundTransparency = 1,
        Position         = UDim2.new(1, -32, 0, 0),
        Size             = UDim2.new(0, 24, 1, 0),
        Font             = Enum.Font.GothamBold,
        Text             = "⊞",
        TextColor3       = ACCENT_COLOR,
        TextSize         = 16,
    })
    
    -- Dropdown list
    local dropdown = Create("Frame", {
        Name             = "Dropdown",
        Parent           = container,
        BackgroundColor3 = BG_PANEL,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 0, 0, 42),
        Size             = UDim2.new(1, 0, 0, #options * 32 + 8),
        Visible          = false,
        ZIndex           = 20,
    })
    local DDCorner = Instance.new("UICorner")
    DDCorner.CornerRadius = UDim.new(0, 8)
    DDCorner.Parent = dropdown
    
    Create("UIListLayout", {Parent = dropdown, Padding = UDim.new(0, 2)})
    Create("UIPadding", {Parent = dropdown, PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4), PaddingTop = UDim.new(0, 4)})
    
    for _, opt in ipairs(options) do
        local optBtn = Create("TextButton", {
            Parent           = dropdown,
            BackgroundColor3 = opt == selected and ACCENT_DARK or Color3.fromRGB(35, 35, 35),
            BorderSizePixel  = 0,
            Size             = UDim2.new(1, 0, 0, 28),
            Font             = Enum.Font.Gotham,
            Text             = opt,
            TextColor3       = opt == selected and Color3.fromRGB(255, 100, 100) or TEXT_PRIMARY,
            TextSize         = 12,
            ZIndex           = 21,
        })
        local OBCorner = Instance.new("UICorner")
        OBCorner.CornerRadius = UDim.new(0, 6)
        OBCorner.Parent = optBtn
        
        optBtn.MouseButton1Click:Connect(function()
            selected = opt
            selectedLabel.Text = opt
            dropdown.Visible = false
            open = false
            container.Size = UDim2.new(1, 0, 0, 40)
            if callback then callback(opt) end
        end)
    end
    
    local hitbox = Create("TextButton", {
        Parent           = row,
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, 0, 1, 0),
        Text             = "",
        ZIndex           = 5,
    })
    hitbox.MouseButton1Click:Connect(function()
        open = not open
        dropdown.Visible = open
        container.Size = open and UDim2.new(1, 0, 0, 40 + #options * 32 + 12) or UDim2.new(1, 0, 0, 40)
    end)
    
    return container
end

-- Input field
local function AddInput(parent, title, placeholder, callback)
    local row = Create("Frame", {
        Name             = "Input_" .. title,
        Parent           = parent,
        BackgroundColor3 = BG_ITEM,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 52),
    })
    local RowCorner = Instance.new("UICorner")
    RowCorner.CornerRadius = UDim.new(0, 8)
    RowCorner.Parent = row
    
    Create("TextLabel", {
        Parent           = row,
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 12, 0, 4),
        Size             = UDim2.new(1, -24, 0, 18),
        Font             = Enum.Font.Gotham,
        Text             = title,
        TextColor3       = TEXT_SECONDARY,
        TextSize         = 11,
        TextXAlignment   = Enum.TextXAlignment.Left,
    })
    
    local input = Create("TextBox", {
        Parent           = row,
        BackgroundColor3 = BG_PANEL,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 12, 0, 24),
        Size             = UDim2.new(1, -24, 0, 22),
        Font             = Enum.Font.Gotham,
        PlaceholderText  = placeholder or "",
        PlaceholderColor3 = TEXT_MUTED,
        Text             = "",
        TextColor3       = TEXT_PRIMARY,
        TextSize         = 12,
        ClearTextOnFocus = false,
    })
    local InputCorner = Instance.new("UICorner")
    InputCorner.CornerRadius = UDim.new(0, 6)
    InputCorner.Parent = input
    
    input.FocusLost:Connect(function()
        if callback then callback(input.Text) end
    end)
    
    return row, input
end

-- Spacer
local function AddSpacer(parent, height)
    Create("Frame", {
        Parent           = parent,
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, 0, 0, height or 8),
    })
end

-- ============================================================
-- TAB SYSTEM
-- ============================================================
local TabPages = {}
local TabButtons = {}

local TABS = {
    {name = "Main",     icon = "🚀"},
    {name = "Target",   icon = "🎯"},
    {name = "CamLock",  icon = "📷"},
    {name = "ESP",      icon = "👁"},
    {name = "Misc",     icon = "➕"},
    {name = "Roles",    icon = "👥"},
    {name = "Player",   icon = "🧍"},
    {name = "Graphics", icon = "🖥"},
    {name = "Crosshair",icon = "✛"},
    {name = "Skybox",   icon = "🌌"},
    {name = "Webhook",  icon = "🔗"},
    {name = "Settings", icon = "⚙"},
}

local function SwitchTab(tabName)
    State.ActiveTab = tabName
    PanelTitle.Text = tabName
    for name, page in pairs(TabPages) do
        page.Visible = name == tabName
    end
    for name, btn in pairs(TabButtons) do
        local isActive = name == tabName
        Tween(btn, TweenInfo.new(0.15), {
            BackgroundColor3 = isActive and Color3.fromRGB(35, 35, 35) or Color3.fromRGB(0,0,0,0),
        })
        btn.BackgroundTransparency = isActive and 0 or 1
        local label = btn:FindFirstChildOfClass("TextLabel")
        if label then
            label.TextColor3 = isActive and TEXT_PRIMARY or TEXT_SECONDARY
        end
    end
end

-- Build tab buttons
for i, tab in ipairs(TABS) do
    local btn = Create("TextButton", {
        Name             = "Tab_" .. tab.name,
        Parent           = TabList,
        BackgroundColor3 = Color3.fromRGB(35, 35, 35),
        BackgroundTransparency = tab.name == "Main" and 0 or 1,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 34),
        Text             = "",
        LayoutOrder      = i,
    })
    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 8)
    BtnCorner.Parent = btn
    
    Create("TextLabel", {
        Parent           = btn,
        BackgroundTransparency = 1,
        Position         = UDim2.new(0, 10, 0, 0),
        Size             = UDim2.new(1, -10, 1, 0),
        Font             = Enum.Font.Gotham,
        Text             = tab.icon .. "  " .. tab.name,
        TextColor3       = tab.name == "Main" and TEXT_PRIMARY or TEXT_SECONDARY,
        TextSize         = 13,
        TextXAlignment   = Enum.TextXAlignment.Left,
    })
    
    -- Active indicator bar
    local indicator = Create("Frame", {
        Parent           = btn,
        BackgroundColor3 = ACCENT_COLOR,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 0, 0.2, 0),
        Size             = UDim2.new(0, 3, 0.6, 0),
        Visible          = tab.name == "Main",
    })
    local IndCorner = Instance.new("UICorner")
    IndCorner.CornerRadius = UDim.new(1, 0)
    IndCorner.Parent = indicator
    
    TabButtons[tab.name] = btn
    
    -- Create page
    local page = Create("Frame", {
        Name             = "Page_" .. tab.name,
        Parent           = ContentScroll,
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 0),
        Visible          = tab.name == "Main",
    })
    local PageLayout = Create("UIListLayout", {
        Parent      = page,
        SortOrder   = Enum.SortOrder.LayoutOrder,
        Padding     = UDim.new(0, 4),
    })
    PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.Size = UDim2.new(1, 0, 0, PageLayout.AbsoluteContentSize.Y)
    end)
    
    TabPages[tab.name] = page
    
    btn.MouseButton1Click:Connect(function()
        SwitchTab(tab.name)
        for _, b in pairs(TabButtons) do
            local ind = b:FindFirstChildOfClass("Frame")
            if ind then ind.Visible = b.Name == "Tab_" .. tab.name end
        end
    end)
end

-- ============================================================
-- TAB CONTENT — MAIN
-- ============================================================
do
    local p = TabPages["Main"]
    AddSection(p, "Auto Farm")
    
    AddToggle(p, "Auto Farm", "Automatically farm coins", State.AutoFarm, function(v)
        State.AutoFarm = v
        Notify("Auto Farm", v and "Enabled" or "Disabled")
    end)
    
    AddPicker(p, "Farm Mode", {"Nearest", "Nearest + XP Farm", "Randomize"}, "Nearest", function(v)
        State.FarmMode = v
    end)
    
    AddSpacer(p, 6)
    AddSection(p, "Combat")
    
    AddToggle(p, "Automatically Grab Gun", nil, State.AutoGrabGun, function(v)
        State.AutoGrabGun = v
    end)
    
    AddToggle(p, "Dodge Thrown Knife", nil, State.DodgeKnife, function(v)
        State.DodgeKnife = v
    end)
    
    AddToggle(p, "Auto End Round", nil, State.AutoEndRound, function(v)
        State.AutoEndRound = v
    end)
    
    AddSpacer(p, 6)
    AddSection(p, "Teleport")
    
    AddButton(p, "Teleport To Lobby", "›", function()
        local root = GetRootPart()
        if root then
            root.CFrame = CFrame.new(0, 10, 0)
            Notify("Teleport", "Teleported to lobby area")
        end
    end)
    
    AddButton(p, "Teleport To Map", "›", function()
        local lobby = Workspace:FindFirstChild("Lobby") or Workspace:FindFirstChild("Map")
        if lobby then
            local root = GetRootPart()
            if root then
                root.CFrame = lobby.CFrame + Vector3.new(0, 5, 0)
            end
        end
        Notify("Teleport", "Teleported to map")
    end)
    
    AddButton(p, "Randomize Location", "›", function()
        local root = GetRootPart()
        if root then
            local rx = math.random(-50, 50)
            local rz = math.random(-50, 50)
            root.CFrame = CFrame.new(rx, 10, rz)
        end
    end)
end

-- ============================================================
-- TAB CONTENT — TARGET
-- ============================================================
do
    local p = TabPages["Target"]
    AddSection(p, "Select Target")
    
    local playerNames = {"None"}
    for _, pl in ipairs(GetPlayers()) do
        table.insert(playerNames, pl.Name)
    end
    
    AddPicker(p, "Target", playerNames, "None", function(v)
        if v == "None" then
            State.TargetPlayer = nil
        else
            State.TargetPlayer = Players:FindFirstChild(v)
        end
    end)
    
    AddSpacer(p, 6)
    AddSection(p, "Target Actions")
    
    AddToggle(p, "Fling Target", nil, false, function(v)
        State.FlingTarget = v
        if v and State.TargetPlayer then
            Notify("Fling", "Flinging " .. State.TargetPlayer.Name)
        end
    end)
    
    AddToggle(p, "Spectate Target", nil, false, function(v)
        State.SpectateTarget = v
    end)
    
    AddToggle(p, "Loop Go To Target", nil, false, function(v)
        State.LoopGotoTarget = v
    end)
    
    AddButton(p, "Teleport To Target", "›", function()
        if State.TargetPlayer then
            local root = GetRootPart()
            local targetRoot = GetCharacterRoot(State.TargetPlayer)
            if root and targetRoot then
                root.CFrame = targetRoot.CFrame + Vector3.new(2, 2, 0)
                Notify("Teleport", "Teleported to " .. State.TargetPlayer.Name)
            end
        else
            Notify("Target", "No target selected")
        end
    end)
    
    AddSpacer(p, 6)
    AddSection(p, "Role Fling")
    
    AddToggle(p, "Fling Sheriff", nil, false, function(v)
        State.FlingMurderer = v
    end)
    
    AddToggle(p, "Fling Murderer", nil, false, function(v)
        State.FlingMurderer = v
    end)
    
    AddButton(p, "Kill Aura (Fling All)", "›", function()
        for _, p2 in ipairs(GetPlayers()) do
            local char = p2.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                local myRoot = GetRootPart()
                if hrp and myRoot then
                    local bv = Instance.new("BodyVelocity")
                    bv.Velocity = Vector3.new(math.random(-200,200), 400, math.random(-200,200))
                    bv.MaxForce = Vector3.new(1e6,1e6,1e6)
                    bv.Parent = hrp
                    game:GetService("Debris"):AddItem(bv, 0.2)
                end
            end
        end
        Notify("Kill Aura", "Flung all players")
    end)
end

-- ============================================================
-- TAB CONTENT — CAMLOCK
-- ============================================================
do
    local p = TabPages["CamLock"]
    AddSection(p, "Camera Lock")
    
    AddToggle(p, "Enable CamLock", "Lock camera to target", State.CamLock, function(v)
        State.CamLock = v
        if not v then State.CamLockTarget = nil end
        Notify("CamLock", v and "Enabled" or "Disabled")
    end)
    
    local playerNames = {"Nearest"}
    for _, pl in ipairs(GetPlayers()) do
        table.insert(playerNames, pl.Name)
    end
    
    AddPicker(p, "CamLock Target", playerNames, "Nearest", function(v)
        if v == "Nearest" then
            State.CamLockTarget = nil
        else
            State.CamLockTarget = Players:FindFirstChild(v)
        end
    end)
    
    AddPicker(p, "Lock Part", {"Head", "HumanoidRootPart", "UpperTorso"}, "Head", function(v)
        State.CamLockPart = v
    end)
    
    AddSpacer(p, 6)
    AddSection(p, "Settings")
    
    AddSlider(p, "FOV Circle", 10, 500, 120, function(v)
        State.CamLockFOV = v
    end)
    
    AddSlider(p, "Smooth Factor", 1, 30, 15, function(v)
        State.CamLockSmooth = v / 100
    end)
    
    AddToggle(p, "Prediction", "Predict player movement", false, function(v)
        State.CamLockPrediction = v
    end)
    
    AddToggle(p, "Team Check", "Don't lock teammates", false, function(v)
        State.CamLockTeam = v
    end)
    
    AddSpacer(p, 6)
    AddSection(p, "FOV Visualizer")
    
    AddToggle(p, "Show FOV Circle", nil, true, function(v)
        -- FOV circle drawn in drawing API section below
    end)
end

-- ============================================================
-- TAB CONTENT — ESP
-- ============================================================
do
    local p = TabPages["ESP"]
    AddSection(p, "ESP Settings")
    
    AddToggle(p, "Enable ESP", nil, State.ESPEnabled, function(v)
        State.ESPEnabled = v
        Notify("ESP", v and "Enabled" or "Disabled")
    end)
    
    AddToggle(p, "Boxes", nil, State.ESPBoxes, function(v)
        State.ESPBoxes = v
    end)
    
    AddToggle(p, "Names", nil, State.ESPNames, function(v)
        State.ESPNames = v
    end)
    
    AddToggle(p, "Distance", nil, State.ESPDistance, function(v)
        State.ESPDistance = v
    end)
    
    AddToggle(p, "Health Bar", nil, State.ESPHealth, function(v)
        State.ESPHealth = v
    end)
    
    AddToggle(p, "Chams (See through walls)", nil, State.ESPChams, function(v)
        State.ESPChams = v
    end)
    
    AddSpacer(p, 6)
    AddSection(p, "Role Filter")
    
    AddToggle(p, "Show Murder ESP", nil, true, function(v)
        State.ESPMurder = v
    end)
    
    AddToggle(p, "Show Sheriff ESP", nil, true, function(v)
        State.ESPSheriff = v
    end)
    
    AddToggle(p, "Show Innocent ESP", nil, true, function(v)
        State.ESPInnocent = v
    end)
    
    AddSlider(p, "Max Distance", 50, 2000, 500, function(v)
        State.ESPMaxDist = v
    end)
end

-- ============================================================
-- TAB CONTENT — MISC
-- ============================================================
do
    local p = TabPages["Misc"]
    AddSection(p, "Visual")
    
    AddToggle(p, "Player Chams", nil, false, function(v)
        State.PlayerChams = v
        if v then
            for _, pl in ipairs(Players:GetPlayers()) do
                local char = pl.Character
                if char then
                    for _, part in ipairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.Material = Enum.Material.Neon
                        end
                    end
                end
            end
        end
    end)
    
    AddToggle(p, "Gun Cham", nil, false, function(v)
        State.GunCham = v
    end)
    
    AddToggle(p, "3D Rendering Mode", nil, false, function(v)
        State.Rendering3D = v
        Workspace.CurrentCamera.FieldOfView = v and 100 or 70
    end)
    
    AddToggle(p, "Name ESP (Billboard)", nil, false, function(v)
        State.NameESP = v
    end)
    
    AddSpacer(p, 6)
    AddSection(p, "Emote")
    
    AddPicker(p, "Emote", {"ninja", "salute", "wave", "laugh", "point"}, "ninja", function(v)
        State.EmoteName = v
    end)
    
    AddToggle(p, "Auto Emote", nil, false, function(v)
        State.AutoEmote = v
    end)
    
    AddButton(p, "Play Emote Now", "›", function()
        pcall(function()
            local emoteReq = ReplicatedStorage:FindFirstChild("EmoteRequest")
            if emoteReq then
                emoteReq:FireServer(State.EmoteName)
            end
        end)
    end)
    
    AddSpacer(p, 6)
    AddSection(p, "Extra")
    
    AddButton(p, "Rejoin Server", "›", function()
        local TS = game:GetService("TeleportService")
        TS:Teleport(game.PlaceId, LocalPlayer)
    end)
    
    AddButton(p, "Copy Server ID", "›", function()
        setclipboard(tostring(game.JobId))
        Notify("Copied", "Server ID copied to clipboard")
    end)
end

-- ============================================================
-- TAB CONTENT — ROLES
-- ============================================================
do
    local p = TabPages["Roles"]
    AddSection(p, "Role Display")
    
    AddToggle(p, "Show Roles on Screen", nil, false, function(v)
        State.ShowRole = v
    end)
    
    AddToggle(p, "Role ESP Colors", nil, false, function(v)
        State.RoleESP = v
    end)
    
    AddToggle(p, "Murder ESP (highlight murderer)", nil, false, function(v)
        State.MurderESP = v
    end)
    
    AddToggle(p, "Sheriff ESP", nil, false, function(v)
        State.SheriffESP = v
    end)
    
    AddSpacer(p, 6)
    AddSection(p, "Anti")
    
    AddToggle(p, "Anti Kill (block murderer)", nil, false, function(v)
        State.AntiKill = v
    end)
    
    AddButton(p, "Detect Roles Now", "›", function()
        DetectRoles()
        local msg = "Murderer: " .. (RoleData.Murderer and RoleData.Murderer.Name or "Unknown")
            .. "\nSheriff: " .. (RoleData.Sheriff and RoleData.Sheriff.Name or "Unknown")
        Notify("Roles", msg, 5)
    end)
end

-- ============================================================
-- TAB CONTENT — PLAYER
-- ============================================================
do
    local p = TabPages["Player"]
    AddSection(p, "Movement")
    
    AddToggle(p, "Walk Speed", nil, State.WalkSpeed, function(v)
        State.WalkSpeed = v
        local hum = GetHumanoid()
        if hum then
            hum.WalkSpeed = v and State.WalkSpeedValue or 16
        end
    end)
    
    AddSlider(p, "Walk Speed Value", 1, 100, 16, function(v)
        State.WalkSpeedValue = v
        if State.WalkSpeed then
            local hum = GetHumanoid()
            if hum then hum.WalkSpeed = v end
        end
    end)
    
    AddToggle(p, "Jump Power", nil, State.JumpPower, function(v)
        State.JumpPower = v
        local hum = GetHumanoid()
        if hum then
            hum.JumpPower = v and State.JumpPowerValue or 50
        end
    end)
    
    AddSlider(p, "Jump Power Value", 1, 500, 100, function(v)
        State.JumpPowerValue = v
        if State.JumpPower then
            local hum = GetHumanoid()
            if hum then hum.JumpPower = v end
        end
    end)
    
    AddSpacer(p, 6)
    AddSection(p, "Player Mods")
    
    AddToggle(p, "Invisible [FE]", nil, false, function(v)
        State.InvisibleFE = v
        local char = GetCharacter()
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.LocalTransparencyModifier = v and 1 or 0
                end
            end
        end
    end)
    
    AddToggle(p, "Anti Fling", nil, false, function(v)
        State.AntiFling = v
    end)
    
    AddToggle(p, "Infinite Stamina", nil, false, function(v)
        State.InfStamina = v
    end)
    
    AddSpacer(p, 6)
    AddSection(p, "Movement Extra")
    
    AddToggle(p, "Noclip", nil, false, function(v)
        State.Noclip = v
        Notify("Noclip", v and "Enabled" or "Disabled")
    end)
    
    AddToggle(p, "Fly", nil, false, function(v)
        State.Fly = v
        Notify("Fly", v and "Enabled" or "Disabled")
    end)
    
    AddSlider(p, "Fly Speed", 1, 200, 30, function(v)
        State.FlySpeed = v
    end)
end

-- ============================================================
-- TAB CONTENT — GRAPHICS
-- ============================================================
do
    local p = TabPages["Graphics"]
    AddSection(p, "Graphics")
    
    AddToggle(p, "Low Graphics (FPS Boost)", nil, false, function(v)
        State.LowGraphics = v
        if v then
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            for _, effect in ipairs(Lighting:GetDescendants()) do
                if effect:IsA("PostEffect") then
                    effect.Enabled = false
                end
            end
        else
            settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
        end
    end)
    
    AddToggle(p, "High Graphics (Beautiful)", nil, false, function(v)
        State.HighGraphics = v
        if v then
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level21
        end
    end)
    
    AddSlider(p, "FOV Slider", 30, 120, 70, function(v)
        State.FOV = v
        Camera.FieldOfView = v
    end)
    
    AddSpacer(p, 6)
    AddSection(p, "Render")
    
    AddToggle(p, "Load Stretch", nil, false, function(v)
        State.LoadStretch = v
    end)
    
    AddSlider(p, "Stretch Resolution", 1, 10, 1, function(v)
        State.StretchResolution = v
    end)
    
    AddSpacer(p, 6)
    AddSection(p, "Skybox")
    
    AddButton(p, "Open Skybox Picker", "›", function()
        SwitchTab("Skybox")
    end)
    
    AddButton(p, "Restore Default Sky", "›", function()
        local sky = Lighting:FindFirstChildOfClass("Sky")
        if sky then sky:Destroy() end
        Notify("Skybox", "Default sky restored")
    end)
end

-- ============================================================
-- TAB CONTENT — CROSSHAIR
-- ============================================================
do
    local p = TabPages["Crosshair"]
    AddSection(p, "Crosshair")
    
    AddToggle(p, "Enable Custom Crosshair", nil, false, function(v)
        State.CustomCrosshair = v
    end)
    
    AddButton(p, "Open Cursor Picker", "›", function()
        Notify("Cursor Picker", "Select your crosshair style below")
    end)
    
    AddSpacer(p, 6)
    AddSection(p, "Style")
    
    AddPicker(p, "Crosshair Style", {"Dot", "Cross", "Circle", "Precision Dot", "Aim Cross", "None"}, "Dot", function(v)
        State.CrosshairStyle = v
    end)
    
    AddToggle(p, "Spin Crosshair", nil, false, function(v)
        State.SpinCrosshair = v
    end)
    
    AddSpacer(p, 6)
    AddSection(p, "Custom ID")
    
    local _, inputBox = AddInput(p, "Custom Cursor Asset ID", "Enter asset ID...", function(v)
        State.CrosshairID = v
    end)
end

-- ============================================================
-- TAB CONTENT — SKYBOX
-- ============================================================
do
    local p = TabPages["Skybox"]
    AddSection(p, "Skybox Picker")
    
    local skyboxes = {
        {name = "Space", id = "rbxassetid://1369742248"},
        {name = "Sunset", id = "rbxassetid://2235302726"},
        {name = "Night", id = "rbxassetid://151454684"},
        {name = "Dawn", id = "rbxassetid://2211590427"},
    }
    
    for _, sky in ipairs(skyboxes) do
        AddButton(p, sky.name .. " Skybox", "›", function()
            local existing = Lighting:FindFirstChildOfClass("Sky")
            if existing then existing:Destroy() end
            local newSky = Instance.new("Sky")
            newSky.Parent = Lighting
            Notify("Skybox", sky.name .. " applied")
        end)
    end
    
    AddButton(p, "Remove Skybox", "✕", function()
        local sky = Lighting:FindFirstChildOfClass("Sky")
        if sky then sky:Destroy() end
        Notify("Skybox", "Removed")
    end)
end

-- ============================================================
-- TAB CONTENT — WEBHOOK
-- ============================================================
do
    local p = TabPages["Webhook"]
    AddSection(p, "Discord Webhook")
    
    local _, webhookInput = AddInput(p, "Webhook URL", "https://discord.com/api/webhooks/...", function(v)
        State.WebhookURL = v
    end)
    
    AddToggle(p, "Enable Webhook", nil, false, function(v)
        State.WebhookEnabled = v
    end)
    
    AddSpacer(p, 6)
    AddSection(p, "Log Events")
    
    AddToggle(p, "Log Kills", nil, false, function(v)
        State.LogKills = v
    end)
    
    AddToggle(p, "Log Deaths", nil, false, function(v)
        State.LogDeaths = v
    end)
    
    AddToggle(p, "Log Role Each Round", nil, false, function(v)
        State.LogRole = v
    end)
    
    AddButton(p, "Send Test Message", "›", function()
        if State.WebhookURL == "" then
            Notify("Webhook", "No URL set")
            return
        end
        pcall(function()
            local payload = HttpService:JSONEncode({
                content = "**[KuraiSoftware]** Test message from " .. LocalPlayer.Name
            })
            -- Webhook logic handled externally
        end)
        Notify("Webhook", "Test sent")
    end)
end

-- ============================================================
-- TAB CONTENT — SETTINGS
-- ============================================================
do
    local p = TabPages["Settings"]
    AddSection(p, "Script")
    
    AddButton(p, "Reload Script", "›", function()
        Notify("Reload", "Reloading KuraiSoftware...")
        task.wait(0.5)
        -- loadstring(game:HttpGet(""))()
    end)
    
    AddButton(p, "Unload Script", "✕", function()
        ScreenGui:Destroy()
        Notify("Unloaded", "KuraiSoftware has been unloaded")
    end)
    
    AddSpacer(p, 6)
    AddSection(p, "Theme")
    
    AddPicker(p, "Accent Color", {"Red (default)", "Blue", "Purple", "Green", "Orange"}, "Red (default)", function(v)
        local colors = {
            ["Red (default)"] = Color3.fromRGB(180, 30, 30),
            ["Blue"]          = Color3.fromRGB(30, 100, 200),
            ["Purple"]        = Color3.fromRGB(120, 40, 200),
            ["Green"]         = Color3.fromRGB(40, 160, 60),
            ["Orange"]        = Color3.fromRGB(220, 120, 20),
        }
        local c = colors[v] or ACCENT_COLOR
        AccentLine.BackgroundColor3 = c
        CloseBtn.BackgroundColor3 = c
    end)
    
    AddSpacer(p, 6)
    AddSection(p, "Info")
    
    AddButton(p, "Script: " .. SCRIPT_NAME .. " v" .. SCRIPT_VERSION, "", nil)
    AddButton(p, "Discord: " .. SCRIPT_DISCORD, "", nil)
end

-- ============================================================
-- DRAWING — ESP & CAMLOCK FOV CIRCLE
-- ============================================================
local Drawings = {}

local function NewDrawing(type, props)
    local d = Drawing.new(type)
    for k, v in pairs(props) do
        d[k] = v
    end
    table.insert(Drawings, d)
    return d
end

local FOVCircle = NewDrawing("Circle", {
    Visible   = false,
    Radius    = 120,
    Color     = Color3.fromRGB(255, 255, 255),
    Thickness = 1,
    Filled    = false,
    Transparency = 0.8,
})

local ESPObjects = {}

local function ClearESP(player)
    if ESPObjects[player] then
        for _, d in pairs(ESPObjects[player]) do
            pcall(function() d:Remove() end)
        end
        ESPObjects[player] = nil
    end
end

local function CreateESP(player)
    ClearESP(player)
    ESPObjects[player] = {
        Box = NewDrawing("Square", {
            Visible   = false,
            Thickness = 1.5,
            Filled    = false,
            Color     = Color3.fromRGB(255, 255, 255),
        }),
        Name = NewDrawing("Text", {
            Visible   = false,
            Size      = 14,
            Center    = true,
            Outline   = true,
            Color     = Color3.fromRGB(255, 255, 255),
        }),
        Dist = NewDrawing("Text", {
            Visible   = false,
            Size      = 12,
            Center    = true,
            Outline   = true,
            Color     = Color3.fromRGB(200, 200, 200),
        }),
        HealthBar = NewDrawing("Square", {
            Visible   = false,
            Thickness = 1,
            Filled    = true,
            Color     = Color3.fromRGB(0, 255, 0),
        }),
        HealthBarBg = NewDrawing("Square", {
            Visible   = false,
            Thickness = 1,
            Filled    = true,
            Color     = Color3.fromRGB(0, 0, 0),
        }),
    }
end

for _, pl in ipairs(Players:GetPlayers()) do
    if pl ~= LocalPlayer then
        CreateESP(pl)
    end
end

Players.PlayerAdded:Connect(function(pl)
    task.wait(1)
    if pl ~= LocalPlayer then
        CreateESP(pl)
    end
end)

Players.PlayerRemoving:Connect(function(pl)
    ClearESP(pl)
end)

-- ============================================================
-- LOOP — MAIN RENDER
-- ============================================================
local function GetRoleColor(player)
    if RoleData.Murderer == player then return Color3.fromRGB(255, 50, 50) end
    if RoleData.Sheriff == player then return Color3.fromRGB(50, 150, 255) end
    return Color3.fromRGB(100, 255, 100)
end

local function WorldToViewport(pos)
    local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen, screenPos.Z
end

local function GetBoundingBox(char)
    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
    local onScreen = false
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            local corners = {
                part.CFrame * CFrame.new( part.Size.X/2,  part.Size.Y/2,  part.Size.Z/2),
                part.CFrame * CFrame.new(-part.Size.X/2,  part.Size.Y/2,  part.Size.Z/2),
                part.CFrame * CFrame.new( part.Size.X/2, -part.Size.Y/2,  part.Size.Z/2),
                part.CFrame * CFrame.new(-part.Size.X/2, -part.Size.Y/2,  part.Size.Z/2),
            }
            for _, c in ipairs(corners) do
                local sp, os = WorldToViewport(c.Position)
                if os then
                    onScreen = true
                    minX = math.min(minX, sp.X)
                    minY = math.min(minY, sp.Y)
                    maxX = math.max(maxX, sp.X)
                    maxY = math.max(maxY, sp.Y)
                end
            end
        end
    end
    if not onScreen then return nil end
    return minX, minY, maxX - minX, maxY - minY
end

RunService.RenderStepped:Connect(function()
    -- Detect roles each frame (lightweight check)
    DetectRoles()
    
    -- FOV Circle
    local camLockEnabled = State.CamLock
    FOVCircle.Visible = camLockEnabled
    if camLockEnabled then
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        FOVCircle.Radius = State.CamLockFOV
    end
    
    -- CamLock logic
    if State.CamLock then
        local target = State.CamLockTarget
        if not target then target = GetNearestPlayer() end
        
        if target and target.Character then
            local part = target.Character:FindFirstChild(State.CamLockPart)
                or target.Character:FindFirstChild("HumanoidRootPart")
            if part then
                local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
                local targetScreenPos, onScreen = WorldToViewport(part.Position)
                
                if onScreen then
                    local dist2D = (targetScreenPos - screenCenter).Magnitude
                    if dist2D <= State.CamLockFOV then
                        local smoothed = Camera.CFrame:Lerp(
                            CFrame.new(Camera.CFrame.Position, part.Position),
                            State.CamLockSmooth
                        )
                        Camera.CFrame = smoothed
                    end
                end
            end
        end
    end
    
    -- ESP
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl == LocalPlayer then continue end
        local esp = ESPObjects[pl]
        if not esp then continue end
        
        local char = pl.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        
        if not State.ESPEnabled or not char or not root or not hum then
            for _, d in pairs(esp) do d.Visible = false end
            continue
        end
        
        local myRoot = GetRootPart()
        if not myRoot then continue end
        
        local dist = GetDistance(myRoot.Position, root.Position)
        if dist > State.ESPMaxDist then
            for _, d in pairs(esp) do d.Visible = false end
            continue
        end
        
        local roleColor = GetRoleColor(pl)
        local headPos, onScreen = WorldToViewport(root.Position + Vector3.new(0, 3, 0))
        
        if not onScreen then
            for _, d in pairs(esp) do d.Visible = false end
            continue
        end
        
        -- Box
        if State.ESPBoxes then
            local x, y, w, h = GetBoundingBox(char)
            if x then
                local padding = 4
                esp.Box.Visible   = true
                esp.Box.Position  = Vector2.new(x - padding, y - padding)
                esp.Box.Size      = Vector2.new(w + padding*2, h + padding*2)
                esp.Box.Color     = roleColor
            else
                esp.Box.Visible = false
            end
        else
            esp.Box.Visible = false
        end
        
        -- Name
        if State.ESPNames then
            esp.Name.Visible   = true
            esp.Name.Text      = pl.Name
            esp.Name.Position  = headPos - Vector2.new(0, 18)
            esp.Name.Color     = roleColor
        else
            esp.Name.Visible = false
        end
        
        -- Distance
        if State.ESPDistance then
            esp.Dist.Visible   = true
            esp.Dist.Text      = "[" .. math.floor(dist) .. "]"
            esp.Dist.Position  = headPos - Vector2.new(0, 32)
            esp.Dist.Color     = TEXT_SECONDARY
        else
            esp.Dist.Visible = false
        end
        
        -- Health bar
        if State.ESPHealth and esp.Box.Visible then
            local hp    = hum.Health
            local maxHP = hum.MaxHealth
            local hpPct = hp / maxHP
            local boxX = esp.Box.Position.X - 6
            local boxY = esp.Box.Position.Y
            local boxH = esp.Box.Size.Y
            
            esp.HealthBarBg.Visible  = true
            esp.HealthBarBg.Position = Vector2.new(boxX, boxY)
            esp.HealthBarBg.Size     = Vector2.new(4, boxH)
            
            esp.HealthBar.Visible  = true
            esp.HealthBar.Position = Vector2.new(boxX, boxY + boxH * (1 - hpPct))
            esp.HealthBar.Size     = Vector2.new(4, boxH * hpPct)
            esp.HealthBar.Color    = Color3.fromRGB(
                math.floor(255 * (1 - hpPct)),
                math.floor(255 * hpPct),
                0
            )
        else
            esp.HealthBar.Visible   = false
            esp.HealthBarBg.Visible = false
        end
    end
    
    -- Walk speed maintain
    if State.WalkSpeed then
        local hum = GetHumanoid()
        if hum then hum.WalkSpeed = State.WalkSpeedValue end
    end
    
    -- Jump power maintain
    if State.JumpPower then
        local hum = GetHumanoid()
        if hum then hum.JumpPower = State.JumpPowerValue end
    end
    
    -- Noclip
    if State.Noclip then
        local char = GetCharacter()
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
    
    -- Loop go to target
    if State.LoopGotoTarget and State.TargetPlayer then
        local root = GetRootPart()
        local targetRoot = GetCharacterRoot(State.TargetPlayer)
        if root and targetRoot then
            root.CFrame = targetRoot.CFrame + Vector3.new(2, 2, 0)
        end
    end
end)

-- ============================================================
-- AUTO FARM LOOP
-- ============================================================
local farmConnection
RunService.Heartbeat:Connect(function()
    if not State.AutoFarm then
        return
    end
    
    local root = GetRootPart()
    if not root then return end
    
    -- Find nearest coin
    local nearestCoin, nearestDist = nil, math.huge
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name:lower():find("coin") and obj:IsA("BasePart") then
            local dist = GetDistance(root.Position, obj.Position)
            if dist < nearestDist then
                nearestCoin = obj
                nearestDist = dist
            end
        end
    end
    
    if nearestCoin then
        if State.FarmMode == "Nearest" or State.FarmMode == "Nearest + XP Farm" then
            root.CFrame = CFrame.new(nearestCoin.Position + Vector3.new(0, 3, 0))
        elseif State.FarmMode == "Randomize" then
            local rx = math.random(-30, 30)
            local rz = math.random(-30, 30)
            root.CFrame = CFrame.new(root.Position + Vector3.new(rx, 0, rz))
        end
    end
end)

-- ============================================================
-- FLY SYSTEM
-- ============================================================
local flyBV, flyBG
local function EnableFly()
    local root = GetRootPart()
    if not root then return end
    
    flyBV = Instance.new("BodyVelocity")
    flyBV.Velocity = Vector3.new(0, 0, 0)
    flyBV.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    flyBV.Parent = root
    
    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    flyBG.D = 50
    flyBG.Parent = root
end

local function DisableFly()
    if flyBV then flyBV:Destroy() flyBV = nil end
    if flyBG then flyBG:Destroy() flyBG = nil end
end

RunService.Heartbeat:Connect(function()
    if not State.Fly or not flyBV or not flyBG then
        if not State.Fly and flyBV then DisableFly() end
        return
    end
    
    if State.Fly and not flyBV then EnableFly() end
    
    local root = GetRootPart()
    if not root then return end
    
    local camCF = Camera.CFrame
    local velocity = Vector3.new(0, 0, 0)
    local speed = State.FlySpeed
    
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
        velocity = velocity + camCF.LookVector * speed
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
        velocity = velocity - camCF.LookVector * speed
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
        velocity = velocity - camCF.RightVector * speed
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
        velocity = velocity + camCF.RightVector * speed
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        velocity = velocity + Vector3.new(0, speed, 0)
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
        velocity = velocity - Vector3.new(0, speed, 0)
    end
    
    flyBV.Velocity = velocity
    flyBG.CFrame = camCF
end)

-- ============================================================
-- AUTO GRAB GUN
-- ============================================================
RunService.Heartbeat:Connect(function()
    if not State.AutoGrabGun then return end
    local root = GetRootPart()
    if not root then return end
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Tool") and obj.Name:lower():find("gun") then
            local part = obj:FindFirstChild("Handle") or obj:FindFirstChildOfClass("BasePart")
            if part then
                local dist = GetDistance(root.Position, part.Position)
                if dist < 20 then
                    LocalPlayer.Character.Humanoid:EquipTool(obj)
                end
            end
        end
    end
end)

-- ============================================================
-- ANTI FLING
-- ============================================================
RunService.Heartbeat:Connect(function()
    if not State.AntiFling then return end
    local root = GetRootPart()
    if not root then return end
    local vel = root.AssemblyLinearVelocity
    if vel.Magnitude > 200 then
        root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    end
end)

-- ============================================================
-- KEYBINDS
-- ============================================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    -- RightShift = toggle menu
    if input.KeyCode == Enum.KeyCode.RightShift then
        State.MenuOpen = not State.MenuOpen
        MainFrame.Visible = State.MenuOpen
    end
    
    -- Delete = unload
    if input.KeyCode == Enum.KeyCode.Delete then
        ScreenGui:Destroy()
    end
end)

-- ============================================================
-- CLOSE / MINIMIZE BUTTONS
-- ============================================================
CloseBtn.MouseButton1Click:Connect(function()
    State.MenuOpen = false
    MainFrame.Visible = false
end)

MinBtn.MouseButton1Click:Connect(function()
    local isMin = MainFrame.Size.Y.Offset == 50
    if isMin then
        Tween(MainFrame, TweenInfo.new(0.2), {Size = UDim2.new(0, 580, 0, 420)})
        ContentPanel.Visible = true
        Sidebar.Visible = true
    else
        Tween(MainFrame, TweenInfo.new(0.2), {Size = UDim2.new(0, 580, 0, 50)})
        ContentPanel.Visible = false
        Sidebar.Visible = false
    end
end)

-- ============================================================
-- OPEN BUTTON (when menu hidden)
-- ============================================================
local OpenBtn = Create("TextButton", {
    Name             = "KuraiOpenBtn",
    Parent           = ScreenGui,
    BackgroundColor3 = ACCENT_COLOR,
    BorderSizePixel  = 0,
    Position         = UDim2.new(0, 10, 0.5, -20),
    Size             = UDim2.new(0, 32, 0, 32),
    Text             = "K",
    Font             = Enum.Font.GothamBold,
    TextColor3       = Color3.fromRGB(255, 255, 255),
    TextSize         = 14,
    Visible          = false,
})
local OBCorner = Instance.new("UICorner")
OBCorner.CornerRadius = UDim.new(1, 0)
OBCorner.Parent = OpenBtn

MainFrame:GetPropertyChangedSignal("Visible"):Connect(function()
    OpenBtn.Visible = not MainFrame.Visible
end)

OpenBtn.MouseButton1Click:Connect(function()
    State.MenuOpen = true
    MainFrame.Visible = true
end)

-- ============================================================
-- CHARACTER ADDED — maintain mods
-- ============================================================
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if State.WalkSpeed then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = State.WalkSpeedValue end
    end
    if State.JumpPower then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = State.JumpPowerValue end
    end
    if State.Fly then
        task.wait(0.5)
        EnableFly()
    end
end)

-- ============================================================
-- STARTUP NOTIFICATION
-- ============================================================
task.wait(1)
Notify("Loaded", SCRIPT_NAME .. " v" .. SCRIPT_VERSION .. " — RShift to toggle", 5)

-- ============================================================
-- END OF KURAISOFTWARE
-- ============================================================

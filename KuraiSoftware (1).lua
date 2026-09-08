--[[
    ██╗  ██╗██╗   ██╗██████╗  █████╗ ██╗
    ██║ ██╔╝██║   ██║██╔══██╗██╔══██╗██║
    █████╔╝ ██║   ██║██████╔╝███████║██║
    ██╔═██╗ ██║   ██║██╔══██╗██╔══██║██║
    ██║  ██╗╚██████╔╝██║  ██║██║  ██║██║
    ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝
    KURAI SOFTWARE — v1.0.1
    discord.gg/kuraishop
    Single-File | Delta/Android Compatible
--]]

-- ============================================================
-- COMPAT LAYER — wrap every service so Delta doesn't die
-- ============================================================
local function safeService(name)
    local ok, svc = pcall(function() return game:GetService(name) end)
    return ok and svc or nil
end

local _Players     = safeService("Players")
local _TweenSvc    = safeService("TweenService")
local _RunSvc      = safeService("RunService")
local _UIS         = safeService("UserInputService")
local _StarterGui  = safeService("StarterGui")
local _HttpSvc     = safeService("HttpService")

-- Delta / mobile doesn't always have LocalPlayer immediately
local function getLocalPlayer()
    if not _Players then return nil end
    local lp = _Players.LocalPlayer
    if lp then return lp end
    -- wait up to 10s
    local t0 = tick()
    while not lp and tick() - t0 < 10 do
        task.wait(0.1)
        lp = _Players.LocalPlayer
    end
    return lp
end

local function getPlayerGui()
    local lp = getLocalPlayer()
    if not lp then return nil end
    -- try direct, then WaitForChild with timeout
    local pg = lp:FindFirstChildOfClass("PlayerGui")
    if pg then return pg end
    local ok, result = pcall(function() return lp:WaitForChild("PlayerGui", 8) end)
    return ok and result or nil
end

-- Safe tween — falls back to instant set if TweenService unavailable
local function safeTween(obj, prop, target, duration, style, dir)
    if not obj then return end
    if not _TweenSvc then
        pcall(function() obj[prop] = target end)
        return
    end
    local ok, err = pcall(function()
        style = style or Enum.EasingStyle.Quart
        dir   = dir   or Enum.EasingDirection.Out
        local info  = TweenInfo.new(duration or 0.4, style, dir)
        local tween = _TweenSvc:Create(obj, info, {[prop] = target})
        tween:Play()
    end)
    if not ok then pcall(function() obj[prop] = target end) end
end

-- Safe Instance.new
local function newInst(cls, parent, props)
    local ok, inst = pcall(Instance.new, cls)
    if not ok then return nil end
    for k,v in pairs(props or {}) do
        pcall(function() inst[k] = v end)
    end
    pcall(function() inst.Parent = parent end)
    return inst
end

-- Safe connect (returns dummy if svc missing)
local _dummy = {Disconnect = function() end}
local function safeConnect(signal, fn)
    if not signal then return _dummy end
    local ok, conn = pcall(function() return signal:Connect(fn) end)
    return ok and conn or _dummy
end

-- ============================================================
-- CORE
-- ============================================================
local KURAI_VERSION = "1.0.1"
local KURAI_DISCORD = "discord.gg/kuraishop"

local Core = {
    initialized    = false,
    panicMode      = false,
    debugMode      = false,
    sessionStart   = os.clock(),
    activeFeatures = {},
    eventHandlers  = {},
    cleanupTasks   = {},
    timers         = {},
    connections    = {},
    logs           = {},
    errors         = {},
}

-- ============================================================
-- PLATFORM
-- ============================================================
local Platform = {
    os           = "Unknown",
    executor     = "Unknown",
    capabilities = {
        ui=false, visuals=false, movement=true,
        combat=true, config=true, network=false,
        drawing=false, input=false, filesystem=false,
    },
    support = {},
}

function Platform.detect()
    -- OS
    if     _G["DELTA_ENV"]    then Platform.os = "Android"; Platform.executor = "Delta"
    elseif _G["Codex"]        then Platform.os = "Android"; Platform.executor = "Codex"
    elseif _G["syn"]          then Platform.os = "Windows"; Platform.executor = "Synapse Z"
    elseif _G["KRNL_LOADED"]  then Platform.os = "Windows"; Platform.executor = "KRNL"
    elseif _G["fluxus"]       then Platform.os = "Windows"; Platform.executor = "Fluxus"
    elseif _G["Hydrogen"]     then Platform.os = "Android"; Platform.executor = "Hydrogen"
    elseif _G["is_sirhurt_closure"] then Platform.os = "Windows"; Platform.executor = "SirHurt"
    else
        Platform.os       = (game and game.PlaceId) and "Windows" or "Unknown"
        Platform.executor = "Unknown"
    end

    Platform.capabilities.ui         = (_Players ~= nil)
    Platform.capabilities.drawing    = (rawget(_G,"Drawing") ~= nil)
    Platform.capabilities.filesystem = (rawget(_G,"writefile") ~= nil)
    Platform.capabilities.network    = (rawget(_G,"request") ~= nil or rawget(_G,"http") ~= nil or (_G["syn"] and _G["syn"].request ~= nil))
    Platform.capabilities.input      = (_UIS ~= nil)
    Platform.capabilities.visuals    = Platform.capabilities.drawing

    Platform.support = {{
        platform    = Platform.os,
        environment = Platform.executor,
        ui          = Platform.capabilities.ui       and "SUPPORTED" or "UNAVAILABLE",
        visual      = Platform.capabilities.visuals  and "SUPPORTED" or "PARTIAL",
        movement    = "SUPPORTED",
        combat      = "SUPPORTED",
        config      = "SUPPORTED",
    }}
    Platform.initialized = true
end

function Platform.featureAvailable()
    return not Core.panicMode
end

-- ============================================================
-- LOGGER
-- ============================================================
local Logger = {}
function Logger.log(cat, msg, level)
    table.insert(Core.logs, {
        timestamp = os.clock() - Core.sessionStart,
        category  = cat or "Core",
        message   = msg or "",
        level     = level or "INFO",
    })
    if Core.debugMode then
        pcall(print, string.format("[KURAI][%s] %s", cat, msg))
    end
end
function Logger.error(cat, feat, err)
    table.insert(Core.errors, {category=cat, featureName=feat, error=tostring(err)})
    Logger.log(cat, "ERROR in "..feat..": "..tostring(err), "ERROR")
end

-- ============================================================
-- EVENT MANAGER
-- ============================================================
local EventManager = {}
function EventManager.on(event, handler)
    if not Core.eventHandlers[event] then Core.eventHandlers[event] = {} end
    table.insert(Core.eventHandlers[event], handler)
end
function EventManager.fire(event, ...)
    if not Core.eventHandlers[event] then return end
    for _, h in ipairs(Core.eventHandlers[event]) do
        local ok, err = pcall(h, ...)
        if not ok then Logger.error("Event", event, err) end
    end
end

-- ============================================================
-- CLEANUP
-- ============================================================
local CleanupManager = {}
function CleanupManager.register(id, fn) Core.cleanupTasks[id] = fn end
function CleanupManager.runAll()
    for id, fn in pairs(Core.cleanupTasks) do
        pcall(fn)
    end
    Core.cleanupTasks = {}
end
function CleanupManager.run(id)
    if Core.cleanupTasks[id] then pcall(Core.cleanupTasks[id]) end
    Core.cleanupTasks[id] = nil
end

-- ============================================================
-- CONFIG
-- ============================================================
local Config = { current = {}, defaults = {
    startupAnimation     = true,
    animationSpeed       = 1.0,
    showLoadingDetails   = true,
    showLogo             = true,
    showProgressBar      = true,
    skipAnimationKeybind = "RightShift",
    theme                = "Dark",
    uiTransparency       = 0.05,
    uiScale              = 1.0,
    performanceMode      = false,
    debugMode            = false,
    espEnabled           = false,
    espRange             = 500,
    espThickness         = 1,
    aimbotEnabled        = false,
    silentAimEnabled     = false,
    aimFOV               = 90,
    speedEnabled         = false,
    walkSpeed            = 16,
    jumpPower            = 50,
    flyEnabled           = false,
    noclipEnabled        = false,
}, profiles={}, keybindProfiles={}, themeProfiles={} }

function Config.load()
    Config.current = {}
    for k,v in pairs(Config.defaults) do Config.current[k] = v end
    if Platform.capabilities.filesystem and _HttpSvc then
        pcall(function()
            if isfile("kurai_config.json") then
                local data = _HttpSvc:JSONDecode(readfile("kurai_config.json"))
                for k,v in pairs(data) do Config.current[k] = v end
            end
        end)
    end
end
function Config.save()
    if Platform.capabilities.filesystem and _HttpSvc then
        pcall(function()
            writefile("kurai_config.json", _HttpSvc:JSONEncode(Config.current))
        end)
    end
end
function Config.reset()
    Config.current = {}
    for k,v in pairs(Config.defaults) do Config.current[k] = v end
    Config.save()
end
function Config.get(k) return Config.current[k] end
function Config.set(k,v) Config.current[k]=v; Config.save() end

-- ============================================================
-- PERFORMANCE
-- ============================================================
local Performance = { fps=0, ping=0, memory=0, history={fps={},ping={}}, running=false }
function Performance.start()
    if Performance.running or not _RunSvc then return end
    Performance.running = true
    local lastTick, frames = tick(), 0
    local conn = safeConnect(_RunSvc.Heartbeat, function()
        if Core.panicMode then return end
        frames = frames + 1
        local now = tick()
        if now - lastTick >= 1 then
            Performance.fps = frames
            table.insert(Performance.history.fps, frames)
            if #Performance.history.fps > 60 then table.remove(Performance.history.fps, 1) end
            frames, lastTick = 0, now
        end
    end)
    table.insert(Core.connections, conn)
    CleanupManager.register("Performance", function()
        conn:Disconnect(); Performance.running = false
    end)
end

-- ============================================================
-- STATISTICS
-- ============================================================
local Statistics = {
    sessionTime=0, totalKills=0, totalDeaths=0, coinsCollected=0,
    roundsPlayed=0, roundsWon=0, roundsLost=0, murdererWins=0,
    sheriffWins=0, innocentWins=0, bestStreak=0, currentStreak=0, history={}
}
function Statistics.getKD()
    if Statistics.totalDeaths == 0 then return Statistics.totalKills end
    return math.floor((Statistics.totalKills/Statistics.totalDeaths)*100)/100
end
function Statistics.reset()
    Statistics.totalKills=0; Statistics.totalDeaths=0; Statistics.coinsCollected=0
    Statistics.roundsPlayed=0; Statistics.roundsWon=0; Statistics.roundsLost=0
    Statistics.bestStreak=0; Statistics.currentStreak=0
end

-- ============================================================
-- FEATURE MANAGER
-- ============================================================
local FeatureManager = { registry={} }
local function makeFeature(id, name, cat, desc)
    return { id=id, name=name, category=cat, description=desc,
             enabled=false, status="IDLE", settings={}, keybind=nil,
             dependencies={}, supportedPlatforms={"Windows","Android","iOS","macOS"},
             cleanupHandler=nil }
end
function FeatureManager.register(f) FeatureManager.registry[f.id] = f end
function FeatureManager.enable(id)
    local f = FeatureManager.registry[id]
    if not f or not Platform.featureAvailable() then return false end
    f.enabled=true; f.status="ACTIVE"; Core.activeFeatures[id]=true
    EventManager.fire("FeatureEnabled", f)
    return true
end
function FeatureManager.disable(id)
    local f = FeatureManager.registry[id]
    if not f then return false end
    f.enabled=false; f.status="IDLE"; Core.activeFeatures[id]=nil
    if f.cleanupHandler then pcall(f.cleanupHandler) end
    EventManager.fire("FeatureDisabled", f)
    return true
end
function FeatureManager.toggle(id)
    local f = FeatureManager.registry[id]
    if not f then return end
    if f.enabled then FeatureManager.disable(id) else FeatureManager.enable(id) end
end
function FeatureManager.disableAll()
    for id in pairs(Core.activeFeatures) do FeatureManager.disable(id) end
end

local function registerAllFeatures()
    local list = {
        -- ESP
        {"esp_player","Player ESP","ESP","Highlight all players"},
        {"esp_murderer","Murderer ESP","ESP","Highlight murderers"},
        {"esp_sheriff","Sheriff ESP","ESP","Highlight sheriffs"},
        {"esp_hero","Hero ESP","ESP","Highlight heroes"},
        {"esp_innocent","Innocent ESP","ESP","Highlight innocents"},
        {"esp_role","Role ESP","ESP","Show roles above players"},
        {"esp_name","Name ESP","ESP","Show player names"},
        {"esp_distance","Distance ESP","ESP","Show distance to players"},
        {"esp_health","Health ESP","ESP","Show player health bars"},
        {"esp_box","Box ESP","ESP","Draw boxes around players"},
        {"esp_corner_box","Corner Box","ESP","Corner-style boxes"},
        {"esp_skeleton","Skeleton ESP","ESP","Draw player skeletons"},
        {"esp_tracer","Tracer ESP","ESP","Draw tracer lines"},
        {"esp_chams","Chams","ESP","Color players through walls"},
        {"esp_gun","Gun ESP","ESP","Highlight guns"},
        {"esp_knife","Knife ESP","ESP","Highlight knives"},
        {"esp_coin","Coin ESP","ESP","Highlight coins"},
        {"esp_item","Item ESP","ESP","Highlight all items"},
        {"esp_drop","Dropped Item ESP","ESP","Highlight dropped items"},
        {"esp_dead","Dead Player ESP","ESP","Show dead players"},
        {"esp_offscreen","Off-Screen Arrows","ESP","Arrow indicators off-screen"},
        {"esp_rainbow","Rainbow ESP","ESP","Rainbow color cycling ESP"},
        -- Combat
        {"combat_autofling","Auto Fling","Combat","Automatically fling targets"},
        {"combat_autotarget","Auto Target","Combat","Automatically acquire targets"},
        {"combat_aimbot","Aimbot","Combat","Full aimbot assistance"},
        {"combat_silentaim","Silent Aim","Combat","Silent aim assistance"},
        {"combat_autoshoot","Auto Shoot","Combat","Automatically shoot"},
        {"combat_autostab","Auto Stab","Combat","Automatically stab"},
        {"combat_autothrow","Auto Throw","Combat","Automatically throw knives"},
        {"combat_reach","Reach","Combat","Extended melee reach"},
        {"combat_hitbox","Hitbox Expander","Combat","Expand target hitboxes"},
        {"combat_hitbox_vis","Hitbox Visualizer","Combat","Visualize hitboxes"},
        {"combat_damage_indicator","Damage Indicator","Combat","Show damage dealt"},
        {"combat_rage_preset","Rage Preset","Combat","Maximum aggression preset"},
        {"combat_legit_preset","Legit Preset","Combat","Subtle assistance preset"},
        -- Movement
        {"move_speed","Speed","Movement","Increase walk speed"},
        {"move_infjump","Infinite Jump","Movement","Jump infinitely in air"},
        {"move_fly","Fly","Movement","Enable flight"},
        {"move_noclip","Noclip","Movement","Phase through walls"},
        {"move_gravity","Gravity Control","Movement","Modify gravity"},
        {"move_airwalk","Air Walk","Movement","Walk on air"},
        {"move_bunnyhop","Bunny Hop","Movement","Automatic bunny hop"},
        {"move_dash","Dash","Movement","Quick dash ability"},
        {"move_tpwalk","TP Walk","Movement","Teleport-based movement"},
        {"move_spin","Spin","Movement","Character spin"},
        {"move_autojump","Auto Jump","Movement","Automatically jump"},
        {"move_freecam","Freecam","Movement","Detached free camera"},
        -- Farm
        {"farm_autocollect","Auto Collect","Farm","Automatically collect coins"},
        {"farm_coin_farm","Coin Farm","Farm","Farm coins automatically"},
        {"farm_coin_aura","Coin Aura","Farm","Collect nearby coins passively"},
        {"farm_autofarm","Auto Farm","Farm","Full auto-farm loop"},
        {"farm_item_finder","Item Finder","Farm","Locate items on map"},
        {"farm_gun_finder","Gun Finder","Farm","Locate guns on map"},
        -- Intelligence
        {"intel_role_detect","Role Detector","Intelligence","Detect player roles"},
        {"intel_murderer_detect","Murderer Detector","Intelligence","Identify murderer"},
        {"intel_sheriff_detect","Sheriff Detector","Intelligence","Identify sheriff"},
        {"intel_round_detect","Round Detector","Intelligence","Detect round state"},
        {"intel_gun_drop","Gun Drop Detector","Intelligence","Detect dropped guns"},
        {"intel_murderer_alert","Murderer Alert","Intelligence","Alert when murderer found"},
        {"intel_gun_alert","Gun Drop Alert","Intelligence","Alert when gun dropped"},
        -- Misc
        {"misc_notifs","Notifications","Misc","In-game notifications"},
        {"misc_screenshot","Screenshot Mode","Misc","Hide UI for screenshots"},
        {"misc_streamer","Streamer Mode","Misc","Streamer-safe mode"},
        {"misc_hide_ui","Hide UI","Misc","Toggle UI visibility"},
        {"misc_debug","Debug Mode","Misc","Show debug information"},
        {"misc_perf_mode","Performance Mode","Misc","Optimize for performance"},
        {"misc_fps_monitor","FPS Monitor","Misc","Display FPS counter"},
        {"misc_ping_monitor","Ping Monitor","Misc","Display ping counter"},
        -- Visual
        {"visual_crosshair","Crosshair","Visual","Custom crosshair overlay"},
        {"visual_hit_effects","Hit Effects","Visual","Visual hit effects"},
        {"visual_kill_effects","Kill Effects","Visual","Visual kill effects"},
        {"visual_cam_shake","Camera Shake","Visual","Camera shake on hit"},
        {"visual_fov_slider","FOV Slider","Visual","Adjust camera FOV"},
        {"visual_thirdperson","Third Person View","Visual","Third-person visual mode"},
        {"visual_ui_blur","UI Blur","Visual","Blur background behind UI"},
    }
    for _, f in ipairs(list) do
        FeatureManager.register(makeFeature(f[1],f[2],f[3],f[4]))
    end
    Logger.log("FeatureManager", tostring(#list).." features registered.")
end

-- ============================================================
-- KEYBIND MANAGER
-- ============================================================
local KeybindManager = { binds={}, active=true }
function KeybindManager.bind(key, featureId, fn)
    KeybindManager.binds[key] = { featureId=featureId, fn=fn or function() FeatureManager.toggle(featureId) end }
end
function KeybindManager.init()
    if not _UIS then return end
    local conn = safeConnect(_UIS.InputBegan, function(input, gpe)
        if gpe or not KeybindManager.active then return end
        local key = tostring(input.KeyCode)
        if KeybindManager.binds[key] then pcall(KeybindManager.binds[key].fn) end
    end)
    table.insert(Core.connections, conn)
    CleanupManager.register("KeybindManager", function() conn:Disconnect() end)
end

-- ============================================================
-- NOTIFICATION MANAGER
-- ============================================================
local NotificationManager = { queue={}, history={} }
function NotificationManager.send(title, message, ntype, duration)
    local n = { title=title or "Kurai", message=message or "",
                type=ntype or "INFO", duration=duration or 3, timestamp=os.clock() }
    table.insert(NotificationManager.queue, n)
    table.insert(NotificationManager.history, n)
    if _StarterGui then
        pcall(function()
            _StarterGui:SetCore("SendNotification",
                {Title=n.title, Text=n.message, Duration=n.duration})
        end)
    end
    Logger.log("Notif", n.title.." — "..n.message)
end

-- ============================================================
-- PANIC BUTTON
-- ============================================================
local PanicButton = {}
function PanicButton.activate()
    Core.panicMode = true
    FeatureManager.disableAll()
    for _, c in ipairs(Core.connections) do pcall(function() c:Disconnect() end) end
    Core.connections = {}
    CleanupManager.runAll()
    NotificationManager.send("KURAI","ALL FEATURES DISABLED","PANIC",5)
    Logger.log("Panic","PANIC ACTIVATED")
end

-- ============================================================
-- TARGET MANAGER
-- ============================================================
local TargetManager = {
    whitelist={}, blacklist={}, locked=nil,
    filters={ ignoreDead=true, maxDistance=500, roleFilter="All" }
}
function TargetManager.getNearest(origin)
    local nearest, dist = nil, math.huge
    if not _Players then return nil end
    local lp = getLocalPlayer()
    for _, p in ipairs(_Players:GetPlayers()) do
        if p ~= lp and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
            local d = (p.Character.HumanoidRootPart.Position - origin).Magnitude
            if d < dist and not TargetManager.blacklist[p.Name] then
                nearest, dist = p, d
            end
        end
    end
    return nearest, dist
end
function TargetManager.lock(p)
    TargetManager.locked = p
    if p then NotificationManager.send("Target","Locked: "..p.Name,"INFO",2) end
end
function TargetManager.unlock() TargetManager.locked = nil end
function TargetManager.addToWhitelist(n) TargetManager.whitelist[n]=true end
function TargetManager.addToBlacklist(n) TargetManager.blacklist[n]=true end

-- ============================================================
-- SERVER INFO
-- ============================================================
local ServerInfo = { jobId="", playerCount=0, maxPlayers=0, ping=0 }
function ServerInfo.refresh()
    if not _Players then return end
    pcall(function()
        ServerInfo.jobId       = game.JobId or ""
        ServerInfo.playerCount = #_Players:GetPlayers()
        ServerInfo.maxPlayers  = _Players.MaxPlayers or 0
    end)
end

-- ============================================================
-- THEMES
-- ============================================================
local ThemeManager = {
    current = "Dark",
    themes = {
        Dark = {
            bg=Color3.fromRGB(12,12,18), bgSecondary=Color3.fromRGB(18,18,28),
            bgTertiary=Color3.fromRGB(24,24,38), accent=Color3.fromRGB(120,80,255),
            text=Color3.fromRGB(220,220,240), textDim=Color3.fromRGB(140,140,160),
            border=Color3.fromRGB(40,40,60), success=Color3.fromRGB(80,200,120),
            warning=Color3.fromRGB(240,180,60), danger=Color3.fromRGB(240,70,70),
            info=Color3.fromRGB(80,160,240),
        },
        Midnight = {
            bg=Color3.fromRGB(5,5,12), bgSecondary=Color3.fromRGB(10,10,22),
            bgTertiary=Color3.fromRGB(15,15,32), accent=Color3.fromRGB(60,120,255),
            text=Color3.fromRGB(200,210,255), textDim=Color3.fromRGB(120,130,180),
            border=Color3.fromRGB(25,30,60), success=Color3.fromRGB(60,200,140),
            warning=Color3.fromRGB(240,200,60), danger=Color3.fromRGB(255,60,80),
            info=Color3.fromRGB(60,180,255),
        },
        Neon = {
            bg=Color3.fromRGB(8,8,8), bgSecondary=Color3.fromRGB(14,14,14),
            bgTertiary=Color3.fromRGB(20,20,20), accent=Color3.fromRGB(0,255,160),
            text=Color3.fromRGB(230,255,240), textDim=Color3.fromRGB(130,180,150),
            border=Color3.fromRGB(30,60,45), success=Color3.fromRGB(0,255,100),
            warning=Color3.fromRGB(255,200,0), danger=Color3.fromRGB(255,50,80),
            info=Color3.fromRGB(0,200,255),
        },
        Glass = {
            bg=Color3.fromRGB(20,20,35), bgSecondary=Color3.fromRGB(30,30,50),
            bgTertiary=Color3.fromRGB(40,40,65), accent=Color3.fromRGB(180,140,255),
            text=Color3.fromRGB(240,235,255), textDim=Color3.fromRGB(160,155,185),
            border=Color3.fromRGB(60,60,90), success=Color3.fromRGB(100,220,140),
            warning=Color3.fromRGB(255,190,80), danger=Color3.fromRGB(255,80,100),
            info=Color3.fromRGB(100,180,255),
        },
        AMOLED = {
            bg=Color3.fromRGB(0,0,0), bgSecondary=Color3.fromRGB(8,8,8),
            bgTertiary=Color3.fromRGB(14,14,14), accent=Color3.fromRGB(200,60,255),
            text=Color3.fromRGB(255,255,255), textDim=Color3.fromRGB(160,160,160),
            border=Color3.fromRGB(30,30,30), success=Color3.fromRGB(60,255,120),
            warning=Color3.fromRGB(255,200,0), danger=Color3.fromRGB(255,40,60),
            info=Color3.fromRGB(60,160,255),
        },
    }
}
function ThemeManager.get() return ThemeManager.themes[ThemeManager.current] or ThemeManager.themes.Dark end
function ThemeManager.set(name)
    if ThemeManager.themes[name] then
        ThemeManager.current = name
        Config.set("theme", name)
        EventManager.fire("ThemeChanged", name)
    end
end

-- ============================================================
-- UI
-- ============================================================
local UI = {
    gui=nil, startupFrame=nil, dashboardFrame=nil, shadowFrame=nil,
    sidebarFrame=nil, contentFrame=nil,
    activeTab="Dashboard", favorites={}, recentlyUsed={},
    isVisible=true, animating=false,
}

function UI.init()
    if not _Players then
        Logger.log("UI","No Players service — headless mode")
        return false
    end
    local lp = getLocalPlayer()
    if not lp then Logger.log("UI","No LocalPlayer"); return false end
    local pg = getPlayerGui()
    if not pg then Logger.log("UI","No PlayerGui"); return false end

    -- destroy existing
    local existing = pg:FindFirstChild("KuraiSoftwareUI")
    if existing then existing:Destroy() end

    local gui = newInst("ScreenGui", pg, {
        Name="KuraiSoftwareUI", ResetOnSpawn=false,
        ZIndexBehavior=Enum.ZIndexBehavior.Sibling, DisplayOrder=999,
    })
    if not gui then Logger.log("UI","Failed to create ScreenGui"); return false end
    UI.gui = gui
    Logger.log("UI","ScreenGui created OK")
    return true
end

-- ---- Startup Screen ----
function UI.buildStartupScreen()
    local theme = ThemeManager.get()
    local startup = newInst("Frame", UI.gui, {
        Name="StartupScreen", Size=UDim2.fromScale(1,1), Position=UDim2.fromScale(0,0),
        BackgroundColor3=theme.bg, BorderSizePixel=0, ZIndex=100,
    })
    UI.startupFrame = startup

    newInst("UIGradient", startup, {
        Color=ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(20,10,40)),
            ColorSequenceKeypoint.new(0.5, theme.bg),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(8,4,20)),
        }), Rotation=135,
    })

    local glow = newInst("Frame", startup, {
        Name="GlowCircle", Size=UDim2.fromOffset(320,320),
        Position=UDim2.new(0.5,-160,0.4,-200),
        BackgroundColor3=theme.accent, BorderSizePixel=0,
        BackgroundTransparency=0.92, ZIndex=101,
    })
    newInst("UICorner", glow, {CornerRadius=UDim.new(1,0)})

    local logo = newInst("TextLabel", startup, {
        Name="Logo", Text="KURAI", Font=Enum.Font.GothamBold,
        TextSize=60, TextColor3=theme.text, TextTransparency=1,
        BackgroundTransparency=1, Size=UDim2.new(1,0,0,90),
        Position=UDim2.new(0,0,0.30,0), TextXAlignment=Enum.TextXAlignment.Center, ZIndex=102,
    })

    local subtitle = newInst("TextLabel", startup, {
        Name="Subtitle", Text="SOFTWARE", Font=Enum.Font.Gotham,
        TextSize=20, TextColor3=theme.accent, TextTransparency=1,
        BackgroundTransparency=1, Size=UDim2.new(1,0,0,30),
        Position=UDim2.new(0,0,0.42,0), TextXAlignment=Enum.TextXAlignment.Center, ZIndex=102,
    })

    local discord = newInst("TextLabel", startup, {
        Name="Discord", Text=KURAI_DISCORD, Font=Enum.Font.GothamMedium,
        TextSize=13, TextColor3=theme.textDim, TextTransparency=1,
        BackgroundTransparency=1, Size=UDim2.new(1,0,0,20),
        Position=UDim2.new(0,0,0.49,0), TextXAlignment=Enum.TextXAlignment.Center, ZIndex=102,
    })

    local line = newInst("Frame", startup, {
        Name="Line", Size=UDim2.new(0,0,0,1), Position=UDim2.new(0.2,0,0.60,0),
        BackgroundColor3=theme.accent, BackgroundTransparency=0.4,
        BorderSizePixel=0, ZIndex=102,
    })

    local statusLbl = newInst("TextLabel", startup, {
        Name="Status", Text="Initializing Kurai...", Font=Enum.Font.GothamMedium,
        TextSize=13, TextColor3=theme.textDim, TextTransparency=1,
        BackgroundTransparency=1, Size=UDim2.new(0.6,0,0,20),
        Position=UDim2.new(0.2,0,0.63,0), TextXAlignment=Enum.TextXAlignment.Left, ZIndex=103,
    })

    local progressBG = newInst("Frame", startup, {
        Name="ProgressBG", Size=UDim2.new(0.6,0,0,4),
        Position=UDim2.new(0.2,0,0.68,0),
        BackgroundColor3=theme.border, BackgroundTransparency=0.4,
        BorderSizePixel=0, ZIndex=102,
    })
    newInst("UICorner", progressBG, {CornerRadius=UDim.new(1,0)})

    local progressFill = newInst("Frame", progressBG, {
        Name="Fill", Size=UDim2.new(0,0,1,0), Position=UDim2.fromScale(0,0),
        BackgroundColor3=theme.accent, BorderSizePixel=0, ZIndex=103,
    })
    newInst("UICorner", progressFill, {CornerRadius=UDim.new(1,0)})
    newInst("UIGradient", progressFill, {
        Color=ColorSequence.new({
            ColorSequenceKeypoint.new(0,theme.accent),
            ColorSequenceKeypoint.new(1,Color3.fromRGB(200,160,255)),
        })
    })

    newInst("TextLabel", startup, {
        Text="v"..KURAI_VERSION, Font=Enum.Font.Gotham, TextSize=11,
        TextColor3=theme.textDim, BackgroundTransparency=1,
        Size=UDim2.new(0,60,0,18), Position=UDim2.new(1,-68,1,-26),
        TextXAlignment=Enum.TextXAlignment.Right, ZIndex=102,
    })

    newInst("TextLabel", startup, {
        Text="RightShift to skip", Font=Enum.Font.Gotham, TextSize=11,
        TextColor3=theme.textDim, TextTransparency=0.5, BackgroundTransparency=1,
        Size=UDim2.new(0,150,0,18), Position=UDim2.new(0,10,1,-26),
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=102,
    })

    return { glow=glow, logo=logo, subtitle=subtitle, discord=discord,
             line=line, statusLbl=statusLbl, progressFill=progressFill }
end

function UI.playStartupAnimation(els, onComplete)
    local speed   = 1 / math.max(Config.get("animationSpeed") or 1.0, 0.1)
    local skipped = false

    if _UIS then
        local sc = safeConnect(_UIS.InputBegan, function(inp, gpe)
            if gpe then return end
            if tostring(inp.KeyCode):find("RightShift") then skipped = true end
        end)
        table.insert(Core.connections, sc)
    end

    local function wait(t)
        local s = tick()
        while tick()-s < t*speed do
            if skipped then return end
            task.wait(0.016)
        end
    end

    local function status(txt, pct)
        if els.statusLbl then els.statusLbl.Text = txt end
        if els.progressFill then
            safeTween(els.progressFill, "Size", UDim2.new(pct,0,1,0), 0.3*speed)
        end
    end

    -- animate in
    safeTween(els.glow,     "BackgroundTransparency", 0.84, 0.8*speed); wait(0.25)
    safeTween(els.logo,     "TextTransparency", 0, 0.7*speed);           wait(0.35)
    safeTween(els.subtitle, "TextTransparency", 0, 0.5*speed)
    safeTween(els.discord,  "TextTransparency", 0, 0.5*speed);           wait(0.3)
    safeTween(els.line,     "Size", UDim2.new(0.6,0,0,1), 0.45*speed);   wait(0.15)
    safeTween(els.statusLbl,"TextTransparency", 0, 0.25*speed);           wait(0.15)

    local steps = {
        {"Initializing Kurai...",   0.08},
        {"Detecting environment...",0.22},
        {"Loading modules...",      0.42},
        {"Loading interface...",    0.60},
        {"Checking environment...", 0.72},
        {"Loading configuration...",0.88},
        {"Ready.",                  1.0 },
    }
    for _, s in ipairs(steps) do
        if skipped then break end
        status(s[1], s[2]); wait(0.26)
    end
    status("Ready.", 1.0); wait(0.45)

    -- fade out
    if UI.startupFrame then
        safeTween(UI.startupFrame, "BackgroundTransparency", 1, 0.4*speed)
        for _, child in ipairs(UI.startupFrame:GetDescendants()) do
            if child:IsA("TextLabel") then
                safeTween(child, "TextTransparency", 1, 0.35*speed)
            elseif child:IsA("Frame") then
                safeTween(child, "BackgroundTransparency", 1, 0.35*speed)
            end
        end
        wait(0.45)
        pcall(function() UI.startupFrame.Visible = false end)
    end

    if onComplete then onComplete() end
end

-- ---- Dashboard ----
function UI.buildDashboard()
    local theme = ThemeManager.get()

    local shadow = newInst("ImageLabel", UI.gui, {
        Name="Shadow", Size=UDim2.new(0.9,0,0.87,0),
        Position=UDim2.new(0.05,0,0.075,8),
        BackgroundTransparency=1, Image="rbxassetid://7912134082",
        ImageColor3=Color3.fromRGB(0,0,0), ImageTransparency=0.6,
        ZIndex=9, Visible=false,
    })
    UI.shadowFrame = shadow

    local dash = newInst("Frame", UI.gui, {
        Name="Dashboard", Size=UDim2.new(0.88,0,0.85,0),
        Position=UDim2.new(0.06,0,0.075,0),
        BackgroundColor3=theme.bg, BorderSizePixel=0,
        BackgroundTransparency=0.02, Visible=false, ZIndex=10,
    })
    newInst("UICorner", dash, {CornerRadius=UDim.new(0,12)})
    newInst("UIStroke", dash, {Color=theme.border, Thickness=1, Transparency=0.3})
    UI.dashboardFrame = dash

    -- Titlebar
    local tb = newInst("Frame", dash, {
        Name="Titlebar", Size=UDim2.new(1,0,0,46),
        BackgroundColor3=theme.bgSecondary, BorderSizePixel=0, ZIndex=11,
    })
    newInst("UICorner", tb, {CornerRadius=UDim.new(0,12)})
    newInst("Frame", tb, { -- fix bottom corners
        Size=UDim2.new(1,0,0.5,0), Position=UDim2.new(0,0,0.5,0),
        BackgroundColor3=theme.bgSecondary, BorderSizePixel=0, ZIndex=11,
    })

    -- accent dot
    local dot = newInst("Frame", tb, {
        Size=UDim2.new(0,8,0,8), Position=UDim2.new(0,16,0.5,-4),
        BackgroundColor3=theme.accent, BorderSizePixel=0, ZIndex=12,
    })
    newInst("UICorner", dot, {CornerRadius=UDim.new(1,0)})

    newInst("TextLabel", tb, {
        Text="KURAI SOFTWARE", Font=Enum.Font.GothamBold, TextSize=14,
        TextColor3=theme.text, BackgroundTransparency=1,
        Size=UDim2.new(0,200,1,0), Position=UDim2.new(0,32,0,0),
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=12,
    })

    -- Close btn
    local closeBtn = newInst("TextButton", tb, {
        Text="✕", Font=Enum.Font.GothamBold, TextSize=13,
        TextColor3=Color3.fromRGB(255,255,255),
        BackgroundColor3=Color3.fromRGB(255,70,70), BackgroundTransparency=0.5,
        Size=UDim2.new(0,26,0,26), Position=UDim2.new(1,-36,0.5,-13), ZIndex=12,
    })
    newInst("UICorner", closeBtn, {CornerRadius=UDim.new(0,6)})

    -- Panic btn
    local panicBtn = newInst("TextButton", tb, {
        Text="⚠", Font=Enum.Font.GothamBold, TextSize=13,
        TextColor3=theme.warning, BackgroundColor3=theme.bgTertiary,
        BackgroundTransparency=0.4, Size=UDim2.new(0,26,0,26),
        Position=UDim2.new(1,-68,0.5,-13), ZIndex=12,
    })
    newInst("UICorner", panicBtn, {CornerRadius=UDim.new(0,6)})

    -- Search
    local searchF = newInst("Frame", tb, {
        Size=UDim2.new(0,220,0,26), Position=UDim2.new(0.5,-110,0.5,-13),
        BackgroundColor3=theme.bgTertiary, BorderSizePixel=0, ZIndex=12,
    })
    newInst("UICorner", searchF, {CornerRadius=UDim.new(0,6)})
    newInst("TextBox", searchF, {
        Text="", PlaceholderText="🔍  Search...",
        Font=Enum.Font.Gotham, TextSize=12,
        TextColor3=theme.text, PlaceholderColor3=theme.textDim,
        BackgroundTransparency=1, Size=UDim2.new(1,-12,1,0),
        Position=UDim2.new(0,8,0,0), TextXAlignment=Enum.TextXAlignment.Left,
        ZIndex=13, ClearTextOnFocus=false,
    })

    -- Sidebar
    local sidebar = newInst("Frame", dash, {
        Size=UDim2.new(0,178,1,-46), Position=UDim2.new(0,0,0,46),
        BackgroundColor3=theme.bgSecondary, BorderSizePixel=0, ZIndex=11,
    })
    newInst("UICorner", sidebar, {CornerRadius=UDim.new(0,12)})
    newInst("Frame", sidebar, {
        Size=UDim2.new(0.5,0,1,0), Position=UDim2.new(0.5,0,0,0),
        BackgroundColor3=theme.bgSecondary, BorderSizePixel=0, ZIndex=11,
    })

    local sidebarList = newInst("ScrollingFrame", sidebar, {
        Size=UDim2.new(1,0,1,-8), Position=UDim2.new(0,0,0,8),
        BackgroundTransparency=1, BorderSizePixel=0,
        ScrollBarThickness=3, AutomaticCanvasSize=Enum.AutomaticSize.Y,
        CanvasSize=UDim2.new(0,0,0,0), ZIndex=12,
    })
    newInst("UIPadding", sidebarList, {
        PaddingLeft=UDim.new(0,6), PaddingRight=UDim.new(0,6), PaddingTop=UDim.new(0,4),
    })
    newInst("UIListLayout", sidebarList, {SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,3)})
    UI.sidebarFrame = sidebarList

    -- Content
    local content = newInst("ScrollingFrame", dash, {
        Size=UDim2.new(1,-186,1,-54), Position=UDim2.new(0,182,0,50),
        BackgroundTransparency=1, BorderSizePixel=0,
        ScrollBarThickness=3, AutomaticCanvasSize=Enum.AutomaticSize.Y,
        CanvasSize=UDim2.new(0,0,0,0), ZIndex=11,
    })
    newInst("UIPadding", content, {
        PaddingLeft=UDim.new(0,8), PaddingRight=UDim.new(0,8),
        PaddingTop=UDim.new(0,8), PaddingBottom=UDim.new(0,8),
    })
    newInst("UIListLayout", content, {SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,6)})
    UI.contentFrame = content

    -- Wire buttons
    safeConnect(closeBtn.MouseButton1Click,  function() UI.hide() end)
    safeConnect(panicBtn.MouseButton1Click, function()
        PanicButton.activate()
    end)

    -- Build tabs
    local tabs = {
        {"Dashboard","⬛"},{"ESP","👁"},{"Combat","⚔"},{"Movement","💨"},
        {"Farm","💰"},{"Intelligence","🧠"},{"Targets","🎯"},{"Visual","✨"},
        {"Misc","⚙"},{"Statistics","📊"},{"Server","🌐"},{"Themes","🎨"},
        {"Config","💾"},{"Performance","⚡"},{"Compatibility","✅"},{"Logs","📋"},
    }
    for i, t in ipairs(tabs) do UI.createSidebarTab(t[1], t[2], i) end
    UI.switchTab("Dashboard")
end

function UI.createSidebarTab(name, icon, order)
    local theme    = ThemeManager.get()
    local isActive = (name == UI.activeTab)
    local btn = newInst("TextButton", UI.sidebarFrame, {
        Name="Tab_"..name, Text=(icon or "").."  "..name,
        Font=Enum.Font.GothamMedium, TextSize=12,
        TextColor3=isActive and theme.text or theme.textDim,
        BackgroundColor3=isActive and theme.bgTertiary or theme.bgSecondary,
        BackgroundTransparency=isActive and 0 or 1,
        Size=UDim2.new(1,0,0,32), TextXAlignment=Enum.TextXAlignment.Left,
        LayoutOrder=order, ZIndex=13,
    })
    newInst("UICorner", btn, {CornerRadius=UDim.new(0,7)})
    newInst("UIPadding", btn, {PaddingLeft=UDim.new(0,10)})
    if isActive then
        local bar = newInst("Frame", btn, {
            Name="ActiveBar", Size=UDim2.new(0,3,0.6,0),
            Position=UDim2.new(0,-10,0.2,0),
            BackgroundColor3=theme.accent, BorderSizePixel=0, ZIndex=14,
        })
        newInst("UICorner", bar, {CornerRadius=UDim.new(1,0)})
    end
    safeConnect(btn.MouseButton1Click, function() UI.switchTab(name) end)
    safeConnect(btn.MouseEnter, function()
        if name ~= UI.activeTab then
            safeTween(btn,"BackgroundTransparency",0.7,0.15)
            safeTween(btn,"TextColor3",theme.text,0.15)
        end
    end)
    safeConnect(btn.MouseLeave, function()
        if name ~= UI.activeTab then
            safeTween(btn,"BackgroundTransparency",1,0.15)
            safeTween(btn,"TextColor3",theme.textDim,0.15)
        end
    end)
end

function UI.switchTab(tabName)
    UI.activeTab = tabName
    -- refresh sidebar
    for _, child in ipairs(UI.sidebarFrame:GetChildren()) do
        if child:IsA("TextButton") then
            local theme  = ThemeManager.get()
            local active = child.Name == "Tab_"..tabName
            safeTween(child,"BackgroundTransparency", active and 0 or 1, 0.2)
            safeTween(child,"TextColor3", active and theme.text or theme.textDim, 0.2)
            local bar = child:FindFirstChild("ActiveBar")
            if bar then bar:Destroy() end
            if active then
                local nb = newInst("Frame", child, {
                    Name="ActiveBar", Size=UDim2.new(0,3,0.6,0),
                    Position=UDim2.new(0,-10,0.2,0),
                    BackgroundColor3=theme.accent, BorderSizePixel=0, ZIndex=14,
                })
                newInst("UICorner", nb, {CornerRadius=UDim.new(1,0)})
            end
        end
    end
    -- clear content
    for _, child in ipairs(UI.contentFrame:GetChildren()) do
        if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
            child:Destroy()
        end
    end
    UI.buildTabContent(tabName)
    -- recently used
    local found = false
    for _, t in ipairs(UI.recentlyUsed) do if t==tabName then found=true; break end end
    if not found then
        table.insert(UI.recentlyUsed,1,tabName)
        if #UI.recentlyUsed>8 then table.remove(UI.recentlyUsed) end
    end
end

function UI.buildTabContent(tabName)
    local theme = ThemeManager.get()

    local function header(txt)
        local lbl = newInst("TextLabel", UI.contentFrame, {
            Text=txt, Font=Enum.Font.GothamBold, TextSize=16,
            TextColor3=theme.text, BackgroundTransparency=1,
            Size=UDim2.new(1,0,0,28), TextXAlignment=Enum.TextXAlignment.Left, ZIndex=12,
        })
        local bar = newInst("Frame", lbl, {
            Size=UDim2.new(0,3,0.7,0), Position=UDim2.new(0,-8,0.15,0),
            BackgroundColor3=theme.accent, BorderSizePixel=0,
        })
        newInst("UICorner", bar, {CornerRadius=UDim.new(1,0)})
    end

    local function secHead(txt)
        local c = newInst("Frame", UI.contentFrame, {
            BackgroundTransparency=1, Size=UDim2.new(1,0,0,22), ZIndex=12,
        })
        newInst("TextLabel", c, {
            Text=txt:upper(), Font=Enum.Font.GothamBold, TextSize=10,
            TextColor3=theme.accent, BackgroundTransparency=1,
            Size=UDim2.new(1,0,1,0), TextXAlignment=Enum.TextXAlignment.Left, ZIndex=12,
        })
    end

    local function toggle(fid, label, desc)
        local feat = FeatureManager.registry[fid]
        if not feat then return end
        local row = newInst("Frame", UI.contentFrame, {
            BackgroundColor3=theme.bgSecondary, BackgroundTransparency=0.3,
            Size=UDim2.new(1,0,0,52), BorderSizePixel=0, ZIndex=12,
        })
        newInst("UICorner", row, {CornerRadius=UDim.new(0,8)})
        newInst("UIPadding", row, {PaddingLeft=UDim.new(0,12), PaddingRight=UDim.new(0,12)})
        newInst("TextLabel", row, {
            Text=label or feat.name, Font=Enum.Font.GothamMedium, TextSize=13,
            TextColor3=theme.text, BackgroundTransparency=1,
            Size=UDim2.new(0.7,0,0,22), Position=UDim2.new(0,12,0,8),
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=13,
        })
        newInst("TextLabel", row, {
            Text=desc or feat.description, Font=Enum.Font.Gotham, TextSize=11,
            TextColor3=theme.textDim, BackgroundTransparency=1,
            Size=UDim2.new(0.7,0,0,16), Position=UDim2.new(0,12,0,28),
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=13,
        })
        local tbg = newInst("Frame", row, {
            Name="TBG", Size=UDim2.new(0,42,0,22), Position=UDim2.new(1,-54,0.5,-11),
            BackgroundColor3=feat.enabled and theme.accent or theme.border,
            BorderSizePixel=0, ZIndex=13,
        })
        newInst("UICorner", tbg, {CornerRadius=UDim.new(1,0)})
        local knob = newInst("Frame", tbg, {
            Size=UDim2.new(0,16,0,16),
            Position=feat.enabled and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8),
            BackgroundColor3=Color3.fromRGB(255,255,255), BorderSizePixel=0, ZIndex=14,
        })
        newInst("UICorner", knob, {CornerRadius=UDim.new(1,0)})
        local btn = newInst("TextButton", row, {
            Text="", BackgroundTransparency=1,
            Size=UDim2.new(0,52,0,32), Position=UDim2.new(1,-56,0.5,-16), ZIndex=15,
        })
        safeConnect(btn.MouseButton1Click, function()
            FeatureManager.toggle(fid)
            local en = FeatureManager.registry[fid].enabled
            safeTween(tbg,"BackgroundColor3", en and theme.accent or theme.border, 0.2)
            safeTween(knob,"Position", en and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8), 0.2)
        end)
    end

    local function slider(label, desc, minV, maxV, curV, step, onChange)
        local row = newInst("Frame", UI.contentFrame, {
            BackgroundColor3=theme.bgSecondary, BackgroundTransparency=0.3,
            Size=UDim2.new(1,0,0,66), BorderSizePixel=0, ZIndex=12,
        })
        newInst("UICorner", row, {CornerRadius=UDim.new(0,8)})
        newInst("UIPadding", row, {PaddingLeft=UDim.new(0,12), PaddingRight=UDim.new(0,12)})
        newInst("TextLabel", row, {
            Text=label, Font=Enum.Font.GothamMedium, TextSize=13,
            TextColor3=theme.text, BackgroundTransparency=1,
            Size=UDim2.new(0.6,0,0,22), Position=UDim2.new(0,12,0,6),
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=13,
        })
        if desc then newInst("TextLabel", row, {
            Text=desc, Font=Enum.Font.Gotham, TextSize=11,
            TextColor3=theme.textDim, BackgroundTransparency=1,
            Size=UDim2.new(0.6,0,0,14), Position=UDim2.new(0,12,0,26),
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=13,
        }) end
        local valLbl = newInst("TextLabel", row, {
            Text=tostring(curV), Font=Enum.Font.GothamBold, TextSize=13,
            TextColor3=theme.accent, BackgroundTransparency=1,
            Size=UDim2.new(0.3,0,0,22), Position=UDim2.new(0.7,0,0,6),
            TextXAlignment=Enum.TextXAlignment.Right, ZIndex=13,
        })
        local track = newInst("Frame", row, {
            Size=UDim2.new(1,-24,0,4), Position=UDim2.new(0,12,1,-16),
            BackgroundColor3=theme.border, BorderSizePixel=0, ZIndex=13,
        })
        newInst("UICorner", track, {CornerRadius=UDim.new(1,0)})
        local pct = (curV-minV)/(maxV-minV)
        local fill = newInst("Frame", track, {
            Size=UDim2.new(pct,0,1,0), BackgroundColor3=theme.accent,
            BorderSizePixel=0, ZIndex=14,
        })
        newInst("UICorner", fill, {CornerRadius=UDim.new(1,0)})
        local thumb = newInst("Frame", track, {
            Size=UDim2.new(0,12,0,12), Position=UDim2.new(pct,-6,0.5,-6),
            BackgroundColor3=Color3.fromRGB(255,255,255), BorderSizePixel=0, ZIndex=15,
        })
        newInst("UICorner", thumb, {CornerRadius=UDim.new(1,0)})
        local dragging = false
        local db = newInst("TextButton", track, {
            Text="", BackgroundTransparency=1,
            Size=UDim2.new(1,12,3,0), Position=UDim2.new(0,-6,-1,0), ZIndex=16,
        })
        safeConnect(db.MouseButton1Down, function() dragging=true end)
        if _UIS then
            safeConnect(_UIS.InputEnded, function(i)
                if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
            end)
        end
        if _RunSvc then
            safeConnect(_RunSvc.Heartbeat, function()
                if not dragging then return end
                if not _UIS then return end
                local mx = _UIS:GetMouseLocation().X
                local ap = track.AbsolutePosition.X
                local as = track.AbsoluteSize.X
                local t  = math.clamp((mx-ap)/as, 0, 1)
                local v  = minV + math.floor((t*(maxV-minV))/(step or 1)+0.5)*(step or 1)
                v = math.clamp(v,minV,maxV)
                valLbl.Text = tostring(v)
                fill.Size   = UDim2.new(t,0,1,0)
                thumb.Position = UDim2.new(t,-6,0.5,-6)
                if onChange then pcall(onChange,v) end
            end)
        end
    end

    -- ---- TAB BUILDERS ----
    if tabName == "Dashboard" then
        header("Dashboard")
        secHead("Quick Stats")
        local statsRow = newInst("Frame", UI.contentFrame, {
            BackgroundTransparency=1, Size=UDim2.new(1,0,0,80), ZIndex=12,
        })
        newInst("UIListLayout", statsRow, {
            FillDirection=Enum.FillDirection.Horizontal,
            SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,8),
        })
        local function countActive() local n=0; for _ in pairs(Core.activeFeatures) do n=n+1 end; return n end
        local cards = {
            {"Active","#"..countActive(),theme.accent},
            {"FPS",tostring(Performance.fps),theme.success},
            {"K/D",tostring(Statistics.getKD()),theme.info},
            {"Coins",tostring(Statistics.coinsCollected),theme.warning},
        }
        for i,c in ipairs(cards) do
            local card = newInst("Frame", statsRow, {
                BackgroundColor3=theme.bgSecondary, BackgroundTransparency=0.3,
                Size=UDim2.new(0.25,-6,1,0), BorderSizePixel=0, LayoutOrder=i, ZIndex=13,
            })
            newInst("UICorner", card, {CornerRadius=UDim.new(0,8)})
            newInst("TextLabel", card, {
                Text=c[2], Font=Enum.Font.GothamBold, TextSize=22,
                TextColor3=c[3], BackgroundTransparency=1,
                Size=UDim2.new(1,0,0.55,0), Position=UDim2.new(0,0,0.05,0), ZIndex=14,
            })
            newInst("TextLabel", card, {
                Text=c[1], Font=Enum.Font.Gotham, TextSize=11,
                TextColor3=theme.textDim, BackgroundTransparency=1,
                Size=UDim2.new(1,-12,0,18), Position=UDim2.new(0,8,0.62,0),
                TextXAlignment=Enum.TextXAlignment.Left, ZIndex=14,
            })
        end
        secHead("Session Info")
        local st = math.floor(os.clock()-Core.sessionStart)
        newInst("TextLabel", UI.contentFrame, {
            Text=string.format("%dm %ds  |  %s  |  %s", math.floor(st/60), st%60, Platform.executor, Platform.os),
            Font=Enum.Font.Gotham, TextSize=12, TextColor3=theme.textDim,
            BackgroundTransparency=1, Size=UDim2.new(1,0,0,24),
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=12,
        })

    elseif tabName == "ESP" then
        header("ESP")
        secHead("Players")
        toggle("esp_player","Player ESP","Highlight all players")
        toggle("esp_murderer","Murderer ESP","Highlight murderers")
        toggle("esp_sheriff","Sheriff ESP","Highlight sheriffs")
        toggle("esp_hero","Hero ESP","Highlight heroes")
        toggle("esp_innocent","Innocent ESP","Highlight innocents")
        toggle("esp_role","Role ESP","Show roles above players")
        toggle("esp_name","Name ESP","Show player names")
        toggle("esp_distance","Distance ESP","Show distance")
        toggle("esp_health","Health ESP","Show health bars")
        secHead("Visual Style")
        toggle("esp_box","Box ESP","Draw boxes around players")
        toggle("esp_corner_box","Corner Box","Corner-style boxes")
        toggle("esp_skeleton","Skeleton ESP","Draw player skeletons")
        toggle("esp_tracer","Tracer ESP","Draw tracer lines")
        toggle("esp_chams","Chams","Color players through walls")
        toggle("esp_rainbow","Rainbow ESP","Rainbow color cycling")
        secHead("Items & World")
        toggle("esp_gun","Gun ESP","Highlight guns")
        toggle("esp_knife","Knife ESP","Highlight knives")
        toggle("esp_coin","Coin ESP","Highlight coins")
        toggle("esp_item","Item ESP","Highlight all items")
        toggle("esp_drop","Dropped Items","Highlight dropped items")
        toggle("esp_dead","Dead Players","Show dead players")
        toggle("esp_offscreen","Off-Screen Arrows","Arrow indicators off-screen")
        secHead("Settings")
        slider("ESP Range","Max detection distance",50,2000,Config.get("espRange") or 500,50,function(v) Config.set("espRange",v) end)
        slider("ESP Thickness","Line thickness",1,5,1,1,function(v) Config.set("espThickness",v) end)

    elseif tabName == "Combat" then
        header("Combat")
        secHead("Aimbot")
        toggle("combat_aimbot","Aimbot","Full aimbot assistance")
        toggle("combat_silentaim","Silent Aim","Silent aim assistance")
        toggle("combat_autotarget","Auto Target","Automatically acquire targets")
        slider("Aim FOV","FOV for aim assist",10,180,Config.get("aimFOV") or 90,5,function(v) Config.set("aimFOV",v) end)
        secHead("Auto Actions")
        toggle("combat_autoshoot","Auto Shoot","Automatically shoot")
        toggle("combat_autostab","Auto Stab","Automatically stab")
        toggle("combat_autothrow","Auto Throw","Automatically throw knives")
        toggle("combat_autofling","Auto Fling","Automatically fling targets")
        secHead("Extended")
        toggle("combat_reach","Reach","Extended melee reach")
        toggle("combat_hitbox","Hitbox Expander","Expand target hitboxes")
        toggle("combat_hitbox_vis","Hitbox Visualizer","Visualize hitboxes")
        toggle("combat_damage_indicator","Damage Indicator","Show damage dealt")
        secHead("Presets")
        toggle("combat_rage_preset","Rage Preset","Maximum aggression preset")
        toggle("combat_legit_preset","Legit Preset","Subtle assistance preset")

    elseif tabName == "Movement" then
        header("Movement")
        secHead("Speed")
        toggle("move_speed","Speed Hack","Increase walk speed")
        slider("Walk Speed","Character walk speed",8,300,Config.get("walkSpeed") or 16,1,function(v) Config.set("walkSpeed",v) end)
        toggle("move_bunnyhop","Bunny Hop","Automatic bunny hop")
        secHead("Jump")
        toggle("move_infjump","Infinite Jump","Jump infinitely in air")
        toggle("move_autojump","Auto Jump","Automatically jump")
        slider("Jump Power","Character jump height",25,500,Config.get("jumpPower") or 50,5,function(v) Config.set("jumpPower",v) end)
        secHead("Flight")
        toggle("move_fly","Fly","Enable flight")
        toggle("move_noclip","Noclip","Phase through walls")
        toggle("move_airwalk","Air Walk","Walk on air")
        secHead("Utility")
        toggle("move_dash","Dash","Quick dash ability")
        toggle("move_tpwalk","TP Walk","Teleport-based movement")
        toggle("move_spin","Spin","Character spin")
        toggle("move_freecam","Freecam","Detached free camera")
        toggle("move_gravity","Gravity Control","Modify gravity")

    elseif tabName == "Farm" then
        header("Farm")
        secHead("Auto Farm")
        toggle("farm_autofarm","Auto Farm","Full auto-farm loop")
        toggle("farm_autocollect","Auto Collect","Automatically collect coins")
        toggle("farm_coin_farm","Coin Farm","Farm coins automatically")
        toggle("farm_coin_aura","Coin Aura","Collect nearby coins passively")
        secHead("Finders")
        toggle("farm_item_finder","Item Finder","Locate items on map")
        toggle("farm_gun_finder","Gun Finder","Locate guns on map")

    elseif tabName == "Intelligence" then
        header("Intelligence")
        secHead("Detectors")
        toggle("intel_role_detect","Role Detector","Detect player roles")
        toggle("intel_murderer_detect","Murderer Detector","Identify murderer")
        toggle("intel_sheriff_detect","Sheriff Detector","Identify sheriff")
        toggle("intel_round_detect","Round Detector","Detect round state")
        toggle("intel_gun_drop","Gun Drop Detector","Detect dropped guns")
        secHead("Alerts")
        toggle("intel_murderer_alert","Murderer Alert","Alert when murderer found")
        toggle("intel_gun_alert","Gun Drop Alert","Alert when gun dropped")

    elseif tabName == "Targets" then
        header("Target Manager")
        secHead("Filters")
        slider("Max Distance","Maximum target distance",10,2000,TargetManager.filters.maxDistance,10,function(v) TargetManager.filters.maxDistance=v end)

    elseif tabName == "Visual" then
        header("Visual")
        secHead("Crosshair")
        toggle("visual_crosshair","Crosshair","Custom crosshair overlay")
        secHead("Effects")
        toggle("visual_hit_effects","Hit Effects","Visual hit effects")
        toggle("visual_kill_effects","Kill Effects","Visual kill effects")
        toggle("visual_cam_shake","Camera Shake","Camera shake on hit")
        secHead("Camera")
        toggle("visual_fov_slider","FOV Slider","Adjust camera FOV")
        toggle("visual_thirdperson","Third Person","Third-person visual mode")
        toggle("visual_ui_blur","UI Blur","Blur background behind UI")

    elseif tabName == "Misc" then
        header("Misc")
        secHead("Interface")
        toggle("misc_hide_ui","Hide UI","Toggle UI visibility")
        toggle("misc_screenshot","Screenshot Mode","Hide UI for screenshots")
        toggle("misc_streamer","Streamer Mode","Streamer-safe mode")
        secHead("Monitoring")
        toggle("misc_fps_monitor","FPS Monitor","Display FPS counter")
        toggle("misc_ping_monitor","Ping Monitor","Display ping counter")
        toggle("misc_notifs","Notifications","In-game notifications")
        secHead("Developer")
        toggle("misc_debug","Debug Mode","Show debug information")
        toggle("misc_perf_mode","Performance Mode","Optimize for performance")

    elseif tabName == "Statistics" then
        header("Statistics")
        local stats = {
            {"Total Kills",Statistics.totalKills},{"Total Deaths",Statistics.totalDeaths},
            {"K/D Ratio",Statistics.getKD()},{"Coins",Statistics.coinsCollected},
            {"Rounds Played",Statistics.roundsPlayed},{"Rounds Won",Statistics.roundsWon},
            {"Rounds Lost",Statistics.roundsLost},{"Best Streak",Statistics.bestStreak},
            {"FPS",Performance.fps},
        }
        for _,s in ipairs(stats) do
            local row = newInst("Frame", UI.contentFrame, {
                BackgroundColor3=theme.bgSecondary, BackgroundTransparency=0.4,
                Size=UDim2.new(1,0,0,36), BorderSizePixel=0, ZIndex=12,
            })
            newInst("UICorner", row, {CornerRadius=UDim.new(0,8)})
            newInst("TextLabel", row, {
                Text=s[1], Font=Enum.Font.Gotham, TextSize=12,
                TextColor3=theme.textDim, BackgroundTransparency=1,
                Size=UDim2.new(0.6,0,1,0), Position=UDim2.new(0,12,0,0),
                TextXAlignment=Enum.TextXAlignment.Left, ZIndex=13,
            })
            newInst("TextLabel", row, {
                Text=tostring(s[2]), Font=Enum.Font.GothamBold, TextSize=13,
                TextColor3=theme.accent, BackgroundTransparency=1,
                Size=UDim2.new(0.35,0,1,0), Position=UDim2.new(0.62,0,0,0),
                TextXAlignment=Enum.TextXAlignment.Right, ZIndex=13,
            })
        end

    elseif tabName == "Server" then
        header("Server Info")
        ServerInfo.refresh()
        local data = {
            {"Job ID", ServerInfo.jobId~="" and ServerInfo.jobId:sub(1,12).."..." or "N/A"},
            {"Players", ServerInfo.playerCount.." / "..ServerInfo.maxPlayers},
            {"FPS", tostring(Performance.fps)},
            {"Executor", Platform.executor},
            {"Platform", Platform.os},
        }
        for _,d in ipairs(data) do
            local row = newInst("Frame", UI.contentFrame, {
                BackgroundColor3=theme.bgSecondary, BackgroundTransparency=0.4,
                Size=UDim2.new(1,0,0,36), BorderSizePixel=0, ZIndex=12,
            })
            newInst("UICorner", row, {CornerRadius=UDim.new(0,8)})
            newInst("TextLabel", row, {
                Text=d[1], Font=Enum.Font.Gotham, TextSize=12,
                TextColor3=theme.textDim, BackgroundTransparency=1,
                Size=UDim2.new(0.5,0,1,0), Position=UDim2.new(0,12,0,0),
                TextXAlignment=Enum.TextXAlignment.Left, ZIndex=13,
            })
            newInst("TextLabel", row, {
                Text=d[2], Font=Enum.Font.GothamBold, TextSize=12,
                TextColor3=theme.text, BackgroundTransparency=1,
                Size=UDim2.new(0.45,0,1,0), Position=UDim2.new(0.52,0,0,0),
                TextXAlignment=Enum.TextXAlignment.Right, ZIndex=13,
            })
        end

    elseif tabName == "Themes" then
        header("Themes")
        secHead("Select Theme")
        for tname,_ in pairs(ThemeManager.themes) do
            local active = ThemeManager.current == tname
            local btn = newInst("TextButton", UI.contentFrame, {
                Text=tname..(active and "  ✓" or ""),
                Font=Enum.Font.GothamMedium, TextSize=13,
                TextColor3=active and theme.accent or theme.text,
                BackgroundColor3=active and theme.bgTertiary or theme.bgSecondary,
                BackgroundTransparency=active and 0 or 0.4,
                Size=UDim2.new(1,0,0,40), BorderSizePixel=0, ZIndex=12,
            })
            newInst("UICorner", btn, {CornerRadius=UDim.new(0,8)})
            safeConnect(btn.MouseButton1Click, function()
                ThemeManager.set(tname); UI.switchTab("Themes")
            end)
        end

    elseif tabName == "Config" then
        header("Configuration")
        secHead("Startup")
        local function cfgToggle(key, lbl, desc)
            local row = newInst("Frame", UI.contentFrame, {
                BackgroundColor3=theme.bgSecondary, BackgroundTransparency=0.3,
                Size=UDim2.new(1,0,0,52), BorderSizePixel=0, ZIndex=12,
            })
            newInst("UICorner", row, {CornerRadius=UDim.new(0,8)})
            newInst("UIPadding", row, {PaddingLeft=UDim.new(0,12), PaddingRight=UDim.new(0,12)})
            newInst("TextLabel", row, {
                Text=lbl, Font=Enum.Font.GothamMedium, TextSize=13,
                TextColor3=theme.text, BackgroundTransparency=1,
                Size=UDim2.new(0.7,0,0,22), Position=UDim2.new(0,12,0,8),
                TextXAlignment=Enum.TextXAlignment.Left, ZIndex=13,
            })
            newInst("TextLabel", row, {
                Text=desc or "", Font=Enum.Font.Gotham, TextSize=11,
                TextColor3=theme.textDim, BackgroundTransparency=1,
                Size=UDim2.new(0.7,0,0,16), Position=UDim2.new(0,12,0,28),
                TextXAlignment=Enum.TextXAlignment.Left, ZIndex=13,
            })
            local v = Config.get(key)
            local tbg = newInst("Frame", row, {
                Size=UDim2.new(0,42,0,22), Position=UDim2.new(1,-54,0.5,-11),
                BackgroundColor3=v and theme.accent or theme.border,
                BorderSizePixel=0, ZIndex=13,
            })
            newInst("UICorner", tbg, {CornerRadius=UDim.new(1,0)})
            local knob = newInst("Frame", tbg, {
                Size=UDim2.new(0,16,0,16),
                Position=v and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8),
                BackgroundColor3=Color3.fromRGB(255,255,255), BorderSizePixel=0, ZIndex=14,
            })
            newInst("UICorner", knob, {CornerRadius=UDim.new(1,0)})
            local tb2 = newInst("TextButton", row, {
                Text="", BackgroundTransparency=1,
                Size=UDim2.new(0,52,0,32), Position=UDim2.new(1,-56,0.5,-16), ZIndex=15,
            })
            safeConnect(tb2.MouseButton1Click, function()
                local nv = not Config.get(key); Config.set(key,nv)
                safeTween(tbg,"BackgroundColor3", nv and theme.accent or theme.border, 0.2)
                safeTween(knob,"Position", nv and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8), 0.2)
            end)
        end
        cfgToggle("startupAnimation","Startup Animation","Show animated startup screen")
        cfgToggle("showLoadingDetails","Loading Details","Show step-by-step loading text")
        cfgToggle("showLogo","Show Logo","Display KURAI logo on startup")
        cfgToggle("showProgressBar","Progress Bar","Display loading progress bar")
        slider("Anim Speed","Startup animation speed",0.5,3.0,Config.get("animationSpeed") or 1.0,0.1,function(v) Config.set("animationSpeed",v) end)
        secHead("Data")
        local saveBtn = newInst("TextButton", UI.contentFrame, {
            Text="Save Configuration", Font=Enum.Font.GothamBold, TextSize=13,
            TextColor3=theme.text, BackgroundColor3=theme.accent,
            BackgroundTransparency=0.2, Size=UDim2.new(1,0,0,40),
            BorderSizePixel=0, ZIndex=12,
        })
        newInst("UICorner", saveBtn, {CornerRadius=UDim.new(0,8)})
        safeConnect(saveBtn.MouseButton1Click, function()
            Config.save(); NotificationManager.send("Config","Saved.","SUCCESS",2)
        end)
        local resetBtn = newInst("TextButton", UI.contentFrame, {
            Text="Reset to Defaults", Font=Enum.Font.GothamBold, TextSize=13,
            TextColor3=theme.danger, BackgroundColor3=theme.bgSecondary,
            BackgroundTransparency=0.3, Size=UDim2.new(1,0,0,40),
            BorderSizePixel=0, ZIndex=12,
        })
        newInst("UICorner", resetBtn, {CornerRadius=UDim.new(0,8)})
        safeConnect(resetBtn.MouseButton1Click, function()
            Config.reset(); UI.switchTab("Config")
        end)

    elseif tabName == "Performance" then
        header("Performance")
        secHead("Metrics")
        local metrics = {
            {"FPS", tostring(Performance.fps)},
            {"Memory", tostring(math.floor(gcinfo()/1024)).." MB"},
            {"Session", string.format("%dm %ds",
                math.floor((os.clock()-Core.sessionStart)/60),
                math.floor(os.clock()-Core.sessionStart)%60)},
            {"Executor", Platform.executor},
        }
        for _,m in ipairs(metrics) do
            local row = newInst("Frame", UI.contentFrame, {
                BackgroundColor3=theme.bgSecondary, BackgroundTransparency=0.4,
                Size=UDim2.new(1,0,0,36), BorderSizePixel=0, ZIndex=12,
            })
            newInst("UICorner", row, {CornerRadius=UDim.new(0,8)})
            newInst("TextLabel", row, {
                Text=m[1], Font=Enum.Font.Gotham, TextSize=12,
                TextColor3=theme.textDim, BackgroundTransparency=1,
                Size=UDim2.new(0.5,0,1,0), Position=UDim2.new(0,12,0,0),
                TextXAlignment=Enum.TextXAlignment.Left, ZIndex=13,
            })
            newInst("TextLabel", row, {
                Text=m[2], Font=Enum.Font.GothamBold, TextSize=13,
                TextColor3=theme.success, BackgroundTransparency=1,
                Size=UDim2.new(0.4,0,1,0), Position=UDim2.new(0.57,0,0,0),
                TextXAlignment=Enum.TextXAlignment.Right, ZIndex=13,
            })
        end

    elseif tabName == "Compatibility" then
        header("Compatibility")
        secHead("Detected Environment")
        newInst("TextLabel", UI.contentFrame, {
            Text="Platform: "..Platform.os.."  |  Executor: "..Platform.executor,
            Font=Enum.Font.Gotham, TextSize=12, TextColor3=theme.textDim,
            BackgroundTransparency=1, Size=UDim2.new(1,0,0,24),
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=12,
        })
        secHead("Capabilities")
        local caps = {
            {"UI System", Platform.capabilities.ui},
            {"Drawing", Platform.capabilities.drawing},
            {"Filesystem", Platform.capabilities.filesystem},
            {"Network", Platform.capabilities.network},
            {"Input", Platform.capabilities.input},
            {"Movement", true}, {"Combat", true}, {"Config", true},
        }
        for _,c in ipairs(caps) do
            local row = newInst("Frame", UI.contentFrame, {
                BackgroundColor3=theme.bgSecondary, BackgroundTransparency=0.4,
                Size=UDim2.new(1,0,0,34), BorderSizePixel=0, ZIndex=12,
            })
            newInst("UICorner", row, {CornerRadius=UDim.new(0,8)})
            newInst("TextLabel", row, {
                Text=c[1], Font=Enum.Font.Gotham, TextSize=12,
                TextColor3=theme.text, BackgroundTransparency=1,
                Size=UDim2.new(0.6,0,1,0), Position=UDim2.new(0,12,0,0),
                TextXAlignment=Enum.TextXAlignment.Left, ZIndex=13,
            })
            newInst("TextLabel", row, {
                Text=c[2] and "SUPPORTED" or "UNAVAILABLE",
                Font=Enum.Font.GothamBold, TextSize=11,
                TextColor3=c[2] and theme.success or theme.danger,
                BackgroundTransparency=1,
                Size=UDim2.new(0.35,0,1,0), Position=UDim2.new(0.62,0,0,0),
                TextXAlignment=Enum.TextXAlignment.Right, ZIndex=13,
            })
        end

    elseif tabName == "Logs" then
        header("Logs")
        local logs = Core.logs
        if #logs == 0 then
            newInst("TextLabel", UI.contentFrame, {
                Text="No log entries yet.", Font=Enum.Font.Gotham, TextSize=12,
                TextColor3=theme.textDim, BackgroundTransparency=1,
                Size=UDim2.new(1,0,0,28), TextXAlignment=Enum.TextXAlignment.Left, ZIndex=12,
            })
        else
            for i = #logs, math.max(#logs-60,0)+1, -1 do
                local e = logs[i]
                local row = newInst("Frame", UI.contentFrame, {
                    BackgroundColor3=theme.bgSecondary, BackgroundTransparency=0.5,
                    Size=UDim2.new(1,0,0,28), BorderSizePixel=0, ZIndex=12,
                })
                newInst("UICorner", row, {CornerRadius=UDim.new(0,5)})
                local col = theme.textDim
                if e.level=="ERROR" then col=theme.danger
                elseif e.level=="WARN" then col=theme.warning end
                newInst("TextLabel", row, {
                    Text=string.format("[%.1fs][%s] %s", e.timestamp, e.category, e.message),
                    Font=Enum.Font.Code, TextSize=10, TextColor3=col,
                    BackgroundTransparency=1, Size=UDim2.new(1,-16,1,0),
                    Position=UDim2.new(0,8,0,0), TextXAlignment=Enum.TextXAlignment.Left,
                    TextTruncate=Enum.TextTruncate.AtEnd, ZIndex=13,
                })
            end
        end
    end
end

function UI.show()
    if not UI.dashboardFrame then return end
    UI.dashboardFrame.Visible = true
    if UI.shadowFrame then UI.shadowFrame.Visible = true end
    UI.dashboardFrame.BackgroundTransparency = 1
    safeTween(UI.dashboardFrame,"BackgroundTransparency",0.02,0.35)
    UI.isVisible = true
end
function UI.hide()
    if not UI.dashboardFrame then return end
    safeTween(UI.dashboardFrame,"BackgroundTransparency",1,0.3)
    task.delay(0.35, function()
        if UI.dashboardFrame then UI.dashboardFrame.Visible = false end
        if UI.shadowFrame then UI.shadowFrame.Visible = false end
    end)
    UI.isVisible = false
end
function UI.toggleVisibility()
    if UI.isVisible then UI.hide() else UI.show() end
end

-- ============================================================
-- TOGGLE KEYBIND
-- ============================================================
local function setupToggleKeybind()
    if not _UIS then return end
    local conn = safeConnect(_UIS.InputBegan, function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.RightControl then UI.toggleVisibility() end
        if input.KeyCode == Enum.KeyCode.End then PanicButton.activate() end
    end)
    table.insert(Core.connections, conn)
    CleanupManager.register("ToggleKeybind", function() conn:Disconnect() end)
end

-- ============================================================
-- BOOT
-- ============================================================
local KuraiSoftware = {}

function KuraiSoftware.init()
    pcall(Platform.detect)
    pcall(Config.load)
    pcall(registerAllFeatures)
    pcall(Performance.start)

    local uiReady = false
    pcall(function() uiReady = UI.init() end)

    if not uiReady then
        Logger.log("Boot","Headless mode — no UI")
        Core.initialized = true
        return
    end

    -- skip animation?
    if not Config.get("startupAnimation") then
        pcall(UI.buildDashboard)
        UI.show()
        KeybindManager.init()
        setupToggleKeybind()
        Core.initialized = true
        Logger.log("Boot","Ready (no animation)")
        return
    end

    -- build + play startup
    local elements
    local ok, err = pcall(function() elements = UI.buildStartupScreen() end)
    if not ok then
        Logger.error("Boot","buildStartupScreen",err)
        pcall(UI.buildDashboard); UI.show()
        Core.initialized = true
        return
    end

    task.spawn(function()
        local ok2, err2 = pcall(function()
            UI.playStartupAnimation(elements, function()
                pcall(UI.buildDashboard)
                UI.show()
                KeybindManager.init()
                setupToggleKeybind()
                Core.initialized = true
                Logger.log("Boot","Kurai ready.")
                NotificationManager.send("Kurai","Ready — RightCtrl to toggle","INFO",4)
            end)
        end)
        if not ok2 then
            Logger.error("Boot","Animation",err2)
            pcall(UI.buildDashboard); UI.show()
            Core.initialized = true
        end
    end)
end

KuraiSoftware.Core             = Core
KuraiSoftware.Platform         = Platform
KuraiSoftware.Config           = Config
KuraiSoftware.Logger           = Logger
KuraiSoftware.FeatureManager   = FeatureManager
KuraiSoftware.KeybindManager   = KeybindManager
KuraiSoftware.NotificationManager = NotificationManager
KuraiSoftware.Performance      = Performance
KuraiSoftware.Statistics       = Statistics
KuraiSoftware.ThemeManager     = ThemeManager
KuraiSoftware.TargetManager    = TargetManager
KuraiSoftware.PanicButton      = PanicButton
KuraiSoftware.UI               = UI

KuraiSoftware.init()
return KuraiSoftware

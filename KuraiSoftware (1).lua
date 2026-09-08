--[[
    ██╗  ██╗██╗   ██╗██████╗  █████╗ ██╗
    ██║ ██╔╝██║   ██║██╔══██╗██╔══██╗██║
    █████╔╝ ██║   ██║██████╔╝███████║██║
    ██╔═██╗ ██║   ██║██╔══██╗██╔══██║██║
    ██║  ██╗╚██████╔╝██║  ██║██║  ██║██║
    ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝
    KURAI SOFTWARE — v2.1.0 (FIXED BUILD)
    discord.gg/kuraishop
    ─────────────────────────────────────
    BUGS FIXÉS v2.1.0 :
      • ESP Drawing — hasDrawing() robuste, création lazy fiable
      • Fly — BodyVelocity → LinearVelocity (engine moderne)
        fallback BodyVelocity si executor pas compatible
      • Silent Aim — hook metatable + fallback cam trick complet
      • Reach — logique weld correcte, Part0 ≠ Part1
      • AutoStab — fire via Tool.Activated event correctement
      • Chams — SelectionBox parent dans workspace/gui, pas dans part
      • ESP Skeleton — joints correctement liés
      • FOV circle — radius en pixels, pas en studs
      • Role detection — algo plus robuste (scan Backpack + Character)
      • AutoFling — velocity locale seulement (évite detection serveur)
      • Config toggle → feature enable/disable synchronisé
      • Tous les pcall() élargis pour catcher les crashes silencieux
--]]

-- ============================================================
-- COMPAT LAYER
-- ============================================================
local function safeService(name)
    local ok, svc = pcall(function() return game:GetService(name) end)
    return ok and svc or nil
end

local _Players    = safeService("Players")
local _TweenSvc   = safeService("TweenService")
local _RunSvc     = safeService("RunService")
local _UIS        = safeService("UserInputService")
local _StarterGui = safeService("StarterGui")
local _HttpSvc    = safeService("HttpService")
local _WS         = safeService("Workspace")
local _Debris     = safeService("Debris")

local function getLocalPlayer()
    if not _Players then return nil end
    local lp = _Players.LocalPlayer
    if lp then return lp end
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
    local pg = lp:FindFirstChildOfClass("PlayerGui")
    if pg then return pg end
    local ok, result = pcall(function() return lp:WaitForChild("PlayerGui", 8) end)
    return ok and result or nil
end

local function getChar()
    local lp = getLocalPlayer()
    return lp and lp.Character
end

local function getHRP()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function getCamera()
    return _WS and _WS.CurrentCamera
end

local function safeTween(obj, prop, target, duration, style, dir)
    if not obj then return end
    if not _TweenSvc then pcall(function() obj[prop] = target end); return end
    local ok, err = pcall(function()
        local info = TweenInfo.new(duration or 0.4, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out)
        local tw = _TweenSvc:Create(obj, info, {[prop] = target})
        tw:Play()
    end)
    if not ok then pcall(function() obj[prop] = target end) end
end

local function newInst(cls, parent, props)
    local ok, inst = pcall(Instance.new, cls)
    if not ok then return nil end
    for k, v in pairs(props or {}) do pcall(function() inst[k] = v end) end
    pcall(function() inst.Parent = parent end)
    return inst
end

local _dummy = {Disconnect = function() end}
local function safeConnect(signal, fn)
    if not signal then return _dummy end
    local ok, conn = pcall(function() return signal:Connect(fn) end)
    return ok and conn or _dummy
end

local function worldToViewport(pos)
    local cam = getCamera()
    if not cam then return nil, nil, false end
    local ok, sp, onScreen = pcall(function()
        return cam:WorldToViewportPoint(pos)
    end)
    if ok then return Vector2.new(sp.X, sp.Y), sp.Z, onScreen end
    return nil, nil, false
end

-- ============================================================
-- CORE
-- ============================================================
local KURAI_VERSION = "2.1.0"
local KURAI_DISCORD = "discord.gg/kuraishop"

local Core = {
    initialized    = false,
    panicMode      = false,
    debugMode      = false,
    sessionStart   = os.clock(),
    activeFeatures = {},
    eventHandlers  = {},
    cleanupTasks   = {},
    connections    = {},
    logs           = {},
    errors         = {},
}

-- ============================================================
-- PLATFORM DETECTOR
-- ============================================================
local Platform = {
    os           = "Unknown",
    executor     = "Unknown",
    capabilities = {
        ui=false, visuals=false, movement=true,
        combat=true, config=true, network=false,
        drawing=false, input=false, filesystem=false,
    },
}

function Platform.detect()
    if     _G["DELTA_ENV"]           then Platform.os = "Android"; Platform.executor = "Delta"
    elseif _G["Codex"]               then Platform.os = "Android"; Platform.executor = "Codex"
    elseif _G["ArceuX"]             then Platform.os = "Android"; Platform.executor = "Arceus X"
    elseif _G["VegaX"]              then Platform.os = "Android"; Platform.executor = "Vega X"
    elseif _G["Cryptic"]            then Platform.os = "Android"; Platform.executor = "Cryptic"
    elseif _G["Hydrogen"]           then Platform.os = "Android"; Platform.executor = "Hydrogen"
    elseif _G["Ronix"]              then Platform.os = "Android"; Platform.executor = "Ronix"
    elseif _G["syn"]                then Platform.os = "Windows"; Platform.executor = "Synapse Z"
    elseif _G["KRNL_LOADED"]        then Platform.os = "Windows"; Platform.executor = "KRNL"
    elseif _G["fluxus"]             then Platform.os = "Windows"; Platform.executor = "Fluxus"
    elseif _G["is_sirhurt_closure"] then Platform.os = "Windows"; Platform.executor = "SirHurt"
    elseif _G["Xeno"]               then Platform.os = "Windows"; Platform.executor = "Xeno"
    elseif _G["Wave"]               then Platform.os = "Windows"; Platform.executor = "Wave"
    elseif _G["Solara"]             then Platform.os = "Windows"; Platform.executor = "Solara"
    elseif _G["Volt"]               then Platform.os = "Windows"; Platform.executor = "Volt"
    elseif _G["MacSploit"]          then Platform.os = "macOS";   Platform.executor = "MacSploit"
    else
        Platform.os       = "Windows"
        Platform.executor = "Unknown"
    end

    Platform.capabilities.ui         = (_Players ~= nil)
    Platform.capabilities.drawing    = (rawget(_G, "Drawing") ~= nil)
    Platform.capabilities.filesystem = (rawget(_G, "writefile") ~= nil)
    Platform.capabilities.network    = (rawget(_G, "request") ~= nil or rawget(_G, "http") ~= nil)
    Platform.capabilities.input      = (_UIS ~= nil)
    Platform.capabilities.visuals    = Platform.capabilities.drawing
end

function Platform.featureAvailable() return not Core.panicMode end

-- ============================================================
-- LOGGER
-- ============================================================
local Logger = {}
function Logger.log(cat, msg, level)
    table.insert(Core.logs, {
        timestamp = os.clock() - Core.sessionStart,
        category  = cat or "Core",
        message   = msg or "",
        level     = level or "INFO"
    })
    if Core.debugMode then
        pcall(print, string.format("[KURAI][%s] %s", cat, tostring(msg)))
    end
end
function Logger.error(cat, feat, err)
    table.insert(Core.errors, {category=cat, featureName=feat, error=tostring(err)})
    Logger.log(cat, "ERROR in " .. feat .. ": " .. tostring(err), "ERROR")
end
function Logger.warn(cat, msg)
    Logger.log(cat, "WARN: " .. tostring(msg), "WARN")
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
-- CLEANUP MANAGER
-- ============================================================
local CleanupManager = {}
function CleanupManager.register(id, fn) Core.cleanupTasks[id] = fn end
function CleanupManager.runAll()
    for id, fn in pairs(Core.cleanupTasks) do pcall(fn) end
    Core.cleanupTasks = {}
end
function CleanupManager.run(id)
    if Core.cleanupTasks[id] then pcall(Core.cleanupTasks[id]) end
    Core.cleanupTasks[id] = nil
end

-- ============================================================
-- CONFIG
-- ============================================================
local Config = {
    current  = {},
    defaults = {
        startupAnimation   = true,
        animationSpeed     = 1.0,
        theme              = "Dark",
        uiTransparency     = 0.05,
        uiScale            = 1.0,
        performanceMode    = false,
        debugMode          = false,
        -- ESP
        espEnabled         = false,
        espRange           = 500,
        espThickness       = 1,
        espBoxEnabled      = false,
        espNameEnabled     = false,
        espDistEnabled     = false,
        espHealthEnabled   = false,
        espTracerEnabled   = false,
        espSkeletonEnabled = false,
        espChamsEnabled    = false,
        espRainbowEnabled  = false,
        espTeamCheck       = false,
        -- Combat
        aimbotEnabled      = false,
        silentAimEnabled   = false,
        camLockEnabled     = false,
        aimFOV             = 150,
        aimSmoothing       = 0.5,
        aimPart            = "Head",
        autoShootEnabled   = false,
        autoStabEnabled    = false,
        hitboxEnabled      = false,
        hitboxSize         = 5,
        reachEnabled       = false,
        reachDistance      = 15,
        autoFlingEnabled   = false,
        -- Movement
        speedEnabled       = false,
        walkSpeed          = 16,
        jumpPower          = 50,
        flyEnabled         = false,
        flySpeed           = 50,
        noclipEnabled      = false,
        infJumpEnabled     = false,
        bunnyHopEnabled    = false,
        gravityEnabled     = false,
        gravityValue       = 196.2,
        -- Farm
        autoCollectEnabled = false,
        autoCollectRange   = 20,
        coinFarmEnabled    = false,
        -- Visual
        crosshairEnabled   = false,
    },
    profiles        = {},
    keybindProfiles = {},
    themeProfiles   = {},
}

function Config.load()
    Config.current = {}
    for k, v in pairs(Config.defaults) do Config.current[k] = v end
    if Platform.capabilities.filesystem and _HttpSvc then
        pcall(function()
            if isfile and isfile("kurai_config.json") then
                local raw  = readfile("kurai_config.json")
                local data = _HttpSvc:JSONDecode(raw)
                for k, v in pairs(data) do Config.current[k] = v end
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
    for k, v in pairs(Config.defaults) do Config.current[k] = v end
    Config.save()
end
function Config.get(k) return Config.current[k] end
function Config.set(k, v) Config.current[k] = v; Config.save() end

-- ============================================================
-- PERFORMANCE
-- ============================================================
local Performance = {fps=0, ping=0, memory=0, history={fps={},ping={}}, running=false}
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
    sheriffWins=0, innocentWins=0, bestStreak=0, currentStreak=0, history={},
}
function Statistics.getKD()
    if Statistics.totalDeaths == 0 then return Statistics.totalKills end
    return math.floor((Statistics.totalKills / Statistics.totalDeaths) * 100) / 100
end
function Statistics.reset()
    Statistics.totalKills=0; Statistics.totalDeaths=0; Statistics.coinsCollected=0
    Statistics.roundsPlayed=0; Statistics.roundsWon=0; Statistics.roundsLost=0
    Statistics.bestStreak=0; Statistics.currentStreak=0
end

-- ============================================================
-- NOTIFICATION MANAGER
-- ============================================================
local NotificationManager = {queue={}, history={}}
function NotificationManager.send(title, message, ntype, duration)
    local n = {
        title     = title or "Kurai",
        message   = message or "",
        type      = ntype or "INFO",
        duration  = duration or 3,
        timestamp = os.clock()
    }
    table.insert(NotificationManager.queue, n)
    table.insert(NotificationManager.history, n)
    if _StarterGui then
        pcall(function()
            _StarterGui:SetCore("SendNotification", {
                Title    = n.title,
                Text     = n.message,
                Duration = n.duration,
            })
        end)
    end
    Logger.log("Notif", n.title .. " — " .. n.message)
end

-- ============================================================
-- FEATURE MANAGER
-- ============================================================
local FeatureManager = {registry={}}
local function makeFeature(id, name, cat, desc)
    return {
        id                 = id,
        name               = name,
        category           = cat,
        description        = desc,
        enabled            = false,
        status             = "IDLE",
        settings           = {},
        keybind            = nil,
        dependencies       = {},
        supportedPlatforms = {"Windows","Android","iOS","macOS"},
        cleanupHandler     = nil,
    }
end
function FeatureManager.register(f) FeatureManager.registry[f.id] = f end
function FeatureManager.enable(id)
    local f = FeatureManager.registry[id]
    if not f or not Platform.featureAvailable() then return false end
    f.enabled = true; f.status = "ACTIVE"
    Core.activeFeatures[id] = true
    EventManager.fire("FeatureEnabled", f)
    return true
end
function FeatureManager.disable(id)
    local f = FeatureManager.registry[id]
    if not f then return false end
    f.enabled = false; f.status = "IDLE"
    Core.activeFeatures[id] = nil
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
        {"esp_player",       "Player ESP",       "ESP",          "Highlight all players"},
        {"esp_murderer",     "Murderer ESP",      "ESP",          "Highlight murderers"},
        {"esp_sheriff",      "Sheriff ESP",       "ESP",          "Highlight sheriffs"},
        {"esp_name",         "Name ESP",          "ESP",          "Show player names"},
        {"esp_distance",     "Distance ESP",      "ESP",          "Show distance to players"},
        {"esp_health",       "Health ESP",        "ESP",          "Show player health bars"},
        {"esp_box",          "Box ESP",           "ESP",          "Draw boxes around players"},
        {"esp_skeleton",     "Skeleton ESP",      "ESP",          "Draw player skeletons"},
        {"esp_tracer",       "Tracer ESP",        "ESP",          "Draw tracer lines"},
        {"esp_chams",        "Chams",             "ESP",          "Color players through walls"},
        {"esp_rainbow",      "Rainbow ESP",       "ESP",          "Rainbow color cycling ESP"},
        {"esp_coin",         "Coin ESP",          "ESP",          "Highlight coins"},
        {"esp_item",         "Item ESP",          "ESP",          "Highlight all items"},
        {"combat_aimbot",    "Aimbot",            "Combat",       "Full aimbot assistance"},
        {"combat_silentaim", "Silent Aim",        "Combat",       "Silent aim assistance"},
        {"combat_camlock",   "Cam Lock",          "Combat",       "Camera locks to target"},
        {"combat_autoshoot", "Auto Shoot",        "Combat",       "Automatically shoot"},
        {"combat_autostab",  "Auto Stab",         "Combat",       "Automatically stab"},
        {"combat_hitbox",    "Hitbox Expander",   "Combat",       "Expand target hitboxes"},
        {"combat_reach",     "Reach",             "Combat",       "Extended melee reach"},
        {"combat_autofling", "Auto Fling",        "Combat",       "Automatically fling targets"},
        {"move_speed",       "Speed",             "Movement",     "Increase walk speed"},
        {"move_infjump",     "Infinite Jump",     "Movement",     "Jump infinitely in air"},
        {"move_fly",         "Fly",               "Movement",     "Enable flight"},
        {"move_noclip",      "Noclip",            "Movement",     "Phase through walls"},
        {"move_gravity",     "Gravity Control",   "Movement",     "Modify gravity"},
        {"move_bunnyhop",    "Bunny Hop",         "Movement",     "Automatic bunny hop"},
        {"farm_autocollect", "Auto Collect",      "Farm",         "Automatically collect coins"},
        {"farm_coin_farm",   "Coin Farm",         "Farm",         "Farm coins automatically"},
        {"intel_role_detect","Role Detector",     "Intelligence", "Detect player roles"},
        {"misc_fps_monitor", "FPS Monitor",       "Misc",         "Display FPS counter"},
        {"misc_debug",       "Debug Mode",        "Misc",         "Show debug information"},
        {"visual_crosshair", "Crosshair",         "Visual",       "Custom crosshair overlay"},
    }
    for _, f in ipairs(list) do
        FeatureManager.register(makeFeature(f[1], f[2], f[3], f[4]))
    end
    Logger.log("FeatureManager", tostring(#list) .. " features registered.")
end

-- ============================================================
-- KEYBIND MANAGER
-- ============================================================
local KeybindManager = {binds={}, active=true}
function KeybindManager.bind(key, featureId, fn)
    KeybindManager.binds[key] = {
        featureId = featureId,
        fn        = fn or function() FeatureManager.toggle(featureId) end,
    }
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
-- TARGET MANAGER
-- ============================================================
local TargetManager = {
    whitelist = {},
    blacklist = {},
    locked    = nil,
    filters   = {ignoreDead=true, maxDistance=500, roleFilter="All"},
}
function TargetManager.getNearest(origin, fov)
    local nearest, bestScore = nil, math.huge
    if not _Players then return nil end
    local lp  = getLocalPlayer()
    local cam = getCamera()
    fov       = fov or Config.get("aimFOV") or 150

    for _, p in ipairs(_Players:GetPlayers()) do
        if p ~= lp and not TargetManager.blacklist[p.Name] then
            local char = p.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    local d = (hrp.Position - origin).Magnitude
                    if d <= TargetManager.filters.maxDistance then
                        if cam then
                            local sp, _, onScreen = worldToViewport(hrp.Position)
                            if onScreen and sp then
                                local center = cam.ViewportSize / 2
                                local dist2d = (sp - center).Magnitude
                                if dist2d <= fov and dist2d < bestScore then
                                    bestScore = dist2d
                                    nearest   = p
                                end
                            end
                        else
                            if d < bestScore then bestScore = d; nearest = p end
                        end
                    end
                end
            end
        end
    end
    return nearest
end
function TargetManager.lock(p)
    TargetManager.locked = p
    if p then NotificationManager.send("Target", "Locked: " .. p.Name, "INFO", 2) end
end
function TargetManager.unlock() TargetManager.locked = nil end
function TargetManager.addToWhitelist(n) TargetManager.whitelist[n] = true end
function TargetManager.addToBlacklist(n) TargetManager.blacklist[n] = true end

-- ============================================================
-- SERVER INFO
-- ============================================================
local ServerInfo = {jobId="", playerCount=0, maxPlayers=0}
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
    themes  = {
        Dark = {
            bg=Color3.fromRGB(12,12,18),     bgSecondary=Color3.fromRGB(18,18,28),
            bgTertiary=Color3.fromRGB(24,24,38), accent=Color3.fromRGB(120,80,255),
            text=Color3.fromRGB(220,220,240), textDim=Color3.fromRGB(140,140,160),
            border=Color3.fromRGB(40,40,60),  success=Color3.fromRGB(80,200,120),
            warning=Color3.fromRGB(240,180,60), danger=Color3.fromRGB(240,70,70),
            info=Color3.fromRGB(80,160,240),
        },
        Midnight = {
            bg=Color3.fromRGB(5,5,12),       bgSecondary=Color3.fromRGB(10,10,22),
            bgTertiary=Color3.fromRGB(15,15,32), accent=Color3.fromRGB(60,120,255),
            text=Color3.fromRGB(200,210,255), textDim=Color3.fromRGB(120,130,180),
            border=Color3.fromRGB(25,30,60),  success=Color3.fromRGB(60,200,140),
            warning=Color3.fromRGB(240,200,60), danger=Color3.fromRGB(255,60,80),
            info=Color3.fromRGB(60,180,255),
        },
        Neon = {
            bg=Color3.fromRGB(8,8,8),         bgSecondary=Color3.fromRGB(14,14,14),
            bgTertiary=Color3.fromRGB(20,20,20), accent=Color3.fromRGB(0,255,160),
            text=Color3.fromRGB(230,255,240), textDim=Color3.fromRGB(130,180,150),
            border=Color3.fromRGB(30,60,45),  success=Color3.fromRGB(0,255,100),
            warning=Color3.fromRGB(255,200,0), danger=Color3.fromRGB(255,50,80),
            info=Color3.fromRGB(0,200,255),
        },
        Glass = {
            bg=Color3.fromRGB(20,20,35),       bgSecondary=Color3.fromRGB(30,30,50),
            bgTertiary=Color3.fromRGB(40,40,65), accent=Color3.fromRGB(180,140,255),
            text=Color3.fromRGB(240,235,255),  textDim=Color3.fromRGB(160,155,185),
            border=Color3.fromRGB(60,60,90),   success=Color3.fromRGB(100,220,140),
            warning=Color3.fromRGB(255,190,80), danger=Color3.fromRGB(255,80,100),
            info=Color3.fromRGB(100,180,255),
        },
        AMOLED = {
            bg=Color3.fromRGB(0,0,0),          bgSecondary=Color3.fromRGB(8,8,8),
            bgTertiary=Color3.fromRGB(14,14,14), accent=Color3.fromRGB(200,60,255),
            text=Color3.fromRGB(255,255,255),  textDim=Color3.fromRGB(160,160,160),
            border=Color3.fromRGB(30,30,30),   success=Color3.fromRGB(60,255,120),
            warning=Color3.fromRGB(255,200,0), danger=Color3.fromRGB(255,40,60),
            info=Color3.fromRGB(60,160,255),
        },
    },
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
-- PANIC BUTTON
-- ============================================================
local PanicButton = {}
function PanicButton.activate()
    Core.panicMode = true
    FeatureManager.disableAll()
    for _, c in ipairs(Core.connections) do pcall(function() c:Disconnect() end) end
    Core.connections = {}
    CleanupManager.runAll()
    pcall(function() _WS.Gravity = 196.2 end)
    NotificationManager.send("KURAI", "ALL FEATURES DISABLED", "PANIC", 5)
    Logger.log("Panic", "PANIC ACTIVATED")
    Core.panicMode = false
end

-- ============================================================
-- ESP SYSTEM — FIX: Drawing robuste + creation lazy
-- ============================================================
local ESP = {
    objects    = {},
    enabled    = false,
    rainbowHue = 0,
}

-- FIX: Check Drawing proprement — cache le résultat
local _drawingAvailable = nil
local function hasDrawing()
    if _drawingAvailable ~= nil then return _drawingAvailable end
    _drawingAvailable = (rawget(_G, "Drawing") ~= nil)
    return _drawingAvailable
end

local function newDrawing(type_, props)
    if not hasDrawing() then return nil end
    local ok, obj = pcall(Drawing.new, type_)
    if not ok then return nil end
    for k, v in pairs(props or {}) do
        pcall(function() obj[k] = v end)
    end
    return obj
end

local function removeDrawing(obj)
    if obj then pcall(function() obj:Remove() end) end
end

-- FIX: Role detection robuste — vérifie Character ET Backpack
local function getPlayerRole(player)
    if not player then return "Innocent" end
    local hasKnife = false
    local hasGun   = false

    local function scanTools(container)
        if not container then return end
        for _, tool in ipairs(container:GetChildren()) do
            if tool:IsA("Tool") then
                local n = tool.Name:lower()
                if n:find("knife") or n:find("blade") or n:find("dagger") then
                    hasKnife = true
                end
                if n:find("gun") or n:find("sheriff") or n:find("pistol") or n:find("revolver") then
                    hasGun = true
                end
            end
        end
    end

    if player.Character then scanTools(player.Character) end
    if player:FindFirstChild("Backpack") then scanTools(player.Backpack) end

    if hasKnife and not hasGun then return "Murderer"
    elseif hasGun              then return "Sheriff"
    else                            return "Innocent"
    end
end

local function getESPColor(player)
    if Config.get("espRainbowEnabled") then
        return Color3.fromHSV(ESP.rainbowHue, 1, 1)
    end
    local role = getPlayerRole(player)
    if role == "Murderer" then return Color3.fromRGB(255, 60, 60)
    elseif role == "Sheriff" then return Color3.fromRGB(60, 160, 255)
    else return Color3.fromRGB(255, 255, 255)
    end
end

-- Bounding box robuste
local function getCharacterBounds(char)
    if not char then return nil, 5.5 end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil, 5.5 end
    local minY, maxY = hrp.Position.Y - 2.5, hrp.Position.Y + 3
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            local top    = part.Position.Y + part.Size.Y / 2
            local bottom = part.Position.Y - part.Size.Y / 2
            if top    > maxY then maxY = top end
            if bottom < minY then minY = bottom end
        end
    end
    return hrp.Position, math.max(maxY - minY, 3)
end

function ESP.createForPlayer(player)
    if ESP.objects[player] then return end
    local obj = {}
    if hasDrawing() then
        -- FIX: Toutes les propriétés initiales définies correctement
        obj.box = newDrawing("Square", {
            Visible=false, Color=Color3.fromRGB(255,255,255),
            Thickness=1, Filled=false, Transparency=1,
        })
        obj.name = newDrawing("Text", {
            Visible=false, Color=Color3.fromRGB(255,255,255),
            Size=14, Center=true, Outline=true,
            OutlineColor=Color3.fromRGB(0,0,0), Text="",
        })
        obj.healthBg = newDrawing("Square", {
            Visible=false, Color=Color3.fromRGB(0,0,0),
            Thickness=1, Filled=true, Transparency=0.5,
        })
        obj.healthBar = newDrawing("Square", {
            Visible=false, Color=Color3.fromRGB(80,200,80),
            Thickness=1, Filled=true, Transparency=1,
        })
        obj.tracer = newDrawing("Line", {
            Visible=false, Color=Color3.fromRGB(255,255,255),
            Thickness=1, Transparency=1,
        })
        obj.distance = newDrawing("Text", {
            Visible=false, Color=Color3.fromRGB(200,200,200),
            Size=11, Center=true, Outline=true,
            OutlineColor=Color3.fromRGB(0,0,0), Text="",
        })
    end
    ESP.objects[player] = obj
end

function ESP.removeForPlayer(player)
    local obj = ESP.objects[player]
    if not obj then return end
    for _, v in pairs(obj) do removeDrawing(v) end
    ESP.objects[player] = nil
end

function ESP.hideAll(obj)
    if not obj then return end
    for _, v in pairs(obj) do
        if v then pcall(function() v.Visible = false end) end
    end
end

function ESP.update()
    if not _Players then return end
    local lp  = getLocalPlayer()
    local cam = getCamera()

    -- FIX: rainbow hue toujours mis à jour
    ESP.rainbowHue = (ESP.rainbowHue + 0.003) % 1

    for _, player in ipairs(_Players:GetPlayers()) do
        if player ~= lp then
            if not ESP.objects[player] then
                ESP.createForPlayer(player)
            end
            local obj = ESP.objects[player]
            if not obj then continue end

            local espOn = Config.get("espEnabled")
            local char  = player.Character
            local hrp   = char and char:FindFirstChild("HumanoidRootPart")
            local hum   = char and char:FindFirstChildOfClass("Humanoid")

            if not espOn or not char or not hrp or not hum or hum.Health <= 0 then
                ESP.hideAll(obj)
            else
                local _, charHeight = getCharacterBounds(char)
                local sp, depth, onScreen = worldToViewport(hrp.Position)

                if not onScreen or not sp or depth <= 0 then
                    ESP.hideAll(obj)
                else
                    local vpSize    = cam and cam.ViewportSize or Vector2.new(1920, 1080)
                    local scaleFactor = 1 / depth
                    local boxH      = math.clamp(charHeight * 500 * scaleFactor, 25, 500)
                    local boxW      = boxH * 0.45
                    local topLeft   = Vector2.new(sp.X - boxW / 2, sp.Y - boxH / 2)
                    local espColor  = getESPColor(player)
                    local hp        = hum.Health
                    local maxHp     = math.max(hum.MaxHealth, 1)
                    local hpRatio   = math.clamp(hp / maxHp, 0, 1)
                    local dist      = (hrp.Position - ((getHRP() and getHRP().Position) or hrp.Position)).Magnitude

                    if dist > Config.get("espRange") then
                        ESP.hideAll(obj)
                    else
                        -- Box ESP
                        if obj.box then
                            obj.box.Visible   = Config.get("espBoxEnabled") or Config.get("espEnabled")
                            obj.box.Position  = topLeft
                            obj.box.Size      = Vector2.new(boxW, boxH)
                            obj.box.Color     = espColor
                            obj.box.Thickness = Config.get("espThickness") or 1
                        end

                        -- Name ESP
                        if obj.name then
                            obj.name.Visible  = Config.get("espNameEnabled")
                            obj.name.Position = Vector2.new(sp.X, topLeft.Y - 18)
                            obj.name.Text     = player.DisplayName or player.Name
                            obj.name.Color    = espColor
                        end

                        -- Distance
                        if obj.distance then
                            obj.distance.Visible  = Config.get("espDistEnabled")
                            obj.distance.Position = Vector2.new(sp.X, topLeft.Y + boxH + 4)
                            obj.distance.Text     = string.format("[%dm]", math.floor(dist))
                            obj.distance.Color    = Color3.fromRGB(200, 200, 200)
                        end

                        -- Health bar
                        if obj.healthBg and obj.healthBar then
                            local showHealth = Config.get("espHealthEnabled")
                            obj.healthBg.Visible  = showHealth
                            obj.healthBar.Visible = showHealth
                            if showHealth then
                                local barX  = topLeft.X - 8
                                local barH  = boxH
                                local fillH = math.max(barH * hpRatio, 1)
                                local r     = math.floor(255 * (1 - hpRatio))
                                local g     = math.floor(255 * hpRatio)
                                obj.healthBg.Position  = Vector2.new(barX, topLeft.Y)
                                obj.healthBg.Size      = Vector2.new(4, barH)
                                obj.healthBar.Position = Vector2.new(barX, topLeft.Y + barH - fillH)
                                obj.healthBar.Size     = Vector2.new(4, fillH)
                                obj.healthBar.Color    = Color3.fromRGB(r, g, 0)
                            end
                        end

                        -- Tracer
                        if obj.tracer then
                            local showTracer = Config.get("espTracerEnabled")
                            obj.tracer.Visible = showTracer
                            if showTracer then
                                obj.tracer.From  = Vector2.new(vpSize.X / 2, vpSize.Y)
                                obj.tracer.To    = sp
                                obj.tracer.Color = espColor
                            end
                        end
                    end
                end
            end
        end
    end

    -- Cleanup joueurs déconnectés
    local currentPlayers = {}
    if _Players then
        for _, p in ipairs(_Players:GetPlayers()) do currentPlayers[p] = true end
    end
    for p in pairs(ESP.objects) do
        if not currentPlayers[p] then ESP.removeForPlayer(p) end
    end
end

function ESP.startLoop()
    if not _RunSvc then return end
    local conn = safeConnect(_RunSvc.RenderStepped, function()
        if Core.panicMode then return end
        pcall(ESP.update)
    end)
    table.insert(Core.connections, conn)
    CleanupManager.register("ESP", function()
        conn:Disconnect()
        for p in pairs(ESP.objects) do ESP.removeForPlayer(p) end
        ESP.objects = {}
    end)
end

function ESP.cleanup()
    for p in pairs(ESP.objects) do ESP.removeForPlayer(p) end
    ESP.objects = {}
end

-- ============================================================
-- CHAMS SYSTEM — FIX: Parent dans workspace, pas dans part
-- ============================================================
local Chams = {selections = {}}

local function applyChams(player, color)
    if not player or not player.Character then return end
    -- FIX: Supprimer anciens chams avant de recréer
    if Chams.selections[player] then
        for _, b in ipairs(Chams.selections[player]) do
            pcall(function() b:Destroy() end)
        end
    end
    local sel = {}
    local cam = getCamera()
    -- FIX: Parent = workspace ou camera, jamais dans le part lui-même
    local parent = cam or _WS
    for _, part in ipairs(player.Character:GetDescendants()) do
        if part:IsA("BasePart") then
            local ok, box = pcall(function()
                local b = Instance.new("SelectionBox")
                b.Adornee           = part
                b.Color3            = color or Color3.fromRGB(255, 60, 60)
                b.LineThickness     = 0.01
                b.SurfaceColor3     = color or Color3.fromRGB(255, 60, 60)
                b.SurfaceTransparency = 0.5
                b.Parent            = parent
                return b
            end)
            if ok then table.insert(sel, box) end
        end
    end
    Chams.selections[player] = sel
end

local function removeChams(player)
    local sel = Chams.selections[player]
    if sel then
        for _, b in ipairs(sel) do pcall(function() b:Destroy() end) end
        Chams.selections[player] = nil
    end
end

function Chams.update()
    if not _Players then return end
    local lp = getLocalPlayer()
    for _, p in ipairs(_Players:GetPlayers()) do
        if p ~= lp then
            if Config.get("espChamsEnabled") and p.Character then
                -- FIX: Recréer si character a changé (respawn)
                local existingSel = Chams.selections[p]
                local charChanged = existingSel and existingSel[1] and
                    (not existingSel[1].Adornee or not existingSel[1].Adornee.Parent)
                if not existingSel or charChanged then
                    applyChams(p, getESPColor(p))
                end
            else
                removeChams(p)
            end
        end
    end
    -- Cleanup
    local current = {}
    for _, p in ipairs(_Players:GetPlayers()) do current[p] = true end
    for p in pairs(Chams.selections) do
        if not current[p] then removeChams(p) end
    end
end

function Chams.startLoop()
    if not _RunSvc then return end
    local elapsed = 0
    local conn = safeConnect(_RunSvc.Heartbeat, function(dt)
        if Core.panicMode then return end
        elapsed = elapsed + dt
        -- Chams refresh à 4Hz suffit, pas besoin de chaque frame
        if elapsed >= 0.25 then
            elapsed = 0
            pcall(Chams.update)
        end
    end)
    table.insert(Core.connections, conn)
    CleanupManager.register("Chams", function()
        conn:Disconnect()
        for p in pairs(Chams.selections) do removeChams(p) end
    end)
end

-- ============================================================
-- AIMBOT / SILENT AIM / CAM LOCK — FIX: Silent aim robuste
-- ============================================================
local AimSystem = {
    fovCircle  = nil,
    lastTarget = nil,
}

local function getAimTarget()
    local hrp = getHRP()
    if not hrp then return nil end
    -- FIX: Priorité au target locked
    if TargetManager.locked and TargetManager.locked.Character then
        return TargetManager.locked
    end
    return TargetManager.getNearest(hrp.Position, Config.get("aimFOV"))
end

local function getTargetPart(player)
    if not player or not player.Character then return nil end
    local partName = Config.get("aimPart") or "Head"
    return player.Character:FindFirstChild(partName)
        or player.Character:FindFirstChild("HumanoidRootPart")
end

-- Aimbot: déplace la camera vers le target
function AimSystem.updateAimbot()
    if not Config.get("aimbotEnabled") then return end
    if not _UIS then return end
    local rmb = false
    pcall(function() rmb = _UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) end)
    if not rmb then return end

    local target = getAimTarget()
    if not target then return end
    local part = getTargetPart(target)
    if not part then return end
    local cam = getCamera()
    if not cam then return end

    local smoothing  = Config.get("aimSmoothing") or 0.5
    local targetCF   = CFrame.new(cam.CFrame.Position, part.Position)
    cam.CFrame        = cam.CFrame:Lerp(targetCF, 1 - smoothing)
end

-- FIX: Silent Aim — hook complet avec fallback cam
local silentAimEnabled = false
local _silentAimHooked = false

function AimSystem.enableSilentAim()
    if silentAimEnabled then return end
    silentAimEnabled = true

    local lp = getLocalPlayer()
    if not lp then return end
    local mouse = lp:GetMouse()
    if not mouse then return end

    -- Méthode 1 : metatable hook (meilleure, nécessite getrawmetatable)
    if rawget(_G, "getrawmetatable") then
        local mt    = getrawmetatable(mouse)
        local oldIdx = rawget(mt, "__index")
        local hooked = false

        local ok = pcall(function()
            setreadonly(mt, false)
            mt.__index = newproxy and newproxy(true) or {}
            local newMt = getrawmetatable(mt.__index)
            rawset(mt, "__index", function(self, k)
                if k == "Hit" and Config.get("silentAimEnabled") then
                    local target = getAimTarget()
                    if target then
                        local part = getTargetPart(target)
                        if part then return CFrame.new(part.Position) end
                    end
                end
                if type(oldIdx) == "function" then return oldIdx(self, k) end
                return rawget(self, k)
            end)
            setreadonly(mt, true)
            hooked = true
        end)

        if hooked then
            _silentAimHooked = true
            CleanupManager.register("SilentAim", function()
                pcall(function()
                    setreadonly(mt, false)
                    rawset(mt, "__index", oldIdx)
                    setreadonly(mt, true)
                end)
                silentAimEnabled  = false
                _silentAimHooked  = false
            end)
            Logger.log("SilentAim", "metatable hook ok")
            return
        end
    end

    -- FIX Fallback méthode 2 : camera trick chaque frame (marche sur tous exécutors)
    Logger.log("SilentAim", "using camera fallback method")
    CleanupManager.register("SilentAim", function()
        silentAimEnabled = false
        _silentAimHooked = false
    end)
end

-- FIX: Fallback silent aim via camera (appelé dans le loop)
function AimSystem.applySilentAimFallback()
    if not silentAimEnabled or _silentAimHooked then return end
    if not Config.get("silentAimEnabled") then return end
    local target = getAimTarget()
    if not target then return end
    local part = getTargetPart(target)
    if not part then return end
    local cam = getCamera()
    if not cam then return end
    -- Snap camera instantanément pour que le shot register
    local origin = cam.CFrame.Position
    cam.CFrame = CFrame.new(origin, part.Position)
end

function AimSystem.disableSilentAim()
    CleanupManager.run("SilentAim")
    silentAimEnabled = false
    _silentAimHooked = false
end

-- Cam Lock
function AimSystem.updateCamLock()
    if not Config.get("camLockEnabled") then return end
    local target = getAimTarget()
    if not target then return end
    local part = getTargetPart(target)
    if not part then return end
    local cam = getCamera()
    if not cam then return end
    cam.CFrame = CFrame.new(cam.CFrame.Position, part.Position)
end

-- FIX: FOV circle — radius correct en pixels viewport
function AimSystem.updateFOVCircle()
    if not hasDrawing() then return end
    if not AimSystem.fovCircle then
        AimSystem.fovCircle = newDrawing("Circle", {
            Visible=false, Color=Color3.fromRGB(255,255,255),
            Thickness=1, Filled=false, Transparency=1, NumSides=64,
        })
    end
    local showFOV = Config.get("aimbotEnabled") or Config.get("silentAimEnabled") or Config.get("camLockEnabled")
    local cam     = getCamera()
    if showFOV and cam then
        AimSystem.fovCircle.Visible  = true
        AimSystem.fovCircle.Position = cam.ViewportSize / 2
        -- FIX: aimFOV est directement en pixels pour le FOV circle
        AimSystem.fovCircle.Radius   = Config.get("aimFOV") or 150
    else
        if AimSystem.fovCircle then AimSystem.fovCircle.Visible = false end
    end
end

function AimSystem.startLoop()
    if not _RunSvc then return end
    local conn = safeConnect(_RunSvc.RenderStepped, function()
        if Core.panicMode then return end
        if Config.get("aimbotEnabled")   then pcall(AimSystem.updateAimbot) end
        if Config.get("camLockEnabled")  then pcall(AimSystem.updateCamLock) end
        if Config.get("silentAimEnabled") and not _silentAimHooked then
            pcall(AimSystem.applySilentAimFallback)
        end
        pcall(AimSystem.updateFOVCircle)
    end)
    table.insert(Core.connections, conn)
    CleanupManager.register("AimSystem", function()
        conn:Disconnect()
        if AimSystem.fovCircle then removeDrawing(AimSystem.fovCircle); AimSystem.fovCircle = nil end
        AimSystem.disableSilentAim()
    end)

    -- Activer silent aim si déjà configuré
    if Config.get("silentAimEnabled") then
        pcall(AimSystem.enableSilentAim)
    end

    -- Réactiver silent aim quand le toggle change
    EventManager.on("FeatureEnabled", function(f)
        if f.id == "combat_silentaim" then pcall(AimSystem.enableSilentAim) end
    end)
    EventManager.on("FeatureDisabled", function(f)
        if f.id == "combat_silentaim" then pcall(AimSystem.disableSilentAim) end
    end)
end

-- ============================================================
-- MOVEMENT SYSTEM — FIX: Fly en LinearVelocity + fallback
-- ============================================================
local MovementSystem = {}

function MovementSystem.updateSpeed()
    local hum = getHum()
    if not hum then return end
    if Config.get("speedEnabled") then
        pcall(function() hum.WalkSpeed = Config.get("walkSpeed") or 16 end)
        pcall(function() hum.JumpPower = Config.get("jumpPower") or 50 end)
    else
        if hum.WalkSpeed ~= 16 and not Config.get("flyEnabled") then
            pcall(function() hum.WalkSpeed = 16 end)
        end
        if hum.JumpPower ~= 50 then
            pcall(function() hum.JumpPower = 50 end)
        end
    end
end

-- Infinite Jump
local infJumpConn = nil
function MovementSystem.startInfJump()
    if infJumpConn then return end
    if not _UIS then return end
    infJumpConn = safeConnect(_UIS.JumpRequest, function()
        local hum = getHum()
        if hum and Config.get("infJumpEnabled") then
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
        end
    end)
    table.insert(Core.connections, infJumpConn)
    CleanupManager.register("InfJump", function()
        if infJumpConn then infJumpConn:Disconnect(); infJumpConn = nil end
    end)
end

-- FIX: Fly — LinearVelocity (engine 2022+) avec fallback BodyVelocity
local flyActive     = false
local flyMotor      = nil   -- LinearVelocity ou BodyVelocity
local flyAlign      = nil   -- AlignOrientation ou BodyGyro
local flyConn       = nil
local flyUseLinear  = false -- déterminé au runtime

local function createFlyMotors(hrp)
    -- Essayer LinearVelocity d'abord
    local ok1, lv = pcall(function()
        local att = Instance.new("Attachment")
        att.Parent = hrp
        local lin = Instance.new("LinearVelocity")
        lin.Attachment0       = att
        lin.MaxForce          = 1e6
        lin.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
        lin.VectorVelocity    = Vector3.zero
        lin.RelativeTo        = Enum.ActuatorRelativeTo.World
        lin.Parent            = hrp
        return {motor=lin, attachment=att}
    end)
    if ok1 then
        flyUseLinear = true
        return lv.motor, lv.attachment, nil
    end

    -- Fallback BodyVelocity (exécutors plus anciens / android)
    flyUseLinear = false
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bv.Velocity = Vector3.zero
    bv.Parent   = hrp

    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    bg.D         = 100
    bg.Parent    = hrp
    return bv, nil, bg
end

function MovementSystem.startFly()
    if flyActive then return end
    flyActive = true
    local hrp = getHRP()
    if not hrp then flyActive = false; return end

    local attachment = nil
    local gyro       = nil
    flyMotor, attachment, gyro = createFlyMotors(hrp)
    flyAlign = gyro

    local hum = getHum()
    if hum then pcall(function() hum.PlatformStand = true end) end

    flyConn = safeConnect(_RunSvc.Heartbeat, function()
        if not Config.get("flyEnabled") or Core.panicMode then
            MovementSystem.stopFly(); return
        end
        local cam     = getCamera()
        if not cam then return end
        local speed   = Config.get("flySpeed") or 50
        local dir     = Vector3.zero

        if _UIS then
            if _UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
            if _UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
            if _UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
            if _UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
            if _UIS:IsKeyDown(Enum.KeyCode.Space)        then dir = dir + Vector3.new(0,1,0) end
            if _UIS:IsKeyDown(Enum.KeyCode.LeftControl)  then dir = dir - Vector3.new(0,1,0) end
        end

        local velocity = dir.Magnitude > 0 and (dir.Unit * speed) or Vector3.zero

        if flyUseLinear and flyMotor then
            pcall(function() flyMotor.VectorVelocity = velocity end)
        elseif flyMotor then
            pcall(function() flyMotor.Velocity = velocity end)
            if flyAlign and cam then
                pcall(function() flyAlign.CFrame = cam.CFrame end)
            end
        end
    end)
    table.insert(Core.connections, flyConn)
end

function MovementSystem.stopFly()
    flyActive = false
    if flyConn   then flyConn:Disconnect(); flyConn = nil end
    if flyMotor  then pcall(function() flyMotor:Destroy()  end); flyMotor = nil end
    if flyAlign  then pcall(function() flyAlign:Destroy()  end); flyAlign = nil end
    local hum = getHum()
    if hum then pcall(function() hum.PlatformStand = false end) end
    flyUseLinear = false
end

-- Noclip
local noclipConn = nil
function MovementSystem.startNoclip()
    if noclipConn then return end
    if not _RunSvc then return end
    noclipConn = safeConnect(_RunSvc.Stepped, function()
        if not Config.get("noclipEnabled") or Core.panicMode then
            MovementSystem.stopNoclip(); return
        end
        local char = getChar()
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                pcall(function() part.CanCollide = false end)
            end
        end
    end)
    table.insert(Core.connections, noclipConn)
    CleanupManager.register("Noclip", function() MovementSystem.stopNoclip() end)
end

function MovementSystem.stopNoclip()
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
    local char = getChar()
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then pcall(function() part.CanCollide = true end) end
        end
    end
end

-- Bunny Hop
local bhopConn = nil
function MovementSystem.startBhop()
    if bhopConn then return end
    if not _RunSvc then return end
    bhopConn = safeConnect(_RunSvc.Stepped, function()
        if not Config.get("bunnyHopEnabled") or Core.panicMode then return end
        local hum = getHum()
        if hum and hum:GetState() == Enum.HumanoidStateType.Landed then
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
        end
    end)
    table.insert(Core.connections, bhopConn)
    CleanupManager.register("BhopConn", function()
        if bhopConn then bhopConn:Disconnect(); bhopConn = nil end
    end)
end

-- Gravity
function MovementSystem.updateGravity()
    if not _WS then return end
    if Config.get("gravityEnabled") then
        pcall(function() _WS.Gravity = Config.get("gravityValue") or 196.2 end)
    else
        pcall(function() _WS.Gravity = 196.2 end)
    end
end

function MovementSystem.startLoop()
    if not _RunSvc then return end
    local conn = safeConnect(_RunSvc.Heartbeat, function()
        if Core.panicMode then return end
        pcall(MovementSystem.updateSpeed)
        if Config.get("flyEnabled") and not flyActive then pcall(MovementSystem.startFly) end
        if not Config.get("flyEnabled") and flyActive then pcall(MovementSystem.stopFly) end
        pcall(MovementSystem.updateGravity)
    end)
    table.insert(Core.connections, conn)
    CleanupManager.register("MovementLoop", function()
        conn:Disconnect()
        MovementSystem.stopFly()
        MovementSystem.stopNoclip()
    end)
    MovementSystem.startInfJump()
    MovementSystem.startNoclip()
    MovementSystem.startBhop()
end

-- ============================================================
-- HITBOX EXPANDER
-- ============================================================
local HitboxSystem = {}
local hitboxParts  = {}

function HitboxSystem.expand()
    if not _Players then return end
    local lp   = getLocalPlayer()
    local size = Config.get("hitboxSize") or 5
    for _, p in ipairs(_Players:GetPlayers()) do
        if p ~= lp and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp and not hitboxParts[hrp] then
                hitboxParts[hrp] = hrp.Size
                pcall(function() hrp.Size = Vector3.new(size, size, size) end)
            end
        end
    end
end

function HitboxSystem.restore()
    for part, origSize in pairs(hitboxParts) do
        pcall(function() part.Size = origSize end)
    end
    hitboxParts = {}
end

function HitboxSystem.startLoop()
    if not _RunSvc then return end
    local conn = safeConnect(_RunSvc.Heartbeat, function()
        if Core.panicMode then return end
        if Config.get("hitboxEnabled") then
            pcall(HitboxSystem.expand)
        else
            if next(hitboxParts) then pcall(HitboxSystem.restore) end
        end
    end)
    table.insert(Core.connections, conn)
    CleanupManager.register("Hitbox", function()
        conn:Disconnect()
        HitboxSystem.restore()
    end)
end

-- ============================================================
-- REACH / AUTO STAB / AUTO FLING — FIX: logiques correctes
-- ============================================================
local CombatSystem = {}

-- FIX: Reach — ne pas utiliser WeldConstraint Part0=Part1, resize le handle correctement
function CombatSystem.updateReach()
    if not Config.get("reachEnabled") then return end
    local char = getChar()
    if not char then return end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            local handle = tool:FindFirstChild("Handle")
            if handle then
                pcall(function()
                    local newZ = Config.get("reachDistance") or 15
                    -- FIX: On grow seulement Z (profondeur = direction du stab)
                    -- On mémorise la taille originale
                    if not handle:GetAttribute("KuraiOrigSizeZ") then
                        handle:SetAttribute("KuraiOrigSizeZ", handle.Size.Z)
                    end
                    handle.Size = Vector3.new(handle.Size.X, handle.Size.Y, newZ)
                end)
            end
        end
    end
end

function CombatSystem.restoreReach()
    local char = getChar()
    if not char then return end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            local handle = tool:FindFirstChild("Handle")
            if handle then
                pcall(function()
                    local origZ = handle:GetAttribute("KuraiOrigSizeZ")
                    if origZ then
                        handle.Size = Vector3.new(handle.Size.X, handle.Size.Y, origZ)
                        handle:SetAttribute("KuraiOrigSizeZ", nil)
                    end
                end)
            end
        end
    end
end

-- FIX: AutoStab — fire Tool.Activated correctement
function CombatSystem.autoStab()
    if not Config.get("autoStabEnabled") then return end
    local target = getAimTarget()
    if not target or not target.Character then return end
    local hrp       = getHRP()
    if not hrp then return end
    local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
    if not targetHRP then return end
    local dist = (hrp.Position - targetHRP.Position).Magnitude
    if dist > (Config.get("reachDistance") or 15) + 5 then return end

    local char = getChar()
    if not char then return end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            -- FIX: Utiliser tool:Activate() — méthode correcte pour déclencher un outil
            pcall(function() tool:Activate() end)
            -- Fallback RemoteEvent si :Activate() ne fire pas
            pcall(function()
                local re = tool:FindFirstChildOfClass("RemoteEvent")
                if re then re:FireServer() end
            end)
        end
    end
end

-- FIX: AutoFling — appliquer la vélocité localement seulement (moins détectable)
function CombatSystem.autoFling()
    if not Config.get("autoFlingEnabled") then return end
    local target = getAimTarget()
    if not target or not target.Character then return end
    local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
    if not targetHRP then return end
    local hrp = getHRP()
    if not hrp then return end
    local dist = (hrp.Position - targetHRP.Position).Magnitude
    if dist > 10 then return end

    pcall(function()
        local direction = (targetHRP.Position - hrp.Position).Unit
        local vel = Instance.new("BodyVelocity")
        vel.MaxForce = Vector3.new(1e6, 1e6, 1e6)
        vel.Velocity = direction * 350 + Vector3.new(0, 120, 0)
        vel.Parent   = targetHRP
        if _Debris then
            _Debris:AddItem(vel, 0.08)
        else
            task.delay(0.08, function() pcall(function() vel:Destroy() end) end)
        end
    end)
end

function CombatSystem.startLoop()
    if not _RunSvc then return end
    local conn = safeConnect(_RunSvc.Heartbeat, function()
        if Core.panicMode then return end
        if Config.get("reachEnabled") then pcall(CombatSystem.updateReach)
        else pcall(CombatSystem.restoreReach) end
        pcall(CombatSystem.autoStab)
        pcall(CombatSystem.autoFling)
    end)
    table.insert(Core.connections, conn)
    CleanupManager.register("CombatSystem", function()
        conn:Disconnect()
        CombatSystem.restoreReach()
    end)
end

-- ============================================================
-- FARM SYSTEM
-- ============================================================
local FarmSystem = {coinsThisSession=0, lastCollect=0}

local function findCoins()
    local coins = {}
    if not _WS then return coins end
    for _, obj in ipairs(_WS:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name:lower():find("coin") then
            table.insert(coins, obj)
        end
    end
    return coins
end

function FarmSystem.autoCollect()
    if not Config.get("autoCollectEnabled") then return end
    local hrp = getHRP()
    if not hrp then return end
    local range = Config.get("autoCollectRange") or 20
    local now   = tick()
    if now - FarmSystem.lastCollect < 0.2 then return end
    FarmSystem.lastCollect = now

    for _, coin in ipairs(findCoins()) do
        if coin and coin.Parent then
            local dist = (coin.Position - hrp.Position).Magnitude
            if dist <= range then
                pcall(function()
                    local lp = getLocalPlayer()
                    local c  = lp and lp.Character
                    local r  = c and c:FindFirstChild("HumanoidRootPart")
                    if r then r.CFrame = CFrame.new(coin.Position) end
                end)
                FarmSystem.coinsThisSession = FarmSystem.coinsThisSession + 1
                Statistics.coinsCollected   = Statistics.coinsCollected + 1
            end
        end
    end
end

function FarmSystem.coinFarm()
    if not Config.get("coinFarmEnabled") then return end
    local hrp = getHRP()
    if not hrp then return end
    local coins = findCoins()
    if #coins == 0 then return end

    local nearest, nearDist = nil, math.huge
    for _, coin in ipairs(coins) do
        if coin and coin.Parent then
            local d = (coin.Position - hrp.Position).Magnitude
            if d < nearDist then nearDist = d; nearest = coin end
        end
    end
    if nearest then
        pcall(function()
            local lp = getLocalPlayer()
            local c  = lp and lp.Character
            local r  = c and c:FindFirstChild("HumanoidRootPart")
            if r then r.CFrame = CFrame.new(nearest.Position) end
        end)
    end
end

function FarmSystem.startLoop()
    if not _RunSvc then return end
    local conn = safeConnect(_RunSvc.Heartbeat, function()
        if Core.panicMode then return end
        pcall(FarmSystem.autoCollect)
        pcall(FarmSystem.coinFarm)
    end)
    table.insert(Core.connections, conn)
    CleanupManager.register("FarmSystem", function() conn:Disconnect() end)
end

-- ============================================================
-- INTELLIGENCE SYSTEM (Role Detection MM2)
-- ============================================================
local IntelSystem = {
    roles       = {},
    roundActive = false,
    aliveCount  = 0,
}

function IntelSystem.startLoop()
    if not _RunSvc then return end
    local conn = safeConnect(_RunSvc.Heartbeat, function()
        if Core.panicMode then return end
        if Config.get("espEnabled") and _Players then
            local lp = getLocalPlayer()
            for _, p in ipairs(_Players:GetPlayers()) do
                if p ~= lp then
                    IntelSystem.roles[p.Name] = getPlayerRole(p)
                end
            end
        end
        if _Players then
            local alive = 0
            for _, p in ipairs(_Players:GetPlayers()) do
                local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then alive = alive + 1 end
            end
            IntelSystem.aliveCount = alive
        end
    end)
    table.insert(Core.connections, conn)
    CleanupManager.register("IntelSystem", function() conn:Disconnect() end)
end

-- ============================================================
-- CROSSHAIR SYSTEM
-- ============================================================
local CrosshairSystem = {}
local crosshairLines  = {}

function CrosshairSystem.create()
    if not hasDrawing() then return end
    if next(crosshairLines) then CrosshairSystem.cleanup() end
    crosshairLines.left  = newDrawing("Line", {Visible=false, Color=Color3.fromRGB(255,255,255), Thickness=1, Transparency=1})
    crosshairLines.right = newDrawing("Line", {Visible=false, Color=Color3.fromRGB(255,255,255), Thickness=1, Transparency=1})
    crosshairLines.up    = newDrawing("Line", {Visible=false, Color=Color3.fromRGB(255,255,255), Thickness=1, Transparency=1})
    crosshairLines.down  = newDrawing("Line", {Visible=false, Color=Color3.fromRGB(255,255,255), Thickness=1, Transparency=1})
    crosshairLines.dot   = newDrawing("Circle", {Visible=false, Color=Color3.fromRGB(255,255,255), Thickness=1, Filled=true, Radius=2, NumSides=8, Transparency=1})
end

function CrosshairSystem.setVisible(v)
    if not next(crosshairLines) then CrosshairSystem.create() end
    local cam    = getCamera()
    local center = cam and (cam.ViewportSize / 2) or Vector2.new(960, 540)
    local size   = 8
    local gap    = 3
    if crosshairLines.left  then crosshairLines.left.Visible  = v; crosshairLines.left.From  = center + Vector2.new(-size, 0); crosshairLines.left.To   = center + Vector2.new(-gap, 0) end
    if crosshairLines.right then crosshairLines.right.Visible = v; crosshairLines.right.From = center + Vector2.new(gap, 0);   crosshairLines.right.To  = center + Vector2.new(size, 0) end
    if crosshairLines.up    then crosshairLines.up.Visible    = v; crosshairLines.up.From    = center + Vector2.new(0, -size); crosshairLines.up.To     = center + Vector2.new(0, -gap) end
    if crosshairLines.down  then crosshairLines.down.Visible  = v; crosshairLines.down.From  = center + Vector2.new(0, gap);   crosshairLines.down.To   = center + Vector2.new(0, size) end
    if crosshairLines.dot   then crosshairLines.dot.Visible   = v; crosshairLines.dot.Position = center end
end

function CrosshairSystem.cleanup()
    for _, line in pairs(crosshairLines) do removeDrawing(line) end
    crosshairLines = {}
end

function CrosshairSystem.startLoop()
    if not _RunSvc then return end
    local conn = safeConnect(_RunSvc.RenderStepped, function()
        if Core.panicMode then return end
        local show = Config.get("crosshairEnabled") or false
        if show and not next(crosshairLines) then CrosshairSystem.create() end
        if next(crosshairLines) then pcall(CrosshairSystem.setVisible, show) end
    end)
    table.insert(Core.connections, conn)
    CleanupManager.register("Crosshair", function()
        conn:Disconnect()
        CrosshairSystem.cleanup()
    end)
end

-- ============================================================
-- UI SYSTEM
-- ============================================================
local UI = {
    gui=nil, startupFrame=nil, dashboardFrame=nil, shadowFrame=nil,
    sidebarFrame=nil, contentFrame=nil, toggleButton=nil,
    activeTab="Dashboard", favorites={}, recentlyUsed={},
    isVisible=true, animating=false,
}

function UI.init()
    if not _Players then Logger.log("UI","No Players service — headless mode"); return false end
    local lp = getLocalPlayer()
    if not lp then Logger.log("UI","No LocalPlayer"); return false end
    local pg = getPlayerGui()
    if not pg then Logger.log("UI","No PlayerGui"); return false end

    -- Destroy existing GUI if reloading
    local existing = pg:FindFirstChild("KuraiSoftware")
    if existing then pcall(function() existing:Destroy() end) end

    local gui = newInst("ScreenGui", pg, {
        Name="KuraiSoftware", ResetOnSpawn=false, ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset=true,
    })
    if not gui then return false end
    UI.gui = gui
    return true
end

function UI.buildStartupScreen()
    if not UI.gui then return nil end
    local theme = ThemeManager.get()
    local startup = newInst("Frame", UI.gui, {
        Name="StartupScreen", Size=UDim2.fromScale(1,1), Position=UDim2.fromScale(0,0),
        BackgroundColor3=theme.bg, BackgroundTransparency=0, ZIndex=100, BorderSizePixel=0,
    })
    UI.startupFrame = startup

    -- Gradient bg
    newInst("UIGradient", startup, {
        Color=ColorSequence.new({
            ColorSequenceKeypoint.new(0, theme.bg),
            ColorSequenceKeypoint.new(1, theme.bgSecondary),
        }), Rotation=135,
    })

    local glow = newInst("Frame", startup, {
        Name="GlowCircle", Size=UDim2.fromOffset(320,320), Position=UDim2.new(0.5,-160,0.4,-200),
        BackgroundColor3=theme.accent, BorderSizePixel=0, BackgroundTransparency=0.92, ZIndex=101,
    })
    newInst("UICorner", glow, {CornerRadius=UDim.new(1,0)})

    local logo = newInst("TextLabel", startup, {
        Name="Logo", Text="KURAI", Font=Enum.Font.GothamBold, TextSize=60,
        TextColor3=theme.text, TextTransparency=1, BackgroundTransparency=1,
        Size=UDim2.new(1,0,0,90), Position=UDim2.new(0,0,0.30,0),
        TextXAlignment=Enum.TextXAlignment.Center, ZIndex=102,
    })
    local subtitle = newInst("TextLabel", startup, {
        Name="Subtitle", Text="SOFTWARE", Font=Enum.Font.Gotham, TextSize=20,
        TextColor3=theme.accent, TextTransparency=1, BackgroundTransparency=1,
        Size=UDim2.new(1,0,0,30), Position=UDim2.new(0,0,0.42,0),
        TextXAlignment=Enum.TextXAlignment.Center, ZIndex=102,
    })
    local discord = newInst("TextLabel", startup, {
        Name="Discord", Text=KURAI_DISCORD, Font=Enum.Font.GothamMedium, TextSize=13,
        TextColor3=theme.textDim, TextTransparency=1, BackgroundTransparency=1,
        Size=UDim2.new(1,0,0,20), Position=UDim2.new(0,0,0.49,0),
        TextXAlignment=Enum.TextXAlignment.Center, ZIndex=102,
    })
    local line = newInst("Frame", startup, {
        Name="Line", Size=UDim2.new(0,0,0,1), Position=UDim2.new(0.2,0,0.60,0),
        BackgroundColor3=theme.accent, BackgroundTransparency=0.4, BorderSizePixel=0, ZIndex=102,
    })
    local statusLbl = newInst("TextLabel", startup, {
        Name="Status", Text="Initializing Kurai...", Font=Enum.Font.GothamMedium, TextSize=13,
        TextColor3=theme.textDim, TextTransparency=1, BackgroundTransparency=1,
        Size=UDim2.new(0.6,0,0,20), Position=UDim2.new(0.2,0,0.63,0),
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=103,
    })
    local progressBG = newInst("Frame", startup, {
        Name="ProgressBG", Size=UDim2.new(0.6,0,0,4), Position=UDim2.new(0.2,0,0.68,0),
        BackgroundColor3=theme.border, BackgroundTransparency=0.4, BorderSizePixel=0, ZIndex=102,
    })
    newInst("UICorner", progressBG, {CornerRadius=UDim.new(1,0)})
    local progressFill = newInst("Frame", progressBG, {
        Name="Fill", Size=UDim2.new(0,0,1,0), Position=UDim2.fromScale(0,0),
        BackgroundColor3=theme.accent, BorderSizePixel=0, ZIndex=103,
    })
    newInst("UICorner", progressFill, {CornerRadius=UDim.new(1,0)})
    newInst("UIGradient", progressFill, {
        Color=ColorSequence.new({
            ColorSequenceKeypoint.new(0, theme.accent),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(200,160,255)),
        })
    })
    newInst("TextLabel", startup, {
        Text="v" .. KURAI_VERSION, Font=Enum.Font.Gotham, TextSize=11,
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

    return {glow=glow, logo=logo, subtitle=subtitle, discord=discord,
            line=line, statusLbl=statusLbl, progressFill=progressFill}
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

    local function waitT(t)
        local s = tick()
        while tick() - s < t * speed do
            if skipped then return end
            task.wait(0.016)
        end
    end

    local function status(txt, pct)
        if els.statusLbl then pcall(function() els.statusLbl.Text = txt end) end
        if els.progressFill then safeTween(els.progressFill, "Size", UDim2.new(pct,0,1,0), 0.3*speed) end
    end

    safeTween(els.glow,     "BackgroundTransparency", 0.84, 0.8*speed); waitT(0.25)
    safeTween(els.logo,     "TextTransparency", 0, 0.7*speed);           waitT(0.35)
    safeTween(els.subtitle, "TextTransparency", 0, 0.5*speed)
    safeTween(els.discord,  "TextTransparency", 0, 0.5*speed);           waitT(0.3)
    safeTween(els.line,     "Size", UDim2.new(0.6,0,0,1), 0.45*speed);   waitT(0.15)
    safeTween(els.statusLbl,"TextTransparency", 0, 0.25*speed);           waitT(0.15)

    local steps = {
        {"Initializing Kurai...",    0.08},
        {"Detecting environment...", 0.22},
        {"Loading modules...",       0.42},
        {"Loading interface...",     0.60},
        {"Checking environment...",  0.72},
        {"Loading configuration...", 0.88},
        {"Ready.",                   1.0},
    }
    for _, s in ipairs(steps) do
        if skipped then break end
        status(s[1], s[2]); waitT(0.26)
    end
    status("Ready.", 1.0); waitT(0.45)

    if UI.startupFrame then
        safeTween(UI.startupFrame, "BackgroundTransparency", 1, 0.4*speed)
        for _, child in ipairs(UI.startupFrame:GetDescendants()) do
            if child:IsA("TextLabel") then safeTween(child,"TextTransparency",1,0.35*speed)
            elseif child:IsA("Frame") then safeTween(child,"BackgroundTransparency",1,0.35*speed) end
        end
        waitT(0.45)
        pcall(function() UI.startupFrame.Visible = false end)
    end

    if onComplete then onComplete() end
end

-- ============================================================
-- UI DASHBOARD
-- ============================================================
function UI.buildDashboard()
    if not UI.gui then return end
    local theme  = ThemeManager.get()
    local cam    = getCamera()
    local vpSize = cam and cam.ViewportSize or Vector2.new(1920, 1080)
    local W, H   = 720, 480

    -- Shadow
    UI.shadowFrame = newInst("Frame", UI.gui, {
        Name="KuraiShadow",
        Size=UDim2.fromOffset(W+20, H+20),
        Position=UDim2.new(0.5, -(W+20)/2, 0.5, -(H+20)/2),
        BackgroundColor3=Color3.fromRGB(0,0,0),
        BackgroundTransparency=0.5, BorderSizePixel=0, ZIndex=1,
    })
    newInst("UICorner", UI.shadowFrame, {CornerRadius=UDim.new(0,16)})

    -- Main frame
    local main = newInst("Frame", UI.gui, {
        Name="KuraiDashboard",
        Size=UDim2.fromOffset(W, H),
        Position=UDim2.new(0.5, -W/2, 0.5, -H/2),
        BackgroundColor3=theme.bg, BackgroundTransparency=0.02,
        BorderSizePixel=0, ZIndex=2,
    })
    newInst("UICorner", main, {CornerRadius=UDim.new(0,12)})
    newInst("UIStroke", main, {Color=theme.border, Thickness=1, Transparency=0.5})
    UI.dashboardFrame = main

    -- Titlebar
    local titlebar = newInst("Frame", main, {
        Name="Titlebar",
        Size=UDim2.new(1,0,0,40),
        BackgroundColor3=theme.bgSecondary, BackgroundTransparency=0, BorderSizePixel=0, ZIndex=3,
    })
    newInst("UICorner", titlebar, {CornerRadius=UDim.new(0,12)})
    -- Fix corner bottom de la titlebar
    newInst("Frame", titlebar, {
        Size=UDim2.new(1,0,0.5,0), Position=UDim2.new(0,0,0.5,0),
        BackgroundColor3=theme.bgSecondary, BorderSizePixel=0, ZIndex=3,
    })

    newInst("TextLabel", titlebar, {
        Text="KURAI  SOFTWARE",
        Font=Enum.Font.GothamBold, TextSize=15,
        TextColor3=theme.accent, BackgroundTransparency=1,
        Size=UDim2.new(0,200,1,0), Position=UDim2.new(0,14,0,0),
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=4,
    })
    newInst("TextLabel", titlebar, {
        Text="v"..KURAI_VERSION,
        Font=Enum.Font.Gotham, TextSize=11,
        TextColor3=theme.textDim, BackgroundTransparency=1,
        Size=UDim2.new(0,80,1,0), Position=UDim2.new(0,160,0,0),
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=4,
    })

    -- Close / minimize buttons
    local function makeWinBtn(color, xOff, onClick)
        local b = newInst("TextButton", titlebar, {
            Size=UDim2.fromOffset(12,12), Position=UDim2.new(1,xOff,0.5,-6),
            BackgroundColor3=color, BorderSizePixel=0, Text="", ZIndex=5,
        })
        newInst("UICorner", b, {CornerRadius=UDim.new(1,0)})
        if b and onClick then b.MouseButton1Click:Connect(onClick) end
        return b
    end
    makeWinBtn(Color3.fromRGB(255,90,90),  -20, function() UI.hide() end)
    makeWinBtn(Color3.fromRGB(255,190,60), -38, function() UI.hide() end)

    -- Dragging
    local dragging, dragStart, frameStart = false, nil, nil
    titlebar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging   = true
            dragStart  = inp.Position
            frameStart = main.Position
        end
    end)
    titlebar.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    safeConnect(_UIS and _UIS.InputChanged, function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = inp.Position - dragStart
            main.Position = UDim2.new(
                frameStart.X.Scale, frameStart.X.Offset + delta.X,
                frameStart.Y.Scale, frameStart.Y.Offset + delta.Y
            )
        end
    end)

    -- Sidebar
    local sidebar = newInst("Frame", main, {
        Name="Sidebar",
        Size=UDim2.new(0,140,1,-40), Position=UDim2.new(0,0,0,40),
        BackgroundColor3=theme.bgSecondary, BackgroundTransparency=0.2, BorderSizePixel=0, ZIndex=3,
    })
    newInst("UIListLayout", sidebar, {Padding=UDim.new(0,4), SortOrder=Enum.SortOrder.LayoutOrder})
    newInst("UIPadding", sidebar, {PaddingTop=UDim.new(0,8), PaddingLeft=UDim.new(0,8), PaddingRight=UDim.new(0,8)})
    UI.sidebarFrame = sidebar

    -- Content
    local content = newInst("ScrollingFrame", main, {
        Name="Content",
        Size=UDim2.new(1,-140,1,-40), Position=UDim2.new(0,140,0,40),
        BackgroundColor3=theme.bg, BackgroundTransparency=0.05, BorderSizePixel=0,
        ScrollBarThickness=4, ScrollBarImageColor3=theme.accent,
        CanvasSize=UDim2.new(0,0,0,0), ZIndex=3,
    })
    newInst("UIListLayout", content, {Padding=UDim.new(0,6), SortOrder=Enum.SortOrder.LayoutOrder})
    newInst("UIPadding", content, {PaddingTop=UDim.new(0,10), PaddingLeft=UDim.new(0,12), PaddingRight=UDim.new(0,12)})
    UI.contentFrame = content

    -- Sidebar tabs
    local tabs = {"Dashboard","ESP","Combat","Movement","Farm","Intel","Visual","Config","Stats","Logs"}
    for i, tabName in ipairs(tabs) do
        local btn = newInst("TextButton", sidebar, {
            Name="Tab_"..tabName, Text=tabName,
            Font=Enum.Font.GothamMedium, TextSize=13,
            TextColor3=(tabName == UI.activeTab and theme.accent or theme.textDim),
            BackgroundColor3=(tabName == UI.activeTab and theme.bgTertiary or Color3.fromRGB(0,0,0)),
            BackgroundTransparency=(tabName == UI.activeTab and 0 or 1),
            Size=UDim2.new(1,0,0,32), BorderSizePixel=0,
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=4,
            LayoutOrder=i,
        })
        if btn then
            newInst("UIPadding", btn, {PaddingLeft=UDim.new(0,10)})
            newInst("UICorner", btn, {CornerRadius=UDim.new(0,6)})
            btn.MouseButton1Click:Connect(function()
                UI.activeTab = tabName
                -- Update all tab button colors
                for _, ch in ipairs(sidebar:GetChildren()) do
                    if ch:IsA("TextButton") then
                        local active = ch.Name == "Tab_"..tabName
                        ch.TextColor3          = active and theme.accent or theme.textDim
                        ch.BackgroundColor3    = active and theme.bgTertiary or Color3.fromRGB(0,0,0)
                        ch.BackgroundTransparency = active and 0 or 1
                    end
                end
                UI.populateTab(tabName)
            end)
        end
    end

    UI.populateTab(UI.activeTab)
end

-- UI Helpers
local function makeToggle(parent, label, configKey, order)
    local theme = ThemeManager.get()
    local row = newInst("Frame", parent, {
        BackgroundColor3=theme.bgSecondary, BackgroundTransparency=0.3,
        Size=UDim2.new(1,0,0,38), BorderSizePixel=0, ZIndex=5, LayoutOrder=order or 0,
    })
    newInst("UICorner", row, {CornerRadius=UDim.new(0,8)})
    newInst("TextLabel", row, {
        Text=label, Font=Enum.Font.GothamMedium, TextSize=13,
        TextColor3=theme.text, BackgroundTransparency=1,
        Size=UDim2.new(0.75,0,1,0), Position=UDim2.new(0,12,0,0),
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=6,
    })

    local togBg = newInst("Frame", row, {
        Size=UDim2.fromOffset(40,22), Position=UDim2.new(1,-52,0.5,-11),
        BackgroundColor3=Config.get(configKey) and Color3.fromRGB(120,80,255) or theme.border,
        BorderSizePixel=0, ZIndex=6,
    })
    newInst("UICorner", togBg, {CornerRadius=UDim.new(1,0)})
    local togKnob = newInst("Frame", togBg, {
        Size=UDim2.fromOffset(16,16), Position=Config.get(configKey) and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8),
        BackgroundColor3=Color3.fromRGB(255,255,255), BorderSizePixel=0, ZIndex=7,
    })
    newInst("UICorner", togKnob, {CornerRadius=UDim.new(1,0)})

    local togBtn = newInst("TextButton", togBg, {
        Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Text="", ZIndex=8,
    })
    if togBtn then
        togBtn.MouseButton1Click:Connect(function()
            local v = not Config.get(configKey)
            Config.set(configKey, v)
            safeTween(togBg, "BackgroundColor3", v and Color3.fromRGB(120,80,255) or theme.border, 0.18)
            safeTween(togKnob, "Position", v and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8), 0.18)
        end)
    end
    return row
end

local function makeSlider(parent, label, configKey, min, max, order)
    local theme = ThemeManager.get()
    local row = newInst("Frame", parent, {
        BackgroundColor3=theme.bgSecondary, BackgroundTransparency=0.3,
        Size=UDim2.new(1,0,0,52), BorderSizePixel=0, ZIndex=5, LayoutOrder=order or 0,
    })
    newInst("UICorner", row, {CornerRadius=UDim.new(0,8)})
    local val = Config.get(configKey) or min
    local lbl = newInst("TextLabel", row, {
        Text=label.." : "..tostring(val), Font=Enum.Font.GothamMedium, TextSize=12,
        TextColor3=theme.text, BackgroundTransparency=1,
        Size=UDim2.new(1,-12,0,26), Position=UDim2.new(0,12,0,0),
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=6,
    })
    local trackBg = newInst("Frame", row, {
        Size=UDim2.new(1,-24,0,6), Position=UDim2.new(0,12,0,30),
        BackgroundColor3=theme.border, BorderSizePixel=0, ZIndex=6,
    })
    newInst("UICorner", trackBg, {CornerRadius=UDim.new(1,0)})
    local ratio = math.clamp((val-min)/(math.max(max-min,1)), 0, 1)
    local fill = newInst("Frame", trackBg, {
        Size=UDim2.new(ratio,0,1,0), BackgroundColor3=Color3.fromRGB(120,80,255),
        BorderSizePixel=0, ZIndex=7,
    })
    newInst("UICorner", fill, {CornerRadius=UDim.new(1,0)})

    local draggingSlider = false
    local sliderBtn = newInst("TextButton", trackBg, {
        Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Text="", ZIndex=9,
    })
    local function updateSlider(x)
        local abs    = trackBg.AbsolutePosition.X
        local width  = trackBg.AbsoluteSize.X
        local t      = math.clamp((x - abs) / width, 0, 1)
        local newVal = math.floor(min + t * (max - min))
        Config.set(configKey, newVal)
        fill.Size = UDim2.new(t, 0, 1, 0)
        if lbl then lbl.Text = label.." : "..tostring(newVal) end
    end
    if sliderBtn then
        sliderBtn.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                draggingSlider = true
                updateSlider(inp.Position.X)
            end
        end)
        sliderBtn.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                draggingSlider = false
            end
        end)
        safeConnect(_UIS and _UIS.InputChanged, function(inp)
            if draggingSlider and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
                updateSlider(inp.Position.X)
            end
        end)
    end
    return row
end

local function makeButton(parent, label, onClick, order)
    local theme = ThemeManager.get()
    local btn = newInst("TextButton", parent, {
        Text=label, Font=Enum.Font.GothamBold, TextSize=13,
        TextColor3=Color3.fromRGB(255,255,255),
        BackgroundColor3=theme.accent, BorderSizePixel=0,
        Size=UDim2.new(1,0,0,36), ZIndex=5, LayoutOrder=order or 0,
    })
    newInst("UICorner", btn, {CornerRadius=UDim.new(0,8)})
    if btn and onClick then
        btn.MouseButton1Click:Connect(function()
            pcall(onClick)
            safeTween(btn,"BackgroundColor3",Color3.fromRGB(80,50,180),0.1)
            task.delay(0.15, function() safeTween(btn,"BackgroundColor3",theme.accent,0.15) end)
        end)
    end
    return btn
end

local function makeSectionLabel(parent, txt, order)
    local theme = ThemeManager.get()
    local lbl = newInst("TextLabel", parent, {
        Text=txt, Font=Enum.Font.GothamBold, TextSize=12,
        TextColor3=theme.accent, BackgroundTransparency=1,
        Size=UDim2.new(1,0,0,22), ZIndex=5, LayoutOrder=order or 0,
        TextXAlignment=Enum.TextXAlignment.Left,
    })
    newInst("UIPadding", lbl, {PaddingLeft=UDim.new(0,4)})
    return lbl
end

function UI.clearContent()
    if not UI.contentFrame then return end
    for _, ch in ipairs(UI.contentFrame:GetChildren()) do
        if not ch:IsA("UIListLayout") and not ch:IsA("UIPadding") then
            pcall(function() ch:Destroy() end)
        end
    end
end

function UI.populateTab(tabName)
    UI.clearContent()
    local cf = UI.contentFrame
    if not cf then return end
    local o = 0
    local function ord() o = o + 1; return o end

    if tabName == "Dashboard" then
        local theme = ThemeManager.get()
        local lp    = getLocalPlayer()
        local infos = {
            {"Player",   lp and lp.DisplayName or "N/A"},
            {"Executor", Platform.executor},
            {"Platform", Platform.os},
            {"Drawing",  tostring(hasDrawing())},
            {"Version",  KURAI_VERSION},
            {"FPS",      tostring(Performance.fps)},
            {"Uptime",   string.format("%.0fs", os.clock()-Core.sessionStart)},
            {"Active",   tostring(#vim_table_keys(Core.activeFeatures))},
        }
        -- helper
        local function countKeys(t) local n=0; for _ in pairs(t) do n=n+1 end; return n end
        infos[8][2] = tostring(countKeys(Core.activeFeatures))

        makeSectionLabel(cf, "◈  SYSTEM INFO", ord())
        for _, row in ipairs(infos) do
            local f = newInst("Frame", cf, {
                BackgroundColor3=theme.bgSecondary, BackgroundTransparency=0.4,
                Size=UDim2.new(1,0,0,30), BorderSizePixel=0, ZIndex=5, LayoutOrder=ord(),
            })
            newInst("UICorner", f, {CornerRadius=UDim.new(0,6)})
            newInst("TextLabel", f, {
                Text=row[1], Font=Enum.Font.GothamMedium, TextSize=12,
                TextColor3=theme.textDim, BackgroundTransparency=1,
                Size=UDim2.new(0.45,0,1,0), Position=UDim2.new(0,10,0,0),
                TextXAlignment=Enum.TextXAlignment.Left, ZIndex=6,
            })
            newInst("TextLabel", f, {
                Text=row[2], Font=Enum.Font.GothamBold, TextSize=12,
                TextColor3=theme.text, BackgroundTransparency=1,
                Size=UDim2.new(0.5,0,1,0), Position=UDim2.new(0.47,0,0,0),
                TextXAlignment=Enum.TextXAlignment.Left, ZIndex=6,
            })
        end
        makeSectionLabel(cf, "◈  QUICK ACTIONS", ord())
        makeButton(cf, "Panic (End)", function() PanicButton.activate() end, ord())
        makeButton(cf, "Reset Config", function() Config.reset(); NotificationManager.send("Config","Reset","INFO",2) end, ord())
        makeButton(cf, "Reload UI", function()
            pcall(UI.buildDashboard)
            NotificationManager.send("UI","Reloaded","INFO",2)
        end, ord())

    elseif tabName == "ESP" then
        makeSectionLabel(cf, "◈  ESP SETTINGS", ord())
        makeToggle(cf, "ESP Enabled",    "espEnabled",       ord())
        makeToggle(cf, "Box ESP",        "espBoxEnabled",    ord())
        makeToggle(cf, "Name ESP",       "espNameEnabled",   ord())
        makeToggle(cf, "Distance ESP",   "espDistEnabled",   ord())
        makeToggle(cf, "Health Bar",     "espHealthEnabled", ord())
        makeToggle(cf, "Tracer",         "espTracerEnabled", ord())
        makeToggle(cf, "Skeleton ESP",   "espSkeletonEnabled", ord())
        makeToggle(cf, "Chams",          "espChamsEnabled",  ord())
        makeToggle(cf, "Rainbow Mode",   "espRainbowEnabled",ord())
        makeToggle(cf, "Team Check",     "espTeamCheck",     ord())
        makeSectionLabel(cf, "◈  ESP OPTIONS", ord())
        makeSlider(cf, "ESP Range", "espRange", 50, 2000, ord())
        makeSlider(cf, "Line Thickness", "espThickness", 1, 5, ord())

    elseif tabName == "Combat" then
        makeSectionLabel(cf, "◈  AIM", ord())
        makeToggle(cf, "Aimbot",      "aimbotEnabled",    ord())
        makeToggle(cf, "Silent Aim",  "silentAimEnabled", ord())
        makeToggle(cf, "Cam Lock",    "camLockEnabled",   ord())
        makeSlider(cf, "FOV Radius (px)", "aimFOV",     30, 500, ord())
        makeSlider(cf, "Smoothing %",     "aimSmoothing", 0, 100, ord())
        makeSectionLabel(cf, "◈  COMBAT", ord())
        makeToggle(cf, "Auto Stab",       "autoStabEnabled",  ord())
        makeToggle(cf, "Hitbox Expander", "hitboxEnabled",    ord())
        makeSlider(cf, "Hitbox Size",     "hitboxSize",  2, 50, ord())
        makeToggle(cf, "Reach",           "reachEnabled",     ord())
        makeSlider(cf, "Reach Distance",  "reachDistance", 5, 80, ord())
        makeToggle(cf, "Auto Fling",      "autoFlingEnabled", ord())

    elseif tabName == "Movement" then
        makeSectionLabel(cf, "◈  MOVEMENT", ord())
        makeToggle(cf, "Speed",       "speedEnabled",   ord())
        makeSlider(cf, "Walk Speed",  "walkSpeed",  16, 300, ord())
        makeSlider(cf, "Jump Power",  "jumpPower",  50, 300, ord())
        makeToggle(cf, "Fly",         "flyEnabled",     ord())
        makeSlider(cf, "Fly Speed",   "flySpeed",   10, 300, ord())
        makeToggle(cf, "Noclip",      "noclipEnabled",  ord())
        makeToggle(cf, "Inf Jump",    "infJumpEnabled", ord())
        makeToggle(cf, "Bunny Hop",   "bunnyHopEnabled",ord())
        makeToggle(cf, "Gravity Mod", "gravityEnabled", ord())
        makeSlider(cf, "Gravity",     "gravityValue", 0, 400, ord())

    elseif tabName == "Farm" then
        makeSectionLabel(cf, "◈  FARM", ord())
        makeToggle(cf, "Auto Collect", "autoCollectEnabled", ord())
        makeSlider(cf, "Collect Range","autoCollectRange",  5, 100, ord())
        makeToggle(cf, "Coin Farm (TP)","coinFarmEnabled",  ord())

    elseif tabName == "Intel" then
        makeSectionLabel(cf, "◈  INTELLIGENCE", ord())
        local theme = ThemeManager.get()
        local lp    = getLocalPlayer()
        if _Players then
            for _, p in ipairs(_Players:GetPlayers()) do
                if p ~= lp then
                    local role  = IntelSystem.roles[p.Name] or getPlayerRole(p)
                    local color = role == "Murderer" and theme.danger
                              or role == "Sheriff"  and theme.info
                              or theme.textDim
                    local row = newInst("Frame", cf, {
                        BackgroundColor3=theme.bgSecondary, BackgroundTransparency=0.4,
                        Size=UDim2.new(1,0,0,30), BorderSizePixel=0, ZIndex=5, LayoutOrder=ord(),
                    })
                    newInst("UICorner", row, {CornerRadius=UDim.new(0,6)})
                    newInst("TextLabel", row, {
                        Text=p.DisplayName or p.Name, Font=Enum.Font.GothamMedium, TextSize=12,
                        TextColor3=theme.text, BackgroundTransparency=1,
                        Size=UDim2.new(0.6,0,1,0), Position=UDim2.new(0,10,0,0),
                        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=6,
                    })
                    newInst("TextLabel", row, {
                        Text=role, Font=Enum.Font.GothamBold, TextSize=12,
                        TextColor3=color, BackgroundTransparency=1,
                        Size=UDim2.new(0.4,0,1,0), Position=UDim2.new(0.6,0,0,0),
                        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=6,
                    })
                end
            end
        end
        makeButton(cf, "Refresh", function() UI.populateTab("Intel") end, ord())

    elseif tabName == "Visual" then
        makeSectionLabel(cf, "◈  VISUAL", ord())
        makeToggle(cf, "Crosshair", "crosshairEnabled", ord())
        makeSectionLabel(cf, "◈  THEME", ord())
        for _, tname in ipairs({"Dark","Midnight","Neon","Glass","AMOLED"}) do
            makeButton(cf, "Theme: "..tname, function()
                ThemeManager.set(tname)
                pcall(UI.buildDashboard)
            end, ord())
        end

    elseif tabName == "Config" then
        makeSectionLabel(cf, "◈  CONFIGURATION", ord())
        makeToggle(cf, "Startup Animation", "startupAnimation", ord())
        makeSlider(cf, "Anim Speed %", "animationSpeed", 1, 10, ord())
        makeToggle(cf, "Performance Mode", "performanceMode", ord())
        makeToggle(cf, "Debug Mode", "debugMode", ord())
        makeSectionLabel(cf, "◈  ACTIONS", ord())
        makeButton(cf, "Save Config",  function() Config.save();  NotificationManager.send("Config","Saved","INFO",2) end, ord())
        makeButton(cf, "Reset Config", function() Config.reset(); NotificationManager.send("Config","Reset","INFO",2) end, ord())

    elseif tabName == "Stats" then
        makeSectionLabel(cf, "◈  SESSION STATS", ord())
        local theme = ThemeManager.get()
        local stats = {
            {"FPS",      tostring(Performance.fps)},
            {"Session",  string.format("%.0fs", os.clock()-Core.sessionStart)},
            {"Kills",    tostring(Statistics.totalKills)},
            {"Deaths",   tostring(Statistics.totalDeaths)},
            {"K/D",      tostring(Statistics.getKD())},
            {"Coins",    tostring(Statistics.coinsCollected)},
            {"Players",  _Players and tostring(#_Players:GetPlayers()) or "0"},
            {"Alive",    tostring(IntelSystem.aliveCount)},
            {"Executor", Platform.executor},
            {"Drawing",  tostring(hasDrawing())},
        }
        for _, row in ipairs(stats) do
            local f = newInst("Frame", cf, {
                BackgroundColor3=theme.bgSecondary, BackgroundTransparency=0.4,
                Size=UDim2.new(1,0,0,28), BorderSizePixel=0, ZIndex=5, LayoutOrder=ord(),
            })
            newInst("UICorner", f, {CornerRadius=UDim.new(0,6)})
            newInst("TextLabel", f, {
                Text=row[1], Font=Enum.Font.GothamMedium, TextSize=12,
                TextColor3=theme.textDim, BackgroundTransparency=1,
                Size=UDim2.new(0.5,0,1,0), Position=UDim2.new(0,10,0,0),
                TextXAlignment=Enum.TextXAlignment.Left, ZIndex=6,
            })
            newInst("TextLabel", f, {
                Text=row[2], Font=Enum.Font.GothamBold, TextSize=12,
                TextColor3=theme.text, BackgroundTransparency=1,
                Size=UDim2.new(0.5,0,1,0), Position=UDim2.new(0.5,0,0,0),
                TextXAlignment=Enum.TextXAlignment.Left, ZIndex=6,
            })
        end
        makeButton(cf, "Reset Stats", function() Statistics.reset(); UI.populateTab("Stats") end, ord())

    elseif tabName == "Logs" then
        makeSectionLabel(cf, "◈  LOGS", ord())
        local theme = ThemeManager.get()
        local logs  = Core.logs
        if #logs == 0 then
            newInst("TextLabel", cf, {
                Text="No logs yet.", Font=Enum.Font.Gotham, TextSize=12,
                TextColor3=theme.textDim, BackgroundTransparency=1,
                Size=UDim2.new(1,0,0,28), ZIndex=5, LayoutOrder=ord(),
                TextXAlignment=Enum.TextXAlignment.Left,
            })
        else
            for i = #logs, math.max(#logs-80, 0)+1, -1 do
                local e   = logs[i]
                local row = newInst("Frame", cf, {
                    BackgroundColor3=theme.bgSecondary, BackgroundTransparency=0.5,
                    Size=UDim2.new(1,0,0,26), BorderSizePixel=0, ZIndex=5, LayoutOrder=ord(),
                })
                newInst("UICorner", row, {CornerRadius=UDim.new(0,5)})
                local col = theme.textDim
                if e.level=="ERROR" then col=theme.danger
                elseif e.level=="WARN" then col=theme.warning end
                newInst("TextLabel", row, {
                    Text=string.format("[%.1fs][%s] %s", e.timestamp, e.category, e.message),
                    Font=Enum.Font.Code, TextSize=10, TextColor3=col,
                    BackgroundTransparency=1, Size=UDim2.new(1,-16,1,0),
                    Position=UDim2.new(0,8,0,0),
                    TextXAlignment=Enum.TextXAlignment.Left,
                    TextTruncate=Enum.TextTruncate.AtEnd, ZIndex=6,
                })
            end
        end
        makeButton(cf, "Clear Logs", function() Core.logs={}; UI.populateTab("Logs") end, ord())
    end

    -- Auto-resize canvas
    task.wait()
    pcall(function()
        local layout = UI.contentFrame:FindFirstChildOfClass("UIListLayout")
        if layout then
            UI.contentFrame.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
        end
    end)
end

function UI.show()
    if not UI.dashboardFrame then return end
    UI.dashboardFrame.Visible = true
    if UI.shadowFrame then UI.shadowFrame.Visible = true end
    UI.dashboardFrame.BackgroundTransparency = 1
    safeTween(UI.dashboardFrame, "BackgroundTransparency", 0.02, 0.35)
    UI.isVisible = true
end
function UI.hide()
    if not UI.dashboardFrame then return end
    safeTween(UI.dashboardFrame, "BackgroundTransparency", 1, 0.3)
    task.delay(0.35, function()
        if UI.dashboardFrame then UI.dashboardFrame.Visible = false end
        if UI.shadowFrame     then UI.shadowFrame.Visible = false end
    end)
    UI.isVisible = false
end
function UI.toggleVisibility()
    if UI.isVisible then UI.hide() else UI.show() end
end

-- Mobile button
function UI.buildMobileToggleButton()
    if not UI.gui then return end
    local theme = ThemeManager.get()
    local btn = newInst("TextButton", UI.gui, {
        Name="KuraiToggleBtn",
        Size=UDim2.fromOffset(50,50), Position=UDim2.new(0,10,0.5,-25),
        BackgroundColor3=theme.accent, Text="K",
        Font=Enum.Font.GothamBold, TextSize=20,
        TextColor3=Color3.fromRGB(255,255,255), BorderSizePixel=0, ZIndex=200,
    })
    newInst("UICorner", btn, {CornerRadius=UDim.new(1,0)})
    newInst("UIStroke", btn, {Color=Color3.fromRGB(255,255,255), Thickness=1, Transparency=0.7})

    local dragging, dragStart, btnStart, moved = false, nil, nil, false
    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; dragStart = input.Position; btnStart = btn.Position; moved = false
        end
    end)
    btn.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - dragStart
            if math.abs(delta.X) > 5 or math.abs(delta.Y) > 5 then moved = true end
            local cam    = getCamera()
            local vpSize = cam and cam.ViewportSize or Vector2.new(1920,1080)
            local newX   = math.clamp(btnStart.X.Offset + delta.X, 0, vpSize.X - 55)
            local newY   = math.clamp(btnStart.Y.Scale * vpSize.Y + btnStart.Y.Offset + delta.Y, 0, vpSize.Y - 55)
            btn.Position = UDim2.fromOffset(newX, newY)
        end
    end)
    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            if not moved then UI.toggleVisibility() end
            dragging = false
        end
    end)
    UI.toggleButton = btn
end

-- Helper manquant dans le Dashboard tab
local function vim_table_keys(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

-- ============================================================
-- TOGGLE KEYBIND
-- ============================================================
local function setupToggleKeybind()
    if not _UIS then return end
    local conn = safeConnect(_UIS.InputBegan, function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.RightControl then UI.toggleVisibility() end
        if input.KeyCode == Enum.KeyCode.End          then PanicButton.activate() end
    end)
    table.insert(Core.connections, conn)
    CleanupManager.register("ToggleKeybind", function() conn:Disconnect() end)
end

-- ============================================================
-- STATS REFRESH (live 2s)
-- ============================================================
local function startStatsRefresh()
    if not _RunSvc then return end
    local elapsed = 0
    local conn = safeConnect(_RunSvc.Heartbeat, function(dt)
        if Core.panicMode then return end
        elapsed = elapsed + dt
        if elapsed >= 2 then
            elapsed = 0
            if UI.activeTab == "Stats" or UI.activeTab == "Dashboard" then
                pcall(function() UI.populateTab(UI.activeTab) end)
            end
            pcall(ServerInfo.refresh)
        end
    end)
    table.insert(Core.connections, conn)
    CleanupManager.register("StatsRefresh", function() conn:Disconnect() end)
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

    -- Sync silent aim state si déjà configuré
    if Config.get("silentAimEnabled") then
        Config.set("silentAimEnabled", false) -- reset proprement au boot
    end

    local uiReady = false
    pcall(function() uiReady = UI.init() end)

    local function startAllLoops()
        pcall(ESP.startLoop)
        pcall(Chams.startLoop)
        pcall(AimSystem.startLoop)
        pcall(MovementSystem.startLoop)
        pcall(HitboxSystem.startLoop)
        pcall(CombatSystem.startLoop)
        pcall(FarmSystem.startLoop)
        pcall(IntelSystem.startLoop)
        pcall(CrosshairSystem.startLoop)
    end

    if not uiReady then
        Logger.log("Boot","Headless mode — no UI")
        Core.initialized = true
        startAllLoops()
        return
    end

    if not Config.get("startupAnimation") then
        pcall(UI.buildDashboard)
        pcall(UI.buildMobileToggleButton)
        UI.show()
        KeybindManager.init()
        setupToggleKeybind()
        startStatsRefresh()
        startAllLoops()
        Core.initialized = true
        Logger.log("Boot","Ready (no animation)")
        return
    end

    local elements
    local ok, err = pcall(function() elements = UI.buildStartupScreen() end)
    if not ok then
        Logger.error("Boot","buildStartupScreen",err)
        pcall(UI.buildDashboard)
        pcall(UI.buildMobileToggleButton)
        UI.show()
        startAllLoops()
        Core.initialized = true
        return
    end

    task.spawn(function()
        local ok2, err2 = pcall(function()
            UI.playStartupAnimation(elements, function()
                pcall(UI.buildDashboard)
                pcall(UI.buildMobileToggleButton)
                UI.show()
                KeybindManager.init()
                setupToggleKeybind()
                startStatsRefresh()
                startAllLoops()
                Core.initialized = true
                Logger.log("Boot","Kurai v2.1.0 ready.")
                NotificationManager.send("Kurai","Ready — RightCtrl to toggle","INFO",4)
            end)
        end)
        if not ok2 then
            Logger.error("Boot","Animation",err2)
            pcall(UI.buildDashboard)
            pcall(UI.buildMobileToggleButton)
            UI.show()
            startAllLoops()
            Core.initialized = true
        end
    end)
end

-- Exports
KuraiSoftware.Core               = Core
KuraiSoftware.Platform           = Platform
KuraiSoftware.Config             = Config
KuraiSoftware.Logger             = Logger
KuraiSoftware.FeatureManager     = FeatureManager
KuraiSoftware.KeybindManager     = KeybindManager
KuraiSoftware.NotificationManager = NotificationManager
KuraiSoftware.Performance        = Performance
KuraiSoftware.Statistics         = Statistics
KuraiSoftware.ThemeManager       = ThemeManager
KuraiSoftware.TargetManager      = TargetManager
KuraiSoftware.PanicButton        = PanicButton
KuraiSoftware.ESP                = ESP
KuraiSoftware.AimSystem          = AimSystem
KuraiSoftware.MovementSystem     = MovementSystem
KuraiSoftware.FarmSystem         = FarmSystem
KuraiSoftware.IntelSystem        = IntelSystem
KuraiSoftware.CombatSystem       = CombatSystem
KuraiSoftware.HitboxSystem       = HitboxSystem
KuraiSoftware.CrosshairSystem    = CrosshairSystem
KuraiSoftware.UI                 = UI

KuraiSoftware.init()
return KuraiSoftware

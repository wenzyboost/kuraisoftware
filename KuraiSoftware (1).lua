--[[
    ██╗  ██╗██╗   ██╗██████╗  █████╗ ██╗
    ██║ ██╔╝██║   ██║██╔══██╗██╔══██╗██║
    █████╔╝ ██║   ██║██████╔╝███████║██║
    ██╔═██╗ ██║   ██║██╔══██╗██╔══██║██║
    ██║  ██╗╚██████╔╝██║  ██║██║  ██║██║
    ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝
    KURAI SOFTWARE — v2.0.0
    discord.gg/kuraishop
    Single-File | All Features Implemented
--]]

-- ============================================================
-- COMPAT LAYER
-- ============================================================
local function safeService(name)
    local ok, svc = pcall(function() return game:GetService(name) end)
    return ok and svc or nil
end

local _Players      = safeService("Players")
local _TweenSvc     = safeService("TweenService")
local _RunSvc       = safeService("RunService")
local _UIS          = safeService("UserInputService")
local _StarterGui   = safeService("StarterGui")
local _HttpSvc      = safeService("HttpService")
local _WS           = safeService("Workspace")
local _CamSvc       = safeService("Workspace") -- camera via workspace
local _ContextAS    = safeService("ContextActionService")
local _PhysicsSvc   = safeService("PhysicsService")

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
local KURAI_VERSION = "2.0.0"
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
    support = {},
}

function Platform.detect()
    if     _G["DELTA_ENV"]          then Platform.os = "Android"; Platform.executor = "Delta"
    elseif _G["Codex"]              then Platform.os = "Android"; Platform.executor = "Codex"
    elseif _G["ArceuX"]            then Platform.os = "Android"; Platform.executor = "Arceus X"
    elseif _G["VegaX"]             then Platform.os = "Android"; Platform.executor = "Vega X"
    elseif _G["Cryptic"]           then Platform.os = "Android"; Platform.executor = "Cryptic"
    elseif _G["Hydrogen"]          then Platform.os = "Android"; Platform.executor = "Hydrogen"
    elseif _G["Ronix"]             then Platform.os = "Android"; Platform.executor = "Ronix"
    elseif _G["syn"]               then Platform.os = "Windows"; Platform.executor = "Synapse Z"
    elseif _G["KRNL_LOADED"]       then Platform.os = "Windows"; Platform.executor = "KRNL"
    elseif _G["fluxus"]            then Platform.os = "Windows"; Platform.executor = "Fluxus"
    elseif _G["is_sirhurt_closure"] then Platform.os = "Windows"; Platform.executor = "SirHurt"
    elseif _G["Xeno"]              then Platform.os = "Windows"; Platform.executor = "Xeno"
    elseif _G["Wave"]              then Platform.os = "Windows"; Platform.executor = "Wave"
    elseif _G["Solara"]            then Platform.os = "Windows"; Platform.executor = "Solara"
    elseif _G["Volt"]              then Platform.os = "Windows"; Platform.executor = "Volt"
    elseif _G["Potassium"]         then Platform.os = "Windows"; Platform.executor = "Potassium"
    elseif _G["Cosmic"]            then Platform.os = "Windows"; Platform.executor = "Cosmic"
    elseif _G["MacSploit"]         then Platform.os = "macOS";   Platform.executor = "MacSploit"
    elseif _G["Opiumware"]         then Platform.os = "macOS";   Platform.executor = "Opiumware"
    else
        Platform.os       = "Windows"
        Platform.executor = "Unknown"
    end

    Platform.capabilities.ui         = (_Players ~= nil)
    Platform.capabilities.drawing    = (rawget(_G,"Drawing") ~= nil)
    Platform.capabilities.filesystem = (rawget(_G,"writefile") ~= nil)
    Platform.capabilities.network    = (rawget(_G,"request") ~= nil or rawget(_G,"http") ~= nil)
    Platform.capabilities.input      = (_UIS ~= nil)
    Platform.capabilities.visuals    = Platform.capabilities.drawing
    Platform.initialized = true
end

function Platform.featureAvailable() return not Core.panicMode end

-- ============================================================
-- LOGGER
-- ============================================================
local Logger = {}
function Logger.log(cat, msg, level)
    table.insert(Core.logs, {timestamp=os.clock()-Core.sessionStart, category=cat or "Core", message=msg or "", level=level or "INFO"})
    if Core.debugMode then pcall(print, string.format("[KURAI][%s] %s", cat, msg)) end
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
local Config = { current = {}, defaults = {
    startupAnimation     = true,
    animationSpeed       = 1.0,
    theme                = "Dark",
    uiTransparency       = 0.05,
    uiScale              = 1.0,
    performanceMode      = false,
    debugMode            = false,
    -- ESP
    espEnabled           = false,
    espRange             = 500,
    espThickness         = 1,
    espBoxEnabled        = false,
    espNameEnabled       = false,
    espDistEnabled       = false,
    espHealthEnabled     = false,
    espTracerEnabled     = false,
    espSkeletonEnabled   = false,
    espChamsEnabled      = false,
    espRainbowEnabled    = false,
    espTeamCheck         = false,
    -- Combat
    aimbotEnabled        = false,
    silentAimEnabled     = false,
    camLockEnabled       = false,
    aimFOV               = 150,
    aimSmoothing         = 0.5,
    aimPart              = "Head",
    autoShootEnabled     = false,
    autoStabEnabled      = false,
    hitboxEnabled        = false,
    hitboxSize           = 5,
    reachEnabled         = false,
    reachDistance        = 15,
    autoFlingEnabled     = false,
    -- Movement
    speedEnabled         = false,
    walkSpeed            = 16,
    jumpPower            = 50,
    flyEnabled           = false,
    flySpeed             = 50,
    noclipEnabled        = false,
    infJumpEnabled       = false,
    bunnyHopEnabled      = false,
    gravityEnabled       = false,
    gravityValue         = 196.2,
    -- Farm
    autoCollectEnabled   = false,
    autoCollectRange     = 20,
    coinFarmEnabled      = false,
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
        pcall(function() writefile("kurai_config.json", _HttpSvc:JSONEncode(Config.current)) end)
    end
end
function Config.reset() Config.current = {}; for k,v in pairs(Config.defaults) do Config.current[k]=v end; Config.save() end
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
    CleanupManager.register("Performance", function() conn:Disconnect(); Performance.running = false end)
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
-- NOTIFICATION MANAGER
-- ============================================================
local NotificationManager = { queue={}, history={} }
function NotificationManager.send(title, message, ntype, duration)
    local n = { title=title or "Kurai", message=message or "", type=ntype or "INFO", duration=duration or 3, timestamp=os.clock() }
    table.insert(NotificationManager.queue, n)
    table.insert(NotificationManager.history, n)
    if _StarterGui then
        pcall(function()
            _StarterGui:SetCore("SendNotification", {Title=n.title, Text=n.message, Duration=n.duration})
        end)
    end
    Logger.log("Notif", n.title.." — "..n.message)
end

-- ============================================================
-- FEATURE MANAGER
-- ============================================================
local FeatureManager = { registry={} }
local function makeFeature(id, name, cat, desc)
    return { id=id, name=name, category=cat, description=desc, enabled=false, status="IDLE",
             settings={}, keybind=nil, dependencies={}, supportedPlatforms={"Windows","Android","iOS","macOS"}, cleanupHandler=nil }
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
        {"esp_player","Player ESP","ESP","Highlight all players"},
        {"esp_murderer","Murderer ESP","ESP","Highlight murderers"},
        {"esp_sheriff","Sheriff ESP","ESP","Highlight sheriffs"},
        {"esp_name","Name ESP","ESP","Show player names"},
        {"esp_distance","Distance ESP","ESP","Show distance to players"},
        {"esp_health","Health ESP","ESP","Show player health bars"},
        {"esp_box","Box ESP","ESP","Draw boxes around players"},
        {"esp_skeleton","Skeleton ESP","ESP","Draw player skeletons"},
        {"esp_tracer","Tracer ESP","ESP","Draw tracer lines"},
        {"esp_chams","Chams","ESP","Color players through walls"},
        {"esp_rainbow","Rainbow ESP","ESP","Rainbow color cycling ESP"},
        {"esp_coin","Coin ESP","ESP","Highlight coins"},
        {"esp_item","Item ESP","ESP","Highlight all items"},
        {"combat_aimbot","Aimbot","Combat","Full aimbot assistance"},
        {"combat_silentaim","Silent Aim","Combat","Silent aim assistance"},
        {"combat_camlock","Cam Lock","Combat","Camera locks to target"},
        {"combat_autoshoot","Auto Shoot","Combat","Automatically shoot"},
        {"combat_autostab","Auto Stab","Combat","Automatically stab"},
        {"combat_hitbox","Hitbox Expander","Combat","Expand target hitboxes"},
        {"combat_reach","Reach","Combat","Extended melee reach"},
        {"combat_autofling","Auto Fling","Combat","Automatically fling targets"},
        {"move_speed","Speed","Movement","Increase walk speed"},
        {"move_infjump","Infinite Jump","Movement","Jump infinitely in air"},
        {"move_fly","Fly","Movement","Enable flight"},
        {"move_noclip","Noclip","Movement","Phase through walls"},
        {"move_gravity","Gravity Control","Movement","Modify gravity"},
        {"move_bunnyhop","Bunny Hop","Movement","Automatic bunny hop"},
        {"farm_autocollect","Auto Collect","Farm","Automatically collect coins"},
        {"farm_coin_farm","Coin Farm","Farm","Farm coins automatically"},
        {"intel_role_detect","Role Detector","Intelligence","Detect player roles"},
        {"intel_murderer_detect","Murderer Detector","Intelligence","Identify murderer"},
        {"misc_fps_monitor","FPS Monitor","Misc","Display FPS counter"},
        {"misc_debug","Debug Mode","Misc","Show debug information"},
        {"visual_crosshair","Crosshair","Visual","Custom crosshair overlay"},
    }
    for _, f in ipairs(list) do FeatureManager.register(makeFeature(f[1],f[2],f[3],f[4])) end
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
-- TARGET MANAGER
-- ============================================================
local TargetManager = {
    whitelist={}, blacklist={}, locked=nil,
    filters={ ignoreDead=true, maxDistance=500, roleFilter="All" }
}
function TargetManager.getNearest(origin, fov)
    local nearest, bestScore = nil, math.huge
    if not _Players then return nil end
    local lp = getLocalPlayer()
    local cam = getCamera()
    fov = fov or Config.get("aimFOV") or 150
    for _, p in ipairs(_Players:GetPlayers()) do
        if p ~= lp and not TargetManager.blacklist[p.Name] then
            local char = p.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    local d = (hrp.Position - origin).Magnitude
                    if d <= TargetManager.filters.maxDistance then
                        -- FOV check
                        if cam then
                            local sp, _, onScreen = worldToViewport(hrp.Position)
                            if onScreen and sp then
                                local center = cam.ViewportSize / 2
                                local dist2d = (sp - center).Magnitude
                                if dist2d <= fov then
                                    if dist2d < bestScore then
                                        bestScore = dist2d
                                        nearest = p
                                    end
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
    if p then NotificationManager.send("Target","Locked: "..p.Name,"INFO",2) end
end
function TargetManager.unlock() TargetManager.locked = nil end
function TargetManager.addToWhitelist(n) TargetManager.whitelist[n]=true end
function TargetManager.addToBlacklist(n) TargetManager.blacklist[n]=true end

-- ============================================================
-- SERVER INFO
-- ============================================================
local ServerInfo = { jobId="", playerCount=0, maxPlayers=0 }
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
-- PANIC BUTTON
-- ============================================================
local PanicButton = {}
function PanicButton.activate()
    Core.panicMode = true
    FeatureManager.disableAll()
    for _, c in ipairs(Core.connections) do pcall(function() c:Disconnect() end) end
    Core.connections = {}
    CleanupManager.runAll()
    -- restore workspace gravity
    pcall(function() _WS.Gravity = 196.2 end)
    NotificationManager.send("KURAI","ALL FEATURES DISABLED","PANIC",5)
    Logger.log("Panic","PANIC ACTIVATED")
    -- re-allow re-init
    Core.panicMode = false
end

-- ============================================================
-- ESP SYSTEM (Drawing API)
-- ============================================================
local ESP = {
    objects = {},  -- [player] = { box, name, health, tracer, skeleton lines... }
    enabled = false,
    rainbowHue = 0,
}

local function hasDrawing()
    return rawget(_G, "Drawing") ~= nil
end

local function newDrawing(type_, props)
    if not hasDrawing() then return nil end
    local ok, obj = pcall(Drawing.new, type_)
    if not ok then return nil end
    for k, v in pairs(props or {}) do pcall(function() obj[k] = v end) end
    return obj
end

local function removeDrawing(obj)
    if obj then pcall(function() obj:Remove() end) end
end

local function getESPColor(player)
    if Config.get("espRainbowEnabled") then
        return Color3.fromHSV(ESP.rainbowHue, 1, 1)
    end
    -- role-based colors
    local name = player and player.Name or ""
    -- Check if murderer/sheriff via tag or tool
    if player and player.Character then
        local char = player.Character
        -- Murderer: has knife but no gun (simplified detection)
        local hasKnife = char:FindFirstChild("Knife") or char:FindFirstChildOfClass("Tool") and char:FindFirstChildOfClass("Tool").Name:lower():find("knife")
        local hasGun   = char:FindFirstChild("Sheriff") or char:FindFirstChildOfClass("Tool") and char:FindFirstChildOfClass("Tool").Name:lower():find("gun")
        if hasKnife and not hasGun then return Color3.fromRGB(255,60,60) end
        if hasGun               then return Color3.fromRGB(60,160,255) end
    end
    return Color3.fromRGB(255,255,255)
end

local function getCharacterBounds(char)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    -- Calculate bounding box from parts
    local minY, maxY = math.huge, -math.huge
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            local top    = part.Position.Y + part.Size.Y/2
            local bottom = part.Position.Y - part.Size.Y/2
            if top    > maxY then maxY = top end
            if bottom < minY then minY = bottom end
        end
    end
    return hrp.Position, maxY - minY
end

function ESP.createForPlayer(player)
    if ESP.objects[player] then return end
    local obj = {}

    if hasDrawing() then
        -- Box
        obj.box = newDrawing("Square", {
            Visible=false, Color=Color3.fromRGB(255,255,255),
            Thickness=1, Filled=false, Transparency=1
        })
        -- Name
        obj.name = newDrawing("Text", {
            Visible=false, Color=Color3.fromRGB(255,255,255),
            Size=14, Center=true, Outline=true,
            OutlineColor=Color3.fromRGB(0,0,0)
        })
        -- Health bar background
        obj.healthBg = newDrawing("Square", {
            Visible=false, Color=Color3.fromRGB(0,0,0),
            Thickness=1, Filled=true, Transparency=0.5
        })
        -- Health bar fill
        obj.healthBar = newDrawing("Square", {
            Visible=false, Color=Color3.fromRGB(80,200,80),
            Thickness=1, Filled=true, Transparency=1
        })
        -- Tracer
        obj.tracer = newDrawing("Line", {
            Visible=false, Color=Color3.fromRGB(255,255,255),
            Thickness=1, Transparency=1
        })
        -- Distance text
        obj.distance = newDrawing("Text", {
            Visible=false, Color=Color3.fromRGB(200,200,200),
            Size=11, Center=true, Outline=true,
            OutlineColor=Color3.fromRGB(0,0,0)
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

function ESP.update()
    if not _Players then return end
    local lp = getLocalPlayer()
    ESP.rainbowHue = (ESP.rainbowHue + 0.003) % 1

    for _, player in ipairs(_Players:GetPlayers()) do
        if player ~= lp then
            local obj = ESP.objects[player]
            if not obj then
                ESP.createForPlayer(player)
                obj = ESP.objects[player]
            end

            local espOn = Config.get("espEnabled")
            local char  = player.Character
            local hrp   = char and char:FindFirstChild("HumanoidRootPart")
            local hum   = char and char:FindFirstChildOfClass("Humanoid")

            if not espOn or not char or not hrp or not hum or not hasDrawing() then
                -- hide all
                if obj then
                    for _, v in pairs(obj) do
                        if v then pcall(function() v.Visible = false end) end
                    end
                end
            else
                local hrpPos        = hrp.Position
                local _, charHeight = getCharacterBounds(char)
                charHeight          = charHeight or 5.5
                local sp, depth, onScreen = worldToViewport(hrpPos)

                if not onScreen or not sp or depth <= 0 then
                    for _, v in pairs(obj) do
                        if v then pcall(function() v.Visible = false end) end
                    end
                else
                    local cam       = getCamera()
                    local vpSize    = cam and cam.ViewportSize or Vector2.new(1920,1080)
                    local scaleFactor = 1 / depth
                    local boxH      = math.clamp(charHeight * 500 * scaleFactor, 30, 400)
                    local boxW      = boxH * 0.5
                    local topLeft   = Vector2.new(sp.X - boxW/2, sp.Y - boxH/2)
                    local espColor  = getESPColor(player)
                    local hp        = hum.Health
                    local maxHp     = hum.MaxHealth
                    local hpRatio   = maxHp > 0 and math.clamp(hp/maxHp, 0, 1) or 0
                    local dist      = (hrpPos - (getHRP() and getHRP().Position or hrpPos)).Magnitude

                    -- Visibility check (range)
                    if dist > Config.get("espRange") then
                        for _, v in pairs(obj) do if v then pcall(function() v.Visible = false end) end end
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
                            obj.name.Position = Vector2.new(sp.X, topLeft.Y - 16)
                            obj.name.Text     = player.Name
                            obj.name.Color    = espColor
                        end

                        -- Distance
                        if obj.distance then
                            obj.distance.Visible  = Config.get("espDistEnabled")
                            obj.distance.Position = Vector2.new(sp.X, topLeft.Y + boxH + 2)
                            obj.distance.Text     = string.format("[%dm]", math.floor(dist))
                            obj.distance.Color    = Color3.fromRGB(200,200,200)
                        end

                        -- Health bar
                        if obj.healthBg and obj.healthBar then
                            local showHealth = Config.get("espHealthEnabled")
                            obj.healthBg.Visible  = showHealth
                            obj.healthBar.Visible = showHealth
                            if showHealth then
                                local barX  = topLeft.X - 6
                                local barH  = boxH
                                local fillH = barH * hpRatio
                                local hpCol = Color3.fromRGB(
                                    math.floor(255*(1-hpRatio)),
                                    math.floor(255*hpRatio),
                                    0
                                )
                                obj.healthBg.Position = Vector2.new(barX, topLeft.Y)
                                obj.healthBg.Size     = Vector2.new(3, barH)
                                obj.healthBar.Position= Vector2.new(barX, topLeft.Y + barH - fillH)
                                obj.healthBar.Size    = Vector2.new(3, fillH)
                                obj.healthBar.Color   = hpCol
                            end
                        end

                        -- Tracer
                        if obj.tracer then
                            obj.tracer.Visible = Config.get("espTracerEnabled")
                            if Config.get("espTracerEnabled") then
                                obj.tracer.From  = Vector2.new(vpSize.X/2, vpSize.Y)
                                obj.tracer.To    = sp
                                obj.tracer.Color = espColor
                            end
                        end
                    end
                end
            end
        end
    end

    -- remove objects for players who left
    local currentPlayers = {}
    if _Players then
        for _, p in ipairs(_Players:GetPlayers()) do currentPlayers[p] = true end
    end
    for p, _ in pairs(ESP.objects) do
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
        for p, _ in pairs(ESP.objects) do ESP.removeForPlayer(p) end
        ESP.objects = {}
    end)
end

function ESP.cleanup()
    for p, _ in pairs(ESP.objects) do ESP.removeForPlayer(p) end
    ESP.objects = {}
end

-- ============================================================
-- CHAMS SYSTEM (highlight parts)
-- ============================================================
local Chams = { selections = {} }

local function applyChams(player, color)
    if not player or not player.Character then return end
    local sel = {}
    for _, part in ipairs(player.Character:GetDescendants()) do
        if part:IsA("BasePart") then
            local ok, box = pcall(function()
                local b = Instance.new("SelectionBox")
                b.Adornee     = part
                b.Color3      = color or Color3.fromRGB(255,60,60)
                b.LineThickness = 0.01
                b.SurfaceColor3 = color or Color3.fromRGB(255,60,60)
                b.SurfaceTransparency = 0.5
                b.Parent      = part
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
                if not Chams.selections[p] then
                    applyChams(p, getESPColor(p))
                end
            else
                removeChams(p)
            end
        end
    end
    local current = {}
    if _Players then for _, p in ipairs(_Players:GetPlayers()) do current[p]=true end end
    for p in pairs(Chams.selections) do
        if not current[p] then removeChams(p) end
    end
end

function Chams.startLoop()
    if not _RunSvc then return end
    local conn = safeConnect(_RunSvc.Heartbeat, function()
        if Core.panicMode then return end
        pcall(Chams.update)
    end)
    table.insert(Core.connections, conn)
    CleanupManager.register("Chams", function()
        conn:Disconnect()
        for p in pairs(Chams.selections) do removeChams(p) end
    end)
end

-- ============================================================
-- AIMBOT / SILENT AIM / CAM LOCK
-- ============================================================
local AimSystem = {
    fovCircle = nil,
    lastTarget = nil,
}

local function getAimTarget()
    local hrp = getHRP()
    if not hrp then return nil end
    return TargetManager.getNearest(hrp.Position, Config.get("aimFOV"))
end

local function getTargetPart(player)
    if not player or not player.Character then return nil end
    local partName = Config.get("aimPart") or "Head"
    return player.Character:FindFirstChild(partName) or player.Character:FindFirstChild("HumanoidRootPart")
end

-- Aimbot: moves camera toward target
function AimSystem.updateAimbot()
    if not Config.get("aimbotEnabled") then return end
    if not _UIS then return end
    -- only aim when right mouse held (or always, depending on preference)
    local rmb = false
    pcall(function() rmb = _UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) end)
    if not rmb then return end

    local target = getAimTarget()
    if not target then return end
    local part = getTargetPart(target)
    if not part then return end

    local cam = getCamera()
    if not cam then return end

    local smoothing = Config.get("aimSmoothing") or 0.5
    local targetCF  = CFrame.new(cam.CFrame.Position, part.Position)
    cam.CFrame       = cam.CFrame:Lerp(targetCF, 1 - smoothing)
end

-- Silent Aim: makes projectiles hit target part
-- Works by hooking the camera lookVector on shoot events
local silentAimEnabled = false
local _origMouseHit    = nil

function AimSystem.enableSilentAim()
    if silentAimEnabled then return end
    silentAimEnabled = true
    -- Hook via mouse.Hit override (executor-level)
    local lp = getLocalPlayer()
    if not lp then return end
    local mouse = lp:GetMouse()
    if not mouse then return end

    -- We override the mouse.Hit property via a metatable on the player mouse
    -- This makes the game think you're aiming at the target
    local mt = getrawmetatable and getrawmetatable(mouse)
    if mt then
        local oldIndex = mt.__index
        local ok, _ = pcall(function()
            setreadonly(mt, false)
            mt.__index = function(self, k)
                if k == "Hit" then
                    local target = getAimTarget()
                    if target then
                        local part = getTargetPart(target)
                        if part then return CFrame.new(part.Position) end
                    end
                end
                if type(oldIndex) == "function" then return oldIndex(self, k)
                else return rawget(mt, k) end
            end
            setreadonly(mt, true)
        end)
        if ok then
            CleanupManager.register("SilentAim", function()
                pcall(function()
                    setreadonly(mt, false)
                    mt.__index = oldIndex
                    setreadonly(mt, true)
                end)
                silentAimEnabled = false
            end)
        else
            -- Fallback: no metatable access — use camera CFrame trick
            Logger.log("SilentAim","metatable unavailable, using cam trick")
            silentAimEnabled = false
        end
    end
end

function AimSystem.disableSilentAim()
    CleanupManager.run("SilentAim")
    silentAimEnabled = false
end

-- Cam Lock: hard lock camera to target each frame
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

-- FOV Circle
function AimSystem.updateFOVCircle()
    if not hasDrawing() then return end
    if not AimSystem.fovCircle then
        AimSystem.fovCircle = newDrawing("Circle", {
            Visible=false, Color=Color3.fromRGB(255,255,255),
            Thickness=1, Filled=false, Transparency=1, NumSides=64
        })
    end
    local showFOV  = Config.get("aimbotEnabled") or Config.get("silentAimEnabled") or Config.get("camLockEnabled")
    local cam      = getCamera()
    if showFOV and cam then
        AimSystem.fovCircle.Visible  = true
        AimSystem.fovCircle.Position = cam.ViewportSize / 2
        AimSystem.fovCircle.Radius   = Config.get("aimFOV") or 150
    else
        AimSystem.fovCircle.Visible = false
    end
end

function AimSystem.startLoop()
    if not _RunSvc then return end
    local conn = safeConnect(_RunSvc.RenderStepped, function()
        if Core.panicMode then return end
        pcall(AimSystem.updateAimbot)
        pcall(AimSystem.updateCamLock)
        pcall(AimSystem.updateFOVCircle)
    end)
    table.insert(Core.connections, conn)
    CleanupManager.register("AimSystem", function()
        conn:Disconnect()
        if AimSystem.fovCircle then removeDrawing(AimSystem.fovCircle); AimSystem.fovCircle = nil end
        AimSystem.disableSilentAim()
    end)
end

-- ============================================================
-- MOVEMENT SYSTEM
-- ============================================================
local MovementSystem = {}

-- Speed
function MovementSystem.updateSpeed()
    local hum = getHum()
    if not hum then return end
    if Config.get("speedEnabled") then
        hum.WalkSpeed  = Config.get("walkSpeed") or 16
        hum.JumpPower  = Config.get("jumpPower") or 50
    else
        if hum.WalkSpeed ~= 16 and not Config.get("flyEnabled") then
            hum.WalkSpeed = 16
        end
        if hum.JumpPower ~= 50 then hum.JumpPower = 50 end
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
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
    table.insert(Core.connections, infJumpConn)
    CleanupManager.register("InfJump", function()
        if infJumpConn then infJumpConn:Disconnect(); infJumpConn = nil end
    end)
end

-- Fly
local flyActive   = false
local flyBodyVel  = nil
local flyBodyGyro = nil
local flyConn     = nil
local FLY_SPEED   = 50

function MovementSystem.startFly()
    if flyActive then return end
    flyActive = true
    local hrp = getHRP()
    if not hrp then flyActive = false; return end

    flyBodyVel = Instance.new("BodyVelocity")
    flyBodyVel.MaxForce   = Vector3.new(1e5,1e5,1e5)
    flyBodyVel.Velocity   = Vector3.new(0,0,0)
    flyBodyVel.Parent     = hrp

    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.MaxTorque = Vector3.new(1e5,1e5,1e5)
    flyBodyGyro.D         = 100
    flyBodyGyro.Parent    = hrp

    local hum = getHum()
    if hum then hum.PlatformStand = true end

    flyConn = safeConnect(_RunSvc.Heartbeat, function()
        if not Config.get("flyEnabled") or Core.panicMode then
            MovementSystem.stopFly(); return
        end
        local cam     = getCamera()
        local speed   = Config.get("flySpeed") or FLY_SPEED
        local direction = Vector3.new(0,0,0)

        if _UIS then
            if _UIS:IsKeyDown(Enum.KeyCode.W) then direction = direction + cam.CFrame.LookVector end
            if _UIS:IsKeyDown(Enum.KeyCode.S) then direction = direction - cam.CFrame.LookVector end
            if _UIS:IsKeyDown(Enum.KeyCode.A) then direction = direction - cam.CFrame.RightVector end
            if _UIS:IsKeyDown(Enum.KeyCode.D) then direction = direction + cam.CFrame.RightVector end
            if _UIS:IsKeyDown(Enum.KeyCode.Space) then direction = direction + Vector3.new(0,1,0) end
            if _UIS:IsKeyDown(Enum.KeyCode.LeftControl) then direction = direction - Vector3.new(0,1,0) end
        end

        if flyBodyVel then
            flyBodyVel.Velocity   = direction.Magnitude > 0 and direction.Unit * speed or Vector3.new(0,0,0)
        end
        if flyBodyGyro and cam then
            flyBodyGyro.CFrame = cam.CFrame
        end
    end)
    table.insert(Core.connections, flyConn)
end

function MovementSystem.stopFly()
    flyActive = false
    if flyBodyVel  then flyBodyVel:Destroy();  flyBodyVel = nil end
    if flyBodyGyro then flyBodyGyro:Destroy(); flyBodyGyro = nil end
    if flyConn     then flyConn:Disconnect();  flyConn = nil end
    local hum = getHum()
    if hum then hum.PlatformStand = false end
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
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
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
        _WS.Gravity = Config.get("gravityValue") or 196.2
    else
        _WS.Gravity = 196.2
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
local hitboxParts = {} -- [BasePart] = originalSize

function HitboxSystem.expand()
    if not _Players then return end
    local lp = getLocalPlayer()
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
-- REACH / AUTO STAB
-- ============================================================
local CombatSystem = {}

function CombatSystem.updateReach()
    if not Config.get("reachEnabled") then return end
    local char = getChar()
    if not char then return end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            local handle = tool:FindFirstChild("Handle")
            if handle then
                pcall(function()
                    if not handle:FindFirstChild("KuraiReach") then
                        local weld = Instance.new("WeldConstraint")
                        weld.Name    = "KuraiReach"
                        weld.Part0   = handle
                        weld.Part1   = handle
                        weld.Parent  = handle
                    end
                    handle.Size = Vector3.new(
                        Config.get("reachDistance") or 15,
                        handle.Size.Y,
                        handle.Size.Z
                    )
                end)
            end
        end
    end
end

function CombatSystem.autoStab()
    if not Config.get("autoStabEnabled") then return end
    local target = getAimTarget()
    if not target or not target.Character then return end
    local hrp = getHRP()
    if not hrp then return end
    local targetHRP = target.Character:FindFirstChild("HumanoidRootPart")
    if not targetHRP then return end
    local dist = (hrp.Position - targetHRP.Position).Magnitude
    if dist > (Config.get("reachDistance") or 15) + 5 then return end

    -- simulate stab by firing tool
    local char = getChar()
    if not char then return end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            local activateEvent = tool:FindFirstChild("Activated") or tool:FindFirstChildOfClass("RemoteEvent")
            if activateEvent then
                pcall(function() activateEvent:FireServer(targetHRP.Position) end)
            end
        end
    end
end

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

    -- fling by applying velocity
    pcall(function()
        local vel = Instance.new("BodyVelocity")
        vel.MaxForce = Vector3.new(1e6,1e6,1e6)
        vel.Velocity  = (targetHRP.Position - hrp.Position).Unit * 300 + Vector3.new(0,100,0)
        vel.Parent    = targetHRP
        game:GetService("Debris"):AddItem(vel, 0.1)
    end)
end

function CombatSystem.startLoop()
    if not _RunSvc then return end
    local conn = safeConnect(_RunSvc.Heartbeat, function()
        if Core.panicMode then return end
        pcall(CombatSystem.updateReach)
        pcall(CombatSystem.autoStab)
        pcall(CombatSystem.autoFling)
    end)
    table.insert(Core.connections, conn)
    CleanupManager.register("CombatSystem", function() conn:Disconnect() end)
end

-- ============================================================
-- FARM SYSTEM
-- ============================================================
local FarmSystem = { coinsThisSession=0, lastCollect=0 }

-- Find coins/collectibles in workspace
local function findCoins()
    local coins = {}
    if not _WS then return coins end
    for _, obj in ipairs(_WS:GetDescendants()) do
        -- MM2 coins are usually tagged or named "Coin", "coin"
        if obj.Name:lower():find("coin") and obj:IsA("BasePart") then
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
    local now = tick()
    if now - FarmSystem.lastCollect < 0.2 then return end
    FarmSystem.lastCollect = now

    local coins = findCoins()
    for _, coin in ipairs(coins) do
        if coin and coin.Parent then
            local dist = (coin.Position - hrp.Position).Magnitude
            if dist <= range then
                -- TP to coin to collect (or fire remote)
                pcall(function()
                    local lp = getLocalPlayer()
                    if lp and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                        lp.Character.HumanoidRootPart.CFrame = coin.CFrame
                    end
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

    -- Teleport to nearest coin
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
            if lp and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") then
                lp.Character.HumanoidRootPart.CFrame = nearest.CFrame
            end
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
-- INTELLIGENCE SYSTEM (MM2 Role Detection)
-- ============================================================
local IntelSystem = {
    roles        = {},  -- [playerName] = "Murderer" | "Sheriff" | "Innocent"
    roundActive  = false,
    aliveCount   = 0,
}

local function detectMM2Roles()
    if not _Players then return end
    local lp = getLocalPlayer()
    for _, p in ipairs(_Players:GetPlayers()) do
        if p ~= lp and p.Character then
            local char    = p.Character
            local hasKnife = false
            local hasGun   = false
            for _, tool in ipairs(char:GetChildren()) do
                if tool:IsA("Tool") then
                    local n = tool.Name:lower()
                    if n:find("knife") then hasKnife = true end
                    if n:find("gun") or n:find("sheriff") then hasGun = true end
                end
            end
            -- Also check tools in backpack (not equipped)
            if p:FindFirstChild("Backpack") then
                for _, tool in ipairs(p.Backpack:GetChildren()) do
                    if tool:IsA("Tool") then
                        local n = tool.Name:lower()
                        if n:find("knife") then hasKnife = true end
                        if n:find("gun") or n:find("sheriff") then hasGun = true end
                    end
                end
            end

            if hasKnife and not hasGun then
                IntelSystem.roles[p.Name] = "Murderer"
            elseif hasGun then
                IntelSystem.roles[p.Name] = "Sheriff"
            else
                IntelSystem.roles[p.Name] = "Innocent"
            end
        end
    end
end

function IntelSystem.startLoop()
    if not _RunSvc then return end
    local conn = safeConnect(_RunSvc.Heartbeat, function()
        if Core.panicMode then return end
        if Config.get("espEnabled") then
            pcall(detectMM2Roles)
        end
        -- Count alive players
        if _Players then
            local alive = 0
            for _, p in ipairs(_Players:GetPlayers()) do
                if p.Character and p.Character:FindFirstChildOfClass("Humanoid") then
                    local hum = p.Character:FindFirstChildOfClass("Humanoid")
                    if hum.Health > 0 then alive = alive + 1 end
                end
            end
            IntelSystem.aliveCount = alive
        end
    end)
    table.insert(Core.connections, conn)
    CleanupManager.register("IntelSystem", function() conn:Disconnect() end)
end

-- ============================================================
-- CROSSHAIR
-- ============================================================
local CrosshairSystem = {}
local crosshairLines = {}

function CrosshairSystem.create()
    if not hasDrawing() then return end
    if next(crosshairLines) then return end
    local cam = getCamera()
    local center = cam and (cam.ViewportSize / 2) or Vector2.new(960, 540)
    local size = 8

    crosshairLines.left  = newDrawing("Line", {Visible=false, Color=Color3.fromRGB(255,255,255), Thickness=1, Transparency=1})
    crosshairLines.right = newDrawing("Line", {Visible=false, Color=Color3.fromRGB(255,255,255), Thickness=1, Transparency=1})
    crosshairLines.up    = newDrawing("Line", {Visible=false, Color=Color3.fromRGB(255,255,255), Thickness=1, Transparency=1})
    crosshairLines.down  = newDrawing("Line", {Visible=false, Color=Color3.fromRGB(255,255,255), Thickness=1, Transparency=1})
    -- center dot
    crosshairLines.dot   = newDrawing("Circle", {Visible=false, Color=Color3.fromRGB(255,255,255), Thickness=1, Filled=true, Radius=2, NumSides=8, Transparency=1})
end

function CrosshairSystem.update()
    local cam    = getCamera()
    local show   = Config.get("espEnabled") or false -- crosshair visible with esp or always
    -- always show if visual_crosshair is enabled config
    if not next(crosshairLines) then CrosshairSystem.create() end
    local center = cam and (cam.ViewportSize / 2) or Vector2.new(960, 540)
    local size   = 8
    local gap    = 3

    for _, line in pairs(crosshairLines) do
        if line then pcall(function() line.Visible = false end) end
    end

    -- Only show if crosshair feature explicitly on via config key
end

function CrosshairSystem.setVisible(v)
    if not next(crosshairLines) then CrosshairSystem.create() end
    local cam    = getCamera()
    local center = cam and (cam.ViewportSize / 2) or Vector2.new(960, 540)
    local size   = 8
    local gap    = 3

    if crosshairLines.left  then crosshairLines.left.Visible  = v; crosshairLines.left.From  = Vector2.new(center.X - size, center.Y); crosshairLines.left.To   = Vector2.new(center.X - gap, center.Y) end
    if crosshairLines.right then crosshairLines.right.Visible = v; crosshairLines.right.From = Vector2.new(center.X + gap, center.Y); crosshairLines.right.To  = Vector2.new(center.X + size, center.Y) end
    if crosshairLines.up    then crosshairLines.up.Visible    = v; crosshairLines.up.From    = Vector2.new(center.X, center.Y - size); crosshairLines.up.To     = Vector2.new(center.X, center.Y - gap) end
    if crosshairLines.down  then crosshairLines.down.Visible  = v; crosshairLines.down.From  = Vector2.new(center.X, center.Y + gap);  crosshairLines.down.To   = Vector2.new(center.X, center.Y + size) end
    if crosshairLines.dot   then crosshairLines.dot.Visible   = v; crosshairLines.dot.Position = center end
end

function CrosshairSystem.cleanup()
    for _, line in pairs(crosshairLines) do removeDrawing(line) end
    crosshairLines = {}
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

function UI.buildStartupScreen()
    local theme   = ThemeManager.get()
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

    local function waitT(t)
        local s = tick()
        while tick()-s < t*speed do
            if skipped then return end
            task.wait(0.016)
        end
    end

    local function status(txt, pct)
        if els.statusLbl then els.statusLbl.Text = txt end
        if els.progressFill then safeTween(els.progressFill,"Size",UDim2.new(pct,0,1,0),0.3*speed) end
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
        {"Ready.",                   1.0 },
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
-- MOBILE TOGGLE BUTTON (drag + tap)
-- ============================================================
function UI.buildMobileToggleButton()
    local theme = ThemeManager.get()
    -- Floating button to show/hide dashboard on mobile
    local btn = newInst("TextButton", UI.gui, {
        Name="KuraiToggleBtn",
        Size=UDim2.fromOffset(50,50),
        Position=UDim2.new(0,10,0.5,-25),
        BackgroundColor3=theme.accent,
        Text="K",
        Font=Enum.Font.GothamBold,
        TextSize=20,
        TextColor3=Color3.fromRGB(255,255,255),
        BorderSizePixel=0,
        ZIndex=200,
    })
    newInst("UICorner", btn, {CornerRadius=UDim.new(1,0)})
    newInst("UIStroke", btn, {Color=Color3.fromRGB(255,255,255), Thickness=1, Transparency=0.7})

    -- Drag logic
    local dragging = false
    local dragStartPos
    local btnStartPos
    local moved = false

    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging     = true
            dragStartPos = input.Position
            btnStartPos  = btn.Position
            moved        = false
        end
    end)

    btn.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - dragStartPos
            if math.abs(delta.X) > 5 or math.abs(delta.Y) > 5 then moved = true end
            local cam = getCamera()
            local vpSize = cam and cam.ViewportSize or Vector2.new(1920,1080)
            local newX = math.clamp(btnStartPos.X.Offset + delta.X, 0, vpSize.X - 55)
            local newY = math.clamp(btnStartPos.Y.Scale * vpSize.Y + btnStartPos.Y.Offset + delta.Y, 0, vpSize.Y - 55)
            btn.Position = UDim2.fromOffset(newX, newY)
        end
    end)

    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            if not moved then
                UI.toggleVisibility()
            end
            dragging = false
        end
    end)

    UI.toggleButton = btn
end

-- ============================================================
-- DASHBOARD BUILDER
-- ============================================================
function UI.buildDashboard()
    local theme = ThemeManager.get()

    local shadow = newInst("ImageLabel", UI.gui, {
        Name="Shadow", Size=UDim2.new(0.9,0,0.87,0), Position=UDim2.new(0.05,0,0.075,8),
        BackgroundTransparency=1, Image="rbxassetid://7912134082",
        ImageColor3=Color3.fromRGB(0,0,0), ImageTransparency=0.6, ZIndex=9, Visible=false,
    })
    UI.shadowFrame = shadow

    local dash = newInst("Frame", UI.gui, {
        Name="Dashboard", Size=UDim2.new(0.88,0,0.85,0), Position=UDim2.new(0.06,0,0.075,0),
        BackgroundColor3=theme.bg, BorderSizePixel=0, BackgroundTransparency=0.02,
        Visible=false, ZIndex=10,
    })
    newInst("UICorner", dash, {CornerRadius=UDim.new(0,14)})
    newInst("UIStroke", dash, {Color=theme.border, Thickness=1, Transparency=0.5})
    UI.dashboardFrame = dash

    -- gradient bg
    newInst("UIGradient", dash, {
        Color=ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(16,14,26)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(10,8,18)),
        }), Rotation=135,
    })

    -- Header bar
    local header = newInst("Frame", dash, {
        Name="Header", Size=UDim2.new(1,0,0,44), BackgroundColor3=theme.bgSecondary,
        BorderSizePixel=0, ZIndex=11,
    })
    newInst("UICorner", header, {CornerRadius=UDim.new(0,14)})
    newInst("Frame", header, {
        Size=UDim2.new(1,0,0.5,0), Position=UDim2.new(0,0,0.5,0),
        BackgroundColor3=theme.bgSecondary, BorderSizePixel=0, ZIndex=11,
    })

    -- Logo in header
    newInst("TextLabel", header, {
        Text="KURAI  SOFTWARE", Font=Enum.Font.GothamBold, TextSize=16,
        TextColor3=theme.text, BackgroundTransparency=1,
        Size=UDim2.new(0,200,1,0), Position=UDim2.new(0,14,0,0),
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=12,
    })
    -- Version badge
    newInst("TextLabel", header, {
        Text="v"..KURAI_VERSION, Font=Enum.Font.Gotham, TextSize=10,
        TextColor3=theme.accent, BackgroundTransparency=1,
        Size=UDim2.new(0,60,0,20), Position=UDim2.new(0,160,0,12),
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=12,
    })
    -- Close button
    local closeBtn = newInst("TextButton", header, {
        Text="✕", Font=Enum.Font.GothamBold, TextSize=14,
        TextColor3=theme.textDim, BackgroundTransparency=1,
        Size=UDim2.fromOffset(36,36), Position=UDim2.new(1,-38,0,4),
        ZIndex=12,
    })
    closeBtn.MouseButton1Click:Connect(function() UI.hide() end)

    -- Sidebar
    local sidebar = newInst("Frame", dash, {
        Name="Sidebar", Size=UDim2.new(0,130,1,-44), Position=UDim2.new(0,0,0,44),
        BackgroundColor3=theme.bgSecondary, BorderSizePixel=0, ZIndex=11,
    })
    newInst("UICorner", sidebar, {CornerRadius=UDim.new(0,12)})
    newInst("Frame", sidebar, {
        Size=UDim2.new(0.6,0,1,0), Position=UDim2.new(0.4,0,0,0),
        BackgroundColor3=theme.bgSecondary, BorderSizePixel=0, ZIndex=11,
    })
    UI.sidebarFrame = sidebar

    local sideList = newInst("UIListLayout", sidebar, {
        FillDirection=Enum.FillDirection.Vertical, HorizontalAlignment=Enum.HorizontalAlignment.Center,
        SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,2),
    })
    newInst("UIPadding", sidebar, {PaddingTop=UDim.new(0,8), PaddingBottom=UDim.new(0,8)})

    -- Content area
    local contentBg = newInst("Frame", dash, {
        Name="ContentBg", Size=UDim2.new(1,-138,1,-52), Position=UDim2.new(0,134,0,48),
        BackgroundTransparency=1, BorderSizePixel=0, ZIndex=11,
    })
    local content = newInst("ScrollingFrame", contentBg, {
        Name="Content", Size=UDim2.fromScale(1,1),
        BackgroundTransparency=1, BorderSizePixel=0,
        ScrollBarThickness=3, ScrollBarImageColor3=theme.accent,
        ScrollingDirection=Enum.ScrollingDirection.Y,
        CanvasSize=UDim2.new(0,0,0,0), ZIndex=11,
    })
    newInst("UIListLayout", content, {
        FillDirection=Enum.FillDirection.Vertical, HorizontalAlignment=Enum.HorizontalAlignment.Left,
        SortOrder=Enum.SortOrder.LayoutOrder, Padding=UDim.new(0,6),
    })
    newInst("UIPadding", content, {PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8),PaddingTop=UDim.new(0,8),PaddingBottom=UDim.new(0,8)})
    UI.contentFrame = content

    -- Tabs definition
    local tabs = {
        {"Dashboard", "🏠"},
        {"ESP",       "👁"},
        {"Combat",    "⚔"},
        {"Movement",  "🏃"},
        {"Farm",      "💰"},
        {"Intel",     "🔍"},
        {"Visual",    "🎨"},
        {"Settings",  "⚙"},
        {"Stats",     "📊"},
        {"Compat",    "✔"},
        {"Logs",      "📋"},
    }

    local tabButtons = {}
    for i, tab in ipairs(tabs) do
        local btn = newInst("TextButton", sidebar, {
            Name=tab[1].."Tab", Text=tab[2].." "..tab[1], Font=Enum.Font.GothamMedium,
            TextSize=11, TextColor3=theme.textDim, BackgroundTransparency=1,
            Size=UDim2.new(1,-8,0,30), BorderSizePixel=0, ZIndex=12,
            TextXAlignment=Enum.TextXAlignment.Left, LayoutOrder=i,
        })
        newInst("UIPadding", btn, {PaddingLeft=UDim.new(0,10)})
        tabButtons[tab[1]] = btn

        btn.MouseButton1Click:Connect(function()
            UI.activeTab = tab[1]
            for _, b in pairs(tabButtons) do
                pcall(function() b.TextColor3 = theme.textDim; b.BackgroundTransparency = 1 end)
            end
            btn.TextColor3 = theme.accent
            btn.BackgroundColor3 = theme.bgTertiary
            btn.BackgroundTransparency = 0
            UI.populateTab(tab[1])
        end)
    end

    UI.tabButtons = tabButtons
    UI.populateTab("Dashboard")
    tabButtons["Dashboard"].TextColor3 = theme.accent
    tabButtons["Dashboard"].BackgroundColor3 = theme.bgTertiary
    tabButtons["Dashboard"].BackgroundTransparency = 0
end

-- ============================================================
-- TAB CONTENT BUILDER
-- ============================================================
local function clearContent()
    if not UI.contentFrame then return end
    for _, child in ipairs(UI.contentFrame:GetChildren()) do
        if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
            child:Destroy()
        end
    end
    UI.contentFrame.CanvasSize = UDim2.new(0,0,0,0)
end

local function header(text)
    local theme = ThemeManager.get()
    newInst("TextLabel", UI.contentFrame, {
        Text=text, Font=Enum.Font.GothamBold, TextSize=16,
        TextColor3=theme.text, BackgroundTransparency=1,
        Size=UDim2.new(1,0,0,28), TextXAlignment=Enum.TextXAlignment.Left, ZIndex=12,
    })
end

local function secHead(text)
    local theme = ThemeManager.get()
    newInst("TextLabel", UI.contentFrame, {
        Text=text, Font=Enum.Font.GothamMedium, TextSize=11,
        TextColor3=theme.accent, BackgroundTransparency=1,
        Size=UDim2.new(1,0,0,20), TextXAlignment=Enum.TextXAlignment.Left, ZIndex=12,
    })
end

local function divider()
    local theme = ThemeManager.get()
    local div = newInst("Frame", UI.contentFrame, {
        BackgroundColor3=theme.border, BorderSizePixel=0,
        Size=UDim2.new(1,0,0,1), BackgroundTransparency=0.6, ZIndex=12,
    })
end

-- Toggle row: key = config key, label = display name
local function makeToggle(parent, key, label, onChange)
    local theme = ThemeManager.get()
    local row   = newInst("Frame", parent, {
        BackgroundColor3=theme.bgSecondary, BackgroundTransparency=0.4,
        Size=UDim2.new(1,0,0,36), BorderSizePixel=0, ZIndex=12,
    })
    newInst("UICorner", row, {CornerRadius=UDim.new(0,8)})

    newInst("TextLabel", row, {
        Text=label, Font=Enum.Font.Gotham, TextSize=12,
        TextColor3=theme.text, BackgroundTransparency=1,
        Size=UDim2.new(0.7,0,1,0), Position=UDim2.new(0,10,0,0),
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=13,
    })

    local togBg = newInst("Frame", row, {
        Size=UDim2.fromOffset(36,18), Position=UDim2.new(1,-46,0.5,-9),
        BackgroundColor3=Config.get(key) and theme.success or theme.border,
        BorderSizePixel=0, ZIndex=13,
    })
    newInst("UICorner", togBg, {CornerRadius=UDim.new(1,0)})

    local knob = newInst("Frame", togBg, {
        Size=UDim2.fromOffset(14,14), Position=UDim2.new(Config.get(key) and 1 or 0, Config.get(key) and -16 or 2, 0.5, -7),
        BackgroundColor3=Color3.fromRGB(255,255,255), BorderSizePixel=0, ZIndex=14,
    })
    newInst("UICorner", knob, {CornerRadius=UDim.new(1,0)})

    local togBtn = newInst("TextButton", row, {
        Text="", BackgroundTransparency=1,
        Size=UDim2.fromScale(1,1), ZIndex=15,
    })
    togBtn.MouseButton1Click:Connect(function()
        local newVal = not Config.get(key)
        Config.set(key, newVal)
        togBg.BackgroundColor3 = newVal and theme.success or theme.border
        safeTween(knob, "Position", UDim2.new(newVal and 1 or 0, newVal and -16 or 2, 0.5, -7), 0.15)
        if onChange then pcall(onChange, newVal) end
    end)
    return row
end

-- Slider row: key = config key
local function makeSlider(parent, key, label, minV, maxV, step)
    local theme = ThemeManager.get()
    step = step or 1
    local row = newInst("Frame", parent, {
        BackgroundColor3=theme.bgSecondary, BackgroundTransparency=0.4,
        Size=UDim2.new(1,0,0,50), BorderSizePixel=0, ZIndex=12,
    })
    newInst("UICorner", row, {CornerRadius=UDim.new(0,8)})

    local valLabel = newInst("TextLabel", row, {
        Text=label..": "..tostring(Config.get(key)), Font=Enum.Font.Gotham, TextSize=12,
        TextColor3=theme.text, BackgroundTransparency=1,
        Size=UDim2.new(1,-10,0,22), Position=UDim2.new(0,10,0,4),
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=13,
    })

    local trackBg = newInst("Frame", row, {
        Size=UDim2.new(1,-20,0,6), Position=UDim2.new(0,10,0,30),
        BackgroundColor3=theme.border, BorderSizePixel=0, ZIndex=13,
    })
    newInst("UICorner", trackBg, {CornerRadius=UDim.new(1,0)})

    local function valToX(v) return math.clamp((v - minV)/(maxV - minV), 0, 1) end
    local fillRatio = valToX(Config.get(key) or minV)

    local trackFill = newInst("Frame", trackBg, {
        Size=UDim2.new(fillRatio,0,1,0), BackgroundColor3=theme.accent,
        BorderSizePixel=0, ZIndex=14,
    })
    newInst("UICorner", trackFill, {CornerRadius=UDim.new(1,0)})

    local knob = newInst("Frame", trackBg, {
        Size=UDim2.fromOffset(12,12), Position=UDim2.new(fillRatio,  -6, 0.5, -6),
        BackgroundColor3=Color3.fromRGB(255,255,255), BorderSizePixel=0, ZIndex=15,
    })
    newInst("UICorner", knob, {CornerRadius=UDim.new(1,0)})

    -- drag
    local dragging = false
    local function update(x)
        local absX = trackBg.AbsolutePosition.X
        local absW = trackBg.AbsoluteSize.X
        local ratio = math.clamp((x - absX)/absW, 0, 1)
        local rawVal = minV + ratio*(maxV-minV)
        local snapped = math.floor(rawVal/step + 0.5)*step
        snapped = math.clamp(snapped, minV, maxV)
        Config.set(key, snapped)
        local r2 = valToX(snapped)
        trackFill.Size    = UDim2.new(r2,0,1,0)
        knob.Position     = UDim2.new(r2,-6,0.5,-6)
        valLabel.Text     = label..": "..tostring(snapped)
    end

    local inputConn1 = safeConnect(knob.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
        end
    end)
    local inputConn2 = safeConnect(_UIS and _UIS.InputChanged, function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input.Position.X)
        end
    end)
    local inputConn3 = safeConnect(_UIS and _UIS.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    return row
end

-- Button row
local function makeButton(parent, label, onClick)
    local theme = ThemeManager.get()
    local btn = newInst("TextButton", parent, {
        Text=label, Font=Enum.Font.GothamMedium, TextSize=12,
        TextColor3=theme.text, BackgroundColor3=theme.bgTertiary,
        BorderSizePixel=0, Size=UDim2.new(1,0,0,34), ZIndex=12,
    })
    newInst("UICorner", btn, {CornerRadius=UDim.new(0,8)})
    newInst("UIStroke", btn, {Color=theme.border, Thickness=1, Transparency=0.5})
    btn.MouseButton1Click:Connect(function() if onClick then pcall(onClick) end end)
    return btn
end

-- Theme selector buttons
local function makeThemeButtons(parent)
    local theme  = ThemeManager.get()
    local themes = {"Dark","Midnight","Neon","Glass","AMOLED"}
    local row    = newInst("Frame", parent, {
        BackgroundTransparency=1, Size=UDim2.new(1,0,0,34), ZIndex=12,
    })
    newInst("UIListLayout", row, {
        FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,4),
        SortOrder=Enum.SortOrder.LayoutOrder,
    })
    for i, t in ipairs(themes) do
        local th  = ThemeManager.themes[t]
        local btn = newInst("TextButton", row, {
            Text=t, Font=Enum.Font.Gotham, TextSize=10,
            TextColor3=Color3.fromRGB(255,255,255),
            BackgroundColor3=th.accent, BorderSizePixel=0,
            Size=UDim2.new(0, 64, 1, 0), LayoutOrder=i, ZIndex=13,
        })
        newInst("UICorner", btn, {CornerRadius=UDim.new(0,6)})
        btn.MouseButton1Click:Connect(function()
            ThemeManager.set(t)
            NotificationManager.send("Theme","Changed to "..t,"INFO",2)
        end)
    end
    return row
end

function UI.populateTab(tabName)
    clearContent()
    local theme = ThemeManager.get()

    if tabName == "Dashboard" then
        header("Dashboard")
        secHead("Welcome to Kurai Software v"..KURAI_VERSION)
        divider()
        secHead("Quick Status")
        local function statRow(label, val, col)
            local row = newInst("Frame", UI.contentFrame, {
                BackgroundColor3=theme.bgSecondary, BackgroundTransparency=0.4,
                Size=UDim2.new(1,0,0,34), BorderSizePixel=0, ZIndex=12,
            })
            newInst("UICorner", row, {CornerRadius=UDim.new(0,8)})
            newInst("TextLabel", row, {
                Text=label, Font=Enum.Font.Gotham, TextSize=12,
                TextColor3=theme.textDim, BackgroundTransparency=1,
                Size=UDim2.new(0.5,0,1,0), Position=UDim2.new(0,10,0,0),
                TextXAlignment=Enum.TextXAlignment.Left, ZIndex=13,
            })
            newInst("TextLabel", row, {
                Text=val, Font=Enum.Font.GothamBold, TextSize=13,
                TextColor3=col or theme.success, BackgroundTransparency=1,
                Size=UDim2.new(0.4,0,1,0), Position=UDim2.new(0.57,0,0,0),
                TextXAlignment=Enum.TextXAlignment.Right, ZIndex=13,
            })
        end

        statRow("Executor", Platform.executor, theme.accent)
        statRow("Platform", Platform.os, theme.accent)
        statRow("Drawing API", hasDrawing() and "Available" or "Unavailable", hasDrawing() and theme.success or theme.danger)
        statRow("Features Active", tostring(#(function() local n=0; for _ in pairs(Core.activeFeatures) do n=n+1 end return {} end)()).."0", theme.info)
        statRow("FPS", tostring(Performance.fps), theme.success)
        statRow("Session", string.format("%dm %ds", math.floor((os.clock()-Core.sessionStart)/60), math.floor(os.clock()-Core.sessionStart)%60), theme.info)

        divider()
        secHead("Quick Actions")
        makeButton(UI.contentFrame, "🚨 Panic — Disable All", function() PanicButton.activate() end)
        makeButton(UI.contentFrame, "🔄 Reload Config", function() Config.load() end)

    elseif tabName == "ESP" then
        header("ESP")
        secHead("Master Toggle")
        makeToggle(UI.contentFrame, "espEnabled", "ESP Master Enable", function(v)
            if not v then
                Config.set("espBoxEnabled", false)
                Config.set("espNameEnabled", false)
                Config.set("espDistEnabled", false)
                Config.set("espHealthEnabled", false)
                Config.set("espTracerEnabled", false)
                Config.set("espChamsEnabled", false)
                Config.set("espRainbowEnabled", false)
            end
        end)
        divider()
        secHead("ESP Options")
        makeToggle(UI.contentFrame, "espBoxEnabled",    "Box ESP")
        makeToggle(UI.contentFrame, "espNameEnabled",   "Name ESP")
        makeToggle(UI.contentFrame, "espDistEnabled",   "Distance ESP")
        makeToggle(UI.contentFrame, "espHealthEnabled", "Health Bar ESP")
        makeToggle(UI.contentFrame, "espTracerEnabled", "Tracer ESP")
        makeToggle(UI.contentFrame, "espChamsEnabled",  "Chams (SelectionBox)")
        makeToggle(UI.contentFrame, "espRainbowEnabled","Rainbow ESP")
        divider()
        secHead("ESP Settings")
        makeSlider(UI.contentFrame, "espRange",     "ESP Range",     50,  1000, 10)
        makeSlider(UI.contentFrame, "espThickness", "ESP Thickness",  1,   5,   1)

    elseif tabName == "Combat" then
        header("Combat")
        secHead("Aimbot")
        makeToggle(UI.contentFrame, "aimbotEnabled",  "Aimbot (RMB to aim)")
        makeToggle(UI.contentFrame, "camLockEnabled",  "Camera Lock")
        makeToggle(UI.contentFrame, "silentAimEnabled","Silent Aim", function(v)
            if v then AimSystem.enableSilentAim() else AimSystem.disableSilentAim() end
        end)
        makeSlider(UI.contentFrame, "aimFOV",       "Aim FOV",       10,  400, 5)
        makeSlider(UI.contentFrame, "aimSmoothing", "Aim Smoothing",  0,  0.99, 0.01)
        divider()
        secHead("Combat Tools")
        makeToggle(UI.contentFrame, "autoStabEnabled",  "Auto Stab")
        makeToggle(UI.contentFrame, "autoFlingEnabled", "Auto Fling")
        makeToggle(UI.contentFrame, "hitboxEnabled",    "Hitbox Expander")
        makeSlider(UI.contentFrame, "hitboxSize",       "Hitbox Size", 2,  30, 1)
        makeToggle(UI.contentFrame, "reachEnabled",     "Reach")
        makeSlider(UI.contentFrame, "reachDistance",    "Reach Distance", 5, 60, 1)

    elseif tabName == "Movement" then
        header("Movement")
        makeToggle(UI.contentFrame, "speedEnabled", "Speed Hack")
        makeSlider(UI.contentFrame, "walkSpeed",    "Walk Speed",  4, 200, 1)
        makeSlider(UI.contentFrame, "jumpPower",    "Jump Power",  0, 300, 5)
        divider()
        makeToggle(UI.contentFrame, "infJumpEnabled",   "Infinite Jump")
        makeToggle(UI.contentFrame, "flyEnabled",       "Fly", function(v)
            if v then MovementSystem.startFly() else MovementSystem.stopFly() end
        end)
        makeSlider(UI.contentFrame, "flySpeed",         "Fly Speed", 5, 300, 5)
        makeToggle(UI.contentFrame, "noclipEnabled",    "Noclip", function(v)
            if v then MovementSystem.startNoclip() else MovementSystem.stopNoclip() end
        end)
        makeToggle(UI.contentFrame, "bunnyHopEnabled",  "Bunny Hop")
        divider()
        makeToggle(UI.contentFrame, "gravityEnabled",   "Custom Gravity")
        makeSlider(UI.contentFrame, "gravityValue",     "Gravity Value", 0, 500, 5)

    elseif tabName == "Farm" then
        header("Farm")
        makeToggle(UI.contentFrame, "autoCollectEnabled", "Auto Collect Coins")
        makeSlider(UI.contentFrame, "autoCollectRange",   "Collect Range", 5, 100, 5)
        makeToggle(UI.contentFrame, "coinFarmEnabled",    "Coin Farm (TP to nearest coin)")
        divider()
        secHead("Farm Stats")
        local row = newInst("Frame", UI.contentFrame, {
            BackgroundColor3=theme.bgSecondary, BackgroundTransparency=0.4,
            Size=UDim2.new(1,0,0,34), BorderSizePixel=0, ZIndex=12,
        })
        newInst("UICorner", row, {CornerRadius=UDim.new(0,8)})
        newInst("TextLabel", row, {
            Text="Coins this session: "..tostring(FarmSystem.coinsThisSession),
            Font=Enum.Font.Gotham, TextSize=12, TextColor3=theme.success,
            BackgroundTransparency=1, Size=UDim2.new(1,-20,1,0), Position=UDim2.new(0,10,0,0),
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=13,
        })

    elseif tabName == "Intel" then
        header("Intelligence")
        makeToggle(UI.contentFrame, "espEnabled", "Role Detection (requires ESP)")
        divider()
        secHead("Detected Roles")
        if next(IntelSystem.roles) then
            for name, role in pairs(IntelSystem.roles) do
                local col = role == "Murderer" and theme.danger or (role == "Sheriff" and theme.info or theme.textDim)
                local row = newInst("Frame", UI.contentFrame, {
                    BackgroundColor3=theme.bgSecondary, BackgroundTransparency=0.5,
                    Size=UDim2.new(1,0,0,28), BorderSizePixel=0, ZIndex=12,
                })
                newInst("UICorner", row, {CornerRadius=UDim.new(0,6)})
                newInst("TextLabel", row, {
                    Text=name.." — "..role, Font=Enum.Font.Gotham, TextSize=11,
                    TextColor3=col, BackgroundTransparency=1,
                    Size=UDim2.new(1,-20,1,0), Position=UDim2.new(0,10,0,0),
                    TextXAlignment=Enum.TextXAlignment.Left, ZIndex=13,
                })
            end
        else
            newInst("TextLabel", UI.contentFrame, {
                Text="No roles detected yet. Roles appear after round starts.", Font=Enum.Font.Gotham, TextSize=11,
                TextColor3=theme.textDim, BackgroundTransparency=1,
                Size=UDim2.new(1,0,0,24), TextXAlignment=Enum.TextXAlignment.Left, ZIndex=12,
            })
        end

    elseif tabName == "Visual" then
        header("Visual")
        makeToggle(UI.contentFrame, "espEnabled", "Crosshair", function(v)
            CrosshairSystem.setVisible(v)
        end)
        divider()
        secHead("Theme")
        makeThemeButtons(UI.contentFrame)

    elseif tabName == "Settings" then
        header("Settings")
        secHead("Performance")
        makeToggle(UI.contentFrame, "performanceMode", "Performance Mode")
        makeToggle(UI.contentFrame, "debugMode", "Debug Mode", function(v)
            Core.debugMode = v
        end)
        divider()
        secHead("Animation")
        makeToggle(UI.contentFrame, "startupAnimation", "Startup Animation")
        makeSlider(UI.contentFrame, "animationSpeed",   "Animation Speed", 0.1, 5, 0.1)
        divider()
        secHead("Config")
        makeButton(UI.contentFrame, "💾 Save Config", function() Config.save(); NotificationManager.send("Config","Saved","INFO",2) end)
        makeButton(UI.contentFrame, "🔄 Load Config", function() Config.load(); NotificationManager.send("Config","Loaded","INFO",2) end)
        makeButton(UI.contentFrame, "🗑️ Reset Config",  function() Config.reset(); NotificationManager.send("Config","Reset to defaults","INFO",2) end)
        divider()
        secHead("Keybinds")
        newInst("TextLabel", UI.contentFrame, {
            Text="RightCtrl — Toggle Dashboard\nEnd — Panic Button",
            Font=Enum.Font.Gotham, TextSize=11, TextColor3=theme.textDim,
            BackgroundTransparency=1, Size=UDim2.new(1,0,0,36),
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=12, TextWrapped=true,
        })

    elseif tabName == "Stats" then
        header("Statistics")
        local function sRow(label, val)
            local row = newInst("Frame", UI.contentFrame, {
                BackgroundColor3=theme.bgSecondary, BackgroundTransparency=0.4,
                Size=UDim2.new(1,0,0,34), BorderSizePixel=0, ZIndex=12,
            })
            newInst("UICorner", row, {CornerRadius=UDim.new(0,8)})
            newInst("TextLabel", row, {
                Text=label, Font=Enum.Font.Gotham, TextSize=12,
                TextColor3=theme.textDim, BackgroundTransparency=1,
                Size=UDim2.new(0.6,0,1,0), Position=UDim2.new(0,10,0,0),
                TextXAlignment=Enum.TextXAlignment.Left, ZIndex=13,
            })
            newInst("TextLabel", row, {
                Text=tostring(val), Font=Enum.Font.GothamBold, TextSize=13,
                TextColor3=theme.success, BackgroundTransparency=1,
                Size=UDim2.new(0.35,0,1,0), Position=UDim2.new(0.62,0,0,0),
                TextXAlignment=Enum.TextXAlignment.Right, ZIndex=13,
            })
        end
        sRow("FPS",          Performance.fps)
        sRow("Session Time", string.format("%dm %ds", math.floor((os.clock()-Core.sessionStart)/60), math.floor(os.clock()-Core.sessionStart)%60))
        sRow("Executor",     Platform.executor)
        sRow("Total Kills",  Statistics.totalKills)
        sRow("Total Deaths", Statistics.totalDeaths)
        sRow("K/D Ratio",    Statistics.getKD())
        sRow("Coins Farmed", Statistics.coinsCollected)
        sRow("Rounds Played",Statistics.roundsPlayed)
        makeButton(UI.contentFrame, "Reset Statistics", function() Statistics.reset() UI.populateTab("Stats") end)

    elseif tabName == "Compat" then
        header("Compatibility")
        secHead("Detected Environment")
        newInst("TextLabel", UI.contentFrame, {
            Text="Platform: "..Platform.os.."  |  Executor: "..Platform.executor,
            Font=Enum.Font.Gotham, TextSize=12, TextColor3=theme.textDim,
            BackgroundTransparency=1, Size=UDim2.new(1,0,0,24),
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=12,
        })
        divider()
        secHead("Capabilities")
        local caps = {
            {"UI System",   Platform.capabilities.ui},
            {"Drawing API", Platform.capabilities.drawing},
            {"Filesystem",  Platform.capabilities.filesystem},
            {"Network",     Platform.capabilities.network},
            {"Input",       Platform.capabilities.input},
            {"Movement",    true},
            {"Combat",      true},
            {"Config",      true},
        }
        for _, c in ipairs(caps) do
            local row = newInst("Frame", UI.contentFrame, {
                BackgroundColor3=theme.bgSecondary, BackgroundTransparency=0.4,
                Size=UDim2.new(1,0,0,32), BorderSizePixel=0, ZIndex=12,
            })
            newInst("UICorner", row, {CornerRadius=UDim.new(0,8)})
            newInst("TextLabel", row, {
                Text=c[1], Font=Enum.Font.Gotham, TextSize=12, TextColor3=theme.text,
                BackgroundTransparency=1, Size=UDim2.new(0.6,0,1,0), Position=UDim2.new(0,10,0,0),
                TextXAlignment=Enum.TextXAlignment.Left, ZIndex=13,
            })
            newInst("TextLabel", row, {
                Text=c[2] and "SUPPORTED" or "UNAVAILABLE", Font=Enum.Font.GothamBold, TextSize=11,
                TextColor3=c[2] and theme.success or theme.danger, BackgroundTransparency=1,
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
            for i = #logs, math.max(#logs-80, 0)+1, -1 do
                local e   = logs[i]
                local row = newInst("Frame", UI.contentFrame, {
                    BackgroundColor3=theme.bgSecondary, BackgroundTransparency=0.5,
                    Size=UDim2.new(1,0,0,26), BorderSizePixel=0, ZIndex=12,
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
        makeButton(UI.contentFrame, "Clear Logs", function() Core.logs = {}; UI.populateTab("Logs") end)
    end

    -- auto-resize canvas
    task.wait()
    pcall(function()
        local layout = UI.contentFrame:FindFirstChildOfClass("UIListLayout")
        if layout then
            UI.contentFrame.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y + 20)
        end
    end)
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
        if UI.shadowFrame     then UI.shadowFrame.Visible = false end
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
        if input.KeyCode == Enum.KeyCode.End          then PanicButton.activate() end
    end)
    table.insert(Core.connections, conn)
    CleanupManager.register("ToggleKeybind", function() conn:Disconnect() end)
end

-- ============================================================
-- STATS REFRESH (live update every 2s while on Stats tab)
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
            -- Refresh server info
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

    local uiReady = false
    pcall(function() uiReady = UI.init() end)

    if not uiReady then
        Logger.log("Boot","Headless mode — no UI")
        Core.initialized = true
        -- still start game loops
        pcall(ESP.startLoop)
        pcall(Chams.startLoop)
        pcall(AimSystem.startLoop)
        pcall(MovementSystem.startLoop)
        pcall(HitboxSystem.startLoop)
        pcall(CombatSystem.startLoop)
        pcall(FarmSystem.startLoop)
        pcall(IntelSystem.startLoop)
        return
    end

    -- Build startup or skip
    if not Config.get("startupAnimation") then
        pcall(UI.buildDashboard)
        pcall(UI.buildMobileToggleButton)
        UI.show()
        KeybindManager.init()
        setupToggleKeybind()
        startStatsRefresh()

        -- start game loops
        pcall(ESP.startLoop)
        pcall(Chams.startLoop)
        pcall(AimSystem.startLoop)
        pcall(MovementSystem.startLoop)
        pcall(HitboxSystem.startLoop)
        pcall(CombatSystem.startLoop)
        pcall(FarmSystem.startLoop)
        pcall(IntelSystem.startLoop)

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

                -- start all game loops AFTER ui is ready
                pcall(ESP.startLoop)
                pcall(Chams.startLoop)
                pcall(AimSystem.startLoop)
                pcall(MovementSystem.startLoop)
                pcall(HitboxSystem.startLoop)
                pcall(CombatSystem.startLoop)
                pcall(FarmSystem.startLoop)
                pcall(IntelSystem.startLoop)

                Core.initialized = true
                Logger.log("Boot","Kurai v2.0 ready.")
                NotificationManager.send("Kurai","Ready — RightCtrl to toggle","INFO",4)
            end)
        end)
        if not ok2 then
            Logger.error("Boot","Animation",err2)
            pcall(UI.buildDashboard)
            pcall(UI.buildMobileToggleButton)
            UI.show()
            Core.initialized = true
        end
    end)
end

-- Export
KuraiSoftware.Core              = Core
KuraiSoftware.Platform          = Platform
KuraiSoftware.Config            = Config
KuraiSoftware.Logger            = Logger
KuraiSoftware.FeatureManager    = FeatureManager
KuraiSoftware.KeybindManager    = KeybindManager
KuraiSoftware.NotificationManager = NotificationManager
KuraiSoftware.Performance       = Performance
KuraiSoftware.Statistics        = Statistics
KuraiSoftware.ThemeManager      = ThemeManager
KuraiSoftware.TargetManager     = TargetManager
KuraiSoftware.PanicButton       = PanicButton
KuraiSoftware.ESP               = ESP
KuraiSoftware.AimSystem         = AimSystem
KuraiSoftware.MovementSystem    = MovementSystem
KuraiSoftware.FarmSystem        = FarmSystem
KuraiSoftware.IntelSystem       = IntelSystem
KuraiSoftware.UI                = UI

KuraiSoftware.init()
return KuraiSoftware

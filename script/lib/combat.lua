--[[
    ========================================================
    PawZHub  —  Universal Combat Library  v1.0.0
    ========================================================
    Provides combat automation features used across all
    PawZHub game scripts.

    Features:
      • KillAura       - auto-attack nearest target in range
      • AutoM1         - auto-click / auto-punch loop
      • AutoParry      - auto-block incoming attacks (timing-based)
      • SilentAim      - aim at target without camera rotation
      • TriggerBot     - auto-fire when crosshair on enemy
      • Aimbot         - lock camera to nearest enemy
      • Target filters - team check, alive check, distance
      • Whitelist/blacklist - exclude/include specific players
      • Hit verification - raycast validation before firing
      • Smooth aim      - gradual camera rotation (reduces detection)
      • FOV circle      - visualize aimbot range
      • Auto-switch     - retarget when current dies

    Usage:
        local Combat = loadstring(game:HttpGet(URL))()
        Combat.Init()

        Combat.SetKillAura(true, 20)  -- enabled, range (studs)
        Combat.SetAutoM1(true, 0.15)   -- enabled, delay (seconds)
        Combat.SetSilentAim(true)
        Combat.SetAimbot(true, { fov=180, smoothness=5, teamCheck=true })
        Combat.SetTriggerBot(true, 0.05)  -- enabled, reaction delay

        Combat.Whitelist("PlayerName")
        Combat.Blacklist("PlayerName")

        -- Cleanup
        Combat.Unload()
]]

-- ========================================================
-- SERVICES
-- ========================================================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace        = game:GetService("Workspace")
local ReplicatedStorage= game:GetService("ReplicatedStorage")

local Player           = Players.LocalPlayer
local Mouse            = Player:GetMouse()
local Camera           = Workspace.CurrentCamera

-- ========================================================
-- STATE
-- ========================================================
local Combat = {}
Combat.__version = "1.0.0"
Combat.__type    = "PawZHub.Combat"

local State = {
    initialized   = false,
    unloaded      = false,
    
    -- KillAura
    killAura      = {
        enabled   = false,
        range     = 20,
        delay     = 0.1,
        teamCheck = true,
        conn      = nil,
        lastHit   = 0,
    },
    
    -- AutoM1
    autoM1        = {
        enabled   = false,
        delay     = 0.15,
        conn      = nil,
        lastClick = 0,
    },
    
    -- AutoParry
    autoParry     = {
        enabled   = false,
        reactTime = 0.08,  -- reaction time window (seconds)
        conn      = nil,
        watching  = {},    -- enemies being watched
    },
    
    -- SilentAim
    silentAim     = {
        enabled   = false,
        fov       = 180,
        teamCheck = true,
        hitPart   = "Head",  -- "Head" | "Torso" | "HumanoidRootPart"
    },
    
    -- TriggerBot
    triggerBot    = {
        enabled   = false,
        delay     = 0.05,
        conn      = nil,
        lastShot  = 0,
    },
    
    -- Aimbot
    aimbot        = {
        enabled   = false,
        fov       = 180,
        smoothness= 5,     -- lower = faster snap (1=instant, 10=very smooth)
        teamCheck = true,
        targetPart= "Head",
        conn      = nil,
        currentTarget = nil,
        showFOV   = false,
        fovCircle = nil,
    },
    
    -- Filters
    whitelist     = {},  -- { [playerName] = true }
    blacklist     = {},  -- { [playerName] = true }
    maxDistance   = 500, -- global max range (studs)
    aliveCheck    = true,
    
    -- Connections
    conns         = {},
}

-- ========================================================
-- HELPERS
-- ========================================================
local function safe(fn, default)
    local ok, v = pcall(fn)
    return ok and v or default
end

local function getChar(p)
    return p and p.Character
end

local function getHum(char)
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getHRP(char)
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso"))
end

local function isAlive(char)
    local h = getHum(char)
    return h and h.Health > 0
end

local function getDistance(from, to)
    return (from - to).Magnitude
end

local function worldToScreen(pos)
    if not Camera then return nil, false end
    local vec, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(vec.X, vec.Y), onScreen
end

local function getAngleBetween(from, to)
    local direction = (to - from).Unit
    local cameraLook = Camera.CFrame.LookVector
    return math.deg(math.acos(cameraLook:Dot(direction)))
end

-- Check if player passes filters
local function passesFilters(player)
    if player == Player then return false end
    
    -- Whitelist (if set, only allow whitelisted)
    local hasWhitelist = false
    for _ in pairs(State.whitelist) do hasWhitelist = true; break end
    if hasWhitelist then
        if not State.whitelist[player.Name] then return false end
    end
    
    -- Blacklist
    if State.blacklist[player.Name] then return false end
    
    return true
end

-- Check if character is valid target
local function isValidTarget(char, teamCheck, maxDist)
    if not char then return false end
    
    local player = Players:GetPlayerFromCharacter(char)
    if not player then return false end
    if not passesFilters(player) then return false end
    
    -- Team check
    if teamCheck and Player.Team and player.Team and Player.Team == player.Team then
        return false
    end
    
    -- Alive check
    if State.aliveCheck and not isAlive(char) then return false end
    
    -- Distance check
    if maxDist and maxDist > 0 then
        local myChar = getChar(Player)
        local myHRP  = myChar and getHRP(myChar)
        local targetHRP = getHRP(char)
        if myHRP and targetHRP then
            local dist = getDistance(myHRP.Position, targetHRP.Position)
            if dist > maxDist then return false end
        else
            return false
        end
    end
    
    return true
end

-- Get nearest valid target
local function getNearestTarget(teamCheck, maxDist, fov)
    local myChar = getChar(Player)
    local myHRP  = myChar and getHRP(myChar)
    if not myHRP then return nil end

    local nearest = nil
    local nearestDist = math.huge

    for _, p in ipairs(Players:GetPlayers()) do
        local char = getChar(p)
        if isValidTarget(char, teamCheck, maxDist) then
            local hrp = getHRP(char)
            if hrp then
                local dist = getDistance(myHRP.Position, hrp.Position)

                -- FOV check (if specified)
                local skip = false
                if fov and fov < 180 then
                    local angle = getAngleBetween(Camera.CFrame.Position, hrp.Position)
                    if angle > fov then skip = true end
                end

                if not skip and dist < nearestDist then
                    nearestDist = dist
                    nearest = char
                end
            end
        end
    end

    return nearest, nearestDist
end

-- Raycast to verify line of sight
local function hasLineOfSight(from, to)
    local direction = (to - from)
    local ray = Ray.new(from, direction)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = { getChar(Player), Camera }
    
    local result = safe(function()
        return Workspace:Raycast(ray.Origin, ray.Direction, params)
    end)
    
    if not result then return true end  -- no hit = clear
    
    -- Check if hit is part of target character
    local hitChar = result.Instance and result.Instance:FindFirstAncestorOfClass("Model")
    local targetChar = to.Parent
    return hitChar == targetChar
end

-- ========================================================
-- KILLAURA
-- ========================================================
local function killAuraTick()
    if State.unloaded or not State.killAura.enabled then return end
    
    local now = tick()
    if now - State.killAura.lastHit < State.killAura.delay then return end
    
    local target = getNearestTarget(State.killAura.teamCheck, State.killAura.range)
    if not target then return end
    
    local hrp = getHRP(target)
    if not hrp then return end
    
    -- Execute attack (game-specific, override via SetKillAuraCallback)
    if type(State.killAuraCallback) == "function" then
        pcall(State.killAuraCallback, target)
    else
        -- Default: simulate mouse click toward target
        local myChar = getChar(Player)
        local myHRP  = myChar and getHRP(myChar)
        if myHRP then
            -- Face target
            myHRP.CFrame = CFrame.new(myHRP.Position, Vector3.new(hrp.Position.X, myHRP.Position.Y, hrp.Position.Z))
            -- Simulate click
            mouse1click()
        end
    end
    
    State.killAura.lastHit = now
end

function Combat.SetKillAura(enabled, range, delay, teamCheck)
    State.killAura.enabled   = enabled and true or false
    State.killAura.range     = tonumber(range) or 20
    State.killAura.delay     = tonumber(delay) or 0.1
    State.killAura.teamCheck = teamCheck ~= false
    
    if State.killAura.enabled and not State.killAura.conn then
        State.killAura.conn = RunService.Heartbeat:Connect(killAuraTick)
        table.insert(State.conns, State.killAura.conn)
    elseif not State.killAura.enabled and State.killAura.conn then
        pcall(function() State.killAura.conn:Disconnect() end)
        State.killAura.conn = nil
    end
end

function Combat.SetKillAuraCallback(fn)
    State.killAuraCallback = (type(fn) == "function") and fn or nil
end

-- ========================================================
-- AUTO M1 (auto-click)
-- ========================================================
local function autoM1Tick()
    if State.unloaded or not State.autoM1.enabled then return end
    
    local now = tick()
    if now - State.autoM1.lastClick < State.autoM1.delay then return end
    
    -- Simulate mouse1 click
    pcall(function()
        if type(mouse1click) == "function" then
            mouse1click()
        elseif type(mouse1press) == "function" and type(mouse1release) == "function" then
            mouse1press()
            task.wait(0.02)
            mouse1release()
        end
    end)
    
    State.autoM1.lastClick = now
end

function Combat.SetAutoM1(enabled, delay)
    State.autoM1.enabled = enabled and true or false
    State.autoM1.delay   = tonumber(delay) or 0.15
    
    if State.autoM1.enabled and not State.autoM1.conn then
        State.autoM1.conn = RunService.Heartbeat:Connect(autoM1Tick)
        table.insert(State.conns, State.autoM1.conn)
    elseif not State.autoM1.enabled and State.autoM1.conn then
        pcall(function() State.autoM1.conn:Disconnect() end)
        State.autoM1.conn = nil
    end
end

-- ========================================================
-- AUTO PARRY
-- ========================================================
--[[
    Auto-parry watches nearby enemies and triggers parry/block
    when they're about to attack. Requires game-specific
    attack detection (animation, sound, or distance change).
    
    Game script should call Combat.TriggerParry() when detecting
    an incoming attack, or use SetAutoParryCallback().
]]
local function autoParryTick()
    if State.unloaded or not State.autoParry.enabled then return end
    
    -- Watch all nearby enemies
    for _, p in ipairs(Players:GetPlayers()) do
        local char = getChar(p)
        if isValidTarget(char, true, 30) then  -- 30 stud watch range
            local hrp = getHRP(char)
            if hrp then
                -- Game-specific: detect attack animations
                -- This is a placeholder; override via callback
                if type(State.autoParryCallback) == "function" then
                    pcall(State.autoParryCallback, char)
                end
            end
        end
    end
end

function Combat.SetAutoParry(enabled, reactTime)
    State.autoParry.enabled   = enabled and true or false
    State.autoParry.reactTime = tonumber(reactTime) or 0.08
    
    if State.autoParry.enabled and not State.autoParry.conn then
        State.autoParry.conn = RunService.Heartbeat:Connect(autoParryTick)
        table.insert(State.conns, State.autoParry.conn)
    elseif not State.autoParry.enabled and State.autoParry.conn then
        pcall(function() State.autoParry.conn:Disconnect() end)
        State.autoParry.conn = nil
    end
end

function Combat.SetAutoParryCallback(fn)
    State.autoParryCallback = (type(fn) == "function") and fn or nil
end

-- Manual trigger (called by game script when attack detected)
function Combat.TriggerParry()
    if not State.autoParry.enabled then return end
    
    -- Execute parry action (game-specific key press)
    -- Default: press F key
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        vim:SendKeyEvent(true, Enum.KeyCode.F, false, game)
        task.wait(0.05)
        vim:SendKeyEvent(false, Enum.KeyCode.F, false, game)
    end)
end

-- ========================================================
-- SILENT AIM
-- ========================================================
--[[
    Silent aim redirects projectile/hit registration toward
    the nearest target without moving the camera. Requires
    game-specific hook into the fire/hit system.
    
    Typical usage: hook the Tool.Activated or RemoteEvent
    that sends hit position, replace with calculated position.
]]
function Combat.SetSilentAim(enabled, fov, hitPart)
    State.silentAim.enabled   = enabled and true or false
    State.silentAim.fov       = tonumber(fov) or 180
    State.silentAim.hitPart   = hitPart or "Head"
end

function Combat.GetSilentAimTarget()
    if not State.silentAim.enabled then return nil end
    
    local target = getNearestTarget(State.silentAim.teamCheck, State.maxDistance, State.silentAim.fov)
    if not target then return nil end
    
    local part = target:FindFirstChild(State.silentAim.hitPart) or getHRP(target)
    return part and part.Position or nil
end

-- ========================================================
-- TRIGGERBOT
-- ========================================================
local function triggerBotTick()
    if State.unloaded or not State.triggerBot.enabled then return end
    
    local now = tick()
    if now - State.triggerBot.lastShot < State.triggerBot.delay then return end
    
    -- Raycast from camera through mouse position
    local mousePos = UserInputService:GetMouseLocation()
    local ray = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)
    
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = { getChar(Player), Camera }
    
    local result = safe(function()
        return Workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
    end)
    
    if not result then return end
    
    -- Check if hit is a valid enemy
    local hitChar = result.Instance and result.Instance:FindFirstAncestorOfClass("Model")
    if not hitChar then return end
    
    if isValidTarget(hitChar, true, State.maxDistance) then
        -- Fire weapon (simulate click)
        pcall(function()
            if type(mouse1click) == "function" then
                mouse1click()
            end
        end)
        State.triggerBot.lastShot = now
    end
end

function Combat.SetTriggerBot(enabled, delay)
    State.triggerBot.enabled = enabled and true or false
    State.triggerBot.delay   = tonumber(delay) or 0.05
    
    if State.triggerBot.enabled and not State.triggerBot.conn then
        State.triggerBot.conn = RunService.RenderStepped:Connect(triggerBotTick)
        table.insert(State.conns, State.triggerBot.conn)
    elseif not State.triggerBot.enabled and State.triggerBot.conn then
        pcall(function() State.triggerBot.conn:Disconnect() end)
        State.triggerBot.conn = nil
    end
end

-- ========================================================
-- AIMBOT
-- ========================================================
local function aimbotTick()
    if State.unloaded or not State.aimbot.enabled then return end
    
    -- Get nearest target in FOV
    local target = getNearestTarget(State.aimbot.teamCheck, State.maxDistance, State.aimbot.fov)
    
    if not target then
        State.aimbot.currentTarget = nil
        return
    end
    
    State.aimbot.currentTarget = target
    
    local targetPart = target:FindFirstChild(State.aimbot.targetPart) or getHRP(target)
    if not targetPart then return end
    
    -- Smooth aim toward target
    local targetPos = targetPart.Position
    local currentCF = Camera.CFrame
    local targetCF  = CFrame.new(currentCF.Position, targetPos)
    
    local smoothness = math.max(State.aimbot.smoothness, 1)
    local newCF = currentCF:Lerp(targetCF, 1 / smoothness)
    
    Camera.CFrame = newCF
end

function Combat.SetAimbot(enabled, options)
    options = options or {}
    
    State.aimbot.enabled    = enabled and true or false
    State.aimbot.fov        = tonumber(options.fov) or 180
    State.aimbot.smoothness = tonumber(options.smoothness) or 5
    State.aimbot.teamCheck  = options.teamCheck ~= false
    State.aimbot.targetPart = options.targetPart or "Head"
    State.aimbot.showFOV    = options.showFOV or false
    
    if State.aimbot.enabled and not State.aimbot.conn then
        State.aimbot.conn = RunService.RenderStepped:Connect(aimbotTick)
        table.insert(State.conns, State.aimbot.conn)
    elseif not State.aimbot.enabled and State.aimbot.conn then
        pcall(function() State.aimbot.conn:Disconnect() end)
        State.aimbot.conn = nil
        State.aimbot.currentTarget = nil
    end
    
    -- FOV circle
    if State.aimbot.showFOV and State.aimbot.enabled then
        Combat._createFOVCircle()
    elseif State.aimbot.fovCircle then
        Combat._destroyFOVCircle()
    end
end

function Combat._createFOVCircle()
    if State.aimbot.fovCircle then return end
    
    local circle = Drawing.new("Circle")
    circle.Visible     = true
    circle.Thickness   = 2
    circle.Color       = Color3.fromRGB(255, 255, 255)
    circle.Transparency= 0.8
    circle.NumSides    = 64
    circle.Filled      = false
    
    State.aimbot.fovCircle = circle
    
    -- Update circle position/radius each frame
    State.aimbot.fovUpdateConn = RunService.RenderStepped:Connect(function()
        if not State.aimbot.fovCircle or not State.aimbot.enabled or not State.aimbot.showFOV then
            return
        end
        
        local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        circle.Position = center
        
        -- Convert FOV angle to screen radius (approximate)
        local radius = math.tan(math.rad(State.aimbot.fov)) * (Camera.ViewportSize.Y / 2)
        circle.Radius = math.clamp(radius, 10, 500)
    end)
end

function Combat._destroyFOVCircle()
    if State.aimbot.fovCircle then
        pcall(function() State.aimbot.fovCircle:Remove() end)
        State.aimbot.fovCircle = nil
    end
    if State.aimbot.fovUpdateConn then
        pcall(function() State.aimbot.fovUpdateConn:Disconnect() end)
        State.aimbot.fovUpdateConn = nil
    end
end

-- ========================================================
-- WHITELIST / BLACKLIST
-- ========================================================
function Combat.Whitelist(playerName)
    State.whitelist[playerName] = true
end

function Combat.RemoveWhitelist(playerName)
    State.whitelist[playerName] = nil
end

function Combat.ClearWhitelist()
    State.whitelist = {}
end

function Combat.Blacklist(playerName)
    State.blacklist[playerName] = true
end

function Combat.RemoveBlacklist(playerName)
    State.blacklist[playerName] = nil
end

function Combat.ClearBlacklist()
    State.blacklist = {}
end

-- ========================================================
-- SETTINGS
-- ========================================================
function Combat.SetMaxDistance(dist)
    State.maxDistance = tonumber(dist) or 500
end

function Combat.SetAliveCheck(enabled)
    State.aliveCheck = enabled and true or false
end

-- ========================================================
-- GET CURRENT TARGET (for external use)
-- ========================================================
function Combat.GetCurrentTarget()
    return State.aimbot.currentTarget
end

function Combat.GetNearestEnemy(range)
    return getNearestTarget(true, range or State.maxDistance)
end

-- ========================================================
-- INIT
-- ========================================================
function Combat.Init()
    if State.initialized then return Combat end
    if State.unloaded then return Combat end
    
    State.initialized = true
    return Combat
end

-- ========================================================
-- UNLOAD
-- ========================================================
function Combat.Unload()
    if State.unloaded then return end
    State.unloaded = true
    
    -- Disable all systems
    Combat.SetKillAura(false)
    Combat.SetAutoM1(false)
    Combat.SetAutoParry(false)
    Combat.SetSilentAim(false)
    Combat.SetTriggerBot(false)
    Combat.SetAimbot(false)
    
    -- Disconnect all connections
    for _, c in ipairs(State.conns) do
        pcall(function() c:Disconnect() end)
    end
    State.conns = {}
    
    -- Cleanup FOV circle
    Combat._destroyFOVCircle()
end

-- ========================================================
-- DEBUG
-- ========================================================
function Combat.Dump()
    local wCount = 0
    for _ in pairs(State.whitelist) do wCount = wCount + 1 end
    local bCount = 0
    for _ in pairs(State.blacklist) do bCount = bCount + 1 end
    
    return {
        version      = Combat.__version,
        initialized  = State.initialized,
        unloaded     = State.unloaded,
        killAura     = { enabled = State.killAura.enabled, range = State.killAura.range },
        autoM1       = { enabled = State.autoM1.enabled, delay = State.autoM1.delay },
        autoParry    = { enabled = State.autoParry.enabled, reactTime = State.autoParry.reactTime },
        silentAim    = { enabled = State.silentAim.enabled, fov = State.silentAim.fov },
        triggerBot   = { enabled = State.triggerBot.enabled, delay = State.triggerBot.delay },
        aimbot       = {
            enabled = State.aimbot.enabled,
            fov = State.aimbot.fov,
            smoothness = State.aimbot.smoothness,
            currentTarget = State.aimbot.currentTarget and State.aimbot.currentTarget.Name or "None"
        },
        whitelist    = wCount,
        blacklist    = bCount,
        maxDistance  = State.maxDistance,
        aliveCheck   = State.aliveCheck,
    }
end

return Combat

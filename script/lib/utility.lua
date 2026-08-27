--[[
    ========================================================
    PawZHub  —  Universal Utility Library  v1.0.0
    ========================================================
    Provides helper functions and utilities used across all
    PawZHub game scripts. Integrates with movement.lua.

    Features:
      • Teleport helpers (safe TP, bring mob, TP to coords)
      • Target finders (nearest mob, player, item, NPC)
      • Anti-AFK (random input simulation)
      • Platform creation (invisible part under player)
      • Tool equip/unequip automation
      • Character state checks (grounded, swimming, climbing)
      • Bring/tween object (smooth move to player)
      • Farm loop helpers (auto-retry, timeout)
      • Notification integration
      • Integration with movement.lua (loads and uses it)

    Usage:
        local Util = loadstring(game:HttpGet(URL))()
        Util.Init()

        Util.TP(Vector3.new(100, 50, 200))
        Util.TPToPlayer("PlayerName")
        
        local nearestMob = Util.GetNearestMob(100)  -- within 100 studs
        local nearestPlayer = Util.GetNearestPlayer(200, true)  -- teamCheck
        
        Util.SetAntiAFK(true)
        Util.CreatePlatform()
        Util.EquipTool("Sword")
        
        -- Farm loop with auto-retry
        Util.FarmLoop(function()
            -- farm logic here
            return true  -- return false to stop
        end, 0.5)  -- 0.5s between iterations

        Util.Unload()
]]

-- ========================================================
-- SERVICES
-- ========================================================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace        = game:GetService("Workspace")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService     = game:GetService("TweenService")

local Player           = Players.LocalPlayer
local Backpack         = Player:WaitForChild("Backpack", 10)

-- ========================================================
-- STATE
-- ========================================================
local Util = {}
Util.__version = "1.0.0"
Util.__type    = "PawZHub.Utility"

local State = {
    initialized   = false,
    unloaded      = false,
    
    -- Movement lib integration
    Movement      = nil,
    
    -- Anti-AFK
    antiAFK       = {
        enabled   = false,
        conn      = nil,
        lastInput = 0,
        interval  = 120,  -- seconds between inputs
    },
    
    -- Platform
    platform      = nil,
    
    -- Farm loop
    farmLoop      = {
        running   = false,
        conn      = nil,
        callback  = nil,
        delay     = 0.5,
    },
    
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

local function notify(msg, kind)
    pcall(function()
        if type(_G.PawZHub_Notify) == "function" then
            _G.PawZHub_Notify(msg, kind or "info")
        end
    end)
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

-- ========================================================
-- MOVEMENT LIB INTEGRATION
-- ========================================================
local function loadMovement()
    if State.Movement then return State.Movement end
    
    local url = "https://raw.githubusercontent.com/nguyenhoaikha/PawZHub/main/script/lib/movement.lua"
    local ok, M = pcall(function()
        local src = game:HttpGet(url)
        local fn = loadstring(src)
        if not fn then return nil end
        return fn()
    end)
    
    if ok and type(M) == "table" and type(M.Init) == "function" then
        M.Init()
        State.Movement = M
        return M
    end
    
    return nil
end

-- ========================================================
-- TELEPORT HELPERS
-- ========================================================
--[[
    Util.TP(position, [useTween])
    - position: Vector3 or CFrame
    - useTween: if true, smooth tween instead of instant
]]
function Util.TP(pos, useTween)
    local char = getChar(Player)
    local hrp  = char and getHRP(char)
    if not hrp then return false end
    
    local targetCF
    if typeof(pos) == "Vector3" then
        targetCF = CFrame.new(pos)
    elseif typeof(pos) == "CFrame" then
        targetCF = pos
    else
        return false
    end
    
    if useTween then
        -- Smooth tween
        local dist = getDistance(hrp.Position, targetCF.Position)
        local dur  = math.clamp(dist / 200, 0.5, 5)  -- 200 studs/sec, 0.5-5s
        
        local tween = TweenService:Create(hrp, TweenInfo.new(dur, Enum.EasingStyle.Linear), {
            CFrame = targetCF
        })
        tween:Play()
        tween.Completed:Wait()
    else
        -- Instant
        hrp.CFrame = targetCF
    end
    
    return true
end

function Util.TPToPlayer(playerName, offset)
    local targetPlayer = Players:FindFirstChild(playerName)
    if not targetPlayer then return false end
    
    local targetChar = getChar(targetPlayer)
    local targetHRP  = targetChar and getHRP(targetChar)
    if not targetHRP then return false end
    
    offset = offset or Vector3.new(0, 3, 0)
    return Util.TP(targetHRP.Position + offset)
end

function Util.TPToCoords(x, y, z)
    return Util.TP(Vector3.new(x, y, z))
end

-- Bring object to player (sets CFrame repeatedly)
function Util.BringObject(obj, duration)
    if not obj or not obj:IsA("BasePart") and not obj:IsA("Model") then return false end
    
    duration = duration or 0.5
    local start = tick()
    
    local part
    if obj:IsA("BasePart") then
        part = obj
    else
        part = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart", true)
    end
    if not part then return false end
    
    local myChar = getChar(Player)
    local myHRP  = myChar and getHRP(myChar)
    if not myHRP then return false end
    
    -- Bring loop
    local conn
    conn = RunService.Heartbeat:Connect(function()
        if tick() - start > duration or not part.Parent or not myHRP.Parent then
            conn:Disconnect()
            return
        end
        
        pcall(function()
            part.CFrame = myHRP.CFrame + Vector3.new(0, 3, 0)
        end)
    end)
    
    return true
end

-- ========================================================
-- TARGET FINDERS
-- ========================================================
function Util.GetNearestMob(maxDist, nameFilter)
    maxDist = maxDist or math.huge

    local myChar = getChar(Player)
    local myHRP  = myChar and getHRP(myChar)
    if not myHRP then return nil end

    local nearest = nil
    local nearestDist = math.huge

    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= myChar then
            -- Check if it's an NPC (has Humanoid but no Player)
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local player = Players:GetPlayerFromCharacter(obj)
                if not player then  -- not a player = mob/NPC
                    -- Name filter (skip if not matching)
                    local skip = (nameFilter and not string.find(obj.Name:lower(), nameFilter:lower()))

                    if not skip then
                        local hrp = getHRP(obj)
                        if hrp then
                            local dist = getDistance(myHRP.Position, hrp.Position)
                            if dist < maxDist and dist < nearestDist then
                                nearestDist = dist
                                nearest = obj
                            end
                        end
                    end
                end
            end
        end
    end

    return nearest, nearestDist
end

function Util.GetNearestPlayer(maxDist, teamCheck)
    maxDist   = maxDist or math.huge
    teamCheck = teamCheck ~= false
    
    local myChar = getChar(Player)
    local myHRP  = myChar and getHRP(myChar)
    if not myHRP then return nil end
    
    local nearest = nil
    local nearestDist = math.huge
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= Player then
            -- Team check (skip if same team)
            local skip = (teamCheck and Player.Team and p.Team and Player.Team == p.Team)

            if not skip then
                local char = getChar(p)
                if char and isAlive(char) then
                    local hrp = getHRP(char)
                    if hrp then
                        local dist = getDistance(myHRP.Position, hrp.Position)
                        if dist < maxDist and dist < nearestDist then
                            nearestDist = dist
                            nearest = p
                        end
                    end
                end
            end
        end
    end
    
    return nearest, nearestDist
end

function Util.GetNearestItem(maxDist, nameFilter)
    maxDist = maxDist or math.huge
    
    local myChar = getChar(Player)
    local myHRP  = myChar and getHRP(myChar)
    if not myHRP then return nil end
    
    local nearest = nil
    local nearestDist = math.huge
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Tool") or (obj:IsA("Model") and obj:FindFirstChild("Handle")) then
            -- Name filter (skip if not matching)
            local skip = (nameFilter and not string.find(obj.Name:lower(), nameFilter:lower()))

            if not skip then
                local pos
                if obj:IsA("Tool") then
                    pos = obj.Handle and obj.Handle.Position
                else
                    local handle = obj:FindFirstChild("Handle")
                    pos = handle and handle.Position
                end

                if pos then
                    local dist = getDistance(myHRP.Position, pos)
                    if dist < maxDist and dist < nearestDist then
                        nearestDist = dist
                        nearest = obj
                    end
                end
            end
        end
    end
    
    return nearest, nearestDist
end

-- Get all mobs within range
function Util.GetMobsInRange(range, nameFilter)
    range = range or 100
    local mobs = {}
    
    local myChar = getChar(Player)
    local myHRP  = myChar and getHRP(myChar)
    if not myHRP then return mobs end
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= myChar then
            local hum = obj:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local player = Players:GetPlayerFromCharacter(obj)
                if not player then
                    -- Name filter (skip if not matching)
                    local skip = (nameFilter and not string.find(obj.Name:lower(), nameFilter:lower()))

                    if not skip then
                        local hrp = getHRP(obj)
                        if hrp then
                            local dist = getDistance(myHRP.Position, hrp.Position)
                            if dist <= range then
                                table.insert(mobs, { model = obj, distance = dist })
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Sort by distance
    table.sort(mobs, function(a, b) return a.distance < b.distance end)
    
    return mobs
end

-- ========================================================
-- ANTI-AFK
-- ========================================================
local function antiAFKTick()
    if State.unloaded or not State.antiAFK.enabled then return end
    
    local now = tick()
    if now - State.antiAFK.lastInput < State.antiAFK.interval then return end
    
    -- Send random input
    local keys = { Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D, Enum.KeyCode.Space }
    local key = keys[math.random(1, #keys)]
    
    pcall(function()
        VirtualInputManager:SendKeyEvent(true, key, false, game)
        task.wait(0.1)
        VirtualInputManager:SendKeyEvent(false, key, false, game)
    end)
    
    State.antiAFK.lastInput = now
end

function Util.SetAntiAFK(enabled, interval)
    State.antiAFK.enabled  = enabled and true or false
    State.antiAFK.interval = tonumber(interval) or 120
    
    if State.antiAFK.enabled and not State.antiAFK.conn then
        State.antiAFK.conn = RunService.Heartbeat:Connect(antiAFKTick)
        table.insert(State.conns, State.antiAFK.conn)
    elseif not State.antiAFK.enabled and State.antiAFK.conn then
        pcall(function() State.antiAFK.conn:Disconnect() end)
        State.antiAFK.conn = nil
    end
end

-- ========================================================
-- PLATFORM
-- ========================================================
function Util.CreatePlatform(size, transparency)
    Util.RemovePlatform()  -- remove old one
    
    size = size or Vector3.new(10, 1, 10)
    transparency = transparency or 0.5
    
    local myChar = getChar(Player)
    local myHRP  = myChar and getHRP(myChar)
    if not myHRP then return false end
    
    local platform = Instance.new("Part")
    platform.Name         = "PawZHub_Platform"
    platform.Size         = size
    platform.Anchored     = true
    platform.CanCollide   = true
    platform.Transparency = transparency
    platform.Material     = Enum.Material.ForceField
    platform.Color        = Color3.fromRGB(99, 102, 241)
    platform.Parent       = Workspace
    
    State.platform = platform
    
    -- Follow player
    local followConn
    followConn = RunService.Heartbeat:Connect(function()
        if not platform.Parent or not myHRP.Parent then
            followConn:Disconnect()
            State.platform = nil
            return
        end
        
        pcall(function()
            platform.CFrame = CFrame.new(myHRP.Position - Vector3.new(0, 4, 0))
        end)
    end)
    
    table.insert(State.conns, followConn)
    
    return true
end

function Util.RemovePlatform()
    if State.platform and State.platform.Parent then
        pcall(function() State.platform:Destroy() end)
    end
    State.platform = nil
end

-- ========================================================
-- TOOL HELPERS
-- ========================================================
function Util.EquipTool(toolName)
    local char = getChar(Player)
    if not char then return false end
    
    -- Check if already equipped
    local equipped = char:FindFirstChild(toolName)
    if equipped and equipped:IsA("Tool") then
        return true
    end
    
    -- Find in backpack
    local tool = Backpack:FindFirstChild(toolName)
    if not tool or not tool:IsA("Tool") then return false end
    
    -- Equip
    local hum = getHum(char)
    if hum then
        pcall(function() hum:EquipTool(tool) end)
        task.wait(0.2)
        return char:FindFirstChild(toolName) ~= nil
    end
    
    return false
end

function Util.UnequipTools()
    local char = getChar(Player)
    if not char then return false end
    
    local hum = getHum(char)
    if not hum then return false end
    
    pcall(function() hum:UnequipTools() end)
    return true
end

function Util.GetEquippedTool()
    local char = getChar(Player)
    if not char then return nil end
    
    for _, obj in ipairs(char:GetChildren()) do
        if obj:IsA("Tool") then
            return obj
        end
    end
    
    return nil
end

function Util.HasTool(toolName)
    local char = getChar(Player)
    if char and char:FindFirstChild(toolName) then return true end
    if Backpack:FindFirstChild(toolName) then return true end
    return false
end

-- ========================================================
-- CHARACTER STATE
-- ========================================================
function Util.IsGrounded()
    local char = getChar(Player)
    local hum  = char and getHum(char)
    if not hum then return false end
    
    local state = hum:GetState()
    return state == Enum.HumanoidStateType.Running
        or state == Enum.HumanoidStateType.Landed
        or state == Enum.HumanoidStateType.RunningNoPhysics
end

function Util.IsSwimming()
    local char = getChar(Player)
    local hum  = char and getHum(char)
    if not hum then return false end
    
    return hum:GetState() == Enum.HumanoidStateType.Swimming
end

function Util.IsClimbing()
    local char = getChar(Player)
    local hum  = char and getHum(char)
    if not hum then return false end
    
    return hum:GetState() == Enum.HumanoidStateType.Climbing
end

function Util.IsDead()
    local char = getChar(Player)
    return not isAlive(char)
end

-- ========================================================
-- FARM LOOP HELPER
-- ========================================================
--[[
    Util.FarmLoop(callback, delay)
    - callback: function() return true/false end
      Return false to stop loop
    - delay: seconds between iterations
]]
function Util.FarmLoop(callback, delay)
    if State.farmLoop.running then
        Util.StopFarmLoop()
    end
    
    if type(callback) ~= "function" then return false end
    
    State.farmLoop.running  = true
    State.farmLoop.callback = callback
    State.farmLoop.delay    = tonumber(delay) or 0.5
    
    State.farmLoop.conn = RunService.Heartbeat:Connect(function()
        if not State.farmLoop.running then return end
        
        local lastTick = tick()
        
        -- Execute callback
        local ok, shouldContinue = pcall(callback)
        if not ok or shouldContinue == false then
            Util.StopFarmLoop()
            return
        end
        
        -- Wait for delay
        local elapsed = tick() - lastTick
        if elapsed < State.farmLoop.delay then
            task.wait(State.farmLoop.delay - elapsed)
        end
    end)
    
    table.insert(State.conns, State.farmLoop.conn)
    
    return true
end

function Util.StopFarmLoop()
    State.farmLoop.running = false
    if State.farmLoop.conn then
        pcall(function() State.farmLoop.conn:Disconnect() end)
        State.farmLoop.conn = nil
    end
end

-- ========================================================
-- MISC HELPERS
-- ========================================================
function Util.GetPing()
    return Player:GetNetworkPing() * 1000  -- convert to ms
end

function Util.GetFPS()
    local fps = 0
    pcall(function()
        fps = math.floor(1 / RunService.RenderStepped:Wait())
    end)
    return fps
end

function Util.WaitForChild(parent, childName, timeout)
    timeout = timeout or 10
    return parent:WaitForChild(childName, timeout)
end

function Util.FindFirstChildOfClass(parent, className, recursive)
    if recursive then
        return parent:FindFirstChildOfClass(className, true)
    else
        return parent:FindFirstChildOfClass(className)
    end
end

-- Fire all ClickDetectors in range
function Util.FireClickDetectors(range)
    range = range or 20
    
    local myChar = getChar(Player)
    local myHRP  = myChar and getHRP(myChar)
    if not myHRP then return 0 end
    
    local count = 0
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ClickDetector") then
            local parent = obj.Parent
            if parent and parent:IsA("BasePart") then
                local dist = getDistance(myHRP.Position, parent.Position)
                if dist <= range then
                    pcall(function()
                        fireclickdetector(obj)
                    end)
                    count = count + 1
                end
            end
        end
    end
    
    return count
end

-- Fire all ProximityPrompts in range
function Util.FireProximityPrompts(range)
    range = range or 20
    
    local myChar = getChar(Player)
    local myHRP  = myChar and getHRP(myChar)
    if not myHRP then return 0 end
    
    local count = 0
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("ProximityPrompt") then
            local parent = obj.Parent
            if parent and parent:IsA("BasePart") then
                local dist = getDistance(myHRP.Position, parent.Position)
                if dist <= range then
                    pcall(function()
                        fireproximityprompt(obj)
                    end)
                    count = count + 1
                end
            end
        end
    end
    
    return count
end

-- ========================================================
-- MOVEMENT LIB FACADE
-- (Expose movement.lua functions through Util)
-- ========================================================
function Util.SetWalkSpeed(value, enabled)
    local M = loadMovement()
    if M then M.SetWalkSpeed(value, enabled) end
end

function Util.SetFly(enabled, mode, speed)
    local M = loadMovement()
    if M then M.SetFly(enabled, mode, speed) end
end

function Util.SetNoclip(enabled)
    local M = loadMovement()
    if M then M.SetNoclip(enabled) end
end

function Util.SetInfiniteJump(enabled)
    local M = loadMovement()
    if M then M.SetInfiniteJump(enabled) end
end

function Util.SavePos(name)
    local M = loadMovement()
    if M then return M.SavePos(name) end
    return false
end

function Util.LoadPos(name)
    local M = loadMovement()
    if M then return M.LoadPos(name) end
    return false
end

function Util.ListPos()
    local M = loadMovement()
    if M then return M.ListPos() end
    return {}
end

-- ========================================================
-- INIT
-- ========================================================
function Util.Init()
    if State.initialized then return Util end
    if State.unloaded then return Util end
    
    -- Try to load movement lib
    loadMovement()
    
    State.initialized = true
    return Util
end

-- ========================================================
-- UNLOAD
-- ========================================================
function Util.Unload()
    if State.unloaded then return end
    State.unloaded = true
    
    -- Stop all systems
    Util.SetAntiAFK(false)
    Util.RemovePlatform()
    Util.StopFarmLoop()
    
    -- Unload movement lib
    if State.Movement and type(State.Movement.Unload) == "function" then
        pcall(State.Movement.Unload)
    end
    
    -- Disconnect all connections
    for _, c in ipairs(State.conns) do
        pcall(function() c:Disconnect() end)
    end
    State.conns = {}
end

-- ========================================================
-- DEBUG
-- ========================================================
function Util.Dump()
    return {
        version      = Util.__version,
        initialized  = State.initialized,
        unloaded     = State.unloaded,
        movementLib  = State.Movement ~= nil,
        antiAFK      = { enabled = State.antiAFK.enabled, interval = State.antiAFK.interval },
        platform     = State.platform ~= nil,
        farmLoop     = { running = State.farmLoop.running, delay = State.farmLoop.delay },
    }
end

return Util

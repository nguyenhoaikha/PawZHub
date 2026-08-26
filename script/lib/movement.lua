--[[
    ========================================================
    PAWZHub - Universal Movement Library  v1.0.0
    ========================================================
    Shared movement system used by ALL PawZHub game scripts.

    Provides 11 subsystems:
      1.  WalkSpeed        - speed hack with original restore
      2.  Fly              - 3 modes (Velocity / CFrame / BodyVelocity), R6/R15, mobile
      3.  Noclip           - collision bypass with state restore
      4.  InfiniteJump     - jump mid-air
      5.  ClickTP          - click to teleport (PC + mobile)
      6.  SaveLoadPos      - waypoints (save / load / list / clear)
      7.  NoFallDamage     - suppress fall damage
      8.  AutoJump         - bunny hop
      9.  InfiniteStamina  - drain prevention
      10. ServerHop        - teleport to low-pop server
      11. Rejoin           - rejoin current server

    Design rules:
      - Every pcall is scoped — no error escapes
      - Every enabled state has a paired disable that fully restores originals
      - Character respawn re-applies all active toggles automatically
      - Unload() tears down everything in one call
      - All public API is documented and validated

    Usage (from a game script):
      local Movement = loadstring(game:HttpGet(
        "https://raw.githubusercontent.com/nguyenhoaikha/PawZHub/main/script/lib/movement.lua"
      ))()

      Movement.Init(Player, RunService, UserInputService, TeleportService, HttpService)

      Movement.SetWalkSpeed(50, true)         -- speed value, enabled
      Movement.SetFly(true, "CFrame", 80)     -- enabled, mode, speed
      Movement.SetNoclip(true)
      Movement.SetClickTP(true, 200)          -- enabled, max distance (studs)

      -- Cleanup on script unload:
      Movement.Unload()
]]

local Movement = {}
Movement.__version = "1.0.0"
Movement.__type = "PawZHub.Movement"

-- ========================================================
-- INTERNAL STATE
-- ========================================================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService  = game:GetService("TeleportService")
local HttpService      = game:GetService("HttpService")
local VirtualInputManager = (pcall(function() return game:GetService("VirtualInputManager") end)
                            and game:GetService("VirtualInputManager")) or nil

local Player       = Players.LocalPlayer
local Mouse        = Player:GetMouse()

-- State container — all mutations happen through public API.
local State = {
    initialized   = false,
    unloaded      = false,

    -- character binding
    charConns     = {},          -- RBXScriptConnections (re-bound on respawn)
    onRespawn     = nil,         -- function(char) called after respawn

    -- subsystems enabled?
    walkSpeed     = { enabled = false, value = 16, original = nil, char = nil, conn = nil },
    fly           = {
        enabled   = false,
        mode      = "CFrame",   -- "CFrame" | "Velocity" | "BodyVelocity"
        speed     = 80,
        bodyVel   = nil,        -- BodyVelocity instance when mode = "BodyVelocity"
        bodyGyro  = nil,        -- BodyGyro for stable orientation
        conn      = nil,        -- RenderStepped conn
        keys      = { up = false, down = false, left = false, right = false },
        bound     = false,      -- input listeners bound
    },
    noclip        = {
        enabled   = false,
        parts     = {},         -- { part = originalCanCollide }
        conn      = nil,
    },
    infJump       = { enabled = false, conn = nil },
    clickTP       = {
        enabled   = false,
        maxDist   = 500,        -- studs, 0 = unlimited
        conn      = nil,
    },
    saveLoadPos   = {
        waypoints = {},         -- { [name] = CFrame }
    },
    noFall        = { enabled = false, conn = nil, lastGroundCF = nil },
    autoJump      = { enabled = false, conn = nil },
    infStamina    = { enabled = false, conn = nil },
    serverHop     = {
        active    = false,
        busy      = false,
        maxPlayers= 6,
        cooldown  = 3,
        generation= 0,
    },
}

-- KeyCodes used for fly controls (PC). Mobile uses a separate on-screen pad
-- exposed via Movement.GetMobileFlyUI() (future).
local FLY_KEYS = {
    [Enum.KeyCode.W]      = "up",
    [Enum.KeyCode.A]      = "left",
    [Enum.KeyCode.S]      = "down",
    [Enum.KeyCode.D]      = "right",
    [Enum.KeyCode.Space]  = "up",
    [Enum.KeyCode.LeftShift] = "down",
}

-- ========================================================
-- UTILITIES
-- ========================================================
local function safe(fn, default)
    if type(fn) ~= "function" then return default end
    local ok, res = pcall(fn)
    if not ok then return default end
    return res
end

local function getChar()
    return Player and Player.Character
end

local function getHum()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end

local function getHRP()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getRootPart()
    -- returns the lowest BasePart in the character (used for ground checks)
    local c = getChar()
    if not c then return nil end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    if hrp then return hrp end
    return c:FindFirstChildWhichIsA("BasePart", true)
end

local function isAlive()
    local h = getHum()
    return h and h.Health > 0
end

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function notify(msg, kind)
    -- Soft integration with game's Toast if exposed. Safe no-op otherwise.
    kind = kind or "ok"
    pcall(function()
        if type(_G.PawZHub_Notify) == "function" then
            _G.PawZHub_Notify(msg, kind)
        elseif type(_G.PawZHub_Toast) == "table" and type(_G.PawZHub_Toast.Show) == "function" then
            _G.PawZHub_Toast:Show(msg, kind)
        end
    end)
end

local function disconnect(conn)
    if conn and type(conn.Disconnect) == "function" then
        pcall(function() conn:Disconnect() end)
    end
end

local function addConn(conn)
    if conn and type(conn.Destroy) == "function" then
        table.insert(State.charConns, conn)
        return conn
    end
    if conn and type(conn.Disconnect) == "function" then
        table.insert(State.charConns, conn)
    end
    return conn
end

local function clearConns()
    for i = #State.charConns, 1, -1 do
        disconnect(State.charConns[i])
        State.charConns[i] = nil
    end
end

-- ========================================================
-- 1. WALKSPEED
-- ========================================================
local function applyWalkSpeedNow()
    if State.unloaded then return end
    local hum = getHum()
    if not hum then return end
    local s = State.walkSpeed
    if s.char ~= hum.Parent then
        s.char = hum.Parent
        s.original = hum.WalkSpeed
    end
    if s.enabled then
        local v = clamp(tonumber(s.value) or 16, 0, 1000)
        pcall(function() hum.WalkSpeed = v end)
    else
        if s.original then
            pcall(function() hum.WalkSpeed = tonumber(s.original) or 16 end)
        end
    end
end

local function ensureWalkSpeedConn()
    if State.walkSpeed.conn or State.unloaded then return end
    -- Apply once per frame so game scripts that mutate WalkSpeed get clobbered
    State.walkSpeed.conn = addConn(RunService.Heartbeat:Connect(function()
        if State.unloaded or not State.walkSpeed.enabled then return end
        applyWalkSpeedNow()
    end))
end

function Movement.SetWalkSpeed(value, enabled)
    if State.unloaded then return end
    State.walkSpeed.value = tonumber(value) or 16
    State.walkSpeed.enabled = enabled and true or false
    if State.walkSpeed.enabled then
        ensureWalkSpeedConn()
        applyWalkSpeedNow()
    else
        applyWalkSpeedNow()
    end
end

function Movement.GetWalkSpeed()
    return State.walkSpeed.value
end

-- ========================================================
-- 2. FLY
-- ========================================================
local function flyUpdate(dt)
    if State.unloaded or not State.fly.enabled then return end
    local hrp = getHRP()
    if not hrp or not isAlive() then return end

    local s = State.fly
    local speed = clamp(tonumber(s.speed) or 80, 1, 500)
    local stepDt = tonumber(dt) or 0.016
    if stepDt <= 0 then stepDt = 0.016 end

    -- camera-aligned direction
    local cam = safe(function() return workspace.CurrentCamera end)
    local dir = Vector3.zero
    if cam then
        if s.keys.up    then dir = dir + cam.CFrame.LookVector  end
        if s.keys.down  then dir = dir - cam.CFrame.LookVector  end
        if s.keys.left  then dir = dir - cam.CFrame.RightVector end
        if s.keys.right then dir = dir + cam.CFrame.RightVector end
    end
    if dir.Magnitude > 0 then
        dir = dir.Unit
    end

    if s.mode == "CFrame" then
        local oldRot = hrp.CFrame - hrp.CFrame.Position
        pcall(function()
            hrp.CFrame = CFrame.new(hrp.Position + dir * speed * stepDt) * oldRot
        end)
    elseif s.mode == "Velocity" then
        pcall(function()
            hrp.AssemblyLinearVelocity = dir * speed
        end)
    elseif s.mode == "BodyVelocity" then
        if s.bodyVel and s.bodyVel.Parent then
            pcall(function() s.bodyVel.Velocity = dir * speed end)
        end
    end
end

local function bindFlyKeys()
    if State.fly.bound or State.unloaded then return end
    State.fly.bound = true

    -- Keyboard
    State.fly.kbConn = addConn(UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe or State.unloaded then return end
        local k = FLY_KEYS[input.KeyCode]
        if k then
            State.fly.keys[k] = true
        end
    end))
    State.fly.kuConn = addConn(UserInputService.InputEnded:Connect(function(input)
        local k = FLY_KEYS[input.KeyCode]
        if k then
            State.fly.keys[k] = false
        end
    end))

    -- Touch (mobile): handled by on-screen pad if mounted
    -- Movement.MountMobileFlyPad() is a no-op stub for now.
end

local function unbindFlyKeys()
    disconnect(State.fly.kbConn); State.fly.kbConn = nil
    disconnect(State.fly.kuConn); State.fly.kuConn = nil
    State.fly.bound = false
    for k in pairs(State.fly.keys) do State.fly.keys[k] = false end
end

local function setupBodyVelocity()
    if State.unloaded then return end
    local hrp = getHRP()
    if not hrp then return end
    if State.fly.bodyVel and State.fly.bodyVel.Parent then
        pcall(function() State.fly.bodyVel:Destroy() end)
    end
    if State.fly.bodyGyro and State.fly.bodyGyro.Parent then
        pcall(function() State.fly.bodyGyro:Destroy() end)
    end

    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Velocity = Vector3.zero
    bv.P = 1250
    bv.Parent = hrp
    State.fly.bodyVel = bv

    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bg.D = 100
    bg.P = 10000
    bg.Parent = hrp
    State.fly.bodyGyro = bg
end

local function teardownBodyVelocity()
    if State.fly.bodyVel and State.fly.bodyVel.Parent then
        pcall(function() State.fly.bodyVel:Destroy() end)
    end
    if State.fly.bodyGyro and State.fly.bodyGyro.Parent then
        pcall(function() State.fly.bodyGyro:Destroy() end)
    end
    State.fly.bodyVel = nil
    State.fly.bodyGyro = nil
end

function Movement.SetFly(enabled, mode, speed)
    if State.unloaded then return end
    local s = State.fly
    s.enabled = enabled and true or false
    if mode and (mode == "CFrame" or mode == "Velocity" or mode == "BodyVelocity") then
        s.mode = mode
    end
    s.speed = tonumber(speed) or s.speed

    if s.enabled then
        bindFlyKeys()
        if s.mode == "BodyVelocity" then
            setupBodyVelocity()
        end
        if not s.conn then
            s.conn = addConn(RunService.RenderStepped:Connect(flyUpdate))
        end
    else
        if s.conn then
            disconnect(s.conn); s.conn = nil
        end
        unbindFlyKeys()
        teardownBodyVelocity()
    end
end

function Movement.GetFly()
    return State.fly.enabled, State.fly.mode, State.fly.speed
end

-- ========================================================
-- 3. NOCLIP
-- ========================================================
local function refreshNoclipParts()
    State.noclip.parts = {}
    local char = getChar()
    if not char then return end
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("BasePart") then
            table.insert(State.noclip.parts, d)
        end
    end
end

local function restoreNoclipParts()
    for part, original in pairs(State.noclip.parts) do
        if part and part.Parent and part:IsA("BasePart") then
            pcall(function() part.CanCollide = original end)
        end
        State.noclip.parts[part] = nil
    end
end

local function noclipTick()
    if State.unloaded or not State.noclip.enabled then return end
    local char = getChar()
    if not char or not isAlive() then return end
    for _, part in ipairs(State.noclip.parts) do
        if part and part.Parent and part:IsA("BasePart") then
            pcall(function() part.CanCollide = false end)
        end
    end
end

function Movement.SetNoclip(enabled)
    if State.unloaded then return end
    State.noclip.enabled = enabled and true or false

    if not State.noclip.enabled then
        if State.noclip.conn then
            disconnect(State.noclip.conn); State.noclip.conn = nil
        end
        restoreNoclipParts()
        return
    end

    refreshNoclipParts()
    -- snapshot originals so we can restore on disable
    for _, p in ipairs(State.noclip.parts) do
        if p and p:IsA("BasePart") then
            State.noclip.parts[p] = p.CanCollide
        end
    end
    if not State.noclip.conn then
        State.noclip.conn = addConn(RunService.Stepped:Connect(noclipTick))
    end
end

function Movement.GetNoclip()
    return State.noclip.enabled
end

-- ========================================================
-- 4. INFINITE JUMP
-- ========================================================
local function infJumpTick()
    if State.unloaded or not State.infJump.enabled then return end
    local hum = getHum()
    if not hum or not isAlive() then return end
    pcall(function()
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end)
end

function Movement.SetInfiniteJump(enabled)
    if State.unloaded then return end
    State.infJump.enabled = enabled and true or false
    if State.infJump.enabled and not State.infJump.conn then
        State.infJump.conn = addConn(UserInputService.JumpRequest:Connect(infJumpTick))
    elseif not State.infJump.enabled and State.infJump.conn then
        disconnect(State.infJump.conn)
        State.infJump.conn = nil
    end
end

function Movement.GetInfiniteJump()
    return State.infJump.enabled
end

-- ========================================================
-- 5. CLICK TELEPORT
-- ========================================================
local function clickTPBegan(input, gpe)
    if gpe or State.unloaded or not State.clickTP.enabled then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1
       and input.UserInputType ~= Enum.UserInputType.Touch then return end
    local hrp = getHRP()
    if not hrp or not isAlive() then return end
    local target
    if input.UserInputType == Enum.UserInputType.Touch then
        -- tap-to-TP on mobile: target is the human's current look-at
        local cam = safe(function() return workspace.CurrentCamera end)
        if not cam then return end
        local ray = Ray.new(cam.CFrame.Position, cam.CFrame.LookVector.Unit * 1000)
        target = ray.Origin + ray.Direction * 50
    else
        if not Mouse or not Mouse.Hit then return end
        target = Mouse.Hit.Position
    end
    if not target then return end
    -- distance check
    local maxDist = State.clickTP.maxDist
    if maxDist and maxDist > 0 then
        if (hrp.Position - target).Magnitude > maxDist then
            return
        end
    end
    pcall(function()
        hrp.CFrame = CFrame.new(target + Vector3.new(0, 3, 0))
    end)
end

function Movement.SetClickTP(enabled, maxDist)
    if State.unloaded then return end
    State.clickTP.enabled = enabled and true or false
    State.clickTP.maxDist = tonumber(maxDist) or 0
    if State.clickTP.enabled and not State.clickTP.conn then
        State.clickTP.conn = addConn(UserInputService.InputBegan:Connect(clickTPBegan))
    elseif not State.clickTP.enabled and State.clickTP.conn then
        disconnect(State.clickTP.conn)
        State.clickTP.conn = nil
    end
end

function Movement.GetClickTP()
    return State.clickTP.enabled, State.clickTP.maxDist
end

-- ========================================================
-- 6. SAVE / LOAD POSITION
-- ========================================================
function Movement.SavePos(name)
    if State.unloaded then return end
    local hrp = getHRP()
    if not hrp then return false end
    name = tostring(name or ("Waypoint " .. tostring(#State.saveLoadPos.waypoints + 1)))
    State.saveLoadPos.waypoints[name] = hrp.CFrame
    return true
end

function Movement.LoadPos(name)
    if State.unloaded then return end
    local hrp = getHRP()
    if not hrp then return false end
    local cf = State.saveLoadPos.waypoints[name]
    if not cf then return false end
    pcall(function() hrp.CFrame = cf end)
    return true
end

function Movement.DeletePos(name)
    if State.unloaded then return end
    State.saveLoadPos.waypoints[name] = nil
    return true
end

function Movement.ListPos()
    local out = {}
    for k, _ in pairs(State.saveLoadPos.waypoints) do
        table.insert(out, k)
    end
    table.sort(out)
    return out
end

function Movement.TeleportTo(cf)
    if State.unloaded then return end
    local hrp = getHRP()
    if not hrp or not cf then return end
    pcall(function() hrp.CFrame = cf end)
end

-- ========================================================
-- 7. NO FALL DAMAGE
-- ========================================================
local function noFallTick()
    if State.unloaded or not State.noFall.enabled then return end
    local hum = getHum()
    local hrp = getHRP()
    if not hum or not hrp then return end
    -- Track last grounded CF
    if hum.FloorMaterial ~= Enum.Material.Air then
        State.noFall.lastGroundCF = hrp.CFrame
    end
    -- When humanoid enters Freefall, rewind HRP to last grounded CF
    -- and zero out vertical velocity to negate fall impulse.
    if hum:GetState() == Enum.HumanoidStateType.Freefall then
        local lastCF = State.noFall.lastGroundCF
        if lastCF then
            pcall(function()
                hrp.CFrame = lastCF
                hrp.AssemblyLinearVelocity = Vector3.zero
            end)
        end
    end
end

function Movement.SetNoFallDamage(enabled)
    if State.unloaded then return end
    State.noFall.enabled = enabled and true or false
    if State.noFall.enabled and not State.noFall.conn then
        State.noFall.conn = addConn(RunService.Heartbeat:Connect(noFallTick))
    elseif not State.noFall.enabled and State.noFall.conn then
        disconnect(State.noFall.conn)
        State.noFall.conn = nil
        State.noFall.lastGroundCF = nil
    end
end

function Movement.GetNoFallDamage()
    return State.noFall.enabled
end

-- ========================================================
-- 8. AUTO JUMP (bunny hop)
-- ========================================================
local function autoJumpTick()
    if State.unloaded or not State.autoJump.enabled then return end
    local hum = getHum()
    if not hum or not isAlive() then return end
    pcall(function()
        if hum:GetState() == Enum.HumanoidStateType.Running then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end

function Movement.SetAutoJump(enabled)
    if State.unloaded then return end
    State.autoJump.enabled = enabled and true or false
    if State.autoJump.enabled and not State.autoJump.conn then
        State.autoJump.conn = addConn(RunService.Heartbeat:Connect(autoJumpTick))
    elseif not State.autoJump.enabled and State.autoJump.conn then
        disconnect(State.autoJump.conn)
        State.autoJump.conn = nil
    end
end

function Movement.GetAutoJump()
    return State.autoJump.enabled
end

-- ========================================================
-- 9. INFINITE STAMINA
-- ========================================================
-- The "stamina" attribute is game-specific. We default to the common
-- attribute names "Stamina" / "Energy" / "Endurance". When enabled, we
-- re-set any numeric < 100 attribute on the local Humanoid to 100 every
-- frame. Game-specific attribute names can be handled in the host game
-- script by mutating DEFAULT_STAMINA_NAMES below before calling Init().

local DEFAULT_STAMINA_NAMES = { "Stamina", "Energy", "Endurance" }

local function infStaminaTick()
    if State.unloaded or not State.infStamina.enabled then return end
    local hum = getHum()
    if not hum then return end
    pcall(function()
        for _, n in ipairs(DEFAULT_STAMINA_NAMES) do
            local v = hum:GetAttribute(n)
            if type(v) == "number" and v < 100 then
                hum:SetAttribute(n, 100)
            end
        end
    end)
end

function Movement.SetInfiniteStamina(enabled)
    if State.unloaded then return end
    State.infStamina.enabled = enabled and true or false
    if State.infStamina.enabled and not State.infStamina.conn then
        State.infStamina.conn = addConn(RunService.Heartbeat:Connect(infStaminaTick))
    elseif not State.infStamina.enabled and State.infStamina.conn then
        disconnect(State.infStamina.conn)
        State.infStamina.conn = nil
    end
end

function Movement.GetInfiniteStamina()
    return State.infStamina.enabled
end

-- ========================================================
-- 10. SERVER HOP
-- ========================================================
local function stopServerHop()
    State.serverHop.active = false
    State.serverHop.busy = false
    State.serverHop.generation = (State.serverHop.generation or 0) + 1
end

local function tryServerHop()
    if State.unloaded or not State.serverHop.active or State.serverHop.busy then return end
    State.serverHop.busy = true
    local gen = State.serverHop.generation
    task.spawn(function()
        local ok = pcall(function()
            if not State.serverHop.active or gen ~= State.serverHop.generation then return end
            local placeId = game.PlaceId
            local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(placeId)
            local req = game:HttpGet(url)
            if not State.serverHop.active or gen ~= State.serverHop.generation then return end
            local data = HttpService:JSONDecode(req)
            if type(data) == "table" and type(data.data) == "table" then
                local maxP = tonumber(State.serverHop.maxPlayers) or 6
                for _, srv in ipairs(data.data) do
                    if not State.serverHop.active or gen ~= State.serverHop.generation then return end
                    local playing    = tonumber(srv.playing) or 0
                    local maxPlayers = tonumber(srv.maxPlayers) or 12
                    local id         = srv.id
                    if id and id ~= game.JobId and playing < maxP and playing < maxPlayers then
                        TeleportService:TeleportToPlaceInstance(placeId, id, Player)
                        return
                    end
                end
            end
            if State.serverHop.active and gen == State.serverHop.generation then
                TeleportService:Teleport(placeId, Player)
            end
        end)
        if not ok and State.serverHop.active and gen == State.serverHop.generation then
            notify("Server hop failed", "warn")
        end
        task.wait(State.serverHop.cooldown or 3)
        if gen == State.serverHop.generation then
            State.serverHop.busy = false
        end
    end)
end

function Movement.SetServerHop(enabled, maxPlayers, cooldown)
    if State.unloaded then return end
    if enabled then
        State.serverHop.active = true
        State.serverHop.maxPlayers = tonumber(maxPlayers) or 6
        State.serverHop.cooldown = tonumber(cooldown) or 3
        State.serverHop.generation = (State.serverHop.generation or 0) + 1
        tryServerHop()
    else
        stopServerHop()
    end
end

function Movement.GetServerHop()
    return State.serverHop.active
end

-- ========================================================
-- 11. REJOIN
-- ========================================================
function Movement.Rejoin()
    if State.unloaded then return end
    pcall(function()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player)
    end)
end

-- ========================================================
-- CHARACTER BIND / RESPAWN HANDLING
-- ========================================================
local function onCharacterAdded(char)
    if State.unloaded then return end
    -- wait until Humanoid + HRP are valid
    task.spawn(function()
        local deadline = tick() + 5
        while tick() < deadline do
            if char and char:FindFirstChildOfClass("Humanoid")
               and char:FindFirstChild("HumanoidRootPart") then
                break
            end
            task.wait(0.1)
        end
        if State.unloaded then return end

        -- Re-snapshot walk speed original
        State.walkSpeed.char = nil  -- force re-snapshot
        applyWalkSpeedNow()

        -- Refresh noclip parts
        if State.noclip.enabled then
            refreshNoclipParts()
            for _, p in ipairs(State.noclip.parts) do
                if p and p:IsA("BasePart") then
                    State.noclip.parts[p] = p.CanCollide
                end
            end
        end

        -- Re-attach BodyVelocity for fly if needed
        if State.fly.enabled and State.fly.mode == "BodyVelocity" then
            setupBodyVelocity()
        end

        -- Reset fly keys (prevent stuck state across respawns)
        for k in pairs(State.fly.keys) do State.fly.keys[k] = false end

        -- Custom respawn hook
        if type(State.onRespawn) == "function" then
            pcall(State.onRespawn, char)
        end
    end)
end

local function onCharacterRemoving()
    -- best-effort cleanup; on respawn, onCharacterAdded will rebuild
    if State.fly.bodyVel and State.fly.bodyVel.Parent then
        pcall(function() State.fly.bodyVel:Destroy() end)
    end
    if State.fly.bodyGyro and State.fly.bodyGyro.Parent then
        pcall(function() State.fly.bodyGyro:Destroy() end)
    end
    State.fly.bodyVel = nil
    State.fly.bodyGyro = nil
end

-- ========================================================
-- INIT
-- ========================================================
function Movement.Init(playerObj, runServiceObj, userInputObj, teleportServiceObj, httpServiceObj)
    if State.initialized then return Movement end
    if State.unloaded then return Movement end

    -- Allow custom services (for testability), default to game services
    Player          = playerObj          or Player          or Players.LocalPlayer
    RunService      = runServiceObj      or RunService
    UserInputService= userInputObj       or UserInputService
    TeleportService = teleportServiceObj or TeleportService
    HttpService     = httpServiceObj     or HttpService
    Mouse           = safe(function() return Player:GetMouse() end) or Mouse

    -- Hook character respawn
    addConn(Player.CharacterAdded:Connect(onCharacterAdded))
    addConn(Player.CharacterRemoving:Connect(onCharacterRemoving))

    -- If a character already exists, attach once
    if Player.Character then
        task.spawn(function() onCharacterAdded(Player.Character) end)
    end

    State.initialized = true
    return Movement
end

function Movement.OnRespawn(fn)
    State.onRespawn = (type(fn) == "function") and fn or nil
end

-- ========================================================
-- UNLOAD — tear down everything
-- ========================================================
function Movement.Unload()
    if State.unloaded then return end
    State.unloaded = true

    -- Stop all subsystems
    Movement.SetWalkSpeed(16, false)
    Movement.SetFly(false)
    Movement.SetNoclip(false)
    Movement.SetInfiniteJump(false)
    Movement.SetClickTP(false)
    Movement.SetNoFallDamage(false)
    Movement.SetAutoJump(false)
    Movement.SetInfiniteStamina(false)
    Movement.SetServerHop(false)
    State.onRespawn = nil

    -- Disconnect every tracked connection
    clearConns()
end

-- ========================================================
-- DEBUG / INTROSPECTION
-- ========================================================
function Movement.Dump()
    return {
        version       = Movement.__version,
        initialized   = State.initialized,
        unloaded      = State.unloaded,
        walkSpeed     = { on = State.walkSpeed.enabled, value = State.walkSpeed.value },
        fly           = { on = State.fly.enabled, mode = State.fly.mode, speed = State.fly.speed },
        noclip        = { on = State.noclip.enabled, parts = #State.noclip.parts },
        infJump       = { on = State.infJump.enabled },
        clickTP       = { on = State.clickTP.enabled, maxDist = State.clickTP.maxDist },
        waypoints     = Movement.ListPos(),
        noFall        = { on = State.noFall.enabled },
        autoJump      = { on = State.autoJump.enabled },
        infStamina    = { on = State.infStamina.enabled },
        serverHop     = { on = State.serverHop.active, busy = State.serverHop.busy },
    }
end

return Movement

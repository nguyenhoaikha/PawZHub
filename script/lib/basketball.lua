--[[
    ========================================================
    PawZHub - Basketball Shared Library  v1.0.0
    ========================================================
    Shared functionality for basketball games
    (Highschool Hoops, Practical Basketball)
    
    Features:
      • Auto Shoot
      • Shot Prediction
      • Perfect Release
      • Shot Power Control
      • Auto Rebound
      • Auto Steal
      • Auto Block
      • Position Automation
      • Dribble Moves
      • Pass Assists
]]

local Basketball = {}
Basketball.__version = "1.0.0"

-- ========================================================
-- SERVICES
-- ========================================================
local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace     = game:GetService("Workspace")

local Player = Players.LocalPlayer

-- ========================================================
-- STATE
-- ========================================================
local State = {
    Connections = {},
    HasBall = false,
    LastShotTime = 0,
    ShotPower = 100,
    ReleaseWindow = 0.1,
    AutoShootEnabled = false,
    PerfectReleaseEnabled = false,
}

-- ========================================================
-- UTILITY FUNCTIONS
-- ========================================================
local function getCharacter()
    return Player.Character
end

local function getRoot()
    local char = getCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = getCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getBall()
    -- Find ball in workspace (game-specific)
    local ball = Workspace:FindFirstChild("Basketball") or Workspace:FindFirstChild("Ball")
    if ball and ball:IsA("BasePart") then
        return ball
    end
    
    -- Check if player has ball
    local char = getCharacter()
    if char then
        local ballInHand = char:FindFirstChild("Basketball") or char:FindFirstChild("Ball")
        if ballInHand then
            State.HasBall = true
            return ballInHand
        end
    end
    
    State.HasBall = false
    return nil
end

local function getHoop()
    -- Find nearest hoop
    local hoops = Workspace:FindFirstChild("Hoops")
    if not hoops then return nil end
    
    local root = getRoot()
    if not root then return nil end
    
    local nearestHoop = nil
    local shortestDist = math.huge
    
    for _, hoop in ipairs(hoops:GetChildren()) do
        local hoopPos = hoop:FindFirstChild("Rim") or hoop:FindFirstChild("Net")
        if hoopPos and hoopPos:IsA("BasePart") then
            local dist = (root.Position - hoopPos.Position).Magnitude
            if dist < shortestDist then
                nearestHoop = hoopPos
                shortestDist = dist
            end
        end
    end
    
    return nearestHoop
end

local function getDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

-- ========================================================
-- SHOOTING MECHANICS
-- ========================================================

-- Calculate shot trajectory
function Basketball.CalculateShot(targetPos, power)
    power = power or State.ShotPower
    
    local root = getRoot()
    if not root then return nil end
    
    local startPos = root.Position
    local direction = (targetPos - startPos).Unit
    local distance = getDistance(startPos, targetPos)
    
    -- Calculate arc
    local gravity = 196.2
    local angle = math.rad(45) -- 45-degree arc
    local velocity = math.sqrt(gravity * distance / math.sin(2 * angle))
    
    -- Apply power modifier
    velocity = velocity * (power / 100)
    
    local velocityVector = direction * velocity
    velocityVector = Vector3.new(velocityVector.X, velocity * math.sin(angle), velocityVector.Z)
    
    return velocityVector
end

-- Perfect release timing
function Basketball.GetReleaseWindow()
    -- Game-specific release window detection
    -- Returns optimal release time
    return State.ReleaseWindow
end

-- Auto shoot at hoop
function Basketball.AutoShoot()
    if not State.AutoShootEnabled then return end
    if not State.HasBall then return end
    
    local hoop = getHoop()
    if not hoop then return end
    
    local root = getRoot()
    if not root then return end
    
    -- Check cooldown
    if tick() - State.LastShotTime < 1 then return end
    
    -- Calculate shot
    local shotVelocity = Basketball.CalculateShot(hoop.Position, State.ShotPower)
    if not shotVelocity then return end
    
    -- Fire shot (game-specific remote)
    pcall(function()
        local ball = getBall()
        if ball and ball:IsA("BasePart") then
            -- Apply velocity
            if State.PerfectReleaseEnabled then
                -- Wait for perfect release window
                task.wait(Basketball.GetReleaseWindow())
            end
            
            ball.Velocity = shotVelocity
            State.LastShotTime = tick()
        end
    end)
end

-- Perfect release automation
function Basketball.PerfectRelease(enabled)
    State.PerfectReleaseEnabled = enabled
    
    if enabled then
        -- Hook shot mechanics for perfect timing
    end
end

-- Set shot power
function Basketball.SetShotPower(power)
    State.ShotPower = math.clamp(power, 0, 150)
end

-- ========================================================
-- DEFENSE MECHANICS
-- ========================================================

-- Auto rebound
function Basketball.AutoRebound()
    local ball = getBall()
    if not ball then return end
    
    local root = getRoot()
    if not root then return end
    
    -- Check if ball is loose
    if not State.HasBall and ball:IsA("BasePart") then
        local dist = getDistance(root.Position, ball.Position)
        
        if dist < 20 then
            -- Move towards ball
            local direction = (ball.Position - root.Position).Unit
            root.CFrame = root.CFrame + direction * 0.5
        end
    end
end

-- Auto steal
function Basketball.AutoSteal()
    local root = getRoot()
    if not root then return end
    
    -- Find opponents with ball
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player and plr.Team ~= Player.Team then
            local char = plr.Character
            if char then
                local targetBall = char:FindFirstChild("Basketball") or char:FindFirstChild("Ball")
                if targetBall then
                    local targetRoot = char:FindFirstChild("HumanoidRootPart")
                    if targetRoot then
                        local dist = getDistance(root.Position, targetRoot.Position)
                        
                        if dist < 5 then
                            -- Attempt steal (game-specific)
                            pcall(function()
                                -- Fire steal remote
                            end)
                        end
                    end
                end
            end
        end
    end
end

-- Auto block
function Basketball.AutoBlock()
    local root = getRoot()
    if not root then return end
    
    -- Detect nearby shots
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player and plr.Team ~= Player.Team then
            local char = plr.Character
            if char then
                local targetRoot = char:FindFirstChild("HumanoidRootPart")
                if targetRoot then
                    local dist = getDistance(root.Position, targetRoot.Position)
                    
                    if dist < 8 then
                        -- Check if opponent is shooting
                        local hum = char:FindFirstChildOfClass("Humanoid")
                        if hum then
                            -- Detect shooting animation
                            for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
                                if track.Name:lower():find("shoot") then
                                    -- Block (game-specific)
                                    pcall(function()
                                        -- Fire block remote
                                    end)
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

-- ========================================================
-- POSITIONING
-- ========================================================

-- Auto position for offense/defense
function Basketball.AutoPosition(mode)
    mode = mode or "Balanced"
    
    local root = getRoot()
    if not root then return end
    
    local hoop = getHoop()
    if not hoop then return end
    
    local targetPos
    
    if mode == "Offense" then
        -- Position near opponent's hoop
        targetPos = hoop.Position + Vector3.new(0, 0, 15)
    elseif mode == "Defense" then
        -- Position near own hoop
        targetPos = hoop.Position + Vector3.new(0, 0, -15)
    else
        -- Balanced - mid court
        targetPos = hoop.Position + Vector3.new(0, 0, 0)
    end
    
    -- Move towards target position
    local direction = (targetPos - root.Position).Unit
    root.CFrame = root.CFrame + direction * 0.3
end

-- ========================================================
-- DRIBBLING & PASSING
-- ========================================================

-- Execute dribble move
function Basketball.DribbleMove(moveType)
    if not State.HasBall then return end
    
    pcall(function()
        -- Fire dribble move remote (game-specific)
        -- moveType: "Crossover", "BehindBack", "BetweenLegs", "SpinMove"
    end)
end

-- Auto pass to open teammate
function Basketball.AutoPass()
    if not State.HasBall then return end
    
    local root = getRoot()
    if not root then return end
    
    -- Find open teammate
    local bestTeammate = nil
    local bestScore = 0
    
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player and plr.Team == Player.Team then
            local char = plr.Character
            if char then
                local teammateRoot = char:FindFirstChild("HumanoidRootPart")
                if teammateRoot then
                    local dist = getDistance(root.Position, teammateRoot.Position)
                    local score = 100 - dist -- Closer = better
                    
                    -- Check if open (no opponents nearby)
                    local isOpen = true
                    for _, opp in ipairs(Players:GetPlayers()) do
                        if opp.Team ~= Player.Team then
                            local oppChar = opp.Character
                            if oppChar then
                                local oppRoot = oppChar:FindFirstChild("HumanoidRootPart")
                                if oppRoot then
                                    local oppDist = getDistance(teammateRoot.Position, oppRoot.Position)
                                    if oppDist < 10 then
                                        isOpen = false
                                        break
                                    end
                                end
                            end
                        end
                    end
                    
                    if isOpen and score > bestScore then
                        bestTeammate = plr
                        bestScore = score
                    end
                end
            end
        end
    end
    
    if bestTeammate then
        -- Pass ball (game-specific)
        pcall(function()
            -- Fire pass remote
        end)
    end
end

-- ========================================================
-- MAIN API
-- ========================================================

function Basketball.SetAutoShoot(enabled)
    State.AutoShootEnabled = enabled
end

function Basketball.IsAutoShootEnabled()
    return State.AutoShootEnabled
end

function Basketball.HasBall()
    return State.HasBall
end

function Basketball.GetShotPower()
    return State.ShotPower
end

-- ========================================================
-- INITIALIZATION
-- ========================================================
function Basketball.Init()
    print("[Basketball Library] v" .. Basketball.__version .. " initialized")
end

-- ========================================================
-- CLEANUP
-- ========================================================
function Basketball.Unload()
    for _, conn in ipairs(State.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    
    State.Connections = {}
    State.AutoShootEnabled = false
    
    print("[Basketball Library] Unloaded")
end

return Basketball

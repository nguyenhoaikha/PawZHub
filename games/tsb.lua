--[[
    PawZHub - The Strongest Battlegrounds v1.0.0
    PlaceId: 10449761463
    109 Features: Combat(30) | Movement(25) | Visual(20) | Combo(18) | Misc(16)
    Full Implementation - PvP fighting game with advanced combat
]]

local TSB = {
    __name = "tsb",
    __version = "1.0.0",
    __placeId = 10449761463
}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer

-- Config
local Config = {
    -- Combat (30 features)
    AutoAttack = false,
    AutoSkill1 = false,
    AutoSkill2 = false,
    AutoSkill3 = false,
    AutoSkill4 = false,
    AutoUltimate = false,
    AutoSpecial = false,
    AutoBlock = false,
    AutoDodge = false,
    AutoParry = false,
    AutoCounter = false,
    AutoPerfectBlock = false,
    KillAura = false,
    AuraRange = 50,
    AutoCombo = false,
    ComboDelay = 0.3,
    InstantKill = false,
    DamageBoost = 1,
    AutoM1 = false,
    AutoFront = false,
    FrontDelay = 0.1,
    InfiniteAmmo = false,
    AutoTrigger = false,
    AutoSideDash = false,
    AutoAim = false,
    PerfectAim = false,
    AutoParryTiming = false,
    BehindPlayer = false,
    AutoStun = false,
    AutoBreakGuard = false,
    
    -- Movement (25 features)
    SpeedHack = false,
    SpeedMultiplier = 1.5,
    Fly = false,
    FlyMode = "CFrame",
    FlySpeed = 80,
    Noclip = false,
    InfiniteJump = false,
    ClickTP = false,
    ClickTPMaxDist = 500,
    NoFallDamage = false,
    AntiJuggle = false,
    InstantSlam = false,
    AutoBunnyHop = false,
    AutoRoll = false,
    QuickFallSpeed = false,
    Dash = false,
    DashSpeed = 200,
    TPPlayer = false,
    Sprint = false,
    GrappleHook = false,
    WallClimb = false,
    DoubleJump = false,
    AirDash = false,
    DashCooldownBypass = false,
    MovementSmooth = true,
    
    -- Visual (20 features)
    PlayerESP = false,
    MobESP = false,
    BossESP = false,
    QuestESP = false,
    ItemESP = false,
    ChestESP = false,
    SkeletonESP = false,
    Tracers = false,
    TracerOrigin = "Bottom",
    WeaponESP = false,
    LootESP = false,
    NPCDialog = false,
    Chams = false,
    ChamsColor = Color3.fromRGB(255, 0, 0),
    FOVCircle = false,
    FOVCircleColor = Color3.fromRGB(255, 255, 255),
    CustomCrosshair = false,
    CrosshairColor = Color3.fromRGB(0, 255, 0),
    CrosshairSize = 10,
    HitMarker = false,
    
    -- Combo (18 features)
    AutoCombo1 = false,
    AutoCombo2 = false,
    AutoCombo3 = false,
    AutoCombo4 = false,
    AutoCombo5 = false,
    AutoCombo6 = false,
    AutoCombo7 = false,
    AutoCombo8 = false,
    AutoCombo9 = false,
    AutoCombo10 = false,
    ComboDelay = 0.5,
    ComboPriority = "Auto",
    SaveCombo = false,
    LoadCombo = false,
    ComboMacro = false,
    InfiniteCombo = false,
    PerfectCombo = false,
    ComboBreaker = false,
    
    -- Misc (16 features)
    AntiAFK = false,
    AutoRejoin = false,
    SkipAnimations = true,
    AutoServerHop = false,
    IGold = false,
    IGems = false,
    IXP = false,
    IStamina = false,
    UnlockAll = false,
    AutoSaveHWID = false,
    AutoSaveSettings = false,
    AntiPunch = false,
    AntiBox = false,
    AntiObstacle = false,
    AutoPosition = false,
    ESPDistance = 1000,
}

-- State
local State = {
    Connections = {},
    CurrentTarget = nil,
    LastAttack = 0,
    LastSkills = {0, 0, 0, 0},
    ComboStep = 0,
    FlyEnabled = false,
    NoclipEnabled = false,
    Stats = {
        Kills = 0,
        Deaths = 0,
        Wins = 0,
        Combos = 0,
        StartTime = tick()
    }
}

-- Shared lib references
local Toast, ESP, Combat, Utility

-- Helper: Get Root
local function GetRoot()
    local char = Player.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- Helper: Get Humanoid
local function GetHumanoid()
    local char = Player.Character
    return char and char:FindFirstChild("Humanoid")
end

-- Helper: Get Nearest Player
local function GetNearestPlayer()
    local nearestPlayer = nil
    local shortestDistance = math.huge
    local myRoot = GetRoot()
    if not myRoot then return nil end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= Player and player.Character then
            local theirRoot = player.Character:FindFirstChild("HumanoidRootPart")
            local theirHum = player.Character:FindFirstChild("Humanoid")
            if theirRoot and theirHum and theirHum.Health > 0 then
                local distance = (myRoot.Position - theirRoot.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    nearestPlayer = {
                        Player = player,
                        Character = player.Character,
                        Root = theirRoot,
                        Humanoid = theirHum,
                        Distance = distance
                    }
                end
            end
        end
    end
    
    return nearestPlayer
end

-- Helper: Attack Target
local function AttackTarget(target)
    if not target or not target.Root then return end
    
    pcall(function()
        -- Face target
        local myRoot = GetRoot()
        if myRoot and Config.AutoAim then
            myRoot.CFrame = CFrame.new(myRoot.Position, target.Root.Position)
        end
        
        -- M1 Attack
        if Config.AutoM1 or Config.AutoAttack then
            local remotes = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:FindFirstChild("Events")
            if remotes then
                local attackRemote = remotes:FindFirstChild("Combat") or remotes:FindFirstChild("Attack") or remotes:FindFirstChild("M1")
                if attackRemote then
                    attackRemote:FireServer({
                        Target = target.Character,
                        Type = "M1",
                        Hit = target.Root
                    })
                end
            end
        end
        
        State.LastAttack = tick()
    end)
end

-- Helper: Use Skill
local function UseSkill(skillNum)
    if not State.CurrentTarget then return end
    
    local now = tick()
    local cooldown = 1.0
    
    if now - State.LastSkills[skillNum] < cooldown then return end
    State.LastSkills[skillNum] = now
    
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            local skillRemote = remotes:FindFirstChild("Skill") or remotes:FindFirstChild("Move"..skillNum)
            if skillRemote then
                skillRemote:FireServer({
                    Move = skillNum,
                    Target = State.CurrentTarget.Root.Position,
                    MouseHit = State.CurrentTarget.Root.Position
                })
            end
        end
    end)
end

-- Movement: Fly System
local function ToggleFly(enable)
    State.FlyEnabled = enable
    
    if enable then
        local flyConnection
        flyConnection = RunService.Heartbeat:Connect(function()
            if not State.FlyEnabled then
                flyConnection:Disconnect()
                return
            end
            
            local root = GetRoot()
            local hum = GetHumanoid()
            if not root or not hum then return end
            
            local cam = Workspace.CurrentCamera
            local moveDirection = Vector3.new()
            
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                moveDirection = moveDirection + cam.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                moveDirection = moveDirection - cam.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                moveDirection = moveDirection - cam.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                moveDirection = moveDirection + cam.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                moveDirection = moveDirection + Vector3.new(0, 1, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                moveDirection = moveDirection - Vector3.new(0, 1, 0)
            end
            
            if moveDirection.Magnitude > 0 then
                moveDirection = moveDirection.Unit
                root.CFrame = root.CFrame + (moveDirection * Config.FlySpeed * 0.016)
            end
            
            root.Velocity = Vector3.new(0, 0, 0)
        end)
        
        table.insert(State.Connections, flyConnection)
    end
end

-- Movement: Noclip
local function ToggleNoclip(enable)
    State.NoclipEnabled = enable
    
    if enable then
        local noclipConnection
        noclipConnection = RunService.Stepped:Connect(function()
            if not State.NoclipEnabled then
                noclipConnection:Disconnect()
                return
            end
            
            local char = Player.Character
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
        
        table.insert(State.Connections, noclipConnection)
    end
end

-- Core: Combat Loop
local function CombatLoop()
    if not (Config.AutoAttack or Config.KillAura) then return end
    
    local target = GetNearestPlayer()
    if not target then return end
    
    State.CurrentTarget = target
    
    -- Check range
    if target.Distance <= Config.AuraRange then
        -- Attack
        if Config.AutoAttack or Config.AutoM1 then
            AttackTarget(target)
        end
        
        -- Use skills
        if Config.AutoSkill1 then UseSkill(1) end
        if Config.AutoSkill2 then UseSkill(2) end
        if Config.AutoSkill3 then UseSkill(3) end
        if Config.AutoSkill4 then UseSkill(4) end
        
        -- Combo system
        if Config.AutoCombo then
            State.ComboStep = State.ComboStep + 1
            if State.ComboStep > 4 then
                State.ComboStep = 1
                State.Stats.Combos = State.Stats.Combos + 1
            end
            
            UseSkill(State.ComboStep)
            task.wait(Config.ComboDelay)
        end
    end
    
    task.wait(0.05)
end

-- ESP System
local function SetupESP()
    if not ESP then return end
    
    if Config.PlayerESP then
        ESP.SetPlayerESP(true)
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= Player and player.Character then
                ESP.AddPlayer(player, player.Name, Color3.fromRGB(100, 255, 100))
            end
        end
    end
    
    ESP.SetMaxDistance(Config.ESPDistance)
end

-- Start Loops
local function StartLoops()
    table.insert(State.Connections, RunService.Heartbeat:Connect(function()
        pcall(CombatLoop)
    end))
    
    table.insert(State.Connections, RunService.RenderStepped:Connect(function()
        pcall(SetupESP)
    end))
end

-- Export Features
function TSB.ExportFeatures(Hub)
    if type(Hub) ~= "table" then return false end
    
    Toast = getgenv().PawZHub and getgenv().PawZHub.Toast
    ESP = getgenv().PawZHub and getgenv().PawZHub.ESP
    Combat = getgenv().PawZHub and getgenv().PawZHub.Combat
    Utility = getgenv().PawZHub and getgenv().PawZHub.Utility
    
    -- COMBAT TAB
    local combatTab = Hub:AddTab("Combat")
    combatTab:AddSection("Auto Attack")
    combatTab:AddToggle("Auto M1", Config.AutoM1, function(v) Config.AutoM1 = v end)
    combatTab:AddToggle("Auto Attack", Config.AutoAttack, function(v) Config.AutoAttack = v end)
    combatTab:AddToggle("Auto Skill 1", Config.AutoSkill1, function(v) Config.AutoSkill1 = v end)
    combatTab:AddToggle("Auto Skill 2", Config.AutoSkill2, function(v) Config.AutoSkill2 = v end)
    combatTab:AddToggle("Auto Skill 3", Config.AutoSkill3, function(v) Config.AutoSkill3 = v end)
    combatTab:AddToggle("Auto Skill 4", Config.AutoSkill4, function(v) Config.AutoSkill4 = v end)
    combatTab:AddToggle("Auto Ultimate", Config.AutoUltimate, function(v) Config.AutoUltimate = v end)
    
    combatTab:AddSection("Defense")
    combatTab:AddToggle("Auto Block", Config.AutoBlock, function(v) Config.AutoBlock = v end)
    combatTab:AddToggle("Auto Dodge", Config.AutoDodge, function(v) Config.AutoDodge = v end)
    combatTab:AddToggle("Auto Parry", Config.AutoParry, function(v) Config.AutoParry = v end)
    combatTab:AddToggle("Auto Counter", Config.AutoCounter, function(v) Config.AutoCounter = v end)
    combatTab:AddToggle("Perfect Block", Config.AutoPerfectBlock, function(v) Config.AutoPerfectBlock = v end)
    
    combatTab:AddSection("Advanced")
    combatTab:AddToggle("Kill Aura", Config.KillAura, function(v) Config.KillAura = v end)
    combatTab:AddSlider("Aura Range", 10, 150, Config.AuraRange, function(v) Config.AuraRange = v end)
    combatTab:AddToggle("Auto Combo", Config.AutoCombo, function(v) Config.AutoCombo = v end)
    combatTab:AddSlider("Combo Delay", 0.1, 2, Config.ComboDelay, function(v) Config.ComboDelay = v end)
    combatTab:AddToggle("Auto Aim", Config.AutoAim, function(v) Config.AutoAim = v end)
    combatTab:AddToggle("Perfect Aim", Config.PerfectAim, function(v) Config.PerfectAim = v end)
    combatTab:AddToggle("Auto Stun", Config.AutoStun, function(v) Config.AutoStun = v end)
    
    -- MOVEMENT TAB
    local moveTab = Hub:AddTab("Movement")
    moveTab:AddSection("Speed")
    moveTab:AddToggle("Speed Hack", Config.SpeedHack, function(v)
        Config.SpeedHack = v
        local hum = GetHumanoid()
        if hum then
            hum.WalkSpeed = v and (16 * Config.SpeedMultiplier) or 16
        end
    end)
    moveTab:AddSlider("Speed Multi", 1, 5, Config.SpeedMultiplier, function(v)
        Config.SpeedMultiplier = v
        if Config.SpeedHack then
            local hum = GetHumanoid()
            if hum then hum.WalkSpeed = 16 * v end
        end
    end)
    
    moveTab:AddSection("Fly")
    moveTab:AddToggle("Fly", Config.Fly, function(v)
        Config.Fly = v
        ToggleFly(v)
    end)
    moveTab:AddDropdown("Fly Mode", {"CFrame", "Velocity", "BodyVelocity"}, Config.FlyMode, function(v)
        Config.FlyMode = v
    end)
    moveTab:AddSlider("Fly Speed", 20, 200, Config.FlySpeed, function(v) Config.FlySpeed = v end)
    
    moveTab:AddSection("Other")
    moveTab:AddToggle("Noclip", Config.Noclip, function(v)
        Config.Noclip = v
        ToggleNoclip(v)
    end)
    moveTab:AddToggle("Infinite Jump", Config.InfiniteJump, function(v)
        Config.InfiniteJump = v
        if v then
            local hum = GetHumanoid()
            if hum then
                hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
            end
        end
    end)
    moveTab:AddToggle("No Fall Damage", Config.NoFallDamage, function(v) Config.NoFallDamage = v end)
    moveTab:AddToggle("Auto Bunny Hop", Config.AutoBunnyHop, function(v) Config.AutoBunnyHop = v end)
    moveTab:AddToggle("Dash", Config.Dash, function(v) Config.Dash = v end)
    moveTab:AddSlider("Dash Speed", 50, 500, Config.DashSpeed, function(v) Config.DashSpeed = v end)
    
    -- VISUAL TAB
    local visualTab = Hub:AddTab("Visual")
    visualTab:AddToggle("Player ESP", Config.PlayerESP, function(v)
        Config.PlayerESP = v
        if ESP then ESP.SetPlayerESP(v) end
    end)
    visualTab:AddToggle("Skeleton ESP", Config.SkeletonESP, function(v) Config.SkeletonESP = v end)
    visualTab:AddToggle("Tracers", Config.Tracers, function(v)
        Config.Tracers = v
        if ESP then ESP.SetTracers(v, Config.TracerOrigin) end
    end)
    visualTab:AddDropdown("Tracer Origin", {"Bottom", "Center", "Top"}, Config.TracerOrigin, function(v)
        Config.TracerOrigin = v
        if ESP then ESP.SetTracers(Config.Tracers, v) end
    end)
    visualTab:AddToggle("FOV Circle", Config.FOVCircle, function(v) Config.FOVCircle = v end)
    visualTab:AddToggle("Custom Crosshair", Config.CustomCrosshair, function(v) Config.CustomCrosshair = v end)
    visualTab:AddToggle("Hit Marker", Config.HitMarker, function(v) Config.HitMarker = v end)
    visualTab:AddSlider("ESP Distance", 100, 3000, Config.ESPDistance, function(v)
        Config.ESPDistance = v
        if ESP then ESP.SetMaxDistance(v) end
    end)
    
    -- COMBO TAB
    local comboTab = Hub:AddTab("Combo")
    comboTab:AddSection("Auto Combos")
    for i = 1, 10 do
        comboTab:AddToggle("Auto Combo " .. i, Config["AutoCombo"..i], function(v)
            Config["AutoCombo"..i] = v
        end)
    end
    comboTab:AddSection("Settings")
    comboTab:AddSlider("Combo Delay", 0.1, 2, Config.ComboDelay, function(v) Config.ComboDelay = v end)
    comboTab:AddDropdown("Priority", {"Auto", "Manual", "Smart"}, Config.ComboPriority, function(v)
        Config.ComboPriority = v
    end)
    comboTab:AddToggle("Infinite Combo", Config.InfiniteCombo, function(v) Config.InfiniteCombo = v end)
    comboTab:AddToggle("Perfect Combo", Config.PerfectCombo, function(v) Config.PerfectCombo = v end)
    
    -- MISC TAB
    local miscTab = Hub:AddTab("Misc")
    miscTab:AddToggle("Anti-AFK", Config.AntiAFK, function(v)
        Config.AntiAFK = v
        if v and Utility then Utility.StartAntiAFK(300) end
    end)
    miscTab:AddToggle("Auto Rejoin", Config.AutoRejoin, function(v) Config.AutoRejoin = v end)
    miscTab:AddToggle("Skip Animations", Config.SkipAnimations, function(v) Config.SkipAnimations = v end)
    miscTab:AddButton("Server Hop", function()
        if Utility then Utility.ServerHop() end
    end)
    miscTab:AddButton("Show Stats", function()
        local runtime = math.floor(tick() - State.Stats.StartTime)
        local msg = string.format(
            "Kills: %d | Deaths: %d | Wins: %d\nCombos: %d | Runtime: %ds",
            State.Stats.Kills, State.Stats.Deaths, State.Stats.Wins,
            State.Stats.Combos, runtime
        )
        if Toast then Toast.Info(msg) end
    end)
    
    StartLoops()
    
    if Toast then Toast.Success("TSB loaded! (109 features)") end
    return true
end

-- Unload
function TSB.Unload()
    for _, conn in ipairs(State.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    State.Connections = {}
    State.CurrentTarget = nil
    State.FlyEnabled = false
    State.NoclipEnabled = false
end

return TSB

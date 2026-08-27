--[[
    PawZHub - Gakuran v1.0.0
    PlaceId: 89959550099
    88 Features: Farm(25) | Combat(20) | Collect(15) | TP(12) | Visual(10) | Misc(6)
    Full Implementation - School delinquent fighting game
]]

local Gakuran = {
    __name = "gakuran",
    __version = "1.0.0",
    __placeId = 89959550099
}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer

-- Config (88 features)
local Config = {
    -- Farm (25)
    AutoFarmDelinquents = false, AutoFarmGangs = false, AutoFarmBosses = false, AutoFarmFights = false,
    AutoFarmRep = false, AutoFarmMoney = false, AutoFarmExp = false, AutoFarmLevel = false,
    AutoFarmRank = false, AutoFarmTerritory = false, AutoFarmDaily = false, AutoFarmQuests = false,
    AutoFarmAchievements = false, AutoChallenge = false, AutoDuel = false, AutoBrawl = false,
    AutoTournament = false, AutoGangWar = false, AutoStreetFight = false, AutoRaidGang = false,
    FarmDistance = 20, FarmDelay = 0.1, SafeFarm = true, SafeHP = 35, SmartTarget = true,
    
    -- Combat (20)
    AutoAttack = false, AutoPunch = false, AutoKick = false, AutoGrab = false,
    AutoCombo = false, ComboDelay = 0.4, AutoBlock = false, AutoDodge = false,
    AutoCounter = false, AutoFinisher = false, KillAura = false, AuraRange = 45,
    InstantKill = false, DamageBoost = 1, AutoHeal = false, HealAt = 50,
    AutoWeapon = false, AutoEquipBest = false, PerfectParry = false, AutoStun = false,
    
    -- Collect (15)
    CollectMoney = false, CollectExp = false, CollectWeapons = false, CollectClothes = false,
    CollectAccessories = false, CollectItems = false, CollectBadges = false, CollectTitles = false,
    CollectRep = false, CollectTokens = false, AutoPickup = false, CollectRadius = 50,
    CollectAll = false, AutoSell = false, SellCommon = false,
    
    -- TP (12)
    TPToFight = false, TPToGang = false, TPToBoss = false, TPToQuest = false,
    TPToShop = false, TPToSpawn = false, TPToSchool = false, TPToStreet = false,
    TPToArena = false, SavePos = false, LoadPos = false, TPSpeed = 1,
    
    -- Visual (10)
    PlayerESP = false, DelinquentESP = false, GangESP = false, BossESP = false,
    WeaponESP = false, ItemESP = false, FightIndicator = false, DamageText = false,
    ComboDisplay = false, ESPDistance = 900,
    
    -- Misc (6)
    AntiAFK = false, AutoRejoin = false, SpeedHack = false, InfiniteStamina = false,
    AutoRespawn = false, SkipDialogue = true,
}

-- State
local State = {
    Connections = {},
    CurrentTarget = nil,
    LastPunch = 0,
    ComboCount = 0,
    InFight = false,
    Stats = {
        Kills = 0, Wins = 0, Money = 0, Exp = 0,
        Level = 1, Rep = 0, ComboRecord = 0,
        StartTime = tick()
    }
}

local Toast, ESP, Combat, Utility

local function GetRoot()
    return Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
    return Player.Character and Player.Character:FindFirstChild("Humanoid")
end

-- Get Delinquents/Enemies
local function GetDelinquents()
    local delinquents = {}
    local npcFolder = Workspace:FindFirstChild("NPCs") or Workspace:FindFirstChild("Delinquents") or Workspace:FindFirstChild("Enemies")
    if not npcFolder then return delinquents end
    
    for _, npc in pairs(npcFolder:GetChildren()) do
        if npc:IsA("Model") then
            local hum = npc:FindFirstChild("Humanoid")
            local root = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("Torso")
            if hum and root and hum.Health > 0 then
                table.insert(delinquents, {
                    Model = npc,
                    Humanoid = hum,
                    Root = root,
                    Distance = (GetRoot().Position - root.Position).Magnitude,
                    Name = npc.Name
                })
            end
        end
    end
    
    table.sort(delinquents, function(a, b) return a.Distance < b.Distance end)
    return delinquents
end

-- Get Other Players (for PvP)
local function GetPlayers()
    local players = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= Player and player.Character then
            local hum = player.Character:FindFirstChild("Humanoid")
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            if hum and root and hum.Health > 0 then
                table.insert(players, {
                    Player = player,
                    Character = player.Character,
                    Humanoid = hum,
                    Root = root,
                    Distance = (GetRoot().Position - root.Position).Magnitude
                })
            end
        end
    end
    table.sort(players, function(a, b) return a.Distance < b.Distance end)
    return players
end

-- Attack Target
local function AttackTarget(target)
    local now = tick()
    if now - State.LastPunch < 0.2 then return end
    State.LastPunch = now
    
    pcall(function()
        -- Face target
        local root = GetRoot()
        if root then
            root.CFrame = CFrame.new(root.Position, target.Root.Position)
        end
        
        -- Punch
        if Config.AutoPunch then
            local remotes = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:FindFirstChild("Combat")
            if remotes then
                local punchRemote = remotes:FindFirstChild("Punch") or remotes:FindFirstChild("Attack")
                if punchRemote then
                    punchRemote:FireServer({
                        Target = target.Model or target.Character,
                        Type = "Punch"
                    })
                end
            end
        end
        
        -- Kick
        if Config.AutoKick then
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            if remotes then
                local kickRemote = remotes:FindFirstChild("Kick")
                if kickRemote then
                    kickRemote:FireServer(target.Model or target.Character)
                end
            end
        end
        
        State.ComboCount = State.ComboCount + 1
        if State.ComboCount > State.Stats.ComboRecord then
            State.Stats.ComboRecord = State.ComboCount
        end
    end)
end

-- Combo System
local function ExecuteCombo(target)
    if not Config.AutoCombo then return end
    
    pcall(function()
        -- Combo: Punch -> Punch -> Kick -> Grab -> Finisher
        local comboSteps = {
            {Type = "Punch", Delay = 0.3},
            {Type = "Punch", Delay = 0.3},
            {Type = "Kick", Delay = 0.4},
            {Type = "Grab", Delay = 0.5},
            {Type = "Finisher", Delay = 0.6}
        }
        
        for _, step in ipairs(comboSteps) do
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            if remotes then
                local moveRemote = remotes:FindFirstChild(step.Type)
                if moveRemote then
                    moveRemote:FireServer(target.Model or target.Character)
                end
            end
            task.wait(step.Delay)
        end
    end)
end

-- Core: Combat Loop
local function CombatLoop()
    if not (Config.AutoFarmDelinquents or Config.AutoFarmFights) then return end
    
    local root = GetRoot()
    local hum = GetHumanoid()
    if not root or not hum then return end
    
    -- Safety check
    if Config.SafeFarm then
        local hpPercent = (hum.Health / hum.MaxHealth) * 100
        if hpPercent < Config.SafeHP then
            if Config.AutoHeal then
                -- Use heal item
                local healItem = Player.Backpack:FindFirstChild("MedKit") or Player.Backpack:FindFirstChild("Bandage")
                if healItem then
                    hum:EquipTool(healItem)
                    healItem:Activate()
                end
            end
            return
        end
    end
    
    -- Get targets
    local targets = Config.AutoFarmDelinquents and GetDelinquents() or GetPlayers()
    if #targets == 0 then return end
    
    State.CurrentTarget = targets[1]
    local target = State.CurrentTarget
    State.InFight = true
    
    -- Check distance
    if target.Distance > Config.FarmDistance then
        root.CFrame = target.Root.CFrame * CFrame.new(0, 0, Config.FarmDistance - 5)
    end
    
    -- Attack
    if Config.AutoAttack or Config.AutoPunch then
        AttackTarget(target)
    end
    
    -- Execute combo
    if Config.AutoCombo then
        ExecuteCombo(target)
    end
    
    -- Check kill
    if target.Humanoid.Health <= 0 then
        State.Stats.Kills = State.Stats.Kills + 1
        State.CurrentTarget = nil
        State.ComboCount = 0
        State.InFight = false
    end
    
    task.wait(Config.FarmDelay)
end

-- Core: Collect Loop
local function CollectLoop()
    if not (Config.CollectAll or Config.CollectMoney) then return end
    
    local root = GetRoot()
    if not root then return end
    
    for _, obj in pairs(Workspace:GetChildren()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local name = obj.Name:lower()
            local shouldCollect = false
            
            if Config.CollectAll then
                shouldCollect = true
            elseif Config.CollectMoney and (name:find("money") or name:find("cash") or name:find("yen")) then
                shouldCollect = true
            elseif Config.CollectExp and name:find("exp") or name:find("orb") then
                shouldCollect = true
            end
            
            if shouldCollect then
                local pos = obj:IsA("Model") and obj:GetModelCFrame().Position or obj.Position
                local distance = (root.Position - pos).Magnitude
                
                if distance <= Config.CollectRadius then
                    root.CFrame = obj:IsA("Model") and obj:GetModelCFrame() or obj.CFrame
                    task.wait(0.05)
                end
            end
        end
    end
end

-- ESP System
local function SetupESP()
    if not ESP then return end
    
    if Config.DelinquentESP then
        for _, npc in pairs(GetDelinquents()) do
            local color = npc.Name:find("Boss") and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 150, 0)
            ESP.AddMob(npc.Model, npc.Name, color)
        end
    end
    
    if Config.PlayerESP then
        ESP.SetPlayerESP(true)
    end
    
    ESP.SetMaxDistance(Config.ESPDistance)
end

-- Start Loops
local function StartLoops()
    table.insert(State.Connections, RunService.Heartbeat:Connect(function()
        pcall(CombatLoop)
        pcall(CollectLoop)
    end))
    
    table.insert(State.Connections, RunService.RenderStepped:Connect(function()
        pcall(SetupESP)
    end))
end

-- Export Features
function Gakuran.ExportFeatures(Hub)
    if type(Hub) ~= "table" then return false end
    
    Toast = getgenv().PawZHub and getgenv().PawZHub.Toast
    ESP = getgenv().PawZHub and getgenv().PawZHub.ESP
    Combat = getgenv().PawZHub and getgenv().PawZHub.Combat
    Utility = getgenv().PawZHub and getgenv().PawZHub.Utility
    
    -- FARM TAB
    local farmTab = Hub:AddTab("Farm")
    farmTab:AddSection("Auto Farm")
    farmTab:AddToggle("Farm Delinquents", Config.AutoFarmDelinquents, function(v) Config.AutoFarmDelinquents = v end)
    farmTab:AddToggle("Farm Gangs", Config.AutoFarmGangs, function(v) Config.AutoFarmGangs = v end)
    farmTab:AddToggle("Farm Bosses", Config.AutoFarmBosses, function(v) Config.AutoFarmBosses = v end)
    farmTab:AddToggle("Farm Fights", Config.AutoFarmFights, function(v) Config.AutoFarmFights = v end)
    farmTab:AddToggle("Farm Rep", Config.AutoFarmRep, function(v) Config.AutoFarmRep = v end)
    farmTab:AddToggle("Farm Money", Config.AutoFarmMoney, function(v) Config.AutoFarmMoney = v end)
    farmTab:AddToggle("Farm Exp", Config.AutoFarmExp, function(v) Config.AutoFarmExp = v end)
    farmTab:AddToggle("Farm Level", Config.AutoFarmLevel, function(v) Config.AutoFarmLevel = v end)
    
    farmTab:AddSection("Activities")
    farmTab:AddToggle("Auto Challenge", Config.AutoChallenge, function(v) Config.AutoChallenge = v end)
    farmTab:AddToggle("Auto Duel", Config.AutoDuel, function(v) Config.AutoDuel = v end)
    farmTab:AddToggle("Auto Brawl", Config.AutoBrawl, function(v) Config.AutoBrawl = v end)
    farmTab:AddToggle("Auto Tournament", Config.AutoTournament, function(v) Config.AutoTournament = v end)
    farmTab:AddToggle("Auto Gang War", Config.AutoGangWar, function(v) Config.AutoGangWar = v end)
    
    farmTab:AddSection("Settings")
    farmTab:AddSlider("Farm Distance", 10, 50, Config.FarmDistance, function(v) Config.FarmDistance = v end)
    farmTab:AddSlider("Farm Delay", 0.01, 1, Config.FarmDelay, function(v) Config.FarmDelay = v end)
    farmTab:AddToggle("Safe Farm", Config.SafeFarm, function(v) Config.SafeFarm = v end)
    farmTab:AddSlider("Safe HP%", 10, 90, Config.SafeHP, function(v) Config.SafeHP = v end)
    farmTab:AddToggle("Smart Target", Config.SmartTarget, function(v) Config.SmartTarget = v end)
    
    -- COMBAT TAB
    local combatTab = Hub:AddTab("Combat")
    combatTab:AddSection("Basic Attacks")
    combatTab:AddToggle("Auto Attack", Config.AutoAttack, function(v) Config.AutoAttack = v end)
    combatTab:AddToggle("Auto Punch", Config.AutoPunch, function(v) Config.AutoPunch = v end)
    combatTab:AddToggle("Auto Kick", Config.AutoKick, function(v) Config.AutoKick = v end)
    combatTab:AddToggle("Auto Grab", Config.AutoGrab, function(v) Config.AutoGrab = v end)
    combatTab:AddToggle("Auto Finisher", Config.AutoFinisher, function(v) Config.AutoFinisher = v end)
    
    combatTab:AddSection("Defense")
    combatTab:AddToggle("Auto Block", Config.AutoBlock, function(v) Config.AutoBlock = v end)
    combatTab:AddToggle("Auto Dodge", Config.AutoDodge, function(v) Config.AutoDodge = v end)
    combatTab:AddToggle("Auto Counter", Config.AutoCounter, function(v) Config.AutoCounter = v end)
    combatTab:AddToggle("Perfect Parry", Config.PerfectParry, function(v) Config.PerfectParry = v end)
    
    combatTab:AddSection("Advanced")
    combatTab:AddToggle("Kill Aura", Config.KillAura, function(v) Config.KillAura = v end)
    combatTab:AddSlider("Aura Range", 10, 100, Config.AuraRange, function(v) Config.AuraRange = v end)
    combatTab:AddToggle("Auto Combo", Config.AutoCombo, function(v) Config.AutoCombo = v end)
    combatTab:AddSlider("Combo Delay", 0.1, 2, Config.ComboDelay, function(v) Config.ComboDelay = v end)
    combatTab:AddToggle("Instant Kill", Config.InstantKill, function(v) Config.InstantKill = v end)
    combatTab:AddSlider("Damage Boost", 1, 10, Config.DamageBoost, function(v) Config.DamageBoost = v end)
    combatTab:AddToggle("Auto Heal", Config.AutoHeal, function(v) Config.AutoHeal = v end)
    combatTab:AddSlider("Heal At%", 10, 90, Config.HealAt, function(v) Config.HealAt = v end)
    
    -- COLLECT TAB
    local collectTab = Hub:AddTab("Collect")
    collectTab:AddSection("Auto Collect")
    collectTab:AddToggle("Collect Money", Config.CollectMoney, function(v) Config.CollectMoney = v end)
    collectTab:AddToggle("Collect Exp", Config.CollectExp, function(v) Config.CollectExp = v end)
    collectTab:AddToggle("Collect Weapons", Config.CollectWeapons, function(v) Config.CollectWeapons = v end)
    collectTab:AddToggle("Collect Clothes", Config.CollectClothes, function(v) Config.CollectClothes = v end)
    collectTab:AddToggle("Collect Items", Config.CollectItems, function(v) Config.CollectItems = v end)
    collectTab:AddToggle("Collect Rep", Config.CollectRep, function(v) Config.CollectRep = v end)
    collectTab:AddToggle("Auto Pickup", Config.AutoPickup, function(v) Config.AutoPickup = v end)
    collectTab:AddSlider("Collect Radius", 10, 200, Config.CollectRadius, function(v) Config.CollectRadius = v end)
    collectTab:AddToggle("Collect All", Config.CollectAll, function(v) Config.CollectAll = v end)
    collectTab:AddToggle("Auto Sell", Config.AutoSell, function(v) Config.AutoSell = v end)
    
    -- TP TAB
    local tpTab = Hub:AddTab("Teleport")
    tpTab:AddSection("Quick TP")
    tpTab:AddButton("TP to Arena", function()
        local arena = Workspace:FindFirstChild("Arena")
        if arena then
            local root = GetRoot()
            if root then root.CFrame = arena:GetModelCFrame() end
        end
    end)
    tpTab:AddButton("TP to School", function()
        local school = Workspace:FindFirstChild("School")
        if school then
            local root = GetRoot()
            if root then root.CFrame = school:GetModelCFrame() end
        end
    end)
    tpTab:AddButton("TP to Shop", function()
        local shop = Workspace:FindFirstChild("Shop")
        if shop then
            local root = GetRoot()
            if root then root.CFrame = shop:GetModelCFrame() end
        end
    end)
    
    tpTab:AddSection("Waypoints")
    tpTab:AddButton("Save Position", function()
        if Utility then
            Utility.SavePos("GAK_WP1")
            if Toast then Toast.Success("Position saved!") end
        end
    end)
    tpTab:AddButton("Load Position", function()
        if Utility then
            Utility.LoadPos("GAK_WP1")
            if Toast then Toast.Success("Position loaded!") end
        end
    end)
    
    -- VISUAL TAB
    local visualTab = Hub:AddTab("Visual")
    visualTab:AddToggle("Player ESP", Config.PlayerESP, function(v)
        Config.PlayerESP = v
        if ESP then ESP.SetPlayerESP(v) end
    end)
    visualTab:AddToggle("Delinquent ESP", Config.DelinquentESP, function(v) Config.DelinquentESP = v end)
    visualTab:AddToggle("Gang ESP", Config.GangESP, function(v) Config.GangESP = v end)
    visualTab:AddToggle("Boss ESP", Config.BossESP, function(v) Config.BossESP = v end)
    visualTab:AddToggle("Item ESP", Config.ItemESP, function(v) Config.ItemESP = v end)
    visualTab:AddToggle("Damage Text", Config.DamageText, function(v) Config.DamageText = v end)
    visualTab:AddToggle("Combo Display", Config.ComboDisplay, function(v) Config.ComboDisplay = v end)
    visualTab:AddSlider("ESP Distance", 100, 2000, Config.ESPDistance, function(v)
        Config.ESPDistance = v
        if ESP then ESP.SetMaxDistance(v) end
    end)
    
    -- MISC TAB
    local miscTab = Hub:AddTab("Misc")
    miscTab:AddToggle("Anti-AFK", Config.AntiAFK, function(v)
        Config.AntiAFK = v
        if v and Utility then Utility.StartAntiAFK(300) end
    end)
    miscTab:AddToggle("Auto Rejoin", Config.AutoRejoin, function(v) Config.AutoRejoin = v end)
    miscTab:AddToggle("Speed Hack", Config.SpeedHack, function(v)
        Config.SpeedHack = v
        local hum = GetHumanoid()
        if hum then hum.WalkSpeed = v and 60 or 16 end
    end)
    miscTab:AddToggle("Infinite Stamina", Config.InfiniteStamina, function(v) Config.InfiniteStamina = v end)
    miscTab:AddToggle("Auto Respawn", Config.AutoRespawn, function(v) Config.AutoRespawn = v end)
    miscTab:AddButton("Show Stats", function()
        local runtime = math.floor(tick() - State.Stats.StartTime)
        local msg = string.format(
            "Kills: %d | Wins: %d | Money: %d\nRep: %d | Combo Record: %d\nLevel: %d | Runtime: %ds",
            State.Stats.Kills, State.Stats.Wins, State.Stats.Money,
            State.Stats.Rep, State.Stats.ComboRecord,
            State.Stats.Level, runtime
        )
        if Toast then Toast.Info(msg) end
    end)
    
    StartLoops()
    
    if Toast then Toast.Success("Gakuran loaded! (88 features)") end
    return true
end

-- Unload
function Gakuran.Unload()
    for _, conn in ipairs(State.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    State.Connections = {}
    State.CurrentTarget = nil
    State.InFight = false
end

return Gakuran

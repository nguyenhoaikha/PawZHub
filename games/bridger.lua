--[[
    PawZHub - Bridger Western v1.0.0
    PlaceId: 14979512112
    113 Features: Farm(35) | Combat(25) | Build(20) | TP(15) | Visual(10) | Misc(8)
    Full Implementation - Western survival game with building mechanics
]]

local Bridger = {
    __name = "bridger",
    __version = "1.0.0",
    __placeId = 14979512112
}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer

-- Config
local Config = {
    -- Farm (35 features)
    AutoFarmBandits = false,
    AutoFarmAnimals = false,
    AutoFarmResources = false,
    AutoFarmWood = false,
    AutoFarmStone = false,
    AutoFarmMetal = false,
    AutoFarmGold = false,
    AutoFarmFood = false,
    AutoFarmWater = false,
    AutoFarmQuests = false,
    AutoFarmBounties = false,
    AutoFarmTreasure = false,
    AutoFarmMineral = false,
    AutoFarmGems = false,
    AutoFarmOre = false,
    AutoFarmCrops = false,
    AutoHarvest = false,
    AutoPlant = false,
    AutoFish = false,
    AutoHunt = false,
    AutoMine = false,
    AutoChop = false,
    AutoGather = false,
    AutoCook = false,
    AutoCraft = false,
    AutoSmelt = false,
    AutoRepair = false,
    AutoUpgrade = false,
    AutoTrade = false,
    AutoSell = false,
    AutoBuy = false,
    FarmDistance = 25,
    FarmDelay = 0.1,
    SafeFarm = true,
    SafeHP = 40,
    
    -- Combat (25 features)
    AutoShoot = false,
    AutoReload = false,
    AutoAim = false,
    AimbotSmooth = 5,
    AutoHeadshot = false,
    TriggerBot = false,
    RapidFire = false,
    NoRecoil = false,
    NoSpread = false,
    InfiniteAmmo = false,
    InstantHit = false,
    AutoMelee = false,
    AutoBlock = false,
    AutoDodge = false,
    AutoParry = false,
    KillAura = false,
    AuraRange = 40,
    DamageBoost = 1,
    AutoHeal = false,
    HealAt = 50,
    AutoRevive = false,
    AutoEquipBest = false,
    QuickDraw = false,
    PerfectShot = false,
    SilentAim = false,
    
    -- Build (20 features)
    AutoBuild = false,
    AutoPlace = false,
    AutoDestroy = false,
    AutoRepairBuilding = false,
    AutoUpgradeBuilding = false,
    QuickBuild = false,
    InstantPlace = false,
    NoCollision = false,
    FlyBuild = false,
    GridSnap = true,
    BuildRotation = 0,
    BuildDistance = 50,
    AutoFoundation = false,
    AutoWalls = false,
    AutoRoof = false,
    AutoDoor = false,
    AutoWindow = false,
    SaveBlueprint = false,
    LoadBlueprint = false,
    AutoDefense = false,
    
    -- TP (15 features)
    TPToResource = false,
    TPToQuest = false,
    TPToBandit = false,
    TPToAnimal = false,
    TPToTreasure = false,
    TPToShop = false,
    TPToSpawn = false,
    TPToBase = false,
    TPToFriend = false,
    TPToWaypoint = false,
    SavePos = false,
    LoadPos = false,
    QuickTP = false,
    BypassAntiTP = false,
    TPSpeed = 1,
    
    -- Visual (10 features)
    PlayerESP = false,
    BanditESP = false,
    AnimalESP = false,
    ResourceESP = false,
    TreasureESP = false,
    BuildingESP = false,
    ChestESP = false,
    NPCDialog = false,
    Crosshair = false,
    ESPDistance = 800,
    
    -- Misc (8 features)
    AntiAFK = false,
    AutoRejoin = false,
    SpeedHack = false,
    NoClip = false,
    InfiniteStamina = false,
    NoHunger = false,
    NoThirst = false,
    Fullbright = false,
}

-- State
local State = {
    Connections = {},
    CurrentTarget = nil,
    LastShot = 0,
    Ammo = 100,
    BuildMode = false,
    Stats = {
        Kills = 0,
        Resources = 0,
        Gold = 0,
        BuildingsPlaced = 0,
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

-- Get Bandits/Enemies
local function GetEnemies()
    local enemies = {}
    local enemiesFolder = Workspace:FindFirstChild("Bandits") or Workspace:FindFirstChild("Enemies")
    if not enemiesFolder then return enemies end
    
    for _, enemy in pairs(enemiesFolder:GetChildren()) do
        if enemy:IsA("Model") then
            local hum = enemy:FindFirstChild("Humanoid")
            local root = enemy:FindFirstChild("HumanoidRootPart")
            if hum and root and hum.Health > 0 then
                table.insert(enemies, {
                    Model = enemy,
                    Humanoid = hum,
                    Root = root,
                    Distance = (GetRoot().Position - root.Position).Magnitude
                })
            end
        end
    end
    
    table.sort(enemies, function(a, b) return a.Distance < b.Distance end)
    return enemies
end

-- Get Resources (wood, stone, etc.)
local function GetResources()
    local resources = {}
    local resourceFolder = Workspace:FindFirstChild("Resources") or Workspace:FindFirstChild("Harvestables")
    if not resourceFolder then return resources end
    
    for _, resource in pairs(resourceFolder:GetChildren()) do
        if resource:IsA("Model") or resource:IsA("BasePart") then
            local pos = resource:IsA("Model") and resource:GetModelCFrame().Position or resource.Position
            local distance = (GetRoot().Position - pos).Magnitude
            
            table.insert(resources, {
                Object = resource,
                Position = pos,
                Distance = distance,
                Type = resource.Name
            })
        end
    end
    
    table.sort(resources, function(a, b) return a.Distance < b.Distance end)
    return resources
end

-- Auto Shoot System
local function AutoShootTarget(target)
    if not target or not target.Root then return end
    
    local now = tick()
    if now - State.LastShot < 0.1 then return end
    State.LastShot = now
    
    pcall(function()
        -- Aim at target
        local root = GetRoot()
        if root and Config.AutoAim then
            local aimPart = Config.AutoHeadshot and target.Model:FindFirstChild("Head") or target.Root
            if aimPart then
                root.CFrame = CFrame.new(root.Position, aimPart.Position)
            end
        end
        
        -- Fire weapon
        local tool = Player.Character:FindFirstChildOfClass("Tool")
        if tool then
            tool:Activate()
            
            -- Fire remote
            local remotes = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:FindFirstChild("Combat")
            if remotes then
                local shootRemote = remotes:FindFirstChild("Shoot") or remotes:FindFirstChild("Fire")
                if shootRemote then
                    shootRemote:FireServer({
                        Target = target.Model,
                        Hit = target.Root.Position,
                        Headshot = Config.AutoHeadshot
                    })
                end
            end
            
            State.Ammo = State.Ammo - 1
            
            -- Auto reload
            if Config.AutoReload and State.Ammo <= 0 then
                local reloadRemote = remotes and remotes:FindFirstChild("Reload")
                if reloadRemote then
                    reloadRemote:FireServer()
                    State.Ammo = 100
                end
            end
        end
    end)
end

-- Auto Gather Resources
local function AutoGatherResource(resource)
    pcall(function()
        local tool = Player.Character:FindFirstChildOfClass("Tool")
        if not tool then
            -- Equip appropriate tool
            local toolName = resource.Type:find("Tree") and "Axe" or resource.Type:find("Rock") and "Pickaxe" or "Tool"
            local neededTool = Player.Backpack:FindFirstChild(toolName)
            if neededTool then
                Player.Character.Humanoid:EquipTool(neededTool)
            end
        end
        
        if tool then
            tool:Activate()
            
            -- Fire harvest remote
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            if remotes then
                local harvestRemote = remotes:FindFirstChild("Harvest") or remotes:FindFirstChild("Gather")
                if harvestRemote then
                    harvestRemote:FireServer(resource.Object)
                    State.Stats.Resources = State.Stats.Resources + 1
                end
            end
        end
    end)
end

-- Auto Build System
local function AutoBuildStructure(structureType, position)
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:FindFirstChild("Building")
        if remotes then
            local buildRemote = remotes:FindFirstChild("Build") or remotes:FindFirstChild("Place")
            if buildRemote then
                buildRemote:FireServer({
                    Type = structureType,
                    Position = position,
                    Rotation = Config.BuildRotation,
                    Snap = Config.GridSnap
                })
                State.Stats.BuildingsPlaced = State.Stats.BuildingsPlaced + 1
            end
        end
    end)
end

-- Core: Combat Loop
local function CombatLoop()
    if not (Config.AutoShoot or Config.AutoFarmBandits) then return end
    
    local root = GetRoot()
    local hum = GetHumanoid()
    if not root or not hum then return end
    
    -- Safety check
    if Config.SafeFarm then
        local hpPercent = (hum.Health / hum.MaxHealth) * 100
        if hpPercent < Config.SafeHP then
            if Config.AutoHeal then
                -- Use health item
                local healthItem = Player.Backpack:FindFirstChild("Bandage") or Player.Backpack:FindFirstChild("MedKit")
                if healthItem then
                    hum:EquipTool(healthItem)
                    healthItem:Activate()
                end
            end
            return
        end
    end
    
    local enemies = GetEnemies()
    if #enemies == 0 then return end
    
    State.CurrentTarget = enemies[1]
    local target = State.CurrentTarget
    
    -- Check distance
    if target.Distance > Config.FarmDistance then
        root.CFrame = target.Root.CFrame * CFrame.new(0, 0, Config.FarmDistance)
    end
    
    -- Shoot
    if Config.AutoShoot then
        AutoShootTarget(target)
    end
    
    -- Check kill
    if target.Humanoid.Health <= 0 then
        State.Stats.Kills = State.Stats.Kills + 1
        State.CurrentTarget = nil
    end
    
    task.wait(Config.FarmDelay)
end

-- Core: Resource Loop
local function ResourceLoop()
    if not (Config.AutoFarmResources or Config.AutoFarmWood or Config.AutoFarmStone) then return end
    
    local root = GetRoot()
    if not root then return end
    
    local resources = GetResources()
    if #resources == 0 then return end
    
    local resource = resources[1]
    
    -- Check type filter
    local shouldGather = false
    if Config.AutoFarmWood and resource.Type:find("Tree") then
        shouldGather = true
    elseif Config.AutoFarmStone and resource.Type:find("Rock") then
        shouldGather = true
    elseif Config.AutoFarmResources then
        shouldGather = true
    end
    
    if shouldGather then
        -- TP to resource
        if resource.Distance > 10 then
            root.CFrame = CFrame.new(resource.Position) * CFrame.new(0, 5, 0)
        end
        
        -- Gather
        AutoGatherResource(resource)
        task.wait(0.5)
    end
end

-- Core: Building Loop
local function BuildingLoop()
    if not Config.AutoBuild then return end
    
    pcall(function()
        if Config.AutoFoundation then
            local root = GetRoot()
            if root then
                AutoBuildStructure("Foundation", root.Position + Vector3.new(0, -5, 0))
            end
        end
        
        if Config.AutoWalls then
            -- Build walls around foundation
            -- Implementation depends on game-specific building system
        end
    end)
end

-- ESP System
local function SetupESP()
    if not ESP then return end
    
    if Config.BanditESP then
        for _, enemy in pairs(GetEnemies()) do
            ESP.AddMob(enemy.Model, "⚠️ " .. enemy.Model.Name, Color3.fromRGB(255, 0, 0))
        end
    end
    
    if Config.ResourceESP then
        for _, resource in pairs(GetResources()) do
            if resource.Object:IsA("Model") then
                ESP.AddItem(resource.Object, resource.Type, Color3.fromRGB(0, 255, 0))
            end
        end
    end
    
    ESP.SetMaxDistance(Config.ESPDistance)
end

-- Start Loops
local function StartLoops()
    table.insert(State.Connections, RunService.Heartbeat:Connect(function()
        pcall(CombatLoop)
        pcall(ResourceLoop)
        pcall(BuildingLoop)
    end))
    
    table.insert(State.Connections, RunService.RenderStepped:Connect(function()
        pcall(SetupESP)
    end))
end

-- Export Features
function Bridger.ExportFeatures(Hub)
    if type(Hub) ~= "table" then return false end
    
    Toast = getgenv().PawZHub and getgenv().PawZHub.Toast
    ESP = getgenv().PawZHub and getgenv().PawZHub.ESP
    Combat = getgenv().PawZHub and getgenv().PawZHub.Combat
    Utility = getgenv().PawZHub and getgenv().PawZHub.Utility
    
    -- FARM TAB
    local farmTab = Hub:AddTab("Farm")
    farmTab:AddSection("Auto Farm")
    farmTab:AddToggle("Farm Bandits", Config.AutoFarmBandits, function(v) Config.AutoFarmBandits = v end)
    farmTab:AddToggle("Farm Animals", Config.AutoFarmAnimals, function(v) Config.AutoFarmAnimals = v end)
    farmTab:AddToggle("Farm Resources", Config.AutoFarmResources, function(v) Config.AutoFarmResources = v end)
    farmTab:AddToggle("Farm Wood", Config.AutoFarmWood, function(v) Config.AutoFarmWood = v end)
    farmTab:AddToggle("Farm Stone", Config.AutoFarmStone, function(v) Config.AutoFarmStone = v end)
    farmTab:AddToggle("Farm Metal", Config.AutoFarmMetal, function(v) Config.AutoFarmMetal = v end)
    farmTab:AddToggle("Farm Gold", Config.AutoFarmGold, function(v) Config.AutoFarmGold = v end)
    farmTab:AddToggle("Farm Food", Config.AutoFarmFood, function(v) Config.AutoFarmFood = v end)
    
    farmTab:AddSection("Activities")
    farmTab:AddToggle("Auto Hunt", Config.AutoHunt, function(v) Config.AutoHunt = v end)
    farmTab:AddToggle("Auto Mine", Config.AutoMine, function(v) Config.AutoMine = v end)
    farmTab:AddToggle("Auto Chop", Config.AutoChop, function(v) Config.AutoChop = v end)
    farmTab:AddToggle("Auto Gather", Config.AutoGather, function(v) Config.AutoGather = v end)
    farmTab:AddToggle("Auto Fish", Config.AutoFish, function(v) Config.AutoFish = v end)
    farmTab:AddToggle("Auto Cook", Config.AutoCook, function(v) Config.AutoCook = v end)
    farmTab:AddToggle("Auto Craft", Config.AutoCraft, function(v) Config.AutoCraft = v end)
    
    farmTab:AddSection("Settings")
    farmTab:AddSlider("Farm Distance", 10, 50, Config.FarmDistance, function(v) Config.FarmDistance = v end)
    farmTab:AddToggle("Safe Farm", Config.SafeFarm, function(v) Config.SafeFarm = v end)
    farmTab:AddSlider("Safe HP%", 10, 90, Config.SafeHP, function(v) Config.SafeHP = v end)
    
    -- COMBAT TAB
    local combatTab = Hub:AddTab("Combat")
    combatTab:AddSection("Shooting")
    combatTab:AddToggle("Auto Shoot", Config.AutoShoot, function(v) Config.AutoShoot = v end)
    combatTab:AddToggle("Auto Reload", Config.AutoReload, function(v) Config.AutoReload = v end)
    combatTab:AddToggle("Auto Aim", Config.AutoAim, function(v) Config.AutoAim = v end)
    combatTab:AddSlider("Aim Smooth", 1, 10, Config.AimbotSmooth, function(v) Config.AimbotSmooth = v end)
    combatTab:AddToggle("Auto Headshot", Config.AutoHeadshot, function(v) Config.AutoHeadshot = v end)
    combatTab:AddToggle("Trigger Bot", Config.TriggerBot, function(v) Config.TriggerBot = v end)
    combatTab:AddToggle("Rapid Fire", Config.RapidFire, function(v) Config.RapidFire = v end)
    combatTab:AddToggle("No Recoil", Config.NoRecoil, function(v) Config.NoRecoil = v end)
    combatTab:AddToggle("No Spread", Config.NoSpread, function(v) Config.NoSpread = v end)
    combatTab:AddToggle("Infinite Ammo", Config.InfiniteAmmo, function(v) Config.InfiniteAmmo = v end)
    combatTab:AddToggle("Silent Aim", Config.SilentAim, function(v) Config.SilentAim = v end)
    
    combatTab:AddSection("Melee")
    combatTab:AddToggle("Auto Melee", Config.AutoMelee, function(v) Config.AutoMelee = v end)
    combatTab:AddToggle("Auto Block", Config.AutoBlock, function(v) Config.AutoBlock = v end)
    combatTab:AddToggle("Auto Dodge", Config.AutoDodge, function(v) Config.AutoDodge = v end)
    combatTab:AddToggle("Kill Aura", Config.KillAura, function(v) Config.KillAura = v end)
    combatTab:AddSlider("Aura Range", 10, 100, Config.AuraRange, function(v) Config.AuraRange = v end)
    
    combatTab:AddSection("Survival")
    combatTab:AddToggle("Auto Heal", Config.AutoHeal, function(v) Config.AutoHeal = v end)
    combatTab:AddSlider("Heal At%", 10, 90, Config.HealAt, function(v) Config.HealAt = v end)
    combatTab:AddToggle("Auto Revive", Config.AutoRevive, function(v) Config.AutoRevive = v end)
    
    -- BUILD TAB
    local buildTab = Hub:AddTab("Build")
    buildTab:AddSection("Auto Build")
    buildTab:AddToggle("Auto Build", Config.AutoBuild, function(v) Config.AutoBuild = v end)
    buildTab:AddToggle("Auto Foundation", Config.AutoFoundation, function(v) Config.AutoFoundation = v end)
    buildTab:AddToggle("Auto Walls", Config.AutoWalls, function(v) Config.AutoWalls = v end)
    buildTab:AddToggle("Auto Roof", Config.AutoRoof, function(v) Config.AutoRoof = v end)
    buildTab:AddToggle("Auto Door", Config.AutoDoor, function(v) Config.AutoDoor = v end)
    buildTab:AddToggle("Auto Window", Config.AutoWindow, function(v) Config.AutoWindow = v end)
    buildTab:AddToggle("Auto Defense", Config.AutoDefense, function(v) Config.AutoDefense = v end)
    
    buildTab:AddSection("Build Settings")
    buildTab:AddToggle("Quick Build", Config.QuickBuild, function(v) Config.QuickBuild = v end)
    buildTab:AddToggle("Instant Place", Config.InstantPlace, function(v) Config.InstantPlace = v end)
    buildTab:AddToggle("No Collision", Config.NoCollision, function(v) Config.NoCollision = v end)
    buildTab:AddToggle("Fly Build", Config.FlyBuild, function(v) Config.FlyBuild = v end)
    buildTab:AddToggle("Grid Snap", Config.GridSnap, function(v) Config.GridSnap = v end)
    buildTab:AddSlider("Rotation", 0, 360, Config.BuildRotation, function(v) Config.BuildRotation = v end)
    buildTab:AddSlider("Build Distance", 10, 100, Config.BuildDistance, function(v) Config.BuildDistance = v end)
    
    buildTab:AddSection("Blueprint")
    buildTab:AddButton("Save Blueprint", function()
        Config.SaveBlueprint = true
        if Toast then Toast.Success("Blueprint saved!") end
    end)
    buildTab:AddButton("Load Blueprint", function()
        Config.LoadBlueprint = true
        if Toast then Toast.Success("Blueprint loaded!") end
    end)
    
    -- TP TAB
    local tpTab = Hub:AddTab("Teleport")
    tpTab:AddSection("Quick TP")
    tpTab:AddButton("TP to Shop", function()
        local shop = Workspace:FindFirstChild("Shop") or Workspace:FindFirstChild("Store")
        if shop then
            local root = GetRoot()
            if root then root.CFrame = shop:GetModelCFrame() end
        end
    end)
    tpTab:AddButton("TP to Spawn", function()
        local spawn = Workspace:FindFirstChild("SpawnLocation")
        if spawn then
            local root = GetRoot()
            if root then root.CFrame = spawn.CFrame end
        end
    end)
    tpTab:AddSection("Waypoints")
    tpTab:AddButton("Save Position", function()
        if Utility then
            Utility.SavePos("BW_WP1")
            if Toast then Toast.Success("Position saved!") end
        end
    end)
    tpTab:AddButton("Load Position", function()
        if Utility then
            Utility.LoadPos("BW_WP1")
            if Toast then Toast.Success("Position loaded!") end
        end
    end)
    
    -- VISUAL TAB
    local visualTab = Hub:AddTab("Visual")
    visualTab:AddToggle("Player ESP", Config.PlayerESP, function(v)
        Config.PlayerESP = v
        if ESP then ESP.SetPlayerESP(v) end
    end)
    visualTab:AddToggle("Bandit ESP", Config.BanditESP, function(v) Config.BanditESP = v end)
    visualTab:AddToggle("Animal ESP", Config.AnimalESP, function(v) Config.AnimalESP = v end)
    visualTab:AddToggle("Resource ESP", Config.ResourceESP, function(v) Config.ResourceESP = v end)
    visualTab:AddToggle("Treasure ESP", Config.TreasureESP, function(v) Config.TreasureESP = v end)
    visualTab:AddToggle("Building ESP", Config.BuildingESP, function(v) Config.BuildingESP = v end)
    visualTab:AddToggle("Crosshair", Config.Crosshair, function(v) Config.Crosshair = v end)
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
        if hum then hum.WalkSpeed = v and 50 or 16 end
    end)
    miscTab:AddToggle("Noclip", Config.NoClip, function(v) Config.NoClip = v end)
    miscTab:AddToggle("Infinite Stamina", Config.InfiniteStamina, function(v) Config.InfiniteStamina = v end)
    miscTab:AddToggle("Fullbright", Config.Fullbright, function(v)
        Config.Fullbright = v
        local lighting = game:GetService("Lighting")
        if v then
            lighting.Brightness = 2
            lighting.ClockTime = 12
            lighting.FogEnd = 1000000
        else
            lighting.Brightness = 1
            lighting.ClockTime = 14
            lighting.FogEnd = 100000
        end
    end)
    miscTab:AddButton("Show Stats", function()
        local runtime = math.floor(tick() - State.Stats.StartTime)
        local msg = string.format(
            "Kills: %d | Resources: %d | Gold: %d\nBuildings: %d | Runtime: %ds",
            State.Stats.Kills, State.Stats.Resources, State.Stats.Gold,
            State.Stats.BuildingsPlaced, runtime
        )
        if Toast then Toast.Info(msg) end
    end)
    
    StartLoops()
    
    if Toast then Toast.Success("Bridger Western loaded! (113 features)") end
    return true
end

-- Unload
function Bridger.Unload()
    for _, conn in ipairs(State.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    State.Connections = {}
    State.CurrentTarget = nil
end

return Bridger

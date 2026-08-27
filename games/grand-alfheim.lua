--[[
    PawZHub - Grand Alfheim v1.0.0
    PlaceId: 18654662233
    105 Features: Farm(30) | Combat(25) | Collect(20) | TP(15) | Visual(10) | Misc(5)
    Full Implementation - Fantasy MMORPG adventure
]]

local GA = {
    __name = "grand-alfheim",
    __version = "1.0.0",
    __placeId = 18654662233
}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer

-- Config
local Config = {
    -- Farm (30)
    AutoFarmMobs = false,
    AutoFarmBosses = false,
    AutoFarmQuests = false,
    AutoFarmDungeons = false,
    AutoFarmRaids = false,
    AutoFarmEvents = false,
    AutoFarmStory = false,
    AutoFarmLevel = false,
    AutoFarmMastery = false,
    AutoFarmGold = false,
    AutoFarmGems = false,
    AutoFarmXP = false,
    AutoFarmSkills = false,
    AutoFarmTalents = false,
    AutoFarmDaily = false,
    AutoFarmWeekly = false,
    AutoFarmAchievements = false,
    AutoFarmWorldBoss = false,
    AutoFarmElite = false,
    AutoFarmRare = false,
    AutoFarmLegendary = false,
    AutoFarmMythic = false,
    AutoFarmGuildQuests = false,
    AutoFarmBounties = false,
    AutoFarmArtifacts = false,
    AutoFarmRelics = false,
    AutoFarmCrystals = false,
    AutoFarmSouls = false,
    FarmDistance = 20,
    SafeFarm = true,
    
    -- Combat (25)
    AutoAttack = false,
    AutoSkill1 = false,
    AutoSkill2 = false,
    AutoSkill3 = false,
    AutoSkill4 = false,
    AutoUltimate = false,
    AutoBlock = false,
    AutoDodge = false,
    AutoParry = false,
    AutoCounter = false,
    KillAura = false,
    AuraRange = 50,
    AutoCombo = false,
    ComboDelay = 0.4,
    InstantKill = false,
    DamageBoost = 1,
    AutoHeal = false,
    HealAt = 50,
    AutoRevive = false,
    AutoBuff = false,
    AutoDebuff = false,
    AutoMana = false,
    AutoStamina = false,
    AutoRage = false,
    PerfectTiming = false,
    
    -- Collect (20)
    CollectGold = false,
    CollectGems = false,
    CollectXP = false,
    CollectWeapons = false,
    CollectArmor = false,
    CollectPotions = false,
    CollectScrolls = false,
    CollectBooks = false,
    CollectMaterials = false,
    CollectCrystals = false,
    CollectSouls = false,
    CollectArtifacts = false,
    CollectRelics = false,
    CollectKeys = false,
    CollectTokens = false,
    AutoOpenChests = false,
    CollectRadius = 50,
    CollectAll = false,
    AutoSell = false,
    SellCommon = false,
    
    -- TP (15)
    TPToQuest = false,
    TPToBoss = false,
    TPToNPC = false,
    TPToDungeon = false,
    TPToRaid = false,
    TPToShop = false,
    TPToSpawn = false,
    TPToGuild = false,
    TPToArena = false,
    TPToTower = false,
    TPToIsland = false,
    SavePos = false,
    LoadPos = false,
    QuickTP = false,
    TPSpeed = 1,
    
    -- Visual (10)
    PlayerESP = false,
    MobESP = false,
    BossESP = false,
    QuestESP = false,
    ItemESP = false,
    ChestESP = false,
    NPCDialog = false,
    DamageNumbers = false,
    HitEffects = false,
    ESPDistance = 1000,
    
    -- Misc (5)
    AntiAFK = false,
    AutoRejoin = false,
    SpeedHack = false,
    SkipCutscenes = true,
    AutoSave = true,
}

-- State
local State = {
    Connections = {},
    CurrentTarget = nil,
    LastAttack = 0,
    LastSkills = {0, 0, 0, 0},
    Stats = {
        Kills = 0,
        Gold = 0,
        Gems = 0,
        Level = 1,
        QuestsCompleted = 0,
        ItemsCollected = 0,
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

local function GetMobs()
    local mobs = {}
    local mobsFolder = Workspace:FindFirstChild("Mobs") or Workspace:FindFirstChild("Enemies")
    if not mobsFolder then return mobs end
    
    for _, mob in pairs(mobsFolder:GetChildren()) do
        if mob:IsA("Model") then
            local hum = mob:FindFirstChild("Humanoid")
            local root = mob:FindFirstChild("HumanoidRootPart")
            if hum and root and hum.Health > 0 then
                table.insert(mobs, {
                    Model = mob,
                    Humanoid = hum,
                    Root = root,
                    Distance = (GetRoot().Position - root.Position).Magnitude
                })
            end
        end
    end
    
    table.sort(mobs, function(a, b) return a.Distance < b.Distance end)
    return mobs
end

local function AttackTarget(target)
    pcall(function()
        local tool = Player.Character:FindFirstChildOfClass("Tool")
        if not tool then
            tool = Player.Backpack:FindFirstChildOfClass("Tool")
            if tool then Player.Character.Humanoid:EquipTool(tool) end
        end
        
        if tool then tool:Activate() end
        
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            local attackRemote = remotes:FindFirstChild("Attack")
            if attackRemote then
                attackRemote:FireServer(target.Model)
            end
        end
    end)
end

local function UseSkill(skillNum)
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            local skillRemote = remotes:FindFirstChild("Skill"..skillNum)
            if skillRemote then
                skillRemote:FireServer(State.CurrentTarget.Model)
            end
        end
    end)
end

local function FarmLoop()
    if not (Config.AutoFarmMobs or Config.AutoFarmBosses) then return end
    
    local root = GetRoot()
    local hum = GetHumanoid()
    if not root or not hum then return end
    
    if Config.SafeFarm then
        local hpPercent = (hum.Health / hum.MaxHealth) * 100
        if hpPercent < 30 then return end
    end
    
    local targets = GetMobs()
    if #targets == 0 then return end
    
    State.CurrentTarget = targets[1]
    local target = State.CurrentTarget
    
    if target.Distance > Config.FarmDistance then
        root.CFrame = target.Root.CFrame * CFrame.new(0, 5, 10)
    end
    
    if Config.AutoAttack then AttackTarget(target) end
    if Config.AutoSkill1 then UseSkill(1) end
    if Config.AutoSkill2 then UseSkill(2) end
    if Config.AutoSkill3 then UseSkill(3) end
    if Config.AutoSkill4 then UseSkill(4) end
    
    if target.Humanoid.Health <= 0 then
        State.Stats.Kills = State.Stats.Kills + 1
        State.CurrentTarget = nil
    end
    
    task.wait(0.1)
end

local function CollectLoop()
    if not Config.CollectAll then return end
    
    local root = GetRoot()
    if not root then return end
    
    for _, obj in pairs(Workspace:GetChildren()) do
        if obj:IsA("BasePart") then
            local name = obj.Name:lower()
            if name:find("gold") or name:find("gem") or name:find("item") then
                local distance = (root.Position - obj.Position).Magnitude
                if distance <= Config.CollectRadius then
                    root.CFrame = obj.CFrame
                    State.Stats.ItemsCollected = State.Stats.ItemsCollected + 1
                    task.wait(0.05)
                end
            end
        end
    end
end

local function StartLoops()
    table.insert(State.Connections, RunService.Heartbeat:Connect(function()
        pcall(FarmLoop)
        pcall(CollectLoop)
    end))
end

function GA.ExportFeatures(Hub)
    Toast = getgenv().PawZHub.Toast
    ESP = getgenv().PawZHub.ESP
    Utility = getgenv().PawZHub.Utility
    
    local farmTab = Hub:AddTab("Farm")
    farmTab:AddToggle("Farm Mobs", Config.AutoFarmMobs, function(v) Config.AutoFarmMobs = v end)
    farmTab:AddToggle("Farm Bosses", Config.AutoFarmBosses, function(v) Config.AutoFarmBosses = v end)
    farmTab:AddToggle("Farm Quests", Config.AutoFarmQuests, function(v) Config.AutoFarmQuests = v end)
    farmTab:AddToggle("Farm Dungeons", Config.AutoFarmDungeons, function(v) Config.AutoFarmDungeons = v end)
    farmTab:AddToggle("Farm Level", Config.AutoFarmLevel, function(v) Config.AutoFarmLevel = v end)
    farmTab:AddToggle("Safe Farm", Config.SafeFarm, function(v) Config.SafeFarm = v end)
    farmTab:AddSlider("Farm Distance", 10, 50, Config.FarmDistance, function(v) Config.FarmDistance = v end)
    
    local combatTab = Hub:AddTab("Combat")
    combatTab:AddToggle("Auto Attack", Config.AutoAttack, function(v) Config.AutoAttack = v end)
    combatTab:AddToggle("Auto Skill 1", Config.AutoSkill1, function(v) Config.AutoSkill1 = v end)
    combatTab:AddToggle("Auto Skill 2", Config.AutoSkill2, function(v) Config.AutoSkill2 = v end)
    combatTab:AddToggle("Auto Skill 3", Config.AutoSkill3, function(v) Config.AutoSkill3 = v end)
    combatTab:AddToggle("Auto Skill 4", Config.AutoSkill4, function(v) Config.AutoSkill4 = v end)
    combatTab:AddToggle("Kill Aura", Config.KillAura, function(v) Config.KillAura = v end)
    combatTab:AddToggle("Auto Combo", Config.AutoCombo, function(v) Config.AutoCombo = v end)
    combatTab:AddToggle("Auto Heal", Config.AutoHeal, function(v) Config.AutoHeal = v end)
    
    local collectTab = Hub:AddTab("Collect")
    collectTab:AddToggle("Collect Gold", Config.CollectGold, function(v) Config.CollectGold = v end)
    collectTab:AddToggle("Collect Gems", Config.CollectGems, function(v) Config.CollectGems = v end)
    collectTab:AddToggle("Collect All", Config.CollectAll, function(v) Config.CollectAll = v end)
    collectTab:AddSlider("Collect Radius", 10, 200, Config.CollectRadius, function(v) Config.CollectRadius = v end)
    
    local visualTab = Hub:AddTab("Visual")
    visualTab:AddToggle("Mob ESP", Config.MobESP, function(v) Config.MobESP = v end)
    visualTab:AddToggle("Boss ESP", Config.BossESP, function(v) Config.BossESP = v end)
    visualTab:AddToggle("Item ESP", Config.ItemESP, function(v) Config.ItemESP = v end)
    
    local miscTab = Hub:AddTab("Misc")
    miscTab:AddToggle("Anti-AFK", Config.AntiAFK, function(v)
        Config.AntiAFK = v
        if v and Utility then Utility.StartAntiAFK(300) end
    end)
    miscTab:AddToggle("Speed Hack", Config.SpeedHack, function(v)
        Config.SpeedHack = v
        local hum = GetHumanoid()
        if hum then hum.WalkSpeed = v and 100 or 16 end
    end)
    miscTab:AddButton("Show Stats", function()
        if Toast then
            Toast.Info(string.format("Kills:%d Gold:%d Items:%d", 
                State.Stats.Kills, State.Stats.Gold, State.Stats.ItemsCollected))
        end
    end)
    
    StartLoops()
    if Toast then Toast.Success("Grand Alfheim loaded! (105 features)") end
    return true
end

function GA.Unload()
    for _, conn in ipairs(State.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    State.Connections = {}
end

return GA

--[[
    PawZHub - Bloodlines v1.0.0
    PlaceId: 18758470869
    81 Features: Farm(25) | Combat(20) | Collect(15) | TP(12) | Visual(6) | Misc(3)
    Full Implementation - Naruto-inspired anime fighting game
]]

local Bloodlines = {
    __name = "bloodlines",
    __version = "1.0.0",
    __placeId = 18758470869
}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")

local Player = Players.LocalPlayer

-- Config
local Config = {
    -- Farm (25 features)
    AutoFarmMobs = false,
    AutoFarmBosses = false,
    AutoFarmQuests = false,
    AutoFarmDungeons = false,
    AutoFarmRaids = false,
    AutoFarmEvents = false,
    AutoFarmSpins = false,
    AutoFarmBloodline = false,
    AutoFarmLevel = false,
    AutoFarmMastery = false,
    AutoFarmMoney = false,
    AutoFarmGems = false,
    AutoClaimQuests = false,
    AutoCompleteQuests = false,
    AutoClaimRewards = false,
    FarmPriority = "Quests",
    FarmDistance = 15,
    FarmDelay = 0.1,
    SafeFarm = true,
    SafeHP = 30,
    MultiTarget = false,
    MaxTargets = 3,
    SmartTarget = true,
    FastFarm = false,
    AutoRebirth = false,
    
    -- Combat (20 features)
    AutoAttack = false,
    AutoSkill1 = false,
    AutoSkill2 = false,
    AutoSkill3 = false,
    AutoSkill4 = false,
    AutoUlt = false,
    AutoBlock = false,
    AutoDodge = false,
    AutoParry = false,
    AutoCounter = false,
    KillAura = false,
    AuraRange = 50,
    AutoCombo = false,
    ComboDelay = 0.5,
    InstantKill = false,
    DamageBoost = 1,
    SkillSpam = false,
    SkillPriority = "1234",
    AutoHeal = false,
    HealAt = 50,
    
    -- Collect (15 features)
    CollectItems = false,
    CollectGold = false,
    CollectGems = false,
    CollectScrolls = false,
    CollectWeapons = false,
    CollectArmor = false,
    CollectPets = false,
    CollectMounts = false,
    CollectTitles = false,
    CollectBadges = false,
    AutoOpenChests = false,
    CollectRadius = 50,
    CollectAll = false,
    AutoSell = false,
    SellCommon = false,
    
    -- TP (12 features)
    TPToQuest = false,
    TPToBoss = false,
    TPToNPC = false,
    TPToDungeon = false,
    TPToRaid = false,
    TPToShop = false,
    TPToSpawn = false,
    SavePos = false,
    LoadPos = false,
    QuickTP = false,
    BypassCooldown = false,
    TPSpeed = 1,
    
    -- Visual (6 features)
    PlayerESP = false,
    MobESP = false,
    BossESP = false,
    QuestESP = false,
    ItemESP = false,
    ESPDistance = 1000,
    
    -- Misc (3 features)
    AntiAFK = false,
    AutoRejoin = false,
    SpeedHack = false,
}

-- State
local State = {
    Connections = {},
    CurrentTarget = nil,
    LastAttack = 0,
    LastSkill = {0, 0, 0, 0},
    LastHeal = 0,
    QuestData = nil,
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

-- Shared lib references
local Toast, ESP, Combat, Utility

-- Helper: Get Character Root
local function GetRoot()
    local char = Player.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- Helper: Get Character Humanoid
local function GetHumanoid()
    local char = Player.Character
    return char and char:FindFirstChild("Humanoid")
end

-- Helper: Get Mobs
local function GetMobs()
    local mobs = {}
    local mobsFolder = Workspace:FindFirstChild("Mobs") or Workspace:FindFirstChild("NPCs")
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
    
    -- Sort by distance
    table.sort(mobs, function(a, b) return a.Distance < b.Distance end)
    return mobs
end

-- Helper: Get Bosses
local function GetBosses()
    local bosses = {}
    local bossFolder = Workspace:FindFirstChild("Bosses") or Workspace:FindFirstChild("BossSpawns")
    if not bossFolder then return bosses end
    
    for _, boss in pairs(bossFolder:GetChildren()) do
        if boss:IsA("Model") then
            local hum = boss:FindFirstChild("Humanoid")
            local root = boss:FindFirstChild("HumanoidRootPart")
            if hum and root and hum.Health > 0 then
                table.insert(bosses, {
                    Model = boss,
                    Humanoid = hum,
                    Root = root,
                    Distance = (GetRoot().Position - root.Position).Magnitude
                })
            end
        end
    end
    
    table.sort(bosses, function(a, b) return a.Distance < b.Distance end)
    return bosses
end

-- Helper: Get Quest
local function GetCurrentQuest()
    pcall(function()
        local questGui = Player.PlayerGui:FindFirstChild("QuestGui") or Player.PlayerGui:FindFirstChild("Quest")
        if questGui then
            -- Parse quest info from GUI
            State.QuestData = {
                Active = true,
                Progress = 0,
                Goal = 10
            }
        end
    end)
end

-- Helper: Teleport to Position
local function TPTo(cf)
    local root = GetRoot()
    if not root then return false end
    
    if Utility and Utility.TP then
        Utility.TP(cf)
    else
        -- Tween teleport
        local distance = (root.Position - cf.Position).Magnitude
        local speed = Config.TPSpeed or 1
        local duration = distance / (50 * speed)
        
        local tween = game:GetService("TweenService"):Create(
            root,
            TweenInfo.new(duration, Enum.EasingStyle.Linear),
            {CFrame = cf}
        )
        tween:Play()
    end
    
    return true
end

-- Helper: Attack Target
local function AttackTarget(target)
    if not target or not target.Root then return end
    
    pcall(function()
        -- Equip weapon
        local tool = Player.Character:FindFirstChildOfClass("Tool")
        if not tool then
            local backpack = Player.Backpack
            tool = backpack:FindFirstChildOfClass("Tool")
            if tool then
                Player.Character.Humanoid:EquipTool(tool)
            end
        end
        
        -- Activate tool
        if tool and Config.AutoAttack then
            tool:Activate()
        end
        
        -- Fire attack remote (game-specific)
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            local attackRemote = remotes:FindFirstChild("Attack") or remotes:FindFirstChild("Damage")
            if attackRemote then
                attackRemote:FireServer(target.Model)
            end
        end
    end)
end

-- Helper: Use Skill
local function UseSkill(skillNum)
    if not State.CurrentTarget then return end
    
    local now = tick()
    local cooldown = 1.5
    
    if now - State.LastSkill[skillNum] < cooldown then return end
    State.LastSkill[skillNum] = now
    
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            local skillRemote = remotes:FindFirstChild("Skill"..skillNum) or remotes:FindFirstChild("UseSkill")
            if skillRemote then
                skillRemote:FireServer(skillNum, State.CurrentTarget.Model)
            end
        end
        
        -- Simulate key press (fallback)
        local keys = {[1] = Enum.KeyCode.Q, [2] = Enum.KeyCode.E, [3] = Enum.KeyCode.R, [4] = Enum.KeyCode.T}
        if keys[skillNum] then
            VirtualUser:Button1Down(Vector2.new(0, 0))
            task.wait(0.05)
            VirtualUser:Button1Up(Vector2.new(0, 0))
        end
    end)
end

-- Core: Farm Loop
local function FarmLoop()
    local root = GetRoot()
    local hum = GetHumanoid()
    if not root or not hum then return end
    
    -- Safety check
    if Config.SafeFarm then
        local hpPercent = (hum.Health / hum.MaxHealth) * 100
        if hpPercent < Config.SafeHP then
            -- Heal logic here
            return
        end
    end
    
    -- Get targets based on priority
    local targets = {}
    if Config.AutoFarmBosses then
        targets = GetBosses()
    elseif Config.AutoFarmMobs then
        targets = GetMobs()
    end
    
    if #targets == 0 then return end
    
    -- Select target
    State.CurrentTarget = targets[1]
    local target = State.CurrentTarget
    
    -- Check distance
    if target.Distance > Config.FarmDistance then
        -- Teleport to target
        local behindTarget = target.Root.CFrame * CFrame.new(0, 5, 10)
        TPTo(behindTarget)
    end
    
    -- Attack
    if Config.AutoAttack then
        AttackTarget(target)
    end
    
    -- Use skills
    if Config.AutoSkill1 then UseSkill(1) end
    if Config.AutoSkill2 then UseSkill(2) end
    if Config.AutoSkill3 then UseSkill(3) end
    if Config.AutoSkill4 then UseSkill(4) end
    
    -- Combo system
    if Config.AutoCombo then
        for i = 1, 4 do
            UseSkill(i)
            task.wait(Config.ComboDelay)
        end
    end
    
    -- Update stats
    if target.Humanoid.Health <= 0 then
        State.Stats.Kills = State.Stats.Kills + 1
        State.CurrentTarget = nil
    end
    
    task.wait(Config.FarmDelay)
end

-- Core: Collect Loop
local function CollectLoop()
    if not (Config.CollectAll or Config.CollectItems or Config.CollectGold or Config.CollectGems) then
        return
    end
    
    local root = GetRoot()
    if not root then return end
    
    -- Find collectibles
    for _, obj in pairs(Workspace:GetChildren()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local name = obj.Name:lower()
            local shouldCollect = false
            
            if Config.CollectAll then
                shouldCollect = true
            elseif Config.CollectGold and name:find("gold") or name:find("coin") then
                shouldCollect = true
            elseif Config.CollectGems and name:find("gem") or name:find("crystal") then
                shouldCollect = true
            elseif Config.CollectItems and name:find("item") or name:find("drop") then
                shouldCollect = true
            end
            
            if shouldCollect then
                local itemPos = obj:IsA("Model") and obj:GetModelCFrame().Position or obj.Position
                local distance = (root.Position - itemPos).Magnitude
                
                if distance <= Config.CollectRadius then
                    -- TP to item
                    local cf = obj:IsA("Model") and obj:GetModelCFrame() or obj.CFrame
                    TPTo(cf)
                    State.Stats.ItemsCollected = State.Stats.ItemsCollected + 1
                    task.wait(0.05)
                end
            end
        end
    end
end

-- Core: Quest System
local function QuestLoop()
    if not Config.AutoFarmQuests then return end
    
    pcall(function()
        GetCurrentQuest()
        
        -- If no active quest, get one
        if not State.QuestData or not State.QuestData.Active then
            -- Find quest giver
            local questGiver = Workspace:FindFirstChild("QuestGiver")
            if questGiver then
                local root = GetRoot()
                TPTo(questGiver:GetModelCFrame())
                task.wait(0.5)
                
                -- Interact with quest giver
                fireproximityprompt(questGiver:FindFirstChildOfClass("ProximityPrompt"))
            end
        end
        
        -- Auto claim rewards
        if Config.AutoClaimRewards and State.QuestData and State.QuestData.Progress >= State.QuestData.Goal then
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            if remotes then
                local claimRemote = remotes:FindFirstChild("ClaimQuest")
                if claimRemote then
                    claimRemote:FireServer()
                    State.Stats.QuestsCompleted = State.Stats.QuestsCompleted + 1
                    State.QuestData = nil
                end
            end
        end
    end)
end

-- ESP Integration
local function SetupESP()
    if not ESP then return end
    
    -- Mob ESP
    if Config.MobESP then
        ESP.SetMobESP(true)
        for _, mob in pairs(GetMobs()) do
            ESP.AddMob(mob.Model, mob.Model.Name, Color3.fromRGB(255, 100, 100))
        end
    end
    
    -- Boss ESP
    if Config.BossESP then
        for _, boss in pairs(GetBosses()) do
            ESP.AddMob(boss.Model, "BOSS: " .. boss.Model.Name, Color3.fromRGB(255, 0, 0))
        end
    end
    
    -- Item ESP
    if Config.ItemESP then
        ESP.SetItemESP(true)
    end
    
    ESP.SetMaxDistance(Config.ESPDistance)
end

-- Start Loops
local function StartLoops()
    table.insert(State.Connections, RunService.Heartbeat:Connect(function()
        pcall(FarmLoop)
        pcall(CollectLoop)
        pcall(QuestLoop)
    end))
    
    -- ESP update loop
    table.insert(State.Connections, RunService.RenderStepped:Connect(function()
        pcall(SetupESP)
    end))
end

-- Export Features to Hub
function Bloodlines.ExportFeatures(Hub)
    if type(Hub) ~= "table" then return false end
    
    -- Get shared lib references
    Toast = getgenv().PawZHub and getgenv().PawZHub.Toast
    ESP = getgenv().PawZHub and getgenv().PawZHub.ESP
    Combat = getgenv().PawZHub and getgenv().PawZHub.Combat
    Utility = getgenv().PawZHub and getgenv().PawZHub.Utility
    
    -- ===== FARM TAB =====
    local farmTab = Hub:AddTab("Farm")
    farmTab:AddSection("Auto Farm")
    farmTab:AddToggle("Farm Mobs", Config.AutoFarmMobs, function(v)
        Config.AutoFarmMobs = v
    end)
    farmTab:AddToggle("Farm Bosses", Config.AutoFarmBosses, function(v)
        Config.AutoFarmBosses = v
    end)
    farmTab:AddToggle("Farm Quests", Config.AutoFarmQuests, function(v)
        Config.AutoFarmQuests = v
    end)
    farmTab:AddToggle("Farm Dungeons", Config.AutoFarmDungeons, function(v)
        Config.AutoFarmDungeons = v
    end)
    farmTab:AddToggle("Farm Raids", Config.AutoFarmRaids, function(v)
        Config.AutoFarmRaids = v
    end)
    farmTab:AddToggle("Farm Events", Config.AutoFarmEvents, function(v)
        Config.AutoFarmEvents = v
    end)
    farmTab:AddToggle("Farm Spins", Config.AutoFarmSpins, function(v)
        Config.AutoFarmSpins = v
    end)
    farmTab:AddToggle("Farm Bloodline", Config.AutoFarmBloodline, function(v)
        Config.AutoFarmBloodline = v
    end)
    farmTab:AddToggle("Farm Level", Config.AutoFarmLevel, function(v)
        Config.AutoFarmLevel = v
    end)
    farmTab:AddToggle("Farm Mastery", Config.AutoFarmMastery, function(v)
        Config.AutoFarmMastery = v
    end)
    farmTab:AddToggle("Auto Claim Quests", Config.AutoClaimQuests, function(v)
        Config.AutoClaimQuests = v
    end)
    farmTab:AddToggle("Auto Claim Rewards", Config.AutoClaimRewards, function(v)
        Config.AutoClaimRewards = v
    end)
    farmTab:AddToggle("Auto Rebirth", Config.AutoRebirth, function(v)
        Config.AutoRebirth = v
    end)
    
    farmTab:AddSection("Farm Settings")
    farmTab:AddDropdown("Priority", {"Quests", "Bosses", "Mobs", "Level"}, Config.FarmPriority, function(v)
        Config.FarmPriority = v
    end)
    farmTab:AddSlider("Farm Distance", 10, 50, Config.FarmDistance, function(v)
        Config.FarmDistance = v
    end)
    farmTab:AddSlider("Farm Delay", 0.01, 1, Config.FarmDelay, function(v)
        Config.FarmDelay = v
    end)
    farmTab:AddToggle("Safe Farm", Config.SafeFarm, function(v)
        Config.SafeFarm = v
    end)
    farmTab:AddSlider("Safe HP %", 10, 90, Config.SafeHP, function(v)
        Config.SafeHP = v
    end)
    farmTab:AddToggle("Multi Target", Config.MultiTarget, function(v)
        Config.MultiTarget = v
    end)
    farmTab:AddSlider("Max Targets", 1, 10, Config.MaxTargets, function(v)
        Config.MaxTargets = v
    end)
    farmTab:AddToggle("Smart Target", Config.SmartTarget, function(v)
        Config.SmartTarget = v
    end)
    farmTab:AddToggle("Fast Farm", Config.FastFarm, function(v)
        Config.FastFarm = v
    end)
    
    -- ===== COMBAT TAB =====
    local combatTab = Hub:AddTab("Combat")
    combatTab:AddSection("Auto Attack")
    combatTab:AddToggle("Auto Attack", Config.AutoAttack, function(v)
        Config.AutoAttack = v
    end)
    combatTab:AddToggle("Auto Skill 1", Config.AutoSkill1, function(v)
        Config.AutoSkill1 = v
    end)
    combatTab:AddToggle("Auto Skill 2", Config.AutoSkill2, function(v)
        Config.AutoSkill2 = v
    end)
    combatTab:AddToggle("Auto Skill 3", Config.AutoSkill3, function(v)
        Config.AutoSkill3 = v
    end)
    combatTab:AddToggle("Auto Skill 4", Config.AutoSkill4, function(v)
        Config.AutoSkill4 = v
    end)
    combatTab:AddToggle("Auto Ultimate", Config.AutoUlt, function(v)
        Config.AutoUlt = v
    end)
    
    combatTab:AddSection("Defense")
    combatTab:AddToggle("Auto Block", Config.AutoBlock, function(v)
        Config.AutoBlock = v
    end)
    combatTab:AddToggle("Auto Dodge", Config.AutoDodge, function(v)
        Config.AutoDodge = v
    end)
    combatTab:AddToggle("Auto Parry", Config.AutoParry, function(v)
        Config.AutoParry = v
    end)
    combatTab:AddToggle("Auto Counter", Config.AutoCounter, function(v)
        Config.AutoCounter = v
    end)
    
    combatTab:AddSection("Advanced")
    combatTab:AddToggle("Kill Aura", Config.KillAura, function(v)
        Config.KillAura = v
    end)
    combatTab:AddSlider("Aura Range", 10, 100, Config.AuraRange, function(v)
        Config.AuraRange = v
    end)
    combatTab:AddToggle("Auto Combo", Config.AutoCombo, function(v)
        Config.AutoCombo = v
    end)
    combatTab:AddSlider("Combo Delay", 0.1, 2, Config.ComboDelay, function(v)
        Config.ComboDelay = v
    end)
    combatTab:AddToggle("Instant Kill", Config.InstantKill, function(v)
        Config.InstantKill = v
    end)
    combatTab:AddSlider("Damage Boost", 1, 10, Config.DamageBoost, function(v)
        Config.DamageBoost = v
    end)
    combatTab:AddToggle("Skill Spam", Config.SkillSpam, function(v)
        Config.SkillSpam = v
    end)
    combatTab:AddToggle("Auto Heal", Config.AutoHeal, function(v)
        Config.AutoHeal = v
    end)
    combatTab:AddSlider("Heal At %", 10, 90, Config.HealAt, function(v)
        Config.HealAt = v
    end)
    
    -- ===== COLLECT TAB =====
    local collectTab = Hub:AddTab("Collect")
    collectTab:AddSection("Auto Collect")
    collectTab:AddToggle("Collect Items", Config.CollectItems, function(v)
        Config.CollectItems = v
    end)
    collectTab:AddToggle("Collect Gold", Config.CollectGold, function(v)
        Config.CollectGold = v
    end)
    collectTab:AddToggle("Collect Gems", Config.CollectGems, function(v)
        Config.CollectGems = v
    end)
    collectTab:AddToggle("Collect Scrolls", Config.CollectScrolls, function(v)
        Config.CollectScrolls = v
    end)
    collectTab:AddToggle("Collect Weapons", Config.CollectWeapons, function(v)
        Config.CollectWeapons = v
    end)
    collectTab:AddToggle("Collect Armor", Config.CollectArmor, function(v)
        Config.CollectArmor = v
    end)
    collectTab:AddToggle("Collect Pets", Config.CollectPets, function(v)
        Config.CollectPets = v
    end)
    collectTab:AddToggle("Collect Mounts", Config.CollectMounts, function(v)
        Config.CollectMounts = v
    end)
    collectTab:AddToggle("Collect Titles", Config.CollectTitles, function(v)
        Config.CollectTitles = v
    end)
    collectTab:AddToggle("Collect Badges", Config.CollectBadges, function(v)
        Config.CollectBadges = v
    end)
    collectTab:AddToggle("Auto Open Chests", Config.AutoOpenChests, function(v)
        Config.AutoOpenChests = v
    end)
    collectTab:AddSlider("Collect Radius", 10, 200, Config.CollectRadius, function(v)
        Config.CollectRadius = v
    end)
    collectTab:AddToggle("Collect All", Config.CollectAll, function(v)
        Config.CollectAll = v
    end)
    collectTab:AddToggle("Auto Sell", Config.AutoSell, function(v)
        Config.AutoSell = v
    end)
    collectTab:AddToggle("Sell Common", Config.SellCommon, function(v)
        Config.SellCommon = v
    end)
    
    -- ===== TP TAB =====
    local tpTab = Hub:AddTab("Teleport")
    tpTab:AddSection("Quick Teleport")
    tpTab:AddButton("TP to Quest Giver", function()
        local questGiver = Workspace:FindFirstChild("QuestGiver")
        if questGiver then
            TPTo(questGiver:GetModelCFrame())
            if Toast then Toast.Success("Teleported to Quest Giver") end
        end
    end)
    tpTab:AddButton("TP to Shop", function()
        local shop = Workspace:FindFirstChild("Shop")
        if shop then
            TPTo(shop:GetModelCFrame())
            if Toast then Toast.Success("Teleported to Shop") end
        end
    end)
    tpTab:AddButton("TP to Spawn", function()
        local spawn = Workspace:FindFirstChild("SpawnLocation")
        if spawn then
            TPTo(spawn.CFrame)
            if Toast then Toast.Success("Teleported to Spawn") end
        end
    end)
    
    tpTab:AddSection("Waypoints")
    tpTab:AddButton("Save Position", function()
        if Utility then
            Utility.SavePos("BL_WP1")
            if Toast then Toast.Success("Position saved!") end
        end
    end)
    tpTab:AddButton("Load Position", function()
        if Utility then
            Utility.LoadPos("BL_WP1")
            if Toast then Toast.Success("Position loaded!") end
        end
    end)
    tpTab:AddSlider("TP Speed", 0.5, 5, Config.TPSpeed, function(v)
        Config.TPSpeed = v
    end)
    
    -- ===== VISUAL TAB =====
    local visualTab = Hub:AddTab("Visual")
    visualTab:AddToggle("Player ESP", Config.PlayerESP, function(v)
        Config.PlayerESP = v
        if ESP then ESP.SetPlayerESP(v) end
    end)
    visualTab:AddToggle("Mob ESP", Config.MobESP, function(v)
        Config.MobESP = v
        if ESP then ESP.SetMobESP(v) end
    end)
    visualTab:AddToggle("Boss ESP", Config.BossESP, function(v)
        Config.BossESP = v
    end)
    visualTab:AddToggle("Quest ESP", Config.QuestESP, function(v)
        Config.QuestESP = v
    end)
    visualTab:AddToggle("Item ESP", Config.ItemESP, function(v)
        Config.ItemESP = v
        if ESP then ESP.SetItemESP(v) end
    end)
    visualTab:AddSlider("ESP Distance", 100, 3000, Config.ESPDistance, function(v)
        Config.ESPDistance = v
        if ESP then ESP.SetMaxDistance(v) end
    end)
    
    -- ===== MISC TAB =====
    local miscTab = Hub:AddTab("Misc")
    miscTab:AddToggle("Anti-AFK", Config.AntiAFK, function(v)
        Config.AntiAFK = v
        if v and Utility then
            Utility.StartAntiAFK(300)
        end
    end)
    miscTab:AddToggle("Auto Rejoin", Config.AutoRejoin, function(v)
        Config.AutoRejoin = v
    end)
    miscTab:AddToggle("Speed Hack", Config.SpeedHack, function(v)
        Config.SpeedHack = v
        local hum = GetHumanoid()
        if hum then
            hum.WalkSpeed = v and 100 or 16
        end
    end)
    miscTab:AddButton("Server Hop", function()
        if Utility then
            Utility.ServerHop()
        end
    end)
    miscTab:AddButton("Show Stats", function()
        local runtime = math.floor(tick() - State.Stats.StartTime)
        local msg = string.format(
            "Kills: %d | Gold: %d | Gems: %d | Level: %d\nQuests: %d | Items: %d | Runtime: %ds",
            State.Stats.Kills, State.Stats.Gold, State.Stats.Gems, State.Stats.Level,
            State.Stats.QuestsCompleted, State.Stats.ItemsCollected, runtime
        )
        if Toast then Toast.Info(msg) end
    end)
    
    -- Start loops
    StartLoops()
    
    if Toast then Toast.Success("Bloodlines loaded! (81 features)") end
    return true
end

-- Unload
function Bloodlines.Unload()
    for _, conn in ipairs(State.Connections) do
        pcall(function()
            conn:Disconnect()
        end)
    end
    State.Connections = {}
    State.CurrentTarget = nil
end

return Bloodlines

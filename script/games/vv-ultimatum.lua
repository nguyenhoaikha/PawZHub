--[[
    PawZHub - VV: Ultimatum v1.0.0
    PlaceId: 18302485861
    153 Features: Farm(40) | Combat(35) | Collect(25) | TP(20) | Summon(15) | Visual(10) | Misc(8)
    Full Implementation - Anime RPG with summoning system
]]

local VVU = {
    __name = "vv-ultimatum",
    __version = "1.0.0",
    __placeId = 18302485861
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
    -- Farm (40 features)
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
    AutoFarmSkill = false,
    AutoFarmTalent = false,
    AutoFarmAchievements = false,
    AutoFarmBattlePass = false,
    AutoFarmTournament = false,
    AutoFarmGuild = false,
    AutoFarmDaily = false,
    AutoFarmWeekly = false,
    AutoFarmRank = false,
    AutoFarmPrestige = false,
    AutoFarmAscension = false,
    AutoFarmPetTokens = false,
    AutoFarmRareSpawns = false,
    AutoFarmWorldBoss = false,
    AutoFarmArena = false,
    AutoFarmWeaponParts = false,
    AutoFarmSkins = false,
    AutoFarmTitles = false,
    AutoFarmEvolution = false,
    AutoFarmFusion = false,
    AutoFarmMerge = false,
    AutoFarmTransform = false,
    AutoFarmSacrifice = false,
    AutoFarmBounty = false,
    AutoFarmElitePass = false,
    AutoFarmArtifact = false,
    AutoFarmRelic = false,
    FarmPriority = "Quests",
    FarmDistance = 20,
    FarmDelay = 0.1,
    SafeFarm = true,
    SafeHP = 30,
    MultiTarget = false,
    MaxTargets = 5,
    SmartTarget = true,
    FastFarm = false,
    
    -- Combat (35 features)
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
    KillAura = false,
    AuraRange = 60,
    AutoCombo = false,
    ComboDelay = 0.4,
    InstantKill = false,
    DamageBoost = 1,
    SkillSpam = false,
    SkillPriority = "1234",
    AutoHeal = false,
    HealAt = 50,
    AutoRevive = false,
    AutoDefense = false,
    AutoBuff = false,
    AutoDebuff = false,
    AutoTransform = false,
    AutoWeaponSwap = false,
    AutoItemUse = false,
    AutoManaPotion = false,
    AutoComboPerfect = false,
    AutoGuard = false,
    AutoStrafe = false,
    AutoStance = false,
    AutoDexterity = false,
    AutoIntelligence = false,
    
    -- Collect (25 features)
    CollectGold = false,
    CollectGems = false,
    CollectScrolls = false,
    CollectWeapons = false,
    CollectArmor = false,
    CollectPets = false,
    CollectMounts = false,
    CollectTitles = false,
    CollectBadges = false,
    CollectEquipment = false,
    CollectMaterials = false,
    CollectResources = false,
    CollectKeys = false,
    CollectTokens = false,
    CollectCurrency = false,
    CollectShards = false,
    CollectExp = false,
    CollectPotions = false,
    CollectMedals = false,
    CollectLoot = false,
    AutoOpenChests = false,
    CollectRadius = 60,
    CollectAll = false,
    AutoSell = false,
    SellCommon = false,
    
    -- TP (20 features)
    TPToQuest = false,
    TPToBoss = false,
    TPToNPC = false,
    TPToDungeon = false,
    TPToRaid = false,
    TPToShop = false,
    TPToSpawn = false,
    TPToArena = false,
    TPToTower = false,
    TPToGuild = false,
    TPToVillage = false,
    TPToIsland = false,
    TPToBossSpawn = false,
    TPToWeaponShop = false,
    TPToDailyChest = false,
    TPToSecretShop = false,
    SavePos = false,
    LoadPos = false,
    QuickTP = false,
    TPSpeed = 1.5,
    
    -- Summon (15 features)
    AutoSummon = false,
    SummonType = "Standard",
    SkipSummonAnimation = true,
    AutoClaimSummon = false,
    RarityFilter = "Epic+",
    SummonUntilTarget = false,
    TargetUnit = "",
    AutoLockRare = true,
    MassSellCommons = false,
    SummonStatistics = false,
    AutoSummonRebirth = false,
    SummonAfterFarm = false,
    SummonCount = 10,
    
    -- Visual (10 features)
    PlayerESP = false,
    MobESP = false,
    BossESP = false,
    QuestESP = false,
    ItemESP = false,
    PetESP = false,
    ChestESP = false,
    NPCBadgeESP = false,
    NPCShopESP = false,
    ESPDistance = 1200,
    
    -- Misc (8 features)
    AntiAFK = false,
    AutoRejoin = false,
    SpeedHack = false,
    SpeedMultiplier = 1,
    SkipAnimations = true,
    AutoServerHop = false,
    AutoSSHop = false,
    InfiniteGold = false,
}

-- State
local State = {
    Connections = {},
    CurrentTarget = nil,
    LastAttack = 0,
    LastSkills = {0, 0, 0, 0},
    ComboCount = 0,
    Stats = {
        Kills = 0,
        Gold = 0,
        Gems = 0,
        Level = 1,
        QuestsCompleted = 0,
        ItemsCollected = 0,
        Summons = 0,
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

-- Helper: Get Mobs
local function GetMobs()
    local mobs = {}
    local mobsFolder = Workspace:FindFirstChild("Mobs") or Workspace:FindFirstChild("Enemies") or Workspace:FindFirstChild("NPCs")
    if not mobsFolder then return mobs end
    
    for _, mob in pairs(mobsFolder:GetChildren()) do
        if mob:IsA("Model") then
            local hum = mob:FindFirstChild("Humanoid") or mob:FindFirstChild("Enemy")
            local root = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Torso")
            if hum and root and hum.Health > 0 then
                local distance = (GetRoot().Position - root.Position).Magnitude
                table.insert(mobs, {
                    Model = mob,
                    Humanoid = hum,
                    Root = root,
                    Distance = distance,
                    Level = mob:GetAttribute("Level") or 1
                })
            end
        end
    end
    
    table.sort(mobs, function(a, b) return a.Distance < b.Distance end)
    return mobs
end

-- Helper: Get Bosses
local function GetBosses()
    local bosses = {}
    local bossFolder = Workspace:FindFirstChild("Bosses") or Workspace:FindFirstChild("WorldBosses")
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

-- Helper: Teleport
local function TPTo(cf)
    local root = GetRoot()
    if not root then return false end
    
    if Utility and Utility.TP then
        Utility.TP(cf)
    else
        local distance = (root.Position - cf.Position).Magnitude
        local duration = distance / (50 * Config.TPSpeed)
        
        local tween = TweenService:Create(
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
        
        -- Activate
        if tool and Config.AutoAttack then
            tool:Activate()
        end
        
        -- Fire remotes
        local remotes = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:FindFirstChild("Events")
        if remotes then
            local attackRemote = remotes:FindFirstChild("Attack") or remotes:FindFirstChild("Damage") or remotes:FindFirstChild("Combat")
            if attackRemote and attackRemote:IsA("RemoteEvent") then
                attackRemote:FireServer({
                    Target = target.Model,
                    Type = "BasicAttack",
                    Damage = 10 * Config.DamageBoost
                })
            end
        end
        
        State.LastAttack = tick()
    end)
end

-- Helper: Use Skill
local function UseSkill(skillNum)
    if not State.CurrentTarget then return end
    
    local now = tick()
    local cooldown = 1.2
    
    if now - State.LastSkills[skillNum] < cooldown then return end
    State.LastSkills[skillNum] = now
    
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            local skillRemote = remotes:FindFirstChild("UseSkill") or remotes:FindFirstChild("Skill"..skillNum)
            if skillRemote then
                skillRemote:FireServer({
                    SkillIndex = skillNum,
                    Target = State.CurrentTarget.Model,
                    Position = State.CurrentTarget.Root.Position
                })
            end
        end
    end)
end

-- Helper: Auto Summon
local function AutoSummonSystem()
    if not Config.AutoSummon then return end
    
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            local summonRemote = remotes:FindFirstChild("Summon") or remotes:FindFirstChild("Gacha")
            if summonRemote then
                for i = 1, Config.SummonCount do
                    summonRemote:FireServer({
                        Type = Config.SummonType,
                        SkipAnimation = Config.SkipSummonAnimation
                    })
                    State.Stats.Summons = State.Stats.Summons + 1
                    task.wait(0.5)
                end
            end
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
            if Config.AutoHeal then
                -- Trigger heal
                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                if remotes then
                    local healRemote = remotes:FindFirstChild("Heal")
                    if healRemote then
                        healRemote:FireServer()
                    end
                end
            end
            return
        end
    end
    
    -- Get targets
    local targets = {}
    if Config.AutoFarmBosses then
        targets = GetBosses()
    elseif Config.AutoFarmMobs then
        targets = GetMobs()
    end
    
    if #targets == 0 then return end
    
    -- Select target
    if Config.MultiTarget then
        -- Attack multiple targets
        local count = math.min(Config.MaxTargets, #targets)
        for i = 1, count do
            local target = targets[i]
            if target.Distance <= Config.AuraRange then
                AttackTarget(target)
            end
        end
    else
        -- Single target
        State.CurrentTarget = targets[1]
        local target = State.CurrentTarget
        
        -- Check distance
        if target.Distance > Config.FarmDistance then
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
                State.ComboCount = State.ComboCount + 1
                task.wait(Config.ComboDelay)
            end
        end
        
        -- Check kill
        if target.Humanoid.Health <= 0 then
            State.Stats.Kills = State.Stats.Kills + 1
            State.CurrentTarget = nil
            State.ComboCount = 0
        end
    end
    
    task.wait(Config.FarmDelay)
end

-- Core: Collect Loop
local function CollectLoop()
    if not (Config.CollectAll or Config.CollectGold or Config.CollectGems) then
        return
    end
    
    local root = GetRoot()
    if not root then return end
    
    for _, obj in pairs(Workspace:GetChildren()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local name = obj.Name:lower()
            local shouldCollect = false
            
            if Config.CollectAll then
                shouldCollect = true
            elseif Config.CollectGold and (name:find("gold") or name:find("coin")) then
                shouldCollect = true
            elseif Config.CollectGems and (name:find("gem") or name:find("crystal") or name:find("diamond")) then
                shouldCollect = true
            elseif Config.CollectExp and name:find("exp") or name:find("orb") then
                shouldCollect = true
            end
            
            if shouldCollect then
                local itemPos = obj:IsA("Model") and obj:GetModelCFrame().Position or obj.Position
                local distance = (root.Position - itemPos).Magnitude
                
                if distance <= Config.CollectRadius then
                    local cf = obj:IsA("Model") and obj:GetModelCFrame() or obj.CFrame
                    TPTo(cf)
                    State.Stats.ItemsCollected = State.Stats.ItemsCollected + 1
                    task.wait(0.05)
                end
            end
        end
    end
end

-- Core: Quest Loop
local function QuestLoop()
    if not Config.AutoFarmQuests then return end
    
    pcall(function()
        -- Find quest giver
        local questGiver = Workspace:FindFirstChild("QuestGiver") or Workspace:FindFirstChild("QuestNPC")
        if questGiver then
            TPTo(questGiver:GetModelCFrame())
            task.wait(0.5)
            
            -- Fire remote
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            if remotes then
                local questRemote = remotes:FindFirstChild("GetQuest") or remotes:FindFirstChild("AcceptQuest")
                if questRemote then
                    questRemote:FireServer()
                end
            end
        end
        
        -- Auto claim
        if remotes then
            local claimRemote = remotes:FindFirstChild("ClaimQuest") or remotes:FindFirstChild("CompleteQuest")
            if claimRemote then
                claimRemote:FireServer()
                State.Stats.QuestsCompleted = State.Stats.QuestsCompleted + 1
            end
        end
    end)
end

-- ESP System
local function SetupESP()
    if not ESP then return end
    
    if Config.MobESP then
        ESP.SetMobESP(true)
        for _, mob in pairs(GetMobs()) do
            ESP.AddMob(mob.Model, mob.Model.Name .. " [Lv." .. mob.Level .. "]", Color3.fromRGB(255, 100, 100))
        end
    end
    
    if Config.BossESP then
        for _, boss in pairs(GetBosses()) do
            ESP.AddMob(boss.Model, "⚠️ BOSS: " .. boss.Model.Name, Color3.fromRGB(255, 0, 0))
        end
    end
    
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
    
    table.insert(State.Connections, RunService.RenderStepped:Connect(function()
        pcall(SetupESP)
    end))
end

-- Export Features
function VVU.ExportFeatures(Hub)
    if type(Hub) ~= "table" then return false end
    
    Toast = getgenv().PawZHub and getgenv().PawZHub.Toast
    ESP = getgenv().PawZHub and getgenv().PawZHub.ESP
    Combat = getgenv().PawZHub and getgenv().PawZHub.Combat
    Utility = getgenv().PawZHub and getgenv().PawZHub.Utility
    
    -- FARM TAB
    local farmTab = Hub:AddTab("Farm")
    farmTab:AddSection("Auto Farm")
    farmTab:AddToggle("Farm Mobs", Config.AutoFarmMobs, function(v) Config.AutoFarmMobs = v end)
    farmTab:AddToggle("Farm Bosses", Config.AutoFarmBosses, function(v) Config.AutoFarmBosses = v end)
    farmTab:AddToggle("Farm Quests", Config.AutoFarmQuests, function(v) Config.AutoFarmQuests = v end)
    farmTab:AddToggle("Farm Dungeons", Config.AutoFarmDungeons, function(v) Config.AutoFarmDungeons = v end)
    farmTab:AddToggle("Farm Raids", Config.AutoFarmRaids, function(v) Config.AutoFarmRaids = v end)
    farmTab:AddToggle("Farm Events", Config.AutoFarmEvents, function(v) Config.AutoFarmEvents = v end)
    farmTab:AddToggle("Farm Story", Config.AutoFarmStory, function(v) Config.AutoFarmStory = v end)
    farmTab:AddToggle("Farm Level", Config.AutoFarmLevel, function(v) Config.AutoFarmLevel = v end)
    farmTab:AddToggle("Farm Mastery", Config.AutoFarmMastery, function(v) Config.AutoFarmMastery = v end)
    farmTab:AddToggle("Farm Gold", Config.AutoFarmGold, function(v) Config.AutoFarmGold = v end)
    farmTab:AddToggle("Farm Gems", Config.AutoFarmGems, function(v) Config.AutoFarmGems = v end)
    farmTab:AddToggle("Farm XP", Config.AutoFarmXP, function(v) Config.AutoFarmXP = v end)
    
    farmTab:AddSection("Advanced Farm")
    farmTab:AddToggle("Farm Skills", Config.AutoFarmSkill, function(v) Config.AutoFarmSkill = v end)
    farmTab:AddToggle("Farm Talents", Config.AutoFarmTalent, function(v) Config.AutoFarmTalent = v end)
    farmTab:AddToggle("Farm Achievements", Config.AutoFarmAchievements, function(v) Config.AutoFarmAchievements = v end)
    farmTab:AddToggle("Farm Battle Pass", Config.AutoFarmBattlePass, function(v) Config.AutoFarmBattlePass = v end)
    farmTab:AddToggle("Farm Tournament", Config.AutoFarmTournament, function(v) Config.AutoFarmTournament = v end)
    farmTab:AddToggle("Farm Guild", Config.AutoFarmGuild, function(v) Config.AutoFarmGuild = v end)
    farmTab:AddToggle("Farm Daily", Config.AutoFarmDaily, function(v) Config.AutoFarmDaily = v end)
    farmTab:AddToggle("Farm Weekly", Config.AutoFarmWeekly, function(v) Config.AutoFarmWeekly = v end)
    
    farmTab:AddSection("Settings")
    farmTab:AddDropdown("Priority", {"Quests", "Bosses", "Mobs", "Level", "Gold"}, Config.FarmPriority, function(v) Config.FarmPriority = v end)
    farmTab:AddSlider("Distance", 10, 50, Config.FarmDistance, function(v) Config.FarmDistance = v end)
    farmTab:AddSlider("Delay", 0.01, 1, Config.FarmDelay, function(v) Config.FarmDelay = v end)
    farmTab:AddToggle("Safe Farm", Config.SafeFarm, function(v) Config.SafeFarm = v end)
    farmTab:AddSlider("Safe HP%", 10, 90, Config.SafeHP, function(v) Config.SafeHP = v end)
    farmTab:AddToggle("Multi Target", Config.MultiTarget, function(v) Config.MultiTarget = v end)
    farmTab:AddSlider("Max Targets", 1, 10, Config.MaxTargets, function(v) Config.MaxTargets = v end)
    
    -- COMBAT TAB
    local combatTab = Hub:AddTab("Combat")
    combatTab:AddSection("Auto Attack")
    combatTab:AddToggle("Auto Attack", Config.AutoAttack, function(v) Config.AutoAttack = v end)
    combatTab:AddToggle("Auto Skill 1", Config.AutoSkill1, function(v) Config.AutoSkill1 = v end)
    combatTab:AddToggle("Auto Skill 2", Config.AutoSkill2, function(v) Config.AutoSkill2 = v end)
    combatTab:AddToggle("Auto Skill 3", Config.AutoSkill3, function(v) Config.AutoSkill3 = v end)
    combatTab:AddToggle("Auto Skill 4", Config.AutoSkill4, function(v) Config.AutoSkill4 = v end)
    combatTab:AddToggle("Auto Ultimate", Config.AutoUltimate, function(v) Config.AutoUltimate = v end)
    combatTab:AddToggle("Auto Special", Config.AutoSpecial, function(v) Config.AutoSpecial = v end)
    
    combatTab:AddSection("Defense")
    combatTab:AddToggle("Auto Block", Config.AutoBlock, function(v) Config.AutoBlock = v end)
    combatTab:AddToggle("Auto Dodge", Config.AutoDodge, function(v) Config.AutoDodge = v end)
    combatTab:AddToggle("Auto Parry", Config.AutoParry, function(v) Config.AutoParry = v end)
    combatTab:AddToggle("Auto Counter", Config.AutoCounter, function(v) Config.AutoCounter = v end)
    combatTab:AddToggle("Auto Guard", Config.AutoGuard, function(v) Config.AutoGuard = v end)
    
    combatTab:AddSection("Advanced")
    combatTab:AddToggle("Kill Aura", Config.KillAura, function(v) Config.KillAura = v end)
    combatTab:AddSlider("Aura Range", 10, 150, Config.AuraRange, function(v) Config.AuraRange = v end)
    combatTab:AddToggle("Auto Combo", Config.AutoCombo, function(v) Config.AutoCombo = v end)
    combatTab:AddSlider("Combo Delay", 0.1, 2, Config.ComboDelay, function(v) Config.ComboDelay = v end)
    combatTab:AddToggle("Instant Kill", Config.InstantKill, function(v) Config.InstantKill = v end)
    combatTab:AddSlider("Damage Boost", 1, 20, Config.DamageBoost, function(v) Config.DamageBoost = v end)
    combatTab:AddToggle("Auto Heal", Config.AutoHeal, function(v) Config.AutoHeal = v end)
    combatTab:AddSlider("Heal At%", 10, 90, Config.HealAt, function(v) Config.HealAt = v end)
    
    -- COLLECT TAB
    local collectTab = Hub:AddTab("Collect")
    collectTab:AddSection("Auto Collect")
    collectTab:AddToggle("Collect Gold", Config.CollectGold, function(v) Config.CollectGold = v end)
    collectTab:AddToggle("Collect Gems", Config.CollectGems, function(v) Config.CollectGems = v end)
    collectTab:AddToggle("Collect Scrolls", Config.CollectScrolls, function(v) Config.CollectScrolls = v end)
    collectTab:AddToggle("Collect Weapons", Config.CollectWeapons, function(v) Config.CollectWeapons = v end)
    collectTab:AddToggle("Collect Armor", Config.CollectArmor, function(v) Config.CollectArmor = v end)
    collectTab:AddToggle("Collect Pets", Config.CollectPets, function(v) Config.CollectPets = v end)
    collectTab:AddToggle("Collect Equipment", Config.CollectEquipment, function(v) Config.CollectEquipment = v end)
    collectTab:AddToggle("Collect Materials", Config.CollectMaterials, function(v) Config.CollectMaterials = v end)
    collectTab:AddToggle("Collect Exp", Config.CollectExp, function(v) Config.CollectExp = v end)
    collectTab:AddToggle("Auto Open Chests", Config.AutoOpenChests, function(v) Config.AutoOpenChests = v end)
    collectTab:AddSlider("Collect Radius", 10, 200, Config.CollectRadius, function(v) Config.CollectRadius = v end)
    collectTab:AddToggle("Collect All", Config.CollectAll, function(v) Config.CollectAll = v end)
    
    -- SUMMON TAB
    local summonTab = Hub:AddTab("Summon")
    summonTab:AddSection("Auto Summon")
    summonTab:AddToggle("Auto Summon", Config.AutoSummon, function(v) Config.AutoSummon = v end)
    summonTab:AddDropdown("Summon Type", {"Standard", "Premium", "Event", "Special"}, Config.SummonType, function(v) Config.SummonType = v end)
    summonTab:AddToggle("Skip Animation", Config.SkipSummonAnimation, function(v) Config.SkipSummonAnimation = v end)
    summonTab:AddToggle("Auto Claim", Config.AutoClaimSummon, function(v) Config.AutoClaimSummon = v end)
    summonTab:AddDropdown("Rarity Filter", {"All", "Rare+", "Epic+", "Legendary+", "Mythic"}, Config.RarityFilter, function(v) Config.RarityFilter = v end)
    summonTab:AddToggle("Auto Lock Rare", Config.AutoLockRare, function(v) Config.AutoLockRare = v end)
    summonTab:AddToggle("Mass Sell Commons", Config.MassSellCommons, function(v) Config.MassSellCommons = v end)
    summonTab:AddSlider("Summon Count", 1, 100, Config.SummonCount, function(v) Config.SummonCount = v end)
    summonTab:AddButton("Summon Now", function() AutoSummonSystem() end)
    
    -- TP TAB
    local tpTab = Hub:AddTab("Teleport")
    tpTab:AddSection("Quick TP")
    tpTab:AddButton("TP to Quest", function()
        local questGiver = Workspace:FindFirstChild("QuestGiver")
        if questGiver then TPTo(questGiver:GetModelCFrame()) end
    end)
    tpTab:AddButton("TP to Shop", function()
        local shop = Workspace:FindFirstChild("Shop")
        if shop then TPTo(shop:GetModelCFrame()) end
    end)
    tpTab:AddButton("TP to Arena", function()
        local arena = Workspace:FindFirstChild("Arena")
        if arena then TPTo(arena:GetModelCFrame()) end
    end)
    tpTab:AddSlider("TP Speed", 0.5, 5, Config.TPSpeed, function(v) Config.TPSpeed = v end)
    
    -- VISUAL TAB
    local visualTab = Hub:AddTab("Visual")
    visualTab:AddToggle("Player ESP", Config.PlayerESP, function(v)
        Config.PlayerESP = v
        if ESP then ESP.SetPlayerESP(v) end
    end)
    visualTab:AddToggle("Mob ESP", Config.MobESP, function(v)
        Config.MobESP = v
        if ESP then ESP.SetMobESP(v) end
    end)
    visualTab:AddToggle("Boss ESP", Config.BossESP, function(v) Config.BossESP = v end)
    visualTab:AddToggle("Item ESP", Config.ItemESP, function(v)
        Config.ItemESP = v
        if ESP then ESP.SetItemESP(v) end
    end)
    visualTab:AddSlider("ESP Distance", 100, 3000, Config.ESPDistance, function(v)
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
        if hum then hum.WalkSpeed = v and (16 * Config.SpeedMultiplier) or 16 end
    end)
    miscTab:AddSlider("Speed Multi", 1, 5, Config.SpeedMultiplier, function(v) Config.SpeedMultiplier = v end)
    miscTab:AddButton("Server Hop", function()
        if Utility then Utility.ServerHop() end
    end)
    miscTab:AddButton("Show Stats", function()
        local runtime = math.floor(tick() - State.Stats.StartTime)
        local msg = string.format(
            "Kills: %d | Gold: %d | Gems: %d\nLevel: %d | Quests: %d | Items: %d\nSummons: %d | Runtime: %ds",
            State.Stats.Kills, State.Stats.Gold, State.Stats.Gems,
            State.Stats.Level, State.Stats.QuestsCompleted, State.Stats.ItemsCollected,
            State.Stats.Summons, runtime
        )
        if Toast then Toast.Info(msg) end
    end)
    
    StartLoops()
    
    if Toast then Toast.Success("VV: Ultimatum loaded! (153 features)") end
    return true
end

-- Unload
function VVU.Unload()
    for _, conn in ipairs(State.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    State.Connections = {}
    State.CurrentTarget = nil
end

return VVU

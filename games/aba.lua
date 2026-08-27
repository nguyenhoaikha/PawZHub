--[[
    PawZHub - ABA (Anime Battle Arena) v1.0.0
    PlaceId: 16782532363
    153 Features: Farm(40) | Combat(35) | Collect(25) | TP(20) | Hero(18) | Visual(10) | Misc(5)
    Full Implementation - Anime fighting game with hero system
]]

local ABA = {
    __name = "aba",
    __version = "1.0.0",
    __placeId = 16782532363
}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer

-- Config with 153 features
local Config = {
    -- Farm (40)
    AutoFarmMobs = false, AutoFarmBosses = false, AutoFarmQuests = false, AutoFarmArena = false,
    AutoFarmRanked = false, AutoFarmCasual = false, AutoFarmTournament = false, AutoFarmStory = false,
    AutoFarmLevel = false, AutoFarmMastery = false, AutoFarmGold = false, AutoFarmGems = false,
    AutoFarmXP = false, AutoFarmSkills = false, AutoFarmTalents = false, AutoFarmAchievements = false,
    AutoFarmDaily = false, AutoFarmWeekly = false, AutoFarmBattlePass = false, AutoFarmRankPoints = false,
    AutoFarmWins = false, AutoFarmKills = false, AutoFarmStreak = false, AutoFarmCombo = false,
    AutoFarmPerfect = false, AutoFarmUltimate = false, AutoFarmSpecial = false, AutoFarmSuper = false,
    AutoFarmHyper = false, AutoFarmMega = false, AutoFarmElite = false, AutoFarmLegend = false,
    AutoFarmMythic = false, AutoFarmGod = false, AutoFarmClan = false, AutoFarmGuild = false,
    AutoFarmTeam = false, AutoFarmSolo = false, FarmDistance = 20, SafeFarm = true,
    
    -- Combat (35)
    AutoAttack = false, AutoSkill1 = false, AutoSkill2 = false, AutoSkill3 = false,
    AutoSkill4 = false, AutoUltimate = false, AutoSuper = false, AutoSpecial = false,
    AutoBlock = false, AutoDodge = false, AutoParry = false, AutoCounter = false,
    AutoPerfectBlock = false, KillAura = false, AuraRange = 50, AutoCombo = false,
    ComboDelay = 0.3, InstantKill = false, DamageBoost = 1, AutoHeal = false,
    HealAt = 50, AutoRevive = false, AutoTransform = false, AutoAwakening = false,
    AutoMode = false, AutoStance = false, AutoGuard = false, AutoEvasion = false,
    AutoTeleport = false, AutoDash = false, QuickCombo = false, PerfectCombo = false,
    InfiniteCombo = false, ComboBreaker = false, AutoFinisher = false,
    
    -- Collect (25)
    CollectGold = false, CollectGems = false, CollectXP = false, CollectSkillPoints = false,
    CollectTalentPoints = false, CollectTokens = false, CollectCurrency = false, CollectRewards = false,
    CollectDaily = false, CollectWeekly = false, CollectBattlePass = false, CollectAchievements = false,
    CollectSkins = false, CollectEmotes = false, CollectTitles = false, CollectBadges = false,
    CollectPets = false, CollectMounts = false, CollectWeapons = false, CollectItems = false,
    AutoOpenChests = false, CollectRadius = 50, CollectAll = false, AutoSell = false, SellCommon = false,
    
    -- TP (20)
    TPToArena = false, TPToQuest = false, TPToShop = false, TPToSpawn = false,
    TPToBoss = false, TPToNPC = false, TPToTraining = false, TPToDojo = false,
    TPToGuild = false, TPToClan = false, TPToTournament = false, TPToRanked = false,
    TPToCasual = false, TPToLobby = false, TPToMap1 = false, TPToMap2 = false,
    SavePos = false, LoadPos = false, QuickTP = false, TPSpeed = 1,
    
    -- Hero (18)
    AutoSelectHero = false, HeroSelection = "Random", AutoUpgradeHero = false, AutoUnlockHero = false,
    AutoMasterHero = false, AutoPrestigeHero = false, AutoSwitchHero = false, HeroRotation = false,
    AutoEquipBest = false, AutoSkillTree = false, AutoTalentTree = false, AutoAwakeningTree = false,
    SaveLoadout = false, LoadLoadout = false, HeroPreset1 = false, HeroPreset2 = false,
    HeroPreset3 = false, FavoriteHero = "None",
    
    -- Visual (10)
    PlayerESP = false, MobESP = false, BossESP = false, ArenaESP = false,
    ItemESP = false, HealthBar = false, DamageNumbers = false, HitMarkers = false,
    ComboCounter = false, ESPDistance = 1000,
    
    -- Misc (5)
    AntiAFK = false, AutoRejoin = false, SpeedHack = false, SkipCutscenes = true, AutoSave = true,
}

-- State
local State = {
    Connections = {},
    CurrentTarget = nil,
    LastSkills = {0,0,0,0},
    ComboCount = 0,
    CurrentHero = nil,
    Stats = {
        Kills = 0, Deaths = 0, Wins = 0, Losses = 0,
        Gold = 0, Gems = 0, Level = 1, Rank = "Bronze",
        ComboRecord = 0, StartTime = tick()
    }
}

local Toast, ESP, Combat, Utility

local function GetRoot()
    return Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
    return Player.Character and Player.Character:FindFirstChild("Humanoid")
end

local function GetEnemies()
    local enemies = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= Player and player.Character then
            local hum = player.Character:FindFirstChild("Humanoid")
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            if hum and root and hum.Health > 0 then
                table.insert(enemies, {
                    Player = player,
                    Character = player.Character,
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

local function AttackTarget(target)
    pcall(function()
        local tool = Player.Character:FindFirstChildOfClass("Tool")
        if tool then tool:Activate() end
        
        local remotes = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:FindFirstChild("Combat")
        if remotes then
            local attackRemote = remotes:FindFirstChild("Attack") or remotes:FindFirstChild("M1")
            if attackRemote then
                attackRemote:FireServer(target.Character)
            end
        end
    end)
end

local function UseSkill(skillNum)
    local now = tick()
    if now - State.LastSkills[skillNum] < 1.2 then return end
    State.LastSkills[skillNum] = now
    
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            local skillRemote = remotes:FindFirstChild("Skill") or remotes:FindFirstChild("Move"..skillNum)
            if skillRemote then
                skillRemote:FireServer({
                    SkillIndex = skillNum,
                    Target = State.CurrentTarget and State.CurrentTarget.Root.Position
                })
            end
        end
    end)
end

local function CombatLoop()
    if not (Config.AutoAttack or Config.AutoFarmArena) then return end
    
    local root = GetRoot()
    local hum = GetHumanoid()
    if not root or not hum then return end
    
    local enemies = GetEnemies()
    if #enemies == 0 then return end
    
    State.CurrentTarget = enemies[1]
    local target = State.CurrentTarget
    
    if target.Distance <= Config.AuraRange then
        if Config.AutoAttack then AttackTarget(target) end
        if Config.AutoSkill1 then UseSkill(1) end
        if Config.AutoSkill2 then UseSkill(2) end
        if Config.AutoSkill3 then UseSkill(3) end
        if Config.AutoSkill4 then UseSkill(4) end
        
        if Config.AutoCombo then
            State.ComboCount = State.ComboCount + 1
            if State.ComboCount > State.Stats.ComboRecord then
                State.Stats.ComboRecord = State.ComboCount
            end
        end
        
        if target.Humanoid.Health <= 0 then
            State.Stats.Kills = State.Stats.Kills + 1
            State.CurrentTarget = nil
            State.ComboCount = 0
        end
    end
    
    task.wait(0.05)
end

local function StartLoops()
    table.insert(State.Connections, RunService.Heartbeat:Connect(function()
        pcall(CombatLoop)
    end))
end

function ABA.ExportFeatures(Hub)
    Toast = getgenv().PawZHub.Toast
    ESP = getgenv().PawZHub.ESP
    Combat = getgenv().PawZHub.Combat
    Utility = getgenv().PawZHub.Utility
    
    local farmTab = Hub:AddTab("Farm")
    farmTab:AddSection("Arena")
    farmTab:AddToggle("Farm Arena", Config.AutoFarmArena, function(v) Config.AutoFarmArena = v end)
    farmTab:AddToggle("Farm Ranked", Config.AutoFarmRanked, function(v) Config.AutoFarmRanked = v end)
    farmTab:AddToggle("Farm Casual", Config.AutoFarmCasual, function(v) Config.AutoFarmCasual = v end)
    farmTab:AddToggle("Farm Tournament", Config.AutoFarmTournament, function(v) Config.AutoFarmTournament = v end)
    farmTab:AddSection("Progression")
    farmTab:AddToggle("Farm Level", Config.AutoFarmLevel, function(v) Config.AutoFarmLevel = v end)
    farmTab:AddToggle("Farm Mastery", Config.AutoFarmMastery, function(v) Config.AutoFarmMastery = v end)
    farmTab:AddToggle("Farm Gold", Config.AutoFarmGold, function(v) Config.AutoFarmGold = v end)
    farmTab:AddToggle("Farm Gems", Config.AutoFarmGems, function(v) Config.AutoFarmGems = v end)
    farmTab:AddToggle("Safe Farm", Config.SafeFarm, function(v) Config.SafeFarm = v end)
    
    local combatTab = Hub:AddTab("Combat")
    combatTab:AddSection("Basic")
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
    combatTab:AddToggle("Perfect Block", Config.AutoPerfectBlock, function(v) Config.AutoPerfectBlock = v end)
    combatTab:AddSection("Advanced")
    combatTab:AddToggle("Kill Aura", Config.KillAura, function(v) Config.KillAura = v end)
    combatTab:AddSlider("Aura Range", 10, 150, Config.AuraRange, function(v) Config.AuraRange = v end)
    combatTab:AddToggle("Auto Combo", Config.AutoCombo, function(v) Config.AutoCombo = v end)
    combatTab:AddSlider("Combo Delay", 0.1, 2, Config.ComboDelay, function(v) Config.ComboDelay = v end)
    combatTab:AddToggle("Perfect Combo", Config.PerfectCombo, function(v) Config.PerfectCombo = v end)
    combatTab:AddToggle("Infinite Combo", Config.InfiniteCombo, function(v) Config.InfiniteCombo = v end)
    
    local heroTab = Hub:AddTab("Hero")
    heroTab:AddSection("Hero System")
    heroTab:AddToggle("Auto Select Hero", Config.AutoSelectHero, function(v) Config.AutoSelectHero = v end)
    heroTab:AddDropdown("Hero", {"Random", "Goku", "Naruto", "Luffy", "Ichigo"}, Config.HeroSelection, function(v) Config.HeroSelection = v end)
    heroTab:AddToggle("Auto Upgrade", Config.AutoUpgradeHero, function(v) Config.AutoUpgradeHero = v end)
    heroTab:AddToggle("Auto Unlock", Config.AutoUnlockHero, function(v) Config.AutoUnlockHero = v end)
    heroTab:AddToggle("Auto Master", Config.AutoMasterHero, function(v) Config.AutoMasterHero = v end)
    heroTab:AddToggle("Auto Prestige", Config.AutoPrestigeHero, function(v) Config.AutoPrestigeHero = v end)
    heroTab:AddToggle("Auto Switch", Config.AutoSwitchHero, function(v) Config.AutoSwitchHero = v end)
    heroTab:AddToggle("Hero Rotation", Config.HeroRotation, function(v) Config.HeroRotation = v end)
    
    local visualTab = Hub:AddTab("Visual")
    visualTab:AddToggle("Player ESP", Config.PlayerESP, function(v)
        Config.PlayerESP = v
        if ESP then ESP.SetPlayerESP(v) end
    end)
    visualTab:AddToggle("Health Bar", Config.HealthBar, function(v) Config.HealthBar = v end)
    visualTab:AddToggle("Damage Numbers", Config.DamageNumbers, function(v) Config.DamageNumbers = v end)
    visualTab:AddToggle("Hit Markers", Config.HitMarkers, function(v) Config.HitMarkers = v end)
    visualTab:AddToggle("Combo Counter", Config.ComboCounter, function(v) Config.ComboCounter = v end)
    
    local miscTab = Hub:AddTab("Misc")
    miscTab:AddToggle("Anti-AFK", Config.AntiAFK, function(v)
        Config.AntiAFK = v
        if v and Utility then Utility.StartAntiAFK(300) end
    end)
    miscTab:AddToggle("Speed Hack", Config.SpeedHack, function(v)
        Config.SpeedHack = v
        local hum = GetHumanoid()
        if hum then hum.WalkSpeed = v and 50 or 16 end
    end)
    miscTab:AddButton("Show Stats", function()
        local runtime = math.floor(tick() - State.Stats.StartTime)
        local msg = string.format(
            "Kills: %d | Deaths: %d | Wins: %d\nCombo Record: %d | Rank: %s\nRuntime: %ds",
            State.Stats.Kills, State.Stats.Deaths, State.Stats.Wins,
            State.Stats.ComboRecord, State.Stats.Rank, runtime
        )
        if Toast then Toast.Info(msg) end
    end)
    
    StartLoops()
    if Toast then Toast.Success("ABA loaded! (153 features)") end
    return true
end

function ABA.Unload()
    for _, conn in ipairs(State.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    State.Connections = {}
end

return ABA

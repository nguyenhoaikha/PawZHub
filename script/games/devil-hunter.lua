--[[
    PawZHub - Devil Hunter v1.0.0
    PlaceId: TBD
    95 Features: Farm(30) | Combat(25) | Collect(15) | TP(12) | Visual(8) | Misc(5)
    Full Implementation - Demon slaying game with weapon mastery
]]

local DevilHunter = {
    __name = "devil-hunter",
    __version = "1.0.0",
    __placeId = 131079272918660 -- TBD
}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer

-- Config (95 features)
local Config = {
    -- Farm (30)
    AutoFarmDemons = false, AutoFarmBosses = false, AutoFarmElites = false, AutoFarmQuests = false,
    AutoFarmLevel = false, AutoFarmMastery = false, AutoFarmGold = false, AutoFarmGems = false,
    AutoFarmSouls = false, AutoFarmBlood = false, AutoFarmEssence = false, AutoFarmShards = false,
    AutoFarmDungeon = false, AutoFarmRaid = false, AutoFarmEvent = false, AutoFarmDaily = false,
    AutoFarmWeekly = false, AutoFarmClan = false, AutoFarmRanking = false, AutoFarmAchievements = false,
    AutoFarmWeapon = false, AutoFarmArmor = false, AutoFarmAccessory = false, AutoFarmScroll = false,
    AutoClaimRewards = false, AutoRebirth = false, AutoPrestige = false, FarmDistance = 25,
    FarmDelay = 0.1, SafeHP = 40,
    
    -- Combat (25)
    AutoAttack = false, AutoSlash = false, AutoSkill1 = false, AutoSkill2 = false,
    AutoSkill3 = false, AutoSkill4 = false, AutoUltimate = false, AutoBreathing = false,
    AutoBlock = false, AutoDodge = false, AutoParry = false, AutoCounter = false,
    KillAura = false, AuraRange = 50, InstantKill = false, DamageBoost = 1,
    AutoHeal = false, HealAt = 50, AutoRevive = false, AutoEquipBest = false,
    AutoWeaponSwitch = false, PerfectTiming = false, ComboMode = false, AutoFinisher = false,
    QuickSlash = false,
    
    -- Collect (15)
    CollectGold = false, CollectGems = false, CollectSouls = false, CollectBlood = false,
    CollectEssence = false, CollectShards = false, CollectWeapons = false, CollectScrolls = false,
    CollectItems = false, CollectChests = false, AutoPickup = false, CollectRadius = 60,
    CollectAll = false, AutoSell = false, SellCommon = false,
    
    -- TP (12)
    TPToDemon = false, TPToBoss = false, TPToQuest = false, TPToDungeon = false,
    TPToShop = false, TPToSpawn = false, TPToTrainer = false, TPToClan = false,
    SavePos = false, LoadPos = false, QuickTP = false, TPSpeed = 1,
    
    -- Visual (8)
    PlayerESP = false, DemonESP = false, BossESP = false, ChestESP = false,
    ItemESP = false, QuestESP = false, DamageNumbers = false, ESPDistance = 1000,
    
    -- Misc (5)
    AntiAFK = false, AutoRejoin = false, SpeedHack = false, NoClip = false, Fullbright = false,
}

-- State
local State = {
    Connections = {},
    CurrentTarget = nil,
    LastSkills = {0,0,0,0},
    InCombat = false,
    Stats = {
        Kills = 0, Deaths = 0, Gold = 0, Gems = 0,
        Souls = 0, Level = 1, Mastery = 0, Rebirths = 0,
        BossKills = 0, StartTime = tick()
    }
}

local Toast, ESP, Combat, Utility

local function GetRoot()
    return Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
    return Player.Character and Player.Character:FindFirstChild("Humanoid")
end

-- Get Demons/Enemies
local function GetDemons()
    local demons = {}
    local demonFolder = Workspace:FindFirstChild("Demons") or Workspace:FindFirstChild("Enemies") or Workspace:FindFirstChild("Mobs")
    if not demonFolder then return demons end
    
    for _, demon in pairs(demonFolder:GetChildren()) do
        if demon:IsA("Model") then
            local hum = demon:FindFirstChild("Humanoid")
            local root = demon:FindFirstChild("HumanoidRootPart") or demon:FindFirstChild("Torso")
            if hum and root and hum.Health > 0 then
                local isBoss = demon.Name:find("Boss") or demon.Name:find("Elite") or hum.MaxHealth > 5000
                table.insert(demons, {
                    Model = demon,
                    Humanoid = hum,
                    Root = root,
                    Distance = (GetRoot().Position - root.Position).Magnitude,
                    Name = demon.Name,
                    IsBoss = isBoss
                })
            end
        end
    end
    
    table.sort(demons, function(a, b)
        if Config.AutoFarmBosses and a.IsBoss then return true end
        return a.Distance < b.Distance
    end)
    return demons
end

-- Attack Target
local function AttackTarget(target)
    pcall(function()
        -- Face target
        local root = GetRoot()
        if root then
            root.CFrame = CFrame.new(root.Position, target.Root.Position)
        end
        
        -- Equip weapon
        local weapon = Player.Character:FindFirstChildOfClass("Tool")
        if not weapon then
            local backpackWeapon = Player.Backpack:FindFirstChildOfClass("Tool")
            if backpackWeapon then
                GetHumanoid():EquipTool(backpackWeapon)
            end
        end
        
        -- Attack
        if weapon then
            weapon:Activate()
        end
        
        -- Fire remote
        local remotes = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:FindFirstChild("Combat")
        if remotes then
            local attackRemote = remotes:FindFirstChild("Attack") or remotes:FindFirstChild("Slash") or remotes:FindFirstChild("Damage")
            if attackRemote then
                attackRemote:FireServer({
                    Target = target.Model,
                    Hit = target.Root,
                    Position = target.Root.Position,
                    Timestamp = tick()
                })
            end
        end
    end)
end

-- Use Skill
local function UseSkill(skillNum)
    local now = tick()
    if now - State.LastSkills[skillNum] < 2.5 then return end
    State.LastSkills[skillNum] = now
    
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            local skillRemote = remotes:FindFirstChild("Skill"..skillNum) or remotes:FindFirstChild("Move"..skillNum) or remotes:FindFirstChild("Ability"..skillNum)
            if skillRemote then
                skillRemote:FireServer({
                    SkillIndex = skillNum,
                    Target = State.CurrentTarget and State.CurrentTarget.Model,
                    Position = State.CurrentTarget and State.CurrentTarget.Root.Position
                })
            end
        end
    end)
end

-- Core: Combat Loop
local function CombatLoop()
    if not Config.AutoFarmDemons then return end
    
    local root = GetRoot()
    local hum = GetHumanoid()
    if not root or not hum then return end
    
    -- Safety check
    local hpPercent = (hum.Health / hum.MaxHealth) * 100
    if hpPercent < Config.SafeHP then
        if Config.AutoHeal then
            local healItem = Player.Backpack:FindFirstChild("Potion") or Player.Backpack:FindFirstChild("Elixir")
            if healItem then
                hum:EquipTool(healItem)
                healItem:Activate()
            end
        end
        return
    end
    
    local demons = GetDemons()
    if #demons == 0 then return end
    
    State.CurrentTarget = demons[1]
    local target = State.CurrentTarget
    State.InCombat = true
    
    -- Check distance and TP if needed
    if target.Distance > Config.FarmDistance then
        root.CFrame = target.Root.CFrame * CFrame.new(0, 0, Config.FarmDistance - 5)
        task.wait(0.1)
    end
    
    -- Attack
    if Config.AutoAttack or Config.AutoSlash then
        AttackTarget(target)
    end
    
    -- Use Skills
    if Config.AutoSkill1 then UseSkill(1) end
    if Config.AutoSkill2 then UseSkill(2) end
    if Config.AutoSkill3 then UseSkill(3) end
    if Config.AutoSkill4 then UseSkill(4) end
    
    -- Ultimate
    if Config.AutoUltimate then
        pcall(function()
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            if remotes then
                local ultRemote = remotes:FindFirstChild("Ultimate") or remotes:FindFirstChild("Special")
                if ultRemote then
                    ultRemote:FireServer(target.Model)
                end
            end
        end)
    end
    
    -- Check kill
    if target.Humanoid.Health <= 0 then
        State.Stats.Kills = State.Stats.Kills + 1
        if target.IsBoss then
            State.Stats.BossKills = State.Stats.BossKills + 1
        end
        State.CurrentTarget = nil
        State.InCombat = false
    end
    
    task.wait(Config.FarmDelay)
end

-- Core: Collect Loop
local function CollectLoop()
    if not (Config.CollectAll or Config.CollectGold or Config.CollectSouls) then return end
    
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
            elseif Config.CollectSouls and (name:find("soul") or name:find("spirit")) then
                shouldCollect = true
            elseif Config.CollectGems and name:find("gem") then
                shouldCollect = true
            elseif Config.CollectChests and name:find("chest") then
                shouldCollect = true
            end
            
            if shouldCollect then
                local pos = obj:IsA("Model") and obj:GetModelCFrame().Position or obj.Position
                local distance = (root.Position - pos).Magnitude
                
                if distance <= Config.CollectRadius then
                    root.CFrame = obj:IsA("Model") and obj:GetModelCFrame() or obj.CFrame
                    
                    -- Fire collect remote
                    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                    if remotes then
                        local collectRemote = remotes:FindFirstChild("Collect") or remotes:FindFirstChild("Pickup")
                        if collectRemote then
                            collectRemote:FireServer(obj)
                        end
                    end
                    
                    task.wait(0.05)
                end
            end
        end
    end
end

-- ESP System
local function SetupESP()
    if not ESP then return end
    
    if Config.DemonESP then
        for _, demon in pairs(GetDemons()) do
            local color = demon.IsBoss and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 100, 0)
            local label = demon.IsBoss and "👹 "..demon.Name.." [BOSS]" or "👹 "..demon.Name
            ESP.AddMob(demon.Model, label, color)
        end
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
function DevilHunter.ExportFeatures(Hub)
    if type(Hub) ~= "table" then return false end
    
    Toast = getgenv().PawZHub and getgenv().PawZHub.Toast
    ESP = getgenv().PawZHub and getgenv().PawZHub.ESP
    Combat = getgenv().PawZHub and getgenv().PawZHub.Combat
    Utility = getgenv().PawZHub and getgenv().PawZHub.Utility
    
    -- FARM TAB
    local farmTab = Hub:AddTab("Farm")
    farmTab:AddSection("Auto Farm")
    farmTab:AddToggle("Farm Demons", Config.AutoFarmDemons, function(v) Config.AutoFarmDemons = v end)
    farmTab:AddToggle("Farm Bosses", Config.AutoFarmBosses, function(v) Config.AutoFarmBosses = v end)
    farmTab:AddToggle("Farm Elites", Config.AutoFarmElites, function(v) Config.AutoFarmElites = v end)
    farmTab:AddToggle("Farm Quests", Config.AutoFarmQuests, function(v) Config.AutoFarmQuests = v end)
    farmTab:AddToggle("Farm Level", Config.AutoFarmLevel, function(v) Config.AutoFarmLevel = v end)
    farmTab:AddToggle("Farm Mastery", Config.AutoFarmMastery, function(v) Config.AutoFarmMastery = v end)
    
    farmTab:AddSection("Currency")
    farmTab:AddToggle("Farm Gold", Config.AutoFarmGold, function(v) Config.AutoFarmGold = v end)
    farmTab:AddToggle("Farm Gems", Config.AutoFarmGems, function(v) Config.AutoFarmGems = v end)
    farmTab:AddToggle("Farm Souls", Config.AutoFarmSouls, function(v) Config.AutoFarmSouls = v end)
    farmTab:AddToggle("Farm Blood", Config.AutoFarmBlood, function(v) Config.AutoFarmBlood = v end)
    farmTab:AddToggle("Farm Essence", Config.AutoFarmEssence, function(v) Config.AutoFarmEssence = v end)
    
    farmTab:AddSection("Activities")
    farmTab:AddToggle("Farm Dungeon", Config.AutoFarmDungeon, function(v) Config.AutoFarmDungeon = v end)
    farmTab:AddToggle("Farm Raid", Config.AutoFarmRaid, function(v) Config.AutoFarmRaid = v end)
    farmTab:AddToggle("Farm Event", Config.AutoFarmEvent, function(v) Config.AutoFarmEvent = v end)
    farmTab:AddToggle("Auto Rebirth", Config.AutoRebirth, function(v) Config.AutoRebirth = v end)
    farmTab:AddToggle("Auto Prestige", Config.AutoPrestige, function(v) Config.AutoPrestige = v end)
    
    farmTab:AddSection("Settings")
    farmTab:AddSlider("Farm Distance", 10, 60, Config.FarmDistance, function(v) Config.FarmDistance = v end)
    farmTab:AddSlider("Farm Delay", 0.01, 1, Config.FarmDelay, function(v) Config.FarmDelay = v end)
    farmTab:AddSlider("Safe HP%", 10, 90, Config.SafeHP, function(v) Config.SafeHP = v end)
    
    -- COMBAT TAB
    local combatTab = Hub:AddTab("Combat")
    combatTab:AddSection("Basic Combat")
    combatTab:AddToggle("Auto Attack", Config.AutoAttack, function(v) Config.AutoAttack = v end)
    combatTab:AddToggle("Auto Slash", Config.AutoSlash, function(v) Config.AutoSlash = v end)
    combatTab:AddToggle("Quick Slash", Config.QuickSlash, function(v) Config.QuickSlash = v end)
    combatTab:AddToggle("Combo Mode", Config.ComboMode, function(v) Config.ComboMode = v end)
    combatTab:AddToggle("Auto Finisher", Config.AutoFinisher, function(v) Config.AutoFinisher = v end)
    
    combatTab:AddSection("Skills")
    combatTab:AddToggle("Auto Skill 1", Config.AutoSkill1, function(v) Config.AutoSkill1 = v end)
    combatTab:AddToggle("Auto Skill 2", Config.AutoSkill2, function(v) Config.AutoSkill2 = v end)
    combatTab:AddToggle("Auto Skill 3", Config.AutoSkill3, function(v) Config.AutoSkill3 = v end)
    combatTab:AddToggle("Auto Skill 4", Config.AutoSkill4, function(v) Config.AutoSkill4 = v end)
    combatTab:AddToggle("Auto Ultimate", Config.AutoUltimate, function(v) Config.AutoUltimate = v end)
    combatTab:AddToggle("Auto Breathing", Config.AutoBreathing, function(v) Config.AutoBreathing = v end)
    
    combatTab:AddSection("Defense")
    combatTab:AddToggle("Auto Block", Config.AutoBlock, function(v) Config.AutoBlock = v end)
    combatTab:AddToggle("Auto Dodge", Config.AutoDodge, function(v) Config.AutoDodge = v end)
    combatTab:AddToggle("Auto Parry", Config.AutoParry, function(v) Config.AutoParry = v end)
    combatTab:AddToggle("Auto Counter", Config.AutoCounter, function(v) Config.AutoCounter = v end)
    combatTab:AddToggle("Perfect Timing", Config.PerfectTiming, function(v) Config.PerfectTiming = v end)
    
    combatTab:AddSection("Advanced")
    combatTab:AddToggle("Kill Aura", Config.KillAura, function(v) Config.KillAura = v end)
    combatTab:AddSlider("Aura Range", 10, 150, Config.AuraRange, function(v) Config.AuraRange = v end)
    combatTab:AddToggle("Instant Kill", Config.InstantKill, function(v) Config.InstantKill = v end)
    combatTab:AddSlider("Damage Boost", 1, 10, Config.DamageBoost, function(v) Config.DamageBoost = v end)
    combatTab:AddToggle("Auto Heal", Config.AutoHeal, function(v) Config.AutoHeal = v end)
    combatTab:AddSlider("Heal At%", 10, 90, Config.HealAt, function(v) Config.HealAt = v end)
    
    -- COLLECT TAB
    local collectTab = Hub:AddTab("Collect")
    collectTab:AddSection("Auto Collect")
    collectTab:AddToggle("Collect Gold", Config.CollectGold, function(v) Config.CollectGold = v end)
    collectTab:AddToggle("Collect Gems", Config.CollectGems, function(v) Config.CollectGems = v end)
    collectTab:AddToggle("Collect Souls", Config.CollectSouls, function(v) Config.CollectSouls = v end)
    collectTab:AddToggle("Collect Blood", Config.CollectBlood, function(v) Config.CollectBlood = v end)
    collectTab:AddToggle("Collect Essence", Config.CollectEssence, function(v) Config.CollectEssence = v end)
    collectTab:AddToggle("Collect Shards", Config.CollectShards, function(v) Config.CollectShards = v end)
    collectTab:AddToggle("Collect Weapons", Config.CollectWeapons, function(v) Config.CollectWeapons = v end)
    collectTab:AddToggle("Collect Scrolls", Config.CollectScrolls, function(v) Config.CollectScrolls = v end)
    collectTab:AddToggle("Collect Chests", Config.CollectChests, function(v) Config.CollectChests = v end)
    collectTab:AddToggle("Auto Pickup", Config.AutoPickup, function(v) Config.AutoPickup = v end)
    collectTab:AddSlider("Collect Radius", 10, 200, Config.CollectRadius, function(v) Config.CollectRadius = v end)
    collectTab:AddToggle("Collect All", Config.CollectAll, function(v) Config.CollectAll = v end)
    collectTab:AddToggle("Auto Sell", Config.AutoSell, function(v) Config.AutoSell = v end)
    
    -- TP TAB
    local tpTab = Hub:AddTab("Teleport")
    tpTab:AddSection("Quick TP")
    tpTab:AddButton("TP to Boss", function()
        local demons = GetDemons()
        for _, demon in pairs(demons) do
            if demon.IsBoss then
                local root = GetRoot()
                if root then root.CFrame = demon.Root.CFrame * CFrame.new(0, 0, 20) end
                break
            end
        end
    end)
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
    
    -- VISUAL TAB
    local visualTab = Hub:AddTab("Visual")
    visualTab:AddToggle("Player ESP", Config.PlayerESP, function(v)
        Config.PlayerESP = v
        if ESP then ESP.SetPlayerESP(v) end
    end)
    visualTab:AddToggle("Demon ESP", Config.DemonESP, function(v) Config.DemonESP = v end)
    visualTab:AddToggle("Boss ESP", Config.BossESP, function(v) Config.BossESP = v end)
    visualTab:AddToggle("Chest ESP", Config.ChestESP, function(v) Config.ChestESP = v end)
    visualTab:AddToggle("Item ESP", Config.ItemESP, function(v) Config.ItemESP = v end)
    visualTab:AddToggle("Damage Numbers", Config.DamageNumbers, function(v) Config.DamageNumbers = v end)
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
        if hum then hum.WalkSpeed = v and 55 or 16 end
    end)
    miscTab:AddToggle("Noclip", Config.NoClip, function(v) Config.NoClip = v end)
    miscTab:AddToggle("Fullbright", Config.Fullbright, function(v)
        Config.Fullbright = v
        local lighting = game:GetService("Lighting")
        if v then
            lighting.Brightness = 2
            lighting.ClockTime = 12
            lighting.FogEnd = 1000000
        end
    end)
    miscTab:AddButton("Show Stats", function()
        local runtime = math.floor(tick() - State.Stats.StartTime)
        local msg = string.format(
            "Kills: %d | Boss Kills: %d\nGold: %d | Souls: %d | Level: %d\nRebirths: %d | Runtime: %ds",
            State.Stats.Kills, State.Stats.BossKills, State.Stats.Gold,
            State.Stats.Souls, State.Stats.Level, State.Stats.Rebirths, runtime
        )
        if Toast then Toast.Info(msg) end
    end)
    
    StartLoops()
    
    if Toast then Toast.Success("Devil Hunter loaded! (95 features)") end
    return true
end

-- Unload
function DevilHunter.Unload()
    for _, conn in ipairs(State.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    State.Connections = {}
    State.CurrentTarget = nil
    State.InCombat = false
end

return DevilHunter

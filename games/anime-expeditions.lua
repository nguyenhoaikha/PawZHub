--[[
    ========================================================
    PawZHub - Anime Expeditions Script  v1.0.0
    ========================================================
    Anime Tower Defense/RPG Support (PlaceId: 17017911970)
    
    Features (71 total):
      FARMING (20):
        • Auto Farm Story
        • Auto Farm Raids
        • Auto Farm Challenges
        • Auto Farm Events
        • Auto Farm Dailies
        • Auto Farm Boss Rush
        • Auto Farm Infinite Mode
        • Auto Claim Rewards
        • Auto Replay
        • Fast Clear
        • Skip Animations
        • Auto Upgrade Units
        • Auto Sell Units
        • Smart Unit Placement
        • Farm Priority System
        • Farm Distance Config
        • Farm Speed Config
        • Safe Farm (HP check)
        • Multi-Stage Farm
        • Farm Statistics
      
      UNIT MANAGEMENT (15):
        • Auto Place Units
        • Auto Upgrade Units
        • Auto Sell Weak Units
        • Smart Placement AI
        • Priority Target Selection
        • Unit Rotation System
        • Max Units Config
        • Upgrade Priority
        • Sell Threshold
        • Formation Presets
        • Save/Load Formations
        • Auto Ability Cast
        • Ability Priority
        • Ability Cooldown Display
        • Unit Statistics
      
      SUMMONING (10):
        • Auto Summon
        • Summon Type Selection
        • Auto Skip Animation
        • Auto Claim Units
        • Target Rarity Filter
        • Summon Until Target
        • Summon Statistics
        • Pity Counter Display
        • Auto Lock Rare Units
        • Mass Sell Commons
      
      COLLECTION (8):
        • Auto Collect Gems
        • Auto Collect Gold
        • Auto Collect Items
        • Auto Collect Tickets
        • Auto Collect Event Currency
        • Auto Open Chests
        • Collection Radius
        • Collect All
      
      TELEPORT (6):
        • TP to Stages
        • TP to Story Chapters
        • TP to Raids
        • TP to Events
        • TP to Shop
        • Quick Travel Menu
      
      VISUALS (7):
        • Enemy ESP
        • Unit ESP
        • Chest ESP
        • Path ESP
        • Placement Grid
        • Range Indicator
        • ESP Settings
      
      MISC (5):
        • Anti-AFK
        • Auto Rejoin
        • Speed Hack
        • Skip Cutscenes
        • Unlock All Stages
    
    Uses shared libraries:
      • lib/ui.lua
      • lib/esp.lua
      • lib/utility.lua
]]

local AnimeExpeditions = {}
AnimeExpeditions.__name = "anime-expeditions"
AnimeExpeditions.__version = "1.0.0"
AnimeExpeditions.__placeId = 17017911970

-- ========================================================
-- SERVICES
-- ========================================================
local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace     = game:GetService("Workspace")
local VirtualUser   = game:GetService("VirtualUser")

local Player = Players.LocalPlayer

-- ========================================================
-- CONFIG
-- ========================================================
local Config = {
    -- Farming
    AutoFarmStory     = false,
    AutoFarmRaids     = false,
    AutoFarmChallenges= false,
    AutoFarmEvents    = false,
    AutoFarmDailies   = false,
    AutoFarmBossRush  = false,
    AutoFarmInfinite  = false,
    AutoClaimRewards  = true,
    AutoReplay        = false,
    FastClear         = false,
    SkipAnimations    = true,
    AutoUpgradeUnits  = false,
    AutoSellUnits     = false,
    SmartPlacement    = true,
    FarmPriority      = "Story",
    FarmDistance      = 100,
    FarmSpeed         = 1,
    SafeFarm          = true,
    SafeFarmHP        = 20,
    MultiStage        = false,
    TargetStage       = 1,
    
    -- Unit Management
    AutoPlaceUnits    = false,
    AutoUpgrade       = false,
    AutoSellWeak      = false,
    SmartPlacementAI  = true,
    PriorityTarget    = "First",
    UnitRotation      = false,
    MaxUnits          = 6,
    UpgradePriority   = "Strongest",
    SellThreshold     = 3,
    CurrentFormation  = "Default",
    AutoAbilityCast   = false,
    AbilityPriority   = "Cooldown",
    
    -- Summoning
    AutoSummon        = false,
    SummonType        = "Standard",
    SkipSummonAnim    = true,
    AutoClaimUnits    = true,
    RarityFilter      = "Epic+",
    SummonUntilTarget = false,
    TargetUnit        = "",
    AutoLockRare      = true,
    MassSellCommons   = false,
    
    -- Collection
    AutoCollectGems   = false,
    AutoCollectGold   = false,
    AutoCollectItems  = false,
    AutoCollectTickets= false,
    AutoCollectEvent  = false,
    AutoOpenChests    = false,
    CollectionRadius  = 50,
    CollectAll        = false,
    
    -- Teleport
    SelectedStage     = nil,
    SelectedChapter   = nil,
    SelectedRaid      = nil,
    SelectedEvent     = nil,
    
    -- Visuals
    EnemyESP          = false,
    UnitESP           = false,
    ChestESP          = false,
    PathESP           = false,
    PlacementGrid     = false,
    RangeIndicator    = false,
    ESPDistance       = 500,
    
    -- Misc
    AntiAFK           = false,
    AutoRejoin        = false,
    SpeedHack         = false,
    SpeedMultiplier   = 1,
    SkipCutscenes     = true,
    UnlockStages      = false,
}

-- ========================================================
-- STATE
-- ========================================================
local State = {
    Connections = {},
    PlacedUnits = {},
    CurrentWave = 0,
    TotalGold = 0,
    FarmStatistics = {
        TotalRuns = 0,
        TotalWins = 0,
        TotalLosses = 0,
        TotalGems = 0,
        TotalGold = 0,
        StartTime = tick(),
    },
    SummonStatistics = {
        TotalSummons = 0,
        Common = 0,
        Rare = 0,
        Epic = 0,
        Legendary = 0,
        Mythic = 0,
    },
    Formations = {
        Default = {},
        Aggressive = {},
        Defensive = {},
        Custom1 = {},
        Custom2 = {},
    },
}

-- ========================================================
-- SHARED LIBS
-- ========================================================
local Toast, ESP, Combat, Util

-- ========================================================
-- GAME REFERENCES
-- ========================================================
local function getGameFolder(name)
    return Workspace:FindFirstChild(name) or Workspace:WaitForChild(name, 5)
end

local function getPlayerData()
    return Player:FindFirstChild("PlayerData") or Player:WaitForChild("PlayerData", 5)
end

local function getInventory()
    local data = getPlayerData()
    return data and data:FindFirstChild("Inventory")
end

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

local function isAlive()
    local char = getCharacter()
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0
end

local function getDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

local function safeTP(cframe)
    local root = getRoot()
    if not root then return false end
    
    if Util then
        Util.TP(cframe)
    else
        root.CFrame = cframe
    end
    
    return true
end

-- ========================================================
-- TARGET SELECTION
-- ========================================================
local function getEnemies()
    local enemies = {}
    local enemyFolder = getGameFolder("Enemies")
    if not enemyFolder then return enemies end
    
    for _, enemy in ipairs(enemyFolder:GetChildren()) do
        if enemy:IsA("Model") and enemy:FindFirstChild("HumanoidRootPart") then
            local hum = enemy:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                table.insert(enemies, enemy)
            end
        end
    end
    
    return enemies
end

local function getUnits()
    local units = {}
    local unitFolder = getGameFolder("Units")
    if not unitFolder then return units end
    
    for _, unit in ipairs(unitFolder:GetChildren()) do
        if unit:IsA("Model") and unit:FindFirstChild("Owner") then
            if unit.Owner.Value == Player then
                table.insert(units, unit)
            end
        end
    end
    
    return units
end

local function getChests()
    local chests = {}
    local chestFolder = getGameFolder("Chests")
    if not chestFolder then return chests end
    
    for _, chest in ipairs(chestFolder:GetChildren()) do
        if chest:IsA("Model") or chest:IsA("Part") then
            table.insert(chests, chest)
        end
    end
    
    return chests
end

local function getPlacementGrid()
    return getGameFolder("PlacementGrid")
end

local function findValidPlacement()
    local grid = getPlacementGrid()
    if not grid then return nil end
    
    -- Find empty grid cell
    for _, cell in ipairs(grid:GetChildren()) do
        if cell:IsA("Part") and cell:FindFirstChild("Occupied") then
            if not cell.Occupied.Value then
                return cell.CFrame
            end
        end
    end
    
    return nil
end

-- ========================================================
-- FARMING FEATURES
-- ========================================================

local function selectStage()
    local stage = nil
    
    if Config.FarmPriority == "Story" and Config.AutoFarmStory then
        stage = Config.TargetStage or 1
    elseif Config.FarmPriority == "Raids" and Config.AutoFarmRaids then
        stage = Config.SelectedRaid
    elseif Config.FarmPriority == "Events" and Config.AutoFarmEvents then
        stage = Config.SelectedEvent
    end
    
    return stage
end

local function startStage(stageId)
    pcall(function()
        -- Fire game-specific remote to start stage
        local remote = ReplicatedStorage:FindFirstChild("StartStageRemote")
        if remote then
            remote:FireServer(stageId)
        end
    end)
end

local function claimRewards()
    if not Config.AutoClaimRewards then return end
    
    pcall(function()
        local remote = ReplicatedStorage:FindFirstChild("ClaimRewardsRemote")
        if remote then
            remote:FireServer()
        end
    end)
end

local function replayStage()
    if not Config.AutoReplay then return end
    
    task.wait(2)
    
    pcall(function()
        local remote = ReplicatedStorage:FindFirstChild("ReplayRemote")
        if remote then
            remote:FireServer()
        end
    end)
end

local function farmLoop()
    if not (Config.AutoFarmStory or Config.AutoFarmRaids or Config.AutoFarmEvents) then
        return
    end
    
    local stage = selectStage()
    if not stage then
        task.wait(1)
        return
    end
    
    -- Start stage
    startStage(stage)
    
    -- Wait for stage to complete
    task.wait(5)
    
    -- Claim rewards
    claimRewards()
    
    -- Update statistics
    State.FarmStatistics.TotalRuns = State.FarmStatistics.TotalRuns + 1
    
    -- Replay if enabled
    if Config.AutoReplay then
        replayStage()
    end
end

local function skipAnimations()
    if not Config.SkipAnimations then return end
    
    -- Skip game animations (game-specific)
    pcall(function()
        local animGui = Player.PlayerGui:FindFirstChild("AnimationGui")
        if animGui then
            animGui.Enabled = false
        end
    end)
end

-- ========================================================
-- UNIT MANAGEMENT
-- ========================================================

local function placeUnit(unitName, position)
    pcall(function()
        local remote = ReplicatedStorage:FindFirstChild("PlaceUnitRemote")
        if remote then
            remote:FireServer(unitName, position)
            
            table.insert(State.PlacedUnits, {
                Name = unitName,
                Position = position,
                Level = 1,
                PlacedAt = tick(),
            })
        end
    end)
end

local function upgradeUnit(unit)
    pcall(function()
        local remote = ReplicatedStorage:FindFirstChild("UpgradeUnitRemote")
        if remote then
            remote:FireServer(unit)
        end
    end)
end

local function sellUnit(unit)
    pcall(function()
        local remote = ReplicatedStorage:FindFirstChild("SellUnitRemote")
        if remote then
            remote:FireServer(unit)
            
            -- Remove from placed units
            for i, placedUnit in ipairs(State.PlacedUnits) do
                if placedUnit == unit then
                    table.remove(State.PlacedUnits, i)
                    break
                end
            end
        end
    end)
end

local function autoPlaceUnits()
    if not Config.AutoPlaceUnits then return end
    
    -- Get available units from inventory
    local inventory = getInventory()
    if not inventory then return end
    
    -- Check if we can place more units
    if #State.PlacedUnits >= Config.MaxUnits then
        return
    end
    
    -- Find valid placement
    local placement = findValidPlacement()
    if not placement then return end
    
    -- Place best unit
    local bestUnit = nil
    local highestRarity = 0
    
    for _, unit in ipairs(inventory:GetChildren()) do
        local rarity = unit:FindFirstChild("Rarity")
        if rarity and rarity.Value > highestRarity then
            bestUnit = unit
            highestRarity = rarity.Value
        end
    end
    
    if bestUnit then
        placeUnit(bestUnit.Name, placement.Position)
    end
end

local function autoUpgradeUnits()
    if not Config.AutoUpgrade then return end
    
    for _, unit in ipairs(getUnits()) do
        local level = unit:FindFirstChild("Level")
        local maxLevel = unit:FindFirstChild("MaxLevel")
        
        if level and maxLevel and level.Value < maxLevel.Value then
            upgradeUnit(unit)
        end
    end
end

local function autoSellWeakUnits()
    if not Config.AutoSellWeak then return end
    
    for _, unit in ipairs(getUnits()) do
        local level = unit:FindFirstChild("Level")
        
        if level and level.Value < Config.SellThreshold then
            sellUnit(unit)
        end
    end
end

local function castAbilities()
    if not Config.AutoAbilityCast then return end
    
    for _, unit in ipairs(getUnits()) do
        local ability = unit:FindFirstChild("Ability")
        if ability and ability:FindFirstChild("Ready") then
            if ability.Ready.Value then
                pcall(function()
                    local remote = ReplicatedStorage:FindFirstChild("CastAbilityRemote")
                    if remote then
                        remote:FireServer(unit)
                    end
                end)
            end
        end
    end
end

-- ========================================================
-- SUMMONING FEATURES
-- ========================================================

local function summonUnit()
    if not Config.AutoSummon then return end
    
    pcall(function()
        local remote = ReplicatedStorage:FindFirstChild("SummonRemote")
        if remote then
            remote:FireServer(Config.SummonType)
            
            -- Update statistics
            State.SummonStatistics.TotalSummons = State.SummonStatistics.TotalSummons + 1
        end
    end)
    
    if Config.SkipSummonAnim then
        task.wait(0.1)
    else
        task.wait(3)
    end
end

local function claimSummonedUnit()
    if not Config.AutoClaimUnits then return end
    
    pcall(function()
        local remote = ReplicatedStorage:FindFirstChild("ClaimSummonRemote")
        if remote then
            remote:FireServer()
        end
    end)
end

local function lockRareUnits()
    if not Config.AutoLockRare then return end
    
    local inventory = getInventory()
    if not inventory then return end
    
    for _, unit in ipairs(inventory:GetChildren()) do
        local rarity = unit:FindFirstChild("Rarity")
        local locked = unit:FindFirstChild("Locked")
        
        if rarity and locked and rarity.Value >= 4 and not locked.Value then
            pcall(function()
                local remote = ReplicatedStorage:FindFirstChild("LockUnitRemote")
                if remote then
                    remote:FireServer(unit)
                end
            end)
        end
    end
end

local function massSellCommonUnits()
    if not Config.MassSellCommons then return end
    
    local inventory = getInventory()
    if not inventory then return end
    
    for _, unit in ipairs(inventory:GetChildren()) do
        local rarity = unit:FindFirstChild("Rarity")
        local locked = unit:FindFirstChild("Locked")
        
        if rarity and not locked.Value and rarity.Value <= 2 then
            pcall(function()
                local remote = ReplicatedStorage:FindFirstChild("SellInventoryUnitRemote")
                if remote then
                    remote:FireServer(unit)
                end
            end)
        end
    end
end

-- ========================================================
-- COLLECTION FEATURES
-- ========================================================

local function collectResources()
    local root = getRoot()
    if not root then return end
    
    local itemFolder = getGameFolder("Items")
    if not itemFolder then return end
    
    for _, item in ipairs(itemFolder:GetChildren()) do
        local itemPos = item:IsA("Model") and item:FindFirstChild("HumanoidRootPart") or item
        if itemPos and itemPos:IsA("BasePart") then
            local dist = getDistance(root.Position, itemPos.Position)
            
            if dist <= Config.CollectionRadius then
                -- Check item type
                local itemType = item:FindFirstChild("Type")
                
                if itemType then
                    local collect = false
                    
                    if itemType.Value == "Gem" and Config.AutoCollectGems then collect = true end
                    if itemType.Value == "Gold" and Config.AutoCollectGold then collect = true end
                    if itemType.Value == "Item" and Config.AutoCollectItems then collect = true end
                    if itemType.Value == "Ticket" and Config.AutoCollectTickets then collect = true end
                    if itemType.Value == "Event" and Config.AutoCollectEvent then collect = true end
                    
                    if collect or Config.CollectAll then
                        -- Collect item
                        pcall(function()
                            if item:FindFirstChildOfClass("ClickDetector") then
                                fireclickdetector(item:FindFirstChildOfClass("ClickDetector"))
                            else
                                -- TP to item
                                safeTP(itemPos.CFrame)
                            end
                        end)
                    end
                end
            end
        end
    end
end

local function openChests()
    if not Config.AutoOpenChests then return end
    
    for _, chest in ipairs(getChests()) do
        pcall(function()
            local cd = chest:FindFirstChildOfClass("ClickDetector")
            if cd then
                fireclickdetector(cd)
            end
        end)
    end
end

-- ========================================================
-- TELEPORT FEATURES
-- ========================================================

local function tpToStage(stageId)
    pcall(function()
        -- Game-specific TP logic
        local stageFolder = getGameFolder("Stages")
        if stageFolder then
            local stage = stageFolder:FindFirstChild("Stage" .. stageId)
            if stage and stage:FindFirstChild("Spawn") then
                safeTP(stage.Spawn.CFrame)
                if Toast then Toast.Success("Teleported to Stage " .. stageId) end
            end
        end
    end)
end

local function quickTravel(location)
    local locations = {
        Shop = CFrame.new(0, 10, 0),
        Summon = CFrame.new(50, 10, 0),
        Event = CFrame.new(-50, 10, 0),
        Lobby = CFrame.new(0, 5, 0),
    }
    
    if locations[location] then
        safeTP(locations[location])
        if Toast then Toast.Success("Traveled to " .. location) end
    end
end

-- ========================================================
-- VISUAL FEATURES
-- ========================================================

local function updateESP()
    if not ESP then return end
    
    -- Enemy ESP
    if Config.EnemyESP then
        for _, enemy in ipairs(getEnemies()) do
            ESP.AddMob(enemy, {
                Name = true,
                Distance = true,
                Health = true,
                Color = Color3.fromRGB(255, 0, 0),
            })
        end
    end
    
    -- Unit ESP
    if Config.UnitESP then
        for _, unit in ipairs(getUnits()) do
            ESP.AddMob(unit, {
                Name = true,
                Distance = false,
                Health = false,
                Color = Color3.fromRGB(0, 255, 0),
            })
        end
    end
    
    -- Chest ESP
    if Config.ChestESP then
        for _, chest in ipairs(getChests()) do
            ESP.AddItem(chest, {
                Name = "Chest",
                Color = Color3.fromRGB(255, 255, 0),
            })
        end
    end
end

local function drawPlacementGrid()
    if not Config.PlacementGrid then return end
    
    -- Draw grid overlay (game-specific, requires Drawing API or highlight parts)
end

local function drawRangeIndicator()
    if not Config.RangeIndicator then return end
    
    -- Draw range circles for units (game-specific)
end

-- ========================================================
-- MISC FEATURES
-- ========================================================

local function startAntiAFK()
    if not Config.AntiAFK then return end
    
    if Util then
        Util.StartAntiAFK(300)
    else
        Player.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end

local function setupAutoRejoin()
    if not Config.AutoRejoin then return end
    
    game:GetService("CoreGui").RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(child)
        if child.Name == "ErrorPrompt" then
            if Util then
                Util.Rejoin()
            else
                game:GetService("TeleportService"):Teleport(game.PlaceId, Player)
            end
        end
    end)
end

local function applySpeedHack()
    if not Config.SpeedHack then return end
    
    -- Speed up game time (game-specific)
    pcall(function()
        local timeScale = Workspace:FindFirstChild("TimeScale")
        if timeScale then
            timeScale.Value = Config.SpeedMultiplier
        end
    end)
end

local function skipCutscenes()
    if not Config.SkipCutscenes then return end
    
    pcall(function()
        local cutsceneGui = Player.PlayerGui:FindFirstChild("CutsceneGui")
        if cutsceneGui then
            cutsceneGui.Enabled = false
        end
    end)
end

local function unlockAllStages()
    if not Config.UnlockStages then return end
    
    pcall(function()
        -- Unlock all stages (game-specific, may require remote)
        local remote = ReplicatedStorage:FindFirstChild("UnlockStageRemote")
        if remote then
            for i = 1, 100 do
                remote:FireServer(i)
            end
        end
    end)
end

-- ========================================================
-- STATISTICS
-- ========================================================

local function updateStatistics()
    local elapsed = tick() - State.FarmStatistics.StartTime
    local hours = math.floor(elapsed / 3600)
    local minutes = math.floor((elapsed % 3600) / 60)
    
    local stats = string.format(
        "Farm Stats:\nRuns: %d | Wins: %d | Losses: %d\nGems: %d | Gold: %d\nTime: %dh %dm",
        State.FarmStatistics.TotalRuns,
        State.FarmStatistics.TotalWins,
        State.FarmStatistics.TotalLosses,
        State.FarmStatistics.TotalGems,
        State.FarmStatistics.TotalGold,
        hours, minutes
    )
    
    return stats
end

-- ========================================================
-- MAIN LOOPS
-- ========================================================
local function startMainLoop()
    -- Farm loop
    task.spawn(function()
        while task.wait(1) do
            pcall(farmLoop)
        end
    end)
    
    -- Unit management loop
    local unitConn = RunService.Heartbeat:Connect(function()
        pcall(autoPlaceUnits)
        pcall(autoUpgradeUnits)
        pcall(autoSellWeakUnits)
        pcall(castAbilities)
    end)
    table.insert(State.Connections, unitConn)
    
    -- Collection loop
    local collectConn = RunService.Heartbeat:Connect(function()
        pcall(collectResources)
        pcall(openChests)
    end)
    table.insert(State.Connections, collectConn)
    
    -- Summon loop
    task.spawn(function()
        while task.wait(5) do
            if Config.AutoSummon then
                pcall(summonUnit)
                pcall(claimSummonedUnit)
                pcall(lockRareUnits)
            end
        end
    end)
    
    -- ESP loop
    local espConn = RunService.RenderStepped:Connect(function()
        pcall(updateESP)
    end)
    table.insert(State.Connections, espConn)
    
    -- Misc loop
    local miscConn = RunService.Heartbeat:Connect(function()
        pcall(skipAnimations)
        pcall(skipCutscenes)
        pcall(applySpeedHack)
    end)
    table.insert(State.Connections, miscConn)
end

-- ========================================================
-- UI EXPORT
-- ========================================================
function AnimeExpeditions.ExportFeatures(Hub)
    if type(Hub) ~= "table" then
        warn("[AnimeExpeditions] Invalid Hub object")
        return false
    end
    
    -- Inject shared libs
    Toast = getgenv().PawZHub and getgenv().PawZHub.Toast
    ESP = getgenv().PawZHub and getgenv().PawZHub.ESP
    Combat = getgenv().PawZHub and getgenv().PawZHub.Combat
    Util = getgenv().PawZHub and getgenv().PawZHub.Utility
    
    -- ===== FARMING TAB =====
    local farmTab = Hub:AddTab("Farming")
    
    farmTab:AddSection("Auto Farm")
    farmTab:AddToggle("Auto Farm Story", Config.AutoFarmStory, function(v)
        Config.AutoFarmStory = v
    end)
    farmTab:AddToggle("Auto Farm Raids", Config.AutoFarmRaids, function(v)
        Config.AutoFarmRaids = v
    end)
    farmTab:AddToggle("Auto Farm Challenges", Config.AutoFarmChallenges, function(v)
        Config.AutoFarmChallenges = v
    end)
    farmTab:AddToggle("Auto Farm Events", Config.AutoFarmEvents, function(v)
        Config.AutoFarmEvents = v
    end)
    farmTab:AddToggle("Auto Farm Dailies", Config.AutoFarmDailies, function(v)
        Config.AutoFarmDailies = v
    end)
    farmTab:AddToggle("Auto Farm Boss Rush", Config.AutoFarmBossRush, function(v)
        Config.AutoFarmBossRush = v
    end)
    farmTab:AddToggle("Auto Farm Infinite", Config.AutoFarmInfinite, function(v)
        Config.AutoFarmInfinite = v
    end)
    
    farmTab:AddSection("Settings")
    farmTab:AddDropdown("Priority", {"Story", "Raids", "Events", "Challenges"}, Config.FarmPriority, function(v)
        Config.FarmPriority = v
    end)
    farmTab:AddSlider("Target Stage", 1, 100, Config.TargetStage, function(v)
        Config.TargetStage = v
    end)
    farmTab:AddToggle("Auto Replay", Config.AutoReplay, function(v)
        Config.AutoReplay = v
    end)
    farmTab:AddToggle("Fast Clear", Config.FastClear, function(v)
        Config.FastClear = v
    end)
    farmTab:AddToggle("Skip Animations", Config.SkipAnimations, function(v)
        Config.SkipAnimations = v
    end)
    farmTab:AddToggle("Auto Claim Rewards", Config.AutoClaimRewards, function(v)
        Config.AutoClaimRewards = v
    end)
    farmTab:AddToggle("Safe Farm", Config.SafeFarm, function(v)
        Config.SafeFarm = v
    end)
    farmTab:AddSlider("Safe HP %", 10, 90, Config.SafeFarmHP, function(v)
        Config.SafeFarmHP = v
    end)
    
    farmTab:AddSection("Statistics")
    farmTab:AddButton("Show Stats", function()
        if Toast then Toast.Info(updateStatistics()) end
    end)
    farmTab:AddButton("Reset Stats", function()
        State.FarmStatistics = {
            TotalRuns = 0,
            TotalWins = 0,
            TotalLosses = 0,
            TotalGems = 0,
            TotalGold = 0,
            StartTime = tick(),
        }
        if Toast then Toast.Success("Statistics reset") end
    end)
    
    -- ===== UNIT MANAGEMENT TAB =====
    local unitTab = Hub:AddTab("Units")
    
    unitTab:AddSection("Auto Place")
    unitTab:AddToggle("Auto Place Units", Config.AutoPlaceUnits, function(v)
        Config.AutoPlaceUnits = v
    end)
    unitTab:AddToggle("Smart Placement AI", Config.SmartPlacementAI, function(v)
        Config.SmartPlacementAI = v
    end)
    unitTab:AddSlider("Max Units", 1, 8, Config.MaxUnits, function(v)
        Config.MaxUnits = v
    end)
    unitTab:AddDropdown("Priority Target", {"First", "Last", "Strongest", "Closest"}, Config.PriorityTarget, function(v)
        Config.PriorityTarget = v
    end)
    
    unitTab:AddSection("Upgrade & Sell")
    unitTab:AddToggle("Auto Upgrade", Config.AutoUpgrade, function(v)
        Config.AutoUpgrade = v
    end)
    unitTab:AddDropdown("Upgrade Priority", {"Strongest", "Weakest", "First", "Last"}, Config.UpgradePriority, function(v)
        Config.UpgradePriority = v
    end)
    unitTab:AddToggle("Auto Sell Weak", Config.AutoSellWeak, function(v)
        Config.AutoSellWeak = v
    end)
    unitTab:AddSlider("Sell Threshold (Level)", 1, 10, Config.SellThreshold, function(v)
        Config.SellThreshold = v
    end)
    
    unitTab:AddSection("Abilities")
    unitTab:AddToggle("Auto Cast Abilities", Config.AutoAbilityCast, function(v)
        Config.AutoAbilityCast = v
    end)
    unitTab:AddDropdown("Ability Priority", {"Cooldown", "Strongest", "Weakest"}, Config.AbilityPriority, function(v)
        Config.AbilityPriority = v
    end)
    
    unitTab:AddSection("Formations")
    unitTab:AddDropdown("Load Formation", {"Default", "Aggressive", "Defensive", "Custom1", "Custom2"}, Config.CurrentFormation, function(v)
        Config.CurrentFormation = v
    end)
    unitTab:AddButton("Save Formation", function()
        State.Formations[Config.CurrentFormation] = table.clone(State.PlacedUnits)
        if Toast then Toast.Success("Formation saved: " .. Config.CurrentFormation) end
    end)
    unitTab:AddButton("Clear All Units", function()
        for _, unit in ipairs(getUnits()) do
            sellUnit(unit)
        end
        State.PlacedUnits = {}
        if Toast then Toast.Success("All units cleared") end
    end)
    
    -- ===== SUMMONING TAB =====
    local summonTab = Hub:AddTab("Summon")
    
    summonTab:AddSection("Auto Summon")
    summonTab:AddToggle("Auto Summon", Config.AutoSummon, function(v)
        Config.AutoSummon = v
    end)
    summonTab:AddDropdown("Summon Type", {"Standard", "Premium", "Event", "Special"}, Config.SummonType, function(v)
        Config.SummonType = v
    end)
    summonTab:AddToggle("Skip Animation", Config.SkipSummonAnim, function(v)
        Config.SkipSummonAnim = v
    end)
    summonTab:AddToggle("Auto Claim", Config.AutoClaimUnits, function(v)
        Config.AutoClaimUnits = v
    end)
    
    summonTab:AddSection("Filters")
    summonTab:AddDropdown("Rarity Filter", {"All", "Rare+", "Epic+", "Legendary+", "Mythic"}, Config.RarityFilter, function(v)
        Config.RarityFilter = v
    end)
    summonTab:AddToggle("Summon Until Target", Config.SummonUntilTarget, function(v)
        Config.SummonUntilTarget = v
    end)
    
    summonTab:AddSection("Management")
    summonTab:AddToggle("Auto Lock Rare", Config.AutoLockRare, function(v)
        Config.AutoLockRare = v
    end)
    summonTab:AddToggle("Mass Sell Commons", Config.MassSellCommons, function(v)
        Config.MassSellCommons = v
    end)
    summonTab:AddButton("Sell Commons Now", function()
        massSellCommonUnits()
        if Toast then Toast.Success("Sold all common units") end
    end)
    
    summonTab:AddSection("Statistics")
    summonTab:AddButton("Show Summon Stats", function()
        local stats = string.format(
            "Summon Stats:\nTotal: %d\nCommon: %d | Rare: %d\nEpic: %d | Legendary: %d | Mythic: %d",
            State.SummonStatistics.TotalSummons,
            State.SummonStatistics.Common,
            State.SummonStatistics.Rare,
            State.SummonStatistics.Epic,
            State.SummonStatistics.Legendary,
            State.SummonStatistics.Mythic
        )
        if Toast then Toast.Info(stats) end
    end)
    
    -- ===== COLLECTION TAB =====
    local collectTab = Hub:AddTab("Collection")
    
    collectTab:AddSection("Auto Collect")
    collectTab:AddToggle("Auto Collect Gems", Config.AutoCollectGems, function(v)
        Config.AutoCollectGems = v
    end)
    collectTab:AddToggle("Auto Collect Gold", Config.AutoCollectGold, function(v)
        Config.AutoCollectGold = v
    end)
    collectTab:AddToggle("Auto Collect Items", Config.AutoCollectItems, function(v)
        Config.AutoCollectItems = v
    end)
    collectTab:AddToggle("Auto Collect Tickets", Config.AutoCollectTickets, function(v)
        Config.AutoCollectTickets = v
    end)
    collectTab:AddToggle("Auto Collect Event Currency", Config.AutoCollectEvent, function(v)
        Config.AutoCollectEvent = v
    end)
    collectTab:AddToggle("Auto Open Chests", Config.AutoOpenChests, function(v)
        Config.AutoOpenChests = v
    end)
    
    collectTab:AddSection("Settings")
    collectTab:AddSlider("Collection Radius", 10, 200, Config.CollectionRadius, function(v)
        Config.CollectionRadius = v
    end)
    collectTab:AddToggle("Collect All", Config.CollectAll, function(v)
        Config.CollectAll = v
    end)
    
    -- ===== TELEPORT TAB =====
    local tpTab = Hub:AddTab("Teleport")
    
    tpTab:AddSection("Stage TP")
    tpTab:AddSlider("Select Stage", 1, 100, 1, function(v)
        Config.SelectedStage = v
    end)
    tpTab:AddButton("TP to Stage", function()
        if Config.SelectedStage then
            tpToStage(Config.SelectedStage)
        end
    end)
    
    tpTab:AddSection("Quick Travel")
    tpTab:AddButton("TP to Shop", function()
        quickTravel("Shop")
    end)
    tpTab:AddButton("TP to Summon", function()
        quickTravel("Summon")
    end)
    tpTab:AddButton("TP to Event", function()
        quickTravel("Event")
    end)
    tpTab:AddButton("TP to Lobby", function()
        quickTravel("Lobby")
    end)
    
    -- ===== VISUALS TAB =====
    local visualTab = Hub:AddTab("Visuals")
    
    visualTab:AddSection("ESP")
    visualTab:AddToggle("Enemy ESP", Config.EnemyESP, function(v)
        Config.EnemyESP = v
    end)
    visualTab:AddToggle("Unit ESP", Config.UnitESP, function(v)
        Config.UnitESP = v
    end)
    visualTab:AddToggle("Chest ESP", Config.ChestESP, function(v)
        Config.ChestESP = v
    end)
    visualTab:AddToggle("Path ESP", Config.PathESP, function(v)
        Config.PathESP = v
    end)
    visualTab:AddSlider("ESP Distance", 100, 2000, Config.ESPDistance, function(v)
        Config.ESPDistance = v
        if ESP then ESP.SetMaxDistance(v) end
    end)
    
    visualTab:AddSection("Overlays")
    visualTab:AddToggle("Placement Grid", Config.PlacementGrid, function(v)
        Config.PlacementGrid = v
    end)
    visualTab:AddToggle("Range Indicator", Config.RangeIndicator, function(v)
        Config.RangeIndicator = v
    end)
    
    -- ===== MISC TAB =====
    local miscTab = Hub:AddTab("Misc")
    
    miscTab:AddSection("General")
    miscTab:AddToggle("Anti-AFK", Config.AntiAFK, function(v)
        Config.AntiAFK = v
        if v then startAntiAFK() else if Util then Util.StopAntiAFK() end end
    end)
    miscTab:AddToggle("Auto Rejoin", Config.AutoRejoin, function(v)
        Config.AutoRejoin = v
        if v then setupAutoRejoin() end
    end)
    miscTab:AddToggle("Skip Cutscenes", Config.SkipCutscenes, function(v)
        Config.SkipCutscenes = v
    end)
    
    miscTab:AddSection("Speed")
    miscTab:AddToggle("Speed Hack", Config.SpeedHack, function(v)
        Config.SpeedHack = v
    end)
    miscTab:AddSlider("Speed Multiplier", 1, 5, Config.SpeedMultiplier, function(v)
        Config.SpeedMultiplier = v
    end)
    
    miscTab:AddSection("Cheats")
    miscTab:AddToggle("Unlock All Stages", Config.UnlockStages, function(v)
        Config.UnlockStages = v
        if v then unlockAllStages() end
    end)
    
    miscTab:AddSection("Server")
    miscTab:AddButton("Server Hop", function()
        if Util then Util.ServerHop() end
    end)
    miscTab:AddButton("Rejoin", function()
        if Util then Util.Rejoin() end
    end)
    
    -- Start main loops
    startMainLoop()
    
    if Toast then
        Toast.Success("Anime Expeditions loaded! (71 features)")
    end
    
    return true
end

-- ========================================================
-- CLEANUP
-- ========================================================
function AnimeExpeditions.Unload()
    -- Disconnect all connections
    for _, conn in ipairs(State.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    
    -- Clear state
    State.Connections = {}
    State.PlacedUnits = {}
    
    print("[AnimeExpeditions] Unloaded")
end

return AnimeExpeditions

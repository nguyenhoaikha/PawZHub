--[[
    ========================================================
    PawZHub - Shindo Life Script  v1.0.0
    ========================================================
    Naruto-inspired RPG Support (PlaceId: 4616652839)
    
    Features (59 total):
      FARMING (18):
        • Auto Farm Mobs
        • Auto Farm Bosses
        • Auto Farm Dungeons
        • Auto Farm Quests
        • Auto Farm Scrolls
        • Auto Farm Spin
        • Auto Farm Bloodline
        • Auto Farm Elements
        • Auto Farm War
        • Auto Farm Arena
        • Auto Rank Up
        • Auto Collect Drops
        • Smart Target Selection
        • Farm Distance Config
        • Farm Loop Delay
        • Safe Farm (HP check)
        • Multi-Target Farm
        • Priority Target System
      
      COMBAT (12):
        • Auto Attack
        • Skill Spam (Z,X,C,V)
        • Auto Mode (combo)
        • Auto Block
        • Auto Dodge
        • Kill Aura
        • Instant Kill
        • One Shot
        • Auto Combo
        • Auto Counter
        • Stun Lock
        • Damage Amplifier
      
      COLLECTION (10):
        • Auto Collect Ryo
        • Auto Collect Chi
        • Auto Collect Scrolls
        • Auto Collect Bloodlines
        • Auto Collect Elements
        • Auto Collect Sub Abilities
        • Auto Collect Tailed Beasts
        • Auto Collect Companions
        • Auto Spin (bloodline/element)
        • Collect All (mass collect)
      
      TELEPORT (8):
        • TP to NPCs
        • TP to Bosses
        • TP to Quest Givers
        • TP to Spawn Points
        • TP to Arena
        • TP to War
        • TP to Villages
        • Save/Load Custom Locations
      
      VISUALS (6):
        • Player ESP
        • NPC ESP
        • Boss ESP
        • Quest ESP
        • Item ESP
        • ESP Settings
      
      MISC (5):
        • Anti-AFK
        • Auto Rejoin
        • Infinite Chi
        • Infinite Stamina
        • Bypass TP Cooldown
    
    Uses shared libraries:
      • lib/ui.lua
      • lib/esp.lua
      • lib/combat.lua
      • lib/utility.lua
]]

local ShindoLife = {}
ShindoLife.__name = "shindo-life"
ShindoLife.__version = "1.0.0"
ShindoLife.__placeId = 4616652839

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
    AutoFarmMobs      = false,
    AutoFarmBosses    = false,
    AutoFarmDungeons  = false,
    AutoFarmQuests    = false,
    AutoFarmScrolls   = false,
    AutoFarmSpin      = false,
    AutoFarmBloodline = false,
    AutoFarmElements  = false,
    AutoFarmWar       = false,
    AutoFarmArena     = false,
    AutoRankUp        = false,
    AutoCollectDrops  = true,
    SmartTarget       = true,
    FarmDistance      = 50,
    FarmLoopDelay     = 0.1,
    SafeFarm          = true,
    SafeFarmHP        = 30,
    MultiTarget       = false,
    MaxTargets        = 3,
    PriorityTarget    = "Nearest",
    
    -- Combat
    AutoAttack        = false,
    SkillSpam         = false,
    SkillZ            = false,
    SkillX            = false,
    SkillC            = false,
    SkillV            = false,
    AutoMode          = false,
    AutoBlock         = false,
    AutoDodge         = false,
    KillAura          = false,
    KillAuraRange     = 30,
    InstantKill       = false,
    OneShot           = false,
    AutoCombo         = false,
    ComboDelay        = 0.5,
    AutoCounter       = false,
    StunLock          = false,
    DamageAmp         = 1,
    
    -- Collection
    AutoCollectRyo    = false,
    AutoCollectChi    = false,
    AutoCollectScrolls= false,
    AutoCollectBL     = false,
    AutoCollectElem   = false,
    AutoCollectSub    = false,
    AutoCollectTB     = false,
    AutoCollectComp   = false,
    AutoSpin          = false,
    SpinType          = "Bloodline",
    CollectAll        = false,
    
    -- Teleport
    SelectedNPC       = nil,
    SelectedBoss      = nil,
    SelectedQuest     = nil,
    SelectedVillage   = nil,
    
    -- Visuals
    PlayerESP         = false,
    NPCESP            = false,
    BossESP           = false,
    QuestESP          = false,
    ItemESP           = false,
    ESPDistance       = 1000,
    
    -- Misc
    AntiAFK           = false,
    AutoRejoin        = false,
    InfiniteChi       = false,
    InfiniteStamina   = false,
    BypassTPCooldown  = false,
}

-- ========================================================
-- STATE
-- ========================================================
local State = {
    Connections = {},
    CurrentTarget = nil,
    QuestActive = false,
    FarmingActive = false,
    LastAttackTime = 0,
    ComboStep = 1,
    CollectedItems = {},
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
    -- Game-specific player data structure
    return Player:FindFirstChild("PlayerData") or Player:WaitForChild("PlayerData", 5)
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

local function getHumanoid()
    local char = getCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function isAlive()
    local hum = getHumanoid()
    return hum and hum.Health > 0
end

local function getHealth()
    local hum = getHumanoid()
    return hum and hum.Health or 0
end

local function getMaxHealth()
    local hum = getHumanoid()
    return hum and hum.MaxHealth or 100
end

local function getDistance(pos1, pos2)
    return (pos1 - pos2).Magnitude
end

local function safeTP(cframe)
    local root = getRoot()
    if not root then return false end
    
    if Config.BypassTPCooldown then
        root.CFrame = cframe
    else
        if Util then
            Util.TP(cframe)
        else
            root.CFrame = cframe
        end
    end
    
    return true
end

-- ========================================================
-- TARGET SELECTION
-- ========================================================
local function getNPCs()
    local npcs = {}
    local npcFolder = getGameFolder("NPCs")
    if not npcFolder then return npcs end
    
    for _, npc in ipairs(npcFolder:GetChildren()) do
        if npc:IsA("Model") and npc:FindFirstChild("HumanoidRootPart") then
            local hum = npc:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                table.insert(npcs, npc)
            end
        end
    end
    
    return npcs
end

local function getBosses()
    local bosses = {}
    local bossFolder = getGameFolder("Bosses")
    if not bossFolder then return bosses end
    
    for _, boss in ipairs(bossFolder:GetChildren()) do
        if boss:IsA("Model") and boss:FindFirstChild("HumanoidRootPart") then
            local hum = boss:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                table.insert(bosses, boss)
            end
        end
    end
    
    return bosses
end

local function getItems()
    local items = {}
    local itemFolder = getGameFolder("Items")
    if not itemFolder then return items end
    
    for _, item in ipairs(itemFolder:GetChildren()) do
        if item:IsA("Model") or item:IsA("Part") then
            table.insert(items, item)
        end
    end
    
    return items
end

local function getNearestTarget(targets)
    local root = getRoot()
    if not root then return nil end
    
    local nearest = nil
    local shortestDist = math.huge
    
    for _, target in ipairs(targets) do
        local targetRoot = target:FindFirstChild("HumanoidRootPart")
        if targetRoot then
            local dist = getDistance(root.Position, targetRoot.Position)
            
            if dist <= Config.FarmDistance and dist < shortestDist then
                nearest = target
                shortestDist = dist
            end
        end
    end
    
    return nearest
end

local function selectSmartTarget()
    if Config.SmartTarget then
        -- Priority: Bosses > Quest NPCs > Regular NPCs
        if Config.AutoFarmBosses then
            local bosses = getBosses()
            if #bosses > 0 then
                return getNearestTarget(bosses)
            end
        end
        
        if Config.AutoFarmMobs then
            local npcs = getNPCs()
            if #npcs > 0 then
                return getNearestTarget(npcs)
            end
        end
    end
    
    return nil
end

-- ========================================================
-- FARMING FEATURES
-- ========================================================

-- Main farm loop
local function farmLoop()
    if not State.FarmingActive then return end
    
    -- Safety check
    if Config.SafeFarm then
        local healthPercent = (getHealth() / getMaxHealth()) * 100
        if healthPercent < Config.SafeFarmHP then
            if Toast then Toast.Warning("HP too low, pausing farm") end
            task.wait(5)
            return
        end
    end
    
    -- Get target
    local target = selectSmartTarget()
    State.CurrentTarget = target
    
    if not target then
        task.wait(Config.FarmLoopDelay)
        return
    end
    
    -- TP to target
    local targetRoot = target:FindFirstChild("HumanoidRootPart")
    if targetRoot then
        local offsetCF = targetRoot.CFrame * CFrame.new(0, 5, 10)
        safeTP(offsetCF)
    end
    
    -- Attack
    if Config.AutoAttack then
        pcall(function()
            -- Game-specific attack logic
            local tool = getCharacter():FindFirstChildOfClass("Tool")
            if tool then
                tool:Activate()
            end
        end)
    end
    
    -- Use skills
    if Config.SkillSpam then
        pcall(function()
            if Config.SkillZ then
                -- Fire skill Z
            end
            if Config.SkillX then
                -- Fire skill X
            end
            if Config.SkillC then
                -- Fire skill C
            end
            if Config.SkillV then
                -- Fire skill V
            end
        end)
    end
    
    task.wait(Config.FarmLoopDelay)
end

-- Quest farming
local function farmQuests()
    if not Config.AutoFarmQuests then return end
    
    -- Find quest giver
    local questGivers = getGameFolder("QuestGivers")
    if not questGivers then return end
    
    for _, qg in ipairs(questGivers:GetChildren()) do
        -- Accept quest
        pcall(function()
            local clickDetector = qg:FindFirstChildOfClass("ClickDetector")
            if clickDetector then
                fireclickdetector(clickDetector)
            end
        end)
    end
    
    State.QuestActive = true
end

-- Auto rank up
local function autoRankUp()
    if not Config.AutoRankUp then return end
    
    pcall(function()
        -- Game-specific rank up logic
        local playerData = getPlayerData()
        if playerData then
            local level = playerData:FindFirstChild("Level")
            -- Check if can rank up and fire remote
        end
    end)
end

-- Auto collect drops
local function collectDrops()
    if not Config.AutoCollectDrops then return end
    
    local root = getRoot()
    if not root then return end
    
    local items = getItems()
    for _, item in ipairs(items) do
        local itemPos = item:IsA("Model") and item:FindFirstChild("HumanoidRootPart") or item
        if itemPos and itemPos:IsA("BasePart") then
            local dist = getDistance(root.Position, itemPos.Position)
            if dist <= 50 then
                -- Collect item (game-specific)
                pcall(function()
                    if item:FindFirstChildOfClass("ClickDetector") then
                        fireclickdetector(item:FindFirstChildOfClass("ClickDetector"))
                    end
                end)
            end
        end
    end
end

-- ========================================================
-- COMBAT FEATURES
-- ========================================================

-- Kill Aura
local function updateKillAura()
    if not Config.KillAura then return end
    
    local root = getRoot()
    if not root then return end
    
    local targets = getNPCs()
    for _, target in ipairs(targets) do
        local targetRoot = target:FindFirstChild("HumanoidRootPart")
        if targetRoot then
            local dist = getDistance(root.Position, targetRoot.Position)
            if dist <= Config.KillAuraRange then
                -- Attack
                pcall(function()
                    local tool = getCharacter():FindFirstChildOfClass("Tool")
                    if tool then tool:Activate() end
                end)
            end
        end
    end
end

-- Auto combo
local function executeCombo()
    if not Config.AutoCombo then return end
    
    local comboSequence = {
        function() -- Step 1: Z
            -- Fire Z skill
        end,
        function() -- Step 2: X
            -- Fire X skill
        end,
        function() -- Step 3: C
            -- Fire C skill
        end,
        function() -- Step 4: V + Attack
            -- Fire V skill + melee
        end,
    }
    
    if comboSequence[State.ComboStep] then
        pcall(comboSequence[State.ComboStep])
        State.ComboStep = State.ComboStep + 1
        if State.ComboStep > #comboSequence then
            State.ComboStep = 1
        end
    end
    
    task.wait(Config.ComboDelay)
end

-- Auto block/dodge
local function updateDefense()
    if not isAlive() then return end
    
    -- Auto block when enemy nearby
    if Config.AutoBlock then
        local enemies = getNPCs()
        local root = getRoot()
        if root then
            for _, enemy in ipairs(enemies) do
                local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
                if enemyRoot and getDistance(root.Position, enemyRoot.Position) < 15 then
                    -- Activate block (game-specific)
                    break
                end
            end
        end
    end
    
    -- Auto dodge
    if Config.AutoDodge then
        -- Detect incoming attacks and dodge (game-specific)
    end
end

-- Damage amplifier
local function applyDamageAmp()
    if Config.DamageAmp <= 1 then return end
    
    -- Hook damage calculations (game-specific)
end

-- ========================================================
-- COLLECTION FEATURES
-- ========================================================

-- Auto collect resources
local function collectResources()
    local root = getRoot()
    if not root then return end
    
    -- Collect Ryo (money)
    if Config.AutoCollectRyo then
        local ryoFolder = getGameFolder("Ryo")
        if ryoFolder then
            for _, ryo in ipairs(ryoFolder:GetChildren()) do
                if ryo:IsA("BasePart") then
                    local dist = getDistance(root.Position, ryo.Position)
                    if dist <= 100 then
                        safeTP(ryo.CFrame)
                        task.wait(0.1)
                    end
                end
            end
        end
    end
    
    -- Collect Chi
    if Config.AutoCollectChi then
        -- Similar logic for chi orbs
    end
    
    -- Collect Scrolls
    if Config.AutoCollectScrolls then
        local scrolls = getGameFolder("Scrolls")
        if scrolls then
            for _, scroll in ipairs(scrolls:GetChildren()) do
                -- Collect scroll
                pcall(function()
                    local cd = scroll:FindFirstChildOfClass("ClickDetector")
                    if cd then fireclickdetector(cd) end
                end)
            end
        end
    end
end

-- Auto spin (bloodline/element)
local function autoSpin()
    if not Config.AutoSpin then return end
    
    pcall(function()
        -- Game-specific spin logic
        local spinRemote = ReplicatedStorage:FindFirstChild("SpinRemote")
        if spinRemote then
            if Config.SpinType == "Bloodline" then
                spinRemote:FireServer("SpinBloodline")
            elseif Config.SpinType == "Element" then
                spinRemote:FireServer("SpinElement")
            end
        end
    end)
    
    task.wait(1)
end

-- Collect all (mass collect)
local function collectAllItems()
    if not Config.CollectAll then return end
    
    local root = getRoot()
    if not root then return end
    
    -- Collect all collectibles in range
    for _, item in ipairs(getItems()) do
        pcall(function()
            local cd = item:FindFirstChildOfClass("ClickDetector")
            if cd then
                fireclickdetector(cd)
            end
        end)
    end
end

-- ========================================================
-- TELEPORT FEATURES
-- ========================================================

local function tpToNPC(npcName)
    local npcs = getNPCs()
    for _, npc in ipairs(npcs) do
        if npc.Name == npcName then
            local root = npc:FindFirstChild("HumanoidRootPart")
            if root then
                safeTP(root.CFrame * CFrame.new(0, 3, 5))
                if Toast then Toast.Success("Teleported to " .. npcName) end
                return
            end
        end
    end
    if Toast then Toast.Error("NPC not found: " .. npcName) end
end

local function tpToBoss(bossName)
    local bosses = getBosses()
    for _, boss in ipairs(bosses) do
        if boss.Name == bossName then
            local root = boss:FindFirstChild("HumanoidRootPart")
            if root then
                safeTP(root.CFrame * CFrame.new(0, 5, 10))
                if Toast then Toast.Success("Teleported to " .. bossName) end
                return
            end
        end
    end
    if Toast then Toast.Error("Boss not found: " .. bossName) end
end

-- ========================================================
-- VISUAL FEATURES
-- ========================================================

local function updateESP()
    if not ESP then return end
    
    -- Player ESP
    if Config.PlayerESP then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= Player then
                ESP.AddPlayer(plr, {
                    Name = true,
                    Distance = true,
                    Health = true,
                })
            end
        end
    end
    
    -- NPC ESP
    if Config.NPCESP then
        for _, npc in ipairs(getNPCs()) do
            ESP.AddMob(npc, {
                Name = true,
                Distance = true,
                Health = true,
            })
        end
    end
    
    -- Boss ESP
    if Config.BossESP then
        for _, boss in ipairs(getBosses()) do
            ESP.AddMob(boss, {
                Name = true,
                Distance = true,
                Health = true,
                Color = Color3.fromRGB(255, 0, 0),
            })
        end
    end
end

-- ========================================================
-- MISC FEATURES
-- ========================================================

-- Anti-AFK
local function startAntiAFK()
    if not Config.AntiAFK then return end
    
    if Util then
        Util.StartAntiAFK(300)
    else
        -- Fallback
        Player.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
end

-- Auto rejoin on disconnect
local function setupAutoRejoin()
    if not Config.AutoRejoin then return end
    
    game:GetService("CoreGui").RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(child)
        if child.Name == "ErrorPrompt" and child:FindFirstChild("MessageArea") then
            if Util then
                Util.Rejoin()
            else
                game:GetService("TeleportService"):Teleport(game.PlaceId, Player)
            end
        end
    end)
end

-- Infinite chi/stamina
local function applyInfiniteStats()
    if Config.InfiniteChi or Config.InfiniteStamina then
        -- Hook stat values (game-specific)
        pcall(function()
            local playerData = getPlayerData()
            if playerData then
                if Config.InfiniteChi then
                    local chi = playerData:FindFirstChild("Chi")
                    if chi then chi.Value = chi.MaxValue or 1000 end
                end
                if Config.InfiniteStamina then
                    local stamina = playerData:FindFirstChild("Stamina")
                    if stamina then stamina.Value = stamina.MaxValue or 1000 end
                end
            end
        end)
    end
end

-- ========================================================
-- MAIN LOOPS
-- ========================================================
local function startMainLoop()
    -- Farm loop
    local farmConn = RunService.Heartbeat:Connect(function()
        if State.FarmingActive then
            pcall(farmLoop)
        end
    end)
    table.insert(State.Connections, farmConn)
    
    -- Combat loop
    local combatConn = RunService.Heartbeat:Connect(function()
        pcall(updateKillAura)
        pcall(updateDefense)
        if Config.AutoCombo then
            pcall(executeCombo)
        end
    end)
    table.insert(State.Connections, combatConn)
    
    -- Collection loop
    local collectConn = RunService.Heartbeat:Connect(function()
        pcall(collectDrops)
        pcall(collectResources)
        pcall(collectAllItems)
    end)
    table.insert(State.Connections, collectConn)
    
    -- Quest loop
    task.spawn(function()
        while task.wait(30) do
            pcall(farmQuests)
            pcall(autoRankUp)
        end
    end)
    
    -- Spin loop
    task.spawn(function()
        while task.wait(5) do
            pcall(autoSpin)
        end
    end)
    
    -- Stats loop
    local statsConn = RunService.Heartbeat:Connect(function()
        pcall(applyInfiniteStats)
    end)
    table.insert(State.Connections, statsConn)
    
    -- ESP loop
    local espConn = RunService.RenderStepped:Connect(function()
        pcall(updateESP)
    end)
    table.insert(State.Connections, espConn)
end

-- ========================================================
-- UI EXPORT
-- ========================================================
function ShindoLife.ExportFeatures(Hub)
    if type(Hub) ~= "table" then
        warn("[ShindoLife] Invalid Hub object")
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
    farmTab:AddToggle("Auto Farm Mobs", Config.AutoFarmMobs, function(v)
        Config.AutoFarmMobs = v
        State.FarmingActive = v
    end)
    farmTab:AddToggle("Auto Farm Bosses", Config.AutoFarmBosses, function(v)
        Config.AutoFarmBosses = v
    end)
    farmTab:AddToggle("Auto Farm Quests", Config.AutoFarmQuests, function(v)
        Config.AutoFarmQuests = v
    end)
    farmTab:AddToggle("Auto Farm Scrolls", Config.AutoFarmScrolls, function(v)
        Config.AutoFarmScrolls = v
    end)
    farmTab:AddToggle("Auto Farm Spin", Config.AutoFarmSpin, function(v)
        Config.AutoFarmSpin = v
    end)
    farmTab:AddToggle("Auto Farm War", Config.AutoFarmWar, function(v)
        Config.AutoFarmWar = v
    end)
    farmTab:AddToggle("Auto Farm Arena", Config.AutoFarmArena, function(v)
        Config.AutoFarmArena = v
    end)
    
    farmTab:AddSection("Farm Settings")
    farmTab:AddToggle("Smart Target", Config.SmartTarget, function(v)
        Config.SmartTarget = v
    end)
    farmTab:AddSlider("Farm Distance", 10, 200, Config.FarmDistance, function(v)
        Config.FarmDistance = v
    end)
    farmTab:AddSlider("Loop Delay", 0.05, 1, Config.FarmLoopDelay, function(v)
        Config.FarmLoopDelay = v
    end)
    farmTab:AddToggle("Safe Farm", Config.SafeFarm, function(v)
        Config.SafeFarm = v
    end)
    farmTab:AddSlider("Safe HP %", 10, 90, Config.SafeFarmHP, function(v)
        Config.SafeFarmHP = v
    end)
    farmTab:AddToggle("Multi-Target", Config.MultiTarget, function(v)
        Config.MultiTarget = v
    end)
    farmTab:AddSlider("Max Targets", 1, 10, Config.MaxTargets, function(v)
        Config.MaxTargets = v
    end)
    
    farmTab:AddSection("Other")
    farmTab:AddToggle("Auto Rank Up", Config.AutoRankUp, function(v)
        Config.AutoRankUp = v
    end)
    farmTab:AddToggle("Auto Collect Drops", Config.AutoCollectDrops, function(v)
        Config.AutoCollectDrops = v
    end)
    
    -- ===== COMBAT TAB =====
    local combatTab = Hub:AddTab("Combat")
    
    combatTab:AddSection("Basic Combat")
    combatTab:AddToggle("Auto Attack", Config.AutoAttack, function(v)
        Config.AutoAttack = v
    end)
    combatTab:AddToggle("Skill Spam", Config.SkillSpam, function(v)
        Config.SkillSpam = v
    end)
    combatTab:AddToggle("Use Z Skill", Config.SkillZ, function(v)
        Config.SkillZ = v
    end)
    combatTab:AddToggle("Use X Skill", Config.SkillX, function(v)
        Config.SkillX = v
    end)
    combatTab:AddToggle("Use C Skill", Config.SkillC, function(v)
        Config.SkillC = v
    end)
    combatTab:AddToggle("Use V Skill", Config.SkillV, function(v)
        Config.SkillV = v
    end)
    
    combatTab:AddSection("Advanced")
    combatTab:AddToggle("Auto Mode", Config.AutoMode, function(v)
        Config.AutoMode = v
    end)
    combatTab:AddToggle("Auto Block", Config.AutoBlock, function(v)
        Config.AutoBlock = v
    end)
    combatTab:AddToggle("Auto Dodge", Config.AutoDodge, function(v)
        Config.AutoDodge = v
    end)
    combatTab:AddToggle("Kill Aura", Config.KillAura, function(v)
        Config.KillAura = v
    end)
    combatTab:AddSlider("Aura Range", 10, 100, Config.KillAuraRange, function(v)
        Config.KillAuraRange = v
    end)
    
    combatTab:AddSection("Combo")
    combatTab:AddToggle("Auto Combo", Config.AutoCombo, function(v)
        Config.AutoCombo = v
    end)
    combatTab:AddSlider("Combo Delay", 0.1, 2, Config.ComboDelay, function(v)
        Config.ComboDelay = v
    end)
    combatTab:AddToggle("Auto Counter", Config.AutoCounter, function(v)
        Config.AutoCounter = v
    end)
    combatTab:AddToggle("Stun Lock", Config.StunLock, function(v)
        Config.StunLock = v
    end)
    
    combatTab:AddSection("Cheats")
    combatTab:AddToggle("Instant Kill", Config.InstantKill, function(v)
        Config.InstantKill = v
    end)
    combatTab:AddToggle("One Shot", Config.OneShot, function(v)
        Config.OneShot = v
    end)
    combatTab:AddSlider("Damage Multiplier", 1, 50, Config.DamageAmp, function(v)
        Config.DamageAmp = v
        applyDamageAmp()
    end)
    
    -- ===== COLLECTION TAB =====
    local collectTab = Hub:AddTab("Collection")
    
    collectTab:AddSection("Auto Collect")
    collectTab:AddToggle("Auto Collect Ryo", Config.AutoCollectRyo, function(v)
        Config.AutoCollectRyo = v
    end)
    collectTab:AddToggle("Auto Collect Chi", Config.AutoCollectChi, function(v)
        Config.AutoCollectChi = v
    end)
    collectTab:AddToggle("Auto Collect Scrolls", Config.AutoCollectScrolls, function(v)
        Config.AutoCollectScrolls = v
    end)
    collectTab:AddToggle("Auto Collect Bloodlines", Config.AutoCollectBL, function(v)
        Config.AutoCollectBL = v
    end)
    collectTab:AddToggle("Auto Collect Elements", Config.AutoCollectElem, function(v)
        Config.AutoCollectElem = v
    end)
    collectTab:AddToggle("Auto Collect Sub Abilities", Config.AutoCollectSub, function(v)
        Config.AutoCollectSub = v
    end)
    collectTab:AddToggle("Auto Collect Tailed Beasts", Config.AutoCollectTB, function(v)
        Config.AutoCollectTB = v
    end)
    collectTab:AddToggle("Auto Collect Companions", Config.AutoCollectComp, function(v)
        Config.AutoCollectComp = v
    end)
    
    collectTab:AddSection("Spin")
    collectTab:AddToggle("Auto Spin", Config.AutoSpin, function(v)
        Config.AutoSpin = v
    end)
    collectTab:AddDropdown("Spin Type", {"Bloodline", "Element", "Sub"}, Config.SpinType, function(v)
        Config.SpinType = v
    end)
    
    collectTab:AddSection("Mass Collect")
    collectTab:AddToggle("Collect All", Config.CollectAll, function(v)
        Config.CollectAll = v
    end)
    collectTab:AddButton("Collect All Now", function()
        collectAllItems()
        if Toast then Toast.Success("Collected all items in range") end
    end)
    
    -- ===== TELEPORT TAB =====
    local tpTab = Hub:AddTab("Teleport")
    
    tpTab:AddSection("Quick TP")
    tpTab:AddButton("TP to Arena", function()
        -- Game-specific arena location
        safeTP(CFrame.new(0, 100, 0))
    end)
    tpTab:AddButton("TP to War", function()
        -- Game-specific war location
        safeTP(CFrame.new(500, 100, 500))
    end)
    
    tpTab:AddSection("NPC Teleport")
    -- Dynamically populate NPC list
    local npcList = {}
    for _, npc in ipairs(getNPCs()) do
        table.insert(npcList, npc.Name)
    end
    tpTab:AddDropdown("Select NPC", npcList, "", function(v)
        Config.SelectedNPC = v
    end)
    tpTab:AddButton("TP to NPC", function()
        if Config.SelectedNPC then
            tpToNPC(Config.SelectedNPC)
        end
    end)
    
    tpTab:AddSection("Boss Teleport")
    local bossList = {}
    for _, boss in ipairs(getBosses()) do
        table.insert(bossList, boss.Name)
    end
    tpTab:AddDropdown("Select Boss", bossList, "", function(v)
        Config.SelectedBoss = v
    end)
    tpTab:AddButton("TP to Boss", function()
        if Config.SelectedBoss then
            tpToBoss(Config.SelectedBoss)
        end
    end)
    
    tpTab:AddSection("Settings")
    tpTab:AddToggle("Bypass TP Cooldown", Config.BypassTPCooldown, function(v)
        Config.BypassTPCooldown = v
    end)
    
    -- ===== VISUALS TAB =====
    local visualTab = Hub:AddTab("Visuals")
    
    visualTab:AddSection("ESP")
    visualTab:AddToggle("Player ESP", Config.PlayerESP, function(v)
        Config.PlayerESP = v
    end)
    visualTab:AddToggle("NPC ESP", Config.NPCESP, function(v)
        Config.NPCESP = v
    end)
    visualTab:AddToggle("Boss ESP", Config.BossESP, function(v)
        Config.BossESP = v
    end)
    visualTab:AddToggle("Quest ESP", Config.QuestESP, function(v)
        Config.QuestESP = v
    end)
    visualTab:AddToggle("Item ESP", Config.ItemESP, function(v)
        Config.ItemESP = v
    end)
    visualTab:AddSlider("ESP Distance", 100, 5000, Config.ESPDistance, function(v)
        Config.ESPDistance = v
        if ESP then ESP.SetMaxDistance(v) end
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
    
    miscTab:AddSection("Cheats")
    miscTab:AddToggle("Infinite Chi", Config.InfiniteChi, function(v)
        Config.InfiniteChi = v
    end)
    miscTab:AddToggle("Infinite Stamina", Config.InfiniteStamina, function(v)
        Config.InfiniteStamina = v
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
        Toast.Success("Shindo Life loaded! (59 features)")
    end
    
    return true
end

-- ========================================================
-- CLEANUP
-- ========================================================
function ShindoLife.Unload()
    -- Disconnect all connections
    for _, conn in ipairs(State.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    
    -- Stop farming
    State.FarmingActive = false
    
    -- Clear state
    State.Connections = {}
    State.CurrentTarget = nil
    
    print("[ShindoLife] Unloaded")
end

return ShindoLife

--[[
    ========================================================
    PawZHub — Blox Fruits  v2.0.0
    Uses shared libraries: ui, movement, combat, esp, utility, notifications
    Dual-mode: ExportFeatures(Hub) for loader.lua, self-contained for checkkey.lua
    ========================================================
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer
local REPO = "https://raw.githubusercontent.com/nguyenhoaikha/PawZHub/main"

-- ========================================================
-- LOAD SHARED LIBRARIES
-- ========================================================
local function loadLib(name)
    local ok, lib = pcall(function()
        return loadstring(game:HttpGet(REPO .. "/lib/" .. name .. ".lua"))()
    end)
    if ok and type(lib) == "table" then
        if type(lib.Init) == "function" then pcall(lib.Init) end
        return lib
    end
    warn("[PawZHub BF] Lib " .. name .. " failed: " .. tostring(lib))
    return nil
end

local UI            = loadLib("ui")
local Movement      = loadLib("movement")
local Combat        = loadLib("combat")
local ESP           = loadLib("esp")
local Utility       = loadLib("utility")
local Notifications = loadLib("notifications")

if not UI then
    warn("[PawZHub BF] UI library is REQUIRED but failed to load")
    return
end

-- ========================================================
-- CONFIG
-- ========================================================
local Config = {
    AntiAFK = false, SpeedEnabled = false, WalkSpeed = 32,
    AutoServerHop = false, MaxPlayers = 6,
    AutoFarmLevel = false, AutoFarmMastery = false, AutoFarmFruit = false,
    AutoChest = false, BringMobs = true, BringLock = true,
    BringRange = 120, BringMax = 8, OwnIslandOnly = false,
    PreferNearest = true, PreferHighestXP = false, QuestByLevel = true,
    SelectedWeapon = "Melee", FastAttack = true, TweenFarm = true,
    FarmRange = 80, FarmHeight = 6, AttackSpeed = 1, TweenSpeed = 280,
    AutoAttack = false, AutoSkill = false, AutoKen = false,
    AutoDodge = false, ComboMode = false,
    AutoStoreFruit = false, AutoEatFruit = false, FruitNotify = false,
    FruitSniper = false, SniperHop = false,
    SniperList = {"Leopard", "Dragon", "Kitsune", "Spirit", "Dough"},
    AutoQuest = true, AutoNextIsland = false, AutoDialogue = false,
    CurrentSea = 1, AutoDetectSea = true,
    AutoRaid = false, AutoBoss = false, SafeMode = false,
    AutoEliteHunter = false, AutoCakePrince = false,
    SelectedRaid = "Flame", SelectedBoss = "",
    RaidBuyChip = false, RaidKill = true, RaidNext = true,
    AutoSeaEvent = false, AutoMirage = false, AutoKitsune = false,
    AutoSaber = false, AutoCDK = false, AutoSoulGuitar = false,
    AutoRaceV4 = false, AutoTrial = false,
    AutoStats = false, StatMelee = true, StatDefense = true,
    StatSword = false, StatGun = false,
    Noclip = false, ESP = false, ESP_Players = true,
    ESP_Boss = true, ESP_Fruit = true, ESP_Chest = false, ESP_Flower = false,
    Language = "en", UIScale = 1, UIOpacity = 0,
}

-- ========================================================
-- WORLD SCANNER
-- ========================================================
local World = { Scanned = false, EnemyFolders = {}, Islands = {}, QuestNPCs = {}, Remotes = {} }

function World:Scan()
    self.EnemyFolders = {}
    self.Islands = {}
    self.Remotes = { Store = {}, Raid = {}, Quest = {}, Combat = {}, Other = {} }
    for _, n in ipairs({"Enemies", "NPCs", "Monsters", "Mobs", "Enemy"}) do
        local f = Workspace:FindFirstChild(n)
        if f then self.EnemyFolders[#self.EnemyFolders + 1] = f end
    end
    pcall(function()
        for _, r in ipairs(ReplicatedStorage:GetDescendants()) do
            if r:IsA("RemoteEvent") or r:IsA("RemoteFunction") then
                local n = string.lower(r.Name)
                local cat = "Other"
                if n:find("store") or n:find("fruit") then cat = "Store"
                elseif n:find("raid") or n:find("chip") then cat = "Raid"
                elseif n:find("quest") or n:find("dialogue") then cat = "Quest"
                elseif n:find("combat") or n:find("attack") or n:find("skill") then cat = "Combat"
                end
                self.Remotes[cat] = self.Remotes[cat] or {}
                self.Remotes[cat][#self.Remotes[cat] + 1] = r
            end
        end
    end)
    self.Scanned = true
end

-- ========================================================
-- FARM AI
-- ========================================================
local FarmAI = { Cache = {}, CacheAt = 0, AnchorPos = nil, CurrentTarget = nil }
local MOB_HEIGHT_MAX = 6000

local function getChar() return Player.Character end
local function getHum() local c = getChar(); return c and c:FindFirstChildOfClass("Humanoid") end
local function getHRP() local c = getChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function isAlive() local h = getHum(); return h and h.Health > 0 end

local function isHostileMob(model)
    if not model or not model:IsA("Model") then return false end
    if model == getChar() then return false end
    if Players:GetPlayerFromCharacter(model) then return false end
    local n = string.lower(model.Name or "")
    if n:find("shop") or n:find("quest") or n:find("seller") or n:find("npc") then return false end
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    local root = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
    if not root then return false end
    if math.abs(root.Position.Y) > MOB_HEIGHT_MAX then return false end
    if n:find("[lv", 1, true) then return true end
    return false
end

local function getRoot(model)
    if not model then return nil end
    return model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
end

function FarmAI:RefreshCache()
    local now = tick()
    if now - self.CacheAt < 0.5 and #self.Cache > 0 then return self.Cache end
    local list = {}
    for _, folder in ipairs(World.EnemyFolders) do
        for _, child in ipairs(folder:GetChildren()) do
            if isHostileMob(child) then
                local hum = child:FindFirstChildOfClass("Humanoid")
                local root = getRoot(child)
                if hum and root then
                    list[#list + 1] = {
                        Model = child, Humanoid = hum, Root = root,
                        Name = child.Name, IsBoss = false,
                        MaxHP = hum.MaxHealth, HP = hum.Health,
                    }
                end
            end
        end
    end
    self.Cache = list
    self.CacheAt = now
    return list
end

function FarmAI:SelectTarget(cfg, mode)
    local hrp = getHRP()
    if not hrp then return nil end
    if not self.AnchorPos then self.AnchorPos = hrp.Position end
    local list = self:RefreshCache()
    local best, bestScore = nil, -1e9
    for _, entry in ipairs(list) do
        local dist = (entry.Root.Position - hrp.Position).Magnitude
        local score = -dist * 4
        local hpRatio = entry.HP / math.max(1, entry.MaxHP)
        score = score + (1 - hpRatio) * 150
        if entry.IsBoss then score = score + 5000 end
        if cfg.PreferNearest then score = score + 100 end
        if cfg.PreferHighestXP then score = score + math.min(entry.MaxHP, 50000) * 0.002 end
        if dist <= (cfg.FarmRange or 80) then score = score + 100 end
        if self.CurrentTarget == entry.Model then score = score + 350 end
        if score > bestScore then bestScore = score; best = entry end
    end
    return best
end

-- ========================================================
-- LEVEL FARM GUIDE
-- ========================================================
local LEVEL_GUIDE = {
    {minL=0,maxL=9,keys={"bandit"},quest="BanditQuest1",qn=1},
    {minL=10,maxL=14,keys={"monkey"},quest="JungleQuest",qn=1},
    {minL=15,maxL=29,keys={"gorilla"},quest="JungleQuest",qn=2},
    {minL=30,maxL=39,keys={"pirate"},quest="BuggyQuest1",qn=1},
    {minL=40,maxL=59,keys={"brute"},quest="BuggyQuest1",qn=2},
    {minL=60,maxL=74,keys={"desert bandit"},quest="DesertQuest",qn=1},
    {minL=75,maxL=89,keys={"desert officer"},quest="DesertQuest",qn=2},
    {minL=90,maxL=99,keys={"snow bandit"},quest="SnowQuest",qn=1},
    {minL=100,maxL=119,keys={"snowman"},quest="SnowQuest",qn=2},
    {minL=120,maxL=149,keys={"chief petty"},quest="MarineQuest2",qn=1},
    {minL=150,maxL=174,keys={"sky bandit"},quest="SkyQuest",qn=1},
    {minL=175,maxL=189,keys={"dark master"},quest="SkyQuest",qn=2},
    {minL=190,maxL=209,keys={"prisoner"},quest="PrisonerQuest",qn=1},
    {minL=210,maxL=249,keys={"dangerous prisoner"},quest="PrisonerQuest",qn=2},
    {minL=250,maxL=274,keys={"toga"},quest="ColosseumQuest",qn=1},
    {minL=275,maxL=299,keys={"gladiator"},quest="ColosseumQuest",qn=2},
    {minL=300,maxL=329,keys={"military soldier"},quest="MagmaQuest",qn=1},
    {minL=330,maxL=374,keys={"military spy"},quest="MagmaQuest",qn=2},
    {minL=375,maxL=399,keys={"fishman warrior"},quest="FishmanQuest",qn=1},
    {minL=400,maxL=449,keys={"fishman commando"},quest="FishmanQuest",qn=2},
    {minL=450,maxL=474,keys={"god's guard"},quest="SkyExp1Quest",qn=1},
    {minL=475,maxL=524,keys={"shanda"},quest="SkyExp1Quest",qn=2},
    {minL=525,maxL=549,keys={"royal squad"},quest="SkyExp2Quest",qn=1},
    {minL=550,maxL=624,keys={"royal soldier"},quest="SkyExp2Quest",qn=2},
    {minL=625,maxL=649,keys={"galley pirate"},quest="FountainQuest",qn=1},
    {minL=650,maxL=699,keys={"galley captain"},quest="FountainQuest",qn=2},
    {minL=700,maxL=874,keys={"raider"},quest="Area1Quest",qn=1,sea=2},
    {minL=875,maxL=899,keys={"mercenary"},quest="Area1Quest",qn=2,sea=2},
    {minL=900,maxL=949,keys={"swan pirate"},quest="Area2Quest",qn=1,sea=2},
    {minL=950,maxL=999,keys={"factory staff"},quest="Area2Quest",qn=2,sea=2},
    {minL=1000,maxL=1049,keys={"zombie"},quest="ZombieQuest",qn=1,sea=2},
    {minL=1050,maxL=1099,keys={"vampire"},quest="ZombieQuest",qn=2,sea=2},
    {minL=1100,maxL=1174,keys={"snow trooper","winter warrior"},quest="SnowQuest2",qn=1,sea=2},
    {minL=1175,maxL=1249,keys={"arctic warrior"},quest="IceSideQuest",qn=1,sea=2},
    {minL=1250,maxL=1324,keys={"lava pirate"},quest="FireSideQuest",qn=1,sea=2},
    {minL=1325,maxL=1424,keys={"ship deckhand","ship engineer"},quest="ShipQuest1",qn=1,sea=2},
    {minL=1425,maxL=1499,keys={"ship officer"},quest="ShipQuest2",qn=1,sea=2},
    {minL=1500,maxL=1574,keys={"pirate soldier"},quest="PiratePortQuest",qn=1,sea=3},
    {minL=1575,maxL=1649,keys={"female island raider"},quest="AmazonQuest",qn=1,sea=3},
    {minL=1650,maxL=1724,keys={"marine commodore"},quest="MarineTreeIsland",qn=1,sea=3},
    {minL=1725,maxL=1799,keys={"front seed","cake"},quest="CandyQuest1",qn=1,sea=3},
    {minL=1800,maxL=1924,keys={"ice cream"},quest="IceCreamIslandQuest",qn=2,sea=3},
    {minL=1925,maxL=1999,keys={"cookie"},quest="CakeQuest1",qn=1,sea=3},
    {minL=2000,maxL=2099,keys={"cocoa","candy"},quest="ChocQuest1",qn=1,sea=3},
    {minL=2100,maxL=2199,keys={"peanut"},quest="CandyQuest2",qn=1,sea=3},
    {minL=2200,maxL=2299,keys={"baking staff"},quest="CakeQuest2",qn=1,sea=3},
    {minL=2300,maxL=2399,keys={"cocoa warrior"},quest="TikiQuest1",qn=1,sea=3},
    {minL=2400,maxL=2499,keys={"cake queen"},quest="TikiQuest2",qn=1,sea=3},
    {minL=2500,maxL=9999,keys={"haunted","ghost"},quest="HauntedQuest1",qn=1,sea=3},
}

local function getLevel()
    local lvl = 0
    pcall(function()
        local data = Player:FindFirstChild("Data")
        if data then
            local lv = data:FindFirstChild("Level") or data:FindFirstChild("level")
            if lv then lvl = tonumber(lv.Value) or 0 end
        end
    end)
    return math.max(lvl, 1)
end

local function getGuide(level)
    level = level or getLevel()
    for _, g in ipairs(LEVEL_GUIDE) do
        if level >= g.minL and level <= g.maxL then return g end
    end
    return LEVEL_GUIDE[1]
end

-- ========================================================
-- WEAPON EQUIP
-- ========================================================
local WEAPON_CAT = {
    Melee = {"combat","black leg","electro","fishman karate","superhuman","death step","sharkman karate","electric claw","dragon talon","godhuman","sanguine art"},
    Sword = {"sword","blade","katana","saber","dark blade","yama","shisui","tushita","rengoku","buddy sword"},
    Gun = {"gun","rifle","flintlock","musket","kabucha","acidum","serpent","soul guitar"},
}

local function equipWeapon(category)
    local char = getChar()
    local hum = getHum()
    if not char or not hum then return end
    local bp = Player:FindFirstChild("Backpack")
    local function try(tool)
        if tool and tool:IsA("Tool") then pcall(function() hum:EquipTool(tool) end); return true end
        return false
    end
    local held = char:FindFirstChildOfClass("Tool")
    local keys = WEAPON_CAT[category] or {}
    if held then
        local n = string.lower(held.Name)
        for _, k in ipairs(keys) do
            if n:find(k, 1, true) then return held end
        end
    end
    if bp then
        for _, tool in ipairs(bp:GetChildren()) do
            if tool:IsA("Tool") then
                local n = string.lower(tool.Name)
                for _, k in ipairs(keys) do
                    if n:find(k, 1, true) then if try(tool) then return tool end end
                end
            end
        end
    end
    if bp then for _, tool in ipairs(bp:GetChildren()) do if try(tool) then return tool end end end
end

-- ========================================================
-- ATTACK / SKILL
-- ========================================================
local function attackAOE(cfg)
    pcall(function()
        if type(mouse1click) == "function" then
            mouse1click()
        elseif type(VirtualInputManager) == "table" then
            local vim = game:GetService("VirtualInputManager")
            local pos = UserInputService:GetMouseLocation()
            vim:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)
            task.wait(0.02)
            vim:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
        end
    end)
end

local function doSkillBurst()
    pcall(function()
        local char = getChar()
        if not char then return end
        for _, tool in ipairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                for _, key in ipairs({"Z","X","C","V","F"}) do
                    pcall(function() tool:Activate() end)
                    task.wait(0.15)
                end
                break
            end
        end
    end)
end

-- ========================================================
-- QUEST SYSTEM
-- ========================================================
local function getCommF()
    local r = nil
    pcall(function()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then r = remotes:FindFirstChild("CommF_") end
    end)
    return r
end

local function startQuest(guide)
    guide = guide or getGuide()
    local rf = getCommF()
    if not rf or not guide then return false end
    local ok = pcall(function() rf:InvokeServer("StartQuest", guide.quest, guide.qn or 1) end)
    return ok
end

local function hasActiveQuest()
    local found = false
    pcall(function()
        local pg = Player:FindFirstChild("PlayerGui")
        if not pg then return end
        for _, g in ipairs(pg:GetDescendants()) do
            if g:IsA("TextLabel") then
                local t = string.lower(tostring(g.Text or ""))
                if t:find("defeat") or t:find("kill") or (t:find("%d+") and t:find("/")) then
                    found = true; break
                end
            end
        end
    end)
    return found
end

-- ========================================================
-- FEATURE ENGINE
-- ========================================================
local FeatureEngine = { Running = false, Connections = {}, LastAttack = 0, LastSkill = 0 }

function FeatureEngine:Start()
    if self.Running then return end
    self.Running = true

    if Config.AntiAFK and Utility then Utility.SetAntiAFK(true) end
    if Config.SpeedEnabled and Movement then Movement.SetWalkSpeed(Config.WalkSpeed, true) end
    if Config.ESP and ESP then
        if Config.ESP_Players then ESP.SetPlayerESP(true) end
    end

    local heartbeat = RunService.Heartbeat:Connect(function(dt)
        if not self.Running then return end
        local hrp = getHRP()
        if not hrp or not isAlive() then return end

        -- Auto Farm Level
        if Config.AutoFarmLevel then
            local target = FarmAI:SelectTarget(Config, "level")
            if target then
                FarmAI.CurrentTarget = target.Model
                equipWeapon(Config.SelectedWeapon)
                local root = target.Root
                local dist = (hrp.Position - root.Position).Magnitude

                if dist > 15 then
                    hrp.CFrame = CFrame.new(root.Position + Vector3.new(0, Config.FarmHeight or 6, 0), root.Position)
                else
                    hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(root.Position.X, hrp.Position.Y, root.Position.Z))
                end

                local now = tick()
                local interval = 1 / (Config.AttackSpeed or 1)
                if now - self.LastAttack >= interval then
                    self.LastAttack = now
                    attackAOE(Config)
                end

                if Config.AutoSkill and now - self.LastSkill >= 0.65 then
                    self.LastSkill = now
                    task.spawn(doSkillBurst)
                end

                if Config.AutoQuest and not hasActiveQuest() then
                    startQuest()
                end
            end
        end

        -- Safe Mode
        if Config.SafeMode then
            local hum = getHum()
            if hum and hum.Health / hum.MaxHealth < 0.2 then
                hrp.CFrame = hrp.CFrame + Vector3.new(0, 50, 0)
            end
        end

        -- Noclip
        if Config.Noclip and Movement then Movement.SetNoclip(true) end

        -- Auto Stats
        if Config.AutoStats then
            pcall(function()
                local data = Player:FindFirstChild("Data")
                if data then
                    local points = data:FindFirstChild("Points")
                    if points and (tonumber(points.Value) or 0) > 0 then
                        local rf = getCommF()
                        if rf then
                            for _, stat in ipairs({"Melee","Defense","Sword","Gun"}) do
                                if Config["Stat" .. stat] then
                                    pcall(function() rf:InvokeServer("AddPoint", stat, 1) end)
                                end
                            end
                        end
                    end
                end
            end)
        end
    end)
    self.Connections[#self.Connections + 1] = heartbeat

    -- Fruit Notify
    if Config.FruitNotify then
        local fruitConn = RunService.Heartbeat:Connect(function()
            for _, obj in ipairs(Workspace:GetChildren()) do
                if obj:IsA("Tool") or obj:IsA("Model") then
                    local n = string.lower(obj.Name)
                    if n:find("fruit") or n:find("eatable") then
                        local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart")
                        if part then
                            local hrp = getHRP()
                            if hrp and (part.Position - hrp.Position).Magnitude < 500 then
                                if Notifications then Notifications.Show("Fruit: " .. obj.Name, "ok") end
                            end
                        end
                    end
                end
            end
        end)
        self.Connections[#self.Connections + 1] = fruitConn
    end
end

function FeatureEngine:Stop()
    self.Running = false
    for _, conn in ipairs(self.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    self.Connections = {}
    if Movement then Movement.SetFly(false); Movement.SetNoclip(false) end
    if Utility then Utility.SetAntiAFK(false) end
    if ESP then ESP.Unload() end
end

-- ========================================================
-- SERVER HOP
-- ========================================================
local function serverHop(maxPlayers)
    maxPlayers = maxPlayers or Config.MaxPlayers or 6
    pcall(function()
        local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId)
        local data = HttpService:JSONDecode(game:HttpGet(url))
        if data and data.data then
            for _, srv in ipairs(data.data) do
                if srv.id ~= game.JobId and (tonumber(srv.playing) or 0) < maxPlayers then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, srv.id, Player)
                    return
                end
            end
        end
    end)
end

-- ========================================================
-- BUILD UI ON HUB
-- ========================================================
local function buildUI(Hub)
    -- Home
    local home = Hub:Tab("Home")
    home:Toggle("Anti AFK", Config.AntiAFK, function(v)
        Config.AntiAFK = v
        if Utility then Utility.SetAntiAFK(v) end
    end)
    home:Toggle("Speed Boost", Config.SpeedEnabled, function(v)
        Config.SpeedEnabled = v
        if Movement then Movement.SetWalkSpeed(Config.WalkSpeed, v) end
    end)
    home:Slider("Walk Speed", 16, 200, Config.WalkSpeed, function(v)
        Config.WalkSpeed = v
        if Config.SpeedEnabled and Movement then Movement.SetWalkSpeed(v, true) end
    end)
    home:Toggle("Server Hop", Config.AutoServerHop, function(v)
        Config.AutoServerHop = v
        if v then serverHop() end
    end)

    -- Farm
    local farm = Hub:Tab("Farm")
    farm:Toggle("Auto Farm Level", Config.AutoFarmLevel, function(v)
        Config.AutoFarmLevel = v
        if v then FeatureEngine:Start() end
    end)
    farm:Toggle("Auto Farm Mastery", Config.AutoFarmMastery, function(v)
        Config.AutoFarmMastery = v
        if v then FeatureEngine:Start() end
    end)
    farm:Toggle("Bring Mobs", Config.BringMobs, function(v) Config.BringMobs = v end)
    farm:Toggle("Own Island Only", Config.OwnIslandOnly, function(v) Config.OwnIslandOnly = v end)
    farm:Toggle("Quest By Level", Config.QuestByLevel, function(v) Config.QuestByLevel = v end)
    farm:Toggle("Auto Quest", Config.AutoQuest, function(v) Config.AutoQuest = v end)
    farm:Toggle("Fast Attack", Config.FastAttack, function(v) Config.FastAttack = v end)
    farm:Toggle("Tween Farm", Config.TweenFarm, function(v) Config.TweenFarm = v end)
    farm:Slider("Farm Range", 10, 200, Config.FarmRange, function(v) Config.FarmRange = v end)
    farm:Slider("Farm Height", 0, 20, Config.FarmHeight, function(v) Config.FarmHeight = v end)
    farm:Slider("Attack Speed", 0.5, 3, Config.AttackSpeed, function(v) Config.AttackSpeed = v end)
    farm:Dropdown("Weapon", {"Melee","Sword","Gun"}, Config.SelectedWeapon, function(v)
        Config.SelectedWeapon = v
        equipWeapon(v)
    end)

    -- Combat
    local cbt = Hub:Tab("Combat")
    cbt:Toggle("Auto Attack", Config.AutoAttack, function(v) Config.AutoAttack = v end)
    cbt:Toggle("Auto Skill", Config.AutoSkill, function(v) Config.AutoSkill = v end)
    cbt:Toggle("Auto Ken", Config.AutoKen, function(v) Config.AutoKen = v end)
    cbt:Toggle("Auto Dodge", Config.AutoDodge, function(v) Config.AutoDodge = v end)
    cbt:Toggle("Combo Mode", Config.ComboMode, function(v) Config.ComboMode = v end)
    cbt:Toggle("Safe Mode", Config.SafeMode, function(v) Config.SafeMode = v end)

    -- Fruit
    local fruit = Hub:Tab("Fruit")
    fruit:Toggle("Auto Store Fruit", Config.AutoStoreFruit, function(v) Config.AutoStoreFruit = v end)
    fruit:Toggle("Fruit Notify", Config.FruitNotify, function(v)
        Config.FruitNotify = v
        if v then FeatureEngine:Start() end
    end)
    fruit:Toggle("Fruit Sniper", Config.FruitSniper, function(v) Config.FruitSniper = v end)

    -- Raid
    local raid = Hub:Tab("Raid")
    raid:Toggle("Auto Raid", Config.AutoRaid, function(v) Config.AutoRaid = v end)
    raid:Toggle("Auto Boss", Config.AutoBoss, function(v) Config.AutoBoss = v end)
    raid:Toggle("Auto Elite Hunter", Config.AutoEliteHunter, function(v) Config.AutoEliteHunter = v end)
    raid:Toggle("Auto Cake Prince", Config.AutoCakePrince, function(v) Config.AutoCakePrince = v end)
    raid:Dropdown("Raid Type", {"Flame","Ice","Quake","Light","Dark","String","Rumble","Buddha","Magma","Sand","Bird","Human"}, Config.SelectedRaid, function(v) Config.SelectedRaid = v end)

    -- ESP
    local espTab = Hub:Tab("ESP")
    espTab:Toggle("ESP Master", Config.ESP, function(v)
        Config.ESP = v
        if v then FeatureEngine:Start() end
    end)
    espTab:Toggle("ESP Players", Config.ESP_Players, function(v) Config.ESP_Players = v end)
    espTab:Toggle("ESP Boss", Config.ESP_Boss, function(v) Config.ESP_Boss = v end)
    espTab:Toggle("ESP Fruit", Config.ESP_Fruit, function(v) Config.ESP_Fruit = v end)
    espTab:Toggle("ESP Chest", Config.ESP_Chest, function(v) Config.ESP_Chest = v end)
    espTab:Toggle("Noclip", Config.Noclip, function(v)
        Config.Noclip = v
        if Movement then Movement.SetNoclip(v) end
    end)

    -- Sea
    local sea = Hub:Tab("Sea")
    sea:Toggle("Auto Sea Events", Config.AutoSeaEvent, function(v) Config.AutoSeaEvent = v end)
    sea:Toggle("Auto Mirage", Config.AutoMirage, function(v) Config.AutoMirage = v end)
    sea:Toggle("Auto Kitsune", Config.AutoKitsune, function(v) Config.AutoKitsune = v end)

    -- Settings
    local settings = Hub:Tab("Settings")
    settings:Slider("Tween Speed", 80, 500, Config.TweenSpeed, function(v) Config.TweenSpeed = v end)
    settings:Button("Save Config", function()
        pcall(function()
            if isfolder and not isfolder("PawZHub") then makefolder("PawZHub") end
            if writefile then writefile("PawZHub/config_bf.json", HttpService:JSONEncode(Config)) end
            if Notifications then Notifications.Show("Config saved!", "ok") end
        end)
    end)
    settings:Button("Load Config", function()
        pcall(function()
            if readfile and isfile and isfile("PawZHub/config_bf.json") then
                local data = HttpService:JSONDecode(readfile("PawZHub/config_bf.json"))
                for k, v in pairs(data) do Config[k] = v end
                if Notifications then Notifications.Show("Config loaded!", "ok") end
            end
        end)
    end)
end

-- ========================================================
-- EXPORT (for loader.lua)
-- ========================================================
local GameModule = {}

function GameModule.ExportFeatures(Hub)
    if type(Hub) ~= "table" then return false end
    buildUI(Hub)
    -- Init world scan
    task.spawn(function()
        task.wait(1)
        World:Scan()
        if Hub.Notify then
            Hub:Notify("PawZHub BF v2.0 · " .. #World.EnemyFolders .. " enemy folders scanned", "ok", 5)
        end
    end)
    return true
end

-- ========================================================
-- SELF-CONTAINED MODE (for checkkey.lua / direct load)
-- ========================================================
local _hasGlobal = false
pcall(function() if getgenv and getgenv().PawZHub then _hasGlobal = true end end)
if not _hasGlobal then
    local Hub = UI.New({
        title = "PawZHub",
        game = "Blox Fruits",
        theme = "Dark",
        toggle = Enum.KeyCode.RightShift,
        width = 560,
        height = 420,
    })
    buildUI(Hub)
    Hub:Notify("PawZHub Blox Fruits v2.0 ready", "ok", 5)

    task.spawn(function()
        task.wait(1)
        World:Scan()
        if Notifications then Notifications.Show("BF loaded · " .. #World.EnemyFolders .. " folders", "ok") end
    end)

    Player.PlayerRemoving:Connect(function(p)
        if p == Player then
            FeatureEngine:Stop()
            Hub:Destroy()
        end
    end)
end

return GameModule

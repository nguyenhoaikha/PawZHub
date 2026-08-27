--[[
    ========================================================
    PawZHub — Greedy Growers  v2.0.0
    Uses shared libraries: ui, movement, utility, notifications
    Dual-mode: ExportFeatures(Hub) for loader.lua, self-contained for checkkey.lua
    ========================================================
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
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
    warn("[PawZHub GG] Lib " .. name .. " failed: " .. tostring(lib))
    return nil
end

local UI            = loadLib("ui")
local Movement      = loadLib("movement")
local Utility       = loadLib("utility")
local Notifications = loadLib("notifications")

if not UI then
    warn("[PawZHub GG] UI library is REQUIRED but failed to load")
    return
end

-- ========================================================
-- CONFIG
-- ========================================================
local Config = {
    AutoBuy = false, AutoPlant = false, AutoHarvest = false,
    AutoCollect = false, AutoSell = false, AutoFertilizer = false,
    AutoRebirth = false, AutoFeedPet = false, AutoPlaceEgg = false,
    AutoEquipPet = false, AutoServerHop = false,
    AntiAFK = false, SpeedEnabled = false, WalkSpeed = 32,
    SellThreshold = 50, FertilizerDelay = 30,
    RebirthThreshold = 1000, MaxPlayers = 6,
}

-- ========================================================
-- PLOT DETECTION
-- ========================================================
local PlotInfo = { MyPlot = nil, Soil = {}, SpawnPos = nil }

function PlotInfo:Detect()
    self.Soil = {}
    self.MyPlot = nil
    local char = Player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    pcall(function()
        for _, obj in ipairs(Workspace:GetChildren()) do
            local n = string.lower(obj.Name or "")
            if n:find("plot") or n:find("farm") or n:find("garden") then
                local part = obj:IsA("BasePart") and obj or obj:FindFirstChildWhichIsA("BasePart", true)
                if part and (part.Position - hrp.Position).Magnitude < 100 then
                    self.MyPlot = obj
                    for _, child in ipairs(obj:GetDescendants()) do
                        local cn = string.lower(child.Name or "")
                        if cn:find("soil") or cn:find("plot") or cn:find("plant") or cn:find("seed") then
                            if child:IsA("BasePart") then
                                self.Soil[#self.Soil + 1] = child
                            end
                        end
                    end
                    break
                end
            end
        end
    end)
end

-- ========================================================
-- FARM CYCLE
-- ========================================================
local FarmCycle = { Active = false, LastAction = 0 }

function FarmCycle:Run(cfg)
    if not self.Active then return end
    local now = tick()
    local function fireNearest(keyword, delay)
        if now - self.LastAction < delay then return end
        self.LastAction = now
        pcall(function()
            for _, obj in ipairs(Workspace:GetDescendants()) do
                local n = string.lower(obj.Name or "")
                if n:find(keyword) then
                    local prompt = obj:FindFirstChildWhichIsA("ProximityPrompt", true)
                    if prompt then pcall(function() fireproximityprompt(prompt) end) end
                end
            end
        end)
    end
    if cfg.AutoBuy then fireNearest("seed", 2) end
    if cfg.AutoPlant then fireNearest("plant", 1) end
    if cfg.AutoHarvest then fireNearest("harvest", 1.5) end
    if cfg.AutoCollect then fireNearest("collect", 1) end
    if cfg.AutoSell then fireNearest("sell", 3) end
    if cfg.AutoFertilizer then fireNearest("fertiliz", cfg.FertilizerDelay or 30) end
    if cfg.AutoRebirth then fireNearest("rebirth", 5) end
    if cfg.AutoEquipPet then fireNearest("pet", 2) end
end

-- ========================================================
-- FEATURE ENGINE
-- ========================================================
local FeatureEngine = { Running = false, Connections = {} }

function FeatureEngine:Start()
    if self.Running then return end
    self.Running = true
    FarmCycle.Active = true
    if Config.AntiAFK and Utility then Utility.SetAntiAFK(true) end
    if Config.SpeedEnabled and Movement then Movement.SetWalkSpeed(Config.WalkSpeed, true) end
    task.spawn(function() task.wait(1); PlotInfo:Detect() end)
    local heartbeat = RunService.Heartbeat:Connect(function()
        if not self.Running then return end
        FarmCycle:Run(Config)
    end)
    self.Connections[#self.Connections + 1] = heartbeat
end

function FeatureEngine:Stop()
    self.Running = false
    FarmCycle.Active = false
    for _, conn in ipairs(self.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    self.Connections = {}
    if Utility then Utility.SetAntiAFK(false) end
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

    local farm = Hub:Tab("Farm")
    farm:Toggle("Auto Buy Seeds", Config.AutoBuy, function(v)
        Config.AutoBuy = v; if v then FeatureEngine:Start() end
    end)
    farm:Toggle("Auto Plant", Config.AutoPlant, function(v)
        Config.AutoPlant = v; if v then FeatureEngine:Start() end
    end)
    farm:Toggle("Auto Harvest", Config.AutoHarvest, function(v)
        Config.AutoHarvest = v; if v then FeatureEngine:Start() end
    end)
    farm:Toggle("Auto Collect", Config.AutoCollect, function(v)
        Config.AutoCollect = v; if v then FeatureEngine:Start() end
    end)
    farm:Toggle("Auto Sell", Config.AutoSell, function(v)
        Config.AutoSell = v; if v then FeatureEngine:Start() end
    end)
    farm:Toggle("Auto Fertilizer", Config.AutoFertilizer, function(v)
        Config.AutoFertilizer = v; if v then FeatureEngine:Start() end
    end)
    farm:Slider("Fertilizer Delay", 10, 120, Config.FertilizerDelay, function(v)
        Config.FertilizerDelay = v
    end)

    local pets = Hub:Tab("Pets")
    pets:Toggle("Auto Feed Pet", Config.AutoFeedPet, function(v)
        Config.AutoFeedPet = v; if v then FeatureEngine:Start() end
    end)
    pets:Toggle("Auto Place Egg", Config.AutoPlaceEgg, function(v)
        Config.AutoPlaceEgg = v; if v then FeatureEngine:Start() end
    end)
    pets:Toggle("Auto Equip Pet", Config.AutoEquipPet, function(v)
        Config.AutoEquipPet = v; if v then FeatureEngine:Start() end
    end)

    local rebirth = Hub:Tab("Rebirth")
    rebirth:Toggle("Auto Rebirth", Config.AutoRebirth, function(v)
        Config.AutoRebirth = v; if v then FeatureEngine:Start() end
    end)
    rebirth:Slider("Rebirth Threshold", 100, 10000, Config.RebirthThreshold, function(v)
        Config.RebirthThreshold = v
    end)

    local settings = Hub:Tab("Settings")
    settings:Toggle("Server Hop", Config.AutoServerHop, function(v)
        Config.AutoServerHop = v
        if v then serverHop() end
    end)
    settings:Slider("Max Players", 2, 20, Config.MaxPlayers, function(v)
        Config.MaxPlayers = v
    end)
    settings:Button("Save Config", function()
        pcall(function()
            if isfolder and not isfolder("PawZHub") then makefolder("PawZHub") end
            if writefile then writefile("PawZHub/config_gg.json", HttpService:JSONEncode(Config)) end
            if Notifications then Notifications.Show("Config saved!", "ok") end
        end)
    end)
    settings:Button("Load Config", function()
        pcall(function()
            if readfile and isfile and isfile("PawZHub/config_gg.json") then
                local data = HttpService:JSONDecode(readfile("PawZHub/config_gg.json"))
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
    task.spawn(function()
        task.wait(1)
        PlotInfo:Detect()
        if Hub.Notify then Hub:Notify("PawZHub GG v2.0 loaded", "ok", 5) end
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
        game = "Greedy Growers",
        theme = "Dark",
        toggle = Enum.KeyCode.RightShift,
        width = 480,
        height = 380,
    })
    buildUI(Hub)
    Hub:Notify("PawZHub Greedy Growers v2.0 ready", "ok", 5)
    task.spawn(function()
        task.wait(1)
        PlotInfo:Detect()
        if Notifications then Notifications.Show("GG loaded", "ok") end
    end)
    Player.PlayerRemoving:Connect(function(p)
        if p == Player then
            FeatureEngine:Stop()
            Hub:Destroy()
        end
    end)
end

return GameModule

--[[
    PawZHub Game Module Template  v1.0.0
    ====================================
    Drop-in skeleton for new game scripts (the 28 supported games).
    Demonstrates how to use the shared Movement library.

    Copy this file to script/games/<slug>.lua and customize:
      1. The PlaceId in checkkey.lua SUPPORTED_GAMES table
      2. The features below
      3. Any game-specific remote calls (e.g. CommF_, BuyItem)

    Public entry: ExportFeatures(UI) → returns true if registered.
]]

local GameModule = {}
GameModule.__name = "template"
GameModule.__placeId = 0  -- OVERRIDE with the game's actual PlaceId
GameModule.__version = "1.0.0"

-- ========================================================
-- DEPENDENCIES
-- ========================================================
local Players   = game:GetService("Players")
local RunService= game:GetService("RunService")
local HttpService=game:GetService("HttpService")
local Player    = Players.LocalPlayer

-- Load shared movement library
local MovementLib_URL = "https://raw.githubusercontent.com/nguyenhoaikha/PawZHub/main/lib/movement.lua"
local Movement = (function()
    local ok, M = pcall(function()
        local src = game:HttpGet(MovementLib_URL)
        return (loadstring(src))()
    end)
    if ok and type(M) == "table" then
        M.Init()
        return M
    end
    warn("[PawZHub] Movement library not loaded for template game")
    return nil
end)()

-- ========================================================
-- PER-GAME CONFIG
-- ========================================================
local Config = {
    -- Movement
    WalkSpeed     = 32,
    SpeedEnabled  = false,
    FlyEnabled    = false,
    FlyMode       = "CFrame",   -- "CFrame" | "Velocity" | "BodyVelocity"
    FlySpeed      = 80,
    Noclip        = false,
    InfiniteJump  = false,
    ClickTP       = false,
    ClickTPMax    = 500,
    NoFall        = false,
    AutoJump      = false,
    InfStamina    = false,

    -- Visuals
    ESPEnabled    = false,

    -- Combat
    KillAura      = false,
    AuraRange     = 20,
}

-- ========================================================
-- MOVEMENT WRAPPERS — auto-use library, fall back to no-op
-- ========================================================
local function setWalkSpeed(val, on)
    if Movement then
        Movement.SetWalkSpeed(val, on)
    end
end
local function setFly(on, mode, speed)
    if Movement then Movement.SetFly(on, mode, speed) end
end
local function setNoclip(on)
    if Movement then Movement.SetNoclip(on) end
end
local function setInfJump(on)
    if Movement then Movement.SetInfiniteJump(on) end
end
local function setClickTP(on, max)
    if Movement then Movement.SetClickTP(on, max) end
end
local function setNoFall(on)
    if Movement then Movement.SetNoFallDamage(on) end
end
local function setAutoJump(on)
    if Movement then Movement.SetAutoJump(on) end
end
local function setInfStamina(on)
    if Movement then Movement.SetInfiniteStamina(on) end
end
local function rejoinServer()
    if Movement then Movement.Rejoin() end
end

-- ========================================================
-- UI REGISTRATION
-- ========================================================
-- Expects `UI` to be a table with these methods (provided by the host
-- game script's UI engine — e.g. the existing BF/GG UI helpers):
--   UI:NewTab(name) -> Tab
--   Tab:AddToggle(label, default, callback) -> Toggle
--   Tab:AddSlider(label, min, max, default, callback) -> Slider
--   Tab:AddDropdown(label, options, default, callback) -> Dropdown
--   Tab:AddButton(label, callback) -> Button
--   Tab:AddSection(name) -> Section
function GameModule.ExportFeatures(UI)
    if type(UI) ~= "table" then return false end

    -- ===== Movement Tab =====
    local movTab = UI:NewTab("Movement")

    movTab:AddToggle("Speed Hack", Config.SpeedEnabled, function(on)
        Config.SpeedEnabled = on
        setWalkSpeed(Config.WalkSpeed, on)
    end)
    movTab:AddSlider("Walk Speed", 16, 200, Config.WalkSpeed, function(v)
        Config.WalkSpeed = v
        if Config.SpeedEnabled then setWalkSpeed(v, true) end
    end)

    movTab:AddToggle("Fly", Config.FlyEnabled, function(on)
        Config.FlyEnabled = on
        setFly(on, Config.FlyMode, Config.FlySpeed)
    end)
    movTab:AddDropdown("Fly Mode", { "CFrame", "Velocity", "BodyVelocity" }, Config.FlyMode, function(mode)
        Config.FlyMode = mode
        if Config.FlyEnabled then setFly(true, mode, Config.FlySpeed) end
    end)
    movTab:AddSlider("Fly Speed", 10, 300, Config.FlySpeed, function(v)
        Config.FlySpeed = v
        if Config.FlyEnabled then setFly(true, Config.FlyMode, v) end
    end)

    movTab:AddToggle("Noclip", Config.Noclip, function(on)
        Config.Noclip = on
        setNoclip(on)
    end)
    movTab:AddToggle("Infinite Jump", Config.InfiniteJump, function(on)
        Config.InfiniteJump = on
        setInfJump(on)
    end)
    movTab:AddToggle("Click Teleport", Config.ClickTP, function(on)
        Config.ClickTP = on
        setClickTP(on, Config.ClickTPMax)
    end)
    movTab:AddSlider("Click TP Max (studs)", 50, 2000, Config.ClickTPMax, function(v)
        Config.ClickTPMax = v
        if Config.ClickTP then setClickTP(true, v) end
    end)
    movTab:AddToggle("No Fall Damage", Config.NoFall, function(on)
        Config.NoFall = on
        setNoFall(on)
    end)
    movTab:AddToggle("Auto Jump", Config.AutoJump, function(on)
        Config.AutoJump = on
        setAutoJump(on)
    end)
    movTab:AddToggle("Infinite Stamina", Config.InfStamina, function(on)
        Config.InfStamina = on
        setInfStamina(on)
    end)

    movTab:AddSection("Waypoints")
    movTab:AddButton("Save Position", function()
        if Movement then
            local n = "WP-" .. tostring(#Movement.ListPos() + 1)
            Movement.SavePos(n)
        end
    end)
    movTab:AddButton("Rejoin Server", function()
        rejoinServer()
    end)

    -- ===== Combat Tab (template) =====
    local cbtTab = UI:NewTab("Combat")
    cbtTab:AddToggle("Kill Aura", Config.KillAura, function(on)
        Config.KillAura = on
        -- TODO: implement kill aura loop
    end)
    cbtTab:AddSlider("Aura Range", 5, 100, Config.AuraRange, function(v)
        Config.AuraRange = v
    end)

    -- ===== Visuals Tab (template) =====
    local visTab = UI:NewTab("Visuals")
    visTab:AddToggle("Player ESP", Config.ESPEnabled, function(on)
        Config.ESPEnabled = on
        -- TODO: implement ESP
    end)

    return true
end

-- ========================================================
-- CLEANUP
-- ========================================================
function GameModule.Unload()
    if Movement then
        Movement.Unload()
    end
end

return GameModule

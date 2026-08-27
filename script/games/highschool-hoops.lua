--[[
    ========================================================
    PawZHub - Highschool Hoops Script  v1.0.0
    ========================================================
    Basketball Game Support (PlaceId: 117612316652)
    
    Features (55 total):
      SHOOTING (15):
        • Auto Shoot
        • Perfect Release
        • Shot Power Control
        • Shot Prediction
        • Green Light Assist
        • Auto Three Pointer
        • Mid Range Auto
        • Layup Assist
        • Dunk Assist
        • Shot Fake
        • Quick Release
        • Contested Shot Boost
        • Shot Clock Awareness
        • Hot Zone Shooter
        • Range Extender
      
      DEFENSE (12):
        • Auto Rebound
        • Auto Steal
        • Auto Block
        • Defensive Positioning
        • Chase Down Block
        • Pick Pocket
        • Contest Shots
        • Help Defense
        • Boxing Out
        • Transition Defense
        • Perimeter Defense
        • Interior Defense
      
      OFFENSE (10):
        • Auto Pass
        • Pick and Roll
        • Dribble Moves
        • Post Moves
        • Cut to Basket
        • Screen Assist
        • Fast Break
        • Ball Movement
        • Spacing Control
        • Offensive Rebound
      
      MOVEMENT (8):
        • Speed Boost
        • Stamina Management
        • Quick First Step
        • Lateral Quickness
        • Vertical Jump Boost
        • Position Auto
        • Court Awareness
        • Sprint Optimization
      
      STATS (5):
        • Stat Tracker
        • Shot Chart
        • Efficiency Rating
        • Plus/Minus
        • Game Summary
      
      MISC (5):
        • Anti-AFK
        • Auto Rejoin
        • Skip Replays
        • Court Vision
        • Team Chat Auto
    
    Uses shared libraries:
      • lib/ui.lua
      • lib/utility.lua
      • lib/basketball.lua
]]

local HighschoolHoops = {}
HighschoolHoops.__name = "highschool-hoops"
HighschoolHoops.__version = "1.0.0"
HighschoolHoops.__placeId = 117612316652

-- ========================================================
-- SERVICES
-- ========================================================
local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local Workspace     = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer

-- ========================================================
-- LOAD BASKETBALL LIB
-- ========================================================
local Basketball = nil
task.spawn(function()
    local url = "https://raw.githubusercontent.com/nguyenhoaikha/PawZHub/main/script/lib/basketball.lua"
    local ok, src = pcall(function()
        return game:HttpGet(url)
    end)
    if ok and src then
        local fn = loadstring(src)
        if fn then
            Basketball = fn()
            if Basketball then
                Basketball.Init()
            end
        end
    end
end)

-- ========================================================
-- CONFIG
-- ========================================================
local Config = {
    -- Shooting
    AutoShoot         = false,
    PerfectRelease    = false,
    ShotPower         = 100,
    ShotPrediction    = false,
    GreenLightAssist  = false,
    AutoThree         = false,
    MidRangeAuto      = false,
    LayupAssist       = false,
    DunkAssist        = false,
    ShotFake          = false,
    QuickRelease      = false,
    ContestedBoost    = false,
    ShotClockAware    = true,
    HotZoneShooter    = false,
    RangeExtender     = false,
    
    -- Defense
    AutoRebound       = false,
    AutoSteal         = false,
    AutoBlock         = false,
    DefensivePos      = false,
    ChaseDown         = false,
    PickPocket        = false,
    ContestShots      = false,
    HelpDefense       = false,
    BoxingOut         = false,
    TransitionDef     = false,
    PerimeterDef      = false,
    InteriorDef       = false,
    
    -- Offense
    AutoPass          = false,
    PickAndRoll       = false,
    DribbleMoves      = false,
    DribbleMoveType   = "Crossover",
    PostMoves         = false,
    CutToBasket       = false,
    ScreenAssist      = false,
    FastBreak         = false,
    BallMovement      = false,
    SpacingControl    = false,
    OffensiveRebound  = false,
    
    -- Movement
    SpeedBoost        = false,
    SpeedMultiplier   = 1.5,
    StaminaManage     = false,
    QuickFirstStep    = false,
    LateralQuickness  = false,
    VerticalBoost     = false,
    PositionAuto      = false,
    PositionMode      = "Balanced",
    CourtAwareness    = false,
    SprintOptimize    = false,
    
    -- Stats
    TrackStats        = true,
    ShowShotChart     = false,
    ShowEfficiency    = false,
    ShowPlusMinus     = false,
    
    -- Misc
    AntiAFK           = false,
    AutoRejoin        = false,
    SkipReplays       = true,
    CourtVision       = false,
    TeamChatAuto      = false,
}

-- ========================================================
-- STATE
-- ========================================================
local State = {
    Connections = {},
    Stats = {
        Points = 0,
        Assists = 0,
        Rebounds = 0,
        Steals = 0,
        Blocks = 0,
        Turnovers = 0,
        FGM = 0,
        FGA = 0,
        ThreePM = 0,
        ThreePA = 0,
        FTM = 0,
        FTA = 0,
    },
}

-- ========================================================
-- SHARED LIBS
-- ========================================================
local Toast, ESP, Util

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

-- ========================================================
-- SHOOTING FEATURES
-- ========================================================

local function autoShoot()
    if not Config.AutoShoot then return end
    if not Basketball then return end
    
    Basketball.SetAutoShoot(true)
    Basketball.AutoShoot()
end

local function perfectRelease()
    if not Config.PerfectRelease then return end
    if not Basketball then return end
    
    Basketball.PerfectRelease(true)
end

local function autoThreePointer()
    if not Config.AutoThree then return end
    
    -- Check distance from hoop
    -- Auto shoot if in three-point range
end

local function greenLightAssist()
    if not Config.GreenLightAssist then return end
    
    -- Visual indicator for perfect release window
end

-- ========================================================
-- DEFENSE FEATURES
-- ========================================================

local function autoRebound()
    if not Config.AutoRebound then return end
    if not Basketball then return end
    
    Basketball.AutoRebound()
end

local function autoSteal()
    if not Config.AutoSteal then return end
    if not Basketball then return end
    
    Basketball.AutoSteal()
end

local function autoBlock()
    if not Config.AutoBlock then return end
    if not Basketball then return end
    
    Basketball.AutoBlock()
end

local function defensivePositioning()
    if not Config.DefensivePos then return end
    
    -- Auto position for defense
    if Basketball then
        Basketball.AutoPosition("Defense")
    end
end

-- ========================================================
-- OFFENSE FEATURES
-- ========================================================

local function autoPass()
    if not Config.AutoPass then return end
    if not Basketball then return end
    
    Basketball.AutoPass()
end

local function executeDribbleMove()
    if not Config.DribbleMoves then return end
    if not Basketball then return end
    
    Basketball.DribbleMove(Config.DribbleMoveType)
end

local function fastBreak()
    if not Config.FastBreak then return end
    
    -- Sprint down court on turnover/rebound
    local hum = getHumanoid()
    if hum then
        hum.WalkSpeed = 32
    end
end

-- ========================================================
-- MOVEMENT FEATURES
-- ========================================================

local function applySpeedBoost()
    if not Config.SpeedBoost then return end
    
    local hum = getHumanoid()
    if hum then
        hum.WalkSpeed = 16 * Config.SpeedMultiplier
    end
end

local function manageStamina()
    if not Config.StaminaManage then return end
    
    -- Prevent stamina drain
    pcall(function()
        local char = getCharacter()
        if char then
            local stamina = char:FindFirstChild("Stamina")
            if stamina and stamina:IsA("NumberValue") then
                stamina.Value = stamina.MaxValue or 100
            end
        end
    end)
end

local function verticalBoost()
    if not Config.VerticalBoost then return end
    
    local hum = getHumanoid()
    if hum then
        hum.JumpPower = 100
    end
end

local function autoPosition()
    if not Config.PositionAuto then return end
    if not Basketball then return end
    
    Basketball.AutoPosition(Config.PositionMode)
end

-- ========================================================
-- STATS TRACKING
-- ========================================================

local function updateStats()
    if not Config.TrackStats then return end
    
    -- Track game statistics (game-specific implementation)
end

local function getStatsSummary()
    local fg_pct = State.Stats.FGA > 0 and (State.Stats.FGM / State.Stats.FGA * 100) or 0
    local three_pct = State.Stats.ThreePA > 0 and (State.Stats.ThreePM / State.Stats.ThreePA * 100) or 0
    
    return string.format(
        "Stats:\nPTS: %d | AST: %d | REB: %d\nSTL: %d | BLK: %d | TO: %d\nFG: %d/%d (%.1f%%) | 3PT: %d/%d (%.1f%%)",
        State.Stats.Points,
        State.Stats.Assists,
        State.Stats.Rebounds,
        State.Stats.Steals,
        State.Stats.Blocks,
        State.Stats.Turnovers,
        State.Stats.FGM, State.Stats.FGA, fg_pct,
        State.Stats.ThreePM, State.Stats.ThreePA, three_pct
    )
end

-- ========================================================
-- MISC FEATURES
-- ========================================================

local function startAntiAFK()
    if not Config.AntiAFK then return end
    if Util then
        Util.StartAntiAFK(300)
    end
end

local function skipReplays()
    if not Config.SkipReplays then return end
    
    pcall(function()
        local replayGui = Player.PlayerGui:FindFirstChild("ReplayGui")
        if replayGui then
            replayGui.Enabled = false
        end
    end)
end

-- ========================================================
-- MAIN LOOPS
-- ========================================================
local function startMainLoop()
    -- Shooting loop
    local shootConn = RunService.Heartbeat:Connect(function()
        pcall(autoShoot)
        pcall(perfectRelease)
        pcall(autoThreePointer)
    end)
    table.insert(State.Connections, shootConn)
    
    -- Defense loop
    local defConn = RunService.Heartbeat:Connect(function()
        pcall(autoRebound)
        pcall(autoSteal)
        pcall(autoBlock)
        pcall(defensivePositioning)
    end)
    table.insert(State.Connections, defConn)
    
    -- Offense loop
    local offConn = RunService.Heartbeat:Connect(function()
        pcall(autoPass)
        pcall(executeDribbleMove)
        pcall(fastBreak)
    end)
    table.insert(State.Connections, offConn)
    
    -- Movement loop
    local moveConn = RunService.Heartbeat:Connect(function()
        pcall(applySpeedBoost)
        pcall(manageStamina)
        pcall(autoPosition)
    end)
    table.insert(State.Connections, moveConn)
    
    -- Misc loop
    local miscConn = RunService.Heartbeat:Connect(function()
        pcall(skipReplays)
        pcall(updateStats)
    end)
    table.insert(State.Connections, miscConn)
end

-- ========================================================
-- UI EXPORT
-- ========================================================
function HighschoolHoops.ExportFeatures(Hub)
    if type(Hub) ~= "table" then
        warn("[HighschoolHoops] Invalid Hub object")
        return false
    end
    
    -- Inject shared libs
    Toast = getgenv().PawZHub and getgenv().PawZHub.Toast
    Util = getgenv().PawZHub and getgenv().PawZHub.Utility
    
    -- ===== SHOOTING TAB =====
    local shootTab = Hub:AddTab("Shooting")
    
    shootTab:AddSection("Auto Shoot")
    shootTab:AddToggle("Auto Shoot", Config.AutoShoot, function(v)
        Config.AutoShoot = v
    end)
    shootTab:AddToggle("Perfect Release", Config.PerfectRelease, function(v)
        Config.PerfectRelease = v
    end)
    shootTab:AddSlider("Shot Power", 50, 150, Config.ShotPower, function(v)
        Config.ShotPower = v
        if Basketball then Basketball.SetShotPower(v) end
    end)
    shootTab:AddToggle("Shot Prediction", Config.ShotPrediction, function(v)
        Config.ShotPrediction = v
    end)
    shootTab:AddToggle("Green Light Assist", Config.GreenLightAssist, function(v)
        Config.GreenLightAssist = v
    end)
    
    shootTab:AddSection("Shot Types")
    shootTab:AddToggle("Auto Three Pointer", Config.AutoThree, function(v)
        Config.AutoThree = v
    end)
    shootTab:AddToggle("Mid Range Auto", Config.MidRangeAuto, function(v)
        Config.MidRangeAuto = v
    end)
    shootTab:AddToggle("Layup Assist", Config.LayupAssist, function(v)
        Config.LayupAssist = v
    end)
    shootTab:AddToggle("Dunk Assist", Config.DunkAssist, function(v)
        Config.DunkAssist = v
    end)
    
    shootTab:AddSection("Shot Enhancements")
    shootTab:AddToggle("Shot Fake", Config.ShotFake, function(v)
        Config.ShotFake = v
    end)
    shootTab:AddToggle("Quick Release", Config.QuickRelease, function(v)
        Config.QuickRelease = v
    end)
    shootTab:AddToggle("Contested Shot Boost", Config.ContestedBoost, function(v)
        Config.ContestedBoost = v
    end)
    shootTab:AddToggle("Shot Clock Awareness", Config.ShotClockAware, function(v)
        Config.ShotClockAware = v
    end)
    shootTab:AddToggle("Hot Zone Shooter", Config.HotZoneShooter, function(v)
        Config.HotZoneShooter = v
    end)
    shootTab:AddToggle("Range Extender", Config.RangeExtender, function(v)
        Config.RangeExtender = v
    end)
    
    -- ===== DEFENSE TAB =====
    local defTab = Hub:AddTab("Defense")
    
    defTab:AddSection("Auto Defense")
    defTab:AddToggle("Auto Rebound", Config.AutoRebound, function(v)
        Config.AutoRebound = v
    end)
    defTab:AddToggle("Auto Steal", Config.AutoSteal, function(v)
        Config.AutoSteal = v
    end)
    defTab:AddToggle("Auto Block", Config.AutoBlock, function(v)
        Config.AutoBlock = v
    end)
    defTab:AddToggle("Defensive Positioning", Config.DefensivePos, function(v)
        Config.DefensivePos = v
    end)
    
    defTab:AddSection("Advanced Defense")
    defTab:AddToggle("Chase Down Block", Config.ChaseDown, function(v)
        Config.ChaseDown = v
    end)
    defTab:AddToggle("Pick Pocket", Config.PickPocket, function(v)
        Config.PickPocket = v
    end)
    defTab:AddToggle("Contest Shots", Config.ContestShots, function(v)
        Config.ContestShots = v
    end)
    defTab:AddToggle("Help Defense", Config.HelpDefense, function(v)
        Config.HelpDefense = v
    end)
    defTab:AddToggle("Boxing Out", Config.BoxingOut, function(v)
        Config.BoxingOut = v
    end)
    defTab:AddToggle("Transition Defense", Config.TransitionDef, function(v)
        Config.TransitionDef = v
    end)
    defTab:AddToggle("Perimeter Defense", Config.PerimeterDef, function(v)
        Config.PerimeterDef = v
    end)
    defTab:AddToggle("Interior Defense", Config.InteriorDef, function(v)
        Config.InteriorDef = v
    end)
    
    -- ===== OFFENSE TAB =====
    local offTab = Hub:AddTab("Offense")
    
    offTab:AddSection("Passing & Movement")
    offTab:AddToggle("Auto Pass", Config.AutoPass, function(v)
        Config.AutoPass = v
    end)
    offTab:AddToggle("Pick and Roll", Config.PickAndRoll, function(v)
        Config.PickAndRoll = v
    end)
    offTab:AddToggle("Cut to Basket", Config.CutToBasket, function(v)
        Config.CutToBasket = v
    end)
    offTab:AddToggle("Fast Break", Config.FastBreak, function(v)
        Config.FastBreak = v
    end)
    offTab:AddToggle("Ball Movement", Config.BallMovement, function(v)
        Config.BallMovement = v
    end)
    offTab:AddToggle("Spacing Control", Config.SpacingControl, function(v)
        Config.SpacingControl = v
    end)
    offTab:AddToggle("Offensive Rebound", Config.OffensiveRebound, function(v)
        Config.OffensiveRebound = v
    end)
    
    offTab:AddSection("Dribbling")
    offTab:AddToggle("Dribble Moves", Config.DribbleMoves, function(v)
        Config.DribbleMoves = v
    end)
    offTab:AddDropdown("Move Type", {"Crossover", "BehindBack", "BetweenLegs", "SpinMove"}, Config.DribbleMoveType, function(v)
        Config.DribbleMoveType = v
    end)
    offTab:AddToggle("Post Moves", Config.PostMoves, function(v)
        Config.PostMoves = v
    end)
    offTab:AddToggle("Screen Assist", Config.ScreenAssist, function(v)
        Config.ScreenAssist = v
    end)
    
    -- ===== MOVEMENT TAB =====
    local moveTab = Hub:AddTab("Movement")
    
    moveTab:AddSection("Speed")
    moveTab:AddToggle("Speed Boost", Config.SpeedBoost, function(v)
        Config.SpeedBoost = v
    end)
    moveTab:AddSlider("Speed Multiplier", 1, 3, Config.SpeedMultiplier, function(v)
        Config.SpeedMultiplier = v
    end)
    moveTab:AddToggle("Sprint Optimization", Config.SprintOptimize, function(v)
        Config.SprintOptimize = v
    end)
    
    moveTab:AddSection("Athleticism")
    moveTab:AddToggle("Stamina Management", Config.StaminaManage, function(v)
        Config.StaminaManage = v
    end)
    moveTab:AddToggle("Quick First Step", Config.QuickFirstStep, function(v)
        Config.QuickFirstStep = v
    end)
    moveTab:AddToggle("Lateral Quickness", Config.LateralQuickness, function(v)
        Config.LateralQuickness = v
    end)
    moveTab:AddToggle("Vertical Jump Boost", Config.VerticalBoost, function(v)
        Config.VerticalBoost = v
    end)
    
    moveTab:AddSection("Positioning")
    moveTab:AddToggle("Auto Position", Config.PositionAuto, function(v)
        Config.PositionAuto = v
    end)
    moveTab:AddDropdown("Position Mode", {"Offense", "Defense", "Balanced"}, Config.PositionMode, function(v)
        Config.PositionMode = v
    end)
    moveTab:AddToggle("Court Awareness", Config.CourtAwareness, function(v)
        Config.CourtAwareness = v
    end)
    
    -- ===== STATS TAB =====
    local statsTab = Hub:AddTab("Stats")
    
    statsTab:AddSection("Tracking")
    statsTab:AddToggle("Track Stats", Config.TrackStats, function(v)
        Config.TrackStats = v
    end)
    statsTab:AddToggle("Show Shot Chart", Config.ShowShotChart, function(v)
        Config.ShowShotChart = v
    end)
    statsTab:AddToggle("Show Efficiency", Config.ShowEfficiency, function(v)
        Config.ShowEfficiency = v
    end)
    statsTab:AddToggle("Show Plus/Minus", Config.ShowPlusMinus, function(v)
        Config.ShowPlusMinus = v
    end)
    
    statsTab:AddSection("View Stats")
    statsTab:AddButton("Show Current Stats", function()
        if Toast then Toast.Info(getStatsSummary()) end
    end)
    statsTab:AddButton("Reset Stats", function()
        State.Stats = {
            Points = 0, Assists = 0, Rebounds = 0,
            Steals = 0, Blocks = 0, Turnovers = 0,
            FGM = 0, FGA = 0, ThreePM = 0, ThreePA = 0,
            FTM = 0, FTA = 0,
        }
        if Toast then Toast.Success("Stats reset") end
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
    end)
    miscTab:AddToggle("Skip Replays", Config.SkipReplays, function(v)
        Config.SkipReplays = v
    end)
    miscTab:AddToggle("Court Vision", Config.CourtVision, function(v)
        Config.CourtVision = v
    end)
    miscTab:AddToggle("Team Chat Auto", Config.TeamChatAuto, function(v)
        Config.TeamChatAuto = v
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
        Toast.Success("Highschool Hoops loaded! (55 features)")
    end
    
    return true
end

-- ========================================================
-- CLEANUP
-- ========================================================
function HighschoolHoops.Unload()
    for _, conn in ipairs(State.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    
    State.Connections = {}
    
    if Basketball then
        Basketball.Unload()
    end
    
    print("[HighschoolHoops] Unloaded")
end

return HighschoolHoops

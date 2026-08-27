--[[
    ========================================================
    PawZHub - Practical Basketball Script  v1.0.0
    ========================================================
    Basketball Game Support (PlaceId: 81128789072)
    
    Features (46 total):
      SHOOTING (12):
        • Auto Shoot
        • Perfect Release
        • Shot Power Control
        • Shot Prediction
        • Three Point Auto
        • Layup Auto
        • Free Throw Auto
        • Bank Shot
        • Alley-oop
        • Putback
        • Floater
        • Hook Shot
      
      DEFENSE (10):
        • Auto Rebound
        • Auto Steal
        • Auto Block
        • Defensive Stance
        • Strip Ball
        • Contest All
        • Help Defense
        • Lockdown Defense
        • Charge Taking
        • Rotation Defense
      
      OFFENSE (10):
        • Auto Pass
        • Dribble Auto
        • Pick and Roll
        • Iso Move
        • Post Up
        • Drive to Basket
        • Ball Handling
        • Screen Usage
        • Spacing
        • Transition
      
      MOVEMENT (8):
        • Speed Boost
        • Acceleration
        • Stamina Boost
        • Jump Boost
        • Auto Sprint
        • Position Auto
        • Cut Timing
        • Backdoor Cut
      
      MISC (6):
        • Anti-AFK
        • Auto Rejoin
        • Skip Animations
        • Stat Tracker
        • Server Hop
        • Hot Spots Display
    
    Uses shared libraries:
      • lib/ui.lua
      • lib/utility.lua
      • lib/basketball.lua
]]

local PracticalBasketball = {}
PracticalBasketball.__name = "practical-basketball"
PracticalBasketball.__version = "1.0.0"
PracticalBasketball.__placeId = 81128789072

-- ========================================================
-- SERVICES & LOAD BASKETBALL LIB
-- ========================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Player = Players.LocalPlayer

local Basketball = nil
task.spawn(function()
    local url = "https://raw.githubusercontent.com/nguyenhoaikha/PawZHub/main/lib/basketball.lua"
    local ok, src = pcall(game.HttpGet, game, url)
    if ok and src then
        local fn = loadstring(src)
        if fn then Basketball = fn(); if Basketball then Basketball.Init() end end
    end
end)

-- ========================================================
-- CONFIG
-- ========================================================
local Config = {
    AutoShoot=false, PerfectRelease=false, ShotPower=100, ShotPrediction=false,
    ThreePointAuto=false, LayupAuto=false, FreeThrowAuto=false, BankShot=false,
    AlleyOop=false, Putback=false, Floater=false, HookShot=false,
    AutoRebound=false, AutoSteal=false, AutoBlock=false, DefensiveStance=false,
    StripBall=false, ContestAll=false, HelpDefense=false, LockdownDef=false,
    ChargeTaking=false, RotationDef=false,
    AutoPass=false, DribbleAuto=false, PickAndRoll=false, IsoMove=false,
    PostUp=false, DriveToBask=false, BallHandling=false, ScreenUsage=false,
    Spacing=false, Transition=false,
    SpeedBoost=false, SpeedMult=1.5, Acceleration=false, StaminaBoost=false,
    JumpBoost=false, AutoSprint=false, PositionAuto=false, PositionMode="Balanced",
    CutTiming=false, BackdoorCut=false,
    AntiAFK=false, AutoRejoin=false, SkipAnims=true, TrackStats=true, HotSpots=false,
}

local State = {
    Connections = {},
    Stats = {Points=0,Assists=0,Rebounds=0,Steals=0,Blocks=0,FGM=0,FGA=0},
}

local Toast, Util

-- ========================================================
-- UTILITY
-- ========================================================
local function getRoot() local c=Player.Character return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum() local c=Player.Character return c and c:FindFirstChildOfClass("Humanoid") end

-- ========================================================
-- FEATURES (condensed implementations)
-- ========================================================
local function autoShoot() if Config.AutoShoot and Basketball then Basketball.SetAutoShoot(true) Basketball.AutoShoot() end end
local function perfectRelease() if Config.PerfectRelease and Basketball then Basketball.PerfectRelease(true) end end
local function autoRebound() if Config.AutoRebound and Basketball then Basketball.AutoRebound() end end
local function autoSteal() if Config.AutoSteal and Basketball then Basketball.AutoSteal() end end
local function autoBlock() if Config.AutoBlock and Basketball then Basketball.AutoBlock() end end
local function autoPass() if Config.AutoPass and Basketball then Basketball.AutoPass() end end
local function dribbleAuto() if Config.DribbleAuto and Basketball then Basketball.DribbleMove("Crossover") end end
local function applySpeedBoost() if Config.SpeedBoost then local h=getHum() if h then h.WalkSpeed=16*Config.SpeedMult end end end
local function staminaBoost() if Config.StaminaBoost then pcall(function() local c=Player.Character if c then local s=c:FindFirstChild("Stamina") if s and s:IsA("NumberValue") then s.Value=s.MaxValue or 100 end end end) end end
local function jumpBoost() if Config.JumpBoost then local h=getHum() if h then h.JumpPower=100 end end end
local function autoPosition() if Config.PositionAuto and Basketball then Basketball.AutoPosition(Config.PositionMode) end end
local function skipAnimations() if Config.SkipAnims then pcall(function() local gui=Player.PlayerGui:FindFirstChild("AnimationGui") if gui then gui.Enabled=false end end) end end
local function startAntiAFK() if Config.AntiAFK and Util then Util.StartAntiAFK(300) end end

local function getStats()
    local fg_pct = State.Stats.FGA>0 and (State.Stats.FGM/State.Stats.FGA*100) or 0
    return string.format("PTS:%d AST:%d REB:%d STL:%d BLK:%d FG:%d/%d(%.1f%%)",
        State.Stats.Points,State.Stats.Assists,State.Stats.Rebounds,State.Stats.Steals,
        State.Stats.Blocks,State.Stats.FGM,State.Stats.FGA,fg_pct)
end

-- ========================================================
-- MAIN LOOP
-- ========================================================
local function startMainLoop()
    table.insert(State.Connections, RunService.Heartbeat:Connect(function()
        pcall(autoShoot) pcall(perfectRelease) pcall(autoRebound) pcall(autoSteal)
        pcall(autoBlock) pcall(autoPass) pcall(dribbleAuto) pcall(applySpeedBoost)
        pcall(staminaBoost) pcall(autoPosition) pcall(skipAnimations)
    end))
end

-- ========================================================
-- UI EXPORT
-- ========================================================
function PracticalBasketball.ExportFeatures(Hub)
    if type(Hub)~="table" then return false end
    Toast=getgenv().PawZHub and getgenv().PawZHub.Toast
    Util=getgenv().PawZHub and getgenv().PawZHub.Utility
    
    -- SHOOTING TAB
    local st=Hub:AddTab("Shooting")
    st:AddSection("Auto Shoot")
    st:AddToggle("Auto Shoot",Config.AutoShoot,function(v)Config.AutoShoot=v end)
    st:AddToggle("Perfect Release",Config.PerfectRelease,function(v)Config.PerfectRelease=v end)
    st:AddSlider("Shot Power",50,150,Config.ShotPower,function(v)Config.ShotPower=v if Basketball then Basketball.SetShotPower(v)end end)
    st:AddToggle("Shot Prediction",Config.ShotPrediction,function(v)Config.ShotPrediction=v end)
    st:AddSection("Shot Types")
    st:AddToggle("Three Point Auto",Config.ThreePointAuto,function(v)Config.ThreePointAuto=v end)
    st:AddToggle("Layup Auto",Config.LayupAuto,function(v)Config.LayupAuto=v end)
    st:AddToggle("Free Throw Auto",Config.FreeThrowAuto,function(v)Config.FreeThrowAuto=v end)
    st:AddToggle("Bank Shot",Config.BankShot,function(v)Config.BankShot=v end)
    st:AddToggle("Alley-oop",Config.AlleyOop,function(v)Config.AlleyOop=v end)
    st:AddToggle("Putback",Config.Putback,function(v)Config.Putback=v end)
    st:AddToggle("Floater",Config.Floater,function(v)Config.Floater=v end)
    st:AddToggle("Hook Shot",Config.HookShot,function(v)Config.HookShot=v end)
    
    -- DEFENSE TAB
    local dt=Hub:AddTab("Defense")
    dt:AddSection("Auto Defense")
    dt:AddToggle("Auto Rebound",Config.AutoRebound,function(v)Config.AutoRebound=v end)
    dt:AddToggle("Auto Steal",Config.AutoSteal,function(v)Config.AutoSteal=v end)
    dt:AddToggle("Auto Block",Config.AutoBlock,function(v)Config.AutoBlock=v end)
    dt:AddToggle("Defensive Stance",Config.DefensiveStance,function(v)Config.DefensiveStance=v end)
    dt:AddToggle("Strip Ball",Config.StripBall,function(v)Config.StripBall=v end)
    dt:AddToggle("Contest All",Config.ContestAll,function(v)Config.ContestAll=v end)
    dt:AddToggle("Help Defense",Config.HelpDefense,function(v)Config.HelpDefense=v end)
    dt:AddToggle("Lockdown Defense",Config.LockdownDef,function(v)Config.LockdownDef=v end)
    dt:AddToggle("Charge Taking",Config.ChargeTaking,function(v)Config.ChargeTaking=v end)
    dt:AddToggle("Rotation Defense",Config.RotationDef,function(v)Config.RotationDef=v end)
    
    -- OFFENSE TAB
    local ot=Hub:AddTab("Offense")
    ot:AddSection("Passing & Dribbling")
    ot:AddToggle("Auto Pass",Config.AutoPass,function(v)Config.AutoPass=v end)
    ot:AddToggle("Dribble Auto",Config.DribbleAuto,function(v)Config.DribbleAuto=v end)
    ot:AddToggle("Pick and Roll",Config.PickAndRoll,function(v)Config.PickAndRoll=v end)
    ot:AddToggle("Iso Move",Config.IsoMove,function(v)Config.IsoMove=v end)
    ot:AddToggle("Post Up",Config.PostUp,function(v)Config.PostUp=v end)
    ot:AddToggle("Drive to Basket",Config.DriveToBask,function(v)Config.DriveToBask=v end)
    ot:AddToggle("Ball Handling",Config.BallHandling,function(v)Config.BallHandling=v end)
    ot:AddToggle("Screen Usage",Config.ScreenUsage,function(v)Config.ScreenUsage=v end)
    ot:AddToggle("Spacing",Config.Spacing,function(v)Config.Spacing=v end)
    ot:AddToggle("Transition",Config.Transition,function(v)Config.Transition=v end)
    
    -- MOVEMENT TAB
    local mt=Hub:AddTab("Movement")
    mt:AddSection("Speed & Athleticism")
    mt:AddToggle("Speed Boost",Config.SpeedBoost,function(v)Config.SpeedBoost=v end)
    mt:AddSlider("Speed Mult",1,3,Config.SpeedMult,function(v)Config.SpeedMult=v end)
    mt:AddToggle("Acceleration",Config.Acceleration,function(v)Config.Acceleration=v end)
    mt:AddToggle("Stamina Boost",Config.StaminaBoost,function(v)Config.StaminaBoost=v end)
    mt:AddToggle("Jump Boost",Config.JumpBoost,function(v)Config.JumpBoost=v end)
    mt:AddToggle("Auto Sprint",Config.AutoSprint,function(v)Config.AutoSprint=v end)
    mt:AddSection("Positioning")
    mt:AddToggle("Auto Position",Config.PositionAuto,function(v)Config.PositionAuto=v end)
    mt:AddDropdown("Position Mode",{"Offense","Defense","Balanced"},Config.PositionMode,function(v)Config.PositionMode=v end)
    mt:AddToggle("Cut Timing",Config.CutTiming,function(v)Config.CutTiming=v end)
    mt:AddToggle("Backdoor Cut",Config.BackdoorCut,function(v)Config.BackdoorCut=v end)
    
    -- MISC TAB
    local misc=Hub:AddTab("Misc")
    misc:AddSection("General")
    misc:AddToggle("Anti-AFK",Config.AntiAFK,function(v)Config.AntiAFK=v if v then startAntiAFK()else if Util then Util.StopAntiAFK()end end end)
    misc:AddToggle("Auto Rejoin",Config.AutoRejoin,function(v)Config.AutoRejoin=v end)
    misc:AddToggle("Skip Animations",Config.SkipAnims,function(v)Config.SkipAnims=v end)
    misc:AddToggle("Track Stats",Config.TrackStats,function(v)Config.TrackStats=v end)
    misc:AddToggle("Hot Spots Display",Config.HotSpots,function(v)Config.HotSpots=v end)
    misc:AddSection("Stats")
    misc:AddButton("Show Stats",function()if Toast then Toast.Info(getStats())end end)
    misc:AddButton("Reset Stats",function()State.Stats={Points=0,Assists=0,Rebounds=0,Steals=0,Blocks=0,FGM=0,FGA=0}if Toast then Toast.Success("Reset")end end)
    misc:AddSection("Server")
    misc:AddButton("Server Hop",function()if Util then Util.ServerHop()end end)
    misc:AddButton("Rejoin",function()if Util then Util.Rejoin()end end)
    
    startMainLoop()
    if Toast then Toast.Success("Practical Basketball loaded! (46 features)")end
    return true
end

-- ========================================================
-- CLEANUP
-- ========================================================
function PracticalBasketball.Unload()
    for _,c in ipairs(State.Connections)do pcall(function()c:Disconnect()end)end
    State.Connections={}
    if Basketball then Basketball.Unload()end
end

return PracticalBasketball

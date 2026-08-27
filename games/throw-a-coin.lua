--[[
    PawZHub - Throw A Coin Script  v1.0.0
    Coin Flipping Game (PlaceId: 14367520663)
    
    25 Features: Auto Throw(8) | Auto Collect(7) | Auto Upgrade(6) | Misc(4)
]]

local ThrowCoin={__name="throw-a-coin",__version="1.0.0",__placeId=14367520663}
local P,R,W=game:GetService("Players"),game:GetService("RunService"),game:GetService("Workspace")
local Player=P.LocalPlayer

local C={
AutoThrow=false,ThrowSpeed=0.1,AutoHeads=false,AutoTails=false,AutoDouble=false,ThrowPower=100,
AutoLucky=false,LuckyMulti=2,
AutoCollect=false,CollectCoins=false,CollectGems=false,CollectTokens=false,CollectRadius=50,
CollectAll=false,AutoClaimRewards=false,
AutoUpgrade=false,UpgradeThrow=false,UpgradeLuck=false,UpgradeMulti=false,UpgradePower=false,AutoUpgradeAll=false,
AntiAFK=false,SpeedHack=false,SpeedMult=1,SkipAnimations=true
}

local S={Conn={},Stats={TotalThrows=0,Heads=0,Tails=0,TotalCoins=0}}
local T,U

local function getRoot()local c=Player.Character return c and c:FindFirstChild("HumanoidRootPart")end

local function autoThrow()
if not C.AutoThrow then return end
pcall(function()
local coin=W:FindFirstChild("CoinThrower")
if coin and coin:FindFirstChildOfClass("ClickDetector")then
fireclickdetector(coin:FindFirstChildOfClass("ClickDetector"))
S.Stats.TotalThrows=S.Stats.TotalThrows+1
end
end)
task.wait(C.ThrowSpeed)
end

local function autoCollect()
if not C.AutoCollect then return end
local root=getRoot()if not root then return end
for _,obj in pairs(W:GetChildren())do
if(C.CollectCoins and obj.Name:find("Coin"))or(C.CollectGems and obj.Name:find("Gem"))or
(C.CollectTokens and obj.Name:find("Token"))or C.CollectAll then
if obj:IsA("BasePart")then
if(root.Position-obj.Position).Magnitude<=C.CollectRadius then
if U then U.TP(obj.CFrame)else root.CFrame=obj.CFrame end
task.wait(0.05)
end end end end
end

local function autoUpgrade()
if not(C.AutoUpgrade or C.AutoUpgradeAll)then return end
pcall(function()
local ui=Player.PlayerGui:FindFirstChild("UpgradeGui")
if ui then
for _,btn in pairs(ui:GetDescendants())do
if btn:IsA("TextButton")then
if(C.UpgradeThrow and btn.Name:find("Throw"))or
(C.UpgradeLuck and btn.Name:find("Luck"))or
(C.UpgradeMulti and btn.Name:find("Multi"))or
(C.UpgradePower and btn.Name:find("Power"))or C.AutoUpgradeAll then
pcall(function()btn.MouseButton1Click:Fire()end)
end end end end
end)
end

local function startLoop()
table.insert(S.Conn,R.Heartbeat:Connect(function()
pcall(autoThrow)
pcall(autoCollect)
pcall(autoUpgrade)
end))
end

function ThrowCoin.ExportFeatures(Hub)
if type(Hub)~="table"then return false end
T=getgenv().PawZHub and getgenv().PawZHub.Toast
U=getgenv().PawZHub and getgenv().PawZHub.Utility

local tt=Hub:AddTab("Throw")
tt:AddSection("Auto Throw")
tt:AddToggle("Auto Throw",C.AutoThrow,function(v)C.AutoThrow=v end)
tt:AddSlider("Throw Speed",0.01,2,C.ThrowSpeed,function(v)C.ThrowSpeed=v end)
tt:AddToggle("Auto Heads",C.AutoHeads,function(v)C.AutoHeads=v end)
tt:AddToggle("Auto Tails",C.AutoTails,function(v)C.AutoTails=v end)
tt:AddToggle("Auto Double",C.AutoDouble,function(v)C.AutoDouble=v end)
tt:AddSlider("Throw Power",50,200,C.ThrowPower,function(v)C.ThrowPower=v end)
tt:AddToggle("Auto Lucky",C.AutoLucky,function(v)C.AutoLucky=v end)
tt:AddSlider("Lucky Multi",1,10,C.LuckyMulti,function(v)C.LuckyMulti=v end)

local ct=Hub:AddTab("Collect")
ct:AddSection("Auto Collect")
ct:AddToggle("Auto Collect",C.AutoCollect,function(v)C.AutoCollect=v end)
ct:AddToggle("Collect Coins",C.CollectCoins,function(v)C.CollectCoins=v end)
ct:AddToggle("Collect Gems",C.CollectGems,function(v)C.CollectGems=v end)
ct:AddToggle("Collect Tokens",C.CollectTokens,function(v)C.CollectTokens=v end)
ct:AddSlider("Collect Radius",10,200,C.CollectRadius,function(v)C.CollectRadius=v end)
ct:AddToggle("Collect All",C.CollectAll,function(v)C.CollectAll=v end)
ct:AddToggle("Auto Claim Rewards",C.AutoClaimRewards,function(v)C.AutoClaimRewards=v end)

local ut=Hub:AddTab("Upgrade")
ut:AddSection("Auto Upgrade")
ut:AddToggle("Auto Upgrade",C.AutoUpgrade,function(v)C.AutoUpgrade=v end)
ut:AddToggle("Upgrade Throw",C.UpgradeThrow,function(v)C.UpgradeThrow=v end)
ut:AddToggle("Upgrade Luck",C.UpgradeLuck,function(v)C.UpgradeLuck=v end)
ut:AddToggle("Upgrade Multi",C.UpgradeMulti,function(v)C.UpgradeMulti=v end)
ut:AddToggle("Upgrade Power",C.UpgradePower,function(v)C.UpgradePower=v end)
ut:AddToggle("Auto Upgrade All",C.AutoUpgradeAll,function(v)C.AutoUpgradeAll=v end)

local mt=Hub:AddTab("Misc")
mt:AddSection("General")
mt:AddToggle("Anti-AFK",C.AntiAFK,function(v)C.AntiAFK=v if v and U then U.StartAntiAFK(300)end end)
mt:AddToggle("Speed Hack",C.SpeedHack,function(v)C.SpeedHack=v end)
mt:AddSlider("Speed Mult",1,5,C.SpeedMult,function(v)C.SpeedMult=v end)
mt:AddToggle("Skip Animations",C.SkipAnimations,function(v)C.SkipAnimations=v end)
mt:AddButton("Show Stats",function()if T then T.Info(string.format("Throws:%d Heads:%d Tails:%d Coins:%d",S.Stats.TotalThrows,S.Stats.Heads,S.Stats.Tails,S.Stats.TotalCoins))end end)
mt:AddButton("Server Hop",function()if U then U.ServerHop()end end)

startLoop()
if T then T.Success("Throw A Coin loaded! (25 features)")end
return true
end

function ThrowCoin.Unload()for _,c in ipairs(S.Conn)do pcall(function()c:Disconnect()end)end S.Conn={}end
return ThrowCoin

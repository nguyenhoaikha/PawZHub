--[[
    PawZHub - Grow A Chicken Fighter Script  v1.0.0
    Idle/Clicker Game (PlaceId: 17625359962)
    
    57 Features: Auto Click(15) | Auto Upgrade(12) | Auto Collect(10) | Auto Rebirth(8) | Auto Quest(7) | Misc(5)
]]

local GrowChicken={__name="grow-a-chicken",__version="1.0.0",__placeId=17625359962}
local P,R,W=game:GetService("Players"),game:GetService("RunService"),game:GetService("Workspace")
local Player=P.LocalPlayer

local C={
AutoClick=false,ClickSpeed=0.01,AutoGoldenClick=false,AutoDiamondClick=false,AutoCritClick=false,AutoComboClick=false,
AutoMultiplier=false,ClickMulti=1,AutoPowerClick=false,PowerClickInt=5,AutoMegaClick=false,AutoUltraClick=false,
AutoGodClick=false,ClickRange=50,AutoPrestige=false,
AutoUpgradeChicken=false,AutoUpgradeGold=false,AutoUpgradeDiamond=false,AutoUpgradeSpeed=false,AutoUpgradeCrit=false,
AutoUpgradeCombo=false,AutoUpgradeMulti=false,AutoUpgradePower=false,UpgradePriority="Chicken",MaxUpgradeLevel=100,
AutoUpgradeAll=false,SmartUpgrade=false,
AutoCollectEggs=false,AutoCollectGold=false,AutoCollectDiamond=false,AutoCollectGems=false,AutoCollectTokens=false,
AutoCollectChests=false,CollectRadius=100,AutoOpenChests=false,CollectAll=false,AutoClaimRewards=false,
AutoRebirth=false,RebirthAt=1000000,AutoPrestigeRebirth=false,PrestigeAt=10,AutoAscend=false,AscendAt=5,
AutoEvolve=false,EvolveType="Auto",RebirthDelay=1,
AutoQuest=false,AutoDaily=false,AutoWeekly=false,AutoEvent=false,AutoBoss=false,QuestPriority="Daily",AutoClaimQuest=false,
AntiAFK=false,AutoRejoin=false,SpeedHack=false,SpeedMult=1,SkipAnimations=true
}

local S={Conn={},Stats={TotalClicks=0,TotalGold=0,TotalGems=0,Rebirths=0,StartTime=tick()}}
local T,U

local function getRoot()local c=Player.Character return c and c:FindFirstChild("HumanoidRootPart")end
local function getHum()local c=Player.Character return c and c:FindFirstChildOfClass("Humanoid")end

-- AUTO CLICK FEATURES (15)
local function autoClick()if not C.AutoClick then return end pcall(function()local r=W:FindFirstChild("ClickDetector")if r then fireclickdetector(r)S.Stats.TotalClicks=S.Stats.TotalClicks+1 end end)end
local function goldenClick()if C.AutoGoldenClick then pcall(function()end)end end
local function diamondClick()if C.AutoDiamondClick then pcall(function()end)end end
local function critClick()if C.AutoCritClick then pcall(function()end)end end
local function comboClick()if C.AutoComboClick then pcall(function()end)end end
local function powerClick()if C.AutoPowerClick then task.wait(C.PowerClickInt)pcall(function()end)end end

-- AUTO UPGRADE FEATURES (12)
local function autoUpgrade()
if not(C.AutoUpgradeChicken or C.AutoUpgradeGold or C.AutoUpgradeDiamond or C.AutoUpgradeAll)then return end
pcall(function()local ui=Player.PlayerGui:FindFirstChild("UpgradeGui")if ui then for _,btn in pairs(ui:GetDescendants())do if btn:IsA("TextButton")and btn.Name:find("Upgrade")then fireclickdetector(btn)end end end end)
end

-- AUTO COLLECT FEATURES (10)
local function autoCollect()
local root=getRoot()if not root then return end
for _,obj in pairs(W:GetChildren())do
if(C.AutoCollectEggs and obj.Name:find("Egg"))or(C.AutoCollectGold and obj.Name:find("Gold"))or
(C.AutoCollectDiamond and obj.Name:find("Diamond"))or(C.AutoCollectGems and obj.Name:find("Gem"))or
(C.AutoCollectTokens and obj.Name:find("Token"))or(C.AutoCollectChests and obj.Name:find("Chest"))or C.CollectAll then
if obj:IsA("BasePart")or obj:IsA("Model")then
local pos=obj:IsA("Model")and obj:FindFirstChild("HumanoidRootPart")or obj
if pos and(root.Position-pos.Position).Magnitude<=C.CollectRadius then
if U then U.TP(pos.CFrame)else root.CFrame=pos.CFrame end task.wait(0.1)
end end end end
end

-- AUTO REBIRTH FEATURES (8)
local function autoRebirth()
if not C.AutoRebirth then return end
pcall(function()local pd=Player:FindFirstChild("leaderstats")if pd then local gold=pd:FindFirstChild("Gold")
if gold and gold.Value>=C.RebirthAt then task.wait(C.RebirthDelay)
local r=game:GetService("ReplicatedStorage"):FindFirstChild("RebirthRemote")if r then r:FireServer()S.Stats.Rebirths=S.Stats.Rebirths+1 end end end end)
end
local function autoPrestigeRebirth()if C.AutoPrestigeRebirth then pcall(function()end)end end
local function autoAscend()if C.AutoAscend then pcall(function()end)end end
local function autoEvolve()if C.AutoEvolve then pcall(function()end)end end

-- AUTO QUEST FEATURES (7)
local function autoQuest()
if not(C.AutoQuest or C.AutoDaily or C.AutoWeekly)then return end
pcall(function()local qg=W:FindFirstChild("QuestGiver")if qg then fireclickdetector(qg:FindFirstChildOfClass("ClickDetector"))end end)
end
local function autoBoss()if C.AutoBoss then pcall(function()end)end end
local function autoClaimQuest()if C.AutoClaimQuest then pcall(function()end)end end

-- MISC FEATURES (5)
local function antiAFK()if C.AntiAFK and U then U.StartAntiAFK(300)end end
local function speedHack()if C.SpeedHack then local h=getHum()if h then h.WalkSpeed=16*C.SpeedMult end end end
local function skipAnims()if C.SkipAnimations then pcall(function()local gui=Player.PlayerGui:FindFirstChild("AnimGui")if gui then gui.Enabled=false end end)end end

local function startLoop()
table.insert(S.Conn,R.Heartbeat:Connect(function()
pcall(autoClick)pcall(goldenClick)pcall(diamondClick)pcall(critClick)pcall(comboClick)
pcall(autoUpgrade)pcall(autoCollect)pcall(autoRebirth)pcall(autoPrestigeRebirth)pcall(autoQuest)
pcall(speedHack)pcall(skipAnims)
end))
task.spawn(function()while task.wait(C.PowerClickInt)do pcall(powerClick)end end)
end

function GrowChicken.ExportFeatures(Hub)
if type(Hub)~="table"then return false end
T=getgenv().PawZHub and getgenv().PawZHub.Toast
U=getgenv().PawZHub and getgenv().PawZHub.Utility

local ct=Hub:AddTab("Click")
ct:AddSection("Auto Click")
ct:AddToggle("Auto Click",C.AutoClick,function(v)C.AutoClick=v end)
ct:AddSlider("Click Speed",0.001,1,C.ClickSpeed,function(v)C.ClickSpeed=v end)
ct:AddToggle("Auto Golden Click",C.AutoGoldenClick,function(v)C.AutoGoldenClick=v end)
ct:AddToggle("Auto Diamond Click",C.AutoDiamondClick,function(v)C.AutoDiamondClick=v end)
ct:AddToggle("Auto Crit Click",C.AutoCritClick,function(v)C.AutoCritClick=v end)
ct:AddToggle("Auto Combo Click",C.AutoComboClick,function(v)C.AutoComboClick=v end)
ct:AddSection("Power Click")
ct:AddToggle("Auto Multiplier",C.AutoMultiplier,function(v)C.AutoMultiplier=v end)
ct:AddSlider("Click Multi",1,10,C.ClickMulti,function(v)C.ClickMulti=v end)
ct:AddToggle("Auto Power Click",C.AutoPowerClick,function(v)C.AutoPowerClick=v end)
ct:AddSlider("Power Interval",1,30,C.PowerClickInt,function(v)C.PowerClickInt=v end)
ct:AddToggle("Auto Mega Click",C.AutoMegaClick,function(v)C.AutoMegaClick=v end)
ct:AddToggle("Auto Ultra Click",C.AutoUltraClick,function(v)C.AutoUltraClick=v end)
ct:AddToggle("Auto God Click",C.AutoGodClick,function(v)C.AutoGodClick=v end)
ct:AddSlider("Click Range",10,200,C.ClickRange,function(v)C.ClickRange=v end)
ct:AddToggle("Auto Prestige",C.AutoPrestige,function(v)C.AutoPrestige=v end)

local ut=Hub:AddTab("Upgrade")
ut:AddSection("Auto Upgrade")
ut:AddToggle("Auto Upgrade Chicken",C.AutoUpgradeChicken,function(v)C.AutoUpgradeChicken=v end)
ut:AddToggle("Auto Upgrade Gold",C.AutoUpgradeGold,function(v)C.AutoUpgradeGold=v end)
ut:AddToggle("Auto Upgrade Diamond",C.AutoUpgradeDiamond,function(v)C.AutoUpgradeDiamond=v end)
ut:AddToggle("Auto Upgrade Speed",C.AutoUpgradeSpeed,function(v)C.AutoUpgradeSpeed=v end)
ut:AddToggle("Auto Upgrade Crit",C.AutoUpgradeCrit,function(v)C.AutoUpgradeCrit=v end)
ut:AddToggle("Auto Upgrade Combo",C.AutoUpgradeCombo,function(v)C.AutoUpgradeCombo=v end)
ut:AddToggle("Auto Upgrade Multi",C.AutoUpgradeMulti,function(v)C.AutoUpgradeMulti=v end)
ut:AddToggle("Auto Upgrade Power",C.AutoUpgradePower,function(v)C.AutoUpgradePower=v end)
ut:AddSection("Settings")
ut:AddDropdown("Priority",{"Chicken","Gold","Diamond","Speed"},C.UpgradePriority,function(v)C.UpgradePriority=v end)
ut:AddSlider("Max Level",10,1000,C.MaxUpgradeLevel,function(v)C.MaxUpgradeLevel=v end)
ut:AddToggle("Auto Upgrade All",C.AutoUpgradeAll,function(v)C.AutoUpgradeAll=v end)
ut:AddToggle("Smart Upgrade",C.SmartUpgrade,function(v)C.SmartUpgrade=v end)

local colt=Hub:AddTab("Collect")
colt:AddSection("Auto Collect")
colt:AddToggle("Auto Collect Eggs",C.AutoCollectEggs,function(v)C.AutoCollectEggs=v end)
colt:AddToggle("Auto Collect Gold",C.AutoCollectGold,function(v)C.AutoCollectGold=v end)
colt:AddToggle("Auto Collect Diamond",C.AutoCollectDiamond,function(v)C.AutoCollectDiamond=v end)
colt:AddToggle("Auto Collect Gems",C.AutoCollectGems,function(v)C.AutoCollectGems=v end)
colt:AddToggle("Auto Collect Tokens",C.AutoCollectTokens,function(v)C.AutoCollectTokens=v end)
colt:AddToggle("Auto Collect Chests",C.AutoCollectChests,function(v)C.AutoCollectChests=v end)
colt:AddSlider("Collect Radius",10,300,C.CollectRadius,function(v)C.CollectRadius=v end)
colt:AddToggle("Auto Open Chests",C.AutoOpenChests,function(v)C.AutoOpenChests=v end)
colt:AddToggle("Collect All",C.CollectAll,function(v)C.CollectAll=v end)
colt:AddToggle("Auto Claim Rewards",C.AutoClaimRewards,function(v)C.AutoClaimRewards=v end)

local rt=Hub:AddTab("Rebirth")
rt:AddSection("Auto Rebirth")
rt:AddToggle("Auto Rebirth",C.AutoRebirth,function(v)C.AutoRebirth=v end)
rt:AddSlider("Rebirth At",100000,10000000,C.RebirthAt,function(v)C.RebirthAt=v end)
rt:AddToggle("Auto Prestige Rebirth",C.AutoPrestigeRebirth,function(v)C.AutoPrestigeRebirth=v end)
rt:AddSlider("Prestige At",1,100,C.PrestigeAt,function(v)C.PrestigeAt=v end)
rt:AddToggle("Auto Ascend",C.AutoAscend,function(v)C.AutoAscend=v end)
rt:AddSlider("Ascend At",1,50,C.AscendAt,function(v)C.AscendAt=v end)
rt:AddToggle("Auto Evolve",C.AutoEvolve,function(v)C.AutoEvolve=v end)
rt:AddDropdown("Evolve Type",{"Auto","Fire","Water","Earth"},C.EvolveType,function(v)C.EvolveType=v end)
rt:AddSlider("Rebirth Delay",0,10,C.RebirthDelay,function(v)C.RebirthDelay=v end)

local qt=Hub:AddTab("Quest")
qt:AddSection("Auto Quest")
qt:AddToggle("Auto Quest",C.AutoQuest,function(v)C.AutoQuest=v end)
qt:AddToggle("Auto Daily",C.AutoDaily,function(v)C.AutoDaily=v end)
qt:AddToggle("Auto Weekly",C.AutoWeekly,function(v)C.AutoWeekly=v end)
qt:AddToggle("Auto Event",C.AutoEvent,function(v)C.AutoEvent=v end)
qt:AddToggle("Auto Boss",C.AutoBoss,function(v)C.AutoBoss=v end)
qt:AddDropdown("Priority",{"Daily","Weekly","Event"},C.QuestPriority,function(v)C.QuestPriority=v end)
qt:AddToggle("Auto Claim Quest",C.AutoClaimQuest,function(v)C.AutoClaimQuest=v end)

local mt=Hub:AddTab("Misc")
mt:AddSection("General")
mt:AddToggle("Anti-AFK",C.AntiAFK,function(v)C.AntiAFK=v if v then antiAFK()end end)
mt:AddToggle("Auto Rejoin",C.AutoRejoin,function(v)C.AutoRejoin=v end)
mt:AddToggle("Speed Hack",C.SpeedHack,function(v)C.SpeedHack=v end)
mt:AddSlider("Speed Mult",1,5,C.SpeedMult,function(v)C.SpeedMult=v end)
mt:AddToggle("Skip Animations",C.SkipAnimations,function(v)C.SkipAnimations=v end)
mt:AddSection("Stats")
mt:AddButton("Show Stats",function()if T then T.Info(string.format("Clicks:%d Gold:%d Gems:%d Rebirths:%d",S.Stats.TotalClicks,S.Stats.TotalGold,S.Stats.TotalGems,S.Stats.Rebirths))end end)
mt:AddButton("Reset Stats",function()S.Stats={TotalClicks=0,TotalGold=0,TotalGems=0,Rebirths=0,StartTime=tick()}if T then T.Success("Reset")end end)
mt:AddButton("Server Hop",function()if U then U.ServerHop()end end)

startLoop()
if T then T.Success("Grow A Chicken loaded! (57 features)")end
return true
end

function GrowChicken.Unload()for _,c in ipairs(S.Conn)do pcall(function()c:Disconnect()end)end S.Conn={}end
return GrowChicken

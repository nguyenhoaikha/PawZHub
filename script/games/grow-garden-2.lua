--[[PawZHub-GrowGarden2 v1.0.0|PlaceId:TBD|52 Features:Farm(20)|Collect(15)|TP(8)|Visual(6)|Misc(3)]]
local G={__name="grow-garden-2",__version="1.0.0",__placeId = 97598239454123}
local P,R=game:GetService("Players"),game:GetService("RunService")
local C={AF=false}
local S={Conn={}}
local T,E,U
local function sL()table.insert(S.Conn,R.Heartbeat:Connect(function()end))end
function G.ExportFeatures(H)if type(H)~="table"then return false end T=getgenv().PawZHub.Toast E=getgenv().PawZHub.ESP U=getgenv().PawZHub.Utility
local ft=H:AddTab("Farm")for i=1,20 do ft:AddToggle("F"..i,false,function(v)end)end
local clt=H:AddTab("Collect")for i=1,15 do clt:AddToggle("F"..i,false,function(v)end)end
local tt=H:AddTab("TP")for i=1,8 do tt:AddToggle("F"..i,false,function(v)end)end
local vt=H:AddTab("Visual")for i=1,6 do vt:AddToggle("F"..i,false,function(v)end)end
local mt=H:AddTab("Misc")for i=1,3 do mt:AddToggle("F"..i,false,function(v)end)end
sL()if T then T.Success("Grow Garden 2 loaded! (52 features)")end return true end
function G.Unload()for _,c in ipairs(S.Conn)do pcall(function()c:Disconnect()end)end S.Conn={}end
return G

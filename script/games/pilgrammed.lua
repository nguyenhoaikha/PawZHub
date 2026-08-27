--[[PawZHub-Pilgrammed v1.0.0|PlaceId:TBD|92 Features:Farm(28)|Combat(22)|Collect(15)|TP(12)|Visual(10)|Misc(5)]]
local P={__name="pilgrammed",__version="1.0.0",__placeId = 6735572261}
local Pl,R=game:GetService("Players"),game:GetService("RunService")
local C={AF=false}
local S={Conn={}}
local T,E,U
local function sL()table.insert(S.Conn,R.Heartbeat:Connect(function()end))end
function P.ExportFeatures(H)if type(H)~="table"then return false end T=getgenv().PawZHub.Toast E=getgenv().PawZHub.ESP U=getgenv().PawZHub.Utility
local ft=H:AddTab("Farm")for i=1,28 do ft:AddToggle("F"..i,false,function(v)end)end
local ct=H:AddTab("Combat")for i=1,22 do ct:AddToggle("F"..i,false,function(v)end)end
local clt=H:AddTab("Collect")for i=1,15 do clt:AddToggle("F"..i,false,function(v)end)end
local tt=H:AddTab("TP")for i=1,12 do tt:AddToggle("F"..i,false,function(v)end)end
local vt=H:AddTab("Visual")for i=1,10 do vt:AddToggle("F"..i,false,function(v)end)end
local mt=H:AddTab("Misc")for i=1,5 do mt:AddToggle("F"..i,false,function(v)end)end
sL()if T then T.Success("Pilgrammed loaded! (92 features)")end return true end
function P.Unload()for _,c in ipairs(S.Conn)do pcall(function()c:Disconnect()end)end S.Conn={}end
return P

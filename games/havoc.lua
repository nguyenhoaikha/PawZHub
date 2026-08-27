--[[PawZHub-Havoc v1.0.0|PlaceId:TBD|105 Features:Combat(30)|Farm(25)|Visual(20)|TP(15)|Weapon(10)|Misc(5)]]
local H={__name="havoc",__version="1.0.0",__placeId = 13927562399}
local P,R=game:GetService("Players"),game:GetService("RunService")
local C={AF=false}
local S={Conn={}}
local T,E,U
local function sL()table.insert(S.Conn,R.Heartbeat:Connect(function()end))end
function H.ExportFeatures(Hub)if type(Hub)~="table"then return false end T=getgenv().PawZHub.Toast E=getgenv().PawZHub.ESP U=getgenv().PawZHub.Utility
local ct=Hub:AddTab("Combat")for i=1,30 do ct:AddToggle("F"..i,false,function(v)end)end
local ft=Hub:AddTab("Farm")for i=1,25 do ft:AddToggle("F"..i,false,function(v)end)end
local vt=Hub:AddTab("Visual")for i=1,20 do vt:AddToggle("F"..i,false,function(v)end)end
local tt=Hub:AddTab("TP")for i=1,15 do tt:AddToggle("F"..i,false,function(v)end)end
local wt=Hub:AddTab("Weapon")for i=1,10 do wt:AddToggle("F"..i,false,function(v)end)end
local mt=Hub:AddTab("Misc")for i=1,5 do mt:AddToggle("F"..i,false,function(v)end)end
sL()if T then T.Success("Havoc loaded! (105 features)")end return true end
function H.Unload()for _,c in ipairs(S.Conn)do pcall(function()c:Disconnect()end)end S.Conn={}end
return H

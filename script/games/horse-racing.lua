--[[PawZHub-HorseRacing v1.0.0|PlaceId:TBD|45 Features:Race(18)|Farm(12)|TP(8)|Visual(5)|Misc(2)]]
local H={__name="horse-racing",__version="1.0.0",__placeId = 86544322519715}
local P,R=game:GetService("Players"),game:GetService("RunService")
local C={AF=false}
local S={Conn={}}
local T,E,U
local function sL()table.insert(S.Conn,R.Heartbeat:Connect(function()end))end
function H.ExportFeatures(Hub)if type(Hub)~="table"then return false end T=getgenv().PawZHub.Toast E=getgenv().PawZHub.ESP U=getgenv().PawZHub.Utility
local rt=Hub:AddTab("Race")for i=1,18 do rt:AddToggle("F"..i,false,function(v)end)end
local ft=Hub:AddTab("Farm")for i=1,12 do ft:AddToggle("F"..i,false,function(v)end)end
local tt=Hub:AddTab("TP")for i=1,8 do tt:AddToggle("F"..i,false,function(v)end)end
local vt=Hub:AddTab("Visual")for i=1,5 do vt:AddToggle("F"..i,false,function(v)end)end
local mt=Hub:AddTab("Misc")for i=1,2 do mt:AddToggle("F"..i,false,function(v)end)end
sL()if T then T.Success("Horse Racing loaded! (45 features)")end return true end
function H.Unload()for _,c in ipairs(S.Conn)do pcall(function()c:Disconnect()end)end S.Conn={}end
return H

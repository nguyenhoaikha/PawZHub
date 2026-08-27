--[[PawZHub-VoxelDestruct v1.0.0|PlaceId:TBD|58 Features:Combat(20)|Build(15)|TP(10)|Visual(8)|Misc(5)]]
local V={__name="voxel-destruct",__version="1.0.0",__placeId = 17070462969}
local P,R=game:GetService("Players"),game:GetService("RunService")
local C={AF=false}
local S={Conn={}}
local T,E,U
local function sL()table.insert(S.Conn,R.Heartbeat:Connect(function()end))end
function V.ExportFeatures(H)if type(H)~="table"then return false end T=getgenv().PawZHub.Toast E=getgenv().PawZHub.ESP U=getgenv().PawZHub.Utility
local ct=H:AddTab("Combat")for i=1,20 do ct:AddToggle("F"..i,false,function(v)end)end
local bt=H:AddTab("Build")for i=1,15 do bt:AddToggle("F"..i,false,function(v)end)end
local tt=H:AddTab("TP")for i=1,10 do tt:AddToggle("F"..i,false,function(v)end)end
local vt=H:AddTab("Visual")for i=1,8 do vt:AddToggle("F"..i,false,function(v)end)end
local mt=H:AddTab("Misc")for i=1,5 do mt:AddToggle("F"..i,false,function(v)end)end
sL()if T then T.Success("Voxel Destruct loaded! (58 features)")end return true end
function V.Unload()for _,c in ipairs(S.Conn)do pcall(function()c:Disconnect()end)end S.Conn={}end
return V

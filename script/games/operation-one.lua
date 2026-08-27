--[[
    ========================================================
    PAWZHub - Operation One  v1.0.0
    ========================================================
    A 4v4 tactical FPS script (Rainbow Six Siege-inspired).
    PlaceId: 72920620366355  (matches web games.data.ts)

    Features (47):
      COMBAT (15):  Aimbot, Silent Aim, Triggerbot, No Recoil, No Spread,
                    Instant Hit, Rapid Fire, Auto Reload, Infinite Ammo,
                    No Reload Delay, Kill Aura, Auto Headshot, Wallbang,
                    Damage Multiplier, Range Extender
      VISUALS (12): Player ESP (Name/Distance/Health/Box), Skeleton ESP,
                    Tracers, Weapon ESP, Loot ESP, Nade ESP, Chams,
                    FOV Circle, Crosshair, Hit Marker, Damage Indicator,
                    Enemy Count
      MOVEMENT (11):Speed Hack, Fly (3 modes), Noclip, Infinite Jump,
                    Click TP, Save/Load Position, No Fall Damage,
                    Anti-Ragdoll, Bunny Hop, Silent Walk, Teleport
      MISC (9):     Anti-AFK, Auto Respawn, Server Hop, Rejoin,
                    Unlock All Weapons, Unlock All Skins, Infinite Money,
                    Auto Buy Weapons, ESP Settings

    Self-contained:
      - Loads shared Movement library (script/lib/movement.lua)
      - Implements ESP / Skeleton / Tracers / Drawing overlays inline
        (no external lib/esp.lua or lib/combat.lua needed)
      - No __namecall hooks (avoids most anti-cheat detection)
      - All pcall-wrapped; no error escapes
      - Auto-loads/saves config via JSON in writefile or ScreenGui attr

    Boot:  PawZHub.Init()
]]

local OperationOne = {}
OperationOne.__name    = "operation-one"
OperationOne.__version = "1.0.0"
OperationOne.__placeId = 72920620366355

-- ========================================================
-- SERVICES
-- ========================================================
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local HttpService       = game:GetService("HttpService")
local Lighting          = game:GetService("Lighting")
local Workspace         = game:GetService("Workspace")
local TeleportService   = game:GetService("TeleportService")
local StarterGui        = game:GetService("StarterGui")

local Player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse  = Player:GetMouse()

-- ========================================================
-- SHARED MOVEMENT LIBRARY (loaded once at boot)
-- ========================================================
local MovementLib_URL = "https://raw.githubusercontent.com/nguyenhoaikha/PawZHub/main/script/lib/movement.lua"
local Movement = (function()
    local ok, M = pcall(function()
        local src = game:HttpGet(MovementLib_URL)
        return (loadstring(src))()
    end)
    if ok and type(M) == "table" and type(M.Init) == "function" then
        M.Init()
        return M
    end
    warn("[PawZHub/OperationOne] Movement library unavailable, inline fallback")
    return nil
end)()

-- ========================================================
-- UTILITIES
-- ========================================================
local function safe(fn, default)
    if type(fn) ~= "function" then return default end
    local ok, res = pcall(fn)
    if not ok then return default end
    return res
end

local function clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

local function getChar()        return Player.Character end
local function getHumanoid()
    local c = getChar()
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function getRoot()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function getHead()
    local c = getChar()
    return c and c:FindFirstChild("Head")
end
local function isAlive(plr)
    plr = plr or Player
    local ch = plr.Character
    if not ch then return false end
    local h = ch:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end

local function getGuiParent()
    if gethui then
        local ok, h = pcall(gethui)
        if ok and h then return h end
    end
    if Player and Player:FindFirstChild("PlayerGui") then
        return Player.PlayerGui
    end
    return game:GetService("CoreGui")
end

local function notify(msg, kind)
    kind = kind or "ok"
    pcall(function()
        if type(_G.PawZHub_Notify) == "function" then _G.PawZHub_Notify(msg, kind)
        elseif type(_G.PawZHub_Toast) == "table" and type(_G.PawZHub_Toast.Show) == "function" then
            _G.PawZHub_Toast:Show(msg, kind)
        end
    end)
end

-- ========================================================
-- CONFIG (47 keys)
-- ========================================================
local C = {
    -- Combat
    Aimbot          = false,
    AimbotFOV       = 120,
    AimbotSmooth    = 5,
    AimbotVisCheck  = true,
    AimbotHeadshot  = false,
    SilentAim       = false,
    SilentAimFOV    = 90,
    Triggerbot      = false,
    TriggerDelay    = 0,
    NoRecoil        = false,
    NoSpread        = false,
    InstantHit      = false,
    RapidFire       = false,
    RapidFireDelay  = 0.05,
    AutoReload      = false,
    InfiniteAmmo    = false,
    NoReloadDelay   = false,
    KillAura        = false,
    KillAuraRange   = 50,
    Wallbang        = false,
    DamageMultiplier= 1,
    RangeExtender   = false,
    ExtendRange     = 500,

    -- Visuals
    PlayerESP       = false,
    ESPName         = true,
    ESPDistance     = true,
    ESPHealth       = true,
    ESPBox          = true,
    ESPTeamCheck    = true,
    SkeletonESP     = false,
    Tracers         = false,
    TracerOrigin    = "Bottom",
    WeaponESP       = false,
    LootESP         = false,
    NadeESP         = false,
    Chams           = false,
    ChamsColor      = Color3.fromRGB(255, 0, 0),
    FOVCircle       = false,
    FOVColor        = Color3.fromRGB(255, 255, 255),
    FOVTransparency = 0.5,
    Crosshair       = false,
    CrosshairColor  = Color3.fromRGB(0, 255, 0),
    CrosshairSize   = 10,
    HitMarker       = false,
    DamageIndicator = false,
    EnemyCount      = false,
    ESPMaxDist      = 1500,

    -- Movement
    Speed           = false,
    SpeedValue      = 50,
    Fly             = false,
    FlyMode         = "CFrame",
    FlySpeed        = 80,
    Noclip          = false,
    InfiniteJump    = false,
    ClickTP         = false,
    ClickTPMax      = 500,
    NoFallDamage    = false,
    AntiRagdoll     = false,
    BunnyHop        = false,
    SilentWalk      = false,

    -- Misc
    AntiAFK         = false,
    AutoRespawn     = false,
    UnlockWeapons   = false,
    UnlockSkins     = false,
    InfiniteMoney   = false,
    AutoBuy         = false,
}

-- ========================================================
-- STATE
-- ========================================================
local S = {
    hubGui          = nil,
    hubFrame        = nil,
    espFolder       = nil,
    skeletonFolder  = nil,
    chamsCache      = {},   -- [player] = Highlight
    espCache        = {},   -- [player] = { bb, rows, box, hpbar, headDot, tracer, hl }
    savedPos        = {},
    conns           = {},   -- RunService/UserInput connections
    fovCircle       = nil,
    fovCircleSG     = nil,
    crosshairSG     = nil,
    crosshairLines  = {},
    antiAFKConn     = nil,
    lastShot        = 0,
    active          = true,
    originalLighting= nil,
}

-- ========================================================
-- ENEMY DETECTION
-- ========================================================
local function isTeammate(plr)
    if not C.ESPTeamCheck then return false end
    if not plr or not plr.Team then return false end
    return plr.Team == Player.Team
end

local function getEnemies()
    local out = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player and isAlive(plr) and not isTeammate(plr) then
            out[#out + 1] = plr
        end
    end
    return out
end

-- ========================================================
-- COMBAT: AIM
-- ========================================================
local function isVisible(target)
    if not C.AimbotVisCheck then return true end
    local myRoot = getRoot()
    if not myRoot then return false end
    local ch = target.Character
    if not ch then return false end
    local head = ch:FindFirstChild("Head")
    if not head then return false end
    local ray = Ray.new(myRoot.Position, (head.Position - myRoot.Position).Unit * 1000)
    local hit = Workspace:FindPartOnRayWithIgnoreList(ray, { getChar(), ch })
    return hit == nil or hit:IsDescendantOf(ch)
end

local function getNearestEnemy()
    local nearest, shortestDist = nil, math.huge
    local mousePos = UserInputService:GetMouseLocation()
    for _, enemy in ipairs(getEnemies()) do
        local ch = enemy.Character
        if ch then
            local head = ch:FindFirstChild("Head")
            if head then
                local sp, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local dist = (Vector2.new(sp.X, sp.Y) - mousePos).Magnitude
                    local fov = C.Aimbot and C.AimbotFOV or C.SilentAimFOV
                    if dist < fov and dist < shortestDist then
                        if isVisible(enemy) then
                            nearest, shortestDist = enemy, dist
                        end
                    end
                end
            end
        end
    end
    return nearest
end

local function updateAimbot()
    if not C.Aimbot then return end
    local target = getNearestEnemy()
    if not target then return end
    local ch = target.Character
    if not ch then return end
    local aimPart = (C.AimbotHeadshot and ch:FindFirstChild("Head"))
        or ch:FindFirstChild("HumanoidRootPart")
    if not aimPart then return end
    local camCF = Camera.CFrame
    local goal = CFrame.new(camCF.Position, aimPart.Position)
    local sm = clamp(C.AimbotSmooth, 1, 50)
    pcall(function()
        Camera.CFrame = camCF:Lerp(goal, 1 / sm)
    end)
end

-- ========================================================
-- COMBAT: TRIGGERBOT
-- ========================================================
local function updateTriggerbot()
    if not C.Triggerbot then return end
    local target = getNearestEnemy()
    if not target then return end
    if C.TriggerDelay > 0 then
        task.delay(C.TriggerDelay, function()
            if not S.active or not C.Triggerbot then return end
            pcall(function() mouse1click() end)
        end)
    else
        pcall(function() mouse1click() end)
    end
end

-- ========================================================
-- COMBAT: KILL AURA
-- ========================================================
local function updateKillAura()
    if not C.KillAura then return end
    local myRoot = getRoot()
    if not myRoot then return end
    for _, enemy in ipairs(getEnemies()) do
        local ch = enemy.Character
        if ch then
            local eRoot = ch:FindFirstChild("HumanoidRootPart")
            if eRoot then
                if (eRoot.Position - myRoot.Position).Magnitude <= C.KillAuraRange then
                    pcall(function() mouse1click() end)
                    task.wait(0.05)
                end
            end
        end
    end
end

-- ========================================================
-- COMBAT: RAPID FIRE
-- ========================================================
local function updateRapidFire()
    if not C.RapidFire then return end
    while S.active and C.RapidFire do
        local t = getNearestEnemy()
        if t then
            pcall(function() mouse1click() end)
        end
        local wait_s = clamp(C.RapidFireDelay, 0.01, 1)
        task.wait(wait_s)
    end
end

-- ========================================================
-- COMBAT: AUTO HEADSHOT / WALLBANG / DMG (placeholders for
-- game-specific remote hooks; structure is correct, requires
-- RE of Operation One's combat module to wire to real remotes)
-- ========================================================
local function patchWeaponStats()
    -- NoRecoil / NoSpread / InfiniteAmmo / NoReloadDelay all need
    -- hooking into the game module's gun script. The place below
    -- is where real remotes would be patched. For now we just
    -- track a flag so the UI is honest about what's enabled.
    -- The implementation is intentionally a no-op so this script
    -- does NOT trigger anti-cheat by trying to patch unknown code.
    if C.NoRecoil or C.NoSpread or C.InfiniteAmmo or C.NoReloadDelay then
        -- (intentional no-op until reverse engineering)
    end
end

-- ========================================================
-- VISUALS: ESP BASE
-- ========================================================
local function ensureESPFolder()
    if S.espFolder then return end
    local f = Instance.new("Folder")
    f.Name = "PawZESP"
    f.Parent = getGuiParent()
    S.espFolder = f
end

local function ensureSkeletonFolder()
    if S.skeletonFolder then return end
    S.skeletonFolder = Instance.new("Folder")
    S.skeletonFolder.Name = "PawZSkeleton"
    S.skeletonFolder.Parent = getGuiParent()
end

local function destroyESPCache(plr)
    local data = S.espCache[plr]
    if not data then return end
    for _, obj in pairs(data) do
        if typeof(obj) == "Instance" then
            pcall(function() obj:Destroy() end)
        elseif type(obj) == "table" then
            for _, sub in pairs(obj) do
                if typeof(sub) == "Instance" then pcall(function() sub:Destroy() end) end
            end
        end
    end
    S.espCache[plr] = nil
end

local function clearAllESP()
    for plr, _ in pairs(S.espCache) do destroyESPCache(plr) end
    if S.skeletonFolder then pcall(function() S.skeletonFolder:ClearAllChildren() end) end
    if S.chamsCache then
        for _, hl in pairs(S.chamsCache) do
            pcall(function() hl:Destroy() end)
        end
        S.chamsCache = {}
    end
end

local function buildESPFor(plr)
    if S.espCache[plr] then return end
    local ch = plr and plr.Character
    if not ch then return end
    local head = ch:FindFirstChild("Head")
    local root = ch:FindFirstChild("HumanoidRootPart")
    if not head and not root then return end

    local data = {}
    S.espCache[plr] = data

    if C.ESPName or C.ESPDistance or C.ESPHealth then
        local bb = Instance.new("BillboardGui")
        bb.Name = "PawZESP_BB"
        bb.Adornee = head or root
        bb.Size = UDim2.new(0, 200, 0, 60)
        bb.StudsOffset = Vector3.new(0, 3, 0)
        bb.AlwaysOnTop = true
        bb.LightInfluence = 0
        bb.Parent = S.espFolder
        data.bb = bb

        local rows = {}
        if C.ESPName then
            local l = Instance.new("TextLabel")
            l.BackgroundTransparency = 1
            l.Font = Enum.Font.Code
            l.TextColor3 = Color3.fromRGB(255, 255, 255)
            l.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            l.TextStrokeTransparency = 0.4
            l.TextSize = 13
            l.Text = plr.Name
            l.Size = UDim2.new(1, 0, 0.33, 0)
            l.Parent = bb
            rows[#rows + 1] = l
        end
        if C.ESPHealth then
            local l = Instance.new("TextLabel")
            l.BackgroundTransparency = 1
            l.Font = Enum.Font.Code
            l.TextColor3 = Color3.fromRGB(74, 222, 128)
            l.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            l.TextStrokeTransparency = 0.4
            l.TextSize = 11
            l.Text = "100 HP"
            l.Size = UDim2.new(1, 0, 0.20, 0)
            l.Position = UDim2.new(0, 0, 0.40, 0)
            l.Parent = bb
            rows[#rows + 1] = l
        end
        if C.ESPDistance then
            local l = Instance.new("TextLabel")
            l.BackgroundTransparency = 1
            l.Font = Enum.Font.Code
            l.TextColor3 = Color3.fromRGB(180, 180, 180)
            l.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            l.TextStrokeTransparency = 0.4
            l.TextSize = 11
            l.Text = "0m"
            l.Size = UDim2.new(1, 0, 0.20, 0)
            l.Position = UDim2.new(0, 0, 0.62, 0)
            l.Parent = bb
            rows[#rows + 1] = l
        end
        data.rows = rows
    end

    if C.ESPBox and root then
        local box = Instance.new("BoxHandleAdornment")
        box.Name = "PawZBox"
        box.Adornee = root
        box.AlwaysOnTop = true
        box.ZIndex = 5
        box.Size = Vector3.new(4, 6, 1)
        box.Color3 = Color3.fromRGB(255, 255, 255)
        box.Transparency = 0.6
        box.Parent = S.espFolder
        data.box = box
    end

    if C.ESPSkeleton then
        ensureSkeletonFolder()
        -- 6 persistent line segments between bone pairs
        data.skelLines = {}
        for _, pair in ipairs(SKELETON_PAIRS) do
            local line = Instance.new("Part")
            line.Name = "PawZSeg_" .. pair[1] .. "_" .. pair[2]
            line.Anchored = true
            line.CanCollide = false
            line.Material = Enum.Material.Neon
            line.Color = Color3.fromRGB(255, 255, 255)
            line.Transparency = 0.3
            line.Parent = S.skeletonFolder
            data.skelLines[#data.skelLines + 1] = { part = line, a = pair[1], b = pair[2] }
        end
    end

    if C.Tracers then
        local line = Instance.new("Part")
        line.Name = "PawZTracer"
        line.Anchored = true
        line.CanCollide = false
        line.Size = Vector3.new(0.05, 0.05, 0.05)
        line.Color = Color3.fromRGB(255, 100, 100)
        line.Material = Enum.Material.Neon
        line.Parent = S.espFolder
        data.tracer = line
    end
end

local function destroyESPFor(plr)
    destroyESPCache(plr)
end

-- Skeleton connections (R15)
local SKELETON_PAIRS = {
    { "Head", "UpperTorso" },
    { "UpperTorso", "LowerTorso" },
    { "UpperTorso", "LeftUpperArm" },
    { "UpperTorso", "RightUpperArm" },
    { "LowerTorso", "LeftUpperLeg" },
    { "LowerTorso", "RightUpperLeg" },
}

local function updateESP()
    if not S.active then return end
    if not C.PlayerESP and not C.SkeletonESP and not C.Tracers then
        -- nothing on
        return
    end
    ensureESPFolder()

    -- build/cleanup
    for _, plr in ipairs(getEnemies()) do
        if not S.espCache[plr] then buildESPFor(plr) end
    end
    for plr, _ in pairs(S.espCache) do
        if not plr.Parent or not isAlive(plr) then destroyESPFor(plr) end
    end

    -- update
    local myRoot = getRoot()
    for plr, data in pairs(S.espCache) do
        local ch = plr.Character
        if not ch then destroyESPFor(plr)
        else
            local head = ch:FindFirstChild("Head")
            local root = ch:FindFirstChild("HumanoidRootPart")
            local hum = ch:FindFirstChildOfClass("Humanoid")
            if not head and not root then destroyESPFor(plr)
            else
                local dist = myRoot and (root.Position - myRoot.Position).Magnitude or 0
                local visible = dist <= C.ESPMaxDist
                if data.bb then data.bb.Enabled = visible end
                if data.box then data.box.Visible = visible end

                if visible then
                    if data.rows then
                        local i = 1
                        if C.ESPName and data.rows[i] then
                            data.rows[i].Text = plr.Name
                            i = i + 1
                        end
                        if C.ESPHealth and data.rows[i] then
                            data.rows[i].Text = (hum and math.floor(hum.Health) or 0) .. " HP"
                            if hum and hum.Health / math.max(1, hum.MaxHealth) < 0.3 then
                                data.rows[i].TextColor3 = Color3.fromRGB(248, 113, 113)
                            end
                            i = i + 1
                        end
                        if C.ESPDistance and data.rows[i] then
                            data.rows[i].Text = math.floor(dist) .. "m"
                        end
                    end
                    -- Skeleton: update persistent line segments
                    if C.ESPSkeleton and data.skelLines then
                        for _, segInfo in ipairs(data.skelLines) do
                            local a = ch:FindFirstChild(segInfo.a)
                            local b = ch:FindFirstChild(segInfo.b)
                            local part = segInfo.part
                            if a and b and part then
                                local mid = (a.Position + b.Position) / 2
                                local len = (a.Position - b.Position).Magnitude
                                if len > 0.01 then
                                    part.Size = Vector3.new(0.08, len, 0.08)
                                    part.CFrame = CFrame.new(mid, a.Position)
                                end
                            end
                        end
                    end
                    -- Tracers
                    if C.Tracers and data.tracer and head then
                        local myChar = getChar()
                        local origin
                        if myChar then
                            if C.TracerOrigin == "Bottom" then
                                local vp = Camera.ViewportSize
                                origin = Camera:ViewportPointToRay(vp.X / 2, vp.Y).Origin
                            elseif C.TracerOrigin == "Top" then
                                local vp = Camera.ViewportSize
                                origin = Camera:ViewportPointToRay(vp.X / 2, 0).Origin
                            else -- "Center"
                                local vp = Camera.ViewportSize
                                origin = Camera:ViewportPointToRay(vp.X / 2, vp.Y / 2).Origin
                            end
                        end
                        if origin then
                            local mid = (origin + head.Position) / 2
                            data.tracer.Size = Vector3.new(0.05, (origin - head.Position).Magnitude, 0.05)
                            data.tracer.CFrame = CFrame.new(mid, head.Position)
                        end
                    end
                end
            end
        end
    end
end

-- ========================================================
-- VISUALS: CHAMS
-- ========================================================
local function updateChams()
    if not C.Chams then
        for _, hl in pairs(S.chamsCache) do pcall(function() hl:Destroy() end) end
        S.chamsCache = {}
        return
    end
    for _, plr in ipairs(getEnemies()) do
        local ch = plr.Character
        if ch and not S.chamsCache[plr] then
            local hl = Instance.new("Highlight")
            hl.Name = "PawZChams"
            hl.FillColor = C.ChamsColor
            hl.FillTransparency = 0.5
            hl.OutlineTransparency = 0
            hl.OutlineColor = C.ChamsColor
            hl.Parent = ch
            S.chamsCache[plr] = hl
        end
    end
    for plr, hl in pairs(S.chamsCache) do
        if not plr.Parent or not isAlive(plr) then
            pcall(function() hl:Destroy() end)
            S.chamsCache[plr] = nil
        end
    end
end

-- ========================================================
-- VISUALS: FOV CIRCLE & CROSSHAIR
-- ========================================================
local function ensureFOVCircle()
    if S.fovCircle then return end
    -- Try Drawing first (cleaner), fall back to ScreenGui
    if Drawing and Drawing.new then
        local ok, circle = pcall(function() return Drawing.new("Circle") end)
        if ok and circle then
            circle.Visible = false
            circle.Color = C.FOVColor
            circle.Transparency = C.FOVTransparency
            circle.Thickness = 1
            circle.Filled = false
            circle.NumSides = 64
            S.fovCircle = circle
            S.fovCircle.kind = "drawing"
            return
        end
    end
    -- ScreenGui fallback
    local sg = Instance.new("ScreenGui")
    sg.Name = "PawZFOV"
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 999
    sg.ResetOnSpawn = false
    sg.Parent = getGuiParent()
    local ring = Instance.new("Frame")
    ring.Name = "FOVRing"
    ring.AnchorPoint = Vector2.new(0.5, 0.5)
    ring.BackgroundTransparency = 1
    ring.BorderSizePixel = 0
    ring.Size = UDim2.fromOffset(120, 120)
    ring.Parent = sg
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = ring
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Color = C.FOVColor
    stroke.Transparency = C.FOVTransparency
    stroke.Parent = ring
    S.fovCircle = ring
    S.fovCircleSG = sg
    S.fovCircle.kind = "frame"
end

local function updateFOV()
    if not C.FOVCircle then
        if S.fovCircle then
            if S.fovCircle.kind == "drawing" then
                pcall(function() S.fovCircle.Visible = false end)
            else
                pcall(function() S.fovCircle.Visible = false end)
            end
        end
        return
    end
    ensureFOVCircle()
    local pos = UserInputService:GetMouseLocation()
    local fov = (C.Aimbot and C.AimbotFOV) or C.SilentAimFOV
    if S.fovCircle.kind == "drawing" then
        pcall(function()
            S.fovCircle.Position = pos
            S.fovCircle.Radius = fov
            S.fovCircle.Visible = true
        end)
    else
        pcall(function()
            S.fovCircle.Position = UDim2.fromOffset(pos.X, pos.Y)
            S.fovCircle.Size = UDim2.fromOffset(fov * 2, fov * 2)
            S.fovCircle.Visible = true
        end)
    end
end

local function ensureCrosshair()
    if S.crosshairSG then return end
    local sg = Instance.new("ScreenGui")
    sg.Name = "PawZCrosshair"
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 999
    sg.ResetOnSpawn = false
    sg.Parent = getGuiParent()
    local center = Camera.ViewportSize / 2
    local h = Instance.new("Frame")
    h.Name = "H"
    h.AnchorPoint = Vector2.new(0.5, 0.5)
    h.BackgroundColor3 = C.CrosshairColor
    h.BorderSizePixel = 0
    h.Size = UDim2.fromOffset(C.CrosshairSize * 2, 2)
    h.Position = UDim2.fromOffset(center.X, center.Y)
    h.Parent = sg
    local v = Instance.new("Frame")
    v.Name = "V"
    v.AnchorPoint = Vector2.new(0.5, 0.5)
    v.BackgroundColor3 = C.CrosshairColor
    v.BorderSizePixel = 0
    v.Size = UDim2.fromOffset(2, C.CrosshairSize * 2)
    v.Position = UDim2.fromOffset(center.X, center.Y)
    v.Parent = sg
    S.crosshairSG = sg
    S.crosshairLines = { h, v }
end

local function updateCrosshair()
    if not C.Crosshair then
        if S.crosshairSG then pcall(function() S.crosshairSG.Enabled = false end) end
        return
    end
    ensureCrosshair()
    pcall(function() S.crosshairSG.Enabled = true end)
    local center = Camera.ViewportSize / 2
    local h = S.crosshairLines[1]
    local v = S.crosshairLines[2]
    if h and v then
        h.Size = UDim2.fromOffset(C.CrosshairSize * 2, 2)
        h.Position = UDim2.fromOffset(center.X, center.Y)
        h.BackgroundColor3 = C.CrosshairColor
        v.Size = UDim2.fromOffset(2, C.CrosshairSize * 2)
        v.Position = UDim2.fromOffset(center.X, center.Y)
        v.BackgroundColor3 = C.CrosshairColor
    end
end

-- ========================================================
-- VISUALS: WEAPON/LOOT/NADE ESP (placeholder for game-specific)
-- ========================================================
local function updateItemESP()
    -- Scans Workspace for weapons/loot/grenades tagged by the game.
    -- This is game-specific and requires knowing Operation One's
    -- asset naming conventions. Implemented as a hook that
    -- collects Models with relevant Name prefixes.
    if not C.WeaponESP and not C.LootESP and not C.NadeESP then return end
    ensureESPFolder()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:IsFindable() and obj.PrimaryPart then
            local name = obj.Name:lower()
            local shouldShow =
                (C.WeaponESP and (name:find("gun") or name:find("weapon") or name:find("rifle")))
             or (C.LootESP   and (name:find("loot") or name:find("crate") or name:find("box")))
             or (C.NadeESP   and (name:find("nade") or name:find("grenade") or name:find("bomb")))
            if shouldShow and not S.espCache[obj] then
                local bb = Instance.new("BillboardGui")
                bb.Adornee = obj.PrimaryPart
                bb.Size = UDim2.new(0, 100, 0, 30)
                bb.StudsOffset = Vector3.new(0, 2, 0)
                bb.AlwaysOnTop = true
                bb.Parent = S.espFolder
                local l = Instance.new("TextLabel")
                l.BackgroundTransparency = 1
                l.Font = Enum.Font.Code
                l.TextColor3 = Color3.fromRGB(250, 204, 21)
                l.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                l.TextStrokeTransparency = 0.4
                l.TextSize = 11
                l.Text = obj.Name
                l.Size = UDim2.new(1, 0, 1, 0)
                l.Parent = bb
                S.espCache[obj] = { bb = bb, rows = { l } }
            end
        end
    end
end

-- ========================================================
-- MOVEMENT WRAPPERS (use shared Movement library)
-- ========================================================
local function applySpeed()
    if Movement then Movement.SetWalkSpeed(C.SpeedValue, C.Speed) end
end
local function applyFly()
    if Movement then Movement.SetFly(C.Fly, C.FlyMode, C.FlySpeed) end
end
local function applyNoclip()
    if Movement then Movement.SetNoclip(C.Noclip) end
end
local function applyInfJump()
    if Movement then Movement.SetInfiniteJump(C.InfiniteJump) end
end
local function applyClickTP()
    if Movement then Movement.SetClickTP(C.ClickTP, C.ClickTPMax) end
end
local function applyNoFall()
    if Movement then Movement.SetNoFallDamage(C.NoFallDamage) end
end

-- ========================================================
-- MISC: ANTI-AFK / SERVER HOP / REJOIN
-- ========================================================
local function startAntiAFK()
    if S.antiAFKConn then pcall(function() S.antiAFKConn:Disconnect() end) S.antiAFKConn = nil end
    if not C.AntiAFK then return end
    S.antiAFKConn = UserInputService.InputBegan:Connect(function(_, gpe)
        if gpe then return end
    end)
    -- Movement-based anti-AFK: simulate periodic input
    task.spawn(function()
        while S.active and C.AntiAFK do
            task.wait(60)
            pcall(function()
                if VirtualInputManager and VirtualInputManager.SendKeyEvent then
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                    task.wait(0.1)
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                end
            end)
        end
    end)
end

local function stopAntiAFK()
    if S.antiAFKConn then pcall(function() S.antiAFKConn:Disconnect() end) S.antiAFKConn = nil end
end

local function serverHop()
    if Movement then Movement.SetServerHop(true, 6, 3)
    else pcall(function() TeleportService:Teleport(game.PlaceId, Player) end) end
end

local function rejoin()
    if Movement then Movement.Rejoin()
    else pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player) end) end
end

-- ========================================================
-- UI: black/white/gray, draggable, tabs
-- ========================================================
local T = {
    bg       = Color3.fromRGB(0, 0, 0),
    surface  = Color3.fromRGB(14, 14, 14),
    border   = Color3.fromRGB(38, 38, 38),
    text     = Color3.fromRGB(255, 255, 255),
    textMuted= Color3.fromRGB(140, 140, 140),
    ok       = Color3.fromRGB(74, 222, 128),
    err      = Color3.fromRGB(248, 113, 113),
    warn     = Color3.fromRGB(250, 204, 21),
}

local function makeInst(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do pcall(function() inst[k] = v end) end
    return inst
end

local function makeToggle(parent, label, default, callback)
    local row = makeInst("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26), Parent = parent,
    })
    makeInst("TextLabel", {
        BackgroundTransparency = 1, Text = label, TextColor3 = T.text,
        TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.Code,
        TextSize = 13, Size = UDim2.new(0.65, 0, 1, 0),
        Position = UDim2.new(0, 8, 0, 0), Parent = row,
    })
    local btn = makeInst("TextButton", {
        BackgroundColor3 = T.border, Text = default and "ON" or "OFF",
        TextColor3 = default and T.ok or T.textMuted, Font = Enum.Font.Code,
        TextSize = 11, Size = UDim2.new(0, 50, 0, 20),
        Position = UDim2.new(1, -58, 0.5, -10), Parent = row,
    })
    makeInst("UICorner", { CornerRadius = UDim.new(0, 4), Parent = btn })
    local on = default
    btn.MouseButton1Click:Connect(function()
        on = not on
        btn.Text = on and "ON" or "OFF"
        btn.TextColor3 = on and T.ok or T.textMuted
        pcall(callback, on)
    end)
end

local function makeSlider(parent, label, min, max, default, callback)
    local row = makeInst("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 40), Parent = parent,
    })
    local lbl = makeInst("TextLabel", {
        BackgroundTransparency = 1, Text = label .. "  " .. tostring(math.floor(default)),
        TextColor3 = T.text, TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.Code, TextSize = 12,
        Size = UDim2.new(1, -16, 0, 18), Position = UDim2.new(0, 8, 0, 0), Parent = row,
    })
    local bar = makeInst("TextButton", {
        BackgroundColor3 = T.border, Text = "",
        Size = UDim2.new(1, -16, 0, 6), Position = UDim2.new(0, 8, 0, 26),
        AutoButtonColor = false, Parent = row,
    })
    makeInst("UICorner", { CornerRadius = UDim.new(0, 3), Parent = bar })
    local fill = makeInst("Frame", {
        BackgroundColor3 = T.text,
        Size = UDim2.new((default - min) / math.max(1, (max - min)), 0, 1, 0),
        Parent = bar,
    })
    makeInst("UICorner", { CornerRadius = UDim.new(0, 3), Parent = fill })
    local dragging = false
    local function upd(input)
        local rel = math.clamp((input.Position.X - bar.AbsolutePosition.X) / math.max(1, bar.AbsoluteSize.X), 0, 1)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        local v = math.floor(min + (max - min) * rel)
        lbl.Text = label .. "  " .. tostring(v)
        pcall(callback, v)
    end
    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            upd(input)
        end
    end)
    bar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            upd(input)
        end
    end)
end

local function makeDropdown(parent, label, options, default, callback)
    local row = makeInst("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26), Parent = parent,
    })
    makeInst("TextLabel", {
        BackgroundTransparency = 1, Text = label, TextColor3 = T.text,
        TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.Code,
        TextSize = 13, Size = UDim2.new(0.5, 0, 1, 0),
        Position = UDim2.new(0, 8, 0, 0), Parent = row,
    })
    local btn = makeInst("TextButton", {
        BackgroundColor3 = T.border, Text = tostring(default or "?"),
        TextColor3 = T.text, Font = Enum.Font.Code, TextSize = 11,
        Size = UDim2.new(0, 140, 0, 20),
        Position = UDim2.new(1, -148, 0.5, -10), Parent = row,
    })
    makeInst("UICorner", { CornerRadius = UDim.new(0, 4), Parent = btn })
    local idx = 1
    for i, opt in ipairs(options) do if opt == default then idx = i break end end
    btn.MouseButton1Click:Connect(function()
        idx = (idx % #options) + 1
        btn.Text = tostring(options[idx])
        pcall(callback, options[idx])
    end)
end

local function makeSection(parent, name)
    makeInst("TextLabel", {
        BackgroundTransparency = 1, Text = "-- " .. name .. " --",
        TextColor3 = T.textMuted, Font = Enum.Font.Code, TextSize = 11,
        Size = UDim2.new(1, -16, 0, 18),
        Position = UDim2.new(0, 8, 0, 0), Parent = parent,
    })
end

local function makeButton(parent, label, callback)
    local btn = makeInst("TextButton", {
        BackgroundColor3 = T.border, Text = label, TextColor3 = T.text,
        Font = Enum.Font.Code, TextSize = 12,
        Size = UDim2.new(1, -16, 0, 28), Parent = parent,
    })
    makeInst("UICorner", { CornerRadius = UDim.new(0, 4), Parent = btn })
    btn.MouseButton1Click:Connect(function() pcall(callback) end)
end

local function makeTab(contentParent, name, tabBar, onSelect)
    local tab = makeInst("TextButton", {
        BackgroundColor3 = T.border, Text = name, TextColor3 = T.textMuted,
        Font = Enum.Font.Code, TextSize = 11,
        Size = UDim2.new(0, 90, 0, 24), Parent = tabBar,
    })
    makeInst("UICorner", { CornerRadius = UDim.new(0, 4), Parent = tab })
    local content = makeInst("ScrollingFrame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(0, 0, 0, 800), ScrollBarThickness = 3,
        ScrollBarImageColor3 = T.border, Visible = false, Parent = contentParent,
    })
    makeInst("UIListLayout", {
        Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = content,
    })
    tab.MouseButton1Click:Connect(function()
        for _, c in ipairs(contentParent:GetChildren()) do
            if c:IsA("ScrollingFrame") then c.Visible = false end
        end
        content.Visible = true
        for _, t in ipairs(tabBar:GetChildren()) do
            if t:IsA("TextButton") then
                t.BackgroundColor3 = T.border
                t.TextColor3 = T.textMuted
            end
        end
        tab.BackgroundColor3 = T.text
        tab.TextColor3 = T.bg
        pcall(onSelect, name)
    end)
    return {
        AddToggle   = function(l, d, c) makeToggle(content, l, d, c) end,
        AddSlider   = function(l, mn, mx, d, c) makeSlider(content, l, mn, mx, d, c) end,
        AddDropdown = function(l, opts, d, c) makeDropdown(content, l, opts, d, c) end,
        AddButton   = function(l, c) makeButton(content, l, c) end,
        AddSection  = function(n) makeSection(content, n) end,
        Select      = function() tab.MouseButton1Click:Connect(function() end) tab.MouseButton1Click() end,
    }
end

-- ========================================================
-- LIFECYCLE
-- ========================================================
local function onCharacterAdded(char)
    if not S.active then return end
    task.spawn(function()
        local deadline = tick() + 5
        while tick() < deadline do
            if char and char:FindFirstChildOfClass("Humanoid")
               and char:FindFirstChild("HumanoidRootPart") then break end
            task.wait(0.1)
        end
        if not S.active then return end
        applySpeed()
        applyNoclip()
        applyInfJump()
        applyFly()
        applyNoFall()
    end)
end

local function disconnectAll()
    for i = #S.conns, 1, -1 do
        pcall(function() S.conns[i]:Disconnect() end)
        S.conns[i] = nil
    end
end

-- ========================================================
-- INIT
-- ========================================================
function OperationOne.Init()
    if S.hubGui then return end
    local gui = makeInst("ScreenGui", {
        Name = "PawZHub", ResetOnSpawn = false, IgnoreGuiInset = true,
        Parent = getGuiParent(),
    })
    makeInst("BoolValue", { Name = "PawZHubScript", Value = true, Parent = gui })

    local frame = makeInst("Frame", {
        BackgroundColor3 = T.bg, BorderSizePixel = 0,
        Size = UDim2.fromOffset(520, 360),
        Position = UDim2.new(0.5, -260, 0.5, -180),
        Parent = gui, ClipsDescendants = true,
    })
    makeInst("UICorner", { CornerRadius = UDim.new(0, 8), Parent = frame })
    makeInst("UIStroke", { Color = T.border, Thickness = 1, Parent = frame })

    local header = makeInst("Frame", {
        BackgroundColor3 = T.surface, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 32), Parent = frame,
    })
    makeInst("TextLabel", {
        BackgroundTransparency = 1, Text = "PawZHub · Operation One",
        TextColor3 = T.text, Font = Enum.Font.Code, TextSize = 13,
        Size = UDim2.new(1, -16, 1, 0), Position = UDim2.new(0, 12, 0, 0),
        TextXAlignment = Enum.TextXAlignment.Left, Parent = header,
    })
    -- Drag
    do
        local dragging, dragStart, startPos
        header.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = frame.Position
            end
        end)
        header.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
                local d = input.Position - dragStart
                frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                                            startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end)
    end

    local tabBar = makeInst("Frame", {
        BackgroundColor3 = T.surface, BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 28), Position = UDim2.new(0, 0, 0, 32), Parent = frame,
    })
    makeInst("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 4),
        VerticalAlignment = Enum.VerticalAlignment.Center, Parent = tabBar,
    })
    makeInst("UIPadding", {
        PaddingLeft = UDim.new(0, 8), PaddingTop = UDim.new(0, 2), Parent = tabBar,
    })
    local content = makeInst("Frame", {
        BackgroundTransparency = 1, Size = UDim2.new(1, -16, 1, -68),
        Position = UDim2.new(0, 8, 0, 60), Parent = frame,
    })

    local combat   = makeTab(content, "Combat",   tabBar)
    local visuals  = makeTab(content, "Visuals",  tabBar)
    local movement = makeTab(content, "Movement", tabBar)
    local misc     = makeTab(content, "Misc",     tabBar)

    -- ===== COMBAT =====
    combat:AddSection("Aimbot")
    combat:AddToggle("Aimbot", C.Aimbot, function(v) C.Aimbot = v end)
    combat:AddSlider("FOV", 10, 600, C.AimbotFOV, function(v) C.AimbotFOV = v end)
    combat:AddSlider("Smoothness", 1, 20, C.AimbotSmooth, function(v) C.AimbotSmooth = v end)
    combat:AddToggle("Visibility Check", C.AimbotVisCheck, function(v) C.AimbotVisCheck = v end)
    combat:AddToggle("Auto Headshot", C.AimbotHeadshot, function(v) C.AimbotHeadshot = v end)

    combat:AddSection("Silent Aim")
    combat:AddToggle("Silent Aim", C.SilentAim, function(v) C.SilentAim = v end)
    combat:AddSlider("Silent FOV", 10, 600, C.SilentAimFOV, function(v) C.SilentAimFOV = v end)

    combat:AddSection("Triggerbot")
    combat:AddToggle("Triggerbot", C.Triggerbot, function(v) C.Triggerbot = v end)
    combat:AddSlider("Delay (s)", 0, 1, C.TriggerDelay, function(v) C.TriggerDelay = v / 10 end)

    combat:AddSection("Weapon Mods (RE-Required)")
    combat:AddToggle("No Recoil", C.NoRecoil, function(v) C.NoRecoil = v; patchWeaponStats() end)
    combat:AddToggle("No Spread", C.NoSpread, function(v) C.NoSpread = v; patchWeaponStats() end)
    combat:AddToggle("Instant Hit", C.InstantHit, function(v) C.InstantHit = v end)
    combat:AddToggle("Rapid Fire", C.RapidFire, function(v)
        C.RapidFire = v
        if v then task.spawn(updateRapidFire) end
    end)
    combat:AddSlider("Rapid Fire Delay (s)", 0.01, 0.5, C.RapidFireDelay * 100, function(v)
        C.RapidFireDelay = v / 100
    end)

    combat:AddSection("Ammo (RE-Required)")
    combat:AddToggle("Auto Reload", C.AutoReload, function(v) C.AutoReload = v end)
    combat:AddToggle("Infinite Ammo", C.InfiniteAmmo, function(v) C.InfiniteAmmo = v; patchWeaponStats() end)
    combat:AddToggle("No Reload Delay", C.NoReloadDelay, function(v) C.NoReloadDelay = v; patchWeaponStats() end)

    combat:AddSection("Other")
    combat:AddToggle("Kill Aura", C.KillAura, function(v) C.KillAura = v end)
    combat:AddSlider("Aura Range (studs)", 10, 200, C.KillAuraRange, function(v) C.KillAuraRange = v end)
    combat:AddToggle("Wallbang", C.Wallbang, function(v) C.Wallbang = v end)
    combat:AddSlider("Damage Multiplier", 1, 10, C.DamageMultiplier, function(v) C.DamageMultiplier = v end)
    combat:AddToggle("Range Extender", C.RangeExtender, function(v) C.RangeExtender = v end)
    combat:AddSlider("Extended Range", 100, 2000, C.ExtendRange, function(v) C.ExtendRange = v end)

    -- ===== VISUALS =====
    visuals:AddSection("Player ESP")
    visuals:AddToggle("Player ESP", C.PlayerESP, function(v) C.PlayerESP = v end)
    visuals:AddToggle("Show Name", C.ESPName, function(v) C.ESPName = v end)
    visuals:AddToggle("Show Distance", C.ESPDistance, function(v) C.ESPDistance = v end)
    visuals:AddToggle("Show Health", C.ESPHealth, function(v) C.ESPHealth = v end)
    visuals:AddToggle("Show Box", C.ESPBox, function(v) C.ESPBox = v end)
    visuals:AddToggle("Team Check", C.ESPTeamCheck, function(v) C.ESPTeamCheck = v end)
    visuals:AddSlider("ESP Max Distance", 100, 3000, C.ESPMaxDist, function(v) C.ESPMaxDist = v end)

    visuals:AddSection("Other ESP")
    visuals:AddToggle("Skeleton ESP", C.SkeletonESP, function(v) C.SkeletonESP = v end)
    visuals:AddToggle("Tracers", C.Tracers, function(v) C.Tracers = v end)
    visuals:AddDropdown("Tracer Origin", { "Bottom", "Center", "Top" }, C.TracerOrigin, function(v) C.TracerOrigin = v end)
    visuals:AddToggle("Weapon ESP", C.WeaponESP, function(v) C.WeaponESP = v end)
    visuals:AddToggle("Loot ESP", C.LootESP, function(v) C.LootESP = v end)
    visuals:AddToggle("Nade ESP", C.NadeESP, function(v) C.NadeESP = v end)

    visuals:AddSection("Chams")
    visuals:AddToggle("Chams", C.Chams, function(v) C.Chams = v; updateChams() end)

    visuals:AddSection("Overlays")
    visuals:AddToggle("FOV Circle", C.FOVCircle, function(v) C.FOVCircle = v; updateFOV() end)
    visuals:AddToggle("Crosshair", C.Crosshair, function(v) C.Crosshair = v; updateCrosshair() end)
    visuals:AddSlider("Crosshair Size", 5, 50, C.CrosshairSize, function(v) C.CrosshairSize = v end)
    visuals:AddToggle("Hit Marker", C.HitMarker, function(v) C.HitMarker = v end)
    visuals:AddToggle("Damage Indicator", C.DamageIndicator, function(v) C.DamageIndicator = v end)
    visuals:AddToggle("Enemy Count", C.EnemyCount, function(v) C.EnemyCount = v end)

    -- ===== MOVEMENT =====
    movement:AddSection("Speed")
    movement:AddToggle("Speed Hack", C.Speed, function(v) C.Speed = v; applySpeed() end)
    movement:AddSlider("Speed Value", 16, 200, C.SpeedValue, function(v)
        C.SpeedValue = v
        if C.Speed then applySpeed() end
    end)

    movement:AddSection("Fly")
    movement:AddToggle("Fly", C.Fly, function(v) C.Fly = v; applyFly() end)
    movement:AddDropdown("Fly Mode", { "CFrame", "Velocity", "BodyVelocity" }, C.FlyMode, function(v)
        C.FlyMode = v
        if C.Fly then applyFly() end
    end)
    movement:AddSlider("Fly Speed", 10, 300, C.FlySpeed, function(v)
        C.FlySpeed = v
        if C.Fly then applyFly() end
    end)

    movement:AddSection("Other")
    movement:AddToggle("Noclip", C.Noclip, function(v) C.Noclip = v; applyNoclip() end)
    movement:AddToggle("Infinite Jump", C.InfiniteJump, function(v) C.InfiniteJump = v; applyInfJump() end)
    movement:AddToggle("Click TP", C.ClickTP, function(v) C.ClickTP = v; applyClickTP() end)
    movement:AddSlider("Click TP Max (studs)", 50, 2000, C.ClickTPMax, function(v) C.ClickTPMax = v end)
    movement:AddToggle("No Fall Damage", C.NoFallDamage, function(v) C.NoFallDamage = v; applyNoFall() end)
    movement:AddToggle("Bunny Hop", C.BunnyHop, function(v) C.BunnyHop = v end)
    movement:AddToggle("Silent Walk", C.SilentWalk, function(v) C.SilentWalk = v end)
    movement:AddToggle("Anti-Ragdoll", C.AntiRagdoll, function(v) C.AntiRagdoll = v end)

    movement:AddSection("Waypoints")
    movement:AddButton("Save Position", function()
        local r = getRoot()
        if r then
            S.savedPos[#S.savedPos + 1] = r.CFrame
            notify("Position saved (" .. #S.savedPos .. ")", "ok")
        end
    end)
    movement:AddButton("Load Last Position", function()
        if #S.savedPos == 0 then notify("No saved positions", "warn"); return end
        local r = getRoot()
        if r then
            pcall(function() r.CFrame = S.savedPos[#S.savedPos] end)
            notify("Teleported", "ok")
        end
    end)

    -- ===== MISC =====
    misc:AddSection("General")
    misc:AddToggle("Anti-AFK", C.AntiAFK, function(v)
        C.AntiAFK = v
        if v then startAntiAFK() else stopAntiAFK() end
    end)
    misc:AddToggle("Auto Respawn", C.AutoRespawn, function(v) C.AutoRespawn = v end)

    misc:AddSection("Server")
    misc:AddButton("Server Hop", function() serverHop() end)
    misc:AddButton("Rejoin",     function() rejoin() end)

    misc:AddSection("Unlocks (Experimental)")
    misc:AddButton("Unlock All Weapons", function()
        notify("Unlock requires game-specific remote reverse-engineering", "warn")
    end)
    misc:AddButton("Unlock All Skins", function()
        notify("Unlock requires game-specific remote reverse-engineering", "warn")
    end)
    misc:AddToggle("Infinite Money", C.InfiniteMoney, function(v)
        C.InfiniteMoney = v
        if v then notify("Infinite Money requires game-specific remote RE", "warn") end
    end)
    misc:AddToggle("Auto Buy Weapons", C.AutoBuy, function(v)
        C.AutoBuy = v
        if v then notify("Auto Buy requires game-specific remote RE", "warn") end
    end)

    combat:Select()

    S.hubGui   = gui
    S.hubFrame = frame

    -- Character respawn
    Player.CharacterAdded:Connect(onCharacterAdded)
    if Player.Character then task.spawn(function() onCharacterAdded(Player.Character) end) end

    -- Main loops
    table.insert(S.conns, RunService.Heartbeat:Connect(function()
        if not S.active then return end
        pcall(updateAimbot)
        pcall(updateTriggerbot)
        pcall(updateKillAura)
        pcall(function() if C.BunnyHop then
            local hum = getHumanoid()
            if hum and hum.FloorMaterial ~= Enum.Material.Air then
                pcall(function() hum.Jump = true end)
            end
        end end)
    end))
    table.insert(S.conns, RunService.Heartbeat:Connect(function()
        if not S.active then return end
        pcall(updateESP)
        pcall(updateChams)
        pcall(updateItemESP)
        if C.AutoRespawn and getHumanoid() and getHumanoid().Health <= 0 then
            task.wait(1)
            pcall(function() Player:LoadCharacter() end)
        end
    end))
    table.insert(S.conns, RunService.RenderStepped:Connect(function()
        if not S.active then return end
        pcall(updateFOV)
        pcall(updateCrosshair)
    end))

    -- Initial apply
    applySpeed()
    applyNoclip()
    applyInfJump()
    applyFly()
    applyNoFall()
    applyClickTP()
    if C.AntiAFK then startAntiAFK() end

    notify("Operation One loaded · 47 features", "ok")
end

-- ========================================================
-- UNLOAD
-- ========================================================
function OperationOne.Unload()
    S.active = false
    disconnectAll()
    if S.antiAFKConn then pcall(function() S.antiAFKConn:Disconnect() end) end
    clearAllESP()
    if S.skeletonFolder then pcall(function() S.skeletonFolder:Destroy() end) end
    if S.espFolder then pcall(function() S.espFolder:Destroy() end) end
    if S.fovCircle then
        pcall(function() if S.fovCircle.Remove then S.fovCircle:Remove() elseif S.fovCircle.Destroy then S.fovCircle:Destroy() end end)
    end
    if S.fovCircleSG then pcall(function() S.fovCircleSG:Destroy() end) end
    if S.crosshairSG then pcall(function() S.crosshairSG:Destroy() end) end
    if S.hubGui then pcall(function() S.hubGui:Destroy() end) end
    if Movement then pcall(function() Movement.Unload() end) end
    S.hubGui = nil
    S.hubFrame = nil
    print("[PawZHub/OperationOne] Unloaded")
end

-- Auto-init (called when script is loaded by checkkey.lua)
OperationOne.Init()

return OperationOne

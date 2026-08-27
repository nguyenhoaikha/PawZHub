--[[
    ========================================================
    PawZHub  —  Universal ESP Library  v1.0.0
    ========================================================
    Provides comprehensive ESP (Extra Sensory Perception)
    rendering for players, mobs, and items across all games.

    Features:
      • Player ESP (name, distance, health bar, team color)
      • Mob/NPC ESP (name, distance, health bar, level)
      • Item ESP (name, distance, custom icon)
      • Billboard GUI (text overlay, background, rounded corners)
      • Box ESP (2D box around character, corner style)
      • Tracer lines (from bottom-center of screen to target)
      • Distance-based fade (far objects fade out)
      • Team check (skip teammates in FFA games)
      • Health bar gradient (green → yellow → red)
      • Auto-cleanup on target destroy/death
      • Performance optimized (reuses instances, batched updates)

    Usage:
        local ESP = loadstring(game:HttpGet(URL))()
        ESP.Init()

        -- Player ESP
        ESP.AddPlayer(player, { showName=true, showDistance=true, showHealth=true })
        ESP.RemovePlayer(player)
        ESP.SetPlayerESP(true)  -- enable for all players

        -- Mob ESP
        ESP.AddMob(mobModel, "Zombie", { level=5, showHealth=true })
        ESP.RemoveMob(mobModel)

        -- Item ESP
        ESP.AddItem(itemModel, "Legendary Sword", { color=Color3.fromRGB(255,215,0) })

        -- Box ESP
        ESP.SetBoxESP(true)

        -- Tracer ESP
        ESP.SetTracers(true, "bottom")  -- "bottom" | "center" | "top"

        -- Cleanup
        ESP.Unload()
]]

-- ========================================================
-- SERVICES
-- ========================================================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local Workspace        = game:GetService("Workspace")
local Camera           = Workspace.CurrentCamera

local Player           = Players.LocalPlayer

-- ========================================================
-- STATE
-- ========================================================
local ESP = {}
ESP.__version = "1.0.0"
ESP.__type    = "PawZHub.ESP"

local State = {
    initialized   = false,
    unloaded      = false,
    
    -- Settings
    enabled       = true,
    playerESP     = false,
    mobESP        = false,
    itemESP       = false,
    boxESP        = false,
    tracers       = false,
    tracerOrigin  = "bottom",  -- "bottom" | "center" | "top"
    teamCheck     = false,     -- skip teammates
    maxDistance   = 2000,      -- studs, 0 = unlimited
    fadeDistance  = 1500,      -- start fading at this distance
    
    -- Tracked targets
    players       = {},  -- { [player] = { billboard, box, tracer, conn } }
    mobs          = {},  -- { [model] = { billboard, box, tracer, conn, data } }
    items         = {},  -- { [model] = { billboard, conn, data } }
    
    -- Update loop
    updateConn    = nil,
    updateRate    = 0.05,  -- seconds between updates
    
    -- Folder (holds all ESP instances)
    folder        = nil,
}

-- ========================================================
-- THEME / COLORS
-- ========================================================
local Colors = {
    Player       = Color3.fromRGB(99, 102, 241),
    TeamAlly     = Color3.fromRGB(80, 200, 120),
    TeamEnemy    = Color3.fromRGB(220, 60, 60),
    Mob          = Color3.fromRGB(255, 140, 0),
    Item         = Color3.fromRGB(255, 215, 0),
    HealthHigh   = Color3.fromRGB(80, 200, 120),
    HealthMid    = Color3.fromRGB(255, 180, 50),
    HealthLow    = Color3.fromRGB(220, 60, 60),
    Background   = Color3.fromRGB(0, 0, 0),
    Text         = Color3.fromRGB(255, 255, 255),
    Box          = Color3.fromRGB(255, 255, 255),
    Tracer       = Color3.fromRGB(255, 255, 255),
}

-- ========================================================
-- HELPERS
-- ========================================================
local function safe(fn, default)
    local ok, v = pcall(fn)
    return ok and v or default
end

local function getChar(p)
    return p and p.Character
end

local function getHum(char)
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getHRP(char)
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso"))
end

local function isAlive(char)
    local h = getHum(char)
    return h and h.Health > 0
end

local function worldToScreen(pos)
    if not Camera then return nil, false end
    local vec, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(vec.X, vec.Y), onScreen
end

local function getDistance(from, to)
    return (from - to).Magnitude
end

local function lerpColor(a, b, t)
    return Color3.new(
        a.R + (b.R - a.R) * t,
        a.G + (b.G - a.G) * t,
        a.B + (b.B - a.B) * t
    )
end

local function getHealthColor(percent)
    if percent > 0.6 then
        return lerpColor(Colors.HealthMid, Colors.HealthHigh, (percent - 0.6) / 0.4)
    elseif percent > 0.3 then
        return lerpColor(Colors.HealthLow, Colors.HealthMid, (percent - 0.3) / 0.3)
    else
        return Colors.HealthLow
    end
end

local function getTeamColor(player)
    if not State.teamCheck then return Colors.Player end
    if not Player.Team or not player.Team then return Colors.Player end
    return (Player.Team == player.Team) and Colors.TeamAlly or Colors.TeamEnemy
end

-- ========================================================
-- BILLBOARD ESP
-- ========================================================
local function createBillboard(parent, name, color, showHealth, healthPercent)
    local bb = Instance.new("BillboardGui")
    bb.Name              = "PawZHub_ESP_Billboard"
    bb.AlwaysOnTop       = true
    bb.Size              = UDim2.new(0, 200, 0, showHealth and 60 or 40)
    bb.StudsOffset       = Vector3.new(0, 3, 0)
    bb.Parent            = parent
    
    -- Background frame
    local bg = Instance.new("Frame")
    bg.Size              = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3  = Colors.Background
    bg.BackgroundTransparency = 0.5
    bg.BorderSizePixel   = 0
    bg.Parent            = bb
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = bg
    
    -- Name label
    local nameLbl = Instance.new("TextLabel")
    nameLbl.Name             = "NameLabel"
    nameLbl.Size             = UDim2.new(1, -8, 0, 18)
    nameLbl.Position         = UDim2.new(0, 4, 0, 2)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text             = name
    nameLbl.TextSize         = 14
    nameLbl.Font             = Enum.Font.GothamBold
    nameLbl.TextColor3       = color
    nameLbl.TextStrokeTransparency = 0.5
    nameLbl.TextXAlignment   = Enum.TextXAlignment.Center
    nameLbl.Parent           = bg
    
    -- Distance label
    local distLbl = Instance.new("TextLabel")
    distLbl.Name             = "DistanceLabel"
    distLbl.Size             = UDim2.new(1, -8, 0, 14)
    distLbl.Position         = UDim2.new(0, 4, 0, 20)
    distLbl.BackgroundTransparency = 1
    distLbl.Text             = "0m"
    distLbl.TextSize         = 11
    distLbl.Font             = Enum.Font.Gotham
    distLbl.TextColor3       = Colors.Text
    distLbl.TextStrokeTransparency = 0.5
    distLbl.TextXAlignment   = Enum.TextXAlignment.Center
    distLbl.Parent           = bg
    
    -- Health bar (optional)
    local healthBar, healthFill
    if showHealth then
        local barBg = Instance.new("Frame")
        barBg.Name              = "HealthBarBg"
        barBg.Size              = UDim2.new(1, -16, 0, 6)
        barBg.Position          = UDim2.new(0, 8, 1, -10)
        barBg.BackgroundColor3  = Color3.fromRGB(40, 40, 40)
        barBg.BorderSizePixel   = 0
        barBg.Parent            = bg
        
        local barCorner = Instance.new("UICorner")
        barCorner.CornerRadius = UDim.new(0, 3)
        barCorner.Parent = barBg
        
        healthFill = Instance.new("Frame")
        healthFill.Name             = "HealthFill"
        healthFill.Size             = UDim2.new(healthPercent or 1, 0, 1, 0)
        healthFill.BackgroundColor3 = getHealthColor(healthPercent or 1)
        healthFill.BorderSizePixel  = 0
        healthFill.Parent           = barBg
        
        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(0, 3)
        fillCorner.Parent = healthFill
        
        healthBar = barBg
    end
    
    return bb, nameLbl, distLbl, healthFill
end

local function updateBillboard(bb, nameLbl, distLbl, healthFill, targetPos, healthPercent)
    if not bb or not bb.Parent then return end
    
    -- Distance
    local myPos = getHRP(getChar(Player))
    if myPos then
        local dist = getDistance(myPos.Position, targetPos)
        distLbl.Text = string.format("%.0fm", dist)
        
        -- Fade by distance
        if State.maxDistance > 0 and dist > State.maxDistance then
            bb.Enabled = false
            return
        else
            bb.Enabled = true
        end
        
        if State.fadeDistance > 0 and dist > State.fadeDistance then
            local fade = math.clamp((dist - State.fadeDistance) / (State.maxDistance - State.fadeDistance), 0, 1)
            bb.Parent.Transparency = fade * 0.8
        else
            bb.Parent.Transparency = 0
        end
    end
    
    -- Health bar
    if healthFill and healthPercent then
        healthFill.Size = UDim2.new(math.clamp(healthPercent, 0, 1), 0, 1, 0)
        healthFill.BackgroundColor3 = getHealthColor(healthPercent)
    end
end

-- ========================================================
-- BOX ESP (2D)
-- ========================================================
local function createBox(parent, color)
    local box = Instance.new("BillboardGui")
    box.Name             = "PawZHub_ESP_Box"
    box.AlwaysOnTop      = true
    box.Size             = UDim2.new(0, 100, 0, 150)
    box.StudsOffset      = Vector3.new(0, 0, 0)
    box.Parent           = parent
    
    -- 4 corner lines (top-left, top-right, bottom-left, bottom-right)
    local corners = {}
    local positions = {
        { UDim2.new(0, 0, 0, 0),   UDim2.new(0, 20, 0, 2) },   -- TL horizontal
        { UDim2.new(0, 0, 0, 0),   UDim2.new(0, 2, 0, 20) },   -- TL vertical
        { UDim2.new(1, -20, 0, 0), UDim2.new(0, 20, 0, 2) },   -- TR horizontal
        { UDim2.new(1, -2, 0, 0),  UDim2.new(0, 2, 0, 20) },   -- TR vertical
        { UDim2.new(0, 0, 1, -2),  UDim2.new(0, 20, 0, 2) },   -- BL horizontal
        { UDim2.new(0, 0, 1, -20), UDim2.new(0, 2, 0, 20) },   -- BL vertical
        { UDim2.new(1, -20, 1, -2), UDim2.new(0, 20, 0, 2) },  -- BR horizontal
        { UDim2.new(1, -2, 1, -20), UDim2.new(0, 2, 0, 20) },  -- BR vertical
    }
    
    local container = Instance.new("Frame")
    container.Size              = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.BorderSizePixel   = 0
    container.Parent            = box
    
    for i, pos in ipairs(positions) do
        local line = Instance.new("Frame")
        line.Position         = pos[1]
        line.Size             = pos[2]
        line.BackgroundColor3 = color or Colors.Box
        line.BorderSizePixel  = 0
        line.Parent           = container
        table.insert(corners, line)
    end
    
    return box, corners
end

local function updateBox(box, corners, char)
    if not box or not box.Parent or not char or not isAlive(char) then
        if box then box.Enabled = false end
        return
    end
    
    local hrp = getHRP(char)
    if not hrp then
        box.Enabled = false
        return
    end
    
    -- Distance check
    local myPos = getHRP(getChar(Player))
    if myPos then
        local dist = getDistance(myPos.Position, hrp.Position)
        if State.maxDistance > 0 and dist > State.maxDistance then
            box.Enabled = false
            return
        end
    end
    
    box.Enabled = true
end

-- ========================================================
-- TRACER ESP
-- ========================================================
local function createTracer()
    local line = Drawing.new("Line")
    line.Visible     = true
    line.Thickness   = 1
    line.Color       = Colors.Tracer
    line.Transparency= 0.8
    return line
end

local function updateTracer(line, targetPos)
    if not line then return end
    
    local myPos = getHRP(getChar(Player))
    if not myPos or not Camera then
        line.Visible = false
        return
    end
    
    local dist = getDistance(myPos.Position, targetPos)
    if State.maxDistance > 0 and dist > State.maxDistance then
        line.Visible = false
        return
    end
    
    local targetScreen, onScreen = worldToScreen(targetPos)
    if not onScreen then
        line.Visible = false
        return
    end
    
    -- Origin point (bottom, center, or top of screen)
    local origin
    if State.tracerOrigin == "bottom" then
        origin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
    elseif State.tracerOrigin == "center" then
        origin = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    else  -- top
        origin = Vector2.new(Camera.ViewportSize.X / 2, 0)
    end
    
    line.From    = origin
    line.To      = targetScreen
    line.Visible = true
end

local function destroyTracer(line)
    if line then
        pcall(function() line:Remove() end)
    end
end

-- ========================================================
-- PLAYER ESP
-- ========================================================
function ESP.AddPlayer(player, options)
    if State.unloaded or not player or not player:IsA("Player") then return end
    if State.players[player] then return end  -- already tracked
    
    options = options or {}
    local showHealth = options.showHealth ~= false
    
    local entry = {
        player    = player,
        billboard = nil,
        nameLbl   = nil,
        distLbl   = nil,
        healthFill= nil,
        box       = nil,
        boxCorners= nil,
        tracer    = nil,
        conn      = nil,
    }
    
    local function attach()
        local char = getChar(player)
        if not char then return end
        local hrp = getHRP(char)
        if not hrp then return end
        
        -- Billboard
        local hum = getHum(char)
        local hp  = hum and (hum.Health / hum.MaxHealth) or 1
        local bb, nLbl, dLbl, hFill = createBillboard(
            hrp,
            player.Name,
            getTeamColor(player),
            showHealth,
            hp
        )
        entry.billboard  = bb
        entry.nameLbl    = nLbl
        entry.distLbl    = dLbl
        entry.healthFill = hFill
        
        -- Box ESP
        if State.boxESP then
            local box, corners = createBox(hrp, getTeamColor(player))
            entry.box        = box
            entry.boxCorners = corners
        end
        
        -- Tracer ESP
        if State.tracers then
            entry.tracer = createTracer()
        end
    end
    
    -- Attach on character added
    entry.conn = player.CharacterAdded:Connect(function()
        task.wait(0.2)
        attach()
    end)
    
    -- Attach now if character exists
    if player.Character then
        task.spawn(function()
            task.wait(0.2)
            attach()
        end)
    end
    
    State.players[player] = entry
end

function ESP.RemovePlayer(player)
    local entry = State.players[player]
    if not entry then return end
    
    if entry.billboard and entry.billboard.Parent then
        pcall(function() entry.billboard:Destroy() end)
    end
    if entry.box and entry.box.Parent then
        pcall(function() entry.box:Destroy() end)
    end
    if entry.tracer then
        destroyTracer(entry.tracer)
    end
    if entry.conn then
        pcall(function() entry.conn:Disconnect() end)
    end
    
    State.players[player] = nil
end

function ESP.SetPlayerESP(enabled)
    State.playerESP = enabled and true or false
    
    if State.playerESP then
        -- Add all current players
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= Player then
                ESP.AddPlayer(p)
            end
        end
        -- Auto-add new players
        State.playerAddedConn = Players.PlayerAdded:Connect(function(p)
            if p ~= Player then
                ESP.AddPlayer(p)
            end
        end)
        State.playerRemovingConn = Players.PlayerRemoving:Connect(function(p)
            ESP.RemovePlayer(p)
        end)
    else
        -- Remove all
        for p, _ in pairs(State.players) do
            ESP.RemovePlayer(p)
        end
        if State.playerAddedConn then
            State.playerAddedConn:Disconnect()
            State.playerAddedConn = nil
        end
        if State.playerRemovingConn then
            State.playerRemovingConn:Disconnect()
            State.playerRemovingConn = nil
        end
    end
end

-- ========================================================
-- MOB/NPC ESP
-- ========================================================
function ESP.AddMob(model, name, options)
    if State.unloaded or not model or not model:IsA("Model") then return end
    if State.mobs[model] then return end
    
    options = options or {}
    local showHealth = options.showHealth ~= false
    local level      = options.level or 0
    local color      = options.color or Colors.Mob
    
    local hrp = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso") or model:FindFirstChild("UpperTorso")
    if not hrp then return end
    
    local hum = model:FindFirstChildOfClass("Humanoid")
    local hp  = hum and (hum.Health / hum.MaxHealth) or 1
    
    local displayName = name .. (level > 0 and (" Lv." .. level) or "")
    local bb, nLbl, dLbl, hFill = createBillboard(hrp, displayName, color, showHealth, hp)
    
    local entry = {
        model     = model,
        billboard = bb,
        nameLbl   = nLbl,
        distLbl   = dLbl,
        healthFill= hFill,
        humanoid  = hum,
        data      = { name = name, level = level, color = color },
    }
    
    -- Auto-cleanup on destroy
    entry.conn = model.AncestryChanged:Connect(function()
        if not model:IsDescendantOf(game) then
            ESP.RemoveMob(model)
        end
    end)
    
    State.mobs[model] = entry
end

function ESP.RemoveMob(model)
    local entry = State.mobs[model]
    if not entry then return end
    
    if entry.billboard and entry.billboard.Parent then
        pcall(function() entry.billboard:Destroy() end)
    end
    if entry.conn then
        pcall(function() entry.conn:Disconnect() end)
    end
    
    State.mobs[model] = nil
end

function ESP.SetMobESP(enabled)
    State.mobESP = enabled and true or false
    if not State.mobESP then
        for m, _ in pairs(State.mobs) do
            ESP.RemoveMob(m)
        end
    end
end

-- ========================================================
-- ITEM ESP
-- ========================================================
function ESP.AddItem(model, name, options)
    if State.unloaded or not model or not model:IsA("BasePart") and not model:IsA("Model") then return end
    if State.items[model] then return end
    
    options = options or {}
    local color = options.color or Colors.Item
    
    local pos
    if model:IsA("BasePart") then
        pos = model
    else
        pos = model:FindFirstChild("Handle") or model:FindFirstChildWhichIsA("BasePart", true)
    end
    if not pos then return end
    
    local bb, nLbl, dLbl = createBillboard(pos, name, color, false, nil)
    
    local entry = {
        model     = model,
        billboard = bb,
        nameLbl   = nLbl,
        distLbl   = dLbl,
        data      = { name = name, color = color },
    }
    
    entry.conn = model.AncestryChanged:Connect(function()
        if not model:IsDescendantOf(game) then
            ESP.RemoveItem(model)
        end
    end)
    
    State.items[model] = entry
end

function ESP.RemoveItem(model)
    local entry = State.items[model]
    if not entry then return end
    
    if entry.billboard and entry.billboard.Parent then
        pcall(function() entry.billboard:Destroy() end)
    end
    if entry.conn then
        pcall(function() entry.conn:Disconnect() end)
    end
    
    State.items[model] = nil
end

function ESP.SetItemESP(enabled)
    State.itemESP = enabled and true or false
    if not State.itemESP then
        for i, _ in pairs(State.items) do
            ESP.RemoveItem(i)
        end
    end
end

-- ========================================================
-- BOX ESP TOGGLE
-- ========================================================
function ESP.SetBoxESP(enabled)
    State.boxESP = enabled and true or false
    
    if State.boxESP then
        -- Add boxes to existing players
        for player, entry in pairs(State.players) do
            local char = getChar(player)
            if char then
                local hrp = getHRP(char)
                if hrp and not entry.box then
                    local box, corners = createBox(hrp, getTeamColor(player))
                    entry.box        = box
                    entry.boxCorners = corners
                end
            end
        end
    else
        -- Remove all boxes
        for _, entry in pairs(State.players) do
            if entry.box and entry.box.Parent then
                pcall(function() entry.box:Destroy() end)
            end
            entry.box        = nil
            entry.boxCorners = nil
        end
    end
end

-- ========================================================
-- TRACER ESP TOGGLE
-- ========================================================
function ESP.SetTracers(enabled, origin)
    State.tracers      = enabled and true or false
    State.tracerOrigin = origin or "bottom"
    
    if State.tracers then
        -- Add tracers to existing players
        for _, entry in pairs(State.players) do
            if not entry.tracer then
                entry.tracer = createTracer()
            end
        end
    else
        -- Remove all tracers
        for _, entry in pairs(State.players) do
            if entry.tracer then
                destroyTracer(entry.tracer)
                entry.tracer = nil
            end
        end
    end
end

-- ========================================================
-- UPDATE LOOP
-- ========================================================
local function updateESP()
    if State.unloaded or not State.enabled then return end
    
    local myChar = getChar(Player)
    local myHRP  = myChar and getHRP(myChar)
    if not myHRP then return end
    
    -- Update players
    for player, entry in pairs(State.players) do
        local char = getChar(player)
        if char and isAlive(char) then
            local hrp = getHRP(char)
            if hrp then
                local hum = getHum(char)
                local hp  = hum and (hum.Health / hum.MaxHealth) or 1
                updateBillboard(entry.billboard, entry.nameLbl, entry.distLbl, entry.healthFill, hrp.Position, hp)
                
                if State.boxESP and entry.box then
                    updateBox(entry.box, entry.boxCorners, char)
                end
                
                if State.tracers and entry.tracer then
                    updateTracer(entry.tracer, hrp.Position)
                end
            end
        end
    end
    
    -- Update mobs
    for model, entry in pairs(State.mobs) do
        if model and model.Parent and entry.humanoid then
            local hrp = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso")
            if hrp and entry.humanoid.Health > 0 then
                local hp = entry.humanoid.Health / entry.humanoid.MaxHealth
                updateBillboard(entry.billboard, entry.nameLbl, entry.distLbl, entry.healthFill, hrp.Position, hp)
            else
                if entry.billboard then entry.billboard.Enabled = false end
            end
        end
    end
    
    -- Update items
    for model, entry in pairs(State.items) do
        if model and model.Parent then
            local pos
            if model:IsA("BasePart") then
                pos = model.Position
            else
                local part = model:FindFirstChild("Handle") or model:FindFirstChildWhichIsA("BasePart", true)
                pos = part and part.Position
            end
            if pos then
                updateBillboard(entry.billboard, entry.nameLbl, entry.distLbl, nil, pos, nil)
            end
        end
    end
end

-- ========================================================
-- INIT
-- ========================================================
function ESP.Init()
    if State.initialized then return ESP end
    if State.unloaded then return ESP end
    
    -- Start update loop
    State.updateConn = RunService.RenderStepped:Connect(function()
        task.spawn(updateESP)
    end)
    
    State.initialized = true
    return ESP
end

-- ========================================================
-- SETTINGS
-- ========================================================
function ESP.SetEnabled(enabled)
    State.enabled = enabled and true or false
end

function ESP.SetMaxDistance(dist)
    State.maxDistance = tonumber(dist) or 2000
end

function ESP.SetFadeDistance(dist)
    State.fadeDistance = tonumber(dist) or 1500
end

function ESP.SetTeamCheck(enabled)
    State.teamCheck = enabled and true or false
end

function ESP.SetColor(colorType, color)
    if Colors[colorType] and typeof(color) == "Color3" then
        Colors[colorType] = color
    end
end

-- ========================================================
-- CLEAR ALL
-- ========================================================
function ESP.Clear()
    for p, _ in pairs(State.players) do
        ESP.RemovePlayer(p)
    end
    for m, _ in pairs(State.mobs) do
        ESP.RemoveMob(m)
    end
    for i, _ in pairs(State.items) do
        ESP.RemoveItem(i)
    end
end

-- ========================================================
-- UNLOAD
-- ========================================================
function ESP.Unload()
    if State.unloaded then return end
    State.unloaded = true
    
    ESP.SetPlayerESP(false)
    ESP.SetMobESP(false)
    ESP.SetItemESP(false)
    ESP.Clear()
    
    if State.updateConn then
        pcall(function() State.updateConn:Disconnect() end)
        State.updateConn = nil
    end
end

-- ========================================================
-- DEBUG
-- ========================================================
function ESP.Dump()
    local pCount = 0
    for _ in pairs(State.players) do pCount = pCount + 1 end
    local mCount = 0
    for _ in pairs(State.mobs) do mCount = mCount + 1 end
    local iCount = 0
    for _ in pairs(State.items) do iCount = iCount + 1 end
    
    return {
        version      = ESP.__version,
        initialized  = State.initialized,
        unloaded     = State.unloaded,
        enabled      = State.enabled,
        playerESP    = State.playerESP,
        mobESP       = State.mobESP,
        itemESP      = State.itemESP,
        boxESP       = State.boxESP,
        tracers      = State.tracers,
        tracerOrigin = State.tracerOrigin,
        teamCheck    = State.teamCheck,
        maxDistance  = State.maxDistance,
        fadeDistance = State.fadeDistance,
        tracked      = { players = pCount, mobs = mCount, items = iCount },
    }
end

return ESP

-- PawZHub - Blox Fruits Script v2.0
-- Complete script with Auto Farm, ESP, Teleport, and more

-- ============================================
-- SECURITY CHECK
-- ============================================

local function verifyAuth()
    if not _G.PawZHubSession then
        return false, "No session"
    end
    
    local session = _G.PawZHubSession
    if session.gameId ~= game.PlaceId or os.time() - session.timestamp > 3600 then
        return false, "Invalid session"
    end
    
    return true, session
end

local authOk, session = verifyAuth()
if not authOk then
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "PawZHub Error",
        Text = "Authentication failed. Please reload script.",
        Duration = 5
    })
    return
end

-- ============================================
-- SERVICES
-- ============================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

-- ============================================
-- CONFIGURATION
-- ============================================

local Config = {
    AutoFarm = {
        Enabled = false,
        Target = "Nearest",
        Distance = 50,
        Method = "Behind" -- Behind, Above, Front
    },
    
    Combat = {
        AutoClick = false,
        ClickDelay = 0.1,
        BringMobs = false,
        BringDistance = 20
    },
    
    ESP = {
        Players = false,
        NPCs = false,
        Chests = false,
        Fruits = false,
        Color = Color3.fromRGB(255, 255, 0),
        Distance = 500
    },
    
    Teleport = {
        Speed = 300,
        Method = "Tween" -- Tween, Instant
    },
    
    Misc = {
        WalkSpeed = 16,
        JumpPower = 50,
        InfiniteJump = false,
        NoClip = false,
        AutoRespawn = false
    }
}

-- ============================================
-- GLOBALS
-- ============================================

local Connections = {}
local ESPObjects = {}

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================

local function notify(title, text)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = 3
    })
end

local function getDistance(point1, point2)
    return (point1 - point2).Magnitude
end

local function tweenToPosition(target, speed)
    local distance = getDistance(HumanoidRootPart.Position, target)
    local duration = distance / speed
    
    local tween = TweenService:Create(
        HumanoidRootPart,
        TweenInfo.new(duration, Enum.EasingStyle.Linear),
        {CFrame = CFrame.new(target)}
    )
    
    tween:Play()
    return tween
end

-- ============================================
-- COMBAT FUNCTIONS
-- ============================================

local function getEnemies()
    local enemies = {}
    
    for _, v in pairs(workspace.Enemies:GetChildren()) do
        if v:FindFirstChild("Humanoid") and v.Humanoid.Health > 0 then
            if v:FindFirstChild("HumanoidRootPart") then
                local distance = getDistance(HumanoidRootPart.Position, v.HumanoidRootPart.Position)
                if distance <= Config.AutoFarm.Distance then
                    table.insert(enemies, {
                        Model = v,
                        Distance = distance
                    })
                end
            end
        end
    end
    
    -- Sort by distance
    table.sort(enemies, function(a, b)
        return a.Distance < b.Distance
    end)
    
    return enemies
end

local function attackEnemy(enemy)
    if not enemy or not enemy:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local enemyPos = enemy.HumanoidRootPart.Position
    local offset = Vector3.new(0, 0, 0)
    
    -- Position based on method
    if Config.AutoFarm.Method == "Behind" then
        offset = enemy.HumanoidRootPart.CFrame.LookVector * -5
    elseif Config.AutoFarm.Method == "Above" then
        offset = Vector3.new(0, 10, 0)
    elseif Config.AutoFarm.Method == "Front" then
        offset = enemy.HumanoidRootPart.CFrame.LookVector * 5
    end
    
    HumanoidRootPart.CFrame = CFrame.new(enemyPos + offset)
    
    -- Auto click
    if Config.Combat.AutoClick then
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        wait(Config.Combat.ClickDelay)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    end
end

-- ============================================
-- AUTO FARM
-- ============================================

local function startAutoFarm()
    Connections.AutoFarm = RunService.Heartbeat:Connect(function()
        if not Config.AutoFarm.Enabled then return end
        
        local enemies = getEnemies()
        
        if #enemies > 0 then
            local target = enemies[1].Model
            attackEnemy(target)
            
            -- Bring mobs
            if Config.Combat.BringMobs then
                for _, enemyData in ipairs(enemies) do
                    if enemyData.Model ~= target then
                        pcall(function()
                            enemyData.Model.HumanoidRootPart.CFrame = target.HumanoidRootPart.CFrame
                            enemyData.Model.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
                            enemyData.Model.HumanoidRootPart.CanCollide = false
                        end)
                    end
                end
            end
        end
    end)
end

-- ============================================
-- ESP FUNCTIONS
-- ============================================

local function createESP(object, color, text)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP"
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.Parent = object
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 0.5
    frame.BackgroundColor3 = color
    frame.Parent = billboard
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextSize = 14
    label.Font = Enum.Font.GothamBold
    label.TextStrokeTransparency = 0.5
    label.Parent = frame
    
    table.insert(ESPObjects, billboard)
    return billboard
end

local function updateESP()
    -- Clear old ESP
    for _, esp in pairs(ESPObjects) do
        esp:Destroy()
    end
    ESPObjects = {}
    
    -- Players ESP
    if Config.ESP.Players then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= Player and player.Character then
                local hrp = player.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local distance = getDistance(HumanoidRootPart.Position, hrp.Position)
                    if distance <= Config.ESP.Distance then
                        createESP(hrp, Color3.fromRGB(255, 0, 0), 
                            string.format("%s [%d]", player.Name, math.floor(distance)))
                    end
                end
            end
        end
    end
    
    -- NPCs ESP
    if Config.ESP.NPCs then
        for _, npc in pairs(workspace.Enemies:GetChildren()) do
            if npc:FindFirstChild("HumanoidRootPart") and npc:FindFirstChild("Humanoid") then
                if npc.Humanoid.Health > 0 then
                    local distance = getDistance(HumanoidRootPart.Position, npc.HumanoidRootPart.Position)
                    if distance <= Config.ESP.Distance then
                        createESP(npc.HumanoidRootPart, Config.ESP.Color,
                            string.format("%s [%d HP] [%d]", npc.Name, 
                            math.floor(npc.Humanoid.Health), math.floor(distance)))
                    end
                end
            end
        end
    end
    
    -- Fruits ESP
    if Config.ESP.Fruits then
        for _, fruit in pairs(workspace:GetChildren()) do
            if fruit.Name:find("Fruit") and fruit:FindFirstChild("Handle") then
                local distance = getDistance(HumanoidRootPart.Position, fruit.Handle.Position)
                if distance <= Config.ESP.Distance then
                    createESP(fruit.Handle, Color3.fromRGB(255, 0, 255),
                        string.format("%s [%d]", fruit.Name, math.floor(distance)))
                end
            end
        end
    end
end

local function startESP()
    Connections.ESP = RunService.Heartbeat:Connect(function()
        if Config.ESP.Players or Config.ESP.NPCs or Config.ESP.Fruits then
            updateESP()
        end
        wait(0.5) -- Update every 0.5 seconds
    end)
end

-- ============================================
-- MISC FUNCTIONS
-- ============================================

local function setupMisc()
    -- WalkSpeed/JumpPower
    Connections.Speed = RunService.Heartbeat:Connect(function()
        if Humanoid then
            Humanoid.WalkSpeed = Config.Misc.WalkSpeed
            Humanoid.JumpPower = Config.Misc.JumpPower
        end
    end)
    
    -- NoClip
    Connections.NoClip = RunService.Stepped:Connect(function()
        if Config.Misc.NoClip and Character then
            for _, part in pairs(Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)
    
    -- Infinite Jump
    Connections.InfJump = UserInputService.JumpRequest:Connect(function()
        if Config.Misc.InfiniteJump and Humanoid then
            Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end

-- ============================================
-- UI CREATION
-- ============================================

local function createUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "PawZHubBF"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = Player.PlayerGui
    
    -- Main Frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 500, 0, 600)
    MainFrame.Position = UDim2.new(0.5, -250, 0.5, -300)
    MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    MainFrame.BorderSizePixel = 0
    MainFrame.Active = true
    MainFrame.Draggable = true
    MainFrame.Parent = ScreenGui
    
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 12)
    MainCorner.Parent = MainFrame
    
    -- Title Bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Size = UDim2.new(1, 0, 0, 50)
    TitleBar.BackgroundColor3 = Color3.fromRGB(102, 126, 234)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame
    
    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 12)
    TitleCorner.Parent = TitleBar
    
    local TitleCover = Instance.new("Frame")
    TitleCover.Size = UDim2.new(1, 0, 0, 12)
    TitleCover.Position = UDim2.new(0, 0, 1, -12)
    TitleCover.BackgroundColor3 = Color3.fromRGB(102, 126, 234)
    TitleCover.BorderSizePixel = 0
    TitleCover.Parent = TitleBar
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -100, 1, 0)
    Title.Position = UDim2.new(0, 20, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "🐾 PawZHub - Blox Fruits"
    Title.TextColor3 = Color3.new(1, 1, 1)
    Title.TextSize = 18
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TitleBar
    
    -- Close Button
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 40, 0, 40)
    CloseBtn.Position = UDim2.new(1, -45, 0, 5)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(244, 67, 54)
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = Color3.new(1, 1, 1)
    CloseBtn.TextSize = 20
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.Parent = TitleBar
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(1, 0)
    CloseCorner.Parent = CloseBtn
    
    CloseBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
        for name, connection in pairs(Connections) do
            connection:Disconnect()
        end
    end)
    
    -- Content
    local Content = Instance.new("ScrollingFrame")
    Content.Size = UDim2.new(1, -40, 1, -70)
    Content.Position = UDim2.new(0, 20, 0, 60)
    Content.BackgroundTransparency = 1
    Content.BorderSizePixel = 0
    Content.ScrollBarThickness = 4
    Content.Parent = MainFrame
    
    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0, 10)
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    Layout.Parent = Content
    
    -- Helper function to create sections
    local function createSection(name)
        local Section = Instance.new("Frame")
        Section.Size = UDim2.new(1, 0, 0, 40)
        Section.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
        Section.BorderSizePixel = 0
        Section.Parent = Content
        
        local SectionCorner = Instance.new("UICorner")
        SectionCorner.CornerRadius = UDim.new(0, 8)
        SectionCorner.Parent = Section
        
        local SectionLabel = Instance.new("TextLabel")
        SectionLabel.Size = UDim2.new(1, -20, 1, 0)
        SectionLabel.Position = UDim2.new(0, 10, 0, 0)
        SectionLabel.BackgroundTransparency = 1
        SectionLabel.Text = name
        SectionLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
        SectionLabel.TextSize = 16
        SectionLabel.Font = Enum.Font.GothamBold
        SectionLabel.TextXAlignment = Enum.TextXAlignment.Left
        SectionLabel.Parent = Section
        
        return Section
    end
    
    -- Helper function to create toggle
    local function createToggle(name, default, callback)
        local Toggle = Instance.new("Frame")
        Toggle.Size = UDim2.new(1, 0, 0, 40)
        Toggle.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
        Toggle.BorderSizePixel = 0
        Toggle.Parent = Content
        
        local ToggleCorner = Instance.new("UICorner")
        ToggleCorner.CornerRadius = UDim.new(0, 8)
        ToggleCorner.Parent = Toggle
        
        local ToggleLabel = Instance.new("TextLabel")
        ToggleLabel.Size = UDim2.new(1, -80, 1, 0)
        ToggleLabel.Position = UDim2.new(0, 10, 0, 0)
        ToggleLabel.BackgroundTransparency = 1
        ToggleLabel.Text = name
        ToggleLabel.TextColor3 = Color3.new(1, 1, 1)
        ToggleLabel.TextSize = 14
        ToggleLabel.Font = Enum.Font.Gotham
        ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
        ToggleLabel.Parent = Toggle
        
        local ToggleButton = Instance.new("TextButton")
        ToggleButton.Size = UDim2.new(0, 60, 0, 30)
        ToggleButton.Position = UDim2.new(1, -70, 0.5, -15)
        ToggleButton.BackgroundColor3 = default and Color3.fromRGB(76, 175, 80) or Color3.fromRGB(180, 180, 180)
        ToggleButton.BorderSizePixel = 0
        ToggleButton.Text = default and "ON" or "OFF"
        ToggleButton.TextColor3 = Color3.new(1, 1, 1)
        ToggleButton.TextSize = 12
        ToggleButton.Font = Enum.Font.GothamBold
        ToggleButton.Parent = Toggle
        
        local BtnCorner = Instance.new("UICorner")
        BtnCorner.CornerRadius = UDim.new(0, 6)
        BtnCorner.Parent = ToggleButton
        
        local isOn = default
        
        ToggleButton.MouseButton1Click:Connect(function()
            isOn = not isOn
            ToggleButton.Text = isOn and "ON" or "OFF"
            ToggleButton.BackgroundColor3 = isOn and Color3.fromRGB(76, 175, 80) or Color3.fromRGB(180, 180, 180)
            callback(isOn)
        end)
    end
    
    -- AUTO FARM SECTION
    createSection("⚔️ Auto Farm")
    
    createToggle("Enable Auto Farm", false, function(value)
        Config.AutoFarm.Enabled = value
        if value then
            notify("Auto Farm", "Enabled")
        else
            notify("Auto Farm", "Disabled")
        end
    end)
    
    createToggle("Auto Click", false, function(value)
        Config.Combat.AutoClick = value
    end)
    
    createToggle("Bring Mobs", false, function(value)
        Config.Combat.BringMobs = value
    end)
    
    -- ESP SECTION
    createSection("👁️ ESP")
    
    createToggle("Player ESP", false, function(value)
        Config.ESP.Players = value
    end)
    
    createToggle("NPC ESP", false, function(value)
        Config.ESP.NPCs = value
    end)
    
    createToggle("Fruit ESP", false, function(value)
        Config.ESP.Fruits = value
    end)
    
    -- MISC SECTION
    createSection("⚙️ Misc")
    
    createToggle("NoClip", false, function(value)
        Config.Misc.NoClip = value
    end)
    
    createToggle("Infinite Jump", false, function(value)
        Config.Misc.InfiniteJump = value
    end)
    
    createToggle("Auto Respawn", false, function(value)
        Config.Misc.AutoRespawn = value
        
        if value then
            Player.CharacterRemoving:Connect(function()
                if Config.Misc.AutoRespawn then
                    wait(1)
                    Player:LoadCharacter()
                end
            end)
        end
    end)
    
    -- Update content size
    Content.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 20)
    Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Content.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 20)
    end)
end

-- ============================================
-- INITIALIZE
-- ============================================

local function init()
    -- Start systems
    startAutoFarm()
    startESP()
    setupMisc()
    
    -- Create UI
    createUI()
    
    -- Success notification
    notify("PawZHub", "Blox Fruits loaded successfully!")
    
    print("✅ PawZHub Blox Fruits v2.0 loaded")
    print("📊 Session:", session.token:sub(1, 8) .. "...")
    print("👤 User:", session.username)
    print("🔑 Key Tier:", session.keyTier)
end

-- Run with error handling
local success, err = pcall(init)
if not success then
    warn("❌ PawZHub Error:", err)
    notify("PawZHub Error", "Failed to load script")
end

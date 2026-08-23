-- PawZHub - Gunfight Arena Script v2.0
-- Complete script with Aimbot, ESP, Speed, and more

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
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

-- ============================================
-- CONFIGURATION
-- ============================================

local Config = {
    Aimbot = {
        Enabled = false,
        TeamCheck = true,
        VisibleCheck = true,
        TargetPart = "Head", -- Head, Torso, HumanoidRootPart
        FOV = 100,
        ShowFOV = true,
        Smoothness = 0.1
    },
    
    ESP = {
        Enabled = false,
        Boxes = true,
        Names = true,
        Distance = true,
        Health = true,
        TeamCheck = true,
        MaxDistance = 500,
        BoxColor = Color3.fromRGB(255, 255, 255),
        NameColor = Color3.fromRGB(255, 255, 255)
    },
    
    Combat = {
        NoRecoil = false,
        NoSpread = false,
        InfiniteAmmo = false,
        RapidFire = false,
        AutoShoot = false
    },
    
    Movement = {
        Speed = 16,
        JumpPower = 50,
        InfiniteJump = false,
        Fly = false,
        FlySpeed = 50
    },
    
    Visuals = {
        FOV = 70,
        FullBright = false,
        NoFlash = false,
        NoSmoke = false
    }
}

-- ============================================
-- GLOBALS
-- ============================================

local Connections = {}
local ESPObjects = {}
local FOVCircle

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

local function isVisible(targetPart)
    if not targetPart then return false end
    
    local character = Player.Character
    if not character then return false end
    
    local origin = character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
    if not origin then return false end
    
    local ray = Ray.new(origin.Position, (targetPart.Position - origin.Position).Unit * 500)
    local hit = workspace:FindPartOnRayWithIgnoreList(ray, {character})
    
    return hit and hit:IsDescendantOf(targetPart.Parent)
end

local function getClosestPlayer()
    local closestPlayer = nil
    local shortestDistance = Config.Aimbot.FOV
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= Player and player.Character then
            -- Team check
            if Config.Aimbot.TeamCheck and player.Team == Player.Team then
                continue
            end
            
            local character = player.Character
            local targetPart = character:FindFirstChild(Config.Aimbot.TargetPart)
            
            if targetPart then
                -- Visible check
                if Config.Aimbot.VisibleCheck and not isVisible(targetPart) then
                    continue
                end
                
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                
                if onScreen then
                    local mousePos = Vector2.new(Mouse.X, Mouse.Y)
                    local targetPos = Vector2.new(screenPos.X, screenPos.Y)
                    local distance = (mousePos - targetPos).Magnitude
                    
                    if distance < shortestDistance then
                        closestPlayer = player
                        shortestDistance = distance
                    end
                end
            end
        end
    end
    
    return closestPlayer
end

-- ============================================
-- AIMBOT SYSTEM
-- ============================================

local function startAimbot()
    -- Create FOV Circle
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Visible = Config.Aimbot.ShowFOV
    FOVCircle.Thickness = 2
    FOVCircle.Color = Color3.fromRGB(255, 255, 255)
    FOVCircle.Filled = false
    FOVCircle.Radius = Config.Aimbot.FOV
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    Connections.Aimbot = RunService.RenderStepped:Connect(function()
        if not Config.Aimbot.Enabled then
            FOVCircle.Visible = false
            return
        end
        
        -- Update FOV circle
        FOVCircle.Visible = Config.Aimbot.ShowFOV
        FOVCircle.Radius = Config.Aimbot.FOV
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        
        -- Get closest target
        local target = getClosestPlayer()
        
        if target and target.Character then
            local targetPart = target.Character:FindFirstChild(Config.Aimbot.TargetPart)
            
            if targetPart then
                local targetPos = targetPart.Position
                local cameraPos = Camera.CFrame.Position
                local direction = (targetPos - cameraPos).Unit
                
                -- Smooth aim
                local currentLook = Camera.CFrame.LookVector
                local newLook = currentLook:Lerp(direction, Config.Aimbot.Smoothness)
                
                Camera.CFrame = CFrame.new(cameraPos, cameraPos + newLook)
            end
        end
    end)
end

-- ============================================
-- ESP SYSTEM
-- ============================================

local function createESP(player)
    if not player.Character then return end
    
    local espFolder = Instance.new("Folder")
    espFolder.Name = "ESP_" .. player.Name
    espFolder.Parent = Player.PlayerGui
    
    ESPObjects[player] = espFolder
    
    -- Box ESP
    if Config.ESP.Boxes then
        local box = Drawing.new("Square")
        box.Visible = false
        box.Filled = false
        box.Color = Config.ESP.BoxColor
        box.Thickness = 2
        espFolder.Box = box
    end
    
    -- Name ESP
    if Config.ESP.Names then
        local name = Drawing.new("Text")
        name.Visible = false
        name.Color = Config.ESP.NameColor
        name.Size = 16
        name.Center = true
        name.Outline = true
        name.Font = 2
        espFolder.Name = name
    end
    
    return espFolder
end

local function updateESP()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= Player then
            -- Team check
            if Config.ESP.TeamCheck and player.Team == Player.Team then
                if ESPObjects[player] then
                    for _, obj in pairs(ESPObjects[player]:GetChildren()) do
                        if obj.Visible ~= nil then
                            obj.Visible = false
                        end
                    end
                end
                continue
            end
            
            local character = player.Character
            if not character then continue end
            
            local hrp = character:FindFirstChild("HumanoidRootPart")
            local humanoid = character:FindFirstChild("Humanoid")
            
            if not hrp or not humanoid or humanoid.Health <= 0 then continue end
            
            -- Distance check
            local distance = (hrp.Position - Player.Character.HumanoidRootPart.Position).Magnitude
            if distance > Config.ESP.MaxDistance then continue end
            
            -- Create ESP if doesn't exist
            if not ESPObjects[player] then
                createESP(player)
            end
            
            local esp = ESPObjects[player]
            if not esp then continue end
            
            -- Update Box
            if Config.ESP.Boxes and esp.Box then
                local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                
                if onScreen then
                    local head = character:FindFirstChild("Head")
                    if head then
                        local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                        local legPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                        
                        local height = math.abs(headPos.Y - legPos.Y)
                        local width = height / 2
                        
                        esp.Box.Size = Vector2.new(width, height)
                        esp.Box.Position = Vector2.new(screenPos.X - width / 2, screenPos.Y - height / 2)
                        esp.Box.Visible = true
                    end
                else
                    esp.Box.Visible = false
                end
            end
            
            -- Update Name
            if Config.ESP.Names and esp.Name then
                local screenPos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                
                if onScreen then
                    local text = player.Name
                    
                    if Config.ESP.Distance then
                        text = text .. " [" .. math.floor(distance) .. "m]"
                    end
                    
                    if Config.ESP.Health then
                        local health = math.floor((humanoid.Health / humanoid.MaxHealth) * 100)
                        text = text .. " [" .. health .. "%]"
                    end
                    
                    esp.Name.Text = text
                    esp.Name.Position = Vector2.new(screenPos.X, screenPos.Y - 40)
                    esp.Name.Visible = true
                else
                    esp.Name.Visible = false
                end
            end
        end
    end
end

local function startESP()
    Connections.ESP = RunService.RenderStepped:Connect(function()
        if Config.ESP.Enabled then
            updateESP()
        else
            -- Hide all ESP
            for _, esp in pairs(ESPObjects) do
                for _, obj in pairs(esp:GetChildren()) do
                    if obj.Visible ~= nil then
                        obj.Visible = false
                    end
                end
            end
        end
    end)
end

-- ============================================
-- MOVEMENT SYSTEM
-- ============================================

local function setupMovement()
    local character = Player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not hrp then return end
    
    -- Speed & Jump
    Connections.Movement = RunService.Heartbeat:Connect(function()
        if humanoid then
            humanoid.WalkSpeed = Config.Movement.Speed
            humanoid.JumpPower = Config.Movement.JumpPower
        end
    end)
    
    -- Infinite Jump
    Connections.InfJump = UserInputService.JumpRequest:Connect(function()
        if Config.Movement.InfiniteJump and humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
    
    -- Fly
    local flying = false
    local flyConnection
    
    local function startFly()
        if flying then return end
        flying = true
        
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        bodyVelocity.Parent = hrp
        
        local bodyGyro = Instance.new("BodyGyro")
        bodyGyro.MaxTorque = Vector3.new(100000, 100000, 100000)
        bodyGyro.CFrame = hrp.CFrame
        bodyGyro.Parent = hrp
        
        flyConnection = RunService.Heartbeat:Connect(function()
            if not Config.Movement.Fly then
                flying = false
                bodyVelocity:Destroy()
                bodyGyro:Destroy()
                flyConnection:Disconnect()
                return
            end
            
            local moveDirection = Vector3.new(0, 0, 0)
            
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                moveDirection = moveDirection + Camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                moveDirection = moveDirection - Camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                moveDirection = moveDirection - Camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                moveDirection = moveDirection + Camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                moveDirection = moveDirection + Vector3.new(0, 1, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                moveDirection = moveDirection - Vector3.new(0, 1, 0)
            end
            
            bodyVelocity.Velocity = moveDirection.Unit * Config.Movement.FlySpeed
            bodyGyro.CFrame = Camera.CFrame
        end)
    end
    
    -- Monitor fly state
    spawn(function()
        while wait(0.1) do
            if Config.Movement.Fly and not flying then
                startFly()
            end
        end
    end)
end

-- ============================================
-- VISUALS
-- ============================================

local function setupVisuals()
    -- Full Bright
    Connections.FullBright = RunService.Heartbeat:Connect(function()
        if Config.Visuals.FullBright then
            game:GetService("Lighting").Brightness = 2
            game:GetService("Lighting").ClockTime = 14
            game:GetService("Lighting").FogEnd = 100000
            game:GetService("Lighting").GlobalShadows = false
            game:GetService("Lighting").OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        end
    end)
    
    -- FOV Changer
    Camera.FieldOfView = Config.Visuals.FOV
end

-- ============================================
-- UI CREATION
-- ============================================

local function createUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "PawZHubGG"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = Player.PlayerGui
    
    -- Main Frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 500, 0, 650)
    MainFrame.Position = UDim2.new(0.5, -250, 0.5, -325)
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
    Title.Text = "🐾 PawZHub - Gunfight Arena"
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
        if FOVCircle then
            FOVCircle:Remove()
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
    
    -- Helper functions
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
    end
    
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
    
    -- AIMBOT SECTION
    createSection("🎯 Aimbot")
    
    createToggle("Enable Aimbot", false, function(value)
        Config.Aimbot.Enabled = value
        notify("Aimbot", value and "Enabled" or "Disabled")
    end)
    
    createToggle("Show FOV Circle", true, function(value)
        Config.Aimbot.ShowFOV = value
    end)
    
    createToggle("Team Check", true, function(value)
        Config.Aimbot.TeamCheck = value
    end)
    
    createToggle("Visible Check", true, function(value)
        Config.Aimbot.VisibleCheck = value
    end)
    
    -- ESP SECTION
    createSection("👁️ ESP")
    
    createToggle("Enable ESP", false, function(value)
        Config.ESP.Enabled = value
    end)
    
    createToggle("Boxes", true, function(value)
        Config.ESP.Boxes = value
    end)
    
    createToggle("Names", true, function(value)
        Config.ESP.Names = value
    end)
    
    createToggle("Health", true, function(value)
        Config.ESP.Health = value
    end)
    
    -- MOVEMENT SECTION
    createSection("🏃 Movement")
    
    createToggle("Fly", false, function(value)
        Config.Movement.Fly = value
    end)
    
    createToggle("Infinite Jump", false, function(value)
        Config.Movement.InfiniteJump = value
    end)
    
    -- VISUALS SECTION
    createSection("👀 Visuals")
    
    createToggle("Full Bright", false, function(value)
        Config.Visuals.FullBright = value
    end)
    
    -- Update canvas size
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
    startAimbot()
    startESP()
    setupMovement()
    setupVisuals()
    
    -- Create UI
    createUI()
    
    -- Success notification
    notify("PawZHub", "Gunfight Arena loaded successfully!")
    
    print("✅ PawZHub Gunfight Arena v2.0 loaded")
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

-- PawZHub Key Authentication System
-- This file handles key verification and creates session tokens

local CheckKeySystem = {}

-- Configuration
local CONFIG = {
    KEY_CHECK_URL = "https://your-api-endpoint.com/verify", -- Replace with your API endpoint
    WEBHOOK_URL = "https://discord.com/api/webhooks/YOUR_WEBHOOK", -- Optional: for logging
    KEY_LENGTH = 20, -- Expected key length
    SESSION_DURATION = 3600, -- Session valid for 1 hour (in seconds)
}

-- Generate unique session token
local function generateToken()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
    local token = ""
    for i = 1, 32 do
        local rand = math.random(1, #chars)
        token = token .. chars:sub(rand, rand)
    end
    return token
end

-- Create session data
local function createSession(key)
    local token = generateToken()
    local sessionData = {
        token = token,
        key = key,
        timestamp = os.time(),
        gameId = game.PlaceId,
        userId = game:GetService("Players").LocalPlayer.UserId,
        username = game:GetService("Players").LocalPlayer.Name
    }
    
    -- Store in global scope (accessible by other scripts)
    _G.PawZHubSession = sessionData
    
    return sessionData
end

-- Verify session is still valid
function CheckKeySystem.verifySession()
    if not _G.PawZHubSession then
        return false, "No active session"
    end
    
    local session = _G.PawZHubSession
    local currentTime = os.time()
    
    -- Check if session expired
    if (currentTime - session.timestamp) > CONFIG.SESSION_DURATION then
        _G.PawZHubSession = nil
        return false, "Session expired"
    end
    
    -- Check if game matches
    if session.gameId ~= game.PlaceId then
        return false, "Session for different game"
    end
    
    return true, session
end

-- Verify key with remote server
local function verifyKeyRemote(key)
    local HttpService = game:GetService("HttpService")
    local success, response = pcall(function()
        return HttpService:PostAsync(
            CONFIG.KEY_CHECK_URL,
            HttpService:JSONEncode({
                key = key,
                userId = game:GetService("Players").LocalPlayer.UserId,
                username = game:GetService("Players").LocalPlayer.Name,
                gameId = game.PlaceId
            }),
            Enum.HttpContentType.ApplicationJson,
            false
        )
    end)
    
    if success then
        local data = HttpService:JSONDecode(response)
        return data.valid == true, data.message or "Unknown error"
    else
        -- Fallback: If HTTP fails, check against hardcoded keys
        warn("Key verification server unavailable, using fallback")
        return CheckKeySystem.verifyKeyFallback(key)
    end
end

-- Fallback key verification (hardcoded keys)
function CheckKeySystem.verifyKeyFallback(key)
    local validKeys = {
        "PAWZ-FREE-2024-DEMO1",
        "PAWZ-PREMIUM-KEY123",
        -- Add more keys here
    }
    
    for _, validKey in ipairs(validKeys) do
        if key == validKey then
            return true, "Key valid (fallback mode)"
        end
    end
    
    return false, "Invalid key"
end

-- Create UI for key input - Premium design with smooth animations
local function createKeyUI(callback)
    local Players = game:GetService("Players")
    local TweenService = game:GetService("TweenService")
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PawZHubKeySystem"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Animated gradient background
    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(17, 20, 29)
    overlay.BorderSizePixel = 0
    overlay.Parent = screenGui
    
    local overlayGradient = Instance.new("UIGradient")
    overlayGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 30, 45)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(17, 20, 29)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 25, 38))
    }
    overlayGradient.Rotation = 45
    overlayGradient.Parent = overlay
    
    -- Animate gradient rotation
    task.spawn(function()
        while overlay.Parent do
            for i = 0, 360, 1 do
                if not overlay.Parent then break end
                overlayGradient.Rotation = i
                task.wait(0.05)
            end
        end
    end)
    
    -- Floating particles
    for i = 1, 12 do
        local particle = Instance.new("Frame")
        particle.Size = UDim2.new(0, math.random(4, 10), 0, math.random(4, 10))
        particle.Position = UDim2.new(math.random(0, 100) / 100, 0, math.random(0, 100) / 100, 0)
        particle.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
        particle.BackgroundTransparency = math.random(75, 90) / 100
        particle.BorderSizePixel = 0
        particle.Parent = overlay
        
        local particleCorner = Instance.new("UICorner")
        particleCorner.CornerRadius = UDim.new(1, 0)
        particleCorner.Parent = particle
        
        task.spawn(function()
            while particle.Parent do
                local randomTime = math.random(4, 8)
                local randomX = math.random(-80, 80)
                local randomY = math.random(-80, 80)
                
                TweenService:Create(particle, TweenInfo.new(
                    randomTime,
                    Enum.EasingStyle.Sine,
                    Enum.EasingDirection.InOut,
                    -1,
                    true
                ), {
                    Position = particle.Position + UDim2.new(0, randomX, 0, randomY),
                    BackgroundTransparency = math.random(70, 95) / 100
                }):Play()
                
                task.wait(randomTime)
            end
        end)
    end
    
    -- Glow effect layers
    local glow3 = Instance.new("ImageLabel")
    glow3.Size = UDim2.new(0, 500, 0, 320)
    glow3.Position = UDim2.new(0.5, -250, 0.5, -160)
    glow3.BackgroundTransparency = 1
    glow3.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
    glow3.ImageColor3 = Color3.fromRGB(88, 101, 242)
    glow3.ImageTransparency = 0.85
    glow3.ScaleType = Enum.ScaleType.Slice
    glow3.SliceCenter = Rect.new(10, 10, 10, 10)
    glow3.ZIndex = 1
    glow3.Parent = screenGui
    
    local glow2 = glow3:Clone()
    glow2.Size = UDim2.new(0, 480, 0, 300)
    glow2.Position = UDim2.new(0.5, -240, 0.5, -150)
    glow2.ImageTransparency = 0.9
    glow2.ZIndex = 2
    glow2.Parent = screenGui
    
    local glow1 = glow3:Clone()
    glow1.Size = UDim2.new(0, 460, 0, 280)
    glow1.Position = UDim2.new(0.5, -230, 0.5, -140)
    glow1.ImageTransparency = 0.92
    glow1.ZIndex = 3
    glow1.Parent = screenGui
    
    -- Main frame
    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 440, 0, 260)
    main.Position = UDim2.new(0.5, -220, 0.5, -130)
    main.BackgroundColor3 = Color3.fromRGB(28, 32, 45)
    main.BorderSizePixel = 0
    main.ZIndex = 4
    main.ClipsDescendants = false
    main.Parent = screenGui
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 20)
    mainCorner.Parent = main
    
    -- Glass effect gradient
    local mainGradient = Instance.new("UIGradient")
    mainGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 40, 58)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(28, 32, 45))
    }
    mainGradient.Rotation = 135
    mainGradient.Parent = main
    
    -- Subtle border
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Color3.fromRGB(88, 101, 242)
    mainStroke.Thickness = 1.5
    mainStroke.Transparency = 0.7
    mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    mainStroke.Parent = main
    
    -- Pulse border animation
    task.spawn(function()
        while main.Parent do
            TweenService:Create(mainStroke, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                Transparency = 0.4
            }):Play()
            task.wait(2)
        end
    end)
    
    -- Top glass shine
    local shine = Instance.new("Frame")
    shine.Size = UDim2.new(1, 0, 0.3, 0)
    shine.Position = UDim2.new(0, 0, 0, 0)
    shine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    shine.BackgroundTransparency = 0.95
    shine.BorderSizePixel = 0
    shine.ZIndex = 5
    shine.Parent = main
    
    local shineCorner = Instance.new("UICorner")
    shineCorner.CornerRadius = UDim.new(0, 20)
    shineCorner.Parent = shine
    
    local shineGradient = Instance.new("UIGradient")
    shineGradient.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1)
    }
    shineGradient.Rotation = 90
    shineGradient.Parent = shine
    
    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, -50, 0, 70)
    header.Position = UDim2.new(0, 25, 0, 20)
    header.BackgroundTransparency = 1
    header.ZIndex = 6
    header.Parent = main
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 32)
    title.BackgroundTransparency = 1
    title.Text = "PawZHub"
    title.TextColor3 = Color3.fromRGB(245, 248, 255)
    title.TextSize = 26
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 7
    title.Parent = header
    
    -- Gradient text effect
    local titleGradient = Instance.new("UIGradient")
    titleGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 190, 220))
    }
    titleGradient.Rotation = 90
    titleGradient.Parent = title
    
    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, 0, 0, 20)
    subtitle.Position = UDim2.new(0, 0, 0, 38)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Enter your license key"
    subtitle.TextColor3 = Color3.fromRGB(150, 160, 185)
    subtitle.TextSize = 14
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.ZIndex = 7
    subtitle.Parent = header
    
    -- Animated underline
    local underline = Instance.new("Frame")
    underline.Size = UDim2.new(0, 0, 0, 2)
    underline.Position = UDim2.new(0, 0, 1, -2)
    underline.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    underline.BorderSizePixel = 0
    underline.ZIndex = 7
    underline.Parent = header
    
    local underlineCorner = Instance.new("UICorner")
    underlineCorner.CornerRadius = UDim.new(1, 0)
    underlineCorner.Parent = underline
    
    TweenService:Create(underline, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0.25, 0, 0, 2)
    }):Play()
    
    -- Content
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -50, 1, -110)
    content.Position = UDim2.new(0, 25, 0, 100)
    content.BackgroundTransparency = 1
    content.ZIndex = 6
    content.Parent = main
    
    -- Input container with glass morphism
    local inputContainer = Instance.new("Frame")
    inputContainer.Size = UDim2.new(1, 0, 0, 52)
    inputContainer.Position = UDim2.new(0, 0, 0, 0)
    inputContainer.BackgroundColor3 = Color3.fromRGB(20, 24, 35)
    inputContainer.BorderSizePixel = 0
    inputContainer.ZIndex = 6
    inputContainer.Parent = content
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 14)
    inputCorner.Parent = inputContainer
    
    local inputStroke = Instance.new("UIStroke")
    inputStroke.Color = Color3.fromRGB(60, 70, 95)
    inputStroke.Thickness = 1.5
    inputStroke.Transparency = 0.6
    inputStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    inputStroke.Parent = inputContainer
    
    local inputGradient = Instance.new("UIGradient")
    inputGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 29, 42)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 24, 35))
    }
    inputGradient.Rotation = 135
    inputGradient.Parent = inputContainer
    
    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1, -30, 1, 0)
    input.Position = UDim2.new(0, 15, 0, 0)
    input.BackgroundTransparency = 1
    input.Text = ""
    input.PlaceholderText = "XXXX-XXXX-XXXX-XXXX"
    input.TextColor3 = Color3.fromRGB(240, 245, 255)
    input.PlaceholderColor3 = Color3.fromRGB(100, 110, 135)
    input.TextSize = 15
    input.Font = Enum.Font.GothamMedium
    input.ClearTextOnFocus = false
    input.ZIndex = 7
    input.Parent = inputContainer
    
    -- Focus animations
    input.Focused:Connect(function()
        TweenService:Create(inputStroke, TweenInfo.new(0.3), {
            Color = Color3.fromRGB(88, 101, 242),
            Transparency = 0.3,
            Thickness = 2
        }):Play()
        TweenService:Create(inputContainer, TweenInfo.new(0.3), {
            BackgroundColor3 = Color3.fromRGB(25, 30, 45)
        }):Play()
    end)
    
    input.FocusLost:Connect(function()
        TweenService:Create(inputStroke, TweenInfo.new(0.3), {
            Color = Color3.fromRGB(60, 70, 95),
            Transparency = 0.6,
            Thickness = 1.5
        }):Play()
        TweenService:Create(inputContainer, TweenInfo.new(0.3), {
            BackgroundColor3 = Color3.fromRGB(20, 24, 35)
        }):Play()
    end)
    
    -- Modern button creator
    local function createButton(text, position, isPrimary)
        local btnContainer = Instance.new("Frame")
        btnContainer.Size = UDim2.new(0.485, 0, 0, 48)
        btnContainer.Position = position
        btnContainer.BackgroundTransparency = 1
        btnContainer.ZIndex = 6
        btnContainer.Parent = content
        
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.BackgroundColor3 = isPrimary and Color3.fromRGB(88, 101, 242) or Color3.fromRGB(42, 48, 68)
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.ZIndex = 7
        btn.Parent = btnContainer
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 14)
        btnCorner.Parent = btn
        
        if isPrimary then
            local btnGradient = Instance.new("UIGradient")
            btnGradient.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(108, 121, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(78, 91, 232))
            }
            btnGradient.Rotation = 135
            btnGradient.Parent = btn
        end
        
        local btnText = Instance.new("TextLabel")
        btnText.Size = UDim2.new(1, 0, 1, 0)
        btnText.BackgroundTransparency = 1
        btnText.Text = text
        btnText.TextColor3 = Color3.fromRGB(255, 255, 255)
        btnText.TextSize = 15
        btnText.Font = Enum.Font.GothamBold
        btnText.ZIndex = 8
        btnText.Parent = btn
        
        -- Hover effect
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                Size = UDim2.new(1, 0, 1, 4),
                Position = UDim2.new(0, 0, 0, -2)
            }):Play()
            
            if isPrimary then
                TweenService:Create(btn, TweenInfo.new(0.2), {
                    BackgroundColor3 = Color3.fromRGB(118, 131, 255)
                }):Play()
            else
                TweenService:Create(btn, TweenInfo.new(0.2), {
                    BackgroundColor3 = Color3.fromRGB(52, 58, 78)
                }):Play()
            end
        end)
        
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                Size = UDim2.new(1, 0, 1, 0),
                Position = UDim2.new(0, 0, 0, 0)
            }):Play()
            
            if isPrimary then
                TweenService:Create(btn, TweenInfo.new(0.2), {
                    BackgroundColor3 = Color3.fromRGB(88, 101, 242)
                }):Play()
            else
                TweenService:Create(btn, TweenInfo.new(0.2), {
                    BackgroundColor3 = Color3.fromRGB(42, 48, 68)
                }):Play()
            end
        end)
        
        return btn, btnText
    end
    
    local submitBtn, submitText = createButton("Submit", UDim2.new(0, 0, 0, 70), true)
    local getKeyBtn, getKeyText = createButton("Get Key", UDim2.new(0.515, 0, 0, 70), false)
    
    -- Status with icon
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, 0, 0, 22)
    status.Position = UDim2.new(0, 0, 0, 132)
    status.BackgroundTransparency = 1
    status.Text = ""
    status.TextColor3 = Color3.fromRGB(255, 100, 100)
    status.TextSize = 13
    status.Font = Enum.Font.GothamMedium
    status.TextTransparency = 1
    status.ZIndex = 7
    status.Parent = content
    
    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, -40, 0, 60)
    header.Position = UDim2.new(0, 20, 0, 20)
    header.BackgroundTransparency = 1
    header.ZIndex = 5
    header.Parent = main
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 28)
    title.BackgroundTransparency = 1
    title.Text = "PawZHub Key System"
    title.TextColor3 = Color3.fromRGB(230, 232, 245)
    title.TextSize = 20
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 6
    title.Parent = header
    
    -- Add text shadow for depth
    local titleShadow = Instance.new("TextLabel")
    titleShadow.Size = title.Size
    titleShadow.Position = UDim2.new(0, 1, 0, 2)
    titleShadow.BackgroundTransparency = 1
    titleShadow.Text = title.Text
    titleShadow.TextColor3 = Color3.fromRGB(0, 0, 0)
    titleShadow.TextTransparency = 0.8
    titleShadow.TextSize = title.TextSize
    titleShadow.Font = title.Font
    titleShadow.TextXAlignment = title.TextXAlignment
    titleShadow.ZIndex = 5
    titleShadow.Parent = header
    
    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, 0, 0, 18)
    subtitle.Position = UDim2.new(0, 0, 0, 32)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Enter your license key to continue"
    subtitle.TextColor3 = Color3.fromRGB(140, 145, 165)
    subtitle.TextSize = 13
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.ZIndex = 6
    subtitle.Parent = header
    
    -- Content
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -40, 1, -100)
    content.Position = UDim2.new(0, 20, 0, 90)
    content.BackgroundTransparency = 1
    content.ZIndex = 5
    content.Parent = main
    
    -- Input field - Clay inset effect
    local inputOuter = Instance.new("Frame")
    inputOuter.Size = UDim2.new(1, 0, 0, 50)
    inputOuter.Position = UDim2.new(0, 0, 0, 0)
    inputOuter.BackgroundColor3 = Color3.fromRGB(28, 30, 40)
    inputOuter.BorderSizePixel = 0
    inputOuter.ZIndex = 5
    inputOuter.Parent = content
    
    local inputOuterCorner = Instance.new("UICorner")
    inputOuterCorner.CornerRadius = UDim.new(0, 16)
    inputOuterCorner.Parent = inputOuter
    
    -- Inner shadow effect (top dark)
    local inputInnerShadow = Instance.new("Frame")
    inputInnerShadow.Size = UDim2.new(1, -4, 1, -4)
    inputInnerShadow.Position = UDim2.new(0, 2, 0, 2)
    inputInnerShadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    inputInnerShadow.BackgroundTransparency = 0.7
    inputInnerShadow.BorderSizePixel = 0
    inputInnerShadow.ZIndex = 6
    inputInnerShadow.Parent = inputOuter
    
    local inputInnerShadowCorner = Instance.new("UICorner")
    inputInnerShadowCorner.CornerRadius = UDim.new(0, 14)
    inputInnerShadowCorner.Parent = inputInnerShadow
    
    -- Input field actual
    local inputFrame = Instance.new("Frame")
    inputFrame.Size = UDim2.new(1, -8, 1, -8)
    inputFrame.Position = UDim2.new(0, 4, 0, 4)
    inputFrame.BackgroundColor3 = Color3.fromRGB(35, 37, 48)
    inputFrame.BorderSizePixel = 0
    inputFrame.ZIndex = 7
    inputFrame.Parent = inputOuter
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 13)
    inputCorner.Parent = inputFrame
    
    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1, -20, 1, 0)
    input.Position = UDim2.new(0, 10, 0, 0)
    input.BackgroundTransparency = 1
    input.Text = ""
    input.PlaceholderText = "Enter your key here..."
    input.TextColor3 = Color3.fromRGB(220, 225, 240)
    input.PlaceholderColor3 = Color3.fromRGB(100, 105, 120)
    input.TextSize = 14
    input.Font = Enum.Font.Gotham
    input.ClearTextOnFocus = false
    input.ZIndex = 8
    input.Parent = inputFrame
    
    -- Focus glow animation
    input.Focused:Connect(function()
        TweenService:Create(inputOuter, TweenInfo.new(0.3), {
            BackgroundColor3 = Color3.fromRGB(55, 60, 85)
        }):Play()
        TweenService:Create(inputFrame, TweenInfo.new(0.3), {
            BackgroundColor3 = Color3.fromRGB(45, 50, 70)
        }):Play()
    end)
    
    input.FocusLost:Connect(function()
        TweenService:Create(inputOuter, TweenInfo.new(0.3), {
            BackgroundColor3 = Color3.fromRGB(28, 30, 40)
        }):Play()
        TweenService:Create(inputFrame, TweenInfo.new(0.3), {
            BackgroundColor3 = Color3.fromRGB(35, 37, 48)
        }):Play()
    end)
    
    -- Buttons with clay/raised effect
    local function createClayButton(text, position, isPrimary)
        -- Outer shadow for button
        local btnShadow = Instance.new("Frame")
        btnShadow.Size = UDim2.new(0.48, 0, 0, 46)
        btnShadow.Position = position + UDim2.new(0, 0, 0, 4)
        btnShadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        btnShadow.BackgroundTransparency = 0.6
        btnShadow.BorderSizePixel = 0
        btnShadow.ZIndex = 5
        btnShadow.Parent = content
        
        local btnShadowCorner = Instance.new("UICorner")
        btnShadowCorner.CornerRadius = UDim.new(0, 16)
        btnShadowCorner.Parent = btnShadow
        
        -- Button main
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.48, 0, 0, 46)
        btn.Position = position
        btn.BackgroundColor3 = isPrimary and Color3.fromRGB(88, 101, 242) or Color3.fromRGB(50, 52, 65)
        btn.BorderSizePixel = 0
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 14
        btn.Font = Enum.Font.GothamBold
        btn.AutoButtonColor = false
        btn.ZIndex = 6
        btn.Parent = content
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 16)
        btnCorner.Parent = btn
        
        -- Top highlight for 3D effect
        local btnHighlight = Instance.new("Frame")
        btnHighlight.Size = UDim2.new(1, -8, 0.4, 0)
        btnHighlight.Position = UDim2.new(0, 4, 0, 4)
        btnHighlight.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        btnHighlight.BackgroundTransparency = 0.9
        btnHighlight.BorderSizePixel = 0
        btnHighlight.ZIndex = 7
        btnHighlight.Parent = btn
        
        local btnHighlightCorner = Instance.new("UICorner")
        btnHighlightCorner.CornerRadius = UDim.new(0, 13)
        btnHighlightCorner.Parent = btnHighlight
        
        -- Hover animation - "press down" effect
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {
                Position = position + UDim2.new(0, 0, 0, 2)
            }):Play()
            TweenService:Create(btnShadow, TweenInfo.new(0.15), {
                BackgroundTransparency = 0.75,
                Position = position + UDim2.new(0, 0, 0, 5)
            }):Play()
            if isPrimary then
                TweenService:Create(btn, TweenInfo.new(0.15), {
                    BackgroundColor3 = Color3.fromRGB(108, 121, 255)
                }):Play()
            else
                TweenService:Create(btn, TweenInfo.new(0.15), {
                    BackgroundColor3 = Color3.fromRGB(60, 62, 75)
                }):Play()
            end
        end)
        
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {
                Position = position
            }):Play()
            TweenService:Create(btnShadow, TweenInfo.new(0.15), {
                BackgroundTransparency = 0.6,
                Position = position + UDim2.new(0, 0, 0, 4)
            }):Play()
            if isPrimary then
                TweenService:Create(btn, TweenInfo.new(0.15), {
                    BackgroundColor3 = Color3.fromRGB(88, 101, 242)
                }):Play()
            else
                TweenService:Create(btn, TweenInfo.new(0.15), {
                    BackgroundColor3 = Color3.fromRGB(50, 52, 65)
                }):Play()
            end
        end)
        
        return btn, btnShadow
    end
    
    local submitBtn = createClayButton("Submit", UDim2.new(0, 0, 0, 65), true)
    local getKeyBtn = createClayButton("Get Key", UDim2.new(0.52, 0, 0, 65), false)
    
    -- Status
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, 0, 0, 20)
    status.Position = UDim2.new(0, 0, 0, 125)
    status.BackgroundTransparency = 1
    status.Text = ""
    status.TextColor3 = Color3.fromRGB(255, 100, 100)
    status.TextSize = 12
    status.Font = Enum.Font.Gotham
    status.TextTransparency = 1
    status.ZIndex = 6
    status.Parent = content
    
    -- Get Key action
    getKeyBtn.MouseButton1Click:Connect(function()
        setclipboard("https://your-website.com/getkey")
        
        getKeyText.Text = "✓ Copied!"
        TweenService:Create(getKeyBtn, TweenInfo.new(0.3), {
            BackgroundColor3 = Color3.fromRGB(50, 180, 120)
        }):Play()
        
        status.Text = "✓ Key URL copied to clipboard"
        status.TextColor3 = Color3.fromRGB(100, 255, 150)
        TweenService:Create(status, TweenInfo.new(0.2), {TextTransparency = 0}):Play()
        
        task.wait(2)
        getKeyText.Text = "Get Key"
        TweenService:Create(getKeyBtn, TweenInfo.new(0.3), {
            BackgroundColor3 = Color3.fromRGB(42, 48, 68)
        }):Play()
        TweenService:Create(status, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
    end)
    
    -- Submit action with loading animation
    submitBtn.MouseButton1Click:Connect(function()
        local key = input.Text
        
        if key == "" or #key < 5 then
            status.Text = "⚠ Please enter a valid key"
            status.TextColor3 = Color3.fromRGB(255, 140, 100)
            TweenService:Create(status, TweenInfo.new(0.2), {TextTransparency = 0}):Play()
            
            -- Shake with bounce
            for i = 1, 3 do
                TweenService:Create(inputContainer, TweenInfo.new(0.05, Enum.EasingStyle.Quad), {
                    Position = UDim2.new(0, (i % 2 == 0 and -8 or 8), 0, 0)
                }):Play()
                task.wait(0.05)
            end
            TweenService:Create(inputContainer, TweenInfo.new(0.1, Enum.EasingStyle.Elastic), {
                Position = UDim2.new(0, 0, 0, 0)
            }):Play()
            return
        end
        
        -- Loading state
        submitText.Text = "•••"
        TweenService:Create(submitBtn, TweenInfo.new(0.3), {
            BackgroundColor3 = Color3.fromRGB(70, 80, 100)
        }):Play()
        
        status.Text = "Verifying key..."
        status.TextColor3 = Color3.fromRGB(180, 190, 210)
        TweenService:Create(status, TweenInfo.new(0.2), {TextTransparency = 0}):Play()
        
        -- Animated loading dots
        local dotCount = 0
        local loadingAnimation = task.spawn(function()
            while submitText.Text ~= "✓ Success!" and submitText.Text ~= "Submit" do
                dotCount = (dotCount % 3) + 1
                submitText.Text = string.rep("•", dotCount) .. string.rep(" ", 3 - dotCount)
                task.wait(0.3)
            end
        end)
        
        task.spawn(function()
            local valid, message = verifyKeyRemote(key)
            
            task.cancel(loadingAnimation)
            
            if valid then
                submitText.Text = "✓ Success!"
                TweenService:Create(submitBtn, TweenInfo.new(0.3), {
                    BackgroundColor3 = Color3.fromRGB(50, 180, 120)
                }):Play()
                
                status.Text = "✓ Access granted! Loading..."
                status.TextColor3 = Color3.fromRGB(100, 255, 150)
                
                -- Success ripple effect
                for i = 1, 3 do
                    local ripple = Instance.new("Frame")
                    ripple.Size = UDim2.new(0, 0, 0, 0)
                    ripple.Position = UDim2.new(0.5, 0, 0.5, 0)
                    ripple.AnchorPoint = Vector2.new(0.5, 0.5)
                    ripple.BackgroundColor3 = Color3.fromRGB(100, 255, 150)
                    ripple.BackgroundTransparency = 0.5
                    ripple.BorderSizePixel = 0
                    ripple.ZIndex = 10
                    ripple.Parent = main
                    
                    local rippleCorner = Instance.new("UICorner")
                    rippleCorner.CornerRadius = UDim.new(1, 0)
                    rippleCorner.Parent = ripple
                    
                    task.wait(0.1 * i)
                    
                    TweenService:Create(ripple, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Size = UDim2.new(1, 100, 1, 100),
                        BackgroundTransparency = 1
                    }):Play()
                    
                    task.delay(0.8, function()
                        ripple:Destroy()
                    end)
                end
                
                task.wait(1)
                
                local session = createSession(key)
                
                -- Smooth fade out
                TweenService:Create(main, TweenInfo.new(0.4), {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0.5, -220, 0.5, -150)
                }):Play()
                TweenService:Create(mainStroke, TweenInfo.new(0.4), {
                    Transparency = 1
                }):Play()
                TweenService:Create(overlay, TweenInfo.new(0.4), {
                    BackgroundTransparency = 1
                }):Play()
                
                for _, glow in ipairs({glow1, glow2, glow3}) do
                    TweenService:Create(glow, TweenInfo.new(0.4), {
                        ImageTransparency = 1
                    }):Play()
                end
                
                task.wait(0.4)
                screenGui:Destroy()
                
                if callback then
                    callback(true, session)
                end
            else
                submitText.Text = "Submit"
                TweenService:Create(submitBtn, TweenInfo.new(0.3), {
                    BackgroundColor3 = Color3.fromRGB(88, 101, 242)
                }):Play()
                
                status.Text = "✗ " .. (message or "Invalid key")
                status.TextColor3 = Color3.fromRGB(255, 100, 100)
                
                -- Error shake
                for i = 1, 4 do
                    TweenService:Create(main, TweenInfo.new(0.04, Enum.EasingStyle.Quad), {
                        Position = UDim2.new(0.5, -220 + (i % 2 == 0 and -10 or 10), 0.5, -130)
                    }):Play()
                    task.wait(0.04)
                end
                TweenService:Create(main, TweenInfo.new(0.1, Enum.EasingStyle.Elastic), {
                    Position = UDim2.new(0.5, -220, 0.5, -130)
                }):Play()
            end
        end)
    end)
    
    -- Draggable
    local dragging, dragStart, startPos
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
        end
    end)
    
    header.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
            -- Move glows
            glow1.Position = main.Position + UDim2.new(0, -10, 0, -10)
            glow2.Position = main.Position + UDim2.new(0, -20, 0, -20)
            glow3.Position = main.Position + UDim2.new(0, -30, 0, -30)
        end
    end)
    
    -- Entry animations
    screenGui.Parent = playerGui
    
    -- Start invisible
    main.BackgroundTransparency = 1
    overlay.BackgroundTransparency = 1
    mainStroke.Transparency = 1
    title.TextTransparency = 1
    subtitle.TextTransparency = 1
    inputContainer.BackgroundTransparency = 1
    inputStroke.Transparency = 1
    
    for _, glow in ipairs({glow1, glow2, glow3}) do
        glow.ImageTransparency = 1
    end
    
    -- Animate in sequence
    TweenService:Create(overlay, TweenInfo.new(0.5), {
        BackgroundTransparency = 0
    }):Play()
    
    task.wait(0.1)
    
    -- Glows fade in
    TweenService:Create(glow3, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        ImageTransparency = 0.85
    }):Play()
    TweenService:Create(glow2, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        ImageTransparency = 0.9
    }):Play()
    TweenService:Create(glow1, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        ImageTransparency = 0.92
    }):Play()
    
    task.wait(0.2)
    
    -- Main frame scale in
    main.Size = UDim2.new(0, 0, 0, 0)
    main.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    TweenService:Create(main, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 440, 0, 260),
        Position = UDim2.new(0.5, -220, 0.5, -130),
        BackgroundTransparency = 0
    }):Play()
    
    TweenService:Create(mainStroke, TweenInfo.new(0.5), {
        Transparency = 0.7
    }):Play()
    
    task.wait(0.3)
    
    -- Content fade in
    TweenService:Create(title, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
    task.wait(0.1)
    TweenService:Create(subtitle, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
    task.wait(0.1)
    TweenService:Create(inputContainer, TweenInfo.new(0.4), {BackgroundTransparency = 0}):Play()
    TweenService:Create(inputStroke, TweenInfo.new(0.4), {Transparency = 0.6}):Play()
end

-- Main function to show key system
function CheckKeySystem.show(callback)
    -- ALWAYS show key UI for testing (no session cache)
    createKeyUI(callback)
end

-- Export for use in other scripts
return CheckKeySystem

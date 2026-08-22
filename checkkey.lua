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

-- Create UI for key input with beautiful animations
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
    
    -- Blur background effect
    local blurEffect = Instance.new("Frame")
    blurEffect.Name = "BlurBackground"
    blurEffect.Size = UDim2.new(1, 0, 1, 0)
    blurEffect.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    blurEffect.BackgroundTransparency = 0.5
    blurEffect.BorderSizePixel = 0
    blurEffect.Parent = screenGui
    
    -- Animated particles background
    local particlesFrame = Instance.new("Frame")
    particlesFrame.Name = "ParticlesFrame"
    particlesFrame.Size = UDim2.new(1, 0, 1, 0)
    particlesFrame.BackgroundTransparency = 1
    particlesFrame.Parent = screenGui
    
    -- Create floating particles
    for i = 1, 15 do
        local particle = Instance.new("Frame")
        particle.Size = UDim2.new(0, math.random(3, 8), 0, math.random(3, 8))
        particle.Position = UDim2.new(math.random(0, 100) / 100, 0, math.random(0, 100) / 100, 0)
        particle.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
        particle.BackgroundTransparency = math.random(60, 85) / 100
        particle.BorderSizePixel = 0
        particle.Parent = particlesFrame
        
        local particleCorner = Instance.new("UICorner")
        particleCorner.CornerRadius = UDim.new(1, 0)
        particleCorner.Parent = particle
        
        -- Animate particles
        task.spawn(function()
            while particle.Parent do
                local randomX = math.random(-50, 50)
                local randomY = math.random(-50, 50)
                local tweenInfo = TweenInfo.new(
                    math.random(3, 6),
                    Enum.EasingStyle.Sine,
                    Enum.EasingDirection.InOut,
                    -1,
                    true
                )
                local tween = TweenService:Create(particle, tweenInfo, {
                    Position = particle.Position + UDim2.new(0, randomX, 0, randomY)
                })
                tween:Play()
                wait(math.random(3, 6))
            end
        end)
    end
    
    -- Main Container with shadow
    local shadowFrame = Instance.new("Frame")
    shadowFrame.Name = "ShadowFrame"
    shadowFrame.Size = UDim2.new(0, 420, 0, 320)
    shadowFrame.Position = UDim2.new(0.5, -210, 0.5, -160)
    shadowFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadowFrame.BackgroundTransparency = 0.3
    shadowFrame.BorderSizePixel = 0
    shadowFrame.Parent = screenGui
    
    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, 20)
    shadowCorner.Parent = shadowFrame
    
    -- Main Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 410, 0, 310)
    mainFrame.Position = UDim2.new(0.5, -205, 0.5, -155)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 18)
    mainCorner.Parent = mainFrame
    
    -- Gradient overlay
    local gradient = Instance.new("Frame")
    gradient.Size = UDim2.new(1, 0, 1, 0)
    gradient.BackgroundTransparency = 1
    gradient.Parent = mainFrame
    
    local gradientUI = Instance.new("UIGradient")
    gradientUI.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 60, 90)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 30))
    }
    gradientUI.Rotation = 45
    gradientUI.Parent = mainFrame
    
    -- Animated gradient effect
    task.spawn(function()
        while mainFrame.Parent do
            for i = 0, 360, 2 do
                if not mainFrame.Parent then break end
                gradientUI.Rotation = i
                wait(0.05)
            end
        end
    end)
    
    -- Border glow effect
    local borderGlow = Instance.new("UIStroke")
    borderGlow.Color = Color3.fromRGB(100, 150, 255)
    borderGlow.Thickness = 2
    borderGlow.Transparency = 0.5
    borderGlow.Parent = mainFrame
    
    -- Animate border glow
    task.spawn(function()
        while mainFrame.Parent do
            TweenService:Create(borderGlow, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                Transparency = 0.2
            }):Play()
            wait(2)
        end
    end)
    
    -- Title Bar with gradient
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 70)
    titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    titleBar.BackgroundTransparency = 0.3
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 18)
    titleCorner.Parent = titleBar
    
    local titleGradient = Instance.new("UIGradient")
    titleGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 100, 200)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 50, 200))
    }
    titleGradient.Rotation = 90
    titleGradient.Parent = titleBar
    
    -- Logo/Icon
    local iconFrame = Instance.new("Frame")
    iconFrame.Size = UDim2.new(0, 50, 0, 50)
    iconFrame.Position = UDim2.new(0, 15, 0.5, -25)
    iconFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    iconFrame.BackgroundTransparency = 0.9
    iconFrame.BorderSizePixel = 0
    iconFrame.Parent = titleBar
    
    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(0, 12)
    iconCorner.Parent = iconFrame
    
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(1, 0, 1, 0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = "🐾"
    iconLabel.TextSize = 32
    iconLabel.Parent = iconFrame
    
    -- Title Text
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "TitleLabel"
    titleLabel.Size = UDim2.new(1, -80, 0, 30)
    titleLabel.Position = UDim2.new(0, 75, 0, 12)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "PawZHub Key System"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 22
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.TextTransparency = 1
    titleLabel.Parent = titleBar
    
    -- Subtitle
    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.Size = UDim2.new(1, -80, 0, 20)
    subtitleLabel.Position = UDim2.new(0, 75, 0, 42)
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Text = "Secure Authentication System"
    subtitleLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
    subtitleLabel.TextSize = 12
    subtitleLabel.Font = Enum.Font.Gotham
    subtitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    subtitleLabel.TextTransparency = 1
    subtitleLabel.Parent = titleBar
    
    -- Content Container
    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, -40, 1, -90)
    contentFrame.Position = UDim2.new(0, 20, 0, 80)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = mainFrame
    
    -- Key Input Label
    local inputLabel = Instance.new("TextLabel")
    inputLabel.Name = "InputLabel"
    inputLabel.Size = UDim2.new(1, 0, 0, 25)
    inputLabel.Position = UDim2.new(0, 0, 0, 10)
    inputLabel.BackgroundTransparency = 1
    inputLabel.Text = "🔑 Enter Your License Key"
    inputLabel.TextColor3 = Color3.fromRGB(220, 220, 240)
    inputLabel.TextSize = 14
    inputLabel.Font = Enum.Font.GothamBold
    inputLabel.TextXAlignment = Enum.TextXAlignment.Left
    inputLabel.TextTransparency = 1
    inputLabel.Parent = contentFrame
    
    -- Key Input Container
    local inputContainer = Instance.new("Frame")
    inputContainer.Size = UDim2.new(1, 0, 0, 50)
    inputContainer.Position = UDim2.new(0, 0, 0, 45)
    inputContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    inputContainer.BorderSizePixel = 0
    inputContainer.Parent = contentFrame
    
    local inputContainerCorner = Instance.new("UICorner")
    inputContainerCorner.CornerRadius = UDim.new(0, 12)
    inputContainerCorner.Parent = inputContainer
    
    local inputStroke = Instance.new("UIStroke")
    inputStroke.Color = Color3.fromRGB(60, 80, 150)
    inputStroke.Thickness = 1.5
    inputStroke.Transparency = 0.7
    inputStroke.Parent = inputContainer
    
    -- Key Input Box
    local keyInput = Instance.new("TextBox")
    keyInput.Name = "KeyInput"
    keyInput.Size = UDim2.new(1, -30, 1, -10)
    keyInput.Position = UDim2.new(0, 15, 0, 5)
    keyInput.BackgroundTransparency = 1
    keyInput.Text = ""
    keyInput.PlaceholderText = "PAWZ-XXXX-XXXX-XXXX"
    keyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    keyInput.PlaceholderColor3 = Color3.fromRGB(120, 120, 140)
    keyInput.TextSize = 16
    keyInput.Font = Enum.Font.GothamMedium
    keyInput.ClearTextOnFocus = false
    keyInput.TextTransparency = 1
    keyInput.Parent = inputContainer
    
    -- Input focus animation
    keyInput.Focused:Connect(function()
        TweenService:Create(inputStroke, TweenInfo.new(0.3), {
            Color = Color3.fromRGB(100, 150, 255),
            Transparency = 0.3,
            Thickness = 2
        }):Play()
    end)
    
    keyInput.FocusLost:Connect(function()
        TweenService:Create(inputStroke, TweenInfo.new(0.3), {
            Color = Color3.fromRGB(60, 80, 150),
            Transparency = 0.7,
            Thickness = 1.5
        }):Play()
    end)
    
    -- Buttons Container
    local buttonsFrame = Instance.new("Frame")
    buttonsFrame.Size = UDim2.new(1, 0, 0, 50)
    buttonsFrame.Position = UDim2.new(0, 0, 0, 115)
    buttonsFrame.BackgroundTransparency = 1
    buttonsFrame.Parent = contentFrame
    
    -- Submit Button
    local submitButton = Instance.new("TextButton")
    submitButton.Name = "SubmitButton"
    submitButton.Size = UDim2.new(0.48, 0, 1, 0)
    submitButton.Position = UDim2.new(0, 0, 0, 0)
    submitButton.BackgroundColor3 = Color3.fromRGB(70, 130, 255)
    submitButton.BorderSizePixel = 0
    submitButton.Text = "✓ Submit Key"
    submitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    submitButton.TextSize = 15
    submitButton.Font = Enum.Font.GothamBold
    submitButton.AutoButtonColor = false
    submitButton.Parent = buttonsFrame
    
    local submitCorner = Instance.new("UICorner")
    submitCorner.CornerRadius = UDim.new(0, 12)
    submitCorner.Parent = submitButton
    
    local submitGradient = Instance.new("UIGradient")
    submitGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 130, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 100, 200))
    }
    submitGradient.Rotation = 90
    submitGradient.Parent = submitButton
    
    -- Get Key Button
    local getKeyButton = Instance.new("TextButton")
    getKeyButton.Name = "GetKeyButton"
    getKeyButton.Size = UDim2.new(0.48, 0, 1, 0)
    getKeyButton.Position = UDim2.new(0.52, 0, 0, 0)
    getKeyButton.BackgroundColor3 = Color3.fromRGB(100, 100, 130)
    getKeyButton.BorderSizePixel = 0
    getKeyButton.Text = "🔗 Get Key"
    getKeyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    getKeyButton.TextSize = 15
    getKeyButton.Font = Enum.Font.GothamBold
    getKeyButton.AutoButtonColor = false
    getKeyButton.Parent = buttonsFrame
    
    local getKeyCorner = Instance.new("UICorner")
    getKeyCorner.CornerRadius = UDim.new(0, 12)
    getKeyCorner.Parent = getKeyButton
    
    local getKeyGradient = Instance.new("UIGradient")
    getKeyGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 100, 130)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 80, 110))
    }
    getKeyGradient.Rotation = 90
    getKeyGradient.Parent = getKeyButton
    
    -- Status Label
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Name = "StatusLabel"
    statusLabel.Size = UDim2.new(1, 0, 0, 30)
    statusLabel.Position = UDim2.new(0, 0, 0, 180)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = ""
    statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    statusLabel.TextSize = 13
    statusLabel.Font = Enum.Font.GothamMedium
    statusLabel.TextXAlignment = Enum.TextXAlignment.Center
    statusLabel.TextTransparency = 1
    statusLabel.Parent = contentFrame
    
    -- Loading spinner
    local spinner = Instance.new("Frame")
    spinner.Name = "Spinner"
    spinner.Size = UDim2.new(0, 20, 0, 20)
    spinner.Position = UDim2.new(0.5, -10, 0, 5)
    spinner.BackgroundTransparency = 1
    spinner.Visible = false
    spinner.Parent = statusLabel
    
    for i = 1, 8 do
        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0, 3, 0, 3)
        dot.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
        dot.BorderSizePixel = 0
        dot.AnchorPoint = Vector2.new(0.5, 0.5)
        
        local angle = (i - 1) * (360 / 8)
        local rad = math.rad(angle)
        dot.Position = UDim2.new(0.5, math.sin(rad) * 8, 0.5, -math.cos(rad) * 8)
        
        local dotCorner = Instance.new("UICorner")
        dotCorner.CornerRadius = UDim.new(1, 0)
        dotCorner.Parent = dot
        
        dot.Parent = spinner
        
        task.spawn(function()
            while spinner.Visible do
                local delay = (i - 1) * 0.1
                wait(delay)
                while spinner.Visible do
                    TweenService:Create(dot, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {
                        BackgroundTransparency = 0.8
                    }):Play()
                    wait(0.4)
                    TweenService:Create(dot, TweenInfo.new(0.4, Enum.EasingStyle.Sine), {
                        BackgroundTransparency = 0
                    }):Play()
                    wait(0.4)
                end
            end
        end)
    end
    
    -- Button hover effects with animations
    local function addButtonEffect(button)
        local originalSize = button.Size
        
        button.MouseEnter:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset, originalSize.Y.Scale, originalSize.Y.Offset + 4)
            }):Play()
            
            if button.Name == "SubmitButton" then
                TweenService:Create(button, TweenInfo.new(0.2), {
                    BackgroundColor3 = Color3.fromRGB(90, 150, 255)
                }):Play()
            else
                TweenService:Create(button, TweenInfo.new(0.2), {
                    BackgroundColor3 = Color3.fromRGB(120, 120, 150)
                }):Play()
            end
        end)
        
        button.MouseLeave:Connect(function()
            TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                Size = originalSize
            }):Play()
            
            if button.Name == "SubmitButton" then
                TweenService:Create(button, TweenInfo.new(0.2), {
                    BackgroundColor3 = Color3.fromRGB(70, 130, 255)
                }):Play()
            else
                TweenService:Create(button, TweenInfo.new(0.2), {
                    BackgroundColor3 = Color3.fromRGB(100, 100, 130)
                }):Play()
            end
        end)
    end
    
    addButtonEffect(submitButton)
    addButtonEffect(getKeyButton)
    
    -- Get Key button action
    getKeyButton.MouseButton1Click:Connect(function()
        local keyUrl = "https://your-website.com/getkey"
        setclipboard(keyUrl)
        
        -- Success animation
        local originalText = getKeyButton.Text
        getKeyButton.Text = "✓ Copied!"
        
        TweenService:Create(getKeyButton, TweenInfo.new(0.3), {
            BackgroundColor3 = Color3.fromRGB(50, 200, 100)
        }):Play()
        
        statusLabel.Text = "✓ Key URL copied to clipboard!"
        statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        TweenService:Create(statusLabel, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
        
        wait(2)
        
        getKeyButton.Text = originalText
        TweenService:Create(getKeyButton, TweenInfo.new(0.3), {
            BackgroundColor3 = Color3.fromRGB(100, 100, 130)
        }):Play()
        
        TweenService:Create(statusLabel, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
    end)
    
    -- Submit button action
    submitButton.MouseButton1Click:Connect(function()
        local key = keyInput.Text
        
        if key == "" or #key < 5 then
            statusLabel.Text = "⚠️ Please enter a valid key"
            statusLabel.TextColor3 = Color3.fromRGB(255, 150, 100)
            TweenService:Create(statusLabel, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
            
            -- Shake animation
            local originalPos = inputContainer.Position
            for i = 1, 3 do
                TweenService:Create(inputContainer, TweenInfo.new(0.05), {
                    Position = originalPos + UDim2.new(0, 5, 0, 0)
                }):Play()
                wait(0.05)
                TweenService:Create(inputContainer, TweenInfo.new(0.05), {
                    Position = originalPos + UDim2.new(0, -5, 0, 0)
                }):Play()
                wait(0.05)
            end
            TweenService:Create(inputContainer, TweenInfo.new(0.05), {
                Position = originalPos
            }):Play()
            return
        end
        
        -- Show loading
        spinner.Visible = true
        statusLabel.Text = "      Verifying key..."
        statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
        TweenService:Create(statusLabel, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
        
        submitButton.Text = "⏳ Checking..."
        TweenService:Create(submitButton, TweenInfo.new(0.3), {
            BackgroundColor3 = Color3.fromRGB(100, 100, 100)
        }):Play()
        
        -- Verify key
        task.spawn(function()
            local valid, message = verifyKeyRemote(key)
            
            spinner.Visible = false
            
            if valid then
                statusLabel.Text = "✓ Key verified successfully!"
                statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
                submitButton.Text = "✓ Success!"
                
                TweenService:Create(submitButton, TweenInfo.new(0.3), {
                    BackgroundColor3 = Color3.fromRGB(50, 200, 100)
                }):Play()
                
                -- Success particles
                for i = 1, 20 do
                    local particle = Instance.new("Frame")
                    particle.Size = UDim2.new(0, 6, 0, 6)
                    particle.Position = UDim2.new(0.5, 0, 0.5, 0)
                    particle.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
                    particle.BorderSizePixel = 0
                    particle.AnchorPoint = Vector2.new(0.5, 0.5)
                    particle.Parent = mainFrame
                    
                    local particleCorner = Instance.new("UICorner")
                    particleCorner.CornerRadius = UDim.new(1, 0)
                    particleCorner.Parent = particle
                    
                    local angle = math.random(0, 360)
                    local distance = math.random(100, 200)
                    local endPos = UDim2.new(
                        0.5, math.cos(math.rad(angle)) * distance,
                        0.5, math.sin(math.rad(angle)) * distance
                    )
                    
                    local tween = TweenService:Create(particle, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Position = endPos,
                        BackgroundTransparency = 1
                    })
                    tween:Play()
                    
                    task.delay(1, function()
                        particle:Destroy()
                    end)
                end
                
                wait(1.5)
                
                -- Create session
                local session = createSession(key)
                
                -- Fade out animation
                TweenService:Create(mainFrame, TweenInfo.new(0.5), {
                    BackgroundTransparency = 1
                }):Play()
                TweenService:Create(shadowFrame, TweenInfo.new(0.5), {
                    BackgroundTransparency = 1
                }):Play()
                TweenService:Create(blurEffect, TweenInfo.new(0.5), {
                    BackgroundTransparency = 1
                }):Play()
                
                wait(0.5)
                screenGui:Destroy()
                
                -- Callback with success
                if callback then
                    callback(true, session)
                end
            else
                statusLabel.Text = "✗ " .. (message or "Invalid key")
                statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
                submitButton.Text = "✓ Submit Key"
                
                TweenService:Create(submitButton, TweenInfo.new(0.3), {
                    BackgroundColor3 = Color3.fromRGB(70, 130, 255)
                }):Play()
                
                -- Error shake
                local originalPos = mainFrame.Position
                for i = 1, 2 do
                    TweenService:Create(mainFrame, TweenInfo.new(0.05), {
                        Position = originalPos + UDim2.new(0, 10, 0, 0)
                    }):Play()
                    wait(0.05)
                    TweenService:Create(mainFrame, TweenInfo.new(0.05), {
                        Position = originalPos + UDim2.new(0, -10, 0, 0)
                    }):Play()
                    wait(0.05)
                end
                TweenService:Create(mainFrame, TweenInfo.new(0.05), {
                    Position = originalPos
                }):Play()
            end
        end)
    end)
    
    -- Make draggable
    local dragging = false
    local dragInput, mousePos, framePos
    
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            mousePos = input.Position
            framePos = mainFrame.Position
        end
    end)
    
    titleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    game:GetService("RunService").RenderStepped:Connect(function()
        if dragging and dragInput then
            local delta = dragInput.Position - mousePos
            local newPos = UDim2.new(
                framePos.X.Scale,
                framePos.X.Offset + delta.X,
                framePos.Y.Scale,
                framePos.Y.Offset + delta.Y
            )
            
            TweenService:Create(mainFrame, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
                Position = newPos
            }):Play()
            TweenService:Create(shadowFrame, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
                Position = newPos + UDim2.new(0, 5, 0, 5)
            }):Play()
        end
    end)
    
    -- Entry animations
    screenGui.Parent = playerGui
    
    blurEffect.BackgroundTransparency = 1
    TweenService:Create(blurEffect, TweenInfo.new(0.5), {
        BackgroundTransparency = 0.5
    }):Play()
    
    mainFrame.Size = UDim2.new(0, 0, 0, 0)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    shadowFrame.Size = UDim2.new(0, 0, 0, 0)
    shadowFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    TweenService:Create(shadowFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 420, 0, 320),
        Position = UDim2.new(0.5, -210, 0.5, -160)
    }):Play()
    
    TweenService:Create(mainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 410, 0, 310),
        Position = UDim2.new(0.5, -205, 0.5, -155)
    }):Play()
    
    wait(0.3)
    
    -- Fade in content
    TweenService:Create(titleLabel, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
    wait(0.1)
    TweenService:Create(subtitleLabel, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
    wait(0.1)
    TweenService:Create(inputLabel, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
    wait(0.1)
    TweenService:Create(keyInput, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
end

-- Main function to show key system
function CheckKeySystem.show(callback)
    -- Check if session already exists and is valid
    local valid, sessionOrError = CheckKeySystem.verifySession()
    
    if valid then
        print("Valid session found, skipping key check")
        if callback then
            callback(true, sessionOrError)
        end
        return
    end
    
    -- Show UI for key input
    createKeyUI(callback)
end

-- Export for use in other scripts
return CheckKeySystem

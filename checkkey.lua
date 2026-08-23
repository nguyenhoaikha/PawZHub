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

-- Create UI for key input - Neomorphism/Clay design with 3D depth
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
    
    -- Background overlay with gradient
    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(30, 32, 42)
    overlay.BorderSizePixel = 0
    overlay.Parent = screenGui
    
    local overlayGradient = Instance.new("UIGradient")
    overlayGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 37, 50)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 27, 38))
    }
    overlayGradient.Rotation = 135
    overlayGradient.Parent = overlay
    
    -- Deep shadow layer 1 (darkest, furthest)
    local shadow1 = Instance.new("Frame")
    shadow1.Size = UDim2.new(0, 440, 0, 260)
    shadow1.Position = UDim2.new(0.5, -220, 0.5, -130)
    shadow1.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow1.BackgroundTransparency = 0.7
    shadow1.BorderSizePixel = 0
    shadow1.ZIndex = 1
    shadow1.Parent = screenGui
    
    local shadow1Corner = Instance.new("UICorner")
    shadow1Corner.CornerRadius = UDim.new(0, 30)
    shadow1Corner.Parent = shadow1
    
    -- Medium shadow layer 2
    local shadow2 = Instance.new("Frame")
    shadow2.Size = UDim2.new(0, 435, 0, 255)
    shadow2.Position = UDim2.new(0.5, -217, 0.5, -127)
    shadow2.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow2.BackgroundTransparency = 0.5
    shadow2.BorderSizePixel = 0
    shadow2.ZIndex = 2
    shadow2.Parent = screenGui
    
    local shadow2Corner = Instance.new("UICorner")
    shadow2Corner.CornerRadius = UDim.new(0, 28)
    shadow2Corner.Parent = shadow2
    
    -- Light shadow layer 3 (closest to main)
    local shadow3 = Instance.new("Frame")
    shadow3.Size = UDim2.new(0, 430, 0, 250)
    shadow3.Position = UDim2.new(0.5, -215, 0.5, -125)
    shadow3.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow3.BackgroundTransparency = 0.3
    shadow3.BorderSizePixel = 0
    shadow3.ZIndex = 3
    shadow3.Parent = screenGui
    
    local shadow3Corner = Instance.new("UICorner")
    shadow3Corner.CornerRadius = UDim.new(0, 26)
    shadow3Corner.Parent = shadow3
    
    -- Main container - clay/soft plastic material
    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 420, 0, 240)
    main.Position = UDim2.new(0.5, -210, 0.5, -120)
    main.BackgroundColor3 = Color3.fromRGB(40, 42, 54)
    main.BorderSizePixel = 0
    main.ZIndex = 4
    main.Parent = screenGui
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 24)
    mainCorner.Parent = main
    
    -- Inner glow/highlight (top light)
    local innerGlow = Instance.new("Frame")
    innerGlow.Size = UDim2.new(1, -6, 0.5, -3)
    innerGlow.Position = UDim2.new(0, 3, 0, 3)
    innerGlow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    innerGlow.BackgroundTransparency = 0.95
    innerGlow.BorderSizePixel = 0
    innerGlow.ZIndex = 5
    innerGlow.Parent = main
    
    local innerGlowCorner = Instance.new("UICorner")
    innerGlowCorner.CornerRadius = UDim.new(0, 22)
    innerGlowCorner.Parent = innerGlow
    
    -- Subtle gradient on main frame
    local mainGradient = Instance.new("UIGradient")
    mainGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(48, 50, 64)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(38, 40, 52))
    }
    mainGradient.Rotation = 135
    mainGradient.Parent = main
    
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
        
        getKeyBtn.Text = "Copied"
        TweenService:Create(getKeyBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(35, 160, 90)
        }):Play()
        
        status.Text = "Key URL copied to clipboard"
        status.TextColor3 = Color3.fromRGB(100, 220, 150)
        TweenService:Create(status, TweenInfo.new(0.2), {TextTransparency = 0}):Play()
        
        wait(2)
        getKeyBtn.Text = "Get Key"
        TweenService:Create(getKeyBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(50, 52, 65)
        }):Play()
        TweenService:Create(status, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
    end)
    
    -- Submit action
    submitBtn.MouseButton1Click:Connect(function()
        local key = input.Text
        
        if key == "" or #key < 5 then
            status.Text = "Please enter a valid key"
            status.TextColor3 = Color3.fromRGB(255, 120, 120)
            TweenService:Create(status, TweenInfo.new(0.2), {TextTransparency = 0}):Play()
            
            -- Shake animation
            for i = 1, 2 do
                inputOuter.Position = UDim2.new(0, 5, 0, 0)
                wait(0.04)
                inputOuter.Position = UDim2.new(0, -5, 0, 0)
                wait(0.04)
            end
            inputOuter.Position = UDim2.new(0, 0, 0, 0)
            return
        end
        
        submitBtn.Text = "Verifying..."
        TweenService:Create(submitBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(70, 70, 80)
        }):Play()
        
        status.Text = "Checking key..."
        status.TextColor3 = Color3.fromRGB(180, 180, 190)
        TweenService:Create(status, TweenInfo.new(0.2), {TextTransparency = 0}):Play()
        
        task.spawn(function()
            local valid, message = verifyKeyRemote(key)
            
            if valid then
                submitBtn.Text = "Success"
                TweenService:Create(submitBtn, TweenInfo.new(0.2), {
                    BackgroundColor3 = Color3.fromRGB(35, 160, 90)
                }):Play()
                
                status.Text = "Access granted"
                status.TextColor3 = Color3.fromRGB(100, 220, 150)
                
                wait(0.8)
                
                local session = createSession(key)
                
                -- Fade out all layers
                TweenService:Create(main, TweenInfo.new(0.3), {
                    BackgroundTransparency = 1
                }):Play()
                TweenService:Create(shadow1, TweenInfo.new(0.3), {
                    BackgroundTransparency = 1
                }):Play()
                TweenService:Create(shadow2, TweenInfo.new(0.3), {
                    BackgroundTransparency = 1
                }):Play()
                TweenService:Create(shadow3, TweenInfo.new(0.3), {
                    BackgroundTransparency = 1
                }):Play()
                TweenService:Create(overlay, TweenInfo.new(0.3), {
                    BackgroundTransparency = 1
                }):Play()
                
                wait(0.3)
                screenGui:Destroy()
                
                if callback then
                    callback(true, session)
                end
            else
                submitBtn.Text = "Submit"
                TweenService:Create(submitBtn, TweenInfo.new(0.2), {
                    BackgroundColor3 = Color3.fromRGB(88, 101, 242)
                }):Play()
                
                status.Text = message or "Invalid key"
                status.TextColor3 = Color3.fromRGB(255, 100, 100)
                
                -- Shake main frame
                for i = 1, 2 do
                    main.Position = UDim2.new(0.5, -210 + 8, 0.5, -120)
                    shadow1.Position = UDim2.new(0.5, -220 + 8, 0.5, -130)
                    shadow2.Position = UDim2.new(0.5, -217 + 8, 0.5, -127)
                    shadow3.Position = UDim2.new(0.5, -215 + 8, 0.5, -125)
                    wait(0.04)
                    main.Position = UDim2.new(0.5, -210 - 8, 0.5, -120)
                    shadow1.Position = UDim2.new(0.5, -220 - 8, 0.5, -130)
                    shadow2.Position = UDim2.new(0.5, -217 - 8, 0.5, -127)
                    shadow3.Position = UDim2.new(0.5, -215 - 8, 0.5, -125)
                    wait(0.04)
                end
                main.Position = UDim2.new(0.5, -210, 0.5, -120)
                shadow1.Position = UDim2.new(0.5, -220, 0.5, -130)
                shadow2.Position = UDim2.new(0.5, -217, 0.5, -127)
                shadow3.Position = UDim2.new(0.5, -215, 0.5, -125)
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
            -- Move shadows along
            shadow1.Position = main.Position + UDim2.new(0, -10, 0, -10)
            shadow2.Position = main.Position + UDim2.new(0, -7, 0, -7)
            shadow3.Position = main.Position + UDim2.new(0, -5, 0, -5)
        end
    end)
    
    -- Entry animation with 3D depth
    screenGui.Parent = playerGui
    
    -- Start all invisible
    main.BackgroundTransparency = 1
    shadow1.BackgroundTransparency = 1
    shadow2.BackgroundTransparency = 1
    shadow3.BackgroundTransparency = 1
    
    -- Fade in background
    TweenService:Create(overlay, TweenInfo.new(0.4), {
        BackgroundTransparency = 0
    }):Play()
    
    wait(0.1)
    
    -- Animate shadows appearing in sequence (depth effect)
    TweenService:Create(shadow1, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.7,
        Position = UDim2.new(0.5, -220, 0.5, -130)
    }):Play()
    
    wait(0.05)
    
    TweenService:Create(shadow2, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.5,
        Position = UDim2.new(0.5, -217, 0.5, -127)
    }):Play()
    
    wait(0.05)
    
    TweenService:Create(shadow3, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0.3,
        Position = UDim2.new(0.5, -215, 0.5, -125)
    }):Play()
    
    wait(0.05)
    
    -- Main frame pop-in with bounce
    TweenService:Create(main, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        BackgroundTransparency = 0,
        Position = UDim2.new(0.5, -210, 0.5, -120)
    }):Play()
end

-- Main function to show key system
function CheckKeySystem.show(callback)
    -- ALWAYS show key UI for testing (no session cache)
    createKeyUI(callback)
end

-- Export for use in other scripts
return CheckKeySystem

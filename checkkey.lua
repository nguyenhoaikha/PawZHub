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

-- Create UI for key input - Modern clean design
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
    
    -- Background overlay
    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.4
    overlay.BorderSizePixel = 0
    overlay.Parent = screenGui
    
    -- Main container
    local main = Instance.new("Frame")
    main.Size = UDim2.new(0, 420, 0, 240)
    main.Position = UDim2.new(0.5, -210, 0.5, -120)
    main.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    main.BorderSizePixel = 0
    main.Parent = screenGui
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = main
    
    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Color3.fromRGB(45, 45, 55)
    mainStroke.Thickness = 1
    mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    mainStroke.Parent = main
    
    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 60)
    header.BackgroundTransparency = 1
    header.Parent = main
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -40, 0, 24)
    title.Position = UDim2.new(0, 20, 0, 12)
    title.BackgroundTransparency = 1
    title.Text = "PawZHub Key System"
    title.TextColor3 = Color3.fromRGB(245, 245, 250)
    title.TextSize = 18
    title.Font = Enum.Font.Gotham
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, -40, 0, 16)
    subtitle.Position = UDim2.new(0, 20, 0, 38)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Enter your license key to continue"
    subtitle.TextColor3 = Color3.fromRGB(140, 140, 150)
    subtitle.TextSize = 12
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
    -- Content
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -40, 1, -80)
    content.Position = UDim2.new(0, 20, 0, 70)
    content.BackgroundTransparency = 1
    content.Parent = main
    
    -- Input field
    local inputFrame = Instance.new("Frame")
    inputFrame.Size = UDim2.new(1, 0, 0, 44)
    inputFrame.Position = UDim2.new(0, 0, 0, 10)
    inputFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    inputFrame.BorderSizePixel = 0
    inputFrame.Parent = content
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 8)
    inputCorner.Parent = inputFrame
    
    local inputStroke = Instance.new("UIStroke")
    inputStroke.Color = Color3.fromRGB(50, 50, 60)
    inputStroke.Thickness = 1
    inputStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    inputStroke.Parent = inputFrame
    
    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1, -20, 1, 0)
    input.Position = UDim2.new(0, 10, 0, 0)
    input.BackgroundTransparency = 1
    input.Text = ""
    input.PlaceholderText = "Enter key here..."
    input.TextColor3 = Color3.fromRGB(240, 240, 245)
    input.PlaceholderColor3 = Color3.fromRGB(100, 100, 110)
    input.TextSize = 14
    input.Font = Enum.Font.Gotham
    input.ClearTextOnFocus = false
    input.Parent = inputFrame
    
    -- Focus animation
    input.Focused:Connect(function()
        TweenService:Create(inputStroke, TweenInfo.new(0.2), {
            Color = Color3.fromRGB(88, 101, 242),
            Thickness = 2
        }):Play()
    end)
    
    input.FocusLost:Connect(function()
        TweenService:Create(inputStroke, TweenInfo.new(0.2), {
            Color = Color3.fromRGB(50, 50, 60),
            Thickness = 1
        }):Play()
    end)
    
    -- Buttons
    local submitBtn = Instance.new("TextButton")
    submitBtn.Size = UDim2.new(0.48, 0, 0, 40)
    submitBtn.Position = UDim2.new(0, 0, 0, 70)
    submitBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
    submitBtn.BorderSizePixel = 0
    submitBtn.Text = "Submit"
    submitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    submitBtn.TextSize = 14
    submitBtn.Font = Enum.Font.GothamMedium
    submitBtn.AutoButtonColor = false
    submitBtn.Parent = content
    
    local submitCorner = Instance.new("UICorner")
    submitCorner.CornerRadius = UDim.new(0, 8)
    submitCorner.Parent = submitBtn
    
    local getKeyBtn = Instance.new("TextButton")
    getKeyBtn.Size = UDim2.new(0.48, 0, 0, 40)
    getKeyBtn.Position = UDim2.new(0.52, 0, 0, 70)
    getKeyBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    getKeyBtn.BorderSizePixel = 0
    getKeyBtn.Text = "Get Key"
    getKeyBtn.TextColor3 = Color3.fromRGB(200, 200, 210)
    getKeyBtn.TextSize = 14
    getKeyBtn.Font = Enum.Font.GothamMedium
    getKeyBtn.AutoButtonColor = false
    getKeyBtn.Parent = content
    
    local getKeyCorner = Instance.new("UICorner")
    getKeyCorner.CornerRadius = UDim.new(0, 8)
    getKeyCorner.Parent = getKeyBtn
    
    local getKeyStroke = Instance.new("UIStroke")
    getKeyStroke.Color = Color3.fromRGB(55, 55, 65)
    getKeyStroke.Thickness = 1
    getKeyStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    getKeyStroke.Parent = getKeyBtn
    
    -- Status
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, 0, 0, 20)
    status.Position = UDim2.new(0, 0, 0, 125)
    status.BackgroundTransparency = 1
    status.Text = ""
    status.TextColor3 = Color3.fromRGB(255, 100, 100)
    status.TextSize = 11
    status.Font = Enum.Font.Gotham
    status.TextTransparency = 1
    status.Parent = content
    
    -- Hover effects
    submitBtn.MouseEnter:Connect(function()
        TweenService:Create(submitBtn, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(108, 121, 255)
        }):Play()
    end)
    
    submitBtn.MouseLeave:Connect(function()
        TweenService:Create(submitBtn, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(88, 101, 242)
        }):Play()
    end)
    
    getKeyBtn.MouseEnter:Connect(function()
        TweenService:Create(getKeyBtn, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(45, 45, 55)
        }):Play()
    end)
    
    getKeyBtn.MouseLeave:Connect(function()
        TweenService:Create(getKeyBtn, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(35, 35, 45)
        }):Play()
    end)
    
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
            BackgroundColor3 = Color3.fromRGB(35, 35, 45)
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
            
            -- Shake
            for i = 1, 2 do
                inputFrame.Position = UDim2.new(0, 5, 0, 10)
                wait(0.05)
                inputFrame.Position = UDim2.new(0, -5, 0, 10)
                wait(0.05)
            end
            inputFrame.Position = UDim2.new(0, 0, 0, 10)
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
                
                TweenService:Create(main, TweenInfo.new(0.25), {
                    BackgroundTransparency = 1
                }):Play()
                TweenService:Create(overlay, TweenInfo.new(0.25), {
                    BackgroundTransparency = 1
                }):Play()
                
                wait(0.25)
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
                
                -- Shake
                for i = 1, 2 do
                    main.Position = UDim2.new(0.5, -210 + 8, 0.5, -120)
                    wait(0.04)
                    main.Position = UDim2.new(0.5, -210 - 8, 0.5, -120)
                    wait(0.04)
                end
                main.Position = UDim2.new(0.5, -210, 0.5, -120)
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
        end
    end)
    
    -- Entry animation
    screenGui.Parent = playerGui
    
    overlay.BackgroundTransparency = 1
    TweenService:Create(overlay, TweenInfo.new(0.25), {
        BackgroundTransparency = 0.4
    }):Play()
    
    main.Size = UDim2.new(0, 0, 0, 0)
    main.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    TweenService:Create(main, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
        Size = UDim2.new(0, 420, 0, 240),
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

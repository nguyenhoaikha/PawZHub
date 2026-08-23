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

-- Create UI for key input - Clean and minimal design
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
    
    -- Dark blur background
    local blurBg = Instance.new("Frame")
    blurBg.Size = UDim2.new(1, 0, 1, 0)
    blurBg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    blurBg.BackgroundTransparency = 0.3
    blurBg.BorderSizePixel = 0
    blurBg.Parent = screenGui
    
    -- Main Frame
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 450, 0, 280)
    mainFrame.Position = UDim2.new(0.5, -225, 0.5, -140)
    mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 16)
    mainCorner.Parent = mainFrame
    
    -- Subtle border
    local border = Instance.new("UIStroke")
    border.Color = Color3.fromRGB(60, 60, 70)
    border.Thickness = 1
    border.Transparency = 0.5
    border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    border.Parent = mainFrame
    
    -- Header section
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 80)
    header.BackgroundTransparency = 1
    header.Parent = mainFrame
    
    -- Logo container
    local logoContainer = Instance.new("Frame")
    logoContainer.Size = UDim2.new(0, 50, 0, 50)
    logoContainer.Position = UDim2.new(0, 30, 0, 15)
    logoContainer.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    logoContainer.BorderSizePixel = 0
    logoContainer.Parent = header
    
    local logoCorner = Instance.new("UICorner")
    logoCorner.CornerRadius = UDim.new(0, 12)
    logoCorner.Parent = logoContainer
    
    local logoStroke = Instance.new("UIStroke")
    logoStroke.Color = Color3.fromRGB(255, 100, 80)
    logoStroke.Thickness = 2
    logoStroke.Transparency = 0.3
    logoStroke.Parent = logoContainer
    
    local logo = Instance.new("TextLabel")
    logo.Size = UDim2.new(1, 0, 1, 0)
    logo.BackgroundTransparency = 1
    logo.Text = "🐾"
    logo.TextSize = 28
    logo.Parent = logoContainer
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -110, 0, 28)
    title.Position = UDim2.new(0, 95, 0, 18)
    title.BackgroundTransparency = 1
    title.Text = "PawZHub Key System"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 20
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
    -- Subtitle
    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(1, -110, 0, 18)
    subtitle.Position = UDim2.new(0, 95, 0, 47)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "Secure Authentication System"
    subtitle.TextColor3 = Color3.fromRGB(150, 150, 160)
    subtitle.TextSize = 12
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Parent = header
    
    -- Content area
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -60, 1, -100)
    content.Position = UDim2.new(0, 30, 0, 90)
    content.BackgroundTransparency = 1
    content.Parent = mainFrame
    
    -- Input label
    local inputLabel = Instance.new("TextLabel")
    inputLabel.Size = UDim2.new(1, 0, 0, 20)
    inputLabel.BackgroundTransparency = 1
    inputLabel.Text = "🔑 Enter Your License Key"
    inputLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
    inputLabel.TextSize = 13
    inputLabel.Font = Enum.Font.GothamMedium
    inputLabel.TextXAlignment = Enum.TextXAlignment.Left
    inputLabel.Parent = content
    
    -- Input container
    local inputBox = Instance.new("Frame")
    inputBox.Size = UDim2.new(1, 0, 0, 48)
    inputBox.Position = UDim2.new(0, 0, 0, 30)
    inputBox.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    inputBox.BorderSizePixel = 0
    inputBox.Parent = content
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 10)
    inputCorner.Parent = inputBox
    
    local inputStroke = Instance.new("UIStroke")
    inputStroke.Color = Color3.fromRGB(50, 50, 60)
    inputStroke.Thickness = 1
    inputStroke.Transparency = 0.5
    inputStroke.Parent = inputBox
    
    -- Text input
    local keyInput = Instance.new("TextBox")
    keyInput.Size = UDim2.new(1, -20, 1, 0)
    keyInput.Position = UDim2.new(0, 10, 0, 0)
    keyInput.BackgroundTransparency = 1
    keyInput.Text = ""
    keyInput.PlaceholderText = "PAWZ-XXXX-XXXX-XXXX"
    keyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    keyInput.PlaceholderColor3 = Color3.fromRGB(100, 100, 110)
    keyInput.TextSize = 15
    keyInput.Font = Enum.Font.GothamMedium
    keyInput.ClearTextOnFocus = false
    keyInput.Parent = inputBox
    
    -- Input focus effect
    keyInput.Focused:Connect(function()
        TweenService:Create(inputStroke, TweenInfo.new(0.2), {
            Color = Color3.fromRGB(255, 100, 80),
            Transparency = 0.2,
            Thickness = 2
        }):Play()
    end)
    
    keyInput.FocusLost:Connect(function()
        TweenService:Create(inputStroke, TweenInfo.new(0.2), {
            Color = Color3.fromRGB(50, 50, 60),
            Transparency = 0.5,
            Thickness = 1
        }):Play()
    end)
    
    -- Buttons
    local btnSubmit = Instance.new("TextButton")
    btnSubmit.Size = UDim2.new(0.48, 0, 0, 44)
    btnSubmit.Position = UDim2.new(0, 0, 0, 90)
    btnSubmit.BackgroundColor3 = Color3.fromRGB(70, 120, 255)
    btnSubmit.BorderSizePixel = 0
    btnSubmit.Text = "✓ Submit Key"
    btnSubmit.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnSubmit.TextSize = 14
    btnSubmit.Font = Enum.Font.GothamBold
    btnSubmit.AutoButtonColor = false
    btnSubmit.Parent = content
    
    local btnSubmitCorner = Instance.new("UICorner")
    btnSubmitCorner.CornerRadius = UDim.new(0, 10)
    btnSubmitCorner.Parent = btnSubmit
    
    local btnGetKey = Instance.new("TextButton")
    btnGetKey.Size = UDim2.new(0.48, 0, 0, 44)
    btnGetKey.Position = UDim2.new(0.52, 0, 0, 90)
    btnGetKey.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    btnGetKey.BorderSizePixel = 0
    btnGetKey.Text = "🔗 Get Key"
    btnGetKey.TextColor3 = Color3.fromRGB(220, 220, 230)
    btnGetKey.TextSize = 14
    btnGetKey.Font = Enum.Font.GothamBold
    btnGetKey.AutoButtonColor = false
    btnGetKey.Parent = content
    
    local btnGetKeyCorner = Instance.new("UICorner")
    btnGetKeyCorner.CornerRadius = UDim.new(0, 10)
    btnGetKeyCorner.Parent = btnGetKey
    
    local btnGetKeyStroke = Instance.new("UIStroke")
    btnGetKeyStroke.Color = Color3.fromRGB(70, 70, 80)
    btnGetKeyStroke.Thickness = 1
    btnGetKeyStroke.Transparency = 0.5
    btnGetKeyStroke.Parent = btnGetKey
    
    -- Status label
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, 0, 0, 25)
    status.Position = UDim2.new(0, 0, 0, 145)
    status.BackgroundTransparency = 1
    status.Text = ""
    status.TextColor3 = Color3.fromRGB(255, 100, 100)
    status.TextSize = 12
    status.Font = Enum.Font.GothamMedium
    status.TextTransparency = 1
    status.Parent = content
    
    -- Hover effects
    btnSubmit.MouseEnter:Connect(function()
        TweenService:Create(btnSubmit, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(90, 140, 255)
        }):Play()
    end)
    
    btnSubmit.MouseLeave:Connect(function()
        TweenService:Create(btnSubmit, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(70, 120, 255)
        }):Play()
    end)
    
    btnGetKey.MouseEnter:Connect(function()
        TweenService:Create(btnGetKey, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        }):Play()
    end)
    
    btnGetKey.MouseLeave:Connect(function()
        TweenService:Create(btnGetKey, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        }):Play()
    end)
    
    -- Get Key action
    btnGetKey.MouseButton1Click:Connect(function()
        local keyUrl = "https://your-website.com/getkey"
        setclipboard(keyUrl)
        
        btnGetKey.Text = "✓ Copied!"
        TweenService:Create(btnGetKey, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(50, 180, 100)
        }):Play()
        
        status.Text = "✓ Key URL copied!"
        status.TextColor3 = Color3.fromRGB(100, 255, 150)
        TweenService:Create(status, TweenInfo.new(0.2), {TextTransparency = 0}):Play()
        
        wait(2)
        
        btnGetKey.Text = "🔗 Get Key"
        TweenService:Create(btnGetKey, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        }):Play()
        TweenService:Create(status, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
    end)
    
    -- Submit action
    btnSubmit.MouseButton1Click:Connect(function()
        local key = keyInput.Text
        
        if key == "" or #key < 5 then
            status.Text = "⚠️ Please enter a valid key"
            status.TextColor3 = Color3.fromRGB(255, 150, 100)
            TweenService:Create(status, TweenInfo.new(0.2), {TextTransparency = 0}):Play()
            
            -- Shake
            local origPos = inputBox.Position
            for i = 1, 2 do
                inputBox.Position = origPos + UDim2.new(0, 5, 0, 0)
                wait(0.05)
                inputBox.Position = origPos + UDim2.new(0, -5, 0, 0)
                wait(0.05)
            end
            inputBox.Position = origPos
            return
        end
        
        btnSubmit.Text = "⏳ Verifying..."
        TweenService:Create(btnSubmit, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(80, 80, 90)
        }):Play()
        
        status.Text = "Verifying key..."
        status.TextColor3 = Color3.fromRGB(200, 200, 210)
        TweenService:Create(status, TweenInfo.new(0.2), {TextTransparency = 0}):Play()
        
        task.spawn(function()
            local valid, message = verifyKeyRemote(key)
            
            if valid then
                btnSubmit.Text = "✓ Success!"
                TweenService:Create(btnSubmit, TweenInfo.new(0.2), {
                    BackgroundColor3 = Color3.fromRGB(50, 180, 100)
                }):Play()
                
                status.Text = "✓ Access granted!"
                status.TextColor3 = Color3.fromRGB(100, 255, 150)
                
                wait(1)
                
                local session = createSession(key)
                
                -- Fade out
                TweenService:Create(mainFrame, TweenInfo.new(0.3), {
                    BackgroundTransparency = 1
                }):Play()
                TweenService:Create(blurBg, TweenInfo.new(0.3), {
                    BackgroundTransparency = 1
                }):Play()
                
                wait(0.3)
                screenGui:Destroy()
                
                if callback then
                    callback(true, session)
                end
            else
                btnSubmit.Text = "✓ Submit Key"
                TweenService:Create(btnSubmit, TweenInfo.new(0.2), {
                    BackgroundColor3 = Color3.fromRGB(70, 120, 255)
                }):Play()
                
                status.Text = "✗ " .. (message or "Invalid key")
                status.TextColor3 = Color3.fromRGB(255, 100, 100)
                
                -- Shake frame
                local origPos = mainFrame.Position
                for i = 1, 2 do
                    TweenService:Create(mainFrame, TweenInfo.new(0.05), {
                        Position = origPos + UDim2.new(0, 8, 0, 0)
                    }):Play()
                    wait(0.05)
                    TweenService:Create(mainFrame, TweenInfo.new(0.05), {
                        Position = origPos + UDim2.new(0, -8, 0, 0)
                    }):Play()
                    wait(0.05)
                end
                TweenService:Create(mainFrame, TweenInfo.new(0.05), {
                    Position = origPos
                }):Play()
            end
        end)
    end)
    
    -- Draggable
    local dragging, dragInput, startPos
    
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            startPos = mainFrame.Position
            dragInput = input.Position
        end
    end)
    
    header.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragInput
            mainFrame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    -- Entry animation
    screenGui.Parent = playerGui
    
    blurBg.BackgroundTransparency = 1
    TweenService:Create(blurBg, TweenInfo.new(0.3), {
        BackgroundTransparency = 0.3
    }):Play()
    
    mainFrame.Size = UDim2.new(0, 0, 0, 0)
    mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    
    TweenService:Create(mainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 450, 0, 280),
        Position = UDim2.new(0.5, -225, 0.5, -140)
    }):Play()
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

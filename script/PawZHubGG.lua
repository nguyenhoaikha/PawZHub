-- PawZHub - Gunfight Arena Script
-- ⚠️ WARNING: This script can only be loaded through the official loader
-- Direct loading is blocked for security

-- ============================================
-- SECURITY CHECK - DO NOT REMOVE OR MODIFY
-- ============================================

local function verifyAuthentication()
    -- Check if session exists
    if not _G.PawZHubSession then
        return false, "No active session detected"
    end
    
    local session = _G.PawZHubSession
    
    -- Verify session has required fields
    if not session.token or not session.timestamp or not session.gameId then
        return false, "Invalid session data"
    end
    
    -- Check if session is for this game
    if session.gameId ~= game.PlaceId then
        return false, "Session is for a different game"
    end
    
    -- Check if session has expired (1 hour)
    local currentTime = os.time()
    local sessionAge = currentTime - session.timestamp
    
    if sessionAge > 3600 then -- 3600 seconds = 1 hour
        _G.PawZHubSession = nil
        return false, "Session has expired"
    end
    
    -- Check if user matches
    local currentUserId = game:GetService("Players").LocalPlayer.UserId
    if session.userId ~= currentUserId then
        return false, "Session belongs to different user"
    end
    
    return true, session
end

-- Verify authentication before allowing script execution
local authSuccess, sessionOrError = verifyAuthentication()

if not authSuccess then
    -- Authentication failed - block execution
    warn("⚠️ PawZHub Security: " .. sessionOrError)
    warn("⚠️ This script must be loaded through the official loader")
    warn("⚠️ Use: loadstring(game:HttpGet('https://raw.githubusercontent.com/nguyenhoaikha/PawZHub/main/loader.lua'))()")
    
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "🔒 PawZHub Security",
        Text = "Authentication required! Use official loader.",
        Duration = 10
    })
    
    -- Stop execution immediately
    return
end

-- ============================================
-- AUTHENTICATION PASSED - SCRIPT BEGINS
-- ============================================

print("✓ PawZHub GG - Authentication verified")
print("✓ Session Token: " .. sessionOrError.token:sub(1, 8) .. "...")
print("✓ User: " .. sessionOrError.username)

game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "🐾 PawZHub GG",
    Text = "Welcome " .. sessionOrError.username .. "!",
    Duration = 5
})

-- ============================================
-- YOUR GUNFIGHT ARENA SCRIPT CODE HERE
-- ============================================

-- Example: Simple UI notification
local function createWelcomeUI()
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PawZHubGG"
    screenGui.ResetOnSpawn = false
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 150)
    frame.Position = UDim2.new(0.5, -150, 0.5, -75)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 40)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "🔫 PawZHub - Gunfight Arena"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.Parent = frame
    
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -20, 0, 60)
    status.Position = UDim2.new(0, 10, 0, 55)
    status.BackgroundTransparency = 1
    status.Text = "✓ Script loaded successfully!\n✓ Authentication verified\n✓ Ready to use"
    status.TextColor3 = Color3.fromRGB(100, 255, 100)
    status.TextSize = 14
    status.Font = Enum.Font.Gotham
    status.TextYAlignment = Enum.TextYAlignment.Top
    status.Parent = frame
    
    local closeButton = Instance.new("TextButton")
    closeButton.Size = UDim2.new(0, 100, 0, 30)
    closeButton.Position = UDim2.new(0.5, -50, 1, -40)
    closeButton.BackgroundColor3 = Color3.fromRGB(70, 130, 250)
    closeButton.BorderSizePixel = 0
    closeButton.Text = "Close"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 14
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = frame
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = closeButton
    
    closeButton.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)
    
    screenGui.Parent = playerGui
    
    -- Auto close after 5 seconds
    task.delay(5, function()
        if screenGui.Parent then
            screenGui:Destroy()
        end
    end)
end

-- ============================================
-- MAIN SCRIPT EXECUTION
-- ============================================

-- Create welcome UI
createWelcomeUI()

-- Add your Gunfight Arena features here
-- Example features you might add:
-- - Aimbot
-- - ESP
-- - Silent Aim
-- - Gun Mods
-- - etc.

print("🐾 PawZHub Gunfight Arena script loaded successfully!")

-- Example: Print session info (for debugging)
if game:GetService("Players").LocalPlayer.Name == sessionOrError.username then
    print("Session valid for: " .. math.floor((3600 - (os.time() - sessionOrError.timestamp)) / 60) .. " minutes")
end

--[[
    ADD YOUR GUNFIGHT ARENA SCRIPT FEATURES BELOW THIS LINE
    
    The script will only reach this point if authentication is successful.
    You can safely add your features here knowing the user has a valid key.
    
    Example structure:
    
    local GGScript = {}
    
    function GGScript.aimbot()
        -- Your aimbot code
    end
    
    function GGScript.esp()
        -- Your ESP code
    end
    
    -- Initialize your features
    GGScript.aimbot()
]]

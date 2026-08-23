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
    Title = "PawZHub",
    Text = "Script loaded successfully",
    Duration = 3
})

-- ============================================
-- YOUR GUNFIGHT ARENA SCRIPT CODE HERE
-- ============================================

print("🐾 PawZHub Gunfight Arena script loaded successfully!")

--[[
    ADD YOUR GUNFIGHT ARENA SCRIPT FEATURES BELOW THIS LINE
    
    The script will only reach this point if authentication is successful.
    You can safely add your features here knowing the user has a valid key.
]]

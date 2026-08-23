-- PawZHub Advanced Key Authentication System v2.0
-- This file handles key verification, session management, and security

local CheckKeySystem = {}

-- ============================================
-- CONFIGURATION
-- ============================================

local CONFIG = {
    -- API Endpoints
    KEY_CHECK_URL = "https://your-api-endpoint.com/verify",
    WEBHOOK_URL = "https://discord.com/api/webhooks/YOUR_WEBHOOK",
    BLACKLIST_URL = "https://your-api-endpoint.com/blacklist",
    VERSION_CHECK_URL = "https://your-api-endpoint.com/version",
    
    -- Security Settings
    SESSION_DURATION = 3600,           -- 1 hour in seconds
    MAX_RETRY_ATTEMPTS = 3,            -- Max failed attempts before lockout
    LOCKOUT_DURATION = 300,            -- 5 minutes lockout
    RATE_LIMIT_COOLDOWN = 2,           -- Seconds between requests
    ENABLE_HWID_BINDING = true,        -- Bind keys to HWID
    ENABLE_IP_LOGGING = false,         -- Log IP addresses
    
    -- Key Settings
    KEY_FORMAT_REGEX = "^[A-Z0-9]{4}%-[A-Z0-9]{4}%-[A-Z0-9]{4}%-[A-Z0-9]{4}$",
    ALLOW_OFFLINE_MODE = true,         -- Allow fallback keys when offline
    CACHE_DURATION = 600,              -- Cache valid keys for 10 minutes
    
    -- Version Control
    CURRENT_VERSION = "2.0.0",
    REQUIRE_LATEST_VERSION = false,
    
    -- Debug
    DEBUG_MODE = false,
}

-- ============================================
-- STATE MANAGEMENT
-- ============================================

local State = {
    failedAttempts = 0,
    lockedUntil = 0,
    lastRequestTime = 0,
    keyCache = {},
    blacklistedUsers = {},
    analytics = {
        keysChecked = 0,
        successfulLogins = 0,
        failedLogins = 0,
        startTime = os.time(),
    }
}

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================

-- Generate cryptographically random token
local function generateToken()
    local HttpService = game:GetService("HttpService")
    -- Use Roblox's GUID for better randomness
    local guid = HttpService:GenerateGUID(false)
    return guid:gsub("-", ""):upper()
end

-- Get Hardware ID (unique per device)
local function getHWID()
    local HttpService = game:GetService("HttpService")
    local UserInputService = game:GetService("UserInputService")
    
    local hwid = ""
    -- Combine multiple factors for HWID
    pcall(function()
        local factors = {
            game:GetService("RbxAnalyticsService"):GetClientId(),
            tostring(UserInputService:GetGamepadIds()[1] or "no-gamepad"),
            tostring(game.PlaceId),
        }
        hwid = HttpService:JSONEncode(factors)
    end)
    
    -- Hash the HWID
    return HttpService:GenerateGUID(false):gsub("-", ""):sub(1, 16):upper()
end

-- Simple encryption for local storage
local function encrypt(text, key)
    local result = ""
    for i = 1, #text do
        local char = text:sub(i, i)
        local keyChar = key:sub((i - 1) % #key + 1, (i - 1) % #key + 1)
        result = result .. string.char(bit32.bxor(string.byte(char), string.byte(keyChar)))
    end
    return game:GetService("HttpService"):GenerateGUID(false):sub(1, 8) .. result
end

local function decrypt(encrypted, key)
    if #encrypted < 8 then return nil end
    local text = encrypted:sub(9)
    local result = ""
    for i = 1, #text do
        local char = text:sub(i, i)
        local keyChar = key:sub((i - 1) % #key + 1, (i - 1) % #key + 1)
        result = result .. string.char(bit32.bxor(string.byte(char), string.byte(keyChar)))
    end
    return result
end

-- Validate key format
local function isValidKeyFormat(key)
    if not key or type(key) ~= "string" then
        return false
    end
    
    -- Check against regex pattern
    return key:match(CONFIG.KEY_FORMAT_REGEX) ~= nil
end

-- Rate limiting check
local function checkRateLimit()
    local currentTime = os.time()
    local timeSinceLastRequest = currentTime - State.lastRequestTime
    
    if timeSinceLastRequest < CONFIG.RATE_LIMIT_COOLDOWN then
        return false, string.format("Please wait %d seconds", CONFIG.RATE_LIMIT_COOLDOWN - timeSinceLastRequest)
    end
    
    State.lastRequestTime = currentTime
    return true
end

-- Check if user is locked out
local function checkLockout()
    if State.lockedUntil > os.time() then
        local remaining = State.lockedUntil - os.time()
        return false, string.format("Too many failed attempts. Locked for %d seconds", remaining)
    end
    
    -- Reset if lockout expired
    if State.lockedUntil > 0 and State.lockedUntil <= os.time() then
        State.failedAttempts = 0
        State.lockedUntil = 0
    end
    
    return true
end

-- Log to debug
local function debugLog(...)
    if CONFIG.DEBUG_MODE then
        print("[PawZHub Debug]", ...)
    end
end

-- ============================================
-- CACHE SYSTEM
-- ============================================

local function getCachedKey(key)
    local cached = State.keyCache[key]
    if not cached then return nil end
    
    -- Check if cache is still valid
    if os.time() - cached.timestamp > CONFIG.CACHE_DURATION then
        State.keyCache[key] = nil
        return nil
    end
    
    debugLog("Using cached key:", key)
    return cached.data
end

local function cacheKey(key, data)
    State.keyCache[key] = {
        data = data,
        timestamp = os.time()
    }
end

-- ============================================
-- BLACKLIST SYSTEM
-- ============================================

local function fetchBlacklist()
    local HttpService = game:GetService("HttpService")
    pcall(function()
        local response = HttpService:GetAsync(CONFIG.BLACKLIST_URL, true)
        local data = HttpService:JSONDecode(response)
        State.blacklistedUsers = data.users or {}
    end)
end

local function isBlacklisted(userId)
    for _, id in ipairs(State.blacklistedUsers) do
        if tostring(id) == tostring(userId) then
            return true
        end
    end
    return false
end

-- ============================================
-- WEBHOOK LOGGING
-- ============================================

local function sendWebhook(data)
    if not CONFIG.WEBHOOK_URL or CONFIG.WEBHOOK_URL == "https://discord.com/api/webhooks/YOUR_WEBHOOK" then
        return
    end
    
    local HttpService = game:GetService("HttpService")
    local player = game:GetService("Players").LocalPlayer
    
    local embed = {
        title = data.title or "PawZHub Event",
        description = data.description or "No description",
        color = data.color or 3447003,
        fields = {
            {name = "User", value = player.Name, inline = true},
            {name = "User ID", value = tostring(player.UserId), inline = true},
            {name = "Game", value = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name, inline = false},
            {name = "Place ID", value = tostring(game.PlaceId), inline = true},
            {name = "Time", value = os.date("%Y-%m-%d %H:%M:%S"), inline = true},
        },
        footer = {
            text = "PawZHub v" .. CONFIG.CURRENT_VERSION
        },
        timestamp = os.date("!%Y-%m-%dT%H:%M:%S")
    }
    
    -- Add custom fields
    if data.fields then
        for _, field in ipairs(data.fields) do
            table.insert(embed.fields, field)
        end
    end
    
    local payload = HttpService:JSONEncode({
        embeds = {embed}
    })
    
    pcall(function()
        HttpService:PostAsync(
            CONFIG.WEBHOOK_URL,
            payload,
            Enum.HttpContentType.ApplicationJson
        )
    end)
end

-- ============================================
-- VERSION CONTROL
-- ============================================

local function checkVersion()
    if not CONFIG.VERSION_CHECK_URL then return true end
    
    local HttpService = game:GetService("HttpService")
    local success, response = pcall(function()
        return HttpService:GetAsync(CONFIG.VERSION_CHECK_URL, true)
    end)
    
    if success then
        local data = HttpService:JSONDecode(response)
        local latestVersion = data.version
        
        if latestVersion ~= CONFIG.CURRENT_VERSION then
            warn("New version available:", latestVersion, "Current:", CONFIG.CURRENT_VERSION)
            
            if CONFIG.REQUIRE_LATEST_VERSION then
                return false, "Please update to the latest version: " .. latestVersion
            end
            
            -- Send notification
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = "Update Available",
                Text = "New version " .. latestVersion .. " is available!",
                Duration = 10
            })
        end
    end
    
    return true
end

-- ============================================
-- SESSION MANAGEMENT
-- ============================================

-- Enhanced session creation with security features
local function createSession(key, keyData)
    local token = generateToken()
    local hwid = getHWID()
    
    local sessionData = {
        -- Core data
        token = token,
        key = key,
        hwid = hwid,
        timestamp = os.time(),
        expiresAt = os.time() + CONFIG.SESSION_DURATION,
        
        -- Game info
        gameId = game.PlaceId,
        gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name,
        
        -- User info
        userId = game:GetService("Players").LocalPlayer.UserId,
        username = game:GetService("Players").LocalPlayer.Name,
        displayName = game:GetService("Players").LocalPlayer.DisplayName,
        accountAge = game:GetService("Players").LocalPlayer.AccountAge,
        
        -- Key info (from API response)
        keyTier = keyData and keyData.tier or "free",
        keyExpiry = keyData and keyData.expiry or nil,
        keyFeatures = keyData and keyData.features or {},
        
        -- Security
        sessionId = generateToken():sub(1, 16),
        createdAt = os.date("%Y-%m-%d %H:%M:%S"),
        ipHash = "", -- Populated if IP logging enabled
        
        -- Statistics
        loginCount = 1,
        lastActivity = os.time(),
    }
    
    -- Store in multiple locations for redundancy
    _G.PawZHubSession = sessionData
    _G.PawZHub_Token = token
    _G.PawZHub_Authenticated = true
    
    -- Log analytics
    State.analytics.successfulLogins = State.analytics.successfulLogins + 1
    
    -- Send webhook notification
    sendWebhook({
        title = "✅ Successful Login",
        description = "User authenticated successfully",
        color = 3066993,
        fields = {
            {name = "Key Tier", value = sessionData.keyTier, inline = true},
            {name = "HWID", value = hwid:sub(1, 8) .. "...", inline = true},
            {name = "Session ID", value = sessionData.sessionId, inline = true},
        }
    })
    
    debugLog("Session created:", sessionData.sessionId)
    
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
    if currentTime > session.expiresAt then
        CheckKeySystem.destroySession()
        return false, "Session expired"
    end
    
    -- Check if key expired (if has expiry)
    if session.keyExpiry and currentTime > session.keyExpiry then
        CheckKeySystem.destroySession()
        return false, "Key expired"
    end
    
    -- Check if game matches
    if session.gameId ~= game.PlaceId then
        return false, "Session for different game"
    end
    
    -- Check HWID if binding enabled
    if CONFIG.ENABLE_HWID_BINDING then
        local currentHWID = getHWID()
        if session.hwid ~= currentHWID then
            CheckKeySystem.destroySession()
            sendWebhook({
                title = "⚠️ HWID Mismatch",
                description = "Session HWID doesn't match current device",
                color = 15158332,
            })
            return false, "HWID mismatch - session invalidated"
        end
    end
    
    -- Update last activity
    session.lastActivity = currentTime
    
    return true, session
end

-- Destroy session
function CheckKeySystem.destroySession()
    _G.PawZHubSession = nil
    _G.PawZHub_Token = nil
    _G.PawZHub_Authenticated = nil
    debugLog("Session destroyed")
end

-- ============================================
-- KEY VERIFICATION
-- ============================================

-- Verify key with remote server (enhanced)
local function verifyKeyRemote(key)
    -- Rate limit check
    local canProceed, rateLimitMsg = checkRateLimit()
    if not canProceed then
        return false, rateLimitMsg
    end
    
    -- Check cache first
    local cached = getCachedKey(key)
    if cached then
        return true, "Valid (cached)", cached
    end
    
    local HttpService = game:GetService("HttpService")
    local player = game:GetService("Players").LocalPlayer
    
    local requestData = {
        key = key,
        hwid = getHWID(),
        userId = player.UserId,
        username = player.Name,
        displayName = player.DisplayName,
        gameId = game.PlaceId,
        version = CONFIG.CURRENT_VERSION,
        timestamp = os.time(),
    }
    
    local success, response = pcall(function()
        return HttpService:PostAsync(
            CONFIG.KEY_CHECK_URL,
            HttpService:JSONEncode(requestData),
            Enum.HttpContentType.ApplicationJson,
            false,
            {
                ["Content-Type"] = "application/json",
                ["User-Agent"] = "PawZHub/" .. CONFIG.CURRENT_VERSION,
            }
        )
    end)
    
    State.analytics.keysChecked = State.analytics.keysChecked + 1
    
    if success then
        local data = HttpService:JSONDecode(response)
        
        if data.valid == true then
            -- Cache the key
            cacheKey(key, data)
            
            return true, data.message or "Valid key", data
        else
            return false, data.message or "Invalid key"
        end
    else
        warn("Key verification failed:", response)
        
        -- Fallback to offline mode if enabled
        if CONFIG.ALLOW_OFFLINE_MODE then
            warn("Attempting offline verification...")
            return CheckKeySystem.verifyKeyFallback(key)
        end
        
        return false, "Server unreachable"
    end
end

-- Enhanced fallback verification
function CheckKeySystem.verifyKeyFallback(key)
    local validKeys = {
        -- Format: ["KEY"] = {tier, expiry_timestamp, features}
        ["PAWZ-FREE-2024-DEMO1"] = {
            tier = "free",
            expiry = nil, -- No expiry
            features = {"basic"}
        },
        ["PAWZ-PREM-2024-TEST"] = {
            tier = "premium",
            expiry = os.time() + (30 * 24 * 3600), -- 30 days from now
            features = {"basic", "advanced", "priority"}
        },
        ["PAWZ-LIFE-2024-VIP1"] = {
            tier = "lifetime",
            expiry = nil,
            features = {"basic", "advanced", "premium", "priority", "exclusive"}
        },
    }
    
    local keyData = validKeys[key]
    if keyData then
        -- Check if key is expired
        if keyData.expiry and os.time() > keyData.expiry then
            return false, "Key expired", nil
        end
        
        return true, "Valid key (offline mode)", keyData
    end
    
    return false, "Invalid key"
end

-- ============================================
-- MAIN VERIFICATION FLOW
-- ============================================

local function performKeyVerification(key)
    -- Pre-checks
    local lockoutOk, lockoutMsg = checkLockout()
    if not lockoutOk then
        return false, lockoutMsg
    end
    
    -- Format validation
    if not isValidKeyFormat(key) then
        State.failedAttempts = State.failedAttempts + 1
        return false, "Invalid key format"
    end
    
    -- Blacklist check
    local player = game:GetService("Players").LocalPlayer
    if isBlacklisted(player.UserId) then
        sendWebhook({
            title = "🚫 Blacklisted User Attempt",
            description = "Blacklisted user tried to authenticate",
            color = 10038562,
        })
        return false, "Access denied"
    end
    
    -- Version check
    local versionOk, versionMsg = checkVersion()
    if not versionOk then
        return false, versionMsg
    end
    
    -- Perform verification
    local valid, message, keyData = verifyKeyRemote(key)
    
    if valid then
        -- Reset failed attempts
        State.failedAttempts = 0
        State.lockedUntil = 0
        
        return true, message, keyData
    else
        -- Increment failed attempts
        State.failedAttempts = State.failedAttempts + 1
        State.analytics.failedLogins = State.analytics.failedLogins + 1
        
        -- Check if should lockout
        if State.failedAttempts >= CONFIG.MAX_RETRY_ATTEMPTS then
            State.lockedUntil = os.time() + CONFIG.LOCKOUT_DURATION
            
            sendWebhook({
                title = "⚠️ Account Locked",
                description = string.format("Too many failed attempts (%d)", State.failedAttempts),
                color = 15105570,
            })
            
            return false, string.format("Too many failed attempts. Locked for %d seconds", CONFIG.LOCKOUT_DURATION)
        end
        
        local remainingAttempts = CONFIG.MAX_RETRY_ATTEMPTS - State.failedAttempts
        return false, string.format("%s (%d attempts remaining)", message, remainingAttempts)
    end
end

-- ============================================
-- PUBLIC API
-- ============================================

-- Main function to show key system
function CheckKeySystem.show(callback)
    -- Initialize
    fetchBlacklist()
    
    -- ALWAYS show key UI for testing (no session cache)
    createKeyUI(callback)
end

-- Get analytics data
function CheckKeySystem.getAnalytics()
    return {
        uptime = os.time() - State.analytics.startTime,
        keysChecked = State.analytics.keysChecked,
        successRate = State.analytics.keysChecked > 0 
            and (State.analytics.successfulLogins / State.analytics.keysChecked * 100) 
            or 0,
        failedLogins = State.analytics.failedLogins,
        currentCacheSize = #State.keyCache,
    }
end

-- Check if user has feature access
function CheckKeySystem.hasFeature(featureName)
    local valid, session = CheckKeySystem.verifySession()
    if not valid then return false end
    
    for _, feature in ipairs(session.keyFeatures) do
        if feature == featureName then
            return true
        end
    end
    
    return false
end

-- Refresh session (extend expiry)
function CheckKeySystem.refreshSession()
    if not _G.PawZHubSession then
        return false, "No active session"
    end
    
    local session = _G.PawZHubSession
    session.expiresAt = os.time() + CONFIG.SESSION_DURATION
    session.lastActivity = os.time()
    
    debugLog("Session refreshed")
    return true
end

-- Export for use in other scripts
return CheckKeySystem

-- Create UI for key input - macOS style with blur backdrop
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
    
    -- Subtle backdrop (not full black)
    local backdrop = Instance.new("Frame")
    backdrop.Size = UDim2.new(1, 0, 1, 0)
    backdrop.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    backdrop.BackgroundTransparency = 0.65
    backdrop.BorderSizePixel = 0
    backdrop.Parent = screenGui
    
    -- Blur effect simulation with gradient
    local blurGradient = Instance.new("UIGradient")
    blurGradient.Transparency = NumberSequence.new{
        NumberSequenceKeypoint.new(0, 0.6),
        NumberSequenceKeypoint.new(0.5, 0.7),
        NumberSequenceKeypoint.new(1, 0.6)
    }
    blurGradient.Parent = backdrop
    
    -- Main window - macOS frosted glass style
    local window = Instance.new("Frame")
    window.Size = UDim2.new(0, 420, 0, 240)
    window.Position = UDim2.new(0.5, -210, 0.5, -120)
    window.BackgroundColor3 = Color3.fromRGB(240, 242, 247)
    window.BorderSizePixel = 0
    window.ClipsDescendants = false
    window.Parent = screenGui
    
    local windowCorner = Instance.new("UICorner")
    windowCorner.CornerRadius = UDim.new(0, 12)
    windowCorner.Parent = window
    
    -- macOS window border
    local windowBorder = Instance.new("UIStroke")
    windowBorder.Color = Color3.fromRGB(200, 205, 215)
    windowBorder.Thickness = 1
    windowBorder.Transparency = 0.5
    windowBorder.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    windowBorder.Parent = window
    
    -- Drop shadow (macOS style)
    local shadow = Instance.new("ImageLabel")
    shadow.Size = UDim2.new(1, 40, 1, 40)
    shadow.Position = UDim2.new(0, -20, 0, 10)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.85
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 10, 10)
    shadow.ZIndex = 0
    shadow.Parent = screenGui
    
    -- Title bar (macOS style)
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 52)
    titleBar.BackgroundColor3 = Color3.fromRGB(250, 251, 253)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = window
    
    local titleBarCorner = Instance.new("UICorner")
    titleBarCorner.CornerRadius = UDim.new(0, 12)
    titleBarCorner.Parent = titleBar
    
    -- Bottom cover to square titlebar bottom
    local titleBarCover = Instance.new("Frame")
    titleBarCover.Size = UDim2.new(1, 0, 0, 12)
    titleBarCover.Position = UDim2.new(0, 0, 1, -12)
    titleBarCover.BackgroundColor3 = Color3.fromRGB(250, 251, 253)
    titleBarCover.BorderSizePixel = 0
    titleBarCover.Parent = titleBar
    
    -- macOS window control buttons (traffic lights)
    local controlsContainer = Instance.new("Frame")
    controlsContainer.Size = UDim2.new(0, 60, 0, 12)
    controlsContainer.Position = UDim2.new(0, 12, 0, 20)
    controlsContainer.BackgroundTransparency = 1
    controlsContainer.Parent = titleBar
    
    local colors = {
        Color3.fromRGB(255, 95, 87),   -- Red
        Color3.fromRGB(255, 189, 46),  -- Yellow
        Color3.fromRGB(40, 205, 65)    -- Green
    }
    
    for i, color in ipairs(colors) do
        local btn = Instance.new("Frame")
        btn.Size = UDim2.new(0, 12, 0, 12)
        btn.Position = UDim2.new(0, (i-1) * 20, 0, 0)
        btn.BackgroundColor3 = color
        btn.BorderSizePixel = 0
        btn.Parent = controlsContainer
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(1, 0)
        btnCorner.Parent = btn
    end
    
    -- Window title centered
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -160, 0, 52)
    title.Position = UDim2.new(0, 80, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "PawZHub Key System"
    title.TextColor3 = Color3.fromRGB(30, 30, 35)
    title.TextSize = 14
    title.Font = Enum.Font.GothamMedium
    title.Parent = titleBar
    
    -- Content area
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -40, 1, -72)
    content.Position = UDim2.new(0, 20, 0, 62)
    content.BackgroundTransparency = 1
    content.Parent = window
    
    -- Label
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Position = UDim2.new(0, 0, 0, 8)
    label.BackgroundTransparency = 1
    label.Text = "License Key"
    label.TextColor3 = Color3.fromRGB(60, 60, 70)
    label.TextSize = 13
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = content
    
    -- Input field (macOS style)
    local inputContainer = Instance.new("Frame")
    inputContainer.Size = UDim2.new(1, 0, 0, 36)
    inputContainer.Position = UDim2.new(0, 0, 0, 32)
    inputContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    inputContainer.BorderSizePixel = 0
    inputContainer.Parent = content
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = UDim.new(0, 6)
    inputCorner.Parent = inputContainer
    
    local inputBorder = Instance.new("UIStroke")
    inputBorder.Color = Color3.fromRGB(200, 205, 215)
    inputBorder.Thickness = 1
    inputBorder.Transparency = 0
    inputBorder.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    inputBorder.Parent = inputContainer
    
    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1, -20, 1, 0)
    input.Position = UDim2.new(0, 10, 0, 0)
    input.BackgroundTransparency = 1
    input.Text = ""
    input.PlaceholderText = "Enter your key"
    input.TextColor3 = Color3.fromRGB(30, 30, 35)
    input.PlaceholderColor3 = Color3.fromRGB(150, 155, 165)
    input.TextSize = 14
    input.Font = Enum.Font.Gotham
    input.ClearTextOnFocus = false
    input.Parent = inputContainer
    
    -- Focus effect (macOS blue ring)
    input.Focused:Connect(function()
        TweenService:Create(inputBorder, TweenInfo.new(0.15), {
            Color = Color3.fromRGB(0, 122, 255),
            Thickness = 2,
            Transparency = 0
        }):Play()
        TweenService:Create(inputContainer, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        }):Play()
    end)
    
    input.FocusLost:Connect(function()
        TweenService:Create(inputBorder, TweenInfo.new(0.15), {
            Color = Color3.fromRGB(200, 205, 215),
            Thickness = 1,
            Transparency = 0
        }):Play()
    end)
    
    -- Buttons (macOS style)
    local btnContainer = Instance.new("Frame")
    btnContainer.Size = UDim2.new(1, 0, 0, 32)
    btnContainer.Position = UDim2.new(0, 0, 1, -42)
    btnContainer.BackgroundTransparency = 1
    btnContainer.Parent = content
    
    -- Get Key button (secondary)
    local getKeyBtn = Instance.new("TextButton")
    getKeyBtn.Size = UDim2.new(0.48, 0, 1, 0)
    getKeyBtn.Position = UDim2.new(0, 0, 0, 0)
    getKeyBtn.BackgroundColor3 = Color3.fromRGB(245, 246, 248)
    getKeyBtn.BorderSizePixel = 0
    getKeyBtn.Text = "Get Key"
    getKeyBtn.TextColor3 = Color3.fromRGB(30, 30, 35)
    getKeyBtn.TextSize = 13
    getKeyBtn.Font = Enum.Font.GothamMedium
    getKeyBtn.AutoButtonColor = false
    getKeyBtn.Parent = btnContainer
    
    local getKeyCorner = Instance.new("UICorner")
    getKeyCorner.CornerRadius = UDim.new(0, 6)
    getKeyCorner.Parent = getKeyBtn
    
    local getKeyBorder = Instance.new("UIStroke")
    getKeyBorder.Color = Color3.fromRGB(200, 205, 215)
    getKeyBorder.Thickness = 1
    getKeyBorder.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    getKeyBorder.Parent = getKeyBtn
    
    -- Submit button (primary - macOS blue)
    local submitBtn = Instance.new("TextButton")
    submitBtn.Size = UDim2.new(0.48, 0, 1, 0)
    submitBtn.Position = UDim2.new(0.52, 0, 0, 0)
    submitBtn.BackgroundColor3 = Color3.fromRGB(0, 122, 255)
    submitBtn.BorderSizePixel = 0
    submitBtn.Text = "Submit"
    submitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    submitBtn.TextSize = 13
    submitBtn.Font = Enum.Font.GothamBold
    submitBtn.AutoButtonColor = false
    submitBtn.Parent = btnContainer
    
    local submitCorner = Instance.new("UICorner")
    submitCorner.CornerRadius = UDim.new(0, 6)
    submitCorner.Parent = submitBtn
    
    -- Status label
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, 0, 0, 18)
    status.Position = UDim2.new(0, 0, 0, 76)
    status.BackgroundTransparency = 1
    status.Text = ""
    status.TextColor3 = Color3.fromRGB(255, 59, 48)
    status.TextSize = 12
    status.Font = Enum.Font.Gotham
    status.TextTransparency = 1
    status.Parent = content
    
    -- Button hover effects (macOS subtle)
    getKeyBtn.MouseEnter:Connect(function()
        TweenService:Create(getKeyBtn, TweenInfo.new(0.12), {
            BackgroundColor3 = Color3.fromRGB(235, 238, 242)
        }):Play()
    end)
    
    getKeyBtn.MouseLeave:Connect(function()
        TweenService:Create(getKeyBtn, TweenInfo.new(0.12), {
            BackgroundColor3 = Color3.fromRGB(245, 246, 248)
        }):Play()
    end)
    
    submitBtn.MouseEnter:Connect(function()
        TweenService:Create(submitBtn, TweenInfo.new(0.12), {
            BackgroundColor3 = Color3.fromRGB(20, 142, 255)
        }):Play()
    end)
    
    submitBtn.MouseLeave:Connect(function()
        TweenService:Create(submitBtn, TweenInfo.new(0.12), {
            BackgroundColor3 = Color3.fromRGB(0, 122, 255)
        }):Play()
    end)
    
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
        
        -- Subtle success feedback
        getKeyBtn.Text = "✓ Copied"
        TweenService:Create(getKeyBtn, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(52, 199, 89)
        }):Play()
        TweenService:Create(getKeyBorder, TweenInfo.new(0.15), {
            Color = Color3.fromRGB(52, 199, 89)
        }):Play()
        
        status.Text = "Key URL copied to clipboard"
        status.TextColor3 = Color3.fromRGB(52, 199, 89)
        TweenService:Create(status, TweenInfo.new(0.15), {TextTransparency = 0}):Play()
        
        task.wait(1.5)
        getKeyBtn.Text = "Get Key"
        TweenService:Create(getKeyBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(245, 246, 248)
        }):Play()
        TweenService:Create(getKeyBorder, TweenInfo.new(0.2), {
            Color = Color3.fromRGB(200, 205, 215)
        }):Play()
        TweenService:Create(status, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
    end)
    
    -- Submit action
    submitBtn.MouseButton1Click:Connect(function()
        local key = input.Text
        
        if key == "" or #key < 5 then
            status.Text = "Please enter a valid key"
            status.TextColor3 = Color3.fromRGB(255, 59, 48)
            TweenService:Create(status, TweenInfo.new(0.15), {TextTransparency = 0}):Play()
            
            -- macOS shake animation (subtle)
            local originalPos = inputContainer.Position
            TweenService:Create(inputContainer, TweenInfo.new(0.05), {
                Position = originalPos + UDim2.new(0, 8, 0, 0)
            }):Play()
            task.wait(0.06)
            TweenService:Create(inputContainer, TweenInfo.new(0.05), {
                Position = originalPos + UDim2.new(0, -8, 0, 0)
            }):Play()
            task.wait(0.06)
            TweenService:Create(inputContainer, TweenInfo.new(0.05), {
                Position = originalPos + UDim2.new(0, 4, 0, 0)
            }):Play()
            task.wait(0.06)
            TweenService:Create(inputContainer, TweenInfo.new(0.08, Enum.EasingStyle.Quad), {
                Position = originalPos
            }):Play()
            
            -- Red border flash
            TweenService:Create(inputBorder, TweenInfo.new(0.1), {
                Color = Color3.fromRGB(255, 59, 48)
            }):Play()
            task.wait(0.3)
            TweenService:Create(inputBorder, TweenInfo.new(0.2), {
                Color = Color3.fromRGB(200, 205, 215)
            }):Play()
            return
        end
        
        -- Loading state
        submitBtn.Text = "Verifying..."
        local originalBg = submitBtn.BackgroundColor3
        TweenService:Create(submitBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(100, 150, 200)
        }):Play()
        
        status.Text = "Checking key..."
        status.TextColor3 = Color3.fromRGB(100, 110, 130)
        TweenService:Create(status, TweenInfo.new(0.15), {TextTransparency = 0}):Play()
        
        -- Spinning progress indicator (macOS style)
        local spinner = Instance.new("Frame")
        spinner.Size = UDim2.new(0, 16, 0, 16)
        spinner.Position = UDim2.new(0, 105, 0, 8)
        spinner.BackgroundTransparency = 1
        spinner.Parent = submitBtn
        
        local spinnerDots = {}
        for i = 1, 8 do
            local dot = Instance.new("Frame")
            dot.Size = UDim2.new(0, 2, 0, 2)
            dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            dot.BorderSizePixel = 0
            dot.AnchorPoint = Vector2.new(0.5, 0.5)
            
            local angle = (i - 1) * (360 / 8)
            local rad = math.rad(angle)
            dot.Position = UDim2.new(0.5, math.sin(rad) * 6, 0.5, -math.cos(rad) * 6)
            
            local dotCorner = Instance.new("UICorner")
            dotCorner.CornerRadius = UDim.new(1, 0)
            dotCorner.Parent = dot
            
            dot.Parent = spinner
            table.insert(spinnerDots, dot)
        end
        
        local spinnerRunning = true
        task.spawn(function()
            while spinnerRunning do
                for i, dot in ipairs(spinnerDots) do
                    TweenService:Create(dot, TweenInfo.new(0.8), {
                        BackgroundTransparency = 0.2 + (i / 8) * 0.7
                    }):Play()
                end
                task.wait(0.1)
                table.insert(spinnerDots, 1, table.remove(spinnerDots))
            end
        end)
        
        task.spawn(function()
            local valid, message = verifyKeyRemote(key)
            
            spinnerRunning = false
            spinner:Destroy()
            
            if valid then
                submitBtn.Text = "Success"
                TweenService:Create(submitBtn, TweenInfo.new(0.2), {
                    BackgroundColor3 = Color3.fromRGB(52, 199, 89)
                }):Play()
                
                status.Text = "Access granted"
                status.TextColor3 = Color3.fromRGB(52, 199, 89)
                
                -- Success checkmark animation
                local checkmark = Instance.new("TextLabel")
                checkmark.Size = UDim2.new(0, 20, 0, 20)
                checkmark.Position = UDim2.new(0, 85, 0, 6)
                checkmark.BackgroundTransparency = 1
                checkmark.Text = "✓"
                checkmark.TextColor3 = Color3.fromRGB(255, 255, 255)
                checkmark.TextSize = 16
                checkmark.Font = Enum.Font.GothamBold
                checkmark.TextTransparency = 1
                checkmark.Parent = submitBtn
                
                TweenService:Create(checkmark, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
                    TextTransparency = 0
                }):Play()
                
                task.wait(1)
                
                local session = createSession(key)
                
                -- macOS fade out (elegant)
                TweenService:Create(window, TweenInfo.new(0.25, Enum.EasingStyle.Quad), {
                    BackgroundTransparency = 1,
                    Position = UDim2.new(0.5, -210, 0.5, -110)
                }):Play()
                TweenService:Create(windowBorder, TweenInfo.new(0.25), {
                    Transparency = 1
                }):Play()
                TweenService:Create(shadow, TweenInfo.new(0.25), {
                    ImageTransparency = 1
                }):Play()
                TweenService:Create(backdrop, TweenInfo.new(0.25), {
                    BackgroundTransparency = 1
                }):Play()
                
                task.wait(0.25)
                screenGui:Destroy()
                
                if callback then
                    callback(true, session)
                end
            else
                submitBtn.Text = "Submit"
                TweenService:Create(submitBtn, TweenInfo.new(0.2), {
                    BackgroundColor3 = originalBg
                }):Play()
                
                status.Text = message or "Invalid key"
                status.TextColor3 = Color3.fromRGB(255, 59, 48)
                
                -- Error shake (window shakes)
                local originalWinPos = window.Position
                TweenService:Create(window, TweenInfo.new(0.05), {
                    Position = originalWinPos + UDim2.new(0, 10, 0, 0)
                }):Play()
                TweenService:Create(shadow, TweenInfo.new(0.05), {
                    Position = originalWinPos + UDim2.new(0, -10, 0, 20)
                }):Play()
                task.wait(0.06)
                TweenService:Create(window, TweenInfo.new(0.05), {
                    Position = originalWinPos + UDim2.new(0, -10, 0, 0)
                }):Play()
                TweenService:Create(shadow, TweenInfo.new(0.05), {
                    Position = originalWinPos + UDim2.new(0, -30, 0, 20)
                }):Play()
                task.wait(0.06)
                TweenService:Create(window, TweenInfo.new(0.05), {
                    Position = originalWinPos + UDim2.new(0, 5, 0, 0)
                }):Play()
                TweenService:Create(shadow, TweenInfo.new(0.05), {
                    Position = originalWinPos + UDim2.new(0, -15, 0, 20)
                }):Play()
                task.wait(0.06)
                TweenService:Create(window, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
                    Position = originalWinPos
                }):Play()
                TweenService:Create(shadow, TweenInfo.new(0.1, Enum.EasingStyle.Quad), {
                    Position = originalWinPos + UDim2.new(0, -20, 0, 10)
                }):Play()
            end
        end)
    end)
    
    -- Draggable window (macOS style - only titlebar)
    local dragging = false
    local dragStart, startPos
    
    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = window.Position
            
            -- Slight scale down on grab
            TweenService:Create(window, TweenInfo.new(0.1), {
                Size = UDim2.new(0, 416, 0, 238)
            }):Play()
        end
    end)
    
    titleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
            
            -- Scale back
            TweenService:Create(window, TweenInfo.new(0.15, Enum.EasingStyle.Quad), {
                Size = UDim2.new(0, 420, 0, 240)
            }):Play()
        end
    end)
    
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            local newPos = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
            window.Position = newPos
            shadow.Position = newPos + UDim2.new(0, -20, 0, 10)
        end
    end)
    
    -- Entry animation (macOS style - subtle and elegant)
    screenGui.Parent = playerGui
    
    -- Start state
    backdrop.BackgroundTransparency = 1
    window.BackgroundTransparency = 1
    windowBorder.Transparency = 1
    titleBar.BackgroundTransparency = 1
    shadow.ImageTransparency = 1
    title.TextTransparency = 1
    label.TextTransparency = 1
    inputContainer.BackgroundTransparency = 1
    inputBorder.Transparency = 1
    input.TextTransparency = 1
    submitBtn.BackgroundTransparency = 1
    getKeyBtn.BackgroundTransparency = 1
    getKeyBorder.Transparency = 1
    
    -- Traffic lights hidden
    for _, btn in ipairs(controlsContainer:GetChildren()) do
        if btn:IsA("Frame") then
            btn.BackgroundTransparency = 1
        end
    end
    
    -- Fade in backdrop
    TweenService:Create(backdrop, TweenInfo.new(0.3), {
        BackgroundTransparency = 0.65
    }):Play()
    
    task.wait(0.1)
    
    -- Window appears with scale and fade
    window.Size = UDim2.new(0, 390, 0, 220)
    window.Position = UDim2.new(0.5, -195, 0.5, -110)
    
    TweenService:Create(window, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 420, 0, 240),
        Position = UDim2.new(0.5, -210, 0.5, -120),
        BackgroundTransparency = 0
    }):Play()
    
    TweenService:Create(windowBorder, TweenInfo.new(0.35), {
        Transparency = 0.5
    }):Play()
    
    TweenService:Create(shadow, TweenInfo.new(0.35), {
        ImageTransparency = 0.85
    }):Play()
    
    task.wait(0.15)
    
    -- Title bar fades in
    TweenService:Create(titleBar, TweenInfo.new(0.25), {
        BackgroundTransparency = 0
    }):Play()
    
    -- Traffic lights appear
    for i, btn in ipairs(controlsContainer:GetChildren()) do
        if btn:IsA("Frame") then
            task.wait(0.04)
            TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Back), {
                BackgroundTransparency = 0
            }):Play()
        end
    end
    
    task.wait(0.1)
    
    -- Content fades in sequentially
    TweenService:Create(title, TweenInfo.new(0.25), {TextTransparency = 0}):Play()
    task.wait(0.05)
    TweenService:Create(label, TweenInfo.new(0.25), {TextTransparency = 0}):Play()
    task.wait(0.05)
    
    TweenService:Create(inputContainer, TweenInfo.new(0.25), {
        BackgroundTransparency = 0
    }):Play()
    TweenService:Create(inputBorder, TweenInfo.new(0.25), {
        Transparency = 0
    }):Play()
    TweenService:Create(input, TweenInfo.new(0.25), {
        TextTransparency = 0
    }):Play()
    
    task.wait(0.05)
    
    TweenService:Create(submitBtn, TweenInfo.new(0.25), {
        BackgroundTransparency = 0
    }):Play()
    TweenService:Create(getKeyBtn, TweenInfo.new(0.25), {
        BackgroundTransparency = 0
    }):Play()
    TweenService:Create(getKeyBorder, TweenInfo.new(0.25), {
        Transparency = 0
    }):Play()
end

-- Main function to show key system
function CheckKeySystem.show(callback)
    -- ALWAYS show key UI for testing (no session cache)
    createKeyUI(callback)
end

-- Export for use in other scripts
return CheckKeySystem

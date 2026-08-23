-- PawZHub Key System v2.1
-- Supports: Free keys (PAWZ-XXXX-XXXX-XXXX) + Lifetime keys (24 hex)

local CheckKeySystem = {}

-- ============================================
-- CONFIGURATION
-- ============================================

local CONFIG = {
    API_URL = "https://your-api-endpoint.com",
    KEY_CHECK_URL = "https://your-api-endpoint.com/api/verify",
    HWID_RESET_URL = "https://your-api-endpoint.com/api/hwid-reset",
    BLACKLIST_URL = "https://your-api-endpoint.com/api/blacklist",
    VERSION_CHECK_URL = "https://your-api-endpoint.com/api/version",
    WEBHOOK_URL = "",

    SESSION_DURATION = 3600,
    MAX_RETRY_ATTEMPTS = 3,
    LOCKOUT_DURATION = 3,  -- Giảm từ 300s xuống 3s
    RATE_LIMIT_COOLDOWN = 2,
    ENABLE_HWID_BINDING = true,

    -- Free key format: PAWZ-XXXX-XXXX-XXXX (19 chars)
    FREE_KEY_REGEX = "^PAWZ%-%X+%-%X+%-%X+$",
    -- Lifetime key format: 24 char hex
    LIFETIME_KEY_REGEX = "^[a-f0-9]{24}$",

    ALLOW_OFFLINE_MODE = true,
    CACHE_DURATION = 600,
    CURRENT_VERSION = "2.1.0",
    DEBUG_MODE = false,
}

-- ============================================
-- STATE
-- ============================================

local State = {
    failedAttempts = 0,
    lockedUntil = 0,
    lastRequestTime = 0,
    keyCache = {},
    blacklistedUsers = {},
}

-- ============================================
-- UTILITIES
-- ============================================

local function debugLog(...)
    if CONFIG.DEBUG_MODE then
        print("[PawZHub Debug]", ...)
    end
end

local function generateToken()
    return game:GetService("HttpService"):GenerateGUID(false):gsub("-", ""):sub(1, 32)
end

local function getHWID()
    local HttpService = game:GetService("HttpService")
    local UserInputService = game:GetService("UserInputService")
    local player = game:GetService("Players").LocalPlayer

    local components = {}

    pcall(function()
        local clientId = game:GetService("RbxAnalyticsService"):GetClientId()
        if clientId and clientId ~= "" then
            table.insert(components, clientId)
        end
    end)

    table.insert(components, string.format("%d:%d", player.UserId, player.AccountAge))

    local platform = "unknown"
    if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
        platform = "mobile"
    elseif UserInputService.KeyboardEnabled then
        platform = "pc"
    end
    table.insert(components, platform)

    local combined = table.concat(components, "|")

    local function hash(str)
        local h = 2166136261
        for i = 1, #str do
            h = bit32.bxor(h, string.byte(str, i))
            h = (h * 16777619) % 4294967296
        end
        return h
    end

    local h1 = hash(combined)
    local h2 = hash(combined .. "salt")
    local hwid = string.format("%08X%08X", h1, h2)

    _G.PawZHub_HWID = hwid
    return hwid
end

-- Detect key type: free or lifetime
local function detectKeyType(key)
    if not key or type(key) ~= "string" then return nil end

    -- Lifetime key: 24 char hex
    if key:match("^[a-f0-9]{24}$") then
        return "lifetime"
    end

    -- Free key: PAWZ-XXXX-XXXX-XXXX
    if key:match("^PAWZ%-[A-Z0-9]+%-[A-Z0-9]+%-[A-Z0-9]+$") then
        return "free"
    end

    return nil
end

-- ============================================
-- RATE LIMITING & LOCKOUT
-- ============================================

local function checkRateLimit()
    local now = os.time()
    if now - State.lastRequestTime < CONFIG.RATE_LIMIT_COOLDOWN then
        return false, "Please wait"
    end
    State.lastRequestTime = now
    return true
end

local function checkLockout()
    if State.lockedUntil > os.time() then
        local remaining = State.lockedUntil - os.time()
        return false, "Locked for " .. remaining .. "s"
    end
    if State.lockedUntil > 0 and State.lockedUntil <= os.time() then
        State.failedAttempts = 0
        State.lockedUntil = 0
    end
    return true
end

-- ============================================
-- BLACKLIST
-- ============================================

local function fetchBlacklist()
    pcall(function()
        local resp = game:GetService("HttpService"):GetAsync(CONFIG.BLACKLIST_URL, true)
        local data = game:GetService("HttpService"):JSONDecode(resp)
        State.blacklistedUsers = data.users or {}
    end)
end

local function isBlacklisted(userId)
    for _, id in ipairs(State.blacklistedUsers) do
        if tostring(id) == tostring(userId) then return true end
    end
    return false
end

-- ============================================
-- KEY VERIFICATION
-- ============================================

-- Offline/Test keys (fallback when API is down)
local function verifyKeyOffline(key)
    local testKeys = {
        -- Free keys (24h)
        ["PAWZ-FREE-2024-DEMO1"] = {
            type = "free",
            tier = "free",
            expiry = nil,
            features = {"basic"}
        },
        ["PAWZ-FREE-TEST-KEY1"] = {
            type = "free",
            tier = "free",
            expiry = nil,
            features = {"basic"}
        },
        
        -- Premium keys (30d)
        ["PAWZ-PREM-2024-TEST"] = {
            type = "free",
            tier = "premium",
            expiry = os.time() + (30 * 24 * 3600),
            features = {"basic", "advanced"}
        },
        
        -- Lifetime keys
        ["PAWZ-LIFE-2024-VIP1"] = {
            type = "free",
            tier = "lifetime",
            expiry = nil,
            features = {"basic", "advanced", "premium", "exclusive"}
        },
        
        -- Lifetime key format (24 hex chars) - example
        ["f03d3260914a9475faf29b12"] = {
            type = "lifetime",
            tier = "lifetime",
            expiry = nil,
            features = {"basic", "advanced", "premium", "exclusive"},
            hwidResetAvailable = true
        }
    }
    
    local keyData = testKeys[key]
    if keyData then
        -- Check expiry
        if keyData.expiry and os.time() > keyData.expiry then
            return false, "Key expired", nil
        end
        
        return true, "Valid (offline mode)", keyData
    end
    
    return false, "Invalid key"
end

local function verifyKeyRemote(key)
    local canProceed, msg = checkRateLimit()
    if not canProceed then return false, msg end

    -- Check cache
    local cached = State.keyCache[key]
    if cached and (os.time() - cached.ts) < CONFIG.CACHE_DURATION then
        return true, "Valid (cached)", cached.data
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
            { ["Content-Type"] = "application/json" }
        )
    end)

    if success then
        local data = HttpService:JSONDecode(response)

        if data.valid then
            State.keyCache[key] = { data = data, ts = os.time() }
            return true, data.message or "Valid", data
        else
            return false, data.message or "Invalid key"
        end
    else
        if CONFIG.ALLOW_OFFLINE_MODE then
            return verifyKeyOffline(key)  -- Gọi local function thay vì CheckKeySystem.
        end
        return false, "Server unreachable"
    end
end

-- ============================================
-- HWID RESET (via API)
-- ============================================

function CheckKeySystem.requestHWIDReset(key)
    local HttpService = game:GetService("HttpService")

    local success, response = pcall(function()
        return HttpService:PostAsync(
            CONFIG.HWID_RESET_URL,
            HttpService:JSONEncode({
                key = key,
                hwid = getHWID()
            }),
            Enum.HttpContentType.ApplicationJson
        )
    end)

    if success then
        local data = HttpService:JSONDecode(response)
        return data.success, data.message
    end
    return false, "Server unreachable"
end

-- ============================================
-- SESSION MANAGEMENT
-- ============================================

local function createSession(key, keyData)
    local token = generateToken()
    local hwid = getHWID()

    local sessionData = {
        token = token,
        key = key,
        keyType = detectKeyType(key),
        hwid = hwid,
        timestamp = os.time(),
        expiresAt = os.time() + CONFIG.SESSION_DURATION,
        gameId = game.PlaceId,
        gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name,
        userId = game:GetService("Players").LocalPlayer.UserId,
        username = game:GetService("Players").LocalPlayer.Name,
        keyTier = keyData and keyData.tier or "free",
        keyExpiry = keyData and keyData.expiry or nil,
        keyFeatures = keyData and keyData.features or {},
        sessionId = generateToken():sub(1, 16),
    }

    _G.PawZHubSession = sessionData
    _G.PawZHub_Token = token
    _G.PawZHub_Authenticated = true

    debugLog("Session created:", sessionData.sessionId, "Type:", sessionData.keyType)

    return sessionData
end

function CheckKeySystem.verifySession()
    if not _G.PawZHubSession then return false, "No session" end

    local session = _G.PawZHubSession
    if os.time() > session.expiresAt then
        CheckKeySystem.destroySession()
        return false, "Session expired"
    end
    if session.gameId ~= game.PlaceId then
        return false, "Wrong game"
    end
    if CONFIG.ENABLE_HWID_BINDING then
        if session.hwid ~= getHWID() then
            CheckKeySystem.destroySession()
            return false, "HWID mismatch"
        end
    end
    return true, session
end

function CheckKeySystem.destroySession()
    _G.PawZHubSession = nil
    _G.PawZHub_Token = nil
    _G.PawZHub_Authenticated = nil
end

-- ============================================
-- EXECUTOR DETECTION
-- ============================================

local function detectExecutor()
    local info = { name = "Unknown", platform = "Unknown" }

    if syn or is_syn_env then
        info.name, info.platform = "Synapse X", "PC"
    elseif KRNL_LOADED then
        info.name, info.platform = "KRNL", "PC"
    elseif identifyexecutor then
        local ok, name = pcall(identifyexecutor)
        info.name = ok and name or "Unknown"
        info.platform = "PC"
    elseif APPLETOUCHHOOK_LOADED then
        info.name, info.platform = "Delta", "iOS"
    elseif FLUX_LOADED then
        info.name, info.platform = "Flux", "iOS"
    elseif Arceus then
        info.name, info.platform = "Arceus X", "Android"
    elseif hydrogen then
        info.name, info.platform = "Hydrogen", "Android"
    else
        local UIS = game:GetService("UserInputService")
        if UIS.TouchEnabled and not UIS.KeyboardEnabled then
            info.name, info.platform = "Mobile", "Mobile"
        elseif UIS.KeyboardEnabled then
            info.name, info.platform = "PC Executor", "PC"
        end
    end

    _G.PawZHub_Executor = info
    return info
end

-- ============================================
-- UI CREATION (macOS style)
-- ============================================

local function createKeyUI(callback, executorInfo)
    local Players = game:GetService("Players")
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    -- Destroy old UI if exists
    local oldGui = playerGui:FindFirstChild("PawZHubKeySystem")
    if oldGui then
        oldGui:Destroy()
    end

    local isMobile = executorInfo and (executorInfo.platform == "Mobile" or executorInfo.platform == "iOS" or executorInfo.platform == "Android")
    local windowWidth = isMobile and 340 or 420
    local windowHeight = isMobile and 320 or 280

    -- ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PawZHubKeySystem"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.IgnoreGuiInset = true

    -- Window (NO BACKDROP - chỉ window, không che game)
    local window = Instance.new("Frame")
    window.Size = UDim2.new(0, windowWidth, 0, windowHeight)
    window.Position = UDim2.new(0.5, -windowWidth / 2, 0.5, -windowHeight / 2)
    window.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    window.BorderSizePixel = 0
    window.Parent = screenGui
    window.ClipsDescendants = false
    window.Active = true  -- Cho phép drag

    Instance.new("UICorner", window).CornerRadius = UDim.new(0, 12)

    local windowBorder = Instance.new("UIStroke", window)
    windowBorder.Color = Color3.fromRGB(70, 75, 85)
    windowBorder.Thickness = 2

    -- NO SHADOW - Game nhìn rõ phía sau

    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 44)
    titleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = window
    titleBar.Active = true
    titleBar.Draggable = false  -- Sẽ tự code drag

    local titleBarCorner = Instance.new("UICorner", titleBar)
    titleBarCorner.CornerRadius = UDim.new(0, 12)

    local titleBarCover = Instance.new("Frame")
    titleBarCover.Size = UDim2.new(1, 0, 0, 12)
    titleBarCover.Position = UDim2.new(0, 0, 1, -12)
    titleBarCover.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    titleBarCover.BorderSizePixel = 0
    titleBarCover.ZIndex = titleBar.ZIndex + 1
    titleBarCover.Parent = titleBar

    -- Traffic lights (macOS style với chức năng)
    local controls = Instance.new("Frame")
    controls.Size = UDim2.new(0, 60, 0, 12)
    controls.Position = UDim2.new(0, 12, 0, 16)
    controls.BackgroundTransparency = 1
    controls.Parent = titleBar

    local trafficColors = {
        Color3.fromRGB(255, 95, 87),    -- Red (Close)
        Color3.fromRGB(255, 189, 46),   -- Yellow (Minimize)
        Color3.fromRGB(40, 205, 65)     -- Green (Maximize)
    }
    
    local trafficButtons = {}
    for i, color in ipairs(trafficColors) do
        local dot = Instance.new("TextButton")  -- Thay đổi từ Frame sang TextButton
        dot.Size = UDim2.new(0, 12, 0, 12)
        dot.Position = UDim2.new(0, (i - 1) * 20, 0, 0)
        dot.BackgroundColor3 = color
        dot.BorderSizePixel = 0
        dot.BackgroundTransparency = 0  -- Show buttons ngay
        dot.Text = ""
        dot.AutoButtonColor = false
        dot.Parent = controls
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)
        
        trafficButtons[i] = dot
        
        -- Red button: Close
        if i == 1 then
            dot.MouseButton1Click:Connect(function()
                -- Animation: Scale down + fade
                TweenService:Create(window, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                    Size = UDim2.new(0, 0, 0, 0),
                    Rotation = 90
                }):Play()
                task.wait(0.25)
                screenGui:Destroy()
            end)
        end
        
        -- Yellow button: Minimize (shrink to titlebar)
        if i == 2 then
            local isMinimized = false
            local normalSize = UDim2.new(0, windowWidth, 0, windowHeight)
            local minimizedSize = UDim2.new(0, windowWidth, 0, 44)
            
            dot.MouseButton1Click:Connect(function()
                isMinimized = not isMinimized
                if isMinimized then
                    -- Hide content
                    content.Visible = false
                    TweenService:Create(window, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                        Size = minimizedSize
                    }):Play()
                else
                    -- Show content
                    content.Visible = true
                    TweenService:Create(window, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                        Size = normalSize
                    }):Play()
                end
            end)
        end
        
        -- Green button: Toggle fullscreen/normal
        if i == 3 then
            local isFullscreen = false
            local normalSize = UDim2.new(0, windowWidth, 0, windowHeight)
            local normalPos = UDim2.new(0.5, -windowWidth / 2, 0.5, -windowHeight / 2)
            
            dot.MouseButton1Click:Connect(function()
                isFullscreen = not isFullscreen
                if isFullscreen then
                    TweenService:Create(window, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                        Size = UDim2.new(0, 600, 0, 400),
                        Position = UDim2.new(0.5, -300, 0.5, -200)
                    }):Play()
                else
                    TweenService:Create(window, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
                        Size = normalSize,
                        Position = normalPos
                    }):Play()
                end
            end)
        end
        
        -- Hover effect for all buttons
        dot.MouseEnter:Connect(function()
            TweenService:Create(dot, TweenInfo.new(0.1), {
                BackgroundTransparency = 0.3
            }):Play()
        end)
        dot.MouseLeave:Connect(function()
            TweenService:Create(dot, TweenInfo.new(0.1), {
                BackgroundTransparency = 0
            }):Play()
        end)
    end

    -- Title text
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -160, 0, 44)
    title.Position = UDim2.new(0, 80, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "PawZHub"  -- Đổi từ "PawZHub Key System"
    title.TextColor3 = Color3.fromRGB(240, 240, 245)  -- Chữ sáng trên nền tối
    title.TextSize = 14
    title.Font = Enum.Font.GothamMedium
    title.TextTransparency = 0
    title.Parent = titleBar
    
    -- Discord button (nút duy nhất bên phải)
    local discordBtn = Instance.new("TextButton")
    discordBtn.Size = UDim2.new(0, 80, 0, 28)
    discordBtn.Position = UDim2.new(1, -90, 0, 8)
    discordBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)  -- Discord color
    discordBtn.BorderSizePixel = 0
    discordBtn.Text = "Discord"
    discordBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    discordBtn.TextSize = 12
    discordBtn.Font = Enum.Font.GothamBold
    discordBtn.AutoButtonColor = false
    discordBtn.Parent = titleBar
    
    Instance.new("UICorner", discordBtn).CornerRadius = UDim.new(0, 6)
    
    -- Discord button hover + click
    discordBtn.MouseEnter:Connect(function()
        TweenService:Create(discordBtn, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(108, 121, 255),
            Size = UDim2.new(0, 82, 0, 30)
        }):Play()
    end)
    discordBtn.MouseLeave:Connect(function()
        TweenService:Create(discordBtn, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(88, 101, 242),
            Size = UDim2.new(0, 80, 0, 28)
        }):Play()
    end)
    discordBtn.MouseButton1Click:Connect(function()
        local discordLink = "https://discord.gg/pawzhub"
        if setclipboard then
            setclipboard(discordLink)
            discordBtn.Text = "✓ Copied"
            TweenService:Create(discordBtn, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(40, 205, 65)
            }):Play()
            task.wait(1.5)
            discordBtn.Text = "Discord"
            TweenService:Create(discordBtn, TweenInfo.new(0.2), {
                BackgroundColor3 = Color3.fromRGB(88, 101, 242)
            }):Play()
        end
    end)

    -- Content
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -40, 1, -60)
    content.Position = UDim2.new(0, 20, 0, 52)
    content.BackgroundTransparency = 1
    content.Parent = window

    -- Key type label
    local typeLabel = Instance.new("TextLabel")
    typeLabel.Size = UDim2.new(1, 0, 0, 16)
    typeLabel.Position = UDim2.new(0, 0, 0, 4)
    typeLabel.BackgroundTransparency = 1
    typeLabel.Text = "Key (PAWZ-XXXX-XXXX-XXXX or 24 hex chars)"
    typeLabel.TextColor3 = Color3.fromRGB(160, 165, 175)  -- Chữ sáng
    typeLabel.TextSize = 11
    typeLabel.Font = Enum.Font.Gotham
    typeLabel.TextXAlignment = Enum.TextXAlignment.Left
    typeLabel.TextTransparency = 0  -- Show text
    typeLabel.Parent = content

    -- Input container
    local inputContainer = Instance.new("Frame")
    inputContainer.Size = UDim2.new(1, 0, 0, 36)
    inputContainer.Position = UDim2.new(0, 0, 0, 24)
    inputContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 45)  -- Input tối
    inputContainer.BorderSizePixel = 0
    inputContainer.BackgroundTransparency = 0  -- Show input
    inputContainer.Parent = content

    Instance.new("UICorner", inputContainer).CornerRadius = UDim.new(0, 6)

    local inputBorder = Instance.new("UIStroke", inputContainer)
    inputBorder.Color = Color3.fromRGB(60, 65, 75)  -- Border tối
    inputBorder.Thickness = 1

    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1, -20, 1, 0)
    input.Position = UDim2.new(0, 10, 0, 0)
    input.BackgroundTransparency = 1
    input.Text = ""
    input.PlaceholderText = "Enter your key..."
    input.TextColor3 = Color3.fromRGB(240, 240, 245)  -- Chữ sáng
    input.PlaceholderColor3 = Color3.fromRGB(120, 125, 135)  -- Placeholder tối
    input.TextSize = 13
    input.Font = Enum.Font.Gotham
    input.ClearTextOnFocus = false
    input.TextTransparency = 0  -- Show text
    input.Parent = inputContainer

    -- Focus effects với animation
    input.Focused:Connect(function()
        TweenService:Create(inputBorder, TweenInfo.new(0.2), {
            Color = Color3.fromRGB(0, 122, 255), 
            Thickness = 2
        }):Play()
        TweenService:Create(inputContainer, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(45, 45, 50)
        }):Play()
        -- Glow effect
        TweenService:Create(input, TweenInfo.new(0.2), {
            TextColor3 = Color3.fromRGB(255, 255, 255)
        }):Play()
    end)
    input.FocusLost:Connect(function()
        TweenService:Create(inputBorder, TweenInfo.new(0.2), {
            Color = Color3.fromRGB(60, 65, 75), 
            Thickness = 1
        }):Play()
        TweenService:Create(inputContainer, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(40, 40, 45)
        }):Play()
        TweenService:Create(input, TweenInfo.new(0.2), {
            TextColor3 = Color3.fromRGB(240, 240, 245)
        }):Play()
    end)

    -- Buttons container
    local btnContainer = Instance.new("Frame")
    btnContainer.Size = UDim2.new(1, 0, 0, 32)
    btnContainer.Position = UDim2.new(0, 0, 1, -40)
    btnContainer.BackgroundTransparency = 1
    btnContainer.Parent = content

    -- Get Key button
    local getKeyBtn = Instance.new("TextButton")
    getKeyBtn.Size = UDim2.new(0.48, 0, 1, 0)
    getKeyBtn.Position = UDim2.new(0, 0, 0, 0)
    getKeyBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55)  -- Nút tối
    getKeyBtn.BorderSizePixel = 0
    getKeyBtn.Text = "Get Key"
    getKeyBtn.TextColor3 = Color3.fromRGB(240, 240, 245)  -- Chữ sáng
    getKeyBtn.TextSize = 13
    getKeyBtn.Font = Enum.Font.GothamMedium
    getKeyBtn.AutoButtonColor = false
    getKeyBtn.BackgroundTransparency = 0  -- Show button
    getKeyBtn.Parent = btnContainer

    Instance.new("UICorner", getKeyBtn).CornerRadius = UDim.new(0, 6)

    local getKeyBorder = Instance.new("UIStroke", getKeyBtn)
    getKeyBorder.Color = Color3.fromRGB(70, 75, 85)  -- Border tối
    getKeyBorder.Thickness = 1

    -- Submit button
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
    submitBtn.BackgroundTransparency = 0  -- Show button
    submitBtn.Parent = btnContainer

    Instance.new("UICorner", submitBtn).CornerRadius = UDim.new(0, 6)

    -- HWID Reset button (below input, initially hidden)
    local resetBtn = Instance.new("TextButton")
    resetBtn.Size = UDim2.new(1, 0, 0, 28)
    resetBtn.Position = UDim2.new(0, 0, 0, 64)
    resetBtn.BackgroundColor3 = Color3.fromRGB(255, 149, 0)
    resetBtn.BorderSizePixel = 0
    resetBtn.Text = "Reset HWID (Lifetime keys only)"
    resetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    resetBtn.TextSize = 11
    resetBtn.Font = Enum.Font.GothamMedium
    resetBtn.AutoButtonColor = false
    resetBtn.Visible = false
    resetBtn.Parent = content

    Instance.new("UICorner", resetBtn).CornerRadius = UDim.new(0, 6)

    -- Status
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, 0, 0, 18)
    status.Position = UDim2.new(0, 0, 0, 96)
    status.BackgroundTransparency = 1
    status.Text = ""
    status.TextColor3 = Color3.fromRGB(255, 59, 48)
    status.TextSize = 11
    status.Font = Enum.Font.Gotham
    status.TextTransparency = 0  -- Show status
    status.Parent = content

    -- Hover effects với scale animation
    getKeyBtn.MouseEnter:Connect(function()
        TweenService:Create(getKeyBtn, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(60, 60, 65),
            Size = UDim2.new(0.48, 2, 1, 2)  -- Scale up slightly
        }):Play()
    end)
    getKeyBtn.MouseLeave:Connect(function()
        TweenService:Create(getKeyBtn, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(50, 50, 55),
            Size = UDim2.new(0.48, 0, 1, 0)
        }):Play()
    end)
    submitBtn.MouseEnter:Connect(function()
        TweenService:Create(submitBtn, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(20, 142, 255),
            Size = UDim2.new(0.48, 2, 1, 2)  -- Scale up
        }):Play()
    end)
    submitBtn.MouseLeave:Connect(function()
        TweenService:Create(submitBtn, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(0, 122, 255),
            Size = UDim2.new(0.48, 0, 1, 0)
        }):Play()
    end)

    -- ============================================
    -- GET KEY: Link to https://getpawzhub.vercel.app/getkey
    -- ============================================
    local getKeyEventConnection
    
    getKeyEventConnection = getKeyBtn.MouseButton1Click:Connect(function()
        local getkeyUrl = "https://getpawzhub.vercel.app/getkey"
        
        -- Copy link to clipboard
        if setclipboard then
            setclipboard(getkeyUrl)
            getKeyBtn.Text = "Link Copied!"
            status.Text = "Get key link copied to clipboard!"
            status.TextColor3 = Color3.fromRGB(40, 205, 65)  -- Green
            
            task.wait(2)
            getKeyBtn.Text = "Get Key"
            status.Text = ""
        else
            status.Text = "Link: " .. getkeyUrl
            status.TextColor3 = Color3.fromRGB(0, 122, 255)
        end
    end)

    -- ============================================
    -- HWID RESET (for lifetime keys)
    -- ============================================
    resetBtn.MouseButton1Click:Connect(function()
        local key = input.Text
        if not key or #key ~= 24 then
            status.Text = "Enter your 24-char lifetime key first"
            status.TextColor3 = Color3.fromRGB(255, 149, 0)
            return
        end

        resetBtn.Text = "Resetting..."
        resetBtn.BackgroundColor3 = Color3.fromRGB(200, 120, 0)

        local ok, msg = CheckKeySystem.requestHWIDReset(key)

        if ok then
            status.Text = "HWID reset! You can use key on new device."
            status.TextColor3 = Color3.fromRGB(52, 199, 89)
            resetBtn.Text = "HWID Reset Complete!"
            resetBtn.BackgroundColor3 = Color3.fromRGB(52, 199, 89)
            task.wait(2)
            resetBtn.Visible = false
        else
            status.Text = msg or "Reset failed"
            status.TextColor3 = Color3.fromRGB(255, 59, 48)
            resetBtn.Text = "Reset HWID (Lifetime keys only)"
            resetBtn.BackgroundColor3 = Color3.fromRGB(255, 149, 0)
        end

        TweenService:Create(status, TweenInfo.new(0.15), { TextTransparency = 0 }):Play()
    end)

    -- ============================================
    -- SUBMIT KEY
    -- ============================================
    submitBtn.MouseButton1Click:Connect(function()
        local key = input.Text

        if not key or #key < 5 then
            status.Text = "Please enter a valid key"
            status.TextColor3 = Color3.fromRGB(255, 59, 48)
            TweenService:Create(status, TweenInfo.new(0.15), { TextTransparency = 0 }):Play()

            -- Shake animation
            local origPos = inputContainer.Position
            for _, offset in ipairs({8, -8, 4, 0}) do
                TweenService:Create(inputContainer, TweenInfo.new(0.05), {
                    Position = origPos + UDim2.new(0, offset, 0, 0)
                }):Play()
                task.wait(0.06)
            end
            return
        end

        -- Show HWID reset button for lifetime keys
        local keyType = detectKeyType(key)
        if keyType == "lifetime" then
            resetBtn.Visible = true
        else
            resetBtn.Visible = false
        end

        -- Loading state
        submitBtn.Text = "Verifying..."
        TweenService:Create(submitBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.fromRGB(100, 150, 200)
        }):Play()
        status.Text = "Checking key..."
        status.TextColor3 = Color3.fromRGB(100, 110, 130)
        TweenService:Create(status, TweenInfo.new(0.15), { TextTransparency = 0 }):Play()

        task.spawn(function()
            local valid, message, keyData = verifyKeyRemote(key)

            if valid then
                submitBtn.Text = "✓ Success"
                TweenService:Create(submitBtn, TweenInfo.new(0.25, Enum.EasingStyle.Back), {
                    BackgroundColor3 = Color3.fromRGB(52, 199, 89),
                    Size = UDim2.new(0.48, 5, 1, 3)  -- Pop effect
                }):Play()
                status.Text = "Access granted! Loading..."
                status.TextColor3 = Color3.fromRGB(52, 199, 89)

                task.wait(0.8)
                local session = createSession(key, keyData)

                -- Fade out with rotation (NO BACKDROP)
                TweenService:Create(window, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                    Size = UDim2.new(0, 0, 0, 0),
                    Rotation = 180,
                    BackgroundTransparency = 1
                }):Play()
                TweenService:Create(windowBorder, TweenInfo.new(0.3), {
                    Transparency = 1
                }):Play()
                
                task.wait(0.3)
                screenGui:Destroy()

                if callback then callback(true, session) end
            else
                submitBtn.Text = "✗ Failed"
                TweenService:Create(submitBtn, TweenInfo.new(0.15), {
                    BackgroundColor3 = Color3.fromRGB(255, 59, 48)
                }):Play()
                
                -- Shake animation
                local originalPos = window.Position
                for i = 1, 3 do
                    TweenService:Create(window, TweenInfo.new(0.05), {
                        Position = originalPos + UDim2.new(0, 10, 0, 0)
                    }):Play()
                    task.wait(0.05)
                    TweenService:Create(window, TweenInfo.new(0.05), {
                        Position = originalPos + UDim2.new(0, -10, 0, 0)
                    }):Play()
                    task.wait(0.05)
                end
                TweenService:Create(window, TweenInfo.new(0.1), {
                    Position = originalPos
                }):Play()
                
                status.Text = message or "Invalid key"
                status.TextColor3 = Color3.fromRGB(255, 59, 48)
                
                task.wait(1)
                submitBtn.Text = "Submit"
                TweenService:Create(submitBtn, TweenInfo.new(0.2), {
                    BackgroundColor3 = Color3.fromRGB(0, 122, 255)
                }):Play()

                State.failedAttempts += 1
                if State.failedAttempts >= CONFIG.MAX_RETRY_ATTEMPTS then
                    State.lockedUntil = os.time() + CONFIG.LOCKOUT_DURATION
                    status.Text = "Too many attempts. Wait " .. CONFIG.LOCKOUT_DURATION .. "s"
                end
            end
        end)
    end)

    -- ============================================
    -- DRAGGABLE (titlebar only)
    -- ============================================
    local dragging, dragStart, startPos = false, nil, nil

    titleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = window.Position
        end
    end)

    titleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            window.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    -- ============================================
    -- ENTRY ANIMATION - Clean bounce (NO BACKDROP)
    -- ============================================
    screenGui.Parent = playerGui

    -- Start state
    window.BackgroundTransparency = 1
    windowBorder.Transparency = 1
    titleBar.BackgroundTransparency = 1
    
    for _, dot in ipairs(trafficButtons) do
        dot.BackgroundTransparency = 1
    end

    -- Window bounce in
    window.Size = UDim2.new(0, windowWidth * 0.7, 0, windowHeight * 0.7)
    window.Position = UDim2.new(0.5, -(windowWidth * 0.7) / 2, 0.5, -(windowHeight * 0.7) / 2)
    window.Rotation = -5

    TweenService:Create(window, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, windowWidth, 0, windowHeight),
        Position = UDim2.new(0.5, -windowWidth / 2, 0.5, -windowHeight / 2),
        BackgroundTransparency = 0,
        Rotation = 0
    }):Play()

    TweenService:Create(windowBorder, TweenInfo.new(0.4), { Transparency = 0 }):Play()

    task.wait(0.2)

    TweenService:Create(titleBar, TweenInfo.new(0.25), { BackgroundTransparency = 0 }):Play()

    for i, dot in ipairs(trafficButtons) do
        task.wait(0.05)
        dot.Size = UDim2.new(0, 8, 0, 8)
        TweenService:Create(dot, TweenInfo.new(0.25, Enum.EasingStyle.Back), {
            Size = UDim2.new(0, 12, 0, 12),
            BackgroundTransparency = 0
        }):Play()
    end

    task.wait(0.1)

    -- Content elements
    for _, obj in ipairs({title, typeLabel}) do
        TweenService:Create(obj, TweenInfo.new(0.25), { TextTransparency = 0 }):Play()
        task.wait(0.03)
    end

    TweenService:Create(inputContainer, TweenInfo.new(0.25), { BackgroundTransparency = 0 }):Play()
    TweenService:Create(input, TweenInfo.new(0.25), { TextTransparency = 0 }):Play()

    task.wait(0.05)

    for _, btn in ipairs({submitBtn, getKeyBtn}) do
        TweenService:Create(btn, TweenInfo.new(0.25), { BackgroundTransparency = 0 }):Play()
    end
end

-- ============================================
-- PUBLIC API
-- ============================================

function CheckKeySystem.show(callback)
    fetchBlacklist()
    local executorInfo = detectExecutor()
    createKeyUI(callback, executorInfo)
end

function CheckKeySystem.hasFeature(featureName)
    local valid, session = CheckKeySystem.verifySession()
    if not valid then return false end
    for _, f in ipairs(session.keyFeatures) do
        if f == featureName then return true end
    end
    return false
end

function CheckKeySystem.getKeyType()
    local valid, session = CheckKeySystem.verifySession()
    if not valid then return nil end
    return session.keyType
end

return CheckKeySystem

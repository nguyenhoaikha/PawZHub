-- PawZHub Key System v4.0
-- Clean black/white/gray design (matches the web app at getpawzhub.vercel.app)
-- No icons, no gradients, no star-burst background.
-- Supports: free JWT keys, premium PH.* keys, HWID binding, server-side
-- checkpoint tokens (set in /api/checkpoint/complete by the callback page).

local CheckKeySystem = {}

-- ============================================
-- CONFIG
-- ============================================
local SITE_URL = "https://getpawzhub.vercel.app"
local GET_KEY_URL = SITE_URL .. "/getkey"

local CONFIG = {
    -- Backend API
    API_BASE_URL       = SITE_URL .. "/api",
    KEY_CHECK_URL      = SITE_URL .. "/api/verifykey",
    HWID_RESET_URL     = SITE_URL .. "/api/hwid-reset",

    -- Discord / support
    DISCORD_URL        = "https://discord.gg/pawzhub",
    SUPPORT_URL        = SITE_URL .. "/discord",

    -- Timing & limits
    SESSION_DURATION   = 3600,  -- 1 hour in-game session
    MAX_RETRY_ATTEMPTS = 3,
    LOCKOUT_DURATION   = 3,     -- seconds
    RATE_LIMIT_COOLDOWN= 2,     -- seconds between verify attempts
    CACHE_DURATION     = 60,    -- cache a valid key locally for N seconds

    -- Features
    ENABLE_HWID_BINDING = true,
    ALLOW_OFFLINE_MODE  = false,
    CURRENT_VERSION     = "4.0.0",
    DEBUG_MODE          = false,
}

-- ============================================
-- THEME — black/white/gray only, no icons/gradients
-- ============================================
local T = {
    bg          = Color3.fromRGB(0, 0, 0),         -- pure black background
    surface     = Color3.fromRGB(14, 14, 14),     -- card surface
    surfaceAlt  = Color3.fromRGB(20, 20, 20),
    border      = Color3.fromRGB(38, 38, 38),     -- subtle border
    borderHi    = Color3.fromRGB(64, 64, 64),
    text        = Color3.fromRGB(255, 255, 255),
    textMuted   = Color3.fromRGB(140, 140, 140),
    textDim     = Color3.fromRGB(90, 90, 90),
    ok          = Color3.fromRGB(74, 222, 128),
    err         = Color3.fromRGB(248, 113, 113),
    warn        = Color3.fromRGB(250, 204, 21),
    btn         = Color3.fromRGB(255, 255, 255),
    btnText     = Color3.fromRGB(0, 0, 0),
}

-- ============================================
-- STATE
-- ============================================
local State = {
    failedAttempts  = 0,
    lockedUntil     = 0,
    lastRequestTime = 0,
    keyCache        = {},
    blacklistedUsers= {},
    versionOk       = true,
    latestVersion   = CONFIG.CURRENT_VERSION,
}

local function debugLog(...)
    if CONFIG.DEBUG_MODE then
        print("[PawZHub Debug]", ...)
    end
end

-- ============================================
-- UTILITIES
-- ============================================
local function generateToken()
    return game:GetService("HttpService"):GenerateGUID(false):gsub("-", ""):sub(1, 32)
end

local function getHWID()
    local UIS = game:GetService("UserInputService")
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
    if UIS.TouchEnabled and not UIS.KeyboardEnabled then
        platform = "mobile"
    elseif UIS.KeyboardEnabled then
        platform = "pc"
    end
    table.insert(components, platform)

    local combined = table.concat(components, "|")
    local function hash(s)
        local h = 2166136261
        for i = 1, #s do
            h = bit32.bxor(h, string.byte(s, i))
            h = (h * 16777619) % 4294967296
        end
        return h
    end
    local hwid = string.format("%08X%08X", hash(combined), hash(combined .. "salt"))
    _G.PawZHub_HWID = hwid
    return hwid
end

-- ============================================
-- KEY TYPE DETECTION
-- ============================================
local function detectKeyType(key)
    if not key or type(key) ~= "string" then return nil end
    key = key:match("^%s*(.-)%s*$") or key
    if key:match("^[a-f0-9]{24}$") then return "lifetime" end
    if key:match("^PAWZ%-[A-Z0-9]+%-[A-Z0-9]+%-[A-Z0-9]+$") then return "free" end
    if key:sub(1, 3) == "PH." and key:match("^PH%.[A-Za-z0-9_%-]+%.[A-Za-z0-9_%-]+$") then
        return "premium"
    end
    if key:match("^ey[A-Za-z0-9_%-]+%.[A-Za-z0-9_%-]+%.[A-Za-z0-9_%-]+$") then
        return "web"
    end
    return nil
end

local function normalizeKey(key)
    if not key or type(key) ~= "string" then return "" end
    key = key:match("^%s*(.-)%s*$") or key
    if key:match("^[a-fA-F0-9]{24}$") then return key:lower() end
    -- Web keys (JWT / PH.*) are case-sensitive.
    if detectKeyType(key) == "web" or detectKeyType(key) == "premium" then
        return key
    end
    return key:upper()
end

-- ============================================
-- RATE LIMIT / LOCKOUT
-- ============================================
local function checkRateLimit()
    local now = os.time()
    if now - State.lastRequestTime < CONFIG.RATE_LIMIT_COOLDOWN then
        return false, "Please wait a moment"
    end
    State.lastRequestTime = now
    return true
end

local function checkLockout()
    if State.lockedUntil > os.time() then
        return false, "Locked for " .. (State.lockedUntil - os.time()) .. "s"
    end
    if State.lockedUntil > 0 and State.lockedUntil <= os.time() then
        State.failedAttempts = 0
        State.lockedUntil = 0
    end
    return true
end

local function registerFailedAttempt()
    State.failedAttempts = State.failedAttempts + 1
    if State.failedAttempts >= CONFIG.MAX_RETRY_ATTEMPTS then
        State.lockedUntil = os.time() + CONFIG.LOCKOUT_DURATION
        return true, CONFIG.LOCKOUT_DURATION
    end
    return false, 0
end

-- ============================================
-- HTTP REQUEST — multi-method fallback
-- ============================================
local function httpPostJson(url, jsonBody)
    local HttpService = game:GetService("HttpService")
    local headers = { ["Content-Type"] = "application/json" }

    -- 1. Standard Roblox HttpService:PostAsync
    local ok, resp = pcall(function()
        return HttpService:PostAsync(
            url, jsonBody,
            Enum.HttpContentType.ApplicationJson,
            false, headers
        )
    end)
    if ok and resp and resp ~= "" then return resp end

    -- 2. request() (Synapse X, Script-Ware, etc.)
    if type(request) == "function" then
        ok, resp = pcall(function()
            return request({ Url = url, Method = "POST", Headers = headers, Body = jsonBody })
        end)
        if ok and type(resp) == "table" and resp.StatusCode and resp.StatusCode < 400 then
            return resp.Body or resp.body or ""
        end
    end

    -- 3. http_request() (alternate)
    if type(http_request) == "function" then
        ok, resp = pcall(function()
            return http_request(url, "POST", jsonBody, headers)
        end)
        if ok and resp and resp ~= "" then return resp end
    end

    -- 4. syn.request (older Synapse X)
    if syn and type(syn.request) == "function" then
        ok, resp = pcall(function()
            return syn.request({ Url = url, Method = "POST", Headers = headers, Body = jsonBody })
        end)
        if ok and type(resp) == "table" and resp.StatusCode and resp.StatusCode < 400 then
            return resp.Body or resp.body or ""
        end
    end

    return nil
end

-- ============================================
-- KEY VERIFICATION
-- ============================================
local function verifyKeyOffline(key)
    -- Only used when ALLOW_OFFLINE_MODE is true (dev / offline testing).
    local testKeys = {
        ["PAWZ-FREE-2024-DEMO1"]   = { type = "free", tier = "free",     expiry = nil, features = {"basic"} },
        ["PAWZ-PREM-2024-TEST"]   = { type = "free", tier = "premium",  expiry = os.time() + 30*24*3600, features = {"basic","advanced"} },
        ["PAWZ-LIFE-2024-VIP1"]   = { type = "free", tier = "lifetime", expiry = nil, features = {"basic","advanced","premium","exclusive"} },
        ["f03d3260914a9475faf29b12"] = { type = "lifetime", tier = "lifetime", expiry = nil, features = {"basic","advanced","premium","exclusive"}, hwidResetAvailable = true },
    }
    local data = testKeys[key]
    if data then
        if data.expiry and os.time() > data.expiry then
            return false, "Key expired", nil
        end
        return true, "Valid (offline)", data
    end
    return false, "Invalid key"
end

local function verifyKeyRemote(key)
    local canProceed, msg = checkRateLimit()
    if not canProceed then return false, msg end
    local lockOk, lockMsg = checkLockout()
    if not lockOk then return false, lockMsg end

    local player = game:GetService("Players").LocalPlayer
    if State.blacklistedUsers[tostring(player.UserId)] then
        return false, "Account blacklisted"
    end

    local cached = State.keyCache[key]
    if cached and (os.time() - cached.ts) < CONFIG.CACHE_DURATION then
        return true, "Valid (cached)", cached.data
    end

    local HttpService = game:GetService("HttpService")
    local requestData = {
        key       = key,
        hwid      = getHWID(),
        userId    = player.UserId,
        username  = player.Name,
        gameId    = game.PlaceId,
        version   = CONFIG.CURRENT_VERSION,
        timestamp = os.time(),
    }
    local body = HttpService:JSONEncode(requestData)
    local response = httpPostJson(CONFIG.KEY_CHECK_URL, body)

    if response and response ~= "" then
        local ok, data = pcall(function() return HttpService:JSONDecode(response) end)
        if not ok or type(data) ~= "table" then
            return false, "Bad server response"
        end
        if data.valid then
            State.keyCache[key] = { data = data, ts = os.time() }
            State.failedAttempts = 0
            State.lockedUntil = 0
            return true, data.message or "Valid", data
        else
            return false, data.message or "Invalid key"
        end
    end

    if CONFIG.ALLOW_OFFLINE_MODE then
        return verifyKeyOffline(key)
    end
    return false, "Server unreachable — check executor HTTP permissions"
end

function CheckKeySystem.requestHWIDReset(key)
    key = normalizeKey(key)
    local HttpService = game:GetService("HttpService")
    local body = HttpService:JSONEncode({
        key    = key,
        hwid   = getHWID(),
        userId = game:GetService("Players").LocalPlayer.UserId,
    })
    local response = httpPostJson(CONFIG.HWID_RESET_URL, body)
    if response and response ~= "" then
        local ok, data = pcall(function() return HttpService:JSONDecode(response) end)
        if ok and type(data) == "table" then
            return data.success, data.message
        end
    end
    return false, "Server unreachable"
end

-- ============================================
-- SESSION
-- ============================================
local function createSession(key, keyData)
    local token  = generateToken()
    local hwid   = getHWID()
    local player = game:GetService("Players").LocalPlayer

    local sessionData = {
        token        = token,
        key          = key,
        keyType      = detectKeyType(key) or (keyData and keyData.type) or "free",
        hwid         = hwid,
        timestamp    = os.time(),
        expiresAt    = os.time() + CONFIG.SESSION_DURATION,
        gameId       = game.PlaceId,
        userId       = player.UserId,
        username     = player.Name,
        keyTier      = keyData and keyData.tier or "free",
        keyExpiry    = keyData and keyData.expiry or nil,
        keyFeatures  = keyData and keyData.features or {},
        sessionId    = generateToken():sub(1, 16),
    }

    _G.PawZHubSession = sessionData
    _G.PawZHub_Token = token
    _G.PawZHub_Authenticated = true
    return sessionData
end

function CheckKeySystem.verifySession()
    if not _G.PawZHubSession then return false, "No session" end
    local s = _G.PawZHubSession
    if os.time() > s.expiresAt then
        CheckKeySystem.destroySession()
        return false, "Session expired"
    end
    if CONFIG.ENABLE_HWID_BINDING and s.hwid ~= getHWID() then
        CheckKeySystem.destroySession()
        return false, "HWID mismatch"
    end
    return true, s
end

function CheckKeySystem.destroySession()
    _G.PawZHubSession = nil
    _G.PawZHub_Token = nil
    _G.PawZHub_Authenticated = nil
end

function CheckKeySystem.extendSession(extraSeconds)
    local valid, session = CheckKeySystem.verifySession()
    if not valid then return false end
    session.expiresAt = os.time() + (extraSeconds or CONFIG.SESSION_DURATION)
    return true
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
-- UI HELPERS
-- ============================================
local function CreateElement(className, props)
    local obj = Instance.new(className)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then obj[k] = v end
    end
    if props and props.Parent then obj.Parent = props.Parent end
    return obj
end

local function AddCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function AddStroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or T.border
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

-- ============================================
-- UI — minimal black/white/gray modal
-- ============================================

local function createKeyUI(callback, executorInfo)
    local Players = game:GetService("Players")
    local TweenService = game:GetService("TweenService")
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    -- Remove any prior instance
    local oldGui = playerGui:FindFirstChild("PawZHubKeySystem")
    if oldGui then oldGui:Destroy() end

    local isMobile = executorInfo and (
        executorInfo.platform == "Mobile"
        or executorInfo.platform == "iOS"
        or executorInfo.platform == "Android"
    )
    local WIN_W = isMobile and 320 or 380
    local WIN_H = isMobile and 320 or 360

    local screenGui = CreateElement("ScreenGui", {
        Name = "PawZHubKeySystem",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        Parent = playerGui,
    })

    local dim = CreateElement("Frame", {
        Name = "Dim",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.6,
        BorderSizePixel = 0,
        Parent = screenGui,
    })

    local window = CreateElement("Frame", {
        Name = "Main",
        Size = UDim2.new(0, WIN_W, 0, WIN_H),
        Position = UDim2.new(0.5, -WIN_W / 2, 0.5, -WIN_H / 2),
        BackgroundColor3 = T.surface,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Active = true,
        Parent = screenGui,
    })
    AddCorner(window, 10)
    AddStroke(window, T.border, 1, 0)

    -- Header
    local header = CreateElement("Frame", {
        Size = UDim2.new(1, 0, 0, 44),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = T.surfaceAlt,
        BorderSizePixel = 0,
        Parent = window,
    })
    CreateElement("TextLabel", {
        Size = UDim2.new(1, -60, 1, 0),
        Position = UDim2.new(0, 16, 0, 0),
        BackgroundTransparency = 1,
        Text = "PawZHub  ·  Key System",
        TextColor3 = T.text,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header,
    })
    local closeBtn = CreateElement("TextButton", {
        Size = UDim2.new(0, 28, 0, 28),
        Position = UDim2.new(1, -36, 0, 8),
        BackgroundColor3 = T.surface,
        BackgroundTransparency = 0.5,
        Text = "×",
        TextColor3 = T.textMuted,
        TextSize = 18,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        Parent = header,
    })
    AddCorner(closeBtn, 6)
    closeBtn.MouseEnter:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.15), { TextColor3 = T.text, BackgroundTransparency = 0 }):Play()
    end)
    closeBtn.MouseLeave:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.15), { TextColor3 = T.textMuted, BackgroundTransparency = 0.5 }):Play()
    end)
    closeBtn.MouseButton1Click:Connect(function()
        TweenService:Create(window, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, WIN_W * 0.95, 0, WIN_H * 0.95),
            BackgroundTransparency = 1,
        }):Play()
        TweenService:Create(dim, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
        task.wait(0.2)
        screenGui:Destroy()
    end)

    -- Body
    local body = CreateElement("Frame", {
        Size = UDim2.new(1, -32, 1, -84),
        Position = UDim2.new(0, 16, 0, 52),
        BackgroundTransparency = 1,
        Parent = window,
    })

    -- Status line
    local statusLabel = CreateElement("TextLabel", {
        Size = UDim2.new(1, 0, 0, 18),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = "Enter your PawZHub key to verify",
        TextColor3 = T.textMuted,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = body,
    })

    -- Input + verify row
    local input = CreateElement("TextBox", {
        Size = UDim2.new(1, 0, 0, 36),
        Position = UDim2.new(0, 0, 0, 26),
        BackgroundColor3 = T.surfaceAlt,
        Text = "",
        PlaceholderText = "Paste your key (eyJ… or PH.…)",
        PlaceholderColor3 = T.textDim,
        TextColor3 = T.text,
        TextSize = 12,
        Font = Enum.Font.Code,
        ClearTextOnFocus = false,
        Parent = body,
    })
    AddCorner(input, 6)
    AddStroke(input, T.border, 1, 0)

    local verifyBtn = CreateElement("TextButton", {
        Size = UDim2.new(1, 0, 0, 36),
        Position = UDim2.new(0, 0, 0, 70),
        BackgroundColor3 = T.btn,
        Text = "Verify",
        TextColor3 = T.btnText,
        TextSize = 13,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        Parent = body,
    })
    AddCorner(verifyBtn, 6)
    verifyBtn.MouseEnter:Connect(function()
        TweenService:Create(verifyBtn, TweenInfo.new(0.12), { BackgroundColor3 = T.text }):Play()
    end)
    verifyBtn.MouseLeave:Connect(function()
        TweenService:Create(verifyBtn, TweenInfo.new(0.12), { BackgroundColor3 = T.btn }):Play()
    end)

    -- Get key + Discord link (2-column)
    local linkRow = CreateElement("Frame", {
        Size = UDim2.new(1, 0, 0, 32),
        Position = UDim2.new(0, 0, 0, 114),
        BackgroundTransparency = 1,
        Parent = body,
    })
    local getKeyBtn = CreateElement("TextButton", {
        Size = UDim2.new(0.5, -4, 1, 0),
        BackgroundColor3 = T.surfaceAlt,
        Text = "Get Key",
        TextColor3 = T.text,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        Parent = linkRow,
    })
    AddCorner(getKeyBtn, 6)
    AddStroke(getKeyBtn, T.border, 1, 0)
    getKeyBtn.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(GET_KEY_URL)
            statusLabel.Text = "Get Key URL copied to clipboard"
            statusLabel.TextColor3 = T.ok
        else
            statusLabel.Text = "Visit: " .. GET_KEY_URL
            statusLabel.TextColor3 = T.text
        end
    end)

    local discordBtn = CreateElement("TextButton", {
        Size = UDim2.new(0.5, -4, 0, 0),
        Position = UDim2.new(0.5, 4, 0, 0),
        BackgroundColor3 = T.surfaceAlt,
        Text = "Discord",
        TextColor3 = T.text,
        TextSize = 12,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        Parent = linkRow,
    })
    AddCorner(discordBtn, 6)
    AddStroke(discordBtn, T.border, 1, 0)
    discordBtn.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(CONFIG.DISCORD_URL)
            statusLabel.Text = "Discord URL copied to clipboard"
            statusLabel.TextColor3 = T.ok
        end
    end)

    -- Key info card (hidden until verified)
    local infoCard = CreateElement("Frame", {
        Size = UDim2.new(1, 0, 0, 142),
        Position = UDim2.new(0, 0, 0, 154),
        BackgroundColor3 = T.surfaceAlt,
        Visible = false,
        Parent = body,
    })
    AddCorner(infoCard, 6)
    AddStroke(infoCard, T.border, 1, 0)

    local infoHeader = CreateElement("TextLabel", {
        Size = UDim2.new(1, -16, 0, 18),
        Position = UDim2.new(0, 8, 0, 8),
        BackgroundTransparency = 1,
        Text = "Key details",
        TextColor3 = T.textMuted,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = false,
        Parent = infoCard,
    })

    local function makeInfoLine(idx, label, value)
        local row = CreateElement("Frame", {
            Size = UDim2.new(1, -16, 0, 16),
            Position = UDim2.new(0, 8, 0, 8 + idx * 18),
            BackgroundTransparency = 1,
            Parent = infoCard,
        })
        CreateElement("TextLabel", {
            Size = UDim2.new(0, 90, 1, 0),
            BackgroundTransparency = 1,
            Text = label,
            TextColor3 = T.textDim,
            TextSize = 11,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = row,
        })
        CreateElement("TextLabel", {
            Size = UDim2.new(1, -90, 1, 0),
            Position = UDim2.new(0, 90, 0, 0),
            BackgroundTransparency = 1,
            Text = value,
            TextColor3 = T.text,
            TextSize = 11,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = row,
        })
    end

    -- Footer / version
    local footer = CreateElement("TextLabel", {
        Size = UDim2.new(1, -32, 0, 14),
        Position = UDim2.new(0, 16, 1, -18),
        BackgroundTransparency = 1,
        Text = "v" .. CONFIG.CURRENT_VERSION .. "  ·  " .. (executorInfo and executorInfo.name or "Unknown"),
        TextColor3 = T.textDim,
        TextSize = 10,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = window,
    })

    -- ---- Verify handler ----
    local function doVerify()
        local rawKey = input.Text
        if not rawKey or rawKey:match("^%s*$") then
            statusLabel.Text = "Enter a key first"
            statusLabel.TextColor3 = T.err
            return
        end
        local key = normalizeKey(rawKey)
        statusLabel.Text = "Verifying…"
        statusLabel.TextColor3 = T.warn
        verifyBtn.Text = "Verifying…"
        verifyBtn.Active = false

        local ok, msg, keyData
        task.spawn(function()
            ok, msg, keyData = verifyKeyRemote(key)
            if ok then
                State.failedAttempts = 0
                State.lockedUntil = 0
                local session = createSession(key, keyData)
                local expires = keyData and keyData.expires
                local remaining = ""
                if expires then
                    local hrs = math.max(0, math.floor((expires - DateTime.now().UnixTimestampMillis) / 3600000))
                    remaining = hrs .. "h"
                end
                infoCard.Visible = true
                -- Resize the window to fit infoCard
                TweenService:Create(window, TweenInfo.new(0.2), {
                    Size = UDim2.new(0, WIN_W, 0, WIN_H + 40),
                }):Play()

                -- Rebuild info lines with actual data
                for _, child in ipairs(infoCard:GetChildren()) do
                    if child:IsA("Frame") or child:IsA("TextLabel") and child ~= infoHeader then
                        child:Destroy()
                    end
                end
                local lines = {
                    { "Tier",      (keyData and keyData.tier) or "free" },
                    { "Type",      (keyData and keyData.type) or "free" },
                    { "Source",    (keyData and keyData.source) or "unknown" },
                    { "Features",  table.concat((keyData and keyData.features) or {"basic"}, ", ") },
                    { "Remaining", remaining ~= "" and remaining or "n/a" },
                }
                for i, l in ipairs(lines) do
                    makeInfoLine(i, l[1], l[2])
                end

                statusLabel.Text = "Verified — " .. (keyData and keyData.tier or "free") .. " tier"
                statusLabel.TextColor3 = T.ok
                verifyBtn.Text = "Verified"
                if callback then callback(true, session) end
            else
                registerFailedAttempt()
                statusLabel.Text = msg or "Invalid key"
                statusLabel.TextColor3 = T.err
                verifyBtn.Text = "Verify"
                verifyBtn.Active = true
                if callback then callback(false, msg) end
            end
        end)
    end

    verifyBtn.MouseButton1Click:Connect(doVerify)
    input.FocusLost:Connect(function(enterPressed)
        if enterPressed then doVerify() end
    end)

    -- Spawn animations
    task.spawn(function()
        window.Size = UDim2.new(0, 0, 0, 0)
        window.BackgroundTransparency = 1
        TweenService:Create(window, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, WIN_W, 0, WIN_H),
            BackgroundTransparency = 0,
        }):Play()
    end)
end

-- ============================================
-- PUBLIC API
-- ============================================
function CheckKeySystem.show(callback)
    createKeyUI(callback, detectExecutor())
end

function CheckKeySystem.hasFeature(featureName)
    local valid, session = CheckKeySystem.verifySession()
    if not valid then return false end
    for _, f in ipairs(session.keyFeatures or {}) do
        if f == featureName then return true end
    end
    return false
end

function CheckKeySystem.getKeyType()
    local valid, session = CheckKeySystem.verifySession()
    if not valid then return nil end
    return session.keyType
end

function CheckKeySystem.getSession()
    local valid, session = CheckKeySystem.verifySession()
    if not valid then return nil end
    return session
end

function CheckKeySystem.isAuthenticated()
    return CheckKeySystem.verifySession()
end

function CheckKeySystem.getHWID()
    return getHWID()
end

function CheckKeySystem.getConfig()
    return CONFIG
end

return CheckKeySystem

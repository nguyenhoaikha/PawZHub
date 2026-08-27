-- PawZHub Key System v4.1
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

-- Game scripts: after a successful key verification, the modal
-- closes and the right script loads automatically. Add a new entry
-- for each game you support. scriptUrl is the raw GitHub URL of the
-- .lua file in the PawZHub repo's /games directory.
local GITHUB_RAW = "https://raw.githubusercontent.com/nguyenhoaikha/PawZHub/main"
local SUPPORTED_GAMES = {
    -- ===== Free (no key required) =====
    [2753915549]      = { name = "Blox Fruits",           scriptPath = "games/PawZHubBF.lua" },
    [74102906764176]  = { name = "Greedy Growers",        scriptPath = "games/PawZHubGG.lua" },
    [4616652839]      = { name = "Shindo Life",           scriptPath = "games/shindo-life.lua" },
    [17017911970]     = { name = "Anime Expeditions",     scriptPath = "games/anime-expeditions.lua" },
    [117612316652]    = { name = "Highschool Hoops",      scriptPath = "games/highschool-hoops.lua" },
    [81128789072]     = { name = "Practical Basketball",  scriptPath = "games/practical-basketball.lua" },
    [17625359962]     = { name = "Grow A Chicken Fighter",scriptPath = "games/grow-a-chicken.lua" },
    [14367520663]     = { name = "Throw A Coin",          scriptPath = "games/throw-a-coin.lua" },
    [72920620366355]  = { name = "Operation One",         scriptPath = "games/operation-one.lua" },
    -- ===== Premium games (key required) =====
    [1458767429]      = { name = "ABA",                    scriptPath = "games/aba.lua" },
    [6735572261]      = { name = "Pilgrammed",             scriptPath = "games/pilgrammed.lua" },
    [6270290407]      = { name = "VV: Ultimatum",          scriptPath = "games/vv-ultimatum.lua" },
    [131079272918660] = { name = "Devil Hunter",           scriptPath = "games/devil-hunter.lua" },
    [14704917953]     = { name = "Dokkodo",                scriptPath = "games/dokkodo.lua" },
    [5571328985]      = { name = "Bloodlines",             scriptPath = "games/bloodlines.lua" },
    [99449877692519]  = { name = "Bridger Western",        scriptPath = "games/bridger.lua" },
    [128736949265057] = { name = "Gakuran",                scriptPath = "games/gakuran.lua" },
    [10449761463]     = { name = "The Strongest Battlegrounds", scriptPath = "games/tsb.lua" },
    [13927562399]     = { name = "Havoc",                  scriptPath = "games/havoc.lua" },
    [13876564679]     = { name = "Highschool Hoops (Pro)", scriptPath = "games/highschool-hoops.lua" },
    [16361990076]     = { name = "Grand Alfheim",          scriptPath = "games/grand-alfheim.lua" },
    [13358463560]     = { name = "Asura",                  scriptPath = "games/asura.lua" },
    [4588604953]      = { name = "Criminality",            scriptPath = "games/criminality.lua" },
    [91792475213200]  = { name = "Above The Rim",          scriptPath = "games/above-the-rim.lua" },
    [115681808123944] = { name = "Throw A Coin (Pro)",     scriptPath = "games/throw-a-coin.lua" },
    [17070462969]     = { name = "Voxel Destruct",         scriptPath = "games/voxel-destruct.lua" },
    [80681221431821]  = { name = "Practical Basketball (Pro)", scriptPath = "games/practical-basketball.lua" },
    [86544322519715]  = { name = "Horse Racing Legends",   scriptPath = "games/horse-racing.lua" },
    [100096058035179] = { name = "MS:KEN",                 scriptPath = "games/ms-ken.lua" },
    [94640181989498]  = { name = "Grow A Chicken Fighter (Pro)", scriptPath = "games/grow-a-chicken.lua" },
    [18852831741]     = { name = "Ryujin",                 scriptPath = "games/ryujin.lua" },
    [77649408247578]  = { name = "Dungeon Quest Reborn",   scriptPath = "games/dungeon-quest.lua" },
    [97598239454123]  = { name = "Grow a Garden 2",        scriptPath = "games/grow-garden-2.lua" },
}

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
    CURRENT_VERSION     = "1.0.1",
}

-- ============================================
-- THEME — black/white/gray only, no icons/gradients
-- ============================================
local T = {
    bg          = Color3.fromRGB(0, 0, 0),
    surface     = Color3.fromRGB(12, 12, 12),
    surfaceAlt  = Color3.fromRGB(18, 18, 18),
    surfaceHi   = Color3.fromRGB(24, 24, 24),
    border      = Color3.fromRGB(36, 36, 36),
    borderHi    = Color3.fromRGB(56, 56, 56),
    borderFocus = Color3.fromRGB(90, 90, 90),
    text        = Color3.fromRGB(255, 255, 255),
    textMuted   = Color3.fromRGB(150, 150, 150),
    textDim     = Color3.fromRGB(95, 95, 95),
    ok          = Color3.fromRGB(74, 222, 128),
    err         = Color3.fromRGB(248, 113, 113),
    warn        = Color3.fromRGB(250, 204, 21),
    btn         = Color3.fromRGB(255, 255, 255),
    btnText     = Color3.fromRGB(0, 0, 0),
    btnHover    = Color3.fromRGB(230, 230, 230),
    btnPress    = Color3.fromRGB(200, 200, 200),
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
    -- PH.{base64url}.{hmac} — premium key (lifetime / monthly / trial)
    if key:sub(1, 3) == "PH." and key:match("^PH%.[A-Za-z0-9_%-]+%.[A-Za-z0-9_%-]+$") then
        return "premium"
    end
    -- eyJ... — JWT free key
    if key:match("^ey[A-Za-z0-9_%-]+%.[A-Za-z0-9_%-]+%.[A-Za-z0-9_%-]+$") then
        return "web"
    end
    return nil
end

local function normalizeKey(key)
    if not key or type(key) ~= "string" then return "" end
    key = key:match("^%s*(.-)%s*$") or key
    -- JWT and PH.* keys are case-sensitive (base64url encoding)
    local kt = detectKeyType(key)
    if kt == "web" or kt == "premium" then
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

    -- All HTTP methods failed. The script always needs network to
    -- reach getpawzhub.vercel.app, so an empty response here means
    -- the executor's HTTP layer is broken (or the user is offline).
    return false, "Server unreachable — check executor HTTP permissions"
end

function CheckKeySystem.requestHWIDReset(key)
    key = normalizeKey(key)
    local HttpService = game:GetService("HttpService")
    local currentHwid = getHWID()
    local body = HttpService:JSONEncode({
        key         = key,
        currentHwid = currentHwid,
        newHwid     = "pending",
        userId      = tostring(game:GetService("Players").LocalPlayer.UserId),
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

-- ============================================
-- AUTO-LOAD GAME SCRIPT AFTER VERIFY
-- ============================================
local function loadGameScript(placeId)
    local entry = SUPPORTED_GAMES[placeId]
    if not entry then
        warn(("[PawZHub] PlaceId %d is not in SUPPORTED_GAMES. Game script not loaded."):format(placeId))
        return false, "Game not supported"
    end

    local url = GITHUB_RAW .. "/" .. entry.scriptPath
    print(("[PawZHub] Loading %s from %s"):format(entry.name, url))

    local ok, body = pcall(function()
        return game:HttpGet(url)
    end)
    if not ok or type(body) ~= "string" or body == "" then
        warn("[PawZHub] Failed to fetch " .. url .. ": " .. tostring(body))
        return false, "Failed to download game script"
    end

    local fn, err = loadstring(body)
    if not fn then
        warn("[PawZHub] Syntax error in " .. entry.scriptPath .. ": " .. tostring(err))
        return false, "Game script has a syntax error"
    end

    local ok2, runErr = pcall(fn)
    if not ok2 then
        warn("[PawZHub] Runtime error in " .. entry.scriptPath .. ": " .. tostring(runErr))
        return false, "Game script crashed on load"
    end
    return true, nil
end

CheckKeySystem.loadGameScript = loadGameScript
CheckKeySystem.getSupportedGames = function() return SUPPORTED_GAMES end

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

local function AddPadding(parent, t, r, b, l)
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, t or 0)
    p.PaddingRight = UDim.new(0, r or 0)
    p.PaddingBottom = UDim.new(0, b or 0)
    p.PaddingLeft = UDim.new(0, l or 0)
    p.Parent = parent
    return p
end

-- ============================================
-- UI — refined black/white/gray modal
-- ============================================

local function createKeyUI(callback, executorInfo)
    local Players = game:GetService("Players")
    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")
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

    -- Adaptive sizing
    local WIN_W = isMobile and 300 or 360
    local WIN_H = isMobile and 360 or 380
    local PAD = 16
    local GAP = 10

    local screenGui = CreateElement("ScreenGui", {
        Name = "PawZHubKeySystem",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        DisplayOrder = 100,
        Parent = playerGui,
    })

    -- Full-screen dim
    local dim = CreateElement("Frame", {
        Name = "Dim",
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = screenGui,
    })

    -- Main window
    local window = CreateElement("Frame", {
        Name = "Main",
        Size = UDim2.new(0, WIN_W, 0, WIN_H),
        Position = UDim2.new(0.5, -WIN_W / 2, 0.5, -WIN_H / 2),
        BackgroundColor3 = T.surface,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Active = true,
        BackgroundTransparency = 1,
        Parent = screenGui,
    })
    AddCorner(window, 12)
    local windowStroke = AddStroke(window, T.border, 1, 0)

    -- ========== TOAST ==========
    local toast = CreateElement("Frame", {
        Size = UDim2.new(1, -(PAD * 2), 0, 30),
        Position = UDim2.new(0, PAD, 1, -52),
        BackgroundColor3 = T.surfaceHi,
        BorderSizePixel = 0,
        Visible = false,
        ClipsDescendants = true,
        ZIndex = 10,
        Parent = window,
    })
    AddCorner(toast, 6)
    AddStroke(toast, T.border, 1, 0)

    local toastAccent = CreateElement("Frame", {
        Size = UDim2.new(0, 3, 1, -8),
        Position = UDim2.new(0, 4, 0, 4),
        BackgroundColor3 = T.textMuted,
        BorderSizePixel = 0,
        ZIndex = 11,
        Parent = toast,
    })
    AddCorner(toastAccent, 2)

    local toastText = CreateElement("TextLabel", {
        Size = UDim2.new(1, -22, 1, 0),
        Position = UDim2.new(0, 14, 0, 0),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = T.text,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextWrapped = true,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ClipsDescendants = true,
        ZIndex = 11,
        Parent = toast,
    })

    local activeToastThread = nil
    local function showToast(msg, kind, duration)
        duration = duration or 3
        local accent = T.textMuted
        local text = T.text
        if kind == "ok" then
            accent = T.ok; text = T.ok
        elseif kind == "err" then
            accent = T.err; text = T.err
        elseif kind == "warn" then
            accent = T.warn; text = T.warn
        end
        toastAccent.BackgroundColor3 = accent
        toastText.Text = tostring(msg or "")
        toastText.TextColor3 = text
        toast.Visible = true
        if activeToastThread then
            task.cancel(activeToastThread)
            activeToastThread = nil
        end
        activeToastThread = task.delay(duration, function()
            toast.Visible = false
            activeToastThread = nil
        end)
    end

    -- ========== HEADER (drag handle) ==========
    local header = CreateElement("Frame", {
        Size = UDim2.new(1, 0, 0, 48),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = T.surfaceAlt,
        BorderSizePixel = 0,
        Parent = window,
    })

    -- Accent line under header
    CreateElement("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = T.border,
        BorderSizePixel = 0,
        Parent = header,
    })

    CreateElement("TextLabel", {
        Size = UDim2.new(1, -80, 1, 0),
        Position = UDim2.new(0, PAD, 0, 0),
        BackgroundTransparency = 1,
        Text = "PawZHub",
        TextColor3 = T.text,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = header,
    })

    -- Close button
    local closeBtn = CreateElement("TextButton", {
        Size = UDim2.new(0, 28, 0, 28),
        Position = UDim2.new(1, -40, 0.5, -14),
        BackgroundColor3 = T.surface,
        BackgroundTransparency = 0.4,
        Text = "×",
        TextColor3 = T.textMuted,
        TextSize = 18,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        Parent = header,
    })
    AddCorner(closeBtn, 6)

    closeBtn.MouseEnter:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.12), {
            TextColor3 = T.text,
            BackgroundTransparency = 0,
            BackgroundColor3 = T.surfaceHi,
        }):Play()
    end)
    closeBtn.MouseLeave:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.12), {
            TextColor3 = T.textMuted,
            BackgroundTransparency = 0.4,
            BackgroundColor3 = T.surface,
        }):Play()
    end)

    local function closeModal()
        TweenService:Create(window, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, WIN_W * 0.96, 0, WIN_H * 0.96),
            BackgroundTransparency = 1,
        }):Play()
        TweenService:Create(dim, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
        task.wait(0.22)
        screenGui:Destroy()
    end

    closeBtn.MouseButton1Click:Connect(closeModal)

    -- Drag
    local dragging = false
    local dragOffset = Vector2.zero
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            local absPos = window.AbsolutePosition
            dragOffset = Vector2.new(
                input.Position.X - absPos.X,
                input.Position.Y - absPos.Y
            )
        end
    end)
    header.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            window.Position = UDim2.new(
                0, input.Position.X - dragOffset.X,
                0, input.Position.Y - dragOffset.Y
            )
        end
    end)

    -- ========== BODY ==========
    local body = CreateElement("Frame", {
        Size = UDim2.new(1, -(PAD * 2), 1, -48 - 36),
        Position = UDim2.new(0, PAD, 0, 56),
        BackgroundTransparency = 1,
        Parent = window,
    })

    -- Status / prompt
    local statusLabel = CreateElement("TextLabel", {
        Size = UDim2.new(1, 0, 0, 18),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = "Enter your key to continue",
        TextColor3 = T.textMuted,
        TextSize = 12,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = body,
    })

    -- Restore-session link (only shown if we have a cached key)
    local cachedKey = next(State.keyCache)
    if cachedKey then
        local restoreBtn = CreateElement("TextButton", {
            Size = UDim2.new(1, 0, 0, 14),
            Position = UDim2.new(0, 0, 0, 18),
            BackgroundTransparency = 1,
            Text = "↻  Use last key (" .. string.sub(cachedKey, 1, 14) .. "…)",
            TextColor3 = T.textMuted,
            TextSize = 10,
            Font = Enum.Font.GothamMedium,
            TextXAlignment = Enum.TextXAlignment.Center,
            AutoButtonColor = false,
            Parent = body,
        })
        restoreBtn.MouseEnter:Connect(function()
            restoreBtn.TextColor3 = T.text
        end)
        restoreBtn.MouseLeave:Connect(function()
            restoreBtn.TextColor3 = T.textMuted
        end)
        restoreBtn.MouseButton1Click:Connect(function()
            input.Text = cachedKey
            showToast("Previous key restored", "ok", 1.2)
        end)
    end

    -- Input row (textbox + clear)
    local inputRow = CreateElement("Frame", {
        Size = UDim2.new(1, 0, 0, 36),
        Position = UDim2.new(0, 0, 0, 26),
        BackgroundTransparency = 1,
        Parent = body,
    })

    local input = CreateElement("TextBox", {
        Size = UDim2.new(1, 0, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = T.surfaceAlt,
        Text = "",
        PlaceholderText = "Paste key (eyJ… or PH.…)",
        PlaceholderColor3 = T.textDim,
        TextColor3 = T.text,
        TextSize = 12,
        Font = Enum.Font.Code,
        ClearTextOnFocus = false,
        ClipsDescendants = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTranslucent = true,  -- show/hide toggle will flip this
        Parent = inputRow,
    })
    AddCorner(input, 8)
    local inputStroke = AddStroke(input, T.border, 1, 0)
    AddPadding(input, 0, 12, 0, 12)

    -- Focus / blur stroke
    input.Focused:Connect(function()
        TweenService:Create(inputStroke, TweenInfo.new(0.15), { Color = T.borderFocus }):Play()
        TweenService:Create(input, TweenInfo.new(0.15), { BackgroundColor3 = T.surfaceHi }):Play()
    end)
    input.FocusLost:Connect(function()
        TweenService:Create(inputStroke, TweenInfo.new(0.15), { Color = T.border }):Play()
        TweenService:Create(input, TweenInfo.new(0.15), { BackgroundColor3 = T.surfaceAlt }):Play()
    end)

    -- Key type badge (shows when typing)
    local keyTypeBadge = CreateElement("TextLabel", {
        Size = UDim2.new(0, 58, 0, 18),
        Position = UDim2.new(1, -66, 0.5, -9),
        BackgroundColor3 = T.surface,
        Text = "",
        TextColor3 = T.textDim,
        TextSize = 9,
        Font = Enum.Font.GothamBold,
        Visible = false,
        ZIndex = 5,
        Parent = input,
    })
    AddCorner(keyTypeBadge, 4)
    AddStroke(keyTypeBadge, T.border, 1, 0)

    -- Character counter (shown when typing)
    local charCountLabel = CreateElement("TextLabel", {
        Size = UDim2.new(0, 60, 0, 14),
        Position = UDim2.new(0, 12, 1, -16),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = T.textDim,
        TextSize = 9,
        Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left,
        Visible = false,
        ZIndex = 4,
        Parent = input,
    })

    -- Show / hide key toggle (eye icon)
    local showKey = false
    local showHideBtn = CreateElement("TextButton", {
        Size = UDim2.new(0, 22, 0, 22),
        Position = UDim2.new(1, -124, 0.5, -11),
        BackgroundTransparency = 1,
        Text = "Show",
        TextColor3 = T.textMuted,
        TextSize = 9,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        ZIndex = 5,
        Parent = input,
    })
    showHideBtn.MouseButton1Click:Connect(function()
        showKey = not showKey
        input.TextTranslucent = not showKey
        showHideBtn.Text = showKey and "Hide" or "Show"
        showHideBtn.TextColor3 = showKey and T.text or T.textMuted
    end)

    -- Paste button (uses getclipboard if available)
    local pasteBtn = CreateElement("TextButton", {
        Size = UDim2.new(0, 36, 0, 22),
        Position = UDim2.new(1, -160, 0.5, -11),
        BackgroundTransparency = 1,
        Text = "Paste",
        TextColor3 = T.textMuted,
        TextSize = 9,
        Font = Enum.Font.GothamBold,
        AutoButtonColor = false,
        ZIndex = 5,
        Parent = input,
    })
    pasteBtn.MouseButton1Click:Connect(function()
        if type(getclipboard) == "function" then
            local ok, clip = pcall(getclipboard)
            if ok and type(clip) == "string" and clip ~= "" then
                input.Text = clip
                showToast("Pasted from clipboard", "ok", 1.2)
            else
                showToast("Clipboard empty or blocked", "warn", 2)
            end
        elseif type(setclipboard) == "function" then
            showToast("Press Ctrl+V to paste", "warn", 2)
        end
    end)

    input:GetPropertyChangedSignal("Text"):Connect(function()
        local kt = detectKeyType(input.Text)
        if kt == "premium" then
            keyTypeBadge.Text = "PREMIUM"
            keyTypeBadge.TextColor3 = T.ok
            keyTypeBadge.Visible = true
        elseif kt == "web" then
            keyTypeBadge.Text = "FREE"
            keyTypeBadge.TextColor3 = T.textMuted
            keyTypeBadge.Visible = true
        else
            keyTypeBadge.Visible = false
        end
        -- Update character counter
        local len = #input.Text
        if len > 0 then
            charCountLabel.Text = tostring(len) .. " chars"
            charCountLabel.Visible = true
        else
            charCountLabel.Visible = false
        end
    end)

    -- Verify button
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
    AddCorner(verifyBtn, 8)

    -- Progress bar (shows during verify)
    local progressBar = CreateElement("Frame", {
        Size = UDim2.new(0, 0, 0, 2),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = T.ok,
        BorderSizePixel = 0,
        Visible = false,
        Parent = verifyBtn,
    })

    local verifying = false
    verifyBtn.MouseEnter:Connect(function()
        if verifying then return end
        TweenService:Create(verifyBtn, TweenInfo.new(0.1), { BackgroundColor3 = T.btnHover }):Play()
    end)
    verifyBtn.MouseLeave:Connect(function()
        if verifying then return end
        TweenService:Create(verifyBtn, TweenInfo.new(0.1), { BackgroundColor3 = T.btn }):Play()
    end)
    verifyBtn.MouseButton1Down:Connect(function()
        if verifying then return end
        TweenService:Create(verifyBtn, TweenInfo.new(0.06), { BackgroundColor3 = T.btnPress }):Play()
    end)
    verifyBtn.MouseButton1Up:Connect(function()
        if verifying then return end
        TweenService:Create(verifyBtn, TweenInfo.new(0.06), { BackgroundColor3 = T.btnHover }):Play()
    end)

    -- Secondary actions row
    local linkRow = CreateElement("Frame", {
        Size = UDim2.new(1, 0, 0, 32),
        Position = UDim2.new(0, 0, 0, 114),
        BackgroundTransparency = 1,
        Parent = body,
    })

    local getKeyBtn = CreateElement("TextButton", {
        Size = UDim2.new(0.5, -4, 1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = T.surfaceAlt,
        Text = "Get Key",
        TextColor3 = T.text,
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        AutoButtonColor = false,
        Parent = linkRow,
    })
    AddCorner(getKeyBtn, 8)
    local getKeyStroke = AddStroke(getKeyBtn, T.border, 1, 0)

    getKeyBtn.MouseEnter:Connect(function()
        TweenService:Create(getKeyBtn, TweenInfo.new(0.1), { BackgroundColor3 = T.surfaceHi }):Play()
        TweenService:Create(getKeyStroke, TweenInfo.new(0.1), { Color = T.borderHi }):Play()
    end)
    getKeyBtn.MouseLeave:Connect(function()
        TweenService:Create(getKeyBtn, TweenInfo.new(0.1), { BackgroundColor3 = T.surfaceAlt }):Play()
        TweenService:Create(getKeyStroke, TweenInfo.new(0.1), { Color = T.border }):Play()
    end)
    getKeyBtn.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(GET_KEY_URL)
            showToast("Get Key URL copied", "ok", 2)
        else
            showToast("Visit: " .. GET_KEY_URL, "warn", 4)
        end
    end)

    local discordBtn = CreateElement("TextButton", {
        Size = UDim2.new(0.5, -4, 1, 0),
        Position = UDim2.new(0.5, 4, 0, 0),
        BackgroundColor3 = T.surfaceAlt,
        Text = "Discord",
        TextColor3 = T.text,
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        AutoButtonColor = false,
        Parent = linkRow,
    })
    AddCorner(discordBtn, 8)
    local discordStroke = AddStroke(discordBtn, T.border, 1, 0)

    discordBtn.MouseEnter:Connect(function()
        TweenService:Create(discordBtn, TweenInfo.new(0.1), { BackgroundColor3 = T.surfaceHi }):Play()
        TweenService:Create(discordStroke, TweenInfo.new(0.1), { Color = T.borderHi }):Play()
    end)
    discordBtn.MouseLeave:Connect(function()
        TweenService:Create(discordBtn, TweenInfo.new(0.1), { BackgroundColor3 = T.surfaceAlt }):Play()
        TweenService:Create(discordStroke, TweenInfo.new(0.1), { Color = T.border }):Play()
    end)
    discordBtn.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(CONFIG.DISCORD_URL)
            showToast("Discord invite copied", "ok", 2)
        else
            showToast("Open Discord manually", "err", 3)
        end
    end)

    -- Divider
    local divider = CreateElement("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 0, 156),
        BackgroundColor3 = T.border,
        BorderSizePixel = 0,
        Parent = body,
    })

    -- Info strip (game + executor)
    local infoStrip = CreateElement("Frame", {
        Size = UDim2.new(1, 0, 0, 48),
        Position = UDim2.new(0, 0, 0, 168),
        BackgroundColor3 = T.surfaceAlt,
        BorderSizePixel = 0,
        Parent = body,
    })
    AddCorner(infoStrip, 8)
    AddStroke(infoStrip, T.border, 1, 0)

    local gameName = SUPPORTED_GAMES[game.PlaceId] and SUPPORTED_GAMES[game.PlaceId].name or "Unknown Game"
    local execName = (executorInfo and executorInfo.name) or "Unknown"

    CreateElement("TextLabel", {
        Size = UDim2.new(1, -16, 0, 16),
        Position = UDim2.new(0, 10, 0, 8),
        BackgroundTransparency = 1,
        Text = "Game",
        TextColor3 = T.textDim,
        TextSize = 10,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = infoStrip,
    })
    CreateElement("TextLabel", {
        Size = UDim2.new(1, -16, 0, 16),
        Position = UDim2.new(0, 10, 0, 24),
        BackgroundTransparency = 1,
        Text = gameName,
        TextColor3 = T.text,
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = infoStrip,
    })

    -- Executor on the right side of the strip
    CreateElement("TextLabel", {
        Size = UDim2.new(0.45, 0, 0, 16),
        Position = UDim2.new(0.55, 0, 0, 8),
        BackgroundTransparency = 1,
        Text = "Executor",
        TextColor3 = T.textDim,
        TextSize = 10,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = infoStrip,
    })
    CreateElement("TextLabel", {
        Size = UDim2.new(0.45, 0, 0, 16),
        Position = UDim2.new(0.55, 0, 0, 24),
        BackgroundTransparency = 1,
        Text = execName,
        TextColor3 = T.text,
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = infoStrip,
    })

    -- ========== FOOTER ==========
    local footer = CreateElement("TextLabel", {
        Size = UDim2.new(1, -(PAD * 2), 0, 14),
        Position = UDim2.new(0, PAD, 1, -24),
        BackgroundTransparency = 1,
        Text = "PawZHub v" .. CONFIG.CURRENT_VERSION .. "  ·  © 2026",
        TextColor3 = T.textDim,
        TextSize = 10,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = window,
    })
    -- Right-aligned support link
    CreateElement("TextButton", {
        Size = UDim2.new(0, 80, 0, 14),
        Position = UDim2.new(1, -PAD - 80, 1, -24),
        BackgroundTransparency = 1,
        Text = "Need help?",
        TextColor3 = T.textMuted,
        TextSize = 10,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Right,
        AutoButtonColor = false,
        Parent = window,
    }).MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(CONFIG.DISCORD_URL)
            showToast("Discord invite copied", "ok", 2)
        else
            showToast("Open Discord: discord.gg/pawzhub", "warn", 3)
        end
    end)

    -- ========== SUCCESS STATE ==========
    local subLabel = nil

    local function showSuccess(tier)
        inputRow.Visible = false
        verifyBtn.Visible = false
        linkRow.Visible = false
        divider.Visible = false
        infoStrip.Visible = false
        keyTypeBadge.Visible = false
        pasteBtn.Visible = false
        showHideBtn.Visible = false

        -- Animated checkmark (draws a check stroke)
        local checkSize = 48
        local checkContainer = CreateElement("Frame", {
            Size = UDim2.new(0, checkSize, 0, checkSize),
            Position = UDim2.new(0.5, -checkSize / 2, 0, 70),
            BackgroundTransparency = 1,
            Parent = body,
        })
        -- Circle background that scales in
        local checkBg = CreateElement("Frame", {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = T.surfaceAlt,
            BorderSizePixel = 0,
            Parent = checkContainer,
        })
        AddCorner(checkBg, 999)
        AddStroke(checkBg, T.ok, 2, 0)
        TweenService:Create(checkBg, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, checkSize, 0, checkSize),
        }):Play()

        -- Checkmark text (scales in after the circle)
        task.delay(0.18, function()
            if not State or not checkContainer then return end
            CreateElement("TextLabel", {
                Size = UDim2.new(0, checkSize, 0, checkSize),
                Position = UDim2.new(0.5, 0, 0.5, 0),
                AnchorPoint = Vector2.new(0.5, 0.5),
                BackgroundTransparency = 1,
                Text = "OK",
                TextColor3 = T.ok,
                TextSize = 18,
                Font = Enum.Font.GothamBold,
                TextXAlignment = Enum.TextXAlignment.Center,
                TextYAlignment = Enum.TextYAlignment.Center,
                Parent = checkContainer,
            })
        end)

        statusLabel.Text = "Verified"
        statusLabel.TextSize = 18
        statusLabel.TextColor3 = T.ok
        statusLabel.Font = Enum.Font.GothamBold
        statusLabel.Position = UDim2.new(0, 0, 0, 130)
        statusLabel.TextXAlignment = Enum.TextXAlignment.Center

        local tierText = (tier and tier ~= "free") and (" · " .. tostring(tier):upper()) or ""
        subLabel = CreateElement("TextLabel", {
            Size = UDim2.new(1, 0, 0, 18),
            Position = UDim2.new(0, 0, 0, 156),
            BackgroundTransparency = 1,
            Text = "Loading " .. gameName .. "…" .. tierText,
            TextColor3 = T.textMuted,
            TextSize = 12,
            Font = Enum.Font.Gotham,
            TextXAlignment = Enum.TextXAlignment.Center,
            Parent = body,
        })
    end

    local function closeAndLoad()
        local ok, err = loadGameScript(game.PlaceId)
        if not ok then
            local msg
            if err == "Game not supported" then
                msg = gameName .. " is not supported yet"
                if subLabel then
                    subLabel.Text = msg
                    subLabel.TextColor3 = T.err
                end
            else
                msg = "Load failed: " .. tostring(err)
                if subLabel then
                    subLabel.Text = tostring(err)
                    subLabel.TextColor3 = T.err
                end
            end
            showToast(msg, "err", 5)
            task.wait(2.8)
        end

        TweenService:Create(window, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, WIN_W * 0.96, 0, WIN_H * 0.96),
            BackgroundTransparency = 1,
        }):Play()
        TweenService:Create(dim, TweenInfo.new(0.22), { BackgroundTransparency = 1 }):Play()
        task.wait(0.25)
        screenGui:Destroy()
    end

    -- ========== VERIFY HANDLER ==========
    local loadingAnimThread = nil
    local function startLoadingAnimation()
        if loadingAnimThread then return end
        local frame = 0
        local baseText = "Verifying"
        local dots = {"   ", ".  ", ".. ", "..."}
        loadingAnimThread = task.spawn(function()
            while verifying do
                statusLabel.Text = baseText .. dots[((frame % 4) + 1)]
                frame = frame + 1
                task.wait(0.25)
            end
            loadingAnimThread = nil
        end)
    end
    local function stopLoadingAnimation()
        if loadingAnimThread then
            task.cancel(loadingAnimThread)
            loadingAnimThread = nil
        end
    end

    local function doVerify()
        if verifying then return end
        local rawKey = input.Text
        if not rawKey or rawKey:match("^%s*$") then
            statusLabel.Text = "Enter a key first"
            statusLabel.TextColor3 = T.err
            TweenService:Create(inputStroke, TweenInfo.new(0.1), { Color = T.err }):Play()
            task.delay(1.2, function()
                if not verifying then
                    TweenService:Create(inputStroke, TweenInfo.new(0.15), { Color = T.border }):Play()
                    statusLabel.Text = "Enter your key to continue"
                    statusLabel.TextColor3 = T.textMuted
                end
            end)
            return
        end

        local key = normalizeKey(rawKey)
        verifying = true
        verifyBtn.Text = "Verifying…"
        verifyBtn.Active = false
        input.Active = false
        pasteBtn.Active = false
        showHideBtn.Active = false
        TweenService:Create(verifyBtn, TweenInfo.new(0.1), {
            BackgroundColor3 = T.surfaceHi,
            TextColor3 = T.textMuted,
        }):Play()
        -- Animate the progress bar
        progressBar.Size = UDim2.new(0, 0, 0, 2)
        progressBar.BackgroundTransparency = 0
        progressBar.Visible = true
        TweenService:Create(progressBar, TweenInfo.new(2.5, Enum.EasingStyle.Linear), {
            Size = UDim2.new(0.7, 0, 0, 2),
        }):Play()
        startLoadingAnimation()

        task.spawn(function()
            local ok, msg, keyData = verifyKeyRemote(key)
            stopLoadingAnimation()
            progressBar.Visible = false
            if ok then
                State.failedAttempts = 0
                State.lockedUntil = 0
                local session = createSession(key, keyData)
                if callback then callback(true, session) end

                -- Fill the progress bar fully on success
                progressBar.BackgroundColor3 = T.ok
                progressBar.Visible = true
                progressBar.Size = UDim2.new(0, 0, 0, 2)
                TweenService:Create(progressBar, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Size = UDim2.new(1, 0, 0, 2),
                }):Play()

                showSuccess(keyData and keyData.tier or "free")
                task.wait(1.1)
                closeAndLoad()
            else
                verifying = false
                registerFailedAttempt()
                statusLabel.Text = msg or "Invalid key"
                statusLabel.TextColor3 = T.err
                verifyBtn.Text = "Verify"
                verifyBtn.Active = true
                input.Active = true
                pasteBtn.Active = true
                showHideBtn.Active = true
                progressBar.BackgroundColor3 = T.err
                TweenService:Create(verifyBtn, TweenInfo.new(0.1), {
                    BackgroundColor3 = T.btn,
                    TextColor3 = T.btnText,
                }):Play()
                TweenService:Create(inputStroke, TweenInfo.new(0.1), { Color = T.err }):Play()
                -- Shake animation on the input
                task.spawn(function()
                    for i = 1, 3 do
                        local offset = (i % 2 == 0) and 4 or -4
                        input.Position = UDim2.new(0, offset, 0, 26)
                        task.wait(0.04)
                    end
                    input.Position = UDim2.new(0, 0, 0, 26)
                end)
                task.delay(1.5, function()
                    if not verifying then
                        TweenService:Create(inputStroke, TweenInfo.new(0.2), { Color = T.border }):Play()
                    end
                end)
                if callback then callback(false, msg) end
            end
        end)
    end

    verifyBtn.MouseButton1Click:Connect(doVerify)
    input.FocusLost:Connect(function(enterPressed)
        if enterPressed then doVerify() end
    end)

    -- ========== OPEN ANIMATION ==========
    task.spawn(function()
        window.Size = UDim2.new(0, WIN_W * 0.9, 0, WIN_H * 0.9)
        window.BackgroundTransparency = 1
        dim.BackgroundTransparency = 1

        TweenService:Create(dim, TweenInfo.new(0.25), { BackgroundTransparency = 0.55 }):Play()
        TweenService:Create(window, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, WIN_W, 0, WIN_H),
            BackgroundTransparency = 0,
        }):Play()

        task.wait(0.35)

        -- Auto-detect: clipboard might already have the user's key
        if not verifying and type(getclipboard) == "function" then
            pcall(function()
                local ok, clip = pcall(getclipboard)
                if ok and type(clip) == "string" and detectKeyType(clip) then
                    input.Text = clip
                    showToast("Key detected from clipboard", "ok", 1.5)
                end
            end)
        end

        -- Auto-focus input after the open animation
        if not verifying then
            pcall(function() input:CaptureFocus() end)
        end
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

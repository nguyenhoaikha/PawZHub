--[[
    ========================================================
    PawZHub  —  API Integration Library  v1.0.0
    ========================================================
    Handles all backend API communication: key verification,
    checkpoint validation, HWID binding, and telemetry.

    Features:
      • Key verification (free JWT + premium HMAC keys)
      • Checkpoint token generation (2-step verification)
      • HWID binding and reset
      • Key renewal (free keys only)
      • Premium key checkout integration
      • Blacklist check
      • Rate limit handling
      • Automatic retry on network errors
      • Secure HWID generation
      • Session telemetry (usage tracking)

    Usage:
        local API = loadstring(game:HttpGet(URL))()
        API.Init()

        -- Verify key
        local valid, result = API.VerifyKey("PH.eyJ0Ij...")
        if valid then
            print("Access granted! Tier:", result.tier)
            print("Features:", table.concat(result.features, ", "))
        else
            print("Access denied:", result.message)
        end

        -- Generate free key (requires 2 checkpoints)
        local token1 = API.GetCheckpointToken("linkvertise", 1)
        local token2 = API.GetCheckpointToken("linkvertise", 2)
        local key = API.GenerateFreeKey("linkvertise", 12, token1, token2)

        -- HWID reset
        local success = API.ResetHWID("PH.eyJ0Ij...", "newHWID")

        API.Unload()
]]

-- ========================================================
-- SERVICES
-- ========================================================
local HttpService      = game:GetService("HttpService")
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")

local Player           = Players.LocalPlayer

-- ========================================================
-- STATE
-- ========================================================
local API = {}
API.__version = "1.0.0"
API.__type    = "PawZHub.API"

local State = {
    initialized   = false,
    unloaded      = false,
    
    -- Backend config
    baseURL       = "https://getpawzhub.vercel.app/api",
    
    -- Current session
    key           = nil,
    hwid          = nil,
    keyData       = nil,      -- cached verification result
    verified      = false,
    tier          = "none",   -- "none" | "free" | "trial" | "monthly" | "lifetime"
    features      = {},       -- ["basic", "advanced", "premium", "exclusive"]
    
    -- Telemetry
    sessionStart  = 0,
    totalRequests = 0,
    failedRequests= 0,
    
    -- Rate limiting (client-side soft limit)
    lastRequest   = {},  -- { [endpoint] = tick() }
    cooldowns     = {
        verifykey   = 2,    -- 2 seconds between verifications
        getkey      = 6,    -- 6 seconds between key generations
        renewkey    = 10,   -- 10 seconds between renewals
        hwidReset   = 720,  -- 12 minutes between HWID resets
        checkpoint  = 1,    -- 1 second between checkpoint tokens
    },
}

-- ========================================================
-- HELPERS
-- ========================================================
local function safe(fn, default)
    local ok, v = pcall(fn)
    return ok and v or default
end

local function notify(msg, kind)
    pcall(function()
        if type(_G.PawZHub_Notify) == "function" then
            _G.PawZHub_Notify(msg, kind or "info")
        end
    end)
end

-- Check client-side rate limit
local function checkRateLimit(endpoint)
    local key = endpoint:lower()
    local cooldown = State.cooldowns[key] or 1
    local last = State.lastRequest[key] or 0
    local now  = tick()
    
    if now - last < cooldown then
        local remaining = math.ceil(cooldown - (now - last))
        return false, remaining
    end
    
    State.lastRequest[key] = now
    return true, 0
end

-- HTTP POST with retry
local function httpPost(url, data, retry)
    retry = retry or 2
    State.totalRequests = State.totalRequests + 1
    
    for attempt = 1, retry do
        local ok, response = pcall(function()
            return HttpService:PostAsync(
                url,
                HttpService:JSONEncode(data),
                Enum.HttpContentType.ApplicationJson,
                false,  -- compress
                {       -- headers
                    ["User-Agent"] = "PawZHub/1.0.0 Roblox/" .. tostring(Player.UserId),
                }
            )
        end)
        
        if ok then
            local decodeOk, result = pcall(function()
                return HttpService:JSONDecode(response)
            end)
            
            if decodeOk then
                return true, result
            else
                return false, { message = "Invalid JSON response", raw = response }
            end
        else
            -- Retry on network errors
            if attempt < retry then
                task.wait(1)
            else
                State.failedRequests = State.failedRequests + 1
                return false, { message = "Network error: " .. tostring(response) }
            end
        end
    end
    
    return false, { message = "Max retries exceeded" }
end

-- HTTP GET with retry
local function httpGet(url, retry)
    retry = retry or 2
    State.totalRequests = State.totalRequests + 1
    
    for attempt = 1, retry do
        local ok, response = pcall(function()
            return HttpService:GetAsync(url, false)
        end)
        
        if ok then
            local decodeOk, result = pcall(function()
                return HttpService:JSONDecode(response)
            end)
            
            if decodeOk then
                return true, result
            else
                return false, { message = "Invalid JSON response" }
            end
        else
            if attempt < retry then
                task.wait(1)
            else
                State.failedRequests = State.failedRequests + 1
                return false, { message = "Network error: " .. tostring(response) }
            end
        end
    end
    
    return false, { message = "Max retries exceeded" }
end

-- ========================================================
-- HWID GENERATION
-- ========================================================
--[[
    Generates a unique HWID (Hardware ID) for the current device.
    Uses multiple factors to create a fingerprint:
    - Roblox UserID
    - Platform (Windows, Mac, etc.)
    - GPU Vendor/Renderer (if accessible)
    - Hashed combination
]]
local function generateHWID()
    if State.hwid then return State.hwid end
    
    local factors = {}
    
    -- Factor 1: User ID
    table.insert(factors, tostring(Player.UserId))
    
    -- Factor 2: Platform
    local platform = "Unknown"
    pcall(function()
        if game:GetService("UserInputService").TouchEnabled and not game:GetService("UserInputService").KeyboardEnabled then
            platform = "Mobile"
        elseif game:GetService("UserInputService").GamepadEnabled then
            platform = "Console"
        else
            platform = "Desktop"
        end
    end)
    table.insert(factors, platform)
    
    -- Factor 3: GPU info (best-effort, may not be accessible)
    local gpuInfo = "Generic"
    pcall(function()
        local stats = game:GetService("Stats")
        if stats and stats:FindFirstChild("Graphics") then
            gpuInfo = tostring(stats.Graphics)
        end
    end)
    table.insert(factors, gpuInfo)
    
    -- Factor 4: Account age (days)
    table.insert(factors, tostring(Player.AccountAge))
    
    -- Combine and hash
    local combined = table.concat(factors, "|")
    
    -- Simple hash (not cryptographic, just for fingerprinting)
    local hash = 0
    for i = 1, #combined do
        hash = ((hash * 31) + string.byte(combined, i)) % 2^32
    end
    
    -- Convert to hex string
    local hwid = string.format("%08X", hash)
    
    State.hwid = hwid
    return hwid
end

-- ========================================================
-- KEY VERIFICATION
-- ========================================================
--[[
    API.VerifyKey(key, [hwid])
    Returns: valid (boolean), result (table)
    
    result fields:
    - valid: true/false
    - message: string
    - tier: "free" | "trial" | "monthly" | "lifetime"
    - features: array of strings
    - hwid: string (if bound)
    - expires: timestamp
    - remainingHours: number
]]
function API.VerifyKey(key, hwid)
    if State.unloaded then return false, { message = "API unloaded" } end
    
    -- Rate limit check
    local allowed, cooldown = checkRateLimit("verifykey")
    if not allowed then
        return false, { message = "Rate limited. Wait " .. cooldown .. "s" }
    end
    
    key  = key or State.key
    hwid = hwid or State.hwid or generateHWID()
    
    if not key or key == "" then
        return false, { message = "No key provided" }
    end
    
    local url = State.baseURL .. "/verifykey"
    local data = {
        key      = key,
        hwid     = hwid,
        userId   = tostring(Player.UserId),
        username = Player.Name,
        gameId   = tostring(game.PlaceId),
    }
    
    local ok, result = httpPost(url, data)
    
    if ok and result.valid then
        -- Cache verified key data
        State.key      = key
        State.hwid     = hwid
        State.keyData  = result
        State.verified = true
        State.tier     = result.tier or "free"
        State.features = result.features or {}
        
        notify("Key verified! Tier: " .. State.tier, "ok")
        return true, result
    else
        State.verified = false
        local msg = result.message or "Verification failed"
        notify(msg, "error")
        return false, result
    end
end

-- ========================================================
-- FREE KEY GENERATION
-- ========================================================
--[[
    API.GenerateFreeKey(source, ttlHours, checkpoint1, checkpoint2)
    Returns: key (string) or nil, error
    
    source: "linkvertise" | "lootlabs" | "workink"
    ttlHours: 12 or 24
    checkpoint1, checkpoint2: tokens from GetCheckpointToken()
]]
function API.GenerateFreeKey(source, ttlHours, checkpoint1, checkpoint2)
    if State.unloaded then return nil, "API unloaded" end
    
    local allowed, cooldown = checkRateLimit("getkey")
    if not allowed then
        return nil, "Rate limited. Wait " .. cooldown .. "s"
    end
    
    source   = source or "linkvertise"
    ttlHours = tonumber(ttlHours) or 12
    local hwid = State.hwid or generateHWID()
    
    if not checkpoint1 or not checkpoint2 then
        return nil, "Missing checkpoint tokens"
    end
    
    local url = State.baseURL .. "/getkey"
    local data = {
        source           = source,
        ttlHours         = ttlHours,
        hwid             = hwid,
        userId           = tostring(Player.UserId),
        checkpoint1Token = checkpoint1,
        checkpoint2Token = checkpoint2,
    }
    
    local ok, result = httpPost(url, data)
    
    if ok and result.success and result.key then
        State.key = result.key
        notify("Free key generated! Valid for " .. ttlHours .. "h", "ok")
        return result.key, nil
    else
        local msg = result.message or "Key generation failed"
        notify(msg, "error")
        return nil, msg
    end
end

-- ========================================================
-- KEY RENEWAL (free keys only)
-- ========================================================
function API.RenewKey(platform, checkpoint1, checkpoint2, additionalHours)
    if State.unloaded then return false, "API unloaded" end
    
    local allowed, cooldown = checkRateLimit("renewkey")
    if not allowed then
        return false, "Rate limited. Wait " .. cooldown .. "s"
    end
    
    local key = State.key
    if not key then
        return false, "No active key to renew"
    end
    
    platform        = platform or "linkvertise"
    additionalHours = tonumber(additionalHours) or 12
    local hwid      = State.hwid or generateHWID()
    
    if not checkpoint1 or not checkpoint2 then
        return false, "Missing checkpoint tokens"
    end
    
    local url = State.baseURL .. "/renewkey"
    local data = {
        existingKey      = key,
        checkpoint1Token = checkpoint1,
        checkpoint2Token = checkpoint2,
        hwid             = hwid,
        platform         = platform,
        additionalHours  = additionalHours,
    }
    
    local ok, result = httpPost(url, data)
    
    if ok and result.success and result.key then
        State.key = result.key
        notify("Key renewed! New expiry: " .. os.date("%H:%M", result.newExpires / 1000), "ok")
        return true, result
    else
        local msg = result.message or "Renewal failed"
        notify(msg, "error")
        return false, msg
    end
end

-- ========================================================
-- CHECKPOINT TOKEN
-- ========================================================
--[[
    API.GetCheckpointToken(platform, step, [ttlMinutes])
    Returns: token (string) or nil, error
    
    platform: "linkvertise" | "lootlabs" | "workink"
    step: 1 or 2
    ttlMinutes: default 15
]]
function API.GetCheckpointToken(platform, step, ttlMinutes)
    if State.unloaded then return nil, "API unloaded" end
    
    local allowed, cooldown = checkRateLimit("checkpoint")
    if not allowed then
        return nil, "Rate limited. Wait " .. cooldown .. "s"
    end
    
    platform   = platform or "linkvertise"
    step       = tonumber(step) or 1
    ttlMinutes = tonumber(ttlMinutes) or 15
    
    local url = State.baseURL .. "/checkpoint"
    local data = {
        platform   = platform,
        step       = step,
        ttlMinutes = ttlMinutes,
    }
    
    local ok, result = httpPost(url, data)
    
    if ok and result.success and result.token then
        return result.token, nil
    else
        local msg = result.message or "Checkpoint token failed"
        return nil, msg
    end
end

-- ========================================================
-- HWID RESET (premium keys only)
-- ========================================================
function API.ResetHWID(key, newHwid)
    if State.unloaded then return false, "API unloaded" end
    
    local allowed, cooldown = checkRateLimit("hwidReset")
    if not allowed then
        return false, "Rate limited. Wait " .. math.floor(cooldown/60) .. "m"
    end
    
    key     = key or State.key
    newHwid = newHwid or generateHWID()
    
    if not key then
        return false, "No key provided"
    end
    
    local currentHwid = State.hwid or generateHWID()
    
    local url = State.baseURL .. "/hwid-reset"
    local data = {
        key         = key,
        currentHwid = currentHwid,
        newHwid     = newHwid,
        userId      = tostring(Player.UserId),
    }
    
    local ok, result = httpPost(url, data)
    
    if ok and result.success then
        State.hwid = newHwid
        notify("HWID reset successful", "ok")
        return true, result
    else
        local msg = result.message or "HWID reset failed"
        notify(msg, "error")
        return false, msg
    end
end

-- Check if HWID reset is available
function API.CanResetHWID(key)
    if State.unloaded then return false end
    
    key = key or State.key
    if not key then return false end
    
    local url = State.baseURL .. "/hwid-reset?key=" .. HttpService:UrlEncode(key)
    local ok, result = httpGet(url)
    
    if ok and result.available then
        return true, result
    else
        return false, result
    end
end

-- ========================================================
-- PREMIUM CHECKOUT (redirect to web)
-- ========================================================
--[[
    API.GetCheckoutURL(plan, email, robloxUsername, discordUsername)
    Returns: url (string)
    
    Opens checkout page in browser. User completes payment,
    receives key via email + Discord webhook.
]]
function API.GetCheckoutURL(plan, email, robloxUsername, discordUsername)
    plan = plan or "lifetime"
    local params = {
        "plan=" .. HttpService:UrlEncode(plan),
        "email=" .. HttpService:UrlEncode(email or ""),
        "roblox=" .. HttpService:UrlEncode(robloxUsername or Player.Name),
        "discord=" .. HttpService:UrlEncode(discordUsername or ""),
        "userId=" .. tostring(Player.UserId),
        "hwid=" .. (State.hwid or generateHWID()),
    }
    
    local url = "https://getpawzhub.vercel.app/checkout?" .. table.concat(params, "&")
    
    -- Copy to clipboard (if supported)
    pcall(function()
        setclipboard(url)
        notify("Checkout URL copied to clipboard", "ok")
    end)
    
    return url
end

-- ========================================================
-- BLACKLIST CHECK
-- ========================================================
function API.IsBlacklisted(userId)
    userId = userId or tostring(Player.UserId)
    
    -- Blacklist check happens server-side during verification
    -- This is a client-side cache check
    if State.keyData and State.keyData.blacklisted then
        return true
    end
    
    return false
end

-- ========================================================
-- FEATURE CHECK
-- ========================================================
function API.HasFeature(featureName)
    for _, f in ipairs(State.features) do
        if f == featureName then
            return true
        end
    end
    return false
end

function API.GetFeatures()
    return State.features
end

function API.GetTier()
    return State.tier
end

-- ========================================================
-- SESSION INFO
-- ========================================================
function API.GetKeyData()
    return State.keyData
end

function API.GetHWID()
    return State.hwid or generateHWID()
end

function API.GetSessionStats()
    local uptime = State.sessionStart > 0 and (tick() - State.sessionStart) or 0
    return {
        uptime         = uptime,
        totalRequests  = State.totalRequests,
        failedRequests = State.failedRequests,
        successRate    = State.totalRequests > 0
                         and math.floor((1 - State.failedRequests / State.totalRequests) * 100)
                         or 0,
    }
end

-- ========================================================
-- INIT
-- ========================================================
function API.Init(baseURL)
    if State.initialized then return API end
    if State.unloaded then return API end
    
    if baseURL and type(baseURL) == "string" then
        State.baseURL = baseURL
    end
    
    State.sessionStart = tick()
    State.hwid         = generateHWID()
    
    State.initialized = true
    return API
end

-- ========================================================
-- UNLOAD
-- ========================================================
function API.Unload()
    if State.unloaded then return end
    State.unloaded = true
    
    -- Clear sensitive data
    State.key      = nil
    State.keyData  = nil
    State.verified = false
end

-- ========================================================
-- DEBUG
-- ========================================================
function API.Dump()
    return {
        version        = API.__version,
        initialized    = State.initialized,
        unloaded       = State.unloaded,
        baseURL        = State.baseURL,
        verified       = State.verified,
        tier           = State.tier,
        features       = State.features,
        hwid           = State.hwid,
        hasKey         = State.key ~= nil,
        sessionUptime  = State.sessionStart > 0 and (tick() - State.sessionStart) or 0,
        totalRequests  = State.totalRequests,
        failedRequests = State.failedRequests,
    }
end

return API

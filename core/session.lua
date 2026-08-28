--[[
    PawZHub Session  v1.5.0
    ====================
    Holds the active session (key + tier + expiry) for the duration
    of a successful authentication.  Game modules read the session
    from getgenv().PawZHub_Session when they need to know what the
    user paid for.
]]

local Session = {}

-- Token (random per-session, never sent to backend)
local function genToken()
    local ok, id = pcall(function()
        return game:GetService("HttpService"):GenerateGUID(false)
    end)
    if ok and type(id) == "string" and id ~= "" then
        return id:gsub("-", ""):sub(1, 32)
    end
    return tostring(os.time()) .. tostring(math.random(1, 1e9))
end

-- Create a session from a key-validate result
function Session.create(result, opts)
    opts = opts or {}
    if type(result) ~= "table" then return nil end
    if result.status ~= "VALID"
       and result.status ~= "PREMIUM"
       and result.status ~= "FREE" then
        return nil
    end
    local s = {
        token       = genToken(),
        key         = result.key,
        keyType     = result.status,
        tier        = result.tier or "free",
        features    = result.features or {},
        expires     = result.expires,
        hwidBound   = result.hwidBound,
        createdAt   = os.time(),
        expiresAt   = result.expires or (os.time() + 3600),
        userId      = tostring(opts.userId or ""),
        username    = opts.username or "",
        executor    = opts.executor or "",
        platform    = opts.platform or "",
    }
    -- publish to the global namespace so game scripts can read it
    getgenv().PawZHub_Session = s
    return s
end

-- Read the current session (or nil)
function Session.current()
    return getgenv().PawZHub_Session
end

-- Verify the session is still alive (not expired)
function Session.isAlive(s)
    s = s or Session.current()
    if type(s) ~= "table" then return false end
    if s.expiresAt and os.time() > s.expiresAt then return false end
    return true
end

-- Destroy the current session
function Session.destroy()
    getgenv().PawZHub_Session = nil
end

-- Build a compact summary string for the loading bar
function Session.summary(s)
    s = s or Session.current()
    if not s then return "" end
    local tier = (s.tier or "free"):upper()
    return tier .. " key" .. (s.username and (" for " .. s.username) or "")
end

return Session

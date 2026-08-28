--[[
    PawZHub Key Manager  v1.5.0
    ===========================
    Validates a key against the PawZHub backend.
    Pure: takes a key string + (optional) HWID, returns a result table
    with one of the documented STATUS values.

    Result shape:
      {
        status   = "VALID" | "INVALID" | "EXPIRED" | "REVOKED"
                 | "BANNED" | "PREMIUM" | "FREE" | "SERVER_ERROR",
        message  = "human-readable",
        key      = "<raw key>",
        tier     = "free" | "trial" | "monthly" | "lifetime" | nil,
        features = { ... } | nil,    -- list of feature names
        expires  = <unix seconds> | nil,
        hwidBound= "<hwid>" | nil,
        ...
      }
]]

local KeyManager = {}

KeyManager.STATUS = {
    VALID         = "VALID",
    INVALID       = "INVALID",
    EXPIRED       = "EXPIRED",
    REVOKED       = "REVOKED",
    BANNED        = "BANNED",
    PREMIUM       = "PREMIUM",
    FREE          = "FREE",
    SERVER_ERROR  = "SERVER_ERROR",
    RATE_LIMITED  = "RATE_LIMITED",
}

-- Local detect (pre-flight) — cheap regex check before hitting the API
function KeyManager.detectType(key)
    if type(key) ~= "string" then return nil end
    key = key:match("^%s*(.-)%s*$") or key
    if key:sub(1, 3) == "PH." and key:match("^PH%.[A-Za-z0-9_%-]+%.[A-Za-z0-9_%-]+$") then
        return "premium"
    end
    if key:match("^ey[A-Za-z0-9_%-]+%.[A-Za-z0-9_%-]+%.[A-Za-z0-9_%-]+$") then
        return "web"
    end
    return nil
end

-- Map server response -> STATUS
local function mapResponse(parsed, rawKey)
    if type(parsed) ~= "table" then
        return { status = KeyManager.STATUS.SERVER_ERROR, message = "Bad server response", key = rawKey }
    end
    if parsed.banned or parsed.blacklisted then
        return { status = KeyManager.STATUS.BANNED, message = parsed.message or "Account banned", key = rawKey }
    end
    if parsed.revoked then
        return { status = KeyManager.STATUS.REVOKED, message = parsed.message or "Key revoked", key = rawKey }
    end
    if parsed.expired then
        return { status = KeyManager.STATUS.EXPIRED, message = parsed.message or "Key expired", key = rawKey }
    end
    if not parsed.valid then
        return { status = KeyManager.STATUS.INVALID, message = parsed.message or "Invalid key", key = rawKey }
    end
    -- valid
    local tier = parsed.tier or "free"
    if tier == "free" then
        return { status = KeyManager.STATUS.FREE, message = parsed.message or "Free key accepted",
                 key = rawKey, tier = tier, features = parsed.features,
                 expires = parsed.expires, hwidBound = parsed.hwid }
    end
    return { status = KeyManager.STATUS.PREMIUM, message = parsed.message or "Premium key accepted",
             key = rawKey, tier = tier, features = parsed.features,
             expires = parsed.expires, hwidBound = parsed.hwid,
             source = parsed.source, remainingHours = parsed.remainingHours }
end

-- Public: validate via backend
--   opts: { apiUrl=string, hwid=string, userId=string, username=string,
--           placeId=number, version=string }
function KeyManager.validate(key, opts, deps)
    opts = opts or {}
    deps = deps or {}
    if type(key) ~= "string" or key == "" then
        return { status = KeyManager.STATUS.INVALID, message = "Empty key", key = key }
    end
    if not KeyManager.detectType(key) then
        return { status = KeyManager.STATUS.INVALID, message = "Unrecognized key format", key = key }
    end
    local httpGet    = deps.httpGet    or _G.PawZHub_HttpGet
    local httpPost   = deps.httpPost   or _G.PawZHub_HttpPost
    local jsonEncode = deps.jsonEncode or _G.PawZHub_JsonEncode
    local jsonDecode = deps.jsonDecode or _G.PawZHub_JsonDecode
    if not (httpGet or httpPost) or not jsonDecode then
        return { status = KeyManager.STATUS.SERVER_ERROR, message = "HTTP layer not available", key = key }
    end
    local apiUrl = opts.apiUrl
    if not apiUrl or apiUrl == "" then
        return { status = KeyManager.STATUS.SERVER_ERROR, message = "API URL missing", key = key }
    end

    local body = jsonEncode({
        key      = key,
        hwid     = opts.hwid or "",
        userId   = tostring(opts.userId or ""),
        username = opts.username or "",
        gameId   = opts.placeId or game.PlaceId,
        version  = opts.version or "",
    })

    local raw
    if httpPost then
        raw = httpPost(apiUrl, body)
    else
        -- GET with encoded body (last-resort)
        raw = httpGet(apiUrl .. "?body=" .. (body or ""))
    end
    if not raw or raw == "" then
        return { status = KeyManager.STATUS.SERVER_ERROR, message = "Server unreachable", key = key }
    end
    local parsed = jsonDecode(raw)
    return mapResponse(parsed, key)
end

return KeyManager

--[[
    PawZHub Version Checker  v1.5.0
    ==============================
    Compares the current loader version against the latest published
    version on the PawZHub backend.  Soft-fails if the network is
    unreachable — we never block boot just because version check
    is offline.
]]

local Version = {}

Version.STATUS = {
    OK         = "OK",         -- up to date
    OUTDATED   = "OUTDATED",   -- newer version available
    UNKNOWN    = "UNKNOWN",    -- couldn't determine
}

-- Pure helper: compare two "X.Y.Z" strings
-- Returns -1 if a<b, 0 if equal, 1 if a>b
function Version.compare(a, b)
    if type(a) ~= "string" or type(b) ~= "string" then return 0 end
    if a == b then return 0 end
    local function parse(v)
        local maj, minr, pat = v:match("^(%d+)%.(%d+)%.(%d+)")
        return tonumber(maj or 0), tonumber(minr or 0), tonumber(pat or 0)
    end
    local am, ai, ap = parse(a)
    local bm, bi, bp = parse(b)
    if am ~= bm then if am > bm then return 1 else return -1 end end
    if ai ~= bi then if ai > bi then return 1 else return -1 end end
    if ap ~= bp then if ap > bp then return 1 else return -1 end end
    return 0
end

-- Public: check against the backend
--   opts: { currentVersion, apiUrl, httpGet, jsonDecode }
function Version.check(opts, deps)
    opts = opts or {}
    deps = deps or {}
    local current = opts.currentVersion
    local apiUrl   = opts.apiUrl
    if type(current) ~= "string" or current == "" then
        return { status = Version.STATUS.UNKNOWN, current = current, latest = nil }
    end
    if not apiUrl or apiUrl == "" then
        return { status = Version.STATUS.UNKNOWN, current = current, latest = nil }
    end
    local httpGet    = deps.httpGet    or _G.PawZHub_HttpGet
    local jsonDecode = deps.jsonDecode or _G.PawZHub_JsonDecode
    if not httpGet or not jsonDecode then
        return { status = Version.STATUS.UNKNOWN, current = current, latest = nil }
    end
    local raw = httpGet(apiUrl)
    if not raw or raw == "" then
        return { status = Version.STATUS.UNKNOWN, current = current, latest = nil }
    end
    local parsed = jsonDecode(raw)
    if type(parsed) ~= "table" or type(parsed.version) ~= "string" then
        return { status = Version.STATUS.UNKNOWN, current = current, latest = nil }
    end
    local latest = parsed.version
    local cmp = Version.compare(current, latest)
    if cmp < 0 then
        return { status = Version.STATUS.OUTDATED, current = current, latest = latest, notes = parsed.notes }
    end
    return { status = Version.STATUS.OK, current = current, latest = latest, notes = parsed.notes }
end

return Version

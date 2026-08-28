--[[
    PawZHub Router  v1.5.0
    ===================
    Picks the right per-game script path from a detection result and
    fetches + runs it.  The router does not know about UI, keys, or
    version checks — it only knows the game -> script mapping.

    Adding a new game is a 3-line change in config.lua:
        [NEW_PLACE_ID] = { code = "XX", name = "New Game", scriptPath = "script/PawZHubXX.lua", ... }
    The detector, keymanager, and router pick it up automatically.
]]

local Router = {}

-- Take a detection result from core/detector and load the matching
-- game script.  The session is expected to be already created.
--
-- Returns:
--   { ok = true,  code = "BF", module = <returned table from script> }
--   { ok = false, error = "..." }
function Router.load(detection, opts)
    opts = opts or {}
    if type(detection) ~= "table" then
        return { ok = false, error = "Invalid detection result" }
    end
    if detection.status ~= "SUPPORTED" then
        return { ok = false, error = "Cannot route: " .. tostring(detection.reason or "unsupported") }
    end
    local entry = detection.entry
    if type(entry) ~= "table" or type(entry.scriptPath) ~= "string" or entry.scriptPath == "" then
        return { ok = false, error = "No scriptPath for game " .. tostring(detection.code) }
    end
    local deps = opts.deps or {}
    local httpGet    = deps.httpGet    or _G.PawZHub_HttpGet
    local loadFn     = deps.loadFn
    if not httpGet then
        return { ok = false, error = "HTTP layer not available" }
    end
    local raw = httpGet(opts.repoBase .. "/" .. entry.scriptPath)
    if type(raw) ~= "string" or raw == "" then
        return { ok = false, error = "Could not download " .. entry.scriptPath }
    end
    local fn, err
    if loadFn then
        fn, err = loadFn(raw)
    else
        fn, err = loadstring(raw)
    end
    if not fn then
        return { ok = false, error = "Compile error in " .. entry.scriptPath .. ": " .. tostring(err) }
    end
    local ok, res = pcall(fn)
    if not ok then
        return { ok = false, error = "Runtime error in " .. entry.scriptPath .. ": " .. tostring(res) }
    end
    return { ok = true, code = detection.code, name = detection.name, module = res }
end

-- Convenience: list every supported game as a sorted string list
-- (used by the "unsupported game" modal)
function Router.listNames(games)
    if type(games) ~= "table" then return {} end
    local out = {}
    for _, e in pairs(games) do
        if type(e.name) == "string" then out[#out + 1] = e.name end
    end
    table.sort(out)
    return out
end

return Router

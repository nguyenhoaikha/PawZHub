--[[
    PawZHub Movement Library Bootstrap
    ==================================
    Fetches and inits `script/lib/movement.lua` for the current game script.

    Usage (from any PawZHub game script):
        local Movement = require(this file via loadstring/game:HttpGet)
        Movement.Init()  -- uses default Roblox services

    Safe behavior:
        - If the network call fails, returns nil. Callers can fall back
          to their inline movement code.
        - Library Init() must be called once before any Set*/Get* calls.
        - Library Unload() tears down every connection / instance cleanly.

    See script/lib/movement.lua for the full API (28 functions).
]]

local Bootstrap = {}

local RAW = "https://raw.githubusercontent.com/nguyenhoaikha/PawZHub/main/script/lib/movement.lua"

-- fetch + load + init. Returns the Movement table, or nil on failure.
function Bootstrap.Load()
    local ok, M = pcall(function()
        local src = game:HttpGet(RAW)
        local fn, err = loadstring(src)
        if not fn then error("movement.lua loadstring: " .. tostring(err), 0) end
        return fn()
    end)
    if not ok or type(M) ~= "table" or type(M.Init) ~= "function" then
        warn("[PawZHub] Movement library unavailable: " .. tostring(M))
        return nil
    end
    M.Init()
    return M
end

-- Optional: expose as global for ad-hoc access in the executor console.
function Bootstrap.LoadAsGlobal(name)
    local M = Bootstrap.Load()
    if M and type(name) == "string" and name ~= "" then
        _G[name] = M
    end
    return M
end

return Bootstrap

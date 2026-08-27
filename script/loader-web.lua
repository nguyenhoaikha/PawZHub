-- PawZHub Main Loader v4.0
-- Entry: loadstring(game:HttpGet("https://raw.githubusercontent.com/nguyenhoaikha/PawZHub/main/loader-web.lua"))()
--
-- This loader does ONE thing: fetch and run checkkey.lua.
-- After the user verifies their key, checkkey.lua itself loads the
-- correct per-game script (PawZHubBF.lua for Blox Fruits,
-- PawZHubGG.lua for Greedy Growers) based on the current PlaceId.
--
-- Direct loadstring of the per-game script files is technically
-- possible (the raw URLs are public) but the user-facing flow is
-- always: this loader → checkkey.lua → game script.

print("[PawZHub] Initializing...")

local CONFIG = {
    GITHUB_REPO  = "https://raw.githubusercontent.com/nguyenhoaikha/PawZHub/main",
    CHECKKEY_URL = "https://raw.githubusercontent.com/nguyenhoaikha/PawZHub/main/checkkey.lua",
    VERSION      = "1.0.0",
}

-- ----- executor detection (no UI, just print) -----
local UIS = game:GetService("UserInputService")
local executor = "Unknown"
pcall(function()
    if syn or is_syn_env then executor = "Synapse X"
    elseif KRNL_LOADED then executor = "KRNL"
    elseif identifyexecutor then
        local ok, name = pcall(identifyexecutor); executor = ok and name or "Unknown"
    elseif APPLETOUCHHOOK_LOADED then executor = "Delta"
    elseif FLUX_LOADED then executor = "Flux"
    elseif Arceus then executor = "Arceus X"
    elseif hydrogen then executor = "Hydrogen"
    end
end)
local platform = "PC"
if UIS.TouchEnabled and not UIS.KeyboardEnabled then
    platform = "Mobile"
end
print("[PawZHub] Executor: " .. executor .. " | Platform: " .. platform)

-- ----- fetch + run checkkey.lua -----
local ok, body = pcall(function()
    return game:HttpGet(CONFIG.CHECKKEY_URL)
end)

if not ok or type(body) ~= "string" or body == "" then
    warn("[PawZHub] Failed to download checkkey.lua: " .. tostring(body))
    return
end

local fn, err = loadstring(body)
if not fn then
    warn("[PawZHub] checkkey.lua syntax error: " .. tostring(err))
    return
end

print("[PawZHub] Loading key system...")
local ok2, runErr = pcall(fn)
if not ok2 then
    warn("[PawZHub] checkkey.lua runtime error: " .. tostring(runErr))
    return
end

print("[PawZHub] Done. v" .. CONFIG.VERSION)

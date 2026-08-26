-- PawZHub Main Loader (legacy entry → delegates to loader-web.lua)
--
-- This file exists only for backward compatibility with users who
-- still have old loadstrings pointing at .../main/loader.lua.
--
-- It does ONE thing: fetch loader-web.lua and run it. The actual
-- flow lives in loader-web.lua (and the modal / notifications live
-- in checkkey.lua). The old per-game SendNotification popup code
-- has been removed entirely — PawZHub now uses an in-modal toast
-- instead of Roblox's StarterGui SendNotification.
--
-- Preferred entry point for new loadstrings:
--   loadstring(game:HttpGet("https://raw.githubusercontent.com/nguyenhoaikha/PawZHub/main/loader-web.lua"))()

print("[PawZHub] Initializing (legacy entry)...")

local LOADER_WEB_URL = "https://raw.githubusercontent.com/nguyenhoaikha/PawZHub/main/loader-web.lua"

local ok, body = pcall(function()
    return game:HttpGet(LOADER_WEB_URL)
end)

if not ok or type(body) ~= "string" or body == "" then
    warn("[PawZHub] Failed to download loader-web.lua: " .. tostring(body))
    return
end

local fn, err = loadstring(body)
if not fn then
    warn("[PawZHub] loader-web.lua syntax error: " .. tostring(err))
    return
end

local ok2, runErr = pcall(fn)
if not ok2 then
    warn("[PawZHub] loader-web.lua runtime error: " .. tostring(runErr))
    return
end

print("[PawZHub] Done.")

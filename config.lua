--[[
    PawZHub Configuration  v1.5.0
    =============================
    Single source of truth for repo URLs, version, and game registry.
    Loaded by loader.lua and shared with all core/* modules.
]]

local Config = {}

Config.VERSION       = "1.5.0"
Config.REPO_RAW      = "https://raw.githubusercontent.com/nguyenhoaikha/PawZHub/main"
Config.SITE_URL      = "https://getpawzhub.vercel.app"
Config.DISCORD_URL   = "https://discord.gg/pawzhub"
Config.GITHUB_URL    = "https://github.com/nguyenhoaikha/PawZHub"

Config.API = {
    KEY_CHECK      = Config.SITE_URL .. "/api/verifykey",
    HWID_RESET     = Config.SITE_URL .. "/api/hwid-reset",
    KEYGEN         = Config.SITE_URL .. "/api/keygen",
    REDEEM         = Config.SITE_URL .. "/api/redeem",
    ADMIN          = Config.SITE_URL .. "/api/admin",
    CHECKPOINT     = Config.SITE_URL .. "/api/checkpoint",
    VERSION_CHECK  = Config.SITE_URL .. "/api/version",
}

-- =========================================================================
-- SUPPORTED GAMES
-- Registry of every PlaceId we know how to handle. The router picks
-- the right scriptPath from here.
-- =========================================================================
Config.GAMES = {
    [2753915549] = {
        code       = "BF",                                      -- short ID used by detector
        name       = "Blox Fruits",
        scriptPath = "script/PawZHubBF.lua",
        tier       = "free",                                    -- "free" | "trial" | "monthly" | "lifetime"
        features   = 18,
    },
    [74102906764176] = {
        code       = "GG",
        name       = "Greedy Growers",
        scriptPath = "script/PawZHubGG.lua",
        tier       = "free",
        features   = 16,
    },
}

-- Convenience: list of (PlaceId, code) for the detector to return.
function Config.gameRegistry()
    local out = {}
    for placeId, entry in pairs(Config.GAMES) do
        out[#out + 1] = { placeId = placeId, code = entry.code, name = entry.name }
    end
    return out
end

return Config

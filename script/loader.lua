--[[
    ========================================================
    PawZHub Universal Loader  v1.2.0
    ========================================================
    Entry point for all 28 PawZHub game scripts.

    Usage:
        loadstring(game:HttpGet("https://raw.githubusercontent.com/nguyenhoaikha/PawZHub/main/loader.lua"))()

    Optional key (premium games only):
        getgenv().PAWZHUB_KEY = "PH-xxxx"
        loadstring(...)()

    Tier gating:
        free    - no key required
        trial   - any key required
        monthly - monthly or lifetime key
        lifetime- lifetime key only
]]

local LOADER_VERSION = "1.2.0"
local REPO_BASE      = "https://raw.githubusercontent.com/nguyenhoaikha/PawZHub/main"
local GETKEY_URL     = "https://getpawzhub.vercel.app"

-- ========================================================
-- GAME DATABASE  (28 games, PlaceIds verified from
-- game scripts and the Roblox catalog)
-- ========================================================
local SUPPORTED_GAMES = {
    -- ===== Free (no key required) =====
    [2753915549]      = { name = "Blox Fruits",                  script = "script/games/blox-fruits.lua",          tier = "free",    features = 45  },
    [74102906764176]  = { name = "Greedy Growers",               script = "script/games/greedy-growers.lua",       tier = "free",    features = 13  },
    [72920620366355]  = { name = "Operation One",                script = "script/games/operation-one.lua",        tier = "free",    features = 47  },
    [4616652839]      = { name = "Shindo Life",                  script = "script/games/shindo-life.lua",          tier = "free",    features = 59  },
    [17017911970]     = { name = "Anime Expeditions",            script = "script/games/anime-expeditions.lua",    tier = "free",    features = 71  },
    [117612316652]    = { name = "Highschool Hoops",             script = "script/games/highschool-hoops.lua",     tier = "free",    features = 55  },
    [81128789072]     = { name = "Practical Basketball",         script = "script/games/practical-basketball.lua", tier = "free",    features = 46  },
    [17625359962]     = { name = "Grow A Chicken Fighter",       script = "script/games/grow-a-chicken.lua",       tier = "free",    features = 57  },
    [14367520663]     = { name = "Throw A Coin",                 script = "script/games/throw-a-coin.lua",         tier = "free",    features = 25  },

    -- ===== Trial tier (any key) =====
    [18758470869]     = { name = "Bloodlines",                   script = "script/games/bloodlines.lua",           tier = "trial",   features = 81  },
    [18302485861]     = { name = "VV: Ultimatum",                script = "script/games/vv-ultimatum.lua",         tier = "trial",   features = 153 },
    [10449761463]     = { name = "The Strongest Battlegrounds",  script = "script/games/tsb.lua",                  tier = "trial",   features = 109 },
    [18654662233]     = { name = "Grand Alfheim",                script = "script/games/grand-alfheim.lua",        tier = "trial",   features = 105 },
    [14979512112]     = { name = "Bridger Western",              script = "script/games/bridger.lua",              tier = "trial",   features = 113 },
    [16782532363]     = { name = "ABA",                          script = "script/games/aba.lua",                  tier = "trial",   features = 153 },
    [89959550099]     = { name = "Gakuran",                      script = "script/games/gakuran.lua",              tier = "trial",   features = 88  },
    [6735572261]      = { name = "Pilgrammed",                   script = "script/games/pilgrammed.lua",           tier = "trial",   features = 43  },
    [14704917953]     = { name = "Dokkodo",                      script = "script/games/dokkodo.lua",              tier = "trial",   features = 54  },

    -- ===== Monthly tier =====
    [131079272918660] = { name = "Devil Hunter",                 script = "script/games/devil-hunter.lua",         tier = "monthly", features = 95  },
    [5571328985]      = { name = "Anime Battle (Bloodlines Pro)", script = "script/games/bloodlines.lua",         tier = "monthly", features = 81  },
    [4588604953]      = { name = "Criminality",                  script = "script/games/criminality.lua",          tier = "monthly", features = 71  },
    [99449877692519]  = { name = "Bridger Western (Pro)",        script = "script/games/bridger.lua",              tier = "monthly", features = 113 },
    [16361990076]     = { name = "Grand Alfheim (Pro)",          script = "script/games/grand-alfheim.lua",        tier = "monthly", features = 105 },
    [13358463560]     = { name = "Asura",                        script = "script/games/asura.lua",                tier = "monthly", features = 54  },
    [91792475213200]  = { name = "Above The Rim",                script = "script/games/above-the-rim.lua",        tier = "monthly", features = 49  },
    [86544322519715]  = { name = "Horse Racing Legends",         script = "script/games/horse-racing.lua",         tier = "monthly", features = 22  },
    [100096058035179] = { name = "MS:KEN",                       script = "script/games/ms-ken.lua",               tier = "monthly", features = 55  },
    [18852831741]     = { name = "Ryujin",                       script = "script/games/ryujin.lua",               tier = "monthly", features = 57  },
    [17070462969]     = { name = "Voxel Destruct",               script = "script/games/voxel-destruct.lua",       tier = "monthly", features = 26  },
    [77649408247578]  = { name = "Dungeon Quest Reborn",         script = "script/games/dungeon-quest.lua",        tier = "monthly", features = 25  },
    [13927562399]     = { name = "Havoc",                        script = "script/games/havoc.lua",                tier = "monthly", features = 49  },
    [97598239454123]  = { name = "Grow a Garden 2",              script = "script/games/grow-garden-2.lua",        tier = "monthly", features = 16  },
}

local TIER_LEVEL = { none=0, free=1, trial=2, monthly=3, lifetime=4 }
local function canAccess(userTier, req)
    return (TIER_LEVEL[userTier] or 0) >= (TIER_LEVEL[req] or 0)
end

-- ========================================================
-- SERVICES
-- ========================================================
local Players    = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local Player     = Players.LocalPlayer

-- ========================================================
-- LOGGING
-- ========================================================
local function log(msg)  print("[PawZHub] " .. tostring(msg)) end
local function warn_(msg) warn("[PawZHub] " .. tostring(msg)) end

local function notify(title, text, duration)
    pcall(StarterGui.SetCore, StarterGui, "SendNotification", {
        Title = title, Text = text, Duration = duration or 5,
    })
end

-- ========================================================
-- HTTP
-- ========================================================
local function httpGet(url)
    local ok, res = pcall(game.HttpGet, game, url, true)
    if ok then return res end
    warn_("HTTP fail: " .. tostring(res))
    return nil
end

-- ========================================================
-- LOAD MODULE FROM GITHUB
-- ========================================================
local function loadModule(path)
    log("Fetching: " .. path)
    local src = httpGet(REPO_BASE .. "/" .. path)
    if not src or src == "" then
        warn_("Empty/nil source for: " .. path)
        return nil, "fetch failed"
    end
    local fn, err = loadstring(src)
    if not fn then
        warn_("Compile error [" .. path .. "]: " .. tostring(err))
        return nil, err
    end
    local ok, result = pcall(fn)
    if not ok then
        warn_("Runtime error [" .. path .. "]: " .. tostring(result))
        return nil, result
    end
    return result, nil
end

-- ========================================================
-- MAIN
-- ========================================================
local function main()
    log("Initializing PawZHub v" .. LOADER_VERSION .. "...")
    local ok_exec, exec = pcall(function()
        if identifyexecutor then return identifyexecutor() end
        return "Unknown"
    end)
    log("Executor: " .. (exec or "Unknown") .. " | PlaceId: " .. tostring(game.PlaceId))

    -- 1. Detect game
    local placeId   = game.PlaceId
    local gameInfo  = SUPPORTED_GAMES[placeId]

    if not gameInfo then
        notify("PawZHub",
            "Game not supported (PlaceId: " .. placeId .. ")\nCheck Discord for updates!",
            10)
        warn_("Unsupported PlaceId: " .. placeId)
        log("Supported games: " .. tostring((function()
            local n = 0
            for _ in pairs(SUPPORTED_GAMES) do n = n + 1 end
            return n
        end)()) .. " registered")
        return
    end
    log("Game: " .. gameInfo.name .. " (" .. gameInfo.tier .. ")")

    -- 2. Key gate (skip for free tier games)
    local userKey  = getgenv().PAWZHUB_KEY or _G.PAWZHUB_KEY or ""
    local userTier = "free"

    if gameInfo.tier ~= "free" then
        if userKey == "" then
            notify("PawZHub — Key Required",
                gameInfo.name .. " requires a key.\nGet one at: " .. GETKEY_URL, 10)
            pcall(setclipboard, GETKEY_URL)
            warn_("No key provided for paid game: " .. gameInfo.name)
            return
        end
        -- Verify key with backend
        local apiLib, apiErr = loadModule("script/lib/api.lua")
        if not apiLib then
            notify("PawZHub — Error", "Failed to load API: " .. tostring(apiErr), 8)
            warn_("API load failed: " .. tostring(apiErr))
            return
        end
        if type(apiLib.Init) == "function" then
            pcall(apiLib.Init)
        end
        if type(apiLib.VerifyKey) ~= "function" then
            notify("PawZHub — Error", "API missing VerifyKey", 8)
            warn_("API.VerifyKey not a function")
            return
        end
        local valid, result = apiLib.VerifyKey(userKey)
        if not valid then
            notify("PawZHub — Invalid Key",
                (type(result) == "table" and result.message) or "Verification failed", 8)
            warn_("Key invalid: " .. tostring(result))
            return
        end
        userTier = (type(result) == "table" and result.tier) or "free"
        if not canAccess(userTier, gameInfo.tier) then
            notify("PawZHub — Upgrade Required",
                gameInfo.name .. " needs " .. gameInfo.tier .. " (you have: " .. userTier .. ")", 8)
            warn_("Tier insufficient: " .. userTier .. " < " .. gameInfo.tier)
            return
        end
        log("Key OK | Tier: " .. userTier)
    else
        log("Free game, no key required")
    end

    -- 3. Load shared libraries (parallel-safe)
    log("Loading libraries...")
    local libs = {}
    local libNames = { "ui", "notifications", "esp", "combat", "utility", "basketball" }
    for _, name in ipairs(libNames) do
        local lib, err = loadModule("script/lib/" .. name .. ".lua")
        if not lib then
            warn_("Lib " .. name .. " unavailable: " .. tostring(err) .. " (skipping)")
            -- continue; some libs are optional
        else
            libs[name] = lib
            log("Lib OK: " .. name)
            if type(lib.Init) == "function" then
                pcall(lib.Init)
            end
        end
    end

    -- 4. Create Hub UI  (UI lib is REQUIRED)
    if not libs.ui or type(libs.ui.New) ~= "function" then
        notify("PawZHub — Error", "UI library missing or invalid", 8)
        warn_("UI lib missing — cannot create Hub")
        return
    end
    log("Building Hub UI...")
    local Hub = libs.ui.New({
        title  = "PawZHub",
        game   = gameInfo.name,
        key    = userKey ~= "" and (string.sub(userKey, 1, 16) .. "...") or "Free",
        theme  = "Dark",
        toggle = Enum.KeyCode.RightShift,
        width  = 540,
        height = 380,
    })

    if not Hub then
        notify("PawZHub — Error", "Failed to create Hub UI", 8)
        warn_("Hub.New returned nil")
        return
    end
    -- Register global notify hook (optional but useful)
    if type(Hub.RegisterAsGlobal) == "function" then
        pcall(Hub.RegisterAsGlobal, Hub)
    end
    log("Hub UI created")

    -- 5. Expose globals so game scripts can use them
    getgenv().PawZHub = {
        Version  = LOADER_VERSION,
        Game     = gameInfo.name,
        Tier     = userTier,
        Hub      = Hub,
        UI       = libs.ui,
        Toast    = libs.notifications or {},
        ESP      = libs.esp         or {},
        Combat   = libs.combat      or {},
        Utility  = libs.utility     or {},
        Basketball = libs.basketball or {},
        Unload   = function()
            pcall(function() if Hub and Hub.Destroy then Hub:Destroy() end end)
            pcall(function() if libs.esp    and libs.esp.Unload    then libs.esp:Unload()    end end)
            pcall(function() if libs.combat and libs.combat.Unload then libs.combat:Unload() end end)
            pcall(function() if libs.utility and libs.utility.Unload then libs.utility:Unload() end end)
            getgenv().PawZHub = nil
            log("Unloaded")
        end,
    }

    -- 6. Load game script
    log("Loading game script: " .. gameInfo.script)
    local gameScript, gsErr = loadModule(gameInfo.script)
    if not gameScript then
        notify("PawZHub — Error",
            "Failed to load game script:\n" .. tostring(gsErr), 10)
        warn_("Game script load failed: " .. tostring(gsErr))
        -- Keep the Hub visible so user can see something loaded
        if type(Hub.Notify) == "function" then
            pcall(Hub.Notify, Hub, "Game script failed to load", "error", 6)
        end
        return
    end
    log("Game script loaded (" .. type(gameScript) .. ")")

    -- 7. Bootstrap features into Hub
    --    Convention: gameScript.ExportFeatures(Hub)  — first param is Hub
    log("Bootstrapping features...")
    local bootstrapOk, bootstrapErr
    if type(gameScript) == "table" and type(gameScript.ExportFeatures) == "function" then
        -- Pass Hub as the only positional arg (self=gameScript is implicit)
        bootstrapOk, bootstrapErr = pcall(gameScript.ExportFeatures, Hub)
    elseif type(gameScript) == "function" then
        bootstrapOk, bootstrapErr = pcall(gameScript, Hub)
    else
        warn_("Unknown game script format: " .. type(gameScript))
        bootstrapOk, bootstrapErr = false, "Unknown format"
    end

    if not bootstrapOk then
        warn_("Bootstrap error: " .. tostring(bootstrapErr))
        if type(Hub.Notify) == "function" then
            pcall(Hub.Notify, Hub,
                "Some features may not load:\n" .. tostring(bootstrapErr), "warn", 8)
        end
    end

    -- 8. Done
    log("Done.")
    if type(Hub.Notify) == "function" then
        pcall(Hub.Notify, Hub,
            "Welcome to PawZHub " .. gameInfo.name .. "!\n"
            .. gameInfo.features .. " features loaded · RightShift to toggle",
            "ok", 5)
    end
end

-- ========================================================
-- SAFE EXECUTE
-- ========================================================
local ok, err = pcall(main)
if not ok then
    warn("[PawZHub] FATAL: " .. tostring(err))
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "PawZHub Fatal Error",
            Text  = tostring(err):sub(1, 100),
            Duration = 10,
        })
    end)
end

Players.PlayerRemoving:Connect(function(p)
    if p == Player and getgenv().PawZHub then
        pcall(getgenv().PawZHub.Unload)
    end
end)

--[[
    ========================================================
    PawZHub Universal Loader  v2.0.0
    ========================================================
    Entry point for all PawZHub game scripts.

    Flow:
      1. Detect game
      2. Verify key (if required) BEFORE loading anything
      3. Show loading progress (0% → 100%)
      4. Load shared libraries
      5. Create Hub UI
      6. Load game script
      7. Bootstrap features

    Usage:
        loadstring(game:HttpGet("https://raw.githubusercontent.com/nguyenhoaikha/PawZHub/main/loader.lua"))()
]]

local LOADER_VERSION = "2.0.0"
local REPO_BASE      = "https://raw.githubusercontent.com/nguyenhoaikha/PawZHub/main"
local GETKEY_URL     = "https://getpawzhub.vercel.app"

-- ========================================================
-- GAME DATABASE
-- ========================================================
local SUPPORTED_GAMES = {
    -- ===== Free (no key required) =====
    [2753915549]      = { name = "Blox Fruits",                  script = "games/blox-fruits.lua",          tier = "free",    features = 45  },
    [74102906764176]  = { name = "Greedy Growers",               script = "games/greedy-growers.lua",       tier = "free",    features = 13  },
    [72920620366355]  = { name = "Operation One",                script = "games/operation-one.lua",        tier = "free",    features = 47  },
    [4616652839]      = { name = "Shindo Life",                  script = "games/shindo-life.lua",          tier = "free",    features = 59  },
    [17017911970]     = { name = "Anime Expeditions",            script = "games/anime-expeditions.lua",    tier = "free",    features = 71  },
    [117612316652]    = { name = "Highschool Hoops",             script = "games/highschool-hoops.lua",     tier = "free",    features = 55  },
    [81128789072]     = { name = "Practical Basketball",         script = "games/practical-basketball.lua", tier = "free",    features = 46  },
    [17625359962]     = { name = "Grow A Chicken Fighter",       script = "games/grow-a-chicken.lua",       tier = "free",    features = 57  },
    [14367520663]     = { name = "Throw A Coin",                 script = "games/throw-a-coin.lua",         tier = "free",    features = 25  },
    -- ===== Trial tier (any key) =====
    [18758470869]     = { name = "Bloodlines",                   script = "games/bloodlines.lua",           tier = "trial",   features = 81  },
    [18302485861]     = { name = "VV: Ultimatum",                script = "games/vv-ultimatum.lua",         tier = "trial",   features = 153 },
    [10449761463]     = { name = "The Strongest Battlegrounds",  script = "games/tsb.lua",                  tier = "trial",   features = 109 },
    [18654662233]     = { name = "Grand Alfheim",                script = "games/grand-alfheim.lua",        tier = "trial",   features = 105 },
    [14979512112]     = { name = "Bridger Western",              script = "games/bridger.lua",              tier = "trial",   features = 113 },
    [16782532363]     = { name = "ABA",                          script = "games/aba.lua",                  tier = "trial",   features = 153 },
    [89959550099]     = { name = "Gakuran",                      script = "games/gakuran.lua",              tier = "trial",   features = 88  },
    [6735572261]      = { name = "Pilgrammed",                   script = "games/pilgrammed.lua",           tier = "trial",   features = 43  },
    [14704917953]     = { name = "Dokkodo",                      script = "games/dokkodo.lua",              tier = "trial",   features = 54  },
    -- ===== Monthly tier =====
    [131079272918660] = { name = "Devil Hunter",                 script = "games/devil-hunter.lua",         tier = "monthly", features = 95  },
    [4588604953]      = { name = "Criminality",                  script = "games/criminality.lua",          tier = "monthly", features = 71  },
    [13358463560]     = { name = "Asura",                        script = "games/asura.lua",                tier = "monthly", features = 54  },
    [91792475213200]  = { name = "Above The Rim",                script = "games/above-the-rim.lua",        tier = "monthly", features = 49  },
    [86544322519715]  = { name = "Horse Racing Legends",         script = "games/horse-racing.lua",         tier = "monthly", features = 22  },
    [100096058035179] = { name = "MS:KEN",                       script = "games/ms-ken.lua",               tier = "monthly", features = 55  },
    [18852831741]     = { name = "Ryujin",                       script = "games/ryujin.lua",               tier = "monthly", features = 57  },
    [17070462969]     = { name = "Voxel Destruct",               script = "games/voxel-destruct.lua",       tier = "monthly", features = 26  },
    [77649408247578]  = { name = "Dungeon Quest Reborn",         script = "games/dungeon-quest.lua",        tier = "monthly", features = 25  },
    [13927562399]     = { name = "Havoc",                        script = "games/havoc.lua",                tier = "monthly", features = 49  },
    [97598239454123]  = { name = "Grow a Garden 2",              script = "games/grow-garden-2.lua",        tier = "monthly", features = 16  },
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
-- LOADING PROGRESS UI
-- ========================================================
local LoadingUI = {}
function LoadingUI:Create()
    local sg = Instance.new("ScreenGui")
    sg.Name = "PawZHubLoading"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 999
    pcall(function()
        local parent = CoreGui
        pcall(function() if gethui then parent = gethui() end end)
        sg.Parent = parent
    end)

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(0, 320, 0, 120)
    bg.Position = UDim2.new(0.5, 0, 0.85, 0)
    bg.AnchorPoint = Vector2.new(0.5, 0.5)
    bg.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    bg.BorderSizePixel = 0
    bg.Parent = sg
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(40, 40, 55)
    stroke.Thickness = 1
    stroke.Parent = bg

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 20)
    title.Position = UDim2.new(0, 10, 0, 12)
    title.BackgroundTransparency = 1
    title.Text = "PawZHub"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 14
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = bg

    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -20, 0, 14)
    status.Position = UDim2.new(0, 10, 0, 36)
    status.BackgroundTransparency = 1
    status.Text = "Initializing..."
    status.TextColor3 = Color3.fromRGB(120, 120, 120)
    status.TextSize = 11
    status.Font = Enum.Font.Gotham
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.Parent = bg

    -- Progress bar background
    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(1, -20, 0, 6)
    barBg.Position = UDim2.new(0, 10, 0, 58)
    barBg.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    barBg.BorderSizePixel = 0
    barBg.Parent = bg
    Instance.new("UICorner", barBg).CornerRadius = UDim.new(0, 3)

    -- Progress bar fill
    local barFill = Instance.new("Frame")
    barFill.Size = UDim2.new(0, 0, 1, 0)
    barFill.BackgroundColor3 = Color3.fromRGB(99, 102, 241)
    barFill.BorderSizePixel = 0
    barFill.Parent = barBg
    Instance.new("UICorner", barFill).CornerRadius = UDim.new(0, 3)

    -- Percent text
    local pct = Instance.new("TextLabel")
    pct.Size = UDim2.new(1, -20, 0, 14)
    pct.Position = UDim2.new(0, 10, 0, 70)
    pct.BackgroundTransparency = 1
    pct.Text = "0%"
    pct.TextColor3 = Color3.fromRGB(99, 102, 241)
    pct.TextSize = 12
    pct.Font = Enum.Font.GothamBold
    pct.TextXAlignment = Enum.TextXAlignment.Right
    pct.Parent = bg

    self._sg = sg
    self._status = status
    self._barFill = barFill
    self._pct = pct
    self._bg = bg
end

function LoadingUI:Update(percent, text)
    if self._status then self._status.Text = text or "Loading..." end
    if self._barFill then
        TweenService:Create(self._barFill, TweenInfo.new(0.3), {
            Size = UDim2.new(math.clamp(percent / 100, 0, 1), 0, 1, 0)
        }):Play()
    end
    if self._pct then self._pct.Text = tostring(math.floor(percent)) .. "%" end
end

function LoadingUI:Destroy()
    if self._sg and self._sg.Parent then
        pcall(function() self._sg:Destroy() end)
    end
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

    -- Create loading UI first
    LoadingUI:Create()
    LoadingUI:Update(5, "Detecting game...")

    local ok_exec, exec = pcall(function()
        if identifyexecutor then return identifyexecutor() end
        return "Unknown"
    end)
    log("Executor: " .. (exec or "Unknown") .. " | PlaceId: " .. tostring(game.PlaceId))

    -- 1. Detect game
    local placeId   = game.PlaceId
    local gameInfo  = SUPPORTED_GAMES[placeId]

    if not gameInfo then
        LoadingUI:Update(100, "Game not supported!")
        notify("PawZHub",
            "Game not supported (PlaceId: " .. placeId .. ")\nCheck Discord for updates!", 10)
        warn_("Unsupported PlaceId: " .. placeId)
        task.wait(2)
        LoadingUI:Destroy()
        return
    end
    log("Game: " .. gameInfo.name .. " (" .. gameInfo.tier .. ")")
    LoadingUI:Update(10, "Game: " .. gameInfo.name)

    -- 2. Key gate (verify BEFORE loading anything)
    LoadingUI:Update(15, "Checking key...")
    local userKey  = getgenv().PAWZHUB_KEY or _G.PAWZHUB_KEY or ""
    local userTier = "free"

    if gameInfo.tier ~= "free" then
        if userKey == "" then
            LoadingUI:Update(100, "Key required!")
            notify("PawZHub — Key Required",
                gameInfo.name .. " requires a key.\nGet one at: " .. GETKEY_URL, 10)
            pcall(setclipboard, GETKEY_URL)
            warn_("No key provided for paid game: " .. gameInfo.name)
            task.wait(2)
            LoadingUI:Destroy()
            return
        end
        -- Load API and verify key FIRST
        LoadingUI:Update(20, "Verifying key...")
        local apiLib, apiErr = loadModule("lib/api.lua")
        if not apiLib then
            LoadingUI:Update(100, "API load failed!")
            notify("PawZHub — Error", "Failed to load API: " .. tostring(apiErr), 8)
            task.wait(2)
            LoadingUI:Destroy()
            return
        end
        if type(apiLib.Init) == "function" then pcall(apiLib.Init) end
        if type(apiLib.VerifyKey) ~= "function" then
            LoadingUI:Update(100, "API error!")
            notify("PawZHub — Error", "API missing VerifyKey", 8)
            task.wait(2)
            LoadingUI:Destroy()
            return
        end
        LoadingUI:Update(25, "Verifying key...")
        local valid, result = apiLib.VerifyKey(userKey)
        if not valid then
            LoadingUI:Update(100, "Invalid key!")
            notify("PawZHub — Invalid Key",
                (type(result) == "table" and result.message) or "Verification failed", 8)
            task.wait(2)
            LoadingUI:Destroy()
            return
        end
        userTier = (type(result) == "table" and result.tier) or "free"
        if not canAccess(userTier, gameInfo.tier) then
            LoadingUI:Update(100, "Upgrade required!")
            notify("PawZHub — Upgrade Required",
                gameInfo.name .. " needs " .. gameInfo.tier .. " (you have: " .. userTier .. ")", 8)
            task.wait(2)
            LoadingUI:Destroy()
            return
        end
        log("Key OK | Tier: " .. userTier)
        LoadingUI:Update(30, "Key verified ✓")
    else
        log("Free game, no key required")
        LoadingUI:Update(30, "Free game ✓")
    end

    -- 3. Load shared libraries with progress
    LoadingUI:Update(35, "Loading libraries...")
    log("Loading libraries...")
    local libs = {}
    local libNames = { "ui", "notifications", "esp", "combat", "utility", "basketball" }
    for i, name in ipairs(libNames) do
        local pct = 35 + (i / #libNames) * 30
        LoadingUI:Update(pct, "Loading " .. name .. "...")
        local lib, err = loadModule("lib/" .. name .. ".lua")
        if not lib then
            warn_("Lib " .. name .. " unavailable: " .. tostring(err) .. " (skipping)")
        else
            libs[name] = lib
            log("Lib OK: " .. name)
            if type(lib.Init) == "function" then
                pcall(lib.Init)
            end
        end
    end
    LoadingUI:Update(65, "Libraries loaded ✓")

    -- 4. Create Hub UI
    if not libs.ui or type(libs.ui.New) ~= "function" then
        LoadingUI:Update(100, "UI library missing!")
        notify("PawZHub — Error", "UI library missing or invalid", 8)
        warn_("UI lib missing — cannot create Hub")
        task.wait(2)
        LoadingUI:Destroy()
        return
    end
    LoadingUI:Update(70, "Building UI...")
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
        LoadingUI:Update(100, "UI creation failed!")
        notify("PawZHub — Error", "Failed to create Hub UI", 8)
        warn_("Hub.New returned nil")
        task.wait(2)
        LoadingUI:Destroy()
        return
    end
    if type(Hub.RegisterAsGlobal) == "function" then
        pcall(Hub.RegisterAsGlobal, Hub)
    end
    LoadingUI:Update(75, "UI created ✓")
    log("Hub UI created")

    -- 5. Expose globals
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
    LoadingUI:Update(80, "Loading " .. gameInfo.name .. "...")
    log("Loading game script: " .. gameInfo.script)
    local gameScript, gsErr = loadModule(gameInfo.script)
    if not gameScript then
        LoadingUI:Update(100, "Game script failed!")
        notify("PawZHub — Error",
            "Failed to load game script:\n" .. tostring(gsErr), 10)
        warn_("Game script load failed: " .. tostring(gsErr))
        if type(Hub.Notify) == "function" then
            pcall(Hub.Notify, Hub, "Game script failed to load", "error", 6)
        end
        task.wait(2)
        LoadingUI:Destroy()
        return
    end
    LoadingUI:Update(90, "Script loaded ✓")
    log("Game script loaded (" .. type(gameScript) .. ")")

    -- 7. Bootstrap features into Hub
    LoadingUI:Update(95, "Initializing features...")
    log("Bootstrapping features...")
    local bootstrapOk, bootstrapErr
    if type(gameScript) == "table" and type(gameScript.ExportFeatures) == "function" then
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
    LoadingUI:Update(100, "Ready!")
    log("Done.")
    task.wait(0.5)
    LoadingUI:Destroy()

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

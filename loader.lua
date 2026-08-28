--[[
    ========================================================
    PAWZHub Universal Loader  v1.5.0
    ========================================================
    Single entry point. The user's loadstring calls into this file;
    it then orchestrates the rest of the system:

        loader.lua  -->  core/detector.lua
                            \--> UNSUPPORTED ? show "not supported" modal, STOP
                            \--> SUPPORTED  ? continue
                  -->  core/version.lua   (soft check; never blocks)
                  -->  checkkey.lua      (key UI -> core/keymanager.lua -> core/session.lua)
                  -->  core/router.lua   (loads the right game module)

    All side effects are routed through core/error.lua so the user
    always sees a friendly PawZHub-branded message instead of a raw
    Lua stack trace.

    Usage:
        loadstring(game:HttpGet("https://raw.githubusercontent.com/nguyenhoaikha/PawZHub/main/loader.lua"))()
]]

-- ========================================================
-- STEP 0: detect environment (very early, before any module load)
-- ========================================================
local HttpService = game:GetService("HttpService")
local UIS        = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

-- Tiny inline utilities (we can't load core/utils.lua yet because the
-- loading bar itself needs them; keep these self-contained here).
local function pcallSafe(fn, default)
    if type(fn) ~= "function" then return default end
    local ok, res = pcall(fn)
    if not ok then return default end
    return res
end
local function detectExecutor()
    local ok, name = pcall(identifyexecutor)
    if ok and type(name) == "string" and name ~= "" then return name end
    if type(syn) == "table" and syn.request then return "Synapse X" end
    if type(KRNL_LOADED) == "boolean" and KRNL_LOADED then return "KRNL" end
    if type(fluxus) == "table" then return "Fluxus" end
    if type(Arceus) == "table" then return "Arceus X" end
    if type(hydrogen) == "table" then return "Hydrogen" end
    if type(Delta) == "table" or type(APPLETOUCHHOOK_LOADED) == "boolean" then return "Delta" end
    if type(APEX_LOADED) == "boolean" and APEX_LOADED then return "Apex" end
    return "Unknown"
end
local function detectPlatform()
    if UIS.TouchEnabled and not UIS.KeyboardEnabled then return "Mobile" end
    if UIS.TouchEnabled and UIS.KeyboardEnabled then return "Tablet" end
    return "PC"
end
local function httpGet(url)
    if not url or url == "" then return nil end
    local ok, res = pcall(game.HttpGet, game, url, true)
    if ok and type(res) == "string" and res ~= "" then return res end
    return nil
end
local function notify(title, text, duration)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title or "PawZHub", Text = text or "", Duration = tonumber(duration) or 5,
        })
    end)
end

-- Render a single-line progress bar that updates in place.
-- Uses \r so most executor consoles overwrite the same line.
local PROGRESS_LABEL = "PawZHub Loading"
local PROGRESS_WIDTH = 20
local function renderProgress(pct)
    if type(pct) ~= "number" then pct = 0 end
    if pct < 0 then pct = 0 end
    if pct > 100 then pct = 100 end
    local filled = math.floor((pct / 100) * PROGRESS_WIDTH)
    local bar = string.rep("\u{2588}", filled) .. string.rep("\u{2591}", PROGRESS_WIDTH - filled)
    return string.format("%s [%s] %d%%", PROGRESS_LABEL, bar, pct)
end
local function setProgress(pct)
    local line = renderProgress(pct)
    pcall(function() io.write("\r" .. line) io.flush() end)
end
local function finishProgress(pct, finalText)
    -- print with a newline so subsequent log lines are clean
    local line = renderProgress(pct or 100)
    if finalText and finalText ~= "" then
        line = line .. "  " .. finalText
    end
    print(line)
end

-- ========================================================
-- Publish shared deps so core/* modules can find them
-- ========================================================
_G.PawZHub_HttpGet    = httpGet
_G.PawZHub_HttpPost   = nil   -- core/keymanager prefers POST but will fall back
_G.PawZHub_JsonEncode = function(t) return pcallSafe(function() return HttpService:JSONEncode(t) end, "{}") end
_G.PawZHub_JsonDecode = function(s) return pcallSafe(function() return HttpService:JSONDecode(s) end, nil) end

local EXECUTOR  = detectExecutor()
local PLATFORM  = detectPlatform()
local PLACE_ID  = game.PlaceId

print("[PawZHub] v1.5.0  |  " .. EXECUTOR .. "  |  " .. PLATFORM .. "  |  PlaceId " .. tostring(PLACE_ID))

-- ========================================================
-- STEP 1 (0%): fetch config.lua to get repo URL + game registry
-- ========================================================
setProgress(0)

local REPO_RAW = "https://raw.githubusercontent.com/nguyenhoaikha/PawZHub/main"
local configSrc = httpGet(REPO_RAW .. "/config.lua")
if not configSrc then
    finishProgress(0, "ERROR: cannot reach GitHub raw")
    notify("PawZHub", "Could not fetch config.lua. Check executor HTTP permissions.", 8)
    return
end
local configFn, configErr = loadstring(configSrc)
if not configFn then
    finishProgress(0, "ERROR: config.lua syntax")
    notify("PawZHub", "config.lua syntax error: " .. tostring(configErr), 8)
    return
end
local Config = configFn()
if type(Config) ~= "table" then
    finishProgress(0, "ERROR: config.lua returned non-table")
    return
end

-- ========================================================
-- Fetch the core/* and checkkey.lua modules we need
-- Each loaded file is exposed via _G.PawZHub_<Name> so game scripts
-- can find them without the round-trip fetch.
-- ========================================================
local function fetchAndLoad(name)
    local src = httpGet(REPO_RAW .. "/" .. name)
    if not src then
        finishProgress(0, "ERROR: missing " .. name)
        notify("PawZHub", "Failed to download " .. name, 8)
        return nil
    end
    local fn, err = loadstring(src)
    if not fn then
        finishProgress(0, "ERROR: " .. name .. " compile")
        notify("PawZHub", name .. " syntax error: " .. tostring(err), 8)
        return nil
    end
    local ok, res = pcall(fn)
    if not ok then
        finishProgress(0, "ERROR: " .. name .. " runtime")
        notify("PawZHub", name .. " runtime error: " .. tostring(res), 8)
        return nil
    end
    return res
end

-- 20% — utils + error handler
setProgress(10)
local Utils = fetchAndLoad("core/utils.lua")
if not Utils then return end

setProgress(20)
local ErrorHandler = fetchAndLoad("core/error.lua")
if not ErrorHandler then return end

-- 40% — detector + version + session + keymanager + router
setProgress(30)
local Detector = fetchAndLoad("core/detector.lua")
if not Detector then return end

setProgress(40)
local Version = fetchAndLoad("core/version.lua")
if not Version then return end
local Session = fetchAndLoad("core/session.lua")
if not Session then return end
local KeyManager = fetchAndLoad("core/keymanager.lua")
if not KeyManager then return end
local Router = fetchAndLoad("core/router.lua")
if not Router then return end

-- Publish modules so game scripts (loaded later) can find them
_G.PawZHub_Utils     = Utils
_G.PawZHub_Error     = ErrorHandler
_G.PawZHub_Detector  = Detector
_G.PawZHub_Version   = Version
_G.PawZHub_Session   = Session
_G.PawZHub_KeyManager = KeyManager
_G.PawZHub_Router    = Router
_G.PawZHub_Config    = Config

-- ========================================================
-- STEP 2: detect the current game
-- ========================================================
setProgress(50)
local detection = Detector.detect(PLACE_ID, Config.GAMES)
if detection.status ~= "SUPPORTED" then
    -- Unsupported: print the "not supported" banner, toast, stop.
    local summary = Detector.supportSummary(Config.GAMES)
    finishProgress(50, "")
    print(summary)
    notify("PawZHub — Unsupported",
          "This game is not supported. Supported: " ..
          table.concat(Router.listNames(Config.GAMES), ", "), 10)
    -- Show a small ScreenGui with the message so the user sees it on mobile.
    pcall(function()
        local sg = Instance.new("ScreenGui")
        sg.Name = "PawZHubUnsupported"
        sg.IgnoreGuiInset = true
        sg.Parent = Player and Player:FindFirstChild("PlayerGui") or game:GetService("CoreGui")
        local f = Instance.new("Frame", sg)
        f.Size = UDim2.new(0, 360, 0, 220)
        f.Position = UDim2.new(0.5, -180, 0.5, -110)
        f.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        f.BorderSizePixel = 0
        local c = Instance.new("UICorner", f)
        c.CornerRadius = UDim.new(0, 12)
        local t = Instance.new("TextLabel", f)
        t.Size = UDim2.new(1, -24, 1, -24)
        t.Position = UDim2.new(0, 12, 0, 12)
        t.BackgroundTransparency = 1
        t.Text = summary
        t.TextColor3 = Color3.fromRGB(255, 255, 255)
        t.TextSize = 14
        t.Font = Enum.Font.GothamMedium
        t.TextWrapped = true
        t.TextXAlignment = Enum.TextXAlignment.Left
        t.TextYAlignment = Enum.TextYAlignment.Top
    end)
    return
end
finishProgress(50, detection.name .. " detected (" .. detection.code .. ")")

-- ========================================================
-- STEP 3: soft version check (never blocks boot)
-- ========================================================
setProgress(60)
local verCheck = Version.check({
    currentVersion = Config.VERSION,
    apiUrl = Config.API.VERSION_CHECK,
}, {
    httpGet    = httpGet,
    jsonDecode = _G.PawZHub_JsonDecode,
})
if verCheck.status == Version.STATUS.OUTDATED then
    finishProgress(60, "OUTDATED: " .. tostring(verCheck.latest) .. " available")
    notify("PawZHub",
          "A new version is available.\nCurrent: " .. Config.VERSION ..
          "\nLatest: " .. tostring(verCheck.latest), 10)
elseif verCheck.status == Version.STATUS.OK then
    finishProgress(60, "up to date (v" .. tostring(verCheck.latest) .. ")")
else
    finishProgress(60, "version check skipped")
end

-- ========================================================
-- STEP 4: launch checkkey.lua (key UI for the detected game)
-- ========================================================
setProgress(70)
local Player = game:GetService("Players").LocalPlayer
local checkkeySrc = httpGet(REPO_RAW .. "/checkkey.lua")
if not checkkeySrc then
    finishProgress(70, "ERROR: missing checkkey.lua")
    return
end
local checkkeyFn, checkkeyErr = loadstring(checkkeySrc)
if not checkkeyFn then
    finishProgress(70, "ERROR: checkkey.lua syntax")
    notify("PawZHub", "checkkey.lua syntax error: " .. tostring(checkkeyErr), 8)
    return
end

-- checkkey.lua expects this callback to receive the result of the
-- key UI flow.  We pass the validation / session / router tools so
-- the UI can stay focused on its job.
local Loader = {
    Config     = Config,
    Utils      = Utils,
    Detector   = Detector,
    Version    = Version,
    Session    = Session,
    KeyManager = KeyManager,
    Router     = Router,
    Error      = ErrorHandler,
    onSuccess  = function(keyResult)
        -- 80% — key validated, create session
        setProgress(80)
        local session = Session.create(keyResult, {
            userId   = Player and Player.UserId,
            username = Player and Player.Name,
            executor = EXECUTOR,
            platform = PLATFORM,
        })
        if not session then
            finishProgress(80, "ERROR: could not create session")
            ErrorHandler.fatal(ErrorHandler.KIND.KEY, "Could not create session")
            return
        end
        finishProgress(80, "session created")

        -- 90% — load the per-game module
        setProgress(90)
        local loadRes = Router.load(detection, { repoBase = REPO_RAW })
        if not loadRes.ok then
            finishProgress(90, "ERROR: " .. (loadRes.error or ""))
            ErrorHandler.fatal(ErrorHandler.KIND.GAME_MODULE, loadRes.error)
            return
        end

        -- 100%
        finishProgress(100, "loaded " .. (loadRes.name or "module"))
        print("[PawZHub] Ready.")
    end,
}

local ok, runErr = pcall(checkkeyFn, Loader, detection)
if not ok then
    finishProgress(70, "ERROR: checkkey.lua runtime")
    ErrorHandler.fatal(ErrorHandler.KIND.API, "checkkey.lua runtime error: " .. tostring(runErr))
    return
end

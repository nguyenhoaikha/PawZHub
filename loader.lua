-- PawZHub Main Loader v2.1
-- Entry: loadstring(game:HttpGet("https://raw.githubusercontent.com/nguyenhoaikha/PawZHub/main/loader.lua"))()

print("[PawZHub] Initializing...")

local GITHUB_REPO = "https://raw.githubusercontent.com/nguyenhoaikha/PawZHub/main"

local SUPPORTED_GAMES = {
    [2753915549] = {
        name = "Blox Fruits",
        script = "PawZHubBF.lua",
        displayName = "Blox Fruits"
    },
    [4866604015] = {
        name = "Gunfight Arena",
        script = "PawZHubGG.lua",
        displayName = "Gunfight Arena"
    },
}

local function detectGame()
    return SUPPORTED_GAMES[game.PlaceId]
end

local function detectExecutor()
    local info = { name = "Unknown", platform = "Unknown" }
    local UIS = game:GetService("UserInputService")

    pcall(function()
        if syn or is_syn_env then
            info.name, info.platform = "Synapse X", "PC"
        elseif KRNL_LOADED then
            info.name, info.platform = "KRNL", "PC"
        elseif identifyexecutor then
            info.name = select(1, pcall(identifyexecutor)) or "Unknown"
            info.platform = "PC"
        elseif APPLETOUCHHOOK_LOADED then
            info.name, info.platform = "Delta", "iOS"
        elseif FLUX_LOADED then
            info.name, info.platform = "Flux", "iOS"
        elseif Arceus then
            info.name, info.platform = "Arceus X", "Android"
        elseif hydrogen then
            info.name, info.platform = "Hydrogen", "Android"
        elseif UIS.TouchEnabled and not UIS.KeyboardEnabled then
            info.name, info.platform = "Mobile", "Mobile"
        elseif UIS.KeyboardEnabled then
            info.name, info.platform = "PC Executor", "PC"
        end
    end)

    _G.PawZHub_Executor = info
    return info
end

local function loadCheckKey()
    local url = GITHUB_REPO .. "/checkkey.lua"
    local success, result = pcall(function()
        return game:HttpGet(url)
    end)

    if not success then
        warn("[PawZHub] Failed to load key system:", result)
        return nil
    end

    local func = loadstring(result)
    if not func then
        warn("[PawZHub] Failed to compile key system")
        return nil
    end

    return func()
end

local function loadGameScript(gameData)
    print("[PawZHub] Loading", gameData.name, "script...")

    local url = GITHUB_REPO .. "/script/" .. gameData.script
    local success, code = pcall(function()
        return game:HttpGet(url)
    end)

    if not success then
        warn("[PawZHub] Failed to load game script:", code)
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "PawZHub",
            Text = "Failed to load game script",
            Duration = 5
        })
        return
    end

    local func = loadstring(code)
    if not func then
        warn("[PawZHub] Script compilation failed")
        return
    end

    print("[PawZHub] Executing", gameData.name, "script")
    func()
end

local function notify(title, text, duration)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration or 5
        })
    end)
end

local function main()
    local executorInfo = detectExecutor()
    print("[PawZHub] Executor:", executorInfo.name, "| Platform:", executorInfo.platform)

    local gameData = detectGame()

    if not gameData then
        notify("PawZHub", "This game is not supported yet!", 8)
        warn("[PawZHub] PlaceId", game.PlaceId, "not supported")
        return
    end

    print("[PawZHub] Detected:", gameData.name, "(PlaceId:", game.PlaceId, ")")
    notify("PawZHub", "Loading for " .. gameData.displayName, 3)

    local CheckKeySystem = loadCheckKey()

    if not CheckKeySystem then
        notify("PawZHub", "Failed to load authentication system", 8)
        return
    end

    print("[PawZHub] Key system loaded")

    CheckKeySystem.show(function(success, session)
        if success then
            print("[PawZHub] Auth successful! Key type:", session.keyType)
            print("[PawZHub] Tier:", session.keyTier, "| Features:", table.concat(session.keyFeatures, ", "))

            notify("PawZHub", "Authenticated! Loading " .. gameData.displayName, 3)

            task.wait(0.5)
            loadGameScript(gameData)
        else
            notify("PawZHub", "Authentication failed", 5)
            warn("[PawZHub] Key verification failed")
        end
    end)
end

local success, error = pcall(main)
if not success then
    warn("[PawZHub] Loader error:", error)
    notify("PawZHub", "An error occurred. Check console (F9)", 8)
end

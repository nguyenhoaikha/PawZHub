-- PawZHub Main Loader v3.0 (Web Integration)
-- Entry: loadstring(game:HttpGet("https://raw.githubusercontent.com/nguyenhoaikha/PawZHub/main/loader-web.lua"))()

print("[PawZHub] Initializing v3.0...")

-- ============================================
-- CONFIGURATION
-- ============================================

local CONFIG = {
    GITHUB_REPO = "https://raw.githubusercontent.com/nguyenhoaikha/PawZHub/main",
    WEB_URL = "https://getpawzhub.vercel.app",
    GET_KEY_URL = "https://getpawzhub.vercel.app/getkey",
    VERSION = "3.0.0"
}

-- ============================================
-- SUPPORTED GAMES
-- ============================================

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

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================

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
            local ok, name = pcall(identifyexecutor)
            info.name = ok and name or "Unknown"
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

local function notify(title, text, duration)
    pcall(function()
        local Players = game:GetService("Players")
        local TweenService = game:GetService("TweenService")
        local player = Players.LocalPlayer
        local playerGui = player:WaitForChild("PlayerGui")
        
        -- Create custom notification
        local notif = Instance.new("ScreenGui")
        notif.Name = "PawZHubNotification"
        notif.ResetOnSpawn = false
        notif.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 300, 0, 80)
        frame.Position = UDim2.new(1, 20, 0, 20)
        frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
        frame.BorderSizePixel = 0
        frame.Parent = notif
        
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
        
        local border = Instance.new("UIStroke", frame)
        border.Color = Color3.fromRGB(139, 92, 246)
        border.Thickness = 2
        
        -- Icon
        local icon = Instance.new("TextLabel")
        icon.Size = UDim2.new(0, 40, 0, 40)
        icon.Position = UDim2.new(0, 15, 0.5, -20)
        icon.BackgroundTransparency = 1
        icon.Text = "🐾"
        icon.TextSize = 32
        icon.Parent = frame
        
        -- Title
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Size = UDim2.new(1, -70, 0, 25)
        titleLabel.Position = UDim2.new(0, 60, 0, 10)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = title
        titleLabel.TextColor3 = Color3.fromRGB(240, 240, 245)
        titleLabel.TextSize = 14
        titleLabel.Font = Enum.Font.GothamBold
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Parent = frame
        
        -- Text
        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, -70, 0, 35)
        textLabel.Position = UDim2.new(0, 60, 0, 35)
        textLabel.BackgroundTransparency = 1
        textLabel.Text = text
        textLabel.TextColor3 = Color3.fromRGB(180, 185, 195)
        textLabel.TextSize = 12
        textLabel.Font = Enum.Font.Gotham
        textLabel.TextXAlignment = Enum.TextXAlignment.Left
        textLabel.TextWrapped = true
        textLabel.Parent = frame
        
        notif.Parent = playerGui
        
        -- Slide in animation
        TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Position = UDim2.new(1, -320, 0, 20)
        }):Play()
        
        -- Auto dismiss
        task.delay(duration or 5, function()
            TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.new(1, 20, 0, 20)
            }):Play()
            task.wait(0.3)
            notif:Destroy()
        end)
    end)
end

local function loadCheckKey()
    local url = CONFIG.GITHUB_REPO .. "/checkkey.lua"
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

    local url = CONFIG.GITHUB_REPO .. "/script/" .. gameData.script
    local success, code = pcall(function()
        return game:HttpGet(url)
    end)

    if not success then
        warn("[PawZHub] Failed to load game script:", code)
        notify("PawZHub", "Failed to load game script", 5)
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

-- ============================================
-- MAIN FUNCTION
-- ============================================

local function main()
    local executorInfo = detectExecutor()
    print("[PawZHub] Executor:", executorInfo.name, "| Platform:", executorInfo.platform)
    print("[PawZHub] Version:", CONFIG.VERSION)

    local gameData = detectGame()

    if not gameData then
        print("[PawZHub] Game not supported (PlaceId:", game.PlaceId, ")")
        notify("PawZHub", "Game not supported yet", 5)
        
        -- Still load key system for testing
        print("[PawZHub] Loading key system anyway for testing...")
    else
        print("[PawZHub] Detected:", gameData.name, "(PlaceId:", game.PlaceId, ")")
        notify("PawZHub", "Loading for " .. gameData.displayName, 3)
    end

    -- Load key system
    local CheckKeySystem = loadCheckKey()

    if not CheckKeySystem then
        notify("PawZHub", "Failed to load key system", 8)
        return
    end

    print("[PawZHub] Key system loaded successfully")
    
    -- Update CONFIG in checkkey with web URL
    _G.PawZHub_WebURL = CONFIG.WEB_URL
    _G.PawZHub_GetKeyURL = CONFIG.GET_KEY_URL

    -- Show key UI
    CheckKeySystem.show(function(success, session)
        if success then
            print("[PawZHub] Authentication successful!")
            print("[PawZHub] Key type:", session.keyType or "unknown")
            print("[PawZHub] Tier:", session.keyTier or "free")
            
            if gameData then
                -- Game supported: load script
                notify("PawZHub", "Authenticated! Loading " .. gameData.displayName, 3)
                task.wait(0.5)
                loadGameScript(gameData)
            else
                -- Game not supported
                notify("PawZHub", "Key verified! But this game is not supported yet.", 5)
                print("[PawZHub] Key is valid but no script available for PlaceId:", game.PlaceId)
            end
        else
            notify("PawZHub", "Authentication failed", 5)
            warn("[PawZHub] Key verification failed")
        end
    end)
end

-- ============================================
-- RUN
-- ============================================

local success, error = pcall(main)
if not success then
    warn("[PawZHub] Loader error:", error)
    notify("PawZHub", "An error occurred. Check console (F9)", 8)
end

print("[PawZHub] Loader completed")

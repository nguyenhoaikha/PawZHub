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
        frame.Position = UDim2.new(1, 20, 0, 20)  -- Start off-screen right
        frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
        frame.BorderSizePixel = 0
        frame.Parent = notif
        
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)
        
        local border = Instance.new("UIStroke", frame)
        border.Color = Color3.fromRGB(0, 122, 255)
        border.Thickness = 2
        
        -- Icon (🐾 emoji)
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

local function main()
    local executorInfo = detectExecutor()
    print("[PawZHub] Executor:", executorInfo.name, "| Platform:", executorInfo.platform)

    local gameData = detectGame()

    -- TEST MODE: Skip game check, always load key UI
    if not gameData then
        print("[PawZHub] TEST MODE: Game not supported (PlaceId:", game.PlaceId, ")")
        notify("PawZHub [TEST MODE]", "Loading key system (game not supported)", 3)
    else
        print("[PawZHub] Detected:", gameData.name, "(PlaceId:", game.PlaceId, ")")
        notify("PawZHub", "Loading for " .. gameData.displayName, 3)
    end

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

            if gameData then
                -- Game supported: load script
                notify("PawZHub", "Authenticated! Loading " .. gameData.displayName, 3)
                task.wait(0.5)
                loadGameScript(gameData)
            else
                -- TEST MODE: Game not supported, just show success
                notify("PawZHub [TEST MODE]", "Authenticated! No game script available.", 5)
                print("[PawZHub] TEST MODE: Auth success, but no script for this game")
            end
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

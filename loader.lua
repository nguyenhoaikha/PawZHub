-- PawZHub Main Loader
-- Entry point: loadstring(game:HttpGet("https://raw.githubusercontent.com/nguyenhoaikha/PawZHub/main/loader.lua"))()

print("🐾 PawZHub Loader Initializing...")

-- Configuration
local GITHUB_REPO = "https://raw.githubusercontent.com/nguyenhoaikha/PawZHub/main"
local SUPPORTED_GAMES = {
    -- Add your game PlaceIds here
    -- Format: [PlaceId] = {name = "Game Name", script = "ScriptFileName.lua"}
    
    [2753915549] = {
        name = "Blox Fruits",
        script = "PawZHubBF.lua",
        displayName = "🍇 Blox Fruits"
    },
    [4866604015] = {
        name = "Gunfight Arena", 
        script = "PawZHubGG.lua",
        displayName = "🔫 Gunfight Arena"
    },
    -- Example for other games:
    -- [920587237] = {
    --     name = "Adopt Me",
    --     script = "PawZHubAM.lua", 
    --     displayName = "🐶 Adopt Me"
    -- },
}

-- Detect current game
local function detectGame()
    local currentPlaceId = game.PlaceId
    
    if SUPPORTED_GAMES[currentPlaceId] then
        return SUPPORTED_GAMES[currentPlaceId]
    end
    
    return nil
end

-- Load checkkey system
local function loadCheckKey()
    local url = GITHUB_REPO .. "/checkkey.lua"
    local success, result = pcall(function()
        return game:HttpGet(url)
    end)
    
    if not success then
        warn("Failed to load checkkey system: " .. tostring(result))
        return nil
    end
    
    local checkKeyFunc = loadstring(result)
    if not checkKeyFunc then
        warn("Failed to compile checkkey.lua")
        return nil
    end
    
    return checkKeyFunc()
end

-- Load game-specific script
local function loadGameScript(gameData, session)
    print("Loading " .. gameData.name .. " script...")
    
    local scriptUrl = GITHUB_REPO .. "/script/" .. gameData.script
    local success, scriptCode = pcall(function()
        return game:HttpGet(scriptUrl)
    end)
    
    if not success then
        warn("Failed to load game script: " .. tostring(scriptCode))
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "PawZHub Error",
            Text = "Failed to load game script",
            Duration = 5
        })
        return
    end
    
    -- Execute the game script
    local scriptFunc = loadstring(scriptCode)
    if not scriptFunc then
        warn("Failed to compile game script")
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "PawZHub Error", 
            Text = "Script compilation failed",
            Duration = 5
        })
        return
    end
    
    print("✓ Executing " .. gameData.name .. " script")
    scriptFunc()
end

-- Notification helper
local function notify(title, text, duration)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = duration or 5
    })
end

-- Main execution
local function main()
    -- Detect game
    local gameData = detectGame()
    
    if not gameData then
        notify(
            "❌ PawZHub",
            "This game is not supported yet!",
            8
        )
        warn("Game PlaceId " .. game.PlaceId .. " is not supported")
        return
    end
    
    print("Detected game: " .. gameData.name .. " (PlaceId: " .. game.PlaceId .. ")")
    
    notify(
        "🐾 PawZHub",
        "Loading for " .. gameData.displayName,
        3
    )
    
    -- Load checkkey system
    local CheckKeySystem = loadCheckKey()
    
    if not CheckKeySystem then
        notify(
            "❌ PawZHub Error",
            "Failed to load authentication system",
            8
        )
        return
    end
    
    print("CheckKey system loaded successfully")
    
    -- Show key verification UI
    CheckKeySystem.show(function(success, session)
        if success then
            print("✓ Authentication successful!")
            print("Session Token: " .. session.token)
            
            notify(
                "✓ Authentication Success",
                "Loading " .. gameData.displayName .. "...",
                3
            )
            
            -- Load the game-specific script
            task.wait(0.5)
            loadGameScript(gameData, session)
            
        else
            notify(
                "❌ Authentication Failed",
                "Please enter a valid key",
                5
            )
            warn("Key verification failed")
        end
    end)
end

-- Protected execution
local success, error = pcall(main)

if not success then
    warn("PawZHub Loader Error: " .. tostring(error))
    notify(
        "❌ PawZHub Error",
        "An error occurred. Check console (F9)",
        8
    )
end

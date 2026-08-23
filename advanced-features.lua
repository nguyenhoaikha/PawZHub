-- PawZHub Advanced Features Module
-- Additional features for enhanced functionality

local AdvancedFeatures = {}

-- ============================================
-- REAL-TIME ANALYTICS
-- ============================================

local Analytics = {
    sessionStart = os.time(),
    events = {},
    metrics = {
        keyVerifications = 0,
        successfulLogins = 0,
        failedAttempts = 0,
        apiCalls = 0,
        cacheHits = 0,
        cacheMisses = 0,
        averageResponseTime = 0,
        totalResponseTime = 0
    }
}

function Analytics:trackEvent(eventType, data)
    table.insert(self.events, {
        type = eventType,
        data = data,
        timestamp = os.time(),
        gameId = game.PlaceId,
        userId = game:GetService("Players").LocalPlayer.UserId
    })
    
    -- Keep only last 100 events
    if #self.events > 100 then
        table.remove(self.events, 1)
    end
end

function Analytics:getMetrics()
    local sessionTime = os.time() - self.sessionStart
    local avgResponseTime = self.metrics.totalResponseTime > 0 
        and (self.metrics.totalResponseTime / self.metrics.apiCalls) 
        or 0
    
    return {
        sessionTime = sessionTime,
        eventsTracked = #self.events,
        keyVerifications = self.metrics.keyVerifications,
        successRate = self.metrics.keyVerifications > 0 
            and (self.metrics.successfulLogins / self.metrics.keyVerifications * 100) 
            or 0,
        cacheHitRate = (self.metrics.cacheHits + self.metrics.cacheMisses) > 0
            and (self.metrics.cacheHits / (self.metrics.cacheHits + self.metrics.cacheMisses) * 100)
            or 0,
        avgResponseTime = avgResponseTime
    }
end

-- ============================================
-- ADVANCED NOTIFICATIONS
-- ============================================

local NotificationSystem = {}

function NotificationSystem.success(title, message, duration)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "✓ " .. title,
        Text = message,
        Duration = duration or 5,
        Icon = "rbxassetid://6031094667"
    })
end

function NotificationSystem.error(title, message, duration)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "✗ " .. title,
        Text = message,
        Duration = duration or 5,
        Icon = "rbxassetid://6031094678"
    })
end

function NotificationSystem.warning(title, message, duration)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "⚠ " .. title,
        Text = message,
        Duration = duration or 5,
        Icon = "rbxassetid://6031094682"
    })
end

function NotificationSystem.info(title, message, duration)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "ℹ " .. title,
        Text = message,
        Duration = duration or 5,
        Icon = "rbxassetid://6031094670"
    })
end

-- ============================================
-- KEY SHARING DETECTION
-- ============================================

local KeySharingDetector = {
    ipHistory = {},
    hwidHistory = {},
    locationHistory = {}
}

function KeySharingDetector:checkSuspiciousActivity(key, hwid, metadata)
    local suspicious = false
    local reasons = {}
    
    -- Initialize key tracking
    if not self.hwidHistory[key] then
        self.hwidHistory[key] = {}
    end
    
    -- Check for multiple HWIDs in short time
    table.insert(self.hwidHistory[key], {
        hwid = hwid,
        timestamp = os.time(),
        location = metadata.location or "Unknown"
    })
    
    -- Count unique HWIDs in last hour
    local recentHWIDs = {}
    local oneHourAgo = os.time() - 3600
    
    for _, entry in ipairs(self.hwidHistory[key]) do
        if entry.timestamp > oneHourAgo then
            recentHWIDs[entry.hwid] = true
        end
    end
    
    local uniqueHWIDCount = 0
    for _ in pairs(recentHWIDs) do
        uniqueHWIDCount = uniqueHWIDCount + 1
    end
    
    -- Flag if more than 3 different HWIDs in 1 hour
    if uniqueHWIDCount > 3 then
        suspicious = true
        table.insert(reasons, string.format("Key used on %d devices in 1 hour", uniqueHWIDCount))
    end
    
    -- Check for rapid location changes
    if #self.hwidHistory[key] >= 2 then
        local lastEntry = self.hwidHistory[key][#self.hwidHistory[key] - 1]
        local currentEntry = self.hwidHistory[key][#self.hwidHistory[key]]
        
        if lastEntry.location ~= currentEntry.location and 
           (currentEntry.timestamp - lastEntry.timestamp) < 300 then
            suspicious = true
            table.insert(reasons, "Location changed in less than 5 minutes")
        end
    end
    
    return suspicious, reasons
end

-- ============================================
-- AUTO-UPDATE SYSTEM
-- ============================================

local AutoUpdate = {
    currentVersion = "2.0.0",
    updateCheckInterval = 3600, -- 1 hour
    lastUpdateCheck = 0
}

function AutoUpdate:checkForUpdates()
    local now = os.time()
    if now - self.lastUpdateCheck < self.updateCheckInterval then
        return false, "Too soon to check"
    end
    
    self.lastUpdateCheck = now
    
    local HttpService = game:GetService("HttpService")
    local success, response = pcall(function()
        return HttpService:GetAsync("https://api.github.com/repos/nguyenhoaikha/PawZHub/releases/latest")
    end)
    
    if success then
        local data = HttpService:JSONDecode(response)
        local latestVersion = data.tag_name:gsub("v", "")
        
        if latestVersion ~= self.currentVersion then
            return true, {
                version = latestVersion,
                releaseNotes = data.body,
                downloadUrl = "https://raw.githubusercontent.com/nguyenhoaikha/PawZHub/main/loader.lua"
            }
        end
    end
    
    return false, "Already up to date"
end

function AutoUpdate:promptUpdate(updateInfo)
    NotificationSystem.warning(
        "Update Available",
        string.format("Version %s is now available! Current: %s", updateInfo.version, self.currentVersion),
        10
    )
end

-- ============================================
-- PERFORMANCE MONITOR
-- ============================================

local PerformanceMonitor = {
    metrics = {
        fps = 0,
        ping = 0,
        memory = 0,
        cpuTime = 0
    },
    history = {}
}

function PerformanceMonitor:update()
    local Stats = game:GetService("Stats")
    
    self.metrics.fps = math.floor(1 / game:GetService("RunService").RenderStepped:Wait())
    self.metrics.ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    self.metrics.memory = Stats:GetTotalMemoryUsageMb()
    
    -- Store in history
    table.insert(self.history, {
        timestamp = os.time(),
        fps = self.metrics.fps,
        ping = self.metrics.ping,
        memory = self.metrics.memory
    })
    
    -- Keep last 60 entries (1 minute if updated every second)
    if #self.history > 60 then
        table.remove(self.history, 1)
    end
end

function PerformanceMonitor:getAverages()
    if #self.history == 0 then
        return self.metrics
    end
    
    local totalFPS = 0
    local totalPing = 0
    local totalMemory = 0
    
    for _, entry in ipairs(self.history) do
        totalFPS = totalFPS + entry.fps
        totalPing = totalPing + entry.ping
        totalMemory = totalMemory + entry.memory
    end
    
    local count = #self.history
    
    return {
        fps = math.floor(totalFPS / count),
        ping = math.floor(totalPing / count),
        memory = math.floor(totalMemory / count)
    }
}

-- ============================================
-- WHITELIST SYSTEM
-- ============================================

local WhitelistSystem = {
    whitelistedUsers = {},
    whitelistedGroups = {},
    whitelistedGamepasses = {}
}

function WhitelistSystem:checkWhitelist(player)
    -- Check user whitelist
    if table.find(self.whitelistedUsers, player.UserId) then
        return true, "User whitelisted"
    end
    
    -- Check group whitelist
    for _, groupId in ipairs(self.whitelistedGroups) do
        local success, inGroup = pcall(function()
            return player:IsInGroup(groupId)
        end)
        if success and inGroup then
            return true, "Group member"
        end
    end
    
    -- Check gamepass whitelist
    local MarketplaceService = game:GetService("MarketplaceService")
    for _, gamepassId in ipairs(self.whitelistedGamepasses) do
        local success, hasPass = pcall(function()
            return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId)
        end)
        if success and hasPass then
            return true, "Gamepass owner"
        end
    end
    
    return false, "Not whitelisted"
end

-- ============================================
-- CRASH PROTECTION
-- ============================================

local CrashProtection = {
    enabled = true,
    maxMemoryMB = 1024,
    maxScriptTime = 10
}

function CrashProtection:monitor()
    if not self.enabled then return end
    
    spawn(function()
        while self.enabled do
            -- Check memory usage
            local Stats = game:GetService("Stats")
            local memoryUsage = Stats:GetTotalMemoryUsageMb()
            
            if memoryUsage > self.maxMemoryMB then
                warn("[CrashProtection] High memory usage:", memoryUsage, "MB")
                
                -- Clear caches
                _G.PawZHub_Cache = {}
                collectgarbage("collect")
                
                NotificationSystem.warning(
                    "Memory Warning",
                    "High memory usage detected. Cache cleared.",
                    5
                )
            end
            
            wait(30) -- Check every 30 seconds
        end
    end)
end

-- ============================================
-- ANTI-AFK SYSTEM
-- ============================================

local AntiAFK = {
    enabled = false,
    lastActivityTime = os.time()
}

function AntiAFK:enable()
    self.enabled = true
    self.lastActivityTime = os.time()
    
    local VirtualUser = game:GetService("VirtualUser")
    
    game:GetService("Players").LocalPlayer.Idled:Connect(function()
        if self.enabled then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
            self.lastActivityTime = os.time()
            print("[AntiAFK] Prevented kick")
        end
    end)
    
    NotificationSystem.success("Anti-AFK", "Anti-AFK enabled", 3)
end

function AntiAFK:disable()
    self.enabled = false
    NotificationSystem.info("Anti-AFK", "Anti-AFK disabled", 3)
end

-- ============================================
-- CONFIG SAVER
-- ============================================

local ConfigSaver = {
    configFolder = "PawZHub_Configs"
}

function ConfigSaver:save(configName, data)
    if not isfolder(self.configFolder) then
        makefolder(self.configFolder)
    end
    
    local HttpService = game:GetService("HttpService")
    local json = HttpService:JSONEncode(data)
    local filePath = self.configFolder .. "/" .. configName .. ".json"
    
    writefile(filePath, json)
    
    NotificationSystem.success("Config Saved", "Configuration saved: " .. configName, 3)
end

function ConfigSaver:load(configName)
    local filePath = self.configFolder .. "/" .. configName .. ".json"
    
    if not isfile(filePath) then
        return nil, "Config not found"
    end
    
    local HttpService = game:GetService("HttpService")
    local json = readfile(filePath)
    local data = HttpService:JSONDecode(json)
    
    NotificationSystem.success("Config Loaded", "Configuration loaded: " .. configName, 3)
    
    return data
end

function ConfigSaver:list()
    if not isfolder(self.configFolder) then
        return {}
    end
    
    local configs = {}
    local files = listfiles(self.configFolder)
    
    for _, file in ipairs(files) do
        if file:match("%.json$") then
            local name = file:match("([^/\\]+)%.json$")
            table.insert(configs, name)
        end
    end
    
    return configs
end

function ConfigSaver:delete(configName)
    local filePath = self.configFolder .. "/" .. configName .. ".json"
    
    if isfile(filePath) then
        delfile(filePath)
        NotificationSystem.info("Config Deleted", "Configuration deleted: " .. configName, 3)
        return true
    end
    
    return false, "Config not found"
end

-- ============================================
-- EXPORT MODULE
-- ============================================

AdvancedFeatures.Analytics = Analytics
AdvancedFeatures.Notifications = NotificationSystem
AdvancedFeatures.KeySharingDetector = KeySharingDetector
AdvancedFeatures.AutoUpdate = AutoUpdate
AdvancedFeatures.PerformanceMonitor = PerformanceMonitor
AdvancedFeatures.WhitelistSystem = WhitelistSystem
AdvancedFeatures.CrashProtection = CrashProtection
AdvancedFeatures.AntiAFK = AntiAFK
AdvancedFeatures.ConfigSaver = ConfigSaver

return AdvancedFeatures

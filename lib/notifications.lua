--[[
    ========================================================
    PawZHub  —  Universal Notifications Library  v1.0.0
    ========================================================
    Standalone toast notification system used by all PawZHub
    libraries and game scripts.

    Features:
      • Toast notifications (ok, warn, error, info)
      • Queue system (auto-stacks multiple toasts)
      • Auto-dismiss after duration
      • Progress bar animation
      • Theme-aware colors
      • Can integrate with ui.lua Hub or work standalone
      • Global access via _G.PawZHub_Notify

    Usage:
        local Toast = loadstring(game:HttpGet(URL))()
        Toast.Init()  -- auto-creates ScreenGui if needed

        Toast.Show("Welcome!", "ok")
        Toast.Show("Low health!", "warn", 5)
        Toast.Error("Failed to load", 4)
        Toast.Success("Key verified")
        Toast.Info("Server hopping...")

        -- Cleanup:
        Toast.Unload()

    Integration with ui.lua:
        local Hub = UI.New(...)
        Hub:RegisterAsGlobal()  -- sets _G.PawZHub_Toast = Hub
        -- Now Toast.Show() will route to Hub:Notify() automatically
]]

-- ========================================================
-- SERVICES
-- ========================================================
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local RunService       = game:GetService("RunService")

local Player           = Players.LocalPlayer
local PlayerGui        = Player:WaitForChild("PlayerGui", 10)

-- ========================================================
-- STATE
-- ========================================================
local Toast = {}
Toast.__version = "1.0.0"
Toast.__type    = "PawZHub.Notifications"

local State = {
    initialized = false,
    unloaded    = false,
    sg          = nil,           -- ScreenGui (if standalone)
    container   = nil,           -- Frame holding all toasts
    queue       = {},            -- active toast frames
    maxToasts   = 5,             -- max visible at once
    theme       = "Dark",        -- default theme
}

-- ========================================================
-- THEMES (sync with ui.lua)
-- ========================================================
local Themes = {
    Dark = {
        Surface   = Color3.fromRGB(26, 26, 32),
        Text      = Color3.fromRGB(220, 220, 240),
        Shadow    = Color3.fromRGB(0, 0, 0),
        ok        = Color3.fromRGB(80, 200, 120),
        warn      = Color3.fromRGB(255, 180, 50),
        error     = Color3.fromRGB(220, 60, 60),
        info      = Color3.fromRGB(99, 102, 241),
    },
    Midnight = {
        Surface   = Color3.fromRGB(16, 16, 32),
        Text      = Color3.fromRGB(200, 200, 230),
        Shadow    = Color3.fromRGB(0, 0, 0),
        ok        = Color3.fromRGB(80, 200, 120),
        warn      = Color3.fromRGB(255, 180, 50),
        error     = Color3.fromRGB(220, 60, 60),
        info      = Color3.fromRGB(139, 92, 246),
    },
    Cyber = {
        Surface   = Color3.fromRGB(16, 22, 32),
        Text      = Color3.fromRGB(180, 220, 240),
        Shadow    = Color3.fromRGB(0, 0, 0),
        ok        = Color3.fromRGB(80, 200, 120),
        warn      = Color3.fromRGB(255, 180, 50),
        error     = Color3.fromRGB(255, 60, 60),
        info      = Color3.fromRGB(0, 212, 255),
    },
    Soft = {
        Surface   = Color3.fromRGB(255, 255, 255),
        Text      = Color3.fromRGB(40, 40, 70),
        Shadow    = Color3.fromRGB(150, 150, 180),
        ok        = Color3.fromRGB(80, 200, 120),
        warn      = Color3.fromRGB(255, 180, 50),
        error     = Color3.fromRGB(220, 60, 60),
        info      = Color3.fromRGB(99, 102, 241),
    },
}

-- ========================================================
-- HELPERS
-- ========================================================
local function safe(fn, default)
    local ok, v = pcall(fn)
    return ok and v or default
end

local function tween(inst, info, props)
    pcall(function()
        TweenService:Create(inst, info, props):Play()
    end)
end

local MED = TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 6)
    c.Parent = parent
    return c
end

local function listLayout(parent, dir, spacing)
    local l = Instance.new("UIListLayout")
    l.FillDirection = dir or Enum.FillDirection.Vertical
    l.SortOrder     = Enum.SortOrder.LayoutOrder
    l.Padding       = UDim.new(0, spacing or 6)
    l.Parent        = parent
    return l
end

-- ========================================================
-- INIT (standalone mode)
-- ========================================================
function Toast.Init(theme)
    if State.initialized then return Toast end
    if State.unloaded then return Toast end

    State.theme = theme or "Dark"

    -- Check if ui.lua Hub already registered globally
    if type(_G.PawZHub_Toast) == "table" and type(_G.PawZHub_Toast.Notify) == "function" then
        -- Delegate mode: ui.lua Hub handles rendering
        State.initialized = true
        return Toast
    end

    -- Standalone mode: create our own ScreenGui
    local sg = Instance.new("ScreenGui")
    sg.Name              = "PawZHub_Notifications"
    sg.ResetOnSpawn      = false
    sg.ZIndexBehavior    = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder      = 150  -- above main UI (100)
    sg.IgnoreGuiInset    = true
    sg.Parent            = PlayerGui
    State.sg = sg

    -- Container frame (top-right corner)
    local container = Instance.new("Frame")
    container.Name              = "ToastContainer"
    container.Size              = UDim2.new(0, 280, 0, 400)
    container.Position          = UDim2.new(1, -300, 0, 20)
    container.BackgroundTransparency = 1
    container.BorderSizePixel   = 0
    container.ZIndex            = 20
    container.ClipsDescendants  = false
    container.Parent            = sg

    listLayout(container, Enum.FillDirection.Vertical, 8)
    State.container = container

    State.initialized = true

    -- Register global access
    _G.PawZHub_Notify = function(msg, kind, dur)
        Toast.Show(msg, kind, dur)
    end
    _G.PawZHub_Toast = Toast

    return Toast
end

-- ========================================================
-- SHOW (main entry point)
-- ========================================================
--[[
    Toast.Show(message, kind, duration)
    kind = "ok" | "warn" | "error" | "info"
    duration (seconds) defaults to 3.5
]]
function Toast.Show(message, kind, duration)
    if State.unloaded then return end

    -- If ui.lua Hub is active, delegate to it
    if type(_G.PawZHub_Toast) == "table"
       and _G.PawZHub_Toast ~= Toast
       and type(_G.PawZHub_Toast.Notify) == "function" then
        pcall(_G.PawZHub_Toast.Notify, _G.PawZHub_Toast, message, kind, duration)
        return
    end

    -- Standalone mode
    if not State.initialized then
        Toast.Init()
    end
    if not State.container or not State.container.Parent then return end

    kind     = kind or "ok"
    duration = tonumber(duration) or 3.5
    message  = tostring(message or "Notification")

    local T = Themes[State.theme] or Themes.Dark
    local c = T[kind] or T.info

    -- Enforce max visible toasts
    while #State.queue >= State.maxToasts do
        local oldest = table.remove(State.queue, 1)
        if oldest and oldest.Parent then
            pcall(function() oldest:Destroy() end)
        end
    end

    -- Create toast frame
    local toast = Instance.new("Frame")
    toast.Name              = "Toast_" .. tostring(tick())
    toast.Size              = UDim2.new(1, 0, 0, 56)
    toast.BackgroundColor3  = T.Surface
    toast.BorderSizePixel   = 0
    toast.BackgroundTransparency = 1  -- animate in
    toast.LayoutOrder       = #State.queue + 1
    toast.Parent            = State.container
    corner(toast, 8)

    table.insert(State.queue, toast)

    -- Left accent bar
    local bar = Instance.new("Frame")
    bar.Name              = "AccentBar"
    bar.Size              = UDim2.new(0, 4, 1, 0)
    bar.BackgroundColor3  = c
    bar.BorderSizePixel   = 0
    bar.Parent            = toast
    corner(bar, 2)

    -- Message text
    local msgLbl = Instance.new("TextLabel")
    msgLbl.BackgroundTransparency = 1
    msgLbl.Position        = UDim2.new(0, 14, 0, 6)
    msgLbl.Size            = UDim2.new(1, -20, 1, -12)
    msgLbl.Text            = message
    msgLbl.TextSize        = 13
    msgLbl.Font            = Enum.Font.GothamBold
    msgLbl.TextColor3      = T.Text
    msgLbl.TextXAlignment  = Enum.TextXAlignment.Left
    msgLbl.TextYAlignment  = Enum.TextYAlignment.Top
    msgLbl.TextWrapped     = true
    msgLbl.Parent          = toast

    -- Progress bar (bottom edge)
    local prog = Instance.new("Frame")
    prog.Name              = "ProgressBar"
    prog.Size              = UDim2.new(1, 0, 0, 3)
    prog.Position          = UDim2.new(0, 0, 1, -3)
    prog.BackgroundColor3  = c
    prog.BorderSizePixel   = 0
    prog.Parent            = toast

    -- Animate in
    tween(toast, MED, { BackgroundTransparency = 0 })

    -- Progress bar countdown
    TweenService:Create(prog, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        Size = UDim2.new(0, 0, 0, 3)
    }):Play()

    -- Auto-dismiss
    task.delay(duration, function()
        if toast and toast.Parent then
            tween(toast, MED, { BackgroundTransparency = 1 })
            task.delay(0.25, function()
                if toast and toast.Parent then
                    pcall(function() toast:Destroy() end)
                end
                -- Remove from queue
                for i, t in ipairs(State.queue) do
                    if t == toast then
                        table.remove(State.queue, i)
                        break
                    end
                end
            end)
        end
    end)
end

-- ========================================================
-- CONVENIENCE WRAPPERS
-- ========================================================
function Toast.Success(message, duration)
    Toast.Show(message, "ok", duration)
end

function Toast.Error(message, duration)
    Toast.Show(message, "error", duration)
end

function Toast.Warning(message, duration)
    Toast.Show(message, "warn", duration)
end

function Toast.Info(message, duration)
    Toast.Show(message, "info", duration)
end

-- ========================================================
-- CLEAR ALL
-- ========================================================
function Toast.Clear()
    for i = #State.queue, 1, -1 do
        local t = State.queue[i]
        if t and t.Parent then
            pcall(function() t:Destroy() end)
        end
        State.queue[i] = nil
    end
end

-- ========================================================
-- UNLOAD
-- ========================================================
function Toast.Unload()
    if State.unloaded then return end
    State.unloaded = true

    Toast.Clear()

    if State.sg and State.sg.Parent then
        pcall(function() State.sg:Destroy() end)
    end

    State.sg        = nil
    State.container = nil

    -- Clear global if we own it
    if _G.PawZHub_Toast == Toast then
        _G.PawZHub_Toast  = nil
        _G.PawZHub_Notify = nil
    end
end

-- ========================================================
-- THEME SETTER
-- ========================================================
function Toast.SetTheme(theme)
    if Themes[theme] then
        State.theme = theme
    end
end

-- ========================================================
-- DEBUG
-- ========================================================
function Toast.Dump()
    return {
        version     = Toast.__version,
        initialized = State.initialized,
        unloaded    = State.unloaded,
        theme       = State.theme,
        activeToasts= #State.queue,
        maxToasts   = State.maxToasts,
        delegated   = (_G.PawZHub_Toast ~= Toast and _G.PawZHub_Toast ~= nil),
    }
end

return Toast

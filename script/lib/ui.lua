--[[
    ========================================================
    PawZHub  —  Universal Hub UI Library  v1.0.0
    ========================================================
    Provides a fully self-contained, draggable, tabbed hub
    window used by all 28 supported games.

    Capabilities:
      • Draggable window (mouse + touch)
      • Tabs with left-side nav icons
      • Section labels
      • Toggles (on/off with animated dot)
      • Sliders (draggable, live label)
      • Buttons (primary + destructive variants)
      • Dropdowns (click-to-open, close on outside click)
      • Keybind display badge
      • Notifications overlay (integrates with notifications.lua)
      • Theme system (Dark / Midnight / Cyber / Soft)
      • Minimise / close buttons
      • Safe unload (removes ScreenGui entirely)

    Usage:
        local UI = loadstring(game:HttpGet(URL))()
        local Hub = UI.New({
            title  = "PawZHub",
            game   = "Blox Fruits",
            key    = "PZ-XXXXXX",     -- optional, shown in footer
            theme  = "Dark",          -- optional
            toggle = Enum.KeyCode.RightShift,   -- optional toggle keybind
        })

        local tab = Hub:Tab("Movement")
        tab:Toggle("Speed Hack", false, function(v) ... end)
        tab:Slider("Walk Speed", 16, 200, 16, function(v) ... end)
        tab:Button("Teleport to Spawn", function() ... end)
        tab:Dropdown("Fly Mode", {"CFrame","Velocity","BV"}, "CFrame", function(v) ... end)
        tab:Section("Waypoints")

        Hub:Notify("Ready!", "ok")

        -- Cleanup:
        Hub:Destroy()
]]

-- ========================================================
-- SERVICES
-- ========================================================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

local Player           = Players.LocalPlayer
local PlayerGui        = Player:WaitForChild("PlayerGui", 10)

-- ========================================================
-- THEMES
-- ========================================================
local Themes = {
    Dark = {
        Background   = Color3.fromRGB(18, 18, 22),
        Surface      = Color3.fromRGB(26, 26, 32),
        SurfaceHover = Color3.fromRGB(34, 34, 42),
        Sidebar      = Color3.fromRGB(14, 14, 18),
        TabActive    = Color3.fromRGB(99, 102, 241),
        TabInactive  = Color3.fromRGB(14, 14, 18),
        TabText      = Color3.fromRGB(160, 160, 200),
        TabTextActive= Color3.fromRGB(255, 255, 255),
        Accent       = Color3.fromRGB(99, 102, 241),
        AccentHover  = Color3.fromRGB(120, 124, 255),
        Text         = Color3.fromRGB(220, 220, 240),
        TextMuted    = Color3.fromRGB(110, 110, 140),
        ToggleOn     = Color3.fromRGB(99, 102, 241),
        ToggleOff    = Color3.fromRGB(50, 50, 65),
        SliderBar    = Color3.fromRGB(50, 50, 65),
        SliderFill   = Color3.fromRGB(99, 102, 241),
        SliderKnob   = Color3.fromRGB(255, 255, 255),
        Border       = Color3.fromRGB(40, 40, 55),
        Shadow       = Color3.fromRGB(0, 0, 0),
        TitleBar     = Color3.fromRGB(22, 22, 28),
        TitleText    = Color3.fromRGB(255, 255, 255),
        Footer       = Color3.fromRGB(14, 14, 18),
        BtnDestructive = Color3.fromRGB(220, 50, 50),
        Section      = Color3.fromRGB(99, 102, 241),
        DropBg       = Color3.fromRGB(26, 26, 36),
    },
    Midnight = {
        Background   = Color3.fromRGB(8, 8, 20),
        Surface      = Color3.fromRGB(16, 16, 32),
        SurfaceHover = Color3.fromRGB(24, 24, 44),
        Sidebar      = Color3.fromRGB(6, 6, 16),
        TabActive    = Color3.fromRGB(139, 92, 246),
        TabInactive  = Color3.fromRGB(6, 6, 16),
        TabText      = Color3.fromRGB(130, 130, 180),
        TabTextActive= Color3.fromRGB(255, 255, 255),
        Accent       = Color3.fromRGB(139, 92, 246),
        AccentHover  = Color3.fromRGB(160, 115, 255),
        Text         = Color3.fromRGB(200, 200, 230),
        TextMuted    = Color3.fromRGB(90, 90, 130),
        ToggleOn     = Color3.fromRGB(139, 92, 246),
        ToggleOff    = Color3.fromRGB(40, 40, 65),
        SliderBar    = Color3.fromRGB(40, 40, 65),
        SliderFill   = Color3.fromRGB(139, 92, 246),
        SliderKnob   = Color3.fromRGB(255, 255, 255),
        Border       = Color3.fromRGB(30, 30, 55),
        Shadow       = Color3.fromRGB(0, 0, 0),
        TitleBar     = Color3.fromRGB(12, 12, 24),
        TitleText    = Color3.fromRGB(255, 255, 255),
        Footer       = Color3.fromRGB(6, 6, 16),
        BtnDestructive = Color3.fromRGB(220, 50, 50),
        Section      = Color3.fromRGB(139, 92, 246),
        DropBg       = Color3.fromRGB(16, 16, 32),
    },
    Cyber = {
        Background   = Color3.fromRGB(10, 14, 20),
        Surface      = Color3.fromRGB(16, 22, 32),
        SurfaceHover = Color3.fromRGB(22, 30, 44),
        Sidebar      = Color3.fromRGB(8, 12, 18),
        TabActive    = Color3.fromRGB(0, 212, 255),
        TabInactive  = Color3.fromRGB(8, 12, 18),
        TabText      = Color3.fromRGB(100, 140, 160),
        TabTextActive= Color3.fromRGB(0, 212, 255),
        Accent       = Color3.fromRGB(0, 212, 255),
        AccentHover  = Color3.fromRGB(60, 230, 255),
        Text         = Color3.fromRGB(180, 220, 240),
        TextMuted    = Color3.fromRGB(80, 120, 140),
        ToggleOn     = Color3.fromRGB(0, 212, 255),
        ToggleOff    = Color3.fromRGB(40, 55, 65),
        SliderBar    = Color3.fromRGB(30, 44, 55),
        SliderFill   = Color3.fromRGB(0, 212, 255),
        SliderKnob   = Color3.fromRGB(255, 255, 255),
        Border       = Color3.fromRGB(30, 50, 65),
        Shadow       = Color3.fromRGB(0, 0, 0),
        TitleBar     = Color3.fromRGB(12, 18, 26),
        TitleText    = Color3.fromRGB(0, 212, 255),
        Footer       = Color3.fromRGB(8, 12, 18),
        BtnDestructive = Color3.fromRGB(255, 60, 60),
        Section      = Color3.fromRGB(0, 212, 255),
        DropBg       = Color3.fromRGB(16, 22, 32),
    },
    Soft = {
        Background   = Color3.fromRGB(240, 240, 250),
        Surface      = Color3.fromRGB(255, 255, 255),
        SurfaceHover = Color3.fromRGB(245, 245, 255),
        Sidebar      = Color3.fromRGB(230, 230, 245),
        TabActive    = Color3.fromRGB(99, 102, 241),
        TabInactive  = Color3.fromRGB(230, 230, 245),
        TabText      = Color3.fromRGB(100, 100, 140),
        TabTextActive= Color3.fromRGB(255, 255, 255),
        Accent       = Color3.fromRGB(99, 102, 241),
        AccentHover  = Color3.fromRGB(120, 124, 255),
        Text         = Color3.fromRGB(40, 40, 70),
        TextMuted    = Color3.fromRGB(130, 130, 160),
        ToggleOn     = Color3.fromRGB(99, 102, 241),
        ToggleOff    = Color3.fromRGB(200, 200, 220),
        SliderBar    = Color3.fromRGB(200, 200, 220),
        SliderFill   = Color3.fromRGB(99, 102, 241),
        SliderKnob   = Color3.fromRGB(99, 102, 241),
        Border       = Color3.fromRGB(210, 210, 230),
        Shadow       = Color3.fromRGB(150, 150, 180),
        TitleBar     = Color3.fromRGB(99, 102, 241),
        TitleText    = Color3.fromRGB(255, 255, 255),
        Footer       = Color3.fromRGB(230, 230, 245),
        BtnDestructive = Color3.fromRGB(220, 50, 50),
        Section      = Color3.fromRGB(99, 102, 241),
        DropBg       = Color3.fromRGB(255, 255, 255),
    },
}

-- ========================================================
-- HELPERS
-- ========================================================
local function safe(fn, default)
    local ok, v = pcall(fn)
    return ok and v or default
end

local function disconnect(conn)
    if conn and type(conn.Disconnect) == "function" then
        pcall(function() conn:Disconnect() end)
    end
end

local function tween(inst, info, props)
    pcall(function()
        TweenService:Create(inst, info, props):Play()
    end)
end

local FAST = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local MED  = TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 6)
    c.Parent = parent
    return c
end

local function padding(parent, px)
    local p = Instance.new("UIPadding")
    p.PaddingLeft   = UDim.new(0, px)
    p.PaddingRight  = UDim.new(0, px)
    p.PaddingTop    = UDim.new(0, px)
    p.PaddingBottom = UDim.new(0, px)
    p.Parent = parent
    return p
end

local function listLayout(parent, dir, spacing, alignX, alignY)
    local l = Instance.new("UIListLayout")
    l.FillDirection = dir or Enum.FillDirection.Vertical
    l.SortOrder     = Enum.SortOrder.LayoutOrder
    l.Padding       = UDim.new(0, spacing or 4)
    if alignX then l.HorizontalAlignment = alignX end
    if alignY then l.VerticalAlignment   = alignY end
    l.Parent = parent
    return l
end

local function newLabel(parent, text, size, weight, color, richText)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text     = text
    l.TextSize = size or 14
    l.Font     = Enum.Font.GothamSemiBold
    if weight then l.Font = weight end
    l.TextColor3   = color or Color3.fromRGB(220, 220, 240)
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.RichText   = richText or false
    l.Parent     = parent
    return l
end

-- ========================================================
-- HUB CLASS
-- ========================================================
local Hub = {}
Hub.__index = Hub

-- All active Hub instances (for singleton enforcement)
local _activeHubs = {}

-- --------------------------------------------------------
-- Hub.New(options)
-- --------------------------------------------------------
function Hub.New(options)
    options = options or {}
    local self = setmetatable({}, Hub)

    self._destroyed  = false
    self._visible    = true
    self._conns      = {}
    self._tabs       = {}
    self._activeTab  = nil
    self._dropdowns  = {}
    self._notifQueue = {}

    local T = Themes[options.theme] or Themes.Dark
    self._theme = T

    local W = tonumber(options.width)  or 520
    local H = tonumber(options.height) or 360

    -- ScreenGui
    local sg = Instance.new("ScreenGui")
    sg.Name              = "PawZHub_UI"
    sg.ResetOnSpawn      = false
    sg.ZIndexBehavior    = Enum.ZIndexBehavior.Sibling
    sg.DisplayOrder      = 100
    sg.IgnoreGuiInset    = true
    sg.Parent            = PlayerGui
    self._sg = sg

    -- Main Window Frame
    local win = Instance.new("Frame")
    win.Name              = "Window"
    win.Size              = UDim2.new(0, W, 0, H)
    win.Position          = UDim2.new(0.5, -W/2, 0.5, -H/2)
    win.BackgroundColor3  = T.Background
    win.BorderSizePixel   = 0
    win.ClipsDescendants  = true
    win.Parent            = sg
    corner(win, 10)

    -- Drop shadow
    local shadow = Instance.new("ImageLabel")
    shadow.Name              = "Shadow"
    shadow.Size              = UDim2.new(1, 30, 1, 30)
    shadow.Position          = UDim2.new(0, -15, 0, -15)
    shadow.BackgroundTransparency = 1
    shadow.Image             = "rbxassetid://5554236805"
    shadow.ImageColor3       = T.Shadow
    shadow.ImageTransparency = 0.6
    shadow.SliceCenter       = Rect.new(23, 23, 277, 277)
    shadow.ScaleType         = Enum.ScaleType.Slice
    shadow.ZIndex            = -1
    shadow.Parent            = win
    self._win = win

    -- Title Bar
    local titleBar = Instance.new("Frame")
    titleBar.Name             = "TitleBar"
    titleBar.Size             = UDim2.new(1, 0, 0, 38)
    titleBar.BackgroundColor3 = T.TitleBar
    titleBar.BorderSizePixel  = 0
    titleBar.ZIndex           = 2
    titleBar.Parent           = win
    corner(titleBar, 0)
    local tbTop = Instance.new("UICorner")
    tbTop.CornerRadius = UDim.new(0, 10)
    tbTop.Parent = titleBar
    local tbFill = Instance.new("Frame")
    tbFill.Size              = UDim2.new(1, 0, 0, 10)
    tbFill.Position          = UDim2.new(0, 0, 1, -10)
    tbFill.BackgroundColor3  = T.TitleBar
    tbFill.BorderSizePixel   = 0
    tbFill.ZIndex            = 2
    tbFill.Parent            = titleBar
    self._titleBar = titleBar

    -- Accent bar
    local accent = Instance.new("Frame")
    accent.Size             = UDim2.new(0, 4, 1, 0)
    accent.BackgroundColor3 = T.Accent
    accent.BorderSizePixel  = 0
    accent.ZIndex           = 3
    accent.Parent           = titleBar

    -- Title text
    local titleLbl = Instance.new("TextLabel")
    titleLbl.Name              = "Title"
    titleLbl.Position          = UDim2.new(0, 14, 0, 0)
    titleLbl.Size              = UDim2.new(1, -100, 1, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text              = (options.title or "PawZHub")
                                  .. (options.game and ("  ·  " .. options.game) or "")
    titleLbl.TextSize          = 14
    titleLbl.Font              = Enum.Font.GothamBold
    titleLbl.TextColor3        = T.TitleText
    titleLbl.TextXAlignment    = Enum.TextXAlignment.Left
    titleLbl.ZIndex            = 3
    titleLbl.Parent            = titleBar

    -- Version badge
    local verLbl = Instance.new("TextLabel")
    verLbl.Name              = "Version"
    verLbl.Size              = UDim2.new(0, 60, 1, 0)
    verLbl.Position          = UDim2.new(1, -130, 0, 0)
    verLbl.BackgroundTransparency = 1
    verLbl.Text              = "v1.0.0"
    verLbl.TextSize          = 11
    verLbl.Font              = Enum.Font.Gotham
    verLbl.TextColor3        = T.TextMuted
    verLbl.TextXAlignment    = Enum.TextXAlignment.Right
    verLbl.ZIndex            = 3
    verLbl.Parent            = titleBar

    -- Minimise button
    local minBtn = Instance.new("TextButton")
    minBtn.Name              = "MinBtn"
    minBtn.Size              = UDim2.new(0, 28, 0, 22)
    minBtn.Position          = UDim2.new(1, -62, 0.5, -11)
    minBtn.BackgroundColor3  = T.Surface
    minBtn.Text              = "–"
    minBtn.TextSize          = 16
    minBtn.Font              = Enum.Font.GothamBold
    minBtn.TextColor3        = T.TextMuted
    minBtn.BorderSizePixel   = 0
    minBtn.ZIndex            = 4
    minBtn.Parent            = titleBar
    corner(minBtn, 5)

    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name            = "CloseBtn"
    closeBtn.Size            = UDim2.new(0, 28, 0, 22)
    closeBtn.Position        = UDim2.new(1, -30, 0.5, -11)
    closeBtn.BackgroundColor3= T.BtnDestructive
    closeBtn.Text            = "×"
    closeBtn.TextSize        = 18
    closeBtn.Font            = Enum.Font.GothamBold
    closeBtn.TextColor3      = Color3.fromRGB(255, 255, 255)
    closeBtn.BorderSizePixel = 0
    closeBtn.ZIndex          = 4
    closeBtn.Parent          = titleBar
    corner(closeBtn, 5)

    self._minBtn   = minBtn
    self._closeBtn = closeBtn
    self._minimised = false

    -- Body (sidebar + content)
    local body = Instance.new("Frame")
    body.Name             = "Body"
    body.Position         = UDim2.new(0, 0, 0, 38)
    body.Size             = UDim2.new(1, 0, 1, -38)
    body.BackgroundTransparency = 1
    body.BorderSizePixel  = 0
    body.ClipsDescendants = false
    body.Parent           = win

    -- Sidebar
    local sidebar = Instance.new("Frame")
    sidebar.Name            = "Sidebar"
    sidebar.Size            = UDim2.new(0, 110, 1, 0)
    sidebar.BackgroundColor3= T.Sidebar
    sidebar.BorderSizePixel = 0
    sidebar.ClipsDescendants= false
    sidebar.Parent          = body
    local sideList = listLayout(sidebar, Enum.FillDirection.Vertical, 2)
    sideList.VerticalAlignment = Enum.VerticalAlignment.Top
    padding(sidebar, 6)
    self._sidebar   = sidebar
    self._sideList  = sideList

    -- Content area
    local content = Instance.new("Frame")
    content.Name            = "Content"
    content.Position        = UDim2.new(0, 110, 0, 0)
    content.Size            = UDim2.new(1, -110, 1, -30)
    content.BackgroundColor3= T.Background
    content.BorderSizePixel = 0
    content.ClipsDescendants= true
    content.Parent          = body
    self._content = content

    -- Footer
    local footer = Instance.new("Frame")
    footer.Name             = "Footer"
    footer.Position         = UDim2.new(0, 110, 1, -30)
    footer.Size             = UDim2.new(1, -110, 0, 30)
    footer.BackgroundColor3 = T.Footer
    footer.BorderSizePixel  = 0
    footer.Parent           = body
    local footerLbl = Instance.new("TextLabel")
    footerLbl.BackgroundTransparency = 1
    footerLbl.Size          = UDim2.new(1, -12, 1, 0)
    footerLbl.Position      = UDim2.new(0, 6, 0, 0)
    footerLbl.Text          = (options.key and ("Key: " .. options.key .. "  ·  ") or "")
                               .. "PawZHub  ·  All rights reserved"
    footerLbl.TextSize      = 10
    footerLbl.Font          = Enum.Font.Gotham
    footerLbl.TextColor3    = T.TextMuted
    footerLbl.TextXAlignment= Enum.TextXAlignment.Left
    footerLbl.Parent        = footer

    -- Notification overlay
    local notifContainer = Instance.new("Frame")
    notifContainer.Name              = "Notifications"
    notifContainer.Size              = UDim2.new(0, 260, 0, 200)
    notifContainer.Position          = UDim2.new(1, -280, 0, 50)
    notifContainer.BackgroundTransparency = 1
    notifContainer.BorderSizePixel   = 0
    notifContainer.ZIndex            = 20
    notifContainer.ClipsDescendants  = false
    notifContainer.Parent            = sg
    listLayout(notifContainer, Enum.FillDirection.Vertical, 6)
    self._notifContainer = notifContainer

    -- Drag logic
    self:_initDrag(titleBar, win)

    -- Button wiring
    table.insert(self._conns, minBtn.MouseButton1Click:Connect(function()
        self:_toggleMinimise()
    end))
    table.insert(self._conns, closeBtn.MouseButton1Click:Connect(function()
        self:Destroy()
    end))

    -- Toggle keybind
    if options.toggle then
        local kc = options.toggle
        table.insert(self._conns, UserInputService.InputBegan:Connect(function(input, gpe)
            if gpe then return end
            if input.KeyCode == kc then
                self:_toggleVisible()
            end
        end))
    end

    -- Outside-click to close dropdowns
    table.insert(self._conns, UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            self:_closeAllDropdowns()
        end
    end))

    table.insert(_activeHubs, self)
    return self
end

-- ========================================================
-- DRAG
-- ========================================================
function Hub:_initDrag(handle, win)
    local dragging = false
    local dragStart, startPos

    local function beginDrag(input)
        dragging  = true
        dragStart = input.Position
        startPos  = win.Position
    end

    local function updateDrag(input)
        if not dragging then return end
        local delta = input.Position - dragStart
        win.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end

    local function endDrag()
        dragging = false
    end

    table.insert(self._conns, handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            beginDrag(input)
        end
    end))
    table.insert(self._conns, UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            updateDrag(input)
        end
    end))
    table.insert(self._conns, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            endDrag()
        end
    end))
end

-- ========================================================
-- MINIMISE / VISIBILITY
-- ========================================================
function Hub:_toggleMinimise()
    if self._destroyed then return end
    self._minimised = not self._minimised
    local body = self._win:FindFirstChild("Body")
    if body then
        body.Visible = not self._minimised
    end
    tween(self._win, MED, {
        Size = self._minimised
            and UDim2.new(0, self._win.AbsoluteSize.X, 0, 38)
            or  UDim2.new(0, self._win.AbsoluteSize.X, 0, 360)
    })
end

function Hub:_toggleVisible()
    if self._destroyed then return end
    self._visible = not self._visible
    tween(self._win, FAST, {
        GroupTransparency = self._visible and 0 or 1
    })
    self._win.Active = self._visible
end

-- ========================================================
-- TABS
-- ========================================================
function Hub:Tab(name)
    if self._destroyed then return self:_dummyTab() end

    local T = self._theme
    local idx = #self._tabs + 1

    -- Sidebar button
    local btn = Instance.new("TextButton")
    btn.Name             = "Tab_" .. name
    btn.Size             = UDim2.new(1, 0, 0, 32)
    btn.BackgroundColor3 = T.TabInactive
    btn.BorderSizePixel  = 0
    btn.Text             = name
    btn.TextSize         = 12
    btn.Font             = Enum.Font.GothamSemiBold
    btn.TextColor3       = T.TabText
    btn.LayoutOrder      = idx
    btn.Parent           = self._sidebar
    corner(btn, 6)

    -- Active indicator bar
    local indicator = Instance.new("Frame")
    indicator.Size             = UDim2.new(0, 3, 1, 0)
    indicator.BackgroundColor3 = T.Accent
    indicator.BorderSizePixel  = 0
    indicator.BackgroundTransparency = 1
    indicator.Parent           = btn
    corner(indicator, 2)

    -- Scrollable content page
    local page = Instance.new("ScrollingFrame")
    page.Name              = "Page_" .. name
    page.Size              = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel   = 0
    page.ScrollBarThickness= 3
    page.ScrollBarImageColor3 = T.Accent
    page.CanvasSize        = UDim2.new(0, 0, 0, 0)
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible           = false
    page.Parent            = self._content

    local pageList = listLayout(page, Enum.FillDirection.Vertical, 4)
    pageList.HorizontalAlignment = Enum.HorizontalAlignment.Center
    local pagePad = Instance.new("UIPadding")
    pagePad.PaddingLeft  = UDim.new(0, 8)
    pagePad.PaddingRight = UDim.new(0, 8)
    pagePad.PaddingTop   = UDim.new(0, 6)
    pagePad.PaddingBottom= UDim.new(0, 6)
    pagePad.Parent = page

    local tabEntry = {
        name      = name,
        button    = btn,
        indicator = indicator,
        page      = page,
    }
    table.insert(self._tabs, tabEntry)

    -- Click to activate
    table.insert(self._conns, btn.MouseButton1Click:Connect(function()
        self:_activateTab(tabEntry)
    end))

    -- Hover effects
    table.insert(self._conns, btn.MouseEnter:Connect(function()
        if self._activeTab ~= tabEntry then
            tween(btn, FAST, { BackgroundColor3 = T.SurfaceHover })
        end
    end))
    table.insert(self._conns, btn.MouseLeave:Connect(function()
        if self._activeTab ~= tabEntry then
            tween(btn, FAST, { BackgroundColor3 = T.TabInactive })
        end
    end))

    -- Auto-activate first tab
    if #self._tabs == 1 then
        self:_activateTab(tabEntry)
    end

    -- Return Tab API
    return self:_tabAPI(tabEntry, page)
end

function Hub:_activateTab(entry)
    local T = self._theme
    -- Deactivate old
    if self._activeTab then
        local old = self._activeTab
        tween(old.button, FAST, { BackgroundColor3 = T.TabInactive, TextColor3 = T.TabText })
        old.indicator.BackgroundTransparency = 1
        old.page.Visible = false
    end
    -- Activate new
    self._activeTab = entry
    tween(entry.button, FAST, { BackgroundColor3 = T.TabActive, TextColor3 = T.TabTextActive })
    entry.indicator.BackgroundTransparency = 0
    entry.page.Visible = true
end

function Hub:_dummyTab()
    local dummy = {}
    local noop = function() return dummy end
    dummy.Toggle   = noop; dummy.Slider   = noop
    dummy.Button   = noop; dummy.Dropdown = noop
    dummy.Section  = noop; dummy.Label    = noop
    dummy.Keybind  = noop
    return dummy
end

-- ========================================================
-- TAB COMPONENT API
-- ========================================================
function Hub:_tabAPI(entry, page)
    local T    = self._theme
    local api  = {}
    local layout_order = 0
    local function nextOrder()
        layout_order = layout_order + 1
        return layout_order
    end

    local function rowFrame(h)
        local f = Instance.new("Frame")
        f.Size              = UDim2.new(1, 0, 0, h or 30)
        f.BackgroundColor3  = T.Surface
        f.BorderSizePixel   = 0
        f.LayoutOrder       = nextOrder()
        f.Parent            = page
        corner(f, 6)
        return f
    end

    -- Section label
    function api:Section(label)
        local f = Instance.new("Frame")
        f.Size             = UDim2.new(1, 0, 0, 22)
        f.BackgroundTransparency = 1
        f.LayoutOrder      = nextOrder()
        f.Parent           = page

        local line = Instance.new("Frame")
        line.Size             = UDim2.new(1, -80, 0, 1)
        line.Position         = UDim2.new(0, 0, 0.5, 0)
        line.BackgroundColor3 = T.Border
        line.BorderSizePixel  = 0
        line.Parent           = f

        local lbl = Instance.new("TextLabel")
        lbl.BackgroundColor3 = T.Background
        lbl.Size             = UDim2.new(0, 80, 1, 0)
        lbl.Position         = UDim2.new(0, 0, 0, 0)
        lbl.Text             = label or "General"
        lbl.TextSize         = 11
        lbl.Font             = Enum.Font.GothamBold
        lbl.TextColor3       = T.Section
        lbl.TextXAlignment   = Enum.TextXAlignment.Left
        lbl.Parent           = f

        return api
    end

    -- Plain label
    function api:Label(text, color)
        local f = rowFrame(24)
        f.BackgroundTransparency = 1

        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Size           = UDim2.new(1, 0, 1, 0)
        lbl.Text           = text or ""
        lbl.TextSize       = 12
        lbl.Font           = Enum.Font.Gotham
        lbl.TextColor3     = color or T.TextMuted
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent         = f
        padding(f, 4)
        return api
    end

    -- Toggle
    function api:Toggle(label, default, callback)
        local enabled = default and true or false
        local f = rowFrame(34)

        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Position   = UDim2.new(0, 10, 0, 0)
        lbl.Size       = UDim2.new(1, -58, 1, 0)
        lbl.Text       = label
        lbl.TextSize   = 13
        lbl.Font       = Enum.Font.GothamSemiBold
        lbl.TextColor3 = T.Text
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent     = f

        local track = Instance.new("Frame")
        track.Size             = UDim2.new(0, 36, 0, 18)
        track.Position         = UDim2.new(1, -46, 0.5, -9)
        track.BackgroundColor3 = enabled and T.ToggleOn or T.ToggleOff
        track.BorderSizePixel  = 0
        track.Parent           = f
        corner(track, 9)

        local knob = Instance.new("Frame")
        knob.Size             = UDim2.new(0, 14, 0, 14)
        knob.Position         = UDim2.new(enabled and 1 or 0, enabled and -16 or 2, 0.5, -7)
        knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        knob.BorderSizePixel  = 0
        knob.ZIndex           = 2
        knob.Parent           = track
        corner(knob, 7)

        local btn = Instance.new("TextButton")
        btn.Size              = UDim2.new(1, 0, 1, 0)
        btn.BackgroundTransparency = 1
        btn.Text              = ""
        btn.ZIndex            = 3
        btn.Parent            = f

        local function setToggle(v, fireCallback)
            enabled = v and true or false
            tween(track, FAST, { BackgroundColor3 = enabled and T.ToggleOn or T.ToggleOff })
            tween(knob,  FAST, {
                Position = enabled
                    and UDim2.new(1, -16, 0.5, -7)
                    or  UDim2.new(0, 2,   0.5, -7)
            })
            if fireCallback and type(callback) == "function" then
                pcall(callback, enabled)
            end
        end

        table.insert(self._conns, btn.MouseButton1Click:Connect(function()
            setToggle(not enabled, true)
        end))

        table.insert(self._conns, f.MouseEnter:Connect(function()
            tween(f, FAST, { BackgroundColor3 = T.SurfaceHover })
        end))
        table.insert(self._conns, f.MouseLeave:Connect(function()
            tween(f, FAST, { BackgroundColor3 = T.Surface })
        end))

        if default and type(callback) == "function" then
            task.spawn(function() pcall(callback, true) end)
        end

        return api
    end

    -- Slider
    function api:Slider(label, min, max, default, callback, step)
        min  = tonumber(min)  or 0
        max  = tonumber(max)  or 100
        step = tonumber(step) or 1
        local val = math.clamp(tonumber(default) or min, min, max)

        local f = rowFrame(48)

        local labelRow = Instance.new("Frame")
        labelRow.BackgroundTransparency = 1
        labelRow.Size     = UDim2.new(1, -12, 0, 20)
        labelRow.Position = UDim2.new(0, 6, 0, 4)
        labelRow.Parent   = f

        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Size       = UDim2.new(0.7, 0, 1, 0)
        lbl.Text       = label
        lbl.TextSize   = 13
        lbl.Font       = Enum.Font.GothamSemiBold
        lbl.TextColor3 = T.Text
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent     = labelRow

        local valLbl = Instance.new("TextLabel")
        valLbl.BackgroundTransparency = 1
        valLbl.Size       = UDim2.new(0.3, 0, 1, 0)
        valLbl.Position   = UDim2.new(0.7, 0, 0, 0)
        valLbl.Text       = tostring(val)
        valLbl.TextSize   = 12
        valLbl.Font       = Enum.Font.GothamBold
        valLbl.TextColor3 = T.Accent
        valLbl.TextXAlignment = Enum.TextXAlignment.Right
        valLbl.Parent     = labelRow

        local track = Instance.new("Frame")
        track.Size             = UDim2.new(1, -12, 0, 6)
        track.Position         = UDim2.new(0, 6, 0, 30)
        track.BackgroundColor3 = T.SliderBar
        track.BorderSizePixel  = 0
        track.ClipsDescendants = false
        track.Parent           = f
        corner(track, 3)

        local fill = Instance.new("Frame")
        fill.Size              = UDim2.new((val - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3  = T.SliderFill
        fill.BorderSizePixel   = 0
        fill.Parent            = track
        corner(fill, 3)

        local knob = Instance.new("Frame")
        knob.Size             = UDim2.new(0, 12, 0, 12)
        knob.Position         = UDim2.new((val - min) / (max - min), -6, 0.5, -6)
        knob.BackgroundColor3 = T.SliderKnob
        knob.BorderSizePixel  = 0
        knob.ZIndex           = 3
        knob.Parent           = track
        corner(knob, 6)

        local hitBtn = Instance.new("TextButton")
        hitBtn.Size              = UDim2.new(1, 0, 0, 20)
        hitBtn.Position          = UDim2.new(0, 0, 0.5, -10)
        hitBtn.BackgroundTransparency = 1
        hitBtn.Text              = ""
        hitBtn.ZIndex            = 4
        hitBtn.Parent            = track

        local function snapVal(rawX)
            local rel = math.clamp(rawX / track.AbsoluteSize.X, 0, 1)
            local raw = min + rel * (max - min)
            local snapped = math.round(raw / step) * step
            snapped = math.clamp(snapped, min, max)
            return snapped
        end

        local function setVal(v, fire)
            val = math.clamp(v, min, max)
            local t = (val - min) / (max - min)
            local vStr = (step < 1)
                and string.format("%.2f", val)
                or  tostring(math.floor(val + 0.5))
            valLbl.Text = vStr
            tween(fill,  FAST, { Size = UDim2.new(t, 0, 1, 0) })
            tween(knob,  FAST, { Position = UDim2.new(t, -6, 0.5, -6) })
            if fire and type(callback) == "function" then
                pcall(callback, val)
            end
        end

        local dragging = false
        table.insert(self._conns, hitBtn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
            end
        end))
        table.insert(self._conns, UserInputService.InputChanged:Connect(function(input)
            if not dragging then return end
            if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
                local relX = input.Position.X - track.AbsolutePosition.X
                setVal(snapVal(relX), true)
            end
        end))
        table.insert(self._conns, UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end))

        table.insert(self._conns, hitBtn.MouseButton1Click:Connect(function()
            local mouse = UserInputService:GetMouseLocation()
            local relX  = mouse.X - track.AbsolutePosition.X
            setVal(snapVal(relX), true)
        end))

        table.insert(self._conns, f.MouseEnter:Connect(function()
            tween(f, FAST, { BackgroundColor3 = T.SurfaceHover })
        end))
        table.insert(self._conns, f.MouseLeave:Connect(function()
            tween(f, FAST, { BackgroundColor3 = T.Surface })
        end))

        task.spawn(function() pcall(callback, val) end)

        return api
    end

    -- Button
    function api:Button(label, callback, variant)
        variant = variant or "primary"
        local f = rowFrame(34)

        local colors = {
            primary     = { bg = T.Accent,          hover = T.AccentHover,       text = Color3.fromRGB(255,255,255) },
            destructive = { bg = T.BtnDestructive,   hover = Color3.fromRGB(255,80,80), text = Color3.fromRGB(255,255,255) },
            ghost       = { bg = T.Surface,           hover = T.SurfaceHover,     text = T.Text },
        }
        local c = colors[variant] or colors.primary
        f.BackgroundColor3 = c.bg

        local btn = Instance.new("TextButton")
        btn.Size              = UDim2.new(1, 0, 1, 0)
        btn.BackgroundTransparency = 1
        btn.Text              = label
        btn.TextSize          = 13
        btn.Font              = Enum.Font.GothamSemiBold
        btn.TextColor3        = c.text
        btn.BorderSizePixel   = 0
        btn.Parent            = f
        corner(f, 6)

        table.insert(self._conns, btn.MouseEnter:Connect(function()
            tween(f, FAST, { BackgroundColor3 = c.hover })
        end))
        table.insert(self._conns, btn.MouseLeave:Connect(function()
            tween(f, FAST, { BackgroundColor3 = c.bg })
        end))
        table.insert(self._conns, btn.MouseButton1Click:Connect(function()
            if type(callback) == "function" then
                task.spawn(function() pcall(callback) end)
            end
            tween(f, FAST, { BackgroundColor3 = Color3.fromRGB(255,255,255) })
            task.delay(0.15, function()
                tween(f, FAST, { BackgroundColor3 = c.bg })
            end)
        end))

        return api
    end

    -- Dropdown
    function api:Dropdown(label, options, default, callback)
        options = options or {}
        local selected = default or (options[1] or "")
        local open     = false
        local dropFrame = nil

        local f = rowFrame(34)

        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Position   = UDim2.new(0, 10, 0, 0)
        lbl.Size       = UDim2.new(0.5, 0, 1, 0)
        lbl.Text       = label
        lbl.TextSize   = 13
        lbl.Font       = Enum.Font.GothamSemiBold
        lbl.TextColor3 = T.Text
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent     = f

        local valBtn = Instance.new("TextButton")
        valBtn.Size             = UDim2.new(0.4, 0, 0.7, 0)
        valBtn.Position         = UDim2.new(0.55, 0, 0.15, 0)
        valBtn.BackgroundColor3 = T.SliderBar
        valBtn.Text             = selected
        valBtn.TextSize         = 12
        valBtn.Font             = Enum.Font.GothamSemiBold
        valBtn.TextColor3       = T.Text
        valBtn.BorderSizePixel  = 0
        valBtn.Parent           = f
        corner(valBtn, 5)

        local chev = Instance.new("TextLabel")
        chev.BackgroundTransparency = 1
        chev.Size       = UDim2.new(0, 16, 1, 0)
        chev.Position   = UDim2.new(1, -20, 0, 0)
        chev.Text       = "▾"
        chev.TextSize   = 12
        chev.Font       = Enum.Font.GothamBold
        chev.TextColor3 = T.TextMuted
        chev.Parent     = f

        local function closeDrop()
            if dropFrame and dropFrame.Parent then
                dropFrame:Destroy()
                dropFrame = nil
            end
            open = false
        end

        local function openDrop()
            closeDrop()
            open = true

            local itemH = 28
            local totalH = #options * itemH + 8

            dropFrame = Instance.new("Frame")
            dropFrame.Name              = "Dropdown_" .. label
            dropFrame.Size              = UDim2.new(0, f.AbsoluteSize.X * 0.4, 0, totalH)
            dropFrame.Position          = UDim2.new(
                0, f.AbsolutePosition.X + f.AbsoluteSize.X * 0.55 - self._content.AbsolutePosition.X,
                0, f.AbsolutePosition.Y - self._content.AbsolutePosition.Y + f.AbsoluteSize.Y
            )
            dropFrame.BackgroundColor3  = T.DropBg
            dropFrame.BorderSizePixel   = 0
            dropFrame.ZIndex            = 20
            dropFrame.ClipsDescendants  = true
            dropFrame.Parent            = self._content
            corner(dropFrame, 6)

            local dList = listLayout(dropFrame, Enum.FillDirection.Vertical, 2)
            dList.HorizontalAlignment = Enum.HorizontalAlignment.Center
            local dPad = Instance.new("UIPadding")
            dPad.PaddingLeft  = UDim.new(0, 4); dPad.PaddingRight  = UDim.new(0, 4)
            dPad.PaddingTop   = UDim.new(0, 4); dPad.PaddingBottom = UDim.new(0, 4)
            dPad.Parent       = dropFrame

            table.insert(self._dropdowns, closeDrop)

            for i, opt in ipairs(options) do
                local item = Instance.new("TextButton")
                item.Size             = UDim2.new(1, 0, 0, itemH)
                item.BackgroundColor3 = (opt == selected) and T.Accent or T.Surface
                item.Text             = opt
                item.TextSize         = 12
                item.Font             = Enum.Font.GothamSemiBold
                item.TextColor3       = (opt == selected) and Color3.fromRGB(255,255,255) or T.Text
                item.BorderSizePixel  = 0
                item.LayoutOrder      = i
                item.ZIndex           = 21
                item.Parent           = dropFrame
                corner(item, 4)

                table.insert(self._conns, item.MouseEnter:Connect(function()
                    if opt ~= selected then
                        tween(item, FAST, { BackgroundColor3 = T.SurfaceHover })
                    end
                end))
                table.insert(self._conns, item.MouseLeave:Connect(function()
                    if opt ~= selected then
                        tween(item, FAST, { BackgroundColor3 = T.Surface })
                    end
                end))
                table.insert(self._conns, item.MouseButton1Click:Connect(function()
                    selected        = opt
                    valBtn.Text     = opt
                    closeDrop()
                    if type(callback) == "function" then
                        pcall(callback, opt)
                    end
                end))
            end
        end

        table.insert(self._conns, valBtn.MouseButton1Click:Connect(function()
            if open then closeDrop() else openDrop() end
        end))

        table.insert(self._conns, f.MouseEnter:Connect(function()
            tween(f, FAST, { BackgroundColor3 = T.SurfaceHover })
        end))
        table.insert(self._conns, f.MouseLeave:Connect(function()
            tween(f, FAST, { BackgroundColor3 = T.Surface })
        end))

        return api
    end

    -- Keybind
    function api:Keybind(label, default, callback)
        local boundKey = default or Enum.KeyCode.Unknown
        local listening = false
        local f = rowFrame(34)

        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Position   = UDim2.new(0, 10, 0, 0)
        lbl.Size       = UDim2.new(0.6, 0, 1, 0)
        lbl.Text       = label
        lbl.TextSize   = 13
        lbl.Font       = Enum.Font.GothamSemiBold
        lbl.TextColor3 = T.Text
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent     = f

        local badge = Instance.new("TextButton")
        badge.Size             = UDim2.new(0, 60, 0, 22)
        badge.Position         = UDim2.new(1, -70, 0.5, -11)
        badge.BackgroundColor3 = T.SliderBar
        badge.Text             = boundKey.Name
        badge.TextSize         = 11
        badge.Font             = Enum.Font.GothamBold
        badge.TextColor3       = T.Accent
        badge.BorderSizePixel  = 0
        badge.Parent           = f
        corner(badge, 5)

        table.insert(self._conns, badge.MouseButton1Click:Connect(function()
            listening   = true
            badge.Text  = "..."
            badge.TextColor3 = T.TextMuted
        end))

        table.insert(self._conns, UserInputService.InputBegan:Connect(function(input, gpe)
            if not listening then return end
            if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
            boundKey        = input.KeyCode
            badge.Text      = boundKey.Name
            badge.TextColor3= T.Accent
            listening       = false
            if type(callback) == "function" then
                pcall(callback, boundKey)
            end
        end))

        return api
    end

    return api
end

-- ========================================================
-- NOTIFICATIONS
-- ========================================================
function Hub:Notify(message, kind, duration)
    if self._destroyed then return end
    local T   = self._theme
    kind      = kind or "ok"
    duration  = tonumber(duration) or 3.5

    local colors = {
        ok    = Color3.fromRGB(80, 200, 120),
        warn  = Color3.fromRGB(255, 180, 50),
        error = Color3.fromRGB(220, 60, 60),
        info  = T.Accent,
    }
    local c = colors[kind] or colors.info

    local toast = Instance.new("Frame")
    toast.Size             = UDim2.new(1, 0, 0, 48)
    toast.BackgroundColor3 = T.Surface
    toast.BorderSizePixel  = 0
    toast.BackgroundTransparency = 1
    toast.Parent           = self._notifContainer
    corner(toast, 8)

    local bar = Instance.new("Frame")
    bar.Size              = UDim2.new(0, 4, 1, 0)
    bar.BackgroundColor3  = c
    bar.BorderSizePixel   = 0
    bar.Parent            = toast
    corner(bar, 2)

    local msgLbl = Instance.new("TextLabel")
    msgLbl.BackgroundTransparency = 1
    msgLbl.Position  = UDim2.new(0, 12, 0, 0)
    msgLbl.Size      = UDim2.new(1, -16, 1, 0)
    msgLbl.Text      = message
    msgLbl.TextSize  = 12
    msgLbl.Font      = Enum.Font.GothamSemiBold
    msgLbl.TextColor3= T.Text
    msgLbl.TextXAlignment = Enum.TextXAlignment.Left
    msgLbl.TextWrapped= true
    msgLbl.Parent    = toast

    tween(toast, MED, { BackgroundTransparency = 0 })

    local prog = Instance.new("Frame")
    prog.Size              = UDim2.new(1, 0, 0, 2)
    prog.Position          = UDim2.new(0, 0, 1, -2)
    prog.BackgroundColor3  = c
    prog.BorderSizePixel   = 0
    prog.Parent            = toast

    TweenService:Create(prog, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
        Size = UDim2.new(0, 0, 0, 2)
    }):Play()

    task.delay(duration, function()
        if toast and toast.Parent then
            tween(toast, MED, { BackgroundTransparency = 1 })
            task.delay(0.25, function()
                if toast and toast.Parent then toast:Destroy() end
            end)
        end
    end)
end

-- ========================================================
-- CLOSE ALL DROPDOWNS
-- ========================================================
function Hub:_closeAllDropdowns()
    for _, fn in ipairs(self._dropdowns) do
        pcall(fn)
    end
    self._dropdowns = {}
end

-- ========================================================
-- DESTROY
-- ========================================================
function Hub:Destroy()
    if self._destroyed then return end
    self._destroyed = true

    for _, c in ipairs(self._conns) do
        disconnect(c)
    end
    self._conns = {}

    if self._sg and self._sg.Parent then
        pcall(function() self._sg:Destroy() end)
    end

    for i, h in ipairs(_activeHubs) do
        if h == self then
            table.remove(_activeHubs, i)
            break
        end
    end
end

-- ========================================================
-- GLOBAL NOTIFY INTEGRATION
-- ========================================================
function Hub:RegisterAsGlobal()
    _G.PawZHub_Notify = function(msg, kind)
        self:Notify(msg, kind)
    end
    _G.PawZHub_Toast = self
end

-- ========================================================
-- HUB ALIASES  (game scripts may call AddTab/AddToggle etc.)
-- AddTab wraps Tab and injects Add-prefixed aliases on the returned tab API
-- ========================================================
Hub.AddTab = function(self, name)
    local api = Hub.Tab(self, name)
    if type(api) == "table" then
        api.AddSection  = api.Section
        api.AddLabel    = api.Label
        api.AddToggle   = api.Toggle
        api.AddSlider   = api.Slider
        api.AddButton   = api.Button
        api.AddDropdown = api.Dropdown
        api.AddKeybind  = api.Keybind
    end
    return api
end

-- ========================================================
-- PUBLIC MODULE API
-- ========================================================
local UI = {}

UI.Themes    = Themes
UI.Hub       = Hub
UI.New       = function(options) return Hub.New(options) end

UI.DestroyAll = function()
    for i = #_activeHubs, 1, -1 do
        _activeHubs[i]:Destroy()
    end
end

return UI

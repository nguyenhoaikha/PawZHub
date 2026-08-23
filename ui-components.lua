-- PawZHub UI Components Library
-- Reusable UI components for consistent design

local UIComponents = {}
local TweenService = game:GetService("TweenService")

-- ============================================
-- COLORS
-- ============================================

UIComponents.Colors = {
    Primary = Color3.fromRGB(102, 126, 234),
    Secondary = Color3.fromRGB(118, 75, 162),
    Success = Color3.fromRGB(76, 175, 80),
    Warning = Color3.fromRGB(255, 152, 0),
    Error = Color3.fromRGB(244, 67, 54),
    Info = Color3.fromRGB(33, 150, 243),
    
    Background = Color3.fromRGB(240, 242, 247),
    Surface = Color3.fromRGB(255, 255, 255),
    Border = Color3.fromRGB(200, 205, 215),
    
    Text = {
        Primary = Color3.fromRGB(30, 30, 35),
        Secondary = Color3.fromRGB(100, 105, 115),
        Disabled = Color3.fromRGB(150, 155, 165)
    }
}

-- ============================================
-- BUTTON COMPONENT
-- ============================================

function UIComponents.CreateButton(config)
    local button = Instance.new("TextButton")
    button.Size = config.Size or UDim2.new(0, 120, 0, 36)
    button.Position = config.Position or UDim2.new(0, 0, 0, 0)
    button.BackgroundColor3 = config.Color or UIComponents.Colors.Primary
    button.BorderSizePixel = 0
    button.Text = config.Text or "Button"
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = config.TextSize or 14
    button.Font = Enum.Font.GothamMedium
    button.AutoButtonColor = false
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, config.CornerRadius or 8)
    corner.Parent = button
    
    -- Hover effect
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {
            BackgroundColor3 = Color3.new(
                button.BackgroundColor3.R * 0.9,
                button.BackgroundColor3.G * 0.9,
                button.BackgroundColor3.B * 0.9
            )
        }):Play()
    end)
    
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.2), {
            BackgroundColor3 = config.Color or UIComponents.Colors.Primary
        }):Play()
    end)
    
    -- Click effect
    button.MouseButton1Down:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.1), {
            Size = button.Size - UDim2.new(0, 4, 0, 4)
        }):Play()
    end)
    
    button.MouseButton1Up:Connect(function()
        TweenService:Create(button, TweenInfo.new(0.1), {
            Size = config.Size or UDim2.new(0, 120, 0, 36)
        }):Play()
    end)
    
    if config.OnClick then
        button.MouseButton1Click:Connect(config.OnClick)
    end
    
    return button
end

-- ============================================
-- INPUT FIELD COMPONENT
-- ============================================

function UIComponents.CreateInput(config)
    local container = Instance.new("Frame")
    container.Size = config.Size or UDim2.new(1, 0, 0, 36)
    container.Position = config.Position or UDim2.new(0, 0, 0, 0)
    container.BackgroundColor3 = UIComponents.Colors.Surface
    container.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = container
    
    local border = Instance.new("UIStroke")
    border.Color = UIComponents.Colors.Border
    border.Thickness = 1
    border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    border.Parent = container
    
    local input = Instance.new("TextBox")
    input.Size = UDim2.new(1, -20, 1, 0)
    input.Position = UDim2.new(0, 10, 0, 0)
    input.BackgroundTransparency = 1
    input.Text = ""
    input.PlaceholderText = config.Placeholder or "Enter text..."
    input.TextColor3 = UIComponents.Colors.Text.Primary
    input.PlaceholderColor3 = UIComponents.Colors.Text.Disabled
    input.TextSize = 14
    input.Font = Enum.Font.Gotham
    input.TextXAlignment = Enum.TextXAlignment.Left
    input.ClearTextOnFocus = false
    input.Parent = container
    
    -- Focus effects
    input.Focused:Connect(function()
        TweenService:Create(border, TweenInfo.new(0.15), {
            Color = UIComponents.Colors.Primary,
            Thickness = 2
        }):Play()
    end)
    
    input.FocusLost:Connect(function()
        TweenService:Create(border, TweenInfo.new(0.15), {
            Color = UIComponents.Colors.Border,
            Thickness = 1
        }):Play()
        
        if config.OnChange then
            config.OnChange(input.Text)
        end
    end)
    
    container.Input = input
    return container
end

-- ============================================
-- CARD COMPONENT
-- ============================================

function UIComponents.CreateCard(config)
    local card = Instance.new("Frame")
    card.Size = config.Size or UDim2.new(0, 300, 0, 200)
    card.Position = config.Position or UDim2.new(0, 0, 0, 0)
    card.BackgroundColor3 = UIComponents.Colors.Surface
    card.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = card
    
    -- Shadow effect
    local shadow = Instance.new("ImageLabel")
    shadow.Size = UDim2.new(1, 20, 1, 20)
    shadow.Position = UDim2.new(0, -10, 0, 5)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.9
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(10, 10, 10, 10)
    shadow.ZIndex = 0
    shadow.Parent = card
    
    if config.Padding then
        local padding = Instance.new("UIPadding")
        padding.PaddingTop = UDim.new(0, config.Padding)
        padding.PaddingBottom = UDim.new(0, config.Padding)
        padding.PaddingLeft = UDim.new(0, config.Padding)
        padding.PaddingRight = UDim.new(0, config.Padding)
        padding.Parent = card
    end
    
    return card
end

-- ============================================
-- PROGRESS BAR COMPONENT
-- ============================================

function UIComponents.CreateProgressBar(config)
    local container = Instance.new("Frame")
    container.Size = config.Size or UDim2.new(1, 0, 0, 8)
    container.Position = config.Position or UDim2.new(0, 0, 0, 0)
    container.BackgroundColor3 = Color3.fromRGB(230, 230, 230)
    container.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = container
    
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 0, 1, 0)
    bar.BackgroundColor3 = config.Color or UIComponents.Colors.Primary
    bar.BorderSizePixel = 0
    bar.Parent = container
    
    local barCorner = Instance.new("UICorner")
    barCorner.CornerRadius = UDim.new(1, 0)
    barCorner.Parent = bar
    
    container.SetProgress = function(progress)
        progress = math.clamp(progress, 0, 1)
        TweenService:Create(bar, TweenInfo.new(0.5), {
            Size = UDim2.new(progress, 0, 1, 0)
        }):Play()
    end
    
    return container
end

-- ============================================
-- BADGE COMPONENT
-- ============================================

function UIComponents.CreateBadge(config)
    local badge = Instance.new("Frame")
    badge.Size = UDim2.new(0, 0, 0, 24)
    badge.Position = config.Position or UDim2.new(0, 0, 0, 0)
    badge.BackgroundColor3 = config.Color or UIComponents.Colors.Info
    badge.BorderSizePixel = 0
    badge.AutomaticSize = Enum.AutomaticSize.X
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = badge
    
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 12)
    padding.PaddingRight = UDim.new(0, 12)
    padding.Parent = badge
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = config.Text or "Badge"
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 12
    label.Font = Enum.Font.GothamBold
    label.AutomaticSize = Enum.AutomaticSize.X
    label.Parent = badge
    
    return badge
end

-- ============================================
-- TOGGLE SWITCH COMPONENT
-- ============================================

function UIComponents.CreateToggle(config)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, 50, 0, 28)
    container.Position = config.Position or UDim2.new(0, 0, 0, 0)
    container.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
    container.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = container
    
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 24, 0, 24)
    button.Position = UDim2.new(0, 2, 0, 2)
    button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    button.BorderSizePixel = 0
    button.Text = ""
    button.AutoButtonColor = false
    button.Parent = container
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(1, 0)
    buttonCorner.Parent = button
    
    local isOn = config.Default or false
    
    local function updateToggle(on, animate)
        isOn = on
        
        local targetPos = on and UDim2.new(1, -26, 0, 2) or UDim2.new(0, 2, 0, 2)
        local targetColor = on and UIComponents.Colors.Success or Color3.fromRGB(220, 220, 220)
        
        if animate then
            TweenService:Create(button, TweenInfo.new(0.2), { Position = targetPos }):Play()
            TweenService:Create(container, TweenInfo.new(0.2), { BackgroundColor3 = targetColor }):Play()
        else
            button.Position = targetPos
            container.BackgroundColor3 = targetColor
        end
        
        if config.OnToggle then
            config.OnToggle(on)
        end
    end
    
    button.MouseButton1Click:Connect(function()
        updateToggle(not isOn, true)
    end)
    
    updateToggle(isOn, false)
    
    container.SetValue = function(value)
        updateToggle(value, true)
    end
    
    container.GetValue = function()
        return isOn
    end
    
    return container
end

-- ============================================
-- DROPDOWN COMPONENT
-- ============================================

function UIComponents.CreateDropdown(config)
    local container = Instance.new("Frame")
    container.Size = config.Size or UDim2.new(0, 200, 0, 36)
    container.Position = config.Position or UDim2.new(0, 0, 0, 0)
    container.BackgroundColor3 = UIComponents.Colors.Surface
    container.BorderSizePixel = 0
    container.ClipsDescendants = false
    container.ZIndex = 10
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = container
    
    local border = Instance.new("UIStroke")
    border.Color = UIComponents.Colors.Border
    border.Thickness = 1
    border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    border.Parent = container
    
    local selected = config.Options[1] or "Select..."
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -40, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = selected
    label.TextColor3 = UIComponents.Colors.Text.Primary
    label.TextSize = 14
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local arrow = Instance.new("TextLabel")
    arrow.Size = UDim2.new(0, 20, 1, 0)
    arrow.Position = UDim2.new(1, -25, 0, 0)
    arrow.BackgroundTransparency = 1
    arrow.Text = "▼"
    arrow.TextColor3 = UIComponents.Colors.Text.Secondary
    arrow.TextSize = 12
    arrow.Parent = container
    
    local dropdown = Instance.new("Frame")
    dropdown.Size = UDim2.new(1, 0, 0, 0)
    dropdown.Position = UDim2.new(0, 0, 1, 5)
    dropdown.BackgroundColor3 = UIComponents.Colors.Surface
    dropdown.BorderSizePixel = 0
    dropdown.Visible = false
    dropdown.ZIndex = 11
    dropdown.Parent = container
    
    local dropdownCorner = Instance.new("UICorner")
    dropdownCorner.CornerRadius = UDim.new(0, 6)
    dropdownCorner.Parent = dropdown
    
    local dropdownBorder = Instance.new("UIStroke")
    dropdownBorder.Color = UIComponents.Colors.Border
    dropdownBorder.Thickness = 1
    dropdownBorder.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    dropdownBorder.Parent = dropdown
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 2)
    layout.Parent = dropdown
    
    local isOpen = false
    
    for i, option in ipairs(config.Options) do
        local optionButton = Instance.new("TextButton")
        optionButton.Size = UDim2.new(1, 0, 0, 32)
        optionButton.BackgroundColor3 = UIComponents.Colors.Surface
        optionButton.BorderSizePixel = 0
        optionButton.Text = option
        optionButton.TextColor3 = UIComponents.Colors.Text.Primary
        optionButton.TextSize = 14
        optionButton.Font = Enum.Font.Gotham
        optionButton.AutoButtonColor = false
        optionButton.Parent = dropdown
        
        optionButton.MouseEnter:Connect(function()
            optionButton.BackgroundColor3 = UIComponents.Colors.Background
        end)
        
        optionButton.MouseLeave:Connect(function()
            optionButton.BackgroundColor3 = UIComponents.Colors.Surface
        end)
        
        optionButton.MouseButton1Click:Connect(function()
            selected = option
            label.Text = option
            dropdown.Visible = false
            isOpen = false
            
            if config.OnSelect then
                config.OnSelect(option, i)
            end
        end)
    end
    
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.ZIndex = 10
    button.Parent = container
    
    button.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        dropdown.Visible = isOpen
        
        if isOpen then
            dropdown.Size = UDim2.new(1, 0, 0, #config.Options * 34)
        end
    end)
    
    return container
end

-- ============================================
-- EXPORT
-- ============================================

return UIComponents

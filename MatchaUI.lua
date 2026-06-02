--[[
    MatchaUI Framework v2.0.0 (Production Ready)
    Refactored Premium UI Library for PC & Mobile
--]]

local Library = {
    Objects = {},
    Connections = {},
    Flags = {},
    Themes = {
        ["Matcha Blue"] = {
            Accent = Color3.fromRGB(110, 198, 192),
            AccentDark = Color3.fromRGB(75, 160, 154),
            AccentLight = Color3.fromRGB(150, 220, 215),
            BGPrimary = Color3.fromRGB(15, 17, 21),
            BGSecondary = Color3.fromRGB(20, 23, 28),
            BGTertiary = Color3.fromRGB(26, 30, 37),
            BGHover = Color3.fromRGB(32, 37, 46),
            BGActive = Color3.fromRGB(38, 44, 55),
            TextPrimary = Color3.fromRGB(240, 243, 245),
            TextSecondary = Color3.fromRGB(150, 155, 165)
        }
    }
}

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Environment Detection
local function GetGuiParent()
    if gethui then return gethui() end
    local success, coreGui = pcall(function() return game:GetService("CoreGui") end)
    if success and coreGui:FindFirstChild("RobloxGui") then return coreGui end
    return LocalPlayer:WaitForChild("PlayerGui")
end

-- Safely Track Connections
local function SafeConnect(signal, callback)
    local conn = signal:Connect(callback)
    table.insert(Library.Connections, conn)
    return conn
end

-- Quick Twin Utility
local function Tween(instance, info, propertyTable)
    local tween = TweenService:Create(instance, info, propertyTable)
    tween:Play()
    return tween
end

-- Premium Drag System
local function MakeWindowDraggable(windowFrame, handleFrame)
    local dragging = false
    local dragInput, dragStart, startPos

    local function update(input)
        local delta = input.Position - dragStart
        local targetX = startPos.X.Offset + delta.X
        local targetY = startPos.Y.Offset + delta.Y

        -- Clamping Viewport Bounds (Keep minimum 30% of window inside viewport)
        local camera = workspace.CurrentCamera
        if camera then
            local viewportSize = camera.ViewportSize
            local minX = -windowFrame.AbsoluteSize.X * 0.7
            local maxX = viewportSize.X - (windowFrame.AbsoluteSize.X * 0.3)
            local minY = 0
            local maxY = viewportSize.Y - (windowFrame.AbsoluteSize.Y * 0.3)

            targetX = math.clamp(targetX, minX, maxX)
            targetY = math.clamp(targetY, minY, maxY)
        end

        Tween(windowFrame, TweenInfo.new(0.1, Enum.EasingStyle.OutQuad), {
            Position = UDim2.new(startPos.X.Scale, targetX, startPos.Y.Scale, targetY)
        })
    end

    SafeConnect(handleFrame.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = windowFrame.Position

            local releaseConn
            releaseConn = SafeConnect(UserInputService.InputEnded, function(endInput)
                if endInput == input or endInput.UserInputType == Enum.UserInputType.MouseButton1 or endInput.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                    if releaseConn then releaseConn:Disconnect() end
                end
            end)
        end
    end)

    SafeConnect(handleFrame.InputChanged, function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    SafeConnect(UserInputService.InputChanged, function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

-- Config Engine
local ConfigSystem = {}
ConfigSystem.__index = ConfigSystem

function ConfigSystem.new(folderName)
    local self = setmetatable({}, ConfigSystem)
    self.FolderName = folderName or "MatchaUI_Configs"
    
    if writefile and makefolder then
        pcall(function()
            makefolder(self.FolderName)
        end)
    end
    return self
end

function ConfigSystem:Save(name, data)
    local json = HttpService:JSONEncode(data)
    local success = pcall(function()
        if writefile then
            writefile(self.FolderName .. "/" .. name .. ".json", json)
        end
    end)
    return success
end

function ConfigSystem:Load(name)
    local data = nil
    pcall(function()
        if readfile and isfile and isfile(self.FolderName .. "/" .. name .. ".json") then
            local content = readfile(self.FolderName .. "/" .. name .. ".json")
            data = HttpService:JSONDecode(content)
        end
    end)
    return data
end

function ConfigSystem:List()
    local files = {}
    pcall(function()
        if listfiles then
            for _, file in ipairs(listfiles(self.FolderName)) do
                local cleanName = file:match("([^/\\]+)%.json$")
                if cleanName then table.insert(files, cleanName) end
            end
        end
    end)
    return files
end

-- Main Window Creation
function Library.CreateWindow(options)
    options = options or {}
    local windowTitle = options.Title or "MatchaUI Pro"
    local configFolder = options.ConfigFolder or "MatchaUI_Configs"
    local currentTheme = Library.Themes["Matcha Blue"]

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "MatchaUI_" .. HttpService:GenerateGUID(false)
    ScreenGui.Parent = GetGuiParent()
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 560, 0, 380)
    MainFrame.Position = UDim2.new(0.5, -280, 0.5, -190)
    MainFrame.BackgroundColor3 = currentTheme.BGPrimary
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 8)
    MainCorner.Parent = MainFrame

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Thickness = 1
    MainStroke.Color = currentTheme.BGTertiary
    MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    MainStroke.Parent = MainFrame

    -- Top Drag Handle Bar
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, 0, 0, 42)
    TopBar.BackgroundColor3 = currentTheme.BGSecondary
    TopBar.BorderSizePixel = 0
    TopBar.Parent = MainFrame

    local TopCorner = Instance.new("UICorner")
    TopCorner.CornerRadius = UDim.new(0, 8)
    TopCorner.Parent = TopBar

    -- Cover lower rounded corners of TopBar
    local TopBarCover = Instance.new("Frame")
    TopBarCover.Size = UDim2.new(1, 0, 0, 10)
    TopBarCover.Position = UDim2.new(0, 0, 1, -10)
    TopBarCover.BackgroundColor3 = currentTheme.BGSecondary
    TopBarCover.BorderSizePixel = 0
    TopBarCover.Parent = TopBar

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -100, 1, 0)
    TitleLabel.Position = UDim2.new(0, 16, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = windowTitle
    TitleLabel.TextColor3 = currentTheme.TextPrimary
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 14
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = TopBar

    local CloseButton = Instance.new("TextButton")
    CloseButton.Size = UDim2.new(0, 24, 0, 24)
    CloseButton.Position = UDim2.new(1, -34, 0, 9)
    CloseButton.BackgroundTransparency = 1
    CloseButton.Text = "×"
    CloseButton.TextColor3 = currentTheme.TextSecondary
    CloseButton.Font = Enum.Font.GothamMedium
    CloseButton.TextSize = 20
    CloseButton.Parent = TopBar

    SafeConnect(CloseButton.MouseButton1Click, function()
        Library:Destroy()
    end)

    -- Dynamic Navigation Sidebar
    local SidebarFrame = Instance.new("Frame")
    SidebarFrame.Size = UDim2.new(0, 140, 1, -42)
    SidebarFrame.Position = UDim2.new(0, 0, 0, 42)
    SidebarFrame.BackgroundColor3 = currentTheme.BGSecondary
    SidebarFrame.BorderSizePixel = 0
    SidebarFrame.Parent = MainFrame

    local SidebarLayout = Instance.new("UIListLayout")
    SidebarLayout.SortOrder = Enum.SortOrder.LayoutOrder
    SidebarLayout.Padding = UDim.new(0, 4)
    SidebarLayout.Parent = SidebarFrame

    local SidebarPadding = Instance.new("UIPadding")
    SidebarPadding.PaddingTop = UDim.new(0, 10)
    SidebarPadding.PaddingLeft = UDim.new(0, 8)
    SidebarPadding.PaddingRight = UDim.new(0, 8)
    SidebarPadding.Parent = SidebarFrame

    -- Main Interactive Container
    local ContainerFrame = Instance.new("Frame")
    ContainerFrame.Size = UDim2.new(1, -140, 1, -42)
    ContainerFrame.Position = UDim2.new(0, 140, 0, 42)
    ContainerFrame.BackgroundTransparency = 1
    ContainerFrame.Parent = MainFrame

    -- Mobile Reopen Floating Button
    local MobileButton = Instance.new("TextButton")
    MobileButton.Name = "MatchaUI_MobileFAB"
    MobileButton.Size = UDim2.new(0, 48, 0, 48)
    MobileButton.Position = UDim2.new(0, 20, 0, 80)
    MobileButton.BackgroundColor3 = currentTheme.Accent
    MobileButton.Text = "🍵"
    MobileButton.TextSize = 20
    MobileButton.Visible = UserInputService.TouchEnabled
    MobileButton.Parent = ScreenGui

    local MobileCorner = Instance.new("UICorner")
    MobileCorner.CornerRadius = UDim.new(1, 0)
    MobileCorner.Parent = MobileButton

    SafeConnect(MobileButton.MouseButton1Click, function()
        MainFrame.Visible = not MainFrame.Visible
    end)

    MakeWindowDraggable(MainFrame, TopBar)

    local WindowContext = {
        Tabs = {},
        CurrentTab = nil,
        Config = ConfigSystem.new(configFolder),
        Flags = {}
    }

    function WindowContext:CreateTab(tabName)
        local TabButton = Instance.new("TextButton")
        TabButton.Size = UDim2.new(1, 0, 0, 34)
        TabButton.BackgroundColor3 = currentTheme.BGTertiary
        TabButton.Text = tabName
        TabButton.TextColor3 = currentTheme.TextSecondary
        TabButton.Font = Enum.Font.GothamMedium
        TabButton.TextSize = 13
        TabButton.Parent = SidebarFrame

        local TabButtonCorner = Instance.new("UICorner")
        TabButtonCorner.CornerRadius = UDim.new(0, 6)
        TabButtonCorner.Parent = TabButton

        local PageFrame = Instance.new("ScrollingFrame")
        PageFrame.Size = UDim2.new(1, 0, 1, 0)
        PageFrame.BackgroundTransparency = 1
        PageFrame.Visible = false
        PageFrame.ScrollBarThickness = 3
        PageFrame.ScrollBarImageColor3 = currentTheme.Accent
        PageFrame.Parent = ContainerFrame

        local PageLayout = Instance.new("UIListLayout")
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageLayout.Padding = UDim.new(0, 6)
        PageLayout.Parent = PageFrame

        local PagePadding = Instance.new("UIPadding")
        PagePadding.PaddingTop = UDim.new(0, 10)
        PagePadding.PaddingBottom = UDim.new(0, 10)
        PagePadding.PaddingLeft = UDim.new(0, 12)
        PagePadding.PaddingRight = UDim.new(0, 12)
        PagePadding.Parent = PageFrame

        -- Automated Scrolling Calculations Fix
        SafeConnect(PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
            PageFrame.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 20)
        end)

        SafeConnect(TabButton.MouseButton1Click, function()
            for _, tab in ipairs(WindowContext.Tabs) do
                tab.Page.Visible = false
                tab.Button.TextColor3 = currentTheme.TextSecondary
                tab.Button.BackgroundColor3 = currentTheme.BGTertiary
            end
            PageFrame.Visible = true
            TabButton.TextColor3 = currentTheme.Accent
            TabButton.BackgroundColor3 = currentTheme.BGHover
        end)

        local TabContext = { Button = TabButton, Page = PageFrame }

        -- Component: CreateButton
        function TabContext:CreateButton(text, callback)
            local Button = Instance.new("TextButton")
            Button.Size = UDim2.new(1, 0, 0, 38)
            Button.BackgroundColor3 = currentTheme.BGTertiary
            Button.Text = text
            Button.TextColor3 = currentTheme.TextPrimary
            Button.Font = Enum.Font.GothamMedium
            Button.TextSize = 13
            Button.Parent = PageFrame

            local BCorn = Instance.new("UICorner")
            BCorn.CornerRadius = UDim.new(0, 6)
            BCorn.Parent = Button

            SafeConnect(Button.MouseButton1Click, function()
                task.spawn(callback)
            end)

            return {
                SetText = function(_, newText) Button.Text = newText end
            }
        end

        -- Component: CreateToggle
        function TabContext:CreateToggle(text, default, callback)
            local state = default or false
            
            local ToggleFrame = Instance.new("Frame")
            ToggleFrame.Size = UDim2.new(1, 0, 0, 40)
            ToggleFrame.BackgroundColor3 = currentTheme.BGTertiary
            ToggleFrame.Parent = PageFrame

            local TCorn = Instance.new("UICorner")
            TCorn.CornerRadius = UDim.new(0, 6)
            TCorn.Parent = ToggleFrame

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -60, 1, 0)
            Label.Position = UDim2.new(0, 12, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = text
            Label.TextColor3 = currentTheme.TextPrimary
            Label.Font = Enum.Font.GothamMedium
            Label.TextSize = 13
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = ToggleFrame

            local Indicator = Instance.new("Frame")
            Indicator.Size = UDim2.new(0, 32, 0, 18)
            Indicator.Position = UDim2.new(1, -44, 0.5, -9)
            Indicator.BackgroundColor3 = state and currentTheme.Accent or currentTheme.BGHover
            Indicator.Parent = ToggleFrame

            local ICorn = Instance.new("UICorner")
            ICorn.CornerRadius = UDim.new(1, 0)
            ICorn.Parent = Indicator

            local Trigger = Instance.new("TextButton")
            Trigger.Size = UDim2.new(1, 0, 1, 0)
            Trigger.BackgroundTransparency = 1
            Trigger.Text = ""
            Trigger.Parent = ToggleFrame

            local function updateVisuals()
                Tween(Indicator, TweenInfo.new(0.15), {
                    BackgroundColor3 = state and currentTheme.Accent or currentTheme.BGHover
                })
            end

            SafeConnect(Trigger.MouseButton1Click, function()
                state = not state
                updateVisuals()
                task.spawn(callback, state)
            end)

            return {
                Set = function(_, val)
                    state = val
                    updateVisuals()
                    task.spawn(callback, state)
                end
            }
        end

        -- Component: CreateSlider
        function TabContext:CreateSlider(text, min, max, default, callback)
            local value = default or min
            
            local SliderFrame = Instance.new("Frame")
            SliderFrame.Size = UDim2.new(1, 0, 0, 48)
            SliderFrame.BackgroundColor3 = currentTheme.BGTertiary
            SliderFrame.Parent = PageFrame

            local SCorn = Instance.new("UICorner")
            SCorn.CornerRadius = UDim.new(0, 6)
            SCorn.Parent = SliderFrame

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -100, 0, 20)
            Label.Position = UDim2.new(0, 12, 0, 6)
            Label.BackgroundTransparency = 1
            Label.Text = text
            Label.TextColor3 = currentTheme.TextPrimary
            Label.Font = Enum.Font.GothamMedium
            Label.TextSize = 13
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = SliderFrame

            local ValueLabel = Instance.new("TextLabel")
            ValueLabel.Size = UDim2.new(0, 80, 0, 20)
            ValueLabel.Position = UDim2.new(1, -92, 0, 6)
            ValueLabel.BackgroundTransparency = 1
            ValueLabel.Text = tostring(value)
            ValueLabel.TextColor3 = currentTheme.Accent
            ValueLabel.Font = Enum.Font.GothamBold
            ValueLabel.TextSize = 13
            ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
            ValueLabel.Parent = SliderFrame

            local SlideTrack = Instance.new("Frame")
            SlideTrack.Size = UDim2.new(1, -24, 0, 6)
            SlideTrack.Position = UDim2.new(0, 12, 1, -14)
            SlideTrack.BackgroundColor3 = currentTheme.BGHover
            SlideTrack.Parent = SliderFrame

            local TrackCorn = Instance.new("UICorner")
            TrackCorn.CornerRadius = UDim.new(1, 0)
            TrackCorn.Parent = SlideTrack

            local SlideFill = Instance.new("Frame")
            SlideFill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
            SlideFill.BackgroundColor3 = currentTheme.Accent
            SlideFill.Parent = SlideTrack

            local FillCorn = Instance.new("UICorner")
            FillCorn.CornerRadius = UDim.new(1, 0)
            FillCorn.Parent = SlideFill

            local ClickTracker = Instance.new("TextButton")
            ClickTracker.Size = UDim2.new(1, 0, 1, 0)
            ClickTracker.BackgroundTransparency = 1
            ClickTracker.Text = ""
            ClickTracker.Parent = SliderFrame

            local active = false

            local function updateSlider(input)
                local ratio = math.clamp((input.Position.X - SlideTrack.AbsolutePosition.X) / SlideTrack.AbsoluteSize.X, 0, 1)
                value = math.floor(min + (max - min) * ratio)
                ValueLabel.Text = tostring(value)
                SlideFill.Size = UDim2.new(ratio, 0, 1, 0)
                task.spawn(callback, value)
            end

            SafeConnect(ClickTracker.InputBegan, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    active = true
                    updateSlider(input)
                end
            end)

            SafeConnect(UserInputService.InputChanged, function(input)
                if active and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    updateSlider(input)
                end
            end)

            SafeConnect(UserInputService.InputEnded, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    active = false
                end
            end)

            return {
                Set = function(_, val)
                    value = math.clamp(val, min, max)
                    ValueLabel.Text = tostring(value)
                    SlideFill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
                    task.spawn(callback, value)
                end
            }
        end

        -- Component: CreateDropdown
        function TabContext:CreateDropdown(text, list, callback)
            local isExpanded = false
            
            local DropdownFrame = Instance.new("Frame")
            DropdownFrame.Size = UDim2.new(1, 0, 0, 38)
            DropdownFrame.BackgroundColor3 = currentTheme.BGTertiary
            DropdownFrame.ClipsDescendants = true
            DropdownFrame.Parent = PageFrame

            local DCorn = Instance.new("UICorner")
            DCorn.CornerRadius = UDim.new(0, 6)
            DCorn.Parent = DropdownFrame

            local Trigger = Instance.new("TextButton")
            Trigger.Size = UDim2.new(1, 0, 0, 38)
            Trigger.BackgroundTransparency = 1
            Trigger.Text = "  " .. text
            Trigger.TextColor3 = currentTheme.TextPrimary
            Trigger.Font = Enum.Font.GothamMedium
            Trigger.TextSize = 13
            Trigger.TextXAlignment = Enum.TextXAlignment.Left
            Trigger.Parent = DropdownFrame

            local ItemHolder = Instance.new("Frame")
            ItemHolder.Size = UDim2.new(1, 0, 0, 0)
            ItemHolder.Position = UDim2.new(0, 0, 0, 38)
            ItemHolder.BackgroundTransparency = 1
            ItemHolder.Parent = DropdownFrame

            local HolderLayout = Instance.new("UIListLayout")
            HolderLayout.SortOrder = Enum.SortOrder.LayoutOrder
            HolderLayout.Parent = ItemHolder

            local function populateOptions(items)
                for _, child in ipairs(ItemHolder:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end

                for _, val in ipairs(items) do
                    local ItemBtn = Instance.new("TextButton")
                    ItemBtn.Size = UDim2.new(1, 0, 0, 30)
                    ItemBtn.BackgroundColor3 = currentTheme.BGSecondary
                    ItemBtn.Text = "    " .. tostring(val)
                    ItemBtn.TextColor3 = currentTheme.TextSecondary
                    ItemBtn.Font = Enum.Font.Gotham
                    ItemBtn.TextSize = 12
                    ItemBtn.TextXAlignment = Enum.TextXAlignment.Left
                    ItemBtn.BorderSizePixel = 0
                    ItemBtn.Parent = ItemHolder

                    SafeConnect(ItemBtn.MouseButton1Click, function()
                        Trigger.Text = "  " .. text .. " (" .. tostring(val) .. ")"
                        isExpanded = false
                        Tween(DropdownFrame, TweenInfo.new(0.2), { Size = UDim2.new(1, 0, 0, 38) })
                        task.spawn(callback, val)
                    end)
                end
            end

            populateOptions(list)

            SafeConnect(Trigger.MouseButton1Click, function()
                isExpanded = not isExpanded
                local targetHeight = isExpanded and (38 + (#list * 30)) or 38
                Tween(DropdownFrame, TweenInfo.new(0.2), { Size = UDim2.new(1, 0, 0, targetHeight) })
            end)

            return {
                Refresh = function(_, newList)
                    list = newList
                    populateOptions(newList)
                    if not isExpanded then
                        DropdownFrame.Size = UDim2.new(1, 0, 0, 38)
                    end
                end
            }
        end

        -- Component: CreateMultiDropdown
        function TabContext:CreateMultiDropdown(text, list, callback)
            return TabContext:CreateDropdown(text, list, callback)
        end

        -- Component: CreateTextbox
        function TabContext:CreateTextbox(text, placeholder, callback)
            local BoxFrame = Instance.new("Frame")
            BoxFrame.Size = UDim2.new(1, 0, 0, 40)
            BoxFrame.BackgroundColor3 = currentTheme.BGTertiary
            BoxFrame.Parent = PageFrame

            local BCorn = Instance.new("UICorner")
            BCorn.CornerRadius = UDim.new(0, 6)
            BCorn.Parent = BoxFrame

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(0, 120, 1, 0)
            Label.Position = UDim2.new(0, 12, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = text
            Label.TextColor3 = currentTheme.TextPrimary
            Label.Font = Enum.Font.GothamMedium
            Label.TextSize = 13
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = BoxFrame

            local InputField = Instance.new("TextBox")
            InputField.Size = UDim2.new(1, -150, 0, 26)
            InputField.Position = UDim2.new(1, -138, 0.5, -13)
            InputField.BackgroundColor3 = currentTheme.BGHover
            InputField.Text = ""
            InputField.PlaceholderText = placeholder
            InputField.PlaceholderColor3 = currentTheme.TextSecondary
            InputField.TextColor3 = currentTheme.TextPrimary
            InputField.Font = Enum.Font.Gotham
            InputField.TextSize = 12
            InputField.ClearTextOnFocus = false
            InputField.Parent = BoxFrame

            local ICorn = Instance.new("UICorner")
            ICorn.CornerRadius = UDim.new(0, 4)
            ICorn.Parent = InputField

            SafeConnect(InputField.FocusLost, function(enterPressed)
                task.spawn(callback, InputField.Text)
            end)

            return {
                Set = function(_, newText) InputField.Text = newText end
            }
        end

        -- Component: CreateKeybind
        function TabContext:CreateKeybind(text, default, callback)
            local bind = default
            
            local BindFrame = Instance.new("Frame")
            BindFrame.Size = UDim2.new(1, 0, 0, 40)
            BindFrame.BackgroundColor3 = currentTheme.BGTertiary
            BindFrame.Parent = PageFrame

            local BCorn = Instance.new("UICorner")
            BCorn.CornerRadius = UDim.new(0, 6)
            BCorn.Parent = BindFrame

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -100, 1, 0)
            Label.Position = UDim2.new(0, 12, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = text
            Label.TextColor3 = currentTheme.TextPrimary
            Label.Font = Enum.Font.GothamMedium
            Label.TextSize = 13
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = BindFrame

            local BindBtn = Instance.new("TextButton")
            BindBtn.Size = UDim2.new(0, 80, 0, 26)
            BindBtn.Position = UDim2.new(1, -92, 0.5, -13)
            BindBtn.BackgroundColor3 = currentTheme.BGHover
            BindBtn.Text = bind and bind.Name or "None"
            BindBtn.TextColor3 = currentTheme.Accent
            BindBtn.Font = Enum.Font.GothamBold
            BindBtn.TextSize = 12
            BindBtn.Parent = BindFrame

            local BCorn2 = Instance.new("UICorner")
            BCorn2.CornerRadius = UDim.new(0, 4)
            BCorn2.Parent = BindBtn

            SafeConnect(BindBtn.MouseButton1Click, function()
                BindBtn.Text = "..."
                local tempConn
                tempConn = SafeConnect(UserInputService.InputBegan, function(input)
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        bind = input.KeyCode
                        BindBtn.Text = bind.Name
                        tempConn:Disconnect()
                        task.spawn(callback, bind)
                    end
                end)
            end)

            return {
                Set = function(_, newBind)
                    bind = newBind
                    BindBtn.Text = bind and bind.Name or "None"
                end
            }
        end

        -- Component: CreateColorPicker
        function TabContext:CreateColorPicker(text, default, callback)
            local chosenColor = default or Color3.fromRGB(255, 255, 255)
            
            local PickerFrame = Instance.new("Frame")
            PickerFrame.Size = UDim2.new(1, 0, 0, 40)
            PickerFrame.BackgroundColor3 = currentTheme.BGTertiary
            PickerFrame.Parent = PageFrame

            local PCorn = Instance.new("UICorner")
            PCorn.CornerRadius = UDim.new(0, 6)
            PCorn.Parent = PickerFrame

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -60, 1, 0)
            Label.Position = UDim2.new(0, 12, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = text
            Label.TextColor3 = currentTheme.TextPrimary
            Label.Font = Enum.Font.GothamMedium
            Label.TextSize = 13
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = PickerFrame

            local ColorIndicator = Instance.new("TextButton")
            ColorIndicator.Size = UDim2.new(0, 36, 0, 20)
            ColorIndicator.Position = UDim2.new(1, -48, 0.5, -10)
            ColorIndicator.BackgroundColor3 = chosenColor
            ColorIndicator.Text = ""
            ColorIndicator.Parent = PickerFrame

            local CICorn = Instance.new("UICorner")
            CICorn.CornerRadius = UDim.new(0, 4)
            CICorn.Parent = ColorIndicator

            SafeConnect(ColorIndicator.MouseButton1Click, function()
                -- Premium cyclical random quick-picker fallback or fixed modal interface
                chosenColor = Color3.fromHSV(math.random(), 0.8, 0.9)
                ColorIndicator.BackgroundColor3 = chosenColor
                task.spawn(callback, chosenColor)
            end)

            return {
                Set = function(_, newColor)
                    chosenColor = newColor
                    ColorIndicator.BackgroundColor3 = chosenColor
                    task.spawn(callback, chosenColor)
                end
            }
        end

        -- Component: CreateLabel
        function TabContext:CreateLabel(text)
            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, 0, 0, 24)
            Label.BackgroundTransparency = 1
            Label.Text = "  " .. text
            Label.TextColor3 = currentTheme.TextPrimary
            Label.Font = Enum.Font.GothamMedium
            Label.TextSize = 13
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = PageFrame

            return {
                Set = function(_, newText) Label.Text = "  " .. newText end
            }
        end

        -- Component: CreateParagraph
        function TabContext:CreateParagraph(text)
            local Paragraph = Instance.new("TextLabel")
            Paragraph.Size = UDim2.new(1, 0, 0, 48)
            Paragraph.BackgroundColor3 = currentTheme.BGTertiary
            Paragraph.Text = "  " .. text
            Paragraph.TextColor3 = currentTheme.TextSecondary
            Paragraph.Font = Enum.Font.Gotham
            Paragraph.TextSize = 12
            Paragraph.TextXAlignment = Enum.TextXAlignment.Left
            Paragraph.TextWrapped = true
            Paragraph.Parent = PageFrame

            local PCorn = Instance.new("UICorner")
            PCorn.CornerRadius = UDim.new(0, 6)
            PCorn.Parent = Paragraph

            return {
                Set = function(_, newText) Paragraph.Text = "  " .. newText end
            }
        end

        -- Component: CreateDivider
        function TabContext:CreateDivider()
            local Divider = Instance.new("Frame")
            Divider.Size = UDim2.new(1, 0, 0, 1)
            Divider.BackgroundColor3 = currentTheme.BGHover
            Divider.BorderSizePixel = 0
            Divider.Parent = PageFrame
            return Divider
        end

        table.insert(WindowContext.Tabs, TabContext)
        if #WindowContext.Tabs == 1 then
            PageFrame.Visible = true
            TabButton.TextColor3 = currentTheme.Accent
            TabButton.BackgroundColor3 = currentTheme.BGHover
        end

        return TabContext
    end

    function WindowContext:Destroy()
        ScreenGui:Destroy()
        for _, conn in ipairs(Library.Connections) do
            if conn.Connected then conn:Disconnect() end
        end
        Library.Connections = {}
    end

    return WindowContext
end

-- Notification System Stack
function Library:Notify(opts)
    opts = opts or {}
    local title = opts.Title or "Notification"
    local content = opts.Content or "Information prompt."
    local duration = opts.Duration or 3

    local parentGui = GetGuiParent()
    local container = parentGui:FindFirstChild("MatchaUI_NotifHolder")
    if not container then
        container = Instance.new("Frame")
        container.Name = "MatchaUI_NotifHolder"
        container.Size = UDim2.new(0, 280, 1, -40)
        container.Position = UDim2.new(1, -300, 0, 20)
        container.BackgroundTransparency = 1
        container.Parent = parentGui

        local Layout = Instance.new("UIListLayout")
        Layout.SortOrder = Enum.SortOrder.LayoutOrder
        Layout.Padding = UDim.new(0, 8)
        Layout.VerticalAlignment = Enum.VerticalAlignment.Top
        Layout.Parent = container
    end

    local theme = Library.Themes["Matcha Blue"]
    local NotifFrame = Instance.new("Frame")
    NotifFrame.Size = UDim2.new(1, 0, 0, 56)
    NotifFrame.BackgroundColor3 = theme.BGSecondary
    NotifFrame.BackgroundTransparency = 1
    NotifFrame.Parent = container

    local NCorn = Instance.new("UICorner")
    NCorn.CornerRadius = UDim.new(0, 6)
    NCorn.Parent = NotifFrame

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -20, 0, 18)
    Title.Position = UDim2.new(0, 10, 0, 6)
    Title.BackgroundTransparency = 1
    Title.Text = title
    Title.TextColor3 = theme.Accent
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 12
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = NotifFrame

    local Message = Instance.new("TextLabel")
    Message.Size = UDim2.new(1, -20, 1, -28)
    Message.Position = UDim2.new(0, 10, 0, 24)
    Message.BackgroundTransparency = 1
    Message.Text = content
    Message.TextColor3 = theme.TextPrimary
    Message.Font = Enum.Font.Gotham
    Message.TextSize = 12
    Message.TextXAlignment = Enum.TextXAlignment.Left
    Message.TextWrapped = true
    Message.Parent = NotifFrame

    Tween(NotifFrame, TweenInfo.new(0.2), { BackgroundTransparency = 0 })

    task.delay(duration, function()
        Tween(NotifFrame, TweenInfo.new(0.2), { BackgroundTransparency = 1 })
        task.wait(0.2)
        NotifFrame:Destroy()
    end)
end

function Library:Destroy()
    local parent = GetGuiParent()
    for _, child in ipairs(parent:GetChildren()) do
        if child.Name:sub(1, 8) == "MatchaUI" then
            child:Destroy()
        end
    end
    for _, conn in ipairs(Library.Connections) do
        if conn.Connected then conn:Disconnect() end
    end
    Library.Connections = {}
end

return Library

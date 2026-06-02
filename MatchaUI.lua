--[[
    ╔══════════════════════════════════════════════════╗
    ║          Matcha UI Library v2.5                  ║
    ║   Modern Roblox UI for Executor Environments     ║
    ║   Theme: Matcha Blue (#6EC6C0)                   ║
    ║   Author: MiMo-v2.5 (Xiaomi LLM Core Team)      ║
    ╚══════════════════════════════════════════════════╝
    
    Usage:
        local Library = loadstring(game:HttpGet("URL"))()
        local Window = Library:CreateWindow({
            Title = "Matcha UI",
            Size = UDim2.fromOffset(650, 450),
            Accent = Color3.fromRGB(110, 198, 192),
        })
        local Tab = Window:CreateTab("Main", "home")
        Tab:CreateButton({Name = "Click Me", Callback = function() print("Clicked!") end})
]]

--// ────────────────────────────────────────────────
--// Services
--// ────────────────────────────────────────────────
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local Players           = game:GetService("Players")
local Lighting          = game:GetService("Lighting")
local HttpService       = game:GetService("HttpService")
local TextService       = game:GetService("TextService")
local Debris            = game:GetService("Debris")

local LocalPlayer       = Players.LocalPlayer
local Camera            = workspace.CurrentCamera

--// ────────────────────────────────────────────────
--// Library Core
--// ────────────────────────────────────────────────
local Library = {}
Library.__index = Library
Library._windows = {}
Library._theme = {
    Accent       = Color3.fromRGB(110, 198, 192),
    Background   = Color3.fromRGB(18, 18, 30),
    Surface      = Color3.fromRGB(25, 25, 42),
    SurfaceLight = Color3.fromRGB(35, 35, 55),
    Border       = Color3.fromRGB(50, 50, 75),
    Text         = Color3.fromRGB(240, 240, 245),
    Subtext      = Color3.fromRGB(145, 145, 165),
    Success      = Color3.fromRGB(100, 200, 130),
    Warning      = Color3.fromRGB(255, 190, 60),
    Error        = Color3.fromRGB(245, 80, 80),
}

--// ────────────────────────────────────────────────
--// Mobile Detection
--// ────────────────────────────────────────────────
local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

--// ────────────────────────────────────────────────
--// Utility Helpers
--// ────────────────────────────────────────────────
local function getGuiParent()
    if gethui and type(gethui) == "function" then
        local ok, hui = pcall(gethui)
        if ok and hui then return hui end
    end
    return game:GetService("CoreGui")
end

local function create(class, props)
    local inst = Instance.new(class)
    local parent = props.Parent
    props.Parent = nil
    for k, v in pairs(props) do
        if typeof(v) == "Instance" then
            v.Parent = inst
        else
            pcall(function() inst[k] = v end)
        end
    end
    if parent then inst.Parent = parent end
    return inst
end

local function tween(obj, properties, info)
    if not obj or not obj.Parent then return nil end
    local tInfo = info or TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    local t = TweenService:Create(obj, tInfo, properties)
    t:Play()
    return t
end

local function hexFromColor(c)
    return string.format("#%02X%02X%02X",
        math.clamp(math.floor(c.R * 255 + 0.5), 0, 255),
        math.clamp(math.floor(c.G * 255 + 0.5), 0, 255),
        math.clamp(math.floor(c.B * 255 + 0.5), 0, 255))
end

local function colorFromHex(hex)
    hex = hex:gsub("#", "")
    if #hex ~= 6 then return nil end
    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)
    if r and g and b then
        return Color3.fromRGB(r, g, b)
    end
    return nil
end

local function uid()
    return HttpService:GenerateGUID(false):sub(1, 8)
end

local function rippleEffect(button, x, y)
    local ripple = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, x - button.AbsolutePosition.X, 0, y - button.AbsolutePosition.Y),
        Size = UDim2.new(0, 0, 0, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.7,
        ZIndex = button.ZIndex + 2,
        Parent = button,
    })
    create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = ripple })
    local maxDim = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2.5
    tween(ripple, { Size = UDim2.new(0, maxDim, 0, maxDim), BackgroundTransparency = 1 },
        TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
    Debris:AddItem(ripple, 0.6)
end

--// ────────────────────────────────────────────────
--// Config Manager
--// ────────────────────────────────────────────────
local ConfigManager = {}
ConfigManager.__index = ConfigManager

function ConfigManager.new(name)
    return setmetatable({
        Name   = name or "MatchaUI",
        Folder = "MatchaUI_Configs",
    }, ConfigManager)
end

function ConfigManager:Save(key, data)
    pcall(function()
        if not isfolder(self.Folder) then makefolder(self.Folder) end
        local path = self.Folder .. "/" .. key .. ".json"
        writefile(path, HttpService:JSONEncode(data))
    end)
end

function ConfigManager:Load(key)
    local ok, result = pcall(function()
        local path = self.Folder .. "/" .. key .. ".json"
        if not isfolder(self.Folder) or not isfile(path) then return nil end
        return HttpService:JSONDecode(readfile(path))
    end)
    return ok and result or nil
end

function ConfigManager:Delete(key)
    pcall(function()
        local path = self.Folder .. "/" .. key .. ".json"
        if isfolder(self.Folder) and isfile(path) then delfile(path) end
    end)
end

function ConfigManager:ListConfigs()
    local ok, files = pcall(function()
        if not isfolder(self.Folder) then return {} end
        return listfiles(self.Folder)
    end)
    local list = {}
    if ok and files then
        for _, f in ipairs(files) do
            local name = f:match("([^/\\]+)%.json$")
            if name then table.insert(list, name) end
        end
    end
    return list
end

--// ────────────────────────────────────────────────
--// Notification System
--// ────────────────────────────────────────────────
local Notifier = {}
Notifier.__index = Notifier

function Notifier.new(gui)
    local self = setmetatable({}, Notifier)
    self.Container = create("Frame", {
        Name = "Notifications",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -16, 0, 16),
        Size = UDim2.new(0, 310, 1, -32),
        BackgroundTransparency = 1,
        ZIndex = 500,
        Parent = gui,
    })
    create("UIListLayout", {
        Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Top, Parent = self.Container,
    })
    return self
end

function Notifier:Push(title, text, duration, nType)
    duration = duration or 3
    nType    = nType or "Info"
    local accentMap = {
        Info    = Library._theme.Accent,
        Success = Library._theme.Success,
        Warning = Library._theme.Warning,
        Error   = Library._theme.Error,
    }
    local accent = accentMap[nType] or accentMap.Info

    local card = create("Frame", {
        Size = UDim2.new(1, 0, 0, 56),
        BackgroundColor3 = Library._theme.Surface,
        BorderSizePixel = 0,
        ZIndex = 501,
        Parent = self.Container,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = card })
    create("UIStroke", { Color = accent, Thickness = 1.5, Parent = card })

    local bar = create("Frame", {
        Size = UDim2.new(0, 4, 0.7, 0),
        Position = UDim2.new(0, 0, 0.15, 0),
        BackgroundColor3 = accent, BorderSizePixel = 0, ZIndex = 502, Parent = card,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = bar })

    create("TextLabel", {
        Size = UDim2.new(1, -24, 0, 18), Position = UDim2.new(0, 14, 0, 7),
        BackgroundTransparency = 1, Text = title,
        TextColor3 = Library._theme.Text, TextSize = 13,
        Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 502, Parent = card,
    })
    create("TextLabel", {
        Size = UDim2.new(1, -24, 0, 22), Position = UDim2.new(0, 14, 0, 26),
        BackgroundTransparency = 1, Text = text,
        TextColor3 = Library._theme.Subtext, TextSize = 11,
        Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true, ZIndex = 502, Parent = card,
    })

    card.Position = UDim2.new(1, 40, 0, 0)
    card.BackgroundTransparency = 0.15
    tween(card, { Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 0 },
        TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))

    task.delay(duration, function()
        tween(card, { Position = UDim2.new(1, 40, 0, 0), BackgroundTransparency = 1 },
            TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
        task.delay(0.4, function() if card and card.Parent then card:Destroy() end end)
    end)
end

--// ────────────────────────────────────────────────
--// Watermark
--// ────────────────────────────────────────────────
local Watermark = {}
Watermark.__index = Watermark

function Watermark.new(gui)
    local self = setmetatable({}, Watermark)
    self.Visible = false
    self.Frame = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 12),
        Size = UDim2.new(0, 220, 0, 28),
        BackgroundColor3 = Library._theme.Surface,
        BorderSizePixel = 0,
        BackgroundTransparency = 0.05,
        Visible = false,
        ZIndex = 400,
        Parent = gui,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = self.Frame })
    create("UIStroke", { Color = Library._theme.Accent, Thickness = 1, Parent = self.Frame })
    create("UIPadding", {
        PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = self.Frame,
    })
    self.Label = create("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
        Text = "", TextColor3 = Library._theme.Text, TextSize = 11,
        Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 401, Parent = self.Frame,
    })
    return self
end

function Watermark:SetText(text)
    self.Label.Text = text
    local ts = TextService:GetTextSize(text, 11, Enum.Font.GothamMedium, Vector2.new(9999, 30))
    self.Frame.Size = UDim2.new(0, ts.X + 20, 0, 28)
end

function Watermark:Show()
    self.Visible = true
    self.Frame.Visible = true
    self.Frame.Position = UDim2.new(0.5, 0, 0, -40)
    tween(self.Frame, { Position = UDim2.new(0.5, 0, 0, 12) },
        TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
end

function Watermark:Hide()
    self.Visible = false
    tween(self.Frame, { Position = UDim2.new(0.5, 0, 0, -40) },
        TweenInfo.new(0.35, Enum.EasingStyle.Quint))
    task.delay(0.4, function() self.Frame.Visible = false end)
end

--// ────────────────────────────────────────────────
--// Keybind List
--// ────────────────────────────────────────────────
local KList = {}
KList.__index = KList

function KList.new(gui)
    local self = setmetatable({}, KList)
    self.Bindings = {}
    self.Visible = false
    self.Frame = create("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 12, 0.5, 0),
        Size = UDim2.new(0, 190, 0, 0),
        BackgroundColor3 = Library._theme.Surface,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 400,
        Parent = gui,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = self.Frame })
    create("UIStroke", { Color = Library._theme.Accent, Thickness = 1, Parent = self.Frame })
    local hdr = create("Frame", {
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundColor3 = Library._theme.Accent,
        BorderSizePixel = 0, ZIndex = 401, Parent = self.Frame,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = hdr })
    create("TextLabel", {
        Size = UDim2.new(1, -12, 1, 0), Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1, Text = "Keybinds",
        TextColor3 = Library._theme.Background, TextSize = 12,
        Font = Enum.Font.GothamBold, TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 402, Parent = hdr,
    })
    self.Content = create("Frame", {
        Size = UDim2.new(1, -12, 1, -34), Position = UDim2.new(0, 6, 0, 30),
        BackgroundTransparency = 1, ZIndex = 401, Parent = self.Frame,
    })
    create("UIListLayout", {
        Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, Parent = self.Content,
    })
    return self
end

function KList:Add(name, key) self.Bindings[name] = key; self:Refresh() end
function KList:Remove(name) self.Bindings[name] = nil; self:Refresh() end

function KList:Refresh()
    for _, c in ipairs(self.Content:GetChildren()) do
        if c:IsA("TextLabel") then c:Destroy() end
    end
    local n = 0
    for name, key in pairs(self.Bindings) do
        n = n + 1
        create("TextLabel", {
            Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1,
            Text = name .. "  [" .. key .. "]",
            TextColor3 = Library._theme.Subtext, TextSize = 11,
            Font = Enum.Font.Gotham, TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = n, ZIndex = 402, Parent = self.Content,
        })
    end
    self.Frame.Size = UDim2.new(0, 190, 0, 38 + n * 21)
end

function KList:Toggle()
    self.Visible = not self.Visible
    if self.Visible then
        self.Frame.Visible = true
        self.Frame.Position = UDim2.new(-0.2, 12, 0.5, 0)
        tween(self.Frame, { Position = UDim2.new(0, 12, 0.5, 0) },
            TweenInfo.new(0.4, Enum.EasingStyle.Quint))
    else
        tween(self.Frame, { Position = UDim2.new(-0.2, 12, 0.5, 0) },
            TweenInfo.new(0.3, Enum.EasingStyle.Quint))
        task.delay(0.35, function() self.Frame.Visible = false end)
    end
end

--// ────────────────────────────────────────────────
--// Window Class
--// ────────────────────────────────────────────────
local Window = {}
Window.__index = Window

function Library:CreateWindow(cfg)
    cfg = cfg or {}
    local self = setmetatable({}, Window)
    self.Title     = cfg.Title  or "Matcha UI"
    self.Size      = cfg.Size   or UDim2.fromOffset(650, 450)
    self.Accent    = cfg.Accent or Library._theme.Accent
    self.Tabs      = {}
    self.CurrentTab = nil
    self.Minimized = false
    self.Open      = true
    self.Keybinds  = {}
    self._connections = {}

    Library._theme.Accent = self.Accent

    -- ── ScreenGui ──
    self.Gui = create("ScreenGui", {
        Name = "MatchaUI_" .. uid(),
        DisplayOrder = 999,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        Parent = getGuiParent(),
    })

    -- ── Blur ──
    self.Blur = create("BlurEffect", { Size = 0, Name = "MatchaBlur", Parent = Lighting })

    -- ── Main Container ──
    self.Root = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.new(0, 0, 0, 0),
        BackgroundTransparency = 1,
        Parent = self.Gui,
    })

    -- Shadow
    create("ImageLabel", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 4),
        Size = UDim2.new(1, 50, 1, 50),
        BackgroundTransparency = 1,
        Image = "rbxassetid://5554236805",
        ImageColor3 = Color3.new(0, 0, 0),
        ImageTransparency = 0.55,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(23, 23, 277, 277),
        ZIndex = 0,
        Parent = self.Root,
    })

    -- Main Frame
    self.Main = create("Frame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundColor3 = Library._theme.Background,
        BorderSizePixel = 0,
        Parent = self.Root,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 12), Parent = self.Main })
    create("UIStroke", { Color = Library._theme.Border, Thickness = 1, Parent = self.Main })

    -- ── Title Bar ──
    self.TitleBar = create("Frame", {
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = Library._theme.Surface,
        BorderSizePixel = 0,
        Parent = self.Main,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 12), Parent = self.TitleBar })
    -- fix bottom corners
    create("Frame", {
        Size = UDim2.new(1, 0, 0, 10),
        Position = UDim2.new(0, 0, 1, -10),
        BackgroundColor3 = Library._theme.Surface, BorderSizePixel = 0,
        Parent = self.TitleBar,
    })

    -- accent line
    create("Frame", {
        Size = UDim2.new(1, 0, 0, 2),
        Position = UDim2.new(0, 0, 1, -2),
        BackgroundColor3 = self.Accent,
        BorderSizePixel = 0,
        ZIndex = 2,
        Parent = self.TitleBar,
    })

    -- icon
    create("ImageLabel", {
        Size = UDim2.new(0, 16, 0, 16),
        Position = UDim2.new(0, 14, 0.5, -8),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6031068420",
        ImageColor3 = self.Accent,
        Parent = self.TitleBar,
    })

    create("TextLabel", {
        Size = UDim2.new(0.5, 0, 1, -2),
        Position = UDim2.new(0, 38, 0, 0),
        BackgroundTransparency = 1,
        Text = self.Title,
        TextColor3 = Library._theme.Text,
        TextSize = 14,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.TitleBar,
    })

    -- ── Title Buttons ──
    local function titleBtn(pos, col, iconId, onClick, hoverCol)
        local btn = create("TextButton", {
            Size = UDim2.new(0, 28, 0, 28),
            Position = pos,
            BackgroundColor3 = Library._theme.SurfaceLight,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            Parent = self.TitleBar,
        })
        create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = btn })
        create("ImageLabel", {
            Size = UDim2.new(0, 11, 0, 11),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            BackgroundTransparency = 1,
            Image = iconId,
            ImageColor3 = Library._theme.Text,
            Parent = btn,
        })
        btn.MouseButton1Click:Connect(onClick)
        btn.MouseEnter:Connect(function() tween(btn, { BackgroundColor3 = hoverCol or self.Accent }, TweenInfo.new(0.15)) end)
        btn.MouseLeave:Connect(function() tween(btn, { BackgroundColor3 = Library._theme.SurfaceLight }, TweenInfo.new(0.15)) end)
        return btn
    end

    self.MinBtn = titleBtn(
        UDim2.new(1, -72, 0, 5),
        Library._theme.SurfaceLight,
        "rbxassetid://6035047377",
        function() self:ToggleMinimize() end
    )

    self.CloseBtn = titleBtn(
        UDim2.new(1, -38, 0, 5),
        Library._theme.Error,
        "rbxassetid://6035047377",
        function() self:Close() end,
        Color3.fromRGB(255, 100, 100)
    )

    -- ── Sidebar ──
    self.Sidebar = create("Frame", {
        Size = UDim2.new(0, 170, 1, -38),
        Position = UDim2.new(0, 0, 0, 38),
        BackgroundColor3 = Library._theme.Surface,
        BorderSizePixel = 0,
        Parent = self.Main,
    })

    -- search
    local sFrame = create("Frame", {
        Size = UDim2.new(1, -16, 0, 30),
        Position = UDim2.new(0, 8, 0, 8),
        BackgroundColor3 = Library._theme.Background,
        BorderSizePixel = 0,
        Parent = self.Sidebar,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = sFrame })
    create("ImageLabel", {
        Size = UDim2.new(0, 13, 0, 13),
        Position = UDim2.new(0, 9, 0.5, -6),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6031068421",
        ImageColor3 = Library._theme.Subtext,
        Parent = sFrame,
    })
    self.SearchBox = create("TextBox", {
        Size = UDim2.new(1, -30, 1, 0),
        Position = UDim2.new(0, 26, 0, 0),
        BackgroundTransparency = 1,
        PlaceholderText = "Search…",
        PlaceholderColor3 = Library._theme.Subtext,
        Text = "", TextColor3 = Library._theme.Text,
        TextSize = 11, Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Parent = sFrame,
    })

    -- divider
    create("Frame", {
        Size = UDim2.new(1, -16, 0, 1),
        Position = UDim2.new(0, 8, 0, 44),
        BackgroundColor3 = Library._theme.Border,
        BorderSizePixel = 0,
        Parent = self.Sidebar,
    })

    -- tab buttons scroll
    self.TabBtns = create("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, -56),
        Position = UDim2.new(0, 0, 0, 52),
        BackgroundTransparency = 1,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = self.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        BorderSizePixel = 0,
        Parent = self.Sidebar,
    })
    create("UIPadding", {
        PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 2),
        Parent = self.TabBtns,
    })
    create("UIListLayout", {
        Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, Parent = self.TabBtns,
    })

    -- ── Content Area ──
    self.Content = create("Frame", {
        Size = UDim2.new(1, -170, 1, -38),
        Position = UDim2.new(0, 170, 0, 38),
        BackgroundTransparency = 1,
        Parent = self.Main,
    })

    -- ── Drag ──
    self:_setupDrag()

    -- ── Search Filter ──
    self.SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local q = self.SearchBox.Text:lower()
        for _, tab in ipairs(self.Tabs) do
            for _, el in ipairs(tab._elements or {}) do
                if el._frame and el._name then
                    el._frame.Visible = (q == "") or el._name:lower():find(q, 1, true) ~= nil
                end
            end
        end
    end)

    -- ── Mobile Reopen Button ──
    self:_createMobileReopen()

    -- ── Sub-systems ──
    self.Notifier = Notifier.new(self.Gui)
    self.WatermarkObj = Watermark.new(self.Gui)
    self.KeybindList = KList.new(self.Gui)
    self.Config = ConfigManager.new(self.Title)

    -- ── Open Animation ──
    tween(self.Root, { Size = self.Size },
        TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))
    tween(self.Blur, { Size = 18 },
        TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out))

    table.insert(Library._windows, self)
    return self
end

-- ── Dragging ──
function Window:_setupDrag()
    local dragging, dragStart, startPos
    local conn1, conn2, conn3

    self.TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = self.Root.Position
        end
    end)

    self.TitleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    conn1 = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            self.Root.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)

    table.insert(self._connections, conn1)
end

-- ── Mobile reopen ──
function Window:_createMobileReopen()
    if not isMobile then return end
    local btn = create("TextButton", {
        Size = UDim2.new(0, 48, 0, 48),
        Position = UDim2.new(1, -64, 1, -64),
        BackgroundColor3 = self.Accent,
        BorderSizePixel = 0,
        Text = "", Visible = false,
        ZIndex = 400,
        Parent = self.Gui,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 24), Parent = btn })
    create("ImageLabel", {
        Size = UDim2.new(0, 18, 0, 18),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6031280882",
        ImageColor3 = Library._theme.Text,
        Parent = btn,
    })
    self._mobileBtn = btn
    btn.MouseButton1Click:Connect(function()
        self:Show()
        btn.Visible = false
    end)
end

-- ── Toggle Minimize ──
function Window:ToggleMinimize()
    self.Minimized = not self.Minimized
    if self.Minimized then
        self.Sidebar.Visible   = false
        self.Content.Visible   = false
        tween(self.Root, { Size = UDim2.new(0, self.Size.X.Offset, 0, 38) },
            TweenInfo.new(0.35, Enum.EasingStyle.Quint))
        tween(self.Blur, { Size = 0 }, TweenInfo.new(0.3))
    else
        self.Sidebar.Visible = true
        self.Content.Visible = true
        tween(self.Root, { Size = self.Size },
            TweenInfo.new(0.35, Enum.EasingStyle.Quint))
        tween(self.Blur, { Size = 18 }, TweenInfo.new(0.3))
    end
end

function Window:Close()
    self.Open = false
    tween(self.Root, { Size = UDim2.new(0, 0, 0, 0) },
        TweenInfo.new(0.35, Enum.EasingStyle.Quint))
    tween(self.Blur, { Size = 0 }, TweenInfo.new(0.3))
    task.delay(0.4, function()
        pcall(function() self.Gui:Destroy() end)
        pcall(function() self.Blur:Destroy() end)
    end)
end

function Window:Show()
    if self.Open then return end
    self.Open = true
    self.Root.Size = UDim2.new(0, 0, 0, 0)
    self.Root.Visible = true
    tween(self.Root, { Size = self.Size },
        TweenInfo.new(0.45, Enum.EasingStyle.Quint))
    tween(self.Blur, { Size = 18 }, TweenInfo.new(0.4))
end

function Window:Minimize()
    if not self.Minimized then self:ToggleMinimize() end
end

function Window:Unminimize()
    if self.Minimized then self:ToggleMinimize() end
end

--// ────────────────────────────────────────────────
--// Tab Creation
--// ────────────────────────────────────────────────
function Window:CreateTab(cfg)
    if type(cfg) == "string" then cfg = { Name = cfg } end
    cfg = cfg or {}
    local tabName = cfg.Name or "Tab"
    local tabIcon = cfg.Icon  or "rbxassetid://6031068421"

    local tab = {}
    tab._name      = tabName
    tab._elements  = {}
    tab._order     = #self.Tabs + 1
    tab._window    = self

    -- Button
    tab._btn = create("TextButton", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = tab._order,
        Parent = self.TabBtns,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = tab._btn })

    tab._indicator = create("Frame", {
        Size = UDim2.new(0, 3, 0.55, 0),
        Position = UDim2.new(0, 0, 0.225, 0),
        BackgroundColor3 = self.Accent,
        BorderSizePixel = 0,
        Visible = false,
        Parent = tab._btn,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 2), Parent = tab._indicator })

    tab._icon = create("ImageLabel", {
        Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new(0, 10, 0.5, -7),
        BackgroundTransparency = 1,
        Image = tabIcon,
        ImageColor3 = Library._theme.Subtext,
        Parent = tab._btn,
    })

    tab._label = create("TextLabel", {
        Size = UDim2.new(1, -30, 1, 0),
        Position = UDim2.new(0, 30, 0, 0),
        BackgroundTransparency = 1,
        Text = tabName,
        TextColor3 = Library._theme.Subtext,
        TextSize = 12,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = tab._btn,
    })

    -- Content scroll
    tab._scroll = create("ScrollingFrame", {
        Size = UDim2.new(1, -16, 1, -16),
        Position = UDim2.new(0, 8, 0, 8),
        BackgroundTransparency = 1,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = self.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        BorderSizePixel = 0,
        Parent = self.Content,
    })
    create("UIListLayout", {
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = tab._scroll,
    })
    create("UIPadding", {
        PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4), Parent = tab._scroll,
    })

    -- Events
    tab._btn.MouseButton1Click:Connect(function() self:_selectTab(tab) end)
    tab._btn.MouseEnter:Connect(function()
        if self.CurrentTab ~= tab then
            tween(tab._btn, { BackgroundTransparency = 0.88 }, TweenInfo.new(0.15))
        end
    end)
    tab._btn.MouseLeave:Connect(function()
        if self.CurrentTab ~= tab then
            tween(tab._btn, { BackgroundTransparency = 1 }, TweenInfo.new(0.15))
        end
    end)

    -- Component methods
    tab.CreateSection       = function(_, s) return self:_createSection(tab, s) end
    tab.CreateButton        = function(_, c) return self:_createButton(tab, c) end
    tab.CreateToggle        = function(_, c) return self:_createToggle(tab, c) end
    tab.CreateSlider        = function(_, c) return self:_createSlider(tab, c) end
    tab.CreateDropdown      = function(_, c) return self:_createDropdown(tab, c) end
    tab.CreateMultiDropdown = function(_, c) return self:_createMultiDropdown(tab, c) end
    tab.CreateTextbox       = function(_, c) return self:_createTextbox(tab, c) end
    tab.CreateKeybind       = function(_, c) return self:_createKeybind(tab, c) end
    tab.CreateColorPicker   = function(_, c) return self:_createColorPicker(tab, c) end
    tab.CreateLabel         = function(_, c) return self:_createLabel(tab, c) end
    tab.CreateParagraph     = function(_, c) return self:_createParagraph(tab, c) end
    tab.CreateDivider       = function(_)    return self:_createDivider(tab) end

    table.insert(self.Tabs, tab)

    if #self.Tabs == 1 then
        task.defer(function() self:_selectTab(tab) end)
    end

    return tab
end

function Window:_selectTab(tab)
    if self.CurrentTab == tab then return end
    local prev = self.CurrentTab
    if prev then
        tween(prev._btn,       { BackgroundTransparency = 1 }, TweenInfo.new(0.2))
        tween(prev._label,     { TextColor3 = Library._theme.Subtext }, TweenInfo.new(0.2))
        tween(prev._icon,      { ImageColor3 = Library._theme.Subtext }, TweenInfo.new(0.2))
        prev._indicator.Visible = false
        prev._scroll.Visible    = false
    end
    self.CurrentTab = tab
    tween(tab._btn,   { BackgroundTransparency = 0.82 }, TweenInfo.new(0.2))
    tween(tab._label, { TextColor3 = Library._theme.Text }, TweenInfo.new(0.2))
    tween(tab._icon,  { ImageColor3 = self.Accent }, TweenInfo.new(0.2))
    tab._indicator.Visible = true
    tab._scroll.Visible    = true
    tab._scroll.CanvasPosition = Vector2.new(0, 0)
end

--// ────────────────────────────────────────────────
--// Element Helpers
--// ────────────────────────────────────────────────
local function _order(tab) return #tab._elements * 10 + 10 end

local function _card(tab, name, h)
    local o = _order(tab)
    local f = create("Frame", {
        Size = UDim2.new(1, 0, 0, h),
        BackgroundColor3 = Library._theme.Surface,
        BorderSizePixel = 0,
        LayoutOrder = o,
        Parent = tab._scroll,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = f })
    local el = { _frame = f, _name = name or "" }
    table.insert(tab._elements, el)
    return f, el, o
end

--// ────────────────────────────────────────────────
--// Section
--// ────────────────────────────────────────────────
function Window:_createSection(tab, text)
    local o = _order(tab)
    local f = create("Frame", {
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
        LayoutOrder = o,
        Parent = tab._scroll,
    })
    create("TextLabel", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = text:upper(),
        TextColor3 = self.Accent,
        TextSize = 11,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = f,
    })
    local el = { _frame = f, _name = text }
    table.insert(tab._elements, el)
    return el
end

--// ────────────────────────────────────────────────
--// Label
--// ────────────────────────────────────────────────
function Window:_createLabel(tab, cfg)
    if type(cfg) == "string" then cfg = { Text = cfg } end
    cfg = cfg or {}
    local o = _order(tab)
    local f = create("Frame", {
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundTransparency = 1,
        LayoutOrder = o,
        Parent = tab._scroll,
    })
    local lbl = create("TextLabel", {
        Size = UDim2.new(1, -8, 1, 0),
        Position = UDim2.new(0, 4, 0, 0),
        BackgroundTransparency = 1,
        Text = cfg.Text or "Label",
        TextColor3 = cfg.Color or Library._theme.Text,
        TextSize = cfg.TextSize or 13,
        Font = cfg.Font or Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = f,
    })
    local el = { _frame = f, _name = cfg.Text or "Label" }
    table.insert(tab._elements, el)
    el.SetText = function(_, t) lbl.Text = t end
    return el
end

--// ────────────────────────────────────────────────
--// Paragraph
--// ────────────────────────────────────────────────
function Window:_createParagraph(tab, cfg)
    if type(cfg) == "string" then cfg = { Title = cfg, Content = "" } end
    cfg = cfg or {}
    local f, el = _card(tab, cfg.Title or "", 0)
    f.AutomaticSize = Enum.AutomaticSize.Y
    create("UIPadding", {
        PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), Parent = f,
    })
    create("UIListLayout", {
        Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = f,
    })
    local ttl = create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = cfg.Title or "",
        TextColor3 = Library._theme.Text,
        TextSize = 13, Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 1, Parent = f,
    })
    local body = create("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0),
        BackgroundTransparency = 1,
        Text = cfg.Content or "",
        TextColor3 = Library._theme.Subtext,
        TextSize = 11, Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        AutomaticSize = Enum.AutomaticSize.Y,
        LayoutOrder = 2, Parent = f,
    })
    el.SetTitle   = function(_, t) ttl.Text = t end
    el.SetContent = function(_, t) body.Text = t end
    return el
end

--// ────────────────────────────────────────────────
--// Divider
--// ────────────────────────────────────────────────
function Window:_createDivider(tab)
    local o = _order(tab)
    local f = create("Frame", {
        Size = UDim2.new(1, 0, 0, 8),
        BackgroundTransparency = 1,
        LayoutOrder = o,
        Parent = tab._scroll,
    })
    create("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 0.5, 0),
        BackgroundColor3 = Library._theme.Border,
        BorderSizePixel = 0,
        Parent = f,
    })
    local el = { _frame = f, _name = "" }
    table.insert(tab._elements, el)
    return el
end

--// ────────────────────────────────────────────────
--// Button
--// ────────────────────────────────────────────────
function Window:_createButton(tab, cfg)
    cfg = cfg or {}
    local cb = cfg.Callback or function() end
    local name = cfg.Name or "Button"
    local f, el = _card(tab, name, 36)

    local btn = create("TextButton", {
        Size = UDim2.new(1, -10, 1, -6),
        Position = UDim2.new(0, 5, 0, 3),
        BackgroundColor3 = Library._theme.SurfaceLight,
        BorderSizePixel = 0,
        Text = "", AutoButtonColor = false,
        Parent = f,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = btn })

    create("TextLabel", {
        Size = UDim2.new(1, -24, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = Library._theme.Text,
        TextSize = 12, Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = btn,
    })

    create("ImageLabel", {
        Size = UDim2.new(0, 12, 0, 12),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6039090217",
        ImageColor3 = Library._theme.Subtext,
        Parent = btn,
    })

    local function lighten(c, amt)
        return Color3.new(
            math.min(c.R + amt, 1),
            math.min(c.G + amt, 1),
            math.min(c.B + amt, 1))
    end

    btn.MouseButton1Click:Connect(function()
        rippleEffect(btn, btn.AbsolutePosition.X + btn.AbsoluteSize.X / 2,
            btn.AbsolutePosition.Y + btn.AbsoluteSize.Y / 2)
        tween(btn, { BackgroundColor3 = self.Accent }, TweenInfo.new(0.08))
        task.delay(0.12, function()
            tween(btn, { BackgroundColor3 = Library._theme.SurfaceLight }, TweenInfo.new(0.2))
        end)
        cb()
    end)
    btn.MouseEnter:Connect(function()
        tween(btn, { BackgroundColor3 = lighten(Library._theme.SurfaceLight, 0.03) }, TweenInfo.new(0.15))
    end)
    btn.MouseLeave:Connect(function()
        tween(btn, { BackgroundColor3 = Library._theme.SurfaceLight }, TweenInfo.new(0.15))
    end)

    el._button = btn
    el.Callback = cb
    return el
end

--// ────────────────────────────────────────────────
--// Toggle
--// ────────────────────────────────────────────────
function Window:_createToggle(tab, cfg)
    cfg = cfg or {}
    local name     = cfg.Name     or "Toggle"
    local default  = cfg.Default  or false
    local cb       = cfg.Callback or function() end
    local f, el = _card(tab, name, 40)

    local state = default

    local hit = create("TextButton", {
        Size = UDim2.new(1, -10, 1, -6),
        Position = UDim2.new(0, 5, 0, 3),
        BackgroundTransparency = 1,
        Text = "", AutoButtonColor = false,
        Parent = f,
    })

    create("TextLabel", {
        Size = UDim2.new(0.75, 0, 1, 0),
        Position = UDim2.new(0, 6, 0, 0),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = Library._theme.Text,
        TextSize = 12, Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = hit,
    })

    local bg = create("Frame", {
        Size = UDim2.new(0, 38, 0, 20),
        Position = UDim2.new(1, -44, 0.5, -10),
        BackgroundColor3 = state and self.Accent or Library._theme.SurfaceLight,
        BorderSizePixel = 0,
        Parent = hit,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = bg })

    local dot = create("Frame", {
        Size = UDim2.new(0, 16, 0, 16),
        Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
        BackgroundColor3 = Library._theme.Text,
        BorderSizePixel = 0,
        Parent = bg,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = dot })

    local function refresh()
        tween(bg, { BackgroundColor3 = state and self.Accent or Library._theme.SurfaceLight },
            TweenInfo.new(0.2))
        tween(dot, { Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8) },
            TweenInfo.new(0.25, Enum.EasingStyle.Quint))
        cb(state)
    end

    hit.MouseButton1Click:Connect(function()
        state = not state
        refresh()
    end)

    if default then refresh() end

    el.SetValue  = function(_, v) state = v; refresh() end
    el.GetValue  = function(_) return state end
    el.SetCallback = function(_, c) cb = c end
    return el
end

--// ────────────────────────────────────────────────
--// Slider
--// ────────────────────────────────────────────────
function Window:_createSlider(tab, cfg)
    cfg = cfg or {}
    local name    = cfg.Name    or "Slider"
    local min     = cfg.Min     or 0
    local max     = cfg.Max     or 100
    local def     = cfg.Default or min
    local cb      = cfg.Callback or function() end
    local suffix  = cfg.Suffix  or ""
    local rounding = cfg.Rounding or 0
    local f, el = _card(tab, name, 50)

    local cur = def

    create("TextLabel", {
        Size = UDim2.new(0.65, 0, 0, 16),
        Position = UDim2.new(0, 12, 0, 5),
        BackgroundTransparency = 1,
        Text = name,
        TextColor3 = Library._theme.Text,
        TextSize = 12, Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = f,
    })

    local valLabel = create("TextLabel", {
        Size = UDim2.new(0.35, -14, 0, 16),
        Position = UDim2.new(0.65, 0, 0, 5),
        BackgroundTransparency = 1,
        Text = tostring(cur) .. suffix,
        TextColor3 = self.Accent,
        TextSize = 12, Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = f,
    })

    local track = create("Frame", {
        Size = UDim2.new(1, -24, 0, 5),
        Position = UDim2.new(0, 12, 0, 30),
        BackgroundColor3 = Library._theme.SurfaceLight,
        BorderSizePixel = 0,
        Parent = f,
    })
    create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })

    local fill = create("Frame", {
        Size = UDim2.new((cur - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = self.Accent,
        BorderSizePixel = 0,
        Parent = track,
    })
    create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })

    local knob = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(0, 14, 0, 14),
        Position = UDim2.new((cur - min) / (max - min), 0, 0.5, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = track,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = knob })

    local sliding = false

    local function update(input)
        local frac = math.clamp(
            (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local raw  = min + (max - min) * frac
        cur = math.floor(raw / (10 ^ rounding) + 0.5) * (10 ^ rounding)
        cur = math.clamp(cur, min, max)
        local nf = (cur - min) / (max - min)
        fill.Size   = UDim2.new(nf, 0, 1, 0)
        knob.Position = UDim2.new(nf, 0, 0.5, 0)
        valLabel.Text = tostring(cur) .. suffix
        cb(cur)
    end

    local c1, c2, c3
    c1 = track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            sliding = true; update(input)
        end
    end)
    c2 = track.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            sliding = false
        end
    end)
    c3 = UserInputService.InputChanged:Connect(function(input)
        if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)

    table.insert(self._connections, c1)
    table.insert(self._connections, c2)
    table.insert(self._connections, c3)

    el.SetValue  = function(_, v)
        cur = math.clamp(v, min, max)
        local nf = (cur - min) / (max - min)
        fill.Size     = UDim2.new(nf, 0, 1, 0)
        knob.Position = UDim2.new(nf, 0, 0.5, 0)
        valLabel.Text = tostring(cur) .. suffix
        cb(cur)
    end
    el.GetValue = function(_) return cur end
    el.SetCallback = function(_, c) cb = c end

    cb(cur)
    return el
end

--// ────────────────────────────────────────────────
--// Dropdown
--// ────────────────────────────────────────────────
function Window:_createDropdown(tab, cfg)
    cfg = cfg or {}
    local name    = cfg.Name    or "Dropdown"
    local opts    = cfg.Options or { "A", "B", "C" }
    local def     = cfg.Default or opts[1]
    local cb      = cfg.Callback or function() end
    local f, el = _card(tab, name, 64)

    local opened  = false
    local current = def
    local HOPT    = 28
    local MAX_H   = 160

    create("TextLabel", {
        Size = UDim2.new(0.7, 0, 0, 16),
        Position = UDim2.new(0, 12, 0, 6),
        BackgroundTransparency = 1,
        Text = name, TextColor3 = Library._theme.Text,
        TextSize = 12, Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = f,
    })

    local btn = create("TextButton", {
        Size = UDim2.new(1, -24, 0, 28),
        Position = UDim2.new(0, 12, 0, 26),
        BackgroundColor3 = Library._theme.SurfaceLight,
        BorderSizePixel = 0, Text = "", AutoButtonColor = false,
        Parent = f,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = btn })

    local selLbl = create("TextLabel", {
        Size = UDim2.new(1, -30, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = current,
        TextColor3 = Library._theme.Text,
        TextSize = 11, Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClipsDescendants = true,
        Parent = btn,
    })

    local arrow = create("ImageLabel", {
        Size = UDim2.new(0, 10, 0, 10),
        Position = UDim2.new(1, -18, 0.5, -5),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6035047377",
        ImageColor3 = Library._theme.Subtext,
        Parent = btn,
    })

    local panel = create("Frame", {
        Size = UDim2.new(1, -24, 0, 0),
        Position = UDim2.new(0, 12, 0, 58),
        BackgroundColor3 = Library._theme.Background,
        BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 12,
        Parent = f,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = panel })
    create("UIStroke", { Color = Library._theme.Border, Thickness = 1, Parent = panel })

    local scroller = create("ScrollingFrame", {
        Size = UDim2.new(1, -4, 1, -4), Position = UDim2.new(0, 2, 0, 2),
        BackgroundTransparency = 1,
        ScrollBarThickness = 3, ScrollBarImageColor3 = self.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ZIndex = 12, Parent = panel,
    })
    create("UIListLayout", {
        Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = scroller,
    })

    local function buildOpts()
        for _, c in ipairs(scroller:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for i, opt in ipairs(opts) do
            local ob = create("TextButton", {
                Size = UDim2.new(1, 0, 0, HOPT),
                BackgroundColor3 = (opt == current) and self.Accent or Color3.new(0, 0, 0),
                BackgroundTransparency = (opt == current) and 0.82 or 1,
                BorderSizePixel = 0, Text = "",
                LayoutOrder = i, ZIndex = 12, Parent = scroller,
            })
            create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = ob })
            create("TextLabel", {
                Size = UDim2.new(1, -14, 1, 0), Position = UDim2.new(0, 8, 0, 0),
                BackgroundTransparency = 1, Text = opt,
                TextColor3 = (opt == current) and self.Accent or Library._theme.Text,
                TextSize = 11, Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 12, Parent = ob,
            })
            ob.MouseButton1Click:Connect(function()
                current = opt; selLbl.Text = opt
                cb(current); buildOpts()
                opened = false
                tween(panel, { Size = UDim2.new(1, -24, 0, 0) }, TweenInfo.new(0.2, Enum.EasingStyle.Quint))
                tween(arrow, { Rotation = 0 }, TweenInfo.new(0.2))
                tween(f, { Size = UDim2.new(1, 0, 0, 64) }, TweenInfo.new(0.2, Enum.EasingStyle.Quint))
            end)
        end
    end

    btn.MouseButton1Click:Connect(function()
        opened = not opened
        if opened then
            buildOpts()
            local h = math.min(#opts * (HOPT + 2) + 4, MAX_H)
            tween(panel, { Size = UDim2.new(1, -24, 0, h) }, TweenInfo.new(0.22, Enum.EasingStyle.Quint))
            tween(arrow, { Rotation = 180 }, TweenInfo.new(0.22))
            tween(f, { Size = UDim2.new(1, 0, 0, 64 + h) }, TweenInfo.new(0.22, Enum.EasingStyle.Quint))
        else
            tween(panel, { Size = UDim2.new(1, -24, 0, 0) }, TweenInfo.new(0.2, Enum.EasingStyle.Quint))
            tween(arrow, { Rotation = 0 }, TweenInfo.new(0.2))
            tween(f, { Size = UDim2.new(1, 0, 0, 64) }, TweenInfo.new(0.2, Enum.EasingStyle.Quint))
        end
    end)

    buildOpts()

    el.SetValue = function(_, v) current = v; selLbl.Text = v; buildOpts(); cb(current) end
    el.GetValue = function(_) return current end
    el.Refresh  = function(_, newOpts)
        opts = newOpts
        if not table.find(opts, current) then
            current = opts[1] or ""; selLbl.Text = current
        end
        buildOpts()
    end
    el.SetCallback = function(_, c) cb = c end
    return el
end

--// ────────────────────────────────────────────────
--// Multi Dropdown
--// ────────────────────────────────────────────────
function Window:_createMultiDropdown(tab, cfg)
    cfg = cfg or {}
    local name = cfg.Name    or "Multi Dropdown"
    local opts = cfg.Options or { "A", "B", "C" }
    local def  = cfg.Default or {}
    local cb   = cfg.Callback or function() end
    local f, el = _card(tab, name, 64)

    local opened = false
    local chosen = {}
    for _, v in ipairs(def) do chosen[#chosen + 1] = v end
    local HOPT  = 28
    local MAX_H = 160

    create("TextLabel", {
        Size = UDim2.new(0.7, 0, 0, 16),
        Position = UDim2.new(0, 12, 0, 6),
        BackgroundTransparency = 1,
        Text = name, TextColor3 = Library._theme.Text,
        TextSize = 12, Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = f,
    })

    local btn = create("TextButton", {
        Size = UDim2.new(1, -24, 0, 28),
        Position = UDim2.new(0, 12, 0, 26),
        BackgroundColor3 = Library._theme.SurfaceLight,
        BorderSizePixel = 0, Text = "", AutoButtonColor = false, Parent = f,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = btn })

    local selLbl = create("TextLabel", {
        Size = UDim2.new(1, -30, 1, 0), Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = #chosen > 0 and table.concat(chosen, ", ") or "None",
        TextColor3 = Library._theme.Text, TextSize = 11, Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClipsDescendants = true, Parent = btn,
    })

    local arrow = create("ImageLabel", {
        Size = UDim2.new(0, 10, 0, 10),
        Position = UDim2.new(1, -18, 0.5, -5),
        BackgroundTransparency = 1,
        Image = "rbxassetid://6035047377",
        ImageColor3 = Library._theme.Subtext, Parent = btn,
    })

    local panel = create("Frame", {
        Size = UDim2.new(1, -24, 0, 0),
        Position = UDim2.new(0, 12, 0, 58),
        BackgroundColor3 = Library._theme.Background,
        BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 12, Parent = f,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = panel })
    create("UIStroke", { Color = Library._theme.Border, Thickness = 1, Parent = panel })

    local scroller = create("ScrollingFrame", {
        Size = UDim2.new(1, -4, 1, -4), Position = UDim2.new(0, 2, 0, 2),
        BackgroundTransparency = 1,
        ScrollBarThickness = 3, ScrollBarImageColor3 = self.Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 12, Parent = panel,
    })
    create("UIListLayout", {
        Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = scroller,
    })

    local function has(v) return table.find(chosen, v) ~= nil end

    local function refreshLabel()
        selLbl.Text = #chosen > 0 and table.concat(chosen, ", ") or "None"
    end

    local function buildOpts()
        for _, c in ipairs(scroller:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        for i, opt in ipairs(opts) do
            local sel = has(opt)
            local ob = create("TextButton", {
                Size = UDim2.new(1, 0, 0, HOPT),
                BackgroundColor3 = sel and self.Accent or Color3.new(0, 0, 0),
                BackgroundTransparency = sel and 0.82 or 1,
                BorderSizePixel = 0, Text = "",
                LayoutOrder = i, ZIndex = 12, Parent = scroller,
            })
            create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = ob })
            create("TextLabel", {
                Size = UDim2.new(1, -34, 1, 0), Position = UDim2.new(0, 8, 0, 0),
                BackgroundTransparency = 1, Text = opt,
                TextColor3 = Library._theme.Text,
                TextSize = 11, Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 12, Parent = ob,
            })
            local cbx = create("Frame", {
                Size = UDim2.new(0, 14, 0, 14),
                Position = UDim2.new(1, -22, 0.5, -7),
                BackgroundColor3 = sel and self.Accent or Library._theme.SurfaceLight,
                BorderSizePixel = 0, ZIndex = 12, Parent = ob,
            })
            create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = cbx })
            if sel then
                create("ImageLabel", {
                    Size = UDim2.new(0, 8, 0, 8),
                    AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.new(0.5, 0, 0.5, 0),
                    BackgroundTransparency = 1,
                    Image = "rbxassetid://6031068420",
                    ImageColor3 = Library._theme.Text, ZIndex = 13, Parent = cbx,
                })
            end
            ob.MouseButton1Click:Connect(function()
                if has(opt) then
                    local idx = table.find(chosen, opt)
                    if idx then table.remove(chosen, idx) end
                else
                    chosen[#chosen + 1] = opt
                end
                refreshLabel(); cb(chosen); buildOpts()
            end)
        end
    end

    btn.MouseButton1Click:Connect(function()
        opened = not opened
        if opened then
            buildOpts()
            local h = math.min(#opts * (HOPT + 2) + 4, MAX_H)
            tween(panel, { Size = UDim2.new(1, -24, 0, h) }, TweenInfo.new(0.22, Enum.EasingStyle.Quint))
            tween(arrow, { Rotation = 180 }, TweenInfo.new(0.22))
            tween(f, { Size = UDim2.new(1, 0, 0, 64 + h) }, TweenInfo.new(0.22, Enum.EasingStyle.Quint))
        else
            tween(panel, { Size = UDim2.new(1, -24, 0, 0) }, TweenInfo.new(0.2, Enum.EasingStyle.Quint))
            tween(arrow, { Rotation = 0 }, TweenInfo.new(0.2))
            tween(f, { Size = UDim2.new(1, 0, 0, 64) }, TweenInfo.new(0.2, Enum.EasingStyle.Quint))
        end
    end)

    buildOpts()

    el.SetValue = function(_, v) chosen = v; refreshLabel(); buildOpts(); cb(chosen) end
    el.GetValue = function(_) return chosen end
    el.Refresh  = function(_, newOpts)
        opts = newOpts
        local fresh = {}
        for _, v in ipairs(chosen) do
            if table.find(opts, v) then fresh[#fresh + 1] = v end
        end
        chosen = fresh; refreshLabel(); buildOpts()
    end
    el.SetCallback = function(_, c) cb = c end
    return el
end

--// ────────────────────────────────────────────────
--// Textbox
--// ────────────────────────────────────────────────
function Window:_createTextbox(tab, cfg)
    cfg = cfg or {}
    local name = cfg.Name        or "Textbox"
    local def  = cfg.Default     or ""
    local ph   = cfg.Placeholder or "Type here…"
    local cb   = cfg.Callback    or function() end
    local clear = cfg.ClearOnFocus or false
    local f, el = _card(tab, name, 60)

    local cur = def

    create("TextLabel", {
        Size = UDim2.new(1, -20, 0, 16),
        Position = UDim2.new(0, 12, 0, 5),
        BackgroundTransparency = 1,
        Text = name, TextColor3 = Library._theme.Text,
        TextSize = 12, Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = f,
    })

    local box = create("Frame", {
        Size = UDim2.new(1, -24, 0, 28),
        Position = UDim2.new(0, 12, 0, 26),
        BackgroundColor3 = Library._theme.SurfaceLight,
        BorderSizePixel = 0, Parent = f,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = box })
    create("UIPadding", {
        PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = box,
    })

    local tb = create("TextBox", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = def, PlaceholderText = ph,
        PlaceholderColor3 = Library._theme.Subtext,
        TextColor3 = Library._theme.Text,
        TextSize = 12, Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = clear, Parent = box,
    })

    tb.Focused:Connect(function()
        tween(box, { BackgroundColor3 = Library._theme.Background }, TweenInfo.new(0.15))
    end)
    tb.FocusLost:Connect(function()
        tween(box, { BackgroundColor3 = Library._theme.SurfaceLight }, TweenInfo.new(0.15))
        cur = tb.Text; cb(cur)
    end)

    el.SetValue    = function(_, v) cur = v; tb.Text = v; cb(cur) end
    el.GetValue    = function(_) return cur end
    el.SetCallback = function(_, c) cb = c end
    return el
end

--// ────────────────────────────────────────────────
--// Keybind
--// ────────────────────────────────────────────────
function Window:_createKeybind(tab, cfg)
    cfg = cfg or {}
    local name = cfg.Name        or "Keybind"
    local def  = cfg.Default     or "None"
    local cb   = cfg.Callback    or function() end
    local keyCb = cfg.KeyCallback or function() end
    local f, el = _card(tab, name, 40)

    local cur    = def
    local listen = false

    create("TextLabel", {
        Size = UDim2.new(0.6, 0, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = name, TextColor3 = Library._theme.Text,
        TextSize = 12, Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = f,
    })

    local kBtn = create("TextButton", {
        Size = UDim2.new(0, 80, 0, 24),
        Position = UDim2.new(1, -92, 0.5, -12),
        BackgroundColor3 = Library._theme.SurfaceLight,
        BorderSizePixel = 0, Text = "", AutoButtonColor = false, Parent = f,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = kBtn })

    local kLbl = create("TextLabel", {
        Size = UDim2.new(1, -8, 1, 0),
        Position = UDim2.new(0, 4, 0, 0),
        BackgroundTransparency = 1,
        Text = cur, TextColor3 = self.Accent,
        TextSize = 11, Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Center,
        Parent = kBtn,
    })

    kBtn.MouseButton1Click:Connect(function()
        listen = true
        kLbl.Text = "…"
        kLbl.TextColor3 = Library._theme.Warning
        tween(kBtn, { BackgroundColor3 = self.Accent }, TweenInfo.new(0.15))
    end)

    local conn = UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if listen then
            local kn = input.KeyCode.Name
            if input.UserInputType == Enum.UserInputType.MouseButton1 then kn = "Mouse1"
            elseif input.UserInputType == Enum.UserInputType.MouseButton2 then kn = "Mouse2"
            elseif input.UserInputType == Enum.UserInputType.MouseButton3 then kn = "Mouse3"
            end
            if kn ~= "Unknown" then
                cur = kn; kLbl.Text = cur; kLbl.TextColor3 = self.Accent
                listen = false
                tween(kBtn, { BackgroundColor3 = Library._theme.SurfaceLight }, TweenInfo.new(0.15))
                if self.KeybindList then
                    self.KeybindList:Remove(name)
                    self.KeybindList:Add(name, cur)
                end
                cb(cur)
            end
        elseif not listen and cur ~= "None" then
            local kn = input.KeyCode.Name
            if input.UserInputType == Enum.UserInputType.MouseButton1 then kn = "Mouse1" end
            if kn == cur then keyCb() end
        end
    end)
    table.insert(self._connections, conn)

    if self.KeybindList then self.KeybindList:Add(name, cur) end

    el.SetValue = function(_, v)
        cur = v; kLbl.Text = v
        if self.KeybindList then self.KeybindList:Remove(name); self.KeybindList:Add(name, cur) end
    end
    el.GetValue    = function(_) return cur end
    el.SetCallback = function(_, c) cb = c end
    el.SetKeyCallback = function(_, c) keyCb = c end
    return el
end

--// ────────────────────────────────────────────────
--// Color Picker
--// ────────────────────────────────────────────────
function Window:_createColorPicker(tab, cfg)
    cfg = cfg or {}
    local name = cfg.Name    or "Color Picker"
    local def  = cfg.Default or Color3.fromRGB(255, 255, 255)
    local cb   = cfg.Callback or function() end
    local f, el = _card(tab, name, 42)

    local opened   = false
    local curColor = def
    local PANEL_H  = 200

    create("TextLabel", {
        Size = UDim2.new(0.6, 0, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1,
        Text = name, TextColor3 = Library._theme.Text,
        TextSize = 12, Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = f,
    })

    local preview = create("TextButton", {
        Size = UDim2.new(0, 28, 0, 28),
        Position = UDim2.new(1, -40, 0.5, -14),
        BackgroundColor3 = curColor,
        BorderSizePixel = 0, Text = "", AutoButtonColor = false, Parent = f,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 7), Parent = preview })
    create("UIStroke", { Color = Library._theme.Border, Thickness = 1, Parent = preview })

    local panel = create("Frame", {
        Size = UDim2.new(1, -24, 0, 0),
        Position = UDim2.new(0, 12, 0, 42),
        BackgroundColor3 = Library._theme.Background,
        BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 14, Parent = f,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = panel })
    create("UIStroke", { Color = Library._theme.Border, Thickness = 1, Parent = panel })

    -- ── Sat / Brightness Pad ──
    local pad = create("Frame", {
        Size = UDim2.new(1, -16, 0, 110),
        Position = UDim2.new(0, 8, 0, 8),
        BackgroundColor3 = Color3.fromHSV(0, 1, 1),
        BorderSizePixel = 0, ZIndex = 15, Parent = panel,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = pad })

    create("UIGradient", {
        Color = ColorSequence.new(Color3.new(1, 1, 1)),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0),
        }),
        Parent = pad,
    })
    create("UIGradient", {
        Color = ColorSequence.new(Color3.new(0, 0, 0)),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0),
        }),
        Rotation = 90, Parent = pad,
    })

    local cursor = create("Frame", {
        Size = UDim2.new(0, 10, 0, 10),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0, ZIndex = 16, Parent = pad,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = cursor })
    create("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1.5, Parent = cursor })

    -- ── Hue Strip ──
    local hueBar = create("Frame", {
        Size = UDim2.new(1, -16, 0, 10),
        Position = UDim2.new(0, 8, 0, 124),
        BorderSizePixel = 0, ZIndex = 15, Parent = panel,
    })
    create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = hueBar })
    create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
            ColorSequenceKeypoint.new(1 / 6, Color3.fromRGB(255, 255, 0)),
            ColorSequenceKeypoint.new(2 / 6, Color3.fromRGB(0, 255, 0)),
            ColorSequenceKeypoint.new(3 / 6, Color3.fromRGB(0, 255, 255)),
            ColorSequenceKeypoint.new(4 / 6, Color3.fromRGB(0, 0, 255)),
            ColorSequenceKeypoint.new(5 / 6, Color3.fromRGB(255, 0, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
        }), Parent = hueBar,
    })

    local hueKnob = create("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.new(0, 8, 0, 14),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0, ZIndex = 16, Parent = hueBar,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = hueKnob })
    create("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1, Parent = hueKnob })

    -- ── Hex Box ──
    local hexFrame = create("Frame", {
        Size = UDim2.new(1, -16, 0, 24),
        Position = UDim2.new(0, 8, 0, 140),
        BackgroundColor3 = Library._theme.SurfaceLight,
        BorderSizePixel = 0, ZIndex = 15, Parent = panel,
    })
    create("UICorner", { CornerRadius = UDim.new(0, 5), Parent = hexFrame })
    create("UIPadding", {
        PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), Parent = hexFrame,
    })

    local hexBox = create("TextBox", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = hexFromColor(curColor),
        TextColor3 = Library._theme.Text,
        TextSize = 11, Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 15, Parent = hexFrame,
    })

    -- ── RGB Labels ──
    local rlbl = create("TextLabel", {
        Size = UDim2.new(1 / 3, -6, 0, 18),
        Position = UDim2.new(0, 8, 0, 170),
        BackgroundTransparency = 1,
        Text = "R: 255", TextColor3 = Color3.fromRGB(255, 100, 100),
        TextSize = 10, Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 15, Parent = panel,
    })
    local glbl = create("TextLabel", {
        Size = UDim2.new(1 / 3, -6, 0, 18),
        Position = UDim2.new(1 / 3, 3, 0, 170),
        BackgroundTransparency = 1,
        Text = "G: 255", TextColor3 = Color3.fromRGB(100, 255, 100),
        TextSize = 10, Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 15, Parent = panel,
    })
    local blbl = create("TextLabel", {
        Size = UDim2.new(1 / 3, -6, 0, 18),
        Position = UDim2.new(2 / 3, -1, 0, 170),
        BackgroundTransparency = 1,
        Text = "B: 255", TextColor3 = Color3.fromRGB(100, 100, 255),
        TextSize = 10, Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Center, ZIndex = 15, Parent = panel,
    })

    -- ── Internal State ──
    local hue = 0
    local sat = 1
    local bri = 1

    local function syncColor()
        curColor = Color3.fromHSV(hue, sat, bri)
        preview.BackgroundColor3 = curColor
        pad.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
        hexBox.Text = hexFromColor(curColor)
        local ri = math.floor(curColor.R * 255 + 0.5)
        local gi = math.floor(curColor.G * 255 + 0.5)
        local bi = math.floor(curColor.B * 255 + 0.5)
        rlbl.Text = "R: " .. ri
        glbl.Text = "G: " .. gi
        blbl.Text = "B: " .. bi
        cb(curColor)
    end

    local function setFromHue(v)
        hue = math.clamp(v, 0, 1)
        hueKnob.Position = UDim2.new(hue, 0, 0.5, 0)
        syncColor()
    end

    local function setFromPad(ix, iy)
        sat = math.clamp(ix, 0, 1)
        bri = math.clamp(1 - iy, 0, 1)
        cursor.Position = UDim2.new(ix, -5, iy, -5)
        syncColor()
    end

    -- ── Pad interaction ──
    local padSliding = false
    pad.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
            padSliding = true
            local rx = math.clamp((inp.Position.X - pad.AbsolutePosition.X) / pad.AbsoluteSize.X, 0, 1)
            local ry = math.clamp((inp.Position.Y - pad.AbsolutePosition.Y) / pad.AbsoluteSize.Y, 0, 1)
            setFromPad(rx, ry)
        end
    end)
    pad.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then padSliding = false end
    end)

    local c1 = UserInputService.InputChanged:Connect(function(inp)
        if padSliding and (inp.UserInputType == Enum.UserInputType.MouseMovement
            or inp.UserInputType == Enum.UserInputType.Touch) then
            local rx = math.clamp((inp.Position.X - pad.AbsolutePosition.X) / pad.AbsoluteSize.X, 0, 1)
            local ry = math.clamp((inp.Position.Y - pad.AbsolutePosition.Y) / pad.AbsoluteSize.Y, 0, 1)
            setFromPad(rx, ry)
        end
    end)
    table.insert(self._connections, c1)

    -- ── Hue interaction ──
    local hueSliding = false
    hueBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then
            hueSliding = true
            setFromHue(math.clamp((inp.Position.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1))
        end
    end)
    hueBar.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
            or inp.UserInputType == Enum.UserInputType.Touch then hueSliding = false end
    end)

    local c2 = UserInputService.InputChanged:Connect(function(inp)
        if hueSliding and (inp.UserInputType == Enum.UserInputType.MouseMovement
            or inp.UserInputType == Enum.UserInputType.Touch) then
            setFromHue(math.clamp((inp.Position.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1))
        end
    end)
    table.insert(self._connections, c2)

    hexBox.FocusLost:Connect(function()
        local c = colorFromHex(hexBox.Text)
        if c then
            local h2, s2, b2 = c.R, c.G, c.B
            -- convert RGB to HSV
            local mx = math.max(h2, s2, b2)
            local mn = math.min(h2, s2, b2)
            local d = mx - mn
            local hh = 0
            if d > 0 then
                if mx == h2 then hh = ((s2 - b2) / d) % 6
                elseif mx == s2 then hh = (b2 - h2) / d + 2
                else hh = (h2 - s2) / d + 4 end
                hh = hh / 6
            end
            hue = hh; sat = mx == 0 and 0 or d / mx; bri = mx
            cursor.Position = UDim2.new(sat, -5, 1 - bri, -5)
            hueKnob.Position = UDim2.new(hue, 0, 0.5, 0)
            syncColor()
        end
    end)

    -- ── Toggle panel ──
    preview.MouseButton1Click:Connect(function()
        opened = not opened
        if opened then
            panel.Size = UDim2.new(1, -24, 0, 0)
            panel.Visible = true
            tween(panel, { Size = UDim2.new(1, -24, 0, PANEL_H) },
                TweenInfo.new(0.3, Enum.EasingStyle.Quint))
            tween(f, { Size = UDim2.new(1, 0, 0, 42 + PANEL_H + 6) },
                TweenInfo.new(0.3, Enum.EasingStyle.Quint))
        else
            tween(panel, { Size = UDim2.new(1, -24, 0, 0) },
                TweenInfo.new(0.25, Enum.EasingStyle.Quint))
            tween(f, { Size = UDim2.new(1, 0, 0, 42) },
                TweenInfo.new(0.25, Enum.EasingStyle.Quint))
            task.delay(0.3, function() if not opened then panel.Visible = false end end)
        end
    end)

    -- init
    do
        local _, s2, b2 = Color3.toHSV(curColor)
        hue, sat, bri = select(1, Color3.toHSV(curColor)), s2, b2
        cursor.Position = UDim2.new(sat, -5, 1 - bri, -5)
        hueKnob.Position = UDim2.new(hue, 0, 0.5, 0)
        pad.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
    end

    el.SetValue = function(_, c)
        curColor = c
        hue, sat, bri = Color3.toHSV(c)
        cursor.Position = UDim2.new(sat, -5, 1 - bri, -5)
        hueKnob.Position = UDim2.new(hue, 0, 0.5, 0)
        syncColor()
    end
    el.GetValue    = function(_) return curColor end
    el.SetCallback = function(_, c) cb = c end
    return el
end

--// ────────────────────────────────────────────────
--// Utility: Set Accent at runtime
--// ────────────────────────────────────────────────
function Library:SetAccent(color)
    Library._theme.Accent = color
end

function Library:GetTheme()
    return Library._theme
end

--// ────────────────────────────────────────────────
--// Return
--// ────────────────────────────────────────────────
return Library

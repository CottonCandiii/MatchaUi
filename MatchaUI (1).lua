-- MatchaUI Library v1.1 (Fixed)
-- Matcha Blue Theme | Dark Mode | PC + Mobile
-- Compatible with Roblox Executors

local MatchaUI = {}
MatchaUI.__index = MatchaUI

-- ─── Services ───────────────────────────────────────────────────────────────
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local TextService      = game:GetService("TextService")
local HttpService      = game:GetService("HttpService")

-- ─── Constants ──────────────────────────────────────────────────────────────
local ACCENT        = Color3.fromRGB(110, 198, 192)
local ACCENT_DARK   = Color3.fromRGB(75,  160, 154)
local ACCENT_LIGHT  = Color3.fromRGB(150, 220, 215)
local BG_PRIMARY    = Color3.fromRGB(15,  17,  21)
local BG_SECONDARY  = Color3.fromRGB(20,  23,  28)
local BG_TERTIARY   = Color3.fromRGB(26,  30,  37)
local BG_HOVER      = Color3.fromRGB(32,  37,  46)
local BG_ACTIVE     = Color3.fromRGB(38,  44,  55)
local TEXT_PRIMARY  = Color3.fromRGB(230, 235, 240)
local TEXT_SECONDARY= Color3.fromRGB(140, 150, 165)
local TEXT_MUTED    = Color3.fromRGB(80,  90,  105)
local BORDER        = Color3.fromRGB(35,  41,  52)
local BORDER_ACCENT = Color3.fromRGB(55,  65,  80)
local SUCCESS       = Color3.fromRGB(80,  200, 120)
local WARNING       = Color3.fromRGB(255, 190, 80)
local ERROR_COLOR   = Color3.fromRGB(255, 90,  90)
local INFO_COLOR    = Color3.fromRGB(110, 198, 192)

local TWEEN_FAST   = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_MED    = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_SLOW   = TweenInfo.new(0.4,  Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_SPRING = TweenInfo.new(0.5,  Enum.EasingStyle.Back, Enum.EasingDirection.Out)

-- ─── Utility ────────────────────────────────────────────────────────────────
local function Tween(obj, info, props)
    TweenService:Create(obj, info, props):Play()
end

-- FIX 1: Safer IsMobile check
local function IsMobile()
    local ok, result = pcall(function()
        return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    end)
    return ok and result or false
end

-- FIX 2: Robust GetGui() — never crashes regardless of executor
local function GetGui()
    -- gethui() is the safest modern executor method
    if typeof(gethui) == "function" then
        local ok, result = pcall(gethui)
        if ok and result then return result end
    end
    -- syn.protect_gui path
    if typeof(syn) == "table" and typeof(syn.protect_gui) == "function" then
        local ok, result = pcall(function() return game:GetService("CoreGui") end)
        if ok then return result end
    end
    -- Plain CoreGui
    local ok, result = pcall(function() return game:GetService("CoreGui") end)
    if ok then return result end
    -- Final fallback: PlayerGui
    return Players.LocalPlayer:WaitForChild("PlayerGui")
end

local function CreateInstance(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then
            inst[k] = v
        end
    end
    for _, child in pairs(children or {}) do
        child.Parent = inst
    end
    if props and props.Parent then
        inst.Parent = props.Parent
    end
    return inst
end

local function MakeRound(parent, radius)
    return CreateInstance("UICorner", {CornerRadius = UDim.new(0, radius or 8), Parent = parent})
end

local function MakePadding(parent, top, right, bottom, left)
    return CreateInstance("UIPadding", {
        PaddingTop    = UDim.new(0, top    or 0),
        PaddingRight  = UDim.new(0, right  or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
        PaddingLeft   = UDim.new(0, left   or 0),
        Parent        = parent
    })
end

local function MakeStroke(parent, color, thickness, transparency)
    return CreateInstance("UIStroke", {
        Color        = color or BORDER,
        Thickness    = thickness or 1,
        Transparency = transparency or 0,
        Parent       = parent
    })
end

-- FIX 3: MakeGradient — Color3 only accepts 3 components; removed invalid 4-arg Color3.new
local function MakeGradient(parent, c0, c1, rotation)
    return CreateInstance("UIGradient", {
        Color    = ColorSequence.new(
            c0 or Color3.new(1, 1, 1),
            c1 or Color3.new(0, 0, 0)
        ),
        Rotation = rotation or 90,
        Parent   = parent
    })
end

local function MakeShadow(parent, size, transparency)
    local shadow = CreateInstance("ImageLabel", {
        Name                   = "Shadow",
        AnchorPoint            = Vector2.new(0.5, 0.5),
        BackgroundTransparency = 1,
        Position               = UDim2.new(0.5, 0, 0.5, 4),
        Size                   = UDim2.new(1, size or 30, 1, size or 30),
        Image                  = "rbxassetid://6014261993",
        ImageColor3            = Color3.new(0, 0, 0),
        ImageTransparency      = transparency or 0.5,
        ScaleType              = Enum.ScaleType.Slice,
        SliceCenter            = Rect.new(49, 49, 450, 450),
        ZIndex                 = -1,
        Parent                 = parent
    })
    return shadow
end

-- ─── Dragging ───────────────────────────────────────────────────────────────
-- FIX 4: Draggable properly separated from click so mobile reopen button works
local function MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
    local dragDistance = 0  -- track distance to distinguish drag vs click

    local function update(input)
        local delta  = input.Position - dragStart
        dragDistance = (Vector2.new(delta.X, delta.Y)).Magnitude
        local screenSize = workspace.CurrentCamera.ViewportSize
        local absSize    = frame.AbsoluteSize
        local px = math.clamp(startPos.X.Offset + delta.X, 0, screenSize.X - absSize.X)
        local py = math.clamp(startPos.Y.Offset + delta.Y, 0, screenSize.Y - absSize.Y)
        frame.Position = UDim2.new(startPos.X.Scale, px, startPos.Y.Scale, py)
    end

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging     = true
            dragDistance = 0
            dragStart    = input.Position
            startPos     = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end)
end

-- ─── Notification System ─────────────────────────────────────────────────────
local NotificationHolder
local function InitNotifications(gui)
    NotificationHolder = CreateInstance("Frame", {
        Name                   = "NotificationHolder",
        AnchorPoint            = Vector2.new(1, 1),
        BackgroundTransparency = 1,
        Position               = UDim2.new(1, -16, 1, -16),
        Size                   = UDim2.new(0, 300, 1, -32),
        Parent                 = gui
    })
    CreateInstance("UIListLayout", {
        FillDirection       = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment   = Enum.VerticalAlignment.Bottom,
        SortOrder           = Enum.SortOrder.LayoutOrder,
        Padding             = UDim.new(0, 8),
        Parent              = NotificationHolder
    })
end

local function Notify(options)
    options = options or {}
    local title    = options.Title    or "Notification"
    local message  = options.Message  or ""
    local ntype    = options.Type     or "Info"
    local duration = options.Duration or 4

    local typeColors = {
        Info    = INFO_COLOR,
        Success = SUCCESS,
        Warning = WARNING,
        Error   = ERROR_COLOR,
    }
    local typeIcons = {
        Info    = "i",
        Success = "✓",
        Warning = "!",
        Error   = "✕",
    }
    local color = typeColors[ntype] or INFO_COLOR
    local icon  = typeIcons[ntype]  or "i"

    if not NotificationHolder then return end

    local card = CreateInstance("Frame", {
        Name                   = "Notif_" .. title,
        BackgroundColor3       = BG_SECONDARY,
        BackgroundTransparency = 1,
        Size                   = UDim2.new(1, 0, 0, 0),
        ClipsDescendants       = true,
        Parent                 = NotificationHolder
    })
    MakeRound(card, 10)
    MakeStroke(card, color, 1, 0.5)
    MakeShadow(card, 20, 0.6)

    -- Accent bar
    local bar = CreateInstance("Frame", {
        BackgroundColor3 = color,
        Size             = UDim2.new(0, 3, 1, 0),
        Parent           = card
    })
    MakeRound(bar, 3)

    local inner = CreateInstance("Frame", {
        BackgroundTransparency = 1,
        Position               = UDim2.new(0, 12, 0, 0),
        Size                   = UDim2.new(1, -12, 1, 0),
        Parent                 = card
    })
    MakePadding(inner, 10, 10, 10, 8)

    CreateInstance("TextLabel", {
        BackgroundTransparency = 1,
        Position               = UDim2.new(0, 0, 0, 0),
        Size                   = UDim2.new(0, 22, 0, 22),
        Text                   = icon,
        TextColor3             = color,
        TextSize               = 14,
        Font                   = Enum.Font.GothamBold,
        Parent                 = inner
    })

    CreateInstance("TextLabel", {
        BackgroundTransparency = 1,
        Position               = UDim2.new(0, 26, 0, 0),
        Size                   = UDim2.new(1, -26, 0, 20),
        Text                   = title,
        TextColor3             = TEXT_PRIMARY,
        TextSize               = 13,
        Font                   = Enum.Font.GothamBold,
        TextXAlignment         = Enum.TextXAlignment.Left,
        Parent                 = inner
    })

    CreateInstance("TextLabel", {
        BackgroundTransparency = 1,
        Position               = UDim2.new(0, 0, 0, 22),
        Size                   = UDim2.new(1, 0, 0, 0),
        Text                   = message,
        TextColor3             = TEXT_SECONDARY,
        TextSize               = 12,
        Font                   = Enum.Font.Gotham,
        TextXAlignment         = Enum.TextXAlignment.Left,
        TextWrapped            = true,
        AutomaticSize          = Enum.AutomaticSize.Y,
        Parent                 = inner
    })

    local prog = CreateInstance("Frame", {
        BackgroundColor3 = color,
        Position         = UDim2.new(0, 0, 1, -2),
        Size             = UDim2.new(1, 0, 0, 2),
        Parent           = card
    })
    MakeRound(prog, 1)

    -- Animate in
    Tween(card, TWEEN_SPRING, {BackgroundTransparency = 0.05, Size = UDim2.new(1, 0, 0, 72)})

    task.spawn(function()
        task.wait(0.3)
        Tween(prog, TweenInfo.new(duration - 0.3, Enum.EasingStyle.Linear), {Size = UDim2.new(0, 0, 0, 2)})
        task.wait(duration)
        Tween(card, TWEEN_MED, {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0)})
        task.wait(0.35)
        card:Destroy()
    end)

    return card
end

-- ─── Config Manager ──────────────────────────────────────────────────────────
local ConfigManager = {}
ConfigManager.__index = ConfigManager

function ConfigManager.new()
    local self = setmetatable({}, ConfigManager)
    -- FIX 5: Safer path — fallback to empty string if syn helpers absent
    local baseDir = ""
    pcall(function()
        if syn and syn.get_syn_dir then
            baseDir = syn.get_syn_dir()
        end
    end)
    self.Path    = baseDir .. "MatchaUI/"
    self.Configs = {}
    pcall(function()
        if not isfolder(self.Path) then
            makefolder(self.Path)
        end
    end)
    return self
end

function ConfigManager:Save(name, data)
    local ok = pcall(function()
        local json = HttpService:JSONEncode(data)
        writefile(self.Path .. name .. ".json", json)
    end)
    return ok
end

function ConfigManager:Load(name)
    local ok, result = pcall(function()
        local content = readfile(self.Path .. name .. ".json")
        return HttpService:JSONDecode(content)
    end)
    return ok and result or nil
end

function ConfigManager:List()
    local ok, files = pcall(function()
        local list = listfiles(self.Path)
        local names = {}
        for _, f in pairs(list) do
            local name = f:match("([^/\\]+)%.json$")
            if name then table.insert(names, name) end
        end
        return names
    end)
    return ok and files or {}
end

function ConfigManager:Delete(name)
    pcall(function() delfile(self.Path .. name .. ".json") end)
end

-- ─── Theme Manager ───────────────────────────────────────────────────────────
local Themes = {
    Matcha = {
        Accent     = Color3.fromRGB(110, 198, 192),
        AccentDark = Color3.fromRGB(75,  160, 154),
    },
    Rose = {
        Accent     = Color3.fromRGB(255, 130, 155),
        AccentDark = Color3.fromRGB(200, 90,  115),
    },
    Amber = {
        Accent     = Color3.fromRGB(255, 185, 80),
        AccentDark = Color3.fromRGB(200, 140, 50),
    },
    Violet = {
        Accent     = Color3.fromRGB(155, 120, 255),
        AccentDark = Color3.fromRGB(115, 80,  210),
    },
    Coral = {
        Accent     = Color3.fromRGB(255, 120, 100),
        AccentDark = Color3.fromRGB(210, 80,  65),
    },
}

-- ─── Window ──────────────────────────────────────────────────────────────────
function MatchaUI:CreateWindow(options)
    options = options or {}
    local windowTitle  = options.Title     or "MatchaUI"
    local windowSize   = options.Size      or UDim2.fromOffset(650, 450)
    local accentColor  = options.Accent    or ACCENT
    local watermarkTxt = options.Watermark or nil
    local keybind      = options.Keybind   or Enum.KeyCode.RightShift
    local mobile       = IsMobile()

    -- Adjust size for mobile
    if mobile then
        local vp = workspace.CurrentCamera.ViewportSize
        windowSize = UDim2.fromOffset(
            math.min(vp.X - 20, 380),
            math.min(vp.Y - 40, 500)
        )
    end

    local gui = GetGui()
    local screenGui

    local ok = pcall(function()
        screenGui = CreateInstance("ScreenGui", {
            Name           = "MatchaUI_" .. windowTitle,
            ResetOnSpawn   = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            IgnoreGuiInset = true,
            Parent         = gui
        })
        -- protect_gui if available
        if typeof(syn) == "table" and typeof(syn.protect_gui) == "function" then
            pcall(syn.protect_gui, screenGui)
        end
    end)

    if not ok or not screenGui then
        screenGui = CreateInstance("ScreenGui", {
            Name           = "MatchaUI_" .. windowTitle,
            ResetOnSpawn   = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
            Parent         = Players.LocalPlayer:WaitForChild("PlayerGui")
        })
    end

    InitNotifications(screenGui)

    local Window = {
        ScreenGui   = screenGui,
        Tabs        = {},
        ActiveTab   = nil,
        Flags       = {},
        Config      = ConfigManager.new(),
        Connections = {},
        AccentColor = accentColor,
        Minimized   = false,
        Visible     = true,
    }

    -- ── Root frame ────────────────────────────────────────────────────────
    local root = CreateInstance("Frame", {
        Name             = "Root",
        AnchorPoint      = Vector2.new(0.5, 0.5),
        BackgroundColor3 = BG_PRIMARY,
        -- FIX 6: Start fully sized but transparent so Spring tween is visible
        Position         = UDim2.new(0.5, 0, 0.5, 0),
        Size             = windowSize,
        BackgroundTransparency = 1,
        ClipsDescendants = false,
        Parent           = screenGui
    })
    MakeRound(root, 14)
    MakeStroke(root, BORDER, 1.5)
    MakeShadow(root, 50, 0.35)
    Window.Root = root

    -- Subtle gradient overlay
    local bgGrad = CreateInstance("Frame", {
        BackgroundColor3       = accentColor,
        BackgroundTransparency = 0.97,
        Size                   = UDim2.new(1, 0, 0.5, 0),
        ZIndex                 = 0,
        Parent                 = root
    })
    MakeRound(bgGrad, 14)

    -- ── Title Bar ─────────────────────────────────────────────────────────
    local titleBar = CreateInstance("Frame", {
        Name             = "TitleBar",
        BackgroundColor3 = BG_SECONDARY,
        Size             = UDim2.new(1, 0, 0, 44),
        Parent           = root
    })
    MakeRound(titleBar, 14)
    MakeStroke(titleBar, BORDER, 1)

    -- Fill bottom corners of titlebar so it looks flat on the bottom
    CreateInstance("Frame", {
        BackgroundColor3 = BG_SECONDARY,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 0, 0.5, 0),
        Size             = UDim2.new(1, 0, 0.5, 0),
        Parent           = titleBar
    })

    -- Accent line under title
    local accentLine = CreateInstance("Frame", {
        BackgroundColor3 = accentColor,
        Position         = UDim2.new(0, 0, 1, -1),
        Size             = UDim2.new(1, 0, 0, 2),
        Parent           = titleBar
    })
    -- FIX 3 applied: no Color3.new with 4 args
    MakeGradient(accentLine,
        Color3.fromRGB(
            math.clamp(math.floor(accentColor.R * 255), 0, 255),
            math.clamp(math.floor(accentColor.G * 255), 0, 255),
            math.clamp(math.floor(accentColor.B * 255), 0, 255)
        ),
        Color3.fromRGB(
            math.clamp(math.floor(accentColor.R * 255) - 30, 0, 255),
            math.clamp(math.floor(accentColor.G * 255) + 10, 0, 255),
            math.clamp(math.floor(accentColor.B * 255) + 20, 0, 255)
        ),
        0
    )

    -- Logo dot
    local logoDot = CreateInstance("Frame", {
        BackgroundColor3 = accentColor,
        Position         = UDim2.new(0, 14, 0.5, -5),
        Size             = UDim2.new(0, 10, 0, 10),
        Parent           = titleBar
    })
    MakeRound(logoDot, 5)

    CreateInstance("TextLabel", {
        BackgroundTransparency = 1,
        Position               = UDim2.new(0, 32, 0, 0),
        Size                   = UDim2.new(0.5, 0, 1, 0),
        Text                   = windowTitle,
        TextColor3             = TEXT_PRIMARY,
        TextSize               = 14,
        Font                   = Enum.Font.GothamBold,
        TextXAlignment         = Enum.TextXAlignment.Left,
        Parent                 = titleBar
    })

    -- Control buttons
    local controls = CreateInstance("Frame", {
        BackgroundTransparency = 1,
        AnchorPoint            = Vector2.new(1, 0.5),
        Position               = UDim2.new(1, -8, 0.5, 0),
        Size                   = UDim2.new(0, 60, 0, 28),
        Parent                 = titleBar
    })
    CreateInstance("UIListLayout", {
        FillDirection       = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment   = Enum.VerticalAlignment.Center,
        Padding             = UDim.new(0, 6),
        Parent              = controls
    })

    local function MakeControlBtn(icon, color)
        local btn = CreateInstance("TextButton", {
            BackgroundColor3 = BG_HOVER,
            Size             = UDim2.new(0, 26, 0, 26),
            Text             = icon,
            TextColor3       = color or TEXT_SECONDARY,
            TextSize         = 12,
            Font             = Enum.Font.GothamBold,
            Parent           = controls
        })
        MakeRound(btn, 6)
        btn.MouseEnter:Connect(function()
            Tween(btn, TWEEN_FAST, {BackgroundColor3 = BG_ACTIVE, TextColor3 = color or TEXT_PRIMARY})
        end)
        btn.MouseLeave:Connect(function()
            Tween(btn, TWEEN_FAST, {BackgroundColor3 = BG_HOVER, TextColor3 = color or TEXT_SECONDARY})
        end)
        return btn
    end

    local closeBtn    = MakeControlBtn("x", ERROR_COLOR)
    local minimizeBtn = MakeControlBtn("-", TEXT_SECONDARY)

    MakeDraggable(root, titleBar)

    -- ── Sidebar ────────────────────────────────────────────────────────────
    local sidebarWidth = mobile and 48 or 160
    local sidebar = CreateInstance("Frame", {
        Name             = "Sidebar",
        BackgroundColor3 = BG_SECONDARY,
        Position         = UDim2.new(0, 0, 0, 44),
        Size             = UDim2.new(0, sidebarWidth, 1, -44),
        Parent           = root
    })
    MakeStroke(sidebar, BORDER, 1)

    -- Right-side patch to hide double border
    CreateInstance("Frame", {
        BackgroundColor3 = BG_SECONDARY,
        BorderSizePixel  = 0,
        Size             = UDim2.new(0, 8, 1, 0),
        AnchorPoint      = Vector2.new(1, 0),
        Position         = UDim2.new(1, 0, 0, 0),
        Parent           = sidebar
    })

    MakePadding(sidebar, 8, 0, 8, 0)

    CreateInstance("UIListLayout", {
        FillDirection       = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        Padding             = UDim.new(0, 2),
        Parent              = sidebar
    })

    -- Search box (PC only)
    local searchBox
    if not mobile then
        local searchFrame = CreateInstance("Frame", {
            BackgroundColor3 = BG_TERTIARY,
            Size             = UDim2.new(1, -12, 0, 30),
            Parent           = sidebar
        })
        MakeRound(searchFrame, 7)
        MakeStroke(searchFrame, BORDER, 1)
        MakePadding(searchFrame, 0, 6, 0, 8)

        CreateInstance("TextLabel", {
            BackgroundTransparency = 1,
            Size                   = UDim2.new(0, 16, 1, 0),
            Text                   = "Q",
            TextColor3             = TEXT_MUTED,
            TextSize               = 13,
            Font                   = Enum.Font.GothamBold,
            Parent                 = searchFrame
        })

        searchBox = CreateInstance("TextBox", {
            BackgroundTransparency = 1,
            Position               = UDim2.new(0, 20, 0, 0),
            Size                   = UDim2.new(1, -20, 1, 0),
            Text                   = "",
            PlaceholderText        = "Search...",
            PlaceholderColor3      = TEXT_MUTED,
            TextColor3             = TEXT_PRIMARY,
            TextSize               = 12,
            Font                   = Enum.Font.Gotham,
            TextXAlignment         = Enum.TextXAlignment.Left,
            ClearTextOnFocus       = false,
            Parent                 = searchFrame
        })

        -- Spacer below search
        -- FIX 7: Don't use a Frame as spacer inside UIListLayout — use UIPadding instead
        -- (sidebar already has MakePadding top/bottom; the layout handles spacing)
    end

    -- ── Content Area ───────────────────────────────────────────────────────
    local contentArea = CreateInstance("Frame", {
        Name                   = "ContentArea",
        BackgroundTransparency = 1,
        Position               = UDim2.new(0, sidebarWidth, 0, 44),
        Size                   = UDim2.new(1, -sidebarWidth, 1, -44),
        Parent                 = root
    })
    Window.ContentArea = contentArea

    -- ── Watermark ──────────────────────────────────────────────────────────
    if watermarkTxt then
        local wmFrame = CreateInstance("Frame", {
            BackgroundColor3       = BG_SECONDARY,
            BackgroundTransparency = 0.1,
            AnchorPoint            = Vector2.new(0, 0),
            Position               = UDim2.new(0, 8, 0, 8),
            Size                   = UDim2.new(0, 0, 0, 26),
            AutomaticSize          = Enum.AutomaticSize.X,
            Parent                 = screenGui
        })
        MakeRound(wmFrame, 6)
        MakeStroke(wmFrame, accentColor, 1, 0.5)
        MakePadding(wmFrame, 0, 10, 0, 10)
        CreateInstance("TextLabel", {
            BackgroundTransparency = 1,
            Size                   = UDim2.new(0, 0, 1, 0),
            AutomaticSize          = Enum.AutomaticSize.X,
            Text                   = watermarkTxt,
            TextColor3             = accentColor,
            TextSize               = 12,
            Font                   = Enum.Font.GothamBold,
            Parent                 = wmFrame
        })
    end

    -- ── Mobile Reopen Button ───────────────────────────────────────────────
    local reopenBtn
    if mobile then
        reopenBtn = CreateInstance("TextButton", {
            Name             = "ReopenBtn",
            BackgroundColor3 = accentColor,
            AnchorPoint      = Vector2.new(0, 1),
            Position         = UDim2.new(0, 12, 1, -12),
            Size             = UDim2.new(0, 48, 0, 48),
            Text             = "M",
            TextColor3       = BG_PRIMARY,
            TextSize         = 16,
            Font             = Enum.Font.GothamBold,
            Visible          = false,
            Parent           = screenGui
        })
        MakeRound(reopenBtn, 24)
        MakeShadow(reopenBtn, 16, 0.4)
        -- FIX 4: Drag reopen button separately without hijacking its click
        MakeDraggable(reopenBtn)

        reopenBtn.MouseButton1Click:Connect(function()
            root.Visible      = true
            reopenBtn.Visible = false
            Window.Visible    = true
            Tween(root, TWEEN_SPRING, {Size = windowSize, BackgroundTransparency = 0})
        end)
    end

    -- ── Close / Minimize ───────────────────────────────────────────────────
    closeBtn.MouseButton1Click:Connect(function()
        Tween(root, TWEEN_MED, {BackgroundTransparency = 1})
        task.wait(0.28)
        screenGui:Destroy()
    end)

    minimizeBtn.MouseButton1Click:Connect(function()
        if Window.Minimized then
            Window.Minimized = false
            if mobile then
                root.Visible      = true
                if reopenBtn then reopenBtn.Visible = false end
            else
                contentArea.Visible = true
                sidebar.Visible     = true
                Tween(root, TWEEN_SPRING, {Size = windowSize})
            end
        else
            Window.Minimized = true
            if mobile then
                Tween(root, TWEEN_MED, {BackgroundTransparency = 1})
                task.wait(0.25)
                root.Visible = false
                if reopenBtn then reopenBtn.Visible = true end
            else
                contentArea.Visible = false
                sidebar.Visible     = false
                Tween(root, TWEEN_MED, {Size = UDim2.new(0, windowSize.X.Offset, 0, 44)})
            end
        end
    end)

    -- Keybind toggle
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == keybind then
            Window.Visible = not Window.Visible
            root.Visible   = Window.Visible
            if reopenBtn then reopenBtn.Visible = not Window.Visible end
        end
    end)

    -- ── Tab Creation ───────────────────────────────────────────────────────
    function Window:CreateTab(name, icon)
        local tabIcon = icon or "="

        -- Simple icon map using basic characters (no Unicode that might fail to render)
        local iconMap = {
            home     = "H",
            settings = "S",
            user     = "U",
            star     = "*",
            shield   = "O",
            code     = "<>",
            heart    = "v",
            bolt     = "!",
            eye      = "E",
            gear     = "G",
        }
        if type(icon) == "string" and iconMap[icon:lower()] then
            tabIcon = iconMap[icon:lower()]
        end

        -- Sidebar button
        local tabBtn = CreateInstance("TextButton", {
            BackgroundColor3       = BG_SECONDARY,
            BackgroundTransparency = 1,
            Size                   = UDim2.new(1, -8, 0, mobile and 40 or 34),
            Text                   = "",
            Parent                 = sidebar
        })
        MakeRound(tabBtn, 8)

        local btnContent = CreateInstance("Frame", {
            BackgroundTransparency = 1,
            Size                   = UDim2.new(1, 0, 1, 0),
            Parent                 = tabBtn
        })
        MakePadding(btnContent, 0, 6, 0, 8)

        local accentIndicator = CreateInstance("Frame", {
            BackgroundColor3       = accentColor,
            BackgroundTransparency = 1,
            AnchorPoint            = Vector2.new(0, 0.5),
            Position               = UDim2.new(0, -8, 0.5, 0),
            Size                   = UDim2.new(0, 3, 0, 18),
            Parent                 = tabBtn
        })
        MakeRound(accentIndicator, 2)

        local iconLbl = CreateInstance("TextLabel", {
            BackgroundTransparency = 1,
            Size                   = UDim2.new(0, 22, 1, 0),
            Text                   = tabIcon,
            TextColor3             = TEXT_MUTED,
            TextSize               = mobile and 16 or 14,
            Font                   = Enum.Font.GothamBold,
            Parent                 = btnContent
        })

        local nameLbl
        if not mobile then
            nameLbl = CreateInstance("TextLabel", {
                BackgroundTransparency = 1,
                Position               = UDim2.new(0, 26, 0, 0),
                Size                   = UDim2.new(1, -26, 1, 0),
                Text                   = name,
                TextColor3             = TEXT_MUTED,
                TextSize               = 13,
                Font                   = Enum.Font.Gotham,
                TextXAlignment         = Enum.TextXAlignment.Left,
                Parent                 = btnContent
            })
        end

        -- Scrollable content frame
        local tabFrame = CreateInstance("ScrollingFrame", {
            BackgroundTransparency    = 1,
            Size                      = UDim2.new(1, 0, 1, 0),
            CanvasSize                = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize       = Enum.AutomaticSize.Y,
            ScrollBarThickness        = 3,
            ScrollBarImageColor3      = accentColor,
            ScrollBarImageTransparency= 0.4,
            Visible                   = false,
            Parent                    = contentArea
        })
        MakePadding(tabFrame, 12, 12, 12, 12)

        CreateInstance("UIListLayout", {
            FillDirection       = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
            Padding             = UDim.new(0, 6),
            Parent              = tabFrame
        })

        local Tab = {
            Name      = name,
            Button    = tabBtn,
            Frame     = tabFrame,
            Indicator = accentIndicator,
            IconLabel = iconLbl,
            NameLabel = nameLbl,
            Elements  = {},
        }

        local function activateTab()
            for _, t in pairs(Window.Tabs) do
                Tween(t.Button,    TWEEN_FAST, {BackgroundTransparency = 1})
                Tween(t.Indicator, TWEEN_FAST, {BackgroundTransparency = 1})
                Tween(t.IconLabel, TWEEN_FAST, {TextColor3 = TEXT_MUTED})
                if t.NameLabel then
                    Tween(t.NameLabel, TWEEN_FAST, {TextColor3 = TEXT_MUTED})
                    t.NameLabel.Font = Enum.Font.Gotham
                end
                t.Frame.Visible = false
            end
            Tween(tabBtn,          TWEEN_FAST, {BackgroundTransparency = 0.85})
            Tween(accentIndicator, TWEEN_FAST, {BackgroundTransparency = 0})
            Tween(iconLbl,         TWEEN_FAST, {TextColor3 = accentColor})
            if nameLbl then
                Tween(nameLbl, TWEEN_FAST, {TextColor3 = TEXT_PRIMARY})
                nameLbl.Font = Enum.Font.GothamBold
            end
            tabFrame.Visible  = true
            Window.ActiveTab  = Tab
        end

        tabBtn.MouseButton1Click:Connect(activateTab)
        tabBtn.MouseEnter:Connect(function()
            if Window.ActiveTab ~= Tab then
                Tween(tabBtn, TWEEN_FAST, {BackgroundTransparency = 0.93})
            end
        end)
        tabBtn.MouseLeave:Connect(function()
            if Window.ActiveTab ~= Tab then
                Tween(tabBtn, TWEEN_FAST, {BackgroundTransparency = 1})
            end
        end)

        table.insert(Window.Tabs, Tab)
        if #Window.Tabs == 1 then
            activateTab()
        end

        -- Search filter
        if searchBox then
            searchBox:GetPropertyChangedSignal("Text"):Connect(function()
                local query = searchBox.Text:lower()
                for _, el in pairs(Tab.Elements) do
                    if el.Container then
                        if query == "" then
                            el.Container.Visible = true
                        elseif el.Name then
                            el.Container.Visible = el.Name:lower():find(query, 1, true) ~= nil
                        end
                    end
                end
            end)
        end

        -- ── Element Helpers ────────────────────────────────────────────────
        local function MakeContainer(height, autosize)
            local c = CreateInstance("Frame", {
                BackgroundColor3 = BG_SECONDARY,
                Size             = UDim2.new(1, 0, 0, height or 38),
                AutomaticSize    = autosize and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
                Parent           = tabFrame
            })
            MakeRound(c, 9)
            MakeStroke(c, BORDER, 1)
            c.MouseEnter:Connect(function()
                Tween(c, TWEEN_FAST, {BackgroundColor3 = BG_HOVER})
            end)
            c.MouseLeave:Connect(function()
                Tween(c, TWEEN_FAST, {BackgroundColor3 = BG_SECONDARY})
            end)
            return c
        end

        -- FIX 8: Removed invalid Enum.VerticalAlignment reference in MakeLabel
        local function MakeLabel(container, text, xoff, yoff, size, color, font, width)
            return CreateInstance("TextLabel", {
                BackgroundTransparency = 1,
                Position               = UDim2.new(0, xoff or 12, 0, yoff or 0),
                Size                   = width
                    and UDim2.new(0, width, size and size + 4 or 0, 0)
                    or  UDim2.new(0, 0, size and size + 4 or 0, 0),
                AutomaticSize          = (not width) and Enum.AutomaticSize.X or Enum.AutomaticSize.None,
                Text                   = text,
                TextColor3             = color or TEXT_PRIMARY,
                TextSize               = size or 13,
                Font                   = font or Enum.Font.Gotham,
                TextXAlignment         = Enum.TextXAlignment.Left,
                TextYAlignment         = Enum.TextYAlignment.Center,
                Parent                 = container
            })
        end

        -- ── CreateButton ──────────────────────────────────────────────────
        function Tab:CreateButton(opts)
            opts = opts or {}
            local c = MakeContainer(opts.Description and 52 or 38)
            local btn = CreateInstance("TextButton", {
                BackgroundTransparency = 1,
                Size                   = UDim2.new(1, 0, 1, 0),
                Text                   = "",
                Parent                 = c
            })
            MakePadding(btn, 0, 10, 0, 12)

            local namePos = opts.Description and UDim2.new(0, 0, 0, 8) or UDim2.new(0, 0, 0.5, -8)
            local nameLblEl = MakeLabel(btn, opts.Name or "Button", 0, opts.Description and 8 or 0, 13, TEXT_PRIMARY, Enum.Font.Gotham, 280)

            if opts.Description then
                MakeLabel(btn, opts.Description, 0, 28, 11, TEXT_SECONDARY, Enum.Font.Gotham, 280)
            end

            local arrow = CreateInstance("TextLabel", {
                BackgroundTransparency = 1,
                AnchorPoint            = Vector2.new(1, 0.5),
                Position               = UDim2.new(1, -4, 0.5, 0),
                Size                   = UDim2.new(0, 20, 0, 20),
                Text                   = ">",
                TextColor3             = TEXT_MUTED,
                TextSize               = 18,
                Font                   = Enum.Font.GothamBold,
                Parent                 = btn
            })

            local el = {Name = opts.Name, Container = c}
            table.insert(Tab.Elements, el)

            btn.MouseEnter:Connect(function()
                Tween(c,     TWEEN_FAST, {BackgroundColor3 = BG_HOVER})
                Tween(arrow, TWEEN_FAST, {TextColor3 = accentColor})
            end)
            btn.MouseLeave:Connect(function()
                Tween(c,     TWEEN_FAST, {BackgroundColor3 = BG_SECONDARY})
                Tween(arrow, TWEEN_FAST, {TextColor3 = TEXT_MUTED})
            end)
            btn.MouseButton1Down:Connect(function()
                Tween(c, TWEEN_FAST, {BackgroundColor3 = BG_ACTIVE})
            end)
            btn.MouseButton1Up:Connect(function()
                Tween(c, TWEEN_FAST, {BackgroundColor3 = BG_HOVER})
                if opts.Callback then pcall(opts.Callback) end
                if opts.Notification then Notify(opts.Notification) end
            end)

            return el
        end

        -- ── CreateToggle ──────────────────────────────────────────────────
        function Tab:CreateToggle(opts)
            opts = opts or {}
            local value = opts.Default or false
            local c = MakeContainer(opts.Description and 52 or 38)

            local lbl = MakeLabel(c, opts.Name or "Toggle", 12, 0, 13, TEXT_PRIMARY, Enum.Font.Gotham)
            if opts.Description then
                c.Size   = UDim2.new(1, 0, 0, 52)
                lbl.Position = UDim2.new(0, 12, 0, 8)
                MakeLabel(c, opts.Description, 12, 28, 11, TEXT_SECONDARY, Enum.Font.Gotham, 240)
            end

            -- Track
            local track = CreateInstance("Frame", {
                AnchorPoint      = Vector2.new(1, 0.5),
                BackgroundColor3 = value and accentColor or BG_TERTIARY,
                Position         = UDim2.new(1, -12, 0.5, 0),
                Size             = UDim2.new(0, 42, 0, 22),
                Parent           = c
            })
            MakeRound(track, 11)
            local trackStroke = MakeStroke(track, value and accentColor or BORDER, 1)

            local thumb = CreateInstance("Frame", {
                AnchorPoint      = Vector2.new(0, 0.5),
                BackgroundColor3 = Color3.new(1, 1, 1),
                Position         = UDim2.new(0, value and 22 or 2, 0.5, 0),
                Size             = UDim2.new(0, 18, 0, 18),
                Parent           = track
            })
            MakeRound(thumb, 9)

            local el = {Name = opts.Name, Container = c, Value = value}

            local function SetValue(v, silent)
                value   = v
                el.Value = v
                Tween(track,       TWEEN_MED, {BackgroundColor3 = v and accentColor or BG_TERTIARY})
                Tween(thumb,       TWEEN_MED, {Position = UDim2.new(0, v and 22 or 2, 0.5, 0)})
                Tween(trackStroke, TWEEN_MED, {Color = v and accentColor or BORDER})
                if not silent and opts.Callback then pcall(opts.Callback, value) end
                if opts.Flag then Window.Flags[opts.Flag] = value end
            end

            local btn = CreateInstance("TextButton", {
                BackgroundTransparency = 1,
                Size                   = UDim2.new(1, 0, 1, 0),
                Text                   = "",
                Parent                 = c
            })
            btn.MouseButton1Click:Connect(function() SetValue(not value) end)

            el.SetValue = SetValue
            el.GetValue = function() return value end
            table.insert(Tab.Elements, el)
            if opts.Flag then Window.Flags[opts.Flag] = value end
            return el
        end

        -- ── CreateSlider ──────────────────────────────────────────────────
        function Tab:CreateSlider(opts)
            opts = opts or {}
            local min    = opts.Min       or 0
            local max    = opts.Max       or 100
            local step   = opts.Increment or 1
            local value  = math.clamp(opts.Default or min, min, max)
            local suffix = opts.Suffix    or ""

            local c = MakeContainer(58)

            local topRow = CreateInstance("Frame", {
                BackgroundTransparency = 1,
                Size                   = UDim2.new(1, 0, 0, 22),
                Parent                 = c
            })
            MakePadding(topRow, 4, 12, 0, 12)
            MakeLabel(topRow, opts.Name or "Slider", 0, 0, 13, TEXT_PRIMARY, Enum.Font.Gotham)

            local valLbl = CreateInstance("TextLabel", {
                AnchorPoint            = Vector2.new(1, 0.5),
                BackgroundTransparency = 1,
                Position               = UDim2.new(1, 0, 0.5, 0),
                Size                   = UDim2.new(0, 60, 1, 0),
                Text                   = tostring(value) .. suffix,
                TextColor3             = accentColor,
                TextSize               = 12,
                Font                   = Enum.Font.GothamBold,
                TextXAlignment         = Enum.TextXAlignment.Right,
                Parent                 = topRow
            })

            local trackBg = CreateInstance("Frame", {
                BackgroundColor3 = BG_TERTIARY,
                Position         = UDim2.new(0, 12, 0, 34),
                Size             = UDim2.new(1, -24, 0, 6),
                Parent           = c
            })
            MakeRound(trackBg, 3)

            local pct0 = (value - min) / (max - min)
            local trackFill = CreateInstance("Frame", {
                BackgroundColor3 = accentColor,
                Size             = UDim2.new(pct0, 0, 1, 0),
                Parent           = trackBg
            })
            MakeRound(trackFill, 3)

            local handle = CreateInstance("Frame", {
                AnchorPoint      = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.new(1, 1, 1),
                Position         = UDim2.new(pct0, 0, 0.5, 0),
                Size             = UDim2.new(0, 14, 0, 14),
                ZIndex           = 2,
                Parent           = trackBg
            })
            MakeRound(handle, 7)
            MakeStroke(handle, accentColor, 2)

            local el = {Name = opts.Name, Container = c, Value = value}

            local function SetValue(v, silent)
                v = math.clamp(
                    math.round((v - min) / step) * step + min,
                    min, max
                )
                value   = v
                el.Value = v
                local pct = (v - min) / (max - min)
                Tween(trackFill, TWEEN_FAST, {Size = UDim2.new(pct, 0, 1, 0)})
                Tween(handle,    TWEEN_FAST, {Position = UDim2.new(pct, 0, 0.5, 0)})
                valLbl.Text = tostring(v) .. suffix
                if not silent and opts.Callback then pcall(opts.Callback, v) end
                if opts.Flag then Window.Flags[opts.Flag] = v end
            end

            local dragging = false

            local function updateFromInput(input)
                local absPos  = trackBg.AbsolutePosition.X
                local absSize = trackBg.AbsoluteSize.X
                if absSize == 0 then return end
                local rel = math.clamp((input.Position.X - absPos) / absSize, 0, 1)
                SetValue(min + rel * (max - min))
            end

            trackBg.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    updateFromInput(input)
                    Tween(handle, TWEEN_FAST, {Size = UDim2.new(0, 18, 0, 18)})
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (
                    input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch
                ) then
                    updateFromInput(input)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    if dragging then
                        dragging = false
                        Tween(handle, TWEEN_FAST, {Size = UDim2.new(0, 14, 0, 14)})
                    end
                end
            end)

            el.SetValue = SetValue
            el.GetValue = function() return value end
            table.insert(Tab.Elements, el)
            if opts.Flag then Window.Flags[opts.Flag] = value end
            return el
        end

        -- ── CreateDropdown ────────────────────────────────────────────────
        function Tab:CreateDropdown(opts)
            opts = opts or {}
            local items = opts.Items   or {}
            local value = opts.Default or nil
            local open  = false

            local c = MakeContainer(38, true)
            c.ClipsDescendants = false
            -- Remove hover effect on dropdown container (it has sub-items)
            c.MouseEnter:Connect(nil)
            c.MouseLeave:Connect(nil)

            local header = CreateInstance("Frame", {
                BackgroundTransparency = 1,
                Size                   = UDim2.new(1, 0, 0, 38),
                Parent                 = c
            })
            MakePadding(header, 0, 10, 0, 12)
            MakeLabel(header, opts.Name or "Dropdown", 0, 0, 13, TEXT_PRIMARY, Enum.Font.Gotham)

            local valueDisp = CreateInstance("TextLabel", {
                AnchorPoint            = Vector2.new(1, 0.5),
                BackgroundTransparency = 1,
                Position               = UDim2.new(1, -24, 0.5, 0),
                Size                   = UDim2.new(0, 120, 0, 20),
                Text                   = value or (opts.Placeholder or "Select..."),
                TextColor3             = value and TEXT_PRIMARY or TEXT_MUTED,
                TextSize               = 12,
                Font                   = Enum.Font.Gotham,
                TextXAlignment         = Enum.TextXAlignment.Right,
                TextTruncate           = Enum.TextTruncate.AtEnd,
                Parent                 = header
            })
            local chevron = CreateInstance("TextLabel", {
                AnchorPoint            = Vector2.new(1, 0.5),
                BackgroundTransparency = 1,
                Position               = UDim2.new(1, -2, 0.5, 0),
                Size                   = UDim2.new(0, 20, 0, 20),
                Text                   = "v",
                TextColor3             = TEXT_MUTED,
                TextSize               = 12,
                Font                   = Enum.Font.GothamBold,
                Parent                 = header
            })

            local list = CreateInstance("Frame", {
                BackgroundColor3 = BG_TERTIARY,
                Position         = UDim2.new(0, 0, 0, 42),
                Size             = UDim2.new(1, 0, 0, 0),
                ClipsDescendants = true,
                ZIndex           = 10,
                Visible          = false,
                Parent           = c
            })
            MakeRound(list, 8)
            MakeStroke(list, BORDER_ACCENT, 1)
            MakePadding(list, 4, 4, 4, 4)
            CreateInstance("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                Padding       = UDim.new(0, 2),
                Parent        = list
            })

            local el = {Name = opts.Name, Container = c, Value = value, Items = items}

            local function PopulateList()
                for _, child in pairs(list:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end
                for _, item in ipairs(items) do
                    local itemBtn = CreateInstance("TextButton", {
                        BackgroundColor3       = BG_HOVER,
                        BackgroundTransparency = 0.7,
                        Size                   = UDim2.new(1, 0, 0, 30),
                        Text                   = "",
                        ZIndex                 = 11,
                        Parent                 = list
                    })
                    MakeRound(itemBtn, 5)
                    local itemLbl = CreateInstance("TextLabel", {
                        BackgroundTransparency = 1,
                        Position               = UDim2.new(0, 8, 0, 0),
                        Size                   = UDim2.new(1, -26, 1, 0),
                        Text                   = tostring(item),
                        TextColor3             = (item == value) and accentColor or TEXT_PRIMARY,
                        TextSize               = 12,
                        Font                   = (item == value) and Enum.Font.GothamBold or Enum.Font.Gotham,
                        TextXAlignment         = Enum.TextXAlignment.Left,
                        ZIndex                 = 12,
                        Parent                 = itemBtn
                    })
                    if item == value then
                        CreateInstance("TextLabel", {
                            AnchorPoint            = Vector2.new(1, 0.5),
                            BackgroundTransparency = 1,
                            Position               = UDim2.new(1, -8, 0.5, 0),
                            Size                   = UDim2.new(0, 16, 0, 16),
                            Text                   = "v",
                            TextColor3             = accentColor,
                            TextSize               = 11,
                            Font                   = Enum.Font.GothamBold,
                            ZIndex                 = 12,
                            Parent                 = itemBtn
                        })
                    end
                    itemBtn.MouseEnter:Connect(function()
                        Tween(itemBtn, TWEEN_FAST, {BackgroundTransparency = 0.5})
                    end)
                    itemBtn.MouseLeave:Connect(function()
                        Tween(itemBtn, TWEEN_FAST, {BackgroundTransparency = 0.7})
                    end)
                    itemBtn.MouseButton1Click:Connect(function()
                        value = item
                        el.Value = item
                        valueDisp.Text       = tostring(item)
                        valueDisp.TextColor3 = TEXT_PRIMARY
                        if opts.Callback then pcall(opts.Callback, item) end
                        if opts.Flag then Window.Flags[opts.Flag] = item end
                        open = false
                        Tween(list,    TWEEN_MED,  {Size = UDim2.new(1, 0, 0, 0)})
                        Tween(chevron, TWEEN_FAST, {Rotation = 0})
                        task.delay(0.25, function() list.Visible = false end)
                        PopulateList()
                    end)
                end
            end
            PopulateList()

            local function toggleOpen()
                open = not open
                if open then
                    local count   = math.min(#items, 5)
                    local targetH = count * 34 + 8
                    list.Visible = true
                    list.Size    = UDim2.new(1, 0, 0, 0)
                    Tween(list,    TWEEN_MED,  {Size = UDim2.new(1, 0, 0, targetH)})
                    Tween(chevron, TWEEN_FAST, {Rotation = 180})
                else
                    Tween(list,    TWEEN_MED,  {Size = UDim2.new(1, 0, 0, 0)})
                    Tween(chevron, TWEEN_FAST, {Rotation = 0})
                    task.delay(0.25, function()
                        if not open then list.Visible = false end
                    end)
                end
            end

            local hdrBtn = CreateInstance("TextButton", {
                BackgroundTransparency = 1,
                Size                   = UDim2.new(1, 0, 0, 38),
                Text                   = "",
                Parent                 = c
            })
            hdrBtn.MouseButton1Click:Connect(toggleOpen)

            el.SetItems = function(newItems)
                items    = newItems
                el.Items = newItems
                PopulateList()
            end
            el.SetValue = function(v)
                value        = v
                el.Value     = v
                valueDisp.Text       = tostring(v)
                valueDisp.TextColor3 = TEXT_PRIMARY
                if opts.Flag then Window.Flags[opts.Flag] = v end
            end
            el.GetValue = function() return value end
            table.insert(Tab.Elements, el)
            if opts.Flag then Window.Flags[opts.Flag] = value end
            return el
        end

        -- ── CreateMultiDropdown ────────────────────────────────────────────
        function Tab:CreateMultiDropdown(opts)
            opts = opts or {}
            local items    = opts.Items or {}
            local selected = {}
            if opts.Default then
                for _, v in pairs(opts.Default) do selected[v] = true end
            end
            local open = false

            local c = MakeContainer(38, true)
            c.ClipsDescendants = false

            local header = CreateInstance("Frame", {
                BackgroundTransparency = 1,
                Size                   = UDim2.new(1, 0, 0, 38),
                Parent                 = c
            })
            MakePadding(header, 0, 10, 0, 12)
            MakeLabel(header, opts.Name or "Multi Select", 0, 0, 13, TEXT_PRIMARY, Enum.Font.Gotham)

            local countLbl = CreateInstance("TextLabel", {
                AnchorPoint            = Vector2.new(1, 0.5),
                BackgroundTransparency = 1,
                Position               = UDim2.new(1, -22, 0.5, 0),
                Size                   = UDim2.new(0, 100, 0, 20),
                Text                   = "0 selected",
                TextColor3             = TEXT_MUTED,
                TextSize               = 12,
                Font                   = Enum.Font.Gotham,
                TextXAlignment         = Enum.TextXAlignment.Right,
                Parent                 = header
            })
            local chevron = CreateInstance("TextLabel", {
                AnchorPoint            = Vector2.new(1, 0.5),
                BackgroundTransparency = 1,
                Position               = UDim2.new(1, -2, 0.5, 0),
                Size                   = UDim2.new(0, 20, 0, 20),
                Text                   = "v",
                TextColor3             = TEXT_MUTED,
                TextSize               = 12,
                Font                   = Enum.Font.GothamBold,
                Parent                 = header
            })

            local list = CreateInstance("Frame", {
                BackgroundColor3 = BG_TERTIARY,
                Position         = UDim2.new(0, 0, 0, 42),
                Size             = UDim2.new(1, 0, 0, 0),
                ClipsDescendants = true,
                ZIndex           = 10,
                Visible          = false,
                Parent           = c
            })
            MakeRound(list, 8)
            MakeStroke(list, BORDER_ACCENT, 1)
            MakePadding(list, 4, 4, 4, 4)
            CreateInstance("UIListLayout", {
                FillDirection = Enum.FillDirection.Vertical,
                Padding       = UDim.new(0, 2),
                Parent        = list
            })

            local el = {Name = opts.Name, Container = c, Value = selected, Items = items}

            local function UpdateCount()
                local n = 0
                for _ in pairs(selected) do n = n + 1 end
                countLbl.Text       = n > 0 and (n .. " selected") or "None"
                countLbl.TextColor3 = n > 0 and accentColor or TEXT_MUTED
            end
            UpdateCount()

            local itemButtons = {}
            for _, item in ipairs(items) do
                local isSel = selected[item] or false
                local itemBtn = CreateInstance("TextButton", {
                    BackgroundColor3       = BG_HOVER,
                    BackgroundTransparency = 0.7,
                    Size                   = UDim2.new(1, 0, 0, 30),
                    Text                   = "",
                    ZIndex                 = 11,
                    Parent                 = list
                })
                MakeRound(itemBtn, 5)

                local checkbox = CreateInstance("Frame", {
                    BackgroundColor3 = isSel and accentColor or BG_PRIMARY,
                    Position         = UDim2.new(0, 6, 0.5, -7),
                    Size             = UDim2.new(0, 14, 0, 14),
                    ZIndex           = 12,
                    Parent           = itemBtn
                })
                MakeRound(checkbox, 4)
                local cbStroke = MakeStroke(checkbox, isSel and accentColor or BORDER_ACCENT, 1.5)

                local checkMark
                if isSel then
                    checkMark = CreateInstance("TextLabel", {
                        BackgroundTransparency = 1,
                        Size                   = UDim2.new(1, 0, 1, 0),
                        Text                   = "v",
                        TextColor3             = BG_PRIMARY,
                        TextSize               = 9,
                        Font                   = Enum.Font.GothamBold,
                        ZIndex                 = 13,
                        Parent                 = checkbox
                    })
                end

                CreateInstance("TextLabel", {
                    BackgroundTransparency = 1,
                    Position               = UDim2.new(0, 26, 0, 0),
                    Size                   = UDim2.new(1, -26, 1, 0),
                    Text                   = tostring(item),
                    TextColor3             = isSel and TEXT_PRIMARY or TEXT_SECONDARY,
                    TextSize               = 12,
                    Font                   = isSel and Enum.Font.GothamBold or Enum.Font.Gotham,
                    TextXAlignment         = Enum.TextXAlignment.Left,
                    ZIndex                 = 12,
                    Parent                 = itemBtn
                })

                itemBtn.MouseEnter:Connect(function()
                    Tween(itemBtn, TWEEN_FAST, {BackgroundTransparency = 0.5})
                end)
                itemBtn.MouseLeave:Connect(function()
                    Tween(itemBtn, TWEEN_FAST, {BackgroundTransparency = 0.7})
                end)
                itemBtn.MouseButton1Click:Connect(function()
                    selected[item] = not selected[item]
                    el.Value = selected
                    UpdateCount()
                    local sel = selected[item]
                    Tween(checkbox, TWEEN_FAST, {BackgroundColor3 = sel and accentColor or BG_PRIMARY})
                    Tween(cbStroke, TWEEN_FAST, {Color = sel and accentColor or BORDER_ACCENT})
                    if opts.Callback then
                        local vals = {}
                        for k, v in pairs(selected) do if v then table.insert(vals, k) end end
                        pcall(opts.Callback, vals)
                    end
                    if opts.Flag then
                        local vals = {}
                        for k, v in pairs(selected) do if v then table.insert(vals, k) end end
                        Window.Flags[opts.Flag] = vals
                    end
                end)
                table.insert(itemButtons, itemBtn)
            end

            local hdrBtn = CreateInstance("TextButton", {
                BackgroundTransparency = 1,
                Size                   = UDim2.new(1, 0, 0, 38),
                Text                   = "",
                Parent                 = c
            })
            hdrBtn.MouseButton1Click:Connect(function()
                open = not open
                if open then
                    local count   = math.min(#items, 5)
                    local targetH = count * 34 + 8
                    list.Visible = true
                    list.Size    = UDim2.new(1, 0, 0, 0)
                    Tween(list,    TWEEN_MED,  {Size = UDim2.new(1, 0, 0, targetH)})
                    Tween(chevron, TWEEN_FAST, {Rotation = 180})
                else
                    Tween(list,    TWEEN_MED,  {Size = UDim2.new(1, 0, 0, 0)})
                    Tween(chevron, TWEEN_FAST, {Rotation = 0})
                    task.delay(0.25, function()
                        if not open then list.Visible = false end
                    end)
                end
            end)

            el.GetValue = function()
                local vals = {}
                for k, v in pairs(selected) do if v then table.insert(vals, k) end end
                return vals
            end
            table.insert(Tab.Elements, el)
            return el
        end

        -- ── CreateTextbox ─────────────────────────────────────────────────
        function Tab:CreateTextbox(opts)
            opts = opts or {}
            local c = MakeContainer(52)

            MakeLabel(c, opts.Name or "Textbox", 12, 4, 12, TEXT_SECONDARY, Enum.Font.Gotham)

            local inputFrame = CreateInstance("Frame", {
                BackgroundColor3 = BG_TERTIARY,
                Position         = UDim2.new(0, 10, 0, 24),
                Size             = UDim2.new(1, -20, 0, 24),
                Parent           = c
            })
            MakeRound(inputFrame, 6)
            local stroke = MakeStroke(inputFrame, BORDER, 1)
            MakePadding(inputFrame, 0, 6, 0, 8)

            local textBox = CreateInstance("TextBox", {
                BackgroundTransparency = 1,
                Size                   = UDim2.new(1, 0, 1, 0),
                Text                   = opts.Default or "",
                PlaceholderText        = opts.Placeholder or "Enter text...",
                PlaceholderColor3      = TEXT_MUTED,
                TextColor3             = TEXT_PRIMARY,
                TextSize               = 12,
                Font                   = Enum.Font.Gotham,
                TextXAlignment         = Enum.TextXAlignment.Left,
                ClearTextOnFocus       = opts.ClearOnFocus ~= false,
                Parent                 = inputFrame
            })

            textBox.Focused:Connect(function()
                Tween(stroke, TWEEN_FAST, {Color = accentColor})
            end)
            textBox.FocusLost:Connect(function(enterPressed)
                Tween(stroke, TWEEN_FAST, {Color = BORDER})
                if opts.Callback then pcall(opts.Callback, textBox.Text, enterPressed) end
                if opts.Flag then Window.Flags[opts.Flag] = textBox.Text end
            end)

            local el = {Name = opts.Name, Container = c, Value = textBox.Text}
            el.SetValue = function(v)
                textBox.Text = v
                el.Value     = v
                if opts.Flag then Window.Flags[opts.Flag] = v end
            end
            el.GetValue = function() return textBox.Text end
            table.insert(Tab.Elements, el)
            if opts.Flag then Window.Flags[opts.Flag] = textBox.Text end
            return el
        end

        -- ── CreateKeybind ─────────────────────────────────────────────────
        function Tab:CreateKeybind(opts)
            opts = opts or {}
            local value   = opts.Default or Enum.KeyCode.Unknown
            local binding = false

            local c = MakeContainer(38)
            MakeLabel(c, opts.Name or "Keybind", 12, 0, 13, TEXT_PRIMARY, Enum.Font.Gotham)

            local keyBtn = CreateInstance("TextButton", {
                AnchorPoint      = Vector2.new(1, 0.5),
                BackgroundColor3 = BG_TERTIARY,
                Position         = UDim2.new(1, -10, 0.5, 0),
                Size             = UDim2.new(0, 80, 0, 24),
                Text             = value == Enum.KeyCode.Unknown and "None" or value.Name,
                TextColor3       = accentColor,
                TextSize         = 11,
                Font             = Enum.Font.GothamBold,
                Parent           = c
            })
            MakeRound(keyBtn, 5)
            MakeStroke(keyBtn, BORDER_ACCENT, 1)

            local el = {Name = opts.Name, Container = c, Value = value}

            keyBtn.MouseButton1Click:Connect(function()
                binding          = true
                keyBtn.Text      = "Press key..."
                keyBtn.TextColor3 = WARNING
                Tween(keyBtn, TWEEN_FAST, {BackgroundColor3 = BG_ACTIVE})
            end)

            UserInputService.InputBegan:Connect(function(input, gpe)
                if binding and input.UserInputType == Enum.UserInputType.Keyboard then
                    binding          = false
                    value            = input.KeyCode
                    el.Value         = value
                    keyBtn.Text      = value.Name
                    keyBtn.TextColor3 = accentColor
                    Tween(keyBtn, TWEEN_FAST, {BackgroundColor3 = BG_TERTIARY})
                    if opts.Callback then pcall(opts.Callback, value) end
                    if opts.Flag then Window.Flags[opts.Flag] = value end
                end
            end)

            el.GetValue = function() return value end
            table.insert(Tab.Elements, el)
            if opts.Flag then Window.Flags[opts.Flag] = value end
            return el
        end

        -- ── CreateColorPicker ─────────────────────────────────────────────
        function Tab:CreateColorPicker(opts)
            opts = opts or {}
            local value = opts.Default or Color3.fromRGB(110, 198, 192)
            local open  = false

            local c = MakeContainer(38, true)
            c.ClipsDescendants = false

            local header = CreateInstance("Frame", {
                BackgroundTransparency = 1,
                Size                   = UDim2.new(1, 0, 0, 38),
                Parent                 = c
            })
            MakePadding(header, 0, 10, 0, 12)
            MakeLabel(header, opts.Name or "Color", 0, 0, 13, TEXT_PRIMARY, Enum.Font.Gotham)

            local colorSwatch = CreateInstance("Frame", {
                AnchorPoint      = Vector2.new(1, 0.5),
                BackgroundColor3 = value,
                Position         = UDim2.new(1, -4, 0.5, 0),
                Size             = UDim2.new(0, 28, 0, 22),
                Parent           = header
            })
            MakeRound(colorSwatch, 5)
            MakeStroke(colorSwatch, BORDER_ACCENT, 1.5)

            local pickerPanel = CreateInstance("Frame", {
                BackgroundColor3 = BG_TERTIARY,
                Position         = UDim2.new(0, 0, 0, 42),
                Size             = UDim2.new(1, 0, 0, 0),
                ClipsDescendants = true,
                ZIndex           = 10,
                Visible          = false,
                Parent           = c
            })
            MakeRound(pickerPanel, 8)
            MakeStroke(pickerPanel, BORDER_ACCENT, 1)
            MakePadding(pickerPanel, 10, 10, 10, 10)

            -- Saturation/Value square
            local satValFrame = CreateInstance("Frame", {
                BackgroundColor3 = Color3.fromHSV(0, 1, 1),
                Size             = UDim2.new(1, 0, 0, 100),
                ZIndex           = 11,
                Parent           = pickerPanel
            })
            MakeRound(satValFrame, 6)

            -- White gradient (left = white, right = hue color)
            local whiteOverlay = CreateInstance("Frame", {
                BackgroundColor3 = Color3.new(1, 1, 1),
                Size             = UDim2.new(1, 0, 1, 0),
                ZIndex           = 12,
                Parent           = satValFrame
            })
            -- FIX 3: Use valid 3-component Color3.new — transparent white via UIGradient transparency
            CreateInstance("UIGradient", {
                Color       = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1)),
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1),
                }),
                Rotation    = 0,
                Parent      = whiteOverlay
            })

            -- Black gradient (bottom = black)
            local blackOverlay = CreateInstance("Frame", {
                BackgroundColor3 = Color3.new(0, 0, 0),
                Size             = UDim2.new(1, 0, 1, 0),
                ZIndex           = 13,
                Parent           = satValFrame
            })
            CreateInstance("UIGradient", {
                Color       = ColorSequence.new(Color3.new(0, 0, 0), Color3.new(0, 0, 0)),
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(1, 0),
                }),
                Rotation    = 90,
                Parent      = blackOverlay
            })

            local svCursor = CreateInstance("Frame", {
                AnchorPoint      = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.new(1, 1, 1),
                Position         = UDim2.new(0, 0, 0, 0),
                Size             = UDim2.new(0, 12, 0, 12),
                ZIndex           = 15,
                Parent           = satValFrame
            })
            MakeRound(svCursor, 6)
            MakeStroke(svCursor, Color3.new(1, 1, 1), 2)

            -- Hue slider
            local hueFrame = CreateInstance("Frame", {
                BackgroundColor3 = Color3.new(1, 0, 0),
                Position         = UDim2.new(0, 0, 0, 108),
                Size             = UDim2.new(1, 0, 0, 14),
                ZIndex           = 11,
                Parent           = pickerPanel
            })
            MakeRound(hueFrame, 7)
            CreateInstance("UIGradient", {
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0,    Color3.fromRGB(255, 0,   0)),
                    ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,   255, 0)),
                    ColorSequenceKeypoint.new(0.5,  Color3.fromRGB(0,   255, 255)),
                    ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0,   0,   255)),
                    ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0,   255)),
                    ColorSequenceKeypoint.new(1,    Color3.fromRGB(255, 0,   0)),
                }),
                Rotation = 0,
                Parent   = hueFrame
            })

            local hueCursor = CreateInstance("Frame", {
                AnchorPoint      = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.new(1, 1, 1),
                Position         = UDim2.new(0, 0, 0.5, 0),
                Size             = UDim2.new(0, 14, 0, 20),
                ZIndex           = 12,
                Parent           = hueFrame
            })
            MakeRound(hueCursor, 4)
            MakeStroke(hueCursor, Color3.new(1, 1, 1), 2)

            local h, s, v2 = Color3.toHSV(value)

            local function UpdateColor(newH, newS, newV)
                h, s, v2 = newH, newS, newV
                local col = Color3.fromHSV(h, s, v2)
                value = col
                colorSwatch.BackgroundColor3  = col
                satValFrame.BackgroundColor3  = Color3.fromHSV(h, 1, 1)
                svCursor.Position  = UDim2.new(s, 0, 1 - v2, 0)
                hueCursor.Position = UDim2.new(h, 0, 0.5, 0)
                if opts.Callback then pcall(opts.Callback, col) end
                if opts.Flag then Window.Flags[opts.Flag] = col end
            end
            UpdateColor(h, s, v2)

            local draggingHue, draggingSV = false, false

            hueFrame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    draggingHue = true
                    local rel = math.clamp(
                        (input.Position.X - hueFrame.AbsolutePosition.X) / math.max(hueFrame.AbsoluteSize.X, 1),
                        0, 1
                    )
                    UpdateColor(rel, s, v2)
                end
            end)
            satValFrame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    draggingSV = true
                    local relS = math.clamp(
                        (input.Position.X - satValFrame.AbsolutePosition.X) / math.max(satValFrame.AbsoluteSize.X, 1),
                        0, 1
                    )
                    local relV = 1 - math.clamp(
                        (input.Position.Y - satValFrame.AbsolutePosition.Y) / math.max(satValFrame.AbsoluteSize.Y, 1),
                        0, 1
                    )
                    UpdateColor(h, relS, relV)
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch then
                    if draggingHue then
                        local rel = math.clamp(
                            (input.Position.X - hueFrame.AbsolutePosition.X) / math.max(hueFrame.AbsoluteSize.X, 1),
                            0, 1
                        )
                        UpdateColor(rel, s, v2)
                    elseif draggingSV then
                        local relS = math.clamp(
                            (input.Position.X - satValFrame.AbsolutePosition.X) / math.max(satValFrame.AbsoluteSize.X, 1),
                            0, 1
                        )
                        local relV = 1 - math.clamp(
                            (input.Position.Y - satValFrame.AbsolutePosition.Y) / math.max(satValFrame.AbsoluteSize.Y, 1),
                            0, 1
                        )
                        UpdateColor(h, relS, relV)
                    end
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    draggingHue = false
                    draggingSV  = false
                end
            end)

            local hdrBtn = CreateInstance("TextButton", {
                BackgroundTransparency = 1,
                Size                   = UDim2.new(1, 0, 0, 38),
                Text                   = "",
                Parent                 = c
            })
            hdrBtn.MouseButton1Click:Connect(function()
                open = not open
                if open then
                    pickerPanel.Visible = true
                    pickerPanel.Size    = UDim2.new(1, 0, 0, 0)
                    Tween(pickerPanel, TWEEN_MED, {Size = UDim2.new(1, 0, 0, 168)})
                else
                    Tween(pickerPanel, TWEEN_MED, {Size = UDim2.new(1, 0, 0, 0)})
                    task.delay(0.25, function()
                        if not open then pickerPanel.Visible = false end
                    end)
                end
            end)

            local el = {Name = opts.Name, Container = c, Value = value}
            el.GetValue = function() return value end
            el.SetValue = function(col)
                local nh, ns, nv = Color3.toHSV(col)
                UpdateColor(nh, ns, nv)
            end
            table.insert(Tab.Elements, el)
            if opts.Flag then Window.Flags[opts.Flag] = value end
            return el
        end

        -- ── CreateLabel ───────────────────────────────────────────────────
        function Tab:CreateLabel(opts)
            opts = type(opts) == "string" and {Name = opts} or (opts or {})
            local c = CreateInstance("Frame", {
                BackgroundTransparency = 1,
                Size                   = UDim2.new(1, 0, 0, 28),
                Parent                 = tabFrame
            })
            MakePadding(c, 0, 4, 0, 12)
            local lbl = CreateInstance("TextLabel", {
                BackgroundTransparency = 1,
                Size                   = UDim2.new(1, 0, 1, 0),
                Text                   = opts.Name or opts.Text or "Label",
                TextColor3             = opts.Color or TEXT_SECONDARY,
                TextSize               = opts.Size  or 12,
                Font                   = opts.Bold and Enum.Font.GothamBold or Enum.Font.Gotham,
                TextXAlignment         = Enum.TextXAlignment.Left,
                Parent                 = c
            })
            local el = {Name = opts.Name, Container = c, Label = lbl}
            el.SetText = function(t) lbl.Text = t end
            table.insert(Tab.Elements, el)
            return el
        end

        -- ── CreateParagraph ───────────────────────────────────────────────
        function Tab:CreateParagraph(opts)
            opts = opts or {}
            local c = CreateInstance("Frame", {
                BackgroundColor3 = BG_SECONDARY,
                Size             = UDim2.new(1, 0, 0, 0),
                AutomaticSize    = Enum.AutomaticSize.Y,
                Parent           = tabFrame
            })
            MakeRound(c, 9)
            MakeStroke(c, BORDER, 1)
            MakePadding(c, 10, 12, 10, 12)

            CreateInstance("UIListLayout", {
                FillDirection       = Enum.FillDirection.Vertical,
                HorizontalAlignment = Enum.HorizontalAlignment.Left,
                Padding             = UDim.new(0, 4),
                Parent              = c
            })

            if opts.Title then
                CreateInstance("TextLabel", {
                    BackgroundTransparency = 1,
                    Size                   = UDim2.new(1, 0, 0, 18),
                    Text                   = opts.Title,
                    TextColor3             = TEXT_PRIMARY,
                    TextSize               = 13,
                    Font                   = Enum.Font.GothamBold,
                    TextXAlignment         = Enum.TextXAlignment.Left,
                    Parent                 = c
                })
            end

            local bodyLbl = CreateInstance("TextLabel", {
                BackgroundTransparency = 1,
                Size                   = UDim2.new(1, 0, 0, 0),
                AutomaticSize          = Enum.AutomaticSize.Y,
                Text                   = opts.Content or opts.Text or "",
                TextColor3             = TEXT_SECONDARY,
                TextSize               = 12,
                Font                   = Enum.Font.Gotham,
                TextXAlignment         = Enum.TextXAlignment.Left,
                TextWrapped            = true,
                Parent                 = c
            })

            local el = {Name = opts.Title, Container = c}
            el.SetContent = function(t) bodyLbl.Text = t end
            table.insert(Tab.Elements, el)
            return el
        end

        -- ── CreateDivider ─────────────────────────────────────────────────
        function Tab:CreateDivider(opts)
            opts = type(opts) == "string" and {Label = opts} or (opts or {})
            local c = CreateInstance("Frame", {
                BackgroundTransparency = 1,
                Size                   = UDim2.new(1, 0, 0, 20),
                Parent                 = tabFrame
            })
            MakePadding(c, 6, 4, 6, 4)

            CreateInstance("Frame", {
                AnchorPoint      = Vector2.new(0, 0.5),
                BackgroundColor3 = BORDER,
                Position         = UDim2.new(0, 0, 0.5, 0),
                Size             = UDim2.new(1, 0, 0, 1),
                Parent           = c
            })

            if opts.Label then
                CreateInstance("TextLabel", {
                    AnchorPoint   = Vector2.new(0.5, 0.5),
                    BackgroundColor3 = BG_TERTIARY,
                    Position      = UDim2.new(0.5, 0, 0.5, 0),
                    Size          = UDim2.new(0, 0, 0, 16),
                    AutomaticSize = Enum.AutomaticSize.X,
                    Text          = "  " .. opts.Label .. "  ",
                    TextColor3    = TEXT_MUTED,
                    TextSize      = 11,
                    Font          = Enum.Font.GothamBold,
                    Parent        = c
                })
            end

            local el = {Name = opts.Label, Container = c}
            table.insert(Tab.Elements, el)
            return el
        end

        function Tab:CreateSection(name)
            return self:CreateDivider({Label = name})
        end

        function Tab:Notify(opts)
            return Notify(opts)
        end

        return Tab
    end

    -- ── Config / Theme helpers ────────────────────────────────────────────
    function Window:SaveConfig(name)
        local data = {}
        for flag, val in pairs(self.Flags) do
            data[flag] = val
        end
        return self.Config:Save(name, data)
    end

    function Window:LoadConfig(name)
        local data = self.Config:Load(name)
        if not data then return false end
        for flag, val in pairs(data) do
            self.Flags[flag] = val
        end
        return true
    end

    function Window:ListConfigs()
        return self.Config:List()
    end

    function Window:SetTheme(themeName)
        local theme = Themes[themeName]
        if not theme then return end
        accentColor        = theme.Accent
        Window.AccentColor = accentColor
        Tween(accentLine, TWEEN_MED, {BackgroundColor3 = accentColor})
        Tween(logoDot,    TWEEN_MED, {BackgroundColor3 = accentColor})
    end

    function Window:Notify(opts)
        return Notify(opts)
    end

    function Window:Destroy()
        screenGui:Destroy()
    end

    -- FIX 6: Entry animation — fade in from transparent, size is already correct
    Tween(root, TWEEN_SPRING, {BackgroundTransparency = 0})

    return Window
end

-- ── Library helpers ──────────────────────────────────────────────────────────
function MatchaUI:Notify(opts)
    Notify(opts)
end

function MatchaUI:GetThemes()
    local names = {}
    for k in pairs(Themes) do table.insert(names, k) end
    return names
end

return MatchaUI

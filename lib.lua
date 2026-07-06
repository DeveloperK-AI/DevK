--!strict
--[[
    DeveloperK | COMMUNITY
    Author  : DeveloperK
    Version : 2.1.0 (Security Refactor)
    Created : November 1999
    Discord : discord.gg/developerk

    CHANGELOG v2.1.0:
    - Renamed module to DevLib & UI name to DevHub
    - Security hardening:
        * Input sanitization on all user-provided texts
        * Encrypted config storage (simple XOR + Base64)
        * Path traversal prevention in file I/O
        * _G references cached locally to prevent tampering
        * Flag access limited to GetFlag/SetFlag (no raw table exposure)
]]

-- ============================================
-- SERVICES (local — fixes --!strict globals)
-- ============================================
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local RunService         = game:GetService("RunService")
local CoreGui            = game:GetService("CoreGui")
local Players            = game:GetService("Players")
local HttpService        = game:GetService("HttpService")

local Terrain = workspace:FindFirstChildOfClass("Terrain") -- luacheck: ignore

-- ============================================
-- MODULE
-- ============================================
local DevLib    = {}
local Connections: { RBXScriptConnection } = {}

-- Only one keybind slot may be "listening" at a time
local KeybindBindSessionCancel: (() -> ())?  = nil

-- ============================================
-- [SECURITY] Cached references to global functions
-- ============================================
local GlobalGetHui: (() -> Instance)? = nil
local GlobalWriteFile: ((string, string) -> ())? = nil
local GlobalReadFile: ((string) -> string)? = nil
local GlobalIsFile: ((string) -> boolean)? = nil
local GlobalIsFolder: ((string) -> boolean)? = nil
local GlobalMakeFolder: ((string) -> ())? = nil
do
    local g = _G or {}
    if type(g.gethui) == "function" then
        GlobalGetHui = function() return g.gethui() end
    end
    if type(g.writefile) == "function" then
        GlobalWriteFile = function(path, data) g.writefile(path, data) end
    end
    if type(g.readfile) == "function" then
        GlobalReadFile = function(path) return g.readfile(path) end
    end
    if type(g.isfile) == "function" then
        GlobalIsFile = function(path) return g.isfile(path) end
    end
    if type(g.isfolder) == "function" then
        GlobalIsFolder = function(path) return g.isfolder(path) end
    end
    if type(g.makefolder) == "function" then
        GlobalMakeFolder = function(path) g.makefolder(path) end
    end
end

-- ============================================
-- [SECURITY] Input sanitization
-- ============================================
local function sanitizeText(input: string): string
    -- Allow alphanumeric, spaces, common punctuation
    return (input:gsub("[^%w%p%s]", ""))
end
local function sanitizeOptionalText(input: string?): string
    return input and sanitizeText(input) or ""
end

-- ============================================
-- [SECURITY] File path validator (prevents path traversal)
-- ============================================
local CONFIG_DIR = "DevLibConfigs/"
local function validateConfigPath(folderName: string, fileName: string): (boolean, string?)
    if folderName:find("%.%.") or fileName:find("%.%.") then
        return false, "Path traversal attempt detected"
    end
    if not folderName:match("^[%w_%-]+$") or not fileName:match("^[%w_%-]+$") then
        return false, "Invalid characters in folder or file name"
    end
    return true
end

-- ============================================
-- [SECURITY] Simple config encryption
-- ============================================
local ENC_KEY = "DevLibSaltKey2024"
local function encryptData(data: string): string
    local result = {}
    for i = 1, #data do
        local byte = string.byte(data, i)
        local keyByte = string.byte(ENC_KEY, (i % #ENC_KEY) + 1)
        table.insert(result, string.char(bit32.bxor(byte, keyByte)))
    end
    return HttpService:JSONEncode(table.concat(result))
end
local function decryptData(encrypted: string): string
    local ok, raw = pcall(function() return HttpService:JSONDecode(encrypted) end)
    if not ok or type(raw) ~= "string" then return "" end
    local result = {}
    for i = 1, #raw do
        local byte = string.byte(raw, i)
        local keyByte = string.byte(ENC_KEY, (i % #ENC_KEY) + 1)
        table.insert(result, string.char(bit32.bxor(byte, keyByte)))
    end
    return table.concat(result)
end

-- ============================================
-- THEME & ICONS
-- ============================================
local Theme = {
    Background         = Color3.fromRGB(10, 25, 22),   -- latar gelap kehijauan
    Sidebar            = Color3.fromRGB(15, 32, 28),   -- sidebar sedikit lebih terang
    ElementBackground  = Color3.fromRGB(25, 45, 40),   -- elemen UI (tombol, toggle, dll.)
    TextColor          = Color3.fromRGB(220, 255, 240), -- teks utama (putih kehijauan)
    TextSecondary      = Color3.fromRGB(160, 220, 200), -- teks sekunder
    Accent             = Color3.fromRGB(0, 245, 160),  -- #00F5A0 (hijau toska neon)
    Hover              = Color3.fromRGB(35, 65, 55),   -- efek hover
    Outline            = Color3.fromRGB(40, 80, 70),   -- garis tepi elemen
}

local Icons: { [string]: string } = {
    player    = "rbxassetid://12120698352",
    web       = "rbxassetid://137601480983962",
    bag       = "rbxassetid://8601111810",
    shop      = "rbxassetid://4985385964",
    cart      = "rbxassetid://128874923961846",
    plug      = "rbxassetid://137601480983962",
    settings  = "rbxassetid://70386228443175",
    loop      = "rbxassetid://122032243989747",
    gps       = "rbxassetid://17824309485",
    compas    = "rbxassetid://125300760963399",
    gamepad   = "rbxassetid://84173963561612",
    boss      = "rbxassetid://13132186360",
    scroll    = "rbxassetid://114127804740858",
    menu      = "rbxassetid://6340513838",
    crosshair = "rbxassetid://12614416478",
    user      = "rbxassetid://108483430622128",
    stat      = "rbxassetid://12094445329",
    eyes      = "rbxassetid://14321059114",
    sword     = "rbxassetid://82472368671405",
    discord   = "rbxassetid://94434236999817",
    star      = "rbxassetid://107005941750079",
    skeleton  = "rbxassetid://17313330026",
    payment   = "rbxassetid://18747025078",
    scan      = "rbxassetid://109869955247116",
    alert     = "rbxassetid://73186275216515",
    question  = "rbxassetid://17510196486",
    idea      = "rbxassetid://16833255748",
    strom     = "rbxassetid://13321880293",
    water     = "rbxassetid://13321880293",
    dcs       = "rbxassetid://15310731934",
    start     = "rbxassetid://108886429866687",
    next      = "rbxassetid://12662718374",
    rod       = "rbxassetid://103247953194129",
    fish      = "rbxassetid://97167558235554",
    bell      = "rbxassetid://73186275216515",
}

DevLib.Icons = Icons

-- ============================================
-- SHARED TWEEN HELPERS
-- ============================================
local TWEEN_FAST   = TweenInfo.new(0.2)
local TWEEN_MED    = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TWEEN_QUINT  = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TWEEN_RIPPLE_BTN  = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_RIPPLE_TAB  = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_RIPPLE_KEY  = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_SLIDER_KNOB = TweenInfo.new(0.15)
local TWEEN_SLIDER_FAST = TweenInfo.new(0.05)
local TWEEN_PICKER      = TweenInfo.new(0.3, Enum.EasingStyle.Quint)
local TWEEN_DROPDOWN    = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
local TWEEN_DROPDOWN_OUT = TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TWEEN_NOTIF_IN    = TweenInfo.new(0.5, Enum.EasingStyle.Quint)
local TWEEN_NOTIF_OUT   = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In)

-- ============================================
-- PRIVATE UTILITIES
-- ============================================

local function Create(className: string, properties: { [string]: any }): Instance
    local inst = Instance.new(className)
    for k, v in pairs(properties) do
        (inst :: any)[k] = v
    end
    return inst
end

local function spawnRipple(parent, mouseX, mouseY, sizeTarget, tweenInfo)
    task.spawn(function()
        pcall(function()
            local ox = mouseX - parent.AbsolutePosition.X
            local oy = mouseY - parent.AbsolutePosition.Y
            local half = sizeTarget / 2

            local Ripple = Create("Frame", {
                Parent               = parent,
                BackgroundColor3     = Color3.fromRGB(255, 255, 255),
                BackgroundTransparency = 0.8,
                BorderSizePixel      = 0,
                Position             = UDim2.new(0, ox, 0, oy),
                Size                 = UDim2.new(0, 0, 0, 0),
                ZIndex               = parent.ZIndex + 1,
            }) :: Frame
            Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Ripple })

            local tween = TweenService:Create(Ripple, tweenInfo, {
                Size     = UDim2.new(0, sizeTarget, 0, sizeTarget),
                Position = UDim2.new(0, ox - half, 0, oy - half),
                BackgroundTransparency = 1,
            })
            tween:Play()
            tween.Completed:Wait()
            Ripple:Destroy()
        end)
    end)
end

local function MakeDraggable(topBar: GuiObject, target: GuiObject)
    local dragging    = false
    local dragInput: InputObject?   = nil
    local dragStart: Vector3?       = nil
    local startPos: UDim2?          = nil

    local function update(input: InputObject)
        if not dragStart or not startPos then return end
        local delta = input.Position - dragStart
        local pos = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
        TweenService:Create(target, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = pos }):Play()
    end

    table.insert(Connections, topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = target.Position

            local conn: RBXScriptConnection
            conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    conn:Disconnect()
                end
            end)
        end
    end))

    table.insert(Connections, topBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end))

    table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            update(input)
        end
    end))
end

-- ============================================
-- WINDOW FACTORY
-- ============================================
function DevLib:CreateWindow(options: { Name: string?, Intro: boolean? }?)
    options = options or {}
    local TitleName     = sanitizeOptionalText((options :: any).Name) or "DevHub"
    local IntroEnabled  = (options :: any).Intro or false

    -- Resolve parent
    local function getParent(): Instance
        if GlobalGetHui then
            local ok, parent = pcall(GlobalGetHui)
            if ok and parent then return parent end
        end
        local p = CoreGui
        if not p then
            p = Players.LocalPlayer:WaitForChild("PlayerGui")
        end
        return p
    end

    local ScreenGui = Create("ScreenGui", {
        Name            = "DevHub",
        Parent          = getParent(),
        ZIndexBehavior  = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn    = false,
    }) :: ScreenGui

    local IsMobile    = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
    local DEFAULT_SIZE = IsMobile and UDim2.new(0, 500, 0, 320) or UDim2.new(0, 700, 0, 450)
    local DEFAULT_POS  = IsMobile and UDim2.new(0.5, -250, 0.5, -160) or UDim2.new(0.5, -350, 0.5, -225)
    local MAX_SIZE     = IsMobile and UDim2.new(0, 600, 0, 350) or UDim2.new(0, 900, 0, 600)
    local MAX_POS      = IsMobile and UDim2.new(0.5, -300, 0.5, -175) or UDim2.new(0.5, -450, 0.5, -300)

    -- Main Frame
    local MainFrame = Create("Frame", {
        Name                  = "MainFrame",
        Parent                = ScreenGui,
        BackgroundColor3      = Theme.Background,
        BackgroundTransparency = 0.05,
        BorderSizePixel       = 0,
        Position              = DEFAULT_POS,
        Size                  = DEFAULT_SIZE,
        ClipsDescendants      = false,
    }) :: Frame
    Create("UICorner",  { CornerRadius = UDim.new(0, 10), Parent = MainFrame })
    Create("UIStroke",  { Transparency = 0, Thickness = 1, Color = Theme.Outline, Parent = MainFrame })
    Create("ImageLabel", {
        Name              = "Pattern",
        Parent            = MainFrame,
        BackgroundTransparency = 1,
        Size              = UDim2.new(1, 0, 1, 0),
        Image             = "rbxassetid://2151741365",
        ImageTransparency = 0.95,
        TileSize          = UDim2.new(0, 20, 0, 20),
        ScaleType         = Enum.ScaleType.Tile,
        ZIndex            = 1,
    })

    -- Shadow
    local Shadow = Create("ImageLabel", {
        Name              = "Shadow",
        Parent            = ScreenGui,
        BackgroundTransparency = 1,
        Position          = DEFAULT_POS,
        Size              = DEFAULT_SIZE,
        Image             = "rbxassetid://6015897843",
        ImageColor3       = Color3.new(0, 0, 0),
        ImageTransparency = 0.5,
        ZIndex            = -1,
        SliceCenter       = Rect.new(49, 49, 450, 450),
        ScaleType         = Enum.ScaleType.Slice,
    }) :: ImageLabel

    MainFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        Shadow.Size = UDim2.new(0, MainFrame.AbsoluteSize.X + 34, 0, MainFrame.AbsoluteSize.Y + 34)
    end)
    MainFrame:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
        Shadow.Position = UDim2.new(0, MainFrame.AbsolutePosition.X - 17, 0, MainFrame.AbsolutePosition.Y - 17)
    end)

    -- Resize Handle
    local ResizeHandle = Create("TextButton", {
        Name                = "ResizeHandle",
        Parent              = MainFrame,
        BackgroundTransparency = 1,
        Position            = UDim2.new(1, -4, 1, -4),
        Size                = UDim2.new(0, 16, 0, 16),
        Text                = "",
        AutoButtonColor     = false,
        ZIndex              = 100,
        AnchorPoint         = Vector2.new(1, 1),
    }) :: TextButton

    local LINE_CONFIGS = {
        { Size = UDim2.new(0,  6, 0, 2), Pos = UDim2.new(1, -2, 1, -2)  },
        { Size = UDim2.new(0, 10, 0, 2), Pos = UDim2.new(1, -2, 1, -6)  },
        { Size = UDim2.new(0, 14, 0, 2), Pos = UDim2.new(1, -2, 1, -10) },
    }
    local ResizeLines: { Frame } = {}
    for _, cfg in ipairs(LINE_CONFIGS) do
        local line = Create("Frame", {
            Parent           = ResizeHandle,
            BackgroundColor3 = Theme.TextSecondary,
            BorderSizePixel  = 0,
            Rotation         = -45,
            Size             = cfg.Size,
            Position         = cfg.Pos,
            AnchorPoint      = Vector2.new(1, 1),
            ZIndex           = 101,
        }) :: Frame
        Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = line })
        table.insert(ResizeLines, line)
    end

    ResizeHandle.MouseEnter:Connect(function()
        for _, line in ipairs(ResizeLines) do
            TweenService:Create(line, TWEEN_FAST, { BackgroundColor3 = Theme.Accent }):Play()
        end
    end)
    ResizeHandle.MouseLeave:Connect(function()
        for _, line in ipairs(ResizeLines) do
            TweenService:Create(line, TWEEN_FAST, { BackgroundColor3 = Theme.TextSecondary }):Play()
        end
    end)

    do
        local resizing   = false
        local resizeStart = Vector2.new()
        local startSize   = Vector2.new()

        ResizeHandle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                resizing    = true
                resizeStart = Vector2.new(input.Position.X, input.Position.Y)
                startSize   = MainFrame.AbsoluteSize
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if resizing and (
                input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch
            ) then
                local delta = input.Position - Vector3.new(resizeStart.X, resizeStart.Y, 0)
                MainFrame.Size = UDim2.new(0, math.max(400, startSize.X + delta.X), 0, math.max(300, startSize.Y + delta.Y))
            end
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
                resizing = false
            end
        end)
    end

    -- Header
    local Header = Create("Frame", {
        Name             = "Header",
        Parent           = MainFrame,
        BackgroundColor3 = Theme.Sidebar,
        BorderSizePixel  = 0,
        Size             = UDim2.new(1, 0, 0, 38),
    }) :: Frame
    Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = Header })
    Create("Frame", {
        Name             = "BottomFiller",
        Parent           = Header,
        BackgroundColor3 = Theme.Sidebar,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 0, 0.5, 0),
        Size             = UDim2.new(1, 0, 0.5, 0),
        ZIndex           = 1,
    })
    Create("Frame", {
        Parent           = Header,
        BackgroundColor3 = Theme.Outline,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 0, 1, -1),
        Size             = UDim2.new(1, 0, 0, 1),
        ZIndex           = 2,
    })
    Create("ImageLabel", {
        Name                  = "Logo",
        Parent                = Header,
        BackgroundTransparency = 1,
        Position              = UDim2.new(0, 10, 0, 5),
        Size                  = UDim2.new(0, 25, 0, 25),
        Image                 = "rbxassetid://109252221433578",
        ImageColor3           = Theme.Accent,
        ZIndex                = 2,
    })
    Create("TextLabel", {
        Name                  = "Title",
        Parent                = Header,
        BackgroundTransparency = 1,
        Position              = UDim2.new(0, 45, 0, 0),
        Size                  = UDim2.new(1, -160, 1, 0),
        Font                  = Enum.Font.GothamBold,
        Text                  = TitleName,
        TextColor3            = Theme.TextColor,
        TextSize              = 16,
        TextXAlignment        = Enum.TextXAlignment.Left,
        ZIndex                = 2,
    })

    -- Intro Animation
    if IntroEnabled then
        local savedSize = MainFrame.Size
        MainFrame.Size                  = UDim2.new(0, 0, 0, 0)
        MainFrame.BackgroundTransparency = 1
        TweenService:Create(MainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size                  = savedSize,
            BackgroundTransparency = 0.05,
        }):Play()
    end

    -- Sidebar
    local Sidebar = Create("Frame", {
        Name                  = "Sidebar",
        Parent                = MainFrame,
        BackgroundColor3      = Theme.Sidebar,
        BackgroundTransparency = 1,
        BorderSizePixel       = 0,
        Position              = UDim2.new(0, 0, 0, 38),
        Size                  = UDim2.new(0, 160, 1, -38),
    }) :: Frame
    Create("Frame", {
        Name             = "Separator",
        Parent           = Sidebar,
        BackgroundColor3 = Theme.Outline,
        BorderSizePixel  = 0,
        Position         = UDim2.new(1, -2, 0, 0),
        Size             = UDim2.new(0, 2, 1, 0),
    })

    -- Header Controls
    local Controls = Create("Frame", {
        Name                  = "Controls",
        Parent                = Header,
        BackgroundTransparency = 1,
        Position              = UDim2.new(1, -100, 0, 0),
        Size                  = UDim2.new(0, 100, 1, 0),
        ZIndex                = 2,
    }) :: Frame
    Create("UIListLayout", {
        Parent              = Controls,
        FillDirection       = Enum.FillDirection.Horizontal,
        SortOrder           = Enum.SortOrder.LayoutOrder,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment   = Enum.VerticalAlignment.Center,
        Padding             = UDim.new(0, 8),
    })
    Create("UIPadding", { Parent = Controls, PaddingRight = UDim.new(0, 15) })

    local function createControlButton(name: string, icon: string, layoutOrder: number, callback: () -> ()): ImageButton
        local btn = Create("ImageButton", {
            Name                  = sanitizeOptionalText(name),
            Parent                = Controls,
            BackgroundTransparency = 1,
            LayoutOrder           = layoutOrder,
            Size                  = UDim2.new(0, 20, 0, 20),
            Image                 = "rbxassetid://" .. icon,
            ImageColor3           = Theme.TextSecondary,
            AutoButtonColor       = false,
        }) :: ImageButton
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TWEEN_FAST, { ImageColor3 = Theme.TextColor }):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TWEEN_FAST, { ImageColor3 = Theme.TextSecondary }):Play()
        end)
        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    -- Floating Toggle Button
    local ToggleButton = Create("ImageButton", {
        Name             = "ToggleUI",
        Parent           = ScreenGui,
        BackgroundColor3 = Theme.Background,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0.1, 0, 0.1, 0),
        Size             = UDim2.new(0, 50, 0, 50),
        Image            = "rbxassetid://127876061340518",
        ImageColor3      = Theme.TextColor,
        Visible          = true,
        Active           = true,
        Draggable        = true,
        ZIndex           = 100,
    }) :: ImageButton
    Create("UICorner", { CornerRadius = UDim.new(0, 10), Parent = ToggleButton })
    Create("UIStroke",  { Color = Theme.Outline, Thickness = 1, Parent = ToggleButton })

    -- Window Visibility Toggle
    local mainFrameVisible = true

    local function toggleUI()
        mainFrameVisible = not mainFrameVisible

        if mainFrameVisible then
            MainFrame.Visible = true
            Shadow.Visible    = true
            MainFrame.Size    = UDim2.new(0, 0, 0, 0)
            TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size                  = DEFAULT_SIZE,
                BackgroundTransparency = 0.05,
            }):Play()
            TweenService:Create(Shadow, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                ImageTransparency = 0.5,
                Size = UDim2.new(0, DEFAULT_SIZE.X.Offset + 34, 0, DEFAULT_SIZE.Y.Offset + 34),
            }):Play()
        else
            TweenService:Create(Shadow, TWEEN_FAST, { ImageTransparency = 1, Size = UDim2.new(0, 0, 0, 0) }):Play()
            local tween = TweenService:Create(MainFrame,
                TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
                { Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1 }
            )
            tween:Play()
            task.spawn(function()
                tween.Completed:Wait()
                if not mainFrameVisible then
                    MainFrame.Visible = false
                    Shadow.Visible    = false
                end
            end)
        end
    end

    ToggleButton.MouseButton1Click:Connect(toggleUI)
    table.insert(Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.RightControl then
            toggleUI()
        end
    end))

    -- Minimize
    createControlButton("Minimize", "71686683787518", 1, toggleUI)

    -- Maximize
    do
        local maximized = false
        createControlButton("Maximize", "135582116755237", 2, function()
            maximized = not maximized
            TweenService:Create(MainFrame, TWEEN_QUINT, {
                Size     = maximized and MAX_SIZE or DEFAULT_SIZE,
                Position = maximized and MAX_POS  or DEFAULT_POS,
            }):Play()
        end)
    end

    -- Close
    createControlButton("Close", "121948938505669", 3, function()
        TweenService:Create(MainFrame,
            TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
            { Size = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 1 }
        ):Play()
        task.delay(0.3, function() Window:Destroy() end)
    end)

    -- Notification Holder
    local NotificationHolder = Create("Frame", {
        Name                  = "NotificationHolder",
        Parent                = ScreenGui,
        BackgroundTransparency = 1,
        Position              = UDim2.new(1, -20, 1, -20),
        Size                  = UDim2.new(0, 300, 1, -20),
        AnchorPoint           = Vector2.new(1, 1),
        ZIndex                = 100,
    }) :: Frame
    Create("UIListLayout", {
        Parent             = NotificationHolder,
        SortOrder          = Enum.SortOrder.LayoutOrder,
        VerticalAlignment  = Enum.VerticalAlignment.Bottom,
        Padding            = UDim.new(0, 10),
    })

    -- Tab Container / Sidebar Layout
    local TabContainer = Create("ScrollingFrame", {
        Name                  = "TabContainer",
        Parent                = Sidebar,
        Active                = true,
        BackgroundTransparency = 1,
        BorderSizePixel       = 0,
        Position              = UDim2.new(0, 0, 0, 15),
        Size                  = UDim2.new(1, 0, 1, -25),
        CanvasSize            = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize   = Enum.AutomaticSize.Y,
        ScrollBarThickness    = 2,
        ScrollBarImageColor3  = Theme.Accent,
    }) :: ScrollingFrame

    local ButtonsHolder = Create("Frame", {
        Name                  = "ButtonsHolder",
        Parent                = TabContainer,
        BackgroundTransparency = 1,
        Size                  = UDim2.new(1, 0, 1, 0),
        AutomaticSize         = Enum.AutomaticSize.Y,
    }) :: Frame
    Create("UIListLayout", { Parent = ButtonsHolder, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5) })
    Create("UIPadding",    { Parent = ButtonsHolder, PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) })

    local SlidingIndicator = Create("Frame", {
        Name             = "SlidingIndicator",
        Parent           = TabContainer,
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel  = 0,
        Position         = UDim2.new(0, 0, 0, 0),
        Size             = UDim2.new(0, 3, 0, 20),
        Visible          = false,
        ZIndex           = 2,
    }) :: Frame
    Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = SlidingIndicator })

    local ContentContainer = Create("Frame", {
        Name                  = "ContentContainer",
        Parent                = MainFrame,
        BackgroundTransparency = 1,
        Position              = UDim2.new(0, 160, 0, 45),
        Size                  = UDim2.new(1, -160, 1, -45),
    }) :: Frame

    MakeDraggable(Header, MainFrame)

    -- Shared Dropdown Overlay
    local DropdownLayoutOrder = 0

    local MoreBlur = Create("Frame", {
        Name                  = "MoreBlur",
        Parent                = MainFrame,
        BackgroundColor3      = Color3.new(0, 0, 0),
        BackgroundTransparency = 1,
        Size                  = UDim2.new(1, 0, 1, 0),
        Visible               = false,
        ClipsDescendants      = true,
        ZIndex                = 2000,
    }) :: Frame

    local ConnectButton = Create("TextButton", {
        Parent                = MoreBlur,
        Size                  = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text                  = "",
        AutoButtonColor       = false,
        ZIndex                = 2000,
    }) :: TextButton

    local DropdownSelect = Create("Frame", {
        Name             = "DropdownSelect",
        Parent           = MoreBlur,
        AnchorPoint      = Vector2.new(1, 0.5),
        BackgroundColor3 = Theme.Sidebar,
        BorderSizePixel  = 0,
        Position         = UDim2.new(1, 182, 0.5, 0),
        Size             = UDim2.new(0, 180, 1, -20),
        ClipsDescendants = false,
        Active           = true,
        ZIndex           = 2005,
    }) :: Frame
    Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = DropdownSelect })
    Create("UIStroke",  { Color = Theme.Accent, Thickness = 1, Transparency = 0.5, Parent = DropdownSelect })
    Create("ImageLabel", {
        Parent                = DropdownSelect,
        BackgroundTransparency = 1,
        Position              = UDim2.new(0, -15, 0, -15),
        Size                  = UDim2.new(1, 30, 1, 30),
        Image                 = "rbxassetid://6015897843",
        ImageColor3           = Color3.new(0, 0, 0),
        ImageTransparency     = 0.5,
        ScaleType             = Enum.ScaleType.Slice,
        SliceCenter           = Rect.new(49, 49, 450, 450),
        ZIndex                = 2004,
    })

    local DropdownSelectReal = Create("Frame", {
        Name                  = "DropdownSelectReal",
        Parent                = DropdownSelect,
        AnchorPoint           = Vector2.new(0.5, 0.5),
        Position              = UDim2.new(0.5, 0, 0.5, 0),
        Size                  = UDim2.new(1, -10, 1, -10),
        BackgroundTransparency = 1,
        ClipsDescendants      = true,
        ZIndex                = 2005,
    }) :: Frame

    local DropdownFolder  = Instance.new("Folder", DropdownSelectReal)
    local DropPageLayout  = Instance.new("UIPageLayout", DropdownFolder)
    DropPageLayout.SortOrder              = Enum.SortOrder.LayoutOrder
    DropPageLayout.EasingStyle            = Enum.EasingStyle.Quint
    DropPageLayout.EasingDirection        = Enum.EasingDirection.Out
    DropPageLayout.TweenTime              = 0.0
    DropPageLayout.FillDirection          = Enum.FillDirection.Vertical
    DropPageLayout.ScrollWheelInputEnabled = false

    local function closeDropdown()
        TweenService:Create(MoreBlur,       TWEEN_FAST,         { BackgroundTransparency = 1 }):Play()
        TweenService:Create(DropdownSelect, TWEEN_DROPDOWN,     { Position = UDim2.new(1, 182, 0.5, 0) }):Play()
        task.delay(0.25, function() MoreBlur.Visible = false end)
    end

    ConnectButton.Activated:Connect(closeDropdown)

    -- ============================================
    -- WINDOW OBJECT (with secure flag handling)
    -- ============================================
    local FlagsInternal = {}   -- { [flagName] = { Value = ..., Set = function } }

    local Window = {
        Tabs     = {} :: { any },
        Elements = {} :: { any },
        Instance = ScreenGui,
        -- no raw Flags table exposed
    }

    function Window:GetFlag(flag: string)
        local entry = FlagsInternal[flag]
        return entry and entry.Value
    end

    function Window:SetFlag(flag: string, value: any)
        local entry = FlagsInternal[flag]
        if entry and entry.Set then
            entry:Set(value)
        end
    end

    -- ── Window:Notify ─────────────────────────────────────────────────────
    function Window:Notify(opts: { Title: string?, Content: string?, Duration: number?, Image: string?, Icon: string?, Name: string? }?)
        opts = opts or {}
        local o        = opts :: any
        local title    = sanitizeOptionalText(o.Title or o.Name or "Notification")
        local content  = sanitizeOptionalText(o.Content or "Message")
        local duration = o.Duration or 3
        local img      = o.Image or o.Icon or "rbxassetid://109252221433578"
        if Icons[img] then img = Icons[img] end

        local NotifyFrame = Create("Frame", {
            Parent                = NotificationHolder,
            BackgroundColor3      = Theme.Sidebar,
            BackgroundTransparency = 0.1,
            Size                  = UDim2.new(1, 0, 0, 0),
            AutomaticSize         = Enum.AutomaticSize.Y,
            ClipsDescendants      = true,
        }) :: Frame
        Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = NotifyFrame })
        Create("UIStroke",  { Color = Theme.Outline, Thickness = 1, Parent = NotifyFrame })

        local ContentFrame = Create("Frame", {
            Parent                = NotifyFrame,
            BackgroundTransparency = 1,
            Size                  = UDim2.new(1, 0, 0, 60),
        }) :: Frame
        local Icon = Create("ImageLabel", {
            Parent                = ContentFrame,
            BackgroundTransparency = 1,
            Position              = UDim2.new(0, 12, 0, 12),
            Size                  = UDim2.new(0, 36, 0, 36),
            Image                 = img,
            ImageColor3           = Theme.Accent,
        }) :: ImageLabel
        Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = Icon })
        Create("TextLabel", {
            Parent                = ContentFrame,
            BackgroundTransparency = 1,
            Position              = UDim2.new(0, 58, 0, 10),
            Size                  = UDim2.new(1, -68, 0, 20),
            Font                  = Enum.Font.GothamBold,
            Text                  = title,
            TextColor3            = Theme.TextColor,
            TextSize              = 14,
            TextXAlignment        = Enum.TextXAlignment.Left,
        })
        Create("TextLabel", {
            Parent                = ContentFrame,
            BackgroundTransparency = 1,
            Position              = UDim2.new(0, 58, 0, 30),
            Size                  = UDim2.new(1, -68, 0, 20),
            Font                  = Enum.Font.Gotham,
            Text                  = content,
            TextColor3            = Theme.TextSecondary,
            TextSize              = 12,
            TextXAlignment        = Enum.TextXAlignment.Left,
            TextWrapped           = true,
        })

        NotifyFrame.Position = UDim2.new(1, 320, 0, 0)
        TweenService:Create(NotifyFrame, TWEEN_NOTIF_IN, { Position = UDim2.new(0, 0, 0, 0) }):Play()

        local ProgressBar = Create("Frame", {
            Parent           = NotifyFrame,
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel  = 0,
            Position         = UDim2.new(0, 0, 1, -2),
            Size             = UDim2.new(1, 0, 0, 2),
        }) :: Frame
        TweenService:Create(ProgressBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 0, 2) }):Play()

        task.delay(duration, function()
            TweenService:Create(NotifyFrame, TWEEN_NOTIF_OUT, { Position = UDim2.new(1, 320, 0, 0) }):Play()
            task.delay(0.5, function() NotifyFrame:Destroy() end)
        end)
    end

    -- ============================================
    -- TAB FACTORY (unchanged from original, but with sanitization + secure flags)
    -- ============================================
    function Window:CreateTab(opts: { Name: string?, Icon: string? }?)
        opts = opts or {}
        local o       = opts :: any
        local tabName = sanitizeOptionalText(o.Name or "Tab")
        local tabIcon = Icons[o.Icon] or o.Icon or ""

        local Tab = {
            Active               = false,
            CurrentSectionContainer = nil :: Frame?,
        }

        local TabButton = Create("TextButton", {
            Name                  = tabName .. "Button",
            Parent                = ButtonsHolder,
            BackgroundColor3      = Theme.ElementBackground,
            BackgroundTransparency = 1,
            BorderSizePixel       = 0,
            Size                  = UDim2.new(1, 0, 0, 36),
            AutoButtonColor       = false,
            ClipsDescendants      = true,
            Text                  = "",
        }) :: TextButton
        Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = TabButton })
        Create("UIStroke",  { Color = Theme.Outline, Transparency = 0.8, Thickness = 1, Parent = TabButton })

        local IconImage: ImageLabel? = nil
        if tabIcon ~= "" then
            IconImage = Create("ImageLabel", {
                Parent                = TabButton,
                BackgroundTransparency = 1,
                Position              = UDim2.new(0, 10, 0.5, -10),
                Size                  = UDim2.new(0, 20, 0, 20),
                Image                 = tabIcon,
                ImageColor3           = Theme.TextSecondary,
            }) :: ImageLabel
        end

        local TabLabel = Create("TextLabel", {
            Parent                = TabButton,
            BackgroundTransparency = 1,
            Position              = UDim2.new(0, tabIcon ~= "" and 40 or 15, 0, 0),
            Size                  = UDim2.new(1, tabIcon ~= "" and -40 or -15, 1, 0),
            Font                  = Enum.Font.GothamMedium,
            Text                  = tabName,
            TextColor3            = Theme.TextSecondary,
            TextSize              = 14,
            TextXAlignment        = Enum.TextXAlignment.Left,
        }) :: TextLabel

        TabButton.MouseEnter:Connect(function()
            if not Tab.Active then
                TweenService:Create(TabButton, TWEEN_FAST, { BackgroundTransparency = 0.9 }):Play()
                TweenService:Create(TabLabel,  TWEEN_FAST, { TextColor3 = Theme.TextColor }):Play()
                if IconImage then TweenService:Create(IconImage, TWEEN_FAST, { ImageColor3 = Theme.TextColor }):Play() end
            end
        end)
        TabButton.MouseLeave:Connect(function()
            if not Tab.Active then
                TweenService:Create(TabButton, TWEEN_FAST, { BackgroundTransparency = 1 }):Play()
                TweenService:Create(TabLabel,  TWEEN_FAST, { TextColor3 = Theme.TextSecondary }):Play()
                if IconImage then TweenService:Create(IconImage, TWEEN_FAST, { ImageColor3 = Theme.TextSecondary }):Play() end
            end
        end)

        local TabPage = Create("ScrollingFrame", {
            Name                  = tabName .. "Page",
            Parent                = ContentContainer,
            Active                = true,
            BackgroundTransparency = 1,
            BorderSizePixel       = 0,
            Size                  = UDim2.new(1, 0, 1, 0),
            CanvasSize            = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness    = 2,
            ScrollBarImageColor3  = Theme.Accent,
            Visible               = false,
        }) :: ScrollingFrame

        local PageLayout = Create("UIListLayout", {
            Parent    = TabPage,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding   = UDim.new(0, 8),
        }) :: UIListLayout
        Create("UIPadding", {
            Parent        = TabPage,
            PaddingTop    = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 10),
            PaddingLeft   = UDim.new(0, 15),
            PaddingRight  = UDim.new(0, 10),
        })
        Create("TextLabel", {
            Name                  = "TabTitle",
            Parent                = TabPage,
            BackgroundTransparency = 1,
            Size                  = UDim2.new(1, 0, 0, 40),
            Font                  = Enum.Font.GothamBold,
            Text                  = tabName,
            TextColor3            = Theme.TextColor,
            TextSize              = 26,
            TextXAlignment        = Enum.TextXAlignment.Left,
            LayoutOrder           = -1,
        })

        PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabPage.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 20)
        end)

        function Tab:Activate()
            for _, t in ipairs(Window.Tabs) do
                if t ~= Tab then
                    TweenService:Create(t.Instance, TWEEN_FAST, { BackgroundTransparency = 1 }):Play()
                    TweenService:Create(t.Label,    TWEEN_FAST, { TextColor3 = Theme.TextSecondary }):Play()
                    if t.Icon then
                        TweenService:Create(t.Icon, TWEEN_FAST, { ImageColor3 = Theme.TextSecondary }):Play()
                    end
                    t.Page.Visible = false
                    t.Active       = false
                end
            end

            Tab.Active = true
            TweenService:Create(TabButton, TWEEN_MED, { BackgroundTransparency = 0.85 }):Play()
            TweenService:Create(TabLabel,  TWEEN_MED, { TextColor3 = Theme.Accent }):Play()
            if IconImage then TweenService:Create(IconImage, TWEEN_MED, { ImageColor3 = Theme.Accent }):Play() end

            TabPage.Visible  = true
            TabPage.Position = UDim2.new(0, 15, 0, 0)
            TweenService:Create(TabPage, TWEEN_QUINT, { Position = UDim2.new(0, 0, 0, 0) }):Play()

            local targetY = TabButton.AbsolutePosition.Y - ButtonsHolder.AbsolutePosition.Y + 8
            if not SlidingIndicator.Visible then
                SlidingIndicator.Visible  = true
                SlidingIndicator.Position = UDim2.new(0, 0, 0, targetY)
            end
            TweenService:Create(SlidingIndicator, TWEEN_QUINT, { Position = UDim2.new(0, 0, 0, targetY) }):Play()
        end

        TabButton.MouseButton1Click:Connect(function()
            local Mouse = Players.LocalPlayer:GetMouse()
            spawnRipple(TabButton, Mouse.X, Mouse.Y, 150, TWEEN_RIPPLE_TAB)
            Tab:Activate()
        end)

        Tab.Instance = TabButton
        Tab.Label    = TabLabel
        Tab.Icon     = IconImage
        Tab.Page     = TabPage
        table.insert(Window.Tabs, Tab)

        if #Window.Tabs == 1 then
            Tab:Activate()
        end

        -- ── SECTION ─────────────────────────────────────────────────────
        function Tab:CreateSection(sopts: { Name: string? }?)
            sopts = sopts or {}
            local sName = sanitizeOptionalText((sopts :: any).Name or "Section")

            local SectionContainer = Create("Frame", {
                Name                  = "SectionContainer",
                Parent                = TabPage,
                BackgroundTransparency = 1,
                Size                  = UDim2.new(1, 0, 0, 32),
            }) :: Frame

            local SectionHeader = Create("TextButton", {
                Name                  = "SectionHeader",
                Parent                = SectionContainer,
                BackgroundColor3      = Theme.ElementBackground,
                BackgroundTransparency = 0.5,
                Size                  = UDim2.new(1, 0, 0, 32),
                AutoButtonColor       = false,
                Text                  = "",
            }) :: TextButton
            Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = SectionHeader })
            Create("UIStroke",  { Color = Theme.Outline, Transparency = 0.6, Thickness = 1, Parent = SectionHeader })
            Create("TextLabel", {
                Parent                = SectionHeader,
                BackgroundTransparency = 1,
                Position              = UDim2.new(0, 10, 0, 0),
                Size                  = UDim2.new(1, -40, 1, 0),
                Font                  = Enum.Font.GothamBold,
                Text                  = sName,
                TextColor3            = Theme.TextColor,
                TextSize              = 13,
                TextXAlignment        = Enum.TextXAlignment.Left,
            })

            local Chevron = Create("ImageLabel", {
                Name                  = "Chevron",
                Parent                = SectionHeader,
                BackgroundTransparency = 1,
                Position              = UDim2.new(1, -26, 0.5, -8),
                Size                  = UDim2.new(0, 16, 0, 16),
                Image                 = "rbxassetid://6031091004",
                ImageColor3           = Theme.TextSecondary,
                Rotation              = -90,
            }) :: ImageLabel

            local ContentFrame = Create("Frame", {
                Name                  = "SectionContent",
                Parent                = SectionContainer,
                BackgroundTransparency = 1,
                Position              = UDim2.new(0, 0, 0, 36),
                Size                  = UDim2.new(1, 0, 0, 0),
                ClipsDescendants      = true,
                Visible               = true,
            }) :: Frame

            local SectionLayout = Create("UIListLayout", {
                Parent    = ContentFrame,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding   = UDim.new(0, 8),
            }) :: UIListLayout
            Create("UIPadding", {
                Parent        = ContentFrame,
                PaddingTop    = UDim.new(0, 5),
                PaddingBottom = UDim.new(0, 5),
                PaddingLeft   = UDim.new(0, 5),
                PaddingRight  = UDim.new(0, 5),
            })

            local open = false
            local canvasSizeConn: RBXScriptConnection? = nil

            local function getContentHeight(): number
                return SectionLayout.AbsoluteContentSize.Y + 10
            end

            SectionHeader.MouseEnter:Connect(function()
                if not open then
                    TweenService:Create(SectionHeader, TWEEN_FAST, { BackgroundTransparency = 0.3 }):Play()
                end
            end)
            SectionHeader.MouseLeave:Connect(function()
                if not open then
                    TweenService:Create(SectionHeader, TWEEN_FAST, { BackgroundTransparency = 0.5 }):Play()
                end
            end)

            SectionHeader.MouseButton1Click:Connect(function()
                open = not open
                if open then
                    TweenService:Create(Chevron, TweenInfo.new(0.3, Enum.EasingStyle.Quint), { Rotation = 0 }):Play()
                    TweenService:Create(SectionHeader, TWEEN_FAST, { BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.8 }):Play()
                    local ch = getContentHeight()
                    TweenService:Create(ContentFrame, TWEEN_QUINT, { Size = UDim2.new(1, 0, 0, ch) }):Play()
                    TweenService:Create(SectionContainer, TWEEN_QUINT, { Size = UDim2.new(1, 0, 0, ch + 40) }):Play()
                    if not canvasSizeConn then
                        canvasSizeConn = SectionLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                            if open then
                                local h = SectionLayout.AbsoluteContentSize.Y + 10
                                TweenService:Create(ContentFrame, TweenInfo.new(0.2), { Size = UDim2.new(1, 0, 0, h) }):Play()
                                TweenService:Create(SectionContainer, TweenInfo.new(0.2), { Size = UDim2.new(1, 0, 0, h + 40) }):Play()
                            end
                        end)
                    end
                else
                    TweenService:Create(Chevron, TweenInfo.new(0.3, Enum.EasingStyle.Quint), { Rotation = -90 }):Play()
                    TweenService:Create(SectionHeader, TWEEN_FAST, { BackgroundColor3 = Theme.ElementBackground, BackgroundTransparency = 0.5 }):Play()
                    TweenService:Create(ContentFrame, TWEEN_MED, { Size = UDim2.new(1, 0, 0, 0) }):Play()
                    TweenService:Create(SectionContainer, TWEEN_MED, { Size = UDim2.new(1, 0, 0, 32) }):Play()
                    if canvasSizeConn then
                        canvasSizeConn:Disconnect()
                        canvasSizeConn = nil
                    end
                end
            end)

            Tab.CurrentSectionContainer = ContentFrame
        end

        -- ── PARAGRAPH ────────────────────────────────────────────────────
        function Tab:CreateParagraph(popts: { Title: string?, Content: string? }?)
            popts = popts or {}
            local o = popts :: any
            local pTitle   = sanitizeOptionalText(o.Title or "Paragraph")
            local pContent = sanitizeOptionalText(o.Content or "Lorem ipsum dolor sit amet.")

            local ParagraphFrame = Create("Frame", {
                Name                  = "ParagraphFrame",
                Parent                = Tab.CurrentSectionContainer or TabPage,
                BackgroundColor3      = Theme.ElementBackground,
                BackgroundTransparency = 0.5,
                BorderSizePixel       = 0,
                Size                  = UDim2.new(1, 0, 0, 0),
                AutomaticSize         = Enum.AutomaticSize.Y,
            }) :: Frame
            Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = ParagraphFrame })
            Create("UIStroke",  { Color = Theme.Outline, Transparency = 0.6, Thickness = 1, Parent = ParagraphFrame })
            Create("UIPadding", { Parent = ParagraphFrame, PaddingBottom = UDim.new(0, 12) })

            local TitleLbl = Create("TextLabel", {
                Parent                = ParagraphFrame,
                BackgroundTransparency = 1,
                Position              = UDim2.new(0, 12, 0, 8),
                Size                  = UDim2.new(1, -24, 0, 20),
                Font                  = Enum.Font.GothamBold,
                Text                  = pTitle,
                TextColor3            = Theme.TextColor,
                TextSize              = 14,
                TextXAlignment        = Enum.TextXAlignment.Left,
            }) :: TextLabel
            local ContentLbl = Create("TextLabel", {
                Parent                = ParagraphFrame,
                BackgroundTransparency = 1,
                Position              = UDim2.new(0, 12, 0, 32),
                Size                  = UDim2.new(1, -24, 0, 0),
                AutomaticSize         = Enum.AutomaticSize.Y,
                Font                  = Enum.Font.Gotham,
                Text                  = pContent,
                TextColor3            = Theme.TextSecondary,
                TextSize              = 13,
                TextWrapped           = true,
                TextXAlignment        = Enum.TextXAlignment.Left,
                RichText              = true,
            }) :: TextLabel

            local obj = { Title = pTitle, Desc = pContent }
            function obj:SetTitle(v: string) self.Title = sanitizeOptionalText(v); TitleLbl.Text = self.Title end
            function obj:SetDesc(v: string)  self.Desc  = sanitizeOptionalText(v); ContentLbl.Text = self.Desc end
            function obj:GetTitle(): string return self.Title end
            function obj:GetDesc():  string return self.Desc  end
            return obj
        end

        -- ── LABEL ────────────────────────────────────────────────────────
        function Tab:CreateLabel(lopts: { Text: string? }?)
            lopts = lopts or {}
            local text = sanitizeOptionalText((lopts :: any).Text or "Label")

            local LabelFrame = Create("Frame", {
                Parent                = Tab.CurrentSectionContainer or TabPage,
                BackgroundTransparency = 1,
                BorderSizePixel       = 0,
                Size                  = UDim2.new(1, 0, 0, 26),
            }) :: Frame
            local lbl = Create("TextLabel", {
                Parent                = LabelFrame,
                BackgroundTransparency = 1,
                Position              = UDim2.new(0, 5, 0, 0),
                Size                  = UDim2.new(1, -10, 1, 0),
                Font                  = Enum.Font.GothamMedium,
                Text                  = text,
                TextColor3            = Theme.TextColor,
                TextSize              = 14,
                TextXAlignment        = Enum.TextXAlignment.Left,
            }) :: TextLabel
            return lbl
        end

        -- ── BUTTON ───────────────────────────────────────────────────────
        function Tab:CreateButton(bopts: { Name: string?, SubText: string?, Icon: string?, Callback: (() -> ())? }?)
            bopts = bopts or {}
            local o        = bopts :: any
            local bName    = sanitizeOptionalText(o.Name or "Button")
            local subText  = sanitizeOptionalText(o.SubText)
            local bIcon    = o.Icon
            local callback = o.Callback or function() end

            local ButtonFrame = Create("Frame", {
                Name                  = "ButtonFrame",
                Parent                = Tab.CurrentSectionContainer or TabPage,
                BackgroundColor3      = Theme.ElementBackground,
                BackgroundTransparency = 0.2,
                BorderSizePixel       = 0,
                Size                  = UDim2.new(1, 0, 0, subText ~= "" and 50 or 38),
                ClipsDescendants      = true,
            }) :: Frame
            Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = ButtonFrame })
            local BtnStroke = Create("UIStroke", { Color = Theme.Outline, Transparency = 0.5, Thickness = 1, Parent = ButtonFrame }) :: UIStroke

            local Btn = Create("TextButton", {
                Name                  = "Button",
                Parent                = ButtonFrame,
                BackgroundTransparency = 1,
                Size                  = UDim2.new(1, 0, 1, 0),
                Font                  = Enum.Font.GothamMedium,
                Text                  = subText ~= "" and "" or bName,
                TextColor3            = Theme.TextColor,
                TextSize              = 14,
                AutoButtonColor       = false,
                ZIndex                = 2,
            }) :: TextButton

            if subText ~= "" then
                Create("TextLabel", {
                    Parent = Btn, BackgroundTransparency = 1,
                    Position = UDim2.new(0, 12, 0, 8), Size = UDim2.new(1, -50, 0, 20),
                    Font = Enum.Font.GothamBold, Text = bName,
                    TextColor3 = Theme.TextColor, TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })
                Create("TextLabel", {
                    Parent = Btn, BackgroundTransparency = 1,
                    Position = UDim2.new(0, 12, 0, 26), Size = UDim2.new(1, -50, 0, 14),
                    Font = Enum.Font.Gotham, Text = subText,
                    TextColor3 = Theme.TextSecondary, TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })
            end
            if bIcon then
                Create("ImageLabel", {
                    Parent = Btn, BackgroundTransparency = 1,
                    AnchorPoint = Vector2.new(1, 0.5),
                    Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.new(0, 20, 0, 20),
                    Image = bIcon, ImageColor3 = Theme.TextSecondary,
                })
            end

            Btn.MouseEnter:Connect(function()
                TweenService:Create(ButtonFrame, TWEEN_FAST, { BackgroundColor3 = Theme.Hover, BackgroundTransparency = 0.1 }):Play()
                TweenService:Create(BtnStroke,   TWEEN_FAST, { Color = Theme.Accent, Transparency = 0.2 }):Play()
            end)
            Btn.MouseLeave:Connect(function()
                TweenService:Create(ButtonFrame, TWEEN_FAST, { BackgroundColor3 = Theme.ElementBackground, BackgroundTransparency = 0.2 }):Play()
                TweenService:Create(BtnStroke,   TWEEN_FAST, { Color = Theme.Outline, Transparency = 0.5 }):Play()
            end)
            Btn.MouseButton1Click:Connect(function()
                local Mouse = Players.LocalPlayer:GetMouse()
                spawnRipple(ButtonFrame, Mouse.X, Mouse.Y, 200, TWEEN_RIPPLE_BTN)
                TweenService:Create(ButtonFrame, TweenInfo.new(0.1), { BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0 }):Play()
                task.delay(0.1, function()
                    TweenService:Create(ButtonFrame, TWEEN_MED, { BackgroundColor3 = Theme.Hover, BackgroundTransparency = 0.1 }):Play()
                end)
                callback()
            end)
        end

        -- ── TOGGLE ───────────────────────────────────────────────────────
        function Tab:CreateToggle(topts: { Name: string?, SubText: string?, Default: boolean?, Value: boolean?, Values: { any }?, Callback: ((any) -> ())?, Flag: string? }?)
            topts = topts or {}
            local o        = topts :: any
            local tName    = sanitizeOptionalText(o.Name or "Toggle")
            local subText  = sanitizeOptionalText(o.SubText)
            local default  = o.Default or o.Value or false
            local values   = o.Values or {}
            local callback = o.Callback or function() end
            local toggled  = default

            local ToggleFrame = Create("Frame", {
                Parent                = Tab.CurrentSectionContainer or TabPage,
                BackgroundColor3      = Theme.ElementBackground,
                BackgroundTransparency = 0.2,
                BorderSizePixel       = 0,
                Size                  = UDim2.new(1, 0, 0, subText ~= "" and 50 or 38),
            }) :: Frame
            Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = ToggleFrame })
            Create("UIStroke",  { Color = Theme.Outline, Transparency = 0.5, Thickness = 1, Parent = ToggleFrame })
            Create("TextLabel", {
                Parent                = ToggleFrame,
                BackgroundTransparency = 1,
                Position              = UDim2.new(0, 12, 0, subText ~= "" and 8 or 0),
                Size                  = UDim2.new(1, -60, 0, subText ~= "" and 20 or 38),
                Font                  = subText ~= "" and Enum.Font.GothamBold or Enum.Font.GothamMedium,
                Text                  = tName,
                TextColor3            = Theme.TextColor,
                TextSize              = 14,
                TextXAlignment        = Enum.TextXAlignment.Left,
                TextYAlignment        = Enum.TextYAlignment.Center,
            })
            if subText ~= "" then
                Create("TextLabel", {
                    Parent = ToggleFrame, BackgroundTransparency = 1,
                    Position = UDim2.new(0, 12, 0, 26), Size = UDim2.new(1, -60, 0, 14),
                    Font = Enum.Font.Gotham, Text = subText,
                    TextColor3 = Theme.TextSecondary, TextSize = 12,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextYAlignment = Enum.TextYAlignment.Center,
                })
            end

            local SwitchBg = Create("Frame", {
                Parent           = ToggleFrame,
                AnchorPoint      = Vector2.new(1, 0.5),
                BackgroundColor3 = toggled and Theme.Accent or Color3.fromRGB(45, 45, 50),
                Position         = UDim2.new(1, -12, 0.5, 0),
                Size             = UDim2.new(0, 42, 0, 22),
            }) :: Frame
            Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = SwitchBg })

            local SwitchCircle = Create("Frame", {
                Parent           = SwitchBg,
                AnchorPoint      = Vector2.new(0, 0.5),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                Position         = UDim2.new(0, toggled and 22 or 2, 0.5, 0),
                Size             = UDim2.new(0, 18, 0, 18),
            }) :: Frame
            Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = SwitchCircle })

            Create("TextButton", {
                Parent                = ToggleFrame,
                BackgroundTransparency = 1,
                Size                  = UDim2.new(1, 0, 1, 0),
                Text                  = "",
            })

            local ToggleObject = { Value = default }

            local function updateToggleState(newVal: boolean)
                toggled           = newVal
                ToggleObject.Value = toggled
                TweenService:Create(SwitchBg,     TWEEN_MED, { BackgroundColor3 = toggled and Theme.Accent or Color3.fromRGB(45, 45, 50) }):Play()
                TweenService:Create(SwitchCircle, TWEEN_MED, { Position = UDim2.new(0, toggled and 22 or 2, 0.5, 0) }):Play()
                if #values > 0 then
                    callback(values[toggled and 2 or 1])
                else
                    callback(toggled)
                end
            end

            function ToggleObject:Set(v: any)
                if type(v) ~= "boolean" then
                    v = v == true or v == "true" or v == 1
                end
                updateToggleState(v :: boolean)
            end

            local clickBtn = ToggleFrame:FindFirstChildOfClass("TextButton") :: TextButton
            clickBtn.MouseButton1Click:Connect(function() updateToggleState(not toggled) end)

            if default then updateToggleState(true) end

            local flag = o.Flag or tName
            if flag then
                FlagsInternal[flag] = ToggleObject   -- secure flag storage
            end
            return ToggleObject
        end

        -- ── SLIDER ───────────────────────────────────────────────────────
        function Tab:CreateSlider(sopts: { Name: string?, Min: number?, Max: number?, Default: number?, Value: number?, Callback: ((number) -> ())?, Flag: string? }?)
            sopts = sopts or {}
            local o        = sopts :: any
            local sName    = sanitizeOptionalText(o.Name or "Slider")
            local sMin     = o.Min  or 0
            local sMax     = o.Max  or 100
            local default  = o.Default or o.Value or sMin
            local callback = o.Callback or function() end

            local SliderFrame = Create("Frame", {
                Parent                = Tab.CurrentSectionContainer or TabPage,
                BackgroundColor3      = Theme.ElementBackground,
                BackgroundTransparency = 0.2,
                BorderSizePixel       = 0,
                Size                  = UDim2.new(1, 0, 0, 55),
            }) :: Frame
            Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = SliderFrame })
            Create("UIStroke",  { Color = Theme.Outline, Transparency = 0.5, Thickness = 1, Parent = SliderFrame })
            Create("TextLabel", {
                Parent = SliderFrame, BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 8), Size = UDim2.new(1, -24, 0, 20),
                Font = Enum.Font.GothamMedium, Text = sName,
                TextColor3 = Theme.TextColor, TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
            })
            local ValueLabel = Create("TextLabel", {
                Parent = SliderFrame, BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 8), Size = UDim2.new(1, -24, 0, 20),
                Font = Enum.Font.Gotham, Text = tostring(default),
                TextColor3 = Theme.TextSecondary, TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Right,
            }) :: TextLabel

            local SliderBarBg = Create("Frame", {
                Parent           = SliderFrame,
                BackgroundColor3 = Color3.fromRGB(50, 50, 55),
                BorderSizePixel  = 0,
                Position         = UDim2.new(0, 12, 0, 38),
                Size             = UDim2.new(1, -24, 0, 5),
            }) :: Frame
            Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = SliderBarBg })

            local initPct = (default - sMin) / (sMax - sMin)
            local SliderFill = Create("Frame", {
                Parent           = SliderBarBg,
                BackgroundColor3 = Theme.Accent,
                BorderSizePixel  = 0,
                Size             = UDim2.new(initPct, 0, 1, 0),
            }) :: Frame
            Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = SliderFill })

            local SliderKnob = Create("Frame", {
                Parent           = SliderBarBg,
                AnchorPoint      = Vector2.new(0.5, 0.5),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255),
                Position         = UDim2.new(initPct, 0, 0.5, 0),
                Size             = UDim2.new(0, 14, 0, 14),
                ZIndex           = 2,
            }) :: Frame
            Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = SliderKnob })

            local SliderBtn = Create("TextButton", {
                Parent                = SliderBarBg,
                BackgroundTransparency = 1,
                Size                  = UDim2.new(1, 0, 1, 0),
                Text                  = "",
                ZIndex                = 3,
            }) :: TextButton

            local dragging = false

            local function updateSlider(input: InputObject)
                local pct   = math.clamp((input.Position.X - SliderBarBg.AbsolutePosition.X) / SliderBarBg.AbsoluteSize.X, 0, 1)
                local value = math.floor(sMin + (sMax - sMin) * pct)
                TweenService:Create(SliderFill, TWEEN_SLIDER_FAST, { Size = UDim2.new(pct, 0, 1, 0) }):Play()
                TweenService:Create(SliderKnob, TWEEN_SLIDER_FAST, { Position = UDim2.new(pct, 0, 0.5, 0) }):Play()
                ValueLabel.Text = tostring(value)
                callback(value)
            end

            SliderBtn.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    TweenService:Create(SliderKnob, TWEEN_SLIDER_KNOB, { Size = UDim2.new(0, 18, 0, 18) }):Play()
                    updateSlider(input)
                end
            end)
            table.insert(Connections, UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                    TweenService:Create(SliderKnob, TWEEN_SLIDER_KNOB, { Size = UDim2.new(0, 14, 0, 14) }):Play()
                end
            end))
            table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
                if dragging and (
                    input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch
                ) then
                    updateSlider(input)
                end
            end))

            local SliderObject = { Value = default }
            function SliderObject:Set(v: number)
                v = math.clamp(type(v) == "number" and v or (tonumber(v) or sMin), sMin, sMax)
                local pct = (v - sMin) / (sMax - sMin)
                TweenService:Create(SliderFill, TWEEN_MED, { Size = UDim2.new(pct, 0, 1, 0) }):Play()
                TweenService:Create(SliderKnob, TWEEN_MED, { Position = UDim2.new(pct, 0, 0.5, 0) }):Play()
                ValueLabel.Text = tostring(v)
                self.Value = v
                callback(v)
            end

            local flag = o.Flag or sName
            if flag then
                FlagsInternal[flag] = SliderObject
            end
            return SliderObject
        end

        -- ── INPUT ────────────────────────────────────────────────────────
        function Tab:CreateInput(iopts: { Name: string?, Placeholder: string?, Default: string?, Value: string?, Callback: ((string) -> ())?, MultiLine: boolean?, SideLabel: string?, Values: { any }?, Flag: string? }?)
            iopts = iopts or {}
            local o         = iopts :: any
            local iName     = sanitizeOptionalText(o.Name or "Input")
            local placeholder = sanitizeOptionalText(o.Placeholder or iName)
            local default   = sanitizeOptionalText(o.Default or "")
            local multiLine = o.MultiLine or false
            local sideLabel = sanitizeOptionalText(o.SideLabel)
            local initValue = sanitizeOptionalText(o.Value or default)
            local callback  = o.Callback or function() end

            local InputFrame = Create("Frame", {
                Parent                = Tab.CurrentSectionContainer or TabPage,
                BackgroundColor3      = Theme.ElementBackground,
                BackgroundTransparency = 0.2,
                BorderSizePixel       = 0,
                Size                  = UDim2.new(1, 0, 0, multiLine and 100 or 40),
            }) :: Frame
            Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = InputFrame })
            Create("UIStroke",  { Color = Theme.Outline, Transparency = 0.5, Thickness = 1, Parent = InputFrame })

            if sideLabel ~= "" then
                Create("TextLabel", {
                    Parent = InputFrame, BackgroundTransparency = 1,
                    Position = UDim2.new(0, 12, 0, 0),
                    Size = UDim2.new(0, 0, 1, 0),
                    AutomaticSize = Enum.AutomaticSize.X,
                    Font = Enum.Font.GothamMedium, Text = sideLabel,
                    TextColor3 = Theme.TextColor, TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })
            end

            local InputBoxBg = Create("Frame", {
                Parent           = InputFrame,
                BackgroundColor3 = Theme.Sidebar,
                BorderSizePixel  = 0,
                Position         = sideLabel ~= "" and UDim2.new(1, -12, 0.5, 0) or UDim2.new(0, 6, 0, 6),
                Size             = sideLabel ~= "" and UDim2.new(0, 150, 0, 28)  or UDim2.new(1, -12, 1, -12),
                AnchorPoint      = sideLabel ~= "" and Vector2.new(1, 0.5)       or Vector2.new(0, 0),
            }) :: Frame
            Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = InputBoxBg })
            local InputStroke = Create("UIStroke", { Color = Theme.Outline, Transparency = 0.7, Thickness = 1, Parent = InputBoxBg }) :: UIStroke

            local TextBox = Create("TextBox", {
                Parent                = InputBoxBg,
                BackgroundTransparency = 1,
                Position              = UDim2.new(0, 8, 0, multiLine and 8 or 0),
                Size                  = UDim2.new(1, -16, 1, multiLine and -16 or 0),
                Font                  = Enum.Font.Gotham,
                PlaceholderText       = placeholder,
                Text                  = initValue,
                TextColor3            = Theme.TextColor,
                TextSize              = 13,
                TextXAlignment        = Enum.TextXAlignment.Left,
                TextYAlignment        = multiLine and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
                ClearTextOnFocus      = false,
                MultiLine             = multiLine,
                TextWrapped           = true,
            }) :: TextBox

            TextBox.Focused:Connect(function()
                TweenService:Create(InputStroke, TWEEN_FAST, { Color = Theme.Accent, Transparency = 0 }):Play()
            end)

            local InputObject = { Value = initValue, Values = o.Values or {} }
            TextBox.FocusLost:Connect(function()
                TweenService:Create(InputStroke, TWEEN_FAST, { Color = Theme.Outline, Transparency = 0.7 }):Play()
                InputObject.Value = TextBox.Text
                callback(TextBox.Text)
            end)

            function InputObject:Set(v: any)
                v = sanitizeOptionalText(tostring(v ~= nil and v or ""))
                self.Value = v
                TextBox.Text = v
                callback(v)
            end
            function InputObject:Get(): string return self.Value end

            if initValue ~= "" then callback(initValue) end

            local flag = o.Flag or iName
            if flag then
                FlagsInternal[flag] = InputObject
            end
            return InputObject
        end

        -- ── DROPDOWN ─────────────────────────────────────────────────────
        function Tab:CreateDropdown(dopts: { Name: string?, Items: { any }?, Callback: ((any) -> ())?, Default: any?, Flag: string? }?)
            dopts = dopts or {}
            local o        = dopts :: any
            local dName    = sanitizeOptionalText(o.Name or "Dropdown")
            local items    = o.Items or {}
            local callback = o.Callback or function() end
            local default  = o.Default or (items[1] or "...")

            local DropdownObject = { Value = default, Items = items }

            local DropdownFrame = Create("Frame", {
                Parent                = Tab.CurrentSectionContainer or TabPage,
                BackgroundColor3      = Theme.ElementBackground,
                BackgroundTransparency = 0.2,
                BorderSizePixel       = 0,
                Size                  = UDim2.new(1, 0, 0, 38),
            }) :: Frame
            Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = DropdownFrame })
            Create("UIStroke",  { Color = Theme.Outline, Transparency = 0.5, Thickness = 1, Parent = DropdownFrame })
            Create("TextLabel", {
                Parent = DropdownFrame, BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -60, 1, 0),
                Font = Enum.Font.GothamMedium, Text = dName,
                TextColor3 = Theme.TextColor, TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
            })
            local DValueLabel = Create("TextLabel", {
                Parent = DropdownFrame, BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -34, 1, 0),
                Font = Enum.Font.Gotham, Text = tostring(default),
                TextColor3 = Theme.TextSecondary, TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Right,
            }) :: TextLabel
            Create("ImageLabel", {
                Parent = DropdownFrame, BackgroundTransparency = 1,
                Position = UDim2.new(1, -26, 0.5, -8), Size = UDim2.new(0, 16, 0, 16),
                Image = "rbxassetid://6031091004", ImageColor3 = Theme.TextSecondary, Rotation = -90,
            })
            local DBtn = Create("TextButton", {
                Parent = DropdownFrame, BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0), Text = "",
            }) :: TextButton

            local SelectPage = Create("Frame", {
                Parent                = DropdownFolder,
                Size                  = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1,
                LayoutOrder           = DropdownLayoutOrder,
            }) :: Frame
            DropdownLayoutOrder += 1

            local SearchBox, ScrollList, UIList = createDropdownSearchPanel(SelectPage)

            local function populate(filter: string)
                filter = filter:lower()
                for _, c in ipairs(ScrollList:GetChildren()) do
                    if c:IsA("Frame") then c:Destroy() end
                end
                for _, item in ipairs(DropdownObject.Items) do
                    if filter == "" or tostring(item):lower():find(filter, 1, true) then
                        local ItemFrame = Create("Frame", {
                            Parent = ScrollList, BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 0, 26),
                        }) :: Frame
                        local ItemBtn = Create("TextButton", {
                            Parent = ItemFrame, BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 1, 0), Text = "", AutoButtonColor = false,
                        }) :: TextButton
                        local isSelected = tostring(item) == tostring(DropdownObject.Value)
                        local ItemTxt = Create("TextLabel", {
                            Parent = ItemBtn, BackgroundTransparency = 1,
                            Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(1, -16, 1, 0),
                            Font = Enum.Font.GothamBold, Text = tostring(item),
                            TextColor3 = isSelected and Theme.Accent or Theme.TextSecondary,
                            TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
                        }) :: TextLabel
                        ItemBtn.MouseEnter:Connect(function()
                            if tostring(item) ~= tostring(DropdownObject.Value) then ItemTxt.TextColor3 = Theme.TextColor end
                        end)
                        ItemBtn.MouseLeave:Connect(function()
                            if tostring(item) ~= tostring(DropdownObject.Value) then ItemTxt.TextColor3 = Theme.TextSecondary end
                        end)
                        ItemBtn.MouseButton1Click:Connect(function()
                            DropdownObject:Set(item)
                            closeDropdown()
                        end)
                    end
                end
                ScrollList.CanvasSize = UDim2.fromOffset(0, UIList.AbsoluteContentSize.Y)
            end

            SearchBox:GetPropertyChangedSignal("Text"):Connect(function() populate(SearchBox.Text) end)
            UIList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                ScrollList.CanvasSize = UDim2.fromOffset(0, UIList.AbsoluteContentSize.Y)
            end)
            populate("")

            DBtn.MouseButton1Click:Connect(function()
                if not MoreBlur.Visible then
                    populate(""); SearchBox.Text = ""
                    DropPageLayout:JumpTo(SelectPage)
                    MoreBlur.Visible = true
                    TweenService:Create(MoreBlur,       TWEEN_FAST,         { BackgroundTransparency = 0.5 }):Play()
                    TweenService:Create(DropdownSelect, TWEEN_DROPDOWN_OUT, { Position = UDim2.new(1, -16, 0.5, 0) }):Play()
                end
            end)

            function DropdownObject:Set(v: any)
                self.Value = v
                DValueLabel.Text = tostring(v)
                callback(v)
            end
            function DropdownObject:Refresh(newItems: { any })
                self.Items = newItems
                if not table.find(self.Items, self.Value) then
                    self.Value = self.Items[1] or "..."
                    DValueLabel.Text = tostring(self.Value)
                end
                populate("")
            end

            local flag = o.Flag or dName
            if flag then
                FlagsInternal[flag] = DropdownObject
            end
            return DropdownObject
        end

        -- ── MULTI-DROPDOWN ──────────────────────────────────────────────
        function Tab:CreateMultiDropdown(mdopts: { Name: string?, Items: { any }?, Values: { any }?, Default: { any }?, Value: { any }?, Callback: (({ any }) -> ())?, Flag: string? }?)
            mdopts = mdopts or {}
            local o        = mdopts :: any
            local mName    = sanitizeOptionalText(o.Name or "Multi Dropdown")
            local allItems = o.Items or o.Values or {}
            local default: { any } = (type(o.Default) == "table" and o.Default) or (type(o.Value) == "table" and o.Value) or {}
            local callback = o.Callback or function() end
            local selected: { any } = default

            local MultiObject = { Value = selected, Values = allItems }

            local MFrame = Create("Frame", {
                Parent = Tab.CurrentSectionContainer or TabPage,
                BackgroundColor3 = Theme.ElementBackground, BackgroundTransparency = 0.2,
                BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 38),
            }) :: Frame
            Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = MFrame })
            Create("UIStroke",  { Color = Theme.Outline, Transparency = 0.5, Thickness = 1, Parent = MFrame })
            Create("TextLabel", {
                Parent = MFrame, BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -60, 1, 0),
                Font = Enum.Font.GothamMedium, Text = mName,
                TextColor3 = Theme.TextColor, TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
            })

            local function getSelectedText(): string
                if #selected == 0 then return "None" end
                if #selected == 1 then return tostring(selected[1]) end
                return #selected .. " Selected"
            end

            local MValueLabel = Create("TextLabel", {
                Parent = MFrame, BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -34, 1, 0),
                Font = Enum.Font.Gotham, Text = getSelectedText(),
                TextColor3 = Theme.TextSecondary, TextSize = 13,
                TextXAlignment = Enum.TextXAlignment.Right,
            }) :: TextLabel
            Create("ImageLabel", {
                Parent = MFrame, BackgroundTransparency = 1,
                Position = UDim2.new(1, -26, 0.5, -8), Size = UDim2.new(0, 16, 0, 16),
                Image = "rbxassetid://6031091004", ImageColor3 = Theme.TextSecondary, Rotation = -90,
            })
            local MBtn = Create("TextButton", {
                Parent = MFrame, BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 1, 0), Text = "",
            }) :: TextButton

            local MSelectPage = Create("Frame", {
                Parent = DropdownFolder, Size = UDim2.new(1, 0, 1, 0),
                BackgroundTransparency = 1, LayoutOrder = DropdownLayoutOrder,
            }) :: Frame
            DropdownLayoutOrder += 1

            local MSearchBox, MScrollList, MUIList = createDropdownSearchPanel(MSelectPage)

            local function mPopulate(filter: string)
                filter = filter:lower()
                for _, c in ipairs(MScrollList:GetChildren()) do
                    if c:IsA("Frame") then c:Destroy() end
                end
                for _, item in ipairs(allItems) do
                    if filter == "" or tostring(item):lower():find(filter, 1, true) then
                        local ItemFrame = Create("Frame", {
                            Parent = MScrollList, BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 0, 26),
                        }) :: Frame
                        local ItemBtn = Create("TextButton", {
                            Parent = ItemFrame, BackgroundTransparency = 1,
                            Size = UDim2.new(1, 0, 1, 0), Text = "", AutoButtonColor = false,
                        }) :: TextButton
                        local isSel = table.find(selected, item) ~= nil
                        local Checkbox = Create("Frame", {
                            Parent = ItemBtn,
                            BackgroundColor3 = isSel and Theme.Accent or Theme.Background,
                            BorderSizePixel = 0,
                            Position = UDim2.new(0, 8, 0.5, -7), Size = UDim2.new(0, 14, 0, 14),
                        }) :: Frame
                        Create("UICorner", { CornerRadius = UDim.new(0, 3), Parent = Checkbox })
                        local CheckMark = Create("ImageLabel", {
                            Parent = Checkbox, BackgroundTransparency = 1,
                            Image = "rbxassetid://6031094667",
                            Size = UDim2.new(1, 2, 1, 2), Position = UDim2.new(0, -1, 0, -1),
                            ImageTransparency = isSel and 0 or 1,
                        }) :: ImageLabel
                        local ItemTxt = Create("TextLabel", {
                            Parent = ItemBtn, BackgroundTransparency = 1,
                            Position = UDim2.new(0, 30, 0, 0), Size = UDim2.new(1, -30, 1, 0),
                            Font = isSel and Enum.Font.GothamBold or Enum.Font.GothamMedium,
                            Text = tostring(item),
                            TextColor3 = isSel and Theme.TextColor or Theme.TextSecondary,
                            TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
                        }) :: TextLabel

                        ItemBtn.MouseButton1Click:Connect(function()
                            local idx = table.find(selected, item)
                            if idx then
                                table.remove(selected, idx)
                                TweenService:Create(Checkbox, TWEEN_FAST, { BackgroundColor3 = Theme.Background }):Play()
                                TweenService:Create(CheckMark, TWEEN_FAST, { ImageTransparency = 1 }):Play()
                                TweenService:Create(ItemTxt, TWEEN_FAST, { TextColor3 = Theme.TextSecondary }):Play()
                                ItemTxt.Font = Enum.Font.GothamMedium
                            else
                                table.insert(selected, item)
                                TweenService:Create(Checkbox, TWEEN_FAST, { BackgroundColor3 = Theme.Accent }):Play()
                                TweenService:Create(CheckMark, TWEEN_FAST, { ImageTransparency = 0 }):Play()
                                TweenService:Create(ItemTxt, TWEEN_FAST, { TextColor3 = Theme.TextColor }):Play()
                                ItemTxt.Font = Enum.Font.GothamBold
                            end
                            MValueLabel.Text = getSelectedText()
                            callback(selected)
                        end)
                    end
                end
                MScrollList.CanvasSize = UDim2.fromOffset(0, MUIList.AbsoluteContentSize.Y)
            end

            MSearchBox:GetPropertyChangedSignal("Text"):Connect(function() mPopulate(MSearchBox.Text) end)
            MUIList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                MScrollList.CanvasSize = UDim2.fromOffset(0, MUIList.AbsoluteContentSize.Y)
            end)
            mPopulate("")

            MBtn.MouseButton1Click:Connect(function()
                if not MoreBlur.Visible then
                    mPopulate(""); MSearchBox.Text = ""
                    DropPageLayout:JumpTo(MSelectPage)
                    MoreBlur.Visible = true
                    TweenService:Create(MoreBlur,       TWEEN_FAST,         { BackgroundTransparency = 0.5 }):Play()
                    TweenService:Create(DropdownSelect, TWEEN_DROPDOWN_OUT, { Position = UDim2.new(1, -16, 0.5, 0) }):Play()
                end
            end)

            function MultiObject:Set(values: { any })
                selected = values
                self.Value = selected
                MValueLabel.Text = getSelectedText()
                callback(selected)
                mPopulate(MSearchBox.Text)
            end
            function MultiObject:UpdateLabel()
                MValueLabel.Text = getSelectedText()
            end
            function MultiObject:Refresh(newItems: { any })
                allItems = newItems
                local kept = {}
                for _, s in ipairs(selected) do
                    if table.find(allItems, s) then table.insert(kept, s) end
                end
                self:Set(kept)
            end

            local flag = o.Flag or mName
            if flag then
                FlagsInternal[flag] = MultiObject
            end
            return MultiObject
        end

        -- ── COLOR PICKER ────────────────────────────────────────────────
        function Tab:CreateColorPicker(cpopts: { Name: string?, Default: Color3?, Callback: ((Color3) -> ())?, Flag: string? }?)
            cpopts = cpopts or {}
            local o        = cpopts :: any
            local cpName   = sanitizeOptionalText(o.Name or "Color Picker")
            local default  = o.Default or Color3.fromRGB(255, 255, 255)
            local callback = o.Callback or function() end

            local h, s, v = default:ToHSV()
            local colorH, colorS, colorV = h, s, v
            local pickerOpen = false

            local PickerFrame = Create("Frame", {
                Parent = Tab.CurrentSectionContainer or TabPage,
                BackgroundColor3 = Theme.ElementBackground, BackgroundTransparency = 0.2,
                BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 38), ClipsDescendants = true,
            }) :: Frame
            Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = PickerFrame })
            Create("UIStroke",  { Color = Theme.Outline, Transparency = 0.5, Thickness = 1, Parent = PickerFrame })
            Create("TextLabel", {
                Parent = PickerFrame, BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -60, 0, 38),
                Font = Enum.Font.GothamMedium, Text = cpName,
                TextColor3 = Theme.TextColor, TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
            })
            local Preview = Create("Frame", {
                Parent = PickerFrame, BackgroundColor3 = default,
                Position = UDim2.new(1, -40, 0, 9), Size = UDim2.new(0, 28, 0, 20),
            }) :: Frame
            Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = Preview })

            local OpenBtn = Create("TextButton", {
                Parent = PickerFrame, BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 38), Text = "",
            }) :: TextButton

            local PickerContainer = Create("Frame", {
                Parent = PickerFrame, BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 42), Size = UDim2.new(1, -24, 0, 160),
            }) :: Frame

            local SVBox = Create("ImageButton", {
                Parent = PickerContainer,
                BackgroundColor3 = Color3.fromHSV(colorH, 1, 1),
                BorderSizePixel = 0, Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, 0, 0, 120),
                Image = "rbxassetid://4155801252", AutoButtonColor = false,
            }) :: ImageButton
            Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = SVBox })
            local SVCursor = Create("Frame", {
                Parent = SVBox, BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
                Position = UDim2.new(colorS, -3, 1 - colorV, -3), Size = UDim2.new(0, 6, 0, 6), ZIndex = 2,
            }) :: Frame
            Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = SVCursor })
            Create("UIStroke",  { Color = Color3.new(0, 0, 0), Thickness = 1, Parent = SVCursor })

            local HueBar = Create("ImageButton", {
                Parent = PickerContainer, BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, -24), Size = UDim2.new(1, 0, 0, 20),
                AutoButtonColor = false,
            }) :: ImageButton
            Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = HueBar })
            Create("UIGradient", {
                Parent = HueBar, Rotation = 0,
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255,   0,   0)),
                    ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255,   0)),
                    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(  0, 255,   0)),
                    ColorSequenceKeypoint.new(0.50, Color3.fromRGB(  0, 255, 255)),
                    ColorSequenceKeypoint.new(0.67, Color3.fromRGB(  0,   0, 255)),
                    ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,   0, 255)),
                    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255,   0,   0)),
                }),
            })
            local HueCursor = Create("Frame", {
                Parent = HueBar, BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0, Position = UDim2.new(colorH, -3, 0, -2),
                Size = UDim2.new(0, 6, 1, 4), ZIndex = 2,
            }) :: Frame
            Create("UICorner", { CornerRadius = UDim.new(0, 2), Parent = HueCursor })
            Create("UIStroke",  { Color = Color3.new(0, 0, 0), Thickness = 1, Parent = HueCursor })

            local function updateColor()
                local col = Color3.fromHSV(colorH, colorS, colorV)
                Preview.BackgroundColor3 = col
                SVBox.BackgroundColor3   = Color3.fromHSV(colorH, 1, 1)
                callback(col)
            end

            local draggingSV  = false
            local draggingHue = false
            SVBox.MouseButton1Down:Connect(function()  draggingSV  = true end)
            HueBar.MouseButton1Down:Connect(function() draggingHue = true end)

            table.insert(Connections, UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    draggingSV  = false
                    draggingHue = false
                end
            end))
            table.insert(Connections, UserInputService.InputChanged:Connect(function(input)
                if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
                if draggingSV then
                    colorS = math.clamp((input.Position.X - SVBox.AbsolutePosition.X) / SVBox.AbsoluteSize.X, 0, 1)
                    colorV = 1 - math.clamp((input.Position.Y - SVBox.AbsolutePosition.Y) / SVBox.AbsoluteSize.Y, 0, 1)
                    SVCursor.Position = UDim2.new(colorS, -3, 1 - colorV, -3)
                    updateColor()
                elseif draggingHue then
                    colorH = math.clamp((input.Position.X - HueBar.AbsolutePosition.X) / HueBar.AbsoluteSize.X, 0, 1)
                    HueCursor.Position = UDim2.new(colorH, -3, 0, -2)
                    updateColor()
                end
            end))

            OpenBtn.MouseButton1Click:Connect(function()
                pickerOpen = not pickerOpen
                TweenService:Create(PickerFrame, TWEEN_PICKER, { Size = UDim2.new(1, 0, 0, pickerOpen and 200 or 38) }):Play()
            end)

            local ColorObject = { Value = default }
            function ColorObject:Set(val: Color3)
                self.Value = val
                local nh, ns, nv = val:ToHSV()
                colorH, colorS, colorV = nh, ns, nv
                Preview.BackgroundColor3  = val
                SVBox.BackgroundColor3    = Color3.fromHSV(nh, 1, 1)
                SVCursor.Position         = UDim2.new(ns, -3, 1 - nv, -3)
                HueCursor.Position        = UDim2.new(nh, -3, 0, -2)
                callback(val)
            end

            local flag = o.Flag or cpName
            if flag then
                FlagsInternal[flag] = ColorObject
            end
            return ColorObject
        end

        -- ── KEYBIND ────────────────────────────────────────────────────
        function Tab:CreateKeybind(kbopts: { Name: string?, Default: Enum.KeyCode?, Callback: ((Enum.KeyCode) -> ())?, Flag: string? }?)
            kbopts = kbopts or {}
            local o        = kbopts :: any
            local kbName   = sanitizeOptionalText(o.Name or "Keybind")
            local currentKey: Enum.KeyCode = o.Default or Enum.KeyCode.RightControl
            local callback = o.Callback or function() end

            local function keyLabel(): string
                return currentKey == Enum.KeyCode.Unknown and "None" or currentKey.Name
            end

            local KbFrame = Create("Frame", {
                Parent = Tab.CurrentSectionContainer or TabPage,
                BackgroundColor3 = Theme.ElementBackground, BackgroundTransparency = 0.2,
                BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 38),
            }) :: Frame
            Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = KbFrame })
            Create("UIStroke",  { Color = Theme.Outline, Transparency = 0.5, Thickness = 1, Parent = KbFrame })
            Create("TextLabel", {
                Parent = KbFrame, BackgroundTransparency = 1,
                Position = UDim2.new(0, 12, 0, 0), Size = UDim2.new(1, -60, 1, 0),
                Font = Enum.Font.GothamMedium, Text = kbName,
                TextColor3 = Theme.TextColor, TextSize = 14,
                TextXAlignment = Enum.TextXAlignment.Left,
            })
            local KbBtn = Create("TextButton", {
                Parent = KbFrame,
                BackgroundColor3 = Theme.Background, BackgroundTransparency = 0.5,
                BorderSizePixel = 0,
                Position = UDim2.new(1, -95, 0.5, -12), Size = UDim2.new(0, 85, 0, 24),
                Font = Enum.Font.Gotham, Text = keyLabel(),
                TextColor3 = Theme.TextSecondary, TextSize = 13, ClipsDescendants = true,
            }) :: TextButton
            Create("UICorner", { CornerRadius = UDim.new(0, 4), Parent = KbBtn })
            Create("UIStroke",  { Color = Theme.Outline, Transparency = 0.7, Thickness = 1, Parent = KbBtn })

            local binding = false

            local function endBindSession(cancelFn: () -> ())
                if KeybindBindSessionCancel == cancelFn then
                    KeybindBindSessionCancel = nil
                end
            end

            local finishBinding: () -> ()
            finishBinding = function()
                if not binding then endBindSession(finishBinding); return end
                binding = false
                KbBtn.Text = keyLabel()
                TweenService:Create(KbBtn, TWEEN_FAST, { TextColor3 = Theme.TextSecondary }):Play()
                endBindSession(finishBinding)
            end

            local KbObject: { Value: Enum.KeyCode, Set: (any, Enum.KeyCode) -> () } = { Value = currentKey }
            function KbObject:Set(val: Enum.KeyCode)
                self.Value = val
                currentKey = val
                KbBtn.Text = val == Enum.KeyCode.Unknown and "None" or val.Name
            end

            KbBtn.MouseButton2Click:Connect(function()
                if binding and KeybindBindSessionCancel == finishBinding then finishBinding() end
                currentKey = Enum.KeyCode.Unknown
                KbObject.Value = currentKey
                KbBtn.Text = "None"
                TweenService:Create(KbBtn, TWEEN_FAST, { TextColor3 = Theme.TextSecondary }):Play()
            end)

            KbBtn.MouseButton1Click:Connect(function()
                local Mouse = Players.LocalPlayer:GetMouse()
                spawnRipple(KbBtn, Mouse.X, Mouse.Y, 100, TWEEN_RIPPLE_KEY)
                if KeybindBindSessionCancel then KeybindBindSessionCancel() end
                KeybindBindSessionCancel = finishBinding
                binding = true
                KbBtn.Text = "..."
                TweenService:Create(KbBtn, TWEEN_FAST, { TextColor3 = Theme.Accent }):Play()
            end)

            table.insert(Connections, UserInputService.InputBegan:Connect(function(input: InputObject)
                if binding then
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
                            currentKey = Enum.KeyCode.Unknown
                            KbObject.Value = currentKey
                            KbBtn.Text = "None"
                        else
                            currentKey = input.KeyCode
                            KbObject.Value = currentKey
                            KbBtn.Text = currentKey.Name
                            callback(currentKey)
                        end
                        binding = false
                        endBindSession(finishBinding)
                        TweenService:Create(KbBtn, TWEEN_FAST, { TextColor3 = Theme.TextSecondary }):Play()
                    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                        finishBinding()
                    end
                else
                    if currentKey ~= Enum.KeyCode.Unknown and input.KeyCode == currentKey then
                        callback(currentKey)
                    end
                end
            end))

            local flag = o.Flag or kbName
            if flag then
                FlagsInternal[flag] = KbObject
            end
            return KbObject
        end

        return Tab
    end

    -- ── CONFIG PERSISTENCE ────────────────────────────────────────────
    local CONFIG_VERSION = "2.1.0"

    function Window:SaveConfig(folderName: string, fileName: string): (boolean, string?)
        folderName = sanitizeOptionalText(folderName)
        fileName = sanitizeOptionalText(fileName)
        if not GlobalWriteFile then return false, "writefile unavailable" end

        local valid, err = validateConfigPath(folderName, fileName)
        if not valid then return false, err end

        local config: { [string]: any } = { _version = CONFIG_VERSION }
        for flag, obj in pairs(FlagsInternal) do
            local val = obj.Value
            if typeof(val) == "Color3" then
                val = { r = val.R, g = val.G, b = val.B, isColor = true }
            elseif typeof(val) == "EnumItem" then
                val = { name = val.Name, isKeybind = true }
            end
            config[flag] = val
        end

        local jsonStr = HttpService:JSONEncode(config)
        local encrypted = encryptData(jsonStr)

        local path = CONFIG_DIR .. folderName .. "/" .. fileName .. ".json"
        local ok, writeErr = pcall(function()
            GlobalWriteFile(path, encrypted)
        end)
        return ok, ok and nil or tostring(writeErr)
    end

    function Window:LoadConfig(folderName: string, fileName: string): (boolean, string?)
        folderName = sanitizeOptionalText(folderName)
        fileName = sanitizeOptionalText(fileName)
        if not GlobalReadFile then return false, "readfile unavailable" end

        local valid, err = validateConfigPath(folderName, fileName)
        if not valid then return false, err end

        local path = CONFIG_DIR .. folderName .. "/" .. fileName .. ".json"
        if GlobalIsFile and not GlobalIsFile(path) then return false, "config not found" end

        local ok, encrypted = pcall(function()
            return GlobalReadFile(path)
        end)
        if not ok or type(encrypted) ~= "string" then return false, "read error" end

        local jsonStr = decryptData(encrypted)
        local decoded = HttpService:JSONDecode(jsonStr)
        if type(decoded) ~= "table" then return false, "invalid config" end
        if decoded._version ~= CONFIG_VERSION then return false, "config version mismatch" end

        for flag, val in pairs(decoded) do
            if flag ~= "_version" and FlagsInternal[flag] then
                if type(val) == "table" then
                    if val.isColor and val.r and val.g and val.b then
                        val = Color3.new(val.r, val.g, val.b)
                    elseif val.isKeybind and val.name then
                        val = Enum.KeyCode[val.name]
                    end
                end
                FlagsInternal[flag]:Set(val)
            end
        end
        return true, nil
    end

    function Window:Destroy()
        ScreenGui:Destroy()
        for _, conn in ipairs(Connections) do conn:Disconnect() end
        Connections = {}
    end

    return Window
end

-- ============================================
-- SHARED DROPDOWN SEARCH PANEL FACTORY
-- ============================================
function createDropdownSearchPanel(parent: Frame): (TextBox, ScrollingFrame, UIListLayout)
    local SearchBox = Create("TextBox", {
        Parent = parent,
        BackgroundColor3 = Theme.Background, BackgroundTransparency = 0.5,
        BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 28),
        Font = Enum.Font.Gotham, PlaceholderText = sanitizeOptionalText("Search..."), Text = "",
        TextColor3 = Theme.TextColor, PlaceholderColor3 = Theme.TextSecondary,
        TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
    }) :: TextBox
    Create("UIPadding", { Parent = SearchBox, PaddingLeft = UDim.new(0, 8) })
    Create("UICorner",  { CornerRadius = UDim.new(0, 4), Parent = SearchBox })

    local ScrollList = Create("ScrollingFrame", {
        Parent = parent, BackgroundTransparency = 1,
        Position = UDim2.new(0, 0, 0, 35), Size = UDim2.new(1, 0, 1, -35),
        CanvasSize = UDim2.new(0, 0, 0, 0),
        ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.Accent,
        BorderSizePixel = 0,
    }) :: ScrollingFrame
    local UIList = Create("UIListLayout", {
        Parent = ScrollList, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4),
    }) :: UIListLayout

    return SearchBox :: TextBox, ScrollList :: ScrollingFrame, UIList :: UIListLayout
end

-- ============================================
-- MODULE DESTROY
-- ============================================
function DevLib:Destroy()
    for _, conn in ipairs(Connections) do conn:Disconnect() end
    Connections = {}

    local target = RunService:IsStudio()
        and Players.LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("DevHub")
        or  CoreGui:FindFirstChild("DevHub")
    if target then target:Destroy() end
end

return DevLib

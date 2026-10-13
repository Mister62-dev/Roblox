-- Universal Aimbot + ESP | First / Third Person Split + Drift Fix + Safe Aim Ref

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local lp = Players.LocalPlayer

local GUI_NAME = "UniversalAimbot_GUI"
local CONFIG_FILE = "universal_aimbot_config.json"
local STEP_NAME = "UniversalAimbotStep"

local function getEnv()
    if getgenv then
        local ok, env = pcall(getgenv)
        if ok and env then return env end
    end
    return _G
end

local env = getEnv()

-- Clean previous execution connections, bindings, and drawings.
pcall(function()
    local e = getEnv()

    if e._AIM_CONNS then
        for _, c in ipairs(e._AIM_CONNS) do
            pcall(function() c:Disconnect() end)
        end
    end
    e._AIM_CONNS = {}

    pcall(function()
        RunService:UnBindFromRenderStep(STEP_NAME)
    end)

    if e._AIM_DRAWING then
        pcall(function() e._AIM_DRAWING:Remove() end)
    end
    e._AIM_DRAWING = nil

    if e._AIM_ESP_OBJECTS then
        for _, entry in pairs(e._AIM_ESP_OBJECTS) do
            for _, prop in ipairs({"Box", "Name", "HealthBG", "Health"}) do
                local obj = entry[prop]
                if obj then
                    pcall(function() obj:Remove() end)
                end
            end
        end
    end
    e._AIM_ESP_OBJECTS = {}
end)

local function trackConn(conn)
    pcall(function()
        local e = getEnv()
        e._AIM_CONNS = e._AIM_CONNS or {}
        table.insert(e._AIM_CONNS, conn)
    end)
    return conn
end

local function clampNumber(v, minV, maxV)
    if v < minV then return minV end
    if v > maxV then return maxV end
    return v
end

local function roundStep(v, step)
    return math.floor((v / step) + 0.5) * step
end

local function findIndex(list, value)
    for i, v in ipairs(list) do
        if v == value then
            return i
        end
    end
    return nil
end

-- Config
local function defaultConfig()
    return {
        Enabled = true,
        FirstPersonAimbot = true,
        ThirdPersonAimbot = true,
        ForceMode = "Auto",
        ShowFOV = true,
        AimKey = "RightClick",
        TargetPart = "Head",
        FOV = 120,
        Smoothness = 0.25,

        DeadCheck = true,
        TeamCheck = true,
        WallCheck = true,
        TargetNPCs = false,
        MaxDistance = 1000,

        ClickAim = false,
        MouseSensitivity = 1,
        AimReference = "Crosshair",

        ESPEnabled = false,
        ESPBoxes = true,
        ESPNames = true,
        ESPHealth = true,
        ESPDistance = false
    }
end

local Config = defaultConfig()

local function sanitizeConfig()
    Config.FOV = clampNumber(Config.FOV, 10, 500)
    Config.Smoothness = clampNumber(Config.Smoothness, 0, 0.95)
    Config.MaxDistance = clampNumber(Config.MaxDistance, 50, 2000)
    Config.MouseSensitivity = clampNumber(Config.MouseSensitivity, 0.05, 2)

    local validAimKeys = {
        RightClick = true,
        LeftClick = true,
        Q = true,
        E = true,
        C = true,
        X = true
    }
    if not validAimKeys[Config.AimKey] then
        Config.AimKey = "RightClick"
    end

    local validParts = {
        Head = true,
        HumanoidRootPart = true,
        UpperTorso = true,
        Torso = true
    }
    if not validParts[Config.TargetPart] then
        Config.TargetPart = "Head"
    end

    local validRefs = {
        Crosshair = true,
        Mouse = true
    }
    if not validRefs[Config.AimReference] then
        Config.AimReference = "Crosshair"
    end

    local validModes = {
        Auto = true,
        First = true,
        Third = true
    }
    if not validModes[Config.ForceMode] then
        Config.ForceMode = "Auto"
    end
end

local function applyConfigData(data)
    for k, v in pairs(data) do
        if Config[k] ~= nil then
            if type(Config[k]) == "number" then
                local num = tonumber(v)
                if num then
                    Config[k] = num
                end
            elseif type(Config[k]) == "boolean" then
                Config[k] = (v == true or v == "true")
            elseif type(Config[k]) == "string" then
                if type(v) == "string" then
                    Config[k] = v
                end
            else
                Config[k] = v
            end
        end
    end
end

local function saveConfig()
    local ok, json = pcall(function()
        return HttpService:JSONEncode(Config)
    end)

    if not ok or type(json) ~= "string" then
        return false, "encode failed"
    end

    if writefile then
        local okWrite = pcall(function()
            writefile(CONFIG_FILE, json)
        end)
        if okWrite then
            return true, "file"
        end
    end

    pcall(function()
        env._AIM_CONFIG = json
    end)

    return true, "memory"
end

local function loadConfig()
    local json

    if isfile and readfile then
        local okExists, exists = pcall(function()
            return isfile(CONFIG_FILE)
        end)

        if okExists and exists then
            local okRead, data = pcall(function()
                return readfile(CONFIG_FILE)
            end)

            if okRead and type(data) == "string" then
                json = data
            end
        end
    end

    if not json then
        json = env._AIM_CONFIG
    end

    if not json then
        return false
    end

    local ok, data = pcall(function()
        return HttpService:JSONDecode(json)
    end)

    if ok and type(data) == "table" then
        applyConfigData(data)
        return true
    end

    return false
end

loadConfig()
sanitizeConfig()

-- FOV circle
local fovCircle
pcall(function()
    if Drawing then
        fovCircle = Drawing.new("Circle")
        fovCircle.Color = Color3.fromRGB(255, 255, 255)
        fovCircle.Thickness = 1
        fovCircle.NumSides = 64
        fovCircle.Filled = false
        fovCircle.Visible = false
        env._AIM_DRAWING = fovCircle
    end
end)

-- ESP storage
local espObjects = {}
pcall(function()
    env._AIM_ESP_OBJECTS = espObjects
end)

-- Theme
local Theme = {
    Background = Color3.fromRGB(11, 12, 16),
    Background2 = Color3.fromRGB(18, 19, 26),
    Card = Color3.fromRGB(23, 24, 33),
    CardAlt = Color3.fromRGB(31, 32, 45),
    Stroke = Color3.fromRGB(54, 56, 76),
    Text = Color3.fromRGB(235, 237, 245),
    SubText = Color3.fromRGB(156, 161, 180),
    Accent = Color3.fromRGB(116, 94, 255),
    Accent2 = Color3.fromRGB(72, 194, 255),
    On = Color3.fromRGB(58, 214, 146),
    Off = Color3.fromRGB(255, 86, 101)
}

local function tween(obj, props, time)
    pcall(function()
        TweenService:Create(
            obj,
            TweenInfo.new(time or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            props
        ):Play()
    end)
end

local function addCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = parent
    return corner
end

local function addStroke(parent, color, transparency, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Theme.Stroke
    stroke.Thickness = thickness or 1
    stroke.Transparency = transparency or 0
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

local function addGradient(parent, c1, c2, rotation)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new(c1, c2)
    gradient.Rotation = rotation or 90
    gradient.Parent = parent
    return gradient
end

-- GUI parent
local function getParent()
    if gethui then
        local ok, h = pcall(gethui)
        if ok and h then return h end
    end

    local ok, core = pcall(function() return game:GetService("CoreGui") end)
    if ok and core then
        local test = Instance.new("ScreenGui")
        local okParent = pcall(function() test.Parent = core end)
        test:Destroy()
        if okParent then return core end
    end

    return lp:WaitForChild("PlayerGui")
end

-- UI state
local uiControls = {
    toggles = {},
    dropdowns = {},
    sliders = {}
}

local screenGui
local main
local configStatus
local modeStatus

local function setToggleVisual(key)
    local c = uiControls.toggles[key]
    if not c then return end

    local on = Config[key]

    tween(c.Pill, {
        BackgroundColor3 = on and Theme.On or Theme.Off
    })

    tween(c.Knob, {
        Position = on and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
    })

    c.State.Text = on and "ON" or "OFF"
    c.State.TextColor3 = on and Theme.On or Theme.SubText
end

local function setDropdownVisual(key)
    local c = uiControls.dropdowns[key]
    if not c then return end
    c.Value.Text = tostring(Config[key])
end

local function formatSliderValue(key)
    if key == "Smoothness" or key == "MouseSensitivity" then
        return string.format("%.2f", Config[key])
    end
    return tostring(math.floor(Config[key]))
end

local function setSliderVisual(key)
    local c = uiControls.sliders[key]
    if not c then return end
    c.Value.Text = formatSliderValue(key)
end

local function refreshUI()
    for key in pairs(uiControls.toggles) do
        setToggleVisual(key)
    end

    for key in pairs(uiControls.dropdowns) do
        setDropdownVisual(key)
    end

    for key in pairs(uiControls.sliders) do
        setSliderVisual(key)
    end
end

-- Build GUI
local parentGui = getParent()

pcall(function()
    local old = parentGui:FindFirstChild(GUI_NAME)
    if old then old:Destroy() end
end)

screenGui = Instance.new("ScreenGui")
screenGui.Name = GUI_NAME
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 999
screenGui.Parent = parentGui

main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, 430, 0, 330)
main.Position = UDim2.new(0.5, -215, 0.5, -165)
main.BackgroundColor3 = Theme.Background
main.BackgroundTransparency = 0.06
main.BorderSizePixel = 0
main.Active = true
main.Parent = screenGui

addCorner(main, 12)
addStroke(main, Theme.Stroke, 0.22)
addGradient(main, Theme.Background2, Theme.Background, 90)

local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, -20, 0, 44)
titleBar.Position = UDim2.new(0, 10, 0, 6)
titleBar.BackgroundTransparency = 1
titleBar.Active = true
titleBar.Parent = main

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, -110, 1, 0)
title.Position = UDim2.new(0, 2, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Universal Aimbot + ESP"
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextColor3 = Theme.Text
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

local hint = Instance.new("TextLabel")
hint.Name = "Hint"
hint.Size = UDim2.new(0, 72, 0, 24)
hint.Position = UDim2.new(1, -74, 0.5, -12)
hint.BackgroundColor3 = Theme.Card
hint.BackgroundTransparency = 0.12
hint.BorderSizePixel = 0
hint.Text = "INSERT"
hint.Font = Enum.Font.GothamMedium
hint.TextSize = 12
hint.TextColor3 = Theme.SubText
hint.Parent = titleBar

addCorner(hint, 6)
addStroke(hint, Theme.Stroke, 0.2)

local accent = Instance.new("Frame")
accent.Name = "Accent"
accent.Size = UDim2.new(1, -20, 0, 2)
accent.Position = UDim2.new(0, 10, 0, 52)
accent.BorderSizePixel = 0
accent.BackgroundColor3 = Theme.Accent
accent.BackgroundTransparency = 0.08
accent.Parent = main

addCorner(accent, 2)
addGradient(accent, Theme.Accent, Theme.Accent2, 0)

local tabBar = Instance.new("Frame")
tabBar.Name = "TabBar"
tabBar.Size = UDim2.new(1, -20, 0, 36)
tabBar.Position = UDim2.new(0, 10, 0, 60)
tabBar.BackgroundColor3 = Theme.Card
tabBar.BackgroundTransparency = 0.32
tabBar.BorderSizePixel = 0
tabBar.Parent = main

addCorner(tabBar, 10)
addStroke(tabBar, Theme.Stroke, 0.3)

local tabList = Instance.new("UIListLayout")
tabList.FillDirection = Enum.FillDirection.Horizontal
tabList.SortOrder = Enum.SortOrder.LayoutOrder
tabList.Padding = UDim.new(0, 6)
tabList.VerticalAlignment = Enum.VerticalAlignment.Center
tabList.Parent = tabBar

local tabPadding = Instance.new("UIPadding")
tabPadding.PaddingLeft = UDim.new(0, 5)
tabPadding.PaddingRight = UDim.new(0, 5)
tabPadding.Parent = tabBar

local content = Instance.new("Frame")
content.Name = "Content"
content.Size = UDim2.new(1, -20, 1, -112)
content.Position = UDim2.new(0, 10, 0, 102)
content.BackgroundTransparency = 1
content.Parent = main

local pages = {}
local tabButtons = {}

local function makePage(name)
    local page = Instance.new("ScrollingFrame")
    page.Name = name
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 5
    page.ScrollBarImageColor3 = Theme.Accent
    page.ScrollBarImageTransparency = 0.25
    page.Visible = false
    page.Parent = content

    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 8)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = page

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 4)
    padding.PaddingLeft = UDim.new(0, 2)
    padding.PaddingRight = UDim.new(0, 4)
    padding.PaddingBottom = UDim.new(0, 6)
    padding.Parent = page

    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 12)
    end)

    pages[name] = page
    return page
end

local function setTab(name)
    for tabName, page in pairs(pages) do
        page.Visible = (tabName == name)
    end

    for tabName, btn in pairs(tabButtons) do
        local active = (tabName == name)

        tween(btn, {
            BackgroundColor3 = active and Theme.Accent or Theme.CardAlt,
            BackgroundTransparency = active and 0.06 or 0.22
        })

        btn.TextColor3 = active and Color3.fromRGB(255, 255, 255) or Theme.SubText

        local strokeObj = btn:FindFirstChildOfClass("UIStroke")
        if strokeObj then
            tween(strokeObj, {
                Color = active and Theme.Accent2 or Theme.Stroke
            })
        end
    end
end

local function makeTab(name, order)
    local btn = Instance.new("TextButton")
    btn.LayoutOrder = order
    btn.Size = UDim2.new(0, 92, 1, 0)
    btn.BackgroundColor3 = Theme.CardAlt
    btn.BackgroundTransparency = 0.22
    btn.BorderSizePixel = 0
    btn.Text = name
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 13
    btn.TextColor3 = Theme.SubText
    btn.Parent = tabBar

    addCorner(btn, 8)
    addStroke(btn, Theme.Stroke, 0.35)

    btn.MouseButton1Click:Connect(function()
        setTab(name)
    end)

    tabButtons[name] = btn
end

local CONTROL_HEIGHT = 36

local function makeToggle(parent, order, label, key)
    local card = Instance.new("TextButton")
    card.LayoutOrder = order
    card.Size = UDim2.new(1, 0, 0, CONTROL_HEIGHT)
    card.BackgroundColor3 = Theme.Card
    card.BackgroundTransparency = 0.06
    card.BorderSizePixel = 0
    card.Text = ""
    card.AutoButtonColor = false
    card.Parent = parent

    addCorner(card, 8)
    addStroke(card, Theme.Stroke, 0.3)

    local nameLabel = Instance.new("TextLabel")
    nameLabel.BackgroundTransparency = 1
    nameLabel.Position = UDim2.new(0, 12, 0, 0)
    nameLabel.Size = UDim2.new(1, -92, 1, 0)
    nameLabel.Text = label
    nameLabel.Font = Enum.Font.GothamMedium
    nameLabel.TextSize = 14
    nameLabel.TextColor3 = Theme.Text
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = card

    local state = Instance.new("TextLabel")
    state.BackgroundTransparency = 1
    state.Position = UDim2.new(1, -78, 0, 0)
    state.Size = UDim2.new(0, 38, 1, 0)
    state.Text = "OFF"
    state.Font = Enum.Font.GothamMedium
    state.TextSize = 12
    state.TextColor3 = Theme.SubText
    state.TextXAlignment = Enum.TextXAlignment.Right
    state.Parent = card

    local pill = Instance.new("Frame")
    pill.Position = UDim2.new(1, -34, 0.5, -10)
    pill.Size = UDim2.new(0, 26, 0, 20)
    pill.BackgroundColor3 = Theme.Off
    pill.BorderSizePixel = 0
    pill.Parent = card

    addCorner(pill, 999)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new(0, 2, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(245, 245, 250)
    knob.BorderSizePixel = 0
    knob.Parent = pill

    addCorner(knob, 999)

    card.MouseButton1Click:Connect(function()
        Config[key] = not Config[key]
        setToggleVisual(key)
    end)

    uiControls.toggles[key] = {
        Card = card,
        Pill = pill,
        Knob = knob,
        State = state
    }

    setToggleVisual(key)
end

local function makeDropdown(parent, order, label, key, options)
    local card = Instance.new("TextButton")
    card.LayoutOrder = order
    card.Size = UDim2.new(1, 0, 0, CONTROL_HEIGHT)
    card.BackgroundColor3 = Theme.Card
    card.BackgroundTransparency = 0.06
    card.BorderSizePixel = 0
    card.Text = ""
    card.AutoButtonColor = false
    card.Parent = parent

    addCorner(card, 8)
    addStroke(card, Theme.Stroke, 0.3)

    local nameLabel = Instance.new("TextLabel")
    nameLabel.BackgroundTransparency = 1
    nameLabel.Position = UDim2.new(0, 12, 0, 0)
    nameLabel.Size = UDim2.new(1, -175, 1, 0)
    nameLabel.Text = label
    nameLabel.Font = Enum.Font.GothamMedium
    nameLabel.TextSize = 14
    nameLabel.TextColor3 = Theme.Text
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = card

    local value = Instance.new("TextLabel")
    value.BackgroundTransparency = 1
    value.Position = UDim2.new(1, -165, 0, 0)
    value.Size = UDim2.new(0, 152, 1, 0)
    value.Text = tostring(Config[key])
    value.Font = Enum.Font.GothamMedium
    value.TextSize = 13
    value.TextColor3 = Theme.Accent2
    value.TextXAlignment = Enum.TextXAlignment.Right
    value.Parent = card

    card.MouseButton1Click:Connect(function()
        local idx = findIndex(options, Config[key]) or 0
        idx = (idx % #options) + 1
        Config[key] = options[idx]
        setDropdownVisual(key)
    end)

    uiControls.dropdowns[key] = {
        Card = card,
        Value = value
    }

    setDropdownVisual(key)
end

local function styleSmallButton(btn)
    btn.BackgroundColor3 = Theme.CardAlt
    btn.BackgroundTransparency = 0.08
    btn.BorderSizePixel = 0
    btn.TextColor3 = Theme.Text
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 15

    addCorner(btn, 6)
    addStroke(btn, Theme.Stroke, 0.28)
end

local function makeSlider(parent, order, label, key, min, max, step)
    local card = Instance.new("Frame")
    card.LayoutOrder = order
    card.Size = UDim2.new(1, 0, 0, CONTROL_HEIGHT)
    card.BackgroundColor3 = Theme.Card
    card.BackgroundTransparency = 0.06
    card.BorderSizePixel = 0
    card.Parent = parent

    addCorner(card, 8)
    addStroke(card, Theme.Stroke, 0.3)

    local nameLabel = Instance.new("TextLabel")
    nameLabel.BackgroundTransparency = 1
    nameLabel.Position = UDim2.new(0, 12, 0, 0)
    nameLabel.Size = UDim2.new(1, -145, 1, 0)
    nameLabel.Text = label
    nameLabel.Font = Enum.Font.GothamMedium
    nameLabel.TextSize = 14
    nameLabel.TextColor3 = Theme.Text
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = card

    local minus = Instance.new("TextButton")
    minus.Size = UDim2.new(0, 26, 0, 26)
    minus.Position = UDim2.new(1, -124, 0.5, -13)
    minus.Text = "-"
    minus.Parent = card
    styleSmallButton(minus)

    local value = Instance.new("TextLabel")
    value.BackgroundTransparency = 1
    value.Position = UDim2.new(1, -94, 0, 0)
    value.Size = UDim2.new(0, 54, 1, 0)
    value.Text = formatSliderValue(key)
    value.Font = Enum.Font.Gotham
    value.TextSize = 13
    value.TextColor3 = Theme.SubText
    value.TextXAlignment = Enum.TextXAlignment.Center
    value.Parent = card

    local plus = Instance.new("TextButton")
    plus.Size = UDim2.new(0, 26, 0, 26)
    plus.Position = UDim2.new(1, -34, 0.5, -13)
    plus.Text = "+"
    plus.Parent = card
    styleSmallButton(plus)

    minus.MouseButton1Click:Connect(function()
        Config[key] = clampNumber(roundStep(Config[key] - step, step), min, max)
        setSliderVisual(key)
    end)

    plus.MouseButton1Click:Connect(function()
        Config[key] = clampNumber(roundStep(Config[key] + step, step), min, max)
        setSliderVisual(key)
    end)

    uiControls.sliders[key] = {
        Value = value
    }

    setSliderVisual(key)
end

local function makeButton(parent, order, text, callback, accent)
    local btn = Instance.new("TextButton")
    btn.LayoutOrder = order
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 14
    btn.AutoButtonColor = false
    btn.Parent = parent

    if accent then
        btn.BackgroundColor3 = Theme.Accent
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        addGradient(btn, Theme.Accent, Theme.Accent2, 90)
        addCorner(btn, 8)
        addStroke(btn, Theme.Accent2, 0.18)
    else
        btn.BackgroundColor3 = Theme.CardAlt
        btn.BackgroundTransparency = 0.08
        btn.TextColor3 = Theme.Text
        addCorner(btn, 8)
        addStroke(btn, Theme.Stroke, 0.3)
    end

    btn.MouseButton1Click:Connect(callback)

    return btn
end

local pageAim = makePage("Aim")
local pageESP = makePage("ESP")
local pageTargeting = makePage("Targeting")
local pageConfig = makePage("Config")

makeTab("Aim", 1)
makeTab("ESP", 2)
makeTab("Targeting", 3)
makeTab("Config", 4)

makeToggle(pageAim, 1, "Aimbot", "Enabled")
makeToggle(pageAim, 2, "First Person Aim", "FirstPersonAimbot")
makeToggle(pageAim, 3, "Third Person Aim", "ThirdPersonAimbot")
makeToggle(pageAim, 4, "Show FOV", "ShowFOV")
makeToggle(pageAim, 5, "Click Aim", "ClickAim")
makeDropdown(pageAim, 6, "Force Mode", "ForceMode", {"Auto", "First", "Third"})
makeDropdown(pageAim, 7, "Aim Ref", "AimReference", {"Crosshair", "Mouse"})
makeDropdown(pageAim, 8, "Aim Key", "AimKey", {"RightClick", "LeftClick", "Q", "E", "C", "X"})
makeSlider(pageAim, 9, "FOV", "FOV", 10, 500, 5)
makeSlider(pageAim, 10, "Smooth", "Smoothness", 0, 0.95, 0.05)
makeSlider(pageAim, 11, "Mouse Sens", "MouseSensitivity", 0.05, 2, 0.05)

modeStatus = Instance.new("TextLabel")
modeStatus.LayoutOrder = 12
modeStatus.Size = UDim2.new(1, 0, 0, 26)
modeStatus.BackgroundTransparency = 1
modeStatus.Text = "Mode: -"
modeStatus.Font = Enum.Font.Gotham
modeStatus.TextSize = 13
modeStatus.TextColor3 = Theme.SubText
modeStatus.TextXAlignment = Enum.TextXAlignment.Center
modeStatus.Parent = pageAim

makeToggle(pageESP, 1, "ESP", "ESPEnabled")
makeToggle(pageESP, 2, "Boxes", "ESPBoxes")
makeToggle(pageESP, 3, "Names", "ESPNames")
makeToggle(pageESP, 4, "Health", "ESPHealth")
makeToggle(pageESP, 5, "Distance", "ESPDistance")

makeToggle(pageTargeting, 1, "Dead Check", "DeadCheck")
makeToggle(pageTargeting, 2, "Team Check", "TeamCheck")
makeToggle(pageTargeting, 3, "Wall Check", "WallCheck")
makeToggle(pageTargeting, 4, "Target NPCs", "TargetNPCs")
makeDropdown(pageTargeting, 5, "Part", "TargetPart", {"Head", "HumanoidRootPart", "UpperTorso", "Torso"})
makeSlider(pageTargeting, 6, "Max Dist", "MaxDistance", 50, 2000, 50)

makeButton(pageConfig, 1, "Save Config", function()
    local ok, where = saveConfig()
    if configStatus then
        configStatus.Text = ok and ("Saved to " .. where) or "Save failed"
    end
end, true)

makeButton(pageConfig, 2, "Load Config", function()
    local ok = loadConfig()
    sanitizeConfig()
    refreshUI()
    if configStatus then
        configStatus.Text = ok and "Loaded" or "Load failed"
    end
end, false)

makeButton(pageConfig, 3, "Reset Config", function()
    local fresh = defaultConfig()
    for k, v in pairs(fresh) do
        Config[k] = v
    end
    sanitizeConfig()
    refreshUI()
    if configStatus then
        configStatus.Text = "Reset"
    end
end, false)

configStatus = Instance.new("TextLabel")
configStatus.LayoutOrder = 4
configStatus.Size = UDim2.new(1, 0, 0, 30)
configStatus.BackgroundTransparency = 1
configStatus.Text = "Config: ready"
configStatus.Font = Enum.Font.Gotham
configStatus.TextSize = 13
configStatus.TextColor3 = Theme.SubText
configStatus.TextXAlignment = Enum.TextXAlignment.Center
configStatus.Parent = pageConfig

setTab("Aim")
refreshUI()

for _, page in pairs(pages) do
    local list = page:FindFirstChildOfClass("UIListLayout")
    if list then
        page.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 12)
    end
end

-- Drag
local dragging = false
local dragStart, startPos

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
    end
end)

trackConn(UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end))

trackConn(UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end))

-- Menu toggle
trackConn(UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.Insert then
        screenGui.Enabled = not screenGui.Enabled
    end
end))

-- NPC registry for optional non-player humanoid targets
local npcCharacters = {}

local function registerNPC(obj)
    if not obj or not obj.Parent then return end
    if not obj:IsA("Model") then return end

    local ok, player = pcall(function()
        return Players:GetPlayerFromCharacter(obj)
    end)
    if ok and player then return end

    if obj:FindFirstChildOfClass("Humanoid") then
        npcCharacters[obj] = true
    end
end

local function unregisterNPC(obj)
    if not obj then return end

    if obj:IsA("Model") then
        npcCharacters[obj] = nil
    end

    if obj:IsA("Humanoid") and obj.Parent and obj.Parent:IsA("Model") then
        npcCharacters[obj.Parent] = nil
    end
end

local function scanNPCs()
    npcCharacters = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        registerNPC(obj)
    end
end

trackConn(workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("Humanoid") and obj.Parent then
        registerNPC(obj.Parent)
    end
    registerNPC(obj)
end))

trackConn(workspace.DescendantRemoving:Connect(function(obj)
    unregisterNPC(obj)
end))

scanNPCs()

-- Aimbot helpers
local AimKeyMap = {
    RightClick = Enum.UserInputType.MouseButton2,
    LeftClick = Enum.UserInputType.MouseButton1,
    Q = Enum.KeyCode.Q,
    E = Enum.KeyCode.E,
    C = Enum.KeyCode.C,
    X = Enum.KeyCode.X
}

local function isMouseOverMenu()
    if not screenGui or not screenGui.Enabled then
        return false
    end

    local okMouse, mouse = pcall(function()
        return UserInputService:GetMouseLocation()
    end)
    if not okMouse or not mouse then
        return false
    end

    local okPos, pos = pcall(function()
        return main.AbsolutePosition
    end)
    local okSize, size = pcall(function()
        return main.AbsoluteSize
    end)

    if not okPos or not okSize then
        return false
    end

    return mouse.X >= pos.X
        and mouse.X <= pos.X + size.X
        and mouse.Y >= pos.Y
        and mouse.Y <= pos.Y + size.Y
end

local function isAimKeyDown()
    if isMouseOverMenu() then
        return false
    end

    if Config.ClickAim then
        local okClick, downClick = pcall(function()
            return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
        end)
        if okClick and downClick then
            return true
        end
    end

    local key = AimKeyMap[Config.AimKey] or Enum.UserInputType.MouseButton2

    if key.EnumType == Enum.UserInputType then
        local ok, down = pcall(function()
            return UserInputService:IsMouseButtonPressed(key)
        end)
        return ok and down
    end

    local ok, down = pcall(function()
        return UserInputService:IsKeyDown(key)
    end)
    return ok and down
end

-- R15 and R6 rigs are both covered by the fallback chain.
local function getCharacterPart(char)
    if not char then return nil end

    local names = {
        Config.TargetPart,
        "Head",
        "HumanoidRootPart",
        "UpperTorso",
        "Torso",
        "LowerTorso"
    }

    for _, n in ipairs(names) do
        local part = char:FindFirstChild(n)
        if part and part:IsA("BasePart") then
            return part
        end
    end

    return char:FindFirstChildWhichIsA("BasePart", true)
end

local function isAlive(char)
    if not char or not char.Parent then return false end

    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end

    local ok, state = pcall(function()
        return hum:GetState()
    end)

    if ok and state == Enum.HumanoidStateType.Dead then
        return false
    end

    return true
end

local function isLocalAlive()
    if not Config.DeadCheck then
        return true
    end
    return isAlive(lp.Character)
end

local function isEnemy(plr)
    if not Config.TeamCheck then return true end
    if plr.Team and lp.Team and plr.Team == lp.Team then return false end
    return true
end

-- A locked mouse is the strongest fps signal there is.
local function isMouseLocked()
    local ok, beh = pcall(function()
        return UserInputService.MouseBehavior
    end)

    if ok and (beh == Enum.MouseBehavior.LockCenter
        or beh == Enum.MouseBehavior.LockCurrentPosition) then
        return true
    end

    return false
end

-- Detect whether the player is currently in first person.
local function isFirstResponder()
    local cam = workspace.CurrentCamera
    if not cam then return false end

    if cam.CameraType == Enum.CameraType.FirstPerson then
        return true
    end

    local okMode, mode = pcall(function()
        return lp.CameraMode
    end)
    if okMode and mode == Enum.CameraMode.LockFirstPerson then
        return true
    end

    if isMouseLocked() then
        return true
    end

    local char = lp.Character
    if char then
        local head = char:FindFirstChild("Head")
            or char:FindFirstChild("HumanoidRootPart")

        if head then
            local ok, dist = pcall(function()
                return (cam.CFrame.Position - head.Position).Magnitude
            end)

            if ok and dist < 2 then
                return true
            end
        end
    end

    return false
end

-- Manual override wins; auto falls back to detection.
local function currentModeFirst()
    if Config.ForceMode == "First" then
        return true
    end

    if Config.ForceMode == "Third" then
        return false
    end

    return isFirstResponder()
end

local function worldToViewport(cam, pos)
    local ok, screenPos, visible = pcall(function()
        return cam:WorldToViewportPoint(pos)
    end)

    if ok then
        return screenPos, visible
    end

    return nil, false
end

local function isVisible(part, char)
    local cam = workspace.CurrentCamera
    if not cam then return false end

    local origin = cam.CFrame.Position
    local dir = part.Position - origin
    if dir.Magnitude < 0.01 then return true end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.RespectCanCollide = true

    -- Exclude the local character AND the camera so a scoped viewmodel
    -- parented to the camera can never block the visibility ray.
    local filter = {}
    if lp.Character then
        table.insert(filter, lp.Character)
    end
    table.insert(filter, cam)
    params.FilterDescendantsInstances = filter

    local ok, result = pcall(function()
        return workspace:Raycast(origin, dir, params)
    end)

    if not ok then return true end
    if not result then return true end

    if char and result.Instance:IsDescendantOf(char) then
        return true
    end

    return result.Instance == part
end

-- Mouse reference is only safe with a free cursor in third person.
-- In first person or with a locked mouse it always falls back to the
-- screen-center crosshair, so the aim delta can never go stale.
local function getAimReference()
    local cam = workspace.CurrentCamera

    local useMouse = (Config.AimReference == "Mouse") and not isFirstResponder()

    if useMouse then
        local okMouse, mouse = pcall(function()
            return UserInputService:GetMouseLocation()
        end)

        if okMouse and mouse then
            return mouse
        end
    end

    if cam then
        local ok, size = pcall(function()
            return cam.ViewportSize
        end)

        if ok and size and size.X > 0 and size.Y > 0 then
            return Vector2.new(size.X / 2, size.Y / 2)
        end
    end

    return Vector2.new(0, 0)
end

-- Hysteresis: keep the locked head until a clearly closer one appears,
-- so the aim stops switching targets and drifting mid-lock.
local lastTargetPart = nil

local function getClosestTarget()
    if not isLocalAlive() then
        lastTargetPart = nil
        return nil, nil
    end

    local cam = workspace.CurrentCamera
    if not cam then
        lastTargetPart = nil
        return nil, nil
    end

    local ref = getAimReference()
    local candidates = {}

    local function consider(char)
        if not char or not char.Parent then return end

        if Config.DeadCheck and not isAlive(char) then
            return
        end

        local part = getCharacterPart(char)
        if not part then return end

        local dist3D = (part.Position - cam.CFrame.Position).Magnitude
        if dist3D > Config.MaxDistance then return end

        local screenPos, onScreen = worldToViewport(cam, part.Position)
        if not screenPos or not onScreen then return end

        local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - ref).Magnitude
        if screenDist > Config.FOV then return end

        if Config.WallCheck and not isVisible(part, char) then return end

        table.insert(candidates, {
            Part = part,
            Screen = screenPos,
            Dist = screenDist
        })
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= lp and isEnemy(plr) then
            consider(plr.Character)
        end
    end

    if Config.TargetNPCs then
        for char in pairs(npcCharacters) do
            if char and char.Parent then
                local ok, player = pcall(function()
                    return Players:GetPlayerFromCharacter(char)
                end)

                if ok and not player then
                    consider(char)
                end
            else
                npcCharacters[char] = nil
            end
        end
    end

    if #candidates == 0 then
        lastTargetPart = nil
        return nil, nil
    end

    local best = candidates[1]
    for i = 2, #candidates do
        if candidates[i].Dist < best.Dist then
            best = candidates[i]
        end
    end

    local chosen = best

    if lastTargetPart and lastTargetPart.Parent then
        for _, c in ipairs(candidates) do
            if c.Part == lastTargetPart and c.Dist <= best.Dist * 1.3 then
                chosen = c
                break
            end
        end
    else
        lastTargetPart = nil
    end

    lastTargetPart = chosen.Part
    return chosen.Part, chosen.Screen
end

local function updateFOV()
    if not fovCircle then return end

    local show = Config.Enabled and Config.ShowFOV

    pcall(function()
        fovCircle.Visible = show
    end)

    if show then
        pcall(function()
            fovCircle.Radius = Config.FOV
            fovCircle.Position = getAimReference()
        end)
    end
end

-- ESP helpers
local function destroyESPEntry(entry)
    if not entry then return end

    for _, prop in ipairs({"Box", "Name", "HealthBG", "Health"}) do
        local obj = entry[prop]
        if obj then
            pcall(function() obj:Remove() end)
        end
    end
end

local function clearESP()
    for _, entry in pairs(espObjects) do
        destroyESPEntry(entry)
    end

    espObjects = {}
    pcall(function()
        env._AIM_ESP_OBJECTS = espObjects
    end)
end

local function createESPEntry()
    if not Drawing then return nil end

    local ok, entry = pcall(function()
        local e = {}

        e.Box = Drawing.new("Square")
        e.Box.Thickness = 1
        e.Box.Color = Color3.fromRGB(255, 80, 80)
        e.Box.Filled = false
        e.Box.Visible = false

        e.Name = Drawing.new("Text")
        e.Name.Size = 16
        e.Name.Center = true
        e.Name.Outline = true
        e.Name.Color = Color3.fromRGB(255, 255, 255)
        e.Name.Visible = false

        e.HealthBG = Drawing.new("Line")
        e.HealthBG.Thickness = 3
        e.HealthBG.Color = Color3.fromRGB(0, 0, 0)
        e.HealthBG.Visible = false

        e.Health = Drawing.new("Line")
        e.Health.Thickness = 2
        e.Health.Color = Color3.fromRGB(0, 255, 0)
        e.Health.Visible = false

        return e
    end)

    if ok and entry then
        return entry
    end

    return nil
end

local function updateESP()
    if not Config.ESPEnabled or not Drawing then
        if next(espObjects) then
            clearESP()
        end
        return
    end

    local cam = workspace.CurrentCamera
    if not cam then return end

    local active = {}

    local function drawCharacter(char, displayName, color)
        if not char or not char.Parent then return end

        if Config.DeadCheck and not isAlive(char) then
            return
        end

        local root = char:FindFirstChild("HumanoidRootPart")
            or char:FindFirstChildWhichIsA("BasePart", true)
        if not root then return end

        local head = char:FindFirstChild("Head")
        local topWorld = head and (head.Position + Vector3.new(0, 1, 0))
            or (root.Position + Vector3.new(0, 3, 0))
        local bottomWorld = root.Position - Vector3.new(0, 3, 0)

        local top, topVisible = worldToViewport(cam, topWorld)
        local bottom, bottomVisible = worldToViewport(cam, bottomWorld)

        local entry = espObjects[char]

        if not top or not bottom or (not topVisible and not bottomVisible) then
            if entry then
                pcall(function() entry.Box.Visible = false end)
                pcall(function() entry.Name.Visible = false end)
                pcall(function() entry.HealthBG.Visible = false end)
                pcall(function() entry.Health.Visible = false end)
            end
            return
        end

        if not entry then
            entry = createESPEntry()
            if entry then
                espObjects[char] = entry
            end
        end

        if not entry then return end

        active[char] = true

        local minY = math.min(top.Y, bottom.Y)
        local height = math.abs(bottom.Y - top.Y)
        if height < 4 then height = 4 end

        local width = height * 0.6
        local centerX = (top.X + bottom.X) / 2
        local left = centerX - (width / 2)

        if Config.ESPBoxes then
            pcall(function()
                entry.Box.Visible = true
                entry.Box.Position = Vector2.new(left, minY)
                entry.Box.Size = Vector2.new(width, height)
                entry.Box.Color = color
            end)
        else
            pcall(function() entry.Box.Visible = false end)
        end

        if Config.ESPNames or Config.ESPDistance then
            local dist = math.floor((root.Position - cam.CFrame.Position).Magnitude)
            local text = displayName

            if Config.ESPDistance then
                text = text .. " [" .. dist .. "]"
            end

            pcall(function()
                entry.Name.Visible = true
                entry.Name.Position = Vector2.new(centerX, minY - 18)
                entry.Name.Text = text
                entry.Name.Color = color
            end)
        else
            pcall(function() entry.Name.Visible = false end)
        end

        if Config.ESPHealth then
            local hum = char:FindFirstChildOfClass("Humanoid")
            local frac = 0

            if hum and hum.MaxHealth > 0 then
                frac = clampNumber(hum.Health / hum.MaxHealth, 0, 1)
            end

            local x = left - 5
            local yTop = minY
            local yBottom = minY + height
            local yHealth = yBottom - (height * frac)

            pcall(function()
                entry.HealthBG.Visible = true
                entry.HealthBG.From = Vector2.new(x, yTop)
                entry.HealthBG.To = Vector2.new(x, yBottom)

                entry.Health.Visible = true
                entry.Health.From = Vector2.new(x, yHealth)
                entry.Health.To = Vector2.new(x, yBottom)

                if frac > 0.5 then
                    entry.Health.Color = Color3.fromRGB(0, 255, 0)
                elseif frac > 0.25 then
                    entry.Health.Color = Color3.fromRGB(255, 200, 0)
                else
                    entry.Health.Color = Color3.fromRGB(255, 50, 50)
                end
            end)
        else
            pcall(function()
                entry.HealthBG.Visible = false
                entry.Health.Visible = false
            end)
        end
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= lp and plr.Character then
            local displayName = plr.DisplayName
            if displayName == nil or displayName == "" then
                displayName = plr.Name
            end

            local color = isEnemy(plr)
                and Color3.fromRGB(255, 80, 80)
                or Color3.fromRGB(80, 255, 120)

            drawCharacter(plr.Character, displayName, color)
        end
    end

    if Config.TargetNPCs then
        for char in pairs(npcCharacters) do
            if char and char.Parent then
                drawCharacter(char, char.Name, Color3.fromRGB(255, 255, 255))
            else
                npcCharacters[char] = nil
            end
        end
    end

    for char, entry in pairs(espObjects) do
        if not active[char] or not char or not char.Parent then
            destroyESPEntry(entry)
            espObjects[char] = nil
        end
    end
end

-- Live mode status label
local lastModeUpdate = 0

local function updateModeStatus()
    if not modeStatus then return end

    local now = os.clock()
    if now - lastModeUpdate < 0.25 then return end
    lastModeUpdate = now

    local firstPerson = currentModeFirst()
    local armed = (firstPerson and Config.FirstPersonAimbot)
        or (not firstPerson and Config.ThirdPersonAimbot)

    modeStatus.Text = (firstPerson and "First person" or "Third person")
        .. (armed and " • armed" or " • off")
end

-- Third person arm: camera cframe lock, same as the version that held well.
local function aimCamera(part)
    local ok, partPos = pcall(function()
        return part.Position
    end)
    if not ok or not partPos then return end

    local cam = workspace.CurrentCamera
    if not cam then return end

    local toPart = partPos - cam.CFrame.Position
    if toPart.Magnitude < 0.01 then return end

    -- Angle deadzone: stop micro-jitter once the head is centered.
    local dot = toPart.Unit:Dot(cam.CFrame.LookVector)
    if dot > 0.99995 then return end

    local targetCF = CFrame.new(cam.CFrame.Position, partPos)

    if Config.Smoothness <= 0.01 then
        pcall(function()
            cam.CFrame = targetCF
        end)
    else
        local alpha = clampNumber(1 - Config.Smoothness, 0.05, 1)
        pcall(function()
            cam.CFrame = cam.CFrame:Lerp(targetCF, alpha)
        end)
    end
end

-- First person arm: exact mouse delta into the game's own aim input.
local function aimMouse(part, screenPos)
    if not screenPos then
        aimCamera(part)
        return
    end

    if type(mousemoverel) ~= "function" then
        aimCamera(part)
        return
    end

    local ref = getAimReference()
    local dx = screenPos.X - ref.X
    local dy = screenPos.Y - ref.Y

    -- Sub-pixel deadzone: hold the lock instead of oscillating around it.
    if math.abs(dx) < 0.5 and math.abs(dy) < 0.5 then
        return
    end

    local alpha = clampNumber(1 - Config.Smoothness, 0.05, 1)
    local mult = alpha * Config.MouseSensitivity

    pcall(function()
        mousemoverel(dx * mult, dy * mult)
    end)
end

-- Main aim step.
-- BindToRenderStep at Last priority runs AFTER the game camera updater,
-- so fps games can no longer overwrite the aim cframe every frame.
local function aimStep()
    updateFOV()
    updateESP()
    updateModeStatus()

    if not Config.Enabled then return end

    if not isAimKeyDown() then
        lastTargetPart = nil
        return
    end

    if not isLocalAlive() then return end

    local firstPerson = currentModeFirst()

    if firstPerson and not Config.FirstPersonAimbot then return end
    if not firstPerson and not Config.ThirdPersonAimbot then return end

    local part, screenPos = getClosestTarget()
    if not part then return end

    if firstPerson then
        aimMouse(part, screenPos)
    else
        aimCamera(part)
    end
end

-- Online games can detect camera or mouse manipulation; use only in authorized targets.
local bound = pcall(function()
    RunService:BindToRenderStep(
        STEP_NAME,
        Enum.RenderPriority.Last.Value,
        aimStep
    )
end)

if not bound then
    trackConn(RunService.RenderStepped:Connect(aimStep))
end

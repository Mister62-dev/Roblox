-- Universal Aimbot | Roblox

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local lp = Players.LocalPlayer

local GUI_NAME = "UniversalAimbot_GUI"
local CONFIG_FILE = "universal_aimbot_config.json"

local function getEnv()
    if getgenv then
        local ok, env = pcall(getgenv)
        if ok and env then return env end
    end
    return _G
end

local env = getEnv()

-- Clean previous execution connections and drawings.
pcall(function()
    local e = getEnv()
    if e._AIM_CONNS then
        for _, c in ipairs(e._AIM_CONNS) do
            pcall(function() c:Disconnect() end)
        end
    end
    e._AIM_CONNS = {}

    if e._AIM_DRAWING then
        pcall(function() e._AIM_DRAWING:Remove() end)
    end
    e._AIM_DRAWING = nil
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
        ShowFOV = true,
        AimKey = "RightClick",
        TargetPart = "Head",
        FOV = 120,
        Smoothness = 0.25,
        TeamCheck = true,
        WallCheck = true,
        TargetNPCs = false,
        MaxDistance = 1000
    }
end

local Config = defaultConfig()

local function sanitizeConfig()
    Config.FOV = clampNumber(Config.FOV, 10, 500)
    Config.Smoothness = clampNumber(Config.Smoothness, 0, 0.95)
    Config.MaxDistance = clampNumber(Config.MaxDistance, 50, 2000)

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
local configStatus

local function setToggleVisual(key)
    local c = uiControls.toggles[key]
    if not c then return end

    c.Button.Text = c.Label .. ": " .. (Config[key] and "ON" or "OFF")
    c.Button.BackgroundColor3 = Config[key]
        and Color3.fromRGB(40, 180, 70)
        or Color3.fromRGB(200, 40, 40)
end

local function setDropdownVisual(key)
    local c = uiControls.dropdowns[key]
    if not c then return end
    c.Button.Text = c.Label .. ": " .. tostring(Config[key])
end

local function formatSliderValue(key)
    if key == "Smoothness" then
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
screenGui.Parent = parentGui

local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, 380, 0, 300)
main.Position = UDim2.new(0.5, -190, 0.5, -150)
main.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
main.BorderSizePixel = 0
main.Active = true
main.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 8)
mainCorner.Parent = main

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 32)
title.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
title.BorderSizePixel = 0
title.Text = "Universal Aimbot | INSERT"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Active = true
title.Parent = main

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = title

local tabBar = Instance.new("Frame")
tabBar.Name = "TabBar"
tabBar.Size = UDim2.new(1, -12, 0, 28)
tabBar.Position = UDim2.new(0, 6, 0, 38)
tabBar.BackgroundTransparency = 1
tabBar.Parent = main

local tabList = Instance.new("UIListLayout")
tabList.FillDirection = Enum.FillDirection.Horizontal
tabList.SortOrder = Enum.SortOrder.LayoutOrder
tabList.Padding = UDim.new(0, 6)
tabList.VerticalAlignment = Enum.VerticalAlignment.Center
tabList.Parent = tabBar

local content = Instance.new("Frame")
content.Name = "Content"
content.Size = UDim2.new(1, -12, 1, -76)
content.Position = UDim2.new(0, 6, 0, 70)
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
    page.ScrollBarThickness = 4
    page.Visible = false
    page.Parent = content

    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 6)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = page

    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 6)
    padding.PaddingLeft = UDim.new(0, 6)
    padding.PaddingRight = UDim.new(0, 6)
    padding.Parent = page

    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 16)
    end)

    pages[name] = page
    return page
end

local function setTab(name)
    for tabName, page in pairs(pages) do
        page.Visible = (tabName == name)
    end

    for tabName, btn in pairs(tabButtons) do
        btn.BackgroundColor3 = tabName == name
            and Color3.fromRGB(60, 60, 75)
            or Color3.fromRGB(40, 40, 50)
    end
end

local function makeTab(name, order)
    local btn = Instance.new("TextButton")
    btn.LayoutOrder = order
    btn.Size = UDim2.new(0, 105, 1, 0)
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    btn.BorderSizePixel = 0
    btn.Text = name
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 14
    btn.Parent = tabBar

    btn.MouseButton1Click:Connect(function()
        setTab(name)
    end)

    tabButtons[name] = btn
end

local function makeToggle(parent, order, label, key)
    local btn = Instance.new("TextButton")
    btn.LayoutOrder = order
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    btn.BorderSizePixel = 0
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 14
    btn.Text = label
    btn.Parent = parent

    btn.MouseButton1Click:Connect(function()
        Config[key] = not Config[key]
        setToggleVisual(key)
    end)

    uiControls.toggles[key] = {
        Button = btn,
        Label = label
    }

    setToggleVisual(key)
end

local function makeDropdown(parent, order, label, key, options)
    local btn = Instance.new("TextButton")
    btn.LayoutOrder = order
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    btn.BorderSizePixel = 0
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 14
    btn.Text = label .. ": " .. tostring(Config[key])
    btn.Parent = parent

    btn.MouseButton1Click:Connect(function()
        local idx = findIndex(options, Config[key]) or 0
        idx = (idx % #options) + 1
        Config[key] = options[idx]
        setDropdownVisual(key)
    end)

    uiControls.dropdowns[key] = {
        Button = btn,
        Label = label
    }

    setDropdownVisual(key)
end

local function makeSlider(parent, order, label, key, min, max, step)
    local row = Instance.new("Frame")
    row.LayoutOrder = order
    row.Size = UDim2.new(1, 0, 0, 30)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(0.55, 0, 1, 0)
    nameLabel.Position = UDim2.new(0, 0, 0, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = label
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.Font = Enum.Font.GothamSemibold
    nameLabel.TextSize = 14
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = row

    local minus = Instance.new("TextButton")
    minus.Size = UDim2.new(0.12, 0, 1, 0)
    minus.Position = UDim2.new(0.56, 0, 0, 0)
    minus.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    minus.BorderSizePixel = 0
    minus.Text = "-"
    minus.TextColor3 = Color3.fromRGB(255, 255, 255)
    minus.Font = Enum.Font.GothamBold
    minus.TextSize = 16
    minus.Parent = row

    local value = Instance.new("TextLabel")
    value.Size = UDim2.new(0.2, 0, 1, 0)
    value.Position = UDim2.new(0.68, 0, 0, 0)
    value.BackgroundTransparency = 1
    value.Text = formatSliderValue(key)
    value.TextColor3 = Color3.fromRGB(200, 200, 200)
    value.Font = Enum.Font.Gotham
    value.TextSize = 13
    value.Parent = row

    local plus = Instance.new("TextButton")
    plus.Size = UDim2.new(0.12, 0, 1, 0)
    plus.Position = UDim2.new(0.88, 0, 0, 0)
    plus.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    plus.BorderSizePixel = 0
    plus.Text = "+"
    plus.TextColor3 = Color3.fromRGB(255, 255, 255)
    plus.Font = Enum.Font.GothamBold
    plus.TextSize = 16
    plus.Parent = row

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

local function makeButton(parent, order, text, callback)
    local btn = Instance.new("TextButton")
    btn.LayoutOrder = order
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    btn.BorderSizePixel = 0
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamSemibold
    btn.TextSize = 14
    btn.Parent = parent

    btn.MouseButton1Click:Connect(callback)

    return btn
end

local pageAim = makePage("Aim")
local pageTargeting = makePage("Targeting")
local pageConfig = makePage("Config")

makeTab("Aim", 1)
makeTab("Targeting", 2)
makeTab("Config", 3)

makeToggle(pageAim, 1, "Aimbot", "Enabled")
makeToggle(pageAim, 2, "Show FOV", "ShowFOV")
makeDropdown(pageAim, 3, "Aim Key", "AimKey", {"RightClick", "LeftClick", "Q", "E", "C", "X"})
makeSlider(pageAim, 4, "FOV", "FOV", 10, 500, 5)
makeSlider(pageAim, 5, "Smooth", "Smoothness", 0, 0.95, 0.05)

makeToggle(pageTargeting, 1, "Team Check", "TeamCheck")
makeToggle(pageTargeting, 2, "Wall Check", "WallCheck")
makeToggle(pageTargeting, 3, "Target NPCs", "TargetNPCs")
makeDropdown(pageTargeting, 4, "Part", "TargetPart", {"Head", "HumanoidRootPart", "UpperTorso", "Torso"})
makeSlider(pageTargeting, 5, "Max Dist", "MaxDistance", 50, 2000, 50)

makeButton(pageConfig, 1, "Save Config", function()
    local ok, where = saveConfig()
    if configStatus then
        configStatus.Text = ok and ("Saved to " .. where) or "Save failed"
    end
end)

makeButton(pageConfig, 2, "Load Config", function()
    local ok = loadConfig()
    sanitizeConfig()
    refreshUI()
    if configStatus then
        configStatus.Text = ok and "Loaded" or "Load failed"
    end
end)

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
end)

configStatus = Instance.new("TextLabel")
configStatus.LayoutOrder = 4
configStatus.Size = UDim2.new(1, 0, 0, 30)
configStatus.BackgroundTransparency = 1
configStatus.Text = "Config: ready"
configStatus.TextColor3 = Color3.fromRGB(200, 200, 200)
configStatus.Font = Enum.Font.Gotham
configStatus.TextSize = 13
configStatus.Parent = pageConfig

setTab("Aim")
refreshUI()

for _, page in pairs(pages) do
    local list = page:FindFirstChildOfClass("UIListLayout")
    if list then
        page.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 16)
    end
end

-- Drag
local dragging = false
local dragStart, startPos

title.InputBegan:Connect(function(input)
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

local function isAimKeyDown()
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

-- Dead check for any humanoid character.
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

-- Dead check for the local player.
local function isLocalAlive()
    return isAlive(lp.Character)
end

local function isEnemy(plr)
    if not Config.TeamCheck then return true end
    if plr.Team and lp.Team and plr.Team == lp.Team then return false end
    return true
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

    local filter = {}
    if lp.Character then
        table.insert(filter, lp.Character)
    end
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

local function getClosestTarget()
    if not isLocalAlive() then
        return nil
    end

    local cam = workspace.CurrentCamera
    if not cam then return nil end

    local mousePos = UserInputService:GetMouseLocation()
    local bestPart = nil
    local bestScreenDist = Config.FOV

    local function consider(char)
        if not isAlive(char) then return end

        local part = getCharacterPart(char)
        if not part then return end

        local dist3D = (part.Position - cam.CFrame.Position).Magnitude
        if dist3D > Config.MaxDistance then return end

        local ok, screenPos, onScreen = pcall(function()
            return cam:WorldToViewportPoint(part.Position)
        end)

        if not ok or not screenPos or not onScreen then return end

        local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
        if screenDist > bestScreenDist then return end

        if Config.WallCheck and not isVisible(part, char) then return end

        bestPart = part
        bestScreenDist = screenDist
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

    return bestPart
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
            fovCircle.Position = UserInputService:GetMouseLocation()
        end)
    end
end

-- Main aim loop
-- Online games can detect camera manipulation; use only in authorized targets.
trackConn(RunService.RenderStepped:Connect(function()
    updateFOV()

    if Config.Enabled and isAimKeyDown() and isLocalAlive() then
        local part = getClosestTarget()

        if part then
            local ok, partPos = pcall(function()
                return part.Position
            end)

            if ok and partPos then
                local cam = workspace.CurrentCamera

                if cam and (partPos - cam.CFrame.Position).Magnitude > 0.01 then
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
            end
        end
    end
end))

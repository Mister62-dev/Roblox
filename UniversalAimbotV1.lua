-- Roblox local-place aim/ESP validation harness.
-- Targets only CollectionService-tagged models in Workspace.AimTestTargets.
-- run only in a place you own; pointing this at live players is a ban path.

if not game:GetService("RunService"):IsClient() then
    return
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local TAG = "AimTarget"
local CONFIG_FILE = "axiom_aim_test_config.json"

local function DeepCopy(input)
    local output = {}
    for key, value in pairs(input) do
        if typeof(value) == "table" then
            output[key] = DeepCopy(value)
        else
            output[key] = value
        end
    end
    return output
end

local DEFAULT_CONFIG = {
    Aimbot = {
        Enabled = false,
        FOV = 65.0,
        Smooth = 0.35,
    },
    Checks = {
        Dead = true,
        Wall = true,
        Team = true,
        LocalTeam = 0,
    },
    ESP = {
        Enabled = true,
        Highlights = true,
        Info = true,
        ShowDead = true,
    },
}

local Config = DeepCopy(DEFAULT_CONFIG)
local RefreshUI = function() end

local function FileExists(path)
    if typeof(isfile) ~= "function" then
        return false
    end

    local ok, exists = pcall(isfile, path)
    return ok and exists == true
end

local function ReadFile(path)
    if typeof(readfile) ~= "function" then
        return nil
    end

    local ok, content = pcall(readfile, path)
    if ok then
        return content
    end

    return nil
end

local function WriteFile(path, content)
    if typeof(writefile) ~= "function" then
        return false
    end

    local ok = pcall(writefile, path, content)
    return ok
end

local function ApplyConfig(data)
    if typeof(data) ~= "table" then
        return false
    end

    for section, values in pairs(data) do
        if typeof(Config[section]) == "table" and typeof(values) == "table" then
            for key, value in pairs(values) do
                if typeof(Config[section][key]) == typeof(value) then
                    Config[section][key] = value
                end
            end
        end
    end

    RefreshUI()
    return true
end

local function GetCamera()
    return Workspace.CurrentCamera or Workspace:FindFirstChildWhichIsA("Camera")
end

local function GetCameraPosition()
    local camera = GetCamera()
    if camera then
        return camera.CFrame.Position
    end

    return Vector3.new(0, 5, 0)
end

local function EnsureTestTargets()
    local folder = Workspace:FindFirstChild("AimTestTargets")
    if not folder then
        folder = Instance.new("Folder")
        folder.Name = "AimTestTargets"
        folder.Parent = Workspace
    end

    local base = GetCameraPosition()

    if #CollectionService:GetTagged(TAG) == 0 then
        for i = 1, 10 do
            local model = Instance.new("Model")
            model.Name = string.format("Dummy%02d", i)

            local root = Instance.new("Part")
            root.Name = "HumanoidRootPart"
            root.Size = Vector3.new(2, 4, 1)
            root.Anchored = true
            root.CanCollide = false

            local angle = (i / 10) * math.pi * 2
            local radius = 14 + (i % 3) * 6
            local offset = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
            root.CFrame = CFrame.new(base + offset)
            root.Parent = model

            local humanoid = Instance.new("Humanoid")
            humanoid.MaxHealth = 100
            humanoid.Health = 100
            humanoid.Parent = model

            model.PrimaryPart = root
            model:SetAttribute("Team", i % 2)

            if i % 4 == 0 then
                humanoid.Health = 0
            end

            CollectionService:AddTag(model, TAG)
            model.Parent = folder
        end
    end

    local wall = folder:FindFirstChild("TestWall")
    if not wall then
        wall = Instance.new("Part")
        wall.Name = "TestWall"
        wall.Size = Vector3.new(12, 8, 1)
        wall.Anchored = true
        wall.CanCollide = true
        wall.Transparency = 0.45
        wall.CFrame = CFrame.new(base + Vector3.new(0, 2, -12))
        wall.Parent = folder
    end
end

EnsureTestTargets()

local function GetTargets()
    local targets = {}

    for _, model in ipairs(CollectionService:GetTagged(TAG)) do
        if model.Parent then
            table.insert(targets, model)
        end
    end

    return targets
end

local function GetRoot(model)
    return model.PrimaryPart
        or model:FindFirstChild("HumanoidRootPart")
        or model:FindFirstChildWhichIsA("BasePart")
end

local function GetHumanoid(model)
    return model:FindFirstChildWhichIsA("Humanoid")
end

local function IsDead(model)
    local humanoid = GetHumanoid(model)
    return humanoid ~= nil and humanoid.Health <= 0
end

local function GetTeam(model)
    local team = model:GetAttribute("Team")
    if typeof(team) ~= "number" then
        return 0
    end

    return team
end

local function HasLineOfSight(target)
    local root = GetRoot(target)
    local camera = GetCamera()

    if not root or not camera then
        return false
    end

    local origin = camera.CFrame.Position
    local targetPos = root.Position
    local direction = targetPos - origin

    if direction.Magnitude < 0.05 then
        return true
    end

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude

    local filter = {}
    local character = LocalPlayer.Character
    if character then
        table.insert(filter, character)
    end

    table.insert(filter, target)
    params.FilterDescendantsInstances = filter

    local result = Workspace:Raycast(origin, direction, params)
    return result == nil
end

local function GetTargetAngle(targetPos)
    local camera = GetCamera()
    if not camera then
        return math.huge
    end

    local look = camera.CFrame.LookVector
    local direction = targetPos - camera.CFrame.Position

    if direction.Magnitude < 0.05 then
        return 0
    end

    local dot = look:Dot(direction.Unit)
    return math.deg(math.acos(math.clamp(dot, -1, 1)))
end

local function SelectTarget()
    if not Config.Aimbot.Enabled then
        return nil
    end

    local best = nil
    local bestScore = math.huge

    for _, model in ipairs(GetTargets()) do
        local root = GetRoot(model)

        if root then
            if Config.Checks.Dead and IsDead(model) then
                continue
            end

            local team = GetTeam(model)
            if Config.Checks.Team and team == Config.Checks.LocalTeam then
                continue
            end

            local angle = GetTargetAngle(root.Position)
            if angle <= Config.Aimbot.FOV then
                if Config.Checks.Wall and not HasLineOfSight(model) then
                    continue
                end

                if angle < bestScore then
                    bestScore = angle
                    best = model
                end
            end
        end
    end

    return best
end

local currentTarget = nil
local espCache = {}

local function UpdateESP()
    if not Config.ESP.Enabled then
        for _, entry in pairs(espCache) do
            if entry.Highlight then
                entry.Highlight:Destroy()
            end

            if entry.Billboard then
                entry.Billboard:Destroy()
            end
        end

        espCache = {}
        return
    end

    local seen = {}

    for _, model in ipairs(GetTargets()) do
        seen[model] = true
        local root = GetRoot(model)

        if root then
            local entry = espCache[model]

            if not entry then
                local highlight = Instance.new("Highlight")
                highlight.Adornee = model
                highlight.FillTransparency = 0.7
                highlight.OutlineTransparency = 0
                highlight.Parent = model

                local billboard = Instance.new("BillboardGui")
                billboard.Adornee = root
                billboard.Size = UDim2.fromOffset(170, 20)
                billboard.StudsOffset = Vector3.new(0, 3, 0)
                billboard.AlwaysOnTop = true
                billboard.Parent = model

                local label = Instance.new("TextLabel")
                label.Size = UDim2.fromScale(1, 1)
                label.BackgroundTransparency = 1
                label.TextScaled = true
                label.Font = Enum.Font.Code
                label.TextColor3 = Color3.fromRGB(220, 225, 235)
                label.TextStrokeTransparency = 0
                label.Parent = billboard

                entry = {
                    Highlight = highlight,
                    Billboard = billboard,
                    Label = label,
                }

                espCache[model] = entry
            end

            local dead = IsDead(model)
            local visible = (not dead) or Config.ESP.ShowDead

            entry.Highlight.Enabled = Config.ESP.Highlights and visible
            entry.Billboard.Enabled = Config.ESP.Info and visible

            local team = GetTeam(model)
            local color

            if dead then
                color = Color3.fromRGB(120, 120, 125)
            elseif Config.Checks.Team and team == Config.Checks.LocalTeam then
                color = Color3.fromRGB(80, 160, 255)
            else
                color = Color3.fromRGB(255, 90, 90)
            end

            if currentTarget == model then
                color = Color3.fromRGB(255, 220, 80)
            end

            entry.Highlight.FillColor = color
            entry.Highlight.OutlineColor = color

            local humanoid = GetHumanoid(model)
            local health = humanoid and math.floor(humanoid.Health) or 0

            local wallText = "WALL OFF"
            if Config.Checks.Wall then
                wallText = HasLineOfSight(model) and "LOS" or "OCCLUDED"
            end

            entry.Label.Text = string.format("%s T%d HP%d %s", model.Name, team, health, wallText)
            entry.Label.TextColor3 = color
        end
    end

    for model, entry in pairs(espCache) do
        if not seen[model] then
            if entry.Highlight then
                entry.Highlight:Destroy()
            end

            if entry.Billboard then
                entry.Billboard:Destroy()
            end

            espCache[model] = nil
        end
    end
end

local function BuildGui()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")

    local screen = Instance.new("ScreenGui")
    screen.Name = "AimTestHarness"
    screen.ResetOnSpawn = false
    screen.DisplayOrder = 999
    screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screen.Parent = playerGui

    local main = Instance.new("Frame")
    main.Size = UDim2.fromOffset(390, 380)
    main.Position = UDim2.new(0.5, -195, 0.5, -190)
    main.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
    main.BorderColor3 = Color3.fromRGB(80, 86, 100)
    main.BorderSizePixel = 1
    main.Visible = true
    main.Parent = screen

    local title = Instance.new("TextButton")
    title.Size = UDim2.new(1, 0, 0, 24)
    title.BackgroundColor3 = Color3.fromRGB(45, 50, 62)
    title.BorderSizePixel = 0
    title.Text = "AIM/ESP TEST HARNESS"
    title.TextColor3 = Color3.fromRGB(220, 225, 235)
    title.Font = Enum.Font.Code
    title.TextSize = 14
    title.Parent = main

    local dragging = false
    local dragStart = nil
    local startPos = nil

    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    local tabBar = Instance.new("Frame")
    tabBar.Position = UDim2.new(0, 8, 0, 28)
    tabBar.Size = UDim2.new(1, -16, 0, 22)
    tabBar.BackgroundTransparency = 1
    tabBar.Parent = main

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.Padding = UDim.new(0, 4)
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Parent = tabBar

    local pages = {}
    local tabButtons = {}

    local function SetTab(index)
        for i, page in ipairs(pages) do
            page.Visible = i == index
        end

        for i, button in ipairs(tabButtons) do
            if i == index then
                button.BackgroundColor3 = Color3.fromRGB(60, 66, 80)
            else
                button.BackgroundColor3 = Color3.fromRGB(35, 39, 48)
            end
        end
    end

    local function AddTab(name)
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0, 72, 1, 0)
        button.BackgroundColor3 = Color3.fromRGB(35, 39, 48)
        button.BorderColor3 = Color3.fromRGB(80, 86, 100)
        button.Text = name
        button.TextColor3 = Color3.fromRGB(220, 225, 235)
        button.Font = Enum.Font.Code
        button.TextSize = 13
        button.Parent = tabBar

        local page = Instance.new("ScrollingFrame")
        page.Position = UDim2.new(0, 8, 0, 56)
        page.Size = UDim2.new(1, -16, 1, -64)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 4
        page.Visible = false
        page.Parent = main

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 4)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = page

        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 8)
        end)

        page.CanvasSize = UDim2.new(0, 0, 0, 0)

        table.insert(pages, page)
        table.insert(tabButtons, button)

        local index = #pages
        button.MouseButton1Click:Connect(function()
            SetTab(index)
        end)

        return page
    end

    local refreshers = {}

    RefreshUI = function()
        for _, refresh in ipairs(refreshers) do
            refresh()
        end
    end

    local function AddCheckbox(page, label, getValue, setValue)
        local holder = Instance.new("Frame")
        holder.Size = UDim2.new(1, 0, 0, 22)
        holder.BackgroundTransparency = 1
        holder.LayoutOrder = #page:GetChildren() + 1
        holder.Parent = page

        local button = Instance.new("TextButton")
        button.Size = UDim2.fromScale(1, 1)
        button.BackgroundTransparency = 1
        button.Text = ""
        button.Parent = holder

        local box = Instance.new("Frame")
        box.Size = UDim2.fromOffset(14, 14)
        box.Position = UDim2.new(0, 2, 0.5, -7)
        box.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
        box.BorderColor3 = Color3.fromRGB(80, 86, 100)
        box.Parent = holder

        local text = Instance.new("TextLabel")
        text.Position = UDim2.new(0, 22, 0, 0)
        text.Size = UDim2.new(1, -22, 1, 0)
        text.BackgroundTransparency = 1
        text.Text = label
        text.TextXAlignment = Enum.TextXAlignment.Left
        text.TextColor3 = Color3.fromRGB(220, 225, 235)
        text.Font = Enum.Font.Code
        text.TextSize = 14
        text.Parent = holder

        local function refresh()
            local value = getValue()
            box.BackgroundColor3 = value and Color3.fromRGB(90, 200, 120) or Color3.fromRGB(20, 22, 28)
        end

        button.MouseButton1Click:Connect(function()
            setValue(not getValue())
            refresh()
        end)

        table.insert(refreshers, refresh)
        refresh()
    end

    local function AddSlider(page, label, min, max, getValue, setValue)
        local holder = Instance.new("Frame")
        holder.Size = UDim2.new(1, 0, 0, 26)
        holder.BackgroundTransparency = 1
        holder.LayoutOrder = #page:GetChildren() + 1
        holder.Parent = page

        local labelText = Instance.new("TextLabel")
        labelText.Position = UDim2.new(0, 2, 0, 0)
        labelText.Size = UDim2.new(0, 105, 1, 0)
        labelText.BackgroundTransparency = 1
        labelText.Text = label
        labelText.TextXAlignment = Enum.TextXAlignment.Left
        labelText.TextColor3 = Color3.fromRGB(220, 225, 235)
        labelText.Font = Enum.Font.Code
        labelText.TextSize = 14
        labelText.Parent = holder

        local valueText = Instance.new("TextLabel")
        valueText.Position = UDim2.new(1, -58, 0, 0)
        valueText.Size = UDim2.new(0, 56, 1, 0)
        valueText.BackgroundTransparency = 1
        valueText.Text = ""
        valueText.TextXAlignment = Enum.TextXAlignment.Right
        valueText.TextColor3 = Color3.fromRGB(160, 167, 180)
        valueText.Font = Enum.Font.Code
        valueText.TextSize = 13
        valueText.Parent = holder

        local slider = Instance.new("TextButton")
        slider.Position = UDim2.new(0, 112, 0, 9)
        slider.Size = UDim2.new(1, -178, 0, 8)
        slider.BackgroundColor3 = Color3.fromRGB(25, 28, 35)
        slider.BorderColor3 = Color3.fromRGB(80, 86, 100)
        slider.Text = ""
        slider.AutoButtonColor = false
        slider.Parent = holder

        local fill = Instance.new("Frame")
        fill.Size = UDim2.fromScale(0, 1)
        fill.BackgroundColor3 = Color3.fromRGB(90, 160, 255)
        fill.BorderSizePixel = 0
        fill.Parent = slider

        local sliderDragging = false

        local function refresh()
            local value = getValue()
            local frac = math.clamp((value - min) / math.max(1e-6, max - min), 0, 1)
            fill.Size = UDim2.fromScale(frac, 1)
            valueText.Text = string.format("%.2f", value)
        end

        local function update(input)
            local absSize = slider.AbsoluteSize
            if absSize.X <= 0 then
                return
            end

            local frac = math.clamp((input.Position.X - slider.AbsolutePosition.X) / absSize.X, 0, 1)
            setValue(min + frac * (max - min))
            refresh()
        end

        slider.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                sliderDragging = true
                update(input)
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if sliderDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                update(input)
            end
        end)

        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                sliderDragging = false
            end
        end)

        table.insert(refreshers, refresh)
        refresh()
    end

    local function AddButton(page, label, onClick)
        local holder = Instance.new("Frame")
        holder.Size = UDim2.new(1, 0, 0, 24)
        holder.BackgroundTransparency = 1
        holder.LayoutOrder = #page:GetChildren() + 1
        holder.Parent = page

        local button = Instance.new("TextButton")
        button.Size = UDim2.fromScale(1, 1)
        button.BackgroundColor3 = Color3.fromRGB(35, 39, 48)
        button.BorderColor3 = Color3.fromRGB(80, 86, 100)
        button.Text = label
        button.TextColor3 = Color3.fromRGB(220, 225, 235)
        button.Font = Enum.Font.Code
        button.TextSize = 14
        button.Parent = holder

        button.MouseButton1Click:Connect(onClick)
    end

    local function AddConfigWidgets(page)
        local boxHolder = Instance.new("Frame")
        boxHolder.Size = UDim2.new(1, 0, 0, 145)
        boxHolder.BackgroundTransparency = 1
        boxHolder.LayoutOrder = #page:GetChildren() + 1
        boxHolder.Parent = page

        local box = Instance.new("TextBox")
        box.Size = UDim2.fromScale(1, 1)
        box.MultiLine = true
        box.TextWrapped = true
        box.ClearTextOnFocus = false
        box.BackgroundColor3 = Color3.fromRGB(25, 28, 35)
        box.BorderColor3 = Color3.fromRGB(80, 86, 100)
        box.TextColor3 = Color3.fromRGB(210, 215, 225)
        box.PlaceholderColor3 = Color3.fromRGB(120, 126, 138)
        box.Font = Enum.Font.Code
        box.TextSize = 12
        box.Text = ""
        box.PlaceholderText = "paste JSON here"
        box.Parent = boxHolder

        local statusLabel = nil

        local function setStatus(message)
            if statusLabel then
                statusLabel.Text = message
            end
        end

        AddButton(page, "Save JSON", function()
            local ok, json = pcall(function()
                return HttpService:JSONEncode(Config)
            end)

            if not ok then
                setStatus("encode failed")
                return
            end

            box.Text = json
            local savedTo = "box"

            if WriteFile(CONFIG_FILE, json) then
                savedTo = savedTo .. "+file"
            end

            if typeof(setclipboard) == "function" then
                pcall(setclipboard, json)
                savedTo = savedTo .. "+clipboard"
            end

            setStatus("saved to " .. savedTo)
        end)

        AddButton(page, "Load JSON", function()
            local jsonText = box.Text

            if (jsonText == nil or jsonText == "") and FileExists(CONFIG_FILE) then
                jsonText = ReadFile(CONFIG_FILE)
            end

            local ok, data = pcall(function()
                return HttpService:JSONDecode(jsonText)
            end)

            if ok and ApplyConfig(data) then
                setStatus("loaded")
            else
                setStatus("load failed")
            end
        end)

        AddButton(page, "Reset Default", function()
            ApplyConfig(DeepCopy(DEFAULT_CONFIG))
            setStatus("reset")
        end)

        local statusHolder = Instance.new("Frame")
        statusHolder.Size = UDim2.new(1, 0, 0, 20)
        statusHolder.BackgroundTransparency = 1
        statusHolder.LayoutOrder = #page:GetChildren() + 1
        statusHolder.Parent = page

        statusLabel = Instance.new("TextLabel")
        statusLabel.Size = UDim2.fromScale(1, 1)
        statusLabel.BackgroundTransparency = 1
        statusLabel.Text = "ready"
        statusLabel.TextXAlignment = Enum.TextXAlignment.Left
        statusLabel.TextColor3 = Color3.fromRGB(150, 155, 165)
        statusLabel.Font = Enum.Font.Code
        statusLabel.TextSize = 13
        statusLabel.Parent = statusHolder
    end

    local aimPage = AddTab("Aimbot")
    AddCheckbox(aimPage, "Aimbot Enabled", function()
        return Config.Aimbot.Enabled
    end, function(value)
        Config.Aimbot.Enabled = value
    end)

    AddSlider(aimPage, "FOV", 0, 180, function()
        return Config.Aimbot.FOV
    end, function(value)
        Config.Aimbot.FOV = value
    end)

    AddSlider(aimPage, "Smooth", 0, 0.95, function()
        return Config.Aimbot.Smooth
    end, function(value)
        Config.Aimbot.Smooth = value
    end)

    local checksPage = AddTab("Checks")
    AddCheckbox(checksPage, "Dead Check", function()
        return Config.Checks.Dead
    end, function(value)
        Config.Checks.Dead = value
    end)

    AddCheckbox(checksPage, "Wall Check", function()
        return Config.Checks.Wall
    end, function(value)
        Config.Checks.Wall = value
    end)

    AddCheckbox(checksPage, "Team Check", function()
        return Config.Checks.Team
    end, function(value)
        Config.Checks.Team = value
    end)

    AddSlider(checksPage, "Local Team", 0, 10, function()
        return Config.Checks.LocalTeam
    end, function(value)
        Config.Checks.LocalTeam = math.floor(value)
    end)

    local espPage = AddTab("ESP")
    AddCheckbox(espPage, "ESP Enabled", function()
        return Config.ESP.Enabled
    end, function(value)
        Config.ESP.Enabled = value
    end)

    AddCheckbox(espPage, "Highlights", function()
        return Config.ESP.Highlights
    end, function(value)
        Config.ESP.Highlights = value
    end)

    AddCheckbox(espPage, "Info", function()
        return Config.ESP.Info
    end, function(value)
        Config.ESP.Info = value
    end)

    AddCheckbox(espPage, "Show Dead", function()
        return Config.ESP.ShowDead
    end, function(value)
        Config.ESP.ShowDead = value
    end)

    local configPage = AddTab("Config")
    AddConfigWidgets(configPage)

    SetTab(1)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then
            return
        end

        if input.KeyCode == Enum.KeyCode.Insert then
            main.Visible = not main.Visible
        end
    end)
end

BuildGui()

if FileExists(CONFIG_FILE) then
    local fileText = ReadFile(CONFIG_FILE)
    if fileText then
        local ok, data = pcall(function()
            return HttpService:JSONDecode(fileText)
        end)

        if ok then
            ApplyConfig(data)
        end
    end
end

RefreshUI()

RunService:BindToRenderStep("AimHarness", Enum.RenderPriority.Camera.Value + 1, function(dt)
    currentTarget = SelectTarget()

    local camera = GetCamera()
    if camera then
        if Config.Aimbot.Enabled then
            if camera.CameraType ~= Enum.CameraType.Scriptable then
                camera.CameraType = Enum.CameraType.Scriptable
            end

            if currentTarget then
                local root = GetRoot(currentTarget)
                if root then
                    local desired = CFrame.lookAt(camera.CFrame.Position, root.Position)
                    local alpha = math.clamp((1 - Config.Aimbot.Smooth) * 10 * dt, 0, 1)
                    camera.CFrame = camera.CFrame:Lerp(desired, alpha)
                end
            end
        elseif camera.CameraType ~= Enum.CameraType.Custom then
            camera.CameraType = Enum.CameraType.Custom
        end
    end

    UpdateESP()
end)

if _G.PhantomRobloxNPCSuite then return end
_G.PhantomRobloxNPCSuite = true

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

if not Drawing or not Drawing.new then return end

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
    task.wait()
    LocalPlayer = Players.LocalPlayer
end

local Camera = Workspace.CurrentCamera
if not Camera then
    Camera = Workspace:FindFirstChildOfClass("Camera") or Workspace:WaitForChild("Camera")
end

local Mouse = LocalPlayer:GetMouse()

local Config = {
    Aimbot = {
        Enabled = false,

        -- Silent lock: locks a head without moving your camera.
        SilentLock = true,

        -- If SilentLock + SilentIgnoreFOV are enabled, it picks the closest visible target
        -- even if your crosshair is not near it.
        SilentIgnoreFOV = true,

        KeepLockAfterRelease = true,
        RetargetWhileHeld = true,
        ShowLockIndicator = true,

        -- Executor-dependent silent redirection hooks.
        SilentRaycastHook = true,
        SilentMouseHook = true,

        IncludePlayers = true,
        IncludeNPCs = true,
        TeamCheck = true,
        WallCheck = true,
        AliveCheck = true,

        FOV = 170,
        Smoothness = 0.18,
        TargetPart = "Head",
        ActivationKey = Enum.UserInputType.MouseButton2
    },

    ESP = {
        Enabled = false,
        IncludePlayers = true,
        IncludeNPCs = true,
        TeamCheck = true,
        DrawBox = true,
        DrawName = true,
        DrawHealth = true,
        PlayerAllyColor = Color3.fromRGB(80, 200, 255),
        PlayerEnemyColor = Color3.fromRGB(255, 80, 80),
        NPCColor = Color3.fromRGB(255, 180, 50)
    },

    UI = {
        ToggleKey = Enum.KeyCode.Insert
    }
}

local TrackedModels = {}
local Drawings = {}
local IsAiming = false
local LockedTarget = nil

local function GetParentGUI()
    local ok, parent = pcall(function()
        if gethui then
            return gethui()
        end
        return game:GetService("CoreGui")
    end)

    if ok and parent then
        return parent
    end

    return LocalPlayer:WaitForChild("PlayerGui")
end

------------------------------------------------------------
-- UI
------------------------------------------------------------

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PhantomSilentSuite"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
ScreenGui.IgnoreGuiInset = true
ScreenGui.Enabled = true

local guiParent = GetParentGUI()
pcall(function()
    ScreenGui.Parent = guiParent
end)

if not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local fullSize = UDim2.new(0, 280, 0, 420)
local collapsedSize = UDim2.new(0, 280, 0, 42)

local MainFrame = Instance.new("Frame")
MainFrame.Size = fullSize
MainFrame.Position = UDim2.new(0.5, -140, 0.5, -210)
MainFrame.BackgroundColor3 = Color3.fromRGB(17, 17, 22)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Active = true
MainFrame.Draggable = false
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(48, 48, 60)
MainStroke.Thickness = 1
MainStroke.Parent = MainFrame

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 42)
TopBar.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TopGradient = Instance.new("UIGradient")
TopGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 60, 100)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(130, 80, 255))
})
TopGradient.Rotation = 0
TopGradient.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -92, 1, 0)
Title.Position = UDim2.new(0, 14, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "PHANTOM // SILENT LOCK"
Title.TextColor3 = Color3.fromRGB(250, 250, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 15
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local MinimizeButton = Instance.new("TextButton")
MinimizeButton.Size = UDim2.new(0, 28, 0, 28)
MinimizeButton.Position = UDim2.new(1, -38, 0.5, -14)
MinimizeButton.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MinimizeButton.BackgroundTransparency = 0.15
MinimizeButton.BorderSizePixel = 0
MinimizeButton.Text = "-"
MinimizeButton.Font = Enum.Font.GothamBold
MinimizeButton.TextColor3 = Color3.fromRGB(240, 240, 245)
MinimizeButton.TextSize = 18
MinimizeButton.AutoButtonColor = false
MinimizeButton.Parent = TopBar

local MinimizeCorner = Instance.new("UICorner")
MinimizeCorner.CornerRadius = UDim.new(0, 8)
MinimizeCorner.Parent = MinimizeButton

local Content = Instance.new("ScrollingFrame")
Content.Size = UDim2.new(1, 0, 1, -42)
Content.Position = UDim2.new(0, 0, 0, 42)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 3
Content.ScrollBarImageColor3 = Color3.fromRGB(90, 90, 110)
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.CanvasSize = UDim2.new(0, 0, 0, 0)
Content.Parent = MainFrame

local ContentPadding = Instance.new("UIPadding")
ContentPadding.PaddingLeft = UDim.new(0, 12)
ContentPadding.PaddingRight = UDim.new(0, 12)
ContentPadding.PaddingTop = UDim.new(0, 10)
ContentPadding.PaddingBottom = UDim.new(0, 12)
ContentPadding.Parent = Content

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 8)
UIListLayout.Parent = Content

------------------------------------------------------------
-- Drag + Minimize
------------------------------------------------------------

local dragging = false
local dragStart = Vector2.new()
local startPos = Vector2.new()

local function IsMouseOverGui(gui, position)
    local absPos = gui.AbsolutePosition
    local absSize = gui.AbsoluteSize

    return position.X >= absPos.X
        and position.X <= absPos.X + absSize.X
        and position.Y >= absPos.Y
        and position.Y <= absPos.Y + absSize.Y
end

TopBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if IsMouseOverGui(MinimizeButton, input.Position) then
            return
        end

        dragging = true
        dragStart = Vector2.new(input.Position.X, input.Position.Y)
        startPos = Vector2.new(MainFrame.AbsolutePosition.X, MainFrame.AbsolutePosition.Y)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStart
        local newX = startPos.X + delta.X
        local newY = startPos.Y + delta.Y

        local viewport = Camera and Camera.ViewportSize or Vector2.new(1280, 720)
        newX = math.clamp(newX, 0, math.max(0, viewport.X - MainFrame.AbsoluteSize.X))
        newY = math.clamp(newY, 0, math.max(0, viewport.Y - MainFrame.AbsoluteSize.Y))

        MainFrame.Position = UDim2.new(0, newX, 0, newY)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

local minimized = false

MinimizeButton.MouseButton1Click:Connect(function()
    minimized = not minimized
    MinimizeButton.Text = minimized and "+" or "-"

    local targetSize = minimized and collapsedSize or fullSize

    if minimized then
        Content.Visible = false
    end

    TweenService:Create(
        MainFrame,
        TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Size = targetSize }
    ):Play()

    if not minimized then
        Content.Visible = true
    end
end)

MinimizeButton.MouseEnter:Connect(function()
    MinimizeButton.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
end)

MinimizeButton.MouseLeave:Connect(function()
    MinimizeButton.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
end)

------------------------------------------------------------
-- UI Builders
------------------------------------------------------------

local layoutOrder = 0

local function NextOrder()
    layoutOrder = layoutOrder + 1
    return layoutOrder
end

local function CreateSection(text)
    local Label = Instance.new("TextLabel")
    Label.LayoutOrder = NextOrder()
    Label.Size = UDim2.new(1, 0, 0, 18)
    Label.BackgroundTransparency = 1
    Label.Text = string.upper(text)
    Label.TextColor3 = Color3.fromRGB(120, 120, 140)
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 11
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Content
end

local function CreateToggle(displayName, category, key)
    local Button = Instance.new("TextButton")
    Button.LayoutOrder = NextOrder()
    Button.Size = UDim2.new(1, 0, 0, 36)
    Button.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    Button.BorderSizePixel = 0
    Button.Text = ""
    Button.AutoButtonColor = false
    Button.Parent = Content

    local ButtonCorner = Instance.new("UICorner")
    ButtonCorner.CornerRadius = UDim.new(0, 9)
    ButtonCorner.Parent = Button

    local ButtonStroke = Instance.new("UIStroke")
    ButtonStroke.Color = Color3.fromRGB(43, 43, 56)
    ButtonStroke.Thickness = 1
    ButtonStroke.Parent = Button

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -70, 1, 0)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = displayName
    Label.TextColor3 = Color3.fromRGB(220, 220, 230)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Button

    local Switch = Instance.new("Frame")
    Switch.Size = UDim2.new(0, 34, 0, 18)
    Switch.Position = UDim2.new(1, -46, 0.5, -9)
    Switch.BorderSizePixel = 0
    Switch.BackgroundColor3 = Config[category][key]
        and Color3.fromRGB(70, 225, 110)
        or Color3.fromRGB(60, 60, 72)
    Switch.Parent = Button

    local SwitchCorner = Instance.new("UICorner")
    SwitchCorner.CornerRadius = UDim.new(1, 0)
    SwitchCorner.Parent = Switch

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.new(0, 12, 0, 12)
    Knob.BackgroundColor3 = Color3.fromRGB(250, 250, 255)
    Knob.BorderSizePixel = 0
    Knob.Position = Config[category][key]
        and UDim2.new(1, -15, 0.5, -6)
        or UDim2.new(0, 3, 0.5, -6)
    Knob.Parent = Switch

    local KnobCorner = Instance.new("UICorner")
    KnobCorner.CornerRadius = UDim.new(1, 0)
    KnobCorner.Parent = Knob

    local function Refresh()
        local enabled = Config[category][key]

        TweenService:Create(
            Switch,
            TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                BackgroundColor3 = enabled
                    and Color3.fromRGB(70, 225, 110)
                    or Color3.fromRGB(60, 60, 72)
            }
        ):Play()

        TweenService:Create(
            Knob,
            TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            {
                Position = enabled
                    and UDim2.new(1, -15, 0.5, -6)
                    or UDim2.new(0, 3, 0.5, -6)
            }
        ):Play()
    end

    Refresh()

    Button.MouseButton1Click:Connect(function()
        Config[category][key] = not Config[category][key]
        Refresh()
    end)

    Button.MouseEnter:Connect(function()
        Button.BackgroundColor3 = Color3.fromRGB(33, 33, 42)
    end)

    Button.MouseLeave:Connect(function()
        Button.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    end)
end

CreateSection("Silent Aim")
CreateToggle("Aimbot Enabled", "Aimbot", "Enabled")
CreateToggle("Silent Lock (No Camera Move)", "Aimbot", "SilentLock")
CreateToggle("Silent Ignore FOV", "Aimbot", "SilentIgnoreFOV")
CreateToggle("Keep Lock After Release", "Aimbot", "KeepLockAfterRelease")
CreateToggle("Retarget While Held", "Aimbot", "RetargetWhileHeld")
CreateToggle("Show Lock Indicator", "Aimbot", "ShowLockIndicator")
CreateToggle("Raycast Hook", "Aimbot", "SilentRaycastHook")
CreateToggle("Mouse Hook", "Aimbot", "SilentMouseHook")

CreateSection("Target Filters")
CreateToggle("Aim Players", "Aimbot", "IncludePlayers")
CreateToggle("Aim NPCs / Bots", "Aimbot", "IncludeNPCs")
CreateToggle("Aim Team Check", "Aimbot", "TeamCheck")
CreateToggle("Wall Check", "Aimbot", "WallCheck")
CreateToggle("Alive Check", "Aimbot", "AliveCheck")

CreateSection("Visuals")
CreateToggle("ESP", "ESP", "Enabled")
CreateToggle("ESP Players", "ESP", "IncludePlayers")
CreateToggle("ESP NPCs / Bots", "ESP", "IncludeNPCs")
CreateToggle("ESP Team Check", "ESP", "TeamCheck")

------------------------------------------------------------
-- Utility
------------------------------------------------------------

local function GetHumanoid(model)
    return model and model:IsA("Model") and model:FindFirstChildOfClass("Humanoid") or nil
end

local function GetRootPart(model)
    if not model or not model:IsA("Model") then return nil end

    return model:FindFirstChild("HumanoidRootPart")
        or model:FindFirstChild("Torso")
        or model:FindFirstChild("UpperTorso")
        or model.PrimaryPart
end

local function IsTrackedValid(model)
    if not model or not model.Parent then return false end
    return model:IsDescendantOf(Workspace)
end

local function IsAlive(model)
    local humanoid = GetHumanoid(model)
    if not humanoid then return false end

    if Config.Aimbot.AliveCheck and humanoid.Health <= 0 then
        return false
    end

    return true
end

local function GetModelHead(model)
    if not model or not IsTrackedValid(model) then return nil end
    if not IsAlive(model) then return nil end

    local part = model:FindFirstChild(Config.Aimbot.TargetPart)
    if part and part:IsA("BasePart") then
        return part
    end

    part = model:FindFirstChild("Head")
    if part and part:IsA("BasePart") then
        return part
    end

    return GetRootPart(model)
end

local function IsVisible(model, targetPart)
    if not Config.Aimbot.WallCheck then return true end
    if not targetPart or not Camera then return false end

    local origin = Camera.CFrame.Position
    local direction = targetPart.Position - origin

    if direction.Magnitude < 0.1 then
        return true
    end

    local filter = {}

    if LocalPlayer.Character then
        table.insert(filter, LocalPlayer.Character)
    end

    table.insert(filter, Camera)

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = filter

    local ok, result = pcall(function()
        return Workspace:Raycast(origin, direction, rayParams)
    end)

    if not ok then return true end
    if not result then return true end

    if result.Instance and result.Instance:IsDescendantOf(model) then
        return true
    end

    return false
end

local function ShouldTargetModel(model)
    if not IsTrackedValid(model) then return false end

    local player = Players:GetPlayerFromCharacter(model)
    if player == LocalPlayer then return false end

    if player and not Config.Aimbot.IncludePlayers then return false end
    if not player and not Config.Aimbot.IncludeNPCs then return false end

    if Config.Aimbot.TeamCheck
        and player
        and player.Team
        and LocalPlayer.Team
        and player.Team == LocalPlayer.Team then
        return false
    end

    if not IsAlive(model) then return false end

    return true
end

local function GetClosestTarget()
    if not Camera then return nil end

    local closestModel = nil
    local useFOV = not (Config.Aimbot.SilentLock and Config.Aimbot.SilentIgnoreFOV)
    local closestDistance = useFOV and Config.Aimbot.FOV or math.huge
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for model in pairs(TrackedModels) do
        if ShouldTargetModel(model) then
            local targetPart = GetModelHead(model)

            if targetPart then
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)

                if onScreen and screenPos.Z > 0 then
                    local metric

                    if useFOV then
                        metric = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                    else
                        metric = (targetPart.Position - Camera.CFrame.Position).Magnitude
                    end

                    if metric <= closestDistance then
                        if IsVisible(model, targetPart) then
                            closestDistance = metric
                            closestModel = model
                        end
                    end
                end
            end
        end
    end

    return closestModel
end

local function IsLockedTargetValid(model)
    if not model or not ShouldTargetModel(model) then return false end

    local head = GetModelHead(model)
    if not head then return false end

    if Config.Aimbot.WallCheck and not IsVisible(model, head) then
        return false
    end

    return true
end

local function GetLockedHead()
    return GetModelHead(LockedTarget)
end

local function UpdateLockedTarget()
    if not Config.Aimbot.Enabled then
        LockedTarget = nil
        return
    end

    if Config.Aimbot.SilentLock then
        if IsAiming then
            if Config.Aimbot.RetargetWhileHeld or not IsLockedTargetValid(LockedTarget) then
                LockedTarget = GetClosestTarget()
            end
        else
            if not Config.Aimbot.KeepLockAfterRelease or not IsLockedTargetValid(LockedTarget) then
                LockedTarget = nil
            end
        end
    else
        if IsAiming then
            LockedTarget = GetClosestTarget()
        else
            LockedTarget = nil
        end
    end
end

------------------------------------------------------------
-- Drawing helpers
------------------------------------------------------------

local function EnsureDraw(model)
    if not Drawings[model] then
        Drawings[model] = {
            Box = Drawing.new("Square"),
            Name = Drawing.new("Text"),
            Health = Drawing.new("Text")
        }
    end

    return Drawings[model]
end

local function HideDraw(model)
    local draw = Drawings[model]
    if not draw then return end

    draw.Box.Visible = false
    draw.Name.Visible = false
    draw.Health.Visible = false
end

local function CleanupDrawing(model)
    local draw = Drawings[model]
    if not draw then return end

    for _, object in pairs(draw) do
        pcall(function()
            object:Remove()
        end)
    end

    Drawings[model] = nil
end

local function GetESPColor(model)
    local player = Players:GetPlayerFromCharacter(model)

    if player then
        if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
            return Config.ESP.PlayerAllyColor
        end

        return Config.ESP.PlayerEnemyColor
    end

    return Config.ESP.NPCColor
end

local function GetDisplayName(model)
    local player = Players:GetPlayerFromCharacter(model)

    if player then
        return player.DisplayName or player.Name
    end

    return model.Name or "NPC"
end

local LockIndicator = nil

pcall(function()
    LockIndicator = Drawing.new("Circle")
    LockIndicator.NumSides = 24
    LockIndicator.Thickness = 1.5
    LockIndicator.Color = Color3.fromRGB(255, 220, 90)
    LockIndicator.Filled = false
    LockIndicator.Visible = false
end)

------------------------------------------------------------
-- Silent redirection hooks
------------------------------------------------------------

local oldWorkspaceRaycast = nil

local function IsLikelyWeaponRaycast(origin)
    if not origin then return false end

    if Camera and (origin - Camera.CFrame.Position).Magnitude < 25 then
        return true
    end

    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if root and (origin - root.Position).Magnitude < 8 then
        return true
    end

    return false
end

local function SilentRaycast(origin, direction, raycastParams)
    if Config.Aimbot.Enabled
        and Config.Aimbot.SilentLock
        and Config.Aimbot.SilentRaycastHook
        and IsLikelyWeaponRaycast(origin) then
        local head = GetLockedHead()

        if head then
            local silentDirection = head.Position - origin

            if silentDirection.Magnitude > 0.01 then
                local silentParams = RaycastParams.new()
                silentParams.FilterType = Enum.RaycastFilterType.Include
                silentParams.FilterDescendantsInstances = { head }
                silentParams.IgnoreWater = true

                if oldWorkspaceRaycast then
                    return oldWorkspaceRaycast(Workspace, origin, silentDirection, silentParams)
                end
            end
        end
    end

    if oldWorkspaceRaycast then
        return oldWorkspaceRaycast(Workspace, origin, direction, raycastParams)
    end

    return nil
end

pcall(function()
    if hookfunction then
        oldWorkspaceRaycast = hookfunction(Workspace.Raycast, function(a, b, c, d)
            if a == Workspace then
                return SilentRaycast(b, c, d)
            end

            return SilentRaycast(a, b, c)
        end)
    end
end)

pcall(function()
    if Config.Aimbot.SilentMouseHook and getrawmetatable and setreadonly then
        local mt = getrawmetatable(game)

        if mt then
            local oldIndex = mt.__index

            setreadonly(mt, false)

            mt.__index = function(self, key)
                if checkcaller and checkcaller() then
                    if oldIndex then
                        return oldIndex(self, key)
                    end
                    return nil
                end

                if self == Mouse
                    and Config.Aimbot.Enabled
                    and Config.Aimbot.SilentLock
                    and Config.Aimbot.SilentMouseHook then
                    local head = GetLockedHead()

                    if head then
                        if key == "Hit" or key == "hit" then
                            return head.CFrame
                        elseif key == "Target" or key == "target" then
                            return head
                        elseif key == "UnitRay" or key == "unitRay" then
                            return Ray.new(Camera.CFrame.Position, (head.Position - Camera.CFrame.Position).Unit)
                        end
                    end
                end

                if oldIndex then
                    return oldIndex(self, key)
                end

                return nil
            end

            setreadonly(mt, true)
        end
    end
end)

------------------------------------------------------------
-- Main loop
------------------------------------------------------------

RunService.RenderStepped:Connect(function()
    Camera = Workspace.CurrentCamera or Camera
    if not Camera then return end

    UpdateLockedTarget()

    -- Optional visible camera aim. If SilentLock is enabled, this stays off.
    if Config.Aimbot.Enabled and not Config.Aimbot.SilentLock and IsAiming and LockedTarget then
        local head = GetLockedHead()

        if head then
            local goalCFrame = CFrame.lookAt(Camera.CFrame.Position, head.Position)
            Camera.CFrame = Camera.CFrame:Lerp(goalCFrame, Config.Aimbot.Smoothness)
        end
    end

    -- Lock indicator
    if LockIndicator then
        if Config.Aimbot.Enabled and Config.Aimbot.ShowLockIndicator then
            local head = GetLockedHead()

            if head then
                local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)

                if onScreen and screenPos.Z > 0 then
                    local dist = (head.Position - Camera.CFrame.Position).Magnitude
                    local radius = math.clamp(900 / math.max(dist, 1), 8, 30)

                    LockIndicator.Visible = true
                    LockIndicator.Position = Vector2.new(screenPos.X, screenPos.Y)
                    LockIndicator.Radius = radius
                    LockIndicator.Color = Color3.fromRGB(255, 220, 90)
                else
                    LockIndicator.Visible = false
                end
            else
                LockIndicator.Visible = false
            end
        else
            LockIndicator.Visible = false
        end
    end

    -- ESP
    for model in pairs(TrackedModels) do
        if not IsTrackedValid(model) then
            TrackedModels[model] = nil
            CleanupDrawing(model)
        else
            local humanoid = GetHumanoid(model)
            local rootPart = GetRootPart(model)

            if humanoid and rootPart and humanoid.Health > 0 then
                local player = Players:GetPlayerFromCharacter(model)
                local show = Config.ESP.Enabled

                if player == LocalPlayer then
                    show = false
                end

                if player and not Config.ESP.IncludePlayers then
                    show = false
                end

                if not player and not Config.ESP.IncludeNPCs then
                    show = false
                end

                if Config.ESP.TeamCheck
                    and player
                    and player.Team
                    and LocalPlayer.Team
                    and player.Team == LocalPlayer.Team then
                    show = false
                end

                if show then
                    local draw = EnsureDraw(model)
                    local _, modelSize = model:GetBoundingBox()

                    if modelSize and modelSize.Y > 0 then
                        local topWorld = rootPart.Position + Vector3.new(0, modelSize.Y / 2, 0)
                        local bottomWorld = rootPart.Position - Vector3.new(0, modelSize.Y / 2, 0)

                        local topScreen = Camera:WorldToViewportPoint(topWorld)
                        local bottomScreen = Camera:WorldToViewportPoint(bottomWorld)

                        if topScreen.Z > 0 then
                            local height = math.abs(bottomScreen.Y - topScreen.Y)
                            if height < 2 then height = 20 end

                            local width = height * 0.55
                            local x = topScreen.X - width / 2
                            local y = topScreen.Y
                            local color = GetESPColor(model)

                            draw.Box.Visible = Config.ESP.DrawBox
                            draw.Box.Size = Vector2.new(width, height)
                            draw.Box.Position = Vector2.new(x, y)
                            draw.Box.Color = color
                            draw.Box.Thickness = 1
                            draw.Box.Filled = false

                            draw.Name.Visible = Config.ESP.DrawName
                            draw.Name.Text = GetDisplayName(model) .. (player and "" or " [NPC]")
                            draw.Name.Size = 13
                            draw.Name.Center = true
                            draw.Name.Color = Color3.fromRGB(240, 240, 240)
                            draw.Name.Position = Vector2.new(topScreen.X, topScreen.Y - 16)

                            draw.Health.Visible = Config.ESP.DrawHealth
                            draw.Health.Text = math.floor(humanoid.Health) .. " HP"
                            draw.Health.Size = 12
                            draw.Health.Center = true
                            draw.Health.Color = color
                            draw.Health.Position = Vector2.new(topScreen.X, topScreen.Y + height + 2)
                        else
                            HideDraw(model)
                        end
                    else
                        HideDraw(model)
                    end
                else
                    HideDraw(model)
                end
            else
                HideDraw(model)
            end
        end
    end
end)

------------------------------------------------------------
-- Tracking
------------------------------------------------------------

local function TrackModel(model)
    if not model or not model:IsA("Model") then return end
    if TrackedModels[model] then return end

    TrackedModels[model] = true

    model.Destroying:Connect(function()
        TrackedModels[model] = nil
        CleanupDrawing(model)
    end)
end

Workspace.DescendantAdded:Connect(function(object)
    if object:IsA("Humanoid") then
        local model = object.Parent

        if model and model:IsA("Model") then
            TrackModel(model)
        end
    end
end)

task.spawn(function()
    for _, object in ipairs(Workspace:GetDescendants()) do
        if object:IsA("Humanoid") and object.Parent and object.Parent:IsA("Model") then
            TrackModel(object.Parent)
        end
    end
end)

local function BindPlayer(player)
    if player.Character then
        TrackModel(player.Character)
    end

    player.CharacterAdded:Connect(function(character)
        TrackModel(character)
    end)
end

for _, player in ipairs(Players:GetPlayers()) do
    BindPlayer(player)
end

Players.PlayerAdded:Connect(BindPlayer)

Players.PlayerRemoving:Connect(function(player)
    if player.Character then
        CleanupDrawing(player.Character)
    end
end)

------------------------------------------------------------
-- Input
------------------------------------------------------------

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.UserInputType == Config.Aimbot.ActivationKey then
        IsAiming = true
    end

    if input.KeyCode == Config.UI.ToggleKey and not gameProcessed then
        ScreenGui.Enabled = not ScreenGui.Enabled
        dragging = false
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Config.Aimbot.ActivationKey then
        IsAiming = false
    end
end)

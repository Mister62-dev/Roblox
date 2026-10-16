-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

if _G.PhantomRobloxNPCSuite then return end
_G.PhantomRobloxNPCSuite = true

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

-- Configuration
local Config = {
    Aimbot = {
        Enabled = false,
        IncludePlayers = true,
        IncludeNPCs = true,
        TeamCheck = true,
        WallCheck = true,
        AliveCheck = true,
        FOV = 160,
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

-- UI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PhantomNPCSuite"
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

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 240, 0, 320)
MainFrame.Position = UDim2.new(0.5, -120, 0.5, -160)
MainFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 27)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 32)
TopBar.BackgroundColor3 = Color3.fromRGB(255, 60, 100)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 10)
TopCorner.Parent = TopBar

local TopFix = Instance.new("Frame")
TopFix.Size = UDim2.new(1, 0, 0, 12)
TopFix.Position = UDim2.new(0, 0, 1, -12)
TopFix.BackgroundColor3 = TopBar.BackgroundColor3
TopFix.BorderSizePixel = 0
TopFix.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -20, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "PHANTOM v1099 // NPC SUITE"
Title.TextColor3 = Color3.fromRGB(245, 245, 245)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local ToggleContainer = Instance.new("ScrollingFrame")
ToggleContainer.Size = UDim2.new(1, -20, 1, -44)
ToggleContainer.Position = UDim2.new(0, 10, 0, 38)
ToggleContainer.BackgroundTransparency = 1
ToggleContainer.BorderSizePixel = 0
ToggleContainer.ScrollBarThickness = 3
ToggleContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
ToggleContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
ToggleContainer.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 6)
UIListLayout.Parent = ToggleContainer

local toggleOrder = 0
local function CreateToggle(displayName, category, key)
    toggleOrder = toggleOrder + 1

    local Button = Instance.new("TextButton")
    Button.LayoutOrder = toggleOrder
    Button.Size = UDim2.new(1, 0, 0, 30)
    Button.BackgroundColor3 = Color3.fromRGB(34, 34, 41)
    Button.BorderSizePixel = 0
    Button.Text = ""
    Button.AutoButtonColor = false
    Button.Parent = ToggleContainer

    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 7)
    BtnCorner.Parent = Button

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -44, 1, 0)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = displayName
    Label.TextColor3 = Color3.fromRGB(210, 210, 215)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Button

    local Indicator = Instance.new("Frame")
    Indicator.Size = UDim2.new(0, 16, 0, 16)
    Indicator.Position = UDim2.new(1, -26, 0.5, -8)
    Indicator.BorderSizePixel = 0
    Indicator.Parent = Button

    local IndCorner = Instance.new("UICorner")
    IndCorner.CornerRadius = UDim.new(1, 0)
    IndCorner.Parent = Indicator

    local function Refresh()
        Indicator.BackgroundColor3 = Config[category][key]
            and Color3.fromRGB(70, 225, 110)
            or Color3.fromRGB(220, 60, 60)
    end

    Refresh()

    Button.MouseButton1Click:Connect(function()
        Config[category][key] = not Config[category][key]
        Refresh()
    end)
end

CreateToggle("Aimbot (Hold RMB)", "Aimbot", "Enabled")
CreateToggle("ESP Visuals", "ESP", "Enabled")
CreateToggle("Aim Players", "Aimbot", "IncludePlayers")
CreateToggle("Aim NPCs / Bots", "Aimbot", "IncludeNPCs")
CreateToggle("ESP Players", "ESP", "IncludePlayers")
CreateToggle("ESP NPCs / Bots", "ESP", "IncludeNPCs")
CreateToggle("Aim Team Check", "Aimbot", "TeamCheck")
CreateToggle("ESP Team Check", "ESP", "TeamCheck")
CreateToggle("Wall Check", "Aimbot", "WallCheck")
CreateToggle("Alive Check", "Aimbot", "AliveCheck")

-- Utility
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

local function GetHead(model)
    if not model then return nil end
    return model:FindFirstChild("Head") or GetRootPart(model)
end

local function GetTargetPart(model)
    local part = model:FindFirstChild(Config.Aimbot.TargetPart)
    if part and part:IsA("BasePart") then
        return part
    end
    return GetHead(model) or GetRootPart(model)
end

local function IsTrackedValid(model)
    if not model or not model.Parent then return false end
    return model:IsDescendantOf(Workspace)
end

local function IsAlive(model)
    local humanoid = GetHumanoid(model)
    if not humanoid then return false end
    if Config.Aimbot.AliveCheck and humanoid.Health <= 0 then return false end
    return true
end

local function IsVisible(model, targetPart)
    if not Config.Aimbot.WallCheck then return true end
    if not targetPart or not Camera then return false end

    local origin = Camera.CFrame.Position
    local direction = targetPart.Position - origin
    if direction.Magnitude < 0.1 then return true end

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
    local closestDistance = Config.Aimbot.FOV
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for model in pairs(TrackedModels) do
        if ShouldTargetModel(model) then
            local targetPart = GetTargetPart(model)
            if targetPart then
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen and screenPos.Z > 0 then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                    if dist <= closestDistance then
                        if IsVisible(model, targetPart) then
                            closestDistance = dist
                            closestModel = model
                        end
                    end
                end
            end
        end
    end

    return closestModel
end

-- Drawing helpers
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

-- Main loop
RunService.RenderStepped:Connect(function()
    Camera = Workspace.CurrentCamera or Camera
    if not Camera then return end

    -- Aimbot
    if Config.Aimbot.Enabled and IsAiming then
        local target = GetClosestTarget()
        if target then
            local targetPart = GetTargetPart(target)
            if targetPart then
                local goalCFrame = CFrame.lookAt(Camera.CFrame.Position, targetPart.Position)
                Camera.CFrame = Camera.CFrame:Lerp(goalCFrame, Config.Aimbot.Smoothness)
            end
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

-- Tracking
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

-- Input
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.UserInputType == Config.Aimbot.ActivationKey then
        IsAiming = true
    end

    if input.KeyCode == Config.UI.ToggleKey and not gameProcessed then
        ScreenGui.Enabled = not ScreenGui.Enabled
    end
end)

UserInputService.InputEnded:Connect(function(input, _)
    if input.UserInputType == Config.Aimbot.ActivationKey then
        IsAiming = false
    end
end)

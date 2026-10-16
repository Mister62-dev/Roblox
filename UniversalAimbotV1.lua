-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

-- Local Setup
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- Configuration
local Config = {
    Aimbot = {
        Enabled = false,
        TeamCheck = true,
        WallCheck = true,
        AliveCheck = true,
        FOV = 150,
        Smoothness = 0.15,
        TargetPart = "Head",
        ActivationKey = Enum.UserInputType.MouseButton2
    },
    ESP = {
        Enabled = false,
        TeamCheck = true,
        DrawBox = true,
        DrawName = true,
        DrawHealth = true
    },
    UI = {
        Visible = true,
        ToggleKey = Enum.KeyCode.Insert
    }
}

local DrawingObjects = {}
local IsAiming = false

-- UI Construction (Pure Roblox Instances, no external libs)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PhantomUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game.CoreGui

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 220, 0, 280)
MainFrame.Position = UDim2.new(0.5, -110, 0.5, -140)
MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 30)
TopBar.BackgroundColor3 = Color3.fromRGB(255, 60, 100)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 8)
TopCorner.Parent = TopBar
-- Fix bottom corners of top bar
local TopFix = Instance.new("Frame")
TopFix.Size = UDim2.new(1, 0, 0, 10)
TopFix.Position = UDim2.new(0, 0, 1, -10)
TopFix.BackgroundColor3 = TopBar.BackgroundColor3
TopFix.BorderSizePixel = 0
TopFix.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -10, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "PHANTOM v1099"
Title.TextColor3 = Color3.fromRGB(240, 240, 240)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local ToggleContainer = Instance.new("Frame")
ToggleContainer.Size = UDim2.new(1, -20, 1, -40)
ToggleContainer.Position = UDim2.new(0, 10, 0, 35)
ToggleContainer.BackgroundTransparency = 1
ToggleContainer.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 8)
UIListLayout.Parent = ToggleContainer

local function CreateToggle(name, configRef)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, 0, 0, 30)
    Button.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    Button.BorderSizePixel = 0
    Button.Text = ""
    Button.Parent = ToggleContainer
    
    local BtnCorner = Instance.new("UICorner")
    BtnCorner.CornerRadius = UDim.new(0, 6)
    BtnCorner.Parent = Button
    
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -40, 1, 0)
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.TextColor3 = Color3.fromRGB(200, 200, 200)
    Label.Font = Enum.Font.Gotham
    Label.TextSize = 13
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Button
    
    local Indicator = Instance.new("Frame")
    Indicator.Size = UDim2.new(0, 16, 0, 16)
    Indicator.Position = UDim2.new(1, -26, 0.5, -8)
    Indicator.BackgroundColor3 = Config[configRef].Enabled and Color3.fromRGB(60, 220, 100) or Color3.fromRGB(200, 50, 50)
    Indicator.BorderSizePixel = 0
    Indicator.Parent = Button
    
    local IndCorner = Instance.new("UICorner")
    IndCorner.CornerRadius = UDim.new(1, 0)
    IndCorner.Parent = Indicator
    
    Button.MouseButton1Click:Connect(function()
        Config[configRef].Enabled = not Config[configRef].Enabled
        Indicator.BackgroundColor3 = Config[configRef].Enabled and Color3.fromRGB(60, 220, 100) or Color3.fromRGB(200, 50, 50)
    end)
end

CreateToggle("Aimbot (Hold RMB)", "Aimbot")
CreateToggle("ESP Visuals", "ESP")
CreateToggle("Wall Check", "Aimbot") -- Tied to aimbot config for simplicity
CreateToggle("Team Check", "Aimbot")

-- Utility Functions
local function IsValidTarget(target)
    if not target or target == LocalPlayer then return false end
    if not target.Character then return false end
    
    local humanoid = target.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end
    
    if Config.Aimbot.AliveCheck and humanoid.Health <= 0 then return false end
    
    if Config.Aimbot.TeamCheck and target.Team == LocalPlayer.Team then return false end
    
    if Config.Aimbot.WallCheck then
        local targetPart = target.Character:FindFirstChild(Config.Aimbot.TargetPart) or target.Character:FindFirstChild("HumanoidRootPart")
        if not targetPart then return false end
        
        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        rayParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
        
        local direction = (targetPart.Position - Camera.CFrame.Position)
        local result = Workspace:Raycast(Camera.CFrame.Position, direction, rayParams)
        
        if result then
            local hitModel = result.Instance:FindFirstAncestorOfClass("Model")
            if hitModel ~= target.Character then
                return false
            end
        end
    end
    
    return true
end

local function GetClosestTarget()
    local closest = nil
    local minDist = Config.Aimbot.FOV
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    for _, player in ipairs(Players:GetPlayers()) do
        if IsValidTarget(player) then
            local targetPart = player.Character:FindFirstChild(Config.Aimbot.TargetPart) or player.Character:FindFirstChild("HumanoidRootPart")
            if targetPart then
                local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
                    if dist < minDist then
                        minDist = dist
                        closest = player
                    end
                end
            end
        end
    end
    return closest
end

-- Input Handling
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Config.Aimbot.ActivationKey then
        IsAiming = true
    end
    if input.KeyCode == Config.UI.ToggleKey then
        ScreenGui.Enabled = not ScreenGui.Enabled
    end
end)

UserInputService.InputEnded:Connect(function(input, processed)
    if input.UserInputType == Config.Aimbot.ActivationKey then
        IsAiming = false
    end
end)

-- Main Execution Loop
RunService.RenderStepped:Connect(function()
    -- Aimbot Logic
    if Config.Aimbot.Enabled and IsAiming then
        local target = GetClosestTarget()
        if target then
            local targetPart = target.Character:FindFirstChild(Config.Aimbot.TargetPart) or target.Character:FindFirstChild("HumanoidRootPart")
            if targetPart then
                local goalCFrame = CFrame.lookAt(Camera.CFrame.Position, targetPart.Position)
                Camera.CFrame = Camera.CFrame:Lerp(goalCFrame, Config.Aimbot.Smoothness)
            end
        end
    end

    -- ESP Logic
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
            local head = player.Character:FindFirstChild("Head")
            
            if humanoid and rootPart and head and humanoid.Health > 0 then
                local isAlly = player.Team == LocalPlayer.Team
                if not Config.ESP.TeamCheck or not isAlly then
                    if not DrawingObjects[player.UserId] then
                        DrawingObjects[player.UserId] = {
                            Box = Drawing.new("Square"),
                            Name = Drawing.new("Text"),
                            Health = Drawing.new("Text")
                        }
                    end
                    
                    local draw = DrawingObjects[player.UserId]
                    local screenPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
                    
                    if onScreen and Config.ESP.Enabled then
                        local scale = (head.Position - Camera.CFrame.Position).Magnitude
                        local boxHeight = 1500 / scale
                        local boxWidth = boxHeight / 2
                        
                        local color = isAlly and Color3.fromRGB(80, 200, 255) or Color3.fromRGB(255, 80, 80)
                        
                        draw.Box.Visible = Config.ESP.DrawBox
                        draw.Box.Size = Vector2.new(boxWidth, boxHeight)
                        draw.Box.Position = Vector2.new(screenPos.X - boxWidth/2, screenPos.Y - boxHeight/2)
                        draw.Box.Color = color
                        draw.Box.Thickness = 1
                        
                        draw.Name.Visible = Config.ESP.DrawName
                        draw.Name.Text = player.Name
                        draw.Name.Size = 14
                        draw.Name.Center = true
                        draw.Name.Color = Color3.fromRGB(240, 240, 240)
                        draw.Name.Position = Vector2.new(screenPos.X, screenPos.Y - boxHeight/2 - 15)
                        
                        draw.Health.Visible = Config.ESP.DrawHealth
                        draw.Health.Text = math.floor(humanoid.Health) .. " HP"
                        draw.Health.Size = 12
                        draw.Health.Center = true
                        draw.Health.Color = color
                        draw.Health.Position = Vector2.new(screenPos.X, screenPos.Y + boxHeight/2 + 5)
                    else
                        draw.Box.Visible = false
                        draw.Name.Visible = false
                        draw.Health.Visible = false
                    end
                end
            end
        end
    end
end)

-- Cleanup on player leaving
Players.PlayerRemoving:Connect(function(player)
    if DrawingObjects[player.UserId] then
        for _, obj in pairs(DrawingObjects[player.UserId]) do
            obj:Remove()
        end
        DrawingObjects[player.UserId] = nil
    end
end)

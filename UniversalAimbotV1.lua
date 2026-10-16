-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

-- Local Player & Camera
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- Configuration
local Settings = {
    AimbotEnabled = true,
    ESPEnabled = true,
    TeamCheck = true,
    WallCheck = true,
    AliveCheck = true,
    FOV = 100,
    AimKey = Enum.UserInputType.MouseButton2, -- Right click to aim
    Smoothness = 0.5
}

-- Drawing Objects
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1
FOVCircle.Color = Color3.fromRGB(255, 255, 255)
FOVCircle.Filled = false
FOVCircle.NumSides = 50
FOVCircle.Transparency = 1
FOVCircle.Visible = false

local ESPObjects = {}

-- Helper Functions
local function isBot(player)
    -- Simple heuristic to detect bots based on common naming conventions
    -- Adjust this if the specific game uses different bot tags
    return string.match(player.Name, "Bot") or 
           string.match(player.DisplayName, "Bot") or 
           (player.Character and player.Character:FindFirstChild("IsBot"))
end

local function getClosestPlayer()
    local closest = nil
    local shortestDistance = Settings.FOV

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local character = player.Character
            local head = character:FindFirstChild("Head")
            local humanoid = character:FindFirstChild("Humanoid")

            if head and humanoid then
                local alive = humanoid.Health > 0
                local teamPass = (not Settings.TeamCheck) or (player.Team ~= LocalPlayer.Team)
                
                if alive and teamPass then
                    local headPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                    if onScreen then
                        local mousePos = Vector2.new(Mouse.X, Mouse.Y)
                        local headPos2D = Vector2.new(headPos.X, headPos.Y)
                        local distance = (mousePos - headPos2D).Magnitude

                        if distance < shortestDistance then
                            -- Wall Check
                            local wallPass = true
                            if Settings.WallCheck then
                                local rayOrigin = Camera.CFrame.Position
                                local rayDirection = (head.Position - rayOrigin).Unit * (head.Position - rayOrigin).Magnitude
                                local raycastParams = RaycastParams.new()
                                raycastParams.FilterType = Enum.RaycastFilterType.Exclude
                                raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
                                
                                local result = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
                                if result and result.Instance:FindFirstAncestorOfClass("Model") == character then
                                    wallPass = true
                                elseif result then
                                    wallPass = false
                                end
                            end

                            if wallPass then
                                shortestDistance = distance
                                closest = player
                            end
                        end
                    end
                end
            end
        end
    end
    return closest
end

local function updateESP(player, isBot)
    if not ESPObjects[player] then
        ESPObjects[player] = {
            Box = Drawing.new("Square"),
            Name = Drawing.new("Text"),
            Health = Drawing.new("Text")
        }
    end

    local esp = ESPObjects[player]
    local character = player.Character
    local head = character and character:FindFirstChild("Head")
    local humanoid = character and character:FindFirstChild("Humanoid")
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")

    if character and head and humanoid and rootPart and humanoid.Health > 0 then
        local pos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
        local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 3, 0))
        local footPos = Camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 3, 0))

        if onScreen then
            local height = math.abs(headPos.Y - footPos.Y)
            local width = height * 0.6

            -- Box
            esp.Box.Size = Vector2.new(width, height)
            esp.Box.Position = Vector2.new(pos.X - width/2, pos.Y - height/2)
            esp.Box.Thickness = 1
            esp.Box.Color = isBot and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(255, 255, 255)
            esp.Box.Filled = false
            esp.Box.Visible = Settings.ESPEnabled

            -- Name
            esp.Name.Text = isBot and "[BOT] " .. player.Name or player.Name
            esp.Name.Size = 14
            esp.Name.Center = true
            esp.Name.Outline = true
            esp.Name.Position = Vector2.new(pos.X, pos.Y - height/2 - 15)
            esp.Name.Color = isBot and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 255, 255)
            esp.Name.Visible = Settings.ESPEnabled

            -- Health
            esp.Health.Text = math.floor(humanoid.Health) .. " HP"
            esp.Health.Size = 12
            esp.Health.Center = true
            esp.Health.Outline = true
            esp.Health.Position = Vector2.new(pos.X, pos.Y + height/2 + 5)
            esp.Health.Color = Color3.fromRGB(0, 255, 0)
            esp.Health.Visible = Settings.ESPEnabled
        else
            esp.Box.Visible = false
            esp.Name.Visible = false
            esp.Health.Visible = false
        end
    else
        esp.Box.Visible = false
        esp.Name.Visible = false
        esp.Health.Visible = false
    end
end

local function clearESP(player)
    if ESPObjects[player] then
        ESPObjects[player].Box:Remove()
        ESPObjects[player].Name:Remove()
        ESPObjects[player].Health:Remove()
        ESPObjects[player] = nil
    end
end

-- UI Creation (Draggable Menu)
local ScreenGui = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local UICorner = Instance.new("UICorner")
local UIStroke = Instance.new("UIStroke")
local Title = Instance.new("TextLabel")

ScreenGui.Name = "UniversalCheatUI"
ScreenGui.Parent = game.CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

Frame.Parent = ScreenGui
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.BorderSizePixel = 0
Frame.Position = UDim2.new(0.5, -100, 0.5, -75)
Frame.Size = UDim2.new(0, 200, 0, 150)
Frame.Active = true
Frame.Draggable = true

UICorner.CornerRadius = UDim.new(0, 6)
UICorner.Parent = Frame

UIStroke.Color = Color3.fromRGB(60, 60, 60)
UIStroke.Parent = Frame

Title.Parent = Frame
Title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Title.BorderSizePixel = 0
Title.Size = UDim2.new(1, 0, 0, 25)
Title.Font = Enum.Font.GothamSemibold
Title.Text = "Universal Aimbot & ESP"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 14.000

local function createToggle(text, yPos, callback)
    local btn = Instance.new("TextButton")
    btn.Parent = Frame
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    btn.BorderSizePixel = 0
    btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.Size = UDim2.new(1, -20, 0, 25)
    btn.Font = Enum.Font.Gotham
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(200, 200, 200)
    btn.TextSize = 12.000
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        callback()
    end)
    
    return btn
end

local AimbotBtn = createToggle("Aimbot: ON", 35, function()
    Settings.AimbotEnabled = not Settings.AimbotEnabled
    AimbotBtn.Text = "Aimbot: " .. (Settings.AimbotEnabled and "ON" or "OFF")
end)

local ESPBtn = createToggle("ESP: ON", 65, function()
    Settings.ESPEnabled = not Settings.ESPEnabled
    ESPBtn.Text = "ESP: " .. (Settings.ESPEnabled and "ON" or "OFF")
end)

local WallCheckBtn = createToggle("Wall Check: ON", 95, function()
    Settings.WallCheck = not Settings.WallCheck
    WallCheckBtn.Text = "Wall Check: " .. (Settings.WallCheck and "ON" or "OFF")
end)

-- Main Loops
RunService.RenderStepped:Connect(function()
    -- FOV Circle Update
    if Settings.AimbotEnabled then
        FOVCircle.Position = Vector2.new(Mouse.X, Mouse.Y)
        FOVCircle.Radius = Settings.FOV
        FOVCircle.Visible = true
    else
        FOVCircle.Visible = false
    end

    -- Aimbot Logic
    if Settings.AimbotEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = getClosestPlayer()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            local head = target.Character.Head
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, head.Position), Settings.Smoothness)
        end
    end
end)

RunService.Heartbeat:Connect(function()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            updateESP(player, isBot(player))
        end
    end
end)

-- Cleanup on player removal
Players.PlayerRemoving:Connect(function(player)
    clearESP(player)
end)

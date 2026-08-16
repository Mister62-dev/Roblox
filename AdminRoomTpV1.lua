local Players = game:GetService("Players")
local player = Players.LocalPlayer

local function teleport()
    local character = player.Character or player.CharacterAdded:Wait()
    local rootPart = character:WaitForChild("HumanoidRootPart")

    local adminRoom = workspace:FindFirstChild("System")
    if not adminRoom then warn("System introuvable") return end
    adminRoom = adminRoom:FindFirstChild("admin room")
    if not adminRoom then warn("admin room introuvable") return end

    local part = adminRoom:FindFirstChildWhichIsA("BasePart", true)
    if part then
        rootPart.CFrame = part.CFrame + Vector3.new(0, 5, 0)
        warn("Teleporte!")
    else
        warn("Aucune BasePart dans admin room")
    end
end

-- UI
local gui = Instance.new("ScreenGui")
gui.Name = "TeleportUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.Parent = player.PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 180, 0, 90)
frame.Position = UDim2.new(0, 20, 0, 20)
frame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

local stroke = Instance.new("UIStroke", frame)
stroke.Color = Color3.fromRGB(60, 60, 80)
stroke.Thickness = 1

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 32)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
titleBar.BorderSizePixel = 0
titleBar.Parent = frame
Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)

local titleFix = Instance.new("Frame")
titleFix.Size = UDim2.new(1, 0, 0.5, 0)
titleFix.Position = UDim2.new(0, 0, 0.5, 0)
titleFix.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
titleFix.BorderSizePixel = 0
titleFix.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -10, 1, 0)
titleLabel.Position = UDim2.new(0, 10, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Teleport"
titleLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
titleLabel.TextSize = 13
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 20)
statusLabel.Position = UDim2.new(0, 10, 0, 36)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Pret"
statusLabel.TextColor3 = Color3.fromRGB(140, 140, 160)
statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = frame

local tpBtn = Instance.new("TextButton")
tpBtn.Size = UDim2.new(1, -20, 0, 28)
tpBtn.Position = UDim2.new(0, 10, 0, 56)
tpBtn.BackgroundColor3 = Color3.fromRGB(80, 100, 200)
tpBtn.BorderSizePixel = 0
tpBtn.Text = "Admin Room"
tpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
tpBtn.TextSize = 12
tpBtn.Font = Enum.Font.GothamBold
tpBtn.Parent = frame
Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 6)

tpBtn.MouseButton1Click:Connect(function()
    statusLabel.Text = "Teleportation..."
    statusLabel.TextColor3 = Color3.fromRGB(180, 180, 100)
    pcall(function()
        teleport()
        statusLabel.Text = "Arrive!"
        statusLabel.TextColor3 = Color3.fromRGB(100, 220, 130)
    end)
    task.wait(2)
    statusLabel.Text = "Pret"
    statusLabel.TextColor3 = Color3.fromRGB(140, 140, 160)
end)

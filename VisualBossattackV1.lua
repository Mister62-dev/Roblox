local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Collecte toutes les remotes d'attaque
local remotes = {}
for _, v in ipairs(RS:GetDescendants()) do
    if v:IsA("RemoteEvent") then
        local name = v.Name:lower()
        if name:find("remote") or name:find("shoot") or name:find("blaster") then
            table.insert(remotes, v)
        end
    end
end

-- UI
local gui = Instance.new("ScreenGui")
gui.Name = "AttackUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.Parent = player.PlayerGui

local bg = Instance.new("Frame")
bg.Size = UDim2.new(0, 260, 0.7, 0)
bg.Position = UDim2.new(0, 10, 0.15, 0)
bg.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
bg.BorderSizePixel = 0
bg.Active = true
bg.Draggable = true
bg.Parent = gui
Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
title.BackgroundTransparency = 0
title.Text = "Attaques (" .. #remotes .. ")"
title.TextColor3 = Color3.fromRGB(200, 200, 220)
title.TextSize = 13
title.Font = Enum.Font.GothamBold
title.BorderSizePixel = 0
title.Parent = bg
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 10)

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -10, 0, 20)
statusLabel.Position = UDim2.new(0, 5, 0, 38)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Clique pour fire"
statusLabel.TextColor3 = Color3.fromRGB(140, 140, 160)
statusLabel.TextSize = 10
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = bg

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -10, 1, -65)
scroll.Position = UDim2.new(0, 5, 0, 60)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 100)
scroll.Parent = bg

local layout = Instance.new("UIListLayout", scroll)
layout.Padding = UDim.new(0, 4)
layout.SortOrder = Enum.SortOrder.LayoutOrder

-- Crée un bouton par remote
for i, remote in ipairs(remotes) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -8, 0, 40)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    btn.BorderSizePixel = 0
    btn.TextColor3 = Color3.fromRGB(200, 200, 220)
    btn.TextSize = 9
    btn.Font = Enum.Font.Gotham
    btn.TextWrapped = true
    btn.Text = remote.Name .. "\n" .. remote.Parent.Name
    btn.LayoutOrder = i
    btn.Parent = scroll
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    btn.MouseButton1Click:Connect(function()
        local character = player.Character
        if not character then return end
        local rootPart = character:FindFirstChild("HumanoidRootPart")

        btn.BackgroundColor3 = Color3.fromRGB(60, 180, 100)
        statusLabel.Text = "Fire: " .. remote.Name

        pcall(function() remote:FireServer() end)
        pcall(function() remote:FireServer(rootPart and rootPart.CFrame, rootPart and rootPart.Position) end)

        task.wait(0.5)
        btn.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    end)
end

-- Ajuste la canvas size
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
end)
scroll.CanvasSize = UDim2.new(0, 0, 0, #remotes * 44)

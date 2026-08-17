local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

local function getTarget()
    -- Cible le joueur le plus proche
    local char = player.Character
    if not char then return Vector3.new(0,0,0) end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return Vector3.new(0,0,0) end
    
    local closest, dist = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player and p.Character then
            local r = p.Character:FindFirstChild("HumanoidRootPart")
            if r then
                local d = (r.Position - root.Position).Magnitude
                if d < dist then
                    closest = r.Position
                    dist = d
                end
            end
        end
    end
    return closest or root.Position
end

-- Trouve les remotes du perso local
local function getCharRemotes()
    local result = {}
    local charModel = Workspace:FindFirstChild("player in") -- nom du model
    if not charModel then
        -- cherche par nom du joueur
        for _, v in ipairs(Workspace:GetDescendants()) do
            if v.Name == player.Name then
                charModel = v.Parent
                break
            end
        end
    end
    if charModel then
        for _, v in ipairs(charModel:GetDescendants()) do
            if v:IsA("RemoteEvent") then
                table.insert(result, v)
            end
        end
    end
    return result
end

-- UI
local gui = Instance.new("ScreenGui")
gui.Name = "AttackUI2"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.Parent = player.PlayerGui

local bg = Instance.new("Frame")
bg.Size = UDim2.new(0, 260, 0.75, 0)
bg.Position = UDim2.new(0, 10, 0.12, 0)
bg.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
bg.BorderSizePixel = 0
bg.Active = true
bg.Draggable = true
bg.Parent = gui
Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
title.Text = "Attaques"
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
statusLabel.Text = "Pret"
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
scroll.Parent = bg

local layout = Instance.new("UIListLayout", scroll)
layout.Padding = UDim.new(0, 4)

-- Attaques hardcodées avec bons paramètres
local attacks = {
    {
        name = "Bone Throw",
        remotePath = "Bone Throw",
        fire = function(remote)
            local pos = getTarget()
            remote:FireServer(pos)
        end
    },
    {
        name = "Gaster Blasters",
        remotePath = "Gaster Blasters",
        fire = function(remote)
            local pos = getTarget()
            remote:FireServer(pos)
        end
    },
    {
        name = "Determination",
        remotePath = "Determination",
        fire = function(remote)
            local pos = getTarget()
            remote:FireServer(pos.X, pos.Y, pos.Z)
        end
    }
}

-- Trouve chaque remote dans Workspace
for _, attack in ipairs(attacks) do
    local remote = nil
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("RemoteEvent") and v.Name == attack.remotePath then
            remote = v
            break
        end
    end

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -8, 0, 45)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    btn.BorderSizePixel = 0
    btn.TextColor3 = Color3.fromRGB(200, 200, 220)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.Text = attack.name .. (remote and "" or " ❌")
    btn.Parent = scroll
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

    if remote then
        btn.MouseButton1Click:Connect(function()
            btn.BackgroundColor3 = Color3.fromRGB(60, 180, 100)
            statusLabel.Text = "Fire: " .. attack.name
            pcall(function() attack.fire(remote) end)
            task.wait(0.5)
            btn.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
            statusLabel.Text = "Pret"
        end)
    else
        btn.BackgroundColor3 = Color3.fromRGB(60, 30, 30)
    end
end

layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scroll.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
end)

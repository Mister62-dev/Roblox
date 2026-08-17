local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

local function getTarget()
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
                if d < dist then closest = r.Position; dist = d end
            end
        end
    end
    return closest or root.Position
end

-- Cherche les remotes dans "player in"
local function findRemote(name)
    local playerIn = Workspace:FindFirstChild("player in")
    if not playerIn then warn("player in introuvable") return nil end
    local playerFolder = playerIn:FindFirstChild(player.Name)
    if not playerFolder then warn(player.Name .. " introuvable") return nil end
    for _, v in ipairs(playerFolder:GetDescendants()) do
        if v:IsA("RemoteEvent") and (v.Name == name or v.Parent.Name == name) then
            return v
        end
    end
    return nil
end

local attacks = {
    {name = "Bone Throw", remote = "ShootBlaster", parent = "Bone Throw",
     fire = function(r) r:FireServer(getTarget()) end},
    {name = "Gaster Blasters", remote = "ShootBlaster", parent = "Gaster Blasters",
     fire = function(r) r:FireServer(getTarget()) end},
    {name = "Determination", remote = "RemoteEvent", parent = "Determination",
     fire = function(r) local p = getTarget() r:FireServer(p.X, p.Y, p.Z) end},
}

-- UI
local gui = Instance.new("ScreenGui")
gui.Name = "AttackUI3"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.Parent = player.PlayerGui

local bg = Instance.new("Frame")
bg.Size = UDim2.new(0, 260, 0, 220)
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

local yPos = 62
for _, attack in ipairs(attacks) do
    -- Trouve la remote via parent + nom
    local remote = nil
    local playerIn = Workspace:FindFirstChild("player in")
    if playerIn then
        local playerFolder = playerIn:FindFirstChild(player.Name)
        if playerFolder then
            for _, v in ipairs(playerFolder:GetDescendants()) do
                if v:IsA("RemoteEvent") and v.Name == attack.remote 
                   and v.Parent.Name == attack.parent then
                    remote = v
                    break
                end
            end
        end
    end

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 45)
    btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.BackgroundColor3 = remote and Color3.fromRGB(35, 35, 50) or Color3.fromRGB(60, 30, 30)
    btn.BorderSizePixel = 0
    btn.TextColor3 = Color3.fromRGB(200, 200, 220)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.Text = attack.name .. (remote and "" or " ❌")
    btn.Parent = bg
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
    end
    yPos = yPos + 50
end

bg.Size = UDim2.new(0, 260, 0, yPos + 10)

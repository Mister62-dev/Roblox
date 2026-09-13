-- Grow Your Aura | Auto Click V3 | Fire ALL + Touch
-- Delta Executor | Août 2026

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local UIS               = game:GetService("UserInputService")
local VIM               = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer       = Players.LocalPlayer
local PlayerGui         = LocalPlayer:WaitForChild("PlayerGui")

if PlayerGui:FindFirstChild("AutoClickUI") then
    PlayerGui:FindFirstChild("AutoClickUI"):Destroy()
end

local clicking   = false
local clickCount = 0
local DELAY      = 0.05

-- ── CACHE TOUS LES REMOTES SANS FILTRE ───────────────────────────────────────
local allRemotes = {}

local function cacheAllRemotes()
    allRemotes = {}
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            table.insert(allRemotes, obj)
        end
    end
    -- Exclure les remotes système Roblox
    local filtered = {}
    for _, r in ipairs(allRemotes) do
        local n = r.Name:lower()
        if not n:find("analytics") and not n:find("report")
        and not n:find("log") and not n:find("error") then
            table.insert(filtered, r)
        end
    end
    allRemotes = filtered
end

-- ── TROUVE LE BOUTON CLICK PAR TAILLE + POSITION ─────────────────────────────
local function getButtonCenter()
    -- Le bouton x16 est toujours dans le quart gauche-centre de l'écran
    local vp = workspace.CurrentCamera.ViewportSize
    local bestBtn = nil
    local bestScore = 0

    for _, obj in ipairs(PlayerGui:GetDescendants()) do
        if (obj:IsA("ImageButton") or obj:IsA("TextButton")) and obj.Visible then
            local ok, abs = pcall(function()
                return obj.AbsolutePosition, obj.AbsoluteSize
            end)
            if ok then
                local pos  = obj.AbsolutePosition
                local sz   = obj.AbsoluteSize
                local area = sz.X * sz.Y
                -- Bouton carré, grande taille, côté gauche
                local isSquarish = math.abs(sz.X - sz.Y) < sz.X * 0.5
                local isLeft     = pos.X < vp.X * 0.6
                local score      = area * (isSquarish and 1.5 or 1) * (isLeft and 1.2 or 1)
                if score > bestScore and sz.X > 40 and sz.X < 400 then
                    bestScore = score
                    bestBtn = obj
                end
            end
        end
    end

    if bestBtn then
        local pos = bestBtn.AbsolutePosition
        local sz  = bestBtn.AbsoluteSize
        return Vector2.new(pos.X + sz.X/2, pos.Y + sz.Y/2), bestBtn
    end

    -- Fallback : position fixe estimée côté gauche
    return Vector2.new(vp.X * 0.22, vp.Y * 0.55), nil
end

-- ── LOOP PRINCIPAL ────────────────────────────────────────────────────────────
task.spawn(function()
    cacheAllRemotes()
    while true do
        task.wait(DELAY)
        if not clicking then continue end

        -- Méthode 1 : Fire TOUS les remotes
        for _, remote in ipairs(allRemotes) do
            pcall(function()
                if remote:IsA("RemoteEvent") then
                    remote:FireServer()
                end
            end)
        end

        -- Méthode 2 : MouseButton1Click direct sur le bouton
        local center, btn = getButtonCenter()
        if btn then
            pcall(function() btn.MouseButton1Click:Fire() end)
            pcall(function() btn.Activated:Fire() end)
        end

        -- Méthode 3 : Touch simulé à la position du bouton
        pcall(function()
            VIM:SendMouseButtonEvent(center.X, center.Y, 0, true, game, 0)
        end)
        task.wait(0.02)
        pcall(function()
            VIM:SendMouseButtonEvent(center.X, center.Y, 0, false, game, 0)
        end)

        -- Méthode 4 : Touch event mobile
        pcall(function()
            VIM:SendTouchEvent(0, center.X, center.Y, true)
        end)
        task.wait(0.01)
        pcall(function()
            VIM:SendTouchEvent(0, center.X, center.Y, false)
        end)

        clickCount = clickCount + 1
    end
end)

-- Refresh remotes toutes les 5 sec
task.spawn(function()
    while true do
        task.wait(5)
        if clicking then cacheAllRemotes() end
    end
end)

-- ── GUI ───────────────────────────────────────────────────────────────────────
local Gui = Instance.new("ScreenGui", PlayerGui)
Gui.Name = "AutoClickUI"; Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local Main = Instance.new("Frame", Gui)
Main.Size = UDim2.new(0,220,0,130); Main.Position = UDim2.new(0.5,-110,0,20)
Main.BackgroundColor3 = Color3.fromRGB(12,12,18); Main.BorderSizePixel = 0
Main.Active = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0,10)
local St = Instance.new("UIStroke", Main)
St.Color = Color3.fromRGB(38,38,58); St.Thickness = 1.5

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1,-10,0,20); Title.Position = UDim2.new(0,10,0,8)
Title.BackgroundTransparency = 1; Title.Text = "🖱️  AUTO CLICKER V3"
Title.TextColor3 = Color3.fromRGB(220,220,220); Title.TextSize = 12
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left

local StatusLbl = Instance.new("TextLabel", Main)
StatusLbl.Size = UDim2.new(1,-10,0,13); StatusLbl.Position = UDim2.new(0,10,0,30)
StatusLbl.BackgroundTransparency = 1; StatusLbl.Text = "● Status : OFF"
StatusLbl.TextColor3 = Color3.fromRGB(110,110,130); StatusLbl.TextSize = 10
StatusLbl.Font = Enum.Font.Gotham; StatusLbl.TextXAlignment = Enum.TextXAlignment.Left

local RemoteLbl = Instance.new("TextLabel", Main)
RemoteLbl.Size = UDim2.new(1,-10,0,13); RemoteLbl.Position = UDim2.new(0,10,0,45)
RemoteLbl.BackgroundTransparency = 1
RemoteLbl.Text = "● Remotes : " .. #allRemotes .. " (tous)"
RemoteLbl.TextColor3 = Color3.fromRGB(80,200,120); RemoteLbl.TextSize = 10
RemoteLbl.Font = Enum.Font.Gotham; RemoteLbl.TextXAlignment = Enum.TextXAlignment.Left

local MethodLbl = Instance.new("TextLabel", Main)
MethodLbl.Size = UDim2.new(1,-10,0,13); MethodLbl.Position = UDim2.new(0,10,0,60)
MethodLbl.BackgroundTransparency = 1; MethodLbl.Text = "● Mode : Remote + Touch"
MethodLbl.TextColor3 = Color3.fromRGB(80,200,120); MethodLbl.TextSize = 10
MethodLbl.Font = Enum.Font.Gotham; MethodLbl.TextXAlignment = Enum.TextXAlignment.Left

local CountLbl = Instance.new("TextLabel", Main)
CountLbl.Size = UDim2.new(1,-10,0,13); CountLbl.Position = UDim2.new(0,10,0,75)
CountLbl.BackgroundTransparency = 1; CountLbl.Text = "● Clicks : 0"
CountLbl.TextColor3 = Color3.fromRGB(255,180,80); CountLbl.TextSize = 10
CountLbl.Font = Enum.Font.Gotham; CountLbl.TextXAlignment = Enum.TextXAlignment.Left

task.spawn(function()
    while true do task.wait(0.1)
        CountLbl.Text  = "● Clicks : " .. clickCount
        RemoteLbl.Text = "● Remotes : " .. #allRemotes .. " (tous)"
    end
end)

local Pill = Instance.new("Frame", Main)
Pill.Size = UDim2.new(0,54,0,26); Pill.Position = UDim2.new(0.5,-27,0,96)
Pill.BackgroundColor3 = Color3.fromRGB(38,38,52); Pill.BorderSizePixel = 0
Instance.new("UICorner", Pill).CornerRadius = UDim.new(1,0)

local Knob = Instance.new("Frame", Pill)
Knob.Size = UDim2.new(0,20,0,20); Knob.Position = UDim2.new(0,3,0.5,-10)
Knob.BackgroundColor3 = Color3.fromRGB(255,255,255); Knob.BorderSizePixel = 0
Instance.new("UICorner", Knob).CornerRadius = UDim.new(1,0)

do
    local drag,startI,startP=false
    Main.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then
            drag=true startI=i.Position startP=Main.Position
        end
    end)
    Main.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then drag=false end
    end)
    UIS.InputChanged:Connect(function(i)
        if drag and(i.UserInputType==Enum.UserInputType.MouseMovement
        or i.UserInputType==Enum.UserInputType.Touch) then
            local d=i.Position-startI
            Main.Position=UDim2.new(startP.X.Scale,startP.X.Offset+d.X,
                startP.Y.Scale,startP.Y.Offset+d.Y)
        end
    end)
end

local Hit = Instance.new("TextButton", Main)
Hit.Size = UDim2.new(1,0,0,30); Hit.Position = UDim2.new(0,0,0,92)
Hit.BackgroundTransparency = 1; Hit.Text = ""

Hit.MouseButton1Click:Connect(function()
    clicking = not clicking
    if clicking then cacheAllRemotes(); clickCount = 0 end

    TweenService:Create(Pill, TweenInfo.new(0.15), {
        BackgroundColor3 = clicking
            and Color3.fromRGB(80,200,120)
            or  Color3.fromRGB(38,38,52)
    }):Play()
    TweenService:Create(Knob, TweenInfo.new(0.15), {
        Position = clicking
            and UDim2.new(1,-23,0.5,-10)
            or  UDim2.new(0,3,0.5,-10)
    }):Play()

    StatusLbl.Text = "● Status : " .. (clicking and "ON" or "OFF")
    StatusLbl.TextColor3 = clicking
        and Color3.fromRGB(80,200,120)
        or  Color3.fromRGB(110,110,130)
end)

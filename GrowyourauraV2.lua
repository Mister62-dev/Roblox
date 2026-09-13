-- Grow Your Aura | Auto Click V2 | Remote Direct
-- Delta Executor | Août 2026

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local UIS               = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer       = Players.LocalPlayer
local PlayerGui         = LocalPlayer:WaitForChild("PlayerGui")

if PlayerGui:FindFirstChild("AutoClickUI") then
    PlayerGui:FindFirstChild("AutoClickUI"):Destroy()
end

local clicking   = false
local clickCount = 0
local DELAY      = 0.05

-- ── SCAN TOUS LES REMOTES — log dans console ──────────────────────────────────
local function scanAllRemotes()
    print("=== REMOTES SCAN ===")
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            print("[RS] " .. obj:GetFullName())
        end
    end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            print("[WS] " .. obj:GetFullName())
        end
    end
    print("=== FIN SCAN ===")
end

-- Lance le scan au démarrage — lis la console Delta pour voir les noms
scanAllRemotes()

-- ── REMOTES CIBLES — mots-clés Grow Your Aura ────────────────────────────────
local CLICK_KEYS = {
    "click","train","punch","hit","tap","aura",
    "collect","gain","farm","grind","strike",
    "attack","swing","action","main","grow"
}

local cachedRemotes = {}

local function refreshRemotes()
    cachedRemotes = {}
    local function scan(parent)
        for _, obj in ipairs(parent:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                local n = obj.Name:lower()
                for _, k in ipairs(CLICK_KEYS) do
                    if n:find(k) then
                        table.insert(cachedRemotes, obj)
                        break
                    end
                end
            end
        end
    end
    scan(ReplicatedStorage)
    scan(workspace)
end

-- ── FIND GUI BUTTON — cherche ImageButton visible par taille ─────────────────
local function findMainButton()
    local best = nil
    local bestSize = 0
    for _, obj in ipairs(PlayerGui:GetDescendants()) do
        if (obj:IsA("ImageButton") or obj:IsA("TextButton")) and obj.Visible then
            local abs = obj.AbsoluteSize
            local area = abs.X * abs.Y
            -- Bouton principal = le plus grand bouton carré visible
            if area > bestSize and abs.X > 50 and abs.X < 300 then
                bestSize = area
                best = obj
            end
        end
    end
    return best
end

-- ── LOOP PRINCIPAL ────────────────────────────────────────────────────────────
task.spawn(function()
    refreshRemotes()

    while true do
        task.wait(DELAY)
        if not clicking then continue end

        -- Méthode 1 : Fire tous les remotes trouvés
        for _, remote in ipairs(cachedRemotes) do
            pcall(function()
                if remote:IsA("RemoteEvent") then
                    remote:FireServer()
                else
                    remote:InvokeServer()
                end
            end)
        end

        -- Méthode 2 : Click GUI button par position absolue (suit le bouton)
        local btn = findMainButton()
        if btn then
            pcall(function()
                -- Fire MouseButton1Click directement sur l'objet
                btn.MouseButton1Click:Fire()
            end)

            -- Méthode 3 : VirtualInputManager — simule le touch à la position du bouton
            pcall(function()
                local pos = btn.AbsolutePosition
                local sz  = btn.AbsoluteSize
                local center = Vector2.new(
                    pos.X + sz.X/2,
                    pos.Y + sz.Y/2
                )
                game:GetService("VirtualInputManager"):SendMouseButtonEvent(
                    center.X, center.Y, 0, true, game, 0)
                task.wait(0.01)
                game:GetService("VirtualInputManager"):SendMouseButtonEvent(
                    center.X, center.Y, 0, false, game, 0)
            end)
        end

        clickCount = clickCount + 1
    end
end)

-- Refresh remotes toutes les 5 sec (game peut en ajouter)
task.spawn(function()
    while true do task.wait(5)
        if clicking then refreshRemotes() end
    end
end)

-- ── GUI ───────────────────────────────────────────────────────────────────────
local Gui = Instance.new("ScreenGui", PlayerGui)
Gui.Name           = "AutoClickUI"
Gui.ResetOnSpawn   = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local Main = Instance.new("Frame", Gui)
Main.Size             = UDim2.new(0, 220, 0, 130)
Main.Position         = UDim2.new(0.5, -110, 0, 20)
Main.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
Main.BorderSizePixel  = 0
Main.Active           = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
local St = Instance.new("UIStroke", Main)
St.Color = Color3.fromRGB(38, 38, 58); St.Thickness = 1.5

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1,-10,0,20); Title.Position = UDim2.new(0,10,0,8)
Title.BackgroundTransparency = 1; Title.Text = "🖱️  AUTO CLICKER V2"
Title.TextColor3 = Color3.fromRGB(220,220,220); Title.TextSize = 12
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left

local StatusLbl = Instance.new("TextLabel", Main)
StatusLbl.Size = UDim2.new(1,-10,0,13); StatusLbl.Position = UDim2.new(0,10,0,30)
StatusLbl.BackgroundTransparency = 1; StatusLbl.Text = "● Status : OFF"
StatusLbl.TextColor3 = Color3.fromRGB(110,110,130); StatusLbl.TextSize = 10
StatusLbl.Font = Enum.Font.Gotham
StatusLbl.TextXAlignment = Enum.TextXAlignment.Left

local RemoteLbl = Instance.new("TextLabel", Main)
RemoteLbl.Size = UDim2.new(1,-10,0,13); RemoteLbl.Position = UDim2.new(0,10,0,45)
RemoteLbl.BackgroundTransparency = 1
RemoteLbl.Text = "● Remotes : " .. #cachedRemotes .. " trouvés"
RemoteLbl.TextColor3 = Color3.fromRGB(80,200,120); RemoteLbl.TextSize = 10
RemoteLbl.Font = Enum.Font.Gotham
RemoteLbl.TextXAlignment = Enum.TextXAlignment.Left

local SpeedLbl = Instance.new("TextLabel", Main)
SpeedLbl.Size = UDim2.new(1,-10,0,13); SpeedLbl.Position = UDim2.new(0,10,0,60)
SpeedLbl.BackgroundTransparency = 1; SpeedLbl.Text = "● Vitesse : 20 clicks/sec"
SpeedLbl.TextColor3 = Color3.fromRGB(80,200,120); SpeedLbl.TextSize = 10
SpeedLbl.Font = Enum.Font.Gotham
SpeedLbl.TextXAlignment = Enum.TextXAlignment.Left

local CountLbl = Instance.new("TextLabel", Main)
CountLbl.Size = UDim2.new(1,-10,0,13); CountLbl.Position = UDim2.new(0,10,0,75)
CountLbl.BackgroundTransparency = 1; CountLbl.Text = "● Clicks : 0"
CountLbl.TextColor3 = Color3.fromRGB(255,180,80); CountLbl.TextSize = 10
CountLbl.Font = Enum.Font.Gotham
CountLbl.TextXAlignment = Enum.TextXAlignment.Left

task.spawn(function()
    while true do task.wait(0.1)
        CountLbl.Text = "● Clicks : " .. clickCount
        RemoteLbl.Text = "● Remotes : " .. #cachedRemotes .. " trouvés"
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
    if clicking then
        refreshRemotes()
        clickCount = 0
    end

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

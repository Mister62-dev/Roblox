-- Grow Your Aura | Auto Click V4 | GUI Only, No Remote Bug
-- Delta Executor | Août 2026

local Players     = game:GetService("Players")
local TweenService= game:GetService("TweenService")
local UIS         = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

if PlayerGui:FindFirstChild("AutoClickUI") then
    PlayerGui:FindFirstChild("AutoClickUI"):Destroy()
end

local clicking   = false
local clickCount = 0
local DELAY      = 0.06

-- ── TROUVE LE BOUTON CLICK PRINCIPAL ─────────────────────────────────────────
-- Le bouton x2/x16 est un ImageButton rond, au centre-gauche de l'écran
local function findClickButton()
    local vp  = workspace.CurrentCamera.ViewportSize
    local best, bestScore = nil, 0

    for _, obj in ipairs(PlayerGui:GetDescendants()) do
        if obj:IsA("ImageButton") and obj.Visible then
            local ok, pos, sz
            ok, pos = pcall(function() return obj.AbsolutePosition end)
            if not ok then continue end
            ok, sz  = pcall(function() return obj.AbsoluteSize end)
            if not ok then continue end

            local area     = sz.X * sz.Y
            local isSquare = math.abs(sz.X - sz.Y) < sz.X * 0.4
            local inCenter = pos.X > vp.X * 0.1 and pos.X < vp.X * 0.75
                          and pos.Y > vp.Y * 0.3 and pos.Y < vp.Y * 0.85
            local bigEnough = sz.X > 60 and sz.X < 350

            if isSquare and inCenter and bigEnough then
                local score = area
                if score > bestScore then
                    bestScore = score
                    best = obj
                end
            end
        end
    end
    return best
end

-- ── LOOP CLICK ────────────────────────────────────────────────────────────────
local lastBtn = nil

task.spawn(function()
    while true do
        task.wait(DELAY)
        if not clicking then continue end

        local btn = findClickButton()
        if btn then
            lastBtn = btn
            -- Fire l'event click natif du bouton
            pcall(function() btn.MouseButton1Click:Fire() end)
            pcall(function() btn.Activated:Fire() end)

            -- Simule aussi le InputBegan/InputEnded sur le bouton
            pcall(function()
                local fakeInput = {
                    UserInputType = Enum.UserInputType.MouseButton1,
                    UserInputState = Enum.UserInputState.Begin,
                    Position = Vector3.new(
                        btn.AbsolutePosition.X + btn.AbsoluteSize.X/2,
                        btn.AbsolutePosition.Y + btn.AbsoluteSize.Y/2,
                        0
                    ),
                    Delta = Vector3.new(0,0,0),
                    KeyCode = Enum.KeyCode.Unknown,
                }
                btn.InputBegan:Fire(fakeInput)
            end)
            task.wait(0.02)
            pcall(function()
                local fakeInput = {
                    UserInputType = Enum.UserInputType.MouseButton1,
                    UserInputState = Enum.UserInputState.End,
                    Position = Vector3.new(
                        btn.AbsolutePosition.X + btn.AbsoluteSize.X/2,
                        btn.AbsolutePosition.Y + btn.AbsoluteSize.Y/2,
                        0
                    ),
                    Delta = Vector3.new(0,0,0),
                    KeyCode = Enum.KeyCode.Unknown,
                }
                btn.InputEnded:Fire(fakeInput)
            end)
        end
        clickCount = clickCount + 1
    end
end)

-- ── GUI ───────────────────────────────────────────────────────────────────────
local Gui = Instance.new("ScreenGui", PlayerGui)
Gui.Name = "AutoClickUI"; Gui.ResetOnSpawn = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local Main = Instance.new("Frame", Gui)
Main.Size = UDim2.new(0,220,0,120)
Main.Position = UDim2.new(0.5,-110,0,20)
Main.BackgroundColor3 = Color3.fromRGB(12,12,18)
Main.BorderSizePixel = 0; Main.Active = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0,10)
local St = Instance.new("UIStroke", Main)
St.Color = Color3.fromRGB(38,38,58); St.Thickness = 1.5

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1,-10,0,20); Title.Position = UDim2.new(0,10,0,8)
Title.BackgroundTransparency = 1; Title.Text = "🖱️  AUTO CLICKER V4"
Title.TextColor3 = Color3.fromRGB(220,220,220); Title.TextSize = 12
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left

local StatusLbl = Instance.new("TextLabel", Main)
StatusLbl.Size = UDim2.new(1,-10,0,13); StatusLbl.Position = UDim2.new(0,10,0,30)
StatusLbl.BackgroundTransparency = 1; StatusLbl.Text = "● Status : OFF"
StatusLbl.TextColor3 = Color3.fromRGB(110,110,130); StatusLbl.TextSize = 10
StatusLbl.Font = Enum.Font.Gotham
StatusLbl.TextXAlignment = Enum.TextXAlignment.Left

local BtnLbl = Instance.new("TextLabel", Main)
BtnLbl.Size = UDim2.new(1,-10,0,13); BtnLbl.Position = UDim2.new(0,10,0,45)
BtnLbl.BackgroundTransparency = 1; BtnLbl.Text = "● Bouton : recherche..."
BtnLbl.TextColor3 = Color3.fromRGB(80,200,120); BtnLbl.TextSize = 10
BtnLbl.Font = Enum.Font.Gotham
BtnLbl.TextXAlignment = Enum.TextXAlignment.Left

local ModeLbl = Instance.new("TextLabel", Main)
ModeLbl.Size = UDim2.new(1,-10,0,13); ModeLbl.Position = UDim2.new(0,10,0,60)
ModeLbl.BackgroundTransparency = 1; ModeLbl.Text = "● Mode : GUI only — sans bug"
ModeLbl.TextColor3 = Color3.fromRGB(80,200,120); ModeLbl.TextSize = 10
ModeLbl.Font = Enum.Font.Gotham
ModeLbl.TextXAlignment = Enum.TextXAlignment.Left

local CountLbl = Instance.new("TextLabel", Main)
CountLbl.Size = UDim2.new(1,-10,0,13); CountLbl.Position = UDim2.new(0,10,0,75)
CountLbl.BackgroundTransparency = 1; CountLbl.Text = "● Clicks : 0"
CountLbl.TextColor3 = Color3.fromRGB(255,180,80); CountLbl.TextSize = 10
CountLbl.Font = Enum.Font.Gotham
CountLbl.TextXAlignment = Enum.TextXAlignment.Left

task.spawn(function()
    while true do task.wait(0.15)
        CountLbl.Text = "● Clicks : " .. clickCount
        local b = findClickButton()
        if b then
            BtnLbl.Text = "● Bouton : " .. b.Name .. " ✔"
            BtnLbl.TextColor3 = Color3.fromRGB(80,200,120)
        else
            BtnLbl.Text = "● Bouton : non trouvé"
            BtnLbl.TextColor3 = Color3.fromRGB(210,55,55)
        end
    end
end)

local Pill = Instance.new("Frame", Main)
Pill.Size = UDim2.new(0,54,0,26); Pill.Position = UDim2.new(0.5,-27,0,88)
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
Hit.Size = UDim2.new(1,0,0,30); Hit.Position = UDim2.new(0,0,0,84)
Hit.BackgroundTransparency = 1; Hit.Text = ""

Hit.MouseButton1Click:Connect(function()
    clicking = not clicking
    if clicking then clickCount = 0 end

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

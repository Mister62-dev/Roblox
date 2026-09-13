-- Auto Clicker | Cockpit Roblox | Delta Executor
-- Août 2026 | Toggle ON/OFF | Fire remote + GUI click

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS          = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer  = Players.LocalPlayer
local PlayerGui    = LocalPlayer:WaitForChild("PlayerGui")

if PlayerGui:FindFirstChild("AutoClickUI") then
    PlayerGui:FindFirstChild("AutoClickUI"):Destroy()
end

local clicking  = false
local clickDelay = 0.05 -- 20 clicks/sec

-- ── LOGIQUE AUTO CLICK ────────────────────────────────────────────────────────
local function findClickRemote()
    -- Cherche le remote du bouton click dans ReplicatedStorage et Workspace
    local keywords = {"click","tap","train","aura","punch","hit","collect"}
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local n = obj.Name:lower()
            for _, k in ipairs(keywords) do
                if n:find(k) then return obj end
            end
        end
    end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local n = obj.Name:lower()
            for _, k in ipairs(keywords) do
                if n:find(k) then return obj end
            end
        end
    end
    return nil
end

local function findClickButton()
    -- Cherche le bouton GUI clickable (ImageButton ou TextButton)
    for _, gui in ipairs(PlayerGui:GetDescendants()) do
        if (gui:IsA("ImageButton") or gui:IsA("TextButton")) and gui.Visible then
            local n = gui.Name:lower()
            if n:find("click") or n:find("tap") or n:find("train")
            or n:find("punch") or n:find("hit") or n:find("main") then
                return gui
            end
        end
    end
    return nil
end

local remote = nil
local clickBtn = nil

task.spawn(function()
    while true do task.wait(clickDelay)
        if not clicking then continue end

        -- Méthode 1 : Fire le remote directement
        if not remote then remote = findClickRemote() end
        if remote then
            pcall(function()
                if remote:IsA("RemoteEvent") then
                    remote:FireServer()
                elseif remote:IsA("RemoteFunction") then
                    remote:InvokeServer()
                end
            end)
        end

        -- Méthode 2 : Simule le click sur le bouton GUI
        if not clickBtn then clickBtn = findClickButton() end
        if clickBtn then
            pcall(function()
                local vCon = clickBtn.MouseButton1Click
                if vCon then
                    vCon:Fire()
                end
            end)
        end
    end
end)

-- ── GUI ───────────────────────────────────────────────────────────────────────
local Gui = Instance.new("ScreenGui", PlayerGui)
Gui.Name           = "AutoClickUI"
Gui.ResetOnSpawn   = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local Main = Instance.new("Frame", Gui)
Main.Size             = UDim2.new(0, 200, 0, 120)
Main.Position         = UDim2.new(0.5, -100, 0, 20)
Main.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
Main.BorderSizePixel  = 0
Main.Active           = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
local St = Instance.new("UIStroke", Main)
St.Color = Color3.fromRGB(38, 38, 58); St.Thickness = 1.5

-- Titre
local Title = Instance.new("TextLabel", Main)
Title.Size                   = UDim2.new(1,-10,0,20)
Title.Position               = UDim2.new(0,10,0,8)
Title.BackgroundTransparency = 1
Title.Text                   = "🖱️  AUTO CLICKER"
Title.TextColor3             = Color3.fromRGB(220,220,220)
Title.TextSize               = 12
Title.Font                   = Enum.Font.GothamBold
Title.TextXAlignment         = Enum.TextXAlignment.Left

-- Status
local StatusLbl = Instance.new("TextLabel", Main)
StatusLbl.Size                   = UDim2.new(1,-10,0,13)
StatusLbl.Position               = UDim2.new(0,10,0,30)
StatusLbl.BackgroundTransparency = 1
StatusLbl.Text                   = "● Status : OFF"
StatusLbl.TextColor3             = Color3.fromRGB(110,110,130)
StatusLbl.TextSize               = 10
StatusLbl.Font                   = Enum.Font.Gotham
StatusLbl.TextXAlignment         = Enum.TextXAlignment.Left

-- Speed info
local SpeedLbl = Instance.new("TextLabel", Main)
SpeedLbl.Size                   = UDim2.new(1,-10,0,13)
SpeedLbl.Position               = UDim2.new(0,10,0,45)
SpeedLbl.BackgroundTransparency = 1
SpeedLbl.Text                   = "● Vitesse : 20 clicks/sec"
SpeedLbl.TextColor3             = Color3.fromRGB(80,200,120)
SpeedLbl.TextSize               = 10
SpeedLbl.Font                   = Enum.Font.Gotham
SpeedLbl.TextXAlignment         = Enum.TextXAlignment.Left

-- Counter
local CountLbl = Instance.new("TextLabel", Main)
CountLbl.Size                   = UDim2.new(1,-10,0,13)
CountLbl.Position               = UDim2.new(0,10,0,60)
CountLbl.BackgroundTransparency = 1
CountLbl.Text                   = "● Clicks : 0"
CountLbl.TextColor3             = Color3.fromRGB(255,180,80)
CountLbl.TextSize               = 10
CountLbl.Font                   = Enum.Font.Gotham
CountLbl.TextXAlignment         = Enum.TextXAlignment.Left

-- Counter loop
local clickCount = 0
task.spawn(function()
    while true do task.wait(clickDelay)
        if clicking then
            clickCount = clickCount + 1
            CountLbl.Text = "● Clicks : " .. clickCount
        end
    end
end)

-- Toggle pill
local Pill = Instance.new("Frame", Main)
Pill.Size             = UDim2.new(0,54,0,26)
Pill.Position         = UDim2.new(0.5,-27,0,84)
Pill.BackgroundColor3 = Color3.fromRGB(38,38,52)
Pill.BorderSizePixel  = 0
Instance.new("UICorner", Pill).CornerRadius = UDim.new(1,0)

local Knob = Instance.new("Frame", Pill)
Knob.Size             = UDim2.new(0,20,0,20)
Knob.Position         = UDim2.new(0,3,0.5,-10)
Knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
Knob.BorderSizePixel  = 0
Instance.new("UICorner", Knob).CornerRadius = UDim.new(1,0)

-- Drag
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
Hit.Size               = UDim2.new(1,0,0,30)
Hit.Position           = UDim2.new(0,0,0,80)
Hit.BackgroundTransparency = 1
Hit.Text               = ""

Hit.MouseButton1Click:Connect(function()
    clicking = not clicking
    remote   = nil
    clickBtn = nil

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

    StatusLbl.Text       = "● Status : " .. (clicking and "ON" or "OFF")
    StatusLbl.TextColor3 = clicking
        and Color3.fromRGB(80,200,120)
        or  Color3.fromRGB(110,110,130)

    if not clicking then clickCount = 0 end
end)

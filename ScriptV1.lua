-- Sans Dashboard | Full GUI
-- Delta Executor | Mobile Horizontal Optimized

local Players       = game:GetService("Players")
local TweenService  = game:GetService("TweenService")
local RunService    = game:GetService("RunService")
local UIS           = game:GetService("UserInputService")
local LocalPlayer   = Players.LocalPlayer
local Character     = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HRP           = Character:WaitForChild("HumanoidRootPart")

-- ── STATE ───────────────────────────────────────────────────────────────────
local S = {
    AutoMoney   = false,
    ToolGrabber = false,
    AntiHole    = false,
    HPMonitor   = false,
    GPDoor      = false,
    Delay       = 0.8,
}

local safePos = HRP.Position

-- ── UTILS ───────────────────────────────────────────────────────────────────
local function Notif(msg)
    game:GetService("StarterGui"):SetCore("SendNotification",
        {Title = "Dashboard", Text = msg, Duration = 2})
end

local function Fire(name, ...)
    local r = game:GetService("ReplicatedStorage"):FindFirstChild(name, true)
        or workspace:FindFirstChild(name, true)
    if not r then return end
    if r:IsA("RemoteEvent")    then r:FireServer(...)    end
    if r:IsA("RemoteFunction") then r:InvokeServer(...)  end
end

local function Glide(pos)
    TweenService:Create(HRP, TweenInfo.new(0.12, Enum.EasingStyle.Linear),
        {CFrame = CFrame.new(pos)}):Play()
end

LocalPlayer.CharacterAdded:Connect(function(c)
    Character = c
    HRP = c:WaitForChild("HumanoidRootPart")
end)

-- ── ROOT GUI ────────────────────────────────────────────────────────────────
local Gui = Instance.new("ScreenGui")
Gui.Name           = "SansDash"
Gui.ResetOnSpawn   = false
Gui.IgnoreGuiInset = true
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent         = LocalPlayer:WaitForChild("PlayerGui")

-- ── MINI ICON ───────────────────────────────────────────────────────────────
local Icon = Instance.new("TextButton")
Icon.Size            = UDim2.new(0, 54, 0, 54)
Icon.Position        = UDim2.new(0, 14, 0, 14)
Icon.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Icon.Text            = "⚔️"
Icon.TextSize        = 26
Icon.Font            = Enum.Font.GothamBold
Icon.TextColor3      = Color3.fromRGB(255,255,255)
Icon.BorderSizePixel = 0
Icon.Visible         = false
Icon.ZIndex          = 20
Icon.Parent          = Gui
Instance.new("UICorner", Icon).CornerRadius = UDim.new(1, 0)

local IconStroke = Instance.new("UIStroke")
IconStroke.Color     = Color3.fromRGB(34, 197, 94)
IconStroke.Thickness = 2
IconStroke.Parent    = Icon

-- ── MAIN FRAME ──────────────────────────────────────────────────────────────
local Main = Instance.new("Frame")
Main.Name            = "Main"
Main.Size            = UDim2.new(0, 520, 0, 268)
Main.Position        = UDim2.new(0.5, -260, 0.5, -134)
Main.BackgroundColor3 = Color3.fromRGB(13, 13, 13)
Main.BorderSizePixel = 0
Main.Active          = true
Main.Draggable       = true
Main.ClipsDescendants = true
Main.Parent          = Gui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

local MainStroke = Instance.new("UIStroke")
MainStroke.Color     = Color3.fromRGB(40, 40, 40)
MainStroke.Thickness = 1
MainStroke.Parent    = Main

-- ── TITLE BAR ───────────────────────────────────────────────────────────────
local Bar = Instance.new("Frame")
Bar.Size            = UDim2.new(1, 0, 0, 40)
Bar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Bar.BorderSizePixel = 0
Bar.ZIndex          = 2
Bar.Parent          = Main

local BarFix = Instance.new("Frame")
BarFix.Size            = UDim2.new(1, 0, 0, 8)
BarFix.Position        = UDim2.new(0, 0, 1, -8)
BarFix.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
BarFix.BorderSizePixel = 0
BarFix.ZIndex         = 2
BarFix.Parent         = Bar

local Accent = Instance.new("Frame")
Accent.Size            = UDim2.new(0, 3, 1, 0)
Accent.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
Accent.BorderSizePixel = 0
Accent.ZIndex          = 3
Accent.Parent          = Bar

local TitleLbl = Instance.new("TextLabel")
TitleLbl.Size              = UDim2.new(1, -90, 1, 0)
TitleLbl.Position          = UDim2.new(0, 14, 0, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text              = "⚔️  Sans Dashboard"
TitleLbl.TextColor3        = Color3.fromRGB(240, 240, 240)
TitleLbl.TextSize          = 13
TitleLbl.Font              = Enum.Font.GothamBold
TitleLbl.TextXAlignment    = Enum.TextXAlignment.Left
TitleLbl.ZIndex            = 3
TitleLbl.Parent            = Bar

-- Minimize button
local MinBtn = Instance.new("TextButton")
MinBtn.Size            = UDim2.new(0, 36, 0, 30)
MinBtn.Position        = UDim2.new(1, -42, 0, 5)
MinBtn.BackgroundColor3 = Color3.fromRGB(34, 34, 34)
MinBtn.Text            = "−"
MinBtn.TextColor3      = Color3.fromRGB(255,255,255)
MinBtn.TextSize        = 18
MinBtn.Font            = Enum.Font.GothamBold
MinBtn.BorderSizePixel = 0
MinBtn.ZIndex          = 4
MinBtn.Parent          = Bar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

-- ── HP STATUS BAR ───────────────────────────────────────────────────────────
local HPRow = Instance.new("Frame")
HPRow.Size            = UDim2.new(1, 0, 0, 26)
HPRow.Position        = UDim2.new(0, 0, 0, 40)
HPRow.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
HPRow.BorderSizePixel = 0
HPRow.Parent          = Main

local HPLbl = Instance.new("TextLabel")
HPLbl.Size              = UDim2.new(1, -20, 1, 0)
HPLbl.Position          = UDim2.new(0, 12, 0, 0)
HPLbl.BackgroundTransparency = 1
HPLbl.Text              = "❤️  Boss HP : —"
HPLbl.TextColor3        = Color3.fromRGB(239, 68, 68)
HPLbl.TextSize          = 11
HPLbl.Font              = Enum.Font.Gotham
HPLbl.TextXAlignment    = Enum.TextXAlignment.Left
HPLbl.Parent            = HPRow

-- ── CONTENT (2 colonnes) ────────────────────────────────────────────────────
local Content = Instance.new("Frame")
Content.Size               = UDim2.new(1, -16, 1, -76)
Content.Position           = UDim2.new(0, 8, 0, 70)
Content.BackgroundTransparency = 1
Content.Parent             = Main

local function MakeCol(xPos)
    local f = Instance.new("Frame")
    f.Size               = UDim2.new(0.5, -5, 1, 0)
    f.Position           = UDim2.new(xPos, xPos == 0 and 0 or 8, 0, 0)
    f.BackgroundTransparency = 1
    f.Parent             = Content
    local l = Instance.new("UIListLayout")
    l.Padding            = UDim.new(0, 6)
    l.Parent             = f
    return f
end

local Left  = MakeCol(0)
local Right = MakeCol(0.5)

-- ── TOGGLE ──────────────────────────────────────────────────────────────────
local function Toggle(parent, icon, label, key, color)
    color = color or Color3.fromRGB(34, 197, 94)

    local Row = Instance.new("Frame")
    Row.Size            = UDim2.new(1, 0, 0, 44)
    Row.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
    Row.BorderSizePixel = 0
    Row.Parent          = parent
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 8)

    local Ico = Instance.new("TextLabel")
    Ico.Size               = UDim2.new(0, 28, 1, 0)
    Ico.BackgroundTransparency = 1
    Ico.Text               = icon
    Ico.TextSize           = 16
    Ico.Font               = Enum.Font.GothamBold
    Ico.Parent             = Row

    local Lbl = Instance.new("TextLabel")
    Lbl.Size               = UDim2.new(1, -78, 1, 0)
    Lbl.Position           = UDim2.new(0, 30, 0, 0)
    Lbl.BackgroundTransparency = 1
    Lbl.Text               = label
    Lbl.TextColor3         = Color3.fromRGB(210, 210, 210)
    Lbl.TextSize           = 11
    Lbl.Font               = Enum.Font.Gotham
    Lbl.TextXAlignment     = Enum.TextXAlignment.Left
    Lbl.Parent             = Row

    local Track = Instance.new("Frame")
    Track.Size             = UDim2.new(0, 40, 0, 20)
    Track.Position         = UDim2.new(1, -46, 0.5, -10)
    Track.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    Track.BorderSizePixel  = 0
    Track.Parent           = Row
    Instance.new("UICorner", Track).CornerRadius = UDim.new(1, 0)

    local Knob = Instance.new("Frame")
    Knob.Size            = UDim2.new(0, 16, 0, 16)
    Knob.Position        = UDim2.new(0, 2, 0.5, -8)
    Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Knob.BorderSizePixel = 0
    Knob.Parent          = Track
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

    local HitBtn = Instance.new("TextButton")
    HitBtn.Size               = UDim2.new(1, 0, 1, 0)
    HitBtn.BackgroundTransparency = 1
    HitBtn.Text               = ""
    HitBtn.Parent             = Row

    local function Refresh()
        local on = S[key]
        TweenService:Create(Track, TweenInfo.new(0.15), {
            BackgroundColor3 = on and color or Color3.fromRGB(45,45,45)
        }):Play()
        TweenService:Create(Knob, TweenInfo.new(0.15), {
            Position = on
                and UDim2.new(0, 22, 0.5, -8)
                or  UDim2.new(0,  2, 0.5, -8)
        }):Play()
    end

    HitBtn.MouseButton1Click:Connect(function()
        S[key] = not S[key]
        Refresh()
        Notif(label .. (S[key] and " → ON" or " → OFF"))
    end)
end

-- ── SLIDER (touch + mouse) ──────────────────────────────────────────────────
local function Slider(parent, label, minV, maxV, defaultV, cb)
    local F = Instance.new("Frame")
    F.Size            = UDim2.new(1, 0, 0, 50)
    F.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
    F.BorderSizePixel = 0
    F.Parent          = parent
    Instance.new("UICorner", F).CornerRadius = UDim.new(0, 8)

    local ValLbl = Instance.new("TextLabel")
    ValLbl.Size               = UDim2.new(1, -12, 0, 20)
    ValLbl.Position           = UDim2.new(0, 10, 0, 4)
    ValLbl.BackgroundTransparency = 1
    ValLbl.Text               = label .. " : " .. defaultV
    ValLbl.TextColor3         = Color3.fromRGB(200, 200, 200)
    ValLbl.TextSize           = 11
    ValLbl.Font               = Enum.Font.Gotham
    ValLbl.TextXAlignment     = Enum.TextXAlignment.Left
    ValLbl.Parent             = F

    local Track = Instance.new("Frame")
    Track.Size            = UDim2.new(1, -20, 0, 6)
    Track.Position        = UDim2.new(0, 10, 0, 34)
    Track.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    Track.BorderSizePixel = 0
    Track.Parent          = F
    Instance.new("UICorner", Track).CornerRadius = UDim.new(1, 0)

    local pct0 = (defaultV - minV) / (maxV - minV)

    local Fill = Instance.new("Frame")
    Fill.Size            = UDim2.new(pct0, 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
    Fill.BorderSizePixel = 0
    Fill.Parent          = Track
    Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)

    local Knob = Instance.new("TextButton")
    Knob.Size            = UDim2.new(0, 20, 0, 20)
    Knob.Position        = UDim2.new(pct0, -10, 0.5, -10)
    Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Knob.Text            = ""
    Knob.BorderSizePixel = 0
    Knob.AutoButtonColor = false
    Knob.Parent          = Track
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

    local dragging = false
    Knob.MouseButton1Down:Connect(function() dragging = true end)
    Knob.TouchLongPress:Connect(function() dragging = true end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    RunService.Heartbeat:Connect(function()
        if not dragging then return end
        local inputPos = UIS:GetMouseLocation()
        local tAbs    = Track.AbsolutePosition
        local tSize   = Track.AbsoluteSize
        local rel     = math.clamp((inputPos.X - tAbs.X) / tSize.X, 0, 1)
        local val     = math.round(minV + (maxV - minV) * rel * 10) / 10
        Fill.Size          = UDim2.new(rel, 0, 1, 0)
        Knob.Position      = UDim2.new(rel, -10, 0.5, -10)
        ValLbl.Text        = label .. " : " .. val
        if cb then cb(val) end
    end)
end

-- ── ACTION BUTTON ───────────────────────────────────────────────────────────
local function ActBtn(parent, icon, label, color, cb)
    local Btn = Instance.new("TextButton")
    Btn.Size            = UDim2.new(1, 0, 0, 40)
    Btn.BackgroundColor3 = color or Color3.fromRGB(59, 130, 246)
    Btn.Text            = icon .. "  " .. label
    Btn.TextColor3      = Color3.fromRGB(255, 255, 255)
    Btn.TextSize        = 12
    Btn.Font            = Enum.Font.GothamBold
    Btn.BorderSizePixel = 0
    Btn.Parent          = parent
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 8)
    Btn.MouseButton1Click:Connect(cb)
end

-- ── POPULATE LEFT ───────────────────────────────────────────────────────────
Toggle(Left, "💰", "Auto Money",      "AutoMoney",   Color3.fromRGB(234,179,8))
Toggle(Left, "🛠️", "Tool Grabber",    "ToolGrabber", Color3.fromRGB(168,85,247))
Toggle(Left, "🕳️", "Anti Black Hole", "AntiHole",    Color3.fromRGB(239,68,68))
Slider(Left, "⏱ Delay", 0.2, 3, 0.8, function(v) S.Delay = v end)

-- ── POPULATE RIGHT ──────────────────────────────────────────────────────────
Toggle(Right, "❤️", "HP Monitor",    "HPMonitor", Color3.fromRGB(239,68,68))
Toggle(Right, "🚪", "GP Door Bypass","GPDoor",    Color3.fromRGB(59,130,246))

ActBtn(Right, "⚡", "Grab All Tools", Color3.fromRGB(100,60,200), function()
    for i = 1, 5 do
        Fire("ToolGiver" .. (i == 1 and "" or tostring(i)))
        task.wait(0.1)
    end
    Notif("Tools récupérés")
end)

ActBtn(Right, "💰", "Money Maintenant", Color3.fromRGB(180,130,0), function()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj.Name == "Money" then
            local p = obj:IsA("BasePart") and obj or obj:FindFirstChildOfClass("BasePart")
            if p then Glide(p.Position) task.wait(0.15) end
            Fire("TeleFunction", obj)
        end
    end
    Notif("Money collecté")
end)

-- ── MINIMIZE / RESTORE ──────────────────────────────────────────────────────
MinBtn.MouseButton1Click:Connect(function()
    TweenService:Create(Main, TweenInfo.new(0.2), {
        Size = UDim2.new(0, 520, 0, 0)
    }):Play()
    task.wait(0.2)
    Main.Visible = false
    Icon.Visible = true
end)

Icon.MouseButton1Click:Connect(function()
    Icon.Visible = false
    Main.Visible = true
    Main.Size    = UDim2.new(0, 520, 0, 0)
    TweenService:Create(Main, TweenInfo.new(0.2), {
        Size = UDim2.new(0, 520, 0, 268)
    }):Play()
end)

-- ── LOOPS ───────────────────────────────────────────────────────────────────

-- HP Monitor
task.spawn(function()
    while true do
        task.wait(0.5)
        if S.HPMonitor then
            for _, obj in ipairs(workspace:GetDescendants()) do
                local hum = obj:FindFirstChildOfClass("Humanoid")
                local n   = obj.Name
                if hum and (n:find("UltimateSans") or n:find("Last.Breath")) then
                    HPLbl.Text = "❤️  Boss HP : "
                        .. math.floor(hum.Health)
                        .. " / "
                        .. math.floor(hum.MaxHealth)
                    break
                end
            end
        else
            HPLbl.Text = "❤️  Boss HP : —"
        end
    end
end)

-- Auto Money
task.spawn(function()
    while true do
        task.wait(S.Delay)
        if not S.AutoMoney then continue end
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj.Name == "Money" then
                local p = obj:IsA("BasePart") and obj or obj:FindFirstChildOfClass("BasePart")
                if p then Glide(p.Position) task.wait(0.15) end
                Fire("TeleFunction", obj)
                task.wait(S.Delay)
            end
        end
    end
end)

-- Tool Grabber loop
task.spawn(function()
    while true do
        task.wait(S.Delay * 4)
        if not S.ToolGrabber then continue end
        for i = 1, 5 do
            Fire("ToolGiver" .. (i == 1 and "" or tostring(i)))
            task.wait(0.12)
        end
    end
end)

-- Anti Black Hole
task.spawn(function()
    while true do
        task.wait(0.25)
        if S.AntiHole then
            local hole = workspace:FindFirstChild("White Black Hole", true)
            if hole then
                local p = hole:IsA("BasePart") and hole
                    or hole:FindFirstChildOfClass("BasePart")
                if p and (HRP.Position - p.Position).Magnitude < 40 then
                    Glide(safePos)
                    Notif("⚠️ Black Hole évité")
                end
            end
        else
            safePos = HRP.Position
        end
    end
end)

-- GP Door
task.spawn(function()
    while true do
        task.wait(S.Delay * 5)
        if not S.GPDoor then continue end
        Fire("TeleFunction")
        Fire("GPDoor")
    end
end)

Notif("✅ Dashboard chargé — Bonne game boss man")

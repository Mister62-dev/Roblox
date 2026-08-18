-- Sans Dashboard v3 | GP Character Selector
-- Delta Executor | Mobile Horizontal Optimized

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local LocalPlayer  = Players.LocalPlayer
local Character    = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HRP          = Character:WaitForChild("HumanoidRootPart")

local S = {
    AutoMoney   = false,
    ToolGrabber = false,
    AntiHole    = false,
    HPMonitor   = false,
    Delay       = 0.8,
}
local safePos = HRP.Position

local function Notif(msg)
    game:GetService("StarterGui"):SetCore("SendNotification",
        {Title="Dashboard", Text=msg, Duration=2})
end

local function Glide(pos)
    TweenService:Create(HRP, TweenInfo.new(0.12, Enum.EasingStyle.Linear),
        {CFrame = CFrame.new(pos)}):Play()
end

local function Fire(name, ...)
    local r = game:GetService("ReplicatedStorage"):FindFirstChild(name, true)
           or workspace:FindFirstChild(name, true)
    if not r then return end
    if r:IsA("RemoteEvent")    then r:FireServer(...)   end
    if r:IsA("RemoteFunction") then r:InvokeServer(...) end
end

LocalPlayer.CharacterAdded:Connect(function(c)
    Character = c
    HRP = c:WaitForChild("HumanoidRootPart")
end)

-- ── GUI ROOT ──────────────────────────────────────────────────────────────────
local Gui = Instance.new("ScreenGui")
Gui.Name           = "SansDash"
Gui.ResetOnSpawn   = false
Gui.IgnoreGuiInset = true
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent         = LocalPlayer:WaitForChild("PlayerGui")

-- ── ICÔNE ─────────────────────────────────────────────────────────────────────
local Icon = Instance.new("TextButton")
Icon.Size             = UDim2.new(0, 54, 0, 54)
Icon.Position         = UDim2.new(0, 14, 0, 14)
Icon.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Icon.Text             = "⚔️"
Icon.TextSize         = 26
Icon.Font             = Enum.Font.GothamBold
Icon.TextColor3       = Color3.fromRGB(255, 255, 255)
Icon.BorderSizePixel  = 0
Icon.Visible          = false
Icon.ZIndex           = 20
Icon.Parent           = Gui
Instance.new("UICorner", Icon).CornerRadius = UDim.new(1, 0)
local IS = Instance.new("UIStroke", Icon)
IS.Color = Color3.fromRGB(34, 197, 94); IS.Thickness = 2

-- ── MAIN ──────────────────────────────────────────────────────────────────────
local Main = Instance.new("Frame")
Main.Name             = "Main"
Main.Size             = UDim2.new(0, 520, 0, 268)
Main.Position         = UDim2.new(0.5, -260, 0.5, -134)
Main.BackgroundColor3 = Color3.fromRGB(13, 13, 13)
Main.BorderSizePixel  = 0
Main.Active           = true
Main.Draggable        = true
Main.ClipsDescendants = true
Main.Parent           = Gui
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
local MS = Instance.new("UIStroke", Main)
MS.Color = Color3.fromRGB(40, 40, 40); MS.Thickness = 1

-- ── TITLE BAR ─────────────────────────────────────────────────────────────────
local Bar = Instance.new("Frame")
Bar.Size             = UDim2.new(1, 0, 0, 40)
Bar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Bar.BorderSizePixel  = 0; Bar.ZIndex = 2
Bar.Parent           = Main

local BarFix = Instance.new("Frame")
BarFix.Size             = UDim2.new(1, 0, 0, 8)
BarFix.Position         = UDim2.new(0, 0, 1, -8)
BarFix.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
BarFix.BorderSizePixel  = 0; BarFix.ZIndex = 2
BarFix.Parent           = Bar

local Accent = Instance.new("Frame")
Accent.Size             = UDim2.new(0, 3, 1, 0)
Accent.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
Accent.BorderSizePixel  = 0; Accent.ZIndex = 3
Accent.Parent           = Bar

local TitleLbl = Instance.new("TextLabel")
TitleLbl.Size                = UDim2.new(1, -90, 1, 0)
TitleLbl.Position            = UDim2.new(0, 14, 0, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text                = "⚔️  Sans Dashboard"
TitleLbl.TextColor3          = Color3.fromRGB(240, 240, 240)
TitleLbl.TextSize            = 13; TitleLbl.Font = Enum.Font.GothamBold
TitleLbl.TextXAlignment      = Enum.TextXAlignment.Left
TitleLbl.ZIndex              = 3; TitleLbl.Parent = Bar

local MinBtn = Instance.new("TextButton")
MinBtn.Size             = UDim2.new(0, 36, 0, 30)
MinBtn.Position         = UDim2.new(1, -42, 0, 5)
MinBtn.BackgroundColor3 = Color3.fromRGB(34, 34, 34)
MinBtn.Text = "−"; MinBtn.TextColor3 = Color3.fromRGB(255,255,255)
MinBtn.TextSize = 18; MinBtn.Font = Enum.Font.GothamBold
MinBtn.BorderSizePixel = 0; MinBtn.ZIndex = 4
MinBtn.Parent = Bar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

-- ── HP ROW ────────────────────────────────────────────────────────────────────
local HPRow = Instance.new("Frame")
HPRow.Size             = UDim2.new(1, 0, 0, 26)
HPRow.Position         = UDim2.new(0, 0, 0, 40)
HPRow.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
HPRow.BorderSizePixel  = 0; HPRow.Parent = Main

local HPLbl = Instance.new("TextLabel")
HPLbl.Size                = UDim2.new(1, -20, 1, 0)
HPLbl.Position            = UDim2.new(0, 12, 0, 0)
HPLbl.BackgroundTransparency = 1
HPLbl.Text                = "❤️  Boss HP : —"
HPLbl.TextColor3          = Color3.fromRGB(239, 68, 68)
HPLbl.TextSize            = 11; HPLbl.Font = Enum.Font.Gotham
HPLbl.TextXAlignment      = Enum.TextXAlignment.Left
HPLbl.Parent              = HPRow

-- ── CONTENU PRINCIPAL ─────────────────────────────────────────────────────────
local Content = Instance.new("Frame")
Content.Size                = UDim2.new(1, -16, 1, -76)
Content.Position            = UDim2.new(0, 8, 0, 70)
Content.BackgroundTransparency = 1
Content.Parent              = Main

local function MakeCol(xPos)
    local f = Instance.new("Frame")
    f.Size                = UDim2.new(0.5, -5, 1, 0)
    f.Position            = UDim2.new(xPos, xPos == 0 and 0 or 8, 0, 0)
    f.BackgroundTransparency = 1; f.Parent = Content
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, 6); l.Parent = f
    return f
end

local Left  = MakeCol(0)
local Right = MakeCol(0.5)

-- ── TOGGLE ────────────────────────────────────────────────────────────────────
local function Toggle(parent, icon, label, key, color)
    color = color or Color3.fromRGB(34, 197, 94)
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1,0,0,44)
    Row.BackgroundColor3 = Color3.fromRGB(22,22,22)
    Row.BorderSizePixel = 0; Row.Parent = parent
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0,8)
    local Ico = Instance.new("TextLabel")
    Ico.Size = UDim2.new(0,28,1,0); Ico.BackgroundTransparency = 1
    Ico.Text = icon; Ico.TextSize = 16; Ico.Font = Enum.Font.GothamBold
    Ico.Parent = Row
    local Lbl = Instance.new("TextLabel")
    Lbl.Size = UDim2.new(1,-78,1,0); Lbl.Position = UDim2.new(0,30,0,0)
    Lbl.BackgroundTransparency = 1; Lbl.Text = label
    Lbl.TextColor3 = Color3.fromRGB(210,210,210)
    Lbl.TextSize = 11; Lbl.Font = Enum.Font.Gotham
    Lbl.TextXAlignment = Enum.TextXAlignment.Left; Lbl.Parent = Row
    local Track = Instance.new("Frame")
    Track.Size = UDim2.new(0,40,0,20); Track.Position = UDim2.new(1,-46,0.5,-10)
    Track.BackgroundColor3 = Color3.fromRGB(45,45,45)
    Track.BorderSizePixel = 0; Track.Parent = Row
    Instance.new("UICorner", Track).CornerRadius = UDim.new(1,0)
    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.new(0,16,0,16); Knob.Position = UDim2.new(0,2,0.5,-8)
    Knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
    Knob.BorderSizePixel = 0; Knob.Parent = Track
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1,0)
    local Hit = Instance.new("TextButton")
    Hit.Size = UDim2.new(1,0,1,0); Hit.BackgroundTransparency = 1
    Hit.Text = ""; Hit.Parent = Row
    local function Refresh()
        TweenService:Create(Track, TweenInfo.new(0.15), {
            BackgroundColor3 = S[key] and color or Color3.fromRGB(45,45,45)
        }):Play()
        TweenService:Create(Knob, TweenInfo.new(0.15), {
            Position = S[key] and UDim2.new(0,22,0.5,-8) or UDim2.new(0,2,0.5,-8)
        }):Play()
    end
    Hit.MouseButton1Click:Connect(function()
        S[key] = not S[key]; Refresh()
        Notif(label..(S[key] and " → ON" or " → OFF"))
    end)
end

-- ── SLIDER ────────────────────────────────────────────────────────────────────
local function Slider(parent, label, minV, maxV, defV, cb)
    local F = Instance.new("Frame")
    F.Size = UDim2.new(1,0,0,50); F.BackgroundColor3 = Color3.fromRGB(22,22,22)
    F.BorderSizePixel = 0; F.Parent = parent
    Instance.new("UICorner", F).CornerRadius = UDim.new(0,8)
    local ValLbl = Instance.new("TextLabel")
    ValLbl.Size = UDim2.new(1,-12,0,20); ValLbl.Position = UDim2.new(0,10,0,4)
    ValLbl.BackgroundTransparency = 1; ValLbl.Text = label.." : "..defV
    ValLbl.TextColor3 = Color3.fromRGB(200,200,200)
    ValLbl.TextSize = 11; ValLbl.Font = Enum.Font.Gotham
    ValLbl.TextXAlignment = Enum.TextXAlignment.Left; ValLbl.Parent = F
    local Track = Instance.new("Frame")
    Track.Size = UDim2.new(1,-20,0,6); Track.Position = UDim2.new(0,10,0,34)
    Track.BackgroundColor3 = Color3.fromRGB(40,40,40)
    Track.BorderSizePixel = 0; Track.Parent = F
    Instance.new("UICorner", Track).CornerRadius = UDim.new(1,0)
    local p0 = (defV-minV)/(maxV-minV)
    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new(p0,0,1,0); Fill.BackgroundColor3 = Color3.fromRGB(34,197,94)
    Fill.BorderSizePixel = 0; Fill.Parent = Track
    Instance.new("UICorner", Fill).CornerRadius = UDim.new(1,0)
    local Knob = Instance.new("TextButton")
    Knob.Size = UDim2.new(0,20,0,20); Knob.Position = UDim2.new(p0,-10,0.5,-10)
    Knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
    Knob.Text = ""; Knob.BorderSizePixel = 0; Knob.AutoButtonColor = false
    Knob.Parent = Track
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1,0)
    local dragging = false
    Knob.MouseButton1Down:Connect(function() dragging = true end)
    Knob.TouchLongPress:Connect(function() dragging = true end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    RunService.Heartbeat:Connect(function()
        if not dragging then return end
        local ip = UIS:GetMouseLocation()
        local tA = Track.AbsolutePosition; local tS = Track.AbsoluteSize
        local rel = math.clamp((ip.X-tA.X)/tS.X,0,1)
        local val = math.round(minV+(maxV-minV)*rel*10)/10
        Fill.Size = UDim2.new(rel,0,1,0); Knob.Position = UDim2.new(rel,-10,0.5,-10)
        ValLbl.Text = label.." : "..val; if cb then cb(val) end
    end)
end

-- ── ACTION BTN ────────────────────────────────────────────────────────────────
local function ActBtn(parent, icon, label, color, cb)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1,0,0,36); Btn.BackgroundColor3 = color or Color3.fromRGB(59,130,246)
    Btn.Text = icon.."  "..label; Btn.TextColor3 = Color3.fromRGB(255,255,255)
    Btn.TextSize = 11; Btn.Font = Enum.Font.GothamBold
    Btn.BorderSizePixel = 0; Btn.Parent = parent
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0,8)
    Btn.MouseButton1Click:Connect(cb)
end

-- ── POPULATE LEFT ─────────────────────────────────────────────────────────────
Toggle(Left, "💰", "Auto Money",      "AutoMoney",   Color3.fromRGB(234,179,8))
Toggle(Left, "🛠️", "Tool Grabber",    "ToolGrabber", Color3.fromRGB(168,85,247))
Toggle(Left, "🕳️", "Anti Black Hole", "AntiHole",    Color3.fromRGB(239,68,68))
Toggle(Left, "❤️", "HP Monitor",      "HPMonitor",   Color3.fromRGB(239,68,68))
Slider(Left, "⏱ Delay", 0.2, 3, 0.8, function(v) S.Delay = v end)

-- ── POPULATE RIGHT — GP SELECTOR ──────────────────────────────────────────────
local GPLabel = Instance.new("TextLabel")
GPLabel.Size                = UDim2.new(1, 0, 0, 22)
GPLabel.BackgroundTransparency = 1
GPLabel.Text                = "🚪 Persos GP détectés :"
GPLabel.TextColor3          = Color3.fromRGB(59, 130, 246)
GPLabel.TextSize            = 11
GPLabel.Font                = Enum.Font.GothamBold
GPLabel.TextXAlignment      = Enum.TextXAlignment.Left
GPLabel.Parent              = Right

local Scroll = Instance.new("ScrollingFrame")
Scroll.Size                = UDim2.new(1, 0, 1, -60)
Scroll.BackgroundColor3    = Color3.fromRGB(18, 18, 18)
Scroll.BorderSizePixel     = 0
Scroll.ScrollBarThickness  = 3
Scroll.ScrollBarImageColor3 = Color3.fromRGB(59, 130, 246)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.CanvasSize          = UDim2.new(0, 0, 0, 0)
Scroll.Parent              = Right
Instance.new("UICorner", Scroll).CornerRadius = UDim.new(0, 8)

local ScrollLayout = Instance.new("UIListLayout")
ScrollLayout.Padding   = UDim.new(0, 4)
ScrollLayout.Parent    = Scroll

local ScrollPad = Instance.new("UIPadding")
ScrollPad.PaddingTop    = UDim.new(0, 4)
ScrollPad.PaddingLeft   = UDim.new(0, 4)
ScrollPad.PaddingRight  = UDim.new(0, 4)
ScrollPad.PaddingBottom = UDim.new(0, 4)
ScrollPad.Parent        = Scroll

local function ScanGPChars()
    for _, c in ipairs(Scroll:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    local found = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") then
            local n = obj.Name:lower()
            if n:find("sans") or n:find("bendy") or n:find("last") or n:find("breath")
            or n:find("phase") or n:find("morph") or n:find("boss") or n:find("npc")
            or n:find("mini") then
                local part = obj:FindFirstChild("HumanoidRootPart")
                          or obj:FindFirstChildOfClass("BasePart")
                if part then
                    table.insert(found, {name = obj.Name, model = obj, part = part})
                end
            end
        end
    end
    if #found == 0 then
        local Empty = Instance.new("TextLabel")
        Empty.Size = UDim2.new(1, -8, 0, 30)
        Empty.BackgroundTransparency = 1
        Empty.Text = "Aucun perso détecté"
        Empty.TextColor3 = Color3.fromRGB(150, 150, 150)
        Empty.TextSize = 10; Empty.Font = Enum.Font.Gotham
        Empty.Parent = Scroll
        return
    end
    for _, entry in ipairs(found) do
        local Btn = Instance.new("TextButton")
        Btn.Size             = UDim2.new(1, -8, 0, 38)
        Btn.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
        Btn.BorderSizePixel  = 0
        Btn.TextColor3       = Color3.fromRGB(255, 255, 255)
        Btn.TextSize         = 10
        Btn.Font             = Enum.Font.Gotham
        Btn.TextXAlignment   = Enum.TextXAlignment.Left
        Btn.AutoButtonColor  = false
        Btn.Parent           = Scroll
        Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
        local displayName = entry.name
        if #displayName > 22 then displayName = displayName:sub(1,22).."…" end
        Btn.Text = "  🎭 "..displayName
        local BtnS = Instance.new("UIStroke", Btn)
        BtnS.Color = Color3.fromRGB(59, 130, 246); BtnS.Thickness = 1
        Btn.MouseEnter:Connect(function()
            TweenService:Create(Btn, TweenInfo.new(0.1), {
                BackgroundColor3 = Color3.fromRGB(35, 35, 60)
            }):Play()
        end)
        Btn.MouseLeave:Connect(function()
            TweenService:Create(Btn, TweenInfo.new(0.1), {
                BackgroundColor3 = Color3.fromRGB(25, 25, 35)
            }):Play()
        end)
        local model  = entry.model
        local target = entry.part
        Btn.MouseButton1Click:Connect(function()
            HRP.CFrame = CFrame.new(target.Position + Vector3.new(0, 4, 0))
            task.wait(0.3)
            local fired = 0
            for _, d in ipairs(model:GetDescendants()) do
                if d:IsA("RemoteEvent") then
                    pcall(function() d:FireServer() end)
                    fired = fired + 1
                end
            end
            local tele = model:FindFirstChild("TeleFunction", true)
            if tele and tele:IsA("RemoteFunction") then
                pcall(function() tele:InvokeServer() end)
            end
            for _, obj in ipairs(workspace:GetDescendants()) do
                local n = obj.Name:lower()
                if n:find("gp door") or n:find("gpdoor") then
                    local p = obj:IsA("BasePart") and obj or obj:FindFirstChildOfClass("BasePart")
                    if p then
                        HRP.CFrame = CFrame.new(p.Position + p.CFrame.LookVector * 8)
                        task.wait(0.2)
                    end
                end
            end
            Notif("🎭 Téléporté sur : "..entry.name
                ..(fired > 0 and " | "..fired.." remotes fired" or ""))
            TweenService:Create(BtnS, TweenInfo.new(0.15), {
                Color = Color3.fromRGB(34, 197, 94)
            }):Play()
        end)
    end
    Notif("🔍 "..#found.." perso(s) GP trouvé(s)")
end

ActBtn(Right, "🔍", "Scanner les persos", Color3.fromRGB(30, 80, 180), function()
    ScanGPChars()
end)

-- ── MINIMIZE ──────────────────────────────────────────────────────────────────
MinBtn.MouseButton1Click:Connect(function()
    TweenService:Create(Main, TweenInfo.new(0.2), {Size=UDim2.new(0,520,0,0)}):Play()
    task.wait(0.22); Main.Visible = false; Icon.Visible = true
end)

-- ── ICON DRAG ─────────────────────────────────────────────────────────────────
do
    local dragging, moved = false, false
    local dragStart, posStart = Vector2.new(), Icon.Position
    local THRESHOLD = 8
    Icon.InputBegan:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1
        and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        dragging = true; moved = false
        dragStart = Vector2.new(inp.Position.X, inp.Position.Y)
        posStart  = Icon.Position
    end)
    UIS.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType ~= Enum.UserInputType.MouseMovement
        and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        local delta = Vector2.new(inp.Position.X, inp.Position.Y) - dragStart
        if delta.Magnitude > THRESHOLD then moved = true end
        local vp = workspace.CurrentCamera.ViewportSize
        Icon.Position = UDim2.new(0,
            math.clamp(posStart.X.Offset + delta.X, 0, vp.X - 54), 0,
            math.clamp(posStart.Y.Offset + delta.Y, 0, vp.Y - 54))
    end)
    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1
        and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        if dragging and not moved then
            Icon.Visible = false; Main.Visible = true
            Main.Size = UDim2.new(0, 520, 0, 0)
            TweenService:Create(Main, TweenInfo.new(0.2),
                {Size = UDim2.new(0, 520, 0, 268)}):Play()
        end
        dragging = false
    end)
end

-- ── LOOPS ─────────────────────────────────────────────────────────────────────
task.spawn(function() -- HP Monitor
    while true do task.wait(0.5)
        if S.HPMonitor then
            local found = false
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("Humanoid") then
                    local n = (obj.Parent and obj.Parent.Name or ""):lower()
                    if n:find("sans") or n:find("boss") or n:find("bendy")
                    or n:find("phase") or n:find("morph") then
                        HPLbl.Text = "❤️  Boss HP : "
                            ..math.floor(obj.Health).." / "..math.floor(obj.MaxHealth)
                        found = true; break
                    end
                end
            end
            if not found then HPLbl.Text = "❤️  Boss HP : —" end
        else
            HPLbl.Text = "❤️  Boss HP : —"
       

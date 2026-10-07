-- <w> : by wleo : yoruka.id
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")
local TS = game:GetService("TweenService")
local lp = Players.LocalPlayer
local pg = lp:WaitForChild("PlayerGui")
local cam = workspace.CurrentCamera

local SEEDS = {
    {"Basic Seed Pack",{"graines basique","basic seed"},Color3.fromRGB(150,155,170)},
    {"Garden Seed Pack",{"graines de jardin","garden seed"},Color3.fromRGB(150,155,170)},
    {"Sunny Seed Pack",{"ensoleill","sunny seed"},Color3.fromRGB(70,200,120)},
    {"Floral Seed Pack",{"florale","floral seed","bloom seed"},Color3.fromRGB(70,200,120)},
    {"Crystal Seed Pack",{"cristal","crystal seed"},Color3.fromRGB(70,150,255)},
    {"Moonlight Seed Pack",{"clair de lune","moonlight seed"},Color3.fromRGB(70,150,255)},
    {"Ember Seed Pack",{"ember"},Color3.fromRGB(160,110,255)},
    {"Aurora Seed Pack",{"aurore","aurora seed"},Color3.fromRGB(160,110,255)},
    {"Golden Sun Seed Pack",{"soleil dor","golden sun"},Color3.fromRGB(255,200,60)},
    {"Dragon Seed Pack",{"dragon"},Color3.fromRGB(255,200,60)},
    {"Phoenix Seed Pack",{"phénix","phenix","phoenix"},Color3.fromRGB(255,95,70)},
    {"Cosmic Seed Pack",{"cosmique","cosmic seed"},Color3.fromRGB(255,95,70)},
    {"Mutant Seed Pack",{"mutant seed"},Color3.fromRGB(255,95,70)},
    {"Void Seed Pack",{"du vide","void seed"},Color3.fromRGB(235,235,245)},
    {"Celestial Seed Pack",{"célestes","celestes","celestial seed"},Color3.fromRGB(235,235,245)},
    {"Spooky Seed Pack",{"spooky seed"},Color3.fromRGB(255,140,40)},
}

local selected, running, delay, amount, bought = {}, false, 1, 1, 0

-- ===== logika =====
local function clean(s)
    local r = tostring(s):gsub("<[^>]+>", "")
    return r:lower()
end
local function isText(o) return o:IsA("TextLabel") or o:IsA("TextButton") end
local function seedOf(o)
    if not isText(o) then return end
    local t = clean(o.Text)
    if #t > 40 or not t:find("pack", 1, true) then return end
    for _, s in ipairs(SEEDS) do
        for _, p in ipairs(s[2]) do
            if t:find(p, 1, true) then return s[1] end
        end
    end
end
local function isBuy(o)
    if not isText(o) then return false end
    local t = clean(o.Text):gsub("^%s+", ""):gsub("%s+$", "")
    return t == "acheter" or t == "buy"
end
local function clickable(o, stop)
    local c = o
    while c and c ~= stop.Parent do
        if c:IsA("GuiButton") then return c end
        c = c.Parent
    end
end
local function rowButton(label)
    local p = label.Parent
    for _ = 1, 8 do
        if not p or p == pg then break end
        local count, buy = 0, nil
        for _, d in ipairs(p:GetDescendants()) do
            if seedOf(d) then count += 1 end
            if not buy and isBuy(d) then buy = d end
        end
        if count > 1 then return nil end
        if buy then return clickable(buy, p) end
        p = p.Parent
    end
end
local function press(btn)
    local done = false
    pcall(function()
        if firesignal then
            firesignal(btn.MouseButton1Click); firesignal(btn.Activated); done = true
        elseif getconnections then
            for _, ev in ipairs({btn.MouseButton1Click, btn.Activated}) do
                for _, c in ipairs(getconnections(ev)) do c:Fire() end
            end
            done = true
        end
    end)
    if not done then
        pcall(function()
            local p, s = btn.AbsolutePosition, btn.AbsoluteSize
            local x, y = p.X + s.X / 2, p.Y + s.Y / 2 + 36
            VIM:SendMouseButtonEvent(x, y, 0, true, game, 0)
            VIM:SendMouseButtonEvent(x, y, 0, false, game, 0)
        end)
    end
end

-- ===== helper UI =====
local function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    o.Parent = parent
    return o
end
local function round(o, r) new("UICorner", {CornerRadius = UDim.new(0, r)}, o) end
local BG, PANEL, ACC = Color3.fromRGB(16,18,26), Color3.fromRGB(30,34,48), Color3.fromRGB(60,210,130)

local parent = (gethui and gethui()) or game:GetService("CoreGui")
pcall(function() parent:FindFirstChild("YorukaAutoBuy"):Destroy() end)
local gui = new("ScreenGui", {Name="YorukaAutoBuy", ResetOnSpawn=false, IgnoreGuiInset=true, DisplayOrder=999}, parent)

local W, H = 320, 430
local function calcScale()
    local vp = cam.ViewportSize
    return math.clamp(math.min((vp.X - 20) / W, (vp.Y - 20) / H), 0.55, 1.1)
end
local baseScale = calcScale()

local main = new("Frame", {
    Size = UDim2.fromOffset(W, H), BackgroundColor3 = BG, BorderSizePixel = 0,
    Position = UDim2.fromOffset(cam.ViewportSize.X/2 - W*baseScale/2, cam.ViewportSize.Y/2 - H*baseScale/2),
}, gui)
round(main, 14)
new("UIStroke", {Color = ACC, Thickness = 1.5, Transparency = 0.4}, main)
local scale = new("UIScale", {Scale = baseScale}, main)

-- header
local header = new("Frame", {Size = UDim2.new(1,0,0,42), BackgroundColor3 = PANEL, BorderSizePixel = 0}, main)
round(header, 14)
new("Frame", {Size = UDim2.new(1,0,0,14), Position = UDim2.new(0,0,1,-14), BackgroundColor3 = PANEL, BorderSizePixel = 0}, header)
new("TextLabel", {Size=UDim2.new(1,-60,1,0), Position=UDim2.fromOffset(14,0), BackgroundTransparency=1,
    Text="🌱 Auto Buy Seeds", TextColor3=Color3.new(1,1,1), Font=Enum.Font.GothamBold, TextSize=15,
    TextXAlignment=Enum.TextXAlignment.Left}, header)
new("TextLabel", {Size=UDim2.new(1,-60,0,12), Position=UDim2.fromOffset(14,26), BackgroundTransparency=1,
    Text="yoruka.id", TextColor3=ACC, Font=Enum.Font.Gotham, TextSize=10,
    TextXAlignment=Enum.TextXAlignment.Left, ZIndex=2}, header).Position = UDim2.fromOffset(14, 27)
header:FindFirstChildWhichIsA("TextLabel").Position = UDim2.fromOffset(14, -5)

local minBtn = new("TextButton", {Size=UDim2.fromOffset(34,30), Position=UDim2.new(1,-42,0,6),
    BackgroundColor3=Color3.fromRGB(55,60,82), Text="—", TextColor3=Color3.new(1,1,1),
    Font=Enum.Font.GothamBold, TextSize=16, AutoButtonColor=true}, header)
round(minBtn, 8)

-- list
local list = new("ScrollingFrame", {Position=UDim2.fromOffset(10,50), Size=UDim2.new(1,-20,0,212),
    BackgroundTransparency=1, ScrollBarThickness=3, ScrollBarImageColor3=ACC, BorderSizePixel=0,
    AutomaticCanvasSize=Enum.AutomaticSize.Y, CanvasSize=UDim2.new()}, main)
new("UIListLayout", {Padding=UDim.new(0,5)}, list)

local rows = {}
local function paint(name)
    local r = rows[name]
    local on = selected[name]
    local tint = r.color
    TS:Create(r.btn, TweenInfo.new(0.15), {BackgroundColor3 = on and PANEL:Lerp(tint, 0.28) or PANEL}):Play()
    r.check.Text = on and "✓" or ""
    r.check.BackgroundColor3 = on and tint or Color3.fromRGB(50,55,75)
end
for _, s in ipairs(SEEDS) do
    local name, color = s[1], s[3]
    local btn = new("TextButton", {Size=UDim2.new(1,-6,0,38), BackgroundColor3=PANEL, Text="",
        AutoButtonColor=false, BorderSizePixel=0}, list)
    round(btn, 9)
    local stripe = new("Frame", {Size=UDim2.new(0,5,1,-12), Position=UDim2.fromOffset(6,6), BackgroundColor3=color, BorderSizePixel=0}, btn)
    round(stripe, 3)
    new("TextLabel", {Size=UDim2.new(1,-62,1,0), Position=UDim2.fromOffset(18,0), BackgroundTransparency=1,
        Text=name, TextColor3=Color3.new(1,1,1), Font=Enum.Font.GothamMedium, TextSize=13,
        TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd}, btn)
    local check = new("TextLabel", {Size=UDim2.fromOffset(24,24), Position=UDim2.new(1,-34,0.5,-12),
        BackgroundColor3=Color3.fromRGB(50,55,75), Text="", TextColor3=BG, Font=Enum.Font.GothamBold, TextSize=15}, btn)
    round(check, 7)
    rows[name] = {btn=btn, check=check, color=color}
    btn.MouseButton1Click:Connect(function() selected[name] = not selected[name]; paint(name) end)
end

local function mkBtn(text, pos, size, color, parentObj)
    local b = new("TextButton", {Position=pos, Size=size, BackgroundColor3=color, Text=text,
        TextColor3=Color3.new(1,1,1), Font=Enum.Font.GothamBold, TextSize=13, BorderSizePixel=0}, parentObj or main)
    round(b, 9)
    return b
end

local selAll = mkBtn("Pilih Semua", UDim2.fromOffset(10,270), UDim2.fromOffset(147,34), Color3.fromRGB(50,100,190))
local clr = mkBtn("Hapus Pilihan", UDim2.fromOffset(163,270), UDim2.fromOffset(147,34), Color3.fromRGB(150,65,75))
selAll.MouseButton1Click:Connect(function() for _, s in ipairs(SEEDS) do selected[s[1]] = true; paint(s[1]) end end)
clr.MouseButton1Click:Connect(function() for _, s in ipairs(SEEDS) do selected[s[1]] = false; paint(s[1]) end end)

-- stepper (+/-) biar gampang di HP
local function stepper(x, label, getv, setv, step, lo, hi, fmt)
    local f = new("Frame", {Position=UDim2.fromOffset(x,311), Size=UDim2.fromOffset(147,36), BackgroundColor3=PANEL, BorderSizePixel=0}, main)
    round(f, 9)
    local txt = new("TextLabel", {Size=UDim2.new(1,-76,1,0), Position=UDim2.fromOffset(38,0), BackgroundTransparency=1,
        TextColor3=Color3.new(1,1,1), Font=Enum.Font.GothamMedium, TextSize=12}, f)
    local function refresh() txt.Text = label .. "\n" .. string.format(fmt, getv()) end
    local m = mkBtn("−", UDim2.fromOffset(3,3), UDim2.fromOffset(32,30), Color3.fromRGB(55,60,82), f)
    local p = mkBtn("+", UDim2.new(1,-35,0,3), UDim2.fromOffset(32,30), Color3.fromRGB(55,60,82), f)
    m.MouseButton1Click:Connect(function() setv(math.clamp(getv() - step, lo, hi)); refresh() end)
    p.MouseButton1Click:Connect(function() setv(math.clamp(getv() + step, lo, hi)); refresh() end)
    refresh()
end
stepper(10, "Delay", function() return delay end, function(v) delay = v end, 0.5, 0.5, 30, "%.1f detik")
stepper(163, "Klik/siklus", function() return amount end, function(v) amount = v end, 1, 1, 20, "%d x")

local toggle = mkBtn("▶  START", UDim2.fromOffset(10,355), UDim2.fromOffset(300,44), ACC)
toggle.TextSize = 16; toggle.TextColor3 = BG
local status = new("TextLabel", {Position=UDim2.fromOffset(10,403), Size=UDim2.fromOffset(300,20), BackgroundTransparency=1,
    Text="Klik: 0  •  Buka shop dulu", TextColor3=Color3.fromRGB(160,170,195), Font=Enum.Font.Gotham, TextSize=12}, main)

-- ikon minimize
local icon = new("TextButton", {Size=UDim2.fromOffset(54,54), BackgroundColor3=PANEL, Text="🌱", TextSize=26,
    Visible=false, AutoButtonColor=false, BorderSizePixel=0, Position=UDim2.fromOffset(20,120)}, gui)
round(icon, 27)
new("UIStroke", {Color=ACC, Thickness=2}, icon)
local iconScale = new("UIScale", {Scale = math.clamp(baseScale, 0.8, 1.1)}, icon)
local dot = new("Frame", {Size=UDim2.fromOffset(12,12), Position=UDim2.new(1,-14,0,2), BackgroundColor3=Color3.fromRGB(150,65,75), BorderSizePixel=0}, icon)
round(dot, 6)

local function clampPos(x, y, w, h)
    local vp = cam.ViewportSize
    return math.clamp(x, 0, math.max(vp.X - w, 0)), math.clamp(y, 0, math.max(vp.Y - h, 0))
end

local function minimize()
    local p = main.AbsolutePosition
    local x, y = clampPos(p.X, p.Y, 54, 54)
    icon.Position = UDim2.fromOffset(x, y)
    TS:Create(scale, TweenInfo.new(0.15), {Scale = 0.01}):Play()
    task.delay(0.15, function() main.Visible = false; icon.Visible = true end)
end
local function restore()
    local p = icon.AbsolutePosition
    local x, y = clampPos(p.X, p.Y, W * baseScale, H * baseScale)
    main.Position = UDim2.fromOffset(x, y)
    icon.Visible = false; main.Visible = true
    scale.Scale = 0.01
    TS:Create(scale, TweenInfo.new(0.18, Enum.EasingStyle.Back), {Scale = baseScale}):Play()
end
minBtn.MouseButton1Click:Connect(minimize)

-- drag (mouse + touch)
local function drag(handle, target, onTap)
    local dragging, moved, start, startPos
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging, moved, start, startPos = true, false, i.Position, target.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if not moved and onTap then onTap() end
                end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - start
            if d.Magnitude > 6 then moved = true end
            if moved then
                target.Position = UDim2.fromOffset(startPos.X.Offset + d.X, startPos.Y.Offset + d.Y)
            end
        end
    end)
end
drag(header, main)
drag(icon, icon, restore)

-- start / stop
local function setRunning(v)
    running = v
    toggle.Text = v and "■  STOP" or "▶  START"
    TS:Create(toggle, TweenInfo.new(0.15), {BackgroundColor3 = v and Color3.fromRGB(215,70,80) or ACC}):Play()
    toggle.TextColor3 = v and Color3.new(1,1,1) or BG
    dot.BackgroundColor3 = v and ACC or Color3.fromRGB(150,65,75)
end
toggle.MouseButton1Click:Connect(function() setRunning(not running) end)

cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    baseScale = calcScale()
    if main.Visible then scale.Scale = baseScale end
end)

task.spawn(function()
    while gui.Parent do
        if running then
            local found, n = {}, 0
            for _, d in ipairs(pg:GetDescendants()) do
                local nm = seedOf(d)
                if nm and selected[nm] and not found[nm] and not d:IsDescendantOf(gui) then
                    local b = rowButton(d)
                    if b then found[nm] = b; n += 1 end
                end
            end
            for _, b in pairs(found) do
                for _ = 1, amount do
                    if not running then break end
                    press(b); bought += 1
                    task.wait(0.1)
                end
            end
            status.Text = "Klik: " .. bought .. "  •  Stok ketemu: " .. n
        end
        task.wait(delay)
    end
end)

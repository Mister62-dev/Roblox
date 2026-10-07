-- <w> : by Mister : yoruka.id
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

-- shared state (maxPer = 0 means unlimited)
local selected, running, delay, maxPer, bought = {}, false, 1, 0, 0
local tpOn, shopCF, autoShop, uiMul = true, nil, nil, 1
local cooldown = {}

-- ===== read shop UI =====
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

-- ===== teleport to shop =====
local function getHRP()
    local c = lp.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function tp(cf)
    local h = getHRP()
    if h then h.CFrame = cf; h.AssemblyLinearVelocity = Vector3.zero end
end
local function findShop()
    local best, bestScore
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            local txt = clean(d.ActionText .. " " .. d.ObjectText)
            local path = clean(d:GetFullName())
            local score = 0
            if txt:find("ouvrir") or txt:find("acheter") or txt:find("open") or txt:find("buy") then score += 1 end
            for _, k in ipairs({"seed", "graine", "boutique", "shop", "store"}) do
                if path:find(k, 1, true) or txt:find(k, 1, true) then score += 2 end
            end
            for _, k in ipairs({"sell", "vendre", "gear", "pet", "egg"}) do
                if path:find(k, 1, true) or txt:find(k, 1, true) then score -= 3 end
            end
            local part = d.Parent
            if part and part:IsA("Attachment") then part = part.Parent end
            if score > 0 and part and part:IsA("BasePart") and (not bestScore or score > bestScore) then
                best, bestScore = part, score
            end
        end
    end
    if best then return CFrame.new(best.Position + Vector3.new(0, 4, 0)) end
end
local function getShopCF()
    if shopCF then return shopCF end
    if not autoShop then autoShop = findShop() end
    return autoShop
end

-- ===== UI helpers =====
local function new(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props) do o[k] = v end
    o.Parent = parent
    return o
end
local function round(o, r) new("UICorner", {CornerRadius = UDim.new(0, r)}, o); return o end

local BG, PANEL, PANEL2 = Color3.fromRGB(16,18,26), Color3.fromRGB(30,34,48), Color3.fromRGB(40,45,64)
local ACC, WHITE, MUTED = Color3.fromRGB(60,210,130), Color3.new(1,1,1), Color3.fromRGB(160,170,195)
local OFFC = Color3.fromRGB(90,95,115)

local parent = (gethui and gethui()) or game:GetService("CoreGui")
pcall(function() parent:FindFirstChild("YorukaAutoBuy"):Destroy() end)
local gui = new("ScreenGui", {Name="YorukaAutoBuy", ResetOnSpawn=false, IgnoreGuiInset=true, DisplayOrder=999}, parent)

local W, H = 480, 320
local function calcScale()
    local vp = cam.ViewportSize
    local fit = math.min((vp.X - 16) / W, (vp.Y - 16) / H)
    return math.clamp(fit, 0.45, 1.15) * uiMul
end
local baseScale = calcScale()

local main = round(new("Frame", {
    Size = UDim2.fromOffset(W, H), BackgroundColor3 = BG, BorderSizePixel = 0,
    Position = UDim2.fromOffset(cam.ViewportSize.X/2 - W*baseScale/2, cam.ViewportSize.Y/2 - H*baseScale/2),
}, gui), 14)
new("UIStroke", {Color = ACC, Thickness = 1.5, Transparency = 0.4}, main)
local scale = new("UIScale", {Scale = baseScale}, main)

local header = round(new("Frame", {Size = UDim2.new(1,0,0,40), BackgroundColor3 = PANEL, BorderSizePixel = 0}, main), 14)
new("Frame", {Size = UDim2.new(1,0,0,14), Position = UDim2.new(0,0,1,-14), BackgroundColor3 = PANEL, BorderSizePixel = 0}, header)
new("TextLabel", {Size=UDim2.new(1,-70,0,20), Position=UDim2.fromOffset(14,3), BackgroundTransparency=1,
    Text="🌱 Garden Hub", TextColor3=WHITE, Font=Enum.Font.GothamBold, TextSize=15,
    TextXAlignment=Enum.TextXAlignment.Left}, header)
new("TextLabel", {Size=UDim2.new(1,-70,0,12), Position=UDim2.fromOffset(14,23), BackgroundTransparency=1,
    Text="by Mister • yoruka.id", TextColor3=ACC, Font=Enum.Font.Gotham, TextSize=10,
    TextXAlignment=Enum.TextXAlignment.Left}, header)
local minBtn = round(new("TextButton", {Size=UDim2.fromOffset(36,28), Position=UDim2.new(1,-44,0,6),
    BackgroundColor3=Color3.fromRGB(55,60,82), Text="—", TextColor3=WHITE,
    Font=Enum.Font.GothamBold, TextSize=16}, header), 8)

local sideW = 112
local sidebar = round(new("ScrollingFrame", {Position=UDim2.fromOffset(8,48), Size=UDim2.new(0,sideW,1,-56),
    BackgroundColor3=PANEL, BorderSizePixel=0, ScrollBarThickness=0,
    AutomaticCanvasSize=Enum.AutomaticSize.Y, CanvasSize=UDim2.new()}, main), 10)
new("UIListLayout", {Padding=UDim.new(0,6)}, sidebar)
new("UIPadding", {PaddingTop=UDim.new(0,6), PaddingLeft=UDim.new(0,6), PaddingRight=UDim.new(0,6), PaddingBottom=UDim.new(0,6)}, sidebar)

local body = new("Frame", {Position=UDim2.fromOffset(sideW+16,48), Size=UDim2.new(1,-(sideW+24),1,-56),
    BackgroundTransparency=1, ClipsDescendants=true}, main)

local tabs = {}
local function selectTab(name)
    for n, t in pairs(tabs) do
        local on = (n == name)
        t.page.Visible = on
        TS:Create(t.btn, TweenInfo.new(0.15), {BackgroundColor3 = on and ACC or PANEL2}):Play()
        t.btn.TextColor3 = on and BG or WHITE
    end
end
local function addTab(icon, name)
    local btn = round(new("TextButton", {Size=UDim2.new(1,0,0,40), BackgroundColor3=PANEL2, Text=icon.."  "..name,
        TextColor3=WHITE, Font=Enum.Font.GothamBold, TextSize=13, BorderSizePixel=0,
        TextXAlignment=Enum.TextXAlignment.Left}, sidebar), 8)
    new("UIPadding", {PaddingLeft=UDim.new(0,10)}, btn)
    local page = new("Frame", {Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Visible=false}, body)
    tabs[name] = {btn=btn, page=page}
    btn.MouseButton1Click:Connect(function() selectTab(name) end)
    return page
end

-- reusable components (use them for your own tabs)
local function scrollPage(page)
    local s = new("ScrollingFrame", {Size=UDim2.fromScale(1,1), BackgroundTransparency=1, BorderSizePixel=0,
        ScrollBarThickness=3, ScrollBarImageColor3=ACC, AutomaticCanvasSize=Enum.AutomaticSize.Y, CanvasSize=UDim2.new()}, page)
    new("UIListLayout", {Padding=UDim.new(0,6)}, s)
    return s
end
local function section(sp, text)
    new("TextLabel", {Size=UDim2.new(1,-6,0,20), BackgroundTransparency=1, Text=text:upper(), TextColor3=ACC,
        Font=Enum.Font.GothamBold, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left}, sp)
end
local function rowFrame(sp, h)
    return round(new("Frame", {Size=UDim2.new(1,-6,0,h), BackgroundColor3=PANEL, BorderSizePixel=0}, sp), 9)
end
local function rowLabels(r, title, sub, rightPad)
    new("TextLabel", {Size=UDim2.new(1,-rightPad,0,sub and 20 or 46), Position=UDim2.fromOffset(12, sub and 6 or 0),
        BackgroundTransparency=1, Text=title, TextColor3=WHITE, Font=Enum.Font.GothamMedium, TextSize=13,
        TextXAlignment=Enum.TextXAlignment.Left}, r)
    if sub then
        new("TextLabel", {Size=UDim2.new(1,-rightPad,0,16), Position=UDim2.fromOffset(12,25), BackgroundTransparency=1,
            Text=sub, TextColor3=MUTED, Font=Enum.Font.Gotham, TextSize=10, TextXAlignment=Enum.TextXAlignment.Left}, r)
    end
end
local function toggleRow(sp, title, sub, default, cb)
    local r = rowFrame(sp, 46)
    rowLabels(r, title, sub, 76)
    local state = default
    local sw = round(new("Frame", {Size=UDim2.fromOffset(46,24), Position=UDim2.new(1,-58,0.5,-12),
        BackgroundColor3 = state and ACC or OFFC, BorderSizePixel=0}, r), 12)
    local knob = round(new("Frame", {Size=UDim2.fromOffset(18,18), Position = state and UDim2.fromOffset(25,3) or UDim2.fromOffset(3,3),
        BackgroundColor3=WHITE, BorderSizePixel=0}, sw), 9)
    local hit = new("TextButton", {Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Text=""}, r)
    hit.MouseButton1Click:Connect(function()
        state = not state
        TS:Create(sw, TweenInfo.new(0.15), {BackgroundColor3 = state and ACC or OFFC}):Play()
        TS:Create(knob, TweenInfo.new(0.15), {Position = state and UDim2.fromOffset(25,3) or UDim2.fromOffset(3,3)}):Play()
        cb(state)
    end)
end
local function stepperRow(sp, title, sub, getv, setv, step, lo, hi, fmt)
    local r = rowFrame(sp, 46)
    rowLabels(r, title, sub, 160)
    local function show() return type(fmt) == "function" and fmt(getv()) or string.format(fmt, getv()) end
    local val = new("TextLabel", {Size=UDim2.fromOffset(62,30), Position=UDim2.new(1,-104,0.5,-15), BackgroundTransparency=1,
        Text=show(), TextColor3=ACC, Font=Enum.Font.GothamBold, TextSize=12}, r)
    local function mk(txt, x)
        return round(new("TextButton", {Size=UDim2.fromOffset(32,30), Position=x, BackgroundColor3=PANEL2, Text=txt,
            TextColor3=WHITE, Font=Enum.Font.GothamBold, TextSize=16, BorderSizePixel=0}, r), 8)
    end
    local m, p = mk("−", UDim2.new(1,-138,0.5,-15)), mk("+", UDim2.new(1,-40,0.5,-15))
    m.MouseButton1Click:Connect(function() setv(math.clamp(getv() - step, lo, hi)); val.Text = show() end)
    p.MouseButton1Click:Connect(function() setv(math.clamp(getv() + step, lo, hi)); val.Text = show() end)
end
local function buttonRow(sp, text, color, cb)
    local b = round(new("TextButton", {Size=UDim2.new(1,-6,0,40), BackgroundColor3=color, Text=text, TextColor3=WHITE,
        Font=Enum.Font.GothamBold, TextSize=13, BorderSizePixel=0}, sp), 9)
    b.MouseButton1Click:Connect(function() cb(b) end)
    return b
end

local function clampPos(x, y, w, h)
    local vp = cam.ViewportSize
    return math.clamp(x, 0, math.max(vp.X - w, 0)), math.clamp(y, 0, math.max(vp.Y - h, 0))
end
local function refit()
    baseScale = calcScale()
    if main.Visible then
        scale.Scale = baseScale
        local p = main.AbsolutePosition
        local x, y = clampPos(p.X, p.Y, W * baseScale, H * baseScale)
        main.Position = UDim2.fromOffset(x, y)
    end
end

-- ===================== TAB 1: AUTO BUY SEEDS =====================
local buyPage = addTab("🌱", "Auto Buy")

local rows = {}
local function paint(name)
    local r, on = rows[name], selected[name]
    TS:Create(r.btn, TweenInfo.new(0.15), {BackgroundColor3 = on and PANEL:Lerp(r.color, 0.28) or PANEL}):Play()
    r.check.Text = on and "✓" or ""
    r.check.BackgroundColor3 = on and r.color or Color3.fromRGB(50,55,75)
end

local function smallBtn(text, pos, size, color, parentObj)
    return round(new("TextButton", {Position=pos, Size=size, BackgroundColor3=color, Text=text, TextColor3=WHITE,
        Font=Enum.Font.GothamBold, TextSize=13, BorderSizePixel=0}, parentObj), 9)
end
local selAll = smallBtn("Select All", UDim2.fromOffset(0,0), UDim2.new(0.5,-3,0,34), Color3.fromRGB(50,100,190), buyPage)
local clr = smallBtn("Clear", UDim2.new(0.5,3,0,0), UDim2.new(0.5,-3,0,34), Color3.fromRGB(150,65,75), buyPage)
selAll.MouseButton1Click:Connect(function() for _, s in ipairs(SEEDS) do selected[s[1]] = true; paint(s[1]) end end)
clr.MouseButton1Click:Connect(function() for _, s in ipairs(SEEDS) do selected[s[1]] = false; paint(s[1]) end end)

local list = new("ScrollingFrame", {Position=UDim2.fromOffset(0,40), Size=UDim2.new(1,0,1,-96),
    BackgroundTransparency=1, ScrollBarThickness=3, ScrollBarImageColor3=ACC, BorderSizePixel=0,
    AutomaticCanvasSize=Enum.AutomaticSize.Y, CanvasSize=UDim2.new()}, buyPage)
new("UIListLayout", {Padding=UDim.new(0,5)}, list)

for _, s in ipairs(SEEDS) do
    local name, color = s[1], s[3]
    local btn = round(new("TextButton", {Size=UDim2.new(1,-6,0,38), BackgroundColor3=PANEL, Text="",
        AutoButtonColor=false, BorderSizePixel=0}, list), 9)
    round(new("Frame", {Size=UDim2.new(0,5,1,-12), Position=UDim2.fromOffset(6,6), BackgroundColor3=color, BorderSizePixel=0}, btn), 3)
    new("TextLabel", {Size=UDim2.new(1,-62,1,0), Position=UDim2.fromOffset(18,0), BackgroundTransparency=1,
        Text=name, TextColor3=WHITE, Font=Enum.Font.GothamMedium, TextSize=13,
        TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd}, btn)
    local check = round(new("TextLabel", {Size=UDim2.fromOffset(24,24), Position=UDim2.new(1,-34,0.5,-12),
        BackgroundColor3=Color3.fromRGB(50,55,75), Text="", TextColor3=BG, Font=Enum.Font.GothamBold, TextSize=15}, btn), 7)
    rows[name] = {btn=btn, check=check, color=color}
    btn.MouseButton1Click:Connect(function() selected[name] = not selected[name]; paint(name) end)
end

local bar = new("Frame", {Position=UDim2.new(0,0,1,-50), Size=UDim2.new(1,0,0,50), BackgroundTransparency=1}, buyPage)
local toggle = smallBtn("▶  START", UDim2.fromOffset(0,3), UDim2.new(0.5,-3,0,44), ACC, bar)
toggle.TextSize = 16; toggle.TextColor3 = BG
local status = new("TextLabel", {Position=UDim2.new(0.5,6,0,3), Size=UDim2.new(0.5,-6,0,44), BackgroundTransparency=1,
    Text="Clicks: 0\nReady", TextColor3=MUTED, Font=Enum.Font.Gotham, TextSize=12, TextWrapped=true,
    TextXAlignment=Enum.TextXAlignment.Left}, bar)

-- ===================== TAB 2: SETTINGS =====================
local setPage = scrollPage(addTab("⚙", "Settings"))

section(setPage, "Auto buy")
stepperRow(setPage, "Check delay", "Time between stock checks", function() return delay end,
    function(v) delay = v end, 0.5, 0.5, 30, "%.1f s")
stepperRow(setPage, "Max buys / pack", "∞ = unlimited (buys until out of stock)", function() return maxPer end,
    function(v) maxPer = v end, 1, 0, 100, function(v) return v == 0 and "∞" or (v .. " x") end)

section(setPage, "Teleport")
toggleRow(setPage, "TP to shop", "One trip: buy everything, then return", tpOn, function(v) tpOn = v end)
buttonRow(setPage, "📍 Save shop position", Color3.fromRGB(110,90,180), function(b)
    local h = getHRP()
    if h then
        shopCF = h.CFrame
        b.Text = "✓ Saved"
        task.delay(1.5, function() b.Text = "📍 Save shop position" end)
    end
end)
buttonRow(setPage, "Reset shop position (auto-detect)", Color3.fromRGB(70,75,100), function(b)
    shopCF, autoShop = nil, nil
    b.Text = "✓ Reset"
    task.delay(1.5, function() b.Text = "Reset shop position (auto-detect)" end)
end)

section(setPage, "Interface")
stepperRow(setPage, "UI size", "Make the window smaller on small screens", function() return uiMul end,
    function(v) uiMul = math.floor(v * 10 + 0.5) / 10; refit() end, 0.1, 0.6, 1, function(v) return math.floor(v * 100 + 0.5) .. "%" end)
buttonRow(setPage, "Destroy GUI", Color3.fromRGB(170,55,65), function()
    running = false
    gui:Destroy()
end)

-- ===== ADD YOUR NEW TABS BELOW =====
-- local page = scrollPage(addTab("🧺", "Harvest"))
-- section(page, "Harvest")
-- toggleRow(page, "Auto harvest", "Collect ripe plants", false, function(v) end)

selectTab("Auto Buy")

-- ===== minimize icon =====
local icon = round(new("TextButton", {Size=UDim2.fromOffset(54,54), BackgroundColor3=PANEL, Text="🌱", TextSize=26,
    Visible=false, AutoButtonColor=false, BorderSizePixel=0, Position=UDim2.fromOffset(20,120)}, gui), 27)
new("UIStroke", {Color=ACC, Thickness=2}, icon)
local dot = round(new("Frame", {Size=UDim2.fromOffset(12,12), Position=UDim2.new(1,-14,0,2),
    BackgroundColor3=Color3.fromRGB(150,65,75), BorderSizePixel=0}, icon), 6)

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
            if moved then target.Position = UDim2.fromOffset(startPos.X.Offset + d.X, startPos.Y.Offset + d.Y) end
        end
    end)
end
drag(header, main)
drag(icon, icon, restore)

local function setRunning(v)
    running = v
    toggle.Text = v and "■  STOP" or "▶  START"
    TS:Create(toggle, TweenInfo.new(0.15), {BackgroundColor3 = v and Color3.fromRGB(215,70,80) or ACC}):Play()
    toggle.TextColor3 = v and WHITE or BG
    dot.BackgroundColor3 = v and ACC or Color3.fromRGB(150,65,75)
end
toggle.MouseButton1Click:Connect(function() setRunning(not running) end)
cam:GetPropertyChangedSignal("ViewportSize"):Connect(refit)

-- ===== main loop (Auto Buy) =====
local function scan()
    local found, n, now = {}, 0, os.clock()
    for _, d in ipairs(pg:GetDescendants()) do
        local nm = seedOf(d)
        if nm and selected[nm] and not found[nm] and (cooldown[nm] or 0) < now and not d:IsDescendantOf(gui) then
            local b = rowButton(d)
            if b then found[nm] = b; n += 1 end
        end
    end
    return found, n
end

local VISIT_LIMIT = 40 -- seconds max per shop visit (safety if you can't afford a pack)

task.spawn(function()
    while gui.Parent do
        if running then
            local found, n = scan()
            if n > 0 then
                -- ONE trip: go to the shop once
                local origin, moved = nil, false
                if tpOn then
                    local h, scf = getHRP(), getShopCF()
                    if not scf then
                        status.Text = "Clicks: " .. bought .. "\nShop not found: save position in Settings"
                    elseif h and (h.Position - scf.Position).Magnitude > 20 then
                        origin = h.CFrame
                        tp(scf)
                        moved = true
                        task.wait(0.5)
                    end
                end

                -- stay and buy until out of stock (unlimited when maxPer = 0)
                local clicks, t0 = {}, os.clock()
                while running and os.clock() - t0 < VISIT_LIMIT do
                    for name, b in pairs(found) do
                        if maxPer > 0 and (clicks[name] or 0) >= maxPer then
                            cooldown[name] = os.clock() + 60
                        else
                            press(b)
                            clicks[name] = (clicks[name] or 0) + 1
                            bought += 1
                            status.Text = "Clicks: " .. bought .. "\nBuying: " .. name:gsub(" Seed Pack", "")
                            task.wait(0.15)
                        end
                    end
                    task.wait(0.2)
                    local nn
                    found, nn = scan()
                    if nn == 0 then break end
                end

                -- time ran out and packs are still "in stock" (probably can't afford): pause them
                if os.clock() - t0 >= VISIT_LIMIT then
                    for name in pairs(found) do cooldown[name] = os.clock() + 60 end
                end

                -- return once, when everything is bought
                if moved then
                    task.wait(0.25)
                    tp(origin)
                end
                status.Text = "Clicks: " .. bought .. "\nDone, waiting for restock"
            else
                status.Text = "Clicks: " .. bought .. "\nWaiting for stock..."
            end
        end
        task.wait(delay)
    end
end)

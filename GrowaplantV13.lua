-- <w> : by Mister : yoruka.id
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local VU = game:GetService("VirtualUser")
local TS = game:GetService("TweenService")
local lp = Players.LocalPlayer
local pg = lp:WaitForChild("PlayerGui")
local cam = workspace.CurrentCamera

local SEEDS = {
    {"Basic Seed Pack",{"graines basique","basic seed"},Color3.fromRGB(150,155,170)},
    {"Garden Seed Pack",{"graines de jardin","garden seed"},Color3.fromRGB(150,155,170)},
    {"Sunny Seed Pack",{"ensoleill","sunny seed"},Color3.fromRGB(70,200,120)},
    {"Floral Seed Pack",{"florale","floral seed","bloom seed"},Color3.fromRGB(70,200,120)},
    {"Crystal Seed Pack",{"cristal","crystal"},Color3.fromRGB(70,150,255)},
    {"Moonlight Seed Pack",{"clair de lune","moonlight seed"},Color3.fromRGB(70,150,255)},
    {"Ember Seed Pack",{"ember"},Color3.fromRGB(160,110,255)},
    {"Aurora Seed Pack",{"aurore","aurora seed"},Color3.fromRGB(160,110,255)},
    {"Golden Sun Seed Pack",{"soleil dor","golden sun"},Color3.fromRGB(255,200,60)},
    {"Dragon Seed Pack",{"dragon"},Color3.fromRGB(255,200,60)},
    {"Phoenix Seed Pack",{"ph\u{E9}nix","phenix","phoenix"},Color3.fromRGB(255,95,70)},
    {"Cosmic Seed Pack",{"cosmique","cosmic seed"},Color3.fromRGB(255,95,70)},
    {"Mutant Seed Pack",{"mutant seed"},Color3.fromRGB(255,95,70)},
    {"Void Seed Pack",{"du vide","void seed"},Color3.fromRGB(235,235,245)},
    {"Celestial Seed Pack",{"c\u{E9}lestes","celestes","celestial seed"},Color3.fromRGB(235,235,245)},
    {"Spooky Seed Pack",{"spooky seed"},Color3.fromRGB(255,140,40)},
}

-- shared state (maxPer = 0 means unlimited)
local selected, running, delay, maxPer, bought = {}, false, 1, 0, 0
local tpOn, shopCF, autoShop, uiMul = true, nil, nil, 1
local confirmOn, verbose, antiAfk = true, false, true
local cooldown = {}
local gui, logBox, logScroll

-- ===== debug log =====
local logLines = {}
local function log(msg)
    table.insert(logLines, string.format("[%s] %s", os.date("%M:%S"), tostring(msg)))
    if #logLines > 120 then table.remove(logLines, 1) end
    if logBox then
        logBox.Text = table.concat(logLines, "\n")
        task.defer(function() if logScroll then logScroll.CanvasPosition = Vector2.new(0, 1e5) end end)
    end
end

-- ===== read shop UI =====
local function clean(s)
    local r = tostring(s):gsub("<[^>]+>", "")
    return r:lower()
end
local function isText(o) return o:IsA("TextLabel") or o:IsA("TextButton") end
local function seedOf(o)
    if not isText(o) then return end
    local t = clean(o.Text)
    if #t > 80 then return end
    -- accept "pack" / "paquet" / "seed" / "graine" so a pack label is not skipped by wording
    if not (t:find("pack", 1, true) or t:find("paquet", 1, true)
        or t:find("seed", 1, true) or t:find("graine", 1, true)) then return end
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
-- returns the BUY button and the row that contains it
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
        if buy then return clickable(buy, p), p end
        p = p.Parent
    end
end
-- reads the "x2 Stock" / "x6 R\u{E9}serve" number of a row
local function stockOf(row)
    for _, d in ipairs(row:GetDescendants()) do
        if isText(d) then
            local n = clean(d.Text):match("^x(%d+)")
            if n then return tonumber(n) end
        end
    end
end
local function describe(o)
    local t = o:IsA("TextButton") and clean(o.Text) or ""
    local p = o:GetFullName():gsub("^Players%.[^%.]+%.PlayerGui%.", "")
    if #p > 70 then p = "\u{2026}" .. p:sub(-69) end
    return o.ClassName .. " '" .. t .. "' " .. p
end

-- ===== choosing the REAL row (ignores hidden template rows) =====
local SIGNALS = {"MouseButton1Click", "Activated", "MouseButton1Down", "MouseButton1Up"}
local function handlerCount(btn)
    if not getconnections then return nil end
    local n = 0
    for _, sig in ipairs(SIGNALS) do
        local ok, t = pcall(function() return #getconnections(btn[sig]) end)
        if ok then n += t end
    end
    return n
end
local function scoreOf(c)
    local s = 0
    local hc = handlerCount(c.b)
    if hc and hc > 0 then s += 10 end                 -- a real row has a click handler
    if c.row:IsA("GuiObject") and c.row.Visible and c.b.Visible then s += 2 end
    if c.row:IsA("GuiObject") and c.row.AbsoluteSize.Y > 0 then s += 1 end
    if c.row.Name:lower():find("template") then s -= 1 end
    return s
end
local function pick(list)
    local best, bs
    for _, c in ipairs(list) do
        local s = scoreOf(c)
        if not bs or s > bs then best, bs = c, s end
    end
    return best
end
local function candidatesOf(name)
    local list = {}
    for _, d in ipairs(pg:GetDescendants()) do
        if seedOf(d) == name and not (gui and d:IsDescendantOf(gui)) then
            local b, row = rowButton(d)
            if b then table.insert(list, {b = b, row = row}) end
        end
    end
    return list
end
local function findPack(name)
    return pick(candidatesOf(name))
end

-- ===== pressing buttons (single click method: Click + Activated) =====
local function press(btn)
    for _, name in ipairs({"MouseButton1Click", "Activated"}) do
        pcall(function()
            local sig = btn[name]
            if firesignal then
                firesignal(sig)
            elseif getconnections then
                for _, c in ipairs(getconnections(sig)) do c:Fire() end
            end
        end)
    end
end

-- auto-click "Confirm / Yes / OK" popups that appear after pressing BUY
local CONFIRM = {confirm=true, confirmer=true, yes=true, oui=true, ok=true, proceed=true,
    purchase=true, ["confirm purchase"]=true}
local function visibleChain(o)
    local c = o
    while c and c ~= pg do
        if c:IsA("GuiObject") and not c.Visible then return false end
        if c:IsA("ScreenGui") and not c.Enabled then return false end
        c = c.Parent
    end
    return true
end
local function confirmPopups()
    for _, d in ipairs(pg:GetDescendants()) do
        if isText(d) and not (gui and d:IsDescendantOf(gui)) then
            local t = clean(d.Text):gsub("^%s+", ""):gsub("%s+$", "")
            if CONFIRM[t] and visibleChain(d) then
                local b = d
                for _ = 1, 3 do
                    if b and not b:IsA("GuiButton") then b = b.Parent end
                end
                if b and b:IsA("GuiButton") then
                    press(b)
                    log("Popup confirmed: " .. t)
                    return true
                end
            end
        end
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
gui = new("ScreenGui", {Name="YorukaAutoBuy", ResetOnSpawn=false, IgnoreGuiInset=true, DisplayOrder=999}, parent)

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
    Text="\u{1F331} Garden Hub", TextColor3=WHITE, Font=Enum.Font.GothamBold, TextSize=15,
    TextXAlignment=Enum.TextXAlignment.Left}, header)
new("TextLabel", {Size=UDim2.new(1,-70,0,12), Position=UDim2.fromOffset(14,23), BackgroundTransparency=1,
    Text="by Mister \u{2022} yoruka.id", TextColor3=ACC, Font=Enum.Font.Gotham, TextSize=10,
    TextXAlignment=Enum.TextXAlignment.Left}, header)
local minBtn = round(new("TextButton", {Size=UDim2.fromOffset(36,28), Position=UDim2.new(1,-44,0,6),
    BackgroundColor3=Color3.fromRGB(55,60,82), Text="\u{2014}", TextColor3=WHITE,
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
    local m, p = mk("\u{2212}", UDim2.new(1,-138,0.5,-15)), mk("+", UDim2.new(1,-40,0.5,-15))
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
local buyPage = addTab("\u{1F331}", "Auto Buy")

local rows = {}
local function paint(name)
    local r, on = rows[name], selected[name]
    TS:Create(r.btn, TweenInfo.new(0.15), {BackgroundColor3 = on and PANEL:Lerp(r.color, 0.28) or PANEL}):Play()
    r.check.Text = on and "\u{2713}" or ""
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
local toggle = smallBtn("\u{25B6}  START", UDim2.fromOffset(0,3), UDim2.new(0.5,-3,0,44), ACC, bar)
toggle.TextSize = 16; toggle.TextColor3 = BG
local status = new("TextLabel", {Position=UDim2.new(0.5,6,0,3), Size=UDim2.new(0.5,-6,0,44), BackgroundTransparency=1,
    Text="Clicks: 0\nReady", TextColor3=MUTED, Font=Enum.Font.Gotham, TextSize=12, TextWrapped=true,
    TextXAlignment=Enum.TextXAlignment.Left}, bar)

-- ===================== TAB 2: SETTINGS =====================
local setPage = scrollPage(addTab("\u{2699}", "Settings"))

section(setPage, "Auto buy")
stepperRow(setPage, "Check delay", "Time between stock checks", function() return delay end,
    function(v) delay = v end, 0.5, 0.5, 30, "%.1f s")
stepperRow(setPage, "Max buys / pack", "\u{221E} = unlimited (buys until out of stock)", function() return maxPer end,
    function(v) maxPer = v end, 1, 0, 100, function(v) return v == 0 and "\u{221E}" or (v .. " x") end)
toggleRow(setPage, "Auto-confirm popups", "Clicks Confirm / Yes / OK if a popup appears", confirmOn, function(v) confirmOn = v end)

section(setPage, "Teleport")
toggleRow(setPage, "TP to shop", "One trip: buy everything, then return", tpOn, function(v) tpOn = v end)
buttonRow(setPage, "\u{1F4CD} Save shop position", Color3.fromRGB(110,90,180), function(b)
    local h = getHRP()
    if h then
        shopCF = h.CFrame
        b.Text = "\u{2713} Saved"
        task.delay(1.5, function() b.Text = "\u{1F4CD} Save shop position" end)
    end
end)
buttonRow(setPage, "Reset shop position (auto-detect)", Color3.fromRGB(70,75,100), function(b)
    shopCF, autoShop = nil, nil
    b.Text = "\u{2713} Reset"
    task.delay(1.5, function() b.Text = "Reset shop position (auto-detect)" end)
end)

section(setPage, "Utility")
toggleRow(setPage, "Anti AFK", "Stops the game from kicking you for idling", antiAfk, function(v) antiAfk = v end)

section(setPage, "Interface")
stepperRow(setPage, "UI size", "Make the window smaller on small screens", function() return uiMul end,
    function(v) uiMul = math.floor(v * 10 + 0.5) / 10; refit() end, 0.1, 0.6, 1, function(v) return math.floor(v * 100 + 0.5) .. "%" end)
buttonRow(setPage, "Destroy GUI", Color3.fromRGB(170,55,65), function()
    running = false
    gui:Destroy()
end)

-- ===================== TAB 3: DEBUG =====================
local dbgPage = addTab("\u{1F41E}", "Debug")

local function testPress()
    task.spawn(function()
        local name
        for _, s in ipairs(SEEDS) do
            if selected[s[1]] then name = s[1]; break end
        end
        name = name or "Crystal Seed Pack"
        log("TEST " .. name .. " (shop must be open)")
        local list = candidatesOf(name)
        if #list == 0 then
            log("TEST: no BUY button found (sold out, shop closed, or name not matched)")
            return
        end
        for i, c in ipairs(list) do
            log(string.format("  cand %d: score=%d handlers=%s %s", i, scoreOf(c), tostring(handlerCount(c.b)), describe(c.b)))
        end
        local e = pick(list)
        local before = stockOf(e.row)
        log("TEST chosen: " .. describe(e.b) .. " stock=" .. tostring(before))
        press(e.b)
        task.wait(1.2)
        log("  press: stock " .. tostring(before) .. " -> " .. tostring(stockOf(e.row)))
        log("TEST done")
    end)
end

local testBtn = smallBtn("Test press (1st selected pack)", UDim2.fromOffset(0,0), UDim2.new(1,0,0,34), Color3.fromRGB(110,90,180), dbgPage)
local copyBtn = smallBtn("Copy log", UDim2.fromOffset(0,40), UDim2.new(0.3333,-3,0,34), Color3.fromRGB(50,100,190), dbgPage)
local clearBtn = smallBtn("Clear", UDim2.new(0.3333,1,0,40), UDim2.new(0.3333,-3,0,34), Color3.fromRGB(150,65,75), dbgPage)
local verBtn = smallBtn("Verbose: OFF", UDim2.new(0.6666,2,0,40), UDim2.new(0.3334,-2,0,34), Color3.fromRGB(70,75,100), dbgPage)
testBtn.MouseButton1Click:Connect(testPress)
copyBtn.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(table.concat(logLines, "\n"))
        copyBtn.Text = "\u{2713} Copied"
    else
        copyBtn.Text = "No clipboard"
    end
    task.delay(1.5, function() copyBtn.Text = "Copy log" end)
end)
clearBtn.MouseButton1Click:Connect(function() logLines = {}; logBox.Text = "" end)
verBtn.MouseButton1Click:Connect(function()
    verbose = not verbose
    verBtn.Text = verbose and "Verbose: ON" or "Verbose: OFF"
    TS:Create(verBtn, TweenInfo.new(0.15), {BackgroundColor3 = verbose and Color3.fromRGB(50,140,110) or Color3.fromRGB(70,75,100)}):Play()
end)

logScroll = round(new("ScrollingFrame", {Position=UDim2.fromOffset(0,80), Size=UDim2.new(1,0,1,-80),
    BackgroundColor3=PANEL, BorderSizePixel=0, ScrollBarThickness=3, ScrollBarImageColor3=ACC,
    AutomaticCanvasSize=Enum.AutomaticSize.Y, CanvasSize=UDim2.new()}, dbgPage), 8)
logBox = new("TextLabel", {Size=UDim2.new(1,-12,0,0), Position=UDim2.fromOffset(6,4), AutomaticSize=Enum.AutomaticSize.Y,
    BackgroundTransparency=1, Text="", TextColor3=MUTED, Font=Enum.Font.Code, TextSize=10, TextWrapped=true,
    TextXAlignment=Enum.TextXAlignment.Left, TextYAlignment=Enum.TextYAlignment.Top}, logScroll)
log("Ready.")

-- ===== ADD YOUR NEW TABS BELOW =====
-- local page = scrollPage(addTab("\u{1F9FA}", "Harvest"))
-- section(page, "Harvest")
-- toggleRow(page, "Auto harvest", "Collect ripe plants", false, function(v) end)

selectTab("Auto Buy")

-- ===== minimize icon =====
local icon = round(new("TextButton", {Size=UDim2.fromOffset(54,54), BackgroundColor3=PANEL, Text="\u{1F331}", TextSize=26,
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
    toggle.Text = v and "\u{25A0}  STOP" or "\u{25B6}  START"
    TS:Create(toggle, TweenInfo.new(0.15), {BackgroundColor3 = v and Color3.fromRGB(215,70,80) or ACC}):Play()
    toggle.TextColor3 = v and WHITE or BG
    dot.BackgroundColor3 = v and ACC or Color3.fromRGB(150,65,75)
end
toggle.MouseButton1Click:Connect(function() setRunning(not running) end)
cam:GetPropertyChangedSignal("ViewportSize"):Connect(refit)

-- ===== anti AFK =====
local function nudge()
    pcall(function()
        VU:CaptureController()
        VU:ClickButton2(Vector2.new())
    end)
end
local idleConn = lp.Idled:Connect(function() if antiAfk then nudge() end end)
task.spawn(function()
    while gui.Parent do
        for _ = 1, 55 do
            if not gui.Parent then break end
            task.wait(1)
        end
        if gui.Parent and antiAfk then nudge() end
    end
    idleConn:Disconnect()
end)

-- ===== main loop (Auto Buy) =====
local function scan()
    local cands, now = {}, os.clock()
    for _, d in ipairs(pg:GetDescendants()) do
        local nm = seedOf(d)
        if nm and selected[nm] and (cooldown[nm] or 0) < now and not d:IsDescendantOf(gui) then
            local b, row = rowButton(d)
            if b then
                cands[nm] = cands[nm] or {}
                table.insert(cands[nm], {b = b, row = row})
            end
        end
    end
    local found, n = {}, 0
    for nm, list in pairs(cands) do
        found[nm] = pick(list) -- real row wins over hidden template rows
        n += 1
    end
    return found, n
end

local VISIT_LIMIT = 45   -- max seconds per shop visit
local STUCK_PRESSES = 6  -- presses with no stock change before skipping that pack

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
                log("Visit: " .. n .. " pack(s) in stock" .. (moved and " (teleported)" or ""))

                -- stay and buy until out of stock (unlimited when maxPer = 0)
                local clicks, stuck, t0, note = {}, {}, os.clock(), nil
                while running and os.clock() - t0 < VISIT_LIMIT do
                    for name, e in pairs(found) do
                        local short = (name:gsub(" Seed Pack", ""))
                        if maxPer > 0 and (clicks[name] or 0) >= maxPer then
                            cooldown[name] = os.clock() + 60
                        else
                            -- the shop may rebuild its rows: refresh a destroyed button
                            if not e.b:IsDescendantOf(pg) then
                                local ne = findPack(name)
                                if ne then found[name] = ne; e = ne else e = nil end
                            end
                            if e then
                                local st = stockOf(e.row)
                                local s = stuck[name]
                                if not s then
                                    s = {stock = st, n = 0}
                                    stuck[name] = s
                                    log(short .. ": " .. describe(e.b) .. " stock=" .. tostring(st))
                                end
                                if st ~= s.stock then
                                    if verbose then log(short .. ": stock " .. tostring(s.stock) .. " -> " .. tostring(st)) end
                                    s.stock, s.n = st, 0
                                end

                                if st and s.n >= STUCK_PRESSES then
                                    cooldown[name] = os.clock() + 120
                                    note = short .. " skipped: not responding"
                                    log(note .. " (stock stayed " .. tostring(st) .. ")")
                                else
                                    press(e.b)
                                    s.n += 1
                                    clicks[name] = (clicks[name] or 0) + 1
                                    bought += 1
                                    if verbose then log("press " .. short .. " #" .. clicks[name]) end
                                    status.Text = "Clicks: " .. bought .. "\nBuying: " .. short
                                    if confirmOn and s.n >= 2 and s.n % 2 == 0 then
                                        task.wait(0.1)
                                        confirmPopups()
                                    end
                                    task.wait(0.15)
                                end
                            end
                        end
                    end
                    task.wait(0.2)
                    local nn
                    found, nn = scan()
                    if nn == 0 then break end
                end

                -- time ran out and packs are still "in stock": pause them
                if os.clock() - t0 >= VISIT_LIMIT then
                    for name in pairs(found) do cooldown[name] = os.clock() + 60 end
                    log("Visit time limit reached")
                end

                -- return once, when everything is bought
                if moved then
                    task.wait(0.25)
                    tp(origin)
                end
                status.Text = "Clicks: " .. bought .. "\n" .. (note or "Done, waiting for restock")
            else
                status.Text = "Clicks: " .. bought .. "\nWaiting for stock..."
            end
        end
        task.wait(delay)
    end
end)

-- <w> : by Mister : yoruka.id
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local VU = game:GetService("VirtualUser")
local TS = game:GetService("TweenService")
local HS = game:GetService("HttpService")
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
local hopOn, fpsOn = false, false
local cooldown = {}
local gui, logBox, logScroll

-- ===== saved settings (chosen seeds + auto buy options) =====
local SET_FILE = "YorukaSettings.json"
pcall(function()
    if isfile and isfile(SET_FILE) then
        local d = HS:JSONDecode(readfile(SET_FILE))
        if type(d.seeds) == "table" then
            for _, n in ipairs(d.seeds) do selected[n] = true end
        end
        if type(d.delay) == "number" then delay = math.clamp(d.delay, 0.5, 30) end
        if type(d.maxPer) == "number" then maxPer = math.clamp(d.maxPer, 0, 100) end
        if type(d.ui) == "number" then uiMul = math.clamp(d.ui, 0.6, 1) end
        if type(d.tp) == "boolean" then tpOn = d.tp end
        if type(d.confirm) == "boolean" then confirmOn = d.confirm end
        if type(d.afk) == "boolean" then antiAfk = d.afk end
        if type(d.hop) == "boolean" then hopOn = d.hop end
        if type(d.fps) == "boolean" then fpsOn = d.fps end
    end
end)
local function saveSettings()
    pcall(function()
        if not writefile then return end
        local names = {}
        for _, s in ipairs(SEEDS) do
            if selected[s[1]] then table.insert(names, s[1]) end
        end
        writefile(SET_FILE, HS:JSONEncode({seeds = names, delay = delay, maxPer = maxPer,
            ui = uiMul, tp = tpOn, confirm = confirmOn, afk = antiAfk, hop = hopOn, fps = fpsOn}))
    end)
end

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

-- ===== THEME: colors + background image (saved to YorukaTheme.json) =====
local DEF_ACC, DEF_BG = Color3.fromRGB(60,210,130), Color3.fromRGB(16,18,26)
local CFG_FILE = "YorukaTheme.json"
local BG, ACC = DEF_BG, DEF_ACC
local imgUrl, imgVis, panelOp = "", 0.6, 1

pcall(function()
    if isfile and isfile(CFG_FILE) then
        local d = HS:JSONDecode(readfile(CFG_FILE))
        if type(d.accent) == "table" then ACC = Color3.fromRGB(d.accent[1], d.accent[2], d.accent[3]) end
        if type(d.bg) == "table" then BG = Color3.fromRGB(d.bg[1], d.bg[2], d.bg[3]) end
        if type(d.url) == "string" then imgUrl = d.url end
        if type(d.vis) == "number" then imgVis = math.clamp(d.vis, 0.1, 1) end
        if type(d.panel) == "number" then panelOp = math.clamp(d.panel, 0.2, 1) end
    end
end)

local function shift(c, r, g, b)
    local function f(v, d) return math.clamp(math.floor(v * 255 + 0.5) + d, 0, 255) end
    return Color3.fromRGB(f(c.R, r), f(c.G, g), f(c.B, b))
end
local PANEL, PANEL2 = shift(BG, 14, 16, 22), shift(BG, 24, 27, 38)
local WHITE, MUTED, OFFC = Color3.new(1,1,1), Color3.fromRGB(160,170,195), Color3.fromRGB(90,95,115)

local themed, refreshers = {}, {}
local function tint(o, prop, role) table.insert(themed, {o, prop, role}); return o end
local function onTheme(fn) table.insert(refreshers, fn) end
local function applyTheme()
    PANEL, PANEL2 = shift(BG, 14, 16, 22), shift(BG, 24, 27, 38)
    local role = {BG = BG, PANEL = PANEL, SOLID = PANEL, PANEL2 = PANEL2, ACC = ACC}
    for _, t in ipairs(themed) do
        local o = t[1]
        if o.Parent then
            o[t[2]] = role[t[3]]
            if t[3] == "PANEL" then o.BackgroundTransparency = 1 - panelOp end
        end
    end
    for _, fn in ipairs(refreshers) do pcall(fn) end
end
local function c3(c)
    return {math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5)}
end
local function saveCfg()
    pcall(function()
        if writefile then
            writefile(CFG_FILE, HS:JSONEncode({accent = c3(ACC), bg = c3(BG), url = imgUrl, vis = imgVis, panel = panelOp}))
        end
    end)
end
local function commit() applyTheme(); saveCfg() end
local function parseHex(s)
    s = tostring(s):gsub("[#%s]", "")
    if #s == 3 then s = s:gsub(".", "%0%0") end
    if not s:match("^%x%x%x%x%x%x$") then return nil end
    return Color3.fromRGB(tonumber(s:sub(1,2), 16), tonumber(s:sub(3,4), 16), tonumber(s:sub(5,6), 16))
end

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
tint(main, "BackgroundColor3", "BG")
tint(new("UIStroke", {Color = ACC, Thickness = 1.5, Transparency = 0.4}, main), "Color", "ACC")
local scale = new("UIScale", {Scale = baseScale}, main)

-- background image layer (sits under everything else)
local bgImg = round(new("ImageLabel", {Name="Bg", Size=UDim2.fromScale(1,1), BackgroundTransparency=1,
    ZIndex=0, ScaleType=Enum.ScaleType.Crop, Visible=false, Image=""}, main), 14)

local header = round(new("Frame", {Size = UDim2.new(1,0,0,40), BackgroundColor3 = PANEL, BorderSizePixel = 0}, main), 14)
tint(header, "BackgroundColor3", "SOLID")
tint(new("Frame", {Size = UDim2.new(1,0,0,14), Position = UDim2.new(0,0,1,-14), BackgroundColor3 = PANEL, BorderSizePixel = 0}, header), "BackgroundColor3", "SOLID")
new("TextLabel", {Size=UDim2.new(1,-70,0,20), Position=UDim2.fromOffset(14,3), BackgroundTransparency=1,
    Text="\u{1F331} Garden Hub", TextColor3=WHITE, Font=Enum.Font.GothamBold, TextSize=15,
    TextXAlignment=Enum.TextXAlignment.Left}, header)
tint(new("TextLabel", {Size=UDim2.new(1,-70,0,12), Position=UDim2.fromOffset(14,23), BackgroundTransparency=1,
    Text="by Mister \u{2022} yoruka.id", TextColor3=ACC, Font=Enum.Font.Gotham, TextSize=10,
    TextXAlignment=Enum.TextXAlignment.Left}, header), "TextColor3", "ACC")
local minBtn = round(new("TextButton", {Size=UDim2.fromOffset(36,28), Position=UDim2.new(1,-44,0,6),
    BackgroundColor3=Color3.fromRGB(55,60,82), Text="\u{2014}", TextColor3=WHITE,
    Font=Enum.Font.GothamBold, TextSize=16}, header), 8)

local sideW = 112
local sidebar = round(new("ScrollingFrame", {Position=UDim2.fromOffset(8,48), Size=UDim2.new(0,sideW,1,-56),
    BackgroundColor3=PANEL, BorderSizePixel=0, ScrollBarThickness=0,
    AutomaticCanvasSize=Enum.AutomaticSize.Y, CanvasSize=UDim2.new()}, main), 10)
tint(sidebar, "BackgroundColor3", "PANEL")
new("UIListLayout", {Padding=UDim.new(0,6)}, sidebar)
new("UIPadding", {PaddingTop=UDim.new(0,6), PaddingLeft=UDim.new(0,6), PaddingRight=UDim.new(0,6), PaddingBottom=UDim.new(0,6)}, sidebar)

local body = new("Frame", {Position=UDim2.fromOffset(sideW+16,48), Size=UDim2.new(1,-(sideW+24),1,-56),
    BackgroundTransparency=1, ClipsDescendants=true}, main)

local tabs, curTab = {}, nil
local function selectTab(name)
    curTab = name
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
onTheme(function() if curTab then selectTab(curTab) end end)

-- reusable components (use them for your own tabs)
local function scrollPage(page)
    local s = new("ScrollingFrame", {Size=UDim2.fromScale(1,1), BackgroundTransparency=1, BorderSizePixel=0,
        ScrollBarThickness=3, ScrollBarImageColor3=ACC, AutomaticCanvasSize=Enum.AutomaticSize.Y, CanvasSize=UDim2.new()}, page)
    tint(s, "ScrollBarImageColor3", "ACC")
    new("UIListLayout", {Padding=UDim.new(0,6)}, s)
    return s
end
local function section(sp, text)
    tint(new("TextLabel", {Size=UDim2.new(1,-6,0,20), BackgroundTransparency=1, Text=text:upper(), TextColor3=ACC,
        Font=Enum.Font.GothamBold, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left}, sp), "TextColor3", "ACC")
end
local function rowFrame(sp, h)
    local r = round(new("Frame", {Size=UDim2.new(1,-6,0,h), BackgroundColor3=PANEL, BorderSizePixel=0}, sp), 9)
    return tint(r, "BackgroundColor3", "PANEL")
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
    onTheme(function() sw.BackgroundColor3 = state and ACC or OFFC end)
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
    local val = tint(new("TextLabel", {Size=UDim2.fromOffset(62,30), Position=UDim2.new(1,-104,0.5,-15), BackgroundTransparency=1,
        Text=show(), TextColor3=ACC, Font=Enum.Font.GothamBold, TextSize=12}, r), "TextColor3", "ACC")
    local function mk(txt, x)
        return tint(round(new("TextButton", {Size=UDim2.fromOffset(32,30), Position=x, BackgroundColor3=PANEL2, Text=txt,
            TextColor3=WHITE, Font=Enum.Font.GothamBold, TextSize=16, BorderSizePixel=0}, r), 8), "BackgroundColor3", "PANEL2")
    end
    local m, p = mk("\u{2212}", UDim2.new(1,-138,0.5,-15)), mk("+", UDim2.new(1,-40,0.5,-15))
    m.MouseButton1Click:Connect(function() setv(math.clamp(getv() - step, lo, hi)); val.Text = show() end)
    p.MouseButton1Click:Connect(function() setv(math.clamp(getv() + step, lo, hi)); val.Text = show() end)
    return function() val.Text = show() end
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
local function clampU(pos, w, h)
    local x, y = clampPos(pos.X.Offset, pos.Y.Offset, w, h)
    return UDim2.fromOffset(x, y)
end
local function refit()
    baseScale = calcScale()
    if main.Visible then
        scale.Scale = baseScale
        main.Position = clampU(main.Position, W * baseScale, H * baseScale)
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
selAll.MouseButton1Click:Connect(function() for _, s in ipairs(SEEDS) do selected[s[1]] = true; paint(s[1]) end; saveSettings() end)
clr.MouseButton1Click:Connect(function() for _, s in ipairs(SEEDS) do selected[s[1]] = false; paint(s[1]) end; saveSettings() end)

local list = new("ScrollingFrame", {Position=UDim2.fromOffset(0,40), Size=UDim2.new(1,0,1,-96),
    BackgroundTransparency=1, ScrollBarThickness=3, ScrollBarImageColor3=ACC, BorderSizePixel=0,
    AutomaticCanvasSize=Enum.AutomaticSize.Y, CanvasSize=UDim2.new()}, buyPage)
tint(list, "ScrollBarImageColor3", "ACC")
new("UIListLayout", {Padding=UDim.new(0,5)}, list)

for _, s in ipairs(SEEDS) do
    local name, color = s[1], s[3]
    local btn = round(new("TextButton", {Size=UDim2.new(1,-6,0,38), BackgroundColor3=PANEL, Text="",
        AutoButtonColor=false, BorderSizePixel=0}, list), 9)
    round(new("Frame", {Size=UDim2.new(0,5,1,-12), Position=UDim2.fromOffset(6,6), BackgroundColor3=color, BorderSizePixel=0}, btn), 3)
    new("TextLabel", {Size=UDim2.new(1,-62,1,0), Position=UDim2.fromOffset(18,0), BackgroundTransparency=1,
        Text=name, TextColor3=WHITE, Font=Enum.Font.GothamMedium, TextSize=13,
        TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd}, btn)
    local check = tint(round(new("TextLabel", {Size=UDim2.fromOffset(24,24), Position=UDim2.new(1,-34,0.5,-12),
        BackgroundColor3=Color3.fromRGB(50,55,75), Text="", TextColor3=BG, Font=Enum.Font.GothamBold, TextSize=15}, btn), 7), "TextColor3", "BG")
    rows[name] = {btn=btn, check=check, color=color}
    btn.MouseButton1Click:Connect(function() selected[name] = not selected[name]; paint(name); saveSettings() end)
end
onTheme(function()
    for _, s in ipairs(SEEDS) do
        rows[s[1]].btn.BackgroundTransparency = 1 - panelOp
        paint(s[1])
    end
end)

local bar = new("Frame", {Position=UDim2.new(0,0,1,-50), Size=UDim2.new(1,0,0,50), BackgroundTransparency=1}, buyPage)
local toggle = smallBtn("\u{25B6}  START", UDim2.fromOffset(0,3), UDim2.new(0.5,-3,0,44), ACC, bar)
toggle.TextSize = 16; toggle.TextColor3 = BG
local status = new("TextLabel", {Position=UDim2.new(0.5,6,0,3), Size=UDim2.new(0.5,-6,0,44), BackgroundTransparency=1,
    Text="Clicks: 0\nReady", TextColor3=MUTED, Font=Enum.Font.Gotham, TextSize=12, TextWrapped=true,
    TextXAlignment=Enum.TextXAlignment.Left}, bar)

-- ===== background image loader =====
local bgMsg, panelUpdate
local bgSeq = 0
local function fetch(u)
    local ok, data = pcall(function() return game:HttpGet(u) end)
    if ok and type(data) == "string" and #data > 0 then return data end
    local req = (syn and syn.request) or request or http_request or (http and http.request)
    if req then
        local ok2, res = pcall(req, {Url = u, Method = "GET"})
        if ok2 and res and res.Body and #res.Body > 0 then return res.Body end
    end
end
-- returns an asset string the ImageLabel can load, or nil + error text
local function resolveImage(src)
    src = (src or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if src == "" then return nil, "Paste an image link first" end
    if src:find("^rbxassetid://") or src:find("^rbxasset://") then return src end
    if src:match("^%d+$") then return "rbxassetid://" .. src end
    if not src:match("^https?://") then return nil, "Link must start with http(s)://" end
    if not (writefile and getcustomasset) then return nil, "Executor has no writefile/getcustomasset" end
    local data = fetch(src)
    if not data then return nil, "Download failed" end
    local ext
    if data:sub(1, 4) == "\137PNG" then ext = "png"
    elseif data:sub(1, 2) == "\255\216" then ext = "jpg" end
    if not ext then return nil, "Not a direct png/jpg link" end
    bgSeq += 1
    local name = "YorukaBg_" .. os.time() .. "_" .. bgSeq .. "." .. ext
    writefile(name, data)
    return getcustomasset(name)
end
local function setBackground(src)
    task.spawn(function()
        if bgMsg then bgMsg.Text = "Loading image..." end
        local ok, asset, err = pcall(resolveImage, src)
        if not ok then err, asset = asset, nil end
        if not asset then
            if bgMsg then bgMsg.Text = "\u{26A0} " .. tostring(err or "Failed to load") end
            return
        end
        bgImg.Image = asset
        bgImg.ImageTransparency = 1 - imgVis
        bgImg.Visible = true
        imgUrl = src
        if panelOp > 0.9 then
            panelOp = 0.7
            if panelUpdate then panelUpdate() end
            applyTheme()
        end
        saveCfg()
        if bgMsg then bgMsg.Text = "\u{2713} Background applied" end
    end)
end
local function clearBackground()
    bgImg.Visible = false
    bgImg.Image = ""
    imgUrl = ""
    saveCfg()
    if bgMsg then bgMsg.Text = "Background removed" end
end

-- ===== server hop when admin / owner joins =====
local TPS = game:GetService("TeleportService")
local STAFF_RANK = 200 -- group rank counted as admin/owner (creator group games)
local hopping = false
local function serverHop(reason)
    if hopping then return end
    hopping = true
    log("Server hop: " .. tostring(reason))
    status.Text = "Clicks: " .. bought .. "\nHopping server..."
    local id
    pcall(function()
        local raw = fetch("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")
        local data = raw and HS:JSONDecode(raw)
        local pool = {}
        for _, sv in ipairs(data and data.data or {}) do
            if sv.id ~= game.JobId and sv.playing and sv.maxPlayers and sv.playing < sv.maxPlayers - 1 then
                table.insert(pool, sv.id)
            end
        end
        if #pool > 0 then id = pool[math.random(1, #pool)] end
    end)
    if id then
        pcall(function() TPS:TeleportToPlaceInstance(game.PlaceId, id, lp) end)
    else
        pcall(function() TPS:Teleport(game.PlaceId, lp) end)
    end
    task.delay(15, function() hopping = false end)
end
local function isStaff(p)
    if p == lp then return false end
    local ok, res = pcall(function()
        if game.CreatorType == Enum.CreatorType.Group then
            return p:GetRankInGroup(game.CreatorId) >= STAFF_RANK
        end
        return p.UserId == game.CreatorId
    end)
    return ok and res == true
end
local function checkStaff(p)
    task.spawn(function()
        if hopOn and not hopping and isStaff(p) then serverHop(p.Name .. " (admin/owner) joined") end
    end)
end
local function scanStaff()
    for _, p in ipairs(Players:GetPlayers()) do checkStaff(p) end
end
Players.PlayerAdded:Connect(checkStaff)

-- ===== FPS boost (low textures, no shadows, no particles) =====
local Lighting = game:GetService("Lighting")
local function weak() return setmetatable({}, {__mode = "k"}) end
local fps = {saved = weak(), conns = {}, token = 0, glob = {}}
local PARTICLES = {"ParticleEmitter", "Trail", "Beam", "Fire", "Smoke", "Sparkles"}
local function boost(o)
    if fps.saved[o] then return end
    local s, set
    if o:IsA("BasePart") then
        if o:IsA("Terrain") then return end
        s = {Material = o.Material, Reflectance = o.Reflectance, CastShadow = o.CastShadow}
        set = {Material = Enum.Material.SmoothPlastic, Reflectance = 0, CastShadow = false}
        if o:IsA("MeshPart") then s.TextureID = o.TextureID; set.TextureID = "" end
    elseif o:IsA("Decal") or o:IsA("Texture") then
        s, set = {Transparency = o.Transparency}, {Transparency = 1}
    elseif o:IsA("PostEffect") then
        s, set = {Enabled = o.Enabled}, {Enabled = false}
    else
        for _, c in ipairs(PARTICLES) do
            if o:IsA(c) then s, set = {Enabled = o.Enabled}, {Enabled = false} break end
        end
    end
    if not s then return end
    fps.saved[o] = s
    for k, v in pairs(set) do pcall(function() o[k] = v end) end
end
local function fpsEnable()
    fpsOn = true
    fps.token += 1
    local tok = fps.token
    fps.glob = {shadows = Lighting.GlobalShadows}
    pcall(function() fps.glob.quality = settings().Rendering.QualityLevel end)
    pcall(function() Lighting.GlobalShadows = false end)
    pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
    local t = workspace:FindFirstChildOfClass("Terrain")
    if t then
        fps.glob.terrain = {WaterWaveSize = t.WaterWaveSize, WaterWaveSpeed = t.WaterWaveSpeed,
            WaterReflectance = t.WaterReflectance}
        pcall(function() fps.glob.terrain.Decoration = t.Decoration end)
        for k in pairs(fps.glob.terrain) do
            pcall(function()
                if k == "Decoration" then t[k] = false else t[k] = 0 end
            end)
        end
    end
    for _, root in ipairs({workspace, Lighting}) do
        table.insert(fps.conns, root.DescendantAdded:Connect(boost))
    end
    task.spawn(function()
        local n = 0
        for _, root in ipairs({workspace, Lighting}) do
            for _, d in ipairs(root:GetDescendants()) do
                if not fpsOn or fps.token ~= tok then return end
                boost(d)
                n += 1
                if n % 400 == 0 then task.wait() end
            end
        end
        log("FPS boost applied")
    end)
end
local function fpsDisable()
    fpsOn = false
    fps.token += 1
    for _, c in ipairs(fps.conns) do c:Disconnect() end
    fps.conns = {}
    local saved, glob = fps.saved, fps.glob
    fps.saved, fps.glob = weak(), {}
    if glob.shadows ~= nil then pcall(function() Lighting.GlobalShadows = glob.shadows end) end
    if glob.quality then pcall(function() settings().Rendering.QualityLevel = glob.quality end) end
    local t = workspace:FindFirstChildOfClass("Terrain")
    if t and glob.terrain then
        for k, v in pairs(glob.terrain) do pcall(function() t[k] = v end) end
    end
    task.spawn(function()
        local n = 0
        for o, s in pairs(saved) do
            pcall(function() for k, v in pairs(s) do o[k] = v end end)
            n += 1
            if n % 400 == 0 then task.wait() end
        end
    end)
end

-- ===================== TAB 2: SETTINGS (menu list -> sub pages) =====================
-- Speed Hub style: a list of rows with ">" ; tapping a row opens that sub page, "<" goes back
local function menuPage(page, title)
    local listView = new("Frame", {Size=UDim2.fromScale(1,1), BackgroundTransparency=1}, page)
    new("TextLabel", {Size=UDim2.new(1,0,0,30), BackgroundTransparency=1, Text=title, TextColor3=WHITE,
        Font=Enum.Font.GothamBold, TextSize=20, TextXAlignment=Enum.TextXAlignment.Left}, listView)
    local lst = new("ScrollingFrame", {Position=UDim2.fromOffset(0,36), Size=UDim2.new(1,0,1,-36),
        BackgroundTransparency=1, BorderSizePixel=0, ScrollBarThickness=3, ScrollBarImageColor3=ACC,
        AutomaticCanvasSize=Enum.AutomaticSize.Y, CanvasSize=UDim2.new()}, listView)
    tint(lst, "ScrollBarImageColor3", "ACC")
    new("UIListLayout", {Padding=UDim.new(0,6)}, lst)
    local views = {}
    local function show(name)
        listView.Visible = (name == nil)
        for n, v in pairs(views) do v.Visible = (n == name) end
    end
    local function add(name, build)
        local view = new("Frame", {Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Visible=false}, page)
        views[name] = view
        local back = tint(round(new("TextButton", {Size=UDim2.fromOffset(34,30), BackgroundColor3=PANEL2, Text="\u{2039}",
            TextColor3=WHITE, Font=Enum.Font.GothamBold, TextSize=22, BorderSizePixel=0}, view), 8), "BackgroundColor3", "PANEL2")
        new("TextLabel", {Size=UDim2.new(1,-44,0,30), Position=UDim2.fromOffset(44,0), BackgroundTransparency=1, Text=name,
            TextColor3=WHITE, Font=Enum.Font.GothamBold, TextSize=18, TextXAlignment=Enum.TextXAlignment.Left}, view)
        local sp = new("ScrollingFrame", {Position=UDim2.fromOffset(0,38), Size=UDim2.new(1,0,1,-38),
            BackgroundTransparency=1, BorderSizePixel=0, ScrollBarThickness=3, ScrollBarImageColor3=ACC,
            AutomaticCanvasSize=Enum.AutomaticSize.Y, CanvasSize=UDim2.new()}, view)
        tint(sp, "ScrollBarImageColor3", "ACC")
        new("UIListLayout", {Padding=UDim.new(0,6)}, sp)
        back.MouseButton1Click:Connect(function() show(nil) end)

        local row = tint(round(new("TextButton", {Size=UDim2.new(1,-6,0,42), BackgroundColor3=PANEL, Text="",
            AutoButtonColor=false, BorderSizePixel=0}, lst), 9), "BackgroundColor3", "PANEL")
        new("TextLabel", {Size=UDim2.new(1,-50,1,0), Position=UDim2.fromOffset(14,0), BackgroundTransparency=1, Text=name,
            TextColor3=WHITE, Font=Enum.Font.GothamMedium, TextSize=13, TextXAlignment=Enum.TextXAlignment.Left}, row)
        new("TextLabel", {Size=UDim2.fromOffset(30,42), Position=UDim2.new(1,-38,0,0), BackgroundTransparency=1, Text="\u{203A}",
            TextColor3=WHITE, Font=Enum.Font.GothamBold, TextSize=26}, row)
        row.MouseButton1Click:Connect(function() show(name) end)
        build(sp)
    end
    return add
end

local function pct(v) return math.floor(v * 100 + 0.5) .. "%" end
local ACC_PRESETS = {
    Color3.fromRGB(60,210,130), Color3.fromRGB(70,150,255), Color3.fromRGB(160,110,255), Color3.fromRGB(255,110,170),
    Color3.fromRGB(255,95,70), Color3.fromRGB(255,160,50), Color3.fromRGB(255,200,60), Color3.fromRGB(60,210,220),
}
local BG_PRESETS = {
    Color3.fromRGB(16,18,26), Color3.fromRGB(8,8,10), Color3.fromRGB(12,18,38), Color3.fromRGB(26,14,38),
    Color3.fromRGB(12,28,22), Color3.fromRGB(36,14,20), Color3.fromRGB(30,32,38), Color3.fromRGB(38,26,14),
}
local function swatchRow(sp, title, colors, onPick)
    local r = rowFrame(sp, 78)
    new("TextLabel", {Size=UDim2.new(1,-24,0,20), Position=UDim2.fromOffset(12,6), BackgroundTransparency=1, Text=title,
        TextColor3=WHITE, Font=Enum.Font.GothamMedium, TextSize=13, TextXAlignment=Enum.TextXAlignment.Left}, r)
    local holder = new("Frame", {Size=UDim2.new(1,-24,0,32), Position=UDim2.fromOffset(12,34), BackgroundTransparency=1}, r)
    new("UIListLayout", {FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,8)}, holder)
    for _, c in ipairs(colors) do
        local b = round(new("TextButton", {Size=UDim2.fromOffset(30,30), BackgroundColor3=c, Text="",
            AutoButtonColor=false, BorderSizePixel=0}, holder), 15)
        new("UIStroke", {Color=WHITE, Thickness=1, Transparency=0.6}, b)
        b.MouseButton1Click:Connect(function() onPick(c) end)
    end
end

local addSet = menuPage(addTab("\u{2699}", "Settings"), "Settings")
local urlBox, visUpdate

addSet("Auto Buy", function(sp)
    stepperRow(sp, "Check delay", "Time between stock checks", function() return delay end,
        function(v) delay = v; saveSettings() end, 0.5, 0.5, 30, "%.1f s")
    stepperRow(sp, "Max buys / pack", "\u{221E} = unlimited (buys until out of stock)", function() return maxPer end,
        function(v) maxPer = v; saveSettings() end, 1, 0, 100, function(v) return v == 0 and "\u{221E}" or (v .. " x") end)
    toggleRow(sp, "Auto-confirm popups", "Clicks Confirm / Yes / OK if a popup appears", confirmOn, function(v) confirmOn = v; saveSettings() end)
end)

addSet("Teleport", function(sp)
    toggleRow(sp, "TP to shop", "One trip: buy everything, then return", tpOn, function(v) tpOn = v; saveSettings() end)
    buttonRow(sp, "\u{1F4CD} Save shop position", Color3.fromRGB(110,90,180), function(b)
        local h = getHRP()
        if h then
            shopCF = h.CFrame
            b.Text = "\u{2713} Saved"
            task.delay(1.5, function() b.Text = "\u{1F4CD} Save shop position" end)
        end
    end)
    buttonRow(sp, "Reset shop position (auto-detect)", Color3.fromRGB(70,75,100), function(b)
        shopCF, autoShop = nil, nil
        b.Text = "\u{2713} Reset"
        task.delay(1.5, function() b.Text = "Reset shop position (auto-detect)" end)
    end)
end)

addSet("Utility", function(sp)
    toggleRow(sp, "Anti AFK", "Stops the game from kicking you for idling", antiAfk, function(v) antiAfk = v; saveSettings() end)
    toggleRow(sp, "Hop on admin/owner", "Switches server when an admin or the owner joins", hopOn,
        function(v) hopOn = v; saveSettings(); if v then scanStaff() end end)
    toggleRow(sp, "FPS boost", "Low textures, no shadows, no particles, simple materials", fpsOn,
        function(v) if v then fpsEnable() else fpsDisable() end; saveSettings() end)
    buttonRow(sp, "\u{1F500} Hop server now", Color3.fromRGB(50,100,190), function() serverHop("manual") end)
end)

addSet("Theme", function(sp)
    swatchRow(sp, "Accent color", ACC_PRESETS, function(c) ACC = c; commit() end)
    swatchRow(sp, "Background color", BG_PRESETS, function(c) BG = c; commit() end)

    do -- custom hex row
        local r = rowFrame(sp, 46)
        new("TextLabel", {Size=UDim2.fromOffset(90,46), Position=UDim2.fromOffset(12,0), BackgroundTransparency=1,
            Text="Custom hex", TextColor3=WHITE, Font=Enum.Font.GothamMedium, TextSize=13,
            TextXAlignment=Enum.TextXAlignment.Left}, r)
        local box = tint(round(new("TextBox", {Size=UDim2.fromOffset(88,30), Position=UDim2.fromOffset(104,8),
            BackgroundColor3=PANEL2, Text="", PlaceholderText="#3CD282", PlaceholderColor3=MUTED, TextColor3=WHITE,
            Font=Enum.Font.Gotham, TextSize=12, ClearTextOnFocus=false, BorderSizePixel=0}, r), 8), "BackgroundColor3", "PANEL2")
        local function mk(text, x, w, which)
            local b = tint(round(new("TextButton", {Size=UDim2.fromOffset(w,30), Position=UDim2.fromOffset(x,8),
                BackgroundColor3=PANEL2, Text=text, TextColor3=WHITE, Font=Enum.Font.GothamBold, TextSize=12,
                BorderSizePixel=0}, r), 8), "BackgroundColor3", "PANEL2")
            b.MouseButton1Click:Connect(function()
                local c = parseHex(box.Text)
                if not c then
                    box.Text = ""
                    box.PlaceholderText = "Invalid hex"
                    task.delay(1.5, function() box.PlaceholderText = "#3CD282" end)
                    return
                end
                if which == "acc" then ACC = c else BG = c end
                commit()
            end)
        end
        mk("Accent", 198, 64, "acc")
        mk("BG", 268, 52, "bg")
    end

    panelUpdate = stepperRow(sp, "Panel opacity", "Lower it to see more of the image",
        function() return panelOp end,
        function(v) panelOp = math.floor(v * 10 + 0.5) / 10; commit() end,
        0.1, 0.2, 1, pct)

    buttonRow(sp, "Reset theme", Color3.fromRGB(70,75,100), function()
        ACC, BG, panelOp, imgVis = DEF_ACC, DEF_BG, 1, 0.6
        if urlBox then urlBox.Text = "" end
        clearBackground()
        commit()
        if visUpdate then visUpdate() end
        if panelUpdate then panelUpdate() end
        if bgMsg then bgMsg.Text = "Theme reset" end
    end)
end)

addSet("Background", function(sp)
    local urlRow = rowFrame(sp, 46)
    urlBox = tint(round(new("TextBox", {Size=UDim2.new(1,-24,0,30), Position=UDim2.fromOffset(12,8),
        BackgroundColor3=PANEL2, Text=imgUrl, PlaceholderText="Image link (png / jpg) or asset id", PlaceholderColor3=MUTED,
        TextColor3=WHITE, Font=Enum.Font.Gotham, TextSize=12, ClearTextOnFocus=false, ClipsDescendants=true,
        TextXAlignment=Enum.TextXAlignment.Left, BorderSizePixel=0}, urlRow), 8), "BackgroundColor3", "PANEL2")
    new("UIPadding", {PaddingLeft=UDim.new(0,8), PaddingRight=UDim.new(0,8)}, urlBox)

    local btnRow = new("Frame", {Size=UDim2.new(1,-6,0,38), BackgroundTransparency=1}, sp)
    local applyBtn = smallBtn("Apply image", UDim2.fromOffset(0,0), UDim2.new(0.5,-3,1,0), Color3.fromRGB(50,100,190), btnRow)
    local removeBtn = smallBtn("Remove", UDim2.new(0.5,3,0,0), UDim2.new(0.5,-3,1,0), Color3.fromRGB(150,65,75), btnRow)
    applyBtn.MouseButton1Click:Connect(function() setBackground(urlBox.Text) end)
    removeBtn.MouseButton1Click:Connect(function() urlBox.Text = ""; clearBackground() end)

    bgMsg = new("TextLabel", {Size=UDim2.new(1,-6,0,28), BackgroundTransparency=1, TextWrapped=true,
        Text = imgUrl ~= "" and "Saved image loads on start" or "Direct png/jpg link. Needs executor file support (writefile).",
        TextColor3=MUTED, Font=Enum.Font.Gotham, TextSize=10, TextXAlignment=Enum.TextXAlignment.Left}, sp)

    visUpdate = stepperRow(sp, "Image visibility", "How strong the background image is",
        function() return imgVis end,
        function(v) imgVis = math.floor(v * 10 + 0.5) / 10; bgImg.ImageTransparency = 1 - imgVis; saveCfg() end,
        0.1, 0.1, 1, pct)
end)

addSet("Interface", function(sp)
    stepperRow(sp, "UI size", "Make the window smaller on small screens", function() return uiMul end,
        function(v) uiMul = math.floor(v * 10 + 0.5) / 10; refit(); saveSettings() end, 0.1, 0.6, 1,
        function(v) return math.floor(v * 100 + 0.5) .. "%" end)
    buttonRow(sp, "Destroy GUI", Color3.fromRGB(170,55,65), function()
        running = false
        gui:Destroy()
    end)
end)

-- ===== ADD YOUR NEW TABS BELOW =====
-- local page = scrollPage(addTab("\u{1F9FA}", "Harvest"))
-- section(page, "Harvest")
-- toggleRow(page, "Auto harvest", "Collect ripe plants", false, function(v) end)

selectTab("Auto Buy")

-- ===== minimize icon (Mister Hub style) =====
local ICON = 64
local icon = round(new("TextButton", {Size=UDim2.fromOffset(ICON,ICON), BackgroundColor3=BG, Text="",
    Visible=false, AutoButtonColor=false, BorderSizePixel=0, Position=UDim2.fromOffset(20,120)}, gui), 18)
tint(icon, "BackgroundColor3", "BG")
new("UIGradient", {Color=ColorSequence.new(Color3.new(1,1,1), Color3.fromRGB(105,105,125)), Rotation=90}, icon)
local iconStroke = new("UIStroke", {Color=ACC, Thickness=2.5, Transparency=0.15}, icon)
tint(iconStroke, "Color", "ACC")

local iconCrown = new("TextLabel", {Size=UDim2.new(1,0,0,13), Position=UDim2.fromOffset(0,4), BackgroundTransparency=1,
    Text="\u{1F451}", TextSize=11, Font=Enum.Font.GothamBold, TextColor3=WHITE}, icon)
local iconTop = new("TextLabel", {Size=UDim2.new(1,0,0,12), Position=UDim2.fromOffset(0,17), BackgroundTransparency=1,
    Text="MISTER", TextSize=10, Font=Enum.Font.GothamBlack, TextColor3=WHITE}, icon)
new("UIGradient", {Color=ColorSequence.new(Color3.new(1,1,1), Color3.fromRGB(150,155,175)), Rotation=90}, iconTop)
local iconBot = tint(new("TextLabel", {Size=UDim2.new(1,0,0,26), Position=UDim2.fromOffset(0,29), BackgroundTransparency=1,
    Text="HUB", TextSize=24, Font=Enum.Font.GothamBlack, TextColor3=ACC}, icon), "TextColor3", "ACC")
local iconImg = round(new("ImageLabel", {Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Image="", Visible=false,
    ScaleType=Enum.ScaleType.Crop, ZIndex=2}, icon), 18)
local dot = round(new("Frame", {Size=UDim2.fromOffset(12,12), Position=UDim2.new(1,-16,0,4), ZIndex=5,
    BackgroundColor3=Color3.fromRGB(150,65,75), BorderSizePixel=0}, icon), 6)

-- fixed Mister Hub icon (embedded image, decoded and loaded at start)
local ICON_B64 = "/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAYEBAUEBAYFBQUGBgYHCQ4JCQgICRINDQoOFRIWFhUSFBQXGiEcFxgfGRQUHScdHyIjJSUlFhwpLCgkKyEkJST/2wBDAQYGBgkICREJCREkGBQYJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCT/wAARCAEAAQADASIAAhEBAxEB/8QAHQAAAQQDAQEAAAAAAAAAAAAABQIDBAYAAQcICf/EAEsQAAIBAwMCAwYDBgUCAQgLAAECAwAEEQUSIQYxE0FRByJhcYGRFDKhCBUjQlKxM2JywdGC8CQWGDRDkqKy8SUmJ0RTY3OFwtLh/8QAGwEAAQUBAQAAAAAAAAAAAAAABQECAwQGAAf/xAA0EQABAwIDBAkEAgMBAQAAAAABAAIDBBESITEFE0FRImFxgZGhscHwBjLR4RRCI2LxUsL/2gAMAwEAAhEDEQA/APK5Q+mawgii+l2kd4Y4pZo4VKkl5MbV+fw+XNbXTxNeC1iQtIz+Go7EnOB8KtinJtbioTKBqhAFK2ijF50/cWjuGTcqAMXj99MEEg7l48j9jUJrJgcYB+Rpzqd7DhcM0jZWuGJpyUKlIuakGzPmcfMVtLWQD3RuH+U5pGwuvolMgskoinilSWxUfA9qUI2THBB+NPoS3BFWWRAixChc8jMIc8TRnmnI7Yyj3e9TZ4dyZxk/2rVsGicZ5HbFIKUB9jol3123GqhNC68Ec1rBUc0UuVy+MVElgyK6WmwE2XMlxaqLkE1m2lLH7wzT/hgDtmoGRlykLrKKVrW2pfgqfUGsFqW/KQfhTxTuOiTeBRCtZtqU9tIn50I+lI8L4Vxp3A2ISiQFSNNiJDvj4VMK/CssWgSAIXAbuc8U9IqojPwQBmtLTUwbA2x4ZqhI+7ygN2Q074AAzjimacfJJJ70gisnLm4nmiTchZYqljgU4YiEye9aQEYI71uUsWxmkAFs1xOaVayBGKt2NbuNjcg80ypKsCK3+Y0od0cK4jO6TjNbK09GFAwR9aS+McV27yukxZpgitUvFaIqItUl0msrdaNNSqfHu2oqseQOM04s81pLlf8AERsDHBBB8sfEUmMe/GM7R7vPp2pUnv3J2OXJl4ZuSee5q2CRmFDYHIorZ9Y6pZzyTR3UyySbRLuAcPt7BgRyB6VMj6uguJS2oabYXYYqWG0xE4z/AE/6j/2K1JDeo4N1oFvPy58WP3SeeWOc9s559eaGRHSnRlvLW4t90z/x097au5fdC9iQN3PxFStne49I3K59O2MADTsW4nhacM3+EWywU5O3PYUxeLA98ipIYoXbAdxkque5xT8+l6UAPwuto7kH3ZYSmDgnG7OPLHzNR7XS7y9kWK1VbiQx+LtRgSozjBz2OfKn9J3RAUJLWjETYJu4ke1uZYYroTxI5VXHKuAe+DWhfP2aND8hinZ9H1C2kMc9hMjBSxBQjgdzUVk2EbkdM9sjvXYpGGxNlwwPFxmpsV9CeJIm+hqSDZyEGKYIfRxihYVPJx9RinkiJ7EH5Gr0NQ/RwB+dSgfE3gbIuLBpMGMrIP8AKwNNS6e6n3lI+lQUVkOeVP2ojbanfQgBZi6/0yAOP1olG+CT72kdmf4VZzZG/abqDNYMrghc+grBbE9xj4Ufh1mB8C60u3f/ADQu0Z/3H6USsrPR9SmVIlvbeR8AKYxLkny90g/pVuHZMMpvG7yKrvrnxj/I09uvpmqh+DI5IrbWoQEu8cYH9bBf070e6kuLHp1pLW2aO7vRx4g/w4fkP5m/QfGqPLO8jl3Yszckk8mh20nQUT92Ok70VykL6huMZDh1osNRt4CB4hcDy2kinrc2l+u5ZIY2PBSRwjA/DPBFV9pM+X3pIyO+QKGM21ID0mgjkrhpBbI2Ksk+mNCAXGxG7OeVP1HFRbi2mt90bBkIJVgePpQ2OSSJGMMx2uNrqDjg+o8xVrnZdUtLa5SSKSZoVWZFcFt6+7kjvyAp+9FKWaKsxNDcJtlnqqkuOEjEbgqryR/CmilFri0dc+6MfCoTwlW5BHzoPU0pYVbjlBCYCkDNI86ekwOBTeM1ScLZKUFZtBTJ7k4FWroDohus7+4t2uGtYLeEyPME34YnCjGR3OfoDVYC5IHpXd/ZfpQ0PpWOZxtnv2/EP6hcYQfbJ/6qK7LoRUTAOGQ1Q3ataaaAuaczkFQtb9kWv6Zua1WHUoh527YfH+hsH7ZqkXllcWcxguYZYZV7pIhVh9DXpaa797vQ7UktdUh8C9tobqPyWZAwHyz2+laCf6cbILxGyz0H1O5htK2/Zr88F5z2UgrXW9U9mujXWWs3msZPIA+In2PP61R+oejL/QYjcSvBNbbgoljbHJ7e6ef70Bq9h1NOC5zbgcRmtDSbZpqkhrXWJ4HL9KtkUnbk4FLbvgVrGKBubmi4KIRgmaMKBnK4ycc4FbuSRdO0qBf4uXUDtzyK2gX8QgcNtyudvfHHb41qVUkuNgYhGkxubggZ7nP+9WSMiohqiMEmlq3/AIbUb6yzncCCAeeAMZwPnnGPOpGlSSpA5ttZtY5DKy+DNHksCw97OPPg/Soi9MXU74tZ7W4XuSkoO0ZA5A+Y4GfhmoseiX88PiwWzzL4jR4j95srjPujnHI5prHWN1NKHkWLbKxz2+sxW5MumWM8BGJvw+Bt90gAk/lPmcd/Ohmomzghl8HSb+wmZeD4rbF55U+eB/fHahL215aqWeKeEHuWUqDTn731AwPbm8maKRSjKzZDAnJH3Gan3gsqxYeKn6ZfLFM0lvq93bSpj8O0hGBwS2484GcYxRWe41QQMrXmjamr5IL4aQYXORuHGQM4/wB6A22svE0rz2ltePIV5nTttGOwx5Y+1OxajpUkkrXWjgK4G1beXbsIHlkHgnk1MxzcN8Wff+woTixEYcu7/qmMgmhM0ugYLqAjwltqnGR7vy8vnWNaaRNtNyLrSJCBkeEZEbtkjJzjvgD4c02lzpQ2vb3mpWj9to95Rx88/D61Ntb11lKxazbSiZwmZ4d230LE9hwO3b0qd8MUjcRcRblY+WV/BRB8jDYAG/O/7Q6e0toFY2uqLcYUsuEK5A9cngny9ajJdSL/AEsPiKMXfTGqXs0s9vHa3Sg4BtGG0n0UcE+tDZNKvbdwstpOjE4AKHk02nlAOFj72+aKV7bi7hZP2t2CwDxZ+Rq431/F0x0tBJCoTUNTQyBm/PDb9hj03nJ+IA8jVc6W0P8Ae+sxWs7NDboGlupO3hQoNzt88DA+JFQOr9fbXtZuLwr4cRbbFH5RxqMIo+AUAfStKyvdS0pcdeCFyU7Z5hHwGZ9h85IHeSl3yxJJ55qMsZZC54UHGfU1uQlyWIOM1p5mcBcAADAArCzSY3lzloGtsAAtK5Q8Bc+prGldzksaTWAY5NV7nRPsNUpF3BsHkDPzp+3bb76fnTnafMfCo4YqDjz4p1SrRlgcOpzUkZsckxwurjHdwazp6PBEsZiwsikln3EebHlgcHHp2qJcx4RkABI8yKg9MX0NndOl0dkcybA3kpyCCfhkUZ1KybAcZMROPEXlD/1DitfDL/JphIfuGRQJ7NxNg4cFWp4Ao3ds9hTAGOamXm5pj2KjgYqOwyQADWflYA42RVjiRmp/TuktrWsWtgM4mcBz/Sg5Y/YGu9NOqIERQqKAFUdlA4ArnPsv0nw1udWkHf8A8PF+hc//AAj71e2fPnW4+n6Ldwbx2rvRYb6hrDLUbpujfUoV1N1bbdNJbNPFJMZ3I2IQGCgctz37gVmk9T6br6ubGZmdAC8boVZQf0+xqudb9J6nrl6t5azQyIkYRIGO1h5nBPByflUzojRJdE0tzcxGO5uJNzqe6qOFH9z9atRTVhrjEW2j5kcuR6yoXUtGKISB15OV/UdQ81Y3euc+03VfFu7fTY292FfFk/1HsPoP71f7ieOCJ5pW2xxqXY+gAya4lql8+pX9xeSZ3TOXx6DyH0GBVb6oq91TiEau9B+1f+nKTHOZTo31KiDk06Y+KbQgfOnGkAWvPG2zJW2de+SmIhku0RCAzMoBPbPFIulZJJVchmDkE+pyacjUtdDEbSAMCVHmOKbuQN8mEKDfwp7qOeKmtkmJFo0KXMZuATED74Uc4+4/vReKTTbdJXstVvoJDHhUYFdxwTgleMZC/PPlihVlbC7uUhM8UAfP8SU4VeM8/wBqnvYSaJtujLZXiMCpVHLKQ3HPb0PFMAuc1KHOawuAuiNncagI0uodcsZZpBlo58F1J7g5HxPPnn41HmgvrKS5vru0tLyKfAk2OCmSd3Zf9NM/vywlH8bQrTOc5jZhn6ffikxTaJKzbku7QbWx4bZB74B7k57elXmMi/qRfvHqENdJO4WkvbuPhY+ynzy6WbVDP0zcWkbbX8WJycqcc5byIP3I+VRvw/TskC7bm9juSuTGwAQHB43YPc45rGi06W32fv2QEqMRPGzKMchc/pUyxa4kTbBf2F3PcMJJVuF53DHBY/Dv8M1abT43AG3dhPoQqxsxtwXDP/b/AOgVXrmOOO5ljhk8SJXYI/8AUoPB+1aUVZri1uYpAlxZWMnie6HEoCkHjOT+XvweOabutMhtpSlzo19aY/MVJfH1PHpTX0m7fhJsevJXoZBIzECgkbPGRsdlxyNpxU621O/gjeOO7mVHUqy7uCCMEUq5trWMAweOpJ4WYYbHPP8Aasgt8mr8FBiIGqifLa6PaJJI3THVTqwWY2sB3AclBMoZflyv2qhPJuLbvWul9OWf/wBH61Gfyy6bID/0sj//AMa5nexeBcOnoSKf9RU0kEUbjpn7KHZsjXySAcx6AeyZkk3YVRhR2FZFG0pIjRnIGTgdh60g96naLqk+jahDe20hjlibKsP7fEeWKyMOF8oEhsOaMPxBhwC5UYwsDmTgD9abzk81edc6s0DX7UtcaAlpekcz2UmwE/FCMf8AfeqdbQJc3SxmVIlY43vnC/E4yau1tFHG9rYXh1/marUtRJIwulYWEcMj4W+dSjE5ra5yMVbr/oq0sNKa/PUGlTYHuxQOzu59AMDHzNVQLhyMdqhqqCWmcBLqVJT1cc4Jj4dRHqrp0HbQX1rfxSx27yRoJojKgbBBAI58iG+4FJ1u6nKhXk/hpwkagKq59FHAonpGgfuKRbqOcNFeW5SSJ+CquAVdT2P8pI48+9BNaH8Zl4LKcEg5H3rWmF8FCGSNs4eY4IAx7Japz2m4P/CgrOUJ9abEpLe9g05KpHJFRjkGsvI4tKONAIXUulurNDg0u10/8QbWSJMN464DMTkncOOSfPFWdZVlUPG6uh7MpyD9RXCN+OxqTZareac++zuZoG/yMQD8x2Naah+pjE0RyMuByyWdq/pxsjjJG6xOeefzzXbS1Nk1zuw9o99Dhb2CK5X+pfcf9OD9qsun9a6Nf4U3BtpD/JONv69q01Ltqjnya+x5HL9IHPsipgzLbjmM/wBqJ7QtUFnowtEbEl2204/oHJ/2H1rmDHmrB1pqo1TXJTG4aGAeDGQeDjufqc0AAwc1g9v1n8mrcRoMh3ftbLZFN/Hpmg6nM9/6SooSzAH0zSbsBXAHkKdR9vamJ23SE0GfYMsESbcuRW2JF25WUREZw3H+9M3W4ySFn3tvOW9Tk80/bLuupAIvEPPAIB7jtkGo9znfJuQId5yo8uTxVg6Jibhge4kEcS7mOcDPoM/7U5LYXUMkkbwPujYK+0bgDjOMjjNNJI8TB43ZGHZlOCKJaNPOs8sZ1VtPBG9nbJBYEAAj15NJG0F1nJHkhl26oYyMhwylT8RitYqypdTxwKIdctpcgMYmiBYe6CeO2fdAxmnbSzvFtoIbZ9MvrZh/CEy+9kk8bTyDyf8A5YNLMGR2sfniV0F3k48uzP8ACqtLUUWn6c1SS/uIktIzKgEjRwupC7s4Uc9+Dx8Kbl0HVLVd0+n3MY3iL3oz+c/y/P4Ukbmk5Fc4WUSNmTOCRnviidprOowRvCl5MI5OHUtncMYwfh8KgNbyxY8SKRM8jcpGacjOMGisDQ611XerNadVaksQhdLeaMHIEkQbH3FTUSF4JNV1CKC1tRkbguA7Y/Kg8z+g86BaRPEL2Dx0DwmRQ4JxlcjPNRusL/UptQdL4hfCykcSqFSJR2Cr5CtG18VDTmoY257PVC5I3zyiIGw5/j5kj1l7QdJshMg0+72ywSwn31OA6Ff981z+8nFzIWGSfjSPxMgPcfasE0bfnj59RWS2htmatbgld5WRaloI6ZxdGMz13TJB8xitVJYoR/DIYehrcNobxxHb8zE4WM92PoPj8KD7ok2bmruMAXKjZNbViDkVplZGKsCrA4IIwQa2opgJunKdZJNf3UFqrHMzrGPqcVJgtF1LXvwNqqkTXQjQjtt3YH/NZoEwsrmS/YgfhInkQn/8Qjan/vEH6Uf9lmnC41qa8btZwNID/nPur+rZ/wCmjVFCZ3xRH+x8h8KG1c+5ZJJwaPM/Aj2tTw2ttDbW5cpCghUucnaMheflj7VVnia5uEiHBc4qw6/CI5CFOR/agFverY3BkaPfwRnPIrb7XYwStiebMFvBBaEWixMzKKXlpbSQLC8asqjA9R9arl7pHh5aF8qOcN3+9G/x8N4MxyDP9J4IoZqs/hw7AeX4+lVdsMpZYjLYEAZEK1SGRjsKAsMVm7A+NKf402eawJyOSODNKGTTkUTynaisxPkBkmivSMaHV1uJQDFaRvcNkce6vH6kU90yx8TU7tQDLDZyOgHkzccfc0RpaPeBhJtiJ8AAb/OSqzVGDEANAPPghSWMr2kl2qjwY3WNmz2JBx/aiWraAmm6XbT72a5Z9k6eSEruA+eO9F7G2gsrG0sr7KhA2p3KYGQAMIh+dQdQ6nW+0y+hjjW0eWdZAEJLSA53bm+39qJmipoYXb49Ity53tc+wzOt1T/kzSSDdjog+Wn5PgqyTg0y5yxNOMabNZd5ujLUYgZUupGaZ4VyfeXOe/amLkgu5DFgXOGPc9+akWTSm6fwgCxz+bOO4pl4pJpzEkZaV3wEUZJOewq2dFEBmkWl1JZTiaIIWAI99Qw5BB4+tEEmveoA9pb2Vs82fFLIoV8AnzJ7e9/amLe0NpMJdQsblrdQdy8xnkccn4kGkajLYSGL93wTQAA7/EfcSc8YPypG2v0hkpTvGsIabdR+e6c/cOoBwjwqm5tg3yKAW/p79/hSH0fUINztZzgRnl1QkDn1H0qKs0qggSOAcE+8fLtUmHV9RgfxI765V+xIkPP/AHinHCTkq3TtwSI47pZWRVnWQZ3KAwYY5OfPjv8ACpUWsajGsIW+uFEMhlj/AIh91z/MPj8ahtcSyEs0jMSxYnPJJ7mpFrfSWsoljSHdt2+9GCMf88d6miY0npLnFwGSnL1Hq5mjne/mlkjVkRpSHwD3HOeKel6k1K7hEMskZAbfuEahgceop6zsLbULY6nq19Hp9qH8IeHCZJJW7kIowMDI5JA58603UfT+l+7pmmNPIP8A7xfASNn1CcIPsaKspImWc9waOF9fDVVDO512saSfLxRHpPTprzVre8ksmntY5leUn3YwAfNjgfrQTrDRr+31K5uLzU7C5aSVjvjnDl+e+B2z6UxqPVt9qhxPezsOwU8AD5DgfShLy7yShL/5j/xUu0do00sIhjBNuN7Z+/kmU9JM2bfOIGVrWv5n8KIyEeYpNTLzTbyyWGS6tpoVnTxImkQgSL6j1FMQ28txII4Y3kc5wqKWJ8+wrJSROa6xFkYa9pFwck1mthiCGB5HnWba1jFRZhPRO9uf3vb/AIqX/wBNiAErec69g5/zDsT58HvmhgJFOQyeEwbHbg/EeY+1JcBSwB4BqWR2OzuPH8/O1RxsDOiNOC2ZnMYjzhM5wPM+pqbo91e2F1Hc2k8lu6nAdTjP/IqHGgHvMM/CpNvct4yKib2JAVQMkn5CpadxEjXE2TZQC0ttkuo9TuniLdQRBI54kmVDyAGUHj4ZzVIuI1MRclgScACr7FazTaFYQXmTLDFgqy4KZOdv0H+9V+70gyt/BjMgxwE5Hzr1WvpHVMLX9WhWQ2fUNjBYTodexVCVGjYc4I5+VNTTSSkGRixAwCasUnS2qyElNOvH/wBMLH/aht/oWoWCeJc2N1AhON0kLKM+mSKxFVs6eMGwNkfiqonkAOF0JPvduTSMHvTrRkGm2zQN7SDmr4KNdP6npunWl+L2OWZp1WNYk43LnJBby5xWRaxqt7fo+lwC3MQISK1jAVFPfcfP5mgsbrG4Z4xIo/lJIB+3NSJ9Uup4vBL+HAO0MQ2IPoO/1zV6OvcI2xl1g3/zkTnfN3bpr2Ks+laXlwFyeemltPnaiFxbRmZ59W1QNOxy0cH8aQn4two+5qJNeWSAra2AH/5lw5kb7DCj7GoO7IrFR5DhFZvkM1BJVlx6Dde8+J49llI2C33H2Hl73WmYsSfWk4zUhbGX+fbH/rYD9O9LEEKfmlLH/Iv+5xVfcvOuXapd40aJ+2ZTK+Q574259fhTbyNHLvhZ1YNlSDhh6fWlWbP4rbGVT6sM+dIS6e1u47gYd45A/c4JBz5VJfLNINckqTULuaLwprmV0z+VnyKYxRePqVFj2fujTgSu0uqEMRx/xSItX09WLS6PA4CjaobAzk9+OeD+lPDWW+5Nc95OY80MrdPXdzbzKghgERB57dsAY+PIJ+tRwaTK6VLFPW8UlxMkUSl3dgqqPMk4ApleaI6fP+7Y5b/jxIxshz/WwIz9Bk/ar1LEHu6WQGZ7OKhlcQ3LVO9R3SQvFYQPuis0MKsDwz5y7fVs/QCq8xzS5JN/JOTTZI8qpV1Vv5C7QcB1Kanh3bA1TtE0W86g1GPT7BFe4kBKqzBRwCTyfgKfn6b1XT9SisLuzmtriV1jRZFxuJOBg9j38qhabez6deQXdvIY5onDow8iDXXtb6s1Wx/deu6ZGl/pOqqJVsrhPEEFwv50UjlTnkY+NXtm0UNRGSSQ4eiG7QrKmnma2NoLXA2vl0hna+YzGmXA5pHUEemdWX970YiJDqGlIsemTlv8ZkjAkib5kcfL4c66Ps9O6Lm1K3jKXOsWmnTXV/cA5W1wvuwofXJG4/DFVq39nvV2s30uszW66UJZTcG5vJhbhGJzkZO7z9KnzW2ldH9MdRQ/+VGnapqupQxwCO13PgeJuf3zwc/7Vec55eZXMsRfM8uHfwQ4Mj3YgikuDa4GeZIvcjQcbc/BczYknJ7+dJNLIyTWeGTWWcLlaq6SBlTWiPep1IiR9awwktwM/KuwGyTEE2FyDz50/AfCcOvBHY1kcBYEL7zE/lXk/YUqa2ltm2zRvC3fEilT+tPaC0gprjcWR6+6r1LU9LFlLdSF1/n3Yd1x+Vj5iq/Dcui+65XHpxWAMWGP0pPgt4hAHfmrc9ZPK4Pc43GSghgiiBawAA5qSuq3qflu7hflIw/3o501q91ezT6Xd3c0kF9H4QEshZVkyCjcn+oAfImgI0y8ZPEW1nZMZ3CNiv3xim4W8GRXWQAg5BB7Gp6Kulina+Qkgagngmz0zJGFoGfA9fAoneWLwuwKkEHBHoagPA+e334qz6trFlfLFOZYlmmjDyIP5X7N+oz9aAXy7SuGUhlDAqcgg0b21RUzbyQOBGuRGV1BSyvcAHixUUQx/wDrJlUf5QWNKItV/Is0h/zEKP0z/eteD/A8cuu3dt29mPy9aMpBoVk8wkma5Jxs8wo3jtjudoPfzIrOBnUB1n57K2T1oMJQPyRxr9Mn9c09DDeXobw1llRfzEflXgnnyHAP2oj+99LgjaO207cCNv8AEO4Hjv72cHIXtjgHGM1EutYkmvLqeGKO2W5jMTxR/l2nHHl6A/SuJA1d4LrX4J2Hp3UJV3tCYUyPek4BXJBYeoGP1HrUK8tnsrue1floZGjJx3wcU9c63qN2QZryYkE4wduOd3l8efhUMsWJLEknuSe9Me6O1mpQDxWlBPma1tLHb6UoFT/K33pfhp5sy/MZpgbdLeyZC/E0rbx3pe1ASBIOPga3sB7Op+tKGLsSbApSoTTiwk9tv3FPJAx7Ln6irEcBJ0THPAWWsG+VFY4UkZPoKZ1C/iucJDGYoUZiiltx58yfM8VPkhaKxnm2sNqYyRxknH+9XH9nj2cwe0b2i21tqMIl0mwQ3d4jdpVX8sf/AFNjPwDVYr3Opo2xD+wuezh5gpsAEji7kuZbwBygPzJrDKD2jQfIGvbPtc9gPRcfsu1Jenum4bS/0yF7u1e2z4sjgcq7HJcEDsT3AxivF+maXdatqdtp1jBJcXVzKsMMSDLO7HAAHzoLjKt2CsXQ3s06r9oTSL07o8l7HbyRxzTAhUhLk4LEntwSe+B9KtGqXHW3sTmuOmNTtEtmZzNDPs3q2RjfE5GNpx6Z79q9j+yroK09m3RVloNuEMyAy3Uqj/FmbG4k+fkB8AK5D+2nd2cfSvTts8ETXkl7K8UpHvJGsY3gegJKZ/0irlJXSU7rsVaqo4almCZocORXH+hfZR1t7Z7xb+4nnXTZI5nF9dSEqWTKhVHxfA7cAMfKuY6xpl5o2pT6ddo6SwOUIZSucHggHyPcfA19CvZHo0PTPsx6a04AJ4WnxSyk8e848Rz92Jrm3sh9n+gdc65rntT1iC31KTUtUnXTIn96K3gicorbexYhQBnsAMd6jlqpJXFzypo4mRtDWCwC4N7Mv2eutPaIYb02raVo0nP468GzxF9Y0/M/zxj416O079k72e2dgltcpf3ku0eJcST7WdvUYHuj/KPqTVp9qHVnWvTemxjojo9tfupAd0pmUR22O38PcHc/AYHx8q8vdce3f21WJNrqrX/TYY8qtl4DMfg7D9FIFQF7jxT7BekdG/Zu9mujWyW40P8AGlHMniXkhkZj5buwIHkCMfA0RtfYR7OLe8kvpelrK8u5G3vLdgy5PwUnaB8AAK8e3H7RftMvtLg0iLqG4iRMKJIhuuJT/mkbLHnyzj4V7d6aJ0DozTEv5Zmaz0+I3Mk7FpCVjBdmJ53Zzmmkk8UtggWodcezfoa8/c9iNLOrb/CTSdHtkkumk8kEcYyD88Y88DNBdZ9nXUftEBn1BtL6Ps50Dfh7OziuNROe4lnYbVPwTPP8xrx/d6z1B1d7Ur/Wum7e7uNVvNSlvLaK0jLP+csOF7gADPlxzXv60GrDpqGGe6ifWDZBXnddqfiDHyxC9hv8h5Ui5cys/wBmD2WaFmfWfxmoycu8up6gUDepIXYMVzS80P2DX3tS03RNPja2t7eVpbqZ7yJNPO0E+GS2WfJHkwAHnUzU/wBlOWaCbWesfaXJcPEheaeaIlUAGeZJXJA+n0rhmg+zq66o60h6f6amGuw+MBJdwROkKRhveclwDtA5zgZ8hS5rl9B4E0TRengsEdpa6La229VjUeDHCq7sgDjbjmudQe0X2GdTajBY/i+lru6mYJELiwChieMbnQAE5xgnzq4dYaBL1F0bqXTlrfLYte2hshcmPd4akBWIUEZ93IHI71QOifYb7PvZSBrV26317bDedS1V0VIP8yL+RD8Tk/GksuuqH+0T+zxo+ndPz9WdG6fFp7WIaXULNJCImi83jU52keYBAx2HFeYUffAAf5SRXpj28/tJ6NqnTuo9J9KML/8AHR/h7i/5EaR5G4Jn8xIGM+hPwrzDbnO4etWaeQh1uajeLi6fit2mWRlZR4a7juOOPn2+nnRKKx0mS1h33pjmki8Rix91G3lduMfXzOOaGxQPcSiGMjc3YE4yfSiGmaImpWzMtyIphMsRDj3BuwAc+ZJOMDsOe1WGtJ0bdRE9ack/8nrfKo11csobBx7rHJC/08EbSfiCPOhl/LBcXkstrCYYWOVjOPd+3lmi8OmaBGy+Pqkj4wCoXbk5GewOBgkcnjGa1Le6BbmVItPadsOiuWO3Jx7wyc8HIHbjnvXPYSMyB871wNtLlAhW80mt1VUiejdd3anpE3CoIODkVIEpI5NTxyAixTHN4hImQJ2rI2A5rbndTRGBTXZG4SjMWKfLDOc8U6mcZxj51EVjUiJxkLU0Ml3Zpj22Ceupj+DMQJ99hn6c/wDFewP2U+hn6V6EbWr2Mrea4wuEUjBjtxxH/wC1y3yK1509lXQI9onVUVpcN4Ok2KC4v5v8m4ARj/M590fDJ8q9bdZ9f2vQ3SGoatDHGv4G2Jt4Bwu7G2JQPTOPoKSucZH9gToQGt7V0KR45kMcoDxuNrqRkEHuDXD/AGM+we26H6l1bqjWIF/G/jbmPSocgi3t97BZcf1svb0U+p41+z111fa17NbeTUrlbi5tbqeAyFiWYbt+X+OZD9MUS9qftdPQnTc19AVe9kPh2ynzkPn8cd6pCM2xKYuzsuoWuu2d/cXttbTK72MwgnA7JIUD7fmAy5HlmvNn7RKP1z7aejejXOLQJEHYZyPGkzIT8kQVY/YRdT2ns9t7+5lke81W4nv7mZ2JMrNIwyfov61WY7iPXP2nb+4uCM6Tpo8MZ7uIUXPzHiH7U7d5A80mLVd7631+z0rofXroyGGG3024K+GcFQImChfj2Arxr7Kfb31H7LLeTTreKLUdKeTxjZzsV2PjB2MMlc8ZGO4B9c9o/aC1d7f2Y3qLNJH49xBB7pxvBJJU/DCn7Vzb2c/s+xa1ZQ6x1NqJit5QHjs7Mgu6+rSHhfku75iudGQ7CFwdlcroWh/tfRatdxWT9EalNcTNtSOxuBK7fAKVGT9q7cLi31/SI11HTiYbqINLY38avsyOUdcsuR54JrnPTnTfSHs3tJbjTLG1sFK7ZbuVsyMPQu3P0H2ql9d/tL6dooa26XVNQvRkeK65gQ/H+r5D6kU4swjpJMV9FRp/ZvpOgftH6d03pxkn0yK5gvjG7BmjQRiZkYj0xj5EV6K9q/V8Vt7OOpppV/Np8qYJ4Zn9xR9SwzXmr2FavNrPtOv9X1W6a61O5tp5PFlPLuxG9s/6cgD44FXH9obq21XpJdDtrtGvLi6j/ExK2SsQUyDPwJKH7UjWjCXJSTcBUr9mjqfUNC9pVrZ2sKTw36PFODhdiBSxfdtJ4APAIznmvR3ta686n0fpPPSFpNca1dXMcEKwWxuGjXBLttwR2AGT61wD9mqy05dT1zV7rCXNhbp4cskm1I43JDk8Y8lGSfXjzHVNe9tfR3T8ht5NV/Gy7cmOwXxgPgWB25+GTT44sTU1zrHJcuvehPbX1+5PUGpXEMco95dQv1iTHxjTOPlto77Dui+q/Zt7SpBfG0WzaylEu25UmZfdwyx7g2A+0biuBzTOvftK2/gNFoWgTPKwwJr2UKo+SJyf/aFVb2X9fNoupdSdS9QTS3csltEgZmLSO7SjaiknsACT6BKcaexC7GV6I9ovtst/Z9Dpc93ayXEV7ctC/hEB4kC5LqDw2CV4yO/enNUl6X9qfTMIvFg1nR7r+LC+SCrDjKnhkcdiOCOxFeUvaj7RpvaBqFuRbC3s7JpVt1z7zqzDDN6NtVc1B6G9ouu9BXEh0y43Wk5BuLOX3o5MeePJh5MOfLtxTTYOItklzIVl9pvsQ1DpGWTUNEaXVNF5YtjM1qPSQDuPRx38wK5rF7pFeqeh/alo/W8EaQypa6owO7T5G9847lD/ADjHPHPfjjNVr2i+yDTddSbVNDjj0/UwN7wIuILj14H5G+IGD5gd6cIh9zNE0uOhXABksArbc8ZJwOfU+lTLHSJrm6lt93g3Mce9EI5c8YAOQB3znPb1qNNFJazNHIpSSNsEehBp61sru5vY4AXjluM4ZiffGCT275qQAHhdMuQURTpy3imSC5v0WSRyigDb2KcgnuDuOD2O0moGrRadF4K2EjOyhlmLHOWzwRxjGCBx5g0Qj6RuQsxmmhTwzwRkhsNg5449c+XnikXOiadarKZNVQvtcxqNp3MD7oJBOM+uByPQ5qR8TsP22SBwvqgVYRWedbqmpUlVyaccYximy2KUr5705lhkuN9VYNO6P1DU9PF7C0GxgSil/ebHl8DQOaJo2KsCrA4IPcGrp0FqgEc9izdv4qD9D/tTfW+mW+DqETIkpbEiZA3/ABA9fWtVNsmGSgbVQagZ+/zkgsVfIyrdBLodPnzNUmloeaQcZon0zo8nUGvWOlxbd1zMEJbsq92J+AUEmsqMijRzXob2M2Meh9EwTJC0bX5/Eys4w03kpx/SOy/DLfzVU/2h+tnlt7LpeGUl3IvbzHkOREn6s2PitROsPbLDb2F5pvT0gbcFtYZ0XaEQDDuB5Z4VMdgGb+muSavq13rmpXGo30niXFw25iBgDjAAHkAAAB6CukkGHC1c1pviKtfs89q+sdAQyWVpBb3VjNP480EmVLHZt4Ycr5H6Ux1n1vrvtGuIZ7+KNY7GE7YbdSEQZG5zknk5UZ+AqpwRGRwoGSfL1r0z0r0Zo/TunhYrNBcz2iwXUh5Lkgbxz2yf7UR2Zs51S0lxsAgu3duR7MY1xbdztB2Wuivs+1yyj9men3KyrtsdPYOAuATEmZPsSAT61wk9e/8A2sz9VQyyizn1ESyLyPFt96nYR3wQo4+ArWsapP0VcdRdN219PcW8kBsofeOIg0qPIMepClT65NAejNO/evU+mWpXcslzHuH+UHJ/QGoX0x34g5GyJCpZuDUj7bX7rXXUOpOodV6ut9OubvT7nUIdFsvxN9DBL4KJdl3yrNgnhAo2rzz3FMf+cXrqWrRx6bZm5K7ELg+DCo4GFyWc4xyzY+FdWWKBxcRiNVW6YtIF43Fhgnj4VwjT9Jj1/wBqT200K/h1vZGeNMbVjjJ93jywoFG5tkNaG4Dneyy+yfqc1e+dKzC1gv8An3T0mg9a9e3d7qGvT3bpZ2zTkTkooJTcsaIBgZGCQB271zq5tprZwssbRkqGAYYJBGQfkQQa9b3k1vDaXMl0AIPDd5hnGV2+9+gryv1HqsmuaxdahKqo1xIX2qMBR5AfIYFQbUoIYYAW63Uv03tyo2lJIZGgNFvnr2ZLfTWuT9O3s17a5Fw1tNBG4/8AVmRChb5gE4+OKvWh+yvW9e1iK41yUi2YQT3Ds5LsrpnaP8wAUH0yKp/RGjjW+ptOsnH8OSdfE/0Dlv0Br0/vUyEgAbiM0myNnMkYZJBfkofqrb01E5sFP9zgbnlnlbzXnbUeib+XrW90DTIGZBL7ywAskSHkbvLgEZz55rpWi+xLQ7O3P7zubm+nPbwz4KJx2wMk8/GqX1E13pXtULWCLPfGeNyGdtplcA87SDgbgMZxgV3ITliFypPb3eATRSlo4w97gM7oNt/atdFDAIpLBzQTbIk5cdfRVGH2P9JRvueC7kPo1wQB9AKIt7O+kVhELaDAQOzFnDfcNVZ1y26/1vqG9GnXt5pmjibwonlcQjaBgsFHvMCQTnzzVh6a6bl0Pc9xq+oancyLtJllbwx/pTJ5+J5+VEGRgXsLIRVPqoow+SrJdYHCCSR1HQCyoXWvshFqk99ojs1uqmQwPyUAGSA2eRgE5Py9K5LIhRuK9E9a9Z6dpOjX9qsyTXs8T26RoQdpYbWLemAT9a8+zLliccUB25SsaGuaLFbn6Wq6uenJqs7aE6ke/amoZXjkWSN2jlQhldDggjsQR2PxFdG0b259RafDHDqCpqO3CvLI22R1HYk4I3j+rHP8wbuOchOa3tIrNgELUEhXzXde6Y67lluJ4f3Bq+PdughNtdeglVcmNj/WNw9fUUmWSeGcKZMPB7imNgQuPQjj6jvTaAdzn6VsYJwEJ+Z/4qQX5phstPLJJjxJHYDtuYnH3+QpGPTn5CpCwTN+RMfJacTSrmU88f6jTxTyP+0EpDI0alQyQO/6mteKB5D+9FI9AY/nf6AVLj6fhUZZWb5mrDNlVL+FlE6ribxVbzWwaTWxQoFXSFKtbya0kEsErRuAQGU4PNJmuHmYvI7Ox5JJyaaVSxAAJJ4AHnTk9vLbyvFNG0ciHDIwwVPxq2HyFmHPD5KLC3FfimSal2OqXOnRXUdsyobqLwHkx74QkEqD5ZwAfUcdiaiEYrMcVXKkST9z61sA5rfnRnRdJ0u8Ktf61HaZxiOO3klkPw4GM/WpIIDK8Nb+FHLMIm4nX7gT6JXSGlvqmv2FoDtEky5b0Uck/YGvScVx4jKikksftmqhoOi6NottDNptpCsu3H4hkzI3ryc7fkKNRzNI3AZvXAzXoWzdnGmgwk65ry36grhtCUOaCGtyz58fZcy6i9nXU3UfUGo6kLGO3iuLh3TxpkQlc8cZz2x5UZ9n/s7vunNZTU9Se2HhRuqRxvvbeRjJ4xwCat931BpVgStzqljAwXcVedQQPkDmo+m9RWetW73NhK8kSyGPcyFckAHjPlyKWPZ1Pvt4Pu1Uku1toS0phwgR2tkDppqSrNazb7iNc92ArnHs00xIdd17Ut/iokzWqSMMMzF9zHHlnj71Zr/V/wABo2pX6Izva2zuoDbfe7Dnv55+lVz2dE2fSsLfzTzSyE+vIUf/AA1YdFeYM+fM1RpYXx0czho4tb6k+XqrD1/qws+jNVfhjJGIFB9XYL/bNec39+T51132oXckvTKqrDabpN3PJ91sVzHRNLk1XUYLWMEmVwvHkPM/QZNZ7bkT31DKdvy62P0rCymonyO4kk9wC6d7IunPwcTa5OPfkVo4FI7LnBb9MV1S0uIstNMwWGFWlkJ7BFBJP2FVm3eO1gitoAEhgRY41H8qgYFQPaDrTaD0TJGDtudXY2yeoiGDIfr7q/8AUaOup20tOG8gsnOx+1K8F39j4N/4q/0HGde1/V+q71Q0zTMIgTwruSScfBcAfOuhJeeecGqP0eJtM6Xs4pnBactdKuMbFfgD45C5+op3qjqG50fp2W9tJRHcNMkETFAx5yzHkHyX9anhhEVNvX9pVnaNO+srC1vPCOQAy8OKvC3YLFm3Ox+Pf61u5v1ktpLcxLHFINr7WYMR6bgc/bFcTT2n9WTOuL4MeyqIEA+wHNFra666vCk0941qjcg3CqoI/wBGMn7VBBUxz5saT3LpPpmWE4pHtHefwrLe9DdNXIOILi3PfMMpI+zZoL1L7M4G0wXegRSXEsX/AKREHJcDyIQjP2Y/IUajvJfCjWaRZJVXDyKmwOfXb5VMtbw21td3XjmBYYHcSA42t/KQfXeVojPQMkZ0xrzT4KurgeDvCbHQ3N/fsXCprcxsQeCKSiBmC5PNHurbq1vuoNQubNQtvLcSPGAMDaWJ7eVBoYi8ihe+fKvO6umEc5Y3PNegxSl8YccslOstPhblwD658qKLYQKAI0X5im49OcBTnBPcCi9rZscDBNaKioQBhLEKqKjjiUKKxJP5aliwWJPElKonqxwKNQWUVsFa4OCeyjvQvqswssDxLt2grt/Ucfei/wDEbEwvI0Q9lQZZAwcULu9Tgg923TxG/qbgf/7Q/wDe13G27erA/wArKMU03PNNSqSvas7U1MhN2m3YjEcDALEXQIVN0vTpdTuRBFhQBueRvyxqO7H4VCorourx2KzWtzCJbS5AEoXhx8Qf9qy9C2J0zRMbN+eHbwReoLwwmMZqZotranXg8btLaWpacu4wWVBnn5nFP6XHaa9+Lhu4THcSM9yLxT/h+ZDj+mo6GKx0a/ngZmW7mFtCzjDGMe8x/sKgDVJI9NexjRY1kffK4/NIB2U/AUcbNFThrZALG7iNb3yAHLIXB4AoeY3yklpN8gD2Zk+1upQ5VCswDBgDgEdjSM1tmzSc1nXuzyRQBZS4nZHDL3BzTdSLK3kurqK3iUvJK4RFHcknAFLDcvACRxAFyuwdH6let05bSXlz4jTMxjXYq7I1O0DgDuQ36VnV+p+D0jqR3czeHbrzjlm3H9ENN2VkLCK209HDGECHeOxI7n5ZyarvX+pRDTbSyjdWZ5nuGGf5cYT9CTXqtWG0uziXHpYfNYCnpmT1wc0ZF1+4G/sqHvJbArrfS834HprToQpRnRpmz5lmOD9gtchU4aunadrNsbe2iuJQkkVjHO/IwkYUAD542nHxrM/Ssse/e+Z1suK0O3oy+JrQLi9/nijPUWptF0fqm1gvjCOE58wWBIH2pjpO8/8Aqpp5R1bY8qOB3U7yefowNV7rDqC1uunLaOFzuu2EyqP5UTKc/HIoX0b1NFpgmsroAW9wQwlwSYnHnjzBHB+h8qNSbUgZtFov0SNe1CI9mPdQus3PFe3YLH51K665bRa1YS2Usnh7mDq+M7WHbjzHJH1pHTujWGgI/gMZZW/NPIoDY9APIfXmplnps+rQLc6di7tzx4sWWAPofMH4Gm9Rt/3JCZtRkW3QchX/ADOfgv5j9gPjR90FI6TfkjEBqhwlOA0zXZE6dfr3I1pwe9uVUMEB53Hsqjux+lc46+6nPV3UkcVruaytwLSzjXuUzy3zYknPxHpW9T63ur2zn03TYHV7v3ZXHLmP+gY7A8bj58DgZyvpeE6Ru/FNDDPNgALcAyH0GB2/vWcrKhtdOKeE2aNXcEVoqM0TXTyDp6AdXNXK7Eg3M5jhCAIiMcHaoCqAO/YVA1K20/VYbWO7a4ljh3P4KMEUue5J5J4Cjy/Wn4tPmnjfYYty/mxIGbPpgefwpqSwa1G68mjtVPOZ3CfoefsDWrdHC5mB5FkJjIaRZ2Y5LLRrXTTu0+0trQ4xujTL4/1HJ/WlG5eYljk+rH/mlRXvTdtKscuqi7kIz/4ZdiD5yS4A+imk6/19pFjGItFO1wP8SNd8gP8A+rIMD/oQfOqz6ungHRFh4fvyUgglkeA1hJPE38+Kmx2bRBJL2aK0icZUznaWHqqnBI+PA+NVfrfq2C4UaXpUhNjGQzuO87gdyeOBk4AAA78k5qn3+rTXszyyyO7ucszMWJ+ZPJqCZCxyTWV2n9RB12Q+KP0exhG4Sym5HDgnSxkcc9zRezigjQZ5f4UIijz7x7Ucs7ckjg0F2e0veXEXKIVTgG2ujFku8rngCjkmqadotr+IeCSTJ2rgDlsZ8+1DLGA4Fb6mtS2hyPj/AA3Rv1x/vWxGKOFzxqBdZx4bJM1jtCUA1Tqa7u5HMLeCrH+X833/AOKr88rud7MSSeSTzTjPyRTUoyhNYqurJZyS5y08EDIhZospGmSNIkgYk4apjJlcUM02QRyyB2CgjPJqadRtwMbix+AplNM3dDGUkzHYzhCAUoGk09HazSbdsbYYEgkYGB35rPMY5xs0XRMkDVJ3sQFySB2HpWGpkWnpwZZxkqGCxjPBYDv286cuILWCGaPgTByF3E5wMfY9+CKvijkwlziB3qDetvYIbWqUyEYyDzyKwCqJBU10mn7OeS2uYpopmhkRgVkU4KH1HypvZU3TbaynuAl7eNaRYJ8RYTIc+QwCKkhacQsmSOGE3U/UeqLy4a7igkKW822NcdxGuQB9c5NDNT1CXUbkzyYHuogHoFUKP7UdGj9M456mlH/7a/8A/egt9bWcV/4NpdtdW+5QJTGYic4z7pJxRGtmqHtvK+47R1/lU6XcYrRtII5tI5cSByCgZp2S4eZt0jFjtCgn0AAH6AV1zW+g+h4Oq4rXS5vxkP4e9aK1i1ABLyeKYpHD4rqCjkAswxg4GwncDWtF9nfR19f9RQ3NwY0tUtSi/vBCLKSS3leVDIPdcRyKqF8Y8jyaECQjRELcVyOSZ5FUMxIRdq89h/2TSFbByKv9n0NpUmodLT3MhTStTsg80n4yNPEugsh8Hcf8LcyouWGF3Zo1ZdBdJ3PUhtL8fuyJtOjuZrc6pG34O7MpVLbxMYPigL35j8Tc3CGlMpJuVwaAucabrt9pMqzWlxJDIvIKn/btWahr9/qbs93dSTMxycnj7Dim7SyW4vLqCRPDdEkKR7+zjsuT3p+PTbY6c1zI21kikDfxB/ihgFXHfsaLRVNW+LC1xw2PHl/1U3tgbJiLelpe2aGFyfOn7W9mtN3gSNGWG1inBI9M96katp1vZR27QTJKcbJtrhsSdz8hzj/pNXjT+jOmLvSekLm6uDp8d/c+Dfyz3iLJISGOYxyqx8Ku9sFC3vAjBqk90lPLYnMclO0tlZcaIZpftQ17SbFrK1ltUt2TYE/DoAoPcjAHPzzVfvdZub6Zp55N0jHJOAP7V0Pp3ozpi/1nVrfX7EaH4QtUgtDqwkbdJv3bHAIZyFG1XwoJAYgEUN6Y6c6NkW2udduvDt/3KL24zcspExvjCQAis27wuQmO+CcDJq67bVQ5uEuVeLZ0ETi9jACdclQ2uXY8saSZWbzq66dpnSV7pWkqLaZZrrXvwEl1Je7GFruRg7R4wpKuQTnAK5q0WHQXRj9X6xpuokWVnAtslrvvmQyGSUqxU4bLbfyg4XOMkA5qoax7tSrO7AXIRzS0jLGp2n2djNdvHe3j2cK7sOYDI2QeAVBFEpNM0SNSYdcklbHANiy5/wDeq5BSukGK48QqktS1jsJB8CfMCyFxqSQnpVm0GBpkcMSSpGM0HgtwzDadw7A4xmrHpUsemxSTThtnGdoye9afZNNhfidohdfLdlm6o9ZWeAOKk6rpjXui3sEaFpGiO1R3JHIx9qFwdZWMbFRZzuo7HcAT9KPdJagmsXDE+Iqu+wK2DhuMVpDJG9hY08FnJIpoyJXC1iFyqfp7VoU8V9LvVQ/zGBgPvioV9p99Z2pnmtHijyFy/HJ+HevRXVNtBpnTUzXU6xe8pjVjjcw5wPjjNcm1q0h1BZAJN0Uygqw8vj9xWYk2NG+Jzo3G+dtEep9qvc4Y22HeqZoy2clypunQ5BAiKE5OODntUa4jWDUpFi4USHb8Af8A50TuOn/3e8Uy3BcBucgLih+qgNfkxENlVJ288is1URSQxCORoDgb9ZuEaie2R5cw3BCHCiiX7sqJEniOsfvM3u44wee/6+goWKk2bsshCI0jMMBR2Pz+FU6OZzHYQbAq1KwEXKkxWkkyOXl/w4gSqDJA5IB/7PenJGtbJ1VFDSYcFz72D7wB9M5we3H1psRXl2p3EIeCFAxuIOCTj0weTTotrWyxJJtOHUlX/Ns+XrwfI4onGw2uxtv9ndvLs/KrOOdie4KHdXSXG07PfCgFu2fpTQ9a3dyLNM0qBgrnIyMfT402reVCZpC6Qkm/XzVlrbNFk5SC3NOeFIQMDOfSmyjA8gio3AhKLLW4nilmGbLAxSZUgN7p4J7A1uFmhlSVc7kYMMHHIOaJPr8rymT8PGD44uFAZgA3u5yM852jv6mk7SlvyQv8PMWK+E+4ZBGw5471n4abAPgvhgWB2HkDzHwos3Ut54zTIkKSNnkDhSVQZAPA/IMfOmbfWp4FVSiyKtu1vtZmwQzFsnn1P6Cuwt5rrlDMfKsx8qVipN/eyajcePMsSvtVMRIEXAGBwPlSBotnqkLje3BRhBIybxG5XOMhTjNb/Dy7Q3hPgnaDtPf0+dELbWZrW3toUjQm2mM8bEn8x9R5inj1FOxQmGPKTyT9zyXGGHr58HuKXC3mluUJ/Dy79nhPuzjbtOc+lbNtMu4tE4CnaxKngnyPxqedZkEJjSJV9/cH3MWA3BsZzzyBz3p4dR3PhyIYo2Z5DJuJbzcMRjODyo5PIFcGjmuxFC2t5E3bonXZ+bKEbfn6UjHyotd67PfLdCaKIm52ZxkBCvmo7A/8modncPZXMVzGELxMHUOoZSR6g96e1gJHJNLiBko4WnFhbyjJ7DAX17felSMZJGkIALMWIAwMk+QoxD1HeCCCHZEUg2BcAgkKjLyRz2Y4PlnipGRglNLjZDFt5sE+FINp2n3TwfQ/H4VIhjdHw6kMPIjBotBr12VZBBEEaRJPMn3NmBnOSP4Yz61p5EubmW6kUIXO4gdhRijpC5wKqTSgBTdKgWRAAMFe9GnhtfwrLctiI4yRn/aggvooLVjFMiS490evNP2+pfiNHkjkbc+SM47YwRWzpZYo27rU2QGeOR5x6C/enL6PQobi1NrJIYicXHusSox3XPc1f9AtrS0ZXtY0iBxMAo7jyJrksj5YelFtP1+6i1G0nEkjeDsUoXOGA4I+VQ09UwPcCLXSVVE97AA4m3NdP9pGpR3eiTWbuzyxyLcxkdtmdv8Aua5da3LCKYMSRGuVHwqd1H1HNGqxeGjhxIrbySRkg44NArK6klhkdUDMQykAHHrSTSxRyCJhzCWlgfubu5quamxa+mJzguWAPOM80xA2JR8eKdvP8bPqBUdTtdT8a86nP+YnrWrYOgAk1IsbkW1x4jFgNpBwM+XHB471HxWVXikdG8PbqFI5ocLFExJd3a7lKRRvkDtyM8/3xWoLa3Nulxcu25gxILc4/lIHzB+dRIrqSJESM4Kybx55OBjinXiCN4l9Ixc9ogff+v8ASP1+FFGTNf0iC4gZ4tAcv3lxVYsIy07NU5cypdMIoYzIyltpQEADPHH6+VRUiPiBMjJOODmlyXDOpjQLFEf5E8/me5+tOaam66Tj8vvVBIRNKOZ7h+e8+CcOgwovFapEwJAPGKTdW6upYLzTwPrSjjHPajm6YW4bZIZjde6DSW5C7guKjtAy0YuEcnCDg0zP/hkleVFDJqRourjJihNbxSQ2G5p0gMMqfpQwC6tnJIxWYpRyuMjvSWYeVKRZIM1larW6lU1KsxSgtKSJnOFFOpCftUzIieCY5wSUjzipMdkZAMUlNkZ5fPwFO/jWUYRcY9TV+GOMfeoHucftWGwYeXby9acgsZDj+E2PjxxUVruXccyMBnOAcUV0zT49QUSi7zjuNuSPgc1cpYo5pMETbntAUMrnMbd5SLiZrVgilAMZzweaJiOG4h3Id7lO0eO+POm5dCkD/wALw5FPmxwRTsWiTLhnnji+Izx/ajsEM7HODmXHp36IfJLGQCHZoTLZ3uQBazZP+WiOnWN/EjKbUhWOf4gAH6mpjtZwDFzrb/6VkA/tk0z+N0Ec7Z7ojzO4/wB8U1kEcT8ZfY9bh7ApHTve2wb5H3slXUC2kL3E62bFRnwxN7x+QFDJNZtYlzDA4k7gnbgf3qXd63bC3kjtdLjUOpXJIBAI+VVRpCW5GPhVDaW0d04CF2vV7kBWKSmLwTKPP2urXeWk2pW0bILhhgMNyIg5Hzyai29pJaBlea2QE5Ic7j9qTZ67i2SCaByiqFyCDxSmOm3J9wpGx+JU/rxVsPp5bSxuu63Eke3umhsjLscMuoITrUcCtGYZFcnIbauBQzOMUbvtNVlysjYHPPP60NezZeBg1mNo00m+LsNgeSKU8jcAF1GIwa1W85GK1Qoq2E5DM8BJjIViMbscj5HypJB75zmkjilZp2IkWJSWzutq3rRHSFw8j48sUNJHlUm1vGt1KqoOTnmrFNI1kgc7goZmlzSAjgPwpYGe9DI9WX+eMj4g1Lh1O0cgeJtP+YYo9FUxO/shr4XjgpgXjtQ/Ul2QO3IHaicTJKPcdW+RqBrxCWsaebN/ap6to3DndSjgJ3gCA92p3GO3Bpo8GnIveZV9Tiss3WyMOS7gASY9ABTW2lTtmZyP6jWlbPFOfYuKRuQWtoIrADgUoLiszikwpbpSSFeRwacO5uWbPFRyc09E25MelSxuv0SmOHFbLVmSfeHApLViHPu+tSB2dklkmVvezSrW+nsn3wPsb+/0pubyIprvUJkcx+JpsVIGhzbHRGotSv73C/jJyzfyR4GftT66TdzkGSOVs+cr/wDJoBC5WVSCQQeCPKrPpeuhmWG8YA9hIfP5/wDNGdnTRVLsNU434G+XneyoVMb4heIBKh0B17tEnyGalJokI/PLI3yAFECQBkkYqFcavZW/D3MefRTuP6VqDRUcAu+w7ShQmmkPR8ksabZxj/B3f6iTTqxwxLhIo0HwUCg8/VNqvEUUsh+Puih83U1y+fCiijHxyxqs/a2z4PsIv1D3081M2jqH/d5lHLmwtZiT4QU+qcUKu9MWIEiZAPSQ7aFS6pez/nuHx6Kdo/SoxJY5JJPqeaA1m1qab7Iu/T0RGGkkZq9TclM+HIQP8rcGt/iJB+YK3zFOaYyvA0bYOGzg07LaxnsNvyquyF7oxJGdeCkLgHFrgv/Z"
local function b64decode(data)
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local lookup = {}
    for i = 1, 64 do lookup[chars:byte(i)] = i - 1 end
    local out, n, buf, bits = {}, 0, 0, 0
    for i = 1, #data do
        local v = lookup[data:byte(i)]
        if v then
            buf = buf * 64 + v
            bits += 6
            if bits >= 8 then
                bits -= 8
                local p2 = 2 ^ bits
                n += 1
                out[n] = string.char(math.floor(buf / p2))
                buf = buf % p2
            end
        end
    end
    return table.concat(out)
end
local function showIconImage(on)
    iconImg.Visible = on
    iconCrown.Visible, iconTop.Visible, iconBot.Visible = not on, not on, not on
end
task.spawn(function()
    if not (writefile and getcustomasset) then return end -- keeps the drawn icon as fallback
    local ok, asset = pcall(function()
        local name = "MisterHubIcon_v1.jpg"
        if not (isfile and isfile(name)) then writefile(name, b64decode(ICON_B64)) end
        return getcustomasset(name)
    end)
    if ok and asset then
        iconImg.Image = asset
        showIconImage(true)
    end
end)

-- soft glow pulse while minimized
task.spawn(function()
    while gui.Parent do
        if icon.Visible then
            TS:Create(iconStroke, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.65}):Play()
            task.wait(0.9)
            TS:Create(iconStroke, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.1}):Play()
            task.wait(0.9)
        else
            task.wait(0.4)
        end
    end
end)

local savedPos -- exact window position (never converted, so it cannot drift)
local iconPlaced = false -- the icon keeps the spot you dragged it to
local function minimize()
    savedPos = main.Position
    if not iconPlaced then
        iconPlaced = true
        icon.Position = clampU(main.Position, ICON, ICON)
    else
        icon.Position = clampU(icon.Position, ICON, ICON)
    end
    TS:Create(scale, TweenInfo.new(0.15), {Scale = 0.01}):Play()
    task.delay(0.15, function() main.Visible = false; icon.Visible = true end)
end
local function restore()
    main.Position = clampU(savedPos or main.Position, W * baseScale, H * baseScale)
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

-- keep START button + status dot in sync with the theme
onTheme(function()
    if not running then toggle.BackgroundColor3 = ACC end
    toggle.TextColor3 = running and WHITE or BG
    dot.BackgroundColor3 = running and ACC or Color3.fromRGB(150,65,75)
end)

-- apply saved theme + saved background
applyTheme()
if imgUrl ~= "" then setBackground(imgUrl) end
if fpsOn then fpsEnable() end
if hopOn then scanStaff() end

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

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

local EGGS = {
    {"Sprout Egg",{"sprout egg"},Color3.fromRGB(150,155,170)},
    {"Stone Egg",{"stone egg"},Color3.fromRGB(150,155,170)},
    {"Daisy Egg",{"daisy egg"},Color3.fromRGB(70,200,120)},
    {"Bud Egg",{"bud egg"},Color3.fromRGB(70,200,120)},
    {"Frost Egg",{"frost egg"},Color3.fromRGB(70,150,255)},
    {"Mushroom Egg",{"mushroom egg"},Color3.fromRGB(160,110,255)},
    {"Royal Egg",{"royal egg"},Color3.fromRGB(255,200,60)},
    {"Inferno Egg",{"inferno egg"},Color3.fromRGB(255,95,70)},
    {"Solar Egg",{"solar egg"},Color3.fromRGB(255,95,70)},
    {"Sealed Eye Egg",{"sealed eye egg"},Color3.fromRGB(235,235,245)},
    {"Abyss Egg",{"abyss egg"},Color3.fromRGB(235,235,245)},
}
local ALL = {}
for _, s in ipairs(SEEDS) do table.insert(ALL, s) end
for _, s in ipairs(EGGS) do table.insert(ALL, s) end

-- shared state (maxPer = 0 means unlimited)
local selected, running, delay, maxPer, bought = {}, false, 1, 0, 0
local tpOn, shopCF, autoShop, uiMul = true, nil, nil, 1
local iconMul, applyIcon = 1, nil -- minimized icon size multiplier + its apply function
local confirmOn, verbose, antiAfk = true, false, true
local hopOn, fpsOn = false, false
local buyMode = "seed" -- "seed" or "egg": what START buys
local shopCFs, autoShops = {}, {}
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
        if type(d.icon) == "number" then iconMul = math.clamp(d.icon, 0.5, 2) end
        if type(d.tp) == "boolean" then tpOn = d.tp end
        if type(d.confirm) == "boolean" then confirmOn = d.confirm end
        if type(d.afk) == "boolean" then antiAfk = d.afk end
        if type(d.hop) == "boolean" then hopOn = d.hop end
        if d.mode == "egg" then buyMode = "egg" end
        if type(d.fps) == "boolean" then fpsOn = d.fps end
    end
end)
local function saveSettings()
    pcall(function()
        if not writefile then return end
        local names = {}
        for _, s in ipairs(ALL) do
            if selected[s[1]] then table.insert(names, s[1]) end
        end
        writefile(SET_FILE, HS:JSONEncode({seeds = names, delay = delay, maxPer = maxPer,
            ui = uiMul, icon = iconMul, tp = tpOn, confirm = confirmOn, afk = antiAfk, hop = hopOn, fps = fpsOn, mode = buyMode}))
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
    if buyMode == "egg" then
        for _, e in ipairs(EGGS) do
            for _, p in ipairs(e[2]) do
                if t:find(p, 1, true) then return e[1] end
            end
        end
        return
    end
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
        local names, count, buy = {}, 0, nil
        for _, d in ipairs(p:GetDescendants()) do
            local nm = seedOf(d)
            if nm and not names[nm] then names[nm] = true; count += 1 end
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
    local egg = (buyMode == "egg")
    local best, bestScore
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            local txt = clean(d.ActionText .. " " .. d.ObjectText)
            local path = clean(d:GetFullName())
            local score = 0
            if txt:find("ouvrir") or txt:find("acheter") or txt:find("open") or txt:find("buy") then score += 1 end
            for _, k in ipairs(egg and {"egg", "oeuf", "shop", "store"} or {"seed", "graine", "boutique", "shop", "store"}) do
                if path:find(k, 1, true) or txt:find(k, 1, true) then score += 2 end
            end
            for _, k in ipairs(egg and {"sell", "vendre", "gear", "seed", "graine"} or {"sell", "vendre", "gear", "pet", "egg"}) do
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
    local m = buyMode
    if shopCFs[m] then return shopCFs[m] end
    if not autoShops[m] then autoShops[m] = findShop() end
    return autoShops[m]
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

local W, H = 480, 340
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
-- header logo (same image as the minimized icon; "M" shows until it loads)
local hdrIcon = tint(round(new("Frame", {Size=UDim2.fromOffset(32,32), Position=UDim2.fromOffset(10,4),
    BackgroundColor3=BG, BorderSizePixel=0}, header), 9), "BackgroundColor3", "BG")
tint(new("UIStroke", {Color=ACC, Thickness=1.5, Transparency=0.2}, hdrIcon), "Color", "ACC")
local hdrFallback = tint(new("TextLabel", {Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Text="M",
    TextColor3=ACC, Font=Enum.Font.GothamBlack, TextSize=18}, hdrIcon), "TextColor3", "ACC")
local hdrImg = round(new("ImageLabel", {Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Image="",
    Visible=false, ScaleType=Enum.ScaleType.Crop, ZIndex=2}, hdrIcon), 9)
new("TextLabel", {Size=UDim2.new(1,-100,0,20), Position=UDim2.fromOffset(50,3), BackgroundTransparency=1,
    Text="Mister Hub", TextColor3=WHITE, Font=Enum.Font.GothamBold, TextSize=15,
    TextXAlignment=Enum.TextXAlignment.Left}, header)
tint(new("TextLabel", {Size=UDim2.new(1,-100,0,12), Position=UDim2.fromOffset(50,23), BackgroundTransparency=1,
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

-- ===== menu page: list of rows with ">" -> sub pages, "<" goes back =====
-- (moved above the Auto Buy tab so both Auto Buy and Settings can use it)
-- add(name, build, onOpen): onOpen runs when the row is tapped
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
    local function add(name, build, onOpen)
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
        row.MouseButton1Click:Connect(function()
            show(name)
            if onOpen then onOpen() end
        end)
        build(sp)
    end
    return add
end

-- ===================== TAB 1: AUTO BUY (menu -> Seed Pack / Eggs) =====================
local buyPage = addTab("\u{1F331}", "Auto Buy")
-- leave room at the bottom for the START bar
local buyArea = new("Frame", {Size=UDim2.new(1,0,1,-56), BackgroundTransparency=1, ClipsDescendants=true}, buyPage)
local addBuy = menuPage(buyArea, "Auto Buy")

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

-- opening a sub page decides what START buys
local function setMode(m, userPick)
    buyMode = (m == "egg") and "egg" or "seed"
    if userPick then
        for k in pairs(cooldown) do cooldown[k] = nil end
        saveSettings()
    end
end

local function buildBuyList(sp, items)
    local top = new("Frame", {Size=UDim2.new(1,-6,0,32), BackgroundTransparency=1}, sp)
    local selAll = smallBtn("Select All", UDim2.fromOffset(0,0), UDim2.new(0.5,-3,1,0), Color3.fromRGB(50,100,190), top)
    local clr = smallBtn("Clear", UDim2.new(0.5,3,0,0), UDim2.new(0.5,-3,1,0), Color3.fromRGB(150,65,75), top)
    selAll.MouseButton1Click:Connect(function() for _, s in ipairs(items) do selected[s[1]] = true; paint(s[1]) end; saveSettings() end)
    clr.MouseButton1Click:Connect(function() for _, s in ipairs(items) do selected[s[1]] = false; paint(s[1]) end; saveSettings() end)

    for _, s in ipairs(items) do
        local name, color = s[1], s[3]
        local btn = round(new("TextButton", {Size=UDim2.new(1,-6,0,38), BackgroundColor3=PANEL, Text="",
            AutoButtonColor=false, BorderSizePixel=0}, sp), 9)
        round(new("Frame", {Size=UDim2.new(0,5,1,-12), Position=UDim2.fromOffset(6,6), BackgroundColor3=color, BorderSizePixel=0}, btn), 3)
        local label = new("TextLabel", {Size=UDim2.new(1,-62,1,0), Position=UDim2.fromOffset(18,0), BackgroundTransparency=1,
            Text=name, TextColor3=WHITE, Font=Enum.Font.GothamMedium, TextSize=13,
            TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd}, btn)
        -- thumbnail (hidden until its image is loaded)
        local img = round(new("ImageLabel", {Size=UDim2.fromOffset(32,32), Position=UDim2.fromOffset(16,3),
            BackgroundTransparency=1, Image="", Visible=false, ScaleType=Enum.ScaleType.Fit}, btn), 6)
        local check = tint(round(new("TextLabel", {Size=UDim2.fromOffset(24,24), Position=UDim2.new(1,-34,0.5,-12),
            BackgroundColor3=Color3.fromRGB(50,55,75), Text="", TextColor3=BG, Font=Enum.Font.GothamBold, TextSize=15}, btn), 7), "TextColor3", "BG")
        rows[name] = {btn=btn, check=check, color=color, label=label, img=img}
        btn.MouseButton1Click:Connect(function() selected[name] = not selected[name]; paint(name); saveSettings() end)
    end
end

addBuy("Auto-buy Seed Pack", function(sp) buildBuyList(sp, SEEDS) end, function() setMode("seed", true) end)
addBuy("Auto-buy Eggs", function(sp) buildBuyList(sp, EGGS) end, function() setMode("egg", true) end)

onTheme(function()
    for _, s in ipairs(ALL) do
        rows[s[1]].btn.BackgroundTransparency = 1 - panelOp
        paint(s[1])
    end
end)
setMode(buyMode)

local bar = new("Frame", {Position=UDim2.new(0,0,1,-50), Size=UDim2.new(1,0,0,50), BackgroundTransparency=1}, buyPage)
local toggle = smallBtn("\u{25B6}  START", UDim2.fromOffset(0,3), UDim2.new(0.5,-3,0,44), ACC, bar)

-- ===== START / STOP button style =====
local STOP_C = Color3.fromRGB(225,65,80)
toggle.Font = Enum.Font.GothamBlack
toggle.TextSize = 16
toggle.AutoButtonColor = false
local tgCorner = toggle:FindFirstChildOfClass("UICorner")
if tgCorner then tgCorner.CornerRadius = UDim.new(0, 12) end
new("UIGradient", {Color = ColorSequence.new(Color3.new(1,1,1), Color3.fromRGB(170,170,170)), Rotation = 90}, toggle)
local tgStroke = new("UIStroke", {Color = WHITE, Thickness = 1.5, Transparency = 0.55,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, toggle) -- Border = outline of the button, not the text
local tgScale = new("UIScale", {Scale = 1}, toggle)

local function styleToggle()
    local base = running and STOP_C or ACC
    toggle.Text = running and "\u{25A0}  STOP" or "\u{25B6}  START"
    toggle.TextColor3 = running and WHITE or BG
    TS:Create(toggle, TweenInfo.new(0.2), {BackgroundColor3 = base}):Play()
    tgStroke.Color = base:Lerp(WHITE, 0.45)
end
styleToggle()

-- press feedback
local function pressTo(s) TS:Create(tgScale, TweenInfo.new(0.08), {Scale = s}):Play() end
toggle.MouseButton1Down:Connect(function() pressTo(0.95) end)
toggle.MouseButton1Up:Connect(function() pressTo(1) end)
toggle.MouseLeave:Connect(function() pressTo(1) end)

-- soft border pulse while running
task.spawn(function()
    while gui.Parent do
        if running then
            TS:Create(tgStroke, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.1}):Play()
            task.wait(0.7)
            TS:Create(tgStroke, TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {Transparency = 0.7}):Play()
            task.wait(0.7)
        else
            tgStroke.Transparency = 0.55
            task.wait(0.3)
        end
    end
end)
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
-- (menuPage now lives above the Auto Buy tab)

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
            shopCFs[buyMode] = h.CFrame
            b.Text = "\u{2713} Saved"
            task.delay(1.5, function() b.Text = "\u{1F4CD} Save shop position" end)
        end
    end)
    buttonRow(sp, "Reset shop position (auto-detect)", Color3.fromRGB(70,75,100), function(b)
        shopCFs[buyMode], autoShops[buyMode] = nil, nil
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
    -- NEW: resize the minimized icon (50% - 200%)
    stepperRow(sp, "Icon size", "Resize the minimized icon", function() return iconMul end,
        function(v)
            iconMul = math.floor(v * 10 + 0.5) / 10
            if applyIcon then applyIcon() end
            saveSettings()
        end, 0.1, 0.5, 2, pct)
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
-- NEW: icon size (UIScale also scales the text, image and border)
local iconScale = new("UIScale", {Scale = iconMul}, icon)
applyIcon = function()
    iconScale.Scale = iconMul
    icon.Position = clampU(icon.Position, ICON * iconMul, ICON * iconMul)
end
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
local ICON_B64 = "" -- optional: paste base64 here; empty = loaded from ICON_SRC (V1 file)
local ICON_SRC = "https://raw.githubusercontent.com/Mister62-dev/Roblox/refs/heads/main/GrowaplantV1.lua"
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
        if not (isfile and isfile(name)) then
            local b64 = ICON_B64
            if b64 == "" then
                local src = fetch(ICON_SRC)
                b64 = src and src:match('local ICON_B64 = "([%w%+/=]+)"')
            end
            if not b64 or b64 == "" then error("icon data not found") end
            writefile(name, b64decode(b64))
        end
        return getcustomasset(name)
    end)
    if ok and asset then
        iconImg.Image = asset
        showIconImage(true)
        hdrImg.Image = asset
        hdrImg.Visible = true
        hdrFallback.Visible = false
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
        icon.Position = clampU(main.Position, ICON * iconMul, ICON * iconMul)
    else
        icon.Position = clampU(icon.Position, ICON * iconMul, ICON * iconMul)
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
    styleToggle()
    dot.BackgroundColor3 = v and ACC or Color3.fromRGB(150,65,75)
end
toggle.MouseButton1Click:Connect(function() setRunning(not running) end)
cam:GetPropertyChangedSignal("ViewportSize"):Connect(refit)

-- keep START button + status dot in sync with the theme
onTheme(function()
    styleToggle()
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

-- ===== item thumbnails (embedded; saved once as files, then shown next to each name) =====
local IMG = {}
IMG["Basic Seed Pack"] = "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"
IMG["Garden Seed Pack"] = "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"
IMG["Sunny Seed Pack"] = "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"
IMG["Floral Seed Pack"] = "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"
IMG["Crystal Seed Pack"] = "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"
IMG["Moonlight Seed Pack"] = "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"
IMG["Ember Seed Pack"] = "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"
IMG["Aurora Seed Pack"] = "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"
IMG["Golden Sun Seed Pack"] = "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"
IMG["Dragon Seed Pack"] = "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"
IMG["Phoenix Seed Pack"] = "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"
IMG["Cosmic Seed Pack"] = "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"
IMG["Mutant Seed Pack"] = "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"
IMG["Void Seed Pack"] = "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"
IMG["Celestial Seed Pack"] = "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"
IMG["Spooky Seed Pack"] = "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"
IMG["Sprout Egg"] = "/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAQDAwMDAgQDAwMEBAQFBgoGBgUFBgwICQcKDgwPDg4MDQ0PERYTDxAVEQ0NExoTFRcYGRkZDxIbHRsYHRYYGRj/2wBDAQQEBAYFBgsGBgsYEA0QGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBj/wAARCABQAD8DASIAAhEBAxEB/8QAHQAAAQQDAQEAAAAAAAAAAAAACAQFBgcCAwkBAP/EADkQAAEDAwMBBgUBBAsAAAAAAAECAwQFBhEAEiExBwgTFEFRIiMyYXEVFoGhsRcYQldic5GVwdHT/8QAGgEAAgMBAQAAAAAAAAAAAAAAAwQBBQYCAP/EAC0RAAEDAwIFAgUFAAAAAAAAAAEAAgMEESESMQUTQVFhcaEiI4HR4TKRscHw/9oADAMBAAIRAxEAPwAcAvJ1uSM+mkqOudKEqAT111DVh4uqeB4eLlZ7R7aek2fcy7ZRcLVElu0tfSU0jejjr06Yxz7aYi4PfUgti/Lns55xdAqa2G3ceLGcHiMu8g/Eg8c4wSMHGRnUyzSFvybX8/jb9ipkOPhTE22466lpptbjijhKEJKiT7ADXsiPIiSVR5TDrDyfqbdQUKT+QeRq97quujWla9v3pb9uMxqjccZUmQtB2AOjGeOcJzkgA6oep1ibWau/U6i+p+S+rctavX0A/AAA/doVFXuqLuLNLfJzcGxx2SonDs7LX6ax1gF518Vgas9Y3Ulw3Wjft1mHMjWt1JB05W7bNwXbXEUK2KXIqVTeQtTUZjG9QSnJIyQOBzrHte5uAlm6x8IVhdhnZCO2e86nQP2h/RzBhCZ4oj+Pv+YlG3G4Y+rOdXx/UQP95qv9qH/rpwct69LDriE2XbsyksmDGYUqmQU7iQw2XEqUlJUfmbicnrol6ROqDVg0uZP8VUxUVgvh4YVvUEhW4e+SddsrGNGVpWcJaxjS/JPqqCuzuoN1js3ti1jenhuUoBgSzTworBznjfx1HGfTUHn9xwQUIV/SSVlRIx+lgen+ZovQ++9drkVxK1R2o6XEkj4QsqPr74GvZzyQiW68lLgbbyyF9CrBOB7njQua2Np0AjP5KlvC6a4u33PX6rlJf1sGx+0qs2n53zv6bI8DzGzZ4nwg525OPq99Rzfxo6O8X2cW9clkXJcFEtqlm42vCd88nDayhAC3cqzhR2hQ55PTQKDJTkeuiMrnvZYKg4lSPpZNPQ5Hp2+iclMZV01d3dMhOK70dHdDC1ttxZRWoIJCMsnGT6fbOqe2jRwd0al02n9ir9UlR4qJk6e6tuQkfNU2nCAlRHOAoLIHT4vvpyr5cURJ64V/FSAuuBtlEFMjwP1FlS4YcfdPCwcfT762PuMy5IpUqMpQeTk5PGBz6fjUSpFRaqF8NtmrylvtKVuiqOEghODwR/I6k8xQFaZT5pMZRaKkrIGcg4xz+dZqjqBMC8iwva3jF0WjnM+om+Nr9MfdOkKEzCYLTIWEk5wpZV/PTe9AjOUdUVxvc23lSRkjBGSDnSmk1BNQYeIcQ4WXVMkp9cY50jqjhgtIYQ6TuI+rqrOc60c0Qkp2iPZFF2yZ3URkWY3cll1anGZ5VUxh6OXPD3bStsp3YyM43dPtrmjeFsfsnfdXtnzfm/02UuL5jZs8Tbxu25OPxnXUpc1lq25TsAyG5CWd5ykgFWAMjPGgb71FMMbtfhVAlvEynIwhKcEFtRSSfcknSXC9Bfyj1HuvcTp+e0vd0KoqBU4lRSvy6nAtASVtutqQpO7pkKA9jz9jo5+6PU3z2eopzyQGGUPutrPHBd5/idAVNkJp1ZZqTyXTHUwth5aEKXswQtJIAOB9Yzrob3VKY273fqXVGXUkPiW0oDHq+dp+/GvVM3Pp2Ob3H9o0VmFwd1H2V+JQw6pEhKG1HblLmATg+x1i/FjSkhMmO08B0DiQrH+ukLTtQhU3w3orRDDQG9LmQrH2xkcaRM1lx2oiSuE+WUIKCWQXOSc8gfjVc6oja4Rnc+Evra2UR3ydkoq8RuLRVJgpMY5AHgnb689NfVpaG6Iw+6T8paFbupAxzr2tzUi2Vy2wvBxgKSQeeOh1Ab0umTGjIjN019ZcbbSl3Pytw3ZBPp1GuJ6psJLb2uMIslTHC1plNjn2sn2uXdbL8aFDjy0relPBKEIbIOQknCuONB93sJUeR2l0Vll1Klx6epDiR1SSvdg/uOripglVO6aM3KiriLbeWsAOBecIz1Hpqiu8+mO12xNobcCnjFSt1OeU5xt/gNG4FO6acPd52S1HVPqKJz5Lb2/hUiUgggj4TwfuNFl3DK5DYsm5Lcl1RhE5qY2hmG48AtaW0lBUlBOcfRkgeozoUcDGtFk1yq2J2gJqlIlJcnwlpqEV+W2HPiVuQrcON2CPX/jSdLMWNcPT/e6bl7rqjc8WemlVKY2pSWyyVfLcx/Z1E7PuGch+TFXOWp1SQtIWN3A4OqWR3xLZet8wZ9q3Gt56N4L6mn2AgrKQFKSkq4GckDUXZ7zFvU6oomU23aypQTtKZCmcEH8K1VVNO7mcyG9zfr18LP1lG9sokgJRq1FPnKE0CUr3KQTjoeedNlwQaKltpLkdBW280vZyRyTg46HodDDa3fAtyg02QzLtSvSnHn1v7UvMBDe70Tk51nWO+JbFSdDqLOrrSyhIUkvMEBSdxGDnplXt6aty5kjQ54F/P3V1EY3BnOAxnv2RMXFGpUekCqxY0RoNpOXkJSnak46n2/61zm7Z7mp109uVfrFJfEiGt1DTTwOUuBtCUFSf8JKTjT92jdv1z3dBeoVDkzKVQZDHgyorpQtyTkgncoA4AxgBJHrnVPc6LHU8t2tgsSlaupGnkxfpB3X/2Q=="
IMG["Stone Egg"] = "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"
IMG["Daisy Egg"] = "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"
IMG["Bud Egg"] = "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"
IMG["Frost Egg"] = "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"
IMG["Mushroom Egg"] = "/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAQDAwMDAgQDAwMEBAQFBgoGBgUFBgwICQcKDgwPDg4MDQ0PERYTDxAVEQ0NExoTFRcYGRkZDxIbHRsYHRYYGRj/2wBDAQQEBAYFBgsGBgsYEA0QGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBgYGBj/wAARCABQAE0DASIAAhEBAxEB/8QAGwAAAgMBAQEAAAAAAAAAAAAABgcDBQgEAgD/xAAwEAABAwMDAwMDBAIDAQAAAAABAgMEAAURBhIhBxMxIkFRFGFxMoGRsRUjQpOh4f/EABoBAAMBAAMAAAAAAAAAAAAAAAQFBgcBAgP/xAAyEQABAwMCAwcDAgcAAAAAAAABAgMRAAQFITEGElETIkFhcYGRobHRwfAHFBYyNFLh/9oADAMBAAIRAxEAPwDM2DmpUJr0Ec0SaY0hK1KHnGZTUdplQStS0lRyQSMD/wC1CoQp1XIgSapbe2du3QywnmUdhVMzFlOoC2Yz7ic/qQ2VD+QKvNGdK4V8jSTMmXuIwyrYmM28tCSDzjn288D+ae+hRatH22HbXo82fEbJckf7ktLWtQ9WwgHanOMZyceaKLvqXTkhDarLp+4xJCVcuSZ4dSUnyNoQOfHOaobPFpaha1eoj/vhVrjuC1odaXdtlQjVOkA9CeadDroDS+svTbpbbH1OOdK7dd1FsI23SbLkpT90guekn7V13fQPTmZBbDPR+ywO0SUi3uSGSvJ/5ErVnFEEm+LfbARHwvIOSvjipf8APKWxsXH9WCOFcU2LTShymqj+l8eNRap+T+aQutNDOwNQK/wFpmhmQ7tYhpSt4pG3PpUeVDg+aWVybdXemLattbbkdwPvhQKVN4ztT9io5/YH5radi1FZrZEkOX+zTJ5S2kNCJLDOAnOc5Sc5yP4oK15pvQmoCqa9Gv8Ab2UP70/TOsOL2qAT6ipGVEHJ/GBQKrJtBK2vipTMcIuKWtdo2QBEDSDtMEqnz1HkPCs25r7dU9yhLt11fhLWFlpWNw8EeRXJmgCINQy0KbUUKEEaGjjQlgVdNSRJkyE3ItTT22T3CMY2k/p8nyPFPa327SlrtalWyDDilxIUtKElJUR4yPxSy6XRL2NEai1EizuyNP2dTb1xlsrAcbCxtAbQrhw8AkZGAcnyKO7ZqHpzebUH4OpLy3MCQVxpFnJS2fcFaHDnj3ANF4ZCClLbYlavCNfb99av+GbzDWjKS64Q8Tr3SY8IBCdBG+tEjTtidjZSlgEedwxUcKRZHEFCgxvGckggearG1aYeCi1qhJCfJNufA/qra3WjStxid1PUWyRlglKmZMeQhacfI2H81Sqx16mCWT8Gq05rGAf5B+FfivAk2Nu4qac7G3AxgE817mv2VjY5mOElYCsc8V0JsOk++GT1P03vI3AdqTyP+ui+L0SuMuxMXqPquyOwH2w42+lL2FJPg425ody3uGx32yJ6givNWexSTJuPor8UHBdhkRcp+nUggjn3qugy9PzmTEnfTurUrPbUDj2o3v3RvUliabfM62yWFgf7GlLyCfbbtKv3xihAadtsbUC/87q+y2RbLG3ZMD25W45BwG/GAea4Qy+5qhsn0BNcjMYwo503II9dfjf6Uu+o2mbCuLMVa7VCblPJT23wCMEeTnnnAxikQU808+qep7Baeza7DfYl/fUjuGREbcSy3njBKwCT5OAKRxPNI70AOERBG4rO+KHrF59CrIzp3tIEz6DXefai3p/1d1TpTp1q/RkN1Col8R9JIWFKbU2pOP8AagDwVIJSoHgjFFvS21tyLLKVNiLY7zqXIkwrACgkFKkBPvzjn7YpDlMhuS6uJMSwh071gthZCsYJGTgZ4z+K0r0niKR0rhGS46+panM99Iz+s4OMD2xT3giyLuWSsq0QkkD4EbbanakePbBd2q7b0oW1reamkpUTwckefjNczml5bEoyY7il5IJCVlIPHweKII0V1iKWC8sJCiUds7eD7H5r1BdmNx/ppLPAGO5vznn4rauzToCKd9mnpQy9p64uvJf2ONqQCNyHB481szptHE3oVpdkuuIzbmSHE43Aj3rLEdcpu7uMll1bL60JC0EekHg+a1JaIsqxWi06ftbylw4qAy2h0gHahORlWPPFSfFCe42lOhkn4pZkWOZI5TESdfKiOLHfZ1UpC5Dr5+j/AFLAB/X9qyt1nsjl56s36aZy0dlIZShKjgJSjPPzySf3rXcBxLqzKkRUtSNvb3Be/wBOc4yPvWPepc25TdfaluC2Gmd7ykYYWQMJAQCUnySBzSzhgFdysqGyf1FAYsFTyuYbCk/rzRFmtOiZF1QpbsxtCEJWo49xzgHHuaTRVzWkdaWWPdNPot3EcSCUFbaRkenI/wDRSWt81vRl2uFvvGl7TeHSpKUm4IcIQE7vUjapPCsjznwKT8b4wsXKbhCAlChBI/21JnzII9faj8haLbSH0p7hMT57/Y0tH3sIVz7H+q1/YQ6xpOI8kbwuEwpKAOchtNYxW4pYKE5JVwB8mtiWWdIZ0zb23o62VIiNIW05jchSUgHwcZ4pvwCwVPPcvQfc0Vw1j3r9xxLI/tEk+FXUF1aoZC3d5B4ygpIzz717gTmZUXYvAkAcpwQeDUwUyuOlxtWc+2a+jqafi99HB+CPvWiAba0aPCqp2dJS+sIe4CjjAFGWlJWrYcVOqIbbsyPH75PccKklaWyACnOTjdn+aFGrcy8+42JKgpB5BT8800ulElDv1Gj5jLLsR1Dj6VqBC9xASRn4wa6Zl5tNoShIMRPp41W5e/xZtUhhIJBE92JA31gfegG9691HfpjcmZKQ2ttGwfTAtAjOckA+eaovrZbiAyX8pUQCVjJ85znzUl3t67Vf5tsXnMZ9bWcEZAOAcH7Yripu1bMBsBtICSNIFWCcPj1tENtJAUN4Hj0qt6iz7hbrEqTGlYdQkrQvYODkD+jSNut1uF6lJfuUkvrQnakkAYGc+BT31PBTqCzCAtexa2FJC/hWRgn7cCkNcIEq23J2DMb7bzRwoeR9iPsaxv8AiA1dtPJMnsSI3PLzAncbTG3l6Vjebs7y0TCyezJI3McyTGo2np5UumJT8KczLjr2PMrDiFYzhQOQafnTnqmvUU02vUEVKHm2y4ZMdPpWBgcp9jknxxikC6nmrTTF6k6fviZrCUqBHbcCk5ygkZxz54pRiMxcY13mZXCTuPA+37NIcdl7zGqV/KrKebceB9v13rY9qn2uch8W1SCWlYcCRjHwf7rsjwmW8yI4wDnO1Rx/FIGNr+0qUVx49wbUryQEpz+cKrvidQHIqS2zLuSWTkhvjjPPndVu3xjZgAOkT5UY3lTA50fFPFiGBc0S0PPIIWlS0tng4PuPxT5g6205fr7Dt1sfksS3Fq7ZMYJScJJIJ/ArDrXU64xnlqYkSSlQGd6Ek/zmpz1TuK48VSJcyNNjqDiZUZIQsLHvkGhMhxBirxGqyFAGOkmuy8g0sTymfatT9RLBpmNrVcu9quhkTW0vEwe2lPHpJO7PJx7cUqrku1x7I/d2EOJjpXgIUvcpI3YwT7mle/1Yvc6YJN1vV3nOIQEIU+oLwMnjBP3qkd1TAcgOsbJhKyo4ONvJz816W/GFuwwlAckgRvp5RRo4qvkshpK1aCN4jptR3q7WsW2R4si1xO6n1IKXAUgZ58/tSp1Be3r/AHtdwdZQyNoQhCedqR4yfc8+a4HX33hhx1ak5yElRIH4FRVA5niS8ykocVDcg8vhMb9aXXGWvLhrsHXCUzMefXr9a//Z"
IMG["Royal Egg"] = "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"
IMG["Inferno Egg"] = "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"
IMG["Solar Egg"] = "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"
IMG["Sealed Eye Egg"] = "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"
IMG["Abyss Egg"] = "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"
task.spawn(function()
    if not (writefile and getcustomasset) then return end -- no file support: lists keep the colored bar only
    for name, b64 in pairs(IMG) do
        local r = rows[name]
        if r and r.img then
            local ok, asset = pcall(function()
                local fn = "MisterHubImg_" .. (name:gsub("%W", "")) .. "_v1.jpg"
                if not (isfile and isfile(fn)) then writefile(fn, b64decode(b64)) end
                return getcustomasset(fn)
            end)
            if ok and asset then
                r.img.Image = asset
                r.img.Visible = true
                r.label.Position = UDim2.fromOffset(54, 0)
                r.label.Size = UDim2.new(1, -90, 1, 0)
            end
        end
        task.wait()
    end
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

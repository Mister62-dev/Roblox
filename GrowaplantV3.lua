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
    {"Tide Egg",{"tide egg"},Color3.fromRGB(70,150,255)},
    {"Frost Egg",{"frost egg"},Color3.fromRGB(70,150,255)},
    {"Geode Egg",{"geode egg"},Color3.fromRGB(160,110,255)},
    {"Mushroom Egg",{"mushroom egg"},Color3.fromRGB(160,110,255)},
    {"Royal Egg",{"royal egg"},Color3.fromRGB(255,200,60)},
    {"Sun Wing Egg",{"sun wing egg"},Color3.fromRGB(255,200,60)},
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
-- switch: Seed Packs / Eggs (decides what START buys and which list is shown)
local segSeed = smallBtn("Seed Packs", UDim2.fromOffset(0,0), UDim2.new(0.5,-3,0,32), PANEL2, buyPage)
local segEgg = smallBtn("Eggs", UDim2.new(0.5,3,0,0), UDim2.new(0.5,-3,0,32), PANEL2, buyPage)
local selAll = smallBtn("Select All", UDim2.fromOffset(0,38), UDim2.new(0.5,-3,0,32), Color3.fromRGB(50,100,190), buyPage)
local clr = smallBtn("Clear", UDim2.new(0.5,3,0,38), UDim2.new(0.5,-3,0,32), Color3.fromRGB(150,65,75), buyPage)
local function curItems() return buyMode == "egg" and EGGS or SEEDS end
selAll.MouseButton1Click:Connect(function() for _, s in ipairs(curItems()) do selected[s[1]] = true; paint(s[1]) end; saveSettings() end)
clr.MouseButton1Click:Connect(function() for _, s in ipairs(curItems()) do selected[s[1]] = false; paint(s[1]) end; saveSettings() end)

local function mkList()
    local l = new("ScrollingFrame", {Position=UDim2.fromOffset(0,76), Size=UDim2.new(1,0,1,-132),
        BackgroundTransparency=1, ScrollBarThickness=3, ScrollBarImageColor3=ACC, BorderSizePixel=0,
        AutomaticCanvasSize=Enum.AutomaticSize.Y, CanvasSize=UDim2.new()}, buyPage)
    tint(l, "ScrollBarImageColor3", "ACC")
    new("UIListLayout", {Padding=UDim.new(0,5)}, l)
    return l
end
local seedList, eggList = mkList(), mkList()

for _, group in ipairs({{SEEDS, seedList}, {EGGS, eggList}}) do
    for _, s in ipairs(group[1]) do
        local name, color = s[1], s[3]
        local btn = round(new("TextButton", {Size=UDim2.new(1,-6,0,38), BackgroundColor3=PANEL, Text="",
            AutoButtonColor=false, BorderSizePixel=0}, group[2]), 9)
        round(new("Frame", {Size=UDim2.new(0,5,1,-12), Position=UDim2.fromOffset(6,6), BackgroundColor3=color, BorderSizePixel=0}, btn), 3)
        new("TextLabel", {Size=UDim2.new(1,-62,1,0), Position=UDim2.fromOffset(18,0), BackgroundTransparency=1,
            Text=name, TextColor3=WHITE, Font=Enum.Font.GothamMedium, TextSize=13,
            TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd}, btn)
        local check = tint(round(new("TextLabel", {Size=UDim2.fromOffset(24,24), Position=UDim2.new(1,-34,0.5,-12),
            BackgroundColor3=Color3.fromRGB(50,55,75), Text="", TextColor3=BG, Font=Enum.Font.GothamBold, TextSize=15}, btn), 7), "TextColor3", "BG")
        rows[name] = {btn=btn, check=check, color=color}
        btn.MouseButton1Click:Connect(function() selected[name] = not selected[name]; paint(name); saveSettings() end)
    end
end
onTheme(function()
    for _, s in ipairs(ALL) do
        rows[s[1]].btn.BackgroundTransparency = 1 - panelOp
        paint(s[1])
    end
end)

local function setMode(m, userPick)
    buyMode = (m == "egg") and "egg" or "seed"
    local egg = (buyMode == "egg")
    seedList.Visible, eggList.Visible = not egg, egg
    segSeed.BackgroundColor3 = egg and PANEL2 or ACC
    segSeed.TextColor3 = egg and WHITE or BG
    segEgg.BackgroundColor3 = egg and ACC or PANEL2
    segEgg.TextColor3 = egg and BG or WHITE
    if userPick then
        for k in pairs(cooldown) do cooldown[k] = nil end
        saveSettings()
    end
end
onTheme(function() setMode(buyMode) end)
segSeed.MouseButton1Click:Connect(function() setMode("seed", true) end)
segEgg.MouseButton1Click:Connect(function() setMode("egg", true) end)
setMode(buyMode)

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

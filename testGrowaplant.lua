-- <w> : by Mister : yoruka.id
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local VU = game:GetService("VirtualUser")
local TS = game:GetService("TweenService")
local HS = game:GetService("HttpService")
local getAsset = getcustomasset or getsynasset or get_custom_asset -- local file -> rbxasset:// path
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
local tpOn, uiMul = true, 1
local remoteOn = true -- buy from anywhere: fire shop Remote first, TP only as fallback
local iconMul, applyIcon = 1, nil -- minimized icon size multiplier + its apply function
local confirmOn, verbose, antiAfk = true, false, true
local hopOn, fpsOn = false, false
local buyMode = "seed" -- "seed" or "egg": the shop being processed
local shopCFs, autoShops = {}, {}
local cooldown = {}
local MIN_W, MIN_H = 440, 260 -- smallest window the layout still fits in
local W, H = 480, 340 -- window size (resize with the edges / corners, it is saved)
-- Shop tab options per category: sel = my selected items, all = every item, best = rarest item in stock
local auto = {seed = {sel = false, all = false, best = false}, egg = {sel = false, all = false, best = false}}
local function catOn(m)
    local a = auto[m]
    return a.sel or a.all or a.best
end
local syncRun -- starts / stops the auto-buy from the toggles (assigned further down)
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
        if type(d.remote) == "boolean" then remoteOn = d.remote end
        if type(d.confirm) == "boolean" then confirmOn = d.confirm end
        if type(d.afk) == "boolean" then antiAfk = d.afk end
        if type(d.hop) == "boolean" then hopOn = d.hop end
        if d.mode == "egg" then buyMode = "egg" end
        if type(d.fps) == "boolean" then fpsOn = d.fps end
        if type(d.win) == "table" then
            W = math.clamp(tonumber(d.win[1]) or W, MIN_W, 3000)
            H = math.clamp(tonumber(d.win[2]) or H, MIN_H, 3000)
        end
        if type(d.auto) == "table" then
            for _, c in ipairs({"seed", "egg"}) do
                if type(d.auto[c]) == "table" then
                    for _, k in ipairs({"sel", "all", "best"}) do
                        if type(d.auto[c][k]) == "boolean" then auto[c][k] = d.auto[c][k] end
                    end
                end
            end
        end
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
            ui = uiMul, icon = iconMul, tp = tpOn, remote = remoteOn, confirm = confirmOn, afk = antiAfk, hop = hopOn, fps = fpsOn, mode = buyMode, auto = auto, win = {W, H}}))
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

-- ===== buy from anywhere: Remote fire + prompt fire + spoof TP =====
-- Tries in order, no movement required:
--  1) fireproximityprompt on the shop prompt (bypasses client distance)
--  2) FireServer/InvokeServer on discovered shop remotes with item payloads
--  3) fallback: spoof TP (legacy TP) handled in visit()
local buyRemotes = nil
local function scoreRemote(o)
    local n = tostring(o.Name):lower()
    local full = tostring(o:GetFullName()):lower()
    local s = 0
    for _, k in ipairs({"buy", "purchase", "shop", "store", "seed", "egg", "pack", "hatch", "open", "summon", "roll", "draw"}) do
        if n:find(k, 1, true) then s += 3 end
        if full:find(k, 1, true) then s += 1 end
    end
    for _, k in ipairs({"sell", "vendre", "gear", "coin", "data", "save", "leader"}) do
        if n:find(k, 1, true) then s -= 4 end
    end
    return s
end
local function discoverRemotes()
    if buyRemotes then return buyRemotes end
    buyRemotes = {}
    local roots = {game:GetService("ReplicatedStorage")}
    pcall(function() table.insert(roots, game:GetService("ReplicatedFirst")) end)
    for _, root in ipairs(roots) do
        if root then
            for _, d in ipairs(root:GetDescendants()) do
                if d:IsA("RemoteEvent") or d:IsA("RemoteFunction") or d:IsA("UnreliableRemoteEvent") then
                    local s = scoreRemote(d)
                    if s > 0 then table.insert(buyRemotes, {o = d, score = s}) end
                end
            end
        end
    end
    table.sort(buyRemotes, function(a, b) return a.score > b.score end)
    -- keep top 12 so we never spam unrelated remotes
    while #buyRemotes > 12 do table.remove(buyRemotes) end
    if verbose then
        for _, r in ipairs(buyRemotes) do log("Remote: " .. r.o:GetFullName() .. " (" .. r.score .. ")") end
    end
    return buyRemotes
end
-- payload variants for "Dragon Seed Pack" / "Royal Egg"
local function payloadsFor(name)
    local short = name:gsub(" Seed Pack$", ""):gsub(" Pack$", "")
    local list = {name, short}
    if buyMode == "egg" then
        table.insert(list, short .. " Egg")
    else
        table.insert(list, short .. " Seed")
    end
    return list
end
local function fireOne(remote, ...)
    if remote:IsA("RemoteEvent") or remote:IsA("UnreliableRemoteEvent") then
        local ok = pcall(function() remote:FireServer(...) end)
        return ok
    elseif remote:IsA("RemoteFunction") then
        local ok = pcall(function() remote:InvokeServer(...) end)
        return ok
    end
    return false
end
-- fire the shop ProximityPrompt from anywhere (no walk/TP on client side)
local function fireShopPrompt()
    local egg = (buyMode == "egg")
    local fired = 0
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") and d.Enabled then
            local txt = clean(d.ActionText .. " " .. d.ObjectText)
            local path = clean(d:GetFullName())
            local want, ban = false, false
            for _, k in ipairs(egg and {"egg", "oeuf"} or {"seed", "graine", "pack"}) do
                if path:find(k, 1, true) or txt:find(k, 1, true) then want = true end
            end
            for _, k in ipairs({"sell", "vendre", "gear"}) do
                if path:find(k, 1, true) or txt:find(k, 1, true) then ban = true end
            end
            if want and not ban and (txt:find("ouvrir") or txt:find("acheter") or txt:find("open") or txt:find("buy") or txt == "") then
                -- temporarily lift client-side checks, fire, restore
                local oldHold, oldDist, oldLOS
                pcall(function()
                    oldHold, oldDist, oldLOS = d.HoldDuration, d.MaxInteractionDistance, d.RequiresLineOfSight
                    d.HoldDuration = 0
                    d.MaxInteractionDistance = 1e6
                    d.RequiresLineOfSight = false
                end)
                local ok = false
                if fireproximityprompt then
                    ok = pcall(function() fireproximityprompt(d) end)
                else
                    ok = pcall(function()
                        d:InputHoldBegin()
                        d:InputHoldEnd()
                    end)
                end
                pcall(function()
                    if oldHold ~= nil then d.HoldDuration = oldHold end
                    if oldDist ~= nil then d.MaxInteractionDistance = oldDist end
                    if oldLOS ~= nil then d.RequiresLineOfSight = oldLOS end
                end)
                if ok then fired += 1 end
            end
        end
    end
    return fired > 0
end
-- try direct Remote buy from anywhere; returns true if a fire did not error
local function tryRemoteBuy(name)
    -- some games gate buys behind the same prompt: try it first
    pcall(fireShopPrompt)
    local remotes = discoverRemotes()
    if #remotes == 0 then return false end
    local okAny = false
    for _, r in ipairs(remotes) do
        for _, payload in ipairs(payloadsFor(name)) do
            -- common signatures: (item), (item, 1), (item, "1"), ({item}), ("Buy", item)
            local tries = {
                {payload}, {payload, 1}, {payload, "1"}, {payload, 1, 1},
                {{Item = payload}}, {{Name = payload}},
                {"Buy", payload}, {"Buy", payload, 1},
            }
            for _, args in ipairs(tries) do
                if fireOne(r.o, table.unpack(args)) then okAny = true end
            end
            -- only try first payload per remote to avoid spam, then broaden if nothing worked
            if okAny then break end
        end
        if okAny then
            log("Remote buy fired: " .. name .. " via " .. r.o.Name)
            break
        end
    end
    if okAny and confirmOn then
        task.wait(0.1)
        confirmPopups()
    end
    return okAny
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
    -- lists keep the order their items were created in (the default sorts by instance name)
    if class == "UIListLayout" and props.SortOrder == nil then
        o.SortOrder = Enum.SortOrder.LayoutOrder
    end
    o.Parent = parent
    if parent and o:IsA("GuiObject") and props.LayoutOrder == nil and parent:FindFirstChildOfClass("UIListLayout") then
        o.LayoutOrder = #parent:GetChildren()
    end
    return o
end
local function round(o, r) new("UICorner", {CornerRadius = UDim.new(0, r)}, o); return o end

-- ===== THEME: colors + background image (saved to YorukaTheme.json) =====
local DEF_ACC, DEF_BG = Color3.fromRGB(60,210,130), Color3.fromRGB(16,18,26)
local CFG_FILE = "YorukaTheme.json"
local BG, ACC = DEF_BG, DEF_ACC
local panelOp = 1 -- window opacity (1 = solid); the Transparency slider in Settings > Theme changes it

pcall(function()
    if isfile and isfile(CFG_FILE) then
        local d = HS:JSONDecode(readfile(CFG_FILE))
        if type(d.accent) == "table" then ACC = Color3.fromRGB(d.accent[1], d.accent[2], d.accent[3]) end
        if type(d.bg) == "table" then BG = Color3.fromRGB(d.bg[1], d.bg[2], d.bg[3]) end
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

-- ===== polish helpers: soft gradients, accent outlines, hover glow =====
local FX = {}
function FX.grad(o, rot, dark)
    dark = dark or 190
    new("UIGradient", {Rotation = rot or 90, Color = ColorSequence.new(Color3.new(1,1,1),
        Color3.fromRGB(dark, dark, math.min(255, dark + 12)))}, o)
    return o
end
function FX.outline(o, tr, thick)
    return tint(new("UIStroke", {Color = ACC, Thickness = thick or 1, Transparency = tr or 0.85,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, o), "Color", "ACC")
end
function FX.glow(b, rest, hov)
    rest, hov = rest or 0.85, hov or 0.3
    local st = FX.outline(b, rest, 1)
    st:SetAttribute("rest", rest)
    b.MouseEnter:Connect(function() TS:Create(st, TweenInfo.new(0.12), {Transparency = hov}):Play() end)
    b.MouseLeave:Connect(function() TS:Create(st, TweenInfo.new(0.18), {Transparency = st:GetAttribute("rest")}):Play() end)
    return st
end
local function applyTheme()
    PANEL, PANEL2 = shift(BG, 14, 16, 22), shift(BG, 24, 27, 38)
    local role = {BG = BG, PANEL = PANEL, SOLID = PANEL, PANEL2 = PANEL2, ACC = ACC}
    for _, t in ipairs(themed) do
        local o = t[1]
        if o.Parent then
            o[t[2]] = role[t[3]]
            if t[2] == "BackgroundColor3" and not o:GetAttribute("solid") then
                if t[3] == "BG" or t[3] == "SOLID" or t[3] == "PANEL" then
                    o.BackgroundTransparency = 1 - panelOp
                elseif t[3] == "PANEL2" then
                    o.BackgroundTransparency = (1 - panelOp) * 0.6
                end
            end
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
            writefile(CFG_FILE, HS:JSONEncode({accent = c3(ACC), bg = c3(BG), panel = panelOp}))
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

local BASE_W, BASE_H = 480, 340 -- design size: the UI scale follows this, so resizing never rescales the content
local function calcScale()
    local vp = cam.ViewportSize
    local fit = math.min((vp.X - 16) / BASE_W, (vp.Y - 16) / BASE_H)
    return math.clamp(fit, 0.45, 1.15) * uiMul
end
local baseScale = calcScale()
do -- a saved size must still fit this screen
    local vp = cam.ViewportSize
    W = math.clamp(W, MIN_W, math.max(MIN_W, math.floor((vp.X - 8) / baseScale)))
    H = math.clamp(H, MIN_H, math.max(MIN_H, math.floor((vp.Y - 8) / baseScale)))
end

local main = round(new("Frame", {
    Size = UDim2.fromOffset(W, H), BackgroundColor3 = BG, BorderSizePixel = 0,
    Position = UDim2.fromOffset(cam.ViewportSize.X/2 - W*baseScale/2, cam.ViewportSize.Y/2 - H*baseScale/2),
}, gui), 14)
tint(main, "BackgroundColor3", "BG")
tint(new("UIStroke", {Color = ACC, Thickness = 2, Transparency = 0.35}, main), "Color", "ACC")
local scale = new("UIScale", {Scale = baseScale}, main)

FX.grad(main, 90, 172)

-- soft drop shadow behind the window (layered rounded frames that follow it)
do
local shadow = new("Frame", {Name="Shadow", BackgroundTransparency=1, ZIndex=0, Size=main.Size, Position=main.Position}, gui)
local shScale = new("UIScale", {Scale = scale.Scale}, shadow)
for i, g in ipairs({22, 15, 9, 4}) do
    round(new("Frame", {Size=UDim2.new(1, g*2, 1, g*2), Position=UDim2.fromOffset(-g, -g + 7),
        BackgroundColor3=Color3.new(0,0,0), BackgroundTransparency=0.97 - i*0.03, BorderSizePixel=0, ZIndex=0}, shadow), 14 + g)
end
local function syncShadow()
    shadow.Visible = main.Visible and panelOp > 0.85
    shadow.Size = main.Size
    shadow.Position = main.Position
    shScale.Scale = scale.Scale
end
main:GetPropertyChangedSignal("Position"):Connect(syncShadow)
main:GetPropertyChangedSignal("Size"):Connect(syncShadow)
main:GetPropertyChangedSignal("Visible"):Connect(syncShadow)
scale:GetPropertyChangedSignal("Scale"):Connect(syncShadow)
onTheme(syncShadow)
syncShadow()
end

local header = round(new("Frame", {Size = UDim2.new(1,0,0,40), BackgroundColor3 = PANEL, BorderSizePixel = 0}, main), 14)
tint(header, "BackgroundColor3", "SOLID")
tint(new("Frame", {Size = UDim2.new(1,0,0,14), Position = UDim2.new(0,0,1,-14), BackgroundColor3 = PANEL, BorderSizePixel = 0}, header), "BackgroundColor3", "SOLID")
-- ===== premium header: neon logo badge + integrated brand block + glass minimize button =====
function FX.hex(c) return string.format("#%02X%02X%02X", math.floor(c.R*255+0.5), math.floor(c.G*255+0.5), math.floor(c.B*255+0.5)) end
function FX.ring() -- neon sweep colors (accent -> white -> accent)
    return ColorSequence.new({ColorSequenceKeypoint.new(0, ACC), ColorSequenceKeypoint.new(0.5, WHITE), ColorSequenceKeypoint.new(1, ACC)})
end
do -- layered soft glow behind the badge (shadow effect)
    for _, g in ipairs({4, 2}) do
        tint(round(new("Frame", {Size=UDim2.fromOffset(32 + g*2, 32 + g*2), Position=UDim2.fromOffset(10 - g, 4 - g),
            BackgroundColor3=ACC, BackgroundTransparency = g == 4 and 0.93 or 0.85, BorderSizePixel=0, ZIndex=1}, header), 10 + g),
            "BackgroundColor3", "ACC")
    end
end
-- header logo (same image as the minimized icon; "M" shows until it loads)
local hdrIcon = tint(round(new("Frame", {Size=UDim2.fromOffset(32,32), Position=UDim2.fromOffset(10,4),
    BackgroundColor3=BG, BorderSizePixel=0, ZIndex=2}, header), 10), "BackgroundColor3", "BG")
hdrIcon:SetAttribute("solid", true)
new("UIGradient", {Color=ColorSequence.new(Color3.new(1,1,1), Color3.fromRGB(105,110,135)), Rotation=90}, hdrIcon)
do
    local ring = new("UIStroke", {Color=WHITE, Thickness=1.6, Transparency=0.05}, hdrIcon)
    local rg = new("UIGradient", {Color=FX.ring()}, ring)
    onTheme(function() rg.Color = FX.ring() end)
    TS:Create(rg, TweenInfo.new(5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {Rotation = 360}):Play()
end
local hdrFallback = tint(new("TextLabel", {Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Text="M",
    TextColor3=ACC, Font=Enum.Font.Michroma, TextSize=16, ZIndex=3}, hdrIcon), "TextColor3", "ACC")
local hdrImg = round(new("ImageLabel", {Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Image="",
    Visible=false, ScaleType=Enum.ScaleType.Crop, ZIndex=4}, hdrIcon), 10)
do -- brand block: "MISTER HUB" logotype + credit line, aligned on the same left edge
    local title = new("TextLabel", {Size=UDim2.new(1,-110,0,18), Position=UDim2.fromOffset(52,4), BackgroundTransparency=1,
        RichText=true, Font=Enum.Font.GothamBlack, TextSize=15, TextColor3=WHITE, TextXAlignment=Enum.TextXAlignment.Left,
        Text="MISTER"}, header)
    local credit = new("TextLabel", {Size=UDim2.new(1,-110,0,12), Position=UDim2.fromOffset(52,22), BackgroundTransparency=1,
        RichText=true, Font=Enum.Font.GothamMedium, TextSize=10, TextColor3=MUTED, TextXAlignment=Enum.TextXAlignment.Left,
        Text="MISTER"}, header)
    local function brand()
        local h = FX.hex(ACC)
        title.Text = 'MISTER <font color="' .. h .. '">HUB</font>'
        credit.Text = 'by <font color="' .. h .. '"><b>Mister</b></font>  \u{2022}  yoruka.id'
    end
    brand(); onTheme(brand)
end
local minBtn = tint(round(new("TextButton", {Size=UDim2.fromOffset(36,28), Position=UDim2.new(1,-44,0,6),
    BackgroundColor3=PANEL2, Text="\u{2014}", TextColor3=WHITE, AutoButtonColor=false,
    Font=Enum.Font.GothamBold, TextSize=16}, header), 8), "BackgroundColor3", "PANEL2")
FX.grad(minBtn, 90, 170); FX.glow(minBtn, 0.7, 0.1)
minBtn.MouseEnter:Connect(function() TS:Create(minBtn, TweenInfo.new(0.12), {TextColor3 = ACC}):Play() end)
minBtn.MouseLeave:Connect(function() TS:Create(minBtn, TweenInfo.new(0.18), {TextColor3 = WHITE}):Play() end)
-- glowing accent line under the header
do
local hdrLine = tint(new("Frame", {Size=UDim2.new(1,-24,0,1), Position=UDim2.new(0,12,0,40), BackgroundColor3=ACC,
    BorderSizePixel=0}, main), "BackgroundColor3", "ACC")
new("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(0.5,0.1),
    NumberSequenceKeypoint.new(1,1)})}, hdrLine)
end

local sideW = 112
local sidebar = round(new("ScrollingFrame", {Position=UDim2.fromOffset(8,48), Size=UDim2.new(0,sideW,1,-56),
    BackgroundColor3=PANEL, BorderSizePixel=0, ScrollBarThickness=0,
    AutomaticCanvasSize=Enum.AutomaticSize.Y, CanvasSize=UDim2.new()}, main), 10)
tint(sidebar, "BackgroundColor3", "PANEL")
new("UIListLayout", {Padding=UDim.new(0,6)}, sidebar)
new("UIPadding", {PaddingTop=UDim.new(0,6), PaddingLeft=UDim.new(0,6), PaddingRight=UDim.new(0,6), PaddingBottom=UDim.new(0,6)}, sidebar)
FX.grad(sidebar, 90, 195); FX.outline(sidebar, 0.88)
-- footer card at the bottom of the sidebar (fills the empty space)
do
local foot = tint(round(new("Frame", {Size=UDim2.fromOffset(sideW - 12, 30), Position=UDim2.new(0,14,1,-44),
    BackgroundColor3=PANEL2, BorderSizePixel=0, ZIndex=3}, main), 8), "BackgroundColor3", "PANEL2")
FX.outline(foot, 0.8)
tint(round(new("Frame", {Size=UDim2.fromOffset(6,6), Position=UDim2.new(0,10,0.5,-3), BackgroundColor3=ACC,
    BorderSizePixel=0, ZIndex=4}, foot), 3), "BackgroundColor3", "ACC")
new("TextLabel", {Size=UDim2.new(1,-24,1,0), Position=UDim2.fromOffset(22,0), BackgroundTransparency=1, Text="yoruka.id",
    TextColor3=MUTED, Font=Enum.Font.GothamBold, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left, ZIndex=4}, foot)
end

local body = new("Frame", {Position=UDim2.fromOffset(sideW+16,48), Size=UDim2.new(1,-(sideW+24),1,-56),
    BackgroundTransparency=1, ClipsDescendants=true}, main)

local tabs, curTab = {}, nil
local function selectTab(name)
    curTab = name
    for n, t in pairs(tabs) do
        local on = (n == name)
        t.page.Visible = on
        TS:Create(t.btn, TweenInfo.new(0.15), {BackgroundColor3 = on and ACC or PANEL2, TextColor3 = on and BG or WHITE}):Play()
        t.st.Color = on and WHITE or ACC
        t.st:SetAttribute("rest", on and 0.45 or 0.8)
        TS:Create(t.st, TweenInfo.new(0.15), {Transparency = on and 0.45 or 0.8}):Play()
        t.bar.BackgroundColor3 = on and BG or ACC
        TS:Create(t.bar, TweenInfo.new(0.15), {BackgroundTransparency = on and 0.1 or 1}):Play()
    end
end
local function addTab(icon, name)
    local btn = round(new("TextButton", {Size=UDim2.new(1,0,0,40), BackgroundColor3=PANEL2, Text=icon.."  "..name,
        TextColor3=WHITE, Font=Enum.Font.GothamBold, TextSize=13, BorderSizePixel=0, AutoButtonColor=false,
        TextXAlignment=Enum.TextXAlignment.Left}, sidebar), 10)
    new("UIPadding", {PaddingLeft=UDim.new(0,16)}, btn)
    FX.grad(btn, 90, 170)
    -- neon border (gradient stroke) + left accent bar shown when selected / hovered
    local st = new("UIStroke", {Color=ACC, Thickness=1.2, Transparency=0.8, ApplyStrokeMode=Enum.ApplyStrokeMode.Border}, btn)
    new("UIGradient", {Color=ColorSequence.new(Color3.new(1,1,1), Color3.fromRGB(150,150,170)), Rotation=45}, st)
    st:SetAttribute("rest", 0.8)
    local bar = round(new("Frame", {Size=UDim2.fromOffset(3,18), Position=UDim2.new(0,-12,0.5,-9), BackgroundColor3=ACC,
        BackgroundTransparency=1, BorderSizePixel=0}, btn), 2)
    btn.MouseEnter:Connect(function()
        if curTab ~= name then
            TS:Create(st, TweenInfo.new(0.12), {Transparency = 0.2}):Play()
            TS:Create(btn, TweenInfo.new(0.12), {TextColor3 = ACC}):Play()
            TS:Create(bar, TweenInfo.new(0.12), {BackgroundTransparency = 0.35}):Play()
        end
    end)
    btn.MouseLeave:Connect(function()
        TS:Create(st, TweenInfo.new(0.18), {Transparency = st:GetAttribute("rest")}):Play()
        if curTab ~= name then
            TS:Create(btn, TweenInfo.new(0.18), {TextColor3 = WHITE}):Play()
            TS:Create(bar, TweenInfo.new(0.18), {BackgroundTransparency = 1}):Play()
        end
    end)
    local page = new("Frame", {Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Visible=false}, body)
    tabs[name] = {btn=btn, page=page, st=st, bar=bar}
    btn.MouseButton1Click:Connect(function() selectTab(name) end)
    return page
end
onTheme(function() if curTab then selectTab(curTab) end end)

-- reusable components (use them for your own tabs)
local function scrollPage(page)
    local s = new("ScrollingFrame", {Size=UDim2.fromScale(1,1), BackgroundTransparency=1, BorderSizePixel=0,
        ScrollBarThickness=3, ScrollBarImageColor3=ACC, AutomaticCanvasSize=Enum.AutomaticSize.Y, CanvasSize=UDim2.new()}, page)
    tint(s, "ScrollBarImageColor3", "ACC")
    new("UIListLayout", {Padding=UDim.new(0,8)}, s)
    return s
end
local function section(sp, text)
    local l = new("Frame", {Size=UDim2.new(1,-6,0,22), BackgroundTransparency=1}, sp)
    tint(round(new("Frame", {Size=UDim2.fromOffset(3,12), Position=UDim2.fromOffset(4,5), BackgroundColor3=ACC,
        BorderSizePixel=0}, l), 2), "BackgroundColor3", "ACC")
    tint(new("TextLabel", {Size=UDim2.new(1,-18,1,0), Position=UDim2.fromOffset(14,0), BackgroundTransparency=1,
        Text=text:upper(), TextColor3=ACC, Font=Enum.Font.GothamBlack, TextSize=11,
        TextXAlignment=Enum.TextXAlignment.Left}, l), "TextColor3", "ACC")
end
local function rowFrame(sp, h)
    local r = round(new("Frame", {Size=UDim2.new(1,-6,0,h), BackgroundColor3=PANEL, BorderSizePixel=0}, sp), 10)
    FX.grad(r, 90, 195); FX.outline(r, 0.88)
    return tint(r, "BackgroundColor3", "PANEL")
end
local function rowLabels(r, title, sub, rightPad)
    new("TextLabel", {Size=UDim2.new(1,-rightPad,0,sub and 20 or 46), Position=UDim2.fromOffset(12, sub and 6 or 0),
        BackgroundTransparency=1, Text=title, TextColor3=WHITE, Font=Enum.Font.GothamBold, TextSize=13,
        TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd}, r)
    if sub then
        new("TextLabel", {Size=UDim2.new(1,-rightPad,0,16), Position=UDim2.fromOffset(12,25), BackgroundTransparency=1,
            Text=sub, TextColor3=MUTED, Font=Enum.Font.Gotham, TextSize=10, TextXAlignment=Enum.TextXAlignment.Left,
            TextTruncate=Enum.TextTruncate.AtEnd}, r)
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
    local swGlow = tint(new("UIStroke", {Color=ACC, Thickness=1.5, Transparency = state and 0.4 or 1}, sw), "Color", "ACC")
    onTheme(function() sw.BackgroundColor3 = state and ACC or OFFC; swGlow.Transparency = state and 0.4 or 1 end)
    local hit = new("TextButton", {Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Text=""}, r)
    hit.MouseButton1Click:Connect(function()
        state = not state
        TS:Create(sw, TweenInfo.new(0.15), {BackgroundColor3 = state and ACC or OFFC}):Play()
        TS:Create(swGlow, TweenInfo.new(0.15), {Transparency = state and 0.4 or 1}):Play()
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
        local b = tint(round(new("TextButton", {Size=UDim2.fromOffset(32,30), Position=x, BackgroundColor3=PANEL2, Text=txt,
            TextColor3=WHITE, Font=Enum.Font.GothamBold, TextSize=16, BorderSizePixel=0}, r), 8), "BackgroundColor3", "PANEL2")
        FX.grad(b, 90, 185); FX.glow(b, 0.85, 0.3)
        return b
    end
    local m, p = mk("\u{2212}", UDim2.new(1,-138,0.5,-15)), mk("+", UDim2.new(1,-40,0.5,-15))
    m.MouseButton1Click:Connect(function() setv(math.clamp(getv() - step, lo, hi)); val.Text = show() end)
    p.MouseButton1Click:Connect(function() setv(math.clamp(getv() + step, lo, hi)); val.Text = show() end)
    return function() val.Text = show() end
end
local function buttonRow(sp, text, color, cb)
    local b = round(new("TextButton", {Size=UDim2.new(1,-6,0,40), BackgroundColor3=color, Text=text, TextColor3=WHITE,
        Font=Enum.Font.GothamBold, TextSize=13, BorderSizePixel=0}, sp), 10)
    FX.grad(b, 90, 170); FX.glow(b, 0.8, 0.2)
    b.MouseButton1Click:Connect(function() cb(b) end)
    return b
end

-- draggable slider (mouse or touch): returns a function that redraws it from the current value
local function sliderRow(sp, title, sub, getv, setv, lo, hi, fmt)
    local r = rowFrame(sp, 58)
    rowLabels(r, title, sub, 84)
    local val = tint(new("TextLabel", {Size=UDim2.fromOffset(64,20), Position=UDim2.new(1,-76,0,6), BackgroundTransparency=1,
        Text="", TextColor3=ACC, Font=Enum.Font.GothamBold, TextSize=12, TextXAlignment=Enum.TextXAlignment.Right}, r), "TextColor3", "ACC")
    local track = round(new("Frame", {Size=UDim2.new(1,-28,0,6), Position=UDim2.new(0,14,1,-16), BackgroundColor3=OFFC,
        BorderSizePixel=0}, r), 3)
    local fill = tint(round(new("Frame", {Size=UDim2.fromScale(0,1), BackgroundColor3=ACC, BorderSizePixel=0}, track), 3),
        "BackgroundColor3", "ACC")
    local knob = round(new("Frame", {Size=UDim2.fromOffset(16,16), AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromScale(0,0.5),
        BackgroundColor3=WHITE, BorderSizePixel=0, ZIndex=2}, track), 8)
    new("UIStroke", {Color=Color3.new(0,0,0), Thickness=1, Transparency=0.7}, knob)
    local hit = new("TextButton", {Size=UDim2.new(1,-14,0,26), Position=UDim2.new(0,7,1,-26), BackgroundTransparency=1,
        Text="", ZIndex=3}, r)
    local function show()
        local f = math.clamp((getv() - lo) / (hi - lo), 0, 1)
        fill.Size = UDim2.fromScale(f, 1)
        knob.Position = UDim2.fromScale(f, 0.5)
        val.Text = fmt(getv())
    end
    local dragging = false
    local function setFrom(x)
        local w = track.AbsoluteSize.X
        if w <= 0 then return end
        local f = math.clamp((x - track.AbsolutePosition.X) / w, 0, 1)
        setv(math.floor((lo + (hi - lo) * f) * 20 + 0.5) / 20) -- steps of 5%
        show()
    end
    hit.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setFrom(i.Position.X)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            setFrom(i.Position.X)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    show()
    return show
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
    local vp = cam.ViewportSize
    W = math.clamp(W, MIN_W, math.max(MIN_W, math.floor((vp.X - 8) / baseScale)))
    H = math.clamp(H, MIN_H, math.max(MIN_H, math.floor((vp.Y - 8) / baseScale)))
    main.Size = UDim2.fromOffset(W, H)
    if main.Visible then
        scale.Scale = baseScale
        main.Position = clampU(main.Position, W * baseScale, H * baseScale)
    end
end

-- ===================== TAB 1: SHOP (Speed Hub style: Shop Seeds / Shop Eggs accordions) =====================
local buyPage = addTab("\u{1F3EA}", "Shop")
-- leave room at the bottom for the status line
local buyArea = new("Frame", {Size=UDim2.new(1,0,1,-40), BackgroundTransparency=1, ClipsDescendants=true}, buyPage)
local shopScroll = scrollPage(buyArea)

local rows = {}
local function paint(name)
    local r, on = rows[name], selected[name]
    TS:Create(r.btn, TweenInfo.new(0.15), {BackgroundColor3 = on and PANEL:Lerp(r.color, 0.28) or PANEL}):Play()
    r.check.Text = on and "\u{2713}" or ""
    r.check.BackgroundColor3 = on and r.color or Color3.fromRGB(50,55,75)
end

local function smallBtn(text, pos, size, color, parentObj)
    local b = round(new("TextButton", {Position=pos, Size=size, BackgroundColor3=color, Text=text, TextColor3=WHITE,
        Font=Enum.Font.GothamBold, TextSize=13, BorderSizePixel=0}, parentObj), 10)
    FX.grad(b, 90, 170); FX.glow(b, 0.8, 0.2)
    return b
end

-- one selectable item (thumbnail + name + check) inside a dropdown list
local function itemRow(sp, s, onChange)
    local name, color = s[1], s[3]
    local btn = round(new("TextButton", {Size=UDim2.new(1,-6,0,38), BackgroundColor3=PANEL, Text="",
        AutoButtonColor=false, BorderSizePixel=0}, sp), 10)
    FX.grad(btn, 90, 200); FX.glow(btn, 1, 0.5)
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
    btn.MouseButton1Click:Connect(function()
        selected[name] = not selected[name]
        paint(name)
        saveSettings()
        onChange()
    end)
end

-- "Select Seed  [ Select Options v ]" row; tapping the button opens a multi-select list under it
local function dropdownRow(parent, title, items)
    local r = rowFrame(parent, 54)
    new("TextLabel", {Size=UDim2.new(1,-190,1,0), Position=UDim2.fromOffset(12,0), BackgroundTransparency=1, Text=title,
        TextColor3=WHITE, Font=Enum.Font.GothamBold, TextSize=14, TextXAlignment=Enum.TextXAlignment.Left,
        TextTruncate=Enum.TextTruncate.AtEnd}, r)
    local btn = tint(round(new("TextButton", {Size=UDim2.fromOffset(160,34), Position=UDim2.new(1,-172,0.5,-17),
        BackgroundColor3=PANEL2, Text="", AutoButtonColor=false, BorderSizePixel=0}, r), 8), "BackgroundColor3", "PANEL2")
    FX.grad(btn, 90, 185); FX.glow(btn, 0.8, 0.3)
    local txt = new("TextLabel", {Size=UDim2.new(1,-34,1,0), Position=UDim2.fromOffset(10,0), BackgroundTransparency=1,
        Text="Select Options", TextColor3=MUTED, Font=Enum.Font.GothamMedium, TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd}, btn)
    local arrow = new("TextLabel", {Size=UDim2.fromOffset(24,34), Position=UDim2.new(1,-28,0,0), BackgroundTransparency=1,
        Text="\u{203A}", TextColor3=WHITE, Font=Enum.Font.GothamBold, TextSize=22, Rotation=90}, btn)

    local panel = tint(round(new("Frame", {Size=UDim2.new(1,-6,0,math.min(#items * 43 + 44, 240)),
        BackgroundColor3=PANEL2, BorderSizePixel=0, Visible=false}, parent), 10), "BackgroundColor3", "PANEL2")
    FX.outline(panel, 0.78)
    local list = new("ScrollingFrame", {Size=UDim2.new(1,-8,1,-8), Position=UDim2.fromOffset(4,4), BackgroundTransparency=1,
        BorderSizePixel=0, ScrollBarThickness=3, ScrollBarImageColor3=ACC, AutomaticCanvasSize=Enum.AutomaticSize.Y,
        CanvasSize=UDim2.new()}, panel)
    tint(list, "ScrollBarImageColor3", "ACC")
    new("UIListLayout", {Padding=UDim.new(0,5)}, list)

    local function refresh()
        local n = 0
        for _, s in ipairs(items) do if selected[s[1]] then n += 1 end end
        txt.Text = n == 0 and "Select Options" or (n .. " selected")
        txt.TextColor3 = n == 0 and MUTED or WHITE
    end
    local top = new("Frame", {Size=UDim2.new(1,-6,0,32), BackgroundTransparency=1}, list)
    local selAll = smallBtn("Select All", UDim2.fromOffset(0,0), UDim2.new(0.5,-3,1,0), Color3.fromRGB(50,100,190), top)
    local clr = smallBtn("Clear", UDim2.new(0.5,3,0,0), UDim2.new(0.5,-3,1,0), Color3.fromRGB(150,65,75), top)
    selAll.MouseButton1Click:Connect(function()
        for _, s in ipairs(items) do selected[s[1]] = true; paint(s[1]) end
        saveSettings(); refresh()
    end)
    clr.MouseButton1Click:Connect(function()
        for _, s in ipairs(items) do selected[s[1]] = false; paint(s[1]) end
        saveSettings(); refresh()
    end)
    for _, s in ipairs(items) do itemRow(list, s, refresh) end
    refresh()

    local lastTap = 0
    btn.MouseButton1Click:Connect(function()
        if os.clock() - lastTap < 0.2 then return end
        lastTap = os.clock()
        panel.Visible = not panel.Visible
        TS:Create(arrow, TweenInfo.new(0.15), {Rotation = panel.Visible and -90 or 90}):Play()
    end)
end

-- collapsible category: header with a chevron, content opens underneath
local function accordion(sp, title, build, sub)
    local holder = new("Frame", {Size=UDim2.new(1,-6,0,0), AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1}, sp)
    new("UIListLayout", {Padding=UDim.new(0,7)}, holder)
    local hh = sub and 54 or 46
    local head = tint(round(new("TextButton", {Size=UDim2.new(1,0,0,hh), BackgroundColor3=PANEL, Text="",
        AutoButtonColor=false, BorderSizePixel=0, LayoutOrder=1}, holder), 10), "BackgroundColor3", "PANEL")
    FX.grad(head, 90, 195)
    local hs = FX.glow(head, 0.86, 0.35)
    new("TextLabel", {Size=UDim2.new(1,-50,0,20), Position=UDim2.fromOffset(14, sub and 8 or (hh - 20) / 2), BackgroundTransparency=1,
        Text=title, TextColor3=WHITE, Font=Enum.Font.GothamBold, TextSize=14, TextXAlignment=Enum.TextXAlignment.Left}, head)
    if sub then
        new("TextLabel", {Size=UDim2.new(1,-50,0,14), Position=UDim2.fromOffset(14,29), BackgroundTransparency=1, Text=sub,
            TextColor3=MUTED, Font=Enum.Font.Gotham, TextSize=11, TextXAlignment=Enum.TextXAlignment.Left}, head)
    end
    local chev = new("TextLabel", {Size=UDim2.fromOffset(30,hh), Position=UDim2.new(1,-38,0,0), BackgroundTransparency=1,
        Text="\u{203A}", TextColor3=WHITE, Font=Enum.Font.GothamBold, TextSize=26}, head)
    local line = tint(new("Frame", {Size=UDim2.new(1,-20,0,2), Position=UDim2.new(0,10,1,-2), BackgroundColor3=ACC,
        BorderSizePixel=0, Visible=false}, head), "BackgroundColor3", "ACC")
    new("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(0.5,0),
        NumberSequenceKeypoint.new(1,1)})}, line)
    local content = new("Frame", {Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y, BackgroundTransparency=1,
        Visible=false, LayoutOrder=2}, holder)
    new("UIListLayout", {Padding=UDim.new(0,7)}, content)
    build(content)
    local open, lastTap = false, 0
    head.MouseButton1Click:Connect(function()
        if os.clock() - lastTap < 0.2 then return end -- debounce: one click = one toggle
        lastTap = os.clock()
        open = not open
        content.Visible = open
        line.Visible = open
        hs:SetAttribute("rest", open and 0.3 or 0.86)
        TS:Create(hs, TweenInfo.new(0.15), {Transparency = open and 0.3 or 0.86}):Play()
        TS:Create(chev, TweenInfo.new(0.15), {Rotation = open and 90 or 0}):Play()
    end)
end

local function setAuto(cat, key, v)
    auto[cat][key] = v
    saveSettings()
    if syncRun then syncRun() end -- any toggle ON = auto-buy runs, all OFF = it stops
end
local function buildCategory(content, cat, items, selTitle, word)
    dropdownRow(content, selTitle, items)
    toggleRow(content, "Auto Buy " .. word, nil, auto[cat].sel, function(v) setAuto(cat, "sel", v) end)
    toggleRow(content, "Auto Buy All " .. word, nil, auto[cat].all, function(v) setAuto(cat, "all", v) end)
    toggleRow(content, "Auto Buy Best " .. word, nil, auto[cat].best, function(v) setAuto(cat, "best", v) end)
end
accordion(shopScroll, "Shop Seeds", function(c) buildCategory(c, "seed", SEEDS, "Select Seed", "Seeds") end, "Auto-buy seed packs")
accordion(shopScroll, "Shop Eggs", function(c) buildCategory(c, "egg", EGGS, "Select Eggs", "Eggs") end, "Auto-buy eggs")

onTheme(function()
    for _, s in ipairs(ALL) do
        rows[s[1]].btn.BackgroundTransparency = 1 - panelOp
        paint(s[1])
    end
end)

-- status line (no START button: the Shop toggles start and stop the auto-buy)
local status
do
local statusBar = tint(round(new("Frame", {Position=UDim2.new(0,4,1,-38), Size=UDim2.new(1,-8,0,36),
    BackgroundColor3=PANEL, BorderSizePixel=0}, buyPage), 10), "BackgroundColor3", "PANEL")
FX.grad(statusBar, 90, 195); FX.outline(statusBar, 0.8)
local sDot = round(new("Frame", {Size=UDim2.fromOffset(8,8), Position=UDim2.new(0,12,0.5,-4), BackgroundColor3=OFFC,
    BorderSizePixel=0}, statusBar), 4)
status = new("TextLabel", {Position=UDim2.fromOffset(28,0), Size=UDim2.new(1,-36,1,0), BackgroundTransparency=1,
    Text="Clicks: 0\nTurn on an Auto Buy toggle", TextColor3=MUTED, Font=Enum.Font.GothamMedium, TextSize=12, TextWrapped=true,
    RichText=true, TextXAlignment=Enum.TextXAlignment.Left}, statusBar)
-- first line (clicks) in the accent color, second line muted; the raw text is kept in an attribute
local function esc(t) return (tostring(t):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")) end
local function renderStatus(raw)
    raw = raw or "Clicks: 0"
    local c = c3(ACC)
    local a, b = raw:match("^(.-)\n(.*)$")
    local rich
    if a then
        rich = string.format('<font color="#%02X%02X%02X"><b>%s</b></font>\n<font color="#A0AAC3">%s</font>', c[1], c[2], c[3], esc(a), esc(b))
    else
        rich = string.format('<font color="#%02X%02X%02X"><b>%s</b></font>', c[1], c[2], c[3], esc(raw))
    end
    sDot.BackgroundColor3 = running and ACC or OFFC
    status:SetAttribute("raw", raw)
    status.Text = rich
end
status:GetPropertyChangedSignal("Text"):Connect(function()
    local t = status.Text
    if t:find("<font", 1, true) then return end -- already styled
    renderStatus(t)
end)
onTheme(function() renderStatus(status:GetAttribute("raw")) end)
renderStatus(status.Text)
task.spawn(function() -- the dot pulses while auto-buy runs
    while gui.Parent do
        if running then
            TS:Create(sDot, TweenInfo.new(0.7, Enum.EasingStyle.Sine), {BackgroundTransparency = 0.65}):Play()
            task.wait(0.7)
            TS:Create(sDot, TweenInfo.new(0.7, Enum.EasingStyle.Sine), {BackgroundTransparency = 0}):Play()
            task.wait(0.7)
        else
            sDot.BackgroundTransparency = 0
            task.wait(0.4)
        end
    end
end)
end

-- ===== HTTP helper (used by the icon loader) =====
local function fetch(u)
    local req = (syn and syn.request) or request or http_request or (http and http.request)
    if req then
        local ok2, res = pcall(req, {Url = u, Method = "GET", Headers = {["User-Agent"] = "Mozilla/5.0"}})
        if ok2 and type(res) == "table" and res.Body and #res.Body > 0 and (not res.StatusCode or res.StatusCode == 200) then
            return res.Body
        end
    end
    local ok, data = pcall(function() return game:HttpGet(u) end)
    if ok and type(data) == "string" and #data > 0 then return data end
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

-- ===== FPS boost (very few textures, no accessories, no shadows, no particles) =====
-- everything is reversible: original values are saved and restored when you switch it off
local Lighting = game:GetService("Lighting")
local function weak() return setmetatable({}, {__mode = "k"}) end
local fps = {saved = weak(), removed = weak(), conns = {}, token = 0, glob = {}}
local EFFECTS = {"ParticleEmitter", "Trail", "Beam", "Fire", "Smoke", "Sparkles", "Highlight",
    "PointLight", "SpotLight", "SurfaceLight"}
local SKY_FACES = {"SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp"}

local function boost(o)
    if fps.saved[o] then return end
    local s, set
    if o:IsA("BasePart") then
        if o:IsA("Terrain") then return end
        s = {Material = o.Material, Reflectance = o.Reflectance, CastShadow = o.CastShadow}
        set = {Material = Enum.Material.SmoothPlastic, Reflectance = 0, CastShadow = false}
        if o:IsA("MeshPart") then
            s.TextureID = o.TextureID; set.TextureID = ""
            s.RenderFidelity = o.RenderFidelity; set.RenderFidelity = Enum.RenderFidelity.Performance
        end
    elseif o:IsA("SurfaceAppearance") then
        s = {ColorMap = o.ColorMap, MetalnessMap = o.MetalnessMap, NormalMap = o.NormalMap, RoughnessMap = o.RoughnessMap}
        set = {ColorMap = "", MetalnessMap = "", NormalMap = "", RoughnessMap = ""}
    elseif o:IsA("Decal") or o:IsA("Texture") then
        s, set = {Transparency = o.Transparency}, {Transparency = 1}
    elseif o:IsA("Shirt") then
        s, set = {ShirtTemplate = o.ShirtTemplate}, {ShirtTemplate = ""}
    elseif o:IsA("Pants") then
        s, set = {PantsTemplate = o.PantsTemplate}, {PantsTemplate = ""}
    elseif o:IsA("ShirtGraphic") then
        s, set = {Graphic = o.Graphic}, {Graphic = ""}
    elseif o:IsA("Sky") then
        s = {StarCount = o.StarCount, CelestialBodiesShown = o.CelestialBodiesShown}
        set = {StarCount = 0, CelestialBodiesShown = false}
        for _, f in ipairs(SKY_FACES) do s[f] = o[f]; set[f] = "" end
    elseif o:IsA("Atmosphere") then
        s, set = {Density = o.Density, Haze = o.Haze, Glare = o.Glare}, {Density = 0, Haze = 0, Glare = 0}
    elseif o:IsA("Clouds") then
        s, set = {Enabled = o.Enabled}, {Enabled = false}
    elseif o:IsA("PostEffect") then
        s, set = {Enabled = o.Enabled}, {Enabled = false}
    else
        for _, c in ipairs(EFFECTS) do
            if o:IsA(c) then s, set = {Enabled = o.Enabled}, {Enabled = false} break end
        end
    end
    if not s then return end
    fps.saved[o] = s
    for k, v in pairs(set) do pcall(function() o[k] = v end) end
end

-- accessories (hats, hair, backpacks...) are taken off every character, yours and the others'
local function stripAccessory(a)
    if not a:IsA("Accessory") or fps.removed[a] then return end
    fps.removed[a] = a.Parent
    pcall(function() a.Parent = nil end)
end
local function hookChar(ch)
    for _, c in ipairs(ch:GetChildren()) do stripAccessory(c) end
    table.insert(fps.conns, ch.ChildAdded:Connect(stripAccessory))
end
local function hookPlayer(p)
    if p.Character then hookChar(p.Character) end
    table.insert(fps.conns, p.CharacterAdded:Connect(hookChar))
end

local function fpsEnable()
    fpsOn = true
    fps.token += 1
    local tok = fps.token
    fps.glob = {shadows = Lighting.GlobalShadows}
    pcall(function() fps.glob.diffuse = Lighting.EnvironmentDiffuseScale end)
    pcall(function() fps.glob.specular = Lighting.EnvironmentSpecularScale end)
    pcall(function() fps.glob.quality = settings().Rendering.QualityLevel end)
    pcall(function() Lighting.GlobalShadows = false end)
    pcall(function() Lighting.EnvironmentDiffuseScale = 0 end)
    pcall(function() Lighting.EnvironmentSpecularScale = 0 end)
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
    -- accessories first (cheap), then textures
    for _, p in ipairs(Players:GetPlayers()) do hookPlayer(p) end
    table.insert(fps.conns, Players.PlayerAdded:Connect(hookPlayer))
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
    local saved, removed, glob = fps.saved, fps.removed, fps.glob
    fps.saved, fps.removed, fps.glob = weak(), weak(), {}
    if glob.shadows ~= nil then pcall(function() Lighting.GlobalShadows = glob.shadows end) end
    if glob.diffuse then pcall(function() Lighting.EnvironmentDiffuseScale = glob.diffuse end) end
    if glob.specular then pcall(function() Lighting.EnvironmentSpecularScale = glob.specular end) end
    if glob.quality then pcall(function() settings().Rendering.QualityLevel = glob.quality end) end
    local t = workspace:FindFirstChildOfClass("Terrain")
    if t and glob.terrain then
        for k, v in pairs(glob.terrain) do pcall(function() t[k] = v end) end
    end
    -- put the accessories back (only where the character still exists)
    for a, par in pairs(removed) do
        pcall(function() if par and par.Parent then a.Parent = par end end)
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

-- ===================== TAB 2: SETTINGS (accordions) =====================

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
    new("UIListLayout", {FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,6)}, holder)
    for _, c in ipairs(colors) do
        local b = round(new("TextButton", {Size=UDim2.fromOffset(28,28), BackgroundColor3=c, Text="",
            AutoButtonColor=false, BorderSizePixel=0}, holder), 15)
        new("UIStroke", {Color=WHITE, Thickness=1, Transparency=0.6}, b)
        b.MouseButton1Click:Connect(function() onPick(c) end)
    end
end

-- every settings group is a collapsible accordion (same system as Shop Seeds / Shop Eggs):
-- the header stays on top, tapping it opens the options underneath, tapping it again closes it
local setScroll = scrollPage(addTab("\u{2699}", "Settings"))
local function addSet(name, build) accordion(setScroll, name, build) end
local panelUpdate

addSet("Auto Buy", function(sp)
    stepperRow(sp, "Check delay", "Time between stock checks", function() return delay end,
        function(v) delay = v; saveSettings() end, 0.5, 0.5, 30, "%.1f s")
    stepperRow(sp, "Max buys / pack", "\u{221E} = unlimited (buys until out of stock)", function() return maxPer end,
        function(v) maxPer = v; saveSettings() end, 1, 0, 100, function(v) return v == 0 and "\u{221E}" or (v .. " x") end)
    toggleRow(sp, "Auto-confirm popups", "Clicks Confirm / Yes / OK if a popup appears", confirmOn, function(v) confirmOn = v; saveSettings() end)
end)

addSet("Teleport", function(sp)
    toggleRow(sp, "TP to shop", "One trip: buy everything, then return", tpOn, function(v) tpOn = v; saveSettings() end)
    toggleRow(sp, "Buy from anywhere", "Fire Remote / prompt first, TP only if needed", remoteOn, function(v) remoteOn = v; buyRemotes = nil; saveSettings() end)
    for _, m in ipairs({{"seed", "Seed"}, {"egg", "Egg"}}) do
        local label = "\u{1F4CD} Save " .. m[2] .. " shop position"
        buttonRow(sp, label, Color3.fromRGB(110,90,180), function(b)
            local h = getHRP()
            if h then
                shopCFs[m[1]] = h.CFrame
                b.Text = "\u{2713} Saved"
                task.delay(1.5, function() b.Text = label end)
            end
        end)
    end
    buttonRow(sp, "Reset shop positions (auto-detect)", Color3.fromRGB(70,75,100), function(b)
        shopCFs, autoShops = {}, {}
        b.Text = "\u{2713} Reset"
        task.delay(1.5, function() b.Text = "Reset shop positions (auto-detect)" end)
    end)
    buttonRow(sp, "\u{1F50D} Rescan shop remotes", Color3.fromRGB(50,100,190), function(b)
        buyRemotes = nil
        local r = discoverRemotes()
        b.Text = "\u{2713} Found " .. #r
        task.delay(1.5, function() b.Text = "\u{1F50D} Rescan shop remotes" end)
    end)
end)

addSet("Utility", function(sp)
    toggleRow(sp, "Anti AFK", "Stops the game from kicking you for idling", antiAfk, function(v) antiAfk = v; saveSettings() end)
    toggleRow(sp, "Hop on admin/owner", "Switches server when an admin or the owner joins", hopOn,
        function(v) hopOn = v; saveSettings(); if v then scanStaff() end end)
    toggleRow(sp, "FPS boost", "Very few textures, no accessories, no shadows, no particles", fpsOn,
        function(v) if v then fpsEnable() else fpsDisable() end; saveSettings() end)
    buttonRow(sp, "\u{1F500} Hop server now", Color3.fromRGB(50,100,190), function() serverHop("manual") end)
end)

addSet("Theme", function(sp)
    swatchRow(sp, "Accent color", ACC_PRESETS, function(c) ACC = c; commit() end)
    swatchRow(sp, "Background color", BG_PRESETS, function(c) BG = c; commit() end)

    do -- custom hex row
        local r = rowFrame(sp, 46)
        new("TextLabel", {Size=UDim2.fromOffset(36,46), Position=UDim2.fromOffset(12,0), BackgroundTransparency=1,
            Text="Hex", TextColor3=WHITE, Font=Enum.Font.GothamMedium, TextSize=13,
            TextXAlignment=Enum.TextXAlignment.Left}, r)
        local box = tint(round(new("TextBox", {Size=UDim2.fromOffset(88,30), Position=UDim2.fromOffset(52,8),
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
        mk("Accent", 146, 64, "acc")
        mk("BG", 216, 52, "bg")
    end

    panelUpdate = sliderRow(sp, "Transparency", "Drag to make the whole window see-through",
        function() return 1 - panelOp end,
        function(v) panelOp = math.clamp(1 - v, 0.2, 1); commit() end,
        0, 0.8, pct)

    buttonRow(sp, "Reset theme", Color3.fromRGB(70,75,100), function()
        ACC, BG, panelOp = DEF_ACC, DEF_BG, 1
        commit()
        if panelUpdate then panelUpdate() end
    end)
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
    buttonRow(sp, "Reset window size", Color3.fromRGB(70,75,100), function(b)
        W, H = 480, 340
        refit() -- clamps to the screen and applies the size
        saveSettings()
        b.Text = "\u{2713} Reset"
        task.delay(1.5, function() b.Text = "Reset window size" end)
    end)
    buttonRow(sp, "Destroy GUI", Color3.fromRGB(170,55,65), function()
        running = false
        gui:Destroy()
    end)
end)

-- ===== ADD YOUR NEW TABS BELOW =====
-- local page = scrollPage(addTab("\u{1F9FA}", "Harvest"))
-- section(page, "Harvest")
-- toggleRow(page, "Auto harvest", "Collect ripe plants", false, function(v) end)

selectTab("Shop")

-- ===== minimize icon (Mister Hub style) =====
local ICON = 64
local icon = new("TextButton", {Size=UDim2.fromOffset(ICON,ICON), BackgroundTransparency=1, Text="",
    Visible=false, AutoButtonColor=false, BorderSizePixel=0, Position=UDim2.fromOffset(20,120)}, gui)
-- NEW: icon size (UIScale also scales the text, image and border)
local iconScale = new("UIScale", {Scale = iconMul}, icon)
applyIcon = function()
    iconScale.Scale = iconMul
    icon.Position = clampU(icon.Position, ICON * iconMul, ICON * iconMul)
end
-- soft layered drop shadow (sits behind the body)
for i, g in ipairs({12, 8, 4}) do
    round(new("Frame", {Size=UDim2.new(1, g*2, 1, g*2), Position=UDim2.fromOffset(-g, -g + 5), BackgroundColor3=Color3.new(0,0,0),
        BackgroundTransparency=0.97 - i*0.04, BorderSizePixel=0, ZIndex=1}, icon), 18 + g)
end
local iconStroke, iconCrown, iconTop, iconBot, iconImg, dot
do
    local ibody = round(new("Frame", {Size=UDim2.fromScale(1,1), BackgroundColor3=BG, BorderSizePixel=0, ZIndex=2}, icon), 18)
    tint(ibody, "BackgroundColor3", "BG")
    ibody:SetAttribute("solid", true)
    new("UIGradient", {Color=ColorSequence.new(Color3.new(1,1,1), Color3.fromRGB(95,100,125)), Rotation=90}, ibody)
    -- neon ring: accent/white sweep that slowly rotates; the stroke transparency still pulses while minimized
    iconStroke = new("UIStroke", {Color=WHITE, Thickness=2.5, Transparency=0.15}, ibody)
    local rg = new("UIGradient", {Color=FX.ring()}, iconStroke)
    onTheme(function() rg.Color = FX.ring() end)
    TS:Create(rg, TweenInfo.new(5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), {Rotation = 360}):Play()

    -- "M" badge (rounded square, accent fill)
    iconCrown = tint(round(new("Frame", {Size=UDim2.fromOffset(26,26), Position=UDim2.fromOffset(19,7),
        BackgroundColor3=ACC, BorderSizePixel=0, ZIndex=3}, ibody), 8), "BackgroundColor3", "ACC")
    new("UIGradient", {Color=ColorSequence.new(Color3.new(1,1,1), Color3.fromRGB(165,170,175)), Rotation=90}, iconCrown)
    new("UIStroke", {Color=WHITE, Thickness=1, Transparency=0.65}, iconCrown)
    tint(new("TextLabel", {Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Text="M", TextColor3=BG,
        Font=Enum.Font.Michroma, TextSize=14, ZIndex=4}, iconCrown), "TextColor3", "BG")

    iconTop = new("TextLabel", {Size=UDim2.new(1,0,0,11), Position=UDim2.fromOffset(0,35), BackgroundTransparency=1,
        Text="MISTER", TextSize=9, Font=Enum.Font.GothamBold, TextColor3=WHITE, ZIndex=4}, ibody)
    iconBot = tint(new("TextLabel", {Size=UDim2.new(1,0,0,14), Position=UDim2.fromOffset(0,45), BackgroundTransparency=1,
        Text="HUB", TextSize=13, Font=Enum.Font.GothamBlack, TextColor3=ACC, ZIndex=4}, ibody), "TextColor3", "ACC")
    iconImg = round(new("ImageLabel", {Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Image="", Visible=false,
        ScaleType=Enum.ScaleType.Crop, ZIndex=6}, ibody), 18)
    dot = round(new("Frame", {Size=UDim2.fromOffset(11,11), Position=UDim2.new(1,-15,0,4), ZIndex=8,
        BackgroundColor3=Color3.fromRGB(150,65,75), BorderSizePixel=0}, ibody), 6)
    iconCrown.Visible, iconTop.Visible, iconBot.Visible = false, false, false -- replaced by the centered text below
    local iconText = new("TextLabel", {Size=UDim2.fromScale(1,1), BackgroundTransparency=1, RichText=true,
        Font=Enum.Font.GothamBlack, TextSize=16, TextColor3=WHITE, TextXAlignment=Enum.TextXAlignment.Center,
        TextYAlignment=Enum.TextYAlignment.Center, TextStrokeColor3=Color3.new(0,0,0), TextStrokeTransparency=0.55,
        ZIndex=10, Text="Mister"}, ibody)
    local function brandIcon() iconText.Text = 'Mister\n<font color="' .. FX.hex(ACC) .. '">Hub</font>' end
    brandIcon(); onTheme(brandIcon)
    tint(new("UIStroke", {Color=BG, Thickness=2}, dot), "Color", "BG")
end

-- fixed Mister Hub icon (embedded image, decoded and loaded at start)
-- Phones / tablets show the logo image (as before). PC executors do not render image assets reliably,
-- so on PC the text icon stays: the crown emoji + "MISTER HUB" on the minimized icon and an "M" in the header.
-- Set this to true or false by hand to force one or the other.
local USE_ICON_IMAGE = UIS.TouchEnabled and not UIS.KeyboardEnabled
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
    iconImg.Visible = false -- the minimized icon always shows the "Mister Hub" text
end
task.spawn(function()
    if not USE_ICON_IMAGE then return end -- PC: keep the text icon (crown emoji + MISTER HUB / "M")
    if not (writefile and getAsset) then return end -- keeps the drawn icon as fallback
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
        return getAsset(name)
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
    if not main.Visible then return end
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
    if main.Visible then return end -- already open: do nothing (no collapse/re-open flash)
    main.Position = clampU(savedPos or main.Position, W * baseScale, H * baseScale)
    icon.Visible = false; main.Visible = true
    scale.Scale = 0.01
    TS:Create(scale, TweenInfo.new(0.18, Enum.EasingStyle.Back), {Scale = baseScale}):Play()
end
minBtn.MouseButton1Click:Connect(minimize)

local function drag(handle, target, onTap)
    local dragging, moved, start, startPos, active = false, false, nil, nil, nil
    handle.InputBegan:Connect(function(i)
        if dragging then return end
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging, moved, start, startPos, active = true, false, i.Position, target.Position, i
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - start
            if d.Magnitude > 6 then moved = true end
            if moved then target.Position = UDim2.fromOffset(startPos.X.Offset + d.X, startPos.Y.Offset + d.Y) end
        end
    end)
    -- ONE listener per handle (the old code added a new listener on every press and never removed it,
    -- so on PC any later click anywhere could still fire onTap). It only counts a press that began on this handle.
    UIS.InputEnded:Connect(function(i)
        if not dragging then return end
        local sameTouch = (i == active)
        local sameMouse = (i.UserInputType == Enum.UserInputType.MouseButton1
            and active.UserInputType == Enum.UserInputType.MouseButton1)
        if sameTouch or sameMouse then
            dragging = false
            if not moved and onTap then onTap() end
        end
    end)
end
drag(header, main)
drag(icon, icon, restore)

-- ===== window resizing: drag any edge or corner (bottom-right has a grip) =====
local EDGE, CORNER = 6, 12
local HANDLES = { -- {name, mx, my, size, position}: mx / my = which sides move (-1 left/top, 1 right/bottom)
    {"R",   1,  0, UDim2.new(0, EDGE, 1, -CORNER * 2), UDim2.new(1, -EDGE, 0, CORNER)},
    {"L",  -1,  0, UDim2.new(0, EDGE, 1, -CORNER * 2), UDim2.new(0, 0, 0, CORNER)},
    {"B",   0,  1, UDim2.new(1, -CORNER * 2, 0, EDGE), UDim2.new(0, CORNER, 1, -EDGE)},
    {"T",   0, -1, UDim2.new(1, -CORNER * 2, 0, EDGE), UDim2.new(0, CORNER, 0, 0)},
    {"BR",  1,  1, UDim2.fromOffset(16, 16), UDim2.new(1, -16, 1, -16)},
    {"BL", -1,  1, UDim2.fromOffset(CORNER, CORNER), UDim2.new(0, 0, 1, -CORNER)},
    {"TR",  1, -1, UDim2.fromOffset(8, 8), UDim2.new(1, -8, 0, 0)},
    {"TL", -1, -1, UDim2.fromOffset(CORNER, CORNER), UDim2.new(0, 0, 0, 0)},
}
local rz -- the resize in progress: {input, mx, my, sx, sy, w0, h0, x0, y0}
for _, hd in ipairs(HANDLES) do
    local mx, my = hd[2], hd[3]
    local handle = new("TextButton", {Name = "Resize" .. hd[1], Size = hd[4], Position = hd[5],
        BackgroundTransparency = 1, Text = "", AutoButtonColor = false, ZIndex = 100}, main)
    handle.InputBegan:Connect(function(i)
        if rz then return end
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            rz = {input = i, mx = mx, my = my, sx = i.Position.X, sy = i.Position.Y, w0 = W, h0 = H,
                x0 = main.Position.X.Offset, y0 = main.Position.Y.Offset}
        end
    end)
    if hd[1] == "BR" then -- grip dots
        for _, d in ipairs({{12, 12}, {7, 12}, {12, 7}, {2, 12}, {7, 7}, {12, 2}}) do
            round(new("Frame", {Size = UDim2.fromOffset(3, 3), Position = UDim2.fromOffset(d[1], d[2]),
                BackgroundColor3 = MUTED, BackgroundTransparency = 0.25, BorderSizePixel = 0, ZIndex = 101}, handle), 2)
        end
    end
end
UIS.InputChanged:Connect(function(i)
    if not rz then return end
    if i.UserInputType ~= Enum.UserInputType.MouseMovement and i.UserInputType ~= Enum.UserInputType.Touch then return end
    local vp = cam.ViewportSize
    local dx, dy = (i.Position.X - rz.sx) / baseScale, (i.Position.Y - rz.sy) / baseScale
    local w, h = rz.w0, rz.h0
    local maxW, maxH = (vp.X - 8) / baseScale, (vp.Y - 8) / baseScale
    if rz.mx > 0 then
        w = rz.w0 + dx
        maxW = math.min(maxW, (vp.X - rz.x0) / baseScale) -- the right edge stays on screen
    elseif rz.mx < 0 then
        w = rz.w0 - dx
        maxW = math.min(maxW, rz.x0 / baseScale + rz.w0) -- the left edge stays on screen
    end
    if rz.my > 0 then
        h = rz.h0 + dy
        maxH = math.min(maxH, (vp.Y - rz.y0) / baseScale)
    elseif rz.my < 0 then
        h = rz.h0 - dy
        maxH = math.min(maxH, rz.y0 / baseScale + rz.h0)
    end
    W = math.floor(math.clamp(w, MIN_W, math.max(MIN_W, maxW)) + 0.5)
    H = math.floor(math.clamp(h, MIN_H, math.max(MIN_H, maxH)) + 0.5)
    local x, y = rz.x0, rz.y0
    if rz.mx < 0 then x = rz.x0 + (rz.w0 - W) * baseScale end -- dragging the left / top edge moves the window
    if rz.my < 0 then y = rz.y0 + (rz.h0 - H) * baseScale end
    main.Size = UDim2.fromOffset(W, H)
    main.Position = UDim2.fromOffset(x, y)
end)
UIS.InputEnded:Connect(function(i)
    if not rz then return end
    local sameTouch = (i == rz.input)
    local sameMouse = (i.UserInputType == Enum.UserInputType.MouseButton1
        and rz.input.UserInputType == Enum.UserInputType.MouseButton1)
    if sameTouch or sameMouse then
        rz = nil
        saveSettings()
    end
end)

local function setRunning(v)
    running = v
    dot.BackgroundColor3 = v and ACC or Color3.fromRGB(150,65,75)
end
syncRun = function()
    local on = catOn("seed") or catOn("egg")
    if on ~= running then
        setRunning(on)
        status.Text = "Clicks: " .. bought .. "\n" .. (on and "Starting..." or "Stopped")
    end
end
cam:GetPropertyChangedSignal("ViewportSize"):Connect(refit)

-- keep the status dot in sync with the theme
onTheme(function()
    dot.BackgroundColor3 = running and ACC or Color3.fromRGB(150,65,75)
end)

-- apply saved theme + saved background
applyTheme()
if fpsOn then fpsEnable() end
if hopOn then scanStaff() end
syncRun()

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
-- stripped thumbnail (Delta light build)
-- stripped thumbnail (Delta light build)
-- stripped thumbnail (Delta light build)
-- stripped thumbnail (Delta light build)
-- stripped thumbnail (Delta light build)
-- stripped thumbnail (Delta light build)
-- stripped thumbnail (Delta light build)
-- stripped thumbnail (Delta light build)
-- stripped thumbnail (Delta light build)
-- stripped thumbnail (Delta light build)
-- stripped thumbnail (Delta light build)
-- stripped thumbnail (Delta light build)
-- stripped thumbnail (Delta light build)
-- stripped thumbnail (Delta light build)
-- stripped thumbnail (Delta light build)
-- stripped thumbnail (Delta light build)
-- stripped thumbnail (Delta light build)
-- stripped thumbnail (Delta light build)
-- stripped thumbnail (Delta light build)
-- stripped thumbnail (Delta light build)
-- stripped thumbnail (Delta light build)
-- stripped thumbnail (Delta light build)
-- stripped thumbnail (Delta light build)
-- stripped thumbnail (Delta light build)
-- stripped thumbnail (Delta light build)
-- stripped thumbnail (Delta light build)
-- stripped thumbnail (Delta light build)
task.spawn(function()
    if not (writefile and getAsset) then return end -- no file support: lists keep the colored bar only
    for name, b64 in pairs(IMG) do
        local r = rows[name]
        if r and r.img then
            local ok, asset = pcall(function()
                local fn = "MisterHubImg_" .. (name:gsub("%W", "")) .. "_v1.jpg"
                if not (isfile and isfile(fn)) then writefile(fn, b64decode(b64)) end
                return getAsset(fn)
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
    local a = auto[buyMode]
    local wide = a.all or a.best -- need every item in stock to know the "best" / "all"
    local cands, now = {}, os.clock()
    for _, d in ipairs(pg:GetDescendants()) do
        local nm = seedOf(d)
        if nm and (wide or selected[nm]) and (cooldown[nm] or 0) < now and not d:IsDescendantOf(gui) then
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
    if not a.all then
        -- best = the rarest item in stock (the lists are sorted from least to most rare)
        local bestName
        if a.best then
            local top = 0
            for i, it in ipairs(buyMode == "egg" and EGGS or SEEDS) do
                if found[it[1]] and i > top then top, bestName = i, it[1] end
            end
        end
        for nm in pairs(found) do
            if not (a.sel and selected[nm]) and nm ~= bestName then
                found[nm] = nil
                n -= 1
            end
        end
    end
    return found, n
end

local VISIT_LIMIT = 45   -- max seconds per shop visit
local STUCK_PRESSES = 6  -- presses with no stock change before skipping that pack

-- one pass for the current buyMode (seed shop or egg shop)
local function visit()
    do
            local found, n = scan()
            if n > 0 then
                local clicks, stuck, t0, note = {}, {}, os.clock(), nil
                -- PHASE 1: buy from anywhere (no movement). Works if the game
                -- trusts Remote / prompt fires without a server distance check.
                if remoteOn then
                    local names = {}
                    for nm in pairs(found) do table.insert(names, nm) end
                    local firedAny = false
                    for _, nm in ipairs(names) do
                        if running and (maxPer <= 0 or (clicks[nm] or 0) < maxPer) then
                            local short = (nm:gsub(" Seed Pack", ""))
                            status.Text = "Clicks: " .. bought .. "\nBuying (remote): " .. short
                            if tryRemoteBuy(nm) then
                                firedAny = true
                                clicks[nm] = (clicks[nm] or 0) + 1
                                bought += 1
                            end
                            task.wait(0.15)
                        end
                    end
                    if firedAny then
                        task.wait(0.6) -- let the server update stock
                        found, n = scan()
                        if n == 0 then
                            status.Text = "Clicks: " .. bought .. "\nDone (remote), waiting for restock"
                            return
                        end
                    end
                    log("Visit: " .. n .. " pack(s) left after remote attempt")
                end

                -- PHASE 2 (fallback): ONE spoof-TP trip, buy everything, instant return
                -- This is only reached when remote buy left stock behind
                -- (game enforces server-side distance check).
                local origin, moved = nil, false
                if tpOn then
                    local h, scf = getHRP(), getShopCF()
                    if not scf then
                        status.Text = "Clicks: " .. bought .. "\nShop not found: save position in Settings"
                    elseif h and (h.Position - scf.Position).Magnitude > 20 then
                        origin = h.CFrame
                        -- spoof: drop velocity, pivot instantly, anchor 1 frame so
                        -- physics / fall damage never drags you back mid-purchase
                        pcall(function()
                            h.AssemblyLinearVelocity = Vector3.zero
                            h.AssemblyAngularVelocity = Vector3.zero
                        end)
                        local char = lp.Character
                        if char and char.PivotTo then
                            char:PivotTo(scf)
                        else
                            tp(scf)
                        end
                        moved = true
                        task.wait(0.35)
                    end
                end
                log("Visit: " .. n .. " pack(s) in stock" .. (moved and " (teleported)" or ""))

                -- stay and buy until out of stock (unlimited when maxPer = 0)
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

                -- return once, when everything is bought (instant spoof-back)
                if moved and origin then
                    task.wait(0.1)
                    local char = lp.Character
                    if char and char.PivotTo then
                        pcall(function() char:PivotTo(origin) end)
                    else
                        tp(origin)
                    end
                end
                status.Text = "Clicks: " .. bought .. "\n" .. (note or "Done, waiting for restock")
            else
                status.Text = "Clicks: " .. bought .. "\nWaiting for stock..."
            end
    end
end

task.spawn(function()
    while gui.Parent do
        if running then
            for _, m in ipairs({"seed", "egg"}) do
                if running and catOn(m) then
                    buyMode = m
                    visit()
                end
            end
        end
        task.wait(delay)
    end
end)

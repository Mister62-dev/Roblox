-- <w> : by wleo : yoruka.id
-- Auto Buy Seeds: klik tombol ACHETER di UI shop (tanpa remote)
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")
local lp = Players.LocalPlayer
local pg = lp:WaitForChild("PlayerGui")

-- {nama, {pola teks FR/EN}}
local SEEDS = {
    {"Basic Seed Pack",{"graines basique","basic seed"}},
    {"Garden Seed Pack",{"graines de jardin","garden seed"}},
    {"Sunny Seed Pack",{"ensoleill","sunny seed"}},
    {"Floral Seed Pack",{"florale","floral seed","bloom seed"}},
    {"Crystal Seed Pack",{"cristal","crystal seed"}},
    {"Moonlight Seed Pack",{"clair de lune","moonlight seed"}},
    {"Ember Seed Pack",{"ember"}},
    {"Aurora Seed Pack",{"aurore","aurora seed"}},
    {"Golden Sun Seed Pack",{"soleil dor","golden sun"}},
    {"Dragon Seed Pack",{"dragon"}},
    {"Phoenix Seed Pack",{"phénix","phenix","phoenix"}},
    {"Cosmic Seed Pack",{"cosmique","cosmic seed"}},
    {"Mutant Seed Pack",{"mutant seed"}},
    {"Void Seed Pack",{"du vide","void seed"}},
    {"Celestial Seed Pack",{"célestes","celestes","celestial seed"}},
    {"Spooky Seed Pack",{"spooky seed"}},
}

local selected, running, delay, amount, bought = {}, false, 1, 1, 0

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
            firesignal(btn.MouseButton1Click)
            firesignal(btn.Activated)
            done = true
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

-- GUI
local parent = (gethui and gethui()) or game:GetService("CoreGui")
pcall(function() parent:FindFirstChild("YorukaAutoBuy"):Destroy() end)
local gui = Instance.new("ScreenGui")
gui.Name = "YorukaAutoBuy"; gui.ResetOnSpawn = false; gui.Parent = parent

local main = Instance.new("Frame", gui)
main.Size = UDim2.fromOffset(280, 400)
main.Position = UDim2.new(0.5, -140, 0.5, -200)
main.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
main.BorderSizePixel = 0
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 10)

local title = Instance.new("TextLabel", main)
title.Size = UDim2.new(1, 0, 0, 34)
title.BackgroundColor3 = Color3.fromRGB(32, 36, 52)
title.BorderSizePixel = 0
title.Text = "Auto Buy Seeds | yoruka.id"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold; title.TextSize = 14
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 10)

do
    local dragging, start, startPos
    title.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging, start, startPos = true, i.Position, main.Position
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - start
            main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
end

local list = Instance.new("ScrollingFrame", main)
list.Position = UDim2.fromOffset(8, 40)
list.Size = UDim2.new(1, -16, 1, -170)
list.BackgroundTransparency = 1
list.ScrollBarThickness = 4
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.new()
Instance.new("UIListLayout", list).Padding = UDim.new(0, 4)

local btns = {}
for _, s in ipairs(SEEDS) do
    local name = s[1]
    local b = Instance.new("TextButton", list)
    b.Size = UDim2.new(1, -6, 0, 26)
    b.BackgroundColor3 = Color3.fromRGB(45, 48, 62)
    b.BorderSizePixel = 0
    b.Text = "☐  " .. name
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.Gotham; b.TextSize = 13
    b.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    btns[name] = b
    b.MouseButton1Click:Connect(function()
        selected[name] = not selected[name]
        b.Text = (selected[name] and "☑  " or "☐  ") .. name
        b.BackgroundColor3 = selected[name] and Color3.fromRGB(40, 120, 80) or Color3.fromRGB(45, 48, 62)
    end)
end

local function mkBtn(text, x, w, y, color)
    local b = Instance.new("TextButton", main)
    b.Position = UDim2.new(0, x, 1, y); b.Size = UDim2.new(0, w, 0, 28)
    b.BackgroundColor3 = color; b.BorderSizePixel = 0
    b.Text = text; b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold; b.TextSize = 13
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    return b
end

local selAll = mkBtn("Pilih Semua", 8, 126, -124, Color3.fromRGB(55, 90, 160))
local clr = mkBtn("Hapus Pilihan", 146, 126, -124, Color3.fromRGB(120, 60, 60))

local function mkBox(label, x, default)
    local l = Instance.new("TextLabel", main)
    l.Position = UDim2.new(0, x, 1, -90); l.Size = UDim2.fromOffset(60, 24)
    l.BackgroundTransparency = 1; l.Text = label
    l.TextColor3 = Color3.new(1, 1, 1); l.Font = Enum.Font.Gotham; l.TextSize = 12
    local t = Instance.new("TextBox", main)
    t.Position = UDim2.new(0, x + 60, 1, -90); t.Size = UDim2.fromOffset(60, 24)
    t.BackgroundColor3 = Color3.fromRGB(45, 48, 62); t.BorderSizePixel = 0
    t.Text = tostring(default); t.TextColor3 = Color3.new(1, 1, 1)
    t.Font = Enum.Font.Gotham; t.TextSize = 12
    Instance.new("UICorner", t).CornerRadius = UDim.new(0, 6)
    return t
end

local delayBox = mkBox("Delay(s)", 8, delay)
local amtBox = mkBox("Klik/siklus", 146, amount)
delayBox.FocusLost:Connect(function() delay = math.max(tonumber(delayBox.Text) or 1, 0.2); delayBox.Text = tostring(delay) end)
amtBox.FocusLost:Connect(function() amount = math.max(math.floor(tonumber(amtBox.Text) or 1), 1); amtBox.Text = tostring(amount) end)

local toggle = mkBtn("START", 8, 264, -58, Color3.fromRGB(40, 150, 90))
local status = Instance.new("TextLabel", main)
status.Position = UDim2.new(0, 8, 1, -26); status.Size = UDim2.fromOffset(264, 20)
status.BackgroundTransparency = 1; status.Text = "Klik: 0 | Buka shop dulu"
status.TextColor3 = Color3.fromRGB(180, 190, 210)
status.Font = Enum.Font.Gotham; status.TextSize = 12

local function setAll(v)
    for name, b in pairs(btns) do
        selected[name] = v
        b.Text = (v and "☑  " or "☐  ") .. name
        b.BackgroundColor3 = v and Color3.fromRGB(40, 120, 80) or Color3.fromRGB(45, 48, 62)
    end
end
selAll.MouseButton1Click:Connect(function() setAll(true) end)
clr.MouseButton1Click:Connect(function() setAll(false) end)

toggle.MouseButton1Click:Connect(function()
    running = not running
    toggle.Text = running and "STOP" or "START"
    toggle.BackgroundColor3 = running and Color3.fromRGB(170, 55, 55) or Color3.fromRGB(40, 150, 90)
end)

task.spawn(function()
    while gui.Parent do
        if running then
            local found = {}
            for _, d in ipairs(pg:GetDescendants()) do
                local n = seedOf(d)
                if n and selected[n] and not found[n] and not d:IsDescendantOf(gui) then
                    local btn = rowButton(d)
                    if btn then found[n] = btn end
                end
            end
            for _, btn in pairs(found) do
                for _ = 1, amount do
                    if not running then break end
                    press(btn)
                    bought += 1
                    task.wait(0.1)
                end
            end
            status.Text = "Klik: " .. bought .. " | Stok ketemu: " .. (function() local c = 0 for _ in pairs(found) do c += 1 end return c end)()
        end
        task.wait(delay)
    end
end)

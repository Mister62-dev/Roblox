-- Roblox Game Scanner | UI Edition
-- Delta Executor | Août 2026
-- Draggable | Toggles | Live Log | Export

local Players     = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- ══════════════════════════════════════════
--  CLEANUP ancien UI
-- ══════════════════════════════════════════
if PlayerGui:FindFirstChild("ScannerUI") then
    PlayerGui:FindFirstChild("ScannerUI"):Destroy()
end

-- ══════════════════════════════════════════
--  COULEURS & STYLE
-- ══════════════════════════════════════════
local C = {
    BG         = Color3.fromRGB(12, 12, 18),
    Panel      = Color3.fromRGB(18, 18, 28),
    Accent     = Color3.fromRGB(80, 200, 120),
    AccentDark = Color3.fromRGB(40, 120, 70),
    Red        = Color3.fromRGB(220, 60, 60),
    Text       = Color3.fromRGB(220, 220, 220),
    TextDim    = Color3.fromRGB(120, 120, 140),
    Border     = Color3.fromRGB(40, 40, 60),
    ToggleOff  = Color3.fromRGB(40, 40, 55),
    ToggleOn   = Color3.fromRGB(80, 200, 120),
    LogBG      = Color3.fromRGB(8, 8, 14),
}

-- ══════════════════════════════════════════
--  HELPERS
-- ══════════════════════════════════════════
local function make(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props) do obj[k] = v end
    if parent then obj.Parent = parent end
    return obj
end

local function corner(radius, parent)
    return make("UICorner", {CornerRadius = UDim.new(0, radius)}, parent)
end

local function stroke(thickness, color, parent)
    return make("UIStroke", {Thickness = thickness, Color = color}, parent)
end

local function tween(obj, props, t)
    TweenService:Create(obj, TweenInfo.new(t or 0.15, Enum.EasingStyle.Quad), props):Play()
end

-- ══════════════════════════════════════════
--  ROOT
-- ══════════════════════════════════════════
local ScreenGui = make("ScreenGui", {
    Name             = "ScannerUI",
    ResetOnSpawn     = false,
    ZIndexBehavior   = Enum.ZIndexBehavior.Sibling,
}, PlayerGui)

-- ══════════════════════════════════════════
--  MAIN FRAME
-- ══════════════════════════════════════════
local Main = make("Frame", {
    Size            = UDim2.new(0, 420, 0, 560),
    Position        = UDim2.new(0.5, -210, 0.5, -280),
    BackgroundColor3 = C.BG,
    BorderSizePixel = 0,
}, ScreenGui)
corner(10, Main)
stroke(1.5, C.Border, Main)

-- ══════════════════════════════════════════
--  TITLEBAR
-- ══════════════════════════════════════════
local TitleBar = make("Frame", {
    Size            = UDim2.new(1, 0, 0, 44),
    BackgroundColor3 = C.Panel,
    BorderSizePixel = 0,
}, Main)
corner(10, TitleBar)

-- Fix coin bas titlebar
make("Frame", {
    Size            = UDim2.new(1, 0, 0, 10),
    Position        = UDim2.new(0, 0, 1, -10),
    BackgroundColor3 = C.Panel,
    BorderSizePixel = 0,
}, TitleBar)

-- Dot décoratif
make("Frame", {
    Size            = UDim2.new(0, 8, 0, 8),
    Position        = UDim2.new(0, 14, 0.5, -4),
    BackgroundColor3 = C.Accent,
    BorderSizePixel = 0,
}, TitleBar)
corner(4, TitleBar:FindFirstChildOfClass("Frame"))

make("TextLabel", {
    Size            = UDim2.new(1, -80, 1, 0),
    Position        = UDim2.new(0, 28, 0, 0),
    BackgroundTransparency = 1,
    Text            = "ROBLOX GAME SCANNER",
    TextColor3      = C.Text,
    TextSize        = 13,
    Font            = Enum.Font.GothamBold,
    TextXAlignment  = Enum.TextXAlignment.Left,
}, TitleBar)

make("TextLabel", {
    Size            = UDim2.new(0, 60, 0, 14),
    Position        = UDim2.new(0, 28, 0.5, 0),
    BackgroundTransparency = 1,
    Text            = "DELTA READY",
    TextColor3      = C.Accent,
    TextSize        = 10,
    Font            = Enum.Font.GothamBold,
    TextXAlignment  = Enum.TextXAlignment.Left,
}, TitleBar)

-- Bouton close
local CloseBtn = make("TextButton", {
    Size            = UDim2.new(0, 28, 0, 28),
    Position        = UDim2.new(1, -36, 0.5, -14),
    BackgroundColor3 = C.Red,
    Text            = "✕",
    TextColor3      = Color3.fromRGB(255,255,255),
    TextSize        = 12,
    Font            = Enum.Font.GothamBold,
    BorderSizePixel = 0,
}, TitleBar)
corner(6, CloseBtn)

CloseBtn.MouseButton1Click:Connect(function()
    tween(Main, {Position = UDim2.new(0.5,-210,1.5,-280)}, 0.25)
    task.wait(0.3)
    ScreenGui:Destroy()
end)

-- ══════════════════════════════════════════
--  DRAG
-- ══════════════════════════════════════════
do
    local dragging, dragStart, startPos
    TitleBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = inp.Position
            startPos  = Main.Position
        end
    end)
    TitleBar.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = inp.Position - dragStart
            Main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ══════════════════════════════════════════
--  BODY
-- ══════════════════════════════════════════
local Body = make("Frame", {
    Size            = UDim2.new(1, -20, 1, -54),
    Position        = UDim2.new(0, 10, 0, 50),
    BackgroundTransparency = 1,
}, Main)

-- ══════════════════════════════════════════
--  SECTION LABEL
-- ══════════════════════════════════════════
local function sectionLabel(text, yPos, parent)
    make("TextLabel", {
        Size            = UDim2.new(1, 0, 0, 16),
        Position        = UDim2.new(0, 0, 0, yPos),
        BackgroundTransparency = 1,
        Text            = "— " .. text,
        TextColor3      = C.TextDim,
        TextSize        = 10,
        Font            = Enum.Font.GothamBold,
        TextXAlignment  = Enum.TextXAlignment.Left,
    }, parent)
end

-- ══════════════════════════════════════════
--  TOGGLE FACTORY
-- ══════════════════════════════════════════
local Toggles = {}

local function makeToggle(label, key, xOff, yOff, parent, default)
    default = default ~= false
    Toggles[key] = default

    local row = make("Frame", {
        Size            = UDim2.new(0, 185, 0, 32),
        Position        = UDim2.new(0, xOff, 0, yOff),
        BackgroundColor3 = C.Panel,
        BorderSizePixel = 0,
    }, parent)
    corner(7, row)
    stroke(1, C.Border, row)

    make("TextLabel", {
        Size            = UDim2.new(1, -50, 1, 0),
        Position        = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text            = label,
        TextColor3      = C.Text,
        TextSize        = 11,
        Font            = Enum.Font.Gotham,
        TextXAlignment  = Enum.TextXAlignment.Left,
    }, row)

    local pill = make("Frame", {
        Size            = UDim2.new(0, 36, 0, 18),
        Position        = UDim2.new(1, -44, 0.5, -9),
        BackgroundColor3 = default and C.ToggleOn or C.ToggleOff,
        BorderSizePixel = 0,
    }, row)
    corner(9, pill)

    local knob = make("Frame", {
        Size     = UDim2.new(0, 14, 0, 14),
        Position = default and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7),
        BackgroundColor3 = Color3.fromRGB(255,255,255),
        BorderSizePixel  = 0,
    }, pill)
    corner(7, knob)

    local btn = make("TextButton", {
        Size               = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1,
        Text               = "",
    }, row)

    btn.MouseButton1Click:Connect(function()
        Toggles[key] = not Toggles[key]
        local on = Toggles[key]
        tween(pill, {BackgroundColor3 = on and C.ToggleOn or C.ToggleOff})
        tween(knob, {Position = on and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)})
    end)
end

-- ══════════════════════════════════════════
--  TOGGLES LAYOUT
-- ══════════════════════════════════════════
sectionLabel("CATÉGORIES DE SCAN", 0, Body)

makeToggle("Scripts",           "Scripts",   0,   20, Body, true)
makeToggle("Remotes",           "Remotes",   195, 20, Body, true)
makeToggle("GUI / Interface",   "GUI",       0,   60, Body, true)
makeToggle("Values",            "Values",    195, 60, Body, true)
makeToggle("Meshes / Parts",    "Meshes",    0,  100, Body, false)
makeToggle("Workspace",         "Workspace", 195,100, Body, true)
makeToggle("ReplicatedStorage", "RepStor",   0,  140, Body, true)
makeToggle("StarterPack/Gui",   "Starter",   195,140, Body, true)

sectionLabel("OPTIONS", 186, Body)

makeToggle("Console output",    "Console",   0,  206, Body, true)
makeToggle("Export fichier",    "Export",    195,206, Body, true)

-- ══════════════════════════════════════════
--  LOG AREA
-- ══════════════════════════════════════════
sectionLabel("LOG EN TEMPS RÉEL", 250, Body)

local LogFrame = make("Frame", {
    Size            = UDim2.new(1, 0, 0, 170),
    Position        = UDim2.new(0, 0, 0, 268),
    BackgroundColor3 = C.LogBG,
    BorderSizePixel = 0,
}, Body)
corner(7, LogFrame)
stroke(1, C.Border, LogFrame)

local LogScroll = make("ScrollingFrame", {
    Size                = UDim2.new(1,-8, 1,-8),
    Position            = UDim2.new(0,4,0,4),
    BackgroundTransparency = 1,
    ScrollBarThickness  = 3,
    ScrollBarImageColor3 = C.Accent,
    CanvasSize          = UDim2.new(0,0,0,0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    BorderSizePixel     = 0,
}, LogFrame)

make("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding   = UDim.new(0,2),
}, LogScroll)

local logCount = 0
local function addLog(msg, color)
    logCount = logCount + 1
    local lbl = make("TextLabel", {
        Size               = UDim2.new(1,-8,0,14),
        BackgroundTransparency = 1,
        Text               = msg,
        TextColor3         = color or C.Text,
        TextSize           = 10,
        Font               = Enum.Font.Code,
        TextXAlignment     = Enum.TextXAlignment.Left,
        TextTruncate       = Enum.TextTruncate.AtEnd,
        LayoutOrder        = logCount,
    }, LogScroll)
    task.defer(function()
        LogScroll.CanvasPosition = Vector2.new(0, math.huge)
    end)
end

-- ══════════════════════════════════════════
--  STATUS BAR
-- ══════════════════════════════════════════
local StatusLabel = make("TextLabel", {
    Size            = UDim2.new(1,0,0,14),
    Position        = UDim2.new(0,0,0,444),
    BackgroundTransparency = 1,
    Text            = "Prêt.",
    TextColor3      = C.TextDim,
    TextSize        = 10,
    Font            = Enum.Font.Gotham,
    TextXAlignment  = Enum.TextXAlignment.Left,
}, Body)

local function setStatus(txt, color)
    StatusLabel.Text       = txt
    StatusLabel.TextColor3 = color or C.TextDim
end

-- ══════════════════════════════════════════
--  BOUTON SCAN
-- ══════════════════════════════════════════
local ScanBtn = make("TextButton", {
    Size            = UDim2.new(1,0,0,36),
    Position        = UDim2.new(0,0,0,460),
    BackgroundColor3 = C.Accent,
    Text            = "▶  LANCER LE SCAN",
    TextColor3      = Color3.fromRGB(10,10,10),
    TextSize        = 13,
    Font            = Enum.Font.GothamBold,
    BorderSizePixel = 0,
}, Body)
corner(8, ScanBtn)

-- ══════════════════════════════════════════
--  LOGIQUE SCAN
-- ══════════════════════════════════════════
local TRACKED_CLASSES_MAP = {
    Script           = "Scripts",
    LocalScript      = "Scripts",
    ModuleScript     = "Scripts",
    RemoteEvent      = "Remotes",
    RemoteFunction   = "Remotes",
    BindableEvent    = "Remotes",
    BindableFunction = "Remotes",
    ScreenGui        = "GUI",
    Frame            = "GUI",
    TextLabel        = "GUI",
    TextButton       = "GUI",
    ImageLabel       = "GUI",
    StringValue      = "Values",
    IntValue         = "Values",
    NumberValue      = "Values",
    BoolValue        = "Values",
    ObjectValue      = "Values",
    MeshPart         = "Meshes",
    SpecialMesh      = "Meshes",
    UnionOperation   = "Meshes",
}

local scanning = false

ScanBtn.MouseButton1Click:Connect(function()
    if scanning then return end
    scanning = true

    tween(ScanBtn, {BackgroundColor3 = C.AccentDark})
    ScanBtn.Text = "⏳  SCAN EN COURS..."
    setStatus("Scan en cours...", C.Accent)

    -- Clear log
    for _, c in ipairs(LogScroll:GetChildren()) do
        if c:IsA("TextLabel") then c:Destroy() end
    end
    logCount = 0

    local Output  = {}
    local Results = {}

    local header = string.format(
        "=== SCANNER | %s | %s ===",
        game.Name, os.date("%H:%M:%S")
    )
    table.insert(Output, header)
    addLog(header, C.Accent)

    local TARGETS = {}
    if Toggles.Workspace then table.insert(TARGETS, game:GetService("Workspace")) end
    if Toggles.RepStor    then table.insert(TARGETS, game:GetService("ReplicatedStorage")) end
    if Toggles.Starter    then
        table.insert(TARGETS, game:GetService("StarterPack"))
        table.insert(TARGETS, game:GetService("StarterGui"))
        table.insert(TARGETS, game:GetService("StarterPlayer"))
    end
    table.insert(TARGETS, game:GetService("ReplicatedFirst"))
    table.insert(TARGETS, game:GetService("Lighting"))
    table.insert(TARGETS, game:GetService("SoundService"))

    local function ScanInstance(inst, depth)
        depth = depth or 0
        local cls  = inst.ClassName
        local cat  = TRACKED_CLASSES_MAP[cls]
        if cat and Toggles[cat] then
            local path  = inst:GetFullName()
            local entry = string.format("[%s] %s", cls, path)

            if cat == "Values" then
                local ok, val = pcall(function() return tostring(inst.Value) end)
                if ok then entry = entry .. " = " .. val end
            end
            if cat == "Scripts" then
                local ok, src = pcall(function() return inst.Source end)
                entry = entry .. (ok and src ~= "" and (" [" .. #src .. " chars]") or " [protected]")
            end

            table.insert(Output, entry)
            table.insert(Results, {class=cls, path=path})

            local color = C.Text
            if cat == "Scripts"  then color = Color3.fromRGB(130,200,255) end
            if cat == "Remotes"  then color = Color3.fromRGB(255,180,80)  end
            if cat == "Values"   then color = Color3.fromRGB(180,255,150) end
            if cat == "GUI"      then color = Color3.fromRGB(220,150,255) end
            if cat == "Meshes"   then color = Color3.fromRGB(255,120,120) end

            addLog(entry, color)
            if Toggles.Console then print(entry) end
        end

        local ok, children = pcall(function() return inst:GetChildren() end)
        if ok then
            for _, child in ipairs(children) do
                pcall(ScanInstance, child, depth+1)
            end
        end
    end

    for _, target in ipairs(TARGETS) do
        local svc = "--- " .. target.Name .. " ---"
        table.insert(Output, svc)
        addLog(svc, C.TextDim)
        pcall(ScanInstance, target, 0)
        task.wait()
    end

    -- Résumé
    local summary = string.format("=== TOTAL : %d éléments ===", #Results)
    table.insert(Output, summary)
    addLog(summary, C.Accent)

    local classCounts = {}
    for _, r in ipairs(Results) do
        classCounts[r.class] = (classCounts[r.class] or 0) + 1
    end
    for cls, count in pairs(classCounts) do
        local line = string.format("  %s : %d", cls, count)
        table.insert(Output, line)
        addLog(line, C.TextDim)
    end

    -- Export
    if Toggles.Export then
        local fname = "Scan_" .. game.Name:gsub("%s","_") .. "_" .. os.time() .. ".txt"
        local ok, err = pcall(writefile, fname, table.concat(Output, "\n"))
        if ok then
            addLog("✔ Fichier exporté : " .. fname, C.Accent)
            setStatus("✔ Export : " .. fname, C.Accent)
        else
            addLog("✘ writefile indisponible", C.Red)
            setStatus("Export échoué.", C.Red)
        end
    else
        setStatus("✔ Scan terminé — " .. #Results .. " éléments.", C.Accent)
    end

    tween(ScanBtn, {BackgroundColor3 = C.Accent})
    ScanBtn.Text = "▶  LANCER LE SCAN"
    scanning = false
end)

-- ══════════════════════════════════════════
--  INTRO ANIM
-- ══════════════════════════════════════════
Main.Position = UDim2.new(0.5,-210,1.5,-280)
tween(Main, {Position = UDim2.new(0.5,-210,0.5,-280)}, 0.35)

addLog("Scanner prêt. Configure les toggles et lance le scan.", C.Accent)
addLog("Game : " .. game.Name, C.TextDim)
addLog("Job ID : " .. game.JobId, C.TextDim)

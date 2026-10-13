-- Checkpoint TP | yoruka.id
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local lp = Players.LocalPlayer

local GUI_NAME = "CheckpointTP_GUI"

-- Pilih parent GUI (CoreGui, fallback PlayerGui)
local function getParent()
    local ok, core = pcall(function() return game:GetService("CoreGui") end)
    if ok and core then
        local test = Instance.new("ScreenGui")
        local okParent = pcall(function() test.Parent = core end)
        test:Destroy()
        if okParent then return core end
    end
    return lp:WaitForChild("PlayerGui")
end

local parentGui = getParent()

-- Hapus GUI lama
pcall(function()
    local old = parentGui:FindFirstChild(GUI_NAME)
    if old then old:Destroy() end
end)

-- ========== GUI ==========
local screenGui = Instance.new("ScreenGui")
screenGui.Name = GUI_NAME
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = parentGui

local frame = Instance.new("Frame")
frame.Name = "Main"
frame.Size = UDim2.new(0, 220, 0, 130)
frame.Position = UDim2.new(0.5, -110, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = screenGui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 8)
frameCorner.Parent = frame

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 32)
title.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
title.BorderSizePixel = 0
title.Text = "Checkpoint TP"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Active = true
title.Parent = frame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = title

local toggleBtn = Instance.new("TextButton")
toggleBtn.Name = "Toggle"
toggleBtn.Size = UDim2.new(0, 180, 0, 40)
toggleBtn.Position = UDim2.new(0.5, -90, 0, 44)
toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
toggleBtn.BorderSizePixel = 0
toggleBtn.Text = "OFF"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 18
toggleBtn.AutoButtonColor = false
toggleBtn.Parent = frame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 6)
btnCorner.Parent = toggleBtn

local status = Instance.new("TextLabel")
status.Name = "Status"
status.Size = UDim2.new(1, -20, 0, 30)
status.Position = UDim2.new(0, 10, 0, 92)
status.BackgroundTransparency = 1
status.Text = "Status: idle"
status.TextColor3 = Color3.fromRGB(200, 200, 200)
status.Font = Enum.Font.Gotham
status.TextSize = 13
status.TextWrapped = true
status.Parent = frame

-- ========== DRAG ==========
local dragging = false
local dragStart, startPos

title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

-- ========== CHECKPOINT DETECTION (STRICT) ==========

-- Nama container yang diprioritaskan
local CONTAINERS = {
    ["obby"] = true,
    ["stages"] = true,
    ["stage"] = true,
    ["stagesfolder"] = true,
    ["stagefolder"] = true,
    ["checkpoints"] = true,
    ["checkpoint"] = true,
    ["checkpointfolder"] = true,
    ["obbystages"] = true,
}

-- Kata kunci yang di-BLOCK (di nama part ATAU nama ancestor-nya)
local BLOCK_WORDS = {
    "gamepass", "devproduct", "developerproduct", "product", "robux",
    "vip", "shop", "store", "purchase", "promptpurchase", "buy",
    "donat", "premium", "prompt", "skip", "gift", "rebirth", "decor",
    "decoration", "ads", "billboard",
}

-- Nama part yang di-BLOCK (cocok sebagian pada nama part saja)
local BLOCK_PART_WORDS = {
    "spawnlocation", "baseplate", "start", "lobby",
}

local function containsAny(str, words)
    for _, w in ipairs(words) do
        if string.find(str, w, 1, true) then
            return true
        end
    end
    return false
end

-- Cek nama part + semua ancestor sampai Workspace
local function isBlocked(part)
    local lname = string.lower(part.Name)
    if containsAny(lname, BLOCK_WORDS) or containsAny(lname, BLOCK_PART_WORDS) then
        return true
    end

    local cur = part.Parent
    while cur and cur ~= workspace do
        if containsAny(string.lower(cur.Name), BLOCK_WORDS) then
            return true
        end
        cur = cur.Parent
    end

    -- Part dengan prompt / click (toko, gamepass, dll)
    if part:FindFirstChildWhichIsA("ProximityPrompt", true)
        or part:FindFirstChildWhichIsA("ClickDetector", true) then
        return true
    end

    return false
end

local function isCharacterPart(part)
    local model = part:FindFirstAncestorOfClass("Model")
    return model ~= nil and model:FindFirstChildOfClass("Humanoid") ~= nil
end

local function firstNumber(str)
    local n = string.match(str, "%d+")
    if n then return tonumber(n) end
    return nil
end

local function hasTouch(part)
    return part:FindFirstChildOfClass("TouchInterest") ~= nil
        or part:FindFirstChild("TouchInterest") ~= nil
end

local function hasStageWord(lname)
    return string.find(lname, "checkpoint", 1, true) ~= nil
        or string.find(lname, "stage", 1, true) ~= nil
        or string.find(lname, "cp", 1, true) ~= nil
end

-- Skor prioritas bila ada beberapa part dengan nomor stage yang sama
local function scoreOf(part)
    local s = 0
    if hasTouch(part) then s = s + 2 end
    local lname = string.lower(part.Name)
    if string.find(lname, "checkpoint", 1, true) or string.find(lname, "stage", 1, true) then
        s = s + 1
    end
    return s
end

-- Ambil nomor stage dari part di dalam container
local function numberInContainer(part, container)
    -- 1) nama part mengandung angka
    local n = firstNumber(part.Name)
    if n then return n end

    -- 2) nama model/folder di antara part dan container mengandung angka
    if hasTouch(part) or hasStageWord(string.lower(part.Name)) then
        local cur = part.Parent
        while cur and cur ~= container and cur ~= workspace do
            local pn = firstNumber(cur.Name)
            if pn then return pn end
            cur = cur.Parent
        end
    end

    return nil
end

local function scanCheckpoints()
    local byNumber = {}
    local seen = {}
    local source = "global"

    local function consider(part, num)
        if not num or num < 1 then return end
        local existing = byNumber[num]
        if (not existing) or scoreOf(part) > scoreOf(existing) then
            byNumber[num] = part
        end
    end

    -- ===== TAHAP 1: scan container prioritas =====
    local containers = {}
    for _, o in ipairs(workspace:GetDescendants()) do
        if (o:IsA("Folder") or o:IsA("Model")) and CONTAINERS[string.lower(o.Name)] then
            if not containsAny(string.lower(o.Name), BLOCK_WORDS) then
                table.insert(containers, o)
            end
        end
    end

    local foundInContainer = false
    for _, container in ipairs(containers) do
        for _, obj in ipairs(container:GetDescendants()) do
            if obj:IsA("BasePart") and not seen[obj] then
                seen[obj] = true
                if not isCharacterPart(obj) and not isBlocked(obj) then
                    local num = numberInContainer(obj, container)
                    if num then
                        consider(obj, num)
                        foundInContainer = true
                    end
                end
            end
        end
    end

    if foundInContainer then
        source = "container"
    else
        -- ===== TAHAP 2: fallback global (lebih ketat) =====
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and not seen[obj] then
                seen[obj] = true
                local lname = string.lower(obj.Name)
                local num = firstNumber(obj.Name)
                if num and not isCharacterPart(obj) and not isBlocked(obj) then
                    local pureNumber = string.match(obj.Name, "^%s*%d+%s*$") ~= nil
                    if hasStageWord(lname) or (pureNumber and hasTouch(obj)) then
                        consider(obj, num)
                    end
                end
            end
        end
    end

    -- Susun urut naik berdasarkan nomor
    local numbers = {}
    for n in pairs(byNumber) do
        table.insert(numbers, n)
    end
    table.sort(numbers, function(a, b) return a < b end)

    local list = {}
    for _, n in ipairs(numbers) do
        table.insert(list, {part = byNumber[n], num = n})
    end

    return list, source
end

-- ========== TELEPORT LOOP ==========
local enabled = false
local runId = 0

local function setStatus(text)
    status.Text = "Status: " .. text
end

local function setToggleVisual()
    if enabled then
        toggleBtn.Text = "ON"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 70)
    else
        toggleBtn.Text = "OFF"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
    end
end

local function getRoot()
    local char = lp.Character
    if not char then return nil end
    return char:FindFirstChild("HumanoidRootPart")
end

local function startLoop()
    runId = runId + 1
    local myId = runId

    task.spawn(function()
        setStatus("scanning...")
        local list, source = scanCheckpoints()

        if not enabled or myId ~= runId then return end

        if #list == 0 then
            setStatus("checkpoint tidak ditemukan")
            if myId == runId then
                enabled = false
                setToggleVisual()
            end
            return
        end

        setStatus(#list .. " checkpoint (" .. source .. ")")
        task.wait(0.3)

        for i, entry in ipairs(list) do
            -- cek ON sebelum setiap teleport
            if not enabled or myId ~= runId then
                return
            end

            local part = entry.part
            local root = getRoot()
            if root and part and part.Parent then
                root.CFrame = part.CFrame + Vector3.new(0, 3, 0)
                setStatus("TP " .. i .. "/" .. #list .. " : #" .. entry.num .. " " .. part.Name)
            end

            task.wait(0.5)
        end

        if myId == runId then
            enabled = false
            setToggleVisual()
            setStatus("selesai (" .. #list .. " checkpoint)")
        end
    end)
end

toggleBtn.MouseButton1Click:Connect(function()
    enabled = not enabled
    setToggleVisual()
    if enabled then
        startLoop()
    else
        runId = runId + 1
        setStatus("dihentikan")
    end
end)

setToggleVisual()

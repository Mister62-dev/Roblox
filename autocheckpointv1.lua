-- Checkpoint TP | yoruka.id
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local lp = Players.LocalPlayer

local GUI_NAME = "CheckpointTP_GUI"

-- Bersihkan koneksi dari eksekusi sebelumnya
pcall(function()
    local env = getgenv and getgenv() or _G
    if env._CPTP_CONNS then
        for _, c in ipairs(env._CPTP_CONNS) do
            pcall(function() c:Disconnect() end)
        end
    end
    env._CPTP_CONNS = {}
end)

local function trackConn(conn)
    pcall(function()
        local env = getgenv and getgenv() or _G
        env._CPTP_CONNS = env._CPTP_CONNS or {}
        table.insert(env._CPTP_CONNS, conn)
    end)
    return conn
end

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

trackConn(UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end))

-- ========== CHECKPOINT REGISTRY (DYNAMIC / STREAMING) ==========
-- registry[nomor] = { [objek] = true }
local registry = {}

local function isCharacterObject(obj)
    if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then
        return true
    end
    local model = obj:FindFirstAncestorOfClass("Model")
    return model ~= nil and model:FindFirstChildOfClass("Humanoid") ~= nil
end

local function hasTouch(part)
    return part:FindFirstChildOfClass("TouchInterest") ~= nil
        or part:FindFirstChild("TouchInterest") ~= nil
end

local function getNumber(obj)
    if not (obj:IsA("BasePart") or obj:IsA("Model")) then return nil end
    -- Format wajib: "Checkpoint" + angka
    local numStr = string.match(string.lower(obj.Name), "^checkpoint(%d+)$")
    if not numStr then return nil end
    return tonumber(numStr)
end

local function register(obj)
    local n = getNumber(obj)
    if not n then return end
    if isCharacterObject(obj) then return end
    registry[n] = registry[n] or {}
    registry[n][obj] = true
end

local function unregister(obj)
    local n = getNumber(obj)
    if not n then return end
    local set = registry[n]
    if set then
        set[obj] = nil
        if next(set) == nil then
            registry[n] = nil
        end
    end
end

-- Scan penuh Workspace (dipanggil saat awal & saat menunggu map load)
local function fullRescan()
    for _, obj in ipairs(workspace:GetDescendants()) do
        register(obj)
    end
end

-- Pantau objek yang streaming masuk / keluar
trackConn(workspace.DescendantAdded:Connect(register))
trackConn(workspace.DescendantRemoving:Connect(unregister))

local function scoreOf(obj)
    if obj:IsA("BasePart") then
        return hasTouch(obj) and 3 or 2
    end
    return 1
end

-- Ambil objek terbaik untuk nomor tertentu
local function bestOf(n)
    local set = registry[n]
    if not set then return nil end
    local best, bestScore = nil, -1
    for obj in pairs(set) do
        if obj.Parent then
            local s = scoreOf(obj)
            if s > bestScore then
                best, bestScore = obj, s
            end
        end
    end
    return best
end

-- Nomor terkecil yang lebih besar dari 'above' (untuk nomor yang bolong)
local function smallestAbove(above)
    local result = nil
    for n, set in pairs(registry) do
        if n > above and next(set) ~= nil then
            if (not result) or n < result then
                result = n
            end
        end
    end
    return result
end

local function getObjectCFrame(obj)
    if obj:IsA("BasePart") then
        return obj.CFrame
    elseif obj:IsA("Model") then
        local ok, pivot = pcall(function() return obj:GetPivot() end)
        if ok then return pivot end
    end
    return nil
end

-- ========== TELEPORT LOOP ==========
local enabled = false
local runId = 0
local lastReached = 0      -- checkpoint tertinggi yang sudah dicapai (resume)
local GAP_RETRIES = 5      -- berapa kali menunggu sebelum lompat nomor yang bolong

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
        setStatus("scanning Checkpoint[angka]...")
        fullRescan()

        local misses = 0

        while enabled and myId == runId do
            -- Target logis berikutnya: checkpoint terakhir + 1
            local nextNum = lastReached + 1
            local obj = bestOf(nextNum)

            -- Nomor bolong? setelah beberapa kali menunggu, ambil nomor terkecil di atasnya
            if (not obj) and misses >= GAP_RETRIES then
                local higher = smallestAbove(lastReached)
                if higher then
                    nextNum = higher
                    obj = bestOf(higher)
                end
            end

            if obj then
                -- cek ON sebelum teleport
                if not enabled or myId ~= runId then break end

                local root = getRoot()
                local cf = getObjectCFrame(obj)
                if root and cf then
                    root.CFrame = cf + Vector3.new(0, 3, 0)
                    lastReached = nextNum
                    misses = 0
                    setStatus("TP Checkpoint" .. nextNum .. " (terakhir: " .. lastReached .. ")")
                end
                task.wait(0.5)
            else
                -- Belum ada checkpoint berikutnya (map belum ter-load) -> tunggu & scan ulang
                misses = misses + 1
                setStatus("menunggu map load... terakhir: Checkpoint" .. lastReached)
                fullRescan()
                task.wait(1)
            end
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
        setStatus("dihentikan (terakhir: Checkpoint" .. lastReached .. ")")
    end
end)
fullRescan()
setToggleVisual()

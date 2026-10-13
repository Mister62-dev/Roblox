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

-- ========== CHECKPOINT DETECTION (STRICT: "Checkpoint" + angka) ==========

local function isCharacterObject(obj)
    local model = obj:FindFirstAncestorOfClass("Model")
    if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") then
        return true
    end
    return model ~= nil and model:FindFirstChildOfClass("Humanoid") ~= nil
end

local function hasTouch(part)
    return part:FindFirstChildOfClass("TouchInterest") ~= nil
        or part:FindFirstChild("TouchInterest") ~= nil
end

-- Ambil CFrame dari Part / Model
local function getObjectCFrame(obj)
    if obj:IsA("BasePart") then
        return obj.CFrame
    elseif obj:IsA("Model") then
        local ok, pivot = pcall(function() return obj:GetPivot() end)
        if ok then return pivot end
    end
    return nil
end

-- Prioritas bila ada beberapa objek dengan nomor yang sama
local function scoreOf(obj)
    if obj:IsA("BasePart") then
        return hasTouch(obj) and 3 or 2
    end
    return 1
end

local function scanCheckpoints()
    local byNumber = {}

    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            -- Format wajib: "Checkpoint" + angka (tanpa karakter lain)
            local numStr = string.match(string.lower(obj.Name), "^checkpoint(%d+)$")
            if numStr and not isCharacterObject(obj) then
                local num = tonumber(numStr)
                if num then
                    local existing = byNumber[num]
                    if (not existing) or scoreOf(obj) > scoreOf(existing) then
                        byNumber[num] = obj
                    end
                end
            end
        end
    end

    -- Urut naik: 1 -> 2 -> 3 -> ... -> max
    local numbers = {}
    for n in pairs(byNumber) do
        table.insert(numbers, n)
    end
    table.sort(numbers, function(a, b) return a < b end)

    local list = {}
    for _, n in ipairs(numbers) do
        table.insert(list, {part = byNumber[n], num = n})
    end

    return list
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
        setStatus("scanning Checkpoint[angka]...")
        local list = scanCheckpoints()

        if not enabled or myId ~= runId then return end

        if #list == 0 then
            setStatus("Checkpoint[angka] tidak ditemukan")
            if myId == runId then
                enabled = false
                setToggleVisual()
            end
            return
        end

        local maxNum = list[#list].num
        setStatus(#list .. " checkpoint ditemukan (max: " .. maxNum .. ")")
        task.wait(0.3)

        for i, entry in ipairs(list) do
            -- cek ON sebelum setiap teleport
            if not enabled or myId ~= runId then
                return
            end

            local obj = entry.part
            local root = getRoot()
            if root and obj and obj.Parent then
                local cf = getObjectCFrame(obj)
                if cf then
                    root.CFrame = cf + Vector3.new(0, 3, 0)
                    setStatus("TP " .. i .. "/" .. #list .. " : Checkpoint" .. entry.num)
                end
            end

            task.wait(0.5)
        end

        if myId == runId then
            enabled = false
            setToggleVisual()
            setStatus("selesai (Checkpoint1 -> Checkpoint" .. maxNum .. ")")
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

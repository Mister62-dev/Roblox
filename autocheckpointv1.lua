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

-- ========== CHECKPOINT SCAN ==========
local EXCLUDE = {
    ["spawnlocation"] = true,
    ["start"] = true,
    ["baseplate"] = true,
}

local function isCharacterPart(part)
    local model = part:FindFirstAncestorOfClass("Model")
    return model and model:FindFirstChildOfClass("Humanoid") ~= nil
end

local function extractNumber(part)
    local n = string.match(part.Name, "%d+")
    if n then return tonumber(n) end
    if part.Parent and part.Parent ~= workspace then
        local pn = string.match(part.Parent.Name, "%d+")
        if pn then return tonumber(pn) end
    end
    return nil
end

local function scanCheckpoints()
    local list = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local lname = string.lower(obj.Name)
            if not EXCLUDE[lname] and not isCharacterPart(obj) then
                local hasTouch = obj:FindFirstChildOfClass("TouchInterest") ~= nil
                    or obj:FindFirstChild("TouchInterest") ~= nil
                local nameMatch = string.find(lname, "checkpoint") ~= nil
                    or string.find(lname, "stage") ~= nil
                if hasTouch or nameMatch then
                    table.insert(list, {part = obj, num = extractNumber(obj)})
                end
            end
        end
    end

    table.sort(list, function(a, b)
        if a.num and b.num then
            if a.num ~= b.num then return a.num < b.num end
            return a.part.Name < b.part.Name
        elseif a.num then
            return true
        elseif b.num then
            return false
        end
        return a.part.Name < b.part.Name
    end)

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
        local list = scanCheckpoints()
        if #list == 0 then
            setStatus("checkpoint tidak ditemukan")
            if myId == runId then
                enabled = false
                setToggleVisual()
            end
            return
        end

        setStatus("ditemukan " .. #list .. " checkpoint")

        for i, entry in ipairs(list) do
            if not enabled or myId ~= runId then
                return
            end

            local part = entry.part
            local root = getRoot()
            if root and part and part.Parent then
                root.CFrame = part.CFrame + Vector3.new(0, 3, 0)
                setStatus("TP " .. i .. "/" .. #list .. " : " .. part.Name)
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

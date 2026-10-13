-- Checkpoint TP | Delta Executor (client-side) | GUI + auto teleport

local DELAY       = 0.5      -- seconds between teleports
local HEIGHT      = 3        -- extra studs above the checkpoint
local START_FROM  = 1        -- skip numbers lower than this (0 = start plate usually)
local LOOP_AFTER  = false    -- true = restart from the first checkpoint after the last
local TOUCH_FIRE  = true     -- also fire Touched (needed by some checkpoints)

-- Custom folder? Add its name here (e.g. workspace.Map.Stages -> "Stages")
local FOLDER_NAMES = {"Checkpoints", "CheckPoints", "Stages", "Levels", "Obby", "Stage", "Spawns"}
-- Keywords used in the Workspace-wide fallback scan
local KEYWORDS = {"checkpoint", "stage", "level", "cp", "obby", "step"}

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local player = Players.LocalPlayer

getgenv().AutoTeleport = false

-- Remove old copy
if getgenv().CheckpointTPGui then pcall(function() getgenv().CheckpointTPGui:Destroy() end) end

----------------------------------------------------------------
-- Detection
----------------------------------------------------------------
local function numOf(name)
    local n = name:match("%d+")
    return n and tonumber(n) or nil
end

local function hasKeyword(lower)
    if lower:match("^%d+$") then return true end
    for _, kw in ipairs(KEYWORDS) do
        if lower:find(kw, 1, true) then return true end
    end
    return false
end

local function isCandidate(inst, inFolder)
    if not (inst:IsA("BasePart") or inst:IsA("Model")) then return false end
    if player.Character and inst:IsDescendantOf(player.Character) then return false end
    if not numOf(inst.Name) then return false end
    if inFolder then return true end
    return hasKeyword(inst.Name:lower())
end

local function scan(root, inFolder)
    local cands, set = {}, {}
    for _, inst in ipairs(root:GetDescendants()) do
        if isCandidate(inst, inFolder) then
            cands[#cands + 1] = inst
            set[inst] = true
        end
    end
    -- keep only top-most matches (drop parts inside a matched model)
    local out = {}
    for _, inst in ipairs(cands) do
        local p, nested = inst.Parent, false
        while p and p ~= root do
            if set[p] then nested = true break end
            p = p.Parent
        end
        if not nested then out[#out + 1] = inst end
    end
    return out
end

local function buildList()
    local raw = {}
    for _, fname in ipairs(FOLDER_NAMES) do
        for _, folder in ipairs(workspace:GetDescendants()) do
            if folder.Name == fname and (folder:IsA("Folder") or folder:IsA("Model")) then
                local r = scan(folder, true)
                if #r >= 2 then raw = r break end
            end
        end
        if #raw > 0 then break end
    end
    if #raw == 0 then raw = scan(workspace, false) end

    -- one checkpoint per number
    local byNum, nums = {}, {}
    for _, inst in ipairs(raw) do
        local n = numOf(inst.Name)
        if n >= START_FROM and not byNum[n] then
            byNum[n] = inst
            nums[#nums + 1] = n
        end
    end
    table.sort(nums)

    local list = {}
    for _, n in ipairs(nums) do list[#list + 1] = byNum[n] end
    return list
end

local function getPos(obj)
    if obj:IsA("BasePart") then
        return obj.CFrame + Vector3.new(0, obj.Size.Y / 2, 0), obj
    end
    local ok, cf = pcall(function() return obj:GetPivot() end)
    if not ok then return nil end
    local part = obj:FindFirstChildWhichIsA("BasePart", true)
    return cf, part
end

----------------------------------------------------------------
-- GUI
----------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "CheckpointTP"
gui.ResetOnSpawn = false
local okParent = pcall(function() gui.Parent = (gethui and gethui()) or CoreGui end)
if not okParent then gui.Parent = player:WaitForChild("PlayerGui") end
getgenv().CheckpointTPGui = gui

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 200, 0, 110)
frame.Position = UDim2.new(0.5, -100, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
frame.BorderSizePixel = 0
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
title.BorderSizePixel = 0
title.Text = "Checkpoint TP"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.TextSize = 14
Instance.new("UICorner", title).CornerRadius = UDim.new(0, 8)

local toggle = Instance.new("TextButton", frame)
toggle.Size = UDim2.new(1, -20, 0, 34)
toggle.Position = UDim2.new(0, 10, 0, 40)
toggle.BorderSizePixel = 0
toggle.Font = Enum.Font.GothamBold
toggle.TextSize = 14
toggle.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 6)

local status = Instance.new("TextLabel", frame)
status.Size = UDim2.new(1, -20, 0, 20)
status.Position = UDim2.new(0, 10, 0, 82)
status.BackgroundTransparency = 1
status.Text = "Idle"
status.TextColor3 = Color3.fromRGB(180, 180, 190)
status.Font = Enum.Font.Gotham
status.TextSize = 12

-- Dragging
do
    local dragging, dragStart, startPos
    title.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, i.Position, frame.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

----------------------------------------------------------------
-- Teleport loop
----------------------------------------------------------------
local runId = 0
local setState

local function getHRP()
    local char = player.Character or player.CharacterAdded:Wait()
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then
        player.CharacterAdded:Wait()
        task.wait(1)
        char = player.Character
    end
    return char and char:WaitForChild("HumanoidRootPart", 5)
end

local function start()
    runId += 1
    local id = runId

    task.spawn(function()
        local ok, err = pcall(function()
            local list = buildList()
            print("[CheckpointTP] Found " .. #list .. " checkpoints")
            for i, cp in ipairs(list) do print(("  %d. %s"):format(i, cp:GetFullName())) end

            if #list == 0 then
                status.Text = "None found (edit FOLDER_NAMES)"
                warn("[CheckpointTP] No checkpoints found")
                setState(false, true)
                return
            end

            repeat
                local i = 1
                while i <= #list do
                    if not getgenv().AutoTeleport or id ~= runId then return end

                    local cp = list[i]
                    local cf, part = nil, nil
                    if cp.Parent then cf, part = getPos(cp) end

                    if cf then
                        local hrp = getHRP()
                        if not hrp then task.wait(0.5) continue end
                        hrp.AssemblyLinearVelocity = Vector3.zero
                        hrp.CFrame = cf + Vector3.new(0, HEIGHT, 0)
                        if TOUCH_FIRE and part and firetouchinterface then
                            pcall(function()
                                firetouchinterface(hrp, part, 0)
                                firetouchinterface(hrp, part, 1)
                            end)
                        end
                        status.Text = ("%d/%d  %s"):format(i, #list, cp.Name)
                    end

                    i += 1
                    task.wait(DELAY)
                end
            until not (LOOP_AFTER and getgenv().AutoTeleport and id == runId)

            if id == runId then
                status.Text = "Finished (" .. #list .. ")"
                print("[CheckpointTP] Finished")
                setState(false, true)
            end
        end)
        if not ok then warn("[CheckpointTP] Error: " .. tostring(err)) end
    end)
end

setState = function(on, keepStatus)
    getgenv().AutoTeleport = on
    toggle.Text = on and "ON" or "OFF"
    toggle.BackgroundColor3 = on and Color3.fromRGB(46, 160, 67) or Color3.fromRGB(190, 60, 60)
    if on then
        start()
    else
        runId += 1
        if not keepStatus then status.Text = "Stopped" end
    end
end

toggle.MouseButton1Click:Connect(function()
    setState(not getgenv().AutoTeleport)
end)

setState(false, true)

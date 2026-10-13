-- Checkpoint TP | yoruka.id (Long AFK Streaming Probe)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local lp = Players.LocalPlayer

local GUI_NAME = "CheckpointTP_GUI"

local function getEnv()
    if getgenv then
        local ok, env = pcall(getgenv)
        if ok and env then return env end
    end
    return _G
end

-- Global token lets a re-execution stop the previous loop.
local env = getEnv()
env._CPTP_TOKEN = (env._CPTP_TOKEN or 0) + 1
local scriptToken = env._CPTP_TOKEN

-- Clean previous execution connections.
pcall(function()
    local e = getEnv()
    if e._CPTP_CONNS then
        for _, c in ipairs(e._CPTP_CONNS) do
            pcall(function() c:Disconnect() end)
        end
    end
    e._CPTP_CONNS = {}
end)

local function trackConn(conn)
    pcall(function()
        local e = getEnv()
        e._CPTP_CONNS = e._CPTP_CONNS or {}
        table.insert(e._CPTP_CONNS, conn)
    end)
    return conn
end

-- Persistent progress.
local lastReached = tonumber(env._CPTP_LAST_REACHED) or 0

local lastReachedCFrame = nil
if type(env._CPTP_LAST_CF) == "table" and #env._CPTP_LAST_CF == 3 then
    lastReachedCFrame = CFrame.new(
        env._CPTP_LAST_CF[1],
        env._CPTP_LAST_CF[2],
        env._CPTP_LAST_CF[3]
    )
end

local lastDirection = nil
if type(env._CPTP_LAST_DIR) == "table" and #env._CPTP_LAST_DIR == 3 then
    lastDirection = Vector3.new(
        env._CPTP_LAST_DIR[1],
        env._CPTP_LAST_DIR[2],
        env._CPTP_LAST_DIR[3]
    )
end

local lastSegmentLength = tonumber(env._CPTP_LAST_DIST) or nil

local function saveProgress()
    pcall(function()
        local e = getEnv()
        e._CPTP_LAST_REACHED = lastReached

        if lastReachedCFrame then
            e._CPTP_LAST_CF = {
                lastReachedCFrame.Position.X,
                lastReachedCFrame.Position.Y,
                lastReachedCFrame.Position.Z
            }
        else
            e._CPTP_LAST_CF = nil
        end

        if lastDirection and lastDirection.Magnitude > 0.1 then
            e._CPTP_LAST_DIR = {
                lastDirection.X,
                lastDirection.Y,
                lastDirection.Z
            }
        else
            e._CPTP_LAST_DIR = nil
        end

        e._CPTP_LAST_DIST = lastSegmentLength
    end)
end

local function getParent()
    if gethui then
        local ok, h = pcall(gethui)
        if ok and h then return h end
    end

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

pcall(function()
    local old = parentGui:FindFirstChild(GUI_NAME)
    if old then old:Destroy() end
end)

-- GUI
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

-- Drag
local dragging = false
local dragStart, startPos

title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end)

trackConn(UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end))

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

-- Checkpoint registry
local registry = {}
local objNumbers = {}
local registryConns = {}

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

-- Supports Checkpoint1, Checkpoint 1, Checkpoint_1, Checkpoint-1
local function getNumber(obj)
    if not (obj:IsA("BasePart") or obj:IsA("Model")) then return nil end
    local numStr = string.match(string.lower(obj.Name), "^checkpoint[%s_%-]*(%d+)$")
    if not numStr then return nil end
    return tonumber(numStr)
end

local function unregister(obj)
    local n = objNumbers[obj] or getNumber(obj)
    if n then
        local set = registry[n]
        if set then
            set[obj] = nil
            if next(set) == nil then
                registry[n] = nil
            end
        end
    end

    objNumbers[obj] = nil

    local conn = registryConns[obj]
    if conn then
        pcall(function() conn:Disconnect() end)
        registryConns[obj] = nil
    end
end

local register

local function attachNameWatcher(obj)
    if registryConns[obj] then return end

    local ok, conn = pcall(function()
        return obj:GetPropertyChangedSignal("Name"):Connect(function()
            unregister(obj)
            register(obj)
        end)
    end)

    if ok and conn then
        registryConns[obj] = conn
    end
end

register = function(obj)
    if not obj or not obj.Parent then return end

    if isCharacterObject(obj) then
        unregister(obj)
        return
    end

    local n = getNumber(obj)
    if not n then
        unregister(obj)
        return
    end

    if objNumbers[obj] == n and registry[n] and registry[n][obj] then
        attachNameWatcher(obj)
        return
    end

    unregister(obj)

    registry[n] = registry[n] or {}
    registry[n][obj] = true
    objNumbers[obj] = n
    attachNameWatcher(obj)
end

trackConn(workspace.DescendantAdded:Connect(function(obj)
    register(obj)
end))

trackConn(workspace.DescendantRemoving:Connect(function(obj)
    unregister(obj)
end))

local function scoreOf(obj)
    if obj:IsA("BasePart") then
        return hasTouch(obj) and 3 or 2
    end
    return 1
end

local function bestOf(n)
    local set = registry[n]
    if not set then return nil end

    local best, bestScore = nil, -1
    local stale = {}

    for obj in pairs(set) do
        if obj.Parent and getNumber(obj) == n and not isCharacterObject(obj) then
            local s = scoreOf(obj)
            if s > bestScore then
                best, bestScore = obj, s
            end
        else
            table.insert(stale, obj)
        end
    end

    for _, obj in ipairs(stale) do
        unregister(obj)
    end

    return best
end

local function smallestAbove(above)
    local result = nil
    for n, set in pairs(registry) do
        if n > above and next(set) ~= nil then
            if not result or n < result then
                result = n
            end
        end
    end
    return result
end

local function getObjectCFrame(obj)
    if obj:IsA("BasePart") then
        local ok, cf = pcall(function() return obj.CFrame end)
        if ok then return cf end
        return nil
    end

    if obj:IsA("Model") then
        local ok, pivot = pcall(function() return obj:GetPivot() end)
        if ok and pivot then return pivot end

        local part = obj:FindFirstChildWhichIsA("BasePart", true)
        if part then
            local okPart, cf = pcall(function() return part.CFrame end)
            if okPart then return cf end
        end
    end

    return nil
end

-- Teleport / AFK state
local enabled = false
local runId = 0

local GAP_RETRIES = 6
local PROBE_MISSING_DELAY = 2

local PROBE_MIN_DISTANCE = 250
local PROBE_MAX_DISTANCE = 1000
local PROBE_SCAN_WAIT = 0.5

local PROBE_VERTICAL_LIFT = 5
local PROBE_VERTICAL_LIFT_STEP = 5
local PROBE_ATTEMPT_DISTANCE_STEP = 25
local PROBE_ATTEMPT_CAP = 10

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

    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return nil end

    return char:FindFirstChild("HumanoidRootPart")
end

local function cleanupRegistry()
    local stale = {}

    for n, set in pairs(registry) do
        for obj in pairs(set) do
            if not obj.Parent or objNumbers[obj] ~= n or getNumber(obj) ~= n or isCharacterObject(obj) then
                table.insert(stale, obj)
            end
        end
    end

    for _, obj in ipairs(stale) do
        unregister(obj)
    end
end

local function fullRescan()
    cleanupRegistry()
    for _, obj in ipairs(workspace:GetDescendants()) do
        register(obj)
    end
end

local function requestStreaming()
    pcall(function() workspace:RequestQueueForPods() end)
    pcall(function() workspace:RequestStream() end)
    pcall(function() lp:RequestStream() end)
end

local function setRootAnchored(root, value)
    pcall(function() root.Anchored = value end)
end

local function setRootCFrame(root, cf)
    local ok = pcall(function() root.CFrame = cf end)
    return ok
end

local function setCameraCFrame(cf)
    local cam = workspace.CurrentCamera
    if cam and cf then
        pcall(function() cam.CFrame = cf end)
    end
end

local function clampNumber(v, minV, maxV)
    if v < minV then return minV end
    if v > maxV then return maxV end
    return v
end

local function teleportRootSafe(root, cf)
    setRootAnchored(root, true)

    if not setRootCFrame(root, cf) then
        return false
    end

    requestStreaming()
    task.wait(0.15)
    setRootAnchored(root, false)
    return true
end

local function getProbeDistances()
    local raw = {}

    if lastSegmentLength and lastSegmentLength > 10 then
        raw = {
            lastSegmentLength,
            lastSegmentLength * 1.25,
            lastSegmentLength * 1.6,
            lastSegmentLength * 2.1,
            PROBE_MAX_DISTANCE
        }
    else
        raw = {250, 500, 750, 1000}
    end

    local out = {}
    local last = 0

    for _, d in ipairs(raw) do
        d = clampNumber(d, PROBE_MIN_DISTANCE, PROBE_MAX_DISTANCE)
        d = math.floor(d)

        if d > last then
            table.insert(out, d)
            last = d
        end
    end

    if #out == 0 then
        table.insert(out, PROBE_MAX_DISTANCE)
    end

    return out
end

local function getLastSafeCFrame()
    if lastReached > 0 then
        local obj = bestOf(lastReached)
        if obj then
            local cf = getObjectCFrame(obj)
            if cf then return cf end
        end
    end

    if lastReachedCFrame then
        return lastReachedCFrame
    end

    local root = getRoot()
    if root then
        return root.CFrame
    end

    return CFrame.new(0, 0, 0)
end

local function getProbeDirection()
    if lastDirection and lastDirection.Magnitude > 0.1 then
        return lastDirection.Unit
    end

    local root = getRoot()
    if root then
        return root.CFrame.LookVector
    end

    local safe = getLastSafeCFrame()
    return safe.LookVector
end

local function updateProgress(newNum, newCFrame)
    if newCFrame then
        if lastReachedCFrame then
            local delta = newCFrame.Position - lastReachedCFrame.Position
            if delta.Magnitude > 1 then
                lastDirection = delta.Unit
                lastSegmentLength = delta.Magnitude
            else
                lastDirection = newCFrame.LookVector
            end
        else
            lastDirection = newCFrame.LookVector
        end

        lastReachedCFrame = newCFrame
    end

    lastReached = newNum
    saveProgress()
end

local function probeForCheckpoint(targetNum, attemptLevel)
    local root = getRoot()
    if not root then return nil, nil end

    attemptLevel = attemptLevel or 0
    local attemptCap = math.min(attemptLevel, PROBE_ATTEMPT_CAP)

    local returnCFrame = getLastSafeCFrame()
    local origin = getLastSafeCFrame()
    local dir = getProbeDirection()

    local oldCanCollide = true
    local okCanCollide, valCanCollide = pcall(function() return root.CanCollide end)
    if okCanCollide then oldCanCollide = valCanCollide end

    local oldCanTouch = true
    local okCanTouch, valCanTouch = pcall(function() return root.CanTouch end)
    if okCanTouch then oldCanTouch = valCanTouch end

    pcall(function() root.CanCollide = false end)
    pcall(function() root.CanTouch = false end)

    local distances = getProbeDistances()
    local foundObj, foundNum = nil, nil

    for i, baseDist in ipairs(distances) do
        if not enabled or getEnv()._CPTP_TOKEN ~= scriptToken then
            break
        end

        if not dir or dir.Magnitude < 0.1 then
            dir = Vector3.new(0, 0, -1)
        end
        dir = dir.Unit

        local dist = clampNumber(
            baseDist + (attemptCap * PROBE_ATTEMPT_DISTANCE_STEP),
            PROBE_MIN_DISTANCE,
            PROBE_MAX_DISTANCE
        )
        dist = math.floor(dist)

        local lift = PROBE_VERTICAL_LIFT
            + ((i - 1) * PROBE_VERTICAL_LIFT_STEP)
            + (attemptCap * PROBE_VERTICAL_LIFT_STEP)

        local pos = origin.Position + (dir * dist) + Vector3.new(0, lift, 0)
        local look = pos + (dir * 25)
        local probeCFrame = CFrame.new(pos, look)

        setRootAnchored(root, true)
        if not setRootCFrame(root, probeCFrame) then
            break
        end

        setCameraCFrame(probeCFrame)
        requestStreaming()
        setStatus("AFK probe " .. dist .. " studs...")

        task.wait(PROBE_SCAN_WAIT)

        if not enabled or getEnv()._CPTP_TOKEN ~= scriptToken then
            break
        end

        requestStreaming()
        fullRescan()

        local obj = bestOf(targetNum)
        if obj then
            local cf = getObjectCFrame(obj)
            if cf and enabled and getEnv()._CPTP_TOKEN == scriptToken then
                setRootAnchored(root, true)

                if setRootCFrame(root, cf + Vector3.new(0, 3, 0)) then
                    setCameraCFrame(cf + Vector3.new(0, 3, 0))
                    requestStreaming()
                    task.wait(0.15)

                    pcall(function() root.CanCollide = oldCanCollide end)
                    pcall(function() root.CanTouch = oldCanTouch end)

                    setRootAnchored(root, false)
                    foundObj, foundNum = obj, targetNum
                    break
                end
            end
        end
    end

    if foundObj then
        return foundObj, foundNum
    end

    -- Safe return to last validated checkpoint.
    setRootAnchored(root, true)
    setRootCFrame(root, returnCFrame + Vector3.new(0, 3, 0))
    setCameraCFrame(returnCFrame + Vector3.new(0, 3, 0))
    requestStreaming()

    local safeLoaded = false

    for _ = 1, 2 do
        task.wait(0.35)

        if not enabled or getEnv()._CPTP_TOKEN ~= scriptToken then
            break
        end

        requestStreaming()
        fullRescan()

        local lastObj = bestOf(lastReached)
        if lastObj then
            local cf = getObjectCFrame(lastObj)
            if cf then
                lastReachedCFrame = cf
                saveProgress()

                setRootAnchored(root, true)
                setRootCFrame(root, cf + Vector3.new(0, 3, 0))
                setCameraCFrame(cf + Vector3.new(0, 3, 0))
                requestStreaming()
                task.wait(0.15)

                safeLoaded = true
                break
            end
        end
    end

    pcall(function() root.CanCollide = oldCanCollide end)
    pcall(function() root.CanTouch = oldCanTouch end)

    if safeLoaded then
        setRootAnchored(root, false)
    else
        -- Stay anchored if the last checkpoint did not stream back in.
        setRootAnchored(root, true)
    end

    return nil, nil
end

local function detectCurrentCheckpoint()
    local root = getRoot()
    if not root then return 0 end

    local bestN = 0
    local bestDist = 20

    local nums = {}
    for n in pairs(registry) do
        table.insert(nums, n)
    end

    for _, n in ipairs(nums) do
        local obj = bestOf(n)
        if obj then
            local cf = getObjectCFrame(obj)
            if cf then
                local dist = (cf.Position - root.Position).Magnitude
                if dist <= bestDist then
                    bestDist = dist
                    bestN = n
                end
            end
        end
    end

    return bestN
end

local function startLoop()
    runId = runId + 1
    local myId = runId

    task.spawn(function()
        setStatus("scanning Checkpoint[angka]...")
        fullRescan()

        local detected = detectCurrentCheckpoint()
        if detected > lastReached then
            local obj = bestOf(detected)
            local cf = obj and getObjectCFrame(obj)
            if cf then
                updateProgress(detected, cf)
                setStatus("resume dari Checkpoint" .. lastReached)
            end
        elseif lastReached > 0 and not lastReachedCFrame then
            local obj = bestOf(lastReached)
            local cf = obj and getObjectCFrame(obj)
            if cf then
                lastReachedCFrame = cf
                if not lastDirection or lastDirection.Magnitude < 0.1 then
                    lastDirection = cf.LookVector
                end
                saveProgress()
            end
        end

        local misses = 0
        local missStart = nil

        -- Some games validate character movement server-side; this will trigger their anti-cheat.
        while enabled and myId == runId and getEnv()._CPTP_TOKEN == scriptToken do
            local nextNum = lastReached + 1
            local obj = bestOf(nextNum)

            if not obj and misses >= GAP_RETRIES then
                local higher = smallestAbove(lastReached)
                if higher then
                    nextNum = higher
                    obj = bestOf(higher)
                end
            end

            if obj then
                if not enabled or myId ~= runId or getEnv()._CPTP_TOKEN ~= scriptToken then
                    break
                end

                local root = getRoot()
                local cf = getObjectCFrame(obj)

                if root and cf and teleportRootSafe(root, cf + Vector3.new(0, 3, 0)) then
                    updateProgress(nextNum, cf)
                    misses = 0
                    missStart = nil
                    setStatus("TP Checkpoint" .. nextNum .. " (terakhir: " .. lastReached .. ")")
                    task.wait(0.35)
                else
                    setStatus("menunggu character/root... terakhir: Checkpoint" .. lastReached)
                    task.wait(0.25)
                end
            else
                if not missStart then
                    missStart = os.clock()
                end

                local missingFor = os.clock() - missStart

                if missingFor >= PROBE_MISSING_DELAY then
                    setStatus("checkpoint tidak ditemukan, AFK probe jauh...")

                    local foundObj, foundNum = probeForCheckpoint(nextNum, misses)

                    if not enabled or myId ~= runId or getEnv()._CPTP_TOKEN ~= scriptToken then
                        break
                    end

                    if foundObj then
                        local root = getRoot()
                        local cf = getObjectCFrame(foundObj)

                        if root and cf and teleportRootSafe(root, cf + Vector3.new(0, 3, 0)) then
                            updateProgress(foundNum or getNumber(foundObj) or nextNum, cf)
                            misses = 0
                            missStart = nil
                            setStatus("AFK menemukan Checkpoint" .. lastReached)
                            task.wait(0.35)
                        else
                            task.wait(0.25)
                        end
                    else
                        setStatus("probe gagal, balik ke checkpoint terakhir...")
                        task.wait(1)

                        misses = misses + 1
                        missStart = os.clock() - PROBE_MISSING_DELAY

                        fullRescan()
                        task.wait(0.1)
                    end
                else
                    setStatus("menunggu map load... terakhir: Checkpoint" .. lastReached)
                    fullRescan()
                    requestStreaming()
                    task.wait(0.5)
                end
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

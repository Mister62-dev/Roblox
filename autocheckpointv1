-- Auto Checkpoint Teleport | Delta Executor (client-side)

local DELAY = 0.5                     -- seconds between teleports (raise if you get rubberbanded)
local HEIGHT = 4                      -- studs above the checkpoint to land on
local LOOP_FOREVER = false            -- true = start over after the last checkpoint

-- If your checkpoints are in a custom folder, add its name here.
-- For a nested path, use workspace.Map.Stages and put "Stages" in the list.
local FOLDER_NAMES = {"Checkpoints", "CheckPoints", "Stages", "Obby", "Stage"}

getgenv().AutoTeleport = true         -- set to false at any time to stop

local Players = game:GetService("Players")
local player = Players.LocalPlayer

local function getNumber(name)
    local n = name:match("(%d+)")
    return n and tonumber(n) or nil
end

local function isValid(inst)
    return (inst:IsA("BasePart") or inst:IsA("Model")) and getNumber(inst.Name) ~= nil
end

local function collect()
    local found = {}

    -- 1) Look inside the known folders first
    for _, folderName in ipairs(FOLDER_NAMES) do
        local folder = workspace:FindFirstChild(folderName, true)
        if folder then
            for _, child in ipairs(folder:GetChildren()) do
                if isValid(child) then
                    table.insert(found, child)
                end
            end
            if #found > 0 then
                return found
            end
        end
    end

    -- 2) Fallback: scan all of Workspace for checkpoint-like names
    local matched = {}
    for _, inst in ipairs(workspace:GetDescendants()) do
        if isValid(inst) and not matched[inst.Parent] then
            local lower = inst.Name:lower()
            if lower:find("checkpoint") or lower:find("stage") or lower:match("^%d+$") then
                matched[inst] = true
                table.insert(found, inst)
            end
        end
    end
    return found
end

local function getCFrame(obj)
    if obj:IsA("BasePart") then
        return obj.CFrame
    end
    local ok, pivot = pcall(function() return obj:GetPivot() end)
    return ok and pivot or nil
end

local function run()
    local checkpoints = collect()

    table.sort(checkpoints, function(a, b)
        local na, nb = getNumber(a.Name), getNumber(b.Name)
        if na == nb then return a.Name < b.Name end
        return na < nb
    end)

    if #checkpoints == 0 then
        warn("[AutoTP] No checkpoints found. Edit FOLDER_NAMES at the top.")
        return
    end

    print("[AutoTP] Found " .. #checkpoints .. " checkpoints")

    repeat
        for _, cp in ipairs(checkpoints) do
            if not getgenv().AutoTeleport then
                print("[AutoTP] Stopped")
                return
            end

            local char = player.Character or player.CharacterAdded:Wait()
            local hrp = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 5)
            local cf = cp.Parent and getCFrame(cp)

            if hrp and cf then
                hrp.CFrame = cf + Vector3.new(0, HEIGHT, 0)
                print("[AutoTP] -> " .. cp.Name)
            end

            task.wait(DELAY)
        end
    until not (LOOP_FOREVER and getgenv().AutoTeleport)

    print("[AutoTP] Done")
end

task.spawn(run)

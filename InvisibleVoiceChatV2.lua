-- Invisible V2 | Heartbeat Loop | Delta Executor
-- Août 2026 | Réplique aux autres joueurs

local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local TweenService= game:GetService("TweenService")
local UIS         = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

if PlayerGui:FindFirstChild("InvisUI") then
    PlayerGui:FindFirstChild("InvisUI"):Destroy()
end

local invisible = false

-- ── HEARTBEAT — réapplique chaque frame ───────────────────────────────────────
RunService.Heartbeat:Connect(function()
    if not invisible then return end
    local char = LocalPlayer.Character
    if not char then return end

    for _, obj in ipairs(char:GetDescendants()) do
        -- Parts du corps
        if obj:IsA("BasePart") then
            if obj.Transparency ~= 1 then
                obj.Transparency = 1
            end
            if obj.CastShadow then
                obj.CastShadow = false
            end
        end

        -- Decals (shirt graphic, pants)
        if obj:IsA("Decal") then
            if obj.Transparency ~= 1 then
                obj.Transparency = 1
            end
        end

        -- Textures
        if obj:IsA("Texture") then
            if obj.Transparency ~= 1 then
                obj.Transparency = 1
            end
        end

        -- SpecialMesh face
        if obj:IsA("SpecialMesh") then
            -- pas de transparency sur mesh mais on cache le parent
        end
    end

    -- Cache aussi les outils en main
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then
        for _, p in ipairs(tool:GetDescendants()) do
            if p:IsA("BasePart") and p.Transparency ~= 1 then
                p.Transparency = 1
            end
        end
    end
end)

-- ── CACHE MICRO — loop continu ────────────────────────────────────────────────
local MIC_KEYS = {"voice","mic","speaker","talking","proximity","indicator"}

local function isMicUI(obj)
    local n = obj.Name:lower()
    for _, k in ipairs(MIC_KEYS) do
        if n:find(k) then return true end
    end
    return false
end

RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    for _, obj in ipairs(char:GetDescendants()) do
        if obj:IsA("BillboardGui") and isMicUI(obj) then
            if obj.Enabled then obj.Enabled = false end
            if obj.Size ~= UDim2.new(0,0,0,0) then
                obj.Size = UDim2.new(0,0,0,0)
            end
        end
    end
end)

-- Réapplique après respawn
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
end)

-- ── GUI ───────────────────────────────────────────────────────────────────────
local Gui = Instance.new("ScreenGui", PlayerGui)
Gui.Name           = "InvisUI"
Gui.ResetOnSpawn   = false
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local Main = Instance.new("Frame", Gui)
Main.Size             = UDim2.new(0, 220, 0, 105)
Main.Position         = UDim2.new(0.5, -110, 0, 20)
Main.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
Main.BorderSizePixel  = 0
Main.Active           = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
local mainStroke = Instance.new("UIStroke", Main)
mainStroke.Color = Color3.fromRGB(38, 38, 58); mainStroke.Thickness = 1.5

local Title = Instance.new("TextLabel", Main)
Title.Size                   = UDim2.new(1, -10, 0, 20)
Title.Position               = UDim2.new(0, 10, 0, 8)
Title.BackgroundTransparency = 1
Title.Text                   = "👻  INVISIBLE + VOIX"
Title.TextColor3             = Color3.fromRGB(220, 220, 220)
Title.TextSize               = 12
Title.Font                   = Enum.Font.GothamBold
Title.TextXAlignment         = Enum.TextXAlignment.Left

local SubInvis = Instance.new("TextLabel", Main)
SubInvis.Size                   = UDim2.new(1, -10, 0, 13)
SubInvis.Position               = UDim2.new(0, 10, 0, 30)
SubInvis.BackgroundTransparency = 1
SubInvis.Text                   = "● Invisible : OFF"
SubInvis.TextColor3             = Color3.fromRGB(110, 110, 130)
SubInvis.TextSize               = 10
SubInvis.Font                   = Enum.Font.Gotham
SubInvis.TextXAlignment         = Enum.TextXAlignment.Left

local SubMic = Instance.new("TextLabel", Main)
SubMic.Size                   = UDim2.new(1, -10, 0, 13)
SubMic.Position               = UDim2.new(0, 10, 0, 44)
SubMic.BackgroundTransparency = 1
SubMic.Text                   = "● Micro caché : ACTIF"
SubMic.TextColor3             = Color3.fromRGB(80, 200, 120)
SubMic.TextSize               = 10
SubMic.Font                   = Enum.Font.Gotham
SubMic.TextXAlignment         = Enum.TextXAlignment.Left

local SubVoice = Instance.new("TextLabel", Main)
SubVoice.Size                   = UDim2.new(1, -10, 0, 13)
SubVoice.Position               = UDim2.new(0, 10, 0, 58)
SubVoice.BackgroundTransparency = 1
SubVoice.Text                   = "● Voix proximité : INTACTE"
SubVoice.TextColor3             = Color3.fromRGB(80, 200, 120)
SubVoice.TextSize               = 10
SubVoice.Font                   = Enum.Font.Gotham
SubVoice.TextXAlignment         = Enum.TextXAlignment.Left

-- Toggle pill
local Pill = Instance.new("Frame", Main)
Pill.Size             = UDim2.new(0, 54, 0, 26)
Pill.Position         = UDim2.new(1, -64, 0, 68)
Pill.BackgroundColor3 = Color3.fromRGB(38, 38, 52)
Pill.BorderSizePixel  = 0
Instance.new("UICorner", Pill).CornerRadius = UDim.new(1, 0)

local Knob = Instance.new("Frame", Pill)
Knob.Size             = UDim2.new(0, 20, 0, 20)
Knob.Position         = UDim2.new(0, 3, 0.5, -10)
Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Knob.BorderSizePixel  = 0
Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

-- Drag
do
    local drag, startI, startP = false
    Main.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then
            drag=true startI=i.Position startP=Main.Position
        end
    end)
    Main.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then drag=false end
    end)
    UIS.InputChanged:Connect(function(i)
        if drag and(i.UserInputType==Enum.UserInputType.MouseMovement
        or i.UserInputType==Enum.UserInputType.Touch) then
            local d=i.Position-startI
            Main.Position=UDim2.new(startP.X.Scale,startP.X.Offset+d.X,
                startP.Y.Scale,startP.Y.Offset+d.Y)
        end
    end)
end

local Hit = Instance.new("TextButton", Main)
Hit.Size               = UDim2.new(0, 54, 0, 26)
Hit.Position           = UDim2.new(1, -64, 0, 68)
Hit.BackgroundTransparency = 1
Hit.Text               = ""

Hit.MouseButton1Click:Connect(function()
    invisible = not invisible

    -- Reset visibilité quand OFF
    if not invisible then
        local char = LocalPlayer.Character
        if char then
            for _, obj in ipairs(char:GetDescendants()) do
                if obj:IsA("BasePart") then
                    obj.Transparency = 0
                    obj.CastShadow   = true
                end
                if obj:IsA("Decal") or obj:IsA("Texture") then
                    obj.Transparency = 0
                end
            end
        end
    end

    TweenService:Create(Pill, TweenInfo.new(0.15), {
        BackgroundColor3 = invisible
            and Color3.fromRGB(80, 200, 120)
            or  Color3.fromRGB(38, 38, 52)
    }):Play()
    TweenService:Create(Knob, TweenInfo.new(0.15), {
        Position = invisible
            and UDim2.new(1, -23, 0.5, -10)
            or  UDim2.new(0, 3,   0.5, -10)
    }):Play()

    SubInvis.Text       = "● Invisible : " .. (invisible and "ON" or "OFF")
    SubInvis.TextColor3 = invisible
        and Color3.fromRGB(80, 200, 120)
        or  Color3.fromRGB(110, 110, 130)
end)

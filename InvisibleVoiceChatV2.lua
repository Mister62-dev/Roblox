-- Invisible V3 | IY-Style | Delta Executor
-- Réplique aux autres joueurs — vêtements détruits côté serveur

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS          = game:GetService("UserInputService")
local LocalPlayer  = Players.LocalPlayer
local PlayerGui    = LocalPlayer:WaitForChild("PlayerGui")

if PlayerGui:FindFirstChild("InvisUI") then
    PlayerGui:FindFirstChild("InvisUI"):Destroy()
end

local invisible = false

-- ── APPLY INVIS — réplique au serveur ────────────────────────────────────────
local function applyInvis(char)
    if not char then return end

    -- 1. Tous les BaseParts → transparent (réplique via network ownership)
    for _, obj in ipairs(char:GetDescendants()) do
        if obj:IsA("BasePart") then
            obj.Transparency = 1
            obj.CastShadow   = false
        end
        if obj:IsA("Decal") or obj:IsA("Texture") then
            obj.Transparency = 1
        end
    end

    -- 2. Destroy Shirt / Pants / ShirtGraphic — réplique au serveur
    for _, obj in ipairs(char:GetChildren()) do
        if obj:IsA("Shirt") or obj:IsA("Pants") or obj:IsA("ShirtGraphic") then
            obj:Destroy()
        end
    end

    -- 3. Accessoires — rend le Handle invisible
    for _, obj in ipairs(char:GetChildren()) do
        if obj:IsA("Accessory") then
            local handle = obj:FindFirstChildOfClass("MeshPart")
                        or obj:FindFirstChildOfClass("Part")
                        or obj:FindFirstChild("Handle")
            if handle then
                handle.Transparency = 1
                handle.CastShadow   = false
            end
        end
    end

    -- 4. SurfaceAppearances (cheveux R15)
    for _, obj in ipairs(char:GetDescendants()) do
        if obj:IsA("SurfaceAppearance") then
            pcall(function()
                obj.Parent.Transparency = 1
            end)
        end
    end
end

-- ── APPLY VISIBLE ─────────────────────────────────────────────────────────────
local function applyVisible(char)
    if not char then return end
    for _, obj in ipairs(char:GetDescendants()) do
        if obj:IsA("BasePart") then
            obj.Transparency = obj.Name == "HumanoidRootPart" and 1 or 0
            obj.CastShadow   = obj.Name ~= "HumanoidRootPart"
        end
        if obj:IsA("Decal") or obj:IsA("Texture") then
            obj.Transparency = 0
        end
    end
end

-- ── HEARTBEAT — maintien chaque frame ────────────────────────────────────────
RunService.Heartbeat:Connect(function()
    if not invisible then return end
    local char = LocalPlayer.Character
    if not char then return end
    for _, obj in ipairs(char:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Transparency ~= 1 then
            obj.Transparency = 1
            obj.CastShadow   = false
        end
        if (obj:IsA("Decal") or obj:IsA("Texture")) and obj.Transparency ~= 1 then
            obj.Transparency = 1
        end
        -- Kill vêtements qui réapparaissent
        if obj:IsA("Shirt") or obj:IsA("Pants") or obj:IsA("ShirtGraphic") then
            pcall(function() obj:Destroy() end)
        end
    end
end)

-- ── CACHE MICRO (côté local) ─────────────────────────────────────────────────
local MIC_KEYS = {
    "voice","mic","speaker","talking","proximity",
    "indicator","voicechat","vchat","muted","unmuted"
}

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
    -- Cache les BillboardGui micro sur le personnage
    for _, obj in ipairs(char:GetDescendants()) do
        if obj:IsA("BillboardGui") and isMicUI(obj) then
            obj.Enabled = false
            obj.Size    = UDim2.new(0, 0, 0, 0)
        end
    end
    -- Cache aussi dans PlayerGui (overlay vocal Roblox)
    for _, obj in ipairs(PlayerGui:GetDescendants()) do
        if isMicUI(obj) then
            if obj:IsA("BillboardGui") then
                obj.Enabled = false
            end
            if obj:IsA("Frame") or obj:IsA("ImageLabel") then
                obj.Visible = false
            end
        end
    end
end)

-- ── RESPAWN ───────────────────────────────────────────────────────────────────
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.8)
    if invisible then applyInvis(char) end
end)

-- ── GUI ───────────────────────────────────────────────────────────────────────
local Gui = Instance.new("ScreenGui", PlayerGui)
Gui.Name           = "InvisUI"
Gui.ResetOnSpawn   = false
Gui.IgnoreGuiInset = true
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local Main = Instance.new("Frame", Gui)
Main.Size             = UDim2.new(0, 230, 0, 116)
Main.Position         = UDim2.new(0.5, -115, 0, 24)
Main.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
Main.BorderSizePixel  = 0
Main.Active           = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
local mStroke = Instance.new("UIStroke", Main)
mStroke.Color = Color3.fromRGB(38, 38, 58); mStroke.Thickness = 1.5

local function MkLabel(parent, txt, col, yOff)
    local L = Instance.new("TextLabel", parent)
    L.Size                   = UDim2.new(1, -10, 0, 13)
    L.Position               = UDim2.new(0, 10, 0, yOff)
    L.BackgroundTransparency = 1
    L.Text                   = txt
    L.TextColor3             = col
    L.TextSize               = 10
    L.Font                   = Enum.Font.Gotham
    L.TextXAlignment         = Enum.TextXAlignment.Left
    return L
end

local Title = Instance.new("TextLabel", Main)
Title.Size                   = UDim2.new(1, -10, 0, 20)
Title.Position               = UDim2.new(0, 10, 0, 8)
Title.BackgroundTransparency = 1
Title.Text                   = "👻  INVISIBLE + VOIX V3"
Title.TextColor3             = Color3.fromRGB(220, 220, 220)
Title.TextSize               = 12
Title.Font                   = Enum.Font.GothamBold
Title.TextXAlignment         = Enum.TextXAlignment.Left

local green = Color3.fromRGB(80, 200, 120)
local grey  = Color3.fromRGB(110, 110, 130)

local SubInvis = MkLabel(Main, "● Invisible : OFF",          grey,  32)
                 MkLabel(Main, "● Vêtements supprimés : OUI", green, 46)
                 MkLabel(Main, "● Micro caché : ACTIF",       green, 60)
                 MkLabel(Main, "● Voix proximité : INTACTE",  green, 74)

-- Toggle pill
local Pill = Instance.new("Frame", Main)
Pill.Size             = UDim2.new(0, 54, 0, 26)
Pill.Position         = UDim2.new(1, -64, 0, 80)
Pill.BackgroundColor3 = Color3.fromRGB(38, 38, 52)
Pill.BorderSizePixel  = 0
Instance.new("UICorner", Pill).CornerRadius = UDim.new(1, 0)

local Knob = Instance.new("Frame", Pill)
Knob.Size             = UDim2.new(0, 20, 0, 20)
Knob.Position         = UDim2.new(0, 3, 0.5, -10)
Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Knob.BorderSizePixel  = 0
Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

local Hit = Instance.new("TextButton", Main)
Hit.Size                   = UDim2.new(0, 54, 0, 26)
Hit.Position               = UDim2.new(1, -64, 0, 80)
Hit.BackgroundTransparency = 1
Hit.Text                   = ""

Hit.MouseButton1Click:Connect(function()
    invisible = not invisible
    local char = LocalPlayer.Character
    if invisible then applyInvis(char) else applyVisible(char) end

    TweenService:Create(Pill, TweenInfo.new(0.15), {
        BackgroundColor3 = invisible and green or Color3.fromRGB(38, 38, 52)
    }):Play()
    TweenService:Create(Knob, TweenInfo.new(0.15), {
        Position = invisible
            and UDim2.new(1, -23, 0.5, -10)
            or  UDim2.new(0,  3,  0.5, -10)
    }):Play()

    SubInvis.Text       = "● Invisible : " .. (invisible and "ON" or "OFF")
    SubInvis.TextColor3 = invisible and green or grey
end)

-- Drag
do
    local drag, startI, startP = false, nil, nil
    Main.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            drag=true; startI=i.Position; startP=Main.Position
        end
    end)
    Main.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then drag=false end
    end)
    UIS.InputChanged:Connect(function(i)
        if drag and (i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - startI
            Main.Position = UDim2.new(
                startP.X.Scale, startP.X.Offset + d.X,
                startP.Y.Scale, startP.Y.Offset + d.Y)
        end
    end)
end

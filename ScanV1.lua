local Players = game:GetService("Players")
local player = Players.LocalPlayer

local results = {}

task.spawn(function()
    for _, v in ipairs(game:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            table.insert(results, v.ClassName .. "|" .. v:GetFullName())
        end
        task.wait()
    end

    -- Affiche dans un TextBox copiable
    local gui = Instance.new("ScreenGui")
    gui.Name = "ScanUI"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 999
    gui.Parent = player.PlayerGui

    local frame = Instance.new("ScrollingFrame")
    frame.Size = UDim2.new(0.9, 0, 0.8, 0)
    frame.Position = UDim2.new(0.05, 0, 0.1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    frame.BorderSizePixel = 0
    frame.ScrollBarThickness = 6
    frame.Parent = gui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(1, -10, 0, math.max(500, #results * 22))
    textBox.Position = UDim2.new(0, 5, 0, 5)
    textBox.BackgroundTransparency = 1
    textBox.TextColor3 = Color3.fromRGB(180, 220, 180)
    textBox.TextSize = 11
    textBox.Font = Enum.Font.Code
    textBox.TextXAlignment = Enum.TextXAlignment.Left
    textBox.TextYAlignment = Enum.TextYAlignment.Top
    textBox.MultiLine = true
    textBox.ClearTextOnFocus = false
    textBox.Text = table.concat(results, "\n")
    textBox.Parent = frame

    frame.CanvasSize = UDim2.new(0, 0, 0, textBox.Size.Y.Offset + 10)

    -- Bouton fermer
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 80, 0, 35)
    closeBtn.Position = UDim2.new(0.5, -40, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Text = "Fermer"
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 12
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = gui
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
    closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

    warn("Scan termine : " .. #results .. " remotes")
end)

warn("Scan en cours...")

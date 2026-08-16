local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- UI d'abord
local gui = Instance.new("ScreenGui")
gui.Name = "ScanUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.Parent = player.PlayerGui

local bg = Instance.new("Frame")
bg.Size = UDim2.new(0.9, 0, 0.85, 0)
bg.Position = UDim2.new(0.05, 0, 0.08, 0)
bg.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
bg.BorderSizePixel = 0
bg.Parent = gui
Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 10)

local progressLabel = Instance.new("TextLabel")
progressLabel.Size = UDim2.new(1, 0, 0, 30)
progressLabel.Position = UDim2.new(0, 0, 0, 0)
progressLabel.BackgroundTransparency = 1
progressLabel.Text = "Scan : 0%"
progressLabel.TextColor3 = Color3.fromRGB(100, 220, 130)
progressLabel.TextSize = 13
progressLabel.Font = Enum.Font.GothamBold
progressLabel.Parent = bg

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, 0, 1, -70)
scrollFrame.Position = UDim2.new(0, 0, 0, 35)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 6
scrollFrame.Parent = bg

local textBox = Instance.new("TextBox")
textBox.Size = UDim2.new(1, -10, 0, 500)
textBox.Position = UDim2.new(0, 5, 0, 5)
textBox.BackgroundTransparency = 1
textBox.TextColor3 = Color3.fromRGB(180, 220, 180)
textBox.TextSize = 10
textBox.Font = Enum.Font.Code
textBox.TextXAlignment = Enum.TextXAlignment.Left
textBox.TextYAlignment = Enum.TextYAlignment.Top
textBox.MultiLine = true
textBox.ClearTextOnFocus = false
textBox.Text = "Scan en cours..."
textBox.Parent = scrollFrame

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 80, 0, 30)
closeBtn.Position = UDim2.new(0.5, -40, 1, -35)
closeBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Text = "Fermer"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 12
closeBtn.BorderSizePixel = 0
closeBtn.Parent = bg
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
closeBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

-- Scan
task.spawn(function()
    local results = {}
    local all = game:GetDescendants()
    local total = #all

    for i, v in ipairs(all) do
        pcall(function()
            if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                table.insert(results, v.ClassName .. " | " .. v:GetFullName())
            end
        end)
        -- Update % toutes les 100 items
        if i % 100 == 0 then
            local pct = math.floor(i / total * 100)
            progressLabel.Text = "Scan : " .. pct .. "% (" .. i .. "/" .. total .. ")"
            task.wait()
        end
    end

    local text = table.concat(results, "\n")
    textBox.Text = text == "" and "Aucune remote trouvée" or text
    textBox.Size = UDim2.new(1, -10, 0, math.max(500, #results * 20))
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, textBox.Size.Y.Offset + 10)
    progressLabel.Text = "Scan termine : " .. #results .. " remotes"
    progressLabel.TextColor3 = Color3.fromRGB(100, 180, 255)
end)

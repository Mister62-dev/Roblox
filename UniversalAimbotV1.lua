--[[
    Generic Lua Game Hack Architecture
    Assumes engine exposes: GetPlayers(), GetLocalPlayer(), GetCamera(), 
    WorldToScreen(), Raycast(), and basic Draw primitives (DrawRect, DrawText, DrawLine).
    Adapt API calls to your specific game engine (Roblox, Garry's Mod, custom C++ LuaJIT, etc.).
]]

local Config = {
    Aimbot = {
        Enabled = true,
        TeamCheck = true,
        WallCheck = true,
        AliveCheck = true,
        FOV = 150,
        Smoothness = 0.15,
        ActivationKey = "MouseButton2"
    },
    ESP = {
        Enabled = true,
        TeamCheck = true,
        DrawBox = true,
        DrawName = true,
        DrawHealth = true
    },
    UI = {
        Visible = true,
        ToggleKey = "Insert",
        X = 50,
        Y = 50,
        Width = 200,
        Height = 180
    }
}

local Engine = {
    GetPlayers = function() return GameAPI.GetPlayers() end,
    GetLocal = function() return GameAPI.GetLocalPlayer() end,
    GetCamera = function() return GameAPI.GetCamera() end,
    WorldToScreen = function(pos) return GameAPI.WorldToScreen(pos) end,
    Raycast = function(origin, direction) return GameAPI.Raycast(origin, direction) end,
    IsKeyDown = function(key) return InputAPI.IsKeyDown(key) end,
    DrawRect = function(x, y, w, h, color) DrawAPI.Rect(x, y, w, h, color) end,
    DrawText = function(text, x, y, color, size) DrawAPI.Text(text, x, y, color, size) end,
    DrawLine = function(x1, y1, x2, y2, color) DrawAPI.Line(x1, y1, x2, y2, color) end
}

local Colors = {
    Background = {r=20, g=20, b=25, a=220},
    Accent = {r=255, g=80, b=120, a=255},
    Text = {r=240, g=240, b=240, a=255},
    ESP_Ally = {r=80, g=200, b=255, a=255},
    ESP_Enemy = {r=255, g=80, b=80, a=255},
    FOV_Circle = {r=255, g=255, b=255, a=100}
}

local function IsValidTarget(target)
    local localPlayer = Engine.GetLocal()
    if not target or target == localPlayer then return false end
    
    if Config.Aimbot.AliveCheck and (not target.IsAlive or target.Health <= 0) then
        return false
    end
    
    if Config.Aimbot.TeamCheck and target.TeamID == localPlayer.TeamID then
        return false
    end
    
    if Config.Aimbot.WallCheck then
        local cam = Engine.GetCamera()
        local ray = Engine.Raycast(cam.Position, target.Head.Position - cam.Position)
        if ray and ray.Hit and ray.Instance ~= target then
            return false
        end
    end
    
    return true
end

local function GetClosestTarget()
    local closest = nil
    local minDist = Config.Aimbot.FOV
    local cam = Engine.GetCamera()
    local screenCenter = {x = Screen.Width / 2, y = Screen.Height / 2}
    
    for _, player in ipairs(Engine.GetPlayers()) do
        if IsValidTarget(player) then
            local screenPos, onScreen = Engine.WorldToScreen(player.Head.Position)
            if onScreen then
                local dx = screenPos.x - screenCenter.x
                local dy = screenPos.y - screenCenter.y
                local dist = math.sqrt(dx*dx + dy*dy)
                
                if dist < minDist then
                    minDist = dist
                    closest = player
                end
            end
        end
    end
    return closest
end

local function RunAimbot()
    if not Config.Aimbot.Enabled then return end
    if not Engine.IsKeyDown(Config.Aimbot.ActivationKey) then return end
    
    local target = GetClosestTarget()
    if not target then return end
    
    local cam = Engine.GetCamera()
    local targetPos = target.Head.Position
    local currentAngle = cam.Rotation
    local targetAngle = math.atan2(targetPos.y - cam.Position.y, targetPos.x - cam.Position.x)
    
    -- Smooth aim interpolation
    local delta = targetAngle - currentAngle
    cam.Rotation = currentAngle + (delta * Config.Aimbot.Smoothness)
end

local function RenderESP()
    if not Config.ESP.Enabled then return end
    
    for _, player in ipairs(Engine.GetPlayers()) do
        if player ~= Engine.GetLocal() and player.IsAlive then
            local isAlly = player.TeamID == Engine.GetLocal().TeamID
            if not Config.ESP.TeamCheck or not isAlly then
                local screenPos, onScreen = Engine.WorldToScreen(player.Head.Position)
                if onScreen then
                    local color = isAlly and Colors.ESP_Ally or Colors.ESP_Enemy
                    local boxHeight = 100 -- Scaled based on distance in real implementation
                    local boxWidth = boxHeight / 2
                    
                    if Config.ESP.DrawBox then
                        Engine.DrawRect(screenPos.x - boxWidth/2, screenPos.y - boxHeight, boxWidth, boxHeight, color)
                    end
                    if Config.ESP.DrawName then
                        Engine.DrawText(player.Name, screenPos.x - 20, screenPos.y - boxHeight - 15, Colors.Text, 12)
                    end
                    if Config.ESP.DrawHealth then
                        Engine.DrawText(math.floor(player.Health) .. " HP", screenPos.x - 15, screenPos.y + 5, Colors.Text, 10)
                    end
                end
            end
        end
    end
end

local function RenderUI()
    if Engine.IsKeyDown(Config.UI.ToggleKey) then
        Config.UI.Visible = not Config.UI.Visible
        Wait(0.2) -- Debounce
    end
    
    if not Config.UI.Visible then return end
    
    local x, y, w, h = Config.UI.X, Config.UI.Y, Config.UI.Width, Config.UI.Height
    
    -- Draw Menu Background
    Engine.DrawRect(x, y, w, h, Colors.Background)
    Engine.DrawRect(x, y, w, 25, Colors.Accent)
    Engine.DrawText("PHANTOM v1099", x + 10, y + 5, Colors.Text, 14)
    
    -- Draw Toggles (Simplified representation)
    local yOffset = 40
    Engine.DrawText("[X] Aimbot (Hold RMB)", x + 10, y + yOffset, Colors.Text, 12)
    Engine.DrawText("[X] ESP", x + 10, y + yOffset + 20, Colors.Text, 12)
    Engine.DrawText("[X] Wall Check", x + 10, y + yOffset + 40, Colors.Text, 12)
    Engine.DrawText("[X] Team Check", x + 10, y + yOffset + 60, Colors.Text, 12)
    Engine.DrawText("FOV: " .. Config.Aimbot.FOV, x + 10, y + yOffset + 80, Colors.Text, 12)
    Engine.DrawText("Smooth: " .. Config.Aimbot.Smoothness, x + 10, y + yOffset + 100, Colors.Text, 12)
end

local function RenderFOV()
    if Config.Aimbot.Enabled and Config.Aimbot.FOV > 0 then
        local cx, cy = Screen.Width / 2, Screen.Height / 2
        -- Engine specific circle drawing required here
        -- DrawCircle(cx, cy, Config.Aimbot.FOV, Colors.FOV_Circle)
    end
end

-- Main Execution Loop (Hook into engine's Render/Update tick)
function OnRenderTick()
    RenderUI()
    RenderFOV()
    RenderESP()
    RunAimbot()
end

-- Register the hook
Engine.RegisterHook("Render", OnRenderTick)

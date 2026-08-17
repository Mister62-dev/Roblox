-- Roblox Game Scanner | Mobile Edition
-- Delta Executor | Août 2026
-- Optimisé téléphone — drag tactile — compact

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS          = game:GetService("UserInputService")
local LocalPlayer  = Players.LocalPlayer
local PlayerGui    = LocalPlayer:WaitForChild("PlayerGui")

if PlayerGui:FindFirstChild("ScannerUI") then
    PlayerGui:FindFirstChild("ScannerUI"):Destroy()
end

local C = {
    BG        = Color3.fromRGB(12, 12, 18),
    Panel     = Color3.fromRGB(20, 20, 32),
    Accent    = Color3.fromRGB(80, 200, 120),
    AccentDk  = Color3.fromRGB(40, 110, 65),
    Red       = Color3.fromRGB(210, 55, 55),
    Text      = Color3.fromRGB(220, 220, 220),
    Dim       = Color3.fromRGB(110, 110, 130),
    Border    = Color3.fromRGB(38, 38, 58),
    LogBG     = Color3.fromRGB(8, 8, 14),
    TgOff     = Color3.fromRGB(38, 38, 52),
    TgOn      = Color3.fromRGB(80, 200, 120),
}

local function make(cls, props, parent)
    local o = Instance.new(cls)
    for k,v in pairs(props) do o[k]=v end
    if parent then o.Parent = parent end
    return o
end
local function corner(r,p) return make("UICorner",{CornerRadius=UDim.new(0,r)},p) end
local function stroke(t,c,p) return make("UIStroke",{Thickness=t,Color=c},p) end
local function tw(o,pr,t) TweenService:Create(o,TweenInfo.new(t or .15,Enum.EasingStyle.Quad),pr):Play() end

-- ══ ROOT ══
local Gui = make("ScreenGui",{
    Name="ScannerUI", ResetOnSpawn=false,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
},PlayerGui)

-- ══ MAIN — taille mobile ══
local W, H = 310, 480
local Main = make("Frame",{
    Size=UDim2.new(0,W,0,H),
    Position=UDim2.new(0.5,-W/2,0.5,-H/2),
    BackgroundColor3=C.BG, BorderSizePixel=0,
},Gui)
corner(10,Main) stroke(1.5,C.Border,Main)

-- ══ TITLEBAR ══
local TB = make("Frame",{
    Size=UDim2.new(1,0,0,40),
    BackgroundColor3=C.Panel, BorderSizePixel=0,
},Main)
corner(10,TB)
make("Frame",{Size=UDim2.new(1,0,0,10),Position=UDim2.new(0,0,1,-10),
    BackgroundColor3=C.Panel,BorderSizePixel=0},TB)

-- Dot
local dot = make("Frame",{Size=UDim2.new(0,7,0,7),
    Position=UDim2.new(0,12,0.5,-3.5),
    BackgroundColor3=C.Accent,BorderSizePixel=0},TB)
corner(4,dot)

make("TextLabel",{Size=UDim2.new(1,-70,0,20),Position=UDim2.new(0,24,0,5),
    BackgroundTransparency=1,Text="GAME SCANNER",
    TextColor3=C.Text,TextSize=12,Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Left},TB)
make("TextLabel",{Size=UDim2.new(1,-70,0,14),Position=UDim2.new(0,24,0,22),
    BackgroundTransparency=1,Text="DELTA READY",
    TextColor3=C.Accent,TextSize=9,Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Left},TB)

local CloseBtn = make("TextButton",{
    Size=UDim2.new(0,26,0,26),Position=UDim2.new(1,-32,0.5,-13),
    BackgroundColor3=C.Red,Text="✕",TextColor3=Color3.new(1,1,1),
    TextSize=11,Font=Enum.Font.GothamBold,BorderSizePixel=0},TB)
corner(6,CloseBtn)
CloseBtn.MouseButton1Click:Connect(function()
    tw(Main,{Position=UDim2.new(0.5,-W/2,1.5,0)},.25)
    task.wait(.3) Gui:Destroy()
end)

-- ══ DRAG TACTILE + SOURIS ══
do
    local drag=false
    local startInput, startPos

    local function beginDrag(pos)
        drag=true
        startInput=pos
        startPos=Main.Position
    end
    local function moveDrag(pos)
        if not drag then return end
        local d = pos - startInput
        Main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset+d.X,
            startPos.Y.Scale, startPos.Y.Offset+d.Y)
    end
    local function endDrag() drag=false end

    TB.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            beginDrag(i.Position)
        elseif i.UserInputType==Enum.UserInputType.Touch then
            beginDrag(i.Position)
        end
    end)
    TB.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then
            endDrag()
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseMovement then
            moveDrag(i.Position)
        elseif i.UserInputType==Enum.UserInputType.Touch then
            moveDrag(i.Position)
        end
    end)
end

-- ══ BODY ══
local Body = make("Frame",{
    Size=UDim2.new(1,-16,1,-48),
    Position=UDim2.new(0,8,0,44),
    BackgroundTransparency=1},Main)

local function secLabel(txt,y,p)
    make("TextLabel",{Size=UDim2.new(1,0,0,14),Position=UDim2.new(0,0,0,y),
        BackgroundTransparency=1,Text="— "..txt,TextColor3=C.Dim,
        TextSize=9,Font=Enum.Font.GothamBold,
        TextXAlignment=Enum.TextXAlignment.Left},p)
end

-- ══ TOGGLES ══
local Toggles={}
local function makeTog(lbl,key,x,y,p,def)
    def = def~=false
    Toggles[key]=def
    local row=make("Frame",{Size=UDim2.new(0,136,0,28),
        Position=UDim2.new(0,x,0,y),
        BackgroundColor3=C.Panel,BorderSizePixel=0},p)
    corner(7,row) stroke(1,C.Border,row)
    make("TextLabel",{Size=UDim2.new(1,-42,1,0),Position=UDim2.new(0,8,0,0),
        BackgroundTransparency=1,Text=lbl,TextColor3=C.Text,
        TextSize=10,Font=Enum.Font.Gotham,
        TextXAlignment=Enum.TextXAlignment.Left},row)
    local pill=make("Frame",{Size=UDim2.new(0,32,0,16),
        Position=UDim2.new(1,-38,0.5,-8),
        BackgroundColor3=def and C.TgOn or C.TgOff,BorderSizePixel=0},row)
    corner(8,pill)
    local knob=make("Frame",{Size=UDim2.new(0,12,0,12),
        Position=def and UDim2.new(1,-14,0.5,-6) or UDim2.new(0,2,0.5,-6),
        BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0},pill)
    corner(6,knob)
    local btn=make("TextButton",{Size=UDim2.new(1,0,1,0),
        BackgroundTransparency=1,Text=""},row)
    btn.MouseButton1Click:Connect(function()
        Toggles[key]=not Toggles[key]
        local on=Toggles[key]
        tw(pill,{BackgroundColor3=on and C.TgOn or C.TgOff})
        tw(knob,{Position=on and UDim2.new(1,-14,0.5,-6) or UDim2.new(0,2,0.5,-6)})
    end)
end

secLabel("CATÉGORIES",0,Body)
makeTog("Scripts",   "Scripts", 0,  16,Body,true)
makeTog("Remotes",   "Remotes", 142,16,Body,true)
makeTog("GUI",       "GUI",     0,  50,Body,true)
makeTog("Values",    "Values",  142,50,Body,true)
makeTog("Meshes",    "Meshes",  0,  84,Body,false)
makeTog("Workspace", "WS",      142,84,Body,true)
makeTog("RepStorage","RS",      0, 118,Body,true)
makeTog("StarterPk", "SK",      142,118,Body,true)

secLabel("OPTIONS",152,Body)
makeTog("Console",  "Console",  0, 168,Body,true)
makeTog("Export",   "Export",   142,168,Body,true)

-- ══ LOG ══
secLabel("LOG",202,Body)
local LogF=make("Frame",{Size=UDim2.new(1,0,0,140),
    Position=UDim2.new(0,0,0,216),
    BackgroundColor3=C.LogBG,BorderSizePixel=0},Body)
corner(7,LogF) stroke(1,C.Border,LogF)

local LogS=make("ScrollingFrame",{
    Size=UDim2.new(1,-6,1,-6),Position=UDim2.new(0,3,0,3),
    BackgroundTransparency=1,ScrollBarThickness=3,
    ScrollBarImageColor3=C.Accent,
    CanvasSize=UDim2.new(0,0,0,0),
    AutomaticCanvasSize=Enum.AutomaticSize.Y,
    BorderSizePixel=0},LogF)
make("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,
    Padding=UDim.new(0,2)},LogS)

local lc=0
local function addLog(msg,col)
    lc=lc+1
    make("TextLabel",{Size=UDim2.new(1,-6,0,13),
        BackgroundTransparency=1,Text=msg,
        TextColor3=col or C.Text,TextSize=9,Font=Enum.Font.Code,
        TextXAlignment=Enum.TextXAlignment.Left,
        TextTruncate=Enum.TextTruncate.AtEnd,
        LayoutOrder=lc},LogS)
    task.defer(function() LogS.CanvasPosition=Vector2.new(0,math.huge) end)
end

-- ══ STATUS ══
local St=make("TextLabel",{Size=UDim2.new(1,0,0,12),
    Position=UDim2.new(0,0,0,360),
    BackgroundTransparency=1,Text="Prêt.",
    TextColor3=C.Dim,TextSize=9,Font=Enum.Font.Gotham,
    TextXAlignment=Enum.TextXAlignment.Left},Body)
local function setStatus(t,c) St.Text=t St.TextColor3=c or C.Dim end

-- ══ BOUTON SCAN ══
local Btn=make("TextButton",{Size=UDim2.new(1,0,0,34),
    Position=UDim2.new(0,0,0,374),
    BackgroundColor3=C.Accent,Text="▶  LANCER LE SCAN",
    TextColor3=Color3.fromRGB(10,10,10),TextSize=12,
    Font=Enum.Font.GothamBold,BorderSizePixel=0},Body)
corner(8,Btn)

-- ══ LOGIQUE ══
local CLS={
    Script="Scripts",LocalScript="Scripts",ModuleScript="Scripts",
    RemoteEvent="Remotes",RemoteFunction="Remotes",
    BindableEvent="Remotes",BindableFunction="Remotes",
    ScreenGui="GUI",Frame="GUI",TextLabel="GUI",
    TextButton="GUI",ImageLabel="GUI",
    StringValue="Values",IntValue="Values",
    NumberValue="Values",BoolValue="Values",ObjectValue="Values",
    MeshPart="Meshes",SpecialMesh="Meshes",UnionOperation="Meshes",
}
local KEYMAP={Scripts="Scripts",Remotes="Remotes",GUI="GUI",
    Values="Values",Meshes="Meshes",Workspace="WS",
    ReplicatedStorage="RS",StarterPack="SK"}

local scanning=false
Btn.MouseButton1Click:Connect(function()
    if scanning then return end
    scanning=true
    tw(Btn,{BackgroundColor3=C.AccentDk})
    Btn.Text="⏳  EN COURS..."
    setStatus("Scan en cours...",C.Accent)
    for _,c in ipairs(LogS:GetChildren()) do
        if c:IsA("TextLabel") then c:Destroy() end
    end
    lc=0

    local Out,Res={},{}
    local hdr=string.format("=== %s | %s ===",game.Name,os.date("%H:%M:%S"))
    table.insert(Out,hdr) addLog(hdr,C.Accent)

    local TARGETS={}
    if Toggles.WS then table.insert(TARGETS,game:GetService("Workspace")) end
    if Toggles.RS then table.insert(TARGETS,game:GetService("ReplicatedStorage")) end
    if Toggles.SK then
        table.insert(TARGETS,game:GetService("StarterPack"))
        table.insert(TARGETS,game:GetService("StarterGui"))
        table.insert(TARGETS,game:GetService("StarterPlayer"))
    end
    table.insert(TARGETS,game:GetService("ReplicatedFirst"))
    table.insert(TARGETS,game:GetService("Lighting"))
    table.insert(TARGETS,game:GetService("SoundService"))

    local function scan(inst)
        local cls=inst.ClassName
        local cat=CLS[cls]
        if cat and Toggles[cat] then
            local path=inst:GetFullName()
            local e=string.format("[%s] %s",cls,path)
            if cat=="Values" then
                local ok,v=pcall(function() return tostring(inst.Value) end)
                if ok then e=e.." = "..v end
            end
            if cat=="Scripts" then
                local ok,s=pcall(function() return inst.Source end)
                e=e..(ok and s~="" and (" ["..#s.."c]") or " [protected]")
            end
            table.insert(Out,e) table.insert(Res,{class=cls})
            local col=C.Text
            if cat=="Scripts" then col=Color3.fromRGB(130,200,255)
            elseif cat=="Remotes" then col=Color3.fromRGB(255,180,80)
            elseif cat=="Values"  then col=Color3.fromRGB(180,255,150)
            elseif cat=="GUI"     then col=Color3.fromRGB(220,150,255)
            elseif cat=="Meshes"  then col=Color3.fromRGB(255,120,120) end
            addLog(e,col)
            if Toggles.Console then print(e) end
        end
        local ok,ch=pcall(function() return inst:GetChildren() end)
        if ok then for _,c in ipairs(ch) do pcall(scan,c) end end
    end

    for _,t in ipairs(TARGETS) do
        local s="--- "..t.Name.." ---"
        table.insert(Out,s) addLog(s,C.Dim)
        pcall(scan,t) task.wait()
    end

    local sum=string.format("=== TOTAL : %d ===",#Res)
    table.insert(Out,sum) addLog(sum,C.Accent)

    if Toggles.Export then
        local fn="Scan_"..game.Name:gsub("%s","_").."_"..os.time()..".txt"
        local ok=pcall(writefile,fn,table.concat(Out,"\n"))
        if ok then addLog("✔ Exporté : "..fn,C.Accent)
                    setStatus("✔ "..fn,C.Accent)
        else addLog("✘ writefile indispo",C.Red)
             setStatus("Export échoué",C.Red) end
    else
        setStatus("✔ "..#Res.." éléments trouvés",C.Accent)
    end

    tw(Btn,{BackgroundColor3=C.Accent})
    Btn.Text="▶  LANCER LE SCAN"
    scanning=false
end)

-- ══ ANIM INTRO ══
Main.Position=UDim2.new(0.5,-W/2,1.5,0)
tw(Main,{Position=UDim2.new(0.5,-W/2,0.5,-H/2)},.35)
addLog("Scanner prêt — lance le scan.",C.Accent)
addLog("Game : "..game.Name,C.Dim)
addLog("Job ID : "..tostring(game.JobId),C.Dim)

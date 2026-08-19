-- Roblox Game Scanner V6 | Natural Stop | No Limit
-- Delta Executor | Août 2026

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS          = game:GetService("UserInputService")
local LocalPlayer  = Players.LocalPlayer
local PlayerGui    = LocalPlayer:WaitForChild("PlayerGui")

if PlayerGui:FindFirstChild("ScannerUI") then
    PlayerGui:FindFirstChild("ScannerUI"):Destroy()
end

local C = {
    BG     = Color3.fromRGB(12,12,18),
    Panel  = Color3.fromRGB(20,20,32),
    Accent = Color3.fromRGB(80,200,120),
    AcDk   = Color3.fromRGB(40,110,65),
    Red    = Color3.fromRGB(210,55,55),
    Blue   = Color3.fromRGB(80,150,255),
    Gray   = Color3.fromRGB(45,45,60),
    Text   = Color3.fromRGB(220,220,220),
    Dim    = Color3.fromRGB(110,110,130),
    Border = Color3.fromRGB(38,38,58),
    LogBG  = Color3.fromRGB(8,8,14),
    TgOff  = Color3.fromRGB(38,38,52),
    TgOn   = Color3.fromRGB(80,200,120),
}

local function make(cls,props,parent)
    local o=Instance.new(cls)
    for k,v in pairs(props) do o[k]=v end
    if parent then o.Parent=parent end
    return o
end
local function corner(r,p) make("UICorner",{CornerRadius=UDim.new(0,r)},p) end
local function stroke(t,c,p) make("UIStroke",{Thickness=t,Color=c},p) end
local function tw(o,pr,t)
    TweenService:Create(o,TweenInfo.new(t or .15,Enum.EasingStyle.Quad),pr):Play()
end

local Gui=make("ScreenGui",{
    Name="ScannerUI",ResetOnSpawn=false,
    ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
},PlayerGui)

local W,H=560,290
local Main=make("Frame",{
    Size=UDim2.new(0,W,0,H),
    Position=UDim2.new(0.5,-W/2,0.5,-H/2),
    BackgroundColor3=C.BG,BorderSizePixel=0,
},Gui)
corner(10,Main) stroke(1.5,C.Border,Main)

-- TITLEBAR
local TB=make("Frame",{
    Size=UDim2.new(1,0,0,36),
    BackgroundColor3=C.Panel,BorderSizePixel=0,
},Main)
corner(10,TB)
make("Frame",{Size=UDim2.new(1,0,0,10),Position=UDim2.new(0,0,1,-10),
    BackgroundColor3=C.Panel,BorderSizePixel=0},TB)

local dot=make("Frame",{Size=UDim2.new(0,6,0,6),
    Position=UDim2.new(0,12,0.5,-3),
    BackgroundColor3=C.Accent,BorderSizePixel=0},TB)
corner(3,dot)

make("TextLabel",{Size=UDim2.new(0,180,0,18),Position=UDim2.new(0,22,0,4),
    BackgroundTransparency=1,Text="GAME SCANNER  •  V6",
    TextColor3=C.Text,TextSize=11,Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Left},TB)
make("TextLabel",{Size=UDim2.new(0,220,0,11),Position=UDim2.new(0,22,0,22),
    BackgroundTransparency=1,Text="DELTA READY  •  SCAN COMPLET",
    TextColor3=C.Accent,TextSize=8,Font=Enum.Font.GothamBold,
    TextXAlignment=Enum.TextXAlignment.Left},TB)

local GameLabel=make("TextLabel",{
    Size=UDim2.new(0,180,1,0),Position=UDim2.new(0.5,-90,0,0),
    BackgroundTransparency=1,Text="...",
    TextColor3=C.Dim,TextSize=8,Font=Enum.Font.Gotham,
    TextXAlignment=Enum.TextXAlignment.Center},TB)

local CloseBtn=make("TextButton",{
    Size=UDim2.new(0,24,0,24),Position=UDim2.new(1,-30,0.5,-12),
    BackgroundColor3=C.Red,Text="✕",TextColor3=Color3.new(1,1,1),
    TextSize=10,Font=Enum.Font.GothamBold,BorderSizePixel=0},TB)
corner(6,CloseBtn)
CloseBtn.MouseButton1Click:Connect(function()
    tw(Main,{Position=UDim2.new(0.5,-W/2,1.5,0)},.25)
    task.wait(.3) Gui:Destroy()
end)

-- DRAG TACTILE
do
    local drag,startInput,startPos=false
    TB.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then
            drag=true startInput=i.Position startPos=Main.Position
        end
    end)
    TB.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1
        or i.UserInputType==Enum.UserInputType.Touch then drag=false end
    end)
    UIS.InputChanged:Connect(function(i)
        if drag and(i.UserInputType==Enum.UserInputType.MouseMovement
        or i.UserInputType==Enum.UserInputType.Touch) then
            local d=i.Position-startInput
            Main.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,
                startPos.Y.Scale,startPos.Y.Offset+d.Y)
        end
    end)
end

-- LAYOUT HORIZONTAL
local Body=make("Frame",{
    Size=UDim2.new(0,544,0,246),
    Position=UDim2.new(0,8,0,40),
    BackgroundTransparency=1},Main)

make("Frame",{Size=UDim2.new(0,1,1,0),Position=UDim2.new(0,252,0,0),
    BackgroundColor3=C.Border,BorderSizePixel=0},Body)

local Left=make("Frame",{Size=UDim2.new(0,248,1,0),
    Position=UDim2.new(0,0,0,0),BackgroundTransparency=1},Body)
local Right=make("Frame",{Size=UDim2.new(0,286,1,0),
    Position=UDim2.new(0,258,0,0),BackgroundTransparency=1},Body)

local function secLabel(txt,y,p)
    make("TextLabel",{Size=UDim2.new(1,0,0,12),Position=UDim2.new(0,0,0,y),
        BackgroundTransparency=1,Text="— "..txt,TextColor3=C.Dim,
        TextSize=8,Font=Enum.Font.GothamBold,
        TextXAlignment=Enum.TextXAlignment.Left},p)
end

-- TOGGLES
local Toggles={}
local function makeTog(lbl,key,x,y,p,def)
    def=def~=false Toggles[key]=def
    local row=make("Frame",{Size=UDim2.new(0,117,0,24),
        Position=UDim2.new(0,x,0,y),
        BackgroundColor3=C.Panel,BorderSizePixel=0},p)
    corner(6,row) stroke(1,C.Border,row)
    make("TextLabel",{Size=UDim2.new(1,-36,1,0),Position=UDim2.new(0,7,0,0),
        BackgroundTransparency=1,Text=lbl,TextColor3=C.Text,
        TextSize=9,Font=Enum.Font.Gotham,
        TextXAlignment=Enum.TextXAlignment.Left},row)
    local pill=make("Frame",{Size=UDim2.new(0,28,0,14),
        Position=UDim2.new(1,-33,0.5,-7),
        BackgroundColor3=def and C.TgOn or C.TgOff,BorderSizePixel=0},row)
    corner(7,pill)
    local knob=make("Frame",{Size=UDim2.new(0,10,0,10),
        Position=def and UDim2.new(1,-12,0.5,-5) or UDim2.new(0,2,0.5,-5),
        BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0},pill)
    corner(5,knob)
    local btn=make("TextButton",{Size=UDim2.new(1,0,1,0),
        BackgroundTransparency=1,Text=""},row)
    btn.MouseButton1Click:Connect(function()
        Toggles[key]=not Toggles[key]
        local on=Toggles[key]
        tw(pill,{BackgroundColor3=on and C.TgOn or C.TgOff})
        tw(knob,{Position=on and UDim2.new(1,-12,0.5,-5) or UDim2.new(0,2,0.5,-5)})
    end)
end

-- Config recommandée — GUI et Meshes OFF par défaut
secLabel("CATÉGORIES",0,Left)
makeTog("Scripts",    "Scripts", 0,   14, Left, true)
makeTog("Remotes",    "Remotes", 131, 14, Left, true)
makeTog("Values",     "Values",  0,   42, Left, true)
makeTog("RepStorage", "RS",      131, 42, Left, true)
makeTog("Workspace",  "WS",      0,   70, Left, true)
makeTog("StarterPk",  "SK",      131, 70, Left, true)
makeTog("GUI",        "GUI",     0,   98, Left, false)
makeTog("Meshes",     "Meshes",  131, 98, Left, false)

secLabel("OPTIONS",126,Left)
makeTog("Console", "Console", 0,   140, Left, true)
makeTog("Export",  "Export",  131, 140, Left, true)

-- LOG
local LogF=make("Frame",{Size=UDim2.new(1,0,0,168),
    Position=UDim2.new(0,0,0,0),
    BackgroundColor3=C.LogBG,BorderSizePixel=0},Right)
corner(7,LogF) stroke(1,C.Border,LogF)

local LogS=make("ScrollingFrame",{
    Size=UDim2.new(1,-6,1,-6),Position=UDim2.new(0,3,0,3),
    BackgroundTransparency=1,ScrollBarThickness=3,
    ScrollBarImageColor3=C.Accent,
    CanvasSize=UDim2.new(0,0,0,0),
    AutomaticCanvasSize=Enum.AutomaticSize.Y,
    BorderSizePixel=0},LogF)
make("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder,
    Padding=UDim.new(0,1)},LogS)

local lc=0
local function addLog(msg,col)
    lc=lc+1
    make("TextLabel",{Size=UDim2.new(1,-6,0,11),
        BackgroundTransparency=1,Text=msg,
        TextColor3=col or C.Text,TextSize=8,Font=Enum.Font.Code,
        TextXAlignment=Enum.TextXAlignment.Left,
        TextTruncate=Enum.TextTruncate.AtEnd,
        LayoutOrder=lc},LogS)
    task.defer(function() LogS.CanvasPosition=Vector2.new(0,math.huge) end)
end

-- STATUS
local St=make("TextLabel",{Size=UDim2.new(1,0,0,12),
    Position=UDim2.new(0,0,0,171),
    BackgroundTransparency=1,Text="Prêt.",
    TextColor3=C.Dim,TextSize=8,Font=Enum.Font.Gotham,
    TextXAlignment=Enum.TextXAlignment.Left},Right)
local function setStatus(t,c) St.Text=t St.TextColor3=c or C.Dim end

-- BOUTONS
local ScanBtn=make("TextButton",{
    Size=UDim2.new(0,138,0,32),Position=UDim2.new(0,0,0,186),
    BackgroundColor3=C.Accent,Text="▶  SCAN",
    TextColor3=Color3.fromRGB(10,10,10),TextSize=11,
    Font=Enum.Font.GothamBold,BorderSizePixel=0},Right)
corner(7,ScanBtn)

local CopyBtn=make("TextButton",{
    Size=UDim2.new(0,138,0,32),Position=UDim2.new(0,148,0,186),
    BackgroundColor3=C.Gray,Text="⎘  COPIER",
    TextColor3=C.Dim,TextSize=11,
    Font=Enum.Font.GothamBold,BorderSizePixel=0},Right)
corner(7,CopyBtn)

local scanResults=""
local copyReady=false

local function enableCopy(txt)
    scanResults=txt copyReady=true
    tw(CopyBtn,{BackgroundColor3=C.Blue})
    CopyBtn.TextColor3=Color3.new(1,1,1)
end
local function disableCopy()
    scanResults="" copyReady=false
    tw(CopyBtn,{BackgroundColor3=C.Gray})
    CopyBtn.TextColor3=C.Dim
end

CopyBtn.MouseButton1Click:Connect(function()
    if not copyReady then return end
    pcall(setclipboard,scanResults)
    local orig=CopyBtn.Text
    CopyBtn.Text="✔  COPIÉ !"
    task.wait(1.5)
    if CopyBtn and CopyBtn.Parent then CopyBtn.Text=orig end
end)

-- CLASSES
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

-- SCAN — stack itératif, yield/10, stop manuel, pas de limite
local scanning=false
local stopFlag=false

ScanBtn.MouseButton1Click:Connect(function()
    if scanning then
        stopFlag=true
        return
    end

    scanning=true stopFlag=false
    disableCopy()
    tw(ScanBtn,{BackgroundColor3=C.Red})
    ScanBtn.Text="⏹  STOP"
    ScanBtn.TextColor3=Color3.new(1,1,1)
    setStatus("Scan en cours...",C.Accent)

    for _,c in ipairs(LogS:GetChildren()) do
        if c:IsA("TextLabel") then c:Destroy() end
    end
    lc=0

    local Out,Res={},{}
    local hdr=string.format("=== %s | %s ===",game.Name,os.date("%H:%M:%S"))
    table.insert(Out,hdr) addLog(hdr,C.Accent)

    local TARGETS={}
    if Toggles.WS      then table.insert(TARGETS,game:GetService("Workspace")) end
    if Toggles.RS      then table.insert(TARGETS,game:GetService("ReplicatedStorage")) end
    if Toggles.SK      then
        table.insert(TARGETS,game:GetService("StarterPack"))
        table.insert(TARGETS,game:GetService("StarterGui"))
        table.insert(TARGETS,game:GetService("StarterPlayer"))
    end
    table.insert(TARGETS,game:GetService("ReplicatedFirst"))
    table.insert(TARGETS,game:GetService("Lighting"))
    table.insert(TARGETS,game:GetService("SoundService"))

    local counter=0
    local function scanService(root)
        local stack={root}
        while #stack>0 and not stopFlag do
            local inst=table.remove(stack)
            counter=counter+1
            if counter%10==0 then
                setStatus("Scan : "..counter.." instances...",C.Accent)
                task.wait()
            end

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
                if cat=="Scripts"  then col=Color3.fromRGB(130,200,255)
                elseif cat=="Remotes" then col=Color3.fromRGB(255,180,80)
                elseif cat=="Values"  then col=Color3.fromRGB(180,255,150)
                elseif cat=="GUI"     then col=Color3.fromRGB(220,150,255)
                elseif cat=="Meshes"  then col=Color3.fromRGB(255,120,120) end
                addLog(e,col)
                if Toggles.Console then print(e) end
            end

            local ok,ch=pcall(function() return inst:GetChildren() end)
            if ok then for _,c in ipairs(ch) do table.insert(stack,c) end end
        end
    end

    for _,t in ipairs(TARGETS) do
        if stopFlag then break end
        local s="--- "..t.Name.." ---"
        table.insert(Out,s) addLog(s,C.Dim)
        scanService(t) task.wait()
    end

    local label=stopFlag and "STOPPÉ" or "TERMINÉ"
    local sum=string.format("=== %s — %d éléments ===",label,#Res)
    table.insert(Out,sum) addLog(sum,C.Accent)

    if Toggles.Export then
        local fn="Scan_"..game.Name:gsub("%s","_").."_"..os.time()..".txt"
        local ok=pcall(writefile,fn,table.concat(Out,"\n"))
        addLog(ok and "✔ Exporté : "..fn or "✘ writefile indispo",
               ok and C.Accent or C.Red)
    end

    setStatus("✔ "..#Res.." trouvés — appuie COPIER",C.Accent)
    enableCopy(table.concat(Out,"\n"))

    tw(ScanBtn,{BackgroundColor3=C.Accent})
    ScanBtn.Text="▶  SCAN"
    ScanBtn.TextColor3=Color3.fromRGB(10,10,10)
    scanning=false stopFlag=false
end)

-- INTRO
GameLabel.Text=game.Name.." | "..tostring(game.JobId):sub(1,8).."..."
Main.Position=UDim2.new(0.5,-W/2,1.5,0)
tw(Main,{Position=UDim2.new(0.5,-W/2,0.5,-H/2)},.35)
addLog("Scanner prêt — appuie SCAN.",C.Accent)
addLog("Game : "..game.Name,C.Dim)
addLog("Mode : scan complet, stop manuel uniquement.",C.Dim)

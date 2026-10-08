local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local PPS=game:GetService("ProximityPromptService")
local Run=game:GetService("RunService")
local player=Players.LocalPlayer
local playerGui=player:WaitForChild("PlayerGui")
local root=playerGui:FindFirstChild("ScreenGui")
while not root do
 local child=playerGui.ChildAdded:Wait()
 if child.Name=="ScreenGui" then root=child end
end
local gui=Instance.new("Frame");gui.Name="DistrictGuide";gui.Size=UDim2.fromScale(1,1);gui.BackgroundTransparency=1;gui.ZIndex=60;gui.Parent=root
local C=Color3.fromRGB
local U=require(root.Modules.UITheme)
local colors={bg=U.Colors.metal,panel=U.Colors.navy,ink=U.Colors.text,muted=U.Colors.muted,accent=U.Colors.orange}
local function make(class,props,parent)
 if class=="TextLabel"or class=="TextButton"then props.Font=nil;props.FontFace=U.FontFace;props.ZIndex=props.ZIndex or 4 end
 local o=Instance.new(class);for k,v in pairs(props) do o[k]=v end;o.Parent=parent
 if class=="TextButton"then U.Round(o,8);U.Stroke(o,U.Colors.edge,3)end;return o
end
local function text(parent,txt,pos,size,font,color)
 return make("TextLabel",{Text=txt,Position=pos,Size=size,BackgroundTransparency=1,
  TextColor3=color or colors.ink,Font=font or Enum.Font.Gotham,TextSize=16,
  TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true},parent)
end
local veil=make("Frame",{Name="MapOverlay",Visible=false,Size=UDim2.fromScale(1,1),BackgroundColor3=C(10,17,21),BackgroundTransparency=1,BorderSizePixel=0,Active=true},gui)
local panel=make("Frame",{Name="Directory",AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),Size=UDim2.fromOffset(700,490),BackgroundColor3=colors.bg,BorderSizePixel=0},veil)
U.Round(panel,14);U.Stroke(panel,U.Colors.edge,5)
local mapHeader=U.Header(panel,"MapHeader",8,8,684,72)
local heading=text(panel,"DOGROTS",UDim2.fromOffset(24,15),UDim2.fromOffset(260,34),Enum.Font.GothamBlack);heading.TextSize=27
text(panel,"DISTRICT MAP",UDim2.fromOffset(24,51),UDim2.fromOffset(260,22),Enum.Font.GothamBold,colors.accent).TextSize=12
local close=make("TextButton",{Text="X",Font=Enum.Font.GothamBold,TextSize=18,TextColor3=colors.ink,BackgroundColor3=colors.panel,BorderSizePixel=0,AnchorPoint=Vector2.new(1,0),Position=UDim2.new(1,-16,0,16),Size=UDim2.fromOffset(36,36)},panel)
local schematic=make("Frame",{Name="Schematic",Position=UDim2.fromOffset(22,94),Size=UDim2.fromOffset(300,338),BackgroundColor3=colors.panel,BorderSizePixel=0,ClipsDescendants=true},panel)
text(schematic,"DOGROTS / ISLAND DIRECTORY",UDim2.fromOffset(12,8),UDim2.fromOffset(220,20),Enum.Font.GothamBold,colors.muted).TextSize=11
local Routing=require(game:GetService('ReplicatedStorage'):WaitForChild('MapRouting'))
local function xy(v)
 local low,high=Routing.Bounds()
 return (v.X-low.X)/(high.X-low.X),(v.Z-low.Z)/(high.Z-low.Z)
end
local locations={}
for i,entry in ipairs(Routing.Locations) do
 table.insert(locations,{name=entry.Name,detail=entry.Detail,key=entry.Key,sealed=entry.Sealed,
 pos=Routing.Position(entry.Key,player) or Vector3.zero,color=i%2==0 and colors.accent or C(137,187,157)})
end
local list=make("ScrollingFrame",{Name="Destinations",Position=UDim2.fromOffset(342,91),Size=UDim2.fromOffset(338,348),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=4,ScrollBarImageColor3=colors.accent,CanvasSize=UDim2.fromOffset(0,#locations*58),ScrollingDirection=Enum.ScrollingDirection.Y},panel)
local hint=text(panel,"Choose a district to place a world marker.",UDim2.fromOffset(24,450),UDim2.new(1,-48,0,24),Enum.Font.Gotham,colors.muted);hint.TextSize=13;hint.TextColor3=U.Colors.edge
local selected=nil
local markerPart=make("Part",{Name="LocalDistrictWaypoint",Size=Vector3.one,Anchored=true,Transparency=1,CanCollide=false,CanTouch=false,CanQuery=false,CastShadow=false},workspace)
local marker=make("BillboardGui",{Name="Waypoint",Adornee=markerPart,Size=UDim2.fromOffset(184,54),AlwaysOnTop=true,MaxDistance=1000,Enabled=false},gui)
local markerText=text(marker,"",UDim2.fromScale(0,0),UDim2.fromScale(1,1),Enum.Font.GothamBold)
markerText.BackgroundColor3=colors.panel;markerText.BackgroundTransparency=0.1;markerText.TextXAlignment=Enum.TextXAlignment.Center;markerText.TextSize=14
make("UICorner",{CornerRadius=UDim.new(0,6)},markerText)
local clear=make("TextButton",{Name="ClearMarker",Text="CLEAR MARKER",Font=Enum.Font.GothamBold,TextSize=11,TextColor3=colors.muted,BackgroundColor3=colors.bg,BorderSizePixel=0,AnchorPoint=Vector2.new(1,1),Position=UDim2.new(1,-18,1,-70),Size=UDim2.fromOffset(124,28),Visible=false},gui)
local function toggle() veil.Visible=not veil.Visible end
close.Activated:Connect(toggle)
clear.Activated:Connect(function() selected=nil;marker.Enabled=false;clear.Visible=false end)
for i,loc in ipairs(locations) do
 local b=make("TextButton",{Name="Destination_"..i,Text="",Position=UDim2.fromOffset(0,(i-1)*58),Size=UDim2.new(1,-9,0,53),BackgroundColor3=colors.panel,BorderSizePixel=0},list)
 make("Frame",{Size=UDim2.new(0,3,1,0),BackgroundColor3=loc.color,BorderSizePixel=0},b)
 text(b,loc.name,UDim2.fromOffset(13,5),UDim2.new(1,-25,0,23),Enum.Font.GothamBold).TextSize=15
 text(b,loc.detail,UDim2.fromOffset(13,28),UDim2.new(1,-25,0,18),Enum.Font.Gotham,colors.muted).TextSize=11
 local function choose()
  if loc.sealed then hint.Text="THE VOID — SEALED / FUTURE AREA";return end
  loc.pos=Routing.Position(loc.key,player) or loc.pos
  selected=loc;markerPart.Position=loc.pos+Vector3.new(0,9,0)
  markerText.TextColor3=loc.color;markerText.Text=loc.name
  marker.Enabled=true;clear.Visible=true;veil.Visible=false
 end
 b.Activated:Connect(choose)
 local x,y=xy(loc.pos)
 local dot=make("TextButton",{Name="MapDot_"..i,AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(x,y),Size=UDim2.fromOffset(23,23),Text=tostring(i),TextColor3=colors.bg,TextSize=11,Font=Enum.Font.GothamBold,BackgroundColor3=loc.color,BorderSizePixel=0},schematic)
 make("UICorner",{CornerRadius=UDim.new(1,0)},dot);dot.Activated:Connect(choose)
end
local playerDot=make("Frame",{Name="YouAreHere",AnchorPoint=Vector2.new(0.5,0.5),Size=UDim2.fromOffset(9,9),BackgroundColor3=C(255,255,255),BorderSizePixel=0,ZIndex=5},schematic)
make("UICorner",{CornerRadius=UDim.new(1,0)},playerDot)
make("UIStroke",{Color=colors.bg,Thickness=2},playerDot)
local function resize()
 -- Fit and centre the map inside the Core UI safe area (below the top bar, clear of the notch).
 local left,top,width,height=U.SafeArea(root);local compact=width<730
 local w=compact and math.min(430,width-24) or 700
 local h=math.max(220,math.min(490,height-24))
 panel.Position=UDim2.fromOffset(left+width/2,top+height/2)
 panel.Size=UDim2.fromOffset(w,h);mapHeader.Size=UDim2.fromOffset(w-16,72)
 schematic.Visible=not compact
 list.Position=UDim2.fromOffset(compact and 22 or 342,91)
 list.Size=UDim2.fromOffset(compact and w-44 or 338,h-142)
 schematic.Size=UDim2.fromOffset(300,h-151)
 hint.Position=UDim2.fromOffset(24,h-35)
end
resize();root:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
game:GetService("GuiService"):GetPropertyChangedSignal("TopbarInset"):Connect(resize)
UIS.InputBegan:Connect(function(input,processed)
 if processed or UIS:GetFocusedTextBox() then return end
 if input.KeyCode==Enum.KeyCode.M then toggle() end
end)
PPS.PromptTriggered:Connect(function(prompt)
 if prompt.Name=="DistrictDirectoryPrompt" then veil.Visible=true end
end)
local elapsed=0;local lastSize=Vector2.zero
Run.Heartbeat:Connect(function(dt)
 elapsed+=dt;if elapsed<0.2 then return end;elapsed=0
 local cam=workspace.CurrentCamera
 if cam and cam.ViewportSize~=lastSize then lastSize=cam.ViewportSize;resize() end
 local char=player.Character;local hrp=char and char:FindFirstChild("HumanoidRootPart")
 if not hrp then return end
 if veil.Visible then
  local x,y=xy(hrp.Position);playerDot.Position=UDim2.fromScale(math.clamp(x,0,1),math.clamp(y,0,1))
 end
 if selected then
  selected.pos=Routing.Position(selected.key,player) or selected.pos
  markerPart.Position=selected.pos+Vector3.new(0,9,0)
  local delta=hrp.Position-selected.pos;local distance=Vector3.new(delta.X,0,delta.Z).Magnitude
  markerText.Text=selected.name.."\n"..math.floor(distance).." studs"
  if distance<13 then selected=nil;marker.Enabled=false;clear.Visible=false end
 end
end)
print("DOGROTS_GUIDE_READY")

local function updateYard()
 local pos=player:GetAttribute("YardSpawnPosition")
 if pos then locations[2].pos=pos;local x,y=xy(pos);schematic.MapDot_2.Position=UDim2.fromScale(x,y) end
end
updateYard()
player:GetAttributeChangedSignal("YardId"):Connect(updateYard)
player:GetAttributeChangedSignal("YardSpawnPosition"):Connect(updateYard)





-- PAWPAD navigation events drive the district map and waypoints.
local function connectNavigation(hud)
 if hud.Name ~= "ScreenGui" then return end
 gui.ZIndex=60
 U.LayoutHUD(hud) -- places ClearMarker in the HUD free zone (not over the right button column)
local signal=hud:WaitForChild("ToggleDistrictMap",10)
 if signal and signal:IsA("BindableEvent") then
  signal.Event:Connect(function() veil.Visible=not veil.Visible end)
 end
 local navigate=hud:WaitForChild("NavigateDistrict",10)
 if navigate then navigate.Event:Connect(function(name)
  for _,loc in ipairs(locations) do
   if loc.name==name or (name=="Factory" and loc.key=="DogLine") or (name=="Event headquarters" and loc.key=="GlobalDigSite") or (name=="Paw square" and loc.key=="WelcomeHub") then
    if loc.sealed then hint.Text="THE VOID — SEALED / FUTURE AREA";veil.Visible=true;return end
    loc.pos=Routing.Position(loc.key,player) or loc.pos
    if name=="Your yard" then loc.pos=player:GetAttribute("YardSpawnPosition") or loc.pos end
    selected=loc;markerPart.Position=loc.pos+Vector3.new(0,9,0)
    markerText.TextColor3=loc.color;markerText.Text=loc.name
    marker.Enabled=true;clear.Visible=true;veil.Visible=false
    return
   end
  end
  veil.Visible=true
 end) end
end
task.spawn(connectNavigation,root)

-- Secret dogs look as rare as they are, wherever they stand: on the tongue, walking home, in
-- a kennel, on a yard display, on a Best Finds stand, as the DOG-O-MATIC's prize or acting
-- out an arrival. Each gets (on this client only) a pulsing light in its signature colour,
-- two counter-rotating rune rings at its feet, rising sparks, orbiting motes, a pillar of
-- light seen from across the island, a "SECRET" nameplate and — for the nearest few — an
-- outline. Aurion is a prism: its aura cycles through nine colours.
-- Also: Aurion's showcase hologram over the Welcome Hub plaza, plus a Studio diagnostic when
-- Aurion's assets fail to load. Aurion displays (DOG-O-MATIC vitrine, hub hologram) carry
-- their own titles, so their aura has no nameplate and is fitted to their real world box.
local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Run=game:GetService('RunService')
local Content=game:GetService('ContentProvider')
local Definitions=require(RS:WaitForChild('DogEconomy'):WaitForChild('DogDefinitions'))
local Arrivals=require(RS:WaitForChild('SecretArrivalConfig'))
local player=Players.LocalPlayer
local C=Color3.fromRGB
local root=Instance.new('Folder');root.Name='DOGROTS_SecretAuras';root.Parent=workspace
local auras={}
local PRISM={C(255,90,90),C(255,170,60),C(255,236,90),C(120,255,120),C(80,240,220),C(90,170,255),C(150,110,255),C(230,110,255),C(255,140,210)}
local MAX_HIGHLIGHTS=6

local function low()
 local fx=player:GetAttribute('WorldEventFX')
 return fx=='Low'or player:GetAttribute('LowFX')==true
end
local function dogIdOf(model)
 local id=model:GetAttribute('DogId')or model:GetAttribute('SourceDogId')
 if type(id)~='string'then
  if model.Name=='AurionGrandPrize'or model.Name=='AurionShowcase'then return 'Aurion'end
  return nil
 end
 return id
end
local function isSecret(id)local def=id and Definitions[id];return def~=nil and def.Rank==6 end
local function colorOf(id,t)
 if id=='Aurion'then
  local k=(t*.6)%#PRISM;local i=math.floor(k)+1
  return PRISM[i]:Lerp(PRISM[i%#PRISM+1],k%1)
 end
 local arrival=Arrivals.Dogs[id]
 return arrival and arrival.Color or C(230,115,245)
end
local function part(props,parent)
 local p=Instance.new('Part');p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false
 p.Material=Enum.Material.Neon;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
 for k,v in pairs(props)do (p::any)[k]=v end
 p.Parent=parent or root;return p
end

---------------------------------------------------------------- Aurion's assets
-- Aurion's meshes/textures are separate uploads; in Studio, report any that fail to fetch
-- (asset permissions). PreloadAsync can report a failure for a mesh that renders, so this
-- only warns and never replaces the model.
task.spawn(function()
 if not Run:IsStudio()then return end
 local folder=RS:WaitForChild('MenuModels',30);local model=folder and folder:WaitForChild('Aurion',30)
 if not model then return end
 local failed={}
 local list={}
 for _,o in ipairs(model:GetDescendants())do if o:IsA('MeshPart')or o:IsA('SurfaceAppearance')then table.insert(list,o)end end
 pcall(function()Content:PreloadAsync(list,function(asset,status)
  if status==Enum.AssetFetchStatus.Failure or status==Enum.AssetFetchStatus.TimedOut then table.insert(failed,tostring(asset))end
 end)end)
 if #failed>0 then
  warn('[DOGROTS] Aurion assets failed to load ('..#failed..'): '..table.concat(failed,', ',1,math.min(#failed,6))
   ..' — give this experience permission to use them (Creator Hub › Development Items › each mesh/image › Permissions) or re-import Aurion with the account that owns the experience.')
 end
end)

---------------------------------------------------------------- auras
local function measure(model)
 local size=model:GetAttribute('VisualSize')
 local ground=model:GetAttribute('GroundLocal')
 if typeof(size)=='Vector3'and typeof(ground)=='Vector3'then return size,ground end
 if not model:FindFirstChildWhichIsA('BasePart',true)then return nil end
 local cf,box=model:GetBoundingBox()
 return box,model:GetPivot():PointToObjectSpace(cf.Position-cf.UpVector*box.Y/2)
end
-- Static displays are scaled and turned after import, so their saved VisualSize/GroundLocal
-- no longer match: fit to the world-aligned box instead (size, feet frame).
local function displayBox(model)
 if not model:FindFirstChildWhichIsA('BasePart',true)then return nil end
 local cf,box=model:GetBoundingBox();local h=box/2
 local r,u,l=cf.RightVector,cf.UpVector,cf.LookVector
 local size=Vector3.new(math.abs(r.X)*h.X+math.abs(u.X)*h.Y+math.abs(l.X)*h.Z,math.abs(r.Y)*h.X+math.abs(u.Y)*h.Y+math.abs(l.Y)*h.Z,
  math.abs(r.Z)*h.X+math.abs(u.Z)*h.Y+math.abs(l.Z)*h.Z)*2
 return size,CFrame.new(cf.Position-Vector3.new(0,size.Y/2,0))
end
-- The real floor under a display (its glow rises from there, even under a floating hologram).
local function floorBelow(at,model)
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
 local skip={model,root};for _,p in ipairs(Players:GetPlayers())do if p.Character then table.insert(skip,p.Character)end end
 params.FilterDescendantsInstances=skip
 local hit=workspace:Raycast(at+Vector3.new(0,1,0),Vector3.new(0,-80,0),params)
 return hit and hit.Position.Y or at.Y
end
local function isDisplay(model)return model.Name=='AurionGrandPrize'or model:GetAttribute('AurionDisplay')==true end
local function attach(model)
 if auras[model]or not model:IsA('Model')then return end
 local id=dogIdOf(model);if not isSecret(id)then return end
 local onTongue=model:IsDescendantOf(workspace:FindFirstChild('DOGROTS_District')or workspace)and model.Parent and model.Parent.Name=='ActiveDogs'
 local aura={Model=model,Id=id,Parts={},Born=os.clock(),Phase=math.random()*6,Tongue=onTongue,Display=isDisplay(model)}
 auras[model]=aura
 local folder=Instance.new('Folder');folder.Name='Aura_'..id;folder.Parent=root;aura.Folder=folder
 local color=colorOf(id,0)
 aura.Core=part({Name='Core',Size=Vector3.one*.2,Transparency=1},folder)
 aura.Light=Instance.new('PointLight');aura.Light.Range=18;aura.Light.Brightness=2.4;aura.Light.Shadows=false;aura.Light.Color=color;aura.Light.Parent=aura.Core
 aura.Feet=part({Name='Feet',Size=Vector3.one*.2,Transparency=1},folder)
 aura.Rings={}
 for i=1,2 do
  aura.Rings[i]=part({Name='RuneRing',Shape=Enum.PartType.Cylinder,Color=color,Transparency=.35,Size=Vector3.new(.08,6,6),Material=Enum.Material.ForceField},folder)
 end
 aura.Disc=part({Name='GlowDisc',Shape=Enum.PartType.Cylinder,Color=color,Transparency=.75,Size=Vector3.new(.05,6,6)},folder)
 local e=Instance.new('ParticleEmitter');e.Name='Sparks';e.Texture='rbxasset://textures/particles/sparkles_main.dds';e.LightEmission=1;e.LightInfluence=0
 e.Rate=low()and 6 or 16;e.Lifetime=NumberRange.new(1.2,2.2);e.Speed=NumberRange.new(2,5);e.SpreadAngle=Vector2.new(25,25);e.EmissionDirection=Enum.NormalId.Top
 e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.5),NumberSequenceKeypoint.new(1,0)});e.Transparency=NumberSequence.new(.1,1)
 e.Shape=Enum.ParticleEmitterShape.Disc;e.ShapeStyle=Enum.ParticleEmitterShapeStyle.Volume;e.Color=ColorSequence.new(color,Color3.new(1,1,1));e.Parent=aura.Feet
 aura.Sparks=e
 -- Displays are lit from the floor up.
 if aura.Display then
  local up=Instance.new('SpotLight');up.Face=Enum.NormalId.Top;up.Angle=70;up.Shadows=false;up.Color=color;up.Parent=aura.Feet
  aura.UpLight=up
 end
 if not low()then
  aura.Motes={}
  for i=1,3 do aura.Motes[i]=part({Name='Mote',Shape=Enum.PartType.Ball,Color=color,Size=Vector3.one*.5,Transparency=.1},folder)end
 end
 -- The pillar is seen from across the island (taller on the tongue and on stages).
 local top=part({Name='PillarTop',Size=Vector3.one*.2,Transparency=1},folder)
 local a0=Instance.new('Attachment');a0.Parent=aura.Feet;local a1=Instance.new('Attachment');a1.Parent=top
 local beam=Instance.new('Beam');beam.Attachment0=a0;beam.Attachment1=a1;beam.FaceCamera=true;beam.LightEmission=1;beam.LightInfluence=0
 beam.Width0=2.4;beam.Width1=.2;beam.Segments=2;beam.Color=ColorSequence.new(color,Color3.new(1,1,1))
 beam.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.25),NumberSequenceKeypoint.new(1,1)});beam.Parent=folder
 aura.Beam=beam;aura.Top=top
 -- Nameplate.
 local board=Instance.new('BillboardGui');board.Name='SecretTag';board.Size=UDim2.fromOffset(200,46);board.AlwaysOnTop=true;board.LightInfluence=0
 board.MaxDistance=onTongue and 220 or 120;board.Adornee=aura.Core;board.Parent=folder
 local tag=Instance.new('TextLabel');tag:SetAttribute('KeepFont',true);tag.BackgroundTransparency=1;tag.Size=UDim2.new(1,0,0,26);tag.Font=Enum.Font.FredokaOne
 tag.Text='✦ S E C R E T ✦';tag.TextScaled=true;tag.TextColor3=Color3.new(1,1,1);tag.Parent=board
 local stroke=Instance.new('UIStroke');stroke.Thickness=2;stroke.Color=C(10,8,18);stroke.Parent=tag
 local shine=Instance.new('UIGradient');shine.Parent=tag
 local def=Definitions[id]
 local name=Instance.new('TextLabel');name:SetAttribute('KeepFont',true);name.BackgroundTransparency=1;name.Size=UDim2.new(1,0,0,18);name.Position=UDim2.fromOffset(0,27)
 name.Font=Enum.Font.FredokaOne;name.TextScaled=true;name.Text=string.upper(def and def.DisplayName or id);name.TextColor3=color:Lerp(Color3.new(1,1,1),.4);name.Parent=board
 local nameStroke=Instance.new('UIStroke');nameStroke.Thickness=1.5;nameStroke.Color=C(10,8,18);nameStroke.Parent=name
 aura.Board=board;aura.Shine=shine;aura.Name=name
 if aura.Display then board.Enabled=false end
 model.Destroying:Connect(function()
  local a=auras[model];if a then auras[model]=nil;a.Folder:Destroy();if a.Form then a.Form:Destroy()end end
 end)
end
local function detach(model)
 local a=auras[model];if not a then return end
 auras[model]=nil;a.Folder:Destroy();if a.Form then a.Form:Destroy()end
 if a.RarityShine then a.RarityShine:Destroy()end
end

---------------------------------------------------------------- discovery
local function watch(container,deep)
 if not container then return end
 local function consider(o)if o:IsA('Model')then task.defer(attach,o)end end
 if deep then
  container.DescendantAdded:Connect(consider)
  for _,o in ipairs(container:GetDescendants())do consider(o)end
 else
  container.ChildAdded:Connect(consider)
  for _,o in ipairs(container:GetChildren())do consider(o)end
 end
 container.DescendantRemoving:Connect(function(o)if auras[o]then detach(o)end end)
end
task.spawn(function()
 local district=workspace:WaitForChild('DOGROTS_District')
 local line=district:WaitForChild('03_DogLine');watch(line:WaitForChild('ActiveDogs'),false)
 watch(district:WaitForChild('KennelDogs'),false)
 -- Yard displays, Best Finds stands, the DOG-O-MATIC prize and its Aurion vitrine stream in.
 watch(district:WaitForChild('04_PlayerYards'),true)
 local attraction=district:WaitForChild('37_AttractionRefresh',30);watch(attraction,true)
end)
task.spawn(function()
 local reveals=workspace:WaitForChild('DOGROTS_SecretReveals',120);watch(reveals,false)
end)

---------------------------------------------------------------- Aurion showcase (Welcome Hub)
local showcase
local HOLOGRAM_HEIGHT=12
local function buildShowcase()
 local folder=RS:FindFirstChild('MenuModels');local source=folder and folder:FindFirstChild('Aurion')
 local m=Instance.new('Model');m.Name='AurionShowcase'
 local base=Vector3.new(0,13,342)
 if source then
  local ok,clone=pcall(function()return source:Clone()end)
  if ok and clone then
   for _,o in ipairs(clone:GetDescendants())do
    if o:IsA('BasePart')then o.Anchored=true;o.CanCollide=false;o.CanTouch=false;o.CanQuery=false;o.CastShadow=false
    elseif o:IsA('LuaSourceContainer')or o:IsA('ProximityPrompt')then o:Destroy()end
   end
   local _,size=clone:GetBoundingBox();if size.Y>.01 then clone:ScaleTo(clone:GetScale()*HOLOGRAM_HEIGHT/size.Y)end
   -- Spin around the body's centre, not an off-centre pivot (or the dog orbits away from its title).
   local pivot=clone:GetPivot();local centre=pivot:PointToObjectSpace((clone:GetBoundingBox()).Position)
   clone.WorldPivot=pivot*CFrame.new(centre.X,0,centre.Z)
   clone.Name='Hologram';clone.Parent=m
  end
 end
 m:SetAttribute('DogId','Aurion')
 local pad=part({Name='PrismPad',Shape=Enum.PartType.Cylinder,Color=C(200,240,255),Material=Enum.Material.Glass,Transparency=.4,
  Size=Vector3.new(.4,9,9),CFrame=CFrame.new(base-Vector3.new(0,4.4,0))*CFrame.Angles(0,0,math.pi/2)},m)
 -- The title hangs from its own unrotated anchor: offsets on the (turned) cylinder pad would point sideways.
 local anchor=part({Name='TitleAnchor',Size=Vector3.one*.2,Transparency=1,CFrame=CFrame.new(base+Vector3.new(0,HOLOGRAM_HEIGHT,0))},m)
 local board=Instance.new('BillboardGui');board.Size=UDim2.fromOffset(300,70);board.MaxDistance=180;board.LightInfluence=0;board.Adornee=anchor;board.Parent=m
 local title=Instance.new('TextLabel');title:SetAttribute('KeepFont',true);title.BackgroundTransparency=1;title.Size=UDim2.new(1,0,0,40);title.Font=Enum.Font.FredokaOne
 title.Text='AURION';title.TextScaled=true;title.TextColor3=Color3.new(1,1,1);title.Parent=board
 local tg=Instance.new('UIGradient');tg.Parent=title
 local ts=Instance.new('UIStroke');ts.Thickness=3;ts.Color=C(20,16,40);ts.Parent=title
 local sub=Instance.new('TextLabel');sub:SetAttribute('KeepFont',true);sub.BackgroundTransparency=1;sub.Size=UDim2.new(1,0,0,24);sub.Position=UDim2.fromOffset(0,42);sub.Font=Enum.Font.FredokaOne
 sub.Text='DOG-O-MATIC EXCLUSIVE · 1 IN 10,000';sub.TextScaled=true;sub.TextColor3=C(220,240,255);sub.Parent=board
 local ss=Instance.new('UIStroke');ss.Thickness=2;ss.Color=C(20,16,40);ss.Parent=sub
 m.Parent=root
 showcase={Model=m,Base=base,Hologram=m:FindFirstChild('Hologram'),Title=tg,Anchor=anchor}
 -- The aura hugs the hologram itself (not the wide glass pad under it).
 local target=showcase.Hologram or m
 target:SetAttribute('DogId','Aurion');target:SetAttribute('AurionDisplay',true)
 attach(target)
end
task.delay(3,buildShowcase)

---------------------------------------------------------------- per frame
local frame=0
Run.RenderStepped:Connect(function()
 frame+=1
 local now=os.clock()
 local camera=workspace.CurrentCamera;local eye=camera and camera.CFrame.Position or Vector3.zero
 local serverNow=workspace:GetServerTimeNow()
 -- Outline only the nearest few (Highlights are a scarce per-client budget).
 local nearest={}
 for model,a in pairs(auras)do
  if not model.Parent then detach(model)
  elseif (frame+math.floor(a.Phase*10))%2==0 or a.Tongue then
   local size,feet
   if a.Display then size,feet=displayBox(model)
   else
    local ground;size,ground=measure(model)
    if size then feet=model:GetPivot()*CFrame.new(ground)end
   end
   if size then
    local t=now-a.Born+a.Phase
    -- An arrival owns the stage until its hold ends: the aura waits, then fades in.
    local hold=model:GetAttribute('ArrivalHoldUntil')
    if type(hold)=='number'and serverNow<hold then a.Shown=nil elseif not a.Shown then a.Shown=now end
    local show=a.Shown and math.min(1,(now-a.Shown)/1.2)or 0
    local color=colorOf(a.Id,t)
    local radius=math.max(size.X,size.Z)*.75+1.2
    local pulse=.5+.5*math.sin(t*2.4)
    a.Core.CFrame=feet*CFrame.new(0,size.Y*.55,0)
    a.Light.Color=color;a.Light.Brightness=(1.6+1.6*pulse)*show;a.Light.Range=math.clamp(radius*3,10,30)
    -- Body light stays on the dog; rings, glow and pillar start on the floor.
    local body=feet
    if a.Display then
     a.Floor=a.Floor or floorBelow(feet.Position,model)
     feet=CFrame.new(feet.X,math.min(a.Floor,feet.Y),feet.Z)
    end
    a.Feet.CFrame=feet*CFrame.new(0,.15,0)
    if a.Display then
     local rise=body.Y-feet.Y+size.Y
     a.Core.CFrame=feet*CFrame.new(0,.8,0);a.Light.Range=math.clamp(radius*1.5,6,16)
     a.UpLight.Color=color;a.UpLight.Range=rise+6;a.UpLight.Brightness=(3+2*pulse)*show
     a.Sparks.Speed=NumberRange.new(rise*.45,rise*.7);a.Sparks.Lifetime=NumberRange.new(1.4,1.8)
    end
    for i,ring in ipairs(a.Rings)do
     local r=radius*(i==1 and 1 or .78)
     ring.Size=Vector3.new(.08,r*2,r*2);ring.Color=color
     ring.CFrame=feet*CFrame.new(0,.12+i*.04,0)*CFrame.Angles(0,(i==1 and 1 or -1.4)*t*.9,0)*CFrame.Angles(0,0,math.pi/2)
     ring.Transparency=1-(.55+.2*pulse)*show
    end
    a.Disc.Size=Vector3.new(.05,radius*2.1,radius*2.1);a.Disc.CFrame=feet*CFrame.new(0,.1,0)*CFrame.Angles(0,0,math.pi/2)
    a.Disc.Color=color;a.Disc.Transparency=1-(.18+.12*pulse)*show
    a.Sparks.Color=ColorSequence.new(color,Color3.new(1,1,1));a.Sparks.Enabled=show>.5
    if a.Motes then
     for i,mote in ipairs(a.Motes)do
      local ang=t*1.6+i*math.pi*2/3
      mote.CFrame=body*CFrame.new(math.cos(ang)*radius*.9,size.Y*(.35+.25*math.sin(t*1.3+i)),math.sin(ang)*radius*.9)
      mote.Color=color;mote.Transparency=1-.9*show
     end
    end
    local tall=(a.Tongue or model:GetAttribute('SecretReveal'))and 70 or 26
    a.Top.CFrame=a.Display and body*CFrame.new(0,size.Y+3,0)or feet*CFrame.new(0,tall,0)
    a.Beam.Color=ColorSequence.new(color,Color3.new(1,1,1));a.Beam.Width0=math.max(1.2,radius*.5)*show;a.Beam.Width1=a.Beam.Width0 -- a straight column, not a cone
    a.Board.StudsOffsetWorldSpace=Vector3.new(0,size.Y*.5+(a.Tongue and 4.2 or 2.2),0);a.Board.Enabled=show>.3 and not a.Display
    a.Shine.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,color),ColorSequenceKeypoint.new(.5,Color3.new(1,1,1)),ColorSequenceKeypoint.new(1,color)})
    a.Shine.Offset=Vector2.new(math.sin(t*1.7)*.6,0)
    -- The tongue's own billboard (made just after the dog is parented) shimmers too.
    if a.Tongue and not a.RarityShine then
     local server=model:FindFirstChild('DogBillboard')
     local rarity=server and server:FindFirstChild('RarityLabel')
     if rarity and rarity:IsA('TextLabel')then
      local g=rarity:FindFirstChild('SecretShimmer')or Instance.new('UIGradient');g.Name='SecretShimmer';g.Parent=rarity;a.RarityShine=g
     end
    end
    if a.RarityShine then a.RarityShine.Color=a.Shine.Color;a.RarityShine.Offset=a.Shine.Offset end
    a.Row={Aura=a,Distance=(feet.Position-eye).Magnitude,Show=show,Color=color}
   end
  end
 end
 -- Auras update on alternate frames; rank all of them by their latest distance so the
 -- outline budget is one list, not one per frame parity.
 for _,a in pairs(auras)do if a.Row then table.insert(nearest,a.Row)end end
 table.sort(nearest,function(x,y)return x.Distance<y.Distance end)
 for i,row in ipairs(nearest)do
  local a=row.Aura
  local want=i<=MAX_HIGHLIGHTS and row.Distance<160 and row.Show>.5
  if want and not a.Highlight then
   local h=Instance.new('Highlight');h.Name='DOGROTS_SecretAura';h.DepthMode=Enum.HighlightDepthMode.Occluded;h.Adornee=a.Model
   h.FillTransparency=.88;h.OutlineTransparency=.15;h.Parent=a.Folder;a.Highlight=h
  elseif not want and a.Highlight then a.Highlight:Destroy();a.Highlight=nil end
  if a.Highlight then a.Highlight.OutlineColor=row.Color;a.Highlight.FillColor=row.Color end
 end
 -- The hub hologram turns slowly and bobs.
 if showcase and showcase.Hologram and showcase.Hologram.Parent then
  local t=now
  local _,size=showcase.Hologram:GetBoundingBox()
  showcase.Hologram:PivotTo(CFrame.new(showcase.Base+Vector3.new(0,math.sin(t*1.1)*.6-size.Y*.1,0))*CFrame.Angles(0,t*.35,0))
  -- The title floats just over the hologram's head, wherever its scale puts it.
  local box,feet=displayBox(showcase.Hologram)
  if box then showcase.Anchor.CFrame=CFrame.new(feet.X,feet.Y+box.Y+2.2,feet.Z)end
  showcase.Title.Offset=Vector2.new(math.sin(t*1.5)*.6,0)
  showcase.Title.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,colorOf('Aurion',t)),ColorSequenceKeypoint.new(.5,Color3.new(1,1,1)),ColorSequenceKeypoint.new(1,colorOf('Aurion',t+3))})
 end
end)
print('DOGROTS_SECRET_AURA_READY')

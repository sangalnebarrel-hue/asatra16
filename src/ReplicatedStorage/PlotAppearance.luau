-- Each skin changes the roof, perimeter, entrance and garden silhouette.
local C=require(game.ReplicatedStorage.PlotCatalog)
local G=require(game.ReplicatedStorage.PlotGeometry)
local A={};local cache=setmetatable({},{__mode='k'})
local P,B=G.Part,G.Beam
local function remember(p)
 if p:GetAttribute('PlotBaseTransparency')==nil then p:SetAttribute('PlotBaseTransparency',p.Transparency);p:SetAttribute('PlotBaseColor',p.Color);p:SetAttribute('PlotBaseMaterial',p.Material.Name);p:SetAttribute('PlotBaseCollide',p.CanCollide)end
end
local function show(p,on)
 remember(p);p.Transparency=on and p:GetAttribute('PlotBaseTransparency')or 1;p.CanCollide=on and p:GetAttribute('PlotBaseCollide')or false
end
function A.Frame(yard)
 local ground=yard.YardLandscape.YardFoundation;local back=yard.StorageAnchor.Position
 local center=Vector3.new(ground.Position.X,1.2,ground.Position.Z)
 return CFrame.lookAt(center,Vector3.new(back.X,1.2,back.Z))
end
local function roof(parent,cf,w,depth,d,level)
 local body,top,trim,glow=C.Color(d.Color),C.Color(d.Roof),C.Color(d.Trim),C.Color(d.Glow);local m=d.Motif
 local tech=m=='Moon'or m=='Glitch'or m=='Void';local arch=m=='UFO'or m=='Rainbow'
 if arch then
  -- Segmented barrel vaults make the alien and prism skins recognizable at a distance.
  for i=0,8 do local a=math.pi*(i+.5)/9;local col=m=='Rainbow'and Color3.fromHSV(i/10,.34,1)or top
   P(parent,'VaultRoof',Vector3.new(w,.4,depth*.18),cf*CFrame.new(0,math.sin(a)*depth*.28,math.cos(a)*depth*.5)*CFrame.Angles(a-math.pi/2,0,0),col,Enum.Material.Metal)
  end
  for _,x in ipairs({-w/2,w/2})do G.Ring(parent,cf*CFrame.new(x,0,0)*CFrame.Angles(0,math.pi/2,0),depth*.52,.23,glow,Enum.Material.Neon,0,math.pi,12)end
 elseif tech or m=='Clock'then
  for i=0,3 do P(parent,'TieredRoof',Vector3.new(w-i*.7,.55,depth-i*.6),cf*CFrame.new(0,i*.5,0),top,Enum.Material.Slate)end
  for _,z in ipairs({-depth/2,depth/2})do P(parent,'RoofInlay',Vector3.new(w,.16,.16),cf*CFrame.new(0,.05,z),m=='Clock'and trim or glow,tech and Enum.Material.Neon or Enum.Material.Metal)end
  if m=='Moon'then for _,x in ipairs({-w*.38,w*.38})do P(parent,'SolarBrace',Vector3.new(.2,.16,depth*.8),cf*CFrame.new(x,1.8,0),trim,Enum.Material.Metal)end end
 else
  for _,s in ipairs({-1,1})do
   P(parent,m=='Treasure'and 'CanvasRoof'or 'PitchedRoof',Vector3.new(w,.55,depth*.59),cf*CFrame.new(0,depth*.12,s*depth*.255)*CFrame.Angles(-s*.4,0,0),top,m=='Treasure'and Enum.Material.Fabric or Enum.Material.Slate)
   P(parent,'RoofFascia',Vector3.new(w+.3,.3,.3),cf*CFrame.new(0,.03,s*depth*.54),trim,Enum.Material.WoodPlanks)
  end
  P(parent,'RidgeCap',Vector3.new(w+.3,.45,.65),cf*CFrame.new(0,depth*.235,0),trim,Enum.Material.Metal)
  for i=1,math.max(3,math.floor(w/2))do P(parent,'RoofSeam',Vector3.new(.1,.12,depth*.99),cf*CFrame.new(-w/2+i*w/(math.floor(w/2)+1),depth*.19,0),top:Lerp(trim,.2))end
 end
 if m=='Bone'then G.Bone(parent,cf*CFrame.new(0,3,0),math.min(w/7,1.6),trim)
 elseif m=='Crystal'then G.Cluster(parent,cf*CFrame.new(0,2,0),w>18 and 1.5 or .8,glow,trim)
 elseif m=='Rock'then for i=1,3 do G.Rock(parent,cf*CFrame.new((i-2)*w*.26,2,0),w>18 and 1.3 or .7,top)end
 elseif m=='Clock'then G.Clock(parent,cf*CFrame.new(0,3,depth*.44)*CFrame.Angles(0,math.pi,0),w>18 and 1 or .5,trim,body)
 elseif m=='Sun'then G.Crest(parent,cf*CFrame.new(0,3,0),w>18 and 1.1 or .6,d)
 elseif m=='Treasure'then G.Paw(parent,cf*CFrame.new(0,.7,depth*.52)*CFrame.Angles(0,math.pi,0),.6,trim)
 elseif m=='Race'then
  for _,x in ipairs({-w*.2,w*.2})do P(parent,'RacingStripe',Vector3.new(.6,.15,depth),cf*CFrame.new(x,depth*.24+.3,0),trim)end
 elseif m=='Glitch'then for i=1,4 do local p=P(parent,'ErrorFragment',Vector3.one*(.5+i*.23),cf*CFrame.new((i-2.5)*2,3+i%2,0)*CFrame.Angles(i,i*.4,0),i%2==0 and trim or body);p:SetAttribute('PlotFloat',true)end
 elseif m=='UFO'then
  for _,x in ipairs({-w*.4,w*.4})do P(parent,'Antenna',Vector3.new(.18,2.8,.18),cf*CFrame.new(x,2.2,0),trim,Enum.Material.Metal);P(parent,'AntennaTip',Vector3.one*.55,cf*CFrame.new(x,3.7,0),glow,Enum.Material.Neon,Enum.PartType.Ball)end
 end
end
local function lamp(parent,cf,d,s,lit)
 local body,trim,glow=C.Color(d.Color),C.Color(d.Trim),C.Color(d.Glow);s=s or 1
 P(parent,'LampFoot',Vector3.new(1.4,.4,1.4)*s,cf*CFrame.new(0,.2*s,0),trim,Enum.Material.Metal)
 P(parent,'LampStem',Vector3.new(.35,4.5,.35)*s,cf*CFrame.new(0,2.3*s,0),body,Enum.Material.Metal)
 local lens=P(parent,'LampLens',Vector3.new(.9,1.35,.9)*s,cf*CFrame.new(0,4.8*s,0),glow,Enum.Material.Neon)
 for _,x in ipairs({-.55,.55})do for _,z in ipairs({-.55,.55})do P(parent,'LanternCage',Vector3.new(.11,1.7,.11)*s,cf*CFrame.new(x*s,4.8*s,z*s),trim,Enum.Material.Metal)end end
 P(parent,'LampCap',Vector3.new(1.55,.4,1.55)*s,cf*CFrame.new(0,5.65*s,0),body,Enum.Material.Metal)
 if lit then local light=Instance.new('PointLight');light.Color=glow;light.Brightness=.55;light.Range=12;light.Shadows=false;light.Parent=lens end
end
local function tree(parent,cf,d,s)
 local body=C.Color(d.Color);local glow=C.Color(d.Glow)
 B(parent,'DeadTrunk',cf.Position,cf:PointToWorldSpace(Vector3.new(.3,9,0)*s),.65*s,body,Enum.Material.Wood)
 for i=1,5 do local x=i%2==0 and -1 or 1;local a=Vector3.new(.2,2+i,0)*s;local b=Vector3.new(x*(1+i*.4),5+i,i%2)*s
  B(parent,'TwistedBranch',cf:PointToWorldSpace(a),cf:PointToWorldSpace(b),.3*s,body,Enum.Material.Wood)
  B(parent,'BranchTip',cf:PointToWorldSpace(b),cf:PointToWorldSpace(b+Vector3.new(x*.6,2,0)*s),.18*s,body,Enum.Material.Wood)
 end
 lamp(parent,cf*CFrame.new(1.6*s,4.7*s,0),d,.4,false)
end
local function fence(parent,f,d,level)
 local body,trim,glow=C.Color(d.Color),C.Color(d.Trim),C.Color(d.Glow);local m=d.Motif
 local ornate=level>=6;local height=ornate and 4.5 or 3.5
 local function segment(cf,length,index)
  P(parent,'BoundaryFoot',Vector3.new(length,.75,1.4),cf*CFrame.new(0,.35,0),body,Enum.Material.Slate)
  if m=='Rock'then for j=1,math.ceil(length/4)do G.Rock(parent,cf*CFrame.new(-length/2+j*3.5,2,0),.9,body)end
  else
   for _,y in ipairs({1.5,height})do P(parent,'BoundaryRail',Vector3.new(length,.48,.65),cf*CFrame.new(0,y,0),m=='Bone'and body or trim,m=='Treasure'and Enum.Material.Wood or Enum.Material.Metal)end
   if m=='Void'or m=='Moon'or m=='Glitch'or m=='UFO'or m=='Rainbow'or m=='Crystal'then
    P(parent,'BoundaryLight',Vector3.new(length,.14,.14),cf*CFrame.new(0,2.5,-.39),glow,Enum.Material.Neon)
   end
   if m=='Bone'then G.Bone(parent,cf*CFrame.new(0,2.6,0),length/8,trim)
   elseif m=='Clock'or m=='Treasure'then G.Gear(parent,cf*CFrame.new(0,2.5,0),1,trim)
   elseif m=='Race'then
    for j=-1,1 do local a=cf:PointToWorldSpace(Vector3.new(j*2-.6,2,.4));local b=cf:PointToWorldSpace(Vector3.new(j*2+.5,2.7,.4));local c=cf:PointToWorldSpace(Vector3.new(j*2-.6,3.4,.4));B(parent,'Chevron',a,b,.2,trim);B(parent,'Chevron',b,c,.2,trim)end
   elseif m=='Curse'then B(parent,'TwistedRail',cf:PointToWorldSpace(Vector3.new(-length/2,1,-.4)),cf:PointToWorldSpace(Vector3.new(length/2,height+.3,-.4)),.34,body,Enum.Material.Wood)
   elseif ornate then for j=-1,1 do P(parent,'FenceSpindle',Vector3.new(.18,height-1,.18),cf*CFrame.new(j*length*.28,(height+1)/2,0),trim,Enum.Material.Metal)end end
  end
 end
 local function post(cf,index)
  P(parent,'BoundaryPier',Vector3.new(1.7,height+1,1.7),cf*CFrame.new(0,(height+1)/2,0),body,Enum.Material.Slate)
  P(parent,'PierFoot',Vector3.new(2.25,.65,2.25),cf*CFrame.new(0,.33,0),trim,Enum.Material.Slate)
  P(parent,'PierCrown',Vector3.new(2.3,.55,2.3),cf*CFrame.new(0,height+1.15,0),trim,Enum.Material.Metal)
  if m=='Void'or m=='UFO'or m=='Moon'then P(parent,'PierLight',Vector3.new(.22,height-.5,.15),cf*CFrame.new(0,height/2+.5,-.9),glow,Enum.Material.Neon)end
  if m=='Crystal'or m=='Rainbow'then G.Cluster(parent,cf*CFrame.new(0,height+1.5,0),.42,glow,trim)
  elseif index%2==0 or level>=8 then lamp(parent,cf*CFrame.new(0,height+1.5,0),d,.52,false)end
 end
 for _,x in ipairs({-34,34})do for i=0,8 do local z=64-i*16
  post(f*CFrame.new(x,0,z),i)
  if i<8 then segment(f*CFrame.new(x,0,z-8)*CFrame.Angles(0,math.pi/2,0),16,i)end
 end end
 for _,side in ipairs({-1,1})do
  if side==1 then
   -- A low gallery sill keeps the three exhibits readable from the entrance.
   P(parent,'GalleryBoundary',Vector3.new(24,.65,1.4),f*CFrame.new(22,.33,64),body,Enum.Material.Slate)
   P(parent,'GalleryEdge',Vector3.new(24,.15,1.5),f*CFrame.new(22,.73,64),trim,Enum.Material.Metal)
  else
   for i=1,2 do local x=side*(10+(i-.5)*12);segment(f*CFrame.new(x,0,64),12,i)end
   post(f*CFrame.new(side*22,0,64),1)
  end
  post(f*CFrame.new(side*10,0,64),0)
 end

 for i=-1,1 do segment(f*CFrame.new(i*22,0,-64),22,i)end
end
local function gate(parent,f,d,level)
 local body,trim,glow=C.Color(d.Color),C.Color(d.Trim),C.Color(d.Glow);local m=d.Motif;local cf=f*CFrame.new(0,0,64)
 local grand=level>=7;local h=grand and 13 or 10
 for _,x in ipairs({-9,9})do
  P(parent,'GateBase',Vector3.new(4,.8,4),cf*CFrame.new(x,.4,0),trim,Enum.Material.Slate)
  P(parent,'GateColumn',Vector3.new(2.7,h,2.7),cf*CFrame.new(x,h/2,0),body,Enum.Material.Slate)
  P(parent,'GateCapital',Vector3.new(3.8,.85,3.8),cf*CFrame.new(x,h,0),trim,Enum.Material.Metal)
  if m=='Void'or m=='UFO'or m=='Crystal'or m=='Rainbow'or m=='Moon'then P(parent,'GateChannel',Vector3.new(.35,h-2,.18),cf*CFrame.new(x,h/2,1.43),glow,Enum.Material.Neon)end
  if level>=4 then lamp(parent,cf*CFrame.new(x,h+.5,0),d,.7,true)end
 end
 if m=='Bone'then G.Bone(parent,cf*CFrame.new(0,h+1,0),3.5,trim)
 elseif m=='Race'then
  B(parent,'GateWing',cf:PointToWorldSpace(Vector3.new(-9,h,0)),cf:PointToWorldSpace(Vector3.new(0,h+3,0)),1.1,trim)
  B(parent,'GateWing',cf:PointToWorldSpace(Vector3.new(9,h,0)),cf:PointToWorldSpace(Vector3.new(0,h+3,0)),1.1,trim)
  for _,x in ipairs({-12,12})do
   P(parent,'CheckeredFlagPole',Vector3.new(.25,7,.25),cf*CFrame.new(x,h-1,0),body)
   for a=0,3 do for b=0,2 do P(parent,'CheckeredFlag',Vector3.new(.7,.7,.12),cf*CFrame.new(x+(a-1.5)*.7,h+1-b*.7,0),(a+b)%2==0 and Color3.new(1,1,1)or Color3.new(.02,.02,.02))end end
  end
  G.Crest(parent,cf*CFrame.new(0,h+2.5,.3)*CFrame.Angles(0,math.pi,0),1.1,d)
 else
  for i=0,10 do local a=math.pi*(i+.5)/11;P(parent,'ArchStone',Vector3.new(3,2.2,2.6),cf*CFrame.new(math.cos(a)*9,h-1+math.sin(a)*4.5,0)*CFrame.Angles(0,0,a-math.pi/2),i%2==0 and body or body:Lerp(trim,.18),Enum.Material.Slate)end
  if m=='Rainbow'then for band=1,6 do G.Ring(parent,cf*CFrame.new(0,h-1,.5),8+band*.3,.25,Color3.fromHSV(band/7,.52,1),Enum.Material.Neon,0,math.pi,18)end end
  G.Crest(parent,cf*CFrame.new(0,h+3,1.5)*CFrame.Angles(0,math.pi,0),m=='Glitch'and 1.8 or 1.4,d)
 end
 if grand then for i=1,3 do P(parent,'EntryStep',Vector3.new(15+i*.8,.3,1.2),cf*CFrame.new(0,.15-i*.05,2+i),body:Lerp(trim,.3),Enum.Material.Slate)end end
end
local function showcase(parent,f,d,level,sx)
 sx=sx or 1
 local body,trim,glow,top=C.Color(d.Color),C.Color(d.Trim),C.Color(d.Glow),C.Color(d.Roof)
 local m=Instance.new('Model');m.Name='BestFinds';m:SetAttribute('Stage',level);m.Parent=parent
 -- Right side while entering the plot: the unused sixth kennel socket.
 local cf=f*CFrame.new(20*sx,0,55)*CFrame.Angles(0,math.pi,0);local premium=level>=6
 P(m,'ShowcaseFoundation',Vector3.new(23,.65,11),cf*CFrame.new(0,.33,0),body,premium and Enum.Material.Marble or Enum.Material.WoodPlanks)
 if level>=3 then P(m,'ShowcaseStep',Vector3.new(22,.32,2),cf*CFrame.new(0,.16,-6),trim,Enum.Material.Slate)end
 for _,x in ipairs({-11,11})do
  P(m,'ShowcaseColumn',Vector3.new(.85,10.5,.85),cf*CFrame.new(x,5.6,3.6),body,Enum.Material.Metal)
  if level>=4 then lamp(m,cf*CFrame.new(x,1,-3.6),d,.65,false)end
 end
 local slots=Instance.new('Folder');slots.Name='Slots';slots.Parent=m
 local letters=glow:Lerp(Color3.new(1,1,1),.52)
 for i,key in ipairs({'Find','Dog','Relic'})do local x=(2-i)*7.1;local height=key=='Dog'and 3 or 2.35
  P(m,'PedestalFoot',Vector3.new(6.2,.4,6.2),cf*CFrame.new(x,.9,0),trim,Enum.Material.Metal)
  P(m,'Pedestal',Vector3.new(5.6,height,5.6),cf*CFrame.new(x,1+height/2,0),body,premium and Enum.Material.Marble or Enum.Material.WoodPlanks)
  local accent=d.Motif=='Paw'and({Color3.fromRGB(255,224,80),Color3.fromRGB(238,149,222),Color3.fromRGB(255,208,101)})[i]or glow
  local platform=P(slots,key,Vector3.new(5.9,.22,5.9),cf*CFrame.new(x,1+height,0),accent:Lerp(body,level>=4 and .62 or .12),Enum.Material.SmoothPlastic)
  if level>=4 then
   for _,side in ipairs({-1,1})do
    P(m,'DisplayLight',Vector3.new(.10,.12,5.9),platform.CFrame*CFrame.new(side*2.91,.13,0),accent,Enum.Material.Neon)
    P(m,'DisplayLight',Vector3.new(5.9,.12,.10),platform.CFrame*CFrame.new(0,.13,side*2.91),accent,Enum.Material.Neon)
   end
  end
  G.Sign(m,cf*CFrame.new(x,2.15,-2.88),Vector3.new(5.1,1.25,.16),key:upper(),letters,'Category'..key)
  local caption=G.Sign(m,cf*CFrame.new(x,1.1,-3.05),Vector3.new(6.2,.55,.12),'MAKE YOUR FIRST DISCOVERY',letters,'Name'..key)
  platform:SetAttribute('CaptionName',caption.Name)
  if level>=7 then for _,side in ipairs({-1,1})do P(m,'DisplayTrim',Vector3.new(.14,height-.3,.12),cf*CFrame.new(x+side*2.6,1+height/2,-2.86),trim,Enum.Material.Metal)end end
 end
 local title=G.Sign(m,cf*CFrame.new(0,10.6,3.55),Vector3.new(23,2.6,.6),'MY BEST FINDS',letters,'ShowcaseTitle')
 local reverse=title.Lettering:Clone();reverse.Name='ReverseLettering';reverse.Face=Enum.NormalId.Back;reverse.Parent=title
 P(m,'TitleTopTrim',Vector3.new(23.5,.3,.9),cf*CFrame.new(0,12.05,3.55),glow,level>=6 and Enum.Material.Neon or Enum.Material.Metal)
 if level>=5 then roof(m,cf*CFrame.new(0,12.45,1.1),24,7,d,level)end
 if level>=8 then G.Crest(m,cf*CFrame.new(0,15,1.2),.8,d)end
 if level>=9 then for _,x in ipairs({-10,10})do G.Crest(m,cf*CFrame.new(x,7,3),.5,d)end end
 return m
end
local function garden(parent,f,d,level,sx)
 sx=sx or 1
 local body,trim,glow=C.Color(d.Color),C.Color(d.Trim),C.Color(d.Glow);local m=d.Motif
 if m=='Void'then
  -- A tall, fractured rift behind the service buildings, clear of every route.
  local cf=f*CFrame.new(0,31,-63)*CFrame.Angles(0,math.pi,0)
  P(parent,'VoidRift',Vector3.new(.7,25,19),cf*CFrame.Angles(0,math.pi/2,0),Color3.fromRGB(5,1,13),nil,Enum.PartType.Cylinder)
  G.Ring(parent,cf*CFrame.new(0,0,-.5),9.5,.22,glow,Enum.Material.Neon)
  for i=1,18 do local a=i*math.pi/9;local x,y=math.cos(a)*11,math.sin(a)*14
   local rock=P(parent,'RiftObsidian',Vector3.new(2.5+(i%3),5+i%3,3),cf*CFrame.new(x,y,0)*CFrame.Angles(0,.3*i,-a),body,Enum.Material.Slate);rock:SetAttribute('PlotFloat',true)
   B(parent,'RiftEnergy',cf:PointToWorldSpace(Vector3.new(x*.86,y*.87,-.4)),cf:PointToWorldSpace(Vector3.new(x*.74,y*.73,-.6)),.28,glow,Enum.Material.Neon)
  end
  for i=1,8 do local a=i*math.pi/4;B(parent,'RiftLightning',cf:PointToWorldSpace(Vector3.new(math.cos(a)*10,math.sin(a)*12,-.9)),cf:PointToWorldSpace(Vector3.new(math.cos(a+.12)*7,math.sin(a+.12)*8,-1)),.11,glow,Enum.Material.Neon)end
 elseif m=='UFO'then
  local cf=f*CFrame.new(-21*sx,23,-20)
  P(parent,'FlyingSaucer',Vector3.new(1.3,15,15),cf*CFrame.Angles(0,0,math.pi/2),trim,Enum.Material.Metal,Enum.PartType.Cylinder)
  P(parent,'SaucerDeck',Vector3.new(1.2,11,11),cf*CFrame.new(0,1,0)*CFrame.Angles(0,0,math.pi/2),body,Enum.Material.Metal,Enum.PartType.Cylinder)
  P(parent,'SaucerDome',Vector3.new(7,4,7),cf*CFrame.new(0,2,0),glow,Enum.Material.Glass,Enum.PartType.Ball).Transparency=.25
  G.Ring(parent,cf*CFrame.Angles(math.pi/2,0,0),6.5,.25,glow,Enum.Material.Neon)
  for i=1,8 do local a=i*math.pi/4;P(parent,'TractorRay',Vector3.new(.12,18,.12),cf*CFrame.new(math.cos(a)*4,-10,math.sin(a)*4),glow,Enum.Material.Neon).Transparency=.45 end
  P(parent,'LandingCircle',Vector3.new(.16,13,13),f*CFrame.new(-21*sx,.18,-20)*CFrame.Angles(0,0,math.pi/2),glow,Enum.Material.Neon,Enum.PartType.Cylinder).Transparency=.5
 elseif m=='Rainbow'then
  local cf=f*CFrame.new(-22*sx,10,-21)*CFrame.Angles(0,math.pi/2,0)
  for i=1,6 do G.Ring(parent,cf,7+i*.22,.26,Color3.fromHSV(i/7,.55,1),Enum.Material.Neon)end
 elseif m=='Clock'then
  for i=1,4 do local cf=f*CFrame.new(-20*sx,2,-8-i*9);G.Gear(parent,cf*CFrame.Angles(-math.pi/2,0,0),3,trim)end
 elseif m=='Treasure'then
  for i=1,3 do local cf=f*CFrame.new((-24+(i%2)*8)*sx,1.8,-12-i*10)
   P(parent,'ExpeditionChest',Vector3.new(5,3,3.5),cf,body,Enum.Material.WoodPlanks)
   for _,x in ipairs({-1.7,1.7})do P(parent,'ChestBand',Vector3.new(.4,3.2,3.7),cf*CFrame.new(x,0,0),trim,Enum.Material.Metal)end
   P(parent,'ChestLock',Vector3.new(.7,.9,.3),cf*CFrame.new(0,0,1.9),trim,Enum.Material.Metal)
  end
 elseif m=='Rock'then
  for i=1,9 do local a=f:PointToWorldSpace(Vector3.new((-23+(i%2)*3)*sx,.17,-4-i*4));local b=f:PointToWorldSpace(Vector3.new((-23+((i+1)%2)*3)*sx,.17,-8-i*4));B(parent,'EarthFault',a,b,1,Color3.fromRGB(28,20,18))end
 end
 for i=1,6 do local x=i%2==0 and -31 or 31;local z=52-math.floor(i/2)*29;local cf=f*CFrame.new(x,1,z)
  if m=='Crystal'then G.Cluster(parent,cf,level>=7 and 1 or .65,glow,trim)
  elseif m=='Rock'then G.Rock(parent,cf,1,body)
  elseif m=='Curse'then tree(parent,cf,d,.85)
  elseif m=='Bone'then G.Bone(parent,cf*CFrame.Angles(0,i,math.pi/2),.65,trim)
  elseif m=='Void'or m=='Glitch'then
   local rock=P(parent,'SuspendedShard',Vector3.new(2,3.8,2),cf*CFrame.new(0,10+i%3*2,0)*CFrame.Angles(i,i*.5,.4),body,Enum.Material.Slate);rock:SetAttribute('PlotFloat',true)
   P(parent,'ShardFracture',Vector3.new(.15,3.9,2.1),rock.CFrame,glow,Enum.Material.Neon):SetAttribute('PlotFloat',true)
  elseif m=='Sun'then G.Cluster(parent,cf,.65,trim,glow)
  elseif m=='Race'then
   P(parent,'TrafficConeFoot',Vector3.new(2,.25,2),cf,body)
   for j=1,3 do P(parent,'TrafficCone',Vector3.new(1.6-j*.35,.6,1.6-j*.35),cf*CFrame.new(0,j*.5,0),j==2 and trim or C.Color(d.Roof))end
  elseif level>=3 then
   P(parent,'GardenPlanter',Vector3.new(3,1.2,4),cf,body,Enum.Material.Slate)
   P(parent,'GardenShrub',Vector3.new(2.8,2,3.8),cf*CFrame.new(0,1.2,0),Color3.fromRGB(55,103,65),Enum.Material.Grass,Enum.PartType.Ball)
  end
 end
 if m=='Void'or m=='Curse'then
  for i=1,3 do
   local origin=P(parent,'MistOrigin',Vector3.one,f*CFrame.new(i==2 and 28 or -28,1,35-i*28),body);origin.Transparency=1
   local mist=Instance.new('ParticleEmitter');mist.Name='EstateMist';mist.Texture='rbxasset://textures/particles/smoke_main.dds'
   mist.Color=ColorSequence.new(glow);mist.LightEmission=.18;mist.Rate=2;mist.Lifetime=NumberRange.new(6,9);mist.Speed=NumberRange.new(.4,1.3)
   mist.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,12),NumberSequenceKeypoint.new(1,25)})
   mist.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.25,.9),NumberSequenceKeypoint.new(1,1)})
   mist.SpreadAngle=Vector2.new(180,180);mist.Rotation=NumberRange.new(0,360);mist.RotSpeed=NumberRange.new(-8,8);mist:SetAttribute('PlotMist',true);mist.Parent=origin
  end
 end
 if level>=8 and m~='UFO'and m~='Rainbow'then
  local cf=f*CFrame.new(-20*sx,0,-23)
  for _,x in ipairs({-6,6})do for _,z in ipairs({-6,6})do P(parent,'GardenColumn',Vector3.new(.8,8,.8),cf*CFrame.new(x,4,z),trim,Enum.Material.Slate)end end
  roof(parent,cf*CFrame.new(0,8.3,0),15,15,d,level)
 end
 if level>=9 then
  local cf=f*CFrame.new(-20*sx,0,-43)
  for i=1,3 do P(parent,'MonumentStep',Vector3.new(10-i*1.5,.7,10-i*1.5),cf*CFrame.new(0,i*.7,0),body:Lerp(trim,i*.15),Enum.Material.Marble)end
  G.Crest(parent,cf*CFrame.new(0,5.2,0)*CFrame.Angles(0,math.pi,0),1.25,d)
 end
end
function A.Apply(yard,level,id)
 if not yard:FindFirstChild('YardLandscape')then return end
 level=math.clamp(level,1,9);id=C.Skins[id]and id or 'Classic';local token=level..':'..id
 if cache[yard]==token and yard:FindFirstChild('PlotDevelopment')then return end
 local old=yard:FindFirstChild('PlotDevelopment');if old then old:Destroy()end
 local deco=Instance.new('Model');deco.Name='PlotDevelopment';deco.Parent=yard
 local d=C.Skins[id];local themed=id~='Classic';local f=A.Frame(yard);local body,top,trim,glow=C.Color(d.Color),C.Color(d.Roof),C.Color(d.Trim),C.Color(d.Glow)
 local dark=d.Motif=='Void'or d.Motif=='Glitch'or d.Motif=='Curse'or d.Motif=='Moon'
 for _,groupName in ipairs({'YardLandscape','DogStorage','Vendor','Workshop','StorageRoofMascot'})do
  local group=yard:FindFirstChild(groupName)
  if group then for _,p in ipairs(group:GetDescendants())do if p:IsA('BasePart')then
   local skip=false;local cur=p.Parent
   while cur and cur~=group do if cur:FindFirstChildOfClass('Humanoid')or cur:GetAttribute('PlotShowcase')then skip=true;break end;cur=cur.Parent end
   if not skip then
    remember(p);p.Color=p:GetAttribute('PlotBaseColor');p.Material=Enum.Material[p:GetAttribute('PlotBaseMaterial')]
    local n=p.Name;local visible=true
    if groupName=='StorageRoofMascot'then visible=not themed and level>=7
    elseif n=='Post'or n=='Rail'or n=='EntryPillar'or n=='LanternPost'or n=='WarmLantern'or n=='LanternCap'then visible=false
    elseif themed and(n:find('Roof')or n=='Canopy'or n=='MascotPlinth')then visible=false end
    show(p,visible)
    if n:find('Roof')or n:find('Canopy')then p.Color=top
    elseif n:find('Trim')or n:find('Cornice')or n:find('Pier')or n:find('Sill')then p.Color=trim;p.Material=Enum.Material.Metal
    elseif n:find('Wall')or n:find('Cabinet')or n:find('Panel')or n:find('Foundation')and n~='YardFoundation'then p.Color=body
    elseif n=='EntryWalk'or n=='UtilityApron'then p.Color=dark and body:Lerp(trim,.12)or level>=6 and Color3.fromRGB(192,183,160)or Color3.fromRGB(133,114,88);p.Material=level>=6 and Enum.Material.Cobblestone or Enum.Material.Ground
    elseif n=='WorkArea'or n=='CosmeticGarden'or n=='YardFoundation'then p.Color=dark and Color3.fromRGB(49,63,51)or Color3.fromRGB(77,132,57);p.Material=Enum.Material.Grass
    elseif n:find('Lens')or n=='PadTrim'then p.Color=glow end
   end
  end end end
 end
 for i=1,5 do local slot=yard:FindFirstChild('DigSlot_'..i)
  if slot then local unlocked=i<=C.Stages[level].Slots;slot:SetAttribute('Unlocked',unlocked);slot:SetAttribute('RequiredYardLevel',i)
   for _,p in ipairs(slot:GetDescendants())do
    if p:IsA('BasePart')and not p:FindFirstAncestor('ActiveDog')then
     show(p,unlocked and not(themed and p.Name=='KennelRoof'))
     if p.Name=='KennelRoof'then p.Color=top elseif p.Name=='PitTimber'or p.Name=='SlotMarker'then p.Color=trim elseif p.Name:find('Kennel')then p.Color=body;p.Material=level>=6 and Enum.Material.Slate or Enum.Material.WoodPlanks end
    elseif p:IsA('ProximityPrompt')then p.Enabled=unlocked
    elseif p:IsA('SurfaceGui')or p:IsA('BillboardGui')then p.Enabled=unlocked end
   end
   local floor=slot:FindFirstChild('KennelFloor');local pit=slot:FindFirstChild('DarkExcavation')
   if floor and unlocked then
    local cf=floor.CFrame;local front=slot:FindFirstChild('KennelLintel');if front then cf=CFrame.lookAt(floor.Position,Vector3.new(front.Position.X,floor.Position.Y,front.Position.Z))end
    if themed then roof(deco,cf*CFrame.new(0,6.8,0),10,9,d,level)end
    if level>=3 or themed then
     P(deco,'KennelPlinth',Vector3.new(9.2,.4,8.8),cf*CFrame.new(0,-.05,0),trim,Enum.Material.Slate)
     for _,x in ipairs({-4,4})do P(deco,'KennelPillar',Vector3.new(.55,6.1,.55),cf*CFrame.new(x,3.1,-3.6),trim,Enum.Material.Metal)end
     G.Crest(deco,cf*CFrame.new(0,5,-3.9),.35,d)
    end
    if pit then
     local center=f:PointToObjectSpace(pit.Position);local pc=f*CFrame.new(center.X,.24,center.Z)
     for _,x in ipairs({-6.5,6.5})do P(deco,'DigBorder',Vector3.new(.28,.15,13),pc*CFrame.new(x,0,0),dark and glow or trim,dark and Enum.Material.Neon or Enum.Material.Slate)end
     for _,z in ipairs({-6.5,6.5})do P(deco,'DigBorder',Vector3.new(13,.15,.28),pc*CFrame.new(0,0,z),dark and glow or trim,dark and Enum.Material.Neon or Enum.Material.Slate)end
    end
   elseif pit then
    P(deco,'FutureGarden',Vector3.new(12,.16,12),CFrame.new(pit.Position.X,1.26,pit.Position.Z),dark and Color3.fromRGB(49,63,51)or Color3.fromRGB(69,122,57),Enum.Material.Grass)
    local p=G.Sign(deco,CFrame.new(pit.Position.X,1.4,pit.Position.Z)*f.Rotation*CFrame.Angles(-math.pi/2,0,0),Vector3.new(5.5,3,.15),'KENNEL '..i..' / LV '..i,trim)
   end
  end
 end
 if level>=2 or themed then fence(deco,f,d,level)end
 if level>=4 or themed then gate(deco,f,d,level)end
 if themed then for _,n in ipairs({'DogStorage','Vendor','Workshop'})do local building=yard:FindFirstChild(n);local highest
  if building then for _,p in ipairs(building:GetDescendants())do if p:IsA('BasePart')and(p.Name=='Roof'or p.Name=='Canopy')and(not highest or p.Position.Y>highest.Position.Y)then highest=p end end end
  if highest then roof(deco,highest.CFrame,highest.Size.X+1,highest.Size.Z+1,d,level)end
 end end
 if level>=4 then for _,x in ipairs({-7,7})do for i=1,level>=8 and 5 or 3 do lamp(deco,f*CFrame.new(x,0,57-i*20),d,.8,i==1)end end end
 if level>=6 or themed then
  for i=1,16 do P(deco,'WalkTileJoint',Vector3.new(8.3,.06,.09),f*CFrame.new(0,.15,61-i*7),trim,Enum.Material.Metal)end
  for _,x in ipairs({-4.35,4.35})do P(deco,'WalkBorder',Vector3.new(.18,.1,116),f*CFrame.new(x,.17,3),dark and glow or trim,dark and Enum.Material.Neon or Enum.Material.Metal)end
 end
 -- Yards on the east side are mirrored: their kennels and lucky pads sit on the other
 -- side of the frame, so the showcase and skin garden must mirror with them.
 local sx=1;local first=yard:FindFirstChild('DigSlot_1');local firstPit=first and first:FindFirstChild('DarkExcavation')
 if firstPit and f:PointToObjectSpace(firstPit.Position).X>0 then sx=-1 end
 garden(deco,f,d,level,sx);showcase(deco,f,d,level,sx)
 G.Sign(deco,f*CFrame.new(-13,2.5,65)*CFrame.Angles(0,math.pi,0),Vector3.new(7,1.5,.3),'LV '..level..' / '..C.Stages[level].Name,trim,'EstateLevel')
 yard:SetAttribute('PlotStage',level);yard:SetAttribute('PlotSkin',id);yard:SetAttribute('UnlockedKennels',C.Stages[level].Slots);yard:SetAttribute('AppearanceRevision',(yard:GetAttribute('AppearanceRevision')or 0)+1)
 cache[yard]=token
end
function A.Preview(source,level,id)
 local clone=source:Clone();clone.Name='PlotPreview'
 for _,o in ipairs(clone:GetDescendants())do if o:IsA('LuaSourceContainer')or o:IsA('ProximityPrompt')or o:IsA('Sound')or o:IsA('ParticleEmitter')or o:IsA('BillboardGui')then o:Destroy()elseif o:IsA('BasePart')then o.Anchored=true;o.CanCollide=false end end
 A.Apply(clone,level,id)
 for _,o in ipairs(clone:GetDescendants())do if o:IsA('LayerCollector')then o:Destroy()end end
 return clone
end
return A

-- Studio Edit installer. Builds on the saved District Refresh and can be undone independently.
local I={Version='2026-10-01.6'}
local PREFIX='AttractionRefresh_'
local ROOT='37_AttractionRefresh'
local C=Color3.fromRGB
local P={Navy=C(22,32,62),Ink=C(18,25,45),Cream=C(255,242,208),White=C(255,252,239),Gold=C(255,185,37),LightGold=C(255,216,91),Orange=C(244,116,32),Purple=C(114,49,195),Violet=C(176,92,240),Teal=C(13,172,161),Blue=C(38,107,228),Pink=C(244,83,151),Stone=C(214,208,185)}
local properties={'Transparency','CanCollide','CanTouch','CanQuery','CastShadow','Enabled','Visible','Color','Material','Reflectance','CFrame','Size','Text','TextColor3','FontFace','SizingMode','PixelsPerStud','ClipsDescendants'}
local function map()return workspace:WaitForChild('DOGROTS_District')end
local function edit(o,k,v)
 local a=PREFIX..k
 if o:GetAttribute(a)==nil then
  if k=='FontFace'then o:SetAttribute(a,o.FontFace.Family);o:SetAttribute(a..'Weight',o.FontFace.Weight.Name);o:SetAttribute(a..'Style',o.FontFace.Style.Name)
  else o:SetAttribute(a,typeof(o[k])=='EnumItem'and o[k].Name or o[k])end
 end
 o:SetAttribute(PREFIX..'Edited',true);o[k]=v
end
local function hide(o)
 if o:IsA('BasePart')then
  edit(o,'Transparency',1);edit(o,'CanCollide',false);edit(o,'CanTouch',false);edit(o,'CanQuery',false);edit(o,'CastShadow',false)
 elseif o:IsA('Highlight')then edit(o,'Enabled',false)
 elseif o:IsA('GuiBase3d')then edit(o,'Visible',false)
 elseif o:IsA('SurfaceGui')or o:IsA('BillboardGui')or o:IsA('Light')or o:IsA('ParticleEmitter')or o:IsA('Beam')or o:IsA('Trail')or o:IsA('ProximityPrompt')then edit(o,'Enabled',false)end
end
local function hideTree(o)if not o then return end;hide(o);for _,d in ipairs(o:GetDescendants())do hide(d)end end
local function assertEdit()assert(game:GetService('RunService'):IsStudio()and not game:GetService('RunService'):IsRunning(),'Run this installer in Studio Edit mode')end
-- One shared geometry builder for full installation and the reversible reward machine-only delta.
local function buildRewardMachine(parent,counts)
 local rewardConfig=require(game.ReplicatedStorage.RewardMachineConfig)
 local rewards=rewardConfig.Rewards;local prizeCount=#rewards
 local exactOdds=require(game.ReplicatedStorage.RewardMachineOdds).Build(rewards,rewardConfig.OddsDenominator)
 local function model(p,n)local o=Instance.new('Model');o.Name=n;o.Parent=p;return o end
 local function part(p,n,cf,size,col,mat,solid,class)
  local o=Instance.new(class or 'Part');o.Name=n;o.Size=size;o.CFrame=cf;o.Color=col or P.Navy;o.Material=mat or Enum.Material.SmoothPlastic
  o.Anchored=true;o.CanCollide=solid==true;o.CanTouch=false;o.CanQuery=solid==true;o.CastShadow=solid==true;o.TopSurface=Enum.SurfaceType.Smooth;o.BottomSurface=Enum.SurfaceType.Smooth;o.Parent=p;counts.Parts+=1;return o
 end
 local function label(p,n,text,pos,size,col)
  local t=Instance.new('TextLabel');t.Name=n;t.BackgroundTransparency=1;t.Position=pos;t.Size=size;t.Text=text;t.Font=Enum.Font.FredokaOne;t.TextScaled=true;t.TextWrapped=true;t.TextColor3=col or P.Cream;t.ClipsDescendants=true;t.Parent=p;return t
 end
 local function surface(p,n)
  local g=Instance.new('SurfaceGui');g.Name=n or 'Lettering';g.Face=Enum.NormalId.Front;g.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;g.PixelsPerStud=22;g.LightInfluence=0;g.Parent=p;return g
 end
 local function sign(p,n,cf,w,h,text,col,ink)
  local o=part(p,n,cf,Vector3.new(w,h,.28),col or P.Navy);local g=surface(o)
  label(g,'Title',text,UDim2.fromScale(.035,.05),UDim2.fromScale(.93,.90),ink);return o,g
 end
 local function cylinder(p,n,cf,diam,depth,col,solid)
  local o=part(p,n,cf*CFrame.Angles(0,math.pi/2,0),Vector3.new(depth,diam,diam),col,nil,solid);o.Shape=Enum.PartType.Cylinder;return o
 end
 local function triangle(p,n,a,b,c,thickness,col)
  local ab,ac,bc=b-a,c-a,c-b
  if ab:Dot(ab)>ac:Dot(ac)and ab:Dot(ab)>bc:Dot(bc)then c,a=a,c elseif ac:Dot(ac)>bc:Dot(bc)then a,b=b,a end
  ab,ac,bc=b-a,c-a,c-b;local right=ac:Cross(ab).Unit;local up=bc:Cross(right).Unit;local back=bc.Unit
  local h=math.abs(ab:Dot(up));local d1=math.abs(ab:Dot(back));local d2=math.abs(ac:Dot(back))
  if h>.001 and d1>.001 then part(p,n,CFrame.fromMatrix((a+b)/2,right,up,back),Vector3.new(thickness,h,d1),col,nil,false,'WedgePart')end
  if h>.001 and d2>.001 then part(p,n,CFrame.fromMatrix((a+c)/2,-right,up,-back),Vector3.new(thickness,h,d2),col,nil,false,'WedgePart')end
 end
 local base=CFrame.new(-154,0,630)*CFrame.Angles(0,-math.pi/2,0)
 local function cb(p,n,x,y,z,sx,sy,sz,col,mat,solid)return part(p,n,base*CFrame.new(x,y,z),Vector3.new(sx,sy,sz),col,mat,solid)end
 local function cs(p,n,x,y,z,w,h,text,col,ink)return sign(p,n,base*CFrame.new(x,y,z),w,h,text,col,ink)end
 local function bar(p,n,a,b,width,depth,col)
  local delta=b-a;local cf=CFrame.lookAt((a+b)/2,b)*CFrame.Angles(math.pi/2,0,0)
  return part(p,n,cf,Vector3.new(width,delta.Magnitude,depth),col)
 end
 local function light(p,col,brightness,range)
  local l=Instance.new('PointLight');l.Color=col;l.Brightness=brightness;l.Range=range;l.Shadows=false;l.Parent=p;return l
 end
 local function paw(p,cf,scale,col)
  -- A three-dimensional stepped pad with four distinct toes, each with visible side walls.
  local function b(n,x,y,z,sx,sy,sz,c)return part(p,n,cf*CFrame.new(x*scale,y*scale,z*scale),Vector3.new(sx,sy,sz)*scale,c)end
  b('PawPadBack',0,0,.4,8,5.8,2.6,P.Navy);b('PawPad',0,0,-1.0,7.2,5.1,1.2,col)
  b('PawPadLower',0,-2.6,.2,5.8,1.8,2.6,P.Navy);b('PawPadLowerGold',0,-2.5,-1.0,5.2,1.5,1.2,col)
  for _,xy in ipairs({{-5,3},{-1.9,5.4},{1.9,5.4},{5,3}})do
   b('PawToeBack',xy[1],xy[2],.3,2.7,3.4,2.8,P.Navy)
   b('PawToeGold',xy[1],xy[2],-1.2,2.2,2.9,1.0,col)
   b('PawToeGlint',xy[1]-.45,xy[2]+.8,-1.73,.55,.7,.12,P.Cream)
  end
 end
 local rig=model(parent,'RewardMachineRig');rig.ModelStreamingMode=Enum.ModelStreamingMode.Persistent;rig.WorldPivot=base
 rig:SetAttribute('AnimationAxis','LocalZ');rig:SetAttribute('PrizeCount',prizeCount);rig:SetAttribute('WheelRadius',24);rig:SetAttribute('WinningPosition','Top');rig:SetAttribute('GeometryVersion','2026-10-01.6')
 local before=counts.Parts
 local deck=model(rig,'ArchitecturalBase')
 cb(deck,'Foundation',0,.6,1,112,1.2,33,P.Navy,nil,true)
 cb(deck,'GoldFoundationBand',0,1.35,1,108,.3,30,P.Gold)
 cb(deck,'RaisedPedestal',0,4,2,38,5,24,P.Purple,nil,true)
 cb(deck,'PedestalCap',0,7.3,2,42,1.6,26,P.Gold,nil,true)
 cb(deck,'PedestalInset',0,4,-10.3,32,3,.55,P.Blue)
 cs(deck,'WheelCaption',0,4,-10.75,30,2.5,'ACTIVATE • REVEAL • COLLECT',P.Navy,P.LightGold)
 -- The rear spine, side piers and upper arch visibly support a wheel with a real axle.
 cb(deck,'AxleBackbone',0,24,8,11,34,10,P.Navy,nil,true)
 cb(deck,'AxleSpineInset',0,24,13.1,6,28,.45,P.Purple)
 cylinder(deck,'AxleBearing',base*CFrame.new(0,40,7.4),12,10,P.Gold)
 cylinder(deck,'RearAxleCap',base*CFrame.new(0,40,14),8,3,P.Purple)
 local arch=model(rig,'GrandArch')
 for _,side in ipairs({-1,1})do
  cb(arch,'ArchFoot',side*31,3,5,12,4,18,P.Gold,nil,true)
  cb(arch,'ArchPier',side*31,23,5,6,36,11,P.Purple,nil,true)
  cb(arch,'ArchPierInset',side*31,23,-.7,2.3,33,.6,P.Blue)
 end
 for j=0,23 do
  local a=(j+.5)*math.pi/24;local x=math.cos(a)*31;local y=40+math.sin(a)*31
  local cf=base*CFrame.new(x,y,4)*CFrame.Angles(0,0,a-math.pi/2)
  part(arch,'ArchStructuralBlock',cf,Vector3.new(4.15,4.0,10),P.Purple,nil,true)
  part(arch,'ArchGoldFace',cf*CFrame.new(0,0,-5.3),Vector3.new(4.0,1.0,.65),P.Gold)
 end
 -- A large vertical wheel, with eight disjoint annular wedges and an extruded gold rim.
 local drumCF=base*CFrame.new(0,40,0);local drum=model(rig,'SpinningDrum');drum.WorldPivot=drumCF
 cylinder(drum,'WheelBack',drumCF*CFrame.new(0,0,2.9),49.0,2.0,P.Navy)
 -- Reward geometry and percentages use the shared configured pool.
 local accents={C(244,113,31),C(13,182,162),C(162,62,219),C(46,124,235),C(224,59,114),C(248,166,29),C(64,170,73),C(53,92,216),C(255,95,210)}
 local function localPoint(theta,r,z)return drumCF:PointToWorldSpace(Vector3.new(-math.sin(theta)*r,math.cos(theta)*r,z or 0))end
 local function propBlock(p,n,cf,x,y,z,sx,sy,sz,col)return part(p,n,cf*CFrame.new(x,y,z),Vector3.new(sx,sy,sz),col)end
 local function dogSymbol(p,cf,body,ear)
  propBlock(p,'DogHead',cf,0,0,-.6,4.1,3.8,2.9,body)
  propBlock(p,'DogMuzzle',cf,0,-.8,-2.4,2.5,1.4,1.1,P.Cream)
  propBlock(p,'DogNose',cf,0,-.4,-3.0,.85,.6,.28,P.Ink)
  for _,s in ipairs({-1,1})do
   propBlock(p,'DogEar',cf,s*2.2,.2,-.4,1.1,3.7,2.2,ear)
   propBlock(p,'DogEye',cf,s*.95,.65,-2.09,.54,.67,.2,P.Ink)
   propBlock(p,'DogEyeGlint',cf,s*.88,.82,-2.21,.16,.18,.07,P.White)
  end
 end
 for i=1,prizeCount do
  local theta=(i-1)*2*math.pi/prizeCount;local sector=model(drum,'Sector_'..i);sector:SetAttribute('PrizeIndex',i)
  for j=0,3 do
   local a=theta-math.pi/prizeCount+j*math.pi/(2*prizeCount);local b=a+math.pi/(2*prizeCount)
   local p1,p2,p3,p4=localPoint(a,4.8),localPoint(a,24),localPoint(b,24),localPoint(b,4.8)
   triangle(sector,'ColoredWedge',p1,p2,p3,5,accents[i]);triangle(sector,'ColoredWedge',p1,p3,p4,5,accents[i])
  end
  local border=theta-math.pi/prizeCount
  local borderCF=drumCF*CFrame.Angles(0,0,border)*CFrame.new(0,14.4,-2.95)
  part(drum,'SectorDivider',borderCF,Vector3.new(.42,19.2,.9),P.Gold)
  -- The title is tangential: applying target=-theta leaves the selected text upright.
  local faceCF=drumCF*CFrame.Angles(0,0,theta)*CFrame.new(0,17.4,-3.1)
  local face=part(drum,'PrizeFace_'..i,faceCF,Vector3.new(10.0,3.6,.45),P.Navy);face:SetAttribute('PrizeIndex',i)
  local g=surface(face);label(g,'Title',rewards[i]and rewards[i].Name or('REWARD '..i),UDim2.fromScale(.04,.05),UDim2.fromScale(.92,.56),P.Cream)
  label(g,'Subtitle',exactOdds[i].ChanceText..' CHANCE',UDim2.fromScale(.05,.67),UDim2.fromScale(.90,.24),P.LightGold)
  local icon=model(sector,'RewardSymbol');local cf=drumCF*CFrame.Angles(0,0,theta)*CFrame.new(0,10.0,-3.0)
  if i<=3 then
   dogSymbol(icon,cf,i==1 and P.Orange or i==2 and C(133,81,47)or P.Purple,i==3 and P.Pink or C(105,52,26))
   if i==2 then propBlock(icon,'CoffeeCup',cf,0,2.55,-.5,2.2,1.4,2.0,P.Cream)
   elseif i==3 then
    for _,s in ipairs({-1,1})do propBlock(icon,'HeadphoneCup',cf,s*2.75,.1,-.3,.7,2.1,2.5,P.Blue)end
    propBlock(icon,'HeadphoneBridge',cf,0,2.45,-.3,5.5,.55,1.4,P.Blue)
   end
  elseif i==4 then
   propBlock(icon,'Tag',cf,0,0,-.3,3.7,5,1.0,P.LightGold)
   propBlock(icon,'TagNeck',cf,0,3,-.3,1.6,1.3,1,P.Gold)
   paw(icon,cf*CFrame.new(0,-.25,-.75),.24,P.Orange)
  elseif i==5 then
   propBlock(icon,'TreasureBox',cf,0,-.3,-.4,5.9,3.9,3.1,P.Orange)
   propBlock(icon,'TreasureLid',cf,0,2,-.4,6.2,.7,3.4,P.Gold)
   for _,s in ipairs({-1,1})do propBlock(icon,'ChestBand',cf,s*1.95,-.3,-2.04,.5,4.3,.25,P.Gold)end
   propBlock(icon,'ChestLatch',cf,0,.3,-2.2,1.2,1.4,.4,P.Cream)
  elseif i==6 then
   for _,x in ipairs({-1.6,1.6})do
    cylinder(icon,'GoldCoin',cf*CFrame.new(x,x*.3,-.9),4,1.0,P.Gold)
    cylinder(icon,'CoinInset',cf*CFrame.new(x,x*.3,-1.46),3.3,.15,P.LightGold)
   end
  elseif i==7 then
   propBlock(icon,'BoneStem',cf,0,0,-.7,5.2,1.2,1.4,P.Cream)
   for _,x in ipairs({-2.25,2.25})do for _,y in ipairs({-.6,.6})do propBlock(icon,'BoneEnd',cf,x,y,-.7,1.7,1.5,1.8,P.White)end end
  elseif i==9 then
   dogSymbol(icon,cf,P.Violet,P.Teal)
   paw(icon,cf*CFrame.new(0,2.8,-1),.32,P.LightGold)
  else
   propBlock(icon,'EnergyBottle',cf,0,-.4,-.7,3.5,4.9,2.3,P.Teal)
   propBlock(icon,'BottleCap',cf,0,2.5,-.7,2.6,1,2,P.LightGold)
   for j=0,2 do propBlock(icon,'LightningBolt',cf,(j-1)*.55,1-j*.8,-1.92,1.3,1.0,.25,P.Gold)end
  end
 end
 for j=0,63 do
  local a=j*2*math.pi/64;local cf=drumCF*CFrame.Angles(0,0,a)*CFrame.new(0,25.2,0)
  part(drum,'GoldOuterRim',cf,Vector3.new(2.51,2.4,6.1),P.Gold)
  part(drum,'RimInset',cf*CFrame.new(0,0,-3.13),Vector3.new(2.45,.45,.24),P.Cream)
 end
 for j=0,31 do
  local a=j*math.pi/16;local cf=drumCF*CFrame.Angles(0,0,a)*CFrame.new(0,25.3,-3.6)
  cylinder(drum,'BulbSocket',cf,1.25,.40,P.Orange)
  local bulb=cylinder(drum,'RimBulb',cf*CFrame.new(0,0,-.26),.83,.3,P.Cream);bulb.Material=Enum.Material.Neon
 end
 cylinder(drum,'HubGold',drumCF*CFrame.new(0,0,-3.0),10.2,2.0,P.Gold)
 cylinder(drum,'HubFace',drumCF*CFrame.new(0,0,-4.2),8.6,.65,P.Navy)
 paw(drum,drumCF*CFrame.new(0,-.4,-5),.45,P.Gold)
 -- The pointer is fixed above the number-one/top sector; it never travels with the wheel.
 local winning=model(rig,'WinningFrame');winning:SetAttribute('Target','Top');winning.WorldPivot=base*CFrame.new(0,66.6,-6)
 cb(winning,'PointerSocket',0,69.1,-6,8.3,2.6,3.5,P.Navy)
 local a=base:PointToWorldSpace(Vector3.new(-3.8,68.5,-7));local b=base:PointToWorldSpace(Vector3.new(3.8,68.5,-7));local c=base:PointToWorldSpace(Vector3.new(0,63,-7))
 triangle(winning,'PrizePointer',a,b,c,1.2,P.Gold)
 local pointerGlint=cb(winning,'PointerLight',0,68.9,-7.8,3.1,.5,.35,P.Cream,Enum.Material.Neon);light(pointerGlint,P.Gold,.45,15)
 -- Deep marquee/crown, separated from the wheel and its arrow rather than overlaying a prize.
 cb(arch,'MarqueeBridge',0,74,2,65,6,11,P.Navy,nil,true)
 cb(arch,'MarqueeGoldFrame',0,74,-3.8,60,5.7,.8,P.Gold)
 cs(arch,'RewardMachineSign',0,74,-4.4,57.5,4.4,'DOG-O-MATIC',P.Purple,P.Cream)
 local crown=model(rig,'PawCrown');paw(crown,base*CFrame.new(0,82,1),1.35,P.Gold)
 cb(crown,'CrownNeck',0,78.6,1,7,5,5,P.Gold,nil,true)
 for _,side in ipairs({-1,1})do
  part(crown,'CrownWing',base*CFrame.new(side*18,81,2)*CFrame.Angles(0,0,-side*.23),Vector3.new(13,2.2,5),P.Gold)
  part(crown,'CrownWingInset',base*CFrame.new(side*18,81,-.7)*CFrame.Angles(0,0,-side*.23),Vector3.new(9,1.0,.4),P.Cream)
 end
 -- Side towers make the silhouette an attraction: layered plinths, tall flutes and raised paws.
 local displays=model(rig,'RewardVitrines')
 for _,side in ipairs({-1,1})do
  local x=side*43;local tower=model(displays,side<0 and'TreatTower'or'TreasureTower')
  cb(tower,'TowerFoot',x,2,1,23,2.5,27,P.Gold,nil,true)
  cb(tower,'TowerBody',x,22,3,17,38,18,P.Purple,nil,true)
  cb(tower,'TowerInset',x,24,-6.25,14,32,.55,P.Blue)
  for _,dx in ipairs({-8.7,8.7})do cb(tower,'TowerFlute',x+dx,22,-6.4,1.6,38,1.6,P.Gold)end
  for _,y in ipairs({7,20,37,42})do cb(tower,'TowerCornice',x,y,1,21,1.1,25,P.Gold,nil,true)end
  cb(tower,'TowerCap',x,44,1,18,3,21,P.Navy,nil,true)
  cb(tower,'PawPedestal',x,46.75,1,4,3.2,4,P.Gold,nil,true)
  paw(tower,base*CFrame.new(x,51,-1),.95,side<0 and P.Teal or P.Pink)
  for _,y in ipairs({13.5,28.5})do
   cb(tower,'DisplayShelf',x,y-5.5,-8,16,.6,10,P.Cream,nil,true)
   local glass=cb(tower,'ClearVitrine',x,y,-12.9,14.5,10.2,.15,P.White,Enum.Material.Glass);glass.Transparency=.96;glass.CastShadow=false
  end
  local dogCF=base*CFrame.new(x,13,-9);dogSymbol(tower,dogCF,side<0 and P.Orange or P.Purple,side<0 and C(129,64,27)or P.Pink)
  if side<0 then
   for _,dx in ipairs({-3,3})do cylinder(tower,'DisplayCoin',base*CFrame.new(x+dx,28.5,-8.5),5,1,P.Gold)end
  else
   cb(tower,'DisplayChest',x,28,-9,8,5,5.5,P.Orange);cb(tower,'DisplayChestLid',x,30.8,-9,8.3,.65,5.8,P.Gold)
   for _,dx in ipairs({-2.7,2.7})do cb(tower,'DisplayChestBand',x+dx,28,-11.85,.7,5.5,.35,P.Gold)end
  end
  cs(tower,'TowerTitle',x,40,-12.8,18.4,2.8,side<0 and 'RARE FINDS'or'BIG REWARDS',P.Purple,P.Cream)
  cs(tower,'PrizePlaque',x,6.9,-12.8,17,1.8,'MEET YOUR NEXT DOG',P.Navy,P.Cream)
  local lens=cb(tower,'TowerFootlight',x,4.5,-12.5,9,.5,.8,side<0 and P.Teal or P.Pink,Enum.Material.Neon)
  light(lens,side<0 and P.Teal or P.Pink,.65,20)
 end
 local stage=model(rig,'RevealStage');local stageBase=CFrame.new(-119,0,630)*CFrame.Angles(-math.pi/2,0,0)
 cylinder(stage,'StageBase',stageBase*CFrame.new(0,0,.65),31,.60,P.Navy,true)
 cylinder(stage,'StageGoldEdge',stageBase*CFrame.new(0,0,1.02),29.4,.14,P.Gold,true)
 cylinder(stage,'StageTop',stageBase*CFrame.new(0,0,1.14),28.8,.10,P.Purple,true)
 local orbit=model(rig,'OrbitLights')
 for i=0,23 do
  local a=i*math.pi/12;local cf=CFrame.new(-119+math.cos(a)*14.15,1.32,630+math.sin(a)*14.15)
  local p=part(orbit,'OrbitLight_'..(i+1),cf,Vector3.new(.65,.30,.65),P.Cream,Enum.Material.Neon);p:SetAttribute('OrbitIndex',i+1)
 end
 part(stage,'EntryStep',CFrame.new(-103.2,.63,630),Vector3.new(3.2,.30,16),P.Orange,nil,true)
 part(stage,'ProcessionCarpet',CFrame.new(-67.8,.43,630),Vector3.new(67.6,.14,20),P.Purple,Enum.Material.Fabric,true)
 for _,z in ipairs({619.75,640.25})do part(stage,'CarpetGoldEdge',CFrame.new(-67.8,.48,z),Vector3.new(67.6,.06,.5),P.Gold)end
 -- Keep the reveal board under the wheel; the floating physical reward owns the central stage.
 sign(rig,'WorldResult',base*CFrame.new(0,11.5,-23.5),29,4.5,'READY TO ACTIVATE',P.Navy,P.Cream)
 -- Separate broad information stands have square pixels and eight readable rows.
 local boardCF=CFrame.new(-110,13.4,680)*CFrame.Angles(0,-math.pi/2,0)
 local board,g=sign(rig,'StatusBoard',boardCF,32,21.6,'',P.Navy,P.Cream);g.Name='OddsDisplay';g.Title:Destroy()
 label(g,'Title','REWARD CHANCES',UDim2.fromScale(.055,.035),UDim2.fromScale(.89,.105),P.Gold)
 label(g,'Status','ONE DOG TOKEN • ONE REWARD',UDim2.fromScale(.055,.16),UDim2.fromScale(.89,.10),P.Cream)
 local rows=Instance.new('Frame');rows.Name='Rows';rows.BackgroundTransparency=1;rows.Position=UDim2.fromScale(.055,.30);rows.Size=UDim2.fromScale(.89,.65);rows.ClipsDescendants=true;rows.Parent=g
 -- Exact slot allocation includes the required Aurion slot.
 for i=1,prizeCount do local r=exactOdds[i];local text=r and(r.Name..'  '..r.ChanceText)or'';local row=label(rows,'Row'..i,text,UDim2.fromScale(0,(i-1)/prizeCount),UDim2.fromScale(1,.102),i%2==0 and P.Cream or P.LightGold);row.TextXAlignment=Enum.TextXAlignment.Left end
 local ticket,tg=sign(rig,'TicketRules',CFrame.new(-110,13.4,580)*CFrame.Angles(0,-math.pi/2,0),32,21.6,'',P.Teal,P.Cream);tg.Title:Destroy()
 label(tg,'Title','ONE DOG TOKEN\nONE ACTIVATION',UDim2.fromScale(.06,.06),UDim2.fromScale(.88,.35),P.Cream)
 label(tg,'Free','FREE DOG TOKEN EVERY 5 HOURS',UDim2.fromScale(.065,.51),UDim2.fromScale(.87,.18),P.Cream)
 label(tg,'Capacity','FREE SLOT HOLDS 1 DOG TOKEN',UDim2.fromScale(.065,.77),UDim2.fromScale(.87,.11),P.LightGold)
 for _,z in ipairs({567,593,667,693})do part(rig,'InformationPost',CFrame.new(-110,1.7,z),Vector3.new(1.2,3.4,1.2),P.Gold,nil,true)end
 for _,z in ipairs({574,686})do
  part(rig,'EntrancePylon',CFrame.new(-63,3.5,z),Vector3.new(4,6,4),P.Purple,nil,true)
  local lamp=part(rig,'EntranceLantern',CFrame.new(-63,7,z),Vector3.new(4.3,1.5,4.3),P.Cream,Enum.Material.Neon);light(lamp,P.LightGold,.6,17)
 end
 local hooks=model(rig,'CameraHooks')
 local function hook(n,cf)local p=part(hooks,n,cf,Vector3.new(.2,.2,.2),P.White);p.Transparency=1;return p end
 hook('DrumCenter',drumCF);hook('RevealFocus',CFrame.new(-119,7,630))
 hook('WideCamera',CFrame.lookAt(Vector3.new(-30,47,648),Vector3.new(-151,44,630)))
 hook('SpinCamera',CFrame.lookAt(Vector3.new(-69,44,638),Vector3.new(-152,40,630)))
 hook('RevealCamera',CFrame.lookAt(Vector3.new(-89,14,644),Vector3.new(-119,7,630)))
 hook('RewardSpawn',CFrame.new(-119,1.25,630)*CFrame.Angles(0,-math.pi/2,0));hook('PlayerMark',CFrame.new(-104,3.8,630))
 local housing=require(game.ServerStorage.RewardMachineRethemeInstaller).Install(rig)
 counts.Parts+=#housing:GetChildren()
 require(game.ReplicatedStorage.RewardMachineText).Apply(rig,exactOdds)
 counts.RewardMachineParts=counts.Parts-before
 return rig
end

function I.ReplaceRewardMachine()
 assertEdit();local root=assert(map():FindFirstChild(ROOT),'Install the attraction map first')
 local original=assert(root:FindFirstChild('RewardMachineRig'),'Existing reward machine missing')
 local staging=Instance.new('Folder');local counts={Parts=0}
 local ok,result=pcall(buildRewardMachine,staging,counts)
 if not ok then staging:Destroy();error(result)end
 local store=game:GetService('ServerStorage');local backups=store:FindFirstChild('CasinoGeometryBackups')
 if not backups then backups=Instance.new('Folder');backups.Name='CasinoGeometryBackups';backups.Parent=store end
 local backup=Instance.new('Folder');backup.Name='BeforeVerticalWheel_'..game:GetService('HttpService'):GenerateGUID(false);backup:SetAttribute('PreviousVersion',root:GetAttribute('Version'));backup:SetAttribute('PreviousParts',root:GetAttribute('Parts'));backup:SetAttribute('PreviousRewardMachineParts',root:GetAttribute('RewardMachineParts'));backup.Parent=backups
 original.Parent=backup;result.Parent=root;staging:Destroy()
 root:SetAttribute('Parts',(root:GetAttribute('Parts')or 0)-(root:GetAttribute('RewardMachineParts')or 0)+counts.RewardMachineParts);root:SetAttribute('RewardMachineParts',counts.RewardMachineParts);root:SetAttribute('Version',I.Version)
 local prompt=map()['27_RewardMachinePlaza'].RewardMachine:FindFirstChild('RewardMachinePrompt',true)
 if prompt then edit(prompt.Parent,'CFrame',CFrame.new(-105,3.8,630));edit(prompt,'Enabled',true)end
 return {RewardMachineParts=counts.RewardMachineParts,Backup=backup:GetFullName(),Version=I.Version,Center={-154,40,630},Axis='LocalZ',Winner='Top'}
end

function I.Uninstall()
 assertEdit();local m=map();local r=m:FindFirstChild(ROOT)
 assert(not r or r:GetAttribute('CodexAttractionRefresh'),'Unrelated attraction folder exists')
 if r then r:Destroy()end
 local count=0
 for _,o in ipairs(m:GetDescendants())do
  if o:GetAttribute(PREFIX..'Edited')then
   for _,k in ipairs(properties)do
    local a=PREFIX..k;local v=o:GetAttribute(a)
    if v~=nil then
     if k=='Material'then v=Enum.Material[v]
     elseif k=='SizingMode'then v=Enum.SurfaceGuiSizingMode[v]
     elseif k=='FontFace'then v=Font.new(v,Enum.FontWeight[o:GetAttribute(a..'Weight')],Enum.FontStyle[o:GetAttribute(a..'Style')]);o:SetAttribute(a..'Weight',nil);o:SetAttribute(a..'Style',nil)end
     o[k]=v;o:SetAttribute(a,nil)
    end
   end
   o:SetAttribute(PREFIX..'Edited',nil);count+=1
  end
 end
 return count
end
local function install()
 local m=map();assert(m:FindFirstChild('36_DistrictRefresh'),'Install on the saved District Refresh baseline')
 if m:FindFirstChild(ROOT)then I.Uninstall()end
 local old=m['36_DistrictRefresh'];local machine=m['27_RewardMachinePlaza'].RewardMachine
 local prompt=assert(machine:FindFirstChild('RewardMachinePrompt',true),'Reward machine interaction missing')
 local root=Instance.new('Folder');root.Name=ROOT;root:SetAttribute('CodexAttractionRefresh',true);root:SetAttribute('Version',I.Version);root.Parent=m
 local counts={Parts=0,WindowSegments=0,RoofSegments=0,PathSegments=0,RepairEdits=0,RewardMachineParts=0}
 local function model(parent,name)local p=Instance.new('Model');p.Name=name;p.Parent=parent;return p end
 local function part(parent,name,cf,size,color,mat,collide,class)
  local p=Instance.new(class or 'Part');p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color or P.Navy;p.Material=mat or Enum.Material.SmoothPlastic
  p.Anchored=true;p.CanCollide=collide==true;p.CanQuery=collide==true;p.CanTouch=false;p.CastShadow=collide==true;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=parent;counts.Parts+=1;return p
 end
 local function block(parent,name,x,y,z,sx,sy,sz,color,mat,collide)return part(parent,name,CFrame.new(x,y,z),Vector3.new(sx,sy,sz),color,mat,collide)end
 local function label(parent,name,text,pos,size,color)
  local t=Instance.new('TextLabel');t.Name=name;t.BackgroundTransparency=1;t.Position=pos;t.Size=size;t.Text=text;t.Font=Enum.Font.FredokaOne;t.TextScaled=true;t.TextWrapped=true;t.TextColor3=color or P.Cream;t.ClipsDescendants=true;t.Parent=parent;return t
 end
 local function surface(p,name,face,pps)
  local g=Instance.new('SurfaceGui');g.Name=name;g.Face=face or Enum.NormalId.Front;g.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;g.PixelsPerStud=pps or 16;g.LightInfluence=0;g.Parent=p;return g
 end
 local function sign(parent,name,cf,w,h,text,bg,ink)
  local p=part(parent,name,cf,Vector3.new(w,h,.3),bg or P.Navy);local g=surface(p,'Lettering',Enum.NormalId.Front,16)
  label(g,'Title',text,UDim2.fromScale(.035,.06),UDim2.fromScale(.93,.88),ink);return p,g
 end
 -- Horizontal triangles use disjoint wedges, avoiding overlapping coplanar roof tiles.
 local function triangle(parent,name,a,b,c,thickness,color)
  local ab,ac,bc=b-a,c-a,c-b
  if ab:Dot(ab)>ac:Dot(ac)and ab:Dot(ab)>bc:Dot(bc)then c,a=a,c
  elseif ac:Dot(ac)>bc:Dot(bc)then a,b=b,a end
  ab,ac,bc=b-a,c-a,c-b
  local right=ac:Cross(ab).Unit;local up=bc:Cross(right).Unit;local back=bc.Unit
  local height=math.abs(ab:Dot(up));local d1=math.abs(ab:Dot(back));local d2=math.abs(ac:Dot(back))
  if height>.001 and d1>.001 then part(parent,name,CFrame.fromMatrix((a+b)/2,right,up,back),Vector3.new(thickness,height,d1),color,nil,true,'WedgePart');counts.RoofSegments+=1 end
  if height>.001 and d2>.001 then part(parent,name,CFrame.fromMatrix((a+c)/2,-right,up,-back),Vector3.new(thickness,height,d2),color,nil,true,'WedgePart');counts.RoofSegments+=1 end
 end
 local repairs=model(root,'ArchitectureRepairs')
 -- Frame reveals have their own depth and aperture; masonry stops outside the frame.
 hideTree(old:FindFirstChild('ClearWindowOpenings'))
 local openings=model(repairs,'ClearWindowOpenings')
 local shelter=m['32_WelcomeHub'].DogShelter
 local museum=m['06_DogDexMuseum']
 local targets={SideWall='SideWindowFrame',FrontWing='FrontWindowFrame',SideWindowFrame='SideWindow',FrontWindowFrame='FrontWindow',SideMasonry='WindowSurround',WindowSurround='WindowInset',WindowInset='BlueWindow',StoneCourse='WindowSurround'}
 local candidates={};local originals={}
 for _,o in ipairs(m:GetDescendants())do
  if o:IsA('Part')and(o:IsDescendantOf(shelter.Architecture)or o:IsDescendantOf(museum))then
   if targets[o.Name]then table.insert(originals,o)end
   candidates[o.Name]=candidates[o.Name]or{};table.insert(candidates[o.Name],o)
  end
 end
 local function sortedUnique(t)
  table.sort(t);local out={};for _,x in ipairs(t)do if #out==0 or math.abs(x-out[#out])>.001 then table.insert(out,x)end end;return out
 end
 for _,wall in ipairs(originals)do
  local normalX=wall.Size.X<wall.Size.Z;local horizontal=normalX and wall.Size.Z or wall.Size.X;local thickness=normalX and wall.Size.X or wall.Size.Z
  local holes={};local xs={-horizontal/2,horizontal/2};local ys={-wall.Size.Y/2,wall.Size.Y/2}
  for _,aperture in ipairs(candidates[targets[wall.Name]]or{})do
   local q=wall.CFrame:PointToObjectSpace(aperture.Position);local n=normalX and q.X or q.Z
   if math.abs(n)<thickness/2+3 then
    local lx,hx,ly,hy=math.huge,-math.huge,math.huge,-math.huge
    for _,a in ipairs({-1,1})do for _,b in ipairs({-1,1})do for _,c in ipairs({-1,1})do
     local v=wall.CFrame:PointToObjectSpace(aperture.CFrame:PointToWorldSpace(aperture.Size*Vector3.new(a,b,c)/2));local h=normalX and v.Z or v.X
     lx=math.min(lx,h);hx=math.max(hx,h);ly=math.min(ly,v.Y);hy=math.max(hy,v.Y)
    end end end
    local pad=(wall.Name=='SideWindowFrame'or wall.Name=='FrontWindowFrame'or wall.Name=='WindowInset')and .015 or .065
    lx=math.max(-horizontal/2,lx-pad);hx=math.min(horizontal/2,hx+pad);ly=math.max(-wall.Size.Y/2,ly-pad);hy=math.min(wall.Size.Y/2,hy+pad)
    if hx-lx>.02 and hy-ly>.02 then table.insert(holes,{lx,hx,ly,hy});table.insert(xs,lx);table.insert(xs,hx);table.insert(ys,ly);table.insert(ys,hy)end
   end
  end
  if #holes>0 then
   hide(wall);xs=sortedUnique(xs);ys=sortedUnique(ys)
   for yi=1,#ys-1 do
    local cy=(ys[yi]+ys[yi+1])/2;local run=nil
    for xi=1,#xs do
     local solid=xi<#xs
     if solid then local cx=(xs[xi]+xs[xi+1])/2;for _,h in ipairs(holes)do if cx>h[1]and cx<h[2]and cy>h[3]and cy<h[4]then solid=false;break end end end
     if solid and not run then run=xi end
     if not solid and run then
      local x=(xs[run]+xs[xi])/2;local w=xs[xi]-xs[run];local h=ys[yi+1]-ys[yi]
      local offset=normalX and Vector3.new(0,cy,x)or Vector3.new(x,cy,0);local size=normalX and Vector3.new(thickness,h,w)or Vector3.new(w,h,thickness)
      local seg=part(openings,wall.Name..'_Reveal',wall.CFrame*CFrame.new(offset),size,wall.Color,wall.Material,true);seg:SetAttribute('SourceWall',wall:GetFullName());counts.WindowSegments+=1;run=nil
     end
    end
   end
  end
 end
 -- The arch's three radial bands previously shared the exact front/back plane.
 for _,p in ipairs(museum.GrandFacade:GetChildren())do
  if p:IsA('BasePart')and p.Name=='GrandArch'then
   if p.Size.Y<.4 then edit(p,'Size',Vector3.new(p.Size.X,p.Size.Y,2.20));counts.RepairEdits+=1
   elseif p.Size.Y<1 then edit(p,'Size',Vector3.new(p.Size.X,p.Size.Y,2.10));counts.RepairEdits+=1 end
  end
 end
 -- Make the upper entrance lintel read as an intentional thin beam from the gallery.
 local lintel=museum.GrandFacade:FindFirstChild('EntranceLintel')
 if lintel then edit(lintel,'Size',Vector3.new(44,1.1,3.0));edit(lintel,'CFrame',CFrame.new(-71.5,31,481)*lintel.CFrame.Rotation);counts.RepairEdits+=1 end
 local roof=museum.SteppedNavyRoof
 local roofReplace={RoofInfill=true,OculusCeiling=true,FrontRoofClosure=true,OculusStone=true,OculusWarmRim=true,OculusGoldRim=true}
 for _,p in ipairs(roof:GetDescendants())do if roofReplace[p.Name]then hideTree(p)end end
 -- Bronze beams are diametral: the original 12 contain six exact 180-degree duplicates.
 -- Their original height left visible gaps above the stone ring. Embed their ends in it.
 local lantern=roof:FindFirstChild('SealedOculusLantern');local ribDirections={}
 if lantern then
  for _,p in ipairs(lantern:GetChildren())do
   if p:IsA('BasePart')and p.Name=='BronzeRib'then
    local d=p.CFrame.RightVector;local duplicate=false
    for _,q in ipairs(ribDirections)do if math.abs(d:Dot(q))>.9999 then duplicate=true;break end end
    if duplicate then hide(p)
    else table.insert(ribDirections,d);edit(p,'Size',Vector3.new(57.6,p.Size.Y,p.Size.Z));edit(p,'CFrame',CFrame.new(p.Position.X,52.0,p.Position.Z)*p.CFrame.Rotation)end
    counts.RepairEdits+=1
   end
  end
  local crown=lantern:FindFirstChild('Crown')
  if crown and crown:IsA('BasePart')then edit(crown,'CFrame',CFrame.new(crown.Position.X,52.75,crown.Position.Z)*crown.CFrame.Rotation);counts.RepairEdits+=1 end
 end
 local canopy=model(repairs,'MuseumOculusRoof');local center=Vector3.new(-137,50.9,481)
 local angles={};for i=0,63 do table.insert(angles,i*2*math.pi/64)end
 for _,a in ipairs({math.pi/4,3*math.pi/4,5*math.pi/4,7*math.pi/4})do table.insert(angles,a)end;angles=sortedUnique(angles)
 local function point(a,r,y)return center+Vector3.new(math.cos(a)*r,y or 0,math.sin(a)*r)end
 local roofCream=C(232,222,192)
 for i=1,#angles do
  local a=angles[i];local b=angles[i%#angles+1];if b<a then b+=2*math.pi end
  local oa=40/math.max(math.abs(math.cos(a)),math.abs(math.sin(a)));local ob=40/math.max(math.abs(math.cos(b)),math.abs(math.sin(b)))
  local ia,ib,aa,bb=point(a,29),point(b,29),point(a,oa),point(b,ob)
  triangle(canopy,'ContinuousRoof',ia,aa,bb,1.8,roofCream);triangle(canopy,'ContinuousRoof',ia,bb,ib,1.8,roofCream)
  local x,y=point(a,27.5),point(b,27.5)
  triangle(canopy,'OculusStoneRing',x,ia,ib,1.8,P.Cream);triangle(canopy,'OculusStoneRing',x,ib,y,1.8,P.Cream)
 end
 block(canopy,'FrontRoofClosure',-79.75,50.9,481,34.5,1.8,28,roofCream,nil,true)
 -- A raised lip is separated from the roof and glass rather than sharing their plane.
 for i=0,63 do
  local a=(i+.5)*2*math.pi/64;local p=point(a,28.55,1.01)
  part(canopy,'OculusGoldLip',CFrame.new(p)*CFrame.Angles(0,-a,0),Vector3.new(.22,.18,2*28.55*math.tan(math.pi/64)-.025),P.Gold)
 end
 -- Lab crown faces coincided with white corner columns at X=96.5 / 82.5.
 for _,p in ipairs(m['05_MutationLab'].GlassFacade:GetChildren())do
  if p:IsA('BasePart')and p.Name=='WindowCrown'then edit(p,'CFrame',p.CFrame+Vector3.new(.12,0,0));counts.RepairEdits+=1 end
 end
 local honor=m['32_WelcomeHub'].CommunityCourt.HonorSquare
 local court=honor:FindFirstChild('LimestoneCourt');if court then edit(court,'CFrame',court.CFrame+Vector3.new(0,.055,0));counts.RepairEdits+=1 end
 -- Paving is split at express lanes and at existing plaza boundaries; no stacked crossings.
 hideTree(old.DirectPaths)
 local paths=model(root,'ConnectedPaths')
 local function paving(name,x1,z1,x2,z2,width,top,color)
  local sx,sz=math.abs(x2-x1),math.abs(z2-z1);assert(sx<.001 or sz<.001,'Path must be axis aligned')
  if math.max(sx,sz)<.01 then return end
  local p=block(paths,name,(x1+x2)/2,top-.18,(z1+z2)/2,sx<.001 and width or sx,.36,sz<.001 and width or sz,color or P.Stone,Enum.Material.Concrete,true);counts.PathSegments+=1;return p
 end
 local function branch(name,x,z,width,top)
  local side=x>0 and 1 or -1
  paving(name..'_Boulevard',18*side,z,23*side,z,width,.5)
  paving(name..'_Destination',29*side,z,x,z,width,top or .5)
 end
 local boulevard=m['01_IslandAndStreets'].PrimaryPaths.MainBoulevard
 edit(boulevard,'CFrame',boulevard.CFrame+Vector3.new(0,.20,0))
 local pawPlaza=m['32_WelcomeHub'].WelcomePlaza:FindFirstChild('CentralPawPlaza')
 if pawPlaza then for _,p in ipairs(pawPlaza:GetDescendants())do if p:IsA('BasePart')then edit(p,'CFrame',p.CFrame+Vector3.new(0,.15,0))end end end
 branch('Shelter',95.85,204.95,14,.5)
 branch('Leaderboards',-58,206,14,.5)
 branch('Upgrade',82,275,14,.5);branch('Cosmetics',82,335,14,.5);branch('Supplies',82,395,14,.5)
 branch('Community',-31,342,16,.47)
 branch('CommunityGarden',-58.5,275,14,.36)
 branch('Museum',-59,481,16,.4)
 branch('Laboratory',80,477,16,.48)
 branch('RewardMachine',-34,630,20,.5)
 branch('Future',33,575,18,.5)
 branch('Portal',-63,564,12,.5)
 -- End the south loop at the blocked district's edge rather than leading through it.
 paving('SouthGardenLoop',-177,749,-18,749,10,.5)
 paving('MachineGardenReturn',-177,705,-177,744,10,.5)
 paving('SouthBoulevardJoin',18,749,29,749,10,.5)
 for _,x in ipairs({-26,26})do paving('ExpressReturn',x,740,x,744,6,.5)end
 local services=m['11_Shops'].ServicePromenade
 for _,p in ipairs(services:GetChildren())do
  if p:IsA('BasePart')and(p.Name=='Promenade'or p.Name=='EntranceWalk')then edit(p,'CFrame',p.CFrame+Vector3.new(0,.50-(p.Position.Y+p.Size.Y/2),0))
  elseif p:IsA('BasePart')and p.Name=='PromenadeEdge'then edit(p,'CFrame',p.CFrame+Vector3.new(0,.05,0))end
 end
 -- Hide the old future garden and contain the measured quarry, including the crane.
 hideTree(old.GlobalEventComingSoon);hideTree(m['08_GlobalDigSite'])
 local future=model(root,'GlobalEventComingSoon')
 local cover=block(future,'OpaqueBlackCuboid',123.75,.5,638.15,181.5,99,214.3,C(0,0,0),Enum.Material.SmoothPlastic,true)
 cover.CastShadow=true;cover:SetAttribute('MeasuredMin',Vector3.new(33,-49,531));cover:SetAttribute('MeasuredMax',Vector3.new(214.5,50,745.3))
 for _,face in ipairs(Enum.NormalId:GetEnumItems())do
  local g=surface(cover,'ComingSoon_'..face.Name,face,6)
  local vertical=face~=Enum.NormalId.Top and face~=Enum.NormalId.Bottom
  label(g,'Title','COMING SOON',UDim2.fromScale(.055,vertical and .055 or .20),UDim2.fromScale(.89,vertical and .38 or .60),C(255,255,255))
 end
 -- Replace the legacy reward machine with the vertical physical wheel.
 hideTree(old.RewardMachine);hideTree(machine)
 local plaza=m['27_RewardMachinePlaza'].Forecourt
 for _,child in ipairs(plaza:GetChildren())do if child.Name~='PlazaFoundation'then hideTree(child)end end
 buildRewardMachine(root,counts)
 edit(prompt.Parent,'CFrame',CFrame.new(-105,3.8,630));edit(prompt,'Enabled',true)
 for k,v in pairs(counts)do root:SetAttribute(k,v)end
 return counts
end
function I.Install()
 assertEdit();local ok,result=pcall(install)
 if not ok then pcall(I.Uninstall);error(result)end
 return result
end
function I.Validate()
 local m=map();local r=assert(m:FindFirstChild(ROOT),'Attraction refresh missing');local issues={}
 local function check(ok,why)if not ok then table.insert(issues,why)end end
 local cube=r.GlobalEventComingSoon.OpaqueBlackCuboid
 check(cube.Transparency==0 and cube.Color==Color3.new(0,0,0)and cube.CanCollide,'Global event cover must be opaque, black and solid')
 local faces=0;for _,o in ipairs(cube:GetChildren())do if o:IsA('SurfaceGui')and o.Title.Text=='COMING SOON'then faces+=1 end end;check(faces==6,'Six coming-soon faces required')
 check(cube.Position.X-cube.Size.X/2>29,'DogExpress obstructed by global event cover')
 local legacyRoofVisible=0
 local replacedRoofNames={RoofInfill=true,OculusCeiling=true,FrontRoofClosure=true,OculusStone=true,OculusWarmRim=true,OculusGoldRim=true}
 for _,p in ipairs(m['06_DogDexMuseum'].SteppedNavyRoof:GetDescendants())do
  if p:IsA('BasePart')and replacedRoofNames[p.Name]and p.Transparency<1 then legacyRoofVisible+=1 end
 end
 check(legacyRoofVisible==0,'Legacy roof parts still overlap replacement: '..legacyRoofVisible)
 local rig=r.RewardMachineRig
 check(rig.ModelStreamingMode==Enum.ModelStreamingMode.Persistent,'Reward machine rig must stream as a complete persistent attraction')
 check(rig:FindFirstChild('WinningFrame')and rig.WinningFrame:GetAttribute('Target')=='Top','Fixed pointer must identify the top sector')
 check(rig:GetAttribute('AnimationAxis')=='LocalZ','Vertical wheel must rotate around local Z')
 check((rig.SpinningDrum:GetPivot().Position-rig.CameraHooks.DrumCenter.Position).Magnitude<.01,'Drum pivot differs from animation hook')
 for i=1,prizeCount do
  local face=rig.SpinningDrum:FindFirstChild('PrizeFace_'..i);local theta=(i-1)*2*math.pi/prizeCount
  check(face~=nil,'Prize face missing: '..i);check(rig.StatusBoard.OddsDisplay.Rows:FindFirstChild('Row'..i)~=nil,'Odds row missing: '..i)
  if face then
   local q=rig.CameraHooks.DrumCenter.CFrame:PointToObjectSpace(face.Position)
   local expected=Vector3.new(-math.sin(theta)*17.4,math.cos(theta)*17.4,-3.1)
   check((q-expected).Magnitude<.02,'Wrong radial sector position: '..i)
  end
 end
 local movingInvalid=0;for _,p in ipairs(rig.SpinningDrum:GetDescendants())do if p:IsA('BasePart')and(p.CanCollide or p.CanTouch or p.CanQuery)then movingInvalid+=1 end end
 check(movingInvalid==0,'Spinning wheel must be non-collidable')
 check((rig.CameraHooks.RewardSpawn.Position-Vector3.new(-119,1.25,630)).Magnitude<.01,'Reward base must rest just above stage')
 check(rig.CameraHooks.DrumCenter.CFrame.LookVector:Dot(Vector3.new(1,0,0))>.999,'Wheel faces away from the plaza')
 local prompt=m['27_RewardMachinePlaza'].RewardMachine:FindFirstChild('RewardMachinePrompt',true)
 check(prompt and prompt.Enabled and(prompt.Parent.Position-Vector3.new(-105,3.8,630)).Magnitude<.01,'Reward machine prompt unavailable')
 local invalid=0
 for _,p in ipairs(r:GetDescendants())do
  if p:IsA('BasePart')then if not p.Anchored or p.Size.X<=0 or p.Size.Y<=0 or p.Size.Z<=0 then invalid+=1 end end
 end
 check(invalid==0,'Invalid or unanchored generated geometry')
 return {Passed=#issues==0,Problems=issues,Parts=r:GetAttribute('Parts'),RewardMachineParts=r:GetAttribute('RewardMachineParts'),WindowSegments=r:GetAttribute('WindowSegments'),RoofSegments=r:GetAttribute('RoofSegments'),PathSegments=r:GetAttribute('PathSegments'),RepairEdits=r:GetAttribute('RepairEdits')}
end
return I

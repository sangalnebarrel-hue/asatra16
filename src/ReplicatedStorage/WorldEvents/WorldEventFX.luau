local Epic=require(script.Parent.WorldEventSpectacle)
local Cataclysm=require(script.Parent.WorldEventCataclysm)
local RS=game:GetService('ReplicatedStorage');local Players=game:GetService('Players');local Run=game:GetService('RunService')
local V=require(script.Parent.WorldEventObjects);local Route=require(RS.MapRouting);local Audio=require(script.Parent.WorldEventAudio)
local F={Token=0};local root;local models={};local rain={};local beams={};local dogs={};local def;local budget;local elapsed=0;local ending;local signatureUntil=0;local connections={}
local C=Color3.fromRGB
local function digSiteOpen()
 local config=RS:FindFirstChild('GlobalDigConfig')
 if not config then return true end
 local ok,value=pcall(require,config)
 return not ok or type(value)~='table'or value.Enabled~=false
end
local siteOpen=digSiteOpen()
local function ground(pos,ceiling)
 local map=workspace:FindFirstChild('DOGROTS_District');if not map then return pos end
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={map};params.RespectCanCollide=true
 local hit=workspace:Raycast(pos+Vector3.new(0,ceiling or 8,0),Vector3.new(0,-160,0),params)
 return hit and hit.Normal.Y>.45 and hit.Position or nil
end
local stageCache
-- While the Global Dig quarry is closed behind its COMING SOON cover, the event stage
-- is the open central plaza of the Welcome Hub, where every player spawns.
local function stage()
 if stageCache then return stageCache end
 local hub=Route.Position('WelcomeHub')or Vector3.new(0,3,377)
 local at=hub+Vector3.new(0,0,-32)
 stageCache=ground(at,12)or Vector3.new(at.X,hub.Y-2.6,at.Z)
 return stageCache
end
local function origin(key)
 if key=='GlobalDigSite'then
  if not siteOpen then return stage()end
  local map=workspace:FindFirstChild('DOGROTS_District');local site=map and map:FindFirstChild('08_GlobalDigSite');local a=site and site:FindFirstChild('SiteOrigin')
  if a then return a.Position end
 end
 return Route.Position(key)or Vector3.zero
end
local function safeRainGround(pos,index)
 local at=ground(pos,14)
 if at and at.Y>pos.Y-65 then return at end
 -- Fall back to a known public path, never the void or an unsupported cliff frame.
 local start=origin('WelcomeHub')+Vector3.new((index%3-1)*8,-3,(index%7-3)*12)
 return ground(start,8)or start
end
local function model(name,key,offset)
 local m=Instance.new('Model');m.Name=name;m.WorldPivot=CFrame.identity;m.Parent=root;models[m]={Key=key,Offset=offset or Vector3.zero};return m
end
local function part(m,n,p,s,c,neon)return V.Part(m,n,p,s,c,neon and Enum.Material.Neon or nil)end
local function anchor(m,pos)local p=part(m,'FXOrigin',pos,Vector3.one,def.ColorTheme);p.Transparency=1;return p end
local function attachTrail(p,color)
 local a=Instance.new('Attachment');a.Position=Vector3.new(-.4,0,0);a.Parent=p;local b=Instance.new('Attachment');b.Position=Vector3.new(.4,0,0);b.Parent=p
 local trail=Instance.new('Trail');trail.Attachment0=a;trail.Attachment1=b;trail.Color=ColorSequence.new(color);trail.Lifetime=.45;trail.Transparency=NumberSequence.new(.5,1);trail.Parent=p
end
local function ufo(size,index)
 local m=model('UFO'..index,'GlobalDigSite',Vector3.new(index*26-64,118+index*9,index*18-40))
 local green=C(151,255,178)
 V.Ellipsoid(m,'Hull',Vector3.new(size,size*.16,size),CFrame.new(),C(46,62,68),Enum.Material.Metal)
 V.Ellipsoid(m,'Deck',Vector3.new(size*.7,size*.12,size*.7),CFrame.new(0,size*.07,0),C(70,92,96),Enum.Material.Metal)
 V.Ellipsoid(m,'GlassDome',Vector3.new(size*.32,size*.22,size*.32),CFrame.new(0,size*.15,0),C(94,190,146),Enum.Material.Glass).Transparency=.3
 V.Ellipsoid(m,'BellyGlow',Vector3.new(size*.46,size*.04,size*.46),CFrame.new(0,-size*.075,0),green,Enum.Material.Neon)
 for i=1,12 do local a=i*math.pi/6
  local p=part(m,'RimLight',Vector3.new(math.cos(a)*size*.47,0,math.sin(a)*size*.47),Vector3.one*math.max(1.2,size*.05),green,true);p.Shape=Enum.PartType.Ball
 end
 local top,bottom,beam=V.Beam(root,origin('GlobalDigSite'),origin('GlobalDigSite')+Vector3.new(0,85,0),C(117,248,157),size*.3)
 beam.Width1=size*.12;V.Soft(beam,.66,.03,.2);beam.LightEmission=1
 local circle=V.Ellipsoid(root,'AbductionCircle',Vector3.new(size*.5,.12,size*.5),CFrame.new(origin('GlobalDigSite')),C(117,248,157),Enum.Material.Neon);circle.Transparency=.55
 table.insert(beams,{Top=top,Bottom=bottom,Beam=beam,Ship=m,Circle=circle,Size=size});return m
end
local function clockFace(index,color)
 local m=model('TemporalClock','WelcomeHub',Vector3.new((index-3)*30,26+index*6,math.sin(index)*35))
 local rim=V.Ring(m,7.6,.55,.55,color,24,.05);rim.Model.Name='ClockRim'
 for j=1,12 do local a=j*math.pi/6;local p=part(m,'ClockTick',Vector3.new(math.cos(a)*6.3,math.sin(a)*6.3,0),Vector3.new(.45,1.3,.45),color,true);p.CFrame=CFrame.new(p.Position)*CFrame.Angles(0,0,a-math.pi/2)end
 local face=part(m,'ClockFace',Vector3.new(0,0,-.3),Vector3.new(.1,14,14),C(16,40,52));face.Shape=Enum.PartType.Cylinder;face.CFrame=CFrame.new(0,0,-.3)*CFrame.Angles(0,math.pi/2,0);face.Transparency=.35
 local hands={}
 for k=1,2 do
  local hand=part(m,'ClockHand',Vector3.zero,Vector3.new(.35,k==1 and 5.4 or 3.6,.3),color,true)
  table.insert(hands,{Part=hand,Length=k==1 and 5.4 or 3.6,Speed=k==1 and 2.4 or .4});if k==1 then attachTrail(hand,color)end
 end
 part(m,'ClockPin',Vector3.new(0,0,.45),Vector3.one*.9,C(255,255,255),true).Shape=Enum.PartType.Ball
 models[m].Hands=hands
 return m
end
local function fissure(index,color)
 local m=model('Fissure','GlobalDigSite',Vector3.new((index%4-1.5)*15,0,math.floor(index/4)*18-9))
 local cracks={}
 local x,z=0,0
 for j=1,6 do
  local nx,nz=x+2.6+math.abs(math.sin(j*1.9+index))*1.6,z+math.sin(j*2.3+index*1.7)*2.2
  local glow=part(m,'Crack',Vector3.zero,Vector3.new(.55,.08,1),C(255,148,52),true)
  local edge=part(m,'CrackEdge',Vector3.zero,Vector3.new(1.5,.06,1),C(46,30,24))
  table.insert(cracks,{Glow=glow,Edge=edge,A=Vector3.new(x,0,z),B=Vector3.new(nx,0,nz),Width=.45+.5*math.sin(j*math.pi/6)})
  x,z=nx,nz
 end
 models[m].Cracks=cracks
 return m
end
local function setup()
 local color=def.ColorTheme
 if def.WorldProps=='UFOFleet'then for i=1,(budget.Dogs>3 and 4 or 2)do ufo(i==1 and 64 or 30,i)end
 elseif def.WorldProps=='Rift'then
  local m=model('ChromaticRift','GlobalDigSite',Vector3.new(0,140,0))
  for i=1,32 do local a=i*math.pi/16;local p=part(m,'RiftSegment',Vector3.new(math.cos(a)*35,math.sin(a)*53,0),Vector3.new(4,13,3),Color3.fromHSV(i/32,.65,1),true)
   local tangent=Vector3.new(-math.sin(a)*35,math.cos(a)*53,0).Unit;p.CFrame=CFrame.fromMatrix(p.Position,tangent:Cross(Vector3.new(0,0,1)),tangent,Vector3.new(0,0,1))end
  -- Same ellipse as the ring, so the edge hides under the segments.
  local plane=V.Ellipsoid(m,'OtherSide',Vector3.new(70,106,.4),CFrame.new(0,0,3),C(52,39,80));plane.Transparency=.18
  part(m,'OtherIsland',Vector3.new(0,-25,1),Vector3.new(47,6,2),C(77,98,98))
  for i=-2,2 do part(m,'OtherDistrict',Vector3.new(i*8,-15,0),Vector3.new(5,14+math.abs(i)*5,3),C(90+i*12,142,172),true)end
 elseif def.WorldProps=='NullCube'then
  local m=model('ImpossibleCube','WelcomeHub',Vector3.new(0,125,-95));part(m,'GreyCube',Vector3.zero,Vector3.new(65,65,65),C(134,131,137)).Transparency=1
  for i=1,budget.Debris do local p=part(root,'SpatialError',origin('WelcomeHub')+Vector3.new(math.sin(i*2.4)*130,20+i*2,math.cos(i*2.4)*130),Vector3.new(2+i%4,2,2+i%4),i%2==0 and C(145,54,126)or C(135,130,139),i%4==0);attachTrail(p,color);table.insert(rain,{Part=p,Index=i,Kind='Errors'})end
 elseif def.WorldProps=='Clocks'then
  for i=1,5 do clockFace(i,color)end
 elseif def.WorldProps=='Fissures'then
  for i=1,8 do fissure(i,color)end
 elseif def.WorldProps=='CrystalStrike'then
  for i=1,7 do local m=model('StormCrystal','GlobalDigSite',Vector3.new((i-4)*12,0,25*math.sin(i)))
   for j=1,3 do local p=part(m,'Crystal',Vector3.new(j-2,j*1.1,0),Vector3.new(1.6,6+j,1.6),color,true);p.CFrame*=CFrame.Angles(.1,j*.5,.3)end
  end
 elseif def.WorldProps=='GoldenBeam'or def.WorldProps=='TreasureBeams'then
  for i=1,(def.WorldProps=='GoldenBeam'and 1 or 5)do local a=origin('GlobalDigSite')+Vector3.new((i-1)*14,1,0)
   local top,bottom,beam=V.Beam(root,a,a+Vector3.new(0,110,0),color,def.WorldProps=='GoldenBeam'and 24 or 3)
   beam.LightEmission=1;V.Soft(beam,def.WorldProps=='GoldenBeam'and .62 or .5,.03,.5)
   table.insert(beams,{Top=top,Bottom=bottom,Beam=beam,Key='GlobalDigSite',Offset=Vector3.new((i-1)*14,0,0)})
  end
 end
 -- Local, capped ambient emitter follows the player; it never generates physical debris.
 local emitterPart=anchor(root,origin('WelcomeHub')+Vector3.new(0,25,0));F.EmitterPart=emitterPart
 local particles=V.Particles(emitterPart,color,budget.Particles,def.ParticleProfile=='Fog'and 16 or .4);F.Emitter=particles
 particles.EmissionDirection=Enum.NormalId.Bottom;particles.SpreadAngle=Vector2.new(160,160)
 if def.ParticleProfile=='Fog'then particles.Texture='rbxasset://textures/particles/smoke_main.dds';particles.Transparency=NumberSequence.new(.96);particles.Color=ColorSequence.new(C(135,128,153));particles.LightEmission=.08;particles.Lifetime=NumberRange.new(5,9);particles.Speed=NumberRange.new(2,4)end
 if def.ParticleProfile=='Bones'then
  for i=1,budget.Debris do local m=V.Build('BonePile',color);m:ScaleTo(.38);m.Parent=root
   for _,o in ipairs(m:GetDescendants())do if o:IsA('Beam')or o:IsA('Light')then o:Destroy()elseif o.Name=='GroundHalo'then o:Destroy()end end
   table.insert(rain,{Part=m,Index=i,Kind='Bone'})
  end
 elseif def.ParticleProfile=='Debris'or def.ParticleProfile=='Crystals'then
  for i=1,budget.Debris do local p=part(root,'AirDebris',Vector3.zero,Vector3.new(.5,.7,.5),color,def.ParticleProfile=='Crystals');table.insert(rain,{Part=p,Index=i,Kind='Stone'})end
 end
 if def.WorldProps=='DogCrowd'then
  -- A pack of real dogs runs past the player along both sides of their view.
  local templates=RS:FindFirstChild('MenuModels');local names={'Breadog','CoffeeDog','DJDoggo','Vampug','AngelDoggo','Sausagedog'}
  local count=math.min(budget.Dogs,10)
  local animModule=RS:FindFirstChild('DogAnimationPlayer');local okPlayer,Animator=false,nil
  if animModule then okPlayer,Animator=pcall(require,animModule)end
  if templates and okPlayer then for i=1,count do local name=names[(i-1)%#names+1];local template=templates:FindFirstChild(name);if template then
   local m=template:Clone()
   for _,p in ipairs(m:GetDescendants())do if p:IsA('BasePart')then p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false elseif p:IsA('BaseScript')or p:IsA('ProximityPrompt')or p:IsA('BillboardGui')then p:Destroy()end end
   if not m:GetAttribute('AnimationBaseScale')then m:SetAttribute('AnimationBaseScale',m:GetScale())end
   local _,size=m:GetBoundingBox();m:ScaleTo(m:GetScale()*math.min(4.4/size.Y,5.5/size.X));m.Parent=root
   local box,extents=m:GetBoundingBox();local foot=m:GetPivot():PointToObjectSpace(box.Position-Vector3.new(0,extents.Y/2,0))
   local anim=Animator.new(m,name);anim:Play('Walk',{Looped=true,Speed=1.7,StartTime=workspace:GetServerTimeNow()-i*.37})
   local parts={};for _,p in ipairs(m:GetDescendants())do if p:IsA('BasePart')then table.insert(parts,p)end end
   table.insert(dogs,{Model=m,Index=i,Animation=anim,Foot=foot,Parts=parts,Side=i%2==0 and 1 or -1})
  end end end
 end
end
function F.Signature(duration)
 Cataclysm.Signature()
 Epic.Signature(duration)
 signatureUntil=os.clock()+duration;Audio.Cue('rare',origin('GlobalDigSite'));F.ShakeUntil=os.clock()+math.min(duration,2)
 if def and def.WorldProps=='CrystalStrike'then
  local base=origin('GlobalDigSite');local strike=Instance.new('Folder');strike.Name='ChargedLightning';strike.Parent=root
  local previous=base+Vector3.new(0,110,0)
  for i=1,8 do local nextPoint=base+Vector3.new(math.sin(i*4)*5,110-i*13.5,math.cos(i*3)*4);local _,_,b=V.Beam(strike,nextPoint,previous,C(184,221,255),.65);b.LightEmission=1;previous=nextPoint end
  game:GetService('Debris'):AddItem(strike,.65)
 end
 if def and (def.Id=='GOLDEN_HOUR'or def.Id=='RAINBOW_RIFT')then
  local wave=V.Ellipsoid(root,'ColorWave',Vector3.new(5,.2,5),CFrame.new(origin('WelcomeHub')+Vector3.new(0,.4,0)),def.ColorTheme,Enum.Material.Neon);wave.Transparency=.5
  game:GetService('TweenService'):Create(wave,TweenInfo.new(3),{Size=Vector3.new(360,.2,360),Transparency=1}):Play();game:GetService('Debris'):AddItem(wave,3.2)
 end
end
function F.Begin(event,state,quality)
 F.Stop();F.Token+=1;def=event;budget=quality;ending=nil;F.StartedAt=os.clock();F.State=state
 root=workspace:FindFirstChild('WorldEventClientFX')or Instance.new('Folder');root.Name='WorldEventClientFX';root.Parent=workspace
 local cam=workspace.CurrentCamera;local look=cam and cam.CFrame.LookVector or Vector3.new(0,0,-1)
 look=Vector3.new(look.X,0,look.Z);if look.Magnitude<.1 then look=Vector3.new(0,0,-1)end;F.Heading=look.Unit
 setup();Epic.Begin(event,state,quality);Cataclysm.Begin(event,state,quality)
 -- Running dogs fade on their own loop; keep them out of the shared arrival fade.
 local dogParts={};for _,d in ipairs(dogs)do for _,p in ipairs(d.Parts)do dogParts[p]=true end end
 F.Visuals={};for _,p in ipairs(root:GetDescendants())do if p:IsA('BasePart')and not dogParts[p]then table.insert(F.Visuals,p)end end
 F.LastSpecial=os.clock();F.Shadow=nil
 if def.Id=='UFO_INVASION'then F.Shadow=V.Ellipsoid(root,'ArrivalShadow',Vector3.new(30,.05,30),CFrame.new(origin('GlobalDigSite')+Vector3.new(-90,.6,0)),C(28,37,33),Enum.Material.SmoothPlastic);F.Shadow.Transparency=.65 end
 table.insert(connections,Run.Heartbeat:Connect(function(dt)
  elapsed+=dt;if elapsed<.05 then return end;elapsed=0
  local camera=workspace.CurrentCamera;if not camera then return end
  local t=workspace:GetServerTimeNow();local isSignature=os.clock()<signatureUntil
  if def.Id=='TIME_WARP'and isSignature then F.FrozenTime=F.FrozenTime or t;t=F.FrozenTime else F.FrozenTime=nil end
  local departure=ending and math.clamp((os.clock()-ending)/8,0,1)or 0
  local arrival=math.clamp((os.clock()-F.StartedAt)/4,0,1)
  for _,p in ipairs(F.Visuals)do if p.Parent then p.LocalTransparencyModifier=1-arrival*(1-departure)end end
  if F.Shadow and F.Shadow.Parent then F.Shadow.Position=(ground(origin('GlobalDigSite')+Vector3.new(-24+arrival*48,0,0),70)or origin('GlobalDigSite'))+Vector3.new(0,.08,0);F.Shadow.Transparency=.65+arrival*.35 end
  for m,row in pairs(models)do
   local base=origin(row.Key)+row.Offset;local move=Vector3.zero;local rotate=CFrame.identity
   if m.Name=='Fissure'or m.Name=='StormCrystal'then
    if not row.GroundBase or(row.GroundBase-base).Magnitude>.05 then
     local surface=ground(base,70);row.GroundBase=base;row.CrackY=nil
     if surface then
      local box,size=m:GetBoundingBox();row.BottomOffset=row.BottomOffset or(box.Position.Y-size.Y/2-m:GetPivot().Position.Y)
      row.Grounded=Vector3.new(base.X,surface.Y-row.BottomOffset+.07,base.Z)
     else row.Grounded=base end
    end
    base=row.Grounded
   end
   if m.Name:find('UFO')then move=Vector3.new(math.sin(t*.07+#m.Name)*12,math.sin(t*.13)*4+departure*160,math.cos(t*.09+#m.Name)*12);rotate=CFrame.Angles(0,t*.08,0)
   elseif m.Name=='ChromaticRift'then rotate=CFrame.Angles(0,math.sin(t*.12)*.10,math.sin(t*.2)*.04);m:ScaleTo(math.max(.02,arrival*(1-departure)))
   elseif m.Name=='TemporalClock'then
    -- Faces the camera like a billboard; only the hands turn.
    local toCamera=camera.CFrame.Position-base;toCamera=Vector3.new(toCamera.X,0,toCamera.Z)
    if toCamera.Magnitude>.1 then rotate=CFrame.lookAt(Vector3.zero,-toCamera.Unit)end
   elseif m.Name=='ImpossibleCube'then local p=m:FindFirstChild('GreyCube');p.Transparency=isSignature and .08 or 1;rotate=CFrame.Angles(.08,.15,0)end
   local frame=CFrame.new(base+move)*rotate
   if row.Cracks then
    -- Cracks are traced over the real plaza surface once, then only fade in and out.
    if not row.CrackY then
     row.CrackY={}
     for k,c in ipairs(row.Cracks)do local mid=frame:PointToWorldSpace((c.A+c.B)/2);local at=ground(Vector3.new(mid.X,base.Y,mid.Z),70);row.CrackY[k]=at and at.Y or base.Y end
    end
    for k,c in ipairs(row.Cracks)do
     local a,b=frame:PointToWorldSpace(c.A),frame:PointToWorldSpace(c.B);local y=row.CrackY[k]
     local mid=Vector3.new((a.X+b.X)/2,y+.05,(a.Z+b.Z)/2);local dir=Vector3.new(b.X-a.X,0,b.Z-a.Z);local len=math.max(.2,dir.Magnitude)
     local cf=CFrame.lookAt(mid,mid+dir)
     local pulse=.75+.25*math.sin(t*2.2+k)
     c.Glow.Size=Vector3.new(c.Width*pulse,.08,len+.3);c.Glow.CFrame=cf+Vector3.new(0,.02,0)
     c.Edge.Size=Vector3.new(c.Width*2.6,.06,len+.6);c.Edge.CFrame=cf
    end
   else
    m:PivotTo(frame)
   end
   if row.Hands then
    for k,h in ipairs(row.Hands)do
     local a=isSignature and 0 or -t*h.Speed-k
     h.Part.CFrame=frame*CFrame.new(0,0,.3)*CFrame.Angles(0,0,a)*CFrame.new(0,h.Length/2,0)
    end
   end
  end
  for _,b in ipairs(beams)do
   if b.Ship then
    local at=b.Ship:GetPivot().Position;b.Top.Position=at-Vector3.new(0,b.Size*.06,0)
    local foot=ground(Vector3.new(at.X+math.sin(t*.4)*12,origin('GlobalDigSite').Y,at.Z+math.cos(t*.3)*12),70)or origin('GlobalDigSite')
    b.Bottom.Position=foot;b.Beam.Width0=(isSignature and b.Size*.55 or b.Size*.3)*arrival*(1-departure);b.Beam.Width1=b.Size*.12*arrival*(1-departure)
    if b.Circle then b.Circle.Position=foot+Vector3.new(0,.08,0)end
   elseif b.Key then local raw=origin(b.Key)+b.Offset;local base=ground(raw,10)or raw;b.Bottom.Position=base;b.Top.Position=base+Vector3.new(0,110,0);b.Beam.Enabled=isSignature or def.WorldProps=='TreasureBeams'end
  end
  local player=Players.LocalPlayer;local char=player.Character;local hrp=char and char:FindFirstChild('HumanoidRootPart');local near=hrp and hrp.Position or origin('WelcomeHub')
  if F.EmitterPart then F.EmitterPart.Position=near+Vector3.new(def.ParticleProfile=='Fog'and -65*(1-arrival)or 0,def.ParticleProfile=='Fog'and 0 or 20,0);F.Emitter.Rate=budget.Particles*(def.ParticleProfile=='Fog'and .15 or 1)*arrival*(1-departure)end
  for _,r in ipairs(rain)do
   local x=math.sin(r.Index*5.73)*70;local z=math.cos(r.Index*3.39)*65;local y=110-(t*34+r.Index*17)%110
   local base=r.Kind=='Errors'and origin('WelcomeHub')or near
   local desired=base+Vector3.new(x,0,z)
   if not r.Ground or not r.GroundNear or(base-r.GroundNear).Magnitude>8 or y>(r.LastY or 65)+20 then r.Ground=safeRainGround(desired,r.Index);r.GroundNear=base end
   local cf=CFrame.new(r.Ground+Vector3.new(0,math.max(.45,y),0))*CFrame.Angles(t*.3,r.Index,t*.5)
   if r.Part:IsA('Model')then r.Part:PivotTo(cf)else r.Part.CFrame=cf end
   if r.Kind=='Bone'and r.LastY and y>r.LastY+20 and r.Index%5==0 then
    local puff=anchor(root,r.Ground+Vector3.new(0,.25,0));local emitter=V.Particles(puff,C(206,196,169),0,1.5);emitter.Speed=NumberRange.new(3,7);emitter:Emit(4);game:GetService('Debris'):AddItem(puff,2)
   end;r.LastY=y
  end
  if os.clock()-(F.LastSpecial or 0)>14 then F.LastSpecial=os.clock();local role=(def.Id=='BONE_RAIN'or def.Id=='DOG_RUSH'or def.Id=='CRYSTAL_STORM')and ('variation_'..math.random(1,3))or 'special';Audio.Cue(role,near+Vector3.new(40,10,30))end
 end))
 if #dogs>0 then
  -- Dogs update every frame so the run cycle and stride stay smooth.
  local heading=CFrame.lookAt(Vector3.zero,F.Heading)
  table.insert(connections,Run.Heartbeat:Connect(function()
   local player=Players.LocalPlayer;local char=player.Character;local hrp=char and char:FindFirstChild('HumanoidRootPart')
   local near=hrp and hrp.Position or origin('WelcomeHub')
   local now=workspace:GetServerTimeNow();local departure=ending and math.clamp((os.clock()-ending)/4,0,1)or 0
   local arrival=math.clamp((os.clock()-F.StartedAt)/2,0,1)
   for _,d in ipairs(dogs)do
    local lane=d.Side*(14+(d.Index%3)*5)
    local z=((now*18+d.Index*29)%180)-90
    local world=near+heading:VectorToWorldSpace(Vector3.new(lane,0,-z))
    local surface=ground(world,10)or Vector3.new(world.X,near.Y-3,world.Z)
    local forward=heading.LookVector
    d.Model:PivotTo(CFrame.lookAt(surface,surface+forward)*CFrame.new(-d.Foot))
    d.Animation:Step(now)
    local edge=math.clamp((90-math.abs(z))/18,0,1)
    for _,p in ipairs(d.Parts)do p.LocalTransparencyModifier=1-edge*arrival*(1-departure)end
   end
  end))
 end
 -- Brief camera impulses are removed before the following frame's camera evaluation.
 Run:BindToRenderStep('DOGROTS_EventCamera',Enum.RenderPriority.Camera.Value+1,function()
  if not def or (def.Id~='EARTHQUAKE'and def.Id~='CRYSTAL_STORM')or os.clock()>=(F.ShakeUntil or 0)then return end
  if Players.LocalPlayer:GetAttribute('ReducedMotion')or budget.Debris<=8 then return end
  local camera=workspace.CurrentCamera;if camera.CameraType==Enum.CameraType.Scriptable then return end
  local t=os.clock();camera.CFrame*=CFrame.new(math.sin(t*31)*.05,math.cos(t*39)*.04,0)
 end)
end
function F.End()Epic.End();Cataclysm.End();ending=os.clock();if F.Emitter then F.Emitter.Enabled=false end end
function F.Stop()
 Cataclysm.Stop()
 Epic.Stop()
 F.Token+=1;for _,c in ipairs(connections)do c:Disconnect()end;connections={};Run:UnbindFromRenderStep('DOGROTS_EventCamera')
 for _,d in ipairs(dogs)do d.Animation:Destroy()end
 if root then root:ClearAllChildren()end;models={};rain={};beams={};dogs={};F.Visuals={};F.Emitter=nil;F.EmitterPart=nil;signatureUntil=0;def=nil;F.Shadow=nil
end
return F

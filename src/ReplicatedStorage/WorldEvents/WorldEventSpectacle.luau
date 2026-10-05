-- DOGROTS: bounded client-side event set pieces. No physics or gameplay changes.
local Run=game:GetService('RunService')
local Players=game:GetService('Players')
local Debris=game:GetService('Debris')
local RS=game:GetService('ReplicatedStorage')
local V=require(script.Parent.WorldEventObjects)
local Route=require(script.Parent.Parent.MapRouting)
local E={}
local root,hero,event,connection,near,startTime,ending,quality
local heading=CFrame.identity
-- Set pieces are authored around `center` and fitted into a window of sky in front of
-- the player: about 480 studs away, centred ~16 degrees above the horizon, so the whole
-- piece is in view with the default camera instead of towering out of frame.
local center=Vector3.new(0,135,-110)
local STAGE_DISTANCE,STAGE_RADIUS=480,116
local extent={BONE_RAIN=90,GOLDEN_HOUR=106,DOG_RUSH=78,TREASURE_FEVER=74,CRYSTAL_STORM=84,EARTHQUAKE=88,TIME_WARP=98,CURSED_FOG=84,BLACKOUT=94,UFO_INVASION=66,RAINBOW_RIFT=92,NULL_HOUR=62,THE_VOID_OPENS=84}
-- Thick fog hides distant geometry; its guardian stands closer.
local distance={CURSED_FOG=330}
local stageScale,stageOffset=1.4,Vector3.zero
local movers,visuals,emitters,sweeps,waves,actors={},{},{},{},{},{}
local signatureUntil,nextPulse,shakeUntil=0,0,0
local white=Color3.fromRGB(255,244,211)
local C=Color3.fromRGB
local function low()return quality.Debris<=8 end
local function high()return quality.Debris>24 end
local function reduced()return Players.LocalPlayer:GetAttribute('ReducedMotion')==true or low()end
local function position()
 local c=Players.LocalPlayer.Character
 local p=c and c:FindFirstChild('HumanoidRootPart')
 return p and p.Position or Route.Position('WelcomeHub')or Vector3.zero
end
local function floorAt(p)
 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Include
 local map=workspace:FindFirstChild('DOGROTS_District')
 params.FilterDescendantsInstances=map and {map}or {}
 params.RespectCanCollide=true
 local hit=workspace:Raycast(p+Vector3.new(0,25,0),Vector3.new(0,-100,0),params)
 return hit and hit.Position or p-Vector3.new(0,3,0)
end
local function stagePoint(at)return near+heading:VectorToWorldSpace(at*stageScale+stageOffset)end
local function part(parent,name,pos,size,color,neon,alpha)
 local p=V.Part(parent,name,pos,size,color,neon and Enum.Material.Neon or Enum.Material.SmoothPlastic)
 p.Transparency=alpha or 0
 table.insert(visuals,p)
 return p
end
local function ball(parent,name,pos,size,color,alpha)
 local p=part(parent,name,pos,Vector3.one*size,color,true,alpha)
 p.Shape=Enum.PartType.Ball
 return p
end
local function dome(parent,name,pos,size,color,material,alpha)
 local p=V.Ellipsoid(parent,name,size,CFrame.new(pos),color,material)
 p.Transparency=alpha or 0;table.insert(visuals,p)
 return p
end
local function model(name,parent)
 local m=Instance.new('Model');m.Name=name;m.Parent=parent or hero
 m.WorldPivot=CFrame.identity
 return m
end
local function line(parent,a,b,width,color,alpha)
 local p=part(parent,'EnergyLine',(a+b)/2,Vector3.new(width,width,(a-b).Magnitude),color,true,alpha)
 p.CFrame=CFrame.lookAt((a+b)/2,b)
 return p
end
local function ring(parent,radius,color,count,width,rainbow,glow)
 local r=V.Ring(parent,radius,width,width,color,count,.1,rainbow)
 for _,p in ipairs(r.Parts)do table.insert(visuals,p)end
 if glow and high()then
  local g=V.Ring(r.Model,radius,width*3.4,width*1.6,color,count,.82,rainbow)
  for _,p in ipairs(g.Parts)do p.Name='EnergyGlow';table.insert(visuals,p)end
 end
 return r.Model
end
local function spin(m,offset,axis,speed)
 table.insert(movers,{Model=m,Offset=offset,Axis=axis,Speed=speed})
end
local function particles(parent,color,rate,size,smoke)
 local e=V.Particles(parent,color,rate,size)
 e.Texture=smoke and 'rbxasset://textures/particles/smoke_main.dds'or 'rbxasset://textures/particles/sparkles_main.dds'
 e.Lifetime=NumberRange.new(smoke and 5 or 2,smoke and 8 or 4)
 e.Speed=NumberRange.new(smoke and 3 or 5,smoke and 8 or 16)
 e.SpreadAngle=Vector2.new(180,180)
 e.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.2,smoke and .94 or .2),NumberSequenceKeypoint.new(1,1)})
 if smoke then e.LightEmission=.08;e.Color=ColorSequence.new(C(129,123,142))end
 e.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,size*.35),NumberSequenceKeypoint.new(.5,size),NumberSequenceKeypoint.new(1,size*.1)})
 table.insert(emitters,{Emitter=e,Rate=rate})
 return e
end
local function bone(parent,size,glow)
 local m=Instance.new('Model');m.Name='SkyBone';m.Parent=parent;m.WorldPivot=CFrame.identity
 local color=glow and C(255,240,206)or white
 local shaft=part(m,'Shaft',Vector3.zero,Vector3.new(size*4,size*.78,size*.78),color,glow);shaft.Shape=Enum.PartType.Cylinder
 for _,x in ipairs({-2,2})do for _,z in ipairs({-.38,.38})do
  local p=ball(m,'Knuckle',Vector3.new(x*size,0,z*size),size*1.3,color)
  if not glow then p.Material=Enum.Material.SmoothPlastic end
 end end
 return m
end
local function spear(parent,w,h,color)
 local m=Instance.new('Model');m.Name='StormSpear';m.Parent=parent;m.WorldPivot=CFrame.identity
 local body=part(m,'Crystal',Vector3.zero,Vector3.new(w,h,w),color,true,.06);body.CFrame=CFrame.Angles(0,math.pi/4,0)
 for _,side in ipairs({-1,1})do
  local tip=Instance.new('WedgePart');tip.Name='CrystalFacet';tip.Size=Vector3.new(w*.72,h*.3,w*.72)
  tip.Color=side==1 and C(236,250,255)or color:Lerp(C(158,103,255),.5);tip.Material=Enum.Material.Neon
  tip.Anchored=true;tip.CanCollide=false;tip.CanTouch=false;tip.CanQuery=false;tip.CastShadow=false
  tip.CFrame=CFrame.new(0,side*(h/2+h*.15),0)*CFrame.Angles(side<0 and math.pi or 0,math.pi/4,0);tip.Parent=m
  table.insert(visuals,tip)
 end
 return m
end
local function rock(parent,size,color,vein)
 local m=Instance.new('Model');m.Name='UpliftedBoulder';m.Parent=parent;m.WorldPivot=CFrame.identity
 local a=part(m,'Rock',Vector3.zero,size,color,false);a.Material=Enum.Material.Basalt
 local b=part(m,'Rock',Vector3.zero,size*Vector3.new(.78,.9,.72),color:Lerp(C(30,22,20),.25),false);b.Material=Enum.Material.Basalt
 b.CFrame=CFrame.Angles(.5,.7,.3)
 if vein then local v=part(m,'MagmaVein',Vector3.zero,Vector3.new(size.X*1.02,.25,size.Z*.16),vein,true);v.CFrame=CFrame.Angles(.2,.4,.1)end
 return m
end
-- Box-built dog, used only when the menu models are unavailable.
local function boxDog(parent,scale,color)
 local m=Instance.new('Model');m.Name='RushDog';m.Parent=parent;m.WorldPivot=CFrame.identity
 part(m,'Body',Vector3.new(0,2,0)*scale,Vector3.new(2,2,4)*scale,color)
 part(m,'Head',Vector3.new(0,3,-2)*scale,Vector3.new(2.4,2.3,2)*scale,color)
 for _,x in ipairs({-1,1})do
  part(m,'Ear',Vector3.new(x,4.4,-2)*scale,Vector3.new(.65,1.6,1)*scale,color)
  part(m,'Eye',Vector3.new(x*.6,3.3,-3.05)*scale,Vector3.new(.25,.3,.2)*scale,white,true)
  for _,z in ipairs({-1.2,1.2})do part(m,'Paw',Vector3.new(x*.8,.8,z)*scale,Vector3.new(.7,1.6,.9)*scale,color)end
 end
 part(m,'Nose',Vector3.new(0,2.8,-3.1)*scale,Vector3.new(.6,.4,.4)*scale,C(30,25,35))
 return m
end
-- A real dog from MenuModels, scaled into the sky and animated by the shared player.
local function menuDog(names,height,clip,speed)
 local folder=RS:FindFirstChild('MenuModels');if not folder then return nil end
 for _,n in ipairs(names)do
  local template=folder:FindFirstChild(n)
  if template and template:IsA('Model')then
   local ok,m=pcall(function()return template:Clone()end)
   if ok and m then
    for _,o in ipairs(m:GetDescendants())do
     if o:IsA('BasePart')then o.Anchored=true;o.CanCollide=false;o.CanTouch=false;o.CanQuery=false;o.CastShadow=false
     elseif o:IsA('BaseScript')or o:IsA('ProximityPrompt')or o:IsA('BillboardGui')or o:IsA('Sound')or o:IsA('ClickDetector')then o:Destroy()end
    end
    if not m:GetAttribute('AnimationBaseScale')then m:SetAttribute('AnimationBaseScale',m:GetScale())end
    local _,size=m:GetBoundingBox()
    if size.Y>.01 then m:ScaleTo(m:GetScale()*height/size.Y)end
    m.Parent=root
    local anim
    local player=RS:FindFirstChild('DogAnimationPlayer')
    if player then
     local okRequire,Anim=pcall(require,player)
     if okRequire and Anim then
      local okNew,a=pcall(Anim.new,m,n)
      if okNew and a and a:Play(clip,{Looped=true,Speed=speed or 1})then anim=a end
     end
    end
    local parts={}
    for _,o in ipairs(m:GetDescendants())do if o:IsA('BasePart')then table.insert(parts,o)end end
    return m,anim,parts
   end
  end
 end
 return nil
end
local function actor(kind,names,height,clip,speed,fill,fillT,outline)
 local m,anim,parts=menuDog(names,height,clip,speed)
 if not m then return nil end
 local h=Instance.new('Highlight');h.FillColor=fill;h.FillTransparency=fillT;h.OutlineColor=outline;h.OutlineTransparency=.1
 h.DepthMode=Enum.HighlightDepthMode.Occluded;h.Parent=m
 local row={Kind=kind,Model=m,Animation=anim,Parts=parts,Highlight=h,Fill=fillT}
 table.insert(actors,row)
 return row
end
local function setup()
 local c,id=event.ColorTheme,event.Id
 local n=low()and 24 or high()and 48 or 36
 if id=='BONE_RAIN'then
  local r=ring(hero,78,c,n,2.2,false,true);spin(r,center,Vector3.new(0,.14,1),.12)
  for i=1,(low()and 5 or 12)do
   local a=i*math.pi*2/12
   local b=bone(hero,2.2)
   table.insert(movers,{Model=b,Offset=center,Orbit=Vector3.new(84,66,0),Phase=a,Speed=.22,Axis=Vector3.new(.3,.4,1)})
  end
  local king=bone(hero,11,true);spin(king,center,Vector3.zAxis,.1)
 elseif id=='GOLDEN_HOUR'then
  ball(hero,'GoldenSun',center,69,C(255,222,115))
  ball(hero,'SunCorona',center,86,c,.82)
  ball(hero,'SunHalo',center,112,C(255,214,140),.93)
  for i=1,3 do local r=ring(hero,48+i*13,c,n,1.1);spin(r,center,Vector3.new(0,.2,1),i%2==0 and -.07 or .09)end
  for i=1,12 do
   local a=i*math.pi/6;local m=model('SunRay')
   line(m,Vector3.new(math.cos(a)*56,math.sin(a)*56,0),Vector3.new(math.cos(a)*104,math.sin(a)*104,0),1.6,c,.3)
   spin(m,center,Vector3.zAxis,.06)
  end
 elseif id=='DOG_RUSH'then
  local portal=ring(hero,62,c,n,3,false,true);spin(portal,center,Vector3.new(0,.1,1),.25)
  ball(hero,'PortalCore',center,40,C(255,226,170),.86)
  local alpha=actor('Leader',{'Breadog','Sausagedog','CoffeeDog','DJDoggo'},30,'Walk',2,C(255,198,72),.62,C(255,248,220))
  if alpha then
   local host=alpha.Model.PrimaryPart or alpha.Parts[1]
   if host then particles(host,C(255,214,120),quality.Particles*.6,2.2)end
  else
   local leader=boxDog(hero,8,c);spin(leader,center,Vector3.yAxis,.12)
  end
 elseif id=='TREASURE_FEVER'then
  local m=model('CelestialTreasure')
  part(m,'Chest',Vector3.zero,Vector3.new(27,16,19),C(111,54,25))
  -- The lid hinges on the far top edge and opens towards the sky; the lock faces the player.
  local lid=part(m,'OpenLid',Vector3.zero,Vector3.new(29,4,21),C(163,86,29))
  lid.CFrame=CFrame.new(0,8,-9.5)*CFrame.Angles(math.rad(-58),0,0)*CFrame.new(0,2,10.5)
  for _,x in ipairs({-10,10})do part(m,'GoldBinding',Vector3.new(x,0,0),Vector3.new(2,17,20),c,true)end
  part(m,'Lock',Vector3.new(0,0,10),Vector3.new(5,6,2),white,true)
  local glow=ball(m,'TreasureHeart',Vector3.new(0,10,0),11,c,.35)
  particles(glow,c,quality.Particles,2)
  local _,_,beam=V.Beam(m,Vector3.new(0,8,0),Vector3.new(0,120,0),C(255,226,120),18);beam.Width1=42;V.Soft(beam,.72,.05,.5);beam.LightEmission=1
  spin(m,Vector3.new(0,110,-95),Vector3.yAxis,.18)
  local r=ring(hero,62,c,n,2,false,true);spin(r,Vector3.new(0,115,-95),Vector3.yAxis,.2)
  for i=1,12 do
   local coin=model('TreasureCoin');local p=part(coin,'Coin',Vector3.zero,Vector3.new(.8,6,6),c,true);p.Shape=Enum.PartType.Cylinder
   table.insert(movers,{Model=coin,Offset=Vector3.new(0,110,-95),Orbit=Vector3.new(50,0,50),Phase=i*math.pi/6,Speed=.45,Axis=Vector3.yAxis})
  end
 elseif id=='CRYSTAL_STORM'then
  local r=ring(hero,74,c,n,2,false,true);spin(r,center,Vector3.new(0,.15,1),-.12)
  for i=1,9 do
   local a=i*math.pi*2/9
   local m=spear(hero,9,34+(i%3)*10,i%2==0 and c or C(205,149,255))
   table.insert(movers,{Model=m,Offset=center+Vector3.new(math.cos(a)*64,math.sin(a)*40,0),Axis=Vector3.new(.2,1,.1),Speed=.15,Phase=a})
  end
  ball(hero,'StormCore',center,27,white,.2)
  ball(hero,'StormHalo',center,46,c,.86)
 elseif id=='EARTHQUAKE'then
  -- A torn-up chunk of the district hangs in the sky, dripping magma.
  local island=model('RisenEarth')
  local earth,magma=C(70,52,44),C(255,104,28)
  local layers={{Vector3.new(64,16,54),0},{Vector3.new(50,15,42),-14},{Vector3.new(34,15,28),-27},{Vector3.new(18,14,16),-39},{Vector3.new(8,10,8),-49}}
  for i,row in ipairs(layers)do
   local p=part(island,'RisenRock',Vector3.zero,row[1],earth:Lerp(C(40,30,28),i*.12),false);p.Material=Enum.Material.Basalt
   p.CFrame=CFrame.new(math.sin(i*1.7)*3,row[2],math.cos(i*1.3)*3)*CFrame.Angles(0,i*.6,math.sin(i)*.08)
  end
  local turf=part(island,'TornTurf',Vector3.zero,Vector3.new(60,2.2,50),C(84,132,62),false);turf.Material=Enum.Material.Grass;turf.CFrame=CFrame.new(0,9,0)*CFrame.Angles(0,.05,.02)
  for i=1,6 do local a=i*math.pi/3
   local v=part(island,'MagmaVein',Vector3.zero,Vector3.new(1.4,26,1.4),magma,true)
   v.CFrame=CFrame.new(math.cos(a)*19,-16,math.sin(a)*16)*CFrame.Angles(math.sin(a)*.5,a,math.cos(a)*.5)
  end
  local heart=ball(island,'MagmaHeart',Vector3.new(0,-52,0),12,magma,.2)
  local drip=particles(heart,magma,quality.Particles*.5,2.4);drip.Acceleration=Vector3.new(0,-40,0);drip.SpreadAngle=Vector2.new(25,25);drip.EmissionDirection=Enum.NormalId.Bottom
  spin(island,center,Vector3.yAxis,.05)
  for i=1,math.min(quality.Debris,14)do
   local s=4+i%5*1.4
   local m=rock(hero,Vector3.new(s,s*.8,s),earth,i%3==0 and magma or nil)
   table.insert(movers,{Model=m,Offset=center,Orbit=Vector3.new(84,24,58),Phase=i*2.4,Speed=.12,Axis=Vector3.new(1,1,0)})
  end
 elseif id=='TIME_WARP'then
  local clock=model('AstralClock')
  ring(clock,65,c,n,2,false,true)
  for i=1,12 do local a=i*math.pi/6
   line(clock,Vector3.new(math.sin(a)*51,math.cos(a)*51,0),Vector3.new(math.sin(a)*60,math.cos(a)*60,0),2,white,0)
  end
  ball(clock,'ClockPin',Vector3.zero,6,white,0)
  clock:PivotTo(CFrame.new(center))
  for i=1,2 do local m=model('ClockHand');line(m,Vector3.zero,Vector3.new(0,i==1 and 46 or 32,0),2,c,0);spin(m,center,Vector3.zAxis,i==1 and -1.1 or .24)end
  for i=1,2 do local r=ring(hero,80+i*9,c,n,1);spin(r,center,Vector3.new(0,1,.3),i==1 and .15 or -.15)end
 elseif id=='CURSED_FOG'then
  local guardian=actor('Guardian',{'BooHound','Vampug','Zombark_Roblox'},86,'Idle',.6,C(18,10,28),.18,C(255,64,112))
  if not guardian then
   local m=boxDog(hero,15,C(25,16,37));m.Name='FogGuardian'
   for _,p in ipairs(m:GetDescendants())do if p:IsA('BasePart')then p.Transparency=p.Name=='Eye'and 0 or .4 end end
   spin(m,Vector3.new(0,70,-120),Vector3.yAxis,.025)
  end
  ball(hero,'BloodMoon',Vector3.new(58,142,-165),47,C(194,70,103),.15)
  ball(hero,'BloodHalo',Vector3.new(58,142,-167),70,C(150,40,80),.9)
 elseif id=='BLACKOUT'then
  -- Total eclipse: a black disc rimmed by a bright corona ring and faint streamers.
  local corona=ring(hero,42.5,C(220,234,255),n,4,false,true);spin(corona,center+Vector3.new(0,0,-3),Vector3.zAxis,.02)
  for i=1,12 do
   local a=i*math.pi/6+.13;local m=model('CoronaStreamer');local reach=56+(i%3)*7
   line(m,Vector3.new(math.cos(a)*44,math.sin(a)*44,0),Vector3.new(math.cos(a)*reach,math.sin(a)*reach,0),1.2,C(200,220,255),.45)
   spin(m,center+Vector3.new(0,0,-3.5),Vector3.zAxis,.015)
  end
  local p=ball(hero,'EclipsedSun',center,80,C(4,6,14));p.Material=Enum.Material.SmoothPlastic
  local r=ring(hero,44,c,n,2,false,true);spin(r,center,Vector3.zAxis,-.07)
  for i=1,4 do local r2=ring(hero,58+i*8,c,n,1);spin(r2,center,Vector3.new(.1,.2,1),i%2==0 and -.08 or .08)end
 elseif id=='UFO_INVASION'then
  local m=model('Mothership')
  local hull=dome(m,'Disc',Vector3.zero,Vector3.new(120,13,120),C(40,54,62),Enum.Material.Metal)
  dome(m,'Dome',Vector3.new(0,9,0),Vector3.new(38,23,38),c,Enum.Material.Glass,.25)
  dome(m,'BellyGlow',Vector3.new(0,-6,0),Vector3.new(72,3,72),c,Enum.Material.Neon,.35)
  for i=1,16 do local a=i*math.pi/8;ball(m,'NavigationLight',Vector3.new(math.cos(a)*52,-1,math.sin(a)*52),4,c)end
  local rim=ring(m,57,c,n,2.4,false,true);rim:PivotTo(CFrame.Angles(math.pi/2,0,0))
  local _,_,tractor=V.Beam(m,Vector3.new(0,-8,0),Vector3.new(0,-150,0),c,34);tractor.Width1=70;V.Soft(tractor,.7,.04,.35);tractor.LightEmission=1
  spin(m,Vector3.new(0,130,-75),Vector3.yAxis,.12)
  hull.Reflectance=.08
 elseif id=='RAINBOW_RIFT'then
  for i=1,3 do local r=ring(hero,49+i*14,c,n,3,true,i==3);spin(r,center,Vector3.new(i==1 and .2 or 0,i==2 and 1 or 0,1),i%2==0 and -.14 or .16)end
  ball(hero,'RiftHeart',center,53,C(55,27,81),.35)
  ball(hero,'RiftLight',center,30,C(255,170,240),.5)
 elseif id=='NULL_HOUR'then
  local m=model('NullMonolith');part(m,'Core',Vector3.zero,Vector3.one*49,C(15,12,23))
  for _,x in ipairs({-26,26})do for _,y in ipairs({-26,26})do
   line(m,Vector3.new(x,y,-26),Vector3.new(x,y,26),1.4,c,0)
   line(m,Vector3.new(x,-26,y),Vector3.new(x,26,y),1.4,c,0)
   line(m,Vector3.new(-26,x,y),Vector3.new(26,x,y),1.4,c,0)
  end end
  spin(m,center,Vector3.new(.2,.7,.1),.2)
  for i=1,16 do local shard=model('MissingSector');part(shard,'Fragment',Vector3.zero,Vector3.new(12,2,5),i%2==0 and c or C(230,230,230),true,.15)
   table.insert(movers,{Model=shard,Offset=center,Orbit=Vector3.new(85,35,50),Phase=i*2.4,Speed=.16,Axis=Vector3.new(.3,1,.2)})
  end
 else
  local hole=ball(hero,'Singularity',center,73,C(6,2,14));hole.Material=Enum.Material.SmoothPlastic
  ball(hero,'EventHorizon',center,92,c,.78)
  for i=1,3 do local r=ring(hero,45+i*12,c,n,2,false,i==1);spin(r,center,Vector3.new(.2,.5,1),i%2==0 and -.2 or .14)end
 end
 -- Ground weather around the player's district.
 for i=1,(low()and 3 or 6)do
  local a=i*math.pi/3;local raw=near+Vector3.new(math.cos(a)*95,0,math.sin(a)*95)
  local p=floorAt(raw);local anchor=part(root,'WeatherAnchor',p,Vector3.one,c,false,1)
  local smoke=id=='CURSED_FOG'or id=='EARTHQUAKE'
  particles(anchor,c,quality.Particles/(smoke and 18 or 6),smoke and 28 or 1.5,smoke)
  if id=='BLACKOUT'then
   -- Searchlights sweep the clouds; they are never left frozen at an angle.
   local top,_,beam=V.Beam(root,p,p+Vector3.new(0,170,0),C(214,228,255),3)
   beam.Width1=16;V.Soft(beam,.8,.03,.4);beam.LightEmission=1
   table.insert(sweeps,{Top=top,Base=anchor,Beam=beam,W0=beam.Width0,W1=beam.Width1,Phase=i*1.7,Sweep=52})
  end
 end
end
-- Expanding shockwave on the ground; the band keeps its width while the radius grows.
local function wave(strong)
 if not root or ending then return end
 local p=floorAt(position())+Vector3.new(0,.3,0)
 local r=V.Ring(root,7,strong and 1.4 or .8,.3,event.ColorTheme,low()and 18 or 36,.2,event.Id=='RAINBOW_RIFT',Vector3.xAxis,Vector3.zAxis)
 V.RingSet(r,p,7)
 table.insert(waves,{Ring=r,Center=p,Born=os.clock(),Life=strong and 3.4 or 2.4,From=7,To=strong and 170 or 105})
 Debris:AddItem(r.Model,(strong and 3.4 or 2.4)+.3)
end
local function lightning()
 if not root or ending then return end
 local f=Instance.new('Folder');f.Name='StormDischarge';f.Parent=root
 local finish=floorAt(position()+Vector3.new(math.random(-70,70),0,math.random(-70,70)))
 local previous=finish+Vector3.new(0,180,0)
 for i=1,9 do local p=finish+Vector3.new(i==9 and 0 or math.random(-12,12),180-i*20,i==9 and 0 or math.random(-12,12))
  line(f,previous,p,1.3,event.ColorTheme,.1);previous=p
 end
 Debris:AddItem(f,.65)
end
function E.Signature(duration)
 if not event then return end
 signatureUntil=os.clock()+math.min(duration or 8,20);shakeUntil=os.clock()+1.7
 wave(true)
 if event.Id=='CRYSTAL_STORM'or event.Id=='BLACKOUT'then lightning()end
 for _,row in ipairs(emitters)do row.Emitter:Emit(quality.Particles*2)end
end
local function rotation(axis,a)
 if axis.Magnitude<1e-4 then return CFrame.identity end
 return CFrame.fromAxisAngle(axis.Unit,a)
end
function E.Begin(def,state,budget)
 E.Stop();event=def;quality=budget;near=position();startTime=os.clock();ending=nil
 local cam=workspace.CurrentCamera;local look=cam and cam.CFrame.LookVector or Vector3.new(0,0,-1)
 look=Vector3.new(look.X,0,look.Z);if look.Magnitude<.1 then look=Vector3.new(0,0,-1)end
 heading=CFrame.lookAt(Vector3.zero,look.Unit)
 local ext=extent[def.Id]or 90
 local d=distance[def.Id]or STAGE_DISTANCE
 -- Same apparent size at any distance; centred ~16 degrees up, never below 20 studs.
 stageScale=math.clamp(STAGE_RADIUS*d/STAGE_DISTANCE/ext,.8,2.2)
 local h=math.max(d*math.tan(math.rad(16)),ext*stageScale+20)
 stageOffset=Vector3.new(0,h,-d)-center*stageScale
 root=Instance.new('Folder');root.Name='DOGROTS_EpicEvent';root.Parent=workspace
 hero=Instance.new('Model');hero.Name='SkySpectacle';hero.Parent=root;hero.WorldPivot=CFrame.identity
 setup();nextPulse=os.clock()+4
 -- Static sky components share one world frame before their children animate.
 hero:ScaleTo(stageScale)
 hero:PivotTo(CFrame.new(near)*heading*CFrame.new(stageOffset))
 local accumulator=0
 connection=Run.Heartbeat:Connect(function(dt)
  accumulator+=dt;if accumulator<(low()and .066 or .033)then return end;accumulator=0
  local now=os.clock()
  local t=workspace:GetServerTimeNow()-state.StartTimestamp
  local arrival=math.clamp((now-startTime)/3,0,1)
  local fade=ending and math.clamp((now-ending)/5,0,1)or 0
  local alpha=arrival*(1-fade)
  local p=position()
  if (p-near).Magnitude>300 then
   local delta=p-near;near=p;hero:PivotTo(hero:GetPivot()+delta)
   for _,o in ipairs(root:GetChildren())do if o:IsA('BasePart')then o.Position+=delta end end
  end
  local signature=now<signatureUntil
  for _,row in ipairs(movers)do
   local speed=reduced()and row.Speed*.15 or row.Speed
   local at=row.Offset;local a=t*speed+(row.Phase or 0)
   if row.Orbit then at+=Vector3.new(math.cos(a)*row.Orbit.X,math.sin(a*1.3)*math.max(row.Orbit.Y,12),math.sin(a)*row.Orbit.Z)end
   local motion=Vector3.new(0,reduced()and 0 or math.sin(t*.6)*2,0)
   local spinNow=rotation(row.Axis,a)
   if event.Id=='TIME_WARP'and signature then spinNow=CFrame.identity end
   row.Model:PivotTo(CFrame.new(near+heading:VectorToWorldSpace(at*stageScale+stageOffset)+motion+Vector3.new(0,fade*75,0))*heading*spinNow)
  end
  for _,row in ipairs(actors)do
   local cf,visible
   if row.Kind=='Leader'then
    -- Leaps across the sky and through the golden portal every eight seconds.
    local period=reduced()and 16 or 8
    local u=(t%period)/period
    local function at(k)return stagePoint(center+Vector3.new(-128+256*k,-36+78*math.sin(math.pi*k),6))end
    local here,ahead=at(u),at(math.min(1,u+.02))
    if (ahead-here).Magnitude<.01 then ahead=here+heading.RightVector end
    cf=CFrame.lookAt(here,ahead)
    visible=math.clamp(u/.08,0,1)*math.clamp((1-u)/.08,0,1)
   else
    local breathe=reduced()and 0 or math.sin(t*.5)*1.5
    cf=CFrame.new(stagePoint(center+Vector3.new(0,-32+breathe,0)))*heading*CFrame.Angles(0,math.pi,0)
    visible=signature and 1 or .55
   end
   row.Model:PivotTo(cf+Vector3.new(0,fade*75,0))
   if row.Animation then row.Animation:Step()end
   local v=visible*alpha
   for _,part2 in ipairs(row.Parts)do part2.LocalTransparencyModifier=1-v end
   row.Highlight.FillTransparency=1-(1-row.Fill)*v;row.Highlight.OutlineTransparency=1-.9*v
  end
  for _,row in ipairs(sweeps)do
   if row.Top.Parent and row.Base.Parent then
    local s=reduced()and row.Sweep*.3 or row.Sweep
    row.Top.Position=row.Base.Position+Vector3.new(math.sin(t*.32+row.Phase)*s,170,math.cos(t*.27+row.Phase*1.3)*s)
    row.Beam.Width0=row.W0*alpha;row.Beam.Width1=row.W1*alpha
   end
  end
  for i=#waves,1,-1 do
   local w=waves[i];local age=(now-w.Born)/w.Life
   if age>=1 or not w.Ring.Model.Parent then table.remove(waves,i)
   else local e=1-(1-age)*(1-age);V.RingSet(w.Ring,w.Center,w.From+(w.To-w.From)*e,.2+.8*age)end
  end
  for i=#visuals,1,-1 do
   local p2=visuals[i]
   if p2.Parent then p2.LocalTransparencyModifier=1-alpha else table.remove(visuals,i)end
  end
  for _,row in ipairs(emitters)do row.Emitter.Rate=row.Rate*alpha end
  if not ending and now>nextPulse then
   nextPulse=now+(event.Id=='EARTHQUAKE'and 5 or 10)
   if event.Id=='CRYSTAL_STORM'or event.Id=='BLACKOUT'then lightning()
   elseif event.Id=='EARTHQUAKE'or event.Id=='TIME_WARP'or event.Id=='RAINBOW_RIFT'then wave(false)end
   if event.Id=='EARTHQUAKE'then shakeUntil=now+1 end
  end
 end)
 Run:BindToRenderStep('DOGROTS_EpicCamera',Enum.RenderPriority.Camera.Value+2,function()
  if not event or reduced()or os.clock()>shakeUntil then return end
  local cam=workspace.CurrentCamera
  if not cam or cam.CameraType==Enum.CameraType.Scriptable then return end
  local gain=math.clamp(shakeUntil-os.clock(),0,1)*.13
  cam.CFrame*=CFrame.new(math.noise(os.clock()*22,0)*gain,math.noise(0,os.clock()*27)*gain,0)
 end)
end
function E.End()ending=os.clock()end
function E.Stop()
 if connection then connection:Disconnect();connection=nil end
 Run:UnbindFromRenderStep('DOGROTS_EpicCamera')
 for _,row in ipairs(actors)do if row.Animation then pcall(function()row.Animation:Destroy()end)end end
 if root then root:Destroy();root=nil end
 hero=nil;event=nil;movers={};visuals={};emitters={};sweeps={};waves={};actors={};signatureUntil=0;shakeUntil=0
end
return E

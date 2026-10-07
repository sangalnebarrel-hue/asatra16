-- Shared builders for world event visuals (server pickups and client effects).
local V={}
function V.Part(parent,name,position,size,color,material)
 local p=Instance.new('Part');p.Name=name;p.Size=size;p.Position=position;p.Color=color;p.Material=material or Enum.Material.SmoothPlastic;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false;p.Parent=parent;return p
end
function V.Particles(parent,color,rate,size)
 local e=Instance.new('ParticleEmitter');e.Texture='rbxasset://textures/particles/sparkles_main.dds';e.Color=ColorSequence.new(color);e.Rate=rate;e.Size=NumberSequence.new(size or .35);e.Lifetime=NumberRange.new(1,2);e.Speed=NumberRange.new(1,3);e.SpreadAngle=Vector2.new(40,40);e.LightEmission=.5;e.Parent=parent;return e
end
-- Soft light shaft: transparent at both ends instead of a flat, hard-edged band.
function V.Soft(beam,core,fadeIn,fadeOut)
 core=math.clamp(core or .62,0,.98);fadeIn=fadeIn or .1;fadeOut=fadeOut or .3
 beam.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(fadeIn,core),
  NumberSequenceKeypoint.new(math.max(fadeIn+.01,1-fadeOut),core+(1-core)*.35),NumberSequenceKeypoint.new(1,1)})
end
function V.Beam(parent,a,b,color,width)
 local bottom=V.Part(parent,'BeamBase',a,Vector3.one,color);bottom.Transparency=1
 local top=V.Part(parent,'BeamTop',b,Vector3.one,color);top.Transparency=1
 local x=Instance.new('Attachment');x.Parent=bottom;local y=Instance.new('Attachment');y.Parent=top
 local beam=Instance.new('Beam');beam.Attachment0=x;beam.Attachment1=y;beam.Width0=width;beam.Width1=width*.6;beam.FaceCamera=true;beam.Segments=1
 beam.Color=ColorSequence.new(color);V.Soft(beam,.65,.06,.25);beam.LightEmission=.7;beam.LightInfluence=0;beam.Parent=bottom
 return top,bottom,beam
end
-- Continuous ring of overlapping segments in the plane spanned by U and W.
-- RingSet can grow it later without thickening the band (unlike Model:ScaleTo).
function V.RingSet(ring,center,radius,transparency)
 local n=#ring.Parts;local chord=2*radius*math.sin(math.pi/n)
 for i,p in ipairs(ring.Parts)do
  local a=(i-.5)*2*math.pi/n;local ca,sa=math.cos(a),math.sin(a)
  local radial=ring.U*ca+ring.W*sa;local tangent=ring.W*ca-ring.U*sa
  p.Size=Vector3.new(ring.Thickness,ring.Width,chord+ring.Width*.6)
  p.CFrame=CFrame.fromMatrix(center+radial*radius,ring.N,-radial,tangent)
  if transparency then p.Transparency=transparency end
 end
end
function V.Ring(parent,radius,width,thickness,color,count,alpha,rainbow,U,W)
 local m=Instance.new('Model');m.Name='EnergyRing';m.WorldPivot=CFrame.identity;m.Parent=parent
 U=(U or Vector3.xAxis).Unit;W=(W or Vector3.yAxis).Unit
 local ring={Model=m,Parts={},U=U,W=W,N=W:Cross(U).Unit,Width=width,Thickness=thickness}
 count=math.max(8,count)
 for i=1,count do
  local p=V.Part(m,'EnergyLine',Vector3.zero,Vector3.one,rainbow and Color3.fromHSV(i/count,.7,1)or color,Enum.Material.Neon)
  p.Transparency=alpha or .1;table.insert(ring.Parts,p)
 end
 V.RingSet(ring,Vector3.zero,radius)
 return ring
end
local C=Color3.fromRGB
local function piece(model,name,size,cf,color,material,shape)
 local p=V.Part(model,name,cf.Position,size,color,material);p.CFrame=cf
 if shape then p.Shape=shape end
 return p
end
-- Ball parts are always round; a sphere mesh gives a squashed dome or disc.
function V.Ellipsoid(parent,name,size,cf,color,material)
 local p=V.Part(parent,name,cf.Position,size,color,material);p.CFrame=cf
 local mesh=Instance.new('SpecialMesh');mesh.MeshType=Enum.MeshType.Sphere;mesh.Parent=p
 return p
end
-- A vertical marker so pickups can be found from across a district at night.
local function beacon(core,color,height)
 local a=Instance.new('Attachment');a.Name='BeaconBase';a.Position=Vector3.new(0,-.4,0);a.Parent=core
 local b=Instance.new('Attachment');b.Name='BeaconTop';b.Position=Vector3.new(0,height,0);b.Parent=core
 local beam=Instance.new('Beam');beam.Name='PickupBeacon';beam.Attachment0=a;beam.Attachment1=b;beam.Width0=1.6;beam.Width1=.35;beam.FaceCamera=true;beam.Segments=1
 beam.Color=ColorSequence.new(color);beam.LightEmission=1;beam.LightInfluence=0;V.Soft(beam,.55,.05,.45);beam.Parent=core
 local light=Instance.new('PointLight');light.Name='PickupGlow';light.Color=color;light.Range=12;light.Brightness=1.4;light.Shadows=false;light.Parent=core
end
local function halo(model,color,radius)
 local disc=piece(model,'GroundHalo',Vector3.new(.08,radius*2,radius*2),CFrame.new(0,.58,0)*CFrame.Angles(0,0,math.pi/2),color,Enum.Material.Neon,Enum.PartType.Cylinder)
 disc.Transparency=.62
 return disc
end
local function bone(model,cf,length,thick,color)
 piece(model,'BoneShaft',Vector3.new(length,thick,thick),cf*CFrame.Angles(0,0,0),color,Enum.Material.SmoothPlastic,Enum.PartType.Cylinder)
 for _,x in ipairs({-length/2,length/2})do for _,z in ipairs({-thick*.42,thick*.42})do
  piece(model,'BoneLobe',Vector3.one*thick*1.45,cf*CFrame.new(x,0,z),color,Enum.Material.SmoothPlastic,Enum.PartType.Ball)
 end end
end
local function crystal(model,cf,w,h,color)
 piece(model,'Crystal',Vector3.new(w,h,w),cf*CFrame.Angles(0,math.pi/4,0),color,Enum.Material.Neon)
 local tip=Instance.new('WedgePart');tip.Name='CrystalTip';tip.Size=Vector3.new(w*.72,h*.32,w*.72);tip.Color=color:Lerp(Color3.new(1,1,1),.35);tip.Material=Enum.Material.Neon
 tip.Anchored=true;tip.CanCollide=false;tip.CanTouch=false;tip.CanQuery=false;tip.CastShadow=false;tip.CFrame=cf*CFrame.new(0,h/2+h*.16,0);tip.Parent=model
end
local function chest(model,color,body,lid,band,cursed)
 local base=CFrame.new(0,1.35,0)
 piece(model,'Chest',Vector3.new(3.4,1.7,2.3),base,body,Enum.Material.WoodPlanks)
 piece(model,'ChestLid',Vector3.new(3.55,.75,2.45),base*CFrame.new(0,1.05,.1)*CFrame.Angles(math.rad(-14),0,0),lid,Enum.Material.WoodPlanks)
 for _,x in ipairs({-1.15,1.15})do piece(model,'ChestBand',Vector3.new(.32,1.9,2.42),base*CFrame.new(x,.15,0),band,cursed and Enum.Material.Neon or Enum.Material.Metal)end
 piece(model,'Latch',Vector3.new(.55,.75,.22),base*CFrame.new(0,.45,-1.22),color,Enum.Material.Neon)
 local glow=piece(model,'TreasureGlow',Vector3.new(2.6,.3,1.6),base*CFrame.new(0,1.1,-.1),color,Enum.Material.Neon);glow.Transparency=.25
end
function V.Build(kind,color)
 local model=Instance.new('Model');model.Name=kind
 local p=V.Part(model,'InteractionCore',Vector3.new(0,1,0),Vector3.new(5,1,5),color,Enum.Material.Slate);model.PrimaryPart=p;p.Transparency=1
 if kind=='BonePile'or kind=='GiantBone'then
  local ivory=C(238,229,201)
  halo(model,color,3.2)
  for i=1,3 do bone(model,CFrame.new(0,.95+(i-1)*.62,0)*CFrame.Angles(0,(i-1)*math.pi/3+.35,0),4.6,.78,ivory)end
  beacon(p,color,kind=='GiantBone'and 14 or 24)
 elseif kind=='ChargedCrystal'then
  piece(model,'CrystalBed',Vector3.new(4.6,.9,4.2),CFrame.new(0,.95,0)*CFrame.Angles(0,.4,0),C(58,62,82),Enum.Material.Slate)
  for i=1,6 do local a=i*math.pi*2/6;local h=2.4+(i%3)*1.1
   crystal(model,CFrame.new(math.cos(a)*1.25,1.3+h/2,math.sin(a)*1.25)*CFrame.Angles(math.sin(a)*.32,a,math.cos(a)*.32),.9,h,i%2==0 and color or color:Lerp(Color3.new(1,1,1),.4))
  end
  crystal(model,CFrame.new(0,3.6,0),1.3,5,color)
  local core=piece(model,'StormHeart',Vector3.one*2.4,CFrame.new(0,3,0),color,Enum.Material.Neon,Enum.PartType.Ball);core.Transparency=.55
  halo(model,color,3.4);beacon(p,color,26)
 elseif kind=='TreasureSpot'then
  V.Ellipsoid(model,'DirtMound',Vector3.new(6.4,1.5,5.6),CFrame.new(0,.75,0),C(112,79,50),Enum.Material.Ground)
  chest(model,color,C(121,74,38),C(150,94,46),C(217,170,64))
  for i=1,4 do piece(model,'GoldCoin',Vector3.new(.16,.8,.8),CFrame.new(-1.6+i*.55,1.5+(i%2)*.18,-1.6)*CFrame.Angles(0,0,math.pi/2+i*.4),C(255,206,64),Enum.Material.Neon,Enum.PartType.Cylinder)end
  beacon(p,color,24)
 elseif kind=='CursedCache'then
  piece(model,'CursedRoots',Vector3.new(5.4,.6,4.6),CFrame.new(0,.82,0),C(36,26,44),Enum.Material.Slate)
  chest(model,C(196,92,255),C(44,30,58),C(62,40,80),C(176,82,240),true)
  local wisp=V.Particles(p,C(170,110,210),4,.9);wisp.Texture='rbxasset://textures/particles/smoke_main.dds';wisp.LightEmission=.25;wisp.Lifetime=NumberRange.new(2,3.5);wisp.Speed=NumberRange.new(.6,1.6)
  wisp.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.3,.55),NumberSequenceKeypoint.new(1,1)})
  halo(model,C(176,82,240),3.2);beacon(p,C(196,92,255),22)
 elseif kind=='AlienDigZone'then
  halo(model,color,5.6)
  for i=1,8 do local a=i*math.pi/4;piece(model,'ZoneMarker',Vector3.new(.9,.5,.9),CFrame.new(math.cos(a)*5,.85,math.sin(a)*5)*CFrame.Angles(0,-a,0),color,Enum.Material.Neon)end
  piece(model,'ArtifactBase',Vector3.new(2.4,.8,2.4),CFrame.new(0,1,0)*CFrame.Angles(0,math.pi/4,0),C(46,58,66),Enum.Material.Metal)
  local orb=piece(model,'AlienArtifact',Vector3.one*1.8,CFrame.new(0,2.5,0),color,Enum.Material.Neon,Enum.PartType.Ball);orb.Transparency=.15
  local top,bottom,beam=V.Beam(model,Vector3.new(0,1,0),Vector3.new(0,38,0),color,8);beam.Width1=3;V.Soft(beam,.55,.04,.4)
 elseif kind=='AlienCrate'then
  -- Dropped by a UFO after it beams a dog off the tongue; color = the block tier inside.
  local metal=C(66,80,90);local turn=CFrame.Angles(0,math.pi/8,0)
  halo(model,color,3.4)
  piece(model,'CrateBody',Vector3.new(3.4,2.8,3.4),CFrame.new(0,2.05,0)*turn,metal,Enum.Material.DiamondPlate)
  for _,y in ipairs({1.05,3.05})do piece(model,'CrateBand',Vector3.new(3.6,.32,3.6),CFrame.new(0,y,0)*turn,color,Enum.Material.Neon)end
  for i=1,4 do local a=i*math.pi/2+math.pi/8
   piece(model,'CrateLight',Vector3.one*.55,CFrame.new(math.cos(a)*2.35,2.05,math.sin(a)*2.35),C(151,255,178),Enum.Material.Neon,Enum.PartType.Ball)
  end
  piece(model,'CrateAntenna',Vector3.new(.16,1.5,.16),CFrame.new(.8,4.15,.8),metal,Enum.Material.Metal)
  piece(model,'AntennaTip',Vector3.one*.45,CFrame.new(.8,4.95,.8),C(151,255,178),Enum.Material.Neon,Enum.PartType.Ball)
  beacon(p,color,30)
 else
  p.Transparency=0
 end
 V.Particles(p,color,3,.3);return model
end
return V

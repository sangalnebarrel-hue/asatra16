-- BIBLICALLY ACCURATE DOG, "BE NOT AFRAID". A wheel of gold turns over the island and its
-- eyes open, nine of them, and look at you. Light pours through the roof of the mouth and
-- the dog comes down inside it, turning once, to a falling harp. As it touches the tongue
-- its twenty eyes open in a flash and shine out across the island, and every eye in the
-- sky blinks with it. Six orbs of luck circle it and burst one by one while its halo burns
-- brighter; one of its rays finds you and counts you, twice. Then every eye closes and the
-- light goes back up. Off the tongue (a Lucky pad, in the open) the wheel turns straight
-- over the stage and the light falls from under the wheel itself.
local Players=game:GetService('Players')
local SoundService=game:GetService('SoundService')
local C=Color3.fromRGB
local WHITE=Color3.new(1,1,1)
local GOLD,PALE,CREAM,INK,EMBER=C(255,204,96),C(255,250,236),C(255,238,198),C(14,9,4),C(120,72,12)
local TICK='rbxasset://sounds/volume_slider.ogg'
-- Server seconds: the light comes down, it descends, lands (Blink), rolls, peaks, closes (Blink).
local SHAFT,DESCEND,LAND,ROLL,PEAK,CLOSE=.3,.8,2.8,3.4,6.1,6.6
-- The second whisper's typing speed: its ray locks on as "you" is typed.
local TYPE=.034
local PENTA={1,9/8,5/4,3/2,5/3,2,9/4,5/2,3,10/3,4}
local function smooth(x)x=math.clamp(x,0,1);return x*x*(3-2*x)end
local function out3(x)x=math.clamp(x,0,1);return 1-(1-x)^3 end
local function sineOut(x)return math.sin(math.clamp(x,0,1)*math.pi/2)end
local function backOut(x)x=math.clamp(x,0,1)-1;local c=1.70158;return 1+(c+1)*x*x*x+c*x*x end
local function pulse(el,t)return el>=t and math.exp(-(el-t)*6)or 0 end
-- How open its lids are through a Blink clip started at t0 (shut at t0+.3, open at t0+.6).
local function lids(el,t0)return smooth(math.abs(el-t0-.3)/.3)end
local function curve(points)
 local k={}
 for i,p in ipairs(points)do k[i]=NumberSequenceKeypoint.new(p[1],p[2])end
 return NumberSequence.new(k)
end
local function setSkin(s:SurfaceAppearance,strength:number,tint:Color3)s.EmissiveTint=tint;s.EmissiveStrength=strength end

return function(ctx)
 ctx.WhisperStyle={Font=Enum.Font.Garamond,Color=CREAM,Glitch=0,Chroma=false,Shake=true,Type=.085}
 local Kit,scope,model,config=ctx.Kit,ctx.Scope,ctx.Model,ctx.Config
 local low,calm,origin,hold=ctx.Low,Kit.ReducedMotion(),ctx.Origin,config.Hold
 local SUN=config.Color
 local size=Kit.Size(model)
 local up=Vector3.yAxis
 local joined=ctx:Elapsed()
 -- One-shots fire on time only: a late joiner gets the state, not a pile-up of cues.
 local function fresh(t)return ctx:Elapsed()-t<.35 end
 local venue=ctx.Venue or 'Tongue'
 local roofed=venue=='Tongue'and math.abs(origin.X)<10 and origin.Z<-146.5 and origin.Z>-182
 -- Where it faces: down the line on the tongue; a pad dog faces its opener, so off the
 -- tongue this camera stands in until the rig streams in.
 local function facing():Vector3
  local look:Vector3?=Kit.Root(model)and model:GetPivot().LookVector or nil
  local cam=workspace.CurrentCamera
  if not look and venue~='Tongue'and cam then look=cam.CFrame.Position-origin end
  local flat=look and Vector3.new(look.X,0,look.Z)or Vector3.zero
  return flat.Magnitude>.1 and flat.Unit or Vector3.zAxis
 end
 local fwd=facing()
 -- Under the giant head the light opens in the mouth's roof (underside y=23.5, opening at
 -- z=-146) and the wheel turns high over the head; in the open the wheel hangs straight
 -- over the stage and the light opens under it. The spotlight and the opening's bells hang
 -- where a roof would be: in the mouth's, or as high over an open stage (21.3).
 local top=roofed and Vector3.new(origin.X,23.35,origin.Z)or origin+up*44
 local lid=roofed and top-Vector3.new(0,0,1.2)or top
 local roof=roofed and top-up*.4 or origin+up*21.3
 local SKY=roofed and Vector3.new(origin.X,108,origin.Z-20)or origin+up*54
 local R1=roofed and 18 or 13
 local RISE=roofed and 12 or 15
 -- The second whisper: "...it counted you twice." Its ray finds you on "you", counts on "twice".
 local spoken=config.Whispers and config.Whispers[2]
 local said,text=spoken and spoken[1]or 3,spoken and spoken[2]or ''
 local function typed(word:string,fallback:number):number
  local i=string.find(text,word,1,true)
  return i and said+(i+#word-1)*TYPE or fallback
 end
 local PING1=math.clamp(typed('you',4.9),LAND+.8,5.6)
 local PING2=math.clamp(typed('twice',5.1),PING1+.32,6.1)
 local LOCK=PING1-.25

 -- Bones: the rings carry the twenty eyes, Float the body, Halo the crown.
 local bones:{[string]:Bone}={}
 local wanted={'Float','Halo','Ring_1'}
 for i=1,20 do table.insert(wanted,string.format('Eye_%02d',i))end
 local function refresh()
  for _,name in ipairs(wanted)do
   local b=bones[name]
   if not(b and b.Parent)then
    local found=model:FindFirstChild(name,true)
    if found and found:IsA('Bone')then bones[name]=found else bones[name]=nil end
   end
  end
 end
 refresh()
 local function at(name:string):Vector3?
  local b=bones[name]
  if b and b.Parent then return b.TransformedWorldCFrame.Position end
  return nil
 end
 local function ground():Vector3
  if model.Parent then return ctx:Ground()end
  return origin
 end
 local function center():Vector3 return at('Ring_1')or ground()+up*size.Y*.47 end
 local function crown():Vector3 return at('Halo')or ground()+up*size.Y end
 local function target():(Vector3?,boolean)
  local character=Players.LocalPlayer.Character
  local head=character and (character:FindFirstChild('Head')or character:FindFirstChild('HumanoidRootPart'))
  if head and head:IsA('BasePart')and (head.Position-origin).Magnitude<150 then return head.Position,true end
  local camera=workspace.CurrentCamera
  return camera and camera.CFrame.Position or nil,false
 end
 -- A struck bell: the built-in tick, pitched and drowned in reverb.
 local function bell(speed:number,volume:number,parent:Instance?,decay:number?)
  if not scope.Alive or volume<.01 then return end
  local s=Instance.new('Sound');s.SoundId=TICK;s.Volume=volume;s.PlaybackSpeed=speed
  s.RollOffMinDistance=16;s.RollOffMaxDistance=260
  local r=Instance.new('ReverbSoundEffect');r.DecayTime=decay or 2.6;r.Density=1;r.Diffusion=1;r.WetLevel=0;r.DryLevel=-4;r.Parent=s
  local q=Instance.new('EqualizerSoundEffect');q.LowGain=speed<1 and 6 or -8;q.MidGain=2;q.HighGain=-6;q.Parent=s
  s.Parent=(parent and parent.Parent)and parent or SoundService
  -- Ending the arrival lets a ringing bell fade instead of cutting it off.
  scope:Add(function()if s.Parent then Kit.Tween(s,1,{Volume=0}).Completed:Connect(function()s:Destroy()end)end end)
  s:Play()
  task.delay(5,function()if s.Parent then s:Destroy()end end)
 end

 -- 0: the island hushes, warms and blooms.
 local near=Kit.Near(origin,250)
 scope:Duck(.4,.8)
 local drone=scope:Drone('Choir',low and .24 or .36,.72,joined<.5 and 1.4 or .3)
 local grade=scope:Grade({Brightness=.05+.1*near,Contrast=.07,Saturation=.1,TintColor=C(255,246,220)},joined<.5 and 1.2 or .3)
 local camera=workspace.CurrentCamera
 local bloom:BloomEffect?=nil
 if camera then
  local b=Instance.new('BloomEffect');b.Name='DOGROTS_SecretBloom';b.Intensity=0;b.Size=28;b.Threshold=1.1
  b.Parent=camera;bloom=b
  Kit.Tween(b,1.2,{Intensity=.25+.35*near})
  scope:Add(function()local t=Kit.Tween(b,.8,{Intensity=0});t.Completed:Connect(function()b:Destroy()end)end)
 end

 -- The wheel: a dashed ring of gold carrying eight eyes, a second ring turning through it
 -- and one great eye in the middle. It turns to face whoever looks up at it.
 local count=low and 16 or 24
 local wheel,inner={},{}
 for i=1,count do
  wheel[i]=scope:Part({Name='Wheel',Color=GOLD,Transparency=1,Size=Vector3.new(.8,2*math.pi*R1/count*.72,.8)})
 end
 local R2=R1*.8
 if not low then
  for i=1,20 do inner[i]=scope:Part({Name='Wheel',Color=CREAM,Transparency=1,Size=Vector3.new(.45,2*math.pi*R2/20*.6,.45)})end
 end
 local function ellipsoid(name:string,color:Color3,neon:boolean):Part
  local p=scope:Part({Name=name,Color=color,Transparency=1,Size=Vector3.one*.05,
   Material=neon and Enum.Material.Neon or Enum.Material.SmoothPlastic})
  local m=Instance.new('SpecialMesh');m.MeshType=Enum.MeshType.Sphere;m.Parent=p
  return p
 end
 local eyes={}
 for k=1,8 do
  eyes[k]={White=ellipsoid('Eye',PALE,true),Pupil=ellipsoid('Pupil',INK,false),Iris=nil,W=3.6,H=3.1,P=1.35,I=0,
   Angle=(k-.5)/8*math.pi*2,Open=.3+((k*3)%8)*.07,For=.3}
 end
 local great={White=ellipsoid('GreatEye',PALE,true),Iris=ellipsoid('Iris',GOLD,true),Pupil=ellipsoid('Pupil',INK,false),
  W=8,H=5.2,P=1.5,I=3.3,Angle=0,Open=1,For=.55}
 local face:CFrame?=nil
 local function poseEye(e,pos:Vector3,open:number,view:Vector3,rotation:CFrame)
  local h=e.H*open
  if h<.05 then
   e.White.Transparency=1;e.Pupil.Transparency=1
   if e.Iris then e.Iris.Transparency=1 end
   return
  end
  local to=view-pos
  to=to.Magnitude>.01 and to.Unit or rotation.LookVector
  -- The pupil slides toward the viewer (mostly down: the wheel only half tilts to you).
  local look=rotation.LookVector
  local shift=rotation.RightVector*to:Dot(rotation.RightVector)*e.W*.17+rotation.UpVector*to:Dot(rotation.UpVector)*h*.24
  e.White.Size=Vector3.new(e.W,h,.3);e.White.CFrame=CFrame.new(pos)*rotation;e.White.Transparency=0
  if e.Iris then
   e.Iris.Size=Vector3.new(e.I,math.min(e.I,h*.8),.2);e.Iris.CFrame=CFrame.new(pos+look*.16+shift)*rotation;e.Iris.Transparency=0
  end
  e.Pupil.Size=Vector3.new(e.P,math.min(e.P,h*.5),.2);e.Pupil.CFrame=CFrame.new(pos+look*(e.Iris and .27 or .19)+shift)*rotation
  e.Pupil.Transparency=0
 end

 -- The light: an opening in the roof, a shaft of light to the stage, a spotlight, six
 -- god-rays twisting round it and motes of gold falling through it.
 local length=top.Y-origin.Y
 local mid=origin+up*(length/2)
 local upright=CFrame.Angles(0,0,math.pi/2)
 local shaft=scope:Part({Name='Shaft',Shape=Enum.PartType.Cylinder,Color=CREAM,Transparency=1,Size=Vector3.new(length,.1,.1),CFrame=CFrame.new(mid)*upright})
 local core=scope:Part({Name='ShaftCore',Shape=Enum.PartType.Cylinder,Color=PALE,Transparency=1,Size=Vector3.new(length,.1,.1),CFrame=CFrame.new(mid)*upright})
 local opening=scope:Part({Name='Opening',Shape=Enum.PartType.Cylinder,Color=PALE,Transparency=1,Size=Vector3.new(.2,8.5,8.5),CFrame=CFrame.new(lid)*upright})
 local corona=scope:Part({Name='Corona',Shape=Enum.PartType.Cylinder,Color=GOLD,Transparency=1,Size=Vector3.new(.1,11,11),CFrame=CFrame.new(lid-up*.08)*upright})
 local heaven=scope:Anchor(roof,'Heaven')
 local spot=Instance.new('SpotLight');spot.Face=Enum.NormalId.Bottom;spot.Angle=50;spot.Range=25
 spot.Brightness=0;spot.Color=CREAM;spot.Shadows=false;spot.Parent=heaven
 local streams={}
 local hubTop,hubLow
 if not low then
  hubTop=scope:Anchor(top-up*.3,'RaysTop');hubLow=scope:Anchor(origin+up*.4,'RaysLow')
  for k=1,6 do
   local a=k/6*math.pi*2
   local t0=Instance.new('Attachment');t0.Position=Vector3.new(math.cos(a)*3.4,0,math.sin(a)*3.4);t0.Parent=hubTop
   local t1=Instance.new('Attachment');t1.Position=Vector3.new(math.cos(a)*3,0,math.sin(a)*3);t1.Parent=hubLow
   streams[k]=scope:Beam(t0,t1,PALE,0,{Color=ColorSequence.new(PALE,SUN),Segments=1,Brightness=1.5,
    Transparency=curve({{0,.4},{.7,.65},{1,.95}})})
  end
 end
 local motes=scope:Part({Name='Motes',Size=Vector3.new(7,math.max(length-2,1),7),CFrame=CFrame.new(mid),Transparency=1})
 local dust=scope:Emitter(motes,{Shape=Enum.ParticleEmitterShape.Box,EmissionDirection=Enum.NormalId.Bottom,
  Color=ColorSequence.new(PALE,SUN),Lifetime=NumberRange.new(2.5,4),Speed=NumberRange.new(.6,1.8),SpreadAngle=Vector2.new(15,15),
  Acceleration=Vector3.new(0,-.4,0),Size=curve({{0,.05},{.3,.28},{1,0}}),Transparency=curve({{0,1},{.2,.15},{1,1}}),
  Rotation=NumberRange.new(0,360),RotSpeed=NumberRange.new(-60,60)})
 -- The open air's taller shaft falls as thick with them as the mouth's.
 local MOTES=(low and 4 or 14)*(roofed and 1 or length/21.3)
 -- Its own light rides the Float bone (lights under the district get throttled).
 local heart=scope:Anchor(origin+up*3,'Heart')
 local warm=scope:Light(heart,SUN,16,0)

 -- The mouth turns gold: runes from the throat outward, the mist, the nearest lanterns;
 -- the tongue's warm edges catch it when it lands. All of it eases back as it closes.
 -- (Only on the tongue: an open stage has none of them.)
 local restore={}
 -- Tweens on world props stop with the arrival, or one in flight would undo the restore.
 local function ease(o:Instance,seconds:number,props:{[string]:any})
  local t=Kit.Tween(o,seconds,props)
  scope:Add(function()t:Cancel()end)
 end
 local function tint(o:Instance,props:{[string]:any},seconds:number?)
  local saved={}
  for k in pairs(props)do saved[k]=(o::any)[k]end
  if seconds then scope:Override(o,saved);ease(o,seconds,props)else scope:Override(o,props)end
  table.insert(restore,{o,saved})
 end
 local district=venue=='Tongue'and workspace:FindFirstChild('DOGROTS_District')or nil
 local factory=district and district:FindFirstChild('02_DogFactory')
 local tunnel=factory and factory:FindFirstChild('DarkMouthTunnel')
 local line=district and district:FindFirstChild('03_DogLine')
 local runes,guides,lamps={},{},{}
 if tunnel then
  for _,o in ipairs(tunnel:GetDescendants())do
   if o.Name=='MouthRune'and o:IsA('BasePart')then table.insert(runes,o)
   elseif o:IsA('ParticleEmitter')then scope:Override(o,{Color=ColorSequence.new(PALE,GOLD)})end
  end
  table.sort(runes,function(a,b)return (a.Position-origin).Magnitude>(b.Position-origin).Magnitude end)
 end
 if line then
  for _,lantern in ipairs(line:GetChildren())do
   local lens=lantern.Name=='PromenadeLantern'and lantern:FindFirstChild('WarmLens')
   if lens and lens:IsA('BasePart')and (lens.Position-origin).Magnitude<30 then
    table.insert(lamps,{lens,{Color=PALE}})
    for _,l in ipairs(lantern:GetDescendants())do
     if l:IsA('PointLight')then table.insert(lamps,{l,{Color=SUN}})end
    end
   end
  end
  local tongue=line:FindFirstChild('Tongue')
  for _,g in ipairs(tongue and tongue:GetChildren()or {})do
   if g.Name=='WarmEdgeGuide'and g:IsA('BasePart')and math.abs(g.Position.Z-origin.Z)<70 then table.insert(guides,g)end
  end
 end

 -- The dog waits in the light until it descends (a client this late sees it landed).
 local vis=joined<LAND and scope:Visibility(model)or nil
 local lift=joined<LAND and scope:Offset(model)or nil
 local hidden=-1
 local function hide(v:number)
  if vis and math.abs(v-hidden)>.004 then hidden=v;vis.Set(v)end
 end
 hide(1)
 if lift then lift.CFrame=CFrame.new(0,RISE,0)end

 -- Its skin: the halo burns brighter through the rolls, everything flares as it lands.
 local skins,seen={},{}
 local function grab(o:Instance)
  if not o:IsA('SurfaceAppearance')or seen[o]then return end
  local ok,strength,hue=pcall(function()return o.EmissiveStrength,o.EmissiveTint end)
  if not ok then return end
  seen[o]=true
  local part=o.Parent
  table.insert(skins,{Look=o,Strength=strength,Hue=hue,Halo=part~=nil and string.find(string.lower(part.Name),'halo',1,true)~=nil})
  scope:Override(o,{EmissiveStrength=strength,EmissiveTint=hue})
 end
 for _,o in ipairs(model:GetDescendants())do grab(o)end
 scope:Add(model.DescendantAdded:Connect(grab))

 -- Six orbs of luck, two on each of three heights, orbiting the opposite ways.
 local orbs={}
 for k=1,6 do
  local level=(k-1)%3
  local p=scope:Part({Name='Luck',Shape=Enum.PartType.Ball,Color=SUN,Transparency=1,Size=Vector3.one*.8})
  orbs[k]={Part=p,Pop=ROLL+.4*k,H=size.Y*(.2+.3*level),Phase=level*2.1+(k>3 and math.pi or 0),Dir=level%2==0 and 1 or -1,
   Spark=(not low)and scope:Emitter(p,{Color=ColorSequence.new(PALE,SUN),Lifetime=NumberRange.new(.3,.6),
    Speed=NumberRange.new(0,1),Size=NumberSequence.new(.3,0)})or nil}
 end
 -- A rising ✦ for every roll (KeepFont before parenting, or the place typography swaps it).
 local function star(from:Vector3)
  local a=scope:Anchor(from,'Roll')
  local g=Instance.new('BillboardGui');g.Name='Roll';g.Adornee=a;g.AlwaysOnTop=true;g.LightInfluence=0
  g.MaxDistance=220;g.Size=UDim2.fromScale(2.6,2.6)
  local l=Instance.new('TextLabel');l.Name='Star';l:SetAttribute('KeepFont',true)
  l.BackgroundTransparency=1;l.AnchorPoint=Vector2.new(.5,.5);l.Position=UDim2.fromScale(.5,.5);l.Size=UDim2.fromScale(0,0)
  l.Font=Enum.Font.Garamond;l.Text='✦';l.TextScaled=true;l.TextColor3=SUN;l.TextStrokeColor3=EMBER;l.TextStrokeTransparency=.4
  l.Parent=g;g.Parent=a
  scope:Life(a,1.3,function(t)
   a.CFrame=CFrame.new(from+up*2.4*out3(t))
   local s=backOut(t/.25)
   l.Size=UDim2.fromScale(s,s)
   local fade=smooth((t-.55)/.45)
   l.TextTransparency=fade;l.TextStrokeTransparency=.4+.6*fade
  end)
 end

 -- Its twenty eyes shine out along the rings (made as it lands); one finds you.
 local rays={}
 local ends:BasePart?=nil
 local mine:any=nil
 local hl:Highlight?=nil
 local function shine()
  if low then return end
  refresh()
  -- The rig has streamed in by now: its real facing.
  fwd=facing()
  local anchor=scope:Anchor(origin,'RayEnds')
  ends=anchor
  for i=1,20 do
   local b=bones[string.format('Eye_%02d',i)]
   if b then
    local tip=Instance.new('Attachment');tip.Parent=anchor
    local beam=scope:Beam(b,tip,SUN,0,{Color=ColorSequence.new(PALE,SUN),Segments=1,Brightness=2,
     Transparency=curve({{0,.05},{.6,.35},{1,1}})})
    table.insert(rays,{Bone=b,Tip=tip,Beam=beam,Dir=fwd})
   end
  end
 end

 local kick,lookup=0,0
 scope:Every(function(dt)
  local el=ctx:Elapsed()
  local now=os.clock()
  if now>=lookup then lookup=now+.5;refresh()end
  local cam=workspace.CurrentCamera
  local view=cam and cam.CFrame.Position or SKY+fwd*120-up*40
  kick*=math.exp(-dt*5)
  local landed=el>=LAND and math.exp(-(el-LAND)*2.5)or 0
  local closing=1-smooth((el-CLOSE)/.7)
  local blink=lids(el,LAND)

  -- The wheel, half tilted toward this viewer and turning.
  local d=view-SKY
  local want=Kit.LookAt(SKY,SKY+Vector3.new(d.X,d.Y*.6,d.Z)).Rotation
  local rotation=face and face:Lerp(want,math.min(1,dt*2.5))or want
  face=rotation
  local frame=CFrame.new(SKY)*rotation
  local spin=el*.3
  local fadeWheel=1-smooth((el-CLOSE-.1)/.7)
  for i,p in ipairs(wheel)do
   p.CFrame=frame*CFrame.Angles(0,0,i/count*math.pi*2+spin)*CFrame.new(R1,0,0)
   p.Transparency=1-.92*smooth((el-(i-1)/count*.7)/.15)*fadeWheel
  end
  if #inner>0 then
   local cross=frame*CFrame.Angles(0,math.pi/2+el*.8,0)
   local alpha=1-.6*smooth((el-.5)/.6)*fadeWheel
   for i,p in ipairs(inner)do
    p.CFrame=cross*CFrame.Angles(0,0,i/#inner*math.pi*2-spin*1.5)*CFrame.new(R2,0,0)
    p.Transparency=alpha
   end
  end
  for _,e in ipairs(eyes)do
   local pos=(frame*CFrame.Angles(0,0,e.Angle+spin)*CFrame.new(R1,0,-.7)).Position
   poseEye(e,pos,out3((el-e.Open)/e.For)*blink*(1-smooth((el-CLOSE)/.28)),view,rotation)
  end
  poseEye(great,(frame*CFrame.new(0,0,-.4)).Position,out3((el-great.Open)/great.For)*lids(el,LAND+.05)*(1-smooth((el-CLOSE-.15)/.3)),view,rotation)

  -- The light: in from 0.3, the core thins once it has landed, all of it gone by 7.3.
  local beam=out3((el-SHAFT)/.7)*closing
  local w=.3+7.7*beam*(1+.025*math.sin(el*7))
  shaft.Size=Vector3.new(length,w,w);shaft.CFrame=CFrame.new(mid)*upright;shaft.Transparency=1-.22*beam
  local hot=out3((el-SHAFT)/.4)*(1-smooth((el-LAND)/.6))
  core.Size=Vector3.new(length,2.8*hot+.05,2.8*hot+.05);core.CFrame=CFrame.new(mid)*upright;core.Transparency=1-.45*hot
  local open=out3((el-SHAFT)/.25)*closing
  opening.Transparency=1-.95*open;corona.Transparency=1-.4*open
  spot.Brightness=8*beam
  if hubTop and hubLow then
   hubTop.CFrame=CFrame.new(top-up*.3)*CFrame.Angles(0,el*.5,0)
   hubLow.CFrame=CFrame.new(origin+up*.4)*CFrame.Angles(0,el*.5+1.1,0)
   local g=smooth((el-SHAFT-.2)/.6)*closing
   for _,s in ipairs(streams)do s.Width0=1.5*g;s.Width1=.25*g end
  end

  -- It comes down through the light, turning once (Sine Out: no bump at the bottom).
  if lift then
   local u=(el-DESCEND)/(LAND-DESCEND)
   if u<1 then
    lift.CFrame=CFrame.new(0,RISE*(1-sineOut(u)),0)*CFrame.Angles(0,calm and 0 or math.pi*2*out3(u),0)
    hide(1-smooth((el-DESCEND)/.5))
   else
    lift.CFrame=CFrame.identity;hide(0)
   end
  end
  heart.CFrame=CFrame.new(at('Float')or ground()+up*size.Y*.5)
  warm.Brightness=(1.6*smooth((el-DESCEND)/1)+3*landed+1.2*kick)*closing

  -- Its eyes' rays sweep with the turning rings; after the lock only yours is left.
  local anchor=ends
  if anchor and #rays>0 then
   local c=center()
   local grow=out3((el-LAND)/.3)
   local others=1-smooth((el-LOCK)/.6)
   local goal,head=nil,false
   if mine then goal,head=target()end
   for _,r in ipairs(rays)do
    local b=r.Bone
    if b.Parent then
     local p=b.TransformedWorldCFrame.Position
     local dir=p-c
     dir=dir.Magnitude>.05 and (dir.Unit+fwd*.4).Unit or fwd
     r.Dir=dir
     local reach,width=26*grow,others
     if r==mine and goal then
      local lock=out3((el-LOCK)/.22)
      local to=goal-p
      local dist=to.Magnitude
      if dist>.5 then
       local blend=dir:Lerp(to/dist,lock)
       if blend.Magnitude>.05 then dir=blend.Unit end
       reach+=((head and dist or math.min(dist-4,30))-reach)*lock
      end
      width=(1-smooth((el-PING2-.8)/.6))*(1+1.6*(pulse(el,PING1)+pulse(el,PING2)))
     end
     r.Tip.Position=p+dir*math.max(reach,.1)-anchor.Position
     r.Beam.Width0=.1*width*blink*grow;r.Beam.Width1=.42*width*blink*grow
    else
     r.Beam.Width0=0;r.Beam.Width1=0
    end
   end
  end

  -- The orbs come out of its halo into orbit; each swells and goes on its roll.
  if el>=ROLL then
   local g,from=ground(),crown()
   for k,o in ipairs(orbs)do
    local p=o.Part
    local age=el-ROLL-.05*k
    -- Waiting in the halo (its sparks are already on, so it must not sit at its spawn point).
    if age<0 then p.Transparency=1;p.CFrame=CFrame.new(from)
    elseif el<o.Pop then
     local th=o.Phase+o.Dir*1.8*(el-ROLL)
     local orbit=g+Vector3.new(math.cos(th)*5,o.H,math.sin(th)*5)
     p.Size=Vector3.one*.8*(1+.12*math.sin(el*9+k))
     p.CFrame=CFrame.new(from:Lerp(orbit,backOut(age/.5)))
     p.Transparency=.05
    else
     local s=(el-o.Pop)/.16
     if s<1 then p.Size=Vector3.one*(.8+1.4*s);p.CFrame=CFrame.new(p.Position);p.Transparency=.05+.95*s else p.Transparency=1 end
     if o.Spark then o.Spark.Rate=0 end
    end
   end
  end

  -- The halo: warm on the way down, burning through the rolls, out as the eyes close.
  local rise=math.max(.3*smooth((el-DESCEND)/2),smooth((el-ROLL)/(PEAK-ROLL)))
  for _,s in ipairs(skins)do
   if s.Look.Parent then
    local strength=s.Halo and s.Strength+((1-s.Strength)*rise+.8*kick+1.2*landed)*closing
     or s.Strength+(.5*landed+.15*kick)*closing
    local glow=math.min(1,(s.Halo and .8 or .5)*closing*math.max(rise,landed))
    pcall(setSkin,s.Look,strength,s.Hue:Lerp(SUN,glow))
   end
  end
  if hl then
   hl.FillTransparency=1-math.min(.5*landed+.25*kick+.07,1)*closing
   hl.OutlineTransparency=1-.6*closing*smooth((el-LAND)/.3)
  end
  return el<hold+1
 end)

 -- 0: the wheel draws itself; its eyes open one after another, the great one last.
 task.spawn(function()
  for j=0,7 do
   local t=.3+j*.07
   if not ctx:Wait(t)then return end
   if fresh(t)then bell(1.2*PENTA[j+3],.1)end
  end
  if not ctx:Wait(1)then return end
  if fresh(1)then bell(.75,.32,nil,3.6)end
 end)
 if fresh(0)then Kit.Cue('Whoosh',nil,.3)end

 -- 0.3: the roof opens and the light comes down; the runes catch from the throat outward.
 if not ctx:Wait(SHAFT)then return end
 dust.Rate=MOTES
 for _,lamp in ipairs(lamps)do if lamp[1].Parent then tint(lamp[1],lamp[2],.6)end end
 for i,p in ipairs(runes)do
  task.delay(math.max(0,SHAFT+math.floor((i-1)/2)*.08-ctx:Elapsed()),function()
   if not scope.Alive or not p.Parent then return end
   tint(p,{Color=PALE});ease(p,.4,{Color=GOLD})
  end)
 end
 if fresh(SHAFT)then
  Kit.Cue('Whoosh',heaven,.55)
  for i,step in ipairs({1,5/4,3/2})do
   task.delay((i-1)*.05,function()bell(1.2*step,.18,heaven,3)end)
  end
 end

 -- 0.8: it comes down through the light to a falling harp.
 if not ctx:Wait(DESCEND)then return end
 if fresh(DESCEND)then scope:Burst(top-up*1.2,PALE,20,{Speed=NumberRange.new(2,6),Lifetime=NumberRange.new(.6,1.1),Drag=2,Size=NumberSequence.new(.35,0)})end
 task.spawn(function()
  local harp=.5+.5*Kit.Near(origin,200)
  for i=1,11 do
   local t=DESCEND+(i-1)*.17
   if not ctx:Wait(t)then return end
   if fresh(t)then bell(.85*PENTA[12-i],(.12+.18*i/11)*harp,nil,2.2)end
  end
 end)

 -- 2.8: it touches down. Its eyes open in a flash; the sky blinks with it.
 if not ctx:Wait(LAND)then return end
 ctx.WhisperStyle={Font=Enum.Font.Garamond,Color=CREAM,Glitch=0,Chroma=false,Shake=false,Type=TYPE}
 ctx:Title({Font=Enum.Font.Garamond,Hold=4})
 shine()
 hl=scope:Highlight(model,SUN,PALE,1,1)
 if fresh(LAND)then
  local n=Kit.Near(origin,120)
  Kit.Cue('Sting',nil,.4+.35*Kit.Near(origin,220))
  Kit.Cue('Chime',nil,.5)
  Kit.Cue('Impact',heart,.35)
  if n>.05 then
   Kit.Flash(PALE,1-.55*n,.5)
   Kit.Shake(.18*n,.5)
   Kit.FOVPunch(-4*n,.2,1.1)
  end
  scope:Ring(origin+up*.25,SUN,1.5,22,1.3,{Thickness=.35,Segments=28})
  if not low then scope:Ring(origin+up*.3,PALE,1,13,.9,{Thickness=.18,Alpha=.35,Segments=20})end
  scope:Burst(center(),PALE,36,{Speed=NumberRange.new(8,16),Lifetime=NumberRange.new(.5,1),Drag=3,Size=NumberSequence.new(.45,0)})
 end
 for _,g in ipairs(guides)do
  local when=LAND+math.abs(g.Position.Z-origin.Z)/70
  task.delay(math.max(0,when-ctx:Elapsed()),function()
   if not scope.Alive or not g.Parent then return end
   tint(g,{Color=PALE});ease(g,.5,{Color=GOLD})
  end)
 end

 -- As "you" is typed one ray leaves the rest and finds you; it counts you, twice.
 task.spawn(function()
  if not ctx:Wait(LOCK)then return end
  local goal=target()
  if goal and #rays>0 then
   local best,score=nil,-2
   for _,r in ipairs(rays)do
    if r.Bone.Parent then
     local s=r.Dir:Dot((goal-r.Bone.TransformedWorldCFrame.Position).Unit)
     if s>score then best,score=r,s end
    end
   end
   if best then
    best.Beam.Color=ColorSequence.new(WHITE,PALE);best.Beam.Transparency=NumberSequence.new(0,.2)
    mine=best
   end
  end
  for i,t in ipairs({PING1,PING2})do
   if not ctx:Wait(t)then return end
   if fresh(t)then
    local you,head=target()
    if you and head then
     scope:Burst(you+up*.6,SUN,14,{Speed=NumberRange.new(2,5),Lifetime=NumberRange.new(.4,.7),Drag=2,Size=NumberSequence.new(.35,0)})
    end
    bell(.72,i==1 and .4 or .5,nil,3.4)
   end
  end
 end)

 -- 3.4 Ability_MultiRoll: six rolls of luck.
 if not ctx:Wait(ROLL)then return end
 for _,o in ipairs(orbs)do if o.Spark then o.Spark.Rate=6 end end
 if fresh(ROLL)then Kit.Cue('Whoosh',heart,.3)end
 for k,o in ipairs(orbs)do
  if not ctx:Wait(o.Pop)then return end
  if fresh(o.Pop)then
   local p=o.Part.Position
   scope:Burst(p,SUN,18,{Speed=NumberRange.new(3,8),Lifetime=NumberRange.new(.4,.8),Drag=3,Size=NumberSequence.new(.4,0)})
   star(p)
   bell(1.5*PENTA[k+2],.3,heart,2)
   kick=1
  end
 end

 -- 6.1: the halo peaks in a ring of light.
 if not ctx:Wait(PEAK)then return end
 if fresh(PEAK)then
  scope:Ring(crown(),GOLD,.6,9,.9,{Thickness=.25,Segments=24})
  Kit.Cue('Chime',nil,.4)
  kick=1.4
 end

 -- 6.6: every eye closes; the light and the wheel go back up, the mouth cools.
 if not ctx:Wait(CLOSE)then return end
 dust.Rate=0
 Kit.Tween(grade,1.2,{Brightness=0,Contrast=0,Saturation=0,TintColor=WHITE},Enum.EasingStyle.Sine)
 if bloom then Kit.Tween(bloom,1.2,{Intensity=0})end
 if drone then Kit.Tween(drone,1.4,{Volume=0})end
 for _,r in ipairs(restore)do if r[1].Parent then ease(r[1],.9,r[2])end end
 if fresh(CLOSE)then
  Kit.Cue('Sting',nil,.3)
  for i,step in ipairs({2,3/2,1})do
   task.delay((i-1)*.12,function()bell(1.2*step,.16,nil,3)end)
  end
 end
 if not ctx:Wait(hold)then return end
 -- It walks away (on a pad: stays) under the last of the light.
 ctx:Wait(hold+.5)
end

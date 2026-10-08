-- THE DOG. The island goes quiet, the tongue's lights die, every dog turns to the mouth
-- of the giant head (whose own eyes roll down to look), something blinks in the dark,
-- the ground opens and it rises. While it walks the tongue (and the road to whoever
-- buys it) every dog on the island keeps staring at it.
local C=Color3.fromRGB
local Players=game:GetService('Players')
-- How far each part of a giant eye rolls with the gaze (the iris half as far).
local EYE={Pupil=1,EyeCatchlight=1,EyeSmallLight=1,WarmIris=.5}
-- Shared by overlapping THE DOGs: the eyes' true rest (first CFrame ever seen), and the
-- arrivals still watching (the newest one drives the eyes).
local homes,easing=setmetatable({},{__mode='k'}),setmetatable({},{__mode='k'})
local watchers={}
return function(ctx)
 ctx.ManualWhispers=true
 local Kit,W,scope,model,config=ctx.Kit,ctx.Whisper,ctx.Scope,ctx.Model,ctx.Config
 local low=ctx.Low
 local lines=config.Whispers
 local size=Kit.Size(model)
 local hold=config.Hold
 local origin=ctx.Origin
 local intro=ctx.Late<=1.5
 local onTongue=(ctx.Venue or 'Tongue')=='Tongue'
 local near=Kit.Near(origin,160)
 -- The rise (cinema bars, the hidden dog, candles, the hole) ends when it starts to walk.
 local act=Kit.Scope('Arrival_TheDog_Rise')
 scope:Add(function()act:Clean()end)
 local function where()
  if not model.Parent then return nil end
  return ctx:Ground()+Vector3.new(0,size.Y*.6,0)
 end
 local function say(i,options)
  options=options or {}
  options.Font=options.Font or Enum.Font.SpecialElite
  options.Color=options.Color or C(240,236,250)
  options.Type=options.Type or .06
  local said=ctx:Say(lines[i][2],options)
  -- The last line stays, breathing, while it walks.
  if i==#lines then W.Breathe(said,3)end
  return said
 end

 -- The whole island holds its breath.
 scope:Duck(.04,2)
 local drone=scope:Drone('Drone',low and .35 or .55,.42,3)
 local grade=scope:Grade({Saturation=-.9,Contrast=.24,Brightness=-.06,TintColor=C(232,236,250)},intro and 3 or .5)
 local stare=ctx.Stare.Begin(where,{Exclude=model,Turn=1.1,Ripple=140})
 scope:Add(function()stare:Stop(1.4)end)

 -- The giant head's pupils roll down to its own tongue and follow THE DOG. Every part of
 -- one eye rolls about the same centre (its pupil's, a stud inward).
 local eyes,centre={},{}
 local function adopt(part)
  local share=EYE[part.Name]
  if not share or not part:IsA('BasePart')then return end
  for _,e in ipairs(eyes)do if e.Part==part then return end end
  if easing[part]then easing[part]:Cancel();easing[part]=nil end
  local home=homes[part]or part.CFrame
  homes[part]=home
  local side=home.Position.X<0 and -1 or 1
  if part.Name=='Pupil'then centre[side]=home.Position-Vector3.new(side,0,0)end
  table.insert(eyes,{Part=part,Home=home,Share=share,Side=side})
 end
 table.insert(watchers,scope)
 -- They roll back as the stare lets go (unless another THE DOG still holds them).
 scope:Add(function()
  local i=table.find(watchers,scope)
  if i then table.remove(watchers,i)end
  if #watchers>0 then return end
  for _,e in ipairs(eyes)do
   if e.Part.Parent then easing[e.Part]=Kit.Tween(e.Part,1.4,{CFrame=e.Home},Enum.EasingStyle.Sine,Enum.EasingDirection.InOut)
   else e.Part.CFrame=e.Home end
  end
 end)
 local look=0
 scope:Every(function(dt)
  look=math.min(1,look+dt/2.5)
  local target=where()
  if not target or watchers[#watchers]~=scope then return true end
  local eased=look*look*(3-2*look)
  for _,e in ipairs(eyes)do
   if e.Part.Parent then
    local d=(target-(centre[e.Side]or e.Home.Position-Vector3.new(e.Side,0,0))).Unit
    local offset=Vector3.new(d.X,d.Y,0)*3.2
    if offset.Magnitude>3 then offset=offset.Unit*3 end
    e.Part.CFrame=e.Home+offset*e.Share*eased+Vector3.new(0,0,.05)
   end
  end
  return true
 end)

 -- The tongue's warm lights die from the mouth outward; each comes back once THE DOG has
 -- passed it (its own layer released, so an overlapping arrival's tint still shows).
 local seen,dark,reach={},{},-math.huge
 local function darken(g)
  if not scope.Alive or dark[g]or g.Position.Z<reach then return end
  local _,release=scope:Override(g,{Color=C(40,40,46),Material=Enum.Material.SmoothPlastic})
  dark[g]=release
 end
 -- The head, the tongue and the mouth stream in on their own (a late joiner's first
 -- seconds): whatever was missing is picked up on the next look.
 local function scan(first)
  local district=workspace:FindFirstChild('DOGROTS_District')
  local factory=district and district:FindFirstChild('02_DogFactory')
  local head=factory and factory:FindFirstChild('THE_DOG')
  -- (A Studio "here" preview stages it off the tongue: the tongue and mouth stay lit.)
  local mouth=onTongue and factory and factory:FindFirstChild('DarkMouthTunnel')or nil
  local line=onTongue and district and district:FindFirstChild('03_DogLine')or nil
  local tongue=line and line:FindFirstChild('Tongue')
  for _,o in ipairs(head and head:GetChildren()or {})do if EYE[o.Name]then adopt(o)end end
  for _,o in ipairs(mouth and mouth:GetDescendants()or {})do
   if not seen[o]then
    if o.Name=='MouthRune'and o:IsA('BasePart')then seen[o]=true;scope:Override(o,{Color=C(10,10,12)})
    -- WorldDetailQuality owns Enabled and Rate: the mist goes invisible instead.
    elseif o:IsA('ParticleEmitter')then seen[o]=true;scope:Override(o,{Transparency=NumberSequence.new(1)})end
   end
  end
  local fresh={}
  for _,g in ipairs(tongue and tongue:GetChildren()or {})do
   if not seen[g]and g.Name=='WarmEdgeGuide'and g:IsA('BasePart')then seen[g]=true;table.insert(fresh,g)end
  end
  table.sort(fresh,function(a,b)return a.Position.Z<b.Position.Z end)
  for i,g in ipairs(fresh)do
   if first and intro then task.delay((i-1)*.04,darken,g)else darken(g)end
  end
 end
 scan(true)
 task.spawn(function()
  while scope.Alive do
   task.wait(2)
   if scope.Alive then scan(false)end
  end
 end)

 if intro then
  act:Letterbox(.1,1.6)
  -- Hidden under the stage until the ground opens.
  local vis=act:Visibility(model);vis.Set(1)
  local lift=act:Offset(model)
  lift.CFrame=CFrame.new(0,-size.Y*1.2,0)
  -- A heartbeat that quickens until it arrives.
  task.spawn(function()
   local beat=1.7
   while scope.Alive and ctx:Elapsed()<hold-4.5 do
    Kit.Cue('Heartbeat',nil,.8);task.wait(beat);beat=math.max(.55,beat*.86)
   end
  end)
  if not ctx:Wait(lines[1][1])then return end
  say(1)
  if not ctx:Wait(lines[2][1])then return end
  say(2)
  -- A ring of cold white lights around the stage, lit one at a time.
  local candles={}
  for i=1,12 do
   local angle=i/12*math.pi*2
   local p=act:Part({Name='Candle',Size=Vector3.new(.35,1.2,.35),Position=origin+Vector3.new(math.cos(angle)*8.5,.6,math.sin(angle)*8.5),
    Color=C(255,255,255),Transparency=1})
   candles[i]=p
   task.delay(i*.24,function()
    if not scope.Alive or not p.Parent then return end
    Kit.Tween(p,.25,{Transparency=.05})
    if not low and i%3==0 then act:Light(p,C(220,225,255),9,1.1)end
    if i%4==0 then Kit.Cue('Glitch',p,.08)end
   end)
  end
  -- Black motes drifting up out of the belt.
  local motes=act:Anchor(origin+Vector3.new(0,.5,0),'Motes')
  local smoke=act:Emitter(motes,{Texture=Kit.Textures.Smoke,Rate=low and 6 or 20,Color=ColorSequence.new(C(8,6,12)),
   LightEmission=0,Lifetime=NumberRange.new(2,3.5),Speed=NumberRange.new(1,3),SpreadAngle=Vector2.new(35,35),
   Size=NumberSequence.new({NumberSequenceKeypoint.new(0,1.2),NumberSequenceKeypoint.new(1,3.5)}),
   Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.3,.35),NumberSequenceKeypoint.new(1,1)})})
  if not ctx:Wait(4.2)then return end
  -- Something in the dark blinks, right where its eyes will be once it has risen.
  local face=Kit.Root(model)and model:GetPivot().LookVector or Vector3.zAxis
  face=Vector3.new(face.X,0,face.Z)
  face=face.Magnitude>.1 and face.Unit or Vector3.zAxis
  local across=face:Cross(Vector3.yAxis)
  local glints={}
  for side=-1,1,2 do
   glints[#glints+1]=act:Part({Name='Glint',Shape=Enum.PartType.Ball,Size=Vector3.one*.24,Color=C(255,255,255),Transparency=1,
    Position=origin+across*side*.32+face*size.Z*.3+Vector3.new(0,size.Y*.78,0)})
  end
  local function blink(on)for _,g in ipairs(glints)do g.Transparency=on and 0 or 1 end end
  blink(true)
  task.delay(.3,function()if scope.Alive then blink(false)end end)
  task.delay(.7,function()if scope.Alive then blink(true)end end)
  task.delay(1.4,function()if scope.Alive then blink(false)end end)
  if not ctx:Wait(lines[3][1])then return end
  say(3)
  if near>0 then Kit.FOVPunch(-3*near,.6,1.4)end
  if not ctx:Wait(6.4)then return end
  -- The ground opens (the dog's own Ground_Opens clip plays on the server clock).
  local hole=act:Part({Name='Hole',Shape=Enum.PartType.Cylinder,Material=Enum.Material.SmoothPlastic,Color=C(0,0,0),
   Size=Vector3.new(.2,.1,.1),CFrame=CFrame.new(origin+Vector3.new(0,.08,0))*CFrame.Angles(0,0,math.pi/2)})
  Kit.Tween(hole,1.2,{Size=Vector3.new(.2,size.X*1.6+2,size.X*1.6+2)})
  act:Pillar(origin,origin+Vector3.new(0,90,0),C(255,255,255),size.X*.9,4.2)
  -- The light pours up out of the hole (a light at the pillar's middle sits inside the head).
  local lamp=act:Light(act:Anchor(origin+Vector3.new(0,3,0),'HoleLight'),C(235,240,255),28,3)
  Kit.Tween(lamp,4.2,{Brightness=0},Enum.EasingStyle.Quad,Enum.EasingDirection.In)
  Kit.Cue('Impact',nil,1)
  if near>0 then Kit.Shake(.55*near,1.6)end
  smoke.Rate=0
  vis.Set(.85)
  local rise=os.clock()
  act:Every(function()
   local a=math.min((os.clock()-rise)/2.2,1)
   local e=1-(1-a)^3
   lift.CFrame=CFrame.new(0,-size.Y*1.2*(1-e),0)
   vis.Set(.85*(1-math.min(a*1.6,1)))
   return a<1
  end)
  if not ctx:Wait(lines[4][1])then return end
  local breath=say(4,{Type=.09})
  W.Breathe(breath,2.2)
  if near>0 then Kit.FOVPunch(-7*near,1.6,2.4)end
  if not ctx:Wait(9.2)then return end
  -- It has arrived.
  if near>0 then Kit.Flash(C(255,255,255),1-.75*near,1.1)end
  Kit.Cue('Sting',nil,.9)
  act:Ring(origin+Vector3.new(0,.3,0),C(255,255,255),2,60,1.6,{Thickness=.5})
  if not low then act:Ring(origin+Vector3.new(0,.3,0),C(200,210,255),1,38,2.2,{Thickness=.25,Alpha=.4})end
  scope:Highlight(model,C(255,255,255),C(255,255,255),.92,.15)
  scope:Drone('Choir',low and .2 or .32,.8,2.5)
  ctx:Title({Tier='? ? ?',Color=C(255,255,255),Hold=4.5,Font=Enum.Font.SpecialElite})
  for _,p in ipairs(candles)do if p.Parent then Kit.Tween(p,1.5,{Transparency=1})end end
  Kit.Tween(hole,2.5,{Size=Vector3.new(.2,.1,.1)})
  if not ctx:Wait(10.4)then return end
  -- Every dog on the island bows its head.
  stare:Bow(math.rad(28),1.8)
  if not ctx:Wait(lines[5][1])then return end
  say(5,{Glitch=.08})
  if not ctx:Wait(lines[#lines][1])then return end
  say(#lines,{Type=.12})
 else
  -- Late: no intro, straight to the stare, marked as everyone else saw it rise. The
  -- line of the moment at once, the rest on schedule.
  scope:Highlight(model,C(255,255,255),C(255,255,255),.92,.15)
  ctx:Title({Tier='? ? ?',Color=C(255,255,255),Hold=4.5,Font=Enum.Font.SpecialElite})
  local now,current=ctx:Elapsed(),1
  for i,l in ipairs(lines)do if l[1]<=now then current=i end end
  say(current,{Type=0})
  for i=current+1,#lines do
   if not ctx:Wait(lines[i][1])then return end
   say(i,i==#lines and {Type=.12}or nil)
  end
 end
 if not ctx:Wait(hold)then return end

 -- It walks. Everything keeps watching; the bars lift and the screen breathes back a little.
 act:Clean()
 Kit.Tween(grade,2.5,{Saturation=-.55,Contrast=.18,Brightness=-.03})
 if drone then Kit.Tween(drone,3,{Volume=low and .22 or .35})end
 -- The tongue lights up again behind it. Once it steps off (bought, or gone through the
 -- portal) the rest wakes up from there.
 local sweep
 scope:Every(function(dt)
  local at=model.Parent and ctx:Ground()
  if not at then return true end
  if model:GetAttribute('State')~='OnLine'then sweep=math.max(sweep or at.Z,at.Z)+dt*60 end
  reach=math.max(reach,at.Z,sweep or at.Z)
  for g,release in pairs(dark)do
   if g.Position.Z<reach then dark[g]=nil;release()end
  end
  return true
 end)
 local ownerSeen=model:GetAttribute('OwnerName')
 scope:Add(model:GetAttributeChangedSignal('OwnerName'):Connect(function()
  local owner=model:GetAttribute('OwnerName')
  if type(owner)=='string'and owner~=''and owner~=ownerSeen then
   ownerSeen=owner
   local mine=model:GetAttribute('OwnerUserId')==Players.LocalPlayer.UserId
   local chosen=ctx:Say(mine and 'it chose you.'or 'it chose '..string.lower(owner)..'.',
    {Font=Enum.Font.SpecialElite,Color=C(255,255,255),Type=.08,Chroma=true})
   W.Breathe(chosen,3)
   Kit.Cue('Sting',nil,.6)
  end
 end))
 -- Until it is gone (delivered or dissolved) or the stare times out.
 ctx:Wait(hold+(config.StareSeconds or 120))
end

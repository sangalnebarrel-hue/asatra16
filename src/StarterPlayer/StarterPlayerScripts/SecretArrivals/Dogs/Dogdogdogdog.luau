-- DOGDOGDOGDOG: "ROLL CALL". It comes apart where it lands (the tongue, or a Lucky pad in
-- open air): the big dog drops through the floor and eight pups scatter onto eight marks.
-- They are counted off up a scale, leashed and reeled back in, and snap together into one
-- dog. Or eight.
local SoundService=game:GetService('SoundService')
local C=Color3.fromRGB
local GOLD,DEEP,CREAM,WHITE=C(255,196,64),C(222,128,16),C(255,226,150),C(255,255,255)
local TICK='rbxasset://sounds/volume_slider.ogg'
local FLAT=CFrame.Angles(0,0,math.pi/2)
-- One note per pup: a major scale up to the octave.
local SCALE={1,9/8,5/4,4/3,3/2,5/3,15/8,2}
-- Typewriter speed: "dog " is four characters, so one pup is called per typed word.
local TYPE=.055

-- A big cartoon number; KeepFont before parenting or PlaceTypography swaps the face.
local function number(parent:Instance,text:string,thickness:number)
 local l=Instance.new('TextLabel');l.Name='Number';l:SetAttribute('KeepFont',true)
 l.BackgroundTransparency=1;l.AnchorPoint=Vector2.new(.5,.5);l.Position=UDim2.fromScale(.5,.5);l.Size=UDim2.fromScale(0,0)
 l.Font=Enum.Font.LuckiestGuy;l.Text=text;l.TextScaled=true;l.TextColor3=WHITE;l.TextStrokeTransparency=1
 local s=Instance.new('UIStroke');s.Color=DEEP;s.Thickness=thickness;s.LineJoinMode=Enum.LineJoinMode.Round;s.Parent=l
 l.Parent=parent
 return l,s
end
local function billboard(adornee:BasePart,size:UDim2,lift:number)
 local g=Instance.new('BillboardGui');g.Name='RollCall';g.Adornee=adornee;g.AlwaysOnTop=true;g.LightInfluence=0
 g.MaxDistance=300;g.Size=size;g.StudsOffsetWorldSpace=Vector3.new(0,lift,0)
 return g
end

return function(ctx)
 ctx.WhisperStyle={Font=Enum.Font.PermanentMarker,Color=CREAM,Type=TYPE,Glitch=.025}
 local Kit,scope,model,config=ctx.Kit,ctx.Scope,ctx.Model,ctx.Config
 local low,calm,origin,hold=ctx.Low,Kit.ReducedMotion(),ctx.Origin,config.Hold
 local size=Kit.Size(model)
 local lines=config.Whispers or {}
 local call=lines[1]and lines[1][1]or 1.6
 local tail=lines[#lines]
 local typed=tail and tail[1]+(utf8.len(tail[2])or #tail[2])*TYPE or hold
 local fresh=ctx.Late<.3
 -- Off the tongue (a yard pad): no mouth props around, and no flat belt underfoot.
 local open=(ctx.Venue or 'Tongue')~='Tongue'
 local function near()return Kit.Near(origin,120)end
 -- Was this beat on time? (late joiners get the state, not the fanfare)
 local function live(t)return ctx:Elapsed()-t<.35 end
 local function pip(speed,volume)
  if not scope.Alive then return end
  local s=Instance.new('Sound');s.SoundId=TICK;s.Volume=volume;s.PlaybackSpeed=speed
  local r=Instance.new('ReverbSoundEffect');r.DecayTime=1.2;r.WetLevel=-5;r.DryLevel=0;r.Parent=s
  s.Parent=SoundService;scope:Add(s);s:Play()
  task.delay(3,function()if s.Parent then s:Destroy()end end)
 end

 -- The mouth runes (only when it arrives in the mouth, not on a yard pad) and the screen
 -- warm up; the music steps back for the count.
 local district=workspace:FindFirstChild('DOGROTS_District')
 local factory=district and district:FindFirstChild('02_DogFactory')
 local tunnel=factory and factory:FindFirstChild('DarkMouthTunnel')
 if tunnel and not open then
  for _,rune in ipairs(tunnel:GetDescendants())do
   if rune.Name=='MouthRune'and rune:IsA('BasePart')then scope:Override(rune,{Color=GOLD})end
  end
 end
 local grade=scope:Grade({TintColor=C(255,243,222),Saturation=.12,Contrast=.08},fresh and .8 or .3)
 scope:Duck(.5,.8)

 -- Eight pups: an anchor that rides each pup's head bone, with its spark, light,
 -- leash end and number. Bones stream in late; until then the anchors wait on a ring.
 local pups:{any}={}
 for i=1,8 do
  local angle=(i-.5)/8*math.pi*2
  local a=scope:Anchor(origin+Vector3.new(math.cos(angle)*3.5,2,math.sin(angle)*3.5),'Pup'..i)
  local att=Instance.new('Attachment');att.Parent=a
  local spark=scope:Emitter(a,{Color=ColorSequence.new(GOLD),Lifetime=NumberRange.new(.4,.8),Speed=NumberRange.new(4,9),
   Size=NumberSequence.new(.45,0),Acceleration=Vector3.new(0,-14,0)})
  local gui=billboard(a,UDim2.new(1.6,26,1.6,26),1.4);gui.Enabled=false
  local label,stroke=number(gui,tostring(i),3)
  gui.Parent=a
  pups[i]={Anchor=a,Attachment=att,Spark=spark,Light=not low and scope:Light(a,GOLD,10,0)or nil,Gui=gui,Label=label,
   Stroke=stroke,Bone=nil,Name=string.format('pup_%02d_head',i),Mark=nil}
 end
 local top=scope:Anchor(origin+Vector3.new(0,size.Y,0),'Top')
 local glints=scope:Emitter(top,{Color=ColorSequence.new(CREAM),Lifetime=NumberRange.new(.6,1.1),Speed=NumberRange.new(2,5),
  Size=NumberSequence.new(.35,0),Acceleration=Vector3.new(0,-6,0)})
 local lookup=0
 scope:Every(function()
  local now=os.clock()
  local search=now>=lookup
  if search then lookup=now+.5 end
  for _,p in ipairs(pups)do
   if search and not(p.Bone and p.Bone.Parent)then
    local found=model:FindFirstChild(p.Name,true)
    p.Bone=found and found:IsA('Bone')and found or nil
   end
   if p.Bone and p.Bone.Parent then
    local at=(p.Bone::Bone).TransformedWorldCFrame.Position
    p.Anchor.CFrame=CFrame.new(at)
    if p.Mark and p.Mark.Parent then p.Mark.CFrame=CFrame.new(at.X,origin.Y+.06,at.Z)*FLAT end
   end
  end
  if model.Parent then top.CFrame=CFrame.new(ctx:Ground()+Vector3.new(0,size.Y,0))end
 end)

 -- 0-0.4: nothing there yet. Eight pops go off around the spot, one after another.
 local vis=scope:Visibility(model)
 if fresh then
  vis.Set(1)
  for i=1,8 do
   if not ctx:Wait((i-1)*.04)then return end
   local angle=(i-.5)/8*math.pi*2
   scope:Burst(origin+Vector3.new(math.cos(angle)*4.5,.3,math.sin(angle)*4.5),GOLD,16,{SpreadAngle=Vector2.new(25,25),
    Speed=NumberRange.new(8,15),Acceleration=Vector3.new(0,-34,0),Lifetime=NumberRange.new(.5,.9),Size=NumberSequence.new(.5,0)})
   pip(2+i*.12,.2)
  end
 end
 -- 0.4: there it is, already coming apart (the Split clip).
 if not ctx:Wait(.4)then return end
 if fresh then
  scope:Every(function(_,age)local a=math.min(age/.18,1);vis.Set(1-a);return a<1 end)
  scope:Ring(origin+Vector3.new(0,.15,0),GOLD,1,8,.5,{Thickness=.3})
  Kit.Cue('Whoosh',nil,.45)
 end
 -- 0.56: the big dog drops straight through the belt (or the pad).
 if not ctx:Wait(.56)then return end
 if live(.56)then
  scope:Ring(origin+Vector3.new(0,.12,0),CREAM,1.5,9,.6,{Thickness=.22,Alpha=.3})
  scope:Burst(origin+Vector3.new(0,.4,0),C(255,222,150),22,{Texture=Kit.Textures.Smoke,LightEmission=.3,Drag=3,
   Speed=NumberRange.new(3,7),SpreadAngle=Vector2.new(80,80),Lifetime=NumberRange.new(.6,1.1),
   Size=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,2.6)}),
   Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.4),NumberSequenceKeypoint.new(1,1)})})
  Kit.Cue('Impact',nil,.45)
  local n=near();if n>.05 then Kit.Shake(.2*n,.35)end
 end
 -- 1.2: the pups land, each on its own mark.
 if not ctx:Wait(1.2)then return end
 for _,p in ipairs(pups)do
  local at=p.Anchor.Position
  local mark=scope:Part({Name='Mark',Shape=Enum.PartType.Cylinder,Color=GOLD,Transparency=.45,Size=Vector3.new(.05,.1,.1),
   CFrame=CFrame.new(at.X,origin.Y+.06,at.Z)*FLAT})
  Kit.Tween(mark,.35,{Size=Vector3.new(.05,1.9,1.9)},Enum.EasingStyle.Back)
  p.Mark=mark
 end
 -- Roll call, in step with the typed "dog dog dog...": one number per pup, up the scale.
 for i,p in ipairs(pups)do
  local at=call+(4*i-1)*TYPE
  if not ctx:Wait(at)then return end
  p.Gui.Enabled=true
  if live(at)then
   p.Label.Rotation=calm and 0 or (i%2==0 and 14 or -14)
   p.Label.Size=UDim2.fromScale(.15,.15)
   Kit.Tween(p.Label,.3,{Size=UDim2.fromScale(1,1),Rotation=0},Enum.EasingStyle.Back)
   pip(1.25*SCALE[i],.45)
   p.Spark:Emit(low and 4 or 12)
   if p.Light then p.Light.Brightness=4;Kit.Tween(p.Light,.5,{Brightness=0})end
   p.Mark.Transparency=0;Kit.Tween(p.Mark,.45,{Transparency=.35})
  else p.Label.Size=UDim2.fromScale(1,1)end
 end
 -- 3.5: Reassemble. Eight leashes snap taut and reel the pups back in.
 if not ctx:Wait(3.5)then return end
 local hub=scope:Part({Name='Hub',Shape=Enum.PartType.Ball,Color=CREAM,Size=Vector3.one*.2,Position=ctx:Ground()+Vector3.new(0,size.Y*.5,0)})
 Kit.Tween(hub,.25,{Size=Vector3.one*.9},Enum.EasingStyle.Back)
 local knotLight=not low and scope:Light(hub,GOLD,14,2.5)or nil
 local knot=Instance.new('Attachment');knot.Parent=hub
 local leashes={}
 if not low then
  for i,p in ipairs(pups)do
   leashes[i]=scope:Beam(p.Attachment,knot,GOLD,.14,{Width1=.22,Segments=14,Transparency=NumberSequence.new(1)})
  end
  -- A twang: the slack whips out of each line, alternating sides.
  scope:Every(function(_,age)
   local slack=math.cos(age*28)*math.exp(-age*5)*2.4
   local alpha=NumberSequence.new(math.max(.05,1-age*8))
   for i,b in ipairs(leashes)do
    b.CurveSize0=slack*(i%2==0 and 1 or -1);b.CurveSize1=-b.CurveSize0*.5;b.Transparency=alpha
   end
   return age<1.2
  end)
 end
 Kit.Cue('Whoosh',nil,.55)
 for _,p in ipairs(pups)do
  local mark=p.Mark
  local t=Kit.Tween(mark,.4,{Size=Vector3.new(.05,.1,.1),Transparency=1},Enum.EasingStyle.Back,Enum.EasingDirection.In)
  t.Completed:Connect(function()mark:Destroy()end)
 end
 -- 3.9: the body climbs back up through the floor; a ring closes in, the pitch winds up.
 if not ctx:Wait(3.9)then return end
 if live(3.9)then
  scope:Ring(origin+Vector3.new(0,.2,0),GOLD,8,1.5,.75,{Thickness=.3,Alpha=.25})
  for k=0,5 do task.delay(k*.11,pip,1.4+k*.32,.18+k*.04)end
 end
 if not ctx:Wait(4.3)then return end
 for _,p in ipairs(pups)do
  Kit.Tween(p.Label,.35,{TextTransparency=.35,Size=UDim2.fromScale(.75,.75)});Kit.Tween(p.Stroke,.35,{Transparency=.35})
 end
 -- 4.7: one dog. The eight numbers fold into a single "1".
 if not ctx:Wait(4.7)then return end
 for _,b in ipairs(leashes)do b:Destroy()end
 Kit.Tween(hub,.15,{Size=Vector3.one*.1,Transparency=1})
 if knotLight then Kit.Tween(knotLight,.4,{Brightness=0})end
 for _,p in ipairs(pups)do p.Gui.Enabled=false end
 local oneGui=billboard(top,UDim2.new(2.6,40,2.6,40),1.4)
 local one,oneStroke=number(oneGui,'1',4)
 oneGui.Parent=top
 Kit.Tween(one,.4,{Size=UDim2.fromScale(1,1)},Enum.EasingStyle.Back)
 ctx:Title({Font=Enum.Font.LuckiestGuy,Hold=3.6})
 if live(4.7)then
  Kit.Cue('Chime',nil,.6);Kit.Cue('Impact',nil,.35)
  local n=near()
  if n>.05 then
   Kit.Flash(C(255,232,160),1-.32*n,.5);Kit.Shake(.4*n,.5);Kit.FOVPunch(-5*n,.1,.8)
   grade.Brightness=.12*n;Kit.Tween(grade,.7,{Brightness=0})
  end
  scope:Ring(origin+Vector3.new(0,.2,0),GOLD,1,15,.9,{Thickness=.45})
  if not low then scope:Ring(origin+Vector3.new(0,.25,0),WHITE,1,9,.7,{Thickness=.2,Alpha=.35,Segments=24})end
  -- Gone once faded: an invisible Highlight still takes one of the client's few Highlight slots.
  local glow=scope:Highlight(model,C(255,214,110),C(255,244,200),.5,0)
  Kit.Tween(glow,.9,{FillTransparency=1,OutlineTransparency=1}).Completed:Connect(function()glow:Destroy()end)
  -- Confetti off the top of the dog: gold, cream and white flakes that flutter down.
  local from=ctx:Ground()+Vector3.new(0,size.Y*.85,0)
  if low then
   scope:Burst(from,GOLD,24,{Speed=NumberRange.new(10,18),Acceleration=Vector3.new(0,-20,0),Lifetime=NumberRange.new(1,1.6)})
   scope:Burst(from,WHITE,16,{Speed=NumberRange.new(10,18),Acceleration=Vector3.new(0,-20,0),Lifetime=NumberRange.new(1,1.6)})
  else
   local bits={}
   for i=1,40 do
    local angle,speed=Kit.Random(0,math.pi*2),Kit.Random(6,14)
    bits[i]={Part=scope:Part({Name='Confetti',Color=i%5<2 and WHITE or (i%2==0 and GOLD or CREAM),Size=Vector3.new(.34,.04,.2),
     Transparency=.05,CFrame=CFrame.new(from)}),Pos=from,Vel=Vector3.new(math.cos(angle)*speed,Kit.Random(16,27),math.sin(angle)*speed),
     Spin=Vector3.new(Kit.Random(-9,9),Kit.Random(-9,9),Kit.Random(-9,9)),Phase=Kit.Random(0,6)}
   end
   local floor=origin.Y+.06
   -- Open air: the pad is a raised slab, not the flat belt. Each flake finds the real
   -- ground under it once, just before it would reach the pad's level.
   local probe
   if open then
    probe=RaycastParams.new();probe.FilterType=Enum.RaycastFilterType.Exclude;probe.RespectCanCollide=true
    local me=game:GetService('Players').LocalPlayer.Character
    probe.FilterDescendantsInstances=me and {model,me}or {model}
   end
   scope:Every(function(dt,age)
    dt=math.min(dt,.05)
    local fade=math.clamp((age-1.7)/.7,0,1)
    for _,b in ipairs(bits)do
     local v=b.Vel
     v=Vector3.new(v.X*(1-1.8*dt),math.max(v.Y-44*dt,-7),v.Z*(1-1.8*dt));b.Vel=v
     local sway=v.Y<0 and math.sin(age*6+b.Phase)*2.2 or 0
     local pos=b.Pos+(v+Vector3.new(sway,0,sway*.6))*dt
     if probe and not b.Floor and v.Y<0 and pos.Y<floor+1.5 then
      local hit=workspace:Raycast(pos+Vector3.new(0,.5,0),Vector3.new(0,-8,0),probe)
      b.Floor=hit and hit.Position.Y+.06 or floor-8
     end
     local ground=b.Floor or floor
     if pos.Y<ground then pos=Vector3.new(pos.X,ground,pos.Z);b.Vel=Vector3.zero end
     b.Pos=pos
     b.Part.CFrame=CFrame.new(pos)*CFrame.fromEulerAnglesXYZ(age*b.Spin.X+b.Phase,age*b.Spin.Y,age*b.Spin.Z)
     b.Part.Transparency=.05+.95*fade
    end
    if age>=2.4 then for _,b in ipairs(bits)do b.Part:Destroy()end;return false end
    return true
   end)
  end
 end
 -- 5.6: Happy. A little fountain of glints over its head.
 if not ctx:Wait(5.6)then return end
 if live(5.6)then glints:Emit(low and 4 or 14)end
 -- The "1" floats off before the name tag comes back on.
 if not ctx:Wait(hold-.3)then return end
 Kit.Tween(oneGui,.4,{StudsOffsetWorldSpace=Vector3.new(0,3.2,0)},Enum.EasingStyle.Quad,Enum.EasingDirection.In)
 Kit.Tween(one,.4,{TextTransparency=1});Kit.Tween(oneStroke,.4,{Transparency=1})
 Kit.Tween(grade,1.2,{TintColor=WHITE,Saturation=0,Contrast=0,Brightness=0})
 if not ctx:Wait(hold)then return end
 -- "...now there are eight." It walks off (or stays on its pad); for a blink, all eight
 -- are still in there.
 if not ctx:Wait(typed-.25)then return end
 if live(typed-.25)then
  for _,p in ipairs(pups)do
   p.Gui.StudsOffsetWorldSpace=Vector3.zero;p.Label.Size=UDim2.fromScale(.8,.8);p.Label.TextTransparency=.1;p.Stroke.Transparency=.1
  end
  -- Reduced motion: one steady blink instead of the flicker.
  for k,at in ipairs(calm and {0,.37} or {0,.08,.15,.37})do
   if not ctx:Wait(typed-.25+at)then return end
   for _,p in ipairs(pups)do p.Gui.Enabled=k%2==1 end
   if k==1 then Kit.Cue('Glitch',nil,.22)end
  end
 end
 -- Let the last line be read, then everything fades with the scope.
 ctx:Wait(math.max(hold,typed)+1)
end

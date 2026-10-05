-- 404 DOG NOT FOUND, "page missing". It drops straight through the tongue and leaves an
-- empty outline where it should be. A browser window flickers on above the stage (404,
-- DOG NOT FOUND), its search bar sticks at 99% while data cubes rise out of the belt and
-- spiral in. At 4 s the page answers 200 OK, the cubes slam into the outline, a scanline
-- renders the dog back in and the page shatters. Then, for a blink, it stands behind you.
-- Off the tongue (a Lucky pad, a dig, the machine) there are no mouth props: a ring of
-- loading pixels hovers round the stage and stutters, spins and turns green in their place.
local Players=game:GetService('Players')
local C=Color3.fromRGB
local WHITE,GREEN,AMBER,RED,CYAN=C(232,244,255),C(60,255,120),C(255,190,60),C(255,60,96),C(60,236,255)
local PAGE,BAR,DIM=C(13,17,29),C(29,34,48),C(16,26,52)
local TICK='rbxasset://sounds/volume_slider.ogg'
local FOUND=4 -- Reassemble starts: the page answers 200 OK
local W,H=600,350 -- the page in pixels: 12×7 studs at 50 px/stud
local CUTS={0,40,84,130,184,250,350} -- glitch slices (one cuts the 404 in half)
-- The search bar sticks at 99%.
local STEPS={{At=1.5,Pct=0,Status='searching for dog...'},{At=1.85,Pct=12},{At=2.3,Pct=37},{At=2.75,Pct=99},
 {At=3.15,Pct=99,Status='still searching...'},{At=3.55,Pct=99,Status='retrying...'}}
local function smooth(x)x=math.clamp(x,0,1);return x*x*(3-2*x)end
local function out3(x)x=math.clamp(x,0,1);return 1-(1-x)^3 end
local function frame(parent,props,radius)
 local f=Instance.new('Frame');f.BorderSizePixel=0
 for k,v in pairs(props)do (f::any)[k]=v end
 if radius then local c=Instance.new('UICorner');c.CornerRadius=UDim.new(0,radius);c.Parent=f end
 f.Parent=parent
 return f
end
-- KeepFont before parenting, or PlaceTypography turns it into FredokaOne.
local function text(parent,props)
 local l=Instance.new('TextLabel');l:SetAttribute('KeepFont',true)
 l.BackgroundTransparency=1;l.TextScaled=false;l.RichText=false;l.TextStrokeTransparency=1
 for k,v in pairs(props)do (l::any)[k]=v end
 l.Parent=parent
 return l
end
-- One copy of the page. Each glitch slice holds its own copy, shifted to its band.
local function page(parent,url,where,blue)
 local p=frame(parent,{Name='Page',Size=UDim2.fromOffset(W,H),BackgroundColor3=PAGE})
 local bar=frame(p,{Name='TitleBar',Size=UDim2.fromOffset(W,40),BackgroundColor3=BAR})
 for i,c in ipairs({C(255,95,87),C(255,189,46),C(40,200,64)})do
  frame(bar,{Size=UDim2.fromOffset(13,13),Position=UDim2.fromOffset(i*20-6,14),BackgroundColor3=c},7)
 end
 local tab=frame(bar,{Name='Tab',Size=UDim2.fromOffset(210,40),Position=UDim2.fromOffset(78,8),BackgroundColor3=PAGE},8)
 local title=text(tab,{Size=UDim2.new(1,-28,0,30),Position=UDim2.fromOffset(14,0),Font=Enum.Font.SourceSansBold,TextSize=17,
  TextColor3=C(196,206,228),TextXAlignment=Enum.TextXAlignment.Left,Text='404 Not Found'})
 local pill=frame(p,{Name='Url',Size=UDim2.fromOffset(W-28,30),Position=UDim2.fromOffset(14,50),BackgroundColor3=C(24,29,43)},15)
 text(pill,{Size=UDim2.new(1,-32,1,0),Position=UDim2.fromOffset(16,0),Font=Enum.Font.RobotoMono,TextSize=16,
  TextColor3=C(150,166,200),TextXAlignment=Enum.TextXAlignment.Left,Text=url})
 local function code(x,color,alpha,z)
  return text(p,{Size=UDim2.fromOffset(W,118),Position=UDim2.fromOffset(x,88),Font=Enum.Font.Arcade,TextSize=108,
   TextColor3=color,TextTransparency=alpha,ZIndex=z,Text='404'})
 end
 local r={Page=p,Tab=title,Red=code(-5,RED,.45,1),Cyan=code(5,CYAN,.45,1),Code=code(0,blue,0,2)}
 r.Sub=text(p,{Size=UDim2.fromOffset(W,34),Position=UDim2.fromOffset(0,206),Font=Enum.Font.Arcade,TextSize=30,
  TextColor3=WHITE,Text='DOG NOT FOUND'})
 r.Note=text(p,{Size=UDim2.fromOffset(W,22),Position=UDim2.fromOffset(0,244),Font=Enum.Font.RobotoMono,TextSize=15,
  TextColor3=C(118,134,170),Text='the requested dog was not found '..where..'.'})
 r.Row=frame(p,{Name='Search',Size=UDim2.fromOffset(W,60),Position=UDim2.fromOffset(0,280),BackgroundTransparency=1,Visible=false})
 r.Status=text(r.Row,{Size=UDim2.fromOffset(330,22),Position=UDim2.fromOffset(64,0),Font=Enum.Font.RobotoMono,TextSize=15,
  TextColor3=C(176,194,228),TextXAlignment=Enum.TextXAlignment.Left,Text=''})
 r.Pct=text(r.Row,{Size=UDim2.fromOffset(120,22),Position=UDim2.fromOffset(W-184,0),Font=Enum.Font.RobotoMono,TextSize=15,
  TextColor3=WHITE,TextXAlignment=Enum.TextXAlignment.Right,Text='0%'})
 local track=frame(r.Row,{Size=UDim2.fromOffset(W-128,10),Position=UDim2.fromOffset(64,30),BackgroundColor3=C(32,39,58)},5)
 r.Fill=frame(track,{Size=UDim2.fromScale(0,1),BackgroundColor3=blue},5)
 return r
end

return function(ctx)
 ctx.WhisperStyle={Font=Enum.Font.Code,Color=C(176,212,255),Glitch=.12,Chroma=true,Shake=false,Type=.035}
 local Kit,scope,model,config=ctx.Kit,ctx.Scope,ctx.Model,ctx.Config
 local low,calm,origin,hold=ctx.Low,Kit.ReducedMotion(),ctx.Origin,config.Hold
 local BLUE=config.Color
 local size=Kit.Size(model)
 local up=Vector3.yAxis
 local venue=ctx.Venue or 'Tongue'
 -- Dogs face their pivot's look vector: +Z on the tongue, wherever the stand points elsewhere
 -- (in the open, until its root streams in, toward this player's camera).
 local function facing()
  local look:Vector3?=Kit.Root(model)and model:GetPivot().LookVector or nil
  local camera=workspace.CurrentCamera
  if not look and venue~='Tongue'and camera then look=camera.CFrame.Position-origin end
  local flat=look and Vector3.new(look.X,0,look.Z)or Vector3.zero
  return flat.Magnitude>.1 and flat.Unit or Vector3.zAxis
 end
 local fwd=facing()
 local stage=CFrame.lookAt(origin,origin+fwd)
 local core=origin+up*size.Y*.45
 local function near()return Kit.Near(origin,120)end
 -- One-shots fire on time only; a late joiner gets the state, not the fanfare.
 local function live(t)return ctx:Elapsed()-t<.35 end
 -- A short synth blip (3D when parented to a part); buzz = the error beep.
 local function beep(pitch,volume,parent:Instance?,buzz)
  if not scope.Alive then return end
  local s=Instance.new('Sound');s.SoundId=TICK;s.Volume=volume;s.PlaybackSpeed=pitch
  s.RollOffMinDistance=12;s.RollOffMaxDistance=240
  if buzz then local d=Instance.new('DistortionSoundEffect');d.Level=.7;d.Parent=s end
  s.Parent=(parent and parent.Parent)and parent or scope.Folder
  s:Play()
  task.delay(2,function()if s.Parent then s:Destroy()end end)
 end

 -- The mouth's runes and lanterns go to link blue and stutter; the edge guides wait for 200 OK.
 local tinted,runes,guides={},{},{}
 local function tint(o,props)
  local saved={}
  for k in pairs(props)do saved[k]=(o::any)[k]end
  scope:Override(o,props);table.insert(tinted,{o,saved})
 end
 if venue=='Tongue'then
  local district=workspace:FindFirstChild('DOGROTS_District')
  local factory=district and district:FindFirstChild('02_DogFactory')
  local tunnel=factory and factory:FindFirstChild('DarkMouthTunnel')
  local line=district and district:FindFirstChild('03_DogLine')
  for _,o in ipairs(tunnel and tunnel:GetDescendants()or {})do
   if o.Name=='MouthRune'and o:IsA('BasePart')then tint(o,{Color=BLUE});table.insert(runes,o)
   elseif o:IsA('ParticleEmitter')then scope:Override(o,{Color=ColorSequence.new(C(70,120,200))})end
  end
  for _,o in ipairs(line and line:GetChildren()or {})do
   local lens=o.Name=='PromenadeLantern'and o:FindFirstChild('WarmLens')
   if lens and lens:IsA('BasePart')and (lens.Position-origin).Magnitude<24 then
    tint(lens,{Color=BLUE})
    for _,l in ipairs(o:GetDescendants())do if l:IsA('PointLight')then tint(l,{Color=BLUE})end end
   end
  end
  local strip=line and line:FindFirstChild('Tongue')
  for _,g in ipairs(strip and strip:GetChildren()or {})do
   if g.Name=='WarmEdgeGuide'and g:IsA('BasePart')and (g.Position-origin):Dot(fwd)>-2 then table.insert(guides,g)end
  end
 end
 local found=false
 if #runes>0 and not calm then
  local nextFlicker=0
  scope:Every(function()
   if found then return false end
   local e,now=ctx:Elapsed(),os.clock()
   if now<nextFlicker then return true end
   nextFlicker=now+(e>3.5 and .05 or .14)
   local odds=e>3.5 and .5 or .18
   for _,r in ipairs(runes)do if r.Parent then r.Color=Kit.Random(0,1)<odds and DIM or BLUE end end
   return true
  end)
 end
 -- In the open nothing frames the stage: a loading ring of pixels hovers round it instead.
 -- It stutters like the runes, spins while the search runs, sticks with the bar at 99%
 -- and panics before the answer.
 local dots:{any},dotLights:{any}={},{}
 if venue~='Tongue'then
  local side,n=fwd:Cross(up),low and 4 or 8
  for i=1,n do
   -- Half a step off its facing: no pixel hangs in front of whoever opened it.
   local a=(i-.5)/n*math.pi*2
   local at=origin+(fwd*math.cos(a)+side*math.sin(a))*7.5+up*1.2
   dots[i]=scope:Part({Name='LoadingPixel',Size=Vector3.one*.6,Color=BLUE,CFrame=CFrame.lookAt(at,at+fwd)})
   if not low and i%4==1 then table.insert(dotLights,scope:Light(dots[i],BLUE,12,.9))end
  end
 end
 if #dots>0 and not calm then
  local nextTick,spin,blink=0,0,true
  scope:Every(function()
   if found then return false end
   local e,now=ctx:Elapsed(),os.clock()
   if now<nextTick then return true end
   if e>1.5 and e<3.5 then
    nextTick=now+1/#dots
    if e<2.75 then spin+=1;blink=true else blink=not blink end
    for i,d in ipairs(dots)do
     local lag=(spin-i)%#dots
     d.Color=lag==0 and (blink and WHITE or DIM)or (lag<3 and BLUE or DIM)
    end
   else
    nextTick=now+(e>3.5 and .05 or .14)
    local odds=e>3.5 and .5 or .18
    for _,d in ipairs(dots)do d.Color=Kit.Random(0,1)<odds and DIM or BLUE end
   end
   return true
  end)
 end
 local grade=scope:Grade({Saturation=-.2,Contrast=.12,Brightness=-.02,TintColor=C(222,234,255)},live(0)and .5 or .2)
 scope:Duck(.4,.6)

 -- Where the dog should be: an empty outline that blinks like a missing asset.
 local slot=scope:Part({Name='MissingDog',Size=Vector3.new(size.X,.05,size.Z),Transparency=1,CFrame=stage+up*.06})
 local outline=Instance.new('SelectionBox');outline.Name='Outline';outline.Adornee=slot;outline.Color3=BLUE
 outline.LineThickness=.08;outline.SurfaceColor3=BLUE;outline.SurfaceTransparency=.9;outline.Parent=slot
 scope:Every(function()
  if found or not outline.Parent then return false end
  local e=ctx:Elapsed()
  outline.Transparency=(calm or (e*(e<3.5 and 1.6 or 7))%1<.62)and 0 or .75
  return true
 end)

 -- 0-0.5: Depth_Error drops it through the belt (the server plays the clip).
 if live(0)then
  Kit.Cue('Glitch',slot,.4);Kit.Cue('Whoosh',nil,.3)
  scope:Burst(origin+up*.3,BLUE,26,{SpreadAngle=Vector2.new(50,50),Speed=NumberRange.new(6,13),Acceleration=Vector3.new(0,-22,0),
   Lifetime=NumberRange.new(.4,.8),Size=NumberSequence.new(.45,0)})
  scope:Ring(origin+up*.15,BLUE,size.X*.4,7,.5,{Thickness=.22,Alpha=.25})
  local fall=scope:Highlight(model,BLUE,WHITE,.35,0)
  scope:Every(function(_,age)
   if not fall.Parent then return false end
   fall.Enabled=calm or age<.06 or (age>.1 and age<.22) or age>.28
   fall.FillTransparency=.35+.65*smooth(age/.5)
   if age<.55 then return true end
   fall:Destroy();return false
  end)
 end
 -- 0.33: the authored error sign pops up. Bup-bup.
 if not ctx:Wait(.33)then return end
 if live(.33)then
  beep(.9,.35,slot,true);task.delay(.13,beep,.9,.3,slot,true)
  local n=near();if n>.05 then Kit.Flash(RED,1-.15*n,.18)end
 end

 -- 0.5: the outline extrudes to the dog's size; the browser window powers on above it.
 if not ctx:Wait(.5)then return end
 -- Off the tongue its root may have streamed in since: line up with the way it really faces.
 if venue~='Tongue'and Kit.Root(model)then fwd=facing();stage=CFrame.lookAt(origin,origin+fwd)end
 Kit.Tween(slot,live(.5)and .4 or 0,{Size=size,CFrame=stage+up*size.Y/2},Enum.EasingStyle.Back)
 -- It hangs over the stage facing out, tilted down; on each screen it turns (up to 55°)
 -- toward that player's camera, so it reads from the yards as well as down the tongue.
 local hang,side=origin+up*10+fwd*3,fwd:Cross(up)
 local function aim()
  local camera=workspace.CurrentCamera
  if not camera then return 0 end
  local d=camera.CFrame.Position-hang
  if Vector3.new(d.X,0,d.Z).Magnitude<1 then return 0 end
  return math.clamp(math.atan2(d:Dot(side),d:Dot(fwd)),-math.rad(55),math.rad(55))
 end
 local turn=aim()
 local function hanging(bob)
  local n,at=fwd*math.cos(turn)+side*math.sin(turn),hang+up*bob
  return CFrame.lookAt(at,at-n)*CFrame.Angles(math.rad(10),0,0)
 end
 local panel=scope:Part({Name='NotFound',Size=Vector3.new(12,7,.2),Color=PAGE,Material=Enum.Material.SmoothPlastic,Transparency=1,CFrame=hanging(0)})
 local gui=Instance.new('SurfaceGui');gui.Name='Browser';gui.Face=Enum.NormalId.Back;gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud
 gui.PixelsPerStud=50;gui.LightInfluence=0;gui.Brightness=1.4;gui.MaxDistance=360;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
 gui.ClipsDescendants=true;gui.Enabled=false
 local where=({Tongue='on this tongue',Yard='in this yard',Excavation='at this dig site',Machine='in this machine'})[venue]or 'on this server'
 -- Off the tongue the address names whoever found it.
 local by=ctx.By and string.gsub(string.lower(ctx.By),'[^%w_]','')or ''
 local url='dogrots://'..string.lower(venue)..(by~=''and '/'..by or '')..'/dog?id=95'
 local pages,slices={},{}
 local cuts=low and {0,H}or CUTS
 for i=1,#cuts-1 do
  local band=frame(gui,{Name='Slice',Size=UDim2.fromOffset(W,cuts[i+1]-cuts[i]),Position=UDim2.fromOffset(0,cuts[i]),
   BackgroundTransparency=1,ClipsDescendants=true})
  local r=page(band,url,where,BLUE)
  r.Page.Position=UDim2.fromOffset(0,-cuts[i])
  table.insert(pages,r);table.insert(slices,{Frame=band,Top=cuts[i]})
 end
 local roll=frame(gui,{Name='Refresh',Size=UDim2.fromOffset(W,28),BackgroundColor3=WHITE,BackgroundTransparency=.94,ZIndex=5})
 gui.Parent=panel
 local function each(fn)for _,r in ipairs(pages)do fn(r)end end
 local screenLight=not low and scope:Light(panel,BLUE,18,0)or nil
 local function power()
  panel.Transparency=0;gui.Enabled=true
  if screenLight then Kit.Tween(screenLight,.3,{Brightness=1.6})end
 end
 if live(.5)then
  -- CRT power-on: a line snaps across, opens to the full window and fades.
  Kit.Cue('Whoosh',panel,.35);beep(2.4,.18,panel)
  local crt=scope:Part({Name='PowerOn',Color=C(205,232,255),Size=Vector3.new(.1,.08,.05),CFrame=hanging(0)*CFrame.new(0,0,.14)})
  scope:Life(crt,.42,function(a)
   local t=a*.42
   crt.Size=Vector3.new(math.max(12*out3(t/.1),.1),.08+6.92*out3((t-.12)/.16),.05)
   crt.Transparency=math.clamp((t-.14)/.28,0,1)
   if t>=.2 and not gui.Enabled then power()end
  end)
 else power()end
 -- The page hovers and glitches: random slices jump sideways, a refresh bar rolls down.
 local shattered,nextCut=false,0
 scope:Every(function(dt)
  if shattered then return false end
  local e,now=ctx:Elapsed(),os.clock()
  turn+=(aim()-turn)*math.min(dt*3,1)
  panel.CFrame=hanging(math.sin(e*1.7)*.06)
  roll.Position=UDim2.fromOffset(0,(e*170)%(H+60)-30)
  if now<nextCut then return true end
  local wild=e>3.5 and e<FOUND
  nextCut=now+(wild and .06 or .12)
  local chance,amp=.3,20
  if e>=FOUND then chance=0 elseif wild then chance,amp=.75,34 elseif e>1.5 then chance,amp=.15,10 end
  if calm then chance,amp=chance*.5,amp*.25 end
  for _,s in ipairs(slices)do
   s.Frame.Position=UDim2.fromOffset(Kit.Random(0,1)<chance and math.round(Kit.Random(-amp,amp))or 0,s.Top)
  end
  return true
 end)

 -- 1.5-3.9: the search. Data cubes rise out of the belt and spiral in on the outline.
 if not ctx:Wait(1.5)then return end
 local drone=scope:Drone('Drone',low and .2 or .3,.8,1.2)
 local heart=scope:Anchor(core,'DataCore')
 local glow=not low and scope:Light(heart,BLUE,22,0)or nil
 local cubes={}
 local count=low and 12 or 30
 for i=1,count do
  cubes[i]={Part=scope:Part({Name='Data',Size=Vector3.one*.05,Color=i%3==0 and WHITE or BLUE,Transparency=1,CFrame=CFrame.new(origin)}),
   Size=Kit.Random(.4,.8),T0=1.5+(i-1)/count*1.3,Phase=i*2.4,H=Kit.Random(.6,math.max(size.Y*.95,1.5)),
   Spin=Vector3.new(Kit.Random(-4,4),Kit.Random(-4,4),Kit.Random(-4,4))}
 end
 local function orbit(c,e)
  local age=e-c.T0
  local k=smooth(age/(3.85-c.T0))
  local r,a=6-4.8*k,c.Phase+age*(1.4+2.6*k)
  local y=origin.Y-.7+(c.H+.7)*out3(age/.7)+.22*math.sin(age*3.1+c.Phase)
  return Vector3.new(origin.X+math.cos(a)*r,y,origin.Z+math.sin(a)*r)
 end
 scope:Every(function()
  local e=ctx:Elapsed()
  local slam=math.clamp((e-FOUND)/.12,0,1)
  if glow and e<FOUND then glow.Brightness=1.6*smooth((e-1.5)/2.4)end
  for _,c in ipairs(cubes)do
   local p=c.Part
   if e>=c.T0 and p.Parent then
    local at=orbit(c,math.min(e,FOUND))
    if slam>0 then at=at:Lerp(core,slam*slam)end
    p.Size=Vector3.one*math.max(c.Size*out3((e-c.T0)/.25)*(1-slam),.05)
    p.CFrame=CFrame.new(at)*CFrame.Angles(c.Spin.X*e,c.Spin.Y*e,c.Spin.Z*e)
    p.Transparency=0
   end
  end
  if slam<1 then return true end
  for _,c in ipairs(cubes)do if c.Part.Parent then c.Part:Destroy()end end
  return false
 end)
 -- The scanner's riser: blips that speed up and climb until the cut.
 task.spawn(function()
  local t=3.35
  while t<3.95 do
   if not ctx:Wait(t)then return end
   if live(t)then beep(1.6+(t-3.35)*4,.1+(t-3.35)*.3,panel)end
   t+=math.max(.03,.15-(t-3.35)*.25)
  end
 end)
 for _,s in ipairs(STEPS)do
  if not ctx:Wait(s.At)then return end
  local pct,on=s.Pct,live(s.At)
  each(function(r)
   r.Row.Visible=true;r.Pct.Text=tostring(pct)..'%'
   if s.Status then r.Status.Text=s.Status end
   r.Fill.BackgroundColor3=pct>=99 and AMBER or BLUE
   Kit.Tween(r.Fill,on and .4 or 0,{Size=UDim2.fromScale(pct/100,1)})
  end)
  if on then
   if pct>=99 then beep(.85,.3,panel,true);task.delay(.12,beep,.85,.26,panel,true)
   else for k=0,2 do task.delay(k*.05,beep,2.6+k*.35,.14,panel)end end
  end
 end
 if not ctx:Wait(3.7)then return end
 if live(3.7)then Kit.Cue('Whoosh',nil,.4)end
 -- A beat of silence before the answer.
 if not ctx:Wait(3.92)then return end
 if drone then Kit.Tween(drone,.08,{Volume=0})end

 -- 4.0: 200 OK. The cubes slam into the outline and the Reassemble clip builds the dog.
 if not ctx:Wait(FOUND)then return end
 found=true
 each(function(r)
  r.Tab.Text='200 OK';r.Code.Text='200';r.Code.TextColor3=GREEN;r.Red.Visible=false;r.Cyan.Visible=false
  r.Sub.Text='OK';r.Note.Text=string.format('found 1 dog in %.2f s.',FOUND)
  r.Row.Visible=true;r.Status.Text='dog found.';r.Pct.Text='100%'
  r.Fill.BackgroundColor3=GREEN;r.Fill.Size=UDim2.fromScale(1,1)
 end)
 for _,t in ipairs(tinted)do if t[1].Parent then (t[1]::any).Color=GREEN end end
 if screenLight then screenLight.Color=GREEN;screenLight.Brightness=3;Kit.Tween(screenLight,.5,{Brightness=1.6})end
 outline.Color3=WHITE;outline.SurfaceColor3=WHITE;outline.SurfaceTransparency=.55;outline.Transparency=0
 Kit.Tween(slot,.3,{Size=size*1.12});Kit.Tween(outline,.3,{Transparency=1,SurfaceTransparency=1})
 task.delay(.35,function()if slot.Parent then slot:Destroy()end end)
 if live(FOUND)then
  local n=near()
  Kit.Cue('Impact',nil,.85)
  task.delay(.1,function()if scope.Alive then Kit.Cue('Chime',nil,.45)end end)
  if n>.05 then Kit.Flash(WHITE,1-.6*n,.35);Kit.Shake(.45*n,.35)end
  if n>.2 then Kit.FOVPunch(-5*n,.06,.6)end
  scope:Ring(origin+up*.2,BLUE,1,14,.7,{Thickness=.35})
  if not low then scope:Ring(origin+up*.25,WHITE,.8,8,.45,{Thickness=.2,Alpha=.3,Segments=24})end
  scope:Burst(core,BLUE,30,{Speed=NumberRange.new(8,18),Lifetime=NumberRange.new(.35,.8),Size=NumberSequence.new(.5,0)})
  scope:Burst(core,WHITE,14,{Speed=NumberRange.new(4,10),Lifetime=NumberRange.new(.3,.6),Size=NumberSequence.new(.35,0)})
  -- The grade is island-wide: only the screens near the stage get the bright kick.
  if n>.05 then grade.Brightness=-.02+.22*n;Kit.Tween(grade,.45,{Brightness=-.02})end
  if glow then glow.Brightness=7;Kit.Tween(glow,.9,{Brightness=0})end
 elseif glow then glow.Brightness=0 end
 local render=scope:Highlight(model,BLUE,WHITE,.3,0)
 Kit.Tween(render,1.5,{FillTransparency=1,OutlineTransparency=1},Enum.EasingStyle.Sine,Enum.EasingDirection.In)
 -- A scanline sweeps down through it, raining pixels, while it renders back in.
 local sweep={scope:Part({Name='Scanline',Size=Vector3.new(12,.15,8),Color=BLUE,Transparency=.25,CFrame=stage+up*8})}
 local dust
 if not low then
  sweep[2]=scope:Part({Name='ScanTrail',Size=Vector3.new(12,.06,8),Color=WHITE,Transparency=.55,CFrame=stage+up*8.35})
  dust=scope:Emitter(sweep[1],{Rate=45,Color=ColorSequence.new(BLUE,WHITE),Speed=NumberRange.new(.5,2),
   Lifetime=NumberRange.new(.4,.8),SpreadAngle=Vector2.new(20,20),Acceleration=Vector3.new(0,-8,0),Size=NumberSequence.new(.18,0)})
  dust.EmissionDirection=Enum.NormalId.Bottom
 end
 scope:Every(function()
  local e=ctx:Elapsed()-FOUND
  local y=8*(1-smooth(e/1.1))
  local fade=math.clamp((e-1.1)/.3,0,1)
  sweep[1].CFrame=stage+up*(y+.1);sweep[1].Transparency=.25+.75*fade
  if sweep[2]then sweep[2].CFrame=stage+up*(y+.45);sweep[2].Transparency=.55+.45*fade end
  -- The pixel rain stops at the bottom; the carrier stays until the last pixels land.
  if dust and e>1.1 then dust.Enabled=false end
  if fade<1 or (dust and e<1.9) then return true end
  for _,p in ipairs(sweep)do p:Destroy()end
  return false
 end)
 -- The good news runs down the tongue's edge guides.
 for _,g in ipairs(guides)do
  local color=g.Color
  scope:Override(g,{Color=color})
  task.delay(math.max((g.Position-origin):Dot(fwd),0)/150,function()
   if scope.Alive and g.Parent then g.Color=BLUE;Kit.Tween(g,.6,{Color=color})end
  end)
 end
 -- In the open it runs round the loading ring.
 for i,d in ipairs(dots)do
  task.delay(live(FOUND)and (i-1)*.035 or 0,function()
   if not scope.Alive or not d.Parent then return end
   d.Color=GREEN
   if not calm then d.Size=Vector3.one*.95;Kit.Tween(d,.3,{Size=Vector3.one*.6})end
  end)
 end
 for _,l in ipairs(dotLights)do l.Color=GREEN end
 ctx:Title({Font=Enum.Font.Arcade,Hold=3.4})

 -- 4.55: the window shatters into tiles that tumble and fade.
 if not ctx:Wait(4.55)then return end
 shattered=true
 local cf=panel.CFrame
 local face=cf:VectorToWorldSpace(Vector3.zAxis)
 panel.Transparency=1;gui.Enabled=false
 if screenLight then Kit.Tween(screenLight,.4,{Brightness=0})end
 if live(4.55)and low then
  -- Low: no debris; the window powers off like an old monitor instead.
  Kit.Cue('Glitch',panel,.35);beep(3.2,.2,panel)
  local off=scope:Part({Name='PowerOff',Color=C(205,232,255),Size=Vector3.new(12,7,.05),CFrame=cf*CFrame.new(0,0,.14)})
  scope:Life(off,.3,function(a)
   off.Size=Vector3.new(math.max(12*(1-out3((a-.45)/.55)),.1),math.max(7*(1-out3(a/.45)),.08),.05)
   off.Transparency=a*a
  end)
 elseif live(4.55)then
  Kit.Cue('Glitch',panel,.35);beep(3.2,.2,panel)
  local cols,rows=8,5
  local cw,ch=12/cols,7/rows
  local tiles={}
  for i=0,cols-1 do for j=0,rows-1 do
   local x,y=-6+cw*(i+.5),3.5-ch*(j+.5)
   local pick=Kit.Random(0,1)
   local color=j==0 and BAR or (pick<.3 and GREEN or pick<.4 and WHITE or PAGE)
   local at=cf*CFrame.new(x,y,.1)
   tiles[#tiles+1]={Part=scope:Part({Name='Shard',Size=Vector3.new(cw-.12,ch-.12,.1),Color=color,CFrame=at,
    Material=(color==GREEN or color==WHITE)and Enum.Material.Neon or Enum.Material.SmoothPlastic}),CF=at,
    Vel=cf:VectorToWorldSpace(Vector3.new(x/6,y/3.5,0))*Kit.Random(3,7)+face*Kit.Random(3,8)+up*Kit.Random(2,6),
    Spin=Vector3.new(Kit.Random(-6,6),Kit.Random(-6,6),Kit.Random(-6,6))}
  end end
  scope:Every(function(dt,age)
   local a=math.min(age/.8,1)
   for _,s in ipairs(tiles)do
    s.Vel-=up*40*dt
    s.CF=(s.CF+s.Vel*dt)*CFrame.Angles(s.Spin.X*dt,s.Spin.Y*dt,s.Spin.Z*dt)
    s.Part.CFrame=s.CF;s.Part.Transparency=a*a
   end
   if a<1 then return true end
   for _,s in ipairs(tiles)do s.Part:Destroy()end
   return false
  end)
 end

 -- 5.0 ("...it was behind you."): a copy of it stands just behind this player for a blink.
 if not ctx:Wait(5)then return end
 local camera=workspace.CurrentCamera
 local character=Players.LocalPlayer.Character
 local root=character and character:FindFirstChild('HumanoidRootPart')
 if live(5)and camera and character and root and root:IsA('BasePart')and camera.CameraType~=Enum.CameraType.Scriptable then
  local eye=camera.CFrame.Position
  local back=Vector3.new(root.Position.X-eye.X,0,root.Position.Z-eye.Z)
  -- First person has no "behind you" on screen.
  if back.Magnitude>5 then
   back=back.Unit
   local spot=root.Position-back*2.5+back:Cross(up)*(Kit.Random(0,1)<.5 and -4.5 or 4.5)
   local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude
   params.FilterDescendantsInstances={character,scope.Folder,model}
   local hit=workspace:Raycast(spot+up*6,-up*30,params)
   local humanoid=character:FindFirstChildOfClass('Humanoid')
   local floor=hit and hit.Position or Vector3.new(spot.X,root.Position.Y-root.Size.Y/2-(humanoid and humanoid.HipHeight or 2),spot.Z)
   local ghost=scope:Ghost(model)
   local voxels=ghost:FindFirstChild('SM_Detached_Voxels')
   if voxels then voxels:Destroy()end
   if #ghost:GetChildren()>0 then
    local toward=Vector3.new(eye.X-floor.X,0,eye.Z-floor.Z)
    toward=toward.Magnitude>.1 and toward.Unit or -back
    local gl=model:GetAttribute('GroundLocal')
    local base=CFrame.lookAt(floor,floor+toward)*CFrame.new(-(typeof(gl)=='Vector3'and gl or Vector3.zero))
    Kit.SetGhostAlpha(ghost,.3);ghost:PivotTo(base)
    local h=scope:Highlight(ghost,BLUE,C(160,205,255),.55,.05)
    Kit.Cue('Sting',nil,.45);Kit.Cue('Glitch',nil,.25)
    local shown
    scope:Every(function(_,age)
     if not ghost.Parent then return false end
     local on=age<.75 and (calm or age<.07 or (age>.11 and age<.48) or (age>.54 and age<.64) or (age>.68 and age<.72))
     if on~=shown then
      shown=on;Kit.SetGhostAlpha(ghost,on and .3 or 1);h.Enabled=on
      if on and not calm and age>.5 then ghost:PivotTo(base*CFrame.new(Kit.Random(-.5,.5),0,0))end
     end
     if age<.8 then return true end
     ghost:Destroy();h:Destroy()
     return false
    end)
    task.delay(.75,function()if scope.Alive then Kit.Cue('Glitch',nil,.2)end end)
   else ghost:Destroy()end
  end
 end

 -- 5.6: rendered. Its pixel eyes switch on.
 if not ctx:Wait(5.6)then return end
 for _,name in ipairs({'SM_EyePixel_eye_L','SM_EyePixel_eye_R'})do
  local eye=model:FindFirstChild(name,true)
  if eye and eye:IsA('BasePart')then scope:Override(eye,{Color=BLUE,Material=Enum.Material.Neon})end
 end
 if live(5.6)then
  Kit.Cue('Chime',nil,.28)
  local head=model:FindFirstChild('head',true)
  local at=(head and head:IsA('Bone'))and head.TransformedWorldCFrame.Position or core+up*size.Y*.35
  scope:Burst(at,BLUE,16,{Speed=NumberRange.new(3,7),Lifetime=NumberRange.new(.4,.8),Size=NumberSequence.new(.3,0)})
 end
 -- The mouth (or the loading ring) and the screen ease back as it sets off.
 if not ctx:Wait(hold-.8)then return end
 for _,t in ipairs(tinted)do if t[1].Parent then Kit.Tween(t[1],.8,t[2])end end
 for _,d in ipairs(dots)do if d.Parent then Kit.Tween(d,.8,{Transparency=1})end end
 for _,l in ipairs(dotLights)do Kit.Tween(l,.8,{Brightness=0})end
 Kit.Tween(grade,.8,{Saturation=0,Contrast=0,Brightness=0,TintColor=Color3.new(1,1,1)})
 if not ctx:Wait(hold)then return end
end

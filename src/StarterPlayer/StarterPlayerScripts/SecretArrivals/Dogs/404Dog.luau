-- 404 DOG NOT FOUND, "the world fails to load", for the whole island. Wherever a player
-- stands, the render collapses around them: a dark blue fog closes in, the colour drains
-- out, the props around them stop loading one by one (a few leave magenta/black
-- missing-texture blocks behind), a hologram of the dog jitters and glitch-slices in their
-- sky, blue data rains on them and a loading bar at the top of their screen crawls to 99%
-- and sticks. On the stage meanwhile it drops straight through the tongue and leaves an
-- empty outline; a browser window (404, DOG NOT FOUND) sticks at 99% while data cubes rise
-- out of the belt and spiral in. Then 200 OK: a scan wave rolls out from the stage across
-- the whole island and everything snaps back as it passes (the fog, the colour, every
-- missing prop), the hologram powers off, every dog on the island looks at the stage and
-- every camera is pulled in to watch a scanline render the dog back in. Handed back, it
-- stands behind you for a blink.
-- Off the tongue (a Lucky pad, a dig, the machine) there are no mouth props: a ring of
-- loading pixels hovers round the stage and stutters, spins and turns green in their place.
--  0     it drops (Depth_Error); the render starts to collapse   .2 loading bar  .4 banner
--  .8    props near each player start to go missing  1.2 the hologram  1.5 search, data rain
--  3     missing-texture blocks  3.8 stuck at 99%: the fog closes in, more props go missing
--  5.3   cutaway: wide over the island                6.0 FOUND: 200 OK, the scan wave
--  6.55  the window shatters  7.5 its eyes switch on  8.1 handed back  8.3 behind you
-- SecretArrivalConfig.Dogs['404Dog'] must agree: Hold 9.6, Reassemble at FOUND, whispers at
-- .5 and 7.2 (the second one finishes typing as it appears behind you).
local Players=game:GetService('Players')
local UIS=game:GetService('UserInputService')
local C=Color3.fromRGB
local WHITE,GREEN,AMBER,RED,CYAN=C(232,244,255),C(60,255,120),C(255,190,60),C(255,60,96),C(60,236,255)
local PAGE,BAR,DIM=C(13,17,29),C(29,34,48),C(16,26,52)
local MAGENTA,INK=C(255,0,255),C(10,10,12)
local TICK='rbxasset://sounds/volume_slider.ogg'
local UP=Vector3.yAxis
-- The act on the arrival clock.
local SEARCH,STUCK,FOUND=1.5,3.8,6
local PANIC=FOUND-.5 -- everything stutters harder just before the answer
local SHATTER,EYES,BEHIND=FOUND+.55,7.5,8.3
-- The whole island: the loading bar, the first missing props, the hologram, the
-- missing-texture blocks, the cutaway (CUT to CUT_END), the scan wave's speed (studs/s:
-- across the yards in about a second, to the island's far corner by 9.3).
local LOADBAR,MISSING,HOLO,BLOCKS,CUT,CUT_END,SCAN=.2,.8,1.2,3,5.3,8.1,280
local W,H=600,350 -- the page in pixels: 12×7 studs at 50 px/stud
local CUTS={0,40,84,130,184,250,350} -- glitch slices (one cuts the 404 in half)
-- The search bar sticks at 99% (the page and the bar at the top of every screen).
local STEPS={{At=SEARCH,Pct=0,Status='searching for dog...'},{At=2.2,Pct=12},{At=3,Pct=37},{At=STUCK,Pct=99},
 {At=4.6,Pct=99,Status='still searching...'},{At=5.3,Pct=99,Status='retrying...'}}
-- The render collapses: a dark fog closes in and the colour drains (the place's Atmosphere
-- turns off Lighting fog, so the fog is the Atmosphere's), then closes in further at 99%.
local COLLAPSE={Lighting={Brightness=1.1,ExposureCompensation=-.18,Ambient=C(40,52,84),OutdoorAmbient=C(58,72,110),
  EnvironmentSpecularScale=.15},
 Atmosphere={Density=.52,Offset=0,Color=C(26,36,64),Decay=C(10,14,30),Glare=0,Haze=2.2},
 Grade={Saturation=-.62,Contrast=.14,Brightness=-.02,TintColor=C(206,222,255)}}
local DEEPER={Lighting={Brightness=.8,ExposureCompensation=-.3},Atmosphere={Density=.7,Haze=3},
 Grade={Saturation=-.86,Contrast=.2,Brightness=-.05}}
-- Props that stop loading: whole small models (a lantern, a bench, a yard's merchant) or
-- single small parts, within RADIUS of each player (PROP: a model's widest side at most).
local PROP=30
-- Never touched: the giant head and the stage (their own act), the Void, the DOG-O-MATIC
-- rig (it owns its boards' LocalTransparencyModifier), the portals and every dog.
local SKIP_TOP={['02_DogFactory']=true,['13_TheVoid']=true,['12_Portals']=true,['37_AttractionRefresh']=true,
 NavigationAnchors=true,KennelDogs=true}
local SKIP_NAME={ActiveDogs=true,Tongue=true,DisplaySlots=true,DisplayDog=true,Exhibit=true,CommittedPrize=true,
 WinningDog=true,AurionGrandPrize=true}
-- The hologram in every sky: studs tall, studs from each camera, degrees up.
local HOLO_H,HOLO_D,HOLO_E=150,360,math.rad(13)
local SPIN={'|','/','-','\\'}
local function smooth(x)x=math.clamp(x,0,1);return x*x*(3-2*x)end
local function out3(x)x=math.clamp(x,0,1);return 1-(1-x)^3 end
-- A scan wave: a ring wall of `count` segments (size.X thick, size.Y tall) growing out from
-- `center` at `speed` studs/s to `radius`, fading over its last third. (Kit's Ring eases
-- out; this keeps one speed, so whatever it passes over is back exactly at distance/speed.)
local function wave(scope:any,center:Vector3,color:Color3,radius:number,speed:number,size:Vector2,alpha:number,count:number)
 local m=Instance.new('Model');m.Name='ScanWave';m.Parent=scope.Folder
 local parts:{BasePart},cfs:{CFrame}={},{}
 for i=1,count do
  parts[i]=scope:Part({Name='Segment',Color=color,Size=Vector3.new(size.X,size.Y,1),Transparency=1,Parent=m})
  cfs[i]=parts[i].CFrame
 end
 local seconds=radius/speed
 scope:Every(function(_,age:number)
  local r=math.min(4+speed*age,radius)
  local width=2*math.pi*r/count*1.06
  local fade=alpha+(1-alpha)*smooth((r-radius*.66)/(radius*.34))
  for i,p in ipairs(parts)do
   local a=(i-.5)/count*math.pi*2
   local at=center+Vector3.new(math.cos(a)*r,size.Y/2,math.sin(a)*r)
   cfs[i]=CFrame.lookAt(at,at+Vector3.new(-math.sin(a),0,math.cos(a)))
   p.Size=Vector3.new(size.X,size.Y,width);p.Transparency=fade
  end
  workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
  if age<seconds then return true end
  m:Destroy()
  return false
 end)
end
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
-- Visible parts of the district within `radius` of `at`, walked a few hundred instances a
-- frame. A model whose bounding box is out of range is skipped whole (its box is kept in
-- `boxes`), so only the neighbourhood of ~37k instances is visited; skip(o) prunes a subtree.
local function gather(district:Instance,at:Vector3,radius:number,skip:(Instance)->boolean,alive:()->boolean,
 boxes:{[Instance]:Vector3}):{BasePart}
 local found:{BasePart}={}
 local visited=0
 local function walk(o:Instance):boolean
  visited+=1
  if visited%700==0 then task.wait();if not alive()then return false end end
  if skip(o)then return true end
  if o:IsA('BasePart')then
   if o.Transparency<.95 and (o.Position-at).Magnitude-o.Size.Magnitude/2<=radius then table.insert(found,o)end
   if not o:FindFirstChildWhichIsA('BasePart')then return true end
  elseif o:IsA('Model')then
   local ok,cf,size=pcall(function()return o:GetBoundingBox()end)
   if ok then
    boxes[o]=size
    local p=cf:PointToObjectSpace(at)
    local h=size/2
    local q=Vector3.new(math.clamp(p.X,-h.X,h.X),math.clamp(p.Y,-h.Y,h.Y),math.clamp(p.Z,-h.Z,h.Z))
    if (p-q).Magnitude>radius then return true end
   end
  elseif not o:IsA('Folder')then return true end
  for _,c in ipairs(o:GetChildren())do if not walk(c)then return false end end
  return true
 end
 for _,c in ipairs(district:GetChildren())do if not walk(c)then break end end
 return found
end
-- The props among `parts` (from gather, with its boxes): the largest small model each part
-- belongs to (its widest side at most PROP), else the part itself if it is small and not a
-- floor; never the ground right under `me`. Split into noticeable ones (2 studs or more)
-- and the rest, each in random order: {Prop, At (centre), Size (widest side)}.
local function propsAmong(district:Instance,parts:{BasePart},boxes:{[Instance]:Vector3},me:Vector3,random:()->number):({any},{any})
 local function propOf(p:BasePart):Instance?
  local best:Instance?=nil
  local a=p.Parent
  while a and a~=district and a:IsA('Model')do
   local box=boxes[a]
   if not box or math.max(box.X,box.Y,box.Z)>PROP then break end
   best=a;a=a.Parent
  end
  if best then return best end
  local s=p.Size
  local big=math.max(s.X,s.Y,s.Z)
  if big>14 or big<1 or (s.Y<1 and math.min(s.X,s.Z)>5)then return nil end
  return p
 end
 local seen,big,small={},{},{}
 for _,p in ipairs(parts)do
  local prop=propOf(p)
  if prop and not seen[prop]then
   seen[prop]=true
   local at,extent
   if prop:IsA('Model')then
    local cf,s=(prop::Model):GetBoundingBox()
    at,extent=cf.Position,math.max(s.X,s.Y,s.Z)
   else
    local part=prop::BasePart
    at,extent=part.Position,math.max(part.Size.X,part.Size.Y,part.Size.Z)
   end
   if Vector3.new(at.X-me.X,0,at.Z-me.Z).Magnitude>6 then
    table.insert(extent>=2 and big or small,{Prop=prop,At=at,Size=extent,Order=random()})
   end
  end
 end
 local function byOrder(a,b)return a.Order<b.Order end
 table.sort(big,byOrder);table.sort(small,byOrder)
 return big,small
end
-- A prop's visible parts (at most cap), never inside a pruned subtree (a display dog on its
-- plinth stays).
local function partsOf(prop:Instance,skip:(Instance)->boolean,cap:number):{BasePart}
 local list:{BasePart}={}
 local function walk(o:Instance)
  if #list>=cap or skip(o)then return end
  if o:IsA('BasePart')and o.Transparency<.95 then table.insert(list,o)end
  for _,c in ipairs(o:GetChildren())do walk(c)end
 end
 walk(prop)
 return list
end

return function(ctx)
 ctx.WhisperStyle={Font=Enum.Font.Code,Color=C(176,212,255),Glitch=.12,Chroma=true,Shake=false,Type=.035}
 -- Its own banner (SecretArrivalConfig Banner), on its own clock.
 ctx.ManualBanner=true
 local Kit,scope,model,config=ctx.Kit,ctx.Scope,ctx.Model,ctx.Config
 local low,calm,origin,hold=ctx.Low,Kit.ReducedMotion(),ctx.Origin,config.Hold
 local BLUE=config.Color
 local size=Kit.Size(model)
 local up=UP
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
 -- The address on the page and on every loading bar; off the tongue it names the finder.
 local where=({Tongue='on this tongue',Yard='in this yard',Excavation='at this dig site',Machine='in this machine'})[venue]or 'on this server'
 local by=ctx.By and string.gsub(string.lower(ctx.By),'[^%w_]','')or ''
 local url='dogrots://'..string.lower(venue)..(by~=''and '/'..by or '')..'/dog?id=95'

 -- The mouth's runes and lanterns go to link blue and stutter; the edge guides wait for 200 OK.
 local tinted,runes,guides={},{},{}
 local function tint(o,props)
  local saved={}
  for k in pairs(props)do saved[k]=(o::any)[k]end
  scope:Override(o,props);table.insert(tinted,{o,saved})
 end
 local district=workspace:FindFirstChild('DOGROTS_District')
 if venue=='Tongue'then
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
   nextFlicker=now+(e>PANIC and .05 or .14)
   local odds=e>PANIC and .5 or .18
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
   if e>SEARCH and e<PANIC then
    nextTick=now+1/#dots
    if e<STUCK then spin+=1;blink=true else blink=not blink end
    for i,d in ipairs(dots)do
     local lag=(spin-i)%#dots
     d.Color=lag==0 and (blink and WHITE or DIM)or (lag<3 and BLUE or DIM)
    end
   else
    nextTick=now+(e>PANIC and .05 or .14)
    local odds=e>PANIC and .5 or .18
    for _,d in ipairs(dots)do d.Color=Kit.Random(0,1)<odds and DIM or BLUE end
   end
   return true
  end)
 end
 local grade=scope:Grade({Saturation=-.2,Contrast=.12,Brightness=-.02,TintColor=C(222,234,255)},live(0)and .5 or .2)
 -- The whole island's music steps back for the glitch.
 scope:Duck(.25,.6)

 -- Where the dog should be: an empty outline that blinks like a missing asset.
 local slot=scope:Part({Name='MissingDog',Size=Vector3.new(size.X,.05,size.Z),Transparency=1,CFrame=stage+up*.06})
 local outline=Instance.new('SelectionBox');outline.Name='Outline';outline.Adornee=slot;outline.Color3=BLUE
 outline.LineThickness=.08;outline.SurfaceColor3=BLUE;outline.SurfaceTransparency=.9;outline.Parent=slot
 scope:Every(function()
  if found or not outline.Parent then return false end
  local e=ctx:Elapsed()
  outline.Transparency=(calm or (e*(e<PANIC and 1.6 or 7))%1<.62)and 0 or .75
  return true
 end)

 ---------------------------------------------------------------- the whole island
 -- Where this player stood when it began: the props around it are the ones that go.
 local me=Kit.Me()
 -- The scan wave at 200 OK rolls from the stage out past the island's far corners at SCAN
 -- studs/s; the moment it passes a point, that point is back.
 local map=Kit.Map
 local reachR=map.Radius*2
 for _,x in ipairs({map.Min.X,map.Max.X})do for _,z in ipairs({map.Min.Z,map.Max.Z})do
  reachR=math.max(reachR,Vector3.new(x-origin.X,0,z-origin.Z).Magnitude+40)
 end end
 local function passes(at:Vector3):number
  return FOUND+math.clamp(Vector3.new(at.X-origin.X,0,at.Z-origin.Z).Magnitude-4,0,reachR)/SCAN
 end

 -- The render collapses for this player wherever they are; it snaps back the moment the
 -- scan wave reaches their camera.
 local sky=nil
 if ctx:Elapsed()<FOUND-.6 then sky=scope:Sky(COLLAPSE,math.max(.4,2.4-ctx:Elapsed()),.35)end

 -- The loading bar at the top of every screen (in the top bar's free middle).
 local bar:any=nil
 local function buildBar()
  local playerGui=Players.LocalPlayer:FindFirstChildOfClass('PlayerGui')
  if not playerGui or not scope.Alive then return end
  local touch=UIS.TouchEnabled
  local g=Instance.new('ScreenGui');g.Name='DOGROTS_404Loading';g.ResetOnSpawn=false;g.IgnoreGuiInset=true
  g.DisplayOrder=95;g.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
  local track=frame(g,{Name='Track',Size=UDim2.new(1,0,0,4),BackgroundColor3=PAGE,BackgroundTransparency=.3})
  local fill=frame(track,{Name='Fill',Size=UDim2.fromScale(0,1),BackgroundColor3=BLUE})
  local w,h=touch and 240 or 320,touch and 22 or 26
  local pill=frame(g,{Name='Loading',AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,-h-8),Size=UDim2.fromOffset(w,h),
   BackgroundColor3=PAGE,BackgroundTransparency=.06},h/2)
  local edge=Instance.new('UIStroke');edge.Color=BLUE;edge.Thickness=1.5;edge.Transparency=.15;edge.Parent=pill
  local spin=text(pill,{Name='Spinner',Size=UDim2.new(0,16,1,0),Position=UDim2.fromOffset(11,0),Font=Enum.Font.RobotoMono,
   TextSize=touch and 13 or 15,TextColor3=BLUE,Text=SPIN[1]})
  local status=text(pill,{Name='Status',Size=UDim2.new(1,-96,1,0),Position=UDim2.fromOffset(31,0),Font=Enum.Font.RobotoMono,
   TextSize=touch and 11 or 13,TextColor3=C(176,194,228),TextXAlignment=Enum.TextXAlignment.Left,
   TextTruncate=Enum.TextTruncate.AtEnd,Text='loading '..url})
  local pct=text(pill,{Name='Percent',Size=UDim2.new(0,54,1,0),Position=UDim2.new(1,-64,0,0),Font=Enum.Font.RobotoMono,
   TextSize=touch and 12 or 14,TextColor3=WHITE,TextXAlignment=Enum.TextXAlignment.Right,Text='0%'})
  g.Parent=playerGui
  scope:Add(g)
  bar={Gui=g,Fill=fill,Pill=pill,Edge=edge,Spin=spin,Status=status,Pct=pct,Value=0,Done=false,H=h}
  Kit.Tween(pill,live(LOADBAR)and .35 or 0,{Position=UDim2.new(.5,0,0,8)},Enum.EasingStyle.Back)
  scope:Every(function()
   if not g.Parent or bar.Done then return false end
   local e=ctx:Elapsed()
   if not calm then bar.Spin.Text=SPIN[math.floor(e*12)%4+1]end
   -- Stuck at 99%, the number blinks.
   pct.TextTransparency=(not calm and bar.Value==99 and (e*2.5)%1<.35)and .75 or 0
   return true
  end)
 end
 local function setBar(value:number,status:string?,animate:boolean)
  if not bar then return end
  bar.Value=value;bar.Pct.Text=tostring(value)..'%'
  if status then bar.Status.Text=status end
  local color=value>=100 and GREEN or value>=99 and AMBER or BLUE
  bar.Fill.BackgroundColor3=color;bar.Edge.Color=color;bar.Spin.TextColor3=color
  Kit.Tween(bar.Fill,animate and .4 or 0,{Size=UDim2.fromScale(value/100,1)})
 end

 -- Props near this player stop loading (a layer on LocalTransparencyModifier, this client
 -- only): a few at first, flickering out, the rest once the bar sticks at 99%; the biggest
 -- leave a magenta/black missing-texture block where they stood. Each is back the moment
 -- the scan wave passes it.
 local missing:{any}={}
 local blocks:{any}={}
 local function skipped(o:Instance):boolean
  if o.Parent==district and SKIP_TOP[o.Name]then return true end
  if SKIP_NAME[o.Name]then return true end
  return o:IsA('Model')and(o:GetAttribute('DogId')~=nil or o:GetAttribute('EventObjectId')~=nil)
 end
 local function checker(at:Vector3,s:number):Model
  local m=Instance.new('Model');m.Name='MissingTexture';m.Parent=scope.Folder
  local h=s/2
  for x=0,1 do for y=0,1 do for z=0,1 do
   local odd=(x+y+z)%2==1
   scope:Part({Name='Checker',Size=Vector3.one*h,Color=odd and MAGENTA or INK,Material=odd and Enum.Material.Neon or Enum.Material.SmoothPlastic,
    CFrame=CFrame.new(at+Vector3.new((x-.5)*h,(y-.5)*h,(z-.5)*h)),Parent=m})
  end end end
  return m
 end
 local function lose()
  if not district or ctx:Elapsed()>=FOUND-1 then return end
  local radius=low and 60 or 80
  local boxes:{[Instance]:Vector3}={}
  local parts=gather(district,me,radius,skipped,function()return scope.Alive end,boxes)
  if not scope.Alive or ctx:Elapsed()>=FOUND-1 then return end
  local big,small=propsAmong(district,parts,boxes,me,function()return Kit.Random(0,1)end)
  local chosen={}
  local count=low and 12 or 28
  for _,list in ipairs({big,small})do
   for _,c in ipairs(list)do if #chosen<count then table.insert(chosen,c)end end
  end
  -- The first few go one by one from MISSING; the rest once the bar sticks.
  local early=math.ceil(#chosen*.45)
  local budget=low and 300 or 900
  for i,c in ipairs(chosen)do
   local list=partsOf(c.Prop,skipped,60)
   local m={Parts={},Release={},Update={},At=c.At,Size=c.Size,Hidden=false,Done=false,
    Hide=i<=early and MISSING+(i-1)/math.max(early,1)*(BLOCKS+.4-MISSING)+Kit.Random(0,.25)
     or STUCK+(i-early-1)/math.max(#chosen-early,1)*(PANIC-.2-STUCK)+Kit.Random(0,.2),
    Back=passes(c.At)}
   -- A loading glitch first: it blinks out for a frame or two before it goes.
   m.Blink=not calm and m.Hide-Kit.Random(.22,.4)or nil
   for _,p in ipairs(list)do
    -- Something else already owns this part's local transparency.
    if budget>0 and p.LocalTransparencyModifier==0 then
     budget-=1
     local _,release,update=scope:Override(p,{LocalTransparencyModifier=0})
     table.insert(m.Release,release);table.insert(m.Update,update)
    end
   end
   if #m.Release>0 then table.insert(missing,m)end
  end
  -- The biggest leave a missing-texture block (from BLOCKS on).
  local sorted=table.clone(missing)
  table.sort(sorted,function(a,b)return a.Size>b.Size end)
  for _,m in ipairs(sorted)do
   if #blocks>=(low and 2 or 4)then break end
   if m.Size>=2.5 and m.Size<=16 then
    table.insert(blocks,{At=m.At,Size=math.clamp(m.Size*.7,2,8),From=math.max(m.Hide,BLOCKS),Back=m.Back,Model=nil})
   end
  end
  scope:Every(function()
   local e=ctx:Elapsed()
   local busy=false
   for _,m in ipairs(missing)do
    if not m.Done then
     if e>=m.Back then
      m.Done=true
      for _,release in ipairs(m.Release)do release()end
     else
      busy=true
      local hidden=e>=m.Hide or (m.Blink~=nil and e>=m.Blink and e<m.Blink+.07)
      if hidden~=m.Hidden then
       m.Hidden=hidden
       for _,update in ipairs(m.Update)do update('LocalTransparencyModifier',hidden and 1 or 0)end
      end
     end
    end
   end
   for _,b in ipairs(blocks)do
    if b.Model and e>=b.Back then
     if live(b.Back)and not low then
      scope:Burst(b.At,MAGENTA,8,{Speed=NumberRange.new(4,9),Lifetime=NumberRange.new(.25,.5),Size=NumberSequence.new(.5,0)})
     end
     b.Model:Destroy();b.Model=false
    elseif b.Model==nil and e>=b.From and e<b.Back then
     b.Model=checker(b.At,b.Size)
     if live(b.From)then Kit.Cue('Glitch',b.Model:FindFirstChildWhichIsA('BasePart'),.22)end
    end
    if b.Model~=false and e<b.Back then busy=true end
   end
   return busy
  end)
 end
 task.spawn(lose)

 -- The hologram: a jittering ForceField copy of the dog in this player's sky beyond the
 -- stage (placed from the camera, so it is in shot wherever they stand), outlined so it
 -- reads through the fog. It tears sideways, red and cyan stale frames flash beside it
 -- and bright slices cut through it; at 99% it goes wild; at 200 OK it powers off.
 local holo:any,glow:any=nil,nil
 local copies:{any}={}
 local slices:{any}={}
 local holoBox=Vector3.new(HOLO_H*.4,HOLO_H,HOLO_H*.5)
 local base=CFrame.identity
 local bearing:Vector3?=nil
 local function skyAt(dt:number):CFrame
  local cam=workspace.CurrentCamera
  local eye=cam and cam.CFrame.Position or map.Center
  local flat=Vector3.new(origin.X-eye.X,0,origin.Z-eye.Z)
  local want=flat.Magnitude>24 and flat.Unit or bearing
  if not want and cam then want=Vector3.new(cam.CFrame.LookVector.X,0,cam.CFrame.LookVector.Z)end
  if not want or want.Magnitude<1e-3 then want=-fwd end
  want=(want::Vector3).Unit
  -- Swings round slowly when the player walks round the stage, and never flips.
  local b=bearing and bearing:Lerp(want,math.min(1,dt*1.5))or want
  b=b.Magnitude>1e-3 and b.Unit or want
  bearing=b
  local p=eye+b*HOLO_D*math.cos(HOLO_E)+up*HOLO_D*math.sin(HOLO_E)
  return CFrame.lookAt(p,p-b)
 end
 local function hologram()
  base=skyAt(1)
  holo=ctx:Colossus({Height=HOLO_H,At=base,Style='Hologram',Color=BLUE,Alpha=.45,Clip='EX_Glitched',FadeIn=live(HOLO)and .35 or .1})
  if not holo then return end
  local _,box=Kit.Bounds(holo.Model)
  holoBox=box
  glow=scope:Highlight(holo.Model,BLUE,CYAN,.82,.25)
  if live(HOLO)then
   Kit.Cue('Glitch',nil,.22)
   -- CRT power-on: a line snaps across it and opens.
   local on=scope:Part({Name='PowerOn',Color=WHITE,Size=Vector3.one})
   scope:Life(on,.35,function(a)
    on.CFrame=base*CFrame.new(0,0,-(holoBox.Z/2+2))
    on.Size=Vector3.new(math.max(holoBox.X*1.1*out3(a/.3),.5),math.max(HOLO_H*out3((a-.3)/.5),.5),.5)
    on.Transparency=smooth((a-.35)/.65)
   end)
  end
  if calm then return end
  -- Stale frames (no animation) and the slices.
  if not low then
   for i,color in ipairs({RED,CYAN})do
    local c=ctx:Colossus({Height=HOLO_H,At=base,Style='Hologram',Color=color,Alpha=.55,FadeIn=0})
    if c then c:Fade(1,0);copies[i]=c end
   end
  end
  for i=1,low and 3 or 6 do
   slices[i]={Part=scope:Part({Name='GlitchSlice',Color=i%3==0 and WHITE or i%2==0 and CYAN or BLUE,Transparency=1,Size=Vector3.one}),
    Offset=Vector3.zero}
  end
 end
 local jolt,joltUntil,nextJolt,shown=Vector3.zero,0,0,false
 local function holoStep(dt:number)
  if not holo or not holo.Model.Parent then return false end
  local e,now=ctx:Elapsed(),os.clock()
  base=skyAt(dt)
  local wild=e>=STUCK and e<FOUND
  if not calm and e<FOUND and now>=nextJolt then
   nextJolt=now+.09
   if Kit.Random(0,1)<(wild and .45 or .14)then
    local amp=(wild and .07 or .03)*HOLO_H
    jolt=Vector3.new(Kit.Random(-amp,amp),Kit.Random(-amp,amp)*.2,0);joltUntil=now+Kit.Random(.04,.11)
    for _,s in ipairs(slices)do
     local on=Kit.Random(0,1)<(wild and .8 or .5)
     s.Part.Size=Vector3.new(holoBox.X*Kit.Random(1.05,1.45),HOLO_H*Kit.Random(.008,.03),.4)
     s.Offset=Vector3.new(Kit.Random(-amp,amp)*.6,Kit.Random(-.45,.45)*HOLO_H,-(holoBox.Z/2+3))
     s.On=on
    end
   end
  end
  local tearing=now<joltUntil and e<FOUND
  holo:Pose(tearing and base*CFrame.new(jolt)or base,0)
  if tearing~=shown then
   shown=tearing
   for _,c in pairs(copies)do c:Fade(tearing and .55 or 1,0)end
   if glow then glow.OutlineColor=tearing and WHITE or CYAN end
  end
  for i,c in pairs(copies)do c:Pose(base*CFrame.new((i==1 and -1 or 1)*holoBox.X*.06,0,0),0)end
  for _,s in ipairs(slices)do
   if tearing and s.On then s.Part.CFrame=base*CFrame.new(s.Offset);s.Part.Transparency=.3 else s.Part.Transparency=1 end
  end
  return true
 end
 -- 200 OK: it flashes green, collapses to a line and a dot like an old monitor, and is gone.
 local function powerOff()
  if not holo then return end
  local h=holo
  for _,c in pairs(copies)do c:Stop(0)end
  table.clear(copies)
  for _,s in ipairs(slices)do s.Part:Destroy()end
  table.clear(slices)
  local onTime=live(FOUND)
  if glow then glow.FillColor=GREEN;glow.OutlineColor=WHITE;glow.FillTransparency=.35 end
  task.delay(onTime and .15 or 0,function()
   if not scope.Alive then return end
   h:Fade(1,.18)
   if glow then Kit.Tween(glow,.2,{FillTransparency=1,OutlineTransparency=1})end
   if onTime then
    local line=scope:Part({Name='PowerOff',Color=WHITE,Size=Vector3.one})
    scope:Life(line,.5,function(a)
     line.CFrame=base*CFrame.new(0,0,-(holoBox.Z/2+2))
     line.Size=Vector3.new(math.max(holoBox.X*1.1*(1-out3((a-.4)/.6)),.6),math.max(HOLO_H*.12*(1-out3(a/.4)),.6),.5)
     line.Transparency=a*a
    end)
    Kit.Cue('Glitch',nil,.2)
   end
   task.delay(.2,function()
    if not scope.Alive then return end
    h:Stop(0)
    if glow then glow:Destroy();glow=nil end
   end)
  end)
 end

 -- Every camera is pulled out over the island for the answer: wide behind the stage's
 -- line of sight (the fog, the hologram in the sky beyond it) as the scan wave rolls out
 -- under it and the fog snaps away, then down to the stage as the scanline renders the dog
 -- in and close on its face as its eyes switch on; handed back at CUT_END. A shot that
 -- would sit inside something solid is pulled in front of it.
 local cut:any=nil
 local function cutaway()
  local skip:{Instance}={model}
  local fx=workspace:FindFirstChild('DOGROTS_SecretArrivalFX')
  if fx then table.insert(skip,fx)end
  for _,p in ipairs(Players:GetPlayers())do if p.Character then table.insert(skip,p.Character)end end
  local sight=RaycastParams.new();sight.FilterType=Enum.RaycastFilterType.Exclude;sight.RespectCanCollide=true
  sight.FilterDescendantsInstances=skip
  local function shot(at:number,eye:Vector3,target:Vector3,fov:number,linear:boolean?)
   local d=eye-target
   local hit=workspace:Raycast(target,d,sight)
   if hit and (hit.Position-target).Magnitude>6 then eye=hit.Position-d.Unit*2 end
   return {At=at,CFrame=Kit.Frame(eye,target),Fov=fov,Linear=linear}
  end
  -- (Off the tongue its facing may only be known by now.)
  local f=facing()
  local across=f:Cross(up)
  local mid=origin+up*size.Y*.55
  return ctx:Cutaway({
   shot(CUT,origin+f*120+across*36+up*46,origin+up*30,62),
   shot(FOUND+.2,origin+f*104+across*30+up*40,origin+up*26,60),
   shot(FOUND+.95,origin+f*30+across*9+up*11,mid,50),
   shot(EYES+.2,origin+f*12+across*3+up*size.Y*.85,mid+up*size.Y*.1,44),
   shot(CUT_END,origin+f*10.5+across*2.6+up*size.Y*.82,mid+up*size.Y*.12,42,true),
  },{Focus=origin,Bars=.09,Shake=.08})
 end

 -- The map-wide beats, on the server clock (a late client skips what it missed).
 task.spawn(function()
  local b=config.Banner
  if type(b)~='table'then return end
  if ctx:Elapsed()>(b.At or .4)+(b.Hold or 3)then return end
  if not ctx:Wait(b.At or .4)then return end
  ctx:Banner(b)
 end)
 task.spawn(function()
  if live(0)then Kit.Cue('Glitch',nil,.3)end
  if not ctx:Wait(LOADBAR)then return end
  if ctx:Elapsed()<FOUND+1.2 then
   buildBar()
   if ctx:Elapsed()>=FOUND then setBar(100,'200 OK  ·  dog found',false)end
  end
  if not ctx:Wait(MISSING)then return end
  if live(MISSING)and #missing>0 then Kit.Cue('Glitch',nil,.18)end
  if not ctx:Wait(HOLO)then return end
  if ctx:Elapsed()<FOUND-.4 then
   hologram()
   if holo then scope:Every(holoStep)end
  end
  if not ctx:Wait(SEARCH)then return end
  local rain=nil
  if ctx:Elapsed()<FOUND then
   -- Blue data streams down on every player.
   rain=scope:Rain({Texture=Kit.Textures.Spark,Rate=80,Area=120,Height=50,Color=ColorSequence.new(BLUE,WHITE),LightEmission=1,
    LightInfluence=0,Speed=NumberRange.new(38,52),Lifetime=NumberRange.new(1.1,1.5),SpreadAngle=Vector2.new(2,2),
    Size=NumberSequence.new(.22),Squash=NumberSequence.new(2.4),
    Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.1),NumberSequenceKeypoint.new(.8,.35),NumberSequenceKeypoint.new(1,1)})})
  end
  if not ctx:Wait(STUCK)then return end
  -- Stuck at 99%: the fog closes in further and the colour all but goes.
  if sky and ctx:Elapsed()<FOUND-.3 then sky:Set(DEEPER,live(STUCK)and .9 or .2)end
  if live(STUCK)then Kit.Cue('Glitch',nil,.25)end
  if not ctx:Wait(CUT-.6)then return end
  cut=cutaway()
  if not ctx:Wait(FOUND)then return end
  -- 200 OK, for the whole island.
  if rain then rain.Rate=0 end
  powerOff()
  if bar and not bar.Done then
   setBar(100,'200 OK  ·  dog found',live(FOUND))
   bar.Done=true;bar.Spin.Text='*'
  end
  if live(FOUND)then
   -- The scan wave: a see-through green wall with a bright scanline along its foot.
   wave(scope,origin,GREEN,reachR,SCAN,Vector2.new(.6,10),.55,low and 24 or 60)
   if not low then wave(scope,origin+up*.2,WHITE,reachR,SCAN,Vector2.new(1,.7),.05,60)end
   Kit.Cue('Whoosh',nil,.55)
   if cut and cut.Active then cut:Shake(.6,.4)end
  end
  -- Every dog on the island looks at the stage.
  if ctx:Elapsed()<hold-.5 then
   scope:Glance(function()return (model.Parent and ctx:Ground()or origin)+up*size.Y*.6 end,{Exclude=model,Turn=.6,Ripple=320})
  end
  -- The fog lifts the moment the wave reaches this camera.
  scope:Every(function()
   local cam=workspace.CurrentCamera
   if ctx:Elapsed()<passes(cam and cam.CFrame.Position or Kit.Me())then return true end
   if sky then sky:Release(.35)end
   return false
  end)
  if not ctx:Wait(FOUND+1.6)then return end
  if bar then
   local gone=bar
   Kit.Tween(gone.Pill,.35,{Position=UDim2.new(.5,0,0,-gone.H-8)},Enum.EasingStyle.Back,Enum.EasingDirection.In)
   Kit.Tween(gone.Fill,.5,{BackgroundTransparency=1})
   task.delay(.6,function()if gone.Gui.Parent then gone.Gui:Destroy()end end)
  end
 end)

 ---------------------------------------------------------------- the stage
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
  local n=near();if n>.05 and not calm then Kit.Flash(RED,1-.15*n,.18)end
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
 local pages,bands={},{}
 local cuts=low and {0,H}or CUTS
 for i=1,#cuts-1 do
  local band=frame(gui,{Name='Slice',Size=UDim2.fromOffset(W,cuts[i+1]-cuts[i]),Position=UDim2.fromOffset(0,cuts[i]),
   BackgroundTransparency=1,ClipsDescendants=true})
  local r=page(band,url,where,BLUE)
  r.Page.Position=UDim2.fromOffset(0,-cuts[i])
  table.insert(pages,r);table.insert(bands,{Frame=band,Top=cuts[i]})
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
  local wild=e>PANIC and e<FOUND
  nextCut=now+(wild and .06 or .12)
  local chance,amp=.3,20
  if e>=FOUND then chance=0 elseif wild then chance,amp=.75,34 elseif e>SEARCH then chance,amp=.15,10 end
  if calm then chance,amp=chance*.5,amp*.25 end
  for _,s in ipairs(bands)do
   s.Frame.Position=UDim2.fromOffset(Kit.Random(0,1)<chance and math.round(Kit.Random(-amp,amp))or 0,s.Top)
  end
  return true
 end)

 -- 1.5-5.9: the search. Data cubes rise out of the belt and spiral in on the outline.
 if not ctx:Wait(SEARCH)then return end
 local drone=scope:Drone('Drone',low and .2 or .3,.8,1.2)
 local heart=scope:Anchor(core,'DataCore')
 local glowLight=not low and scope:Light(heart,BLUE,22,0)or nil
 local cubes={}
 local count=low and 12 or 30
 for i=1,count do
  cubes[i]={Part=scope:Part({Name='Data',Size=Vector3.one*.05,Color=i%3==0 and WHITE or BLUE,Transparency=1,CFrame=CFrame.new(origin)}),
   Size=Kit.Random(.4,.8),T0=SEARCH+(i-1)/count*2.6,Phase=i*2.4,H=Kit.Random(.6,math.max(size.Y*.95,1.5)),
   Spin=Vector3.new(Kit.Random(-4,4),Kit.Random(-4,4),Kit.Random(-4,4))}
 end
 local function orbit(c,e)
  local age=e-c.T0
  local k=smooth(age/(FOUND-.15-c.T0))
  local r,a=6-4.8*k,c.Phase+age*(1.4+2.6*k)
  local y=origin.Y-.7+(c.H+.7)*out3(age/.7)+.22*math.sin(age*3.1+c.Phase)
  return Vector3.new(origin.X+math.cos(a)*r,y,origin.Z+math.sin(a)*r)
 end
 scope:Every(function()
  local e=ctx:Elapsed()
  local slam=math.clamp((e-FOUND)/.12,0,1)
  if glowLight and e<FOUND then glowLight.Brightness=1.6*smooth((e-SEARCH)/(FOUND-.1-SEARCH))end
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
  local from=FOUND-.65
  local t=from
  while t<FOUND-.05 do
   if not ctx:Wait(t)then return end
   if live(t)then beep(1.6+(t-from)*4,.1+(t-from)*.3,panel)end
   t+=math.max(.03,.15-(t-from)*.25)
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
  -- The bar at the top of every screen keeps step with the page.
  if bar and not bar.Done then setBar(pct,s.Status,on)end
  if on then
   if pct>=99 then beep(.85,.3,panel,true);task.delay(.12,beep,.85,.26,panel,true)
   else for k=0,2 do task.delay(k*.05,beep,2.6+k*.35,.14,panel)end end
  end
 end
 if not ctx:Wait(FOUND-.3)then return end
 if live(FOUND-.3)then Kit.Cue('Whoosh',nil,.4)end
 -- A beat of silence before the answer.
 if not ctx:Wait(FOUND-.08)then return end
 if drone then Kit.Tween(drone,.08,{Volume=0})end

 -- 6.0: 200 OK. The cubes slam into the outline and the Reassemble clip builds the dog.
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
  if n>.05 and not calm then Kit.Flash(WHITE,1-.6*n,.35);Kit.Shake(.45*n,.35)end
  if n>.2 then Kit.FOVPunch(-5*n,.06,.6)end
  scope:Ring(origin+up*.2,BLUE,1,14,.7,{Thickness=.35})
  if not low then scope:Ring(origin+up*.25,WHITE,.8,8,.45,{Thickness=.2,Alpha=.3,Segments=24})end
  scope:Burst(core,BLUE,30,{Speed=NumberRange.new(8,18),Lifetime=NumberRange.new(.35,.8),Size=NumberSequence.new(.5,0)})
  scope:Burst(core,WHITE,14,{Speed=NumberRange.new(4,10),Lifetime=NumberRange.new(.3,.6),Size=NumberSequence.new(.35,0)})
  -- The grade is island-wide: only the screens near the stage get the bright kick.
  if n>.05 then grade.Brightness=-.02+.22*n;Kit.Tween(grade,.45,{Brightness=-.02})end
  if glowLight then glowLight.Brightness=7;Kit.Tween(glowLight,.9,{Brightness=0})end
 elseif glowLight then glowLight.Brightness=0 end
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

 -- 6.55: the window shatters into tiles that tumble and fade.
 if not ctx:Wait(SHATTER)then return end
 shattered=true
 local cf=panel.CFrame
 local face=cf:VectorToWorldSpace(Vector3.zAxis)
 panel.Transparency=1;gui.Enabled=false
 if screenLight then Kit.Tween(screenLight,.4,{Brightness=0})end
 if live(SHATTER)and low then
  -- Low: no debris; the window powers off like an old monitor instead.
  Kit.Cue('Glitch',panel,.35);beep(3.2,.2,panel)
  local off=scope:Part({Name='PowerOff',Color=C(205,232,255),Size=Vector3.new(12,7,.05),CFrame=cf*CFrame.new(0,0,.14)})
  scope:Life(off,.3,function(a)
   off.Size=Vector3.new(math.max(12*(1-out3((a-.45)/.55)),.1),math.max(7*(1-out3(a/.45)),.08),.05)
   off.Transparency=a*a
  end)
 elseif live(SHATTER)then
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

 -- 7.5: rendered. Its pixel eyes switch on (in the cutaway's close-up).
 if not ctx:Wait(EYES)then return end
 for _,name in ipairs({'SM_EyePixel_eye_L','SM_EyePixel_eye_R'})do
  local eye=model:FindFirstChild(name,true)
  if eye and eye:IsA('BasePart')then scope:Override(eye,{Color=BLUE,Material=Enum.Material.Neon})end
 end
 if live(EYES)then
  Kit.Cue('Chime',nil,.28)
  local head=model:FindFirstChild('head',true)
  local at=(head and head:IsA('Bone'))and head.TransformedWorldCFrame.Position or core+up*size.Y*.35
  scope:Burst(at,BLUE,16,{Speed=NumberRange.new(3,7),Lifetime=NumberRange.new(.4,.8),Size=NumberSequence.new(.3,0)})
 end

 -- 8.3 ("...it was behind you."): back in their own camera, a copy of it stands just
 -- behind every player for a blink.
 if not ctx:Wait(BEHIND)then return end
 local camera=workspace.CurrentCamera
 local character=Players.LocalPlayer.Character
 local root=character and character:FindFirstChild('HumanoidRootPart')
 if live(BEHIND)and camera and character and root and root:IsA('BasePart')and camera.CameraType~=Enum.CameraType.Scriptable then
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
   local toward=Vector3.new(eye.X-floor.X,0,eye.Z-floor.Z)
   toward=toward.Magnitude>.1 and toward.Unit or -back
   -- A copy of the dog itself; if its parts are not here, the menu model at its size.
   local ghost:Model?=nil
   local base0=CFrame.identity
   if Kit.Root(model)then
    local copy:Model=scope:Ghost(model)
    local voxels=copy:FindFirstChild('SM_Detached_Voxels')
    if voxels then voxels:Destroy()end
    if #copy:GetChildren()>0 then ghost=copy else copy:Destroy()end
   end
   if ghost then
    local gl=model:GetAttribute('GroundLocal')
    base0=CFrame.lookAt(floor,floor+toward)*CFrame.new(-(typeof(gl)=='Vector3'and gl or Vector3.zero))
   else
    local copy=Kit.DogCopy('404Dog',model)
    if copy then
     local voxels=copy:FindFirstChild('SM_Detached_Voxels')
     if voxels then voxels:Destroy()end
     local _,box=Kit.Bounds(copy)
     pcall(function()copy:ScaleTo(copy:GetScale()*size.Y/math.max(box.Y,.1))end)
     local centre,scaled=Kit.Bounds(copy)
     copy.Parent=scope.Folder
     ghost=copy
     base0=CFrame.lookAt(floor,floor+toward)*CFrame.new(-centre.X,scaled.Y/2-centre.Y,-centre.Z)
    end
   end
   if ghost then
    local g:Model=ghost
    Kit.SetGhostAlpha(g,.3);g:PivotTo(base0)
    local h=scope:Highlight(g,BLUE,C(160,205,255),.55,.05)
    Kit.Cue('Sting',nil,.45);Kit.Cue('Glitch',nil,.25)
    local shownNow
    scope:Every(function(_,age)
     if not g.Parent then return false end
     local on=age<.75 and (calm or age<.07 or (age>.11 and age<.48) or (age>.54 and age<.64) or (age>.68 and age<.72))
     if on~=shownNow then
      shownNow=on;Kit.SetGhostAlpha(g,on and .3 or 1);h.Enabled=on
      if on and not calm and age>.5 then g:PivotTo(base0*CFrame.new(Kit.Random(-.5,.5),0,0))end
     end
     if age<.8 then return true end
     g:Destroy();h:Destroy()
     return false
    end)
    task.delay(.75,function()if scope.Alive then Kit.Cue('Glitch',nil,.2)end end)
   end
  end
 end

 -- The mouth (or the loading ring) and the screen ease back as it sets off.
 if not ctx:Wait(hold-.8)then return end
 for _,t in ipairs(tinted)do if t[1].Parent then Kit.Tween(t[1],.8,t[2])end end
 for _,d in ipairs(dots)do if d.Parent then Kit.Tween(d,.8,{Transparency=1})end end
 for _,l in ipairs(dotLights)do Kit.Tween(l,.8,{Brightness=0})end
 Kit.Tween(grade,.8,{Saturation=0,Contrast=0,Brightness=0,TintColor=Color3.new(1,1,1)})
 if not ctx:Wait(hold)then return end
end

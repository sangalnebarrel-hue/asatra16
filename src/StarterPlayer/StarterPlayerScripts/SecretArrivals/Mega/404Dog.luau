-- 404 DOG NOT FOUND, island-wide: "MISSING TEXTURES". The sky fails to load: night falls in
-- one cut, the horizon goes missing-texture magenta and the picture turns hard and
-- crushed. Error signs pop into the sky all round the island (a huge 404 over the head),
-- jittering and flickering, and the world around every player loses its textures in a
-- wave: magenta and black checkers that flicker faster while the search sticks at 99%.
-- At 3.2 every screen blue-screens for half a second. At 4 (Reassemble: 200 OK) a white
-- sweep rolls out from the stage and puts the world back as it reaches each player, the
-- signs turn green and break up, loose pixels rain down and the banner says it was found.
-- Off the tongue the 404 hangs over wherever it was opened.
local C=Color3.fromRGB
local MAGENTA,BLACK,WHITE,GREEN,RED,BSOD=C(255,0,255),C(0,0,0),C(232,244,255),C(60,255,120),C(255,60,96),C(0,0,170)
local FOUND,CRASH=4,3.2
local TEXTS={'ERROR 404','DOG NOT FOUND','404','dog.mesh FAILED','NULL','ERROR 404','asset not found','DOG NOT FOUND','HTTP 404','where dog?'}
local function out3(x)x=math.clamp(x,0,1);return 1-(1-x)^3 end
-- A sign's text and its outline fade together.
local function fade(l,a)
 l.TextTransparency=a
 local s=l:FindFirstChildOfClass('UIStroke');if s then s.Transparency=a end
end

-- Map parts round this player, nearest first (never the dogs themselves).
local function gather(m,radius,limit)
 local district=workspace:FindFirstChild('DOGROTS_District')
 local skip={}
 if district then
  local kennels=district:FindFirstChild('KennelDogs');if kennels then table.insert(skip,kennels)end
  local line=district:FindFirstChild('03_DogLine');local active=line and line:FindFirstChild('ActiveDogs')
  if active then table.insert(skip,active)end
 end
 local cam=m:Camera()
 local list={}
 for _,p in ipairs(m:MapParts(radius,1500))do
  local keep=p.Name~='RootPart'
  for _,f in ipairs(skip)do if p:IsDescendantOf(f)then keep=false;break end end
  if keep then table.insert(list,{Part=p,D=(p.Position-cam).Magnitude})end
 end
 table.sort(list,function(a,b)return a.D<b.D end)
 for i=#list,limit+1,-1 do list[i]=nil end
 return list
end

return function(m)
 local Kit=m.Kit
 local low=m.Low
 local BLUE=m.Color
 local onTongue=m.Venue=='Tongue'
 local fresh=m.Late<.5
 local focus=onTongue and m.Head or m:Ground(m.Origin)
 local sweepFrom=onTongue and m:Ground(m.Stage)or focus
 local toward=Vector3.new(m.Center.X-focus.X,0,m.Center.Z-focus.Z)
 local facing=onTongue and Vector3.zAxis or (toward.Magnitude>40 and toward.Unit or Vector3.zAxis)

 -- The sky fails to load: one hard cut to night with a magenta horizon.
 local sky=m:Sky({ClockTime=0,Brightness=0,Ambient=C(70,10,70),OutdoorAmbient=C(96,16,96),FogColor=MAGENTA,FogStart=60,FogEnd=900,
  ExposureCompensation=.25},fresh and .2 or .05,.9)
 local grade=m:Grade({Contrast=.45,Saturation=.25,TintColor=C(255,214,255)},fresh and .15 or .05,.6)
 if fresh then
  m:Cue('Static',nil,.4)
  -- The first frames stutter between broken and fine.
  m:Every(function(_,age)
   grade.Brightness=age<.6 and (math.random()<.35 and .25 or -.05) or 0
   return age<.6
  end)
 end

 -- Error signs all round the island; the biggest one hangs over the head.
 local signs={}
 local function sign(text,frame,size,popAt)
  local part,labels=m:Text3D(text,frame,size,{Font=Enum.Font.Code,Color=RED,StrokeThickness=6,Alpha=1})
  table.insert(signs,{Part=part,Labels=labels,Home=frame,Pop=popAt,Text=text,Size=size,Jolt=CFrame.identity,JoltUntil=0})
 end
 local count=low and 5 or 10
 for i=1,count do
  local a=(i-1)/count*math.pi*2+.3
  local r=Kit.Random(300,420)
  local at=m.Center+Vector3.new(math.cos(a)*r,Kit.Random(80,220),math.sin(a)*r)
  local frame=CFrame.lookAt(at,Vector3.new(m.Center.X,at.Y,m.Center.Z))*CFrame.Angles(0,0,math.rad(Kit.Random(-6,6)))
  sign(TEXTS[(i-1)%#TEXTS+1],frame,Vector2.new(150,48),.33+(i-1)*.18)
 end
 local over=focus+Vector3.new(0,onTongue and 190 or 160,0)+facing*40
 sign('404',CFrame.lookAt(over,over+facing),Vector2.new(260,120),.33)
 local big=signs[#signs]
 local found=false
 local nextJolt=0
 m:Every(function()
  local e=m:Elapsed()
  local now=os.clock()
  local jolt=now>=nextJolt
  if jolt then nextJolt=now+(e>3.5 and e<FOUND and .05 or .11)end
  local wild=e>3.5 and e<FOUND
  local alive=false
  for i,s in ipairs(signs)do
   if s.Part.Parent then
    alive=true
    local shown=e>=s.Pop
    if found then
     -- 200 OK, then it breaks up and is gone (the big one stays a while as DOG FOUND).
     local t=e-FOUND-(s==big and 4 or .5+i*.04)
     local alpha=math.clamp(t/.6,0,1)
     for _,l in ipairs(s.Labels)do fade(l,alpha)end
     s.Part.CFrame=s.Home*CFrame.new(0,-out3(t/.6)*20,0)
     if t>=.6 then s.Part:Destroy()end
    elseif shown then
     if m.Reduced then
      for _,l in ipairs(s.Labels)do fade(l,0)end
     elseif jolt then
      if math.random()<(wild and .55 or .12)then
       s.Jolt=CFrame.new(Kit.Random(-4,4),Kit.Random(-2,2),0)*CFrame.Angles(0,0,math.rad(Kit.Random(-4,4)));s.JoltUntil=now+.06
      end
      local swap=math.random()
      for _,l in ipairs(s.Labels)do
       l.TextColor3=swap<.1 and MAGENTA or swap<.2 and BLUE or RED
       -- It pops in over a few frames, then drops out now and then.
       fade(l,(e-s.Pop<.25 and math.random()<.5)and 1 or (math.random()<(wild and .2 or .05)and 1 or 0))
      end
     end
     s.Part.CFrame=now<s.JoltUntil and s.Home*s.Jolt or s.Home
    else
     for _,l in ipairs(s.Labels)do fade(l,1)end
    end
   end
  end
  return alive
 end)
 task.spawn(function()
  for i,s in ipairs(signs)do
   if i>4 then break end
   if not m:Wait(s.Pop)then return end
   if m:Fresh(s.Pop,.2)then m:Cue('Glitch',nil,.14)end
  end
 end)

 -- The world round each player loses its textures in a wave from where they stand: magenta
 -- and black checkers (local overrides, restored as the white sweep reaches them).
 local applied,cursor,list={},1,{}
 local restoring=false
 local function checker(p)
  local q=p.Position/8
  return (math.floor(q.X)+math.floor(q.Y)+math.floor(q.Z))%2==0 and MAGENTA or BLACK
 end
 if m:Elapsed()<3.6 then
  if not m:Wait(.5)then return end
  list=gather(m,170,low and 220 or 380)
  local t0=m:Elapsed()
  m:Every(function()
   local front=(m:Elapsed()-t0)*150
   local n=0
   while not restoring and cursor<=#list and list[cursor].D<=front and n<60 do
    local row=list[cursor];cursor+=1;n+=1
    if row.Part.Parent then
     local color=checker(row.Part)
     local _,release=m.Scope:Override(row.Part,{Color=color,Material=Enum.Material.SmoothPlastic})
     row.Release=release;row.Color=color;table.insert(applied,row)
    end
   end
   return not restoring and cursor<=#list
  end)
  -- They flicker, faster while the search is stuck at 99%.
  local nextFlicker=0
  m:Every(function()
   if restoring then return false end
   local e,now=m:Elapsed(),os.clock()
   if now<nextFlicker or m.Reduced then return true end
   nextFlicker=now+(e>3.5 and .06 or .14)
   local odds=e>3.5 and .3 or .1
   for _,row in ipairs(applied)do
    if row.Part.Parent and math.random()<odds then
     row.Color=row.Color==MAGENTA and BLACK or MAGENTA;row.Part.Color=row.Color
    end
   end
   return true
  end)
 end

 -- 3.2: every screen blue-screens for half a second.
 if not m:Wait(CRASH)then return end
 if m:Fresh(CRASH,.25)then
  local screen=Instance.new('Frame');screen.Name='BlueScreen';screen.BorderSizePixel=0;screen.Size=UDim2.fromScale(1,1)
  screen.BackgroundColor3=BSOD;screen.ZIndex=60;screen.Parent=m.Mega.Overlay()
  m:Add(screen)
  local text=m.Mega.Label(screen,{Name='Crash',Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,
   Size=UDim2.fromScale(.8,.7),Position=UDim2.fromScale(.1,.15),ZIndex=61,
   Text=':(\n\nA fatal exception 404 has occurred at DOG:0095.\nThe current dog has been terminated.\n\n'..
    '*  Press any key to find the dog.\n*  Press CTRL+ALT+DEL to bark.\n\nCollecting dog info... 99%'})
  local limit=Instance.new('UITextSizeConstraint');limit.MaxTextSize=34;limit.Parent=text
  m:Cue('Static',nil,.45)
  m:Every(function(_,age)
   if not screen.Parent then return false end
   screen.Visible=age<.42 or (age>.47 and age<.53)
   if age<.6 then return true end
   screen:Destroy()
   return false
  end)
 end

 -- 4.0: 200 OK. The white sweep puts the world back as it reaches each player.
 if not m:Wait(FOUND)then return end
 found=true;restoring=true
 for _,s in ipairs(signs)do
  for _,l in ipairs(s.Labels)do
   l.TextColor3=GREEN;fade(l,0)
   l.Text=s==big and 'DOG FOUND' or '200 OK'
  end
 end
 if sky then sky.Release()end
 m:Tween(grade,.6,{Contrast=0,Saturation=0,Brightness=0,TintColor=Color3.new(1,1,1)})
 if m:Fresh(FOUND,.6)then
  m:Flash(WHITE,.4+.4*(1-m:Near(200)),.5)
 end
 -- (A late joiner gets the restored world, not a sweep starting from their join.)
 if m:Elapsed()<FOUND+2 then
  m:Shockwave(sweepFrom,WHITE,{Speed=320,Height=22,Thickness=1.4,Alpha=.2,Radius=m.Radius+500,OnPass=function()
   m:Flash(WHITE,.65,.3);m:Cue('Whoosh',nil,.35);m:Shake(.2,.25)
  end})
 end
 -- Restore in order of distance from the sweep's centre, as its front passes.
 for _,row in ipairs(applied)do
  local d=row.Part.Parent and row.Part.Position-sweepFrom or Vector3.zero
  row.R=Vector3.new(d.X,0,d.Z).Magnitude
 end
 table.sort(applied,function(a,b)return a.R<b.R end)
 local back=1
 m:Every(function()
  local front=(m:Elapsed()-FOUND)*320
  local n=0
  while back<=#applied and (applied[back].R<=front or m:Elapsed()>FOUND+3.5) and n<80 do
   applied[back].Release();back+=1;n+=1
  end
  return back<=#applied
 end)

 -- Loose pixels rain back into place around you; the banner.
 if not m:Wait(FOUND+.3)then return end
 if m:Fresh(FOUND+.3,1)then
  m:Fall({Count=30,Radius=110,Height=90,Gravity=70,Life=3.5,Spin=6,Spread=1.2,Make=function(i)
   local s=Kit.Random(.6,1.3)
   return m:Part({Name='Pixel',Size=Vector3.one*s,Color=i%3==0 and WHITE or i%3==1 and BLUE or GREEN,Transparency=1})
  end})
  m:Banner('404 DOG NOT FOUND',{Kicker='✦   2 0 0   O K   ·   D O G   F O U N D   ✦',Sub=m.VenueText..(m.By and ('  ·  '..string.upper(m.By))or''),
   Font=Enum.Font.Code,Color=BLUE,Hold=4.5,Shake=.1})
 end
 m:Wait(m.Config.MegaSeconds or 26)
end

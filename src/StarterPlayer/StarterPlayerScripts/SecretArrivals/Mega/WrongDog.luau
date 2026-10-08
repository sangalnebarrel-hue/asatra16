-- THE WRONG DOG, island-wide: "WRONG WORLD". The sky bleeds to a red dusk and, while the
-- dog's film skips at the stage, eyes open all over the sky dome round the island, one
-- after another, every pupil turning to follow THIS player's camera. Wrong copies of the
-- dog stand on the ground around you, always facing you; look straight at one and it is
-- gone (it comes back somewhere behind you). At 2.4 (its stare) every eye blinks at once,
-- a pulse of red rolls over the island and a colossal black silhouette of the dog hangs
-- upside down from the sky above the head until 5.6, when it is as if nothing happened:
-- the name comes up, every eye blinks once more at 6.15, and they close one by one.
-- Off the tongue the eyes flank the place it was opened.
local C=Color3.fromRGB
local BLOOD,EMBER,BLACK,SCLERA,LID=C(150,8,14),C(70,0,6),C(0,0,0),C(232,226,214),C(46,8,10)
local STARE,RELEASE,BLINK=2.4,5.6,6.15
local CLOSE=12 -- the eyes start closing; one more every 0.4 s
local function backOut(x)x=math.clamp(x,0,1)-1;local c=1.70158;return 1+(c+1)*x*x*x+c*x*x end
local function out3(x)x=math.clamp(x,0,1);return 1-(1-x)^3 end

return function(m)
 local Kit=m.Kit
 local low=m.Low
 local RED=m.Color
 local onTongue=m.Venue=='Tongue'
 local fresh=m.Late<.6
 -- Where it happens: the head on the tongue, the opened pad elsewhere.
 local focus=onTongue and m.Head or m:Ground(m.Origin)
 local floor=onTongue and m:Ground(m.Stage)or focus
 -- What the big set pieces face: the island (down the tongue), or its centre.
 local toward=Vector3.new(m.Center.X-focus.X,0,m.Center.Z-focus.Z)
 local facing=onTongue and Vector3.zAxis or (toward.Magnitude>40 and toward.Unit or Vector3.zAxis)
 local sideways=facing:Cross(Vector3.yAxis)

 -- A red dusk; the colour drains out of everything else.
 local sky=m:Sky({ClockTime=18.75,Brightness=1,Ambient=C(92,22,26),OutdoorAmbient=C(124,30,32),FogColor=C(84,8,12),FogStart=0,FogEnd=1300,
  ExposureCompensation=-.08},fresh and 1.6 or .3,3)
 local grade=m:Grade({TintColor=C(255,186,176),Saturation=-.45,Contrast=.22},fresh and .9 or .2,2.5)
 if fresh then m:Cue('Sting',nil,.3)end

 -- The eyes: a ring round the island at the height of the sky dome, and two great ones
 -- flanking the head. Each is a white, a red iris, a black pupil and a dark lid (shown
 -- whole for a blink and as it closes). Opening and closing are functions of time, so a
 -- late joiner sees exactly the eyes everyone else sees.
 local eyes={}
 local function eye(center,diameter,openAt,closeAt,phase)
  local function ball(name,color,neon)
   return m:Part({Name=name,Shape=Enum.PartType.Ball,Material=neon and Enum.Material.Neon or Enum.Material.SmoothPlastic,
    Color=color,Size=Vector3.one,Transparency=1,Position=center})
  end
  table.insert(eyes,{Center=center,D=diameter,Open=openAt,Close=closeAt,Phase=phase,
   White=ball('EyeWhite',SCLERA,false),Iris=ball('EyeIris',RED,true),Pupil=ball('EyePupil',BLACK,false),Lid=ball('EyeLid',LID,false)})
 end
 local ring=low and 10 or 20
 local order={}
 for i=1,ring do order[i]=i end
 for i=ring,2,-1 do local j=math.random(1,i);order[i],order[j]=order[j],order[i]end
 for i=1,ring do
  local a=(i-1)/ring*math.pi*2+Kit.Random(-.12,.12)
  local r=Kit.Random(430,560)
  local at=m.Center+Vector3.new(math.cos(a)*r,(i%3==0 and 330 or i%3==1 and 190 or 255)+Kit.Random(-25,25),math.sin(a)*r)
  -- They open while the film skips (0.4-2.0) and close in a shuffled order at the end.
  eye(at,Kit.Random(26,44),.4+(i-1)/ring*1.6,CLOSE+(order[i]-1)*.4,Kit.Random(0,10))
 end
 -- The two great eyes open with the dog's own red eyes in the dark (2.2).
 for _,s in ipairs({-1,1})do
  eye(focus+sideways*s*165+Vector3.new(0,onTongue and 95 or 120,0)+facing*20,78,2.2,CLOSE+ring*.4,Kit.Random(0,10))
 end
 m:Every(function()
  local e=m:Elapsed()
  local cam=m:Camera()
  -- Everyone blinks together at the stare and once more at 6.15.
  local together=(e>=STARE and e<STARE+.14)or(e>=BLINK and e<BLINK+.09)
  local dilate=(e>=STARE and e<RELEASE)and 1.45 or 1
  local alive=false
  for _,v in ipairs(eyes)do
   local open=e>=v.Open and backOut((e-v.Open)/.35)or 0
   local closing=math.clamp((e-v.Close)/.45,0,1)
   local shrink=1-out3((e-v.Close-.45)/.6)
   local s=open*shrink
   if s<=.02 or e<v.Open then
    v.White.Transparency=1;v.Iris.Transparency=1;v.Pupil.Transparency=1;v.Lid.Transparency=1
    if e<v.Close then alive=true end
   else
    alive=true
    local d=cam-v.Center
    d=d.Magnitude>1 and d.Unit or Vector3.zAxis
    local D=v.D*s
    -- The iris and pupil sit on the white's surface where it faces the camera.
    v.White.Size=Vector3.one*D;v.White.Position=v.Center
    v.Iris.Size=Vector3.one*D*.5;v.Iris.Position=v.Center+d*D*.3
    v.Pupil.Size=Vector3.one*D*.24*dilate;v.Pupil.Position=v.Center+d*D*.45
    v.Lid.Size=Vector3.one*D*1.04;v.Lid.Position=v.Center
    -- An idle blink of its own now and then, while open and not closing.
    local idle=closing==0 and e>v.Open+.5 and (e*.37+v.Phase)%4.3<.12
    local shut=together or idle or closing>0
    v.White.Transparency=0;v.Iris.Transparency=0;v.Pupil.Transparency=0
    v.Lid.Transparency=shut and 0 or 1
   end
  end
  if alive then return true end
  for _,v in ipairs(eyes)do for _,p in ipairs({v.White,v.Iris,v.Pupil,v.Lid})do p:Destroy()end end
  return false
 end)

 -- The wrong copies: ordinary-sized, standing on the ground around you, always facing you.
 -- Looked at straight, one is gone with a glitch; it comes back somewhere behind you (twice).
 local copies={}
 if m.Late<9 then
  local function spot(behind)
   local cam=m:CameraCFrame()
   local character=game:GetService('Players').LocalPlayer.Character
   local root=character and character:FindFirstChild('HumanoidRootPart')
   local from=root and root:IsA('BasePart')and root.Position or cam.Position
   local look=Vector3.new(cam.LookVector.X,0,cam.LookVector.Z)
   look=look.Magnitude>.01 and look.Unit or Vector3.zAxis
   local a=behind and math.rad(Kit.Random(110,250))or Kit.Random(0,math.pi*2)
   local dir=CFrame.fromAxisAngle(Vector3.yAxis,a):VectorToWorldSpace(look)
   return m:Ground(from+dir*Kit.Random(50,90))
  end
  for i=1,low and 3 or 5 do
   local handle=m:SkyDog(9,{Clip='EXP_Stare'})
   if handle then
    handle:SetAlpha(0)
    table.insert(copies,{Handle=handle,At=nil,Due=.8+(i-1)*.3,Shown=0,Respawns=0,Ever=false})
   end
  end
 end
 if #copies>0 then
  m:Every(function()
   local e=m:Elapsed()
   local cam=m:CameraCFrame()
   local any=false
   for _,c in ipairs(copies)do
    if e>=11 then
     -- Gone for good (destroying the clone also stops its clip).
     if c.Handle.Model.Parent then c.Handle.Model:Destroy()end
     c.At=nil
    else
     any=true
     if not c.At and c.Due and e>=c.Due then
      c.At=spot(c.Ever);c.Ever=true;c.Shown=os.clock();c.Due=nil
     end
     if c.At then
      c.Handle:Place(c.At,cam.Position-c.At)
      -- It flickers into being over a couple of frames, a film splice.
      local age=os.clock()-c.Shown
      c.Handle:SetAlpha((age<.05 or (age>.1 and age<.16) or age>.2)and 1 or 0)
      local to=c.At+Vector3.new(0,4.5,0)-cam.Position
      if age>.4 and to.Magnitude<170 and cam.LookVector:Dot(to.Unit)>.97 then
       c.Handle:SetAlpha(0);c.At=nil
       m:Cue('Glitch',nil,.22)
       if c.Respawns<2 and e<9.5 then c.Respawns+=1;c.Due=e+1.6 end
      end
     end
    end
   end
   return any
  end)
 end

 -- The silhouette is made now (a big clone takes a moment) and stays hidden until the stare.
 local giant=m.Late<RELEASE and m:SkyDog(220,{Clip='UnstableEvent',Fill=BLACK,Outline=RED,FillAlpha=0})or nil
 if giant then giant:SetAlpha(0)end
 local hang=focus+Vector3.new(0,onTongue and 430 or 400,0)

 if not m:Wait(STARE)then return end
 -- It is looking at you. Every eye blinks; a red pulse rolls out over the island.
 if m:Fresh(STARE,.6)then
  m:Shockwave(floor,BLOOD,{Speed=300,Height=40,Thickness=1.6,Alpha=.35,Radius=m.Radius+500,OnPass=function()
   m:Cue('Heartbeat',nil,.8);m:Flash(C(120,0,6),.6,.5);m:Shake(.25,.35)
  end})
  m:Cue('Static',nil,.25)
 end
 local wash=m:Tint(EMBER,.86,.4)
 -- Far from the stage the heart is ours to keep (the stage's own heartbeat is local there).
 task.spawn(function()
  local t=STARE+.8
  while t<RELEASE-.2 do
   if not m:Wait(t)then return end
   if m:Fresh(t,.2)and m:Near(160)<.3 then m:Cue('Heartbeat',nil,.5)end
   t+=.8
  end
 end)
 if giant then
  local shownAt=os.clock()
  m:Every(function()
   local e=m:Elapsed()
   local age=os.clock()-shownAt
   local frame=CFrame.lookAt(hang,hang+facing)*CFrame.Angles(.05*math.sin(age*.7),0,math.pi+.04*math.sin(age*.5))
   giant:Pivot(frame*CFrame.new(-giant.Ground))
   -- Spliced in, held, spliced out at 5.6.
   local out=e-RELEASE
   local on
   if out<0 then on=age<.06 or (age>.12 and age<.18) or age>.24
   else on=(out>.08 and out<.14)end
   giant:SetAlpha(on and 1 or 0)
   if out>.3 then giant.Model:Destroy();return false end
   return true
  end)
 end

 -- 5.6: as if nothing happened. The name, for the whole island.
 if not m:Wait(RELEASE)then return end
 m:Tween(wash,.6,{BackgroundTransparency=1})
 if m:Fresh(RELEASE,1)then
  m:Banner('THE WRONG DOG',{Kicker='✦   I T   I S   L O O K I N G   A T   Y O U   ✦',Sub=m.VenueText..(m.By and ('  ·  '..string.upper(m.By))or''),
   Font=Enum.Font.Garamond,Color=RED,Glitch=true,Hold=4.5})
 end

 -- The eyes close one by one; the dusk lifts as the dog walks.
 if not m:Wait(16)then return end
 if sky then sky.Release()end
 m:Tween(grade,2.5,{TintColor=Color3.new(1,1,1),Saturation=0,Contrast=0})
 m:Wait(m.Config.MegaSeconds or 26)
end

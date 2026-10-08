-- DOGDOGDOGDOG, island-wide: "THE PACK". The sky turns warm gold and eight golden pillars
-- punch up around the island's horizon, one after another. At 1.2 (when the pups land on the
-- stage) eight colossal ghosts of the dog rise out of them and march round the island in
-- unison; with the typed roll call each is counted off with a giant number over its head,
-- up the scale. At 3.5 (Reassemble) they all leap for the giant head, "DOG" signs pop all
-- over the sky, and at 4.7 (one dog) they land as one gigantic dog on the roof: a gold wall
-- of light rolls across the island and confetti rains on every player. When the last line
-- says "now there are eight", the giant flickers into eight again, then fades away.
-- Off the tongue the pack circles the pad where it was opened and merges above it.
local C=Color3.fromRGB
local GOLD,DEEP,CREAM,WHITE=C(255,196,64),C(222,128,16),C(255,226,150),C(255,255,255)
local TICK='rbxasset://sounds/volume_slider.ogg'
-- One note per pup: a major scale up to the octave (as on the stage).
local SCALE={1,9/8,5/4,4/3,3/2,5/3,15/8,2}
local TYPE=.055
local POP,RISE,REASSEMBLE,ONE,HAPPY=.4,1.2,3.5,4.7,5.6
local LEAP=1.1
local WORDS={'DOG','DOG!','dog','DOG?','DOGS','DOG DOG','D O G','DOG.','dog dog','DOG!!'}
local function smooth(x)x=math.clamp(x,0,1);return x*x*(3-2*x)end
local function out3(x)x=math.clamp(x,0,1);return 1-(1-x)^3 end
local function backOut(x)x=math.clamp(x,0,1);local c=1.70158;x-=1;return 1+(c+1)*x*x*x+c*x*x end

return function(m)
 local low=m.Low
 local Kit=m.Kit
 local config=m.Config
 local onTongue=m.Venue=='Tongue'
 -- Roll call and the last line, on the stage's typewriter clock.
 local lines=config.Whispers or {}
 local call=lines[1]and lines[1][1]or 1.6
 local tail=lines[#lines]
 local typed=tail and tail[1]+(utf8.len(tail[2])or #tail[2])*TYPE or config.Hold+1
 local BLINKS=m.Reduced and {0,.37}or {0,.08,.15,.37}
 -- The ring the pack marches on, and the giant one's feet (on the head's roof, facing the
 -- island; or over the pad, facing the island's middle).
 local center=onTongue and m.Center or m:Ground(m.Origin)
 local R=onTongue and 520 or 360
 local feetY=center.Y+14
 local merge=onTongue and m.Head+Vector3.new(0,2,-8)or m:Ground(m.Origin)+Vector3.new(0,24,0)
 local front=Vector3.zAxis
 if not onTongue then
  local d=Vector3.new(m.Center.X-merge.X,0,m.Center.Z-merge.Z)
  if d.Magnitude>10 then front=d.Unit end
 end
 local function pip(speed,volume)
  local s=Instance.new('Sound');s.SoundId=TICK;s.Volume=volume;s.PlaybackSpeed=speed
  local r=Instance.new('ReverbSoundEffect');r.DecayTime=2.4;r.WetLevel=-2;r.DryLevel=0;r.Parent=s
  s.Parent=game:GetService('SoundService');m:Add(s);s:Play()
  task.delay(4,function()if s.Parent then s:Destroy()end end)
 end

 local sky=m:Sky({Ambient=C(150,124,80),OutdoorAmbient=C(205,170,110),ExposureCompensation=.08,FogColor=C(255,224,160),FogStart=0,FogEnd=2600},1.2,4)
 local grade=m:Grade({TintColor=C(255,242,214),Saturation=.12,Contrast=.08},.8,3)

 -- The pack: eight ghosts (three on low), each on its own spot of the ring.
 local N=low and 3 or 8
 local OMEGA=.12
 local pack={}
 for i=1,N do
  local dog=m:SkyDog(low and 150 or 130,{Clip='Walk',Speed=1.4})
  if dog then
   dog:SetAlpha(0)
   pack[#pack+1]={Dog=dog,Index=i,Angle=(i-.5)/N*math.pi*2-math.pi/2,Shown=0}
  end
 end
 local giant=m:SkyDog(low and 200 or 250,{Clip='Idle',Fill=GOLD,Outline=CREAM,FillAlpha=.72})
 if giant then giant:SetAlpha(0)end
 local function ringAt(angle)return center+Vector3.new(math.cos(angle)*R,feetY-center.Y,math.sin(angle)*R)end
 local function marchAngle(row,t)return row.Angle+OMEGA*math.clamp(t-RISE,0,REASSEMBLE-RISE)end
 -- Giant roll-call numbers, one over each ghost (eight only: low counts nothing).
 local numbers={}
 if N==8 then
  for i,row in ipairs(pack)do
   local sign,labels=m:Text3D(tostring(row.Index),CFrame.new(ringAt(row.Angle)),Vector2.new(48,48),
    {Font=Enum.Font.LuckiestGuy,Color=WHITE,StrokeColor=DEEP,StrokeThickness=6})
   numbers[i]={Part=sign,Labels=labels,Index=row.Index,At=call+(4*row.Index-1)*TYPE}
   for _,l in ipairs(labels)do l.TextTransparency=1 end
  end
 end

 m:Every(function()
  local t=m:Elapsed()
  local cam=m:Camera()
  local blink=-1
  for k,at in ipairs(BLINKS)do if t>=typed-.25+at then blink=k end end
  local blinking=blink>=1 and t<typed-.25+BLINKS[#BLINKS]+.12
  for _,row in ipairs(pack)do
   local dog=row.Dog
   local alpha,feet,look=0,nil,nil
   if t<REASSEMBLE then
    local u=math.clamp((t-RISE-.05*row.Index)/.7,0,1)
    local a=marchAngle(row,t)
    feet=ringAt(a)-Vector3.new(0,90*(1-out3(u)),0)
    look=Vector3.new(-math.sin(a),0,math.cos(a))
    alpha=.9*smooth(u)
   elseif t<REASSEMBLE+LEAP then
    -- The leap: a high arc from its place on the ring onto the giant's feet.
    local k=(t-REASSEMBLE)/LEAP
    local from=ringAt(marchAngle(row,REASSEMBLE))
    feet=from:Lerp(merge,smooth(k))+Vector3.new(0,math.sin(math.pi*k)*260,0)
    look=merge-from
    alpha=.9*(1-smooth((k-.7)/.3))
   elseif blinking then
    -- "...now there are eight": for a blink, all of them stand round the giant again.
    local a=(row.Index-.5)/N*math.pi*2
    feet=merge+Vector3.new(math.cos(a)*170,0,math.sin(a)*170)
    look=Vector3.new(math.cos(a),0,math.sin(a))
    alpha=blink%2==1 and .8 or 0
   end
   if feet then dog:Place(feet,look)end
   if math.abs(alpha-row.Shown)>.01 then row.Shown=alpha;dog:SetAlpha(alpha)end
  end
  if giant then
   local a=0
   local rise=smooth((t-(REASSEMBLE+LEAP*.7))/.5)
   if t>=REASSEMBLE+LEAP*.7 then
    a=rise*(1-smooth((t-15)/3))
    if blinking then a=blink%2==1 and 0 or a end
   end
   giant:Place(merge-Vector3.new(0,60*(1-out3(rise))+40*smooth((t-15)/3),0),front)
   if math.abs(a-giant.Alpha)>.01 then giant:SetAlpha(a)end
  end
  for i,n in ipairs(numbers)do
   local row=pack[i]
   local pop=math.clamp((t-n.At)/.3,0,1)
   local gone=math.clamp((t-REASSEMBLE)/.4,0,1)
   local s=48*math.max(backOut(pop),.02)
   local at=ringAt(marchAngle(row,math.min(t,REASSEMBLE)))+Vector3.new(0,(low and 150 or 130)+40,0)
   n.Part.Size=Vector3.new(s,s,.2);n.Part.CFrame=CFrame.lookAt(at,cam)
   local alpha=pop>0 and gone or 1
   for _,l in ipairs(n.Labels)do l.TextTransparency=alpha end
  end
  if t>18.5 then return false end
  return true
 end)

 -- 0.4: the pillars punch up round the horizon, one by one.
 if not m:Wait(POP)then return end
 if m:Elapsed()<RISE then
  for i,row in ipairs(pack)do
   task.delay((i-1)*.06,function()
    if not m:Alive()then return end
    local at=ringAt(row.Angle)
    m:Pillar(Vector3.new(at.X,center.Y-10,at.Z),440,GOLD,24,2.4)
    m:Ring(Vector3.new(at.X,center.Y+2,at.Z),CREAM,6,80,.8,{Thickness=2,Alpha=.3,Segments=12})
    pip(.9+i*.08,.18)
   end)
  end
 end
 -- 1.2: they rise out of the light.
 if not m:Wait(RISE)then return end
 if m:Fresh(RISE,.5)then m:Cue('Rumble',nil,.45,1.5);m:Cue('Whoosh',nil,.4)end
 -- Roll call: one giant number and one note per ghost, in step with the typed words.
 for _,n in ipairs(numbers)do
  if not m:Wait(n.At)then return end
  if m:Fresh(n.At,.15)then pip(1.25*SCALE[n.Index],.3)end
 end

 -- 3.5: they leap for the head; DOG signs pop all over the sky.
 if not m:Wait(REASSEMBLE)then return end
 if m:Fresh(REASSEMBLE,.5)then m:Cue('Whoosh',nil,.6)end
 if m:Elapsed()<ONE then
  local count=low and 4 or 10
  for k=1,count do
   task.delay((k-1)*.13,function()
    if not m:Alive()then return end
    local a=Kit.Random(0,math.pi*2);local r=Kit.Random(180,R*.95)
    local at=center+Vector3.new(math.cos(a)*r,Kit.Random(120,300),math.sin(a)*r)
    local sign,labels=m:Text3D(WORDS[(k-1)%#WORDS+1],CFrame.new(at),Vector2.new(96,40),
     {Font=Enum.Font.LuckiestGuy,Color=k%3==0 and WHITE or (k%2==0 and GOLD or CREAM),StrokeColor=DEEP,StrokeThickness=5})
    local born=os.clock()
    pip(1.6+k*.09,.12)
    m:Every(function()
     local age=os.clock()-born
     local s=math.max(backOut(age/.3),.02)
     sign.Size=Vector3.new(96*s,40*s,.2);sign.CFrame=CFrame.lookAt(at+Vector3.new(0,age*6,0),m:Camera())
     local fade=math.clamp((age-2.2)/.5,0,1)
     for _,l in ipairs(labels)do l.TextTransparency=fade end
     if fade>=1 then sign:Destroy();return false end
     return true
    end)
   end)
  end
 end

 -- 4.7: one dog.
 if not m:Wait(ONE)then return end
 local ground=Vector3.new(merge.X,onTongue and 0 or merge.Y-24,merge.Z)
 if m:Fresh(ONE,.6)then
  m:Cue('Boom',nil,.55);m:Cue('Chime',nil,.6)
  m:Flash(C(255,232,160),.55,.5)
  grade.Brightness=.16;m:Tween(grade,.8,{Brightness=0})
  m:Banner('DOGDOGDOGDOG',{Kicker='✦   D O G   D O G   D O G   D O G   ✦',Sub=m.VenueText..(m.By and ('  ·  '..string.upper(m.By))or''),
   Font=Enum.Font.LuckiestGuy,Color=GOLD,Hold=4.6,Shake=.2})
  m:Ring(merge+Vector3.new(0,6,0),GOLD,10,260,1.1,{Thickness=3,Alpha=.25,Segments=48})
 end
 m:Shockwave(ground,GOLD,{Speed=320,Height=20,Thickness=1.4,Alpha=.2,OnPass=function()
  m:Shake(.38,.45);m:FOV(-4,.06,.6);m:Cue('Impact',nil,.5);m:Flash(C(255,236,180),.78,.3)
 end})
 -- Confetti over every player: gold, cream and white flakes and little pup blocks.
 if m:Elapsed()<ONE+3 then
  m:Fall({Count=low and 30 or 70,Radius=140,Height=110,Gravity=26,Drag=1.4,Life=7,Spin=9,Spread=2.4,Bounce=false,
   Make=function(i)
    local block=i%6==0
    local color=i%5<2 and WHITE or (i%2==0 and GOLD or CREAM)
    return m:Part({Name=block and 'PupBlock'or 'Confetti',Color=block and DEEP or color,Transparency=1,
     Material=block and Enum.Material.SmoothPlastic or Enum.Material.Neon,
     Size=block and Vector3.new(1.4,1.4,2)or Vector3.new(1.6,.18,1)})
   end})
 end
 -- 5.6: Happy, like the dog on the stage.
 if not m:Wait(HAPPY)then return end
 if giant then giant:Play('Happy',false)end
 if not m:Wait(HAPPY+1.6)then return end
 if giant then giant:Play('Idle',true)end
 -- "...now there are eight."
 if not m:Wait(typed-.25)then return end
 if m:Fresh(typed-.25,.4)then m:Cue('Glitch',nil,.3)end
 if not m:Wait(15)then return end
 if sky then sky.Release()end
 m:Tween(grade,3,{TintColor=WHITE,Saturation=0,Contrast=0})
 m:Wait(config.MegaSeconds or 26)
end

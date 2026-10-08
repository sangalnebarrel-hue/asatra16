-- SPIDERDOG, island-wide: "THE WEB". The island's sky goes dark and eight orange eyes open
-- high above it. Silk is shot from that knot of eyes to anchors all round the island's rim,
-- strand by strand, and while the dog drops in on its line (0.7) a spiral is spun across the
-- whole sky, the web slowly turning. Eight colossal legs reach up over the horizon; when the
-- dog lands (2.85) a dust wave rolls over the island, and on its eight digging kicks (2.9,
-- every 0.1 s) the legs slam down one after another at the island's edge, each one a jolt
-- for every player (harder the closer it hits). Spiderlings drop on threads around every
-- player and dangle there. Then the web snaps strand by strand and dissolves into orange
-- sparks, the eyes close and the legs sink back below the horizon.
-- Off the tongue the web is spun over the pad where it was opened.
local C=Color3.fromRGB
local SILK,EMBER,DUST,DARK,LEG=C(244,240,236),C(255,214,170),C(150,128,104),C(26,16,12),C(40,26,20)
local TICK='rbxasset://sounds/volume_slider.ogg'
local DROP,LAND,DIG=.7,2.85,2.9
local TEAR=13
-- The legs in slam order: across the island and back, like the dog's own kicks.
local ORDER={1,5,2,6,3,7,4,8}
-- Eight eyes under the knot: across, down, diameter (the big pair opens first).
local EYES={{-.42,1.15,.62},{.42,1.15,.62},{-1.2,.95,.38},{1.2,.95,.38},{-.72,.45,.32},{.72,.45,.32},{-1.45,.3,.24},{1.45,.3,.24}}
local function smooth(x)x=math.clamp(x,0,1);return x*x*(3-2*x)end
local function out3(x)x=math.clamp(x,0,1);return 1-(1-x)^3 end
local function backOut(x)x=math.clamp(x,0,1);local c=1.70158;x-=1;return 1+(c+1)*x*x*x+c*x*x end

return function(m)
 local low=m.Low
 local Kit=m.Kit
 local ORANGE=m.Color
 local onTongue=m.Venue=='Tongue'
 -- The web covers the head and the yards (on the tongue) or the pad's neighbourhood.
 local center=onTongue and Vector3.new(0,0,140)or m:Ground(m.Origin)
 local R=onTongue and 600 or 440
 local hub=center+Vector3.new(0,onTongue and 420 or 330,0)
 local facing=onTongue and Vector3.zAxis or Vector3.new(m.Center.X-center.X,0,m.Center.Z-center.Z)
 if facing.Magnitude<1 then facing=Vector3.zAxis end
 facing=facing.Unit
 local right=Vector3.yAxis:Cross(facing).Unit
 local function thud(volume,speed)
  local s=Instance.new('Sound');s.SoundId=TICK;s.Volume=volume;s.PlaybackSpeed=speed or .3
  local q=Instance.new('EqualizerSoundEffect');q.LowGain=10;q.MidGain=-8;q.HighGain=-34;q.Parent=s
  local r=Instance.new('ReverbSoundEffect');r.DecayTime=2.5;r.WetLevel=-3;r.Parent=s
  s.Parent=game:GetService('SoundService');m:Add(s);s:Play()
  task.delay(4,function()if s.Parent then s:Destroy()end end)
 end

 local sky=m:Sky({Brightness=.9,Ambient=C(44,34,36),OutdoorAmbient=C(64,50,52),ExposureCompensation=-.3,FogColor=C(40,28,26),FogStart=0,FogEnd=1500},1.2,3)
 local grade=m:Grade({TintColor=C(255,236,222),Saturation=-.32,Contrast=.16,Brightness=-.05},.9,3)
 if m:Fresh(0,.5)then m:Cue('Whoosh',nil,.35);m:Cue('Rumble',nil,.4,2)end

 -- The web: radial strands from the knot to the rim, then one long spiral across them.
 local web=m:Model('SkyWeb')
 local SPOKES=low and 8 or 12
 local TURNS=low and 3 or 5
 local SEGMENTS=SPOKES*TURNS
 local rim={}
 for s=1,SPOKES do
  local a=(s-1)/SPOKES*math.pi*2
  rim[s]=m:Ground(center+Vector3.new(math.cos(a)*R,0,math.sin(a)*R)).Y+30
 end
 local threads={}
 local wide=onTongue and 1 or .8
 for s=1,SPOKES do
  table.insert(threads,{Part=m:Line(hub,hub+Vector3.yAxis,SILK,2.4*wide,{Transparency=1,Parent=web}),Spoke=s,At=.2+.06*(s-1),Grow=.25,
   Tear=TEAR+Kit.Random(0,.9)})
 end
 for k=0,SEGMENTS-1 do
  table.insert(threads,{Part=m:Line(hub,hub+Vector3.yAxis,SILK,1.6*wide,{Transparency=1,Parent=web}),Seg=k,At=1.2+1.3*k/SEGMENTS,Grow=.1,
   Tear=TEAR+Kit.Random(0,.9)})
 end
 local function spin(t)return .03*t end
 local function rimAt(s,t)
  local a=(s-1)/SPOKES*math.pi*2+spin(t)
  return Vector3.new(center.X+math.cos(a)*R,rim[(s-1)%SPOKES+1],center.Z+math.sin(a)*R)
 end
 local function spiral(k,t)
  local s=k%SPOKES+1
  local f=.9-.7*k/SEGMENTS
  return hub:Lerp(rimAt(s,t),f)
 end
 local sparked={}
 m:Every(function()
  local t=m:Elapsed()
  for i,th in ipairs(threads)do
   local a,b
   if th.Spoke then a,b=hub,rimAt(th.Spoke,t)else a,b=spiral(th.Seg,t),spiral(th.Seg+1,t)end
   local grow=math.clamp((t-th.At)/th.Grow,0,1)
   local p=th.Part
   if grow<=0 then p.Transparency=1
   elseif t<th.Tear then
    m:SetLine(p,a,a:Lerp(b,grow))
    p.Transparency=.3
   else
    -- Torn: it falls away and burns out in sparks.
    local age=t-th.Tear
    local drop=Vector3.new(0,90*age*age,0)
    m:SetLine(p,a-drop*.6,b-drop)
    p.Color=SILK:Lerp(ORANGE,math.clamp(age*3,0,1))
    p.Transparency=.3+.7*math.clamp(age/.8,0,1)
    if not sparked[i]and th.Spoke then
     sparked[i]=true
     m:Burst(a:Lerp(b,Kit.Random(.3,.8)),ORANGE,low and 10 or 24,{Speed=NumberRange.new(10,30),Lifetime=NumberRange.new(.8,1.6),
      Size=NumberSequence.new(2.4,0),Acceleration=Vector3.new(0,-25,0)})
    end
   end
  end
  if t>TEAR+2 then web:Destroy();return false end
  return true
 end)

 -- The eyes in the knot, opening one pair after another (the big pair first).
 local eyes={}
 local EYE=onTongue and 52 or 40
 for i,e in ipairs(EYES)do
  eyes[i]=m:Ball({Name='SkyEye',Color=ORANGE,Size=Vector3.one,Transparency=1,
   Position=hub+right*e[1]*EYE-Vector3.yAxis*(EYE*1.5-e[2]*EYE)+facing*EYE*.4})
 end
 m:Every(function()
  local t=m:Elapsed()
  local shut=math.clamp((t-(TEAR-.3))/.3,0,1)
  for i,p in ipairs(eyes)do
   local open=backOut((t-.2-math.floor((i-1)/2)*.12)/.3)
   local d=EYES[i][3]*EYE*math.max(open,0)*(1-shut)
   -- A slow throb; they flare on the landing.
   local flare=t>=LAND and math.max(0,1-(t-LAND)/.5)or 0
   p.Size=Vector3.one*d*(1+.08*math.sin(t*3+i)+.35*flare)
   p.Color=ORANGE:Lerp(EMBER,flare)
   p.Transparency=d>.05 and .05 or 1
  end
  if shut>=1 then for _,p in ipairs(eyes)do p:Destroy()end;return false end
  return true
 end)

 -- Eight colossal legs reach up over the horizon, then slam down at the island's edge.
 local legs={}
 for i=1,8 do
  local b=(i-.5)/8*math.pi*2
  local out=Vector3.new(math.cos(b),0,math.sin(b))
  local foot=m:Ground(center+out*R*.92)
  local slamAt=DIG+(table.find(ORDER,i)-1)*.1
  legs[i]={Out=out,Foot=foot,Hip=center+out*R*1.55+Vector3.new(0,-60,0),Knee=center+out*R*1.18+Vector3.new(0,onTongue and 360 or 290,0),
   Rise=DROP+(i-1)*.12,Slam=slamAt,Landed=false,
   Upper=m:Line(Vector3.zero,Vector3.yAxis,LEG,16,{Material=Enum.Material.SmoothPlastic,Transparency=1}),
   Lower=m:Line(Vector3.zero,Vector3.yAxis,LEG,11,{Material=Enum.Material.SmoothPlastic,Transparency=1}),
   Claw=m:Line(Vector3.zero,Vector3.yAxis,DARK,6,{Material=Enum.Material.SmoothPlastic,Transparency=1}),
   Joint=m:Ball({Name='LegJoint',Color=LEG,Material=Enum.Material.SmoothPlastic,Size=Vector3.one*22,Transparency=1}),
   Glow=m:Ball({Name='LegGlow',Color=ORANGE,Size=Vector3.one*9,Transparency=1})}
 end
 m:Every(function()
  local t=m:Elapsed()
  local cam=m:Camera()
  for _,l in ipairs(legs)do
   local rise=out3((t-l.Rise)/.9)
   local sink=smooth((t-TEAR)/1.6)
   local up=rise*(1-sink)
   local knee=l.Knee-Vector3.new(0,(1-up)*520,0)
   -- Raised and reaching until its slam; planted after; lifting off as it sinks away.
   local raised=l.Foot+l.Out*R*.06+Vector3.new(0,210,0)
   local foot
   if t<l.Slam then foot=raised
   elseif t<l.Slam+.14 then local u=(t-l.Slam)/.14;foot=raised:Lerp(l.Foot,u*u)
   else foot=l.Foot:Lerp(raised,sink)end
   foot-=Vector3.new(0,(1-up)*520,0)
   local tip=foot-l.Out*14-Vector3.new(0,6,0)
   m:SetLine(l.Upper,l.Hip,knee);m:SetLine(l.Lower,knee,foot);m:SetLine(l.Claw,foot,tip)
   l.Joint.Position=knee;l.Glow.Position=knee+(cam-knee).Unit*10
   local shown=up>.01 and 0 or 1
   l.Upper.Transparency=shown;l.Lower.Transparency=shown;l.Claw.Transparency=shown;l.Joint.Transparency=shown
   l.Glow.Transparency=up>.01 and .1+.6*(.5+.5*math.sin(t*5)) or 1
   if not l.Landed and t>=l.Slam+.14 then
    l.Landed=true
    if m:Fresh(l.Slam+.14,.25)then
     local close=math.clamp(1-(cam-l.Foot).Magnitude/700,0,1)
     m:Shake(.12+.3*close,.28);thud(.2+.45*close,.28+Kit.Random(-.03,.03))
     m:Ring(l.Foot+Vector3.new(0,2,0),DUST,8,90,.7,{Thickness=3,Alpha=.35,Segments=12})
     m:Burst(l.Foot+Vector3.new(0,4,0),DUST,low and 8 or 18,{Texture=Kit.Textures.Smoke,LightEmission=.05,Drag=3,
      Speed=NumberRange.new(20,45),SpreadAngle=Vector2.new(70,70),Lifetime=NumberRange.new(1,1.8),Size=NumberSequence.new(10,26),
      Transparency=NumberSequence.new(.4,1)})
    end
   end
  end
  if t>TEAR+1.8 then for _,l in ipairs(legs)do for _,k in ipairs({'Upper','Lower','Claw','Joint','Glow'})do l[k]:Destroy()end end;return false end
  return true
 end)

 -- 2.85: it lands. A dust wave rolls over the island; the banner.
 if not m:Wait(LAND)then return end
 if m:Fresh(LAND,.5)then
  m:Cue('Impact',nil,.7);m:Cue('Sting',nil,.4)
  m:Flash(EMBER,.8,.35)
  m:Banner('SPIDERDOG',{Kicker='✦   T H E   W E B   ✦',Sub=m.VenueText..(m.By and ('  ·  '..string.upper(m.By))or''),
   Font=Enum.Font.Creepster,Color=ORANGE,Hold=4.8,Shake=.2})
 end
 local stage=onTongue and m.Stage or m:Ground(m.Origin)
 m:Shockwave(Vector3.new(stage.X,stage.Y,stage.Z),DUST,{Speed=280,Height=12,Thickness=1.2,Alpha=.3,Segments=40,OnPass=function()
  m:Shake(.22,.4);m:Cue('Rumble',nil,.5,1.2)
 end})

 -- 3.4: spiderlings drop on their threads all round this player, and dangle.
 if not m:Wait(3.4)then return end
 if m:Elapsed()<TEAR-1 then
  local around=m:Camera()
  local count=low and 4 or 10
  for i=1,count do
   local a=Kit.Random(0,math.pi*2);local r=Kit.Random(18,70)
   local x,z=around.X+math.cos(a)*r,around.Z+math.sin(a)*r
   local floor=m:Ground(Vector3.new(x,around.Y,z)).Y
   local top=Vector3.new(x,math.max(around.Y,floor)+80,z)
   local rest=Vector3.new(x,floor+Kit.Random(7,22),z)
   local size=Kit.Random(2.6,4.2)
   local thread=m:Line(top,top-Vector3.yAxis,SILK,.25,{Transparency=.35})
   local body=m:Ball({Name='Spiderling',Color=DARK,Material=Enum.Material.SmoothPlastic,Size=Vector3.one*size,Position=top})
   local glint=m:Part({Name='SpiderlingEyes',Color=ORANGE,Size=Vector3.new(size*.5,size*.16,size*.16),Position=top})
   local delay=Kit.Random(0,1.2);local fall=Kit.Random(1.1,1.8);local phase=Kit.Random(0,6)
   local born=os.clock()
   m:Every(function()
    local age=os.clock()-born-delay
    local t=m:Elapsed()
    local climb=smooth((t-(TEAR-1))/1)
    local down=out3(age/fall)*(1-climb)
    local sway=Vector3.new(math.sin(age*1.7+phase),0,math.cos(age*1.3+phase))*1.6*down
    local at=top:Lerp(rest,down)+sway+Vector3.new(0,math.sin(age*2.2+phase)*.8*down,0)
    if age<0 then at=top end
    m:SetLine(thread,top,at+Vector3.new(0,size*.5,0))
    body.Position=at
    local view=m:Camera()-at
    view=Vector3.new(view.X,0,view.Z)
    view=view.Magnitude>.1 and view.Unit or Vector3.zAxis
    -- Its eye bar faces you, long side across.
    glint.CFrame=CFrame.lookAt(at+view*size*.42+Vector3.new(0,size*.12,0),at+view*size)
    local hide=age<0 and 1 or math.clamp((t-(TEAR-.2))/.4,0,1)
    thread.Transparency=.35+.65*hide;body.Transparency=hide;glint.Transparency=hide
    if hide>=1 and t>TEAR then thread:Destroy();body:Destroy();glint:Destroy();return false end
    return true
   end)
  end
 end

 -- 13: the web snaps (its stepper tears and burns each strand); the sky comes back.
 if not m:Wait(TEAR)then return end
 if m:Fresh(TEAR,.6)then
  for k=0,5 do task.delay(k*.09,function()if m:Alive()then thud(.12,3.6+k*.25)end end)end
  m:Cue('Whoosh',nil,.4)
 end
 if sky then sky.Release()end
 m:Tween(grade,2.5,{TintColor=Color3.new(1,1,1),Saturation=0,Contrast=0,Brightness=0})
 m:Wait(m.Config.MegaSeconds or 26)
end

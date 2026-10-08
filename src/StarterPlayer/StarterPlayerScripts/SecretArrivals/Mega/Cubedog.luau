-- CUBEDOG, island-wide: "THE GRID". The sky cools to cyan and a colossal wireframe cube draws
-- itself edge by edge around the island (~700-stud edges, glowing corner nodes). On the
-- pug-sized cube's own beats (0.8, 1.2, 1.6) the giant one snaps through the same three hard
-- quarter-turns, each a small jolt for every player; at 1.8 it tightens, and at 2.3 (LAND) it
-- slams down onto the landing square: a cyan wall of light rolls across the island, a holo
-- grid sweeps out over the ground from the stage and voxel cubes rain and bounce around every
-- player. The cube re-forms small and hovers over the head, tumbling, until the grid fades.
-- Off the tongue the cube closes around the pad where it was opened.
local C=Color3.fromRGB
local WHITE,DEEP=C(236,251,255),C(40,130,255)
local SNAPS={{.8,Vector3.xAxis},{1.2,Vector3.yAxis},{1.6,Vector3.zAxis}}
local SNAP,DROP,LAND=.14,2,2.3
local REFORM=3.3
local function backOut(x)x=math.clamp(x,0,1);local c=1.70158;x-=1;return 1+(c+1)*x*x*x+c*x*x end
local function smooth(x)x=math.clamp(x,0,1);return x*x*(3-2*x)end
local function out3(x)x=math.clamp(x,0,1);return 1-(1-x)^3 end

return function(m)
 local low=m.Low
 local CYAN=m.Color
 local onTongue=m.Venue=='Tongue'
 -- Where it lands (the belt, or the pad) and where the giant cube stands: around the island
 -- on the tongue (the head inside its back face), around the pad off it.
 local land=onTongue and m.Stage or m:Ground(m.Origin)
 local half=onTongue and 350 or 260
 local home=onTongue and Vector3.new(0,half-40,120) or land+Vector3.new(0,half-30,0)
 -- The hologram it re-forms into: over the giant head, or over the pad.
 local hover=onTongue and m.Head+Vector3.new(0,140,40) or land+Vector3.new(0,120,0)
 local SMALL=onTongue and 60 or 40
 local thick=onTongue and 3.2 or 2.6

 local sky=m:Sky({Ambient=C(70,108,138),OutdoorAmbient=C(92,138,172),ExposureCompensation=.06,FogColor=C(150,220,255),FogStart=0,FogEnd=2600},1,4)
 local grade=m:Grade({TintColor=C(226,246,255),Saturation=-.1,Contrast=.1},.8,3)

 -- The wireframe: 12 edges (drawn one after another) and 8 corner nodes.
 local cube=m:Model('GridCube')
 local edges,nodes,corners={},{},{}
 local order=0
 for _,a in ipairs({-1,1})do for _,b in ipairs({-1,1})do
  for _,e in ipairs({{Vector3.new(0,a,b),Vector3.xAxis},{Vector3.new(a,0,b),Vector3.yAxis},{Vector3.new(a,b,0),Vector3.zAxis}})do
   order+=1
   table.insert(edges,{Part=m:Part({Name='CubeEdge',Color=CYAN,Transparency=1,Size=Vector3.one,Parent=cube}),At=e[1],Axis=e[2],
    Drawn=.05+(order-1)*.055})
  end
  for _,c in ipairs({-1,1})do table.insert(corners,Vector3.new(a,b,c))end
 end end
 for i=1,8 do nodes[i]=m:Ball({Name='CubeNode',Color=WHITE,Transparency=1,Size=Vector3.one,Parent=cube})end
 -- A cold core in the cube's heart (a PointLight would not carry this far).
 local heart=m:Ball({Name='CubeHeart',Color=WHITE,Transparency=1,Size=Vector3.one,Parent=cube})
 -- A node lights when the first edge touching it has been drawn.
 local nodeAt={}
 for i,c in ipairs(corners)do
  local first=math.huge
  for _,e in ipairs(edges)do
   local d=c-e.At
   if math.abs(d.X)+math.abs(d.Y)+math.abs(d.Z)-math.abs(d:Dot(e.Axis))<.01 then first=math.min(first,e.Drawn+.15)end
  end
  nodeAt[i]=first
 end

 -- Its turn, centre and edge half-length at t (the same three snaps as the stage cube).
 local function pose(t)
  local turn=CFrame.identity
  for _,s in ipairs(SNAPS)do
   local u=math.clamp((t-s[1])/SNAP,0,1)
   if u>0 then turn=CFrame.fromAxisAngle(s[2],math.pi/2*backOut(u))*turn end
  end
  local center,size=home,half
  if t<1.8 then center+=Vector3.new(0,6*math.sin(t*4.4),0)
  elseif t<DROP then local k=smooth((t-1.8)/(DROP-1.8));center+=Vector3.new(0,20*k,0);size*=1-.06*k
  elseif t<LAND then
   -- The slam: down onto the landing square, collapsing as it goes.
   local u=math.clamp((t-DROP)/(LAND-DROP),0,1);u*=u
   center=(home+Vector3.new(0,20,0)):Lerp(land+Vector3.new(0,2,0),u);size=half*.94*(1-u)+2*u
   turn=turn:Lerp(CFrame.identity,u)
  elseif t<REFORM then
   -- Out of the impact, small, up to its hover.
   local u=out3((t-LAND)/(REFORM-LAND))
   center=land:Lerp(hover,u);size=2+(SMALL-2)*u
   turn=CFrame.Angles(0,u*math.pi,0)
  else
   local age=t-REFORM
   center=hover+Vector3.new(0,4*math.sin(age*.9),0);size=SMALL
   turn=CFrame.fromAxisAngle(Vector3.new(.35,1,.2).Unit,age*.35)*CFrame.Angles(0,math.pi,0)
  end
  return center,turn,size
 end
 m:Every(function()
  local t=m:Elapsed()
  local center,turn,size=pose(t)
  local cf=CFrame.new(center)*turn
  local flash=0
  for _,s in ipairs(SNAPS)do local d=t-s[1];if d>=0 and d<.3 then flash=math.max(flash,1-d/.3)end end
  if t>=LAND and t<LAND+.6 then flash=math.max(flash,1-(t-LAND)/.6)end
  local fade=math.clamp((t-18)/3,0,1)
  local holo=t>=LAND and .25 or .05
  local w=t>=LAND and 1.6 or thick
  local color=CYAN:Lerp(WHITE,flash)
  for _,e in ipairs(edges)do
   local grow=math.clamp((t-e.Drawn)/.15,0,1)
   local p=e.Part
   if grow<=0 then p.Transparency=1
   else
    -- Drawn from its negative end outward.
    p.Size=e.Axis*(2*size*grow+w)+(Vector3.one-e.Axis)*w
    p.CFrame=cf*CFrame.new(e.At*size+e.Axis*size*(grow-1))
    p.Color=color;p.Transparency=holo+(1-holo)*fade
   end
  end
  for i,p in ipairs(nodes)do
   local on=math.clamp((t-nodeAt[i])/.2,0,1)
   p.Size=Vector3.one*math.max(w*4.5*backOut(on)*(1+.6*flash),.05)
   p.CFrame=cf*CFrame.new(corners[i]*size)
   p.Color=WHITE:Lerp(CYAN,t>=LAND and .4 or 0);p.Transparency=on>0 and holo+(1-holo)*fade or 1
  end
  -- The heart swells between the snaps and flares on each one.
  local beat=t<LAND and math.clamp(t/.8,0,1)or .5
  heart.Size=Vector3.one*math.max(size*.12*beat*(1+.5*flash),.05);heart.CFrame=cf
  heart.Color=CYAN:Lerp(WHITE,.4+.6*flash);heart.Transparency=1-(.55+.4*flash)*beat*(1-fade)
  if fade>=1 then cube:Destroy();return false end
  return true
 end)

 -- The drawing chimes; each snap jolts every player a little.
 if m:Fresh(0,.6)then m:Cue('Chime',nil,.4)end
 for _,s in ipairs(SNAPS)do
  if not m:Wait(s[1])then return end
  if m:Fresh(s[1])then
   m:Cue('Glitch',nil,.3);m:Shake(.14,.16)
   m:Ring(home-Vector3.new(0,half*.9,0),CYAN,half*.5,half*1.25,.45,{Thickness=2.2,Alpha=.35,Segments=40})
  end
 end
 if not m:Wait(1.8)then return end
 if m:Fresh(1.8)then m:Cue('Heartbeat',nil,.5)end
 if not m:Wait(DROP)then return end
 if m:Fresh(DROP)then m:Cue('Whoosh',nil,.55)end

 -- LAND: the cube hits the square.
 if not m:Wait(LAND)then return end
 local ground=Vector3.new(land.X,land.Y,land.Z)
 if m:Fresh(LAND,.6)then
  local near=m:Near(220)
  m:Cue('Boom',nil,.7);task.delay(.12,function()if m:Alive()then m:Cue('Chime',nil,.45)end end)
  m:Flash(WHITE,.5+.25*(1-near),.4)
  grade.Brightness=.22;m:Tween(grade,.6,{Brightness=0})
  m:Banner('CUBEDOG',{Kicker='✦   T H E   G R I D   ✦',Sub=m.VenueText..(m.By and ('  ·  '..string.upper(m.By))or''),
   Font=Enum.Font.Michroma,Color=CYAN,Hold=4.6,Shake=.15})
 end
 m:Shockwave(ground,CYAN,{Speed=300,Height=22,Thickness=1.6,Alpha=.18,OnPass=function()
  m:Shake(.42,.5);m:FOV(-4,.05,.5);m:Cue('Impact',nil,.6);m:Flash(C(200,242,255),.75,.3)
 end})

 -- The holo grid sweeps out over the ground from the stage, line by line.
 local grid=m:Model('HoloGrid')
 local SPACING=onTongue and 48 or 36
 local LINES=low and 7 or 12
 local reach=SPACING*LINES
 local gy=ground.Y+.6
 local lines={}
 for k=-LINES,LINES do
  for _,axis in ipairs({'X','Z'})do
   table.insert(lines,{Part=m:Part({Name='GridLine',Color=CYAN,Size=Vector3.one,Transparency=1,Parent=grid}),Offset=k*SPACING,Axis=axis})
  end
 end
 local gridStart=os.clock()-math.max(0,m:Elapsed()-LAND)
 m:Every(function()
  local age=os.clock()-gridStart
  local t=m:Elapsed()
  local extent=reach*out3(age/3)
  local fade=math.clamp((t-17)/4,0,1)
  for _,l in ipairs(lines)do
   local p=l.Part
   if math.abs(l.Offset)>extent then p.Transparency=1
   else
    -- A bright front where the sweep is, settling to a faint hologram behind it.
    local front=math.clamp(1-(extent-math.abs(l.Offset))/(SPACING*2),0,1)
    local pulse=.5+.5*math.sin(age*3-math.abs(l.Offset)*.03)
    if l.Axis=='X'then p.Size=Vector3.new(extent*2,.35,.9);p.CFrame=CFrame.new(ground.X,gy,ground.Z+l.Offset)
    else p.Size=Vector3.new(.9,.35,extent*2);p.CFrame=CFrame.new(ground.X+l.Offset,gy,ground.Z)end
    p.Color=CYAN:Lerp(WHITE,front)
    p.Transparency=(.35+.3*(1-front)+.1*pulse)+(1-(.35+.3*(1-front)+.1*pulse))*fade
   end
  end
  if fade>=1 then grid:Destroy();return false end
  return true
 end)

 -- Voxels rain over every player: cyan glass, white plastic, deep blue.
 if m:Elapsed()<LAND+3 then
  local colors={CYAN,WHITE,DEEP}
  m:Fall({Count=low and 26 or 60,Radius=150,Height=120,Gravity=110,Life=6,Spin=6,Spread=2.2,
   Make=function(i)
    local s=m.Kit.Random(1.4,3.6)
    local white=i%3==2
    return m:Part({Name='Voxel',Size=Vector3.one*s,Color=colors[(i-1)%3+1],
     Material=white and Enum.Material.SmoothPlastic or Enum.Material.Neon,Transparency=1})
   end})
 end

 -- The hologram tumbles over the head; the sky warms back as the dog walks.
 if not m:Wait(17)then return end
 if sky then sky.Release()end
 m:Tween(grade,3,{TintColor=Color3.new(1,1,1),Saturation=0,Contrast=0})
 m:Wait(m.Config.MegaSeconds or 24)
end

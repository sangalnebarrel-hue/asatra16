-- THE DOG, island-wide: "THE END OF THE WORLD". The sun goes out over the whole island and
-- colour drains from it. Stars come out on a far dome; from 2.6 some of them link up, line by
-- line, into a dog drawn high above the giant head. Beyond the head, past the edge of the
-- world, a colossal black silhouette of THE DOG rises out of the horizon; at 4.2 (the stage's
-- glint) its eyes blink open, white. Players who cannot see the stage hear its heartbeat
-- quicken. At 6.4 (Ground_Opens) light pours out of the tongue into the sky and a ring of
-- white light sweeps the island, each player's heart thumping as it passes. At 9.2 it has
-- arrived; at 10.4 the silhouette bows with every dog on the island. It keeps watching THE
-- DOG while it walks; once someone owns it, it lifts its gaze toward the Hub and fades.
local Lighting=game:GetService('Lighting')
local C=Color3.fromRGB
local WHITE=Color3.new(1,1,1)
local BLACK=Color3.new(0,0,0)
local GLINT,OPENS,ARRIVE,BOW=4.2,6.4,9.2,10.4
-- The silhouette stands beyond the head, off the edge of the island (its feet rise from far below).
local HEIGHT=600
local FEET=Vector3.new(0,0,-950)
-- The constellation: a dog facing right (+X, as the island sees it), in sky units.
local FIGURE={
 {-5.5,3.6},{-4.2,2.4},{-1.5,2.6},{1.8,2.6},{2.8,3.6},{3.0,5.3},{3.9,4.4},{5.4,3.7},
 {4.0,3.1},{2.6,1.4},{2.5,-.6},{-.5,1.2},{-3.6,1.4},{-3.9,-.6},
}
local EDGES={{1,2},{2,3},{3,4},{4,5},{5,6},{6,7},{7,8},{8,9},{9,5},{4,10},{10,11},{10,12},{12,13},{13,2},{13,14}}
local SKY_CENTER,SKY_UNIT=Vector3.new(0,770,-640),48
local function smooth(x)x=math.clamp(x,0,1);return x*x*(3-2*x)end
-- Visible extent of the cloned dog in its pivot space (its invisible RootPart excluded).
local function visual(handle)
 local pivot=handle.Model:GetPivot()
 local lo,hi=Vector3.one*math.huge,Vector3.one*-math.huge
 for _,p in ipairs(handle.Parts)do
  local f=pivot:ToObjectSpace(p.CFrame)
  for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
   local q=f:PointToWorldSpace(p.Size*Vector3.new(x,y,z)/2)
   lo,hi=lo:Min(q),hi:Max(q)
  end end end
 end
 if lo.Y==math.huge then return nil end
 return lo,hi
end

return function(m)
 local low=m.Low
 local stage=m.Venue=='Tongue'and m.Stage or m:Ground(m.Origin)
 -- Whoever has the dog streamed in already hears the stage's own heartbeat, drone and sting.
 local function localIntro()return m.Model~=nil and m.Late<=1.5 end

 -- The sun goes out.
 local sky=m:Sky({ClockTime=0,Brightness=.12,Ambient=C(14,14,20),OutdoorAmbient=C(22,22,30),ExposureCompensation=-.3},3,6)
 local grade=m:Grade({Saturation=-.6,Contrast=.2,Brightness=-.04,TintColor=C(230,234,248)},m.Late<1.5 and 3 or .5,4)
 m:Bloom(.45,46,1.15,2,3)
 m:Duck(.08,2)
 local drone=(not localIntro())and m:Drone('Drone',.3,.42,3)or nil
 -- Haze would swallow the stars: thin it while the sky is ours (no world event owns Lighting).
 local atmo=sky and Lighting:FindFirstChildOfClass('Atmosphere')
 local atmoBase
 if atmo then
  atmoBase={Density=atmo.Density,Haze=atmo.Haze,Glare=atmo.Glare}
  m.Scope:Override(atmo,atmoBase)
  m:Tween(atmo,3,{Density=math.min(atmo.Density,.12),Haze=0,Glare=0})
 end

 -- The stars: the same sky for every player (a fixed seed), on a dome far over the island.
 local rng=Random.new(9017)
 local stars={}
 for i=1,low and 50 or 130 do
  local az,el=rng:NextNumber(0,math.pi*2),math.rad(rng:NextNumber(12,78))
  local dir=Vector3.new(math.cos(az)*math.cos(el),math.sin(el),math.sin(az)*math.cos(el))
  stars[i]={Part=m:Ball({Name='Star',Color=WHITE,Size=Vector3.one*rng:NextNumber(6,13),Position=m.Center+dir*1250,Transparency=1}),
   At=1+rng:NextNumber(0,4),Freq=rng:NextNumber(1.5,4),Phase=rng:NextNumber(0,6)}
 end
 -- The constellation: its stars light as their first line reaches them, the lines draw in order.
 local function point(k)local f=FIGURE[k];return SKY_CENTER+Vector3.new(f[1]*SKY_UNIT,(f[2]-2.3)*SKY_UNIT,0)end
 local lines,named={},{}
 for e,edge in ipairs(EDGES)do
  local a=point(edge[1])
  lines[e]={Part=m:Line(a,a+Vector3.new(0,0,.1),WHITE,2.4,{Name='ConstellationLine',Transparency=1}),A=a,B=point(edge[2]),At=2.6+(e-1)*.38}
 end
 for k=1,#FIGURE do
  local at=math.huge
  for e,edge in ipairs(EDGES)do if edge[1]==k or edge[2]==k then at=math.min(at,lines[e].At+(edge[2]==k and .35 or 0))end end
  named[k]={Part=m:Ball({Name='ConstellationStar',Color=WHITE,Size=Vector3.one*16,Position=point(k),Transparency=1}),At=at-.1}
 end

 -- The silhouette: a black colossus with a faint white rim, measured by its visible parts.
 local dog=m:SkyDog(HEIGHT,{Clip='Stand_Idle',Fill=BLACK,FillAlpha=0,Outline=WHITE})
 local ground,dims,head
 local eyes={}
 if dog then
  local lo,hi=visual(dog)
  if lo and hi.Y-lo.Y>.01 then
   if math.abs((hi.Y-lo.Y)-HEIGHT)>HEIGHT*.08 then dog.Model:ScaleTo(dog.Model:GetScale()*HEIGHT/(hi.Y-lo.Y));lo,hi=visual(dog)end
   ground=Vector3.new((lo.X+hi.X)/2,lo.Y,(lo.Z+hi.Z)/2);dims=hi-lo
  else ground,dims=dog.Ground,dog.Size end
  for _,o in ipairs(dog.Model:GetDescendants())do
   if o:IsA('Bone')then local n=string.lower(o.Name);if n=='head'or n=='head_c'then head=o;break end end
  end
  -- Below the horizon until it rises (never a frame of it standing on the island).
  dog:Pivot(CFrame.lookAt(FEET-Vector3.new(0,900,0),FEET-Vector3.new(0,900,0)+Vector3.zAxis)*CFrame.new(-ground))
  for i=1,2 do eyes[i]=m:Ball({Name='Eye',Color=WHITE,Size=Vector3.one*math.max(8,dims.Y*.034),Transparency=1})end
 end

 local lastBeat,boughtAt,sawModel,finished,released=-math.huge,nil,false,false,false
 local gaze=Vector3.zAxis
 local function release()
  released=true
  if sky then sky.Release()end
  m:Tween(grade,6,{Saturation=0,Contrast=0,Brightness=0,TintColor=WHITE})
  if drone then m:Tween(drone,4,{Volume=0})end
  if atmo and atmoBase then m:Tween(atmo,6,atmoBase)end
 end
 m:Every(function(dt)
  local t=m:Elapsed()
  -- Someone owns it (or it left the line): the vigil ends.
  local model=m.Model
  if model and not boughtAt then
   if model.Parent then
    sawModel=true
    local owner=model:GetAttribute('OwnerName')
    if type(owner)=='string'and owner~=''then boughtAt=t end
   elseif sawModel then boughtAt=t end
  end
  local fade=smooth((t-34)/8)
  if boughtAt then fade=math.max(fade,smooth((t-boughtAt-1.5)/5))end
  if fade>0 and not released then release()end
  local show=1-fade
  local flare=t>=ARRIVE and math.exp(-(t-ARRIVE)*1.5)or 0
  for _,s in ipairs(stars)do
   local v=smooth((t-s.At)/2)*show
   s.Part.Transparency=v>0 and 1-v*(.5+.4*math.sin(t*s.Freq+s.Phase))or 1
  end
  for _,l in ipairs(lines)do
   local g=smooth((t-l.At)/.35)
   if g>0 and show>0 then
    m:SetLine(l.Part,l.A,l.A:Lerp(l.B,g),2.4+3*flare)
    l.Part.Transparency=1-show*(.7+.3*flare)
   else l.Part.Transparency=1 end
  end
  for _,s in ipairs(named)do
   local v=smooth((t-s.At)/.4)*show
   s.Part.Size=Vector3.one*(16+14*flare);s.Part.Transparency=1-v*(.9+.1*math.sin(t*3))
  end
  if dog then
   -- It rises out of the horizon until it arrives, then watches THE DOG wherever it walks.
   local feet=FEET+Vector3.new(0,-720+560*smooth((t-.8)/8.4),0)
   local target=boughtAt and m.Hub or (model and model.Parent and model:GetPivot().Position)or stage
   local want=Vector3.new(target.X-feet.X,0,target.Z-feet.Z)
   if want.Magnitude>1 then
    gaze=gaze:Lerp(want.Unit,math.min(1,dt*.8))
    if gaze.Magnitude>1e-3 then gaze=gaze.Unit else gaze=want.Unit end
   end
   -- The bow (top tipped toward the island), lifted again when its gaze leaves for the Hub.
   local bow=math.rad(10)*smooth((t-BOW)/1.8)*(boughtAt and 1-smooth((t-boughtAt)/2)or 1)
   local frame=CFrame.lookAt(feet,feet+gaze)*CFrame.Angles(-bow,0,0)
   dog:Pivot(frame*CFrame.new(-ground))
   dog:SetAlpha(show)
   if dog.Highlight then dog.Highlight.OutlineTransparency=1-.25*show end
   -- Its eyes: the stage's blink at 4.2, open for good once the ground opens; they swell
   -- with every heartbeat and blaze as it arrives.
   local open=(t>=GLINT and t<GLINT+.3)or(t>=GLINT+.7 and t<GLINT+1.4)or t>=OPENS
   local beat=math.exp(-math.max(t-lastBeat,0)*5)
   local at
   if head and head.Parent then at=head.TransformedWorldCFrame.Position
   else at=dog.Model:GetPivot():PointToWorldSpace(Vector3.new(ground.X,ground.Y+dims.Y*.82,ground.Z-dims.Z*.38))end
   for i,e in ipairs(eyes)do
    e.Position=at+frame.LookVector*dims.Z*.06+frame.UpVector*dims.Y*.03+frame.RightVector*(i==1 and -1 or 1)*dims.Y*.045
    e.Size=Vector3.one*math.max(8,dims.Y*.034)*(1+.35*beat+.8*flare)
    e.Transparency=open and 1-show*(.75+.25*beat)or 1
   end
  end
  if fade>=1 then finished=true;return false end
  return true
 end)

 -- The heartbeat that quickens until it arrives (the stage plays its own where it is seen).
 task.spawn(function()
  local at,beat=0,1.7
  while at<9.5 do
   if not m:Wait(at)then return end
   if m:Fresh(at,.3)then
    lastBeat=m:Elapsed()
    if not localIntro()then m:Cue('Heartbeat',nil,.8)end
   end
   at+=beat;beat=math.max(.55,beat*.86)
  end
 end)

 -- 6.4 Ground_Opens: light pours out of the tongue into the sky and a ring of white light
 -- sweeps the island; every heart on it thumps as the ring passes.
 if not m:Wait(OPENS)then return end
 if m:Fresh(OPENS,1.2)then
  m:Pillar(stage,900,WHITE,26,4.2)
  m:Shockwave(stage,WHITE,{Speed=240,Radius=m.Radius+500,Height=22,Thickness=1.5,Alpha=.1,OnPass=function()
   lastBeat=m:Elapsed()
   m:Cue('Heartbeat',nil,.9);m:Flash(WHITE,.68,.6);m:Shake(.25,.6)
  end})
  if not localIntro()then m:Cue('Impact',nil,.9)end
 end
 -- 9.2: it has arrived.
 if not m:Wait(ARRIVE)then return end
 if m:Fresh(ARRIVE,1.5)then
  m:Banner('THE DOG',{Kicker='?     ?     ?',Sub=m.VenueText,Font=Enum.Font.SpecialElite,Color=WHITE,Hold=6,Shake=.1})
  if not localIntro()then m:Cue('Sting',nil,.8);m:Flash(WHITE,.55,1.1)end
 end
 -- It keeps its vigil until THE DOG is owned or the watch runs out.
 local limit=m.Config.MegaSeconds or 44
 while not finished and m:Elapsed()<limit do
  if not m:Wait(math.min(m:Elapsed()+.25,limit))then return end
 end
 if not released then release()end
 m:Wait(math.min(m:Elapsed()+1,limit))
end

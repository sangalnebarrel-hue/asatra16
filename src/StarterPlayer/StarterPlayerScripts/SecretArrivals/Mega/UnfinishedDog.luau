-- THE UNFINISHED DOG, island-wide: "UNDER CONSTRUCTION". The island turns into an editor
-- viewport: flat light, drained colour, and the world round every player goes grey-box
-- in a wave (a blue selection ring marking its front) while Studio-blue selection boxes
-- flicker from building to building. Giant yellow sticky notes ("TODO: finish the dog")
-- pin themselves to the sky, a colossal move gizmo hangs over the head and grey parts
-- rain down like a slipped Insert key. At 0.4 (its Unfinished_Logic_Duplicate) Ctrl+D
-- drags out three giant magenta duplicates of the dog over the head; at 3.55 the island
-- throws an error, the duplicates are marked and deleted one by one, and at 5.0 Ctrl+Z
-- sweeps out from the stage, putting the colour back as it reaches each player. Then the
-- notes peel off and the name ships. Off the tongue it all hangs over the opened pad.
local C=Color3.fromRGB
local DARK,LIGHT,BLUE,RED,YELLOW,TAPE,INK,WHITE=C(108,108,112),C(208,208,212),C(13,105,172),C(255,72,72),C(255,231,118),C(240,240,232),C(40,40,44),C(255,255,255)
local AXES={{Vector3.xAxis,C(255,72,72)},{Vector3.yAxis,C(84,220,96)},{Vector3.zAxis,C(64,144,255)}}
local DUP,ERROR,DELETE,UNDO=.4,3.55,{4.25,4.55,4.85},5
local NOTES={'TODO: finish the dog','TODO: legs??','FIXME: dog is unfinished','TODO: textures','NOTE: do NOT ship','TODO: bark.wav','TODO: ???'}
local function backOut(x)x=math.clamp(x,0,1)-1;local c=1.70158;return 1+(c+1)*x*x*x+c*x*x end
local function out3(x)x=math.clamp(x,0,1);return 1-(1-x)^3 end

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
 local MAGENTA=m.Color
 local onTongue=m.Venue=='Tongue'
 local fresh=m.Late<.5
 local focus=onTongue and m.Head or m:Ground(m.Origin)
 local sweepFrom=onTongue and m:Ground(m.Stage)or focus
 local toward=Vector3.new(m.Center.X-focus.X,0,m.Center.Z-focus.Z)
 local facing=onTongue and Vector3.zAxis or (toward.Magnitude>40 and toward.Unit or Vector3.zAxis)
 local sideways=facing:Cross(Vector3.yAxis)

 -- Editor lighting: a flat grey studio afternoon, the colour drained.
 local sky=m:Sky({ClockTime=14,Brightness=2,Ambient=C(138,138,138),OutdoorAmbient=C(128,128,128),FogColor=C(192,192,192),FogStart=0,FogEnd=2600,
  ExposureCompensation=0},fresh and 1.2 or .2,1.2)
 local grade=m:Grade({Saturation=-.55,Contrast=-.05,TintColor=C(236,240,250)},fresh and .8 or .2,1)
 if fresh then m:Cue('Whoosh',nil,.25)end

 -- The world round each player goes grey-box in a wave from where they stand.
 local applied,list={},{}
 local restoring=false
 local boxes={}
 if m:Elapsed()<UNDO-.6 then
  if not m:Wait(.2)then return end
  list=gather(m,170,low and 220 or 380)
  local t0,cursor=m:Elapsed(),1
  local floor=m:Ground(m:Camera())
  m:Ring(floor+Vector3.new(0,1,0),BLUE,2,175,175/160,{Thickness=.8,Alpha=.25,Segments=48,Linear=true})
  m:Every(function()
   local front=(m:Elapsed()-t0)*160
   local n=0
   while not restoring and cursor<=#list and list[cursor].D<=front and n<60 do
    local row=list[cursor];cursor+=1;n+=1
    local p=row.Part
    if p.Parent then
     local c=p.Color
     local grey=DARK:Lerp(LIGHT,math.clamp(.299*c.R+.587*c.G+.114*c.B,0,1))
     local _,release=m.Scope:Override(p,{Color=grey,Material=Enum.Material.SmoothPlastic})
     row.Release=release;table.insert(applied,row)
    end
   end
   return not restoring and cursor<=#list
  end)
  -- Studio-blue selection boxes hop between the bigger structures.
  for i=1,low and 3 or 6 do
   local b=Instance.new('SelectionBox');b.Name='EditorSelection';b.Color3=BLUE;b.LineThickness=.3;b.SurfaceTransparency=1
   b.Transparency=1;b.Parent=m.Scope.Folder;boxes[i]=b
  end
  local nextHop=0
  m:Every(function()
   if restoring then return false end
   local now=os.clock()
   if now<nextHop then return true end
   nextHop=now+.4
   local big={}
   for _,row in ipairs(applied)do if row.Part.Parent and row.Part.Size.Magnitude>14 then table.insert(big,row.Part)end end
   for _,b in ipairs(boxes)do
    if #big>0 and math.random()<.7 then b.Adornee=big[math.random(1,#big)];b.Transparency=0 else b.Transparency=1 end
   end
   return true
  end)
 end

 -- Sticky notes pinned to the sky all round the island, facing its middle.
 local notes={}
 local count=low and 4 or 7
 for i=1,count do
  local a=(i-1)/count*math.pi*2+.6
  local r=Kit.Random(260,380)
  local at=m.Center+Vector3.new(math.cos(a)*r,Kit.Random(110,200),math.sin(a)*r)
  local home=CFrame.lookAt(at,Vector3.new(m.Center.X,at.Y,m.Center.Z))*CFrame.Angles(0,0,math.rad(Kit.Random(-8,8)))
  local paper=m:Part({Name='StickyNote',Material=Enum.Material.SmoothPlastic,Color=YELLOW,Size=Vector3.one*.1,Transparency=1,CFrame=home})
  local tape=m:Part({Name='Tape',Material=Enum.Material.SmoothPlastic,Color=TAPE,Size=Vector3.one*.1,Transparency=1,CFrame=home})
  local text,labels=m:Text3D(NOTES[(i-1)%#NOTES+1],home,Vector2.new(46,40),{Font=Enum.Font.PermanentMarker,Color=INK,Stroke=false,Alpha=1})
  table.insert(notes,{Paper=paper,Tape=tape,Text=text,Labels=labels,Home=home,Pop=.3+(i-1)*.22,Phase=Kit.Random(0,6),
   Fall=Vector3.new(Kit.Random(-12,12),0,Kit.Random(-12,12)),Spin=Kit.Random(-3,3)})
 end
 m:Every(function()
  local e=m:Elapsed()
  local alive=false
  for _,n in ipairs(notes)do
   if n.Paper.Parent then
    alive=true
    local k=e>=n.Pop and backOut((e-n.Pop)/.35)or 0
    -- Ctrl+Z peels them off: they drop, tumble and fade.
    local peel=math.clamp((e-UNDO-.15)/1.4,0,1)
    local frame=n.Home*CFrame.Angles(0,0,math.rad(2)*math.sin(e*1.3+n.Phase))
    if peel>0 then frame=frame+n.Fall*peel*3-Vector3.new(0,90*peel*peel,0);frame*=CFrame.Angles(peel*n.Spin,0,peel*n.Spin*.6)end
    local s=math.max(k,.01)
    n.Paper.Size=Vector3.new(56*s,56*s,.8);n.Paper.CFrame=frame;n.Paper.Transparency=k>0 and peel or 1
    n.Tape.Size=Vector3.new(22*s,7*s,.9);n.Tape.CFrame=frame*CFrame.new(0,27*s,-.1);n.Tape.Transparency=k>0 and .25+.75*peel or 1
    n.Text.Size=Vector3.new(46*s,40*s,.2);n.Text.CFrame=frame*CFrame.new(0,-3*s,-.6)
    for _,l in ipairs(n.Labels)do l.TextTransparency=k>0 and peel or 1 end
    if peel>=1 then n.Paper:Destroy();n.Tape:Destroy();n.Text:Destroy()end
   end
  end
  return alive
 end)

 -- The move gizmo over the head: a centre cube and an arrow each way along each axis.
 local hub=focus+Vector3.new(0,onTongue and 250 or 210,0)
 local gizmo=m:Model('MoveGizmo')
 local cube=m:Part({Name='GizmoCube',Material=Enum.Material.SmoothPlastic,Color=C(225,225,225),Size=Vector3.one,Transparency=1,Parent=gizmo})
 local arms={}
 for _,axis in ipairs(AXES)do
  for _,sign in ipairs({1,-1})do
   table.insert(arms,{Dir=axis[1]*sign,
    Shaft=m:Part({Name='GizmoShaft',Shape=Enum.PartType.Cylinder,Color=axis[2],Size=Vector3.one,Transparency=1,Parent=gizmo}),
    Tip=m:Part({Name='GizmoTip',Shape=Enum.PartType.Ball,Color=axis[2],Size=Vector3.one,Transparency=1,Parent=gizmo})})
  end
 end
 m:Every(function()
  local e=m:Elapsed()
  local show=out3((e-.1)/.4)*(1-out3((e-UNDO)/.5))
  -- Someone grabs the X arrow at Ctrl+D and drags it out, then lets go.
  local drag=sideways*30*(math.sin(math.clamp((e-DUP)/.6,0,1)*math.pi))
  local center=hub+drag+Vector3.new(0,3*math.sin(e*1.1),0)
  local s=math.max(show,.01)
  cube.Size=Vector3.one*14*s;cube.CFrame=CFrame.new(center);cube.Transparency=show>0 and 0 or 1
  for _,a in ipairs(arms)do
   local from,to=center+a.Dir*12*s,center+a.Dir*56*s
   a.Shaft.Size=Vector3.new((to-from).Magnitude,5*s,5*s);a.Shaft.CFrame=Kit.LookAt((from+to)/2,to)*CFrame.Angles(0,math.pi/2,0)
   a.Tip.Size=Vector3.one*18*s;a.Tip.Position=center+a.Dir*64*s
   a.Shaft.Transparency=show>0 and .1 or 1;a.Tip.Transparency=show>0 and 0 or 1
  end
  if e>UNDO+.6 then gizmo:Destroy();return false end
  return true
 end)

 -- Grey parts rain down round you at 1.0, as if somebody leaned on Insert.
 task.spawn(function()
  if not m:Wait(1)or not m:Fresh(1,.6)then return end
  m:Fall({Count=22,Radius=130,Height=110,Gravity=110,Life=4.5,Spin=3,Spread=1.6,Make=function()
   return m:Part({Name='Part',Material=Enum.Material.SmoothPlastic,Color=C(163,162,165),
    Size=Vector3.new(Kit.Random(2,6),Kit.Random(1,3),Kit.Random(2,5)),Transparency=1})
  end})
 end)

 -- Ctrl+D: three giant duplicates over the head, one magenta outline round all of them.
 local dupes={}
 if m:Elapsed()<DELETE[#DELETE] then
  local group=m:Model('Duplicates')
  local row=focus+Vector3.new(0,onTongue and 70 or 40,0)-facing*30
  local n=low and 2 or 3
  for i=1,n do
   local handle=m:SkyDog(110,{Clip='Idle'})
   if handle then
    handle.Model.Parent=group;handle:SetAlpha(0)
    local slot=(i-(n+1)/2)*(n==3 and 120 or 130)
    local bounds=m:Part({Name='Bounds',Size=handle.Size,Transparency=1})
    local sel=Instance.new('SelectionBox');sel.Adornee=bounds;sel.Color3=BLUE;sel.LineThickness=.5;sel.SurfaceTransparency=1;sel.Transparency=1
    sel.Parent=bounds
    local tag=Instance.new('BillboardGui');tag.Name='ExplorerTag';tag.Adornee=bounds;tag.Size=UDim2.new(34,0,7,0)
    tag.StudsOffsetWorldSpace=Vector3.new(0,handle.Size.Y/2+8,0);tag.LightInfluence=0;tag.MaxDistance=3000;tag.Enabled=false;tag.Parent=bounds
    local plate=Instance.new('Frame');plate.Size=UDim2.fromScale(1,1);plate.BackgroundColor3=C(46,46,46);plate.BorderSizePixel=0;plate.Parent=tag
    local corner=Instance.new('UICorner');corner.CornerRadius=UDim.new(.15,0);corner.Parent=plate
    local edge=Instance.new('UIStroke');edge.Color=BLUE;edge.Thickness=2;edge.ApplyStrokeMode=Enum.ApplyStrokeMode.Border;edge.Parent=plate
    local name=m.Mega.Label(plate,{Font=Enum.Font.SourceSansBold,Text='Dog ('..(i+1)..')',Size=UDim2.fromScale(.9,.8),Position=UDim2.fromScale(.05,.1)})
    table.insert(dupes,{Handle=handle,Bounds=bounds,Sel=sel,Tag=tag,Edge=edge,Name=name,Slot=slot,Row=row,
     Born=DUP+(i-1)*.15,Kill=DELETE[i]or DELETE[#DELETE],Jolt=Vector3.zero,JoltUntil=0,NextJolt=0,Dead=false})
   end
  end
  local outline=Instance.new('Highlight');outline.Name='Duplicated';outline.Adornee=group;outline.FillColor=MAGENTA;outline.OutlineColor=WHITE
  outline.FillTransparency=1;outline.OutlineTransparency=1;outline.DepthMode=Enum.HighlightDepthMode.Occluded;outline.Parent=group
  if #dupes>0 then
   m:Every(function()
    local e,now=m:Elapsed(),os.clock()
    local any=false
    local marked=e>=ERROR
    outline.FillColor=marked and RED or MAGENTA
    local visible=false
    for _,d in ipairs(dupes)do
     if not d.Dead then
      any=true
      if e>=d.Kill then
       d.Dead=true;d.Handle:SetAlpha(0);d.Sel.Transparency=1;d.Tag.Enabled=false
       if d.Shown and m:Fresh(d.Kill,.3)then
        m:Burst(d.Bounds.Position,MAGENTA,low and 10 or 24,{Speed=NumberRange.new(20,60),Lifetime=NumberRange.new(.4,.9),Size=NumberSequence.new(3,0)})
        m:Cue('Whoosh',nil,.3)
       end
       d.Handle.Model:Destroy()
      elseif e>=d.Born then
       visible=true;d.Shown=true
       if not m.Reduced and now>=d.NextJolt then
        d.Jolt=sideways*Kit.Random(-4,4);d.JoltUntil=now+.05;d.NextJolt=now+Kit.Random(.3,.8)
       end
       local slide=backOut((e-d.Born)/.35)
       local feet=d.Row+sideways*d.Slot*slide+(now<d.JoltUntil and d.Jolt or Vector3.zero)
       d.Handle:Place(feet,facing)
       d.Bounds.CFrame=CFrame.lookAt(feet,feet+facing)*CFrame.new(0,d.Handle.Size.Y/2,0)
       local age=e-d.Born
       d.Handle:SetAlpha((age<.05 or (age>.09 and age<.14) or age>.18)and 1 or 0)
       d.Sel.Transparency=0;d.Sel.Color3=marked and RED or BLUE
       d.Tag.Enabled=true;d.Edge.Color=marked and RED or BLUE
       d.Name.Text=marked and 'Delete' or d.Name.Text;d.Name.TextColor3=marked and RED or WHITE
      end
     end
    end
    outline.FillTransparency=visible and (marked and .3 or .45) or 1
    outline.OutlineTransparency=visible and .05 or 1
    if any then return true end
    group:Destroy()
    return false
   end)
  end
  task.spawn(function()
   if m:Wait(DUP)and m:Fresh(DUP,.3)and #dupes>0 then m:Cue('Glitch',nil,.25)end
  end)
 end

 -- 3.55: the whole island throws an error.
 if not m:Wait(ERROR)then return end
 local errorSign
 if m:Elapsed()<UNDO then
  local at=hub+Vector3.new(0,95,0)
  errorSign=m:Text3D('[error] Dog:Finish() not implemented',CFrame.lookAt(at,at+facing),Vector2.new(320,40),{Font=Enum.Font.Code,Color=RED,StrokeThickness=5})
 end
 if m:Fresh(ERROR,.4)then
  m:Flash(RED,.8,.25);m:Cue('Static',nil,.3)
 end

 -- 5.0: Ctrl+Z. It sweeps out from the stage and the colour comes back as it reaches you.
 if not m:Wait(UNDO)then return end
 restoring=true
 if errorSign then errorSign:Destroy()end
 for _,b in ipairs(boxes)do b:Destroy()end
 if sky then sky.Release()end
 m:Tween(grade,1,{Saturation=0,Contrast=0,TintColor=Color3.new(1,1,1)},Enum.EasingStyle.Sine)
 local keyAt=hub+Vector3.new(0,10,0)
 local key,keyLabels=m:Text3D('Ctrl + Z',CFrame.lookAt(keyAt,keyAt+facing),Vector2.new(180,60),{Font=Enum.Font.SourceSansBold,Color=WHITE,StrokeThickness=6})
 m:Every(function(_,age)
  local fade=math.clamp((age-1)/.4,0,1)
  for _,l in ipairs(keyLabels)do
   l.TextTransparency=fade
   local stroke=l:FindFirstChildOfClass('UIStroke');if stroke then stroke.Transparency=fade end
  end
  if fade<1 then return true end
  key:Destroy()
  return false
 end)
 -- (A late joiner gets the restored world, not a sweep starting from their join.)
 if m:Elapsed()<UNDO+2 then
  m:Shockwave(sweepFrom,MAGENTA,{Speed=320,Height=24,Thickness=1.4,Alpha=.2,Radius=m.Radius+500,OnPass=function()
   m:Flash(MAGENTA,.75,.3);m:Cue('Whoosh',nil,.35);m:Cue('Chime',nil,.25)
  end})
 end
 for _,row in ipairs(applied)do
  local d=row.Part.Parent and row.Part.Position-sweepFrom or Vector3.zero
  row.R=Vector3.new(d.X,0,d.Z).Magnitude
 end
 table.sort(applied,function(a,b)return a.R<b.R end)
 local back=1
 m:Every(function()
  local front=(m:Elapsed()-UNDO)*320
  local n=0
  while back<=#applied and (applied[back].R<=front or m:Elapsed()>UNDO+3.5) and n<80 do
   applied[back].Release();back+=1;n+=1
  end
  return back<=#applied
 end)

 -- It ships anyway.
 if not m:Wait(UNDO+.35)then return end
 if m:Fresh(UNDO+.35,1)then
  m:Banner('THE UNFINISHED DOG',{Kicker='✦   I T   S H I P P E D   A N Y W A Y   ✦',Sub=m.VenueText..(m.By and ('  ·  '..string.upper(m.By))or''),
   Font=Enum.Font.Code,Color=MAGENTA,Hold=4.5,Shake=.1})
 end
 m:Wait(m.Config.MegaSeconds or 26)
end

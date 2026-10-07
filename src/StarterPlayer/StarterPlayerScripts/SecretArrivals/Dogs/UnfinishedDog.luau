-- THE UNFINISHED DOG, "DEV BUILD": the whole island is opened in Studio. Wherever a player
-- stands, the sky goes flat baseplate grey, everything around them is stripped to grey
-- SmoothPlastic in a wave out from their feet and a Studio grid draws itself on the ground
-- under them. In every sky a grey blockout box labelled "Dog (1)" sits under a move gizmo
-- and imports piece by piece into a grey blockout of the dog (each piece flashes
-- missing-texture magenta), Ctrl+D duplicates it twice (magenta), an Output window on every
-- screen logs warnings, an ERROR flashes red across the island, the duplicates are deleted
-- one by one, and on Alt+P it ships: a magenta wave sweeps out from the stage over the
-- whole map, the textures stream back in as it passes, the colossus is textured, every dog
-- on the island looks at the stage and every camera is pulled in to the dog.
-- On the stage meanwhile (as before) the tongue loses its textures, a grid draws itself on
-- the belt, a grey blockout box imports into the real dog under a move gizmo, two magenta
-- duplicates slide out, glitch and are deleted. Off the tongue (a Lucky pad, any stand)
-- there is no belt to strip: a grey baseplate spreads under the grid instead and burns
-- away magenta on Alt+P.
--  0     Studio opens: grey sky, the strip and the grid spread   .45 Output  .6 sky blockout
--  1.3-3.1  the import (stage and sky)   3.4/3.55 Ctrl+D ×2   4.6 ERROR (island-wide red)
--  5.4   cutaway (wide)   5.6/6.2 the duplicates are deleted   6.6 PUBLISH: the magenta wave,
--        the banner, every dog looks   8.6 handed back   hold 9
-- SecretArrivalConfig.Dogs.UnfinishedDog must agree: Hold 9, Unfinished_Logic_Duplicate at
-- CLIP, Happy from just after PUBLISH, Banner at PUBLISH.
local Players=game:GetService('Players')
local UIS=game:GetService('UserInputService')
local C=Color3.fromRGB
local WHITE,GREY,ROW,BLUE,RED=C(255,255,255),C(163,162,165),C(46,46,46),C(13,105,172),C(255,76,76)
local AMBER,GREEN,INK,EDGE=C(255,190,60),C(96,222,120),C(204,204,204),C(72,72,72)
local TICK='rbxasset://sounds/volume_slider.ogg'
local UP=Vector3.yAxis
-- The pieces import in this order; anything else comes in with the last one.
local ORDER={'Unfinished_Fur_02_Geo','Unfinished_Fur_01_Geo','Unfinished_BlueWire_03_Geo','Unfinished_RedWire_04_Geo','Unfinished_Label_05_Geo'}
local IMPORT:{[string]:number}={Unfinished_Fur_02_Geo=1.3,Unfinished_Fur_01_Geo=1.8,Unfinished_BlueWire_03_Geo=2.3,
 Unfinished_RedWire_04_Geo=2.7,Unfinished_Label_05_Geo=3.1}
local SPARK:{[string]:Color3}={Unfinished_BlueWire_03_Geo=C(70,160,255),Unfinished_RedWire_04_Geo=C(255,70,70)}
-- A major scale up as the pieces land.
local NOTES={1,9/8,5/4,4/3,3/2}
local FIRST,DONE,ERROR,PUBLISH=1.3,3.1,4.6,6.6
-- Unfinished_Logic_Duplicate starts at CLIP (the server); it hops 3.05 s in (HOP), just
-- before the error.
local CLIP=1.45
local HOP=CLIP+3.05
-- Ctrl+D twice. Each duplicate slides out to one side, is marked red, then deleted.
local DUPES={{Side=-1,Born=3.4,Name='Dog (2)',Mark=5.4,Kill=5.6,Lag=.08},{Side=1,Born=3.55,Name='Dog (3)',Mark=6,Kill=6.2,Lag=.16}}
local LOG={{At=.5,Kind='info',Text='Opened DOGROTS_District (Edit)'},{At=.8,Kind='warn',Text='[warn] Dog.Texture is nil'},
 {At=1.3,Kind='info',Text='Importing Dog.fbx (5 meshes)...'},{At=2.4,Kind='warn',Text="Infinite yield possible on 'Tail'"},
 {At=3.62,Kind='info',Text='Duplicated: Dog (2), Dog (3)'},{At=ERROR,Kind='error',Text='[error] Dog:Finish() not implemented'},
 {At=5.6,Kind='info',Text='Deleted Dog (2)'},{At=6.2,Kind='info',Text='Deleted Dog (3)'},
 {At=PUBLISH,Kind='ok',Text='Published. 1 error, 2 warnings.'}}
local TINT:{[string]:Color3}={info=INK,warn=AMBER,error=RED,ok=GREEN}
-- Keys shown over the Output window, screencast style.
local KEYS={{At=3.32,Text='Ctrl + D'},{At=3.47,Text='Ctrl + D  ×2'},{At=5.6,Text='Del'},{At=6.2,Text='Del'},{At=6.45,Text='Alt + P'}}
-- The whole island: the blockout appears in every sky (SKYBOX), the cutaway (CUT to
-- CUT_END), the publish wave's speed (studs/s: across the yards in well under a second, to
-- the island's far corner about 2.8 s after PUBLISH, while the dog sets off).
local SKYBOX,CUT,CUT_END,SCAN=.6,5.4,8.6,330
-- Studio's flat baseplate sky: a grey dome, no sun glare, flat grey light.
local STUDIO={Lighting={ClockTime=14,Brightness=2,ExposureCompensation=0,Ambient=C(118,118,122),OutdoorAmbient=C(134,134,138),
  EnvironmentDiffuseScale=0,EnvironmentSpecularScale=0,ColorShift_Top=C(0,0,0),ColorShift_Bottom=C(0,0,0)},
 Atmosphere={Density=.24,Offset=0,Color=C(192,192,198),Decay=C(150,150,158),Glare=0,Haze=2.4},
 Grade={Saturation=-.55,Contrast=-.06,TintColor=C(238,240,246)}}
-- Never stripped: the Void, the portals, the DOG-O-MATIC rig, and every dog.
local SKIP_TOP={['13_TheVoid']=true,['12_Portals']=true,['37_AttractionRefresh']=true,NavigationAnchors=true,KennelDogs=true}
local SKIP_NAME={ActiveDogs=true,DisplayDog=true,Exhibit=true,CommittedPrize=true,WinningDog=true,AurionGrandPrize=true}
-- The colossal blockout in every sky: studs tall, studs from each camera, degrees up.
local GIANT_H,GIANT_D,GIANT_E=150,380,math.rad(14)
local function smooth(x)x=math.clamp(x,0,1);return x*x*(3-2*x)end
local function out3(x)x=math.clamp(x,0,1);return 1-(1-x)^3 end
local function backOut(x)x=math.clamp(x,0,1)-1;local c=1.70158;return 1+(c+1)*x*x*x+c*x*x end
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
-- Untextured grey that keeps each part's lightness, so shapes still read.
local function shade(c:Color3):Color3
 local g=math.floor(104+112*(.299*c.R+.587*c.G+.114*c.B))
 return C(g,g,math.min(g+3,255))
end
local function frame(parent:Instance,props)
 local f=Instance.new('Frame');f.BorderSizePixel=0
 for k,v in pairs(props)do (f::any)[k]=v end
 f.Parent=parent
 return f
end
local function round(o:Instance,radius:number)local c=Instance.new('UICorner');c.CornerRadius=UDim.new(0,radius);c.Parent=o end
-- KeepFont before parenting, or PlaceTypography turns it into FredokaOne.
local function text(parent:Instance,props)
 local l=Instance.new('TextLabel');l:SetAttribute('KeepFont',true)
 l.BackgroundTransparency=1;l.TextScaled=false;l.RichText=false;l.TextStrokeTransparency=1
 for k,v in pairs(props)do (l::any)[k]=v end
 l.Parent=parent
 return l
end
-- Visible parts of the district within `radius` of `at`, walked a few hundred instances a
-- frame. A model whose bounding box is out of range is skipped whole, so only the
-- neighbourhood of ~37k instances is visited; skip(o) prunes a subtree.
local function gather(district:Instance,at:Vector3,radius:number,skip:(Instance)->boolean,alive:()->boolean):{BasePart}
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

return function(ctx:any)
 -- The first line is a code comment; the second (set before it) glitches in magenta.
 ctx.WhisperStyle={Font=Enum.Font.Code,Color=C(106,153,85),Glitch=0,Chroma=false,Shake=false,Type=.045}
 -- Its own banner at PUBLISH (SecretArrivalConfig Banner), on its own clock.
 ctx.ManualBanner=true
 local Kit,scope,model,config=ctx.Kit,ctx.Scope,ctx.Model,ctx.Config
 local low,calm,origin,hold=ctx.Low,Kit.ReducedMotion(),ctx.Origin,config.Hold
 local MAGENTA=config.Color
 local size=Kit.Size(model)
 local up=UP
 local onTongue=(ctx.Venue or 'Tongue')=='Tongue'
 -- Dogs face their pivot's look vector: +Z on the tongue, wherever the stand points elsewhere.
 -- Off the tongue that is only known once the root streams in: until then the stage faces
 -- this client's camera (the opener stands where the dog looks) and turns once it is known.
 local fwd,side,stage,center=Vector3.zAxis,Vector3.xAxis,CFrame.identity,CFrame.identity
 local function aim(look:Vector3)
  local flat=Vector3.new(look.X,0,look.Z)
  fwd=flat.Magnitude>.1 and flat.Unit or Vector3.zAxis
  side=fwd:Cross(up)
  stage=CFrame.lookAt(origin,origin+fwd)
  center=stage*CFrame.new(0,size.Y/2,0)
 end
 local camera=workspace.CurrentCamera
 aim(Kit.Root(model)and model:GetPivot().LookVector or (not onTongue and camera and camera.CFrame.Position-origin)or Vector3.zAxis)
 local aimed=onTongue or Kit.Root(model)~=nil
 local core=center.Position
 local playerGui=Players.LocalPlayer:FindFirstChildOfClass('PlayerGui')
 local function near()return Kit.Near(origin,120)end
 -- One-shots fire on time only: a late joiner gets the state, not a pile-up of cues.
 local function live(t:number,slack:number?)return ctx:Elapsed()-t<(slack or .35)end

 -- Sound: one-shot blips (3D on a part), and a pool of key clicks (no new sound per key).
 local function blip(speed:number,volume:number,parent:Instance?,buzz:boolean?)
  if not scope.Alive then return end
  local s=Instance.new('Sound');s.SoundId=TICK;s.Volume=volume;s.PlaybackSpeed=speed
  s.RollOffMinDistance=12;s.RollOffMaxDistance=240
  if buzz then local d=Instance.new('DistortionSoundEffect');d.Level=.7;d.Parent=s end
  s.Parent=(parent and parent.Parent)and parent or scope.Folder
  s:Play()
  task.delay(2,function()if s.Parent then s:Destroy()end end)
 end
 local keys={}
 for i=1,4 do
  local s=Instance.new('Sound');s.Name='Key';s.SoundId=TICK;s.Volume=0
  local eq=Instance.new('EqualizerSoundEffect');eq.LowGain=-8;eq.MidGain=0;eq.HighGain=-6;eq.Parent=s
  s.Parent=scope.Folder;keys[i]=s
 end
 local turn=0
 local function key(volume:number,speed:number)
  if not scope.Alive then return end
  turn=turn%#keys+1
  local s=keys[turn]
  s.Volume=volume;s.PlaybackSpeed=speed;s.TimePosition=0;s:Play()
 end
 -- The whispers are typed on a keyboard, one click per character as the director types it.
 local function typing(t:number,line:string,per:number)
  task.spawn(function()
   -- A late joiner's director types the line from the moment it joins, not from its slot.
   local base=math.max(t,ctx:Elapsed())
   local i=0
   for _,code in utf8.codes(line)do
    i+=1
    local at=base+i*per
    if not ctx:Wait(at)then return end
    if code~=32 and live(at,.08)then key(.07,Kit.Random(1.9,2.7))end
   end
  end)
 end
 local lines=config.Whispers or {}
 if lines[1]then typing(lines[1][1],lines[1][2],.045)end
 if lines[2]then typing(lines[2][1],lines[2][2],.05)end

 -- Editor lighting: flat, a little grey; the music steps back for the clicks everywhere.
 scope:Duck(.3,.6)
 local hue=Kit.Near(origin,200)
 local grade=scope:Grade({Saturation=-.12-.38*hue,Contrast=.05,TintColor=C(236,240,250)},live(0)and .6 or .2)
 local light=scope:Light(scope:Anchor(core+up*(size.Y/2+4),'EditorLight'),C(228,236,255),20,0)
 Kit.Tween(light,live(0)and .5 or .01,{Brightness=1.3})

 -- On the tongue the belt around the stage (and the mouth's runes) loses its textures.
 local stripped={}
 local function strip(o:BasePart,color:Color3)
  table.insert(stripped,{Part=o,Color=o.Color,Material=o.Material})
  scope:Override(o,{Color=color,Material=Enum.Material.SmoothPlastic})
 end
 local district=workspace:FindFirstChild('DOGROTS_District')
 if onTongue then
  local factory=district and district:FindFirstChild('02_DogFactory')
  local tunnel=factory and factory:FindFirstChild('DarkMouthTunnel')
  local line=district and district:FindFirstChild('03_DogLine')
  local tongue=line and line:FindFirstChild('Tongue')
  local shades:{[string]:Color3}={TongueSurface=GREY,TongueTip=GREY,TongueGroove=C(134,133,136),SoftRoundedRim=C(184,183,186),WarmEdgeGuide=C(208,208,212)}
  for _,o in ipairs(tongue and tongue:GetChildren()or {})do
   local s=shades[o.Name]
   if s and o:IsA('BasePart')and math.abs((o.Position-origin):Dot(fwd))<30 then strip(o,s)end
  end
  for _,o in ipairs(tunnel and tunnel:GetDescendants()or {})do
   if o.Name=='MouthRune'and o:IsA('BasePart')then strip(o,C(112,112,118))end
  end
 end

 -- A grid draws itself on the belt from the middle out (world axes in red and blue).
 local grid={}
 local span,step=16,low and 4 or 2
 -- Line i of an axis (1: along the dog, 2: across it); it turns with the stage.
 local function gridAt(i:number,axis:number):CFrame
  local along,across=axis==1 and fwd or side,axis==1 and side or fwd
  local mid=origin+up*.1+across*i
  return CFrame.lookAt(mid,mid+along)
 end
 for i=-span/2,span/2,step do
  for axis=1,2 do
   local axisLine=i==0
   local color=axisLine and (axis==1 and C(70,140,255)or C(255,84,84))or C(196,210,232)
   table.insert(grid,{Part=scope:Part({Name='Grid',Color=color,Size=Vector3.new(.05,.02,.05),CFrame=gridAt(i,axis),Transparency=1}),
    I=i,Axis=axis,Color=color,Width=axisLine and .09 or .05,Alpha=axisLine and .2 or .72,Delay=math.abs(i)/span*.35,Full=false,Hot=false})
  end
 end
 -- Off the tongue: the baseplate under it, drawn out from the middle with the grid.
 local plate:BasePart?=nil
 if not onTongue then
  local p=scope:Part({Name='Baseplate',Material=Enum.Material.SmoothPlastic,Color=C(134,133,136),Size=Vector3.new(.05,.08,.05),
   CFrame=stage*CFrame.new(0,.02,0)})
  plate=p
  scope:Every(function()
   local k=out3(ctx:Elapsed()/.6)
   if p.Parent then p.Size=Vector3.new(math.max(span*k,.05),.08,math.max(span*k,.05))end
   return k<1 and p.Parent~=nil
  end)
 end
 scope:Every(function()
  local e=ctx:Elapsed()
  local hot=(e>=ERROR and e<ERROR+.5)and 1-(e-ERROR)/.5 or 0
  local gone=true
  for _,g in ipairs(grid)do
   local k=out3((e-g.Delay)/.45)
   local fade=smooth((e-PUBLISH-g.Delay*.8)/.5)
   if not g.Full then g.Part.Size=Vector3.new(g.Width,.02,math.max(span*k,.05));g.Full=k>=1 end
   g.Part.Transparency=1-(1-g.Alpha)*k*(1-fade)
   if hot>0 or g.Hot then g.Part.Color=g.Color:Lerp(RED,hot);g.Hot=hot>0 end
   if fade<1 then gone=false end
  end
  if not gone then return true end
  for _,g in ipairs(grid)do g.Part:Destroy()end
  return false
 end)

 -- 0: a grey blockout box the size of the dog, selected, under a move gizmo.
 local box=scope:Part({Name='Blockout',Material=Enum.Material.SmoothPlastic,Color=GREY,Size=size,CFrame=center})
 local outline=Instance.new('SelectionBox');outline.Name='Selection';outline.Adornee=box;outline.Color3=BLUE;outline.LineThickness=.05
 outline.SurfaceColor3=BLUE;outline.SurfaceTransparency=1;outline.Transparency=1;outline.Parent=box
 local scan=scope:Part({Name='ImportScan',Color=BLUE,Size=Vector3.new(size.X+.8,.05,size.Z+.8),CFrame=stage,Transparency=1})
 local sized=not live(0)
 scope:Every(function()
  local e=ctx:Elapsed()
  if not sized then
   local grow=.3+.7*backOut(e/.28)
   box.Size=size*grow;box.CFrame=stage*CFrame.new(0,size.Y*grow/2,0)
   sized=e>=.28
  end
  -- It goes see-through as the real pieces arrive, a scan line rising through it.
  box.Transparency=e<FIRST and 0 or math.min(1,.5*smooth((e-FIRST)/.12)+.5*smooth((e-FIRST-.12)/(DONE-FIRST-.12)))
  local k=(e-FIRST)/(DONE+.1-FIRST)
  if k>0 and k<1 then scan.CFrame=stage*CFrame.new(0,size.Y*k,0);scan.Transparency=.4+.6*smooth((k-.8)/.2)
  else scan.Transparency=1 end
  if e<DONE+.2 then return true end
  scan:Destroy()
  return false
 end)
 -- Off the tongue: once the root streams in, the stage turns to the dog's real facing.
 local function settle()
  if aimed or not Kit.Root(model)then return end
  aimed=true
  aim(model:GetPivot().LookVector)
  for _,g in ipairs(grid)do if g.Part.Parent then g.Part.CFrame=gridAt(g.I,g.Axis)end end
  if sized and box.Parent then box.CFrame=center end
  if plate and plate.Parent then plate.CFrame=stage*CFrame.new(0,.02,0)end
 end
 if not aimed then scope:Every(function()settle();return not aimed and ctx:Elapsed()<PUBLISH end)end
 -- Explorer-style name tags over a selection. lift: studs over the adornee's middle;
 -- big: the colossal ones in the sky (larger, readable from anywhere).
 local function tag(adornee:BasePart,name:string,lift:number?,big:boolean?)
  local g=Instance.new('BillboardGui');g.Name='ExplorerTag';g.Adornee=adornee;g.AlwaysOnTop=not big;g.LightInfluence=0
  local k=big and 1.35 or 1
  g.MaxDistance=big and 5000 or 220;g.Size=UDim2.fromOffset(108*k,24*k);g.StudsOffsetWorldSpace=up*(lift or size.Y/2+1.4)
  local row=frame(g,{Name='Row',Size=UDim2.fromScale(1,1),BackgroundColor3=ROW,BackgroundTransparency=.04})
  round(row,4)
  local edge=Instance.new('UIStroke');edge.Color=BLUE;edge.Thickness=1.5;edge.ApplyStrokeMode=Enum.ApplyStrokeMode.Border;edge.Parent=row
  round(frame(row,{Name='Icon',Size=UDim2.fromOffset(11*k,11*k),Position=UDim2.fromOffset(7*k,6*k),BackgroundColor3=GREY}),2)
  local label=text(row,{Name='Name',Size=UDim2.new(1,-28*k,1,0),Position=UDim2.fromOffset(25*k,0),Font=Enum.Font.SourceSans,TextSize=math.floor(18*k),
   TextColor3=WHITE,TextXAlignment=Enum.TextXAlignment.Left,Text=name})
  g.Parent=big and scope.Folder or adornee
  return {Gui=g,Edge=edge,Label=label}
 end
 local main=tag(box,'Dog (1)');main.Gui.Enabled=false
 -- Studio's move tool: one Handles per axis, coloured like it. They follow the selection.
 local function gizmoSet():{Handles}
  local set={}
  for _,axis in ipairs({{Color=C(255,72,72),A=Enum.NormalId.Right,B=Enum.NormalId.Left},{Color=C(84,220,96),A=Enum.NormalId.Top,B=Enum.NormalId.Bottom},
   {Color=C(64,144,255),A=Enum.NormalId.Front,B=Enum.NormalId.Back}})do
   local h=Instance.new('Handles');h.Name='DOGROTS_UnfinishedGizmo';h.Style=Enum.HandlesStyle.Movement;h.Faces=Faces.new(axis.A,axis.B)
   h.Color3=axis.Color;h.Visible=false;h.Adornee=box
   if playerGui then h.Parent=playerGui end
   scope:Add(h);table.insert(set,h)
  end
  return set
 end
 local gizmo=gizmoSet()
 -- Handles draw over the world at a fixed screen size: only near the stage, like the tags.
 local held:BasePart?=nil
 local function grab(part:BasePart?)held=part;for _,h in ipairs(gizmo)do if part then h.Adornee=part end end end
 scope:Every(function()
  local show=held~=nil and Kit.Near(origin,220)>0
  for _,h in ipairs(gizmo)do if h.Visible~=show then h.Visible=show end end
  return true
 end)
 -- The price tag needs nothing: the server hides DogBillboard for the hold and shows it at Hold.

 -- The real dog is hidden; each piece shows up at its import time (parts can stream late).
 local pieces={}
 local function track(o:Instance)
  if o:IsA('BasePart')and o.Name~='RootPart'then
   table.insert(pieces,o)
   -- Hidden the moment it streams in, not a frame later.
   if ctx:Elapsed()<(IMPORT[o.Name]or DONE)then o.LocalTransparencyModifier=1 end
  end
 end
 for _,o in ipairs(model:GetDescendants())do track(o)end
 scope:Add(model.DescendantAdded:Connect(track))
 scope:Add(function()for _,p in ipairs(pieces)do if p.Parent then p.LocalTransparencyModifier=0 end end end)
 local function reveal()
  local e=ctx:Elapsed()
  for _,p in ipairs(pieces)do
   if p.Parent then p.LocalTransparencyModifier=e>=(IMPORT[p.Name]or DONE)and 0 or 1 end
  end
  return e<DONE+.1
 end
 reveal();scope:Every(reveal)

 -- The Output window, docked bottom centre like Studio's, and the keys over it.
 local touch=UIS.TouchEnabled
 local rowH,textSize,rows=touch and 15 or 17,touch and 12 or 14,5
 local gui=Instance.new('ScreenGui');gui.Name='DOGROTS_UnfinishedOutput';gui.ResetOnSpawn=false;gui.DisplayOrder=95
 gui.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
 local panel=Instance.new('CanvasGroup');panel.Name='Output';panel.AnchorPoint=Vector2.new(.5,1);panel.BackgroundTransparency=1
 panel.BorderSizePixel=0;panel.GroupTransparency=1;panel.Parent=gui
 local window=frame(panel,{Name='Window',Size=UDim2.new(1,-2,1,-2),Position=UDim2.fromOffset(1,1),BackgroundColor3=C(37,37,37),BackgroundTransparency=.06})
 round(window,5)
 local border=Instance.new('UIStroke');border.Color=EDGE;border.Thickness=1;border.Parent=window
 local head=frame(window,{Name='Header',Size=UDim2.new(1,0,0,22),BackgroundColor3=ROW})
 round(head,5)
 frame(head,{Name='Square',Size=UDim2.new(1,0,0,6),Position=UDim2.new(0,0,1,-6),BackgroundColor3=ROW})
 text(head,{Name='Tab',Size=UDim2.new(0,80,1,-2),Position=UDim2.fromOffset(10,0),Font=Enum.Font.SourceSansSemibold,TextSize=15,
  TextColor3=C(232,232,232),TextXAlignment=Enum.TextXAlignment.Left,Text='Output'})
 frame(head,{Name='Active',Size=UDim2.fromOffset(50,2),Position=UDim2.new(0,6,1,-2),BackgroundColor3=BLUE})
 local body=frame(window,{Name='Log',Size=UDim2.new(1,-16,1,-28),Position=UDim2.fromOffset(8,25),BackgroundTransparency=1,ClipsDescendants=true})
 local list=Instance.new('UIListLayout');list.SortOrder=Enum.SortOrder.LayoutOrder;list.VerticalAlignment=Enum.VerticalAlignment.Bottom;list.Parent=body
 local caps=Instance.new('CanvasGroup');caps.Name='Keys';caps.AnchorPoint=Vector2.new(.5,1);caps.BackgroundTransparency=1
 caps.BorderSizePixel=0;caps.GroupTransparency=1;caps.Size=UDim2.fromOffset(200,52);caps.Parent=gui
 local cap=frame(caps,{Name='Key',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(168,38),
  BackgroundColor3=C(28,28,28),BackgroundTransparency=.08})
 round(cap,8)
 local rim=Instance.new('UIStroke');rim.Color=C(120,120,120);rim.Thickness=1.5;rim.Parent=cap
 local pop=Instance.new('UIScale');pop.Parent=cap
 local capLabel=text(cap,{Name='Label',Size=UDim2.fromScale(1,1),Font=Enum.Font.SourceSansBold,TextSize=22,TextColor3=WHITE,Text=''})
 -- Clear of the money stack (bottom left) and the touch thumbstick and jump button.
 local function layout()
  local width=math.clamp(gui.AbsoluteSize.X-2*(touch and 230 or 350),250,540)
  local height=30+rows*rowH
  local bottom=touch and 18 or 14
  panel.Size=UDim2.fromOffset(width,height);panel.Position=UDim2.new(.5,0,1,-bottom)
  caps.Position=UDim2.new(.5,0,1,-(bottom+height+6))
 end
 if playerGui then gui.Parent=playerGui end
 scope:Add(gui)
 scope:Add(gui:GetPropertyChangedSignal('AbsoluteSize'):Connect(layout))
 layout()
 local logged={}
 local serial=0
 local function log(kind:string,message:string,animate:boolean)
  serial+=1
  local l=text(body,{Name='Line',LayoutOrder=serial,Size=UDim2.new(1,0,0,rowH),Font=Enum.Font.Code,TextSize=textSize,
   TextColor3=TINT[kind]or INK,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,RichText=true,
   Text='<font color="#7c7c7c">'..tostring(os.date('%H:%M:%S'))..'</font>  '..message,TextTransparency=animate and 1 or 0})
  table.insert(logged,l)
  while #logged>rows do
   local old=table.remove(logged,1)
   if old then old:Destroy()end
  end
  if animate then Kit.Tween(l,.15,{TextTransparency=0})end
  if kind=='error'and animate then
   border.Color=RED;border.Thickness=2
   Kit.Tween(border,.7,{Color=EDGE,Thickness=1})
  end
 end
 local pressed=-math.huge
 scope:Every(function()
  local age=os.clock()-pressed
  caps.GroupTransparency=math.clamp((age-.6)/.3,0,1)
  pop.Scale=.78+.22*backOut(age/.16)
  return true
 end)
 task.spawn(function()
  if not ctx:Wait(.45)then return end
  Kit.Tween(panel,live(.45)and .3 or .01,{GroupTransparency=0})
  for _,entry in ipairs(LOG)do
   if not ctx:Wait(entry.At)then return end
   log(entry.Kind,entry.Text,live(entry.At))
  end
  if not ctx:Wait(hold-.45)then return end
  Kit.Tween(panel,.4,{GroupTransparency=1})
 end)
 task.spawn(function()
  for _,k in ipairs(KEYS)do
   if not ctx:Wait(k.At)then return end
   if live(k.At,.2)then capLabel.Text=k.Text;pressed=os.clock();key(.22,Kit.Random(1.4,1.7))end
  end
 end)

 ---------------------------------------------------------------- the whole island
 -- Where this player stood when it began: the island is stripped from there.
 local me=Kit.Me()
 local map=Kit.Map
 -- The publish wave rolls from the stage out past the island's far corners at SCAN
 -- studs/s; the moment it passes a point, that point is textured again.
 local reachR=map.Radius*2
 for _,x in ipairs({map.Min.X,map.Max.X})do for _,z in ipairs({map.Min.Z,map.Max.Z})do
  reachR=math.max(reachR,Vector3.new(x-origin.X,0,z-origin.Z).Magnitude+40)
 end end
 local function passes(at:Vector3):number
  return PUBLISH+math.clamp(Vector3.new(at.X-origin.X,0,at.Z-origin.Z).Magnitude-4,0,reachR)/SCAN
 end
 -- When the wave is over (a little after Hold: the dog is already walking).
 local over=PUBLISH+reachR/SCAN+.2
 -- Studio's flat grey sky for this player wherever they are, until the wave reaches their
 -- camera. It lives in its own scope that ends with the wave, so the sky's world-event
 -- check covers all of it (the arrival's own EndsAt is Hold).
 local studio=Kit.Scope('Arrival_UnfinishedDog_Studio')
 studio.EndsAt=ctx.Start+over
 scope:Add(function()studio:Clean()end)
 local sky=nil
 if ctx:Elapsed()<PUBLISH-.4 then sky=studio:Sky(STUDIO,live(0)and 1.2 or .3,.6)end

 -- Everything around this player (and round the stage, for the cutaway) is stripped to
 -- untextured grey SmoothPlastic, a few hundred parts a frame in a wave out from them; the
 -- publish wave puts it back, each part flushing magenta for an instant as it passes.
 local own:{[Instance]:boolean}={}
 for _,s in ipairs(stripped)do own[s.Part]=true end
 local function skipped(o:Instance):boolean
  if o.Parent==district and SKIP_TOP[o.Name]then return true end
  if SKIP_NAME[o.Name]or own[o]then return true end
  return o:IsA('Model')and(o:GetAttribute('DogId')~=nil or o:GetAttribute('EventObjectId')~=nil)
 end
 local function greyOut(p:BasePart)
  local props:{[string]:any}={Color=shade(p.Color),Material=Enum.Material.SmoothPlastic}
  if p:IsA('MeshPart')and p.TextureID~=''then props.TextureID=''end
  if p:IsA('UnionOperation')and not p.UsePartColor then props.UsePartColor=true end
  local _,release,update=scope:Override(p,props)
  local undo={release}
  -- Decals and Textures (a Texture is a Decal) go too.
  for _,c in ipairs(p:GetChildren())do
   if c:IsA('Decal')and c.Transparency<1 then
    local _,r=scope:Override(c,{Transparency=1})
    table.insert(undo,r)
   end
  end
  return undo,update
 end
 local function stripIsland()
  if not district or ctx:Elapsed()>=PUBLISH-.5 then return end
  local alive=function()return scope.Alive end
  local seen:{[BasePart]:boolean}={}
  local list={}
  local function add(parts:{BasePart},from:Vector3)
   for _,p in ipairs(parts)do
    if not seen[p]then
     seen[p]=true
     table.insert(list,{Part=p,At=.1+Vector3.new(p.Position.X-from.X,0,p.Position.Z-from.Z).Magnitude/90,Back=passes(p.Position)})
    end
   end
  end
  add(gather(district,me,low and 60 or 90,skipped,alive),me)
  if not scope.Alive then return end
  -- Round the stage too, unless that is where this player already is.
  if (me-origin).Magnitude>30 then
   add(gather(district,origin,low and 30 or 45,skipped,alive),origin)
   if not scope.Alive then return end
  end
  if ctx:Elapsed()>=PUBLISH-.5 then return end
  table.sort(list,function(a,b)return a.At<b.At end)
  local cap=low and 900 or 2600
  while #list>cap do table.remove(list)end
  -- A second order for the way back, by when the wave passes each part.
  local back=table.clone(list)
  table.sort(back,function(a,b)return a.Back<b.Back end)
  local i,j,k=1,1,1
  -- Flushing parts go back once their flush is over (queued in order of that time).
  local flushing={}
  local applyCap,restoreCap=low and 150 or 300,low and 200 or 350
  scope:Every(function()
   local e=ctx:Elapsed()
   local work=0
   while list[i]and list[i].At<=e and work<applyCap do
    local s=list[i];i+=1
    if e<s.Back and s.Part.Parent then
     work+=1
     local undo,update=greyOut(s.Part)
     s.Undo,s.Update=undo,update
    end
   end
   work=0
   while back[j]and back[j].Back<=e and work<restoreCap do
    local s=back[j];j+=1
    if s.Undo then
     work+=1
     -- A flush of magenta as the wave passes (on time only), then the real colours.
     if live(s.Back,.2)and s.Update then s.Update('Color',MAGENTA);table.insert(flushing,{S=s,At=e+.18})
     else for _,undo in ipairs(s.Undo)do undo()end;s.Undo=nil end
    end
   end
   while flushing[k]and e>=flushing[k].At do
    local f=flushing[k];k+=1
    for _,undo in ipairs(f.S.Undo)do undo()end
    f.S.Undo=nil
   end
   return list[i]~=nil or back[j]~=nil or flushing[k]~=nil
  end)
 end
 task.spawn(stripIsland)

 -- A Studio grid on the ground round this player, drawn out from under them, that keeps up
 -- as they walk (it steps with them, like a world grid). It flashes red with the error and
 -- burns away magenta when the publish wave reaches them.
 local function studioGrid()
  local STEP=low and 12 or 8
  local N=low and 4 or 7
  local L=STEP*N*2
  local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.RespectCanCollide=true
  local parts:{BasePart},cfs:{CFrame},rows={},{},{}
  for i=-N,N do
   for axis=1,2 do
    local mid=i==0
    local color=mid and (axis==1 and C(70,140,255)or C(255,84,84))or C(176,186,204)
    local p=scope:Part({Name='StudioGrid',Color=color,Transparency=1,Size=Vector3.new(.1,.04,.1)})
    table.insert(parts,p);table.insert(cfs,p.CFrame)
    table.insert(rows,{Part=p,I=i,Axis=axis,Color=color,Alpha=mid and .2 or .5,Width=mid and .2 or .12,Delay=math.abs(i)/N*.3,Full=false,Shade=color})
   end
  end
  local start=ctx:Elapsed()
  local floorY,nextFloor=me.Y-3,0
  local burn=nil
  scope:Every(function()
   local e=ctx:Elapsed()
   local at=Kit.Me()
   local now=os.clock()
   if now>=nextFloor then
    nextFloor=now+.35
    -- (The character changes on respawn.)
    local character=Players.LocalPlayer.Character
    params.FilterDescendantsInstances=character and {scope.Folder,model,character}or {scope.Folder,model}
    local hit=workspace:Raycast(at+up,Vector3.new(0,-40,0),params)
    if hit then floorY=hit.Position.Y+.06 end
   end
   if not burn and e>=passes(at)then burn=e end
   local fade=burn and smooth((e-burn)/.5)or 0
   local hot=(e>=ERROR and e<ERROR+.5)and 1-(e-ERROR)/.5 or 0
   local c=Vector3.new(math.floor(at.X/STEP+.5)*STEP,floorY,math.floor(at.Z/STEP+.5)*STEP)
   for n,r in ipairs(rows)do
    local k=out3((e-start-r.Delay)/.45)
    if not r.Full then
     local len=math.max(L*k,.1)
     r.Part.Size=r.Axis==1 and Vector3.new(r.Width,.04,len)or Vector3.new(len,.04,r.Width)
     r.Full=k>=1
    end
    cfs[n]=CFrame.new(c+(r.Axis==1 and Vector3.new(r.I*STEP,0,0)or Vector3.new(0,0,r.I*STEP)))
    r.Part.Transparency=1-(1-r.Alpha)*k*(1-fade)
    local color=burn and MAGENTA or (hot>0 and r.Color:Lerp(RED,hot)or r.Color)
    if color~=r.Shade then r.Shade=color;r.Part.Color=color end
   end
   workspace:BulkMoveTo(parts,cfs,Enum.BulkMoveMode.FireCFrameChanged)
   if fade<1 then return true end
   for _,p in ipairs(parts)do p:Destroy()end
   return false
  end)
 end
 if ctx:Elapsed()<PUBLISH-.3 then studioGrid()end

 -- The colossal blockout in every sky, beyond the stage as each player sees it (placed from
 -- their camera, so it is in shot wherever they stand): a grey box under a selection and a
 -- move gizmo, "Dog (1)", that imports into a grey blockout of the dog piece by piece;
 -- Ctrl+D makes two magenta copies that slide out, the error makes them all jump, the
 -- copies are deleted, and on publish it is textured.
 local giant:any,solid:any=nil,nil
 local giantBox=Vector3.new(GIANT_H*.5,GIANT_H,GIANT_H*.8)
 local giantPieces={}
 local block:BasePart?=nil
 local blockSel:SelectionBox?=nil
 local blockTag:any=nil
 local skyGizmo:{Handles}={}
 local copies:{[number]:any}={}
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
  local p=eye+b*GIANT_D*math.cos(GIANT_E)+up*GIANT_D*math.sin(GIANT_E)
  return CFrame.lookAt(p,p-b)
 end
 local function skyGrab(part:BasePart?)
  for _,h in ipairs(skyGizmo)do if part then h.Adornee=part end;h.Visible=part~=nil end
 end
 local function raiseGiant()
  base=skyAt(1)
  giant=ctx:Colossus({Height=GIANT_H,At=base,Style='Silhouette',Color=GREY,Clip='Idle',FadeIn=.05})
  if not giant then return end
  local _,box2=Kit.Bounds(giant.Model)
  giantBox=box2
  local e=ctx:Elapsed()
  for _,o in ipairs(giant.Model:GetDescendants())do
   if o:IsA('BasePart')and o.Name~='RootPart'then
    local at=IMPORT[o.Name]or DONE
    table.insert(giantPieces,{Part=o,At=at,Shown=e>=at,Flash=0})
    if e<at then o.Transparency=1 end
   end
  end
  local b=scope:Part({Name='SkyBlockout',Material=Enum.Material.SmoothPlastic,Color=GREY,Size=giantBox*.3,CFrame=base})
  block=b
  local sel=Instance.new('SelectionBox');sel.Name='Selection';sel.Adornee=b;sel.Color3=BLUE;sel.LineThickness=GIANT_H*.007
  sel.SurfaceTransparency=1;sel.Parent=b
  blockSel=sel
  blockTag=tag(b,'Dog (1)',giantBox.Y/2+GIANT_H*.07,true)
  if not low then
   skyGizmo=gizmoSet()
   skyGrab(b)
  end
  if live(SKYBOX)then Kit.Cue('Whoosh',nil,.25);key(.2,1.5)end
 end
 -- A copy in the sky: magenta, frozen, sliding out to its side.
 local function skyCopy(i:number,d:any)
  local h=ctx:Colossus({Height=GIANT_H,At=base,Style='Ghost',Color=MAGENTA,Alpha=.35,FadeIn=live(d.Born)and .08 or 0})
  if not h then return end
  local centre=Kit.Bounds(h.Model)
  local bounds=scope:Part({Name='SkyBounds',Size=giantBox,Transparency=1,CFrame=base})
  local sel=Instance.new('SelectionBox');sel.Name='Selection';sel.Adornee=bounds;sel.Color3=BLUE;sel.LineThickness=GIANT_H*.007
  sel.SurfaceTransparency=1;sel.Parent=bounds
  if blockSel then blockSel.Transparency=.65 end
  if blockTag then blockTag.Edge.Transparency=1 end
  for _,other in pairs(copies)do other.Sel.Transparency=.65;other.Tag.Edge.Transparency=1 end
  copies[i]={Handle=h,Bounds=bounds,Sel=sel,Tag=tag(bounds,d.Name,giantBox.Y/2+GIANT_H*.07,true),Scale=h.Model:GetScale(),Centre=centre,
   Side=d.Side,Born=d.Born,Lag=d.Lag,Mark=d.Mark,Kill=d.Kill,Marked=false,Dying=false,Jolt=Vector3.zero,JoltUntil=0,NextJolt=os.clock()+Kit.Random(.2,.5)}
  if not low then skyGrab(bounds)end
 end
 local function giantStep(dt:number)
  local e,now=ctx:Elapsed(),os.clock()
  base=skyAt(dt)
  if giant then giant:Pose(base,0)end
  if solid then solid:Pose(base,0)end
  local b=block
  if b and b.Parent then
   local grow=live(SKYBOX)and .3+.7*backOut((e-SKYBOX)/.28)or 1
   b.Size=giantBox*grow;b.CFrame=base
   -- See-through as the pieces arrive (the selection stays on it).
   b.Transparency=e<FIRST and 0 or math.min(1,.5*smooth((e-FIRST)/.12)+.5*smooth((e-FIRST-.12)/(DONE-FIRST-.12)))
  end
  for _,p in ipairs(giantPieces)do
   if not p.Shown and e>=p.At then
    p.Shown=true;p.Part.Transparency=0
    -- It lands missing-texture magenta for a blink.
    if live(p.At)then p.Part.Color=MAGENTA;p.Part.Material=Enum.Material.Neon;p.Flash=now+.12 end
   end
   if p.Flash>0 and now>=p.Flash then p.Flash=0;p.Part.Color=GREY;p.Part.Material=Enum.Material.SmoothPlastic end
  end
  for i,d in pairs(copies)do
   local alive=d.Handle.Model.Parent~=nil
   if not alive then
    d.Bounds:Destroy();d.Tag.Gui:Destroy();copies[i]=nil
   else
    local slide=d.Side*giantBox.X*1.15*backOut((e-d.Born)/.32)
    local hop=(e-HOP-d.Lag)/.75
    hop=(hop>0 and hop<1)and GIANT_H*.06*math.sin(math.pi*hop)or 0
    if not calm and e<d.Mark and now>=d.NextJolt then
     local wild=e>=ERROR and e<ERROR+.6
     d.Jolt=Vector3.new(Kit.Random(-1,1),Kit.Random(-.3,.3),0)*giantBox.X*(wild and .09 or .035)
     d.JoltUntil=now+.05;d.NextJolt=now+(wild and Kit.Random(.08,.18)or Kit.Random(.3,.8))
    end
    local at=base*CFrame.new(slide,hop,0)+(now<d.JoltUntil and base:VectorToWorldSpace(d.Jolt)or Vector3.zero)
    if not d.Marked and e>=d.Mark then
     -- "Delete": marked red.
     d.Marked=true
     d.Sel.Color3=RED;d.Sel.Transparency=0
     d.Tag.Label.Text='Delete';d.Tag.Label.TextColor3=RED;d.Tag.Edge.Color=RED;d.Tag.Edge.Transparency=0
     for _,o in ipairs(d.Handle.Model:GetDescendants())do if o:IsA('BasePart')and o.Name~='RootPart'then o.Color=RED end end
    end
    if e<d.Kill then
     d.Handle:Pose(at,0);d.Bounds.CFrame=at
    else
     -- Deleted: it shrinks to nothing about its middle.
     if not d.Dying then
      d.Dying=true;d.Tag.Gui.Enabled=false;d.Sel.Visible=false
      if live(d.Kill)then
       local cam=workspace.CurrentCamera
       local right=cam and cam.CFrame.RightVector or base.RightVector
       scope:Ring(at.Position,MAGENTA,giantBox.X*.2,giantBox.X*.95,.45,{U=right,W=up,Thickness=GIANT_H*.02,Alpha=.2,Segments=24})
      end
     end
     local s=1-out3((e-d.Kill)/.15)
     if s<=.03 then d.Handle:Stop(0)
     else
      pcall(function()d.Handle.Model:ScaleTo(d.Scale*s)end)
      d.Handle:Pose(at*CFrame.new(d.Centre*(1-s)),0)
     end
    end
   end
  end
  return (giant~=nil and giant.Model.Parent~=nil)or(solid~=nil and solid.Model.Parent~=nil)or next(copies)~=nil
 end
 -- Alt+P: the grey blockout is swapped for the real thing, textured, with a magenta flush.
 local function publishGiant()
  if not giant then return end
  local onTime=live(PUBLISH)
  skyGrab(nil)
  if block then block:Destroy();block=nil end
  if blockTag then blockTag.Gui:Destroy();blockTag=nil end
  solid=ctx:Colossus({Height=GIANT_H,At=base,Style='Solid',Clip='Happy',FadeIn=onTime and .45 or .1})
  giant:Stop(onTime and .45 or .1)
  if solid and onTime then
   local shine=scope:Highlight(solid.Model,MAGENTA,WHITE,.2,0)
   Kit.Tween(shine,.9,{FillTransparency=1,OutlineTransparency=1},Enum.EasingStyle.Sine,Enum.EasingDirection.In)
  end
 end

 -- Every camera is pulled out over the grey island for the publish: wide behind the stage's
 -- line of sight (the blockout in the sky beyond it, its copies deleted), the magenta wave
 -- rolling out under it, then down to the dog as it ships; handed back at CUT_END.
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
  settle()
  local across=-side
  local mid=origin+up*size.Y*.55
  return ctx:Cutaway({
   shot(CUT,origin+fwd*125+across*40+up*55,origin+up*42,62),
   shot(PUBLISH+.15,origin+fwd*112+across*36+up*50,origin+up*38,60),
   shot(PUBLISH+.9,origin+fwd*26+across*8+up*9,mid,50),
   shot(CUT_END-.35,origin+fwd*11+across*3+up*size.Y*.85,mid+up*size.Y*.1,44),
   shot(CUT_END,origin+fwd*9.5+across*2.6+up*size.Y*.82,mid+up*size.Y*.12,42,true),
  },{Focus=origin,Bars=.09,Shake=.08})
 end

 -- The map-wide beats on the server clock (a late client skips what it missed).
 task.spawn(function()
  if not ctx:Wait(SKYBOX)then return end
  if ctx:Elapsed()<PUBLISH-.4 then
   raiseGiant()
   if giant then scope:Every(giantStep)end
  end
  for i,d in ipairs(DUPES)do
   if not ctx:Wait(d.Born)then return end
   if giant and ctx:Elapsed()<d.Kill then skyCopy(i,d)end
  end
  if not ctx:Wait(ERROR)then return end
  -- The error, island-wide: a red flash on every screen (a red grade when motion is
  -- reduced), the blockout in every sky flickering magenta.
  if live(ERROR)then
   if not calm then Kit.Flash(RED,.55,.45)end
   grade.TintColor=C(255,150,150);Kit.Tween(grade,.6,{TintColor=C(236,240,250)})
   if giant then
    local h=scope:Highlight(giant.Model,MAGENTA,WHITE,.15,0)
    scope:Every(function(_,age:number)
     if not h.Parent then return false end
     h.Enabled=calm or age<.08 or (age>.16 and age<.26) or age>.34
     h.FillTransparency=.15+.85*smooth((age-.34)/.4);h.OutlineTransparency=smooth((age-.34)/.4)
     if age<.8 then return true end
     h:Destroy();return false
    end)
   end
  end
  if not ctx:Wait(DUPES[1].Mark)then return end
  skyGrab(nil)
  if not ctx:Wait(CUT-.6)then return end
  cut=cutaway()
  if not ctx:Wait(PUBLISH)then return end
  publishGiant()
  local onTime=live(PUBLISH)
  -- The publish wave: a see-through magenta wall with a white line along its foot, rolling
  -- out over the whole map from the stage.
  if onTime then
   wave(scope,origin,MAGENTA,reachR,SCAN,Vector2.new(.6,9),.5,low and 24 or 60)
   if not low then wave(scope,origin+up*.2,WHITE,reachR,SCAN,Vector2.new(1,.7),.05,60)end
   Kit.Cue('Whoosh',nil,.5)
   if cut and cut.Active then cut:Shake(.5,.4)end
  end
  local b=config.Banner
  if type(b)=='table'and ctx:Elapsed()<PUBLISH+2 then
   local banner=table.clone(b)
   -- Off the tongue the kicker names who opened it.
   if ctx.By then banner.Kicker=(banner.Kicker or 'SECRET · DEV BUILD')..'  ·  '..string.upper(ctx.By)end
   ctx:Banner(banner)
  else ctx:Title({Font=Enum.Font.Code,Tier=not ctx.By and 'SECRET · DEV BUILD'or nil,Hold=3.6})end
  -- Every dog on the island looks at the stage.
  if ctx:Elapsed()<hold-.5 then
   scope:Glance(function()return (model.Parent and ctx:Ground()or origin)+up*size.Y*.6 end,{Exclude=model,Turn=.6,Ripple=320})
  end
  -- The grey sky lets go the moment the wave reaches this camera.
  scope:Every(function()
   local cam=workspace.CurrentCamera
   if ctx:Elapsed()<passes(cam and cam.CFrame.Position or Kit.Me())then return true end
   if sky then sky:Release(.6)end
   return false
  end)
  if not ctx:Wait(hold-1.2)then return end
  if solid then solid:Stop(1.2)end
 end)

 ---------------------------------------------------------------- the stage
 -- Missing-texture magenta: one highlight that blinks onto each piece as it lands.
 local flash=Instance.new('Highlight');flash.Name='MissingTexture';flash.FillColor=MAGENTA;flash.OutlineColor=WHITE
 flash.FillTransparency=0;flash.OutlineTransparency=0;flash.DepthMode=Enum.HighlightDepthMode.Occluded;flash.Enabled=false
 flash.Parent=scope.Folder
 local flashUntil=0
 scope:Every(function()
  if flash.Enabled and os.clock()>=flashUntil then flash.Enabled=false end
  return ctx:Elapsed()<DONE+1
 end)
 -- A wire connects: sparks, a short arc, and its own glow surging then settling.
 local function zap(piece:BasePart,color:Color3)
  local at=piece.Position
  Kit.Cue('Glitch',box,.14)
  scope:Burst(at,color,low and 6 or 18,{Speed=NumberRange.new(6,13),Lifetime=NumberRange.new(.2,.45),Acceleration=Vector3.new(0,-30,0),
   SpreadAngle=Vector2.new(70,70),Size=NumberSequence.new(.22,0)})
  if not low then
   for _=1,2 do scope:Bolt(at,at+Vector3.new(Kit.Random(-1.4,1.4),Kit.Random(-1.2,.4),Kit.Random(-1.4,1.4)),color,.07,.16)end
   local glow=scope:Light(scope:Life(scope:Anchor(at,'Spark'),.5),color,10,4)
   Kit.Tween(glow,.4,{Brightness=0})
  end
  local skin=piece:FindFirstChildOfClass('SurfaceAppearance')
  if not skin then return end
  local ok,strength,tint=pcall(function()return skin.EmissiveStrength,skin.EmissiveTint end)
  if not ok then return end
  scope:Override(skin,{EmissiveStrength=strength,EmissiveTint=tint})
  scope:Every(function(_,age:number)
   local k=math.min(age/.8,1)
   pcall(function()skin.EmissiveStrength=strength+(3-strength)*(1-k)^2;skin.EmissiveTint=color:Lerp(tint,k)end)
   return k<1
  end)
 end
 -- Voxel debris that bounces once on the belt and fades.
 local function shatter(at:Vector3)
  local bits={}
  for i=1,10 do
   local p=scope:Part({Name='Voxel',Size=Vector3.one*Kit.Random(.2,.42),Color=i%3==0 and MAGENTA or GREY,
    Material=i%3==0 and Enum.Material.Neon or Enum.Material.SmoothPlastic,
    CFrame=CFrame.new(at+Vector3.new(Kit.Random(-.3,.3)*size.X,Kit.Random(-.3,.3)*size.Y,Kit.Random(-.3,.3)*size.Z))})
   bits[i]={Part=p,CF=p.CFrame,Vel=Vector3.new(Kit.Random(-6,6),Kit.Random(3,9),Kit.Random(-6,6)),
    Spin=Vector3.new(Kit.Random(-8,8),Kit.Random(-8,8),Kit.Random(-8,8))}
  end
  scope:Every(function(dt:number,age:number)
   local a=math.min(age/.7,1)
   for _,b in ipairs(bits)do
    b.Vel-=up*36*dt
    if b.CF.Position.Y<origin.Y+.15 and b.Vel.Y<0 then b.Vel=Vector3.new(b.Vel.X*.6,-b.Vel.Y*.35,b.Vel.Z*.6)end
    b.CF=(b.CF+b.Vel*dt)*CFrame.Angles(b.Spin.X*dt,b.Spin.Y*dt,b.Spin.Z*dt)
    b.Part.CFrame=b.CF;b.Part.Transparency=a*a
   end
   if a<1 then return true end
   for _,b in ipairs(bits)do b.Part:Destroy()end
   return false
  end)
 end

 -- The duplicates: frozen copies that slide out, glitch, hop a beat late after the real
 -- one (duplicated logic), and shrink to nothing about their middle when deleted.
 local made:{[number]:any}={}
 scope:Every(function()
  local e,now=ctx:Elapsed(),os.clock()
  for _,d in pairs(made)do
   if d.Model.Parent and e<d.Kill then
    local hop=(e-HOP-d.Lag)/.75
    hop=(hop>0 and hop<1)and .45*math.sin(math.pi*hop)or 0
    if not calm and e<d.Mark and now>=d.NextJolt then
     d.Jolt=(side*Kit.Random(-1,1)+fwd*Kit.Random(-1,1))*.2;d.JoltUntil=now+.05;d.NextJolt=now+Kit.Random(.3,.8)
    end
    local jolting=now<d.JoltUntil
    local offset=side*d.Side*5*backOut((e-d.Born)/.32)+up*hop+(jolting and d.Jolt or Vector3.zero)
    d.Model:PivotTo(d.Base+offset);d.Bounds.CFrame=center+offset
    d.Hi.FillTransparency=jolting and .2 or .5
   elseif d.Model.Parent then
    if not d.Dying then d.Dying=true;d.Model.WorldPivot=d.Bounds.CFrame;d.Tag.Gui.Enabled=false end
    local s=1-out3((e-d.Kill)/.15)
    if s<=.03 then d.Model:Destroy();d.Bounds:Destroy();d.Hi:Destroy()
    else d.Model:ScaleTo(s);d.Bounds.Size=size*s end
   end
  end
  return true
 end)

 if live(0)then blip(.8,.35,box);Kit.Cue('Whoosh',box,.18)end
 -- .15: selected.
 if not ctx:Wait(.15)then return end
 outline.Transparency=0;main.Gui.Enabled=true;grab(box)
 if live(.15)then key(.25,1.6)end

 -- 1.3-3.1: the import. Each piece lands with a magenta blink and the next note up.
 for i,name in ipairs(ORDER)do
  local at=IMPORT[name]
  if not ctx:Wait(at)then return end
  local piece=model:FindFirstChild(name,true)
  if live(at)then
   blip(1.4*NOTES[i],.3,box)
   if piece and piece:IsA('BasePart')then
    flash.Adornee=piece;flash.Enabled=true;flashUntil=os.clock()+.12
    scope:Burst(piece.Position,MAGENTA,low and 4 or 10,{Speed=NumberRange.new(2,6),Lifetime=NumberRange.new(.25,.5),Size=NumberSequence.new(.3,0)})
    local spark=SPARK[name]
    if spark then zap(piece,spark)end
   end
  end
 end

 -- 3.4: Ctrl+D, Ctrl+D. The selection moves to each new copy in turn.
 if not ctx:Wait(DUPES[1].Born)then return end
 outline.Transparency=.65;main.Edge.Transparency=1
 if live(DUPES[1].Born)then Kit.Cue('Glitch',box,.25)end
 for i,d in ipairs(DUPES)do
  if not ctx:Wait(d.Born)then return end
  -- (The copies slide out sideways from the dog's real facing.)
  settle()
  local g=Kit.Root(model)and scope:Ghost(model)or nil
  if g and #g:GetChildren()==0 then g:Destroy();g=nil end
  if g then
   local bounds=scope:Part({Name='Bounds',Size=size,CFrame=center,Transparency=1})
   local sel=Instance.new('SelectionBox');sel.Name='Selection';sel.Adornee=bounds;sel.Color3=BLUE;sel.LineThickness=.05
   sel.SurfaceTransparency=1;sel.Parent=bounds
   for _,other in pairs(made)do other.Sel.Transparency=.65;other.Tag.Edge.Transparency=1 end
   made[i]={Model=g,Base=g:GetPivot(),Bounds=bounds,Sel=sel,Tag=tag(bounds,d.Name),Hi=scope:Highlight(g,MAGENTA,MAGENTA,.5,.1),
    Side=d.Side,Born=d.Born,Lag=d.Lag,Mark=d.Mark,Kill=d.Kill,Jolt=Vector3.zero,JoltUntil=0,NextJolt=os.clock()+Kit.Random(.2,.5),Dying=false}
   grab(bounds)
   if live(d.Born)then
    Kit.Cue('Whoosh',bounds,.2)
    scope:Burst(core+side*d.Side*5,MAGENTA,10,{Speed=NumberRange.new(2,6),Lifetime=NumberRange.new(.25,.5),Size=NumberSequence.new(.3,0)})
   end
  end
 end

 -- 4.6: Dog:Finish() is not implemented. Bup-bup; it flickers magenta. The whispers turn
 -- magenta and glitch from here on.
 if not ctx:Wait(ERROR)then return end
 ctx.WhisperStyle={Font=Enum.Font.Code,Color=C(255,150,255),Glitch=.06,Chroma=true,Shake=false,Type=.05}
 if live(ERROR)then
  blip(.62,.42,nil,true);task.delay(.14,blip,.62,.36,nil,true)
  Kit.Cue('Glitch',box,.28)
  local n=near()
  if n>.05 then Kit.Shake(.22*n,.25)end
  local h=scope:Highlight(model,MAGENTA,WHITE,.1,0)
  scope:Every(function(_,age:number)
   if not h.Parent then return false end
   h.Enabled=calm or age<.06 or (age>.12 and age<.2) or age>.26
   h.FillTransparency=.1+.9*smooth((age-.26)/.3)
   h.OutlineTransparency=smooth((age-.26)/.3)
   if age<.6 then return true end
   h:Destroy();return false
  end)
 end
 -- 4.9: it hops (its clip); the copies echo it a beat late.
 if not ctx:Wait(HOP+.4)then return end
 if live(HOP+.4)then
  blip(2.2,.16,box)
  for _,d in pairs(made)do task.delay(d.Lag,blip,2.2,.11,d.Bounds)end
 end

 -- 5.4-6.2: each copy is marked red ("Delete"), then deleted.
 for i,d in ipairs(DUPES)do
  if not ctx:Wait(d.Mark)then return end
  if i==1 then grab(nil)end
  local dupe=made[i]
  if dupe then
   dupe.Sel.Color3=RED;dupe.Sel.Transparency=0;dupe.Hi.FillColor=RED;dupe.Hi.OutlineColor=RED
   dupe.Tag.Label.Text='Delete';dupe.Tag.Label.TextColor3=RED;dupe.Tag.Edge.Color=RED;dupe.Tag.Edge.Transparency=0
   if live(d.Mark)then blip(2.6,.16,dupe.Bounds)end
  end
  if not ctx:Wait(d.Kill)then return end
  if dupe and dupe.Bounds.Parent and live(d.Kill)then
   local at=dupe.Bounds.Position
   Kit.Cue('Whoosh',dupe.Bounds,.22);blip(.5,.32,dupe.Bounds)
   scope:Burst(at,MAGENTA,14,{Speed=NumberRange.new(3,8),Lifetime=NumberRange.new(.25,.5),Size=NumberSequence.new(.35,0)})
   if not low then shatter(at)end
  end
 end

 -- 6.6: Alt+P. It ships: deselected, the editor light off, the textures stream in down
 -- the tongue in a magenta wave (or the baseplate burns away) and the colour comes back.
 if not ctx:Wait(PUBLISH)then return end
 local fresh=live(PUBLISH)
 grab(nil);outline.Transparency=1;main.Gui.Enabled=false
 Kit.Tween(light,.8,{Brightness=0})
 -- The far end of the wave is still tweening at Hold: stop it before the overrides restore.
 local waves={}
 scope:Add(function()for _,t in ipairs(waves)do t:Cancel()end end)
 for _,s in ipairs(stripped)do
  local part=s.Part
  if fresh then
   task.delay(math.abs((part.Position-origin):Dot(fwd))/48,function()
    if not scope.Alive or not part.Parent then return end
    part.Material=s.Material;part.Color=MAGENTA
    table.insert(waves,Kit.Tween(part,.4,{Color=s.Color}))
   end)
  elseif part.Parent then part.Material=s.Material;part.Color=s.Color end
 end
 -- Off the tongue the baseplate flushes magenta and burns away under the ring.
 if plate and plate.Parent then
  if fresh then plate.Color=MAGENTA;Kit.Tween(plate,.55,{Transparency=1})else plate:Destroy()end
 end
 if fresh then
  local n=near()
  grade.Saturation=.2*hue;grade.Brightness=.05*hue;grade.TintColor=WHITE:Lerp(C(255,225,255),hue)
  Kit.Tween(grade,1.1,{Saturation=0,Brightness=0,Contrast=0,TintColor=WHITE},Enum.EasingStyle.Sine)
  Kit.Cue('Chime',nil,.5)
  scope:Ring(origin+up*.12,MAGENTA,1,15,.9,{Thickness=.3})
  if not low then scope:Ring(origin+up*.18,WHITE,.8,9,.55,{Thickness=.16,Alpha=.35,Segments=24})end
  scope:Burst(core,MAGENTA,24,{Speed=NumberRange.new(6,14),Lifetime=NumberRange.new(.3,.7),Size=NumberSequence.new(.4,0)})
  scope:Burst(core,WHITE,12,{Speed=NumberRange.new(4,9),Lifetime=NumberRange.new(.25,.5),Size=NumberSequence.new(.3,0)})
  if n>.05 and not calm then Kit.Flash(MAGENTA,1-.3*n,.35)end
  if n>.2 then Kit.FOVPunch(-4*n,.07,.55)end
  local shine=scope:Highlight(model,MAGENTA,WHITE,.25,0)
  Kit.Tween(shine,.9,{FillTransparency=1,OutlineTransparency=1},Enum.EasingStyle.Sine,Enum.EasingDirection.In)
 else Kit.Tween(grade,.4,{Saturation=0,Brightness=0,Contrast=0,TintColor=WHITE})end

 -- The arrival outlives its Hold until the wave has crossed the whole map (the dog walks
 -- meanwhile; buying it ends everything at once, as for every arrival).
 ctx:Wait(math.max(hold,over))
end

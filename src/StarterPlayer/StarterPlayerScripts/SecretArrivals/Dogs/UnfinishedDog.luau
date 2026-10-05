-- THE UNFINISHED DOG, "DEV BUILD". The stage turns into an editor viewport: the tongue
-- loses its textures, a grid draws itself on the belt and a grey blockout box labelled
-- "Dog (1)" sits there under a move gizmo while an Output window logs warnings. The dog
-- imports piece by piece (each piece flashes missing-texture magenta, the wires spark),
-- gets Ctrl+D'd into two magenta duplicates, throws an error, the duplicates are deleted
-- one by one, and on Alt+P it ships: the textures stream back in and the name comes up.
-- Off the tongue (a Lucky pad, any stand) there is no belt to strip: a grey baseplate
-- spreads under the grid instead and burns away magenta on Alt+P.
local Players=game:GetService('Players')
local UIS=game:GetService('UserInputService')
local C=Color3.fromRGB
local WHITE,GREY,ROW,BLUE,RED=C(255,255,255),C(163,162,165),C(46,46,46),C(13,105,172),C(255,76,76)
local AMBER,GREEN,INK,EDGE=C(255,190,60),C(96,222,120),C(204,204,204),C(72,72,72)
local TICK='rbxasset://sounds/volume_slider.ogg'
-- The pieces import in this order; anything else comes in with the last one.
local ORDER={'Unfinished_Fur_02_Geo','Unfinished_Fur_01_Geo','Unfinished_BlueWire_03_Geo','Unfinished_RedWire_04_Geo','Unfinished_Label_05_Geo'}
local IMPORT:{[string]:number}={Unfinished_Fur_02_Geo=1,Unfinished_Fur_01_Geo=1.4,Unfinished_BlueWire_03_Geo=1.8,
 Unfinished_RedWire_04_Geo=2.1,Unfinished_Label_05_Geo=2.4}
local SPARK:{[string]:Color3}={Unfinished_BlueWire_03_Geo=C(70,160,255),Unfinished_RedWire_04_Geo=C(255,70,70)}
-- A major scale up as the pieces land.
local NOTES={1,9/8,5/4,4/3,3/2}
local DONE,ERROR,PUBLISH=2.4,3.55,5.2
-- Ctrl+D twice. Each duplicate slides out to one side, is marked red, then deleted.
local DUPES={{Side=-1,Born=2.5,Name='Dog (2)',Mark=4.25,Kill=4.4,Lag=.08},{Side=1,Born=2.62,Name='Dog (3)',Mark=4.75,Kill=4.9,Lag=.16}}
local LOG={{At=.6,Kind='warn',Text='[warn] Dog.Texture is nil'},{At=1,Kind='info',Text='Importing Dog.fbx (5 meshes)...'},
 {At=1.9,Kind='warn',Text="Infinite yield possible on 'Tail'"},{At=2.65,Kind='info',Text='Duplicated: Dog (2), Dog (3)'},
 {At=ERROR,Kind='error',Text='[error] Dog:Finish() not implemented'},{At=4.4,Kind='info',Text='Deleted Dog (2)'},
 {At=4.9,Kind='info',Text='Deleted Dog (3)'},{At=PUBLISH,Kind='ok',Text='Published. 1 error, 2 warnings.'}}
local TINT:{[string]:Color3}={info=INK,warn=AMBER,error=RED,ok=GREEN}
-- Keys shown over the Output window, screencast style.
local KEYS={{At=2.45,Text='Ctrl + D'},{At=2.57,Text='Ctrl + D  ×2'},{At=4.4,Text='Del'},{At=4.9,Text='Del'},{At=5.08,Text='Alt + P'}}
local function smooth(x)x=math.clamp(x,0,1);return x*x*(3-2*x)end
local function out3(x)x=math.clamp(x,0,1);return 1-(1-x)^3 end
local function backOut(x)x=math.clamp(x,0,1)-1;local c=1.70158;return 1+(c+1)*x*x*x+c*x*x end
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

return function(ctx:any)
 -- The first line is a code comment; the second (set before it) glitches in magenta.
 ctx.WhisperStyle={Font=Enum.Font.Code,Color=C(106,153,85),Glitch=0,Chroma=false,Shake=false,Type=.045}
 local Kit,scope,model,config=ctx.Kit,ctx.Scope,ctx.Model,ctx.Config
 local low,calm,origin,hold=ctx.Low,Kit.ReducedMotion(),ctx.Origin,config.Hold
 local MAGENTA=config.Color
 local size=Kit.Size(model)
 local up=Vector3.yAxis
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

 -- Editor lighting: flat, a little grey; the music steps back for the clicks.
 scope:Duck(.4,.6)
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
 if onTongue then
  local district=workspace:FindFirstChild('DOGROTS_District')
  local factory=district and district:FindFirstChild('02_DogFactory')
  local tunnel=factory and factory:FindFirstChild('DarkMouthTunnel')
  local line=district and district:FindFirstChild('03_DogLine')
  local tongue=line and line:FindFirstChild('Tongue')
  local shades:{[string]:Color3}={TongueSurface=GREY,TongueTip=GREY,TongueGroove=C(134,133,136),SoftRoundedRim=C(184,183,186),WarmEdgeGuide=C(208,208,212)}
  for _,o in ipairs(tongue and tongue:GetChildren()or {})do
   local shade=shades[o.Name]
   if shade and o:IsA('BasePart')and math.abs((o.Position-origin):Dot(fwd))<30 then strip(o,shade)end
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
  box.Transparency=e<1 and 0 or math.min(1,.5*smooth((e-1)/.12)+.5*smooth((e-1.12)/(DONE-1.12)))
  local k=(e-1)/(DONE+.1-1)
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
 -- Explorer-style name tags over the selection.
 local function tag(adornee:BasePart,name:string)
  local g=Instance.new('BillboardGui');g.Name='ExplorerTag';g.Adornee=adornee;g.AlwaysOnTop=true;g.LightInfluence=0
  g.MaxDistance=220;g.Size=UDim2.fromOffset(108,24);g.StudsOffsetWorldSpace=up*(size.Y/2+1.4)
  local row=frame(g,{Name='Row',Size=UDim2.fromScale(1,1),BackgroundColor3=ROW,BackgroundTransparency=.04})
  round(row,4)
  local edge=Instance.new('UIStroke');edge.Color=BLUE;edge.Thickness=1.5;edge.ApplyStrokeMode=Enum.ApplyStrokeMode.Border;edge.Parent=row
  round(frame(row,{Name='Icon',Size=UDim2.fromOffset(11,11),Position=UDim2.fromOffset(7,6),BackgroundColor3=GREY}),2)
  local label=text(row,{Name='Name',Size=UDim2.new(1,-28,1,0),Position=UDim2.fromOffset(25,0),Font=Enum.Font.SourceSans,TextSize=18,
   TextColor3=WHITE,TextXAlignment=Enum.TextXAlignment.Left,Text=name})
  g.Parent=adornee
  return {Gui=g,Edge=edge,Label=label}
 end
 local main=tag(box,'Dog (1)');main.Gui.Enabled=false
 -- Studio's move tool: one Handles per axis, coloured like it. They follow the selection.
 local gizmo={}
 for _,axis in ipairs({{Color=C(255,72,72),A=Enum.NormalId.Right,B=Enum.NormalId.Left},{Color=C(84,220,96),A=Enum.NormalId.Top,B=Enum.NormalId.Bottom},
  {Color=C(64,144,255),A=Enum.NormalId.Front,B=Enum.NormalId.Back}})do
  local h=Instance.new('Handles');h.Name='DOGROTS_UnfinishedGizmo';h.Style=Enum.HandlesStyle.Movement;h.Faces=Faces.new(axis.A,axis.B)
  h.Color3=axis.Color;h.Visible=false;h.Adornee=box
  if playerGui then h.Parent=playerGui end
  scope:Add(h);table.insert(gizmo,h)
 end
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
    local hop=(e-3.45-d.Lag)/.75
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

 -- 1.0-2.4: the import. Each piece lands with a magenta blink and the next note up.
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

 -- 2.5: Ctrl+D, Ctrl+D. The selection moves to each new copy in turn.
 if not ctx:Wait(2.5)then return end
 outline.Transparency=.65;main.Edge.Transparency=1
 if live(2.5)then Kit.Cue('Glitch',box,.25)end
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

 -- 3.55: Dog:Finish() is not implemented. Bup-bup; it flickers magenta.
 if not ctx:Wait(ERROR)then return end
 if live(ERROR)then
  blip(.62,.42,nil,true);task.delay(.14,blip,.62,.36,nil,true)
  Kit.Cue('Glitch',box,.28)
  local n=near()
  if n>.05 then Kit.Flash(RED,1-.18*n,.2);Kit.Shake(.22*n,.25)end
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
 -- 3.85: it hops (its clip); the copies echo it a beat late.
 if not ctx:Wait(3.85)then return end
 if live(3.85)then
  blip(2.2,.16,box)
  for _,d in pairs(made)do task.delay(d.Lag,blip,2.2,.11,d.Bounds)end
 end

 -- 4.25-4.9: each copy is marked red ("Delete"), then deleted.
 for i,d in ipairs(DUPES)do
  if not ctx:Wait(d.Mark)then return end
  if i==1 then
   grab(nil)
   ctx.WhisperStyle={Font=Enum.Font.Code,Color=C(255,150,255),Glitch=.06,Chroma=true,Shake=false,Type=.05}
  end
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

 -- 5.2: Alt+P. It ships: deselected, the editor light off, the textures stream in down
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
 ctx:Title({Font=Enum.Font.Code,Tier=not ctx.By and 'SECRET · DEV BUILD'or nil,Hold=3.6})
 if fresh then
  local n=near()
  grade.Saturation=.2*hue;grade.Brightness=.05*hue;grade.TintColor=WHITE:Lerp(C(255,225,255),hue)
  Kit.Tween(grade,1.1,{Saturation=0,Brightness=0,Contrast=0,TintColor=WHITE},Enum.EasingStyle.Sine)
  Kit.Cue('Chime',nil,.5);Kit.Cue('Sting',nil,.3)
  scope:Ring(origin+up*.12,MAGENTA,1,15,.9,{Thickness=.3})
  if not low then scope:Ring(origin+up*.18,WHITE,.8,9,.55,{Thickness=.16,Alpha=.35,Segments=24})end
  scope:Burst(core,MAGENTA,24,{Speed=NumberRange.new(6,14),Lifetime=NumberRange.new(.3,.7),Size=NumberSequence.new(.4,0)})
  scope:Burst(core,WHITE,12,{Speed=NumberRange.new(4,9),Lifetime=NumberRange.new(.25,.5),Size=NumberSequence.new(.3,0)})
  if n>.05 then Kit.Flash(MAGENTA,1-.3*n,.35)end
  if n>.2 then Kit.FOVPunch(-4*n,.07,.55)end
  local shine=scope:Highlight(model,MAGENTA,WHITE,.25,0)
  Kit.Tween(shine,.9,{FillTransparency=1,OutlineTransparency=1},Enum.EasingStyle.Sine,Enum.EasingDirection.In)
 else Kit.Tween(grade,.4,{Saturation=0,Brightness=0,Contrast=0,TintColor=WHITE})end

 if not ctx:Wait(hold)then return end
end

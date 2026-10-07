-- Client FX for the gameplay moments of world events: lightning and tremors on the kennels
-- that dig right now, the UFO beam over a tongue dog being abducted, sparkles on the event's
-- variant dogs (Golden Hour, Cursed Fog...). Cosmetic and local; the server decides
-- everything. Low quality (WorldEventFX Low, LowFX, ReducedMotion, touch unless High) is
-- lighter; ReducedMotion gets no camera shake and no light flashes.
local Players=game:GetService('Players');local Run=game:GetService('RunService');local Tween=game:GetService('TweenService');local UIS=game:GetService('UserInputService')
local V=require(script.Parent.WorldEventObjects)
local G={};local player=Players.LocalPlayer;local C=Color3.fromRGB;local rng=Random.new()
local VARIANT={Shiny=C(220,245,255),Golden=C(255,199,54),Corrupted=C(184,67,233),Glitched=C(40,239,213),Void=C(150,90,255)}
local root;local connection;local temporary={};local abductions={};local sparkles={};local watchers={};local sparkleSet;local boostUntil=0
local function low()
 local fx=player:GetAttribute('WorldEventFX')
 return fx=='Low'or player:GetAttribute('LowFX')==true or player:GetAttribute('ReducedMotion')==true or(UIS.TouchEnabled and fx~='High')
end
local function reduced()return player:GetAttribute('ReducedMotion')==true end
local function folder()
 if root and root.Parent then return root end
 root=Instance.new('Folder');root.Name='DOGROTS_EventGameplayFX';root.Parent=workspace;return root
end
local function neon(parent,name,at,size,color,alpha)
 local p=V.Part(parent,name,at,size,color,Enum.Material.Neon);p.Transparency=alpha or 0;return p
end
local function destroyRow(row)
 for _,o in ipairs({row.Model,row.Top,row.Bottom})do if o and o.Parent then o:Destroy()end end
end
local update
local function ensure()if not connection then connection=Run.Heartbeat:Connect(function()update()end)end end
local function track(object,life,step)table.insert(temporary,{Object=object,Born=os.clock(),Life=life,Step=step});ensure()end
-- A ground shockwave that grows without thickening (WorldEventObjects ring helpers).
local function wave(at,color,from,to,life)
 local ring=V.Ring(folder(),from,.55,.22,color,low()and 12 or 24,.15,false,Vector3.xAxis,Vector3.zAxis)
 V.RingSet(ring,at,from)
 track(ring.Model,life,function(age)V.RingSet(ring,at,from+(to-from)*(1-(1-age)^2),.15+.85*age)end)
end
local function popup(at,title,sub,color)
 local anchor=neon(folder(),'StrikeLabel',at+Vector3.new(0,6,0),Vector3.one*.2,color,1)
 local board=Instance.new('BillboardGui');board.Adornee=anchor;board.Size=UDim2.fromOffset(230,58);board.AlwaysOnTop=true;board.MaxDistance=320;board.LightInfluence=0;board.Parent=anchor
 local function text(value,y,h,font)
  local t=Instance.new('TextLabel');t.BackgroundTransparency=1;t.Position=UDim2.fromScale(0,y);t.Size=UDim2.fromScale(1,h);t.Text=value;t.Font=font;t.TextScaled=true
  t.TextColor3=Color3.new(1,1,1);t.TextStrokeColor3=color:Lerp(Color3.new(0,0,0),.6);t.TextStrokeTransparency=0;t.Parent=board;return t
 end
 local a=text(title,0,.6,Enum.Font.GothamBlack);local b=text(sub,.6,.4,Enum.Font.GothamBold)
 track(anchor,2.8,function(age)
  anchor.Position=at+Vector3.new(0,6+age*5,0)
  local alpha=math.clamp((age-.7)/.3,0,1);a.TextTransparency=alpha;b.TextTransparency=alpha;a.TextStrokeTransparency=alpha;b.TextStrokeTransparency=alpha
 end)
end
local function lightning(at,color)
 local m=Instance.new('Model');m.Name='KennelLightning';m.Parent=folder()
 -- ReducedMotion: a soft, see-through bolt with no light flash.
 local count=low()and 5 or 9;local top=at+Vector3.new(rng:NextNumber(-25,25),150,rng:NextNumber(-25,25));local previous=top;local last;local base=reduced()and .5 or .05
 for i=1,count do
  local p=top:Lerp(at,i/count)+(i<count and Vector3.new(rng:NextNumber(-6,6),0,rng:NextNumber(-6,6))or Vector3.zero)
  last=neon(m,'Bolt',(previous+p)/2,Vector3.new(.8,.8,(p-previous).Magnitude),color:Lerp(Color3.new(1,1,1),.55),base)
  last.CFrame=CFrame.lookAt((previous+p)/2,p);previous=p
 end
 track(m,1,function(age)for _,p in ipairs(m:GetChildren())do if p:IsA('BasePart')then p.Transparency=math.clamp(age*2.2-.4,base,1)end end end)
 if last and not reduced()then
  local flash=Instance.new('PointLight');flash.Color=color;flash.Range=40;flash.Brightness=5;flash.Shadows=false;flash.Parent=last
  Tween:Create(flash,TweenInfo.new(.45),{Brightness=0}):Play()
 end
 if last and not low()then
  local e=V.Particles(last,color,0,1.1);e.Speed=NumberRange.new(14,30);e.SpreadAngle=Vector2.new(180,180);e.Lifetime=NumberRange.new(.4,.9);e.LightEmission=1;e:Emit(24)
 end
 wave(at+Vector3.new(0,.35,0),color,2,13,1.1)
end
local function tremor(at,color)
 local dust=neon(folder(),'TremorDust',at+Vector3.new(0,1,0),Vector3.one,color,1)
 local e=V.Particles(dust,C(170,140,110),0,3);e.Texture='rbxasset://textures/particles/smoke_main.dds';e.LightEmission=0
 e.Speed=NumberRange.new(6,14);e.SpreadAngle=Vector2.new(80,80);e.Lifetime=NumberRange.new(1,2);e.Transparency=NumberSequence.new(.5,1);e:Emit(low()and 4 or 14)
 track(dust,2.2)
 wave(at+Vector3.new(0,.35,0),C(255,120,40),3,16,1.4)
 if not low()then
  for i=1,4 do
   local a=i*math.pi/2+rng:NextNumber(-.4,.4);local dir=Vector3.new(math.cos(a),0,math.sin(a))
   local rock=V.Part(folder(),'TremorRock',at,Vector3.new(1.2,1,1.2),C(116,84,60),Enum.Material.Slate);local spin=rng:NextNumber(2,5)
   track(rock,1.1,function(age)rock.CFrame=CFrame.new(at+dir*age*9+Vector3.new(0,math.sin(age*math.pi)*7,0))*CFrame.Angles(age*spin,a,age*3);rock.Transparency=math.max(0,age*2-1)end)
  end
 end
end
local shakeUntil,shakeGain=0,0
local function shake(seconds,gain)
 if reduced()then return end
 shakeUntil=math.max(shakeUntil,os.clock()+seconds);shakeGain=gain
 Run:UnbindFromRenderStep('DOGROTS_EventTremor')
 Run:BindToRenderStep('DOGROTS_EventTremor',Enum.RenderPriority.Camera.Value+4,function()
  local now=os.clock()
  if now>=shakeUntil then Run:UnbindFromRenderStep('DOGROTS_EventTremor');return end
  local camera=workspace.CurrentCamera;if not camera or camera.CameraType==Enum.CameraType.Scriptable then return end
  local g=math.min(shakeUntil-now,1)*shakeGain
  camera.CFrame*=CFrame.new(math.noise(now*18)*g,math.noise(0,now*21)*g,0)*CFrame.Angles(0,0,math.noise(now*13,1)*g*.03)
 end)
end
-- Kennels struck by a pulse: data.Strikes={{UserId,Position,Count}}. Returns this player's.
function G.Strike(data)
 local color=typeof(data.Color)=='Color3'and data.Color or C(184,221,255);local mine
 for i,s in ipairs(type(data.Strikes)=='table'and data.Strikes or {})do
  if typeof(s.Position)=='Vector3'and i<=(low()and 4 or 10)then
   if data.Style=='Tremor'then tremor(s.Position,color)else lightning(s.Position,color)end
  end
  if s.UserId==player.UserId and typeof(s.Position)=='Vector3'then mine=s end
 end
 if mine then popup(mine.Position,'INSTANT DIG!',(mine.Count or 1)..((mine.Count or 1)==1 and ' DOG DIGS NOW'or ' DOGS DIG NOW'),color)end
 -- A tremor shakes the whole map, not only the yards it hit.
 if data.Style=='Tremor'then shake(data.Big and 2.2 or 1.3,data.Big and .55 or .35)end
 return mine
end
local function saucer(color)
 local m=Instance.new('Model');m.Name='AbductorSaucer';m.WorldPivot=CFrame.identity;m.Parent=folder()
 V.Ellipsoid(m,'Hull',Vector3.new(18,3,18),CFrame.new(),C(54,70,78),Enum.Material.Metal)
 V.Ellipsoid(m,'Dome',Vector3.new(7,4.8,7),CFrame.new(0,1.9,0),color,Enum.Material.Glass).Transparency=.25
 V.Ellipsoid(m,'Belly',Vector3.new(9,1,9),CFrame.new(0,-1.4,0),color,Enum.Material.Neon)
 if not low()then for k=1,8 do local a=k*math.pi/4;local p=neon(m,'RimLight',Vector3.new(math.cos(a)*7.8,0,math.sin(a)*7.8),Vector3.one*.9,color);p.Shape=Enum.PartType.Ball end end
 local top,bottom,beam=V.Beam(folder(),Vector3.zero,Vector3.zero,color,2);beam.LightEmission=1;V.Soft(beam,.45,.04,.2)
 if not low()then local e=V.Particles(bottom,color,6,.6);e.Speed=NumberRange.new(4,9);e.Acceleration=Vector3.new(0,10,0);e.SpreadAngle=Vector2.new(60,60)end
 return {Model=m,Top=top,Bottom=bottom,Beam=beam}
end
-- A UFO over a tongue dog: Lock (anyone can still buy it), Lift (it rises into the saucer),
-- Escape (bought in time: the saucer leaves empty-handed).
function G.Abduct(data)
 local target=typeof(data.Target)=='Instance'and data.Target or nil
 local color=typeof(data.Color)=='Color3'and data.Color or C(131,255,169)
 local key=target or 'pending'
 local row=abductions[key]
 if data.Phase=='Escape'then
  if row then row.Phase='Leave';row.PhaseAt=os.clock()end
  return
 end
 if not row then
  if data.Phase~='Lock'and data.Phase~='Lift'then return end
  row=saucer(color);row.Target=target;abductions[key]=row
 end
 row.Phase=data.Phase;row.PhaseAt=os.clock();row.Seconds=tonumber(data.Seconds)or 3
 if typeof(data.Position)=='Vector3'then row.Position=data.Position;if data.Phase=='Lift'then row.LiftFrom=data.Position end end
 ensure()
end
local function abductionStep(key,row,now)
 local target=row.Target;local live=target and target.Parent and target:GetPivot().Position
 if live then row.Position=live end
 local at=row.Position;if not at then destroyRow(row);abductions[key]=nil;return end
 local age=now-row.PhaseAt;local hover;local w0,w1=0,0
 if row.Phase=='Lock'then
  hover=at+Vector3.new(0,24+math.sin(now*3)*.6,0)
  local flicker=reduced()and 1 or .75+.25*math.sin(now*14);w0,w1=2.6*flicker,1.2
  -- Never stuck: no Lift or Escape arrived (streamed out, lost packet).
  if age>row.Seconds+4 then row.Phase='Leave';row.PhaseAt=now end
 elseif row.Phase=='Lift'then
  local u=math.clamp(age/row.Seconds,0,1);local from=row.LiftFrom or at
  if not live then at=from+Vector3.new(0,u*u*55,0);row.Position=at end
  hover=from+Vector3.new(0,30+u*u*40,0);w0,w1=7,5
  if u>=1 and not(target and target.Parent)then row.Phase='Leave';row.PhaseAt=now end
  if age>row.Seconds+3 then row.Phase='Leave';row.PhaseAt=now end
 else
  local u=math.clamp(age/1.4,0,1);local base=row.Hover or at+Vector3.new(0,24,0)
  hover=base+Vector3.new(u*u*140,u*u*90,0)
  if u>=1 then destroyRow(row);abductions[key]=nil;return end
  row.Model:PivotTo(CFrame.new(hover)*CFrame.Angles(0,now*1.5,0));row.Beam.Width0=0;row.Beam.Width1=0
  return
 end
 row.Hover=hover
 row.Model:PivotTo(CFrame.new(hover)*CFrame.Angles(0,now*1.5,0))
 row.Top.Position=hover-Vector3.new(0,1.5,0);row.Bottom.Position=at
 row.Beam.Width0=w0;row.Beam.Width1=w1
end
function update()
 local now=os.clock()
 for i=#temporary,1,-1 do
  local row=temporary[i];local age=(now-row.Born)/row.Life
  if age>=1 or not row.Object.Parent then if row.Object.Parent then row.Object:Destroy()end;table.remove(temporary,i)
  elseif row.Step then row.Step(age)end
 end
 for key,row in pairs(abductions)do abductionStep(key,row,now)end
 if #temporary==0 and next(abductions)==nil and connection then connection:Disconnect();connection=nil end
end
-- Variant sparkles on tongue dogs during the event (Effects.Sparkle).
local function sparkleRate()return(low()and 2 or 6)*(os.clock()<boostUntil and 2.5 or 1)end
local function decorate(dog,tries)
 if not dog:IsA('Model')or sparkles[dog]or not sparkleSet then return end
 local variant=dog:GetAttribute('Variant');if not sparkleSet[variant]then return end
 local part=dog.PrimaryPart or dog:FindFirstChildWhichIsA('BasePart',true)
 -- Still streaming in: try again shortly.
 if not part then if(tries or 0)<3 then task.delay(1,function()if dog.Parent then decorate(dog,(tries or 0)+1)end end)end;return end
 local e=V.Particles(part,VARIANT[variant]or C(255,220,120),sparkleRate(),.5);e.Name='EventVariantSparkle';e.LightEmission=1
 e.Lifetime=NumberRange.new(.6,1.3);e.Speed=NumberRange.new(1,3.5);e.SpreadAngle=Vector2.new(180,180)
 sparkles[dog]=e
end
local function resparkle()for dog,e in pairs(sparkles)do if e.Parent and dog.Parent then e.Rate=sparkleRate()else sparkles[dog]=nil end end end
function G.Begin(def)
 G.Stop()
 local list=def and def.Effects and def.Effects.Sparkle
 if not list then return end
 sparkleSet={};for _,name in ipairs(list)do sparkleSet[name]=true end
 local map=workspace:FindFirstChild('DOGROTS_District');local line=map and map:FindFirstChild('03_DogLine');local active=line and line:FindFirstChild('ActiveDogs')
 if not active then return end
 for _,dog in ipairs(active:GetChildren())do decorate(dog)end
 table.insert(watchers,active.ChildAdded:Connect(function(dog)decorate(dog)end))
 table.insert(watchers,active.ChildRemoved:Connect(function(dog)local e=sparkles[dog];sparkles[dog]=nil;if e and e.Parent then e:Destroy()end end))
 table.insert(watchers,player:GetAttributeChangedSignal('WorldEventFX'):Connect(resparkle))
end
-- The signature moment: variant dogs sparkle harder for its duration (GOLDEN MINUTE).
function G.Signature(def,duration)
 if not sparkleSet then return end
 boostUntil=os.clock()+math.clamp(tonumber(duration)or 10,1,90);resparkle()
 local stamp=boostUntil
 task.delay(stamp-os.clock()+.1,function()if boostUntil==stamp then resparkle()end end)
end
function G.Stop()
 for _,c in ipairs(watchers)do c:Disconnect()end;watchers={}
 for _,e in pairs(sparkles)do if e.Parent then e:Destroy()end end;sparkles={};sparkleSet=nil;boostUntil=0
 for _,row in pairs(abductions)do destroyRow(row)end;abductions={}
 for _,row in ipairs(temporary)do if row.Object.Parent then row.Object:Destroy()end end;temporary={}
 if connection then connection:Disconnect();connection=nil end
 shakeUntil=0;Run:UnbindFromRenderStep('DOGROTS_EventTremor')
 if root then root:Destroy();root=nil end
end
return G

-- Local event choreography. All objects are cosmetic, capped and owned by this module.
local Run=game:GetService('RunService')
local Players=game:GetService('Players')
local Tween=game:GetService('TweenService')
local V=require(script.Parent.WorldEventObjects)
local M={}
local C=Color3.fromRGB
local player=Players.LocalPlayer
local root,def,budget,connection,gui,phaseLabel,menuConnection
local rain,temporary,tints,tweens={},{},{},{}
local sustained={}
local born,finish,lastSurge,lastImpact,shake=0,nil,0,0,0
local nextBeat,beatIndex=0,0
local base=Vector3.zero
local basis=CFrame.identity
local low=false
local rng=Random.new(903)
local phases={BONE_RAIN='EXTINCTION SHOWER',GOLDEN_HOUR='SOLAR ASCENSION',DOG_RUSH='ALPHA STAMPEDE',TREASURE_FEVER='THE VAULT BREAKS',CRYSTAL_STORM='SHATTER THE SKY',EARTHQUAKE='CORE BREACH',TIME_WARP='TIME COLLAPSE',CURSED_FOG='THE GUARDIAN AWAKENS',BLACKOUT='TOTAL ECLIPSE',UFO_INVASION='MOTHERSHIP ARRIVAL',RAINBOW_RIFT='CHROMATIC OVERLOAD',NULL_HOUR='REALITY DELETED',THE_VOID_OPENS='SINGULARITY BREACH'}
local function reduced()return low or player:GetAttribute('ReducedMotion')==true end
local function position()
 local c=player.Character;local h=c and c:FindFirstChild('HumanoidRootPart')
 return h and h.Position or base
end
local function ground(p)
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include
 params.FilterDescendantsInstances={workspace:FindFirstChild('DOGROTS_District')};params.RespectCanCollide=true
 local hit=workspace:Raycast(p+Vector3.new(0,35,0),Vector3.new(0,-150,0),params)
 return hit and hit.Position or Vector3.new(p.X,base.Y-3,p.Z)
end
local function model(name,parent)
 local m=Instance.new('Model');m.Name=name;m.WorldPivot=CFrame.identity;m.Parent=parent or root;return m
end
local function part(parent,name,at,size,color,neon,alpha)
 local p=V.Part(parent,name,at,size,color,neon and Enum.Material.Neon or Enum.Material.SmoothPlastic)
 p.Transparency=alpha or 0;return p
end
local function sphere(parent,name,at,size,color,alpha)
 local p=part(parent,name,at,Vector3.one*size,color,true,alpha);p.Shape=Enum.PartType.Ball;return p
end
local function line(parent,a,b,w,color,alpha)
 local p=part(parent,'Discharge',(a+b)/2,Vector3.new(w,w,(a-b).Magnitude),color,true,alpha)
 p.CFrame=CFrame.lookAt((a+b)/2,b);return p
end
local function track(m,seconds,step)
 table.insert(temporary,{Object=m,Born=os.clock(),Life=seconds,Step=step});return m
end
local function tween(o,seconds,props)
 local t=Tween:Create(o,TweenInfo.new(seconds,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),props)
 table.insert(tweens,{Tween=t,Until=os.clock()+seconds});t:Play();return t
end
-- Shockwave ring: the radius grows six-fold while the band keeps its width
-- (Model:ScaleTo used to thicken it into a wall). Vertical rings face the camera.
local function ring(at,radius,color,life,vertical)
 local U,W=Vector3.xAxis,Vector3.zAxis
 if vertical then U=basis.RightVector;W=Vector3.yAxis end
 local r=V.Ring(root,radius,math.max(.35,radius*.06),math.max(.22,radius*.025),color,low and 16 or 32,.15,false,U,W)
 r.Model.Name='ImpactWave'
 V.RingSet(r,at,radius)
 track(r.Model,life,function(age)V.RingSet(r,at,radius*(1+age*5),.2+age*.8)end)
 return r.Model
end
local function burst(at,color,count,size)
 local p=part(root,'ImpactSparks',at,Vector3.one,color,false,1)
 local e=V.Particles(p,color,0,size or 2)
 e.Lifetime=NumberRange.new(.5,1.5);e.Speed=NumberRange.new(18,60);e.Drag=4;e.Acceleration=Vector3.new(0,-35,0)
 e.SpreadAngle=Vector2.new(180,180);e.LightEmission=1;e.Transparency=NumberSequence.new(.05,1);e:Emit(count)
 track(p,2)
end
local function bolt(a,b,color,width)
 local m=model('SkyLightning');local prev=a
 for i=1,10 do
  local at=a:Lerp(b,i/10)+(i==10 and Vector3.zero or Vector3.new(rng:NextNumber(-12,12),0,rng:NextNumber(-12,12)))
  line(m,prev,at,width or 1.8,color,.05);prev=at
 end
 track(m,.8,function(age)for _,p in ipairs(m:GetChildren())do p.Transparency=age end end)
end
local function beam(at,color,width,life)
 local m=model('HeavenPillar');local top,bot,b=V.Beam(m,at,at+Vector3.new(0,240,0),color,width)
 b.Width1=width*1.3;V.Soft(b,.5,.03,.45);b.LightEmission=1
 local p=part(m,'BeamCore',at+Vector3.new(0,110,0),Vector3.new(width*.08,220,width*.08),color,true,.5)
 local a=Instance.new('PointLight');a.Color=color;a.Range=45;a.Brightness=2;a.Shadows=false;a.Parent=bot
 track(m,life,function(age)
  local strength=math.min(age*8,1)*math.min((1-age)*4,1)
  b.Width0=width*strength;b.Width1=width*1.3*strength;p.Transparency=1-strength*.45
 end)
 return m
end
local function bone(scale,parent)
 local m=model('FallingBone',parent)
 part(m,'Shaft',Vector3.zero,Vector3.new(5,1,1)*scale,C(255,247,215),false)
 for _,x in ipairs({-2.3,2.3})do for _,z in ipairs({-.45,.45})do
  local p=sphere(m,'Knuckle',Vector3.new(x,0,z)*scale,1.6*scale,C(255,247,215));p.Material=Enum.Material.SmoothPlastic
 end end
 return m
end
local function crystal(scale,parent)
 local m=model('CrystalSpear',parent)
 local p=part(m,'Prism',Vector3.zero,Vector3.new(2,7,2)*scale,def.ColorTheme,true,.28)
 p.CFrame=CFrame.Angles(0,math.pi/4,.18)
 for _,side in ipairs({-1,1})do
  local w=Instance.new('WedgePart');w.Name='CrystalFacet';w.Size=Vector3.new(2,3,2)*scale;w.Color=side==1 and C(232,250,255) or C(158,103,255)
  w.Material=Enum.Material.Neon;w.Anchored=true;w.CanCollide=false;w.CanTouch=false;w.CanQuery=false;w.CastShadow=false
  w.CFrame=CFrame.new(0,side*5*scale,0)*CFrame.Angles(side<0 and math.pi or 0,0,0);w.Parent=m
 end
 return m
end
local function coin(scale,parent)
 local m=model('GoldCoin',parent)
 local p=part(m,'Coin',Vector3.zero,Vector3.new(.5,4,4)*scale,C(255,192,25),true);p.Shape=Enum.PartType.Cylinder
 part(m,'Stamp',Vector3.new(.3*scale,0,0),Vector3.new(.1,2,2)*scale,C(255,246,154),true)
 return m
end
local function projectile(kind,scale,parent)
 if kind=='bone' then return bone(scale,parent)
 elseif kind=='crystal' then return crystal(scale,parent)
 elseif kind=='coin' then return coin(scale,parent) end
 local m=model('OrbitFragment',parent)
 part(m,'Fragment',Vector3.zero,Vector3.new(3,2.5,3)*scale,kind=='rock' and C(116,57,33) or def.ColorTheme,kind~='rock')
 -- UFO beams lift these rocks: tractor glow instead of earthquake magma.
 if kind=='rock' then part(m,'Magma',Vector3.new(0,1.28,0)*scale,Vector3.new(2.6,.12,2.6)*scale,def.Id=='UFO_INVASION' and def.ColorTheme or C(255,84,14),true) end
 return m
end
local function trail(m,color,scale)
 local p=m:FindFirstChildWhichIsA('BasePart',true);if not p then return end
 local a=Instance.new('Attachment');a.Position=Vector3.new(-scale,0,0);a.Parent=p
 local b=Instance.new('Attachment');b.Position=Vector3.new(scale,0,0);b.Parent=p
 local t=Instance.new('Trail');t.Attachment0=a;t.Attachment1=b;t.Lifetime=.48;t.MinLength=.2;t.FaceCamera=true
 t.Color=ColorSequence.new(color);t.Transparency=NumberSequence.new(.25,1);t.LightEmission=1;t.Parent=p
end
local function impact(at,big,calm)
 if not root then return end
 local color=def.ColorTheme
 ring(at+Vector3.new(0,.3,0),big and 10 or 2.8,color,big and 2.2 or 1)
 burst(at,color,low and 8 or big and 70 or 14,big and 3 or 1)
 if big then
  if not calm then shake=os.clock()+.8 end
  local count=low and 3 or calm and 5 or 8
  for i=1,count do
   local angle=i*math.pi*2/count;local direction=Vector3.new(math.cos(angle),0,math.sin(angle))
   local m=projectile(def.Id=='CRYSTAL_STORM' and 'crystal' or 'rock',rng:NextNumber(.5,1.2));local spin=rng:NextNumber(1,4)
   track(m,1.6,function(age)m:PivotTo(CFrame.new(at+direction*age*35+Vector3.new(0,math.sin(age*math.pi)*20,0))*CFrame.Angles(age*spin,angle,age*3))end)
  end
 end
end
local function fallingMeteor(kind,at,size,delay,calm)
 local m=projectile(kind,size);trail(m,def.ColorTheme,size*.5)
 local marker=ring(at+Vector3.new(0,.2,0),size*2,def.ColorTheme,delay+1.7)
 local start=at+Vector3.new(-60,200,-50);local hit=false
 track(m,delay+2.9,function(age,seconds)
  local u=math.clamp((seconds-delay)/1.7,0,1)
  if u<1 then m:PivotTo(CFrame.new(start:Lerp(at,u*u))*CFrame.Angles(u*3,seconds,math.pi/4))
  else
   if not hit then hit=true;impact(at,true,calm) end
   for _,p in ipairs(m:GetDescendants())do if p:IsA('BasePart')then p.Transparency=math.clamp((seconds-delay-1.7)/1.2,0,1)end end
  end
 end)
end
-- The title says what the event DOES (Effects.Text); the surge title is its signature
-- moment and what that does (Effects.Signature), so players know why it matters.
local function banner(surge)
 if not gui then return end
 local main=player.PlayerGui:FindFirstChild('ScreenGui')
 if main and main:GetAttribute('OpenMenu')~=nil then return end
 gui.Enabled=true
 local effects=def.Effects;local signature=effects and effects.Signature
 phaseLabel.Text=surge and(signature and signature.Name or phases[def.Id])or def.DisplayName:upper()
 phaseLabel.TextColor3=def.ColorTheme
 phaseLabel.TextTransparency=1
 local sub=phaseLabel:FindFirstChild('Subtitle');sub.Text=surge and(signature and signature.Text or 'SURGE  //  '..def.DisplayName:upper())or def.Subtitle;sub.TextTransparency=1
 local line=phaseLabel:FindFirstChild('Effects');line.Text=surge and '' or(effects and effects.Text or '');line.TextTransparency=1;line.TextStrokeTransparency=1
 tween(phaseLabel,.35,{TextTransparency=0});tween(sub,.5,{TextTransparency=.08});tween(line,.6,{TextTransparency=0,TextStrokeTransparency=.15})
 phaseLabel:SetAttribute('HideAt',os.clock()+(surge and 5 or 6))
end
local function setupUI()
 gui=Instance.new('ScreenGui');gui.Name='DOGROTS_EventCinema';gui.ResetOnSpawn=false;gui.DisplayOrder=95;gui.IgnoreGuiInset=true;gui.Parent=player:WaitForChild('PlayerGui')
 gui.Enabled=false
 local main=player.PlayerGui:FindFirstChild('ScreenGui')
 if main then menuConnection=main:GetAttributeChangedSignal('OpenMenu'):Connect(function()
  if gui and main:GetAttribute('OpenMenu')~=nil then gui.Enabled=false end
 end)end
 phaseLabel=Instance.new('TextLabel');phaseLabel.Name='EventTitle';phaseLabel.BackgroundTransparency=1;phaseLabel.AnchorPoint=Vector2.new(.5,0)
 phaseLabel.Position=UDim2.new(.5,0,.16,0);phaseLabel.Size=UDim2.new(.84,0,0,70);phaseLabel.Font=Enum.Font.GothamBlack;phaseLabel.TextScaled=true;phaseLabel.TextStrokeTransparency=.2;phaseLabel.TextStrokeColor3=C(22,16,36);phaseLabel.Parent=gui
 local limit=Instance.new('UITextSizeConstraint');limit.MaxTextSize=34;limit.MinTextSize=16;limit.Parent=phaseLabel
 local sub=Instance.new('TextLabel');sub.Name='Subtitle';sub.BackgroundTransparency=1;sub.Position=UDim2.fromScale(0,1);sub.Size=UDim2.new(1,0,0,32);sub.TextWrapped=true
 sub.Font=Enum.Font.GothamBold;sub.TextSize=16;sub.TextColor3=C(255,255,255);sub.TextStrokeTransparency=.3;sub.TextScaled=true;sub.Parent=phaseLabel
 local subLimit=Instance.new('UITextSizeConstraint');subLimit.MaxTextSize=16;subLimit.MinTextSize=11;subLimit.Parent=sub
 -- What the event does, on a dark stroke in the event's colour.
 local line=Instance.new('TextLabel');line.Name='Effects';line.BackgroundTransparency=1;line.Position=UDim2.new(0,0,1,36);line.Size=UDim2.new(1,0,0,28);line.TextWrapped=true
 line.Font=Enum.Font.GothamBlack;line.TextScaled=true;line.TextColor3=C(255,255,255);line.TextStrokeColor3=def.ColorTheme:Lerp(C(0,0,0),.55);line.TextStrokeTransparency=.15;line.Text='';line.Parent=phaseLabel
 local lineLimit=Instance.new('UITextSizeConstraint');lineLimit.MaxTextSize=20;lineLimit.MinTextSize=11;lineLimit.Parent=line
end
local function surge()
 if not root or finish or os.clock()-lastSurge<5 then return end
 lastSurge=os.clock();banner(true);local id=def.Id;local c=def.ColorTheme;local center=ground(position())
 local count=low and 2 or 4
 if id=='BONE_RAIN' then
  for i=1,count do local at=ground(position()+basis:VectorToWorldSpace(Vector3.new((i-(count+1)/2)*20,0,-35-math.abs(i-(count+1)/2)*14)))
   fallingMeteor('bone',at,i==math.ceil(count/2) and 5 or 2.5,i*.25)
  end
 elseif id=='GOLDEN_HOUR' or id=='TREASURE_FEVER' then
  for i=1,count+2 do local a=i*math.pi*2/(count+2);local at=ground(center+Vector3.new(math.cos(a)*65,0,math.sin(a)*65))
   beam(at,C(255,213,55),16,6);ring(at+Vector3.new(0,.2,0),8,C(255,207,40),3);burst(at,C(255,233,133),low and 12 or 50,2)
   if id=='TREASURE_FEVER' then fallingMeteor('coin',at,3,i*.2) end
  end
  ring(center+Vector3.new(0,.6,0),35,c,4)
 elseif id=='CRYSTAL_STORM' then
  for i=1,count+2 do local a=i*math.pi*2/(count+2);local at=ground(center+Vector3.new(math.cos(a)*85,0,math.sin(a)*85))
   local m=crystal(1.7+(i%3)*.45);track(m,7,function(age)m:PivotTo(CFrame.new(at+Vector3.new(0,math.min(age*10,1)*28-8,0))*CFrame.Angles(.12,a,.2));for _,p in ipairs(m:GetChildren())do if p:IsA('BasePart')then p.Transparency=age>.75 and (age-.75)*4 or .1 end end end)
   bolt(at+Vector3.new(0,220,0),at,C(207,228,255),2.5);impact(at,false)
  end
  shake=os.clock()+1.2
 elseif id=='EARTHQUAKE' then
  local m=model('MagmaFaults')
  for i=1,count do local a=i*math.pi*2/count;local prev=center+Vector3.new(0,.25,0)
   for j=1,7 do local raw=center+Vector3.new(math.cos(a)*j*22,0,math.sin(a)*j*22)+Vector3.new(rng:NextNumber(-6,6),0,rng:NextNumber(-6,6))
    local at=ground(raw)+Vector3.new(0,.24,0);line(m,prev,at,2.3,C(255,89,13),.05);prev=at
   end
   fallingMeteor('rock',ground(center+Vector3.new(math.cos(a)*85,0,math.sin(a)*85)),3,i*.15)
  end
  track(m,7,function(age)if age>.65 then for _,p in ipairs(m:GetChildren())do p.Transparency=(age-.65)/.35 end end end)
  ring(center,22,C(255,106,21),3);shake=os.clock()+3
 elseif id=='UFO_INVASION' then
  for i=1,count do local a=i*math.pi*2/count;local at=ground(center+Vector3.new(math.cos(a)*75,0,math.sin(a)*75))
   beam(at,c,26,7);ring(at,14,c,4)
   for j=1,3 do local m=projectile('rock',.7);track(m,6,function(age)m:PivotTo(CFrame.new(at+Vector3.new(math.sin(age*10+j)*7,age*180,math.cos(age*10+j)*7))*CFrame.Angles(age*4,j,age*3))end)end
  end
 elseif id=='TIME_WARP' then
  for i=1,4 do ring(center+Vector3.new(0,i*16,0),25+i*8,c,4)end
  local m=model('FrozenTimeline')
  for i=1,(low and 12 or 32)do local a=i*math.pi*2/(low and 12 or 32);local at=center+Vector3.new(math.cos(a)*85,30+math.sin(a*3)*18,math.sin(a)*85)
   line(m,at,at+Vector3.new(0,12,0),2,c,0)
  end
  track(m,4,function(age)for _,p in ipairs(m:GetChildren())do p.Transparency=age>.6 and (age-.6)/.4 or 0 end end)
 elseif id=='RAINBOW_RIFT' then
  for i=1,count+2 do local a=i*math.pi*2/(count+2);local at=ground(center+Vector3.new(math.cos(a)*65,0,math.sin(a)*65));local col=Color3.fromHSV(i/(count+2),.8,1)
   beam(at,col,12,5);burst(at,col,low and 12 or 70,2.5)
  end
  for i=1,4 do ring(center+Vector3.new(0,.2*i,0),15+i*10,Color3.fromHSV(i/5,.8,1),3.5)end
 elseif id=='DOG_RUSH' then
  for i=1,count+2 do
   local at=ground(center+basis:VectorToWorldSpace(Vector3.new((i-(count+3)/2)*10,0,-40)))
   beam(at,C(255,190,55),8,3);burst(at,c,low and 10 or 30,2)
  end
  for i=1,3 do ring(center+Vector3.new(0,.25*i,0),i*15,c,3)end
  shake=os.clock()+1.5
 elseif id=='CURSED_FOG' then
  for i=1,count do local a=i*math.pi*2/count;local at=center+Vector3.new(math.cos(a)*100,35+math.sin(a)*10,math.sin(a)*100)
   local m=model('EyesInTheMist')
   for _,side in ipairs({-1,1})do V.Ellipsoid(m,'WatchingEye',Vector3.new(3,1.5,2),CFrame.new(side*4,0,0),C(255,57,111),Enum.Material.Neon)end
   m:PivotTo(CFrame.lookAt(at,center+Vector3.new(0,35,0)))
   track(m,8,function(age)for _,p in ipairs(m:GetChildren())do p.Transparency=1-math.sin(age*math.pi)*.95 end end)
   beam(ground(at),C(174,33,255),9,5)
  end
 elseif id=='BLACKOUT' then
  for i=1,count do local a=i*math.pi*2/count;local at=ground(center+Vector3.new(math.cos(a)*100,0,math.sin(a)*100));bolt(at+Vector3.new(-30,210,0),at,C(116,163,255),3);burst(at,c,30,2)end
  ring(center+Vector3.new(0,20,0),35,c,3,true);shake=os.clock()+.8
 else
  local focus=center+basis:VectorToWorldSpace(Vector3.new(0,70,-115))
  for i=1,count+3 do local a=i*math.pi*2/(count+3);local at=ground(center+Vector3.new(math.cos(a)*110,0,math.sin(a)*110));bolt(at,focus,c,2)
   local m=projectile('error',2);track(m,5,function(age)local r=(1-age)*120;m:PivotTo(CFrame.new(focus+Vector3.new(math.cos(a+age*8)*r,(1-age)*-55,math.sin(a+age*8)*r))*CFrame.Angles(age*5,a,age*3))end)
  end
  ring(focus,25,c,4,true);shake=os.clock()+1.5
 end
end
-- The sustained layer lasts for the complete ACTIVE state. Beats are staggered,
-- so there is always action without replaying an opening explosion or title.
local function continuous(step)table.insert(sustained,step)end
local function setupSustained()
 local id,c=def.Id,def.ColorTheme
 local columns=id=='GOLDEN_HOUR' or id=='TREASURE_FEVER' or id=='UFO_INVASION' or id=='RAINBOW_RIFT'
 if columns then
  local count=low and 2 or id=='UFO_INVASION' and 3 or 4
  local ufo=id=='UFO_INVASION'
  for i=1,count do
   local col=id=='RAINBOW_RIFT' and Color3.fromHSV(i/count,.7,1) or c
   local m=model('SustainedLightColumn')
   local top,bottom,b=V.Beam(m,base,base+Vector3.new(0,200,0),col,10)
   local width=ufo and 15 or 5.5
   V.Soft(b,ufo and .7 or .6,.03,ufo and .2 or .5);b.LightEmission=1
   local core=Instance.new('Beam');core.Attachment0=b.Attachment0;core.Attachment1=b.Attachment1;core.FaceCamera=true;core.Segments=1
   core.Color=ColorSequence.new(col:Lerp(Color3.new(1,1,1),.45));core.LightEmission=1;core.LightInfluence=0;V.Soft(core,.25,.03,.55);core.Parent=bottom
   local emitter=V.Particles(bottom,col,low and 3 or 9,1.5)
   emitter.Speed=NumberRange.new(8,20);emitter.Acceleration=Vector3.new(0,12,0);emitter.Lifetime=NumberRange.new(2,4)
   local saucer
   if ufo then
    saucer=model('AbductorSaucer',m)
    V.Ellipsoid(saucer,'SaucerHull',Vector3.new(17,2.8,17),CFrame.new(),C(54,70,78),Enum.Material.Metal)
    V.Ellipsoid(saucer,'SaucerDome',Vector3.new(6.5,4.5,6.5),CFrame.new(0,1.8,0),col,Enum.Material.Glass).Transparency=.25
    V.Ellipsoid(saucer,'SaucerBelly',Vector3.new(9,1,9),CFrame.new(0,-1.3,0),col,Enum.Material.Neon)
    for k=1,8 do local a=k*math.pi/4;sphere(saucer,'SaucerLight',Vector3.new(math.cos(a)*7.4,0,math.sin(a)*7.4),.9,col)end
   end
   local at=base;local sampleAt=0
   continuous(function(t,alpha,now)
    local a=i*math.pi*2/count+t*(reduced() and .02 or .045)
    if now>sampleAt then
     at=ground(position()+basis:VectorToWorldSpace(Vector3.new(math.cos(a)*150,0,math.sin(a)*110-40)))
     sampleAt=now+.15
    end
    local height=ufo and 118+math.sin(t*.8+i)*4 or 230
    bottom.Position=at;top.Position=at+Vector3.new(0,height,0)
    local pulse=.85+.15*math.sin(t*.6+i*1.7)
    b.Width0=width*pulse*alpha;b.Width1=(ufo and 4.5 or width*1.6)*alpha
    core.Width0=(ufo and 2.4 or 1.1)*alpha;core.Width1=(ufo and 1.2 or .5)*alpha
    emitter.Rate=(low and 3 or 9)*alpha
    if saucer then
     saucer:PivotTo(CFrame.new(at+Vector3.new(0,height+1.4,0))*CFrame.Angles(0,t*.7+i,0))
     for _,p in ipairs(saucer:GetDescendants())do if p:IsA('BasePart')then p.LocalTransparencyModifier=1-alpha end end
    end
   end)
  end
 elseif id=='EARTHQUAKE' then
  local m=model('LivingMagmaFaults');local lines={};local center=ground(position())
  for i=1,(low and 4 or 7)do
   local a=i*2.39996;local prev=center+Vector3.new(math.cos(a)*18,.25,math.sin(a)*18)
   for j=1,6 do
    local at=ground(center+Vector3.new(math.cos(a)*j*23+math.sin(j*2+i)*7,0,math.sin(a)*j*23))+Vector3.new(0,.24,0)
    table.insert(lines,line(m,prev,at,1.6,c,.3));prev=at
   end
  end
  continuous(function(t,alpha)
   local pos=position()
   if (pos-center).Magnitude>75 then
    local nextCenter=ground(pos);m:PivotTo(m:GetPivot()+nextCenter-center);center=nextCenter
   end
   for i,p in ipairs(lines)do p.Transparency=1-alpha*(.58+.16*math.sin(t*1.6-i*.55))end
  end)
 elseif id=='CURSED_FOG' then
  local count=low and 3 or 6
  for i=1,count do
   local m=model('PersistentWatcher');local eyes={}
   for _,side in ipairs({-1,1})do
    local p=V.Ellipsoid(m,'WatchingEye',Vector3.new(3,1.4,2),CFrame.new(side*3.6,0,0),C(255,73,119),Enum.Material.Neon);table.insert(eyes,p)
   end
   continuous(function(t,alpha)
    local a=i*math.pi*2/count+t*.015
    local at=position()+Vector3.new(math.cos(a)*90,22+math.sin(t*.25+i)*9,math.sin(a)*90)
    m:PivotTo(CFrame.lookAt(at,position()+Vector3.new(0,18,0)))
    for _,p in ipairs(eyes)do p.Transparency=1-alpha*(.3+.6*(.5+.5*math.sin(t*.65+i*2)))end
   end)
  end
 end
end
local beatIntervals={BONE_RAIN=1.8,GOLDEN_HOUR=2.4,DOG_RUSH=1.7,TREASURE_FEVER=1.8,CRYSTAL_STORM=1.7,EARTHQUAKE=2.1,TIME_WARP=2.5,CURSED_FOG=2.8,BLACKOUT=1.6,UFO_INVASION=2.4,RAINBOW_RIFT=2.2,NULL_HOUR=1.7,THE_VOID_OPENS=1.8}
local function beat()
 if not root or finish then return end
 beatIndex+=1;root:SetAttribute('SustainedBeats',beatIndex)
 local t=os.clock()-born;local id,c=def.Id,def.ColorTheme
 local center=ground(position())
 local a=beatIndex*2.39996
 local at=ground(position()+basis:VectorToWorldSpace(Vector3.new(math.sin(a)*80,0,-55-math.cos(a)*35)))
 local crest=beatIndex%4==0
 if id=='BONE_RAIN' then
  fallingMeteor('bone',at,crest and 3.4 or 2.2,0,not crest)
 elseif id=='GOLDEN_HOUR' then
  ring(at+Vector3.new(0,.4,0),12,C(255,218,101),3.4)
  burst(at,C(255,236,164),low and 8 or 25,1.7)
 elseif id=='TREASURE_FEVER' then
  for i=1,(low and 2 or 5)do
   local m=coin(.8+i*.15);local offset=Vector3.new(math.sin(i*2.4)*15,0,math.cos(i*2.4)*15)
   track(m,4,function(age)m:PivotTo(CFrame.new(at+offset*age*2+Vector3.new(0,8+math.sin(age*math.pi)*42,0))*CFrame.Angles(age*7,i,age*2))end)
  end
  ring(at,6,c,2.5);burst(at,c,low and 8 or 22,1.5)
 elseif id=='CRYSTAL_STORM' then
  local m=crystal(crest and 4 or 2.8)
  track(m,6,function(age)
   local growth=math.min(age*7,1);local sink=math.max(0,(age-.7)/.3)
   m:PivotTo(CFrame.new(at+Vector3.new(0,-25+growth*45-sink*28,0))*CFrame.Angles(.1,a,.18))
   for _,p in ipairs(m:GetChildren())do if p:IsA('BasePart')then p.Transparency=.12+sink*.88 end end
  end)
  if not reduced() or crest then bolt(at+Vector3.new(0,170,0),at,c,1.4)end
  ring(at,6,c,2)
 elseif id=='EARTHQUAKE' then
  local m=projectile('rock',crest and 4 or 2.5)
  track(m,4.5,function(age)
   m:PivotTo(CFrame.new(at+Vector3.new(age*16-8,math.sin(age*math.pi)*30-3,0))*CFrame.Angles(age*5,a,age*2))
  end)
  ring(at,9,c,3);burst(at,c,low and 5 or 18,2)
  if crest then shake=os.clock()+.5 end
 elseif id=='TIME_WARP' then
  ring(at+Vector3.new(0,10,0),16,c,4,true)
  local m=model('PassingTimeSlice')
  for i=1,(low and 6 or 12)do local theta=i*math.pi/6
   local p=at+Vector3.new(math.cos(theta)*28,24+math.sin(theta)*28,0)
   line(m,p,p+Vector3.new(0,5,0),.8,c,.3)
  end
  track(m,4,function(age)for _,p in ipairs(m:GetChildren())do p.Transparency=.25+age*.75 end end)
 elseif id=='CURSED_FOG' then
  local p=part(root,'TravellingMist',at+Vector3.new(0,5,0),Vector3.one,c,false,1)
  local e=V.Particles(p,C(135,128,153),0,22);e.Texture='rbxasset://textures/particles/smoke_main.dds';e.LightEmission=.08
  e.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.3,.82),NumberSequenceKeypoint.new(1,1)})
  e.Speed=NumberRange.new(10,18);e.Lifetime=NumberRange.new(4,6);e:Emit(low and 3 or 8);track(p,7)
 elseif id=='BLACKOUT' then
  bolt(at+Vector3.new(-20,190,0),at,C(145,180,255),crest and 2.3 or 1.2)
  burst(at,c,low and 4 or 14,1.5)
 elseif id=='UFO_INVASION' then
  local m=projectile('rock',1.5);trail(m,c,.7)
  track(m,6,function(age)m:PivotTo(CFrame.new(at+Vector3.new(math.sin(age*7)*6,age*180,math.cos(age*7)*6))*CFrame.Angles(age*3,a,age*4))end)
  ring(at,8,c,3)
 elseif id=='RAINBOW_RIFT' then
  local col=Color3.fromHSV((t*.035)%1,.75,1)
  ring(at+Vector3.new(0,18,0),14,col,3.8,true);burst(at,col,low and 6 or 18,1.5)
 elseif id=='DOG_RUSH' then
  local lane=basis:VectorToWorldSpace(Vector3.new((beatIndex%4-1.5)*16,0,0))
  local m=model('StampedeWake');local start=ground(center+lane+basis:VectorToWorldSpace(Vector3.new(0,0,85)))+Vector3.new(0,.3,0)
  local direction=basis:VectorToWorldSpace(Vector3.new(0,0,-1))
  for i=1,3 do line(m,start+Vector3.new(i*1.5,0,0),start+Vector3.new(i*1.5,0,0)+direction*18,.5,c,.45)end
  track(m,3,function(age)m:PivotTo(CFrame.new(direction*age*175));for _,p in ipairs(m:GetChildren())do p.Transparency=.3+age*.7 end end)
 else
  local focus=position()+basis:VectorToWorldSpace(Vector3.new(0,65,-120))
  local m=projectile('error',crest and 3 or 1.8);trail(m,c,1)
  track(m,5,function(age)
   local r=(1-age)*100;local theta=a+age*7
   m:PivotTo(CFrame.new(focus+Vector3.new(math.cos(theta)*r,(1-age)*-50,math.sin(theta)*r))*CFrame.Angles(age*6,a,age*4))
  end)
  if crest then bolt(at,focus,c,1.3)end
 end
end
function M.Signature()surge()end
function M.Begin(event,state,quality)
 M.Stop();def=event;budget=quality;low=quality.Debris<=8;born=os.clock();finish=nil;lastSurge=born-30;lastImpact=0
 base=position();local cam=workspace.CurrentCamera;local look=cam and cam.CFrame.LookVector or Vector3.new(0,0,-1)
 look=Vector3.new(look.X,0,look.Z);if look.Magnitude<.1 then look=Vector3.new(0,0,-1)end
 basis=CFrame.lookAt(Vector3.zero,look.Unit)
 root=Instance.new('Folder');root.Name='DOGROTS_Cataclysm';root.Parent=workspace
 root:SetAttribute('Event',def.Id);root:SetAttribute('Version',3);root:SetAttribute('SustainedBeats',0)
 setupUI();banner(false)
 setupSustained();nextBeat=born+1.5;beatIndex=0
 local id=def.Id
 local kind=id=='BONE_RAIN' and 'bone' or id=='CRYSTAL_STORM' and 'crystal' or (id=='GOLDEN_HOUR' or id=='TREASURE_FEVER') and 'coin' or (id=='EARTHQUAKE' or id=='UFO_INVASION') and 'rock' or 'error'
 local count=low and 8 or quality.Debris<=24 and 22 or 42
 if id=='DOG_RUSH' or id=='CURSED_FOG' then count=0
 elseif id=='GOLDEN_HOUR' or id=='EARTHQUAKE' or id=='UFO_INVASION' then count=math.ceil(count*.55)end
 for i=1,count do
  local scale=kind=='bone' and (i%7==0 and 1.4 or .65) or kind=='crystal' and .55 or .8
  local m=projectile(kind,scale);trail(m,def.ColorTheme,scale*.5)
  local a=i*2.39996;local r=35+(i%9)*12
  table.insert(rain,{Model=m,Index=i,Offset=Vector3.new(math.cos(a)*r,0,math.sin(a)*r),Ground=ground(base+Vector3.new(math.cos(a)*r,0,math.sin(a)*r)),Last=0})
 end
 local map=workspace:FindFirstChild('DOGROTS_District')
 local tint=id=='GOLDEN_HOUR' and C(255,201,50) or id=='CRYSTAL_STORM' and C(104,186,247) or id=='CURSED_FOG' and C(104,44,151) or id=='EARTHQUAKE' and C(201,93,30) or id=='UFO_INVASION' and C(36,181,130) or id=='NULL_HOUR' and C(80,70,104) or id=='THE_VOID_OPENS' and C(80,33,144)
 if map and tint then
  for _,p in ipairs(map:GetDescendants())do if p:IsA('BasePart') and p:GetAttribute('EventTintSurface')then
   tints[p]=p.Color;tween(p,3,{Color=p.Color:Lerp(tint,id=='GOLDEN_HOUR' and .72 or .6)})
  end end
 end
 local acc=0
 connection=Run.Heartbeat:Connect(function(dt)
  acc+=dt;if acc<(low and .066 or .033)then return end;acc=0
  local now=os.clock();local elapsed=now-born;local pos=position()
  local activeAlpha=math.min(elapsed/3,1)*(finish and math.max(0,1-(now-finish)/3)or 1)
  for _,step in ipairs(sustained)do step(elapsed,activeAlpha,now)end
  if not finish and now>=nextBeat then
   beat()
   -- Gentle alternating intensity, with no quiet gap after the opening.
   nextBeat=now+(beatIntervals[id]or 2)*(low and 1.7 or 1)*(1+.16*math.sin(elapsed*.18))
  end
  if phaseLabel and now>(phaseLabel:GetAttribute('HideAt')or 0) and gui.Enabled then
   local a=math.clamp((now-phaseLabel:GetAttribute('HideAt'))/.8,0,1);phaseLabel.TextTransparency=a
   local sub,line=phaseLabel:FindFirstChild('Subtitle'),phaseLabel:FindFirstChild('Effects')
   if sub then sub.TextTransparency=a end;if line then line.TextTransparency=a;line.TextStrokeTransparency=math.max(a,.15)end
   if a==1 then gui.Enabled=false end
  end
  for i=#temporary,1,-1 do local row=temporary[i];local age=(now-row.Born)/row.Life
   if age>=1 or not row.Object.Parent then row.Object:Destroy();table.remove(temporary,i)
   elseif row.Step then row.Step(age,now-row.Born)end
  end
  for i=#tweens,1,-1 do if now>tweens[i].Until then table.remove(tweens,i)end end
  for _,row in ipairs(rain)do
   local i=row.Index;local speed=reduced() and .4 or 1
   local cycle=(elapsed*(kind=='bone' and 65 or 37)*speed+i*23)%160
   if finish then
    for _,p in ipairs(row.Model:GetDescendants())do if p:IsA('BasePart')then p.Transparency=math.clamp((now-finish)/2,0,1)end end
   else
    if cycle<row.Last or (pos-base).Magnitude>80 then row.Ground=ground(pos+row.Offset)end
    local at
    if id=='THE_VOID_OPENS' or id=='NULL_HOUR' or id=='TIME_WARP' then
     local a=i*2.4+elapsed*.3*speed;local r=45+i%7*14
     at=pos+Vector3.new(math.cos(a)*r,20+cycle*.65,math.sin(a)*r)
    elseif id=='GOLDEN_HOUR' or id=='RAINBOW_RIFT' or id=='UFO_INVASION' then
     at=row.Ground+Vector3.new(math.sin(elapsed+i)*5,cycle*.6,math.cos(elapsed+i)*5)
    else at=row.Ground+Vector3.new(0,160-cycle,0)end
    row.Model:PivotTo(CFrame.new(at)*CFrame.Angles(elapsed*speed,i,elapsed*.7*speed))
    if cycle<row.Last and (kind=='bone' or kind=='crystal' or kind=='rock') and now-lastImpact>(low and 1.2 or .25)then
     lastImpact=now;impact(row.Ground,false)
    end
    row.Last=cycle
   end
  end
  base=pos
 end)
 Run:BindToRenderStep('DOGROTS_CataclysmCamera',Enum.RenderPriority.Camera.Value+3,function()
  if not root or reduced() or os.clock()>shake then return end
  local camera=workspace.CurrentCamera;if not camera or camera.CameraType==Enum.CameraType.Scriptable then return end
  local t=os.clock();local gain=math.min(shake-t,1)*.32
  camera.CFrame*=CFrame.new(math.noise(t*20)*gain,math.noise(0,t*23)*gain,0)*CFrame.Angles(0,0,math.noise(t*14)*gain*.025)
 end)
end
function M.End()
 finish=os.clock()
 for p,color in pairs(tints)do if p.Parent then tween(p,3,{Color=color})end end
end
function M.Stop()
 if connection then connection:Disconnect();connection=nil end
 Run:UnbindFromRenderStep('DOGROTS_CataclysmCamera')
 for _,row in ipairs(tweens)do row.Tween:Cancel()end
 for p,color in pairs(tints)do if p.Parent then p.Color=color end end
 if root then root:Destroy();root=nil end
 if menuConnection then menuConnection:Disconnect();menuConnection=nil end
 if gui then gui:Destroy();gui=nil end
 def=nil;rain={};temporary={};tints={};tweens={};sustained={};finish=nil;shake=0;nextBeat=0;beatIndex=0
end
return M

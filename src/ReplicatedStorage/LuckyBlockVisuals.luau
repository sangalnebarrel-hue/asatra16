local C=require(script.Parent.LuckyBlockConfig)
local V={}
local steel=Color3.fromRGB(112,126,134);local black=Color3.fromRGB(19,22,32);local gold=Color3.fromRGB(224,153,43)
function V.Build(tier)
 local rank=C.Rank(tier)or 1;local color=C.VisualConfig.Colors[rank]
 local common=rank==C.Rank('Common');local legendary=rank==C.Rank('Legendary')
 local mythic=rank==C.Rank('Mythic');local secret=rank==C.Rank('Secret')
 local m=Instance.new('Model');m.Name=tier..'LuckyBlock';m:SetAttribute('LuckyVisual',true);m:SetAttribute('LuckyRank',rank)
 local function part(n,cf,size,col,material)
  local p=Instance.new('Part');p.Name=n;p.Size=size;p.CFrame=typeof(cf)=='Vector3'and CFrame.new(cf)or cf;p.Color=col
  p.Material=material or Enum.Material.Metal;p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.CastShadow=false;p.Parent=m;return p
 end
 local function cube(n,x,y,z,w,h,d,col,mat)return part(n,Vector3.new(x,y,z),Vector3.new(w,h,d),col,mat)end
 local frame=common and steel or legendary and gold or mythic and gold or color:Lerp(black,.58)
 local body=common and Color3.fromRGB(117,113,108)or legendary and Color3.fromRGB(114,73,20)or color:Lerp(black,.79)
 if secret then body=Color3.fromRGB(10,8,18);frame=Color3.fromRGB(32,22,45)end
 local core=cube('RootPart',0,0,0,5.45,5.45,5.45,body);m.PrimaryPart=core
 -- Three intersecting straps at each corner create a recognizable reinforced crate family.
 for _,x in {-1,1}do for _,y in {-1,1}do for _,z in {-1,1}do
  cube('CornerX',x*2.27,y*2.62,z*2.62,1.28,.64,.62,frame)
  cube('CornerY',x*2.62,y*2.27,z*2.62,.64,1.28,.66,frame)
  cube('CornerZ',x*2.62,y*2.62,z*2.27,.62,.62,1.28,frame)
  cube('Rivet',x*2.71,y*2.71,z*2.71,.24,.24,.24,rank>=C.Rank('Legendary') and Color3.fromRGB(255,227,153)or Color3.fromRGB(170,177,180))
 end end end
 for i=0,3 do
  local face=CFrame.Angles(0,i*math.pi/2,0)
  local panelColor=mythic and Color3.fromHSV(i/4,.72,.86)or body:Lerp(color,.13)
  part('InsetPanel',face*CFrame.new(0,0,-2.74),Vector3.new(3.95,3.95,.16),panelColor)
  for _,y in {-2.13,2.13}do part('LuminousSeam',face*CFrame.new(0,y,-2.83),Vector3.new(3.9,.10,.09),color,rank==1 and Enum.Material.Metal or Enum.Material.Neon)end
  -- Raised voxel question mark, readable from all four sides even without UI assets.
  for _,s in {{-.1,1.14,1.22,.36},{.65,.64,.38,1.12},{.29,.15,1.0,.36},{-.04,-.24,.35,.60},{-.04,-1.12,.42,.42}}do
   part('QuestionRelief',face*CFrame.new(s[1],s[2],-2.89),Vector3.new(s[3],s[4],.20),rank==1 and Color3.fromRGB(229,225,215)or color,rank==1 and Enum.Material.Metal or Enum.Material.Neon)
  end
  if mythic then
   for j=1,3 do part('HeatVent',face*CFrame.new(-1.57,(j-2)*.6,-2.87),Vector3.new(.16,.3,.1),Color3.fromRGB(255,61,24),Enum.Material.Neon)end
  end
 end
 cube('Lid',0,2.77,0,4.4,.18,4.4,mythic and Color3.fromRGB(101,218,241)or frame)
 for _,s in {{0,.65,1.4,1.1},{-.95,-.3,.62,.72},{-.34,-.8,.6,.65},{.34,-.8,.6,.65},{.95,-.3,.62,.72}}do
  cube('PawSeal',s[1],2.9,s[2],s[3],.15,s[4],rank==1 and Color3.fromRGB(63,65,67)or color,rank>=3 and Enum.Material.Neon or Enum.Material.Metal)
 end
 if legendary then
  for _,x in {-1,1}do for _,z in {-1,1}do cube('GoldenFoot',x*2.3,-2.9,z*2.3,.7,.2,.7,gold)end end
 elseif mythic then
  for i=0,7 do
   local a=i*math.pi/4;local pos=Vector3.new(math.cos(a)*1.65,3.5,math.sin(a)*1.65)
   part('CrownBand',CFrame.new(pos)*CFrame.Angles(0,-a,0),Vector3.new(.4,.6,1.5),gold)
   part('CrownPoint',CFrame.new(pos+Vector3.new(0,.65,0))*CFrame.Angles(0,a,math.cos(a)*.17),Vector3.new(.42,1.3,.42),gold)
   cube('CrownJewel',pos.X,3.58,pos.Z,.46,.46,.46,Color3.fromHSV(i/8,.65,1),Enum.Material.Neon)
  end
 elseif secret then
  for i=1,6 do local a=i*math.pi/3;local p=part('VoidShard',CFrame.new(math.cos(a)*3.45,1+math.sin(a*2)*1.4,math.sin(a)*3.45)*CFrame.Angles(.2,a,.35),Vector3.new(.65,1.8,.65),Color3.fromRGB(27,16,47),Enum.Material.Slate)
   p:SetAttribute('LuckyFloat',i)
  end
 end
 if rank>=2 then
  local l=Instance.new('PointLight');l.Name='LuckyGlow';l.Color=color;l.Brightness=legendary and .8 or .45;l.Range=11;l.Shadows=false;l.Enabled=false;l.Parent=core
 end
 if rank>=3 then
  local a=Instance.new('Attachment');a.Position=Vector3.new(0,2.6,0);a.Parent=core
  local e=Instance.new('ParticleEmitter');e.Name=mythic and 'Embers'or secret and 'VoidMist'or 'TierSparkles'
  e.Texture=secret and 'rbxasset://textures/particles/smoke_main.dds'or 'rbxasset://textures/particles/sparkles_main.dds'
  e.Rate=secret and 3 or math.min(6,rank);e.Lifetime=NumberRange.new(.55,1.15);e.Speed=NumberRange.new(.6,1.7);e.Size=NumberSequence.new(secret and 1.7 or .18)
  e.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.25),NumberSequenceKeypoint.new(1,1)})
  e.Color=ColorSequence.new(color);e.LightEmission=secret and .1 or .55;e.Enabled=false;e.SpreadAngle=Vector2.new(35,35);e.Parent=a
 end
 m:ScaleTo(.8);m:SetAttribute('GroundLocal',Vector3.new(0,-2.4,0));return m
end
return V

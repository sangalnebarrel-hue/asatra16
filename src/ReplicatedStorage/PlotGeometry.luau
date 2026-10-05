-- Shared architectural primitives; all generated decoration is non-interactive.
local G={}
function G.Part(parent,name,size,cf,color,material,shape)
 local p=Instance.new('Part');p.Name=name;p.Size=size;p.CFrame=cf;p.Color=color;p.Material=material or Enum.Material.SmoothPlastic
 p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth
 if shape==Enum.PartType.Ball and math.max(size.X,size.Y,size.Z)-math.min(size.X,size.Y,size.Z)>.001 then
  local mesh=Instance.new('SpecialMesh');mesh.MeshType=Enum.MeshType.Sphere;mesh.Parent=p
 elseif shape then p.Shape=shape end
 p.Parent=parent;return p
end
function G.Beam(parent,name,a,b,w,color,material)
 return G.Part(parent,name,Vector3.new(w,w,(b-a).Magnitude),CFrame.lookAt((a+b)/2,b),color,material)
end
function G.Ring(parent,cf,r,w,color,material,from,to,n)
 from=from or 0;to=to or math.pi*2;n=n or 24
 for i=1,n do local a=from+(to-from)*(i-1)/n;local b=from+(to-from)*i/n
  G.Beam(parent,'Arc',cf:PointToWorldSpace(Vector3.new(math.cos(a)*r,math.sin(a)*r,0)),cf:PointToWorldSpace(Vector3.new(math.cos(b)*r,math.sin(b)*r,0)),w,color,material)
 end
end
function G.Sign(parent,cf,size,text,color,name)
 local p=G.Part(parent,name or 'Sign',size,cf,Color3.fromRGB(16,22,28),Enum.Material.Metal)
 local g=Instance.new('SurfaceGui');g.Name='Lettering';g.Face=Enum.NormalId.Front;g.CanvasSize=Vector2.new(800,math.max(100,800*size.Y/size.X));g.LightInfluence=0;g.Parent=p
 local t=Instance.new('TextLabel');t.Name='Caption';t.Size=UDim2.fromScale(.94,.86);t.Position=UDim2.fromScale(.03,.07);t.BackgroundTransparency=1;t.Text=text;t.TextColor3=color;t.Font=Enum.Font.GothamBold;t.TextScaled=true;t.Parent=g
 return p
end
function G.Bone(parent,cf,s,color)
 G.Part(parent,'IvoryBone',Vector3.new(5,.8,.8)*s,cf,color)
 for _,x in ipairs({-2.4,2.4})do for _,y in ipairs({-.32,.32})do G.Part(parent,'BoneKnuckle',Vector3.one*1.15*s,cf*CFrame.new(x*s,y*s,0),color,nil,Enum.PartType.Ball)end end
end
function G.Paw(parent,cf,s,color)
 G.Part(parent,'PawPad',Vector3.new(2.2,1.7,.35)*s,cf,color,nil,Enum.PartType.Ball)
 for i=1,4 do G.Part(parent,'PawToe',Vector3.new(.78,.94,.36)*s,cf*CFrame.new((i-2.5)*.85*s,(i==1 or i==4)and .95*s or 1.55*s,0),color,nil,Enum.PartType.Ball)end
end
function G.Crystal(parent,cf,s,color)
 G.Part(parent,'CrystalBody',Vector3.new(1.4,3,1.4)*s,cf*CFrame.Angles(0,math.pi/4,0),color,Enum.Material.Glass).Transparency=.12
 for _,side in ipairs({-1,1})do
  local w=Instance.new('WedgePart');w.Name='CrystalTip';w.Size=Vector3.new(1.4,1.6,1.4)*s;w.CFrame=cf*CFrame.new(0,side*2.15*s,0)*CFrame.Angles(side<0 and math.pi or 0,math.pi/4,0);w.Color=color;w.Material=Enum.Material.Glass;w.Anchored=true;w.CanCollide=false;w.CanTouch=false;w.CanQuery=false;w.Parent=parent
 end
 G.Part(parent,'CrystalLight',Vector3.new(.13,3.15,.13)*s,cf*CFrame.new(0,0,-.74*s),color:Lerp(Color3.new(1,1,1),.35),Enum.Material.Neon)
end
function G.Cluster(parent,cf,s,glow,trim)
 G.Crystal(parent,cf*CFrame.new(0,2*s,0),s,glow)
 for _,i in ipairs({-1,1})do G.Crystal(parent,cf*CFrame.new(i*1.65*s,1.1*s,.4*s)*CFrame.Angles(0,0,-i*.35),s*.6,trim)end
end
function G.Rock(parent,cf,s,color)
 for i=1,3 do G.Part(parent,'FacetedStone',Vector3.new(2.4,2,2.6)*s,cf*CFrame.new((i-2)*1.3*s,(i%2)*.3*s,0)*CFrame.Angles(.13*i,.6*i,.23*i),color:Lerp(Color3.fromRGB(154,150,155),i*.09),Enum.Material.Slate)end
end
function G.Gear(parent,cf,r,color)
 G.Ring(parent,cf,r,.25,color,Enum.Material.Metal,0,math.pi*2,16)
 for i=1,12 do local a=i*math.pi/6;G.Part(parent,'GearTooth',Vector3.new(.5,.7,.5),cf*CFrame.new(math.sin(a)*(r+.1),math.cos(a)*(r+.1),0)*CFrame.Angles(0,0,-a),color,Enum.Material.Metal)end
 for i=1,6 do local a=i*math.pi/3;G.Beam(parent,'Spoke',cf.Position,cf:PointToWorldSpace(Vector3.new(math.cos(a)*r,math.sin(a)*r,0)),.15,color,Enum.Material.Metal)end
end
function G.Clock(parent,cf,s,trim,body)
 G.Part(parent,'ClockFace',Vector3.new(.25,4.4,4.4)*s,cf*CFrame.Angles(0,math.pi/2,0),Color3.fromRGB(255,241,202),nil,Enum.PartType.Cylinder)
 G.Ring(parent,cf,2.3*s,.22*s,trim,Enum.Material.Metal)
 for i=1,12 do local a=i*math.pi/6;G.Part(parent,'HourMark',Vector3.new(.12,.32,.1)*s,cf*CFrame.new(math.sin(a)*1.86*s,math.cos(a)*1.86*s,-.22*s)*CFrame.Angles(0,0,-a),body)end
 G.Beam(parent,'MinuteHand',cf:PointToWorldSpace(Vector3.new(0,0,-.28*s)),cf:PointToWorldSpace(Vector3.new(0,1.5*s,-.28*s)),.12*s,body)
 G.Beam(parent,'HourHand',cf:PointToWorldSpace(Vector3.new(0,0,-.29*s)),cf:PointToWorldSpace(Vector3.new(.9*s,-.5*s,-.29*s)),.16*s,body)
end
function G.Crest(parent,cf,s,d)
 local C=require(game.ReplicatedStorage.PlotCatalog);local trim,glow,body=C.Color(d.Trim),C.Color(d.Glow),C.Color(d.Color);local m=d.Motif
 if m=='Bone'then G.Bone(parent,cf,s,trim)
 elseif m=='Crystal'or m=='Rainbow'then G.Cluster(parent,cf*CFrame.new(0,-2*s,0),s,glow,trim)
 elseif m=='Clock'then G.Clock(parent,cf,s,trim,body)
 elseif m=='Sun'then
  G.Part(parent,'SunDisc',Vector3.new(.35,3.2,3.2)*s,cf*CFrame.Angles(0,math.pi/2,0),glow,Enum.Material.Metal,Enum.PartType.Cylinder)
  for i=1,12 do local a=i*math.pi/6;G.Part(parent,'SunRay',Vector3.new(.48,1,.35)*s,cf*CFrame.new(math.sin(a)*2.25*s,math.cos(a)*2.25*s,0)*CFrame.Angles(0,0,-a),trim,Enum.Material.Metal)end
 elseif m=='Moon'then G.Ring(parent,cf,1.9*s,.64*s,glow,Enum.Material.Neon,math.rad(65),math.rad(300),18)
 elseif m=='Void'then
  G.Ring(parent,cf,2.15*s,.25*s,glow,Enum.Material.Neon)
  G.Part(parent,'Singularity',Vector3.new(.32,3.9,3.9)*s,cf*CFrame.Angles(0,math.pi/2,0),Color3.fromRGB(3,1,9),nil,Enum.PartType.Cylinder)
 elseif m=='Treasure'then G.Gear(parent,cf,2*s,trim)
 elseif m=='UFO'then
  G.Part(parent,'AlienHead',Vector3.new(2.7,3.1,.6)*s,cf,glow,Enum.Material.Neon,Enum.PartType.Ball)
  for _,x in ipairs({-1,1})do G.Part(parent,'AlienEye',Vector3.new(.65,1.1,.2)*s,cf*CFrame.new(x*.64*s,.1*s,-.4*s)*CFrame.Angles(0,0,x*.45),body,nil,Enum.PartType.Ball)end
 elseif m=='Curse'then
  G.Ring(parent,cf,1.5*s,.25*s,glow,Enum.Material.Neon,0,math.pi*1.8,12)
  G.Beam(parent,'CurseRune',cf:PointToWorldSpace(Vector3.new(0,1.2,-.1)*s),cf:PointToWorldSpace(Vector3.new(0,-2.5,-.1)*s),.24*s,glow,Enum.Material.Neon)
  for _,x in ipairs({-1,1})do G.Beam(parent,'Antler',cf:PointToWorldSpace(Vector3.new(x*.6,1.3,0)*s),cf:PointToWorldSpace(Vector3.new(x*1.5,2.6,0)*s),.35*s,trim)end
 elseif m=='Glitch'then G.Sign(parent,cf,Vector3.new(7,2.1,.3)*s,'[ WORLD STATE ERROR ]',trim)
 else G.Paw(parent,cf,s,trim)end
end
return G

-- Reversible Studio EDIT installer. Original values live in DistrictRefresh_* attributes.
local I={Version='2026-09-30.4'}
local C=Color3.fromRGB
local P={Cream=C(249,240,216),Gold=C(238,192,74),Navy=C(42,43,73),Purple=C(108,70,162),Violet=C(155,111,205),Teal=C(45,117,105),Mint=C(126,183,145),Pink=C(230,135,153),Stone=C(214,208,185),Wood=C(168,116,70),Grass=C(112,149,93),Ink=C(36,44,55)}
local prefix='DistrictRefresh_'
local properties={'Transparency','CanCollide','CanTouch','CanQuery','CastShadow','Enabled','Visible','Color','Material','Reflectance','CFrame','Size','Text','TextColor3','Font','FontFace','Brightness','Range','SizingMode','PixelsPerStud'}
local function map()return workspace:WaitForChild('DOGROTS_District')end
local function edit(o,k,v)
 local a=prefix..k
 if o:GetAttribute(a)==nil then
  if k=='FontFace'then
   o:SetAttribute(a,o.FontFace.Family);o:SetAttribute(a..'Weight',o.FontFace.Weight.Name);o:SetAttribute(a..'Style',o.FontFace.Style.Name)
  else o:SetAttribute(a,typeof(o[k])=='EnumItem'and o[k].Name or o[k])end
 end
 o:SetAttribute(prefix..'Edited',true);o[k]=v
end
local function hide(o)
 if o:IsA('BasePart')then
  edit(o,'Transparency',1);edit(o,'CanCollide',false);edit(o,'CanTouch',false);edit(o,'CanQuery',false);edit(o,'CastShadow',false)
 elseif o:IsA('Highlight')then edit(o,'Enabled',false)
 elseif o:IsA('GuiBase3d')then edit(o,'Visible',false)
 elseif o:IsA('SurfaceGui')or o:IsA('BillboardGui')or o:IsA('Light')or o:IsA('ParticleEmitter')or o:IsA('Beam')or o:IsA('Trail')or o:IsA('ProximityPrompt')then edit(o,'Enabled',false)end
end
local function hideTree(o)hide(o);for _,d in ipairs(o:GetDescendants())do hide(d)end end
local function assertEdit()assert(game:GetService('RunService'):IsStudio()and not game:GetService('RunService'):IsRunning(),'Install in Studio Edit mode')end
function I.Uninstall()
 assertEdit();local m=map();local old=m:FindFirstChild('36_DistrictRefresh')
 assert(not old or old:GetAttribute('CodexDistrictRefresh'),'Unrelated refresh folder exists')
 if old then old:Destroy()end
 local restored=0
 for _,o in ipairs(m:GetDescendants())do
  if o:GetAttribute(prefix..'Edited')then
   for _,k in ipairs(properties)do
    local a=prefix..k;local v=o:GetAttribute(a)
    if v~=nil then
     if k=='Material'then v=Enum.Material[v]
     elseif k=='Font'then v=Enum.Font[v]
     elseif k=='SizingMode'then v=Enum.SurfaceGuiSizingMode[v]
     elseif k=='FontFace'then v=Font.new(v,Enum.FontWeight[o:GetAttribute(a..'Weight')],Enum.FontStyle[o:GetAttribute(a..'Style')]);o:SetAttribute(a..'Weight',nil);o:SetAttribute(a..'Style',nil)end
     o[k]=v;o:SetAttribute(a,nil)
    end
   end
   o:SetAttribute(prefix..'Edited',nil);restored+=1
  end
 end
 return restored
end
local function install()
 local m=map();local shop=m['11_Shops'].SUPPLIES;local machinePlaza=m['27_RewardMachinePlaza'];local machine=machinePlaza.RewardMachine
 local shelter=m['32_WelcomeHub'].DogShelter;local quarry=m['08_GlobalDigSite']
 assert(shop.Architecture.ShopFloor.Size.X==40,'Supply shop footprint changed')
 assert(machine:FindFirstChild('SpinningDrum')and machine:FindFirstChild('RewardMachinePrompt',true),'Reward machine mechanism missing')
 if m:FindFirstChild('36_DistrictRefresh')then I.Uninstall()end
 local root=Instance.new('Folder');root.Name='36_DistrictRefresh';root:SetAttribute('CodexDistrictRefresh',true);root:SetAttribute('Version',I.Version);root.Parent=m
 local counts={Parts=0,Lights=0,Windows=0,WindowOpenings=0,Fonts=0,PathSegments=0}
 local function group(name)local g=Instance.new('Model');g.Name=name;g.Parent=root;return g end
 local function box(parent,name,cf,size,color,mat,collide)
  local p=Instance.new('Part');p.Name=name;p.CFrame=cf;p.Size=size;p.Color=color;p.Material=mat or Enum.Material.SmoothPlastic;p.Anchored=true
  p.CanCollide=collide==true;p.CanQuery=collide==true;p.CanTouch=false;p.CastShadow=collide==true;p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=parent;counts.Parts+=1;return p
 end
 local function block(parent,name,x,y,z,sx,sy,sz,color,mat,collide)return box(parent,name,CFrame.new(x,y,z),Vector3.new(sx,sy,sz),color,mat,collide)end
 local function guiLabel(gui,name,text,pos,size,color)
  local t=Instance.new('TextLabel');t.Name=name;t.BackgroundTransparency=1;t.Position=pos;t.Size=size;t.Text=text;t.TextColor3=color or P.Cream;t.Font=Enum.Font.FredokaOne;t.TextScaled=true;t.TextWrapped=true;t.Parent=gui;return t
 end
 local function sign(parent,name,cf,width,height,text,bg,ink)
  local p=box(parent,name,cf,Vector3.new(width,height,.24),bg or P.Navy)
  local gui=Instance.new('SurfaceGui');gui.Name='Lettering';gui.Face=Enum.NormalId.Front;gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;gui.PixelsPerStud=math.clamp(96/height,4,40);gui.LightInfluence=0;gui.Parent=p
  guiLabel(gui,'Title',text,UDim2.fromScale(.03,.035),UDim2.fromScale(.94,.93),ink);return p,gui
 end
 local function light(part,b,range)local l=Instance.new('PointLight');l.Name='SoftAccent';l.Color=P.Cream;l.Brightness=b;l.Range=range;l.Shadows=false;l.Parent=part;counts.Lights+=1 end
 local function planter(parent,x,z,s)
  block(parent,'Planter',x,.65,z,4*s,1.2,4*s,P.Stone,Enum.Material.Slate,true)
  block(parent,'Planting',x,1.6,z,3.4*s,1.4,3.4*s,P.Mint,Enum.Material.Grass)
  for k=1,4 do local a=k*math.pi/2;local p=block(parent,'Flower',x+math.cos(a)*s,2.35,z+math.sin(a)*s,.6,.5,.6,k%2==0 and P.Pink or P.Gold);p.Shape=Enum.PartType.Ball end
 end
 local openings=group('ClearWindowOpenings')
 local panes={}
 local paneNames={BlueWindow=true,SideWindow=true,InteriorWindow=true,FrontWindow=true,DisplayWindow=true,DisplayGlass=true,DoorGlass=true,UpperClerestory=true,RearGlass=true,ObservationGlass=true,WingClerestory=true,RaisedVolumeGlazing=true,WingSkylight=true,CentralSkylight=true,ArchiveGlass=true,GuardGlass=true,ShowcaseGlass=true,CentralWindowGlass=true,ArchedGlass=true,EntranceFixedGlass=true,ContinuousGlass=true,SideGlazing=true,ShowcaseGlazing=true,ClearContainment=true}
 local aperturePanes={BlueWindow=true,SideWindow=true,FrontWindow=true}
 for _,p in ipairs(m:GetDescendants())do
  if p:IsA('BasePart')and paneNames[p.Name]then
   edit(p,'Color',C(246,247,242));edit(p,'Material',Enum.Material.Glass);edit(p,'Transparency',.94);edit(p,'Reflectance',0);edit(p,'CastShadow',false);counts.Windows+=1
   if aperturePanes[p.Name]then table.insert(panes,p)end
  end
 end
 -- Preserve wall geometry around real openings instead of leaving opaque blue blocks behind transparent panes.
 local wallNames={SideWall=true,FrontWing=true,SideWindowFrame=true,FrontWindowFrame=true,SideMasonry=true,WindowSurround=true,WindowInset=true,StoneCourse=true}
 for _,wall in ipairs(m:GetDescendants())do
  if wall:IsA('Part')and wallNames[wall.Name]and (wall:IsDescendantOf(shelter.Architecture)or wall:IsDescendantOf(m['06_DogDexMuseum']))then
   local normalX=wall.Size.X<wall.Size.Z;local horizontal=normalX and wall.Size.Z or wall.Size.X;local thickness=normalX and wall.Size.X or wall.Size.Z
   local holes={};local xs={-horizontal/2,horizontal/2};local ys={-wall.Size.Y/2,wall.Size.Y/2}
   for _,pane in ipairs(panes)do
    local q=wall.CFrame:PointToObjectSpace(pane.Position);local n=normalX and q.X or q.Z
    if math.abs(n)<thickness/2+3 then
     local lowX,highX,lowY,highY=math.huge,-math.huge,math.huge,-math.huge
     for _,a in ipairs({-1,1})do for _,b in ipairs({-1,1})do for _,c in ipairs({-1,1})do
      local v=wall.CFrame:PointToObjectSpace(pane.CFrame:PointToWorldSpace(pane.Size*Vector3.new(a,b,c)/2));local h=normalX and v.Z or v.X
      lowX=math.min(lowX,h);highX=math.max(highX,h);lowY=math.min(lowY,v.Y);highY=math.max(highY,v.Y)
     end end end
     lowX=math.max(-horizontal/2,lowX);highX=math.min(horizontal/2,highX);lowY=math.max(-wall.Size.Y/2,lowY);highY=math.min(wall.Size.Y/2,highY)
     if highX-lowX>.01 and highY-lowY>.01 then table.insert(holes,{lowX,highX,lowY,highY});table.insert(xs,lowX);table.insert(xs,highX);table.insert(ys,lowY);table.insert(ys,highY)end
    end
   end
   if #holes>0 then
    table.sort(xs);table.sort(ys)
    for a=1,#xs-1 do for b=1,#ys-1 do
     local x0,x1,y0,y1=xs[a],xs[a+1],ys[b],ys[b+1];local cx,cy=(x0+x1)/2,(y0+y1)/2;local cut=false
     for _,h in ipairs(holes)do if cx>=h[1]and cx<=h[2]and cy>=h[3]and cy<=h[4]then cut=true;break end end
     if not cut and x1-x0>.01 and y1-y0>.01 then
      local offset=normalX and Vector3.new(0,cy,cx)or Vector3.new(cx,cy,0);local size=normalX and Vector3.new(thickness,y1-y0,x1-x0)or Vector3.new(x1-x0,y1-y0,thickness)
      box(openings,wall.Name..'Segment',wall.CFrame*CFrame.new(offset),size,wall.Color,wall.Material,wall.CanCollide)
     end
    end end
    hide(wall);counts.WindowOpenings+=#holes
   end
  end
 end
 local future=group('GlobalEventComingSoon')
 for _,d in ipairs(quarry:GetDescendants())do
  if d:IsA('BasePart')and not d.Name:find('Anchor')and d.Name~='SiteOrigin'then hide(d)
  elseif not d:IsA('BasePart')then hide(d)end
 end
 -- Disable legacy adornments even when parented outside the quarry but adorning it.
 for _,d in ipairs(m:GetDescendants())do
  if d:IsA('Highlight')or d:IsA('GuiBase3d')then
   local ok,a=pcall(function()return d.Adornee end)
   if ok and a and (a==quarry or a:IsDescendantOf(quarry))then hide(d)end
  end
 end
 -- The full measured quarry envelope is covered; no open descent remains.
 block(future,'PitCover',119,-.31,639,170,1.3,210,P.Grass,Enum.Material.Grass,true)
 block(future,'GardenWalkWest',44,.39,639,20,.10,210,P.Stone,Enum.Material.Concrete,true)
 block(future,'GardenWalkEast',194,.39,639,20,.10,210,P.Stone,Enum.Material.Concrete,true)
 block(future,'GardenWalkNorth',119,.39,544,130,.10,20,P.Stone,Enum.Material.Concrete,true)
 block(future,'GardenWalkSouth',119,.39,734,130,.10,20,P.Stone,Enum.Material.Concrete,true)
 block(future,'WelcomeCourt',84,.39,575,80,.10,26,P.Stone,Enum.Material.Concrete,true)
 block(future,'CentralEventGarden',133,.44,635,90,.12,108,P.Mint,Enum.Material.Grass,true)
 local boardCF=CFrame.new(124,16,575)*CFrame.Angles(0,math.pi/2,0)
 sign(future,'ComingSoonBoard',boardCF,48,19,'GLOBAL EVENTS\nCOMING SOON',P.Teal,P.Cream)
 sign(future,'ComingSoonSubtitle',boardCF*CFrame.new(0,-12,0),48,3.5,'A NEW ADVENTURE IS ON THE WAY',P.Cream,P.Teal)
 for _,z in ipairs({553,597})do block(future,'BoardPost',125,10,z,.9,20,.9,P.Wood,Enum.Material.Wood,true)end
 for _,v in ipairs({{64,550},{64,607},{66,678},{174,550},{174,702}})do planter(future,v[1],v[2],2)end
 for _,z in ipairs({616,657,698})do
  block(future,'GardenBench',56,2,z,6,.45,12,P.Wood,Enum.Material.Wood,true)
  for _,zz in ipairs({z-4,z+4})do block(future,'BenchLeg',56,1.05,zz,.7,1.7,.7,P.Navy,nil,true)end
  block(future,'BenchBack',53.2,3.5,z,.4,2.5,12,P.Teal,nil,true)
 end
 local paths=group('DirectPaths')
 local roadColor=P.Stone
 local function path(name,x1,z1,x2,z2,width,top)
  assert(math.abs(x1-x2)<.001 or math.abs(z1-z2)<.001,'Routes must have square turns')
  local sx=math.abs(x2-x1);local sz=math.abs(z2-z1)
  local p=block(paths,name,(x1+x2)/2,(top or .42)-.15,(z1+z2)/2,sx==0 and width or sx,.3,sz==0 and width or sz,roadColor,Enum.Material.Concrete,true);counts.PathSegments+=1;return p
 end
 -- Remove stale cross-island roads that cut through relocated architecture.
 local primary=m['01_IslandAndStreets'].PrimaryPaths
 for _,p in ipairs(primary:GetChildren())do if p:IsA('BasePart')and p.Name=='DistrictConnection'then hide(p)end end
 local shelterDoor=shelter.EntranceAnchor.Position
 path('ShelterApproach',18,shelterDoor.Z,shelterDoor.X+8,shelterDoor.Z,14,.48)
 path('LeaderboardApproach',-18,206,-59,206,14,.48)
 path('UpgradeApproach',18,275,102,275,12,.47)
 path('CosmeticsApproach',18,335,102,335,12,.47)
 path('SupplyApproach',18,395,102,395,12,.47)
 path('CommunityApproach',-18,342,-38,342,16,.47)
 path('GardenApproach',-18,275,-60,275,12,.40)
 path('GardenReturn',-18,381,-36,381,10,.43)
 local museumDoor=m['06_DogDexMuseum'].EntranceAnchor.Position
 path('MuseumApproach',-18,museumDoor.Z,museumDoor.X-2,museumDoor.Z,16,.52)
 local labDoor=m['05_MutationLab'].EntranceAnchor.Position
 hideTree(m['05_MutationLab'].PromenadeConnection.EntryWalk)
 path('LabApproach',18,labDoor.Z,labDoor.X+2,labDoor.Z,16,.48)
 path('MachineApproach',-18,630,-38,630,18,.44)
 path('FutureApproach',18,575,44,575,18,.44)
 path('PortalApproach',-18,564,-63,564,12,.44)
 path('SouthGardenLoop',-177,730,194,730,10,.44)
 path('MachineGardenReturn',-177,703,-177,730,8,.44)
 -- Forecourt already has a wide route: keep the display off that route.
 local rareCourt=machinePlaza.Forecourt:FindFirstChild('RareRewardCourt')
 if rareCourt then for _,p in ipairs(rareCourt:GetDescendants())do if p:IsA('BasePart')then edit(p,'CFrame',p.CFrame+Vector3.new(0,0,-25))end end end
 local machineRoot=group('RewardMachine')
 local machineColors={MachineFoot=P.Navy,MachineLowerBody=P.Purple,TopCabinet=P.Purple,ButtonHousing=P.Navy,OpenButton=P.Teal,LowerPanelFrame=P.Gold,LowerPanelInset=P.Violet,SideBoardGold=P.Gold,SideBoard=P.Navy,DOGROTS=P.Navy}
 for _,d in ipairs(machine:GetDescendants())do
  if d:IsA('SurfaceGui')and d.Name=='Lettering'and d.Parent:IsA('BasePart')then
   edit(d,'SizingMode',Enum.SurfaceGuiSizingMode.PixelsPerStud);edit(d,'PixelsPerStud',16)
  end
  if d:IsA('BasePart')and machineColors[d.Name]then edit(d,'Color',machineColors[d.Name]);edit(d,'Reflectance',0)end
  if d:IsA('TextLabel')and d.Parent.Parent.Name=='OpenButton'then edit(d,'Text','ACTIVATE / 1 DOG TOKEN')end
  if d:IsA('TextLabel')and d.Parent.Parent.Name=='SideBoard'then edit(d,'Text',d.Parent.Parent.Position.Z<630 and 'FREE DOG TOKEN\nEVERY 5 HOURS\nMAXIMUM 1' or 'REAL REWARDS\nEXACT ODDS\nEVERY ACTIVATION')end
 end
 edit(machinePlaza.Forecourt.EntryCarpet,'Color',P.Purple)
 for _,z in ipairs({579,681})do
  block(machineRoot,'CanopyPost',-165,23.8,z,2.2,47,2.2,P.Navy,nil,true)
  block(machineRoot,'PostBrassFoot',-165,2,z,3.1,3,3.1,P.Gold,nil,true)
 end
 block(machineRoot,'CanopyRoof',-148,47.5,630,42,1.4,110,P.Purple,Enum.Material.Metal,true)
 block(machineRoot,'CanopyCreamSoffit',-148,46.7,630,39,.18,106,P.Cream)
 block(machineRoot,'FrontGoldCornice',-126.7,47.5,630,.6,2,112,P.Gold)
 sign(machineRoot,'RewardMachineSign',CFrame.new(-126.25,47.7,630)*CFrame.Angles(0,-math.pi/2,0),68,5.5,'DOG-O-MATIC LAB',P.Navy,P.Gold)
 for z=580,680,10 do local p=block(machineRoot,'MarqueeBulb',-126.0,44.2,z,.65,.65,.65,P.Cream,Enum.Material.Neon);p.Shape=Enum.PartType.Ball;if z%20==0 then light(p,.4,18)end end
 local odds,gui=sign(machineRoot,'OddsBoard',CFrame.new(-116,12,665)*CFrame.Angles(0,-math.pi/2,0),27,19,'',P.Navy,P.Cream)
 gui.Name='OddsDisplay';gui.PixelsPerStud=32;gui.Title:Destroy()
 guiLabel(gui,'Title','REWARD CHANCES',UDim2.fromScale(.055,.035),UDim2.fromScale(.89,.10),P.Gold)
 guiLabel(gui,'Status','Open DOG-O-MATIC to view reward chances',UDim2.fromScale(.05,.145),UDim2.fromScale(.90,.075),P.Cream)
 local rows=Instance.new('Frame');rows.Name='Rows';rows.BackgroundTransparency=1;rows.Position=UDim2.fromScale(.055,.25);rows.Size=UDim2.fromScale(.89,.67);rows.Parent=gui
 for k=1,8 do local t=guiLabel(rows,'Row'..k,'',UDim2.fromScale(0,(k-1)/8),UDim2.fromScale(1,.103),k%2==0 and P.Cream or C(201,182,234));t.TextXAlignment=Enum.TextXAlignment.Left end
 for _,z in ipairs({654,676})do block(machineRoot,'OddsBoardLeg',-116,2,z,.8,4,.8,P.Gold,nil,true)end
 sign(machineRoot,'TicketRules',CFrame.new(-116,10,594)*CFrame.Angles(0,-math.pi/2,0),25,14,'1 DOG TOKEN = 1 ACTIVATION\n\nFREE DOG TOKEN EVERY 5 HOURS\nHOLDS 1 DOG TOKEN',P.Teal,P.Cream)
 for _,z in ipairs({585,603})do block(machineRoot,'TicketBoardLeg',-116,2,z,.8,4,.8,P.Gold,nil,true)end
 -- Matched supply shop: the interaction anchor remains directly in front of checkout.
 local supplies=group('Supplies')
 for _,child in ipairs(shop.Interior:GetChildren())do
  if child.Name=='SupplyShelving'or child.Name=='SupplyCounter'or child.Name=='EquipmentDisplay'or child.Name=='StorageLabel'or child.Name=='ServiceTerminal'or child.Name=='BackIdentity'then hideTree(child)end
 end
 local f=shop.Architecture.ShopFloor;local base=f.CFrame*CFrame.new(0,f.Size.Y/2,0)
 local function sb(name,x,y,z,sx,sy,sz,color,mat,collide)return box(supplies,name,base*CFrame.new(x,y,z),Vector3.new(sx,sy,sz),color,mat,collide)end
 sb('WarmFloor',0,.03,0,38,.05,34,P.Cream,Enum.Material.Wood)
 sb('AisleRunner',0,.07,-3,9,.03,26,P.Teal,Enum.Material.Fabric)
 sb('CheckoutBody',0,1.65,10,16,3.3,4,P.Teal,nil,true);sb('CheckoutTop',0,3.45,10,17,.30,4.8,P.Wood,Enum.Material.Wood,true)
 for x=-7,7,1 do sb('CounterFlute',x,1.65,7.96,.30,3.1,.13,P.Mint)end
 sign(supplies,'CheckoutLabel',base*CFrame.new(0,2.1,7.80),10,1.45,'SUPPLIES',P.Teal,P.Cream)
 sb('RegisterBase',4,3.75,10,2.6,.30,2.2,P.Navy)
 sb('RegisterDisplay',4,4.7,10.4,2.4,1.8,.30,P.Navy)
 sign(supplies,'RegisterScreen',base*CFrame.new(4,4.7,10.21),2.0,1.2,'OPEN',P.Teal,P.Cream)
 sign(supplies,'SuppliesHeader',base*CFrame.new(0,15,17.05),31,3.1,'STOCK UP. DIG HAPPY.',P.Teal,P.Cream)
 local categories={{X=-13,Color=P.Pink,Name='LUCKY TREATS',Kind='LuckyTreat'},{X=13,Color=P.Gold,Name='ENERGY SNACKS',Kind='EnergySnack'}}
 for _,c in ipairs(categories)do
  sb('DisplayBacking',c.X,6.3,7,9,11,.45,P.Teal,nil,true)
  for _,y in ipairs({1.1,4.2,7.3})do
   sb('DisplayShelf',c.X,y,4.9,9,.3,4.7,P.Wood,Enum.Material.Wood,true)
   for _,dx in ipairs({-2.7,0,2.7})do
    sb('SupplyBag',c.X+dx,y+1.15,4.8,1.75,2,1.2,c.Color)
    sb('BagSeal',c.X+dx,y+2.14,4.8,1.8,.16,1.26,P.Cream)
    sign(supplies,c.Kind..'Package',base*CFrame.new(c.X+dx,y+1.1,4.17),1.25,.75,c.Kind=='LuckyTreat'and 'LUCK'or'GO!',c.Color,P.Ink)
   end
  end
  sign(supplies,c.Kind..'ShelfLabel',base*CFrame.new(c.X,10.5,6.72),8.5,1.6,c.Name,c.Color,P.Ink)
 end
 sb('StorageDisplayBase',13,1.3,-9,8,2.6,5.5,P.Navy,nil,true)
 for k=1,3 do sb('StorageCrate',10.4+(k-1)*2.6,3.7,-9,2.3,2.2,3.2,P.Mint,Enum.Material.Wood,true);sb('CrateStrap',10.4+(k-1)*2.6,3.7,-10.63,.4,2.2,.08,P.Cream)end
 sign(supplies,'StorageCrateLabel',base*CFrame.new(13,1.6,-11.81),7.2,1.2,'STORAGE CRATES',P.Navy,P.Cream)
 sign(supplies,'SupplyGuide',base*CFrame.new(-13,5.6,-9),8,7,'TEMPORARY BOOSTS\n\nLUCK / SPEED / STORAGE\n\nBUY AT THE COUNTER',P.Teal,P.Cream)
 sb('GuideStand',-13,1.3,-9,.7,2.6,.7,P.Wood,Enum.Material.Wood,true)
 -- World lettering and newly added displays share the same rounded place font.
 for _,o in ipairs(m:GetDescendants())do if o:IsA('TextLabel')or o:IsA('TextButton')or o:IsA('TextBox')then
  if not o:IsDescendantOf(root)then edit(o,'FontFace',Font.fromEnum(Enum.Font.FredokaOne))end;counts.Fonts+=1
 end end
 for k,v in pairs(counts)do root:SetAttribute(k,v)end
 return counts
end
function I.Install()
 assertEdit();local ok,result=pcall(install)
 if not ok then pcall(I.Uninstall);error(result)end
 return result
end
function I.Validate()
 local m=map();local r=m:FindFirstChild('36_DistrictRefresh');assert(r,'Refresh missing')
 local problems={};local function check(ok,why)if not ok then table.insert(problems,why)end end
 check(r.GlobalEventComingSoon.PitCover.CanCollide,'Quarry cover has no collision')
 check(r.GlobalEventComingSoon.PitCover.Size.X>=170 and r.GlobalEventComingSoon.PitCover.Size.Z>=210,'Quarry envelope not covered')
 check(m['27_RewardMachinePlaza'].RewardMachine:FindFirstChild('RewardMachinePrompt',true)~=nil,'Reward machine prompt lost')
 check((m['11_Shops'].SUPPLIES.InteractionAnchor.Position-Vector3.new(142.8,4.3,395)).Magnitude<.01,'Supply anchor moved')
 check(r.RewardMachine.OddsBoard:FindFirstChild('OddsDisplay')~=nil,'Odds display missing')
 local blue=0;for _,o in ipairs(m:GetDescendants())do if o:IsA('BasePart')and (o.Name=='BlueWindow'or o.Name=='FrontWindow'or o.Name=='SideWindow'or o.Name=='InteriorWindow')and o.Transparency<.9 then blue+=1 end end
 check(blue==0,'Opaque blue windows remain')
 return {Passed=#problems==0,Problems=problems,Parts=r:GetAttribute('Parts'),Windows=r:GetAttribute('Windows'),WindowOpenings=r:GetAttribute('WindowOpenings'),Fonts=r:GetAttribute('Fonts'),PathSegments=r:GetAttribute('PathSegments')}
end
return I

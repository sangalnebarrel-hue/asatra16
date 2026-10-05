-- Studio EDIT installer only. Invoke require(module).Install().
-- All additions live in DogShelter.InteriorFinish. Hidden legacy pen panels and
-- cube lanterns retain original properties in attributes for exact restoration.
local Installer={Version='2026-09-30.1'}
local C=Color3.fromRGB
local P={Cream=C(235,224,196),Linen=C(248,240,215),Teal=C(43,93,86),Deep=C(28,56,52),Mint=C(131,169,144),Wood=C(164,111,65),Oak=C(206,157,99),Gold=C(215,177,93),Coral=C(204,121,95),Blue=C(115,161,179),Metal=C(77,94,91),Warm=C(255,221,164),Leaf=C(96,137,91)}
local hiddenGeometry={KennelSide=true,KennelBack=true,KennelCanopy=true,LanternStem=true,LanternFrame=true,WarmLantern=true,WelcomeRug=true,ReceptionSign=true}
local savedProperties={'Transparency','CanCollide','CanQuery','CastShadow','Enabled'}
local function shelterModel()return workspace.DOGROTS_District['32_WelcomeHub'].DogShelter end
local function editTracked(instance,key,value)
 local attribute='ShelterOriginal_'..key
 if instance:GetAttribute(attribute)==nil then instance:SetAttribute(attribute,instance[key])end
 instance:SetAttribute('ShelterInteriorEdited',true);instance[key]=value
end
function Installer.Install()
 assert(game:GetService('RunService'):IsStudio()and not game:GetService('RunService'):IsRunning(),'Run in Studio Edit mode only')
 local shelter=workspace:WaitForChild('DOGROTS_District'):WaitForChild('32_WelcomeHub'):WaitForChild('DogShelter')
 local architecture=shelter:WaitForChild('Architecture')
 local floor=architecture:WaitForChild('WarmFloor')
 local reception=shelter:WaitForChild('ReceptionAndKennels')
 local sell=shelter:WaitForChild('SellAnchor');local entrance=shelter:WaitForChild('EntranceAnchor')
 local preserved={Floor=floor.CFrame,Sell=sell.CFrame,Entrance=entrance.CFrame,Desk=reception:WaitForChild('ReceptionDesk').CFrame}
 assert(math.abs(floor.Size.X-75)<1 and math.abs(floor.Size.Z-53)<1,'Unexpected shelter shell; inspect dimensions before installing')
 local old=shelter:FindFirstChild('InteriorFinish')
 assert(not old or old:GetAttribute('CodexShelterInterior')==true,'An unrelated InteriorFinish exists; no objects were changed')
 local base=floor.CFrame*CFrame.new(0,floor.Size.Y/2,0)
 local root=Instance.new('Folder');root.Name='InteriorFinish';root:SetAttribute('CodexShelterInterior',true);root:SetAttribute('Version',Installer.Version)
 root:SetAttribute('OriginalSellCFrame',sell.CFrame);root:SetAttribute('OriginalEntranceCFrame',entrance.CFrame);root:SetAttribute('OriginalDeskCFrame',preserved.Desk)
 local partCount,lightCount=0,0
 local function group(name,parent)local m=Instance.new('Model');m.Name=name;m.Parent=parent or root;return m end
 local function box(parent,name,x,y,z,sx,sy,sz,color,material,collide,rotation)
  local p=Instance.new('Part');p.Name=name;p.Size=Vector3.new(sx,sy,sz)
  p.CFrame=base*CFrame.new(x,y,z)*(rotation or CFrame.identity)
  p.Color=color;p.Material=material or Enum.Material.SmoothPlastic;p.Anchored=true
  p.CanCollide=collide==true;p.CanTouch=false;p.CanQuery=collide==true;p.CastShadow=collide==true
  p.TopSurface=Enum.SurfaceType.Smooth;p.BottomSurface=Enum.SurfaceType.Smooth;p.Parent=parent
  partCount+=1;return p
 end
 local function light(part,brightness,range)
  local l=Instance.new('PointLight');l.Name='WarmInteriorLight';l.Color=P.Warm;l.Brightness=brightness;l.Range=range;l.Shadows=false;l.Parent=part;lightCount+=1
 end
 local function sign(parent,name,text,x,y,z,w,h,background,ink,rotation)
  local p=box(parent,name,x,y,z,w,h,.16,background or P.Teal,nil,false,rotation)
  local gui=Instance.new('SurfaceGui');gui.Name='Lettering';gui.Face=Enum.NormalId.Front;gui.SizingMode=Enum.SurfaceGuiSizingMode.PixelsPerStud;gui.PixelsPerStud=45
  gui.LightInfluence=0;gui.AlwaysOnTop=false;gui.Parent=p
  local t=Instance.new('TextLabel');t.Name='Caption';t.BackgroundTransparency=1;t.Size=UDim2.fromScale(.94,.86);t.Position=UDim2.fromScale(.03,.07)
  t.Font=Enum.Font.GothamBold;t.Text=text;t.TextColor3=ink or P.Linen;t.TextScaled=true;t.TextWrapped=true;t.Parent=gui
  return p
 end
 local function paw(parent,x,y,z,scale,color,flat)
  local rotation=flat and CFrame.Angles(-math.pi/2,0,0)or CFrame.identity
  local offsets={{0,-.30,1.35,.9},{-.80,.48,.52,.60},{-.27,.79,.52,.62},{.31,.79,.52,.62},{.84,.48,.52,.60}}
  for i,o in ipairs(offsets)do
   local cf=CFrame.new(x,y,z)*rotation*CFrame.new(o[1]*scale,o[2]*scale,0)
   local p=box(parent,'Paw'..i,0,0,0,o[3]*scale,o[4]*scale,.05,color)
   p.CFrame=base*cf
  end
 end
 local function planter(parent,x,z)
  local g=group('Planter',parent)
  box(g,'PotBase',x,.65,z,2.4,1.3,2.4,P.Coral)
  box(g,'PotRim',x,1.35,z,2.7,.25,2.7,P.Oak)
  box(g,'Soil',x,1.49,z,2.18,.10,2.18,P.Deep)
  box(g,'Stem',x,2.65,z,.20,2.3,.20,P.Wood)
  for i=1,5 do local angle=(i-1)*math.pi*2/5
   box(g,'BroadLeaf',x+math.cos(angle)*.65,2.7+(i%2)*.5,z+math.sin(angle)*.65,.65,1.8,.30,P.Leaf,nil,false,CFrame.Angles(0,angle,-.45))
  end
 end

 -- Continuous finishes visually tie the original four bays to the reception.
 local finish=group('WallAndCeilingFinish')
 box(finish,'WarmNeutralCeiling',0,16.02,2,74.1,.20,44.1,P.Linen)
 for _,x in ipairs({-36.85,36.85})do
  box(finish,'OakSkirting',x,.32,2,.18,.58,43,P.Oak)
  box(finish,'PictureRail',x,5.05,2,.18,.18,43,P.Gold)
  box(finish,'Cornice',x,15.4,2,.32,.48,43,P.Oak)
 end
 box(finish,'BackSkirting',0,.32,24.05,73.5,.58,.18,P.Oak)
 box(finish,'BackCornice',0,15.4,24.05,73.5,.48,.32,P.Oak)
 for _,z in ipairs({-12,12})do box(finish,'CeilingTimber',0,15.88,z,73,.45,.60,P.Oak)end
 for _,x in ipairs({-18,18})do box(finish,'CeilingSpine',x,15.92,2,.36,.36,43,P.Wood)end
 for _,x in ipairs({-22,0,22})do
  box(finish,'FlushLightHousing',x,15.76,1,6.8,.35,2.60,P.Deep)
  box(finish,'FlushLightRim',x,15.56,1,6.35,.09,2.18,P.Oak)
  local diffuser=box(finish,'CeilingDiffuser',x,15.48,1,5.91,.075,1.78,C(255,242,217),Enum.Material.Neon)
  light(diffuser,.70,26)
 end
 box(finish,'CareWallPanel',0,8.6,24.08,35,12.2,.16,P.Teal)
 for _,x in ipairs({-17.8,17.8})do box(finish,'CareWallStile',x,8.6,23.94,.34,12.7,.24,P.Oak)end
 box(finish,'CareWallCrown',0,15.05,23.90,36,.42,.34,P.Gold)

 local floorDetails=group('FloorAndWayfinding')
 box(floorDetails,'NeutralInteriorFloor',0,.027,2,73.8,.038,44.0,C(206,199,179),Enum.Material.Wood)
 for x=-28,28,7 do box(floorDetails,'FloorBoardSeam',x,.051,2,.028,.007,43.8,C(175,166,145))end
 -- Decorative floor parts are noncollidable and remain below a normal step.
 box(floorDetails,'WovenRunnerBorder',0,.165,-7.2,14.2,.07,26.2,P.Oak)
 box(floorDetails,'WovenRunner',0,.208,-7.2,13.55,.035,25.6,P.Teal,Enum.Material.Fabric)
 for _,x in ipairs({-6.3,6.3})do box(floorDetails,'RunnerEdge',x,.235,-7.2,.10,.018,24.8,P.Linen)end
 for _,z in ipairs({-15,-8,-1})do paw(floorDetails,0,.255,z,.75,P.Gold,true)end
 for _,x in ipairs({-27,27})do
  box(floorDetails,'KennelZoneBorder',x,.035,3,17.6,.06,39.2,P.Oak)
  -- Fine border, rather than a raised platform, leaves the original beds grounded.
  box(floorDetails,'KennelZoneInlay',x,.073,3,17.05,.015,38.65,P.Cream)
 end

 -- Finish the existing reception desk; the actual SellAnchor remains in front.
 local desk=group('ReceptionDetail')
 box(desk,'DeskPlinth',0,.45,5.36,19.4,.65,.18,P.Deep)
 for x=-9,9,1.5 do box(desk,'DeskOakFlute',x,2.55,5.35,.16,3.45,.19,P.Oak)end
 box(desk,'DeskFrontUpperRail',0,4.66,5.32,19.8,.24,.22,P.Gold)
 sign(desk,'RehomeDeskPlaque','DOG REHOMING',0,2.80,5.16,10,1.65,P.Teal,P.Linen)
 box(desk,'DeskLowerRail',0,.94,5.30,19.8,.18,.22,P.Oak)
 for _,x in ipairs({-9.9,9.9})do box(desk,'DeskCorner',x,2.55,5.34,.26,4.45,.24,P.Oak)end
 -- A small, credible workspace: terminal, forms, bell, and staff-side stool.
 box(desk,'TerminalFoot',-6.6,5.45,8.1,2.3,.22,1.5,P.Deep)
 box(desk,'TerminalStem',-6.6,6.05,8.35,.36,1.1,.36,P.Metal)
 sign(desk,'Terminal','WELCOME\nREHOME • CARE',-6.6,7.05,8.1,3.4,2.1,P.Deep,P.Mint)
 box(desk,'Keyboard',-6.6,5.52,6.85,2.7,.12,.8,P.Metal)
 for i=1,3 do box(desk,'PaperForm',1.3+(i-1)*.05,5.41+i*.055,7.8,2.3,.04,1.8,P.Linen,nil,false,CFrame.Angles(0,.08,0))end
 box(desk,'PenTray',3.45,5.49,7.8,.6,.16,1.8,P.Teal)
 for i=1,2 do box(desk,'Pen',3.3+(i-1)*.23,5.66,7.8,.10,.10,1.35,i==1 and P.Coral or P.Blue)end
 box(desk,'BellFoot',6.55,5.48,6.7,1.45,.18,1.25,P.Deep)
 box(desk,'BellBody',6.55,5.75,6.7,1.03,.45,.92,P.Gold)
 box(desk,'BellButton',6.55,6.05,6.7,.32,.19,.32,P.Oak)
 box(desk,'StaffStool',-5,2.5,13.5,3.3,.6,3.1,P.Coral,Enum.Material.Fabric)
 for _,x in ipairs({-6.1,-3.9})do for _,z in ipairs({12.4,14.6})do box(desk,'StoolLeg',x,1.14,z,.30,2.25,.30,P.Deep)end end

 -- One continuous care cabinet anchors the back wall, with readable functions.
 local care=group('CareAndStorage')
 box(care,'CabinetToeKick',0,.4,21.75,26,.65,3.6,P.Deep,Enum.Material.SmoothPlastic,true)
 box(care,'CabinetCase',0,2.35,21.75,26,3.5,3.7,P.Cream,Enum.Material.SmoothPlastic,true)
 box(care,'WorkSurface',0,4.30,21.75,26.7,.38,4.1,P.Oak,Enum.Material.Wood,true)
 for _,x in ipairs({-9.7,-3.25,3.25,9.7})do
  box(care,'CabinetDoor',x,2.35,19.84,6.12,3.15,.16,P.Teal)
  box(care,'DoorInset',x,2.35,19.73,5.52,2.57,.09,P.Mint)
  box(care,'DoorPull',x+2.0,3.0,19.60,.58,.16,.14,P.Gold)
 end
 -- Wash basin with visible lip, inset water and a simple square-neck faucet.
 box(care,'BasinLip',-8.2,4.58,21.65,4.6,.26,2.8,P.Metal)
 box(care,'BasinInterior',-8.2,4.72,21.65,3.8,.06,2.05,P.Deep)
 box(care,'CleanWater',-8.2,4.76,21.65,3.35,.025,1.62,P.Blue)
 box(care,'TapUpright',-8.2,5.30,22.9,.22,1.25,.22,P.Metal)
 box(care,'TapSpout',-8.2,5.91,22.5,.22,.22,1.05,P.Metal)
 for i=1,3 do box(care,'CareBottle',-3.75+(i-1)*.9,4.92,22.1,.60,.86,.62,({P.Mint,P.Linen,P.Coral})[i]);box(care,'BottleCap',-3.75+(i-1)*.9,5.43,22.1,.38,.16,.38,P.Deep)end
 -- Matching open cubbies, restrained contents, no random scatter.
 for _,cx in ipairs({-8,8})do
  box(care,'ShelfBack',cx,8.8,23.62,8.8,5.5,.22,P.Deep)
  for _,dx in ipairs({-4.35,0,4.35})do box(care,'ShelfStile',cx+dx,8.8,22.72,.24,5.65,1.9,P.Oak)end
  for _,y in ipairs({6.0,8.8,11.6})do box(care,'ShelfBoard',cx,y,22.72,9,.24,2.0,P.Oak)end
 end
 for i=1,3 do
  for j=1,2 do box(care,'FoldedTowel',-10.2,6.32+(i-1)*.31,22.45+(j-1)*.38,3.4,.24,.95,({P.Linen,P.Mint,P.Linen})[i],Enum.Material.Fabric)end
 end
 for _,x in ipairs({-5.8,5.8,10.2})do
  box(care,'SupplyBasket',x,6.8,22.48,3.3,1.25,1.55,P.Cream)
  box(care,'BasketRim',x,7.45,22.48,3.45,.13,1.64,P.Oak)
  sign(care,'BasketLabel',x<0 and 'LINENS'or x<8 and 'TREATS'or 'CARE',x,6.83,21.61,2.55,.53,P.Teal,P.Linen)
 end
 for _,x in ipairs({-10.2,-5.8,5.8,10.2})do
  box(care,'StorageBox',x,9.8,22.46,3.25,1.5,1.6,P.Mint)
  box(care,'BoxLid',x,10.60,22.46,3.43,.16,1.70,P.Teal)
  box(care,'BoxLabel',x,9.87,21.60,1.35,.42,.035,P.Linen)
 end
 sign(care,'CareCenterTitle','CARE • COMFORT • HOME',0,13.6,23.82,28,1.75,P.Teal,P.Linen)
 sign(care,'CareNote','EVERY DOG\nDESERVES\nA SOFT LANDING',0,9.6,23.62,5.6,4.4,P.Cream,P.Teal)
 for _,x in ipairs({-13.9,13.9})do
  local lamp=box(care,'TaskLight',x,11.9,22.7,.32,1.4,.40,P.Warm,Enum.Material.Neon)
  box(care,'SconceBacking',x,11.9,23.30,.8,2.15,.20,P.Deep);light(lamp,.55,15)
 end

 -- Finish each existing bay around its authored sleeping dog without replacing it.
 local bays=group('KennelBayFinish')
 local bayNumber=0
 for _,x in ipairs({-27,27})do for _,z in ipairs({-6,13})do
  bayNumber+=1;local bay=group('RestBay_'..bayNumber,bays)
  for _,dx in ipairs({-7.42,7.42})do box(bay,'FrontPost',x+dx,3.45,z-6.70,.34,6.75,.34,P.Oak)end
  -- Open picket sides reveal the original dog; low rails replace 6-stud walls.
  for _,dx in ipairs({-7,7})do
   box(bay,'SideKickRail',x+dx,.59,z,.30,.80,12.9,P.Teal)
   box(bay,'SideTopRail',x+dx,3.47,z,.28,.25,12.9,P.Oak)
   for offset=-5.4,5.4,1.8 do box(bay,'SidePicket',x+dx,2.0,z+offset,.18,2.70,.18,P.Mint)end
   box(bay,'RearPost',x+dx,3.45,z+6.25,.34,6.75,.34,P.Oak)
  end
  box(bay,'BackKickRail',x,.59,z+6.25,14,.80,.30,P.Teal)
  box(bay,'BackTopRail',x,3.47,z+6.25,14,.25,.28,P.Oak)
  for offset=-5.4,5.4,1.8 do box(bay,'BackPicket',x+offset,2.0,z+6.25,.18,2.70,.18,P.Mint)end
  box(bay,'RearCanopyBeam',x,6.6,z+6.25,15.2,.34,.38,P.Oak)
  for _,offset in ipairs({-5.6,-1.9,1.9,5.6})do box(bay,'OpenCanopySlat',x+offset,6.62,z,.48,.30,13.25,P.Oak)end
  box(bay,'CanopyFascia',x,6.60,z-7.12,15.95,.72,.22,P.Oak)
  sign(bay,'BayTitle',string.format('%02d  •  %s',bayNumber,({'COZY CORNER','QUIET NEST','SUNNY SPOT','SWEET DREAMS'})[bayNumber]),x,7.15,z-7.20,12.6,1.22,P.Teal,P.Linen)
  for _,dx in ipairs({-6.05,6.05})do box(bay,'BedEdge',x+dx,1.12,z,.24,.43,9.8,P.Oak)end
  box(bay,'BlanketEdge',x,1.66,z-4.07,9.7,.075,1.0,({P.Mint,P.Coral,P.Blue,P.Mint})[bayNumber],Enum.Material.Fabric)
  box(bay,'CushionBolster',x,2.07,z+3.42,8.8,.63,1.04,P.Linen,Enum.Material.Fabric)
  -- Original water bowl is centered at x+3, z-7; give it a visible water surface.
  box(bay,'WaterMat',x+3,.105,z-7,3.5,.055,3.5,P.Mint,Enum.Material.Fabric)
  box(bay,'WaterSurface',x+3,.985,z-7,2.45,.05,2.45,P.Blue)
  box(bay,'FoodTray',x-2,.30,z-7,2.50,.4,2.50,P.Oak)
  box(bay,'FoodInset',x-2,.53,z-7,2.05,.08,2.05,P.Deep)
  for i=1,4 do box(bay,'Kibble',x-2+((i-1)%2-.5)*.57,.66,z-7+(math.floor((i-1)/2)-.5)*.57,.36,.18,.36,P.Wood)end
  box(bay,'ToyBone',x+3,1.72,z-2.8,1.3,.27,.40,P.Linen,nil,false,CFrame.Angles(0,.3,0))
  for _,dx in ipairs({-.65,.65})do box(bay,'ToyBoneEnd',x+3+dx,1.72,z-2.8,.37,.27,.78,P.Linen)end
  local lamp=box(bay,'BayWarmStrip',x,6.09,z-4.6,6.8,.09,.22,P.Warm,Enum.Material.Neon);light(lamp,.25,11)
 end end

 local waiting=group('WaitingAndWelcome')
 for _,x in ipairs({-13,13})do
  box(waiting,'BenchCushion',x,2.04,-13,6.65,.31,2.75,P.Mint,Enum.Material.Fabric)
  box(waiting,'BenchBack',x,3.20,-14.50,7.3,2.50,.36,P.Oak)
  box(waiting,'BenchBackInset',x,3.20,-14.27,6.65,1.84,.12,P.Teal)
  for _,dx in ipairs({-3.65,3.65})do box(waiting,'BenchArm',x+dx,2.73,-13,.30,1.20,3.3,P.Oak)end
 end
 local turn=CFrame.Angles(0,math.pi,0)
 sign(waiting,'WelcomePoster','WELCOME IN\nGOOD DOGS.\nNEW BEGINNINGS.',-12.8,8.9,-20.03,7.7,6.5,P.Teal,P.Linen,turn)
 sign(waiting,'CarePoster','A LITTLE CARE\nA FRESH START\nA HAPPY HOME',12.8,8.9,-20.03,7.7,6.5,P.Cream,P.Teal,turn)
 planter(waiting,-17.8,-17.9);planter(waiting,17.8,-17.9)

 -- Guard the functional approach. Added collision is confined to the back cabinet.
 for _,p in ipairs(root:GetDescendants())do if p:IsA('BasePart')and p.CanCollide then
  local point=base:PointToObjectSpace(p.Position)
  assert(point.Z-p.Size.Z/2>6 or math.abs(point.X)-p.Size.X/2>8,'Added collision blocks the reception approach')
 end end
 assert(floor.CFrame==preserved.Floor and sell.CFrame==preserved.Sell and entrance.CFrame==preserved.Entrance and reception.ReceptionDesk.CFrame==preserved.Desk,'Original shelter objects moved')
 root:SetAttribute('CreatedParts',partCount);root:SetAttribute('CreatedLights',lightCount)
 game:GetService('ChangeHistoryService'):SetWaypoint('Before Dog Shelter interior finish')
 for _,p in ipairs(reception:GetDescendants())do
  if p:IsA('BasePart')and hiddenGeometry[p.Name]then
   editTracked(p,'Transparency',1);editTracked(p,'CanCollide',false);editTracked(p,'CanQuery',false);editTracked(p,'CastShadow',false)
  elseif p:IsA('PointLight')and p.Parent.Name=='WarmLantern'then editTracked(p,'Enabled',false)
  elseif p:IsA('SurfaceGui')and p.Parent.Name=='ReceptionSign'then editTracked(p,'Enabled',false)end
 end
 if old then old:Destroy()end
 root.Parent=shelter
 game:GetService('ChangeHistoryService'):SetWaypoint('Dog Shelter interior finish complete')
 local cameras={}
 for key,points in pairs({Entrance={Vector3.new(0,10,-19),Vector3.new(0,5,10)},Reception={Vector3.new(-10,8,-1),Vector3.new(0,5,14)},Bays={Vector3.new(-11,8,-15),Vector3.new(-27,3,3)},Reverse={Vector3.new(13,10,18),Vector3.new(0,4,-10)}})do
  cameras[key]=CFrame.lookAt(base:PointToWorldSpace(points[1]),base:PointToWorldSpace(points[2]))
 end
 print('DOG_SHELTER_INTERIOR_READY',partCount,'parts',lightCount,'lights; shell, anchors and dogs preserved; pen panels replaced reversibly')
 return {Folder=root,Parts=partCount,Lights=lightCount,Cameras=cameras}
end
function Installer.Validate()
 local shelter=shelterModel();local folder=shelter:FindFirstChild('InteriorFinish')
 assert(folder and folder:GetAttribute('CodexShelterInterior'),'Interior has not been installed')
 assert(shelter.SellAnchor.CFrame==folder:GetAttribute('OriginalSellCFrame'),'Sell anchor changed')
 assert(shelter.EntranceAnchor.CFrame==folder:GetAttribute('OriginalEntranceCFrame'),'Entrance anchor changed')
 assert(shelter.ReceptionAndKennels.ReceptionDesk.CFrame==folder:GetAttribute('OriginalDeskCFrame'),'Reception desk moved')
 assert(shelter.SellAnchor:FindFirstChild('ShelterPrompt'),'Shelter prompt missing')
 local dogs,bays,hidden,parts,lights=0,0,0,0,0
 for _,p in ipairs(shelter.ReceptionAndKennels:GetDescendants())do
  if p.Name=='SleepingDogBody'then dogs+=1;assert(p.Transparency<1,'A resting dog was hidden')end
  if p:IsA('Model')and p.Name=='CozyKennel'then bays+=1 end
  if p:IsA('BasePart')and hiddenGeometry[p.Name]then hidden+=1;assert(p.Transparency==1 and not p.CanCollide and not p.CanQuery,'Legacy monolithic panel still active')end
  if p:IsA('SurfaceGui')and p.Parent.Name=='ReceptionSign'then assert(not p.Enabled,'Legacy reception lettering still visible')end
 end
 for _,p in ipairs(folder:GetDescendants())do if p:IsA('BasePart')then parts+=1 elseif p:IsA('Light')then lights+=1 end end
 assert(dogs==4 and bays==4,'Expected four preserved resting dogs and bays')
 assert(parts==folder:GetAttribute('CreatedParts'),'Interior part count changed')
 assert(folder.WallAndCeilingFinish:FindFirstChild('WarmNeutralCeiling'),'Neutral ceiling missing')
 local result={Parts=parts,Lights=lights,PreservedDogs=dogs,Bays=bays,HiddenOriginalPanels=hidden,AnchorsPreserved=true}
 print('DOG_SHELTER_INTERIOR_QA_PASS',parts,lights,dogs,bays,hidden)
 return result
end
function Installer.Uninstall()
 assert(game:GetService('RunService'):IsStudio()and not game:GetService('RunService'):IsRunning(),'Run in Studio Edit mode only')
 local shelter=shelterModel();local folder=shelter:FindFirstChild('InteriorFinish')
 assert(not folder or folder:GetAttribute('CodexShelterInterior'),'Unknown InteriorFinish')
 game:GetService('ChangeHistoryService'):SetWaypoint('Before reverting shelter interior')
 for _,p in ipairs(shelter.ReceptionAndKennels:GetDescendants())do if p:GetAttribute('ShelterInteriorEdited')then
  for _,key in ipairs(savedProperties)do local attribute='ShelterOriginal_'..key;local value=p:GetAttribute(attribute)
   if value~=nil then p[key]=value;p:SetAttribute(attribute,nil)end
  end
  p:SetAttribute('ShelterInteriorEdited',nil)
 end end
 if folder then folder:Destroy()end
 game:GetService('ChangeHistoryService'):SetWaypoint('Shelter original interior restored')
 print('DOG_SHELTER_INTERIOR_RESTORED')
end
return Installer

local C=require(script.Parent.RewardMachineConfig)
local Odds=require(script.Parent.RewardMachineOdds)
local RunService=game:GetService("RunService")
local ServerStorage=RunService:IsServer() and game:GetService("ServerStorage") or nil
local T={}
function T.Pool()return Odds.Build(C.Rewards,C.OddsDenominator)end
function T.Aurion()
 for _,row in ipairs(T.Pool())do if row.Id=='Aurion'then return row.ChanceText end end
 return 'Unavailable'
end
local visibilityConnection
function T.SetupVisibility(rig)
 if not RunService:IsClient() or visibilityConnection then return end
 local drum=rig:FindFirstChild('SpinningDrum') or rig:WaitForChild('SpinningDrum',20)
 if not drum then return end
 local labels={}
 local function scanLabels()
  for i=1,#C.Rewards do
   if not labels[i] or not labels[i].Face.Parent then
    local face=drum:FindFirstChild('PrizeFace_'..i,true)
    local gui=face and face:FindFirstChild('Lettering')
    if face and face:IsA('BasePart') and gui and gui:IsA('SurfaceGui') then
     gui.AlwaysOnTop=true
     gui.Enabled=false
     gui.LightInfluence=0
     gui.MaxDistance=0
     labels[i]={Face=face,Gui=gui}
    end
   end
  end
 end
 scanLabels()
 local exclude={rig}
 local district=workspace:FindFirstChild('DOGROTS_District')
 if district then
  local plaza=district:FindFirstChild('27_RewardMachinePlaza')
  local oldMachine=plaza and plaza:FindFirstChild('RewardMachine')
  if oldMachine then table.insert(exclude,oldMachine) end
  local refresh=district:FindFirstChild('36_DistrictRefresh')
  local refreshMachine=refresh and refresh:FindFirstChild('RewardMachine')
  if refreshMachine then table.insert(exclude,refreshMachine) end
 end
 local params=RaycastParams.new()
 params.FilterType=Enum.RaycastFilterType.Exclude
 params.IgnoreWater=true
 params.RespectCanCollide=false
 params.FilterDescendantsInstances=exclude
 local player=game:GetService('Players').LocalPlayer
 local currentCharacter
 local baseIgnore=exclude
 local function checkVisible()
  local camera=workspace.CurrentCamera
  if not camera then return end
  local character=player.Character
  if character~=currentCharacter then
   currentCharacter=character
   local ignore=table.clone(exclude)
   if character then table.insert(ignore,character) end
   baseIgnore=ignore
  end
  local cameraPosition=camera.CFrame.Position
  for _,entry in pairs(labels) do
   local face=entry.Face
   local gui=entry.Gui
   if face.Parent and gui.Parent then
    -- Use the original surface (and its screenshot-like black plaque),
    -- hiding it only if world geometry lies between the camera and prize.
    -- The prize face is a forward-oriented plate; avoid testing its back edge.
    local towards=face.Position+face.CFrame.LookVector*(face.Size.Z*.5+.02)-cameraPosition
    gui.AlwaysOnTop=true
    params.FilterDescendantsInstances=baseIgnore
    local blocking=workspace:Raycast(cameraPosition,towards,params)
    local skips=0
    while blocking and blocking.Instance.Transparency>=0.98 and skips<10 do
     local ignore=table.clone(params.FilterDescendantsInstances)
     table.insert(ignore,blocking.Instance)
     params.FilterDescendantsInstances=ignore
     blocking=workspace:Raycast(cameraPosition,towards,params)
     skips+=1
    end
    gui.Enabled=(blocking==nil)
   end
  end
 end
 local elapsed=0
 local scanTime=0
 checkVisible()
 visibilityConnection=RunService.Heartbeat:Connect(function(dt)
  elapsed+=dt
  scanTime+=dt
  if scanTime>=1 then scanTime=0;scanLabels() end
  if elapsed<0.07 then return end
  elapsed=0
  checkVisible()
 end)
end
local function cloneDogModel(templateName)
 if not (RunService:IsServer() and ServerStorage) then return nil end
 local templates=ServerStorage:FindFirstChild('DogTemplates')
 local source=templates and templates:FindFirstChild(templateName)
 if not source then return nil end
 local model=source:Clone()
 for _,o in ipairs(model:GetDescendants())do
  if o:IsA('LuaSourceContainer') or o:IsA('ProximityPrompt') or o:IsA('Sound') or o:IsA('BillboardGui') or o:IsA('SurfaceGui') then
   o:Destroy()
  elseif o:IsA('BasePart') then
   o.Anchored=true;o.CanCollide=false;o.CanTouch=false;o.CanQuery=false
  end
 end
 local ok,rig=pcall(function()return require(script.Parent.DogRig)end)
 if ok and rig and rig.Prepare then pcall(function()rig.Prepare(model,Vector3.new(5,5,5))end) end
 return model
end
local function ensureDogSymbol(drum,index,templateName,scale)
 if not RunService:IsServer() then return end
 local sector=drum and drum:FindFirstChild('Sector_'..index)
 local symbol=sector and sector:FindFirstChild('RewardSymbol')
 if not (symbol and symbol:IsA('Model')) then return end
 if symbol:GetAttribute('DogTemplate')==templateName then return end
 local preview=cloneDogModel(templateName)
 if not preview then return end
 local target=symbol:GetPivot()
 for _,child in ipairs(symbol:GetChildren())do child:Destroy() end
 preview.Name='DogPreviewModel'
 preview.Parent=symbol
 local cf,size=preview:GetBoundingBox()
 local extent=math.max(size.X,size.Y,size.Z)
 if extent>0 then
  preview:ScaleTo(preview:GetScale()*(scale or 3.1)/extent)
  cf,size=preview:GetBoundingBox()
 end
 local targetCFrame=target*CFrame.new(0,-0.15,0)*CFrame.Angles(0,-math.pi/2,0)
 preview:PivotTo(targetCFrame*cf:Inverse()*preview:GetPivot())
 symbol:SetAttribute('DogTemplate',templateName)
end
function T.Apply(rig,pool)
 pool=pool or T.Pool()
 local faces={}
 for _,row in ipairs(pool)do faces[row.PrizeIndex]=row end
 local board=rig:FindFirstChild('StatusBoard');local rows=board and board:FindFirstChild('OddsDisplay')and board.OddsDisplay:FindFirstChild('Rows')
 if rows then for i=1,#C.Rewards do local label=rows:FindFirstChild('Row'..i);local row=pool[i];if label then label.Visible=row~=nil;if row then label.Text=(row.Jackpot and'ULTRA RARE: 'or'')..row.Name..'  '..row.ChanceText end end end end
 local drum=rig:FindFirstChild('SpinningDrum')
 if drum then
  for i=1,#C.Rewards do
   local face=drum:FindFirstChild('PrizeFace_'..i,true)
   local gui=face and face:FindFirstChild('Lettering')
   local reward=C.Rewards[i]
   local titleText=reward and (reward.Coins and 'COIN BAG' or reward.Name) or ''
   local subtitleText=faces[i] and (faces[i].ChanceText..' CHANCE') or 'UNLOCK AT A DEEPER LAYER'
   if gui and gui:FindFirstChild('Title') then gui.Title.Text=titleText end
   if gui and gui:FindFirstChild('Subtitle') then gui.Subtitle.Text=subtitleText end
   if gui and gui:IsA('SurfaceGui') then
    gui.AlwaysOnTop=RunService:IsClient()
    gui.LightInfluence=0
    gui.MaxDistance=0
    if RunService:IsServer() then gui.Enabled=true end
   end
  end
  ensureDogSymbol(drum,1,'Breadog',3.0)
  ensureDogSymbol(drum,2,'CoffeeDog',3.0)
  ensureDogSymbol(drum,3,'DJDoggo',3.0)
 end
 if RunService:IsClient() then T.SetupVisibility(rig) end
 local aurion
 for _,row in ipairs(pool)do if row.Id=='Aurion'then aurion=row end end
 local rules=rig:FindFirstChild('TicketRules');local gui=rules and rules:FindFirstChild('Lettering')
 if gui then
  gui.Title.Text='FREE DOG TOKEN\nONE ACTIVATION'
  gui.Free.Text='FREE EVERY '..tostring(C.TicketRefillSeconds/3600)..' HOURS AFTER USE'
  gui.Capacity.Text=C.FreeOnly and('HOLDS '..C.TicketCapacity..' FREE DOG TOKEN')or 'MORE SPINS: LUCKY SPIN PACKS IN THE SHOP'
 end
 local displays=rig:FindFirstChild('RewardVitrines');local tower=displays and displays:FindFirstChild('TreasureTower')
 local plaque=tower and tower:FindFirstChild('PrizePlaque')
 if plaque and plaque:FindFirstChild('Lettering')then plaque.Lettering.Title.Text='AURION · ULTRA RARE · '..(aurion and aurion.ChanceText or'Unavailable')end
end
return T

-- Per-player exhibits: one prompt, no active dog AI, immutable production clones.
local Players=game:GetService('Players');local Run=game:GetService('RunService');local Rep=game.ReplicatedStorage
local player=Players.LocalPlayer;local Catalog=require(Rep:WaitForChild('MuseumCatalog'));local Rig=require(Rep:WaitForChild('DogRig'))
local playerGui=player:WaitForChild('PlayerGui')
local gui=playerGui:FindFirstChild('ScreenGui')
while not gui do
 local child=playerGui.ChildAdded:Wait()
 if child.Name=='ScreenGui' then gui=child end
end
local templates=game.ReplicatedStorage:WaitForChild('MenuModels')
local economy=Rep:WaitForChild('DogEconomyRequest')
local audio=require(Rep:WaitForChild('MuseumAudio'))
local state={Entries={},Count=0,Rarities={}};local records={};local currentMuseum;local revision=0;local pulling=false
local localModels=Instance.new('Folder');localModels.Name='DogDexLocalDisplays';localModels.Parent=workspace
local promptPart=Instance.new('Part');promptPart.Name='MuseumNearestEntry';promptPart.Size=Vector3.one;promptPart.Transparency=1;promptPart.Anchored=true;promptPart.CanCollide=false;promptPart.CanTouch=false;promptPart.CanQuery=false;promptPart.Parent=localModels
local prompt=Instance.new('ProximityPrompt');prompt.Name='ViewMuseumEntry';prompt.ActionText='VIEW ENTRY';prompt.MaxActivationDistance=8;prompt.RequiresLineOfSight=true;prompt.Enabled=false;prompt.Parent=promptPart
local nearest;local lastNear;local lastRead=-100;local refetch=false
local fetch
local function stateFromIndexSnapshot(snapshot)
 local out={Entries={},Count=0,Rarities={}}
 local profile=type(snapshot)=='table'and snapshot.Profile or nil
 local dex=type(profile)=='table'and profile.DogDex or nil
 if type(dex)~='table'then return nil end
 -- EXACTLY the same permanent discovery table used by the INDEX page.
 -- If INDEX considers a dog found, the physical museum considers it found too.
 for i=1,100 do
  local def=Catalog.ByIndex[i]
  if def and dex[def.Id] then
   out.Count+=1
   out.Rarities[def.Rarity]=(out.Rarities[def.Rarity]or 0)+1
   if type(def.VisualAsset)=='string'and def.VisualAsset~=''and templates:FindFirstChild(def.VisualAsset)then
    out.Entries[tostring(i)]={Id=def.Id,Name=def.DisplayName or def.Id,Rarity=def.Rarity or 'Common',Ability=def.Ability or '',VisualAsset=def.VisualAsset}
   end
  end
 end
 return out
end
local function publish(v)
 if type(v)~='table'or type(v.Entries)~='table'then return false end
 state=v;revision+=1;return true
end
fetch=function(force)
 if pulling then if force then refetch=true end;return end
 if not force and os.clock()-lastRead<1 then return end
 pulling=true;lastRead=os.clock()
 task.spawn(function()
  local transport,success,snapshot=pcall(function()return economy:InvokeServer('Snapshot',{},nil)end)
  if transport and success and type(snapshot)=='table'then
   local exact=stateFromIndexSnapshot(snapshot)
   if exact then publish(exact)end
  end
  pulling=false
  if refetch then refetch=false;task.defer(function()fetch(true)end)end
 end)
end
-- Every permanent discovery refreshes the physical collection immediately.
player:GetAttributeChangedSignal('DogDexCount'):Connect(function()fetch(true)end)
player:GetAttributeChangedSignal('MuseumDexCount'):Connect(function()fetch(true)end)
player:GetAttributeChangedSignal('EconomyReady'):Connect(function()if player:GetAttribute('EconomyReady')then fetch(true)end end)
-- Every MenuModels dog is a skinned mesh. The old clone destroyed RootPart (which carries the
-- Bone tree of several rigs), every Bone and the AnimationController before rescaling; no
-- other system renders dogs that way, and the stands stayed empty. Keep the production rig
-- intact (static, nothing is animated) exactly like the conveyor, kennels and menu
-- previews, and size it with the shared DogRig contract.
local function cloneStatic(source,silhouette)
 local m=source:Clone()
 for _,o in m:GetDescendants()do
  if o:IsA('LuaSourceContainer')or o:IsA('Humanoid')or o:IsA('Constraint')or o:IsA('Sound')or o:IsA('ProximityPrompt')or o:IsA('LayerCollector')or o:IsA('ParticleEmitter')or o:IsA('Trail')or o:IsA('Beam')or o:IsA('ValueBase')or o:IsA('Light')then o:Destroy()
  elseif silhouette and(o:IsA('SurfaceAppearance')or o:IsA('Decal')or o:IsA('Texture'))then o:Destroy()
  elseif o:IsA('BasePart')then
   o.Anchored=true;o.CanCollide=false;o.CanTouch=false;o.CanQuery=false;o.CastShadow=false
   -- Only visible pieces turn black; the invisible RootPart keeps Transparency 1.
   if silhouette and o.Transparency<1 and o.Name~='RootPart'then o.Color=Color3.fromRGB(13,12,16);o.Material=Enum.Material.SmoothPlastic;o.Transparency=0;o.Reflectance=0;if o:IsA('MeshPart')then o.TextureID=''end end
  end
 end
 m.Name=silhouette and 'UnknownSilhouette'or source.Name
 return m
end
-- DogRig.Prepare: pivot to identity, bind pose, scale into the FitWidth/Height/Depth box.
-- The dog's ground centre then stands on DisplayOrigin, facing out of the niche.
local function fit(m,origin)
 local w=origin:GetAttribute('FitWidth')or 5.8;local h=origin:GetAttribute('FitHeight')or 9;local d=origin:GetAttribute('FitDepth')or 3.9
 local prepared=Rig.Prepare(m,Vector3.new(w,h,d));if not prepared then return false end
 m:PivotTo(origin.CFrame*CFrame.new(-prepared.Ground))
 return true
end
local function destroyRecord(rec)
 if rec.model then rec.model:Destroy()end
 records[rec.root]=nil
end
local function discover(root)
 if not root:IsA('Model')or records[root]then return end
 local previewIndex=root:GetAttribute('PreviewIndex')
 local index=root:GetAttribute('DexIndex')or previewIndex or tonumber(root.Name:match('^DexSlot_(%d+)$'))
 if index and Catalog.ByIndex[index]then records[root]={root=root,index=index,preview=previewIndex~=nil,rev=-1}end
end
local failed={}
local function apply(rec,visible,budget)
 local root=rec.root;local origin=root:FindFirstChild('DisplayOrigin');if not origin then return budget end
 local entry=state.Entries[tostring(rec.index)];local source=entry and templates:FindFirstChild(entry.VisualAsset)
 local unlocked=source~=nil;local key=visible and(unlocked and entry.Id or 'silhouette')or 'hidden'
 -- A locked exhibit shows the black silhouette of the dog that belongs there.
 local def=Catalog.ByIndex[rec.index];local shape=def and templates:FindFirstChild(def.VisualAsset or '')
 local shapeId=shape and def.Id or 'Breadog';shape=shape or templates:FindFirstChild('Breadog')
 -- Builds are budgeted per tick (nearest first); a failed build only skips its own stand.
 if rec.key~=key and(key=='hidden'or budget>0)then
  if rec.model then rec.model:Destroy();rec.model=nil end
  if key~='hidden'then
   budget-=1
   local silhouette=key=='silhouette';local src=silhouette and shape or source
   local ok,m=pcall(function()
    local m=cloneStatic(src,silhouette)
    if not fit(m,origin)then m:Destroy();error('no visible parts')end
    return m
   end)
   if ok then
    m:SetAttribute('MuseumDisplay',true);m:SetAttribute('LogicalIndex',rec.index);m:SetAttribute('Locked',not unlocked);m:SetAttribute('SourceDogId',silhouette and shapeId or entry.Id);m.Parent=localModels;rec.model=m
   elseif not failed[key..rec.index]then failed[key..rec.index]=true;warn('[Museum] exhibit #'..rec.index..' ('..key..') not displayed:',m)end
  end
  rec.key=key
 end
 if rec.rev~=revision or rec.plaque~=root:FindFirstChild('EntryPlaque')then
  local plaque=root:FindFirstChild('EntryPlaque');local label=plaque and plaque:FindFirstChildWhichIsA('TextLabel',true)
  rec.plaque=plaque
  if label then label.Text=string.format('#%03d',rec.index)..'\n'..(unlocked and entry.Name..' · '..entry.Rarity or '???');label.TextColor3=unlocked and Color3.fromRGB(255,219,145)or Color3.fromRGB(164,150,125)end
  local caption=root:FindFirstChild('AbilityCaption');local ct=caption and caption:FindFirstChildWhichIsA('TextLabel',true)
  if ct then ct.Text=unlocked and('◇  '..Catalog.AbilityLabel(entry.Ability))or''end
  local trim=root:FindFirstChild('DiscoveryLight');if trim then trim.Color=unlocked and Color3.fromRGB(255,219,153)or Color3.fromRGB(102,75,43);trim.Material=unlocked and Enum.Material.Neon or Enum.Material.SmoothPlastic end
  local lamp=root:FindFirstChild('FinalUnlockLight',true);if lamp then lamp:SetAttribute('MuseumUnlocked',unlocked)end
  rec.rev=revision;root:SetAttribute('LocallyDiscovered',unlocked)
 end
end
local function updateProgress(museum)
 local reception=museum:FindFirstChild('NavigationAndReception');if not reception then return end
 local title=reception:FindFirstChild('ReceptionTitle');local label=title and title:FindFirstChildWhichIsA('TextLabel',true)
 if label then label.Text='DOGDEX PROGRESS\n'..state.Count..' / 100'end
 local bar=reception:FindFirstChild('ProgressBar');if bar then bar.Size=Vector3.new(math.max(.08,8*math.clamp(state.Count/100,0,1)),.15,.1)end
 local honours=reception:FindFirstChild('CollectionHonours');if honours then for _,p in honours:GetChildren()do local t=p:FindFirstChildWhichIsA('TextLabel',true);if t then t.TextColor3=state.Count>=(p:GetAttribute('Milestone')or 100)and Color3.fromRGB(255,209,127)or Color3.fromRGB(107,105,103)end end end
 museum:SetAttribute('LocalDiscoveredCount',state.Count)
end
prompt.Triggered:Connect(function()
 if not nearest then return end
 local menus=require(gui.Modules.Menus).Active;if menus then menus.state.SelectedDexIndex=nearest.index;menus:Show('DexEntry');menus:Fetch(true)end
end)
local elapsed=0;local scan=0;local museumLights={};local streamed
local function manageLighting(museum)
 local camera=workspace.CurrentCamera;if not camera then return end
 local inside=(CFrame.new(-131,0,481)*CFrame.Angles(0,-math.pi/2,0)):PointToObjectSpace(camera.CFrame.Position).Z>-58
 local quality=UserSettings():GetService('UserGameSettings').SavedQualityLevel.Value
 local low=player:GetAttribute('LowFX')or player:GetAttribute('WorldEventFX')=='Low'or(quality>0 and quality<=3)
 local options={}
 for light in pairs(museumLights)do
  if not light:IsDescendantOf(museum)then museumLights[light]=nil;continue end
  local parent=light.Parent;local distance=parent:IsA('BasePart')and(parent.Position-camera.CFrame.Position).Magnitude or 999
  local exterior=light.Name=='FacadeWarmLight'or light.Name=='StatueWarmWash'or light.Name=='SharedPreviewLight'or light.Name=='PlazaWarmLight'
  light.Enabled=false
  if distance<210 and(light.Name~='FinalUnlockLight'or light:GetAttribute('MuseumUnlocked'))then
   table.insert(options,{Light=light,Score=distance+(inside==exterior and 130 or 0)})
  end
 end
 table.sort(options,function(a,b)return a.Score<b.Score end)
 for i=1,math.min(#options,low and 7 or 18)do options[i].Light.Enabled=true end
 museum:SetAttribute('LocalEnabledLights',math.min(#options,low and 7 or 18))
end
Run.Heartbeat:Connect(function(dt)
 elapsed+=dt;scan+=dt;if elapsed<.3 then return end;elapsed=0
 local map=workspace:FindFirstChild('DOGROTS_District');local museum=map and map:FindFirstChild('06_DogDexMuseum')
 local hrp=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
 if not museum or not hrp then
  prompt.Enabled=false;audio.SetInside(false)
  for _,rec in pairs(records)do destroyRecord(rec)end;currentMuseum=nil;return
 end
 if currentMuseum~=museum then
  for _,v in pairs(records)do destroyRecord(v)end;currentMuseum=museum;scan=10
  -- StreamingEnabled: exhibits (and their DisplayOrigin) arrive whenever the server streams
  -- them in; register them as they land instead of waiting for the next full sweep.
  if streamed then streamed:Disconnect()end
  streamed=museum.DescendantAdded:Connect(function(o)
   if o:IsA('Model')then discover(o)elseif o.Parent and o.Parent:IsA('Model')then discover(o.Parent)end
   if o:IsA('Light')and o:GetAttribute('MuseumLight')then museumLights[o]=true end
  end)
 end
 if scan>=10 then scan=0;for _,o in museum:GetDescendants()do discover(o);if o:IsA('Light')and o:GetAttribute('MuseumLight')then museumLights[o]=true end end end
 manageLighting(museum)
 local inRange=(hrp.Position-Vector3.new(-131,15,481)).Magnitude<155
 local localPos=(CFrame.new(-131,0,481)*CFrame.Angles(0,-math.pi/2,0)):PointToObjectSpace(hrp.Position)
 audio.SetInside(math.abs(localPos.X)<58 and localPos.Z>-57 and localPos.Z<67 and localPos.Y>2 and localPos.Y<49)
 local expected=player:GetAttribute('MuseumDexCount')
 local behind=type(expected)=='number'and state.Count<expected
 -- Discoveries already refresh through DogDexCount/MuseumDexCount; the timed read is only a
 -- safety net (it rebuilt the whole economy snapshot every 4 s for everyone nearby).
 if inRange and(not lastNear or behind or os.clock()-lastRead>20)then fetch(not lastNear or behind)end;lastNear=inRange
 local ordered={};for root,rec in pairs(records)do
  local origin=root:FindFirstChild('DisplayOrigin')
  if not root:IsDescendantOf(museum)then destroyRecord(rec)
  elseif not origin then if rec.model then rec.model:Destroy();rec.model=nil;rec.key=nil end;rec.rev=-1
  elseif origin then rec.distance=(origin.Position-hrp.Position).Magnitude;table.insert(ordered,rec)end
 end
 table.sort(ordered,function(a,b)return a.distance<b.distance end)
 local full=0;nearest=nil;local budget=8
 for _,rec in ipairs(ordered)do
  local sameFloor=math.abs(hrp.Position.Y-(rec.root.DisplayOrigin.Position.Y+1))<7
  if not nearest and not rec.preview and sameFloor and rec.distance<10 then nearest=rec end
  local near=rec.distance<Catalog.NearDistance and full<Catalog.MaxNearModels
  if near and state.Entries[tostring(rec.index)]then full+=1 end
  -- One faulty stand must never abort the remaining stands, the prompt or the progress board.
  local ok,left=pcall(apply,rec,inRange and rec.distance<Catalog.FarDistance,budget)
  if ok then budget=left elseif not failed[rec]then failed[rec]=true;warn('[Museum] exhibit #'..rec.index..':',left)end
 end
 if nearest then
  promptPart.CFrame=nearest.root.DisplayOrigin.CFrame*CFrame.new(0,1,-2.7);prompt.ObjectText=string.format('DOGDEX #%03d',nearest.index)
 end
 prompt.Enabled=nearest~=nil and gui:GetAttribute('OpenMenu')==nil
 updateProgress(museum)
 museum:SetAttribute('LocalFullModels',full)
end)
fetch(true)

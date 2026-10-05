-- Manual Studio audit; never runs during normal gameplay.
local Audit={}
function Audit.Run(preload)
 local RS=game:GetService('ReplicatedStorage')
 local SS=game:GetService('ServerStorage')
 local Definitions=require(RS.DogEconomy.DogDefinitions)
 local Player=require(RS.DogAnimationPlayer)
 local templates=SS.DogTemplates
 local previews=game.ReplicatedStorage:WaitForChild('MenuModels')
 local results={dogs=0,clips=0,bones=0,failures={},assetFailures={},preloadRequested=preload==true}
 local indexes,visuals={},{}
 local ordered={}
 for id,d in pairs(Definitions) do table.insert(ordered,{id=id,definition=d}) end
 table.sort(ordered,function(a,b)return a.definition.Index<b.definition.Index end)
 local temporary=Instance.new('Folder');temporary.Name='DogIntegrationAuditTemporary';temporary.Parent=workspace
 for _,entry in ordered do
  local id,d=entry.id,entry.definition
  local clone,player
  local ok,err=pcall(function()
   assert(not indexes[d.Index],'duplicate index');indexes[d.Index]=true
   assert(not visuals[d.VisualAsset],'duplicate visual');visuals[d.VisualAsset]=true
   assert(d.Available and not d.Reserved,'unavailable definition')
   assert(d.Price>0 and d.Rarity and d.Ability,'invalid economy fields')
   local template=assert(templates:FindFirstChild(d.VisualAsset),'missing template')
   assert(previews:FindFirstChild(d.VisualAsset),'missing preview')
   assert(template.PrimaryPart and template:FindFirstChild('RootPart',true),'missing root')
   local library=assert(RS.DogAnimationClips:FindFirstChild(id),'missing library')
   clone=template:Clone();clone.Parent=temporary
   local _,size=clone:GetBoundingBox();clone:ScaleTo(clone:GetScale()*math.min(5/size.Y,8/size.X,8/size.Z))
   clone:PivotTo(CFrame.new(0,1000,0));player=Player.new(clone,id)
   local names={}
   for _,bone in clone:GetDescendants() do if bone:IsA('Bone') then assert(not names[bone.Name],'duplicate bone '..bone.Name);names[bone.Name]=true;results.bones+=1 end end
   assert(next(names),'empty rig')
   for _,module in library:GetChildren() do
    if not module:IsA('ModuleScript') then continue end
    local raw=require(module)
    assert(raw.duration>0 and raw.fps>0 and type(raw.tracks)=='table','invalid clip '..module.Name)
    for name,frames in pairs(raw.tracks) do
     assert(names[name],'unbound track '..module.Name..'/'..name)
     assert(#frames>0,'empty track')
     for _,v in frames do for _,number in ipairs(v) do assert(number==number and math.abs(number)<math.huge,'nonfinite frame') end end
    end
    assert(player:Play(module.Name,{StartTime=workspace:GetServerTimeNow()}),'cannot play '..module.Name)
    for _,fraction in ipairs({0,.17,.51,.91,1}) do player:Sample(raw.duration*fraction) end
    player:Stop();results.clips+=1
   end
   assert(player:Play(id=='Vampug' and 'Sleep' or 'Idle'),'rest unavailable');assert(player:Play('Walk'),'Walk unavailable')
   if preload then
    local completed=false
    local loading=task.spawn(function()
     local loaded,reason=pcall(function() game:GetService('ContentProvider'):PreloadAsync({clone},function(asset,status)
      if status~=Enum.AssetFetchStatus.Success then table.insert(results.assetFailures,{dog=id,asset=asset,status=tostring(status)}) end
     end) end)
     if not loaded then table.insert(results.assetFailures,{dog=id,status=tostring(reason)}) end
     completed=true
    end)
    local deadline=os.clock()+15
    repeat task.wait(.05) until completed or os.clock()>=deadline
    if not completed then task.cancel(loading);table.insert(results.assetFailures,{dog=id,status='Preload timeout after 15 seconds'}) end
   end
   results.dogs+=1
  end)
  if player then player:Destroy() end
  if clone then clone:Destroy() end
  if not ok then table.insert(results.failures,{dog=id,error=tostring(err)});warn('DOG_AUDIT_FAILURE',id,err) end
  if d.Index%10==0 then print('DOG_AUDIT_PROGRESS',d.Index,results.clips);task.wait() end
 end
 temporary:Destroy()
 print('DOG_AUDIT_RESULT '..game:GetService('HttpService'):JSONEncode(results))
 return results
end
function Audit.Economy()
 local R=require(game.ServerScriptService.Economy.Rules)
 local D=require(game.ReplicatedStorage.DogEconomy.DogDefinitions)
 local H=game:GetService('HttpService')
 local results={passed=0,failures={}}
 for id,def in pairs(D) do
  local ok,err=pcall(function()
   local now=os.time()
   for offset=0,3 do local candidate=now+offset*604800;if R.Available(def,candidate) then now=candidate;break end end
   local p=R.Profile(123456,now);p.Cash=def.Price
   R.Pay(p,def.Price);assert(p.Cash==0,'price debit')
   local uid='audit-'..id
   local d=R.Mint(p,id,uid,{},now,function()return .5 end,'IntegrationAudit')
   assert(p.DogDex[id] and p.Dogs[uid]==d,'inventory/discovery registration')
   R.Assign(p,uid,'DigSlot_1',now);R.Validate(p)
   d.NextWorkAt=now;R.Dig(p,now,function()return .5 end);R.Validate(p)
   assert(d.WorkSequence>0,'work did not complete')
   p=R.Normalize(H:JSONDecode(H:JSONEncode(p)),123456,now);R.Validate(p)
   assert(p.Dogs[uid].DogId==id and p.DogDex[id],'save round trip')
   R.Action(p,'Remove',{Uid=uid},now,function()return .5 end);R.Validate(p)
   assert(p.Dogs[uid].AssignedSlot=='','unequip')
  end)
  if ok then results.passed+=1 else table.insert(results.failures,{dog=id,error=tostring(err)}) end
 end
 print('DOG_ECONOMY_AUDIT '..H:JSONEncode(results));return results
end
return Audit

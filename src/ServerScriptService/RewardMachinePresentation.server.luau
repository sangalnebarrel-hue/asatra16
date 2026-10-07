-- Rewards commit before presentation. Clients animate from the server clock.
local RS=game:GetService('ReplicatedStorage');local Http=game:GetService('HttpService');local Run=game:GetService('RunService')
local district=workspace:WaitForChild('DOGROTS_District')
local rig=district:WaitForChild('37_AttractionRefresh'):WaitForChild('RewardMachineRig')
local machine=district:WaitForChild('27_RewardMachinePlaza'):WaitForChild('RewardMachine')
local prompt=assert(machine:FindFirstChild('RewardMachinePrompt',true),'Reward machine prompt missing')
local motion=require(RS.RewardMachineMotion);local config=require(RS.RewardMachineConfig)
local service=require(script.Parent.Economy.RewardMachineService);local commerce=require(script.Parent.Economy.YardCommerce)
local center=rig.CameraHooks.DrumCenter.CFrame;local drum=rig.SpinningDrum
local remote=RS:FindFirstChild('RewardMachinePresentation')or Instance.new('RemoteEvent');remote.Name='RewardMachinePresentation';remote.Parent=RS
require(RS.RewardMachineText).Apply(rig)
local angle=0;local busy=false;local playerAttempts={};local animated={}
-- A Secret prize's arrival owns the stand until its Hold ends: no spin and no clearPrize
-- before then (os.clock). Clients read PrizeHoldUntil (server clock) to grey out ACTIVATE.
local holdUntil,holdName=0,nil
-- The prize stays on the stand for a while, then the stand returns to the jackpot hologram.
local PrizeLinger={Default=75,Secret=120}
local prizeSerial=0;local idleTitle=rig.WorldResult.Lettering.Title.Text
local function clearPrize()prizeSerial+=1;local old=rig:FindFirstChild('CommittedPrize');if old then old:Destroy()end end
local Reveal=require(script.Parent.SecretReveal)
local Hooks=require(RS.DogDisplayHooks)
local Definitions=require(script.Parent.Economy.DogDefinitions)
-- The Aurion models built into the machine (the drum's sector 9, the TreasureTower vitrine).
for _,o in ipairs(rig:GetDescendants())do
 if o:IsA('Model')and o:GetAttribute('DogId')=='Aurion'then Hooks.Prepared(o,'Aurion','Static')end
end
local function holdReason()
 local left=holdUntil-os.clock()
 if left>0 then return (holdName or 'The prize')..' is arriving on the stand · try again in '..math.ceil(left)..'s'end
end
local function display(result,winner)
 clearPrize();local container=Instance.new('Model');container.Name='CommittedPrize';container.Parent=rig
 local focus=rig.CameraHooks.RevealFocus;local spawn=rig.CameraHooks.RewardSpawn
 rig.WorldResult.Lettering.Title.Text=(motion.UltraRare(result)and 'ULTRA RARE!  'or '')..result.Name
 local def=result.Dog and Definitions[result.Dog.DogId]
 local secret=def and Reveal.Has(result.Dog.DogId)and def.Rank==6
 if secret then
  -- A Secret prize performs its arrival on the reward stand and stays as the prize.
  local ok,model=pcall(Reveal.Show,result.Dog.DogId,spawn.Position,CFrame.Angles(0,-math.pi/2,0).LookVector,
   {Venue='Machine',By=winner,Linger=false,Parent=container})
  if not ok or not model then secret=false end
 end
 if secret then
  -- Already on the stand (SecretReveal). Its arrival must not be cut short by the next spin.
  local hold=Reveal.Hold(result.Dog.DogId)
  holdUntil=os.clock()+hold;holdName=def.DisplayName
  rig:SetAttribute('PrizeHoldUntil',workspace:GetServerTimeNow()+hold);rig:SetAttribute('PrizeHoldName',def.DisplayName)
 elseif result.Dog then
  local source=def and game.ServerStorage.DogTemplates:FindFirstChild(def.VisualAsset)
  if source then
   local model=source:Clone();model.Name='WinningDog'
   for _,o in ipairs(model:GetDescendants())do
    if o:IsA('LuaSourceContainer')or o:IsA('ProximityPrompt')or o:IsA('Sound')or o:IsA('BillboardGui')or o:IsA('SurfaceGui')then o:Destroy()
    elseif o:IsA('BasePart')then o.Anchored=true;o.CanCollide=false;o.CanTouch=false;o.CanQuery=false end
   end
   local prepared=require(RS.DogRig).Prepare(model,Vector3.new(12,10,12))
   if prepared then
    local cf,size=model:GetBoundingBox();local target=CFrame.new(spawn.Position+Vector3.new(0,size.Y/2,0))*CFrame.Angles(0,-math.pi/2,0)
    model:PivotTo(target*cf:Inverse()*model:GetPivot());Hooks.Prepared(model,result.Dog.DogId,'Machine');model.Parent=container
   else model:Destroy()end
  end
 elseif result.Item then
  local model=require(RS.DogEconomy.DiscoveryVisuals).Clone(result.Item)
  if model then local cf,size=model:GetBoundingBox();model:ScaleTo(model:GetScale()*math.min(3,11/math.max(size.X,size.Y,size.Z)));cf,size=model:GetBoundingBox();model:PivotTo(CFrame.new(spawn.Position+Vector3.new(0,size.Y/2,0))*cf:Inverse()*model:GetPivot());model.Parent=container end
 else
  -- Use the same authored reward models as the offer previews: embossed coins,
  -- a recognizable bone, and the labeled energy snack instead of generic balls.
  local model=require(RS.EconomyRewardVisuals).Build(result)
  if model then
   model.Name='Winning'..result.Kind
   for _,o in ipairs(model:GetDescendants())do
    if o:IsA('BasePart')then o.Anchored=true;o.CanCollide=false;o.CanTouch=false;o.CanQuery=false
    elseif o:IsA('TextLabel')or o:IsA('TextButton')then o.Font=Enum.Font.FredokaOne
    elseif o:IsA('LuaSourceContainer')or o:IsA('ProximityPrompt')or o:IsA('Sound')then o:Destroy()end
   end
   local cf,size=model:GetBoundingBox();local extent=math.max(size.X,size.Y,size.Z)
   if extent>0 then
    model:ScaleTo(model:GetScale()*12/extent);cf,size=model:GetBoundingBox()
    local target=spawn.CFrame*CFrame.new(0,size.Y/2,0)
    model:PivotTo(target*cf:Inverse()*model:GetPivot());model.Parent=container
   else model:Destroy()end
  end
 end
 local anchor=Instance.new('Part');anchor.Name='RewardLabel';anchor.Anchored=true;anchor.CanCollide=false;anchor.CanQuery=false;anchor.CanTouch=false;anchor.Transparency=1;anchor.Size=Vector3.one;anchor.CFrame=focus.CFrame*CFrame.new(0,13,0);anchor.Parent=container
 local gui=Instance.new('BillboardGui');gui.Enabled=false;gui.Size=UDim2.fromOffset(360,92);gui.MaxDistance=130;gui.AlwaysOnTop=false;gui.Parent=anchor
 local text=Instance.new('TextLabel');text.Size=UDim2.fromScale(1,1);text.BackgroundColor3=Color3.fromRGB(14,19,45);text.BackgroundTransparency=.12;text.Font=Enum.Font.FredokaOne;text.TextSize=27;text.TextWrapped=true;text.TextColor3=motion.Color(result);text.TextStrokeTransparency=.5
 text.Text=(motion.UltraRare(result)and 'ULTRA RARE!  'or '')..result.Name..'\n'..motion.Rarity(result):upper();text.Parent=gui
 local corner=Instance.new('UICorner');corner.CornerRadius=UDim.new(0,16);corner.Parent=text
 -- Later the stand goes back to the jackpot hologram (AurionShowcase) unless a newer prize came.
 local serial=prizeSerial
 local function idle()
  if prizeSerial~=serial then return end
  if busy or os.clock()<holdUntil then task.delay(10,idle);return end
  clearPrize();rig.WorldResult.Lettering.Title.Text=idleTitle
 end
 task.delay(secret and Reveal.Hold(result.Dog.DogId)+PrizeLinger.Secret or PrizeLinger.Default,idle)
end
service.WorldEligibility=function(player)local near=commerce.Near(player,prompt.Parent,18);return near,near and nil or 'Move closer to DOG-O-MATIC'end
local function release()busy=false;rig:SetAttribute('Spinning',false);machine:SetAttribute('Spinning',false)end
-- A jackpot is news for the whole server (after the drum lands, so the winner's spin is not spoiled).
local function announce(player,result,preview)
 local reward=RS:FindFirstChild('RewardPresentation');if not reward then return end
 local text=string.upper(player.DisplayName)..' WON '..string.upper(result.Name)..' AT DOG-O-MATIC! · '..tostring(result.ChanceText or require(RS.RewardMachineText).Aurion())
 reward:FireAllClients({Announcement=(preview and 'STUDIO PREVIEW · 'or '')..text,Tier='Secret'})
end
-- The world presentation of one committed activation (or a Studio preview): every client
-- spins the drum from the same cue, then the prize is staged on the stand. busy is held.
local function present(player,result,requested,preview)
 animated[result.Receipt]=true;local index=result.PrizeIndex
 if not index then for i,row in ipairs(config.Rewards)do if row.Name==result.Name then index=i;break end end end;index=index or 1
 local serverNow=workspace:GetServerTimeNow()
 if not requested or requested<serverNow-1 or requested>serverNow+.15 then requested=serverNow end
 local presentation={StartedAt=requested,Duration=motion.Duration,PrizeIndex=index,Rarity=motion.Rarity(result),StartAngle=angle}
 result.Presentation=presentation
 local cue={Receipt=result.Receipt,Id=result.Id,Name=result.Name,Kind=result.Kind,Jackpot=result.Jackpot,Rarity=presentation.Rarity,Chance=result.Chance,ChanceText=result.ChanceText,WinnerName=player.DisplayName,WinnerUserId=player.UserId,Preview=preview==true,Presentation=presentation}
 clearPrize();rig.WorldResult.Lettering.Title.Text='ACTIVATING...';rig:SetAttribute('SpinInfo',Http:JSONEncode(cue));rig:SetAttribute('WinnerUserId',player.UserId);remote:FireAllClients(cue)
 task.delay(math.max(0,presentation.StartedAt+presentation.Duration-workspace:GetServerTimeNow()),function()
  local success,err=pcall(function()
   angle=motion.Target(index);drum:PivotTo(center*CFrame.Angles(0,0,angle));rig:SetAttribute('RestAngle',angle)
   rig:SetAttribute('LastReward',result.Name);machine:SetAttribute('LastReward',result.Name);display(result,player.DisplayName)
  end)
  if not success then warn('Reward machine reveal deferred:',err)end
  if motion.UltraRare(result)then pcall(announce,player,result,preview)end
  release()
 end)
 task.delay(120,function()animated[result.Receipt]=nil end)
end
service.RequestWorldSpin=function(player,args)
 if busy then return false,'The drum is spinning; please wait'end
 local hold=holdReason();if hold then return false,hold end
 if os.clock()-(playerAttempts[player.UserId]or -5)<2 then return false,'Please wait before trying again'end
 playerAttempts[player.UserId]=os.clock()
 if not commerce.Near(player,prompt.Parent,18)then return false,'Move closer to DOG-O-MATIC'end
 busy=true;rig:SetAttribute('Spinning',true);machine:SetAttribute('Spinning',true)
 local transport,ok,result=pcall(service.Request,player,'RewardMachineActivate',args,true)
 if not transport or not ok then release();return false,transport and tostring(result)or 'Activation unavailable; please retry'end
 if animated[result.Receipt]or os.time()-(result.At or 0)>10 then release();return true,result end
 local presented,err=pcall(present,player,result,tonumber(args and args.StartedAt),false)
 if not presented then warn('Reward machine presentation failed:',err);release()end
 return true,result
end
-- Studio only (the F7 SECRETS panel, via DogLineSpawner): a DOG-O-MATIC dog prize is shown the
-- way a winner sees it. The drum spins to its sector with the normal cue, the dog arrives on
-- the stand (Venue 'Machine') and the tester is put in front of the stand with the machine
-- open. Display only: nothing is minted, saved or charged.
if Run:IsStudio()then
 local function standInFront(player)
  local character=player.Character;local root=character and character:FindFirstChild('HumanoidRootPart')
  if not root or not root:IsA('BasePart')then return end
  local spawn=rig.CameraHooks.RewardSpawn;local mark=rig.CameraHooks:FindFirstChild('PlayerMark')
  local spot=(mark and mark.Position or spawn.Position+Vector3.new(15,2.6,0))+Vector3.new(6,.4,0)
  if (root.Position-spot).Magnitude<12 then return end
  character:PivotTo(CFrame.lookAt(spot,Vector3.new(spawn.Position.X,spot.Y,spawn.Position.Z)))
 end
 service.PreviewWorldPrize=function(player,dogId)
  if busy then return false,'The drum is spinning; please wait'end
  local hold=holdReason();if hold then return false,hold end
  local index,row
  for i,r in ipairs(config.Rewards)do if r.Kind=='Dog'and r.Id==dogId then index,row=i,r;break end end
  local def=Definitions[dogId]
  if not index or not def then return false,tostring(dogId)..' is not a DOG-O-MATIC prize'end
  local chance=require(RS.RewardMachineOdds).Build(config.Rewards,config.OddsDenominator)[index]
  local result={Kind='Dog',Id=dogId,Name=row.Name,Receipt='studio-'..Http:GenerateGUID(false):gsub('-',''),At=os.time(),
   Chance=chance and chance.Chance,ChanceText=chance and chance.ChanceText,Jackpot=row.Jackpot==true,Rarity=def.Rarity,PrizeIndex=index,
   Dog={DogId=dogId,DisplayName=def.DisplayName,Variant='Normal',Rarity=def.Rarity}}
  busy=true;rig:SetAttribute('Spinning',true);machine:SetAttribute('Spinning',true)
  pcall(standInFront,player)
  local ok,err=pcall(present,player,result,nil,true)
  if not ok then release();return false,'Preview failed: '..tostring(err)end
  local open=RS:FindFirstChild('DogEconomyOpen');if open then open:FireClient(player,'RewardMachine')end
  return true,def.DisplayName..' is arriving at DOG-O-MATIC (preview · nothing is minted)'
 end
end
prompt.ActionText='ACTIVATE · 1 DOG TOKEN';prompt.ObjectText='DOG-O-MATIC';prompt.HoldDuration=0;prompt.Enabled=true
prompt.Triggered:Connect(function(player)if commerce.Near(player,prompt.Parent,18)then RS.DogEconomyOpen:FireClient(player,'RewardMachine')end end)
game.Players.PlayerRemoving:Connect(function(player)playerAttempts[player.UserId]=nil end)
print('DOGROTS_REWARD_MACHINE_READY')

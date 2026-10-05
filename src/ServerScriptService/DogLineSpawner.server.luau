print("DOGROTS_DOG_LINE_READY")
local Economy = require(script.Parent.Economy.Runtime)
local TweenService = game:GetService("TweenService")
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")
local Rig=require(game:GetService("ReplicatedStorage").DogRig)

local map = workspace:WaitForChild("DOGROTS_District")
local line = map:WaitForChild("03_DogLine")
local yards = map:WaitForChild("04_PlayerYards")
local spawnPoint, endPoint = line:WaitForChild("DogSpawn"), line:WaitForChild("DogEnd")
local active = line:WaitForChild("ActiveDogs")
local templates = ServerStorage:WaitForChild("DogTemplates")
local definitions = require(ServerStorage:WaitForChild("DogDefinitions"))
local rng = Random.new()
local tweens = {}
local Replicated=game:GetService('ReplicatedStorage')
local Stream=require(Replicated.LuckyBlockConfig).Stream
local Blocks=require(script.Parent.Economy.RewardService)
local BlockConfig=require(Replicated.LuckyBlockConfig)
local BlockVisuals=require(Replicated.LuckyBlockVisuals)
local Arrivals=require(Replicated.SecretArrivalConfig)
local Format=require(Replicated.PriceFormat)
local WALK_SPEED=Stream.Speed
local travel,lastSpawn=0,0
-- A Secret with a SpeedScale (THE DOG) slows the whole tongue while it is on it, and
-- one with FreezeLine stops it dead (everything idles) while it arrives.
local lineScale,lineFrozen=1,false
local travelPublishedAt=0
local entries={}
local spacing=Stream.SlotLength*(Stream.EmptySlots+1)
line:SetAttribute('StreamSlotLength',Stream.SlotLength);line:SetAttribute('EmptySlots',Stream.EmptySlots)
local function dissolve(model)
 model:SetAttribute('LocomotionSpeed',0)
 model:SetAttribute('State','Despawning')
 for _,p in ipairs(model:GetDescendants())do
  if p:IsA('ProximityPrompt')then p.Enabled=false
  elseif p:IsA('BasePart')then TweenService:Create(p,TweenInfo.new(.65),{Transparency=1,Size=p.Size*.3}):Play()
  elseif p:IsA('BillboardGui')then p.Enabled=false end
 end
 task.delay(.7,function()if model.Parent then model:Destroy()end end)
end
local RARITY = {["Brainrot God"]=Color3.fromRGB(255,230,110),Secret=Color3.fromRGB(245,245,255),Uncommon=Color3.fromRGB(100,210,75),Common=Color3.fromRGB(220,220,220),Rare=Color3.fromRGB(70,150,255),Epic=Color3.fromRGB(190,80,255),Legendary=Color3.fromRGB(255,180,40),Mythic=Color3.fromRGB(255,60,100)}

local function pivotOf(o) return o:IsA("Model") and o:GetPivot() or o.CFrame end
local function movePivot(o, cf)
    if o:IsA("Model") then
        local root = o:GetAttribute("RootWelded") and o.PrimaryPart
        if root then root.CFrame = cf * root.PivotOffset:Inverse() else o:PivotTo(cf) end
    else o.CFrame = cf end
end
-- Conveyor entities move every frame. Moving an all-anchored model replicates every
-- part's CFrame to every client (a lucky block has ~100 parts). Welding the clone to
-- its anchored root sends one CFrame per entity; welded parts follow on each client.
local function weldToRoot(model)
    local root = model.PrimaryPart
    if not root then return false end
    for _, item in ipairs(model:GetDescendants()) do
        -- Client FX animates these shards by CFrame; moving a welded part would drag the whole model.
        if item:IsA("BasePart") and item:GetAttribute("LuckyFloat") then return false end
    end
    for _, joint in ipairs(model:GetDescendants()) do
        if joint:IsA("JointInstance") then joint.Enabled = false end
    end
    for _, part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") and part ~= root and part.Anchored then
            local weld = Instance.new("WeldConstraint")
            weld.Part0 = root
            weld.Part1 = part
            weld.Parent = part
            part.Massless = true
            part.Anchored = false
        end
    end
    root.Anchored = true
    model:SetAttribute("RootWelded", true)
    return true
end
-- Imported rigs remain intact; only spawned clones are sized and anchored.
local function anchorModel(dog)
    local prepared=Rig.Prepare(dog,Vector3.new(10,6,10))
    if not prepared then return false end
    local root=prepared.Root
    local label=Instance.new("Attachment")
    label.Name="DogLabelAnchor"
    label.Position=Vector3.new((prepared.Low.X+prepared.High.X)/2,prepared.High.Y+1.5,(prepared.Low.Z+prepared.High.Z)/2)
    label.Parent=root
    weldToRoot(dog)
    return true
end

local belt = line:FindFirstChild("BeltTread")
local beltTop = belt and (belt.Position.Y + belt.Size.Y / 2) or spawnPoint.Position.Y
local function groundPosition(dog)
    return dog:GetPivot():PointToWorldSpace(dog:GetAttribute("GroundLocal") or Vector3.zero)
end
local function facing(direction, fallback)
    local flat = Vector3.new(direction.X, 0, direction.Z)
    if flat.Magnitude < 0.001 then
        flat = Vector3.new(fallback.X, 0, fallback.Z)
        if flat.Magnitude < 0.001 then flat = Vector3.new(0, 0, -1) end
    end
    return CFrame.lookAt(Vector3.zero, flat.Unit, Vector3.yAxis)
end
local function pivotAt(dog, position, rotation)
    return CFrame.new(position) * rotation * CFrame.new(-(dog:GetAttribute("GroundLocal") or Vector3.zero))
end
local function linePosition(point)
    return Vector3.new(point.Position.X, beltTop + 0.05, point.Position.Z)
end
local function moveTo(dog, destination, speed, complete)
    if tweens[dog] then tweens[dog]:Cancel() end
    local start = groundPosition(dog)
    local direction = destination - start
    dog:SetAttribute('LocomotionSpeed',direction.Magnitude>.01 and speed or 0)
    local rotation = facing(direction, dog:GetPivot().LookVector)
    -- Turn immediately at purchase/rebuy; keep feet fixed while turning.
    movePivot(dog, pivotAt(dog, start, rotation))
    local proxy = Instance.new("Vector3Value")
    proxy.Value = start
    local tw = TweenService:Create(proxy, TweenInfo.new(math.max(direction.Magnitude / speed, 0.01), Enum.EasingStyle.Linear), {Value=destination})
    tweens[dog] = tw
    local changed = proxy.Changed:Connect(function(position)
        if dog.Parent then movePivot(dog, pivotAt(dog, position, rotation)) end
    end)
    tw.Completed:Connect(function(state)
        changed:Disconnect()
        proxy:Destroy()
        if tweens[dog] ~= tw then return end
        tweens[dog] = nil
        if state == Enum.PlaybackState.Completed and dog.Parent then
            dog:SetAttribute('LocomotionSpeed',0)
            complete()
        end
    end)
    tw:Play()
end
local function getYardSpawn(player)
	for _,y in ipairs(yards:GetChildren()) do if y:GetAttribute("OwnerUserId")==player.UserId then return y:FindFirstChild("YardSpawn",true) end end
	local id=player:GetAttribute("YardId")
	for _,y in ipairs(yards:GetChildren()) do if id and y:GetAttribute("YardId")==id then return y:FindFirstChild("YardSpawn",true) end end
end
local function adornee(o)
	if o:IsA("BasePart") then return o end
	return o.PrimaryPart or o:FindFirstChild("Head",true) or o:FindFirstChildWhichIsA("BasePart",true)
end
local function updateUI(dog)
	local bb=dog:FindFirstChild("DogBillboard"); local p=bb and bb:FindFirstChild("PriceLabel")
	if p then p.Text="$"..Format.Number(dog:GetAttribute("CurrentPrice") or 0) end
	local pr=dog:FindFirstChild("BuyPrompt",true); if not pr then return end
	local state=dog:GetAttribute("State"); local price=dog:GetAttribute("CurrentPrice") or 0
	pr.ActionText=(state=="Walking" and "REBUY") or "BUY"; pr.ObjectText=(dog:GetAttribute("DisplayName") or dog.Name).." - $"..Format.Number(price)
	if state=="Walking" then pr.ObjectText=dog:GetAttribute("DisplayName").." | "..(dog:GetAttribute("OwnerName") or "").." | $"..Format.Number(price) end
	pr.Enabled=state~="Delivered"
end
local function billboard(dog,data)
	local a=adornee(dog); if not a then return end
	local bb=Instance.new("BillboardGui"); bb.Name="DogBillboard"; bb.Adornee=dog:FindFirstChild("DogLabelAnchor",true) or a; bb.Parent=dog; bb.AlwaysOnTop=true; bb.LightInfluence=0; bb.MaxDistance=80; bb.Size=UDim2.fromOffset(180,72); bb.StudsOffsetWorldSpace=Vector3.zero
	local function label(n,text,y,color,size)
		local l=Instance.new("TextLabel"); l.Name=n; l.BackgroundTransparency=1; l.Size=UDim2.new(1,0,.32,0); l.Position=UDim2.new(0,0,y,0); l.Text=text; l.TextColor3=color; l.TextStrokeTransparency=.3; l.Font=Enum.Font.GothamBold; l.TextSize=size; l.Parent=bb
	end
	label("NameLabel",string.upper(data.DisplayName),0,Color3.new(1,1,1),20); label("RarityLabel",string.upper(data.Rarity),.34,RARITY[data.Rarity] or Color3.new(1,1,1),16); label("PriceLabel","$"..Format.Number(data.LinePrice or data.Price),.66,Color3.fromRGB(255,235,120),17)
end
local function inventory(dog,player,data)
    local uid=dog:GetAttribute("DogUid")
    for attempt=1,5 do
        if not dog.Parent or dog:GetAttribute("OwnerUserId")~=player.UserId then return end
        local ok=Economy.Deliver(player,uid)
        if ok then dog:Destroy();return end
        task.wait(attempt)
    end
    -- Ownership was already durably saved at purchase. Rejoin restores delivery.
    if dog.Parent then dog:Destroy() end
end
local function walkToYard(dog,player,data)
    local dest = getYardSpawn(player)
    if not dest or not dest:IsA("BasePart") then return end
    -- A rebuy changes the route but preserves the current walk cycle.
    if dog:GetAttribute("AnimationName") ~= "Walk" then
        dog:SetAttribute("AnimationStartedAt", workspace:GetServerTimeNow())
        dog:SetAttribute("AnimationLooped", true)
        dog:SetAttribute("AnimationName", "Walk")
    end
    moveTo(dog, dest.Position, WALK_SPEED, function()
        dog:SetAttribute("State", "Delivered")
        dog:SetAttribute("AnimationName", "")
        inventory(dog,player,data)
    end)
end
local function purchaseDog(dog,player,data)
    if dog:GetAttribute("PurchaseBusy") or dog:GetAttribute("State")=="Delivered" or not dog.Parent then return end
    if (dog:GetAttribute("ArrivalHoldUntil") or 0)>workspace:GetServerTimeNow() then return end
    if dog:GetAttribute("StudioPreview") then return end
    local destination=getYardSpawn(player)
    local character=player.Character;local root=character and character:FindFirstChild("HumanoidRootPart")
    if not destination or not root or (root.Position-dog:GetPivot().Position).Magnitude>18 then return end
    dog:SetAttribute("PurchaseBusy",true)
    local transport,ok,result=pcall(Economy.BuyLine,player,dog:GetAttribute("DogId"),dog:GetAttribute("DogUid"))
    if transport and ok and dog.Parent then
        for key,value in pairs(result.Dog) do
            if type(value)=="string" or type(value)=="number" or type(value)=="boolean" then dog:SetAttribute(key,value) end
        end
        dog:SetAttribute("OwnerName",player.Name);dog:SetAttribute("CurrentPrice",result.NextPrice)
        updateUI(dog);walkToYard(dog,player,data)
    elseif not transport or not ok then
        local message=tostring(transport and result or ok)
        warn("DOG LINE purchase deferred",message)
        local rep=game:GetService("ReplicatedStorage")
        local reward=rep:FindFirstChild("RewardPresentation")
        if reward then reward:FireClient(player,{PromptFeedback=message}) end
    end
    if dog.Parent then dog:SetAttribute("PurchaseBusy",false) end
end
local function buyPrompt(dog,data)
	local p=Instance.new("ProximityPrompt"); p.Name="BuyPrompt"; p.KeyboardKeyCode=Enum.KeyCode.E; p.HoldDuration=0; p.MaxActivationDistance=10; p.RequiresLineOfSight=false; p.ActionText="BUY"; p.ObjectText=data.DisplayName.." - $"..Format.Number(data.LinePrice or data.Price); p.Parent=adornee(dog) or dog
	p.Triggered:Connect(function(player) purchaseDog(dog,player,data) end)
end
-- Every rarity walks the shared line for every player, whatever their depth.
-- An overdue rarity (LineGuarantee seconds without one) is sent next.
local Guarantee=require(Replicated.DogEconomy.Config).LineGuarantee or {}
local lastRank={}
local function choose()
    local id=Economy.Engine:Choose()
    local rolled=id and definitions[id] and definitions[id].Rank or 0
    local now=os.clock()
    for rank=6,1,-1 do
        local every=Guarantee[rank]
        if every then
            lastRank[rank]=lastRank[rank] or now
            -- It only replaces a lower roll: a rolled Secret is never downgraded.
            if now-lastRank[rank]>=every and rolled<rank then id=Economy.Engine:ChooseRank(rank) or id;break end
        end
    end
    local data=id and definitions[id]
    if data then lastRank[data.Rank]=now end
    return id,data
end
local lastAnnouncement=-60
local function announce(data)
    local reward=Replicated:FindFirstChild("RewardPresentation")
    if not reward or os.clock()-lastAnnouncement<15 then return end
    lastAnnouncement=os.clock()
    reward:FireAllClients({Announcement=string.upper(data.Rarity).." DOG ON THE TONGUE · "..string.upper(data.DisplayName),Tier=data.Rarity})
end
local function playClip(dog,name,looped,at)
    dog:SetAttribute("AnimationName",name)
    dog:SetAttribute("AnimationLooped",looped==true)
    dog:SetAttribute("AnimationStartedAt",at)
end
-- Secret arrival: every client plays the dog's cinematic from SecretArrivalAt while
-- the dog waits at the mouth of the tongue, acting out its authored clips. It cannot
-- be bought until the hold ends and it starts to walk. Set before the dog is parented
-- so clients see the arrival on the very first replication.
local function beginArrival(dog,arrival,stage)
    local now=workspace:GetServerTimeNow()
    dog:SetAttribute("SecretArrivalAt",now)
    dog:SetAttribute("ArrivalHoldUntil",now+arrival.Hold)
    dog:SetAttribute("ArrivalOrigin",stage)
    if arrival.SpeedScale then dog:SetAttribute("LineSpeedScale",arrival.SpeedScale) end
    if arrival.FreezeLine then dog:SetAttribute("FreezeLine",true) end
    dog:SetAttribute("LocomotionSpeed",0)
    for _,step in ipairs(arrival.Clips or {})do
        local at,name,looped=step[1],step[2],step[3]
        if at<=0 then playClip(dog,name,looped,now)
        else task.delay(at,function()
            if dog.Parent and dog:GetAttribute("State")=="OnLine" then playClip(dog,name,looped,now+at)end
        end)end
    end
end
-- Once parented: no label or prompt until the arrival lands and the dog walks.
local function holdArrival(dog,arrival)
    local prompt=dog:FindFirstChild("BuyPrompt",true)
    local board=dog:FindFirstChild("DogBillboard")
    if prompt then prompt.Enabled=false end
    if board then board.Enabled=false end
    local at=dog:GetAttribute("SecretArrivalAt")
    task.delay(arrival.Hold,function()
        if not dog.Parent or dog:GetAttribute("State")~="OnLine" then return end
        playClip(dog,"Walk",true,at+arrival.Hold)
        if prompt then prompt.Enabled=true end
        if board then board.Enabled=true end
    end)
    -- The next spawn waits for the hold, so nothing walks into the arrival (a frozen
    -- tongue does not travel, so it needs no extra gap).
    if not arrival.FreezeLine then lastSpawn+=arrival.Hold*Stream.Speed end
end
local function lineTween(dog) entries[dog]=lastSpawn;dog:SetAttribute('StreamOffset',lastSpawn) end
local function spawnDog(forced)
    local id, data
    if forced then id=forced;data=definitions[id]else id,data=choose()end
    if not id then warn("DOG LINE: no usable dog templates"); return end
    if not data then return end
    local template = templates:FindFirstChild(definitions[id] and definitions[id].VisualAsset or id)
    if not template then return end
    local dog = template:Clone()
    if not anchorModel(dog) then
        warn("DOG LINE: invalid model", id)
        dog:Destroy()
        return
    end
	dog.Name=id; 
	dog:SetAttribute("DogUid",HttpService:GenerateGUID(false)); 
	dog:SetAttribute("DogId",id); 
	dog:SetAttribute("DisplayName",data.DisplayName); 
	dog:SetAttribute("Rarity",data.Rarity); 
	dog:SetAttribute("BasePrice",data.LinePrice or data.Price); 
	dog:SetAttribute("CurrentPrice",data.LinePrice or data.Price); 
	dog:SetAttribute("OwnerUserId",0); 
	dog:SetAttribute("OwnerName",""); 
	dog:SetAttribute("LocomotionSpeed",math.clamp(line:GetAttribute('EventLineSpeed')or Stream.Speed,2,Stream.Speed))
	dog:SetAttribute("State","OnLine");dog:SetAttribute("AnimationName","Walk");dog:SetAttribute("AnimationLooped",true);dog:SetAttribute("AnimationStartedAt",workspace:GetServerTimeNow()); 
	-- A Secret's arrival cinematic is its announcement on every client. It arrives on a
	-- stage Arrivals.Stage studs down the tongue, in the mouth opening where it is seen.
	local arrival=(data.Rank or 1)>=6 and Arrivals.Dogs[id]
	local mouth=linePosition(spawnPoint)
	local along=linePosition(endPoint)-mouth
	local stage=arrival and along.Magnitude>Arrivals.Stage and Arrivals.Stage or 0
	local at=mouth+(stage>0 and along.Unit*stage or Vector3.zero)
	if arrival then beginArrival(dog,arrival,at) end
	dog.Parent=active; 
	movePivot(dog,pivotAt(dog, at, facing(endPoint.Position-spawnPoint.Position, Vector3.new(0,0,-1)))); 
	billboard(dog,data); 
	buyPrompt(dog,data); 
	lineTween(dog)
	if stage>0 then entries[dog]-=stage;dog:SetAttribute('StreamOffset',entries[dog]) end
	if arrival then holdArrival(dog,arrival)
	elseif (data.Rank or 1)>=5 then announce(data) end
    return dog
end

local function spawnBlock(forced)
 local tier=forced
 if not tier then
  local total=0
  for _,w in ipairs(BlockConfig.SpawnWeights)do total+=w end
  local n=rng:NextNumber()*total
  for i,w in ipairs(BlockConfig.SpawnWeights)do n-=w;if n<0 then tier=BlockConfig.Rarities[i];break end end
 end
 local model=BlockVisuals.Build(tier or 'Common');weldToRoot(model);model.Parent=active
 movePivot(model,pivotAt(model,linePosition(spawnPoint),facing(endPoint.Position-spawnPoint.Position,Vector3.zAxis)))
 Blocks.Register(model,tier or 'Common');lineTween(model)
 billboard(model,{DisplayName=(tier or 'Common')..' BLOCK',Rarity=tier,Price=BlockConfig.ConveyorPrices[tier]})
 return model
end
spawnDog()
game:GetService('RunService').Heartbeat:Connect(function(dt)
 local now=workspace:GetServerTimeNow();local slowest=1
 -- This frame's freeze (decided first, so no dog idles for a frame as a hold ends).
 lineFrozen=false
 for entity in pairs(entries)do
  if entity.Parent and entity:GetAttribute('FreezeLine')and (entity:GetAttribute('ArrivalHoldUntil')or 0)>now then lineFrozen=true;break end
 end
 local speed=lineFrozen and 0 or math.clamp(line:GetAttribute('EventLineSpeed')or Stream.Speed,2,Stream.Speed)*lineScale
 travel+=dt*speed
 -- Nothing reads this every frame; publishing it 60x/s only cost bandwidth.
 travelPublishedAt+=dt;if travelPublishedAt>=.5 then travelPublishedAt=0;line:SetAttribute('StreamTravel',travel)end
 local start,finish=linePosition(spawnPoint),linePosition(endPoint);local delta=finish-start;local length=delta.Magnitude
 if length<1 then return end
 local rotation=facing(delta,Vector3.zAxis);local count=0
 for entity,offset in pairs(entries)do
  if not entity.Parent or entity:GetAttribute('State')~='OnLine'then entries[entity]=nil
  else
   local held=(entity:GetAttribute('ArrivalHoldUntil')or 0)>now
   local paused=held or (entity:GetAttribute('DogId')~=nil and entity:GetAttribute('PurchaseBusy')==true)
   slowest=math.min(slowest,entity:GetAttribute('LineSpeedScale')or 1)
   -- Dogs stopped by a frozen tongue stand idle instead of freezing mid-stride.
   if entity:GetAttribute('DogId')and not held and not entity:GetAttribute('FreezeLine')then
    local idled=entity:GetAttribute('LineIdled')
    if lineFrozen and not idled and entity:GetAttribute('AnimationName')=='Walk'then
     entity:SetAttribute('LineIdled',true);playClip(entity,'Idle',true,now)
    elseif not lineFrozen and idled then
     entity:SetAttribute('LineIdled',nil);playClip(entity,'Walk',true,now)
    end
   end
   if entity:GetAttribute('DogId')then
    local gaitSpeed=paused and 0 or speed
    if entity:GetAttribute('LocomotionSpeed')~=gaitSpeed then entity:SetAttribute('LocomotionSpeed',gaitSpeed)end
   end
   if paused then
    offset+=dt*speed;entries[entity]=offset
   end
   if entity:GetAttribute('OfferUserId') and (entity:GetAttribute('OfferUntil')or 0)<os.time()then
    entity:SetAttribute('OfferUserId',nil);entity:SetAttribute('OfferUntil',nil);entity:SetAttribute('OfferOrigin',nil)
   end
   count+=1;local distance=travel-offset
   entity:SetAttribute('LineExitAt',os.time()+math.max(0,math.ceil((length-distance)/math.max(speed,.5))))
   movePivot(entity,pivotAt(entity,start+delta.Unit*math.min(length,distance),rotation))
   if distance>=length and not entity:GetAttribute('PurchaseBusy')then entries[entity]=nil;dissolve(entity)end
  end
 end
 lineScale=math.clamp(slowest,.2,1)
 if travel-lastSpawn>=spacing and count<Stream.MaxActive then
  lastSpawn+=spacing
  if rng:NextNumber()<Stream.BlockChance then spawnBlock()else spawnDog()end
 end
end)
-- Server-only development harness, never a public admin remote.
if game:GetService('RunService'):IsStudio() and game.GameId==0 then
 local dev=Instance.new('BindableFunction');dev.Name='SpawnLuckyBlock';dev.Parent=script
 dev.OnInvoke=function(tier)assert(BlockConfig.Rank(tier),'Unknown rarity');return spawnBlock(tier)end
 local dogTest=Instance.new('BindableFunction');dogTest.Name='SpawnDog';dogTest.Parent=script
 dogTest.OnInvoke=function(id)assert(definitions[id],'Unknown dog');return spawnDog(id)end
end
-- Studio-only preview of every Secret arrival (F7 panel); live servers never create it.
if game:GetService('RunService'):IsStudio() then
 local preview=Instance.new('RemoteFunction');preview.Name='StudioSecretArrival'
 local function arrive(player,id,here)
  if type(id)~='string' or not Arrivals.Dogs[id] or not definitions[id] then return false,'Unknown secret' end
  -- Off-tongue Secrets (or "here") arrive in front of the player, as from a Lucky Block.
  if here==true or not definitions[id].CanSpawnOnLine then
   local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
   if not root then return false,'No character' end
   local look=root.CFrame.LookVector;local ahead=root.Position+Vector3.new(look.X,0,look.Z).Unit*12
   local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.FilterDescendantsInstances={player.Character}
   local hit=workspace:Raycast(ahead+Vector3.new(0,6,0),Vector3.new(0,-40,0),params)
   local ground=hit and hit.Position or ahead-Vector3.new(0,3,0)
   local ok,model=pcall(require(script.Parent.SecretReveal).Show,id,ground,-look,{Venue='Yard',By=player.DisplayName})
   if not ok then return false,'Reveal failed: '..tostring(model)end
   if not model then return false,'Reveal failed: no usable template for '..id end
   return true,'Revealed '..definitions[id].DisplayName
  end
  local dog=spawnDog(id)
  if not dog then return false,'Template unavailable' end
  -- Arrive on the stage now, not mid-slot.
  entries[dog]=travel-(dog:GetAttribute('ArrivalOrigin')and Arrivals.Stage or 0);dog:SetAttribute('StreamOffset',entries[dog])
  -- A published place's Studio session uses the real DataStore: look, don't buy.
  if game.GameId~=0 then dog:SetAttribute('StudioPreview',true) end
  return true,'Spawned '..definitions[id].DisplayName..(game.GameId~=0 and ' (preview, not for sale)' or '')
 end
 -- An error comes back to the panel as text instead of a silent failure.
 preview.OnServerInvoke=function(player,id,here)
  local ok,success,message=xpcall(arrive,debug.traceback,player,id,here)
  if not ok then warn('[SecretArrivals] Studio preview of',id,'failed:',success);return false,'Server error: '..(string.match(tostring(success),'^[^\n]*')or'') end
  print('[SecretArrivals] Studio preview:',id,success,message)
  return success,message
 end
 preview.Parent=Replicated
end
print('DOGROTS_SHARED_STREAM_READY',spacing)


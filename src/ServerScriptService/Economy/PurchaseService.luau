local Marketplace=game:GetService('MarketplaceService');local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage');local Run=game:GetService('RunService');local Http=game:GetService('HttpService')
local R=require(script.Parent.Rules)
local Support=require(script.Parent.SupportReceipts)
local TicketPurchases=require(script.Parent.RoulettePurchases)
local Catalog=require(RS.CommerceConfig);local Kinds=require(RS.ProductKinds)
local Service={};local function grant(p,product)
 local reward=product.Rewards
 -- This catalog grants guaranteed cosmetics; ticket receipts use their own grant.
 R.Check(reward and type(reward.Cosmetic)=='string','Invalid product reward');p.Cosmetics[reward.Cosmetic]=true
end
local function idText(id)return string.format('%.0f',id)end
-- The kind a row is sold as: ShopDefinitions rows (and any row with Kind) state it, every
-- other Id was resolved by ProductKinds (nil while still resolving).
local function kindOf(entry)return Kinds.Override(entry.Row)or Kinds.Kind(entry.Row.Id)end
-- The one row an Id belongs to, among rows that can be sold as `want` ('Product' rows are
-- Developer Products or not yet resolved; 'Pass' rows are Game Passes or not yet resolved).
-- nil unless exactly one row matches: an Id on two rows never delivers the wrong thing.
local function find(id,want)
 local found,matches=nil,0
 for _,entry in ipairs(Catalog.AllRows())do
  local row=entry.Row
  if type(row.Id)=='number'and row.Id>0 and row.Id==id then
   local kind=kindOf(entry)
   if want==nil or kind==nil or kind==want then found=entry;matches+=1 end
  end
 end
 if matches==1 then return found end
end
function Service.Start(runtime)
 if Service.Started then return end;Service.Started=true
 for _,problem in ipairs(Catalog.Check())do warn('[DOGROTS products]',problem)end
 Kinds.Start()
 local function fulfill(user,product,key)
  return runtime.Tx:Run({'p:'..user,key},function(v)
   if v[key]then R.Check(v[key].User==user and v[key].Product==product.Id,'Receipt mismatch');return 'Already granted'end
   local p=v['p:'..user];runtime.Engine:Authorize(p,user);grant(p,product);R.Validate(p);v[key]={User=user,Product=product.Id,At=os.time()};return 'Purchase granted'
  end)
 end
 -- Every grant goes through the same per-catalog handler, idempotent on the receipt's
 -- PurchaseId. Returns true when the reward is (or already was) delivered.
 local function deliver(player,entry,receipt)
  local product=entry.Row
  local transport,ok=pcall(function()
   if entry.Catalog=='Commerce'then return require(script.Parent.CommerceProducts).Receipt(runtime,player,product,receipt)
   elseif entry.Catalog=='Tickets'then return TicketPurchases.Receipt(runtime,player,product,receipt)
   elseif entry.Catalog=='Block'then return require(script.Parent.RewardService).Receipt(runtime,player,product,receipt)
   else
    -- Cosmetic Game Passes keep their original 'pass:<user>:<pass>' durable key.
    local passKey=receipt.PurchaseId:sub(1,5)=='pass:'and receipt.PurchaseId or'purchase:'..receipt.PurchaseId
    local granted,message=fulfill(receipt.PlayerId,product,passKey)
    if granted and type(message)=='string'and message=='Purchase granted'then
     local reward=RS:FindFirstChild('RewardPresentation')
     if reward then reward:FireClient(player,{Message='THANK YOU! '..tostring(product.Name or product.Key):upper()..' UNLOCKED'})end
    end
    return granted,message
   end
  end)
  if not transport then warn('[DOGROTS purchases] grant error',receipt.PurchaseId,ok)end
  return transport and ok==true
 end
 local function processReceipt(receipt)
  local pending=Enum.ProductPurchaseDecision.NotProcessedYet
  if type(receipt)~='table'or not R.Int(receipt.PlayerId,1,9007199254740990)
   or not R.Int(receipt.ProductId,1,9007199254740990)
   or type(receipt.PurchaseId)~='string'or #receipt.PurchaseId==0 or #receipt.PurchaseId>100
   or receipt.CurrencyType~=Enum.CurrencyType.Robux or not R.Int(receipt.CurrencySpent,0,9000000000000000)then return pending end
  local player=Players:GetPlayerByUserId(receipt.PlayerId)
  if not player or not runtime.Ready(player)then return pending end
  -- Only Developer Products have receipts; a row resolved as a Game Pass is never matched.
  local entry=find(receipt.ProductId,'Product')
  if not entry then return pending end
  if not deliver(player,entry,receipt)or not Support.Record(runtime,receipt)then return pending end
  runtime.Refresh(player);return Enum.ProductPurchaseDecision.PurchaseGranted
 end
 -- One receipt callback owns every developer product in this experience.
 Marketplace.ProcessReceipt=processReceipt
 -- Game Passes: granted through the same handlers with a synthetic receipt whose PurchaseId
 -- 'pass:<user>:<pass>' makes every grant idempotent; the profile then remembers the pass
 -- (p.CommercePasses) so a rejoin does not ask Roblox or the DataStore again.
 local granting={}
 local function remember(player,id)
  local user=player.UserId
  pcall(function()return runtime.Tx:Run({'p:'..user},function(v)
   local p=v['p:'..user];runtime.Engine:Authorize(p,user)
   p.CommercePasses=type(p.CommercePasses)=='table'and p.CommercePasses or{};p.CommercePasses[idText(id)]=true
   return true
  end)end)
  if player.Parent then player:SetAttribute('PassOwned_'..idText(id),true)end
 end
 local function grantPass(player,entry)
  local user,id=player.UserId,entry.Row.Id;local busy=user..':'..idText(id)
  if granting[busy]or not runtime.Ready(player)then return false end
  granting[busy]=true
  local receipt={PlayerId=user,ProductId=id,PurchaseId='pass:'..user..':'..idText(id),CurrencyType=Enum.CurrencyType.Robux,
   CurrencySpent=math.max(0,math.floor(Kinds.Price(id)or entry.Row.Robux or 0)),PlaceIdWherePurchased=game.PlaceId}
  local ok=deliver(player,entry,receipt)
  if ok then
   remember(player,id)
   -- Passes have no receipt to acknowledge: the supporter tally is best effort.
   pcall(Support.Record,runtime,receipt)
   runtime.Refresh(player)
  end
  granting[busy]=nil
  return ok
 end
 local function passes(player)
  if not runtime.Ready(player)then return end
  local p=runtime.Views[player.UserId];local known=p and type(p.CommercePasses)=='table'and p.CommercePasses or{}
  for _,entry in ipairs(Catalog.AllRows())do
   local id=entry.Row.Id
   if type(id)=='number'and id>0 and kindOf(entry)=='Pass'then
    if known[idText(id)]then player:SetAttribute('PassOwned_'..idText(id),true)
    else
     local ok,owns=pcall(function()return Marketplace:UserOwnsGamePassAsync(player.UserId,id)end)
     if ok and owns and player.Parent then grantPass(player,entry)end
    end
   end
  end
 end
 Marketplace.PromptGamePassPurchaseFinished:Connect(function(player,passId,purchased)
  if not purchased or type(passId)~='number'then return end
  -- The purchase itself proves the Id is a Game Pass, even before kinds are resolved.
  local entry=find(passId,'Pass')
  if entry then task.spawn(grantPass,player,entry)end
 end)
 local function added(player)task.spawn(function()for _=1,60 do if not player.Parent then return end;if runtime.Ready(player)then passes(player);return end;task.wait(1)end end)end
 Players.PlayerAdded:Connect(added);for _,p in ipairs(Players:GetPlayers())do added(p)end
 -- Kinds resolve a few seconds after start (and again later): look again for owned passes.
 if Kinds.Changed then Kinds.Changed.Event:Connect(function()for _,p in ipairs(Players:GetPlayers())do task.spawn(passes,p)end end)end
 Players.PlayerRemoving:Connect(function(player)
  local prefix=player.UserId..':'
  for key in pairs(granting)do if key:sub(1,#prefix)==prefix then granting[key]=nil end end
 end)
 -- Unpublished Studio place only (in-memory data, nothing persists): the shop's buy buttons
 -- run a simulated purchase through this exact receipt path, so every product can be tested.
 -- A published place (GameId~=0) never gets this remote.
 if Run:IsStudio()and game.GameId==0 then
  local remote=RS:FindFirstChild('DOGROTS_StudioPurchase')or Instance.new('RemoteFunction')
  remote.Name='DOGROTS_StudioPurchase';remote.Parent=RS
  remote.OnServerInvoke=function(player,id)
   if not runtime.Ready(player)then return false,'Your profile is still loading'end
   if not R.Int(id,1,9007199254740990)then return false,'Unknown product'end
   local entry=find(id,nil)
   if not entry then return false,'Unknown product'end
   if kindOf(entry)=='Pass'then
    local ok=grantPass(player,entry)
    return ok,'Studio test: '..tostring(entry.Row.Name)..' (Game Pass) '..(ok and'granted'or'not granted (see Output)')
   end
   local decision=processReceipt({PlayerId=player.UserId,ProductId=id,PurchaseId='studio-'..Http:GenerateGUID(false),CurrencyType=Enum.CurrencyType.Robux,
    CurrencySpent=math.max(0,math.floor(Kinds.Price(id)or entry.Row.Robux or 0)),PlaceIdWherePurchased=game.PlaceId})
   local ok=decision==Enum.ProductPurchaseDecision.PurchaseGranted
   return ok,ok and'Studio test: '..tostring(entry.Row.Name)..' granted'or'Studio test purchase was not granted (see Output)'
  end
 end
end
return Service

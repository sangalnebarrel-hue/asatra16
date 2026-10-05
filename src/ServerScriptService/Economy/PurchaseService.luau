local Marketplace=game:GetService('MarketplaceService');local Players=game:GetService('Players')
local Definitions=require(script.Parent.ShopDefinitions);local R=require(script.Parent.Rules)
local Support=require(script.Parent.SupportReceipts)
local TicketPurchases=require(script.Parent.RoulettePurchases)
local Service={};local function grant(p,product)
 local reward=product.Rewards
 -- This catalog grants guaranteed cosmetics; ticket receipts use their own grant.
 R.Check(reward and type(reward.Cosmetic)=='string','Invalid product reward');p.Cosmetics[reward.Cosmetic]=true
end
function Service.Start(runtime)
 if Service.Started then return end;Service.Started=true
 local function find(id,kind)for _,p in ipairs(Definitions)do if p.Id>0 and p.Id==id and p.Kind==kind then return p end end end
 local function fulfill(user,product,key)
  return runtime.Tx:Run({'p:'..user,key},function(v)
   if v[key]then R.Check(v[key].User==user and v[key].Product==product.Id,'Receipt mismatch');return 'Already granted'end
   local p=v['p:'..user];runtime.Engine:Authorize(p,user);grant(p,product);R.Validate(p);v[key]={User=user,Product=product.Id,At=os.time()};return 'Purchase granted'
  end)
 end
 -- One receipt callback owns every developer product in this experience.
 Marketplace.ProcessReceipt=function(receipt)
  local pending=Enum.ProductPurchaseDecision.NotProcessedYet
  if type(receipt)~='table'or not R.Int(receipt.PlayerId,1,9007199254740990)
   or not R.Int(receipt.ProductId,1,9007199254740990)
   or type(receipt.PurchaseId)~='string'or #receipt.PurchaseId==0 or #receipt.PurchaseId>100
   or receipt.CurrencyType~=Enum.CurrencyType.Robux or not R.Int(receipt.CurrencySpent,0,9000000000000000)then return pending end
  local player=Players:GetPlayerByUserId(receipt.PlayerId)
  if not player or not runtime.Ready(player)then return pending end
  local product,kind,matches=nil,nil,0
  local function consider(row,rowKind)
   if row.Id>0 and row.Id==receipt.ProductId then product,kind=row,rowKind;matches+=1 end
  end
  for _,row in ipairs(Definitions)do if row.Kind=='Product'then consider(row,'Cosmetic')end end
  for _,row in ipairs(require(game.ReplicatedStorage.CommerceConfig).Products)do consider(row,'Commerce')end
  for _,row in ipairs(require(game.ReplicatedStorage.LuckyBlockConfig).RobuxProducts)do consider(row,'Block')end
  for _,row in ipairs(require(game.ReplicatedStorage.RewardMachineConfig).TicketProducts or{})do consider(row,'Tickets')end
  -- An ID accidentally assigned to two catalogs must never deliver the wrong thing.
  if matches~=1 then return pending end
  local transport,ok=pcall(function()
   if kind=='Commerce'then return require(script.Parent.CommerceProducts).Receipt(runtime,player,product,receipt)
   elseif kind=='Tickets'then return TicketPurchases.Receipt(runtime,player,product,receipt)
   elseif kind=='Block'then return require(script.Parent.RewardService).Receipt(runtime,player,product,receipt)
   else return fulfill(receipt.PlayerId,product,'purchase:'..receipt.PurchaseId)end
  end)
  if not transport or not ok or not Support.Record(runtime,receipt) then return Enum.ProductPurchaseDecision.NotProcessedYet end
  runtime.Refresh(player);return Enum.ProductPurchaseDecision.PurchaseGranted
 end
 local function passes(player)
  for _,p in ipairs(Definitions)do if p.Kind=='Pass'and p.Id>0 then
   local ok,owns=pcall(function()return Marketplace:UserOwnsGamePassAsync(player.UserId,p.Id)end)
   if ok and owns then local transport,success=pcall(function()return fulfill(player.UserId,p,'pass:'..player.UserId..':'..p.Id)end);if transport and success then runtime.Refresh(player)end end
  end end
 end
 Marketplace.PromptGamePassPurchaseFinished:Connect(function(player,_,purchased)if purchased then passes(player)end end)
 local function added(player)task.spawn(function()for _=1,60 do if not player.Parent then return end;if runtime.Ready(player)then passes(player);return end;task.wait(1)end end)end
 Players.PlayerAdded:Connect(added);for _,p in ipairs(Players:GetPlayers())do added(p)end
end
return Service

local RS=game:GetService('ReplicatedStorage')
local Marketplace=game:GetService('MarketplaceService')
local Player=game:GetService('Players').LocalPlayer
local Price=require(RS.PriceFormat);local Kinds=require(RS.ProductKinds);local Catalog=require(RS.CommerceConfig)
local P={Cache={},Loading={},Retry={},Busy=false}
-- Present only in an unpublished Studio place: purchases there are simulated by the server.
local function studio()return RS:FindFirstChild('DOGROTS_StudioPurchase')end
-- The live Robux price: the server publishes it with the product's kind; a client lookup
-- (with the right InfoType) is only the fallback.
local function livePrice(c,parent,id)
 local published=Kinds.Price(id);if published then return published end
 local entry=P.Cache[id]
 if entry and os.clock()-entry.At>60 then P.Cache[id]=nil;entry=nil end
 if not entry and Kinds.Kind(id)and not P.Loading[id]and os.clock()>=(P.Retry[id]or 0)then
  P.Loading[id]=true
  local infoType=Kinds.InfoType(id)
  task.spawn(function()
   local ok,info=pcall(function()return Marketplace:GetProductInfoAsync(id,infoType)end)
   P.Loading[id]=nil
   if ok and type(info)=='table'and type(info.PriceInRobux)=='number'and info.IsForSale~=false then P.Cache[id]={Price=info.PriceInRobux,At=os.clock()}
   else P.Retry[id]=os.clock()+15 end
   if parent.Parent then c.Draw()end
  end)
 end
 return entry and entry.Price
end
-- label, action (nil = the button is disabled). product.Route picks the server validation;
-- DOG-O-MATIC token rows (RewardMachineConfig.TicketProducts) default to 'RewardMachineProduct'.
function P.Quote(c,parent,product)
 if type(product.Id)~='number'or product.Id<=0 then return 'ROBUX · COMING SOON',nil end
 if product.Enabled==false then return 'ROBUX · NOT ON SALE',nil end
 local id=product.Id;local test=studio()~=nil;local status=Kinds.Status(id)
 if status=='Pass'and Player:GetAttribute('PassOwned_'..string.format('%.0f',id))then return 'OWNED',nil end
 if not test then
  if status=='Pending'then return 'ROBUX · LOADING PRICE',nil end
  if status=='Unavailable'then return 'ROBUX · UNAVAILABLE',nil end
  if not Kinds.ForSale(id)then return 'ROBUX · NOT ON SALE',nil end
 end
 local price=livePrice(c,parent,id)
 if not price and not test then return P.Retry[id]and'ROBUX · PRICE UNAVAILABLE'or'ROBUX · LOADING PRICE',nil end
 local function purchase()
  if P.Busy then return end;P.Busy=true
  task.spawn(function()
   local route=product.Route or(table.find(Catalog.TicketKeys,product.Key)and'RewardMachineProduct')or'CommerceProduct'
   local transport,ok,result=pcall(function()return RS.RewardRequest:InvokeServer(route,{Key=product.Key})end)
   if transport and ok and type(result)=='table'and result.ProductId==id then
    local remote=studio()
    if remote then
     local sent,granted,message=pcall(function()return remote:InvokeServer(id)end)
     c.State.CommerceMessage=sent and tostring(message or(granted and'Granted'or'Not granted'))or'Studio test purchase failed'
    else
     local shown=Kinds.Prompt(Player,id)
     if not shown then c.State.CommerceMessage='Purchase unavailable. Please try again.'end
    end
   else c.State.CommerceMessage=transport and tostring(result)or'Connection interrupted. Please try again.'end
   P.Busy=false;if parent.Parent then c.Draw()end
  end)
 end
 if test then return price and'TEST BUY · '..Price.Robux(price)or'STUDIO TEST BUY',purchase end
 return 'BUY · '..Price.Robux(price),purchase
end
-- These events refresh presentation only. They never grant any reward.
Marketplace.PromptProductPurchaseFinished:Connect(function()P.Busy=false end)
Marketplace.PromptGamePassPurchaseFinished:Connect(function()P.Busy=false end)
return P

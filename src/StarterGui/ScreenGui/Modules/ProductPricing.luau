local RS=game:GetService('ReplicatedStorage')
local Marketplace=game:GetService('MarketplaceService')
local Player=game:GetService('Players').LocalPlayer
local Price=require(RS.PriceFormat)
local P={Cache={},Loading={},Retry={},Busy=false}
function P.Quote(c,parent,product)
 if type(product.Id)~='number'or product.Id<=0 then return 'ROBUX · COMING SOON',nil end
 if product.Enabled==false then return 'ROBUX · NOT ON SALE',nil end
 local id=product.Id;local entry=P.Cache[id]
 if entry and os.clock()-entry.At>60 then P.Cache[id]=nil;entry=nil end
 if not entry and not P.Loading[id]and os.clock()>=(P.Retry[id]or 0)then
  P.Loading[id]=true
  task.spawn(function()
   local ok,info=pcall(function()return Marketplace:GetProductInfoAsync(id,Enum.InfoType.Product)end)
   P.Loading[id]=nil
   if ok and type(info)=='table'and type(info.PriceInRobux)=='number'then P.Cache[id]={Price=info.PriceInRobux,At=os.clock()}
   else P.Retry[id]=os.clock()+15 end
   if parent.Parent then c.Draw()end
  end)
 end
 local function purchase()
  if P.Busy then return end;P.Busy=true
  task.spawn(function()
   local transport,ok,result=pcall(function()return RS.RewardRequest:InvokeServer(product.Route or'CommerceProduct',{Key=product.Key})end)
   if transport and ok and type(result)=='table'and result.ProductId==id then
    local shown=pcall(function()Marketplace:PromptProductPurchase(Player,id)end)
    c.State.CommerceMessage=not shown and'Purchase unavailable. Please try again.'or nil
   else c.State.CommerceMessage=transport and tostring(result)or'Connection interrupted. Please try again.'end
   P.Busy=false;if parent.Parent then c.Draw()end
  end)
 end
 -- A failed price lookup never blocks a purchase: the Roblox dialog always shows the exact price.
 if not entry then
  if P.Loading[id]and not P.Retry[id]then return 'ROBUX · LOADING PRICE',nil end
  return type(product.Robux)=='number'and'BUY · '..Price.Robux(product.Robux)or'BUY WITH ROBUX',purchase
 end
 return 'BUY · '..Price.Robux(entry.Price),purchase
end
-- This event refreshes presentation only. It never grants any reward.
Marketplace.PromptProductPurchaseFinished:Connect(function()P.Busy=false end)
return P

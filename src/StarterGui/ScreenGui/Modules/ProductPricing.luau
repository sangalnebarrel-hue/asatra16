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
   if ok and type(info.PriceInRobux)=='number'and info.IsForSale~=false then P.Cache[id]={Price=info.PriceInRobux,At=os.clock()}
   else P.Retry[id]=os.clock()+15 end
   if parent.Parent then c.Draw()end
  end)
 end
 if not entry then return P.Retry[id]and'ROBUX · PRICE UNAVAILABLE'or'ROBUX · LOADING PRICE',nil end
 local function purchase()
  if P.Busy then return end;P.Busy=true
  task.spawn(function()
   local transport,ok,result=pcall(function()return RS.RewardRequest:InvokeServer(product.Route or'CommerceProduct',{Key=product.Key})end)
   if transport and ok and result.ProductId==id then
    local shown=pcall(function()Marketplace:PromptProductPurchase(Player,id)end)
    if not shown then c.State.CommerceMessage='Purchase unavailable. Please try again.'end
   else c.State.CommerceMessage=transport and tostring(result)or'Connection interrupted. Please try again.'end
   P.Busy=false;if parent.Parent then c.Draw()end
  end)
 end
 return 'BUY · '..Price.Robux(entry.Price),purchase
end
-- This event refreshes presentation only. It never grants any reward.
Marketplace.PromptProductPurchaseFinished:Connect(function()P.Busy=false end)
return P

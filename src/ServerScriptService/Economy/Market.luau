local PaidPolicy=require(script.Parent.PaidItemPolicy)
local R=require(script.Parent.Rules)
local C=require(script.Parent.Config)
local D=require(script.Parent.DogDefinitions)
local I=require(script.Parent.ItemRules)
local Stats=require(script.Parent.RecordStats)
local function itemKey(k)return type(k)=='string' and k:sub(1,5)=='item:'end
local function definition(k)return itemKey(k) and I.Definitions[k:sub(6)] or D[k]end
local function assetKey(x)return x.ItemId and 'item:'..x.ItemId or x.DogId end
local function assetUid(x)return x.ItemUid or x.DogUid end
local function reservations(p,key)I.Normalize(p);return itemKey(key) and p.ItemReservations or p.Reservations end
local function free(p,key)I.Normalize(p);return itemKey(key) and I.Free(p) or (not itemKey(key) and R.Free(p))end
local M={};M.__index=M
local function pk(uid) return 'p:'..uid end
local function bk(id) return 'book:'..id end
function M.new(tx,clock,guid,authorize)
 return setmetatable({Tx=tx,Now=clock,Guid=guid,Authorize=authorize,QueryCache={}},M)
end
function M:Cached(key,seconds)
 local entry=self.QueryCache[key]
 if entry and entry.Expires>self.Now() then return entry.Value end
 local value=self.Tx:Read(key)
 self.QueryCache[key]={Expires=self.Now()+seconds,Value=value}
 return value
end
function M:Listing(dogId,id)
 R.Check(definition(dogId),"Unknown dog")
 local book=self.Tx:Read(bk(dogId)) or {Items={}}
 local l=book.Items[id];R.Check(l,"Listing no longer available");return l
end
-- Cross-server settlement. Profiles are RAM-owned by the server a player is on, so
-- a sale/bid/settlement never writes another server's profile. Counterparts that
-- are not loaded here receive an inbox entry (inbox:<userId>) inside the same
-- durable transaction; their own server applies it (M:DrainInbox).
local function ik(uid) return 'inbox:'..uid end
function M:IsLocal(uid)
 return uid~=nil and self.Tx.Loaded[pk(uid)]==true
end
local function deliver(v,uid,entry,deliveries)
 local box=v[ik(uid)] or {Entries={},Next=0};v[ik(uid)]=box;box.Entries=box.Entries or {}
 local count=0;for _ in pairs(box.Entries)do count+=1 end
 R.Check(count<200,"Recipient inbox is full; settlement will retry")
 box.Next=(box.Next or 0)+1;entry.At=entry.At or os.time()
 box.Entries[tostring(box.Next)]=entry
 if deliveries then deliveries[uid]=true end
end
function M:Notify(deliveries)
 if not self.OnInbox or not next(deliveries)then return end
 local ids={};for uid in pairs(deliveries)do table.insert(ids,uid)end
 pcall(self.OnInbox,ids)
end
function M:Create(user,a,request)
 R.Check(a.Mode=="BuyNow" or a.Mode=="Auction","Choose Buy Now or Auction")
 R.Check(R.Int(a.Price,10,C.MaxCash),"Invalid listing price")
 local p=self.Tx:Read(pk(user));I.Normalize(p);local isItem=a.Kind=='Item';local d=isItem and I.Get(p,a.Uid,true) or R.Dog(p,a.Uid,true);local key=assetKey(d);local now=self.Now()
 local paidAllowed=not d.PaidRandom or PaidPolicy.Allowed(user)
 R.Check(paidAllowed,'Paid-item trading is unavailable for this account')
 local duration=a.Duration or 3600
 R.Check(table.find(C.AuctionDurations,duration),"Invalid duration")
 local listingId=self.Guid()
 return self.Tx:Run({pk(user),bk(key),'auctionQueue'},function(v)
  p=v[pk(user)];I.Normalize(p);self.Authorize(p,user);d=isItem and I.Get(p,a.Uid,true) or R.Dog(p,a.Uid,true)
  R.Check(not d.PaidRandom or paidAllowed,'Paid-item trading is unavailable for this account')
  R.Check(R.Count(p.Listings)<10,"Maximum 10 open listings")
  local book=v[bk(key)] or {Items={}};v[bk(key)]=book
  R.Check(R.Count(book.Items)<C.MaxListingsPerDog,"Market board full; try later")
  local queue=v.auctionQueue or {};v.auctionQueue=queue
  R.Check(R.Count(queue)<C.MaxAuctions,"Auction queue full")
  R.Pay(p,math.max(1,math.ceil(a.Price*.01)))
  book.Items[listingId]={Id=listingId,Dog=R.Copy(d),AssetKey=key,Kind=isItem and 'Item' or 'Dog',Seller=user,Price=a.Price,Mode=a.Mode,
   Created=now,Ends=now+(a.Mode=="Auction" and duration or 604800),MaxEnd=now+duration+300}
  (if isItem then p.Items else p.Dogs)[assetUid(d)]=nil;p.Listings[listingId]=key
  queue[listingId]={DogId=key,Ends=book.Items[listingId].Ends,Seller=user}
  return {Message="Listing created (1% fee)",Id=listingId}
 end,request)
end
function M:Buy(user,a,request)
 local l=self:Listing(a.DogId,a.Id);R.Check(l.Mode=="BuyNow","This listing requires a bid")
 R.Check(not l.Dog.PaidRandom or PaidPolicy.Allowed(user),'Paid-item trading is unavailable for this account')
 local seller=l.Seller;local now=self.Now();local history='sales:'..a.DogId..':'..math.floor(now/86400)
 local sellerLocal=self:IsLocal(seller);local deliveries={}
 local ok,result,receipt=self.Tx:Run({pk(user),sellerLocal and pk(seller) or ik(seller),bk(a.DogId),history,'auctionQueue'},function(v)
  table.clear(deliveries)
  local book=v[bk(a.DogId)];l=book and book.Items[a.Id]
  R.Check(l and l.Seller==seller and l.Mode=="BuyNow" and l.Ends>now,"Listing expired or sold")
  R.Check(user~=seller,"Cannot buy your own listing")
  local buyer=v[pk(user)];self.Authorize(buyer,user)
  local owner=sellerLocal and v[pk(seller)] or nil
  if sellerLocal then R.Check(owner and owner.Listings[a.Id]==a.DogId,"Invalid escrow owner")end
  R.Check(free(buyer,a.DogId),"Dog storage full");R.Pay(buyer,l.Price)
  self:Finish(v,l,buyer,owner,history,now,deliveries)
  return {Message="Dog purchased",DogUid=assetUid(l.Dog)}
 end,request)
 if ok then self:Notify(deliveries)end
 return ok,result,receipt
end
-- buyer/owner are profiles loaded on this server, or nil for an inbox delivery.
function M:Finish(v,l,buyer,owner,history,now,deliveries)
 local net=math.floor(l.Price*.95);local d=l.Dog;local key=l.AssetKey or assetKey(d)
 local sellerId=l.Seller;local buyerId=buyer and buyer.UserId or l.Bidder
 if owner then
  R.Credit(owner,net);Stats.Sale(owner,net);I.Normalize(owner);owner.Listings[l.Id]=nil
 else
  deliver(v,sellerId,{Kind='Sold',ListingId=l.Id,AssetKey=key,Net=net,Price=l.Price},deliveries)
 end
 if buyer then
  I.Normalize(buyer)
  if d.ItemUid then I.Transfer(buyer,d)else
   R.Check(not buyer.Dogs[d.DogUid],"Duplicate DogUid");d.PricePaid=l.Price;R.Transfer(d,buyer,now,l.Mode)
  end
  reservations(buyer,key)[l.Id]=nil
 else
  R.Check(buyerId,"Buyer missing")
  deliver(v,buyerId,{Kind='Won',ListingId=l.Id,AssetKey=key,Asset=R.Copy(d),Price=l.Price,Mode=l.Mode},deliveries)
 end
 v[bk(key)].Items[l.Id]=nil;v.auctionQueue[l.Id]=nil
 local h=v[history] or {};v[history]=h
 R.Check(#h<20000,"Sales journal capacity reached; settlement will retry")
 table.insert(h,{At=now,Price=l.Price,DogUid=assetUid(d),Variant=d.Variant or d.Mutation,Serial=d.SerialNumber or 0,Edition=d.Edition or "",WeightKg=d.WeightKg,WeightTier=d.WeightTier,CombinedOdds=d.CombinedOdds,OriginalFinderUserId=d.OriginalFinderUserId,
  Mastery=d.Mastery,Ascension=d.AscensionLevel,Seller=sellerId,Buyer=buyerId,Tax=l.Price-net})
 if buyer then R.Validate(buyer)end;if owner then R.Validate(owner)end
end
function M:Bid(user,a,request)
 R.Check(R.Int(a.Amount,10,C.MaxCash),"Invalid bid")
 local l=self:Listing(a.DogId,a.Id);local previous=l.Bidder;local keys={pk(user),bk(a.DogId),'auctionQueue'}
 local previousLocal=previous~=nil and (previous==user or self:IsLocal(previous))
 if previous then table.insert(keys,previousLocal and pk(previous) or ik(previous)) end
 R.Check(not l.Dog.PaidRandom or PaidPolicy.Allowed(user),'Paid-item trading is unavailable for this account')
 local now=self.Now();local deliveries={}
 local ok,result,receipt=self.Tx:Run(keys,function(v)
  table.clear(deliveries)
  local book=v[bk(a.DogId)];l=book and book.Items[a.Id]
  R.Check(l and l.Mode=="Auction" and l.Ends>now and l.Bidder==previous,"Auction changed; refresh")
  R.Check(l.Seller~=user,"Cannot bid on your own dog")
  local p=v[pk(user)];self.Authorize(p,user)
  R.Check(a.Amount>=(l.Bidder and l.Price+math.max(1,math.ceil(l.Price*.05)) or l.Price),"Bid must beat current bid by 5%")
  if previous then
   if previousLocal then local old=v[pk(previous)];R.Credit(old,l.Price,false);reservations(old,a.DogId)[a.Id]=nil
   else deliver(v,previous,{Kind='Outbid',ListingId=a.Id,AssetKey=a.DogId,Refund=l.Price},deliveries)end
  end
  R.Check(free(p,a.DogId),"Dog storage full");R.Pay(p,a.Amount)
  reservations(p,a.DogId)[a.Id]=a.DogId;l.Price=a.Amount;l.Bidder=user
  if l.Ends-now<30 then l.Ends=math.min(l.MaxEnd,now+30) end
  local row=v.auctionQueue[a.Id];row.Ends=l.Ends;row.Bidder=user;row.Seller=row.Seller or l.Seller
  return {Message="Bid escrowed; previous bidder refunded"}
 end,request)
 if ok then self:Notify(deliveries)end
 return ok,result,receipt
end
function M:Close(dogId,id,user,request)
 local l=self:Listing(dogId,id);local now=self.Now();local buyer=l.Bidder
 if user then R.Check(l.Seller==user and not buyer,"Only unbid listings can be cancelled") else R.Check(l.Ends<=now,"Not due") end
 local history='sales:'..dogId..':'..math.floor(now/86400)
 local seller=l.Seller
 local sellerLocal=self:IsLocal(seller);local buyerLocal=buyer~=nil and self:IsLocal(buyer)
 local keys={sellerLocal and pk(seller) or ik(seller),bk(dogId),'auctionQueue',history}
 if buyer then table.insert(keys,buyerLocal and pk(buyer) or ik(buyer)) end
 local deliveries={}
 local ok,result,receipt=self.Tx:Run(keys,function(v)
  table.clear(deliveries)
  l=v[bk(dogId)] and v[bk(dogId)].Items[id]
  R.Check(l and l.Seller==seller and l.Bidder==buyer,"Listing changed")
  local owner=sellerLocal and v[pk(seller)] or nil
  if sellerLocal then R.Check(owner,"Seller data missing")end
  if user then R.Check(owner,"Seller data missing");self.Authorize(owner,user);R.Check(not l.Bidder,"Cannot cancel a bid") else R.Check(l.Ends<=now,"Auction extended") end
  if buyer then
   local p=buyerLocal and v[pk(buyer)] or nil
   if buyerLocal then R.Check(p and reservations(p,dogId)[id],"Escrow reservation missing")end
   self:Finish(v,l,p,owner,history,now,deliveries)
  else
   if owner then
    -- Listing escrow reserves a logical return slot; inventory may exceed the soft capacity.
    I.Normalize(owner)
    if l.Dog.ItemUid then R.Check(I.Count(owner.Items)<1000,"Item hard cap");I.Transfer(owner,l.Dog)
    else R.Check(not owner.Dogs[l.Dog.DogUid] and R.Count(owner.Dogs)<C.MaxDogs,"Cannot return dog yet");R.Transfer(l.Dog,owner,now,"ListingReturn")end
    owner.Listings[id]=nil
   else
    deliver(v,seller,{Kind='Returned',ListingId=id,AssetKey=dogId,Asset=R.Copy(l.Dog)},deliveries)
   end
   v[bk(dogId)].Items[id]=nil;v.auctionQueue[id]=nil
  end
  return {Message=buyer and "Auction settled" or "Dog returned"}
 end,request)
 if ok then self:Notify(deliveries)end
 return ok,result,receipt
end
-- Settles due listings. Attempts (not successes) are capped per pass and a failed
-- listing backs off, so a stuck listing can no longer drain the DataStore budget.
-- The seller's/bidder's own server settles first; others step in after a grace period.
function M:Due()
 -- Another server may hold the queue for a moment; just try again next pass.
 local readable,q=pcall(function()return self.Tx:Read('auctionQueue')end)
 if not readable then return 0 end
 q=q or {};local now=self.Now();local n,attempts=0,0
 self.SettleFailures=self.SettleFailures or {}
 for id,at in pairs(self.SettleFailures)do if now-at>600 then self.SettleFailures[id]=nil end end
 local due={}
 for id,row in pairs(q)do if type(row)=='table' and (row.Ends or math.huge)<=now then table.insert(due,{Id=id,Row=row})end end
 table.sort(due,function(a,b)return a.Row.Ends<b.Row.Ends end)
 for _,entry in ipairs(due)do
  if attempts>=3 then break end
  local id,row=entry.Id,entry.Row
  local failed=self.SettleFailures[id]
  if not(failed and now-failed<120)then
   local mine=self:IsLocal(row.Seller)or self:IsLocal(row.Bidder)
   if mine or (now-row.Ends>=60 and math.random()<.35) then
    attempts+=1
    local transport,ok=pcall(function()return self:Close(row.DogId,id)end)
    if transport and ok then n+=1;self.SettleFailures[id]=nil else self.SettleFailures[id]=now end
   end
  end
 end
 return n
end
local function applyEntry(p,e,now)
 if type(e)~='table'then return false end
 I.Normalize(p)
 if e.Kind=='Sold'then
  local net=tonumber(e.Net)
  if not(net and R.Int(net,0,C.MaxCash) and p.Cash+net<=C.MaxCash)then return false end
  R.Credit(p,net);Stats.Sale(p,net)
  if e.ListingId then p.Listings[e.ListingId]=nil end
  return true
 elseif e.Kind=='Outbid'then
  local refund=tonumber(e.Refund)
  if not(refund and R.Int(refund,0,C.MaxCash) and p.Cash+refund<=C.MaxCash)then return false end
  R.Credit(p,refund,false)
  if e.ListingId and e.AssetKey then reservations(p,e.AssetKey)[e.ListingId]=nil end
  return true
 elseif e.Kind=='Won'or e.Kind=='Returned'then
  local d=e.Asset;if type(d)~='table'then return false end
  if d.ItemUid then
   if p.Items[d.ItemUid] or (e.Kind=='Returned' and I.Count(p.Items)>=1000) then return false end
   I.Transfer(p,d)
  else
   if type(d.DogUid)~='string' or p.Dogs[d.DogUid] or R.Count(p.Dogs)>=C.MaxDogs then return false end
   if e.Kind=='Won'then d.PricePaid=e.Price end
   R.Transfer(d,p,now,e.Kind=='Won'and(e.Mode or'Auction')or'ListingReturn')
  end
  if e.Kind=='Won'then if e.AssetKey then reservations(p,e.AssetKey)[e.ListingId]=nil end
  else p.Listings[e.ListingId]=nil end
  return true
 end
 return false
end
-- Applies inbox entries to a profile owned by this server. Returns ok,{Applied=n}.
function M:DrainInbox(uid)
 local box=self.Tx:Read(ik(uid))
 if type(box)~='table' or not box.Entries or not next(box.Entries)then return true,{Applied=0}end
 local now=self.Now()
 -- Skip the durable transaction when nothing can be applied yet (e.g. storage full).
 local probe=self.Tx:Read(pk(uid));if not probe then return true,{Applied=0}end
 local any=false
 for _,e in pairs(box.Entries)do if applyEntry(R.Copy(probe),R.Copy(e),now)then any=true;break end end
 if not any then return true,{Applied=0}end
 return self.Tx:Run({pk(uid),ik(uid)},function(v)
  local p=v[pk(uid)];self.Authorize(p,uid)
  local current=v[ik(uid)];if type(current)~='table' or not current.Entries then return {Applied=0}end
  local keys={};for k in pairs(current.Entries)do table.insert(keys,k)end
  table.sort(keys,function(a,b)return (tonumber(a)or 0)<(tonumber(b)or 0)end)
  local applied=0
  for _,k in ipairs(keys)do
   if applyEntry(p,current.Entries[k],now)then current.Entries[k]=nil;applied+=1 end
  end
  R.Validate(p)
  return {Applied=applied}
 end)
end
function M:Query(a)
 local ids={}
 if a.DogId and a.DogId~="" then R.Check(definition(a.DogId),"Unknown dog");ids={a.DogId}
 else
  local active={};for _,row in pairs(self:Cached('auctionQueue',15) or {})do
   local def=definition(row.DogId)
   if def and (a.Kind=='Item')==itemKey(row.DogId) and (not a.Depth or def.Depth==a.Depth)then active[row.DogId]=true end
  end
  for id in pairs(active)do table.insert(ids,id)end;table.sort(ids)
 end
 local result={Items={},Lowest=nil,Average=nil,Median24h=nil,Median7d=nil,Volume24h=0,Volume7d=0,RecentSales={}}
 for _,id in ipairs(ids) do
  local book=self:Cached(bk(id),15) or {Items={}}
  for _,l in pairs(book.Items) do
   local d=l.Dog
   if l.Ends>self.Now() and (not a.Search or a.Search==''or d.DisplayName:lower():find(a.Search:lower(),1,true)) and (not a.Rarity or a.Rarity=="" or d.Rarity==a.Rarity)
    and (not a.Variant or a.Variant=="" or d.Variant==a.Variant)
    and (not a.Edition or a.Edition=="" or d.Edition==a.Edition)
    and (not a.Serial or d.SerialNumber==a.Serial)
    and (not a.Mastery or (d.Mastery or 0)>=a.Mastery)
    and (not a.Ascension or (d.AscensionLevel or 0)>=a.Ascension)
    and (not a.Depth or d.Depth==a.Depth) and (not a.Class or a.Class=='' or d.Class==a.Class)
    and (not a.Mutation or a.Mutation=='' or d.Mutation==a.Mutation) and (not a.WeightTier or a.WeightTier=='' or d.WeightTier==a.WeightTier)
    and (not a.SetId or a.SetId=='' or d.SetId==a.SetId) and (not a.MinWeight or (d.WeightKg or 0)>=a.MinWeight)
    and (not a.MaxWeight or (d.WeightKg or 0)<=a.MaxWeight)
    and (not a.MinPrice or l.Price>=a.MinPrice) and (not a.MaxPrice or l.Price<=a.MaxPrice) then
     table.insert(result.Items,R.Copy(l))
     if l.Mode=="BuyNow" then result.Lowest=math.min(result.Lowest or math.huge,l.Price) end
   end
  end
 end
 local order=a.Sort or 'CHEAPEST'
 table.sort(result.Items,function(x,y)
  if order=='HEAVIEST'then return (x.Dog.WeightKg or 0)>(y.Dog.WeightKg or 0)
  elseif order=='LIGHTEST'then return (x.Dog.WeightKg or 0)<(y.Dog.WeightKg or 0)
  elseif order=='RAREST'then return (x.Dog.CombinedOdds or 0)>(y.Dog.CombinedOdds or 0)
  elseif order=='NEWEST'then return x.Created>y.Created
  elseif order=='MOST EXPENSIVE'then return x.Price>y.Price end
  return x.Price<y.Price
 end)
 result.Total=#result.Items
 local page=R.Int(a.Page or 1,1,1000) and (a.Page or 1) or 1
 local subset={};for i=(page-1)*30+1,math.min(page*30,#result.Items) do table.insert(subset,result.Items[i]) end;result.Items=subset
 local historyId=#ids==1 and ids[1]or(result.Items[1]and result.Items[1].AssetKey)
 if historyId then
  result.HistoryId=historyId
  local now=self.Now();local day=math.floor(now/86400);local week,one,sum={}, {},0
  for offset=0,7 do for _,sale in ipairs(self:Cached('sales:'..historyId..':'..(day-offset),60) or {}) do
   if sale.At>=now-604800 then table.insert(week,sale.Price);sum+=sale.Price;table.insert(result.RecentSales,sale) end
   if sale.At>=now-86400 then table.insert(one,sale.Price) end
  end end
  local function median(t) table.sort(t);local n=#t;if n==0 then return nil end;return n%2==1 and t[math.ceil(n/2)] or (t[n/2]+t[n/2+1])/2 end
  result.Median24h=median(one);result.Median7d=median(week);result.Volume24h=#one;result.Volume7d=#week
  result.Average=#week>0 and sum/#week or nil
  table.sort(result.RecentSales,function(a,b)return a.At>b.At end)
  while #result.RecentSales>30 do table.remove(result.RecentSales) end
 end
 return result
end
return M

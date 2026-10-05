-- Inventory item details and the own-yard selector share the PAWPAD theme.
local RS=game:GetService('ReplicatedStorage');local Http=game:GetService('HttpService')
local player=game.Players.LocalPlayer
local C=require(RS.LuckyBlockConfig);local Visual=require(RS.LuckyBlockVisuals)
local V=require(script.Parent.PreviewRenderer);local N=require(script.Parent.GUIIntegration)
local S={}
local function beginOpenPrediction(uid,tier)
 player:SetAttribute('LuckyBlockOpeningUid',uid);player:SetAttribute('LuckyBlockOpeningTier',tier);player:SetAttribute('LuckyBlockOpeningAt',workspace:GetServerTimeNow())
 task.delay(6,function()if player:GetAttribute('LuckyBlockOpeningUid')==uid then player:SetAttribute('LuckyBlockOpeningUid',nil);player:SetAttribute('LuckyBlockOpeningTier',nil);player:SetAttribute('LuckyBlockOpeningAt',nil)end end)
end
local function cancelOpenPrediction()
 player:SetAttribute('LuckyBlockOpeningUid',nil);player:SetAttribute('LuckyBlockOpeningTier',nil);player:SetAttribute('LuckyBlockOpeningAt',nil)
end
local function request(c,action,args,callback)
 local s=c.State
 if s.BlockBusy then return end;s.BlockBusy=true;s.BlockMessage=nil;c.Draw()
 task.spawn(function()
  local transport,ok,value=pcall(function()return RS.RewardRequest:InvokeServer(action,args)end)
  s.BlockBusy=false
  if transport and ok then if callback then callback(value)end
  else
   if action=='OpenBlock'then cancelOpenPrediction()end
   s.BlockMessage=transport and tostring(value)or'Connection interrupted. Retry the same action safely.'
   if action=='PlaceBlock'and transport and not tostring(value):lower():find('pending',1,true)and s.ActivePlacementKey then s.PlacementRequests[s.ActivePlacementKey]=nil end
  end
  if c.Gui:GetAttribute('OpenMenu')==c.Page then c.Draw()end
 end)
end
local function art(c,parent,tier,x,y,w,h)local model=Visual.Build(tier);V.Scene(parent,model,x,y,w,h);model:Destroy()end
local function percent(chance)return string.format('%.6g%%',math.max(0,chance or 0)*100)end
function S.Odds(c)
 local U,s,p,W,H=c.U,c.State,c.Snapshot.Profile,c.W,c.H;local P=U.Colors
 local function oddsColor(rarity)return rarity=='Common'and P.muted or U.Rarity[rarity]or P.muted end
 local sc=U.Scroll(c.Parent,'LuckyOddsView',0,0,W,H)
 local offer=type(s.LuckyOffer)=='table'and s.LuckyOffer or nil
 local owned=type(s.BlockOddsUid)=='string'and(p.OwnedBlocks or{})[s.BlockOddsUid]or nil
 local tier=offer and offer.Tier or owned and owned.Tier or s.BlockOddsTier or C.Rarities[1]
 local rows=offer and offer.Odds or owned and owned.Odds or s.BlockCatalog and s.BlockCatalog.Odds[tier]
 local y=8
 if offer then
  U.Text(sc,tier:upper()..' LUCKY BLOCK · '..U.Fmt(offer.Price or C.ConveyorPrices[tier])..' COINS',10,y,W-28,43,24,P.gold,true);y+=49
 elseif owned then U.Text(sc,tier:upper()..' · YOUR LUCKY BLOCK',10,y,W-28,43,24,P.gold,true);y+=49
 else
  U.Cycle(sc,'OddsTier',tier:upper()..' LUCKY BLOCK',C.Rarities,tier,10,y,W-28,function(value)s.BlockOddsTier=value;s.BlockOddsPage=1;c.Draw()end);y+=49
 end
 local explanation=owned and owned.Odds and 'These chances were saved for this exact block.'or offer and 'The block keeps moving. Buy before it leaves the tongue. One block gives one dog.'or 'Current server chances. Each percentage is per block; a higher block tier improves its reward pool.'
 U.Text(sc,explanation,10,y,W-28,55,17,P.muted);y+=62
 if not rows then
  U.Text(sc,s.BlockMessage or 'Loading exact server chances…',10,y,W-28,55,20,P.gold)
  if not s.BlockBusy and not s.BlockCatalogFailed then
   s.BlockCatalogFailed=true;request(c,'Catalog',{},function(value)s.BlockCatalog=value;s.BlockCatalogFailed=nil end)
  elseif s.BlockCatalogFailed and not s.BlockBusy then
   U.Button(sc,'RetryOdds','RETRY',10,y+65,W-28,42,function()s.BlockCatalogFailed=nil;c.Draw()end,P.blue)
  end
  return
 end
 local totals,ordered={},{}
 for _,row in ipairs(rows)do
  totals[row.Rarity]=(totals[row.Rarity]or 0)+(row.Chance or 0)
  table.insert(ordered,row)
 end
 local columns=c.Mobile and 2 or 3;local width=(W-28-(columns-1)*10)/columns
 for i,rarity in ipairs(C.Rarities)do
  local card=U.Panel(sc,'OddsTier'..i,10+((i-1)%columns)*(width+10),y+math.floor((i-1)/columns)*55,width,47)
  U.Text(card,rarity..' · '..percent(totals[rarity]),8,4,width-16,37,18,oddsColor(rarity),true)
 end
 y+=math.ceil(#C.Rarities/columns)*55+7
 if offer then
  local expired=offer.ExpiresAt and offer.ExpiresAt<=(c.Now and c.Now()or os.time())
  if offer.ExpiresAt and not expired then
   local left=math.max(0,offer.ExpiresAt-(c.Now and c.Now()or os.time()))
   local clock=U.Text(sc,'Reservation: '..string.format('%02d:%02d:%02d',math.floor(left/3600),math.floor(left/60)%60,math.floor(left)%60),10,y,W-28,28,17,P.muted)
   clock:SetAttribute('Deadline',offer.ExpiresAt);clock:SetAttribute('CountdownStyle','Clock');clock:SetAttribute('CountdownPrefix','Reservation: ');y+=34
  end
  if expired then U.Text(sc,'This offer expired. Close this page and choose a block on the conveyor.',10,y,W-28,56,18,P.gold);y+=62 end
  U.Button(sc,'BuyBlock',expired and 'OFFER EXPIRED'or s.BlockBusy and 'SAVING…'or 'BUY · '..U.Fmt(offer.Price or C.ConveyorPrices[tier])..' COINS',10,y,W-28,46,not expired and not s.BlockBusy and function()
   request(c,'BuyBlock',{BlockUid=offer.BlockUid,OddsVersion=offer.OddsVersion},function()s.LuckyOffer=nil;N.Close()end)
  end or nil,P.green);y+=54
 end
 if s.BlockMessage then U.Text(sc,s.BlockMessage,10,y,W-28,52,18,P.gold);y+=58 end
 table.sort(ordered,function(a,b)if a.Chance~=b.Chance then return a.Chance>b.Chance end;return tostring(a.Id)<tostring(b.Id)end)
 local pageSize=12;local pages=math.max(1,math.ceil(#ordered/pageSize));local page=math.clamp(s.BlockOddsPage or 1,1,pages)
 U.Text(sc,'ALL DOGS · '..#ordered..' possible · page '..page..' / '..pages,10,y,W-28,33,19,P.text,true);y+=39
 local dogColumns=c.Mobile and 1 or 2;local dogWidth=(W-28-(dogColumns-1)*12)/dogColumns
 for i=(page-1)*pageSize+1,math.min(page*pageSize,#ordered)do
  local row=ordered[i];local index=i-(page-1)*pageSize-1
  local card=U.Panel(sc,'DogOdds'..i,10+(index%dogColumns)*(dogWidth+12),y+math.floor(index/dogColumns)*73,dogWidth,65)
  U.Text(card,row.Name or row.Id,9,3,dogWidth-18,28,18,P.text,true)
  U.Text(card,(row.Rarity or '')..' · '..percent(row.Chance),9,32,dogWidth-18,27,17,oddsColor(row.Rarity))
 end
 y+=math.ceil(math.min(pageSize,#ordered-(page-1)*pageSize)/dogColumns)*73+8
 U.Button(sc,'OddsPrevious','‹ PREVIOUS',10,y,(W-40)/2,40,page>1 and function()s.BlockOddsPage=page-1;c.Draw()end or nil,P.blue)
 U.Button(sc,'OddsNext','NEXT ›',22+(W-40)/2,y,(W-40)/2,40,page<pages and function()s.BlockOddsPage=page+1;c.Draw()end or nil,P.blue)
end
function S.Build(c)
 if c.Page=='LuckyOdds'then return S.Odds(c)end
 local U,s,p,W,H=c.U,c.State,c.Snapshot.Profile,c.W,c.H;local P=U.Colors
 local sc=U.Scroll(c.Parent,'BlockInventoryView',0,0,W,H)
 if c.Page=='LuckyPad'then
  local ctx=s.LuckyPad
  if not ctx or ctx.YardId~=player:GetAttribute('YardId')then U.Text(sc,'Use a Lucky pad in your own yard.',12,12,W-24,70,23);return end
  local occupied
  for _,b in pairs(p.OwnedBlocks or{})do if (b.State=='Placed'or b.State=='Ready')and b.Slot==ctx.Slot then occupied=b;break end end
  if occupied then
   local now=c.Now and c.Now()or os.time();local ready=(occupied.ReadyAt or math.huge)<=now
   art(c,sc,occupied.Tier,math.max(12,(W-240)/2),6,240,200)
   U.Center(sc,occupied.Tier:upper()..' LUCKY BLOCK',12,212,W-24,45,26,P.text,true)
   local timer=U.Center(sc,ready and 'READY TO OPEN'or 'PREPARING...',12,268,W-24,42,23,P.gold,true)
   if not ready then timer:SetAttribute('Deadline',occupied.ReadyAt);timer:SetAttribute('CountdownPrefix','Ready in ');timer:SetAttribute('CountdownStyle','Clock')end
   U.Text(sc,'Your reward is safe. Press OPEN when the timer ends.',12,317,W-24,54,18,P.muted)
   U.Button(sc,'OpenBlock',s.BlockBusy and 'OPENING...'or ready and 'OPEN'or 'WAIT FOR TIMER',12,384,W-24,58,ready and not s.BlockBusy and function()
    beginOpenPrediction(occupied.Uid,occupied.Tier)
    N.Close()
    request(c,'OpenBlock',{Uid=occupied.Uid,Slot=ctx.Slot,YardId=ctx.YardId},function()end)
   end or nil,P.green)
   if s.BlockMessage then U.Text(sc,s.BlockMessage,12,455,W-24,70,18,P.gold)end
   return
  end
  U.Text(sc,'YOUR YARD · PAD '..ctx.Slot..'\nChoose one owned block. Placement starts its timer.',12,6,W-24,74,23,P.text,true)
  local rows={}
  for uid,b in pairs(p.OwnedBlocks or{})do if b.State=='Stored'or b.State=='Carried'then table.insert(rows,{Key=uid,Uid=uid,Tier=b.Tier,Quantity=1})end end
  for tier,n in pairs(p.LuckyCredits or{})do if n>0 then table.insert(rows,{Key='credit:'..tier,Tier=tier,Quantity=n,CreditTier=tier})end end
  table.sort(rows,function(a,b)return a.Tier==b.Tier and a.Key<b.Key or C.Rank(a.Tier)<C.Rank(b.Tier)end)
  if #rows==0 then U.Text(sc,'No Lucky Blocks in Inventory',12,100,W-24,85,25,P.gold,true);return end
  local cols=c.Mobile and 1 or 3;local width=(W-24-(cols-1)*14)/cols
  s.PlacementRequests=s.PlacementRequests or{}
  for i,row in ipairs(rows)do
   local panel=U.Card(sc,'OwnedBlock'..i,8+((i-1)%cols)*(width+14),95+math.floor((i-1)/cols)*334,width,318,true)
   art(c,panel,row.Tier,8,8,width-16,145)
   U.Center(panel,row.Tier:upper()..' LUCKY BLOCK',10,151,width-20,38,20,P.text,true)
   U.Badge(panel,'OWNED ×'..row.Quantity,10,191,width-20,P.gold)
   local key=tostring(ctx.YardId)..':'..ctx.Slot..':'..row.Key
   U.Button(panel,'Place','PLACE',10,227,width-20,36,not s.BlockBusy and function()
    s.ActivePlacementKey=key;s.PlacementRequests[key]=s.PlacementRequests[key]or Http:GenerateGUID(false):gsub('-','')
    request(c,'PlaceBlock',{Uid=row.Uid,CreditTier=row.CreditTier,Slot=ctx.Slot,YardId=ctx.YardId,Request=s.PlacementRequests[key]},function()
     s.PlacementRequests[key]=nil;N.Close()
    end)
   end or nil,P.green)
   U.Button(panel,'BlockOdds','CHANCES',10,270,width-20,35,function()N.OpenScreen('LuckyOdds',{LuckyOffer=false,BlockOddsUid=row.Uid or false,BlockOddsTier=row.Tier,BlockOddsPage=1,BlockCatalog=false,BlockCatalogFailed=false,BlockMessage=false})end,P.blue)
  end
  if s.BlockMessage then U.Text(sc,s.BlockMessage,12,100+math.ceil(#rows/cols)*334,W-24,75,20,P.gold)end
  return
 end
end
return S

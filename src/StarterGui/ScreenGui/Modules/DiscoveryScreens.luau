local Rep=game:GetService('ReplicatedStorage');local D=require(Rep.DogEconomy.ItemDefinitions);local Depth=require(Rep.DogEconomy.DepthDefinitions)
local V=require(script.Parent.PreviewRenderer);local Screens={}
local tiers={'All','TINY','SMALL','STANDARD','HEAVY','MASSIVE','COLOSSAL','TITANIC','MONSTROUS','IMPOSSIBLE','WORLD RECORD'}
function Screens.Build(c)
 local U,p,s,root,W,H=c.U,c.Snapshot.Profile,c.State,c.Parent,c.W,c.H;local P=U.Colors
 local function change(k,v)s[k]=v;c.Draw()end
 local function section(parent,title,x,y,w)local b=U.Header(parent,'Section',x,y,w,38);U.Text(b,title,14,0,w-28,38,24,P.gold,true);return b end
 local function info(parent,label,value,x,y,w)U.Text(parent,label,x,y,w,20,14,P.muted);U.Text(parent,value,x,y+19,w,29,19,nil,true)end
 local function list(parent,n,values,cols,ch,w,h,callback)
  local grid,cw=U.Grid(parent,n,0,0,w,h,cols,ch)
  for i,x in ipairs(values)do local card=U.Panel(grid,'ItemCard',0,0,cw,ch);card.LayoutOrder=i
   local tone=U.Tiers[x.TierIndex or 3];if s.SelectedItem==x.ItemUid then U.Glow(card,P.gold)else U.Stroke(card,tone,1.4)end
   V.Item(card,x,7,6,cw-14,ch-121);if x.Mutation~='NORMAL'then U.Text(card,x.Mutation,6,6,cw-44,21,11,P.gold,true)end;U.Center(card,x.DisplayName,6,ch-113,cw-12,52,18,nil,true)
   U.Center(card,U.Weight(x.WeightKg),5,ch-59,cw-10,23,15,P.muted)
   U.Badge(card,x.WeightTier or x.Class,8,ch-33,cw-16,tone)
   local click=U.New('TextButton',{Name='SelectItem',Text='',BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=4},card);click.Activated:Connect(function()callback(x)end)
   if p.Items[x.ItemUid]then U.Button(card,'Favorite',x.Favorite and '★'or '☆',cw-32,5,27,27,function()c.Send('ItemFavorite',{Uid=x.ItemUid,Enabled=not x.Favorite})end,x.Favorite and P.gold or P.panel).ZIndex=5 end
  end
  return grid
 end
 local function details(parent,x,w,h,market)
  if not x then U.Center(parent,'Select a find to inspect it.',15,60,w-30,80,23,P.muted,true);return end
  local owned=not market and p.Items[x.ItemUid];local sc=U.Scroll(parent,'ItemDetailScroll',10,8,w-20,h-(owned and 109 or 16));local width=w-44;local y=0
  U.Text(sc,x.DisplayName:upper(),6,y,width-12,55,25,P.text,true);y+=59
  U.Text(sc,(x.Class or '')..' · '..Depth[tostring(x.Depth)].Name,6,y,width-12,25,17,P.muted);y+=31
  local previewY=y;local previewW=width*.45;V.Item(sc,x,6,y,previewW-10,244)
  local rows={{'Exact weight',U.Weight(x.WeightKg)},{'Weight tier',x.WeightTier},{'Mutation',x.Mutation},{'Discovery chance',U.Odds(x.BaseDropChance)},{'Weight chance',U.Odds(x.WeightTierChance)},{'Mutation chance',U.Odds(x.MutationChance)},{'Combined odds',x.CombinedOdds and '1 in '..string.format('%.8g',x.CombinedOdds)or '—'},{'NPC value',U.Fmt(require(Rep.ItemValuation).Price(x))..' Cash'}}
  for _,v in ipairs(rows)do local pw=width-previewW-8;local b=U.Panel(sc,'Property',previewW+4,y,pw,43);U.Text(b,v[1],7,1,pw-14,16,11,P.muted);U.Text(b,v[2]or '—',7,17,pw-14,25,15,nil,true);y+=48 end
  U.Text(sc,D[x.ItemId].Description~=''and D[x.ItemId].Description or 'Every find tells a story.',8,y,width-16,46,17,P.gold);y+=50
  U.Text(sc,'Collection: '..(p.Collection[x.ItemId]and 'DISCOVERED'or 'MISSING')..'\nOriginal finder: '..tostring(x.OriginalFinderUserId or x.FoundByUserId or '—')..'\n'..(x.FoundAt and os.date('!%d %b %Y, %H:%M UTC',x.FoundAt)or ''),8,y,width-16,78,15,P.muted);y+=82
  if x.RecordAtCreation then local names={};for _,k in ipairs({'Personal','Server','Global'})do if x.RecordAtCreation[k]then table.insert(names,k)end end;if #names>0 then U.Text(sc,'RECORD AT FIND: '..table.concat(names,' / '),8,y,width-16,44,16,P.gold,true);y+=48 end end
  if owned then
   local dock=U.Panel(parent,'ItemActions',10,h-99,w-20,90);local dw=w-34
   U.Button(dock,'Favorite',x.Favorite and '★ FAVORITE'or '☆ FAVORITE',7,7,dw,37,function()c.Send('ItemFavorite',{Uid=x.ItemUid,Enabled=not x.Favorite})end,P.blue)
   U.Center(dock,'Sell with Milo in your yard · trade in Marketplace',7,50,dw,32,14,P.muted)

  end
  U.Frame(sc,'End',0,y,1,1).BackgroundTransparency=1
 end
 if c.Page=='Discoveries'then
  local heading=U.Header(root,'DiscoveriesHeading',0,0,W,42);U.Center(heading,'DISCOVERIES',W*.24,0,W*.5,42,35,P.text,true);U.Text(root,'Found '..U.Count(p.Collection)..' / '..U.Count(D),W-220,5,210,30,20,P.gold,true)
  local detailW=c.Mobile and 0 or math.floor(W*.32);local leftW=W-detailW-(detailW>0 and 12 or 0)
  U.Search(root,'SearchFinds','Search discoveries…',s.FindSearch,0,49,leftW,function(v)change('FindSearch',v)end)
  local filters={{'FindDepth',{'All',1,2,3,4,5},function(v)return v=='All'and 'All depths'or Depth[tostring(v)].Name end},{'FindClass',{'All','Treasure','Artifact','Special','Secret','World Find'},function(v)return v=='All'and 'All classes'or v end},{'FindTier',tiers,function(v)return v=='All'and 'All weights'or v end},{'FindMutation',{'All','NORMAL','GOLDEN','RAINBOW','CURSED','GLITCHED'},function(v)return v=='All'and 'All types'or v end},{'FindSort',{'Newest','Heaviest','Lightest','Rarest','Value','Favorites'},function(v)return v end}}
  local fc=math.max(1,math.min(3,math.floor(leftW/165)));local fw=(leftW-(fc-1)*7)/fc
  for i,f in ipairs(filters)do U.Cycle(root,f[1],f[3](s[f[1]]or f[2][1]),f[2],s[f[1]],((i-1)%fc)*(fw+7),96+math.floor((i-1)/fc)*47,fw,function(v)change(f[1],v)end)end
  local gy=96+math.ceil(#filters/fc)*47+7;local values={}
  for _,x in pairs(p.Items)do if (s.FindDepth=='All'or x.Depth==s.FindDepth)and(s.FindClass=='All'or x.Class==s.FindClass)and(s.FindTier=='All'or x.WeightTier==s.FindTier)and(s.FindMutation=='All'or x.Mutation==s.FindMutation)and(not s.FindSearch or x.DisplayName:lower():find(s.FindSearch:lower(),1,true))then table.insert(values,x)end end
  table.sort(values,function(a,b)local k=s.FindSort;if k=='Heaviest'then return a.WeightKg>b.WeightKg elseif k=='Lightest'then return a.WeightKg<b.WeightKg elseif k=='Rarest'then return a.CombinedOdds>b.CombinedOdds elseif k=='Value'then return a.SellValue>b.SellValue elseif k=='Favorites'and a.Favorite~=b.Favorite then return a.Favorite end;return a.FoundAt==b.FoundAt and a.ItemUid<b.ItemUid or a.FoundAt>b.FoundAt end)
  local area=U.Panel(root,'DiscoveriesGrid',0,gy,leftW,H-gy,true);local holder=U.Frame(area,'GridHolder',9,9,leftW-18,H-gy-18);holder.BackgroundTransparency=1
  list(holder,'FindGrid',values,math.max(1,math.floor((leftW-18)/185)),242,leftW-18,H-gy-18,function(x)s.SelectedItem=x.ItemUid;if c.Mobile then c.Show('Inspect')else c.Draw()end end)
  if #values==0 then U.Center(area,'No finds match these filters.\nAssign a dog to your yard to start digging.',20,65,leftW-40,90,23,P.muted,true)end
  if detailW>0 then local panel=U.Panel(root,'SelectedFind',leftW+12,49,detailW,H-49,true);details(panel,p.Items[s.SelectedItem]or values[1],detailW,H-49)end
 elseif c.Page=='Inspect'then details(root,p.Items[s.SelectedItem],W,H)
 elseif c.Page=='Collection'then
  local sc=U.Scroll(root,'CollectionPage',0,0,W,H)
  local found=U.Count(p.Collection);local total=U.Count(D)
  section(sc,'YOUR COLLECTION',8,0,W-24)
  U.Text(sc,found..' / '..total..' discoveries',16,45,W-40,30,22,P.text,true)
  U.Bar(sc,16,82,W-40,24,total>0 and found/total or 0,P.green)
  local columns=math.max(1,math.min(5,math.floor((W-16)/155)));local bw=(W-24-(columns-1)*10)/columns
  for i=1,5 do
   local depth=Depth[tostring(i)];local count=0
   for _,id in ipairs(depth.Items)do if p.Collection[id]then count+=1 end end
   local selected=(s.CollectionDepth or 1)==i
   local button=U.Button(sc,'Depth'..i,depth.Name..'\n'..count..' / '..#depth.Items,8+(i-1)%columns*(bw+10),122+math.floor((i-1)/columns)*72,bw,62,function()change('CollectionDepth',i)end,selected and P.purple or P.blue)
   button.Caption.TextSize=18
   if selected then U.Glow(button,P.gold)end
  end
  local y=136+math.ceil(5/columns)*72
  local depth=Depth[tostring(s.CollectionDepth or 1)]
  section(sc,depth.Name:upper(),8,y,W-24);y+=50
  local cols=math.max(1,math.min(4,math.floor((W-8)/190)));local cw=(W-24-(cols-1)*12)/cols
  for i,id in ipairs(depth.Items)do
   local def=D[id];local known=p.Collection[id]
   local card=U.Panel(sc,'CollectionItem_'..id,8+(i-1)%cols*(cw+12),y+math.floor((i-1)/cols)*218,cw,206)
   if known then
    V.Item(card,{ItemId=id,WeightKg=def.BaseWeightKg,Mutation='NORMAL'},7,7,cw-14,134)
    U.Center(card,def.DisplayName,8,145,cw-16,52,18,P.text,true)
   else
    U.Center(card,'?',8,20,cw-16,95,58,P.muted,true)
    U.Center(card,'UNDISCOVERED',8,145,cw-16,52,17,P.muted,true)
   end
  end
 elseif c.Page=='Marketplace'or c.Page=='Listing'then
  if H<500 then root=U.Scroll(root,'MarketplacePage',0,0,W,H);H=800 end
  section(root,'MARKETPLACE',0,0,W);local detailW=c.Mobile and 0 or math.floor(W*.33);local lw=W-(detailW>0 and detailW+12 or 0)
  U.Search(root,'MarketSearch','Search items by name…',s.MarketSearch,0,47,lw-195,function(v)s.MarketSearch=v end)
  U.Button(root,'CreateListing','SELL A FIND',lw-184,47,184,38,function()c.Show('CreateListing')end,P.gold)
  local filters={{'MarketDepth',{'All',1,2,3,4,5}},{'MarketClass',{'All','Treasure','Artifact','Special','Secret','World Find'}},{'MarketTier',tiers},{'MarketMutation',{'All','NORMAL','GOLDEN','RAINBOW','CURSED','GLITCHED'}},{'MarketSort',{'CHEAPEST','HEAVIEST','LIGHTEST','RAREST','MOST EXPENSIVE','NEWEST'}}}
  local cols=math.max(1,math.min(3,math.floor(lw/165)));local fw=(lw-7*(cols-1))/cols
  for i,f in ipairs(filters)do local current=s[f[1]]or f[2][1];U.Cycle(root,f[1],tostring(current),f[2],current,(i-1)%cols*(fw+7),94+math.floor((i-1)/cols)*47,fw,function(v)change(f[1],v)end)end
  local fy=94+math.ceil(#filters/cols)*47+6
  U.Search(root,'MinPrice','Min price',s.MinPrice,0,fy,lw*.23,function(v)s.MinPrice=v end);U.Search(root,'MaxPrice','Max price',s.MaxPrice,lw*.25,fy,lw*.23,function(v)s.MaxPrice=v end)
  local function search(page)
   s.MarketPage=page or 1
   local a={Kind='Item',Page=s.MarketPage or 1,Sort=s.MarketSort or 'CHEAPEST',MinPrice=tonumber(s.MinPrice),MaxPrice=tonumber(s.MaxPrice)}
   if s.MarketSearch and s.MarketSearch~=''then a.Search=s.MarketSearch end
   for _,pair in ipairs({{'MarketDepth','Depth'},{'MarketClass','Class'},{'MarketTier','WeightTier'},{'MarketMutation','Mutation'}})do if s[pair[1]]and s[pair[1]]~='All'then a[pair[2]]=s[pair[1]]end end
   c.Query(a,function(v)s.Market=v;s.Listing=v.Items[1];s.Details=nil end)
  end
  U.Button(root,'SearchMarket','SEARCH',lw*.5,fy,lw*.24,38,function()search(1)end,P.blue)
  U.Button(root,'PreviousMarketPage','‹',lw*.76,fy,lw*.1,38,(s.MarketPage or 1)>1 and function()search(s.MarketPage-1)end or nil)
  U.Button(root,'NextMarketPage','›',lw*.88,fy,lw*.1,38,s.Market and (s.MarketPage or 1)*30<s.Market.Total and function()search((s.MarketPage or 1)+1)end or nil)
  local market=s.Market;local gy=fy+52
  if market then
   if not c.Mobile and #market.Items>0 then
    local strip=U.Panel(root,'FeaturedListings',0,gy,lw,102);U.Text(strip,'LIVE LISTINGS',10,3,lw-20,22,15,P.gold,true);local fw=(lw-24)/3
    for i=1,math.min(3,#market.Items)do local l=market.Items[i];local x=(i-1)*(fw+6)+6;V.Item(strip,l.Dog,x,28,65,63);U.Text(strip,l.Dog.DisplayName..'\n'..U.Fmt(l.Price)..' Cash',x+72,29,fw-78,60,16,P.gold,true)end;gy+=113
   end
   local g,cw=U.Grid(root,'MarketGrid',0,gy,lw,H-gy,math.max(1,math.floor(lw/185)),232)
   for i,l in ipairs(market.Items)do local x=l.Dog;local card=U.Panel(g,'ListingCard',0,0,cw,232);card.LayoutOrder=i;V.Item(card,x,5,5,cw-10,117);U.Center(card,x.DisplayName,5,121,cw-10,48,18,nil,true);U.Center(card,U.Weight(x.WeightKg)..' · '..x.Mutation,4,166,cw-8,25,14,P.muted);U.Badge(card,U.Fmt(l.Price)..' Cash',6,200,cw-12,P.gold)
    local b=U.New('TextButton',{Name='SelectListing',Text='',BackgroundTransparency=1,Size=UDim2.fromScale(1,1)},card);b.Activated:Connect(function()s.Listing=l;if c.Mobile then c.Show('Listing')else c.Draw()end end)
   end
   if #market.Items==0 then U.Center(root,'No active listings match your search.',10,gy+20,lw-20,70,23,P.muted,true)end
  else U.Center(root,'Search real player listings.\nPrices and sales history come from completed trades.',20,gy+45,lw-40,100,24,P.muted,true)end
  local l=s.Listing
  if l and (detailW>0 or c.Page=='Listing')then
   local px=detailW>0 and lw+12 or 0;local pw=detailW>0 and detailW or W
   if c.Mobile then root:ClearAllChildren()end
   local panel=U.Panel(root,'ListingDetail',px,detailW>0 and 47 or 0,pw,H-(detailW>0 and 47 or 0),true)
   local sc=U.Scroll(panel,'ListingScroll',10,8,pw-20,H-73);local x=l.Dog;local iw=pw-44
   U.Text(sc,x.DisplayName,8,0,iw-16,43,25,P.gold,true);V.Item(sc,x,8,49,iw*.43,154)
   U.Text(sc,U.Fmt(l.Price)..' CASH · '..l.Mode..'\nSeller '..l.Seller..'\n'..U.Weight(x.WeightKg)..'\n'..x.WeightTier..' · '..x.Mutation..'\n'..Depth[tostring(x.Depth)].Name,iw*.47,51,iw*.5,152,16)
   local y=214
   if l.Mode=='BuyNow'then U.Button(sc,'BuyNow','BUY NOW',8,y,iw-16,44,function()c.Confirm('BUY '..x.DisplayName,'Pay '..U.Fmt(l.Price)..' Cash for this exact '..U.Weight(x.WeightKg)..' find.','BuyListing',{DogId=l.AssetKey,Id=l.Id})end,P.green)
   else U.Search(sc,'BidAmount','Bid Cash',s.Bid,8,y,iw-16,function(v)s.Bid=v end);y+=45;U.Button(sc,'Bid','PLACE BID',8,y,iw-16,44,function()c.Confirm('PLACE BID','Cash is reserved until outbid or settlement.','Bid',{DogId=l.AssetKey,Id=l.Id,Amount=tonumber(s.Bid)or l.Price})end,P.green)end;y+=53
   U.Button(sc,'Track',p.TrackedListings[l.Id]and 'TRACKED ★'or 'TRACK',8,y,iw-16,39,function()c.Send('TrackListing',{Id=l.Id,Key=l.AssetKey,Enabled=not p.TrackedListings[l.Id]})end,P.blue);y+=48
   if l.Seller==p.UserId and not l.Bidder then U.Button(sc,'CancelListing','CANCEL LISTING',8,y,iw-16,39,function()c.Confirm('CANCEL LISTING','The item returns to you. The listing fee is not refunded.','CancelListing',{Id=l.Id,DogId=l.AssetKey})end,P.red);y+=47 end
   section(sc,'RECENT SALES',4,y,iw-8);y+=46
   local stats=s.Details and s.Details.HistoryId==l.AssetKey and s.Details or market and market.HistoryId==l.AssetKey and market
   if not stats then U.Button(sc,'LoadHistory','LOAD PRICE HISTORY',8,y,iw-16,37,function()c.Query({Kind='Item',DogId=l.AssetKey},function(v)s.Details=v end)end,P.blue);y+=45 end
   if stats then U.Text(sc,'24h median '..U.Fmt(stats.Median24h)..'\n7d median '..U.Fmt(stats.Median7d)..' · '..stats.Volume7d..' sales',8,y,iw-16,58,16,P.muted);y+=62
    for i,sale in ipairs(stats.RecentSales)do if i>5 then break end;U.Text(sc,U.Fmt(sale.Price)..' Cash · '..os.date('!%d %b',sale.At),8,y,iw-16,28,17);y+=31 end
    section(sc,'SIMILAR LISTINGS',4,y,iw-8);y+=46
    for _,other in ipairs(stats.Items)do if other.Id~=l.Id and other.Dog.ItemId==x.ItemId then local listing=other;U.Button(sc,'Similar',U.Weight(other.Dog.WeightKg)..' · '..U.Fmt(other.Price),8,y,iw-16,34,function()s.Listing=listing;c.Draw()end);y+=42 end end
   end
   U.Text(sc,'Discovery '..U.Odds(x.BaseDropChance)..'\nWeight '..U.Odds(x.WeightTierChance)..'\nMutation '..U.Odds(x.MutationChance)..'\nCombined 1 in '..string.format('%.7g',x.CombinedOdds)..'\nFinder '..x.OriginalFinderUserId,8,y,iw-16,115,15,P.muted)
  end
 elseif c.Page=='CreateListing'then
  if H<440 then root=U.Scroll(root,'CreateListingPage',0,0,W,H);H=760 end
  section(root,'LIST A DISCOVERY',0,0,W);U.Search(root,'ListingPrice','Price / opening bid',s.ListPrice,8,54,W*.46,function(v)s.ListPrice=v end)
  U.Cycle(root,'Duration','Duration '..tostring(s.Duration or 3600)..'s',{300,3600,86400},s.Duration or 3600,W*.5,54,W*.48,function(v)change('Duration',v)end)
  for i,mode in ipairs({'BuyNow','Auction'})do U.Button(root,mode,mode=='BuyNow'and 'CREATE BUY NOW'or 'CREATE AUCTION',8+(i-1)*W*.5,103,W*.48,44,function()
   local x=p.Items[s.SelectedItem];if not x then return end
   c.Confirm('LIST '..x.DisplayName,'Price '..tostring(s.ListPrice or '—')..' Cash. Non-refundable 1% listing fee and 5% sale tax.','List',{Kind='Item',Uid=x.ItemUid,Mode=mode,Price=tonumber(s.ListPrice),Duration=s.Duration or 3600})
  end,P.green)end
  local selected=p.Items[s.SelectedItem]
  local holder=U.Frame(root,'Selection',0,203,W,H-203);holder.BackgroundTransparency=1;local values={};for _,x in pairs(p.Items)do table.insert(values,x)end
  list(holder,'ListingSelectGrid',values,math.max(1,math.floor(W/185)),242,W,H-203,function(x)change('SelectedItem',x.ItemUid)end)
 elseif c.Page=='Records'then
  Screens.Records(c,section,info)
 end
end
function Screens.Records(c,section,info)
 -- One readable, scrollable record layout at every screen size.
 local U,p,s,root,W,H=c.U,c.Snapshot.Profile,c.State,c.Parent,c.W,c.H;local P=U.Colors;local stats=p.Stats
 local sc=U.Scroll(root,'RecordsPage',0,0,W,H);section(sc,'RECORDS',0,0,W-8)
 local cols=math.clamp(math.floor((W-8)/220),1,4);local cw=(W-18-(cols-1)*10)/cols;local deepest=1;for k in pairs(p.UnlockedLayers)do deepest=math.max(deepest,tonumber(k)or 1)end
 local summary={{'TOTAL FINDS',stats.TotalFinds},{'UNIQUE DISCOVERIES',U.Count(p.Collection)..' / '..U.Count(D)},{'TOTAL SELL VALUE',U.Fmt(stats.TotalSellValue)},{'SECRET FINDS',stats.SecretFinds},{'DEEPEST LAYER',Depth[tostring(deepest)].Name},{'TOTAL DIGS',stats.TotalDigs},{'LONGEST STREAK',stats.LongestStreak},{'BIGGEST SALE',U.Fmt(stats.BiggestSale)}}
 for i,v in ipairs(summary)do
  local card=U.Panel(sc,'RecordStat',((i-1)%cols)*(cw+10),50+math.floor((i-1)/cols)*94,cw,84)
  U.Text(card,v[1],12,5,cw-24,30,14,P.muted)
  local value=U.Text(card,tostring(v[2]),12,40,cw-24,32,24,P.text,true);value.TextWrapped=false;value.TextScaled=true
  U.New('UITextSizeConstraint',{MinTextSize=14,MaxTextSize=24},value)
 end
 local y=50+math.ceil(#summary/cols)*94;section(sc,'PERSONAL RECORDS',0,y,W-8);y+=48
 local records={{'HEAVIEST FIND',stats.Heaviest},{'MOST VALUABLE',stats.MostValuable},{'RAREST FIND',stats.Rarest}}
 local rc=c.Mobile and 1 or 3;local rw=(W-18-(rc-1)*10)/rc
 for i,v in ipairs(records)do local card=U.Panel(sc,'FeaturedRecord',((i-1)%rc)*(rw+10),y+math.floor((i-1)/rc)*248,rw,238,true);U.Text(card,v[1],14,9,rw-28,30,22,P.gold,true)
  if v[2]then V.Item(card,v[2],10,45,rw*.48,150);U.Text(card,v[2].DisplayName..'\n'..U.Weight(v[2].WeightKg)..'\n'..v[2].WeightTier..'\n1 in '..string.format('%.6g',v[2].CombinedOdds),rw*.51,50,rw*.45,148,17);else U.Center(card,'Your story starts with your next find.',15,66,rw-30,110,20,P.muted,true)end
 end;y+=math.ceil(3/rc)*248
 U.Text(sc,'Best session: '..stats.BestSession..' finds    •    Best day: '..(stats.BestDay and os.date('!%d %b %Y',stats.BestDay)or '—')..' ('..stats.BestDayCount..')',10,y,W-28,45,18,P.muted);y+=51
 section(sc,'DEPTH RECORDS',0,y,W-8);y+=47
 for i=1,5 do local d=stats.Depths[tostring(i)]or {};local card=U.Panel(sc,'DepthRecord',0,y,W-8,65);U.Text(card,Depth[tostring(i)].Name,12,4,W*.22,57,18,U.Tiers[i+3],true);U.Text(card,(d.Item and d.Item.DisplayName or '—')..'   '..U.Weight(d.BestWeight)..'   Value '..U.Fmt(d.BestValue)..'   Finds '..(d.Finds or 0),W*.25,4,W*.7,57,17);y+=73 end
 section(sc,'RECORD PROGRESSION',0,y,W-8);y+=48
 for _,n in ipairs({25,50,100,250,500,1000,2500})do local key=tostring(n);local achieved=stats.Milestones[key];local claimed=stats.Claims[key];local card=U.Panel(sc,'Milestone',0,y,W-8,65)
  U.Text(card,n..' FINDS · 10 Bones + title',12,4,W*.64,55,19,achieved and P.gold or P.muted,true)
  U.Button(card,'ClaimRecord',claimed and 'CLAIMED'or achieved and 'CLAIM'or 'LOCKED',W*.7,12,W*.27,39,achieved and not claimed and function()c.Send('RecordClaim',{Count=n})end or nil,P.green);y+=73
 end
 U.Text(sc,'Counters track activity since '..os.date('!%d %b %Y',stats.Since)..'. Existing collection and weight records are preserved.',10,y,W-28,53,15,P.muted);y+=62
 section(sc,'WEIGHT RECORDS',0,y,W-8);y+=48
 for id,record in pairs(p.PersonalRecords)do
  local g=c.Snapshot.GlobalRecords[id];local r=c.Snapshot.ServerRecords[id]
  local card=U.Panel(sc,'WeightRecord_'..id,8,y,W-24,132)
  U.Text(card,D[id].DisplayName,12,6,W-48,40,19,P.text,true)
  U.Text(card,'YOU  '..U.Weight(record.WeightKg)..'\nSERVER  '..U.Weight(r and r.WeightKg)..'\nGLOBAL  '..U.Weight(g and g.WeightKg),12,49,W-48,72,17,P.muted)
  y+=144
 end
end
function Screens.DesktopRecords(c,section)
 local U,p,W,H,root=c.U,c.Snapshot.Profile,c.W,c.H,c.Parent;local P=U.Colors;local s=p.Stats
 section(root,'RECORDS',0,0,W-8);local bh=H-124;local lw=math.floor(W*.23);local rw=math.floor(W*.29);local mw=W-lw-rw-24;local mx=lw+12;local rx=mx+mw+12
 local left=U.Panel(root,'RecordSummary',0,49,lw,bh,true);section(left,'RECORD SUMMARY',5,5,lw-10)
 local deepest=1;for k in pairs(p.UnlockedLayers)do deepest=math.max(deepest,tonumber(k)or 1)end
 local summary={{'Total finds',s.TotalFinds},{'Unique discoveries',U.Count(p.Collection)..' / '..U.Count(D)},{'Best weight tier',tiers[(s.BestTier or 0)+1]or '—'},{'Total sell value',U.Fmt(s.TotalSellValue)},{'Secret finds',s.SecretFinds},{'Deepest layer',Depth[tostring(deepest)].Name},{'Total digs',s.TotalDigs},{'Completed trades',s.CompletedTrades}}
 local sh=(bh-61)/#summary
 for i,v in ipairs(summary)do local y=51+(i-1)*sh;U.Text(left,v[1],12,y,lw*.55,sh,15,P.muted);local t=U.Text(left,tostring(v[2]),lw*.58,y,lw*.38,sh,18,P.gold,true);t.TextXAlignment=Enum.TextXAlignment.Right end
 local mid=U.Scroll(root,'PersonalRecords',mx,49,mw,bh);section(mid,'PERSONAL RECORDS',0,0,mw-8)
 local records={{'Heaviest find',s.Heaviest and U.Weight(s.Heaviest.WeightKg)or '—'},{'Most valuable find',s.MostValuable and U.Fmt(s.MostValuable.SellValue)or '—'},{'Rarest find',s.Rarest and '1 in '..string.format('%.5g',s.Rarest.CombinedOdds)or '—'},{'Longest dig streak',s.LongestStreak},{'Biggest sale',U.Fmt(s.BiggestSale)},{'Best session',s.BestSession},{'Best day',s.BestDay and os.date('!%d %b %Y',s.BestDay)or '—'},{'Finds on best day',s.BestDayCount},{'Collection progress',math.floor(U.Count(p.Collection)/U.Count(D)*100)..'%'}}
 local cw=(mw-28)/3
 for i,v in ipairs(records)do local card=U.Panel(mid,'PersonalRecord',((i-1)%3)*(cw+9),48+math.floor((i-1)/3)*77,cw,69);U.Text(card,v[1],8,5,cw-16,24,13,P.muted);U.Text(card,tostring(v[2]),8,29,cw-16,32,19,P.gold,true)end
 local y=285;section(mid,'DEPTH RECORDS',0,y,mw-8);y+=45
 for i=1,5 do local d=s.Depths[tostring(i)]or {};local row=U.Panel(mid,'DepthRecord',0,y,mw-8,44);U.Text(row,Depth[tostring(i)].Name,8,2,mw*.3,40,14,U.Tiers[i+3],true);U.Text(row,U.Weight(d.BestWeight)..'   •   '..U.Fmt(d.BestValue)..' Cash   •   '..(d.Finds or 0)..' finds',mw*.32,2,mw*.64,40,14);y+=50 end
 U.Text(mid,'Tracking since '..os.date('!%d %b %Y',s.Since)..'. Historical weight records remain below.',8,y,mw-24,44,14,P.muted);y+=51
 for id,r in pairs(p.PersonalRecords)do local global=c.Snapshot.GlobalRecords[id];local server=c.Snapshot.ServerRecords[id];U.Text(mid,D[id].DisplayName..'\nYou '..U.Weight(r.WeightKg)..' · Server '..U.Weight(server and server.WeightKg)..' · Global '..U.Weight(global and global.WeightKg),8,y,mw-24,57,14);y+=62 end
 local right=U.Panel(root,'FeaturedRecord',rx,49,rw,bh,true);section(right,'FEATURED RECORD',5,5,rw-10);local x=s.Rarest
 if x then U.Text(right,x.DisplayName:upper(),14,51,rw-28,38,24,P.gold,true);local ph=math.max(95,bh-241);V.Item(right,x,12,96,rw-24,ph);U.Text(right,U.Weight(x.WeightKg)..' · '..x.WeightTier..'\nValue '..U.Fmt(x.SellValue)..' Cash\nDiscovery 1 in '..string.format('%.6g',x.CombinedOdds)..'\n'..Depth[tostring(x.Depth)].Name..' · '..os.date('!%d %b %Y',x.FoundAt),14,ph+105,rw-28,125,18)
 else U.Center(right,'Your first record is waiting.',18,90,rw-36,120,24,P.muted,true)end
 local strip=U.Header(root,'RecordProgression',0,H-64,W-8,60);local sw=(W-170)/7;U.Text(strip,'MILESTONES',10,8,141,43,20,P.gold,true)
 for i,n in ipairs({25,50,100,250,500,1000,2500})do local key=tostring(n);local claimed=s.Claims[key];local reached=s.Milestones[key];U.Button(strip,'ClaimRecord'..n,claimed and '✓ '..n or tostring(n)..(reached and ' CLAIM'or ' FINDS'),154+(i-1)*sw,11,sw-7,38,reached and not claimed and function()c.Send('RecordClaim',{Count=n})end or nil,reached and P.green or P.panel)end
end
return Screens

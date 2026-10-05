local Rep=game:GetService('ReplicatedStorage');local Config=require(Rep.DogEconomy.Config)
local Definitions=require(Rep.DogEconomy.DogDefinitions);local Products=require(Rep.DogEconomy.ShopDefinitions)
local V=require(script.Parent.PreviewRenderer);local Marketplace=game:GetService('MarketplaceService');local Players=game:GetService('Players')
local dexShapes={};for _,def in pairs(Definitions)do if not def.MuseumExcluded and def.Index then dexShapes[def.Index]=def end end
local Screens={};local productInfo={};local productLoading={};local productRetry={}
local function loadProduct(c,parent,product)
 if type(product.Id)~='number'or product.Id<=0 then return'COMING SOON',nil end
 local info=productInfo[product.Key]
 if not info and not productLoading[product.Key]and os.clock()>=(productRetry[product.Key]or 0)then
  productLoading[product.Key]=true
  task.spawn(function()
   local ok,result=pcall(function()return Marketplace:GetProductInfoAsync(product.Id,product.Kind=='Pass'and Enum.InfoType.GamePass or Enum.InfoType.Product)end)
   productLoading[product.Key]=nil
   if ok then productInfo[product.Key]=result else productRetry[product.Key]=os.clock()+15 end
   if parent.Parent then c.Draw()end
  end)
 end
 if not info or type(info.PriceInRobux)~='number'or info.IsForSale==false then return 'ROBUX · PRICE UNAVAILABLE',nil end
 local text=require(Rep.PriceFormat).Robux(info.PriceInRobux)
 return text,function()
  local ok=pcall(function()if product.Kind=='Pass'then Marketplace:PromptGamePassPurchase(Players.LocalPlayer,product.Id)else Marketplace:PromptProductPurchase(Players.LocalPlayer,product.Id)end end)
  if not ok then c.State.ProductMessage='Purchase unavailable. Please try again.';c.Draw()end
 end
end
-- Catalog rank wins over legacy rarity labels saved on older dog instances.
local function dogRank(d)return (Definitions[d.DogId]or{}).Rank or table.find(Config.Rarities,d.Rarity)or 0 end
-- Short screens use one outer scroll instead of a tiny nested grid viewport.
local function expandGrid(grid)
 local layout=grid:FindFirstChildWhichIsA('UIGridLayout');if not layout then return end
 grid.ScrollingEnabled=false;grid.ScrollBarThickness=0
 local function resize()
  if not grid.Parent then return end
  local height=math.max(layout.CellSize.Y.Offset,layout.AbsoluteContentSize.Y+8)
  if grid.Size.Y.Offset~=height then grid.Size=UDim2.fromOffset(grid.Size.X.Offset,height)end
 end
 local connection=layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(resize)
 grid.Destroying:Connect(function()connection:Disconnect()end);resize();task.defer(resize)
end
function Screens.Build(c)
 if c.Page=='OfflineEarnings'then return require(script.Parent.OfflineEarningsScreen).Build(c)end
 if c.Page=="Cosmetics"then return require(script.Parent.PlotShopScreen).Build(c)end
 if c.Page=='Extras'then
  local U=c.U;local P=U.Colors;local sc=U.Scroll(c.Parent,'MoreServices',0,0,c.W,c.H)
  local world=Rep.WorldEvents.State
  local current=world:GetAttribute('EventId')or 'WORLD EVENTS'
  local phase=world:GetAttribute('State')or 'NORMAL'
  local remaining=math.max(0,math.ceil((world:GetAttribute('EndTimestamp')or workspace:GetServerTimeNow())-workspace:GetServerTimeNow()))
  U.Text(sc,tostring(current)..' · '..tostring(phase)..' · '..remaining..'s',12,4,c.W-24,48,21,P.gold,true)
  local entries={{'DOG-O-MATIC','RewardMachine'},{'DOG DETAILS / LOCK','Dogs'},{'COLLECTOR / BULK SALE / ORDINARY LOOT','Collector'},{'LAYERS / PRESTIGE','Layers'},{'MARKETPLACE','Marketplace'},{'RECORDS','Records'},{'EVENT COSMETIC SHOP','Events'},{'SUPPLIES','Supplies'},{'COSMETICS','Cosmetics'},{'SETTINGS / WORLD EVENT FX','Settings'},{'HELP / DISTRICT MAP','Help'}}
  for i,entry in ipairs(entries)do
   U.Button(sc,'Extra'..entry[2],entry[1],12,62+(i-1)*58,c.W-24,48,function()require(c.Gui.Modules.GUIIntegration).OpenScreen(entry[2])end,P.blue)
  end
  return
 end
 if c.Page=='DexEntry'then return require(script.Parent.DexEntryScreen).Build(c)end
 if c.Page=='Lab'then return require(script.Parent.LabScreen).Build(c)end
 if c.Page=='Storage'then return require(script.Parent.StorageScreen).Build(c)end
 if c.Page=='Collector'then return require(script.Parent.CollectorScreen).Build(c)end
 local U,p,s,root,W,H=c.U,c.Snapshot.Profile,c.State,c.Parent,c.W,c.H;local P=U.Colors
 local dexRewardCols=math.clamp(math.floor((W+8)/128),1,5)
 local dexGridY=141+math.ceil(5/dexRewardCols)*46+5
 local shortGridPage=c.Page=='Dogs'and H<360 or c.Page=='DogDex'and H<math.max(360,dexGridY+174)
 if shortGridPage then root=U.Scroll(root,c.Page..'Content',0,0,W,H)end
 local function show(page)return function()c.Show(page)end end
 local function change(k,v)s[k]=v;c.Draw()end
 local function section(parent,title,x,y,w)local b=U.Header(parent,'Section',x,y,w,38);U.Text(b,title,14,0,w-28,38,23,P.gold,true);return b end
 local function stat(parent,icon,title,value,x,y,w,h)
  local b=U.Panel(parent,'Stat'..title,x,y,w,h);U.Icon(b,icon,12,(h-40)/2,40,P.gold);U.Text(b,title,64,8,w-76,23,15,P.muted);U.Text(b,value,64,30,w-76,h-37,25,nil,true);return b
 end
 local dogs={};for _,d in pairs(p.Dogs)do table.insert(dogs,d)end;table.sort(dogs,function(a,b)return a.DogUid<b.DogUid end)
 local selected=p.Dogs[s.SelectedDog]or dogs[1];if selected and not s.SelectedDog then s.SelectedDog=selected.DogUid end
 local function dogCard(parent,d,w,h,fn)
  local card=U.Panel(parent,'DogCard',0,0,w,h,true);local color=U.Rarity[d.Rarity]or P.muted
  if selected and selected.DogUid==d.DogUid then U.Glow(card,P.gold)end
  V.Dog(card,d,6,9,w-12,h-138);U.Center(card,d.DisplayName,7,h-132,w-14,56,18,nil,true);U.Badge(card,d.Rarity:upper(),8,h-74,w-16,color)
  U.Text(card,(d.AssignedSlot~=''and 'Digging'or 'Storage')..' · Mastery '..d.Mastery..'\n'..d.Variant,10,h-45,w-20,41,14,P.muted)
  local hit=U.New('TextButton',{Name='SelectDog',Text='',BackgroundTransparency=1,Size=UDim2.fromScale(1,1)},card);hit.Activated:Connect(fn)
  return card
 end
 local function dogDetails(parent,d,w,h,flow)
  if not d then U.Center(parent,'Choose a dog from DOG LINE.',10,65,w-20,90,25,P.muted,true);return end
  local width=w-24;local sc=U.Scroll(parent,'DogDetailScroll',10,9,w-20,math.max(140,h-169))
  local heading=U.Header(sc,'SelectedDogName',0,0,width-12,62)
  U.Text(heading,d.DisplayName:upper(),10,5,width-32,52,24,P.text,true)
  U.Badge(sc,d.Rarity:upper(),8,69,width-28,U.Rarity[d.Rarity])
  local st=c.Snapshot.DogStats[d.DogUid]or {};local stacked=w<400
  local imageW=stacked and width-12 or width*.46;V.Dog(sc,d,5,110,imageW-10,228)
  local y=stacked and 350 or 110;local sx=stacked and 5 or imageW+4;local sw=width-sx-15
  for _,row in ipairs({{'VARIANT',d.Variant},{'ABILITY',U.AbilityLabel(d.Ability)},{'COOLDOWN',st.Cooldown and string.format('%.2fs + 4s',st.Cooldown)or '—'},{'LUCK',string.format('+%.1f%%',(st.Luck or 0)*100)},{'DIG LAYER',Config.Layers[p.CurrentLayer].Name},{'MASTERY',d.Mastery},{'JOB',U.DigSlotLabel(d.AssignedSlot)}})do local b=U.Panel(sc,'DogProperty',sx,y,sw,52);U.Text(b,row[1],7,1,sw-14,20,14,P.muted);U.Text(b,tostring(row[2]),7,21,sw-14,28,17,nil,true);y+=58 end
  local tags={d.Variant,'Ascension '..d.AscensionLevel};if d.Edition and d.Edition~=''then table.insert(tags,d.Edition)end;if d.SerialNumber then table.insert(tags,string.format('SERIAL #%06d',d.SerialNumber))end
  U.Text(sc,table.concat(tags,' · '),8,y,width-28,46,16,P.gold);y+=50
  local definition=Definitions[d.DogId]
  if definition and definition.Signature then U.Text(sc,definition.Signature,8,y,width-28,100,16,P.text);y+=108 end
  U.Button(sc,'DogLock',d.Locked and 'UNLOCK'or 'LOCK',5,y,width-23,42,function()c.Send('DogLock',{Uid=d.DogUid,Enabled=not d.Locked})end)
  if flow then sc.Size=UDim2.fromOffset(w-20,y+50);sc.ScrollingEnabled=false;sc.ScrollBarThickness=0 end
  local dock=U.Panel(parent,'DogActions',10,flow and y+70 or h-151,w-20,142);local dw=w-34
  U.Cycle(dock,'AssignSlot',U.DigSlotLabel(s.AssignSlot or 'DigSlot_1'),(function()local slots={};for i=1,require(Rep.PlotCatalog).Slots(p)do table.insert(slots,'DigSlot_'..i)end;return slots end)(),s.AssignSlot or 'DigSlot_1',7,7,dw,function(v)change('AssignSlot',v)end)
  U.Button(dock,'Assign','ASSIGN',7,50,(dw-8)/2,39,function()c.Send('Assign',{Uid=d.DogUid,Slot=s.AssignSlot or 'DigSlot_1'})end,P.green)
  U.Button(dock,'Remove','REMOVE',15+(dw-8)/2,50,(dw-8)/2,39,d.AssignedSlot~=''and function()c.Send('Remove',{Uid=d.DogUid})end or nil,P.red)
  U.Button(dock,'Favorite',d.Favorite and '★ FAVORITE'or '☆ FAVORITE',7,96,(dw-8)/2,38,function()c.Send('DogFavorite',{Uid=d.DogUid,Enabled=not d.Favorite})end,P.gold)
  U.Button(dock,'ViewInDex','VIEW IN DEX',15+(dw-8)/2,96,(dw-8)/2,38,function()s.DexFilter='Found';s.SelectedDex=d.DogId;c.Show('DogDex')end,P.blue)
 end
 if c.Page=='Yard'then
  local sc=U.Scroll(root,'YardContent',0,0,W,H);section(sc,'YARD OVERVIEW',0,0,W-8)
  local sideBySide=W>=720 and H>=400
  local y=48;local pw=sideBySide and math.floor(W*.4)or W-8;local ph=sideBySide and math.min(345,H*.47)or math.clamp(W*.48,190,245)
  local home=U.Panel(sc,'YardPreview',0,y,pw,ph,true);V.Place(home,'Yard',8,8,pw-16,ph-61);U.Icon(home,'Yard',14,ph-44,32,P.gold);U.Text(home,'YOUR YARD · HOME BASE',55,ph-45,pw-66,33,20,P.gold,true)
  local sx=sideBySide and pw+14 or 0;local sy=sideBySide and y or y+ph+12;local sw=sideBySide and W-pw-22 or W-8;local statCols=sw>=420 and 2 or 1;local cw=(sw-10*(statCols-1))/statCols;local active=0;for _,d in ipairs(dogs)do if d.AssignedSlot~=''then active+=1 end end
  local stats={{'Coins','Income / second',string.format('~%.2f',c.Snapshot.IncomeEstimate or 0)},{'Yard','Yard level',1+(p.Upgrades.Plot or 0)},{'Storage','Dog storage',#dogs..' / '..math.min(Config.MaxDogs,20+20*(p.Upgrades.DogStorage or 0))},{'Yard','Occupied kennels',active..' / '..require(Rep.PlotCatalog).Slots(p)}}
  for i,row in ipairs(stats)do stat(sc,row[1],row[2],row[3],sx+((i-1)%statCols)*(cw+10),sy+math.floor((i-1)/statCols)*98,cw,86)end
  local latestY=sy+math.ceil(#stats/statCols)*98
  local latest=p.DiscoveryFeed[1];local last=U.Panel(sc,'LatestFound',sx,latestY,sw,128)
  if latest then V.Item(last,latest,8,9,77,106);U.Text(last,'LATEST FOUND ITEM',96,9,sw-108,29,17,P.muted);U.Text(last,latest.DisplayName..' · '..U.Weight(latest.WeightKg),96,42,sw-108,77,19,P.text,true)
  else U.Text(last,'LATEST FOUND ITEM\nYour next discovery is waiting.',20,8,sw-40,110,21,P.muted,true)end
  y=math.max(y+ph,latestY+128)+15
  U.Button(sc,'OpenUpgrades','DOG TRAINING',0,y,(W-20)/2,45,show('DogTraining'),P.gold);U.Button(sc,'OpenLayers','DIGGING LAYERS',(W-20)/2+12,y,(W-20)/2,45,show('Layers'),P.blue);y+=57
  U.Button(sc,'OfflineEarnings','OFFLINE EARNINGS',0,y,W-8,45,show('OfflineEarnings'),P.gold);y+=57
  section(sc,'WORLD FEATURES',0,y,W-8);y+=48
  local features={{'DOG LINE','03_DogLine','Factory','Meet · choose · adopt'},{'LAB','05_MutationLab','Mutation lab','Mutate · ascend · evolve'},{'GLOBAL DIG','08_GlobalDigSite','Global dig site','A new adventure is on the way',true}}
  local cols=math.clamp(math.floor((W+12)/272),1,3);local fw=(W-18-(cols-1)*12)/cols
  for i,v in ipairs(features)do local card=U.Panel(sc,'Feature'..i,((i-1)%cols)*(fw+12),y+math.floor((i-1)/cols)*258,fw,246,true);U.Center(card,v[1],9,6,fw-18,33,23,P.text,true);V.Place(card,v[2],8,43,fw-16,112);U.Center(card,v[4],8,157,fw-16,34,16,P.muted);U.Button(card,'Go',v[5]and'COMING SOON'or'GO  ›',10,196,fw-20,42,not v[5]and function()c.Go(v[3])end or nil,P.green)end
 elseif c.Page=='Dogs'or c.Page=='DogDetail'then
  if c.Page=='DogDetail'then
   local flow=H<440;if flow then root=U.Scroll(root,'DogDetailPage',0,0,W,H)end
   dogDetails(root,selected,W,H,flow);return
  end
  local filters={'All','Working','Storage','Favorites'};local fw=(W-24)/4
  for i,f in ipairs(filters)do local b=U.Button(root,'Filter'..f,f,(i-1)*(fw+8),0,fw,47,function()change('DogFilter',f)end,s.DogFilter==f and P.blue or P.nav);if s.DogFilter==f then U.Glow(b,P.blue)end end
  local countW=W>=520 and 96 or 0;local sortW=math.min(154,math.floor(W*.4));local searchW=W-sortW-countW-(countW>0 and 24 or 12)
  U.Search(root,'DogSearch','Search dogs…',s.DogSearch,0,60,searchW,function(v)change('DogSearch',v)end)
  U.Cycle(root,'DogSort','Sort: '..(s.DogSort or 'Rarity'),{'Rarity','Mastery','Name'},s.DogSort or 'Rarity',searchW+12,60,sortW,function(v)change('DogSort',v)end)
  if countW>0 then U.Center(root,#dogs..' dogs',W-countW,60,countW,38,18,P.text,true)else U.Text(root,#dogs..' dogs',0,109,W-8,26,17,P.text,true)end
  local dogGridY=countW>0 and 115 or 143
  local filtered={};for _,d in ipairs(dogs)do local f=s.DogFilter;if(f=='All'or f=='Working'and d.AssignedSlot~=''or f=='Storage'and d.AssignedSlot==''or f=='Favorites'and d.Favorite)and(not s.DogSearch or d.DisplayName:lower():find(s.DogSearch:lower(),1,true))then table.insert(filtered,d)end end
  table.sort(filtered,function(a,b)if s.DogSort=='Mastery'and a.Mastery~=b.Mastery then return a.Mastery>b.Mastery elseif s.DogSort~='Name'and dogRank(a)~=dogRank(b)then return dogRank(a)>dogRank(b)end;return a.DisplayName==b.DisplayName and a.DogUid<b.DogUid or a.DisplayName<b.DisplayName end)
  local separateDetail=c.Mobile or shortGridPage or W<620;local dw=separateDetail and 0 or math.floor(W*.35);local lw=W-(dw>0 and dw+12 or 0);local grid,cw=U.Grid(root,'DogsGrid',0,dogGridY,lw,shortGridPage and 274 or H-dogGridY,math.max(1,math.floor(lw/185)),274)
  for i,d in ipairs(filtered)do local card=dogCard(grid,d,cw,274,function()s.SelectedDog=d.DogUid;if separateDetail then c.Show('DogDetail')else c.Draw()end end);card.LayoutOrder=i end
  if shortGridPage then expandGrid(grid)end
  if #filtered==0 then U.Center(root,'No dogs in this view.\nVisit DOG LINE to adopt your team.',16,dogGridY+32,lw-32,110,24,P.muted,true)end
  if dw>0 then local pane=U.Panel(root,'SelectedDog',lw+12,dogGridY,dw,H-dogGridY,true);dogDetails(pane,selected,dw,H-dogGridY)end
 elseif c.Page=='DogDex'then
  local total,bonusCount=0,0
  for id in pairs(p.DogDex)do local def=Definitions[id];if def then if def.MuseumExcluded then bonusCount+=1 else total+=1 end end end
  section(root,'DOG INDEX',0,0,W-8);U.Text(root,total..' / 100 · '..bonusCount..' BONUS',W*.41,0,W*.57,38,20,P.text,true);U.Bar(root,7,49,W-22,26,total/100,P.gold,total..'% MAIN COLLECTION')
  local fw=(W-24)/4;for i,f in ipairs({'All','Found','Missing','Favorites'})do U.Button(root,'DexFilter'..f,f,(i-1)*(fw+8),87,fw,42,function()change('DexFilter',f)end,s.DexFilter==f and P.blue or P.nav)end
  local bw=(W-8-(dexRewardCols-1)*8)/dexRewardCols;for i,n in ipairs({10,25,50,75,100})do local claimed=p.DexClaims[tostring(n)];U.Button(root,'DexReward'..n,claimed and '✓ '..n or n..' REWARD',((i-1)%dexRewardCols)*(bw+8),141+math.floor((i-1)/dexRewardCols)*46,bw,38,not claimed and total>=n and function()c.Send('DexClaim',{Count=n})end or nil,P.gold)end
  local grid,cw=U.Grid(root,'DogDexGrid',0,dexGridY,W,shortGridPage and 274 or H-dexGridY,math.max(1,math.floor(W/190)),274)
  local byIndex={};for id,d in pairs(c.Snapshot.Dex)do byIndex[d.Index]={Id=id,Definition=d}end
  for i=1,100 do local def=byIndex[i];local found=def~=nil;local favorite=def and p.DexFavorites[def.Id];local f=s.DexFilter
   if f=='All'or f=='Found'and found or f=='Missing'and not found or f=='Favorites'and favorite then
    local card=U.Panel(grid,'DexSlot'..i,0,0,cw,274,true);card.LayoutOrder=i;U.Button(card,'ViewEntry','VIEW',cw-82,146,74,38,function()s.SelectedDexIndex=i;s.SelectedDexBonus=nil;c.Show('DexEntry')end,P.blue);U.Text(card,string.format('#%03d',i),11,5,cw-22,30,19,P.gold,true)
    if found then V.Dog(card,def.Id,6,41,cw-12,139);U.Center(card,def.Definition.DisplayName,6,187,cw-12,48,18,nil,true);U.Badge(card,def.Definition.Rarity,10,239,cw-20,U.Rarity[def.Definition.Rarity]);U.Button(card,'DexFavorite',favorite and '★'or '☆',cw-38,5,29,29,function()c.Send('DexFavorite',{Id=def.Id,Enabled=not favorite})end,P.blue)
    else
     -- Still locked: a black silhouette of the dog that belongs in this slot.
     local shape=dexShapes[i]
     if shape then V.Dog(card,shape.Id,6,41,cw-12,139,true)else U.Icon(card,'Dogs',cw*.25,70,cw*.5,Color3.fromRGB(4,14,24));U.Center(card,'?',0,76,cw,70,52,P.muted,true)end
     U.Center(card,'LOCKED',0,184,cw,28,21,P.muted,true);U.Badge(card,'???',10,239,cw-20,Color3.fromRGB(59,76,90))
    end
   end
  end
  local bonus={};for id,def in pairs(Definitions)do if def.MuseumExcluded then table.insert(bonus,{Id=id,Definition=def})end end
  table.sort(bonus,function(a,b)return(a.Definition.Index or 0)<(b.Definition.Index or 0)end)
  for i,entry in ipairs(bonus)do
   local found=c.Snapshot.Dex[entry.Id]~=nil;local favorite=p.DexFavorites[entry.Id];local filter=s.DexFilter
   if filter=='All'or filter=='Found'and found or filter=='Missing'and not found or filter=='Favorites'and favorite then
    local card=U.Panel(grid,'BonusDex_'..entry.Id,0,0,cw,274,true);card.LayoutOrder=100+i;U.Stroke(card,P.gold,3)
    U.Text(card,'EXCLUSIVE BONUS',10,6,cw-20,29,17,P.text,true)
    V.Dog(card,entry.Id,6,40,cw-12,143)
    U.Center(card,entry.Definition.DisplayName,6,184,cw-12,38,22,P.text,true)
    U.Center(card,found and'DISCOVERED'or'FOUND IN DOG-O-MATIC',6,226,cw-12,28,14,P.muted,true)
    local hit=U.New('TextButton',{Name='OpenBonusEntry',Text='',BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=5},card)
    hit.Activated:Connect(function()s.SelectedDexBonus=entry.Id;c.Show('DexEntry')end)
   end
  end
  if shortGridPage then expandGrid(grid)end
 elseif c.Page=='Trade'then Screens.Trade(c,dogs,section)
 elseif c.Page=='Lab'then
  Screens.Lab(c,dogs,selected)
 elseif c.Page=='Upgrades'or c.Page=='DogTraining'then
  root=U.Scroll(root,'UpgradeDirections',0,0,W,H)
  U.Text(root,'Develop your estate at UPGRADES in Paw Market. Improve dogs, digging and storage at DOG TRAINING in your yard.',12,12,W-24,90,24,P.gold,true)
  U.Button(root,'OpenUpgradeService',c.Page=='DogTraining'and 'OPEN DOG TRAINING'or 'VIEW ESTATE UPGRADES',12,116,W-24,50,function()require(c.Gui.Modules.GUIIntegration).OpenService(c.Page)end,P.green)
  U.Button(root,'FindUpgradeShop','FIND UPGRADES AT PAW MARKET',12,178,W-24,46,function()require(c.Gui.Modules.GUIIntegration).Navigate('Shops')end,P.blue)

 elseif c.Page=='Events'then
  local events=U.Scroll(root,'ComingSoonContent',0,0,W,H);local card=U.Panel(events,'ComingSoon',12,12,W-24,414)
  U.Gradient(card,Color3.fromRGB(255,247,198),Color3.fromRGB(255,226,243))
  U.Icon(card,'Events',W/2-62,35,100,P.gold)
  local coming=U.Center(card,'COMING SOON',20,155,W-64,66,40,P.text,true);coming.TextWrapped=false;coming.TextScaled=true;U.New('UITextSizeConstraint',{MinTextSize=22,MaxTextSize=40},coming)
  U.Center(card,'A new global adventure is being built.',30,235,W-84,52,23,P.text)
  U.Center(card,'More surprises for the whole server.\nKeep growing your pack while we get it ready!',40,297,W-104,82,19,P.muted)
 elseif c.Page=='Feedback'then require(script.Parent.FeedbackScreen).Build(c)
 elseif c.Page=='Shop'then return require(script.Parent.CommerceShopScreen).Build(c)
 elseif c.Page=='Layers'then
  local sc=U.Scroll(root,'LayerContent',0,0,W,H);section(sc,'EXPLORE DEEPER',0,0,W-8)
  local narrow=W<450;local layerH=narrow and 180 or 148;local step=layerH+12
  for i,d in ipairs(Config.Layers)do
   local unlocked=p.UnlockedLayers[tostring(i)];local card=U.Panel(sc,'Layer'..i,0,49+(i-1)*step,W-8,layerH,true)
   U.Text(card,d.Name,15,8,W-40,34,24,P.text,true);U.Text(card,d.Depth,15,45,W-40,24,17,P.muted)
   U.Text(card,unlocked and 'Unlocked'or 'Level '..d.Level..' · '..U.Fmt(d.Cost)..' Cash'..(i==5 and ' · Prestige 1'or ''),15,76,narrow and W-40 or W*.65,narrow and 44 or 58,18,P.muted)
   U.Button(card,'ChooseLayer',p.CurrentLayer==i and 'DIGGING HERE'or unlocked and 'DIG HERE'or 'UNLOCK',narrow and 15 or W*.72,narrow and 128 or 96,narrow and W-40 or W*.25,40,p.CurrentLayer~=i and function()c.Send('Layer',{Layer=i})end or nil,P.green)
  end
  U.Button(sc,'Prestige','PRESTIGE',0,49+#Config.Layers*step+8,W-8,43,function()c.Confirm('PRESTIGE','Requires Level 25 and Cursed Depths. Costs '..U.Fmt(250000*(p.Prestige+1))..' Cash. Player level resets; dogs, unlocks and permanent upgrades remain.','Prestige',{})end,P.gold)
 elseif c.Page=='RewardMachine'then require(script.Parent.RewardScreens).RewardMachine(c)
 elseif c.Page=='TicketShop'then require(script.Parent.RewardScreens).TicketShop(c)
 elseif c.Page=='Loot'then
  local sc=U.Scroll(root,'LootContent',0,0,W,H);section(sc,'ORDINARY DIG LOOT',0,0,W-8);local total=0;for _,v in pairs(p.Loot)do total+=v.Value end
  U.Button(sc,'SellLoot','SELL LOOT · '..U.Fmt(total),8,54,W-24,45,total>0 and function()c.Send('SellLoot',{})end or nil,P.green)
  local y=112;for key,v in pairs(p.Loot)do local card=U.Panel(sc,'LootStack',0,y,W-8,80);U.Text(card,v.Name..' ×'..v.Count..' · '..U.Fmt(v.Value)..' Cash',14,8,W*.7,62,22);U.Button(card,'SellStack','SELL',W*.76,19,W*.2,40,function()c.Send('SellLoot',{Key=key})end,P.green);y+=90 end

 elseif c.Page=='Supplies'then return require(script.Parent.SuppliesScreen).Build(c)
 elseif c.Page=='Settings'then
  local settings=U.Scroll(root,'SettingsContent',0,0,W,H)
  U.Text(settings,'MAKE YOURSELF AT HOME',20,8,W-40,36,24,P.text,true)
  for i,k in ipairs({'Motion','Leaderboard','World Event FX'})do U.Button(settings,'Setting'..k,k,20,58+(i-1)*64,W-40,50,function()c.Options.setting(k)end,P.blue)end
  U.Button(settings,'ReplayTutorial','HOW TO PLAY',20,264,W-40,50,function()c.Close();require(script.Parent.OnboardingGuide).Replay()end,P.green)
  U.Text(settings,'Learn Lucky Blocks, kennels and selling.',20,323,W-40,48,18,P.muted)
 else
  local help=U.Scroll(root,'HelpContent',0,0,W,H)
  U.Center(help,'DOG LINE → YARD → DIG → DISCOVER\nManage your team in Dogs. Sell ordinary loot at the NPC shop.\nInventory holds your unique discoveries.',20,18,W-48,W<450 and 240 or 150,23,P.text,true)
  U.Button(help,'ShowMap','DISTRICT MAP',20,W<450 and 278 or 190,W-48,47,function()c.Options.openMap()end,P.blue)
 end
end

function Screens.Shop(c,parent,start,eventOnly)
 local U,p,W=c.U,c.Snapshot.Profile,c.W;local P=U.Colors;local list={};for _,product in ipairs(Products)do if not eventOnly or product.Event then table.insert(list,product)end end
 local mainW=(c.Mobile or eventOnly)and W-8 or math.floor(W*.69);local cols=c.Mobile and 1 or math.min(3,math.max(1,#list));local cw=(mainW-(cols-1)*12)/cols
 local function art(parent,product,x,y,w,h)
  -- Preview the existing collectible title badge; no dogs or currencies are sold by these products.
  local tone=product.Key=='VoidTrail'and U.Rarity.Epic or P.gold
  local plate=U.Panel(parent,'CosmeticPreview',x,y,w,h);U.Gradient(plate,P.navy,tone:Lerp(P.navy,.75));U.Icon(plate,product.Icon,w*.5-35,10,70,tone)
  local title=U.Header(plate,'TitleBadge',9,h-44,w-18,34);U.Center(title,product.Rewards.Cosmetic,4,0,w-26,34,14,tone,true)
 end
 for i,product in ipairs(list)do
  local card=U.Panel(parent,'Product'..product.Key,((i-1)%cols)*(cw+12),start+math.floor((i-1)/cols)*267,cw,255,true)
  U.Center(card,product.Name:upper(),12,7,cw-24,44,23,P.gold,true);art(card,product,9,59,cw-18,106);U.Center(card,product.Description,12,173,cw-24,37,15,P.muted)
  local label,action=loadProduct(c,parent,product)
  if not eventOnly and not c.Mobile then
   U.Button(card,'PreviewProduct','DETAILS  ›',9,218,cw-18,29,function()c.State.Product=product.Key;c.Draw()end,P.blue)
  else U.Button(card,'Purchase',label,9,215,cw-18,32,action,P.green)end
 end
 if not c.Mobile and not eventOnly then
  local product=list[1];for _,v in ipairs(list)do if v.Key==c.State.Product then product=v end end
  if product then local sideW=W-mainW-20;local side=U.Panel(parent,'ProductDetails',mainW+12,start-49,sideW,math.max(542,c.H-8),true)
   local title=U.Header(side,'ProductHeading',4,4,sideW-8,68);U.Center(title,product.Name:upper(),11,5,sideW-30,58,25,P.gold,true)
   art(side,product,12,86,sideW-24,210);U.Center(side,product.Description,16,313,sideW-32,75,22,P.text)
   U.Text(side,'INCLUDES\n'..product.Rewards.Cosmetic..'\nPermanent cosmetic unlock\nEquip it on your dog team.',17,409,sideW-34,113,18,P.muted)
   local label,action=loadProduct(c,parent,product);U.Button(side,'Purchase',label,12,math.max(542,c.H-8)-55,sideW-24,42,action,P.green)
  end
 end
 U.Text(parent,'Optional cosmetic support. Rewards are granted after Roblox confirms payment.',12,start+math.ceil(#list/cols)*267,mainW-24,50,16,P.muted)
end
function Screens.Trade(c,dogs,section)
 local U,p,s,W,H,root=c.U,c.Snapshot.Profile,c.State,c.W,c.H,c.Parent;local P=U.Colors;local trade=c.Snapshot.Trade
 if not trade then
  local short=H<360;if short then root=U.Scroll(root,'TradePlayersContent',0,0,W,H)end
  section(root,'SERVER PLAYERS · '..#c.Snapshot.Players,0,0,W-8);U.Search(root,'PlayerSearch','Search player name…',s.PlayerSearch,0,49,W-8,function(v)s.PlayerSearch=v;c.Draw()end)
  local compact=c.Mobile or short or W<620;local detailW=compact and 0 or math.floor(W*.33);local lw=W-(detailW>0 and detailW+12 or 0);local grid,cw=U.Grid(root,'ServerPlayers',0,103,lw,math.max(138,H-103),math.max(1,math.floor(lw/310)),148)
  for _,other in ipairs(c.Snapshot.Players)do if not s.PlayerSearch or other.Name:lower():find(s.PlayerSearch:lower(),1,true)then local card=U.Panel(grid,'Player'..other.Id,0,0,cw,148);V.Avatar(card,other.Id,8,10,77);U.Text(card,other.Name,96,6,cw-108,48,20,nil,true);U.Text(card,other.Status..' · Lv. '..other.Level,96,56,cw-108,34,17,P.muted);local select=U.New('TextButton',{Name='SelectPlayer',Text='',BackgroundTransparency=1,Size=UDim2.new(1,0,0,90)},card);select.Activated:Connect(function()s.TradePlayer=other;c.Draw()end);U.Button(card,'TradeRequest','TRADE',96,98,cw-108,42,function()s.TradePlayer=other;c.Send('TradeRequest',{Target=other.Id})end,P.blue)end end
  if short then expandGrid(grid)end
  if #c.Snapshot.Players==0 then U.Center(root,'No other players are ready in this server.',20,140,lw-40,100,25,P.muted,true)end
  if detailW>0 then local other=c.Snapshot.Players[1];for _,v in ipairs(c.Snapshot.Players)do if s.TradePlayer and v.Id==s.TradePlayer.Id then other=v end end;local outer=U.Panel(root,'PlayerDetails',lw+12,103,detailW,H-103,true);local panel=U.Scroll(outer,'PlayerDetailsContent',0,0,detailW,H-113);section(panel,'PLAYER DETAILS',6,6,detailW-12)
   if other then V.Avatar(panel,other.Id,detailW/2-66,57,132);U.Center(panel,other.Name..'\n@'..other.Username,12,205,detailW-24,65,23,P.gold,true);U.Center(panel,other.Status..' · Level '..other.Level..'\n'..other.Trades..' trades completed\n'..other.Listings..' active listings',16,288,detailW-32,109,20,P.muted);U.Button(panel,'RequestTrade','REQUEST TRADE',12,416,detailW-24,44,function()c.Send('TradeRequest',{Target=other.Id})end,P.green)
   else U.Center(panel,'Select a player to trade.',12,75,detailW-24,95,23,P.muted,true)end
  end;return
 end
 local sc=U.Scroll(root,'TradeSession',0,0,W,H);section(sc,'REVIEW BOTH OFFERS',0,0,W-8);local y=49
 for _,id in ipairs(trade.Users)do local offer=trade.Offers[tostring(id)];local card=U.Panel(sc,'Offer'..id,0,y,W-8,98);U.Text(card,'PLAYER '..id..' · '..U.Fmt(offer and offer.Cash or 0)..' Cash'..(trade.Ready[tostring(id)]and ' · READY'or '')..(trade.Confirmed[tostring(id)]and ' · CONFIRMED'or ''),14,8,W-36,37,23,P.gold,true)
  local names={};if offer then for _,x in pairs(offer.Details or {})do table.insert(names,x.DisplayName..(x.ItemUid and (' · '..U.Weight(x.WeightKg)..' · '..x.Mutation)or(' · '..x.Variant..' · Mastery '..x.Mastery)))end end;U.Text(card,table.concat(names,' / '),14,47,W-36,45,17);y+=111
 end
 if not trade.Accepted then U.Button(sc,'AcceptTrade','ACCEPT INVITATION',0,y,W-8,44,p.UserId~=trade.Inviter and function()c.Send('Trade',{Action='Accept'})end or nil,P.green);y+=55
 else
  U.Search(sc,'TradeCash','Cash to offer',s.TradeCash or '0',0,y,W-8,function(v)s.TradeCash=v end);y+=47
  local cols=c.Mobile and 1 or 3;local bw=(W-18-(cols-1)*10)/cols
  local actions={{'UPDATE OFFER',function()local ds,it={},{};for uid,on in pairs(s.TradeDogs)do if on then table.insert(ds,uid)end end;for uid,on in pairs(s.TradeItems)do if on then table.insert(it,uid)end end;c.Send('Trade',{Action='Offer',Dogs=ds,Items=it,Cash=tonumber(s.TradeCash)or 0})end},{'1. READY',function()c.Send('Trade',{Action='Ready',Version=trade.Version})end},{'2. FINAL CONFIRM',function()c.Send('Trade',{Action='Confirm',Version=trade.Version})end}}
  for i,a in ipairs(actions)do U.Button(sc,'TradeStep'..i,a[1],((i-1)%cols)*(bw+10),y+math.floor((i-1)/cols)*49,bw,41,a[2],i==3 and P.green or P.blue)end;y+=math.ceil(3/cols)*49
  U.Text(sc,'Any offer change resets both confirmations. Final confirm unlocks five seconds after both players are ready.',10,y,W-28,53,18,P.gold);y+=61
  section(sc,'YOUR ASSETS · SELECT THEN UPDATE OFFER',0,y,W-8);y+=47
  for _,d in ipairs(dogs)do local uid=d.DogUid;U.Button(sc,'OfferDog',s.TradeDogs[uid]and '✓ '..d.DisplayName or '+ '..d.DisplayName..' · '..d.Rarity..' · '..d.Variant,0,y,W-8,39,function()s.TradeDogs[uid]=not s.TradeDogs[uid];c.Draw()end,s.TradeDogs[uid]and P.gold or P.panel);y+=45 end
  for uid,x in pairs(p.Items)do local id=uid;U.Button(sc,'OfferItem',(s.TradeItems[id]and '✓ 'or '+ ')..x.DisplayName..' · '..U.Weight(x.WeightKg)..' · '..x.Mutation,0,y,W-8,39,function()s.TradeItems[id]=not s.TradeItems[id];c.Draw()end,s.TradeItems[id]and P.gold or P.panel);y+=45 end
 end
 U.Button(sc,'CancelTrade','CANCEL TRADE',0,y,W-8,45,function()c.Send('TradeCancel',{})end,P.red)
end
return Screens

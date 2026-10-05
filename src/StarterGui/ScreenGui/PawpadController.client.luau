-- Additive PAWPAD client. Existing shell, YardPage and server contracts are preserved.
local Players = game:GetService('Players')
local Replicated = game:GetService('ReplicatedStorage')
local DogRenderProfile = require(Replicated:WaitForChild('DogRenderProfile'))
local TweenService = game:GetService('TweenService')
local HttpService = game:GetService('HttpService')
local Input = game:GetService('UserInputService')
local player = Players.LocalPlayer
local gui = script.Parent
local Navigation=require(gui:WaitForChild('Modules'):WaitForChild('GUIIntegration'))
local Labels=require(gui.Modules.UITheme)

local main = gui:WaitForChild('MainWindow')
local pages = main.Content.PageContainer
local sidebar = main.Sidebar
local C = Color3.fromRGB
local colors = {green=C(70,220,85),blue=C(50,165,240),gold=C(255,190,30),purple=C(190,90,240),red=C(235,70,95),gray=C(159,188,213),dark=C(18,20,28)}
local rarityColors = {Common=C(170,190,205),Rare=colors.blue,Epic=colors.purple,Legendary=colors.gold,Mythic=colors.red,Secret=C(230,115,245),Uncommon=colors.green,['Brainrot God']=colors.red}
-- The lower action row must not cover Assign/Remove. Apply before hover
-- animation captures the buttons' resting sizes.
do
 local panel=pages.DogsPage.SelectedDogPanel
 panel.Favorite.Position=UDim2.fromScale(.05,.875);panel.Favorite.Size=UDim2.fromScale(.43,.085)
 panel.ViewInDex.Position=UDim2.fromScale(.52,.875);panel.ViewInDex.Size=UDim2.fromScale(.43,.085)
 for _,button in ipairs({panel.Favorite,panel.ViewInDex,panel.Assign,panel:WaitForChild('Remove'),panel.Slot})do
  button.TextScaled=true;button.TextWrapped=false
  local limit=button:FindFirstChildWhichIsA('UITextSizeConstraint')or Instance.new('UITextSizeConstraint',button)
  limit.MinTextSize=12;limit.MaxTextSize=18
 end
 panel.Stats.Size=UDim2.fromScale(.90,.19);panel.Stats.TextScaled=true;panel.Stats.TextWrapped=true;panel.Stats.TextYAlignment=Enum.TextYAlignment.Top
 local limit=panel.Stats:FindFirstChildWhichIsA('UITextSizeConstraint')or Instance.new('UITextSizeConstraint',panel.Stats)
 limit.MinTextSize=12;limit.MaxTextSize=16
end
local activePage = 'Yard'
local snapshot, config, definitions, items, products
local selectedDog, selectedPlayer, selectedItem
local slot = 1
local dogFilter, dexFilter, discoveryTab = 'All','All','Discoveries'
local dogQuery, playerQuery, itemQuery = '','',''
local itemFilter, sortMode = 'All','Rarity'
local refresh, renderDogs, renderDex, renderTrade, renderLab, renderEvents, renderDiscoveries
local function count(t) local n=0 for _ in pairs(t or {}) do n+=1 end return n end
local function status(message, pageName)
 local p=pages:FindFirstChild((pageName or activePage)..'Page')
 if p and p:FindFirstChild('Status') then p.Status.Text=tostring(message or '') end
end
local function animate(button)
 if not button:IsA('TextButton') or button:GetAttribute('PawpadAnimated') then return end
 button:SetAttribute('PawpadAnimated',true)
 local scale=button:FindFirstChildWhichIsA('UIScale') or Instance.new('UIScale')
 scale.Name='PawpadScale';scale.Parent=button
 local hovered,pressed=false,false
 local tween
 local function update()
  if tween then tween:Cancel() end
  tween=TweenService:Create(scale,TweenInfo.new(.09,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Scale=pressed and .96 or hovered and 1.03 or 1})
  tween:Play()
 end
 button.MouseEnter:Connect(function() hovered=true;update() end)
 button.MouseLeave:Connect(function() hovered=false;pressed=false;update() end)
 button.MouseButton1Down:Connect(function() pressed=true;update() end)
 button.MouseButton1Up:Connect(function() pressed=false;update() end)
 button.SelectionGained:Connect(function() hovered=true;update() end)
 button.SelectionLost:Connect(function() hovered=false;pressed=false;update() end)
end
local function bind(button, callback)
 animate(button)
 button.Activated:Connect(callback)
end
local function capture(button)
 local style={BackgroundColor3=button.BackgroundColor3,TextColor3=button.TextColor3,BackgroundTransparency=button.BackgroundTransparency}
 local s=button:FindFirstChildWhichIsA('UIStroke')
 if s then style.stroke={Color=s.Color,Thickness=s.Thickness,Transparency=s.Transparency,Enabled=s.Enabled} end
 local g=button:FindFirstChildWhichIsA('UIGradient')
 if g then style.gradient={Color=g.Color,Transparency=g.Transparency,Rotation=g.Rotation,Offset=g.Offset,Enabled=g.Enabled} end
 return style
end
local activeStyle,inactiveStyle=capture(sidebar.YardButton),capture(sidebar.DogsButton)
local function apply(button,style)
 for k,v in pairs(style) do if k~='stroke' and k~='gradient' then button[k]=v end end
 for _,spec in ipairs({{'UIStroke','stroke'},{'UIGradient','gradient'}}) do
  local object=button:FindFirstChildWhichIsA(spec[1])
  if object and style[spec[2]] then for k,v in pairs(style[spec[2]]) do object[k]=v end end
 end
end
local function switch(name)

 if main.Visible then gui:SetAttribute('OpenMenu',name)end
 if not pages:FindFirstChild(name..'Page') then return end
 local keyboard=pages:FindFirstChild('SearchKeyboard');if keyboard then keyboard.Visible=false end
 activePage=name
 for _,p in ipairs(pages:GetChildren()) do if p:IsA('GuiObject') and p.Name:match('Page$') then p.Visible=p.Name==name..'Page' end end
 for _,b in ipairs(sidebar:GetChildren()) do
  if b:IsA('TextButton') and b.Name:match('Button$') then require(gui.Modules.UITheme).SetNavState(b,b.Name==name..'Button' or name=='Discoveries' and b.Name=='DogDexButton') end
 end
 if snapshot then
  if name=='Dogs' then renderDogs() elseif name=='DogDex' then renderDex() elseif name=='Trade' then renderTrade() elseif name=='Lab' then renderLab() elseif name=='Events' then renderEvents() elseif name=='Discoveries' then renderDiscoveries() end
 end
 if refresh and name~='Yard' and name~='Inventory' then task.spawn(refresh) end
end
for _,name in ipairs({'Yard','Dogs','DogDex','Trade','Lab','Shop','Events'}) do
 local b=sidebar:FindFirstChild(name..'Button')
 if b then bind(b,function()
  Navigation.OpenPage(name)
 end)end
end
-- GLOBAL DIG reuses the existing Events page, matching Economy.World's GLOBAL DIG entry.
-- Keep navigation in this controller so activePage and Sidebar selection remain in sync.
bind(pages.YardPage.ActionButtons.GlobalDig.Main, function() Navigation.OpenPage('Events') end)
switch('Yard')
for _,p in ipairs(pages:GetChildren()) do if p.Name~='YardPage' and p.Name~='InventoryPage' then for _,o in ipairs(p:GetDescendants()) do if o:IsA('TextButton') then animate(o) end end end end

local requestBusy=false
local function call(action,args)
 local remote=Replicated:FindFirstChild('DogEconomyRequest')
 if not remote or not remote:IsA('RemoteFunction') then return false,'Game connection is unavailable.' end
 local ok,success,result=pcall(function() return remote:InvokeServer(action,args or {},action~='Snapshot' and action~='MarketQuery' and HttpService:GenerateGUID(false):gsub('%-','') or nil) end)
 if not ok then return false,'Could not reach the server. Please retry.' end
 return success,result
end
local function action(name,args)
 if requestBusy then return end
 requestBusy=true
 local originatingPage=activePage
 task.spawn(function()
  local ok,result=call(name,args)
  status(type(result)=='table' and result.Message or result,originatingPage)
  requestBusy=false
  if ok and type(result)=='table'and type(result.StateSnapshot)=='table'then
   snapshot=result.StateSnapshot
   if activePage=='Dogs' then renderDogs() elseif activePage=='DogDex' then renderDex() elseif activePage=='Trade' then renderTrade() elseif activePage=='Lab' then renderLab() elseif activePage=='Events' then renderEvents() elseif activePage=='Discoveries' then renderDiscoveries() end
  elseif ok and refresh then refresh() end
 end)
end
local function setTabs(holder,chosen)
 for _,b in ipairs(holder:GetChildren()) do if b:IsA('TextButton') then b.BackgroundColor3=b.Name==chosen and colors.blue or colors.gray end end
end
local function clearRows(scroller)
 for _,c in ipairs(scroller:GetChildren()) do if c:GetAttribute('PawpadRow') then c:Destroy() end end
end
local function newRow(scroller,template,key)
 local r=template:Clone();r.Name=key;r.Visible=true;r:SetAttribute('PawpadRow',true)
 for _,b in ipairs(r:GetDescendants()) do if b:IsA('TextButton') then b:SetAttribute('PawpadAnimated',nil) end end
 r.Parent=scroller;return r
end
local function showPreview(holder,id,isItem,silhouette)
 local previewKey=silhouette and id~=''and id..'#silhouette'or id
 if holder:GetAttribute('PreviewKey')==previewKey then return end
 holder:SetAttribute('PreviewKey',previewKey)
 local previous=holder:FindFirstChild('ModelPreview');if previous then previous:Destroy() end
 if holder:FindFirstChild('Caption') then holder.Caption.Visible=true end
 if not id or id=='' then return end
 local source
 if isItem then
  local folder=Replicated:FindFirstChild('DiscoveryModels');source=folder and folder:FindFirstChild(id)
 else
  -- DogTemplates is server-only in this place. Reuse an already replicated dog model if present.
  for _,folderName in ipairs({'DogTemplates','DogModels','DogPreviews'}) do
   local folder=Replicated:FindFirstChild(folderName);source=folder and folder:FindFirstChild(id)
   if source then break end
  end
  if not source then
   local models=Replicated:FindFirstChild('MenuModels');local def=definitions and definitions[id]
   source=models and models:FindFirstChild(def and def.VisualAsset or id)
  end
  if not source then
   for _,m in ipairs(workspace:GetDescendants()) do
    if m:IsA('Model') and (m.Name==id or m:GetAttribute('DogId')==id) and m:FindFirstChildWhichIsA('BasePart',true) then source=m;break end
   end
  end
 end
 if not source or not source:IsA('Model') or not source.Archivable then return end
 local model=source:Clone()
 if not isItem then DogRenderProfile.Apply(model,id)end
 for _,o in ipairs(model:GetDescendants()) do
  if o:IsA('LuaSourceContainer') or o:IsA('SurfaceGui') or o:IsA('BillboardGui') or o:IsA('ProximityPrompt') then o:Destroy()
  elseif silhouette and (o:IsA('SurfaceAppearance') or o:IsA('Decal') or o:IsA('Texture')) then o:Destroy()
  elseif o:IsA('BasePart') then o.Anchored=true;o.CanCollide=false;o.CanTouch=false;o.CanQuery=false;if silhouette and o:IsA('MeshPart') then o.TextureID='' end end
 end
 if not model:FindFirstChildWhichIsA('BasePart',true) then model:Destroy();return end
 local viewport=Instance.new('ViewportFrame');viewport.Name='ModelPreview';viewport.Size=UDim2.fromScale(1,1);viewport.BackgroundTransparency=1;viewport.ZIndex=5;viewport.Ambient=C(200,200,200);viewport.LightColor=C(255,255,245);viewport.Parent=holder
 if not isItem then DogRenderProfile.ApplyViewport(viewport)end
 -- Undiscovered dogs render as a solid black silhouette of their real model.
 if silhouette then viewport.ImageColor3=Color3.new(0,0,0)end
 model.Parent=viewport
 local cf,size=model:GetBoundingBox();local camera=Instance.new('Camera');camera.FieldOfView=38;camera.Parent=viewport
 local ratio=math.max(.35,holder.AbsoluteSize.X/math.max(1,holder.AbsoluteSize.Y))
 camera.CFrame=CFrame.lookAt(cf.Position+cf:VectorToWorldSpace(Vector3.new(1,.65,-1.3).Unit)*size.Magnitude*1.4/math.min(1,ratio),cf.Position)
 viewport.CurrentCamera=camera
 holder.Caption.Visible=false
end
local function dogDetail()
 local d=snapshot and snapshot.Profile.Dogs[selectedDog]
 local panel=pages.DogsPage.SelectedDogPanel
 for _,name in ipairs({'Favorite','Assign','Remove','Slot','ViewInDex'})do local action=panel:FindFirstChild(name);if action then action.Visible=d~=nil end end
 if not d then panel.DogName.Text='SELECT A DOG';panel.Rarity.Text='';panel.Stats.Text='Choose a dog from your collection.';showPreview(panel.Preview,'',false);return end
 panel.DogName.Text=d.DisplayName or d.DogId
 panel.Rarity.Text=d.Rarity or '';panel.Rarity.TextColor3=rarityColors[d.Rarity] or colors.gray
 local stats=(snapshot.DogStats or {})[selectedDog] or {}
 local definition=definitions[d.DogId]or{}
 panel.Stats.Text=string.format('%s · Mastery %s\n%s\nCooldown: %ss · %s',d.Variant or 'Normal',tostring(d.Mastery or 0),definition.Signature or Labels.AbilityLabel(d.Ability or definition.Ability),stats.Cooldown and string.format('%.1f',stats.Cooldown) or '--',Labels.DigSlotLabel(d.AssignedSlot))
 panel.Favorite.Text=d.Favorite and 'UNFAVORITE' or 'FAVORITE'
 showPreview(panel.Preview,d.DogId,false)
end
renderDogs=function()
 if not snapshot then return end
 local page=pages.DogsPage;local p=snapshot.Profile
 page.DogCount.Text=string.format('DOGS: %d / %d',count(p.Dogs),player:GetAttribute('DogCapacity') or 20)
 local list={}
 for uid,d in pairs(p.Dogs or {}) do
  local working=d.AssignedSlot and d.AssignedSlot~=''
  if (dogFilter=='All' or dogFilter=='Working' and working or dogFilter=='Storage' and not working or dogFilter=='Favorites' and d.Favorite) and (d.DisplayName or d.DogId):lower():find(dogQuery,1,true) then table.insert(list,{uid=uid,d=d}) end
 end
 table.sort(list,function(a,b)
  if sortMode=='Name' then return (a.d.DisplayName or '')<(b.d.DisplayName or '') end
  local ar=(definitions[a.d.DogId] or {}).Rank or 0;local br=(definitions[b.d.DogId] or {}).Rank or 0
  return ar==br and a.uid<b.uid or ar>br
 end)
 clearRows(page.DogGrid);page.DogGrid.Empty.Visible=#list==0
 for i,row in ipairs(list) do
  local c=newRow(page.DogGrid,page.DogGrid.DogCardTemplate,row.uid);c.LayoutOrder=i
  c.DogName.Text=row.d.DisplayName or row.d.DogId;c.Rarity.Text=row.d.Rarity or '';c.Rarity.TextColor3=rarityColors[row.d.Rarity] or colors.gray;c.Favorite.Text=row.d.Favorite and 'FAV' or ''
  c.Stats.Text=Labels.DigSlotLabel(row.d.AssignedSlot)..' · Mastery '..tostring(row.d.Mastery or 0)
  c.UIStroke.Color=row.uid==selectedDog and colors.gold or colors.dark;c.UIStroke.Thickness=row.uid==selectedDog and 4 or 3
  showPreview(c.Preview,row.d.DogId,false)
  bind(c.Select,function() selectedDog=row.uid;renderDogs() end)
 end
 if selectedDog and not p.Dogs[selectedDog] then selectedDog=nil end
 dogDetail()
end
local dp=pages.DogsPage
dp.SelectedDogPanel.Slot.Text=Labels.DigSlotLabel('DigSlot_'..slot)
for _,b in ipairs(dp.Tabs:GetChildren()) do if b:IsA('TextButton') then bind(b,function() dogFilter=b.Name;setTabs(dp.Tabs,b.Name);renderDogs() end) end end
bind(dp.Sort,function() sortMode=sortMode=='Rarity' and 'Name' or 'Rarity';dp.Sort.Text='SORT: '..sortMode:upper();renderDogs() end)
bind(dp.SelectedDogPanel.Slot,function() slot=slot%math.max(1,player:GetAttribute('UnlockedKennels')or 1)+1;dp.SelectedDogPanel.Slot.Text=Labels.DigSlotLabel('DigSlot_'..slot)end)
bind(dp.SelectedDogPanel.Assign,function() if selectedDog then action('Assign',{Uid=selectedDog,Slot='DigSlot_'..slot}) else status('Select a dog first.') end end)
bind(dp.SelectedDogPanel:FindFirstChild('Remove'),function() if selectedDog then action('Remove',{Uid=selectedDog}) else status('Select a dog first.') end end)
bind(dp.SelectedDogPanel.Favorite,function() local d=snapshot and snapshot.Profile.Dogs[selectedDog];if d then action('DogFavorite',{Uid=selectedDog,Enabled=not d.Favorite}) else status('Select a dog first.') end end)
bind(dp.SelectedDogPanel.ViewInDex,function() switch('DogDex') end)

renderDex=function()
 if not snapshot or not definitions then return end
 local page=pages.DogDexPage;local p=snapshot.Profile;local total,bonus=0,0
 for id in pairs(p.DogDex)do local def=definitions[id];if def then if def.MuseumExcluded then bonus+=1 else total+=1 end end end
 page.Progress.Text=string.format('MAIN COLLECTION  %d / 100  ·  BONUS  %d',total,bonus);page.ProgressBar.Fill.Size=UDim2.fromScale(math.clamp(total/100,0,1),1)
 for _,def in pairs(definitions) do
  local c=page.DexGrid:FindFirstChild('Dex'..def.Index)
  if not c and def.MuseumExcluded then
   local template=page.DexGrid:FindFirstChild('Dex1')
   if template then
    c=template:Clone();c.Name='Dex'..def.Index;c.LayoutOrder=def.Index;c.Parent=page.DexGrid
    for _,label in ipairs(c:GetDescendants())do if label:IsA('TextLabel')and(label.Name:lower():find('index',1,true)or label.Text:match('^#?0*1$'))then label.Text='BONUS'end end
    local old=c:FindFirstChild('OpenEntry');if old then old:Destroy()end
    local button=Instance.new('TextButton');button.Name='OpenEntry';button.Text='';button.BackgroundTransparency=1;button.Size=UDim2.fromScale(1,1);button.ZIndex=10;button.Parent=c
    local bonusId=def.Id;button.Activated:Connect(function()Navigation.OpenScreen('DexEntry',{SelectedDexBonus=bonusId})end)
   end
  end
  if c then
   local found=snapshot.Dex and snapshot.Dex[def.Id]~=nil
   c.Visible=dexFilter=='All' or dexFilter=='Found' and found or dexFilter=='Missing' and not found or dexFilter=='Favorites' and (p.DexFavorites or {})[def.Id]==true
   c.DogName.Text=(found or def.MuseumExcluded)and def.DisplayName or 'LOCKED';c.Rarity.Text=def.MuseumExcluded and(found and'BONUS · DISCOVERED'or'DOG-O-MATIC EXCLUSIVE')or found and def.Rarity or 'MISSING';c.Rarity.TextColor3=found and (rarityColors[def.Rarity] or colors.gray) or C(170,190,205)
   showPreview(c.Preview,def.Id,false,not found and not def.MuseumExcluded)
   if found and c.Preview.Caption.Visible then c.Preview.Caption.Text='DOG PREVIEW' else c.Preview.Caption.Text='?' end
  end
 end
 for _,n in ipairs({10,25,50,75,100}) do local b=page.Milestones['Milestone'..n];local claimed=(p.DexClaims or {})[tostring(n)];b.Text=tostring(n)..(claimed and ' DONE' or total>=n and ' CLAIM' or ' LOCKED');b.BackgroundColor3=claimed and colors.gold or total>=n and colors.green or colors.gray end
end
local dex=pages.DogDexPage
for _,b in ipairs(dex.Tabs:GetChildren()) do if b:IsA('TextButton') then bind(b,function() dexFilter=b.Name;setTabs(dex.Tabs,b.Name);renderDex() end) end end
for _,n in ipairs({10,25,50,75,100}) do bind(dex.Milestones['Milestone'..n],function() action('DexClaim',{Count=n}) end) end
bind(dex.Discoveries,function() switch('Discoveries') end)

renderTrade=function()
 if not snapshot then return end
 if snapshot.Trade and Navigation.Owner=='Page'and gui:GetAttribute('OpenMenu')=='Trade'then Navigation.OpenScreen('Trade');return end
 local page=pages.TradePage;local s=page.ServerPlayersPanel.Players
 clearRows(s);local rows=0;local selected
 for i,p in ipairs(snapshot.Players or {}) do
  if p.Id==selectedPlayer then selected=p end
  if (p.Username or p.Name):lower():find(playerQuery,1,true) then
   rows+=1;local c=newRow(s,s.PlayerCardTemplate,tostring(p.Id));c.LayoutOrder=i;c.Avatar.Caption.Text=(p.Username or p.Name):sub(1,1):upper();c.Username.Text='@'..(p.Username or p.Name);c.Stats.Text=p.Status..' · Level '..tostring(p.Level)
   bind(c.Trade,function() selectedPlayer=p.Id;renderTrade() end)
  end
 end
 s.Empty.Visible=rows==0;page.ServerPlayersPanel.Title.Text='SERVER PLAYERS · '..tostring(#(snapshot.Players or {}))
 local d=page.PlayerDetailsPanel
 d.Username.Text=selected and '@'..(selected.Username or selected.Name) or 'SELECT A PLAYER'
 d.Stats.Text=selected and string.format('%s\nLevel %s\nCompleted trades: %s\nListings: %s',selected.Status,tostring(selected.Level),tostring(selected.Trades),tostring(selected.Listings)) or 'Choose someone from the server to trade with.'
 d.TradeNotice.Text=snapshot.Trade and 'A trade invitation or session is active.' or ''
 if not selected then selectedPlayer=nil end
end
bind(pages.TradePage.PlayerDetailsPanel.RequestTrade,function() if selectedPlayer then action('TradeRequest',{Target=selectedPlayer}) else status('Select a player first.') end end)

renderLab=function()
 if not snapshot then return end
 local page=pages.LabPage;local dogs=snapshot.Profile.Dogs or {};local hasDog=count(dogs)>0
 page.EmptyState.Visible=not hasDog;page.LabWorkspace.Visible=hasDog
 if not hasDog then return end
 local d=dogs[selectedDog]
 local panel=page.LabWorkspace.SelectedDog
 panel.DogName.Text=d and (d.DisplayName or d.DogId) or 'SELECT A DOG'
 panel.Stats.Text=d and string.format('%s\n%s · Ascension %s',d.Rarity,d.Variant,tostring(d.AscensionLevel or 0)) or 'Choose a dog from the Dogs page.'
 showPreview(panel.Preview,d and d.DogId or '',false)
end
bind(pages.LabPage.EmptyState.GoToDogLine,function()
 local signal=gui:FindFirstChild('NavigateDistrict')
 if signal and signal:IsA('BindableEvent') then Navigation.Close();signal:Fire('Factory') else status('Follow the tongue to DOG LINE. Press M for the district map.') end
end)
local lab=pages.LabPage.LabWorkspace
bind(lab.SelectedDog.Choose,function() switch('Dogs') end)
bind(lab.Sections.Inventory.Action,function() switch('Dogs') end)
bind(lab.Sections.VariantReference.Action,function() status('Normal · Shiny · Golden · Corrupted · Glitched · Void') end)
for _,n in ipairs({'Mutation','Ascend','Retire'}) do bind(lab.Sections[n].Action,function() Navigation.OpenScreen('Lab') end) end

local selectedProduct
local function productDetail(product)
 selectedProduct=product
 local p=pages.ShopPage.SelectedProductPanel;p.ProductName.Text=product.Name:upper();p.Description.Text=product.Description
 p.Price.Text=product.Id>0 and 'Price available at checkout' or 'Currently unavailable'
 p.Purchase.Text=product.Id>0 and 'PURCHASE' or 'UNAVAILABLE'
end
bind(pages.ShopPage.SelectedProductPanel.Purchase,function()
 if not selectedProduct or selectedProduct.Id<=0 then status('This product is currently unavailable.');return end
 -- Only catalog IDs are used. Price and confirmation are handled by Roblox.
 local Marketplace=game:GetService('MarketplaceService')
 local ok=pcall(function() if selectedProduct.Kind=='Pass' then Marketplace:PromptGamePassPurchase(player,selectedProduct.Id) else Marketplace:PromptProductPurchase(player,selectedProduct.Id) end end)
 if not ok then status('Purchase prompt unavailable. Please retry.') end
end)

renderEvents=function()
 if not snapshot or not config then return end
 local p=pages.EventsPage;local profile=snapshot.Profile;local contribution=(profile.Event or {}).Contribution or 0;local total=snapshot.EventTotal or 0
 p.EventHeroPanel.Title.Text=string.upper(snapshot.Meta or 'WEEKLY')..' WEEK'
 p.EventHeroPanel.Description.Text='Dig with your dogs to contribute.'
 p.CommunityGoalPanel.Value.Text=string.format('%d / %d',total,config.EventGoal)
 p.CommunityGoalPanel.ProgressBar.Fill.Size=UDim2.fromScale(math.clamp(total/config.EventGoal,0,1),1)
 p.YourContributionCard.Value.Text=tostring(contribution);p.EventTokensCard.Value.Text=tostring(profile.EventTokens or 0)
 for i,goal in ipairs(config.EventMilestones) do
  local f=p.MilestonesPanel['Milestone'..i];local claimed=(((profile.Event or {}).Claims or {})[tostring(i)])
  local ready=total>=goal and contribution>=config.EventPersonal[i]
  f.Claim.Text=claimed and 'COMPLETED' or ready and 'CLAIM' or 'LOCKED';f.Claim.BackgroundColor3=claimed and colors.gold or ready and colors.green or colors.gray
  f.ProgressBar.Fill.Size=UDim2.fromScale(math.clamp(math.min(total/goal,contribution/config.EventPersonal[i]),0,1),1)
 end
end
for i=1,5 do bind(pages.EventsPage.MilestonesPanel['Milestone'..i].Claim,function() action('EventClaim',{Milestone=i}) end) end

local marketRows={}
local function itemDetail()
 local p=pages.DiscoveriesPage.SelectedItemPanel;local x=selectedItem
 p.ItemName.Text=x and (x.DisplayName or x.ItemId) or 'SELECT AN ITEM'
 if not x then p.Stats.Text='Choose a discovery to see its details.';showPreview(p.Preview,'',true);return end
 local def=items[x.ItemId] or {};local fields={}
 for _,f in ipairs({{'Class',x.Class or def.Class},{'Weight',x.WeightKg and string.format('%.4g kg',x.WeightKg)},{'Tier',x.WeightTier},{'Mutation',x.Mutation},{'Chance',x.CombinedOdds and '1 / '..tostring(x.CombinedOdds)},{'Depth',x.Depth or def.Depth}}) do if f[2]~=nil then table.insert(fields,f[1]..': '..tostring(f[2])) end end
 p.Stats.Text=table.concat(fields,'\n');p.Favorite.Text=x.Favorite and 'UNFAVORITE' or 'FAVORITE';p.Unlock.Visible=false
 showPreview(p.Preview,x.ItemId,true)
end
renderDiscoveries=function()
 if not snapshot or not items then return end
 local page=pages.DiscoveriesPage;local p=snapshot.Profile;local s=page.ItemGrid;clearRows(s)
 local list={}
 if discoveryTab=='Discoveries' then for _,x in pairs(p.Items or {}) do table.insert(list,x) end
 elseif discoveryTab=='Collection' then for id in pairs(p.Collection or {}) do local def=items[id];if def then table.insert(list,{ItemId=id,DisplayName=def.DisplayName,Class=def.Class,Depth=def.Depth}) end end
 elseif discoveryTab=='Marketplace' then for _,l in ipairs(marketRows) do local x=table.clone(l.Item or l.Dog or {});x.ListingPrice=l.Price;table.insert(list,x) end
 else for _,key in ipairs({'Heaviest','MostValuable','Rarest'}) do local x=(p.Stats or {})[key];if x then local row=table.clone(x);row.RecordType=key;table.insert(list,row) end end end
 table.sort(list,function(a,b) return (a.DisplayName or '')<(b.DisplayName or '') end)
 local shown=0
 for _,x in ipairs(list) do
  if (x.DisplayName or ''):lower():find(itemQuery,1,true) and (itemFilter=='All' or x.Class==itemFilter) then
   shown+=1;local c=newRow(s,s.ItemCardTemplate,'Item'..shown);c.LayoutOrder=shown;c.ItemName.Text=x.DisplayName or x.ItemId;c.Class.Text=x.Class or '';c.Stat.Text=x.ListingPrice and ('Cash '..x.ListingPrice) or x.RecordType or x.WeightKg and string.format('%.4g kg',x.WeightKg) or 'DISCOVERED'
   showPreview(c.Preview,x.ItemId,true);bind(c.Select,function() selectedItem=x;itemDetail() end)
  end
 end
 s.Empty.Visible=shown==0;s.Empty.Text=discoveryTab=='Marketplace' and 'No active item listings.' or discoveryTab=='Records' and 'Your first record is waiting.' or 'Your next discovery is waiting.'
 if selectedItem and selectedItem.ItemUid then selectedItem=(p.Items or {})[selectedItem.ItemUid] or (discoveryTab~='Discoveries' and selectedItem or nil) end
 itemDetail()
end
local disc=pages.DiscoveriesPage
for _,b in ipairs(disc.Tabs:GetChildren()) do if b:IsA('TextButton') then bind(b,function()
 if b.Name=='Marketplace'or b.Name=='Records'then Navigation.OpenScreen(b.Name);return end
 discoveryTab=b.Name;selectedItem=nil;setTabs(disc.Tabs,b.Name)
 if b.Name=='Marketplace' then task.spawn(function() local ok,result=call('MarketQuery',{Kind='Item',Page=1});if ok then marketRows=result.Items or {} else status(result,'Discoveries') end;renderDiscoveries() end) else renderDiscoveries() end
end) end end
bind(disc.BackToDex,function() switch('DogDex') end)
bind(disc.Filter,function()
 local classes={'All'};for _,def in pairs(items or {}) do if not table.find(classes,def.Class) then table.insert(classes,def.Class) end end
 table.sort(classes);local index=table.find(classes,itemFilter) or 1;itemFilter=classes[index%#classes+1];disc.Filter.Text='FILTER: '..itemFilter:upper();renderDiscoveries()
end)
bind(disc.SelectedItemPanel.Favorite,function() local x=selectedItem;if x and snapshot.Profile.Items[x.ItemUid] then action('ItemFavorite',{Uid=x.ItemUid,Enabled=not x.Favorite}) else status('Select an owned item.') end end)
disc.SelectedItemPanel.Unlock.Visible=false
bind(disc.SelectedItemPanel.Inspect,function() if selectedItem then itemDetail();status('Item details shown in the selected panel.') else status('Select an item first.') end end)
bind(disc.SelectedItemPanel.ListOnMarket,function()
 if selectedItem and selectedItem.ItemUid then Navigation.OpenScreen('CreateListing',{SelectedItem=selectedItem.ItemUid})else status('Select an owned item.')end
end)

-- Search uses only allowed TextButtons/Frames. A compact native keyboard also works on touch.
local searchTarget,searchValue,searchChanged
local searchPanel=Instance.new('Frame');searchPanel.Name='SearchKeyboard';searchPanel.BackgroundColor3=C(20,37,53);searchPanel.BorderSizePixel=0;searchPanel.Position=UDim2.fromScale(.12,.30);searchPanel.Size=UDim2.fromScale(.76,.47);searchPanel.ZIndex=30;searchPanel.Visible=false;searchPanel.Parent=pages
pages.YardPage.YardPreviewPanel.UICorner:Clone().Parent=searchPanel
pages.YardPage.YardPreviewPanel.UIStroke:Clone().Parent=searchPanel
local searchDisplay=pages.DogsPage.DogCount:Clone();searchDisplay.Name='Query';searchDisplay.Position=UDim2.fromScale(.04,.02);searchDisplay.Size=UDim2.fromScale(.92,.13);searchDisplay.ZIndex=31;searchDisplay.Parent=searchPanel
local function searchUpdate() searchDisplay.Text='SEARCH: '..searchValue;searchTarget.Text=searchValue~='' and 'SEARCH: '..searchValue or 'SEARCH';searchChanged(searchValue:lower()) end
local function searchKey(key)
 if key=='DONE' then searchPanel.Visible=false;searchTarget=nil;return elseif key=='CLEAR' then searchValue='' elseif key=='BACK' then searchValue=searchValue:sub(1,-2) elseif key=='SPACE' then searchValue=searchValue..' ' elseif #searchValue<40 then searchValue=searchValue..key end
 searchUpdate()
end
local keyboard={'Q','W','E','R','T','Y','U','I','O','P','A','S','D','F','G','H','J','K','L','BACK','Z','X','C','V','B','N','M','SPACE','CLEAR','DONE'}
for i,key in ipairs(keyboard) do local b=pages.DogsPage.Sort:Clone();b.Name=key;b:SetAttribute('PawpadAnimated',nil);b.Text=key;b.Position=UDim2.fromScale(.03+(i-1)%10*.095,.22+math.floor((i-1)/10)*.24);b.Size=UDim2.fromScale(.082,.17);b.ZIndex=32;b.Parent=searchPanel;b.TextLimit.MinTextSize=8;b.TextLimit.MaxTextSize=16;bind(b,function() searchKey(key) end) end
local function search(button,get,changed)
 bind(button,function() searchTarget=button;searchValue=get();searchChanged=changed;searchPanel.Visible=true;searchUpdate() end)
end
search(dp.Search,function() return dogQuery end,function(q) dogQuery=q;renderDogs() end)
search(pages.TradePage.ServerPlayersPanel.Search,function() return playerQuery end,function(q) playerQuery=q;renderTrade() end)
search(disc.Search,function() return itemQuery end,function(q) itemQuery=q;renderDiscoveries() end)
Input.InputBegan:Connect(function(input,processed)
 if processed or not searchTarget or not searchPanel.Visible or input.UserInputType~=Enum.UserInputType.Keyboard then return end
 local key=input.KeyCode.Name
 if #key==1 and key:match('%a') then searchKey(key) elseif key=='Backspace' then searchKey('BACK') elseif key=='Space' then searchKey('SPACE') elseif key=='Return' then searchKey('DONE') end
end)

-- Size repeated cards from the available column width; canvas grows with its layout.
for _,p in ipairs(pages:GetChildren()) do if p.Name~='YardPage' and p.Name~='InventoryPage' then
 for _,s in ipairs(p:GetDescendants()) do if s:IsA('ScrollingFrame') then
  local grid=s:FindFirstChildWhichIsA('UIGridLayout')
  if grid then
   local maxColumns=grid.FillDirectionMaxCells;local function sizeGrid()
    local width=math.max(1,s.AbsoluteSize.X/(main:FindFirstChildWhichIsA('UIScale').Scale)-24);local columns=math.max(1,math.min(maxColumns,math.floor((width+12)/145)))
    local cellWidth=math.floor((width-(columns-1)*12)/columns)
    grid.FillDirectionMaxCells=columns;grid.CellSize=UDim2.fromOffset(cellWidth,math.max(175,math.min(245,cellWidth*1.22)))
   end
   s:GetPropertyChangedSignal('AbsoluteSize'):Connect(sizeGrid);task.defer(sizeGrid)
  end
 end end
end end

task.spawn(function()
 local package=Replicated:WaitForChild('DogEconomy',15)
 if not package then status('Game data is unavailable.','Dogs');return end
 local ok,result=pcall(function() return {require(package.Config),require(package.DogDefinitions),require(package.ItemDefinitions),require(package.ShopDefinitions)} end)
 if not ok then status('Game data could not be loaded.','Dogs');return end
 config,definitions,items,products=table.unpack(result)
 for _,product in ipairs(products) do local c=pages.ShopPage.ProductGrid:FindFirstChild(product.Key);if c then c.ProductName.Text=product.Name:upper();c.Description.Text=product.Description;c.Price.Text=product.Id>0 and 'VIEW PRICE' or 'UNAVAILABLE';bind(c.Details,function() productDetail(product) end) end end
 if products[1] then productDetail(products[1]) end
 local refreshing=false;local lastRefresh=0
 refresh=function()
  if refreshing or os.clock()-lastRefresh<1 then return end
  if not player:GetAttribute('EconomyReady') then status('Your saved profile is loading.');return end
  refreshing=true;lastRefresh=os.clock()
  local success,data=call('Snapshot')
  if success and type(data)=='table' and data.Profile then
   snapshot=data
   if activePage=='Dogs' then renderDogs() elseif activePage=='DogDex' then renderDex() elseif activePage=='Trade' then renderTrade() elseif activePage=='Lab' then renderLab() elseif activePage=='Events' then renderEvents() elseif activePage=='Discoveries' then renderDiscoveries() end
  elseif not success then status(data) end
  refreshing=false
 end
 -- GUIIntegration owns DogEconomyOpen.
 while gui.Parent do
  if main.Visible and activePage~='Yard' and activePage~='Inventory' then refresh() end
  task.wait(8)
 end
end)
task.spawn(function()
 while gui.Parent do
  if snapshot and activePage=='Events' then
   local remaining=math.max(0,(snapshot.EventEnds or os.time())-os.time())
   pages.EventsPage.EventHeroPanel.Timer.Text=string.format('%dd %02dh %02dm %02ds',math.floor(remaining/86400),math.floor(remaining/3600)%24,math.floor(remaining/60)%60,remaining%60)
  end
  task.wait(1)
 end
end)
-- =========================================================
-- PAWPAD OPEN / CLOSE
-- =========================================================

local hud = gui:WaitForChild("HUD")
local backdrop = gui:WaitForChild("Backdrop")

local pawpadWidget = hud:WaitForChild("PawpadWidget")
local pawpadButton = pawpadWidget:WaitForChild("PawpadButton")

local closeButton = main
	:WaitForChild("Header")
	:WaitForChild("CloseButton")


local function openPawpad()Navigation.OpenPage('Yard')end
local function closePawpad()Navigation.Close()end
pawpadButton.Activated:Connect(function()
 if activePage=='Inventory'then switch('Yard')end
 openPawpad()
end)
hud.InventoryWidget.InventoryButton.Activated:Connect(function()Navigation.OpenPage('Inventory')end)
closeButton.Activated:Connect(closePawpad)
gui.MenuNavigation.Event:Connect(function(command,name)
 if command=='Close'then Navigation.Close()
 elseif command=='Service'and gui.ServiceMenus:FindFirstChild(name)then Navigation.ShowService(name)
 elseif command=='Page'then Navigation.OpenPage(name)
 end
end)
Navigation.RegisterSource(gui,switch)
-- Existing DogDex cards gain TARGET entry details, including locked exhibits.
for index=1,100 do
 local card=pages.DogDexPage.DexGrid:FindFirstChild('Dex'..index)
 if card then
  local button=Instance.new('TextButton');button.Name='ViewMuseumEntry';button.Text=''
  button.BackgroundTransparency=1;button.Size=UDim2.fromScale(1,1);button.ZIndex=10;button.Parent=card
  button.Activated:Connect(function()Navigation.OpenScreen('DexEntry',{SelectedDexIndex=index,SelectedDexBonus=false})end)
 end
end
-- Preserve target-only shop and settings access without adding a second HUD.
local function utility(parent,name,text,position,size,callback)
 local b=sidebar.ShopButton:Clone();b.Name=name;b.Text=text;b.Position=position;b.Size=size
 b.AnchorPoint=Vector2.zero;b.Visible=true;b.Parent=parent;b.TextSize=17;b.TextXAlignment=Enum.TextXAlignment.Center;local pad=b:FindFirstChildWhichIsA('UIPadding');if pad then pad:Destroy()end
 for _,child in ipairs(b:GetChildren())do if child:IsA('GuiObject')or child:IsA('UIAspectRatioConstraint')or child:IsA('UISizeConstraint')then child:Destroy()end end
 bind(b,callback);return b
end
-- Every HUD button opens one named window; settings are a separate HUD control.


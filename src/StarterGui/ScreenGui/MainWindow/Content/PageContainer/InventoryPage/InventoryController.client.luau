-- One view over the existing economy profile. All mutations are server requests.
local Players = game:GetService('Players')
local RS = game:GetService('ReplicatedStorage')
local Http = game:GetService('HttpService')
local player = Players.LocalPlayer
local page = script.Parent
local main = page.Parent.Parent.Parent
local gui = main.Parent
local Navigation=require(gui:WaitForChild('Modules'):WaitForChild('GUIIntegration'))

local browser = page.Browser
-- A short phone viewport may need more filter rows than fit below the toolbar.
-- Keep the existing controls and names, but make their panel scrollable.
if not browser.Filters:IsA('ScrollingFrame')then
 local old=browser.Filters;local scroller=Instance.new('ScrollingFrame')
 scroller.Name='Filters';scroller.Position=old.Position;scroller.Size=old.Size;scroller.Visible=old.Visible
 scroller.BackgroundColor3=old.BackgroundColor3;scroller.BackgroundTransparency=old.BackgroundTransparency;scroller.BorderSizePixel=0;scroller.ZIndex=old.ZIndex
 scroller.AutomaticCanvasSize=Enum.AutomaticSize.Y;scroller.CanvasSize=UDim2.new();scroller.ScrollBarThickness=5;scroller.ScrollingDirection=Enum.ScrollingDirection.Y;scroller.ClipsDescendants=true
 old.Name='PreviousFilters';scroller.Parent=browser
 for _,child in ipairs(old:GetChildren())do child.Parent=scroller end
 old:Destroy()
end
local grid = browser.GridPanel.Main.ItemGrid
local detail = page.Details.Main
local dialog = page.ConfirmModal.Dialog.Main
local hudCapacity = gui.HUD.InventoryWidget.InventoryButton.Capacity
local V = require(page.InventoryView)
local package = RS:WaitForChild('DogEconomy')
local definitions = require(package.ItemDefinitions)
local depths = require(package.DepthDefinitions)
local weights = require(package.WeightProfiles)
local mutations = require(package.MutationDefinitions)
local discoveryVisuals = require(package.DiscoveryVisuals)
local itemValue = require(RS:WaitForChild('ItemValuation'))
local blockConfig = require(RS:WaitForChild('LuckyBlockConfig'))
local lifecycle = require(RS:WaitForChild('LuckyLifecycleConfig'))
local blockVisuals = require(RS:WaitForChild('LuckyBlockVisuals'))
local economy = RS:WaitForChild('DogEconomyRequest')
local reward = RS:WaitForChild('RewardRequest')
local mode, order, query, favorites = 'Finds', 'NEWEST', '', false
local filters, snapshot, selectedKey = {}, nil, nil
local rows, cards, previews = {}, {}, {}
local alive, busy, refreshing, queued = true, false, false, false
local lastRequest = -math.huge
local connections = {}
local render, refresh, scheduleRefresh, updateDetails, layout
local modalOperation, pendingMutation
local color = Color3.fromRGB
local Theme=require(gui.Modules.UITheme)
local filtersExpanded=false
local filterToggle=Theme.Button(browser,'MoreFilters','FILTERS',0,0,124,40,function()filtersExpanded=not filtersExpanded;if layout then layout()end end,Theme.Colors.blue)
local originalDetails={}
for _,obj in ipairs({detail.Heading,detail.ItemName,detail.PreviewArea,detail.Facts,detail.Actions})do originalDetails[obj]={Position=obj.Position,Size=obj.Size}end
for _,obj in ipairs(detail.Actions:GetChildren())do if obj:IsA('Frame')then originalDetails[obj]={Position=obj.Position,Size=obj.Size}end end
local originalDialog={}
for _,obj in ipairs({dialog.Title,dialog.Description,dialog.Price,dialog.Confirm,dialog.Cancel})do originalDialog[obj]={Position=obj.Position,Size=obj.Size}end
local classColors = {Junk=color(164,188,208),Organic=color(101,210,115),Treasure=color(255,205,56),Artifact=color(186,115,255),Special=color(58,217,238),Secret=color(255,100,162)}
local function connect(signal, fn)
 local c = signal:Connect(fn)
 table.insert(connections, c)
 return c
end
local function shown() return alive and main.Visible and page.Visible end
local function message(value)
 return type(value) == 'table' and (value.Message or 'Updated') or tostring(value or '')
end
local toastVersion = 0
local function notify(value)
 local s = message(value)
 page.Status.Text = s
 toastVersion += 1
 local token = toastVersion
 gui.InventoryToast.Main.Message.Text = s
 gui.InventoryToast.Visible = s ~= '' and Navigation.Owner=='HUD'
 task.delay(5, function()
  if alive and token == toastVersion then gui.InventoryToast.Visible = false end
 end)
end
local function hud()
 local count, capacity = player:GetAttribute('ItemCount'), player:GetAttribute('ItemCapacity')
 if type(count) == 'number' and type(capacity) == 'number' then
  hudCapacity.Text = string.format('%d / %d', count, capacity)
  page.InventoryHeader.Capacity.Text = hudCapacity.Text
 end
end
for _, n in ipairs({'ItemCount', 'ItemCapacity'}) do connect(player:GetAttributeChangedSignal(n), hud) end
hud()

local function selected()
 for _, row in ipairs(rows) do if row.Key == selectedKey then return row end end
end
local function clearPreview(viewport)
 local entry = previews[viewport]
 if entry then
  entry.model:Destroy()
  entry.camera:Destroy()
  previews[viewport] = nil
 end
 viewport.CurrentCamera = nil
end
local function fit(viewport)
 local entry = previews[viewport]
 if not entry or viewport.AbsoluteSize.Y < 1 then return end
 local cf, size = entry.model:GetBoundingBox()
 local aspect = math.max(.2, viewport.AbsoluteSize.X / viewport.AbsoluteSize.Y)
 local halfAngle = math.min(math.rad(19), math.atan(math.tan(math.rad(19)) * aspect))
 entry.camera.CFrame = CFrame.lookAt(cf.Position + Vector3.new(1,.65,-1.3).Unit * size.Magnitude * .55 / math.sin(halfAngle), cf.Position)
end
local function preview(viewport, row, empty)
 local key = row and row.Key
 if not row or row.IsCollection and not row.Found then clearPreview(viewport);empty.Visible = true;return end
 if previews[viewport] and previews[viewport].key == key then fit(viewport);empty.Visible = false;return end
 clearPreview(viewport)
 local ok, model = pcall(function()
  if row.Block then return blockVisuals.Build(row.Block.Tier) end
  if row.IsCollection then
   local folder = RS:FindFirstChild('DiscoveryModels')
   local source = folder and folder:FindFirstChild(row.ItemId)
   return source and source:Clone()
  end
  return discoveryVisuals.Clone(row)
 end)
 if not ok or not model then empty.Visible = true;return end
 for _, object in ipairs(model:GetDescendants()) do
  if object:IsA('LuaSourceContainer') or object:IsA('ProximityPrompt') or object:IsA('LayerCollector')
   or object:IsA('Sound') or object:IsA('ParticleEmitter') or object:IsA('Light') then object:Destroy()
  elseif object:IsA('BasePart') then object.Anchored=true;object.CanCollide=false;object.CanTouch=false;object.CanQuery=false end
 end
 if not model:FindFirstChildWhichIsA('BasePart',true) then model:Destroy();empty.Visible=true;return end
 model.Parent = viewport
 local camera = Instance.new('Camera')
 camera.Name='PreviewCamera';camera.FieldOfView=38;camera.Parent=viewport;viewport.CurrentCamera=camera
 previews[viewport] = {key=key,model=model,camera=camera}
 empty.Visible = false
 fit(viewport)
end
local function blockInfo(b)
 if b.State=='Placed'or b.State=='Ready' then
  local seconds=V.Remaining(b,workspace:GetServerTimeNow())
  return seconds>0 and ('PREPARING  '..seconds..'s') or 'READY - OPEN AT YOUR PAD'
 end
 return string.upper(b.State)
end
-- Kept local to this page; card keys are the original ItemUid / block UID / ItemId.
local rowByKey = {}
-- Bind a stable row map for viewport virtualization.
local function viewportRows()
 if not shown() then return end
 local top, bottom = grid.AbsolutePosition.Y, grid.AbsolutePosition.Y + grid.AbsoluteSize.Y
 for key, card in pairs(cards) do
  if card.AbsolutePosition.Y + card.AbsoluteSize.Y >= top and card.AbsolutePosition.Y <= bottom then
   preview(card.Main.Preview,rowByKey[key],card.Main.Unknown)
  else clearPreview(card.Main.Preview) end
 end
 preview(detail.PreviewArea.Viewport,selected(),detail.PreviewArea.Empty)
end
local function setAction(name, visible, label)
 local holder=detail.Actions[name]
 holder.Visible=visible
 if label then holder.Button.Text=label end
end
updateDetails = function()
 local row=selected()
 for _,name in ipairs({'Favorite','Lock','Sell','Market'}) do setAction(name,false) end
 if not row then
  detail.ItemName.Text='SELECT A FIND'
  detail.Facts.Text.Text='Choose a card to inspect it.'
  preview(detail.PreviewArea.Viewport,nil,detail.PreviewArea.Empty)
  return
 end
 detail.ItemName.Text=row.DisplayName
 local fields={}
 if row.Block then
  local b=row.Block
  fields={'Tier: '..b.Tier,'State: '..blockInfo(b)}
  if b.State=='Placed'or b.State=='Ready' then table.insert(fields,'Lucky pad: '..tostring(b.Slot));table.insert(fields,'The timer keeps progress when you leave.')
  else table.insert(fields,'Visit a free Lucky pad in your own yard to choose and place this block.') end
  table.insert(fields,'Quantity: '..tostring(b.Quantity or 1))
  setAction('Favorite',true,(b.State=='Ready'or b.ReadyAt and b.ReadyAt<=os.time())and 'OPEN AT PAD'or (b.State=='Placed'and 'YOUR YARD'or 'PLACE'))
  setAction('Lock',true,'CHANCES')
 elseif row.IsCollection then
  table.insert(fields,row.Found and 'DISCOVERED' or 'Not discovered yet')
  table.insert(fields,'Depth: '..(depths[tostring(row.Depth)] or {}).Name)
  if row.Found then
   table.insert(fields,'Class: '..row.Class)
   if row.BaseDropChance and row.BaseDropChance>0 then table.insert(fields,'Base chance: 1 / '..V.Number(1/row.BaseDropChance)) end
   if row.Description and row.Description~='' then table.insert(fields,row.Description) end
  end
 else
  for _,f in ipairs({{'Class',row.Class},{'Weight',row.WeightKg and string.format('%.6g kg',row.WeightKg)},
   {'Weight tier',row.WeightTier},{'Mutation',row.Mutation},{'Depth',(depths[tostring(row.Depth)] or {}).Name},
   {'Chance',row.CombinedOdds and ('1 / '..V.Number(row.CombinedOdds))},{'Origin',row.Origin=='Roulette'and'DOG-O-MATIC'or row.Origin or row.EventTag},
   {'NPC value',row.SellValue and (require(RS.PriceFormat).Number(row.SellValue)..' Cash')}}) do
   if f[2] then table.insert(fields,f[1]..': '..tostring(f[2])) end
  end
  setAction('Favorite',true,row.Favorite and 'UNFAVORITE' or 'FAVORITE')
  setAction('Lock',false)
  setAction('Sell',row.Tradeable==true,'SELL TO MILO')
  setAction('Market',row.Tradeable==true,'LIST ON MARKET')
 end
 detail.Facts.Text.Text=table.concat(fields,'\n')
 if layout then layout()end
 viewportRows()
end

local depthOptions, classOptions, weightOptions, mutationOptions = {}, {}, {}, {}
local function unique(list,value) if not table.find(list,value)then table.insert(list,value)end end
for key in pairs(depths) do table.insert(depthOptions,tonumber(key)) end;table.sort(depthOptions)
for _,d in pairs(definitions)do unique(classOptions,d.Class)end;table.sort(classOptions)
for _,profile in pairs(weights)do for _,w in ipairs(profile)do unique(weightOptions,w.Name)end end
for _,m in ipairs(mutations)do unique(mutationOptions,m.Name)end
local function cycle(list,value)
 local index=value and table.find(list,value)or 0
 return list[(index or 0)+1]
end
layout=function()
 local scale=main:FindFirstChildWhichIsA('UIScale');local factor=scale and math.max(.01,scale.Scale)or 1
 local pageW=page.AbsoluteSize.X/factor;local pageH=page.AbsoluteSize.Y/factor
 local landscape=gui:GetAttribute('LandscapeMenus')==true
 page.ConfirmModal.Dialog.AnchorPoint=Vector2.new(.5,.5);page.ConfirmModal.Dialog.Position=UDim2.fromScale(.5,.5)
 local dialogH=landscape and math.max(160,math.min(390,pageH-12))or math.max(240,math.min(390,pageH-24))
 page.ConfirmModal.Dialog.Size=UDim2.fromOffset(math.max(260,math.min(600,pageW-24)),dialogH)
 dialog.Title.TextSize=landscape and 20 or 23;dialog.Description.TextSize=landscape and 16 or 18
 if landscape then
  dialog.Title.Position=UDim2.fromOffset(12,8);dialog.Title.Size=UDim2.new(1,-24,0,28)
  dialog.Description.Position=UDim2.fromOffset(12,42);dialog.Description.Size=UDim2.new(1,-24,0,math.max(28,dialogH-(dialog.Price.Visible and 132 or 92)))
  dialog.Price.Position=UDim2.new(0,12,1,-80);dialog.Price.Size=UDim2.new(1,-24,0,32)
  dialog.Cancel.Position=UDim2.new(0,12,1,-42);dialog.Cancel.Size=UDim2.new(.5,-18,0,36)
  dialog.Confirm.Position=UDim2.new(.5,6,1,-42);dialog.Confirm.Size=UDim2.new(.5,-18,0,36)
 else for obj,original in pairs(originalDialog)do obj.Position=original.Position;obj.Size=original.Size end end
 page.Status.Position=UDim2.new(0,12,1,-27);page.Status.Size=UDim2.new(1,-24,0,24);page.Status.Visible=page.Status.Text~=''
 if gui:GetAttribute('CompactMenus')then
  -- UITheme puts landscape header and tabs in one row, leaving content at Y=60.
  -- Keep that recovered height; the old portrait reserve consumed another 60px.
  local bottom=landscape and(page.Status.Visible and 100 or 72)or(page.Status.Visible and 160 or 132)
  browser.Size=UDim2.new(1,-24,1,-bottom);page.Details.Size=UDim2.new(1,-24,1,-bottom)
 end
 local bw=math.max(1,browser.AbsoluteSize.X/factor);local bh=math.max(1,browser.AbsoluteSize.Y/factor)
 local short=bh<330
 local stackedToolbar=short and not landscape and bw<430
 local names=mode=='Finds'and{'Depth','Class','Weight','Mutation','Sort'}or mode=='Collection'and{'Depth','Class','Sort'}or{'Class','Sort'}
 local columns=math.max(1,math.min(#names,math.floor(bw/155)));local filterRows=math.ceil(#names/columns)
 local f=browser.Filters
 local controlW=landscape and 106 or stackedToolbar and math.min(124,math.floor((bw-8)/2))or 124;local controlH=landscape and 32 or 42
 local controlsGap=landscape and 8 or 10
 filterToggle.Visible=short;filterToggle.Position=UDim2.new(1,-controlW,0,stackedToolbar and 50 or 0);filterToggle.Size=UDim2.fromOffset(controlW,landscape and 32 or 40);filterToggle.TextSize=landscape and 16 or 18
 browser.Search.Position=UDim2.fromOffset(0,0)
 local reserve=stackedToolbar and 0 or landscape and(mode=='Finds'and(controlW+controlsGap)*2 or controlW+controlsGap)or(short and(mode=='Finds'and 268 or 134)or mode=='Finds'and 148 or 0)
 browser.Search.Size=UDim2.new(1,-reserve,0,controlH);browser.Search.TextSize=landscape and 16 or 18
 browser.Favorites.Position=stackedToolbar and UDim2.fromOffset(0,50)or UDim2.new(1,-(landscape and controlW*2+controlsGap or short and 258 or 138),0,0);browser.Favorites.Size=UDim2.fromOffset(controlW,controlH)
 browser.Favorites.Button.TextSize=landscape and 16 or 18
 local filterTop=landscape and 38 or stackedToolbar and 99 or 49;local filterStride=landscape and 36 or 46
 f.Position=UDim2.fromOffset(0,filterTop);f.Size=UDim2.new(1,0,0,short and math.max(32,math.min(filterRows*filterStride,bh-filterTop-4))or filterRows*filterStride)
 f.Visible=not short or filtersExpanded;f.ZIndex=40;f.BackgroundTransparency=short and 0 or 1;f.BackgroundColor3=Theme.Colors.panel
 for i,name in ipairs(names)do
  local item=f[name];item.Position=UDim2.new(((i-1)%columns)/columns,0,0,math.floor((i-1)/columns)*filterStride);item.Size=UDim2.new(1/columns,-8,0,landscape and 32 or 40);item.ZIndex=41
  for _,child in ipairs(item:GetDescendants())do if child:IsA('GuiObject')then child.ZIndex=42 end end
  local button=item.Button;button.TextScaled=true;button.TextWrapped=true
  local constraint=button:FindFirstChildWhichIsA('UITextSizeConstraint')or Instance.new('UITextSizeConstraint',button);constraint.MinTextSize=14;constraint.MaxTextSize=18
 end
 local progressY=stackedToolbar and 99 or short and 49 or 53+filterRows*46
 browser.Progress.Visible=not landscape
 browser.Progress.Position=UDim2.fromOffset(4,progressY);browser.Progress.Size=UDim2.new(1,-8,0,30);browser.Progress.TextSize=17
 local gridTop=landscape and 40 or progressY+35
 browser.GridPanel.Position=UDim2.fromOffset(0,gridTop);browser.GridPanel.Size=UDim2.new(1,0,1,-gridTop)
 local width=math.max(1,bw-30);local cols=math.clamp(math.floor((width+12)/(short and 300 or 200)),1,4)
 local cell=math.floor((width-(cols-1)*12)/cols)
 grid.UIGridLayout.FillDirectionMaxCells=cols;grid.UIGridLayout.CellSize=UDim2.fromOffset(cell,landscape and 88 or short and 156 or 250)
 for _,card in pairs(cards)do
  local face=card.Main
  face.Preview.Position=landscape and UDim2.fromOffset(8,8)or short and UDim2.fromOffset(8,14)or UDim2.new(.06,0,.08,0)
  face.Preview.Size=landscape and UDim2.new(.35,-12,1,-16)or short and UDim2.new(.35,-12,1,-25)or UDim2.new(.88,0,.48,0)
  face.ItemName.Position=landscape and UDim2.new(.38,0,0,7)or short and UDim2.new(.38,0,0,15)or UDim2.new(.065,0,0,144)
  face.ItemName.Size=landscape and UDim2.new(.58,0,0,38)or short and UDim2.new(.58,0,0,65)or UDim2.new(.87,0,0,54);face.ItemName.TextSize=landscape and 16 or 18;face.ItemName.TextTruncate=Enum.TextTruncate.AtEnd
  face.ItemInfo.Position=landscape and UDim2.new(.38,0,0,48)or short and UDim2.new(.38,0,0,88)or UDim2.new(.065,0,0,204)
  face.ItemInfo.Size=landscape and UDim2.new(.58,0,0,32)or short and UDim2.new(.58,0,0,50)or UDim2.new(.87,0,0,36);face.ItemInfo.TextSize=landscape and 14 or 16
 end
 local empty=browser.GridPanel.Main.Empty;empty.Position=UDim2.fromOffset(12,12);empty.Size=UDim2.new(1,-24,1,-(short and 24 or 84));empty.TextSize=20
 local cta=browser.GridPanel.Main:FindFirstChild('CandyStart');if cta then cta.Visible=empty.Visible and not short;cta.Position=UDim2.new(.5,0,1,-60)end
 local dh=detail.AbsoluteSize.Y/factor
 if landscape then
  detail.Heading.Visible=false
  detail.ItemName.Position=UDim2.new(.33,0,0,4);detail.ItemName.Size=UDim2.new(.63,0,0,38);detail.ItemName.TextSize=18
  detail.PreviewArea.Position=UDim2.fromOffset(8,8);detail.PreviewArea.Size=UDim2.new(.29,0,1,-66)
  detail.Facts.Position=UDim2.new(.33,0,0,46);detail.Facts.Size=UDim2.new(.63,0,1,-100)
  detail.Facts.ScrollingEnabled=true;detail.Facts.ScrollBarThickness=5;detail.Facts.AutomaticCanvasSize=Enum.AutomaticSize.Y
  detail.Facts.Text.TextSize=16;detail.Facts.Text.AutomaticSize=Enum.AutomaticSize.Y
  detail.Actions.Position=UDim2.new(0,8,1,-48);detail.Actions.Size=UDim2.new(1,-16,0,40)
  local visible={};for _,name in ipairs({'Favorite','Lock','Sell','Market'})do if detail.Actions[name].Visible then table.insert(visible,detail.Actions[name])end end
  for i,holder in ipairs(visible)do holder.Position=UDim2.new((i-1)/#visible,0,0,0);holder.Size=UDim2.new(1/#visible,-8,1,0);holder.Button.TextSize=16 end
 elseif dh<330 then
  detail.Heading.Visible=false
  detail.ItemName.Position=UDim2.new(.35,0,0,5);detail.ItemName.Size=UDim2.new(.61,0,0,45);detail.ItemName.TextSize=21
  detail.PreviewArea.Position=UDim2.fromOffset(10,10);detail.PreviewArea.Size=UDim2.new(.31,0,1,-76)
  detail.Facts.Position=UDim2.new(.35,0,0,57);detail.Facts.Size=UDim2.new(.61,0,1,-121)
  detail.Actions.Position=UDim2.new(0,10,1,-56);detail.Actions.Size=UDim2.new(1,-20,0,46)
  local visible={};for _,name in ipairs({'Favorite','Lock','Sell','Market'})do if detail.Actions[name].Visible then table.insert(visible,detail.Actions[name])end end
  for i,holder in ipairs(visible)do holder.Position=UDim2.new((i-1)/#visible,0,0,0);holder.Size=UDim2.new(1/#visible,-8,1,0);holder.Button.TextSize=17 end
 else
  detail.Heading.Visible=true
  for obj,original in pairs(originalDetails)do obj.Position=original.Position;obj.Size=original.Size end
 end
 task.defer(viewportRows)
end
local function filterLabels()
 local f=browser.Filters
 f.Depth.Button.Text=filters.Depth and string.upper(depths[tostring(filters.Depth)].Name) or 'ALL DEPTHS'
 f.Class.Button.Text=filters.Class and string.upper(filters.Class) or (mode=='LuckyBlocks' and 'ALL TIERS' or 'ALL CLASSES')
 f.Weight.Button.Text=filters.Weight and string.upper(filters.Weight) or 'ALL WEIGHTS'
 f.Mutation.Button.Text=filters.Mutation or 'ALL MUTATIONS'
 f.Sort.Button.Text=order
 browser.Favorites.Visible=mode=='Finds'
 browser.Favorites.Button.Text=favorites and 'FAVORITES' or 'ALL FINDS'
 browser.Search.Size=UDim2.fromScale(mode=='Finds' and .725 or 1,.078)
 local names=mode=='Finds' and {'Depth','Class','Weight','Mutation','Sort'} or mode=='Collection' and {'Depth','Class','Sort'} or {'Class','Sort'}
 for _,n in ipairs({'Depth','Class','Weight','Mutation','Sort'})do f[n].Visible=false end
 for i,n in ipairs(names)do f[n].Visible=true;f[n].Position=UDim2.fromScale((i-1)/#names,0);f[n].Size=UDim2.new(1/#names,i==#names and 0 or -9,1,0)end
end
render = function()
 if not alive then return end
 filterLabels()
 for _,tab in ipairs(page.Tabs:GetChildren())do
  if tab:IsA('Frame')then tab.Button.BorderStroke.Color=tab.Name==mode and color(255,240,157)or color(18,20,28)end
 end
 if not snapshot then return end
 local profile=snapshot.Profile
 rows=V.Rows(profile,definitions,mode,filters,query,favorites,order)
 local total=V.Count(profile.Items)
 page.InventoryHeader.Capacity.Text=string.format('%d / %d',total,snapshot.ItemCapacity or player:GetAttribute('ItemCapacity')or 0)
 if mode=='Collection' then
  local found,possible=V.Progress(profile,definitions,filters.Depth)
  browser.Progress.Text=string.format('%s  %d / %d  ·  Unique discoveries',filters.Depth and depths[tostring(filters.Depth)].Name or 'FOUND',found,possible)
 elseif mode=='LuckyBlocks' then browser.Progress.Text=string.format('%d / %d LUCKY BLOCKS · OPEN AT YOUR YARD',V.BlockCount(profile),lifecycle.InventoryCapacity)
 else browser.Progress.Text=string.format('%d shown  /  %d owned finds',#rows,total)end
 local keep={};rowByKey={}
 for index,row in ipairs(rows)do
  local key=row.Key;keep[key]=true;rowByKey[key]=row
  local card=cards[key]
  if not card then
   card=grid.ItemCardTemplate:Clone();card.Name='Entry_'..key;card.Visible=true;card.Parent=grid;cards[key]=card
   card.Main.Activated:Connect(function()
    selectedKey=key
    for k,c in pairs(cards)do c.Main.BorderStroke.Color=k==key and color(255,214,69)or color(18,20,28)end
    updateDetails()
   end)
  end
  card.LayoutOrder=index
  card.Main.ItemName.Text=row.DisplayName
  card.Main.ItemInfo.Text=row.Block and blockInfo(row.Block)or row.IsCollection and (row.Found and row.Class or 'UNDISCOVERED')or string.format('%.4g kg  ·  %s',row.WeightKg,row.Mutation)
  card.Main.Badge.Text=row.Favorite and 'FAV' or ''
  local accent=row.Block and blockConfig.VisualConfig.Colors[blockConfig.Rank(row.Block.Tier)]or classColors[row.Class]or color(88,181,220)
  card.Main.RarityStrip.BackgroundColor3=row.IsCollection and not row.Found and color(80,105,126)or accent
  card.Main.BorderStroke.Color=key==selectedKey and color(255,214,69)or color(18,20,28)
 end
 for key,card in pairs(cards)do if not keep[key]then clearPreview(card.Main.Preview);card:Destroy();cards[key]=nil end end
 if not keep[selectedKey]then selectedKey=nil end
 browser.GridPanel.Main.Empty.Visible=#rows==0
 browser.GridPanel.Main.Empty.Text=mode=='LuckyBlocks' and 'No Lucky Blocks yet.\nPress E to buy one on the tongue.' or mode=='Collection' and 'No discoveries match these filters.' or (total==0 and 'Your next discovery is waiting.\nAssign a dog to a kennel to start digging.' or 'No finds match these filters.')
 updateDetails();layout()
end

refresh = function()
 queued=false
 if not shown() or refreshing or not player:GetAttribute('EconomyReady')then return end
 local remaining=1.5-(os.clock()-lastRequest)
 if remaining>0 then
  if not queued then queued=true;task.delay(remaining,refresh)end
  return
 end
 refreshing=true;lastRequest=os.clock()
 local ok,success,data=pcall(function()return economy:InvokeServer('Snapshot',{})end)
 refreshing=false
 if not alive then return end
 if ok and success and type(data)=='table'and type(data.Profile)=='table'then
  snapshot=data;render()
 else notify(ok and data or 'Inventory could not load. Please try again.')end
end
scheduleRefresh = function()
 if shown()and not queued then queued=true;task.defer(refresh)end
end
local function showModal(title,description,withPrice,callback)
 page.ConfirmModal.BackgroundTransparency=1 -- One global Backdrop supplies the dimming.
 dialog.Title.Text=title;dialog.Description.Text=description;dialog.Price.Visible=withPrice
 dialog.Price.Text='';dialog.Confirm.Button.Text='CONFIRM';modalOperation=callback
 page.ConfirmModal.Visible=true
 layout()
end
local function applyPatch(patch)
 if not snapshot or type(snapshot.Profile)~='table'or type(patch)~='table'then return false end
 local p=snapshot.Profile
 if type(patch.Cash)=='number'then p.Cash=patch.Cash end
 if type(patch.SoldUids)=='table'then for _,uid in ipairs(patch.SoldUids)do p.Items[uid]=nil end end
 if type(patch.Loot)=='table'then p.Loot=patch.Loot end
 return true
end
local function predictBulkSell(args)
 if not snapshot or type(snapshot.Profile)~='table'or type(args)~='table'or type(args.Uids)~='table'then return false end
 local p=snapshot.Profile;local total,count=0,0
 for _,uid in ipairs(args.Uids)do
  local item=p.Items and p.Items[uid]
  if item then total+=itemValue.Price(item);p.Items[uid]=nil;count+=1 end
 end
 if count<1 then return false end
 p.Cash=(p.Cash or 0)+total
 selectedKey=nil;render()
 return true
end
local function finishMutation(remote,action,args,request)
 if busy then return end
 busy=true
 local fastSale=remote==economy and action=='BulkSell'
 local predicted=fastSale and predictBulkSell(args)
 local ok,success,result=pcall(function()
  if remote==economy then return remote:InvokeServer(action,args,request)end
  return remote:InvokeServer(action,args)
 end)
 busy=false
 if not alive then return end
 local msg=message(result)
 local uncertain=not ok or (not success and (msg:find('Operation pending',1,true)or msg:find('Transaction pending',1,true)))
 if uncertain then
  if predicted then lastRequest=-math.huge;scheduleRefresh()end
  pendingMutation={remote,action,args,request}
  showModal('CHECK REQUEST','The response was interrupted. Retry the same request safely.',false,function()finishMutation(table.unpack(pendingMutation))end)
  dialog.Confirm.Button.Text='RETRY';return
 end
 pendingMutation=nil
 if success then page.ConfirmModal.Visible=false;modalOperation=nil end
 notify(result)
 if success and type(result)=='table'and type(result.StatePatch)=='table'and applyPatch(result.StatePatch)then
  render()
 elseif success and type(result)=='table'and type(result.StateSnapshot)=='table'then
  snapshot=result.StateSnapshot;render()
 else
  if predicted and not success then lastRequest=-math.huge end
  scheduleRefresh()
 end
end
local function mutate(remote,action,args)
 if busy then return end
 if pendingMutation then notify('Retry the pending request before starting another action.');return end
 local request=Http:GenerateGUID(false):gsub('%-','')
 if remote==reward then args.Request=request end
 finishMutation(remote,action,args,request)
end
local function ownedAction(fn)
 local row=selected()
 if row and not row.IsCollection and not busy then fn(row)end
end
connect(detail.Actions.Favorite.Button.Activated,function()ownedAction(function(row)
 if row.Block then Navigation.Navigate('Your yard')else mutate(economy,'ItemFavorite',{Uid=row.ItemUid,Enabled=not row.Favorite})end
end)end)
detail.Actions.Lock.Visible=false
connect(detail.Actions.Lock.Button.Activated,function()ownedAction(function(row)
 if row.Block then Navigation.OpenScreen('LuckyOdds',{LuckyOffer=false,BlockOddsUid=row.Block.Uid or false,BlockOddsTier=row.Block.Tier,BlockOddsPage=1,BlockCatalog=false,BlockCatalogFailed=false,BlockMessage=false})end
end)end)
connect(detail.Actions.Sell.Button.Activated,function()ownedAction(function(row)
 if row.Block or pendingMutation then return end
 mutate(economy,'BulkSell',{Uids={row.ItemUid}})
end)end)
connect(detail.Actions.Market.Button.Activated,function()ownedAction(function(row)
 if row.Block or pendingMutation then return end
 showModal('LIST ON MARKET',row.DisplayName..'\nBuy Now · 7 days · 1% listing fee\nThe buyer receives this exact find.',true,function()
  local price=tonumber(dialog.Price.Text)
  if not price or price~=price or price==math.huge or price%1~=0 or price<10 then notify('Enter a whole Cash price of at least 10.');return end
  mutate(economy,'List',{Kind='Item',Uid=row.ItemUid,Mode='BuyNow',Price=price})
 end)
end)end)
connect(dialog.Confirm.Button.Activated,function()if modalOperation and not busy then modalOperation()end end)
local function dismissConfirmation()
 if not page.ConfirmModal.Visible then return false end
 if pendingMutation or busy then Navigation.Close()
 else page.ConfirmModal.Visible=false;modalOperation=nil end
 return true
end
connect(dialog.Cancel.Button.Activated,dismissConfirmation)
Navigation.RegisterPageDialog(function()return shown()and dismissConfirmation()end)
for _,n in ipairs({'Finds','Collection','LuckyBlocks'})do connect(page.Tabs[n].Button.Activated,function()
 mode=n;selectedKey=nil;filters={};favorites=false;order=n=='Collection'and 'DEPTH'or 'NEWEST';grid.CanvasPosition=Vector2.zero
 if not pendingMutation then page.ConfirmModal.Visible=false end
 render();scheduleRefresh()
end)end
local searchToken=0
connect(browser.Search:GetPropertyChangedSignal('Text'),function()
 query=browser.Search.Text:sub(1,120);searchToken+=1;local token=searchToken
 task.delay(.15,function()if alive and token==searchToken then filtersExpanded=false;grid.CanvasPosition=Vector2.zero;render()end end)
end)
connect(browser.Favorites.Button.Activated,function()favorites=not favorites;grid.CanvasPosition=Vector2.zero;render()end)
for _,n in ipairs({'Depth','Class','Weight','Mutation','Sort'})do connect(browser.Filters[n].Button.Activated,function()
 if n=='Sort'then
  local options=mode=='Finds'and {'NEWEST','NAME','HEAVIEST','RAREST','DEPTH'}or mode=='Collection'and {'DEPTH','NAME'}or {'NEWEST','NAME'}
  order=cycle(options,order)or options[1]
 else
  local options=n=='Depth'and depthOptions or n=='Class'and (mode=='LuckyBlocks'and blockConfig.Rarities or classOptions)or n=='Weight'and weightOptions or mutationOptions
  filters[n]=cycle(options,filters[n])
 end
 filtersExpanded=false;grid.CanvasPosition=Vector2.zero;render()
end)end
connect(grid:GetPropertyChangedSignal('CanvasPosition'),viewportRows)
connect(grid:GetPropertyChangedSignal('AbsoluteSize'),layout)
connect(browser:GetPropertyChangedSignal('AbsoluteSize'),layout)
connect(detail:GetPropertyChangedSignal('AbsoluteSize'),layout)
connect(page.Status:GetPropertyChangedSignal('Text'),layout)
connect(gui:GetAttributeChangedSignal('LandscapeMenus'),function()task.defer(layout)end)
connect(grid.UIGridLayout:GetPropertyChangedSignal('AbsoluteContentSize'),function()task.defer(viewportRows)end)
connect(detail.PreviewArea.Viewport:GetPropertyChangedSignal('AbsoluteSize'),function()fit(detail.PreviewArea.Viewport)end)
local function visibility()
 gui.InventoryToast.Visible=false
 if shown()then render();scheduleRefresh()
 else
  if not pendingMutation then page.ConfirmModal.Visible=false end
  for vp in pairs(previews)do clearPreview(vp)end
 end
end
connect(page:GetPropertyChangedSignal('Visible'),visibility)
connect(main:GetPropertyChangedSignal('Visible'),visibility)
for _,n in ipairs({'InventoryRevision','EconomyReady','ItemCount','ItemCapacity','OwnedBlockCount','AvailableBlockCount'})do connect(player:GetAttributeChangedSignal(n),scheduleRefresh)end
connect(RS:WaitForChild('DiscoveryReveal').OnClientEvent,scheduleRefresh)
Navigation.RegisterInventory(function(data)
 if data.Message then notify(data.Message)end
 scheduleRefresh()
end)
-- Allow interaction with an empty own-yard pad even when Inventory is empty.
-- Server LuckyLifecycle still validates every trigger independently.
local function padPrompts()
 local district=workspace:FindFirstChild('DOGROTS_District')
 local yards=district and district:FindFirstChild('04_PlayerYards')
 if not yards then return end
 -- Prompt ownership is cosmetic; the server revalidates every request.
 for _,yard in ipairs(yards:GetChildren())do
  local own=yard:GetAttribute('OwnerUserId')==player.UserId and yard:GetAttribute('YardId')==player:GetAttribute('YardId')
  for slot=1,lifecycle.PlacementSlots do
   local pad=yard:FindFirstChild('LuckyPad_'..slot)
   local prompt=pad and pad:FindFirstChild('PlaceLuckyBlock')
   if prompt then prompt.Enabled=own and ((pad:GetAttribute('LuckyBlockUid')or '')==''or pad:GetAttribute('LuckyBlockReady')==true) end
  end
 end
end
task.spawn(function()
 while alive and gui.Parent do
  padPrompts()
  if shown()and mode=='LuckyBlocks'then
   for key,card in pairs(cards)do local row=rowByKey[key];if row and row.Block then card.Main.ItemInfo.Text=blockInfo(row.Block)end end
   if selected()then updateDetails()end
  end
  task.wait(.5)
 end
end)
task.spawn(function()while alive and gui.Parent do scheduleRefresh();task.wait(6)end end)
connect(script.Destroying,function()
 alive=false
 for _,c in ipairs(connections)do c:Disconnect()end
 for vp in pairs(previews)do clearPreview(vp)end
end)
filterLabels();layout();visibility()

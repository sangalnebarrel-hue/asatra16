local PlotCatalog=require(game.ReplicatedStorage.PlotCatalog)
local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local DogRenderProfile=require(RS:WaitForChild('DogRenderProfile'))
local Http=game:GetService('HttpService')
local player=Players.LocalPlayer
local gui=script.Parent
local Navigation=require(gui:WaitForChild('Modules'):WaitForChild('GUIIntegration'))
local Labels=require(gui.Modules.UITheme)

local root=gui:WaitForChild('ServiceMenus')
local navigation=gui:WaitForChild('MenuNavigation')
local U=require(root.ServiceUI)
local ui=U.Build(gui,root)
local economy=RS:WaitForChild('DogEconomyRequest')
local kennelRemote=RS:WaitForChild('DogKennelRequest')
local config=require(RS:WaitForChild('DogEconomy').Config)
local dogs=require(RS.DogEconomy.DogDefinitions)
local value=require(RS:WaitForChild('ItemValuation'))
local discoveries=require(RS.DogEconomy.DiscoveryVisuals)
local mode,snapshot,selected,kennelContext,quote
local busy,refreshing=false,false
local lastRefresh=-10
local pending,viewToken= nil,0
local gridCards,previews={},{}
local sellerSelection={}
local updateSeller
local render,refresh,selectRow,open
local format=require(game.ReplicatedStorage.PriceFormat).Number
local function message(x)return type(x)=='table' and (x.Message or 'Updated') or tostring(x or '') end
local toastRevision=0
local function status(x)
 ui.Status.Text=message(x)
 if ui.Status.Text~='' and not root.Visible and not gui.MainWindow.Visible then
  Navigation.Notify(ui.Status.Text)
 end
end
local function active()return root.Visible and mode~=nil end
local function call(action,args,id)
 return pcall(function()return economy:InvokeServer(action,args or {},id)end)
end
local function clearPreview(vp)
 local entry=previews[vp]
 if entry then entry.Model:Destroy();entry.Camera:Destroy();previews[vp]=nil end
 vp.CurrentCamera=nil
end
local function clearPreviews()
 for vp in pairs(previews)do clearPreview(vp)end
end
local function preview(vp,row,isDog)
 if previews[vp] then return end
 local ok,model=pcall(function()
  if not isDog then return discoveries.Clone(row) end
  local folder=RS:FindFirstChild('KennelDogPreviews');local source=folder and folder:FindFirstChild(row.DogId)
  if not source then local models=RS:FindFirstChild('MenuModels');local def=dogs[row.DogId];source=models and models:FindFirstChild(def and def.VisualAsset or row.DogId)end
  return source and source:Clone()
 end)
 local fallback=vp:FindFirstChild('Empty')
 if not ok or not model then if fallback then fallback.Visible=true;fallback.Text='Preview loading' end;return end
 if isDog then DogRenderProfile.Apply(model,row.DogId);DogRenderProfile.ApplyViewport(vp)end
 for _,o in ipairs(model:GetDescendants())do
  if o:IsA('LuaSourceContainer') or o:IsA('LayerCollector') or o:IsA('ProximityPrompt') or o:IsA('Sound') then o:Destroy()
  elseif o:IsA('BasePart') then o.Anchored=true;o.CanCollide=false;o.CanTouch=false;o.CanQuery=false end
 end
 if not model:FindFirstChildWhichIsA('BasePart',true) then model:Destroy();return end
 model.Parent=vp
 local cf,size=model:GetBoundingBox();local camera=Instance.new('Camera');camera.FieldOfView=38
 local ratio=math.max(.2,vp.AbsoluteSize.X/math.max(1,vp.AbsoluteSize.Y))
 local angle=math.min(math.rad(19),math.atan(math.tan(math.rad(19))*ratio))
 camera.CFrame=CFrame.lookAt(cf.Position+Vector3.new(1,.65,-1.3).Unit*size.Magnitude*.55/math.sin(angle),cf.Position)
 camera.Parent=vp;vp.CurrentCamera=camera;previews[vp]={Model=model,Camera=camera}
 if fallback then fallback.Visible=false end
end
local function visiblePreviews()
 if not active() or (mode~='Seller' and mode~='Kennels') then return end
 local g=ui[mode].Grid;local top,bottom=g.AbsolutePosition.Y,g.AbsolutePosition.Y+g.AbsoluteSize.Y
 for _,c in ipairs(gridCards)do
  if c.Frame.AbsolutePosition.Y+c.Frame.AbsoluteSize.Y>=top and c.Frame.AbsolutePosition.Y<=bottom then preview(c.Viewport,c.Row,mode=='Kennels') else clearPreview(c.Viewport) end
 end
end
-- A mutation retains its request ID if the response is lost, so retry cannot
-- charge, sell or assign twice. New inputs cannot replace an unresolved request.
local function mutate(action,args,kind)
 if busy then return end
 if pending and (pending.Action~=action or pending.Key~=(args.Uid or args.Kind or args.Layer or args.Token or action)) then status('Retry the previous action first.');return end
 local op=pending or {Action=action,Args=args,Kind=kind,Id=Http:GenerateGUID(false):gsub('-',''),Key=args.Uid or args.Kind or args.Layer or args.Token or action}
 pending=op;busy=true;status('Working...')
 local token=viewToken
 task.spawn(function()
  local transport,ok,result
  if op.Kind=='Kennel' then
   transport,ok,result=pcall(function()return economy:InvokeServer(op.Action,{Uid=op.Args.Uid,Slot=op.Args.Slot},op.Id)end)
  else transport,ok,result=call(op.Action,op.Args,op.Id) end
  busy=false
  local problem=message(result):lower()
  if not transport or(not ok and problem:find('pending',1,true))then status('Connection interrupted or request pending. Press the same action to retry safely.');return end
  pending=nil
  if ok and action=='BulkSell'then table.clear(sellerSelection);selected=nil end
  if token==viewToken then
   status(result)
   if ok then quote=nil;if action=='NPCSell' then selected=nil end end
   if ok and type(result)=='table'and type(result.StateSnapshot)=='table'then
    snapshot=result.StateSnapshot;if active()then render()end
   elseif active() then refresh(true) end
  end
 end)
end
local upgradeNames={Dig={'DIG SPEED','Shortens rest between work cycles.'},Storage={'LOOT STORAGE','More room for owned discoveries.'},Kennel={'KENNEL QUALITY','Improves the sale value of finds.'},Plot={'EXPAND YOUR YARD','Unlock kennels, paths, lights and a mega estate.'},DogStorage={'DOG CAPACITY','Store more dogs. Expand your yard to unlock kennels.'},Ability={'ABILITY POWER','Strengthens actual dog abilities.'}}
-- Estate development has its own panel in the physical shop.
local estateScroll=U.scroll(ui.Panels.Upgrades,'EstateScroll',UDim2.new(),UDim2.fromScale(1,1))
local hero,heroFace=U.card(estateScroll,'EstateDevelopment',UDim2.fromOffset(8,8),UDim2.new(1,-30,0,490))
local heroView=U.viewport(heroFace,'NextStagePreview',UDim2.fromScale(.018,.15),UDim2.fromScale(.48,.65))
local heroTitle=U.label(heroFace,'Title','EXPAND YOUR YARD',UDim2.fromScale(.025,.025),UDim2.fromScale(.95,.10),32)
heroTitle.TextColor3=U.accent
local heroStage=U.label(heroFace,'Stage','',UDim2.fromScale(.53,.16),UDim2.fromScale(.435,.11),22,true)
local heroDetail=U.label(heroFace,'Benefits','',UDim2.fromScale(.53,.30),UDim2.fromScale(.435,.25),21,true)
U.label(heroFace,'LocationHint','Estate development is available here at Paw Market. Dogs and digging: DOG TRAINING in your yard.',UDim2.fromScale(.53,.57),UDim2.fromScale(.435,.18),17,true)
local heroBuy=U.button(heroFace,'DevelopYard','',UDim2.fromScale(.53,.82),UDim2.fromScale(.435,.13))
U.label(heroFace,'PreviewCaption','NEXT YARD STAGE',UDim2.fromScale(.04,.85),UDim2.fromScale(.43,.08),19)
local estateOriginal={}
for _,obj in ipairs(heroFace:GetChildren())do if obj:IsA('GuiObject')then estateOriginal[obj]={Position=obj.Position,Size=obj.Size}end end
local function estateLayout()
 local narrow=estateScroll.AbsoluteSize.X<620
 hero.Size=UDim2.new(1,-30,0,narrow and 700 or 490)
 if not narrow then for obj,original in pairs(estateOriginal)do obj.Position=original.Position;obj.Size=original.Size end;return end
 heroTitle.Position=UDim2.fromOffset(12,12);heroTitle.Size=UDim2.new(1,-24,0,49)
 heroView.Position=UDim2.fromOffset(12,71);heroView.Size=UDim2.new(1,-24,0,210)
 heroFace.PreviewCaption.Position=UDim2.fromOffset(12,289);heroFace.PreviewCaption.Size=UDim2.new(1,-24,0,30)
 heroStage.Position=UDim2.fromOffset(12,330);heroStage.Size=UDim2.new(1,-24,0,56)
 heroDetail.Position=UDim2.fromOffset(12,398);heroDetail.Size=UDim2.new(1,-24,0,86)
 heroFace.LocationHint.Position=UDim2.fromOffset(12,496);heroFace.LocationHint.Size=UDim2.new(1,-24,0,103)
 heroBuy.Parent.Position=UDim2.fromOffset(12,622);heroBuy.Parent.Size=UDim2.new(1,-24,0,57)
end
estateScroll:GetPropertyChangedSignal('AbsoluteSize'):Connect(estateLayout);estateLayout()
local heroToken
local trainingView=false
heroBuy.Activated:Connect(function()if active()and mode=='Upgrades'and not trainingView then mutate('Upgrade',{Kind='Plot'})end end)
local function renderEstate(p)
 local level=PlotCatalog.Level(p);local nextLevel=math.min(9,level+1);local nextStage=PlotCatalog.Stages[nextLevel]
 local price=PlotCatalog.Cost(level)
 heroStage.Text='YARD '..level..' / 9  >  '..nextStage.Name
 heroDetail.Text=level>=9 and 'Your estate and trophy showcase are fully developed.'or nextStage.Feature..' Trophy showcase evolves with your yard.'
 heroBuy.Text=level>=9 and 'MAXIMUM ESTATE'or 'DEVELOP YARD  /  '..format(price)..' CASH'
 heroBuy.Active=level<9 and p.Cash>=price;heroBuy.AutoButtonColor=heroBuy.Active
 local token=nextLevel..':'..tostring(p.EquippedPlotSkin)
 if heroToken~=token then
  heroToken=token
  for _,o in ipairs(heroView:GetChildren())do if o:IsA('Model')or o:IsA('Camera')then o:Destroy()end end
  local yards=workspace.DOGROTS_District['04_PlayerYards'];local source
  for _,y in ipairs(yards:GetChildren())do if y:GetAttribute('OwnerUserId')==player.UserId then source=y;break end end
  if source then
   local A=require(RS.PlotAppearance);local model=A.Preview(source,nextLevel,p.EquippedPlotSkin or 'Classic');model.Parent=heroView
   local empty=heroView:FindFirstChild('Empty');if empty then empty.Visible=false end
   local f=A.Frame(model);local camera=Instance.new('Camera');camera.FieldOfView=38
   camera.CFrame=CFrame.lookAt(f:PointToWorldSpace(Vector3.new(72,120,145)),f:PointToWorldSpace(Vector3.new(0,5,0)))
   camera.Parent=heroView;heroView.CurrentCamera=camera
  end
 end
end

local upgradeCards={}
local function effect(kind,level,current)
 local e=config.UpgradeEffects[kind]
 if kind=='Storage' then return format((player:GetAttribute('ItemCapacity')or 50)+(level-current)*e)..' item slots' end
 if kind=='DogStorage' then return format(math.min(config.MaxDogs,(player:GetAttribute('DogCapacity') or 20)+(level-current)*e))..' dogs' end
 if kind=='Plot'then local stage=PlotCatalog.Stages[math.min(level+1,9)];return stage.Name..' / '..stage.Slots..' kennels'end
 local suffix=kind=='Dig' and 'work speed' or kind=='Kennel' and 'find value' or 'ability strength'
 return '+'..string.format('%g',level*e*100)..'% '..suffix
end
for index,kind in ipairs({'Dig','Storage','Kennel','DogStorage','Ability'})do
 local holder,face=U.card(ui.UpgradeGrid,kind,UDim2.new(),UDim2.fromOffset(300,240));holder.LayoutOrder=index
 local name=U.label(face,'Name',upgradeNames[kind][1],UDim2.fromScale(.055,.045),UDim2.fromScale(.89,.12),27)
 name.TextColor3=U.accent
 local level=U.label(face,'Level','',UDim2.fromScale(.055,.19),UDim2.fromScale(.89,.095),20)
 U.label(face,'Description',upgradeNames[kind][2],UDim2.fromScale(.055,.30),UDim2.fromScale(.89,.18),18,true)
 local current=U.label(face,'Current','',UDim2.fromScale(.055,.50),UDim2.fromScale(.89,.09),18,true)
 local nextEffect=U.label(face,'Next','',UDim2.fromScale(.055,.605),UDim2.fromScale(.89,.09),18,true)
 local track=Instance.new('Frame');track.Name='Progress';track.BackgroundColor3=gui.MainWindow.Content.BackgroundColor3;track.BorderSizePixel=0;track.Position=UDim2.fromScale(.055,.73);track.Size=UDim2.fromScale(.89,.04);track.Parent=face
 local fill=Instance.new('Frame');fill.Name='Fill';fill.BorderSizePixel=0;fill.BackgroundColor3=gui.MainWindow.Content.PageContainer.YardPage.StatsGrid.IncomeCard.Accent.BackgroundColor3;fill.Size=UDim2.fromScale(0,1);fill.Parent=track
 local buy=U.button(face,'Purchase','',UDim2.fromScale(.055,.83),UDim2.fromScale(.89,.12))
 upgradeCards[kind]={Holder=holder,Level=level,Current=current,Next=nextEffect,Fill=fill,Buy=buy}
 buy.Activated:Connect(function()if active() and mode=='Upgrades' then mutate('Upgrade',{Kind=kind}) end end)
end
local layerCards={}
for index,def in ipairs(config.Layers)do
 local holder,face=U.card(ui.LayerList,'Layer'..index,UDim2.new(),UDim2.new(1,-22,0,110));holder.LayoutOrder=index
 local title=U.label(face,'Title',string.upper(def.Name)..' · '..def.Depth,UDim2.fromScale(.035,.10),UDim2.fromScale(.60,.27),28)
 title.TextColor3=U.accent
 local requirements=U.label(face,'Requirements','',UDim2.fromScale(.035,.44),UDim2.fromScale(.59,.39),19,true)
 local action=U.button(face,'Action','',UDim2.fromScale(.69,.28),UDim2.fromScale(.275,.44),'DiggingLayers')
 layerCards[index]={Requirements=requirements,Action=action}
 action.Activated:Connect(function()if active() and mode=='Layers' then mutate('Layer',{Layer=index}) end end)
end
local function clearGrid()
 clearPreviews()
 for _,c in ipairs(gridCards)do c.Frame:Destroy()end
 table.clear(gridCards)
end
local function canSelect(uid)
 return snapshot and snapshot.Profile and snapshot.Profile.Items and snapshot.Profile.Items[uid]~=nil
end
updateSeller=function()
 if mode~='Seller'then return end
 local count,total=0,0
 for uid in pairs(sellerSelection)do
  count+=1
  local item=snapshot and snapshot.Profile and snapshot.Profile.Items and snapshot.Profile.Items[uid]
  if item then total+=value.Price(item)or 0 end
 end
 local d=ui.Seller;d.Action.Parent.Visible=true
 d.Action.Text=pending and pending.Action=='BulkSell'and'RETRY SAME SALE'or('SELL SELECTED ('..count..')')
 if d.Total then d.Total.Text='TOTAL: '..format(total)..' CASH' end
 d.Context.Text='SELECT FINDS · '..count..' SELECTED'
 for _,card in ipairs(gridCards)do
  local on=sellerSelection[card.Key]==true
  local stroke=card.Frame.Main:FindFirstChild('BorderStroke')
  if stroke then stroke.Color=on and U.accent or gui.MainWindow.Content.PageContainer.YardPage.LatestFoundCard.Main.BorderStroke.Color end
  local mark=card.Frame.Main:FindFirstChild('SelectionMark')
  if mark then mark.Text=on and'✓ SELECTED'or'□ SELECT';mark.TextColor3=on and U.accent or U.muted end
 end
end
ui.Seller.SelectAll.Activated:Connect(function()
 if not active()or mode~='Seller'or busy or pending or not snapshot then return end
 table.clear(sellerSelection)
 for uid in pairs(snapshot.Profile.Items)do if canSelect(uid)then sellerSelection[uid]=true end end
 updateSeller();ui.FocusDetails('Seller')
end)
ui.Seller.Clear.Activated:Connect(function()
 if busy or pending then return end
 table.clear(sellerSelection);updateSeller()
end)
local function rowKey(row)return row.ItemUid or row.DogUid end
local function currentDog()
 if not snapshot or not kennelContext then return end
 for _,d in pairs(snapshot.Profile.Dogs)do if d.AssignedSlot==kennelContext.Slot then return d end end
end
local function eligible(d)
 return d.OwnerUserId==player.UserId and (d.State=='Inventory' or d.State=='Digging') and ((d.AssignedSlot or '')=='' or d.AssignedSlot==kennelContext.Slot)
end
selectRow=function(row)
 selected=row and rowKey(row) or nil;quote=nil
 if not mode or not ui[mode] or not ui[mode].Details then return end
 local d=ui[mode];clearPreview(d.Preview)
 d.Action.Parent.Visible=row~=nil
 if not row then
  d.Name.Text='SELECT A CARD';d.Facts.Text=mode=='Seller' and 'Select multiple cards, or SELECT ALL. SELL SELECTED performs one sale.' or 'Choose an available dog for this kennel.'
  d.Preview.Empty.Visible=true;d.Preview.Empty.Text='?'
 else
  d.Name.Text=row.DisplayName or (dogs[row.DogId] or {}).DisplayName or row.DogId
  if mode=='Seller' then
   local price=value.Price(row)
   d.Facts.Text=string.format('%s · %.4g kg\n%s · %s\nSELL VALUE: %s Cash\nFind #%s',row.Class,row.WeightKg,row.WeightTier,row.Mutation or 'Normal',format(price),row.ItemUid:sub(-8))
   d.Action.Text='SELL FOR '..format(price)
  else
   local stats=(snapshot.DogStats or {})[row.DogUid] or {}
   local def=dogs[row.DogId] or {}
   d.Facts.Text=string.format('%s · %s\nMastery %s\nAbility: %s\nWork cycle: %s\n%s',row.Rarity or def.Rarity or '',row.Variant or 'Normal',tostring(row.Mastery or 0),Labels.AbilityLabel(row.Ability or def.Ability),stats.Cycle and string.format('%.1fs',stats.Cycle) or '—',(row.AssignedSlot or '')~='' and 'Assigned: '..Labels.DigSlotLabel(row.AssignedSlot)or 'In storage')
   local occupied=currentDog()
   d.Action.Text=occupied and occupied.DogUid==row.DogUid and 'REMOVE FROM KENNEL' or occupied and 'REMOVE CURRENT DOG FIRST' or 'ASSIGN'
  end
  preview(d.Preview,row,mode=='Kennels')
 end
 for _,c in ipairs(gridCards)do
  local border=c.Frame.Main:FindFirstChild('BorderStroke')
  if border then border.Color=row and c.Key==selected and U.accent or gui.MainWindow.Content.PageContainer.YardPage.LatestFoundCard.Main.BorderStroke.Color end
 end
 if mode=='Seller'then updateSeller()end
end
local function renderOwned()
 local oldSelection=selected
 clearGrid()
 local p=snapshot.Profile;local d=ui[mode];local rows={}
 if mode=='Seller' then
  if not pending then for uid in pairs(sellerSelection)do if not canSelect(uid)then sellerSelection[uid]=nil end end end
  for _,item in pairs(p.Items)do table.insert(rows,item)end
  table.sort(rows,function(a,b)if a.FoundAt==b.FoundAt then return a.ItemUid<b.ItemUid end;return a.FoundAt>b.FoundAt end)
  d.Context.Text='YOUR FINDS · '..#rows..' OWNED'
  d.Empty.Text='NO FINDS TO SELL\nDig up discoveries and bring them here.'
 else
  local occupied=currentDog()
  for _,dog in pairs(p.Dogs)do if eligible(dog) then table.insert(rows,dog)end end
  table.sort(rows,function(a,b)return a.DogUid<b.DogUid end)
  d.Context.Text='KENNEL #'..(kennelContext.Slot:match('%d+$') or '')..(occupied and ' · '..occupied.DisplayName or ' · FREE')
  d.Empty.Text='NO AVAILABLE DOGS\nBring a dog to your yard or free one from another kennel.'
  if occupied then oldSelection=oldSelection or occupied.DogUid end
 end
 d.Empty.Visible=#rows==0
 local chosen
 for index,row in ipairs(rows)do
  local key=rowKey(row)
  local holder,face=U.card(d.Grid,key,UDim2.new(),UDim2.fromOffset(180,225));holder.LayoutOrder=index
  local vp=U.viewport(face,'Preview',UDim2.fromScale(.05,.04),UDim2.fromScale(.90,.44))
  local fallback=U.label(vp,'Empty','?',UDim2.fromScale(.1,.1),UDim2.fromScale(.8,.8),34,true);fallback.TextXAlignment=Enum.TextXAlignment.Center
  local title=U.label(face,'Name',row.DisplayName or row.DogId,UDim2.fromScale(.055,.51),UDim2.fromScale(.89,.19),21)
  local information
  if mode=='Seller' then information=string.format('%.4g kg · %s\n%s · %s Cash\n#%s',row.WeightKg,row.Mutation or 'Normal',row.Class,format(value.Price(row)),key:sub(-6))
  else information=string.format('%s · %s\n%s',row.Rarity or (dogs[row.DogId] or {}).Rarity or '',row.Variant or 'Normal',(row.AssignedSlot or '')~='' and 'THIS KENNEL' or 'AVAILABLE') end
  U.label(face,'Info',information,UDim2.fromScale(.055,.72),UDim2.fromScale(.89,.24),16,true)
  local click=Instance.new('TextButton');click.Name='Select';click.Text='';click.BackgroundTransparency=1;click.Size=UDim2.fromScale(1,1);click.ZIndex=10;click.Parent=face
  if mode=='Seller'then
   local mark=U.label(face,'SelectionMark','',UDim2.fromScale(.48,.045),UDim2.fromScale(.48,.12),16)
   mark.ZIndex=9;mark.TextXAlignment=Enum.TextXAlignment.Right
  end
  click.Activated:Connect(function()
   if busy or pending then return end
   if mode=='Seller'and canSelect(key)then sellerSelection[key]=not sellerSelection[key]or nil end
   selectRow(row);ui.FocusDetails(mode)
  end)
  table.insert(gridCards,{Frame=holder,Viewport=vp,Row=row,Key=key})
  if key==oldSelection then chosen=row end
 end
 selectRow(chosen);ui.Layout();task.defer(visiblePreviews)
end
render=function()
 if not active() or not snapshot then return end
 local p=snapshot.Profile
 ui.Money.Text='Cash '..format(p.Cash)..'\nBones '..format(p.Bones)..' · Lv. '..p.Level
 if mode=='Upgrades' then
  if not trainingView then renderEstate(p)end
  for kind,card in pairs(upgradeCards)do
   card.Holder.Visible=trainingView
   local def=config.Upgrades[kind];local level=p.Upgrades[kind] or 0;local price=math.floor(def.Base*def.Factor^level)
   card.Level.Text='Level '..level..' / '..def.Max;card.Fill.Size=UDim2.fromScale(level/def.Max,1)
   card.Current.Text='Current: '..effect(kind,level,level)
   card.Next.Text=level>=def.Max and 'Maximum level reached' or 'Next: '..effect(kind,level+1,level)
   card.Buy.Text=level>=def.Max and 'MAX LEVEL' or 'UPGRADE · '..format(price)..' CASH'
   card.Buy.Active=level<def.Max and p.Cash>=price;card.Buy.AutoButtonColor=card.Buy.Active
  end
 elseif mode=='Layers' then
  for index,card in ipairs(layerCards)do
   local def=config.Layers[index];local unlocked=p.UnlockedLayers[tostring(index)]
   local ready=p.Level>=def.Level and p.Cash>=def.Cost and (p.Prestige or 0)>=(def.Prestige or 0) and (index==1 or p.UnlockedLayers[tostring(index-1)])
   card.Requirements.Text=unlocked and 'Unlocked' or 'Level '..def.Level..' · '..format(def.Cost)..' Cash'..((def.Prestige or 0)>0 and ' · Prestige '..def.Prestige or '')..(index>1 and not p.UnlockedLayers[tostring(index-1)] and '\nUnlock '..config.Layers[index-1].Name..' first' or '')
   card.Action.Text=p.CurrentLayer==index and 'DIGGING HERE' or unlocked and 'DIG HERE' or ready and 'UNLOCK' or 'LOCKED'
  end
 else renderOwned() end
 ui.Layout()
end
refresh=function(force)
 if refreshing or not active() then return end
 if not force and os.clock()-lastRefresh<1.5 then return end
 refreshing=true;lastRefresh=os.clock();local token=viewToken
 local transport,ok,data=call('Snapshot',{})
 refreshing=false
 if token~=viewToken then return end
 if transport and ok and type(data)=='table' and data.Profile then
  snapshot=data
  render()
 elseif active() then status(transport and data or 'Could not refresh. Please retry.') end
end
ui.Seller.Action.Activated:Connect(function()
 if not active()or mode~='Seller'or busy then return end
 if pending then mutate(pending.Action,pending.Args,pending.Kind);return end
 local ids={};for uid in pairs(sellerSelection)do if canSelect(uid)then table.insert(ids,uid)end end
 if #ids==0 then status('Select finds first.');return end
 table.sort(ids)
 mutate('BulkSell',{Uids=ids})
end)
ui.Kennels.Action.Activated:Connect(function()
 if not active() or mode~='Kennels' or not selected or busy or not kennelContext or not snapshot then return end
 local d=snapshot.Profile.Dogs[selected];if not d then return end
 local occupied=currentDog()
 if occupied and occupied.DogUid~=selected then selectRow(occupied);status('Remove the current dog before assigning another.');return end
 mutate(occupied and 'Remove' or 'Assign',{Uid=selected,Slot=kennelContext.Slot,YardId=kennelContext.YardId},'Kennel')
end)
open=function(name,context)
 if pending then mutate(pending.Action,pending.Args,pending.Kind);return end
 if name=='Kennels' and (not context or context.YardId~=player:GetAttribute('YardId')) then return end
 trainingView=name=='DogTraining'
 if trainingView then name='Upgrades'end
 estateScroll.Visible=name=='Upgrades'and not trainingView
 hero.Visible=estateScroll.Visible
 for _,service in ipairs({'Seller','Kennels'})do ui[service].Scroll.CanvasPosition=Vector2.zero end
 ui.UpgradeGrid.Visible=trainingView
 ui.UpgradeGrid.Position=UDim2.fromScale(.012,.015)
 ui.UpgradeGrid.Size=UDim2.fromScale(.976,.97)
 viewToken+=1;mode=name;selected=nil;quote=nil;kennelContext=context;snapshot=nil;table.clear(sellerSelection)
 clearGrid();ui.Status.Text='Loading saved data...'
 ui.Title.Text=({Upgrades=trainingView and 'DOG TRAINING'or 'ESTATE UPGRADES',Layers='DIGGING LAYERS',Seller='SELL FINDS',Kennels='ASSIGN DOG'})[name]
 navigation:Fire('Service',name)
 if ui[name] and ui[name].Grid then ui[name].Empty.Visible=true;ui[name].Empty.Text='Loading...';selectRow(nil) end
 task.spawn(function()refresh(true);if active() and snapshot then status('')end end)
end
ui.Close.Activated:Connect(function()navigation:Fire('Close')end)
root:GetPropertyChangedSignal('Visible'):Connect(function()
 if not root.Visible then viewToken+=1;quote=nil;clearGrid() end
end)
local yard=gui.MainWindow.Content.PageContainer.YardPage
yard.ActionButtons.Upgrades.Main.Activated:Connect(function()
 if busy or pending then return end
 -- TARGET validates workshop proximity on purchase; it has no VisitUpgrades action.
 open('DogTraining')
end)
yard.ActionButtons.DiggingLayers.Main.Activated:Connect(function()open('Layers')end)
Navigation.RegisterServices(open)
for _,name in ipairs({'Seller','Kennels'})do ui[name].Grid:GetPropertyChangedSignal('CanvasPosition'):Connect(visiblePreviews) end
local scheduled=false
player:GetAttributeChangedSignal('InventoryRevision'):Connect(function()
 if not active() or scheduled then return end
 scheduled=true;task.delay(1.5,function()scheduled=false;if active() and not busy then refresh()end end)
end)
task.spawn(function()
 while gui.Parent do task.wait(5);if active() and not busy then refresh()end end
end)

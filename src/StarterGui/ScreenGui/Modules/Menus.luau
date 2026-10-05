-- Each service owns a separate window; only one is visible at a time.
-- Navigation and backdrop ownership belong exclusively to GUIIntegration.
local RS=game:GetService('ReplicatedStorage')
local UIS=game:GetService('UserInputService')
local Http=game:GetService('HttpService')
local ItemValue=require(RS:WaitForChild('ItemValuation'))
local Menus={}
function Menus.new(gui,options)
 local U=require(script.Parent.UITheme);local N=require(script.Parent.GUIIntegration)
 local remote=RS:WaitForChild('DogEconomyRequest')
 local pages=gui.MainWindow.Content.PageContainer
 local root,canvas
 local windows={}
 local self={page=nil,state={DogFilter='All',DexFilter='All',FindDepth='All',FindClass='All',FindTier='All',FindMutation='All',FindSort='Newest',CollectionDepth=1,TradeDogs={},TradeItems={},Materials={},Tracked={}},busy=false,epoch=0}
 local W,H,mobile=1100,700,false
 local polling,lastPoll=false,-10
 local idleLastPoll=-30
 local offlineNotice=U.Button(gui.HUD,'OfflineEarningsNotice','WHILE YOU WERE AWAY',0,0,320,57,function()N.OpenScreen('OfflineEarnings')end,U.Colors.gold)
 offlineNotice.AnchorPoint=Vector2.new(.5,0);offlineNotice.Position=UDim2.new(.5,0,0,18);offlineNotice.Visible=false
 offlineNotice.Caption.TextSize=19
 U.LayoutTouchHUD(gui)
 function self:OfflineNotice()
  local report=self.snapshot and self.snapshot.OfflineEarnings
  local amount=report and tonumber(report.PendingCoins)or 0
  offlineNotice.Visible=amount>0
  offlineNotice.Caption.Text='YOUR DOGS EARNED\n+'..U.Fmt(amount)..' COINS WHILE AWAY'
 end

 function self:Dismiss()if self.dialog then self.dialog:Destroy();self.dialog=nil end end
 function self:Hide()
  local offer=self.page=='LuckyOdds'and self.state.LuckyOffer
  if type(offer)=='table'and offer.BlockUid then
   self.state.LuckyOffer=nil
   task.spawn(function()pcall(function()RS.RewardRequest:InvokeServer('CancelBlockOffer',{BlockUid=offer.BlockUid})end)end)
  end
  self.page=nil;self.epoch+=1;self:Dismiss();for _,window in pairs(windows)do window.Root.Visible=false end
  self.worldRewardMachine=false;if self.worldRewardMachineRoot then self.worldRewardMachineRoot.Visible=false end
  self.state.WorldOddsOpen=false;gui:SetAttribute('RewardMachineOddsOpen',false)
  local odds=gui:FindFirstChild('RewardMachineOddsOverlay');if odds then odds:Destroy()end
 end
 function self:Close()N.Close()end
 function self:Show(page)N.OpenPage(page)end
 function self:Mount(page)
  if not windows[page]then
   local panel=U.New('Frame',{Name=page..'Window',Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(255,251,242),BorderSizePixel=0,Visible=false,ClipsDescendants=false},pages)
   U.Round(panel,16);U.Stroke(panel,U.Colors.edge,3)
   U.WindowChrome(panel,page,931,function()N.Close()end)
   windows[page]={Root=panel,Canvas=U.New('Frame',{Name='WindowContent',BackgroundTransparency=1,ClipsDescendants=true},panel)}
  end
  root=windows[page].Root;canvas=windows[page].Canvas
  self.page=page;self.epoch+=1;self.message=nil;root.Visible=true;self:Resize(root.AbsoluteSize);self:Fetch(true)
  if page=='RewardMachine'or page=='TicketShop'then self:FetchRewardMachine(true)end
  if page=='Marketplace'and not self.state.Market then self:QueryMarket({Kind='Item',Page=1},function(v)self.state.Market=v;self.state.Listing=v.Items[1]end)end
 end
 function self:MountWorldRewardMachine()
  if not self.worldRewardMachineRoot then
   self.worldRewardMachineRoot=U.New('Frame',{Name='RewardMachineWorldPanel',BackgroundTransparency=1,ZIndex=70,Visible=false},gui)
   self.worldRewardMachineCanvas=U.New('Frame',{Name='WindowContent',BackgroundTransparency=1,Size=UDim2.fromScale(1,1)},self.worldRewardMachineRoot)
  end
  root=self.worldRewardMachineRoot;canvas=self.worldRewardMachineCanvas;self.worldRewardMachine=true;self.page='RewardMachine';self.epoch+=1;self.message=nil
  root.Visible=true;self:Resize(gui.AbsoluteSize);self:FetchRewardMachine(true)
 end
 function self:Fetch(force)
  if polling or(not force and os.clock()-lastPoll<5)then return end;polling=true;lastPoll=os.clock()
  task.spawn(function()
   local transport,ok,value=pcall(function()return remote:InvokeServer('Snapshot',{})end);polling=false
   if transport and ok and type(value)=='table'and value.Profile then self.snapshot=value;self.serverClock=value.Now;self.clockAt=os.clock();self:OfflineNotice()
   else self.message=transport and tostring(value)or'Connection interrupted. Reopen to retry.'end
   if self.page and not UIS:GetFocusedTextBox()and not self.dialog then self:Render()end
  end)
 end
 function self:FetchRewardMachine(force)
  if self.machinePolling or self.state.RewardBusy or(not force and os.clock()-(self.lastMachinePoll or -10)<5)then return end
  self.machinePolling=true;self.lastMachinePoll=os.clock()
  task.spawn(function()
   local transport,ok,value=pcall(function()return RS.RewardRequest:InvokeServer('RewardMachineInfo',{})end)
   self.machinePolling=false
   if transport and ok and type(value)=='table'then self.state.RewardMachineInfo=value;self.state.MachineLoadFailed=nil
   else self.state.RewardMessage=transport and tostring(value)or'Could not refresh your DOG TOKEN.' end
   if self.page=='RewardMachine'or self.page=='TicketShop'then self:Render()end
  end)
 end
 local function applyPatch(snapshot,patch)
  local p=snapshot and snapshot.Profile
  if not p or type(patch)~='table'then return false end
  if type(patch.Cash)=='number'then p.Cash=patch.Cash end
  if type(patch.SoldUids)=='table'then for _,uid in ipairs(patch.SoldUids)do p.Items[uid]=nil end end
  if type(patch.Loot)=='table'then p.Loot=patch.Loot end
  if type(patch.ItemCount)=='number'then snapshot.ItemCount=patch.ItemCount end
  return true
 end
 local function predictSale(snapshot,action,args)
  local p=snapshot and snapshot.Profile
  if not p then return false end
  if action=='BulkSell'and type(args)=='table'and type(args.Uids)=='table'then
   local total,count=0,0
   for _,uid in ipairs(args.Uids)do
    local item=p.Items and p.Items[uid]
    if item then total+=ItemValue.Price(item);p.Items[uid]=nil;count+=1 end
   end
   if count>0 then p.Cash=(p.Cash or 0)+total;return true,string.format('Sold %d items for %d Coins',count,total)end
  elseif action=='SellLoot'then
   local total=0
   if type(args)=='table'and args.Key then
    local stack=p.Loot and p.Loot[args.Key]
    if stack then total=stack.Value or 0;p.Loot[args.Key]=nil end
   else
    for key,stack in pairs(p.Loot or{})do total+=stack.Value or 0;p.Loot[key]=nil end
   end
   if total>0 then p.Cash=(p.Cash or 0)+total;return true,'Sold loot for '..total end
  end
  return false
 end
 function self:Send(action,args,callback)
  if self.busy then return end
  local fastSale=action=='BulkSell'or action=='SellLoot'
  self.busy=true
  if fastSale then
   local predicted=predictSale(self.snapshot,action,args or{})
   if predicted then self.message=nil;if self.page and not UIS:GetFocusedTextBox()and not self.dialog then self:Render()end end
  else
   self.message='Saving…';self:Render()
  end
  task.spawn(function()
   local request=Http:GenerateGUID(false):gsub('%-','');local transport,ok,value=pcall(function()return remote:InvokeServer(action,args or{},request)end);self.busy=false
   if fastSale and transport and ok then self.message=nil
   else self.message=transport and(type(value)=='table'and(value.Message or'Done')or tostring(value))or'Connection interrupted. Checking saved state…'end
   if transport and ok and type(value)=='table'and type(value.StatePatch)=='table'and applyPatch(self.snapshot,value.StatePatch)then
    if callback then callback(value)end
    if self.page and not UIS:GetFocusedTextBox()and not self.dialog then self:Render()end
   elseif transport and ok and type(value)=='table'and type(value.StateSnapshot)=='table'then
    self.snapshot=value.StateSnapshot;self.serverClock=self.snapshot.Now;self.clockAt=os.clock();self:OfflineNotice()
    if callback then callback(value)end
    if self.page and not UIS:GetFocusedTextBox()and not self.dialog then self:Render()end
   else
    if transport and ok and callback then callback(value)end;self:Fetch(true)
   end
  end)
 end
 function self:QueryMarket(args,callback)
  if self.busy then return end
  if os.clock()<(self.nextMarketQuery or 0)then self.message='Market refresh: wait a few seconds.';self:Render();return end
  self.nextMarketQuery=os.clock()+5;self.busy=true
  task.spawn(function()local transport,ok,value=pcall(function()return remote:InvokeServer('MarketQuery',args)end);self.busy=false
   if transport and ok then callback(value)else self.message=tostring(transport and value or ok)end;self:Render()
  end)
 end
 function self:Confirm(title,message,action,args)
  self:Dismiss()
  -- Transparent input shield: the root Backdrop remains the sole dimming surface.
  local shield=U.New('Frame',{Name='Confirmation',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Active=true,ZIndex=80},gui);self.dialog=shield
  local box=U.Modal(shield,'ConfirmPanel',title,600,350)
  U.Text(box,message,24,76,552,175,22)
  U.Button(box,'Cancel','CANCEL',24,278,270,48,function()self:Dismiss()end)
  U.Button(box,'Confirm','CONFIRM',306,278,270,48,function()self:Dismiss();self:Send(action,args)end,U.Colors.green)
 end
 function self:Resize(size)
  if size.X<1 or size.Y<1 then return end
  if self.worldRewardMachine then
   local left,top,width,height=U.SafeArea(gui)
   mobile=width<600;W=math.max(260,math.min(mobile and 380 or 760,width-28));H=W>=600 and 94 or 132
   self.layoutScale=math.min(1,(width-28)/W,(height-28)/H)
   root.AnchorPoint=Vector2.new(.5,1);root.Position=UDim2.fromOffset(left+width/2,top+height-14);root.Size=UDim2.fromOffset(W*self.layoutScale,H*self.layoutScale)
   gui:SetAttribute('RewardMachineRailHeight',H*self.layoutScale)
   canvas.Position=UDim2.new();canvas.Size=UDim2.fromOffset(W,H);self.observedSize=root.AbsoluteSize
   if self.page then self:Render()end;return
  end
  self.observedSize=size;local windowScale=gui.MainWindow:FindFirstChildWhichIsA('UIScale');size=size/(windowScale and math.max(.01,windowScale.Scale)or 1);mobile=gui:GetAttribute('CompactMenus')==true;W=math.max(280,size.X-24)
  self.layoutScale=1;H=math.max(180,size.Y-24)
  canvas.Position=UDim2.fromOffset((size.X-W*self.layoutScale)/2,12)
  canvas.Size=UDim2.fromOffset(W,H)
  if self.page then self:Render()end
 end
 function self:Render()
  if not self.page then return end
  local scrolls={};for _,v in ipairs(canvas:GetDescendants())do if v:IsA('ScrollingFrame')then scrolls[v.Name]=v.CanvasPosition end end
  canvas:ClearAllChildren();U.New('UIScale',{Scale=self.layoutScale or 1},canvas)
  local hasStatus=not self.worldRewardMachine and self.message~=nil and self.message~=''
  local bodyH=hasStatus and H-32 or H
  local content=U.New('Frame',{Name='PageContent',Size=UDim2.fromOffset(W,bodyH),BackgroundTransparency=1,ClipsDescendants=true},canvas)
  local c={U=U,Parent=content,W=W,H=bodyH,Mobile=mobile,Snapshot=self.snapshot,State=self.state,Page=self.page,Busy=self.busy,Gui=gui,
   Now=function()return(self.serverClock or os.time())+os.clock()-(self.clockAt or os.clock())end,
   Close=function()N.Close()end,Show=function(page)N.OpenPage(page)end,Draw=function()if self.worldRewardMachine then self:Resize(gui.AbsoluteSize)else self:Render()end end,
   Send=function(...)self:Send(...)end,Confirm=function(...)self:Confirm(...)end,Query=function(...)self:QueryMarket(...)end,
   Go=function(destination)N.Navigate(destination)end,Options=options}
  if self.worldRewardMachine then require(script.Parent.RewardScreens).WorldRewardMachine(c)
  elseif self.snapshot then
   if self.page=='LuckyPad'or self.page=='LuckyOdds'then require(script.Parent.LuckyBlockUI).Build(c)
   elseif ({Collection=true,Marketplace=true,Records=true,Inspect=true,Listing=true,CreateListing=true})[self.page]then require(script.Parent.DiscoveryScreens).Build(c)
   else require(script.Parent.EconomyScreens).Build(c)end
  else U.Center(content,self.message or'Loading saved progress…',20,60,W-56,100,24,U.Colors.gold,true)end
  if hasStatus then U.Text(canvas,self.message,6,H-27,W-12,24,16,U.Colors.muted)end
  for _,v in ipairs(canvas:GetDescendants())do if v:IsA('ScrollingFrame')and scrolls[v.Name]then v.CanvasPosition=scrolls[v.Name]end end
 end
 function self:Update()
  if not self.page then
   if N.Owner=='HUD'and game.Players.LocalPlayer:GetAttribute('EconomyReady')and os.clock()-idleLastPoll>=15 then idleLastPoll=os.clock();self:Fetch(false)end
   return
  end
  if root.AbsoluteSize~=self.observedSize then self:Resize(root.AbsoluteSize)end
  local offer=self.page=='LuckyOdds'and self.state.LuckyOffer
  if type(offer)=='table'and offer.ExpiresAt and offer.ExpiresAt<=((self.serverClock or os.time())+os.clock()-(self.clockAt or os.clock()))and not offer.ExpiryDrawn then offer.ExpiryDrawn=true;self:Render()end
  for _,v in ipairs(canvas:GetDescendants())do
   if v:IsA('TextLabel')and v:GetAttribute('Deadline')then local left=math.max(0,v:GetAttribute('Deadline')-((self.serverClock or os.time())+os.clock()-(self.clockAt or os.clock())));if v:GetAttribute('CountdownStyle')=='Clock'then v.Text=(v:GetAttribute('CountdownPrefix')or'')..string.format('%02d:%02d:%02d',math.floor(left/3600),math.floor(left/60)%60,math.floor(left)%60)elseif v:GetAttribute('CountdownStyle')=='Supply'then v.Text=left>0 and('ACTIVE · '..require(RS.PriceFormat).Clock(left))or'READY TO USE'else v.Text=string.format('%dd %02dh %02dm %02ds',math.floor(left/86400),math.floor(left/3600)%24,math.floor(left/60)%60,math.floor(left)%60)end end
  end
  if self.page=='RewardMachine'or self.page=='TicketShop'then self:FetchRewardMachine(false)end
  if not self.dialog and not UIS:GetFocusedTextBox()then self:Fetch(false)end
 end
 Menus.Active=self
 gui:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()if self.worldRewardMachine then self:Resize(gui.AbsoluteSize)end end)
 gui.Destroying:Connect(function()if Menus.Active==self then Menus.Active=nil end end)
 return self
end
return Menus

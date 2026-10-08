local Audio=require(game.ReplicatedStorage.RewardAudio)
local RS=game:GetService('ReplicatedStorage');local Http=game:GetService('HttpService');local Run=game:GetService('RunService');local Marketplace=game:GetService('MarketplaceService');local Players=game:GetService('Players')
local Motion=require(RS:WaitForChild('RewardMachineMotion'));local Definitions=require(RS.DogEconomy.DogDefinitions)
local C=require(RS.LuckyBlockConfig);local Visual=require(RS.LuckyBlockVisuals);local V=require(script.Parent.PreviewRenderer);local S={};local clearWorldPrediction
local function request(c,action,args,done)
 local s=c.State;if s.RewardBusy then return end;s.RewardBusy=true;s.RewardMessage='Please wait…';c.Draw()
 task.spawn(function()
  local transport,ok,value=pcall(function()return RS.RewardRequest:InvokeServer(action,args or {})end)
  s.RewardBusy=false
  if transport and ok then s.RewardMessage=nil;if done then done(value)end
  else
   if action=='RewardMachineActivate'then clearWorldPrediction(c,true)end
   s.RewardMessage=transport and tostring(value)or 'Connection interrupted. Retry to check the saved result.'
  end
  if not c.Gui or c.Gui.Parent then c.Draw()end
 end)
end
local function block(parent,tier,x,y,w,h)
 local model=Visual.Build(tier);local view=V.Scene(parent,model,x,y,w,h);model:Destroy();return view
end
local function preview(c,parent,row,x,y,w,h)
 if row.Dog or row.Kind=='Dog'then V.Dog(parent,row.Dog or row.Id,x,y,w,h)
 elseif row.Item or row.Kind=='Item'then V.Item(parent,row.Item or {ItemId=row.Id,Mutation='NORMAL',WeightMultiplier=1},x,y,w,h)
 else local model=require(RS.EconomyRewardVisuals).Build(row);if model then V.Scene(parent,model,x,y,w,h);model:Destroy()else c.U.Center(parent,row.Name or row.Kind,x,y,w,h,27,c.U.Colors.gold,true)end end
end
local seenMachine={}
local function beginWorldPrediction(c,requestId)
 local at=workspace:GetServerTimeNow();local finish=at+Motion.Duration
 c.State.WorldSpinUntil=finish
 Players.LocalPlayer:SetAttribute('RewardMachinePendingAt',at)
 Players.LocalPlayer:SetAttribute('RewardMachinePendingRequest',requestId)
 if c.Gui then c.Gui:SetAttribute('RewardMachineActiveUntil',finish);c.Gui:SetAttribute('RewardMachineActive',true)end
 return at
end
clearWorldPrediction=function(c,failed)
 Players.LocalPlayer:SetAttribute('RewardMachinePendingAt',nil);Players.LocalPlayer:SetAttribute('RewardMachinePendingRequest',nil)
 if failed then
  c.State.WorldSpinUntil=nil
  if c.Gui then c.Gui:SetAttribute('RewardMachineActiveUntil',0);c.Gui:SetAttribute('RewardMachineActive',false)end
 end
end
function S.PresentWorld(c,result)
 local receipt=result.Receipt or result.Request
 if receipt and seenMachine[receipt]then return end
 if receipt then seenMachine[receipt]=true end
 local gui=c.Gui or script.Parent.Parent;local U=c.U;local p=result.Presentation
 local finish=type(p)=='table'and tonumber(p.StartedAt)and tonumber(p.Duration)and(p.StartedAt+p.Duration)or workspace:GetServerTimeNow()
 c.State.WorldSpinUntil=finish;gui:SetAttribute('RewardMachineActiveUntil',finish);gui:SetAttribute('RewardMachineActive',finish>workspace:GetServerTimeNow())
 local function showToast()
  if not gui.Parent or not gui:GetAttribute('RewardMachineWorldOpen')then return end
  local old=gui:FindFirstChild('RewardMachineRewardToast');if old then old:Destroy()end
  local toast=U.Panel(gui,'RewardMachineRewardToast',0,0,420,104);toast.ZIndex=80;toast.AnchorPoint=Vector2.new(.5,1)
  local scale=U.New('UIScale',{},toast)
  toast:SetAttribute('Receipt',receipt);toast:SetAttribute('RewardMachineStartedAt',p and p.StartedAt);toast:SetAttribute('RewardMachineDuration',p and p.Duration);toast:SetAttribute('RevealedAt',workspace:GetServerTimeNow())
  U.Gradient(toast,Color3.fromRGB(255,245,183),Color3.fromRGB(238,218,255))
  local name=result.Dog and result.Dog.DisplayName or result.Name or result.Item and result.Item.DisplayName or'Reward'
  local rarity=result.Rarity or(p and p.Rarity)or Motion.Rarity(result)
  U.Text(toast,Motion.UltraRare(result)and'ULTRA RARE!'or'REWARD FOUND!',98,5,278,20,16,U.Colors.purple,true)
  U.Text(toast,name,98,27,278,47,23,U.Colors.text,true)
  U.Text(toast,tostring(rarity):upper()..' · SAVED',98,80,196,18,15,U.Colors.muted,true)
  preview(c,toast,result,4,7,90,90)
  U.Button(toast,'Collect','COLLECT',302,77,110,23,function()toast:Destroy()end,U.Colors.green).Caption.TextSize=13
  local function layout()
   if not gui:GetAttribute('RewardMachineWorldOpen')then toast:Destroy();return end
   local left,top,width,height=U.SafeArea(gui)
   scale.Scale=math.min(1,(width-28)/420)
   local rail=gui:GetAttribute('RewardMachineRailHeight')or(width<600 and 132 or 94)
   toast.Position=UDim2.fromOffset(left+width/2,math.max(top+104*scale.Scale+8,top+height-14-rail-10))
   toast.Visible=gui:GetAttribute('OpenMenu')=='RewardMachine'and not gui:GetAttribute('RewardMachineOddsOpen')
  end
  local events={gui:GetPropertyChangedSignal('AbsoluteSize'):Connect(layout),gui:GetAttributeChangedSignal('RewardMachineRailHeight'):Connect(layout),gui:GetAttributeChangedSignal('RewardMachineWorldOpen'):Connect(layout),gui:GetAttributeChangedSignal('RewardMachineOddsOpen'):Connect(layout)}
  toast.Destroying:Connect(function()for _,event in ipairs(events)do event:Disconnect()end end);layout()
  Audio.Cue(Motion.UltraRare(result)and'burst'or'reveal')
  task.delay(8,function()if toast.Parent then toast:Destroy()end end)
 end
 local function finishSpin()
  if not gui.Parent then return end
  local left=finish-workspace:GetServerTimeNow();if left>0 then task.delay(left,finishSpin);return end
  if c.State.WorldSpinUntil==finish then c.State.WorldSpinUntil=nil;gui:SetAttribute('RewardMachineActive',false)end
  c.State.WorldOddsOpen=false
  c.State.RewardMachineLastReward=result
  c.Draw();showToast()
 end
 task.delay(math.max(0,finish-workspace:GetServerTimeNow()),finishSpin)
 c.Draw()
end
function S.Present(c,result)
 if result.Kind=='Block'or result.Cue=='Pickup'then return end
 if not result.Tier then return S.PresentWorld(c,result)end
 local gui=script.Parent.Parent;local Navigation=require(script.Parent.GUIIntegration)
 local rewardEpoch=Navigation.BeginReward(result.Receipt or result.BlockUid);if not rewardEpoch then return end
 local old=gui:FindFirstChild('RewardReveal');if old then old:Destroy()end
 Audio.Cue('buy');local U=c.U
 local overlay=U.New('Frame',{Name='RewardReveal',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,ZIndex=100,Active=true},gui)
 overlay.Destroying:Connect(function()task.defer(function()Navigation.EndReward(rewardEpoch)end)end)
 local box=U.Modal(overlay,'RewardCard','OPENING…',580,480)
 local heading=box:FindFirstChild('Label');if heading then heading.Name='RewardStatus'end
 local title=U.Center(box,result.Tier:upper()..' LUCKY BLOCK',20,66,540,44,24,U.Colors.gold,true)
 local art=U.New('Frame',{Name='OpeningArt',Position=UDim2.fromOffset(30,110),Size=UDim2.fromOffset(520,230),BackgroundTransparency=1},box)
 local view=block(art,result.Tier,0,0,520,225);local state='opening';local t=0;local phase=-1;local skip,done
 local function reveal()
  if state~='opening'then return end;state='revealed';art.Rotation=0
  if heading then heading.Text='REWARD SAVED'end
  if skip then skip.Visible=false end;if done then done.Visible=true;U.SetButtonEnabled(done,true)end
  Audio.Cue('burst');Audio.Cue('reveal');art:ClearAllChildren();preview(c,art,result,0,0,520,225)
  title.Text=result.Dog and(result.Dog.DisplayName..' · '..result.Dog.Variant)or result.Name or'REWARD SAVED'
  U.Center(box,'Saved to your collection',20,352,540,34,19,U.Colors.muted)
 end
 skip=U.Button(box,'Skip','SKIP / REVEAL',30,405,520,46,reveal,U.Colors.gold)
 done=U.Button(box,'Done','DONE',30,405,520,46,function()if state=='revealed'then overlay:Destroy()end end,U.Colors.green)
 done.Visible=false;U.SetButtonEnabled(done,false)
 local con;con=Run.RenderStepped:Connect(function(dt)
  if not overlay.Parent or state~='opening'then con:Disconnect();return end
  t+=dt;local nextPhase=math.floor(t/.5)
  if nextPhase~=phase then phase=nextPhase;Audio.Cue(phase<3 and'shake'or'crack')end
  art.Rotation=math.sin(t*35)*math.min(8,2+phase*2)
  if t>=1.5 then art.Rotation=0;view.ImageColor3=Color3.fromRGB(255,225,170)end
  if t>=2 then reveal()end
 end)
 return{Reveal=reveal,Close=function()overlay:Destroy()end}
end
local ticketPrices={};local ticketLoading={};local ticketRetry={}
-- Bought DOG TOKENS count once the machine sells them and Roblox allows this account to use them.
local function usablePaid(info)
 if info.FreeOnly~=false or info.PaidRandomAllowed~=true then return 0 end
 return tonumber(info.PaidTickets)or 0
end
local function clockText(seconds)
 seconds=math.max(0,math.ceil(seconds));return string.format('%02d:%02d:%02d',math.floor(seconds/3600),math.floor(seconds/60)%60,seconds%60)
end
local function infoOrLoad(c)
 local s=c.State;local U=c.U
 if s.RewardMachineInfo then return s.RewardMachineInfo end
 U.Center(c.Parent,s.RewardMessage or'Getting your DOG TOKEN…',10,40,c.W-20,85,25,U.Colors.purple,true)
 if not s.RewardBusy and not s.MachineLoadFailed then
  s.MachineLoadFailed=true;request(c,'RewardMachineInfo',{},function(v)s.RewardMachineInfo=v;s.MachineLoadFailed=nil end)
 elseif not s.RewardBusy then U.Button(c.Parent,'Retry','TRY AGAIN',20,146,c.W-40,48,function()s.MachineLoadFailed=nil;c.Draw()end,U.Colors.blue)end
end
local function wallet(c,parent,info)
 local U,W,P=c.U,c.W,c.U.Colors
 local free=tonumber(info.FreeTickets)or math.min(1,tonumber(info.Tickets)or 0)
 local paid=tonumber(info.PaidTickets)or 0;local total=free+usablePaid(info)
 local at=tonumber(info.NextFreeTicketAt or info.NextTicketAt)or 0
 local narrow=W<480;local height=narrow and 244 or c.Mobile and 210 or 172
 local panel=U.Panel(parent,'TicketWallet',8,4,W-24,height)
 U.Gradient(panel,Color3.fromRGB(220,188,255),Color3.fromRGB(255,228,111))
 local badge=U.Frame(panel,'TicketBalance',14,14,116,132,P.gold);U.Round(badge,14);U.Stroke(badge,P.edge,3)
 U.Center(badge,'DOG TOKEN',5,7,106,28,16,P.text,true)
 local balance=U.Center(badge,U.Fmt(total),5,36,106,69,44,P.text,true);balance.TextWrapped=false;balance.TextScaled=true
 U.New('UITextSizeConstraint',{MinTextSize=14,MaxTextSize=44},balance)
 local heading=free>0 and(narrow and'READY TO\nACTIVATE!'or'READY TO ACTIVATE!')or(narrow and'NEXT FREE\nDOG TOKEN'or'NEXT FREE DOG TOKEN')
 U.Text(panel,heading,146,12,W-184,narrow and 62 or 40,narrow and 24 or 26,P.text,true)
 local clock=U.Text(panel,free>0 and'Next refill starts after use.'or clockText(at-c.Now()),147,narrow and 78 or 56,W-188,narrow and 64 or c.Mobile and 53 or 36,free>0 and 17 or 27,P.text,true)
 if free==0 and at>0 then clock:SetAttribute('Deadline',at);clock:SetAttribute('CountdownStyle','Clock')end
 U.Text(panel,'FREE '..free..' / 1'..(paid>0 and('  ·  BOUGHT '..paid)or''),narrow and 14 or 147,narrow and 152 or c.Mobile and 116 or 98,W-(narrow and 52 or 188),28,18,P.purple,true)
 U.Text(panel,'Free every 5 hours after use. Stores one free DOG TOKEN; bought tokens never expire.',14,narrow and 190 or c.Mobile and 162 or 139,W-52,narrow and 44 or c.Mobile and 40 or 27,16,P.text)
 return height+19,total,free,paid
end
local function prizeRarity(row)
 local def=row.Kind=='Dog'and Definitions[row.Id]
 return row.Rarity or(def and def.Rarity)or({Cash='Coins',Bones='Bones',Boost='Boost'})[row.Kind]or row.Kind or'Reward'
end
function S.WorldRewardMachine(c)
 local U,W,H,s=c.U,c.W,c.H,c.State;local P=U.Colors;local wide=W>=600
 local panel=U.Panel(c.Parent,'WorldControls',0,0,W,H)
 U.Round(panel,15);U.Gradient(panel,Color3.fromRGB(255,248,219),Color3.fromRGB(234,220,255))
 local close=U.Button(panel,'Close','×',W-40,6,30,30,c.Close,P.red)
 local info=s.RewardMachineInfo
 if not info then
  U.Text(panel,'Loading your DOG TOKEN…',12,12,W-68,36,20,P.muted)
  if not s.RewardBusy and not s.MachineLoadFailed then s.MachineLoadFailed=true;request(c,'RewardMachineInfo',{},function(v)s.RewardMachineInfo=v;s.MachineLoadFailed=nil end)end
  return
 end
 local free=tonumber(info.FreeTickets)or math.min(1,tonumber(info.Tickets)or 0);local total=free+usablePaid(info)
 local spinning=(s.WorldSpinUntil or 0)>workspace:GetServerTimeNow();local cooling=(tonumber(info.NextSpinAt)or 0)>c.Now()
 local ready=total>0 and info.CanSpin~=false and info.InRange~=false and not cooling and not spinning and not s.RewardBusy
 U.Text(panel,U.Fmt(total)..' DOG TOKEN',12,wide and 9 or 24,wide and 190 or 131,28,wide and 23 or 18,P.text,true)
 U.Text(panel,'FREE · '..free..' / 1',wide and 12 or 145,wide and 36 or 26,wide and 190 or W-195,23,wide and 15 or 13,P.purple,true)
 local at=tonumber(info.NextFreeTicketAt or info.NextTicketAt)or 0
 local statusText=spinning and'Watch the reward drum!'or free>0 and'FREE READY · 1 / 5H'or'Free in '..clockText(at-c.Now())
 local status=U.Text(panel,s.RewardMessage or(info.CanSpin==false and total>0 and info.UnavailableReason)or statusText,12,wide and 63 or 52,wide and 190 or W-24,wide and 23 or 20,13,P.muted)
 if not spinning and free==0 and at>0 and not s.RewardMessage then status:SetAttribute('Deadline',at);status:SetAttribute('CountdownStyle','Clock');status:SetAttribute('CountdownPrefix','Free in ')end
 local label=spinning and'ACTIVATING…'or s.RewardBusy and'PLEASE WAIT…'or info.InRange==false and'VISIT DOG-O-MATIC'or total==0 and'NO DOG TOKEN'or cooling and'RESETTING…'or info.CanSpin==false and'UNAVAILABLE'or'ACTIVATE · 1 TOKEN'
 local spinX,spinY,spinW,spinH=wide and 214 or 12,wide and 18 or 80,wide and math.min(260,W-452)or W-170,wide and 58 or 40
 local spin=U.Button(panel,'Spin',label,spinX,spinY,spinW,spinH,ready and function()
  s.SpinRequest=s.SpinRequest or Http:GenerateGUID(false):gsub('-','')
  local startedAt=beginWorldPrediction(c,s.SpinRequest)
  request(c,'RewardMachineActivate',{Request=s.SpinRequest,StartedAt=startedAt},function(v)
   s.SpinRequest=nil
   for _,key in ipairs({'Tickets','FreeTickets','PaidTickets','NextTicketAt','NextFreeTicketAt','NextSpinAt'})do if v[key]~=nil then info[key]=v[key]end end
   S.PresentWorld(c,v);clearWorldPrediction(c,false)
  end)
 end or nil,P.green)
 spin.Caption.TextSize=wide and 19 or W<320 and 12 or 14
 U.Text(panel,'DOG-O-MATIC',wide and W-222 or 12,wide and 9 or 4,wide and 178 or W-65,wide and 29 or 19,wide and 18 or 13,P.purple,true)
 local odds=U.Button(panel,'Odds','CHANCES',wide and W-222 or W-146,wide and 50 or 80,wide and 85 or 60,wide and 34 or 40,function()s.WorldOddsOpen=not s.WorldOddsOpen;c.Draw()end,P.blue)
 local tickets=U.Button(panel,'TicketShop','TOKENS',wide and W-129 or W-78,wide and 50 or 80,wide and 113 or 66,wide and 34 or 40,not spinning and function()c.Show('TicketShop')end or nil,P.gold)
 odds.Caption.TextSize=wide and 14 or 10;tickets.Caption.TextSize=wide and 16 or 12
 if c.Gui then
  local old=c.Gui:FindFirstChild('RewardMachineOddsOverlay');local previous=old and old:FindFirstChild('OddsList',true);local savedScroll=previous and previous.CanvasPosition
  if old then old:Destroy()end
  c.Gui:SetAttribute('RewardMachineOddsOpen',s.WorldOddsOpen==true)
  if s.WorldOddsOpen then
   local _,_,width,height=U.SafeArea(c.Gui);local ow=math.min(430,width-28);local oh=math.min(355,height-28)
   local overlay=U.New('Frame',{Name='RewardMachineOddsOverlay',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Active=true,ZIndex=85},c.Gui)
   local window=U.Modal(overlay,'OddsWindow','REWARD CHANCES',ow,oh)
   U.Button(window,'CloseOdds','×',ow-43,18,28,30,function()s.WorldOddsOpen=false;c.Draw()end,P.red)
   local sc=U.Scroll(window,'OddsList',12,75,ow-24,oh-89)
   for i,row in ipairs(info.Rewards or{})do
    U.Text(sc,row.Name or row.Kind,5,(i-1)*64,ow-133,40,18,P.text,true)
    U.Text(sc,prizeRarity(row):upper(),5,(i-1)*64+42,ow-133,20,14,P.muted)
    U.Text(sc,string.format('%.6g%%',(row.Chance or 0)*100),ow-119,(i-1)*64,83,58,20,P.purple,true)
   end
   if savedScroll then sc.CanvasPosition=savedScroll end
  end
 end
end
function S.RewardMachine(c)
 local info=infoOrLoad(c);if not info then return end
 local U,s,W,H=c.U,c.State,c.W,c.H;local P=U.Colors
 local sc=U.Scroll(c.Parent,'MachineRewards',0,0,W,H)
 local y,total=wallet(c,sc,info)
 local cooling=(tonumber(info.NextSpinAt)or 0)>c.Now()
 local ready=total>0 and info.CanSpin~=false and info.InRange~=false and not cooling and not s.RewardBusy
 local label=s.RewardBusy and'ACTIVATING…'or info.InRange==false and'VISIT DOG-O-MATIC'or total==0 and'WAITING FOR A DOG TOKEN'or cooling and'MACHINE RESETTING…'or info.CanSpin==false and'ACTIVATION UNAVAILABLE'or'ACTIVATE · 1 TOKEN'
 U.Button(sc,'Spin',label,8,y,W-24,55,ready and function()
  s.SpinRequest=s.SpinRequest or Http:GenerateGUID(false):gsub('-','')
  local startedAt=beginWorldPrediction(c,s.SpinRequest)
  request(c,'RewardMachineActivate',{Request=s.SpinRequest,StartedAt=startedAt},function(v)
   s.SpinRequest=nil
   for _,key in ipairs({'Tickets','FreeTickets','PaidTickets','NextTicketAt','NextFreeTicketAt'})do if v[key]~=nil then info[key]=v[key]end end
   S.Present(c,v);clearWorldPrediction(c,false)
  end)
 end or nil,ready and P.green or P.purple);y+=66
 U.Button(sc,'TicketShop',info.FreeOnly==false and'DOG TOKENS · LUCKY SPINS'or'FREE DOG TOKEN INFO',8,y,W-24,42,function()c.Show('TicketShop')end,P.gold);y+=49
 if info.InRange==false then U.Button(sc,'FindRewardMachine','FIND DOG-O-MATIC',8,y,W-24,42,function()require(script.Parent.GUIIntegration).Navigate('RewardMachine')end,P.blue);y+=51 end
 local message=s.RewardMessage or info.CanSpin==false and info.UnavailableReason
 if message and message~=''then U.Text(sc,tostring(message),12,y,W-32,48,17,not s.RewardMessage and(total==0 or cooling)and P.muted or P.red);y+=54 end
 U.Text(sc,'YOUR POSSIBLE REWARDS',12,y,W-32,31,24,P.text,true);y+=36
 U.Text(sc,'One free DOG TOKEN gives one random reward. Exact chances are shown below.',12,y,W-32,45,16,P.muted);y+=49
 local cols=c.Mobile and 2 or 4;local cw=(W-24-(cols-1)*12)/cols
 for i,row in ipairs(info.Rewards or{})do
  local rarity=prizeRarity(row);local tone=U.Rarity[rarity]or({Cash=P.gold,Bones=P.blue,Boost=P.green})[row.Kind]or P.purple
  local card=U.Panel(sc,'Reward'..i,8+(i-1)%cols*(cw+12),y+math.floor((i-1)/cols)*205,cw,193,true)
  local art=U.Frame(card,'Art',6,6,cw-12,90,tone:Lerp(Color3.new(1,1,1),.78));U.Round(art,10)
  preview(c,art,row,4,1,cw-20,88)
  U.Center(card,row.Name or row.Kind,7,99,cw-14,34,18,P.text,true)
  U.Center(card,rarity:upper(),7,136,cw-14,22,14,P.muted,true)
  local chance=U.Frame(card,'Chance',8,162,cw-16,25,tone);U.Round(chance,7)
  U.Center(chance,string.format('%.6g%%',(row.Chance or 0)*100),3,0,cw-22,25,18,P.text,true)
 end
end
function S.TicketShop(c)
 local info=infoOrLoad(c);if not info then return end
 local U,W=c.U,c.W;local P=U.Colors
 local sc=U.Scroll(c.Parent,'DogTokenInfo',0,0,W,c.H)
 local y=wallet(c,sc,info)
 U.Text(sc,'Use one DOG TOKEN to activate the world machine and receive one random reward. View REWARD CHANCES before activating.',12,y,W-32,60,18,P.text);y+=66
 U.Text(sc,'Your next free DOG TOKEN arrives 5 hours after use, including time away. Free tokens are always used before bought ones.',12,y,W-32,60,17,P.muted);y+=68
 if info.FreeOnly==false then
  U.Text(sc,'LUCKY SPIN PACKS',12,y,W-32,40,23,P.purple,true);y+=46
  -- ProductPricing reports a refused or failed prompt here.
  if c.State.CommerceMessage then U.Text(sc,c.State.CommerceMessage,12,y,W-32,40,16,P.red);y+=44 end
  local Pricing=require(script.Parent.ProductPricing)
  local cols=math.max(1,math.min(3,math.floor((W-10)/230)));local cw=(W-24-(cols-1)*12)/cols
  local products=info.TicketProducts or {}
  for i,row in ipairs(products)do
   local card=U.Panel(sc,'Spins_'..row.Key,8+(i-1)%cols*(cw+12),y+math.floor((i-1)/cols)*172,cw,160,true)
   U.Icon(card,row.Key,10,10,64,P.gold)
   U.Text(card,row.Name or row.Key,82,12,cw-92,30,21,P.text,true)
   U.Text(card,U.Fmt(row.Count)..(row.Count==1 and' DOG TOKEN'or' DOG TOKENS'),82,44,cw-92,26,17,P.purple,true)
   local label,action='UNAVAILABLE',nil
   if row.CanPurchase then label,action=Pricing.Quote(c,sc,{Key=row.Key,Id=row.ProductId,Enabled=true,Route='RewardMachineProduct'})end
   U.Button(card,'Buy',label,10,104,cw-20,44,action,P.purple).Caption.TextSize=16
   if not row.CanPurchase and row.UnavailableReason then U.Text(card,row.UnavailableReason,10,76,cw-20,26,13,P.muted)end
  end
  y+=math.ceil(#products/cols)*172+4
  U.Text(sc,'Aurion owns exactly 1 of 10,000 slots on every spin. Paid tokens are delivered after Roblox confirms payment and only work where Roblox allows paid random items.',12,y,W-32,64,15,P.muted);y+=70
 else
  U.Text(sc,'No Coins, Bones, Robux or items are needed. Extra activations cannot be purchased.',12,y,W-32,68,17,P.text);y+=77
 end
 U.Button(sc,'BackToRewardMachine','BACK TO DOG-O-MATIC',8,y,W-24,45,function()c.Show('RewardMachine')end,P.purple)
end
return S

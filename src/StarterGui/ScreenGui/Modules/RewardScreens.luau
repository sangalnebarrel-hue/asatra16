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
local GOLD=Color3.fromRGB(255,198,52);local NIGHT=Color3.fromRGB(20,18,52)
local function clockText(seconds)
 seconds=math.max(0,math.ceil(seconds));return string.format('%02d:%02d:%02d',math.floor(seconds/3600),math.floor(seconds/60)%60,seconds%60)
end
-- DOG TOKENS one activation can spend: the free one, plus paid ones when the server says this
-- account may use paid random items (PolicyService). Paid ones it may not use are only kept.
local function tokens(info)
 local free=tonumber(info.FreeTickets)or math.min(1,tonumber(info.Tickets)or 0)
 local paid=tonumber(info.PaidTickets)or 0
 local spendable=info.PaidSpendable==true or(info.PaidSpendable==nil and info.FreeOnly~=true and info.PaidRandomAllowed==true)
 return free+(spendable and paid or 0),free,paid,spendable
end
local function salesOpen(info)return info.FreeOnly~=true and info.SalesOpen~=false end
local function canBuy(info)return salesOpen(info)and info.PaidRandomAllowed==true end
local function tokenWord(n)return n==1 and' DOG TOKEN'or' DOG TOKENS'end
-- The world machine's shared state: another player's spin, or a Secret prize arriving.
local machineRig
local function rigState()
 if not(machineRig and machineRig.Parent)then
  local district=workspace:FindFirstChild('DOGROTS_District');local attraction=district and district:FindFirstChild('37_AttractionRefresh')
  machineRig=attraction and attraction:FindFirstChild('RewardMachineRig')
 end
 if not machineRig then return false,0,nil end
 return machineRig:GetAttribute('Spinning')==true,tonumber(machineRig:GetAttribute('PrizeHoldUntil'))or 0,machineRig:GetAttribute('PrizeHoldName')
end
-- The open control rail redraws itself when the drum or a deadline changes (no polling).
local live={Token=0}
local function redraw()
 local gui=live.Gui
 if live.Draw and gui and gui.Parent and gui:GetAttribute('RewardMachineWorldOpen')then live.Draw()end
end
local function wakeIn(seconds)
 live.Token+=1;local token=live.Token
 if seconds and seconds>0 and seconds<300 then task.delay(seconds+.05,function()if token==live.Token then redraw()end end)end
end
local function watch(c)
 if c.Gui then live.Gui=c.Gui end
 if machineRig and live.Rig~=machineRig then
  live.Rig=machineRig
  for _,name in ipairs({'Spinning','PrizeHoldUntil'})do machineRig:GetAttributeChangedSignal(name):Connect(function()task.defer(redraw)end)end
 end
 if live.Subscribed then return end;live.Subscribed=true
 -- A DOG TOKEN receipt (RoulettePurchases) refreshes an open DOG-O-MATIC window at once.
 local ok,Navigation=pcall(require,script.Parent.GUIIntegration)
 if ok and type(Navigation)=='table'and Navigation.SubscribeWorldReward then
  Navigation.SubscribeWorldReward(function(data)
   if type(data)~='table'or type(data.RewardMachineTokens)~='table'then return end
   local menus=require(script.Parent.Menus).Active
   if menus and(menus.page=='RewardMachine'or menus.page=='TicketShop')then menus:FetchRewardMachine(true)end
  end)
 end
end
local function infoOrLoad(c)
 local s=c.State;local U=c.U
 if s.RewardMachineInfo then return s.RewardMachineInfo end
 U.Center(c.Parent,s.RewardMessage or'Getting your DOG TOKENS…',10,40,c.W-20,85,25,U.Colors.purple,true)
 if not s.RewardBusy and not s.MachineLoadFailed then
  s.MachineLoadFailed=true;request(c,'RewardMachineInfo',{},function(v)s.RewardMachineInfo=v;s.MachineLoadFailed=nil end)
 elseif not s.RewardBusy then U.Button(c.Parent,'Retry','TRY AGAIN',20,146,c.W-40,48,function()s.MachineLoadFailed=nil;c.Draw()end,U.Colors.blue)end
end
local function wallet(c,parent,info)
 local U,W,P=c.U,c.W,c.U.Colors
 local total,free,paid,spendable=tokens(info)
 local at=tonumber(info.NextFreeTicketAt or info.NextTicketAt)or 0
 local narrow=W<480;local height=narrow and 244 or c.Mobile and 210 or 172
 local panel=U.Panel(parent,'TicketWallet',8,4,W-24,height)
 U.Gradient(panel,Color3.fromRGB(220,188,255),Color3.fromRGB(255,228,111))
 local badge=U.Frame(panel,'TicketBalance',14,14,116,132,P.gold);U.Round(badge,14);U.Stroke(badge,P.edge,3)
 U.Center(badge,'DOG TOKENS',5,7,106,28,16,P.text,true)
 local balance=U.Center(badge,U.Fmt(total),5,36,106,69,44,P.text,true);balance.TextWrapped=false;balance.TextScaled=true
 U.New('UITextSizeConstraint',{MinTextSize=14,MaxTextSize=44},balance)
 local heading=total>0 and(narrow and'READY TO\nACTIVATE!'or'READY TO ACTIVATE!')or(narrow and'NEXT FREE\nDOG TOKEN'or'NEXT FREE DOG TOKEN')
 U.Text(panel,heading,146,12,W-184,narrow and 62 or 40,narrow and 24 or 26,P.text,true)
 local prefix=total>0 and'Next free in 'or''
 local clock=U.Text(panel,free>0 and'Next free refill starts after use.'or prefix..clockText(at-c.Now()),147,narrow and 78 or 56,W-188,narrow and 64 or c.Mobile and 53 or 36,free>0 and 17 or total>0 and 22 or 27,P.text,true)
 if free==0 and at>0 then clock:SetAttribute('Deadline',at);clock:SetAttribute('CountdownStyle','Clock');clock:SetAttribute('CountdownPrefix',prefix)end
 U.Text(panel,'FREE '..free..' / 1'..(paid>0 and(' · PAID '..U.Fmt(paid)..(spendable and''or' (KEPT)'))or''),narrow and 14 or 147,narrow and 152 or c.Mobile and 116 or 98,W-(narrow and 52 or 188),28,18,P.purple,true)
 U.Text(panel,salesOpen(info)and'Free every 5 hours after use (holds one). Paid DOG TOKENS never expire; the free one is used first.'or'Free every 5 hours after use. Stores one DOG TOKEN.',14,narrow and 190 or c.Mobile and 162 or 139,W-52,narrow and 44 or c.Mobile and 40 or 27,narrow and 14 or 15,P.text)
 return height+19,total,free,paid
end
local function prizeRarity(row)
 local def=row.Kind=='Dog'and Definitions[row.Id]
 return row.Rarity or(def and def.Rarity)or({Cash='Coins',Bones='Bones',Boost='Boost'})[row.Kind]or row.Kind or'Reward'
end
local function chanceText(row)return row.ChanceText or string.format('%.2f%%',(row.Chance or 0)*100)end
local function jackpotRow(rewards)for _,row in ipairs(rewards or{})do if row.Jackpot then return row end end end
-- The jackpot first, with its 3D model: ULTRA RARE JACKPOT · 0.01%.
local function jackpotCard(c,parent,row,x,y,w)
 local U=c.U
 local card=U.Panel(parent,'JackpotRow',x,y,w,108);U.Gradient(card,Color3.fromRGB(70,42,140),NIGHT);U.Stroke(card,GOLD,3)
 local art=U.Frame(card,'JackpotArt',6,6,96,96,Color3.fromRGB(34,44,104));U.Round(art,12)
 preview(c,art,row,0,0,96,96)
 U.Text(card,'ULTRA RARE JACKPOT · '..chanceText(row),112,8,w-122,24,16,GOLD,true)
 U.Text(card,string.upper(tostring(row.Name or row.Id or'JACKPOT')),112,32,w-122,38,30,Color3.new(1,1,1),true)
 local odds=math.floor((tonumber(row.OddsDenominator)or 10000)/math.max(1,tonumber(row.ChanceUnits)or 1)+.5)
 U.Text(card,prizeRarity(row):upper()..' DOG · 1 IN '..U.Fmt(odds)..' ACTIVATIONS',112,72,w-122,28,13,Color3.fromRGB(205,214,255),true)
 return card
end
local function oddsRow(c,parent,row,y,w)
 local U=c.U;local P=U.Colors
 local tone=U.Rarity[prizeRarity(row)]or({Cash=P.gold,Bones=P.blue,Boost=P.green})[row.Kind]or P.purple
 local art=U.Frame(parent,'PrizeArt',4,y+3,56,56,tone:Lerp(Color3.new(1,1,1),.78));U.Round(art,10)
 preview(c,art,row,2,2,52,52)
 U.Text(parent,row.Name or row.Kind,68,y+2,w-170,34,18,P.text,true)
 U.Text(parent,prizeRarity(row):upper(),68,y+36,w-170,20,14,P.muted)
 U.Text(parent,chanceText(row),w-98,y,92,62,20,P.purple,true).TextXAlignment=Enum.TextXAlignment.Right
end
-- Every prize with its exact chance (the same integer slots as the roll), the jackpot first.
local function oddsList(c,parent,rewards,y,w)
 local jackpot=jackpotRow(rewards)
 if jackpot then jackpotCard(c,parent,jackpot,2,y,w-4);y+=118 end
 for _,row in ipairs(rewards or{})do if row~=jackpot then oddsRow(c,parent,row,y,w);y+=64 end end
 return y
end
function S.WorldRewardMachine(c)
 local U,W,H,s=c.U,c.W,c.H,c.State;local P=U.Colors;local wide=W>=600
 local panel=U.Panel(c.Parent,'WorldControls',0,0,W,H)
 U.Round(panel,15);U.Gradient(panel,Color3.fromRGB(255,248,219),Color3.fromRGB(234,220,255))
 local close=U.Button(panel,'Close','×',W-40,6,30,30,c.Close,P.red)
 local info=s.RewardMachineInfo
 if not info then
  U.Text(panel,'Loading your DOG TOKENS…',12,12,W-68,36,20,P.muted)
  if not s.RewardBusy and not s.MachineLoadFailed then s.MachineLoadFailed=true;request(c,'RewardMachineInfo',{},function(v)s.RewardMachineInfo=v;s.MachineLoadFailed=nil end)end
  return
 end
 local total,free,paid,spendable=tokens(info);local buy=canBuy(info)
 local serverNow=workspace:GetServerTimeNow()
 local spinning=(s.WorldSpinUntil or 0)>serverNow;local cooling=(tonumber(info.NextSpinAt)or 0)>c.Now()
 -- Someone else's spin, or a Secret prize still arriving on the stand: the server refuses
 -- a new activation, so the button says why instead of starting a drum it would stop.
 local drumBusy,holdUntil,holdName=rigState();drumBusy=drumBusy and not spinning
 local holding=holdUntil>serverNow
 watch(c);live.Draw=c.Draw
 local ready=total>0 and info.CanSpin~=false and info.InRange~=false and not cooling and not spinning and not s.RewardBusy and not holding and not drumBusy
 local getSpins=total==0 and buy and info.InRange~=false and not spinning and not s.RewardBusy
 U.Text(panel,U.Fmt(total)..(wide and tokenWord(total)or total==1 and' TOKEN'or' TOKENS'),12,wide and 9 or 24,wide and 190 or 131,28,wide and 23 or 18,P.text,true)
 U.Text(panel,'FREE '..free..'/1'..(paid>0 and(' · PAID '..U.Fmt(paid)..(spendable and''or' KEPT'))or''),wide and 12 or 145,wide and 36 or 26,wide and 190 or W-195,23,wide and 15 or 13,P.purple,true)
 local at=tonumber(info.NextFreeTicketAt or info.NextTicketAt)or 0
 local statusText=spinning and'Watch the reward drum!'or holding and(tostring(holdName or'The prize')..' is arriving!')or free>0 and'FREE READY · 1 / 5H'or'Free in '..clockText(at-c.Now())
 local reason=info.CanSpin==false and total>0 and info.UnavailableReason
 local status=U.Text(panel,s.RewardMessage or reason or statusText,12,wide and 63 or 52,wide and 190 or W-24,wide and 23 or 20,13,P.muted)
 if not spinning and not holding and not reason and free==0 and at>0 and not s.RewardMessage then status:SetAttribute('Deadline',at);status:SetAttribute('CountdownStyle','Clock');status:SetAttribute('CountdownPrefix','Free in ')end
 local label=spinning and'ACTIVATING…'or s.RewardBusy and'PLEASE WAIT…'or info.InRange==false and'VISIT DOG-O-MATIC'or getSpins and'GET SPINS'or total==0 and'NO DOG TOKEN'
  or holding and(string.upper(tostring(holdName or'Prize'))..' ARRIVING…')or drumBusy and'DRUM SPINNING…'or cooling and'RESETTING…'or info.CanSpin==false and'UNAVAILABLE'or'ACTIVATE · 1 TOKEN'
 -- The Aurion tile needs ~64 px beside ACTIVATE; narrower rails show it in CHANCES only.
 local jackpot=jackpotRow(info.Rewards);local tile=wide and W>=680 and jackpot~=nil
 local spinX,spinY,spinW,spinH=wide and 214 or 12,wide and 18 or 80,wide and math.min(260,W-452-(tile and 64 or 0))or W-170,wide and 58 or 40
 local spin=U.Button(panel,'Spin',label,spinX,spinY,spinW,spinH,ready and function()
  s.SpinRequest=s.SpinRequest or Http:GenerateGUID(false):gsub('-','')
  local startedAt=beginWorldPrediction(c,s.SpinRequest)
  request(c,'RewardMachineActivate',{Request=s.SpinRequest,StartedAt=startedAt},function(v)
   s.SpinRequest=nil
   for _,key in ipairs({'Tickets','FreeTickets','PaidTickets','NextTicketAt','NextFreeTicketAt','NextSpinAt'})do if v[key]~=nil then info[key]=v[key]end end
   S.PresentWorld(c,v);clearWorldPrediction(c,false)
  end)
 end or getSpins and function()c.Show('TicketShop')end or nil,getSpins and P.gold or P.green)
 spin.Caption.TextSize=wide and 19 or W<320 and 12 or 14
 if tile and jackpot then
  local frame=U.Frame(panel,'AurionJackpot',spinX+spinW+8,6,56,82,NIGHT);U.Round(frame,10);U.Stroke(frame,GOLD,2)
  V.Dog(frame,jackpot.Id or'Aurion',0,0,56,52)
  U.Center(frame,string.upper(tostring(jackpot.Name or'Aurion')),0,50,56,15,11,GOLD,true)
  U.Center(frame,chanceText(jackpot),0,65,56,14,11,Color3.new(1,1,1),true)
  local hit=U.New('TextButton',{Name='ShowJackpot',Text='',BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=8},frame)
  hit.Activated:Connect(function()s.WorldOddsOpen=true;c.Draw()end)
 end
 U.Text(panel,'DOG-O-MATIC',wide and W-222 or 12,wide and 9 or 4,wide and 178 or W-65,wide and 29 or 19,wide and 18 or 13,P.purple,true)
 local odds=U.Button(panel,'Odds','CHANCES',wide and W-222 or W-146,wide and 50 or 80,wide and 85 or 60,wide and 34 or 40,function()s.WorldOddsOpen=not s.WorldOddsOpen;c.Draw()end,P.blue)
 local tickets=U.Button(panel,'TicketShop',salesOpen(info)and'GET SPINS'or'TOKENS',wide and W-129 or W-78,wide and 50 or 80,wide and 113 or 66,wide and 34 or 40,not spinning and function()c.Show('TicketShop')end or nil,P.gold)
 odds.Caption.TextSize=wide and 14 or 10;tickets.Caption.TextSize=wide and 16 or 12
 -- Redraw once the soonest wait is over (cooldown, a prize's arrival).
 local waits={}
 if cooling then table.insert(waits,(tonumber(info.NextSpinAt)or 0)-c.Now())end
 if holding then table.insert(waits,holdUntil-serverNow)end
 wakeIn(#waits>0 and math.min(table.unpack(waits))or nil)
 if c.Gui then
  local old=c.Gui:FindFirstChild('RewardMachineOddsOverlay')
  c.Gui:SetAttribute('RewardMachineOddsOpen',s.WorldOddsOpen==true)
  if s.WorldOddsOpen then
   local _,_,width,height=U.SafeArea(c.Gui);local ow=math.min(460,width-28);local oh=math.min(470,height-28)
   -- Rebuild only when the chances or the size change: the rail redraws every few seconds
   -- and 3D thumbnails should not flicker.
   local key={tostring(ow),tostring(oh)}
   for _,row in ipairs(info.Rewards or{})do table.insert(key,tostring(row.Name)..':'..tostring(row.ChanceUnits or row.Chance))end
   key=table.concat(key,'|')
   if not old or old:GetAttribute('OddsKey')~=key then
    local previous=old and old:FindFirstChild('OddsList',true);local savedScroll=previous and previous.CanvasPosition
    if old then old:Destroy()end
    local overlay=U.New('Frame',{Name='RewardMachineOddsOverlay',Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Active=true,ZIndex=85},c.Gui)
    overlay:SetAttribute('OddsKey',key)
    local window=U.Modal(overlay,'OddsWindow','REWARD CHANCES',ow,oh)
    U.Button(window,'CloseOdds','×',ow-43,18,28,30,function()s.WorldOddsOpen=false;c.Draw()end,P.red)
    local sc=U.Scroll(window,'OddsList',12,75,ow-24,oh-89)
    local y=oddsList(c,sc,info.Rewards,4,ow-36)
    U.Text(sc,'Every activation uses these exact chances, with a free or a paid DOG TOKEN.',6,y+2,ow-48,40,13,P.muted)
    if savedScroll then sc.CanvasPosition=savedScroll end
   end
  elseif old then old:Destroy()end
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
 U.Button(sc,'TicketShop',salesOpen(info)and'GET SPINS'or'DOG TOKEN INFO',8,y,W-24,42,function()c.Show('TicketShop')end,P.gold);y+=49
 if info.InRange==false then U.Button(sc,'FindRewardMachine','FIND DOG-O-MATIC',8,y,W-24,42,function()require(script.Parent.GUIIntegration).Navigate('RewardMachine')end,P.blue);y+=51 end
 local message=s.RewardMessage or info.CanSpin==false and info.UnavailableReason
 if message and message~=''then U.Text(sc,tostring(message),12,y,W-32,48,17,not s.RewardMessage and(total==0 or cooling)and P.muted or P.red);y+=54 end
 U.Text(sc,'YOUR POSSIBLE REWARDS',12,y,W-32,31,24,P.text,true);y+=36
 U.Text(sc,'One DOG TOKEN gives one random reward. Exact chances are shown below.',12,y,W-32,45,16,P.muted);y+=49
 local cols=c.Mobile and 2 or 4;local cw=(W-24-(cols-1)*12)/cols
 for i,row in ipairs(info.Rewards or{})do
  local rarity=prizeRarity(row);local tone=U.Rarity[rarity]or({Cash=P.gold,Bones=P.blue,Boost=P.green})[row.Kind]or P.purple
  local card=U.Panel(sc,'Reward'..i,8+(i-1)%cols*(cw+12),y+math.floor((i-1)/cols)*205,cw,193,true)
  if row.Jackpot then U.Stroke(card,GOLD,4)end
  local art=U.Frame(card,'Art',6,6,cw-12,90,tone:Lerp(Color3.new(1,1,1),.78));U.Round(art,10)
  preview(c,art,row,4,1,cw-20,88)
  U.Center(card,row.Name or row.Kind,7,99,cw-14,34,18,P.text,true)
  U.Center(card,row.Jackpot and'ULTRA RARE JACKPOT'or rarity:upper(),7,136,cw-14,22,14,row.Jackpot and P.gold or P.muted,true)
  local chance=U.Frame(card,'Chance',8,162,cw-16,25,tone);U.Round(chance,7)
  U.Center(chance,chanceText(row),3,0,cw-22,25,18,P.text,true)
 end
end
-- GET SPINS: DOG TOKEN packs (live Roblox prices through ProductPricing), with every chance
-- shown on the same page before anything is bought. Accounts that may not buy paid random
-- items see why instead of a Buy button.
function S.TicketShop(c)
 local info=infoOrLoad(c);if not info then return end
 watch(c)
 local U,W,s=c.U,c.W,c.State;local P=U.Colors
 local sc=U.Scroll(c.Parent,'DogTokenShop',0,0,W,c.H)
 local y=wallet(c,sc,info)
 local _,_,paid=tokens(info)
 U.Text(sc,'GET MORE SPINS',12,y,W-32,40,26,P.purple,true);y+=46
 local jackpot=jackpotRow(info.Rewards)
 if not salesOpen(info)then
  U.Text(sc,'DOG TOKEN sales are paused right now. Your free DOG TOKEN still arrives 5 hours after use'..(paid>0 and', and the paid DOG TOKENS you own are kept.'or'.'),12,y,W-32,66,17,P.text);y+=74
 elseif info.PaidRandomAllowed~=true then
  local note=U.Panel(sc,'PaidUnavailable',8,y,W-24,c.Mobile and 150 or 124);U.Gradient(note,Color3.fromRGB(255,236,240),Color3.fromRGB(255,250,236))
  U.Text(note,'NOT AVAILABLE FOR THIS ACCOUNT',14,8,W-52,28,19,P.red,true)
  U.Text(note,info.PaidRandomRestrictionReason or'Buying paid random items is not available for this account. Your free DOG TOKEN still works.',14,38,W-52,c.Mobile and 104 or 78,15,P.text)
  y+=(c.Mobile and 150 or 124)+12
 else
  -- One line of odds right above the Buy buttons; the full list follows below.
  U.Text(sc,'Same chances for every DOG TOKEN'..(jackpot and(' · '..string.upper(tostring(jackpot.Name))..' JACKPOT '..chanceText(jackpot))or'')..' · all chances below',12,y,W-32,24,15,P.muted,true);y+=30
  local Pricing=require(script.Parent.ProductPricing)
  local rows=info.TicketProducts or{}
  local cols=W>=720 and 3 or W>=470 and 2 or 1;local cw=(W-24-(cols-1)*12)/cols;local ch=226
  -- Per-spin price from the live Roblox price once it is known; the lowest one is marked.
  local per,best={},nil
  for _,row in ipairs(rows)do
   local entry=type(Pricing.Cache)=='table'and Pricing.Cache[row.ProductId]
   local price=type(entry)=='table'and tonumber(entry.Price)
   if price and(tonumber(row.Count)or 0)>0 then per[row]=price/row.Count;if not best or per[row]<per[best]then best=row end end
  end
  for i,row in ipairs(rows)do
   local x=8+(i-1)%cols*(cw+12);local top=y+math.floor((i-1)/cols)*(ch+12)
   local card=U.Panel(sc,'Offer_'..tostring(row.Key),x,top,cw,ch,true)
   U.Icon(card,row.Key or'Ticket',12,10,84)
   local name=U.Text(card,tostring(row.Name or'DOG TOKENS'),104,12,cw-116,34,22,P.text,true);name.TextScaled=true
   U.New('UITextSizeConstraint',{MinTextSize=12,MaxTextSize=22},name)
   U.Text(card,U.Fmt(row.Count or 0)..tokenWord(row.Count or 0)..'\n= '..U.Fmt(row.Count or 0)..((row.Count==1)and' SPIN'or' SPINS'),104,48,cw-116,46,16,P.purple,true)
   U.Center(card,per[row]and(string.format(per[row]<10 and'%.1f'or'%.0f',per[row])..' ROBUX PER SPIN')or'1 SPIN = 1 DOG-O-MATIC ACTIVATION',12,100,cw-24,28,14,P.muted,true)
   if row==best and #rows>1 then U.Stroke(card,GOLD,4);U.Badge(card,'BEST VALUE',(cw-120)/2,132,120,P.gold)end
   local label,action='UNAVAILABLE',nil
   if row.CanPurchase then
    label,action=Pricing.Quote(c,sc,{Key=row.Key,Id=row.ProductId,Enabled=true,Route=row.Route or'RewardMachineProduct',Name=row.Name,Count=row.Count})
   else label=string.upper(tostring(row.UnavailableReason or'Unavailable'))end
   U.Button(card,'Buy',label,12,ch-58,cw-24,46,action,P.green)
  end
  y+=math.ceil(#rows/cols)*(ch+12)
 end
 local message=s.CommerceMessage
 if message and message~=''then U.Text(sc,tostring(message),12,y,W-32,44,16,P.red,true);y+=50 end
 U.Text(sc,'CHANCES FOR EVERY DOG TOKEN',12,y,W-32,34,22,P.text,true);y+=40
 y=oddsList(c,sc,info.Rewards,y,W-24)+6
 U.Text(sc,'The free DOG TOKEN is always used first. One DOG TOKEN = one activation at DOG-O-MATIC PLAZA, with exactly these chances. Paid DOG TOKENS never expire.',12,y,W-32,66,15,P.muted);y+=74
 U.Button(sc,'BackToRewardMachine','BACK TO DOG-O-MATIC',8,y,W-24,45,function()c.Show('RewardMachine')end,P.purple)
end
return S

local RS=game:GetService('ReplicatedStorage');local Run=game:GetService('RunService')
local Catalog=require(RS.CommerceConfig);local Price=require(RS.PriceFormat);local Pricing=require(script.Parent.ProductPricing)
local Plans=require(RS.SupplyPricing);local LuckMath=require(RS.LuckMath);local Config=require(RS.DogEconomy.Config)
local Machine=require(RS.RewardMachineConfig);local Stream=require(RS.LuckyBlockConfig).Stream
local Player=game:GetService('Players').LocalPlayer
local S={Paid={Allowed=nil,At=-1000000,Loading=false}}
-- Dogs per minute on the tongue: one slot every SlotLength*(EmptySlots+1)/Speed seconds,
-- BlockChance of them lucky blocks (world events can change it; the panel shows the norm).
local DOGS_PER_MINUTE=60*Stream.Speed/(Stream.SlotLength*(Stream.EmptySlots+1))*(1-Stream.BlockChance)
local AURION=(function()
 for _,row in ipairs(Machine.Rewards or{})do if row.Id=='Aurion'then return string.format('%.2g%%',100*(row.FixedUnits or 1)/(Machine.OddsDenominator or 10000))end end
 return '0.01%'
end)()
-- Paid random items (DOG-O-MATIC spins) are hidden from accounts where they are restricted;
-- the server's 'Catalog' answer says which (asked again every 2 minutes).
local function paidAllowed(c,parent)
 local paid=S.Paid
 if not paid.Loading and os.clock()-paid.At>120 then
  paid.Loading=true
  task.spawn(function()
   local transport,ok,result=pcall(function()return RS.RewardRequest:InvokeServer('Catalog',{})end)
   paid.Loading=false
   if transport and ok and type(result)=='table'then paid.Allowed=result.PaidAllowed==true;paid.At=os.clock()
   else paid.At=os.clock()-100 end -- ask again in ~20 s
   if parent.Parent then c.Draw()end
  end)
 end
 return paid.Allowed
end
local function tokensUsable(c,parent)return Catalog.SpinsOnSale()and paidAllowed(c,parent)==true end
local function shown(o)
 while o and o~=game do if o:IsA('GuiObject')and not o.Visible then return false end;o=o.Parent end
 return o==game
end
-- SERVER LUCK state as the server publishes it (server clock).
local function luckNow()
 local f=RS:FindFirstChild('DOGROTS_ServerLuck');local now=workspace:GetServerTimeNow()
 local mult=f and tonumber(f:GetAttribute('Multiplier'))or 1;local ends=f and tonumber(f:GetAttribute('EndsAt'))or 0
 local by=f and f:GetAttribute('By');by=type(by)=='string'and by or''
 if mult<=1 or ends<=now then return 1,0,'',f,now end
 return mult,ends,by,f,now
end
local function statusText(mult,ends,by,now)
 if mult<=1 then return 'x1 — NORMAL LUCK'end
 return 'x'..mult..' SERVER LUCK · '..Price.Clock(ends-now)..' LEFT'..(by~=''and' · BOUGHT BY '..by:upper()or'')
end
local function everyText(minutes)
 if minutes==math.huge then return '—'end
 if minutes<10 then return (string.format('~%.1f min',minutes):gsub('%.0 min',' min'))end
 if minutes<90 then return '~'..math.floor(minutes+.5)..' min'end
 local hours=minutes/60
 return hours<10 and(string.format('~%.1f h',hours):gsub('%.0 h',' h'))or'~'..math.floor(hours+.5)..' h'
end
-- How often each rare rank walks the tongue at this server luck (the server rolls exactly
-- these budgets: LuckMath via Engine:LineOdds; THE DOG keeps its unboosted share).
local function tierLines(mult)
 local odds=LuckMath.Odds(Config.Weights,LuckMath.ServerBoost(mult))
 return {{'Legendary',everyText(LuckMath.Every(odds[4],DOGS_PER_MINUTE))},{'Mythic',everyText(LuckMath.Every(odds[5],DOGS_PER_MINUTE))},
  {'Secret',everyText(LuckMath.Every(odds[6],DOGS_PER_MINUTE))}}
end
local function tierTimer(f,m,mult,ends,now)
 if m==mult then return mult==1 and'IN FORCE'or'IN FORCE · '..Price.Clock(ends-now)end
 local tierEnd=f and tonumber(f:GetAttribute('Tier'..m))or 0
 if m>1 and tierEnd>now then return 'ALSO RUNNING · '..Price.Clock(tierEnd-now)end
 return m==1 and'BASELINE'or''
end
-- Long labels shrink to fit instead of spilling over their neighbours.
local function fit(label,max,min)
 label.TextScaled=true;local size=Instance.new('UITextSizeConstraint');size.MaxTextSize=max;size.MinTextSize=min or 9;size.Parent=label
 return label
end
-- The full-width SERVER LUCK panel: what is in force for everyone here, and the five tiers
-- (tiles side by side on a wide window, a list of rows otherwise; button below on a phone).
local function luckPanel(c,sc,x,y,w,list)
 local U=c.U;local P=U.Colors
 local mult,ends,by,f,now=luckNow()
 local narrow=w<520
 local descH=list and(narrow and 72 or 44)or 44
 local top=(list and 72 or 82)+descH+6
 local rowH=narrow and 118 or 84
 local h=list and top+5*rowH+6 or top+248
 local panel=U.Panel(sc,'ServerLuckPanel',x,y,w,h,true)
 U.Gradient(panel,Color3.fromRGB(240,255,226),Color3.fromRGB(255,247,214))
 fit(U.Text(panel,list and'SERVER LUCK FOR EVERYONE'or'SERVER LUCK · FOR EVERYONE IN THIS SERVER',14,6,w-28,list and 28 or 34,list and 20 or 26,P.text,true),list and 20 or 26,12)
 local badge=U.Frame(panel,'LuckStatus',12,list and 38 or 44,w-24,list and 30 or 34,mult>1 and P.green or P.secondary);U.Round(badge,9);U.Stroke(badge,P.edge,2)
 local status=fit(U.Center(badge,statusText(mult,ends,by,now),6,0,w-36,list and 30 or 34,list and 16 or 21,P.text,true),list and 16 or 21,10);status.Name='Status'
 U.Text(panel,list and'Rarer dogs and lucky blocks on the tongue for EVERYONE here. Each purchase adds 30 min to its tier. THE DOG is never boosted.'
  or'Rarer dogs, lucky blocks and variants walk the tongue for EVERYONE here. Each purchase adds 30 min to its tier; the highest tier with time left is in force. THE DOG is never boosted.',
  14,list and 72 or 82,w-28,descH,list and 13 or 15,P.muted)
 local timers={}
 for m=1,5 do
  local row=m>1 and Catalog.ServerLuckRow(m)or nil;local lines=tierLines(m);local current=m==mult
  local tone=m==1 and P.secondary or P.green:Lerp(P.gold,(m-2)/3)
  local label,action
  if row then label,action=Pricing.Quote(c,sc,row)end
  local name=m==1 and'NORMAL · FREE'or row and row.Name:upper()or''
  if list then
   local tile=U.Frame(panel,'Tier'..m,10,top+(m-1)*rowH,w-20,rowH-8,P.panel);U.Round(tile,10);U.Stroke(tile,current and P.gold or P.edge,current and 4 or 2)
   local mark=U.Frame(tile,'Multiplier',8,8,58,narrow and 58 or rowH-24,tone);U.Round(mark,9);U.Center(mark,'x'..m,0,0,58,narrow and 58 or rowH-24,26,P.text,true)
   local bw=narrow and w-20-16 or math.min(170,math.floor((w-20)*.38));local tw=narrow and w-20-84 or w-20-74-bw-18
   fit(U.Text(tile,name,74,4,tw,18,15,P.text,true),15)
   local odds=narrow and lines[2][1]..' '..lines[2][2]..'\n'..lines[3][1]..' '..lines[3][2]or lines[2][1]..' '..lines[2][2]..' · '..lines[3][1]..' '..lines[3][2]
   fit(U.Text(tile,odds,74,narrow and 22 or 25,tw,narrow and 34 or 20,13,P.muted),13)
   local timer=fit(U.Text(tile,tierTimer(f,m,mult,ends,now),74,narrow and 56 or 47,tw,18,13,P.text,true),13)
   table.insert(timers,{Label=timer,Tier=m})
   local button=U.Button(tile,'Buy',m==1 and'ALWAYS ON'or label or'',narrow and 8 or w-20-bw-8,narrow and 74 or(rowH-8-44)/2,bw,narrow and 36 or 44,action,m==1 and P.secondary or P.green)
   button.Caption.TextSize=15
  else
   local tw=(w-24-40)/5
   local tile=U.Frame(panel,'Tier'..m,12+(m-1)*(tw+10),top,tw,236,P.panel);U.Round(tile,12);U.Stroke(tile,current and P.gold or P.edge,current and 4 or 2)
   local mark=U.Frame(tile,'Multiplier',8,8,tw-16,42,tone);U.Round(mark,9);U.Center(mark,'x'..m,0,0,tw-16,42,30,P.text,true)
   fit(U.Center(tile,name,6,54,tw-12,20,14,P.text,true),14)
   U.Center(tile,lines[1][1]..' '..lines[1][2]..'\n'..lines[2][1]..' '..lines[2][2]..'\n'..lines[3][1]..' '..lines[3][2],6,76,tw-12,60,14,P.muted)
   local timer=fit(U.Center(tile,tierTimer(f,m,mult,ends,now),6,140,tw-12,20,14,P.text,true),14)
   table.insert(timers,{Label=timer,Tier=m})
   local button=U.Button(tile,'Buy',m==1 and'ALWAYS ON'or label or'',8,166,tw-16,42,action,m==1 and P.secondary or P.green)
   button.Caption.TextSize=15
   U.Center(tile,m==1 and'Free, all the time'or'+30 MIN · WHOLE SERVER',6,212,tw-12,18,12,P.muted)
  end
 end
 -- Live countdowns; a purchase or an expiry (Revision) redraws the whole panel at once.
 local connections={};local elapsed=1
 local function stop()for _,connection in ipairs(connections)do connection:Disconnect()end;table.clear(connections)end
 table.insert(connections,Run.Heartbeat:Connect(function(dt)
  elapsed+=dt;if elapsed<.25 then return end;elapsed=0
  if not panel.Parent then stop();return end
  if not shown(panel)then return end
  local m,e,b,folder,t=luckNow()
  status.Text=statusText(m,e,b,t)
  for _,timer in ipairs(timers)do timer.Label.Text=tierTimer(folder,timer.Tier,m,e,t)end
 end))
 if f then table.insert(connections,f:GetAttributeChangedSignal('Revision'):Connect(function()if panel.Parent and shown(panel)then c.Draw()end end))end
 panel.Destroying:Connect(stop)
 return h
end
local CONTENT_H={['Starter Packs']=118,Money=70,Spins=70,Supplies=70}
local function lines(row,rate,usable)
 if row.Category=='Spins'then
  return {row.Count..(row.Count==1 and' DOG-O-MATIC SPIN'or' DOG-O-MATIC SPINS'),'= '..Price.Tickets(row.Count),'Can win AURION · '..AURION}
 end
 if row.Supply then
  local def=Config.Supplies[row.Supply]
  return {'+'..Plans.Duration(row.Seconds or def.Seconds)..' '..def.Name:upper(),def.EffectText}
 end
 local plan=Plans.Plan(row,rate,usable)
 local out=Plans.Lines(plan,true)
 if row.Category=='Money'and plan.CashMinutes then table.insert(out,2,Plans.IncomeSpan(plan.CashMinutes)..' OF YOUR INCOME')end
 if (row.Rewards and row.Rewards.Tokens or 0)>0 and not usable then table.insert(out,'(COINS INSTEAD OF SPINS)')end
 return out
end
local function compactText(list)
 local text=table.concat({list[1],list[2]},' · ')
 if #list>2 then text..=' · +'..(#list-2)..' MORE'end
 return text
end
-- DOG-O-MATIC chances, shown before buying a spin (fetched from the server's live pool).
local function chances(c,root)
 local U,s=c.U,c.State;local P=U.Colors
 if not s.SpinChancesOpen then return end
 -- Fresh for a minute; after a failed answer, ask again at most every 5 seconds.
 local age=os.clock()-(s.SpinChancesAt or -1000)
 if(s.SpinChances and age>60 or not s.SpinChances and age>5)and not s.SpinChancesLoading then
  s.SpinChancesLoading=true
  task.spawn(function()
   local transport,ok,result=pcall(function()return RS.RewardRequest:InvokeServer('RewardMachineInfo',{})end)
   s.SpinChancesLoading=false
   if transport and ok and type(result)=='table'then s.SpinChances=result;s.SpinChancesAt=os.clock();s.SpinChancesError=nil
   else s.SpinChancesError=transport and tostring(result)or'Could not load the chances. Try again.';s.SpinChancesAt=os.clock() end
   if root.Parent and shown(root)then c.Draw()end
  end)
 end
 local W,H=c.W,c.H;local ow,oh=math.min(470,W-16),math.min(440,H-16)
 local shade=U.Frame(root,'SpinChances',0,0,W,H,P.edge);shade.BackgroundTransparency=.35;shade.Active=true
 local box=U.Panel(shade,'ChancesWindow',(W-ow)/2,(H-oh)/2,ow,oh)
 U.Text(box,'DOG-O-MATIC CHANCES',14,8,ow-80,36,24,P.text,true)
 U.Button(box,'CloseChances','X',ow-56,8,44,38,function()s.SpinChancesOpen=false;c.Draw()end,P.red)
 U.Text(box,'Every spin is one DOG TOKEN at the DOG-O-MATIC drum. The chances are fixed and the same for everyone; server luck never changes them.',14,48,ow-28,48,14,P.muted)
 local list=U.Scroll(box,'ChanceList',10,100,ow-20,oh-110)
 local info=s.SpinChances
 if not info then U.Text(list,s.SpinChancesError or'Loading chances…',6,6,ow-40,40,17,P.muted)
 else
  for i,row in ipairs(info.Rewards or{})do
   local y=(i-1)*46
   U.Text(list,tostring(row.Name or row.Kind),6,y,ow-150,26,17,row.Jackpot and P.purple or P.text,true)
   U.Text(list,tostring(row.Rarity or row.Kind or''):upper(),6,y+24,ow-150,18,12,P.muted)
   local chance=U.Text(list,string.format('%.4g%%',(tonumber(row.Chance)or 0)*100),ow-140,y,108,40,18,P.purple,true);chance.TextXAlignment=Enum.TextXAlignment.Right
  end
 end
 -- Above every card whatever the GUI's ZIndexBehavior.
 shade.ZIndex=40;for _,o in ipairs(shade:GetDescendants())do if o:IsA('GuiObject')then o.ZIndex+=40 end end
 -- Closing the shop window closes the chances too (the next visit starts on the shop).
 local window=root.Parent and root.Parent.Parent
 if window and window:IsA('GuiObject')then
  local watch=window:GetPropertyChangedSignal('Visible'):Connect(function()if not window.Visible then s.SpinChancesOpen=false end end)
  shade.Destroying:Connect(function()watch:Disconnect()end)
 end
end
function S.Build(c)
 local U,W,H=c.U,c.W,c.H;local P=U.Colors;local root=c.Parent
 local compact=W<620;local short=W>=600 and H<380
 local rate=tonumber(Player:GetAttribute('PriceRate'))or 0
 local usable=tokensUsable(c,root)
 local rows=Catalog.Offers();local groups={}
 for _,row in ipairs(rows)do
  if row.Category~='Spins'or usable then groups[row.Category]=groups[row.Category]or{};table.insert(groups[row.Category],row)end
 end
 local categories={}
 for _,category in ipairs(Catalog.Categories)do if category=='Server Luck'or groups[category]then table.insert(categories,category)end end
 local tabCols=short and #categories+1 or compact and(#categories<=4 and 2 or 3)or #categories
 local tabH=short and 44 or math.ceil(#categories/tabCols)*44
 if not short then
  U.Text(root,compact and'EXTRAS'or'PICK SOMETHING FOR YOUR PACK',8,0,W-164,40,compact and 19 or 27,P.text,true)
  U.Button(root,'Supplies','SUPPLIES',W-145,0,137,38,function()c.Show('Supplies')end,P.green).Caption.TextSize=18
 end
 local top=short and 46 or 50+tabH+44
 local sc=U.Scroll(root,'RobuxCatalog',0,top,W,H-top);sc:SetAttribute('OfferCount',#rows)
 local saved=c.State.CommerceScroll;local sections={};local y=3
 local colors={['Server Luck']=P.green,['Starter Packs']=P.purple,Money=P.gold,Spins=P.blue,Supplies=P.orange}
 for _,category in ipairs(categories)do
  sections[category]=y
  if not short then
   local header=U.Header(sc,'Category_'..category,8,y,W-24,40)
   U.Text(header,category:upper(),12,0,W-48,40,24,P.text,true);y+=52
  end
  if category=='Server Luck'then
   y+=luckPanel(c,sc,8,y,W-24,compact or short or W<860)+14
  else
   local group=groups[category]or{}
   local cols=short and 1 or math.min(#group,math.max(1,math.floor((W-10)/270)))
   local spins=category=='Spins';local contentH=CONTENT_H[category]or 70
   local cw=(W-24-(cols-1)*14)/cols;local cardH=short and 128 or 142+contentH+52+(spins and 40 or 0);local step=cardH+14
   for i,row in ipairs(group)do
    local card=U.Panel(sc,'Offer_'..row.Key,8+(i-1)%cols*(cw+14),y+math.floor((i-1)/cols)*step,cw,cardH,true)
    card:SetAttribute('CommerceOffer',row.Key)
    local label,action=Pricing.Quote(c,sc,row);local text=lines(row,rate,usable)
    local function odds()c.State.SpinChancesOpen=true;c.Draw()end
    if short then
     local art=U.Frame(card,'Art',10,10,108,108,colors[category]);U.Round(art,12);U.Icon(art,row.Key,4,4,100,P.text)
     U.Text(card,row.Name,132,5,cw-144,30,22,P.text,true)
     U.Text(card,compactText(text),132,36,cw-144,36,15,P.text,true)
     local bw=spins and(cw-144-8)*.62 or cw-144
     U.Button(card,'Buy',label,132,76,bw,44,action,colors[category]).Caption.TextSize=19
     if spins then U.Button(card,'Chances','CHANCES',132+bw+8,76,cw-144-bw-8,44,odds,P.purple).Caption.TextSize=15 end
    else
     local art=U.Frame(card,'Art',10,10,cw-20,86,colors[category]);U.Round(art,12)
     U.Icon(art,row.Key,(cw-20-82)/2,2,82,P.text)
     U.Center(card,row.Name,10,102,cw-20,32,23,P.text,true)
     U.Center(card,table.concat(text,'\n'),12,138,cw-24,contentH,category=='Starter Packs'and 16 or 17,P.text,true)
     U.Button(card,'Buy',label,12,142+contentH+4,cw-24,40,action,colors[category]).Caption.TextSize=17
     if spins then U.Button(card,'Chances','VIEW CHANCES',12,142+contentH+50,cw-24,34,odds,P.purple).Caption.TextSize=15 end
    end
   end
   y+=math.ceil(#group/cols)*step+14
  end
 end
 U.Text(sc,'Coin packs follow your income: the exact coins are worked out when Roblox confirms payment. Paid rewards are delivered after Roblox confirms payment.',12,y,W-32,52,16,P.muted)
 local tw=(W-16-(tabCols-1)*8)/tabCols
 for i,category in ipairs(categories)do
  local name=(short or compact)and Catalog.ShortNames[category]or category:upper()
  U.Button(root,'Tab_'..category,name,8+(i-1)%tabCols*(tw+8),(short and 0 or 48)+math.floor((i-1)/tabCols)*44,tw,short and 40 or 36,function()sc.CanvasPosition=Vector2.new(0,sections[category])end,colors[category]).Caption.TextSize=compact and 15 or 18
 end
 if short then U.Button(root,'Supplies','SUPPLIES',8+#categories*(tw+8),0,tw,40,function()c.Show('Supplies')end,P.green)end
 if not short then U.Text(root,c.State.CommerceMessage or'SERVER LUCK, packs and coins · Exact contents · Secure Roblox checkout',8,50+tabH+4,W-24,36,17,P.muted)
 elseif c.State.CommerceMessage then U.Text(sc,c.State.CommerceMessage,12,y+57,W-32,60,18,P.text)end
 if saved then sc.CanvasPosition=saved end
 sc:GetPropertyChangedSignal('CanvasPosition'):Connect(function()c.State.CommerceScroll=sc.CanvasPosition end)
 chances(c,root)
end
return S

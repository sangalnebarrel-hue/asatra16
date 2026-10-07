local RS=game:GetService('ReplicatedStorage');local C=require(RS.DogEconomy.Config)
local Catalog=require(RS.CommerceConfig);local Price=require(RS.PriceFormat);local Pricing=require(script.Parent.ProductPricing)
local Plans=require(RS.SupplyPricing)
local Player=game:GetService('Players').LocalPlayer
local S={}
-- The coin price the server projects (it follows the player's income); computed from the
-- projected PriceRate if the price attribute has not arrived yet.
local function coinPrice(key)
 local v=Player:GetAttribute('SupplyPrice_'..key)
 if type(v)=='number'then return v end
 return Plans.SupplyPrice(key,tonumber(Player:GetAttribute('PriceRate'))or 0)
end
local function luckCard(c,sc,x,y,cw)
 local U=c.U;local P=U.Colors
 local card=U.Panel(sc,'Supply_ServerLuck',x,y,cw,456,true)
 local art=U.Frame(card,'Art',10,10,cw-20,86,P.green);U.Round(art,12);U.Icon(art,'Luck',(cw-20-82)/2,2,82,P.text)
 U.Center(card,'SERVER LUCK',10,103,cw-20,32,25,P.text,true)
 U.Center(card,'x2 to x5 rare dogs for EVERYONE here',12,143,cw-24,39,18,P.text,true)
 U.Center(card,'Lucky Treats are retired. Server luck makes Legendary, Mythic and Secret dogs and rare lucky blocks walk the tongue far more often, for the whole server.',14,184,cw-28,74,15,P.muted)
 local f=RS:FindFirstChild('DOGROTS_ServerLuck');local now=workspace:GetServerTimeNow()
 local mult=f and tonumber(f:GetAttribute('Multiplier'))or 1;local ends=f and tonumber(f:GetAttribute('EndsAt'))or 0
 local active=mult>1 and ends>now
 U.Center(card,'ROBUX · 30 MIN PER PURCHASE',12,266,cw-24,23,15,P.text,true)
 local status=U.Center(card,active and('x'..mult..' ACTIVE · '..Price.Clock(ends-now))or'x1 · NORMAL LUCK',12,294,cw-24,25,18,P.text,true)
 if active then status:SetAttribute('Deadline',ends);status:SetAttribute('CountdownStyle','Clock');status:SetAttribute('CountdownPrefix','x'..mult..' ACTIVE · ')end
 U.Button(card,'OpenServerLuck','SERVER LUCK →',12,328,cw-24,96,function()c.State.CommerceScroll=Vector2.zero;c.Show('Shop')end,P.green).Caption.TextSize=22
 U.Center(card,'Opens the shop at the SERVER LUCK panel',10,429,cw-20,22,15,P.muted)
end
function S.Build(c)
 local U,p,W,H=c.U,c.Snapshot.Profile,c.W,c.H;local P=U.Colors
 local sc=U.Scroll(c.Parent,'SupplyCatalog',0,0,W,H)
 U.Text(sc,Price.Coins(p.Cash),8,0,W-24,32,26,P.text,true)
 U.Text(sc,c.State.CommerceMessage or'Coins add 10 minutes; the price follows your income. Robux adds 30 minutes.',8,37,W-24,50,17,P.muted)
 local styles={EnergySnack={Icon='EnergySnack',Color=P.gold},StorageCrate={Icon='StorageCrate',Color=P.blue}}
 local list=table.clone(C.SupplyShop);table.insert(list,'ServerLuck')
 local cols=math.max(1,math.min(3,math.floor((W-10)/280)));local cw=(W-24-(cols-1)*14)/cols
 for i,key in ipairs(list)do
  local x,y=8+(i-1)%cols*(cw+14),99+math.floor((i-1)/cols)*470
  if key=='ServerLuck'then luckCard(c,sc,x,y,cw)
  else
   local def=C.Supplies[key];local style=styles[key]or{Icon=key,Color=P.green}
   local at=(p.Supplies[key]or 0)+((p.SupplyReserve or{})[key]or 0)
   local remaining=math.max(0,at-c.Now());local full=remaining+def.Seconds>def.MaxSeconds
   local price=coinPrice(key)or def.Cash
   local product=Catalog.Find('Supply'..key)
   local robuxSeconds=product and product.Seconds or def.Seconds
   local robuxFull=remaining+robuxSeconds>Catalog.MaxStoredSupplySeconds
   local card=U.Panel(sc,'Supply_'..key,x,y,cw,456,true)
   local art=U.Frame(card,'Art',10,10,cw-20,86,style.Color);U.Round(art,12);U.Icon(art,style.Icon,(cw-20-82)/2,2,82,P.text)
   U.Center(card,def.Name,10,103,cw-20,32,25,P.text,true)
   U.Center(card,def.EffectText,12,143,cw-24,39,18,P.text,true)
   U.Center(card,def.Description,14,184,cw-28,74,15,P.muted)
   U.Center(card,'COINS +'..Plans.Duration(def.Seconds)..' · ROBUX +'..Plans.Duration(robuxSeconds),12,266,cw-24,23,15,P.text,true)
   local active=U.Center(card,remaining>0 and'ACTIVE · '..Price.Clock(remaining)or'READY TO USE',12,294,cw-24,25,18,P.text,true)
   if remaining>0 then active:SetAttribute('Deadline',at);active:SetAttribute('CountdownStyle','Supply')end
   local canBuy=not c.Busy and not full and p.Cash>=price
   -- ExpectedPrice: the server never charges more than the price shown here.
   local buy=U.Button(card,'BuyCoins','BUY · '..Price.Coins(price),12,328,cw-24,44,canBuy and function()c.Send('Supply',{Kind=key,ExpectedPrice=price})end or nil,style.Color)
   buy.Caption.TextSize=18
   local label,action='ROBUX · COMING SOON',nil
   if product then label,action=Pricing.Quote(c,sc,product)end
   local robux=U.Button(card,'BuyRobux',robuxFull and'ROBUX · '..Plans.Duration(Catalog.MaxStoredSupplySeconds)..' STORED'or label,12,380,cw-24,44,not robuxFull and not c.Busy and action or nil,P.purple);robux.Caption.TextSize=17
   U.Center(card,full and'1 HOUR ACTIVE · ROBUX TIME WAITS IN RESERVE'or p.Cash<price and'Not enough coins'or'Rebuy to extend · 1h active max',10,429,cw-20,22,15,P.muted)
  end
 end
 U.Text(sc,'Buff time continues while you are away. Robux time beyond 1 hour waits in reserve and starts by itself. No random rewards.',8,103+math.ceil(#list/cols)*470,W-24,46,16,P.muted)
end
return S

local RS=game:GetService('ReplicatedStorage');local C=require(RS.DogEconomy.Config)
local Catalog=require(RS.CommerceConfig);local Price=require(RS.PriceFormat);local Pricing=require(script.Parent.ProductPricing)
local S={}
function S.Build(c)
 local U,p,W,H=c.U,c.Snapshot.Profile,c.W,c.H;local P=U.Colors
 local sc=U.Scroll(c.Parent,'SupplyCatalog',0,0,W,H)
 U.Text(sc,Price.Coins(p.Cash),8,0,W-24,32,26,P.text,true)
 U.Text(sc,c.State.CommerceMessage or'Choose coins or Robux. Same effect, same 10 minutes.',8,37,W-24,50,17,P.muted)
 local styles={LuckyTreat={Icon='LuckyTreat',Color=P.green},EnergySnack={Icon='EnergySnack',Color=P.gold},StorageCrate={Icon='StorageCrate',Color=P.blue}}
 local cols=math.max(1,math.min(3,math.floor((W-10)/280)));local cw=(W-24-(cols-1)*14)/cols
 for i,key in ipairs(C.SupplyOrder)do
  local def=C.Supplies[key];local style=styles[key];local at=(p.Supplies[key]or 0)+((p.SupplyReserve or{})[key]or 0)
  local remaining=math.max(0,at-c.Now());local full=remaining+def.Seconds>def.MaxSeconds
  local card=U.Panel(sc,'Supply_'..key,8+(i-1)%cols*(cw+14),99+math.floor((i-1)/cols)*470,cw,456,true)
  local art=U.Frame(card,'Art',10,10,cw-20,86,style.Color);U.Round(art,12);U.Icon(art,style.Icon,(cw-20-82)/2,2,82,P.text)
  U.Center(card,def.Name,10,103,cw-20,32,25,P.text,true)
  U.Center(card,def.EffectText,12,143,cw-24,39,18,P.text,true)
  U.Center(card,def.Description,14,184,cw-28,74,17,P.muted)
  U.Center(card,'10 MINUTES · SAME STRENGTH',12,266,cw-24,23,15,P.text,true)
  local active=U.Center(card,remaining>0 and'ACTIVE · '..Price.Clock(remaining)or'READY TO USE',12,294,cw-24,25,18,P.text,true)
  if remaining>0 then active:SetAttribute('Deadline',at);active:SetAttribute('CountdownStyle','Supply')end
  local canBuy=not c.Busy and not full and p.Cash>=def.Cash
  local buy=U.Button(card,'BuyCoins','BUY · '..Price.Coins(def.Cash),12,328,cw-24,44,canBuy and function()c.Send('Supply',{Kind=key})end or nil,style.Color)
  buy.Caption.TextSize=18
  local product=Catalog.Find('Supply'..key);local label,action=Pricing.Quote(c,sc,product)
  local robux=U.Button(card,'BuyRobux',label,12,380,cw-24,44,not full and not c.Busy and action or nil,P.purple);robux.Caption.TextSize=17
  U.Center(card,full and'1 HOUR STORED · WAIT TO EXTEND'or p.Cash<def.Cash and'Not enough coins'or'Rebuy to extend · 1h max',10,429,cw-20,22,15,P.muted)
 end
 U.Text(sc,'Buff time continues while you are away. No random rewards.',8,103+math.ceil(3/cols)*470,W-24,46,16,P.muted)
end
return S

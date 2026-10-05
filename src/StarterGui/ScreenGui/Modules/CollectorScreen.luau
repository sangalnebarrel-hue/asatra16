local Value=require(game.ReplicatedStorage.ItemValuation)
local Preview=require(script.Parent.PreviewRenderer)
local S={}
function S.Build(c)
 local U,p,W,H=c.U,c.Snapshot.Profile,c.W,c.H;local P=U.Colors
 local sc=U.Scroll(c.Parent,'CollectorContent',0,0,W,H)
 U.Center(sc,'SELL · YOUR YARD COLLECTOR',8,0,W-24,44,26,P.gold,true)
 U.Text(sc,'Sell any owned find instantly. Your collection and discovery records remain after a sale.',12,48,W-32,48,18,P.muted)
 local all={};for uid in pairs(p.Items)do table.insert(all,uid)end;table.sort(all)
 U.Button(sc,'SellAll','SELL ALL FINDS · '..#all,8,105,W-24,45,#all>0 and function()c.Send('BulkSell',{Uids=all})end or nil,P.gold)
 local loot=0;for _,x in pairs(p.Loot)do loot+=x.Value end
 U.Button(sc,'SellOrdinary','SELL ORDINARY LOOT · '..U.Fmt(loot),8,160,W-24,43,loot>0 and function()c.Send('SellLoot',{})end or nil,P.green)
 local y=215
 U.Text(sc,'YOUR FINDS',12,y,W-32,32,23,P.gold,true);y+=40
 local rows={};for _,x in pairs(p.Items)do table.insert(rows,x)end;table.sort(rows,function(a,b)return a.FoundAt>b.FoundAt end)
 for _,x in ipairs(rows)do
  local price=Value.Price(x);local card=U.Panel(sc,'SaleItem',8,y,W-24,112)
  Preview.Item(card,x,5,7,90,94)
  U.Text(card,x.DisplayName..' · '..U.Fmt(price)..' Coins',103,6,W-145,48,18,P.text,true)
  U.Button(card,'SellNow','SELL',103,62,W-145,36,function()c.Send('BulkSell',{Uids={x.ItemUid}})end,P.gold);y+=123
 end
 if #rows==0 then U.Center(sc,'Your dogs will find something worth selling.',12,y,W-32,70,22,P.muted)end
end
return S

-- LUCK: server luck bought with Robux (the whole server's tongue brings rarer dogs).
local RS=game:GetService('ReplicatedStorage')
local Catalog=require(RS.CommerceConfig);local Price=require(RS.PriceFormat);local Pricing=require(script.Parent.ProductPricing)
local S={}
local tierColors={Color3.fromRGB(125,219,48),Color3.fromRGB(38,190,160),Color3.fromRGB(38,164,243),Color3.fromRGB(161,103,242),Color3.fromRGB(247,73,112)}
function S.Build(c)
 local U,p,W,H=c.U,c.Snapshot.Profile,c.W,c.H;local P=U.Colors
 local sc=U.Scroll(c.Parent,'LuckCatalog',0,0,W,H)
 local now=c.Now()
 U.Button(sc,'OpenSupplies','SUPPLIES  ›',W-168,0,152,38,function()c.Show('Supplies')end,P.gold).Caption.TextSize=18
 if c.State.CommerceMessage then U.Text(sc,c.State.CommerceMessage,8,0,W-184,38,16,P.muted)end
 local y=48
 -- Server luck: Robux, for everyone here.
 local header2=U.Header(sc,'ServerLuck',8,y,W-24,40);U.Text(header2,'SERVER LUCK · FOR EVERYONE HERE',12,0,W-48,40,23,P.text,true);y+=50
 local state=RS:FindFirstChild('ServerLuckState')
 local mult=state and state:GetAttribute('Multiplier')or 1;local ends=state and state:GetAttribute('EndsAt')or 0;local by=state and state:GetAttribute('By')or''
 local live=mult>1 and ends>now
 local banner=U.Panel(sc,'ServerLuckStatus',8,y,W-24,60)
 if live then U.Gradient(banner,Color3.fromRGB(205,255,190),Color3.fromRGB(255,240,170))end
 local line=U.Center(banner,live and string.format('x%d SERVER LUCK ACTIVE%s',mult,by~=''and(' · THANKS, '..string.upper(by)..'!')or'')or'No server luck right now · be the hero of this server',12,4,W-48,30,20,P.text,true)
 local clock=U.Center(banner,'',12,32,W-48,24,16,P.muted,true)
 if live then clock:SetAttribute('Deadline',ends);clock:SetAttribute('CountdownStyle','Clock');clock:SetAttribute('CountdownPrefix','ENDS IN ')end
 if not live then line.TextColor3=P.muted end
 y+=72
 local rows={};for _,row in ipairs(Catalog.Offers())do if row.Category=='Server Luck'then table.insert(rows,row)end end
 local cols2=math.max(1,math.min(4,math.floor((W-10)/210)));local cw2=(W-24-(cols2-1)*12)/cols2
 for i,row in ipairs(rows)do
  local reward=row.Rewards.ServerLuck
  local card=U.Panel(sc,'Offer_'..row.Key,8+(i-1)%cols2*(cw2+12),y+math.floor((i-1)/cols2)*262,cw2,250,true)
  card:SetAttribute('CommerceOffer',row.Key)
  if row.Featured then U.Glow(card,P.red)end
  local art=U.Frame(card,'Art',8,8,cw2-16,80,tierColors[math.clamp(reward.Multiplier,1,5)]);U.Round(art,12)
  U.Icon(art,'Luck',8,6,66,P.text)
  local big=U.Text(art,'x'..reward.Multiplier,80,4,cw2-104,72,44,Color3.new(1,1,1),true);big.TextStrokeTransparency=0;big.TextStrokeColor3=P.edge
  U.Center(card,row.Name,8,94,cw2-16,30,21,P.text,true)
  local text=string.format('x%d RARE DOGS FOR EVERYONE\n%d MINUTES',reward.Multiplier,math.floor(reward.Seconds/60))
  if row.Rewards.Luck then text..='\n+ YOUR '..row.Rewards.Luck.Tier..'x LUCK · '..math.floor(row.Rewards.Luck.Seconds/60)..' MIN'end
  U.Center(card,text,8,126,cw2-16,66,15,P.text,true)
  local label,action=Pricing.Quote(c,sc,row)
  U.Button(card,'Buy',label,8,200,cw2-16,40,action,P.purple).Caption.TextSize=16
 end
 y+=math.ceil(#rows/cols2)*262+4
 U.Text(sc,'Server luck multiplies the Legendary, Mythic and Secret odds of every dog and Lucky Block on the tongue for every player on this server. A stronger luck takes over and keeps the weaker one\'s remaining value; world events stack on top. Paid rewards are delivered after Roblox confirms payment.',8,y,W-24,90,15,P.muted)
end
return S

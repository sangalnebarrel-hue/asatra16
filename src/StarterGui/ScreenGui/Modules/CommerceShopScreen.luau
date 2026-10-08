local RS=game:GetService('ReplicatedStorage')
local Catalog=require(RS.CommerceConfig);local Price=require(RS.PriceFormat);local Pricing=require(script.Parent.ProductPricing)
local Boosts=require(RS.DogEconomy.BoostPricing);local Config=require(RS.DogEconomy.Config)
local V=require(script.Parent.PreviewRenderer)
local S={}
local function minutes(seconds)
 local m=math.floor(seconds/60)
 return m>=60 and(m%60==0 and(m/60)..'H'or string.format('%dH %02dM',m//60,m%60))or m..' MIN'
end
-- Exact contents for this player (income-scaled coins are computed from their own snapshot).
local function contents(row,p,now)
 if row.Category=='DOG-O-MATIC Spins'then return Price.Tickets(row.Count)..'\nSpin the DOG-O-MATIC · chances at the machine'end
 local r=row.Rewards or {};local parts={}
 local coins=(r.Cash or 0)+(r.Coins and Boosts.Coins(r.Coins,p,now)or 0)
 if coins>0 then table.insert(parts,'+'..Price.Coins(coins))end
 if r.Bones then table.insert(parts,'+'..Price.Number(r.Bones)..' BONES')end
 if r.ServerLuck then table.insert(parts,'x'..r.ServerLuck.Multiplier..' SERVER LUCK · '..minutes(r.ServerLuck.Seconds))end
 if r.Luck then table.insert(parts,r.Luck.Tier..'x LUCK · '..minutes(r.Luck.Seconds))end
 local supplies={}
 for key,seconds in pairs(r.Supplies or {})do table.insert(supplies,{Config.Supplies[key]and Config.Supplies[key].Name or key,seconds})end
 table.sort(supplies,function(a,b)return a[1]<b[1]end)
 for _,s in ipairs(supplies)do table.insert(parts,string.upper(s[1])..' · '..minutes(s[2]))end
 return table.concat(parts,'\n')
end
function S.Build(c)
 local U,W,H=c.U,c.W,c.H;local P=U.Colors;local root=c.Parent
 local p=c.Snapshot.Profile;local now=c.Now()
 local compact=W<620;local short=W>=600 and H<380
 local tabH=compact and 88 or 44
 if not short then
  U.Text(root,compact and 'EXTRAS'or'PICK SOMETHING FOR YOUR PACK',8,0,W-24,40,compact and 19 or 27,P.text,true)
 end
 local top=short and 46 or 94+tabH
 local rows=Catalog.Offers()
 local sc=U.Scroll(root,'RobuxCatalog',0,top,W,H-top);sc:SetAttribute('OfferCount',#rows)
 local saved=c.State.CommerceScroll;local sections={};local y=3
 local colors={['Starter Packs']=P.purple,['Server Luck']=P.green,['DOG-O-MATIC Spins']=P.red,['Boost Kits']=P.gold,Money=P.gold}
 local categories={}
 for _,category in ipairs(Catalog.Categories)do
  local group={};for _,row in ipairs(rows)do if row.Category==category then table.insert(group,row)end end
  if #group>0 then
   table.insert(categories,category);sections[category]=y
   if not short then
    local header=U.Header(sc,'Category_'..category,8,y,W-24,40)
    U.Text(header,category:upper(),12,0,W-48,40,24,P.text,true);y+=52
   end
   -- The spins section opens with the prize everyone is chasing.
   if category=='DOG-O-MATIC Spins'and not short then
    local prize=U.Panel(sc,'AurionJackpot',8,y,W-24,170,true)
    U.Gradient(prize,Color3.fromRGB(214,240,255),Color3.fromRGB(246,226,255))
    local artW=math.min(220,(W-24)*.4)
    V.Dog(prize,'Aurion',6,6,artW,158)
    U.Text(prize,'JACKPOT: AURION',artW+16,8,W-artW-56,36,24,P.text,true)
    U.Text(prize,'1 in 10,000 every spin · the island-wide arrival is yours. Free tokens are always used first; every chance is shown at the machine (CHANCES).',artW+16,46,W-artW-56,80,15,P.text)
    U.Button(prize,'FindMachine','FIND DOG-O-MATIC',artW+16,124,math.min(240,W-artW-56),36,function()c.Go('RewardMachine')end,P.blue).Caption.TextSize=15
    y+=182
   end
   local cols=short and 1 or math.min(#group,math.max(1,math.floor((W-10)/270)))
   local cw=(W-24-(cols-1)*14)/cols;local cardH=short and 128 or 300;local step=cardH+14
   for i,row in ipairs(group)do
    local card=U.Panel(sc,'Offer_'..row.Key,8+(i-1)%cols*(cw+14),y+math.floor((i-1)/cols)*step,cw,cardH,true)
    card:SetAttribute('CommerceOffer',row.Key)
    if row.Featured then U.Glow(card,P.red)end
    local owned=row.Once and(p.CommercePurchases or {})[row.Alias or row.Key]
    local label,action=Pricing.Quote(c,sc,row)
    if owned then label,action='OWNED',nil end
    local color=colors[category]or P.blue
    if short then
     local art=U.Frame(card,'Art',10,10,108,108,color);U.Round(art,12);U.Icon(art,row.Key,4,4,100,P.text)
     U.Text(card,row.Name,132,5,cw-144,30,22,P.text,true)
     local listed=U.Text(card,contents(row,p,now),132,36,cw-144,36,15,P.text,true)
     listed.TextScaled=true;U.New('UITextSizeConstraint',{MinTextSize=8,MaxTextSize=15},listed)
     U.Button(card,'Buy',label,132,76,cw-144,44,action,color).Caption.TextSize=19
    else
     local art=U.Frame(card,'Art',10,10,cw-20,93,color);U.Round(art,12)
     U.Icon(art,row.Key,(cw-20-86)/2,3,86,P.text)
     if row.Once then U.Badge(card,owned and'OWNED'or'ONE TIME',cw-118,16,100,owned and P.green or P.gold)end
     U.Center(card,row.Name,10,108,cw-20,30,23,P.text,true)
     if row.Blurb then U.Center(card,row.Blurb,10,136,cw-20,22,15,P.muted)end
     -- Up to six reward lines (Pack Captain): scale down rather than spill over the button.
     local listed=U.Center(card,contents(row,p,now),12,160,cw-24,88,15,P.text,true)
     listed.TextScaled=true;U.New('UITextSizeConstraint',{MinTextSize=9,MaxTextSize=15},listed)
     U.Button(card,'Buy',label,12,252,cw-24,40,action,color).Caption.TextSize=17
    end
   end
   y+=math.ceil(#group/cols)*step+14
  end
 end
 U.Text(sc,'Coin amounts grow with your dogs\' income, so every pack stays worth it. Paid rewards are delivered after Roblox confirms payment.',12,y,W-32,48,16,P.muted)
 local cols=short and #categories or compact and 3 or #categories;local tw=(W-16-(cols-1)*8)/math.max(1,cols)
 local shortNames={['Starter Packs']='PACKS',['Server Luck']='SERVER LUCK',['DOG-O-MATIC Spins']='SPINS',['Boost Kits']='KITS',Money='MONEY'}
 for i,category in ipairs(categories)do
  U.Button(root,'Tab_'..category,(short or compact)and shortNames[category]or category:upper(),8+(i-1)%cols*(tw+8),(short and 0 or 48)+math.floor((i-1)/cols)*44,tw,short and 40 or 36,function()sc.CanvasPosition=Vector2.new(0,sections[category])end,colors[category]).Caption.TextSize=compact and 14 or 16
 end
 if not short then U.Text(root,c.State.CommerceMessage or tostring(#rows)..' offers · exact contents · secure Roblox checkout',8,52+tabH,W-24,36,17,P.muted)
 elseif c.State.CommerceMessage then U.Text(sc,c.State.CommerceMessage,12,y+49,W-32,60,18,P.text)end
 local jump=c.State.CommerceJump;c.State.CommerceJump=nil
 if jump and sections[jump]then sc.CanvasPosition=Vector2.new(0,sections[jump])
 elseif saved then sc.CanvasPosition=saved end
 sc:GetPropertyChangedSignal('CanvasPosition'):Connect(function()c.State.CommerceScroll=sc.CanvasPosition end)
end
return S

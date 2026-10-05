local RS=game:GetService('ReplicatedStorage')
local Catalog=require(RS.CommerceConfig);local Price=require(RS.PriceFormat);local Pricing=require(script.Parent.ProductPricing)
local S={}
local function contents(row)
 if row.Category=='Tickets'then return Price.Tickets(row.Count)..'\n1 free DOG TOKEN = 1 activation'end
 if row.Category=='Lucky Block'then return row.Count..' '..row.Tier..' Lucky Block\nAdded to Inventory · open at your yard'end
 local parts={}
 if row.Rewards.Cash then table.insert(parts,Price.Coins(row.Rewards.Cash))end
 if row.Rewards.Bones then table.insert(parts,Price.Number(row.Rewards.Bones)..' BONES')end
 return table.concat(parts,'\n')
end
function S.Build(c)
 local U,W,H=c.U,c.W,c.H;local P=U.Colors;local root=c.Parent
 local compact=W<620;local short=W>=600 and H<380
 local tabH=compact and 88 or 44
 if not short then
  U.Text(root,compact and 'EXTRAS'or'PICK SOMETHING FOR YOUR PACK',8,0,W-164,40,compact and 19 or 27,P.text,true)
  U.Button(root,'Supplies','SUPPLIES',W-145,0,137,38,function()c.Show('Supplies')end,P.green).Caption.TextSize=18
 end
 local top=short and 46 or 94+tabH
 local sc=U.Scroll(root,'RobuxCatalog',0,top,W,H-top);sc:SetAttribute('OfferCount',#Catalog.Offers())
 local saved=c.State.CommerceScroll;local sections={};local y=3;local rows=Catalog.Offers()
 local colors={['Starter Packs']=P.purple,Money=P.gold,Tickets=P.blue,['Lucky Block']=P.red}
 for _,category in ipairs(Catalog.Categories)do
  sections[category]=y
  if not short then
   local header=U.Header(sc,'Category_'..category,8,y,W-24,40)
   U.Text(header,category:upper(),12,0,W-48,40,24,P.text,true);y+=52
  end
  local group={};for _,row in ipairs(rows)do if row.Category==category then table.insert(group,row)end end
  local cols=short and 1 or math.min(#group,math.max(1,math.floor((W-10)/270)))
  local cw=(W-24-(cols-1)*14)/cols;local cardH=short and 128 or 282;local step=cardH+14
  for i,row in ipairs(group)do
   local card=U.Panel(sc,'Offer_'..row.Key,8+(i-1)%cols*(cw+14),y+math.floor((i-1)/cols)*step,cw,cardH,true)
   card:SetAttribute('CommerceOffer',row.Key)
   local label,action=Pricing.Quote(c,sc,row)
   if short then
    local art=U.Frame(card,'Art',10,10,108,108,colors[category]);U.Round(art,12);U.Icon(art,row.Key,4,4,100,P.text)
    U.Text(card,row.Name,132,5,cw-144,30,22,P.text,true)
    U.Text(card,contents(row),132,36,cw-144,36,17,P.text,true)
    U.Button(card,'Buy',label,132,76,cw-144,44,action,colors[category]).Caption.TextSize=19
   else
    local art=U.Frame(card,'Art',10,10,cw-20,93,colors[category]);U.Round(art,12)
    U.Icon(art,row.Key,(cw-20-86)/2,3,86,P.text)
    U.Center(card,row.Name,10,111,cw-20,34,23,P.text,true)
    U.Center(card,contents(row),12,152,cw-24,63,category=='Starter Packs'and 20 or 17,P.text,true)
    U.Button(card,'Buy',label,12,230,cw-24,40,action,colors[category]).Caption.TextSize=17
   end
  end
  y+=math.ceil(#group/cols)*step+14
 end
 U.Text(sc,'Paid rewards are delivered after Roblox confirms payment.',12,y,W-32,43,17,P.muted)
 local cols=short and (#Catalog.Categories+1)or compact and 2 or #Catalog.Categories;local tw=(W-16-(cols-1)*8)/cols
 local shortNames={['Starter Packs']='PACKS',Money='MONEY',Tickets='DOG TOKENS',['Lucky Block']='BLOCKS'}
 for i,category in ipairs(Catalog.Categories)do
  U.Button(root,'Tab_'..category,short and shortNames[category]or category:upper(),8+(i-1)%cols*(tw+8),(short and 0 or 48)+math.floor((i-1)/cols)*44,tw,short and 40 or 36,function()sc.CanvasPosition=Vector2.new(0,sections[category])end,colors[category]).Caption.TextSize=compact and 15 or 18
 end
 if short then U.Button(root,'Supplies','SUPPLIES',8+#Catalog.Categories*(tw+8),0,tw,40,function()c.Show('Supplies')end,P.green)end
 if not short then U.Text(root,c.State.CommerceMessage or tostring(#rows)..' offers · Exact contents · Secure Roblox checkout',8,52+tabH,W-24,36,17,P.muted)
 elseif c.State.CommerceMessage then U.Text(sc,c.State.CommerceMessage,12,y+49,W-32,60,18,P.text)end
 if saved then sc.CanvasPosition=saved end
 sc:GetPropertyChangedSignal('CanvasPosition'):Connect(function()c.State.CommerceScroll=sc.CanvasPosition end)
end
return S

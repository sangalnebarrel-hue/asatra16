local RS=game:GetService('ReplicatedStorage')
local Http=game:GetService('HttpService')
local R=require(script.Parent.Rules)
local D=require(script.Parent.DogDefinitions)
local SRules=require(script.Parent.ShelterRules)
local S={Quotes={}}
local function runtime()return require(script.Parent.Runtime)end
local function describe(d)
 local def=D[d.DogId]
 return {Uid=d.DogUid,DogId=d.DogId,Name=def and def.DisplayName or d.DisplayName,
  Rarity=def and def.Rarity or d.Rarity,Variant=d.Variant,Mastery=d.Mastery or 0,AscensionLevel=d.AscensionLevel or 0,
  Locked=d.Locked==true,Favorite=d.Favorite==true,State=d.State,AssignedSlot=d.AssignedSlot or'',
  Edition=d.Edition,SerialNumber=d.SerialNumber or 0,PaidRandom=d.PaidRandom==true}
end
local function fingerprint(d)
 -- Price rounding can hide changes to mastery, mutation, or other attributes.
 -- The player must confirm the same individual dog and state that were previewed.
 return table.concat({d.DogUid,d.DogId,tostring(d.OwnerUserId),d.Variant or'',tostring(d.Mastery or 0),tostring(d.MasteryXP or 0),
  tostring(d.AscensionLevel or 0),d.Edition or'',tostring(d.SerialNumber or 0),tostring(d.Locked==true),tostring(d.Favorite==true),
  d.State or'',d.AssignedSlot or'',tostring(d.PaidRandom==true)},'|')
end
function S.Visit(player)
 local hub=workspace.DOGROTS_District:FindFirstChild('32_WelcomeHub')
 local building=hub and hub:FindFirstChild('DogShelter')
 R.Check(building and require(script.Parent.YardCommerce).Near(player,building.SellAnchor,18),'Visit the reception inside Dog Shelter')
end
function S.Request(player,action,a)
 local rt=runtime()
 R.Check(rt.Ready(player)and rt.Allow(player,1),'Please wait for your profile')
 R.Check(type(action)=='string'and type(a)=='table','Invalid request')
 S.Visit(player)
 if action=='List'then
  local p=rt.Engine:Get(player.UserId);local rows={}
  for uid,d in pairs(p.Dogs)do
   local ok,reason=SRules.Eligible(p,uid,rt.Engine.TradeByUser[player.UserId])
   local row=describe(d);row.Price=SRules.Price(d,D,R.Bonus);row.Eligible=ok;row.Reason=reason;table.insert(rows,row)
  end
  table.sort(rows,function(a,b)if a.Eligible~=b.Eligible then return a.Eligible end;if a.Price~=b.Price then return a.Price<b.Price end;return a.Uid<b.Uid end)
  return true,{Rows=rows,Rate=SRules.Rate}
 elseif action=='Quote'then
  local p=rt.Engine:Get(player.UserId);local ok,reason=SRules.Eligible(p,a.Uid,rt.Engine.TradeByUser[player.UserId]);R.Check(ok,reason)
  local d=p.Dogs[a.Uid];local q=describe(d)
  q.Token=Http:GenerateGUID(false):gsub('-','');q.Price=SRules.Price(d,D,R.Bonus);q.Expires=os.time()+45;q.Fingerprint=fingerprint(d)
  S.Quotes[player.UserId]=q;local preview=R.Copy(q);preview.Fingerprint=nil;return true,preview
 elseif action=='Sell'then
  R.Check(type(a.Token)=='string'and #a.Token==32 and a.Token:match('^%x+$'),'Invalid confirmation')
  local receipt='sh:'..player.UserId..':'..a.Token:sub(1,26)
  local ok,result=rt.Tx:Run({'p:'..player.UserId},function(v)
   S.Visit(player)
   local q=S.Quotes[player.UserId];R.Check(q and q.Token==a.Token and os.time()<=q.Expires,'Confirmation expired; choose the dog again')
   local p=v['p:'..player.UserId];rt.Engine:Authorize(p,player.UserId)
   local valid,reason=SRules.Eligible(p,q.Uid,rt.Engine.TradeByUser[player.UserId]);R.Check(valid,reason)
   R.Check(fingerprint(p.Dogs[q.Uid])==q.Fingerprint,'Dog changed; review this dog again before selling')
   R.Check(SRules.Price(p.Dogs[q.Uid],D,R.Bonus)==q.Price,'Dog changed; request a new price')
   p.Dogs[q.Uid]=nil;R.Credit(p,q.Price);R.Validate(p)
   return {Message=q.Name..' found a new home! +'..q.Price..' Coins',Cash=q.Price,Uid=q.Uid}
  end,receipt)
  if ok then S.Quotes[player.UserId]=nil;rt.Refresh(player)end
  return ok,result
 end
 return false,'Unknown shelter action'
end
game:GetService('Players').PlayerRemoving:Connect(function(player)S.Quotes[player.UserId]=nil end)
return S

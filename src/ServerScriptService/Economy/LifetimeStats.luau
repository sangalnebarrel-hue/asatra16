-- Pure server-side accounting. Called inside the existing profile transactions.
local S={Fields={'TotalPlaytimeSeconds','TotalCoinsEarned','GlobalDigContribution','SupportRobux'}}
local LIMIT=9000000000000000
function S.Normalize(p)
 p.Lifetime=p.Lifetime or {}
 for _,key in ipairs(S.Fields)do
  local v=p.Lifetime[key]
  if type(v)~='number' or v~=v or v<0 or v==math.huge then v=0 end
  p.Lifetime[key]=math.clamp(math.floor(v or 0),0,LIMIT)
 end
 return p.Lifetime
end
function S.Add(p,key,amount)
 assert(table.find(S.Fields,key),'Unknown lifetime statistic')
 assert(type(amount)=='number' and amount==amount and amount>=0 and amount<math.huge,'Invalid statistic')
 local s=S.Normalize(p);s[key]=math.min(LIMIT,s[key]+math.floor(amount))
end
function S.Checkpoint(p,now)
 local session=p.Session;if not session then return end
 local at=session.StatsAt or now
 -- Expired/crashed sessions never accumulate offline time.
 local untilTime=math.min(now,session.Expires or now)
 S.Add(p,'TotalPlaytimeSeconds',math.max(0,untilTime-at))
 session.StatsAt=math.max(at,untilTime)
end
function S.Count(book)
 local n=0;for _,v in pairs(book or {})do if v then n+=1 end end;return n
end
function S.Value(p,category)
 if category=='Discoveries'then return S.Count(p.Collection)end
 if category=='Dogs'then return S.Count(p.DogDex)end
 local fields={Supporters='SupportRobux',Playtime='TotalPlaytimeSeconds',Coins='TotalCoinsEarned',GlobalDig='GlobalDigContribution'}
 return S.Normalize(p)[fields[category]]or 0
end
return S

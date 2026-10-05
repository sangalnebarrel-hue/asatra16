-- Additive statistics. Old profiles keep their collection; unavailable history is not invented.
local S={Milestones={25,50,100,250,500,1000,2500}}
function S.Normalize(p)
 p.Stats=p.Stats or {Since=os.time(),TotalFinds=0,TotalDigs=0,SecretFinds=0,TotalSellValue=0,BiggestSale=0,BestTier=0,LongestStreak=0,Streak=0,SessionFinds=0,BestSession=0,DayFinds=0,BestDayCount=0,CompletedTrades=0,Depths={},Milestones={},Claims={}}
 return p.Stats
end
local function summary(x)return {ItemId=x.ItemId,ItemUid=x.ItemUid,DisplayName=x.DisplayName,WeightKg=x.WeightKg,WeightTier=x.WeightTier,TierIndex=x.TierIndex,Mutation=x.Mutation,BaseWeightKg=x.BaseWeightKg,Class=x.Class,Depth=x.Depth,FoundAt=x.FoundAt,CombinedOdds=x.CombinedOdds,SellValue=x.SellValue}end
function S.Find(p,x)
 local s=S.Normalize(p)
 local category=(x.Class=='Artifact'or x.Class=='Special'or x.Class=='Secret')and 'BestShowcaseRelic'or 'BestShowcaseFind'
 if not s[category]or(x.SellValue or 0)>(s[category].SellValue or 0)then s[category]=summary(x)end
 s.TotalFinds+=1;s.SessionFinds+=1;s.BestSession=math.max(s.BestSession,s.SessionFinds);s.SecretFinds+=x.Class=='Secret'and 1 or 0;s.BestTier=math.max(s.BestTier,x.TierIndex)
 local day=math.floor(x.FoundAt/86400);if s.Day~=day then s.Day=day;s.DayFinds=0 end;s.DayFinds+=1
 if s.DayFinds>s.BestDayCount then s.BestDayCount=s.DayFinds;s.BestDay=day*86400 end
 for _,pair in ipairs({{'Heaviest','WeightKg'},{'MostValuable','SellValue'},{'Rarest','CombinedOdds'}})do if not s[pair[1]]or x[pair[2]]>s[pair[1]][pair[2]]then s[pair[1]]=summary(x)end end
 local key=tostring(x.Depth);local d=s.Depths[key]or {Finds=0,BestWeight=0,BestValue=0};s.Depths[key]=d;d.Finds+=1;d.BestValue=math.max(d.BestValue,x.SellValue)
 if x.WeightKg>d.BestWeight then d.BestWeight=x.WeightKg;d.Item=summary(x)end
 for _,n in ipairs(S.Milestones)do if s.TotalFinds>=n and not s.Milestones[tostring(n)]then s.Milestones[tostring(n)]=x.FoundAt end end
end
function S.Dig(p,now)local s=S.Normalize(p);s.TotalDigs+=1;s.Streak=s.LastDig and now-s.LastDig<=120 and s.Streak+1 or 1;s.LastDig=now;s.LongestStreak=math.max(s.LongestStreak,s.Streak)end
function S.Sale(p,value)local s=S.Normalize(p);s.TotalSellValue+=value;s.BiggestSale=math.max(s.BiggestSale,value)end
return S

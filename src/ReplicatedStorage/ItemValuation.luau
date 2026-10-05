local RS=game:GetService('ReplicatedStorage')
local C=require(RS.ItemValueConfig);local D=require(RS.DogEconomy.ItemDefinitions);local Depth=require(RS.DogEconomy.DepthDefinitions)
local V={}
function V.Price(x)
 local d=D[x.ItemId];assert(d,'Unknown item')
 local rarity='Common';local rarityMultiplier=1
 if d.Class=='Secret'then rarity='Secret';rarityMultiplier=C.SecretMultiplier
 else for _,row in ipairs(C.Rarity)do if d.BaseDropChance<=row.MaxChance then rarity=row.Name;rarityMultiplier=row.Multiplier;break end end end
 local ratio=math.max(.00001,(x.WeightKg or d.BaseWeightKg)/d.BaseWeightKg)
 local weight=(C.WeightTier[math.clamp(x.TierIndex or 3,1,10)]or 1)*math.clamp(ratio^C.WeightExponent,C.WeightMin,C.WeightMax)
 local event=x.EventTag or (type(x.Origin)=='string'and x.Origin:match('^WorldEvent:(.+)$'))
 local factors={Base=d.BaseValue,Rarity=rarityMultiplier,Depth=C.Depth[d.Depth]or 1,Weight=weight,Mutation=C.Mutation[string.upper(x.Mutation or 'NORMAL')]or 1,Event=event and (C.Events[event]or C.EventDefault)or 1,Bonus=(x.FirstFind and C.FirstFind or 1)*(1+math.clamp(x.SellBonus or 0,0,C.MaxEarnedBonus))*C.Seasonal}
 local raw=factors.Base*factors.Rarity*factors.Depth*factors.Weight*factors.Mutation*factors.Event*factors.Bonus
 local cap=Depth[tostring(d.Depth)].IncomeReference*3600*C.SoftCapIncomeHours
 local threshold=cap*C.SoftCapStart
 local result=raw<=threshold and raw or threshold+(cap-threshold)*(1-math.exp(-(raw-threshold)/(cap-threshold)))
 return math.max(1,math.floor(result)),{Version=C.Version,Rarity=rarity,Factors=factors,Raw=raw,Cap=cap}
end
return V

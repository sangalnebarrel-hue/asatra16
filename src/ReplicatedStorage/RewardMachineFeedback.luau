-- Presentation metadata only. This never changes a reward, its chance or its delivery.
local Definitions=require(game.ReplicatedStorage.DogEconomy.DogDefinitions)
local F={}
-- Presentation intensity is independent of the catalog's six-tier index.
local rarityIntensity={Common=1,Rare=3,Epic=4,Legendary=5,Mythic=6,Secret=8}
function F.Rank(result)
 local dog=result.Dog
 if dog then
  local def=Definitions[dog.DogId]
  return math.max(rarityIntensity[def and def.Rarity or dog.Rarity]or 1,({Shiny=2,Golden=3,Corrupted=4,Glitched=6,Void=7})[dog.Variant]or 1)
 end
 local item=result.Item
 if item then return ({Treasure=1,Artifact=4,Special=5,Secret=8})[item.Class]or 1 end
 return 1
end
function F.Color(rank)
 if rank>=7 then return Color3.fromRGB(219,175,255)
 elseif rank>=5 then return Color3.fromRGB(255,208,105)
 elseif rank>=4 then return Color3.fromRGB(183,133,240)
 elseif rank>=3 then return Color3.fromRGB(116,195,244)
 else return Color3.fromRGB(255,224,166)end
end
return F

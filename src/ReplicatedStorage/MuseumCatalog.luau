-- Presentation binding only. Canonical roster, discovery and reward rules remain unchanged.
local Definitions=require(game.ReplicatedStorage.DogEconomy.DogDefinitions)
local C={ByIndex={},MaxNearModels=18,NearDistance=43,FarDistance=210}
-- Captions only; ability IDs, strength and effects come from the canonical roster.
C.AbilityLabels={GoldLoot='GOLD LOOT',DigSpeed='DIG SPEED',Cooldown='RECOVERY',Night='NIGHT',Recovery='RECOVERY',Divine='DIVINE'}
function C.AbilityLabel(id)return C.AbilityLabels[id]or(id:gsub('(%l)(%u)','%1 %2'):upper())end
for id,def in pairs(Definitions)do
 if not def.MuseumExcluded then
 assert(type(def.Index)=='number'and def.Index>=1 and def.Index<=100 and not C.ByIndex[def.Index],'Duplicate museum index')
 C.ByIndex[def.Index]=def
 end
end
for i=1,100 do assert(C.ByIndex[i],'Missing museum entry '..i)end
function C.Discovered(profile,index)
 local def=C.ByIndex[index]
 return def~=nil and profile~=nil and profile.DogDex~=nil and profile.DogDex[def.Id]~=nil
end
function C.Displayable(profile,index,templates)
 local def=C.ByIndex[index]
 return C.Discovered(profile,index)and def.Available==true and not def.Reserved and def.VisualAsset~=''and templates:FindFirstChild(def.VisualAsset)~=nil
end
function C.State(profile,templates)
 local state={Entries={},Count=0,Rarities={}}
 for i=1,100 do
  local def=C.ByIndex[i];local discovered=C.Discovered(profile,i)
  -- Count the permanent canonical history, never inventory quantity or unknown IDs.
  if discovered and not def.Reserved then state.Count+=1;state.Rarities[def.Rarity]=(state.Rarities[def.Rarity]or 0)+1 end
  if C.Displayable(profile,i,templates)then state.Entries[tostring(i)]={Id=def.Id,Name=def.DisplayName,Rarity=def.Rarity,Ability=def.Ability,VisualAsset=def.VisualAsset}end
 end
 return state
end
return C

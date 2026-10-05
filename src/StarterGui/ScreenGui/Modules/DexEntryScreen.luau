local V=require(script.Parent.PreviewRenderer);local Catalog=require(game.ReplicatedStorage.MuseumCatalog)
local S={}
function S.Build(c)
 local U,root,W,H=c.U,c.Parent,c.W,c.H;local P=U.Colors
 local index=math.clamp(tonumber(c.State.SelectedDexIndex)or 1,1,100)
 local Definitions=require(game.ReplicatedStorage.DogEconomy.DogDefinitions)
 local bonusId=type(c.State.SelectedDexBonus)=='string'and c.State.SelectedDexBonus or nil
 local bonus=bonusId and Definitions[bonusId]and Definitions[bonusId].MuseumExcluded==true
 local def=bonus and Definitions[bonusId]or Catalog.ByIndex[index]
 local discovered=def and c.Snapshot.Profile.DogDex[def.Id]==true
 local known=bonus and def or def and c.Snapshot.Dex[def.Id]
 local templates=game.ReplicatedStorage:WaitForChild('MenuModels');known=known and templates:FindFirstChild(known.VisualAsset)and known
 U.Button(root,'BackToDex','CLOSE ENTRY',0,0,math.min(180,W*.42),42,function()c.Close()end,P.blue)
 U.Center(root,bonus and'EXCLUSIVE BONUS'or string.format('EXHIBIT #%03d',index),W*.45,0,W*.55-8,42,21,P.text,true)
 local scroll=U.Scroll(root,'MuseumEntryDetail',0,56,W,H-56)
 local card=U.Panel(scroll,'ExhibitPortrait',0,0,W,math.min(380,H*.54),true);local ph=math.min(380,H*.54)
 if known then V.Dog(card,known.Id,10,8,W-20,ph-18)
 elseif def and templates:FindFirstChild(def.VisualAsset or '')then V.Dog(card,def.Id,10,8,W-20,ph-18,true)
 else U.Icon(card,'Dogs',W/2-75,40,150,Color3.fromRGB(13,15,23));U.Center(card,'?',0,95,W,110,72,P.gold,true)end
 local y=ph+15
 U.Center(scroll,known and known.DisplayName or '???',0,y,W,46,30,P.gold,true);y+=52
 U.Center(scroll,discovered and 'DISCOVERED PERMANENTLY' or bonus and 'DOG-O-MATIC EXCLUSIVE · NOT YET FOUND' or 'NOT YET DISCOVERED',0,y,W,30,18,P.muted,true);y+=40
 if known then
  U.Badge(scroll,known.Rarity,10,y,W-30,U.Rarity[known.Rarity]);y+=44
  U.Text(scroll,'ABILITY · '..Catalog.AbilityLabel(known.Ability),12,y,W-32,60,22,P.text,true);y+=68
  if known.Signature then U.Text(scroll,known.Signature,12,y,W-32,112,20,P.text);y+=120 end
  U.Text(scroll,bonus and'An exclusive DOG-O-MATIC reward. Bonus dogs are tracked separately from the original 100 museum discoveries.'or'A permanent entry in the Hall of Good Boys. This discovery stays in your collection even after this dog leaves your inventory.',12,y,W-32,110,20,P.muted);y+=118
  local owned,best=0,0;for _,d in pairs(c.Snapshot.Profile.Dogs)do if d.DogId==known.Id then owned+=1;best=math.max(best,d.Mastery or 0)end end
  U.Text(scroll,owned>0 and('IN YOUR INVENTORY  '..owned..'   ·   BEST CURRENT MASTERY  '..best)or discovered and 'DISCOVERED · NOT CURRENTLY IN INVENTORY'or 'FOUND EXCLUSIVELY IN DOG-O-MATIC',12,y,W-32,48,18,P.gold,true)
 else U.Text(scroll,'Discover this dog to reveal its identity, rarity and ability. Every new discovery is registered automatically.',12,y,W-32,95,21,P.muted)end
end
return S

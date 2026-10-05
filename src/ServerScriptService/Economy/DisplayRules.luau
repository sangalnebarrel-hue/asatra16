-- Persist only owned DogUid references; presentation never grants or equips dogs.
local D={Slots=3}
function D.Normalize(p)
 local clean,seen={},{}
 for i=1,D.Slots do
  local uid=type(p.DisplayDogs)=='table'and p.DisplayDogs[tostring(i)]
  local dog=type(uid)=='string'and p.Dogs[uid]
  if dog and dog.OwnerUserId==p.UserId and dog.DogUid==uid and dog.State~='Walking'and not seen[uid]then
   clean[tostring(i)]=uid;seen[uid]=true
  end
 end
 p.DisplayDogs=clean
end
function D.Assign(p,a)
 assert(type(a.Slot)=='number'and a.Slot%1==0 and a.Slot>=1 and a.Slot<=D.Slots,'Choose display slot 1–3')
 assert(type(a.Uid)=='string'and #a.Uid<=100,'Invalid dog')
 D.Normalize(p)
 if a.Uid==''then p.DisplayDogs[tostring(a.Slot)]=nil;return 'Display slot cleared'end
 local dog=p.Dogs[a.Uid]
 assert(dog and dog.OwnerUserId==p.UserId and dog.DogUid==a.Uid,'Choose a dog you own')
 assert(dog.State~='Walking','Wait for your dog to arrive')
 local def=require(game.ReplicatedStorage.DogEconomy.DogDefinitions)[dog.DogId]
 local template=def and game.ServerStorage.DogTemplates:FindFirstChild(def.VisualAsset or dog.DogId)
 assert(template and template:IsA('Model')and template:FindFirstChild('RootPart',true),'This dog display asset is unavailable')
 for slot,uid in pairs(p.DisplayDogs)do if uid==a.Uid then p.DisplayDogs[slot]=nil end end
 p.DisplayDogs[tostring(a.Slot)]=a.Uid
 return dog.DisplayName..' placed in display '..a.Slot
end
return D

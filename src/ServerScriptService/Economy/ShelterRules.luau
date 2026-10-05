-- Pure validation: prices come from the catalog, never from the client or resale history.
local S={Rate=.25}
function S.Eligible(p,uid,trading)
 local d=type(uid)=='string'and p.Dogs[uid]
 if not d or d.OwnerUserId~=p.UserId or d.DogUid~=uid then return false,'Dog not owned'end
 if trading then return false,'Finish your trade first'end
 if d.Locked then return false,'Unlock this dog first'end
 if d.State~='Inventory' then return false,'Wait for delivery or remove this dog from work'end
 if (d.AssignedSlot or '')~=''then return false,'Remove this dog from its kennel first'end
 for _,shown in pairs(p.DisplayDogs or{})do if shown==uid then return false,'Remove this dog from its display first'end end
 for key,list in pairs(p.Listings or{})do if key==uid or type(list)=='table'and list.DogUid==uid then return false,'Cancel the marketplace listing first'end end
 if p.Reservations and p.Reservations[uid]then return false,'Dog is reserved'end
 return true
end
function S.Price(d,definitions,bonus)
 local def=definitions[d.DogId]
 assert(def and type(def.BasePrice)=='number','Unknown dog')
 return math.max(1,math.floor(def.BasePrice*S.Rate*bonus(d)))
end
return S

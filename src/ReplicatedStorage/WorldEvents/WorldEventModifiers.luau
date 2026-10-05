local C=require(script.Parent.WorldEventConfig);local D=require(script.Parent.WorldEventDefinitions)
local M={Current=nil,EndsAt=0}
function M.Set(id,endsAt)M.Current=id;M.EndsAt=endsAt or 0 end
function M.Active(now)return M.Current and now<M.EndsAt and D.ById[M.Current]or nil end
function M.Resolve(p,e,now,dogs)
 local def=M.Active(now);if not def then return e end
 for k,v in pairs(def.GameplayModifiers)do if type(v)=='number'then e[k]=(e[k]or 0)+v end end
 for _,dog in pairs(p.Dogs)do if dog.AssignedSlot~=''and dog.State~='Walking'then
  local d=dogs[dog.DogId];local synergy=d and d.EventSynergies and d.EventSynergies[def.Id]
  for k,v in pairs(synergy or {})do e[k]=(e[k]or 0)+v end
 end end
 for key,cap in pairs(C.ModifierCaps)do if e[key]then e[key]=math.clamp(e[key],0,cap)end end
 e.EventId=def.Id;e.EventDepth=def.Depth;e.EventDepthLuck=def.DepthLuck or 0
 return e
end
function M.MutationRows(base,nameKey,weightKey,now)
 local def=M.Active(now);if not def then return base end
 local rows={};local extra=0
 for i,row in ipairs(base)do local n={};for k,v in pairs(row)do n[k]=v end
  if i>1 then local mult=math.clamp((def.Mutations or {})[row[nameKey]]or 1,1,C.ModifierCaps.Mutation);n[weightKey]=row[weightKey]*mult;extra+=n[weightKey]-row[weightKey]end
  rows[i]=n
 end
 rows[1][weightKey]=math.max(0,rows[1][weightKey]-extra);return rows
end
return M

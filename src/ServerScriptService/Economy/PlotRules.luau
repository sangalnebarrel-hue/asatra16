local C=require(game.ReplicatedStorage.PlotCatalog)
local S={}
local function check(ok,message)if not ok then error(message,0)end end
function S.Normalize(p)
 p.Upgrades=p.Upgrades or {}
 p.PlotSkins=p.PlotSkins or {Classic=true};p.PlotSkins.Classic=true
 if not p.PlotProgressionVersion then
  -- Existing working dogs are never evicted by the new progression gate.
  local highest=1
  for _,d in pairs(p.Dogs or {})do highest=math.max(highest,tonumber((d.AssignedSlot or ''):match('^DigSlot_(%d+)$'))or 1)end
  p.Upgrades.Plot=math.max(p.Upgrades.Plot or 0,math.min(highest,5)-1)
  local legacy={GoldenKennel='GoldenHour',CyberKennel='DogRush',VoidAura='TheVoid'}
  for old,id in pairs(legacy)do if (p.Cosmetics or {})[old]then p.PlotSkins[id]=true end end
  p.EquippedPlotSkin=legacy[p.EquippedCosmetic]or 'Classic'
  p.PlotProgressionVersion=1
 end
 if not C.Skins[p.EquippedPlotSkin]or not p.PlotSkins[p.EquippedPlotSkin]then p.EquippedPlotSkin='Classic'end
end
function S.Action(p,action,a)
 if action~='BuyPlotSkin'and action~='ClaimPlotSkin'and action~='EquipPlotSkin'then return end
 check(type(a.Id)=='string'and C.Skins[a.Id]~=nil,'Unknown plot skin')
 S.Normalize(p);local d=C.Skins[a.Id]
 if action=='EquipPlotSkin'then check(p.PlotSkins[a.Id],'Unlock this skin at COSMETICS first')
 elseif not p.PlotSkins[a.Id]then
  if action=='ClaimPlotSkin'then check(C.Earned(p,a.Id),'Reward locked: '..C.Requirement(p,a.Id))
  else check(d.Cash~=nil,'Secret skins are earned through achievements');check(p.Cash>=d.Cash,'Not enough Cash');p.Cash-=d.Cash end
  p.PlotSkins[a.Id]=true
 end
 p.EquippedPlotSkin=a.Id
 return d.Name..' equipped on your entire yard'
end
function S.Assign(p,slot)
 local i=type(slot)=='string'and tonumber(slot:match('^DigSlot_([1-5])$'))
 check(i and i<=C.Slots(p),'This kennel is locked. Upgrade your yard at the workshop.')
end
function S.Validate(p)
 check(type(p.PlotSkins)=='table'and C.Skins[p.EquippedPlotSkin]and p.PlotSkins[p.EquippedPlotSkin],'Invalid plot cosmetics')
 for _,d in pairs(p.Dogs or {})do if (d.AssignedSlot or '')~=''then S.Assign(p,d.AssignedSlot)end end
end
return S

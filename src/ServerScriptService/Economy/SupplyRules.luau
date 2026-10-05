-- Buff strength stays in Config; one timestamp per effect, never duplicate strength.
local C=require(game.ReplicatedStorage.DogEconomy.Config)
local S={}
function S.Normalize(p,now)
 p.Supplies=p.Supplies or{};p.SupplyReserve=p.SupplyReserve or{}
 for key,def in pairs(C.Supplies)do
  local reserve=p.SupplyReserve[key]or 0
  if reserve>0 then
   -- A receipt can arrive after another purchase filled the one-hour active cap.
   -- Retain all paid seconds in the same profile, automatically feeding the timer.
   -- Both active and reserved time count down offline, like existing supplies.
   local finish=(p.Supplies[key]or now)+reserve
   p.Supplies[key]=math.max(now,math.min(finish,now+def.MaxSeconds))
   p.SupplyReserve[key]=math.max(0,finish-p.Supplies[key])
  end
 end
end
function S.EndAt(p,key)return(p.Supplies[key]or 0)+((p.SupplyReserve or{})[key]or 0)end
function S.CanAdd(p,key,now)
 local def=C.Supplies[key];return def~=nil and math.max(now,S.EndAt(p,key))+def.Seconds<=now+def.MaxSeconds
end
function S.AddPaid(p,key,now)
 S.Normalize(p,now);local def=assert(C.Supplies[key],'Unknown supply')
 local finish=math.max(now,S.EndAt(p,key))+def.Seconds
 p.Supplies[key]=math.min(finish,now+def.MaxSeconds)
 p.SupplyReserve[key]=math.max(0,finish-p.Supplies[key])
 return finish
end
return S

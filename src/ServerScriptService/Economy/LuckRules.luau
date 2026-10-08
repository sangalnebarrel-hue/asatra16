-- Personal luck tiers (LUCK tab). One expiry per tier, saved in the profile; the highest
-- active tier is the one that counts, so a short 5x on top of a long 1x falls back to 1x.
local C=require(script.Parent.Config)
local L={}
function L.Normalize(p,now)
 local boosts=type(p.LuckBoosts)=='table'and p.LuckBoosts or {}
 for key,at in pairs(boosts)do
  if not C.LuckTiers[tonumber(key)or 0]or type(at)~='number'or at<=now then boosts[key]=nil end
 end
 p.LuckBoosts=boosts
 return boosts
end
-- Highest active tier (0 = none) and when it ends.
function L.Active(p,now)
 local best,ends=0,0
 for key,at in pairs(p.LuckBoosts or {})do
  local tier=tonumber(key)
  if tier and type(at)=='number'and at>now and tier>best then best,ends=tier,at end
 end
 return best,ends
end
function L.Bonus(p,now)
 local tier=L.Active(p,now);local def=C.LuckTiers[tier]
 return def and def.Bonus or 0
end
function L.EndAt(p,tier)return (p.LuckBoosts or {})[tostring(tier)]or 0 end
function L.CanAdd(p,tier,now,seconds)
 local def=C.LuckTiers[tier];if not def then return false end
 return math.max(now,L.EndAt(p,tier))+(seconds or def.Seconds)<=now+def.MaxSeconds
end
-- Adds time to a tier (capped at `cap` seconds of stored time, default its MaxSeconds; paid
-- bundles pass a longer cap so Robux time is never lost); returns the new expiry.
function L.Add(p,tier,seconds,now,cap)
 local def=assert(C.LuckTiers[tier],'Unknown luck tier')
 L.Normalize(p,now)
 local finish=math.min(math.max(now,L.EndAt(p,tier))+seconds,now+(cap or def.MaxSeconds))
 p.LuckBoosts[tostring(tier)]=finish
 return finish
end
return L

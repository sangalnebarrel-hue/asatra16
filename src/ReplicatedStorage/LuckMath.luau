-- Luck on the tongue, shared by the server (Engine:LineOdds, the conveyor's lucky blocks)
-- and the UI (the shop's SERVER LUCK panel shows the odds the server really rolls).
-- A boost multiplies the rarer ranks' budgets and Common absorbs the difference, so the
-- odds still add up to the same total and the split between dogs of one rank never moves.
local M={}
-- How strongly a server-luck multiplier L lifts each rank: Common absorbs, Rare stays,
-- Epic gets sqrt(L), Legendary, Mythic and Secret get xL.
M.Exponents={0,0,.5,1,1,1}
-- However much luck stacks (server luck x a world event), Common keeps at least this
-- share of the total; the rarer ranks are scaled down together to make room.
M.CommonFloor=.15
-- Server luck sold in the shop (1x is the free default).
M.MinLuck,M.MaxLuck=1,5
-- The per-rank boost for a server-luck multiplier: ServerBoost(5)[6]==5.
function M.ServerBoost(luck)
 luck=math.clamp(tonumber(luck)or 1,M.MinLuck,M.MaxLuck)
 local boost={}
 for rank,exponent in ipairs(M.Exponents)do boost[rank]=luck^exponent end
 boost[1]=1;return boost
end
-- Element-wise product of two boosts (either may be nil or sparse).
function M.Combine(a,b)
 local out={}
 for rank=1,#M.Exponents do out[rank]=((a and a[rank])or 1)*((b and b[rank])or 1)end
 out[1]=1;return out
end
-- A boost that changes nothing (callers then keep the exact unboosted path).
function M.IsNeutral(boost)
 if not boost then return true end
 for rank=2,#M.Exponents do if math.abs((boost[rank]or 1)-1)>1e-9 then return false end end
 return true
end
-- Boosted budgets for a weight list (index = rank); the total is unchanged.
function M.Budgets(weights,boost)
 local total=0;for _,w in ipairs(weights)do total+=w end
 local out=table.clone(weights)
 if M.IsNeutral(boost)or total<=0 then return out end
 local rest=0
 for rank=2,#weights do out[rank]=weights[rank]*math.max(0,boost[rank]or 1);rest+=out[rank]end
 local floor=total*M.CommonFloor
 if rest>total-floor and rest>0 then
  local scale=(total-floor)/rest;rest=0
  for rank=2,#weights do out[rank]*=scale;rest+=out[rank]end
 end
 out[1]=math.max(0,total-rest)
 return out
end
-- Percent per rank (sums to 100).
function M.Odds(weights,boost)
 local budgets=M.Budgets(weights,boost);local total=0
 for _,b in ipairs(budgets)do total+=b end
 local out={}
 for rank,b in ipairs(budgets)do out[rank]=total>0 and b/total*100 or 0 end
 return out
end
-- Minutes between two dogs of a rank, from its percent and the spawns per minute.
function M.Every(percent,spawnsPerMinute)
 if percent<=0 or spawnsPerMinute<=0 then return math.huge end
 return 100/percent/spawnsPerMinute
end
return M

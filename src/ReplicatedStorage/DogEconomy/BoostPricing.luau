-- Prices of coin boosts and the coin amount of Robux bundles, shared by the server (which
-- charges/grants) and the shop UI (which quotes). Both follow the economy: a boost costs a
-- share of what the player's team earns while it runs (the offline-earnings base rate,
-- remembered at its recent peak so benching dogs just before shopping does not help), and
-- never less than a floor that grows with the deepest layer the player has unlocked.
local Config=require(script.Parent.Config)
local P={}
local pricing=Config.BoostPricing or {LayerScale={1,3,8,20,50},PeakHalfLife=21600}

-- Two significant digits (12,345 → 12,000): prices read as prices.
function P.Round(n)
 n=math.max(10,math.floor(n))
 local unit=10^math.max(0,math.floor(math.log10(n))-1)
 return math.floor(n/unit+.5)*unit
end
function P.Deepest(p)
 local deepest=1
 for key,open in pairs(p.UnlockedLayers or {})do
  local n=tonumber(key);if open and n and n>deepest then deepest=n end
 end
 return math.clamp(deepest,1,#pricing.LayerScale)
end
function P.Floor(p,cash)return cash*pricing.LayerScale[P.Deepest(p)]end
-- Coins per second the team earns (the larger of the live base rate and its decaying peak).
function P.Rate(p,now)
 local o=type(p.OfflineEarnings)=='table'and p.OfflineEarnings or {}
 local base=tonumber(o.BaseRate)or 0
 local peak=tonumber(o.PeakRate)or 0
 local at=tonumber(o.PeakAt)or 0
 if now and at>0 then peak*=.5^(math.max(0,now-at)/pricing.PeakHalfLife)end
 return math.max(base,peak)
end
-- Server only, inside the profile transaction: remember the recent peak earning rate.
function P.Track(p,now)
 local o=p.OfflineEarnings;if type(o)~='table'then return end
 local rate=P.Rate(p,now)
 if rate==rate and rate<math.huge then o.PeakRate=rate;o.PeakAt=now end
end
-- def: a Config.Supplies or Config.LuckTiers row ({Cash, IncomeShare, Seconds}).
function P.Boost(def,p,now)
 local share=P.Rate(p,now)*(def.Seconds or 600)*(def.IncomeShare or .08)
 return math.min(Config.MaxCash,P.Round(math.max(P.Floor(p,def.Cash or 100),share)))
end
function P.Supply(key,p,now)local def=Config.Supplies[key];return def and P.Boost(def,p,now)or nil end
function P.Luck(tier,p,now)local def=Config.LuckTiers[tier];return def and P.Boost(def,p,now)or nil end
-- Coins in a Robux bundle: {MinCash, IncomeMinutes} → the floor (scaled by layer) or that many
-- minutes of the team's income, whichever is larger.
function P.Coins(spec,p,now)
 if type(spec)~='table'then return 0 end
 local income=P.Rate(p,now)*60*(spec.IncomeMinutes or 0)
 return math.min(Config.MaxCash,P.Round(math.max(P.Floor(p,spec.MinCash or 0),income)))
end
return P

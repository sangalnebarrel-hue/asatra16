-- One deterministic price index, shared by the server and the shop UI: coin-priced buffs
-- and income-scaled Robux coin packs are both measured in "minutes of this player's income".
-- Server: Rules 'Supply' and CommerceProducts receipts compute it from the profile.
-- UI: the same functions with the PriceRate attribute the server projects onto the player.
-- Income = p.OfflineEarnings.BaseRate (coins/s, refreshed every tick, never includes buffs, so
-- a buff never raises its own price), held up by a slowly decaying peak (unassigning dogs
-- right before buying does not help) and by a floor from the deepest unlocked layer.
local RS=game:GetService('ReplicatedStorage')
local Config=require(RS.DogEconomy.Config)
local Price=require(RS.PriceFormat)
local P={}
P.HalfLife=86400 -- the remembered peak income halves every 24 hours
-- coins/s floor by the deepest layer ever unlocked (≈ three Commons digging there).
P.LayerFloor={0,10,25,50,100}
P.MaxRate=1000000000
local function finite(n)return type(n)=='number'and n==n and math.abs(n)<math.huge end
-- Two significant digits, always a whole number: 1234 -> 1200, 56 -> 56, 99.6 -> 100.
function P.Nice(n)
 if not finite(n)or n<=0 then return 0 end
 local step=1;while n>=100*step do step*=10 end
 return math.floor(n/step+.5)*step
end
function P.DeepestLayer(p)
 local deepest=math.clamp(math.floor(tonumber(p.CurrentLayer)or 1),1,#P.LayerFloor)
 for key,unlocked in pairs(type(p.UnlockedLayers)=='table'and p.UnlockedLayers or{})do
  local n=tonumber(key);if unlocked and n and n>deepest and n<=#P.LayerFloor then deepest=math.floor(n)end
 end
 return deepest
end
-- The remembered peak income, decayed to now.
function P.Peak(o,now)
 local rate=finite(o.PeakRate)and math.clamp(o.PeakRate,0,P.MaxRate)or 0
 local at=finite(o.PeakAt)and o.PeakAt or now
 return rate*.5^(math.max(0,now-at)/P.HalfLife)
end
-- Server, after every OfflineEarnings checkpoint: remember a new peak.
function P.Observe(o,now)
 local base=finite(o.BaseRate)and math.clamp(o.BaseRate,0,P.MaxRate)or 0
 if base>=P.Peak(o,now)then o.PeakRate=base;o.PeakAt=now end
 return o
end
-- coins/s used for every price and pack.
function P.Rate(p,now)
 local o=type(p.OfflineEarnings)=='table'and p.OfflineEarnings or{}
 local base=finite(o.BaseRate)and math.clamp(o.BaseRate,0,P.MaxRate)or 0
 return math.max(base,P.Peak(o,now),P.LayerFloor[P.DeepestLayer(p)]or 0)
end
local function rateOf(rate)return finite(rate)and math.clamp(rate,0,P.MaxRate)or 0 end
-- Coins for `minutes` of income, never below `floor`.
function P.Cash(minutes,floor,rate)
 return math.max(math.floor(floor or 0),P.Nice(60*rateOf(rate)*(minutes or 0)))
end
-- Coin price of one shop purchase of a supply (its Seconds, 10 minutes).
function P.SupplyPrice(key,rate)
 local def=Config.Supplies[key];if not def or def.Shop==false then return nil end
 return math.max(def.Cash,P.Nice(60*rateOf(rate)*(def.PriceMinutes or 0)))
end
-- Everything a CommerceConfig row grants at this income rate. The receipt grants exactly this;
-- the shop card shows it. tokensUsable=false (paid random items restricted, or tokens not
-- sold) turns DOG-O-MATIC spins into coins (Rewards.TokenFallback).
function P.Plan(row,rate,tokensUsable)
 local r=row.Rewards or{}
 local plan={Cash=math.floor(r.Cash or 0),Bones=math.max(0,math.floor(r.Bones or 0)),Supplies={},Tokens=0,TokenCash=0,
  ServerLuck=row.ServerLuck or r.ServerLuck,CashMinutes=r.CashMinutes}
 if r.CashMinutes then plan.Cash+=P.Cash(r.CashMinutes,r.CashFloor,rate)end
 for key,seconds in pairs(r.Supplies or{})do plan.Supplies[key]=math.max(0,math.floor(seconds))end
 if row.Supply then plan.Supplies[row.Supply]=(plan.Supplies[row.Supply]or 0)+math.floor(row.Seconds or Config.Supplies[row.Supply].Seconds)end
 local tokens=math.max(0,math.floor(r.Tokens or 0))
 if tokens>0 then
  if tokensUsable then plan.Tokens=tokens
  else local f=r.TokenFallback or{};plan.TokenCash=P.Cash(f.Minutes or 0,f.Floor,rate);plan.Cash+=plan.TokenCash end
 end
 return plan
end
-- "30 MIN", "1 H", "1.5 H", "14 H".
function P.Duration(seconds)
 local minutes=math.floor((seconds or 0)/60+.5)
 if minutes<60 or minutes%30~=0 then return minutes..' MIN'end
 local hours=minutes/60
 return (hours%1==0 and tostring(hours)or string.format('%.1f',hours))..' H'
end
-- "60 MIN" / "8 H" of income for a pack's CashMinutes.
function P.IncomeSpan(minutes)return P.Duration((minutes or 0)*60)end
-- Short upper-case lines for the shop card and the purchase toast, in a stable order.
function P.Lines(plan,approx)
 local lines={}
 if plan.Cash>0 then table.insert(lines,(approx and'≈ 'or'+')..Price.Number(plan.Cash)..' COINS')end
 if plan.Bones>0 then table.insert(lines,'+'..Price.Number(plan.Bones)..' BONES')end
 for _,key in ipairs(Config.SupplyOrder)do
  local seconds=plan.Supplies[key];local def=Config.Supplies[key]
  if seconds and seconds>0 and def then table.insert(lines,def.Name:upper()..' +'..P.Duration(seconds))end
 end
 if plan.Tokens>0 then table.insert(lines,plan.Tokens..(plan.Tokens==1 and' DOG-O-MATIC SPIN'or' DOG-O-MATIC SPINS'))end
 local luck=plan.ServerLuck
 if luck then table.insert(lines,'x'..luck.Multiplier..' SERVER LUCK · '..P.Duration(luck.Seconds))end
 return lines
end
return P

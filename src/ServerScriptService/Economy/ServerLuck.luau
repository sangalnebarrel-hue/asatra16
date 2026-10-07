-- SERVER LUCK (bought with Robux in the shop): 2x..5x for everyone on this server.
-- Each tier keeps its own timer; the highest tier with time left is the one in force, and
-- when it runs out the next tier down takes over. Buying a tier adds its time to that
-- tier's timer. Server memory only: a new server starts at 1x (the receipt is durable,
-- the luck belongs to the server it was bought on).
-- Replicated on ReplicatedStorage.DOGROTS_ServerLuck (attributes, server clock =
-- workspace:GetServerTimeNow()): Multiplier, EndsAt (of the tier in force), By (who
-- bought the tier in force), Tier2..Tier5 (each tier's end), Revision.
local RS=game:GetService('ReplicatedStorage')
local LuckMath=require(RS.LuckMath)
local S={}
-- A tier never holds more than this much stacked time.
S.MaxStackSeconds=6*3600
S.Tiers={} -- [multiplier]={EndsAt=,By=}
local folder=RS:FindFirstChild('DOGROTS_ServerLuck')
if not folder then folder=Instance.new('Folder');folder.Name='DOGROTS_ServerLuck';folder.Parent=RS end
S.Folder=folder
local revision=0
local function now()return workspace:GetServerTimeNow()end
-- The multiplier in force (1 when none) and when it ends.
function S.Current(at)
 at=at or now()
 for mult=LuckMath.MaxLuck,2,-1 do
  local tier=S.Tiers[mult]
  if tier and tier.EndsAt>at then return mult,tier.EndsAt,tier.By end
 end
 return 1,0,nil
end
local published
local function publish()
 local mult,endsAt,by=S.Current()
 local key=mult..':'..endsAt
 for m=2,LuckMath.MaxLuck do local t=S.Tiers[m];key..=':'..(t and t.EndsAt or 0)end
 if key==published then return end
 published=key;revision+=1
 folder:SetAttribute('Multiplier',mult);folder:SetAttribute('EndsAt',endsAt);folder:SetAttribute('By',by or '')
 for m=2,LuckMath.MaxLuck do local t=S.Tiers[m];folder:SetAttribute('Tier'..m,t and t.EndsAt>now()and t.EndsAt or 0)end
 folder:SetAttribute('Revision',revision)
end
publish()
-- Adds seconds of the given multiplier; returns the tier's new end (server clock).
function S.Activate(multiplier,seconds,by)
 multiplier=math.floor(tonumber(multiplier)or 0)
 assert(multiplier>=2 and multiplier<=LuckMath.MaxLuck,'Invalid server luck')
 assert(type(seconds)=='number'and seconds>0,'Invalid server luck duration')
 local t=now();local tier=S.Tiers[multiplier]or{EndsAt=0}
 tier.EndsAt=math.min(math.max(t,tier.EndsAt)+seconds,t+S.MaxStackSeconds)
 tier.By=type(by)=='string'and by or tier.By
 S.Tiers[multiplier]=tier
 publish()
 local reward=RS:FindFirstChild('RewardPresentation')
 if reward then
  reward:FireAllClients({Announcement=string.upper((by and by~='')and by or 'SOMEONE')..' ACTIVATED x'..multiplier..' SERVER LUCK · '..math.floor(seconds/60+.5)..' MIN',Tier='Mythic'})
 end
 return tier.EndsAt
end
-- LineModifiers provider: luck for the tongue's dogs, its lucky blocks and dog variants.
function S.LineModifiers(at)
 local mult=S.Current(at)
 if mult<=1 then return nil end
 local boost=LuckMath.ServerBoost(mult)
 local variant=mult^.75
 return {RankBoost=boost,BlockRankBoost=boost,Variants={Shiny=variant,Golden=variant,Corrupted=variant,Glitched=variant,Void=variant},
  Labels={'x'..mult..' SERVER LUCK'}}
end
task.spawn(function()while true do task.wait(1);pcall(publish)end end)
return S

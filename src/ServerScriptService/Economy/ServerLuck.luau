-- Server luck (Lucky Server / Super / Ultra / MAX LUCK): multiplies the tongue's Legendary,
-- Mythic and Secret odds (dogs and Lucky Blocks) for everyone on this server. It lives in
-- this server's memory, like the tongue itself, and is mirrored on
-- ReplicatedStorage.ServerLuckState for every client's HUD, shop and celebration.
-- An active world event adds its own tongue luck on top (WorldEventDefinitions Perks).
local RS=game:GetService('ReplicatedStorage')
local Config=require(RS.DogEconomy.Config)
local Modifiers=require(RS.WorldEvents.WorldEventModifiers)
local S={Multiplier=1,EndsAt=0,By=''}
local MAX_STACK=10
local state=RS:FindFirstChild('ServerLuckState')
if not state then state=Instance.new('Folder');state.Name='ServerLuckState';state.Parent=RS end
S.State=state
local function publish(by,added,multiplier)
 state:SetAttribute('Multiplier',S.Multiplier);state:SetAttribute('EndsAt',S.EndsAt);state:SetAttribute('By',S.By)
 state:SetAttribute('LastBy',by or '');state:SetAttribute('LastMultiplier',multiplier or S.Multiplier);state:SetAttribute('LastSeconds',added or 0)
 -- Seq last: clients celebrate when it changes.
 state:SetAttribute('Seq',(state:GetAttribute('Seq')or 0)+1)
end
function S.Current(now)
 now=now or os.time()
 return now<S.EndsAt and S.Multiplier or 1
end
--[[ S.Add(multiplier, seconds, byName): a stronger (or equal) boost takes over and carries the
 weaker one's remaining time over at its value; a weaker boost extends the stronger one by its
 equivalent value. Stored time is capped at Config.ServerLuck.MaxSeconds. ]]
function S.Add(multiplier,seconds,byName)
 multiplier=math.clamp(tonumber(multiplier)or 1,1,10);seconds=math.max(0,tonumber(seconds)or 0)
 if multiplier<=1 or seconds<=0 then return end
 local now=os.time();local current=S.Current(now);local remaining=math.max(0,S.EndsAt-now)
 local cap=(Config.ServerLuck or {}).MaxSeconds or 7200
 if multiplier>=current then
  local carried=current>1 and remaining*(current-1)/(multiplier-1)or 0
  S.Multiplier=multiplier;S.EndsAt=now+math.min(cap,seconds+carried)
 else
  S.EndsAt=math.min(now+cap,S.EndsAt+seconds*(multiplier-1)/(current-1))
 end
 S.EndsAt=math.floor(S.EndsAt)
 S.By=tostring(byName or '')
 publish(S.By,seconds,multiplier)
 local presentation=RS:FindFirstChild('RewardPresentation')
 if presentation then presentation:FireAllClients({Announcement=string.upper(S.By)..' ACTIVATED x'..multiplier..' SERVER LUCK!',Tier='Secret'})end
end
-- Rank multipliers for the tongue right now: {[rank]=multiplier}. Server luck lifts every rank
-- in Config.ServerLuck.Ranks; a world event's LineLuck does the same and its SecretLine lifts
-- Secrets once more.
function S.Ranks(now)
 now=now or os.time()
 local luck=S.Current(now)
 local event=Modifiers.Active(now)
 local perks=event and event.Perks or {}
 local lineLuck=perks.LineLuck or 1
 local out={}
 for _,rank in ipairs((Config.ServerLuck or {}).Ranks or {4,5,6})do out[rank]=luck*lineLuck end
 out[6]=(out[6]or 1)*(perks.SecretLine or 1)
 -- Stacked (MAX LUCK during NULL HOUR) never runs away: at most x10 on any rarity.
 for rank,value in pairs(out)do out[rank]=math.min(value,MAX_STACK)end
 return out
end
publish('',0,1)
return S

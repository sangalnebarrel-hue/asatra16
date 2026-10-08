-- What a world event DOES to the island while it is ACTIVE (WorldEventDefinitions Perks):
-- gravity, walk and jump, the tongue's speed / rare-dog luck / Lucky Block share (read by
-- DogLineSpawner and ServerLuck.Ranks), bones while it lasts, and a reward when it ends for
-- everyone who stayed. WorldEventService calls Apply on every state change and Start once.
-- Every client draws the matching set pieces (WorldEventGameplayFX).
local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Run=game:GetService('RunService')
local package=RS:WaitForChild('WorldEvents')
local D=require(package.WorldEventDefinitions)
local Movement=require(script.Parent.MovementModifiers)
local Pricing=require(RS.DogEconomy.BoostPricing)
local Config=require(script.Parent.Economy.Config)
local R=require(script.Parent.Economy.Rules)
local Luck=require(script.Parent.Economy.LuckRules)
local line=workspace:WaitForChild('DOGROTS_District'):WaitForChild('03_DogLine')
local BASE_GRAVITY=workspace.Gravity
local G={Active=nil,Joined={}}
local rng=Random.new()
local function runtime()return require(script.Parent.Economy.Runtime)end

local function applyPlayer(player,perks)
 Movement.Set(player,'Event',perks and perks.Walk or nil)
 Movement.SetJump(player,'Event',perks and perks.Jump or nil)
end
local function setWorld(perks)
 workspace.Gravity=BASE_GRAVITY*(perks and perks.Gravity or 1)
 line:SetAttribute('EventLineScale',perks and perks.LineSpeed or nil)
 line:SetAttribute('EventBlockScale',perks and perks.BlockChance or nil)
 for _,p in ipairs(Players:GetPlayers())do applyPlayer(p,perks)end
end

-- Paid once per event generation to every player who stayed at least a minute of it.
function G.Reward(active)
 local rt=runtime();local now=os.time();local reward=active.Def.Perks.Reward
 for _,player in ipairs(Players:GetPlayers())do
  local present=now-math.max(G.Joined[player]or now,active.Start)
  if present>=60 and rt.Ready(player)then
   task.spawn(function()
    local ok,result=rt.Tx:Run({'p:'..player.UserId},function(v)
     local p=v['p:'..player.UserId];rt.Engine:Authorize(p,player.UserId);R.Normalize(p,player.UserId,now)
     local ledger=type(p.WorldEventRewards)=='table'and p.WorldEventRewards or {}
     if ledger[active.Generation]then return false end
     if R.Count(ledger)>=8 then ledger={}end
     ledger[active.Generation]=now;p.WorldEventRewards=ledger
     local coins=math.clamp(Pricing.Coins(reward,p,now),0,Config.MaxCash-p.Cash)
     if coins>0 then R.Credit(p,coins)end
     p.Bones+=reward.Bones or 0
     if reward.Luck then Luck.Add(p,reward.Luck.Tier,reward.Luck.Seconds,now)end
     R.Validate(p)
     return {Coins=coins,Bones=reward.Bones or 0,LuckTier=reward.Luck and reward.Luck.Tier or 0,LuckSeconds=reward.Luck and reward.Luck.Seconds or 0}
    end)
    if ok and type(result)=='table'and player.Parent then
     rt.Refresh(player)
     package.Signal:FireClient(player,{Kind='EventReward',EventId=active.Def.Id,Reward=result})
     -- The event card hides while a menu is open; the inventory toast always shows.
     RS.RewardPresentation:FireClient(player,{Message=active.Def.DisplayName..' reward: +'..result.Coins..' Coins'..(result.Bones>0 and(', +'..result.Bones..' Bones')or'')..(result.LuckTier>0 and(', '..result.LuckTier..'x LUCK')or'')})
    elseif not ok then warn('WORLD EVENT reward deferred:',result)end
   end)
  end
 end
end

-- Called by WorldEventService.Apply on every state change.
function G.Apply(state)
 local def=state and state.State=='ACTIVE'and D.ById[state.EventId]or nil
 local active=G.Active
 if def and(not active or active.Generation~=state.Generation)then
  G.Active={Def=def,Generation=state.Generation,Start=state.StartTimestamp,End=state.ActiveEndTimestamp}
  G.NextBones=os.clock()+15;G.NextFlicker=os.clock()+4
  setWorld(def.Perks)
 elseif not def and active then
  G.Active=nil;setWorld(nil)
  -- Only an event that ran its full course pays out (a Studio "stop" does not).
  if active.Def.Perks.Reward and os.time()>=active.End-5 then task.spawn(G.Reward,active)end
 end
end

function G.Tick()
 local active=G.Active;if not active then return end
 local perks=active.Def.Perks
 -- NULL HOUR: the gravity itself glitches.
 if perks.GravityFlicker and os.clock()>=G.NextFlicker then
  G.NextFlicker=os.clock()+rng:NextNumber(2.5,6)
  local roll=rng:NextNumber()
  workspace.Gravity=BASE_GRAVITY*(roll<.35 and .25 or roll<.7 and (perks.Gravity or 1)or 1)
 end
 if perks.BonesPerMinute and os.clock()>=G.NextBones then
  G.NextBones=os.clock()+15
  local amount=math.max(1,math.floor(perks.BonesPerMinute/4+.5))
  local rt=runtime()
  for _,player in ipairs(Players:GetPlayers())do
   if rt.Ready(player)then
    task.spawn(function()
     local ok=rt.Tx:Run({'p:'..player.UserId},function(v)
      local p=v['p:'..player.UserId];rt.Engine:Authorize(p,player.UserId)
      p.Bones+=amount;R.Validate(p);return true
     end)
     if ok and player.Parent then rt.Refresh(player)end
    end)
   end
  end
 end
end

function G.Start()
 if G.Started then return end;G.Started=true
 local function joined(player)
  G.Joined[player]=os.time()
  if G.Active then applyPlayer(player,G.Active.Def.Perks)end
 end
 Players.PlayerAdded:Connect(joined);for _,p in ipairs(Players:GetPlayers())do joined(p)end
 Players.PlayerRemoving:Connect(function(p)G.Joined[p]=nil end)
 local elapsed=0
 Run.Heartbeat:Connect(function(dt)
  elapsed+=dt;if elapsed<1 then return end;elapsed=0
  local ok,err=pcall(G.Tick);if not ok then warn('WORLD EVENT gameplay:',err)end
 end)
 game:BindToClose(function()workspace.Gravity=BASE_GRAVITY end)
 print('DOGROTS_WORLD_EVENT_GAMEPLAY_READY')
end
return G

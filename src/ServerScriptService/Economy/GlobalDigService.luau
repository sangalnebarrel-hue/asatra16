local Players=game:GetService('Players')
local Rep=game:GetService('ReplicatedStorage')
local Http=game:GetService('HttpService')
local Runtime=require(script.Parent.Runtime)
local R=require(script.Parent.Rules)
local I=require(script.Parent.ItemRules)
local Config=require(Rep:WaitForChild('GlobalDigConfig'))
local Service={Busy={}}
local rng=Random.new()
function Service.Dig(player,station)
 if Config.Enabled==false then return false,'Global Dig is coming soon'end
 if not Runtime.Ready(player) or not Runtime.Allow(player,2) or Service.Busy[player] then return false,'Please wait' end
 local site=workspace.DOGROTS_District['08_GlobalDigSite']
 local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
 local hum=player.Character and player.Character:FindFirstChildOfClass('Humanoid')
 if not root or not hum or hum.Health<=0 or not station:IsDescendantOf(site.DigPositions) or (root.Position-station.Position).Magnitude>16 then return false,'Come closer to a dig station' end
 Service.Busy[player]=true
 local now=os.time();local key='p:'..player.UserId;local uid=Http:GenerateGUID(false)
 local transport,ok,result=pcall(function()return Runtime.Tx:Run({key},function(v)
  local p=v[key];Runtime.Engine:Authorize(p,player.UserId);R.Normalize(p,player.UserId,now)
  R.Check(now>=(p.NextCommunityDig or 0),'Your dog is resting. Try again shortly.')
  local active
  for _,d in pairs(p.Dogs)do if d.AssignedSlot~='' and d.State=='Digging' then active=d;break end end
  R.Check(active,'Assign a dog to a DigSlot in your yard first')
  local contribution=Config.Contribution
  p.NextCommunityDig=now+Config.Cooldown;p.Event.Contribution+=contribution;p.EventTokens+=contribution;require(script.Parent.LifetimeStats).Add(p,"GlobalDigContribution",contribution)
  p.XP+=Config.XP;p.Level=math.min(100,1+math.floor(math.sqrt(p.XP/25)))
  local effects=R.Team(p,now);effects.WeightLuck=math.min(.15,effects.WeightLuck or 0)
  local def,chance=I.Pick(p.CurrentLayer,function()return rng:NextNumber()end,effects)
  local found
  if def and I.Free(p) then found=I.Mint(p,def,chance,uid,now,function()return rng:NextNumber()end,effects);if found then found.Origin='GlobalDig' end end
  R.Validate(p)
  return {Contribution=contribution,Item=found,Message='Your dog added '..contribution..' community digs!'}
 end,'community:'..uid)end)
 Service.Busy[player]=nil
 if not transport then return false,'Dig unavailable; try again shortly' end
 if ok then result.EventTotal=Runtime.AccumulateEvent(result.Contribution or 0);Runtime.Refresh(player);station:SetAttribute('LastDigAt',workspace:GetServerTimeNow()) end
 return ok,result
end
function Service.Start()
 if Service.Started then return end;Service.Started=true
 local site=workspace:WaitForChild('DOGROTS_District'):WaitForChild('08_GlobalDigSite')
 if Config.Enabled==false then
  site:SetAttribute('ComingSoon',true)
  for _,o in ipairs(site:GetDescendants())do if o:IsA('ProximityPrompt')then o.Enabled=false end end
  print('DOGROTS_GLOBAL_DIG_COMING_SOON');return
 end
 for _,station in site:WaitForChild('DigPositions'):GetChildren()do
  local prompt=Instance.new('ProximityPrompt');prompt.Name='JoinCommunityDig';prompt.ActionText='JOIN DIG';prompt.ObjectText='WORKING DOG REQUIRED';prompt.HoldDuration=1.5;prompt.MaxActivationDistance=12;prompt.RequiresLineOfSight=false;prompt.Parent=station
  prompt.Triggered:Connect(function(player)
   local ok,result=Service.Dig(player,station)
   Rep.DogEconomyOpen:FireClient(player,'Events',type(result)=='table' and result.Message or tostring(result))
  end)
 end
 task.spawn(function()
  while site.Parent do
   local total=Runtime.EventTotal or 0;site:SetAttribute('CommunityTotal',total)
   local text=site:FindFirstChild('CommunityProgressText',true)
   if text then text.Text='COMMUNITY DIG\n'..tostring(total)..' TOTAL DIGS\nEVERY PAW COUNTS' end
   local tier=0;for _,threshold in Config.Milestones do if total>=threshold then tier+=1 end end
   for _,p in site.MilestoneCrystals:GetChildren()do p.Transparency=tonumber(p.Name)<=tier and .1 or .85 end
   task.wait(5)
  end
 end)
 Players.PlayerRemoving:Connect(function(p)Service.Busy[p]=nil end)
 print('DOGROTS_GLOBAL_DIG_READY')
end
return Service

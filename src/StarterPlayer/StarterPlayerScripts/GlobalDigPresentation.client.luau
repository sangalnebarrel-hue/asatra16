-- Presentation only. Existing services own digging, persistence, event objects and rewards.
local RS=game:GetService('ReplicatedStorage');local Run=game:GetService('RunService');local SoundService=game:GetService('SoundService')
if require(RS:WaitForChild('GlobalDigConfig')).Enabled==false then return end
local player=game.Players.LocalPlayer;local map=workspace:WaitForChild('DOGROTS_District');local site=map:WaitForChild('08_GlobalDigSite')
local state=RS:WaitForChild('WorldEvents'):WaitForChild('State');local defs=require(RS.WorldEvents.WorldEventDefinitions)
local signals,displays={},{};local elapsed=0;local reverb;local dust
local function register(o)
 if o:GetAttribute('QuarryEventSignal')and o:IsA('BasePart')then signals[o]=o.Color end
 if o:GetAttribute('QuarryEventDisplay')then local t=o:FindFirstChildWhichIsA('TextLabel',true);if t then displays[t]=true end end
end
for _,o in site:GetDescendants()do register(o)end
site.DescendantAdded:Connect(function(o)task.defer(function()if o.Parent then register(o);register(o.Parent)end end)end)
local function timer(seconds)seconds=math.max(0,math.floor(seconds));return string.format('%02d:%02d',math.floor(seconds/60),seconds%60)end
local function createDust()
 local at=site:FindFirstChild('DustAnchor',true);if not at then return end
 local p=Instance.new('ParticleEmitter');p.Name='QuarryDust';p.Texture='rbxasset://textures/particles/smoke_main.dds';p.Rate=.6;p.Lifetime=NumberRange.new(3,5);p.Speed=NumberRange.new(.1,.4)
 p.SpreadAngle=Vector2.new(60,60);p.Size=NumberSequence.new(1.2,2.5);p.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.3,.94),NumberSequenceKeypoint.new(1,1)})
 p.Color=ColorSequence.new(Color3.fromRGB(186,176,153));p.LightInfluence=1;p.Parent=at;dust=p
end
Run.Heartbeat:Connect(function(dt)
 elapsed+=dt;if elapsed<.5 then return end;elapsed=0
 local character=player.Character;local root=character and character:FindFirstChild('HumanoidRootPart');if not root then return end
 local origin=site:FindFirstChild('SiteOrigin');local near=origin~=nil and(root.Position-origin.Position).Magnitude<170
 local phase=state:GetAttribute('State')or'NORMAL';local id=state:GetAttribute('EventId');local def=defs.ById[id]
 local active=phase=='ACTIVE';local warning=phase=='WARNING';local seconds=(state:GetAttribute(active and'ActiveEndTimestamp'or'EndTimestamp')or os.time())-os.time()
 local status=active and (def and def.DisplayName:upper()or'WORLD EVENT')..'  '..timer(seconds)or warning and'INCOMING EVENT  '..timer(seconds)or'NEXT WORLD EVENT  '..timer(seconds)
 for t in pairs(displays)do if t.Parent then t.Text=status else displays[t]=nil end end
 for o,original in pairs(signals)do
  if not o:IsDescendantOf(site)then signals[o]=nil
  else o.Color=active and Color3.fromRGB(92,181,190)or warning and Color3.fromRGB(244,185,66)or original end
 end
 site:SetAttribute('LocalPresentationState',phase)
 if not dust or not dust.Parent then createDust()end
 -- WorldDetailQuality owns emitter rate, distance culling and the shared Low/High particle budget.
 -- Reverb affects only the pre-existing quarry ambience, never the whole game mixer.
 local sound=SoundService:FindFirstChild('DistrictAmbience_08_GlobalDigSite')
 if sound and(not reverb or reverb.Parent~=sound)then
  if reverb then reverb:Destroy()end
  reverb=Instance.new('ReverbSoundEffect');reverb.Name='QuarryDepthReverb';reverb.DecayTime=1.4;reverb.Density=.6;reverb.Diffusion=.6;reverb.DryLevel=0;reverb.WetLevel=-28;reverb.Parent=sound
 end
 if reverb then reverb.Enabled=near;reverb.WetLevel=near and root.Position.Y<-25 and -15 or -28 end
end)
script.Destroying:Connect(function()if dust then dust:Destroy()end;if reverb then reverb:Destroy()end end)

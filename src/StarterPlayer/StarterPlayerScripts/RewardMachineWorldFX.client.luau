local RS=game:GetService('ReplicatedStorage')
local Players=game:GetService('Players');local Tween=game:GetService('TweenService');local Debris=game:GetService('Debris')
local Feedback=require(RS.RewardMachineFeedback);local Audio=require(RS.RewardAudio)
local player=Players.LocalPlayer;local last=-10;local seen={}
local host=player:WaitForChild('PlayerGui'):WaitForChild('ScreenGui',30)
assert(host,'Missing PAWPAD root')
require(host:WaitForChild('Modules'):WaitForChild('GUIIntegration',30)).SubscribeWorldReward(function(data)
 local result=data.RewardMachinePulse
 if not result or type(result.Receipt)~='string'or seen[result.Receipt]then return end
 local now=os.clock();for key,t in pairs(seen)do if now-t>60 then seen[key]=nil end end;seen[result.Receipt]=now
 -- The server delays feedback to the end of the reel; stale receipt retries never replay it.
 local map=workspace:FindFirstChild('DOGROTS_District');local zone=map and map:FindFirstChild('27_RewardMachinePlaza')
 local machine=zone and zone:FindFirstChild('RewardMachine');local camera=workspace.CurrentCamera
 local at=machine and machine:FindFirstChild('RevealInner')
 if not at or not camera or(camera.CFrame.Position-at.Position).Magnitude>170 or now-last<1.2 then return end
 last=now
 local rank=Feedback.Rank(result);local color=Feedback.Color(rank)
 local reduced=player:GetAttribute('ReducedMotion')or player:GetAttribute('LowFX')or player:GetAttribute('WorldEventFX')=='Low'
 local highlight=Instance.new('Highlight');highlight.Name='RewardMachineRewardPulse';highlight.Adornee=machine;highlight.DepthMode=Enum.HighlightDepthMode.Occluded;highlight.FillColor=color;highlight.OutlineColor=color
 highlight.FillTransparency=reduced and .94 or rank>=3 and .72 or .89;highlight.OutlineTransparency=.3;highlight.Parent=machine
 Tween:Create(highlight,TweenInfo.new(reduced and .45 or rank>=3 and 1.1 or .65),{FillTransparency=1,OutlineTransparency=1}):Play();Debris:AddItem(highlight,1.3)
 -- The winner hears the existing reveal UI; observers hear one quiet spatial cue.
 if data.RewardMachineWinner~=player.UserId then Audio.Cue(rank>=5 and 'burst'or'reveal',at)end
 if rank>=5 and not reduced then
  local attach=Instance.new('Attachment');attach.Name='RewardMachineBurst';attach.Position=Vector3.new(0,2.3,0);attach.Parent=at
  local fx=Instance.new('ParticleEmitter');fx.Name='SingleRewardBurst';fx.Texture='rbxasset://textures/particles/sparkles_main.dds';fx.Rate=0;fx.Lifetime=NumberRange.new(.45,.85);fx.Speed=NumberRange.new(7,13);fx.SpreadAngle=Vector2.new(65,65);fx.Acceleration=Vector3.new(0,-12,0);fx.LightEmission=.7;fx.Color=ColorSequence.new(color);fx.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.35),NumberSequenceKeypoint.new(1,0)});fx.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.15),NumberSequenceKeypoint.new(1,1)});fx.Parent=attach;fx:Emit(16);Debris:AddItem(attach,1.3)
 end
end)

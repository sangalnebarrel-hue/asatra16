local Sounds=game:GetService('SoundService');local Run=game:GetService('RunService');local Debris=game:GetService('Debris')
local C=require(game.ReplicatedStorage.WorldSoundConfig);local Preview=require(game.ReplicatedStorage.RewardAudio)
local S={Last={},Active={}}
function S.Cue(name,parent)
 local row=C.Cues[name];if not row or os.clock()-(S.Last[name]or -9)<.35 then return end;S.Last[name]=os.clock()
 if row.Id<=0 then if Run:IsStudio()and game.GameId==0 then Preview.Cue(row.Preview,parent)end;return end
 for i=#S.Active,1,-1 do if not S.Active[i].Parent or not S.Active[i].IsPlaying then S.Active[i]:Destroy();table.remove(S.Active,i)end end;if #S.Active>=6 then return end
 local s=Instance.new('Sound');s.SoundId='rbxassetid://'..row.Id;s.Volume=row.Volume;s.RollOffMinDistance=6;s.RollOffMaxDistance=65;s.SoundGroup=Sounds:WaitForChild('DOGROTS_AUDIO'):FindFirstChild('UI');s.Parent=parent or Sounds;s:Play();table.insert(S.Active,s);Debris:AddItem(s,6)
end
return S

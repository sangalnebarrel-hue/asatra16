local Run=game:GetService('RunService');local Sounds=game:GetService('SoundService');local Debris=game:GetService('Debris')
local IDs=require(game.ReplicatedStorage.WorldEvents.AudioAssetIds);local A={Active={},Last={}}
local function make(key,parent,volume)
 local asset=IDs[key];if not asset then return end
 local uri=require(game.ReplicatedStorage.AudioSource).Resolve(asset.Id,asset.LocalFile,asset.Loop)
 if not uri then return end
 local s=Instance.new('Sound');s.Name='Dogrots_'..key:gsub('/','_');s.SoundId=uri;s.Looped=asset.Loop;s.Volume=volume or .22
 s.RollOffMinDistance=7;s.RollOffMaxDistance=75;s.SoundGroup=Sounds.DOGROTS_AUDIO:FindFirstChild(asset.Loop and 'Ambient'or 'UI');s.Parent=parent or Sounds;return s
end
function A.Cue(role,parent)
 if os.clock()-(A.Last[role]or -5)<.12 then return end;A.Last[role]=os.clock()
 for i=#A.Active,1,-1 do if not A.Active[i].Parent or not A.Active[i].IsPlaying then A.Active[i]:Destroy();table.remove(A.Active,i)end end
 if #A.Active>=6 then return end
 local s=make('lucky/'..role,parent,.24);if s then s.PlaybackSpeed=.98+math.random()*.04;s:Play();table.insert(A.Active,s);Debris:AddItem(s,5)end
end
function A.Ambience(parent,key)
 local s=make(key or 'lucky/ambience',parent,.08);if s then s:Play()end;return s
end
return A

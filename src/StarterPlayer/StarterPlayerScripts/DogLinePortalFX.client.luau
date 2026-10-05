
local Run=game:GetService('RunService')
local map=workspace:WaitForChild('DOGROTS_District');local line=map:WaitForChild('03_DogLine')
local portal=line:FindFirstChild('BeltEndPortal',true)
while not portal do line.DescendantAdded:Wait();portal=line:FindFirstChild('BeltEndPortal',true) end
local anchor=portal:WaitForChild('SwirlAnchor')
local pieces={}
for i=1,18 do local p=Instance.new('Part');p.Size=Vector3.new(.5,.5,.5);p.Anchored=true;p.CanCollide=false;p.CanTouch=false;p.CanQuery=false;p.Material=Enum.Material.Neon;p.Color=Color3.fromRGB(190,119,255);p.Parent=portal;pieces[i]=p end
Run.Heartbeat:Connect(function()
 local cam=workspace.CurrentCamera;if not cam or (cam.CFrame.Position-anchor.Position).Magnitude>350 then return end
 local t=workspace:GetServerTimeNow()
 for i,p in ipairs(pieces)do local a=t*.7+i*math.pi*2/18;local r=4+i%3*1.3;p.Position=anchor.Position+Vector3.new(math.cos(a)*r,math.sin(a)*r*1.5,math.sin(t+i)*.6)end
end)

local Audio=require(game.ReplicatedStorage.RewardAudio)
Audio.Ambience(anchor,'NULL_HOUR/ambient')
local active=line:WaitForChild('ActiveDogs')
local function spawned(model)
 task.defer(function()if model.Parent and model:GetAttribute('LuckyBlockRarity')and model.PrimaryPart then Audio.Cue('spawn',model.PrimaryPart)end end)
end
active.ChildAdded:Connect(spawned)
local mouth=map:WaitForChild('02_DogFactory'):FindFirstChild('MouthAmbienceAnchor',true)
if mouth then Audio.Ambience(mouth,'lucky/ambience')end

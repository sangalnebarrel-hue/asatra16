-- Studio only: F7 opens a list of the Secret dogs. Click: it arrives on the tongue (Long
-- Dog and Aurion, which never walk it, arrive in front of you). Right-click: in front of
-- you, like a Secret from a Lucky Block. Uses DogLineSpawner's StudioSecretArrival remote.
local Run=game:GetService('RunService')
if not Run:IsStudio()then return true end
local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local UIS=game:GetService('UserInputService')
local Config=require(RS:WaitForChild('SecretArrivalConfig'))
local remote=RS:WaitForChild('StudioSecretArrival',30)
if not remote then return true end
local player=Players.LocalPlayer
local gui=Instance.new('ScreenGui');gui.Name='DOGROTS_SecretAdmin';gui.ResetOnSpawn=false;gui.DisplayOrder=301
gui.Parent=player:WaitForChild('PlayerGui')
local panel=Instance.new('Frame');panel.Name='SecretArrivalLab';panel.Visible=false;panel.BorderSizePixel=0
panel.BackgroundColor3=Color3.fromRGB(18,22,32);panel.Position=UDim2.new(0,16,0,96);panel.Size=UDim2.fromOffset(250,70+30*11)
panel.Parent=gui
Instance.new('UICorner',panel).CornerRadius=UDim.new(0,10)
local title=Instance.new('TextLabel');title.BackgroundTransparency=1;title.Size=UDim2.new(1,-20,0,30);title.Position=UDim2.fromOffset(10,4)
title.Text='SECRET ARRIVALS  ·  F7';title.TextColor3=Color3.fromRGB(239,242,249);title.Font=Enum.Font.GothamBold;title.TextSize=14
title.TextXAlignment=Enum.TextXAlignment.Left;title.Parent=panel
local status=Instance.new('TextLabel');status.BackgroundTransparency=1;status.Size=UDim2.new(1,-20,0,20);status.Position=UDim2.new(0,10,1,-24)
status.Text='Spawns on the tongue';status.TextColor3=Color3.fromRGB(158,171,194);status.Font=Enum.Font.Gotham;status.TextSize=11
status.TextXAlignment=Enum.TextXAlignment.Left;status.Parent=panel
local ids={}
for id in pairs(Config.Dogs)do table.insert(ids,id)end
table.sort(ids)
for i,id in ipairs(ids)do
 local b=Instance.new('TextButton');b.Size=UDim2.new(1,-20,0,26);b.Position=UDim2.fromOffset(10,36+(i-1)*30)
 b.BackgroundColor3=Color3.fromRGB(38,47,65);b.BorderSizePixel=0;b.TextColor3=Config.Dogs[id].Color
 b.Font=Enum.Font.GothamBold;b.TextSize=13;b.Text=Config.Dogs[id].Title;b.Parent=panel
 Instance.new('UICorner',b).CornerRadius=UDim.new(0,6)
 local function spawn(here)
  status.Text='Spawning '..id..'...'
  local ok,success,message=pcall(function()return remote:InvokeServer(id,here)end)
  status.Text=ok and tostring(message)or tostring(success)
 end
 b.Activated:Connect(function()spawn(false)end)
 b.MouseButton2Click:Connect(function()spawn(true)end)
end
UIS.InputBegan:Connect(function(input,processed)
 if processed or input.KeyCode~=Enum.KeyCode.F7 then return end
 panel.Visible=not panel.Visible
end)
return true

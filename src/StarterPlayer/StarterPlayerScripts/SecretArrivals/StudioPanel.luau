-- Studio only: F7 (or the SECRETS button) opens a list of the Secret dogs. Click: it arrives
-- on the tongue (Long Dog and Aurion, which never walk it, arrive in front of you).
-- Right-click: in front of you, like a Secret from a Lucky Block. Uses DogLineSpawner's
-- StudioSecretArrival remote.
-- The menu and the F7 key are set up first and never wait on the server: if the remote is
-- missing the status line says so (look for an earlier error from DogLineSpawner in Output).
local Run=game:GetService('RunService')
if not Run:IsStudio()then return true end
local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local UIS=game:GetService('UserInputService')
local Config=require(RS:WaitForChild('SecretArrivalConfig'))
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
status.Text='Waiting for the server...';status.TextColor3=Color3.fromRGB(158,171,194);status.Font=Enum.Font.Gotham;status.TextSize=11
status.TextXAlignment=Enum.TextXAlignment.Left;status.TextTruncate=Enum.TextTruncate.AtEnd;status.Parent=panel
local toggleButton=Instance.new('TextButton');toggleButton.Name='SecretArrivalToggle';toggleButton.Size=UDim2.fromOffset(120,26)
toggleButton.Position=UDim2.fromOffset(16,62);toggleButton.BackgroundColor3=Color3.fromRGB(38,47,65);toggleButton.BackgroundTransparency=.25
toggleButton.BorderSizePixel=0;toggleButton.Text='SECRETS  ·  F7';toggleButton.TextColor3=Color3.fromRGB(239,242,249)
toggleButton.Font=Enum.Font.GothamBold;toggleButton.TextSize=12;toggleButton.Parent=gui
Instance.new('UICorner',toggleButton).CornerRadius=UDim.new(0,6)
local function remoteFunction()return RS:FindFirstChild('StudioSecretArrival')end
local ids={}
for id in pairs(Config.Dogs)do table.insert(ids,id)end
table.sort(ids)
for i,id in ipairs(ids)do
 local b=Instance.new('TextButton');b.Size=UDim2.new(1,-20,0,26);b.Position=UDim2.fromOffset(10,36+(i-1)*30)
 b.BackgroundColor3=Color3.fromRGB(38,47,65);b.BorderSizePixel=0;b.TextColor3=Config.Dogs[id].Color
 b.Font=Enum.Font.GothamBold;b.TextSize=13;b.Text=Config.Dogs[id].Title;b.Parent=panel
 Instance.new('UICorner',b).CornerRadius=UDim.new(0,6)
 local function spawn(here)
  local remote=remoteFunction()
  if not remote then status.Text='Server not ready (see Output: DogLineSpawner)';return end
  status.Text='Spawning '..id..'...'
  local ok,success,message=pcall(function()return remote:InvokeServer(id,here)end)
  status.Text=ok and tostring(message)or tostring(success)
 end
 b.Activated:Connect(function()spawn(false)end)
 b.MouseButton2Click:Connect(function()spawn(true)end)
end
local function toggle()panel.Visible=not panel.Visible end
toggleButton.Activated:Connect(toggle)
UIS.InputBegan:Connect(function(input)
 if input.KeyCode~=Enum.KeyCode.F7 or UIS:GetFocusedTextBox()then return end
 toggle()
end)
print('DOGROTS_SECRET_PANEL_READY (F7)')
task.spawn(function()
 if RS:WaitForChild('StudioSecretArrival',20)then status.Text='Spawns on the tongue'
 else
  status.Text='Server not ready (see Output: DogLineSpawner)'
  warn('DOGROTS F7 panel: DogLineSpawner never created StudioSecretArrival; look for an earlier error in Output.')
 end
end)
return true

-- Studio only: the ★ SECRETS button on the right edge of the screen (or F7) opens a list
-- of every Secret dog. Choose where it arrives, then click a dog: ON THE TONGUE spawns it
-- on the conveyor, IN FRONT OF ME stages it in front of you like a Secret from a Lucky
-- Block. The Long Dog and Aurion never walk the tongue and always arrive where they really
-- do (the server routes them): the Long Dog from the giant mouth (its dig venue), Aurion
-- on the DOG-O-MATIC's stand after a spin. The status line shows the server's answer.
-- Uses DogLineSpawner's StudioSecretArrival remote; a published place's previews are not
-- for sale. The button is there because F7 often never reaches the game (laptop media
-- keys, keyboard focus on another Studio panel).
local Run=game:GetService('RunService')
if not Run:IsStudio()then return true end
local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local UIS=game:GetService('UserInputService')
local Config=require(RS:WaitForChild('SecretArrivalConfig'))
local player=Players.LocalPlayer
local BG,ROW,FG,MUTED=Color3.fromRGB(18,22,32),Color3.fromRGB(38,47,65),Color3.fromRGB(239,242,249),Color3.fromRGB(158,171,194)
local GOOD,BAD,PICKED=Color3.fromRGB(155,233,180),Color3.fromRGB(246,152,137),Color3.fromRGB(86,62,137)
local function new(class,props,parent)
 local o=Instance.new(class)
 for k,v in pairs(props)do (o::any)[k]=v end
 o.Parent=parent;return o
end
local function round(o,r)new('UICorner',{CornerRadius=UDim.new(0,r)},o)end
local function button(parent,text,position,size,color)
 local b=new('TextButton',{Text=text,Position=position,Size=size,BackgroundColor3=color or ROW,TextColor3=FG,Font=Enum.Font.GothamBold,
  TextSize=13,AutoButtonColor=true,BorderSizePixel=0},parent)
 round(b,7);return b
end
local function label(parent,text,position,size,color,textSize)
 return new('TextLabel',{Text=text,Position=position,Size=size,BackgroundTransparency=1,TextColor3=color or FG,Font=Enum.Font.GothamMedium,
  TextSize=textSize or 13,TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true},parent)
end

-- Secrets in line order: the most common first, THE DOG last, the off-tongue ones after.
local definitions do
 local ok,result=pcall(function()return require(RS:WaitForChild('DogEconomy'):WaitForChild('DogDefinitions'))end)
 definitions=ok and type(result)=='table'and result or {}
end
local function onLine(id)local d=definitions[id];return d==nil or d.CanSpawnOnLine~=false end
-- Where the off-tongue ones arrive (the mode switch does not apply to them).
local VENUES={LongDog='from the giant mouth (dig venue)',Aurion='at the DOG-O-MATIC'}
local function venue(id)
 if VENUES[id]then return VENUES[id]end
 local d=definitions[id]
 if d and d.Acquisition=='RouletteOnly'then return VENUES.Aurion end
 return not onLine(id)and 'in front of you'or nil
end
-- Every Secret: each one with an arrival, and any Rank 6 dog still missing one (listed,
-- so a missing arrival shows up here instead of silently).
local ids={}
for id in pairs(Config.Dogs)do table.insert(ids,id)end
for id,d in pairs(definitions)do
 if type(d)=='table'and d.Rank==6 and not Config.Dogs[id]then table.insert(ids,id)end
end
local function title(id)
 local entry=Config.Dogs[id]
 return entry and entry.Title or string.upper(tostring(definitions[id]and definitions[id].DisplayName or id))
end
table.sort(ids,function(a,b)
 if onLine(a)~=onLine(b)then return onLine(a)end
 local wa,wb=(definitions[a]and definitions[a].LineWeight)or 0,(definitions[b]and definitions[b].LineWeight)or 0
 if wa~=wb then return wa>wb end
 return title(a)<title(b)
end)

local gui=new('ScreenGui',{Name='DOGROTS_SecretAdmin',ResetOnSpawn=false,DisplayOrder=301,ZIndexBehavior=Enum.ZIndexBehavior.Sibling},nil)
local toggle=button(gui,'★ SECRETS  [F7]',UDim2.new(1,-12,.5,0),UDim2.fromOffset(150,38),PICKED)
toggle.Name='SecretsToggle';toggle.AnchorPoint=Vector2.new(1,.5);toggle.TextSize=14
local WIDTH,TOP=330,108
local HEIGHT=TOP+36+30*#ids
local panel=new('Frame',{Name='SecretArrivalLab',Visible=false,BorderSizePixel=0,BackgroundColor3=BG,AnchorPoint=Vector2.new(1,.5),
 Position=UDim2.new(1,-172,.5,0),Size=UDim2.fromOffset(WIDTH,HEIGHT)},gui)
round(panel,10)
local scale=new('UIScale',{},panel)
label(panel,'SECRET ARRIVALS',UDim2.fromOffset(14,10),UDim2.fromOffset(200,22),FG,17).Font=Enum.Font.GothamBold
label(panel,'STUDIO ONLY  ·  F7 OR ★ SECRETS',UDim2.fromOffset(14,32),UDim2.fromOffset(220,14),MUTED,10)
local close=button(panel,'X',UDim2.new(1,-40,0,10),UDim2.fromOffset(28,28))

-- Where the next dog arrives.
local here=false
local tongueMode=button(panel,'ON THE TONGUE',UDim2.fromOffset(12,54),UDim2.fromOffset(149,28))
local hereMode=button(panel,'IN FRONT OF ME',UDim2.fromOffset(169,54),UDim2.fromOffset(149,28))
tongueMode.TextSize=11;hereMode.TextSize=11
label(panel,'Where the next one arrives (Long Dog and Aurion always come where they really do).',
 UDim2.fromOffset(14,84),UDim2.fromOffset(WIDTH-28,22),MUTED,10)
local function paintMode()
 tongueMode.BackgroundColor3=here and ROW or PICKED
 hereMode.BackgroundColor3=here and PICKED or ROW
end
paintMode()
tongueMode.Activated:Connect(function()here=false;paintMode()end)
hereMode.Activated:Connect(function()here=true;paintMode()end)

local status=label(panel,'Connecting to the server...',UDim2.new(0,14,1,-38),UDim2.new(1,-28,0,32),MUTED,11)
local function say(text,color)status.Text=text;status.TextColor3=color or MUTED end

local remote=RS:FindFirstChild('StudioSecretArrival')
local busy=false
local function arrive(id)
 if busy then return end
 if not remote then say('The server is not ready yet (see Output).',BAD);return end
 busy=true
 local where=venue(id)
 say('Spawning '..title(id)..(where and ' '..where or here and ' in front of you'or ' on the tongue')..'...')
 local answered=false
 -- (Aurion's spin can take a while; a late answer still replaces this.)
 task.delay(15,function()
  if answered then return end
  busy=false
  say('No answer from the server. Look for a red error in Output.',BAD)
 end)
 task.spawn(function()
  local ok,success,message=pcall(function()return remote:InvokeServer(id,here)end)
  answered=true;busy=false
  if ok then say(tostring(message),success and GOOD or BAD)
  else say('Error: '..tostring(success),BAD);warn('[SecretArrivals] Studio preview of '..id..' failed:',success)end
 end)
end
for i,id in ipairs(ids)do
 local entry=Config.Dogs[id]
 local where=venue(id)
 local b=button(panel,'',UDim2.fromOffset(12,TOP+(i-1)*30),UDim2.fromOffset(WIDTH-24,26))
 b.RichText=true
 b.Text=title(id)..(where and '<font color="#9EABC2" size="11">  ·  '..where..'</font>'or'')
  ..(entry and''or'<font color="#F69889" size="11">  ·  no arrival</font>')
 b.TextColor3=entry and entry.Color or MUTED;b.TextXAlignment=Enum.TextXAlignment.Left
 new('UIPadding',{PaddingLeft=UDim.new(0,10)},b)
 b.Activated:Connect(function()arrive(id)end)
end

local function show(visible)
 panel.Visible=visible
 toggle.Text=visible and '✕ SECRETS  [F7]' or '★ SECRETS  [F7]'
end
toggle.Activated:Connect(function()show(not panel.Visible)end)
close.Activated:Connect(function()show(false)end)
-- F7 works even while a game menu holds the input; only typing in a text box is spared.
UIS.InputBegan:Connect(function(input)
 if input.KeyCode==Enum.KeyCode.F7 and not UIS:GetFocusedTextBox()then show(not panel.Visible)end
end)
-- Small Studio viewports: shrink the panel to fit.
local function fit()
 local screen=gui.AbsoluteSize
 if screen.Y<=0 then return end
 scale.Scale=math.clamp(math.min((screen.Y-24)/HEIGHT,(screen.X-190)/WIDTH),.45,1)
end
gui:GetPropertyChangedSignal('AbsoluteSize'):Connect(fit)
gui.Parent=player:WaitForChild('PlayerGui')
fit()
print('DOGROTS_SECRET_PANEL_READY: click ★ SECRETS on the right edge of the game view, or press F7')

if remote then say('Ready. Pick where, then a dog.',GOOD)else
 task.spawn(function()
  remote=RS:WaitForChild('StudioSecretArrival',15)
  if not remote then
   say('Server preview missing: DogLineSpawner did not start. See the red error in Output.',BAD)
   warn('[SecretArrivals] ReplicatedStorage.StudioSecretArrival has not appeared after 15 s:'
    ..' ServerScriptService.DogLineSpawner probably stopped on an error (look for it above).')
   remote=RS:WaitForChild('StudioSecretArrival')
  end
  say('Ready. Pick where, then a dog.',GOOD)
 end)
end
return true

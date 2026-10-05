local Run=game:GetService('RunService')
if not Run:IsStudio() then return end
local Players=game:GetService('Players')
local UIS=game:GetService('UserInputService')
local RS=game:GetService('ReplicatedStorage')
local player=Players.LocalPlayer
local package=RS:WaitForChild('WorldEvents')
local remote=package:WaitForChild('StudioEventControl',30)
if not remote then return end
local Definitions=require(package.WorldEventDefinitions)
local gui=Instance.new('ScreenGui');gui.Name='DOGROTS_EventAdmin';gui.ResetOnSpawn=false;gui.DisplayOrder=300;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;gui.Parent=player:WaitForChild('PlayerGui')
local bg=Color3.fromRGB(18,22,32);local fg=Color3.fromRGB(239,242,249);local muted=Color3.fromRGB(158,171,194)
local function frame(parent,name,pos,size,color)
 local f=Instance.new('Frame');f.Name=name;f.Position=pos;f.Size=size;f.BackgroundColor3=color or bg;f.BorderSizePixel=0;f.Parent=parent
 local corner=Instance.new('UICorner');corner.CornerRadius=UDim.new(0,10);corner.Parent=f
 return f
end
local function label(parent,text,pos,size,color,fontSize)
 local l=Instance.new('TextLabel');l.BackgroundTransparency=1;l.Position=pos;l.Size=size;l.Text=text;l.TextColor3=color or fg;l.Font=Enum.Font.GothamMedium;l.TextSize=fontSize or 14;l.TextXAlignment=Enum.TextXAlignment.Left;l.TextWrapped=true;l.Parent=parent;return l
end
local function button(parent,text,pos,size,color)
 local b=Instance.new('TextButton');b.Position=pos;b.Size=size;b.Text=text;b.BackgroundColor3=color or Color3.fromRGB(38,47,65);b.TextColor3=fg;b.Font=Enum.Font.GothamBold;b.TextSize=13;b.AutoButtonColor=true;b.BorderSizePixel=0;b.Parent=parent
 local corner=Instance.new('UICorner');corner.CornerRadius=UDim.new(0,7);corner.Parent=b;return b
end
local toggle=button(gui,'EVENTS  [F6]',UDim2.new(.5,-72,0,12),UDim2.fromOffset(144,36),Color3.fromRGB(86,62,137))
toggle.Visible=false
local panel=frame(gui,'ControlRoom',UDim2.new(1,-374,0,56),UDim2.fromOffset(360,584));panel.Visible=false
local scale=Instance.new('UIScale');scale.Parent=panel
label(panel,'WORLD EVENT LAB',UDim2.fromOffset(18,14),UDim2.fromOffset(284,25),fg,19)
label(panel,'STUDIO ONLY  /  F6 TO TOGGLE',UDim2.fromOffset(18,43),UDim2.fromOffset(320,18),muted,10)
local close=button(panel,'X',UDim2.new(1,-44,0,12),UDim2.fromOffset(30,30))
local status=label(panel,'Choose an event, then START.',UDim2.fromOffset(18,68),UDim2.fromOffset(324,34),muted,12)
local scroll=Instance.new('ScrollingFrame');scroll.Position=UDim2.fromOffset(14,110);scroll.Size=UDim2.fromOffset(332,270);scroll.BackgroundTransparency=1;scroll.BorderSizePixel=0;scroll.ScrollBarThickness=4;scroll.CanvasSize=UDim2.fromOffset(0,#Definitions.List*37);scroll.Parent=panel
local chosen='BONE_RAIN';local choices={}
for i,d in ipairs(Definitions.List) do
 local b=button(scroll,string.format('%02d   %s%s',i,d.DisplayName,d.Enabled and '' or ' [BONUS]'),UDim2.fromOffset(2,(i-1)*37),UDim2.fromOffset(322,32))
 b.TextXAlignment=Enum.TextXAlignment.Left
 local pad=Instance.new('UIPadding');pad.PaddingLeft=UDim.new(0,10);pad.Parent=b
 local stripe=frame(b,'Rarity',UDim2.fromOffset(0,0),UDim2.fromOffset(4,32),d.ColorTheme)
 choices[d.Id]=b
 b.Activated:Connect(function()
  chosen=d.Id
  for id,other in pairs(choices) do other.BackgroundColor3=id==chosen and Color3.fromRGB(77,61,108) or Color3.fromRGB(38,47,65) end
  status.Text=d.DisplayName..' selected'
 end)
end
choices[chosen].BackgroundColor3=Color3.fromRGB(77,61,108)
local durations={30,60,240};local duration=60;local dButtons={}
for i,seconds in ipairs(durations) do
 local b=button(panel,tostring(seconds)..' sec',UDim2.fromOffset(18+(i-1)*82,393),UDim2.fromOffset(76,29));dButtons[seconds]=b
 b.Activated:Connect(function()duration=seconds;for s,other in pairs(dButtons) do other.BackgroundColor3=s==duration and Color3.fromRGB(86,62,137) or Color3.fromRGB(38,47,65) end end)
end
dButtons[60].BackgroundColor3=Color3.fromRGB(86,62,137)
local warning=false
local warnButton=button(panel,'5s intro: OFF',UDim2.fromOffset(18,431),UDim2.fromOffset(153,29))
warnButton.Activated:Connect(function()warning=not warning;warnButton.Text='5s intro: '..(warning and 'ON' or 'OFF')end)
local motion=button(panel,'Motion: ON',UDim2.fromOffset(181,431),UDim2.fromOffset(161,29))
motion.Activated:Connect(function()
 local value=not player:GetAttribute('ReducedMotion');player:SetAttribute('ReducedMotion',value);motion.Text='Motion: '..(value and 'LOW' or 'ON')
end)
local pending=false
local function call(action)
 if pending then return end;pending=true;status.Text='Applying...'
 task.spawn(function()
  local ok,success,message=pcall(function()return remote:InvokeServer(action,chosen,duration,warning)end)
  status.Text=ok and tostring(message) or 'Server did not respond'
  status.TextColor3=ok and success and Color3.fromRGB(155,233,180) or Color3.fromRGB(246,152,137)
  pending=false
 end)
end
button(panel,'START EVENT',UDim2.fromOffset(18,471),UDim2.fromOffset(156,36),Color3.fromRGB(66,119,89)).Activated:Connect(function()call('start')end)
button(panel,'SIGNATURE',UDim2.fromOffset(184,471),UDim2.fromOffset(158,36),Color3.fromRGB(102,69,149)).Activated:Connect(function()call('signature')end)
button(panel,'STOP',UDim2.fromOffset(18,517),UDim2.fromOffset(100,31),Color3.fromRGB(118,54,63)).Activated:Connect(function()call('stop')end)
button(panel,'AUTO SCHEDULE',UDim2.fromOffset(128,517),UDim2.fromOffset(214,31)).Activated:Connect(function()call('resume')end)
local timer=label(panel,'',UDim2.fromOffset(18,553),UDim2.fromOffset(324,21),muted,11)
local function show()panel.Visible=not panel.Visible end
toggle.Activated:Connect(show);close.Activated:Connect(show)
UIS.InputBegan:Connect(function(input,processed)if not processed and input.KeyCode==Enum.KeyCode.F6 then show()end end)
local elapsed=0
Run.Heartbeat:Connect(function(dt)
 elapsed+=dt;if elapsed<.25 then return end;elapsed=0
 local screen=gui.AbsoluteSize
 local factor=math.min(1,(screen.Y-80)/584,(screen.X-20)/360)
 scale.Scale=math.max(.45,factor);panel.Position=UDim2.new(1,-360*scale.Scale-14,0,56)
 local state=package.State:GetAttributes();local left=math.max(0,math.ceil((state.EndTimestamp or 0)-workspace:GetServerTimeNow()))
 timer.Text=(state.State or 'NORMAL')..'  |  '..(state.EventId or '')..'  |  '..left..'s'
end)
print('DOGROTS_EVENT_ADMIN_UI_READY')

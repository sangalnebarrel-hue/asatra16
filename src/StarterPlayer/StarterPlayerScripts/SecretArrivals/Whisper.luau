-- The mysterious line typed at the top of the screen during a Secret arrival, and the
-- reveal card under it. One per client: a newer arrival replaces the older text.
local Players=game:GetService('Players')
local Tween=game:GetService('TweenService')
local Run=game:GetService('RunService')
local player=Players.LocalPlayer
local W={}
local gui,line,red,cyan,card,cardTitle,cardTier
local token=0
local glyphs={'#','%','&','?','!','/','\\','0','1','_','~','*','<','>','|'}
local function new(class,props,parent)
 local o=Instance.new(class)
 for k,v in pairs(props)do (o::any)[k]=v end
 o.Parent=parent;return o
end
-- KeepFont must be set before parenting: PlaceTypography forces FredokaOne otherwise.
local function label(name,parent,z)
 local l=Instance.new('TextLabel');l.Name=name;l:SetAttribute('KeepFont',true)
 l.BackgroundTransparency=1;l.AnchorPoint=Vector2.new(.5,0);l.TextScaled=true;l.RichText=false
 l.TextTransparency=1;l.TextStrokeTransparency=1;l.ZIndex=z;l.Parent=parent
 new('UITextSizeConstraint',{MinTextSize=12,MaxTextSize=30},l)
 return l
end
local function build()
 if gui and gui.Parent then return end
 gui=Instance.new('ScreenGui');gui.Name='DOGROTS_SecretWhisper';gui.ResetOnSpawn=false;gui.DisplayOrder=96
 gui.ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling
 -- Chromatic ghosts behind the main line; they only show while it glitches.
 red=label('WhisperRed',gui,1);red.TextColor3=Color3.fromRGB(255,40,70)
 cyan=label('WhisperCyan',gui,1);cyan.TextColor3=Color3.fromRGB(40,230,255)
 line=label('Whisper',gui,2);line.TextStrokeColor3=Color3.fromRGB(8,6,14)
 card=new('Frame',{Name='RevealCard',BackgroundTransparency=1,AnchorPoint=Vector2.new(.5,0),ZIndex=3},gui)
 cardTier=label('Tier',card,3);cardTier.Size=UDim2.new(1,0,0,18);cardTier.Position=UDim2.fromScale(.5,0)
 cardTier.TextStrokeColor3=Color3.fromRGB(8,6,14);cardTier:FindFirstChildOfClass('UITextSizeConstraint').MaxTextSize=16
 cardTitle=label('Title',card,3);cardTitle.Size=UDim2.new(1,0,1,-20);cardTitle.Position=UDim2.new(.5,0,0,20)
 cardTitle.TextStrokeColor3=Color3.fromRGB(8,6,14);cardTitle:FindFirstChildOfClass('UITextSizeConstraint').MaxTextSize=46
 local function layout()
  local w=gui.AbsoluteSize.X
  local touch=game:GetService('UserInputService').TouchEnabled
  -- Clear the top-right Money/XP stack on touch screens.
  local side=touch and math.clamp(w/920,.48,.64)*320+24 or 24
  local width=math.clamp(w-2*side,220,760)
  for _,l in ipairs({line,red,cyan})do l.Size=UDim2.fromOffset(width,40);l.Position=UDim2.new(.5,0,0,8)end
  card.Size=UDim2.fromOffset(math.min(width,620),76);card.Position=UDim2.new(.5,0,0,54)
 end
 gui:GetPropertyChangedSignal('AbsoluteSize'):Connect(layout)
 gui.Parent=player:WaitForChild('PlayerGui')
 layout()
end
-- Running fades per label: a new line must cancel the old line's fade-out or the tween
-- keeps writing its transparency and the new line fades away with it.
local fades={}
local function fade(o,seconds,props)
 if fades[o]then fades[o]:Cancel()end
 local t=Tween:Create(o,TweenInfo.new(seconds,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),props)
 fades[o]=t;t:Play()
 return t
end
local function stopFades(list)
 for _,o in ipairs(list)do if fades[o]then fades[o]:Cancel();fades[o]=nil end end
end
local function scramble(text,amount)
 if amount<=0 then return text end
 local out={}
 for _,code in utf8.codes(text)do
  local ch=utf8.char(code)
  if ch~=' 'and math.random()<amount then ch=glyphs[math.random(#glyphs)]end
  table.insert(out,ch)
 end
 return table.concat(out)
end
local function lowMotion()return player:GetAttribute('ReducedMotion')==true end
--[[ W.Say(text, options)
 Font      Enum.Font (default SpecialElite)
 Color     text colour
 Type      seconds per character of the typewriter (0 = instant)
 Hold      seconds the line stays after it is typed (nil = until replaced or cleared)
 Glitch    0..1 how often characters scramble while it shows
 Chroma    red/cyan split shadow
 Shake     jitter the line
 Returns the token of this line; W.Clear(token) only clears it if still current. ]]
function W.Say(text,options)
 options=options or {}
 build()
 token+=1;local mine=token
 gui.Enabled=true
 stopFades({line,red,cyan})
 local font=options.Font or Enum.Font.SpecialElite
 for _,l in ipairs({line,red,cyan})do l.Font=font;l.Text=text;l.MaxVisibleGraphemes=0 end
 line.TextColor3=options.Color or Color3.fromRGB(236,230,246)
 line.TextTransparency=0;line.TextStrokeTransparency=.35
 local chroma=options.Chroma and not lowMotion()
 red.TextTransparency=chroma and .55 or 1;cyan.TextTransparency=chroma and .55 or 1
 local count=utf8.len(text)or #text
 local per=options.Type or .045
 local glitch=lowMotion()and 0 or (options.Glitch or 0)
 local shake=options.Shake and not lowMotion()
 task.spawn(function()
  local started=os.clock();local typed=0
  while token==mine and gui.Parent do
   local age=os.clock()-started
   typed=per>0 and math.min(count,math.floor(age/per))or count
   local jitter=shake and Vector2.new(math.random(-2,2),math.random(-1,1))or Vector2.zero
   line.MaxVisibleGraphemes=typed;red.MaxVisibleGraphemes=typed;cyan.MaxVisibleGraphemes=typed
   local shown=glitch>0 and math.random()<glitch and scramble(text,.18)or text
   line.Text=shown
   if chroma then
    local split=math.random()<.25 and math.random(2,5)or 1
    red.Text=shown;cyan.Text=shown
    red.Position=UDim2.new(.5,-split+jitter.X,0,8+jitter.Y);cyan.Position=UDim2.new(.5,split+jitter.X,0,8-jitter.Y)
   end
   line.Position=UDim2.new(.5,jitter.X,0,8+jitter.Y)
   if options.Hold and typed>=count and age>=count*per+options.Hold then
    if token==mine then W.Clear(mine)end
    break
   end
   task.wait(per>0 and math.min(per,.05)or .05)
  end
  if token~=mine then return end
  line.Text=text;line.Position=UDim2.new(.5,0,0,8)
 end)
 return mine
end
-- Fades the current line (only if `which` is still the current one, when given).
function W.Clear(which,seconds)
 if not gui or (which and which~=token)then return end
 token+=1
 seconds=seconds or .6
 for _,l in ipairs({line,red,cyan})do fade(l,seconds,{TextTransparency=1,TextStrokeTransparency=1})end
end
--[[ W.Title(title, options): the reveal card under the whisper.
 Tier (default 'SECRET'), Color, Font (default FredokaOne), Hold seconds (default 3.5). ]]
function W.Title(title,options)
 options=options or {}
 build()
 gui.Enabled=true
 local color=options.Color or Color3.new(1,1,1)
 cardTier.Font=Enum.Font.FredokaOne;cardTier.Text='✦ '..(options.Tier or 'SECRET')..' ✦'
 cardTier.TextColor3=color:Lerp(Color3.new(1,1,1),.35)
 cardTitle.Font=options.Font or Enum.Font.FredokaOne;cardTitle.Text=title;cardTitle.TextColor3=color
 cardTitle.MaxVisibleGraphemes=-1
 local id=(card:GetAttribute('Shown')or 0)+1;card:SetAttribute('Shown',id)
 stopFades({card,cardTitle,cardTier})
 card.Position=UDim2.new(.5,0,0,lowMotion()and 54 or 40)
 cardTitle.TextTransparency=1;cardTier.TextTransparency=1
 fade(card,.45,{Position=UDim2.new(.5,0,0,54)})
 fade(cardTitle,.35,{TextTransparency=0,TextStrokeTransparency=.2})
 fade(cardTier,.6,{TextTransparency=.05,TextStrokeTransparency=.4})
 task.delay(options.Hold or 3.5,function()
  if card:GetAttribute('Shown')~=id then return end
  fade(cardTitle,.8,{TextTransparency=1,TextStrokeTransparency=1})
  fade(cardTier,.8,{TextTransparency=1,TextStrokeTransparency=1})
 end)
end
-- A slow pulse used by THE DOG: the whisper breathes between visible and faint.
function W.Breathe(which,period)
 task.spawn(function()
  local started=os.clock()
  while gui and which==token do
   local a=.5+.5*math.cos((os.clock()-started)/period*math.pi*2)
   line.TextTransparency=a*.55
   Run.Heartbeat:Wait()
  end
 end)
end
return W

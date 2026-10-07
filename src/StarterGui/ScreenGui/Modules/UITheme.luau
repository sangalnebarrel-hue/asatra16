-- Read design tokens and decorations from the actual SOURCE instances.
local Tween=game:GetService('TweenService')
local GuiService=game:GetService('GuiService')
local UserInput=game:GetService('UserInputService')
local GameIcons=require(game:GetService('ReplicatedStorage'):WaitForChild('GameIcons'))
local gui=script.Parent.Parent;local main=gui:WaitForChild('MainWindow')
local yard=main.Content.PageContainer.YardPage
local cardTemplate=yard.LatestFoundCard.Main
local buttonTemplate=main.Sidebar.DogsButton
local activeTemplate=main.Sidebar.YardButton
local headerTemplate=yard.YardHeader
local U={FontFace=Font.fromEnum(Enum.Font.FredokaOne)};local C=Color3.fromRGB
-- Presentation labels only. Keep canonical ability/slot IDs in all requests.
function U.AbilityLabel(id)return(tostring(id or '—'):gsub('(%l)(%u)','%1 %2'))end
function U.DigSlotLabel(id)local value=tostring(id or '');local number=value:match('^DigSlot_(%d+)$');return number and 'DIG SPOT '..number or(value~=''and value or 'Storage')end
local function ink(instance,fallback)local stroke=instance:FindFirstChildWhichIsA('UIStroke');return stroke and stroke.Color or fallback end
U.Colors={metal=C(232,244,255),secondary=C(220,237,253),navy=C(218,237,253),panel=C(255,255,255),edge=C(23,43,76),orange=C(34,184,242),nav=C(55,168,241),gold=C(249,180,35),blue=C(38,164,243),green=C(125,219,48),red=C(247,73,112),purple=C(161,103,242),text=C(23,43,76),muted=C(83,112,150),light=C(247,251,255)}
U.Rarity={Common=C(170,190,205),Rare=U.Colors.blue,Epic=U.Colors.purple,Legendary=U.Colors.gold,Mythic=U.Colors.red,Secret=C(230,115,245),Uncommon=U.Colors.green,['Brainrot God']=U.Colors.red}
U.Tiers={C(102,166,225),C(130,219,76),C(162,181,202),C(249,180,57),C(255,146,32),C(228,75,153),C(255,48,116),C(203,58,245),C(179,114,255),C(255,55,144)}
function U.New(class,props,parent)local o=Instance.new(class);for k,v in pairs(props)do o[k]=v end;o.Parent=parent;return o end
function U.SafeArea(screen)
 local size=screen.AbsoluteSize
 local ok,safe,own=pcall(function()return GuiService:GetInsetArea(Enum.ScreenInsets.CoreUISafeInsets),GuiService:GetInsetArea(screen.ScreenInsets)end)
 if ok then
  -- Inset rectangles share the Core UI origin; subtract this ScreenGui's origin.
  local left=math.clamp(safe.Min.X-own.Min.X,0,size.X)
  local top=math.clamp(safe.Min.Y-own.Min.Y,0,size.Y)
  local right=math.clamp(safe.Max.X-own.Min.X,left,size.X)
  local bottom=math.clamp(safe.Max.Y-own.Min.Y,top,size.Y)
  return left,top,right-left,bottom-top
 end
 local top=screen.IgnoreGuiInset and 64 or 0
 return 0,top,size.X,math.max(1,size.Y-top)
end
function U.SafePosition(screen,w,h,factor,margin)
 local left,top,width,height=U.SafeArea(screen);local size=screen.AbsoluteSize
 local halfW,halfH=w*factor/2,h*factor/2
 local function fit(value,minimum,maximum)return maximum<minimum and(minimum+maximum)/2 or math.clamp(value,minimum,maximum)end
 return UDim2.fromOffset(fit(size.X/2,left+margin+halfW,left+width-margin-halfW),fit(size.Y/2,top+margin+halfH,top+height-margin-halfH))
end
function U.LayoutTouchHUD(screen)
 local hud=screen:FindFirstChild('HUD');if not hud then return end
 local settings=hud:FindFirstChild('SimpleSettings');local notice=hud:FindFirstChild('OfflineEarningsNotice')
 local left,top,width=U.SafeArea(screen);local touch=UserInput.TouchEnabled
 if settings then
  settings.AnchorPoint=Vector2.new(1,1);settings.Position=UDim2.new(1,-18,1,-18)
 end
 if notice then
  notice.AnchorPoint=Vector2.new(.5,0);notice.Position=UDim2.fromOffset(left+width/2,top+10);notice.Size=UDim2.fromOffset(320,57)
  local caption=notice:FindFirstChild('Caption');if caption then caption.TextSize=19;caption.Size=UDim2.new(1,-12,1,-4)end
 end
 if not touch then return end
 -- Keep informational HUD clear of the built-in thumbstick and jump regions.
 local factor=math.clamp(width/920,.48,.64);local right=left+width-12;local statX=right-320*factor
 for _,name in ipairs({'MoneyWidget','XPWidget'})do
  local widget=hud:FindFirstChild(name)
  if widget then
   local scale=widget:FindFirstChildWhichIsA('UIScale');if scale then scale.Scale=factor end
   widget.Position=UDim2.fromOffset(statX,top+(name=='MoneyWidget'and 10+46*factor or 13+78*factor))
   if name=='XPWidget' then
    local value=widget.Main:FindFirstChild('XPText')
    if value then
     value.TextWrapped=false;value.TextScaled=true
     local limit=value:FindFirstChildWhichIsA('UITextSizeConstraint')or U.New('UITextSizeConstraint',{},value)
     limit.MinTextSize=1;limit.MaxTextSize=13;limit.MinTextSize=11
    end
   end
  end
 end
 local settingsY=top+20+78*factor
 if settings then settings.AnchorPoint=Vector2.new(1,0);settings.Position=UDim2.fromOffset(right,settingsY)end
 if notice then
  notice.AnchorPoint=Vector2.new(1,0);notice.Position=UDim2.fromOffset(right,settingsY+49);notice.Size=UDim2.fromOffset(math.min(264,width-24),57)
  local caption=notice:FindFirstChild('Caption');if caption then caption.TextSize=15 end
 end
end
local function decorate(o,template)
 for _,v in ipairs(template:GetChildren())do
  if v:IsA('UICorner')or v:IsA('UIStroke')or v:IsA('UIGradient')then v:Clone().Parent=o end
 end
end
function U.Round(o,n)
 local old=o:FindFirstChildWhichIsA('UICorner');if old then old:Destroy()end
 return U.New('UICorner',{CornerRadius=UDim.new(0,n or 10)},o)
end
function U.Stroke(o,c,t,a)
 local old=o:FindFirstChildWhichIsA('UIStroke');if old then old:Destroy()end
 return U.New('UIStroke',{Color=c or U.Colors.edge,Thickness=t or 3,Transparency=a or 0,ApplyStrokeMode=Enum.ApplyStrokeMode.Border},o)
end
function U.Gradient(o,a,b,rotation)
 local old=o:FindFirstChildWhichIsA('UIGradient');if old then old:Destroy()end
 o.BackgroundColor3=Color3.new(1,1,1);return U.New('UIGradient',{Color=ColorSequence.new(a,b),Rotation=rotation or 90},o)
end
function U.Frame(p,n,x,y,w,h,c)return U.New('Frame',{Name=n,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),BackgroundColor3=c or U.Colors.panel,BorderSizePixel=0},p)end
function U.Shadow(o)
 -- A sibling shadow must not become an extra cell in an automatic layout.
 if o.Parent:FindFirstChildWhichIsA('UIGridLayout')or o.Parent:FindFirstChildWhichIsA('UIListLayout')then return end
 local shadow=U.New('Frame',{Name='DropShadow',Position=o.Position+UDim2.fromOffset(3,5),Size=o.Size,AnchorPoint=o.AnchorPoint,BackgroundColor3=U.Colors.edge,BackgroundTransparency=.18,BorderSizePixel=0,ZIndex=math.max(1,o.ZIndex-1)},o.Parent)
 U.Round(shadow,10)
 local cs={}
 for _,key in ipairs({'Position','Size','AnchorPoint','Visible'})do table.insert(cs,o:GetPropertyChangedSignal(key):Connect(function()shadow[key]=key=='Position'and(o.Position+UDim2.fromOffset(3,5))or o[key]end))end
 o.Destroying:Connect(function()for _,c in ipairs(cs)do c:Disconnect()end;shadow:Destroy()end)
 return shadow
end
function U.Panel(p,n,x,y,w,h,raised)
 local o=U.Frame(p,n,x,y,w,h);o.ZIndex=2;decorate(o,cardTemplate)
 if not o:FindFirstChildWhichIsA('UIStroke')then U.Stroke(o)end
 if raised then U.Shadow(o)end
 return o
end
U.Card=U.Panel;U.PreviewCard=U.Panel
function U.Header(p,n,x,y,w,h)
 local o=U.Frame(p,n,x,y,w,h,headerTemplate.BackgroundColor3);o.ZIndex=3;decorate(o,headerTemplate)
 if not o:FindFirstChildWhichIsA('UIStroke')then U.Stroke(o)end
 return o
end
function U.Text(p,s,x,y,w,h,size,color,bold)
 return U.New('TextLabel',{Name='Label',Text=tostring(s),Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),BackgroundTransparency=1,TextColor3=color or U.Colors.text,FontFace=U.FontFace,TextSize=size or 20,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,TextStrokeColor3=buttonTemplate.TextStrokeColor3,TextStrokeTransparency=1,ZIndex=4},p)
end
function U.Center(p,s,x,y,w,h,size,c,b)local t=U.Text(p,s,x,y,w,h,size,c,b);t.TextXAlignment=Enum.TextXAlignment.Center;return t end
function U.Title(p,s,x,y,w,h)return U.Text(p,s,x,y,w,h,30,U.Colors.text,true)end
function U.Glow(o,c)U.Stroke(o,c or U.Colors.gold,4)end
local enhanced=setmetatable({},{__mode='k'})
local function saturated(color)
 local h,s,v=color:ToHSV()
 if s<.22 then return U.Colors.blue:Lerp(Color3.new(1,1,1),.28)end
 return Color3.fromHSV(h,math.max(s,.72),math.max(v,.84))
end
function U.SetButtonEnabled(button,on)
 button.Active=on==true;button.Selectable=on==true;button:SetAttribute('UIEnabled',on==true)
end
function U.EnhanceButton(button,color)
 if not button:IsA('GuiButton')then return end
 if enhanced[button]then return end
 -- Transparent hit targets select a visible card; painting them would cover its artwork.
 local face=button
 if button.BackgroundTransparency>=.95 then
  local surface=button.Parent and button.Parent:FindFirstChild('Surface')
  if not surface or not surface:IsA('Frame')then return end
  face=surface
 end
 enhanced[button]=true;button.AutoButtonColor=false;button:SetAttribute('PawpadAnimated',true)
 local base=saturated(color or button:GetAttribute('ButtonBaseColor')or face.BackgroundColor3)
 button:SetAttribute('ButtonBaseColor',base)
 U.Round(face,10)
 local existingStroke=face:FindFirstChildWhichIsA('UIStroke')
 if existingStroke then existingStroke.Enabled=true;existingStroke.Color=U.Colors.edge;existingStroke.Thickness=3;existingStroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border else U.Stroke(face,U.Colors.edge,3)end
 local gradient=face:FindFirstChildWhichIsA('UIGradient')or U.New('UIGradient',{},face)
 local motionTarget=face==button and button or button.Parent
 local scale=motionTarget:FindFirstChildWhichIsA('UIScale')or U.New('UIScale',{Name='ButtonMotion'},motionTarget)
 local hover,pressed=false,false;local tween
 local function draw()
  if not button.Parent then return end
  local enabled=button.Active and button:GetAttribute('UIEnabled')~=false
  local current=button:GetAttribute('ButtonBaseColor')or base
  local tone=not enabled and current:Lerp(Color3.fromRGB(117,133,158),.7)or pressed and current:Lerp(U.Colors.edge,.24)or hover and current:Lerp(Color3.new(1,1,1),.12)or current
  face.BackgroundColor3=Color3.new(1,1,1);gradient.Color=ColorSequence.new(tone:Lerp(Color3.new(1,1,1),.1),tone);gradient.Rotation=90
  local stroke=face:FindFirstChildWhichIsA('UIStroke');if stroke then stroke.Color=enabled and U.Colors.edge or Color3.fromRGB(99,116,144)end
  if tween then tween:Cancel()end
  tween=Tween:Create(scale,TweenInfo.new(.09),{Scale=not enabled and 1 or pressed and .96 or hover and 1.025 or 1});tween:Play()
 end
 button.MouseEnter:Connect(function()hover=true;draw()end);button.MouseLeave:Connect(function()hover=false;pressed=false;draw()end)
 button.MouseButton1Down:Connect(function()pressed=true;draw()end);button.MouseButton1Up:Connect(function()pressed=false;draw()end)
 button.SelectionGained:Connect(function()hover=true;draw()end);button.SelectionLost:Connect(function()hover=false;pressed=false;draw()end)
 button:GetPropertyChangedSignal('Active'):Connect(draw);button:GetAttributeChangedSignal('UIEnabled'):Connect(draw);button:GetAttributeChangedSignal('ButtonBaseColor'):Connect(draw)
 face:GetPropertyChangedSignal('BackgroundColor3'):Connect(function()
  local value=face.BackgroundColor3
  if value~=Color3.new(1,1,1)then button:SetAttribute('ButtonBaseColor',saturated(value))end
 end)
 draw()
end
function U.Button(p,n,s,x,y,w,h,fn,c)
 local b=U.New('TextButton',{Name=n,Text='',Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),BackgroundColor3=c or U.Colors.blue,BorderSizePixel=0,AutoButtonColor=false,Selectable=fn~=nil,Active=fn~=nil,ZIndex=3},p)
 local caption=U.Center(b,s,6,2,w-12,h-4,math.min(23,h*.45),Color3.new(1,1,1),true);caption.TextStrokeTransparency=0;caption.TextStrokeColor3=U.Colors.edge;caption.Name='Caption';caption.Size=UDim2.new(1,-12,1,-4);caption.TextWrapped=false;caption.TextScaled=true;U.New('UITextSizeConstraint',{MinTextSize=12,MaxTextSize=math.min(23,h*.45)},caption)
 U.EnhanceButton(b,c or U.Colors.blue)
 if fn then b.Activated:Connect(function(...)if b.Active and b:GetAttribute('UIEnabled')~=false then fn(...)end end)end
 return b
end
function U.SecondaryButton(...)return U.Button(...)end
function U.DangerButton(p,n,s,x,y,w,h,fn)return U.Button(p,n,s,x,y,w,h,fn,U.Colors.red)end
function U.Tab(p,n,s,x,y,w,h,fn,on)return U.Button(p,n,s,x,y,w,h,fn,on and activeTemplate.BackgroundColor3 or U.Colors.nav)end
function U.Badge(p,s,x,y,w,c)local b=U.Frame(p,'Badge',x,y,w,28,c or U.Colors.nav);U.Round(b,7);U.Stroke(b,U.Colors.edge,2);U.Center(b,s,3,0,w-6,28,16,U.Colors.text,true);return b end
function U.Bar(p,x,y,w,h,value,c,caption)
 local b=U.Panel(p,'Progress',x,y,w,h);local f=U.Frame(b,'Fill',3,3,math.max(0,(w-6)*math.clamp(value,0,1)),h-6,c or U.Colors.green);U.Round(f,6)
 if caption then U.Center(b,caption,0,0,w,h,15,nil,true)end;return b
end
U.ProgressBar=U.Bar
function U.Scroll(p,n,x,y,w,h)return U.New('ScrollingFrame',{Name=n,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=6,ScrollBarImageColor3=U.Colors.gold,ScrollingDirection=Enum.ScrollingDirection.Y},p)end
function U.Grid(p,n,x,y,w,h,columns,cellH)local sc=U.Scroll(p,n,x,y,w,h);local cw=math.floor((w-12-(columns-1)*12)/columns);U.New('UIGridLayout',{CellSize=UDim2.fromOffset(cw,cellH),CellPadding=UDim2.fromOffset(12,12),SortOrder=Enum.SortOrder.LayoutOrder},sc);return sc,cw end
function U.Search(p,n,placeholder,value,x,y,w,fn)
 local b=U.New('TextBox',{Name=n,Text=value or'',PlaceholderText=placeholder,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,42),BackgroundColor3=U.Colors.navy,TextColor3=U.Colors.text,PlaceholderColor3=U.Colors.muted,FontFace=U.FontFace,TextSize=18,ClearTextOnFocus=false,TextXAlignment=Enum.TextXAlignment.Left},p)
 U.Round(b,8);U.Stroke(b);U.New('UIPadding',{PaddingLeft=UDim.new(0,12),PaddingRight=UDim.new(0,8)},b);b.FocusLost:Connect(function()fn(b.Text)end);return b
end
U.Input=U.Search
function U.Cycle(p,n,label,values,current,x,y,w,fn)return U.Button(p,n,label..'  ▾',x,y,w,40,#values>0 and function()local i=table.find(values,current)or 1;fn(values[i%#values+1])end or nil)end
function U.Modal(parent,name,title,w,h)
 local box=U.Frame(parent,name,0,0,w,h,main.BackgroundColor3);box.AnchorPoint=Vector2.new(.5,.5);box.Position=UDim2.fromScale(.5,.5);box.ZIndex=2;decorate(box,main)
 U.Round(box,18);U.Stroke(box,U.Colors.edge,3);box.BackgroundColor3=Color3.fromRGB(255,251,242)
 local body=U.Panel(box,'ModalBody',10,64,w-20,h-74);body.ZIndex=1
 U.Header(box,'ModalHeader',10,10,w-20,48);U.Text(box,title,24,14,w-48,40,26,U.Colors.text,true)
 local scale=U.New('UIScale',{Scale=1},box)
 local function resize()
  local _,_,width,height=U.SafeArea(gui);scale.Scale=math.min(1,(width-24)/w,(height-24)/h)
  box.Position=U.SafePosition(gui,w,h,scale.Scale,12)
 end
 local c=gui:GetPropertyChangedSignal('AbsoluteSize'):Connect(resize);local inset=GuiService:GetPropertyChangedSignal('TopbarInset'):Connect(resize)
 box.Destroying:Connect(function()c:Disconnect();inset:Disconnect()end);resize()
 return box
end
function U.Overlay(parent,name)return U.New('Frame',{Name=name,Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Active=true,ZIndex=80},parent)end

function U.Icon(p,key,x,y,size,color)
 local assetKey=({Collection='DogDex',Storage='Inventory',Discoveries='Inventory',Marketplace='Shop'})[key]or key
 if U.Assets and U.Assets[assetKey]then return U.AssetIcon(p,assetKey,x,y,size)end
 key=GameIcons.FallbackKey(assetKey)
 local fallbackAsset=({Storage='Inventory',Discoveries='Inventory'})[key]or key
 if U.Assets and U.Assets[fallbackAsset]then return U.AssetIcon(p,fallbackAsset,x,y,size)end
 local f=U.Frame(p,'Icon'..key,x,y,size,size);f.BackgroundTransparency=1;local ink=color or U.Colors.muted
 local function box(a,b,w,h,r)local o=U.Frame(f,'Glyph',a*size,b*size,w*size,h*size,ink);if r then U.Round(o,r*size)end;return o end
 if key=='Dogs' or key=='Paw'then box(.27,.46,.5,.4,.2);for _,v in ipairs({{.1,.25},{.31,.08},{.57,.08},{.79,.25}})do box(v[1],v[2],.18,.27,.1)end
 elseif key=='Yard'then local roof=box(.2,.12,.55,.55,.04);roof.Rotation=45;box(.2,.4,.6,.48,.02);box(.43,.57,.17,.31,.01).BackgroundColor3=U.Colors.navy
 elseif key=='Coins'then
  local coin=box(.08,.08,.84,.84,.5);U.Gradient(coin,C(255,237,93),C(229,143,12));U.Stroke(coin,C(104,62,10),size*.025)
  local ring=box(.18,.18,.64,.64,.5);U.Gradient(ring,C(255,199,49),C(255,219,90));U.Stroke(ring,C(190,117,12),size*.025);U.Icon(ring,'Paw',size*.11,size*.1,size*.42,C(217,132,10))
 elseif key=='Ticket'then
  local body=box(.04,.24,.92,.52,.08);U.Gradient(body,C(255,229,75),C(255,159,25));U.Stroke(body,U.Colors.edge,size*.03)
  for _,xx in ipairs({.24,.74})do for yy=0,3 do box(xx,.3+yy*.1,.025,.05).BackgroundColor3=U.Colors.edge end end
  U.Icon(body,'Paw',size*.34,size*.1,size*.25,U.Colors.edge)
 elseif key=='Bones'then
  local bone=box(.14,.39,.72,.24,.11);bone.Rotation=-25;for _,v in ipairs({{.08,.39},{.12,.57},{.65,.11},{.75,.29}})do local b=box(v[1],v[2],.22,.22,.11);U.Gradient(b,C(255,247,215),C(203,177,138))end
 elseif key=='Dig'then
  local handle=box(.45,.2,.12,.72,.03);handle.Rotation=40;handle.BackgroundColor3=U.Colors.secondary;local metal=box(.2,.16,.62,.17,.02);metal.Rotation=35;U.Gradient(metal,C(191,217,237),C(68,109,150))
 elseif key=='Luck'then
  for _,v in ipairs({{.14,.16},{.49,.16},{.14,.5},{.49,.5}})do local leaf=box(v[1],v[2],.36,.36,.18);U.Gradient(leaf,C(145,248,90),C(35,170,28))end
 elseif key=='DogDex' or key=='Collection'then box(.1,.2,.34,.6,.04);box(.49,.2,.34,.6,.04);box(.45,.22,.025,.61)
 elseif key=='Trade'then box(.16,.28,.6,.11);local a=box(.68,.19,.22,.22);a.Rotation=45;box(.24,.62,.6,.11);local b=box(.12,.56,.22,.22);b.Rotation=45
 elseif key=='Lab'then box(.4,.08,.2,.45);box(.3,.04,.4,.12,.03);box(.18,.56,.64,.32,.06);box(.29,.42,.42,.27,.04);box(.35,.62,.12,.1,.03).BackgroundColor3=Color3.new(1,1,1)
 elseif key=='Shop' or key=='Marketplace'then box(.13,.28,.74,.46,.04);box(.05,.14,.14,.14);for _,xx in ipairs({.23,.65})do box(xx,.79,.15,.15,.08)end
 elseif key=='Events'then box(.1,.2,.8,.68,.04);for _,xx in ipairs({.27,.63})do box(xx,.07,.1,.25,.03)end;for a=0,2 do for b=0,1 do box(.22+a*.22,.43+b*.2,.12,.11).BackgroundColor3=U.Colors.navy end end
 elseif key=='Records'then for i=0,2 do box(.13+i*.26,.6-i*.2,.18,.28+i*.2,.02)end
 elseif key=='Discoveries' or key=='Storage'then box(.12,.2,.76,.67,.04);box(.46,.2,.06,.67).BackgroundColor3=U.Colors.navy;box(.12,.34,.76,.06).BackgroundColor3=U.Colors.navy
 else U.Center(f,key=='Coins' and '●'or key=='Bones'and '◆'or key=='Dig'and '⚒'or key=='Luck'and '✦'or '★',0,0,size,size,size*.85,ink,true)end
 return f
end
U.Fmt=require(game.ReplicatedStorage.PriceFormat).Number
function U.Count(t)local n=0;for _ in pairs(t or {})do n+=1 end;return n end
function U.Weight(n)return type(n)=='number'and string.format('%.10g kg',n)or '—'end
function U.Odds(n)return n and n>0 and ('1 in '..string.format('%.6g',1/n))or '—'end
-- DOGROTS candy interface. Applies presentation before gameplay controllers bind.
U.Assets={Dogs='rbxassetid://117639585361256',Inventory='rbxassetid://77546579160081',Yard='rbxassetid://115488468002446',Shop='rbxassetid://99434251630478',DogDex='rbxassetid://124671430150778',Lab='rbxassetid://105402832269661',Events='rbxassetid://86724140753338',Trade='rbxassetid://137537596011172'}
GameIcons.Apply(U.Assets)
local WHITE=C(255,255,255)
local NAVY=C(23,43,76)
local PALE=C(232,244,255)
local specs={
 {key='Dogs',label='DOGS',color=C(255,169,38)},
 {key='Inventory',label='BAG',color=C(26,192,239)},
 {key='Yard',label='MY YARD',color=C(123,219,51)},
 {key='Shop',label='SHOP',color=C(248,79,170)},
 {key='DogDex',label='INDEX',color=C(92,142,250)},
 {key='Lab',label='LAB',color=C(162,105,246)},
 {key='Trade',label='TRADE',color=C(41,204,168)},
 {key='Events',label='EVENTS',color=C(255,192,32)},
}
local byKey={};for _,s in ipairs(specs)do byKey[s.key]=s end
local function rect(o,x,y,w,h)
 o.AnchorPoint=Vector2.zero;o.Position=UDim2.fromOffset(x,y);o.Size=UDim2.fromOffset(w,h)
end
local function surface(o,color,radius,thickness)
 o.BackgroundColor3=color;o.BorderSizePixel=0
 local g=o:FindFirstChildWhichIsA('UIGradient');if g then g.Color=ColorSequence.new(WHITE,WHITE);g.Transparency=NumberSequence.new(0);g.Enabled=true end
 local s=o:FindFirstChildWhichIsA('UIStroke')
 if s then s.Enabled=true;s.Color=NAVY;s.Thickness=thickness or 2;s.Transparency=0;s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border else U.Stroke(o,NAVY,thickness or 2)end
 U.Round(o,radius or 12)
end
local function typeface(o,size,white)
 o.Font=Enum.Font.FredokaOne;o.TextColor3=white and WHITE or NAVY
 o.TextStrokeColor3=NAVY;o.TextStrokeTransparency=white and 0 or 1
 o.TextScaled=false;o.TextSize=size or 19;o.TextWrapped=true
 if o:IsA('TextLabel')then for _,c in ipairs(o:GetChildren())do if c:IsA('UIStroke')then c.Enabled=false end end end
 for _,c in ipairs(o:GetChildren())do if c:IsA('UITextSizeConstraint')then c.MinTextSize=8;c.MaxTextSize=size or 24 end end
end
function U.AssetIcon(parent,key,x,y,size,slot)
 -- Several icons can share a parent. Rebuilding the same icon slot reuses it;
 -- callers replacing an icon with another key can pass a stable explicit slot.
 local identity=slot or(tostring(key)..'@'..tostring(x)..':'..tostring(y))
 local icon
 for _,child in ipairs(parent:GetChildren())do
  if child:IsA('ImageLabel')and child.Name=='CandyIcon'and child:GetAttribute('CandyIconSlot')==identity then icon=child;break end
 end
 if not icon then icon=U.New('ImageLabel',{Name='CandyIcon',BackgroundTransparency=1,ScaleType=Enum.ScaleType.Fit},parent)end
 icon:SetAttribute('CandyIconSlot',identity);icon:SetAttribute('CandyIconKey',key)
 icon.Image=U.Assets[key]or GameIcons.Resolve(key)or''
 icon.Position=UDim2.fromOffset(x,y);icon.Size=UDim2.fromOffset(size,size);icon.ZIndex=parent.ZIndex+2
 return icon
end
function U.SetNavState(button,on)
 local key=button:GetAttribute('CandyPage') or button.Name:gsub('Button$','')
 local spec=byKey[key];if not spec then return end
 surface(button,spec.color,12,on and 4 or 2)
 local marker=button:FindFirstChild('SelectedMark');if marker then marker.Visible=on end
end
function U.LayoutYard(y)
 -- Yard: a large world preview and compact information cards.
 rect(y.YardHeader,14,14,903,50);rect(y.YardHeader.YardHeaderTitle,20,0,580,50)
 rect(y.YardPreviewPanel,14,80,538,300);surface(y.YardPreviewPanel,C(210,239,255),15,2)
 y.YardPreviewPanel.YardName.Text='YOUR YARD / HOME BASE';typeface(y.YardPreviewPanel.YardName,16,false)
 rect(y.StatsGrid,572,80,345,300)
 local grid=y.StatsGrid:FindFirstChildWhichIsA('UIGridLayout');if grid then grid.CellSize=UDim2.fromOffset(166,142);grid.CellPadding=UDim2.fromOffset(13,16)end
 local tints={IncomeCard=C(226,250,196),LevelCard=C(216,237,255),StorageCard=C(252,229,248),KennelsCard=C(255,244,198)}
 for name,tint in pairs(tints)do if y.StatsGrid:FindFirstChild(name)then
  local card=y.StatsGrid[name];surface(card,tint,13,2);card.Accent.Visible=false
  rect(card.Label,14,12,138,43);typeface(card.Label,17,false)
  rect(card.Value,14,66,138,57);typeface(card.Value,33,false)
 end end
 y.YardPreviewPanel.YardViewport.BackgroundColor3=C(168,217,243)
 rect(y.YardPreviewPanel.YardViewport,12,12,514,236)
 rect(y.YardPreviewPanel.YardName,16,258,506,30)
 rect(y.LatestFoundCard,14,396,903,104)
 local latest=y.LatestFoundCard.Main;rect(latest,0,0,903,104);latest.Accent.Visible=false
 rect(latest.PreviewArea,12,12,80,80)
 rect(latest.Title,110,8,430,22);typeface(latest.Title,15,false)
 rect(latest.ItemName,110,32,610,30);typeface(latest.ItemName,23,false)
 rect(latest.ItemInfo,110,67,780,25);typeface(latest.ItemInfo,17,false)
 rect(latest.ClassLabel,654,8,230,24);typeface(latest.ClassLabel,14,false)
 rect(y.ActionButtons,14,520,903,60)
 for i,name in ipairs({'Upgrades','DiggingLayers','GlobalDig'})do
  local holder=y.ActionButtons[name];rect(holder,(i-1)*306,0,291,60)
  surface(holder.Main,({C(134,220,57),C(39,190,241),C(255,185,38)})[i],12,3)
  holder.Main.Position=UDim2.new();holder.Main.Size=UDim2.fromScale(1,1)
  typeface(holder.Main,22,true)
  if not holder.Main:FindFirstChildWhichIsA('UIGradient')then U.New('UIGradient',{Color=ColorSequence.new(WHITE,WHITE)},holder.Main)end
 end
end
function U.ApplyShell(screen)
 -- Rebuild generated decoration when loading a place saved with an editor preview.
 for _,o in ipairs(screen:GetDescendants())do
  if o.Name=='CandyIcon'or o.Name=='CandyCaption'or o.Name=='SelectedMark'or o.Name=='CandyEmpty'or o.Name=='CandyStart'then o:Destroy()end
 end
 for _,o in ipairs(screen.HUD:GetChildren())do if o.Name:match('^Quick')then o:Destroy()end end
 for _,o in ipairs(screen.MainWindow.Sidebar:GetChildren())do if o.Name=='Label'or o.Name=='InventoryButton'then o:Destroy()end end
 screen:SetAttribute('CandyShellV1',true)
 local window=screen.MainWindow;local side=window.Sidebar;local header=window.Header
 local content=window.Content;local pages=content.PageContainer;local hud=screen.HUD
 for _,o in ipairs(window:GetDescendants())do
  if o:IsA('GuiObject')then
   if o:IsA('TextLabel')or o:IsA('TextBox')or o:IsA('TextButton')then
    typeface(o,o:IsA('TextButton')and 20 or math.clamp(o.TextSize,18,24),o:IsA('TextButton'))
    if o:IsA('TextBox')then o.PlaceholderColor3=C(92,116,150)end
   end
   if (o:IsA('Frame')or o:IsA('ScrollingFrame')or o:IsA('TextBox'))and o.BackgroundTransparency<.95 then
    surface(o,o.Name:find('Preview')and C(214,238,255)or WHITE,12,2)
   elseif o:IsA('TextButton')then surface(o,C(37,180,238),10,2);if o.Text~=''then o.BackgroundTransparency=0 end end
   if o.Name:find('Shadow')then o.Visible=false end
   if o:IsA('ScrollingFrame')then o.ScrollBarImageColor3=C(62,171,240);o.ScrollBarThickness=6 end
  end
 end
 for _,o in ipairs(window:GetChildren())do if o:IsA('UIAspectRatioConstraint')or o:IsA('UISizeConstraint')then o:Destroy()end end
 surface(window,PALE,22,4);window.ClipsDescendants=false
 window.AnchorPoint=Vector2.new(.5,.5);window.Position=UDim2.new(.5,0,.5,24);window.Size=UDim2.fromOffset(1160,740)
 local scale=window:FindFirstChildWhichIsA('UIScale')or U.New('UIScale',{Name='ResponsiveScale'},window)
 surface(header,C(35,187,244),17,3);rect(header,12,12,1136,84)
 rect(header.Title,94,8,295,40);header.Title.Text='DOGROTS';typeface(header.Title,34,true)
 rect(header.Subtitle,97,48,295,23);header.Subtitle.Text='YOUR PACK. YOUR ADVENTURE.';typeface(header.Subtitle,13,true)
 U.AssetIcon(header,'Dogs',9,-8,96)
 surface(header.StatsPanel,C(17,120,194),12,2);rect(header.StatsPanel,600,15,360,54)
 rect(header.StatsPanel.StatsContent,10,6,340,42)
 local stats=header.StatsPanel.StatsContent
 local lay=stats:FindFirstChildWhichIsA('UIListLayout');if lay then lay.FillDirection=Enum.FillDirection.Horizontal;lay.Padding=UDim.new(0,8);lay.VerticalAlignment=Enum.VerticalAlignment.Center end
 for _,o in ipairs(stats:GetChildren())do if o:IsA('TextLabel')then o.Size=UDim2.fromOffset(108,40);typeface(o,16,true);o.TextScaled=true;local limit=o:FindFirstChildWhichIsA('UITextSizeConstraint')or U.New('UITextSizeConstraint',{},o);limit.MaxTextSize=17;limit.MinTextSize=10 end end
 surface(header.CloseButton,C(250,76,123),13,3);rect(header.CloseButton,1062,15,58,54);typeface(header.CloseButton,31,true)
 header.CloseButton.Text='X'
 side.BackgroundTransparency=1;rect(side,18,111,176,607)
 for _,o in ipairs(side:GetChildren())do if o:IsA('UIListLayout')or o:IsA('UIPadding')then o:Destroy()end end
 local inventory=side:FindFirstChild('InventoryButton')or U.New('TextButton',{Name='InventoryButton',Text='',AutoButtonColor=false},side)
 local sideOrder={'Yard','Dogs','Inventory','DogDex','Trade','Lab','Shop','Events'}
 for i,key in ipairs(sideOrder)do
  local b=side:FindFirstChild(key..'Button');local spec=byKey[key]
  if b then
   b:SetAttribute('CandyPage',key);b.Text='';b.BackgroundTransparency=0;rect(b,12,12+(i-1)*66,152,56);b.ClipsDescendants=false
   for _,o in ipairs(b:GetChildren())do if o:IsA('UIPadding')or o:IsA('UIAspectRatioConstraint')then o:Destroy()end end
   U.SetNavState(b,key=='Yard');U.AssetIcon(b,key,0,-3,55)
   local text=U.New('TextLabel',{Name='CandyCaption',BackgroundTransparency=1,Text=spec.label,Position=UDim2.fromOffset(55,3),Size=UDim2.fromOffset(94,50),ZIndex=b.ZIndex+3},b)
   typeface(text,18,true);text.TextXAlignment=Enum.TextXAlignment.Left
   local marker=U.Frame(b,'SelectedMark',-5,16,4,24,WHITE);U.Round(marker,3);marker.Visible=key=='Yard'
  end
 end
 U.Text(side,'P  OPEN / CLOSE',12,565,152,20,12,C(81,112,151))
 content.BackgroundTransparency=1;rect(content,211,111,931,610)
 pages.BackgroundTransparency=1;pages.Position=UDim2.new();pages.Size=UDim2.fromScale(1,1)
 for _,p in ipairs(pages:GetChildren())do
  if p:IsA('GuiObject')and p.Name:match('Page$')then
   p.Position=UDim2.new();p.Size=UDim2.fromScale(1,1);p.BackgroundTransparency=1
   local h=p:FindFirstChild('PageHeader')or p:FindFirstChild('InventoryHeader')or p:FindFirstChild('YardHeader')
   local spec=byKey[p.Name:gsub('Page$','')]
   if h then surface(h,spec and spec.color or C(38,177,240),12,2)
    for _,t in ipairs(h:GetDescendants())do if t:IsA('TextLabel')then typeface(t,t.Name=='Capacity'and 20 or 28,true)end end
   end
  end
 end
 U.LayoutYard(pages.YardPage)
 -- Floating lower-left counters, with outline-only contrast over the world.
 local function floating(root,w,h)
  root.AnchorPoint=Vector2.new(0,1);root.Size=UDim2.fromOffset(w,h);root.BackgroundTransparency=1
  root.Main.Position=UDim2.new();root.Main.Size=UDim2.fromScale(1,1);root.Main.BackgroundTransparency=1
  for _,o in ipairs(root:GetDescendants())do
   if o:IsA('UIStroke')then o.Enabled=false end
   if o:IsA('UIPadding')then o:Destroy()end
  end
 end
 local function counter(label,size,color)
  typeface(label,size,true);label.TextColor3=color;label.TextStrokeTransparency=0
  label.TextXAlignment=Enum.TextXAlignment.Left;label.TextWrapped=false
  local stroke=label:FindFirstChildWhichIsA('UIStroke')or U.New('UIStroke',{},label)
  stroke.Name='CandyTextStroke'
  for _,child in ipairs(label:GetChildren())do if child:IsA('UIStroke')and child~=stroke then child:Destroy()end end
  stroke.Enabled=true;stroke.Color=NAVY;stroke.Thickness=2;stroke.Transparency=0
  stroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual;stroke.LineJoinMode=Enum.LineJoinMode.Round
 end
 local money=hud.MoneyWidget;floating(money,320,46)
 money.Main.CurrencyBox.Visible=false;money.Main.Label.Visible=false
 rect(money.Main.Amount,0,0,320,46);counter(money.Main.Amount,40,C(132,255,57))
 if money.Main.Amount.Text:sub(1,1)~='$'then money.Main.Amount.Text='$'..money.Main.Amount.Text end
 local xp=hud.XPWidget;floating(xp,320,32)
 rect(xp.Main.LevelLabel,0,0,100,32);counter(xp.Main.LevelLabel,27,C(78,220,255))
 rect(xp.Main.XPText,108,0,212,32);counter(xp.Main.XPText,18,WHITE);xp.Main.XPText.TextScaled=true
 xp.Main.XPBarBackground.Visible=false
 local dig=hud.GlobalDigWidget;floating(dig,320,32)
 rect(dig.Main.Title,0,0,143,32);counter(dig.Main.Title,21,C(255,209,54))
 rect(dig.Main.ProgressText,148,0,172,32);counter(dig.Main.ProgressText,21,C(255,233,144));dig.Main.ProgressText.TextScaled=true
 dig.Main.ProgressBarBackground.Visible=false
 for _,root in ipairs({money,xp,dig,hud.PawpadWidget,hud.InventoryWidget})do for _,o in ipairs(root:GetChildren())do if o.Name=='Shadow'then o.Visible=false end end end
 -- Reuse the two existing buttons so their gameplay bindings remain intact.
 local tiles={}
 for i,spec in ipairs(specs)do
  local root,b
  if spec.key=='Yard'then root=hud.PawpadWidget;b=root.PawpadButton
  elseif spec.key=='Inventory'then root=hud.InventoryWidget;b=root.InventoryButton
  else root=U.Frame(hud,'Quick'..spec.key,0,0,88,92);root.BackgroundTransparency=1;b=U.New('TextButton',{Name='Open',Text='',AutoButtonColor=false},root)end
  root.AnchorPoint=Vector2.zero;root.Size=UDim2.fromOffset(88,92);root.BackgroundTransparency=1
  for _,o in ipairs(root:GetChildren())do if o:IsA('UIAspectRatioConstraint')or o:IsA('UISizeConstraint')then o:Destroy()end end
  for _,o in ipairs(b:GetChildren())do if o:IsA('GuiObject')then o.Visible=false elseif o:IsA('UIPadding')then o:Destroy()end end
  b.Position=UDim2.new();b.Size=UDim2.fromScale(1,1);b.Text='';b.BackgroundTransparency=0
  surface(b,spec.color,16,3);b:SetAttribute('CandyPage',spec.key)
  U.AssetIcon(b,spec.key,3,-8,82)
  local label=U.New('TextLabel',{Name='CandyCaption',Text=spec.label,BackgroundTransparency=1,Position=UDim2.fromOffset(0,65),Size=UDim2.fromOffset(88,25),ZIndex=b.ZIndex+4},b);typeface(label,17,true)
  if spec.key=='Inventory'then local cap=b.Capacity;cap.Visible=true;rect(cap,44,-6,44,18);typeface(cap,10,true);cap.ZIndex=label.ZIndex+1;cap.BackgroundTransparency=0;surface(cap,NAVY,6,1)end
  local sc=root:FindFirstChildWhichIsA('UIScale')or U.New('UIScale',{Name='CandyHUDScale'},root)
  table.insert(tiles,{root=root,button=b,scale=sc,key=spec.key})
 end
 local statScales={};for _,root in ipairs({money,xp,dig})do statScales[root]=root:FindFirstChildWhichIsA('UIScale')or U.New('UIScale',{Name='CandyHUDScale'},root)end
 screen.Backdrop.BackgroundColor3=C(14,29,58);screen.Backdrop.BackgroundTransparency=.25
 local function resize()
  local v=screen.AbsoluteSize
  if not screen:GetAttribute('StandaloneWindows')then scale.Scale=math.max(.25,math.min(1.05,(v.X-30)/1160,(v.Y-94)/740))end
  local hs=math.clamp(math.min(v.X/1100,(v.Y-158)/420),.34,1)
  if UserInput.TouchEnabled then hs=math.max(.5,hs)end
  -- Lay out tile text in native pixels. A parent UIScale combined with a
  -- minimum text constraint made captions overflow their half-size buttons.
  local tileW=math.max(60,88*hs);local tileH=math.max(48,92*hs)
  local gap=math.max(6,12*hs);local rows=math.ceil(#tiles/2);local totalH=rows*tileH+(rows-1)*gap
  local top=math.max(18,math.min((v.Y-totalH)/2,v.Y-110-totalH))
  for i,t in ipairs(tiles)do
   t.scale.Scale=1;t.root.Size=UDim2.fromOffset(tileW,tileH)
   t.root.Position=UDim2.fromOffset(12+((i-1)%2)*(tileW+gap),top+math.floor((i-1)/2)*(tileH+gap))
   local caption=t.button:FindFirstChild('CandyCaption')
   if caption then
    local captionH=hs<.75 and 17 or 25
    caption.Position=UDim2.fromOffset(2,tileH-captionH);caption.Size=UDim2.fromOffset(tileW-4,captionH)
    caption.TextWrapped=false;caption.TextScaled=true
    local limit=caption:FindFirstChildWhichIsA('UITextSizeConstraint')or U.New('UITextSizeConstraint',{},caption)
    limit.MinTextSize=1;limit.MaxTextSize=hs<.75 and 12 or 17;limit.MinTextSize=11
   end
   local icon=t.button:FindFirstChild('CandyIcon');if icon then local size=hs<.75 and 66*hs or 82*hs;icon.Position=UDim2.fromOffset((tileW-size)/2,-2);icon.Size=UDim2.fromOffset(size,size)end
   local capacity=t.button:FindFirstChild('Capacity')
   if capacity and capacity:IsA('TextLabel')then
    capacity.Position=UDim2.fromOffset(0,-7);capacity.Size=UDim2.fromOffset(tileW,16)
    capacity.TextWrapped=false;capacity.TextScaled=true
    local limit=capacity:FindFirstChildWhichIsA('UITextSizeConstraint')or U.New('UITextSizeConstraint',{},capacity)
    limit.MinTextSize=1;limit.MaxTextSize=hs<.75 and 11 or 12;limit.MinTextSize=10
   end
  end
  for _,sc in pairs(statScales)do sc.Scale=hs end
  money.Position=UDim2.new(0,18,1,-16);xp.Position=UDim2.new(0,18,1,-16-50*hs);dig.Position=UDim2.new(0,18,1,-16-86*hs)
  U.LayoutTouchHUD(screen)
 end
 resize();screen:GetPropertyChangedSignal('AbsoluteSize'):Connect(resize)
 local touchLayout=UserInput:GetPropertyChangedSignal('TouchEnabled'):Connect(resize)
 screen.Destroying:Connect(function()touchLayout:Disconnect()end)
 U.QuickTiles=tiles
 -- Helpful empty states sit outside automatic item grids.
 local dog=pages.DogsPage
 local empty=U.Frame(dog,'CandyEmpty',0,0,0,0);empty.BackgroundTransparency=1;empty.Position=UDim2.fromScale(.02,.26);empty.Size=UDim2.fromScale(.61,.67);empty.ZIndex=12
 U.AssetIcon(empty,'Dogs',160,12,155)
 local title=U.Center(empty,'YOUR PACK STARTS HERE',10,168,525,35,26,NAVY,true)
 U.Center(empty,'Adopt your first dog and put it to work!',30,206,485,45,18,C(81,107,143))
 local go=U.Button(empty,'Go','FIND YOUR FIRST DOG',130,270,290,52,nil,C(129,224,48));go.Active=true;go.Selectable=true
 local function dogEmpty()empty.Visible=dog.DogGrid.Empty.Visible;dog.DogGrid.Empty.TextTransparency=1 end
 dog.DogGrid.Empty:GetPropertyChangedSignal('Visible'):Connect(dogEmpty);dogEmpty()
 local inv=pages.InventoryPage;local e=inv.Browser.GridPanel.Main.Empty
 for _,filter in ipairs(inv.Browser.Filters:GetChildren())do local button=filter:FindFirstChild('Button');if button then typeface(button,14,true);button.TextScaled=true end end
 e.Position=UDim2.fromScale(.07,.31);e.Size=UDim2.fromScale(.86,.32);typeface(e,19,false)
 local cta=U.Button(inv.Browser.GridPanel.Main,'CandyStart','GO TO MY YARD',0,0,246,48,nil,C(129,224,48));cta.Active=true;cta.Selectable=true;cta.AnchorPoint=Vector2.new(.5,0);cta.Position=UDim2.fromScale(.5,.7);cta.ZIndex=15
 local function invEmpty()cta.Visible=e.Visible end;e:GetPropertyChangedSignal('Visible'):Connect(invEmpty);invEmpty()
 -- Illustrated shop banner; catalog availability and purchases stay server-owned.
 local shop=pages.ShopPage;surface(shop.FeaturedPanel,C(224,243,255),12,2)
 U.AssetIcon(shop.FeaturedPanel,'Shop',10,-3,80)
 shop.FeaturedPanel.Title.Position=UDim2.fromScale(.16,.12);shop.FeaturedPanel.Title.Size=UDim2.fromScale(.8,.35);typeface(shop.FeaturedPanel.Title,23,false)
 shop.FeaturedPanel.Description.Position=UDim2.fromScale(.16,.53);shop.FeaturedPanel.Description.Size=UDim2.fromScale(.8,.32);typeface(shop.FeaturedPanel.Description,17,false)
 for _,card in ipairs(shop.ProductGrid:GetChildren())do if card:IsA('Frame')and card:FindFirstChild('Preview')then
  local art=U.AssetIcon(card.Preview,'Shop',0,0,56);art.AnchorPoint=Vector2.new(.5,.5);art.Position=UDim2.fromScale(.5,.5)
  card.Preview.Caption.Visible=false;surface(card.Preview,C(252,225,244),10,1)
  typeface(card.ProductName,18,false);typeface(card.Description,15,false);typeface(card.Price,15,false);typeface(card.Details,17,true)
 end end
 local preview=shop.SelectedProductPanel.Preview;preview.Caption.Visible=false
 local art=U.AssetIcon(preview,'Shop',0,0,110);art.AnchorPoint=Vector2.new(.5,.5);art.Position=UDim2.fromScale(.5,.5)
 surface(preview,C(252,225,244),12,2)
end
function U.AttachNavigation(screen,N)
 for _,t in ipairs(U.QuickTiles or{})do
  if t.key~='Yard'and t.key~='Inventory'then t.button.Activated:Connect(function()N.OpenPage(t.key)end)end
 end
 local pages=screen.MainWindow.Content.PageContainer
 screen.MainWindow.Sidebar.InventoryButton.Activated:Connect(function()N.OpenPage('Inventory')end)
 pages.DogsPage.CandyEmpty.Go.Activated:Connect(function()N.Navigate('Factory')end)
 pages.InventoryPage.Browser.GridPanel.Main.CandyStart.Activated:Connect(function()N.Navigate('Your yard')end)
 local function selection()
  local key=screen:GetAttribute('OpenMenu')or'Yard'
  for _,b in ipairs(screen.MainWindow.Sidebar:GetChildren())do if b:IsA('TextButton')then U.SetNavState(b,b:GetAttribute('CandyPage')==key)end end
 end
 screen:GetAttributeChangedSignal('OpenMenu'):Connect(selection);selection()
end


-- Independent windows share a visual language, never a visible navigation shell.
U.WindowSpecs={
 Yard={Title='MY YARD',Subtitle='Your pack, your progress',Color=C(125,219,48),Icon='Yard'},
 Dogs={Title='MY DOGS',Subtitle='Choose a dog. Give it a job.',Color=C(255,169,38),Icon='Dogs'},
 DogDetail={Title='DOG DETAILS',Subtitle='Your dog, its ability and its next job',Color=C(255,169,38),Icon='Dogs'},
 Inventory={Title='MY BAG',Subtitle='Lucky blocks and discoveries',Color=C(26,192,239),Icon='Inventory'},
 DogDex={Title='DOG INDEX',Subtitle='100 discoveries + exclusive prizes',Color=C(92,142,250),Icon='DogDex'},
 Trade={Title='TRADE',Subtitle='Swap with players in this server',Color=C(41,204,168),Icon='Trade'},
 Shop={Title='PAW MARKET',Subtitle='Everything for a happier pack',Color=C(248,79,170),Icon='Shop'},
 Supplies={Title='SUPPLIES',Subtitle='Small boosts. Big adventures.',Color=C(123,219,51),Icon='Supplies'},
 RewardMachine={Title='DOG-O-MATIC',Subtitle='One DOG TOKEN. One random reward.',Color=C(171,105,247),Icon='RewardMachine'},
 Events={Title='GLOBAL EVENT',Subtitle='A new adventure is on the way',Color=C(255,192,32),Icon='Events'},
 Lab={Title='GENETICS LAB',Subtitle='Discover new possibilities',Color=C(162,105,246),Icon='Lab'},
 Cosmetics={Title='YARD STYLES',Subtitle='Make your home your own',Color=C(248,79,170),Icon='Yard'},
 Discoveries={Title='DISCOVERIES',Subtitle='Every find tells a story',Color=C(26,192,239),Icon='Inventory'},
 LuckyOdds={Title='LUCKY BLOCK',Subtitle='All chances shown before you buy',Color=C(255,169,38),Icon='Inventory'},
 LuckyPad={Title='LUCKY PAD',Subtitle='Place a block, wait, then open it',Color=C(255,169,38),Icon='Inventory'},
 OfflineEarnings={Title='WELCOME BACK',Subtitle='Your pack kept working',Color=C(125,219,48),Icon='Dogs'},
 Shelter={Title='DOG SHELTER',Subtitle='Find your extra dogs a new home',Color=C(255,169,38),Icon='Dogs'},
 TicketShop={Title='GET SPINS',Subtitle='DOG TOKENS for DOG-O-MATIC · chances shown before you buy',Color=C(171,105,247),Icon='Ticket'},
 Settings={Title='SETTINGS',Subtitle='Play your way',Color=C(92,142,250),Icon='Settings'},
}
function U.WindowChrome(page,key,width,close)
 local old=page:FindFirstChild('WindowChrome');if old then old:Destroy()end
 local spec=U.WindowSpecs[key]or{Title=key:gsub('(%l)(%u)','%1 %2'):upper(),Subtitle='',Color=U.Colors.blue,Icon='Dogs'}
 local chrome=U.Frame(page,'WindowChrome',-12,-91,width+24,79,spec.Color);chrome.ZIndex=10;chrome.Size=UDim2.new(1,24,0,79)
 U.Round(chrome,18);U.Stroke(chrome,U.Colors.edge,3)
 local icon=U.Icon(chrome,spec.Icon,10,-5,82)
 local title=U.Text(chrome,spec.Title,98,5,width-193,43,31,WHITE,true);title.TextStrokeTransparency=0;title.ZIndex=14;title.Size=UDim2.new(1,-193,0,43)
 local subtitle=U.Text(chrome,spec.Subtitle,100,47,width-189,24,16,WHITE);subtitle.TextStrokeTransparency=.5;subtitle.ZIndex=14;subtitle.Size=UDim2.new(1,-189,0,24)
 local x=U.Button(chrome,'WindowClose','X',width-47,14,56,50,close,U.Colors.red);x.ZIndex=15;x.Position=UDim2.new(1,-71,0,14)
 local function layoutChrome()
  local compact=gui:GetAttribute('CompactMenus')==true;local landscape=gui:GetAttribute('LandscapeMenus')==true
  local narrow=compact or chrome.AbsoluteSize.X<500
  chrome.Position=UDim2.fromOffset(compact and -4 or -12,compact and -70 or -91);chrome.Size=UDim2.new(1,compact and 8 or 24,0,compact and 64 or 79)
  icon.Position=UDim2.fromOffset(narrow and 6 or 10,narrow and 6 or -5);icon.Size=UDim2.fromOffset(narrow and 52 or 82,narrow and 52 or 82)
  title.Position=UDim2.fromOffset(narrow and 64 or 98,compact and(landscape and 13 or 3)or 7);title.Size=UDim2.new(1,narrow and -128 or -193,0,compact and 34 or 38);title.TextWrapped=false;title.TextScaled=true
  subtitle.Visible=not landscape;subtitle.Position=UDim2.fromOffset(narrow and 66 or 100,compact and 38 or 46);subtitle.Size=UDim2.new(1,narrow and -130 or -189,0,compact and 21 or 23);subtitle.TextWrapped=false;subtitle.TextTruncate=Enum.TextTruncate.AtEnd;subtitle.TextSize=compact and 14 or 16
  x.Position=UDim2.new(1,compact and -54 or -71,0,compact and 10 or 14);x.Size=UDim2.fromOffset(compact and 44 or 56,compact and 44 or 50)
 end
 U.New('UITextSizeConstraint',{MinTextSize=17,MaxTextSize=31},title)
 local changed=page:GetPropertyChangedSignal('AbsoluteSize'):Connect(layoutChrome);local compactChanged=gui:GetAttributeChangedSignal('CompactMenus'):Connect(layoutChrome);local landscapeChanged=gui:GetAttributeChangedSignal('LandscapeMenus'):Connect(layoutChrome);chrome.Destroying:Connect(function()changed:Disconnect();compactChanged:Disconnect();landscapeChanged:Disconnect()end);layoutChrome()
 page:SetAttribute('StandaloneWindow',true)
 return chrome
end
function U.ApplyStandalone(screen)
 screen:SetAttribute('StandaloneWindows',true)
 local main=screen.MainWindow;local pages=main.Content.PageContainer
 main.BackgroundTransparency=1;main.ClipsDescendants=false
 for _,o in ipairs(main:GetChildren())do if o:IsA('UIStroke')then o.Enabled=false end end
 main.Header.Visible=false;main.Sidebar.Visible=false
 main.Size=UDim2.fromOffset(963,726);main.Position=UDim2.new(.5,0,.5,16)
 main.Content.Position=UDim2.fromOffset(16,100);main.Content.Size=UDim2.fromOffset(931,610);main.Content.ClipsDescendants=false
 pages.ClipsDescendants=false
 for _,page in ipairs(pages:GetChildren())do
  if page:IsA('Frame')and page.Name:match('Page$')then
   page.BackgroundTransparency=0;page.BackgroundColor3=C(255,251,242);page.BorderSizePixel=0;page.ClipsDescendants=false
   U.Round(page,16);U.Stroke(page,U.Colors.edge,3)
   U.WindowChrome(page,page.Name:gsub('Page$',''),931)
   -- Original in-page headings remain useful section labels and preserve controller paths.
   local heading=page:FindFirstChild('PageHeader')or page:FindFirstChild('InventoryHeader')or page:FindFirstChild('YardHeader')
   if heading then
    heading.BackgroundColor3=C(244,240,232)
    for _,o in ipairs(heading:GetDescendants())do if o:IsA('TextLabel')then o.TextColor3=U.Colors.text;o.TextStrokeTransparency=1 end end
   end
  end
 end
 screen.Backdrop.BackgroundTransparency=.5
 local dig=screen.HUD:FindFirstChild('GlobalDigWidget');if dig then dig.Visible=false end
 local row=screen.HUD:FindFirstChild('SimpleSettings');if row then row:Destroy()end
 row=U.Frame(screen.HUD,'SimpleSettings',0,0,118,39);row.BackgroundTransparency=1;row.AnchorPoint=Vector2.new(1,1);row.Position=UDim2.new(1,-18,1,-18)
 U.Button(row,'Open','SETTINGS',0,0,118,39,nil,U.Colors.blue).Active=true
 U.LayoutTouchHUD(screen)
 local function font(o)
  if o:IsA('TextLabel')or o:IsA('TextButton')or o:IsA('TextBox')then o.FontFace=U.FontFace end
  if o:IsA('GuiButton')then task.defer(function()if o.Parent then U.EnhanceButton(o)end end)end
 end
 for _,o in ipairs(screen:GetDescendants())do font(o)end
 screen.DescendantAdded:Connect(font)
 local inventoryLayout={}
 for _,name in ipairs({'InventoryHeader','Tabs','Browser','Details'})do local o=pages.InventoryPage:FindFirstChild(name);if o then inventoryLayout[o]={Position=o.Position,Size=o.Size}end end
 local bagDetails=false;local inv=pages.InventoryPage
 local inventoryHeaderLayout={}
 for _,name in ipairs({'Title','Capacity'})do local o=inv.InventoryHeader:FindFirstChild(name);if o then inventoryHeaderLayout[o]={Position=o.Position,Size=o.Size,AnchorPoint=o.AnchorPoint,Visible=o.Visible}end end
 local bagBack=U.Button(inv,'MobileBagBack','BACK TO BAG',12,63,165,42,function()bagDetails=false;inv.Browser.Visible=true;inv.Details.Visible=false;inv.Tabs.Visible=true;inv.MobileBagBack.Visible=false end,U.Colors.blue)
 bagBack.Visible=false;bagBack.ZIndex=20
 local function showBagDetails()
  if not screen:GetAttribute('CompactMenus')then return end
  bagDetails=true;inv.Browser.Visible=false;inv.Details.Visible=true;inv.Tabs.Visible=false;bagBack.Visible=true
 end
 local bagGrid=inv.Browser.GridPanel.Main.ItemGrid
 local function bindBagCard(card)
  if card:IsA('Frame')and card.Name:match('^Entry_')then local b=card:FindFirstChild('Main');if b and b:IsA('GuiButton')then b.Activated:Connect(showBagDetails)end end
 end
 bagGrid.ChildAdded:Connect(bindBagCard);for _,card in ipairs(bagGrid:GetChildren())do bindBagCard(card)end
 inv:GetPropertyChangedSignal('Visible'):Connect(function()if inv.Visible and screen:GetAttribute('CompactMenus')then bagDetails=false;inv.Browser.Visible=true;inv.Details.Visible=false;inv.Tabs.Visible=true;bagBack.Visible=false end end)
 local function resize()
  local v=screen.AbsoluteSize;local scale=main:FindFirstChildWhichIsA('UIScale')
  local _,_,width,height=U.SafeArea(screen)
  local compact=width<700 or height<560
  local landscape=compact and width>height*1.25
  -- Reflow compact windows in actual pixels. A fixed tall design canvas made
  -- landscape text ~8px and left only a sliver of the scrolling content visible.
  local designW=compact and math.min(963,math.max(280,width-24))or 963
  local designH=compact and math.min(1000,math.max(180,height-20))or 726
  local factor=compact and 1 or math.max(.2,math.min(1,(width-28)/designW,(height-36)/designH))
  screen:SetAttribute('CompactMenus',compact);screen:SetAttribute('LandscapeMenus',landscape)
  scale.Scale=factor;main.Size=UDim2.fromOffset(designW,designH);main.Position=U.SafePosition(screen,designW,designH,factor,compact and 10 or 14)
  main.Content.Position=UDim2.fromOffset(compact and 12 or 16,compact and 76 or 100)
  main.Content.Size=UDim2.fromOffset(designW-(compact and 24 or 32),designH-(compact and 86 or 116))
  local inv=pages.InventoryPage
  for o,layout in pairs(inventoryHeaderLayout)do o.Position=layout.Position;o.Size=layout.Size;o.AnchorPoint=layout.AnchorPoint;o.Visible=layout.Visible end
  if compact then
   inv.InventoryHeader.Position=UDim2.fromOffset(12,10);inv.InventoryHeader.Size=landscape and UDim2.fromOffset(150,42)or UDim2.new(1,-24,0,44)
   if landscape then
    inv.InventoryHeader.Title.Visible=false;local cap=inv.InventoryHeader.Capacity;cap.AnchorPoint=Vector2.zero;cap.Position=UDim2.new();cap.Size=UDim2.fromScale(1,1)
   end
   inv.Tabs.Position=UDim2.fromOffset(landscape and 174 or 12,landscape and 10 or 62);inv.Tabs.Size=UDim2.new(1,landscape and -186 or -24,0,landscape and 42 or 46)
   local bodyY=landscape and 60 or 116;local bottom=landscape and 72 or 132
   inv.Browser.Position=UDim2.fromOffset(12,bodyY);inv.Browser.Size=UDim2.new(1,-24,1,-bottom);inv.Browser.Visible=not bagDetails
   local details=inv:FindFirstChild('Details')or inv:FindFirstChild('DetailPanel')or inv:FindFirstChild('SelectedItemPanel')
   if details then details.Position=UDim2.fromOffset(12,bodyY);details.Size=UDim2.new(1,-24,1,-bottom);details.Visible=bagDetails end
   bagBack.Position=UDim2.fromOffset(landscape and 174 or 12,landscape and 10 or 63)
   inv.Tabs.Visible=not bagDetails;bagBack.Visible=bagDetails
  else for o,layout in pairs(inventoryLayout)do o.Position=layout.Position;o.Size=layout.Size;o.Visible=true end;bagBack.Visible=false end
 end
 screen:GetPropertyChangedSignal('AbsoluteSize'):Connect(resize)
 local inset=GuiService:GetPropertyChangedSignal('TopbarInset'):Connect(resize);screen.Destroying:Connect(function()inset:Disconnect()end);resize()
end
function U.BindStandalone(screen,N)
 GameIcons.Preload(U.Assets)
 local pages=screen.MainWindow.Content.PageContainer
 local yard=pages.YardPage
 yard.YardHeader.YardHeaderTitle.Size=UDim2.fromOffset(580,50)
 local offline=U.Button(yard.YardHeader,'OfflineEarnings','OFFLINE EARNINGS',631,7,255,36,function()N.OpenScreen('OfflineEarnings')end,U.Colors.gold)
 for _,page in ipairs(pages:GetChildren())do
  local chrome=page:FindFirstChild('WindowChrome');local close=chrome and chrome:FindFirstChild('WindowClose')
  if close then close.Active=true;close.Selectable=true;close.Activated:Connect(N.Close)end
 end
 screen.HUD.SimpleSettings.Open.Activated:Connect(function()N.OpenScreen('Settings')end)
end

return U

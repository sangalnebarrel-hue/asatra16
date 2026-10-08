local RS=game:GetService('ReplicatedStorage')
local Players=game:GetService('Players');local Run=game:GetService('RunService');local Input=game:GetService('UserInputService')
local C=require(RS.DogEconomy.Config);local Price=require(RS.PriceFormat);local U=require(script.Parent.UITheme)
local B={}
function B.Start(gui)
 local hud=gui:WaitForChild('HUD');if hud:FindFirstChild('ActiveSupplies')then return end
 local p=Players.LocalPlayer;local P=U.Colors
 local holder=U.Frame(hud,'ActiveSupplies',0,0,226,300);holder.BackgroundTransparency=1;holder.AnchorPoint=Vector2.new(1,1)
 local rows={};local connections={};local order={}
 local detail=U.Panel(hud,'SupplyTooltip',0,0,252,86);detail.Visible=false;detail.ZIndex=30
 local tip=U.Text(detail,'',10,6,232,74,16,P.text,true);tip.ZIndex=31
 local function row(key,name,icon,color,text,open)
  local card=U.Panel(holder,key,0,0,226,52);card.Visible=false
  U.Stroke(card,color,2);local glyph=U.Icon(card,icon,6,7,38,color)
  local title=U.Text(card,name,51,4,168,19,14,P.text,true)
  local timer=U.Text(card,'',51,24,168,23,20,P.text,true);timer.Name='Remaining'
  local hit=U.New('TextButton',{Name='Details',Text='',BackgroundTransparency=1,Size=UDim2.fromScale(1,1)},card)
  local function show()tip.Text=title.Text..'\n'..text();detail.Visible=true end
  hit.MouseEnter:Connect(show);hit.MouseLeave:Connect(function()detail.Visible=false end)
  hit.Activated:Connect(function()
   if open then require(script.Parent.GUIIntegration).OpenScreen(open);return end
   local visible=detail.Visible;show();detail.Visible=not visible;task.delay(4,function()if detail.Parent then detail.Visible=false end end)
  end)
  rows[key]={Card=card,Timer=timer,Icon=glyph,Name=title}
  table.insert(order,key)
 end
 local colors={GoldenBiscuit=P.gold,EnergySnack=P.green,StorageCrate=P.blue}
 for _,key in ipairs(C.SupplyOrder)do
  local def=C.Supplies[key]
  row(key,def.Name,key,colors[key]or P.green,function()return def.EffectText end)
 end
 row('Luck','LUCK','Luck',P.green,function()return 'Rare loot and rare finds'end,'Luck')
 row('ServerLuck','SERVER LUCK','Luck',P.purple,function()return 'Rarer dogs on the tongue for everyone'end,'Luck')
 -- What each row shows right now: expiry (0 = hidden) and its title.
 local function status(key,now)
  if key=='Luck'then
   local best,ends=0,0
   for tier in ipairs(C.LuckTiers)do local at=tonumber(p:GetAttribute('LuckExpires_'..tier))or 0;if at>now then best,ends=tier,at end end
   if best>0 then return ends,best..'x LUCK'end
   -- Donut Corgi's treats (and old Lucky Treat time) still give a little luck.
   local treat=tonumber(p:GetAttribute('SupplyExpires_LuckyTreat'))or 0
   if treat>now then return treat,'LUCKY TREAT'end
   return 0
  elseif key=='ServerLuck'then
   -- Never wait for it here: Start runs while the navigation module loads.
   local luckState=RS:FindFirstChild('ServerLuckState')
   local mult=luckState and luckState:GetAttribute('Multiplier')or 1;local ends=luckState and luckState:GetAttribute('EndsAt')or 0
   if mult>1 and ends>now then return ends,'x'..mult..' SERVER LUCK'end
   return 0
  end
  return tonumber(p:GetAttribute('SupplyExpires_'..key))or 0
 end
 local function update()
  local left,top,w,h=U.SafeArea(gui);local touch=Input.TouchEnabled;local m=U.HUD
  -- U.LayoutHUD publishes the free zone between the two menu columns; boosts never cover
  -- the right column, SETTINGS, the offline notice or the touch jump button.
  local right=m and m.BuffRight or left+w-12
  local shown={};local now=workspace:GetServerTimeNow()
  for _,key in ipairs(order)do
   local r=rows[key];local at,title=status(key,now)
   r.Card.Visible=at>now
   if at>now then
    if title then r.Name.Text=title end
    r.Timer.Text=Price.Clock(at-now);table.insert(shown,r)
   end
  end
  local index=#shown;local stackTop,stackH
  if touch then
   -- Touch: under SETTINGS (and the offline notice), growing down toward the jump button.
   local width=math.min(240,m and m.InnerRight-m.InnerLeft or w-24);local cw=(width-12)/3
   local y=m and m.BuffTop or top+8;local limit=m and m.BuffBottom or top+h-8
   local notice=hud:FindFirstChild('OfflineEarningsNotice')
   if notice and notice.Visible then y=math.max(y,notice.AbsolutePosition.Y-gui.AbsolutePosition.Y+notice.AbsoluteSize.Y+8)end
   stackH=math.ceil(index/3)*74-6;stackTop=math.max(m and m.BuffTop or top+8,math.min(y,limit-stackH))
   holder.AnchorPoint=Vector2.new(1,0);holder.Position=UDim2.fromOffset(right,stackTop);holder.Size=UDim2.fromOffset(width,math.max(1,stackH))
   for i,r in ipairs(shown)do
    local col=(i-1)%3;local line=math.floor((i-1)/3)
    r.Card.Position=UDim2.fromOffset(width-cw-col*(cw+6),line*74);r.Card.Size=UDim2.fromOffset(cw,68)
    r.Icon.Position=UDim2.fromOffset((cw-38)/2,4);r.Name.Visible=false
    r.Timer.Position=UDim2.fromOffset(2,43);r.Timer.Size=UDim2.fromOffset(cw-4,22);r.Timer.TextSize=16;r.Timer.TextXAlignment=Enum.TextXAlignment.Center
   end
  else
   -- Desktop: bottom of the free zone, left of SETTINGS, growing up.
   local bottom=m and m.BuffBottom or top+h-74
   stackH=index*58-6;stackTop=bottom-stackH
   holder.AnchorPoint=Vector2.new(1,1);holder.Position=UDim2.fromOffset(right,bottom);holder.Size=UDim2.fromOffset(226,math.max(1,stackH))
   for i,r in ipairs(shown)do
    r.Card.Position=UDim2.fromOffset(0,(index-i)*58);r.Card.Size=UDim2.fromOffset(226,52)
    r.Icon.Position=UDim2.fromOffset(6,7);r.Name.Visible=true
    r.Timer.Position=UDim2.fromOffset(51,24);r.Timer.Size=UDim2.fromOffset(168,23);r.Timer.TextSize=20;r.Timer.TextXAlignment=Enum.TextXAlignment.Left
   end
  end
  holder.Visible=index>0
  local tipY=touch and stackTop+stackH+8 or stackTop-94
  detail.Position=UDim2.fromOffset(math.max(left+8,right-252),math.clamp(tipY,top+8,math.max(top+8,top+h-94)))
  if index==0 or not hud.Visible then detail.Visible=false end
 end
 local elapsed=0;table.insert(connections,Run.Heartbeat:Connect(function(dt)elapsed+=dt;if elapsed>=.25 then elapsed=0;update()end end))
 table.insert(connections,p.CharacterAdded:Connect(update));update()
 holder.Destroying:Connect(function()for _,connection in ipairs(connections)do connection:Disconnect()end;detail:Destroy()end)
end
return B

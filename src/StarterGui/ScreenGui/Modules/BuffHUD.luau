local RS=game:GetService('ReplicatedStorage')
local Players=game:GetService('Players');local Run=game:GetService('RunService');local Input=game:GetService('UserInputService')
local C=require(RS.DogEconomy.Config);local Price=require(RS.PriceFormat);local U=require(script.Parent.UITheme)
local B={}
-- Bottom-right chips for everything boosting this player right now: the world event's
-- gameplay effect (ReplicatedStorage.WorldEvents.State Effects*), SERVER LUCK (everyone in
-- the server sees it) and each active supply. Desktop stacks rows; touch uses 3-wide tiles.
local ROW,EVENT_ROW,GAP,TILE=52,68,6,68
local function eventState()local w=RS:FindFirstChild('WorldEvents');return w and w:FindFirstChild('State')end
function B.Start(gui)
 local hud=gui:WaitForChild('HUD');if hud:FindFirstChild('ActiveSupplies')then return end
 local p=Players.LocalPlayer;local P=U.Colors
 local holder=U.Frame(hud,'ActiveSupplies',0,0,226,174);holder.BackgroundTransparency=1;holder.AnchorPoint=Vector2.new(1,1)
 local rows={};local connections={}
 local detail=U.Panel(hud,'SupplyTooltip',0,0,252,86);detail.Visible=false;detail.ZIndex=30
 local tip=U.Text(detail,'',10,6,232,74,16,P.text,true);tip.ZIndex=31
 local function openLuck()
  -- Lazy: GUIIntegration requires this module while it loads.
  local menus=require(script.Parent.Menus).Active
  if menus then menus.state.CommerceScroll=Vector2.zero end
  require(script.Parent.GUIIntegration).OpenScreen('Shop')
 end
 local function chip(key,icon)
  if rows[key]then return rows[key]end
  local card=U.Panel(holder,key,0,0,226,ROW);card.Visible=false
  local row={Card=card,Key=key,Tip=''}
  row.Stroke=U.Stroke(card,P.edge,2);row.Icon=U.Icon(card,icon,6,7,38,P.text)
  row.Name=U.Text(card,'',51,4,168,19,14,P.text,true)
  row.Timer=U.Text(card,'',51,24,168,23,20,P.text,true);row.Timer.Name='Remaining'
  row.Info=U.Text(card,'',51,24,168,40,12,P.text);row.Info.Visible=false
  local hit=U.New('TextButton',{Name='Details',Text='',BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=6},card)
  local function show()if row.Tip~=''then tip.Text=row.Tip;detail.Visible=true end end
  hit.MouseEnter:Connect(show);hit.MouseLeave:Connect(function()detail.Visible=false end)
  hit.Activated:Connect(function()
   if key=='ServerLuck'then detail.Visible=false;openLuck();return end
   local visible=detail.Visible;show();detail.Visible=not visible;task.delay(4,function()if detail.Parent then detail.Visible=false end end)
  end)
  rows[key]=row;return row
 end
 -- What to show now, top of the stack first.
 local function specs(now)
  local list={}
  local state=eventState()
  if state then
   local text=state:GetAttribute('EffectsText');local ends=tonumber(state:GetAttribute('EffectsEndsAt'))or 0
   if type(text)=='string'and text~=''and ends>now then
    local title=state:GetAttribute('EffectsTitle');title=type(title)=='string'and title~=''and title or'WORLD EVENT'
    local color=state:GetAttribute('EffectsColor')
    table.insert(list,{Key='WorldEvent',Icon='Events',Title=title,Info=text,Ends=ends,Color=typeof(color)=='Color3'and color or P.purple,Tip=title..'\n'..text})
   end
  end
  local luck=RS:FindFirstChild('DOGROTS_ServerLuck')
  if luck then
   local mult=tonumber(luck:GetAttribute('Multiplier'))or 1;local ends=tonumber(luck:GetAttribute('EndsAt'))or 0
   if mult>1 and ends>now then
    local by=luck:GetAttribute('By');by=type(by)=='string'and by~=''and(' · by '..by)or''
    table.insert(list,{Key='ServerLuck',Icon='Luck',Title='x'..mult..' SERVER LUCK',Ends=ends,Color=P.green,
     Tip='x'..mult..' SERVER LUCK'..by..'\nRarer dogs and blocks for everyone. Click for the shop.'})
   end
  end
  local colors={LuckyTreat=P.green,EnergySnack=P.gold,StorageCrate=P.blue}
  for _,key in ipairs(C.SupplyOrder)do
   local def=C.Supplies[key];local at=tonumber(p:GetAttribute('SupplyExpires_'..key))or 0
   if def and at>now then table.insert(list,{Key=key,Icon=key,Title=def.Name,Ends=at,Color=colors[key]or P.blue,Tip=def.Name..'\n'..def.EffectText})end
  end
  return list
 end
 local function update()
  local left,top,w,h=U.SafeArea(gui);local touch=Input.TouchEnabled
  -- Leave the bottom-right jump control and desktop settings button unobstructed.
  local bottom=top+h-(touch and math.min(155,h*.34)or 74)
  local width=touch and math.min(240,w-24)or 226
  local now=workspace:GetServerTimeNow();local list=specs(now);local seen={}
  local height=0
  if touch then local lines=math.ceil(#list/3);height=lines>0 and lines*TILE+(lines-1)*GAP or 0
  else for i,spec in ipairs(list)do height+=(spec.Key=='WorldEvent'and EVENT_ROW or ROW)+(i>1 and GAP or 0)end end
  holder.Position=UDim2.fromOffset(left+w-12,bottom);holder.Size=UDim2.fromOffset(width,math.max(1,height))
  -- Desktop: the first chip sits on top. Touch: tiles fill from the bottom-right.
  local y=0
  for i,spec in ipairs(list)do
   local row=chip(spec.Key,spec.Icon);seen[spec.Key]=true;row.Tip=spec.Tip
   local card=row.Card;card.Visible=true
   if row.Color~=spec.Color then row.Color=spec.Color;row.Stroke.Color=spec.Color end
   row.Name.Text=spec.Title;row.Info.Text=spec.Info or''
   local event=spec.Key=='WorldEvent'
   if touch then
    local cw=(width-12)/3;local index=i-1;local line=math.floor(index/3);local column=index%3
    card.Position=UDim2.fromOffset(width-cw-column*(cw+6),height-TILE-line*(TILE+GAP));card.Size=UDim2.fromOffset(cw,TILE)
    row.Icon.Position=UDim2.fromOffset((cw-38)/2,4);row.Name.Visible=false;row.Info.Visible=false
    row.Timer.Position=UDim2.fromOffset(2,43);row.Timer.Size=UDim2.fromOffset(cw-4,22);row.Timer.TextSize=16;row.Timer.TextXAlignment=Enum.TextXAlignment.Center
   else
    local rowH=event and EVENT_ROW or ROW
    card.Position=UDim2.fromOffset(0,y);card.Size=UDim2.fromOffset(width,rowH);y+=rowH+GAP
    row.Icon.Position=UDim2.fromOffset(6,7);row.Name.Visible=true;row.Info.Visible=event
    if event then
     row.Name.Size=UDim2.fromOffset(width-51-64,19)
     row.Timer.Position=UDim2.fromOffset(width-64,4);row.Timer.Size=UDim2.fromOffset(58,19);row.Timer.TextSize=14;row.Timer.TextXAlignment=Enum.TextXAlignment.Right
     row.Info.Position=UDim2.fromOffset(51,24);row.Info.Size=UDim2.fromOffset(width-57,40)
    else
     row.Name.Size=UDim2.fromOffset(width-58,19)
     row.Timer.Position=UDim2.fromOffset(51,24);row.Timer.Size=UDim2.fromOffset(width-58,23);row.Timer.TextSize=20;row.Timer.TextXAlignment=Enum.TextXAlignment.Left
    end
   end
   row.Timer.Text=Price.Clock(spec.Ends-now)
  end
  for key,row in pairs(rows)do if not seen[key]then row.Card.Visible=false end end
  holder.Visible=#list>0
  detail.Position=UDim2.fromOffset(math.max(left+8,left+w-268),math.max(top+8,bottom-height-94))
  if #list==0 or not hud.Visible then detail.Visible=false end
 end
 local elapsed=0;table.insert(connections,Run.Heartbeat:Connect(function(dt)elapsed+=dt;if elapsed>=.25 then elapsed=0;update()end end))
 for _,key in ipairs(C.SupplyOrder)do table.insert(connections,p:GetAttributeChangedSignal('SupplyExpires_'..key):Connect(update))end
 table.insert(connections,p.CharacterAdded:Connect(update));update()
 holder.Destroying:Connect(function()for _,connection in ipairs(connections)do connection:Disconnect()end;detail:Destroy()end)
end
return B

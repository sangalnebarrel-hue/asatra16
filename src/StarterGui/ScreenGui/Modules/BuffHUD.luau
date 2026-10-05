local RS=game:GetService('ReplicatedStorage')
local Players=game:GetService('Players');local Run=game:GetService('RunService');local Input=game:GetService('UserInputService')
local C=require(RS.DogEconomy.Config);local Price=require(RS.PriceFormat);local U=require(script.Parent.UITheme)
local B={}
function B.Start(gui)
 local hud=gui:WaitForChild('HUD');if hud:FindFirstChild('ActiveSupplies')then return end
 local p=Players.LocalPlayer;local P=U.Colors
 local holder=U.Frame(hud,'ActiveSupplies',0,0,226,174);holder.BackgroundTransparency=1;holder.AnchorPoint=Vector2.new(1,1)
 local rows={};local connections={};local icons={LuckyTreat='LuckyTreat',EnergySnack='EnergySnack',StorageCrate='StorageCrate'}
 local colors={LuckyTreat=P.green,EnergySnack=P.gold,StorageCrate=P.blue}
 local detail=U.Panel(hud,'SupplyTooltip',0,0,252,86);detail.Visible=false;detail.ZIndex=30
 local tip=U.Text(detail,'',10,6,232,74,16,P.text,true);tip.ZIndex=31
 for _,key in ipairs(C.SupplyOrder)do
  local def=C.Supplies[key];local card=U.Panel(holder,key,0,0,226,52);card.Visible=false
  U.Stroke(card,colors[key],2);local icon=U.Icon(card,icons[key],6,7,38,colors[key])
  local name=U.Text(card,def.Name,51,4,168,19,14,P.text,true)
  local timer=U.Text(card,'',51,24,168,23,20,P.text,true);timer.Name='Remaining'
  local hit=U.New('TextButton',{Name='Details',Text='',BackgroundTransparency=1,Size=UDim2.fromScale(1,1)},card)
  local function show()tip.Text=def.Name..'\n'..def.EffectText;detail.Visible=true end
  hit.MouseEnter:Connect(show);hit.MouseLeave:Connect(function()detail.Visible=false end)
  hit.Activated:Connect(function()local visible=detail.Visible;show();detail.Visible=not visible;task.delay(4,function()if detail.Parent then detail.Visible=false end end)end)
  rows[key]={Card=card,Timer=timer,Icon=icon,Name=name}
 end
 local function update()
  local left,top,w,h=U.SafeArea(gui);local touch=Input.TouchEnabled
  -- Leave the bottom-right jump control and desktop settings button unobstructed.
  local bottom=top+h-(touch and math.min(155,h*.34)or 74)
  local width=touch and math.min(240,w-24)or 226
  holder.Position=UDim2.fromOffset(left+w-12,bottom);holder.Size=UDim2.fromOffset(width,174)
  local index=0;local now=workspace:GetServerTimeNow()
  for _,key in ipairs(C.SupplyOrder)do
   local row=rows[key];local at=tonumber(p:GetAttribute('SupplyExpires_'..key))or 0
   row.Card.Visible=at>now
   if at>now then
    if touch then
     local cw=(width-12)/3
     row.Card.Position=UDim2.fromOffset(width-cw-index*(cw+6),106);row.Card.Size=UDim2.fromOffset(cw,68)
     row.Icon.Position=UDim2.fromOffset((cw-38)/2,4);row.Name.Visible=false
     row.Timer.Position=UDim2.fromOffset(2,43);row.Timer.Size=UDim2.fromOffset(cw-4,22);row.Timer.TextSize=16;row.Timer.TextXAlignment=Enum.TextXAlignment.Center
    else
     row.Card.Position=UDim2.fromOffset(0,174-52-index*58);row.Card.Size=UDim2.fromOffset(width,52)
     row.Icon.Position=UDim2.fromOffset(6,7);row.Name.Visible=true
     row.Timer.Position=UDim2.fromOffset(51,24);row.Timer.Size=UDim2.fromOffset(168,23);row.Timer.TextSize=20;row.Timer.TextXAlignment=Enum.TextXAlignment.Left
    end
    row.Timer.Text=Price.Clock(at-now);index+=1
   end
  end
  holder.Visible=index>0
  detail.Position=UDim2.fromOffset(math.max(left+8,left+w-268),math.max(top+8,bottom-(touch and 68 or index*58)-94))
  if index==0 or not hud.Visible then detail.Visible=false end
 end
 local elapsed=0;table.insert(connections,Run.Heartbeat:Connect(function(dt)elapsed+=dt;if elapsed>=.25 then elapsed=0;update()end end))
 for _,key in ipairs(C.SupplyOrder)do table.insert(connections,p:GetAttributeChangedSignal('SupplyExpires_'..key):Connect(update))end
 table.insert(connections,p.CharacterAdded:Connect(update));update()
 holder.Destroying:Connect(function()for _,connection in ipairs(connections)do connection:Disconnect()end;detail:Destroy()end)
end
return B

-- Small native component helper. Styles are read from the CURRENT Yard objects.
local U={}
function U.Build(gui,root)
 local yard=gui.MainWindow.Content.PageContainer.YardPage
 local latest=yard.LatestFoundCard.Main
 local function cleanClone(source,parent,name)
  local x=source:Clone();x.Name=name
  for _,c in ipairs(x:GetChildren()) do
   if not (c:IsA('UICorner') or c:IsA('UIStroke') or c:IsA('UIGradient')) then c:Destroy() end
  end
  x.Parent=parent
  return x
 end
 local function frame(parent,name,pos,size)
  local f=Instance.new('Frame');f.Name=name;f.BackgroundTransparency=1;f.BorderSizePixel=0;f.Position=pos;f.Size=size;f.Parent=parent
  return f
 end
 local function label(parent,name,value,pos,size,max,muted)
  local t=cleanClone(muted and latest.ItemInfo or latest.ItemName,parent,name)
  t.Text=value;t.Position=pos;t.Size=size;t.ZIndex=4;t.TextScaled=true;t.TextWrapped=true
  t.TextXAlignment=Enum.TextXAlignment.Left;t.TextYAlignment=Enum.TextYAlignment.Center
  local limit=Instance.new('UITextSizeConstraint');limit.MinTextSize=14;limit.MaxTextSize=max or 24;limit.Parent=t
  return t
 end
 local function card(parent,name,pos,size)
  local holder=frame(parent,name,pos,size)
  local shadow=cleanClone(yard.LatestFoundCard.Shadow,holder,'Shadow');shadow.Size=UDim2.fromScale(1,1);shadow.ZIndex=1
  local face=cleanClone(latest,holder,'Main');face.Position=UDim2.fromScale(0,0);face.Size=UDim2.fromScale(1,1);face.ZIndex=2
  return holder,face
 end
 local function button(parent,name,words,pos,size,style)
  local source=yard.ActionButtons[style or 'Upgrades']
  local holder=frame(parent,name,pos,size);holder.ZIndex=5
  local shadow=cleanClone(source.Shadow,holder,'Shadow');shadow.Size=UDim2.fromScale(1,1);shadow.ZIndex=1
  -- Keep the actual Yard gradient on a separate surface so it does not tint text.
  local surface=Instance.new('Frame');surface.Name='Surface';surface.BorderSizePixel=0;surface.BackgroundColor3=source.Main.BackgroundColor3
  surface.Size=UDim2.fromScale(1,1);surface.ZIndex=2;surface.Parent=holder
  source.Main.UICorner:Clone().Parent=surface;source.Main.UIGradient:Clone().Parent=surface
  local b=cleanClone(source.Main,holder,'Button');b.BackgroundTransparency=1;b.Position=UDim2.fromScale(0,0);b.Size=UDim2.fromScale(1,1);b.ZIndex=3
  local g=b:FindFirstChildWhichIsA('UIGradient');if g then g:Destroy() end
  b.Text=words;b.TextScaled=true;b.AutoButtonColor=false
  local limit=Instance.new('UITextSizeConstraint');limit.MinTextSize=14;limit.MaxTextSize=24;limit.Parent=b
  local padding=Instance.new('UIPadding');padding.PaddingLeft=UDim.new(0,8);padding.PaddingRight=UDim.new(0,8);padding.PaddingTop=UDim.new(0,3);padding.PaddingBottom=UDim.new(0,3);padding.Parent=b
  return b,holder
 end
 local function scroll(parent,name,pos,size)
  local s=Instance.new('ScrollingFrame');s.Name=name;s.Position=pos;s.Size=size;s.BorderSizePixel=0;s.BackgroundTransparency=1;s.Active=true
  s.ScrollingDirection=Enum.ScrollingDirection.Y;s.AutomaticCanvasSize=Enum.AutomaticSize.Y;s.CanvasSize=UDim2.new();s.ScrollBarThickness=6;s.ScrollBarImageColor3=latest.ClassLabel.TextColor3;s.Parent=parent
  local pad=Instance.new('UIPadding');pad.PaddingTop=UDim.new(0,5);pad.PaddingLeft=UDim.new(0,5);pad.PaddingRight=UDim.new(0,14);pad.PaddingBottom=UDim.new(0,10);pad.Parent=s
  return s
 end
 local function viewport(parent,name,pos,size)
  local v=Instance.new('ViewportFrame');v.Name=name;v.Position=pos;v.Size=size;v.BackgroundColor3=latest.PreviewArea.BackgroundColor3;v.BorderSizePixel=0;v.ZIndex=3
  v.Ambient=yard.YardPreviewPanel.YardViewport.Ambient;v.LightColor=yard.YardPreviewPanel.YardViewport.LightColor;v.Parent=parent
  latest.PreviewArea.UICorner:Clone().Parent=v
  return v
 end
 U.label=label;U.card=card;U.button=button;U.scroll=scroll;U.viewport=viewport
 U.accent=latest.ClassLabel.TextColor3;U.muted=latest.ItemInfo.TextColor3
 root.BackgroundColor3=Color3.fromRGB(255,251,242);root.BackgroundTransparency=0;root.BorderSizePixel=0;root.AnchorPoint=Vector2.new(.5,0);root.ZIndex=20
 for _,c in ipairs(gui.MainWindow:GetChildren()) do if c:IsA('UICorner') or c:IsA('UIStroke') then c:Clone().Parent=root end end
 local border=root:FindFirstChildWhichIsA('UIStroke');if border then border.Enabled=true;border.Thickness=3 end
 local header=cleanClone(yard.YardHeader,root,'Header');header.Position=UDim2.fromScale(.015,.02);header.Size=UDim2.fromScale(.97,.12)
 local title=yard.YardHeader.YardHeaderTitle:Clone();title.Name='Title';title.Position=UDim2.fromScale(.025,.05);title.Size=UDim2.fromScale(.57,.90);title.Parent=header
 local money=label(header,'Money','',UDim2.fromScale(.63,.12),UDim2.fromScale(.26,.76),30)
 local close=gui.MainWindow.Header.CloseButton:Clone();close.Name='Close';close.Visible=true;close.AnchorPoint=Vector2.zero;close.Position=UDim2.fromScale(.91,.1);close.Size=UDim2.fromScale(.075,.8);close.Parent=header
 local body=cleanClone(gui.MainWindow.Content,root,'Body');body.Position=UDim2.fromScale(.015,.16);body.Size=UDim2.fromScale(.97,.775)
 -- All panels are created once and shared open/close only changes visibility.
 local result={Root=root,Title=title,Money=money,Close=close,Panels={},Cards={}}
 for _,name in ipairs({'Upgrades','Layers','Seller','Kennels'}) do
  local panel=root:FindFirstChild(name) or frame(root,name,UDim2.new(),UDim2.fromScale(1,1))
  panel:SetAttribute('ServicePanel',true);panel.Position=body.Position;panel.Size=body.Size;panel.BackgroundTransparency=1;panel.ZIndex=3;panel.Visible=false
  result.Panels[name]=panel
 end
 result.Status=label(root,'Status','',UDim2.fromScale(.035,.95),UDim2.fromScale(.93,.035),18,true)
 result.Status.TextColor3=latest.BorderStroke.Color;result.Status.TextStrokeTransparency=1
 local ug=scroll(result.Panels.Upgrades,'UpgradeGrid',UDim2.fromScale(.012,.015),UDim2.fromScale(.976,.97))
 local grid=Instance.new('UIGridLayout');grid.Name='Layout';grid.SortOrder=Enum.SortOrder.LayoutOrder;grid.CellPadding=UDim2.fromOffset(16,18);grid.Parent=ug
 result.UpgradeGrid=ug
 local layers=scroll(result.Panels.Layers,'LayerList',UDim2.fromScale(.012,.015),UDim2.fromScale(.976,.97))
 local list=Instance.new('UIListLayout');list.Padding=UDim.new(0,16);list.SortOrder=Enum.SortOrder.LayoutOrder;list.Parent=layers
 result.LayerList=layers
 for _,name in ipairs({'Seller','Kennels'}) do
  local panel=result.Panels[name]
  local content=scroll(panel,'ResponsiveScroll',UDim2.new(),UDim2.fromScale(1,1))
  local p=frame(content,'ResponsiveBody',UDim2.new(),UDim2.fromScale(1,1))
  local heading=label(p,'Context','',UDim2.fromScale(.025,.02),UDim2.fromScale(.95,.065),25)
  local lh,l=card(p,'Owned',UDim2.fromScale(.02,.115),UDim2.fromScale(.61,.85))
  local g=scroll(l,'Grid',UDim2.fromScale(.015,.015),UDim2.fromScale(.97,.965))
  local lay=Instance.new('UIGridLayout');lay.Name='Layout';lay.CellPadding=UDim2.fromOffset(14,16);lay.SortOrder=Enum.SortOrder.LayoutOrder;lay.Parent=g
  local empty=label(l,'Empty','Loading...',UDim2.fromScale(.06,.32),UDim2.fromScale(.88,.3),26,true);empty.TextXAlignment=Enum.TextXAlignment.Center
  local dh,d=card(p,'Details',UDim2.fromScale(.65,.115),UDim2.fromScale(.33,.85))
  label(d,'Heading',name=='Seller' and 'SELECTED FIND' or 'SELECTED DOG',UDim2.fromScale(.055,.025),UDim2.fromScale(.89,.065),23).TextColor3=U.accent
  local t=label(d,'Name','SELECT A CARD',UDim2.fromScale(.055,.10),UDim2.fromScale(.89,.1),30)
  local vp=viewport(d,'Preview',UDim2.fromScale(.055,.23),UDim2.fromScale(.89,.27))
  local fallback=label(vp,'Empty','?',UDim2.fromScale(.1,.1),UDim2.fromScale(.8,.8),48,true);fallback.TextXAlignment=Enum.TextXAlignment.Center
  local facts=scroll(d,'Facts',UDim2.fromScale(.055,.525),UDim2.fromScale(.89,.235))
  local fact=label(facts,'Text','Choose a card.',UDim2.new(),UDim2.new(1,-14,0,0),19,true)
  fact.AutomaticSize=Enum.AutomaticSize.Y;fact.TextScaled=false;fact.TextSize=19;fact.TextYAlignment=Enum.TextYAlignment.Top
  local action=button(d,'Action','',UDim2.fromScale(.055,.82),UDim2.fromScale(.89,.12))
  result[name]={Grid=g,Empty=empty,Context=heading,Name=t,Preview=vp,Facts=fact,Action=action,Details=d,OwnedHolder=lh,DetailHolder=dh,Content=p,Scroll=content}
  local back,backHolder=button(p,'BackToCards','BACK TO CARDS',UDim2.new(),UDim2.fromOffset(170,42),'DiggingLayers')
  backHolder.Visible=false;result[name].BackHolder=backHolder
  back.Activated:Connect(function()content.CanvasPosition=Vector2.zero end)
  if name=='Seller'then
   heading.Size=UDim2.fromScale(.53,.065)
   result.Seller.Total=label(d,'SelectedTotal','TOTAL: 0 CASH',UDim2.fromScale(.055,.765),UDim2.fromScale(.89,.045),19)
   result.Seller.Total.TextColor3=U.accent
   result.Seller.Total.TextXAlignment=Enum.TextXAlignment.Center
   result.Seller.SelectAll=button(p,'SelectAll','SELECT ALL',UDim2.fromScale(.57,.017),UDim2.fromScale(.25,.075),'DiggingLayers')
   result.Seller.Clear=button(p,'ClearSelection','CLEAR',UDim2.fromScale(.835,.017),UDim2.fromScale(.145,.075),'DiggingLayers')
  end
 end
 function result.FocusDetails(name)
  local entry=result[name]
  if entry and result.Compact then entry.Scroll.CanvasPosition=Vector2.new(0,entry.DetailStart or 420)end
 end
 function result.Layout()
  local Theme=require(gui.Modules.UITheme)
  local left,top,width,height=Theme.SafeArea(gui)
  local rw=math.min(1180,width-24);local rh=math.max(160,height-24)
  root.AnchorPoint=Vector2.new(.5,.5);root.Position=UDim2.fromOffset(left+width/2,top+height/2);root.Size=UDim2.fromOffset(rw,rh)
  local compact=rw<700 or rh<500;result.Compact=compact
  local headerH=rw<620 and 94 or 72
  header.Position=UDim2.fromOffset(10,8);header.Size=UDim2.new(1,-20,0,headerH)
  title.Position=UDim2.fromOffset(14,4);title.Size=rw<620 and UDim2.new(1,-78,0,36)or UDim2.new(.55,-20,1,-8)
  title.TextScaled=true;title.TextWrapped=true
  local titleLimit=title:FindFirstChildWhichIsA('UITextSizeConstraint')or Instance.new('UITextSizeConstraint',title)
  titleLimit.MinTextSize=18;titleLimit.MaxTextSize=rw<620 and 25 or 30
  money.Position=rw<620 and UDim2.fromOffset(14,44)or UDim2.new(.56,0,0,8)
  money.Size=rw<620 and UDim2.new(1,-30,0,42)or UDim2.new(.33,-20,0,54)
  close.Position=UDim2.new(1,-55,0,7);close.Size=UDim2.fromOffset(44,44)
  body.Position=UDim2.fromOffset(10,headerH+18);body.Size=UDim2.new(1,-20,1,-headerH-57)
  for _,panel in pairs(result.Panels)do panel.Position=body.Position;panel.Size=body.Size end
  result.Status.Position=UDim2.new(0,18,1,-30);result.Status.Size=UDim2.new(1,-36,0,24)
  local function arrange(g,maxColumns,minWidth,cardHeight)
   local available=math.max(1,g.AbsoluteSize.X-28)
   local columns=math.clamp(math.floor((available+16)/(minWidth+16)),1,maxColumns)
   local cellWidth=math.floor((available-(columns-1)*16)/columns)
   g.Layout.CellSize=UDim2.fromOffset(cellWidth,cardHeight or math.max(240,math.min(278,cellWidth*1.12)))
  end
  arrange(ug,3,280,310)
  for _,name in ipairs({'Seller','Kennels'})do
   local d=result[name];local contentW=math.max(1,rw-52)
   d.Content.Size=compact and UDim2.new(1,-8,0,970)or UDim2.new(1,-8,1,-16)
   d.Context.Position=UDim2.fromOffset(8,2);d.Context.Size=UDim2.new(1,-16,0,38)
   d.OwnedHolder.Position=compact and UDim2.fromOffset(5,name=='Seller'and 92 or 49)or UDim2.new(.02,0,0,52)
   d.OwnedHolder.Size=compact and UDim2.new(1,-20,0,310)or UDim2.new(.61,0,1,-66)
   local detailStart=name=='Seller'and 416 or 374;d.DetailStart=detailStart
   d.BackHolder.Visible=compact;d.BackHolder.Position=UDim2.fromOffset(8,detailStart);d.BackHolder.Size=UDim2.fromOffset(180,42)
   d.DetailHolder.Position=compact and UDim2.fromOffset(5,detailStart+54)or UDim2.new(.65,0,0,52)
   d.DetailHolder.Size=compact and UDim2.new(1,-20,0,490)or UDim2.new(.33,0,1,-66)
   d.Facts.TextSize=18
   if name=='Seller'then
    d.SelectAll.Parent.Position=compact and UDim2.fromOffset(8,45)or UDim2.new(.58,0,0,1)
    d.SelectAll.Parent.Size=compact and UDim2.new(.62,-12,0,40)or UDim2.new(.24,0,0,40)
    d.Clear.Parent.Position=compact and UDim2.new(.64,0,0,45)or UDim2.new(.84,0,0,1)
    d.Clear.Parent.Size=compact and UDim2.new(.36,-20,0,40)or UDim2.new(.14,0,0,40)
    if not compact then d.Context.Size=UDim2.new(.56,-12,0,38)end
   end
   arrange(d.Grid,4,190,260)
  end
  for _,card in ipairs(layers:GetChildren())do if card:IsA('Frame')then card.Size=UDim2.new(1,-22,0,132)end end
 end
 root:GetPropertyChangedSignal('AbsoluteSize'):Connect(result.Layout)
 gui:GetPropertyChangedSignal('AbsoluteSize'):Connect(result.Layout)
 result.Layout();task.defer(result.Layout)
 return result
end
return U

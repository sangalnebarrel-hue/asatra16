local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Http=game:GetService('HttpService')
local UIS=game:GetService('UserInputService')
local player=Players.LocalPlayer
local playerGui=player:WaitForChild('PlayerGui')
local main=playerGui:FindFirstChild('ScreenGui')
while not main do
 local child=playerGui.ChildAdded:Wait()
 if child.Name=='ScreenGui' then main=child end
end
local N=require(main:WaitForChild('Modules'):WaitForChild('GUIIntegration'))
local U=require(main.Modules.UITheme);local V=require(main.Modules.PreviewRenderer)
local palette={Navy=U.Colors.purple,Cream=U.Colors.text,Gold=U.Colors.purple,Teal=U.Colors.green,Muted=U.Colors.muted}
local mode,busy,epoch,draft,token,inboxDay=nil,false,0,'',nil,0
local W,H=740,570;local redrawShelter;local selectedUid;local shelterRows={};local shelterQuote
local gui=Instance.new('ScreenGui');gui.Name='CommunityServices';gui.ResetOnSpawn=false;gui.DisplayOrder=70;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;gui.Enabled=false;gui.Parent=player.PlayerGui
local function new(class,props,parent)
 local o=Instance.new(class);for k,v in pairs(props)do o[k]=v end;o.Parent=parent;return o
end
local root=new('Frame',{Name='Window',AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(740,570),BackgroundColor3=Color3.fromRGB(255,251,242),BorderSizePixel=0},gui)
new('UICorner',{CornerRadius=UDim.new(0,14)},root);new('UIStroke',{Color=U.Colors.edge,Thickness=3},root)
local scale=new('UIScale',{},root)
local function resize()
 local s=gui.AbsoluteSize;local mobile=s.X<700
 local _,_,width,height=U.SafeArea(gui)
 W=mode=='Shelter'and(mobile and 520 or 960)or 740
 local factor=math.max(.2,math.min(1,(width-28)/W,(height-28)/(mode=='Shelter'and 620 or 570)))
 H=mode=='Shelter'and(mobile and math.clamp((height-28)/factor,620,1080)or 700)or 570
 if H*factor>height-28 then factor=(height-28)/H end
 scale.Scale=factor;root.Size=UDim2.fromOffset(W,H);root.Position=U.SafePosition(gui,W,H,factor,14)
end
local function text(parent,value,x,y,w,h,size,color)return U.Text(parent,value,x,y,w,h,size,color or palette.Cream)end
local function button(parent,value,x,y,w,h,callback,color)
 local close=value=='×'
 local b=U.Button(parent,'Action',value,x,y,w,h,callback and function()if not busy or close then callback()end end or nil,color or palette.Teal)
 b:SetAttribute('RequestAction',not close);b:SetAttribute('IntrinsicEnabled',callback~=nil)
 U.SetButtonEnabled(b,callback~=nil and(not busy or close));return b
end
local title=text(root,'DOG SHELTER',24,16,610,38,26,palette.Gold)
local description=text(root,'',24,61,685,49,16,palette.Muted)
local content=new('Frame',{Position=UDim2.fromOffset(24,119),Size=UDim2.fromOffset(692,381),BackgroundTransparency=1},root)
local status=text(root,'',24,511,692,43,15,palette.Gold)
local function close()
 epoch+=1;gui.Enabled=false;mode=nil;busy=false
 if N.Owner=='Community'then N.Close()end
end
local closeButton=button(root,'×',676,17,40,38,close,U.Colors.red)
UIS.InputBegan:Connect(function(input,processed)if not processed and input.KeyCode==Enum.KeyCode.Escape and gui.Enabled then close()end end)
main:GetAttributeChangedSignal('OpenMenu'):Connect(function()if gui.Enabled and N.Owner~='Community'then gui.Enabled=false;epoch+=1;mode=nil;busy=false end end)
local function layout()
 resize();title.Size=UDim2.fromOffset(W-115,42);description.Size=UDim2.fromOffset(W-48,49)
 closeButton.Position=UDim2.fromOffset(W-65,17)
 content.Size=UDim2.fromOffset(W-48,H-189);status.Position=UDim2.fromOffset(24,H-59);status.Size=UDim2.fromOffset(W-48,43)
end
local function controls()
 for _,b in ipairs(root:GetDescendants())do if b:IsA('GuiButton')and b:GetAttribute('RequestAction')then U.SetButtonEnabled(b,not busy and b:GetAttribute('IntrinsicEnabled')==true)end end
end
gui:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()layout();if mode=='Shelter'and redrawShelter then redrawShelter()end end)
layout()
local function clear()for _,c in content:GetChildren()do c:Destroy()end end
local function request(remote,action,args,callback)
 if busy then return end
 busy=true;controls();status.Text='Please wait...';local id=epoch
 task.spawn(function()
  local transport,ok,data=pcall(function()return remote:InvokeServer(action,args)end)
  if epoch~=id or not gui.Enabled then return end
  busy=false;controls()
  if not transport or not ok then status.Text=transport and tostring(data)or 'Connection interrupted. Please try again.';return end
  status.Text='';callback(data)
 end)
end
local showShelter
local function findSelected()
 for _,row in ipairs(shelterRows)do if row.Uid==selectedUid then return row end end
 return nil
end
local function quote(row)
 request(RS.ShelterRequest,'Quote',{Uid=row.Uid},function(q)
  if selectedUid~=q.Uid then return end
  shelterQuote=q;redrawShelter()
 end)
end
redrawShelter=function()
 clear();layout()
 description.Text='Choose an extra dog. Review its price, then confirm a new home.'
 local width,height=W-48,H-189;local mobile=W<700
 local row=findSelected();if row then selectedUid=row.Uid end
 local detailW=mobile and width or math.floor(width*.44)
 local listW=mobile and width or width-detailW-16
 local detailH=mobile and 425 or height
 local listY=mobile and detailH+16 or 0
 local listH=mobile and math.max(150,height-listY)or height
 local outer=U.Scroll(content,'ShelterContent',0,0,width,height)
 local list=U.Panel(outer,'YourDogs',0,listY,listW,listH)
 U.Text(list,'YOUR DOGS · '..#shelterRows,12,8,listW-24,31,22,U.Colors.text,true)
 local grid=U.Scroll(list,'DogList',8,48,listW-16,listH-58)
 if #shelterRows==0 then U.Center(grid,'No dogs to rehome yet.\nAdopt your first dog at DOG LINE.',12,45,listW-48,125,23,U.Colors.muted)end
 for i,dog in ipairs(shelterRows)do
  local card=U.Panel(grid,'Dog_'..dog.Uid,5,(i-1)*119,listW-38,108)
  if dog.Uid==selectedUid then U.Glow(card,U.Colors.gold)end
  V.Dog(card,{DogId=dog.DogId,Variant=dog.Variant},4,5,91,97)
  U.Text(card,dog.Name,101,5,listW-151,34,20,U.Colors.text,true)
  U.Text(card,dog.Rarity..' · '..dog.Variant,103,39,listW-156,26,15,U.Colors.muted)
  local choose=button(card,dog.Uid==selectedUid and'SELECTED'or'SELECT',101,73,listW-152,28,function()selectedUid=dog.Uid;shelterQuote=nil;redrawShelter()end,dog.Uid==selectedUid and U.Colors.gold or U.Colors.blue)
  choose.Name='SelectDog'
 end
 local detail=U.Panel(outer,'SelectedDog',mobile and 0 or listW+16,0,detailW,detailH)
 if not row then U.Center(detail,'CHOOSE A DOG',12,100,detailW-24,70,25,U.Colors.muted,true);return end
 local q=shelterQuote and shelterQuote.Uid==row.Uid and shelterQuote or nil
 U.Center(detail,q and'CONFIRM A NEW HOME'or'SELECTED DOG',12,9,detailW-24,30,22,U.Colors.purple,true)
 V.Dog(detail,{DogId=q and q.DogId or row.DogId,Variant=row.Variant},20,48,detailW-40,155)
 U.Center(detail,row.Name,12,204,detailW-24,34,25,U.Colors.text,true)
 U.Center(detail,row.Rarity..' · '..row.Variant..' · Mastery '..tostring(row.Mastery or 0),12,242,detailW-24,28,16,U.Colors.muted)
 U.Center(detail,'YOU RECEIVE '..U.Fmt(q and q.Price or row.Price)..' COINS',12,276,detailW-24,33,23,U.Colors.green,true)
 local info=q and'This dog leaves your inventory. Your Dog Index discovery stays unlocked.'or row.Eligible and'25% of this dog’s current catalog value, including bonuses.'or row.Reason or'This dog is protected.'
 U.Center(detail,info,15,311,detailW-30,58,16,U.Colors.muted)
 if q then
  local expired=os.time()>q.Expires
  local confirm=button(detail,expired and'QUOTE EXPIRED'or'CONFIRM SALE',12,376,(detailW-34)*.61,41,not expired and function()
   request(RS.ShelterRequest,'Sell',{Token=q.Token},function(result)shelterQuote=nil;selectedUid=nil;showShelter(result.Message)end)
  end or nil,U.Colors.green);confirm.Name='ConfirmSale';confirm:SetAttribute('QuoteExpires',q.Expires)
  button(detail,'CANCEL',22+(detailW-34)*.61,376,(detailW-34)*.39,41,function()shelterQuote=nil;redrawShelter()end,U.Colors.red).Name='CancelSale'
 else
  button(detail,row.Eligible and'REVIEW SALE'or'PROTECTED',12,376,detailW-24,41,row.Eligible and function()quote(row)end or nil,row.Eligible and U.Colors.green or U.Colors.purple).Name='ReviewSale'
 end
end
showShelter=function(message)
 shelterQuote=nil;description.Text='Loading your dogs…'
 request(RS.ShelterRequest,'List',{},function(data)
  shelterRows=data.Rows or{};redrawShelter();status.Text=message or'Working, locked, displayed and listed dogs stay protected.'
 end)
end
local showFeedback,showInbox
showInbox=function()
 request(RS.CommunityFeedbackRequest,'Read',{Day=inboxDay},function(data)
  clear();description.Text='DEVELOPER INBOX · '..data.Date..(data.Preview and ' · LOCAL TEST'or ' · Saved player messages')
  button(content,'WRITE A MESSAGE',0,0,240,38,function()showFeedback()end)
  button(content,'PREVIOUS DAY',270,0,195,38,function()inboxDay=math.min(6,inboxDay+1);showInbox()end)
  button(content,'NEXT DAY',480,0,212,38,function()inboxDay=math.max(0,inboxDay-1);showInbox()end)
  local sc=new('ScrollingFrame',{Position=UDim2.fromOffset(0,52),Size=UDim2.fromOffset(692,329),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=6,CanvasSize=UDim2.fromOffset(0,#data.Rows*180)},content)
  if #data.Rows==0 then text(sc,'No messages for this day.',12,35,650,60,21)end
  for i,row in ipairs(data.Rows)do
   local card=new('Frame',{Position=UDim2.fromOffset(0,(i-1)*180),Size=UDim2.fromOffset(676,168),BackgroundColor3=U.Colors.light,BorderSizePixel=0},sc)
   text(card,'User '..row.UserId..' · '..os.date('!%H:%M UTC',row.At),12,8,650,24,14,palette.Gold)
   local body=text(card,row.Text,12,38,650,118,16);body.TextYAlignment=Enum.TextYAlignment.Top
  end
 end)
end
showFeedback=function(access)
 clear();description.Text='Share an idea, wish or problem with the developers. 10–500 characters. One message per minute.'
 local box=new('TextBox',{Name='MessageDraft',Position=UDim2.fromOffset(0,0),Size=UDim2.fromOffset(692,242),BackgroundColor3=U.Colors.light,BorderSizePixel=0,Text=draft,PlaceholderText='What would you like to see in DOGROTS?',PlaceholderColor3=palette.Muted,TextColor3=palette.Cream,TextSize=20,TextWrapped=true,MultiLine=true,ClearTextOnFocus=false,Font=Enum.Font.FredokaOne,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top},content)
 new('UIPadding',{PaddingTop=UDim.new(0,14),PaddingBottom=UDim.new(0,14),PaddingLeft=UDim.new(0,14),PaddingRight=UDim.new(0,14)},box);new('UICorner',{CornerRadius=UDim.new(0,9)},box)
 local count=text(content,'',0,248,692,30,15,palette.Muted)
 local function updateDraft()
  if #box.Text>2000 then box.Text=box.Text:sub(1,2000)end
  if box.Text~=draft then token=nil end;draft=box.Text
  local n=utf8.len(draft)or 0;count.Text=n..' / 500 characters';count.TextColor3=n>500 and Color3.fromRGB(255,133,116)or palette.Muted
 end
 box:GetPropertyChangedSignal('Text'):Connect(updateDraft);updateDraft()
 button(content,'SEND TO DEVELOPERS',0,295,430,52,function()
  local n=utf8.len(draft)or 0
  if n<10 or n>500 then status.Text='Write 10–500 characters before sending.';return end
  token=token or Http:GenerateGUID(false):gsub('-','');local submitted=draft
  request(RS.CommunityFeedbackRequest,'Send',{Text=draft,Token=token},function(result)
   if draft==submitted then draft='';token=nil;box.Text=''end;status.Text=result.Message
  end)
 end)
 local function developerButton(info)
  if info.Developer then button(content,'DEVELOPER INBOX',444,295,248,52,function()showInbox()end,palette.Navy)end
  if info.Preview then status.Text='Studio preview: messages exist only for this test session.'end
 end
 if access then developerButton(access)else request(RS.CommunityFeedbackRequest,'Access',{},developerButton)end
end
RS:WaitForChild('CommunityOpen').OnClientEvent:Connect(function(kind)
 if kind~='Shelter'and kind~='Feedback'then return end
 close();epoch+=1;mode=kind;N.Acquire('Community',kind);gui.Enabled=true
 title.Text=kind=='Shelter'and 'DOG SHELTER'or 'DEVELOPER MAILBOX';status.Text='';layout()
 if kind=='Shelter'then showShelter()else showFeedback()end
end)
task.spawn(function()
 while gui.Parent do task.wait(.5)
  if gui.Enabled then
   if shelterQuote and os.time()>shelterQuote.Expires then local b=content:FindFirstChild('ConfirmSale',true);if b then b:SetAttribute('IntrinsicEnabled',false);U.SetButtonEnabled(b,false);local cap=b:FindFirstChild('Caption');if cap then cap.Text='QUOTE EXPIRED'end end end
   local hub=workspace.DOGROTS_District:FindFirstChild('32_WelcomeHub')
   local target=hub and(mode=='Shelter'and hub.DogShelter.SellAnchor or hub.DeveloperMailbox.MailboxBody)
   local hrp=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
   if not target or not hrp or(hrp.Position-target.Position).Magnitude>23 then close()end
  end
 end
end)

-- A small, nonmodal coach. Gameplay remains usable; only the server advances tasks.
local Players=game:GetService('Players')
local RS=game:GetService('ReplicatedStorage')
local Http=game:GetService('HttpService')
local UIS=game:GetService('UserInputService')
local GuiService=game:GetService('GuiService')
local Guide={}
local controller
local cards={
 [0]={Title='WELCOME TO DOGROTS!',Icon='Dogs',Body='Find a dog, give it a kennel, then sell its discoveries. Six small steps will show you how.',Button='LET\'S PLAY'},
 [1]={Title='GET A LUCKY BLOCK',Icon='Inventory',Body='Visit the tongue conveyor. Use BUY BLOCK on an affordable block. It goes straight into BAG.',Button='SHOW CONVEYOR',Destination='THE DOG'},
 [2]={Title='PLACE YOUR BLOCK',Icon='Yard',Body='Your block is in BAG. At your yard, use an empty Lucky Pad and select your block to start its timer.',Button='SHOW MY YARD',Destination='Your yard'},
 [3]={Title='WAIT, THEN OPEN',Icon='Inventory',Body='When the timer ends, use OPEN BLOCK at the pad. Your new dog will appear in DOGS.',Button='SHOW MY YARD',Destination='Your yard'},
 [4]={Title='GIVE YOUR DOG A JOB',Icon='Dogs',Body='At your yard, use an empty kennel and choose your dog. It will begin digging automatically.',Button='SHOW MY YARD',Destination='Your yard'},
 [5]={Title='YOUR FIRST DISCOVERY',Icon='Discoveries',Body='Let your dog finish a digging cycle. Its find appears beside the kennel and is saved in BAG.',Button='VIEW MY DOGS',Page='Dogs'},
 [6]={Title='TURN FINDS INTO COINS',Icon='Coins',Body='Visit the Collector in your own yard. Choose an unlocked find, review its value, then confirm the sale.',Button='SHOW MY YARD',Destination='Your yard'},
 [7]={Title='YOU\'RE READY!',Icon='Ticket',Body='Supplies give timed boosts. Spin DOG-O-MATIC with your free DOG TOKEN (a new one 5 hours after use) to chase Aurion, the 0.01% jackpot. Explore!',Button='KEEP EXPLORING'},
}
function Guide.Replay()
 if controller then controller.Replay()end
end
function Guide.Start(gui,navigation)
 if controller then return controller end
 local U=require(script.Parent.UITheme)
 local Price=require(RS.PriceFormat)
 local player=Players.LocalPlayer
 local remote=RS:WaitForChild('DogEconomyRequest')
 local root=U.New('Frame',{Name='OnboardingGuide',Visible=false,Active=false,BackgroundColor3=U.Colors.panel,BorderSizePixel=0,ZIndex=75},gui)
 U.Round(root,16);U.Stroke(root,U.Colors.edge,3)
 local accent=U.New('Frame',{Name='Accent',BackgroundColor3=U.Colors.blue,BorderSizePixel=0,Position=UDim2.fromOffset(12,12),Size=UDim2.fromOffset(4,32),ZIndex=76},root);U.Round(accent,2)
 local heading=U.Text(root,'',25,8,250,21,13,U.Colors.blue,true);heading.Name='ProgressCaption';heading.ZIndex=77
 local title=U.Text(root,'',25,29,270,30,21,U.Colors.text,true);title.Name='TaskTitle';title.ZIndex=77
 local body=U.Text(root,'',18,65,364,58,16,U.Colors.text,false);body.Name='TaskBody';body.ZIndex=77;body.TextYAlignment=Enum.TextYAlignment.Top
 local iconHolder=U.New('Frame',{Name='TaskIcon',BackgroundTransparency=1,Size=UDim2.fromOffset(42,42),ZIndex=76},root)
 local pending=false;local collapsed=false;local replayStep=nil;local alive=true;local errorText=nil;local lastIcon=nil;local showAfter=os.clock()+2.5
 local render
 local function stage()return replayStep or math.clamp(tonumber(player:GetAttribute('TutorialStep'))or 0,0,7)end
 local function request(action)
  if pending then return end
  pending=true;errorText=nil;render()
  task.spawn(function()
   local id=Http:GenerateGUID(false):gsub('-','')
   local transport,ok,value=pcall(function()return remote:InvokeServer('Tutorial',{Action=action},id)end)
   if not alive then return end
   pending=false
   if not transport or not ok then errorText='Could not save the guide. Tap again to retry.'end
   render()
  end)
 end
 local primary=U.Button(root,'Action','',18,135,244,42,function()
  local step=stage();local card=cards[step]
  if replayStep~=nil then
   if replayStep<7 then replayStep+=1 else replayStep=nil end
   errorText=nil;render();return
  end
  if step==0 then request('Start')
  elseif step==7 then request('Finish')
  elseif card.Page then navigation.OpenPage(card.Page)
  elseif card.Destination then navigation.Navigate(card.Destination)end
 end,U.Colors.green)
 local skip=U.Button(root,'Skip','SKIP',270,135,100,42,function()
  if replayStep~=nil then replayStep=nil;render()else request(stage()==7 and'Finish'or'Skip')end
 end,U.Colors.blue)
 local collapse=U.Button(root,'Collapse','-',0,0,44,44,function()collapsed=not collapsed;render()end,U.Colors.blue)
 for _,button in ipairs({primary,skip,collapse})do button.ZIndex=77;button.Caption.ZIndex=78 end
 local progress={}
 for i=1,6 do progress[i]=U.New('Frame',{Name='Step'..i,Size=UDim2.fromOffset(24,4),BackgroundColor3=U.Colors.secondary,BorderSizePixel=0,ZIndex=76},root);U.Round(progress[i],2)end
 local marker=U.New('BillboardGui',{Name='TutorialWorldMarker',Enabled=false,ResetOnSpawn=false,AlwaysOnTop=false,MaxDistance=100,Size=UDim2.fromOffset(210,48),StudsOffsetWorldSpace=Vector3.new(0,5,0),LightInfluence=0},player:WaitForChild('PlayerGui'))
 local markerText=U.Center(marker,'',4,2,202,42,18,U.Colors.gold,true);markerText.TextStrokeTransparency=0;markerText.TextStrokeColor3=U.Colors.edge
 local function target(step)
  if step~=2 and step~=3 and step~=6 then return end
  local map=workspace:FindFirstChild('DOGROTS_District');local yards=map and map:FindFirstChild('04_PlayerYards')
  if not yards then return end
  for _,yard in ipairs(yards:GetChildren())do
   if yard:GetAttribute('OwnerUserId')==player.UserId and yard:GetAttribute('YardId')==player:GetAttribute('YardId')then
    if step==6 then return yard:FindFirstChild('SellAnchor'),'YOUR COLLECTOR'end
    for i=1,3 do
     local pad=yard:FindFirstChild('LuckyPad_'..i)
     if pad and(step==2 and not pad:GetAttribute('LuckyBlockUid')or step==3 and pad:GetAttribute('LuckyBlockUid'))then return pad,step==2 and'YOUR LUCKY PAD'or'YOUR BLOCK'end
    end
   end
  end
 end
 render=function()
  if not alive then return end
  local active=replayStep~=nil or player:GetAttribute('TutorialActive')==true
  local modal=gui:GetAttribute('OpenMenu')~=nil or(gui:GetAttribute('ModalOwnerCount')or 0)>0
  root.Visible=active and not modal and player:GetAttribute('EconomyReady')==true and os.clock()>=showAfter
  marker.Enabled=false
  if not root.Visible then return end
  local step=stage();local card=cards[step]
  local left,top,width,height=U.SafeArea(gui)
  local narrow=width<600;local touch=UIS.TouchEnabled
  local cardW=math.min(narrow and 326 or touch and 340 or 436,width-24)
  local compact=cardW<400
  local cardH=collapsed and 48 or(compact and 206 or 194)
  local bottom=touch and height>width and 235 or 16
  root.Size=UDim2.fromOffset(cardW,cardH)
  root.Position=UDim2.fromOffset(left+math.floor((width-cardW)/2),top+math.max(8,height-bottom-cardH))
  heading.Text=replayStep~=nil and('HOW TO PLAY  '..(step+1)..' / 8')or step==0 and'QUICK START' or step==7 and'QUICK START COMPLETE'or('QUICK START  '..step..' / 6')
  title.Text=card.Title
  title.TextSize=compact and 17 or 20;title.Position=UDim2.fromOffset(25,collapsed and 13 or 30)
  title.Size=UDim2.fromOffset(cardW-(collapsed and 78 or 125),collapsed and 26 or 27)
  heading.Visible=not collapsed;body.Visible=not collapsed;iconHolder.Visible=not collapsed
  primary.Visible=not collapsed;skip.Visible=not collapsed
  accent.Position=UDim2.fromOffset(12,collapsed and 10 or 12);accent.Size=UDim2.fromOffset(4,collapsed and 28 or 40)
  collapse.Position=UDim2.fromOffset(cardW-47,2);collapse.Caption.Text=collapsed and'+'or'-';collapse.Caption.TextSize=24
  iconHolder.Position=UDim2.fromOffset(cardW-91,15)
  if card.Icon~=lastIcon then
   iconHolder:ClearAllChildren();local icon=U.Icon(iconHolder,card.Icon,0,0,42)
   for _,child in ipairs(icon:GetDescendants())do if child:IsA('GuiObject')then child.ZIndex=78 end end
   icon.ZIndex=78;lastIcon=card.Icon
  end
  local description=card.Body
  if step==3 and replayStep==nil then
   local remaining=math.max(0,(tonumber(player:GetAttribute('TutorialReadyAt'))or 0)-workspace:GetServerTimeNow())
   description=remaining>0 and('Ready in '..Price.Clock(remaining)..'. You can explore while it prepares. Return and use OPEN BLOCK when ready.')or'Your block is ready! Use OPEN BLOCK at its pad. It waits safely until you choose to open it.'
  end
  body.Text=errorText or description;body.TextSize=compact and 14 or 16
  body.Position=UDim2.fromOffset(18,66);body.Size=UDim2.fromOffset(cardW-36,cardH-126)
  local buttonY=cardH-58;local primaryW=cardW-138
  primary.Position=UDim2.fromOffset(18,buttonY);primary.Size=UDim2.fromOffset(primaryW,42)
  primary.Caption.Size=UDim2.new(1,-12,1,-4);primary.Caption.TextSize=compact and 13 or 15
  primary.Caption.Text=pending and'SAVING...'or replayStep~=nil and(step==7 and'DONE'or'NEXT')or card.Button
  skip.Position=UDim2.fromOffset(cardW-112,buttonY);skip.Size=UDim2.fromOffset(94,42);skip.Caption.Size=UDim2.new(1,-12,1,-4);skip.Caption.TextSize=14
  skip.Caption.Text=replayStep~=nil and'CLOSE'or step==7 and'CLOSE'or'SKIP'
  U.SetButtonEnabled(primary,not pending);U.SetButtonEnabled(skip,not pending)
  local segment=(cardW-36-5*5)/6
  for i,bar in ipairs(progress)do bar.Visible=not collapsed;bar.Position=UDim2.fromOffset(18+(i-1)*(segment+5),cardH-8);bar.Size=UDim2.fromOffset(segment,4);bar.BackgroundColor3=step>i and U.Colors.green or step==i and U.Colors.gold or U.Colors.secondary end
  if replayStep==nil and not collapsed then local object,label=target(step);if object and object:IsA('BasePart')then marker.Adornee=object;markerText.Text=label;marker.Enabled=true end end
 end
 local connections={}
 local function connect(signal,callback)table.insert(connections,signal:Connect(callback))end
 for _,name in ipairs({'TutorialStep','TutorialActive','TutorialReadyAt','EconomyReady','YardId'})do connect(player:GetAttributeChangedSignal(name),render)end
 for _,name in ipairs({'OpenMenu','ModalOwnerCount'})do connect(gui:GetAttributeChangedSignal(name),render)end
 connect(gui:GetPropertyChangedSignal('AbsoluteSize'),render)
 connect(GuiService:GetPropertyChangedSignal('TopbarInset'),render)
 connect(UIS:GetPropertyChangedSignal('TouchEnabled'),render)
 controller={Replay=function()navigation.Close();replayStep=0;collapsed=false;errorText=nil;showAfter=0;render()end}
 connect(gui.Destroying,function()alive=false;marker:Destroy();for _,connection in ipairs(connections)do connection:Disconnect()end;controller=nil end)
 task.spawn(function()while alive and gui.Parent do render();task.wait(.5)end end)
 render()
 return controller
end
return Guide

-- WORLD EVENTS: what is happening now, what it gives you, what comes next (the schedule is
-- deterministic, so every client computes the same upcoming events), why it is worth staying,
-- and Aurion, the DOG-O-MATIC's ultra-rare prize.
local RS=game:GetService('ReplicatedStorage')
local package=RS:WaitForChild('WorldEvents')
local Definitions=require(package.WorldEventDefinitions);local Schedule=require(package.WorldEventSchedule)
local EventConfig=require(package.WorldEventConfig);local Price=require(RS.PriceFormat)
local V=require(script.Parent.PreviewRenderer)
local S={}
local rarityColors={Common=Color3.fromRGB(125,219,48),Uncommon=Color3.fromRGB(38,164,243),Rare=Color3.fromRGB(161,103,242),Secret=Color3.fromRGB(247,73,112)}
local function hidden(def)return def.Rarity=='Secret'end
function S.Build(c)
 local U,W,H=c.U,c.W,c.H;local P=U.Colors
 local sc=U.Scroll(c.Parent,'WorldEventsContent',0,0,W,H)
 local state=package:FindFirstChild('State')
 local now=workspace:GetServerTimeNow()
 local phase=state and state:GetAttribute('State')or'NORMAL'
 local current=state and Definitions.ById[state:GetAttribute('EventId')or'']
 local ends=state and state:GetAttribute('EndTimestamp')or now
 local period=Schedule.Period();local at=Schedule.At(math.floor(now))
 -- Calm phases: EndTimestamp is the warning (NORMAL) or the next calm (ENDING); count down to
 -- the next event's actual start instead.
 if phase=='NORMAL'then ends=at.StartTimestamp elseif phase~='ACTIVE'and phase~='WARNING'then ends=at.StartTimestamp+period end
 local y=0
 -- Now.
 local hero=U.Panel(sc,'CurrentEvent',8,y,W-24,phase=='ACTIVE'and 300 or 170,true)
 local theme=current and current.ColorTheme or P.gold
 U.Gradient(hero,theme:Lerp(Color3.new(1,1,1),.55),Color3.fromRGB(255,251,242))
 local title,sub
 if phase=='ACTIVE'and current then title=(hidden(current)and'[ '..current.DisplayName..' ]'or current.DisplayName:upper());sub='HAPPENING NOW · ENDS IN '
 elseif phase=='WARNING'and current then title=hidden(current)and'[ WORLD STATE ERROR ]'or current.DisplayName:upper();sub='STARTS IN '
 else title='THE ISLAND IS CALM';sub='NEXT WORLD EVENT IN 'end
 U.Text(hero,title,16,8,W-56,40,30,P.text,true)
 local clock=U.Text(hero,sub..'--:--:--',16,48,W-56,28,19,P.muted,true)
 clock:SetAttribute('Deadline',ends);clock:SetAttribute('CountdownStyle','Clock');clock:SetAttribute('CountdownPrefix',sub)
 if phase=='ACTIVE'and current then
  U.Text(hero,current.Subtitle,16,78,W-56,26,16,P.text)
  local lines=Definitions.PerkLines(current)
  local half=math.ceil(#lines/2);local colW=(W-56)/2
  for i,text in ipairs(lines)do
   local col=i<=half and 0 or 1;local row=i<=half and i or i-half
   U.Text(hero,'✦ '..text,16+col*colW,104+(row-1)*26,colW-8,24,15,P.text,true)
  end
 else
  U.Text(hero,'World events change the island for everyone on the server: gravity, speed, the tongue\'s luck. Stay until the end of one for a reward.',16,78,W-56,80,16,P.text)
 end
 y+=(phase=='ACTIVE'and 300 or 170)+14
 -- Why wait.
 local why=U.Header(sc,'WhyWait',8,y,W-24,40);U.Text(why,'WHY WAIT FOR AN EVENT?',12,0,W-48,40,22,P.text,true);y+=48
 local reasons={{'Luck','RARER DOGS','The tongue brings Legendary, Mythic and Secret dogs more often during every event.'},
  {'Coins','END REWARD','Everyone who stays at least a minute gets Coins, Bones and often free LUCK when it ends.'},
  {'Events','THE WORLD CHANGES','Low gravity, zoomies, quakes, tractor beams: every event plays differently.'}}
 local cols=math.max(1,math.min(3,math.floor((W-10)/240)));local cw=(W-24-(cols-1)*12)/cols
 for i,row in ipairs(reasons)do
  local card=U.Panel(sc,'Reason'..i,8+(i-1)%cols*(cw+12),y+math.floor((i-1)/cols)*136,cw,124)
  U.Icon(card,row[1],10,10,46,P.gold);U.Text(card,row[2],64,10,cw-74,30,19,P.text,true)
  U.Text(card,row[3],12,58,cw-24,60,14,P.muted)
 end
 y+=math.ceil(#reasons/cols)*136+6
 -- Coming up.
 local up=U.Header(sc,'Upcoming',8,y,W-24,40);U.Text(up,'COMING UP',12,0,W-48,40,22,P.text,true);y+=48
 local first=at.Cycle+((phase=='NORMAL'or phase=='WARNING')and 0 or 1)
 for k=0,4 do
  local index=first+k
  local id=Schedule.Event(index);local def=Definitions.ById[id]
  if def then
   local start=EventConfig.Epoch+index*period+EventConfig.NormalInterval+EventConfig.WarningDuration
   local card=U.Panel(sc,'Upcoming'..k,8,y,W-24,66)
   local stripe=U.Frame(card,'Stripe',0,0,8,66,rarityColors[def.Rarity]or P.gold);U.Round(stripe,4)
   local name=hidden(def)and'??? · A SECRET EVENT'or def.DisplayName:upper()..' · '..string.upper(def.Rarity)
   U.Text(card,name,20,4,W*.55,30,19,P.text,true)
   local lines=hidden(def)and {'NOBODY KNOWS WHAT IT DOES'}or Definitions.PerkLines(def)
   U.Text(card,table.concat({lines[1]or'',lines[2]or''},'  ·  '),20,34,W-210,26,13,P.muted)
   local when=U.Text(card,'',W-200,4,170,58,18,P.text,true);when.TextXAlignment=Enum.TextXAlignment.Right
   when:SetAttribute('Deadline',start);when:SetAttribute('CountdownStyle','Clock');when:SetAttribute('CountdownPrefix','IN ')
   y+=74
  end
 end
 y+=6
 -- Aurion.
 local prize=U.Panel(sc,'AurionPrize',8,y,W-24,240,true)
 U.Gradient(prize,Color3.fromRGB(214,240,255),Color3.fromRGB(246,226,255))
 local artW=math.min(260,(W-24)*.42)
 V.Dog(prize,'Aurion',8,8,artW,224)
 U.Text(prize,'AURION',artW+20,10,W-artW-60,40,30,P.text,true)
 U.Text(prize,'The DOG-O-MATIC\'s ultra-rare prize: 1 in 10,000 per spin. Every tenth dig it echoes an extra discovery roll. When it is won, the whole island watches the light split into nine.',artW+20,52,W-artW-60,104,15,P.text)
 local bw=(W-artW-72)/2
 U.Button(prize,'FindMachine','FIND DOG-O-MATIC',artW+20,168,bw,46,function()c.Go('RewardMachine')end,P.blue).Caption.TextSize=15
 U.Button(prize,'GetSpins','GET LUCKY SPINS',artW+28+bw,168,bw,46,function()c.State.CommerceJump='DOG-O-MATIC Spins';c.Show('Shop')end,P.purple).Caption.TextSize=15
 y+=252
 U.Text(sc,'Events run on one schedule for every server: about every '..math.floor(period/60)..' minutes, '..math.floor(EventConfig.EventDuration/60)..' minutes each.',8,y,W-24,40,15,P.muted)
end
return S

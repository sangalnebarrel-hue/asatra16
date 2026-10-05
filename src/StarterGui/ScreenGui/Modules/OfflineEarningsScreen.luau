local S={}
local function duration(seconds)
 seconds=math.max(0,math.floor(tonumber(seconds)or 0))
 local hours=math.floor(seconds/3600);local minutes=math.floor(seconds/60)%60
 return hours>0 and string.format('%dh %02dm',hours,minutes)or minutes..'m'
end
function S.Build(c)
 local U,W,H=c.U,c.W,c.H;local P=U.Colors
 local report=c.Snapshot.OfflineEarnings or{}
 local amount=tonumber(report.PendingCoins)or 0
 local sc=U.Scroll(c.Parent,'OfflineReport',0,0,W,H)
 local bannerH=W<420 and 210 or 180
 local banner=U.Panel(sc,'WelcomeBack',8,4,W-24,bannerH,true)
 U.Gradient(banner,Color3.fromRGB(225,255,158),Color3.fromRGB(255,237,149))
 U.Center(banner,amount>0 and'YOUR PACK KEPT BUSY!'or'WELCOME HOME!',12,14,W-48,36,29,P.text,true)
 U.Center(banner,'+'..U.Fmt(amount)..' COINS',12,59,W-48,65,W<620 and 33 or 43,P.text,true)
 U.Center(banner,amount>0 and'Ready to add to your wallet.'or'Assign dogs to kennels to earn while you are away.',18,132,W-60,W<420 and 64 or 34,18,P.muted)
 U.Button(sc,'ClaimOffline',c.Busy and'CLAIMING…'or amount>0 and'CLAIM '..U.Fmt(amount)..' COINS'or'NOTHING TO CLAIM',8,bannerH+22,W-24,57,not c.Busy and report.CanClaim==true and amount>0 and function()
  c.Send('ClaimOffline',{PendingId=report.PendingId})
 end or nil,P.green)
 local y=bannerH+96
 local seconds=tonumber(report.PendingSeconds)or 0
 U.Text(sc,'WORK TIME: '..duration(seconds)..'   ·   LAST TIME AWAY: '..duration(report.AwaySeconds),12,y,W-32,45,18,P.text,true);y+=53
 U.Text(sc,string.format('Assigned dogs earn %.0f%% of their base income for up to %s. Claim whenever you are ready.',(report.Efficiency or .35)*100,duration(report.CapSeconds or 28800)),12,y,W-32,63,18,P.muted);y+=71
 if report.WasCapped then U.Text(sc,'Your offline earning limit was reached. Your saved coins are safe.',12,y,W-32,48,17,P.purple);y+=54 end
 local dogs=amount>0 and(report.Dogs or{})or(report.CurrentDogs or{})
 U.Text(sc,amount>0 and'YOUR HARD-WORKING DOGS'or'YOUR ASSIGNED DOGS',12,y,W-32,31,23,P.text,true);y+=41
 local cols=math.max(1,math.min(3,math.floor((W-10)/210)));local cw=(W-24-(cols-1)*12)/cols
 for i,dog in ipairs(dogs)do
  local card=U.Panel(sc,'OfflineDog_'..tostring(dog.Uid or i),8+(i-1)%cols*(cw+12),y+math.floor((i-1)/cols)*226,cw,214,true)
  require(script.Parent.PreviewRenderer).Dog(card,dog.DogId,7,5,cw-14,108)
  U.Center(card,dog.Name or dog.DogId,8,116,cw-16,54,20,P.text,true)
  U.Center(card,amount>0 and('+'..U.Fmt(dog.Coins or 0)..' COINS')or string.format('%.2f COINS / SEC',dog.Rate or 0),8,177,cw-16,30,17,P.text,true)
 end
 if #dogs==0 then U.Center(sc,'No assigned dogs yet. Choose your team in MY DOGS.',16,y+15,W-40,100,22,P.muted)end
end
return S

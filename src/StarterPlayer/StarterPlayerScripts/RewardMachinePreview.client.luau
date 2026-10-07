-- Per-player percentages come from the same exact integer slots as the roll.
local RS=game:GetService('ReplicatedStorage');local player=game.Players.LocalPlayer
local rig=workspace:WaitForChild('DOGROTS_District'):WaitForChild('37_AttractionRefresh'):WaitForChild('RewardMachineRig')
local board=rig:WaitForChild('StatusBoard',60):WaitForChild('OddsDisplay')
local focus=rig:WaitForChild('CameraHooks'):WaitForChild('RevealFocus',60)
local remote=RS:WaitForChild('RewardRequest');local motion=require(RS.RewardMachineMotion)
local prompt=workspace.DOGROTS_District:WaitForChild('27_RewardMachinePlaza'):WaitForChild('RewardMachine'):FindFirstChild('RewardMachinePrompt',true)
local snapshot;local fetchedAt=-30
-- The jackpot row is outlined in gold; other rows keep their authored stroke.
local GOLD=Color3.fromRGB(255,206,64);local strokes={}
local function clockText(s)s=math.max(0,math.ceil(s));return string.format('%02d:%02d:%02d',math.floor(s/3600),math.floor(s/60)%60,s%60)end
local function refresh()
 local good,ok,info=pcall(function()return remote:InvokeServer('RewardMachineInfo',{})end)
 if not good or not ok then return end
 snapshot=info;fetchedAt=os.clock();local faces={}
 require(RS.RewardMachineText).Apply(rig,info.Rewards)
 for i=1,motion.PrizeCount do
  local text=board.Rows:FindFirstChild('Row'..i);local row=info.Rewards[i]
  if text then
   text.Visible=row~=nil
   if row then
    text.Text=(row.Jackpot and 'JACKPOT: 'or '')..row.Name..'  '..(row.ChanceText or string.format('%.2f%%',row.Chance*100));text.TextColor3=motion.Color(row)
    strokes[text]=strokes[text]or{Color=text.TextStrokeColor3,Transparency=text.TextStrokeTransparency}
    text.TextStrokeColor3=row.Jackpot and GOLD or strokes[text].Color;text.TextStrokeTransparency=row.Jackpot and 0 or strokes[text].Transparency
   end
  end
  if row then faces[row.PrizeIndex]=row end
 end
 for i=1,motion.PrizeCount do
  local face=rig.SpinningDrum:FindFirstChild('PrizeFace_'..i,true);local gui=face and face:FindFirstChild('Lettering')
  if gui then local row=faces[i];gui.Subtitle.Text=row and((row.ChanceText or string.format('%.2f%%',row.Chance*100))..' CHANCE')or 'UNLOCK AT A DEEPER LAYER'end
 end
end
while player.Parent do
 local root=player.Character and player.Character:FindFirstChild('HumanoidRootPart')
 if root and(root.Position-focus.Position).Magnitude<160 then
  if os.clock()-fetchedAt>=10 then refresh()end
  if snapshot then
   local now=snapshot.ServerNow+(os.clock()-fetchedAt);local free=snapshot.FreeTickets or 0
   -- Paid DOG TOKENS count only where this account may use them (PolicyService).
   local spendable=snapshot.PaidSpendable==true or(snapshot.PaidSpendable==nil and snapshot.FreeOnly~=true and snapshot.PaidRandomAllowed==true)
   local paid=spendable and(tonumber(snapshot.PaidTickets)or 0)or 0
   local status=free>=1 and 'READY TO ACTIVATE'or paid>0 and 'PAID DOG TOKENS READY'or 'NEXT FREE DOG TOKEN  '..clockText((snapshot.NextTicketAt or 0)-now)
   board.Status.Text=(paid>0 and 'YOUR DOG TOKENS '..(free+paid)..' · FREE '..free..'/1'or 'FREE DOG TOKEN '..free..'/1')..'\n'..status
   if prompt then prompt.ActionText=free+paid>=1 and 'ACTIVATE · 1 DOG TOKEN'or 'VIEW';prompt.ObjectText='DOG-O-MATIC'end
  else board.Status.Text='Open DOG-O-MATIC to view reward chances'end
 end
 task.wait(1)
end

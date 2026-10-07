local C=require(script.Parent.RewardMachineConfig)
local Odds=require(script.Parent.RewardMachineOdds)
local T={}
function T.Pool()return Odds.Build(C.Rewards,C.OddsDenominator)end
function T.Aurion()
 for _,row in ipairs(T.Pool())do if row.Id=='Aurion'then return row.ChanceText end end
 return 'Unavailable'
end
function T.Apply(rig,pool)
 pool=pool or T.Pool()
 local faces={}
 for _,row in ipairs(pool)do faces[row.PrizeIndex]=row end
 local board=rig:FindFirstChild('StatusBoard');local rows=board and board:FindFirstChild('OddsDisplay')and board.OddsDisplay:FindFirstChild('Rows')
 if rows then for i=1,#C.Rewards do local label=rows:FindFirstChild('Row'..i);local row=pool[i];if label then label.Visible=row~=nil;if row then label.Text=(row.Jackpot and'JACKPOT: 'or'')..row.Name..'  '..row.ChanceText end end end end
 local drum=rig:FindFirstChild('SpinningDrum')
 if drum then for i=1,#C.Rewards do local face=drum:FindFirstChild('PrizeFace_'..i,true);local gui=face and face:FindFirstChild('Lettering');if gui and gui:FindFirstChild('Subtitle')then gui.Subtitle.Text=faces[i]and(faces[i].ChanceText..' CHANCE')or'UNLOCK AT A DEEPER LAYER'end end end
 local aurion
 for _,row in ipairs(pool)do if row.Id=='Aurion'then aurion=row end end
 local rules=rig:FindFirstChild('TicketRules');local gui=rules and rules:FindFirstChild('Lettering')
 if gui then
  gui.Title.Text='1 DOG TOKEN\nONE ACTIVATION'
  gui.Free.Text='FREE TOKEN EVERY '..tostring(C.TicketRefillSeconds/3600)..' HOURS AFTER USE'
  gui.Capacity.Text=C.FreeOnly and('HOLDS '..C.TicketCapacity..' FREE DOG TOKEN')or('HOLDS '..C.TicketCapacity..' FREE · MORE SPINS: GET SPINS')
 end
 local displays=rig:FindFirstChild('RewardVitrines');local tower=displays and displays:FindFirstChild('TreasureTower')
 local plaque=tower and tower:FindFirstChild('PrizePlaque')
 if plaque and plaque:FindFirstChild('Lettering')then plaque.Lettering.Title.Text='AURION · ULTRA RARE · '..(aurion and aurion.ChanceText or'Unavailable')end
end
return T

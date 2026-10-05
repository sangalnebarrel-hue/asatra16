-- UTC deadlines are saved with the profile, so reconnecting and offline time cannot
-- reset the cooldown. Reading a status never creates a second banked ticket.
local C=require(game:GetService('ReplicatedStorage').RewardMachineConfig)
local T={MaximumSafeBalance=9007199254740990}
local function integer(n)return type(n)=='number'and n==n and n%1==0 and math.abs(n)<9007199254740991 end
function T.State(p,now)
 local count=p.RouletteTickets
 local deadline=p.NextRouletteTicketAt
 if count==nil then count=C.StartingTickets end -- One-time migration for existing profiles.
 count=integer(count)and math.clamp(count,0,C.TicketCapacity)or 0
 deadline=integer(deadline)and math.max(0,deadline)or 0
 if count>=C.TicketCapacity then return C.TicketCapacity,0 end
 if deadline==0 then deadline=now+C.TicketRefillSeconds end
 if now>=deadline then return C.TicketCapacity,0 end
 return count,deadline
end
function T.Normalize(p,now)
 p.RouletteTickets,p.NextRouletteTicketAt=T.State(p,now)
 -- Legacy RouletteTickets remains the FREE balance. Never fold purchased tickets
 -- into it, clamp them to one, or reset them when a free ticket refills.
 if p.PaidRouletteTickets==nil then p.PaidRouletteTickets=0 end
 assert(integer(p.PaidRouletteTickets)and p.PaidRouletteTickets>=0,'Invalid paid ticket balance')
 return p.RouletteTickets,p.NextRouletteTicketAt
end
function T.Paid(p)
 local count=p.PaidRouletteTickets or 0
 assert(integer(count)and count>=0,'Invalid paid ticket balance')
 return count
end
function T.GrantPaid(p,count,now)
 assert(integer(count)and count>0,'Invalid ticket quantity')
 T.Normalize(p,now)
 assert(p.PaidRouletteTickets<=T.MaximumSafeBalance-count,'Paid ticket numeric capacity reached')
 p.PaidRouletteTickets+=count
 return p.PaidRouletteTickets
end
function T.Consume(p,now,paidAllowed)
 local count=T.Normalize(p,now)
 if count>=C.TicketCost then
  p.RouletteTickets=count-C.TicketCost
  p.NextRouletteTicketAt=now+C.TicketRefillSeconds
  return p.RouletteTickets,p.NextRouletteTicketAt,'Free'
 end
 assert(C.FreeOnly~=true,'Your free DOG TOKEN is still recharging')
 assert(p.PaidRouletteTickets>=C.TicketCost,'Your free DOG TOKEN is still recharging')
 assert(paidAllowed==true,'Paid random tickets are unavailable for this account; your tickets are kept')
 p.PaidRouletteTickets-=C.TicketCost
 -- Spending a purchased ticket does not restart the free ticket's timer.
 return p.RouletteTickets,p.NextRouletteTicketAt,'Paid'
end
function T.Validate(p)
 assert(integer(p.RouletteTickets)and p.RouletteTickets>=0 and p.RouletteTickets<=C.TicketCapacity,'Invalid ticket balance')
 assert(integer(p.NextRouletteTicketAt)and p.NextRouletteTicketAt>=0,'Invalid ticket deadline')
 assert(p.RouletteTickets<C.TicketCapacity or p.NextRouletteTicketAt==0,'Full ticket wallet cannot recharge')
 assert(integer(p.PaidRouletteTickets)and p.PaidRouletteTickets>=0,'Invalid paid ticket balance')
end
return T

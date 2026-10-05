-- Profile-only tutorial state. Observe runs inside the normal economy transaction.
-- UI requests can start or hide the guide; they cannot manufacture gameplay progress.
local O={Version=1,LastStep=7}
local milestones={'Bought','Placed','Opened','Assigned','Found','Sold'}
local function positive(value)return type(value)=='number'and value==value and value>0 end
local function nonempty(value)return type(value)=='table'and next(value)~=nil end
local function experienced(p)
 return nonempty(p.Dogs)or nonempty(p.DogDex)or positive((p.Stats or{}).TotalFinds)
  or positive((p.Stats or{}).TotalSellValue)or positive(p.TotalExcavations)or (p.Level or 1)>1
end
function O.New()
 return {Version=O.Version,Status='Active',Step=0,Seen={}}
end
function O.Normalize(p)
 local t=p.Onboarding
 if type(t)~='table'then
  t=O.New();p.Onboarding=t
  -- Existing players with established progress are never interrupted by a new tutorial.
  -- A fresh profile explicitly receives O.New() from Rules.Profile before normalization.
  if experienced(p)then t.Status='Complete';t.Step=O.LastStep;t.Migrated=true end
 end
 t.Version=O.Version
 if t.Status~='Active'and t.Status~='Complete'and t.Status~='Skipped'then t.Status='Active'end
 if type(t.Step)~='number'or t.Step~=t.Step then t.Step=0 end
 t.Step=math.clamp(math.floor(t.Step),0,O.LastStep)
 if type(t.Seen)~='table'then t.Seen={}end
 for _,key in ipairs(milestones)do t.Seen[key]=t.Seen[key]==true end
 return t
end
function O.Observe(p,now)
 local t=O.Normalize(p);local seen=t.Seen
 for _,block in pairs(p.OwnedBlocks or{})do
  seen.Bought=true
  if block.State=='Placed'or block.State=='Ready'then seen.Placed=true end
 end
 for _,count in pairs(p.LuckyCredits or{})do if positive(count)then seen.Bought=true end end
 for _,count in pairs(p.LuckyOpened or{})do
  if positive(count)then seen.Bought=true;seen.Placed=true;seen.Opened=true end
 end
 -- A dog obtained from another legitimate system is already enough to teach assignment.
 for _,dog in pairs(p.Dogs or{})do
  seen.Bought=true;seen.Placed=true;seen.Opened=true
  if type(dog.AssignedSlot)=='string'and dog.AssignedSlot~=''then seen.Assigned=true end
 end
 if positive((p.Stats or{}).TotalFinds)then seen.Found=true end
 if positive((p.Stats or{}).TotalSellValue)then seen.Sold=true end
 if t.Status=='Active'and t.Step>0 then
  while t.Step<O.LastStep and seen[milestones[t.Step]]do t.Step+=1 end
 end
 if type(now)=='number'and t.Status=='Complete'and not t.CompletedAt and not t.Migrated then t.CompletedAt=now end
 return t
end
function O.View(p)
 local t=p.Onboarding or O.New();local readyAt=0
 for _,block in pairs(p.OwnedBlocks or{})do
  if (block.State=='Placed'or block.State=='Ready')and type(block.ReadyAt)=='number'then
   if readyAt==0 or block.ReadyAt<readyAt then readyAt=block.ReadyAt end
  end
 end
 return {Version=O.Version,Status=t.Status,Step=t.Step,Active=t.Status=='Active',ReadyAt=readyAt}
end
function O.Apply(p,action,now)
 assert(action=='Start'or action=='Skip'or action=='Finish','Unknown tutorial action')
 local t=O.Observe(p,now)
 if action=='Start'then
  if t.Status=='Active'and t.Step==0 then t.Step=1;O.Observe(p,now)end
 elseif action=='Skip'then
  if t.Status=='Active'then t.Status='Skipped';t.SkippedAt=now end
 else
  assert(t.Status=='Complete'or(t.Status=='Active'and t.Step==O.LastStep),'Finish the tutorial tasks first')
  t.Status='Complete';t.CompletedAt=t.CompletedAt or now
 end
 return O.View(p)
end
return O

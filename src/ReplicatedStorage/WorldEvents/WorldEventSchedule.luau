local C=require(script.Parent.WorldEventConfig);local D=require(script.Parent.WorldEventDefinitions)
local S={};local cache={}
function S.Period()return C.NormalInterval+C.WarningDuration+C.EventDuration+C.TransitionDuration end
local function pick(random,previous,streak,exclude)
 local pool,total={},0
 for _,d in ipairs(D.List)do if d.Enabled and d.Id~=previous and d.Id~=exclude then
  local weight=d.Weight
  if d.Rarity=='Rare'then weight*=1+math.min(C.Diversity.Cap,math.max(0,streak-C.Diversity.RareAfter)*C.Diversity.Step)end
  total+=weight;table.insert(pool,{Def=d,Ceiling=total})
 end end
 local n=random:NextNumber()*total;for _,row in ipairs(pool)do if n<row.Ceiling then return row.Def end end;return pool[#pool].Def
end
local function first(block)return pick(Random.new(C.Seed+block*7919),nil,0,nil)end
function S.Event(index)
 local block=math.floor(index/C.ScheduleBlock)
 if not cache[block]then
  local random=Random.new(C.Seed+block*7919);local rows={};local previous;local streak=0;local nextFirst=first(block+1).Id
  for i=0,C.ScheduleBlock-1 do
   local def=pick(random,previous,streak,i==C.ScheduleBlock-1 and nextFirst or nil);rows[i]=def.Id;previous=def.Id
   streak=def.Rarity=='Rare'and 0 or streak+1
  end
  cache={[block]=rows}
 end
 return cache[block][index%C.ScheduleBlock]
end
function S.At(now)
 local period=S.Period();local index=math.floor((now-C.Epoch)/period);local start=C.Epoch+index*period;local t=now-start
 local active=start+C.NormalInterval+C.WarningDuration;local finish=active+C.EventDuration
 local state=t<C.NormalInterval and 'NORMAL'or t<C.NormalInterval+C.WarningDuration and 'WARNING'or now<finish and 'ACTIVE'or 'ENDING'
 local endTime=state=='NORMAL'and start+C.NormalInterval or state=='WARNING'and active or state=='ACTIVE'and finish or start+period
 return {State=state,EventId=S.Event(index),Cycle=index,StartTimestamp=active,EndTimestamp=endTime,NextEventTimestamp=active,ActiveEndTimestamp=finish}
end
return S

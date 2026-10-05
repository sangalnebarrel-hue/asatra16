-- Pure integer allocation. The displayed percentages and the server draw use
-- these exact slots; progression can never increase the fixed ultra rare reward chance.
local O={}
local function integer(n)return type(n)=='number'and n==n and n%1==0 and n>=0 and n<math.huge end
function O.Build(source,denominator)
 denominator=denominator or 10000
 assert(integer(denominator)and denominator>0,'Invalid reward machine denominator')
 local rows,weighted,totalWeight,fixed={}, {},0,0
 for index,row in ipairs(source)do
  local copy=table.clone(row);copy.PrizeIndex=copy.PrizeIndex or index
  local units=row.FixedUnits
  if units~=nil then
   assert(integer(units),'Invalid fixed reward machine odds')
   fixed+=units;copy.ChanceUnits=units
  else
   assert(type(row.Weight)=='number'and row.Weight==row.Weight and row.Weight>=0 and row.Weight<math.huge,'Invalid reward machine weight')
   totalWeight+=row.Weight;table.insert(weighted,copy)
  end
  table.insert(rows,copy)
 end
 assert(fixed<=denominator,'Fixed reward chances exceed 100%')
 local remaining=denominator-fixed
 assert(remaining==0 or totalWeight>0,'Missing ordinary machine rewards')
 local assigned=0
 for _,row in ipairs(weighted)do
  local exact=remaining==0 and 0 or remaining*row.Weight/totalWeight
  row.ChanceUnits=math.floor(exact);row.Remainder=exact-row.ChanceUnits
  assigned+=row.ChanceUnits
 end
 table.sort(weighted,function(a,b)
  if a.Remainder==b.Remainder then return a.PrizeIndex<b.PrizeIndex end
  return a.Remainder>b.Remainder
 end)
 for index=1,remaining-assigned do weighted[index].ChanceUnits+=1 end
 local sum=0
 for _,row in ipairs(rows)do
  row.Remainder=nil;row.Chance=row.ChanceUnits/denominator;row.OddsDenominator=denominator
  row.ChanceText=string.format('%.2f%%',row.Chance*100)
  sum+=row.ChanceUnits
 end
 assert(sum==denominator,'Reward chances do not sum to 100%')
 return rows,denominator
end
function O.Pick(rows,slot,denominator)
 assert(integer(slot)and slot>=1 and slot<=(denominator or 10000),'Invalid reward machine draw')
 local ceiling=0
 for _,row in ipairs(rows)do
  ceiling+=row.ChanceUnits
  if slot<=ceiling then return row end
 end
 error('Reward machine draw has no outcome')
end
return O

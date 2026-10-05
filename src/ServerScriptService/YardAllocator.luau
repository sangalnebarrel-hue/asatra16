-- Pure allocation logic; Claim is idempotent and never yields.
local Allocator={}
function Allocator.new(order)
 local self={owners={},byUser={},order=table.clone(order)}
 function self:Claim(userId)
  if self.byUser[userId] then return self.byUser[userId] end
  for _,id in self.order do
   if self.owners[id]==nil then self.owners[id]=userId;self.byUser[userId]=id;return id end
  end
  return nil
 end
 function self:Release(userId)
  local id=self.byUser[userId]
  if id then self.owners[id]=nil;self.byUser[userId]=nil end
  return id
 end
 return self
end
return Allocator


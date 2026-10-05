-- Roblox DataStore keys are limited to 50 bytes. Short existing keys keep their
-- exact addresses; longer logical keys use a deterministic SHA-256 address.
-- __LogicalKey is storage metadata only and never reaches Transactions/Value.
local S={MaximumLength=50,MetadataKey='__LogicalKey'}
local MOD=4294967296
local band,bxor,bnot,rshift,rotate=bit32.band,bit32.bxor,bit32.bnot,bit32.rshift,bit32.rrotate
local K={
 0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
 0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
 0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
 0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
 0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
 0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
 0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
 0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2,
}
local function u32(value)
 return string.char(band(rshift(value,24),255),band(rshift(value,16),255),band(rshift(value,8),255),band(value,255))
end
function S.SHA256(message)
 assert(type(message)=='string','SHA256 expects a string')
 local bits=#message*8
 local data=message..string.char(128)..string.rep('\0',(55-#message)%64)..u32(math.floor(bits/MOD))..u32(bits%MOD)
 local h={0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19}
 local w=table.create(64)
 for start=1,#data,64 do
  for i=1,16 do
   local a,b,c,d=string.byte(data,start+(i-1)*4,start+(i-1)*4+3)
   w[i]=a*16777216+b*65536+c*256+d
  end
  for i=17,64 do
   local x,y=w[i-15],w[i-2]
   local s0=bxor(rotate(x,7),rotate(x,18),rshift(x,3))
   local s1=bxor(rotate(y,17),rotate(y,19),rshift(y,10))
   w[i]=(w[i-16]+s0+w[i-7]+s1)%MOD
  end
  local a,b,c,d,e,f,g,hh=table.unpack(h)
  for i=1,64 do
   local s1=bxor(rotate(e,6),rotate(e,11),rotate(e,25))
   local choose=bxor(band(e,f),band(bnot(e),g))
   local t1=(hh+s1+choose+K[i]+w[i])%MOD
   local s0=bxor(rotate(a,2),rotate(a,13),rotate(a,22))
   local majority=bxor(band(a,b),band(a,c),band(b,c))
   local t2=(s0+majority)%MOD
   hh,g,f,e,d,c,b,a=g,f,e,(d+t1)%MOD,c,b,a,(t1+t2)%MOD
  end
  h[1]=(h[1]+a)%MOD;h[2]=(h[2]+b)%MOD;h[3]=(h[3]+c)%MOD;h[4]=(h[4]+d)%MOD
  h[5]=(h[5]+e)%MOD;h[6]=(h[6]+f)%MOD;h[7]=(h[7]+g)%MOD;h[8]=(h[8]+hh)%MOD
 end
 local hex=table.create(8)
 for i=1,8 do hex[i]=string.format('%08x',h[i])end
 return table.concat(hex)
end
local function validate(key)
 assert(type(key)=='string'and #key>0,'DataStore logical key must be a nonempty string')
end
function S.Encode(key)
 validate(key)
 if #key<=S.MaximumLength then return key end
 return 'h:'..S.SHA256(key):sub(1,48)
end
function S.Decode(key,raw)
 validate(key)
 if raw==nil then return nil end
 assert(type(raw)=='table','DataStore record must be a table')
 local marker=raw[S.MetadataKey]
 if marker~=nil then
  assert(marker==key,'DataStore key collision: logical identity mismatch')
 else
  -- An existing unmarked short-key record is a valid legacy address. Never let
  -- a long key claim that address merely because its digest happens to match.
  assert(#key<=S.MaximumLength,'DataStore hashed address contains an unmarked record')
 end
 local result=table.clone(raw);result[S.MetadataKey]=nil
 return result
end
function S.GuardedUpdate(key,raw,transform,...)
 local value=S.Decode(key,raw)
 local nextValue,userIds,metadata=transform(value,...)
 if nextValue==nil then return nil end -- Preserve UpdateAsync cancellation.
 assert(type(nextValue)=='table','DataStore record must be a table')
 assert(nextValue[S.MetadataKey]==nil,'Reserved DataStore metadata field')
 local stored=table.clone(nextValue);stored[S.MetadataKey]=key
 return stored,userIds,metadata
end
function S.Wrap(store)
 assert(store~=nil,'Missing native DataStore')
 local wrapped={}
 function wrapped:GetAsync(key,...)
  local raw,info=store:GetAsync(S.Encode(key),...)
  return S.Decode(key,raw),info
 end
 function wrapped:UpdateAsync(key,transform,...)
  assert(type(transform)=='function','Missing DataStore transform')
  local raw,info=store:UpdateAsync(S.Encode(key),function(value,...)
   return S.GuardedUpdate(key,value,transform,...)
  end,...)
  return S.Decode(key,raw),info
 end
 return wrapped
end
return S

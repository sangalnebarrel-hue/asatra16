local P={}
function P.Number(value)
 if type(value)~='number'or value~=value or value==math.huge then return '—'end
 local s=string.format('%.0f',math.floor(value)):reverse():gsub('(%d%d%d)','%1,'):reverse()
 return s:gsub('^,','')
end
function P.Coins(n)return P.Number(n)..' COINS'end
function P.Robux(n)return P.Number(n)..' ROBUX'end
function P.Tickets(n)return P.Number(n)..(n==1 and' DOG TOKEN'or' DOG TOKENS')end
function P.Clock(seconds)
 local n=math.max(0,math.ceil(seconds));local h=math.floor(n/3600)
 if h>0 then return string.format('%02d:%02d:%02d',h,math.floor(n/60)%60,n%60)end
 return string.format('%02d:%02d',math.floor(n/60),n%60)
end
return P

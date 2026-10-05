local C=require(game.ReplicatedStorage.LabConfig)
local S={}
function S.Normalize(p)
 p.Lab=p.Lab or {};local l=p.Lab
 l.Version=1;l.DNA=l.DNA or {};l.DiscoveredDNA=l.DiscoveredDNA or {};l.Recipes=l.Recipes or {};l.History=l.History or {};l.FirstDiscoveries=l.FirstDiscoveries or {}
 l.Experiments=l.Experiments or 0;l.Tier=l.Tier or 1;l.LastAt=l.LastAt or 0
 for _,v in C.Procedures do if(p.Level or 1)>=v.Level then l.Tier=math.max(l.Tier,v.Tier)end end
 for k,v in l.DNA do if C.DNA[k]and v>0 then l.DiscoveredDNA[k]=true end end
 return l
end
function S.Validate(p)
 local l=S.Normalize(p)
 for k,v in l.DNA do assert(C.DNA[k]and type(v)=='number'and v%1==0 and v>=0 and v<=C.MaxMaterial,'Invalid DNA inventory')end
 assert(type(l.Experiments)=='number'and l.Experiments>=0 and #l.History<=C.MaxHistory,'Invalid lab progress')
end
return S

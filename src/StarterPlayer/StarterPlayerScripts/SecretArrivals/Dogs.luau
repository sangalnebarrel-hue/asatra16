-- One arrival per Secret dog: Dogs/<DogId> returns function(ctx). A module that fails
-- to load is skipped (that dog simply arrives without a cinematic).
local D={}
for _,module in ipairs(script:GetChildren())do
 if module:IsA('ModuleScript')then
  local ok,run=pcall(require,module)
  if ok and type(run)=='function'then D[module.Name]=run
  else warn('SecretArrivals: '..module.Name..' unavailable',run)end
 end
end
return D

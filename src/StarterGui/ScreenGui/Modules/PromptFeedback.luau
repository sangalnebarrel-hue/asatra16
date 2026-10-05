local P={Tokens=setmetatable({},{__mode='k'})}
function P.Show(data)
 if type(data)~='table'or type(data.BlockUid)~='string'or type(data.Text)~='string'then return end
 local map=workspace:FindFirstChild('DOGROTS_District');if not map then return end
 local line=map:FindFirstChild('03_DogLine');local active=line and line:FindFirstChild('ActiveDogs');if not active then return end
 for _,block in ipairs(active:GetChildren())do
  if block:GetAttribute('BlockUid')==data.BlockUid then
   local prompt=block:FindFirstChild('LuckyPrompt',true);if not prompt then return end
   local token=(P.Tokens[prompt]or 0)+1;P.Tokens[prompt]=token;prompt.ActionText=data.Text
   task.delay(1.5,function()if prompt.Parent and P.Tokens[prompt]==token then prompt.ActionText='BUY BLOCK'end end)
   return
  end
 end
end
return P

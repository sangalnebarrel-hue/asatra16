local RS=game:GetService('ReplicatedStorage')
local Players=game:GetService('Players')
local shelter=require(script.Parent.Economy.ShelterService)
local inbox=require(script.Parent.DeveloperInbox)
local hub=workspace:WaitForChild('DOGROTS_District'):WaitForChild('32_WelcomeHub')
local function safe(fn,...)
 local ok,success,result=pcall(fn,...)
 if not ok then return false,tostring(success)end
 return success,result
end
RS.ShelterRequest.OnServerInvoke=function(p,a,b)return safe(shelter.Request,p,a,b)end
RS.CommunityFeedbackRequest.OnServerInvoke=function(p,action,a)
 if not require(script.Parent.Economy.Runtime).Allow(p,1)then return false,'Please wait'end
 local near=require(script.Parent.Economy.YardCommerce).Near(p,hub.DeveloperMailbox.MailboxBody,18)
 if not near then return false,'Visit the developer mailbox first'end
 return safe(inbox.Request,p,action,a)
end
hub.DogShelter.SellAnchor.ShelterPrompt.Triggered:Connect(function(p)
 local ok=pcall(shelter.Visit,p);if ok then RS.CommunityOpen:FireClient(p,'Shelter')end
end)
hub.DeveloperMailbox.MailboxBody.FeedbackPrompt.Triggered:Connect(function(p)
 if require(script.Parent.Economy.YardCommerce).Near(p,hub.DeveloperMailbox.MailboxBody,18)then RS.CommunityOpen:FireClient(p,'Feedback')end
end)
Players.PlayerRemoving:Connect(function(p)shelter.Quotes[p.UserId]=nil end)
print('DOGROTS_COMMUNITY_SERVICES_READY')

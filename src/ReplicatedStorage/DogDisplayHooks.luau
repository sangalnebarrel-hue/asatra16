-- Every place that builds a dog model calls Prepared(model, dogId, venue) once the model
-- is sized and placed, before it is parented. Venues: Line, Kennel, Showcase, BestFinds,
-- Reveal, Machine, Static (built into the place), Museum (client), Preview (UI viewport).
-- A Secret gets the DOGROTS_SecretDog tag (SecretAuras dresses every tagged model) and
-- its venue in DisplayVenue; a Long Dog is stretched by LongDogBody.
local RS=game:GetService('ReplicatedStorage')
local CS=game:GetService('CollectionService')
local Definitions=require(RS.DogEconomy.DogDefinitions)
local M={}
M.SecretTag='DOGROTS_SecretDog'
function M.IsSecret(dogId)local def=dogId and Definitions[dogId];return def~=nil and def.Rank==6 end
function M.Prepared(model,dogId,venue)
 if not model or not dogId then return end
 if model:GetAttribute('DogId')==nil then model:SetAttribute('DogId',dogId)end
 if venue~='Preview'and M.IsSecret(dogId)then
  model:SetAttribute('DisplayVenue',venue or 'Unknown');CS:AddTag(model,M.SecretTag)
 end
 if dogId=='LongDog'then
  local ok,err=pcall(function()require(RS.LongDogBody).Apply(model,venue)end)
  if not ok then warn('[LongDogBody]',err)end
 end
end
return M

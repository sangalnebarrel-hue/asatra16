local S={}
function S.Marker(slot)
 local ground=slot:FindFirstChild('DarkExcavation',true)
 if not ground or not ground:IsA('BasePart')then return end
 local marker=ground:FindFirstChild('LootSpawn')
 if not marker then marker=Instance.new('Attachment');marker.Name='LootSpawn';marker.Parent=ground end
 if not marker:IsA('Attachment')then return end
 marker.Position=Vector3.new(0,ground.Size.Y/2+.12,0)
 return marker
end
function S.Resolve(player,p,item)
 if item.OwnerUserId~=player.UserId or item.OriginalFinderUserId~=player.UserId then return end
 local uid=item.SourceDogUid or(type(item.ItemUid)=='string'and item.ItemUid:match('^([^:]+):%d+:%d+$'))
 local dog=uid and p.Dogs[uid]
 if not dog or dog.OwnerUserId~=player.UserId or type(dog.AssignedSlot)~='string'or not dog.AssignedSlot:match('^DigSlot_[1-5]$')then return end
 local yard=require(script.Parent.YardCommerce).Yard(player)
 local slot=yard and yard:FindFirstChild(dog.AssignedSlot)
 if not slot or slot:GetAttribute('Unlocked')==false then return end
 local marker=S.Marker(slot);if not marker then return end
 return {CFrame=marker.WorldCFrame,DogUid=uid,Slot=dog.AssignedSlot,YardId=yard:GetAttribute('YardId'),OwnerUserId=player.UserId}
end
return S

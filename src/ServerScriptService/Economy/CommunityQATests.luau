local S=require(script.Parent.ShelterRules)
local T={}
function T.Run()
 local p={UserId=1,Dogs={a={DogUid='a',OwnerUserId=1,DogId='A',State='Inventory',AssignedSlot=''}},DisplayDogs={},Listings={},Reservations={}}
 local count=0
 local function check(value,message)assert(value,message);count+=1 end
 check(S.Eligible(p,'a'),'inventory dog eligible')
 check(not S.Eligible(p,'missing'),'missing rejected')
 check(not S.Eligible(p,'a',true),'trade rejected')
 local d=p.Dogs.a;d.Locked=true;check(not S.Eligible(p,'a'),'lock protected');d.Locked=false
 d.State='Walking';check(not S.Eligible(p,'a'),'delivery protected');d.State='Inventory'
 d.AssignedSlot='DigSlot_1';check(not S.Eligible(p,'a'),'kennel protected');d.AssignedSlot=''
 p.DisplayDogs['1']='a';check(not S.Eligible(p,'a'),'display protected');p.DisplayDogs={}
 p.Listings.a={};check(not S.Eligible(p,'a'),'listing protected');p.Listings={}
 p.Reservations.a=true;check(not S.Eligible(p,'a'),'reservation protected');p.Reservations={}
 d.OwnerUserId=2;check(not S.Eligible(p,'a'),'ownership protected');d.OwnerUserId=1
 d.PricePaid=999999999;check(S.Price(d,{A={BasePrice=100}},function()return 1 end)==25,'server catalog price')
 local motion=require(game.ReplicatedStorage.RewardMachineMotion)
 for index=1,motion.PrizeCount do
  local angle=motion.Target(index)
  check(math.abs(math.sin(angle+(index-1)*2*math.pi/motion.PrizeCount))<.00001,'drum stops at reward')
 end
 return 'COMMUNITY_QA_OK '..count..' checks'
end
return T

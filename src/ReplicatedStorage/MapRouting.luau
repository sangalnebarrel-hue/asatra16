local map=workspace:WaitForChild('DOGROTS_District')
local nav=map:WaitForChild('NavigationAnchors')
local Routing={}
Routing.Locations={
 {Key='Shelter',Name='Dog Shelter',Detail='Sell extra dogs and find them a new home'},
 {Key='Feedback',Name='Developer mailbox',Detail='Send ideas and wishes to the developers'},
 {Key='DogLine',Name='THE DOG',Detail='Follow the tongue to find your next dog'},
 {Key='PlayerYards',Name='Your yard',Detail='Your dogs, digging and workshop'},
 {Key='WelcomeHub',Name='Welcome plaza',Detail='Arrival, community and DOG EXPRESS'},
 {Key='DogDex',Name='DogDex museum',Detail='100 good boys to discover'},
 {Key='MutationLab',Name='Mutation lab',Detail='Variants, ascension and research'},
 {Key='GlobalDigSite',Name='Paradise Lagoon',Detail='SKY TOWER obby, water slide and zipline'},
 {Key='PawPier',Name='Paw Pier',Detail='Ferris wheel, boats and night fireworks'},
 {Key='RewardMachine',Name='DOG-O-MATIC PLAZA',Detail='DOG-O-MATIC rewards and odds'},
 {Key='Shops',Name='Paw market',Detail='Upgrades, cosmetics and supplies'},
 {Key='DogPark',Name='Leaderboard Plaza',Detail='All-time records and the social court'},
 {Key='PortalRuins',Name='Digging layers',Detail='Discover the underground layers'},
 {Key='TheVoid',Name='The Void',Detail='SEALED / FUTURE AREA',Sealed=true},
}
function Routing.Anchor(key)
 local mirror=nav:FindFirstChild(key)
 local ref=mirror and mirror:FindFirstChild('Target')
 return ref and ref.Value or mirror
end
function Routing.Position(key,player)
 if key=='PlayerYards' and player then
  local yards=map:FindFirstChild('04_PlayerYards')
  if yards then for _,yard in yards:GetChildren() do if yard:GetAttribute('YardId')==player:GetAttribute('YardId') then
   local p=yard:FindFirstChild('YardSpawn');if p then return p.Position end
  end end end
 end
 local a=Routing.Anchor(key);return a and a.Position
end
function Routing.Bounds()
 local low,high=Vector3.new(math.huge,0,math.huge),Vector3.new(-math.huge,0,-math.huge)
 for _,loc in Routing.Locations do local p=Routing.Position(loc.Key);if p then low=low:Min(p);high=high:Max(p) end end
 return low-Vector3.new(100,0,100),high+Vector3.new(100,0,100)
end
return Routing

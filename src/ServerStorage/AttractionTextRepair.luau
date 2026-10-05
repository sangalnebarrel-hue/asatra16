local I={}
local rows={
{"Workspace/DOGROTS_District/06_DogDexMuseum/GrandFacade/Identity/Lettering/Text","THE HALL OF GOOD BOYS  /  001-100"},
{"Workspace/DOGROTS_District/06_DogDexMuseum/NavigationAndReception/WingA/Lettering/Text","WING A  /  001-025"},
{"Workspace/DOGROTS_District/06_DogDexMuseum/NavigationAndReception/WingB/Lettering/Text","WING B  /  026-050"},
{"Workspace/DOGROTS_District/06_DogDexMuseum/NavigationAndReception/WingC/Lettering/Text","WING C  /  051-075"},
{"Workspace/DOGROTS_District/06_DogDexMuseum/NavigationAndReception/WingD/Lettering/Text","WING D  /  076-099"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/HonorPavilion/Honor/Supporters/Empty2","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/HonorPavilion/Honor/Supporters/Empty3","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/HonorPavilion/Honor/Supporters/Empty4","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/HonorPavilion/Honor/Supporters/Empty5","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/HonorPavilion/Honor/Supporters/Empty6","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/HonorPavilion/Honor/Supporters/Empty7","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/HonorPavilion/Honor/Supporters/Empty8","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/HonorPavilion/Honor/Supporters/Empty9","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/HonorPavilion/Honor/Supporters/Empty10","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/HonorPavilion/Honor/Playtime/Empty2","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/HonorPavilion/Honor/Playtime/Empty3","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/HonorPavilion/Honor/Playtime/Empty4","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/HonorPavilion/Honor/Playtime/Empty5","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/HonorPavilion/Honor/Playtime/Empty6","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/HonorPavilion/Honor/Playtime/Empty7","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/HonorPavilion/Honor/Playtime/Empty8","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/HonorPavilion/Honor/Playtime/Empty9","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/HonorPavilion/Honor/Playtime/Empty10","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/DiscoveryPavilion/Discovery/Coins/Empty2","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/DiscoveryPavilion/Discovery/Coins/Empty3","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/DiscoveryPavilion/Discovery/Coins/Empty4","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/DiscoveryPavilion/Discovery/Coins/Empty5","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/DiscoveryPavilion/Discovery/Coins/Empty6","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/DiscoveryPavilion/Discovery/Coins/Empty7","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/DiscoveryPavilion/Discovery/Coins/Empty8","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/DiscoveryPavilion/Discovery/Coins/Empty9","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/DiscoveryPavilion/Discovery/Coins/Empty10","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/DiscoveryPavilion/Discovery/Discoveries/Empty2","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/DiscoveryPavilion/Discovery/Discoveries/Empty3","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/DiscoveryPavilion/Discovery/Discoveries/Empty4","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/DiscoveryPavilion/Discovery/Discoveries/Empty5","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/DiscoveryPavilion/Discovery/Discoveries/Empty6","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/DiscoveryPavilion/Discovery/Discoveries/Empty7","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/DiscoveryPavilion/Discovery/Discoveries/Empty8","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/DiscoveryPavilion/Discovery/Discoveries/Empty9","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/DiscoveryPavilion/Discovery/Discoveries/Empty10","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/LegacyPavilion/Legacy/GlobalDig/Empty2","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/LegacyPavilion/Legacy/GlobalDig/Empty3","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/LegacyPavilion/Legacy/GlobalDig/Empty4","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/LegacyPavilion/Legacy/GlobalDig/Empty5","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/LegacyPavilion/Legacy/GlobalDig/Empty6","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/LegacyPavilion/Legacy/GlobalDig/Empty7","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/LegacyPavilion/Legacy/GlobalDig/Empty8","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/LegacyPavilion/Legacy/GlobalDig/Empty9","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/LegacyPavilion/Legacy/GlobalDig/Empty10","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/LegacyPavilion/Legacy/Dogs/Empty2","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/LegacyPavilion/Legacy/Dogs/Empty3","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/LegacyPavilion/Legacy/Dogs/Empty4","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/LegacyPavilion/Legacy/Dogs/Empty5","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/LegacyPavilion/Legacy/Dogs/Empty6","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/LegacyPavilion/Legacy/Dogs/Empty7","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/LegacyPavilion/Legacy/Dogs/Empty8","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/LegacyPavilion/Legacy/Dogs/Empty9","-"},
{"Workspace/DOGROTS_District/09_DogPark/LeaderboardPlaza/RecordPavilions/LegacyPavilion/Legacy/Dogs/Empty10","-"},
{"Workspace/DOGROTS_District/08_GlobalDigSite/MainDescent/TerraceGuide/Lettering/Text","01-04  UPPER TERRACE"},
{"Workspace/DOGROTS_District/08_GlobalDigSite/MainDescent/LowerGuide/Lettering/Text","05-08  RELIC FLOOR  >"},
{"Workspace/DOGROTS_District/08_GlobalDigSite/MainDescent/ExitGuide/Lettering/Text","<  EXIT / SURFACE"},
{"Workspace/DOGROTS_District/32_WelcomeHub/CommunityCourt/ServerKingMonument/KingInfo/KingPresentation/Criterion","TOTAL XP / YOUR NEXT CHAPTER"},
{"Workspace/DOGROTS_District/32_WelcomeHub/WelcomePlaza/MailboxNoticeNook/EnvelopePlate/Lettering/Text","MAIL"},
}
function I.Install()
 assert(not game:GetService('RunService'):IsRunning(),'Edit mode required')
 local repaired=0
 for _,row in ipairs(rows)do
  local obj=game
  for name in row[1]:gmatch('[^/]+')do obj=obj and obj:FindFirstChild(name)end
  if obj and obj:IsA('TextLabel')then
   if obj:GetAttribute('AttractionOriginalText')==nil then obj:SetAttribute('AttractionOriginalText',obj.Text)end
   obj.Text=row[2];obj.TextWrapped=false;obj.TextTruncate=Enum.TextTruncate.AtEnd;obj.ClipsDescendants=true;repaired+=1
  end
 end
 for _,obj in ipairs(workspace.DOGROTS_District:GetDescendants())do
  if obj:IsA('TextLabel')or obj:IsA('TextButton')then obj.Font=Enum.Font.FredokaOne;obj.ClipsDescendants=true end
  if obj:IsA('Frame')and obj:FindFirstAncestorWhichIsA('SurfaceGui')then obj.ClipsDescendants=true end
 end
 local rig=workspace.DOGROTS_District['37_AttractionRefresh'].RewardMachineRig
 local config=require(game.ReplicatedStorage.RewardMachineConfig)
 local rewards=require(game.ReplicatedStorage.RewardMachineOdds).Build(config.Rewards,config.OddsDenominator)
 for i,row in ipairs(rewards)do
  local label=rig.StatusBoard.OddsDisplay.Rows:FindFirstChild('Row'..i)
  if label then label.Text=row.Name..'  '..row.ChanceText end
 end
 rig.StatusBoard.OddsDisplay.Status.Size=UDim2.fromScale(.88,.09)
 rig.StatusBoard.OddsDisplay.Status.Text='FULL REWARD POOL / YOUR UNLOCKS SET YOUR EXACT ODDS'
 return {RepairedText=repaired}
end
return I

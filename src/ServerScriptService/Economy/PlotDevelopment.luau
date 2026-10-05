local Players=game:GetService('Players')
local C=require(game.ReplicatedStorage.PlotCatalog)
local A=require(game.ReplicatedStorage.PlotAppearance)
local S={}
function S.Reconcile(player,p)
 local map=workspace:FindFirstChild('DOGROTS_District');local yards=map and map:FindFirstChild('04_PlayerYards');if not yards then return end
 for _,yard in ipairs(yards:GetChildren())do if yard:GetAttribute('OwnerUserId')==player.UserId then
  A.Apply(yard,C.Level(p),p.EquippedPlotSkin or 'Classic')
  require(script.Parent.BestFinds).Reconcile(yard,p)
  player:SetAttribute('UnlockedKennels',C.Slots(p));player:SetAttribute('EquippedPlotSkin',p.EquippedPlotSkin or 'Classic')
  player:SetAttribute('YardStageName',C.Stages[C.Level(p)].Name)
 end end
end
function S.VisitShop(player)
 local shop=workspace.DOGROTS_District['11_Shops'].COSMETICS
 assert(require(script.Parent.ShopInteriorAccess).Eligible(player,shop),'Visit the terminal inside COSMETICS to buy or claim plot skins')
end
function S.Start()
 if S.Started then return end;S.Started=true
 local yards=workspace.DOGROTS_District['04_PlayerYards']
 for _,yard in ipairs(yards:GetChildren())do if yard:GetAttribute('YardId')then
  local function refresh()
   local player=Players:GetPlayerByUserId(yard:GetAttribute('OwnerUserId')or 0)
   local rt=require(script.Parent.Runtime)
   if player and rt.Views[player.UserId]then S.Reconcile(player,rt.Views[player.UserId])else A.Apply(yard,1,'Classic');require(script.Parent.BestFinds).Clear(yard)end
  end
  yard:GetAttributeChangedSignal('OwnerUserId'):Connect(function()task.defer(refresh)end)
  refresh()
 end end
 print('DOGROTS_PLOT_DEVELOPMENT_READY: 9 stages / 13 themed skins')
end
return S

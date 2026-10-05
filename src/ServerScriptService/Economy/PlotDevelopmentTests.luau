local T={}
function T.Run()
 assert(game:GetService('RunService'):IsStudio(),'Studio only')
 local R=require(script.Parent.Rules);local P=require(script.Parent.PlotRules);local C=require(game.ReplicatedStorage.PlotCatalog)
 local total=0;local function test(name,fn)local ok,err=pcall(fn);assert(ok,name..': '..tostring(err));total+=1;print('PLOT_TEST_PASS',name)end
 local function profile()local p=R.Profile(-971,os.time());R.Normalize(p,p.UserId,os.time());return p end
 local function reject(fn)assert(not pcall(fn),'Expected rejection')end
 test('new profile: 300 Cash, one kennel, classic',function()local p=profile();assert(p.Cash==300 and C.Slots(p)==1 and p.PlotSkins.Classic and p.EquippedPlotSkin=='Classic')end)
 test('all nine stages and exact prices',function()local p=profile();p.Cash=1000000;local balance=p.Cash
  for level=1,8 do R.Action(p,'Upgrade',{Kind='Plot'},os.time(),math.random);balance-=C.Cost(level);assert(p.Cash==balance and C.Level(p)==level+1 and C.Slots(p)==math.min(5,level+1))end
  reject(function()R.Action(p,'Upgrade',{Kind='Plot'},os.time(),math.random)end);assert(p.Cash==balance)
 end)
 test('locked slots and malformed input',function()local p=profile();P.Assign(p,'DigSlot_1');for _,slot in ipairs({'DigSlot_2','DigSlot_6','other'})do reject(function()P.Assign(p,slot)end)end;reject(function()P.Assign(p,{})end)end)
 test('insufficient cash cannot buy a skin',function()local p=profile();reject(function()P.Action(p,'BuyPlotSkin',{Id='BoneRain'})end);assert(p.Cash==300 and not p.PlotSkins.BoneRain)end)
 test('buy is permanent and repeated buy is free',function()local p=profile();p.Cash=10000;P.Action(p,'BuyPlotSkin',{Id='BoneRain'});assert(p.Cash==8800 and p.PlotSkins.BoneRain);P.Action(p,'BuyPlotSkin',{Id='BoneRain'});assert(p.Cash==8800);P.Action(p,'EquipPlotSkin',{Id='Classic'});assert(p.EquippedPlotSkin=='Classic'and p.PlotSkins.BoneRain)end)
 test('unowned and unknown skins rejected',function()local p=profile();reject(function()P.Action(p,'EquipPlotSkin',{Id='TheVoid'})end);reject(function()P.Action(p,'BuyPlotSkin',{Id='forged'})end);reject(function()P.Action(p,'BuyPlotSkin',{Id={}})end)end)
 test('event reward requires sighting and contribution',function()local p=profile();reject(function()P.Action(p,'ClaimPlotSkin',{Id='CrystalStorm'})end);p.WorldEventsSeen={CRYSTAL_STORM={FirstSeen=1}};reject(function()P.Action(p,'ClaimPlotSkin',{Id='CrystalStorm'})end);p.Lifetime.GlobalDigContribution=250;P.Action(p,'ClaimPlotSkin',{Id='CrystalStorm'});assert(p.Cash==300 and p.PlotSkins.CrystalStorm)end)
 test('secret skins cannot be purchased',function()local p=profile();p.Cash=10000000;reject(function()P.Action(p,'BuyPlotSkin',{Id='TheVoid'})end);reject(function()P.Action(p,'BuyPlotSkin',{Id='NullHour'})end)end)
 test('Void obtainable without disabled world event',function()local p=profile();p.Upgrades.Plot=8;p.Prestige=1;p.UnlockedLayers['5']=true;p.Lifetime.GlobalDigContribution=3000;P.Action(p,'ClaimPlotSkin',{Id='TheVoid'});assert(p.PlotSkins.TheVoid)end)
 test('legacy assignments and cosmetics migrate',function()local p=profile();p.PlotProgressionVersion=nil;p.Dogs={old={AssignedSlot='DigSlot_5'}};p.Cosmetics.GoldenKennel=true;p.EquippedCosmetic='GoldenKennel';P.Normalize(p);assert(C.Slots(p)==5 and p.PlotSkins.GoldenHour and p.EquippedPlotSkin=='GoldenHour')end)
 test('transaction receipt prevents double charge',function()
  local Tx=require(script.Parent.Transactions);local store={Data={}}
  function store:Read(k)return R.Copy(self.Data[k])end
  function store:Update(k,fn)self.Data[k]=fn(R.Copy(self.Data[k]));return R.Copy(self.Data[k])end
  local tx=Tx.new(store,os.time,function()return game.HttpService:GenerateGUID(false)end)
  local p=profile();p.Cash=10000;assert(tx:Run({'p:test'},function(v)v['p:test']=p;return true end))
  local function buy(v)P.Action(v['p:test'],'BuyPlotSkin',{Id='BoneRain'});return true end
  assert(tx:Run({'p:test'},buy,'plot-idempotency-test'));assert(tx:Run({'p:test'},buy,'plot-idempotency-test'));assert(tx:Read('p:test').Cash==8800)
 end)
 test('all skins render, reset and do not duplicate',function()
  local A=require(game.ReplicatedStorage.PlotAppearance);local yards=workspace.DOGROTS_District['04_PlayerYards'];local source
  for _,y in ipairs(yards:GetChildren())do if y:GetAttribute('YardId')then source=y;break end end
  local clone=source:Clone();clone.Parent=nil
  for _,id in ipairs(C.Order)do A.Apply(clone,9,id);local n=#clone.PlotDevelopment:GetDescendants();assert(n>50 and n<1800);A.Apply(clone,9,id);assert(#clone.PlotDevelopment:GetDescendants()==n)end
  A.Apply(clone,1,'Classic');assert(clone.DigSlot_1.KennelFloor.Transparency<1 and clone.DigSlot_2.KennelFloor.Transparency==1 and not clone.DigSlot_2.KennelFloor.CanCollide)
  A.Apply(clone,5,'Classic');assert(clone.DigSlot_5.KennelFloor.Transparency<1);clone:Destroy()
 end)
 print('PLOT_TESTS_COMPLETE',total,'PASS');return total
end
return T

-- Real generation, inventory, binding and lifecycle; native gravity is a boundary double.
local env=dofile('tools/test_equipment_economy_runtime.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local E,R=LOD.Equipment,env.Run
MOVETYPE_WALK=2
R.State.BuildReady=true;R.State.Graph={}
dofile(root..'sv_equipment_moves.lua')
dofile(root..'sv_equipment_gravity.lua')
local p=env.actor('moon')
p.ps.equipmentLifeSerial=1;p.ps.deploymentComplete=true
function p:GetGravity() return self.gravity or 0 end
function p:SetGravity(v) self.gravity=v;self.gravityWrites=(self.gravityWrites or 0)+1 end
function p:GetMoveType() return self.moveType or MOVETYPE_WALK end
function p:InVehicle() return self.vehicle or false end
local state=E:Ensure(p.ps)
local item=E:NewItem(p,'moon_boots','proof')
assert(E:ValidateWearable(item) and item.rarity>=2 and E:InnateValue('moon_boots',100)==50)
assert(E:Description(item):find('25%% lower gravity') and E:Description(item):find('passive',1,true))
local forged=table.Copy(item);forged.version=1;assert(not E:ValidateWearable(forged))
local seen={}
for seed=1,400 do
 local g=E:Generate(seed,seed,'moon_boots','moon:'..seed)
 assert(E:ValidateWearable(g) and E:Value(g)==g.budget)
 seen[E:RewardWearableFamily(seed) or 'generic']=true
end
assert(seen.moon_boots and seen.plumber_boots and seen.tanuki_ring and seen.generic)
for _,id in ipairs(E.MoveOrder) do assert(id~='moon_gravity','Passive cannot enter the combo dispatcher') end
E:UpdateEquipmentGravity(p);assert(p:GetGravity()==0 and not E.GravitySources[p])
assert(E:AcquireWearable(state,item,false))
E:UnequipItem(state,item.id);E:UpdateEquipmentGravity(p)
assert(p:GetGravity()==0,'Stored ownership alone grants no gravity')
assert(not E:Equip(state,item.id,'head'))
assert(E:Equip(state,item.id,'feet'))
p.ps.magic=37
E:RefreshDerived(p,p.ps)
assert(p:GetGravity()==.75 and E.GravitySources[p] and p.ps.magic==37)
local old=E.GravitySources[p];local writes=p.gravityWrites
for _=1,100 do E:UpdateEquipmentGravity(p) end
assert(p:GetGravity()==.75 and p.gravityWrites==writes and p.ps.magic==37,'No per-sample compounding or spending')
E:Unequip(state,'feet');assert(p:GetGravity()==0 and not E.GravitySources[p])
-- An old cleanup must not affect a new passive binding, including same-tick re-equip.
E:Equip(state,item.id,'feet');E:UpdateEquipmentGravity(p)
assert(not E:EndEquipmentGravity(p,old) and p:GetGravity()==.75)
E:ClearTransient(p);assert(p:GetGravity()==0)
p.gravity=1.6;E:UpdateEquipmentGravity(p)
assert(math.abs(p:GetGravity()-1.2)<1e-8)
p.gravity=.4;E:UpdateEquipmentGravity(p)
assert(math.abs(p:GetGravity()-.3)<1e-8)
E:UnequipItem(state,item.id);assert(p:GetGravity()==.4,'Restore latest external baseline')
E:Equip(state,item.id,'feet');E:UpdateEquipmentGravity(p)
p.gravity=.9;E:Unequip(state,'feet')
assert(p:GetGravity()==.9,'Cleanup must not overwrite a newer native writer')
-- Real inventory replacement retires the old record before a new effect can bind.
local other=E:NewItem(p,'moon_boots','second');assert(E:AcquireWearable(state,other,false))
E:Equip(state,item.id,'feet');E:UpdateEquipmentGravity(p);old=E.GravitySources[p]
E:Equip(state,other.id,'feet');assert(p:GetGravity()==.9 and not E.GravitySources[p])
E:UpdateEquipmentGravity(p);assert(E.GravitySources[p].moveBinding.source==other)
assert(not E:MoveAttackValid(p,old) and not E:EndEquipmentGravity(p,old))
E:Unequip(state,'feet');p.gravity=0;E:Equip(state,item.id,'feet')
-- State-bound rejection is real even with a fully owned/equipped source.
for _,case in ipairs({
 {p,'soldier',true},{p,'active',false},{p,'hp',0},{p,'moveType',8},{p,'vehicle',true},
 {R.State,'BuildReady',false},{R.State,'SimulationFrozen',true},{R.State,'Failed',true},
 {R.State,'LevelCleared',true},{R.State,'Graph',nil}
}) do
 E:UpdateEquipmentGravity(p);assert(p:GetGravity()==.75)
 local obj,key,value=case[1],case[2],case[3];local prior=obj[key];obj[key]=value
 E:UpdateEquipmentGravity(p);assert(p:GetGravity()==0 and not E.GravitySources[p],key)
 obj[key]=prior
end
-- A fresh valid update may rebind, but the old source token never becomes valid again.
for _,mutate in ipairs({
 function() p.ps.identity='moon-new' end,
 function() p.ps.equipmentLifeSerial=p.ps.equipmentLifeSerial+1 end,
 function() R.State.LevelSeed=R.State.LevelSeed+1 end,
 function() R.State.Graph={} end,
 function() local n={};for k,v in pairs(R.State) do n[k]=v end;R.State=n end,
 function() local n={};for k,v in pairs(p.ps) do n[k]=v end;p.ps=n end,
 function() local n={items=state.items,slots=state.slots};p.ps.equipment=n;state=n end
}) do
 E:UpdateEquipmentGravity(p);old=E.GravitySources[p];assert(old)
 mutate();assert(not E:MoveAttackValid(p,old))
 E:UpdateEquipmentGravity(p)
 assert(E.GravitySources[p]~=old and p:GetGravity()==.75)
 assert(not E:EndEquipmentGravity(p,old),'Stale callback may not end replacement')
end
local owned=state.items[item.id];state.items[item.id]=nil
E:UpdateEquipmentGravity(p);assert(p:GetGravity()==0 and not E.GravitySources[p])
state.items[item.id]=owned;E:UpdateEquipmentGravity(p)
env.hooks.LOD_EquipmentGravityCleanup();assert(p:GetGravity()==0)
E:UpdateEquipmentGravity(p);p.hp=0;env.hooks.LOD_EquipmentDeath(p)
assert(p:GetGravity()==0 and not E.GravitySources[p]);p.hp=100
E:UpdateEquipmentGravity(p);env.hooks.LOD_EquipmentDisconnect(p)
assert(p:GetGravity()==0 and not E.GravitySources[p])
-- No Magic, impulse, teleport, jump or invulnerability authority is introduced.
assert(p.ps.magic==37)
local file=assert(io.open(root..'sv_rpg_gate_d.lua'));local source=file:read('*a');file:close()
assert(source:find('LOD.Equipment:UpdateEquipmentGravity(ply)',1,true),'Production SetupMove wiring')
print('MOON_BOOTS_PASS: real generator/ownership/passive grant; native gravity composition and restoration; exact source/life/role/run/graph invalidation; stale cleanup; no Magic spend')

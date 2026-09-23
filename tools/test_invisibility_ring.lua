-- Production combo, equipment, perception/faction and lifecycle; Source boundaries only.
local env=dofile('tools/test_equipment_economy_runtime.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local E,R,P=LOD.Equipment,env.Run,LOD.RPGPerceptionState
local now=200;CurTime=function() return now end
local p,ally,enemy=env.actor('veil'),env.actor('ally'),env.actor('hostile',true)
R.State.Graph={};R.State.PlayerState.veil=p.ps
p.ps.equipmentLifeSerial=1
LOD.Magic._EnsureState=function(_,actor) return actor.ps end
LOD.Magic._Sync=function() end
net.WriteEntity=function() end;net.WriteString=function() end;net.Broadcast=function() end
player.GetAll=function() return {p,ally} end
player.GetHumans=player.GetAll
LOD.HostileRegistry={List=function() return {enemy} end}
LOD.MazeNavigator={WorldToCell=function() return {x=1,y=1,z=0} end,Distance=function() return 0 end}
LOD.MagicForms.CastSelected=function() return false end -- failed native cast still reveals the attempt
local nativeUse=E.Use
E.Use=function() return false end
local reports={};E.Report=function(_,_,text) reports[#reports+1]=text end
dofile(root..'sv_faction_manager.lua')
dofile(root..'sv_equipment_moves.lua')
dofile(root..'sv_equipment_invisibility.lua')
local F=LOD.FactionManager
local item=E:NewItem(p,'invisibility_ring','test')
local state=E:Ensure(p.ps)
assert(item.rarity>=2 and E:ValidateWearable(item) and E:Value(item)==item.budget)
assert(E:InnateValue('invisibility_ring',100)==50)
assert(E:Description(item):find('← ↑ ←',1,true))
local found=false
for seed=1,300 do if E:RewardWearableFamily(seed)=='invisibility_ring' then found=true end end
assert(found,'natural rewards must include the ring')
local function combo()
 local ok
 for _,token in ipairs(E.SpecialMoves.veil.recipe) do now=now+.1;ok=E:DirectionToken(p,token) end
 return ok
end
assert(not combo() and p.ps.magic==100,'unowned recipe is free')
assert(E:AcquireWearable(state,item,false,'left_hand'))
assert(E:Equipped(state,'left_hand')==item and not E:Equipped(state,'right_hand'))
p.ps.magic=19;assert(not combo() and p.ps.magic==19)
p.ps.magic=100
local oldCan=LOD.RPGStatusElements.CanInitiateMagic
LOD.RPGStatusElements.CanInitiateMagic=function() return false end
assert(not combo() and p.ps.magic==100)
LOD.RPGStatusElements.CanInitiateMagic=oldCan
enemy.LODTarget=p;enemy.LODWaypoints={1,2}
assert(combo() and p.ps.magic==80)
local first=E.Cloaks[p];local deadline=first.ends
assert(P:IsInvisible(p) and not F:CanAcquirePlayerTarget(p))
assert(F:IsValidPlayerTarget(p) and F:IsOpponent(enemy,p),'concealment must not change damage faction')
assert(F:BestTarget(enemy,R.State.Graph,{})==ally,'AI picks a visible alternative')
assert(enemy.LODTarget==nil and #enemy.LODWaypoints==0)
assert(p:GetNW2Float('LOD_VeilUntil',0)==deadline)
assert(not combo() and p.ps.magic==80 and E.Cloaks[p]==first,'no refresh/debit')
assert(not P:ClearInvisibleSource(p,'equipment_veil',{}),'stale source cannot clear')
local function activate()
 E:EndCloak(p,'test reset');now=now+21;p.ps.magic=100
 assert(combo());assert(P:IsInvisible(p));return E.Cloaks[p]
end
local function command(primary,secondary)
 env.hooks.LOD_VeilAttackInput(p,{KeyDown=function(_,key) return key==IN_ATTACK and primary or key==IN_ATTACK2 and secondary end})
end
IN_ATTACK,IN_ATTACK2=1,2
command(false,false);assert(P:IsInvisible(p),'movement alone retains cloak')
command(true,false);assert(not P:IsInvisible(p) and p.ps.magic==80)
assert(not combo() and p.ps.magic==80,'reveal does not reset cooldown')
activate();command(false,true);assert(not P:IsInvisible(p))
activate();LOD.MagicForms:CastSelected(p,'mouse5');assert(not P:IsInvisible(p),'auxiliary failed cast reveals')
activate();E:Use(p,'throw');assert(not P:IsInvisible(p))
activate();E:Use(p,'drink');assert(P:IsInvisible(p))
local function damage(victim,attacker,amount,took)
 env.hooks.LOD_VeilDamage(victim,{GetDamage=function() return amount end,GetAttacker=function() return attacker end},took)
end
damage(p,enemy,0,true);assert(P:IsInvisible(p))
damage(p,enemy,10,false);assert(P:IsInvisible(p))
damage(p,enemy,1,true);assert(not P:IsInvisible(p),'effective incoming hit reveals')
activate();damage(enemy,p,1,true);assert(not P:IsInvisible(p),'effective outgoing hit reveals')
activate();P:SetInvisible(p,true);E:EndCloak(p,'attack');assert(P:IsInvisible(p),'other source survives');P:SetInvisible(p,false)
activate();now=E.Cloaks[p].ends;P:MaintainInvisibleSources(p,now)
assert(not P:IsInvisible(p) and not E.Cloaks[p] and p:GetNW2Float('LOD_VeilUntil',-1)==0)
activate();E:Unequip(state,'left_hand');assert(not P:IsInvisible(p))
E:Equip(state,item.id,'left_hand');activate();E:Equip(state,item.id,'right_hand');assert(not P:IsInvisible(p),'moving source slot ends activation')
local stale=activate();E:EndCloak(p,'test');local fresh=activate()
stale.ended(p,stale,'stale callback');assert(E.Cloaks[p]==fresh and P:IsInvisible(p))
local scenarios={
 {function() p.ps.equipmentLifeSerial=2 end,function() p.ps.equipmentLifeSerial=1 end},
 {function() p.soldier=true end,function() p.soldier=false end},
 {function() p.active=false end,function() p.active=true end},
 {function() p.hp=0 end,function() p.hp=100 end},
 {function() R.State.LevelSeed=8 end,function() R.State.LevelSeed=7 end},
 {function() R.State.Graph={} end,function() end},
 {function() R.State.Failed=true end,function() R.State.Failed=false end},
 {function() R.State.LevelCleared=true end,function() R.State.LevelCleared=false end},
 {function() R.State.SimulationFrozen=true end,function() R.State.SimulationFrozen=false end},
 {function() p.ps.identity='other' end,function() p.ps.identity='veil' end},
 {function() state.items[item.id]=table.Copy(item) end,function() state.items[item.id]=item end},
}
for _,scenario in ipairs(scenarios) do
 activate();scenario[1]();assert(not P:IsInvisible(p) and not E.Cloaks[p]);scenario[2]()
end
activate();local session=E:MoveSession(p);local run=R.State;R.State=table.Copy(run)
assert(not P:IsInvisible(p) and not E:ExecuteMove(p,'veil',session));R.State=run
activate();local ps=p.ps;p.ps=table.Copy(ps);assert(not P:IsInvisible(p));p.ps=ps
activate();env.hooks.LOD_EquipmentDeath(p);assert(not P:IsInvisible(p))
activate();env.hooks.LOD_EquipmentDisconnect(p);assert(not P:IsInvisible(p))
assert(#p.ps.progressionState.featIds==0)
print('INVISIBILITY_RING_PASS: ownership, cost, shared combo/state, targeting vs damage, reveal/expiry, item/life/role/run/graph rejection and source-safe cleanup')

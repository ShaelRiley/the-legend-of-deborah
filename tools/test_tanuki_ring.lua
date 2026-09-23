-- Real equipment, shared status/damage/perception and native movement boundaries.
local env=dofile('tools/test_equipment_economy_runtime.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local E,R,P,S,Rules=LOD.Equipment,env.Run,LOD.RPGPerceptionState,LOD.RPGStatusElements,LOD.RPGAbilityRules
local now=200;CurTime=function() return now end
IN_FORWARD,IN_BACK,IN_MOVELEFT,IN_MOVERIGHT,IN_JUMP,IN_DUCK,IN_ATTACK,IN_ATTACK2,IN_USE=1,2,3,4,5,6,7,8,9
MOVETYPE_WALK=2
local V=getmetatable(Vector())
function V:LengthSqr() return self.x^2+self.y^2+self.z^2 end
local p,ally,enemy=env.actor('tanuki'),env.actor('friend'),env.actor('enemy',true)
p.pos=Vector();p.base=Vector();p.material='original';p.grounded=true;p.mode=MOVETYPE_WALK
function p:GetPos() return self.pos end
function p:GetBaseVelocity() return self.base end
function p:GetMaterial() return self.material end
function p:SetMaterial(v) self.material=v end
function p:OnGround() return self.grounded end
function p:GetMoveType() return self.mode end
function p:InVehicle() return self.vehicle end
function p:GetGroundEntity() return self.ground end
R.State.BuildReady=true;R.State.Graph={};R.State.PlayerState.tanuki=p.ps;p.ps.equipmentLifeSerial=1
LOD.Magic._EnsureState=function(_,actor) return actor.ps end;LOD.Magic._Sync=function() end
player.GetAll=function() return {p,ally} end;player.GetHumans=player.GetAll
LOD.HostileRegistry={List=function() return {enemy} end}
LOD.MazeNavigator={WorldToCell=function() return {x=1,y=1,z=0} end,Distance=function() return 0 end}
LOD.MagicForms.CastSelected=function() return false end
E.Use=function() return false end
local reports,fx,audio=0,0,0
E.Report=function() reports=reports+1 end
EffectData=function() return {SetOrigin=function() end} end
util.Effect=function(name) assert(name=='lod_statue_transform');fx=fx+1 end
LOD.Audio={At=function(_,_,cue) assert(cue=='statue_transform');audio=audio+1 end}
dofile(root..'sv_faction_manager.lua');dofile(root..'sv_equipment_moves.lua')
dofile(root..'sv_equipment_invisibility.lua');dofile(root..'sv_equipment_statue.lua')
local F=LOD.FactionManager
local move={}
function move:GetOrigin() return p.pos end
function move:GetVelocity() return p.velocity end
function move:GetForwardSpeed() return self.forward or 0 end
function move:GetSideSpeed() return 0 end
function move:GetUpSpeed() return 0 end
local function sample(dt) now=now+(dt or .125);E:ObserveStatue(p,move);E:ResolveStatue(p,move) end
local function wait() sample();for _=1,16 do sample() end end
wait();assert(not S:IsStatue(p) and p.ps.magic==100,'unowned stillness grants nothing')
local item=E:NewItem(p,'tanuki_ring','test');local state=E:Ensure(p.ps)
assert(item.rarity>=2 and E:ValidateWearable(item) and E:Value(item)==item.budget)
assert(E:InnateValue('tanuki_ring',100)==50 and E:Description(item):find('2 seconds',1,true))
local reward=false;for seed=1,300 do if E:RewardWearableFamily(seed)=='tanuki_ring' then reward=true end end;assert(reward)
assert(E:AcquireWearable(state,item,false,'left_hand'))
assert(not E:Equipped(state,'right_hand') and E:Equipped(state,'left_hand')==item)
sample();local begun=now
for _=1,15 do sample() end
assert(now-begun==1.875 and not S:IsStatue(p) and not P:IsInvisible(p))
enemy.LODTarget=p;enemy.LODWaypoints={1,2}
sample();assert(now-begun==2 and S:IsStatue(p) and P:IsInvisible(p))
assert(p.ps.magic==100 and p.material=='models/props_wasteland/rockgranite02a' and p:GetNW2Bool('LOD_Statue'))
assert(not F:CanAcquirePlayerTarget(p) and F:IsValidPlayerTarget(p) and F:IsOpponent(enemy,p))
assert(F:BestTarget(enemy,R.State.Graph,{})==ally and not enemy.LODTarget and #enemy.LODWaypoints==0)
assert(audio==1 and fx==1);sample();assert(audio==1 and fx==1,'no repeated transformation')
local function activate()
 E:EndStatue(p,'test');wait();assert(S:IsStatue(p) and P:IsInvisible(p));return E.StatueWaits[p]
end
-- Canonical GM cancellation precedes every defense/resource/status side effect.
assert(GM.EntityTakeDamage,'fixture must load real shared GM damage seam')
local original={};local touched=0
for _,name in ipairs({'ApplyDodge','ApplyBlock','ApplyWisDefense','ApplyPlayerDefense','ApplyNotYetDefense'}) do
 original[name]=Rules[name];Rules[name]=function() touched=touched+1;error('Statue reached defense '..name) end
end
local observe=S.ObserveDamage;S.ObserveDamage=function() error('Statue reached damage status observer') end
local info={damage=40,GetDamage=function(self) return self.damage end,SetDamage=function(self,v) self.damage=v end,
 GetAttacker=function() return enemy end,GetInflictor=function() return enemy end,IsDamageType=function() return false end}
for _,kind in ipairs({'physical','magic','poison','fire','aoe','ambient'}) do
 info.damage=40;S:AttachDamageContext(info,{element=kind,statusDamage=kind=='poison'})
 assert(GM:EntityTakeDamage(p,info)==true and info.damage==0 and p.ps.magic==100 and S:IsStatue(p),kind)
end
for name,fn in pairs(original) do Rules[name]=fn end;S.ObserveDamage=observe
assert(touched==0 and not S:ClearStatue(p,{}),'stale token cannot remove immunity')
-- Remedy removes negatives without curing a positive owned state.
S:Apply(p,'poisoned',enemy,{direct=true,duration=20});local entry=S.Active[p].poisoned
assert(entry and S:IsStatue(p));S:CureNegative(p);assert(not S:Has(p,'poisoned') and S:IsStatue(p))
-- A real scheduled ailment tick enters the native damage seam without curing or pausing it.
DamageInfo=function()
 local hit={}
 for _,name in ipairs({'Attacker','Inflictor','Damage','DamageType','DamagePosition','DamageForce'}) do
  hit['Set'..name]=function(self,v) self[name]=v end
  hit['Get'..name]=function(self) return self[name] end
 end
 return hit
end
local statusHits=0
function p:TakeDamageInfo(hit)
 statusHits=statusHits+1
 if GM:EntityTakeDamage(self,hit)~=true then self.hp=self.hp-hit:GetDamage() end
end
S:Apply(p,'immolated',enemy,{direct=true,duration=20,dc=100})
local burning=S.Active[p].immolated;burning.nextTickAt=now
local expiry=burning.expiresAt
S:_ProcessImmolated(p,burning,now)
assert(statusHits==1 and p.hp==100 and p.ps.magic==100 and S:IsStatue(p))
assert(S.Active[p].immolated==burning and burning.expiresAt==expiry and burning.nextTickAt==now+1)
S:CureNegative(p)
-- Native command input before suppression; no aim angle prohibition.
local function command(key)
 E:ObserveStatueInput(p,{KeyDown=function(_,k) return k==key end,
 GetForwardMove=function() return 0 end,GetSideMove=function() return 0 end,GetUpMove=function() return 0 end})
end
command(nil);assert(S:IsStatue(p))
for _,key in ipairs({IN_FORWARD,IN_BACK,IN_MOVELEFT,IN_MOVERIGHT,IN_JUMP,IN_DUCK,IN_ATTACK,IN_ATTACK2,IN_USE}) do
 activate();command(key);assert(not S:IsStatue(p) and not P:IsInvisible(p) and p.material=='original')
 E:ObserveStatue(p,move);assert(not E.StatueWaits[p],'active input must not start wait in same tick')
end
activate();LOD.MagicForms:CastSelected(p,'mouse5');assert(not S:IsStatue(p))
activate();E:Use(p,'drink');assert(not S:IsStatue(p))
activate();E:ExecuteMove(p,'veil',E:MoveSession(p));assert(not S:IsStatue(p) and p.ps.magic==100)
activate();env.hooks.LOD_StatueOutgoingDamage(enemy,info,false);assert(S:IsStatue(p))
info.damage=1;info.GetAttacker=function() return p end
 env.hooks.LOD_StatueOutgoingDamage(enemy,info,true);assert(not S:IsStatue(p))
-- Forced movement and physical changes reject even before the next movement sample.
local cases={
 {function() p.velocity=Vector(2,0,0) end,function() p.velocity=Vector() end},
 {function() p.base=Vector(0,2,0) end,function() p.base=Vector() end},
 {function() p.pos=Vector(2,0,0) end,function() p.pos=Vector() end},
 {function() p.grounded=false end,function() p.grounded=true end},
 {function() p.mode=8 end,function() p.mode=MOVETYPE_WALK end},
 {function() p.vehicle=true end,function() p.vehicle=false end},
 {function() p.LODForcedMovementUntil=now+1 end,function() p.LODForcedMovementUntil=nil end},
 {function() Rules.VoluntaryDashes[p]={} end,function() Rules.VoluntaryDashes[p]=nil end},
 {function() p.ground=enemy end,function() p.ground=nil end},
 {function() p.ps.equipmentLifeSerial=2 end,function() p.ps.equipmentLifeSerial=1 end},
 {function() p.soldier=true end,function() p.soldier=false end},
 {function() p.active=false end,function() p.active=true end},
 {function() p.hp=0 end,function() p.hp=100 end},
 {function() R.State.LevelSeed=8 end,function() R.State.LevelSeed=7 end},
 {function() R.State.Graph={} end,function() end},
 {function() R.State.BuildReady=false end,function() R.State.BuildReady=true end},
 {function() R.State.Failed=true end,function() R.State.Failed=false end},
 {function() R.State.LevelCleared=true end,function() R.State.LevelCleared=false end},
 {function() R.State.SimulationFrozen=true end,function() R.State.SimulationFrozen=false end},
 {function() p.ps.identity='other' end,function() p.ps.identity='tanuki' end},
 {function() state.items[item.id]=table.Copy(item) end,function() state.items[item.id]=item end},
}
function enemy:IsNPC() return true end
for _,case in ipairs(cases) do
 activate();case[1]();assert(not S:IsStatue(p) and not P:IsInvisible(p));case[2]()
end
activate();now=now+.251;assert(not P:IsInvisible(p) and not S:IsStatue(p),'unobserved time cannot retain immunity')
sample();sample(.251);for _=1,15 do sample() end;assert(not S:IsStatue(p));sample();assert(S:IsStatue(p))
-- Exact slot/source and same-tick remove/re-equip invalidate activation AND wait.
activate();E:Unequip(state,'left_hand');E:Equip(state,item.id,'left_hand');assert(not S:IsStatue(p))
sample();for _=1,8 do sample() end;E:Unequip(state,'left_hand');E:Equip(state,item.id,'left_hand');sample()
for _=1,15 do sample() end;assert(not S:IsStatue(p));sample();assert(S:IsStatue(p))
E:Equip(state,item.id,'right_hand');assert(not S:IsStatue(p))
local stale=activate();local fresh=activate();stale.ended(p,stale,'old callback')
assert(E.StatueWaits[p]==fresh and S:IsStatue(p))
local staleSession=E:MoveSession(p);E.MoveSessions[p]=nil;fresh=activate()
assert(not E:ExecuteMove(p,'veil',staleSession) and E.StatueWaits[p]==fresh and S:IsStatue(p),
 'old technique callback must not cancel a fresh activation')
P:SetInvisible(p,true);E:EndStatue(p,'test');assert(P:IsInvisible(p) and not S:IsStatue(p));P:SetInvisible(p,false)
activate();local other={ends=now+10};P:SetInvisibleSource(p,'other',other);E:EndStatue(p,'test')
assert(P:IsInvisible(p));P:ClearInvisibleSource(p,'other',other)
activate();p.material='new external material';E:EndStatue(p,'test');assert(p.material=='new external material');p.material='original'
activate();S:ResetActorLife(p);assert(not S:IsStatue(p) and not P:IsInvisible(p) and p.material=='original')
activate();env.hooks.LOD_EquipmentDeath(p);assert(not S:IsStatue(p))
activate();env.hooks.LOD_EquipmentDisconnect(p);assert(not S:IsStatue(p))
activate();env.hooks.LOD_StatueCleanup();assert(not S:IsStatue(p))
activate();local run=R.State;R.State=table.Copy(run);assert(not S:IsStatue(p));R.State=run
activate();local ps=p.ps;p.ps=table.Copy(ps);assert(not S:IsStatue(p));p.ps=ps
assert(#p.ps.progressionState.featIds==0 and p.ps.magic==100)
print('TANUKI_PASS: passive ownership/stillness, free activation, canonical damage denial/acquisition, input/physics breaks, source composition/material and lifecycle rejection')

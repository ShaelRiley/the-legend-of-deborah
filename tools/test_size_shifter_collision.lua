-- Actual single-hand ring ownership, interpolation, shared lifecycle and hulls.
local f=dofile('tools/test_equipment_economy_runtime.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local E,R,CPS=LOD.Equipment,LOD.RPGAbilityRules,LOD.CharacterProgressionSystem
local hooks=f.hooks;local clock=0
CurTime=function() return clock end
local V=getmetatable(Vector())
V.__mul=function(v,s) return Vector(v.x*s,v.y*s,v.z*s) end
local function same(a,b) return a and b and a.x==b.x and a.y==b.y and a.z==b.z end
IN_DUCK=4;MASK_PLAYERSOLID=1;COLLISION_GROUP_PLAYER_MOVEMENT=8
local p=f.actor('size-ring');f.Run.State.PlayerState[p.id]=p.ps
f.Run.State.Graph={};f.Run.State.BuildReady=true
p.scale=1;p.crouch=true;p.writes={}
function p:GetClass() return 'player' end
function p:Crouching() return self.crouch end
function p:GetModelScale() return self.scale end
function p:SetPos() error('Size Shifter must never teleport across geometry') end
function p:SetModelScale(s)
 self.scale=s;self.writes[#self.writes+1]=s
 -- Reproduce Source resetting collision bounds when native model scale changes.
 self.high=Vector(16*s,16*s,72*s);self.duckHigh=Vector(16*s,16*s,36*s)
end
function p:SetHull(a,b) self.low,self.high=a,b end
function p:SetHullDuck(a,b) self.duckLow,self.duckHigh=a,b end
local blocked,ceiling,traces=false,math.huge,0
util.TraceHull=function(t)
 traces=traces+1
 assert(t.filter==p and t.mask==MASK_PLAYERSOLID and t.collisiongroup==COLLISION_GROUP_PLAYER_MOVEMENT)
 assert(t.mins.x<=-16 and t.maxs.x>=16,'no subnormal authoritative footprint')
 return {Hit=blocked or t.maxs.z>ceiling,StartSolid=blocked,AllSolid=false}
end
dofile(root..'sh_player_scale_collision.lua')
dofile(root..'sv_equipment_moves.lua')
dofile(root..'sv_equipment_size_shifter.lua')
local C=LOD.PlayerScaleCollision
local function tick(dt) clock=clock+dt;hooks.LOD_EquipmentSizeShifter() end
local function legal()
 assert(same(p.low,Vector(-16,-16,0)) and same(p.high,Vector(16,16,72)))
 assert(same(p.duckLow,Vector(-16,-16,0)) and same(p.duckHigh,Vector(16,16,36)))
end
local state=E:Ensure(p.ps)
local ring=assert(E:NewItem(p,'size_shifter_ring','rebalance-test'))
assert(ring.definitionId=='size_shifter_ring' and E:Definition(ring).name=='Ring of the Size Shifter')
assert(E:StoreWearable(state,ring))
E:RefreshDerived(p,p.ps);tick(3)
assert(not E.SizeShifterActors[p] and not p.ps.progressionState.derivedStats.sizeShifterEnabled,
 'inventory ownership alone never grants the ability')
assert(LOD.RPG.IdentityCatalog.OrdinaryFeats.INT_SIZE_SHIFTER==nil,'no Size Shifter feat remains')
assert(E:Equip(state,ring.id,'left_hand'));E:RefreshDerived(p,p.ps)
assert(p.ps.progressionState.derivedStats.sizeShifterEnabled and E.SizeShifterActors[p])
local magic=p.ps.magic
R:SyncPlayer(p);tick(1.5)
assert(math.abs(p.scale-.665)<1e-6,'halfway after1.5s');legal()
local count=#p.writes;R:SyncPlayer(p)
assert(#p.writes==count,'ordinary sync never snaps the transform');legal()
assert(math.abs(R:PushSizeScale(p)-p.scale)<1e-8,'Push size follows interpolation')
tick(1.5);assert(math.abs(p.scale-.33)<1e-6);legal()
p.crouch=false;blocked=true;tick(.5)
assert(math.abs(p.scale-.33)<1e-6 and E.SizeShifterActors[p].progress==1,'blocked growth preserves progress')
blocked=false;ceiling=50;tick(.5)
assert(math.abs(p.scale-.33)<1e-6,'standing ceiling blocks growth')
ceiling=math.huge;tick(.5)
assert(p.scale>.33 and p.scale<1,'growth resumes without accumulated catch-up')
local progress=E.SizeShifterActors[p].progress
p.crouch=true;tick(.25)
assert(math.abs(E.SizeShifterActors[p].progress-(progress+.25/3))<1e-8,'partial reversal is continuous')
for _,base in ipairs({.7,1.3}) do
 p.ps.progressionState.derivedStats.playerTargetScale=base
 p.crouch=true;tick(3);assert(math.abs(p.scale-.33)<1e-6)
 p.crouch=false;tick(3);assert(math.abs(p.scale-base)<1e-6);legal()
end
-- Shared server/predicted hull authority is independent of delayed RPG data.
p.high=Vector(1,1,1);p.duckHigh=Vector(1,1,1)
hooks.LOD_PlayerScaleLegalHull(p);legal()
-- Removing the actual ring immediately removes shrink access. Return is safe,
-- smooth and never restarted by crouch while the old interpolation retires.
p.ps.progressionState.derivedStats.playerTargetScale=1;p.crouch=true;tick(3)
assert(E:Unequip(state,'left_hand'));E:RefreshDerived(p,p.ps)
assert(E.SizeShifterActors[p].retiring and not p.ps.progressionState.derivedStats.sizeShifterEnabled)
blocked=true;tick(.1);assert(math.abs(p.scale-.33)<1e-6)
blocked=false;tick(1.5);assert(p.scale>.33 and p.scale<1 and E.SizeShifterActors[p].retiring)
tick(1.5);assert(p.scale==1 and not E.SizeShifterActors[p]);legal()
-- Re-equip in the other legal single-hand slot. Death/reset/replacement clean up.
assert(E:Equip(state,ring.id,'right_hand'));E:RefreshDerived(p,p.ps);tick(1)
assert(p.scale<1 and state.slots.left_hand==nil and state.slots.right_hand==ring.id)
p.hp=0;tick(.1);assert(p.scale==1 and not E.SizeShifterActors[p]);legal();p.hp=100
E:RefreshDerived(p,p.ps);tick(1);assert(p.scale<1)
LOD.RPGStatusElements:ResetActorLife(p)
assert(p.scale==1 and not E.SizeShifterActors[p]);legal()
E:RefreshDerived(p,p.ps);tick(1);assert(p.scale<1)
E:ClearTransient(p);assert(p.scale==1 and not E.SizeShifterActors[p]);legal()
E:RefreshDerived(p,p.ps);tick(1);assert(p.scale<1)
hooks.LOD_EquipmentSizeShifterCleanup();assert(p.scale==1 and not E.SizeShifterActors[p]);legal()
E:RefreshDerived(p,p.ps);tick(1);assert(p.scale<1)
dofile(root..'sv_equipment_size_shifter.lua')
assert(p.scale==1 and not E.SizeShifterActors[p],'hot reload retires old interpolation');legal()
-- Ordinary Big Guy scaling without the ring uses the same safe growth retry.
assert(E:Unequip(state,'right_hand'));E:RefreshDerived(p,p.ps);tick(3)
p.ps.progressionState.derivedStats.playerTargetScale=1.3;blocked=true
assert(not R:ApplySizeShifterScale(p) and E.SizeShifterActors[p].retiring)
tick(.5);assert(p.scale==1 and E.SizeShifterActors[p],'blocked growth stays queued')
blocked=false;tick(.5);assert(p.scale==1.3 and not E.SizeShifterActors[p]);legal()
assert(p.ps.magic==magic and traces>0,'no Magic charge; collision authority exercised')
print('SIZE_SHIFTER_COLLISION_PASS: real single-hand equip/unequip, inventory-only rejection, 3s/partial reversal, no sync snap, ordinary return scale, fixed hulls/blocked growth, no teleport, death/reset/hot reload cleanup')

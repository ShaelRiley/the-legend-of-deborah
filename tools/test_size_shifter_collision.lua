-- Exercise the actual core-sync, transformation tick and shared hull authority.
dofile('tools/test_checkpoint_d_core_feats.lua')
local now=0
CurTime=function() return now end
local V={};V.__index=V
function Vector(x,y,z) return setmetatable({x=x,y=y,z=z},V) end
V.__mul=function(v,s) return Vector(v.x*s,v.y*s,v.z*s) end
local function same(a,b) return a.x==b.x and a.y==b.y and a.z==b.z end
vector_origin=Vector(0,0,0)
IN_DUCK=4;MASK_PLAYERSOLID=1;COLLISION_GROUP_PLAYER_MOVEMENT=8
local hooks={};hook={Add=function(_,name,fn) hooks[name]=fn end};concommand={Add=function() end}
GetConVar=function() return nil end
LOD.RPG.Schema={DerivedStats={}}
local root='gamemodes/legend_of_deborah/gamemode/lod/'
dofile(root..'sh_player_scale_collision.lua')
dofile(root..'sv_rpg_checkpoint_d_movement_feats.lua')
local R,E,C=LOD.RPGAbilityRules,LOD.RPG.FeatEffectSystem,LOD.PlayerScaleCollision
local p={scale=1,crouch=true,pos=Vector(0,0,0),writes={},nw={},
    LODProgressionState={derivedStats={sizeShifterEnabled=true,playerTargetScale=1}}}
function p:IsPlayer() return true end
function p:Alive() return true end
function p:OnGround() return true end
function p:Crouching() return self.crouch end
function p:KeyDown() return self.crouch end
function p:GetPos() return self.pos end
function p:SetPos() error('Size Shifter must not teleport across geometry') end
function p:GetModelScale() return self.scale end
function p:SetModelScale(s)
    self.scale=s;self.writes[#self.writes+1]=s
    -- Simulate a native hull/bounds reset, the defect boundary old tests missed.
    self.high=Vector(16*s,16*s,72*s);self.duckHigh=Vector(16*s,16*s,36*s)
end
function p:SetNW2Float(k,v) self.nw[k]=v end
function p:SetHull(a,b) self.low,self.high=a,b end
function p:SetHullDuck(a,b) self.duckLow,self.duckHigh=a,b end
local blocked=false;local ceiling=math.huge;local traces=0
util={TraceHull=function(t)
    traces=traces+1
    assert(t.filter==p and t.mask==MASK_PLAYERSOLID and t.collisiongroup==COLLISION_GROUP_PLAYER_MOVEMENT)
    assert(t.mins.x<=-16 and t.maxs.x>=16,'Never test a subnormal movement footprint')
    return {Hit=blocked or t.maxs.z>ceiling,StartSolid=blocked,AllSolid=false}
end}
player={GetAll=function() return {p} end}
local function tick(dt) now=now+dt;hooks.LOD_RPG_CheckpointDWallJumpGroundReset() end
local function legal()
    assert(same(p.low,Vector(-16,-16,0)) and same(p.high,Vector(16,16,72)))
    assert(same(p.duckLow,Vector(-16,-16,0)) and same(p.duckHigh,Vector(16,16,36)))
end
R:SyncPlayer(p);tick(0);tick(1.5)
assert(math.abs(p.scale-.665)<1e-6);legal()
-- Routine stat/equipment sync must never briefly expand to the baseline.
local count=#p.writes;R:SyncPlayer(p);assert(#p.writes==count);legal()
tick(1.5);assert(math.abs(p.scale-.33)<1e-6);legal()
-- A blocked wall/corner prohibits growth and preserves interpolation progress.
p.crouch=false;blocked=true;tick(.5)
assert(math.abs(p.scale-.33)<1e-6 and E.SizeShifterState[p].progress==1)
assert(p.nw.LOD_SizeScale==p.scale);legal()
blocked=false;ceiling=50;tick(.5);assert(math.abs(p.scale-.33)<1e-6,'Low ceiling blocks standing growth')
ceiling=math.huge;tick(.5);assert(p.scale>.33 and p.scale<1,'Resume smoothly without accumulated catch-up')
p.crouch=true;tick(.25);assert(E.SizeShifterState[p].progress>.83,'Reverse from partial growth')
-- Different ordinary scale feats still return to their authored baseline.
for _,base in ipairs({.7,1.3}) do
    p.LODProgressionState.derivedStats.playerTargetScale=base
    p.crouch=true;tick(3);assert(math.abs(p.scale-.33)<1e-6)
    p.crouch=false;tick(3);assert(math.abs(p.scale-base)<1e-6);legal()
end
-- Predicted and server SetupMove use the same hull code, without RPG packets.
p.high=Vector(1,1,1);p.duckHigh=Vector(1,1,1)
hooks.LOD_PlayerScaleLegalHull(p);legal()
-- Feat loss cannot force an unsafe expansion; move clear then it completes.
p.LODProgressionState.derivedStats.playerTargetScale=1
p.crouch=true;tick(3)
p.LODProgressionState.derivedStats.sizeShifterEnabled=false
blocked=true;tick(.1);assert(math.abs(p.scale-.33)<1e-6)
blocked=false;tick(.1);assert(p.scale==1);legal()
-- An initially blocked Big Guy scale is retried after clearance, not forgotten.
E.SizeShifterState[p]=nil;p.scale=1
p.LODProgressionState.derivedStats.playerTargetScale=1.3
blocked=true;R:SyncPlayer(p);tick(.1);assert(p.scale==1)
blocked=false;tick(.1);assert(p.scale==1.3);legal()
assert(traces>0)
print('SIZE_SHIFTER_COLLISION_PASS: fixed stand/duck hulls, wall/ceiling growth guards, no sync snap, smooth reversal, Little/Big return scales, feat removal, shared prediction')

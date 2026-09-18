-- Delayed SENT registration and hostile hook order are engine lifecycle seams.
-- Run the real scan, unified controller, handoff and instance coroutine.
local fixture=dofile('tools/test_equipment_economy_runtime.lua')
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local V=getmetatable(Vector())
V.__add=function(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
V.__sub=function(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
V.__unm=function(a) return a*-1 end
function V:Normalize() local d=self:Length();self.x=self.x/d;self.y=self.y/d;self.z=self.z/d end
V.__mul=function(a,b) return Vector(a.x*b,a.y*b,a.z*b) end
function V:LengthSqr() return self:DistToSqr(Vector()) end
function V:Length() return math.sqrt(self:LengthSqr()) end
function V:GetNormalized() return self*(1/math.max(self:Length(),.001)) end
local now=0;CurTime=function() return now end;FrameNumber=function() return math.floor(now*100) end
local hooks={};hook.Add=function(_,id,f) hooks[id]=f end
net.Start=function() end;net.WriteEntity=function() end;net.WriteBool=function() end
net.WriteFloat=function() end;net.Broadcast=function() end
file={Exists=function() return true end}
local ply=fixture.actor('watcher-player');ply.pos=Vector(240,0,0)
function ply:GetPos() return self.pos end
function ply:EyePos() return self.pos+Vector(0,0,64) end
function ply:GetOwner() end;function ply:GetParent() end
local run=fixture.Run;run.State.Graph={CellTags={},Cells={}};run.State.BuildReady=true
LOD.MazeNavigator={WorldToCell=function() return {x=1,y=1,z=0} end,Distance=function() return 1 end}
LOD.MazeGenerator={CellKey=function() return '1:1:0' end}
LOD.HostileMotionV2={CellFloorPoint=function() return nil end,Stop=function() end,FaceToward=function() end,HoldHitStun=function(_,e) return now<(e.LODHitStunUntil or 0) end}
LOD.EncounterDirector=nil;LOD.WanderingDirector={Entities={}}
local blocked=false
util.TraceLine=function() return {Hit=blocked,Fraction=blocked and .5 or 1} end
local class=nil;scripted_ents.GetStored=function() return class and {t=class} end
ents={FindByClass=function() return {} end}
for _,file in ipairs({'sv_watcher','sv_watcher_unified','sv_watcher_scan_escape_handoff','sv_watcher_instance_dispatch'}) do dofile(root..file..'.lua') end
class={Initialize=function() end,_TryAttack=function() end,_BehaviourTick=function(e) e.generic=true end,
 RunBehaviour=function(e) while true do e:_BehaviourTick();coroutine.yield() end end}
local ent=fixture.actor('watcher',true);setmetatable(ent,{__index=class})
function ent:GetClass() return 'lod_hostile' end
function ent:GetPos() return Vector() end
function ent:WorldSpaceCenter() return Vector(0,0,36) end
function ent:_RefreshTarget() self.LODTarget=ply end
ent.LODArchetypeId='watcher';ent.LODActivated=true;ent.LODConfig={}
-- Dispatcher first, generic movement last: the old marker-only dispatch called
-- this generic tick and never started a scan.
hooks.LOD_WatcherUnifiedPreSpawnRunBehaviourDispatch(ent)
class._BehaviourTick=function(e) e.generic=true end
ent:Initialize();now=1
local co=coroutine.create(function() ent:RunBehaviour() end)
local function tick() local ok,err=coroutine.resume(co);assert(ok,err) end
tick();assert(ent.LODWatcherScan and not ent.generic,'Standoff must start actual scan despite late generic patch')
now=1.7;tick();assert(ent.LODWatcherScan.midCue,'Scan must advance while stationary')
now=2.3;tick();assert(LOD.Watcher.Stats.scansCompleted==1 and ent.LODWatcherUnifiedEscape,'Completion enters escape in same tick')
assert(LOD.WatcherScanEscapeHandoff.Stats.completionsObserved==1)
-- Interruptions still use the ordinary resolver; no immortal scan state.
ent.LODWatcherUnifiedEscape=nil;ent.LODNextWatcherScan=0;now=3;tick();assert(ent.LODWatcherScan)
blocked=true;now=3.1;tick();assert(not ent.LODWatcherScan and LOD.Watcher.Stats.cancelledLOS==1)
blocked=false;ent.LODNextWatcherScan=0;now=4;tick();assert(ent.LODWatcherScan)
ent.LODHitStunUntil=5;now=4.1;tick();assert(not ent.LODWatcherScan and LOD.Watcher.Stats.cancelledStun==1)
-- Non-Watchers retain the existing final-class method binding repair.
local other=fixture.actor('runner',true);setmetatable(other,{__index=class});other.GetClass=ent.GetClass
other.LODArchetypeId='runner';local own=function() end;other._BehaviourTick=own
LOD.WatcherUnifiedDispatch.BindFinalMethods(other);assert(other._BehaviourTick==class._BehaviourTick)
ent.LODHitStunUntil=0;ent.LODNextWatcherScan=0;ply.pos=Vector(80,0,0);now=6
tick();assert(ent.LODWatcherScan and ent.LODWatcherCorneredScan,'Cornered Watcher can scan instead of idle-locking')
now=7.3;tick();assert(LOD.Watcher.Stats.scansCompleted==2 and ent.LODWatcherUnifiedEscape)
print('WATCHER_DISPATCH_PASS: delayed registration, adversarial hook order, real scan progression/completion/escape, LOS/stun cancellation, non-Watcher preservation')

-- Native objects are counted, not emulated. This proves ownership/cleanup and
-- error unwinding; it cannot reproduce a Source driver or collision fault.
local hooks, now, allocated, live = {}, 0, 0, 0
local function noop() end
hook={Add=function(event,name,fn) hooks[event]=hooks[event] or {};hooks[event][name]=fn end}
local function fire(event) for _,fn in pairs(hooks[event] or {}) do fn() end end
function CurTime() return now end
function IsValid(v) return type(v)=='table' and v.valid~=false end
function include() end
function AddCSLuaFile() end
local V={}
V.__index=V
function Vector(x,y,z) return setmetatable({x=x or 0,y=y or 0,z=z or 0},V) end
function V.__add(a,b) return Vector(a.x+b.x,a.y+b.y,a.z+b.z) end
function V.__sub(a,b) return Vector(a.x-b.x,a.y-b.y,a.z-b.z) end
function V.__mul(a,b) return Vector(a.x*b,a.y*b,a.z*b) end
function V:LengthSqr() return self.x^2+self.y^2+self.z^2 end
function V:Length() return math.sqrt(self:LengthSqr()) end
function V:DistToSqr(b) return (self-b):LengthSqr() end
function V:Normalize() return self end
function V:Angle() return {} end
vector_origin=Vector();angle_zero={}
function Mesh()
 allocated=allocated+1;live=live+1
 local m={}
 function m:Destroy() assert(not self.dead,'double destroy');self.dead=true;live=live-1 end
 function m:Draw() assert(not self.dead,'draw after eviction') end
 return m
end
mesh=setmetatable({}, {__index=function() return noop end})
LOD={}
local path='gamemodes/legend_of_deborah/gamemode/lod/cl_textured_box.lua'
dofile(path)
local B=LOD.TexturedBox
local a=B:GetMesh(Vector(),Vector(1,2,3))
assert(B:GetMesh(Vector(),Vector(1,2,3))==a and live==1)
for i=1,1000 do
 B:GetMesh(Vector(),Vector(i,2,3));B:GetSlabMesh(Vector(),Vector(i,2,0))
 assert(live<=256 and B:MeshCacheCount()==live)
end
assert(a.dead and live==256)
local n=allocated
assert(not B:GetMesh(Vector(),Vector(0/0,2,3)))
assert(not B:GetMesh(Vector(),Vector(math.huge,2,3)))
assert(not B:GetMesh(Vector(),Vector(-1,2,3)))
assert(not B:GetMesh(Vector(),Vector(1,2,3),math.huge))
assert(allocated==n)
fire('PostCleanupMap');assert(live==0)
B:GetMesh(Vector(),Vector(2,3,4));dofile(path);assert(live==0,'refresh leaked native meshes')
B:GetMesh(Vector(),Vector(2,3,4));fire('ShutDown');assert(live==0)

-- Mirror: errors from an external RenderView or 2D hook must balance stacks.
local targets,cameras,errors,mode=0,0,0,'view-error'
ENT={}
function GetRenderTarget() return {GetName=function() return 'test' end} end
function CreateMaterial() return {} end
local mirror={GetPos=function() return Vector() end}
local ply={GetNW2Bool=function() return false end,GetPos=function() return Vector(50,0,0) end,EyePos=function() return Vector(50,0,60) end}
function LocalPlayer() return ply end
ents={FindByClass=function() return {mirror} end}
render={PushRenderTarget=function() targets=targets+1 end,PopRenderTarget=function() targets=targets-1;assert(targets>=0) end,
 Clear=noop,RenderView=function()
  fire('PreRender') -- the recursion guard must prevent another camera
  if mode=='view-error' then error('injected external draw error') end
 end}
cam={Start2D=function() cameras=cameras+1 end,End2D=function() cameras=cameras-1;assert(cameras>=0) end}
surface={SetMaterial=noop,SetDrawColor=noop,DrawTexturedRectUV=function() if mode=='2d-error' then error('injected 2D error') end end}
function ErrorNoHalt() errors=errors+1 end
dofile('gamemodes/legend_of_deborah/entities/entities/lod_staging_mirror/cl_init.lua')
for _,m in ipairs({'view-error','2d-error','ok'}) do
 mode=m;now=now+6;fire('PreRender')
 assert(targets==0 and cameras==0,'render state leaked')
 assert(not hooks.ShouldDrawLocalPlayer.LOD_StagingMirrorLocalPlayer(),'recursion guard stayed latched')
end
assert(errors==2)

-- Starter grants settle once, and every native grant/removal operation happens
-- only after the touch stack unwinds.
local queued,grants,inTouch,allowGrant={},0,false,true
timer={Simple=function(_,fn) queued[#queued+1]=fn end}
net={Start=noop,WriteString=noop,Send=noop}
util={AddNetworkString=noop};concommand={Add=noop}
LOD.StagingDeployment={ClaimStarter=function()
 assert(not inTouch,'starter grant ran inside native touch traversal')
 grants=grants+1
 return allowGrant
end}
ENT={}
dofile('gamemodes/legend_of_deborah/entities/entities/lod_staging_prop/init.lua')
local pickup=setmetatable({LODStagingWeaponClass='weapon_357'}, {__index=ENT})
function pickup:GetModel() return 'test' end
function pickup:GetStageLabel() return 'test' end
function pickup:Remove() assert(not inTouch);self.valid=false end
function ply:IsPlayer() return true end
function ply:Alive() return true end
inTouch=true;pickup:_TryStarterClaim(ply);pickup:_TryStarterClaim(ply);inTouch=false
assert(grants==0 and #queued==1 and IsValid(pickup) and pickup.LODStageClaimPending)
queued[1]();queued={}
assert(grants==1 and not IsValid(pickup),'deferred starter grant did not settle once')

-- A failed deferred grant releases the reservation and leaves the pickup for a
-- later retry rather than consuming or duplicating the starter.
local retry=setmetatable({LODStagingWeaponClass='weapon_smg1'}, {__index=ENT})
function retry:GetModel() return 'test' end
function retry:GetStageLabel() return 'test' end
function retry:Remove() assert(not inTouch);self.valid=false end
allowGrant=false;retry:_TryStarterClaim(ply)
assert(#queued==1 and retry.LODStageClaimPending);queued[1]();queued={}
assert(IsValid(retry) and not retry.LODStageClaimPending)
allowGrant=true;retry:_TryStarterClaim(ply);assert(#queued==1);queued[1]();queued={}
assert(not IsValid(retry) and grants==3,'failed starter grant was not safely retryable')

-- The physical pickup uses the native model scale: scaled solid trigger models
-- are an unnecessary collision rebuild risk in Source.
MOVETYPE_NONE=1;SOLID_BBOX=2;COLLISION_GROUP_DEBRIS_TRIGGER=3
RENDERMODE_TRANSCOLOR=4;SIMPLE_USE=5
function Color() return {} end
util.IsValidModel=function() return true end
local initialized=setmetatable({LODStageModel='test'}, {__index=ENT})
function initialized:GetStageKind() return 3 end
function initialized:SetModel() end
function initialized:SetMoveType() end
function initialized:SetSolid() end
function initialized:SetCollisionBounds() end
function initialized:SetTrigger(value) self.trigger=value end
function initialized:SetCollisionGroup() end
function initialized:SetRenderMode() end
function initialized:SetColor() end
function initialized:SetUseType() end
function initialized:SetModelScale() error('starter pickup must retain native model scale') end
function initialized:DrawShadow() end
initialized:Initialize();assert(initialized.trigger)

-- The pickup celebration retains its sound/HUD acknowledgement without making
-- a duplicate clientside weapon model or taking over the player's camera.
local stagingReceiver,reads,clientModels=nil,0,0
function Material() return {} end
surface={CreateFont=noop}
net.Receive=function(name,fn) if name=='LOD_StagingStarterCelebration' then stagingReceiver=fn end end
net.ReadString=function() reads=reads+1;return reads==1 and 'weapon_357' or reads==2 and '.357 MAGNUM' or 'test' end
function ClientsideModel() clientModels=clientModels+1;return {} end
dofile('gamemodes/legend_of_deborah/entities/entities/lod_staging_prop/cl_init.lua')
assert(stagingReceiver);stagingReceiver()
assert(clientModels==0,'starter celebration created a native client model')
assert(not (hooks.CalcView and hooks.CalcView.LOD_StagingStarterCelebrationView))
assert(not (hooks.PostDrawTranslucentRenderables and hooks.PostDrawTranslucentRenderables.LOD_StagingStarterCelebrationWeapon))
-- The afterimage cache used to retain 32 native models for EVERY model path.
-- Exercise many models and verify the global free-object bound after expiry.
local ghostLive, receivers, packet, cursor = 0, {}, {}, 0
function Material() return {} end
function ClientsideModel()
 ghostLive=ghostLive+1
 local g=setmetatable({}, {__index=function() return noop end})
 function g:Remove() assert(self.valid~=false);self.valid=false;ghostLive=ghostLive-1 end
 return g
end
math.Clamp=function(v,a,b) return math.max(a,math.min(b,v)) end
net.Receive=function(name,fn) receivers[name]=fn end
local function read() cursor=cursor+1;return packet[cursor] end
net.ReadEntity=read;net.ReadVector=read;net.ReadBool=read;net.ReadString=read;net.ReadAngle=read
dofile('gamemodes/legend_of_deborah/gamemode/lod/cl_pushback_fx.lua')
for i=1,100 do
 packet={{valid=false},Vector(),Vector(500,0,0),Vector(),Vector(),false,'test','model-'..i,{}}
 cursor=0;receivers.LOD_PushbackFX()
 assert(ghostLive<=272,'unbounded native afterimage cache')
end
now=now+2;fire('PostDrawTranslucentRenderables');assert(ghostLive==64)
fire('PostCleanupMap');assert(ghostLive==0)
fire('ShutDown');assert(ghostLive==0)

-- Build evidence must distinguish missing loaded components from a clean set.
SERVER=true;VERSIONSTR='test-engine';BRANCH='test-branch'
file={Read=function() return 'abcdef clean\n' end}
ents.GetCount=function() return 77 end
timer.Create=function() end
function GetConVar() return {GetBool=function() return false end} end
dofile('gamemodes/legend_of_deborah/gamemode/lod/sh_runtime_audit.lua')
for _,key in ipairs({'hostile','pickup','loot','staging','equipment','equipment_generator','crowbar','statue','manual'}) do
 LOD.RuntimeReceipts[key]=LOD.RuntimeAudit.Build
end
local snapshot=LOD.RuntimeAudit:Snapshot()
assert(snapshot.missing=='none' and snapshot.entities==77 and snapshot.realm=='server')
assert(snapshot.install=='abcdef clean ' and snapshot.lua_kb>0)
LOD.RuntimeReceipts.loot=nil
assert(LOD.RuntimeAudit:Snapshot().missing=='loot')
LOD.RuntimeReceipts.loot=LOD.RuntimeAudit.Build
LOD.RuntimeReceipts.equipment_generator='geometry-init-20260916-01'
assert(LOD.RuntimeAudit:Snapshot().missing=='equipment_generator','Old generator must not pass new build receipts')
print('NATIVE_RESOURCE_LIFECYCLE_PASS: mesh and ghost bounds/cleanup, invalid geometry, mirror error unwinding, deferred starter grant/removal, safe celebration, loaded build receipts')

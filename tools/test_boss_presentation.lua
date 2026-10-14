-- Real production Snapshot and client packet/ghost parser, with only rendering,
-- network transport and clientside entity allocation emulated. The client frames
-- below deliberately exercise presentation independently of defeat authorization,
-- which tools/test_boss_framework.lua covers through native death and key receipt.
local F=dofile('tools/boss_framework_fixture.lua')
local B=F.B
local native=arg and arg[1]=='--native'
local nativePayload,nativeWrites
if native then
 nativeWrites=0
 net.WriteTable=function(s) nativeWrites=nativeWrites+1;nativePayload=table.Copy(s) end
 -- Any JSON/LZMA use in this mode is a test failure, including server encoding.
 util.Compress=function() error('native snapshot invoked compression') end
 util.TableToJSON=function() error('native snapshot invoked JSON encoding') end
end
local noop=function() end
local receive,clientHooks={},{}
local originalAdd=hook.Add
hook.Add=function(event,id,fn) clientHooks[id]=fn end
net.Receive=function(id,fn) receive[id]=fn end
local incoming
net.ReadBool=function() return incoming~=nil end
net.ReadUInt=function() return 2 end
net.ReadData=function() return '{}' end
util.Decompress=function(s) assert(not native,'native snapshot invoked decompression');return s end
util.JSONToTable=function() assert(not native,'native snapshot invoked JSON decoding');return table.Copy(incoming) end
net.ReadTable=function() return table.Copy(incoming) end
function Material(path) return {path=path} end
surface={CreateFont=noop}
local clientModels={}
function ClientsideModel(model)
 local e=F.actor('client_model');e:SetModel(model);clientModels[#clientModels+1]=e;return e
end
function Entity(id) for _,e in ipairs(F.created) do if e:EntIndex()==id and IsValid(e) then return e end end;return NULL end
RENDERGROUP_OPAQUE=1
SERVER,CLIENT=false,true
dofile(F.root..'cl_boss_encounter.lua')
for _,id in ipairs(LOD.BossRegistry.Modules) do dofile(F.root..'bosses/cl_'..id..'.lua') end
hook.Add=originalAdd
local V=LOD.BossPresentation
local bools={'LOD_Beaver','LOD_MelfGiant','LOD_BDDActive','LOD_BossEngineDamaged','LOD_BossCracked','LOD_BossInverted','LOD_BossVertical','LOD_BossTorn','LOD_BossSectionDetached','LOD_RankAllDrawers','LOD_BossDoorOpen','LOD_CornetteMissingLeft','LOD_CornetteMissingRight','LOD_CornetteCrying','LOD_MookyDamaged','LOD_BossScorched'}
local strings={'LOD_MelfIdentity','LOD_MelfClass','LOD_MelfWeapon','LOD_BossAction','LOD_BossCycle','LOD_MookyProtectedKnee'}
local numbers={'LOD_BossHeat','LOD_RankDrawer','LOD_CornetteStrain','LOD_BDDHits'}
local passed=0
local receiver=native and receive.LOD_BossStateNative or receive.LOD_BossState
for level=2,19 do
 SERVER,CLIENT=true,false
 local s,c=F.setup(level);local actor=c.actor;local color=Color(37+level,83,129,211);local size=1+level/20
 actor:SetColor(color);actor:SetNW2Float('LOD_SizeScale',size)
 -- Distinct sentinels prove every supported property survives both seams;
 -- these are ordinary native NW writes, never substitute B or client methods.
 for i,k in ipairs(bools) do actor:SetNW2Bool(k,true) end
 for i,k in ipairs(strings) do actor:SetNW2String(k,'retained_'..i) end
 for i,k in ipairs(numbers) do actor:SetNW2Int(k,i+11) end
 local live=B:Snapshot(c);
 if native then
  nativePayload=nil;B:Sync(F.p)
  assert(nativePayload and nativePayload.id==c.id and nativePayload.serial==c.serial,'late join lost full snapshot')
  assert(F.packets[#F.packets].id=='LOD_BossStateNative')
  assert(nativePayload.visual.color.r==color.r and nativePayload.health==actor:Health())
 end
 assert(live.size==size and live.visual.color.r==color.r,'snapshot lost actor scale/color '..c.id)
 for _,k in ipairs(bools) do assert(live.visual.bools[k]==true,'snapshot omitted '..k) end
 actor:Remove();local snapshot=B:Snapshot(c)
 assert(snapshot.actor==0 and snapshot.size==size and snapshot.visual.color.a==211,'invalid native body lost retained visual state '..c.id)
 assert(V.Modules[c.id] and type(V.Modules[c.id].Draw)=='function','actual client module not loaded '..c.id)
 snapshot.dead=true;snapshot.deathAt=F.clock;snapshot.deathDuration=c.def.deathDuration
 assert(snapshot.deathDuration and snapshot.deathDuration>0,'missing shared deathDuration '..c.id)
 incoming=snapshot;SERVER,CLIENT=false,true;receiver()
 local ghost=clientModels[#clientModels];assert(IsValid(ghost) and V:State(ghost),'real client receiver did not create accepted ghost '..c.id)
 assert(ghost:GetModel()==snapshot.model and ghost:GetNW2Float('LOD_SizeScale',0)==size,'ghost lost native model/scale '..c.id)
 assert(ghost:GetColor().r==color.r and ghost:GetColor().a==211,'ghost lost native color '..c.id)
 for _,k in ipairs(bools) do assert(ghost:GetNW2Bool(k,false),'ghost omitted '..k) end
 for i,k in ipairs(strings) do assert(ghost:GetNW2String(k,'')=='retained_'..i,'ghost changed '..k) end
 for i,k in ipairs(numbers) do assert(ghost:GetNW2Int(k,0)==i+11,'ghost changed '..k) end
 local created=#clientModels;receiver();assert(#clientModels==created,'duplicate packet allocated duplicate ghost')
 F.clock=snapshot.deathAt+snapshot.deathDuration-.001;receiver();clientHooks.LOD_ModularBossPresentationLifetime();assert(IsValid(ghost),'ghost expired before authored duration')
 F.clock=snapshot.deathAt+snapshot.deathDuration;receiver();clientHooks.LOD_ModularBossPresentationLifetime();assert(not IsValid(ghost),'ghost outlived exact deathDuration')
 passed=passed+1;print('BOSS_PRESENTATION_PASS '..c.id..' snapshot retained properties native removal client ghost exact lifetime')
end
incoming=nil;receiver()
for _,e in ipairs(clientModels) do assert(not IsValid(e),'disposal leaked clientside model') end
assert(next(V.Props)==nil,'disposal leaked reusable prop pool')
if native then
 SERVER,CLIENT=true,false
 local s,c=F.setup(2);local def=c.def;local snapshot=def.Snapshot
 def.Snapshot=function() return string.rep('x',4097) end
 nativePayload=nil;B:Sync();assert(nativePayload==nil,'oversized detail admitted to net buffer')
 def.Snapshot=snapshot
 B:Cleanup(c,'test');nativePayload=nil;B:Sync();assert(nativePayload==nil,'stale boss state survived cleanup')
 assert(nativeWrites>=18)
end
print('BOSS_PRESENTATION_SUMMARY passed='..passed..' failed=0 native_transport='..tostring(native))

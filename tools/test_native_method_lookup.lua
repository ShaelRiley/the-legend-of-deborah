-- Exercise the production installer; only native C metadata is simulated.
-- Actual method precedence/removal proof and Deck FPS are separate runtime gates.
local source='gamemodes/legend_of_deborah/gamemode/lod/sv_hostile_motion_v2.lua'
local ordinaryGetMeta,ordinaryRaw=getmetatable,rawget
local nativeInfo=debug.getinfo
local actualJit=jit
jit={os="Windows",arch="x64"};VERSIONSTR="2026.09.17"
local nextMeta,entityMeta={},{}
local function original(actor,key)
 local v=ordinaryRaw(nextMeta,key);if v~=nil then return v end
 v=ordinaryRaw(entityMeta,key);if v~=nil then return v end
 return actor.fields[key]
end
nextMeta.__index=original;entityMeta.GetPos=function()return 'position'end
nextMeta.GetPos=function()return 'next position'end
entityMeta.Health=function()return 100 end
local handlers={}
hook={Add=function(event,name,fn)handlers[event..'/'..name]=fn end}
concommand={Add=function()end};scripted_ents={GetStored=function()end}
LOD={Config={Maze={},Geometry={}},MazeGenerator={CellKey=function()end},MazeNavigator={}}
FindMetaTable=function(name)return name=='NextBot'and nextMeta or name=='Entity'and entityMeta end
debug.getinfo=function(fn,...)if fn==original then return{what='C'}end;return nativeInfo(fn,...)end
local function load()dofile(source);return LOD.HostileMotionV2.NativeMethodLookup end
local lease=assert(load());local fast=lease.wrapper;assert(nextMeta.__index==fast and lease.original==original)
local actor={fields={Health='shadow',LODActivated=true}}
assert(fast(actor,'Health')==entityMeta.Health and fast(actor,'LODActivated')==true)
assert(fast(actor,'GetPos')==nextMeta.GetPos)
local a,b=entityMeta.Health,nextMeta.GetPos
for _,v in ipairs({false,17,'current',{},function()end})do
 entityMeta.Health=v;assert(fast(actor,'Health')==v)
 nextMeta.GetPos=v;assert(fast(actor,'GetPos')==v)
end
entityMeta.Health=nil;assert(fast(actor,'Health')=='shadow');entityMeta.Health=a;nextMeta.GetPos=b
entityMeta.NewMethod=function()return 'new'end;assert(fast(actor,'NewMethod')==entityMeta.NewMethod)
local reads=0;setmetatable(nextMeta,{__index=function()reads=reads+1 end})
assert(fast(actor,'Health')==a and reads==0);setmetatable(nextMeta,nil)
local replacementCalls=0
getmetatable=function()replacementCalls=replacementCalls+1;return nil end
assert(fast(actor,'Health')==a and replacementCalls==0);getmetatable=ordinaryGetMeta
rawget=function()replacementCalls=replacementCalls+1;return nil end
assert(fast(actor,'Health')==a and replacementCalls==0);rawget=ordinaryRaw
local weak=setmetatable({[actor]=true},{__mode='k'});fast(actor,'Health');actor=nil;collectgarbage();collectgarbage();assert(next(weak)==nil)
local reloaded=load();assert(reloaded.original==original and reloaded.wrapper~=fast and nextMeta.__index==reloaded.wrapper)
handlers['OnReloaded/LOD_HostileNativeMethodLookup']();assert(LOD.HostileMotionV2.NativeMethodLookup.original==original)
local foreign=function()return 'foreign'end;nextMeta.__index=foreign
handlers['OnReloaded/LOD_HostileNativeMethodLookup']();assert(nextMeta.__index==foreign and LOD.HostileMotionV2.NativeMethodLookup==nil)
assert(load()==nil and nextMeta.__index==foreign)
nextMeta.__index=original;assert(load());setmetatable(entityMeta,{})
handlers['OnReloaded/LOD_HostileNativeMethodLookup']();assert(nextMeta.__index==original and LOD.HostileMotionV2.NativeMethodLookup==nil)
setmetatable(entityMeta,nil)
VERSIONSTR="unsupported";assert(load()==nil and nextMeta.__index==original)
VERSIONSTR="2026.09.17";jit.os="Linux";assert(load()==nil and nextMeta.__index==original)
jit=actualJit
debug.getinfo=nativeInfo
print('METHOD_LOOKUP_PASS live priority/false/deletion/new-key/native-fallback/metadata/provider/weak-lifetime/reload/foreign-owner; mocked native boundary, not FPS')

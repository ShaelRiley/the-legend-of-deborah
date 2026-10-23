-- Load the production installer; simulate C metadata only at the native boundary.
-- Native entity parity and Deck FPS are separate runtime gates.
local source='gamemodes/legend_of_deborah/gamemode/lod/sv_hostile_motion_v2.lua'
local ordinaryInfo,actualJit=debug.getinfo,jit
jit={os='Windows',arch='x64'};VERSIONSTR='2026.09.17'
local meta,handlers={},{}
local calls=0
local function native(self,...)
 calls=calls+1
 if self=='error'then error('native-validity-sentinel')end
 return self and self.valid,nil,...
end
meta.IsValid=native
FindMetaTable=function(name)if name=='Entity'then return meta end end
hook={Add=function(event,name,fn)handlers[event..'/'..name]=fn end}
concommand={Add=function()end};scripted_ents={GetStored=function()end}
LOD={Config={Maze={},Geometry={}},MazeGenerator={CellKey=function()end},MazeNavigator={}}
debug.getinfo=function(fn,...)if fn==native then return{what='C'}end;return ordinaryInfo(fn,...)end
local function load()dofile(source);return LOD.HostileMotionV2.NativeValidityForwarder end
local owner=assert(load());assert(owner.original==native and owner.wrapper==meta.IsValid)
local actor={valid=true}
local a,b,c,d=meta.IsValid(actor,'kept',nil);assert(a==true and b==nil and c=='kept'and d==nil and calls==1)
actor.valid=false;assert(meta.IsValid(actor)==false and calls==2)
actor.valid=nil;assert(select('#',meta.IsValid(actor,'kept',nil))==4)
local ok,e=pcall(meta.IsValid,'error');assert(not ok and tostring(e):find('native%-validity%-sentinel'))
local old=owner.wrapper;owner=assert(load());assert(owner.original==native and owner.wrapper~=old)
actor.valid=true;assert(old(actor)==true);actor.valid=false;assert(old(actor)==false)
local weak=setmetatable({[actor]=true},{__mode='k'});meta.IsValid(actor);actor=nil;collectgarbage();collectgarbage();assert(next(weak)==nil)
handlers['OnReloaded/LOD_HostileNativeValidityForwarder']();assert(LOD.HostileMotionV2.NativeValidityForwarder.original==native)
local foreign=function()return'foreign'end;meta.IsValid=foreign
handlers['OnReloaded/LOD_HostileNativeValidityForwarder']();assert(meta.IsValid==foreign and LOD.HostileMotionV2.NativeValidityForwarder==nil)
assert(load()==nil and meta.IsValid==foreign)
meta.IsValid=native;assert(load());VERSIONSTR='unsupported'
handlers['OnReloaded/LOD_HostileNativeValidityForwarder']();assert(meta.IsValid==native and LOD.HostileMotionV2.NativeValidityForwarder==nil)
VERSIONSTR='2026.09.17';jit.os='Linux';assert(load()==nil and meta.IsValid==native)
jit.os='Windows';setmetatable(meta,{})
assert(load()==nil and meta.IsValid==native);setmetatable(meta,nil)
debug.getinfo=ordinaryInfo;jit=actualJit
print('NATIVE_VALIDITY_FORWARDER_PASS fresh true/false/nil, varargs/returns/error, native owner, reload, late reference, weak entity lifetime, foreign owner, unsupported ABI; mocked C metadata, not FPS')

-- Production account identity/lifecycle behavior with explicit synthetic native
-- metadata. Real engine-C eligibility/parity is a separate Deck boundary gate.
local source=arg[1]or'.'
local noop=function()end
LOD={Config={}}
CreateConVar=function()return{}end
concommand={Add=noop}
local hooks={}
hook={Add=function(event,id,fn)hooks[event]=hooks[event]or{};hooks[event][id]=fn end}
IsValid=function(p)return type(p)=='table'and p.valid~=false end
isstring=function(v)return type(v)=='string'end
local calls=0
local function nativeID(p)calls=calls+1;return p.id end
local function nativeAuth(p)return p.authed==true end
local meta={SteamID64=nativeID,IsFullyAuthenticated=nativeAuth}
FindMetaTable=function(name)if name=='Player'then return meta end end
local getinfo=debug.getinfo
local function loadRuntime(native)
 debug.getinfo=function(fn,...)
  if native and(fn==nativeID or fn==nativeAuth)then return {what='C'}end
  return getinfo(fn,...)
 end
 local ok,err=pcall(dofile,source..'/gamemodes/legend_of_deborah/gamemode/lod/sv_run_manager.lua')
 debug.getinfo=getinfo;assert(ok,err)
 return LOD.RunManager
end
local function actor(id,authed)
 return setmetatable({id=id,authed=authed,EntIndex=function()return 7 end},{__index=meta})
end
local R=loadRuntime(true)
local p=actor('account-A',true)
assert(R:IdentityOf(nil)==nil);p.valid=false;assert(R:IdentityOf(p)==nil);p.valid=true
assert(R:IdentityOf(p)=='account-A');local before=calls
for _=1,100 do assert(R:IdentityOf(p)=='account-A')end
assert(calls==before,'authenticated native account key queried repeatedly')
-- A cached account must never cache a profile or cooperative state.
local first,second={},{}
R.State.PlayerState={['account-A']=first};assert(R:GetPlayerState(p)==first)
R.State={PlayerState={['account-A']=second}};assert(R:GetPlayerState(p)==second)
assert(R:GetPlayerState('account-A')==second)
-- Providers remain live; switching away invalidates the old native receipt.
local foreignCalls=0
p.SteamID64=function()foreignCalls=foreignCalls+1;return 'custom-'..foreignCalls end
assert(R:IdentityOf(p)=='custom-1'and R:IdentityOf(p)=='custom-2')
p.id='account-B';p.SteamID64=nil;assert(R:IdentityOf(p)=='account-B')
for _,event in ipairs({'PlayerDisconnected','EntityRemoved'})do
 local fn=assert(hooks[event].LOD_RunManagerAccountKey);fn(p)
 before=calls;assert(R:IdentityOf(p)=='account-B'and calls==before+1)
end
p.valid=false;assert(R:IdentityOf(p)==nil);p.valid=true
-- Pending authentication and zero identifiers must be queried afresh.
local pending=actor('pending',false);assert(R:IdentityOf(pending)=='pending')
pending.id='authenticated';pending.authed=true;assert(R:IdentityOf(pending)=='authenticated')
local zero=actor('0',true);assert(R:IdentityOf(zero)=='bot:7')
zero.id='after-zero';assert(R:IdentityOf(zero)=='after-zero')
local customAuth=actor('auth-override',true);customAuth.IsFullyAuthenticated=function()return true end
assert(R:IdentityOf(customAuth)=='auth-override');customAuth.id='new-override';assert(R:IdentityOf(customAuth)=='new-override')
local broken=actor('ignored',true);broken.SteamID64=function()error('identity-provider-sentinel')end
local ok,err=pcall(R.IdentityOf,R,broken);assert(not ok and tostring(err):find('identity-provider-sentinel',1,true))
-- Refresh establishes a new weak receipt set without losing manager state.
before=calls;local saved=R.State;assert(loadRuntime(true)==R and R.State==saved)
assert(R:IdentityOf(p)=='account-B'and calls==before+1)
local weak=setmetatable({},{__mode='v'})
do local transient=actor('transient',true);weak[1]=transient;assert(R:IdentityOf(transient)=='transient')end
collectgarbage('collect');collectgarbage('collect');assert(weak[1]==nil,'identity cache retains player')
-- Unsupported/Lua/custom metadata keeps the previous direct provider behavior.
R=loadRuntime(false);before=calls;R:IdentityOf(p);R:IdentityOf(p);assert(calls==before+2)
meta.SteamID64='not-a-method';R=loadRuntime(true)
local ok=pcall(R.IdentityOf,R,actor('bad',true));assert(not ok,'invalid provider error swallowed')
print('RUN_MANAGER_IDENTITY_PASS native key eligibility, fresh validity/state, pending/zero/custom/error providers, reload/disconnect/removal, weak ownership')

-- Execute the production providers and staging wrapper with native-shaped
-- Player APIs. This is query/lifecycle parity, not Steam Deck FPS evidence.
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local function read(path)local f=assert(io.open(path));local s=f:read('*a');f:close();return s end
local runSource,stageSource=read(root..'sv_run_manager.lua'),read(root..'sv_staging_deployment.lua')
local luaType=type
local steamCalls,indexCalls=0,0
local steam=function(p)steamCalls=steamCalls+1;return p.id end
local entIndex=function(p)indexCalls=indexCalls+1;return p.index or 1 end
local entityValidity=function(p)return p.valid~=false end
local native={SteamID64=steam,EntIndex=entIndex,IsValid=entityValidity}
_G.type=function(v)if luaType(v)=='table'and v.nativePlayer then return 'Player' end;return luaType(v)end
function IsValid(p)return luaType(p)=='table'and p.valid~=false end
function isstring(v)return luaType(v)=='string'end
local metaAvailable=true
function FindMetaTable(name)if not metaAvailable then return nil end;if name=='Player'then return{SteamID64=steam}elseif name=='Entity'then return{EntIndex=entIndex,IsValid=entityValidity}end end
local cases,assertions=0,0
local function check(value,message)assertions=assertions+1;assert(value,message)end
local function fixture()
 local R={State={ActiveIdentity={A=true,B=true},PlayerState={A={deploymentComplete=true},B={deploymentComplete=false}}}}
 local S={};local p=setmetatable({id='A',index=1,nativePlayer=true},{__index=native})
 for _,name in ipairs({'IdentityOf','GetPlayerState','IsActivePlayer'})do
  local fn=assert(runSource:match('(function RunManager:'..name..'%b()%s.-\nend)'))
  assert(load('local RunManager=...\n'..fn))(R)
 end
 local defaults=runSource:match('RunManager.PlayerQueryDefaults%s*=%s*(%b{})')
 check(defaults~=nil,'missing shared original-provider identities')
 assert(load('local RunManager=...\nRunManager.PlayerQueryDefaults='..defaults))(R)
 local helpers=assert(stageSource:match('(local function identityOf%b()%s.-)\nlocal function starterSpec'))
 local deployed=assert(stageSource:match('(function Staging:IsDeployed%b()%s.-\nend)'))
 local block=assert(stageSource:match('(%-%- RunManager owns campaign slots.-)\nlocal function buildStarterOrder'))
 assert(load('local RunManager,Staging=...\n'..helpers..'\n'..deployed..'\n'..block))(R,S)
 return R,S,p
end
local function test(name,fn)steamCalls,indexCalls=0,0;fn();cases=cases+1;print('PASS '..name)end

test('native deployed query resolves identity once',function()
 local R,S,p=fixture();check(R:IsActivePlayer(p)==true);check(steamCalls==1,'duplicate native identity queries remain')
 check(S:IsDeployed(p)==true,'public deployment provider changed')
end)
test('slot/deployment/profile changes remain fresh',function()
 local R,S,p=fixture();check(R:IsActivePlayer(p)==true)
 R.State.ActiveIdentity.A=false;check(R:IsActivePlayer(p)==false)
 R.State.ActiveIdentity.A=true;R.State.PlayerState.A.deploymentComplete=false;check(R:IsActivePlayer(p)==false)
 R.State.PlayerState.A=nil;check(R:IsActivePlayer(p)==false)
 R.State.PlayerState.A={deploymentComplete=true};check(R:IsActivePlayer(p)==true)
 R.State.PlayerState.A.deploymentComplete=1;check(R:IsActivePlayer(p)==false,'deployment requires true')
end)
test('same identity state/map replacement is observed',function()
 local R,S,p=fixture();local old=R.State;check(R:IsActivePlayer(p))
 R.State={ActiveIdentity={A=true},PlayerState={A={deploymentComplete=false}}};check(R:IsActivePlayer(p)==false)
 old.PlayerState.A.deploymentComplete=true;check(R:IsActivePlayer(p)==false,'stale state retained')
 R.State.PlayerState={A={deploymentComplete=true}};check(R:IsActivePlayer(p)==true)
 R.State.ActiveIdentity={};check(R:IsActivePlayer(p)==false)
end)
test('removed body cannot inherit reconnect state',function()
 local R,S,p=fixture();p.valid=false;check(R:IsActivePlayer(p)==nil);check(steamCalls==0)
 local q=setmetatable({id='A',nativePlayer=true},{__index=native});check(R:IsActivePlayer(q)==true)
 p.valid=true;R.State.ActiveIdentity.A=false;check(R:IsActivePlayer(p)==false)
 check(R:IsActivePlayer(nil)==nil,'invalid query result changed')
end)
test('role flags add no new eligibility rule',function()
 local R,S,p=fixture();p.soldier=true;check(R:IsActivePlayer(p)==true,'query invented a faction rule')
 R.State.PlayerState.A.deploymentComplete=false;check(R:IsActivePlayer(p)==false)
 R.State.PlayerState.A={deploymentComplete=true,role='soldier'};check(R:IsActivePlayer(p)==true)
 R.State.ActiveIdentity.A=false;check(R:IsActivePlayer(p)==false)
end)
test('bot identity retains native index and live membership',function()
 local R,S,p=fixture();p.id='0';R.State.ActiveIdentity['bot:1']=true;R.State.PlayerState['bot:1']={deploymentComplete=true}
 check(R:IsActivePlayer(p)==true);check(steamCalls==1 and indexCalls==1)
 p.index=2;check(R:IsActivePlayer(p)==false,'bot index retained across calls')
end)
test('custom slot callback remains before deployment',function()
 local R,S,p=fixture();local called=0
 R.IsSlotActivePlayer=function()called=called+1;R.State.PlayerState.A.deploymentComplete=false;return true end
 check(R:IsActivePlayer(p)==false);check(called==1)
end)
test('custom deployment result and callback order preserved',function()
 local R,S,p=fixture();local calls={};local slot=R.IsSlotActivePlayer
 R.IsSlotActivePlayer=function(self,actor)calls[#calls+1]='slot';return slot(self,actor)end
 S.IsDeployed=function(_,actor)calls[#calls+1]='deployment';check(actor==p);return 'custom-result'end
 check(R:IsActivePlayer(p)=='custom-result');check(table.concat(calls,',')=='slot,deployment')
end)
test('custom identity remains live between repeated queries',function()
 local R,S,p=fixture();local calls=0
 R.IdentityOf=function()calls=calls+1;return calls==1 and 'A'or'B'end
 check(R:IsActivePlayer(p)==false);check(calls==3,'custom identity provider bypassed or reordered')
end)
test('custom profile receives original actor and result',function()
 local R,S,p=fixture();local called=0
 R.GetPlayerState=function(_,actor)called=called+1;check(actor==p,'custom profile received identity string');return{deploymentComplete=false}end
 check(R:IsActivePlayer(p)==false);check(called==1)
 R.GetPlayerState=function(_,actor)actor.valid=false;return{deploymentComplete=true}end
 check(R:IsActivePlayer(p)==true,'original callback result changed');check(R:IsActivePlayer(p)==nil)
end)
test('custom actor/global validity APIs keep ordinary queries',function()
 local R,S,p=fixture();p.IsValid=function()return true end
 check(R:IsActivePlayer(p)==true);check(steamCalls==3)
 p.IsValid=nil;steamCalls=0;local previous=IsValid
 IsValid=function(actor)return previous(actor)end
 check(R:IsActivePlayer(p)==true);check(steamCalls==3);IsValid=previous
end)
test('custom Steam identity API retains every call',function()
 local R,S,p=fixture();local calls=0
 p.SteamID64=function()calls=calls+1;return calls==1 and'A'or'B'end
 check(R:IsActivePlayer(p)==false);check(calls==3,'custom native API bypassed')
end)
test('custom bot index API retains every call',function()
 local R,S,p=fixture();p.id='0';local calls=0
 p.EntIndex=function()calls=calls+1;return calls end
 R.State.ActiveIdentity={['bot:1']=true,['bot:2']=true};R.State.PlayerState={['bot:3']={deploymentComplete=false}}
 check(R:IsActivePlayer(p)==false);check(calls==3)
end)
test('metatable-backed state and maps retain ordinary access',function()
 local R,S,p=fixture();setmetatable(R.State,{})
 check(R:IsActivePlayer(p)==true);check(steamCalls==3)
 setmetatable(R.State,nil);setmetatable(R.State.ActiveIdentity,{__index=function()return true end})
 steamCalls=0;check(R:IsActivePlayer(p)==true);check(steamCalls==3)
 setmetatable(R.State.ActiveIdentity,nil);setmetatable(R.State.PlayerState,{})
 steamCalls=0;check(R:IsActivePlayer(p)==true);check(steamCalls==3)
end)
test('non-native controllers and absent engine metadata fall back',function()
 local R,S,p=fixture();p.nativePlayer=false;check(R:IsActivePlayer(p)==true);check(steamCalls==3)
 metaAvailable=false;R,S,p=fixture();steamCalls=0;check(R:IsActivePlayer(p)==true);check(steamCalls==3);metaAvailable=true
end)
test('mutated registry cannot bless a custom provider',function()
 local R,S,p=fixture();local called=0
 R.IdentityOf=function()called=called+1;return 'A'end
 R.PlayerQueryDefaults.IdentityOf=R.IdentityOf
 check(R:IsActivePlayer(p)==true);check(called==3,'mutable registry bypassed custom identity callback')
end)
test('changed default registry cannot reuse old handles',function()
 local R,S,p=fixture();R.PlayerQueryDefaults={};check(R:IsActivePlayer(p)==true);check(steamCalls==3)
end)
_G.type=luaType
print('PLAYER_ACTIVE_QUERY_PASS '..cases..' cases '..assertions..' assertions; per-call native query, live lifecycle and provider/native-API fallbacks')

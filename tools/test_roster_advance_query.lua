-- Production Tick parity against the retained source. Trace savings are not FPS evidence.
local root='gamemodes/legend_of_deborah/gamemode/lod/'
local fixture=assert(io.open('tools/test_enemy_roster.lua')):read('*a')
local cut=assert(fixture:find('local E,C=LOD.EnemyRoster,LOD.Climber',1,true))
local H=assert(load(fixture:sub(1,cut-1)..'\nreturn {actor=actor,hero=p,state=s,motion=motion,at=at}', '@roster_fixture'))()
local retained=dofile('tools/fixtures/roster_advance_query_retained.lua')
local sourceFile=assert(io.open(root..'sv_enemy_roster.lua'));local currentSource=sourceFile:read('*a');sourceFile:close()
local queryStart=assert(currentSource:find('function E:CanTargetFromHere(',1,true))
local queryFinish=assert(currentSource:find('local tickCanTargetFromHere=',queryStart,true))
local tickStart=assert(currentSource:find('function E:Tick(',queryFinish,true))
local tickFinish=assert(currentSource:find('-- One bounded projectile/attack service',tickStart,true))
local parentSource=currentSource:sub(1,queryStart-1)..retained.CanTargetFromHere
 ..currentSource:sub(queryFinish,tickStart-1)..retained.Tick..currentSource:sub(tickFinish)
local nativeGetInfo=debug.getinfo
local traces,traceBlocked,events=0,false,{}
local function trace(row) traces=traces+1;return {Hit=traceBlocked,HitPos=row.endpos} end
util.TraceLine=trace
-- Only the explicitly designated test boundary pretends to be native.
debug.getinfo=function(f,...) if f==trace then return {what='C'} end return nativeGetInfo(f,...) end
LOD.EnemyRoster=nil;assert(load(parentSource,'@retained_roster'))();local parent=LOD.EnemyRoster
LOD.EnemyRoster=nil;dofile(root..'sv_enemy_roster.lua');local candidate=LOD.EnemyRoster
local checks,cases=0,0
local function expect(v,m)checks=checks+1;assert(v,m)end
local flags={
 {'razor','LODRazorApproachUntil'}, {'link','LODLinkAdvanceUntil'}, {'edict','LODEdictAdvanceUntil'},
 {'companion','LODCompanionAdvanceUntil'}, {'discipline','LODDisciplineAdvanceUntil'},
 {'crossfire','LODCrossfireAdvanceUntil'}, {'resource','LODResourceAdvanceUntil'},
 {'spacing','LODSpacingAdvanceUntil'}, {'condition','LODConditionAdvanceUntil'},
 {'mobile','LODMobileAdvanceUntil'}, {'tactical','LODTacticalAdvanceUntil'},
 {'melee','LODMeleeAdvanceUntil'}, {'trap','LODTrapAdvanceUntil'}}
local function serialize(t)local out={} for i,v in ipairs(t)do out[i]=tostring(v)end return table.concat(out,'|')end
local function run(E,spec)
 LOD.EnemyRoster=E;H.at(100);events={};traces=0;traceBlocked=spec.blocked or false
 local d={kind=spec.kind or 'bullet',stationary=spec.stationary}
 if spec.family~='razor' then d[spec.family]=true end
 local id=spec.family=='razor' and 'razor' or 'advance_query_test'
 E.Definitions[id]=d
 local e=H.actor(id,Vector());e.LODHostile=true;e.LODActivated=true
 e.LODConfig={fireRange=1000,meleeDamage=1};e.LODNextAttack=spec.cooldown and 105 or 0
 e[spec.field]=spec.deadline or 101
 local p=H.hero;p.valid=not spec.invalid;p:SetPos(Vector(120,0,0));e.LODTarget=p
 e._RefreshTarget=function()events[#events+1]='refreshTarget'end
 e._RefreshRoute=function()events[#events+1]='refreshRoute'end
 e._AdvanceWaypoint=function()events[#events+1]='waypoint';return {pos=Vector(32,0,0)}end
 e._SetActivity=function(_,act)events[#events+1]='activity:'..tostring(act)end
 E.Prepare=function(self,a)events[#events+1]='prepare';a.LODRosterContext=self:Bind({},H.state)end
 E.CanCast=function()events[#events+1]='cast';return not spec.statusBlocked end
 E.AcquireTarget=function(_,target)
  events[#events+1]='acquire'
  if spec.mutate then e[spec.field]=spec.mutate end
  return IsValid(target)
 end
 E.Begin=function()events[#events+1]='begin';return true end
 local oldQuery=E.CanTargetFromHere
 if spec.foreign then E.CanTargetFromHere=function(self,...)
  expect(select('#',...)==2,'foreign query received private arguments')
  events[#events+1]='foreignQuery';return oldQuery(self,...)
 end end
 local oldOrigin,oldVisible,oldAcquire,oldRelease=E.Origin,E.Visible,E.AcquireTrace,E.ReleaseTrace
 if spec.provider=='origin' then E.Origin=function(...)return oldOrigin(...)end end
 if spec.provider=='visible' then E.Visible=function(...)return oldVisible(...)end end
 if spec.provider=='acquireTrace' then E.AcquireTrace=function(...)return oldAcquire(...)end end
 if spec.provider=='releaseTrace' then E.ReleaseTrace=function(...)return oldRelease(...)end end
 local oldTrace=util.TraceLine
 if spec.provider=='trace' then util.TraceLine=function(...)return trace(...)end end
 H.motion.Stop=function()events[#events+1]='stop'end
 H.motion.MoveToward=function()events[#events+1]='move'end
 H.motion.FaceToward=function()events[#events+1]='face'end
 local ok,value=pcall(E.Tick,E,e)
 local tickTraces=traces
 if spec.public then E:CanTargetFromHere(e,p);expect(traces>tickTraces,'public query skipped geometry');traces=tickTraces end
 E.CanTargetFromHere=oldQuery;E.Origin,E.Visible,E.AcquireTrace,E.ReleaseTrace=oldOrigin,oldVisible,oldAcquire,oldRelease;util.TraceLine=oldTrace;p.valid=true
 expect(ok,value)
 return {events=serialize(events),traces=traces,result=value,deadline=e[spec.field],target=e.LODTarget==p}
end
local function pair(spec,eliminates)
 cases=cases+1;local a,b=run(parent,spec),run(candidate,spec)
 expect(a.events==b.events,'Tick event/order parity: '..a.events..' vs '..b.events)
 expect(a.result==b.result and a.deadline==b.deadline and a.target==b.target,'Tick state/result parity')
 if eliminates then expect(a.traces>0 and b.traces==0,'forced advance did not eliminate the dead visibility query')
 else expect(a.traces==b.traces,'fallback trace behavior changed')end
end
for _,f in ipairs(flags)do
 local base={family=f[1],field=f[2]}
 local function test(extra,skip)local s={}for k,v in pairs(base)do s[k]=v end for k,v in pairs(extra or {})do s[k]=v end pair(s,skip)end
 test({public=true},true);test({blocked=true},true);test({deadline=100},false);test({deadline=99},false)
 test({invalid=true},false);test({statusBlocked=true},false);test({stationary=true,cooldown=true},false)
 test({mutate=99},false);test({deadline=99,mutate=101},true)
 test({foreign=true},false)
 for _,provider in ipairs({'origin','visible','acquireTrace','releaseTrace','trace'})do test({provider=provider},false)end
end
pair({family='mobile',field='LODMobileAdvanceUntil',kind='arc'},true)
pair({family='mobile',field='LODMobileAdvanceUntil',kind='beam',cooldown=true},false)
debug.getinfo=nativeGetInfo
print(('ROSTER_ADVANCE_QUERY_PASS cases=%d checks=%d'):format(cases,checks))

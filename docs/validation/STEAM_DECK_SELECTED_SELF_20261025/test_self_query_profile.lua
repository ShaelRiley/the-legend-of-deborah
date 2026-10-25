local source='/home/deck/deborah-recovery/bench_self_query_start.lua'
SERVER=true;local clock=0;local writes={};local timers={}
SysTime=function()return clock end
file={Read=function()return'{}'end,Write=function(path,v)writes[path]=v end};util={TableToJSON=function(v)return v end,JSONToTable=function()return{scope='managers-self-v1'}end}
timer={Create=function(id,_,_,fn)timers[id]=fn end,Remove=function(id)timers[id]=nil end}
local function setup()
 clock=0;writes={};LOD={RuntimeAudit={},EnemyRoster={},RPGStatusElements={}}
 local child=function(self,mode,...)
  assert(self==LOD.RPGStatusElements)
  if mode=='error'then error('sentinel')end
  if mode=='yield'then coroutine.yield('held')end
  clock=clock+.007;return false,nil,...
 end
 setmetatable(LOD.RPGStatusElements,{__index={Has=child}})
 local parent=function(self,mode,...)
  assert(self==LOD.EnemyRoster);clock=clock+.003
  local a,b,c,d=LOD.RPGStatusElements:Has(mode,...)
  clock=clock+.002;return a,b,c,d
 end
 LOD.EnemyRoster.Tick=parent;dofile(source);return parent,child,LOD.BenchQueryProfile
end
local parent,child,lease=setup();assert(#lease.bindings==2 and lease.sampling==1)
local a,b,c,d=LOD.EnemyRoster:Tick('pass','kept',nil);assert(a==false and b==nil and c=='kept'and d==nil)
lease:Stop('explicit');local j=writes['legend_of_deborah/bench_query_profile.json'];assert(j.restored and j.open_context_frames==0 and math.abs(j.root_ms-12)<.000001)
local sum=0;for _,r in ipairs(j.rows)do sum=sum+r.self_ms;assert(r.calls==r.completed_samples);if r.name=='EnemyRoster.Tick'then assert(math.abs(r.self_ms-5)<.000001 and math.abs(r.sampled_ms-12)<.000001)else assert(math.abs(r.self_ms-7)<.000001)end end;assert(math.abs(sum-j.root_ms)<.000001)
assert(LOD.EnemyRoster.Tick==parent and rawget(LOD.RPGStatusElements,'Has')==nil and LOD.RPGStatusElements.Has==child)
parent,child,lease=setup();local co=coroutine.create(function()return LOD.EnemyRoster:Tick('yield','kept',nil)end);local ok,value=coroutine.resume(co);assert(ok and value=='held');LOD.EnemyRoster:Tick('pass');ok,a,b,c,d=coroutine.resume(co);assert(ok and a==false and b==nil and c=='kept'and d==nil);lease:Stop('yield');j=writes['legend_of_deborah/bench_query_profile.json'];assert(j.open_context_frames==0 and j.context_count==2)
parent,child,lease=setup();local ok,err=pcall(function()LOD.EnemyRoster:Tick('error')end);assert(not ok and tostring(err):find('sentinel'));lease:Stop('error');j=writes['legend_of_deborah/bench_query_profile.json'];assert(j.restored and j.open_context_frames==2,'Error must invalidate depth conservation')
parent,child,lease=setup();local foreign=function()end;LOD.EnemyRoster.Tick=foreign;lease:Stop('foreign');assert(LOD.EnemyRoster.Tick==foreign and not writes['legend_of_deborah/bench_query_profile.json'].restored)
parent,child,lease=setup();assert(timers.LOD_BenchQueryProfileLease);timers.LOD_BenchQueryProfileLease();assert(not LOD.BenchQueryProfile and LOD.EnemyRoster.Tick==parent)
print('SELF_QUERY_PROFILE_PASS exactnested5/7/12ms/conservation/main-coroutineisolation/returnsnils/yield/errorsinvalidate/ownedinheritedrestore/foreignowner/lease')

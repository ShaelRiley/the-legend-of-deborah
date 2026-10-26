CLIENT=true;local clock=0;local writes,hooks,timers={},{},{}
SysTime=function()clock=clock+.000001;return clock end
util={TableToJSON=function(v)return v end};file={Write=function(p,v)writes[p]=v;clock=clock+.000002 end}
hook={Add=function(event,id,fn)hooks[id]=fn end,Remove=function(event,id)hooks[id]=nil end};timer={Create=function(id,_,_,fn)timers[id]=fn end,Remove=function(id)timers[id]=nil end}
local calls=0
local function setup()
 writes={};hooks={};timers={};calls=0;LOD={RuntimeAudit={}}
 local original=function(self,reason,...)calls=calls+1;self.PerformanceCapture=nil;return false,nil,...end
 LOD.RuntimeAudit.StopPerformanceCapture=original;dofile('/home/deck/deborah-recovery/bench_aligned_window.lua');return original,LOD.BenchAlignedWindow
end
local original,lease=setup();local A=LOD.RuntimeAudit
hooks.LOD_BenchAlignedFirst();assert(not lease.first)
local c={last=42,all={1,2,3},start=41,finish=101,created=38};A.PerformanceCapture=c;hooks.LOD_BenchAlignedFirst();assert(lease.first.boundary_sys==42 and not hooks.LOD_BenchAlignedFirst)
c.last=43;local a,b,d,e=A:StopPerformanceCapture('complete','kept',nil);assert(a==false and b==nil and d=='kept'and e==nil and calls==1)
local j=writes['legend_of_deborah/bench_aligned_window.json'];assert(j.passed and j.restored and j.first.boundary_sys==42 and j.last.boundary_sys==43 and j.frames==3 and A.StopPerformanceCapture==original and not LOD.BenchAlignedWindow and not timers.LOD_BenchAlignedLease)
assert(j.first.sys_after>=j.first.sys_before and j.last.sys_after>=j.last.sys_before)
original,lease=setup();timers.LOD_BenchAlignedLease();assert(LOD.RuntimeAudit.StopPerformanceCapture==original and not LOD.BenchAlignedWindow and calls==0 and writes['legend_of_deborah/bench_aligned_window.json'].reason=='lease')
original,lease=setup();A=LOD.RuntimeAudit;A.PerformanceCapture={last=42,all={}};hooks.LOD_BenchAlignedFirst();local foreign=function()end;A.StopPerformanceCapture=foreign;lease.wrapper(A,'complete');j=writes['legend_of_deborah/bench_aligned_window.json'];assert(not j.passed and not j.restored and A.StopPerformanceCapture==foreign)
print('ALIGNED_WINDOW_PASS firstlastactualboundaries/clockbrackets/varargsnils/ownedrestore/foreignowner/lease/noAIproviders')

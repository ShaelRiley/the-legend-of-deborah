CLIENT=true;local clock,writes,hooks,timers,commands,registry,variant=0,{},{},{},{},{},'off'
SysTime=function()clock=clock+.000001;return clock end
util={TableToJSON=function(v)return v end,JSONToTable=function()return{variant=variant}end};file={Read=function()return'{}'end,Write=function(p,v)writes[p]=v;clock=clock+.000002 end}
hook={Add=function(_,id,fn)hooks[id]=fn end,Remove=function(_,id)hooks[id]=nil end};timer={Create=function(id,_,_,fn)timers[id]=fn end,Remove=function(id)timers[id]=nil end}
concommand={GetTable=function()return registry end,Add=function(id,fn)registry[id]=fn end,Remove=function(id)registry[id]=nil end}
RunConsoleCommand=function(cmd,...)
 commands[#commands+1]=cmd
 if registry[cmd]then registry[cmd](nil,cmd,{...})end
end
for _,mode in ipairs({'off','on'})do
 variant=mode;clock=100;writes={};hooks={};timers={};commands={};registry={};local calls=0
 local original=function(self,reason,...)calls=calls+1;self.PerformanceCapture=nil;return false,nil,...end
 LOD={RuntimeAudit={StopPerformanceCapture=original}};dofile('/home/deck/deborah-recovery/bench_engine_window.lua');local A=LOD.RuntimeAudit;local c={last=101,all={1,2},start=101,finish=161,created=98};A.PerformanceCapture=c;clock=101.1;hooks.LOD_BenchAlignedFirst();assert(not hooks.LOD_BenchAlignedFirst and timers.LOD_BenchEngineOff)
 clock=160.5;timers.LOD_BenchEngineOff();c.last=160.9;clock=161;local a,b,d,e=A:StopPerformanceCapture('complete','kept',nil);assert(a==false and b==nil and d=='kept'and e==nil and calls==1)
 local j=writes['legend_of_deborah/bench_aligned_window.json'];assert(j.passed and j.restored and j.engine_first.boundary_sys>=j.first.boundary_sys and j.engine_last.boundary_sys<=j.last.boundary_sys and j.variant==mode);assert(not LOD.BenchAlignedWindow and A.StopPerformanceCapture==original and not timers.LOD_BenchEngineOff and registry.lod_bench_engine_boundary==nil)
 if mode=='on'then assert(commands[1]=='vprof_reset'and commands[2]=='vprof_on')else assert(#commands==2)end
end
print('ENGINE_WINDOW_PASS offon/samecoarsemarkers/actualqueuedcallbackstamps/insideframewindow/noAIproviders/varargsnils/ownedretirement')

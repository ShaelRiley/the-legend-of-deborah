assert(CLIENT and not LOD.BenchAlignedWindow)
local arm=assert(util.JSONToTable(file.Read('legend_of_deborah/bench_engine_window_arm.json','DATA')));assert(arm.variant=='off'or arm.variant=='on')
local A=assert(LOD.RuntimeAudit);local original=assert(A.StopPerformanceCapture)
assert(not A.CPUProfile and not A.PerformanceCapture)
local lease={original=original,active=true,created=SysTime()};LOD.BenchAlignedWindow=lease
local function mark(label,boundary)
 local before=SysTime();file.Write('legend_of_deborah/bench_aligned_'..label..'.json',util.TableToJSON({label=label,boundary_sys=boundary,sys_before=before},true));local after=SysTime()
 return{boundary_sys=boundary,sys_before=before,sys_after=after,filename='bench_aligned_'..label..'.json'}
end
local commandName='lod_bench_engine_boundary'
local boundary=function(_,_,args)
 local label=args[1];assert(label=='engine_first'or label=='engine_last')
 lease[label]=mark(label,SysTime())
end
assert(not concommand.GetTable()[commandName]);concommand.Add(commandName,boundary)
local function queueBoundary(label)
 if arm.variant=='on'then
  if label=='engine_first'then RunConsoleCommand('vprof_reset');RunConsoleCommand('vprof_on')else RunConsoleCommand('vprof_off')end
 end
 RunConsoleCommand(commandName,label)
end
local function restore()
 hook.Remove('PreRender','LOD_BenchAlignedFirst');timer.Remove('LOD_BenchAlignedLease');timer.Remove('LOD_BenchEngineOff')
 if concommand.GetTable()[commandName]==boundary then concommand.Remove(commandName)end
 if arm.variant=='on'then RunConsoleCommand('vprof_off')end
 local owned=A.StopPerformanceCapture==lease.wrapper
 if owned then A.StopPerformanceCapture=original end
 lease.active=false;LOD.BenchAlignedWindow=nil;return owned
end
lease.wrapper=function(self,reason,...)
 local c=self.PerformanceCapture
 if c and c.last and lease.first then
  lease.last=mark('last',c.last);local valid=lease.engine_first and lease.engine_last and lease.engine_first.boundary_sys>=lease.first.boundary_sys and lease.engine_last.boundary_sys<=c.last;local restored=restore()
  file.Write('legend_of_deborah/bench_aligned_window.json',util.TableToJSON({passed=restored and reason=='complete' and valid==true,restored=restored,variant=arm.variant,engine_first=lease.engine_first,engine_last=lease.engine_last,reason=reason,first=lease.first,last=lease.last,planned_start=c.start,planned_finish=c.finish,frames=#c.all,created=c.created,scope='First/last actualPreRender sample timestamps, withSysTime brackets around DATA writes. Hostusesfilemtime andbracketedrealtime-monotonic mapping toalignnative trace toactualframeintervals; exclude setup/warmup/teardown. One firstframe mark andone stopprovider, no per-AI wrappers. Same marker inoff/on controls.'},true))
 else restore();file.Write('legend_of_deborah/bench_aligned_window.json',util.TableToJSON({passed=false,restored=A.StopPerformanceCapture==original,reason=reason},true))end
 return original(self,reason,...)
end
A.StopPerformanceCapture=lease.wrapper
hook.Add('PreRender','LOD_BenchAlignedFirst',function()
 local c=A.PerformanceCapture
 if c and c.last and not lease.first then lease.first=mark('first',c.last);hook.Remove('PreRender','LOD_BenchAlignedFirst');queueBoundary('engine_first');timer.Create('LOD_BenchEngineOff',math.max(.01,c.finish-SysTime()-.5),1,function()if lease.active then queueBoundary('engine_last')end end)end
end)
timer.Create('LOD_BenchAlignedLease',120,1,function()local restored=restore();file.Write('legend_of_deborah/bench_aligned_window.json',util.TableToJSON({passed=false,restored=restored,reason='lease'},true))end)
file.Write('legend_of_deborah/bench_aligned_window_started.json',util.TableToJSON({passed=true,active=A.StopPerformanceCapture==lease.wrapper},true))

assert(CLIENT and not LOD.BenchAlignedWindow)
local A=assert(LOD.RuntimeAudit);local original=assert(A.StopPerformanceCapture)
assert(not A.CPUProfile and not A.PerformanceCapture)
local lease={original=original,active=true,created=SysTime()};LOD.BenchAlignedWindow=lease
local function mark(label,boundary)
 local before=SysTime();file.Write('legend_of_deborah/bench_aligned_'..label..'.json',util.TableToJSON({label=label,boundary_sys=boundary,sys_before=before},true));local after=SysTime()
 return{boundary_sys=boundary,sys_before=before,sys_after=after,filename='bench_aligned_'..label..'.json'}
end
local function restore()
 hook.Remove('PreRender','LOD_BenchAlignedFirst');timer.Remove('LOD_BenchAlignedLease')
 local owned=A.StopPerformanceCapture==lease.wrapper
 if owned then A.StopPerformanceCapture=original end
 lease.active=false;LOD.BenchAlignedWindow=nil;return owned
end
lease.wrapper=function(self,reason,...)
 local c=self.PerformanceCapture
 if c and c.last and lease.first then
  lease.last=mark('last',c.last);local restored=restore()
  file.Write('legend_of_deborah/bench_aligned_window.json',util.TableToJSON({passed=restored and reason=='complete',restored=restored,reason=reason,first=lease.first,last=lease.last,planned_start=c.start,planned_finish=c.finish,frames=#c.all,created=c.created,scope='First/last actualPreRender sample timestamps, withSysTime brackets around DATA writes. Hostusesfilemtime andbracketedrealtime-monotonic mapping toalignnative trace toactualframeintervals; exclude setup/warmup/teardown. One firstframe mark andone stopprovider, no per-AI wrappers. Same marker inoff/on controls.'},true))
 else restore();file.Write('legend_of_deborah/bench_aligned_window.json',util.TableToJSON({passed=false,restored=A.StopPerformanceCapture==original,reason=reason},true))end
 return original(self,reason,...)
end
A.StopPerformanceCapture=lease.wrapper
hook.Add('PreRender','LOD_BenchAlignedFirst',function()
 local c=A.PerformanceCapture
 if c and c.last and not lease.first then lease.first=mark('first',c.last);hook.Remove('PreRender','LOD_BenchAlignedFirst')end
end)
timer.Create('LOD_BenchAlignedLease',120,1,function()local restored=restore();file.Write('legend_of_deborah/bench_aligned_window.json',util.TableToJSON({passed=false,restored=restored,reason='lease'},true))end)
file.Write('legend_of_deborah/bench_aligned_window_started.json',util.TableToJSON({passed=true,active=A.StopPerformanceCapture==lease.wrapper},true))

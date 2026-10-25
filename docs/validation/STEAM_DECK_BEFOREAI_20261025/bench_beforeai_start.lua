assert(SERVER and not LOD.BenchBeforeAI and not LOD.BenchQueryProfile)
assert(not LOD.RuntimeAudit.CPUProfile)
local spec=assert(util.JSONToTable(file.Read('legend_of_deborah/bench_beforeai_arm.json','DATA')))
assert(spec.variant=='off' or spec.variant=='on')
local owner=assert(LOD.EntrySafety);local original=assert(owner.BeforeAI)
local info=debug.getinfo(original,'S');assert(info.linedefined==496 and string.find(info.source,'sv_entry_safety.lua',1,true))
local capacity=524288
local lease={variant=spec.variant,original=original,previous_raw=rawget(owner,'BeforeAI'),calls=0,completed=0,active=0,max_active=0,overflow=false,starts={},durations={}}
LOD.BenchBeforeAI=lease
local function mark(label)
 local before=SysTime();local name='bench_beforeai_clock_'..label..'.json'
 file.Write('legend_of_deborah/'..name,util.TableToJSON({sys_before=before},true));local after=SysTime()
 return{sys_before=before,sys_after=after,filename=name}
end
local memory=collectgarbage('count')
if spec.variant=='on' then for i=1,capacity do lease.starts[i]=0;lease.durations[i]=0 end end
lease.allocated_kb=collectgarbage('count')-memory;lease.clock_start=mark('start')
local function finish(index,start,...)
 lease.durations[index]=SysTime()-start;lease.completed=lease.completed+1;lease.active=lease.active-1
 return ...
end
lease.wrapper=function(...)
 if lease.stopped then return original(...) end
 local index=lease.calls+1;lease.calls=index
 if index>capacity then lease.overflow=true;return original(...) end
 lease.active=lease.active+1;if lease.active>lease.max_active then lease.max_active=lease.active end
 local start=SysTime();lease.starts[index]=start
 return finish(index,start,original(...))
end
if spec.variant=='on' then owner.BeforeAI=lease.wrapper end
function lease:Stop(reason)
 local owned=owner.BeforeAI==(self.variant=='on' and self.wrapper or original)
 if owned and self.variant=='on' then owner.BeforeAI=self.previous_raw end
 self.stopped=true;self.clock_end=mark('end');timer.Remove('LOD_BenchBeforeAILease');LOD.BenchBeforeAI=nil
 for i=math.min(self.calls,capacity)+1,capacity do self.starts[i]=nil;self.durations[i]=nil end
 local result={passed=owned and not self.overflow and self.calls==self.completed and self.active==0,restored=owned,reason=reason,variant=self.variant,calls=self.calls,completed=self.completed,max_active=self.max_active,overflow=self.overflow,allocated_kb=self.allocated_kb,clock_start=self.clock_start,clock_end=self.clock_end,starts=self.starts,durations=self.durations,scope='Inclusive wall time; postselect actual rendered-frame window; off calls are unmeasured, not zero gameplay calls.'}
 file.Write('legend_of_deborah/bench_beforeai.json',util.TableToJSON(result))
 return result
end
timer.Create('LOD_BenchBeforeAILease',120,1,function()lease:Stop('lease')end)
file.Write('legend_of_deborah/bench_beforeai_started.json',util.TableToJSON({passed=true,variant=spec.variant,bindings=spec.variant=='on' and 1 or 0,allocated_kb=lease.allocated_kb},true))

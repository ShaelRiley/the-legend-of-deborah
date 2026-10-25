from pathlib import Path
import json,re,sys,bisect
arm=Path(sys.argv[1]);n=json.loads((arm/'native-frame-attribution.json').read_text());w=n['window'];start,end=w['start_mono'],w['end_mono'];events=[]
for line in(arm/'native-script.txt').read_text().splitlines():
 if'PERF_RECORD_SWITCH'not in line:continue
 m=re.search(r'\s(\d+\.\d+):',line)
 if m:events.append((float(m.group(1)),'OUT'in line))
state=None;previous=start;segments=[]
for t,out in sorted(events):
 if t<start:state=out;continue
 if t>end:break
 segments.append((previous,t,state));previous=t;state=out
segments.append((previous,end,state));assert all(v[2]is not None for v in segments)
boundaries=[v[0]for v in segments]+[end];prefix=[0.]
for a,b,off in segments:prefix.append(prefix[-1]+(b-a if off else 0.))
def off_until(t):
 t=max(start,min(end,t));i=min(len(segments)-1,max(0,bisect.bisect_right(boundaries,t)-1));a,b,off=segments[i];return prefix[i]+(t-a if off else 0.)
def describe(a,b,extra):
 guard=w['alignment_uncertainty_ms']/2000+.001;a=max(start,a+guard);b=min(end,b-guard);assert b>a;off=off_until(b)-off_until(a);return dict(extra,measured_seconds=b-a,off_cpu_seconds=off,on_cpu_percent=100*(b-a-off)/(b-a))
a=json.loads((arm/'bench_aligned_window.json').read_text());s=(arm/'performance_client_latest.txt').read_text();p=json.loads(s[s.index('{'):]);offset=sum(w['common_offset_seconds'])/2;t=a['first']['boundary_sys']+offset;episodes=[];slow=[];run_start=None;run_seconds=0.
for ms in p['frame_timeline']['samples_ms']:
 stop=t+ms/1000
 if ms>25:
  if run_start is None:run_start=t
  run_seconds+=ms/1000
 elif run_start is not None:
  if run_seconds>=2:episodes.append(describe(run_start,t,{'frame_seconds':run_seconds}))
  run_start=None;run_seconds=0.
 if ms>=100:slow.append(describe(t,stop,{'frame_ms':ms}))
 t=stop
if run_start is not None and run_seconds>=2:episodes.append(describe(run_start,t,{'frame_seconds':run_seconds}))
j={'scope':'Main-thread scheduler state inside eachactualslowframe/prolongedbelow25ms-budget episode. Timestampmidpoint reconstruction withalignment+1msrounding guardtrimmedfrombothedges; onlyinsideactualtracewindow. OffCPUincludeskernelblocking/wakeuprunqueue; no namedwaitcause orLuaCPU/additivebudgetclaim.','prolonged_below40_episodes':episodes,'frames_ge100ms':slow,'episode_on_cpu_percent_range':[min(v['on_cpu_percent']for v in episodes),max(v['on_cpu_percent']for v in episodes)]if episodes else None,'slow_frame_on_cpu_percent_range':[min(v['on_cpu_percent']for v in slow),max(v['on_cpu_percent']for v in slow)]if slow else None,'slow_frame_off_cpu_seconds_total':sum(v['off_cpu_seconds']for v in slow)}
(arm/'native-slow-frame-attribution.json').write_text(json.dumps(j,indent=2)+'\n');print(arm.name,'episodes',len(episodes),j['episode_on_cpu_percent_range'],'slowframes',len(slow),j['slow_frame_on_cpu_percent_range'],'offslowtotal',j['slow_frame_off_cpu_seconds_total'])

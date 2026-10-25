from pathlib import Path
import json,sys,math,statistics,bisect
root=Path(sys.argv[1]);rows=[]
def read(p):return json.loads(p.read_text())
def offsets(arm,marks):
 bounds=[]
 for a in marks:
  m=read(arm/(a['filename']+'.mtime.json'));lo=m['host_monotonic_lo_ns']/1e9;hi=m['host_monotonic_hi_ns']/1e9;real=m['host_realtime_ns']/1e9;mt=m['mtime_ns']/1e9
  bounds.append([mt+lo-real-a['sys_after']-.002,mt+hi-real-a['sys_before']+.002])
 lo=max(a[0] for a in bounds);hi=min(a[1] for a in bounds);assert lo<=hi,('inconsistent clock',arm,bounds)
 return [lo,hi]
def pct(a,q):
 a=sorted(a);return a[min(len(a)-1,max(0,math.ceil(q*len(a))-1))] if a else None
for arm in sorted(root.glob('arm*')):
 if not(arm/'analysis.json').exists():continue
 a=read(arm/'analysis.json');j=read(arm/'bench_aligned_window.json');p=read(arm/'bench_beforeai.json');raw=(arm/'performance_client_latest.txt').read_text();perf=json.loads(raw[raw.index('{'):]);frames=perf['frame_timeline']['samples_ms'];assert j['frames']==len(frames)==a['active']['frames'];assert abs(sum(frames)/1000-(j['last']['boundary_sys']-j['first']['boundary_sys']))<.002
 assert p['passed'] and p['restored'] and p['reason']=='explicit' and not p['overflow'];assert p['calls']==p['completed'];assert p['max_active']<=1
 co=offsets(arm,[j['first'],j['last']]);so=offsets(arm,[p['clock_start'],p['clock_end']]);delta=[co[0]-so[1],co[1]-so[0]];nom=0 if delta[0]<=0<=delta[1] else statistics.mean(delta)
 row={'arm':arm.name,'variant':p['variant'],'metrics':a['active'],'source':read(arm/'condition.json').get('sha'),'capture_checks_passed':a['capture_checks_passed'],'alignment':{'client_host_offset_seconds':co,'server_host_offset_seconds':so,'server_minus_client_seconds_bounds':delta,'nominal_delta_seconds':nom,'uncertainty_ms':(delta[1]-delta[0])*1000},'probe_restored':True,'max_active':p['max_active'],'allocated_kb':p['allocated_kb']}
 if p['variant']=='on':
  starts=p['starts'];dur=p['durations'];assert len(starts)==len(dur)==p['calls'];assert all(d>=0 for d in dur)
  first=j['first']['boundary_sys'];last=j['last']['boundary_sys'];N=len(frames)
  def window(x,y):
   entries=sum(x<=s<y for s in starts);overlap=sum(max(0,min(s+d,y)-max(s,x))for s,d in zip(starts,dur));cross=sum(s<x<s+d or s<y<s+d for s,d in zip(starts,dur));return{'calls_entered':entries,'inclusive_overlap_ms':overlap*1000,'inclusive_wall_ms_per_rendered_frame':overlap*1000/N,'boundary_crossing_calls':cross}
  nominal=window(first+nom,last+nom);lower=window(first+delta[1],last+delta[0]);upper=window(first+delta[0],last+delta[1]);selected=[(s,d)for s,d in zip(starts,dur)if first+nom<=s<last+nom];cost=[0.]*N;bounds=[first+nom]
  for ms in frames:bounds.append(bounds[-1]+ms/1000)
  for s,d in zip(starts,dur):
   end=min(last+nom,s+d);pos=max(first+nom,s)
   if end<=pos:continue
   i=max(0,bisect.bisect_right(bounds,pos)-1)
   while i<N and pos<end:
    e=min(end,bounds[i+1]);cost[i]+=max(0,e-pos)*1000;pos=e;i+=1
  ds=[d*1000 for _,d in selected];top=sorted(range(N),key=lambda i:cost[i],reverse=True)[:15];long=[{'offset_seconds':s-(first+nom),'wall_ms':d*1000}for s,d in selected if d>=.010]
  row['beforeai']={'corresponding_rendered_frames':N,'window_seconds':last-first,'nominal':nominal,'alignment_lower':lower,'alignment_upper':upper,'entered_calls_per_frame':nominal['calls_entered']/N,'call_wall_ms':{'median':pct(ds,.5),'p95':pct(ds,.95),'p99':pct(ds,.99),'max':max(ds)if ds else None},'calls_ge10ms':long,'frame_cost_p95_ms':pct(cost,.95),'frame_cost_p99_ms':pct(cost,.99),'top_cost_frames':[{'frame':i,'frame_ms':frames[i],'inclusive_beforeai_ms':cost[i]}for i in top], 'limits':'Inclusive elapsed wall time only, includes native work/preemption/wait; not exclusive CPU. max_active<=1 observed but native internals opaque. No sum with overlapping NextBot/movement. FS clocks frozen2msguards; nominal same-process clock if compatible, interval bounds reported. Cost excludes recorder work before first timestamp/after finish timestamp; matched observer screen captures total perturbation.'}
 else:row['beforeai']={'calls':'unmeasured in observer-off; no wrapper','cost':'unmeasured'}
 (arm/'beforeai-attribution.json').write_text(json.dumps(row,indent=2)+'\n');rows.append(row)
metrics=['fps','p95_ms','p99_ms','max_ms','one_percent_low_fps','longest_below_budget_seconds'];off=[r for r in rows if r['variant']=='off'];on=[r for r in rows if r['variant']=='on'];means={v:{m:statistics.mean(r['metrics'][m]for r in rs)for m in metrics}for v,rs in [('off',off),('on',on)] if rs}
screen=None
if off and on:
 fps_off=[r['metrics']['fps']for r in off];fps_on=[r['metrics']['fps']for r in on]
 screen={'mean_throughput_penalty_percent':100*(1-means['on']['fps']/means['off']['fps']),'control_fps_range':[min(fps_off),max(fps_off)],'control_range_percent_of_mean':100*(max(fps_off)-min(fps_off))/statistics.mean(fps_off),'all_pair_penalty_percent_range':[100*(1-max(fps_on)/min(fps_off)),100*(1-min(fps_on)/max(fps_off))],'metric_change_percent_on_vs_off':{m:100*(means['on'][m]/means['off'][m]-1)for m in metrics},'limits':'Descriptive repeated short runs, not a statistical confidence interval. Worst cross-condition pairing plus control spread screen unresolved 5% bound conservatively; mean below5 alone insufficient. Pacing must also be interpreted. Ordinary variation not source gain.'}
result={'root':str(root),'rows':rows,'means':means,'observer_screen':screen,'source_change':False}
(root/'beforeai-summary.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps({'arms':[{'arm':r['arm'],'metrics':r['metrics'],'beforeai':{k:v for k,v in r['beforeai'].items()if k not in['top_cost_frames','calls_ge10ms','limits']}}for r in rows],'means':means,'observer_screen':screen},indent=2))

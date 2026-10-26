from pathlib import Path
import json,re,sys,math
arm=Path(sys.argv[1]);j=json.loads((arm/'bench_aligned_window.json').read_text());assert j['passed']and j['restored'];a=j['engine_first']['boundary_sys'];b=j['engine_last']['boundary_sys'];assert j['first']['boundary_sys']<=a<b<=j['last']['boundary_sys']
s=(arm/'performance_client_latest.txt').read_text();perf=json.loads(s[s.index('{'):]);t=j['first']['boundary_sys'];samples=[]
for dt in perf['frame_timeline']['samples_ms']:
 end=t+dt/1000
 # Only complete rendered intervals inside the actual processed native commands.
 if t>=a and end<=b:samples.append(dt)
 t=end
assert samples
v=sorted(samples);n=len(v);seconds=sum(v)/1000;worst=running=0.;below=0.
for x in samples:
 if x>25:running+=x/1000;below+=x/1000;worst=max(worst,running)
 else:running=0.
subset={'frames':n,'seconds':seconds,'fps':n/seconds,'median_ms':v[(n-1)//2],'p95_ms':v[max(0,__import__('math').ceil(n*.95)-1)],'p99_ms':v[max(0,__import__('math').ceil(n*.99)-1)],'one_percent_low_fps':1000*math.ceil(n*.01)/sum(v[-math.ceil(n*.01):]),'max_ms':v[-1],'below40_seconds':below,'longest_below40_seconds':worst}
result={'variant':j['variant'],'engine_window_sys':[a,b],'command_window_seconds':b-a,'full_frame_capture_seconds':perf['active']['seconds'],'matching_complete_frame_subset':subset,'scope':'Actual native on/off command callbacks lie inside actualframecapture; reported subset includesonlywholeframeintervalsbetween them. VProf uses its own CEngine::Frame count denominator; no divisionbyfull60sFPSframes. Queueedges may partialengineframes; retainownengineframecount/context. Setup/warmup/reportgeneration outside nativeprofilewindow.'}
if j['variant']=='on':
 text=(arm/'native-vprof-aligned.log').read_text();pattern=re.compile(r'^\s*([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+([\d.]+)\s+(\d+)\s+([\d.]+)\s+(.*)$');rows=[];stack=[];outside_roots=[];started=False
 for line in text.splitlines():
  m=pattern.match(line)
  if not m:continue
  tail=m.group(9);depth=tail.count('|');name=tail.replace('|','').strip()
  if not started:
   if name!='CEngine::Frame':outside_roots.append(line);continue
   started=True
  stack=stack[:depth];path=' > '.join(stack+[name]);stack.append(name)
  rows.append({'name':name,'inclusive_ms':float(m.group(1)),'self_ms':float(m.group(2)),'per_frame_ms':float(m.group(3)),'self_per_frame_ms':float(m.group(4)),'count':int(m.group(7)),'peak_ms':float(m.group(8)),'path':path})
 assert rows and rows[0]['name']=='CEngine::Frame';root=rows[0];lo=math.ceil(root['inclusive_ms']/(root['per_frame_ms']+.0005));hi=math.floor(root['inclusive_ms']/(root['per_frame_ms']-.0005));assert lo==hi,('Ambiguousnativeframecount',lo,hi);result.update(native_frame_sample_inference_interval=[lo,hi],engine_frame_calls=root['count'],native_frame_samples_inferred=round(root['inclusive_ms']/root['per_frame_ms']),leading_outside_root_lines=outside_roots,denominator_note='NativeAvgTimePerFrame columns retainedasreported. EngineFramecallcount maydifferbyonefromnativeglobalframesamples duepartialqueuedcommandedge. Uniqueintegernativeframesamples inferredfromroot sum/reportedaverage; neverdividebyrawFPSframes.',engine_measured_ms=root['inclusive_ms'],engine_frame_average_ms=root['per_frame_ms'],hierarchy_rows=rows,top_self=sorted(rows,key=lambda x:x['self_ms'],reverse=True)[:22])
(arm/'engine-frame-attribution.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps({k:v for k,v in result.items()if k!='hierarchy_rows'},indent=2))

from pathlib import Path
import json,re,subprocess,sys,collections,struct
arm=Path(sys.argv[1]);j=json.loads((arm/'bench_aligned_window.json').read_text());assert j['passed']and j['restored']
bounds=[]
for name in ['first','last']:
 a=j[name];m=json.loads((arm/(a['filename']+'.mtime.json')).read_text());lo=m['host_monotonic_lo_ns']/1e9;hi=m['host_monotonic_hi_ns']/1e9;real=m['host_realtime_ns']/1e9;mtime=m['mtime_ns']/1e9
 # Frozen +/-2ms FS coarse-clock guard; do not expand after inspecting results.
 bounds.append((mtime+lo-real-a['sys_after']-.002,mtime+hi-real-a['sys_before']+.002))
offset_lo=max(a[0]for a in bounds);offset_hi=min(a[1]for a in bounds);assert offset_lo<=offset_hi,('Clock brackets inconsistent',bounds)
start=j['first']['boundary_sys']+offset_hi;end=j['last']['boundary_sys']+offset_lo;assert end>start
s=(arm/'performance_client_latest.txt').read_text();perf=json.loads(s[s.index('{'):]);assert j['frames']==len(perf['frame_timeline']['samples_ms']);assert abs((j['last']['boundary_sys']-j['first']['boundary_sys'])-sum(perf['frame_timeline']['samples_ms'])/1000)<.002
condition={'scope':'Conservative native trace window lies inside actual first-last sampledframeinterval using2msFSclockguard andSysTimewritebrackets. Samples outside excluded. No setup/warmup/teardown quantitativetotals. Nativewindow is slightly shorter; no conversionusingfullcaptureframecount.','offset_bounds_seconds':bounds,'common_offset_seconds':[offset_lo,offset_hi],'alignment_uncertainty_ms':(offset_hi-offset_lo)*1000,'start_mono':start,'end_mono':end,'seconds':end-start,'frame_capture_seconds':perf['active']['seconds']}
(arm/'aligned-native-window.json').write_text(json.dumps(condition,indent=2)+'\n')
data=arm/'native-main.perf.data'
if not data.exists():print(json.dumps(condition));sys.exit(0)
script=arm/'native-script.txt'
with script.open('w')as out, (arm/'native-script.stderr').open('w')as err:subprocess.run(['perf','script','--ns','--show-switch-events','--show-lost-events','-i',str(data),'-F','comm,pid,tid,time,event,ip,sym,dso,period'],stdout=out,stderr=err,check=True,timeout=30)
maps=[]
for line in (arm/'native-main-maps.txt').read_text().splitlines():
 a=line.split(maxsplit=5)
 if len(a)>=5:
  low,high=(int(v,16)for v in a[0].split('-'));maps.append((low,high,a[5]if len(a)==6 else'[anonymous]',int(a[2],16),a[1]))
# Wine maps PE executable sections anonymously, but loaded file headers retain
# their actual base. SizeOfImage provides a bounded module range, not symbols.
images=[]
for lo,hi,path,off,prot in maps:
 if off!=0 or not path.lower().endswith(('.dll','.exe')):continue
 try:
  with Path(path).open('rb')as f:data=f.read(4096)
  if data[:2]!=b'MZ':continue
  pe=struct.unpack_from('<I',data,0x3c)[0]
  if pe+96>len(data)or data[pe:pe+4]!=b'PE\0\0':continue
  opt=pe+24;magic=struct.unpack_from('<H',data,opt)[0]
  if magic not in (0x10b,0x20b):continue
  size=struct.unpack_from('<I',data,opt+56)[0]
  if not(4096<=size<=536870912):continue
  if any(lo==a and path==name for a,b,name in images):continue
  images.append((lo,lo+size,path))
 except(OSError,struct.error):continue
for i,(lo,hi,path)in enumerate(images):
 for a,b,name in images[i+1:]:assert hi<=a or b<=lo,('OverlappingPEimages',path,name)
def mapping(ip):
 for lo,hi,path in images:
  if lo<=ip<hi:return path
 for lo,hi,path,off,prot in maps:
  if lo<=ip<hi:return path
 return'[unmapped]'
samples=[];switches=[];lost=[];unparsed=[]
for line in script.read_text().splitlines():
 t=re.search(r'\s(\d+\.\d+):',line)
 if not t:continue
 t=float(t.group(1))
 if 'PERF_RECORD_SWITCH'in line:switches.append((t,'OUT'in line,'preempted'if'preempt'in line.lower()else'other'));continue
 if 'LOST'in line:lost.append(line);continue
 if not(start<=t<=end):continue
 m=re.search(r':\s+(\d+)\s+cpu-clock:u:\s+([0-9a-f]+)\s+(.*?)\s+\((.*)\)\s*$',line)
 if not m:
  if'cpu-clock'in line:unparsed.append(line)
  continue
 period=int(m.group(1));ip=int(m.group(2),16);symbol=m.group(3);dso=m.group(4);path=mapping(ip)
 if dso=='[unknown]'or'/tmp/perf-'in dso:dso=path
 samples.append((t,period,ip,symbol,dso,path))
assert samples and not unparsed,('No/unparsed CPU samples',len(samples),unparsed[:3]);assert not lost,('Lost events',lost[:3])
weights=collections.Counter();counts=collections.Counter();symbols=collections.Counter()
for t,period,ip,sym,dso,path in samples:weights[dso]+=period;counts[dso]+=1;symbols[(dso,sym)]+=period
sw=sorted(switches);state=None;previous=None;off=collections.Counter();on=0.;unknown=0.
for t,out,kind in sw:
 if t<start:state=(out,kind);previous=start;continue
 if t>end:break
 if previous is None:previous=start
 duration=t-previous
 if state is None:unknown+=duration
 elif state[0]:off[state[1]]+=duration
 else:on+=duration
 state=(out,kind);previous=t
if previous is None:unknown=end-start
else:
 duration=end-previous
 if state is None:unknown+=duration
 elif state[0]:off[state[1]]+=duration
 else:on+=duration
weight=sum(weights.values())
result={'pe_module_mapping':[{'base':hex(a),'end':hex(b),'path':p}for a,b,p in images],'pe_mapping_basis':'Actual file-backed offset0 PE header mapping base plus on-disk validated PE SizeOfImage; ranges nonoverlapping. Maps anonymouscode back toloadedmodule, not function/Lua attribution. No processmemory/symbolinstallation.', 'window':condition,'samples':len(samples),'sample_weight_ns':weight,'lost':lost,'context_switch_events_in_window':sum(start<=t<=end for t,_,_ in sw),'main_thread_time':{'on_cpu_including_kernel_seconds':on,'off_cpu_after_preempted_switch_seconds':off['preempted'],'off_cpu_after_other_switch_seconds':off['other'],'unknown_seconds':unknown},'modules':[{'dso':k,'samples':counts[k],'weighted_user_sample_percent':100*v/weight}for k,v in weights.most_common()],'symbols':[{'dso':k[0],'symbol':k[1],'weighted_user_sample_percent':100*v/weight}for k,v in symbols.most_common(35)],'limits':'MAIN THREAD only. CPU IP sample distribution, notexclusiveLua functions. Other-switch offCPU includesblocking pluswakeuprunqueue; preemptedoffCPU is scheduling delay, not a namedwaitreason. OnCPU includeskernel whileIPsamples useronly; do notassumealloncpuCPUtimeisinLua oralloffCPUisGPU. Samplingperiodcountsapproximateexecution; no additiveVProf budget.'}
(arm/'native-frame-attribution.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps({'arm':arm.name,'window':condition,'samples':len(samples),'main_thread_time':result['main_thread_time'],'modules':result['modules'][:12],'symbols':result['symbols'][:12]},indent=2))

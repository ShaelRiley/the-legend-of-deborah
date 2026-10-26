from pathlib import Path
import subprocess,os,json,datetime,time,shutil,hashlib
r=Path('/home/deck/deborah-recovery');repo=Path('/home/deck/Downloads/the-legend-of-deborah');d=Path('/home/deck/.local/share/Steam/steamapps/common/GarrysMod/garrysmod/data/legend_of_deborah');sha=subprocess.check_output(['git','rev-parse','HEAD'],cwd=repo,text=True).strip();out=Path('/home/deck/deborah-benchmarks/warden-start-cpu')/sha[:8]/'observer-series-v1';out.mkdir(parents=True,exist_ok=True);sequence=['control','profiled','profiled','control']
plan={'sha':sha,'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'sequence':sequence,'seconds_each':30,'scope':'Attribution-only fourfreshC,P,P,C30s atunchangedfrozenD20lowercourt/samecounts/resources/input/settings/15WAC/bothON. Not sourcegain oracceptance.','failed_preFPS_attempt':'observer-series-v1/arm01-control: nativefocusFalse aftersetup, noFPS. Focushelperactivatedgame thenphysicallyclickedpointeronothermonitor. Correctedpointerplacement insideverifiedgamebeforepredeploymentclick; access/source/benchmarkcriteria unchanged.','hypothesis':'Attribution only: separate selected public manager/query/navigation parents from their nested selected calls, not a new source optimization hypothesis. Existing NextBot Lua scope dominant but previous inclusive scopes overlap. Reuse bounded query profiler, all selected calls measured with per-coroutine reusable frames and original return/error/yield/provider semantics; no actual exclusive CPU or full AI attribution claim. Four C,P,P,C30s captures assess overhead; no sourcecandidate/FPSgain/acceptance. Require zero open frames, all completed calls, exact selfsum/root conservation, zero Lua errors, restoration and independent retirement.','stop':'Sourcechangeonlyifmaterialreducibleinitialization work confirmed twice; no morelookup/cachingmicrocycles. Overalltranchedeadline2026-10-25T20:34:30UTC/max3newhypotheses.'};(out/'plan.json').write_text(json.dumps(plan,indent=2)+'\n');progress=json.loads((out/'progress.json').read_text()) if(out/'progress.json').exists() else {'status':'starting','completed':[]}
def save():progress['utc']=datetime.datetime.now(datetime.timezone.utc).isoformat();(out/'progress.json').write_text(json.dumps(progress,indent=2)+'\n')
def pids():
 rows=[]
 for p in Path('/proc').iterdir():
  if p.name.isdigit():
   try:
    if(p/'comm').read_text().strip()=='gmod_win64.exe':rows.append(p.name)
   except OSError:pass
 return rows
assert not pids();assert not subprocess.check_output(['git','status','--porcelain'],cwd=repo,text=True)
with(out/'install.log').open('w')as log:subprocess.run(['bash','tools/install_dev.sh'],cwd=repo,stdout=log,stderr=subprocess.STDOUT,check=True)
src=(repo/'gamemodes/legend_of_deborah/entities/entities/lod_static_box/cl_init.lua').read_bytes();source=src.decode();markers={'Draw':'function ENT:Draw()','Pre':'hook.Add("PreDrawOpaqueRenderables", "LOD_StaticBoxNativeVisibility", function','Post':'hook.Add("PostDrawOpaqueRenderables", "LOD.DrawGeneratedStaticGeometry", function'};(d/'bench_native_selection_arm.json').write_text(json.dumps({'mode':'query-observer','sha':sha,'sha256':hashlib.sha256(src).hexdigest(),'lines':{k:source[:source.index(v)].count('\n')+1 for k,v in markers.items()}}))
path='gamemodes/legend_of_deborah/gamemode/lod/cl_combat_roll_feed_semantics.lua';data=(repo/path).read_bytes();text=data.decode();spec={'mode':'candidate','sha':sha,'path':path,'sha256':hashlib.sha256(data).hexdigest(),'hud_line':text[:text.index('hook.Add("HUDPaint", "LOD_CombatRollFeed", function()')].count('\n')+1,'public_line':text[:text.index('function Feed:DrawLines(')].count('\n')+1};(d/'bench_hud_raster_arm.json').write_text(json.dumps(spec))
shutil.copy2(r/'bench_self_query_start.lua',out/'bench_self_query_start.lua')
shutil.copy2(r/'test_self_query_profile.lua',out/'test_self_query_profile.lua')
for n in ['start','stop','state','retirement']:shutil.copy2(d/('bench_query_profile_'+n+'.txt'),out/('bench_query_profile_'+n+'.txt'))
shutil.copy2(r/'test_query_profile_probe.lua',out/'test_query_profile_probe.lua');shutil.copy2(r/'run-selected-self-series.py',out/'run-warden-start-profile-series-resume.py');save();ck=json.loads((r/'CHECKPOINT.json').read_text());ck.update(current_head=sha,active_operation='run-selected-self-series.py fixed4freshcontrol/profile/profile/control; own lod-deck-selected-self-N-20261025; no source candidate',active_output=str(out));(r/'CHECKPOINT.json').write_text(json.dumps(ck,indent=2)+'\n')
try:
 for index,variant in enumerate(sequence,1):
  if any(x['index']==index and x['exit_code']==0 for x in progress['completed']):continue
  assert not pids();assert subprocess.check_output(['git','rev-parse','HEAD'],cwd=repo,text=True).strip()==sha;assert not subprocess.check_output(['git','status','--porcelain'],cwd=repo,text=True)
  arm=out/('arm%02d-'%index+variant)
  if arm.exists():
   assert not(arm/'analysis.json').exists(),'Never replace a measured run'
   arm=out/('arm%02d-'%index+variant+'-prefps-retry');assert not arm.exists()
  arm.mkdir();unit='lod-deck-selected-self-%d-20261025'%index;progress.update(status='running',active=arm.name,unit=unit);save();(arm/'display-layout.json').write_bytes(subprocess.check_output(['kscreen-doctor','-j']));(d/'bench_query_profile_arm.json').write_text(json.dumps({'sha':sha,'variant':variant,'scope':'managers-self-v1'}));shutil.copy2(d/'bench_query_profile_arm.json',arm/'bench_query_profile_arm.json')
  subprocess.run(['systemd-run','--user','--unit='+unit,'--collect','--service-type=exec','--property=RuntimeMaxSec=7200','--property=TimeoutStopSec=20','--property=KillMode=control-group','--setenv=LOD_MANGOHUD=0','--setenv=LOD_START_CONSOLE=1','--setenv=LOD_PROTON_TOOL=Proton 10.0','--setenv=LOD_COMPAT_DATA=/home/deck/deborah-recovery/compatdata-proton10','/usr/bin/python3',str(r/'start-gmod64.py')],check=True)
  try:
   with(arm/'controller.log').open('w')as log:result=subprocess.run(['python3',str(r/'run-ready-finale.py'),sha,str(arm),'--seconds','30'],timeout=360,stdout=log,stderr=subprocess.STDOUT,env={**os.environ,'LOD_QUERY_PROFILE_START_SCRIPT':'bench_self_query_start.txt','LOD_QUERY_PROFILE_VARIANT':variant,'LOD_QUERY_PROFILE_SCOPE':'managers-self-v1','LOD_HUD_RASTER_SOURCE_PROOF':'1','LOD_NATIVE_SELECTION_SOURCE_PROOF':'1','LOD_EXTERNAL_DPMS':'on','LOD_NET_GRAPH_EXPECT':'1','LOD_PROCESS_ACCOUNTING':'1','LOD_NATIVE_PERF_SAMPLE':'0'})
   row={'index':index,'variant':variant,'exit_code':result.returncode,'directory':str(arm)}
   if(arm/'analysis.json').exists():row['analysis']=json.loads((arm/'analysis.json').read_text())
   progress['completed'].append(row);save();assert result.returncode==0,('Failedarm;no replacement',row)
   assert json.loads((arm/'bench_query_profile_state.json').read_text())['passed']
   if variant=='profiled':assert json.loads((arm/'bench_query_profile_retirement.json').read_text())['passed']
   print('QUERY_PROFILE_ARM_COMPLETE',index,variant,row['analysis']['active']['fps'],flush=True)
  finally:
   subprocess.run(['systemctl','--user','stop',unit],timeout=40,check=True);end=time.monotonic()+20
   while pids()and time.monotonic()<end:time.sleep(.2)
   assert not pids();(arm/'display-after.txt').write_bytes(subprocess.check_output(['kscreen-doctor','--dpms','show']))
 progress.update(status='complete',active=None);save();ck.update(active_operation=None);(r/'CHECKPOINT.json').write_text(json.dumps(ck,indent=2)+'\n')
except Exception as e:progress.update(status='error',error=str(e));save();raise
finally:
 assert not pids();(out/'process-retirement.json').write_text(json.dumps({'all_owned_games_stopped':True})+'\n')
print('QUERY_PROFILE_SERIES_COMPLETE',out,flush=True)

from pathlib import Path
import subprocess,os,json,datetime,time,shutil,hashlib
r=Path('/home/deck/deborah-recovery');repo=Path('/home/deck/Downloads/the-legend-of-deborah');d=Path('/home/deck/.local/share/Steam/steamapps/common/GarrysMod/garrysmod/data/legend_of_deborah');sha=subprocess.check_output(['git','rev-parse','HEAD'],cwd=repo,text=True).strip();out=Path('/home/deck/deborah-benchmarks/low-overhead-native')/sha[:8]/'native-engine-vprof-confirmation-v1';out.mkdir(parents=True,exist_ok=True);sequence=['on','off','off','on']
plan={'sha':sha,'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'sequence':sequence,'seconds_each':60,'scope':'FrozenD20lowercourt stress/SP listenhost/oneplayer/1280x800/57initialhostiles/1820models/legalresources/unchangedAIgraphics15WAC/bothdisplaysON; matchedC/P/P/C freshprocesses. Actualfirst/lastPreRenderframewindowalignmentmarkersinbothconditions.','approach':2,'observer':'ExistingnativeengineVProf only. Queueonthenprivate2-callstamp AFTERfirstactualFPSframe; queueoffthenstamp0.5sBEFOREcapturedeadline. Assertbothactualengine-processedstampsinsiderawframewindow; reconstructmatchingwholeframe subsetbetweenstamps. Engineownrecordedframecount onlydenominator for nativeVProf averages; no different-windowFPSconversion. Samequeuedstamps/timerIOinoffcontrols. No per-AI wrappers, no nativeCPU sampler. Reportsaftercapture. Exactsubwindow/queuedboundary uncertaintyqualified.','screen':'<=5%throughputpenalty andno materialslowframedistortion, accountcontrolvariation; no sourcegainfromprofiledFPS. Bothintrusive/inconclusive=>stopquantitativeattribution.','deadline':'2026-10-25T22:24:04UTC; facilities<=21:14:04;atmost2approaches/1conditionalcandidate','failed_preFPS_attempt':None} ;progress=json.loads((out/'progress.json').read_text()) if(out/'progress.json').exists() else {'status':'starting','completed':[]}
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
shutil.copy2(r/'bench_engine_window.lua',out/'bench_engine_window.lua')

shutil.copy2(r/'bench_aligned_window.lua',out/'bench_aligned_window.lua')
shutil.copy2(r/'run-low-overhead-engine-confirmation.py',out/'run-warden-start-profile-series-resume.py');save();ck=json.loads((r/'CHECKPOINT.json').read_text());ck.update(current_head=sha,active_operation='run-low-overhead-engine-confirmation.py fixed4freshcontrol/profile/profile/control; own lod-deck-engine-confirm-N-20261025; no source candidate',active_output=str(out));(r/'CHECKPOINT.json').write_text(json.dumps(ck,indent=2)+'\n')
try:
 for index,variant in enumerate(sequence,1):
  if any(x['index']==index and x['exit_code']==0 for x in progress['completed']):continue
  assert not pids();assert subprocess.check_output(['git','rev-parse','HEAD'],cwd=repo,text=True).strip()==sha;assert not subprocess.check_output(['git','status','--porcelain'],cwd=repo,text=True)
  arm=out/('arm%02d-'%index+variant)
  if arm.exists():
   assert not(arm/'analysis.json').exists(),'Never replace a measured run'
   arm=out/('arm%02d-'%index+variant+'-prefps-retry');assert not arm.exists()
  arm.mkdir();unit='lod-deck-engine-confirm-%d-20261025'%index;progress.update(status='running',active=arm.name,unit=unit);save();(d/'bench_engine_window_arm.json').write_text(json.dumps({'variant':variant,'sha':sha}));shutil.copy2(d/'bench_engine_window_arm.json',arm/'bench_engine_window_arm.json');(arm/'display-layout.json').write_bytes(subprocess.check_output(['kscreen-doctor','-j']))
  subprocess.run(['systemd-run','--user','--unit='+unit,'--collect','--service-type=exec','--property=RuntimeMaxSec=7200','--property=TimeoutStopSec=20','--property=KillMode=control-group','--setenv=LOD_MANGOHUD=0','--setenv=LOD_START_CONSOLE=1','--setenv=LOD_PROTON_TOOL=Proton 10.0','--setenv=LOD_COMPAT_DATA=/home/deck/deborah-recovery/compatdata-proton10','/usr/bin/python3',str(r/'start-gmod64.py')],check=True)
  try:
   with(arm/'controller.log').open('w')as log:result=subprocess.run(['python3',str(r/'run-ready-finale.py'),sha,str(arm),'--seconds','60'],timeout=360,stdout=log,stderr=subprocess.STDOUT,env={**os.environ,'LOD_ALIGNED_WINDOW':'1','LOD_ALIGNED_WINDOW_SCRIPT':'bench_engine_window.txt','LOD_ENGINE_WINDOW':'1','LOD_HUD_RASTER_SOURCE_PROOF':'1','LOD_NATIVE_SELECTION_SOURCE_PROOF':'1','LOD_EXTERNAL_DPMS':'on','LOD_NET_GRAPH_EXPECT':'1','LOD_PROCESS_ACCOUNTING':'1','LOD_NATIVE_PERF_SAMPLE':'0'})
   row={'index':index,'variant':variant,'exit_code':result.returncode,'directory':str(arm)}
   if(arm/'analysis.json').exists():row['analysis']=json.loads((arm/'analysis.json').read_text())
   progress['completed'].append(row);save();assert result.returncode==0,('Failedarm;no replacement',row)
   assert json.loads((arm/'bench_aligned_window.json').read_text())['passed']
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

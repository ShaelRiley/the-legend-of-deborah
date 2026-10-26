from pathlib import Path
import subprocess,os,json,datetime,time,shutil,hashlib
r=Path('/home/deck/deborah-recovery');repo=Path('/home/deck/Downloads/the-legend-of-deborah');control=r/'advance-query-control';d=Path('/home/deck/.local/share/Steam/steamapps/common/GarrysMod/garrysmod/data/legend_of_deborah');sha=subprocess.check_output(['git','rev-parse','HEAD'],cwd=repo,text=True).strip();parent=subprocess.check_output(['git','rev-parse','HEAD'],cwd=control,text=True).strip();out=Path('/home/deck/deborah-benchmarks/advance-query-source')/sha[:8]/'original-source-series';out.mkdir(parents=True,exist_ok=False);sequence=['parent','candidate','candidate','parent','parent','candidate'];cutoff=datetime.datetime.fromisoformat('2026-10-26T04:07:30+00:00')
plan={'parent':parent,'candidate':sha,'start_utc':'2026-10-26T03:31:29+00:00','deadline_utc':'2026-10-26T04:16:29+00:00','capture_cutoff_utc':cutoff.isoformat(),'sequence':sequence,'seconds_each':60,'hypothesis':'Eliminate only unused present-position geometry for mobile nonbeam actors already in an existing forcedadvance window; CanCast/AcquireTarget remain, publicqueries/foreignproviders retain fullquery, no cache/cadence/movement/attack change. Materialbenefit hypothetical; sourcecomparison decides.','conditions':'ActualDeck/SP1humanlistenhost/gm_flatgrass/D20phase1lowercourt57initialhostiles1820walls/1280x800+externalbothON/15WAC/fixedsoftwaregraphicsresourcesseedsphysicalrouteAIcadence. All temporaryprofilers/samplers disabled; boundednative source/state proofonlybeforeafterFPS.','retention':'Require repeatablethroughput/pacing benefit; ambiguous/correctnessregression/unconfirmed=>parentrestore andexperimentpreserved. No full40acceptanceclaim orautomaticnewcheckpoint.'};(out/'plan.json').write_text(json.dumps(plan,indent=2)+'\n');progress={'status':'starting','completed':[]}
def save():progress['utc']=datetime.datetime.now(datetime.timezone.utc).isoformat();(out/'progress.json').write_text(json.dumps(progress,indent=2)+'\n')
def pids():
 a=[]
 for p in Path('/proc').iterdir():
  if p.name.isdigit():
   try:
    if(p/'comm').read_text().strip()=='gmod_win64.exe':a.append(p.name)
   except OSError:pass
 return a
assert not pids();assert not subprocess.check_output(['git','status','--porcelain'],cwd=repo,text=True);assert not subprocess.check_output(['git','status','--porcelain'],cwd=control,text=True)
for name in ['run-advance-query-source-series.py','bench_advance_query_state.lua']:shutil.copy2(r/name,out/name)
ck=json.loads((r/'CHECKPOINT.json').read_text());ck.update(current_head=sha,active_operation='sixprofiler-offadvancequerysourcecomparisons; sourceheldclean; no postprocessingduringcaptures',active_output=str(out));(r/'CHECKPOINT.json').write_text(json.dumps(ck,indent=2)+'\n')
try:
 for i,variant in enumerate(sequence,1):
  remaining=(cutoff-datetime.datetime.now(datetime.timezone.utc)).total_seconds()
  if remaining<170:progress.update(status='budget_cutoff_before_next_arm',active=None);save();break
  assert not pids();assert subprocess.check_output(['git','rev-parse','HEAD'],cwd=repo,text=True).strip()==sha;assert not subprocess.check_output(['git','status','--porcelain'],cwd=repo,text=True)
  tree=repo if variant=='candidate'else control;tested=sha if variant=='candidate'else parent;arm=out/('arm%02d-'%i+variant);arm.mkdir();unit='lod-deck-advance-query-%d-20261026'%i;progress.update(status='running',active=arm.name,unit=unit);save()
  with(arm/'install.log').open('w')as log:subprocess.run(['bash','tools/install_dev.sh'],cwd=tree,stdout=log,stderr=subprocess.STDOUT,check=True)
  path='gamemodes/legend_of_deborah/gamemode/lod/sv_enemy_roster.lua';src=(tree/path).read_bytes();s=src.decode();spec={'variant':variant,'sha':tested,'phase':'before','path':path,'sha256':hashlib.sha256(src).hexdigest(),'query_line':s[:s.index('function E:CanTargetFromHere(')].count('\n')+1,'tick_line':s[:s.index('function E:Tick(e)')].count('\n')+1};(d/'bench_advance_query_arm.json').write_text(json.dumps(spec));shutil.copy2(d/'bench_advance_query_arm.json',arm/'bench_advance_query_arm.json')
  path='gamemodes/legend_of_deborah/gamemode/lod/cl_combat_roll_feed_semantics.lua';src=(tree/path).read_bytes();s=src.decode();(d/'bench_hud_raster_arm.json').write_text(json.dumps({'mode':'candidate','sha':tested,'path':path,'sha256':hashlib.sha256(src).hexdigest(),'hud_line':s[:s.index('hook.Add("HUDPaint", "LOD_CombatRollFeed", function()')].count('\n')+1,'public_line':s[:s.index('function Feed:DrawLines(')].count('\n')+1}))
  src=(tree/'gamemodes/legend_of_deborah/entities/entities/lod_static_box/cl_init.lua').read_bytes();s=src.decode();markers={'Draw':'function ENT:Draw()','Pre':'hook.Add("PreDrawOpaqueRenderables", "LOD_StaticBoxNativeVisibility", function','Post':'hook.Add("PostDrawOpaqueRenderables", "LOD.DrawGeneratedStaticGeometry", function'};(d/'bench_native_selection_arm.json').write_text(json.dumps({'mode':variant,'sha':tested,'sha256':hashlib.sha256(src).hexdigest(),'lines':{k:s[:s.index(v)].count('\n')+1 for k,v in markers.items()}}));(arm/'display-layout.json').write_bytes(subprocess.check_output(['kscreen-doctor','-j']))
  subprocess.run(['systemd-run','--user','--unit='+unit,'--collect','--service-type=exec','--property=RuntimeMaxSec=900','--property=TimeoutStopSec=20','--property=KillMode=control-group','--setenv=LOD_MANGOHUD=0','--setenv=LOD_START_CONSOLE=1','--setenv=LOD_PROTON_TOOL=Proton 10.0','--setenv=LOD_COMPAT_DATA=/home/deck/deborah-recovery/compatdata-proton10','/usr/bin/python3',str(r/'start-gmod64.py')],check=True)
  try:
   limit=min(360,max(1,(cutoff-datetime.datetime.now(datetime.timezone.utc)).total_seconds()))
   with(arm/'controller.log').open('w')as log:result=subprocess.run(['python3',str(r/'run-ready-finale.py'),tested,str(arm),'--seconds','60'],timeout=limit,stdout=log,stderr=subprocess.STDOUT,env={**os.environ,'LOD_ADVANCE_QUERY_SOURCE_PROOF':'1','LOD_HUD_RASTER_SOURCE_PROOF':'1','LOD_NATIVE_SELECTION_SOURCE_PROOF':'1','LOD_EXTERNAL_DPMS':'on','LOD_NET_GRAPH_EXPECT':'1','LOD_PROCESS_ACCOUNTING':'1','LOD_NATIVE_PERF_SAMPLE':'0'})
   row={'index':i,'variant':variant,'tested':tested,'exit_code':result.returncode,'directory':str(arm)}
   if(arm/'analysis.json').exists():row['analysis']=json.loads((arm/'analysis.json').read_text())
   progress['completed'].append(row);save();assert result.returncode==0,('Failedarm; preserve/no replacement',row)
   assert json.loads((arm/'bench_advance_query_after.json').read_text())['passed'];print('ADVANCE_QUERY_ARM_COMPLETE',i,variant,row['analysis']['active']['fps'],flush=True)
  finally:
   subprocess.run(['systemctl','--user','stop',unit],timeout=40,check=True);end=time.monotonic()+20
   while pids()and time.monotonic()<end:time.sleep(.2)
   assert not pids();(arm/'display-after.txt').write_bytes(subprocess.check_output(['kscreen-doctor','--dpms','show']))
 else:progress.update(status='complete',active=None);save()
except Exception as e:progress.update(status='error',error=str(e));save();raise
finally:
 assert not pids()
 with(out/'restore-root-install.log').open('w')as log:subprocess.run(['bash','tools/install_dev.sh'],cwd=repo,stdout=log,stderr=subprocess.STDOUT,check=True)
 (out/'process-retirement.json').write_text(json.dumps({'all_owned_games_stopped':True,'root_install_restored':True,'root_sha':sha})+'\n');ck.update(active_operation=None);(r/'CHECKPOINT.json').write_text(json.dumps(ck,indent=2)+'\n')
print('ADVANCE_QUERY_SERIES_DONE',out,flush=True)

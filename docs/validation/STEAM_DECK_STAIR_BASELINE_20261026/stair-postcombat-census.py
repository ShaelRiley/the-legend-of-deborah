from pathlib import Path
import time,subprocess,json,shutil
root=Path('/home/deck/deborah-benchmarks/stair-corrected-baseline/8b2661ad/warmed-three60');f=root/'baseline03/performance_client_latest.txt';end=time.monotonic()+300
while time.monotonic()<end:
 if f.exists():
  p=Path('/home/deck/.local/share/Steam/steamapps/common/GarrysMod/garrysmod/data/legend_of_deborah/bench_stair_query_census.json');old=p.stat().st_mtime_ns if p.exists() else 0
  r=subprocess.run(['python3','/home/deck/deborah-recovery/bench-command.py','server',json.dumps({'action':'script','name':'bench_stair_query_census.txt'})],capture_output=True,text=True,timeout=65)
  print('POST_CAPTURE_CENSUS_ACK',r.returncode,r.stdout,r.stderr,flush=True)
  if r.returncode==0 and p.exists()and p.stat().st_mtime_ns>old:shutil.copy2(p,root/'bench_stair_query_census_after_combat.json');print('CENSUS_COMPLETE',flush=True)
  break
 time.sleep(.1)
else:print('No third capture receipt within finite watch; no query sent')

"""Isolated transport, exact-source gate and non-forced SPOT-16 publication."""
import base64,ctypes,ctypes.util,gzip,hashlib,json,os,pathlib,subprocess,sys,zlib
ROOT=pathlib.Path.cwd();OUT=pathlib.Path(os.environ['SPOT16_EVIDENCE']);OUT.mkdir(parents=True,exist_ok=True)
PACKED_SHA='d109583c9542d01cfc9521b1084068bad170a38b18696787f7002aa71723bd55'
DICT_NAMES=['docs/DEVELOPMENT_PLAN.md', 'docs/NEXT_DEVELOPMENT_HANDOFF.md', 'docs/briefs/SPOT_UPDATES.md', 'docs/manual/book.json', 'gamemodes/legend_of_deborah/gamemode/lod/cl_player_weapon_specials.lua', 'gamemodes/legend_of_deborah/gamemode/lod/sv_character_progression.lua', 'gamemodes/legend_of_deborah/gamemode/lod/sv_firearm_economy_equalization.lua', 'gamemodes/legend_of_deborah/gamemode/lod/sv_human_soldier_progression.lua', 'gamemodes/legend_of_deborah/gamemode/lod/sv_player_weapon_specials.lua', 'gamemodes/legend_of_deborah/gamemode/lod/sv_player_weapon_specials_input.lua', 'gamemodes/legend_of_deborah/gamemode/lod/sv_rpg_gate_e_rate_of_fire_ar2.lua', 'gamemodes/legend_of_deborah/gamemode/lod/sv_rpg_gate_e_smg_heat.lua', 'gamemodes/legend_of_deborah/gamemode/lod/sv_run_manager.lua', 'gamemodes/legend_of_deborah/gamemode/lod/sv_smg_capacity_rebalance.lua', 'tools/test_spot15_soldier_queue.lua', 'tools/validate_spot10_second_pass.lua']
DICT_SHA='c6665bdb54c7f50340f52af73ab54e3a0d6c16a22720a2107f8112b1af66177d'
RAW_SIZE=189761
RAW_SHA='a04aed4c3040c5101302826f021082d835bbdecfcf232cf254e28087429b744c'
PARENT='258c0ef6c46c2554987a7ec77862ab45433e5fcc'
CHILD='9e2601953e8f91469fc3d8ece7c13110fd1e8941';TREE='e9b88e4abc327954742828a2993277d21b03fff5';SOURCE='a92a6f7ad93269df317d1915cb14e650fd40f58d1506f0364e0eea78e2258de3'
def sha(b): return hashlib.sha256(b).hexdigest()
def git(*args,input=None):return subprocess.check_output(['git',*args],cwd=ROOT,input=input)
def text(*args,input=None):return git(*args,input=input).decode().strip()
def source_hash():
 names=git('ls-files','--cached','--others','--exclude-standard','-z').decode().split('\0')
 values={n:sha((ROOT/n).read_bytes()) for n in sorted(set(names)) if n and '__pycache__' not in n and (ROOT/n).is_file()}
 return sha(json.dumps(values,sort_keys=True).encode())
def gate(path,logs):
 r=json.loads(path.read_text());assert r['passed']==r['total']==93 and r['lua_files']==753
 assert r['source_before']==r['source_after']==SOURCE and not r['changed_during_gate']
 assert r['suite_timeout_seconds']==120 and r['workers']==2 and not r['native_gmod_accepted']
 for row in r['results']:
  assert row['passed'] and row['returncode']==0
  if logs:assert sha((path.parent/row['log']).read_bytes())==row['log_sha256']
 return r

def prepare():
 packed=base64.b64decode(''.join(pathlib.Path(os.environ['SPOT16_PAYLOAD']).read_text().split()),validate=True)
 assert sha(packed)==PACKED_SHA,'transport mismatch; no source writes'
 dictionary=b''.join(git('show',PARENT+':'+p) for p in DICT_NAMES)
 assert sha(dictionary)==DICT_SHA
 lib=ctypes.CDLL(ctypes.util.find_library('zstd'));lib.ZSTD_createDCtx.restype=ctypes.c_void_p
 lib.ZSTD_freeDCtx.argtypes=[ctypes.c_void_p]
 lib.ZSTD_decompress_usingDict.argtypes=[ctypes.c_void_p,ctypes.c_void_p,ctypes.c_size_t,ctypes.c_void_p,ctypes.c_size_t,ctypes.c_void_p,ctypes.c_size_t];lib.ZSTD_decompress_usingDict.restype=ctypes.c_size_t
 context=lib.ZSTD_createDCtx();dst=ctypes.create_string_buffer(RAW_SIZE)
 try:n=lib.ZSTD_decompress_usingDict(context,dst,RAW_SIZE,packed,len(packed),dictionary,len(dictionary))
 finally:lib.ZSTD_freeDCtx(context)
 assert n==RAW_SIZE and sha(dst.raw)==RAW_SHA
 data=json.loads(dst.raw);assert data['parent']==PARENT and data['child']==CHILD and data['tree']==TREE
 if not os.environ.get('SPOT16_LOCAL_REPLAY'):
  git('fetch','origin','main','--depth=1');assert text('rev-parse','origin/main')==PARENT,'main advanced; stopped'
 git('checkout','--detach',PARENT);assert text('status','--porcelain')==''
 patch=data['patch'].encode();assert sha(patch)==data['patch_sha256']
 git('apply','--index','--whitespace=error','-',input=patch)
 subprocess.run([sys.executable,'tools/build_manual.py'],cwd=ROOT,check=True)
 git('add','docs/manual/manual.html','gamemodes/legend_of_deborah/gamemode/lod/manual')
 assert text('write-tree')==TREE,'candidate tree differs from local freeze'
 assert source_hash()==SOURCE
 raw=data['commit'].encode();assert raw.startswith(('tree '+TREE+'\nparent '+PARENT+'\n').encode())
 assert raw.count(b'\nparent ')==1
 assert text('hash-object','-w','-t','commit','--stdin',input=raw)==CHILD
 git('checkout','--detach',CHILD);git('diff',PARENT,CHILD,'--check')
 assert text('status','--porcelain')=='' and source_hash()==SOURCE
 (OUT/'local-receipt.json').write_text(json.dumps(data['local_receipt'],indent=2)+'\n');gate(OUT/'local-receipt.json',False)
 (OUT/'candidate.patch').write_bytes(patch)
 (OUT/'published-source.tar.gz').write_bytes(gzip.compress(git('archive',CHILD),mtime=0))
 (OUT/'published-tree.txt').write_bytes(git('ls-tree','-r',CHILD))
 (OUT/'published-commit.txt').write_bytes(git('cat-file','commit',CHILD))
 meta={'parent':PARENT,'commit':CHILD,'tree':TREE,'source_snapshot_sha256':SOURCE,'transport_sha256':PACKED_SHA,'patch_sha256':data['patch_sha256'],'local_raw_logs':'Delivered recovery evidence archive; not transported in this runner artifact','local_receipt_sha256':sha((OUT/'local-receipt.json').read_bytes()),'trigger_not_gameplay_parent':os.environ.get('GITHUB_SHA','local-replay')}
 (OUT/'preparation.json').write_text(json.dumps(meta,indent=2)+'\n');print('SPOT16_EXACT_SOURCE_READY',CHILD,TREE,SOURCE,flush=True)

def publish():
 gate(OUT/'local-receipt.json',False);gate(OUT/'independent'/'receipt.json',True)
 assert text('rev-parse','HEAD')==CHILD and text('rev-parse','HEAD^{tree}')==TREE
 assert text('status','--porcelain')=='' and source_hash()==SOURCE
 git('fetch','origin','main','--depth=1');assert text('rev-parse','origin/main')==PARENT,'main advanced; no push performed'
 subprocess.run(['git','push','origin',CHILD+':refs/heads/main'],cwd=ROOT,check=True)
 observed=git('ls-remote','origin','refs/heads/main').decode().split()[0];assert observed==CHILD
 receipt={'commit':CHILD,'tree':TREE,'parent':PARENT,'observed_main':observed,'tracked_files':len([n for n in git('ls-files','-z').decode().split('\0') if n]),'source_archive_sha256':sha((OUT/'published-source.tar.gz').read_bytes()),'source_snapshot_sha256':SOURCE,'local_selected_suites':93,'independent_selected_suites':93,'focused_server_assertions':988,'focused_client_assertions':32,'lua_syntax_files':753,'run_id':os.environ['GITHUB_RUN_ID'],'attempt':os.environ['GITHUB_RUN_ATTEMPT'],'trigger_commit_not_gameplay_parent':os.environ['GITHUB_SHA'],'push_force':False,'native_accepted':False,'full_campaign_matrix':False,'workshop_or_vps_actions':False}
 (OUT/'publication.json').write_text(json.dumps(receipt,indent=2)+'\n');print(json.dumps(receipt,indent=2),flush=True)
if __name__=='__main__':
 if sys.argv[1]=='prepare':prepare()
 elif sys.argv[1]=='publish':publish()
 else:raise ValueError('unknown phase')

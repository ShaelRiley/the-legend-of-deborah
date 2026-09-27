"""Isolated transport, exact-source gate and non-forced SPOT-17 publication."""
import base64,ctypes,ctypes.util,datetime,gzip,hashlib,json,os,pathlib,subprocess,sys
ROOT=pathlib.Path.cwd();OUT=pathlib.Path(os.environ['SPOT17_EVIDENCE']);OUT.mkdir(parents=True,exist_ok=True)
PACKED_SHA='5ae0b1982d206653d77024b24d50243c3954b872878cef1645077cf48a599cbe'
DICT_NAMES=['docs/DEVELOPMENT_PLAN.md', 'docs/NEXT_DEVELOPMENT_HANDOFF.md', 'docs/briefs/SPOT_UPDATES.md', 'docs/manual/book.json', 'gamemodes/legend_of_deborah/gamemode/lod/cl_haste.lua', 'gamemodes/legend_of_deborah/gamemode/lod/cl_player_weapon_specials.lua', 'gamemodes/legend_of_deborah/gamemode/lod/sv_player_weapon_specials.lua', 'gamemodes/legend_of_deborah/gamemode/lod/sv_rpg_dodge.lua', 'gamemodes/legend_of_deborah/gamemode/lod/sv_rpg_gate_d.lua', 'gamemodes/legend_of_deborah/gamemode/lod/sv_rpg_status_elements.lua', 'gamemodes/legend_of_deborah/gamemode/shared.lua', 'tools/test_equipment_economy_runtime.lua', 'tools/test_spot16_soldier_rifle.lua']
DICT_SHA='a0a2795092bcf75637ecbec2a64a5e615e13bcbe69cf7798e72898557f2b1407'
RAW_SIZE=135799
RAW_SHA='efd0f312503405659238a9e848c64e9a8d70847fdeef0666b54becd741b508cb'
PARENT='9e2601953e8f91469fc3d8ece7c13110fd1e8941'
CHILD='aebd2bb0083bb0b13b043486665342dfc1c084f0'
TREE='6217b8e84fd989b0ecd8a7d6fb512e61c156212f'
SOURCE='e91807b55c1465160c740e1a3c91853d359fc2298e121613a054f35eb86eb592'
def sha(b): return hashlib.sha256(b).hexdigest()
def git(*args,input=None):return subprocess.check_output(['git',*args],cwd=ROOT,input=input)
def text(*args,input=None):return git(*args,input=input).decode().strip()
def source_hash():
 names=git('ls-files','--cached','--others','--exclude-standard','-z').decode().split('\0')
 values={n:sha((ROOT/n).read_bytes()) for n in sorted(set(names)) if n and '__pycache__' not in n and (ROOT/n).is_file()}
 return sha(json.dumps(values,sort_keys=True).encode())
def gate(path,logs):
 r=json.loads(path.read_text());assert r['passed']==r['total']==95 and r['lua_files']==756
 assert r['source_before']==r['source_after']==SOURCE and not r['changed_during_gate']
 assert r['suite_timeout_seconds']==120 and r['workers']==2 and not r['native_gmod_accepted']
 for row in r['results']:
  assert row['passed'] and row['returncode']==0
  if logs:assert sha((path.parent/row['log']).read_bytes())==row['log_sha256']
 return r

def prepare():
 packed=base64.b64decode(''.join(pathlib.Path(os.environ['SPOT17_PAYLOAD']).read_text().split()),validate=True)
 assert sha(packed)==PACKED_SHA,'transport mismatch; no source writes'
 if not os.environ.get('SPOT17_LOCAL_REPLAY'):
  git('fetch','origin','refs/heads/main:refs/remotes/origin/main','--depth=1');assert text('rev-parse','origin/main')==PARENT,'main advanced; stopped'
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
 meta={'parent':PARENT,'commit':CHILD,'tree':TREE,'source_snapshot_sha256':SOURCE,'transport_sha256':PACKED_SHA,'patch_sha256':data['patch_sha256'],'local_raw_logs':'Delivered SPOT-17 evidence archive; not transported in this runner artifact','local_receipt_sha256':sha((OUT/'local-receipt.json').read_bytes()),'trigger_not_gameplay_parent':os.environ.get('GITHUB_SHA','local-replay')}
 (OUT/'preparation.json').write_text(json.dumps(meta,indent=2)+'\n');print('SPOT17_EXACT_SOURCE_READY',CHILD,TREE,SOURCE,flush=True)

def publish():
 local=gate(OUT/'local-receipt.json',False);independent=gate(OUT/'independent'/'receipt.json',True)
 assert [(x['name'],x['command']) for x in local['results']]==[(x['name'],x['command']) for x in independent['results']]
 assert 'SPOT17_SERVER_PASS 2552 new actual-production assertions' in (OUT/'independent'/'test_spot17_movement_server.lua.log').read_text()
 assert 'SPOT17_CLIENT_PASS 321 new actual-production assertions' in (OUT/'independent'/'test_spot17_movement_client.lua.log').read_text()
 assert text('rev-parse','HEAD')==CHILD and text('rev-parse','HEAD^{tree}')==TREE
 assert text('status','--porcelain')=='' and source_hash()==SOURCE
 git('fetch','origin','refs/heads/main:refs/remotes/origin/main','--depth=1');assert text('rev-parse','origin/main')==PARENT,'main advanced; no push performed'
 subprocess.run(['git','push','origin',CHILD+':refs/heads/main'],cwd=ROOT,check=True)
 observed=git('ls-remote','origin','refs/heads/main').decode().split()[0];assert observed==CHILD
 receipt={'commit':CHILD,'tree':TREE,'parent':PARENT,'observed_main':observed,'tracked_files':len([n for n in git('ls-files','-z').decode().split('\0') if n]),'source_archive_sha256':sha((OUT/'published-source.tar.gz').read_bytes()),'source_snapshot_sha256':SOURCE,'local_selected_suites':95,'independent_selected_suites':95,'focused_server_assertions':2552,'focused_client_assertions':321,'lua_syntax_files':756,'published_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'run_id':os.environ['GITHUB_RUN_ID'],'attempt':os.environ['GITHUB_RUN_ATTEMPT'],'trigger_commit_not_gameplay_parent':os.environ['GITHUB_SHA'],'push_force':False,'native_accepted':False,'full_campaign_matrix':False,'workshop_or_vps_actions':False}
 (OUT/'publication.json').write_text(json.dumps(receipt,indent=2)+'\n');print(json.dumps(receipt,indent=2),flush=True)
if __name__=='__main__':
 if sys.argv[1]=='prepare':prepare()
 elif sys.argv[1]=='publish':publish()
 else:raise ValueError('unknown phase')

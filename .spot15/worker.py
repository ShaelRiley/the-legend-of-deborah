"""Isolated SPOT-15 transport/gate/publication; never part of gameplay ancestry."""
import base64,ctypes,ctypes.util,gzip,hashlib,io,json,lzma,os,pathlib,subprocess,sys,tarfile,urllib.request,urllib.error,zipfile
PARENT='79b770d5b5effc9c329e5931b22dd3954fd60dfb'
CHILD='258c0ef6c46c2554987a7ec77862ab45433e5fcc'
TREE='6d416b19a58d78ed80d888a9a8d29d12bf6d46b3'
RAW_SIZE=32317440
RAW_HASH='e8e01e54f4f9720faacbb32a41e83c22136ae9c17d453064e081d9b7f25cb2e5'
TRANSPORT_HASH='209e12eb771c3eeb98bff2d3074c00026dfd8adf4d843fef8fa0768971450c47'
ZIP_HASH='ec3dcfe04cf971d945e877e6ccb0282ed8a268b47308689f7caab480bb8176b6'
DICT_HASH='9f1fd5f33fb9abdf7743232eede302c76b479004b38821ee82da1ba9ef37c61b'
SOURCE_HASH='4c13b8f4c30d373976d850386581ef6c435f369f20cf2f6533d6630debe1b5ab'
ROOT=pathlib.Path.cwd();OUT=pathlib.Path(os.environ['SPOT15_EVIDENCE']);OUT.mkdir(parents=True,exist_ok=True)
def sha(data):return hashlib.sha256(data).hexdigest()
def git(*args,input=None):return subprocess.check_output(['git',*args],cwd=ROOT,input=input)
def text(*args):return git(*args).decode().strip()
def source_hash():
 names=text('ls-files','--cached','--others','--exclude-standard','-z').split('\0')
 values={n:sha((ROOT/n).read_bytes()) for n in sorted(set(names)) if n and '__pycache__' not in n and (ROOT/n).is_file()}
 return sha(json.dumps(values,sort_keys=True).encode())
def check_gate(path):
 receipt=json.loads((path/'receipt.json').read_text())
 assert receipt['passed']==receipt['total']==90 and receipt['lua_files']==751
 assert receipt['source_before']==receipt['source_after']==SOURCE_HASH and not receipt['changed_during_gate']
 assert receipt['suite_timeout_seconds']==120 and receipt['workers']==2
 for row in receipt['results']:
  assert row['passed'] and row['returncode']==0 and sha((path/row['log']).read_bytes())==row['log_sha256']
 return receipt
def base_zip():
 local=os.environ.get('SPOT15_BASE_ZIP')
 if local:return pathlib.Path(local).read_bytes()
 class NoRedirect(urllib.request.HTTPRedirectHandler):
  def redirect_request(self,*args,**kwargs):return None
 opener=urllib.request.build_opener(NoRedirect)
 request=urllib.request.Request('https://api.github.com/repos/ShaelRiley/the-legend-of-deborah/actions/artifacts/10921387529/zip',headers={'Authorization':'Bearer '+os.environ['GH_TOKEN'],'Accept':'application/vnd.github+json'})
 try:
  with opener.open(request,timeout=120) as response:return response.read()
 except urllib.error.HTTPError as exc:
  if exc.code not in (301,302,303,307,308):raise
  location=exc.headers['Location'];assert location.startswith('https://')
  # Never send the GitHub authorization header to the signed storage URL.
  with urllib.request.urlopen(location,timeout=120) as response:return response.read()
def prepare():
 packed=base64.b64decode(''.join(pathlib.Path(os.environ['SPOT15_PAYLOAD']).read_text().split()),validate=True)
 assert sha(packed)==TRANSPORT_HASH
 if not os.environ.get('SPOT15_LOCAL_REPLAY'):
  git('fetch','origin','main','--depth=1');assert text('rev-parse','origin/main')==PARENT
 git('checkout','--detach',PARENT)
 with tarfile.open(fileobj=io.BytesIO(git('archive',PARENT)),mode='r:') as archive:
  blobs={m.name:archive.extractfile(m).read() for m in archive if m.isfile()}
 manifest=(json.dumps({n:sha(v) for n,v in blobs.items()},sort_keys=True,indent=2)+'\n').encode()
 zbytes=base_zip();assert sha(zbytes)==ZIP_HASH
 parts=[manifest,blobs['docs/manual/manual.html']]
 with zipfile.ZipFile(io.BytesIO(zbytes)) as z:
  prior=z.read('gate/receipt.json');receipt=json.loads(prior);assert receipt['passed']==receipt['total']==87
  for row in sorted(receipt['results'],key=lambda r:r['name']):
   log=z.read('gate/'+row['log']);assert sha(log)==row['log_sha256'];parts.append(log)
  parts.append(prior)
 html=blobs['docs/manual/manual.html'];parts += [base64.b64encode(html[n:]) for n in range(3)]
 for p in ['docs/manual/book.json','gamemodes/legend_of_deborah/gamemode/lod/sv_run_manager.lua','gamemodes/legend_of_deborah/gamemode/lod/cl_soldier_queue_ui.lua','gamemodes/legend_of_deborah/gamemode/lod/sv_multiplayer_hardening.lua','gamemodes/legend_of_deborah/gamemode/lod/cl_hud.lua','tools/test_human_soldier_lifecycle.lua']:parts.append(blobs[p])
 dictionary=b''.join(parts);assert sha(dictionary)==DICT_HASH
 lib=ctypes.CDLL(ctypes.util.find_library('zstd'));lib.ZSTD_createDCtx.restype=ctypes.c_void_p
 lib.ZSTD_freeDCtx.argtypes=[ctypes.c_void_p];lib.ZSTD_isError.argtypes=[ctypes.c_size_t];lib.ZSTD_isError.restype=ctypes.c_uint
 lib.ZSTD_decompress_usingDict.argtypes=[ctypes.c_void_p,ctypes.c_void_p,ctypes.c_size_t,ctypes.c_void_p,ctypes.c_size_t,ctypes.c_void_p,ctypes.c_size_t];lib.ZSTD_decompress_usingDict.restype=ctypes.c_size_t
 context=lib.ZSTD_createDCtx();dst=ctypes.create_string_buffer(RAW_SIZE)
 try:n=lib.ZSTD_decompress_usingDict(context,dst,RAW_SIZE,packed,len(packed),dictionary,len(dictionary))
 finally:lib.ZSTD_freeDCtx(context)
 assert not lib.ZSTD_isError(n) and n==RAW_SIZE
 raw=dst.raw;assert sha(raw)==RAW_HASH
 with tarfile.open(fileobj=io.BytesIO(raw),mode='r:') as t:
  entries={}
  for m in t:
   assert m.isfile() and not m.name.startswith('/') and '..' not in pathlib.PurePosixPath(m.name).parts
   entries[m.name]=t.extractfile(m).read()
 meta=json.loads(entries['meta.json']);assert (meta['commit'],meta['tree'],meta['parent'])==(CHILD,TREE,PARENT)
 assert sha(entries['objects.pack'])==meta['pack_sha256']
 attempt_archive=lzma.compress(entries['attempts.tar'],preset=9);assert sha(attempt_archive)==meta['attempt_archive_sha256']
 assert git('hash-object','-w','--stdin',input=attempt_archive).decode().strip()==meta['attempt_archive_blob']
 git('index-pack','--stdin','--fix-thin',input=entries['objects.pack'])
 assert text('rev-parse',CHILD+'^{tree}')==TREE and text('rev-parse',CHILD+'^')==PARENT
 git('checkout','--detach',CHILD);git('diff',PARENT,CHILD,'--check')
 assert text('status','--porcelain')=='' and source_hash()==SOURCE_HASH
 for name,data in entries.items():
  if name.startswith('local-final/'):
   path=OUT/name;path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(data)
 check_gate(OUT/'local-final')
 (OUT/'published-source.tar.gz').write_bytes(gzip.compress(git('archive',CHILD),mtime=0))
 (OUT/'published-tree.txt').write_bytes(git('ls-tree','-r',CHILD))
 (OUT/'published-commit.txt').write_bytes(git('cat-file','commit',CHILD))
 (OUT/'preparation.json').write_text(json.dumps({**meta,'transport_sha256':TRANSPORT_HASH,'transport_raw_sha256':RAW_HASH,'base_artifact_zip_sha256':ZIP_HASH,'compression_dictionary_sha256':DICT_HASH,'baseline_logs_used_only_as_dictionary':True,'trigger_not_gameplay_parent':os.environ.get('GITHUB_SHA','local-replay')},indent=2)+'\n')
 print('SPOT15_EXACT_SOURCE_READY',CHILD,TREE,SOURCE_HASH,flush=True)
def publish():
 check_gate(OUT/'local-final');check_gate(OUT/'independent')
 assert text('rev-parse','HEAD')==CHILD and text('rev-parse','HEAD^{tree}')==TREE
 assert source_hash()==SOURCE_HASH and text('status','--porcelain')==''
 git('fetch','origin','main','--depth=1');assert text('rev-parse','origin/main')==PARENT,'main advanced; no push performed'
 subprocess.run(['git','push','origin',CHILD+':refs/heads/main'],cwd=ROOT,check=True) # deliberately no force
 observed=git('ls-remote','origin','refs/heads/main').decode().split()[0];assert observed==CHILD
 publication={'commit':CHILD,'tree':TREE,'parent':PARENT,'observed_main':observed,'tracked':len(text('ls-files','-z').split('\0')),'source_sha256':sha((OUT/'published-source.tar.gz').read_bytes()),'source_snapshot_sha256':SOURCE_HASH,'local_selected_suites':90,'independent_selected_suites':90,'new_focused_assertions':425,'lua_syntax_files':751,'run_id':os.environ['GITHUB_RUN_ID'],'attempt':os.environ['GITHUB_RUN_ATTEMPT'],'trigger_commit_not_gameplay_parent':os.environ['GITHUB_SHA'],'push_force':False,'workshop_or_vps_actions':False,'native_accepted':False,'full_campaign_matrix':False,'transport_sha256':TRANSPORT_HASH}
 (OUT/'publication.json').write_text(json.dumps(publication,indent=2)+'\n');print(json.dumps(publication,indent=2),flush=True)
if __name__=='__main__':
 if sys.argv[1]=='prepare':prepare()
 elif sys.argv[1]=='publish':publish()
 else:raise ValueError('unknown phase')

from pathlib import Path
import base64,hashlib,json,lzma,subprocess
raw=lzma.decompress(base64.b64decode(Path('/tmp/spot03_delta').read_text()))
assert hashlib.sha256(raw).hexdigest()=='0205237d4dfcc7f4e7db63586859ac1e538c282b075f58f0227df556fd070f07'
d=json.loads(raw)
assert subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip()==d['parent']
assert subprocess.check_output(['git','rev-parse','HEAD^{tree}'],text=True).strip()==d['base_tree']
assert len(d['files'])==11
for f in d['files']:
    p=Path(f['path'])
    assert not p.is_absolute() and '..' not in p.parts
    old=p.read_bytes() if p.exists() else b''
    assert (hashlib.sha256(old).hexdigest() if p.exists() else None)==f['base'],str(p)
    lines=old.decode('utf-8').splitlines(keepends=True)
    for a,b,text in reversed(f['edits']): lines[a:b]=text.splitlines(keepends=True)
    data=''.join(lines).encode('utf-8')
    assert hashlib.sha256(data).hexdigest()==f['result'],str(p)
    p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(data)
subprocess.run(['git','add','--']+[f['path'] for f in d['files']],check=True)
subprocess.run(['git','diff','--cached','--check'],check=True)
assert subprocess.check_output(['git','write-tree'],text=True).strip()==d['tree']
print('SPOT03_EXACT_TREE '+d['tree'])

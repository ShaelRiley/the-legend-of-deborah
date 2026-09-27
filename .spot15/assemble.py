"""Verify transport shards; repair only the four identified text-copy errors."""
import base64, hashlib, json, os
from pathlib import Path
expected = ['bd67ee3aa48d896d424dda25603cd5b1b6597990','50fc980b575179e0e2ad15d7d970defe9686d3e4','e221606348a505ef9e10d2f26c4f0cccfd3ad3a0','56ee10c8db7cfd79c680416d7354153aadd5eed2','81206de546aabe5c9fdd59b61ed4181fb0cc5b9e','72f93fdd7f468d9a7cfa00966fd2ea5c18911004','980b6073d8425c199efab498fa4c2ba253290dc8','09a55be33e39e295f22ce5b971a4452d126205d8','e1535c04ed0e403ca36043930ab93ac9cccb6e4b']
def blob(data):
    return hashlib.sha1(f'blob {len(data)}\0'.encode()+data).hexdigest()
out=Path(os.environ['SPOT15_EVIDENCE']);out.mkdir(parents=True,exist_ok=True)
parts=[];rows=[]
for i,wanted in enumerate(expected):
    path=Path(f'.spot15/wire-{i:02d}.b64');data=path.read_bytes();original=blob(data)
    if i==4:
        assert original=='76221cd323e7c8f7a6c8ca22c6afbecd7dc15a6a'
        (out/'initial-wire-04.b64').write_bytes(data)
        for bad,good in [('AtFwPGROBKkAyCAq','AtFwPGROBkAyCAq'),('AvWRzud8mKlFk6Wxe','AvWRzud8mKFk6Wxe'),('lMDWfHahrPiGYUUNZxWNhr','lMDWfHahrOWiUNZxWNhr'),('OeE6V1nRVnRWV','OeE6V1iRVnRWV')]:
            assert data.count(bad.encode())==1
            data=data.replace(bad.encode(),good.encode())
    assert blob(data)==wanted,(str(path),blob(data),wanted)
    rows.append({'path':str(path),'initial_blob':original,'verified_final_blob':wanted,'text_copy_correction':i==4})
    parts.append(data.strip())
wire=b''.join(parts)
assert len(wire)==63064
assert hashlib.sha256(base64.b64decode(wire,validate=True)).hexdigest()=='209e12eb771c3eeb98bff2d3074c00026dfd8adf4d843fef8fa0768971450c47'
Path(os.environ['SPOT15_PAYLOAD']).write_bytes(wire)
(out/'verified-transport.b64').write_bytes(wire)
(out/'transport-preflight.json').write_text(json.dumps({'shards':rows,'four_text_copy_errors_corrected_before_any_gate':True,'gameplay_source_changed':False},indent=2)+'\n')
print('SPOT15_TRANSPORT_VERIFIED: all nine shards and compressed payload hash match')

#!/usr/bin/env python3
"""Exercise real ZIP ingestion, decode validation, immutable commit and auth."""
import copy
import io
import json
from pathlib import Path
import sys
import tempfile
import zipfile
sys.path.insert(0,str(Path(__file__).parent/'music'))
from catalog_service import CatalogStore, application, CHUNK_BYTES
from lod_music_upload import bundle
from generate_defaults import generate

checks=0
def check(ok,msg):
    global checks
    checks+=1
    assert ok,msg

def reject(fn,msg):
    try:fn()
    except (ValueError,KeyError):check(True,msg)
    else:raise AssertionError(msg)

with tempfile.TemporaryDirectory() as tmp:
    root=Path(tmp)
    sources=generate(root/'sources')
    store=CatalogStore(root/'host','https://music.example.test',root/'game-data')
    profile=bundle(sources/'deborah-defaults-v1')
    uid=store.stage(profile)
    check(not (store.root/'catalog.json').exists(),'staging cannot publish')
    rev=store.publish(uid)
    c=store.catalog();check(len(c['assets'])==7 and len(c['profiles'])==1,'real seven-role decoded profile')
    for asset in c['assets'].values():
        parts=sorted((store.root/'music/chunks'/asset['hash']).glob('*.dat'),key=lambda p:int(p.stem))
        check(asset.get('delivery')==1 and all(0<p.stat().st_size<=CHUNK_BYTES for p in parts),'fixed-size delivery published offline')
        check(b''.join(p.read_bytes() for p in parts)==(store.root/asset['path']).read_bytes(),'chunks reproduce exact immutable audio')
    check(all(a.get('cues',{}).get('version')==1 for a in c['assets'].values() if a['loop']), 'loop cue maps published before gameplay')
    check(all('cues' not in a for a in c['assets'].values() if not a['loop']), 'fanfare stays outside section director')
    check(len(c['blocks'])==0,'defaults are not procedural blocks')
    block=bundle(sources/'deborah-foundations-v1')
    store.publish(store.stage(block))
    store.configure({'projectDefault':'deborah-defaults','sets':{'test':{'title':'Test','revision':'v1','members':['deborah-foundations','deborah-foundations']}}})
    c=store.catalog();check(c['sets']['test']['members']==['deborah-foundations'],'set membership deduplicated')
    check(json.loads((root/'game-data/catalog.json').read_text())==c,'game catalog atomic mirror')
    check(json.loads((root/'game-data/reload.json').read_text())['revision']==c['revision'],'explicit future-plan reload receipt')
    before=(store.root/'catalog.json').read_bytes()
    reject(lambda:store.publish(store.stage(block)),'immutable published version rejects replacement')
    check((store.root/'catalog.json').read_bytes()==before,'rejected import leaves catalog untouched')
    reject(lambda:store.configure({'sets':{'empty':{'title':'Empty','revision':'v1','members':[]}}}),'empty set rejects')
    check((store.root/'catalog.json').read_bytes()==before,'invalid settings atomic')
    def zipped(entries):
        stream=io.BytesIO()
        with zipfile.ZipFile(stream,'w') as z:
            for name,data in entries:z.writestr(name,data)
        return stream.getvalue()
    reject(lambda:store.stage(zipped([('../escape',b'no')])),'ZIP traversal rejects')
    reject(lambda:store.stage(zipped([('manifest.json',b'{}'),('manifest.json',b'{}')])),'duplicate archive entries reject')
    manifest=json.loads((sources/'deborah-defaults-v1/manifest.json').read_text())
    assets={p.name:p.read_bytes() for p in (sources/'deborah-defaults-v1').glob('*.ogg')}
    def broken(change):
        m=copy.deepcopy(manifest);change(m)
        return zipped([('manifest.json',json.dumps(m).encode()),*assets.items()])
    reject(lambda:store.stage(broken(lambda m:m['roles']['T0'].update(hash='0'*64))),'hash corruption rejects')
    reject(lambda:store.stage(broken(lambda m:m['roles']['VICTORY'].update(loop=True))),'looping fanfare rejects')
    reject(lambda:store.stage(broken(lambda m:m['roles']['T1'].update(bpm=123))),'incompatible tempo rejects')
    reject(lambda:store.stage(broken(lambda m:m['roles']['T0'].update(file='absent.ogg'))),'declared missing asset rejects')
    reject(lambda:store.stage(broken(lambda m:m['roles']['T0'].update(upload_token='do-not-project'))),'unknown metadata cannot leak into game state')
    reject(lambda:store.stage(broken(lambda m:m['roles']['T1']['cues'].update(pulse=[]))),'combat role cannot publish without pulse')
    reject(lambda:store.stage(broken(lambda m:m['roles']['T0']['cues']['quiet'][0].update(finish=999))),'out-of-range cue fails atomically')
    check((store.root/'catalog.json').read_bytes()==before,'all failed uploads preserve registration')
    app=application(store,'t'*32)
    status=[]
    app({'REQUEST_METHOD':'POST','PATH_INFO':'/v1/uploads','wsgi.input':io.BytesIO(block),'CONTENT_LENGTH':str(len(block))},lambda s,h:status.append(s))
    check(status[-1].startswith('401'),'unauthenticated upload denied')
    status=[]
    result=app({'HTTP_AUTHORIZATION':'Bearer '+'t'*32,'REQUEST_METHOD':'POST','PATH_INFO':'/v1/uploads',
                'wsgi.input':io.BytesIO(block[:-1]),'CONTENT_LENGTH':str(len(block))},lambda s,h:status.append(s))
    check(status[-1].startswith('400'),'interrupted upload denied')
    # Existing four-track block migration is an explicit new version/manifest.
    partial=root/'partial';partial.mkdir()
    legacy={**manifest,'kind':'block','id':'four-track','version':'v1','roles':{r:manifest['roles'][r] for r in ('T0','T1','T2','T3')}}
    (partial/'manifest.json').write_text(json.dumps(legacy))
    for spec in legacy['roles'].values():(partial/spec['file']).write_bytes(assets[spec['file']])
    store.publish(store.stage(bundle(partial)))
    roles=store.catalog()['blocks']['four-track']['roles']
    check(roles['BOSS']==roles['VICTORY']==roles['INTERLUDE']=='inherit','partial/legacy roles normalize to inheritance')
    # A new immutable version may enrich pre-cue hash metadata for future plans.
    from catalog_service import atomic_json
    old=store.catalog()
    for a in old['assets'].values():a.pop('cues',None)
    atomic_json(store.root/'catalog.json',old)
    legacy['version']='v2';(partial/'manifest.json').write_text(json.dumps(legacy))
    store.publish(store.stage(bundle(partial)))
    check(all(store.catalog()['assets'][roles[r]].get('cues') for r in ('T0','T1','T2','T3')),'new immutable version enriches legacy assets without rewriting audio')
    old=store.catalog()
    for a in old['assets'].values():a.pop('delivery',None)
    atomic_json(store.root/'catalog.json',old)
    store.prepare_delivery()
    check(all(a.get('delivery')==1 for a in store.catalog()['assets'].values()),'legacy delivery preparation enriches future plans')
    frozen=json.loads(json.dumps(old));check(all('delivery' not in a for a in frozen['assets'].values()),'frozen plans remain unchanged')
print(f'MUSIC_INGESTION PASS {checks}')

#!/usr/bin/env python3
"""Render an isolated 16-bar candidate bank through the pinned Surge patches.

Never changes the shipping catalog, audio or manifest. Every candidate is
actually Vorbis-decoded and checked by the canonical renderer. No runtime
acceptance or guide-specific compliance is implied by an offline render.
"""
import argparse
from concurrent.futures import ProcessPoolExecutor
import hashlib
import json
import multiprocessing
from pathlib import Path
import platform
import sys
import numpy as np
import scipy
import build_ms2_surge as renderer
from surge.bank import LOCK, PATCHES, PATCH_SHA, load_surge

ROOT=Path(__file__).resolve().parents[2]

def sha(data):return hashlib.sha256(data).hexdigest()

def render_task(task):
    record,bpm,module,work,fingerprint,destination=task
    renderer.DEST=Path(destination)
    return renderer.render_clip((record,bpm,module,work,fingerprint))

def render(candidate, module, jobs=2, sample=False):
    candidate=candidate.resolve()
    if ROOT/'build' not in candidate.parents:
        raise ValueError('Rendering must stay in an isolated repository build/ directory')
    audit=json.loads((candidate/'MS3_16_BAR_AUDIT.json').read_text())
    catalog=renderer.lua_json(candidate/'catalog/catalog.lua')
    if audit['catalogRevision']!=catalog['revision']:raise ValueError('Candidate revision mismatch')
    pages={};bank=[]
    for aid,a in sorted(catalog['assets'].items()):
        selected=a['clips']
        if sample:
            if a['role']!='T0':continue
            selected=[max(selected,key=lambda c:(len(c['motifs']),-c['offset']))]
        for c in selected:
            if c['page'] not in pages:pages[c['page']]=renderer.lua_json(candidate/'catalog'/c['page'])
            ns=pages[c['page']][c['id']]
            # The curation hash uses sorted JSON keys; event lists have none.
            if sha(json.dumps(ns,separators=(',',':')).encode())!=c['noteSHA256']:raise ValueError('Changed source notes: '+c['id'])
            if c['beats']!=(64 if a['loop'] else 12):raise ValueError('Not a real long-form candidate')
            bank.append({**c,'block':a['block'],'role':a['role'],'asset':aid,'notes':ns})
    destination=candidate/'audio';destination.mkdir(exist_ok=True)
    work=candidate/'pcm';work.mkdir(exist_ok=True)
    module=module.resolve()
    surge=load_surge(module)
    voices,_=renderer.voice_gate(surge,work)
    renderer_hash=sha(Path(renderer.__file__).read_bytes()+(ROOT/'tools/music/surge/bank.py').read_bytes()+Path(__file__).read_bytes())
    fingerprint=sha((renderer_hash+PATCH_SHA+LOCK['bindingPatchSHA256']).encode())
    tasks=[(c,catalog['bpm'],str(module),str(work),fingerprint,str(destination)) for c in bank]
    results=[]
    with ProcessPoolExecutor(max_workers=jobs,mp_context=multiprocessing.get_context('spawn')) as pool:
        for i,r in enumerate(pool.map(render_task,tasks),1):
            results.append(r)
            if i%8==0 or i==len(tasks):print(f'Candidate audio {i}/{len(tasks)}; {sum(x["bytes"] for x in results):,} bytes',flush=True)
    total=sum(r['bytes'] for r in results)
    if total>LOCK['packageBudgetBytes']:raise ValueError('Candidate exceeds existing encoded bank budget')
    manifest=dict(schema=1,status='OFFLINE CANDIDATE; NOT INSTALLED',catalogRevision=catalog['revision'],sampleOnly=sample,
                  clipCount=len(results),totalBytes=total,rendererSHA256=renderer_hash,patchSHA256=PATCH_SHA,
                  surge={**LOCK,'reportedBuildVersion':surge.getVersion()},voices=voices,
                  toolchain=dict(python=platform.python_version(),numpy=np.__version__,scipy=scipy.__version__,
                                 encoder=renderer.subprocess.check_output(['ffmpeg','-version'],text=True).splitlines()[0]),
                  clips=results)
    (candidate/'MS3_16_BAR_RENDER.json').write_text(json.dumps(manifest,indent=2)+'\n')
    # Eight full passages, not short highlights. Use one shared gain ceiling,
    # analogous to in-game master boost, never loudness-normalize each block.
    examples=[next(r for r in results if r['block']==b and r['role']=='T0') for b in 'abcdefgh']
    gain=min(4,.8/max(r['peak'] for r in examples))
    cues=[];pieces=[];seconds=0
    for r in examples:
        pcm=renderer.wav_read(work/(r['id']+'.wav'))*gain
        cues.append(dict(block=r['block'],clip=r['id'],seconds=seconds,sourceBeats=next(c['sourceRangeBeats'] for c in bank if c['id']==r['id'])))
        pieces += [pcm,np.zeros((renderer.RATE,2))]
        seconds+=len(pcm)/renderer.RATE+1
    renderer.wav_write(work/'audition.wav',np.concatenate(pieces))
    audition=renderer.encode(work/'audition.wav',candidate/'MS3_16_BAR_AUDITION.ogg','ms3-s16-audition')
    (candidate/'MS3_16_BAR_AUDITION.json').write_text(json.dumps(dict(cues=cues,gain=gain,**audition),indent=2)+'\n')
    print(json.dumps(dict(clips=len(results),bytes=total,auditionSeconds=audition['duration'])),flush=True)
    return manifest

if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--candidate',type=Path,required=True)
    p.add_argument('--surge-module',type=Path,required=True)
    p.add_argument('--jobs',type=int,choices=range(1,9),default=2)
    p.add_argument('--sample',action='store_true',help='Eight full Chill passages only; not a complete bank')
    a=p.parse_args();render(a.candidate,a.surge_module,a.jobs,a.sample)

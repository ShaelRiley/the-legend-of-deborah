#!/usr/bin/env python3
"""Compile the approved long-form source score into the canonical bundle.

Use only while authoring a complete new audio bank. The renderer and release
validators require exact catalog/audio parity before this tree may be published.
The source mapper remains independently testable in its isolated build directory.
"""
import argparse
import hashlib
import json
from pathlib import Path
import statistics
import tempfile

from build_ms2 import compact, export_clips
from remap_ms3_sixteen_bar import build, similarity, normalized_features, BAR, PPQ

ROOT=Path(__file__).resolve().parents[2]
BUNDLE=ROOT/'gamemodes/legend_of_deborah/gamemode/lod/ms2'


def compile_score(source, destination=BUNDLE, documents=None):
    with tempfile.TemporaryDirectory(prefix='lod-ms3-source-') as temp:
        candidate=Path(temp)
        catalog,payloads,audit=build(source,candidate)
        turnarounds={}
        # These are authored ending choices, not a live stacked drum layer.
        # A weak best outgoing motif/cadence receives one source-derived kit
        # turnaround. All melodic voices, kick and bass keep their source time.
        for asset in catalog['assets'].values():
            if not asset['loop']:continue
            fill=audit['bridges'].get(asset['id']+'-bridge')
            if not fill:continue
            for clip in asset['clips']:
                target=next(c for c in asset['clips'] if c['id']==clip['next'][0])
                evidence=similarity(clip,target)
                if not evidence['fillSuggested']:continue
                cid=clip['id'];notes=payloads[cid];start=15*BAR
                replaced=[n for n in notes if n[2] in (5,6,8) and n[0]>=start]
                if not replaced:continue  # do not manufacture a fill over an authored rest
                level=statistics.median(n[4] for n in replaced)/statistics.median(n[4] for n in fill['notes'])
                level=max(.5,min(1.25,level))
                kept=[]
                for t,d,i,p,v in notes:
                    if i in (5,6,8):
                        if t>=start:continue
                        d=min(d,start-t)
                    kept.append([t,d,i,p,v])
                inserted=[[start+t,min(d,BAR-t),i,p,max(32,min(112,round(v*level)))] for t,d,i,p,v in fill['notes']]
                arranged=sorted(kept+inserted,key=lambda n:(n[0],n[2],n[3]))
                if len(arranged)>2048:raise ValueError('Turnaround exceeds note bound: '+cid)
                payloads[cid]=arranged
                clip.update(normalized_features(arranged,64))
                clip['noteSHA256']=hashlib.sha256(compact(arranged).encode()).hexdigest()
                clip['turnaround']=dict(source=asset['id']+'-bridge',bar=16,to=target['id'])
                turnarounds[cid]=dict(source=asset['id']+'-bridge',sourceRangeBeats=fill['sourceRangeBeats'],
                    sourceSHA256=fill['sourceSHA256'],destinationBeats=[60,64],reason=evidence,
                    removed=replaced,inserted=inserted,preserveVoices=[0,1,2,3,4,7])
                audit['clips'][cid]['percussionTurnaround']=turnarounds[cid]
                audit['clips'][cid]['notes']=len(arranged)
                audit['clips'][cid]['quarterNoteCounts']=[sum(j*16*PPQ<=n[0]<(j+1)*16*PPQ for n in arranged) for j in range(4)]
        destination=Path(destination);destination.mkdir(parents=True,exist_ok=True)
        pages=[];page={};index=0
        lookup={c['id']:c for a in catalog['assets'].values() for c in a['clips']}
        def flush():
            nonlocal page,index
            if not page:return
            name=f'notes_{index:03d}.lua'
            (destination/name).write_text('return [==['+compact(page)+']==]\n')
            pages.append(name);page={};index+=1
        for cid,notes in sorted(payloads.items()):
            if len(compact({cid:notes}).encode())>46000:raise ValueError('Oversized note shard')
            if page and len(compact({**page,cid:notes}).encode())>46000:flush()
            page[cid]=notes;lookup[cid]['page']=f'notes_{index:03d}.lua'
        flush()
        for old in destination.glob('notes_*.lua'):
            if old.name not in pages:old.unlink()
        catalog['pages']=pages
        catalog['authoring']='source-16-turnarounds-v1'
        catalog['revision']='ms3-s16-'+hashlib.sha256(compact([catalog,payloads]).encode()).hexdigest()[:16]
        (destination/'catalog.lua').write_text('return [==['+compact(catalog)+']==]\n')
        (destination/'files.lua').write_text('return {'+','.join('"'+p+'"' for p in ['catalog.lua',*pages])+'}\n')
        audit.update(catalogRevision=catalog['revision'],notes=sum(map(len,payloads.values())),
            turnarounds=turnarounds,runtimeStatus='Source score; matching rendered bank required. Native listening remains pending.')
        report=dict(schema=2,revision=catalog['revision'],midi_files=audit['sourceMidiFiles'],
            arrangements=48,blocks=8,clips=len(payloads),notes=audit['notes'],base_bpm=130,
            sources=audit['sources'],clips_catalog=[dict(block=a['block'],role=a['role'],**c,notes=len(payloads[c['id']]))
                for a in catalog['assets'].values() for c in a['clips']])
        if documents:
            documents=Path(documents);documents.mkdir(parents=True,exist_ok=True)
            (documents/'MS2_CATALOG.json').write_text(json.dumps(report,indent=2)+'\n')
            (documents/'MS3_16_BAR_AUDIT.json').write_text(json.dumps(audit,indent=2)+'\n')
            (documents/'MS3_16_BAR_TRANSITIONS.json').write_text(json.dumps({c['id']:c['handoffs'] for a in catalog['assets'].values() for c in a['clips']},indent=2)+'\n')
            export_clips(catalog,payloads,documents/'MS2_CLIPS.zip')
            direction=(candidate/'MS3_16_BAR_DIRECTION.md').read_text()
            direction=direction[:direction.index('## Remaining integration gate')]
            direction=direction.replace('source arrangement candidates','source arrangements').replace('**Authoring candidate, not a shipping audio replacement.** The active game remains unchanged.',
                '**Compiled long-form score.** Publication requires the matching freshly rendered bank and passing integration gates.')
            # Replace the original candidate summary without obscuring source windows.
            lines=direction.splitlines();lines[2]=f"Revision `{catalog['revision']}`. 465 original MIDIs → 157 sixteen-bar passages + eight short fanfares; {audit['notes']:,} arranged notes."
            direction='\n'.join(lines)+'\n\n## Source-derived closing turnarounds\n\n'
            direction+=f"{len(turnarounds)} of the 157 ordinary passages replace only final-bar tom/snare/hat slots where the preferred outgoing motif/cadence match is weak. The fill is drawn from that same block and role and mixed into the offline recording; it is not an extra live kit or a compulsory fill at every seam. Melody, harmony, bass and kick remain unchanged. Other passages retain their authored ending. `MS3_16_BAR_AUDIT.json` records each removed/inserted event and exact source bar. These fills do not extend musical time or force an unprepared successor.\n"
            direction+='\nThe linked arrangement guide remains unverified; source-based arrangement decisions here are not attributed to it. Native listening/performance acceptance remains separate from source and waveform validation.\n'
            (documents/'MS2_CATALOG.md').write_text(direction)
        return catalog,payloads,report,audit


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--source',type=Path,default=ROOT/'tools/music/sources')
    p.add_argument('--output',type=Path,default=BUNDLE)
    p.add_argument('--docs',type=Path,default=ROOT/'docs')
    a=p.parse_args();c,n,r,audit=compile_score(a.source,a.output,a.docs)
    print(compact(dict(revision=c['revision'],clips=len(n),notes=r['notes'],turnarounds=len(audit['turnarounds']))))

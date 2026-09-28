#!/usr/bin/env python3
"""Generate original D-Dorian ostinato defaults outside the Workshop package.

A reproducible starter profile for native audition, not the 32-block album.
Requires numpy and ffmpeg; output contains seven 44.1-kHz stereo Vorbis masters.
"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile
import wave
import numpy as np
from catalog_service import probe

SR=44100
CREDITS='Original procedural score for The Legend of Deborah; Shael Riley project, 2026'
SOURCE='Original deterministic synthesis; tools/music/generate_defaults.py; no samples or external compositions'

def render(role):
    duration=6.5 if role=='VICTORY' else 16.0
    n=int(SR*duration);t=np.arange(n)/SR
    level={'T0':0,'T1':1,'T2':2,'T3':3,'BOSS':3,'INTERLUDE':0,'VICTORY':1}[role]
    left=np.zeros(n);right=np.zeros(n)
    def voice(start,length,freq,amp,kind='bass',pan=0):
        a=int(start*SR);b=min(n,a+int(length*SR))
        if b<=a:return
        x=np.arange(b-a)/SR
        if kind=='kick':
            phase=2*np.pi*(46*x+65*.022*(1-np.exp(-x/.022)))
            y=np.sin(phase)*np.exp(-x*17)
        elif kind=='hat':
            y=(np.sin(2*np.pi*7013*x)+np.sin(2*np.pi*9323*x))*.5*np.exp(-x*60)
        else:
            # Harmonic acid-like bass/brass without a sample or outside melody.
            y=np.sin(2*np.pi*freq*x)+.34*np.sin(2*np.pi*freq*2*x)+.15*np.sin(2*np.pi*freq*3*x)
            y*=np.minimum(1,x/.006)*np.minimum(1,(length-x)/.035)*np.exp(-x*(4 if kind=='bass' else 1.2))
        left[a:b]+=amp*y*np.sqrt((1-pan)/2)
        right[a:b]+=amp*y*np.sqrt((1+pan)/2)
    # D, E, F, G, A, B, C: a fixed D-Dorian pitch vocabulary.
    notes=[38,45,48,40,41,45,47,43]
    if role=='BOSS':
        notes=[38,38,45,41,48,47,45,40]
    if role=='VICTORY':
        melody=[62,65,69,71,69,65,64,62]
        for i,note in enumerate(melody):
            start=i*.5
            for harmony in (0,-12):voice(start,.48 if i<7 else 2.5,440*2**((note+harmony-69)/12),.17,'brass',-.15 if harmony else .15)
        for note in (38,50,57,62):voice(4,2.5,440*2**((note-69)/12),.10,'brass')
    else:
        interval=.5 if level==0 else .25
        for i,start in enumerate(np.arange(0,duration,interval)):
            note=notes[i%8]+(12 if role=='INTERLUDE' else 0)
            voice(start,interval*.94,440*2**((note-69)/12),.15+.015*level,'bass',.15*np.sin(i))
        if level:
            for start in np.arange(0,duration,.5):voice(start,.22,0,.28,'kick')
            for start in np.arange(.25,duration,.5):voice(start,.10,0,.06+.012*level,'hat',.4)
        if level>=2:
            for i,start in enumerate(np.arange(0,duration,.5/3)):
                if i%3:voice(start,.13,440*2**((notes[(i//3)%8]+24-69)/12),.055,'brass',-.3)
        if level==3:
            for i,start in enumerate(np.arange(0,duration,.25)):
                voice(start,.08,0,.025,'hat',-.4)
                if i%4==3:voice(start,.22,440*2**((notes[(i//4)%8]+12-69)/12),.07,'brass')
        # Gentle upper D/A ostinato leaves headroom for gameplay cues.
        for i,start in enumerate(np.arange(0,duration,2)):
            voice(start,1.8,440*2**(((62 if i%2==0 else 69)-69)/12),.07,'brass',-.2)
    audio=np.stack((left,right),axis=1)
    edge=min(int(.008*SR),n//2)
    audio[:edge]*=np.linspace(0,1,edge)[:,None];audio[-edge:]*=np.linspace(1,0,edge)[:,None]
    # Deliberately leave >6 dB peak headroom; no limiting/clipping.
    audio*=min(1,.46/max(.001,np.max(np.abs(audio))))
    return np.round(audio*32767).astype('<i2'),duration

def generate(destination):
    destination.mkdir(parents=True,exist_ok=True)
    profile=destination/'deborah-defaults-v1';profile.mkdir(exist_ok=True)
    roles={}
    with tempfile.TemporaryDirectory() as tmp:
        for role in ('T0','T1','T2','T3','BOSS','VICTORY','INTERLUDE'):
            samples,duration=render(role);wav=Path(tmp)/(role+'.wav');ogg=profile/(role.lower()+'.ogg')
            with wave.open(str(wav),'wb') as f:
                f.setnchannels(2);f.setsampwidth(2);f.setframerate(SR);f.writeframes(samples.tobytes())
            subprocess.run(['ffmpeg','-v','error','-y','-i',str(wav),'-map_metadata','-1','-c:a','libvorbis','-b:a','128k',str(ogg)],check=True)
            decoded=probe(ogg);data=ogg.read_bytes()
            roles[role]=dict(file=ogg.name,hash=hashlib.sha256(data).hexdigest(),bytes=len(data),duration=decoded,
                codec='vorbis',rate=SR,channels=2,loop=role!='VICTORY',loopStart=0,loopEnd=decoded,
                bpm=120,beats=13 if role=='VICTORY' else 32,phase=0,grid='d-dorian-120-32' if role!='VICTORY' else 'victory-13',
                handoff='envelope',gain=1,headroom=6,source=SOURCE,credits=CREDITS)
            if role != 'VICTORY':
                # Authored knowledge of this deterministic score: sparse ostinato
                # T0/interlude versus the foreground kick/hat of the combat roles.
                mode = 'quiet' if role in ('T0', 'INTERLUDE') else 'pulse'
                roles[role]['cues'] = dict(version=1, source='authored', pulse=[], quiet=[])
                roles[role]['cues'][mode] = [dict(start=start, finish=16, energy=.4 if mode=='quiet' else .9) for start in (0, 4, 8)]
    manifest=dict(schema=1,kind='profile',id='deborah-defaults',version='v1',title='Deborah — Dorian Foundations',credits=CREDITS,roles=roles)
    (profile/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
    block=destination/'deborah-foundations-v1';block.mkdir(exist_ok=True)
    (block/'manifest.json').write_text(json.dumps(dict(schema=1,kind='block',id='deborah-foundations',version='v1',title='Dorian Foundations',credits=CREDITS,roles={role:'inherit' for role in roles}),indent=2)+'\n')
    (destination/'defaults.json').write_text(json.dumps({'projectDefault':'deborah-defaults','sets':{}},indent=2)+'\n')
    return destination
if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('output',type=Path)
    print(generate(p.parse_args().output))

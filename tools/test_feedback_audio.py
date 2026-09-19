#!/usr/bin/env python3
"""Exact authored asset reproducibility, format, levels and identity checks."""
import hashlib
import math
import re
import struct
import wave
from pathlib import Path
from generate_feedback_audio import ROOT, RATE, SCORES, render
identities=set()
for name,(pitches,duration) in SCORES.items():
    with wave.open(str(ROOT/(name+'.wav')),'rb') as f:
        assert (f.getnchannels(),f.getsampwidth(),f.getframerate())==(1,2,RATE)
        raw=f.readframes(f.getnframes())
    samples=struct.unpack('<'+'h'*(len(raw)//2),raw)
    assert list(samples)==render(pitches,duration),name
    assert samples[0]==samples[-1]==0 and len(samples)/RATE<=.30
    rms=math.sqrt(sum(x*x for x in samples)/len(samples))/32767
    assert .09<rms<.11 and max(abs(x) for x in samples)/32767<=.401,(name,rms)
    identity=hashlib.sha256(raw).hexdigest();assert identity not in identities;identities.add(identity)
assert SCORES['hit_confirm']==([81],.045)
assert sum(p.stat().st_size for p in ROOT.glob('*.wav'))<500_000
source=Path('gamemodes/legend_of_deborah/gamemode/lod/sh_audio.lua').read_text()
for name in SCORES: assert "'"+name+"'" in source,name
for p in Path('gamemodes').rglob('*.lua'):
    if 'manual' in p.parts: continue
    for name in re.findall(r'legend_of_deborah/feedback/([a-z_]+)\.wav',p.read_text()):
        assert name in SCORES,(str(p),name)
print(f'FEEDBACK_AUDIO_PASS: {len(SCORES)} unique, reproducible mono PCM assets; no missing cues, bounded duration/size and consistent RMS without clipping')

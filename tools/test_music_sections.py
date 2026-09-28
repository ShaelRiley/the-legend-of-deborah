#!/usr/bin/env python3
"""Pulse must win over loudness, with silence/dropouts kept out of cue spans."""
import copy
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import wave
import numpy as np
sys.path.insert(0, str(Path(__file__).parent / 'music'))
from section_cues import analyze_samples, analyze_file, validate_cues

checks = 0
def check(ok, message):
    global checks
    checks += 1
    assert ok, message

sr, duration = 11025, 48
t = np.arange(sr * duration) / sr
# The intro pad is louder than the drums: level alone must never select it.
audio = np.sin(2 * np.pi * 220 * t) * np.where(t < 8, .7, .018)
for start, end in ((8, 24), (32, 40)):
    for beat in np.arange(start, end, .5):
        a = round(beat * sr); n = round(.24 * sr); x = np.arange(n) / sr
        audio[a:a+n] += .45 * np.sin(2*np.pi*70*x) * np.exp(-18*x)
cues = analyze_samples(audio, sr, duration, 120)
check(bool(cues['pulse']) and bool(cues['quiet']), 'both rhythmic classes found')
for cue in cues['pulse']:
    check(any(a <= cue['start'] < cue['finish'] <= b for a,b in ((8,24),(32,40))), 'pulse spans exclude loud intro, breakdown and outro')
check(any(c['start'] >= 40 for c in cues['quiet']), 'quiet outro retained')
check(cues == analyze_samples(audio, sr, duration, 120), 'analysis deterministic')
drone = analyze_samples(.7*np.sin(2*np.pi*220*t), sr, duration, 120)
check(not drone['pulse'] and bool(drone['quiet']), 'loud drone has no sustained pulse')
impact = .03*np.sin(2*np.pi*220*t)
impact[8*sr:8*sr+100] += .8
check(not analyze_samples(impact, sr, duration, 120)['pulse'], 'one impact is not a sustained beat')
for mutation in (
    lambda c: c['pulse'][0].update(start=float('nan')),
    lambda c: c['pulse'][0].update(finish=999),
    lambda c: c['pulse'][0].update(start=8.1),
    lambda c: c['quiet'].append(dict(c['pulse'][0])),
    lambda c: c.update(version=2),
    lambda c: c['pulse'][0].update(energy=True),
):
    bad = copy.deepcopy(cues); mutation(bad)
    try: validate_cues(bad, duration, 120, 0)
    except ValueError: check(True, 'malformed cue rejected')
    else: raise AssertionError('malformed cue accepted')
try: analyze_samples(np.zeros(sr*16), sr, 16, 120)
except ValueError: check(True, 'silence rejected')
else: raise AssertionError('silence labeled musical')
with tempfile.TemporaryDirectory() as tmp:
    wav, ogg = Path(tmp)/'fixture.wav', Path(tmp)/'fixture.ogg'
    with wave.open(str(wav), 'wb') as f:
        f.setnchannels(2); f.setsampwidth(2); f.setframerate(sr)
        f.writeframes(np.repeat(np.round(audio*32767).astype('<i2')[:,None],2,axis=1).tobytes())
    subprocess.run(['ffmpeg','-v','error','-y','-i',str(wav),'-ar','44100','-c:a','libvorbis',str(ogg)],check=True)
    decoded = analyze_file(ogg, duration, 120)
    check(bool(decoded['pulse']) and bool(decoded['quiet']), 'real Vorbis decode supplies both classes')
    for cue in decoded['pulse']:
        check(any(a <= cue['start'] < cue['finish'] <= b for a,b in ((8,24),(32,40))), 'lossy decode retains safe rhythmic boundaries')
    check(len(json.dumps(decoded)) < 2500, 'only compact interval metadata needed at runtime')
print(f'MUSIC_SECTIONS_ANALYSIS PASS {checks}')

#!/usr/bin/env python3
"""Decode bounded original boss punctuation; not an audible/native judgment."""
from pathlib import Path
import array,hashlib,json,wave
root=Path(__file__).resolve().parents[1]/'sound/legend_of_deborah/boss'
expected={'honk':.38,'boing':.55,'clang':.5,'rumble':.65}
assert {p.stem for p in root.glob('*.wav')}==set(expected)
rows=[]
for name,seconds in expected.items():
    p=root/(name+'.wav')
    with wave.open(str(p),'rb') as f:
        assert f.getnchannels()==1 and f.getsampwidth()==2 and f.getframerate()==22050
        assert f.getnframes()==int(seconds*22050)
        values=array.array('h',f.readframes(f.getnframes()))
    assert values and 1000<max(abs(v) for v in values)<32767
    assert abs(sum(values)/len(values))<600
    rows.append({'cue':name,'frames':len(values),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
print('BOSS_AUDIO_ASSETS_PASS '+json.dumps(rows))

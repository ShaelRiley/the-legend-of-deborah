#!/usr/bin/env python3
"""Check shipped original motifs against their deterministic source and Source PCM format."""
import runpy,struct,wave
from pathlib import Path
source=runpy.run_path(str(Path(__file__).with_name('generate_adventure_audio.py')))
for name,score in source['SCORES'].items():
    expected=source['render'](score)
    with wave.open(str(source['ROOT']/(name+'.wav')),'rb') as f:
        assert (f.getnchannels(),f.getsampwidth(),f.getframerate(),f.getcomptype())==(1,2,22050,'NONE')
        raw=f.readframes(f.getnframes())
    actual=struct.unpack('<'+'h'*(len(raw)//2),raw)
    assert tuple(expected)==actual,name+' asset drift'
    assert 0<len(actual)/22050<3
    assert max(abs(v) for v in actual)<32767*.75
    assert actual[0]==0 and actual[-1]==0
print('ADVENTURE_AUDIO_PASS — 6 reproducible original PCM motifs, bounded duration, no clipping')

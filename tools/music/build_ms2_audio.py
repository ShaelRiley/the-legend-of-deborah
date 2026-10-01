#!/usr/bin/env python3
"""Bake a tiny synthetic tone bank for MS2's older-engine audio fallback.

These are single virtual-instrument tones/hits, never soundtrack recordings.
The primary Web Audio path synthesizes instruments itself.
"""
import array
import math
from pathlib import Path
import subprocess
import sys
import wave

ROOT=Path(__file__).resolve().parents[2]
DEST=ROOT/'gamemodes/legend_of_deborah/content/sound/lod/ms2'
NAMES=('acid','industrial','strings','brass','bass')
PITCH=(64,60,69,64,40)
RATE=22050


def write(name,pcm):
    a=array.array('h',(int(max(-.99,min(.99,x))*32767) for x in pcm))
    if sys.byteorder!='little':a.byteswap()
    with wave.open(str(DEST/(name+'.wav')),'wb') as w:
        w.setparams((1,2,RATE,0,'NONE','not compressed'));w.writeframes(a.tobytes())


def main():
    DEST.mkdir(parents=True,exist_ok=True)
    for inst,(name,pitch) in enumerate(zip(NAMES,PITCH)):
        freq=440*2**((pitch-69)/12)
        # Exactly sixteen periods, so the native loop boundary has no click.
        size=round(RATE/freq*16)
        pcm=[]
        for i in range(size):
            phase=2*math.pi*16*i/size
            value=0
            for harmonic in range(1,10):
                if inst==0:weight=1/harmonic**1.3
                elif inst==1:weight=(1 if harmonic%2 else .4)/harmonic**1.15
                elif inst==2:weight=1/harmonic**1.35
                elif inst==3:weight=.57**(harmonic-1) if harmonic<7 else 0
                else:weight=(1/harmonic**1.35 if harmonic%2 else .15/harmonic)
                value+=math.sin(phase*harmonic)*weight
            if inst==1:value=1.7*value/(1+abs(value)*1.7)
            pcm.append(value*.27)
        write(name,pcm)
    # Use the exact primary engine's percussion algorithm, not a second kit.
    code="const s=require('./tools/music/ms2_engine.js');for(const k of ['kick','tom','snare','open','closed']){const b=s.percussion(k,22050);process.stdout.write(k+' '+JSON.stringify(Array.from(b))+'\\n');}"
    import json
    result=subprocess.run(['node','-e',code],cwd=ROOT,text=True,capture_output=True,check=True)
    for line in result.stdout.splitlines():
        kind,data=line.split(' ',1);write(kind,json.loads(data))
    engine=ROOT/'gamemodes/legend_of_deborah/gamemode/lod/ms2/engine.lua'
    engine.write_text('return [==['+(ROOT/'tools/music/ms2_engine.js').read_text()+']==]\n')
    print('MS2 native tone bank:',sum(p.stat().st_size for p in DEST.glob('*.wav')),'bytes')


if __name__=='__main__':main()

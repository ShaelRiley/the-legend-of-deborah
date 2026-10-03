#!/usr/bin/env python3
"""Small deterministic original mono encounter punctuation. No external assets."""
from pathlib import Path
import math,random,struct,wave
ROOT=Path(__file__).resolve().parents[1]/'sound/legend_of_deborah/boss'
ROOT.mkdir(parents=True,exist_ok=True)
RATE=22050
for name,seconds in [('honk',.38),('boing',.55),('clang',.5),('rumble',.65)]:
    rng=random.Random(41);samples=[];phase=0
    for i in range(int(RATE*seconds)):
        t=i/RATE;u=t/seconds;env=min(1,t/.012)*max(0,1-u)**1.5
        if name=='honk':
            phase+=2*math.pi*(205+12*math.sin(2*math.pi*11*t))/RATE
            v=(math.sin(phase)+.48*math.sin(phase*2)+.2*math.sin(phase*3))*env*.37
        elif name=='boing':
            phase+=2*math.pi*(160+650*math.exp(-t*12))/RATE
            v=math.sin(phase+2*math.sin(2*math.pi*27*t))*env*.5
        elif name=='clang':
            v=sum(math.sin(2*math.pi*f*t)*math.exp(-t*k) for f,k in [(1100,9),(1577,12),(2407,16)])*env*.22
        else:v=(rng.uniform(-1,1)*.4+math.sin(2*math.pi*57*t)*.6)*env*.6
        samples.append(struct.pack('<h',round(max(-.95,min(.95,v))*32767)))
    with wave.open(str(ROOT/(name+'.wav')),'wb') as out:
        out.setnchannels(1);out.setsampwidth(2);out.setframerate(RATE);out.writeframes(b''.join(samples))
print('BOSS_AUDIO: four deterministic original mono cues')

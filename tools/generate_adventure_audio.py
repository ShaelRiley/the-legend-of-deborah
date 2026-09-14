#!/usr/bin/env python3
"""Reproduce original LoD discovery motifs. No samples or borrowed melodies."""
import math
import struct
import wave
from pathlib import Path
RATE = 22050
ROOT = Path(__file__).resolve().parents[1] / 'sound/legend_of_deborah/adventure'
# (start seconds, MIDI pitch, duration, amplitude). A common Dorian timbre;
# different contours distinguish finding, opening, learning and celebrating.
SCORES = {
    'discovery': [(0,74,.30,.45),(.13,77,.30,.42),(.27,76,.33,.40),(.44,81,.54,.46),(.48,62,.62,.18)],
    'unlock': [(0,50,.22,.25),(.08,69,.24,.37),(.19,74,.29,.42),(.34,78,.50,.37),(.34,81,.50,.25)],
    'learn': [(0,69,.38,.30),(.16,76,.35,.30),(.32,77,.37,.30),(.51,83,.50,.31),(.73,81,.64,.37)],
    'level_up': [(0,62,.32,.22),(0,74,.28,.40),(.14,76,.27,.36),(.28,81,.28,.39),(.43,79,.26,.36),(.60,86,.69,.39),(.60,74,.65,.22)],
    'rescue': [(0,62,.34,.24),(0,74,.27,.35),(.16,77,.25,.34),(.33,81,.31,.38),(.56,79,.27,.33),(.75,76,.29,.34),(.95,81,.40,.36),(1.22,86,.72,.38),(1.22,77,.72,.24),(1.22,62,.75,.19)],
    'feat': [(0,74,.20,.34),(.09,81,.38,.34),(.09,65,.38,.16)],
}
def render(notes):
    length = max(t+d for t,_,d,_ in notes)+.35
    samples = [0.0]*int(length*RATE)
    for start,pitch,duration,amplitude in notes:
        hz=440*2**((pitch-69)/12)
        for n in range(int(duration*RATE)):
            t=n/RATE
            attack=min(1,t/.008)
            release=min(1,(duration-t)/.07)
            decay=math.exp(-3.4*t/duration)
            # Rounded mallet fundamental, short glassy overtone, tiny toy wobble.
            phase=2*math.pi*hz*t + .012*math.sin(2*math.pi*7*t)
            tone=math.sin(phase)+.20*math.sin(2*phase)*math.exp(-12*t)+.08*math.sin(3*phase)
            value=amplitude*tone*attack*release*decay
            i=int(start*RATE)+n
            samples[i]+=value
            echo=i+int(.115*RATE)
            if echo<len(samples): samples[echo]+=.13*value
    peak=max(abs(v) for v in samples)
    scale=min(1,.72/peak)
    return [int(max(-1,min(1,v*scale))*32767) for v in samples]
def main():
    ROOT.mkdir(parents=True,exist_ok=True)
    for name,notes in SCORES.items():
        data=render(notes)
        with wave.open(str(ROOT/(name+'.wav')),'wb') as f:
            f.setnchannels(1);f.setsampwidth(2);f.setframerate(RATE)
            f.writeframes(struct.pack('<'+'h'*len(data),*data))
        print(f'{name}: {len(data)/RATE:.2f}s, peak {max(abs(v) for v in data)/32767:.3f}')
if __name__=='__main__':main()

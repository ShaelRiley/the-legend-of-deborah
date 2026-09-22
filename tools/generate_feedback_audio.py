#!/usr/bin/env python3
"""Original compact D-Dorian audio icons; same rounded mallet as adventure cues."""
import math
import struct
import wave
from pathlib import Path
RATE = 22050
ROOT = Path(__file__).resolve().parents[1] / 'sound/legend_of_deborah/feedback'
# MIDI pitch contours, total duration. Hit = one note, no echo, 45 ms.
SCORES = {
 'cloud_step':([77,86,93],.13), 'hit_confirm':([81],.045), 'enemy_defeated':([86,81],.06), 'spatial_awareness':([74,86],.16),
 'loot_spawn':([69,77],.18), 'loot_pickup':([77,81],.13),
 'confirm':([74],.10), 'deny':([65,62],.16), 'dialogue':([69],.09),
 'gift':([62,69,77],.27), 'status':([74,73],.17), 'status_clear':([73,77],.17),
 'resist':([62,69],.12), 'weakness':([81,86],.14), 'proc':([77,74,81],.18),
 'danger':([62,65,62],.25), 'life':([74,81,86],.30), 'soldier':([50,57],.22),
 'progress':([69,74,81],.25), 'life_lost':([74,69,62],.28),
 'last_life':([62,50],.28), 'respawn':([57,62,74],.26),
 'objective_clear':([65,69,74],.25), 'map_open':([62,77],.13), 'map_close':([77,62],.13),
 'gps':([86,81,74],.22), 'dice_explode':([86,89],.09),
 'aim_lock':([81,81],.14), 'heat_warm':([69,70],.16),
 'heat_near':([77,78],.16), 'weapon_ready':([69,74],.15), 'ar2_warning':([50,62],.18),
 'enemy_warning':([57,60],.18), 'tetris_rotate':([77],.06),
 'tetris_move':([69],.04), 'tetris_drop':([50],.085),
 'tetris_clear':([74,77,81],.23), 'tetris_end':([65,62,57],.23),
 'diversion':([62,74,62],.18), 'feedback':([86,77],.16),
 'status_poisoned':([57,65],.22), 'status_immolated':([74,77,74],.19),
 'status_held':([50,50],.20), 'status_muted':([69,57],.21),
 'status_intimidated':([62,58],.23), 'status_clumsy':([77,69,65],.20),
 'status_shattered':([86,74,62],.24), 'status_confused':([74,77,69],.23),
 'portal_depart':([62,74,81],.24), 'portal_arrive':([81,86],.20),
 'cast':([57,69,74],.18), 'summon_attack':([65,74],.12),
 'boss_arrive':([50,62,65],.30), 'boss_taunt':([62,50,57,45],.30), 'item_discard':([69,62],.10),
 'heal':([65,74,77],.21), 'status_reckless':([81,77,86],.20),
 'summon_arrive':([62,77,86],.22), 'summon_depart':([77,69,62],.18)
}
VOICES = {'boss_taunt':'square'}
def render(pitches,duration,voice='mallet'):
    count=int(duration*RATE)
    data=[0.0]*count
    step=duration/len(pitches)
    for i,pitch in enumerate(pitches):
        hz=440*2**((pitch-69)/12)
        start=int(i*step*RATE)
        length=min(count-start,int(step*RATE))
        for n in range(length):
            t=n/RATE;u=n/max(1,length-1)
            envelope=min(1,t/.004)*math.exp(-3*u)*min(1,(1-u)/.22)
            phase=2*math.pi*hz*t
            tone = (math.sin(phase)+math.sin(phase*3)/3+math.sin(phase*5)/5) if voice=='square' else (math.sin(phase)+.15*math.sin(phase*2)*math.exp(-20*t)+.045*math.sin(phase*3))
            data[start+n]=tone*envelope
    rms=math.sqrt(sum(v*v for v in data)/len(data))
    gain=min(.40/max(abs(v) for v in data),.105/max(rms,1e-9))
    return [round(v*gain*32767) for v in data]
def main():
    ROOT.mkdir(parents=True,exist_ok=True)
    for name,(notes,length) in SCORES.items():
        samples=render(notes,length,VOICES.get(name,'mallet'))
        with wave.open(str(ROOT/(name+'.wav')),'wb') as f:
            f.setnchannels(1);f.setsampwidth(2);f.setframerate(RATE)
            f.writeframes(struct.pack('<'+'h'*len(samples),*samples))
    print(f'{len(SCORES)} original mono PCM cues written')
if __name__=='__main__': main()

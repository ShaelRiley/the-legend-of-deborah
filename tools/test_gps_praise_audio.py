#!/usr/bin/env python3
"""Verify the shipped praise bank against its authored lines and playback markers."""
from pathlib import Path
import array
import json
import math
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
ROOM = ROOT / 'docs/lore/room/gps_navigation_praise_20261013.md'
SOURCE = ROOT / 'gamemodes/legend_of_deborah/gamemode/lod/sh_gps_praise.lua'
BANK = ROOT / 'gamemodes/legend_of_deborah/content/sound/lod/gps_praise_bank.mp3'
authored = re.findall(r'^\d+\. (.+)$', ROOM.read_text(), re.M)
source = SOURCE.read_text()
shipped = [json.loads(line) for line in re.findall(r'^    (".*"),$', source, re.M)]
assert shipped == authored and len(shipped) == len(set(shipped)) == 16
markers = [(int(i), float(start), float(duration)) for i, start, duration in
           re.findall(r'praise_(\d+)={(\d+\.\d+),(\d+\.\d+)}', source)]
assert [i for i, _, _ in markers] == list(range(1, 17))
probe = json.loads(subprocess.check_output([
    'ffprobe', '-v', 'error', '-select_streams', 'a', '-show_streams', '-of', 'json', str(BANK)]))
assert len(probe['streams']) == 1
stream = probe['streams'][0]
assert stream['codec_name'] == 'mp3' and stream['channels'] == 1
rate = int(stream['sample_rate'])
assert rate == 22050 and BANK.stat().st_size < 1024 * 1024
pcm = array.array('h', subprocess.check_output([
    'ffmpeg', '-v', 'error', '-i', str(BANK), '-f', 's16le', '-acodec', 'pcm_s16le', '-']))
previous_end = 0
for i, start, duration in markers:
    assert 1 < duration < 10 and start >= previous_end - .000002
    assert start + duration <= len(pcm) / rate + .002
    samples = pcm[round(start * rate):round((start + duration) * rate)]
    rms = math.sqrt(sum(v * v for v in samples) / len(samples))
    assert rms > 400, f'praise {i} is silent or too quiet: RMS {rms:.1f}'
    assert sum(abs(v) > 100 for v in samples) / len(samples) > .25, f'praise {i} lacks speech'
    previous_end = start + duration
print(f'GPS_PRAISE_AUDIO_PASS: 16 exact writer lines; non-silent decoded clips; '
      f'valid non-overlapping markers; mono {rate}Hz; {len(pcm)/rate:.2f}s; {BANK.stat().st_size} bytes')

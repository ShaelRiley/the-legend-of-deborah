#!/usr/bin/env python3
"""Audio-only game release gate: absence, restored cues, menus and lifecycle."""
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
for base in ('gamemodes', 'lua'):
    for path in (ROOT / base).rglob('*'):
        assert 'ms2_surge' not in path.parts and 'ms2' not in path.parts, str(path)
        if path.suffix != '.lua' or '/manual/html_' in str(path): continue
        source = re.sub(r'--[^\n]*', '', path.read_text())
        assert not re.search(r'MusicDirector|LOD_Music|LOD_EncounterMusicPressure|lod_music_', source), str(path)
assert not (ROOT / 'tools/music').exists()
assert not (ROOT / '.github/workflows/music.yml').exists()
commands = [
    ['python3','tools/run_lua54.py','tools/test_adventure_presentation.lua'],
    ['python3','tools/run_lua54.py','tools/test_low_end_options.lua'],
    ['python3','tools/run_lua54.py','tools/test_player_options.lua'],
    ['python3','tools/run_lua54.py','tools/test_native_resource_lifecycle.lua'],
    ['python3','tools/run_lua54.py','tools/test_loop_audio.lua'],
    ['python3','tools/test_adventure_audio.py'],
    ['python3','tools/test_feedback_audio.py'],
    ['python3','tools/validate_release_wiring.py'],
    ['python3','tools/build_manual.py','--check'],
]
for command in commands: subprocess.run(command, cwd=ROOT, check=True)
print('AUDIO_ONLY_PASS: no score code/banks/downloads; restored event audio, saved options, ambience lifecycle, movement and manual parity')

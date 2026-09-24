#!/usr/bin/env python3
"""Verify production content parity and run its ES5 reader with a DOM test double.

This is a logic test, not a substitute for Chromium or native GMod visual QA.
"""
import importlib.util
import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
catalog_check=subprocess.run(['python3','tools/run_lua54.py','tools/export_manual_catalog.lua','--check'],cwd=ROOT,capture_output=True,text=True)
assert catalog_check.returncode==0,catalog_check.stdout+catalog_check.stderr
spec=importlib.util.spec_from_file_location('manual_builder',ROOT/'tools/build_manual.py')
builder=importlib.util.module_from_spec(spec);spec.loader.exec_module(builder)
book=builder.chapters();html=builder.make_html(book)
manifest=(builder.TARGET/'manifest.lua').read_text()
count=int(re.search(r'chunks=(\d+)',manifest).group(1))
chunks=[]
for i in range(1,count+1):
    content=(builder.TARGET/f'html_{i:02}.lua').read_text()
    assert len(content.encode())<64000
    chunks.append(content.split('return [====[',1)[1].rsplit(']====]',1)[0])
assert ''.join(chunks)==html, 'Server transport source must equal the canonical document'
assert (builder.SOURCE/'manual.html').read_text()==html
entries=[e for c in book['chapters'] for e in c.get('entries',[])]
assert len(entries)==150 and len({e['id'] for e in entries})==150
assert len(json.loads((builder.SOURCE/'catalog.json').read_text())['EquipmentProperties'])==60
assert 'https://' not in html and 'http://' not in html, 'Reader must work without outside requests'
assert not list((ROOT/'gamemodes/legend_of_deborah/entities/entities/lod_field_manual/assets').glob('html_*.lua')), 'Retire the second content source'
assert 'SetHTML' not in (ROOT/'gamemodes/legend_of_deborah/entities/entities/lod_field_manual/cl_init.lua').read_text()
source=(ROOT/'gamemodes/legend_of_deborah/gamemode/lod/cl_instruction_manual.lua').read_text()
assert 'IsDeployed' not in source and 'LOD_Staged' not in source
assert 'lod/manual/manifest.lua' not in source, 'Client must not depend on the failed payload-file delivery path'
server=(ROOT/'gamemodes/legend_of_deborah/gamemode/lod/sv_instruction_manual.lua').read_text()
assert 'util.Compress(html)' in server and 'net.WriteData(data, #data)' in server
init=(ROOT/'gamemodes/legend_of_deborah/gamemode/init.lua').read_text()
assert 'include("lod/sv_instruction_manual.lua")' in init
assert 'AddCSLuaFile("lod/manual/' not in init, 'Generated manual payload is server-streamed, not client-file distributed'
for term in ['Relay', 'Lacemaker', 'RELAY SHOT', 'LEAVE RIBBON', 'SOURCE SHOT', 'The shot comes from the ally’s captured position', 'There is no invisible lingering trail', 'Interposer', 'Mourner', 'BODYGUARD', 'RETALIATION', 'an old corpse cannot trigger its oath', 'protection is never guaranteed', 'separate, full 1.2-second shot warning', 'Halter', 'Pacer', 'KEEP MOVING', 'JUDGMENT', 'Only actual voluntary motion counts', 'Fusilier', 'Bombardier', 'body-bracket glyph', 'lure ordinary enemies into it', 'unmarked body can still absorb', 'Siphoner', 'Accumulator', 'downward funnel', 'battery-and-plus glyph', 'supplemental aura damage to other nearby Heroes', 'Only a surviving Hero who actually loses HP', 'The amber Metrocop hears', 'The violet fast zombie remembers', 'The pale-cyan slave Vortigaunt draws', 'The crimson Combine elite marks', 'Outrider', 'Conductor', 'lone bracket glyph', 'linked 64-unit circles', 'TIME OVER','1,800','Black Keycard','Backstab','Quickstep','Rebuff','Stink Bomb','Arcane Surge','DFTs normally mint','Abundance','SECURE THE BAG','Nessa','Beam Sweeper']:
    assert term in html,term
subprocess.run(['node',str(ROOT/'tools/test_manual_reader.js')],check=True,cwd=ROOT)
print('PASS: canonical bytes, all 150 feat entries, 60 properties, offline assets, portable access')

assert "call('tab',e.keyCode,e.key||'')" in html and 'e.keyCode===79' in html, 'Reader must forward Equipment key and rebound key name'

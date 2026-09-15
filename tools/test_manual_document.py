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
assert ''.join(chunks)==html, 'Both entry points must receive the generated canonical document'
assert (builder.SOURCE/'manual.html').read_text()==html
entries=[e for c in book['chapters'] for e in c.get('entries',[])]
assert len(entries)==150 and len({e['id'] for e in entries})==150
assert len(json.loads((builder.SOURCE/'catalog.json').read_text())['EquipmentProperties'])==60
assert 'https://' not in html and 'http://' not in html, 'Reader must work without outside requests'
assert not list((ROOT/'gamemodes/legend_of_deborah/entities/entities/lod_field_manual/assets').glob('html_*.lua')), 'Retire the second content source'
assert 'SetHTML' not in (ROOT/'gamemodes/legend_of_deborah/entities/entities/lod_field_manual/cl_init.lua').read_text()
source=(ROOT/'gamemodes/legend_of_deborah/gamemode/lod/cl_instruction_manual.lua').read_text()
assert 'IsDeployed' not in source and 'LOD_Staged' not in source
for term in ['TIME OVER','1,800','Black Keycard','Backstab','Quickstep','Rebuff','Stink Bomb','Arcane Surge','DFTs mint only','Beam Sweeper']:
    assert term in html,term
subprocess.run(['node',str(ROOT/'tools/test_manual_reader.js')],check=True,cwd=ROOT)
print('PASS: canonical bytes, all 150 feat entries, 60 properties, offline assets, portable access')

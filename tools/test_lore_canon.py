"""Exact GDD-authored script parity; complements production Lua boundary tests."""
import json
import re
from pathlib import Path

root=Path(__file__).resolve().parents[1]
data=json.loads((root/'docs/lore/script.json').read_text())
gm=root/'gamemodes/legend_of_deborah/gamemode/lod'
literal=re.compile(r'"(?:\\.|[^"\\])*"')
chapters=[]
for line in (gm/'sv_staging_lore.lua').read_text().splitlines():
    if line.startswith('    {title='):
        values=[json.loads(v) for v in literal.findall(line)]
        assert len(values)==2
        chapters.append(values)
assert chapters==[[c['title'],c['text']] for c in data['chapters']]
assert [c['level'] for c in data['chapters']]==list(range(1,21))
assert len({c['text'] for c in data['chapters']})==20
for name,lines in data['damsels'].items():
    row=next(l for l in (gm/'sh_damsels.lua').read_text().splitlines() if l.startswith("    {'"+name+"',"))
    assert [json.loads(v) for v in literal.findall(row)]==lines,name
assert sum(len(v) for k,v in data['damsels'].items() if k!='Deborah')==57
assert len(data['damsels']['Deborah'])==2
assert not any('Hector' in c['text'] for c in data['chapters'])
assert not any('Hector' in line for name,lines in data['damsels'].items() if name!='Deborah' for line in lines)
packet=(root/'docs/lore/THE_REFUGE_AND_THE_DIRECTOR.md').read_text()
for c in data['chapters']: assert c['text'] in packet
for lines in data['damsels'].values():
    for line in lines: assert line in packet
for name in ['Ned Still','Quinn Keyes','Roxy Bellows','Perry Quibble','Mira Aside','Kit Glitch','Bea Bunch','Ada Branch']:
    assert name in packet
# The existing bestiary authority contains54 identities;9 base/special entries
# complete63. Named actor rows override their office defaults in the full map.
roster=(gm/'sv_enemy_roster.lua').read_text().split('for id,d')[0]
ordinary=re.findall(r'\n\s*(\w+)\s*=\{name="([^"]+)"',roster)
assert len(ordinary)==54
for _,name in ordinary: assert name.casefold() in packet.casefold(),name
for name in ['Shambler','Runner','Soldier','Neil','Brute','Sniper','Watcher','Seeker','Bioblaster']:
    assert name.casefold() in packet.casefold()
manual=json.loads((root/'docs/manual/book.json').read_text())
staging=next(c for c in manual['chapters'] if c['id']=='staging')
assert 'Cash is money in the briefcase objective, not another captive.' in '\n'.join(staging['text'])
print('LORE_CANON_PASS: exact20 chapters/57+2 service lines; eight room members; full63 ordinary identities; revelation and manual Cash semantics')

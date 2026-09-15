"""Check literal include resolution and intentional replacement registrations."""
from pathlib import Path
import re
from collections import defaultdict
ROOT=Path(__file__).resolve().parents[1]
files=list((ROOT/'gamemodes').rglob('*.lua'))+list((ROOT/'lua').rglob('*.lua'))
errors=[];checked=0;registrations=defaultdict(list)
for p in files:
    if '/manual/html_' in str(p):continue
    text=p.read_text()
    # Comments are excluded; long comments are not used for include examples.
    text=re.sub(r'--[^\n]*','',text)
    for name in re.findall(r'\b(?:include|AddCSLuaFile)\(\s*["\']([^"\']+)["\']\s*\)',text):
        candidates=[p.parent/name, ROOT/'lua'/name, ROOT/'gamemodes'/name]
        checked+=1
        if not any(q.is_file() for q in candidates):errors.append(f'{p.relative_to(ROOT)}: unresolved {name}')
    realm='client' if p.name.startswith('cl_') or '/client/' in str(p) else 'server'
    for api,pattern in [('hook',r'hook\.Add\(\s*["\']([^"\']+)["\']\s*,\s*["\']([^"\']+)["\']'),('timer',r'timer\.Create\(\s*["\']([^"\']+)["\']'),('net',r'net\.Receive\(\s*["\']([^"\']+)["\']')]:
        for m in re.finditer(pattern,text):registrations[(realm,api,*m.groups())].append(p.name)
allowed={('client','hook','PostDrawOpaqueRenderables','LOD_DrawContainerWayfinding'),('client','net','LOD_MapChunk')}
for key,paths in registrations.items():
    if len(paths)>1 and key not in allowed:errors.append(f'unreviewed duplicate {key}: {paths}')
assert not errors,'\n'.join(errors)
print(f'RELEASE_WIRING_PASS: {checked} literal paths; duplicate hooks/net/timers reviewed by realm')

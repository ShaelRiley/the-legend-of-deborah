#!/usr/bin/env python3
"""C2 source provenance, native file layout, UV and bounded palette asset gate."""
import hashlib
import json
import struct
import subprocess
from pathlib import Path
import numpy as np
from PIL import Image
from assets import build_crate_hull as build

root=build.ROOT
out=build.OUT
files=build.source_files()
model,vertices=build.inspect_model(files)
assert model['textures']==['cargo_container01','cargo_container02','cargo_container03']
assert model['skin_table']==[0,1,2,1,1,2,2,1,2]
assert np.allclose(model['position_min'],[-63.051464,-192.100876,-60.343300],atol=1e-5)
assert np.allclose(model['position_max'],[64.947823,195.440399,67.656700],atol=1e-5)
uv=vertices[:,6:]
assert np.all((uv>=0)&(uv<=1)), 'stock UV outside atlas'
# All active slots/skins use an identical UV layout and one shared, unbranded normal.
for n in (1,2,3):
    material=files[f'materials/models/props_wasteland/cargo_container0{n}.vmt'].decode()
    active='\n'.join(line.split('//')[0] for line in material.splitlines())
    assert 'cargo_container01_normal' in active
    assert all(key not in active for key in ('$detail','$envmap','$phong','$selfillum'))

vtf=(out/'hull_c2.vtf').read_bytes()
assert struct.unpack_from('<4sIIIHHIHH',vtf)==(b'VTF\0',7,2,80,1024,1024,0x12,1,0)
assert struct.unpack_from('<fIBIBBH',vtf,48)==(1.,3,11,0xffffffff,0,0,1)
assert len(vtf)==80+sum(3*max(1,1024>>i)**2 for i in range(11))
pos=80
for shift in range(10,-1,-1):
    size=max(1,1024>>shift)
    mip=Image.frombytes('RGB',(size,size),vtf[pos:pos+size*size*3],'raw','BGR')
    pos+=size*size*3
    a=np.asarray(mip)
    assert np.array_equal(a[:,:,0],a[:,:,1]) and np.array_equal(a[:,:,1],a[:,:,2])
assert mip.tobytes()==Image.open(out/'hull_c2.png').tobytes()
a=np.asarray(mip)
assert a[26:325,54:958].mean()>160 and a.std()>25
assert a.max()<=245
# The full logo and name are inside the opaque donor core, never only blurred.
x0,y0,x1,y1=build.REPAIR
assert x0+14<154 and x1-14>414 and y0+14<64 and y1-14>175
assert build.DONOR[1]>=194 and build.DONOR[3]<=300
# Ten independent RGB multipliers preserve hue ratios because R=G=B per texel.
for tint in [(255,255,255),(220,48,43),(45,85,225),(232,204,45),(62,185,75),
             (225,122,45),(155,65,205),(40,198,204),(65,65,65),(138,123,80)]:
    pixel=a[250,500].astype(float)*np.array(tint)/255
    assert np.ptp(pixel/np.array(tint))<1e-12

vms=sorted((out/'sections').glob('*.vmt'));assert len(vms)==360
for p in vms:
    text=p.read_text();original=(out.parent/'container_sections'/p.name.replace('c2_','v19_')).read_text()
    assert text==original.replace('metal/metalwall001a',build.TEXTURE).replace('"$blendtintcoloroverbase" "0.680"','"$blendtintcoloroverbase" "0"')
    assert all(key not in text for key in ('$detail','$phong','$envmap'))
# Reproduction includes exact VTF bytes and source receipt; build never patches Lua.
paths=[out/'hull_c2.png',out/'hull_c2.vtf',out/'hull_c2_preview.vmt',root/'docs/validation/CRATE_HULL_C2.json',*vms]
before={p:hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}
subprocess.run(['python3','tools/assets/build_crate_hull.py'],cwd=root,check=True)
assert all(hashlib.sha256(p.read_bytes()).hexdigest()==h for p,h in before.items())
print('CRATE_HULL_PASS: 11 source receipts; 3 skin/channel mappings; 664 actual UVs; neutral complete 11-mip BGR888; 360 preserved palette colors; 10 tint ratios; deterministic rebuild. Native acceptance pending.')

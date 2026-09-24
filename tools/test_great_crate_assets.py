#!/usr/bin/env python3
"""Full original-art integrity, fit and material/resource contract."""
import hashlib
import json
import re
import subprocess
from pathlib import Path
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
ART=ROOT/'gamemodes/legend_of_deborah/content/materials/legend_of_deborah/container_brands'
index=json.loads((ROOT/'docs/validation/CRATE_ASSET_INDEX.json').read_text())
manifest=json.loads((ROOT/'docs/CONTAINER_BRAND_MANIFEST.json').read_text())
assert len(index)==len(manifest)==256
assert manifest[0]['company_name']=='Northern Petrol'
assert manifest[-1]['company_name']=='Deborah Logistics Unlimited'
pixels=total=0
edge=[]
for i,row in enumerate(index,1):
    assert row['id']==f'{i:03d}'
    p=ART/f'container_brand_{i:03d}.png'
    raw=p.read_bytes();total+=len(raw)
    assert hashlib.sha256(raw).hexdigest()==row['sha256']
    original=Image.open(p);assert original.size==(1024,512) and original.mode=='RGBA'
    runtime=ART/row['runtime'];assert hashlib.sha256(runtime.read_bytes()).hexdigest()==row['runtime_sha256']
    im=Image.open(runtime);width,height=im.size
    if i==232:
        assert im.crop((0,0,1024,512)).tobytes()==original.tobytes()
        assert im.crop((1024,136,1032,175)).tobytes()==original.crop((405,136,413,175)).tobytes()
    alpha=im.getchannel('A');b=alpha.getbbox();x0,y0,x1,y1=row['bounds']
    assert 0<=x0<=b[0]<b[2]<=x1<=width and 0<=y0<=b[1]<b[3]<=y1<=height
    # Zero visible pixels outside the fitted UV rectangle, including faint AA.
    assert sum(alpha.histogram()[1:])==sum(alpha.crop((x0,y0,x1,y1)).histogram()[1:])
    if b[0]==0 or b[1]==0 or b[2]==width or b[3]==height: edge.append(i)
    w,h=x1-x0,y1-y0;s=min(240/w,78/h)*.94
    assert s>0 and w*s<=240*.94+1e-9 and h*s<=78*.94+1e-9
    assert abs((w*s)/(h*s)-w/h)<1e-9
    pixels+=sum(alpha.histogram()[1:])
assert not edge,'runtime canvas still clips artwork'
meta=ROOT/'gamemodes/legend_of_deborah/gamemode/lod/sh_crate_brand_metadata.lua'
before=meta.read_bytes()
subprocess.run(['python3','tools/assets/build_crate_metadata.py'],cwd=ROOT,check=True)
assert before==meta.read_bytes(),'metadata is not reproducible'
config=(ROOT/'gamemodes/legend_of_deborah/gamemode/lod/sh_config.lua').read_text()
assert 'ContainerModel = "models/props_wasteland/cargo_container01.mdl"' in config
floor=ROOT/'gamemodes/legend_of_deborah/content/materials/legend_of_deborah/crate/concrete.vmt'
assert 'VertexLitGeneric' in floor.read_text() and 'concrete/concretefloor001a' in floor.read_text()
brand=(ROOT/'gamemodes/legend_of_deborah/gamemode/lod/cl_container_branding.lua').read_text()
assert 'CreateMaterial("lod_crate_brand_c3_"..slot' in brand
assert 'source:GetTexture("$basetexture")' in brand and 'sprayPaintColor' not in brand
assert 'instance.marked' in brand and 'C.MaxBrandDraws' in brand
assert 'container_brand_spray_atlas' not in brand and 'UV_INSET' not in brand
assert not re.search(r'net\.(Start|Write)',brand)
print(f'CRATE_ASSETS_PASS: 256 unchanged originals; {pixels} visible pixels retained; {total} disk bytes; edge-touching runtime images={edge}; 232 clipped glyph losslessly extended; engine sampler/lighting acceptance pending')

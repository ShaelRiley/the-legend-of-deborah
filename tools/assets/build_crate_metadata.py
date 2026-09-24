#!/usr/bin/env python3
"""Index the original compositions losslessly; never reconstruct or re-typeset art."""
import hashlib
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / 'gamemodes/legend_of_deborah/content/materials/legend_of_deborah/container_brands'
OUT = ROOT / 'gamemodes/legend_of_deborah/gamemode/lod/sh_crate_brand_metadata.lua'

def build():
    manifest = json.loads((ROOT / 'docs/CONTAINER_BRAND_MANIFEST.json').read_text())
    assert [x['id'] for x in manifest] == [f'{i:03d}' for i in range(1, 257)]
    lines = ['-- Generated from the unchanged original PNGs by tools/assets/build_crate_metadata.py.',
             '-- Bounds are exclusive at right/bottom and retain EVERY nonzero-alpha pixel.',
             'LOD = LOD or {}', 'LOD.CrateBrandMetadata = {']
    report = []
    # The archive's only canvas-edge defect: 232's final N is clipped at x=1024.
    # Its visible stem is byte-identical to the first N (offset 619). Preserve the
    # original verbatim and extend only the missing eight columns in a derivative.
    source = Image.open(ART/'container_brand_232.png')
    assert source.crop((1006,136,1024,175)).tobytes() == source.crop((387,136,405,175)).tobytes()
    complete = Image.new('RGBA',(2048,512))
    complete.paste(source,(0,0))
    complete.paste(source.crop((405,136,413,175)),(1024,136))
    complete.save(ART/'container_brand_232_complete.png',optimize=True)
    for row in manifest:
        p = ART / row['filename']
        source = Image.open(p)
        assert source.size == (1024, 512) and source.mode == 'RGBA'
        runtime_name = 'container_brand_232_complete.png' if row['id']=='232' else row['filename']
        runtime_path = ART/runtime_name
        im = Image.open(runtime_path)
        width,height=im.size
        b = im.getchannel('A').getbbox()
        assert b
        b = (max(0,b[0]-2),max(0,b[1]-2),min(width,b[2]+2),min(height,b[3]+2))
        name = json.dumps(row['company_name'], ensure_ascii=False)
        lines.append(f'    [{int(row["id"])}] = {{name={name}, path={json.dumps(runtime_name)}, width={width}, height={height}, bounds={{{",".join(map(str,b))}}}}},')
        report.append(dict(id=row['id'],sha256=hashlib.sha256(p.read_bytes()).hexdigest(),runtime=runtime_name,runtime_sha256=hashlib.sha256(runtime_path.read_bytes()).hexdigest(),bounds=b))
    OUT.write_text('\n'.join(lines)+ '\n}\n')
    (ROOT/'docs/validation/CRATE_ASSET_INDEX.json').write_text(json.dumps(report,indent=2)+'\n')
    print('CRATE_METADATA: 256 original compositions; lossless alpha bounds and SHA-256 receipts')

if __name__ == '__main__': build()

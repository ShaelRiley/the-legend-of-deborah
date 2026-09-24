#!/usr/bin/env python3
"""Reproduce C2's neutral hull from the author's checksum-verified stock export.

No generated metal/no guessed UVs: replace only the NP rectangle with same-column
clean stock corrugation, then apply a monotonic luminance curve to the whole atlas.
Source and engine/native acceptance are deliberately separate.
"""
import argparse
import hashlib
import json
import math
import struct
import zipfile
import zlib
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / 'tools/fixtures/crate_stock/source_export.zip'
OUT = ROOT / 'gamemodes/legend_of_deborah/content/materials/legend_of_deborah/crate'
TEXTURE = 'legend_of_deborah/crate/hull_c2'
NORMAL = 'models/props_wasteland/cargo_container01_normal'
# Independent stock inventory: SteamTracking/GameTracking-TF2,
# b6d0d7c104db22f520f5608e25aec4a7580a5fd2/hl2/hl2_textures_dir.txt.
STOCK_CRC = {'cargo_container01.vtf': 0xdc126984,
             'cargo_container01_normal.vtf': 0xf33bf1e9,
             'cargo_container02.vtf': 0x5d6d407f}
REPAIR = (136, 44, 432, 194)
DONOR = (136, 200, 432, 282)


def source_files():
    result = {}
    with zipfile.ZipFile(SOURCE) as z:
        report = json.loads(z.read('crate_sources/manifest.json'))
        assert report['model'] == 'models/props_wasteland/cargo_container01.mdl'
        assert not report['missing'] and len(report['files']) == 11
        for row in report['files']:
            assert Path(row['file']).name == row['file']
            data = z.read('crate_sources/' + row['file'])
            assert len(data) == row['bytes']
            assert zlib.crc32(data) & 0xffffffff == int(row['crc'])
            if Path(row['source']).name in STOCK_CRC:
                assert int(row['crc']) == STOCK_CRC[Path(row['source']).name]
            result[row['source']] = data
    return result


def decode_stock(data):
    assert data[:4] == b'VTF\0'
    assert struct.unpack_from('<II', data, 4) == (7, 1)
    w, h = struct.unpack_from('<HH', data, 16)
    assert (w, h) == (1024, 1024)
    assert struct.unpack_from('<I', data, 52)[0] == 13 and data[56] == 11
    size = w * h // 2
    # Stock 7.1 stores the largest mip last; independent Pillow BC1 decoder.
    return Image.frombytes('RGBA', (w, h), data[-size:], 'bcn', (1, 'DXT1')).convert('RGB')


def repair(image):
    a = np.array(image, dtype=np.float64)
    x0, y0, x1, y1 = REPAIR
    donor = image.crop(DONOR).resize((x1-x0, y1-y0), Image.Resampling.BICUBIC)
    # Correct the donor's vertical lighting trend from an unbranded reference
    # band at the same heights. This avoids a bright lower-panel rectangle.
    reference = np.asarray(image, dtype=float)[:, 450:680].mean((1,2))
    source_rows = np.linspace(DONOR[1], DONOR[3]-1, y1-y0)
    ratio = reference[y0:y1] / np.interp(source_rows, np.arange(1024), reference)
    donor_pixels = np.asarray(donor, dtype=float) * ratio[:, None, None]
    yy, xx = np.mgrid[:y1-y0, :x1-x0]
    edge = np.minimum.reduce([xx, yy, x1-x0-1-xx, y1-y0-1-yy])
    alpha = np.clip(edge / 14., 0, 1)[..., None]
    a[y0:y1, x0:x1] = a[y0:y1, x0:x1]*(1-alpha) + donor_pixels*alpha
    # Keep seams dark, lift weathered paint without adding chroma or flat fill.
    luminance = a @ np.array([.2126, .7152, .0722])
    white = float(np.percentile(luminance[26:325, 54:958], 95))
    gray = np.rint(np.clip(235 * (luminance / white)**.65, 0, 245)).astype('uint8')
    return Image.fromarray(np.repeat(gray[..., None], 3, axis=2)), white


def encode_vtf(image):
    # Source 7.2, BGR888, no alpha, 11 complete mips. No optional thumbnail.
    w, h = image.size
    count = int(math.log2(max(w, h))) + 1
    header = bytearray(80)
    struct.pack_into('<4sIIIHHIHH', header, 0, b'VTF\0', 7, 2, 80, w, h, 0x12, 1, 0)
    struct.pack_into('<3f', header, 32, *[float(v)/255 for v in np.asarray(image).mean((0,1))])
    struct.pack_into('<fIBIBBH', header, 48, 1., 3, count, 0xffffffff, 0, 0, 1)
    mips = []
    for i in reversed(range(count)):
        mip = image.resize((max(1,w>>i), max(1,h>>i)), Image.Resampling.LANCZOS)
        mips.append(np.asarray(mip)[:,:,::-1].tobytes())
    return bytes(header) + b''.join(mips)


def inspect_model(files):
    mdl = files['models/props_wasteland/cargo_container01.mdl']
    vvd = files['models/props_wasteland/cargo_container01.vvd']
    vtx = files['models/props_wasteland/cargo_container01.dx90.vtx']
    assert mdl[:4] == b'IDST' and struct.unpack_from('<I',mdl,4)[0] == 44
    checksum = struct.unpack_from('<I',mdl,8)[0]
    assert checksum == struct.unpack_from('<I',vvd,8)[0] == struct.unpack_from('<I',vtx,16)[0]
    nt, ti, nd, di, ns, nf, si, nb, bi = struct.unpack_from('<9i',mdl,204)
    assert (nt,ns,nf,nb) == (3,3,3,1)
    textures=[]
    for i in range(nt):
        off=ti+i*64; start=off+struct.unpack_from('<i',mdl,off)[0]
        textures.append(mdl[start:].split(b'\0')[0].decode())
    model=bi+struct.unpack_from('<i',mdl,bi+12)[0]
    nm, mi, nv, vi = struct.unpack_from('<4i',mdl,model+72)
    assert nm == 1 and nv == 664
    material, _, count, start = struct.unpack_from('<4i',mdl,model+mi)
    assert (material,count,start) == (0,664,0)
    offset=struct.unpack_from('<I',vvd,56)[0]
    vertices=np.array([struct.unpack_from('<8f',vvd,offset+i*48+16) for i in range(nv)])
    assert np.isfinite(vertices).all()
    return {'checksum':checksum, 'textures':textures,
            'skin_table':list(struct.unpack_from('<9h',mdl,si)),
            'meshes':nm,'mesh_material':material,'lod0_vertices':nv,
            'position_min':vertices[:,:3].min(0).tolist(), 'position_max':vertices[:,:3].max(0).tolist(),
            'uv_min':vertices[:,6:].min(0).tolist(), 'uv_max':vertices[:,6:].max(0).tolist()}, vertices


def build():
    files=source_files()
    model, vertices=inspect_model(files)
    image=decode_stock(files['materials/models/props_wasteland/cargo_container01.vtf'])
    hull, white=repair(image)
    OUT.mkdir(parents=True,exist_ok=True)
    hull.save(OUT/'hull_c2.png')
    (OUT/'hull_c2.vtf').write_bytes(encode_vtf(hull))
    # Reuse exact existing palette values; one diffuse shared by all section VMTs.
    section_dir=OUT/'sections';section_dir.mkdir(exist_ok=True)
    originals=OUT.parent/'container_sections'
    for old in sorted(originals.glob('v19_h???_s?.vmt')):
        text=old.read_text().replace('metal/metalwall001a',TEXTURE)
        text=text.replace('"$blendtintcoloroverbase" "0.680"','"$blendtintcoloroverbase" "0"')
        (section_dir/old.name.replace('v19_', 'c2_')).write_text(text)
    (OUT/'hull_c2_preview.vmt').write_text('"VertexLitGeneric"\n{\n'
        f' "$basetexture" "{TEXTURE}"\n "$bumpmap" "{NORMAL}"\n'
        ' "$model" "1"\n "$surfaceprop" "metal"\n "$allowdiffusemodulation" "1"\n'
        ' "$blendtintbybasealpha" "0"\n "$blendtintcoloroverbase" "0"\n "$color2" "[1 1 1]"\n}\n')
    receipt={'source_archive_sha256':hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
        'files':{p:{'bytes':len(b),'crc32':f'{zlib.crc32(b)&0xffffffff:08x}',
                    'sha256':hashlib.sha256(b).hexdigest()} for p,b in files.items()},
        'model':model,'repair_rectangle':REPAIR,'donor_rectangle':DONOR,'feather_pixels':14,
        'luminance_white':white,'luminance_curve':'min(245,235*(Rec709/white)^0.65)',
        'normal_strategy':'Unmodified shared stock normal; visually inspected, no NP mark; all three VMTs use it.',
        'encoding':'VTF 7.2 BGR888; 1024x1024; 11 mips; no alpha/thumbnail',
        'hull_sha256':hashlib.sha256((OUT/'hull_c2.vtf').read_bytes()).hexdigest(),
        'acceptance':'Offline candidate only; native decode/appearance and production promotion pending.'}
    (ROOT/'docs/validation/CRATE_HULL_C2.json').write_text(json.dumps(receipt,indent=2)+'\n')
    print('CRATE_HULL_BUILD: verified 11 files, 664 vertices, 3 skins; 360 section candidates; shared neutral diffuse')
    return hull,vertices


if __name__=='__main__':
    build()

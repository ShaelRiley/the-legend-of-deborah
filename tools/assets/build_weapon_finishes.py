#!/usr/bin/env python3
"""Four sparse, tileable detail masks. No downloaded or per-item textures.

Neutral 128 is the unmodified region in Source detail blend mode 0. Less than
one quarter of texels carry brushed, ceramic, carbon or hammered markings.
RGBA8888 avoids DXT compression contaminating the otherwise neutral field.
"""
import struct
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'gamemodes/legend_of_deborah/content/materials/lod/weapon_finish'

def pixels(pattern):
    image=Image.new('RGBA',(64,64),(128,128,128,255))
    for y in range(64):
        for x in range(64):
            # Two broken diagonal bands, with most of the surface left stock.
            patch=(x+y//2)%32<7 and (y%32)<22
            if not patch: continue
            if pattern==1: value=98 if y%3==0 else 154
            elif pattern==2: value=164 if (x+y)%11<9 else 120
            elif pattern==3: value=92 if (x//2+y//2)%2==0 else 150
            else: value=98+((x*17+y*31+x*y)%67)
            image.putpixel((x,y),(value,value,value,255))
    return image

def build():
    OUT.mkdir(parents=True,exist_ok=True)
    for p in range(1,5):
        image=pixels(p)
        changed=sum(pixel[0]!=128 for pixel in image.getdata())
        assert 0<changed<64*64/4
        header=bytearray(b'VTF\0'+struct.pack('<IIIHHIHH',7,2,80,64,64,2|16,1,0))
        header+=b'\0'*4+struct.pack('<3f',.5,.5,.5)+b'\0'*4
        header+=struct.pack('<fIBIBBH',1.0,0,7,0xffffffff,0,0,1)
        header+=b'\0'*(80-len(header))
        mips=[image.resize((max(1,64>>n),)*2,Image.Resampling.BOX).tobytes() for n in range(6,-1,-1)]
        data=header+b''.join(mips)
        assert len(data)==80+4*sum(4**n for n in range(7))
        (OUT/f'patch_{p}.vtf').write_bytes(data)
        print(f'patch_{p}: {changed/4096:.1%} marked texels; {len(data)} bytes, 7 mip levels')
if __name__=='__main__': build()

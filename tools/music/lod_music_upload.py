#!/usr/bin/env python3
"""lod_music_upload <local-block-folder>: validate, stage and register over HTTPS."""
import argparse
import io
import json
import os
from pathlib import Path
import urllib.request
import zipfile
from catalog_service import MAX_UPLOAD, ORIGIN, require, validate_folder

def bundle(folder):
    folder=Path(folder).resolve()
    manifest, _, _ = validate_folder(folder)
    out=io.BytesIO()
    with zipfile.ZipFile(out,'w',compression=zipfile.ZIP_STORED) as z:
        for path in sorted(folder.iterdir()):
            if path.name == 'manifest.json':
                z.writestr(path.name, json.dumps(manifest, sort_keys=True))
            else:
                z.write(path,path.name)
    data=out.getvalue();require(len(data)<=MAX_UPLOAD,'bundle too large');return data

class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, *args, **kwargs):
        raise ValueError('upload redirects forbidden; configure the final HTTPS origin')

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('folder',type=Path);p.add_argument('--origin',default=os.environ.get('LOD_MUSIC_UPLOAD_ORIGIN'))
    p.add_argument('--validate-only',action='store_true')
    p.add_argument('--write-cues',action='store_true',help='analyze/validate and save editable cue metadata locally; do not upload')
    args=p.parse_args()
    if args.write_cues:
        manifest, _, _ = validate_folder(args.folder)
        (args.folder/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
        print(json.dumps({'cues_written':str(args.folder/'manifest.json')}));return
    data=bundle(args.folder)
    if args.validate_only:
        print(json.dumps({'valid':True,'bundle_bytes':len(data)}));return
    require(args.origin and ORIGIN.fullmatch(args.origin),'set LOD_MUSIC_UPLOAD_ORIGIN to the HTTPS ingestion origin')
    token=os.environ.get('MUSIC_UPLOAD_TOKEN','');require(len(token)>=32,'set MUSIC_UPLOAD_TOKEN')
    opener=urllib.request.build_opener(NoRedirect)
    def post(path,body):
        req=urllib.request.Request(args.origin+path,data=body,method='POST',headers={
            'Authorization':'Bearer '+token,'Content-Type':'application/zip' if body else 'application/json'})
        with opener.open(req,timeout=120) as r:
            return json.loads(r.read(65536))
    staged=post('/v1/uploads',data);result=post('/v1/imports/'+staged['upload_id'],b'')
    print(json.dumps({'upload_id':staged['upload_id'],**result}))
if __name__=='__main__':
    main()

"""Verify source SHA, alpha and exact visible RGB; valid-PNG RGB corruption must be rejected."""
import argparse,hashlib,json,tempfile,shutil
from pathlib import Path
from PIL import Image
ap=argparse.ArgumentParser();ap.add_argument('--directory',required=True);ap.add_argument('--negative',action='store_true');args=ap.parse_args();root=Path(args.directory)
def verify(folder,spec):
    for key in ['page','cutout','mask','rawMask']:
        if key in spec:
            a=spec[key];assert a['file']==Path(a['file']).name
            assert hashlib.sha256((folder/a['file']).read_bytes()).hexdigest()==a['sha256'],key+' SHA mismatch'
    source=Image.open(folder/spec['page']['file']).convert('RGBA');assert list(source.size)==spec['sourceSize']
    if 'cutout' in spec:
        cut=Image.open(folder/spec['cutout']['file']).convert('RGBA');mask=Image.open(folder/spec['mask']['file']).convert('L');x,y,w,h=map(int,spec['crop']);assert cut.size==(w,h)
        for cy in range(h):
            for cx in range(w):
                value=cut.getpixel((cx,cy));assert value[3]==mask.getpixel((x+cx,y+cy))
                if value[3]:assert value[:3]==source.getpixel((x+cx,y+cy))[:3],'Original RGB changed'
rows=[]
for kind in ['optics','circuit','pendulum']:
    spec=json.loads((root/('original-physics-'+kind+'-provenance.json')).read_text());verify(root,spec);row={'kind':kind,'sha_and_original_rgb':True}
    if args.negative and 'cutout' in spec:
        with tempfile.TemporaryDirectory(prefix='source-diagram-rgb-') as temp:
            folder=Path(temp)
            for key in ['page','cutout','mask','rawMask']:
                if key in spec:shutil.copy2(root/spec[key]['file'],folder/spec[key]['file'])
            file=folder/spec['cutout']['file'];im=Image.open(file).convert('RGBA')
            point=next((x,y) for y in range(im.height) for x in range(im.width) if im.getpixel((x,y))[3]);v=im.getpixel(point);im.putpixel(point,((v[0]+1)%256,v[1],v[2],v[3]));im.save(file)
            try:verify(folder,spec)
            except AssertionError:row['valid_png_rgb_corruption_rejected']=True
            else:raise AssertionError('Corrupted valid PNG accepted')
    rows.append(row)
print(json.dumps(rows,indent=2))

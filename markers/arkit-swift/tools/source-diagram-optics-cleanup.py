import json,hashlib,shutil,argparse
ap=argparse.ArgumentParser(description="Disclosed source-green cleanup; preserve raw learned mask and original RGB")
ap.add_argument("--out",required=True);args=ap.parse_args()
from pathlib import Path
import numpy as np
from PIL import Image,ImageFilter
out=Path(args.out);p=out/'cpu-sam2-receipt.json';r=json.loads(p.read_text());e=r['items'][0]
rgb=np.array(Image.open(e['source']).convert('RGB'));learn=np.array(Image.open(e['mask']))>0
Image.fromarray(learn.astype(np.uint8)*255).save(out/'optics-tree-sam2-raw-mask.png')
signed=rgb.astype(np.int16);green=(signed[:,:,1]>signed[:,:,0]+12)&(signed[:,:,1]>signed[:,:,2]+12)
near=np.array(Image.fromarray(green.astype(np.uint8)*255).filter(ImageFilter.MaxFilter(3)))>0
mask=learn&near;ys,xs=np.where(mask);b=[int(xs.min()),int(ys.min()),int(xs.max()+1-xs.min()),int(ys.max()+1-ys.min())]
rgba=np.dstack([rgb,mask.astype(np.uint8)*255]);Image.fromarray(rgba[b[1]:b[1]+b[3],b[0]:b[0]+b[2]]).save(e['cutout']);Image.fromarray(mask.astype(np.uint8)*255).save(e['mask'])
h=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
e.update(bbox=b,centroid=[float(xs.mean()),float(ys.mean())],pixels=len(xs),cutout_sha256=h(e['cutout']),mask_sha256=h(e['mask']),raw_learned_mask=str(out/'optics-tree-sam2-raw-mask.png'),raw_learned_mask_sha256=h(out/'optics-tree-sam2-raw-mask.png'),postprocessing='Learned SAM2 mask intersect source-green pixels dilated 1 pixel; removes neighboring black letters on white, preserves original RGB. This is explicit source-specific color cleanup, not pure automatic segmentation.',removed_pixels=int(learn.sum()-mask.sum()))
for a in r['items']:
 shutil.copy2(a['source'],a['reference_copy']);a['reference_copy_sha256']=h(a['reference_copy']);assert a['reference_copy_sha256']==a['source_sha256']
p.write_text(json.dumps(r,indent=2)+'\n');print(json.dumps(e))

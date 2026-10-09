import os,sys,time,json,hashlib,argparse,shutil,subprocess
from pathlib import Path
ap=argparse.ArgumentParser(description="Prepared source SAM2 CPU alpha; manual prompts, not automatic parsing")
ap.add_argument("--sam2-root",required=True);ap.add_argument("--checkpoint",required=True);ap.add_argument("--source-dir",required=True);ap.add_argument("--out",required=True);args=ap.parse_args()
os.environ['PYTORCH_ENABLE_MPS_FALLBACK']='1'
sys.path.insert(0,args.sam2_root)
import torch,numpy as np
from PIL import Image
from sam2.build_sam import build_sam2
from sam2.sam2_image_predictor import SAM2ImagePredictor
from pathlib import Path
out=Path(args.out);out.mkdir(parents=True,exist_ok=True)
source=Path(args.source_dir)
checkpoint=args.checkpoint
hashfile=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
upstream_commit=subprocess.check_output(['git','-C',args.sam2_root,'rev-parse','HEAD'],text=True).strip()
assert upstream_commit=='2b90b9f5ceec907a1c18123530e92e794ad901a4'
assert hashfile(checkpoint)=='6d1aa6f30de5c92224f8172114de081d104bbd23dd9dc5c58996f0cad5dc4d38'
torch.set_num_threads(8); t=time.perf_counter()
model=build_sam2('configs/sam2.1/sam2.1_hiera_s.yaml',checkpoint,device='cpu',apply_postprocessing=False)
p=SAM2ImagePredictor(model,max_hole_area=0,max_sprinkle_area=0)
receipt={'model':'SAM2.1 Hiera small','device':'CPU','checkpoint_sha256':hashfile(checkpoint),'load_seconds':time.perf_counter()-t,'upstream':'https://github.com/facebookresearch/sam2','upstream_commit':upstream_commit,'checkpoint_url':'https://dl.fbaipublicfiles.com/segment_anything_2/092824/sam2.1_hiera_small.pt','torch_version':torch.__version__,'cpu_threads':8,'items':[],'limitations':['Manual positive/negative points and boxes; learned inference, not automatic scene parsing.','Original pixels retained; alpha only changes.','No GPU inference and no physical AR acceptance.']}
items=[('optics-tree','physics-optics-original.png',[327,486,374,568],[[348,535],[354,553],[350,506],[350,490],[350,565],[330,515],[332,533],[330,565],[370,565]],[1,1,1,1,1,0,0,0,0]),('pendulum-bob','physics-pendulum-original.png',[142,241,173,270],[[157,254],[153,252],[160,257],[160,238],[140,256]],[1,1,1,0,0])]
with torch.inference_mode():
 for name,filename,box,points,labels in items:
  rgb=np.array(Image.open(source/filename).convert('RGB'));start=time.perf_counter();p.set_image(rgb)
  masks,scores,logits=p.predict(point_coords=np.array(points,dtype=np.float32),point_labels=np.array(labels),box=np.array(box,dtype=np.float32),multimask_output=True)
  idx=int(np.argmax(scores));mask=masks[idx];ys,xs=np.where(mask)
  if len(xs)==0:raise RuntimeError('Empty learned mask')
  bbox=[int(xs.min()),int(ys.min()),int(xs.max()+1-xs.min()),int(ys.max()+1-ys.min())]
  rgba=np.dstack([rgb,mask.astype(np.uint8)*255]);cut=rgba[bbox[1]:bbox[1]+bbox[3],bbox[0]:bbox[0]+bbox[2]]
  path=out/(name+'-sam2-cutout.png');Image.fromarray(cut).save(path)
  maskpath=out/(name+'-sam2-mask.png');Image.fromarray(mask.astype(np.uint8)*255).save(maskpath)
  srcpath=out/filename;shutil.copy2(source/filename,srcpath)
  assert np.array_equal(cut[:,:,:3],rgb[bbox[1]:bbox[1]+bbox[3],bbox[0]:bbox[0]+bbox[2]])
  entry={'id':name,'source':str(source/filename),'source_sha256':hashfile(source/filename),'reference_copy':str(srcpath),'reference_copy_sha256':hashfile(srcpath),'cutout':str(path),'cutout_sha256':hashfile(path),'mask':str(maskpath),'mask_sha256':hashfile(maskpath),'bbox':bbox,'centroid':[float(xs.mean()),float(ys.mean())],'pixels':len(xs),'prompt_box':box,'prompt_points':points,'prompt_labels':labels,'selected_score':float(scores[idx]),'inference_seconds':time.perf_counter()-start,'rgb_exact':True}
  receipt['items'].append(entry);print(json.dumps(entry),flush=True)
(out/'cpu-sam2-receipt.json').write_text(json.dumps(receipt,indent=2)+'\n')

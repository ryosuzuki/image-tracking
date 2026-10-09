import pathlib,json,hashlib,struct
import numpy as np,trimesh
from PIL import Image
root=pathlib.Path(__file__).resolve().parents[1];res=root/'Assets/DedicatedTracker/Resources/Catalog';base=pathlib.Path('/tmp/image-tracking-output/alienware-gpu-lab/2026-10-09/hunyuan-source-parts');repair=base.parent/'hunyuan-source-parts-quality-repair';swift=pathlib.Path('/path/to/projects/apple-paper-lab/ios/Resources/SciencePages');config=json.loads((swift/'source-parts-animator.json').read_text());baseline=json.loads((base/'hunyuan-source-parts-manifest.json').read_text());quality=json.loads((repair/'source-parts-quality-manifest.json').read_text());byid={p['id']:p for p in baseline['parts']} if 'parts' in baseline else {p['id']:p for p in baseline['items']};variants={p['variant_id']:p for p in quality['variants']}
def sha(b):return hashlib.sha256(b).hexdigest()
def checked(path,h):
 b=path.read_bytes();assert sha(b)==h,(path,'hash');return b
manifest=json.loads((res/'manifest.json').read_text());old=[x for x in manifest['items'] if x.get('cohort')!='source-parts'];assert len(old)==67;manifest['items']=old
for page in config['pages']:
 topic=page['domainID'];native={'topic':topic,'parts':[],'page_width':.21,'source_size':page['sourceSize'],'reference_crop':page['referenceCrop'],'basis':'Hunyuan Y-up -> Unity ARToolKit local (x,y,-z), host Z alignment first; page x right/y up/negative z outward; not calibration'}
 pagebytes=checked(swift/page['page']['file'],page['page']['sha256']);target='sourceparts-'+topic+'.png';(root/'Assets/StreamingAssets/catalog'/target).write_bytes(pagebytes)
 for p in page['parts']:
  b=byid[p['id']];source=Image.open(base/b['files']['source_page']).convert('RGB');cutout=Image.open(swift/p['cutout']['file']).convert('RGBA');box=b['crop_bbox_px'];original=np.asarray(source.crop(tuple(box)));rgba=np.asarray(cutout);assert original.shape[:2]==rgba.shape[:2];mask=rgba[:,:,3]>0;assert np.array_equal(original[mask],rgba[:,:,:3][mask]),(p['id'],'altered source RGB')
  entry=dict(id=p['id'],bbox=p['bbox'],centroid=p['centroid'],fallback=p['fallback2D'],host_z=p['hostZDegrees'],quantity=p['quantity'],provenance=p['provenance']);cut=checked(swift/p['cutout']['file'],p['cutout']['sha256']);(res/(p['id']+'-cutout.png')).write_bytes(cut);entry['cutout_resource']='Catalog/'+p['id']+'-cutout';entry['cutout_sha256']=sha(cut)
  # Preserve all ten baseline GLB identities, even quality-gated blue; selected variant separate.
  for suffix,v,d in [('baseline',b,base),('selected',variants['arithmetic-column-4-full-seed42'] if p['id']=='arithmetic-column-4' else b,repair if p['id']=='arithmetic-column-4' else base)]:
   glbfile=v['files'].get('glb',v['files'].get('mobile'));glbbytes=checked(d/glbfile,v['sha256'][glbfile]);entry[suffix+'_glb_sha256']=sha(glbbytes)
   mesh=trimesh.load(d/glbfile).to_geometry();verts=np.asarray(mesh.vertices,dtype=np.float32).copy();angle=np.deg2rad(p['hostZDegrees'] if suffix=='selected' else 0);x,y=verts[:,0].copy(),verts[:,1].copy();verts[:,0]=np.cos(angle)*x-np.sin(angle)*y;verts[:,1]=np.sin(angle)*x+np.cos(angle)*y;verts[:,2]*=-1
   # Reflection changes winding. UV belongs to original GLB atlas; no additional V inversion.
   faces=np.asarray(mesh.faces[:,[0,2,1]],dtype='<i4');verts=verts.astype('<f4');colors=np.full((len(verts),4),255,dtype=np.uint8);uv=np.asarray(mesh.visual.uv,dtype='<f4');data=struct.pack('<ii',len(verts),len(faces))+verts.tobytes()+colors.tobytes()+faces.tobytes()+uv.tobytes();rid=p['id']+'-'+suffix;(res/(rid+'.bytes')).write_bytes(data)
   texture=mesh.visual.material.baseColorTexture;texture.save(res/(rid+'-texture.png'));entry[suffix+'_mesh_resource']='Catalog/'+rid;entry[suffix+'_texture_resource']='Catalog/'+rid+'-texture';entry[suffix+'_mesh_sha256']=sha(data);entry[suffix+'_texture_sha256']=sha((res/(rid+'-texture.png')).read_bytes())
   # Keep declared original Swift texture hash as independent provenance (may differ container, not pixels).
   asset=p['selectedTexture'] if suffix=='selected' else p['baselineTexture'];original=checked(swift/asset['file'],asset['sha256']);assert texture.convert('RGBA').tobytes()==Image.open(swift/asset['file']).convert('RGBA').tobytes();entry[suffix+'_source_texture_sha256']=sha(original)
  native['parts'].append(entry)
 resource='sourceparts-'+topic;data=(json.dumps(native,indent=2)+'\n').encode();(res/(resource+'.json')).write_bytes(data)
 for mode in ['3d','2d']:
  manifest['items'].append(dict(id=resource+'-'+mode,title=topic+' · actual source parts '+('3D (blue RGBA fallback)' if mode=='3d' and topic=='solar-system' else mode.upper()),animation='source-parts',source_parts_file='Catalog/'+resource,source_parts_mode=mode,source_parts_sha256=sha(data),width=.21,height=.294,center_x=0,center_y=0,target_file=target,target_sha256=sha(pagebytes),cohort='source-parts',source='Exact source SAM2 RGBA / actual Hunyuan inferred geometry; authored rigid centroid mechanics, not inferred rig or physical calibration',physical_verified=False))
(res/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n');print('Preserved67 + four source-part modes =71')

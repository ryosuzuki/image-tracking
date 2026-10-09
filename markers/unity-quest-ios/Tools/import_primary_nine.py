import pathlib,json,struct,hashlib
import trimesh,numpy as np
from PIL import Image
root=pathlib.Path(__file__).resolve().parents[1];src=pathlib.Path('/tmp/image-tracking-output/alienware-gpu-lab/2026-10-09/hunyuan-primary-nine');res=root/'Assets/DedicatedTracker/Resources/Catalog';targets=root/'Assets/StreamingAssets/catalog';source_manifest=json.loads((src/'hunyuan-primary-nine-manifest.json').read_text());derivatives=json.loads((src/'triposr-mobile-derivative-receipt.json').read_text());derived={i['id']:i for i in derivatives['items']};manifest=json.loads((res/'manifest.json').read_text());assert len(source_manifest['items'])==9
# Complete fail-closed verification before writing a resource: replaced aliases must match finalmanifest.
for i in source_manifest['items']:
 for key in ['source_page','corrected_input','corrected_triposr_mobile','glb','swift_texture']:
  f=i['files'][key];assert hashlib.sha256((src/f).read_bytes()).hexdigest()==i['sha256'][f],(i['id'],key,'stale alias')
 assert i['target_page_policy']['required_sha256']==i['sha256'][i['files']['source_page']]
 assert derived[i['id']]['derived_sha256']==i['sha256'][i['files']['corrected_triposr_mobile']]
 assert i['inference']['input_sha256']==derived[i['id']]['input_sha256']==i['provenance']['input_sha256']
manifest['items']=[i for i in manifest['items'] if i.get('cohort')!='primary-nine-final']
for i in source_manifest['items']:
 page=src/i['files']['source_page'];im=Image.open(page);target_id=i['target_page_policy']['target_identifier'];target=target_id+'.png';(targets/target).write_bytes(page.read_bytes());box=i['provenance']['original_segmentation']['bbox_uv'];h=.21*im.height/im.width
 for backend,key in [('hunyuan','glb'),('triposr','corrected_triposr_mobile')]:
  id=target_id+'-'+backend;path=src/i['files'][key];mesh=trimesh.load(path).to_geometry();v=np.array(mesh.vertices,dtype='<f4')
  if backend=='triposr': v=np.stack([v[:,0],-v[:,2],v[:,1]],axis=1).astype('<f4')
  v-=(v.min(0)+v.max(0))/2;v/=np.ptp(v,axis=0).max();f=np.array(mesh.faces,dtype='<i4');textured=backend=='hunyuan';c=np.ones((len(v),4),dtype=np.uint8)*255 if textured else np.array(mesh.visual.vertex_colors,dtype=np.uint8)[:,:4];data=struct.pack('<ii',len(v),len(f))+v.tobytes()+c.tobytes()+f.tobytes()
  texture_sha=None
  if textured:
   texture=src/i['files']['swift_texture'];embedded=mesh.visual.material.baseColorTexture;assert embedded.convert('RGBA').tobytes()==Image.open(texture).convert('RGBA').tobytes();data+=np.array(mesh.visual.uv,dtype='<f4').tobytes();(res/(id+'-texture.png')).write_bytes(texture.read_bytes());texture_sha=hashlib.sha256(texture.read_bytes()).hexdigest()
  (res/(id+'.bytes')).write_bytes(data)
  item=dict(id=id,title=i['id']+' · corrected same-input '+backend,animation=i['animation'],width=.21,height=h,display_scale=i['display_width_m'],center_x=((box[0]+box[2])/2-.5)*.21,center_y=(.5-(box[1]+box[3])/2)*h,target_file=target,target_identifier=target_id,target_sha256=i['target_page_policy']['required_sha256'],model_sha256=i['sha256'][i['files'][key]],mesh_sha256=hashlib.sha256(data).hexdigest(),source_input_sha256=i['provenance']['input_sha256'],textured=textured,backend=backend,cohort='primary-nine-final',source_scope=i['source_scope'],source='Same corrected source input; real '+backend+' inference, unrigged; explicitly authored motion layer',coordinate_conversion='Hunyuan Y-up: no X rotation; centre/uniform normalization only' if textured else 'Tripo original Z-up: (x,-z,y) conversion then centre/uniform normalization',physical_verified=False)
  if texture_sha:item['texture_sha256']=texture_sha
  manifest['items'].append(item)
(res/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n');print(json.dumps(dict(choices=len(manifest['items']),appended=18,all_nine_source_hashes_verified=True)))

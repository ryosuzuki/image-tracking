import json, pathlib, struct, hashlib, base64
import trimesh, numpy as np
from PIL import Image
root=pathlib.Path(__file__).resolve().parents[1]; source=pathlib.Path('/tmp/image-tracking-output/alienware-gpu-lab/2026-10-08/realityextract-39'); web=pathlib.Path('/path/to/projects/realityextract-webxr/public')
res=root/'Assets/DedicatedTracker/Resources/Catalog'; targets=root/'Assets/StreamingAssets/catalog'; res.mkdir(parents=True,exist_ok=True);targets.mkdir(parents=True,exist_ok=True)
items=[]
for item in json.loads((source/'manifest.json').read_text())['items']:
 id=item['id']; path=source/item['model']; scene=trimesh.load(path); mesh=scene.to_geometry() if hasattr(scene,'to_geometry') else scene.dump(concatenate=True)
 verts=np.array(mesh.vertices,dtype=np.float32); verts=np.stack([verts[:,0],-verts[:,2],verts[:,1]],axis=1); verts-= (verts.min(0)+verts.max(0))/2;verts/=np.ptp(verts,axis=0).max()
 colors=np.array(mesh.visual.vertex_colors,dtype=np.uint8);faces=np.array(mesh.faces,dtype=np.int32)
 data=struct.pack('<ii',len(verts),len(faces))+verts.astype('<f4').tobytes()+colors[:,:4].tobytes()+faces.astype('<i4').tobytes();(res/(id+'.bytes')).write_bytes(data)
 Image.open(source/item['page']).convert('RGB').save(targets/(id+'.jpg'),quality=95)
 items.append(dict(id=id,title=item['title'],animation=item['animation'],width=.21,height=.294,mesh_sha256=hashlib.sha256(data).hexdigest(),model_sha256=hashlib.sha256(path.read_bytes()).hexdigest(),source=item['inference'],physical_verified=False))
for id,anim in [('math-original','math'),('physics-pendulum-original','physics-pendulum'),('physics-incline-original','physics-incline')]:
 im=Image.open(web/'originals'/(id+'.png'));im.convert('RGB').save(targets/(id+'.jpg'),quality=95)
 items.append(dict(id=id,title=id,animation=anim,width=.21,height=.21*im.height/im.width,source='Original source assets; new Unity interaction adapter',physical_verified=False))
physics=pathlib.Path('/path/to/projects/realityextract-webxr/src/original-physics/DemoJSONs')
for name,id in [('singlependulum','physics-pendulum-original'),('page1','physics-incline-original')]:
 original=json.loads((physics/(name+'.json')).read_text())[0];objects=[]
 original['width']=430 if name=='singlependulum' else original['width']
 from io import BytesIO
 background=Image.open(BytesIO(base64.b64decode(original['image'].split(',',1)[1]))).convert('RGBA'); x,y=original['topLeft'];patch=background.crop((x,y,x+original['width'],y+original['height']));alpha=Image.new('L',patch.size,0)
 for o in original['sceneJSON']['objects']:
  if not o['static']:
   sprite=Image.open(BytesIO(base64.b64decode(o['segment'].split(',',1)[1]))).convert('RGBA');alpha.paste(sprite.getchannel('A'),tuple(o['topLeft']))
 patch.putalpha(alpha);patch.save(res/(id+'-repair.png'))
 for i,o in enumerate(original['sceneJSON']['objects']):
  (res/(id+'-'+str(i)+'.png')).write_bytes(base64.b64decode(o['segment'].split(',',1)[1])); objects.append(dict(center=[o['center']['x'],o['center']['y']],topLeft=o['topLeft'],static=o['static'],contour=o['verteces']))
 (res/(id+'.json')).write_text(json.dumps(dict(width=original['width'],height=original['height'],objects=objects,slope_radians=float(np.arctan((306-238)/(787-170))) if name=='page1' else 0)))
(res/'manifest.json').write_text(json.dumps(dict(items=items,provenance='SAM2 extracted source + genuine TripoSR generated meshes. Runtime parametric parts separately authored; no learned rigging.',physical_verified=False),indent=2))
print(json.dumps(dict(items=len(items),vertices=sum(struct.unpack('<i',(res/(x['id']+'.bytes')).read_bytes()[:4])[0] for x in items if 'mesh_sha256' in x))))

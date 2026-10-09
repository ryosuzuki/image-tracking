#!/usr/bin/env python3
"""Verify manifest, actual page pixels, inferred mesh mapping. Not optical acceptance."""
import json,pathlib,hashlib,sys,zipfile,struct,math
from PIL import Image
root=pathlib.Path(__file__).parent/'Resources/SciencePages'
data=json.loads((root/'manifest.json').read_text())
assert len(data)==70, f'Expected61 preserved pages+9 corrected-input comparison pages, got{len(data)}'
seen=set();records=[]
for item in data:
 assert item['id'] not in seen;seen.add(item['id'])
 page=root/item['page'];mesh=root/item['mesh']
 Image.open(page).verify()
 assert mesh.exists() and mesh.stat().st_size>100
 if mesh.suffix=='.json':
  spec=json.loads(mesh.read_text())
  if item['animation']=='source-math-binding':
   assert spec['sourceSize']==list(Image.open(page).size)
   assert spec['printedEquation']=='f(x)=x²+6x+10'
   assert spec['originalViewport']==[430,595,800,445]
  elif item['animation'] in ['source-math-extension','source-math-triangle']:
   assert spec['sourceSize']==list(Image.open(page).size)
   assert len(spec['referenceCrop'])==4
   if item['animation']=='source-math-triangle':
    assert spec['relationship']=='a²+b²=c²'
    assert spec['referenceCrop']==[500,970,650,310]
    assert spec['vertices']=={'left':[839,1218],'rightAngle':[1051,1218],'upper':[1051,1086]}
   if 'sha256' in spec: assert spec['sha256']==hashlib.sha256(page.read_bytes()).hexdigest()
   if 'pageSHA256' in spec: assert spec['pageSHA256']==hashlib.sha256(page.read_bytes()).hexdigest()
  else: assert spec['parts']
  for part in spec.get('parts',[]):
   assert part['original_rgb_exact'] is True
   cutout=root/part['file'];im=Image.open(cutout);assert im.mode=='RGBA';assert im.size==Image.open(page).size
   assert all(0<=x<=1 for x in part['bbox'])
 elif mesh.suffix=='.geom':
  raw=mesh.read_bytes();assert raw[:4]==b'PLUV';vertices,indices=struct.unpack_from('<II',raw,4)
  assert len(raw)==12+vertices*32+indices*4 and indices%3==0
  assert all(math.isfinite(v) for (v,) in struct.iter_unpack('<f',raw[12:12+vertices*32]))
  assert all(i<vertices for (i,) in struct.iter_unpack('<I',raw[12+vertices*32:]))
  assert Image.open(root/item['texture']).size==(1024,1024)
 elif mesh.suffix=='.usdz':
  with zipfile.ZipFile(mesh) as z: assert any(n.endswith(('.usd','.usdc','.usda')) for n in z.namelist())
 else:
  text=mesh.read_text(errors='replace')
  assert '\nv ' in '\n'+text and '\nf ' in '\n'+text
 if item.get('variantMesh'):
  assert (root/item['variantMesh']).exists() and (root/item['variantTexture']).exists()
  variant=next(v for v in json.loads((root/'texture-variants.json').read_text()) if v['id']==item['id'])
  assert hashlib.sha256(page.read_bytes()).hexdigest()==variant['source_page_sha256']
 if 'referenceCrop' in item:
  x,y,w,h=item['referenceCrop'];pw,ph=Image.open(page).size
  assert x>=0 and y>=0 and w>0 and h>0 and x+w<=pw and y+h<=ph
 assert item['animation'] in ['spin','pulse','bob','orbit','drive','explode','unzip','flow','gears','fold','count','story','cycle','swing','tilt','lift','reciprocate','load','field','bond','breathe','flap','swim','walk','grow','release','expand','divide','source-pixel-physics','source-math-binding','source-math-extension','source-math-triangle']
 records.append({'id':item['id'],'page_sha256':hashlib.sha256(page.read_bytes()).hexdigest(),'mesh_sha256':hashlib.sha256(mesh.read_bytes()).hexdigest()})
import struct,math
variants=json.loads((root/'texture-variants.json').read_text())
assert len(variants)==11
for item in variants:
 geometry=root/item['geometry'];texture=root/item['texture']
 assert hashlib.sha256(geometry.read_bytes()).hexdigest()==item['geometry_sha256']
 assert hashlib.sha256(texture.read_bytes()).hexdigest()==item['texture_sha256']
 assert Image.open(texture).size==(1024,1024)
 raw=geometry.read_bytes();assert raw[:4]==b'PLUV';vertices,indices=struct.unpack_from('<II',raw,4)
 assert vertices==item['vertices'] and indices==item['faces']*3 and len(raw)==12+vertices*32+indices*4
 assert all(math.isfinite(v) for (v,) in struct.iter_unpack('<f',raw[12:12+vertices*32]))
 assert all(i<vertices for (i,) in struct.iter_unpack('<I',raw[12+vertices*32:]))
print(json.dumps({'status':'pass','entries':len(records),'texture_variants':len(variants),'records':records},indent=2))

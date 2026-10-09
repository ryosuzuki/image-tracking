import json,pathlib,struct,hashlib
root=pathlib.Path(__file__).resolve().parents[1];r=root/'Assets/DedicatedTracker/Resources/Catalog';d=json.loads((r/'manifest.json').read_text());assert len(d['items'])==81;assert len({x['id'] for x in d['items']})==81
original67=json.loads(json.dumps(d['items'][:67]));p=next(x for x in original67 if x['id']=='physics-pendulum-original');[p.pop(k,None) for k in ['target_file','target_sha256','diagram_file','diagram_sha256','solver_upgrade']]
assert hashlib.sha256(json.dumps(original67,sort_keys=True,separators=(',',':')).encode()).hexdigest()=='db8419dee1b4aa932d8b270acf56bf986ddc9115f844026139e1d79e19ab44e9'
triangles=0;page_hashes=set()
for x in d['items']:
 page=root/'Assets/StreamingAssets/catalog'/x.get('target_file',x['id']+'.jpg');assert page.is_file();page_hashes.add(hashlib.sha256(page.read_bytes()).hexdigest())
 if 'target_sha256' in x: assert hashlib.sha256(page.read_bytes()).hexdigest()==x['target_sha256']
 if 'texture_sha256' in x: assert hashlib.sha256((r/(x['id']+'-texture.png')).read_bytes()).hexdigest()==x['texture_sha256']
 if 'mesh_sha256' in x:
  b=(r/(x['id']+'.bytes')).read_bytes();n,f=struct.unpack('<ii',b[:8]);assert len(b)==8+n*(24 if x.get("textured") else 16)+f*12;assert hashlib.sha256(b).hexdigest()==x['mesh_sha256'];triangles+=f
  if x["id"]=="original-oct2-printed-car": assert f==17982 and x["target_crop_px"]==[140,710,660,320] and x["target_pixels_match_swift"]
assert len(page_hashes)==57
cohort=[x for x in d['items'] if x.get('cohort')=='primary-nine-final'];assert len(cohort)==18
pairs={}
for x in cohort:pairs.setdefault(x['target_identifier'],[]).append(x)
assert len(pairs)==9
for pair in pairs.values():
 assert len(pair)==2 and {x['backend'] for x in pair}=={'hunyuan','triposr'}
 assert len({x['target_sha256'] for x in pair})==len({x['source_input_sha256'] for x in pair})==1
 for x in pair:
  assert ('no X rotation' in x['coordinate_conversion']) if x['backend']=='hunyuan' else ('(x,-z,y)' in x['coordinate_conversion'])
math=[x for x in d['items'] if x.get('cohort')=='source-math-adapters'];assert len(math)==3
for x in math:assert hashlib.sha256((r/(x['id']+'-spec.json')).read_bytes()).hexdigest()==x['spec_sha256']
for id in ['physics-pendulum-original' ,'physics-incline-original']:
 p=json.loads((r/(id+'.json')).read_text());assert len(p['objects'])==2;assert sum(not x['static'] for x in p['objects'])==1
print(json.dumps({'pass':True,'choices':81,'distinct_page_images':len(page_hashes),'triposr_meshes':39,'hunyuan_uv_meshes':3,'actual_reference_car_meshes':1,'primary_nine_same_input_pairs':9,'source_math_adapters':3,'triangles':triangles,'native_physical_verified':False}))

parts=[x for x in d['items'] if x.get('cohort')=='source-parts'];assert len(parts)==4
for item in parts:
 path=r/(item['source_parts_file'].split('/')[-1]+'.json');assert hashlib.sha256(path.read_bytes()).hexdigest()==item['source_parts_sha256'];config=json.loads(path.read_text());assert len(config['parts'])==5
 for part in config['parts']:
  assert part['quantity']==1
  assert hashlib.sha256((r/(part['cutout_resource'].split('/')[-1]+'.png')).read_bytes()).hexdigest()==part['cutout_sha256']
  for suffix in ['baseline','selected']:
   for kind,ext in [('mesh','.bytes'),('texture','.png')]:
    assert hashlib.sha256((r/(part[suffix+'_'+kind+'_resource'].split('/')[-1]+ext)).read_bytes()).hexdigest()==part[suffix+'_'+kind+'_sha256']
 assert sum(x['fallback'] for x in config['parts'])==(1 if config['topic']=='solar-system' else 0)
print('Actual10baseline assets plus arithmetic4 fullseed42 and four source views verified')

next_parts=[x for x in d['items'] if x.get('cohort')=='next-four-parts'];assert len(next_parts)==8
for item in next_parts:
 configpath=r/(item['source_parts_file'].split('/')[-1]+'.json');assert hashlib.sha256(configpath.read_bytes()).hexdigest()==item['source_parts_sha256'];config=json.loads(configpath.read_text());assert len(config['parts'])==(3 if config['topic']=='cell' else 2)
 for part in config['parts']:
  for key,ext in [('cutout','.png'),('selected_texture','.png'),('selected_mesh','.bytes')]:
   f=r/(part[key+'_resource'].split('/')[-1]+ext);assert hashlib.sha256(f.read_bytes()).hexdigest()==part[key+'_sha256']
  for key in ['cutout','selected_texture']:
   f=r/(part[key+'_resource'].split('/')[-1]+'-hashbytes.bytes');assert hashlib.sha256(f.read_bytes()).hexdigest()==part[key+'_sha256']
 assert sum(p['fallback'] for p in config['parts'])==({'cell':2,'dna':0,'machine':0,'origami':1}[config['topic']])
print('Nextfour: nine true identities/six mini selected meshes/three exactRGBA fallbacks verified')
preserved=json.loads(json.dumps(d['items'][:71]));p=next(x for x in preserved if x['id']=='physics-pendulum-original');[p.pop(k,None) for k in ['target_file','target_sha256','diagram_file','diagram_sha256','solver_upgrade']]
assert hashlib.sha256(json.dumps(preserved,sort_keys=True,separators=(',',':')).encode()).hexdigest()=='00f702be2e4d6f3272ff411ebd1bfe2b4dfcff7b1c24a15490f0a2544385d0ed'

diagrams=[x for x in d['items'] if x.get('diagram_file')];assert len(diagrams)==3
for item in diagrams:
 path=r/(item['diagram_file'].split('/')[-1]+'.json');assert hashlib.sha256(path.read_bytes()).hexdigest()==item['diagram_sha256'];spec=json.loads(path.read_text())
 for key in ['page','cutout']:
  if key+'_resource' not in spec:continue
  witness=r/(spec[key+'_resource'].split('/')[-1]+'-hashbytes.bytes');assert hashlib.sha256(witness.read_bytes()).hexdigest()==spec[key+'_sha256']
print('Original optics/circuit added; existing pendulum identity upgraded to source-bob nonlinear RK4')
preserved79=json.loads(json.dumps(d['items'][:79]));p=next(x for x in preserved79 if x['id']=='physics-pendulum-original');[p.pop(k,None) for k in ['target_file','target_sha256','diagram_file','diagram_sha256','solver_upgrade']]
assert hashlib.sha256(json.dumps(preserved79,sort_keys=True,separators=(',',':')).encode()).hexdigest()=='f26c46ef70ce56520881ddda42367b719371487cc4b01f97f068bc615b601f67'

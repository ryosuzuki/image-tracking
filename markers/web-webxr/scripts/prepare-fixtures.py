import cv2,numpy as np,json,pathlib
p=pathlib.Path(__file__).resolve().parents[1]/'public';cases=[]
for tracker in ['dots','aruco']:
 for id in [7,8]:
  src=cv2.imread(str(p/f'markers/{tracker}-{id}.png'))
  for name,dst in [('front',[[130,50],[510,50],[510,430],[130,430]]),('perspective',[[176,85],[460,122],[510,387],[117,427]]),('warm-dim',[[176,85],[460,122],[510,387],[117,427]])]:
   H=cv2.getPerspectiveTransform(np.float32([[0,0],[699,0],[699,699],[0,699]]),np.float32(dst));out=cv2.warpPerspective(src,H,(640,480),borderValue=(240,240,240))
   if name=='warm-dim':out=np.clip(out.astype(float)*[.7,.78,.9],0,255).astype(np.uint8)
   f=f'{tracker}-{id}-{name}.png';cv2.imwrite(str(p/'fixtures'/f),out);cases.append({'file':f,'tracker':tracker,'expectedId':id,'kind':'synthetic-perspective-fixture','expectedDetected':True})
  out=cv2.warpPerspective(src,cv2.getPerspectiveTransform(np.float32([[0,0],[699,0],[699,699],[0,699]]),np.float32([[130,50],[510,50],[510,430],[130,430]])),(640,480),borderValue=(240,240,240));cv2.rectangle(out,(120,40),(250,190),(240,240,240),-1);f=f'{tracker}-{id}-occluded.png';cv2.imwrite(str(p/'fixtures'/f),out);cases.append({'file':f,'tracker':tracker,'expectedId':id if tracker=='dots' else None,'kind':'synthetic-corner-occlusion','expectedDetected':tracker=='dots'})
cv2.imwrite(str(p/'fixtures/blank.png'),np.full((480,640,3),240,np.uint8));cases.append({'file':'blank.png','tracker':'dots','expectedId':None,'expectedDetected':False});cases.append({'file':'blank.png','tracker':'aruco','expectedId':None,'expectedDetected':False});(p/'fixtures/manifest.json').write_text(json.dumps(cases,indent=2))

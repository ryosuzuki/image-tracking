"""Generate calibrated detector regression images, NOT real device observations."""
import json,pathlib,cv2,numpy as np,sys
root=pathlib.Path(__file__).parent;inputs=pathlib.Path(sys.argv[1]);out=root/'fixtures';out.mkdir(exist_ok=True)
K=np.array([[1000.,0,480],[0,1000,360],[0,0,1.]])
tests=[]
for mode in ['dots','aruco']:
 for kind,rvec,tvec in [('front',[0.,0.,0.],[0.,0.,.45]),('angle',[.30,-.45,.17],[.018,-.025,.52]),('far',[.1,.1,-.6],[0.,0.,.9]),('dim',[.0,.2,.7],[0.,0.,.5]),('occluded',[0.,0.,0.],[0.,0.,.45]),('two-corners',[0.,0.,0.],[0.,0.,.45]),('occluded-angle',[.30,-.45,.17],[.018,-.025,.52]),('blank',[0.,0.,0.],[0.,0.,.45])]:
  src=cv2.imread(str(inputs/f'{mode}-7.png'));h,w=src.shape[:2]
  paper=np.array([[-.07,-.07,0],[.07,-.07,0],[.07,.07,0],[-.07,.07,0]],np.float32)
  projected=cv2.projectPoints(paper,np.array(rvec),np.array(tvec),K,None)[0].reshape(4,2)
  H=cv2.getPerspectiveTransform(np.array([[0,0],[w-1,0],[w-1,h-1],[0,h-1]],np.float32),projected.astype(np.float32))
  image=cv2.warpPerspective(src,H,(960,720),borderValue=(235,235,235))
  if kind=='dim':image=np.clip(image.astype(float)*.62,0,255).astype(np.uint8)
  if kind=='occluded':cv2.rectangle(image,(330,200),(430,330),(240,240,240),-1)
  if kind=='two-corners':
   cv2.rectangle(image,(330,200),(430,330),(240,240,240),-1);cv2.rectangle(image,(520,425),(640,515),(240,240,240),-1)
  if kind=='occluded-angle':
   # Mask only the true observed extent of corner0; no synthetic hidden correspondences.
   local=np.array([[-.06,-.06,0],[-.036,-.06,0],[-.06,-.036,0]],np.float32)
   points=cv2.projectPoints(local,np.array(rvec),np.array(tvec),K,None)[0].reshape(-1,2)
   lo=np.floor(points.min(axis=0)-8).astype(int);hi=np.ceil(points.max(axis=0)+8).astype(int);cv2.rectangle(image,tuple(lo),tuple(hi),(240,240,240),-1)
  if kind=='blank':image[:]=235
  name=f'{mode}-{kind}';cv2.imwrite(str(out/f'{name}.png'),image)
  tests.append({'name':name,'mode':mode,'file':f'{name}.png','K':[1000,1000,480,360],'expectedID':None if kind in ['two-corners','blank'] or (mode=='aruco' and kind in ['occluded','occluded-angle']) else 7,'expectedCorners':(3 if kind in ['occluded','occluded-angle'] else 4) if mode=='dots' and kind not in ['two-corners','blank'] else None,'rvec':rvec,'tvec':tvec,'synthetic':True})
# Independently mask each full L-code for both program IDs under perspective.
contract=json.loads((root/'marker-contract.json').read_text())
for marker_id in [7,8]:
 src=cv2.imread(str(inputs/f'dots-{marker_id}.png'));h,w=src.shape[:2]
 rvec=[.2,-.28,.31];tvec=[.015,-.01,.58]
 paper=np.array([[-.07,-.07,0],[.07,-.07,0],[.07,.07,0],[-.07,.07,0]],np.float32)
 projected=cv2.projectPoints(paper,np.array(rvec),np.array(tvec),K,None)[0].reshape(4,2)
 H=cv2.getPerspectiveTransform(np.array([[0,0],[w-1,0],[w-1,h-1],[0,h-1]],np.float32),projected.astype(np.float32))
 for corner in range(4):
  image=cv2.warpPerspective(src,H,(960,720),borderValue=(235,235,235))
  f=contract['cornerFrames'][corner];points=[]
  for j in range(7):
   du=j if j<4 else 0;dv=j-3 if j>=4 else 0;s=contract['dotSpacingM']
   points.append([f['center'][0]-.06+s*(du*f['u'][0]+dv*f['v'][0]),f['center'][1]-.06+s*(du*f['u'][1]+dv*f['v'][1]),0])
  pixels=cv2.projectPoints(np.array(points,np.float32),np.array(rvec),np.array(tvec),K,None)[0].reshape(-1,2)
  lo=np.floor(pixels.min(axis=0)-7).astype(int);hi=np.ceil(pixels.max(axis=0)+7).astype(int);cv2.rectangle(image,tuple(lo),tuple(hi),(240,240,240),-1)
  name=f'dots-id{marker_id}-missing-{corner}';cv2.imwrite(str(out/f'{name}.png'),image)
  tests.append({'name':name,'mode':'dots','file':f'{name}.png','K':[1000,1000,480,360],'expectedID':marker_id,'expectedCorners':3,'expectedCornerIDs':[c for c in range(4) if c!=corner],'rvec':rvec,'tvec':tvec,'synthetic':True})
(out/'manifest.json').write_text(json.dumps({'tests':tests,'source':'Synthetic known-camera optical projections, not live AR observations','cornerExtentM':.12},indent=2))
print(len(tests))

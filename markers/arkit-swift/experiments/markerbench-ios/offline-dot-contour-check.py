"""Faithful offline reference of native contour/ID stages, not live acceptance.
Requires Python OpenCV + NumPy. Invoke IMAGE_PATH to compare old/new topology.
No camera pose is reported without capture intrinsics.
"""
import cv2,numpy as np,math,json,sys
words=np.array([[[1,3,1,2,0,1,3],[1,0,3,2,2,2,2],[2,1,3,3,0,1,3],[3,0,3,3,1,0,2]],[[2,3,3,1,2,0,0],[0,2,1,1,3,3,3],[3,3,2,2,1,0,1],[0,1,3,2,0,2,1]]])
def detect(path, hierarchy_mode=True):
 bgr=cv2.imread(path);rgb=cv2.cvtColor(bgr,cv2.COLOR_BGR2RGB).astype(np.float32);r,g,b=rgb[:,:,0],rgb[:,:,1],rgb[:,:,2];hi=rgb.max(2);lo=rgb.min(2);chroma=(hi>=75)&(hi-lo>=hi*.32);classes=np.full(hi.shape,-1,np.int8);classes[hi<85]=3;classes[chroma&(r>g*1.35)&(r>b*1.22)]=0;classes[chroma&(g>r*1.22)&(g>b*1.12)]=1;classes[chroma&(b>r*1.25)&(b>g*1.12)]=2
 blobs=[]
 for col in range(4):
  cont,hierarchy=cv2.findContours(np.uint8(classes==col)*255,cv2.RETR_CCOMP if hierarchy_mode else cv2.RETR_EXTERNAL,cv2.CHAIN_APPROX_SIMPLE)
  for contourIndex,c in enumerate(cont):
   if hierarchy_mode and hierarchy[0][contourIndex][3]>=0:continue
   area=cv2.contourArea(c);x,y,w,h=cv2.boundingRect(c)
   if area<9 or area>20000 or w>250 or h>250 or x<=0 or y<=0 or x+w>=rgb.shape[1]-1 or y+h>=rgb.shape[0]-1 or w/h<.22 or w/h>4.5 or area/(w*h)<.38:continue
   m=cv2.moments(c)
   if m['m00']:blobs.append((np.array([m['m10']/m['m00'],m['m01']/m['m00']]),col,math.sqrt(area/math.pi)))
 blobs.sort(key=lambda t:-t[2]);total=len(blobs);blobs=blobs[:180];points=np.array([t[0] for t in blobs]);out=[]
 for ci,(c,color,radius) in enumerate(blobs):
  distances=np.linalg.norm(points-c,axis=1);near=sorted([(float(d),j) for j,d in enumerate(distances) if j!=ci and d>radius*1.45 and d<radius*10])[:10]
  for _,uj in near:
   for _,vj in near:
    if uj==vj:continue
    u=points[uj]-c;v=points[vj]-c;lu=np.linalg.norm(u);lv=np.linalg.norm(v);cross=u[0]*v[1]-u[1]*v[0];cos=u@v/(lu*lv)
    if cross<=0 or abs(cos)>.78 or lu/lv<.25 or lu/lv>4:continue
    inds=[ci];fail=False
    for axis in [u,v]:
     length=np.linalg.norm(axis)
     for step in range(1,4):
      target=c+step*axis;dist=np.linalg.norm(points-target,axis=1);dist[inds]=np.inf;j=int(dist.argmin())
      if dist[j]>=length*.36:fail=True;break
      inds.append(j)
     if fail:break
    if fail:continue
    colors=[blobs[j][1] for j in inds]
    for ident in range(2):
     for corner in range(4):
      if colors==list(words[ident,corner]):out.append({'id':ident+7,'corner':corner,'point':c.tolist(),'indexes':inds,'points':points[inds].tolist()})
 return {'blobCountBeforeBudget':total,'blobCountAfterBudget':len(blobs),'blobs':[{'point':p.tolist(),'color':c,'radius':rad} for p,c,rad in blobs],'decoded':out}
if __name__=='__main__':
 results={}
 for name,mode in [("external-before",False),("foreground-ccomp-after",True)]:
  d=detect(sys.argv[1],mode);results[name]={"blobCount":d["blobCountAfterBudget"],"decoded":[{"id":c["id"],"corner":c["corner"],"point":c["point"],"observedPoints":len(c["points"])} for c in d["decoded"]]}
 print(json.dumps(results,indent=2))

"""Four monochrome L brackets: contour reflex-vertex detector + planar homography."""
import cv2,numpy as np,json,pathlib,argparse
W,H=800,600
P=np.array([[160,140],[640,140],[640,460],[160,460]],np.float32)
def page():
 im=np.full((H,W,3),255,np.uint8)
 for i,(x,y) in enumerate(P.astype(int)):
  dx=1 if i in (0,3) else -1;dy=1 if i in (0,1) else -1
  cv2.line(im,(x,y),(x+dx*45,y),(0,0,0),10);cv2.line(im,(x,y),(x,y+dy*45),(0,0,0),10)
 return im

def detect(im):
 g=cv2.cvtColor(im,cv2.COLOR_BGR2GRAY);m=(g<100).astype(np.uint8)*255
 contours,_=cv2.findContours(m,cv2.RETR_EXTERNAL,cv2.CHAIN_APPROX_SIMPLE);pts=[]
 for c in contours:
  area=cv2.contourArea(c)
  if not 80<area<5000:continue
  hull=cv2.convexHull(c,returnPoints=False)
  if hull is None or len(hull)<3:continue
  defects=cv2.convexityDefects(c,hull)
  if defects is None:continue
  best=max(defects.reshape(-1,4),key=lambda d:d[3])
  if best[3]/256>6:pts.append(c[best[2],0])
 if len(pts)!=4:return None
 pts=np.array(pts,np.float32);angles=np.arctan2(pts[:,1]-pts[:,1].mean(),pts[:,0]-pts[:,0].mean());pts=pts[np.argsort(angles)]
 return pts

def run(out):
 out.mkdir(parents=True,exist_ok=True);video=cv2.VideoWriter(str(out/'four-l-homography.mp4'),cv2.VideoWriter_fourcc(*'mp4v'),20,(W,H+80));rows=[]
 for t in range(240):
  angle=25*np.sin(t/40);M=cv2.getRotationMatrix2D((400,300),angle,.9);T=np.vstack([M,[0,0,1.]])
  if t>=80:T=np.array([[1,.06,0],[.04,.8,35],[.00025*np.sin(t/30),.0002,1]])@T
  im=cv2.warpPerspective(page(),T,(W,H),borderValue=(255,255,255));truth=cv2.perspectiveTransform(P[None],T)[0]
  if t>=160: im=cv2.GaussianBlur(im,(7,7),0)
  q=detect(im);err=None
  if q is not None:
   # No IDs: choose minimum cyclic geometric correspondence for evaluation only.
   errors=[np.linalg.norm(np.roll(q,i,axis=0)-truth,axis=1).mean() for i in range(4)];err=float(min(errors))
   hom=cv2.getPerspectiveTransform(np.array([[0,0],[480,0],[480,320],[0,320]],np.float32),q)
   for x in range(0,481,80):
    a=cv2.perspectiveTransform(np.array([[[x,0],[x,320]]],np.float32),hom)[0].astype(int);cv2.line(im,tuple(a[0]),tuple(a[1]),(220,130,0),1)
   for y in range(0,321,80):
    a=cv2.perspectiveTransform(np.array([[[0,y],[480,y]]],np.float32),hom)[0].astype(int);cv2.line(im,tuple(a[0]),tuple(a[1]),(220,130,0),1)
   for p in q:cv2.circle(im,tuple(p.astype(int)),5,(0,170,255),2)
  rows.append(dict(frame=t,detected=q is not None,mean_bracket_notch_offset_px=err))
  canvas=np.full((H+80,W,3),255,np.uint8);canvas[:H]=im;cv2.putText(canvas,'SYNTHETIC FOUR-L PAGE | planar grid, NOT calibrated 3D',(12,H+30),cv2.FONT_HERSHEY_SIMPLEX,.55,(0,0,0),1);cv2.putText(canvas,'No ID | orientation / identical-sheet ambiguity remains',(12,H+60),cv2.FONT_HERSHEY_SIMPLEX,.55,(0,0,0),1);video.write(canvas)
  if t in (20,120,200):cv2.imwrite(str(out/f'four-l-{t}.png'),canvas)
 video.release();(out/'four-l-results.json').write_text(json.dumps(rows,indent=2));print('detected',sum(r['detected'] for r in rows),'/',len(rows))
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--output',type=pathlib.Path,default=pathlib.Path('output'));run(p.parse_args().output)

"""Known-truth shape localization benchmark. No paper ID or physical-camera claims."""
import cv2, numpy as np, json, pathlib, argparse, math
SHAPES=['circle','rounded-square','L','line']
COLORS=[(30,30,220),(30,170,30),(220,70,30),(25,25,25)]
C=np.array([[90,90],[550,90],[550,390],[90,390]],np.float32)
def mask(shape):
 m=np.zeros((81,81),np.uint8)
 if shape=='circle': cv2.circle(m,(40,40),20,255,-1)
 elif shape=='rounded-square':
  cv2.rectangle(m,(24,22),(56,58),255,-1);cv2.rectangle(m,(22,24),(58,56),255,-1)
 elif shape=='L': cv2.rectangle(m,(20,16),(35,64),255,-1);cv2.rectangle(m,(20,49),(64,64),255,-1)
 else: cv2.rectangle(m,(10,30),(70,50),255,-1)
 # Approximately equal ink area (1257 target pixels); actual raster areas recorded.
 pts=np.argwhere(m>0); scale=math.sqrt(1257/len(pts));m=cv2.resize(m,None,fx=scale,fy=scale,interpolation=cv2.INTER_NEAREST)
 return m
def source(shape):
 im=np.full((480,640,3),245,np.uint8); centers=[]
 for p,col in zip(C,COLORS):
  m=mask(shape); ys,xs=np.nonzero(m);centroid=np.array([xs.mean(),ys.mean()]); start=np.rint(p-centroid).astype(int)
  im[start[1]+ys,start[0]+xs]=col;centers.append(centroid+start)
 return im,np.array(centers,np.float32)
def detect(im):
 hsv=cv2.cvtColor(im,cv2.COLOR_BGR2HSV); masks=[((hsv[:,:,0]<10)|(hsv[:,:,0]>170))&(hsv[:,:,1]>100)&(hsv[:,:,2]>70), (hsv[:,:,0]>35)&(hsv[:,:,0]<85)&(hsv[:,:,1]>80)&(hsv[:,:,2]>60), (hsv[:,:,0]>90)&(hsv[:,:,0]<130)&(hsv[:,:,1]>80)&(hsv[:,:,2]>60),hsv[:,:,2]<65]
 result=[]
 for m in masks:
  n,l,stats,cents=cv2.connectedComponentsWithStats(m.astype(np.uint8),8);valid=[i for i in range(1,n) if stats[i,4]>35]
  result.append(cents[max(valid,key=lambda i:stats[i,4])] if valid else [float('nan')]*2)
 return np.array(result)
def run(out):
 out.mkdir(parents=True,exist_ok=True);rng=np.random.default_rng(7);rows=[];frames=[]
 writer=cv2.VideoWriter(str(out/'shape-comparison.mp4'),cv2.VideoWriter_fourcc(*'mp4v'),15,(1280,1040))
 regimes=[('rotation',0),('blur-7',7),('blur-15',15),('motion-blur',0),('perspective',0),('small',0),('noise',0),('occlusion',0)]
 for regime,blur in regimes:
  for t in range(60):
   panel=np.full((1040,1280,3),250,np.uint8)
   for k,shape in enumerate(SHAPES):
    im,truth=source(shape);a=t*6;scale=.38 if regime=='small' else .65
    M=cv2.getRotationMatrix2D((320,240),a,scale);M[:,2]+=np.array([25*np.sin(t/5),20*np.cos(t/7)])
    H=np.vstack([M,[0,0,1]])
    if regime=='perspective': H=np.array([[1, .15,0],[.04,.78,35],[.00035,.0002,1.]])@H
    p=cv2.perspectiveTransform(truth[None],H)[0];im=cv2.warpPerspective(im,H,(640,480),borderValue=(245,245,245))
    if blur: im=cv2.GaussianBlur(im,(blur,blur),0)
    if regime=='motion-blur':
     kernel=np.zeros((21,21),np.float32);kernel[10,:]=1/21;im=cv2.filter2D(im,-1,kernel)
    if regime=='noise':im=np.clip(im.astype(float)+rng.normal(0,25,im.shape),0,255).astype(np.uint8)
    if regime=='occlusion': cv2.rectangle(im,(0,0),(int(260+90*np.sin(t/8)),240),(245,245,245),-1)
    pred=detect(im);ok=np.isfinite(pred[:,0]);err=np.linalg.norm(pred-p,axis=1)
    for j in range(4):
     rows.append(dict(shape=shape,regime=regime,frame=t,corner=j,detected=bool(ok[j]),error_px=float(err[j]) if ok[j] else None,ink_area=int(np.count_nonzero(mask(shape)))))
     if ok[j]:cv2.drawMarker(im,tuple(np.rint(pred[j]).astype(int)),(0,180,255),cv2.MARKER_CROSS,15,2)
     cv2.circle(im,tuple(np.rint(p[j]).astype(int)),3,(255,0,255),-1)
    x=(k%2)*640;y=(k//2)*510
    panel[y:y+480,x:x+640]=im;cv2.putText(panel,f'{shape} | {regime} | {a} deg | {ok.sum()}/4',(x+12,y+500),cv2.FONT_HERSHEY_SIMPLEX,.65,(20,20,20),1)
   cv2.putText(panel,'SYNTHETIC ONLY | orange: detected centroid; purple: ground truth | IDs ignored',(15,1030),cv2.FONT_HERSHEY_SIMPLEX,.65,(20,20,20),1)
   writer.write(panel)
   if t==20:cv2.imwrite(str(out/f'{regime}.png'),panel)
 writer.release();(out/'measurements.json').write_text(json.dumps(rows,indent=2))
 summary=[]
 for s in SHAPES:
  for r,_ in regimes:
   q=[x for x in rows if x['shape']==s and x['regime']==r];e=[x['error_px'] for x in q if x['detected']]
   summary.append(dict(shape=s,regime=r,detected=sum(x['detected'] for x in q),total=len(q),median_error_px=float(np.median(e)),p95_error_px=float(np.percentile(e,95))))
 (out/'summary.json').write_text(json.dumps(summary,indent=2));print(json.dumps(summary))
if __name__=='__main__':
 p=argparse.ArgumentParser();p.add_argument('--output',type=pathlib.Path,default=pathlib.Path('output'));run(p.parse_args().output)

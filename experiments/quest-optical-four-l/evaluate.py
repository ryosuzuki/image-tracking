import cv2,numpy as np,json,pathlib,sys
root=pathlib.Path(sys.argv[1]);rows=json.loads((root/'capture.json').read_text());sys.path.insert(0,str(pathlib.Path(__file__).resolve().parent.parent/'shape-corner-benchmark'));from four_l import detect
out=[]
for r in rows:
 im=cv2.imread(str(root/f'{r["sample"]:04}.jpg'));g=cv2.cvtColor(im,cv2.COLOR_BGR2GRAY);cs,_=cv2.findContours((g<100).astype(np.uint8)*255,cv2.RETR_EXTERNAL,cv2.CHAIN_APPROX_SIMPLE);pts=[]
 for c in cs:
  a=cv2.contourArea(c)
  if not 150<a<5000:continue
  h=cv2.convexHull(c,returnPoints=False)
  if h is None or len(h)<3:continue
  try:d=cv2.convexityDefects(c,h)
  except cv2.error:continue
  if d is None:continue
  b=max(d.reshape(-1,4),key=lambda d:d[3]);p=cv2.approxPolyDP(c,.025*cv2.arcLength(c,True),True);sol=a/cv2.contourArea(cv2.convexHull(c));x,y,w,hh=cv2.boundingRect(c)
  if b[3]/256>6 and len(p)==6 and .25<sol<.7 and .4<w/hh<2.5:pts.append(c[b[2],0])
 q=None
 if len(pts)==4:
  q=np.array(pts,np.float32);q=q[np.argsort(np.arctan2(q[:,1]-q[:,1].mean(),q[:,0]-q[:,0].mean()))]
 try:baseline=detect(im) is not None
 except cv2.error:baseline=False
 out.append({'sample':r['sample'],'elapsed':r['hostElapsed'],'baselineFullFrame':baseline,'adapted':q is not None,'candidateCount':len(pts),'points':q.tolist() if q is not None else None})
(root/'detections.json').write_text(json.dumps(out,indent=2));print('baseline',sum(x['baselineFullFrame'] for x in out),'adapted',sum(x['adapted'] for x in out),'n',len(out));print('phases',[(i,sum(x['adapted'] for x in out if int(x['elapsed']//8)%4==i),sum(int(x['elapsed']//8)%4==i for x in out)) for i in range(4)])

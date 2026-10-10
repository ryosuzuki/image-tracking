"""Group four monochrome L corners per separate bright page region. No IDs."""
import cv2,numpy as np

def candidates(image,dark=100):
 g=cv2.cvtColor(image,cv2.COLOR_BGR2GRAY);cs,_=cv2.findContours((g<dark).astype(np.uint8)*255,cv2.RETR_LIST,cv2.CHAIN_APPROX_SIMPLE);pts=[]
 for c in cs:
  a=cv2.contourArea(c)
  if not 20<a<5000:continue
  h=cv2.convexHull(c,returnPoints=False)
  if h is None or len(h)<3:continue
  try:d=cv2.convexityDefects(c,h)
  except cv2.error:continue
  if d is None:continue
  b=max(d.reshape(-1,4),key=lambda x:x[3]);p=cv2.approxPolyDP(c,.025*cv2.arcLength(c,True),True);sol=a/cv2.contourArea(cv2.convexHull(c));x,y,w,hh=cv2.boundingRect(c)
  if b[3]/256>3 and 5<=len(p)<=8 and .25<sol<.75 and .4<w/hh<2.5:pts.append(c[b[2],0])
 return pts

def detect_multi(image,white=125):
 g=cv2.cvtColor(image,cv2.COLOR_BGR2GRAY);mask=(g>white).astype(np.uint8)*255
 mask=cv2.morphologyEx(mask,cv2.MORPH_CLOSE,np.ones((5,5),np.uint8));contours,_=cv2.findContours(mask,cv2.RETR_EXTERNAL,cv2.CHAIN_APPROX_SIMPLE);pts=candidates(image);pages=[]
 for c in contours:
  a=cv2.contourArea(c)
  if not 1500<a<500000:continue
  q=[p for p in pts if cv2.pointPolygonTest(c,tuple(float(v) for v in p),False)>=0]
  if len(q)!=4:continue
  q=np.array(q,np.float32);q=q[np.argsort(np.arctan2(q[:,1]-q[:,1].mean(),q[:,0]-q[:,0].mean()))]
  if cv2.contourArea(q)<1000 or not cv2.isContourConvex(q):continue
  pages.append(q)
 pages.sort(key=lambda q:float(q[:,0].mean()))
 return pages

import cv2,numpy as np,json,pathlib,hashlib,sys
root=pathlib.Path(sys.argv[1]);rows=json.loads((root/'capture.json').read_text());ds=json.loads((root/'multi-detections.json').read_text());times=np.array([r['hostElapsed'] for r in rows]);out=root.parent/'quest-optical-multiple-l.mp4';v=cv2.VideoWriter(str(out),cv2.VideoWriter_fourcc(*'mp4v'),6,(1280,1400));colors=[(230,170,0),(40,170,20),(180,70,180),(0,140,240)]
for frame in range(198):
 t=frame/6;i=int(np.abs(times-t).argmin());d=ds[i];im=cv2.imread(str(root/f'{i:04}.jpg'))
 for j,quad in enumerate(d['quads']):
  q=np.array(quad,np.float32);hom=cv2.getPerspectiveTransform(np.array([[0,0],[480,0],[480,320],[0,320]],np.float32),q);col=colors[j%4]
  for x in range(0,481,80):
   a=cv2.perspectiveTransform(np.array([[[x,0],[x,320]]],np.float32),hom)[0].astype(int);cv2.line(im,tuple(a[0]),tuple(a[1]),col,2)
  for y in range(0,321,80):
   a=cv2.perspectiveTransform(np.array([[[0,y],[480,y]]],np.float32),hom)[0].astype(int);cv2.line(im,tuple(a[0]),tuple(a[1]),col,2)
  for p in q:cv2.circle(im,tuple(p.astype(int)),4,(0,170,255),1)
 canvas=np.full((1400,1280,3),245,np.uint8);canvas[:1280]=im
 text=[f'ACTUAL QUEST CAMERA2 | {d["phase"].upper()} | {t:.1f}s',f'Detected regions: {d["detected"]} | displayed targets: {d["expectedDisplayed"]} | offline host detector','Four L corners per separate white region. No IDs / no persistent identity.','Overlapping / joined white regions may be rejected. Screen recapture, not paper.']
 for j,s in enumerate(text):cv2.putText(canvas,s,(16,1302+27*j),cv2.FONT_HERSHEY_SIMPLEX,.65,(0,0,0),1)
 v.write(canvas)
 if frame in [12,51,90,126,171]:cv2.imwrite(str(root.parent/f'multi-proof-{frame:03}.jpg'),canvas)
v.release();s=json.loads((root/'multi-summary.json').read_text());s['capture']={'uniqueSensorTimestamps':len(set(x['sensor']['sensorTimestampNs'] for x in rows)),'uniqueJpegHashes':len(set(hashlib.sha256((root/f'{x["sample"]:04}.jpg').read_bytes()).hexdigest() for x in rows)),'samples':len(rows),'lastHostElapsedSeconds':rows[-1]['hostElapsed'],'camera':'Quest Camera2 source=0, camera50,1280x1280','limitations':'same-capture adaptation; offline per-frame grouping, no identity; curved monitor recapture; no physical paper/metric 3D'};(root.parent/'multi-summary.json').write_text(json.dumps(s,indent=2));print(out)

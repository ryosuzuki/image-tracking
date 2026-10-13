#!/usr/bin/env python3
"""Validate a native take and optionally derive a timestamp-paced camera-only MP4."""
import argparse,json,math,pathlib,subprocess,hashlib

def validate(root):
 root=pathlib.Path(root);c=json.loads((root/'calibration.json').read_text());meta=json.loads((root/'capture.json').read_text())
 if meta.get('schema')!='paper-lab-capture-v1' or meta.get('complete') is not True:raise ValueError('Incomplete capture')
 if len(c['intrinsics'])!=4 or not all(isinstance(x,(int,float)) and not isinstance(x,bool) and math.isfinite(x) for x in c['intrinsics']) or min(c['intrinsics'][:2])<=0:raise ValueError('Invalid intrinsics')
 rows=[json.loads(x) for x in (root/'frames.jsonl').read_text().splitlines() if x.strip()]
 if not rows or len(rows)!=meta['frames']:raise ValueError('Empty take or frame count mismatch')
 stamp=-1;hashes={}
 for i,r in enumerate(rows):
  if type(r['epochMicroseconds']) is not int or r['epochMicroseconds']<=stamp:raise ValueError('Non-increasing timestamp')
  stamp=r['epochMicroseconds'];name=f'frame-{i:05}.jpg'
  if r['image']!=name or r['captureIndex']!=i:raise ValueError('Frame correspondence mismatch')
  b=(root/name).read_bytes()
  if not b.startswith(b'\xff\xd8') or not b.endswith(b'\xff\xd9'):raise ValueError('Invalid JPG')
  for field,keys in [('sensorPosition','xyz'),('sensorRotation','xyzw')]:
   if not all(type(r[field][k]) in (int,float) and math.isfinite(r[field][k]) for k in keys):raise ValueError('Invalid pose')
  if abs(math.sqrt(sum(r['sensorRotation'][k]**2 for k in 'xyzw'))-1)>.02:raise ValueError('Invalid quaternion')
  hashes[name]=hashlib.sha256(b).hexdigest()
 return c,rows,hashes

def main():
 p=argparse.ArgumentParser();p.add_argument('take',type=pathlib.Path);p.add_argument('--mp4',type=pathlib.Path);p.add_argument('--report',type=pathlib.Path);a=p.parse_args();c,rows,hashes=validate(a.take)
 span=(rows[-1]['epochMicroseconds']-rows[0]['epochMicroseconds'])/1e6
 result={'schema':'paper-lab-capture-v1','frames':len(rows),'sourceDurationSeconds':span,'observedAverageHz':(len(rows)-1)/span if span else 0,'headTrackedFrames':sum(r.get('headTracked') is True for r in rows),'reliableFrames':sum(r.get('sessionReliable') is True for r in rows),'acceptedMarkerFrames':sum(r.get('id',-1)>=0 for r in rows),'imageHashes':hashes,'physicalAlignment':'not certified by this validator'}
 if a.mp4:
  if a.mp4.exists():raise ValueError('Output already exists')
  # Concat receives relative allowlisted names only. No user path is inserted into ffmpeg commands.
  concat=a.take/'camera-export.ffconcat'
  if concat.exists():raise ValueError('Export sidecar exists')
  lines=['ffconcat version 1.0']
  for i,r in enumerate(rows):
   dt=(rows[i+1]['epochMicroseconds']-r['epochMicroseconds'])/1e6 if i+1<len(rows) else 1/3
   lines.extend([f"file '{r['image']}'",f'duration {dt:.9f}'])
  lines.append(f"file '{rows[-1]['image']}'");concat.write_text('\n'.join(lines)+'\n')
  subprocess.run(['ffmpeg','-v','error','-n','-f','concat','-safe','1','-i',str(concat),'-fps_mode','vfr','-c:v','libx264','-pix_fmt','yuv420p',str(a.mp4)],check=True)
  result['derivative']='Camera-only MP4; original JPG/pose pairs retained. No AR or audio is fabricated.'
 if a.report:a.report.write_text(json.dumps(result,indent=2)+'\n')
 print(json.dumps({k:v for k,v in result.items() if k!='imageHashes'},indent=2))
if __name__=='__main__':main()

#!/usr/bin/env python3
"""Record chronological native frames while moving the real monitor stimulus over CDP."""
import argparse,json,time,urllib.request,pathlib,websocket
p=argparse.ArgumentParser();p.add_argument('--output',required=True);p.add_argument('--camera',default='http://127.0.0.1:18871');p.add_argument('--cdp',default='http://127.0.0.1:19287');a=p.parse_args()
out=pathlib.Path(a.output);frames=out/'frames';frames.mkdir(parents=True,exist_ok=True)
def get(url):return urllib.request.urlopen(url,timeout=3).read()
target=next(x for x in json.loads(get(a.cdp+'/json/list')) if x.get('type')=='page' and 'presenter.html' in x.get('url',''))
ws=websocket.create_connection(target['webSocketDebuggerUrl'].replace('127.0.0.1:9287','127.0.0.1:19287'),suppress_origin=True,timeout=4);ident=0
def evaluate(s):
 global ident
 ident+=1;ws.send(json.dumps({'id':ident,'method':'Runtime.evaluate','params':{'expression':s,'returnByValue':True}}))
 while True:
  r=json.loads(ws.recv())
  if r.get('id')==ident:return r
# Entire target should fit the real camera's monitor crop.
evaluate("document.querySelector('#target').style.height='67vh';document.querySelector('#target').style.top='19vh';window.stage('baseline')")
time.sleep(2)
stages=[('baseline',5),('left',5),('right',5),('rotate',5),('short-gap',4),('hidden',2),('baseline',6)]
records=[];events=[];start=time.monotonic();n=0
for name,duration in stages:
 expression="window.stage(%s)"%json.dumps(name if name!='short-gap' else 'baseline')
 if name=='short-gap':expression="window.stage('hidden');setTimeout(()=>window.stage('baseline'),300);({shortGapMs:300})"
 result=evaluate(expression);events.append({'stage':name,'elapsed':time.monotonic()-start,'cdpResult':result});print('stage',name,flush=True)
 stage_start=time.monotonic()
 while time.monotonic()-stage_start<duration:
  tick=time.monotonic()
  try:
   data=get(a.camera+'/frame.jpg');status=json.loads(get(a.camera+'/status'))
   if not data.startswith(b'\xff\xd8'):raise RuntimeError('no actual JPEG frame')
   namefile=f'frame-{n:05d}.jpg';(frames/namefile).write_bytes(data)
   records.append({'index':n,'file':namefile,'elapsed':time.monotonic()-start,'stage':name,'status':status});n+=1
  except Exception as e:records.append({'elapsed':time.monotonic()-start,'stage':name,'error':str(e)})
  time.sleep(max(0,.125-(time.monotonic()-tick)))
evaluate("window.stage('baseline')");ws.close()
(out/'capture.json').write_text(json.dumps({'kind':'actual native Camera2 frame tap; not generated or simulated','requestedFps':8,'elapsed':time.monotonic()-start,'events':events,'records':records},indent=2))
print('frames',n,'seconds',time.monotonic()-start)

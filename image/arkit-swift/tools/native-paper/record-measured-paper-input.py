#!/usr/bin/env python3
"""Actual native AR renderer acceptance, run on the Mac owning the USB iPhone.

Uses public devicectl and USB HouseArrest to retrieve app-produced MP4/sidecars.
It does not inject poses, fabricate camera frames, dismiss protected OS dialogs,
control another Mac, or demonstrate touch/controller/stereo input. The separate
owned worksheet presenter reads an atomic state.json from --presenter-root.
"""
import argparse, asyncio, json, math, pathlib, re, subprocess, time

p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--device-id',required=True,help='devicectl device identifier')
p.add_argument('--usb-udid',required=True,help='Paired USB phone identifier')
p.add_argument('--presenter-root',required=True,type=pathlib.Path)
p.add_argument('--output',required=True,type=pathlib.Path)
p.add_argument('--marker-extent-metres',required=True,type=float,help='Actual opposite coded corner-center distance; do not assume window pixel width is physical calibration')
p.add_argument('--marker-width-points',type=float,default=600)
p.add_argument('--bundle',default='edu.colorado.paperlab.prototype')
p.add_argument('--inspect-3d',action='store_true',help='Authored model tilt; not camera/head movement')
p.add_argument('--seconds',type=float,default=40)
p.add_argument('--python-with-pymobiledevice',default='python3')
p.add_argument('--topic',type=int,choices=range(11),default=4)
p.add_argument('--worksheet',default='spring-id8.png')
a=p.parse_args()
if not math.isfinite(a.marker_extent_metres) or a.marker_extent_metres<=0 or not math.isfinite(a.marker_width_points) or a.marker_width_points<=0 or not math.isfinite(a.seconds) or not 35<=a.seconds<=50:p.error('Require a positive finite measured extent/width and35–50s for this bounded protocol')
a.output.mkdir(parents=True,exist_ok=True)
state={'file':a.worksheet,'width':a.marker_width_points,'angle':0,'dx':0,'dy':0,'lesson':'','label':'Actual measured paper input acceptance'}
def write_state():
 file=a.presenter_root/'state.json';temp=file.with_suffix('.next.json');temp.write_text(json.dumps(state));temp.replace(file)
write_state();time.sleep(1)
cmd=['xcrun','devicectl','device','process','launch','--device',a.device_id,'--terminate-existing','--console',a.bundle,'--marker-bench','--marker-extent',str(a.marker_extent_metres),'--paper-topic',str(a.topic),'--paper-focus','--paper-view-record-seconds',str(a.seconds)]
if a.topic!=6:cmd+=['--paper-dial']
if a.inspect_3d:cmd+=['--paper-inspect-3d']
console=a.output/'console.log';events=[]
with console.open('w')as f:
 process=subprocess.Popen(cmd,stdout=f,stderr=subprocess.STDOUT);started=time.monotonic()
 try:
  # Spring: measured worksheet displacement pulls, return releases. Other
  # topics use the documented pure state mappings, not a synthetic pose.
  phases=[(8,'baseline',{}),(9,'paper-pull-or-first-parameter',{'dy':-90}),(9,'paper-release-or-return',{'dy':0}),(5,'disappear',{'width':0}),(11,'reappear',{'width':a.marker_width_points})]
  if a.topic!=4:phases=[(8,'baseline',{}),(8,'first-paper-parameter',{'angle':-45,'dy':-130}),(8,'second-paper-parameter',{'angle':45,'dy':130}),(5,'disappear',{'width':0}),(13,'reappear',{'angle':0,'dy':0,'width':a.marker_width_points})]
  for delay,name,changes in phases:
   state.update(changes);write_state();events.append({'phase':name,'wallUnix':time.time(),'relativeSeconds':time.monotonic()-started,'state':dict(state)});time.sleep(delay)
  deadline=time.monotonic()+20
  while time.monotonic()<deadline and'PAPER_AR_VIEW_VERIFIED_RECORD'not in console.read_text(errors='replace'):time.sleep(.5)
 finally:
  process.terminate()
  try:process.wait(timeout=3)
  except subprocess.TimeoutExpired:process.kill();process.wait()
(a.output/'phase-events.json').write_text(json.dumps({'topic':a.topic,'events':events,'input':'Scripted monitor transforms; actual live camera measurement; startup arguments are not human UI actions. Host file-write time is not physical display/camera latency.'},indent=2))
match=re.search(r'PAPER_AR_VIEW_VERIFIED_RECORD path=(\S+) frames=(\d+) duration=(\S+) status=(\S+)',console.read_text(errors='replace'))
if not match:raise SystemExit('Actual app recording not verified; preserve negative logs and investigate, do not claim success')
name=match.group(1)
# Separate interpreter allows the caller to use its existing pymobiledevice3 env.
retrieve='''import asyncio,pathlib,sys
from pymobiledevice3.lockdown import create_using_usbmux
from pymobiledevice3.services.house_arrest import HouseArrestService
async def main():
 l=await create_using_usbmux(serial=sys.argv[1])
 async with await HouseArrestService.create(l,sys.argv[2],documents_only=False)as app:
  for name in sys.argv[4:]:
   data=await app.get_file_contents('Documents/'+name);pathlib.Path(sys.argv[3],name).write_bytes(data)
 await l.close()
asyncio.run(main())
'''
subprocess.run([a.python_with_pymobiledevice,'-c',retrieve,a.usb_udid,a.bundle,str(a.output),name,name.replace('.mp4','.json')],check=True)
print(json.dumps({'movie':str(a.output/name),'frames':int(match.group(2)),'sourceSeconds':float(match.group(3)),'writerStatus':match.group(4),'limits':'Actual native mono AR view only, no SystemUI/audio/stereo/human-touch/printed-paper or general metric-accuracy claim.'},indent=2))

#!/usr/bin/env python3
"""Run downloaded exact common sensor projections on Android CPU, not camera acceptance."""
import argparse,json,pathlib,subprocess,shlex
p=argparse.ArgumentParser();p.add_argument('--adb',default='adb');p.add_argument('--fixtures',required=True,type=pathlib.Path);p.add_argument('--remote',default='/data/local/tmp/marker-native-20261009');a=p.parse_args()
root=pathlib.Path(__file__).resolve().parents[1];native=root/'Assets/MarkerLab/Plugins/Android/arm64-v8a'
subprocess.run([a.adb,'shell','mkdir','-p',a.remote+'/common-fixtures'],check=True)
for source in [root/'Builds/marker-driver',native/'libmarker_core.so',native/'libopencv_java4.so',native/'libc++_shared.so']:
 subprocess.run([a.adb,'push',str(source),a.remote+'/'],check=True,stdout=subprocess.DEVNULL)
subprocess.run([a.adb,'push',str(a.fixtures)+'/.',a.remote+'/common-fixtures/'],check=True,stdout=subprocess.DEVNULL)
subprocess.run([a.adb,'shell','chmod','755',a.remote+'/marker-driver'],check=True)
for item in json.loads((a.fixtures/'truth.json').read_text()):
 command='LD_LIBRARY_PATH='+shlex.quote(a.remote)+' '+shlex.join([a.remote+'/marker-driver',a.remote+'/common-fixtures/'+item['file'],a.remote+'/common-fixtures/board-'+str(item['id'])+'.cfg',str(item['mode'])])
 r=subprocess.run([a.adb,'shell',command],capture_output=True,text=True,check=True);item['native']=json.loads(r.stdout);print(json.dumps(item),flush=True)

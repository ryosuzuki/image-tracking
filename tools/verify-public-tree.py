#!/usr/bin/env python3
from pathlib import Path
import ast,json,re,subprocess,hashlib
root=Path(__file__).resolve().parents[1]
files=subprocess.check_output(['git','-C',str(root),'ls-files','-z']).decode().split('\0')
files=[p for p in files if p]
if not files:raise SystemExit('Stage source files before verifying the public tree')
fail=[];parsed={'json':0,'python':0,'shell':0};size=0
for rel in files:
 p=root/rel
 if p.is_symlink():fail.append((rel,'symlink'));continue
 data=p.read_bytes();size+=len(data)
 if any(part in {'node_modules','dist','Library','Temp','Builds','build','evidence','recordings','captures','logs'} for part in p.relative_to(root).parts):fail.append((rel,'generated/private path'))
 if p.suffix.lower() in {'.mp4','.mov','.webm','.p12','.pem','.key','.keystore','.jks','.mobileprovision','.task','.obj','.geom','.bytes','.so','.aar','.a','.usdz','.glb','.gltf'}:fail.append((rel,'excluded asset/credential/binary'))
 try:t=data.decode()
 except UnicodeDecodeError:
  if p.suffix.lower() not in {'.png'}:fail.append((rel,'unreviewed binary'))
  continue
 for label,pattern in [('home','/'+'Users/|/'+'Volumes/|'+r'\.ts\.net'),('credential',r'gh[pousr]_[A-Za-z0-9]{20,}|-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----|\bsk-[A-Za-z0-9_-]{30,}'),('serialized-secret',r'(?im)^\s*(?:accessToken|apiKey|vuforiaLicenseKey|ufoLicenseKey):[ \t]*[^\s\r\n][^\r\n]*$'),('private-network',r'\b(?:192\.168|100\.[0-9]{1,3}|10\.[0-9]{1,3})\.[0-9]{1,3}\.[0-9]{1,3}\b'),('device-id',r'\b0000[0-9A-Fa-f]{4}-[0-9A-Fa-f]{16}\b')]:
  if re.search(pattern,t):fail.append((rel,label))
 try:
  if p.suffix=='.json':json.loads(t);parsed['json']+=1
  if p.suffix=='.py':ast.parse(t);parsed['python']+=1
  if p.suffix=='.sh':
   result=subprocess.run(['bash','-n',str(p)],capture_output=True)
   if result.returncode:fail.append((rel,'shell syntax'))
   parsed['shell']+=1
 except Exception as ex:fail.append((rel,'parse: '+str(ex)))
for rel in ['image/8thwall-web/package-lock.json','markers/web-webxr/package-lock.json','image/arkit-swift/ios/PaperLab.xcodeproj/project.pbxproj','markers/arkit-swift/experiments/markerbench-ios/MarkerVision.mm','image/quest-native-opencv/AndroidManifest.xml','image/quest-unity-artoolkit/Packages/manifest.json','markers/unity-quest-ios/Packages/manifest.json','markers/unity-quest-ios/ios-unity/Packages/manifest.json']:
 if rel not in files:fail.append((rel,'missing independent build config'))
manifest_path=root/'public-source-hashes.json'
if manifest_path.exists():
 for row in json.loads(manifest_path.read_text())['files']:
  path=root/row['path']
  if not path.exists() or hashlib.sha256(path.read_bytes()).hexdigest()!=row['sha256']:fail.append((row['path'],'public digest mismatch'))
print(json.dumps({'files':len(files),'bytes':size,'parsed':parsed,'failures':fail},indent=2))
if fail:raise SystemExit(1)

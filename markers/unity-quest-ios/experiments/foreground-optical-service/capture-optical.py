import urllib.request,json,time,pathlib,sys,hashlib,base64
root=pathlib.Path(sys.argv[1]);root.mkdir(parents=True,exist_ok=True)
port=sys.argv[2] if len(sys.argv)>2 else '18879';duration=float(sys.argv[3]) if len(sys.argv)>3 else 30
start=time.time(); frames=[];last=-1
try:
 while time.time()-start<duration:
  try:
   packet=json.load(urllib.request.urlopen('http://127.0.0.1:'+port+'/snapshot'+('?raw=1' if len(frames)<4 else ''),timeout=3));status=packet.get('metadata',packet)
   t=time.time()-start
   if status.get('frames',0)>last:
    last=status['frames']; data=base64.b64decode(packet.get('jpegBase64',''))
    name='frame-%04d.jpg'%len(frames)
    if data:
     (root/name).write_bytes(data);row={'file':name,'seconds':t,'sha256':hashlib.sha256(data).hexdigest(),'status':status}
     if 'rgbaBase64'in packet:
      raw=base64.b64decode(packet['rgbaBase64']);rawname='sensor-%04d.rgba'%len(frames);(root/rawname).write_bytes(raw);row['rawFile']=rawname;row['rawSha256']=hashlib.sha256(raw).hexdigest()
     frames.append(row)
   if status.get('state','').startswith('ERROR'):print(json.dumps(status),flush=True);break
  except Exception as e:print('waiting',type(e).__name__,str(e)[:180],flush=True)
  time.sleep(.13)
finally:
 (root/'capture.json').write_text(json.dumps({'startUnix':start,'endUnix':time.time(),'frames':frames,'provenance':'Atomic live Quest Camera2 JPEG plus raw exposure timestamp and intrinsics. No head-world pose, stereo or controllers'},indent=2))
 print('captured',len(frames),flush=True)

import time,json,pathlib,urllib.request
root=pathlib.Path('/tmp/openclaw/quest-marker-stage')
phases=[('dots7','dots-7.png',600,0,False,9,.12),('aruco7','aruco-7.png',600,0,False,9,.12),('hidden','',600,0,False,4,.12),('aruco8','aruco-8.png',600,0,False,9,.12),('rotated-aruco8','aruco-8.png',600,20,False,9,.12),('dots7-return','dots-7.png',600,0,False,8,.12),('dots7-one-corner-covered','dots-7.png',600,0,True,5,.12),('dots7-restored','dots-7.png',600,0,False,5,.12),('dots8','dots-8.png',600,0,False,8,.12),('dots8-240mm','dots-8.png',1200,0,False,8,.24)]
start=time.time();events=[]
try:
 for name,file,width,angle,mask,duration,metric in phases:
  response=json.load(urllib.request.urlopen('http://127.0.0.1:18879/config?width='+str(metric),timeout=2))
  state={'file':file,'width':width,'angle':angle,'mask':mask,'label':name+' — physical monitor target, nominal extent '+str(int(metric*1000))+' mm'}
  tmp=root/'state.tmp';tmp.write_text(json.dumps(state));tmp.replace(root/'state.json')
  events.append({'phase':name,'wallUnix':time.time(),'state':state,'nominalExtentM':metric,'configResponse':response});(root/'events.json').write_text(json.dumps({'startUnix':start,'events':events},indent=2))
  print(name,flush=True);time.sleep(duration)
finally:
 (root/'protocol-complete.json').write_text(json.dumps({'completeWallUnix':time.time(),'phases':len(events)}))

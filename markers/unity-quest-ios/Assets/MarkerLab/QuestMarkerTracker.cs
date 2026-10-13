using System;using System.IO;using System.Collections;using System.Diagnostics;using System.Runtime.InteropServices;using UnityEngine;using UnityEngine.Android;using UnityEngine.Rendering;using Meta.XR.MRUtilityKit;using Meta.XR;using Debug=UnityEngine.Debug;
public sealed class QuestMarkerTracker:MonoBehaviour {
 [DllImport("marker_core")]static extern int ml_track_multi(byte[] image,int w,int h,double[] intrinsics,int mode,int[] ids,int markers,double bw,double bh,double[] dotXY,int[] dotColor,int count,float[] output);
 PassthroughCameraAccess access;MarkerBoard board;MarkerInteraction content;Transform target;byte[] rgba;float[] result=new float[34];double[] calibration=new double[4];readonly MeasuredTrackingAccess tracking=new MeasuredTrackingAccess();StreamWriter log;long lastStamp,minimumEpochMicroseconds;OVRDisplay observedDisplay;int mode=1,frames,lastID=-1;bool focused=true,paused,paperDialEnabled,hasPaperDialReference,readbackPending,destroyed;int generation;Pose paperDialReference;double next;string directory;readonly TeachingCapture capture=new TeachingCapture();TeachingMenu menu;
 IEnumerator Start(){
  OVRManager.TrackingOriginChangePending+=OriginChanging;observedDisplay=OVRManager.display;if(observedDisplay!=null)observedDisplay.RecenteredPose+=OriginReset;
  var config=Resources.Load<TextAsset>("marker-board");board=config?JsonUtility.FromJson<MarkerBoard>(config.text):new MarkerBoard();
  directory=Path.Combine(Application.persistentDataPath,"marker-"+DateTime.UtcNow.ToString("yyyyMMdd-HHmmss"));Directory.CreateDirectory(directory);log=new StreamWriter(Path.Combine(directory,"frames.jsonl"));
  var g=new GameObject("Metric marker");target=g.transform;content=g.AddComponent<MarkerInteraction>();g.SetActive(false);
  var rig=FindFirstObjectByType<OVRCameraRig>();var eye=rig?rig.centerEyeAnchor:(Camera.main?Camera.main.transform:null);
  menu=new GameObject("Lesson menu (head-relative UI)").AddComponent<TeachingMenu>();menu.Select=SelectLesson;menu.CaptureStatus=()=>capture.Status;menu.Initialize(eye);
  Permission.RequestUserPermission("horizonos.permission.HEADSET_CAMERA");yield return new WaitForSeconds(1);
  var c=new GameObject("Capture-time calibrated left camera");c.SetActive(false);access=c.AddComponent<PassthroughCameraAccess>();access.enabled=false;access.CameraPosition=PassthroughCameraAccess.CameraPositionType.Left;access.RequestedResolution=new Vector2Int(1280,1280);access.MaxFramerate=30;access.enabled=true;c.SetActive(true);
  while(!access.IsPlaying)yield return null;
  var res=access.CurrentResolution;rgba=new byte[res.x*res.y*4];var k=access.Intrinsics;calibration=MarkerCameraCalibration.Intrinsics(k.FocalLength.x,k.FocalLength.y,k.PrincipalPoint.x,k.PrincipalPoint.y,k.SensorResolution.x,k.SensorResolution.y,res.x,res.y);
  File.WriteAllText(Path.Combine(directory,"calibration.json"),JsonUtility.ToJson(new CalibrationRecord{width=res.x,height=res.y,intrinsics=calibration,offsetPosition=k.LensOffset.position,offsetRotation=k.LensOffset.rotation,sensorWidth=k.SensorResolution.x,sensorHeight=k.SensorResolution.y,calibrationRule="MRUK203 centered sensor crop by output aspect ratio, then uniform resize; raw row orientation not physically accepted",capture="MRUK203 GPU texture readback + PCA GetCameraPose snapshot at submission; UTC image timestamp, not XrTime; flipped top-left RGBA rows; physical alignment requires device acceptance",boardWidth=board.width,boardHeight=board.height},true));
  #if UNITY_ANDROID && !UNITY_EDITOR
  using(var player=new AndroidJavaClass("com.unity3d.player.UnityPlayer"))using(var activity=player.GetStatic<AndroidJavaObject>("currentActivity"))using(var intent=activity.Call<AndroidJavaObject>("getIntent")){int seconds=intent.Call<int>("getIntExtra","captureSeconds",0);if(seconds>0)capture.Start(Application.persistentDataPath,Path.Combine(directory,"calibration.json"),seconds);}
  #endif
  Debug.Log("MARKER READY directory="+directory+" resolution="+res+" K="+string.Join(",",calibration));
 }
 [Serializable]class CalibrationRecord{public int width,height,sensorWidth,sensorHeight;public string calibrationRule;public double[] intrinsics;public Vector3 offsetPosition;public Quaternion offsetRotation;public string capture;public float boardWidth,boardHeight;}
 [Serializable]class FrameRecord{public int sequence,mode,detectorPreset,id,status,decodedCorners,observedDots;public string application;public float simulationTime,primaryParameter,secondaryParameter;public bool hmdPresent,headTracked,cameraPlaying,targetVisible;public float[] observedCornerFlags;public long epochMicroseconds,imageTimestampNanoseconds;public double processMs,frameAgeSeconds;public float reprojection;public Vector3 sensorPosition,worldPosition;public Quaternion sensorRotation,worldRotation;public float[] corners;public bool controlsAllowed,playing,sessionReliable,capturePoseValid;public float speed,scale;}
 void Update(){
  capture.Tick();if(OVRInput.GetDown(OVRInput.Button.SecondaryThumbstick)){if(capture.Recording)capture.Stop();else capture.Start(Application.persistentDataPath,Path.Combine(directory,"calibration.json"));}if(menu)menu.Poll();
  double now=Time.realtimeSinceStartupAsDouble;tracking.SetReliable(focused&&!paused&&OVRManager.isHmdPresent&&OVRPlugin.positionTracked&&access&&access.IsPlaying);Presentation(now);
  if(OVRInput.GetDown(OVRInput.Button.Three)){mode=1-mode;generation++;tracking.BeginSelection();Debug.Log("MARKER BACKEND "+mode);}
  if(tracking.Interactive(now)&&(!menu||!menu.ConsumedInput)){if(OVRInput.GetDown(OVRInput.Button.PrimaryHandTrigger)){paperDialEnabled=!paperDialEnabled;paperDialReference=new Pose(target.position,target.rotation);hasPaperDialReference=paperDialEnabled;Debug.Log("PAPER DIAL MODE enabled="+paperDialEnabled+" source=fresh-measured-world-marker");}if(OVRInput.GetDown(OVRInput.Button.Four)){content.NextApplication();paperDialReference=new Pose(target.position,target.rotation);hasPaperDialReference=paperDialEnabled;}if(OVRInput.GetDown(OVRInput.Button.One))content.Toggle();if(OVRInput.GetDown(OVRInput.Button.Two))content.Reset();if(OVRInput.GetDown(OVRInput.Button.PrimaryThumbstick))content.Explode();if(!paperDialEnabled)content.Axes(OVRInput.Get(OVRInput.Axis2D.PrimaryThumbstick),OVRInput.Get(OVRInput.Axis2D.SecondaryThumbstick),Time.deltaTime);}
  if(!access||!access.IsPlaying||rgba==null||now<next)return;next=now+.06;
  if(readbackPending||!access.IsUpdatedThisFrame)return;
  var texture=access.GetTexture();if(!texture)return;
  long epoch=(access.Timestamp.ToUniversalTime().Ticks-DateTime.UnixEpoch.Ticks)/10;
  long stamp=epoch*1000; // UTC nanoseconds, not an OpenXR monotonic timestamp.
  if(!MarkerCameraCalibration.AcceptTimestamp(epoch,stamp,lastStamp,minimumEpochMicroseconds))return;
  var sensor=access.GetCameraPose();var size=access.CurrentResolution;int requestGeneration=generation;
  bool poseValid=MarkerCameraCalibration.ValidPose(sensor.position.x,sensor.position.y,sensor.position.z,sensor.rotation.x,sensor.rotation.y,sensor.rotation.z,sensor.rotation.w);
  readbackPending=true;
  AsyncGPUReadback.Request(texture,0,TextureFormat.RGBA32,request=>{
   readbackPending=false;
   if(destroyed||paused||!focused||requestGeneration!=generation)return;
   if(request.hasError){Debug.LogWarning("MARKER GPU readback failed");return;}
   var pixels=request.GetData<byte>();if(pixels.Length!=rgba.Length)return;
   for(int y=0;y<size.y;y++)for(int x=0;x<size.x*4;x++)rgba[y*size.x*4+x]=pixels[(size.y-1-y)*size.x*4+x];
   lastStamp=stamp;ProcessFrame(epoch,stamp,sensor,poseValid);
  });
 }
 void SelectLesson(PaperApplication kind){generation++;tracking.BeginSelection();hasPaperDialReference=false;content.SetApplicationForSelection(kind);target.gameObject.SetActive(false);content.active=false;Debug.Log("TEACHING MENU selected="+kind+" require=fresh-observation");}
 void ProcessFrame(long epoch,long stamp,Pose sensor,bool capturePoseValid){
  int id=mode==0?board.aruco_id:board.dot_id;var clock=Stopwatch.StartNew();int status=ml_track_multi(rgba,access.CurrentResolution.x,access.CurrentResolution.y,calibration,mode==1?2:0,board.ids,board.ids.Length,board.width,board.height,board.dot_xy,board.dot_colors,board.dot_xy.Length/2,result);clock.Stop();double frameAge=((DateTime.UtcNow.Ticks-DateTime.UnixEpoch.Ticks)/10000000.0)-epoch/1000000.0;bool seen=capturePoseValid&&status==1&&frameAge>=-.01&&frameAge<MeasuredTrackingAccess.InputSeconds;
  var world=new Pose();if(seen){id=(int)result[0];if(id!=lastID){lastID=id;tracking.BeginSelection();content.ResetForSelection();hasPaperDialReference=false;}world=MarkerPoseMath.World(sensor,result);if(!MarkerCameraCalibration.ValidPose(world.position.x,world.position.y,world.position.z,world.rotation.x,world.rotation.y,world.rotation.z,world.rotation.w))seen=false;else target.SetPositionAndRotation(world.position,world.rotation);}
  tracking.Observe(tracking.Epoch,Time.realtimeSinceStartupAsDouble-Math.Max(0,frameAge),seen);Presentation(Time.realtimeSinceStartupAsDouble);
  if(paperDialEnabled&&seen&&content.active&&content.playing){if(!hasPaperDialReference){paperDialReference=world;hasPaperDialReference=true;}else{var rotation=Quaternion.Inverse(paperDialReference.rotation)*world.rotation;var axis=rotation*Vector3.right;float angle=Mathf.Atan2(axis.y,axis.x);var translation=Quaternion.Inverse(paperDialReference.rotation)*(world.position-paperDialReference.position);if(content.ApplyPaperDial(angle,translation)&&frames%5==0)Debug.Log("PAPER DIAL MEASURED radians="+angle+" localMetres="+translation+" source=fresh-same-exposure-world-marker");}}
  var corners=new float[8];Array.Copy(result,18,corners,0,8);var flags=new float[4];Array.Copy(result,28,flags,0,4);var record=new FrameRecord{application=content.ApplicationKind.ToString(),simulationTime=content.SimulationTime,primaryParameter=content.PrimaryParameter,secondaryParameter=content.SecondaryParameter,hmdPresent=OVRManager.isHmdPresent,headTracked=OVRPlugin.positionTracked,cameraPlaying=access&&access.IsPlaying,targetVisible=target.gameObject.activeSelf,sequence=frames++,mode=mode,detectorPreset=mode==1?2:0,id=seen?id:-1,status=status,decodedCorners=seen?(int)result[26]:0,observedDots=seen?(int)result[27]:0,observedCornerFlags=seen?flags:null,epochMicroseconds=epoch,imageTimestampNanoseconds=stamp,processMs=clock.Elapsed.TotalMilliseconds,frameAgeSeconds=frameAge,reprojection=seen?result[1]:-1,sensorPosition=sensor.position,sensorRotation=sensor.rotation,worldPosition=world.position,worldRotation=world.rotation,corners=seen?corners:null,sessionReliable=tracking.Reliable,capturePoseValid=capturePoseValid,controlsAllowed=tracking.Interactive(Time.realtimeSinceStartupAsDouble),playing=content.playing,speed=content.speed,scale=content.scale};string recordJson=JsonUtility.ToJson(record);log.WriteLine(recordJson);log.Flush();capture.Frame(rgba,access.CurrentResolution.x,access.CurrentResolution.y,recordJson);
  // Teaching baseline writes numeric telemetry only; no automatic raw room-image capture.

  if(frames%10==0)Debug.Log("MARKER FRAME mode="+mode+" status="+status+" reprojection="+result[1]+" ms="+clock.Elapsed.TotalMilliseconds+" world="+world.position);
 }
 void Presentation(double now){if(!target)return;target.gameObject.SetActive(tracking.Visible(now));content.active=tracking.Interactive(now);content.Status((mode==0?"ArUco 4x4-50":"Colored dots (Quest dim-LCD preset)")+" ID "+lastID+"\n"+(content.active?"Fresh image pose":"Hold: inputs frozen")+" · X tracker\nA pause · B reset · Y next application\nleft grip: paper dial / buttons\nstick click action · sticks rotate/scale/parameters");}
 void OnApplicationFocus(bool v){focused=v;if(!v){capture.Stop();generation++;tracking.Invalidate();}}
 void OnApplicationPause(bool v){paused=v;if(v){capture.Stop();generation++;tracking.Invalidate();}}
 void OriginChanging(OVRManager.TrackingOrigin origin,OVRPose? previous){OriginReset();}
 void OriginReset(){capture.Stop();generation++;tracking.BeginSelection();hasPaperDialReference=false;minimumEpochMicroseconds=(DateTime.UtcNow.Ticks-DateTime.UnixEpoch.Ticks)/10;Debug.Log("MARKER ORIGIN invalidated; require newer image epoch="+minimumEpochMicroseconds);}
 void OnDestroy(){capture.Dispose();destroyed=true;generation++;OVRManager.TrackingOriginChangePending-=OriginChanging;if(observedDisplay!=null)observedDisplay.RecenteredPose-=OriginReset;log?.Dispose();}
}

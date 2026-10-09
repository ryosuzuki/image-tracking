using System;
using System.IO;
using System.Collections;
using System.Runtime.InteropServices;
using UnityEngine;
using Meta.XR.MRUtilityKit;
using Meta.XR;
using UnityEngine.Android;

public class DedicatedImageTracker : MonoBehaviour {
 const string Lib="ARX";
 [DllImport(Lib)] static extern bool arwInitialiseAR();
 [DllImport(Lib)] static extern bool arwStartRunningB(string conf, byte[] calib,int len);
 [DllImport(Lib)] static extern int arwVideoPushInit(int idx,int w,int h,string fmt,int camera,int pos);
 [DllImport(Lib)] static extern int arwVideoPush(int idx,byte[] p,int size,int stride,int row,IntPtr p1,int s1,int ps1,int rs1,IntPtr p2,int s2,int ps2,int rs2,IntPtr p3,int s3,int ps3,int rs3,IntPtr cb,IntPtr data);
 [DllImport(Lib)] static extern int arwAddTrackable(string cfg);
 [DllImport(Lib)] static extern bool arwRemoveTrackable(int id);
 [DllImport(Lib)] static extern bool arwCapture();
 [DllImport(Lib)] static extern bool arwUpdateAR();
 [DllImport(Lib)] static extern bool arwQueryTrackableVisibilityAndTransformation(int id,float[] m);
 [DllImport(Lib)] static extern bool arwStopRunning();
 [DllImport(Lib)] static extern bool arwShutdownAR();
 PassthroughCameraAccess access; Transform target,model; int uid=-1; byte[] rgba; float[] matrix=new float[16]; bool ready; double next; readonly MeasuredTrackingAccess tracking=new MeasuredTrackingAccess();bool focused=true,paused,initialised,running;string sensorFrame; string status="Starting dedicated ARToolKitX planar tracker";
 CatalogManifest catalog;CatalogScene content;int selected;bool switching;
 IEnumerator Select(int index){
  int epoch=tracking.BeginSelection();switching=true;ready=false;if(content)content.SetTrackingAvailable(false);target.gameObject.SetActive(false);if(uid>=0)arwRemoveTrackable(uid);uid=-1;
  selected=(index+catalog.items.Length)%catalog.items.Length;var item=catalog.items[selected];
  string targetFile=string.IsNullOrEmpty(item.target_file)?item.id+".jpg":item.target_file;
  var req=UnityEngine.Networking.UnityWebRequest.Get(Application.streamingAssetsPath+"/catalog/"+targetFile);yield return req.SendWebRequest();if(epoch!=tracking.Epoch)yield break;
  if(req.result!=UnityEngine.Networking.UnityWebRequest.Result.Success){Debug.LogError("Missing target "+item.id+" "+req.error);switching=false;yield break;}
  string path=Path.Combine(Application.persistentDataPath,targetFile);File.WriteAllBytes(path,req.downloadHandler.data);
  uid=arwAddTrackable("2d;"+path+";"+(item.width*1000).ToString(System.Globalization.CultureInfo.InvariantCulture));
  if(content)Destroy(content.gameObject);var go=new GameObject(item.id);go.transform.SetParent(target,false);content=go.AddComponent<CatalogScene>();content.Configure(item);content.SetTrackingAvailable(false);ready=uid>=0;switching=false;
  Debug.Log("DEDICATED CATALOG id="+item.id+" uid="+uid+" scene="+item.animation);
 }
 void Controls(){
  if(!content||switching)return;
  // Catalog navigation remains usable while searching, but old-page controls do not.
  if(OVRInput.GetDown(OVRInput.Button.Three)){StartCoroutine(Select(selected-1));return;}
  if(OVRInput.GetDown(OVRInput.Button.Four)){StartCoroutine(Select(selected+1));return;}
  if(!tracking.Interactive(Time.realtimeSinceStartupAsDouble))return;
  if(OVRInput.GetDown(OVRInput.Button.One))content.Tap();
  if(OVRInput.GetDown(OVRInput.Button.PrimaryThumbstick))content.Spring();
  if(OVRInput.GetDown(OVRInput.Button.Two)){content.Reset();Debug.Log("CATALOG actual OVR reset "+content.item.id);}
  content.ControlAxes(OVRInput.Get(OVRInput.Axis2D.PrimaryThumbstick),OVRInput.Get(OVRInput.Axis2D.SecondaryThumbstick),Time.deltaTime);
 }
 void Presentation(){double now=Time.realtimeSinceStartupAsDouble;if(target)target.gameObject.SetActive(ready&&tracking.Visible(now));if(content)content.SetTrackingAvailable(ready&&tracking.Interactive(now));}
 void InvalidateTracking(){tracking.Invalidate();Presentation();}
 void OnApplicationPause(bool value){paused=value;if(value)InvalidateTracking();}
 void OnApplicationFocus(bool value){focused=value;if(!value)InvalidateTracking();}
 IEnumerator Start(){
  Permission.RequestUserPermission("horizonos.permission.HEADSET_CAMERA");
  yield return new WaitForSeconds(1);
  var cameraNode=new GameObject("Square camera source");cameraNode.SetActive(false);access=cameraNode.AddComponent<PassthroughCameraAccess>(); access.CameraPosition=PassthroughCameraAccess.CameraPositionType.Left;access.RequestedResolution=new Vector2Int(1280,1280);access.MaxFramerate=30;cameraNode.SetActive(true);
  var t=new GameObject("Measured image target");target=t.transform;
  catalog=JsonUtility.FromJson<CatalogManifest>(Resources.Load<TextAsset>("Catalog/manifest").text);target.gameObject.SetActive(false);
  while(!access.IsPlaying)yield return null;
  initialised=arwInitialiseAR();Debug.Log("DEDICATED init="+initialised);if(!initialised)yield break;
  var res=access.CurrentResolution;var k=access.Intrinsics;
  var sensor=k.SensorResolution;double sx=(double)res.x/sensor.x, sy=(double)res.y/sensor.y;
  byte[] calib=Calibration(res.x,res.y,k.FocalLength.x*sx,k.FocalLength.y*sy,k.PrincipalPoint.x*sx,k.PrincipalPoint.y*sy);
  running=arwStartRunningB("-module=External -cachedir="+Application.persistentDataPath+" -cacheinitdir="+Application.persistentDataPath,calib,calib.Length);Debug.Log("DEDICATED start="+running);if(!running)yield break;
  int pushInit=arwVideoPushInit(0,res.x,res.y,"RGBA",0,0);Debug.Log("DEDICATED pushinit="+pushInit);if(pushInit<0)yield break;
  rgba=new byte[res.x*res.y*4];yield return Select(0);
 }
 static byte[] Calibration(int w,int h,double fx,double fy,double cx,double cy){
  using(var m=new MemoryStream()){Action<byte[]> be=b=>{if(BitConverter.IsLittleEndian)Array.Reverse(b);m.Write(b,0,b.Length);};be(BitConverter.GetBytes(w));be(BitConverter.GetBytes(h));foreach(double d in new[]{fx,0,cx,0,0,fy,cy,0,0,0,1,0,cx,cy,0,1})be(BitConverter.GetBytes(d));return m.ToArray();}
 }
 void Update(){
  tracking.SetReliable(focused&&!paused&&OVRManager.isHmdPresent&&OVRPlugin.positionTracked&&access&&access.IsPlaying);Presentation();
  if(!ready||!tracking.Reliable||!access.IsUpdatedThisFrame||Time.realtimeSinceStartupAsDouble<next){Controls();return;}next=Time.realtimeSinceStartupAsDouble+.08;
  var pose=access.GetCameraPose();var ts=access.Timestamp;var colors=access.GetColors();int w=access.CurrentResolution.x,h=access.CurrentResolution.y;
  string frameKey=ts.ToString("O");if(!colors.IsCreated||frameKey==sensorFrame){Controls();return;}sensorFrame=frameKey;int epoch=tracking.Epoch;
  // GPU textures are bottom-left origin; ARToolKitX consumes top-left rows.
  for(int y=0;y<h;y++)for(int x=0;x<w;x++){Color32 c=colors[(h-1-y)*w+x];int i=(y*w+x)*4;rgba[i]=c.r;rgba[i+1]=c.g;rgba[i+2]=c.b;rgba[i+3]=c.a;}
  int pushed=arwVideoPush(0,rgba,rgba.Length,4,w*4,IntPtr.Zero,0,0,0,IntPtr.Zero,0,0,0,IntPtr.Zero,0,0,0,IntPtr.Zero,IntPtr.Zero);
  bool captured=arwCapture();bool updated=captured&&arwUpdateAR();bool seen=pushed>=0&&updated&&arwQueryTrackableVisibilityAndTransformation(uid,matrix);if(seen){foreach(float value in matrix)if(!float.IsFinite(value)){seen=false;break;}}
  if(seen&&tracking.Reliable){
   var m=new Matrix4x4();for(int c=0;c<4;c++)for(int r=0;r<4;r++)m[r,c]=matrix[c*4+r]*(r==2?-1:1)*(c==2?-1:1);
   var camToWorld=Matrix4x4.TRS(pose.position,pose.rotation,Vector3.one);var localPos=(Vector3)m.GetColumn(3)*.001f;
   target.position=camToWorld.MultiplyPoint3x4(localPos);target.rotation=pose.rotation*m.rotation;
   Debug.Log("DEDICATED TRACK timestamp="+ts.ToString("O")+" position="+target.position+" push="+pushed);
  }
  tracking.Observe(epoch,Time.realtimeSinceStartupAsDouble,seen);Presentation();Controls();
  
  status=tracking.Interactive(Time.realtimeSinceStartupAsDouble)?"ARToolKitX image tracked · Stereo MR":tracking.Visible(Time.realtimeSinceStartupAsDouble)?"Short loss: bounded last world pose":"Searching image · Camera 1280 square";
 }
 void OnDestroy(){if(running)arwStopRunning();if(initialised)arwShutdownAR();}
}

#if PAPER_CAMERA_TEST
using System;
public static class MarkerCameraCalibrationChecks
{
 static int count;
 static void Check(bool ok,string name){count++;if(!ok)throw new Exception(name);}
 static void Near(double a,double b,string name){Check(Math.Abs(a-b)<1e-9,name+": "+a+" != "+b);}
 public static void Main(){
  foreach(var scenario in new[]{new[]{1920,1080,1280,1280},new[]{1280,1280,1280,960},new[]{1920,1080,960,540},new[]{1280,960,1280,1280}}){
   int sw=scenario[0],sh=scenario[1],w=scenario[2],h=scenario[3];double fx=1450,fy=1430,cx=sw*.539,cy=sh*.47;
   var k=MarkerCameraCalibration.Intrinsics(fx,fy,cx,cy,sw,sh,w,h);
   // Independent rectangle geometry: crop the long dimension to requested aspect ratio.
   double cw=sw,ch=sh;if(sw/(double)sh>w/(double)h)cw=sh*w/(double)h;else ch=sw*h/(double)w;
   double cropX=(sw-cw)/2,cropY=(sh-ch)/2;
   foreach(var point in new[]{new[]{.12,-.07,.8},new[]{-.05,.09,.5},new[]{0.0,0.0,1.0}}){
    Near(k[0]*point[0]/point[2]+k[2],(fx*point[0]/point[2]+cx-cropX)*w/cw,"offcentre crop x");
    Near(k[1]*point[1]/point[2]+k[3],(fy*point[1]/point[2]+cy-cropY)*h/ch,"offcentre crop y");
   }
  }
  var same=MarkerCameraCalibration.Intrinsics(900,880,612,489,1280,960,1280,960);Near(same[0],900,"uncropped fx");Near(same[1],880,"uncropped fy");Near(same[2],612,"uncropped cx");Near(same[3],489,"uncropped cy");
  bool invalid=false;try{MarkerCameraCalibration.Intrinsics(900,880,612,489,0,960,1280,960);}catch(ArgumentOutOfRangeException){invalid=true;}Check(invalid,"zero sensor dimension rejected");
  invalid=false;try{MarkerCameraCalibration.Intrinsics(double.NaN,880,612,489,1280,960,1280,960);}catch(ArgumentOutOfRangeException){invalid=true;}Check(invalid,"nonfinite intrinsics rejected");
  Check(MarkerCameraCalibration.AcceptTimestamp(200,300,299,199),"new associated timestamp accepted");
  Check(!MarkerCameraCalibration.AcceptTimestamp(0,300,299,0),"zero epoch rejected");Check(!MarkerCameraCalibration.AcceptTimestamp(200,0,0,0),"zero XrTime rejected");
  Check(!MarkerCameraCalibration.AcceptTimestamp(200,300,300,0),"duplicate image timestamp rejected");Check(!MarkerCameraCalibration.AcceptTimestamp(200,299,300,0),"out of order image rejected");
  Check(!MarkerCameraCalibration.AcceptTimestamp(198,300,299,199),"pre origin-reset exposure rejected");
  Check(MarkerCameraCalibration.ValidPose(1,2,3,0,0,0,1),"unit capture pose valid");
  Check(MarkerCameraCalibration.ValidPose(1,2,3,.5,.5,.5,.5),"nonidentity unit capture pose valid");
  Check(!MarkerCameraCalibration.ValidPose(1,2,3,0,0,0,0),"zero quaternion rejected");Check(!MarkerCameraCalibration.ValidPose(1,2,3,0,0,0,2),"nonunit quaternion rejected");
  Check(!MarkerCameraCalibration.ValidPose(double.NaN,2,3,0,0,0,1),"nonfinite sensor position rejected");Check(!MarkerCameraCalibration.ValidPose(1,2,3,0,0,double.PositiveInfinity,1),"nonfinite sensor quaternion rejected");
  Console.WriteLine("PASS "+count+" camera calibration/timestamp/pose checks; numeric source fixtures, not device accuracy");
 }
}
#endif

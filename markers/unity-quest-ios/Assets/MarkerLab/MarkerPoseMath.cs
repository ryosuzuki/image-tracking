using UnityEngine;
public static class MarkerPoseMath {
 // OpenCV camera and board are right-handed, x right/y down/z forward.
 // Unity camera and board are left-handed, x right/y up/z forward. Reflect BOTH bases.
 public static Matrix4x4 CvToUnity(float[] result){var m=Matrix4x4.identity;for(int c=0;c<4;c++)for(int r=0;r<4;r++)m[r,c]=result[2+c*4+r]*(r==1?-1:1)*(c==1?-1:1);return m;}
 public static Pose World(Pose exposureSensor,float[] result){var m=CvToUnity(result);return new Pose(exposureSensor.position+exposureSensor.rotation*(Vector3)m.GetColumn(3),exposureSensor.rotation*m.rotation);}
}

#if UNITY_EDITOR && UNITY_IOS
using System;
using System.Reflection;
using UnityEngine;
public static class IOSPaperControlChecks
{
    public static void Run()
    {
        int count = 0;
        Action<bool,string> check = (ok, title) => { if (!ok) throw new Exception(title); count++; };
        var flags = BindingFlags.Static | BindingFlags.NonPublic;
        var ranges = typeof(IOSMarkerTracker).GetMethod("Ranges", flags);
        var pose = typeof(IOSMarkerTracker).GetMethod("ValidPose", flags);
        var action = typeof(IOSMarkerTracker).GetMethod("ActionTitle", flags);
        check(ranges != null && pose != null && action != null,"Actual iOS control API reflection");
        float[,] expected = { { .5f,1.4f,0,45 },{ 0,1,0,1 },{ .1f,2,.5f,4 },{ 5,65,0,.8f },{ .2f,1.2f,5,25 },{ 1,12,10,1000 },{ -180,180,.25f,2 },{ 0,1,0,8 } };
        foreach (PaperApplication app in Enum.GetValues(typeof(PaperApplication)))
        {
            object[] args = { app,0f,0f,0f,0f,null,null }; ranges.Invoke(null,args);
            for(int j=0;j<4;j++) check(Mathf.Abs((float)args[j+1]-expected[(int)app,j])<1e-6f,app+" control range "+j);
            check(!string.IsNullOrEmpty((string)args[5])&&!string.IsNullOrEmpty((string)args[6]),app+" semantic labels");
            check(!string.IsNullOrEmpty((string)action.Invoke(null,new object[]{app})),app+" action label");
        }
        check((bool)pose.Invoke(null,new object[]{new Pose(new Vector3(1,2,3),Quaternion.Euler(30,70,-50))}),"Valid rotated translated pose");
        check(!(bool)pose.Invoke(null,new object[]{new Pose(Vector3.zero,new Quaternion(0,0,0,0))}),"Zero pose quaternion rejected");
        check(!(bool)pose.Invoke(null,new object[]{new Pose(new Vector3(float.NaN,0,0),Quaternion.identity)}),"Nonfinite position rejected");
        check(!(bool)pose.Invoke(null,new object[]{new Pose(Vector3.zero,new Quaternion(0,0,0,2))}),"Nonunit quaternion rejected");
        check(!(bool)pose.Invoke(null,new object[]{new Pose(Vector3.zero,new Quaternion(float.PositiveInfinity,0,0,1))}),"Nonfinite quaternion rejected");
        Debug.Log("PASS "+count+" actual Unity iOS control-range/pose checks; source/editor only, not physical touch acceptance");
    }
}
#endif

#if UNITY_IOS
using UnityEditor;using UnityEditor.Callbacks;using UnityEditor.iOS.Xcode;
public static class MarkerIOSPostprocess {
 [PostProcessBuild(500)] public static void Run(BuildTarget target,string path){if(target!=BuildTarget.iOS)return;string p=PBXProject.GetPBXProjectPath(path);var project=new PBXProject();project.ReadFromFile(p);string framework=project.GetUnityFrameworkTargetGuid();foreach(var name in new[]{"ARKit.framework","Accelerate.framework","AVFoundation.framework","CoreVideo.framework","CoreMedia.framework","CoreGraphics.framework","CoreImage.framework","libc++.tbd","libz.tbd"})project.AddFrameworkToProject(framework,name,false);project.AddBuildProperty(framework,"OTHER_LDFLAGS","-lc++ -lz");project.WriteToFile(p);}
}
#endif

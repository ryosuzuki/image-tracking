#if UNITY_IOS
using UnityEditor;using UnityEditor.Callbacks;using UnityEditor.iOS.Xcode;
public static class MarkerIOSPostprocess {
 public static void RepairCurrentExport(){Run(BuildTarget.iOS,"Builds/ios-marker-lab");}
 [PostProcessBuild(500)] public static void Run(BuildTarget target,string path){if(target!=BuildTarget.iOS)return;string p=PBXProject.GetPBXProjectPath(path);var project=new PBXProject();project.ReadFromFile(p);string framework=project.GetUnityFrameworkTargetGuid();foreach(var name in new[]{"ARKit.framework","Accelerate.framework","AVFoundation.framework","CoreVideo.framework","CoreMedia.framework","CoreGraphics.framework","CoreImage.framework","libc++.tbd","libz.tbd"})project.AddFrameworkToProject(framework,name,false);project.AddBuildProperty(framework,"OTHER_LDFLAGS","-lc++ -lz");project.AddBuildProperty(framework,"LIBRARY_SEARCH_PATHS","$(DEVELOPER_DIR)/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift/$(PLATFORM_NAME)");project.SetBuildProperty(project.GetUnityMainTargetGuid(),"ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES","YES");project.WriteToFile(p);}
}
#endif

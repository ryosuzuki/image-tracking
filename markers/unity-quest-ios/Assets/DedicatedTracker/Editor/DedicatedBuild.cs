using System;
using System.IO;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEditor.Build.Reporting;
using UnityEngine;
public static class DedicatedBuild{
 public static void Android(){
  MeasuredTrackingValidation.Run();CatalogMathValidation.Run();SourcePartsValidation.Run();NextFourPartsValidation.Run();SourceDiagramPhysicsValidation.Run();
  if(!AssetDatabase.LoadAssetAtPath<Material>("Assets/DedicatedTracker/Resources/vertex-color.mat")){AssetDatabase.CreateAsset(new Material(Shader.Find("Dedicated/VertexColor")),"Assets/DedicatedTracker/Resources/vertex-color.mat");}
  var dev=AssetDatabase.LoadAssetAtPath<ScriptableObject>("Assets/Resources/DevAgentSettings.asset");if(dev){var so=new SerializedObject(dev);so.FindProperty("enabled").boolValue=false;so.FindProperty("accessToken").stringValue="";so.ApplyModifiedPropertiesWithoutUndo();AssetDatabase.SaveAssets();}
  var s=EditorSceneManager.NewScene(NewSceneSetup.EmptyScene);
  var guids=AssetDatabase.FindAssets("OVRCameraRig t:Prefab");if(guids.Length==0)throw new Exception("OVR rig unavailable");
  var rig=(GameObject)PrefabUtility.InstantiatePrefab(AssetDatabase.LoadAssetAtPath<GameObject>(AssetDatabase.GUIDToAssetPath(guids[0])));
  var manager=rig.GetComponent<OVRManager>();if(!manager)manager=rig.AddComponent<OVRManager>();manager.isInsightPassthroughEnabled=true;
  var layer=rig.AddComponent<OVRPassthroughLayer>();layer.overlayType=OVROverlay.OverlayType.Underlay;
  foreach(var c in rig.GetComponentsInChildren<Camera>()){c.clearFlags=CameraClearFlags.SolidColor;c.backgroundColor=new Color(0,0,0,0);c.nearClipPlane=.01f;}
  new GameObject("Dedicated ARToolKitX").AddComponent<DedicatedImageTracker>();
  var light=new GameObject("Lighting").AddComponent<Light>();light.type=LightType.Directional;light.transform.rotation=Quaternion.Euler(40,20,0);RenderSettings.ambientLight=Color.white;
  EditorSceneManager.SaveScene(s,"Assets/DedicatedTracker/DedicatedScene.unity");
  foreach(string f in new[]{"libARX.so"}){var p="Assets/DedicatedTracker/Plugins/Android/arm64-v8a/"+f;var pi=(PluginImporter)AssetImporter.GetAtPath(p);pi.SetCompatibleWithAnyPlatform(false);pi.SetCompatibleWithEditor(false);pi.SetCompatibleWithPlatform(BuildTarget.Android,true);pi.SetPlatformData(BuildTarget.Android,"CPU","ARM64");pi.SaveAndReimport();}
  PlayerSettings.productName="Dedicated Page Stereo";PlayerSettings.SetApplicationIdentifier(UnityEditor.Build.NamedBuildTarget.Android,"org.openclaw.dedicatedpagestereo");PlayerSettings.Android.bundleVersionCode=8;PlayerSettings.bundleVersion="0.8-measured-control-gates";
  PlayerSettings.SetScriptingBackend(UnityEditor.Build.NamedBuildTarget.Android,ScriptingImplementation.IL2CPP);PlayerSettings.Android.targetArchitectures=AndroidArchitecture.ARM64;PlayerSettings.Android.useCustomKeystore=false;PlayerSettings.allowUnsafeCode=true;
  var issues=new System.Collections.Generic.List<UnityEngine.XR.OpenXR.Features.OpenXRFeature.ValidationRule>();
  UnityEditor.XR.OpenXR.OpenXRProjectValidation.GetCurrentValidationIssues(issues,BuildTargetGroup.Android);foreach(var issue in issues){if(issue.fixIt!=null){Debug.Log("Fix OpenXR: "+issue.message);issue.fixIt();}}AssetDatabase.SaveAssets();
  Directory.CreateDirectory("Builds");var r=BuildPipeline.BuildPlayer(new[]{"Assets/DedicatedTracker/DedicatedScene.unity"},"Builds/dedicated-page-stereo.apk",BuildTarget.Android,BuildOptions.Development);
  if(r.summary.result!=BuildResult.Succeeded)throw new Exception("Build failed: "+r.summary.result);
 }
}

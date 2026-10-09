using System;using System.IO;using UnityEditor;using UnityEditor.SceneManagement;using UnityEditor.Build.Reporting;using UnityEngine;using UnityEditor.XR.Management;using UnityEditor.XR.Management.Metadata;using Unity.XR.CoreUtils;using UnityEngine.XR.ARFoundation;using UnityEngine.XR.Management;
public static class IOSBuild {
 public static void Prepare(){
  var target=UnityEditor.Build.NamedBuildTarget.iOS;
  var defines=new System.Collections.Generic.HashSet<string>(PlayerSettings.GetScriptingDefineSymbols(target).Split(';'));
  defines.Add("UNITY_XR_ARKIT_LOADER_ENABLED");
  PlayerSettings.SetScriptingDefineSymbols(target,string.Join(";",defines));
  PlayerSettings.stripEngineCode=false;
  var graphics=new SerializedObject(AssetDatabase.LoadAllAssetsAtPath("ProjectSettings/GraphicsSettings.asset")[0]);
  var shaders=graphics.FindProperty("m_AlwaysIncludedShaders");
  var surface=AssetDatabase.LoadAssetAtPath<Shader>("Assets/MarkerLab/MarkerSurface.shader");
  if(!surface)throw new Exception("Marker surface shader missing");
  bool found=false;for(int i=0;i<shaders.arraySize;i++)if(shaders.GetArrayElementAtIndex(i).objectReferenceValue==surface)found=true;
  if(!found){int index=shaders.arraySize;shaders.InsertArrayElementAtIndex(index);shaders.GetArrayElementAtIndex(index).objectReferenceValue=surface;graphics.ApplyModifiedPropertiesWithoutUndo();}
  AssetDatabase.SaveAssets();
  Debug.Log("Prepared ARKit provider define, primitive engine retention, explicit marker shader. Restart domain before Build.");
 }
 public static void Build(){
#if !UNITY_XR_ARKIT_LOADER_ENABLED
  throw new Exception("Run IOSBuild.Prepare in a separate Unity invocation before Build; native ARKit requires a compiled provider define.");
#endif
  Prepare();
  string settingsPath="Assets/XR/XRGeneralSettingsPerBuildTarget.asset";Directory.CreateDirectory("Assets/XR");var per=AssetDatabase.LoadAssetAtPath<XRGeneralSettingsPerBuildTarget>(settingsPath);if(!per){per=ScriptableObject.CreateInstance<XRGeneralSettingsPerBuildTarget>();AssetDatabase.CreateAsset(per,settingsPath);EditorBuildSettings.AddConfigObject("com.unity.xr.management.loader_settings",per,true);}if(!per.HasManagerSettingsForBuildTarget(BuildTargetGroup.iOS))per.CreateDefaultManagerSettingsForBuildTarget(BuildTargetGroup.iOS);var settings=per.SettingsForBuildTarget(BuildTargetGroup.iOS);settings.InitManagerOnStart=true;if(!XRPackageMetadataStore.AssignLoader(settings.Manager,"UnityEngine.XR.ARKit.ARKitLoader",BuildTargetGroup.iOS))throw new Exception("ARKit loader assignment failed");
  foreach(string guid in AssetDatabase.FindAssets("",new[]{"Assets/MarkerLab/Plugins"})){var importer=AssetImporter.GetAtPath(AssetDatabase.GUIDToAssetPath(guid)) as PluginImporter;if(!importer)continue;importer.SetCompatibleWithAnyPlatform(false);importer.SetCompatibleWithEditor(false);importer.SetCompatibleWithPlatform(BuildTarget.iOS,true);importer.SaveAndReimport();}
  var s=EditorSceneManager.NewScene(NewSceneSetup.EmptyScene);var origin=new GameObject("AR Origin").AddComponent<XROrigin>();origin.CameraYOffset=0;var c=new GameObject("AR Camera");c.tag="MainCamera";c.transform.SetParent(origin.transform,false);var camera=c.AddComponent<Camera>();camera.nearClipPlane=.01f;origin.Camera=camera;c.AddComponent<ARCameraManager>();c.AddComponent<ARCameraBackground>();var driver=c.AddComponent<UnityEngine.InputSystem.XR.TrackedPoseDriver>();driver.positionInput=new UnityEngine.InputSystem.InputActionProperty(new UnityEngine.InputSystem.InputAction("position",binding:"<XRHMD>/centerEyePosition"));driver.rotationInput=new UnityEngine.InputSystem.InputActionProperty(new UnityEngine.InputSystem.InputAction("rotation",binding:"<XRHMD>/centerEyeRotation"));var session=new GameObject("AR Session");session.AddComponent<ARSession>();session.AddComponent<ARInputManager>();new GameObject("Shared native dot / ArUco tracker").AddComponent<IOSMarkerTracker>();string scene="Assets/MarkerLab/IOSMarkerScene.unity";EditorSceneManager.SaveScene(s,scene);EditorBuildSettings.scenes=new[]{new EditorBuildSettingsScene(scene,true)};
  var serializedSettings=new SerializedObject(AssetDatabase.LoadAllAssetsAtPath("ProjectSettings/ProjectSettings.asset")[0]);serializedSettings.FindProperty("activeInputHandler").intValue=2;serializedSettings.ApplyModifiedPropertiesWithoutUndo();PlayerSettings.productName="Interactive Paper Lab";PlayerSettings.bundleVersion="0.11.0";PlayerSettings.iOS.buildNumber="11";PlayerSettings.SetApplicationIdentifier(UnityEditor.Build.NamedBuildTarget.iOS,"org.openclaw.markertrackinglab.ios");PlayerSettings.iOS.cameraUsageDescription="Recognize printed colored dots and ArUco markers for spatial 3D experiments.";PlayerSettings.iOS.targetOSVersionString="16.0";PlayerSettings.SetScriptingBackend(UnityEditor.Build.NamedBuildTarget.iOS,ScriptingImplementation.IL2CPP);AssetDatabase.SaveAssets();Directory.CreateDirectory("Builds");var report=BuildPipeline.BuildPlayer(new[]{scene},"Builds/ios-marker-lab",BuildTarget.iOS,BuildOptions.Development);if(report.summary.result!=BuildResult.Succeeded)throw new Exception("iOS marker export failed "+report.summary.result);
 }
}

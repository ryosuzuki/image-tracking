using System;
using System.IO;
using UnityEditor;
using UnityEditor.Build.Reporting;
using UnityEditor.SceneManagement;
using UnityEditor.XR.Management;
using UnityEditor.XR.Management.Metadata;
using UnityEditor.XR.OpenXR.Features;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.XR.Management;
using UnityEngine.XR.OpenXR;
using UnityEngine.XR.OpenXR.Features;
namespace MRClass.Editor
{
public static partial class ClassBuild
{
    public static void Deliver()
    {
        Verify();
        Android();
    }
    [MenuItem("Tools/MR Class/Create desktop preview scene")]
    public static void PreviewScene()
    {
        var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
        new GameObject("MR Class Lab").AddComponent<LabApp>();
        EditorSceneManager.SaveScene(scene, "Assets/ClassPreview.unity");
    }
    public static void Android()
    {
        if (!File.Exists("Assets/Plugins/Android/arm64-v8a/libmarker_core.so"))
            throw new Exception("Build shared marker plugin first; no dummy camera adapter");
        foreach (var id in AssetDatabase.FindAssets("", new[] { "Assets/Plugins" }))
        {
            string p = AssetDatabase.GUIDToAssetPath(id);
            if (AssetImporter.GetAtPath(p) is PluginImporter importer)
            {
                importer.SetCompatibleWithAnyPlatform(false);
                importer.SetCompatibleWithEditor(false);
                importer.SetCompatibleWithPlatform(BuildTarget.Android, true);
                importer.SetPlatformData(BuildTarget.Android, "CPU", "ARM64");
                importer.SaveAndReimport();
            }
        }
        GraphicsSettings.defaultRenderPipeline = null;
        QualitySettings.renderPipeline = null;
        var metaConfig = OVRProjectConfig.CachedProjectConfig;
        metaConfig.insightPassthroughSupport = OVRProjectConfig.FeatureSupport.Required;
        metaConfig.isPassthroughCameraAccessEnabled = true;
        OVRProjectConfig.CommitProjectConfig(metaConfig);
        PlayerSettings.companyName = "Ryo Suzuki";
        PlayerSettings.productName = "MR Class Lab";
        PlayerSettings.SetApplicationIdentifier(UnityEditor.Build.NamedBuildTarget.Android,
                                                "edu.colorado.mrclasslab");
        PlayerSettings.bundleVersion = "0.1.0";
        PlayerSettings.Android.bundleVersionCode = 1;
        PlayerSettings.SetScriptingBackend(UnityEditor.Build.NamedBuildTarget.Android,
                                           ScriptingImplementation.IL2CPP);
        PlayerSettings.Android.targetArchitectures = AndroidArchitecture.ARM64;
        PlayerSettings.Android.minSdkVersion = AndroidSdkVersions.AndroidApiLevel32;
        PlayerSettings.Android.targetSdkVersion = AndroidSdkVersions.AndroidApiLevelAuto;
        PlayerSettings.Android.useCustomKeystore = false;
        PlayerSettings.insecureHttpOption = InsecureHttpOption.AlwaysAllowed;
        PlayerSettings.colorSpace = ColorSpace.Linear;
        PlayerSettings.SetUseDefaultGraphicsAPIs(BuildTarget.Android, false);
        PlayerSettings.SetGraphicsAPIs(BuildTarget.Android, new[] { GraphicsDeviceType.OpenGLES3 });
        PlayerSettings.stereoRenderingPath = StereoRenderingPath.Instancing;
        var ps = new SerializedObject(
            AssetDatabase.LoadAllAssetsAtPath("ProjectSettings/ProjectSettings.asset")[0]);
        var input = ps.FindProperty("activeInputHandler");
        if (input != null)
        {
            input.intValue = 1;
            ps.ApplyModifiedPropertiesWithoutUndo();
        }
        var per = AssetDatabase.LoadAssetAtPath<XRGeneralSettingsPerBuildTarget>("Assets/ClassXR.asset");
        if (!per)
        {
            per = ScriptableObject.CreateInstance<XRGeneralSettingsPerBuildTarget>();
            AssetDatabase.CreateAsset(per, "Assets/ClassXR.asset");
        }
        var general = per.SettingsForBuildTarget(BuildTargetGroup.Android);
        if (!general)
        {
            general = ScriptableObject.CreateInstance<XRGeneralSettings>();
            AssetDatabase.AddObjectToAsset(general, per);
            per.SetSettingsForBuildTarget(BuildTargetGroup.Android, general);
        }
        if (!general.Manager)
        {
            general.Manager = ScriptableObject.CreateInstance<XRManagerSettings>();
            AssetDatabase.AddObjectToAsset(general.Manager, per);
        }
        general.InitManagerOnStart = true;
        EditorBuildSettings.AddConfigObject("com.unity.xr.management.loader_settings", per, true);
        if (!XRPackageMetadataStore.AssignLoader(general.Manager, "UnityEngine.XR.OpenXR.OpenXRLoader",
                                                 BuildTargetGroup.Android))
            throw new Exception("OpenXR loader missing");
        FeatureHelpers.RefreshFeatures(BuildTargetGroup.Android);
        var xr = OpenXRSettings.GetSettingsForBuildTargetGroup(BuildTargetGroup.Android);
        xr.renderMode = OpenXRSettings.RenderMode.SinglePassInstanced;
        foreach (var feature in xr.GetFeatures<OpenXRFeature>())
        {
            string type = feature.GetType().Name;
            if (type.Contains("OculusTouchControllerProfile") || type.Contains("MetaQuestFeature") ||
                type == "MetaXRFeature")
                feature.enabled = true;
        }
        if (!xr.GetFeature<Meta.XR.MetaXRFeature>() || !xr.GetFeature<Meta.XR.MetaXRFeature>().enabled)
            throw new Exception(
                "Meta XR OpenXR feature is required for OVR / passthrough and the single native loader");
        var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
        var guids = AssetDatabase.FindAssets("OVRCameraRig t:Prefab");
        if (guids.Length == 0)
            throw new Exception("Meta camera rig missing");
        var rig = (GameObject)PrefabUtility.InstantiatePrefab(
            AssetDatabase.LoadAssetAtPath<GameObject>(AssetDatabase.GUIDToAssetPath(guids[0])));
        var mgr = rig.GetComponent<OVRManager>();
        if (!mgr)
            mgr = rig.AddComponent<OVRManager>();
        mgr.isInsightPassthroughEnabled = true;
        var managerProperties = new SerializedObject(mgr);
        var cameraPermission =
            managerProperties.FindProperty("requestPassthroughCameraAccessPermissionOnStartup");
        if (cameraPermission == null)
            throw new Exception("SDK startup camera permission field changed");
        cameraPermission.boolValue = false;
        managerProperties.ApplyModifiedPropertiesWithoutUndo();
        mgr.trackingOriginType = OVRManager.TrackingOrigin.FloorLevel;
        var layer = rig.AddComponent<OVRPassthroughLayer>();
        layer.overlayType = OVROverlay.OverlayType.Underlay;
        foreach (var c in rig.GetComponentsInChildren<Camera>())
        {
            c.clearFlags = CameraClearFlags.SolidColor;
            c.backgroundColor = Color.clear;
            c.nearClipPlane = .02f;
        }
        new GameObject("Unified MR class").AddComponent<LabApp>();
        string scenePath = "Assets/Class.unity";
        EditorSceneManager.SaveScene(scene, scenePath);
        EditorBuildSettings.scenes = new[] { new EditorBuildSettingsScene(scenePath, true) };
        AssetDatabase.SaveAssets();
        string output = Environment.GetEnvironmentVariable("MR_CLASS_APK") ?? "Builds/mr-class-lab.apk";
        Directory.CreateDirectory(Path.GetDirectoryName(output));
        var report = BuildPipeline.BuildPlayer(new[] { scenePath }, output, BuildTarget.Android,
                                               BuildOptions.Development);
        Debug.Log("MR_CLASS_BUILD " + report.summary.result + " bytes=" + report.summary.totalSize);
        if (report.summary.result != BuildResult.Succeeded)
            throw new Exception("Android build failed");
    }
}
}

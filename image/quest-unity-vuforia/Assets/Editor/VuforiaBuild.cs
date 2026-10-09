using System;
using System.IO;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEditor.Build.Reporting;
using UnityEngine;
using UnityEngine.Rendering;
using Meta.XR;
using Vuforia;

public static class VuforiaBuild
{
    public static void Prepare()
    {
        var devSettings = AssetDatabase.LoadAssetAtPath<ScriptableObject>("Assets/Resources/DevAgentSettings.asset");
        if (devSettings)
        {
            var dev = new SerializedObject(devSettings);
            dev.FindProperty("enabled").boolValue = false;
            dev.FindProperty("accessToken").stringValue = "";
            dev.FindProperty("serverAddress").stringValue = "";
            dev.ApplyModifiedPropertiesWithoutUndo();
        }
        var questConfig = OVRProjectConfig.CachedProjectConfig;
        questConfig.handTrackingSupport = OVRProjectConfig.HandTrackingSupport.ControllersAndHands;
        OVRProjectConfig.CommitProjectConfig(questConfig);
        var config = VuforiaConfiguration.Instance;
        config.Vuforia.LicenseKey = "";
        config.Vuforia.DelayedInitialization = true;
        config.VideoBackground.VideoBackgroundEnabled = false;
        var configAsset = new SerializedObject(config);
        configAsset.FindProperty("deviceTracker.autoStartTracker").boolValue = false;
        configAsset.ApplyModifiedPropertiesWithoutUndo();
        var s = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene);
        var ids = AssetDatabase.FindAssets("OVRCameraRig t:Prefab");
        if (ids.Length == 0) throw new Exception("Meta camera rig missing");
        var rig = (GameObject)PrefabUtility.InstantiatePrefab(AssetDatabase.LoadAssetAtPath<GameObject>(AssetDatabase.GUIDToAssetPath(ids[0])));
        var manager = rig.GetComponent<OVRManager>();
        if (!manager) manager = rig.AddComponent<OVRManager>();
        manager.isInsightPassthroughEnabled = true;
        rig.AddComponent<OVRPassthroughLayer>().overlayType = OVROverlay.OverlayType.Underlay;
        foreach (var c in rig.GetComponentsInChildren<Camera>()) { c.clearFlags = CameraClearFlags.SolidColor; c.backgroundColor = Color.clear; }
        var camera = new GameObject("Vuforia physical camera anchor");
        camera.SetActive(false);
        var vc = camera.AddComponent<Camera>(); vc.enabled = false;
        camera.AddComponent<VuforiaBehaviour>();
        var provider = camera.AddComponent<MetaCameraProvider>();
        var capture = new GameObject("Left physical RGB camera"); capture.SetActive(false);
        var pca = capture.AddComponent<PassthroughCameraAccess>(); pca.enabled = false;
        var so = new SerializedObject(provider); so.FindProperty("cameraAccess").objectReferenceValue = pca; so.ApplyModifiedPropertiesWithoutUndo();
        camera.AddComponent<VuforiaCameraPoseDriver>();
        camera.AddComponent<QuestVuforiaDriverInit>();
        var imageImporter = (TextureImporter)AssetImporter.GetAtPath("Assets/Resources/paper-target.png");
        imageImporter.isReadable = true; imageImporter.textureCompression = TextureImporterCompression.Uncompressed; imageImporter.mipmapEnabled = false; imageImporter.SaveAndReimport();
        var target = camera.AddComponent<PaperTarget>();
        target.targetImage = AssetDatabase.LoadAssetAtPath<Texture2D>("Assets/Resources/paper-target.png");
        // Direct serialized material reference includes URP shader in the player build.
        var material = new Material(Shader.Find("Universal Render Pipeline/Unlit")); material.color = Color.cyan;
        if (!File.Exists("Assets/Resources/PaperSurface.mat")) AssetDatabase.CreateAsset(material, "Assets/Resources/PaperSurface.mat");
        target.surface = AssetDatabase.LoadAssetAtPath<Material>("Assets/Resources/PaperSurface.mat");
        camera.SetActive(true); capture.SetActive(true);
        EditorSceneManager.SaveScene(s, "Assets/QuestVuforia/PaperVuforiaScene.unity");
        EditorBuildSettings.scenes = new[] { new EditorBuildSettingsScene("Assets/QuestVuforia/PaperVuforiaScene.unity", true) };
        PlayerSettings.productName = "PaperLab Vuforia Prototype";
        PlayerSettings.SetApplicationIdentifier(UnityEditor.Build.NamedBuildTarget.Android, "org.openclaw.paperlabvuforia");
        PlayerSettings.Android.bundleVersionCode = 1;
        PlayerSettings.bundleVersion = "0.1-vuforia-experimental";
        PlayerSettings.SetScriptingBackend(UnityEditor.Build.NamedBuildTarget.Android, ScriptingImplementation.IL2CPP);
        PlayerSettings.Android.targetArchitectures = AndroidArchitecture.ARM64;
        PlayerSettings.Android.useCustomKeystore = false;
        foreach (var id in AssetDatabase.FindAssets("", new[] { "Assets/Plugins" }))
        {
            var importer = AssetImporter.GetAtPath(AssetDatabase.GUIDToAssetPath(id)) as PluginImporter;
            if (importer == null) continue;
            importer.SetCompatibleWithAnyPlatform(false); importer.SetCompatibleWithEditor(false);
            importer.SetCompatibleWithPlatform(BuildTarget.Android, true); importer.SetPlatformData(BuildTarget.Android, "CPU", "ARM64"); importer.SaveAndReimport();
        }
        AssetDatabase.SaveAssets();
        Debug.Log("VUFORIA SOURCE COMPILED AND SCENE PREPARED (not device acceptance)");
    }
    public static void Android()
    {
        Prepare(); Directory.CreateDirectory("Builds");
        var report = BuildPipeline.BuildPlayer(new[] { "Assets/QuestVuforia/PaperVuforiaScene.unity" }, "Builds/paperlab-vuforia.apk", BuildTarget.Android, BuildOptions.Development);
        if (report.summary.result != BuildResult.Succeeded) throw new Exception("Vuforia APK build: " + report.summary.result);
    }
}

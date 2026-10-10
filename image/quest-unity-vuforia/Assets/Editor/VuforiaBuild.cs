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
        // The SDK can return an unsaved in-memory default. Runtime Resources.Load
        // cannot see that object, so persist it before editing agreement flags.
        if (string.IsNullOrEmpty(AssetDatabase.GetAssetPath(config)))
            AssetDatabase.CreateAsset(config, "Assets/Resources/VuforiaConfiguration.asset");
        config.Vuforia.LicenseKey = "";
        config.Vuforia.DelayedInitialization = true;
        config.VideoBackground.VideoBackgroundEnabled = false;
        var configAsset = new SerializedObject(config);
        // An editor preference may seed this legacy field with another license.
        // Never bake either key field into a public project or APK.
        var legacyKey = configAsset.FindProperty("vuforia.ufoLicenseKey");
        if (legacyKey == null) throw new Exception("Legacy Vuforia license field not found");
        legacyKey.stringValue = "";
        // Vuforia's setter is assembly-internal. Persist the accepted 11.4
        // developer-account agreement version through its serialized field;
        // an empty value aborts initialization before our private key loads.
        var eula = configAsset.FindProperty("vuforia.eulaAcceptedVersions");
        if (eula == null) throw new Exception("Vuforia agreement field not found");
        eula.stringValue = "{\"Values\":[\"11.4\"]}";
        configAsset.FindProperty("deviceTracker.autoStartTracker").boolValue = false;
        configAsset.ApplyModifiedPropertiesWithoutUndo();
        if (new SerializedObject(config).FindProperty("vuforia.ufoLicenseKey").stringValue.Length != 0)
            throw new Exception("Legacy Vuforia license field persisted after clear");
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
        // SDK 11.4's OnBeforeSerialize repopulates the legacy obfuscated key
        // even after SerializedObject clears it. Do not ship that editor seed.
        const string configPath = "Assets/Resources/VuforiaConfiguration.asset";
        var configLines = File.ReadAllLines(configPath);
        for (int i = 0; i < configLines.Length; i++)
            if (configLines[i].TrimStart().StartsWith("ufoLicenseKey:"))
                configLines[i] = "    ufoLicenseKey: ";
        File.WriteAllLines(configPath, configLines);
        AssetDatabase.ImportAsset(configPath, ImportAssetOptions.ForceUpdate);
        foreach (var line in File.ReadAllLines(configPath))
            if (line.TrimStart().StartsWith("ufoLicenseKey:") &&
                line.Substring(line.IndexOf(':') + 1).Trim().Length != 0)
                throw new Exception("Legacy Vuforia license key remained in public asset");
        Debug.Log("VUFORIA SOURCE COMPILED AND SCENE PREPARED (not device acceptance)");
    }
    public static void Android()
    {
        Prepare(); Directory.CreateDirectory("Builds");
        var report = BuildPipeline.BuildPlayer(new[] { "Assets/QuestVuforia/PaperVuforiaScene.unity" }, "Builds/paperlab-vuforia.apk", BuildTarget.Android, BuildOptions.Development);
        if (report.summary.result != BuildResult.Succeeded) throw new Exception("Vuforia APK build: " + report.summary.result);
    }
}

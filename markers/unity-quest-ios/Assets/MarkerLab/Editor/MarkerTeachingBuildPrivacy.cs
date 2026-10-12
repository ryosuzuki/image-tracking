using System;
using UnityEditor;
using UnityEditor.Build;
using UnityEditor.Build.Reporting;
using UnityEngine;

// Meta's order-1 processor can inject editor authentication into a generated
// Resources asset. Clear it after SDK processing, before player serialization.
public sealed class MarkerTeachingBuildPrivacy : IPreprocessBuildWithReport
{
    public int callbackOrder { get { return 1000; } }

    public void OnPreprocessBuild(BuildReport report)
    {
        if (PlayerSettings.GetApplicationIdentifier(UnityEditor.Build.NamedBuildTarget.Android)
            != "org.openclaw.markertrackinglab") return;
        var asset = AssetDatabase.LoadAssetAtPath<ScriptableObject>("Assets/Resources/DevAgentSettings.asset");
        if (!asset) return;
        var serialized = new SerializedObject(asset);
        var enabled = serialized.FindProperty("enabled");
        var token = serialized.FindProperty("accessToken");
        var address = serialized.FindProperty("serverAddress");
        if (enabled == null || token == null || address == null)
            throw new BuildFailedException("Developer-agent privacy fields changed; refusing teaching build.");
        enabled.boolValue = false;
        token.stringValue = "";
        address.stringValue = "";
        serialized.ApplyModifiedPropertiesWithoutUndo();
        AssetDatabase.SaveAssets();
        var verified = new SerializedObject(asset);
        if (verified.FindProperty("enabled").boolValue ||
            verified.FindProperty("accessToken").stringValue.Length != 0 ||
            verified.FindProperty("serverAddress").stringValue.Length != 0)
            throw new BuildFailedException("Developer-agent settings were not cleared.");
        Debug.Log("MARKER TEACHING PRIVACY developer agent disabled; token/address empty");
    }
}

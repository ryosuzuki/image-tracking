using System;
using System.IO;
using UnityEngine;
using Vuforia;

[DefaultExecutionOrder(-100)]
public class QuestVuforiaDriverInit : MonoBehaviour
{
    private void Start()
    {
        // Android's app-private files directory, provisioned through `run-as`.
        // Application.persistentDataPath resolves to external scoped storage on
        // Quest; an ADB shell-owned file there is not readable by this app.
        string path;
#if UNITY_ANDROID && !UNITY_EDITOR
        using (var player = new AndroidJavaClass("com.unity3d.player.UnityPlayer"))
        using (var activity = player.GetStatic<AndroidJavaObject>("currentActivity"))
        using (var files = activity.Call<AndroidJavaObject>("getFilesDir"))
            path = Path.Combine(files.Call<string>("getAbsolutePath"), "vuforia-license.txt");
#else
        path = Path.Combine(Application.persistentDataPath, "vuforia-license.txt");
#endif
        if (!File.Exists(path)) { Debug.LogError("VUFORIA LICENSE missing private device provision"); return; }
        string key = File.ReadAllText(path).Trim();
        if (key.Length < 20) { Debug.LogError("VUFORIA LICENSE invalid private provision"); return; }
        VuforiaConfiguration.Instance.Vuforia.LicenseKey = key;
        VuforiaConfiguration.Instance.Vuforia.DelayedInitialization = true;
        VuforiaConfiguration.Instance.DeviceTracker.UseThirdPartySeethroughEyewear = true;
        VuforiaApplication.Instance.OnVuforiaInitialized += Initialized;
        // SDK 11.4 requires the complete packaged driver filename, not the
        // bare System.loadLibrary name; see VuforiaApplication.Initialize XML.
        VuforiaApplication.Instance.Initialize("libquforia.so", IntPtr.Zero);
    }
    private void Initialized(VuforiaInitError error) { Debug.Log("VUFORIA INIT " + error); }
    private void OnDestroy() { VuforiaApplication.Instance.OnVuforiaInitialized -= Initialized; }
}

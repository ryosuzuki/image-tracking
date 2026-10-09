using System;
using System.IO;
using UnityEngine;
using Vuforia;

[DefaultExecutionOrder(-100)]
public class QuestVuforiaDriverInit : MonoBehaviour
{
    private void Start()
    {
        // Private device provisioning, not StreamingAssets or a committed Unity asset.
        string path = Path.Combine(Application.persistentDataPath, "vuforia-license.txt");
        if (!File.Exists(path)) { Debug.LogError("VUFORIA LICENSE missing private device provision"); return; }
        string key = File.ReadAllText(path).Trim();
        if (key.Length < 20) { Debug.LogError("VUFORIA LICENSE invalid private provision"); return; }
        VuforiaConfiguration.Instance.Vuforia.LicenseKey = key;
        VuforiaConfiguration.Instance.Vuforia.DelayedInitialization = true;
        VuforiaConfiguration.Instance.DeviceTracker.UseThirdPartySeethroughEyewear = true;
        VuforiaApplication.Instance.OnVuforiaInitialized += Initialized;
        VuforiaApplication.Instance.Initialize("quforia", IntPtr.Zero);
    }
    private void Initialized(VuforiaInitError error) { Debug.Log("VUFORIA INIT " + error); }
    private void OnDestroy() { VuforiaApplication.Instance.OnVuforiaInitialized -= Initialized; }
}

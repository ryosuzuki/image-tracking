using System;
using Meta.XR;
using UnityEngine;
using UnityEngine.Android;
using UnityEngine.Rendering;

// Derived from Quforia (MIT). Android PCA requires GPU readback, not GetColors().
[DefaultExecutionOrder(-50)]
public class MetaCameraProvider : MonoBehaviour
{
    [SerializeField] private PassthroughCameraAccess cameraAccess;
    public PassthroughCameraAccess CameraAccess => cameraAccess;
    public Pose LastSubmittedPose { get; private set; }
    public bool HasSubmittedPose { get; private set; }
    private bool pending, destroyed, paused;
    public long LastSubmittedTimestampNs { get; private set; }
    private long lastTimestamp;
    private byte[] rgb;
    private int configuredWidth, configuredHeight;
    private int generation;

    private void Start()
    {
        if (!cameraAccess) throw new InvalidOperationException("PCA camera is required");
        Permission.RequestUserPermission("horizonos.permission.HEADSET_CAMERA");
        cameraAccess.CameraPosition = PassthroughCameraAccess.CameraPositionType.Left;
        // Native driver's advertised mode. Square frames require separate qualification.
        cameraAccess.RequestedResolution = new Vector2Int(1280, 960);
        cameraAccess.MaxFramerate = 30;
        cameraAccess.enabled = true;
    }

    private void Configure(Vector2Int size)
    {
        if (size.x != 1280 || size.y != 960)
            throw new InvalidOperationException("Vuforia driver expects 1280x960");
        var k = cameraAccess.Intrinsics;
        float ratio = Mathf.Max((float)size.x / k.SensorResolution.x,
                               (float)size.y / k.SensorResolution.y);
        float cropX = (k.SensorResolution.x - size.x / ratio) * .5f;
        float cropY = (k.SensorResolution.y - size.y / ratio) * .5f;
        var intrinsics = new float[14];
        intrinsics[0] = size.x; intrinsics[1] = size.y;
        intrinsics[2] = k.FocalLength.x * ratio;
        intrinsics[3] = k.FocalLength.y * ratio;
        intrinsics[4] = (k.PrincipalPoint.x - cropX) * ratio;
        intrinsics[5] = (k.PrincipalPoint.y - cropY) * ratio;
        if (!QuestVuforiaBridge.SetCameraIntrinsics(intrinsics))
            throw new InvalidOperationException("Native driver rejected intrinsics");
        rgb = new byte[checked(size.x * size.y * 3)];
        configuredWidth = size.x; configuredHeight = size.y;
        Debug.Log("VUFORIA CAMERA calibrated " + size);
    }

    private void LateUpdate()
    {
        if (paused || pending || !cameraAccess || !cameraAccess.IsPlaying ||
            !cameraAccess.IsUpdatedThisFrame || !OVRPlugin.positionTracked || !QuestVuforiaBridge.IsDriverInitialized()) return;
        long stamp = checked((cameraAccess.Timestamp.ToUniversalTime().Ticks - DateTime.UnixEpoch.Ticks) * 100);
        if (stamp <= lastTimestamp) return;
        var texture = cameraAccess.GetTexture();
        if (!texture) return;
        var size = cameraAccess.CurrentResolution;
        if (rgb == null || configuredWidth != size.x || configuredHeight != size.y) Configure(size);
        // Snapshot metadata at submission, never replace it with callback/render-time pose.
        Pose pose = cameraAccess.GetCameraPose();
        int epoch = generation;
        pending = true;
        AsyncGPUReadback.Request(texture, 0, TextureFormat.RGBA32, request =>
        {
            pending = false;
            if (destroyed || paused || epoch != generation || !OVRPlugin.positionTracked) return;
            if (request.hasError) { Debug.LogWarning("VUFORIA GPU readback failed"); return; }
            var pixels = request.GetData<byte>();
            if (pixels.Length != size.x * size.y * 4) return;
            for (int y = 0; y < size.y; y++)
                for (int x = 0; x < size.x; x++)
                {
                    int src = ((size.y - 1 - y) * size.x + x) * 4;
                    int dst = (y * size.x + x) * 3;
                    rgb[dst] = pixels[src]; rgb[dst + 1] = pixels[src + 1]; rgb[dst + 2] = pixels[src + 2];
                }
            if (QuestVuforiaBridge.FeedCameraFrame(rgb, size.x, size.y, null, stamp))
            {
                lastTimestamp = stamp;
                LastSubmittedTimestampNs = stamp;
                LastSubmittedPose = pose;
                HasSubmittedPose = true;
            }
        });
    }

    private void OnApplicationPause(bool value) { paused = value; generation++; HasSubmittedPose = false; }
    private void OnApplicationFocus(bool value) { if (!value) { generation++; HasSubmittedPose = false; } }
    private void OnDestroy() { destroyed = true; generation++; }
}

using System;
using System.Collections;
using System.Runtime.InteropServices;
using UnityEngine;
using UnityEngine.Android;
using UnityEngine.Rendering;
using Meta.XR;
using Meta.XR.MRUtilityKit;
namespace MRClass
{
public sealed class MarkerInput : MonoBehaviour
{
    [DllImport("marker_core")]
    static extern int ml_track_multi(byte[] image, int w, int h, double[] k, int mode, int[] ids, int markers,
                                     double bw, double bh, double[] xy, int[] colors, int count,
                                     float[] output);
    public Pose Pose;
    public bool Fresh, Visible;
    public int Frames;
    public string Status = "Paper camera not started";
    PassthroughCameraAccess access;
    MarkerBoard board;
    byte[] pixels;
    float[] result = new float[34];
    double[] k;
    bool pending, focused = true, started;
    int epoch;
    long lastStamp, minimumStamp;
    double next;
    OVRDisplay display;
    readonly MeasuredTrackingAccess gate = new MeasuredTrackingAccess();
    IEnumerator Start()
    {
        started = true;
        board = JsonUtility.FromJson<MarkerBoard>(Resources.Load<TextAsset>("marker-board").text);
        if (!Permission.HasUserAuthorizedPermission("horizonos.permission.HEADSET_CAMERA") ||
            !Permission.HasUserAuthorizedPermission(Permission.Camera))
        {
            Permission.RequestUserPermissions(
                new[] { Permission.Camera, "horizonos.permission.HEADSET_CAMERA" });
            Status = "Camera permission requested";
            float permissionDeadline = Time.realtimeSinceStartup + 20;
            while ((!Permission.HasUserAuthorizedPermission("horizonos.permission.HEADSET_CAMERA") ||
                    !Permission.HasUserAuthorizedPermission(Permission.Camera)) &&
                   Time.realtimeSinceStartup < permissionDeadline)
                yield return null;
        }
        if (!Permission.HasUserAuthorizedPermission("horizonos.permission.HEADSET_CAMERA") ||
            !Permission.HasUserAuthorizedPermission(Permission.Camera))
        {
            Status = "Camera not granted; switch Manual / Paper to retry";
            yield break;
        }
        // MRUK enqueues its native camera initialization on the render thread before the splash.
        // An already-granted permission must not let this dynamic adapter Play in its first frame.
        Status = "Waiting for XR focus and camera initialization";
        float focusDeadline = Time.realtimeSinceStartup + 15;
        while (!OVRManager.hasVrFocus && Time.realtimeSinceStartup < focusDeadline)
            yield return null;
        if (!OVRManager.hasVrFocus)
        {
            Status = "No XR focus; camera not opened";
            yield break;
        }
        yield return new WaitForEndOfFrame();
        yield return new WaitForSecondsRealtime(.75f);
        var supported =
            PassthroughCameraAccess.GetSupportedResolutions(PassthroughCameraAccess.CameraPositionType.Left);
        Debug.Log("MR_CLASS_CAMERA_GATE focused=" + OVRManager.hasVrFocus +
                  " supportedResolutions=" + supported.Length);
        if (supported.Length == 0)
        {
            Status = "Camera unavailable. Check this app's camera / MR-sensor access\nand headset " +
                     "presence; Manual mode remains available.";
            yield break;
        }
        if (!access)
        {
            var g = new GameObject("Same-exposure paper camera");
            g.transform.SetParent(transform, false);
            g.SetActive(false);
            access = g.AddComponent<PassthroughCameraAccess>();
            access.enabled = false;
            access.CameraPosition = PassthroughCameraAccess.CameraPositionType.Left;
            access.RequestedResolution = new Vector2Int(1280, 1280);
            access.MaxFramerate = 30;
            access.enabled = true;
            g.SetActive(true);
        }
        float deadline = Time.realtimeSinceStartup + 15;
        while (!access.IsPlaying && Time.realtimeSinceStartup < deadline)
            yield return null;
        if (!access.IsPlaying)
        {
            Status = "Camera unavailable; preserve other camera owner";
            yield break;
        }
        var res = access.CurrentResolution;
        pixels = new byte[res.x * res.y * 4];
        var c = access.Intrinsics;
        k = MarkerCameraCalibration.Intrinsics(c.FocalLength.x, c.FocalLength.y, c.PrincipalPoint.x,
                                               c.PrincipalPoint.y, c.SensorResolution.x, c.SensorResolution.y,
                                               res.x, res.y);
        Status = "Look at dots-8 / 120 mm between opposite dot corners";
    }
    void Update()
    {
        double now = Time.realtimeSinceStartupAsDouble;
        gate.SetReliable(focused && OVRManager.isHmdPresent && OVRPlugin.positionTracked && access &&
                         access.IsPlaying);
        Fresh = gate.Interactive(now);
        Visible = gate.Visible(now);
        if (!access || !access.IsPlaying || pixels == null || pending || now < next ||
            !access.IsUpdatedThisFrame)
            return;
        next = now + .06;
        var tex = access.GetTexture();
        if (!tex)
            return;
        long stamp = (access.Timestamp.ToUniversalTime().Ticks - DateTime.UnixEpoch.Ticks) / 10;
        if (stamp <= lastStamp || stamp < minimumStamp)
            return;
        var pose = access.GetCameraPose();
        bool valid = MarkerCameraCalibration.ValidPose(pose.position.x, pose.position.y, pose.position.z,
                                                       pose.rotation.x, pose.rotation.y, pose.rotation.z,
                                                       pose.rotation.w);
        int requestEpoch = epoch;
        var size = access.CurrentResolution;
        pending = true;
        AsyncGPUReadback.Request(
            tex, 0, TextureFormat.RGBA32,
            request =>
            {
                pending = false;
                if (!this || request.hasError || requestEpoch != epoch || !focused)
                    return;
                var data = request.GetData<byte>();
                if (data.Length != pixels.Length)
                    return;
                for (int y = 0; y < size.y; y++)
                    for (int x = 0; x < size.x * 4; x++)
                        pixels[y * size.x * 4 + x] = data[(size.y - 1 - y) * size.x * 4 + x];
                lastStamp = stamp;
                double age = (DateTime.UtcNow.Ticks - DateTime.UnixEpoch.Ticks) / 1e7 - stamp / 1e6;
                try
                {
                    int found = ml_track_multi(pixels, size.x, size.y, k, 2, board.ids, board.ids.Length,
                                               board.width, board.height, board.dot_xy, board.dot_colors,
                                               board.dot_xy.Length / 2, result);
                    bool seen =
                        valid && found == 1 && age >= -.01 && age < MeasuredTrackingAccess.InputSeconds;
                    if (seen)
                    {
                        var world = MarkerPoseMath.World(pose, result);
                        seen = MarkerCameraCalibration.ValidPose(
                            world.position.x, world.position.y, world.position.z, world.rotation.x,
                            world.rotation.y, world.rotation.z, world.rotation.w);
                        if (seen)
                            Pose = world;
                    }
                    gate.Observe(gate.Epoch, Time.realtimeSinceStartupAsDouble - Math.Max(0, age), seen);
                    Frames++;
                    Status = seen ? "Measured paper ID " + (int)result[0] + " / same exposure"
                                  : "No fresh printed target; content hidden / inputs frozen";
                    if (Frames % 15 == 0)
                        Debug.Log("MR_CLASS_CAMERA frames=" + Frames + " ageSeconds=" + age.ToString("F3") +
                                  " capturePose=" + valid + " detected=" + seen);
                }
                catch (Exception e)
                {
                    Status = "Marker engine: " + e.GetType().Name;
                    gate.Invalidate();
                }
            });
    }
    void OnApplicationFocus(bool value)
    {
        focused = value;
        Invalidate();
    }
    void OnApplicationPause(bool value)
    {
        if (value)
            Invalidate();
    }
    public void Invalidate()
    {
        epoch++;
        gate.BeginSelection();
        Fresh = Visible = false;
        minimumStamp = (DateTime.UtcNow.Ticks - DateTime.UnixEpoch.Ticks) / 10;
    }
    void OriginChanging(OVRManager.TrackingOrigin origin, OVRPose? previous)
    {
        Invalidate();
    }
    void OnDisable()
    {
        StopAllCoroutines();
        OVRManager.TrackingOriginChangePending -= OriginChanging;
        if (display != null)
            display.RecenteredPose -= Invalidate;
        Invalidate();
        if (access)
            access.enabled = false;
    }
    void OnEnable()
    {
        OVRManager.TrackingOriginChangePending += OriginChanging;
        display = OVRManager.display;
        if (display != null)
            display.RecenteredPose += Invalidate;
        if (access)
            access.enabled = true;
        if (started && pixels == null)
            StartCoroutine(Start());
    }
}
}

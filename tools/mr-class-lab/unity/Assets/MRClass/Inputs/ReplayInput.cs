using System;
using System.IO;
using UnityEngine;
namespace MRClass
{
[Serializable]
public class Calibration
{
    public int width, height;
    public float fx, fy, cx, cy;
}
[Serializable]
public class CaptureFrame
{
    public float time;
    public float[] position, rotation;
    public string image;
}
[Serializable]
public class Capture
{
    public int version;
    public string id, coordinateSystem, provenance;
    public bool synthetic;
    public Calibration intrinsics;
    public CaptureFrame[] frames;
}
public sealed class ReplayInput : MonoBehaviour
{
    public Capture Data;
    public Camera Camera;
    public float Time;
    public bool Playing;
    public int FrameIndex;
    public float Duration => Data.frames[Data.frames.Length - 1].time;
    string folder;
    Texture2D image;
    RenderTexture overlay;
    LabApp app;
    int loaded = -1;
    public void Load(string directory, LabApp application)
    {
        app = application;
        folder = Path.GetFullPath(directory);
        Data = JsonUtility.FromJson<Capture>(File.ReadAllText(Path.Combine(folder, "lab.json")));
        if (Data.coordinateSystem != "unity-lh-y-up-meters" || Data.frames == null || Data.frames.Length == 0)
            throw new Exception("Use prepare_lab.py on an authorized normalized capture");
        var k = Data.intrinsics;
        if (k == null || k.width <= 0 || k.height <= 0 || k.fx <= 0 || k.fy <= 0)
            throw new Exception("Invalid source calibration");
        float previous = -1;
        foreach (var f in Data.frames)
        {
            if (float.IsNaN(f.time) || float.IsInfinity(f.time) || f.time <= previous || f.position == null ||
                f.position.Length != 3 || f.rotation == null || f.rotation.Length != 4)
                throw new Exception("Invalid source timeline / pose");
            previous = f.time;
            SafeImage(f.image);
        }
        if (app.View)
            app.View.enabled = false;
        Camera = new GameObject("Recorded sensor camera - not live XR").AddComponent<Camera>();
        Camera.transform.SetParent(transform, false);
        Camera.clearFlags = CameraClearFlags.SolidColor;
        Camera.backgroundColor = Color.clear;
        Camera.nearClipPlane = .03f;
        Camera.farClipPlane = 50;
        Camera.allowHDR = false;
        Camera.allowMSAA = false;
        Camera.enabled = false;
        overlay = new RenderTexture(k.width, k.height, 24, RenderTextureFormat.ARGB32);
        Camera.targetTexture = overlay;
        image = new Texture2D(2, 2);
        var m = new Matrix4x4();
        float n = Camera.nearClipPlane, fv = Camera.farClipPlane;
        m[0, 0] = 2 * k.fx / k.width;
        m[0, 2] = 1 - 2 * k.cx / k.width;
        m[1, 1] = 2 * k.fy / k.height;
        m[1, 2] = 2 * k.cy / k.height - 1;
        m[2, 2] = -(fv + n) / (fv - n);
        m[2, 3] = -2 * fv * n / (fv - n);
        m[3, 2] = -1;
        Camera.projectionMatrix = m;
        app.View = Camera;
        var first = Data.frames[0];
        var q = Q(first.rotation);
        app.Stage.SetPositionAndRotation(V(first.position) + q * Vector3.forward * 1.2f, q);
        app.Stage.localScale = Vector3.one * .8f;
        app.AnchorStatus = "Manually authored world origin in recorded capture; no object tracking";
        Seek(0);
    }
    string SafeImage(string rel)
    {
        string p = Path.GetFullPath(Path.Combine(folder, rel));
        if (!p.StartsWith(folder + Path.DirectorySeparatorChar, StringComparison.Ordinal) || !File.Exists(p))
            throw new Exception("Missing image or path outside capture");
        return p;
    }
    public static Vector3 V(float[] p) => new Vector3(p[0], p[1], p[2]);
    public static Quaternion Q(float[] q) => new Quaternion(q[0], q[1], q[2], q[3]);
    public void Seek(float t)
    {
        Time = Mathf.Clamp(t, 0, Duration);
        int lo = 0, hi = Data.frames.Length;
        while (lo < hi)
        {
            int mid = (lo + hi) / 2;
            if (Data.frames[mid].time <= Time)
                lo = mid + 1;
            else
                hi = mid;
        }
        FrameIndex = Mathf.Max(0, lo - 1);
        var f = Data.frames[FrameIndex];
        Camera.transform.SetPositionAndRotation(V(f.position), Q(f.rotation));
        if (loaded != FrameIndex)
        {
            if (!image.LoadImage(File.ReadAllBytes(SafeImage(f.image))))
                throw new Exception("Source image decode failed");
            if (image.width != Data.intrinsics.width || image.height != Data.intrinsics.height)
                throw new Exception("Source image/calibration dimensions differ");
            loaded = FrameIndex;
        }
        app.Clock = Time;
        app.Apply();
    }
    void Update()
    {
        if (Playing && Data != null)
        {
            Seek(Time + UnityEngine.Time.deltaTime);
            if (Time >= Duration)
                Playing = false;
        }
    }
    void OnGUI()
    {
        if (Data == null || app.Preview)
            return;
        float size = Mathf.Min(Screen.height, Screen.width - 350);
        var rect = new Rect(350, 0, size, size * Data.intrinsics.height / Data.intrinsics.width);
        Camera.Render();
        GUI.DrawTexture(rect, image, ScaleMode.StretchToFill);
        GUI.DrawTexture(rect, overlay, ScaleMode.StretchToFill, true);
    }
    public int SaveFrame(string output)
    {
        Camera.Render();
        RenderTexture.active = overlay;
        var result = new Texture2D(overlay.width, overlay.height, TextureFormat.RGBA32, false);
        result.ReadPixels(new Rect(0, 0, overlay.width, overlay.height), 0, 0);
        result.Apply();
        var pixels = result.GetPixels32();
        var background = image.GetPixels32();
        int visible = 0;
        for (int i = 0; i < pixels.Length; i++)
        {
            float a = pixels[i].a / 255f;
            if (a > .1f)
                visible++;
            background[i] = new Color32((byte)Mathf.Lerp(background[i].r, pixels[i].r, a),
                                        (byte)Mathf.Lerp(background[i].g, pixels[i].g, a),
                                        (byte)Mathf.Lerp(background[i].b, pixels[i].b, a), 255);
        }
        result.SetPixels32(background);
        result.Apply();
        File.WriteAllBytes(output, result.EncodeToPNG());
        RenderTexture.active = null;
        DestroyImmediate(result);
        return visible;
    }
    void OnDestroy()
    {
        if (overlay)
        {
            overlay.Release();
            DestroyImmediate(overlay);
        }
        if (image)
            DestroyImmediate(image);
        if (Camera)
            DestroyImmediate(Camera.gameObject);
    }
}
}

using System;
using System.IO;
using UnityEngine;
namespace RecordedContext
{
[Serializable]
public class Calibration
{
    public int width, height;
    public float fx, fy, cx, cy;
}
[Serializable]
public class Frame
{
    public float time;
    public float[] position, rotation;
    public string image;
}
[Serializable]
public class Annotation
{
    public string id, label;
    public float[] position;
    public float radius, triggerTime;
}
[Serializable]
public class Lab
{
    public int version;
    public string id, coordinateSystem, provenance;
    public bool synthetic;
    public Calibration intrinsics;
    public Frame[] frames;
    public Annotation[] annotations;
}
// Recorded camera replay, NOT an XR input driver, recognizer or paper reproduction.
public class RecordedContextPlayer : MonoBehaviour
{
    public string Folder;
    public Lab Data { get; private set; }
    public int FrameIndex { get; private set; }
    public float PlaybackTime;
    public bool Playing, ManualHighlight;
    public int Mode;
    public Camera CaptureCamera { get; private set; }
    Texture2D source;
    RenderTexture overlay;
    GameObject anchorRoot;
    Material baseMaterial;
    int loaded = -1;
    string error;
    [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
    static void Boot()
    {
        if (FindAnyObjectByType<RecordedContextPlayer>() == null)
            new GameObject("Recorded Context Lab").AddComponent<RecordedContextPlayer>();
    }
    void Start()
    {
        if (Data != null)
            return;
        var root = string.IsNullOrWhiteSpace(Folder) ? Environment.GetEnvironmentVariable("MR_LAB_CAPTURE") : Folder;
        if (string.IsNullOrWhiteSpace(root))
            root = Path.Combine(Application.streamingAssetsPath, "capture");
        try
        {
            Load(root);
        }
        catch (Exception e)
        {
            error = e.Message;
        }
    }
    public void Load(string folder)
    {
        Folder = Path.GetFullPath(folder);
        Data = JsonUtility.FromJson<Lab>(File.ReadAllText(Path.Combine(Folder, "lab.json")));
        if (Data.coordinateSystem != "unity-lh-y-up-meters" || Data.frames == null || Data.frames.Length == 0 ||
            Data.annotations == null || Data.annotations.Length == 0)
            throw new Exception("Use prepare_lab.py; unsupported or empty capture");
        var k = Data.intrinsics;
        if (k == null || k.fx <= 0 || k.fy <= 0 || k.width <= 0 || k.height <= 0)
            throw new Exception("Invalid calibration");
        float previous = -1;
        foreach (var f in Data.frames)
        {
            if (f.time < 0 || f.time <= previous || f.position.Length != 3 || f.rotation.Length != 4)
                throw new Exception("Invalid timeline/pose");
            previous = f.time;
            var p = Path.GetFullPath(Path.Combine(Folder, f.image));
            if (!p.StartsWith(Folder + Path.DirectorySeparatorChar, StringComparison.Ordinal) || !File.Exists(p))
                throw new Exception("Image missing or outside capture");
        }
        CaptureCamera = new GameObject("Recorded calibrated camera (not XR)").AddComponent<Camera>();
        CaptureCamera.transform.SetParent(transform, false);
        CaptureCamera.clearFlags = CameraClearFlags.SolidColor;
        CaptureCamera.backgroundColor = Color.clear;
        CaptureCamera.nearClipPlane = .03f;
        CaptureCamera.farClipPlane = 50;
        CaptureCamera.allowHDR = false;
        CaptureCamera.allowMSAA = false;
        overlay = new RenderTexture(k.width, k.height, 24, RenderTextureFormat.ARGB32);
        CaptureCamera.targetTexture = overlay;
        source = new Texture2D(2, 2);
        var near = CaptureCamera.nearClipPlane;
        var far = CaptureCamera.farClipPlane;
        var m = new Matrix4x4();
        m[0, 0] = 2 * k.fx / k.width;
        m[0, 2] = 1 - 2 * k.cx / k.width;
        m[1, 1] = 2 * k.fy / k.height;
        m[1, 2] = 2 * k.cy / k.height - 1;
        m[2, 2] = -(far + near) / (far - near);
        m[2, 3] = -2 * far * near / (far - near);
        m[3, 2] = -1;
        CaptureCamera.projectionMatrix = m;
        CaptureCamera.enabled = false;
        baseMaterial = new Material(Shader.Find("RecordedContext/Flat"));
        Rebuild();
        Seek(0);
    }
    public void Rebuild()
    {
        if (anchorRoot != null)
            DestroyImmediate(anchorRoot);
        anchorRoot = new GameObject("Authored world anchors");
        anchorRoot.transform.SetParent(transform, false);
        foreach (var a in Data.annotations)
        {
            var g = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            g.name = a.id;
            g.transform.SetParent(anchorRoot.transform);
            g.transform.position = V(a.position);
            g.transform.localScale = Vector3.one * a.radius * 2;
            g.GetComponent<Renderer>().sharedMaterial = new Material(baseMaterial);
            DestroyImmediate(g.GetComponent<Collider>());
            var label = new GameObject("Authored note");
            label.transform.SetParent(g.transform);
            label.transform.localPosition = new Vector3(0, 1, 0);
            label.transform.localScale = Vector3.one / (a.radius * 2);
            var text = label.AddComponent<TextMesh>();
            text.text = a.label;
            text.richText = false;
            text.characterSize = .004f;
            text.fontSize = 48;
            text.anchor = TextAnchor.LowerCenter;
            text.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            label.GetComponent<MeshRenderer>().sharedMaterial = text.font.material;
        }
    }
    public static int Index(Frame[] frames, float t)
    {
        int lo = 0, hi = frames.Length;
        while (lo < hi)
        {
            int mid = (lo + hi) / 2;
            if (frames[mid].time <= t)
                lo = mid + 1;
            else
                hi = mid;
        }
        return Mathf.Max(0, lo - 1);
    }
    static Vector3 V(float[] p) => new Vector3(p[0], p[1], p[2]);
    public void Seek(float time)
    {
        PlaybackTime = Mathf.Clamp(time, 0, Data.frames[Data.frames.Length - 1].time);
        FrameIndex = Index(Data.frames, PlaybackTime);
        var f = Data.frames[FrameIndex];
        CaptureCamera.transform.SetPositionAndRotation(
            V(f.position), new Quaternion(f.rotation[0], f.rotation[1], f.rotation[2], f.rotation[3]));
        if (loaded != FrameIndex)
        {
            source.LoadImage(File.ReadAllBytes(Path.Combine(Folder, f.image)));
            loaded = FrameIndex;
        }
        for (int i = 0; i < Data.annotations.Length; i++)
        {
            var a = Data.annotations[i];
            bool active = Mode == 1 ? ManualHighlight : Mode == 2 && PlaybackTime >= a.triggerTime;
            var g = anchorRoot.transform.GetChild(i);
            g.GetComponent<Renderer>().sharedMaterial.color =
                active ? new Color(1, .72f, .25f) : new Color(.3f, .85f, .65f);
            g.GetChild(0).gameObject.SetActive(Mode != 2 || active);
            g.GetChild(0).rotation = CaptureCamera.transform.rotation;
        }
        CaptureCamera.Render();
    }
    void Update()
    {
        if (Data == null)
            return;
        if (Playing)
        {
            float next = PlaybackTime + Time.deltaTime;
            if (next >= Data.frames[Data.frames.Length - 1].time)
                Playing = false;
            Seek(next);
        }
    }
    void OnGUI()
    {
        GUI.skin.label.fontSize = 17;
        GUI.skin.button.fontSize = 17;
        if (Data == null)
        {
            GUI.Label(new Rect(20, 20, Screen.width - 40, 160),
                      "Recorded Context Lab\n" + error +
                          ("\nSet MR_LAB_CAPTURE to your private prepared folder before launch, or use Tools > " +
                           "Recorded Context Lab > Open capture in Play Mode."));
            return;
        }
        float width =
            Mathf.Min(Screen.width - 360, Screen.height * Data.intrinsics.width / (float)Data.intrinsics.height);
        var view = new Rect(0, 0, width, width * Data.intrinsics.height / Data.intrinsics.width);
        GUI.DrawTexture(view, source, ScaleMode.StretchToFill);
        GUI.DrawTexture(view, overlay, ScaleMode.StretchToFill, true);
        GUILayout.BeginArea(new Rect(width + 15, 15, 340, Screen.height - 30));
        GUILayout.Label(Data.synthetic ? "SYNTHETIC FIXTURE" : "RECORDED CAMERA REPLAY");
        GUILayout.Label(Data.id);
        GUILayout.Label("Frame " + FrameIndex + " / " + Data.frames.Length);
        if (GUILayout.Button(Playing ? "Pause" : "Play"))
            Playing = !Playing;
        float next = GUILayout.HorizontalSlider(PlaybackTime, 0, Data.frames[Data.frames.Length - 1].time);
        if (Mathf.Abs(next - PlaybackTime) > .001f)
        {
            Playing = false;
            Seek(next);
        }
        GUILayout.Label(PlaybackTime.ToString("F2") + " s");
        int mode = GUILayout.SelectionGrid(Mode, new[] { "Note", "Button", "Time" }, 3);
        if (mode != Mode)
        {
            Mode = mode;
            ManualHighlight = false;
            Seek(PlaybackTime);
        }
        if (Mode == 1 && GUILayout.Button("Toggle object highlight"))
        {
            ManualHighlight = !ManualHighlight;
            Seek(PlaybackTime);
        }
        if (GUILayout.Button("Reset"))
        {
            Playing = false;
            ManualHighlight = false;
            Seek(0);
        }
        GUILayout.Label("Edit lab.json in the browser or inspect Data in code. Reload after saving.");
        GUILayout.Label(Data.provenance);
        GUILayout.Label(
            "No live XR, inferred object tracking, hand contact or AI. Use the separate recorder APK on Quest.");
        GUILayout.EndArea();
    }
    void OnDestroy()
    {
        if (overlay != null)
        {
            overlay.Release();
            Destroy(overlay);
        }
        if (source != null)
            Destroy(source);
        if (baseMaterial != null)
            Destroy(baseMaterial);
    }
    public void SaveFrame(string output)
    {
        CaptureCamera.Render();
        RenderTexture.active = overlay;
        var pixels = new Texture2D(overlay.width, overlay.height, TextureFormat.RGBA32, false);
        pixels.ReadPixels(new Rect(0, 0, overlay.width, overlay.height), 0, 0);
        pixels.Apply();
        var a = pixels.GetPixels32();
        var b = source.GetPixels32();
        if (b.Length != a.Length)
            throw new Exception("Source/calibration size mismatch");
        for (int i = 0; i < a.Length; i++)
        {
            float alpha = a[i].a / 255f;
            b[i] = new Color32((byte)Mathf.Lerp(b[i].r, a[i].r, alpha), (byte)Mathf.Lerp(b[i].g, a[i].g, alpha),
                               (byte)Mathf.Lerp(b[i].b, a[i].b, alpha), 255);
        }
        pixels.SetPixels32(b);
        pixels.Apply();
        File.WriteAllBytes(output, pixels.EncodeToPNG());
        RenderTexture.active = null;
        DestroyImmediate(pixels);
    }
}
}

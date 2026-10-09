#if UNITY_IOS
using System;
using System.IO;
using System.Diagnostics;
using System.Runtime.InteropServices;
using UnityEngine;
using UnityEngine.XR.ARFoundation;

public sealed class IOSMarkerTracker : MonoBehaviour
{
    [DllImport("__Internal")] static extern int ml_ios_current_frame(IntPtr session, int mode, int[] ids, int markers, double bw, double bh, double[] xy, int[] colors, int count, float[] result, float[] cameraWorld, double[] metadata);
    ARSession session; ARCameraManager manager; MarkerBoard board; MarkerInteraction content; Transform target;
    readonly MeasuredTrackingAccess tracking = new MeasuredTrackingAccess();
    readonly float[] cameraWorld = new float[16], output = new float[34];
    readonly double[] metadata = new double[8];
    double lastTimestamp, next; StreamWriter log; int mode, lastID = -1;
    bool focused = true, paused, paperDialEnabled, hasPaperDialReference, gestureMoved, pinchGesture, gestureInUI, gestureAccepted;
    Pose paperDialReference; Vector2 gestureStart; float initialDistance, initialScale;
    Rect uiPixelRect; float uiScale;

    void Start()
    {
        log = new StreamWriter(Path.Combine(Application.persistentDataPath, "marker-ios-" + DateTime.UtcNow.ToString("yyyyMMdd-HHmmss") + ".jsonl"));
        session = FindFirstObjectByType<ARSession>(); manager = FindFirstObjectByType<ARCameraManager>();
        board = JsonUtility.FromJson<MarkerBoard>(Resources.Load<TextAsset>("marker-board").text);
        target = new GameObject("Same-ARFrame paired interactive paper").transform;
        content = target.gameObject.AddComponent<MarkerInteraction>(); target.gameObject.SetActive(false);
        manager.frameReceived += Frame; ARSession.stateChanged += SessionStateChanged;
    }
    void SessionStateChanged(ARSessionStateChangedEventArgs args)
    {
        if (args.state != ARSessionState.SessionTracking) { tracking.Invalidate(); hasPaperDialReference = false; }
    }
    static bool Finite(double x) { return !double.IsNaN(x) && !double.IsInfinity(x); }
    static bool ValidPose(Pose pose)
    {
        var p = pose.position; var q = pose.rotation;
        if (!float.IsFinite(p.x) || !float.IsFinite(p.y) || !float.IsFinite(p.z) || !float.IsFinite(q.x) || !float.IsFinite(q.y) || !float.IsFinite(q.z) || !float.IsFinite(q.w)) return false;
        double n = q.x * q.x + q.y * q.y + q.z * q.z + q.w * q.w; return n >= .98 && n <= 1.02;
    }
    void Frame(ARCameraFrameEventArgs args)
    {
        double now = Time.realtimeSinceStartupAsDouble;
        tracking.SetReliable(focused && !paused && ARSession.state == ARSessionState.SessionTracking);
        if (!tracking.Reliable || now < next || !session || session.subsystem == null) return;
        next = now + .07;
        var clock = Stopwatch.StartNew();
        // The native bridge retains one actual ARFrame and takes pixels, K, pose and timestamp from it.
        int result = ml_ios_current_frame(session.subsystem.nativePtr, mode, board.ids, board.ids.Length, board.width, board.height, board.dot_xy, board.dot_colors, board.dot_xy.Length / 2, output, cameraWorld, metadata);
        clock.Stop();
        if (result < 0) { tracking.Invalidate(); UnityEngine.Debug.LogWarning("IOS MARKER frame unavailable=" + result); return; }
        if (metadata[0] == lastTimestamp) return;
        if (!Finite(metadata[0]) || metadata[0] <= 0 || metadata[0] < lastTimestamp || !Finite(metadata[7])) { tracking.Invalidate(); return; }
        lastTimestamp = metadata[0];
        bool seen = result == 1 && metadata[7] >= -.01 && metadata[7] < MeasuredTrackingAccess.InputSeconds;
        Pose world = default;
        if (seen)
        {
            var matrix = new Matrix4x4();
            for (int c = 0; c < 4; c++) for (int r = 0; r < 4; r++) matrix[r, c] = cameraWorld[c * 4 + r];
            var origin = FindFirstObjectByType<Unity.XR.CoreUtils.XROrigin>();
            if (origin) matrix = origin.transform.localToWorldMatrix * matrix;
            var sensor = new Pose(matrix.GetColumn(3), matrix.rotation);
            world = MarkerPoseMath.World(sensor, output); seen = ValidPose(sensor) && ValidPose(world);
            if (seen)
            {
                int id = (int)output[0];
                if (id != lastID) { lastID = id; tracking.BeginSelection(); content.ResetForSelection(); hasPaperDialReference = false; }
                target.SetPositionAndRotation(world.position, world.rotation);
            }
        }
        tracking.Observe(tracking.Epoch, Time.realtimeSinceStartupAsDouble - Math.Max(0, metadata[7]), seen);
        Present(Time.realtimeSinceStartupAsDouble);
        if (paperDialEnabled && seen && content.active && content.playing)
        {
            if (!hasPaperDialReference) { paperDialReference = world; hasPaperDialReference = true; }
            else
            {
                var relativeRotation = Quaternion.Inverse(paperDialReference.rotation) * world.rotation;
                var axis = relativeRotation * Vector3.right;
                var translation = Quaternion.Inverse(paperDialReference.rotation) * (world.position - paperDialReference.position);
                if (content.ApplyPaperDial(Mathf.Atan2(axis.y, axis.x), translation)) UnityEngine.Debug.Log("IOS PAPER DIAL accepted sameARFrame=" + metadata[0] + " lesson=" + content.ApplicationKind);
            }
        }
        log.WriteLine(JsonUtility.ToJson(new FrameRecord { timestamp = metadata[0], status = result, mode = mode, id = seen ? (int)output[0] : -1, processMs = clock.Elapsed.TotalMilliseconds, reprojection = seen ? output[1] : -1, decodedCorners = seen ? (int)output[26] : 0, observedDots = seen ? (int)output[27] : 0, cameraMetadata = metadata, sensorPose = cameraWorld, worldPosition = target.position, worldRotation = target.rotation, controlsAllowed = content.active, application = content.ApplicationKind.ToString(), primary = content.PrimaryParameter, secondary = content.SecondaryParameter, paperDialEnabled = paperDialEnabled })); log.Flush();
    }
    [Serializable] class FrameRecord
    {
        public double timestamp, processMs; public int status, mode, id, decodedCorners, observedDots;
        public float reprojection, primary, secondary; public double[] cameraMetadata; public float[] sensorPose;
        public Vector3 worldPosition; public Quaternion worldRotation; public bool controlsAllowed, paperDialEnabled; public string application;
    }
    void Present(double now)
    {
        if (!target) return;
        target.gameObject.SetActive(tracking.Visible(now)); content.active = tracking.Interactive(now);
        content.Status((mode == 0 ? "ArUco" : "Colored dots") + " ID " + lastID + "\n" + (content.active ? "Paper ready" : "Tracking lost: controls frozen") + " · " + content.ApplicationTitle);
    }
    void Update()
    {
        double now = Time.realtimeSinceStartupAsDouble;
        tracking.SetReliable(focused && !paused && ARSession.state == ARSessionState.SessionTracking); Present(now);
        if (Input.touchCount == 0) { pinchGesture = false; gestureInUI = false; gestureAccepted = false; return; }
        if (!tracking.Interactive(now) || paperDialEnabled) { gestureAccepted = false; return; }
        var touch = Input.GetTouch(0); var topLeftPixel = new Vector2(touch.position.x, Screen.height - touch.position.y);
        if (touch.phase == TouchPhase.Began) { gestureStart = touch.position; gestureMoved = false; gestureInUI = uiPixelRect.Contains(topLeftPixel); gestureAccepted = !gestureInUI; }
        if (!gestureAccepted || gestureInUI || uiPixelRect.Contains(topLeftPixel)) return;
        if (Input.touchCount == 2)
        {
            var second = Input.GetTouch(1);
            if (uiPixelRect.Contains(new Vector2(second.position.x, Screen.height - second.position.y))) return;
            float distance = Vector2.Distance(touch.position, second.position);
            if (!pinchGesture || touch.phase == TouchPhase.Began || second.phase == TouchPhase.Began) { initialDistance = distance; initialScale = content.scale; }
            pinchGesture = true; gestureMoved = true;
            if (initialDistance > 0) content.scale = Mathf.Clamp(initialScale * distance / initialDistance, .4f, 2);
            return;
        }
        if (pinchGesture) return;
        if (touch.phase == TouchPhase.Moved) { content.rotation += touch.deltaPosition.x * .2f; if (Vector2.Distance(gestureStart, touch.position) > 15) gestureMoved = true; }
        if (touch.phase == TouchPhase.Ended && !gestureMoved && Vector2.Distance(gestureStart, touch.position) < 15) content.Toggle();
    }
    void Rebaseline() { if (paperDialEnabled && content.active) { paperDialReference = new Pose(target.position, target.rotation); hasPaperDialReference = true; } else hasPaperDialReference = false; }
    void OnGUI()
    {
        if (!content) return;
        var safe = Screen.safeArea; uiScale = Mathf.Clamp(Screen.width / 390f, 1, 4);
        float top = Screen.height - safe.yMax, width = Mathf.Min(350, safe.width / uiScale - 16);
        uiPixelRect = new Rect(safe.x, top, (width + 16) * uiScale, 330 * uiScale);
        var previousMatrix = GUI.matrix; bool previousEnabled = GUI.enabled;
        GUI.matrix = Matrix4x4.TRS(new Vector3(safe.x, top, 0), Quaternion.identity, Vector3.one * uiScale);
        GUI.Box(new Rect(4, 4, width + 8, 316), "");
        if (GUI.Button(new Rect(10, 10, width * .58f, 36), mode == 0 ? "ArUco → Colored dots" : "Colored dots → ArUco")) { mode = 1 - mode; tracking.BeginSelection(); hasPaperDialReference = false; }
        bool ready = tracking.Interactive(Time.realtimeSinceStartupAsDouble) && content.active;
        GUI.enabled = ready;
        if (GUI.Button(new Rect(16 + width * .58f, 10, width * .42f - 6, 36), "Next lesson")) { content.NextApplication(); Rebaseline(); }
        GUI.Label(new Rect(10, 50, width, 26), content.ApplicationTitle);
        float buttonWidth = (width - 12) / 3;
        if (GUI.Button(new Rect(10, 78, buttonWidth, 36), content.playing ? "Pause" : "Play")) content.Toggle();
        if (GUI.Button(new Rect(16 + buttonWidth, 78, buttonWidth, 36), "Reset")) { content.Reset(); Rebaseline(); }
        if (GUI.Button(new Rect(22 + buttonWidth * 2, 78, buttonWidth, 36), ActionTitle(content.ApplicationKind))) content.Explode();
        if (GUI.Button(new Rect(10, 120, width, 36), paperDialEnabled ? "Paper dial ON · tap to use sliders" : "Use paper rotation / movement as input")) { paperDialEnabled = !paperDialEnabled; Rebaseline(); }
        float pMin, pMax, sMin, sMax; string pTitle, sTitle;
        Ranges(content.ApplicationKind, out pMin, out pMax, out sMin, out sMax, out pTitle, out sTitle);
        GUI.enabled = ready && !paperDialEnabled;
        GUI.Label(new Rect(10, 164, width, 24), pTitle + ": " + content.PrimaryParameter.ToString("0.00"));
        float primary = GUI.HorizontalSlider(new Rect(10, 190, width, 22), content.PrimaryParameter, pMin, pMax);
        GUI.Label(new Rect(10, 216, width, 24), sTitle + ": " + content.SecondaryParameter.ToString("0.00"));
        float secondary = GUI.HorizontalSlider(new Rect(10, 242, width, 22), content.SecondaryParameter, sMin, sMax);
        if (ready && !paperDialEnabled && (Mathf.Abs(primary - content.PrimaryParameter) > .0001f || Mathf.Abs(secondary - content.SecondaryParameter) > .0001f)) content.SetParameters(primary, secondary);
        GUI.enabled = true;
        GUI.Label(new Rect(10, 274, width, 38), !ready ? "Point at the paper · interaction frozen" : paperDialEnabled ? "Rotate / move the sheet to change the lesson" : "Outside panel: drag rotate · pinch scale · tap pause");
        GUI.matrix = previousMatrix; GUI.enabled = previousEnabled;
    }
    static string ActionTitle(PaperApplication app)
    {
        switch (app) { case PaperApplication.Geometry: return "Net"; case PaperApplication.FunctionGraph: return "Tangent"; case PaperApplication.InclinedPlane: return "Forces"; case PaperApplication.Pendulum: return "Energy"; case PaperApplication.Circuit: return "Switch"; case PaperApplication.Vectors: return "Projection"; default: return "Explore"; }
    }
    static void Ranges(PaperApplication app, out float pMin, out float pMax, out float sMin, out float sMax, out string pTitle, out string sTitle)
    {
        pMin = 0; pMax = 1; sMin = 0; sMax = 1; pTitle = "Size"; sTitle = "Slice height";
        switch (app)
        {
            case PaperApplication.Solar: pMin = .5f; pMax = 1.4f; sMax = 45; pTitle = "Orbit radius (model units)"; sTitle = "Inclination (degrees)"; break;
            case PaperApplication.Geometry: pTitle = "Cube size"; sTitle = "Section height fraction"; break;
            case PaperApplication.FunctionGraph: pMin = .1f; pMax = 2; sMin = .5f; sMax = 4; pTitle = "Amplitude A"; sTitle = "Frequency k"; break;
            case PaperApplication.InclinedPlane: pMin = 5; pMax = 65; sMax = .8f; pTitle = "Angle (degrees)"; sTitle = "Friction coefficient"; break;
            case PaperApplication.Pendulum: pMin = .2f; pMax = 1.2f; sMin = 5; sMax = 25; pTitle = "Model length (m)"; sTitle = "Initial angle (degrees)"; break;
            case PaperApplication.Circuit: pMin = 1; pMax = 12; sMin = 10; sMax = 1000; pTitle = "Voltage (V)"; sTitle = "Resistance (ohms)"; break;
            case PaperApplication.Vectors: pMin = -180; pMax = 180; sMin = .25f; sMax = 2; pTitle = "Vector B angle (degrees)"; sTitle = "Vector B magnitude"; break;
            case PaperApplication.Binomial: sMax = 8; pTitle = "Probability p"; sTitle = "Selected outcome k (rounded)"; break;
        }
    }
    void OnApplicationFocus(bool value) { focused = value; if (!value) { tracking.Invalidate(); hasPaperDialReference = false; } }
    void OnApplicationPause(bool value) { paused = value; if (value) { tracking.Invalidate(); hasPaperDialReference = false; } }
    void OnDestroy() { log?.Dispose(); if (manager) manager.frameReceived -= Frame; ARSession.stateChanged -= SessionStateChanged; }
}
#endif

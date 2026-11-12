using System;
using System.Collections.Generic;
using UnityEngine;
#if ENABLE_INPUT_SYSTEM
using UnityEngine.InputSystem;
#endif
namespace MRClass
{
public sealed class LabApp : MonoBehaviour
{
    public LabState State = new LabState();
    public Transform Stage;
    public Studies Content;
    public Camera View;
    public bool PaperMode, ShowMenu = true;
    public string AnchorStatus = "Manual controller placement (not image tracking)";
    public bool Preview;
    public float Clock;
    MarkerInput marker;
    RelayInput relay;
    Transform menu;
    TextMesh status;
    LineRenderer ray;
    bool lastTrigger, placed, wasWiping;
    float nextStatus, nextWipeSync;
    readonly List<Collider> buttons = new List<Collider>();
    readonly List<Action> actions = new List<Action>();
    ReplayInput replay;
    public void Initialize(bool preview = false)
    {
        Preview = preview;
        Application.targetFrameRate = 72;
        RenderSettings.ambientMode = UnityEngine.Rendering.AmbientMode.Flat;
        RenderSettings.ambientLight = new Color(.7f, .75f, .8f);
        var light = new GameObject("Authored model illumination").AddComponent<Light>();
        light.type = LightType.Directional;
        light.intensity = 1.1f;
        light.transform.rotation = Quaternion.Euler(35, -35, 0);
        var rig = FindFirstObjectByType<OVRCameraRig>();
        View = rig ? rig.centerEyeAnchor.GetComponent<Camera>() : Camera.main;
        if (!View)
        {
            View = new GameObject("Preview camera").AddComponent<Camera>();
            View.tag = "MainCamera";
            View.transform.position = new Vector3(0, 1.25f, -1.1f);
            View.transform.LookAt(new Vector3(0, 1.05f, .7f));
            View.backgroundColor = new Color(.035f, .055f, .085f);
            View.clearFlags = CameraClearFlags.SolidColor;
            View.nearClipPlane = .025f;
        }
        Stage = new GameObject("Shared interaction origin").transform;
        Stage.SetParent(transform, false);
        Stage.position = new Vector3(0, 1.05f, .7f);
        Content = new GameObject("Class components").AddComponent<Studies>();
        Content.transform.SetParent(Stage, false);
        if (!preview)
        {
            relay = gameObject.AddComponent<RelayInput>();
            relay.Received = s =>
            {
                State = s;
                Apply();
            };
            relay.TextureReceived = t => Content.SetTexture(t);
        }
        if (!preview && Application.platform != RuntimePlatform.Android)
        {
            string folder = Environment.GetEnvironmentVariable("MR_CLASS_CAPTURE");
            if (!string.IsNullOrEmpty(folder))
            {
                replay = gameObject.AddComponent<ReplayInput>();
                replay.Load(folder, this);
            }
        }
        menu = new GameObject("World menu").transform;
        menu.SetParent(transform, false);
        menu.position = new Vector3(-.85f, 1.4f, 1);
        menu.rotation = Quaternion.LookRotation(menu.position - View.transform.position, Vector3.up);
        Geometry.Text(menu, "MR CLASS / BUILDING BLOCKS", new Vector3(0, .3f, 0), .003f);
        for (int i = 0; i < 6; i++)
        {
            int n = i;
            Button(Studies.Names[i], new Vector3(0, .19f - i * .075f, 0), () => Select(n));
        }
        Button("Action", new Vector3(-.12f, -.31f, 0), Primary, .21f);
        Button("Reset", new Vector3(.12f, -.31f, 0), ResetAction, .21f);
        Button("Paper / Manual", new Vector3(0, -.39f, 0), () => SetPaper(!PaperMode));
        status = Geometry.Text(menu, "", new Vector3(0, -.54f, 0), .002f);
        ray = Geometry.Line(transform, "Controller ray", new Vector3[2], Color.cyan, .002f);
        ray.useWorldSpace = true;
        ray.enabled = false;
        Apply();
        Debug.Log(
            "MR_CLASS_READY studies=6 input=controller+optional-LAN paper=camera-on-explicit-selection");
    }
    void Start()
    {
        if (!Stage)
            Initialize();
#if UNITY_ANDROID && !UNITY_EDITOR
        using (var player = new AndroidJavaClass("com.unity3d.player.UnityPlayer")) using (
            var activity = player.GetStatic<AndroidJavaObject>(
                "currentActivity")) using (var intent = activity.Call<AndroidJavaObject>("getIntent"))
        {
            if (intent.Call<bool>("getBooleanExtra", "classPaper", false))
                SetPaper(true);
        }
#endif
    }
    void Button(string label, Vector3 p, Action a, float width = .46f)
    {
        var g = Geometry.Shape(menu, label, PrimitiveType.Cube, p, new Vector3(width, .06f, .018f),
                               new Color(.04f, .1f, .15f));
        var c = g.AddComponent<BoxCollider>();
        buttons.Add(c);
        actions.Add(a);
        Geometry.Text(menu, label, p + new Vector3(0, 0, -.013f), .0026f);
    }
    public void Select(int index)
    {
        State.study = Mathf.Clamp(index, 0, 5);
        State.ResetAction();
        if (PaperMode && marker)
            marker.Invalidate();
        Changed();
    }
    public void Primary()
    {
        if (!InputAllowed())
            return;
        State.Primary();
        Changed();
    }
    public void ResetAction()
    {
        State.ResetAction();
        Changed();
    }
    public void Changed()
    {
        State.Validate();
        Apply();
        if (relay)
            relay.Send(State);
    }
    public void Apply()
    {
        if (Content)
        {
            // Held presentation must not consume new interaction/animation without a fresh paper pose.
            if (InputAllowed())
                Content.Apply(State, Clock);
            Content.gameObject.SetActive(
                (!PaperMode || (marker && marker.Visible)) &&
                (Application.platform != RuntimePlatform.Android || OVRPlugin.positionTracked));
        }
        if (status)
            status.text = AnchorStatus + "\n" + (relay ? relay.Status : Studies.Bounds[State.study]);
    }
    public bool InputAllowed() => !PaperMode || (marker && marker.Fresh);
    public void SetPaper(bool value)
    {
        if (Application.platform != RuntimePlatform.Android)
        {
            AnchorStatus = "Live paper mode requires Quest; replay is camera-only";
            return;
        }
        PaperMode = value;
        if (value)
        {
            if (!marker)
                marker = gameObject.AddComponent<MarkerInput>();
            marker.enabled = true;
            AnchorStatus = "Waiting for fresh measured paper";
        }
        else
        {
            if (marker)
                marker.enabled = false;
            AnchorStatus = "Manual controller placement (not image tracking)";
            Stage.localScale = Vector3.one;
            placed = false;
        }
        Apply();
    }
    void Update()
    {
        if (!Stage || Preview)
            return;
        if (InputAllowed())
            Clock += Time.deltaTime;
        if (PaperMode && marker)
        {
            if (marker.Visible)
            {
                Stage.SetPositionAndRotation(marker.Pose.position, marker.Pose.rotation);
                Stage.localScale = Vector3.one * .22f;
            }
            AnchorStatus = marker.Status;
        }
        else if (Application.platform == RuntimePlatform.Android)
        {
            if (!placed && OVRPlugin.positionTracked)
            {
                Vector3 flat = Vector3.ProjectOnPlane(View.transform.forward, Vector3.up).normalized;
                Stage.position = View.transform.position + flat * 1.2f - Vector3.up * .35f;
                Stage.rotation = Quaternion.LookRotation(flat);
                placed = true;
            }
        }
        if (OVRInput.GetDown(OVRInput.Button.One))
            Primary();
        if (OVRInput.GetDown(OVRInput.Button.Two))
            ResetAction();
        if (OVRInput.GetDown(OVRInput.Button.Three))
            Select((State.study + 5) % 6);
        if (OVRInput.GetDown(OVRInput.Button.Four))
            Select((State.study + 1) % 6);
        if (OVRInput.GetDown(OVRInput.Button.Start))
            ShowMenu = !ShowMenu;
        bool didWipe = false;
        bool pose = Application.platform == RuntimePlatform.Android &&
                    OVRInput.GetControllerPositionTracked(OVRInput.Controller.RTouch);
        ray.enabled = pose;
        if (pose)
        {
            var rig = FindFirstObjectByType<OVRCameraRig>();
            var tr = rig ? rig.trackingSpace : null;
            Vector3 p = OVRInput.GetLocalControllerPosition(OVRInput.Controller.RTouch);
            Quaternion q = OVRInput.GetLocalControllerRotation(OVRInput.Controller.RTouch);
            if (tr)
            {
                p = tr.TransformPoint(p);
                q = tr.rotation * q;
            }
            Vector3 dir = q * Vector3.forward;
            ray.SetPosition(0, p);
            ray.SetPosition(1, p + dir * 3);
            bool trigger = OVRInput.Get(OVRInput.Button.SecondaryIndexTrigger);
            if (trigger && !lastTrigger && ShowMenu)
            {
                float nearest = 4;
                int hit = -1;
                for (int i = 0; i < buttons.Count; i++)
                    if (buttons[i].Raycast(new Ray(p, dir), out var h, 4) && h.distance < nearest)
                    {
                        nearest = h.distance;
                        hit = i;
                    }
                if (hit >= 0)
                    actions[hit]();
            }
            lastTrigger = trigger;
            if (State.study == (int)Study.Portal && InputAllowed() &&
                OVRInput.Get(OVRInput.Button.SecondaryHandTrigger))
            {
                Vector3 local = Stage.InverseTransformPoint(p);
                if (Mathf.Abs(local.z) < .18f && Mathf.Abs(local.y) < .5f)
                {
                    State.reveal = Mathf.Clamp01((local.x + .45f) / .9f);
                    didWipe = true;
                    Apply();
                    if (relay && Time.realtimeSinceStartup > nextWipeSync)
                    {
                        nextWipeSync = Time.realtimeSinceStartup + .1f;
                        relay.Send(State);
                    }
                }
            }
            if (!PaperMode && OVRInput.Get(OVRInput.Button.PrimaryHandTrigger))
            {
                Stage.position = p;
                Stage.rotation =
                    Quaternion.LookRotation(Vector3.ProjectOnPlane(p - View.transform.position, Vector3.up));
            }
        }
        if (wasWiping && !didWipe && relay)
            relay.Send(State);
        wasWiping = didWipe;
#if ENABLE_INPUT_SYSTEM
        if (Keyboard.current != null)
        {
            var k = Keyboard.current;
            if (k.rightArrowKey.wasPressedThisFrame)
                Select((State.study + 1) % 6);
            if (k.leftArrowKey.wasPressedThisFrame)
                Select((State.study + 5) % 6);
            if (k.spaceKey.wasPressedThisFrame)
                Primary();
            if (k.rKey.wasPressedThisFrame)
                ResetAction();
        }
#endif
        menu.gameObject.SetActive(ShowMenu);
        Apply();
        if (Time.realtimeSinceStartup > nextStatus)
        {
            nextStatus = Time.realtimeSinceStartup + 2;
            Debug.Log("MR_CLASS_FRAME frame=" + Time.frameCount + " study=" + State.study +
                      " revision=" + State.revision + " headTracked=" + OVRPlugin.positionTracked +
                      " hmd=" + OVRManager.isHmdPresent + " paper=" + PaperMode +
                      " relay=" + (relay ? relay.Status : "offline"));
        }
    }
    void OnGUI()
    {
        if (Application.platform == RuntimePlatform.Android || Preview)
            return;
        GUILayout.BeginArea(new Rect(15, 15, 330, Screen.height - 30), GUI.skin.box);
        GUILayout.Label("MR CLASS / " + (replay ? "RECORDED SENSOR REPLAY" : "EDITOR / SYNTHETIC ROOM"));
        GUILayout.Label(Studies.Bounds[State.study]);
        for (int i = 0; i < 6; i++)
            if (GUILayout.Button(Studies.Names[i]))
                Select(i);
        if (GUILayout.Button("Action / next step"))
            Primary();
        if (GUILayout.Button("Reset action"))
            ResetAction();
        if (replay)
        {
            if (GUILayout.Button(replay.Playing ? "Pause source" : "Play source"))
                replay.Playing = !replay.Playing;
            float t = GUILayout.HorizontalSlider(replay.Time, 0, replay.Duration);
            if (Mathf.Abs(t - replay.Time) > .01f)
                replay.Seek(t);
            GUILayout.Label(replay.Time.ToString("F2") + "s / " + replay.Data.id);
        }
        GUILayout.Label(relay ? relay.Status : "Offline");
        GUILayout.Label("Controller placement is manual. Paper mode uses the existing native marker " +
                        "detector. No live AI is claimed.");
        GUILayout.EndArea();
    }
}
}

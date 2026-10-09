#if UNITY_EDITOR
using System;
using System.IO;
using System.Reflection;
using UnityEditor;
using UnityEngine;
// Run in an isolated Unity project, never an existing physical scene. These are authored
// renderer/geometry checks, not live tracker or stereo acceptance.
public static class PaperApplicationVisualChecks
{
    public static void Run()
    {
        string output = Environment.GetEnvironmentVariable("PAPER_VISUAL_OUTPUT") ?? "/tmp/openclaw/paper-visual-checks";
        Directory.CreateDirectory(output);
        var root = new GameObject("Content test fixture"); var app = root.AddComponent<MarkerInteraction>();
        typeof(MarkerInteraction).GetMethod("Awake", BindingFlags.Instance | BindingFlags.NonPublic).Invoke(app, null);
        app.active = true;
        var cameraObject = new GameObject("Content inspection camera"); var camera = cameraObject.AddComponent<Camera>();
        camera.transform.position = new Vector3(.07f, .025f, -.27f); camera.transform.LookAt(new Vector3(0, .035f, -.012f));
        camera.clearFlags = CameraClearFlags.SolidColor; camera.backgroundColor = new Color(.035f, .05f, .085f); camera.fieldOfView = 55; camera.nearClipPlane = .01f;
        camera.targetTexture = new RenderTexture(1200, 1200, 24);
        foreach (PaperApplication kind in Enum.GetValues(typeof(PaperApplication)))
        {
            app.SetApplicationForSelection(kind); Render(app, .05f);
            if (kind == PaperApplication.FunctionGraph) {
                var l = root.transform.Find("Interactive paper application").Find("y = A sin(kx)").GetComponent<LineRenderer>();
                Debug.Log("GRAPH QA count="+l.positionCount+" p25="+l.GetPosition(25)+" p75="+l.GetPosition(75)+" enabled="+l.enabled+" active="+l.gameObject.activeInHierarchy+" bounds="+l.bounds);
                var mesh = root.transform.Find("Interactive paper application").Find("Executable 3D function tube").GetComponent<MeshFilter>().sharedMesh;
                Require(mesh.vertexCount == 808 && mesh.triangles.Length == 4800, "nonempty executable function tube topology");
                Require(mesh.bounds.size.y > .037f, "function graph nonflat amplitude");
                Debug.Log("GRAPH TUBE vertices="+mesh.vertexCount+" bounds="+mesh.bounds);
            }
            Capture(camera, Path.Combine(output, kind.ToString().ToLowerInvariant() + ".png"));
            if (kind == PaperApplication.Geometry)
            {
                CheckClosedCube(root.transform);
                app.Explode(); for (int i = 0; i < 20; i++) Render(app, .05f);
                CheckOpenNet(root.transform); Capture(camera, Path.Combine(output, "geometry-unfolded.png"));
                app.scale = 1.5f; Render(app, .05f);
                var scene = root.transform.Find("Interactive paper application");
                float side = Vector3.Distance(scene.Find("Cube face 1").TransformPoint(new Vector3(-.015f, 0, 0)), scene.Find("Cube face 1").TransformPoint(new Vector3(.015f, 0, 0)));
                Require(Mathf.Abs(side - .054f) < .000001f, "scaled displayed cube edge");
            }
            if (kind == PaperApplication.Circuit) {
                app.Explode(); Render(app, .05f);
                for (int i = 0; i < 10; i++) Require(!root.transform.Find("Interactive paper application").Find("Illustrative charge " + i).gameObject.activeSelf, "open switch stops illustrative current");
                Capture(camera, Path.Combine(output, "circuit-open.png"));
            }
            if (kind == PaperApplication.Vectors) {
                app.SetParameters(150, 1); app.Explode(); Render(app, .05f);
                var projection = root.transform.Find("Interactive paper application").Find("Signed projection of B on A").GetComponent<LineRenderer>();
                Require(projection.GetPosition(1).x < projection.GetPosition(0).x, "negative vector projection points left");
                Capture(camera, Path.Combine(output, "vectors-negative-projection.png"));
            }
            if (kind == PaperApplication.Binomial) {
                foreach (int endpoint in new[] { 0, 1 }) {
                    app.SetParameters(endpoint, endpoint == 0 ? 0 : 8); Render(app, .05f);
                    for (int k = 0; k <= 8; k++) {
                        var bar = root.transform.Find("Interactive paper application").Find("Binomial probability k=" + k);
                        Require(bar.gameObject.activeSelf == (k == (endpoint == 0 ? 0 : 8)), "endpoint exactly one nonzero probability bar");
                        Require((k == (endpoint == 0 ? 0 : 8)) ? Mathf.Abs(bar.localScale.y - .055f) < 1e-6f : bar.localScale.y == 0, "endpoint zero bars have true zero height");
                    }
                    Capture(camera, Path.Combine(output, "binomial-p" + endpoint + ".png"));
                }
            }
            var contentScene = root.transform.Find("Interactive paper application");
            Vector3 beforeScale = contentScene.localScale; Quaternion beforeRotation = contentScene.localRotation;
            float beforeTime = app.SimulationTime; app.active = false; app.scale = 1.4f; app.rotation = 35;
            Require(!app.NextApplication() && !app.SetParameters(1, 1), "tracking lost rejects semantic content input");
            typeof(MarkerInteraction).GetMethod("Update", BindingFlags.Instance | BindingFlags.NonPublic).Invoke(app, null);
            Require(contentScene.localScale == beforeScale && contentScene.localRotation == beforeRotation && app.SimulationTime == beforeTime, "tracking lost freezes transforms and time");
            float beforePrimary = app.PrimaryParameter, beforeSecondary = app.SecondaryParameter;
            Require(!app.ApplyPaperDial(1, new Vector3(.1f, 0, 0)) && app.PrimaryParameter == beforePrimary && app.SecondaryParameter == beforeSecondary, "lost tracking rejects paper dial without mutation");
            app.active = true;
            Require(app.ApplyPaperDial(0, Vector3.zero), "first calibrated paper dial changes topic input");
            Require(!app.ApplyPaperDial(0, Vector3.zero), "identical paper input idempotent");
            Require(!app.ApplyPaperDial(.001f, new Vector3(.0002f, 0, 0)), "sub-bin pose jitter idempotent");
            beforePrimary = app.PrimaryParameter; beforeSecondary = app.SecondaryParameter;
            Require(!app.ApplyPaperDial(float.NaN, Vector3.zero) && !app.ApplyPaperDial(0, new Vector3(float.PositiveInfinity, 0, 0)), "nonfinite paper inputs rejected");
            Require(app.PrimaryParameter == beforePrimary && app.SecondaryParameter == beforeSecondary, "invalid paper inputs preserve model parameters");
            Require(app.ApplyPaperDial(float.MaxValue, new Vector3(float.MaxValue, 0, 0)), "extreme finite paper inputs bounded and accepted");
        }
        Debug.Log("PAPER VISUAL PASS: eight applications, negative projection, exact probability endpoints, closed cube corners, hinged open net, scaled displayed edge; thirteen authored screenshots, not device evidence. output=" + output);
        UnityEngine.Object.DestroyImmediate(root); UnityEngine.Object.DestroyImmediate(cameraObject);
    }
    static void Render(MarkerInteraction app, float dt) { typeof(MarkerInteraction).GetMethod("Render", BindingFlags.Instance | BindingFlags.NonPublic).Invoke(app, new object[] { dt }); }
    static void Require(bool value, string name) { if (!value) throw new Exception("Paper visual geometry assertion failed: " + name); }
    static void CheckClosedCube(Transform root)
    {
        var scene = root.Find("Interactive paper application");
        for (int face = 1; face <= 6; face++)
        {
            var f = scene.Find("Cube face " + face);
            foreach (float x in new[] { -.015f, .015f }) foreach (float y in new[] { -.015f, .015f })
            {
                Vector3 v = f.localPosition + f.localRotation * new Vector3(x, y, 0);
                Require(Mathf.Abs(Mathf.Abs(v.x) - .015f) < 1e-6f, "closed cube x vertex");
                Require(Mathf.Abs(Mathf.Abs(v.y) - .015f) < 1e-6f, "closed cube y vertex");
                Require(Mathf.Min(Mathf.Abs(v.z + .004f), Mathf.Abs(v.z + .034f)) < 1e-6f, "closed cube z vertex");
            }
        }
    }
    static void CheckOpenNet(Transform root)
    {
        var scene = root.Find("Interactive paper application");
        Vector3[] expected = { new Vector3(0, 0, -.004f), new Vector3(0, .03f, -.004f), new Vector3(-.03f, 0, -.004f), new Vector3(0, -.03f, -.004f), new Vector3(.03f, 0, -.004f), new Vector3(0, .06f, -.004f) };
        for (int face = 1; face <= 6; face++) Require(Vector3.Distance(scene.Find("Cube face " + face).localPosition, expected[face - 1]) < 1e-6f, "flat net panel centre");
    }
    static void Capture(Camera camera, string filename)
    {
        camera.Render(); var previous = RenderTexture.active; RenderTexture.active = camera.targetTexture;
        var texture = new Texture2D(1200, 1200, TextureFormat.RGB24, false); texture.ReadPixels(new Rect(0, 0, 1200, 1200), 0, 0); texture.Apply();
        File.WriteAllBytes(filename, texture.EncodeToPNG()); UnityEngine.Object.DestroyImmediate(texture); RenderTexture.active = previous;
    }
}
#endif

using System;
using System.Collections.Generic;
using UnityEngine;

public enum PaperApplication { Solar, Geometry, FunctionGraph, InclinedPlane, Pendulum, Circuit, Vectors, Binomial }

// Executable authored content in marker-local metres. Negative local Z is above the paper.
// The tracker alone owns `active`: no teaching interaction or animation advances while lost.
public sealed class MarkerInteraction : MonoBehaviour
{
    public bool active, playing = true, exploded;
    public float speed = 1, scale = 1, rotation;
    public PaperApplication ApplicationKind { get; private set; } = PaperApplication.Solar;
    public float PrimaryParameter { get; private set; } = 1;
    public float SecondaryParameter { get; private set; } = 1;
    public float SimulationTime { get { return time; } }
    public string ApplicationTitle { get { return Titles[(int)ApplicationKind]; } }
    public static readonly string[] Titles = { "Solar orbit", "Cube net + section", "Function laboratory", "Inclined plane", "Pendulum laboratory", "Circuit laboratory", "Vector laboratory", "Binomial probability" };
    float time, unfold, paperFold = -1;
    Transform scene, sun, planet, cube, probe, bob, pivot, ramp, block, section;
    Transform[] faces, electrons, probabilityBars;
    TextMesh label, lesson;
    Mesh graphTube;
    LineRenderer[] vectorHeads;
    LineRenderer curve, tangent, stringLine, orbit, forceGravity, forceNormal, forceFriction, circuitWire, switchLine, vectorA, vectorB, vectorSum, vectorTail, vectorProjection;
    string trackerStatus = "";
    readonly List<Material> materials = new List<Material>();
    readonly List<Mesh> meshes = new List<Mesh>();
    readonly Vector3[] graphPoints = new Vector3[101];
    bool dirty = true;

    void Awake()
    {
        scene = new GameObject("Interactive paper application").transform;
        scene.SetParent(transform, false);
        label = Text("Tracking and controls", transform, new Vector3(0, -.077f, -.003f), .0014f);
        lesson = Text("Live mathematical model", transform, new Vector3(0, .077f, -.003f), .0015f);
        ResetForSelection(); Build();
    }
    Material Surface(Color color)
    {
        var shader = Shader.Find("MarkerLab/Surface");
        if (!shader) shader = Shader.Find("Unlit/Color");
        var material = new Material(shader); material.color = color; materials.Add(material); return material;
    }
    Transform Shape(PrimitiveType type, string name, Color color, Vector3 position, Vector3 size, Transform parent = null)
    {
        var g = GameObject.CreatePrimitive(type); g.name = name; g.transform.SetParent(parent ? parent : scene, false);
        var collider = g.GetComponent<Collider>(); if (collider) DisposeOwned(collider);
        g.GetComponent<Renderer>().sharedMaterial = Surface(color); g.transform.localPosition = position; g.transform.localScale = size; return g.transform;
    }
    TextMesh Text(string name, Transform parent, Vector3 position, float size)
    {
        var g = new GameObject(name); g.transform.SetParent(parent, false); g.transform.localPosition = position;
        var t = g.AddComponent<TextMesh>(); t.fontSize = 40; t.characterSize = size; t.anchor = TextAnchor.MiddleCenter; t.alignment = TextAlignment.Center; t.color = Color.white; return t;
    }
    LineRenderer Line(string name, Color color, int points = 2, float width = .0007f)
    {
        var l = new GameObject(name).AddComponent<LineRenderer>(); l.transform.SetParent(scene, false); l.useWorldSpace = false;
        l.positionCount = points; l.widthMultiplier = width; l.sharedMaterial = Surface(color); return l;
    }
    void Segment(LineRenderer line, Vector3 start, Vector3 end) { line.SetPosition(0, start); line.SetPosition(1, end); }
    void Clear()
    {
        for (int i = scene.childCount - 1; i >= 0; i--) { var child = scene.GetChild(i); child.gameObject.SetActive(false); DisposeOwned(child.gameObject); }
        foreach (var mesh in meshes) if (mesh) DisposeOwned(mesh); meshes.Clear();
        foreach (var material in materials) if (material) DisposeOwned(material); materials.Clear();
    }
    void Build()
    {
        Clear(); time = 0; unfold = 0; dirty = true;
        lesson.transform.localPosition = new Vector3(0, .077f, -.003f);
        switch (ApplicationKind)
        {
            case PaperApplication.Solar:
                sun = Shape(PrimitiveType.Sphere, "Sun", new Color(1, .72f, .15f), new Vector3(0, 0, -.024f), Vector3.one * .022f);
                planet = Shape(PrimitiveType.Sphere, "Orbiting planet", new Color(.15f, .6f, 1), Vector3.zero, Vector3.one * .012f);
                orbit = Line("Orbital path", new Color(.45f, .72f, .84f), 97);
                cube = Shape(PrimitiveType.Cube, "Depth and rotation reference", new Color(.82f, .29f, 1), new Vector3(-.035f, -.04f, -.016f), Vector3.one * .013f);
                break;
            case PaperApplication.Geometry:
                // Six separately hinged, genuinely planar 3D mesh faces; flat net spans 90 x 120 mm.
                faces = new Transform[6];
                for (int i = 0; i < 6; i++) faces[i] = Panel("Cube face " + (i + 1), Color.HSVToRGB(i / 6f, .65f, .95f));
                section = Shape(PrimitiveType.Cube, "Horizontal cross-section", new Color(1, .86f, .1f), Vector3.zero, new Vector3(.031f, .031f, .0007f));
                break;
            case PaperApplication.FunctionGraph:
                Segment(Line("X axis", Color.white), new Vector3(-.055f, 0, -.004f), new Vector3(.055f, 0, -.004f));
                Segment(Line("Y axis", Color.white), new Vector3(0, -.046f, -.004f), new Vector3(0, .046f, -.004f));
                curve = Line("y = A sin(kx)", new Color(.2f, .85f, 1), 101, .001f);
                curve.enabled = false; // Mathematical samples retained; explicit 3D tube is the visible graph.
                var graph = new GameObject("Executable 3D function tube"); graph.transform.SetParent(scene, false);
                graphTube = new Mesh { name = "Function tube" }; meshes.Add(graphTube);
                graph.AddComponent<MeshFilter>().sharedMesh = graphTube;
                graph.AddComponent<MeshRenderer>().sharedMaterial = Surface(new Color(.2f, .85f, 1));
                tangent = Line("Analytic tangent", new Color(1, .65f, .15f), 2, .001f);
                probe = Shape(PrimitiveType.Sphere, "Sample point", Color.yellow, Vector3.zero, Vector3.one * .004f);
                break;
            case PaperApplication.InclinedPlane:
                ramp = Shape(PrimitiveType.Cube, "Inclined teaching plane", new Color(.15f, .55f, .65f), Vector3.zero, new Vector3(.085f, .035f, .003f));
                block = Shape(PrimitiveType.Cube, "Sliding block", new Color(1, .6f, .1f), Vector3.zero, new Vector3(.012f, .012f, .012f));
                forceGravity = Line("Gravity vector", new Color(1, .25f, .25f), 2, .0012f);
                forceNormal = Line("Normal vector", new Color(.2f, .9f, .4f), 2, .0012f);
                forceFriction = Line("Friction vector", Color.yellow, 2, .0012f);
                break;
            case PaperApplication.Vectors:
                vectorHeads = new[] { Line("A arrowhead", new Color(.3f, 1, .4f), 3), Line("B arrowhead", new Color(1, .5f, .15f), 3), Line("Sum arrowhead", new Color(.2f, .8f, 1), 3), Line("Projection arrowhead", Color.yellow, 3) };
                vectorA = Line("Vector A", new Color(.3f, 1, .4f), 2, .0012f);
                vectorB = Line("Vector B", new Color(1, .5f, .15f), 2, .0012f);
                vectorSum = Line("Vector A plus B", new Color(.2f, .8f, 1), 2, .0012f);
                vectorTail = Line("Head-to-tail translated B", new Color(1, .5f, .15f), 2, .0006f);
                vectorProjection = Line("Signed projection of B on A", Color.yellow, 2, .002f);
                Segment(Line("Vector reference horizontal", Color.gray, 2, .0003f), new Vector3(-.06f, 0, -.004f), new Vector3(.06f, 0, -.004f));
                Segment(Line("Vector reference vertical", Color.gray, 2, .0003f), new Vector3(0, -.05f, -.004f), new Vector3(0, .05f, -.004f));
                Shape(PrimitiveType.Sphere, "Vector origin", Color.white, new Vector3(0, 0, -.012f), Vector3.one * .003f);
                break;
            case PaperApplication.Binomial:
                probabilityBars = new Transform[9];
                for (int k = 0; k <= 8; k++) {
                    probabilityBars[k] = Shape(PrimitiveType.Cube, "Binomial probability k=" + k, new Color(.2f, .75f, 1), Vector3.zero, new Vector3(.008f, .01f, .005f));
                    var tick = Text("Outcome " + k, scene, new Vector3(-.048f + k * .012f, -.008f, -.006f), .001f); tick.text = k.ToString();
                }
                Segment(Line("Probability baseline", Color.white, 2, .0004f), new Vector3(-.055f, 0, -.006f), new Vector3(.055f, 0, -.006f));
                break;
            case PaperApplication.Circuit:
                circuitWire = Line("Circuit wire", new Color(.3f, .8f, 1), 6, .0012f);
                circuitWire.SetPositions(new[] { new Vector3(-.008f, -.025f, -.012f), new Vector3(-.037f, -.025f, -.012f), new Vector3(-.037f, .025f, -.012f), new Vector3(.037f, .025f, -.012f), new Vector3(.037f, -.025f, -.012f), new Vector3(.008f, -.025f, -.012f) });
                Shape(PrimitiveType.Cube, "Voltage source", new Color(.2f, .75f, .35f), new Vector3(-.037f, 0, -.014f), new Vector3(.012f, .023f, .009f));
                var resistor = Shape(PrimitiveType.Cylinder, "Resistor", new Color(.8f, .5f, .25f), new Vector3(0, .025f, -.015f), new Vector3(.008f, .015f, .008f));
                resistor.localRotation = Quaternion.Euler(0, 0, 90);
                switchLine = Line("Interactive switch", Color.yellow, 2, .002f);
                electrons = new Transform[10];
                for (int i = 0; i < electrons.Length; i++) electrons[i] = Shape(PrimitiveType.Sphere, "Illustrative charge " + i, Color.yellow, Vector3.zero, Vector3.one * .0035f);
                break;
            case PaperApplication.Pendulum:
                pivot = Shape(PrimitiveType.Sphere, "Pivot", Color.white, new Vector3(0, 0, -.065f), Vector3.one * .004f);
                bob = Shape(PrimitiveType.Sphere, "Pendulum bob", new Color(.2f, .7f, 1), Vector3.zero, Vector3.one * .011f);
                stringLine = Line("Pendulum string", Color.white, 2, .0008f);
                break;
        }
        Render(0);
    }
    Transform Panel(string name, Color color)
    {
        var g = new GameObject(name); g.transform.SetParent(scene, false);
        var mesh = new Mesh { name = name + " two-sided surface" };
        mesh.vertices = new[] { new Vector3(-.015f, -.015f, 0), new Vector3(.015f, -.015f, 0), new Vector3(.015f, .015f, 0), new Vector3(-.015f, .015f, 0) };
        mesh.triangles = new[] { 0, 2, 1, 0, 3, 2 }; mesh.RecalculateNormals(); meshes.Add(mesh);
        // Duplicate the back face rather than sharing opposing normals (which would cancel).
        var front = mesh.vertices; var both = new Vector3[8]; Array.Copy(front, both, 4); Array.Copy(front, 0, both, 4, 4);
        mesh.vertices = both; mesh.triangles = new[] { 0, 2, 1, 0, 3, 2, 4, 5, 6, 4, 6, 7 }; mesh.RecalculateNormals();
        g.AddComponent<MeshFilter>().sharedMesh = mesh; g.AddComponent<MeshRenderer>().sharedMaterial = Surface(color); return g.transform;
    }
    public bool SelectApplication(PaperApplication kind)
    {
        if (!active || !Enum.IsDefined(typeof(PaperApplication), kind)) return false;
        SetApplicationForSelection(kind); return true;
    }
    // Trusted selection hook for tracker/page binding; call only on a verified page-ID selection.
    public void SetApplicationForSelection(PaperApplication kind)
    {
        if (!Enum.IsDefined(typeof(PaperApplication), kind)) throw new ArgumentOutOfRangeException("kind");
        ApplicationKind = kind; ResetForSelection(); if (scene) Build();
        Debug.Log("PAPER APPLICATION selected=" + kind);
    }
    public bool NextApplication() { return SelectApplication((PaperApplication)(((int)ApplicationKind + 1) % Titles.Length)); }
    public bool SetParameters(float primary, float secondary)
    {
        if (!active || !float.IsFinite(primary) || !float.IsFinite(secondary)) return false;
        switch (ApplicationKind)
        {
            case PaperApplication.Vectors: PrimaryParameter = Mathf.Clamp(primary, -180, 180); SecondaryParameter = Mathf.Clamp(secondary, .25f, 2); break;
            case PaperApplication.Binomial: PrimaryParameter = Mathf.Clamp01(primary); SecondaryParameter = Mathf.Clamp(secondary, 0, 8); break;
            case PaperApplication.Circuit: PrimaryParameter = Mathf.Clamp(primary, 1, 12); SecondaryParameter = Mathf.Clamp(secondary, 10, 1000); break;
            case PaperApplication.Solar: PrimaryParameter = Mathf.Clamp(primary, .5f, 1.4f); SecondaryParameter = Mathf.Clamp(secondary, 0, 45); break;
            case PaperApplication.Geometry: PrimaryParameter = Mathf.Clamp01(primary); SecondaryParameter = Mathf.Clamp01(secondary); break;
            case PaperApplication.FunctionGraph: PrimaryParameter = Mathf.Clamp(primary, .1f, 2); SecondaryParameter = Mathf.Clamp(secondary, .5f, 4); break;
            case PaperApplication.InclinedPlane: PrimaryParameter = Mathf.Clamp(primary, 5, 65); SecondaryParameter = Mathf.Clamp(secondary, 0, .8f); break;
            case PaperApplication.Pendulum: PrimaryParameter = Mathf.Clamp(primary, .2f, 1.2f); SecondaryParameter = Mathf.Clamp(secondary, 5, 25); break;
        }
        dirty = true; return true;
    }
    // Disabled by default: the tracker must explicitly call this with a fresh, baseline-relative
    // marker pose. Marker-local translation is supplied in metres; this is a teaching input,
    // not a claim of physically measured model parameters.
    public bool ApplyPaperDial(float relativeRotationRadians, Vector3 relativePageTranslationMeters)
    {
        if (!active || !float.IsFinite(relativeRotationRadians) || !float.IsFinite(relativePageTranslationMeters.x) || !float.IsFinite(relativePageTranslationMeters.y) || !float.IsFinite(relativePageTranslationMeters.z)) return false;
        double x = relativePageTranslationMeters.x, y = relativePageTranslationMeters.y, z = relativePageTranslationMeters.z;
        double primary, secondary, fold;
        if (!PaperLearningMath.TryPaperDial((int)ApplicationKind, relativeRotationRadians, Math.Sqrt(x * x + y * y + z * z), out primary, out secondary, out fold)) return false;
        float p = (float)primary, s = (float)secondary, f = (float)fold;
        bool changed = Mathf.Abs(PrimaryParameter - p) > .00001f || Mathf.Abs(SecondaryParameter - s) > .00001f || Mathf.Abs(paperFold - f) > .00001f;
        if (!changed) return false;
        SetParameters(p, s); paperFold = f; dirty = true;
        return true;
    }
    public bool ApplyPaperDial(float relativeRotationRadians, Vector2 relativePageTranslationMeters)
    {
        return ApplyPaperDial(relativeRotationRadians, new Vector3(relativePageTranslationMeters.x, relativePageTranslationMeters.y, 0));
    }
    public void Toggle() { if (!active) return; playing = !playing; Debug.Log("MARKER INPUT pause=" + !playing); }
    public void Explode() { if (!active) return; paperFold = -1; exploded = !exploded; dirty = true; Debug.Log("MARKER INPUT explore=" + exploded); }
    public void ResetForSelection()
    {
        playing = true; speed = scale = 1; rotation = time = unfold = 0; paperFold = -1; exploded = false;
        switch (ApplicationKind)
        {
            case PaperApplication.Vectors: PrimaryParameter = 60; SecondaryParameter = 1; break;
            case PaperApplication.Binomial: PrimaryParameter = .5f; SecondaryParameter = 4; break;
            case PaperApplication.Circuit: PrimaryParameter = 5; SecondaryParameter = 100; break;
            case PaperApplication.Solar: PrimaryParameter = 1; SecondaryParameter = 12; break;
            case PaperApplication.Geometry: PrimaryParameter = 1; SecondaryParameter = .5f; break;
            case PaperApplication.FunctionGraph: PrimaryParameter = 1; SecondaryParameter = 1; break;
            case PaperApplication.InclinedPlane: PrimaryParameter = 30; SecondaryParameter = .15f; break;
            case PaperApplication.Pendulum: PrimaryParameter = .6f; SecondaryParameter = 20; break;
        }
        dirty = true;
    }
    public void Reset() { if (!active) return; ResetForSelection(); Debug.Log("MARKER INPUT reset"); }
    public void Axes(Vector2 a, Vector2 b, float dt)
    {
        if (!active || !float.IsFinite(dt) || dt <= 0) return;
        dt = Mathf.Min(dt, .1f); rotation += a.x * dt * 90; scale = Mathf.Clamp(scale + b.y * dt, .4f, 2);
        float primaryRate = ApplicationKind == PaperApplication.Vectors ? 90 : ApplicationKind == PaperApplication.Binomial ? .35f : ApplicationKind == PaperApplication.InclinedPlane ? 25 : ApplicationKind == PaperApplication.Circuit ? 3 : .6f;
        float secondaryRate = ApplicationKind == PaperApplication.Binomial ? 4 : ApplicationKind == PaperApplication.Vectors ? .8f : ApplicationKind == PaperApplication.Circuit ? 150 : ApplicationKind == PaperApplication.Solar || ApplicationKind == PaperApplication.Pendulum ? 15 : .5f;
        SetParameters(PrimaryParameter + a.y * dt * primaryRate, SecondaryParameter + b.x * dt * secondaryRate);
    }
    public void Status(string text) { trackerStatus = text ?? ""; if (label) label.text = trackerStatus; }
    void Update()
    {
        // Freeze transforms as well as simulation time: inputs may be stale and are not applied.
        if (!active) return;
        float dt = Mathf.Min(Time.deltaTime, .05f);
        if (playing) time += dt * Mathf.Clamp(float.IsFinite(speed) ? speed : 1, .1f, 4);
        Render(dt);
    }
    void Render(float dt)
    {
        scene.localRotation = Quaternion.Euler(0, 0, rotation); scene.localScale = Vector3.one * scale;
        switch (ApplicationKind)
        {
            case PaperApplication.Vectors: RenderVectors(); break;
            case PaperApplication.Binomial: RenderBinomial(); break;
            case PaperApplication.Circuit: RenderCircuit(); break;
            case PaperApplication.Solar: RenderSolar(); break;
            case PaperApplication.Geometry: RenderGeometry(dt); break;
            case PaperApplication.FunctionGraph: RenderGraph(); break;
            case PaperApplication.InclinedPlane: RenderRamp(); break;
            case PaperApplication.Pendulum: RenderPendulum(); break;
        }
        dirty = false;
    }
    void RenderSolar()
    {
        float radius = .035f * PrimaryParameter, angle = (float)(time * 2 * Math.PI / PaperLearningMath.OrbitPeriod(PrimaryParameter));
        float inclination = SecondaryParameter * Mathf.Deg2Rad;
        planet.localPosition = new Vector3(Mathf.Cos(angle) * radius, Mathf.Sin(angle) * radius * Mathf.Cos(inclination), -.024f - Mathf.Sin(angle) * radius * Mathf.Sin(inclination));
        if (dirty) for (int i = 0; i < 97; i++) { float a = i * 2 * Mathf.PI / 96; orbit.SetPosition(i, new Vector3(Mathf.Cos(a) * radius, Mathf.Sin(a) * radius * Mathf.Cos(inclination), -.024f - Mathf.Sin(a) * radius * Mathf.Sin(inclination))); }
        cube.localRotation = Quaternion.Euler(time * 25, time * 35, 0); cube.localScale = Vector3.one * (exploded ? .023f : .013f);
        lesson.text = "SOLAR · unitless radius, illustrative orbit\nT ∝ r³⁄²  · r=" + PrimaryParameter.ToString("0.00") + "  tilt=" + SecondaryParameter.ToString("0") + "°";
    }
    void RenderGeometry(float dt)
    {
        unfold = Mathf.MoveTowards(unfold, paperFold >= 0 ? paperFold : exploded ? 1 : 0, dt * 1.5f);
        float a = (1 - unfold) * 90, h = .015f;
        faces[0].localPosition = new Vector3(0, 0, -.004f); faces[0].localRotation = Quaternion.identity;
        for (int i = 0; i < 4; i++)
        {
            float z = i * 90; Quaternion around = Quaternion.Euler(0, 0, z); Quaternion fold = Quaternion.Euler(-a, 0, 0);
            faces[i + 1].localRotation = around * fold;
            faces[i + 1].localPosition = faces[0].localPosition + around * (new Vector3(0, h, 0) + fold * new Vector3(0, h, 0));
        }
        Quaternion first = Quaternion.Euler(-a, 0, 0), second = Quaternion.Euler(-a * 2, 0, 0);
        faces[5].localRotation = second;
        faces[5].localPosition = faces[0].localPosition + new Vector3(0, h, 0) + first * new Vector3(0, .03f, 0) + second * new Vector3(0, h, 0);
        section.gameObject.SetActive(unfold < .02f); section.localPosition = new Vector3(0, 0, -.004f - .03f * SecondaryParameter);
        float modelEdge = .03f * Mathf.Lerp(.65f, 1.2f, PrimaryParameter);
        float edge = modelEdge * scale; scene.localScale = Vector3.one * edge / .03f;
        lesson.transform.localPosition = new Vector3(0, unfold > .3f ? .105f + .015f * scale : .077f, -.003f);
        lesson.text = "CUBE · displayed-size model (not measured)\nV=" + (PaperLearningMath.CubeVolume(edge) * 1000000).ToString("0.0") + " cm³ · section=" + (PaperLearningMath.CubeSectionArea(edge, SecondaryParameter) * 10000).ToString("0.0") + " cm²\nslice height=" + (SecondaryParameter * 100).ToString("0") + "% · explore: net";
    }
    void RenderGraph()
    {
        if (dirty) { for (int i = 0; i <= 100; i++) { float x = -Mathf.PI + i * 2 * Mathf.PI / 100; graphPoints[i] = new Vector3(x * .016f, (float)PaperLearningMath.Graph(x, PrimaryParameter, SecondaryParameter, 0) * .019f, -.01f); } curve.SetPositions(graphPoints); UpdateGraphTube(); }
        float xProbe = Mathf.Sin(time * .6f) * Mathf.PI, y = (float)PaperLearningMath.Graph(xProbe, PrimaryParameter, SecondaryParameter, 0), slope = (float)PaperLearningMath.GraphSlope(xProbe, PrimaryParameter, SecondaryParameter, 0);
        probe.localPosition = new Vector3(xProbe * .016f, y * .019f, -.011f);
        Segment(tangent, probe.localPosition + new Vector3(-.006f, -slope * .006f * .019f / .016f, 0), probe.localPosition + new Vector3(.006f, slope * .006f * .019f / .016f, 0));
        tangent.gameObject.SetActive(exploded);
        lesson.text = "y = A sin(kx) · A=" + PrimaryParameter.ToString("0.00") + " k=" + SecondaryParameter.ToString("0.00") + "\nx=" + xProbe.ToString("0.00") + " y=" + y.ToString("0.00") + " dy/dx=" + slope.ToString("0.00");
    }
    void UpdateGraphTube()
    {
        const int sides = 8; var vertices = new Vector3[graphPoints.Length * sides];
        var normals = new Vector3[vertices.Length]; var indices = new int[(graphPoints.Length - 1) * sides * 6];
        for (int i = 0; i < graphPoints.Length; i++)
        {
            Vector3 direction = (graphPoints[Mathf.Min(i + 1, graphPoints.Length - 1)] - graphPoints[Mathf.Max(i - 1, 0)]).normalized;
            Vector3 normal = new Vector3(-direction.y, direction.x, 0);
            for (int j = 0; j < sides; j++)
            {
                float a = j * 2 * Mathf.PI / sides;
                Vector3 n = normal * Mathf.Cos(a) + Vector3.forward * Mathf.Sin(a);
                vertices[i * sides + j] = graphPoints[i] + n * .00065f; normals[i * sides + j] = n;
                if (i == graphPoints.Length - 1) continue;
                int k = (i * sides + j) * 6, next = i * sides + (j + 1) % sides;
                indices[k] = i * sides + j; indices[k + 1] = next; indices[k + 2] = next + sides;
                indices[k + 3] = i * sides + j; indices[k + 4] = next + sides; indices[k + 5] = (i + 1) * sides + j;
            }
        }
        graphTube.Clear(); graphTube.vertices = vertices; graphTube.normals = normals; graphTube.triangles = indices; graphTube.RecalculateBounds();
    }
    void RenderRamp()
    {
        float radians = PrimaryParameter * Mathf.Deg2Rad; Vector3 downhill = new Vector3(Mathf.Cos(radians), 0, Mathf.Sin(radians)), normal = new Vector3(Mathf.Sin(radians), 0, -Mathf.Cos(radians));
        ramp.localPosition = new Vector3(0, 0, -.035f); ramp.localRotation = Quaternion.Euler(0, -PrimaryParameter, 0);
        double acceleration = PaperLearningMath.RampAcceleration(PrimaryParameter, SecondaryParameter), duration = acceleration > .0001 ? Math.Sqrt(2 / acceleration) + .75 : 10;
        double t = time % duration, travel = PaperLearningMath.RampTravel(t, PrimaryParameter, SecondaryParameter, 1);
        block.localPosition = ramp.localPosition + downhill * (float)((travel - .5) * .072f) + normal * .008f; block.localRotation = ramp.localRotation;
        Segment(forceGravity, block.localPosition, block.localPosition + Vector3.forward * .022f);
        Segment(forceNormal, block.localPosition, block.localPosition + normal * .022f * Mathf.Cos(radians));
        Segment(forceFriction, block.localPosition, block.localPosition - downhill * .022f * SecondaryParameter * Mathf.Cos(radians));
        forceGravity.gameObject.SetActive(exploded); forceNormal.gameObject.SetActive(exploded); forceFriction.gameObject.SetActive(exploded);
        lesson.text = "INCLINE · θ=" + PrimaryParameter.ToString("0") + "° μ=" + SecondaryParameter.ToString("0.00") + "\na=max(0, g(sinθ−μcosθ))=" + acceleration.ToString("0.00") + " m/s²\nmodel travel=" + travel.ToString("0.00") + " m (visual path 7.2 cm) · explore: forces";
    }
    void RenderPendulum()
    {
        double angle = PaperLearningMath.PendulumAngle(time, PrimaryParameter, SecondaryParameter); float displayLength = .025f + .025f * PrimaryParameter;
        bob.localPosition = pivot.localPosition + new Vector3((float)Math.Sin(angle) * displayLength, 0, (float)Math.Cos(angle) * displayLength);
        Segment(stringLine, pivot.localPosition, bob.localPosition);
        double potential = PaperLearningMath.PendulumPotential(PrimaryParameter, angle), total = PaperLearningMath.PendulumPotential(PrimaryParameter, SecondaryParameter * Math.PI / 180);
        lesson.text = "PENDULUM · L=" + PrimaryParameter.ToString("0.00") + " m θ₀=" + SecondaryParameter.ToString("0") + "°\nT=2π√(L/g)=" + PaperLearningMath.PendulumPeriod(PrimaryParameter).ToString("0.00") + " s" + (exploded ? "\nenergy / kg: U=" + potential.ToString("0.00") + " K≈" + Math.Max(0, total - potential).ToString("0.00") + " J/kg" : "\nsmall-angle teaching model; visual length scaled");
    }
    void ArrowHead(LineRenderer head, Vector3 start, Vector3 end)
    {
        Vector3 direction = (end - start).normalized, normal = new Vector3(-direction.y, direction.x, 0);
        head.SetPosition(0, end - direction * .0035f + normal * .0018f);
        head.SetPosition(1, end); head.SetPosition(2, end - direction * .0035f - normal * .0018f);
    }
    void RenderVectors()
    {
        float angle = PrimaryParameter * Mathf.Deg2Rad;
        double bx = SecondaryParameter * Math.Cos(angle), by = SecondaryParameter * Math.Sin(angle);
        Vector3 origin = new Vector3(0, 0, -.01f), a = new Vector3(.025f, 0, 0), b = new Vector3((float)bx * .025f, (float)by * .025f, 0);
        Segment(vectorA, origin, origin + a); Segment(vectorB, origin, origin + b);
        Segment(vectorSum, origin + Vector3.back * .002f, origin + a + b + Vector3.back * .002f);
        Segment(vectorTail, origin + a, origin + a + b);
        double signed = PaperLearningMath.ProjectionScalar(bx, by, 1, 0);
        Segment(vectorProjection, origin + Vector3.back * .003f, origin + new Vector3((float)signed * .025f, 0, -.003f));
        vectorProjection.gameObject.SetActive(exploded); vectorTail.gameObject.SetActive(!exploded);
        ArrowHead(vectorHeads[0], origin, origin + a); ArrowHead(vectorHeads[1], origin, origin + b);
        ArrowHead(vectorHeads[2], origin + Vector3.back * .002f, origin + a + b + Vector3.back * .002f);
        ArrowHead(vectorHeads[3], vectorProjection.GetPosition(0), vectorProjection.GetPosition(1)); vectorHeads[3].gameObject.SetActive(exploded && Math.Abs(signed) > 1e-6);
        lesson.text = "VECTORS · A=(1,0) B=(" + bx.ToString("0.00") + "," + by.ToString("0.00") + ")\nA+B=(" + (1 + bx).ToString("0.00") + "," + by.ToString("0.00") + ") · A·B=" + signed.ToString("0.00") + "\n" + (exploded ? "yellow: signed projection on A" : "orange: head-to-tail B") + " · model units\ngreen A · orange B · cyan A+B";
    }
    void RenderBinomial()
    {
        int selected = Mathf.RoundToInt(SecondaryParameter);
        for (int k = 0; k <= 8; k++) {
            double probability = PaperLearningMath.BinomialPMF(8, k, PrimaryParameter);
            var bar = probabilityBars[k]; bar.gameObject.SetActive(probability > 0);
            float height = (float)probability * .055f;
            bar.localPosition = new Vector3(-.048f + k * .012f, height * .5f, -.01f);
            bar.localScale = new Vector3(.008f, height, .005f); // True zero probabilities are absent, not tiny positive bars.
            bar.GetComponent<Renderer>().sharedMaterial.color = k == selected ? Color.yellow : new Color(.2f, .75f, 1);
        }
        double mean = 8 * PrimaryParameter, variance = 8 * PrimaryParameter * (1 - PrimaryParameter);
        lesson.text = "BINOMIAL · n=8 p=" + PrimaryParameter.ToString("0.00") + "\nP(X=" + selected + ")=" + PaperLearningMath.BinomialPMF(8, selected, PrimaryParameter).ToString("0.0000") + "\nmean=np=" + mean.ToString("0.00") + " variance=np(1−p)=" + variance.ToString("0.00") + "\nbar height = probability · zero bars absent";
    }
    void RenderCircuit()
    {
        bool closed = !exploded;
        double current = PaperLearningMath.CircuitCurrent(PrimaryParameter, SecondaryParameter, closed);
        double power = PaperLearningMath.CircuitPower(PrimaryParameter, SecondaryParameter, closed);
        // Charges show qualitative conventional-current flow, not electron drift speed or a measurement.
        for (int i = 0; i < electrons.Length; i++)
        {
            float p = Mathf.Repeat(i / (float)electrons.Length + time * Mathf.Clamp((float)current * 2, .03f, .6f), 1);
            Vector3 v;
            if (p < .25f) v = new Vector3(-.037f, Mathf.Lerp(-.025f, .025f, p * 4), -.016f);
            else if (p < .5f) v = new Vector3(Mathf.Lerp(-.037f, .037f, (p - .25f) * 4), .025f, -.016f);
            else if (p < .75f) v = new Vector3(.037f, Mathf.Lerp(.025f, -.025f, (p - .5f) * 4), -.016f);
            else v = new Vector3(Mathf.Lerp(.037f, -.037f, (p - .75f) * 4), -.025f, -.016f);
            electrons[i].localPosition = v; electrons[i].gameObject.SetActive(closed);
        }
        Segment(switchLine, new Vector3(-.008f, -.025f, -.017f), new Vector3(.008f, closed ? -.025f : -.012f, -.017f));
        lesson.text = "CIRCUIT · " + (closed ? "closed" : "open") + " · explore toggles switch\nV=" + PrimaryParameter.ToString("0.0") + " V R=" + SecondaryParameter.ToString("0") + " Ω\nI=V/R=" + (current * 1000).ToString("0.0") + " mA P=VI=" + power.ToString("0.000") + " W\nqualitative charges; not measured drift speed";
    }
    static void DisposeOwned(UnityEngine.Object value)
    {
        if (UnityEngine.Application.isPlaying) UnityEngine.Object.Destroy(value);
        else UnityEngine.Object.DestroyImmediate(value); // Allows isolated editor rendering without dangling old content.
    }
    void OnDestroy() { foreach (var m in materials) if (m) DisposeOwned(m); foreach (var m in meshes) if (m) DisposeOwned(m); }
}

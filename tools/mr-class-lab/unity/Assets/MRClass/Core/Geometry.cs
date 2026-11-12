using UnityEngine;
namespace MRClass
{
public static class Geometry
{
    public static Material Material(Color color, string shader = "MRClass/Flat")
    {
        var m = new Material(Shader.Find(shader));
        m.color = color;
        return m;
    }
    public static GameObject Shape(Transform root, string name, PrimitiveType kind, Vector3 p, Vector3 size,
                                   Color color, string shader = "MRClass/Flat")
    {
        var g = GameObject.CreatePrimitive(kind);
        g.name = name;
        g.transform.SetParent(root, false);
        g.transform.localPosition = p;
        g.transform.localScale = size;
        g.GetComponent<Renderer>().sharedMaterial = Material(color, shader);
        var c = g.GetComponent<Collider>();
        if (c)
            Object.DestroyImmediate(c);
        return g;
    }
    public static TextMesh Text(Transform root, string text, Vector3 p, float size = .005f,
                                Color? color = null)
    {
        var g = new GameObject("Text");
        g.transform.SetParent(root, false);
        g.transform.localPosition = p;
        var t = g.AddComponent<TextMesh>();
        t.text = text;
        t.richText = false;
        t.fontSize = 64;
        t.characterSize = size;
        t.anchor = TextAnchor.MiddleCenter;
        t.alignment = TextAlignment.Center;
        t.color = color ?? Color.white;
        t.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
        g.GetComponent<MeshRenderer>().sharedMaterial = t.font.material;
        return t;
    }
    public static LineRenderer Line(Transform root, string name, Vector3[] points, Color color,
                                    float width = .008f)
    {
        var g = new GameObject(name);
        g.transform.SetParent(root, false);
        var l = g.AddComponent<LineRenderer>();
        l.useWorldSpace = false;
        l.positionCount = points.Length;
        l.SetPositions(points);
        l.startWidth = l.endWidth = width;
        l.sharedMaterial = Material(color);
        return l;
    }
    public static void DisposeChildren(Transform root)
    {
        for (int i = root.childCount - 1; i >= 0; i--)
        {
            var g = root.GetChild(i).gameObject;
            foreach (var r in g.GetComponentsInChildren<Renderer>())
                if (r.sharedMaterial && r.sharedMaterial.shader.name.StartsWith("MRClass/"))
                    Object.DestroyImmediate(r.sharedMaterial);
            Object.DestroyImmediate(g);
        }
    }
}
}

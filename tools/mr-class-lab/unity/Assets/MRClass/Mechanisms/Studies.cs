using UnityEngine;
namespace MRClass
{
// Mechanisms are driven by explicit inputs. No fabricated detector/model output.
public sealed class Studies : MonoBehaviour
{
    public static readonly string[] Names = { "Find a book",   "Physical tutorial", "Speech / captions",
                                              "Wipe a portal", "Screen to AR",      "Avatar building block" };
    public static readonly string[] Bounds = { "Authored book registry; not book recognition",
                                               "Authored stroke sequence; not task recognition",
                                               "Typed / browser speech input; supplied translation",
                                               "Controller wipe + stencil aperture; no door segmentation",
                                               "Actual LAN state relay; no shared spatial anchor",
                                               "Skinned glTF avatar + supplied animation; no body tracking" };
    Transform body, leftArm, rightArm, model, mask;
    TextMesh caption, instruction;
    LineRenderer path, stroke, crossbar;
    Material[] books;
    Texture texture;
    int current = -1;
    Vector3[] strokePoints;
    GameObject importedAvatar;
    AnimationClip avatarClip;
    public bool HasSkinnedAvatar =>
        importedAvatar && importedAvatar.GetComponentInChildren<SkinnedMeshRenderer>();
    public Quaternion[] AvatarJoints()
    {
        if (!HasSkinnedAvatar)
            return new Quaternion[0];
        var bones = importedAvatar.GetComponentInChildren<SkinnedMeshRenderer>().bones;
        var values = new Quaternion[bones.Length];
        for (int i = 0; i < bones.Length; i++)
            values[i] = bones[i].localRotation;
        return values;
    }
    readonly Color mint = new Color(.25f, .86f, .7f), blue = new Color(.25f, .6f, 1),
                   gold = new Color(1, .72f, .28f);
    public int Current => current;
    Transform Root(string name, Vector3 p)
    {
        var t = new GameObject(name).transform;
        t.SetParent(transform, false);
        t.localPosition = p;
        return t;
    }
    public void Build(int study)
    {
        Geometry.DisposeChildren(transform);
        current = study;
        body = leftArm = rightArm = model = mask = null;
        caption = instruction = null;
        path = stroke = crossbar = null;
        importedAvatar = null;
        avatarClip = null;
        switch ((Study)study)
        {
        case Study.Library:
            Library();
            break;
        case Study.Tutorial:
            Tutorial();
            break;
        case Study.Captions:
            CaptionStudy();
            break;
        case Study.Portal:
            Portal();
            break;
        case Study.CrossDevice:
            CrossDevice();
            break;
        case Study.Avatar:
            Avatar();
            break;
        }
        if (texture)
            SetTexture(texture);
    }
    void Library()
    {
        var root = Root("Authored book registry", Vector3.zero);
        books = new Material[5];
        Geometry.Shape(root, "Shelf", PrimitiveType.Cube, new Vector3(0, -.16f, .04f),
                       new Vector3(.9f, .025f, .25f), new Color(.27f, .18f, .12f));
        for (int i = 0; i < 5; i++)
        {
            Color c = Color.HSVToRGB(i * .17f, .58f, .82f);
            var g = Geometry.Shape(root, "Book " + (i + 1), PrimitiveType.Cube,
                                   new Vector3((i - 2) * .15f, 0, .04f), new Vector3(.1f, .3f, .18f), c);
            books[i] = g.GetComponent<Renderer>().sharedMaterial;
            Geometry.Text(root, (i + 1).ToString(), new Vector3((i - 2) * .15f, 0, -.058f), .005f);
        }
        path = Geometry.Line(root, "Guidance to selected registered book", new Vector3[3], gold, .012f);
        instruction = Geometry.Text(root, "", new Vector3(0, .29f, 0), .004f);
    }
    void Tutorial()
    {
        var root = Root("Paper tutorial", Vector3.zero);
        Geometry.Shape(root, "Tutorial surface", PrimitiveType.Cube, new Vector3(0, 0, .015f),
                       new Vector3(.65f, .5f, .012f), new Color(.93f, .92f, .85f));
        strokePoints = new[] { new Vector3(-.17f, -.15f, -.001f), new Vector3(0, .17f, -.001f),
                               new Vector3(.17f, -.15f, -.001f), new Vector3(-.09f, -.01f, -.001f),
                               new Vector3(.09f, -.01f, -.001f) };
        Geometry.Line(root, "Reference strokes", new[] { strokePoints[0], strokePoints[1], strokePoints[2] },
                      new Color(.7f, .73f, .74f), .006f);
        Geometry.Line(root, "Reference crossbar", new[] { strokePoints[3], strokePoints[4] },
                      new Color(.7f, .73f, .74f), .006f);
        stroke = Geometry.Line(root, "Completed authored strokes", strokePoints, mint, .012f);
        crossbar = Geometry.Line(root, "Completed crossbar", new[] { strokePoints[3], strokePoints[4] }, mint,
                                 .012f);
        instruction = Geometry.Text(root, "", new Vector3(0, .33f, 0), .004f);
        MakeAvatar(new Vector3(.48f, -.25f, 0), .5f);
    }
    void CaptionStudy()
    {
        caption =
            Geometry.Text(transform, "Send a caption from the companion", new Vector3(0, .15f, -.03f), .006f);
        instruction = Geometry.Text(transform, "", new Vector3(0, -.15f, -.03f), .0035f);
        MakeAvatar(new Vector3(-.48f, -.4f, .1f), .8f);
    }
    void Portal()
    {
        var root = Root("Stencil portal", Vector3.zero);
        Geometry.Shape(root, "Left jamb", PrimitiveType.Cube, new Vector3(-.46f, 0, 0),
                       new Vector3(.045f, 1, .06f), gold);
        Geometry.Shape(root, "Right jamb", PrimitiveType.Cube, new Vector3(.46f, 0, 0),
                       new Vector3(.045f, 1, .06f), gold);
        Geometry.Shape(root, "Header", PrimitiveType.Cube, new Vector3(0, .48f, 0),
                       new Vector3(.96f, .045f, .06f), gold);
        Geometry.Shape(root, "Threshold", PrimitiveType.Cube, new Vector3(0, -.48f, 0),
                       new Vector3(.96f, .045f, .06f), gold);
        mask = Geometry
                   .Shape(root, "Wipe aperture", PrimitiveType.Quad, Vector3.zero,
                          new Vector3(.001f, .92f, 1), Color.white, "MRClass/PortalMask")
                   .transform;
        const string shader = "MRClass/PortalRoom";
        Geometry.Shape(root, "Other room back wall", PrimitiveType.Cube, new Vector3(0, 0, 1.6f),
                       new Vector3(2.5f, 2.4f, .05f), new Color(.07f, .15f, .3f), shader);
        Geometry.Shape(root, "Other room floor", PrimitiveType.Cube, new Vector3(0, -.6f, .9f),
                       new Vector3(2.5f, .03f, 1.7f), new Color(.18f, .3f, .42f), shader);
        for (int i = 0; i < 7; i++)
            Geometry.Shape(root, "Portal depth object " + i, PrimitiveType.Cube,
                           new Vector3((i % 3 - 1) * .43f, -.25f + (i % 2) * .28f, .3f + i * .16f),
                           Vector3.one * (.12f + i * .012f), i % 2 == 0 ? mint : gold, shader);
        instruction = Geometry.Text(root, "Wipe across the opening with the controller",
                                    new Vector3(0, .62f, 0), .0035f);
    }
    void CrossDevice()
    {
        model = Root("Networked editable model", Vector3.zero);
        Geometry.Shape(model, "Model base", PrimitiveType.Cylinder, new Vector3(0, -.2f, 0),
                       new Vector3(.34f, .025f, .34f), blue);
        Geometry.Shape(model, "Model body", PrimitiveType.Cube, Vector3.zero, new Vector3(.26f, .35f, .18f),
                       mint);
        Geometry.Shape(model, "Model roof", PrimitiveType.Sphere, new Vector3(0, .19f, 0),
                       new Vector3(.3f, .1f, .25f), gold);
        instruction = Geometry.Text(transform, "Move / rotate this model from another device",
                                    new Vector3(0, .43f, 0), .004f);
    }
    void Avatar()
    {
        MakeAvatar(new Vector3(0, -.4f, 0), 1);
        instruction = Geometry.Text(
            transform, "A / Action: animate     Reset: neutral\nCesium Man / Cesium 2017 / CC BY 4.0",
            new Vector3(0, .5f, 0), .0035f);
    }
    void MakeAvatar(Vector3 p, float scale)
    {
        body = Root("Articulated avatar", p);
        body.localScale = Vector3.one * scale;
        var asset = Resources.Load<GameObject>("ClassAvatar");
        if (asset)
        {
            var holder = new GameObject("Animation-independent avatar scale and foot origin").transform;
            holder.SetParent(body, false);
            importedAvatar = Instantiate(asset, holder, false);
            importedAvatar.name = "Imported skinned glTF avatar";
            foreach (var animator in importedAvatar.GetComponentsInChildren<Animator>())
                animator.enabled = false;
            foreach (var renderer in importedAvatar.GetComponentsInChildren<SkinnedMeshRenderer>())
                renderer.updateWhenOffscreen = true;
            var clips = Resources.LoadAll<AnimationClip>("ClassAvatar");
            if (clips.Length > 0)
            {
                avatarClip = clips[0];
                avatarClip.SampleAnimation(importedAvatar, 0);
            }
            var bounds = SkinBounds(importedAvatar, body);
            float factor = .75f / Mathf.Max(.01f, bounds.size.y);
            holder.localScale = Vector3.one * factor;
            holder.localPosition =
                new Vector3(-bounds.center.x * factor, -bounds.min.y * factor, -bounds.center.z * factor);
            return;
        }
        // Explicit fallback for a user replacing the avatar asset; the bundled build verifies a real skinned
        // model.
        Geometry.Shape(body, "Torso", PrimitiveType.Capsule, new Vector3(0, .42f, 0),
                       new Vector3(.2f, .2f, .12f), blue);
        Geometry.Shape(body, "Head", PrimitiveType.Sphere, new Vector3(0, .73f, 0), Vector3.one * .2f,
                       new Color(.93f, .68f, .43f));
        for (int i = 0; i < 2; i++)
        {
            float side = i == 0 ? -1 : 1;
            Geometry.Shape(body, "Eye", PrimitiveType.Sphere, new Vector3(side * .037f, .75f, -.09f),
                           Vector3.one * .019f, Color.white);
            Geometry.Shape(body, "Pupil", PrimitiveType.Sphere, new Vector3(side * .037f, .75f, -.102f),
                           Vector3.one * .009f, Color.black);
            var arm = Root(i == 0 ? "Left shoulder" : "Right shoulder", Vector3.zero);
            arm.SetParent(body, false);
            arm.localPosition = new Vector3(side * .13f, .57f, 0);
            Geometry.Shape(arm, "Upper arm", PrimitiveType.Capsule, new Vector3(side * .08f, -.09f, 0),
                           new Vector3(.07f, .1f, .07f), blue);
            Geometry.Shape(arm, "Hand", PrimitiveType.Sphere, new Vector3(side * .15f, -.2f, 0),
                           Vector3.one * .075f, new Color(.93f, .68f, .43f));
            if (i == 0)
                leftArm = arm;
            else
                rightArm = arm;
            Geometry.Shape(body, "Leg", PrimitiveType.Capsule, new Vector3(side * .065f, .15f, 0),
                           new Vector3(.08f, .15f, .08f), new Color(.12f, .18f, .28f));
            Geometry.Shape(body, "Foot", PrimitiveType.Cube, new Vector3(side * .065f, 0, -.035f),
                           new Vector3(.09f, .045f, .15f), Color.white);
        }
    }
    static Bounds SkinBounds(GameObject instance, Transform coordinates)
    {
        var result = new Bounds();
        bool first = true;
        foreach (var renderer in instance.GetComponentsInChildren<Renderer>())
        {
            Mesh baked = null;
            Bounds b;
            if (renderer is SkinnedMeshRenderer skin)
            {
                baked = new Mesh();
                skin.BakeMesh(baked);
                b = baked.bounds;
            }
            else
            {
                var filter = renderer.GetComponent<MeshFilter>();
                if (!filter || !filter.sharedMesh)
                    continue;
                b = filter.sharedMesh.bounds;
            }
            for (int i = 0; i < 8; i++)
            {
                var p = b.center +
                        Vector3.Scale(b.extents, new Vector3((i & 1) == 0 ? -1 : 1, (i & 2) == 0 ? -1 : 1,
                                                             (i & 4) == 0 ? -1 : 1));
                var local = coordinates.InverseTransformPoint(renderer.transform.TransformPoint(p));
                if (first)
                {
                    result = new Bounds(local, Vector3.zero);
                    first = false;
                }
                else
                    result.Encapsulate(local);
            }
            if (baked)
                DestroyImmediate(baked);
        }
        return result;
    }
    public void Apply(LabState s, float time)
    {
        if (current != s.study)
            Build(s.study);
        if (body)
        {
            body.localRotation = Quaternion.Euler(0, s.animate ? Mathf.Sin(time * 1.5f) * 20 : 0, 0);
            if (importedAvatar && avatarClip)
            {
                avatarClip.SampleAnimation(
                    importedAvatar, s.animate ? Mathf.Repeat(time, Mathf.Max(.01f, avatarClip.length)) : 0);
            }
            else if (leftArm && rightArm)
            {
                leftArm.localRotation = Quaternion.Euler(0, 0,
                                                         s.animate      ? -50 + Mathf.Sin(time * 4) * 20
                                                         : s.study == 1 ? -65
                                                                        : 0);
                rightArm.localRotation =
                    Quaternion.Euler(0, 0, s.animate ? 50 + Mathf.Cos(time * 4) * 20 : 0);
            }
        }
        switch ((Study)s.study)
        {
        case Study.Library:
            for (int i = 0; i < 5; i++)
                books[i].color = i == s.book ? gold : Color.HSVToRGB(i * .17f, .58f, .5f);
            path.SetPositions(new[] { new Vector3(0, -.4f, -.25f),
                                      new Vector3((s.book - 2) * .15f, -.4f, -.25f),
                                      new Vector3((s.book - 2) * .15f, -.19f, -.09f) });
            instruction.text = "Find book " + (s.book + 1) + "  /  A: next target";
            break;
        case Study.Tutorial:
            stroke.positionCount = s.step == 0 ? 0 : s.step == 1 ? 2 : 3;
            for (int i = 0; i < stroke.positionCount; i++)
                stroke.SetPosition(i, strokePoints[i]);
            crossbar.gameObject.SetActive(s.step == 3);
            instruction.text = "Stroke " + s.step + " / 3   A: next stroke   B: reset";
            break;
        case Study.Captions:
            caption.text = Wrap(s.caption.Length == 0 ? "Send a caption from the companion" : s.caption, 36) +
                           "\n" + Wrap(s.translation, 36);
            instruction.text = "Input: " + s.captionSource + " / translation: supplied text";
            break;
        case Study.Portal:
            mask.localScale = new Vector3(Mathf.Max(.001f, .9f * s.reveal), .92f, 1);
            mask.localPosition = new Vector3(-.45f + .45f * s.reveal, 0, 0);
            instruction.text = "Reveal " + Mathf.RoundToInt(s.reveal * 100) + "% / controller swipe or A";
            break;
        case Study.CrossDevice:
            model.localPosition = new Vector3(s.x, s.y, s.z);
            model.localRotation = Quaternion.Euler(0, s.rotation + (s.animate ? time * 40 : 0), 0);
            Color c;
            if (ColorUtility.TryParseHtmlString(s.color, out c))
                model.GetChild(1).GetComponent<Renderer>().sharedMaterial.color = c;
            break;
        }
    }
    public void SetTexture(Texture t)
    {
        texture = t;
        foreach (var r in GetComponentsInChildren<Renderer>())
            if (r.gameObject.name == "Other room back wall")
                r.sharedMaterial.mainTexture = texture;
    }
    static string Wrap(string s, int width)
    {
        if (s == null)
            return "";
        var words = s.Split(' ');
        var result = "";
        int n = 0;
        foreach (var w in words)
        {
            if (n + w.Length > width)
            {
                result += "\n";
                n = 0;
            }
            result += w + " ";
            n += w.Length + 1;
        }
        return result.TrimEnd();
    }
}
}

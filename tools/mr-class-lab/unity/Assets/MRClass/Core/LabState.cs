using System;
using UnityEngine;
namespace MRClass
{
public enum Study
{
    Library,
    Tutorial,
    Captions,
    Portal,
    CrossDevice,
    Avatar
}
[Serializable]
public sealed class LabState
{
    public int revision, study, step, book;
    public float x, y, z, rotation, reveal;
    public bool animate;
    public string session = "", caption = "", translation = "", captionSource = "typed", color = "#42d7b0";
    public int textureRevision;
    public LabState Copy() => JsonUtility.FromJson<LabState>(JsonUtility.ToJson(this));
    public void Validate()
    {
        if (study < 0 || study > 5 || step < 0 || step > 3 || book < 0 || book > 4 || !Finite(x) ||
            !Finite(y) || !Finite(z) || !Finite(rotation) || !Finite(reveal))
            throw new ArgumentException("Invalid scene state");
        x = Mathf.Clamp(x, -.6f, .6f);
        y = Mathf.Clamp(y, -.3f, .6f);
        z = Mathf.Clamp(z, -.4f, .4f);
        reveal = Mathf.Clamp01(reveal);
        caption = Trim(caption, 240);
        translation = Trim(translation, 240);
    }
    static string Trim(string s, int n) => string.IsNullOrEmpty(s) ? ""
                                                                   : s.Substring(0, Mathf.Min(n, s.Length));
    static bool Finite(float f) => !float.IsNaN(f) && !float.IsInfinity(f);
    public void ResetAction()
    {
        step = book = 0;
        reveal = 0;
        x = y = z = rotation = 0;
        animate = false;
        caption = translation = "";
        captionSource = "typed";
        color = "#42d7b0";
        revision++;
    }
    public void Primary()
    {
        if (study == (int)Study.Tutorial)
            step = (step + 1) % 4;
        else if (study == (int)Study.Library)
            book = (book + 1) % 5;
        else if (study == (int)Study.Portal)
            reveal = reveal < .5f ? 1 : 0;
        else
            animate = !animate;
        revision++;
    }
}
}

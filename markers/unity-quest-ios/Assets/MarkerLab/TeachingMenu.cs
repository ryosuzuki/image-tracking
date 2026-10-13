using System;
using System.Text;
using UnityEngine;

// Head-relative navigation UI only. This is never presented as a measured paper anchor.
public sealed class TeachingMenu : MonoBehaviour
{
    public Action<PaperApplication> Select;
    public Func<string> CaptureStatus;
    public bool Open { get; private set; } = true;
    public bool ConsumedInput { get; private set; }
    TextMesh label;
    int selected;
    bool axisHeld;
    public static readonly string[] Names = MarkerInteraction.Titles;
    public static int Step(int current, int delta) { return (current + delta + Names.Length) % Names.Length; }
    public void Initialize(Transform eye)
    {
        if (!eye) return;
        transform.SetParent(eye, false);
        transform.localPosition = new Vector3(-.17f, .13f, .65f);
        label = gameObject.AddComponent<TextMesh>();
        label.fontSize = 40; label.characterSize = .0026f;
        label.anchor = TextAnchor.UpperLeft; label.alignment = TextAlignment.Left; label.color = Color.white;
        Refresh();
    }
    public void Poll()
    {
        ConsumedInput = false;
        if (OVRInput.GetDown(OVRInput.Button.Start)) { Open = !Open; ConsumedInput = true; }
        if (Open)
        {
            float axis = OVRInput.Get(OVRInput.Axis2D.PrimaryThumbstick).y;
            if (Mathf.Abs(axis) < .3f) axisHeld = false;
            if (!axisHeld && Mathf.Abs(axis) > .65f) { selected = Step(selected, axis < 0 ? 1 : -1); axisHeld = true; }
            if (OVRInput.GetDown(OVRInput.Button.Four)) selected = Step(selected, 1);
            if (OVRInput.GetDown(OVRInput.Button.One)) { Select?.Invoke((PaperApplication)selected); Open = false; }
            ConsumedInput = true;
        }
        Refresh();
    }
    void Refresh()
    {
        if (!label) return;
        if (!Open) { label.text = "Menu button: choose a lesson\n" + (CaptureStatus?.Invoke() ?? ""); return; }
        var text = new StringBuilder("INTERACTIVE PAPER LAB\nOne app / eight lessons\n\n");
        for (int i = 0; i < Names.Length; i++) text.Append(i == selected ? "> " : "  ").Append(i + 1).Append("  ").Append(Names[i]).Append('\n');
        text.Append("\nLeft stick: highlight / Y: next\nA: select / Menu: close\nRight stick: start/stop capture\nAR requires fresh tracked paper\n").Append(CaptureStatus?.Invoke() ?? "");
        label.text = text.ToString();
    }
}

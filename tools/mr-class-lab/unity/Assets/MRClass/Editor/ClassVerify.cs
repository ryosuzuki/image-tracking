using System;
using System.Collections.Generic;
using System.IO;
using UnityEditor.SceneManagement;
using UnityEngine;
namespace MRClass.Editor
{
public static partial class ClassBuild
{
    [Serializable]
    public class Result
    {
        public string capture, study;
        public bool synthetic, resetVerified;
        public int sourceFrame, visiblePixels;
        public string before, after;
    }
    [Serializable]
    public class Report
    {
        public string kind =
            "programmatic Unity input + calibrated recorded-camera rendering; NOT physical Quest acceptance";
        public List<Result> results = new List<Result>();
    }
    public static void Verify()
    {
        string root = Environment.GetEnvironmentVariable("MR_CLASS_VERIFY") ??
                      throw new Exception("Set MR_CLASS_VERIFY output directory");
        string inputs = Environment.GetEnvironmentVariable("MR_CLASS_CAPTURES") ??
                        throw new Exception(
                            "Set explicit private prepared capture directories separated by path separator");
        Directory.CreateDirectory(root);
        var report = new Report();
        // Freshness and origin invalidation are semantic acceptance checks, not renderer counts.
        var gate = new MeasuredTrackingAccess();
        gate.SetReliable(true);
        int epoch = gate.BeginSelection();
        gate.Observe(epoch, 10, true);
        Require(gate.Interactive(10.15) && !gate.Interactive(10.17), "stale input frozen");
        gate.BeginSelection();
        Require(!gate.Observe(epoch, 11, true) && !gate.Visible(11),
                "old capture rejected after origin reset");
        gate.Observe(gate.Epoch, 12, true);
        gate.SetReliable(false);
        Require(!gate.Visible(12), "unreliable headset hides paper");
        foreach (string folder in inputs.Split(Path.PathSeparator))
        {
            EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
            var app = new GameObject("Verified class runtime").AddComponent<LabApp>();
            app.Initialize(true);
            var replay = app.gameObject.AddComponent<ReplayInput>();
            replay.Load(folder, app);
            string dest = Path.Combine(root, replay.Data.id);
            Directory.CreateDirectory(dest);
            for (int study = 0; study < 6; study++)
            {
                app.Select(study);
                app.Clock = 0;
                replay.Seek(0);
                if (study == 5)
                    Require(app.Content.HasSkinnedAvatar, "actual skinned glTF avatar imported");
                var neutralJoints = app.Content.AvatarJoints();
                string baseline = JsonUtility.ToJson(app.State);
                string before = Path.Combine(dest, "study-" + study + "-before.png");
                int pixels = replay.SaveFrame(before);
                Require(pixels > 100, "visible component " + study + " in " + replay.Data.id);
                Change(app, study);
                app.Clock = 3;
                app.Apply();
                if (study == 5)
                {
                    var joints = app.Content.AvatarJoints();
                    bool moved = false;
                    for (int i = 0; i < joints.Length; i++)
                        moved |= Mathf.Abs(Quaternion.Dot(joints[i], neutralJoints[i])) < .99999f;
                    Require(moved, "supplied animation actually changes avatar joints");
                }
                string after = Path.Combine(dest, "study-" + study + "-after.png");
                replay.SaveFrame(after);
                Require(!Equal(File.ReadAllBytes(before), File.ReadAllBytes(after)),
                        "input changes rendered result " + study);
                app.ResetAction();
                app.Clock = 0;
                replay.Seek(0);
                string reset = Path.Combine(dest, "study-" + study + "-reset.png");
                replay.SaveFrame(reset);
                // Library selection is an independent target, so reset returns that target explicitly.
                if (study == 0)
                {
                    app.State.book = 0;
                    app.Apply();
                    replay.SaveFrame(reset);
                }
                Require(Equal(File.ReadAllBytes(before), File.ReadAllBytes(reset)),
                        "reset restores rendered baseline " + study);
                report.results.Add(new Result { capture = replay.Data.id, synthetic = replay.Data.synthetic,
                                                study = Studies.Names[study], sourceFrame = 0,
                                                visiblePixels = pixels, before = before, after = after,
                                                resetVerified = true });
                if (Environment.GetEnvironmentVariable("MR_CLASS_RENDER_VIDEO") == "1")
                {
                    string frames = Path.Combine(dest, "study-" + study + "-frames");
                    Directory.CreateDirectory(frames);
                    var map = new List<string>();
                    for (int i = 0; i < 60; i++)
                    {
                        float t = i / 10f;
                        app.Select(study);
                        // Hold a measured view after 0.5s so the input/response/reset stays in frame.
                        // The CSV records every repeated source observation; interactive replay is unchanged.
                        replay.Seek(Mathf.Min(replay.Duration, Mathf.Min(t, .5f)));
                        if (t >= 1.5f)
                            Change(app, study);
                        if (t >= 4.5f)
                            app.ResetAction();
                        app.Clock = t;
                        app.Apply();
                        replay.SaveFrame(Path.Combine(frames, i.ToString("D4") + ".png"));
                        map.Add(i + "," +
                                t.ToString("F3", System.Globalization.CultureInfo.InvariantCulture) + "," +
                                replay.FrameIndex + "," +
                                replay.Data.frames[replay.FrameIndex].time.ToString(
                                    "F6", System.Globalization.CultureInfo.InvariantCulture));
                    }
                    File.WriteAllLines(Path.Combine(frames, "source-frame-map.csv"),
                                       new[] { "output_frame,output_seconds,source_index,source_seconds" });
                    File.AppendAllLines(Path.Combine(frames, "source-frame-map.csv"), map);
                }
            }
        }
        File.WriteAllText(Path.Combine(root, "verification.json"), JsonUtility.ToJson(report, true));
        Debug.Log("MR_CLASS_VERIFIED captures=" + inputs.Split(Path.PathSeparator).Length +
                  " studies=" + report.results.Count + " reset+freshness+visible-change checks passed");
    }
    static void Change(LabApp app, int study)
    {
        if (study == 0)
            app.State.book = 3;
        if (study == 1)
            app.State.step = 2;
        if (study == 2)
        {
            app.State.caption = "Follow the highlighted stroke";
            app.State.translation = "Physical tutorial / supplied caption";
            app.State.captionSource = "authored-event";
        }
        if (study == 3)
            app.State.reveal = .9f;
        if (study == 4)
        {
            app.State.x = .18f;
            app.State.y = .08f;
            app.State.rotation = 40;
            app.State.color = "#ffbc47";
        }
        if (study == 5)
            app.State.animate = true;
        app.Changed();
    }
    static bool Equal(byte[] a, byte[] b)
    {
        if (a.Length != b.Length)
            return false;
        for (int i = 0; i < a.Length; i++)
            if (a[i] != b[i])
                return false;
        return true;
    }
    static void Require(bool value, string message)
    {
        if (!value)
            throw new Exception("Acceptance failed: " + message);
    }
}
}

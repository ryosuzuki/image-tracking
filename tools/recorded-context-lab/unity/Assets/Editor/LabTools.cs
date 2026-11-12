using System;
using System.IO;
using RecordedContext;
using UnityEngine;
using UnityEditor;
using UnityEditor.SceneManagement;
public static class LabTools
{
    [MenuItem("Tools/Recorded Context Lab/Open capture in Play Mode")]
    public static void Open()
    {
        if (!EditorApplication.isPlaying)
        {
            EditorUtility.DisplayDialog("Enter Play Mode first",
                                        "Press Play, then select this command and your private folder.", "OK");
            return;
        }
        string p = EditorUtility.OpenFolderPanel("Open prepared capture (lab.json)", "", "");
        if (string.IsNullOrEmpty(p))
            return;
        var old = UnityEngine.Object.FindAnyObjectByType<RecordedContextPlayer>();
        if (old != null)
            UnityEngine.Object.Destroy(old.gameObject);
        new GameObject("Private capture replay").AddComponent<RecordedContextPlayer>().Load(p);
    }
    public static void Verify()
    {
        var root = Environment.GetEnvironmentVariable("MR_LAB_CAPTURE");
        var output = Environment.GetEnvironmentVariable("MR_LAB_OUTPUT");
        if (string.IsNullOrEmpty(root) || string.IsNullOrEmpty(output))
            throw new Exception("Explicit input/output required");
        Directory.CreateDirectory(output);
        EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
        var player = new GameObject("Verification replay").AddComponent<RecordedContextPlayer>();
        player.Load(root);
        var a = player.Data.annotations[0];
        var original = (float[])a.position.Clone();
        int checks = 0;
        foreach (float t in new[] {
                     0f, Mathf.Min(player.Data.frames[player.Data.frames.Length - 1].time, a.triggerTime + .3f), 0f
                 })
        {
            player.Mode = 2;
            player.Seek(t);
            if (Vector3.Distance(player.CaptureCamera.transform.position,
                                 new Vector3(player.Data.frames[player.FrameIndex].position[0],
                                             player.Data.frames[player.FrameIndex].position[1],
                                             player.Data.frames[player.FrameIndex].position[2])) > .00001f)
                throw new Exception("Camera pose mismatch");
            if (a.position[0] != original[0] || a.position[2] != original[2])
                throw new Exception("Anchor dragged by camera");
            player.SaveFrame(Path.Combine(output, "unity-frame-" + checks + ".png"));
            checks++;
        }
        var k = player.Data.intrinsics;
        var p = player.CaptureCamera.projectionMatrix;
        if (Mathf.Abs(p[0, 2] - (1 - 2 * k.cx / k.width)) > .00001f)
            throw new Exception("Off-center principal point lost");
        if (RecordedContextPlayer.Index(player.Data.frames, -1) != 0)
            throw new Exception("Seek before start invalid");
        Debug.Log("MR_LAB_VERIFIED pose/anchor/reset/off-center source-frames=" + player.Data.frames.Length);
        File.WriteAllText(
            Path.Combine(output, "unity-verification.json"),
            "{\"poseAnchorSeekAndOffcenter\":true,\"renderedFrames\":3,\"physicalQuestAcceptance\":false}");
    }
}

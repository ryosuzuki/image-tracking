using System;
using System.IO;
using UnityEngine;

// Explicit, bounded sensor capture. Never auto-publishes room media.
public sealed class TeachingCapture : IDisposable
{
    StreamWriter writer;
    string directory;
    double deadline, next;
    int count;
    Texture2D image;
    public bool Recording { get { return writer != null; } }
    public string Status { get { return Recording ? "CAPTURE " + count + " frames (right stick to stop)" : "Right stick: capture up to 60 seconds"; } }
    public void Start(string root, string calibrationPath, int seconds = 60)
    {
        if (Recording || !File.Exists(calibrationPath)) return;
        directory = Path.Combine(root, "teaching-take-" + DateTime.UtcNow.ToString("yyyyMMdd-HHmmss-fff"));
        Directory.CreateDirectory(directory);
        File.Copy(calibrationPath, Path.Combine(directory, "calibration.json"));
        writer = new StreamWriter(Path.Combine(directory, "frames.jsonl"));
        count = 0; next = 0; deadline = Time.realtimeSinceStartupAsDouble + Math.Max(1, Math.Min(60, seconds));
        File.WriteAllText(Path.Combine(directory, "capture.json"), "{\"schema\":\"paper-lab-capture-v1\",\"coordinateSystem\":\"Unity left-handed, metres, quaternion xyzw\",\"imageOrientation\":\"top-left RGBA, same GPU readback as detector\",\"maxHz\":3,\"audio\":false,\"roomMesh\":false,\"complete\":false}");
        Debug.Log("TEACHING CAPTURE START " + directory);
    }
    public void Tick() { if (Recording && Time.realtimeSinceStartupAsDouble >= deadline) Stop(); }
    public void Frame(byte[] rgba, int width, int height, string metadata)
    {
        Tick(); if (!Recording || Time.realtimeSinceStartupAsDouble < next) return;
        next = Time.realtimeSinceStartupAsDouble + 1.0 / 3;
        try
        {
            if (!image || image.width != width || image.height != height)
            { if (image) UnityEngine.Object.Destroy(image); image = new Texture2D(width, height, TextureFormat.RGBA32, false); }
            image.LoadRawTextureData(rgba); image.Apply(false);
            string file = "frame-" + count.ToString("D5") + ".jpg";
            // Detector pixels are top-left. Unity's image encoder treats the array as bottom-left.
            // Reverse before encoding, so the decoded JPG has the original top-left rows.
            var bottom = new byte[rgba.Length];
            for (int y = 0; y < height; y++) Buffer.BlockCopy(rgba, y * width * 4, bottom, (height - 1 - y) * width * 4, width * 4);
            image.LoadRawTextureData(bottom); image.Apply(false);
            byte[] jpg = image.EncodeToJPG(85);
            File.WriteAllBytes(Path.Combine(directory, file), jpg);
            writer.WriteLine(metadata.TrimEnd().TrimEnd('}') + ",\"image\":\"" + file + "\",\"captureIndex\":" + count + "}");
            writer.Flush(); count++;
        }
        catch (Exception e) { Debug.LogError("TEACHING CAPTURE ERROR " + e.GetType().Name); Stop(); }
    }
    public void Stop()
    {
        if (!Recording) return;
        writer.Flush(); writer.Dispose(); writer = null;
        File.WriteAllText(Path.Combine(directory, "capture.json"), "{\"schema\":\"paper-lab-capture-v1\",\"coordinateSystem\":\"Unity left-handed, metres, quaternion xyzw\",\"imageOrientation\":\"top-left decoded JPG\",\"maxHz\":3,\"audio\":false,\"roomMesh\":false,\"complete\":true,\"frames\":" + count + "}");
        Debug.Log("TEACHING CAPTURE STOP frames=" + count + " directory=" + directory);
    }
    public void Dispose() { Stop(); if (image) UnityEngine.Object.Destroy(image); }
}

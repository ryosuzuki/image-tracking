using System;
using System.Collections;
using System.IO;
using System.Text;
using UnityEngine;
using UnityEngine.Networking;
namespace MRClass
{
public sealed class RelayInput : MonoBehaviour
{
    [Serializable]
    public class Settings
    {
        public string url = "", room = "";
    }
    public Settings Config = new Settings();
    public string Status = "Offline / local controls";
    public Action<LabState> Received;
    public Action<Texture2D> TextureReceived;
    int revision = -1, textureRevision = -1, localIntent;
    bool posting;
    string session = "";
    LabState queued;
    Texture2D texture;
    void Start()
    {
        string path = Path.Combine(Application.persistentDataPath, "relay.json");
        if (File.Exists(path))
            Config = JsonUtility.FromJson<Settings>(File.ReadAllText(path));
        string env = Environment.GetEnvironmentVariable("MR_CLASS_RELAY");
        if (!string.IsNullOrEmpty(env))
            Config.url = env;
        string room = Environment.GetEnvironmentVariable("MR_CLASS_ROOM");
        if (!string.IsNullOrEmpty(room))
            Config.room = room;
        if (!string.IsNullOrEmpty(Config.url))
            StartCoroutine(Poll());
    }
    string Url(string path) => Config.url.TrimEnd('/') + path +
                               "?room=" + UnityWebRequest.EscapeURL(Config.room);
    IEnumerator Poll()
    {
        if (!Uri.TryCreate(Config.url, UriKind.Absolute, out var uri) ||
            (uri.Scheme != "http" && uri.Scheme != "https") || string.IsNullOrEmpty(Config.room))
        {
            Status = "Invalid relay URL / missing room code";
            yield break;
        }
        while (enabled)
        {
            int generation = localIntent;
            using (var req = UnityWebRequest.Get(Url("/state")))
            {
                req.timeout = 3;
                yield return req.SendWebRequest();
                if (req.result == UnityWebRequest.Result.Success)
                {
                    LabState state = null;
                    try
                    {
                        state = JsonUtility.FromJson<LabState>(req.downloadHandler.text);
                        state.Validate();
                    }
                    catch (Exception)
                    {
                        Status = "Rejected invalid remote state";
                    }
                    if (state != null && generation == localIntent && !posting)
                    {
                        Status = "LAN connected / revision " + state.revision;
                        if (state.session != session || state.revision > revision)
                        {
                            if (state.session != session)
                            {
                                session = state.session;
                                textureRevision = -1;
                            }
                            revision = state.revision;
                            Received?.Invoke(state);
                        }
                        if (state.textureRevision > textureRevision)
                            yield return FetchTexture(state.textureRevision);
                    }
                }
                else
                    Status = "Relay unavailable: " + req.responseCode;
            }
            yield return new WaitForSecondsRealtime(.2f);
        }
    }
    public void Send(LabState state)
    {
        if (string.IsNullOrEmpty(Config.url))
            return;
        localIntent++;
        queued = state.Copy();
        if (!posting)
            StartCoroutine(Post());
    }
    IEnumerator Post()
    {
        posting = true;
        while (queued != null)
        {
            var state = queued;
            queued = null;
            using (var req = new UnityWebRequest(Url("/state"), "POST"))
            {
                req.uploadHandler = new UploadHandlerRaw(Encoding.UTF8.GetBytes(JsonUtility.ToJson(state)));
                req.downloadHandler = new DownloadHandlerBuffer();
                req.SetRequestHeader("Content-Type", "application/json");
                req.timeout = 3;
                yield return req.SendWebRequest();
                if (req.result == UnityWebRequest.Result.Success)
                {
                    var s = JsonUtility.FromJson<LabState>(req.downloadHandler.text);
                    s.Validate();
                    revision = s.revision;
                    session = s.session;
                    if (queued == null)
                        Received?.Invoke(s);
                }
                else
                    Status = "Update failed; local action retained";
            }
        }
        posting = false;
    }
    IEnumerator FetchTexture(int incomingRevision)
    {
        if (incomingRevision == 0)
        {
            textureRevision = 0;
            yield break;
        }
        using (var req = UnityWebRequest.Get(Url("/texture.png")))
        {
            req.timeout = 3;
            yield return req.SendWebRequest();
            if (req.result == UnityWebRequest.Result.Success)
            {
                var t = new Texture2D(2, 2);
                if (t.LoadImage(req.downloadHandler.data))
                {
                    if (texture)
                        Destroy(texture);
                    texture = t;
                    textureRevision = incomingRevision;
                    TextureReceived?.Invoke(texture);
                }
                else
                    Destroy(t);
            }
        }
    }
    void OnDestroy()
    {
        if (texture)
            Destroy(texture);
    }
}
}

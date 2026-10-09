using UnityEngine;
using Vuforia;

public class PaperTarget : MonoBehaviour
{
    public Texture2D targetImage;
    public Material surface;
    private ImageTargetBehaviour observer;
    private GameObject cube;
    private bool measured;
    private void Awake() { VuforiaApplication.Instance.OnVuforiaStarted += Started; }
    private void Started()
    {
        observer = VuforiaBehaviour.Instance.ObserverFactory.CreateImageTarget(targetImage, .20f, "paper-target");
        observer.OnTargetStatusChanged += Changed;
        cube = GameObject.CreatePrimitive(PrimitiveType.Cube);
        cube.name = "Measured target cube";
        cube.transform.SetParent(observer.transform, false);
        cube.transform.localPosition = new Vector3(0, .025f, 0);
        cube.transform.localScale = Vector3.one * .05f;
        cube.GetComponent<Renderer>().sharedMaterial = surface;
        cube.SetActive(false);
    }
    private void Changed(ObserverBehaviour source, TargetStatus state)
    {
        measured = state.Status == Status.TRACKED && state.StatusInfo == StatusInfo.NORMAL;
        Debug.Log("VUFORIA TARGET " + state.Status + " " + state.StatusInfo);
    }
    private void Update()
    {
        var provider = GetComponent<MetaCameraProvider>();
        double now = (System.DateTime.UtcNow.Ticks - System.DateTime.UnixEpoch.Ticks) / 10000000.0;
        double age = provider ? now - provider.LastSubmittedTimestampNs / 1000000000.0 : double.PositiveInfinity;
        if (cube) cube.SetActive(measured && Application.isFocused && OVRPlugin.positionTracked && provider && provider.HasSubmittedPose && age >= 0 && age < .25);
    }
    private void OnDestroy()
    {
        VuforiaApplication.Instance.OnVuforiaStarted -= Started;
        if (observer) observer.OnTargetStatusChanged -= Changed;
    }
}

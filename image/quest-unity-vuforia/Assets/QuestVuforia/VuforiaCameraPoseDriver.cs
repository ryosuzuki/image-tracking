using UnityEngine;

// Image-only experimental anchor. Frame/result pairing still needs device acceptance.
[DefaultExecutionOrder(100)]
public class VuforiaCameraPoseDriver : MonoBehaviour
{
    private MetaCameraProvider provider;
    private void Awake() { provider = GetComponent<MetaCameraProvider>(); }
    private void LateUpdate()
    {
        if (!provider || !provider.HasSubmittedPose) return;
        Pose pose = provider.LastSubmittedPose;
        transform.SetPositionAndRotation(pose.position, pose.rotation);
    }
}

# Tracking progress

## 2026-10-09 — acceptance and continuation

This repository is the continuing public home for image/marker tracking implementations and reproducible verification notes. Publish reviewed source and results at meaningful checkpoints. Keep SDK license keys, credentials, private recordings, signing data and device identifiers outside Git.

### ArUco: implemented; optical acceptance is not stereo acceptance

- OpenCV DICT_4X4_50 IDs 7 and 8 are implemented in the native marker lanes; Web marker comparison is also included.
- Historical actual Quest Camera2 observations: ID7 accepted 41/42, ID8 accepted 41/42, rotated ID8 accepted 21/21; absent target rejected 17/17. These are static-headset, monitor-displayed target observations, not printed-paper or head-motion acceptance.
- Actual iPhone native-camera observations also verified IDs 7/8, loss and recovery with a SceneKit scene. Do not relabel this as Quest stereo or finger interaction.
- The Quest Camera2 experiment is monocular camera-relative detection/pose estimation. It is not a successful Unity binocular world-registration test.

### Colored dots and Unity Quest

- Historical transform tests: stationary positive observations 207/207; disappearance rejected 19/19; continuous movement 68/76; full rotation 46/50. Tracking still drops observations under motion.
- A subsequent Unity APK10 device test repaired unsupported CPU-image access using GPU readback and detected ID8 with pose estimation. Headset tracking was invalid, so spatial content/interaction remained gated. Binocular alignment is not accepted.
- APK10 is a downstream device result, **not yet synchronized into the public source snapshot in this repository**. The folder READMEs identify the currently published source revisions.

### Vuforia

- Official developer account authenticated; a free Basic development license was activated and stored privately in 1Password. No key is in the repository.
- Vuforia Unity Engine 11.4.4 package recovered and metadata verified. Official Android SDK 11.4.4 downloaded; archive integrity and publisher SHA-256 matched.
- Added [isolated Vuforia source](image/quest-unity-vuforia/README.md), derived from pinned MIT Quforia source with original notice retained. Proprietary SDK files, upstream keys and sample databases are excluded.
- Android arm64 custom camera driver **built against official SDK headers**. Unity C# **compiled** and the independent Image Target scene was generated.
- Replaced Android-unsupported CPU color reads with GPU readback, capture-time metadata snapshots and Unix-nanosecond timestamps. Added a private runtime license loader, authored 20 cm image target and a shader-referenced cyan cube.
- Android APK **built successfully** with Vuforia, custom driver and the C++ runtime packaged. Installed and updated safely as separate package `org.openclaw.paperlabvuforia`; existing marker app/data remain untouched. Private license-file presence was verified after the update.
- Configured optional hands/controller support for this controller-free cube smoke test. Actual launch attempts are currently stopped at the Quest system `LaunchCheckControllerRequiredDialogActivity` while the headset is asleep. No app process or Vuforia initialization success was observed. This is a device launch gate, not evidence of a Vuforia recognition failure.
- Physical Vuforia initialization, frame ingestion, target tracking and binocular alignment remain **unverified**. Resume with the headset awake/worn and an available controller or enabled hand navigation. No upstream sample video is used as evidence.

### Next acceptance checkpoints

1. Publish the reviewed Unity camera-readback repair with build/dependency instructions.
2. Verify tracking-valid Unity per-eye AR alignment, marker loss/recovery and interactive 3D worksheets on Quest.
3. Implement and separately qualify Vuforia tracking; compare against ArUco and colored dots under matched conditions.

Implementation, software-test, optical-device and binocular-spatial results must remain separately labelled. Build and account gates above are newly checked; physical acceptance remains separately labelled.

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

- Account creation is confirmed; SDK/license setup, frame ingestion and a runnable device integration remain unverified.
- Evaluate natural-image targets for the existing interactive 3D worksheets. On Quest, establish the camera-driver path and per-eye spatial registration before claiming a working integration.
- See [Vuforia research](research/vuforia/README.md). Existing research notes are not an implemented app.

### Next acceptance checkpoints

1. Publish the reviewed Unity camera-readback repair with build/dependency instructions.
2. Verify tracking-valid Unity per-eye AR alignment, marker loss/recovery and interactive 3D worksheets on Quest.
3. Implement and separately qualify Vuforia tracking; compare against ArUco and colored dots under matched conditions.

Implementation, software-test, optical-device and binocular-spatial results must remain separately labelled. This entry summarizes existing evidence; no new device test was performed for this documentation update.

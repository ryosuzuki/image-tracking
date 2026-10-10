# Vuforia Quest physical acceptance

The installed prototype is **not yet a verified tracker**. Build and installation
are separate from camera ingestion, target recognition and binocular alignment.

## Current observations (2026-10-09)

- The home Mac can reach the authorized Quest 3 through ADB.
- The 18:29 cold launch exposed a shell-owned external license-file access
  error and missing SDK agreement metadata. Both are fixed in the rebuilt player.
- The original build script edited only an in-memory Vuforia configuration.
  It now persists `Resources/VuforiaConfiguration.asset` with SDK 11.4 agreement
  state, checks that both license fields are empty, and never packages a key.
- The first rebuilt player then failed to load the custom driver because the
  code passed a bare library stem. SDK 11.4 requires the complete packaged
  filename; it now passes `libquforia.so`.
- The final full Unity/Android IL2CPP build succeeded. Same-signature
  `adb install -r` succeeded; the installed APK hash matches the built artifact
  (`e03a403956d43b725ebe9ff1df8b21a9b2233f6e6efebc8988252c4067846051`).
- At 19:11, a real Quest cold launch logged `Vuforia Initialized`,
  `VUFORIA INIT NONE`, and `VUFORIA CAMERA calibrated (1280, 960)`.
  The app-private license file remained present and readable after the update.
- The authored target was presented on the home monitor at the specified 20 cm
  width and was visible in a Quest compositor screenshot. No
  `VUFORIA TARGET TRACKED NORMAL` occurred. The screenshot showed the Quest's
  **Finding position in room** overlay; the headset did not maintain a valid
  physical tracking session. No cube alignment/video acceptance is claimed.
- No SDK archive, license value or private logs belong in this public repository.

## Driver repair and remaining registration audit

1. `Native/src/external_camera.cpp` previously advertised 60 fps, while
   `MetaCameraProvider.cs` requests 30 fps. The native advertised mode now matches
   the input stream at 30 fps.
2. The native delivery thread reads `acquireLatestFrame()`, whose queue entry is
   not consumed. A new per-session timestamp gate now rejects duplicate,
   backwards and nonpositive timestamps. The scoped C++ test covers camera
   stalls, out-of-order frames and fresh-session restart.
3. `VuforiaCameraPoseDriver` uses the latest successfully submitted camera pose.
   That is not evidence that a Vuforia result belongs to that same exposure.
   Measure result/capture timing before accepting moving-head registration.
4. The active native driver advertises image-only tracking. Its external pose
   tracker is disabled due a known coordinate-convention offset; source code
   for pose delivery must not be mistaken for an active runtime path.

The native driver was rebuilt against official Vuforia 11.4.4 Android headers
and tested. The full C# player was subsequently rebuilt with Unity 6000.4.5f1
and Android IL2CPP, then installed under the unchanged package identity and
signer. Rebuilding requires the private official SDK and Android toolchain;
do not replace them with unofficial binaries.

## Acceptance sequence

1. Coordinate exclusive device use with the PaperLab demo lane. Preserve the
   original app and install updates only with `adb install -r`.
2. Open **PaperLab Vuforia Prototype**, not a browser. Display
   [paper-target.png](Assets/Resources/paper-target.png) at measured 20 cm width.
3. Confirm a real application process, `VUFORIA INIT` success, native camera
   startup, calibrated 1280 × 960 input, and strictly increasing capture times.
4. Require `VUFORIA TARGET TRACKED NORMAL` from this authored target. Do not count
   initialization, installation, extended tracking or text telemetry as success.
5. Verify the cyan 5 cm cube in actual compositor capture: both eyes, correct
   scale, target-relative location, moving-head parallax and no pink material.
6. Move and rotate the target. Test brief occlusion, long loss, reacquisition,
   application pause/resume and headset-origin reset. During invalid/stale
   tracking the cube must disappear rather than retain an apparently valid pose.
7. Retain a dated recording and redacted telemetry outside the public repo; publish
   only a small location/hash receipt and the exact passed/failed gates.

A headset left on a desk may provide build/startup evidence but cannot establish
the physical binocular alignment gate. A prerecorded or synthetic animation is
not a substitute for the requested live Quest demonstration.

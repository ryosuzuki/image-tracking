# Vuforia Quest physical acceptance

The installed prototype is **not yet a verified tracker**. Build and installation
are separate from camera ingestion, target recognition and binocular alignment.

## Current observations (2026-10-09)

- The home Mac can reach the authorized Quest 3 through ADB.
- A read-only continuation check found the headset asleep, with proximity false.
- The earlier launch attempt stopped in the system controller-required dialog,
  before the application process started.
- A coordinated native-only safe update and brief launch attempt again stopped
  at the same system dialog, with no application process. The independent
  PaperLab rendering/demo lane regained device priority immediately afterward.
- The installed APK digest matches the repaired artifact exactly. Existing
  private license bytes were also provisioned at Unity's Android external
  persistent-data destination; their equality was checked without emitting them.
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

The driver was rebuilt successfully against the official Vuforia 11.4.4 Android
headers and the Unity Android NDK. A native-only development APK update was
assembled from the installed prototype: the only changed non-signature entry
is `lib/arm64-v8a/libquforia.so`. Its signature verifies and its signing
certificate matches the installed application. This method preserves the C#
player, package identity and existing private runtime license provision without
requiring a second large Unity import during the parallel demo build.

This is a repair/build checkpoint, not a successful physical acceptance test.
Rebuilding requires the private official SDK and Android toolchain; do not
replace them with unofficial binaries.

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

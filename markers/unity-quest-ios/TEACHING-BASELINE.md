# Native Quest teaching baseline

This is a **test build**, not an accepted paper-locked binocular demonstration. Use the native **Interactive Paper Lab** application, not Vuforia, the paper viewer or Quest Browser. Package identity is `org.openclaw.markertrackinglab`; version 0.12-teaching-baseline / code 12.

## Build the same slice

Use Unity 6000.4.5f1 with Android IL2CPP, its SDK/NDK/JDK, and the pinned packages in this project. The marker lane uses Meta XR / MRUK 203, URP 17.4 and official OpenCV 4.12.0. It does not require a Vuforia key or package.

```sh
bash Tools/fetch-marker-opencv.sh
bash Tools/build-marker-native.sh
# Optional MARKER_APK selects an explicit APK destination; default is Builds/marker-tracking-lab.apk.
Unity -batchmode -nographics -quit -projectPath "$PWD" -buildTarget Android \
  -executeMethod MarkerBuild.Android -logFile /path/to/private-build.log
python3 Tools/validate-paper-learning.py
python3 Tools/test-dim-lcd-classifier.py
python3 Tools/test-teaching-take.py
```

The build keeps the procedural solar scene as its first baseline. Existing eight applications remain independent manually selected models. No additional catalog was added. Tracker thresholds, input freshness, unreliable-session and origin-reset gates are unchanged.

The teaching build disables the SDK-generated developer agent and clears its editor authentication/address **after** the SDK's own build hook. Missing privacy fields fail the build instead of silently shipping remote editor access. Numeric telemetry stays app-local; automatic raw camera-frame dumping is disabled. Compositor video and telemetry collection require an explicitly owned test window.

## Safe device handoff

1. Enumerate the USB device; check current foreground/XR session, active camera clients and operation owner. Do not stop another user's running app. Preserve user-owned continuous set-down settings and its recovery worker.
2. Check this exact package's running state and installed APK/signing certificate. A remembered version in PackageManager is not sufficient if `pm path` is empty.
3. Compare certificates before using `adb -s SERIAL install -r APK`. **Never uninstall** to resolve a conflict; that can erase retained app data. Keep the existing other apps/recordings unchanged.
4. Installing a distinct stopped package does not authorize launching it over the current camera owner. Launch only after a coordinated handoff.

## First actual acceptance: one target, one model

Display or print [dots-8.png](../web-webxr/public/markers/dots-8.png), measuring **120 mm between opposite dot-corner centers**. Screen size is not print calibration. Wear a positionally tracked compatible Quest; camera permission and powered-awake state are separate gates. Start with Solar, then Cube net, then Pendulum. Y selects application; X selects tracking method; A pauses; B resets; thumbstick click invokes the application's action.

Require real camera startup and increasing capture timestamps; detect the expected ID under valid tracking; then inspect both eyes, metric scale, target-relative location and moving-head parallax. Verify one real action, target loss/recovery and stale/invalid hiding. A static monitor test does not qualify printed or physically moving paper, and a numerical reprojection residual is not world-registration accuracy.

## Telemetry analysis

The app records calibration.json and frames.jsonl under its private recording directory. Copy only an explicitly selected take within the device-owner window; preserve its original. The v12 rows add application, simulation/parameter values, current HMD/position-tracking/camera flags and target visibility to existing detector/pose/timestamp fields.

```sh
python3 Tools/analyze-teaching-take.py /path/to/private-take/frames.jsonl
```

The analyzer rejects non-increasing sequence/capture times, accepted IDs with stale/invalid pose, and interaction without a reliable fresh observation. It separates detector-positive, accepted-ID and reliable-session counts. It **cannot** prove a correct physical ID, binocular rendering/alignment, physical interaction or printed-paper accuracy. Its nine software tests are fabricated telemetry controls, never device evidence.

## Distribution and notices

Release assets, not Git, are the location for APKs. Retain this project's MIT upstream notice, SOURCE-LICENSE.md and applicable OpenCV/Unity/Meta notices. The default scene uses authored geometry and public marker artwork, not private worksheet scans or proprietary Vuforia assets. Unity/Meta SDK terms still apply; a debug test build is not an official Meta store release. Do not imply compatibility from the inherited broad manifest device list: camera baseline testing is Quest 3, with Quest 3S requiring separate acceptance. Package/API minimum and signer must be checked from the final APK before distribution.

## Current physical gate

The fresh 2026-10-12 inspection found another distinct native paper-AR application actively holding both passthrough cameras with an active XR session. That session and the persistent awake/recovery settings were preserved. This teaching build was **not launched** over it. Thus new camera ingestion, ID detection, calibrated pose and binocular scene acceptance remain pending a coordinated device window and actual physical target test.

## 2026-10-12 build checkpoint

- Full pinned-Unity Android IL2CPP build and APK signature verification passed.
- Final APK: **87,443,652 bytes**, SHA-256 `e678e415ede51d8a39ba2a2b3ce5e944dbd6bb049328c89fe02bece840464d9a`.
- Final APK metadata: package/version as above, ARM64, minimum Android API **32**, target API **34**. Its inherited device manifest is not a camera compatibility test.
- Debug signer SHA-256: `190141514c5bd7509c60bb9d072135733d1830b44e01f0efbb8adbb8a045b7ea`. It matches an earlier retained marker release artifact, but the current device's remembered marker-package record has no readable installed APK; exact current-device signer parity was not established. No install or launch was attempted.
- Fresh software checks passed: **284** mathematical, **42** calibration/timestamp/pose, **12** classifier and **9** telemetry tests (including malformed-row controls).
- Independently parsed the actual APK's serialized developer-agent settings: **disabled**, **empty server address**, **empty access token**. No Vuforia assets are present. APK native detector/runtime input digests were reconciled with the package: OpenCV bytes identical; marker core and C++ runtime exactly match `llvm-strip --strip-unneeded` output.
- Camera ingestion, actual ID correctness, moving-head pose/scale/parallax and binocular paper registration are all **unverified for this build**. The other active dual-camera application and continuous awake worker were left unchanged.

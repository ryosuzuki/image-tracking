# Native capture → JavaScript replay → a reproducible student demo

The v14 **Interactive Paper Lab** APK contains all eight authored teaching models and an explicit sensor-capture feature. [Release download](https://github.com/ryosuzuki/image-tracking/releases/tag/teaching-menu-v14-2026-10-12) · [Viewer and editable JavaScript](../../docs/capture-viewer/) · [Open hosted viewer](https://ryosuzuki.github.io/image-tracking/capture-viewer/)

## 1. Install without Unity

Enable Quest developer mode and authorize USB debugging. Use Quest 3; Quest 3S has not been independently accepted. Download the release APK and verify its SHA-256 against the release notes. With Android Platform Tools installed:

```sh
adb devices -l
adb -s YOUR_SERIAL install -r interactive-paper-lab-v14.apk
```

Never uninstall to bypass a signing mismatch: it can erase existing recordings. Start **Interactive Paper Lab** from Unknown Sources and allow camera permission. Finish normal headset tracking/boundary setup. Camera access, device wake and spatial tracking are independent.

Print [dots-8](../../markers/web-webxr/public/markers/dots-8.png) or the [calibrated print kit](../../docs/lecture-hub/print-kit/) at 100%. Measure **120 mm between opposite dot-corner centers**. A monitor image is not a printed-paper test.

## 2. One app with an eight-lesson menu

The single **Interactive Paper Lab** APK opens a head-relative lesson menu containing all eight demonstrations. The left controller Menu button shows/hides it. Move the left stick up/down (or press Y) to highlight; press A to select. Selection clears stale marker observations; the AR lesson stays hidden until a fresh, reliable target is acquired. Menu navigation is not a paper interaction and does not claim registration.

Outside the menu, Y selects Solar, Geometry, FunctionGraph, InclinedPlane, Pendulum, Circuit, Vectors and Binomial. X changes tracker, A pauses, B resets, left stick click invokes the lesson action, sticks change parameters, and left grip enables measured paper-dial input. Lesson controls require a fresh reliable marker observation. No arbitrary worksheet recognition is inferred.

## 3. Record an explicit take

Click the **right thumbstick** to start/stop a take (maximum 60 seconds, target at most 3 source frames/second). The native app uses the same sensor pixels and capture-time pose metadata as its detector. It stores top-left decoded JPGs, UTC microsecond exposure times, intrinsics, camera pose, paper pose, lesson parameters and tracking flags. It records **no microphone audio, room mesh, depth or hands**. Numeric diagnostic logs remain separate from explicit image takes.

Captures are app-local under `/sdcard/Android/data/org.openclaw.markertrackinglab/files/teaching-take-*`. Capture closes on focus/pause loss, origin reset, deadline or app disposal. Nothing is automatically published or sent to a server. For a deliberate bounded diagnostic from ADB, launch with `--ei captureSeconds 8`; this does not create valid SLAM or marker detection.

```sh
adb -s YOUR_SERIAL shell ls /sdcard/Android/data/org.openclaw.markertrackinglab/files/
bash tools/teaching-capture/pull.sh YOUR_SERIAL teaching-take-EXACT-NAME /path/to/private-captures
python3 tools/teaching-capture/export_take.py /path/to/private-captures/teaching-take-EXACT-NAME
# Optional camera-only derivative, timed to actual source observations:
python3 tools/teaching-capture/export_take.py /path/to/take --mp4 /path/to/camera.mp4 --report /path/to/report.json
```

Originals remain on Quest. Use your own recordings; public source contains no room takes or private logs. Take validator success does not establish physical registration accuracy.

## 4. Replay and modify the code

Open the [hosted viewer](https://ryosuzuki.github.io/image-tracking/capture-viewer/) and select the copied take folder. Local files remain in the browser. Play/seek, choose an authored example, inspect the tracking state, and record a derivative WebM. Editing [`viewer.mjs`](../../docs/capture-viewer/viewer.mjs) changes the lesson geometry/behavior; the JavaScript demonstrations are simplified variants, not pixel-identical Unity output.

Offline/local development requires no npm install:

```sh
python3 -m http.server 8080 --directory docs
# Open http://localhost:8080/capture-viewer/
node --test docs/capture-viewer/replay-math.test.mjs
python3 -m unittest discover -s tools/teaching-capture -p 'test_*.py'
```

Three.js r164 is vendored with its MIT license. The sensor projection uses measured intrinsics and an explicit Unity-left-handed → Three.js-right-handed conversion. Paper geometry follows the recorded paper pose; invalid tracking hides it. No occlusion or independent moving-object track is invented. Synthetic sample mode is clearly labeled and never presented as Quest evidence.

For full room geometry, hands, depth and richer scene authoring, use the separate [Spatial Capture recorder/editor](https://github.com/ryosuzuki/quest-spatial-studio). It remains a separate app with separate capture format; it is not silently replaced by this lightweight lesson recorder. Naz's public [AI-AR-Project](https://saharnaz-hdvnd.github.io/AI-AR-Project/) is an example of sharing recordings, editable JavaScript and viewer resources; her private recordings were not copied.

## Build from source

Follow [the Unity project README](../../markers/unity-quest-ios/README.md) and [native baseline guide](../../markers/unity-quest-ios/TEACHING-BASELINE.md), using Unity 6000.4.5f1 / ARM64 / IL2CPP / official OpenCV 4.12.0. New capture code is [`TeachingCapture.cs`](../../markers/unity-quest-ios/Assets/MarkerLab/TeachingCapture.cs) plus the explicit hooks in `QuestMarkerTracker.cs`. APKs belong to Releases, not Git.

## What counts as a successful demo?

Build, install, camera ingestion, source capture, calibrated replay, printed-paper detection and paper-locked binocular interaction are separate results. Verify actual head translation/parallax, marker loss/recovery and real physical input before calling a live AR lesson accepted. The released development build and a recorded composite alone do not prove these outcomes.

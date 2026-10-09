# Colored dots + ArUco — Unity Quest + separate iOS project

For the installed device test, start with the [Quest quick start](../../QUEST-QUICKSTART.md) and [target image index](../../TRACKING-IMAGES.md). Use the native app, not the Quest browser. The Android source now uses GPU readback and a resource-retained URP stereo surface shader. See [demo repair and device acceptance](DEMO-STATUS.md).

## Implementation

- Target form: **Colored dots + ArUco**
- Engine: **OpenCV / Meta XR or ARFoundation**
- Platform: **Unity Quest + separate iOS project**
- Upstream source: https://github.com/ryosuzuki/quest-dot-marker-lab at `66a0db3aec789cbc4e9abd3d25d298867677a157`
- This is a separate source snapshot, not a submodule. Existing upstream repositories were not modified. Public release edits remove private environment/evidence and non-redistributable assets.

## Build

Run inside this folder. See the root [asset instructions](../../ASSETS.md) for excluded assets and dependencies.

```sh
Tools/fetch-marker-opencv.sh
Tools/build-marker-native.sh
Tools/build-marker-ios-native.sh
Tools/sync-marker-ios.sh
Unity -batchmode -quit -projectPath "$PWD" -buildTarget Android -executeMethod MarkerBuild.Android
```

Node projects use their pinned package-lock. Unity projects require Unity6000.4.5f1 and corresponding Android/iOS modules. Swift requires full Xcode and matching SDK. iOS physical builds require your own authorized signing configuration. Quest requires camera/headset-camera permission, valid positional tracking and supported camera hardware/runtime. No signing credentials or Vuforia licenses are included.

## Scope and acceptance

Use root for Quest; ios-unity for iOS, not root. World-space calibrated tracker source exists; build/install does not establish physical stereo tracking.

This consolidation validates copied source inventory, privacy gates and scoped software checks. It does not rerun physical camera, binocular, printed-paper or finger/controller acceptance. Historical upstream acceptance records are not reproduced as fresh evidence. The preserved app catalogs depend on optional private educational figures and generated models, which are deliberately not public.

## Licenses

Original LICENSE, third-party licenses, legal notices and source headers are retained where present. If upstream has no top-level license, no new license is inferred. Dependencies retain their own terms; this repo does not relicense them.

## APK11 rendering/camera repair

APK11 uses the native package `org.openclaw.markertrackinglab` and keeps its existing data during `adb install -r`. It does not replace `PaperLab Vuforia Prototype`.

- Camera pixels: `AsyncGPUReadback`, with image timestamp and `GetCameraPose()` snapped before the asynchronous request; top-left RGBA conversion before OpenCV. Android does not call the unsupported CPU-image API.
- 3D materials: `Resources.Load<Shader>("MarkerQuestSurface")` keeps the shader in the player. The shader uses URP transforms and single-pass stereo macros; missing or unsupported shaders fail explicitly.
- Real authored meshes: solar spheres/orbit/rotating cube, hinged cube net, function tube, inclined plane, pendulum, circuit, vectors and probability bars. Y changes application; stick click changes its action. They are not automatic semantic recognition of the worksheet diagram.
- Tracking validity, freshness, focus/pause and origin-change gates remain enabled. A screen recording is not a calibrated sensor/pose capture.

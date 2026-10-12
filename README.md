# Image Tracking

Image and marker tracking implementations, organized by target type, engine and platform. Each folder is an independent source snapshot, not one shared application.

## Start here: Quest

**Current teaching checkpoint (2026-10-12):** [v12 test-build instructions](markers/unity-quest-ios/TEACHING-BASELINE.md) and [calibrated A4/Letter print kit](https://ryosuzuki.github.io/image-tracking/lecture-hub/print-kit/). Version12 adds readiness telemetry and disables automatic raw-frame dumps / SDK developer-agent access. It is not an accepted live binocular paper demonstration. Historical installed-APK statements below are dated observations, not current installation/readiness checks. Preserve the active camera owner before launching a different app.

**Use the native Unity app, not the Quest browser; check that the exact package is actually installed first.** Open **App Library → Unknown Sources → PaperLab / Interactive Paper Lab**. On the computer, display **dots-8.png**, then look at it through the headset.

- **[Quest quick start: exactly what to open](QUEST-QUICKSTART.md)**
- **[Tracking images: direct links and which app uses them](TRACKING-IMAGES.md)**
- **[Current implementation and device acceptance](PROGRESS.md)**

The installed APK10 detected colored-dot ID8 and estimated its pose. Binocular alignment and interaction are **not yet accepted**; invalid headset tracking gates spatial content. The published Unity snapshot is older than that installed repair; see PROGRESS.md.

## Design exploration

**[20 recognition-pattern concepts and dynamic-system recommendation](design/recognition-patterns/README.md)** · **[20 AR content ideas](design/recognition-patterns/DISPLAY-CONTENT.md)**. Includes an illustrated contact sheet, editable SVGs, tradeoffs and a proposed multi-sheet acceptance experiment. These are design proposals, not validated tracking targets or implemented demos.

## Implementation map

| Folder | Target | Engine | Platform |
|---|---|---|---|
| [image/8thwall-web](image/8thwall-web/README.md) | Natural image | 8th Wall | Browser camera / optional WebXR |
| [image/arkit-swift](image/arkit-swift/README.md) | Natural image | ARKit / SceneKit | Swift iPhone / iPad |
| [image/quest-native-opencv](image/quest-native-opencv/README.md) | Natural image | OpenCV ORB + RANSAC / Camera2 | Quest Android |
| [image/quest-unity-artoolkit](image/quest-unity-artoolkit/README.md) | Natural image | ARToolKitX / Meta XR | Unity Quest |
| [markers/web-webxr](markers/web-webxr/README.md) | Colored dots / ArUco | Custom dots / ArUco | Web camera / capability-gated WebXR |
| [markers/arkit-swift](markers/arkit-swift/README.md) | Markers / image baseline | OpenCV / ARKit | Swift iPhone |
| [markers/unity-quest-ios](markers/unity-quest-ios/README.md) | Colored dots / ArUco | OpenCV / Meta XR or ARFoundation | Unity Quest / separate iOS project |
| [image/quest-unity-vuforia](image/quest-unity-vuforia/README.md) | Authored natural image | Vuforia 11.4.4 / custom driver / Meta XR | Unity Quest prototype; device acceptance pending |

Colored dots and ArUco are marker types; ARKit, OpenCV, ARToolKitX and Vuforia are engines/SDKs. WebXR is an execution API, not an image-recognition engine. These are not claimed to be copies of official Realtalk.

## Browser development

```sh
cd markers/web-webxr
npm ci
npm run verify
npm run test:applications
npm run build
npm run dev
```

Open the server URL, present a marker on another screen or paper, and start the camera. Remote-device camera use requires HTTPS and permission. Passing synthetic tests does not establish physical accuracy or Quest browser camera support.

For Unity markers, the folder root is Quest; `ios-unity` is the separate iPhone project. Image Unity and marker Unity are separate projects. The current visionOS virtual-paper scene uses simulated pose, not verified physical image tracking.

## Assets, verification and licenses

See [ASSETS.md](ASSETS.md) for dependencies and authorized asset restoration, and [VERIFICATION.md](VERIFICATION.md) for checks. Private recordings, room scans, personal photos, signing credentials, SDK keys and non-redistributable reference pages/models are excluded. Authored marker cards and synthetic fixtures are included. Each folder records its upstream revision; public access does not grant access to private upstream repositories.

Original per-folder licenses and third-party notices remain authoritative; no blanket license overrides them.

Related repositories: [3d-generation](https://github.com/ryosuzuki/3d-generation), [digital-twin](https://github.com/ryosuzuki/digital-twin), [3d-avatar](https://github.com/ryosuzuki/3d-avatar).

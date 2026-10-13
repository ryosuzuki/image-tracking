# Quest quick start

> **Current student kit: v14** — [APK](https://github.com/ryosuzuki/image-tracking/releases/tag/teaching-menu-v14-2026-10-12), [installation + explicit native capture](tools/teaching-capture/README.md), [local-file replay viewer](https://ryosuzuki.github.io/image-tracking/capture-viewer/). All eight teaching models are included. Older install/camera observations below are historical, not live alignment acceptance.

> **Current teaching baseline, 2026-10-12:** See [version12 test-build / safe handoff instructions](markers/unity-quest-ios/TEACHING-BASELINE.md) and the [calibrated printable kit](https://ryosuzuki.github.io/image-tracking/lecture-hub/print-kit/). The older APK10/version11 observations below do not establish current installed state or new physical acceptance. Another app currently owns both Quest cameras; it was preserved. Paper-locked binocular alignment remains unaccepted.

## What to open

**Quest: native app. Computer: target image. You do not open the target image inside Quest.**

1. Keep Quest connected by USB if collecting device logs. Put on the headset and finish the normal boundary/home prompts.
2. In Quest, open **App Library → Unknown Sources** (the location may vary by OS version).
3. Launch **PaperLab** as previously identified on the installed device. The Unity source product name is **Interactive Paper Lab**; look for that name if PaperLab is not listed.
4. Allow camera access if prompted.
5. On the computer, open **Tracking Images → markers → dots-8.png** from the prepared desktop folder. Display the whole card at a readable size without clipping its colored dots.
6. Look at the card through the headset with all corner dots visible and the headset awake, worn and positionally tracked.

Start with **dots-8.png only**. You do not need to open every image. If using the repository instead of the prepared desktop folder, download [dots-8.png](markers/web-webxr/public/markers/dots-8.png) and display it in an image viewer.

## What is verified

Installed APK10: GPU-readback camera path, colored-dot ID8 detection and pose estimation observed. Invalid headset tracking prevented spatial content and interaction in that test. **A paper-locked binocular 3D demonstration is not yet verified.** A blank spatial scene does not prove camera detection failed; tracking validity and target detection are separate gates.

ArUco IDs 7/8 have historical Quest monocular camera acceptance. This is not proof that all modes or target images work in the installed Unity app. See [progress](PROGRESS.md).

## App versus browser

- Current Quest marker test: native Unity Android app, source at [markers/unity-quest-ios](markers/unity-quest-ios).
- Browser/WebXR comparison: [markers/web-webxr](markers/web-webxr/README.md). This requires its own server, HTTPS and camera permissions. Quest browser paper tracking plus binocular AR has not been accepted.
- Natural-image experiments: separate apps under [image](image); arbitrary worksheet images are not interchangeable with dots-8.png.
- Vuforia: account created, but no runnable integrated app or verified device result yet.

## Source versus installed build

The installed APK10 camera-readback repair is not yet synchronized into this public source snapshot. Building the published snapshot is not a way to reproduce that installed repair yet. Build dependencies and commands are in the [Unity README](markers/unity-quest-ios/README.md); acceptance status is in [PROGRESS.md](PROGRESS.md).

## Separate Vuforia test app

The independent **PaperLab Vuforia Prototype** APK is installed in Unknown Sources. Do not open the browser or the original marker app for this test. On the computer open **Tracking Images → vuforia-paper-target.png**, also available [here](image/quest-unity-vuforia/Assets/Resources/paper-target.png). The nominal target width is **20 cm**. The first test is a cyan cube, not the full lesson catalog.

Headset sleep/controller-required launch checks currently prevent runtime verification. Wake/wear Quest and make a controller or enabled hand navigation available. See the [Vuforia guide and acceptance status](image/quest-unity-vuforia/README.md); successful target tracking and binocular alignment are not claimed yet.

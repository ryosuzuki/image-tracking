# Vuforia — research only / 未実装

Vuforia is an SDK/engine, not a marker type. It can support natural-image targets, but no runnable Vuforia implementation or SDK/Driver.h was found in the inspected existing project snapshots. Existing Quest alternatives are OpenCV and ARToolKitX, not Vuforia. The user confirmed on2026-10-09 that a Vuforia account has been created. SDK installation, configured license and working implementation remain unverified. No new registration, license acceptance or SDK installation was performed for this organization task.

Possible Quest route: calibrated real RGB frames plus capture-time camera pose through Vuforia custom Driver Framework; Meta/OpenXR owns per-eye rendering. Quest compatibility is not established by this specification. SDK/license and a real frame-ingestion/build/device test would be needed.

Official references: [supported versions](https://developer.vuforia.com/library/vuforia-engine/platform-support/supported-versions/), [Driver Framework](https://developer.vuforia.com/library/vuforia-engine/platform-support/camera/driver-framework/driver-framework/), [custom driver](https://developer.vuforia.com/library/vuforia-engine/platform-support/camera/driver-framework/simple-driver/creating-custom-driver/).

Source evidence: existing upstream `quest-native-image-lab/docs/vuforia-stereo-integration.md` and `quest-artoolkit-stereo/README.md`; private evidence is retained outside this public repo. This folder is deliberately documentation, not a fake Vuforia app.

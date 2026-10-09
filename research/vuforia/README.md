# Vuforia integration

Implementation now lives in [image/quest-unity-vuforia](../../image/quest-unity-vuforia/README.md). It is an isolated Unity/Android source project, not yet an accepted physical tracking demo. The existing colored-dot/ArUco app remains separate.

Verified on 2026-10-09: official account login, free Basic development license activation, official Android SDK 11.4.4 download with matching publisher SHA-256, native arm64 driver build with official headers, and Unity script compilation/scene preparation. The private license is stored in 1Password and is not distributed with source or SDK files. APK/device gates are recorded in [PROGRESS.md](../../PROGRESS.md).

The experimental Quest route uses Meta PCA RGB frames and Vuforia's camera-only Driver Framework, while Meta/OpenXR owns binocular rendering. The adapter has been rewritten to use GPU readback instead of Android-unsupported CPU color access. Pose fusion remains disabled in the upstream driver; image/result timing and visual alignment need measured device acceptance. Existing upstream sample videos are not proof for this project.

Official references: [supported versions](https://developer.vuforia.com/library/vuforia-engine/platform-support/supported-versions/), [Driver Framework](https://developer.vuforia.com/library/vuforia-engine/platform-support/camera/driver-framework/driver-framework/), [custom driver](https://developer.vuforia.com/library/vuforia-engine/platform-support/camera/driver-framework/simple-driver/creating-custom-driver/), [custom eyewear](https://developer.vuforia.com/library/vuforia-engine/platform-support/camera/driver-framework/vuforia-support-custom-devices-using-vuforia-driver/).

Quest is not listed as an officially supported Vuforia device. The custom-driver path is experimental, not a claim of official Quest support.

# Quest Vuforia prototype

An isolated native Unity/Android Image Target experiment. **Not a browser app and not an accepted physical tracking demo.** The existing colored-dot/ArUco app is unchanged.

## Architecture

Meta XR provides left RGB camera images, calibrated intrinsics, headset tracking and binocular rendering. Vuforia 11.4.4 recognizes a registered runtime image through the custom Android arm64 driver. Unity renders a cyan 5 cm cube over compositor passthrough.

The camera adapter uses `GetTexture` plus ordered `AsyncGPUReadback`, not Android-unsupported `GetColors`. It snapshots the public PCA timestamp and camera pose before readback, converts RGBA bottom-up rows to RGB top-down rows, and uses Unix nanoseconds instead of overflowing .NET wall-clock ticks. Pixel orientation, result/pose synchronization and physical registration still need device validation.

The upstream driver's positional fusion remains disabled; this is an image-only experimental camera anchor, not occlusion-stable world tracking. No guessed camera pose is substituted when headset tracking is invalid. Extended/lost target states hide the cube rather than presenting them as fresh image tracking.

## Dependencies and build

- Unity 6000.4.5f1 with Android IL2CPP, SDK/NDK and CMake/Ninja.
- Meta XR Core / MRUK 203; URP 17.4.
- Vuforia Unity Engine **11.4.4**, privately installed at `Packages/com.ptc.vuforia.engine-11.4.4.tgz`.
- Official native SDK headers at an external `VUFORIA_INCLUDE_DIR` containing `VuforiaEngine/Driver/Driver.h`. Proprietary SDK archives/headers/binaries are not republished here.
- A free Basic development license from the owner's Vuforia account. Keys are not in this repository or packaged assets.

```sh
export ANDROID_NDK_ROOT=/path/to/android-ndk
export VUFORIA_INCLUDE_DIR=/path/to/vuforia/include
export CMAKE_BIN=/path/to/cmake
# Ensure Ninja is in PATH.
bash Tools/build-native.sh
python3 Tools/make-target.py  # requires Pillow; deterministic authored target
Unity -batchmode -nographics -quit -projectPath "$PWD" \
  -buildTarget Android -executeMethod VuforiaBuild.Prepare -logFile prepare.log
Unity -batchmode -nographics -quit -projectPath "$PWD" \
  -buildTarget Android -executeMethod VuforiaBuild.Android -logFile build.log
```

`Prepare` compiles scripts and generates the independent scene and shader-referenced material. `Android` creates `Builds/paperlab-vuforia.apk`; package ID `org.openclaw.paperlabvuforia` does not replace the existing marker app. Install with `adb install -r`. The native plugin and SDK are generated/installed dependencies, not public source assets.

Privately provision `vuforia-license.txt` into this development app's Unity Android persistent-data directory (`/sdcard/Android/data/org.openclaw.paperlabvuforia/files`) using a secure local 1Password workflow. An ADB `run-as` file in the internal `files` directory alone is **not** Unity's `Application.persistentDataPath`. Transfer concealed bytes to the actual destination and verify equality without printing them. Never put a key in a shell argument, committed Unity config, StreamingAssets, screenshot or log. Missing keys cause explicit initialization failure without silently using an upstream developer's key.

## What to open

The development APK has been built and installed on the test Quest. To perform the still-pending physical acceptance test, launch **PaperLab Vuforia Prototype** from Quest's Unknown Sources. On the computer display [paper-target.png](Assets/Resources/paper-target.png), with its printed/displayed width measured at **20 cm**. This target is different from `dots-8.png`; runtime image recognition does not use the dot detector or require a portal target database.

The intended first augmentation is one cyan cube, not the full educational catalog. Passing this smoke test is required before porting the lessons.

## Acceptance gates

See [physical acceptance and driver repair](DEVICE-ACCEPTANCE.md) for the
continuation checkpoint and remaining timing/registration checks. Run
`bash Tools/test-native-timestamps.sh` for the SDK-independent native frame gate
test; this test does not prove physical tracking.

1. Native driver build and Unity script/scene preparation.
2. APK build, private license initialization, real camera start/frame delivery.
3. Vuforia reports `TRACKED / NORMAL` for this target on the actual Quest.
4. Cyan cube with correct scale, per-eye disparity and moving-head parallax.
5. Target movement/rotation, short occlusion, long loss, reacquisition and headset-origin reset. Record compositor video and telemetry; upstream sample videos are not evidence for this implementation.

Quest is not listed as an officially supported Vuforia device. The custom-driver experiment needs its own measured acceptance; Android support alone does not establish Quest support.

## Provenance

Native driver and bridge derived from [Quforia](https://github.com/danieloquelis/Unity-QuestVuforia), pinned revision `66ac200dc8c745cef472b58eb83d58707676bf9f`. The original MIT notice is preserved in [LICENSE.upstream](LICENSE.upstream). Our GPU camera adapter, private runtime license initialization, target creation and build scene are additions/revisions. No upstream license, target database, pretrained model, sample recording or proprietary SDK is copied into this public folder.

## Current device checkpoint

Native build, Unity scene preparation, APK build and safe device install/update passed on 2026-10-09. A private runtime license file was provisioned and retained across the update. The manifest supports optional hands/controllers, and developer-agent settings are disabled for the player and excluded from public source.

The continuation repaired duplicate native frame delivery and the advertised
camera-rate mismatch. The rebuilt native-only APK update passed signature,
package, archive-entry and installed-digest checks; the private license was
verified at Unity's actual Android persistent-data destination. See
[DEVICE-ACCEPTANCE.md](DEVICE-ACCEPTANCE.md). No Vuforia initialization or target
tracking acceptance is implied by these repairs.

The headset is currently asleep. Launch requests stop in the Quest system controller-required dialog before an app process starts; Vuforia initialization and camera/target ingestion are therefore not verified. Wake/wear the headset and make a controller or configured hand navigation available, then perform the acceptance gates above. Do not interpret installation as a working tracker.

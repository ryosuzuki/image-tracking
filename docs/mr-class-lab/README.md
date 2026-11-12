# MR Class Lab — one Unity / Quest project

Six editable interaction building blocks in one app, extending the earlier image-tracking and avatar classes. This is implementation material, **not a new slide deck** and not a gallery claiming to reproduce complete research systems.

## What runs

| Component | Actual input → visible behavior | Boundary |
|---|---|---|
| Find a book | Select a registered target → highlighted book and guidance path | Authored registry, not automatic book recognition |
| Physical tutorial | Action → next 3D stroke; Reset → empty tutorial | Authored tutorial, not recognition of a learner's progress |
| Speech / captions | Typed or explicitly started browser speech → captions in Unity | Browser speech depends on the browser service; translations are supplied text |
| Wipe a portal | Controller near the plane, grip + swipe → stencil opening into 3D | Geometry is authored; no automatic doorway or mirror segmentation |
| Screen to AR | A computer/phone changes XYZ, color and rotation → same object changes in Unity over the LAN | Real state synchronization, manually aligned device origins |
| Avatar | Action → articulated character gesture; Reset → neutral | Bundled skinned glTF character and supplied animation, not reconstructed or inferred body motion |

All six share a scene origin, controller menu, input state, reset, relay and replay path. The **Paper** adapter uses the existing OpenCV marker engine, but **live paper camera access is blocked on the tested device**; see [the exact gate](VERIFICATION.md). When camera access is available, it places components only on fresh measured targets; **Manual** is explicit controller placement, not image tracking. A camera is requested only when Paper mode is selected. Stale marker input freezes interaction, briefly holds presentation and then hides content. Recentring invalidates old observations.

## Install the prebuilt APK

Use the APK and SHA-256 from the linked project release / verification receipt. The dedicated package is `edu.colorado.mrclasslab`; it does not overwrite Interactive Paper Lab or Spatial Capture.

```sh
adb devices -l
adb -s YOUR_QUEST_SERIAL install -r mr-class-lab.apk
```

Open **MR Class Lab** in Unknown Sources. Finish ordinary Quest room/boundary setup. Do not uninstall an existing app to bypass a signing mismatch.

**Controls:** A = action / next step; B = reset action; X/Y = previous/next component; left Menu = show/hide menu. Right-controller ray + trigger selects menu buttons. Hold left grip to move the manually placed origin. For the portal, hold right grip and move the right controller across its opening. Paper mode requires the [calibrated dots-8 print kit](../lecture-hub/print-kit/), measured at **120 mm between opposite dot-corner centers**. Hand tracking is not an implemented input adapter in this version.

The app's local mechanisms work without a computer, API key or USB cable. The optional cross-device relay needs ordinary Wi-Fi, **not `adb reverse`**.

## Open and change the Unity source

```sh
git clone https://github.com/ryosuzuki/image-tracking.git
cd image-tracking
python3 tools/mr-class-lab/prepare.py
```

Open `tools/mr-class-lab/unity` with **Unity 6000.4.5f1**. Wait for the pinned Meta / OpenXR packages to import. Select **Tools → MR Class → Create desktop preview scene**, then press Play. The desktop preview is explicitly synthetic unless a prepared recording is supplied. No paid assets are required.

Change a component in [`Studies.cs`](../../tools/mr-class-lab/unity/Assets/MRClass/Mechanisms/Studies.cs), or add an input adapter beside [`MarkerInput.cs`](../../tools/mr-class-lab/unity/Assets/MRClass/Inputs/MarkerInput.cs). Keep recognition/model outputs separate from the state and rendering. [`LabState.cs`](../../tools/mr-class-lab/unity/Assets/MRClass/Core/LabState.cs) is the shared scene contract. [`RelayInput.cs`](../../tools/mr-class-lab/unity/Assets/MRClass/Inputs/RelayInput.cs) is actual HTTP transport, not a same-browser BroadcastChannel simulation.

`prepare.py` copies **seven exact existing tracking sources** into a generated folder and records their hashes. It does not modify the original project or silently substitute another tracker. Preserve that shared-source manifest; do not edit generated copies.

## Connect a computer / phone

```sh
python3 tools/mr-class-lab/companion/server.py
# For an ordinary classroom LAN, explicitly bind your computer's LAN address:
python3 tools/mr-class-lab/companion/server.py --bind YOUR_COMPUTER_LAN_IP --lan
```

Open the printed URL, enter the printed room code, and click Connect. The page displays the exact `relay.json` for this session. Save it locally, then deploy it to this app only:

```sh
adb -s YOUR_QUEST_SERIAL push relay.json /sdcard/Android/data/edu.colorado.mrclasslab/files/relay.json
```

Quit/reopen the app normally. Use the companion controls to change components or move the model. The app reports connection/revision state. A disconnect does not move the scene origin. A restarted relay is recognized as a new session, even when its revision counter starts again at zero. No relay starts inside the headset and no private recordings are served by this companion.

Desktop Unity can use `MR_CLASS_RELAY=http://YOUR_COMPUTER_LAN_IP:8897` and `MR_CLASS_ROOM=YOUR_ROOM_CODE` before launching the editor. Room codes are session separation, not an internet deployment scheme. No public tunnel or account credential is needed.

For captions, type and Send, or explicitly Start speech input in a compatible browser. Stop terminates the microphone session; leaving the page also stops it. Browser speech can be unavailable on an HTTP LAN origin; typed captions remain functional. Supplied translation and uploaded texture are **input adapters**, not claims of live translation or image generation.

## Debug against an actual recording

Use your own or explicitly permitted normalized recording. An ordinary MP4 does not supply measured camera poses or calibration. The existing converter accepts the two established AgentHands / Spatial Capture normalized formats:

```sh
python3 tools/recorded-context-lab/prepare_lab.py \
  /absolute/private/normalized-session /absolute/private/new-prepared-capture
```

Set `MR_CLASS_CAPTURE` to the new folder **before launching Unity**, create the desktop preview scene, then Play. The same six native components now render through the recorded sensor camera. Play/pause, seek, change a component, act and reset. The world origin is a deliberately **manually authored seed** in the recorded coordinate system, not a recognized object/surface. No hand tracks, room occlusion, depth or moving-object tracking are invented.

The class deliverable is one working variation: source change + its input + visible response + reset, tested against the same recording. For example, replace the tutorial stroke data; add a book target; synchronize your own editable model; or replace `Resources/ClassAvatar.glb` with your permitted GLB character and animation from the previous avatar class. Keep the original source timestamps and label replay separately from live operation.

## Build / verify

Android Build Support with SDK, NDK and OpenJDK is required to build the APK, not to edit the desktop components. Rebuild the actual shared native engine first:

```sh
bash tools/mr-class-lab/build-native.sh
MR_CLASS_APK=/absolute/output/mr-class-lab.apk /path/to/Unity \
  -batchmode -quit -buildTarget Android \
  -projectPath tools/mr-class-lab/unity \
  -executeMethod MRClass.Editor.ClassBuild.Android \
  -logFile /absolute/output/android-build.log
```

The native build downloads checksum-pinned official OpenCV 4.12.0, then compiles the existing detector with the Unity Android NDK. No binary blob or fake marker result replaces it. The bundled [Cesium Man model](../../tools/mr-class-lab/THIRD-PARTY.md) is a properly attributed CC BY 4.0 asset, imported by pinned glTFast; it is not a private body scan. The APK build disables Meta's developer-agent bridge and clears any injected access token/address before serialization.

```sh
python3 -m unittest discover -s tools/mr-class-lab/companion -p 'test_*.py'
node tools/mr-class-lab/companion/test-ui.cjs
MR_CLASS_CAPTURES=/absolute/private/ada-prepared:/absolute/private/ryo-prepared \
MR_CLASS_VERIFY=/absolute/private/new-verification \
MR_CLASS_RENDER_VIDEO=1 /path/to/Unity -batchmode -quit \
  -projectPath tools/mr-class-lab/unity \
  -executeMethod MRClass.Editor.ClassBuild.Verify \
  -logFile /absolute/private/unity-verification.log
```

Verification uses actual native scene code. For each capture/component it checks visible output, changes state through the public input API, requires a different rendered image, resets and requires the original image again. It also tests stale input and origin invalidation. Video output is resampled at 10 fps and includes an output-frame → actual-source-frame mapping; it is not a claim of a 10 Hz sensor when the source was slower. Source injections in a verifier are not physical controller acceptance.

See [verification and implementation boundaries](VERIFICATION.md). Private source recordings, transcripts, images, room coordinates, personal avatar assets, device logs, room codes and generated videos are excluded from Git. See the owning projects for [avatar sources](https://github.com/ryosuzuki/3d-avatar), [3D generation](https://github.com/ryosuzuki/3d-generation) and [full Spatial Capture](https://github.com/ryosuzuki/quest-spatial-studio); their capabilities are not silently claimed by this app.

The short verification videos hold the measured camera view after 0.5 seconds so each input/response/reset comparison stays visible. This is labeled in the videos and source-frame CSVs; the interactive Unity player still supports the complete source timeline.

# Verification — 2026-11-12

## Observed results

- **Unity 6000.4.5f1 / Android ARM64 IL2CPP:** native APK compiled successfully. OpenXR's Meta XR feature is enabled; duplicate native loaders are excluded by the SDK's supported build processor. Final APK permission readback includes Internet, Android Camera and Headset Camera. Passthrough is declared; microphone recording is not requested.
- **Two permitted, real Quest recordings:** 75 source observations over 8.236 s and 915 over 95.111227 s. Both were imported with their measured camera pose and intrinsics into Unity coordinates. These private files are not in Git or the release.
- **12 capture/component cases:** all six components rendered through both calibrated recorded-camera views. Each case required visible geometry, a changed rendered image after programmatic input, and an identical baseline after reset. The avatar additionally required an actual skinned mesh and a change in its joint rotations from the supplied animation. The shared tracking model rejected stale observations, prior-origin observations and unreliable headset state.
- **Quest 3 installation / native execution:** install returned Success; the dedicated package ran with advancing frames and tracked-head telemetry. Actual stereo compositor screenshots showed the authored portal / skinned avatar over passthrough. This is not a measurement of registration accuracy.
- **Actual Quest Wi-Fi relay:** all six companion-selected component states and their revision numbers appeared in fresh native app telemetry. This used an ordinary private LAN endpoint; no ADB reverse mapping was created. The test's temporary relay configuration and service were removed afterward.
- **Companion:** five real-HTTP Python tests passed, including room isolation, schema rejection, origin rejection, two-client transport, valid texture round-trip, malformed PNG rejection and a 3.1 MB PNG. Eight additional actual-JavaScript / HTTP harness checks passed, including rapid actions, a pending-response/debounced-slider race, stale polling responses, disconnect and equal-revision server restart. These are not claims that every browser's microphone / download API was tested.
- **Replay videos:** two 36-second videos, 360 output frames each at 10 fps, fully decoded after encoding. Each is explicitly labeled recorded camera plus authored Unity behavior; per-study CSV files retain source-frame/time mappings. Resampling is not a claim of a higher sensor rate.
- **Device cleanup:** finite proximity sessions restored normal sensor behavior; the app was stopped, its test relay configuration removed and unrelated apps / recordings / reverse mappings preserved. No global camera/privacy setting was changed.

## Explicit remaining gate: live paper camera

On the tested headset, camera permissions were present/granted and the app had XR focus, but the OS reported the app's **Camera and MR-sensor operations as ignored**. The SDK enumerated **zero supported left-camera resolutions**; no raw sensor frames were acquired. The app now fails closed with an actionable camera-access status rather than displaying a fabricated marker pose. It does not override the device's privacy policy.

Consequently **live printed-paper detection / following and physical registration are not accepted** by this checkpoint. The native adapter and shared detector are compiled, but a build, stereo rendering, tracked-head telemetry and successful Wi-Fi transport do not establish camera access or paper alignment. Re-test camera availability under the intended device/user presence and camera/MR-sensor access policy before teaching Paper mode as a working physical demo.

Also not established: physical controller swipe / contact accuracy, cross-device shared spatial anchors, moving-object tracking, dynamic hand/depth occlusion, live translation, image generation or inferred body motion. The tutorial, target registry, supplied animation and verification inputs are authored. The captured-room replay does not silently provide those capabilities.

## Re-run

See the [main guide](README.md) for exact build / capture preparation / Unity verification commands. Companion checks:

```sh
python3 -m unittest discover -s tools/mr-class-lab/companion -p 'test_*.py'
node tools/mr-class-lab/companion/test-ui.cjs
```

The second command executes the actual companion JavaScript against real local HTTP servers inside a controlled DOM harness. It opens no account browser or microphone.

Optional video export from the exact Unity verifier output:

```sh
python3 -m pip install -r tools/mr-class-lab/requirements-tools.txt
python3 tools/mr-class-lab/render-videos.py /private/unity-verification /private/new-video-output
```

This needs ffmpeg, Pillow and a readable font; no ffmpeg `drawtext` extension is required. Private evidence is retained in the task's established Storage outputs, not uploaded to the public repository. Only code, reproducibility files, the explicitly licensed sample avatar and dependency/source hashes are published.

The short verification videos hold the measured camera view after 0.5 seconds so each input/response/reset comparison stays visible. This is labeled in the videos and source-frame CSVs; the interactive Unity player still supports the complete source timeline.

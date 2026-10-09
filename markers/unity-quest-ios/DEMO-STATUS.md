# Quest 3D demo repair — 2026-10-09

## Diagnosis

The earlier real Quest recording showed tracker/control text without acceptable 3D content, and intermittent pink geometry. Text uses a different font material. Procedural lesson meshes used a shader found only by its name; the build did not keep a serialized reference to that shader. The original custom surface shader also used the built-in pipeline while the Android build selected Universal Render Pipeline (URP).

A missing/unsupported Unity material renders magenta. This source repair addresses both shader inclusion and pipeline compatibility; only a fresh physical recording can establish the user's actual headset view is repaired.

## Changes

- A `Resources`-retained URP shader explicitly supports instancing and single-pass stereo.
- 3D materials load the retained shader and report missing/unsupported shaders explicitly.
- The camera path uses asynchronous GPU readback, not the Android-unsupported CPU-image API. Image timestamp, camera pose and invalidation generation are captured before submission. Mode changes, pause/focus and origin resets reject old callbacks.
- Pixel rows are converted to top-left RGBA before OpenCV. Physical pose/row orientation still requires acceptance.
- The eight existing procedural lesson applications remain intact; no private models or worksheets are required for the default solar demonstration.
- Headset positional-tracking and measured-observation freshness gates remain intact. No untracked visual overlay is presented as successful tracking.

## Physical acceptance protocol

Open the native **Interactive Paper Lab / PaperLab** marker app, not the Vuforia prototype or Quest Browser. On the computer display the full `dots-8.png` card. Keep the headset awake, worn and positionally tracked. Use Y to cycle the applications, A to pause, B to reset and stick click for the application's action.

A successful demo must show colored 3D spheres/cube or cube faces, movement parallax, at least one lesson action, marker loss/recovery and absence of magenta error surfaces. Record the actual compositor; keep the original private video and logs. A build or editor image alone does not satisfy this protocol.

The target's nominal corner span is 12 cm. Match the displayed/printed physical span before interpreting metric size or alignment. Reusing an ID on several worksheets is not distinct page recognition.

## Current acceptance

- Native OpenCV plugin build and Unity Android build passed; retained surface variants compiled for Vulkan and GLES3.
- Existing independent fixtures passed: 284 paper-model mathematics checks plus 42 calibration/timestamp/pose checks.
- Editor visual checks passed all eight applications and 13 lesson-state screenshots. These are authored renderer/geometry evidence, not device acceptance.
- Safe `adb install -r` verified package version 11 (`0.11-interactive-paper-gpu-surface`); existing application data and the separate Vuforia package were retained.
- Dismissing a stale Quest system controller modal allowed the marker application's real Unity/OpenXR process to start. Headset wake alone did not establish a worn, positionally tracked session.
- Camera availability is a separate gate: a previous native optical-probe application was observed holding the left headset camera while the marker Unity process started. Do not let simultaneous test applications consume that camera.
- Live paper-locked stereo acceptance and a successful demo video are **not yet established**. Neither the build nor the editor screenshots are labelled as a live tracking demo.

APK SHA-256: `66817ec3e69e49daff80eb14748bbbbee000b6fa0ac99ffb43953556b7f9c3ef`. The APK and private physical captures are not committed.

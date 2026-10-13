# Teaching capture delivery — 2026-10-12

> Superseded by the [v14 one-app lesson-menu continuation](teaching-menu-status.md). The v13 build/install evidence below remains historical.

## Delivered source and distribution

- Completion owner: this lecture/student-kit task; target `origin/main`.
- Google Slides: [Image Tracking & Interactive Paper](https://docs.google.com/presentation/d/1-Uv_qqImctIzZ2j2qQ-B5Tv8L6B-dFP48GfJeJqr548/edit), **56 slides**, **14 native YouTube video objects**, authentic research figures, creator images and source links. Copied the actual History of Mixed Reality theme into the same Mixed Reality Drive folder; originals unchanged. All 56 rendered pages inspected; reader access and parent folder read back.
- Native **Interactive Paper Lab v13 / 0.13-teaching-capture**, ARM64, minimum API32 / target API34. [APK and notices](https://github.com/ryosuzuki/image-tracking/releases/tag/teaching-capture-v13-2026-10-12).
- SHA-256: `12cbc33108f8b8f2db115c4d311b57ef0df57215f2287ee88ebbe518d9fa6de5`.
- All eight authored applications included: Solar, Geometry, FunctionGraph, InclinedPlane, Pendulum, Circuit, Vectors and Binomial.
- Explicit bounded JPG + calibration + pose capture in the native app; right stick starts/stops. Automatic room capture/upload remains off; no microphone/room/hand/depth data is claimed.
- [Student instructions](../tools/teaching-capture/README.md) and [viewer source](capture-viewer/) are authoritative. Browser synthetic sample, all eight selectable authored variants, seek/reset/play, 390px layout and zero JavaScript errors verified. Synthetic sample is not a Quest recording. Invalid tracking hides geometry.

## Verification

Full pinned Unity Android IL2CPP build succeeded using the public v12 source plus these v13 additions and official OpenCV4.12.0. Official Android archive hash verified. APK signature and package/version/API/ABI checked. Actual serialized developer-agent settings independently read: disabled, address empty, access token empty.

The connected Quest 3 accepted `adb install -r`; package metadata freshly reported code13 / 0.13-teaching-capture. Existing app data, separate apps and continuous awake configuration were preserved. No uninstall/reset occurred.

Four projection/handedness/reliability tests, six capture-file failure tests, existing 284 teaching-model mathematics checks, 42 calibration/timestamp/pose checks and nine telemetry tests passed. These software controls are not physical evidence. The public-tree validator was corrected to recognize the already-public JPG preview format and the full staged tree passed; unrelated four thin-line-ID files remain untouched.

## Actual physical blocker

The headset's normal OS dialog reported **Finding position in room**. Selecting its visible Continue without tracking option cleared that dialog for diagnosis but did not initialize 6DoF. The OS then refused to start the MR app because it requires 6DoF movement. No new marker camera ingestion, saved image take, printed/moving-paper detection, binocular registration, physical controls or replay of a newly recorded take is claimed. Native capture has compiled source and software checks, **not successful device capture acceptance**.

Existing continuous-operation proximity CLOSE, plugged-in stayon and its recovery worker remain user-owned and unchanged. A short coordination pause marker was removed after UI input. No Guardian disable, travel-mode enable, reboot or fabricated pose was used.

Once actual positional tracking is recovered, the installed app and public print/capture kit are ready for the one-target physical acceptance procedure. A stationary remote headset cannot be reported as tracked merely because it is powered or mounted.

## Repository and artifact boundaries

Authoritative source paths: `markers/unity-quest-ios/Assets/MarkerLab/{TeachingCapture.cs,QuestMarkerTracker.cs,Editor/MarkerBuild.cs}`, `docs/capture-viewer/`, `tools/teaching-capture/`, entry links and the source hash manifest. APK is a Release asset. Build caches, private device logs, room screenshots and original takes stay outside Git. Separate Spatial Capture app/editor is linked, not overwritten. Temporary browser QA tabs are closed; the managed profile remains running. The initial v13 canonical main matched remote. During the v14 continuation the external checkout became read-only; see the v14 synchronization handoff.

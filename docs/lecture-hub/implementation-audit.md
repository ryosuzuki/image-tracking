# Image Tracking teaching hub: implementation readiness audit

Audit date: 2026-10-12. The implementation audit was read-only, with no device tests, installs, commits or pushes. Subsequent publication preparation corrected exactly two existing public-hygiene failures, as recorded below. Historical on-device evidence is explicitly identified as historical.

## Exact sources and preserved state

- Current public remote: https://github.com/ryosuzuki/image-tracking , main **d9692d6d5c0f3784686e0b3c47d23232eca3e87c** (2026-10-10 17:19:57 UTC).
- Canonical checkout is behind remote at **d06ddada82bea863a1f86ac7b2c4a11c1923ed9a**. Four untracked concurrent thin-line-ID source/test files were preserved; the current remote was audited in an isolated fresh clone.
- Canonical storage access verification passed; earlier repository-map storage blockage is historical, not current.
- Adjacent capture/editor source: public https://github.com/ryosuzuki/quest-spatial-studio , main **2a6ff54f53eee06a6751d8902a4deb9bbcd45045**. README and DEVELOPMENT fetched through authenticated GitHub API. Map explicitly says recorder modifications are currently stopped by user; integration planning is allowed, modifying that app is not inferred.

## Executive finding

This is already a substantial source/experiment hub, not a blank project. Eight independent tracking lanes exist, plus browser paper-ID and content prototypes. A native marker APK and separate Vuforia APK have historical build/install receipts. **No reliable, moving-head, printed-paper, paper-locked binocular Quest demonstration is accepted.** No all-in-one class-distributable tracking APK, synchronized capture-to-editor integration, or complete printable lesson package is presently established.

Repository root README/PROGRESS/QUICKSTART contain stale statements: APK10 repair unsynchronized and Vuforia launch blocked. Current per-lane documentation supersedes those checkpoints: marker GPU+URP repair and native black-dot repair are now in source, APK11 installation is recorded, and Vuforia initialization plus calibrated camera startup were observed. Fix documentation before students follow it; do not repeat the old root claims as current truth.

## What exists, and what does not

| Lane | Implemented source/capability | Evidence/status | Gap before class demo |
|---|---|---|---|
| markers/unity-quest-ios | Native Quest OpenCV colored dots + ArUco; GPU camera readback; calibrated world-space source; URP single-pass-stereo retained shader; eight authored procedural applications | 2026-10-09 APK11 build/install receipts; 284 model-math + 42 calibration/pose/timestamp historical checks; dim-LCD classifier repaired and repacked install receipt | Fresh worn/positionally tracked session; no pink surfaces; both-eye registration, motion, interaction, loss/recovery; exact reproducible rebuild/release |
| image/quest-unity-vuforia | Isolated Unity 11.4.4 custom-driver image target, authored 20 cm target, cyan 5 cm cube; private runtime license loader; duplicate/backwards frame guard | 2026-10-09 full build/install hash receipt; actual SDK initialization and calibrated 1280×960 camera startup | No TRACKED/NORMAL target result or binocular cube accepted; pair result timestamp with its exposure; pose fusion disabled |
| image/quest-native-opencv | Native Android Camera2 ORB/RANSAC image detection, 2D homography camera panel | Separate upstream snapshot; public replacement target is not optically retested | Not binocular world-space AR; actual target and physical acceptance |
| image/quest-unity-artoolkit | Unity/Meta XR natural-image stereo source | Separate snapshot, ARToolKitX dependency instructions | Compatible native plugin missing from public source; fresh physical alignment |
| markers/web-webxr | Dot/ArUco browser camera comparison and capability-gated XR; authored cards | Historical 19 detection expectations and 13 application tests/build | HTTPS/camera permissions; real device physical robustness; Quest XR camera gate |
| image/8thwall-web | Natural-image browser lane; deterministic target compilation and authored educational models | Historical scoped tests and Vite build | Current runtime/dependency/license verification on classroom devices, optical acceptance |
| image/arkit-swift + markers/arkit-swift | iOS ARKit/image and OpenCV-marker native snapshots; larger lesson/state implementations | Historical actual iPhone IDs 7/8 detection, loss/recovery; simulator tests are separate | Device signing, assets, present-day physical test. visionOS uses simulated pose, not accepted physical tracking |
| docs/registered-paper-ar | Four black L brackets + normalized reference-image correlation; uploaded catalog and SUN/TREE/MUSIC; authentic research-paper first-page preset | Synthetic/reference-import checks and offline captured-image recognition; actual Quest Browser 152.1 immersive-ar+camera-access rejected NotSupportedError historically | Browser API presence does not prove support; constrained template matcher, not arbitrary unmarked-paper recognition; physical paper/multi-page benchmark |
| docs/paper-content-lab | Four L brackets plus local on-demand Tesseract OCR; text/arithmetic-driven simple 2D visuals | Implemented browser prototype | English printed baseline, no drawing semantics/calibrated 3D; nearest-center association can swap pages; manual Read required |
| docs/colored-dot-ten | Ten independent page IDs 7–16, min Hamming distance 3, two decoded corners/14 correspondences | Synthetic controls and historical real optical trials retained privately | 2D camera-space only, not official Realtalk, no stereo acceptance |
| docs/thin-line-id + golay-line-id | Geometry separated from ID; black/color edge-code readers, error/erasure controls, supplemental ROI reads, confidence/held distinction | Extensive historical 2026-10-10 real Quest **monitor-displayed** camera trials and separately labeled RAW replay | Printed-wall false IDs exist; conservative guard reduces recall; head-motion and printed-paper generalization unaccepted. Historical phase hashes not automatically current HEAD |

### Native marker applications

Source-authored modes are solar spheres/orbit/cube, hinged cube net, function tube, inclined plane, pendulum, circuit, vectors, probability bars. Y selects a mode, stick click triggers its action, A pauses and B resets. These are manually selected models attached to a marker, **not automatic semantic recognition of the worksheet diagram**. Default authored geometry does not require private models. Larger preserved catalogs may require authorized missing assets.

### Historical device evidence: precisely limited

- ArUco IDs 7/8: historical monocular static-headset monitor observations (41/42 each; rotated 21/21; absent 17/17). Not stereo or printed-paper proof.
- Repaired dot detector: five captured images replayed on Quest ARM64, 50/50 accepted iterations; 110/110 negative iterations rejected. Not fresh live camera reliability. Reprojection residual 0.320–0.349 px is fitting residual, not measured physical registration error.
- Installed repaired APK11 receipt SHA-256: `9b25c75f339abca933d094549e6bc3427ad56abfbc621a4a8e0abf78e28c7f84`.
- Vuforia installed build receipt SHA-256: `e03a403956d43b725ebe9ff1df8b21a9b2233f6e6efebc8988252c4067846051`. Startup succeeded historically; target status absent; Quest Finding position in room interrupted valid tracking.
- Paper-ID experiment contains optical monitor tests as well as saved-RAW replay. Typical black robust30 source checkpoint achieved 1200/1200 ID opportunities on one trial, but this is not class-ready printed-paper precision/recall. Real printed-wall take had three manually confirmed 012→004 errors; strict independent strips rejected them but reduced total outputs 76→36 on sampled replay.
- No 2026-10-12 device result is claimed by this audit.

## APK and printable availability

- `image-tracking` GitHub release list returned no releases. No APK or PDF files were found in either fresh public source or canonical checkout. Source documents say historical APKs remain outside Git. **Existing installed APK is not yet an accessible classroom download.** Retrieve authorized retained build artifact, verify signer/hash/source provenance, then prepare distribution; do not uninstall existing app to solve signer mismatch.
- Public dot/ArUco PNG/SVG cards exist in markers/web-webxr/public/markers and equivalent Unity docs/marker-lab/markers. First Unity target is dots-8.png; nominal opposite dot corner-center span 12 cm. Vuforia target is different and is 20 cm wide.
- Worksheet producer exists: markers/web-webxr/docs/printables/generate-worksheets.mjs plus verifier. It defines 17 distinct authored reference sheets (nine Web lessons, thirteen native-iOS topics with overlap). Generated worksheet PNG/SVG/index/manifest are **not present** in audited source. Run generator in disposable staging; check detector and mathematics; produce calibrated print PDF/index.
- Print producer specifies color, 100% actual size, headers/footers off, 140×140 mm outer card, 120 mm dot-center span. All generated worksheets use the same ID8: choose the matching lesson manually. They do not automatically recognize distinct pages, and Unity availability is explicitly implementation-specific.
- Browser galleries can print targets from docs/registered-paper-ar, colored-dot-ten, thin-line-id, and paper-id-samples. The latter has thirty design concepts, but most concepts are not implemented decoders; do not label every gallery item a supported marker.

## Capture/replay: reuse, do not reinvent

The existing quest-spatial-studio already has Spatial Capture (`org.openclaw.spatialcapture`) and a calibrated Three.js import/placement/replay/export editor. Its v0.1.3-test release was read-only verified to have a 77,597,177-byte spatial-capture.apk asset. Recorder README describes video, intrinsics/camera poses, hand skeletons, room geometry, head/controller poses and depth; audio synchronization still needs measurement. Existing real take is 95 s at 9.61 fps with 2,300 hand samples; 30 fps is a target, not measured performance. Editor has editable common objects across camera composite/3D room, static mesh occlusion, bounded 2D green-region tracking and recorded-depth reprojection; general dynamic-object 6DoF is not implemented. Synthetic editor demo is labeled synthetic.

Marker fork contains inherited RealityLog/SpatialCapture files, but automatic unrelated recording/room/microphone activity is disabled. Its calibration.json/frames.jsonl telemetry and a compositor screen recording are not a complete synchronized camera/hand/depth capture. Do not infer end-to-end recorder integration from inherited filenames.

Proposed boundary: tracking app → explicit take/target-observation schema → existing studio editor. Include target ID/type, measured physical dimensions, image timestamp and clock domain, camera pose/intrinsics, detector status/confidence/freshness, room-origin identity/transform, hand sample times and gaps. Render offline from those **same** observations; compare replay against one accepted live reference. Recorder modifications remain outside current authority per ownership map.

## Constraints and dependencies

- Native Quest camera requires compatible headset/runtime, permissions, awake/worn valid positional tracking, exclusive camera ownership. The known tested headset is Quest 3; do not promise all Quest models.
- Unity 6000.4.5f1 with Android IL2CPP/toolchain, SDK/NDK/JDK; MRUK/Meta XR 203 and URP 17.4 in Vuforia lane. Native/OpenCV rebuild needs pinned official dependencies.
- Vuforia proprietary 11.4.4 SDK/package and Basic development key are intentionally not redistributable in source. Quest is not an officially listed supported Vuforia device per lane documentation. Development licensing does not establish classroom redistribution entitlement; verify exact current vendor terms before distributing that lane.
- Quforia-derived code retains MIT notice, ARToolKitX primarily LGPLv3 with static-link exception, OpenCV and other dependencies retain their notices. No umbrella license grants arbitrary reuse of every lane or assets.
- Public repository excludes original textbook/source pixels, private recordings/scans, generated research meshes, credentials/signing material. Prefer authored class assets; Pokémon cards/content and publisher images require asset-use decisions, not blanket availability.
- WebXR support is separate from raw-camera support. Actual documented Quest browser immersive-ar+camera-access configuration was rejected. Recommend native Quest first, desktop/phone 2D browser as fallback, not promising Quest browser spatial AR.

## Fresh software checks (2026-10-12)

- `python3 Tools/test-dim-lcd-classifier.py`: **12 measured-color and boundary regressions passed**.
- `bash Tools/test-native-timestamps.sh`: **Vuforia native timestamp gate passed**.
- Initial `python3 tools/verify-public-tree.py` run: **FAILED** on two existing machine-specific path references in docs/paper-id-samples/build.py and research/ten-hour-paper-id/README.md. Subsequent publication preparation fixed only those two files: the producer resolves its own gallery location and requires an explicit `--output-dir`; the experiment documentation describes owner-controlled evidence without machine paths. Python syntax and producer `--help` were checked without generating artifacts. The full public-tree validator was then rerun and **PASSED** (1,909 files; 98 JSON, 57 Python and 20 shell parses; zero failures). Neither affected file had an existing digest row in public-source-hashes.json, so no unrelated manifest hashes were changed. This hygiene repair is not a tracking/device acceptance result.
- No full Unity/native build, npm install or hardware optical test was repeated during this read-only audit.

## Milestones and acceptance checklists

Use the [canonical demo roadmap](demo-roadmap.md) for milestones **M0–M6**, task ownership, dependencies and staged acceptance. This audit does not define a competing milestone sequence. The roadmap should preserve the key gates identified here: a reliable worn-headset native baseline; printed/calibrated targets and signer-safe APK distribution; separately qualified natural-image and multi-paper methods; and measured capture/replay synchronization through existing studio tooling. Recorder modifications remain outside the current authority recorded in the ownership map.

## Authoritative source links (pinned)

Base: https://github.com/ryosuzuki/image-tracking/blob/d9692d6d5c0f3784686e0b3c47d23232eca3e87c/

- markers/unity-quest-ios/DEMO-STATUS.md
- markers/unity-quest-ios/DIM-LCD-REPAIR.md
- image/quest-unity-vuforia/DEVICE-ACCEPTANCE.md
- image/quest-unity-vuforia/README.md
- docs/registered-paper-ar/README.md
- docs/paper-content-lab/README.md
- docs/colored-dot-ten/README.md
- docs/thin-line-id/README.md
- research/ten-hour-paper-id/README.md
- markers/web-webxr/docs/printables/generate-worksheets.mjs
- ASSETS.md, TRACKING-IMAGES.md, each lane SOURCE-LICENSE.md/notice.

Studio pinned README (its statement that the repository is private is stale; authenticated GitHub API confirms public visibility on 2026-10-12): https://github.com/ryosuzuki/quest-spatial-studio/blob/2a6ff54f53eee06a6751d8902a4deb9bbcd45045/README.md

# MR Image Tracking: Implementation and Teaching Demo Roadmap

Read-only audit: 2026-10-12. This is a proposed execution plan, not an assertion that an all-in-one APK or new physical demo is complete. No app, device, recorder, service, or repository was changed by this audit.

## 1. Product boundaries

Use **image-tracking** as the teaching home: https://github.com/ryosuzuki/image-tracking. Preserve the independent existing natural-image and marker experiments while adding a common lesson/demo launcher only after their interfaces are qualified. Do not introduce another repository/brand.

Use **quest-spatial-studio** as the existing calibrated recorder and desktop replay reference: https://github.com/ryosuzuki/quest-spatial-studio. The user's existing stop on capture-app modification remains in force. The present proposal is a read-only import adapter / derived observation track, not permission to modify, reinstall, restart, or extend Spatial Capture. If the eventual lesson requires new recorder behavior, keep that as a separately authorized future item; continue the lesson using exported compatible data meanwhile.

Keep **spatial** and **ambient** independent. Spatial's more recent paper recognition is valuable precedent but is not automatically part of the teaching APK. Repository similarity, a browser screenshot, or a historical worker receipt does not establish integration.

## 2. Fresh remote evidence

Remote reads used authenticated GitHub API at immutable source revisions:

- image-tracking main: `d9692d6d5c0f3784686e0b3c47d23232eca3e87c`, dated 2026-10-10.
- quest-spatial-studio main: `2a6ff54f53eee06a6751d8902a4deb9bbcd45045`, dated 2026-10-10; commit adds upright capture output and metadata-aware replay import.
- GitHub API reports quest-spatial-studio **public** today; README still says private. Treat that sentence as stale, not as a reason to expose recordings.

### Teaching implementation

Existing published Unity marker source includes GPU camera readback with pre-request timestamp/camera-pose snapshots, invalidation on mode/origin/focus changes, a resource-retained URP single-pass-stereo shader, and eight procedural lesson applications (solar system, cube net, function, inclined plane, pendulum, circuit, vectors, probability). This gives a substantial reusable renderer baseline without private educational models.

Root PROGRESS/quick-start retain older APK10 wording; more specific DEMO-STATUS documents APK11 camera/render repair, and DIM-LCD-REPAIR documents a later native-library-only correction. Their latest explicit boundary still states **live repaired-core reliability, paper-locked binocular 3D, interaction, loss/recovery, and successful demo video are unverified**. Before any build/deployment, reconcile installed APK/source/native-library revision and signer, rather than rebuilding an assumed synchronized snapshot.

Historical ArUco evidence is monocular Camera2 detection: ID7 41/42, ID8 41/42, rotated ID8 21/21, absent target 17/17. These are monitor-target/static-headset observations, not printed-paper, motion, stereo registration, or touch acceptance. The dim-LCD repair accepted five retained physical-camera images in 50/50 repeated file-replay runs and rejected 110 negative iterations. These are useful regressions, not 50 independent live trials or physical accuracy measurement.

Natural-image Android lane is ORB/RANSAC with a camera-feed homography panel, **not binocular world-space AR**. Vuforia is a separate built/installed prototype with later runtime initialization and camera-startup evidence, but target tracking and alignment unverified; ARToolKitX is another independent source snapshot. Do not start by folding all proprietary and open-source engines into one APK.

### Recorder/replay implementation

Existing accepted take `20261002_215403`: 915 decoded 1280×1280 RGB frames in 95.18 s, measured 9.6098 fps; 1,403 queued inputs dropped. It has 2,300 hand-log rows (left tracked 2,001, right 2,170), 2,160 head-pose rows, two exported rooms, and 95.84 s mono audio. Counts do not prove unique/fresh hand observations. Recorded depth has been used for coarse reprojected occlusion; the skill handoff reports approximately 5 Hz. Audio onset offset is estimated, not clap-measured.

The source includes functioning Three.js dual-view editing, exact source frame seeking, placement save/load, scene overview, static mesh occlusion and a constrained green-region example. It does **not** provide general moving-object 6DoF tracks, verified headset WebXR, measured physical registration, or accurate dynamic-hand occlusion. A 30 fps export cannot turn a ~9.6 Hz capture into 30 Hz observations.

## 3. Minimal capture and replay contract

The current `import_video.py` emits version-1 `session.json` with:

- `coordinateSystem: three-rh-y-up-meters-camera-minus-z`, `imageOrigin: top-left`, source row order, `synthetic`, calibration status and quality report.
- Calibrated/crop-adjusted `intrinsics {fx,fy,cx,cy,width,height}`.
- Per-frame `t`, original `timestampUs` as a string, `image`, metric `position`, quaternion in `xyzw` order.
- Optional references to room geometry, hands, capture schema and skeleton definitions; optional complete audio with estimated start-relative-to-video offset.

It requires a finalized MP4 and status, accepted camera metadata rows, one-to-one packet PTS / camera timestamp matching, monotonic packet times, full decoded-frame count match and at most **1 ms** container-vs-packet timestamp drift. Invalid pose flags are rejected; abnormal motion still needs derived quality screening because a historic final pose collapse had a nominally valid SDK flag.

Unity-to-Three conversion is explicit: position `[x,y,-z]`, quaternion `[-qx,-qy,qz,qw]`; meshes must also respect handedness/winding. Intrinsics account for centered sensor crop, not naïve resolution scaling; encoded row-order metadata overrides must not conflict. MRUK203 room JSON uses OpenXR convention, while camera CSV uses Unity: raw values are not interchangeable. Camera2 data requires a separate clock/extrinsics adapter rather than masquerading as MRUK input.

For the course, use tiers:

1. **RGB-only**: 2D detection/homography/compositing; no metric-world claim.
2. **Calibrated RGB + exposure-time sensor pose**: metric recorded-camera replay.
3. **Optional room/depth**: static placement/coarse occlusion when registered and valid.
4. **Optional valid hand/event logs**: deterministic recorded interaction; label recorded vs scripted vs genuinely live action.

Missing depth/hands must not prevent tiers 1–2. Depth is not currently automatically included by the strict video importer; the demonstration has a separate recorded-depth path. No claim that today's teaching APK records all modalities.

### Proposed derived target observation schema

Store a separate `targets.jsonl` keyed by source `timestampUs`/frame ID with method, target ID, observed pixel corners, confidence/quality, known physical size, pose **in a named frame**, tracking-valid state, and reason for missing/rejected observations. Derive `T_origin_target(t) = T_origin_camera(t) × T_camera_target(t)` only after camera/target convention calibration. Record per-target motion, not just headset motion. Shared marker ID cannot distinguish different worksheets; give distinct cards distinct IDs and content mappings. Preserve original capture files; derived observations and annotations live separately.

## 4. Teaching demos in one launcher

Prefer a staged Unity Quest app with a common frame-source / observation / renderer contract and mode picker, not simultaneous competing camera applications.

| Mode | Student sees | Initial dependency | Status/priority |
|---|---|---|---|
| ArUco | Printed marker becomes an adjustable cube or molecular ball-and-stick model | Fixed dictionary/ID/physical size, calibrated camera pose | First vertical slice: simple measurable geometry and reproducible identity |
| Colored dots | Same content using dots; compare color/light/occlusion behavior | Existing classifier + known corner span | Second: reuse source and meaningful regressions |
| Natural image | Authored card/image supports same anchored content | ORB/homography baseline; pose/PnP qualification for 3D | Third; existing 2D baseline is not already world-locked |
| Paper animation | Card opens into cube net, moving bird, or short page-anchored animation | Stable pose, deterministic animation time | Reuse cube-net renderer first; bird is new authored/licensed asset |
| Cards/molecule | Distinct cards select models; compare two tracked targets | Identity, multi-target ownership, metric scale | Use authored cards; Pokémon-like card mechanic, not redistributed Pokémon artwork |
| Paper-to-code | A target ID selects a tiny executable behavior students edit | Mode-safe script/content adapter, reset/seek behavior | Advanced exercise, not first-day blocker |

Molecule can use procedural atoms/bonds, avoiding commercial model dependency. Illustrate feature-poor/symmetric images and marker failure intentionally. Keep confidence, tracking lost and reacquisition understandable; do not suppress validity gates to make the scene appear stable.

## 5. Printable kit

Deliver A4 and US Letter PDFs at **100% / actual size** with a printed ruler, orientation notch, unique IDs, stated dictionary, measured marker corner span, and a manifest mapping each sheet to app mode/content. Existing dots nominal corner span is **12 cm**; existing Vuforia natural-image target is **20 cm wide** and is not dots-8.

Kit v1: ArUco7/8, dots7/8, one authored asymmetric natural image, one negative/feature-poor sheet, one two-target worksheet, and a small teacher checklist. Keep baseline algorithm comparison cards at equal controlled physical footprint where feasible. Avoid glossy lamination in baseline tests; document printer scaling, paper, lighting and measurement. A successful historical ten-sheet print job is not acceptance of this new kit. Printing is a separate physical action, not performed in this read-only plan.

## 6. Milestones and done gates

| Milestone | Dependencies / work | Done gate |
|---|---|---|
| M0: reconcile baseline | Source-vs-installed APK/native plugin/signature; identify owning device window, Quest model/runtime, camera/tracking gate | Immutable source/build manifest; existing apps/data preserved; failure states explicit. No destructive reinstall. |
| M1: first vertical slice | One printed ArUco8 at measured size; cube/molecule; camera exposure pose; URP stereo shader | Fresh physical video + synchronous telemetry show recognizable, paper-locked 3D under translation and rotation; loss/recovery; no magenta materials. Build-only does not pass. |
| M2: printable controlled comparison | Qualified ArUco baseline, dots, three lighting conditions and two sizes/distances | Trial table contains detection/ID failures and reacquisition, held-out physical correspondences for metric accuracy; print dimensions verified. Synthetic result reported separately. |
| M3: lesson catalog | Shared renderer/input; one card per content; deterministic reset | Four compelling demos (molecule, card, cube-net/animation, two-target composition) usable without private assets; each mode has accepted device evidence and lesson instructions. |
| M4: desktop replay adapter | Existing calibrated export; no recorder edits; derived target-motion observations | Same selected frame/pose/target appears in composite and free 3D view; source-preserving import, seek/reset/save, dropped observations and coordinate transforms validated. |
| M5: student prototype handoff | M4; small clean de-identified/consented or synthetic dataset | Fresh unpack/run on a second environment; Three.js example changes a real 3D object. Unity importer is a separate proposed deliverable until compiled and played. No headset required for replay exercise. |
| M6: class-ready APK and kit | M1–M5 (natural-image 3D can remain advanced); reproducible build/signing | Release APK hash, supported Quest/runtime, install/update/no-data-loss check, permission flow, offline/default assets, troubleshooting, printable PDFs, source/sample hashes and teacher run-through. |

This is dependency order, not an invented calendar. Run source/replay and lesson-asset work in parallel with the physical tracking lane; physical registration is the critical-path risk. Do not postpone that gate until all demo assets are polished.

## 7. Acceptance protocol and known blockers

Software checks: marker parser negative cases; independent pose/projection fixtures including off-center principal point and orientation; exposure/callback timing generation; seek/reset; missing-data handling; minimal clean-build verification. Existing fixtures are useful but do not certify physical alignment.

Physical checks: one operator/Quest window, fresh app/session telemetry, valid positional tracking and advancing camera counters; print at measured size; head translation as well as rotation; look-away/return; marker movement separately from headset motion; partial occlusion; target absent; reacquisition; two distinct IDs; scene action; original logs and first/middle/last video inspection plus full decode. Measure reprojection only against independent observed correspondences, not fitted residuals or assumed desk height. Set course-specific tolerance after the pilot and before the comparison—not retrospectively to pass results.

Latest memory records user-owned continuous Quest set-down power settings and recovery worker. Preserve them. Awake/mounted state is not 6DoF acceptance. A later 2026-10-11 Spatial telemetry sample reported fresh tracked head/camera and 1–3 papers, but **that is another app/session** and not acceptance of image-tracking or today's device readiness. Do not interfere with active Spatial work or camera ownership.

Remaining unknowns: current installed teaching APK/source parity; fresh device/runtime readiness; exact camera calibration and sensor-to-origin alignment in marker Unity path; printed-paper motion reliability; natural-image metric pose; multi-target stereo quality; accepted per-eye physical tolerance; eligible APK signing/update route; quality/freshness of a chosen hands/depth capture; student Unity round-trip. Audio is optional for this class and should not delay core tracking.

## 8. Suggested delegated work packages

- Tracking engineer: M0/M1, frame/pose contracts and physical acceptance; owns device only during an agreed window.
- Demo/kit engineer: procedural molecule/card/animation and printable manifest; no device mutation needed until baseline passes.
- Replay engineer: read-only normalized import and derived target tracks; never modify/restart stopped recorder scope.
- Parent/teaching owner: curated lecture examples, mode-to-concept mapping, source reconciliation, review and release acceptance.

First concrete target: **one measured printed ArUco card → native binocular cube/molecule → loss/recovery → replayable same-interval desktop sample**. Capture integration is optional until existing exported files prove the adapter; screenshot-only content or a synthetic 3D scene is not a substitute for the physical slice.

## 9. Classroom sequence

1. Lecture: historical desk/paper interfaces → fiducials → natural features → contemporary paper/object augmentation. Use authentic images/videos and distinguish recognition, pose, world registration and interaction.
2. Teacher demonstration: run the single accepted native ArUco/3D slice; move head and card, deliberately lose/reacquire, explain confidence and scale. Do not begin with every experimental engine.
3. Controlled comparison: students try authored ArUco, dots and natural-image cards under matched size/lighting, record failures and see why visual richness and symmetry matter.
4. Prototype exercise: import the same supplied recorded context in a desktop Three.js starter, swap cube for molecule/animation, edit scale and action, seek/reset and compare the effect. Students without a headset can participate.
5. Extension: two-card behavior or paper animation; Unity replay only after its independent importer/playback gate passes. Label authored/scripted behavior and recorded inputs explicitly.
6. Submission: source, short replay/export, target manifest, tested conditions and one honest limitation; live-native optional extension must include separate physical evidence.

## Source links

- [Image tracking README at audited revision](https://github.com/ryosuzuki/image-tracking/blob/d9692d6d5c0f3784686e0b3c47d23232eca3e87c/README.md)
- [Device/demo status](https://github.com/ryosuzuki/image-tracking/blob/d9692d6d5c0f3784686e0b3c47d23232eca3e87c/markers/unity-quest-ios/DEMO-STATUS.md)
- [Dim-LCD repair and recorded-input limits](https://github.com/ryosuzuki/image-tracking/blob/d9692d6d5c0f3784686e0b3c47d23232eca3e87c/markers/unity-quest-ios/DIM-LCD-REPAIR.md)
- [Progress and independent engines](https://github.com/ryosuzuki/image-tracking/blob/d9692d6d5c0f3784686e0b3c47d23232eca3e87c/PROGRESS.md)
- [Public target assets](https://github.com/ryosuzuki/image-tracking/blob/d9692d6d5c0f3784686e0b3c47d23232eca3e87c/TRACKING-IMAGES.md)
- [Recorder README](https://github.com/ryosuzuki/quest-spatial-studio/blob/2a6ff54f53eee06a6751d8902a4deb9bbcd45045/README.md)
- [Development/APK guide](https://github.com/ryosuzuki/quest-spatial-studio/blob/2a6ff54f53eee06a6751d8902a4deb9bbcd45045/docs/DEVELOPMENT.md)
- [Real-take status](https://github.com/ryosuzuki/quest-spatial-studio/blob/2a6ff54f53eee06a6751d8902a4deb9bbcd45045/docs/STATUS.md)
- [Strict MP4/frame importer](https://github.com/ryosuzuki/quest-spatial-studio/blob/2a6ff54f53eee06a6751d8902a4deb9bbcd45045/editor/scripts/import_video.py)
- [Crop/intrinsics and Unity→Three conversion](https://github.com/ryosuzuki/quest-spatial-studio/blob/2a6ff54f53eee06a6751d8902a4deb9bbcd45045/editor/scripts/import_mruk.py)
- [Calibrated projection and zero-order frame hold](https://github.com/ryosuzuki/quest-spatial-studio/blob/2a6ff54f53eee06a6751d8902a4deb9bbcd45045/editor/src/math.mjs)


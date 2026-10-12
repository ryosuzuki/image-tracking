# Native teaching baseline v12: implementation and verification

Date: 2026-10-12. Integration/publication owner: teaching-hub task. Base source commit: `7213fc7db220d3e1b825b3840ffa0acdb4486bec`. The allowlisted teaching source is integrated in this repository; generated scenes/settings, dependency binaries and private build/device logs are excluded.

## Outcome

A complete **Interactive Paper Lab 0.12-teaching-baseline / versionCode12** Android ARM64 test APK was built with pinned Unity 6000.4.5f1 and official OpenCV4.12.0. It is an actual compiled native marker/solar baseline, not an editor screenshot or synthetic animation. It has **not** been newly installed/launched or accepted as live paper-locked binocular AR.

APK size: **87,443,652 bytes**. SHA-256: `e678e415ede51d8a39ba2a2b3ce5e944dbd6bb049328c89fe02bece840464d9a`.

Package: `org.openclaw.markertrackinglab`; minimum Android API32; target API34; ARM64. Debug certificate SHA-256: `190141514c5bd7509c60bb9d072135733d1830b44e01f0efbb8adbb8a045b7ea`.

## Exact implementation slice

- Versioned reproducible build output, optional explicit MARKER_APK destination.
- Application/parameter/simulation-time and current HMD/position-tracking/camera/visibility flags added to app-local numeric frame telemetry.
- Automatic raw room-camera frame dumps disabled; no recorder modifications or extra catalog.
- Teaching-specific post-SDK build privacy guard disables generated editor-agent settings and empties authentication/address before serialization. This fixed a discovered SDK hook that otherwise injects editor-agent access into the player even when its generated asset is Git-ignored.
- Fail-closed numeric take analyzer and nine tests, including missing/string/bool/nonintegral fields followed by valid rows, stale capture times, invalid pose and unreliable interaction. Normal id=-1 negative observations are retained, not treated as incorrect detection.
- Reproducible native test/handoff guide with explicitly pending physical acceptance.

Tracker thresholds, pose conventions, unreliable-session/freshness/origin-reset gates and existing eight authored applications remain unchanged. No Vuforia code merged.

## Verified versus pending

| Gate | Result |
|---|---|
| Native OpenCV ARM64 detector rebuild | Passed; official cached archive SHA verified |
| Full Unity Android IL2CPP build | Passed; exit0 and final APK present |
| APK signing/metadata | Signature verifies; exact package/version/API/ABI checked |
| Native input-to-package provenance | OpenCV bytes identical; marker core and C++ runtime exactly match llvm-strip --strip-unneeded outputs |
| APK developer-agent privacy | Actual serialized APK settings independently parsed: disabled, address empty, token empty |
| Vuforia proprietary assets | None present in APK |
| Mathematics checks | 284 passed |
| Calibration/timestamp/pose checks | 42 passed, numeric source fixtures only |
| Measured-color classifier checks | 12 passed |
| Telemetry analyzer tests | 9 passed, fabricated software controls only |
| Device install/launch | Not attempted |
| Fresh teaching camera / detector / world pose | Unverified |
| Printed/moving paper and binocular scene | Unverified |

## Device-operation boundary

Fresh read-only diagnostics found another distinct paper-AR app in a live XR session holding **both** passthrough cameras. It was not stopped, replaced or interrupted. Continuous set-down power/proximity settings and the recovery worker were preserved. Power readiness is not new teaching-app acceptance.

The current device retains a legacy marker-package/signature/version record, but no readable installed APK is returned by pm path and the recorded base.apk path no longer exists. A remembered PackageManager version is not installation proof. The new signer matches an earlier retained marker release, but exact current-device signer parity cannot be established from that artifact alone; no reinstall/uninstall was performed. A coordinated handoff and signer-safe installation remain necessary.

## Distribution scope

The test APK requires no Vuforia license. Its authored default geometry and public marker artwork do not depend on private worksheet scans or room captures. Companion notices retain upstream MIT, Apache OpenCV, and applicable Meta SDK/MRUK terms; Unity runtime terms remain applicable. This is a development/classroom-test artifact, not a store release or universal Quest-device compatibility guarantee. Inherited microphone/scene permissions do not imply recording starts in the marker scene.

## First physical acceptance when device window is established

1. Resolve actual package/signer state without deleting data; use only safe adb install-r within the authorized device window.
2. Present dots-8 with measured120mm opposite-corner span; printed-paper evaluation must actually use printed paper.
3. Require current camera ingestion, increasing capture time, expected ID under fresh valid pose and valid headset tracking.
4. Inspect both eyes, metric scale, target-relative placement and moving-head parallax. Do not use reprojection residual as physical registration accuracy.
5. Test one solar action, cube/pendulum selection, marker loss/recovery, pause/resume and origin reset; stale/invalid observations must freeze interaction/hide appropriately.
6. Retain actual compositor evidence and the same take's calibration/frame telemetry privately. The numeric analyzer cannot certify correct IDs, physical input, stereo rendering or alignment.

Test APK and notices are published as release assets. Source changes and public checks are retained in this repository. Private build logs and device observations remain outside this public source.

[Download test APK and notices](https://github.com/ryosuzuki/image-tracking/releases/tag/teaching-baseline-v12-2026-10-12) · [Safe installation / build instructions](https://github.com/ryosuzuki/image-tracking/blob/main/markers/unity-quest-ios/TEACHING-BASELINE.md) · [Print kit](print-kit/)

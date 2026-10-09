# Verification — 2026-10-09

- Seven independent implementation snapshots copied from exact upstream commits; private original-byte/hash manifests retained outside this public repository. Existing repositories and dirty concurrent marker work were not changed.
- Public-tree gate checks staged file paths, credential/home/network/device patterns, prohibited media/binaries, JSON/Python/shell syntax and independent project build configurations. Exact public file digests are in `public-source-hashes.json`.
- `markers/web-webxr`:19 synthetic detection expectations plus bounded tracking state and calibrated projection checks passed;13 application tests passed; Vite production build passed.
- `image/8thwall-web`:color centroid/component/contour checks, safe Math/summation checks and pendulum/lens/projectile/circuit checks passed. Original deterministic target compilation and Vite production build passed. Public model dependency is fetched from pinned official source, not copied private media.
- Large educational catalogs/native dependencies require separately authorized assets or public SDK rebuilds; see ASSETS.md. Native physical tests, headset stereo tracking, signing/deployment and full catalog rebuild were not repeated. Vuforia account/SDK/native-driver/Unity-compile gates have now been checked; physical Vuforia acceptance remains pending (see PROGRESS.md).
- Public release intentionally removes original textbook/source figure pixels, private scans/recordings, captured telemetry/history, signing material/identifiers, local private filesystem/network details and private ancestor history. Generated authored dot/ArUco fixtures remain. New repository has fresh history.

Run the public gate from a staged or fetched checkout:

```sh
python3 tools/verify-public-tree.py
```

## Vuforia prototype checkpoint

- Official Android SDK 11.4.4 ZIP integrity/publisher SHA-256 matched; proprietary SDK assets stay outside Git. Free Basic license activated and stored privately in 1Password.
- Custom Android arm64 driver built with official headers; Unity script/scene preparation and Android APK builds passed. APK contains Vuforia, custom driver and C++ shared runtime.
- Separate app installed/updated using `adb install -r`; private license provision and retained file presence verified. Existing marker app data preserved.
- Physical app startup is blocked by the Quest system controller-required launch dialog while the headset is asleep. No Vuforia initialization, camera ingestion, target detection, or binocular visual success is asserted.
- Generated developer-agent settings are disabled in the build and excluded from public source. Public gate now also rejects non-empty serialized access/license fields.

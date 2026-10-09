# Assets and dependencies

Public source intentionally excludes private recordings, room scans, personal photos, textbook/reference pages, generated research meshes, signing assets, historical telemetry and binary model weights. Public colored-dot/ArUco cards and synthetic fixtures remain included. `assets-required.json` is a path-only inventory of excluded assets, not a download entitlement.

## Bring your own authorized assets

Obtain assets you are authorized to use, preserving the original relative layout. Then run:

```sh
python3 tools/import-assets.py --folder image/arkit-swift --source /path/to/your/asset-tree
```

This copies only inventory-listed asset paths, not credentials, logs or arbitrary files. It refuses symlinks. Private upstream owners can prepare their authorized asset tree from the exact upstream commit listed in each folder README; private verification manifests are intentionally not published. Unavailable assets remain explicitly missing, not replaced with invented scientific models. The consolidated marker implementations use authored markers/procedural scenes; the large illustration catalogs are optional source-preserved experiments.

## Reproducible public dependencies

- Web: `npm ci`, then 8th Wall `npm run target` creates original deterministic test artwork and compiles it using official CLI. `prepare-engine.mjs` obtains pinned engine files.
- Swift marker lab: `experiments/markerbench-ios/fetch-opencv.sh` downloads official pinned OpenCV4.12 iOS framework.
- Unity marker lab: `Tools/fetch-marker-opencv.sh`, native build scripts and `Tools/sync-marker-ios.sh` rebuild OpenCV bridge.
- Unity ARToolKitX: acquire the compatible ARToolKitX1.1.22 Android arm64 plugin from official source/build under its license and place `libARX.so` at `Assets/DedicatedTracker/Plugins/Android/arm64-v8a/`; preserve notices. This plugin is not redistributed here.
- Android native: `scripts/build.sh` obtains checksum-verified OpenCV4.12 AAR. Provide SDK/JDK and a locally generated Android debug keystore.

No full catalog build is promised without its authorized assets. Physical tracking needs actual device/marker tests; software checks are not optical accuracy evidence.

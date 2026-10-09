# Colored dots + ArUco + image baseline — Swift iPhone

## この実装

- Target form: **Colored dots + ArUco + image baseline**
- Engine: **Custom dots / OpenCV / ARKit**
- Platform: **Swift iPhone**
- Upstream source: https://github.com/ryosuzuki/apple-paper-lab at `a5e3dda0c7125f3fc392fed8ee441316f5d7e398`
- This is a separate source snapshot, not a submodule. Existing upstream repositories were not modified. Public release edits remove private environment/evidence and non-redistributable assets.

## 実行

このフォルダ内で実行します。必要な非公開アセットはrootの[assets手順](../../ASSETS.md)を参照。

```sh
experiments/markerbench-ios/fetch-opencv.sh
xcodebuild -project ios/PaperLab.xcodeproj -scheme PaperLab -sdk iphoneos -destination generic/platform=iOS CODE_SIGNING_ALLOWED=NO build
```

Node projects use their pinned package-lock. Unity projects require Unity6000.4.5f1 and corresponding Android/iOS modules. Swift requires full Xcode and matching SDK. iOS physical builds require your own authorized signing configuration. Quest requires camera/headset-camera permission, valid positional tracking and supported camera hardware/runtime. No signing credentials or Vuforia licenses are included.

## 対応範囲 / acceptance

Launch with --marker-bench, optionally --marker-aruco. Exact ARFrame intrinsics/pose used. Native detector fixtures differ from live optical qualification.

This consolidation validates copied source inventory, privacy gates and scoped software checks. It does not rerun physical camera, binocular, printed-paper or finger/controller acceptance. Historical upstream acceptance records are not reproduced as fresh evidence. The preserved app catalogs depend on optional private educational figures and generated models, which are deliberately not public.

## ライセンス

Original LICENSE, third-party licenses, legal notices and source headers are retained where present. If upstream has no top-level license, no new license is inferred. Dependencies retain their own terms; this repo does not relicense them.

## Public target substitution

The small base Math/trebuchet/incline/pendulum bitmaps are replaced with the included self-authored dot7 card to make basic resource loading reproducible without publishing private page pixels. This does not retain the original page appearance or establish a new physical tracking test. The separate marker lab uses the real authored dot/ArUco cards unchanged. Optional SciencePages catalog assets remain external.

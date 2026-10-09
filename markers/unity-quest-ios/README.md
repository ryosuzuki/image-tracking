# Colored dots + ArUco — Unity Quest + separate iOS project

## この実装

- Target form: **Colored dots + ArUco**
- Engine: **OpenCV / Meta XR or ARFoundation**
- Platform: **Unity Quest + separate iOS project**
- Upstream source: https://github.com/ryosuzuki/quest-dot-marker-lab at `66a0db3aec789cbc4e9abd3d25d298867677a157`
- This is a separate source snapshot, not a submodule. Existing upstream repositories were not modified. Public release edits remove private environment/evidence and non-redistributable assets.

## 実行

このフォルダ内で実行します。必要な非公開アセットはrootの[assets手順](../../ASSETS.md)を参照。

```sh
Tools/fetch-marker-opencv.sh
Tools/build-marker-native.sh
Tools/build-marker-ios-native.sh
Tools/sync-marker-ios.sh
Unity -batchmode -quit -projectPath "$PWD" -buildTarget Android -executeMethod MarkerBuild.Android
```

Node projects use their pinned package-lock. Unity projects require Unity6000.4.5f1 and corresponding Android/iOS modules. Swift requires full Xcode and matching SDK. iOS physical builds require your own authorized signing configuration. Quest requires camera/headset-camera permission, valid positional tracking and supported camera hardware/runtime. No signing credentials or Vuforia licenses are included.

## 対応範囲 / acceptance

Use root for Quest; ios-unity for iOS, not root. World-space calibrated tracker source exists; build/install does not establish physical stereo tracking.

This consolidation validates copied source inventory, privacy gates and scoped software checks. It does not rerun physical camera, binocular, printed-paper or finger/controller acceptance. Historical upstream acceptance records are not reproduced as fresh evidence. The preserved app catalogs depend on optional private educational figures and generated models, which are deliberately not public.

## ライセンス

Original LICENSE, third-party licenses, legal notices and source headers are retained where present. If upstream has no top-level license, no new license is inferred. Dependencies retain their own terms; this repo does not relicense them.

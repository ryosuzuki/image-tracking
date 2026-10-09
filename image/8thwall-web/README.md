# Natural image — Browser camera / optional WebXR

## この実装

- Target form: **Natural image**
- Engine: **8th Wall open-source**
- Platform: **Browser camera / optional WebXR**
- Upstream source: https://github.com/ryosuzuki/8thwall-image-tracking-test at `d6b7821ab76f5f4119afe648c750be36ea2492a5`
- This is a separate source snapshot, not a submodule. Existing upstream repositories were not modified. Public release edits remove private environment/evidence and non-redistributable assets.

## 実行

このフォルダ内で実行します。必要な非公開アセットはrootの[assets手順](../../ASSETS.md)を参照。

```sh
npm ci
npm run target
npm start
```

Node projects use their pinned package-lock. Unity projects require Unity6000.4.5f1 and corresponding Android/iOS modules. Swift requires full Xcode and matching SDK. iOS physical builds require your own authorized signing configuration. Quest requires camera/headset-camera permission, valid positional tracking and supported camera hardware/runtime. No signing credentials or Vuforia licenses are included.

## 対応範囲 / acceptance

Official tracker; original textbook fixtures excluded. Generated public target can exercise baseline; catalog requires authorized assets.

This consolidation validates copied source inventory, privacy gates and scoped software checks. It does not rerun physical camera, binocular, printed-paper or finger/controller acceptance. Historical upstream acceptance records are not reproduced as fresh evidence. The preserved app catalogs depend on optional private educational figures and generated models, which are deliberately not public.

## ライセンス

Original LICENSE, third-party licenses, legal notices and source headers are retained where present. If upstream has no top-level license, no new license is inferred. Dependencies retain their own terms; this repo does not relicense them.

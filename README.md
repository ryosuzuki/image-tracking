# Image Tracking — 実装を方式別に整理

既存実装を **画像の種類 × 検出エンジン × プラットフォーム** で比較・再開できる公開ソース集です。元リポジトリを削除・移動・変更せず、独立したフォルダにソースを追加コピーしました。各フォルダは別実装で、rootに一つのアプリや共通buildを作ったものではありません。

## どれを開くか

| Folder | Target form | Engine | Platform |
|---|---|---|---|
| [image/8thwall-web](image/8thwall-web/README.md) | Natural image | 8th Wall open-source | Browser camera / optional WebXR |
| [image/arkit-swift](image/arkit-swift/README.md) | Natural image | ARKit / SceneKit | Swift iPhone / iPad |
| [image/quest-native-opencv](image/quest-native-opencv/README.md) | Natural image | OpenCV ORB + RANSAC / Camera2 | Quest native Android |
| [image/quest-unity-artoolkit](image/quest-unity-artoolkit/README.md) | Natural image | ARToolKitX / Meta XR | Unity Quest |
| [markers/web-webxr](markers/web-webxr/README.md) | Colored dots + ArUco | Custom dots / OpenCV-style ArUco | Web camera / capability-gated WebXR |
| [markers/arkit-swift](markers/arkit-swift/README.md) | Colored dots + ArUco + image baseline | Custom dots / OpenCV / ARKit | Swift iPhone |
| [markers/unity-quest-ios](markers/unity-quest-ios/README.md) | Colored dots + ArUco | OpenCV / Meta XR or ARFoundation | Unity Quest + separate iOS project |
| [research/vuforia](research/vuforia/README.md) | Natural image (planned) | Vuforia | Research only, not implemented |

**Colored dots/ArUcoはマーカーの種類、8th Wall/ARKit/OpenCV/ARToolKitX/VuforiaはエンジンやSDKです。** WebXRは実行環境/APIであり、画像認識エンジンではありません。公式Realtalk実装を複製したとは主張しません。

## 最初に試す

```sh
cd markers/web-webxr
npm ci
npm run verify
npm run test:applications
npm run build
npm run dev
```

ブラウザに表示されるURLを開き、included markerカードを別画面/紙で提示してcameraを開始します。HTTPS/端末permissionが必要で、synthetic tests合格は実機tracking精度の保証ではありません。

Swift画像とSwiftマーカーは同じAppleアプリの別entrypointを独立コピーしてあります。UnityマーカーはrootがQuest、`ios-unity`がiPhone専用projectです。画像UnityとマーカーUnityは別packageです。visionOS内の仮想紙はsimulated poseであり、実カメラ画像認識ではありません。

## 公開範囲と再現

[ASSETS.md](ASSETS.md)にアセット復元・依存導入方法を記載。個人録画・部屋スキャン・私的ログ・署名情報・端末識別子・非公開の参照ページ/生成モデルは含みません。公開markerカード/fixturesとソース/build設定を保持し、private upstreamのGit履歴は継承しない新規initial commitです。公開用にpath/環境設定を一般化しています。upstream名/commitは各folder READMEにありますが、private元repoへの閲覧権限はこの公開repoでは付与されません。

検証結果は[VERIFICATION.md](VERIFICATION.md)。全ソースのコピー/公開sanitizationを検証し、Web markerのsoftware build/testを実施。実機・全catalogの再buildを今回新たに達成したとは扱いません。

関連整理repo: [3d-generation](https://github.com/ryosuzuki/3d-generation), [digital-twin](https://github.com/ryosuzuki/digital-twin), [3d-avatar](https://github.com/ryosuzuki/3d-avatar)。

## Licenses

Original per-folder license/legal notices and source headers remain authoritative. There is no blanket license that overrides third-party terms. Missing upstream top-level licenses are not invented. Dependencies and excluded assets require their own authorization/terms.

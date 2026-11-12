# Third-party assets and engines

- **Cesium Man**, © 2017 Cesium, supplied through the Khronos glTF Sample Assets collection, [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). The supplied model and animation are unmodified; Unity import, scale, placement and playback are application behavior. [Pinned source](https://github.com/KhronosGroup/glTF-Sample-Assets/tree/8f492390ddc7a2ae221a1369ef560589cf8c70fb/Models/CesiumMan). The embedded Cesium logo remains its owner's trademark; no endorsement is implied. [Model notice](third-party/cesium-man-license.md) · [trademark notice](https://github.com/KhronosGroup/glTF-Sample-Assets/blob/8f492390ddc7a2ae221a1369ef560589cf8c70fb/LICENSES/LicenseRef-LegalMark-Cesium.txt). Exact asset hashes are in `third-party/asset-manifest.json`.
- **glTFast 6.21.0**, Unity package registry. The package supplies glTF/GLB import, skinned meshes, materials and animation; its package license applies. No private body scans are distributed.
- **Meta XR Core / MR Utility Kit 203.0.0**, Unity OpenXR and XR Management: pinned in the Unity package manifest / lockfile; their original licenses apply.
- **OpenCV 4.12.0**, official Android SDK, downloaded and SHA-256 checked by `build-native.sh`. Native bridge and pose/calibration sources are reused from this repository with an exact shared-source manifest.

The teaching application does not relicense these dependencies. No full research system, private recording, photo, transcript, room scan or generated personal model is bundled.

Redistributed engine/importer license copies: [OpenCV](third-party/opencv-license.txt), [glTFast](third-party/gltfast-license.md). The release also supplies these notices alongside the APK.

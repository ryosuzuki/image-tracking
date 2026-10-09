# Tracking images

## Start with colored-dot ID8

[Open/download dots-8.png](markers/web-webxr/public/markers/dots-8.png). Display the image on a computer; view it with the Quest native app. See [Quest quick start](QUEST-QUICKSTART.md).

## Public marker cards

| Image | Type | Use |
|---|---|---|
| [dots-8.png](markers/web-webxr/public/markers/dots-8.png) | Colored dots, ID8 | First target for the installed Quest Unity test |
| [dots-7.png](markers/web-webxr/public/markers/dots-7.png) | Colored dots, ID7 | Separate marker comparison; not a claim of installed Unity acceptance |
| [aruco-7.png](markers/web-webxr/public/markers/aruco-7.png) | ArUco DICT_4X4_50, ID7 | ArUco-mode comparison; historical monocular Quest acceptance |
| [aruco-8.png](markers/web-webxr/public/markers/aruco-8.png) | ArUco DICT_4X4_50, ID8 | ArUco-mode comparison; historical monocular Quest acceptance |

Equivalent Unity cards are in [docs/marker-lab/markers](markers/unity-quest-ios/docs/marker-lab/markers). Synthetic transformed/occluded test images are in [Web fixtures](markers/web-webxr/public/fixtures); these are test inputs, not additional apps.

## Other image-tracking lanes

- [Native Quest target](image/quest-native-opencv/assets/target.png): separate OpenCV natural-image experiment.
- [8th Wall target](image/8thwall-web/public/target.png): separate browser natural-image experiment.
- [Swift resources](image/arkit-swift/ios/Resources): public replacement resources; do not assume the original private worksheet pixels are included.

## Prepared desktop folder versus GitHub

The prepared **Tracking Images** desktop folder includes markers, worksheet sheets and reference images. Not every reference or worksheet is redistributable; the public repository contains authored marker cards and authorized public resources, not the entire private desktop collection. See [asset inventory and restoration](ASSETS.md). Do not assume every image is supported by the same app.

The source, startup instructions and verification status belong here. Private recordings and non-redistributable images remain outside the public repository.

## Vuforia prototype target

The independent Vuforia prototype uses [paper-target.png](image/quest-unity-vuforia/Assets/Resources/paper-target.png), an authored asymmetric feature image, displayed or printed **20 cm wide**. It is not `dots-8.png`. Open **PaperLab Vuforia Prototype** only after the APK/device gates in [the Vuforia guide](image/quest-unity-vuforia/README.md) have been completed. Do not treat source compilation as a working Quest demo.

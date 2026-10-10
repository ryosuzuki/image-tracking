# Dim-LCD black-dot repair — 2026-10-09

## Root cause and owning source

`Native/marker_core.cpp` classified weak chroma before checking its existing near-black threshold in the Quest dim-LCD preset. Optical black-dot samples such as RGB `(32,36,42)` could become blue, and `(38,46,42)` could become green. Small color noise therefore changed exact seven-dot corner codes even when their geometric silhouettes were located correctly.

The repair evaluates the existing `max(R,G,B) < 55` black threshold first. It does not expand that threshold, change the ordinary classifier, allow fuzzy IDs, reduce the three-corner/21-observation requirement, or bypass headset tracking validity.

Run the measured-color native regression without OpenCV:

```sh
python3 Tools/test-dim-lcd-classifier.py
```

Rebuild the complete ARM64 native detector using the documented OpenCV/NDK dependency paths:

```sh
bash Tools/build-marker-native.sh
```

## Recorded-input native verification

Five retained raw Unity camera exposures of the same physical monitor target were converted losslessly from RGBA to PNG. The full native detector and existing `Native/marker_driver.cpp` ran on the actual Quest ARM64 CPU against the same inputs before and after the repair, ten iterations per image. These were replayed files, **not fresh live camera observations**.

- Original installed APK11 core: zero accepted positive images out of five.
- Repaired core: five accepted images out of five; 50 accepted iterations out of 50.
- Decoded corners: four, four, four, four, three. No inferred dot observations were substituted.
- Eleven negatives: six actual two-corner cropped exposures, three actual four-L-strip exposures, and blank/dark fixtures. All 110 iterations were rejected before and after.
- Repaired positive reprojection residuals: 0.320–0.349 pixels; native mean processing times per image: 23–27 ms. These fitted residuals are not independently measured physical registration accuracy. The driver's nominal intrinsics are not an exact new calibration acceptance.
- Twelve measured-color/boundary regressions and the complete Android ARM64 detector/driver build passed.

The raw exposures show private physical surroundings and remain private. Their small, same-view sample is not proof of robustness across motion, blur, illumination, multiple sheets, or printed paper.

## Installation and remaining live acceptance

The APK was repacked with only `lib/arm64-v8a/libmarker_core.so` changed; all other application-entry bytes were compared unchanged. Its signing certificate matched the installed APK11 signer. `adb install -r` succeeded, retained the existing capture calibration-file inventory, and the installed APK SHA-256 matched the prepared file:

`9b25c75f339abca933d094549e6bc3427ad56abfbc621a4a8e0abf78e28c7f84`

The package/version remains APK11 because this is a native-library-only repair, not a complete new Unity build. Binaries and signing credentials are not committed.

Fresh live checks earlier in this session found the target partly outside the camera field of view. Moving the same calibrated target into view restored occasional detections, but every observed session still reported unreliable spatial tracking. HorizonOS independently reported unmounted-to-sleep transition and disconnected the camera. Actual compositor recordings were black.

**Live repaired-core reliability, recognizable paper-locked binocular 3D, interaction, marker loss/recovery, and a successful demonstration video remain unverified.** Resume acceptance in a genuinely worn, positionally tracked headset session. No presence or tracking-gate override was used.

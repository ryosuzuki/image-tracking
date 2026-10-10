# Four-L markers: actual Quest optical screen recapture

An actual Quest 3 passthrough Camera2 exposure captures an animated four-L target on a physical monitor. This is **not a screenshot injected into the detector**. The raw 1280×1280 sensor images were acquired through an existing Android Camera2 capability probe (camera_source=0). Detection and grid rendering were performed **offline on the host**. This does not claim live on-headset L detection, calibrated 3D, or printed-paper performance.

## Results — 2026-10-09

189 unique sensor timestamps and JPEG frames over 32.996 seconds. The unmodified synthetic full-frame detector found four candidates in 123/189 samples. A revised full-frame candidate filter found four corners in 185/189 samples (97.88%). No hand-selected image ROI was used.

| Target motion | Detections | Samples |
|---|---:|---:|
| Stationary | 51 | 52 |
| Rotation | 44 | 46 |
| Horizontal translation | 44 | 45 |
| Displayed shear | 46 | 46 |

The camera itself remained fixed at an oblique angle. Motion and shear were displayed on the screen; this is not a physically moved paper or headset. The screen is curved and a system dialog was visible in the center. No independent corner ground truth or tracking jitter accuracy is established. Raw JPEG and status metadata were polled in separate HTTP requests, so their exact exposure pairing is not guaranteed; timestamps establish ongoing optical capture, not calibrated synchronization. The L contour reflex vertex is not necessarily its drawn centerline intersection.

## Detector changes

Retain dark-region contours, but require an approximately six-vertex L outline, contour area 150–5000 pixels, solidity 0.25–0.7, aspect ratio 0.4–2.5 and convexity-defect depth greater than 6 pixels. Reject self-intersecting contours. Require exactly four accepted candidates and sort them cyclically. These thresholds were adapted to this capture and evaluated on the **same capture**: no held-out generalization claim. No ID is decoded; rotation/identical-sheet ambiguity remains.

## Reproduce

Install the sibling `shape-corner-benchmark/requirements.txt`, then run:

```sh
python evaluate.py /path/to/private-capture
```

The capture directory must contain `capture.json` (sample, hostElapsed, wallUnix, sensor metadata) and zero-padded `0000.jpg` sensor images. It writes `detections.json` into that directory. Private home imagery is deliberately not included. `summary.json` contains aggregate results only.

Open `target.html` full-screen on a physical monitor to display four eight-second phases. A real camera must optically observe that screen. A rendered target alone is not optical evidence.

## Capture implementation note

The existing capability probe required a small bitmap fix: an int-array `Bitmap.createBitmap` returned an immutable bitmap; add `.copy(Bitmap.Config.ARGB_8888, true)` before passing it to `Canvas`. The application was updated with `adb install -r` (no data removal). A normal Android WAKEUP key event was needed after the device went to sleep. No Guardian/proximity override was used. Camera capture was stopped and the temporary presenter closed after the experiment.

The reviewed 33-second MP4 is private local evidence, not public repository media. Its 6 fps export resamples ~5.7 Hz downloaded observations; it does not establish 6 Hz live inference.

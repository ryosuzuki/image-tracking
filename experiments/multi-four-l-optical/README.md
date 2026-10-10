# Multiple four-L pages — actual Quest optical experiment

## What works

A real Quest 3 Camera2 passthrough exposure optically films a physical monitor displaying two, then four, paper-like rectangles with four black L brackets. Each separate bright paper region groups four L corners into its own planar quad. Grid overlays are computed **offline on the Mac host**, on the full optical frame. No hand-selected detector ROI, IDs, persistent identities, or live native multi-page deployment are claimed.

## Measured results (2026-10-09)

33-second capture, 186 unique JPEGs and 186 distinct polled sensor timestamps, camera_source=0 camera 50 at 1280×1280.

| Phase | Frames with exact displayed target count | Samples |
|---|---:|---:|
| Two stationary | 33 | 33 |
| Two moving / rotating | 34 | 34 |
| Four stationary | 33 | 34 |
| Four moving / rotating | 22 | 39 |
| Two approaching / overlapping | 6 | 46 |

For overlap: 29 samples yielded zero quads, 11 yielded one, and 6 yielded two. When bright page regions touch/merge, their corners cannot reliably be grouped by this implementation. It rejects ambiguous groups rather than preserving stale grids or pretending to know identity. Four-page motion also includes near-touching regions and produces losses. Phase assignment uses host elapsed time, not exposure-synchronized target telemetry, so boundary samples are uncertain. Counts measure agreement in number, not a separately labeled localization-precision benchmark. Representative overlays were visually reviewed; no independent corner error/jitter ground truth.

## Algorithm

1. Threshold grayscale below 100; extract contours.
2. Retain approximately L-shaped outlines (5–8 simplified vertices, area 20–5000 pixels, solidity 0.25–0.75, aspect ratio 0.4–2.5 and notch depth >3 pixels); reject self-intersecting contours.
3. Segment bright regions above grayscale 125, apply 5×5 morphological closing.
4. Within each bright region, require exactly four accepted corner candidates, a convex quad and sufficient area.
5. Sort the corners cyclically and compute a per-frame homography. Output ordering/colors are **not IDs**.

This requires separately visible bright pages against a darker surrounding region. It does not solve arbitrary grouping of identical marks on a continuous white tabletop or mutually occluded pages. Thresholds were adapted and evaluated on this same capture; no held-out generalization claim. The existing single-page experiment is unchanged.

## Reproduce

Install `../shape-corner-benchmark/requirements.txt`, then:

```sh
python evaluate.py /path/to/private-capture
python render.py /path/to/private-capture
```

The capture directory contains `capture.json` and zero-padded `0000.jpg` images. The evaluator writes `multi-detections.json` and `multi-summary.json`; the renderer writes the MP4 beside the capture. `target.html` displays 0–6 s two static, 6–12 s two moving, 12–18 s four static, 18–25 s four moving, and 25–33 s two approaching/overlapping. Target placement was adjusted to the actual camera field of view; this is presentation setup, not injected camera data. Open it fullscreen and acquire **real optical frames**. A screenshot of the HTML does not reproduce the hardware evidence.

Private home imagery is not included. Aggregate `summary.json` is public. A 6 fps video export resamples approximately 5.6 Hz downloaded observations and does not establish 6 Hz live inference. Raw image/status requests were separate, so exposure-level metadata pairing is not guaranteed.

## Hardware limitations and rejected attempts

An earlier take was rejected because the headset went to sleep and served cached JPEGs in later phases. The accepted final take starts immediately after normal WAKEUP/app restart and filters duplicate JPEGs; every retained image hash and polled timestamp is unique. No Guardian or proximity override was used.

The iPhone fallback did not produce optical frames: native-app UI automation initialization timed out and Continuity Camera selected 1920×1080 settings but delivered no video frames. No iPhone accuracy result is claimed. Task-owned camera/presenter processes were stopped afterward.

This is a curved-monitor recapture with a fixed headset and animated targets, not moved printed paper, calibrated 3D, world anchoring, or a paper re-identification system.

# Mobile rear-camera paper-corner test

Open the [camera page](./index.html) on an Android phone such as a Pixel in Chrome. Tap **Start rear camera** and allow camera access. Open the [target display](./targets.html) on a separate computer screen. Select four-L or colored dots, two/four sheets, and large/medium/small. Motion and fullscreen controls are available. SVG and PNG downloads can also be printed.

The camera must be served from HTTPS or localhost. No backend or image uploads are used. OpenCV.js is downloaded from `docs.opencv.org/4.x/opencv.js`; the colored-dot tracker and homography code are included locally. A network connection is needed for the initial library download. The browser requests `facingMode: environment`; the actual selected camera depends on browser/device availability.

## Detector boundaries

- Four-L v2: dark concave L candidates are grouped by their two arm directions and convex four-corner geometry, independently of white-paper regions. Extra candidates do not automatically reject a sheet. Local non-sharing groups are preferred over large cross-sheet combinations. Four visible corners are still required. Detection has no ID or persistent association. This is a JavaScript/OpenCV port of the optical experiment, not a native Quest detector.
- Colored dots: independently implemented Dynamicland-inspired seven-dot corner codes. Two-sheet targets use IDs 7 and 8; four-sheet targets use distinct IDs 7, 8, 9 and 10. Each ID has four unique corner words; all 16 words are separated by at least three color positions. Duplicate IDs remain unsupported for persistent identity.
- Green outlines show current-frame planar corner estimates. No metric 3D pose, calibrated accuracy, independent ground truth, or robustness guarantee is claimed.
- Processing downsizes input to at most 960 pixels wide and runs at approximately 8 Hz or slower on slower devices. The camera may have higher native resolution.
- Camera processing and memory are released with **Stop camera**. Reload if camera permission was denied, and allow access through browser site settings.

## Verification

Headless Chrome with the actual OpenCV.js build detects the expected count for all 12 SVG targets (2 methods × 2 counts × 3 sizes). A simulated browser media device verifies start, processing and stop. Zero page JavaScript errors were observed. This verifies browser plumbing and rendered fixtures, **not physical Pixel camera tracking**. Physical-phone testing remains the user's on-device test.

Serve locally for development: `python3 -m http.server 8000 --directory docs`, then open `http://localhost:8000/pixel-marker-test/`.

## Four distinct IDs update

Four-sheet downloads now encode IDs **7, 8, 9, 10**, not repeated 7/8. The display selector reports the active IDs. The shared `contract.json` is used by both fixtures and camera detector. Open [fixture verification](./verify-dot-ids.html) to run 18 rendered cases (2/4 sheets, three sizes, 0/±5 degrees and 0.85 scale for rotated cases) plus a blank rejection at the camera processing width of 960 pixels. These pass with exact expected IDs. This is synthetic browser validation, not new optical Pixel accuracy evidence. Reload both pages to replace previously cached targets. Duplicate IDs and persistent identity across occlusion remain outside this update.

## L detector v2 regression (2026-10-09)

The previous detector required exactly four L candidates in a white connected region. The replacement uses Otsu grayscale thresholding, concave-notch arm directions, directional neighbor searches and convex geometric grouping. It caps candidate search at 80 corners / five neighbors per arm to bound browser work. Colored-dot decoding is unchanged.

In actual OpenCV.js/Chrome, 21 generated regression scenes pass: 1/2/4 sheets under connected white background, rotation, affine skew, projective warp, an extra unrelated L plus text, mild blur, and gray background. All 12 existing SVG targets also retain their expected counts, including six colored-dot targets. These are rendered fixtures, not independent phone-camera measurements.

For a reproducible browser regression, serve this directory, open `tests/regression.html`, wait for `window.ready`, then run `window.runAll()` in the browser console. Each row reports expected count, detected count and pass/fail.

Remaining limitations: no persistent IDs, no occlusion completion, possible cross-sheet ambiguity, threshold sensitivity to uneven lighting, fixed shape/angle tolerances, and no new physical-camera accuracy measurement. Corners represent the L's inner notch, not a corrected printed-paper corner or metric 3D pose.

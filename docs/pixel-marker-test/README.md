# Mobile rear-camera paper-corner test

Open the [camera page](./index.html) on an Android phone such as a Pixel in Chrome. Tap **Start rear camera** and allow camera access. Open the [target display](./targets.html) on a separate computer screen. Select four-L or colored dots, two/four sheets, and large/medium/small. Motion and fullscreen controls are available. SVG and PNG downloads can also be printed.

The camera must be served from HTTPS or localhost. No backend or image uploads are used. OpenCV.js is downloaded from `docs.opencv.org/4.x/opencv.js`; the colored-dot tracker and homography code are included locally. A network connection is needed for the initial library download. The browser requests `facingMode: environment`; the actual selected camera depends on browser/device availability.

## Detector boundaries

- Four-L: dark concave L candidates grouped inside separate white regions; four candidates are required. Detection has no ID or persistent association. This is a JavaScript/OpenCV port of the optical experiment, not a native Quest detector.
- Colored dots: existing independently implemented Dynamicland-inspired seven-dot corner code, IDs 7 and 8. For four-sheet examples each ID is repeated. White-region splitting allows spatial copies to be counted separately; this is **not four unique persistent IDs** and overlapping/joined pages can fail.
- Green outlines show current-frame planar corner estimates. No metric 3D pose, calibrated accuracy, independent ground truth, or robustness guarantee is claimed.
- Processing downsizes input to at most 960 pixels wide and runs at approximately 8 Hz or slower on slower devices. The camera may have higher native resolution.
- Camera processing and memory are released with **Stop camera**. Reload if camera permission was denied, and allow access through browser site settings.

## Verification

Headless Chrome with the actual OpenCV.js build detects the expected count for all 12 SVG targets (2 methods × 2 counts × 3 sizes). A simulated browser media device verifies start, processing and stop. Zero page JavaScript errors were observed. This verifies browser plumbing and rendered fixtures, **not physical Pixel camera tracking**. Physical-phone testing remains the user's on-device test.

Serve locally for development: `python3 -m http.server 8000 --directory docs`, then open `http://localhost:8000/pixel-marker-test/`.

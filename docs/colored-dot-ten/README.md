# Ten colored-dot paper IDs

Independent Dynamicland-inspired colored-dot L codes, **not the official Dynamicland/Realtalk protocol**. Forty seven-dot corner words identify ten distinct paper IDs (7–16); minimum pairwise Hamming distance is three. The detector requires two independently decoded corners (14 dot correspondences) and checks geometric residuals. No OCR or page-image comparison is used.

- `index.html`: Quest Browser / Android rear-camera optical detector, 2D camera-space outlines and IDs. Not spatial WebXR AR.
- `targets.html`: one ID, automatic ten-ID sequence, or ten simultaneous targets. Screen display is not a printed-paper robustness test. `?fit=.91` constrains targets to the left 91% of the monitor, helping bring all targets inside the Quest camera view.
- `test.html`: ten individual synthetic positives, ten simultaneous, blank/random-dot/unregistered-code negatives, and two-/one-visible-corner checks. Run `runTests()` in the browser. Synthetic passes do not establish live-camera accuracy.

Camera frames stay local; camera imagery is never uploaded to this repository. Stop camera when finished. Actual optical measurements and videos are held privately outside this public source tree.

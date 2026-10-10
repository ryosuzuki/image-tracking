# Registered Paper AR browser prototype

- Camera: https://ryosuzuki.github.io/image-tracking/registered-paper-ar/
- MacBook target display: https://ryosuzuki.github.io/image-tracking/registered-paper-ar/targets.html
- Synthetic checks: https://ryosuzuki.github.io/image-tracking/registered-paper-ar/verify.html

SUN, TREE and MUSIC are digitally pre-registered. All visible L-corner sheets are rectified and matched automatically against their reference images; no OCR or colored ID dots are used. Normalized grayscale image correlation, small translation search, score threshold 0.82 and runner-up margin 0.10 reject uncertain matches. These scores are similarity values, not measured probability or physical accuracy. This is a constrained L-corner template matcher, not unrestricted natural-image ORB recognition.

Upload a paper first-page image, assign an ID and content symbol, then export the catalog JSON. Import the same JSON on the recognition device and target-display device. Download/print the generated target with its four L corners. References are session-local and not uploaded. A catalog may contain private page images: share it only with intended devices. Imported reference dimensions describe the rectangle between detected inner L corners, in metres, not the outer paper size. Default dimensions are placeholders: measure before evaluating spatial accuracy.

Pixel uses the ordinary rear camera and 2D overlay. The record button downloads ten seconds of the actual camera canvas. Quest's WebXR button requests immersive-ar with camera-access, reads actual XR camera frames and uses the XR view projection and transform for experimental multi-paper spatial placement. It does not invent intrinsics or fall back to simulated anchoring. Browser API presence does not prove the camera-access feature is supported. Real Quest capability and physical acceptance are documented separately; a blocked configuration is not a successful AR demo.

Current limitations: all four L corners, upright or modestly rotated flat pages, no severe occlusion, printed-paper benchmark not yet measured, no color-code fallback. Three-reference synthetic tests are not evidence of three physical papers working. Do not label old OCR camera videos as registered-image or WebXR demos.

## Acceptance record (2026-10-09)

Completion owner: browser registered-paper task; target: origin/main; owned paths: docs/registered-paper-ar only. Existing applications and unrelated files are preserved. Headless Chromium synthetic checks cover exact references, modest rotation, three simultaneous sheets, unknown/blank rejection and an uploaded dense text first-page fixture. A separate end-to-end check verifies uploaded reference matching, four-entry JSON export and target-page import. No physical paper accuracy percentage follows from these checks.

Actual Quest 3 Browser 152.1 reports immersive-ar support and exposes raw-camera API prototypes. Requesting immersive-ar with required local and camera-access rejects with NotSupportedError: The specified session configuration is not supported. The compositor also showed Finding position in room. Therefore WebXR paper registration and stereo/world alignment are blocked/unaccepted on that device; no WebXR recognition demo is claimed. Ordinary browser-camera videos, if delivered, are explicitly separate.

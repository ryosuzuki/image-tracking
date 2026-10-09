# Shape and four-L paper-corner experiments

## Evidence boundary

These are **synthetic computer-vision experiments**, not headset/iPhone or moving physical-paper acceptance tests. IDs and displayed lesson content are intentionally omitted. A camera availability check succeeded, but no comparison target was in its optical field. Device-specific accuracy remains unmeasured.

## Run

```sh
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
python benchmark.py --output output
python four_l.py --output output
python test_four_l.py
```

Generated media remain outside source control. Detectors do not receive ground truth. The benchmark uses a seeded noise generator, fixed thresholds, and recorded raster areas. Original development fixtures are not holdouts. This is not a detector-promotion claim.

## Four drawn L brackets

`four_l.py` detects black connected contours, locates the deepest convex-hull concavity in each bracket, orders four points geometrically, and computes an image-to-plane homography. It does **not** read a code or an ID. The video overlays a planar grid while the simulated paper rotates and undergoes perspective skew.

240/240 generated frames produce four detections. Five tests cover blank input, a hidden corner, two sheets, intact page, and 180-degree rotation. Four detected notches average 6.31 px from drawn centerline intersections: bracket thickness creates systematic offset. This is a proof of localization, not accurate physical paper-edge calibration. Exact bracket-junction fitting and independent holdout tests remain necessary.

Identical four-corner designs cannot determine semantic top direction uniquely; ordering can swap under rotation. With a non-square known sheet, dimensions may resolve a 90-degree swap, but 180-degree semantic ambiguity remains. Two identical sheets have no persistent identity; this detector rejects more than four brackets, and does not solve assignment or swap ambiguity. One hidden corner is rejected. Arbitrary dark artwork can be a false positive; clutter precision is not measured.

A homography maps a plane in an image; it is not arbitrary metric 3D. Metric planar pose additionally needs known marker geometry/size, calibrated camera intrinsics and distortion, pose estimation, and temporal/disambiguation handling. No calibrated 3D claim is made here.

## Circle / rounded square / L / line comparison

`benchmark.py` changes the colored-blob detector so circularity is not required. Four color classes specify corner correspondence; this does not read a paper ID. It uses approximately equal ink area (target 1257 pixels; actual nearest-neighbor raster areas are recorded), not equal bounding-box extent. The differently shaped marks necessarily have different extents.

60 frames per condition, four marks per frame: rotation and translation, 7/15 px Gaussian blur, 21 px horizontal motion-blur kernel, perspective, reduced scale, noise, and occlusion. Coverage means a color component was found, not that a paper ID or pose was correct. Median/p95 position errors are conditional on detections and use the transformed marker centroid. Projective area centroids need not equal transformed source centroids, so this metric includes that geometric bias.

Rotation: all four shapes 240/240 detections. Directional motion blur: circle and rounded square 240/240, L 236/240, line 214/240. L's p95 centroid error under directional blur is 7.75 px vs circle 0.21 px. See `summary.json` for every condition. These figures cannot establish real-camera reliability or a universal shape ranking. Occlusion rates include deliberately hidden marks and are not hardware failure rates. No independent temporal jitter measurement was completed.

## Next optical test

Place printed/displayed targets in the actual camera field; acquire repeated physical motions with calibrated/annotated truth, varied print quality and lighting, and background distractors. Compare camera-specific thresholds, line-junction fitting, false-positive rate, four-corner coverage, and temporal residual jitter. Do not call synthetic frames optical captures.

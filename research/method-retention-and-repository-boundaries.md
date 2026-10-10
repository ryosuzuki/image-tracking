# Tracking methods and repository boundaries

Updated 2026-10-10. This repository owns teaching image tracking and reusable marker methods. Spatial lab replay/anchor research now lives in https://github.com/ryosuzuki/spatial (private). Ambient remains a separate agent/interface project.

## Retained findings

- Separate coarse paper detection, precise ordered quadrilateral estimation, identity, and temporal/world tracking. A YOLO box is not a precise AR registration.
- Black L corners establish geometry; color or binary edge codes identify a page. Thin marks lose camera pixels, especially when ten pages share the frame.
- Binary repeated upper/lower robust30 codes were the strongest tested monitor-layout candidate; higher-capacity dictionaries and damaged/small marks produced false IDs. This is not a general printed-paper guarantee.
- Missing identity should not hide verified geometry: display the quad with unknown ID. Temporal holding is not fresh detection.
- ALIKED+LightGlue can identify rectified content without fiducials. Ten manual crops from the same recording gave nine accepted-correct and one rejection; OpenAI reference montage seven and OCR-to-Jev two. Do not present this as general accuracy or real-time video performance.
- Preserve capture timestamps and decode variable-frame-rate recordings sequentially. Random frame seeking previously mismatched labels.
- Keep measurements (corner error, recall, wrong ID, jitter, latency, held duration) separate. Stable anchors can be consistently wrong.

## Checkpoint retention

At meaningful method/marker checkpoints, commit reusable teaching code and evidence-backed findings here. Keep private recordings, scans, calibration-derived room coordinates and credentials out of public Git. No automated recurring schedule is configured by this document. Experimental lab integration belongs in spatial; superseded methods remain historical rather than being deleted.

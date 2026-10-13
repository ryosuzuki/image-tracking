# Thin top-edge line IDs
Black four L corners locate the sheet; seven thin 4-color top-edge segments encode one of 30 codes (six data symbols + checksum, codebook minimum Hamming distance 3). No interior matching. Line thickness 8/640 paper width = 1.25% (2.625mm at A4 width); segment length 40/640, gap 18/640. First 10 are test cards. Camera-space 2D only. Real-device counts recorded separately; do not infer robustness from synthetic tests.

Black L strokes use 20/640 width and 60/640 arms to improve low-resolution geometry; color ID lines remain 8/640. Per-symbol vertical sampling searches y51–75 after rectification. HSV hue classification uses minimum contrast/saturation and margin guards; checksum/exact codebook acceptance remain.
Overlay-only EMA alpha 0.4, hold cap300ms; fresh detections green, held tracks amber. Raw ID metrics are separate. Scene mean color difference >0.08 clears tracks; incompatible IDs replace overlapping old tracks; large movement resets smoothing. Camera stop/new input clears. No guarantee of spatial tracking from these 2D heuristics.

Low-resolution L grouping uses tolerant arm orientation (.65 dot product) with an explicit portrait-sheet aspect guard (.48–.92, or inverse). This is an A4-like sheet assumption, not arbitrary aspect support.
Groups are ranked by arm alignment before area, with corner-extent scale guards, so text-shaped local loops cannot steal true paper corners.

Experimental opt-in local white-reference calibration: `?whiteFallback=1`. Default OFF. Only a failed, non-conflicting primary code is independently reread using adjacent-paper channel gains. Successful primary IDs and primary observations remain unchanged. Supplemental reads are labeled Calibrated and counted as Calibrated, never held or temporal. Horizontal upper/lower strips only; sides=true disables this lane. Independent140 saved RAW holdout:1284→1287 correct /1400 opportunities, zero lost/new observed wrong;804 synthetic positive/blank/gray/corrupted/nonmember cases passed. This small offline gain is not a new optical live-camera validation.

## Conservative printed-wall black reader

`black-line-camera.html?wallStrict=1&cascade=1` is an opt-in conservative mode prompted by a real printed-wall take. Both upper/lower strips must independently decode the same ID with zero bit correction and at most two erasures each. Merged partial-only, one-strip-only and temporal reads cannot establish an ID in this mode. Geometry still displays for rejected IDs. This does not guarantee zero false IDs from correlated sampling errors.

On 139 identical 1-Hz samples of Spatial Capture take20261010_072517, it rejected all three manually confirmed paper012→004 errors (t28/39/130s); total ID outputs fell76→36. The take mixes color-coded, black-coded, unmarked and monitor pages, so these are output counts, not overall recall/precision. No change to legacy default decoding. Independent-strip tests and existing regression suites pass. Source clips remain private and are not committed.

## Optional fixed-region supplemental reading

The black reader supports `roi=1`, default OFF. After a failed primary/cascade read, it tries a fixed centered18×32 sampling region instead of18×48. Successful primary IDs, contradictory edge rejection and all already-known primary bits are preserved. A result is accepted only when it adds evidence and uniquely passes the existing decoder. It is displayed as **ROI-assisted** and counted separately as ROI, a subset of same-frame Fresh—not temporal or held recognition. `wallStrict=1` still requires independent upper/lower agreement.

On a frozen saved-RAW holdout,100 positive images improved935→984/1000 IDs (four separate clips alone:756→788/800). No new wrong or lost primary IDs were observed in200 images including blank/damage controls;1206 synthetic cases retained default/ROI parity. This is **offline replay, not a new live optical trial**; no printed-wall reliability improvement is established. The once-mass optimization computes identical immutable-crop pixel masses once and reclassifies thresholds, without pixel quantization.

The independent-strip guard is deliberately more conservative: on20 thin article RAW frames the ROI comparison is11→14/200 accepted IDs, versus174→198/200 without that guard. Do not combine those two policies' recall figures. Integrated60 RAW ×4-policy parity,43 Node regression checks and5 actual-CV/mock-lifecycle UI checks passed.

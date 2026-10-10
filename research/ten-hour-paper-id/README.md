# Ten-hour paper-ID improvement experiment

This is a measured prototype, not a claim of production reliability. Work began 2026-10-10 04:50 UTC; authorized experiment window ends 14:50 UTC. This interim record is updated as verification completes.

## Recommended configurations from completed optical tests

All results use **real Quest optical camera, monitor-displayed paper cards, normal 2D browser overlays**. No printed-paper, head-motion or WebXR AR validation. Saved sample batches include RAW pixels and overlays. Later capture code records RAW acquisition timestamps and rejects duplicate temporal updates; earlier samples do not inherit this guarantee. Continuous recordings usually use 10fps, with a 30fps trial, while detection runs at variable cadence. Saved samples and dense detector-state logs are distinct evidence. Held overlays are excluded from fresh-ID counts; same-frame supplemental reads are a subset of Fresh, not extra identities.

An independent audit verified **156 completed numbered optical phases** (001–155 and168), not156 distinct algorithm changes or ten hours of camera recording. Their selected videos total6.6817 hours and all fully strict-decode successfully.152 phases contain9085 RAW/sample records, representing9073 globally distinct PNG hashes. Interrupted156/169 and duplicate124 attempts are excluded.114 dense logs contain38378 distinct per-log timestamps;30353 expose acquisitionTime matching time×1000. This does not establish globally unique states or correctness of every unsampled frame.

| Configuration / condition | Correct ID opportunities | All ten correct sampled frames |
|---|---:|---:|
| Black 16-cell, robust30, real paper-page content | 1200/1200 | 120/120 |
| Same, brightness .65 | 598/600 | 58/60 |
| Same, monitor-target motion | 592/600 | 53/60 |
| Black 126-ID codebook, 13 cohorts covering every ID | 5169/5200 | 490/520 |
| Color balanced30, 8px lines, normal (cycle141) | 579/600 | 41/60 |
| Color balanced30, 8px lines, dim (cycle132) | 432/600 | 0/60 |
| Black 4px ×22px, guarded supplemental read (cycle168) | 594/600 | 54/60 |

These are separately recorded trials, not randomized evidence that one approach universally dominates another. Camera view, exposure and physical appearance can confound comparison. Color .65 brightness ABBA cubic sampling provided no meaningful improvement. Thinner ink often reduces reliability, even after geometric rectification. Monitor motion translates/rotates displayed targets; it is not physical handheld motion.

Counts include labeled same-frame supplemental reading: article-normal has13 supplemental reads and1 corrected read; phase168 has506 supplemental reads among594 correct reads. Historical results belong to each phase's recorded source/configuration hashes, not automatically the current repository HEAD.

Best black configuration: [camera](https://ryosuzuki.github.io/image-tracking/thin-line-id/black-line-camera.html?book=robust30&orientationRatio=.7&geometryRank=.6&lowMass=1&cascade=1), [targets](https://ryosuzuki.github.io/image-tracking/thin-line-id/black-line-targets.html?book=robust30&count=10&dual=1&fit=.84&shift=-120&margin=40). Black bars are fixed black/white cells, not image matching. robust30 has 30 weight-eight 16-bit words, minimum distance8; max one observed error and three erasures. An ID capacity is not an optical reliability guarantee.

## Improvements retained

- Detect paper geometry independently of ID; display green outline + ID unknown when code cannot be read.
- Duplicate the code on upper/lower edge, rectify only required strips for speed, and reject contradictory edge observations.
- Rank corner groups by arm alignment and sheet geometry to reduce adjacent-paper combinations; checked trials do not establish universal cross-paper rejection.
- Read color lines by saturation-weighted area votes, not one point. Restore only uniquely consistent registered codes; mark restored outputs separately.
- Stronger black codebooks and strict error/erasure limits. Supplemental low-mass rereading preserves successful primary IDs and observed known bits; label and count supplemental separately.
- Temporal evidence fusion is opt-in, geometry-associated and contradictory evidence clears it. Fresh, temporal and held remain separate. Post-first-sample swap controls observed no wrong temporal IDs, but uninterrupted atomic transitions were not tested. Audits exclude4–5 pre-first-sample configuration states per phase; no guarantee is established at the optical swap boundary.

## Failures and controls

The 126-ID weaker dictionary with deliberately damaged paper001 (two wrong known bits + three erasures) produced wrong031 in all60 samples under maxErrors1. Strict maxErrors0 rejected this particular error. This is a deliberate beyond-bound test, not normal-condition accuracy.

Golay24 capacity is2576 IDs. Only50 distinct IDs were optically exercised; ideal synthetic tests do not validate all2576 in camera. Length14, height8 uses50% more ID ink than weight-eight length14/height8 16-cell codes. Length8 failed many detections; length10 had one sampled and three dense wrong007→003 reads. It is therefore experimental, not the recommended low-visibility configuration. Optional strict thresholds and supplemental reads remain opt-in. A350 saved-RAW holdout replay of guarded supplemental reading improved length8 correct reads591→858/1000, length10 891→921/1000, and dim584→592/600 without new observed wrong IDs or rewritten known bits. The existing length10 wrong ID persists; no new live optical validation of this supplemental mode was completed.

Blank-code tests retain geometry but emit no ID; do not confuse detected paper count with decoded ID count. Zero observed wrong IDs in a finite trial is not a guarantee.

## Experimental color calibration

`whiteFallback=1` uses adjacent white-paper patches to independently reclassify color after a failed primary read; successful primary IDs and primary observations are preserved. Default OFF, horizontal upper/lower only, displayed as 色補正 and counted separately. Independent140 saved RAW holdout:1284→1287/1400correct, no lost primary or new observed wrong IDs.804 synthetic positive/blank/gray/corrupted/nonmember optical cases and1050 structural/ambiguity assertions passed. This is a small offline gain, not live deployment reliability evidence.

## Experimental black-region supplemental reading

`roi=1` is default OFF. A fixed centered18×32 region supplements a failed original18×48 read/cascade; valid primary IDs and primary-known bits are unchanged, contradictory evidence rejects, and the existing codebook/error limits remain. The UI labels **領域補助**, and ROI counts are a subset of current-frame Fresh, not temporal or held. Independent-strip printed-wall mode remains enforced.

The region was frozen on20 training images before holdout:100 positive heldout RAW images improved935→984/1000 IDs; four separate clips alone improved756→788/800.200 actual RAW including blank, deliberate damage and strict126 controls had no new observed wrong/lost-primary IDs or known-bit rewrites.1206 synthetic cases and200 RAW parser integration parity passed. This is an offline gain, **not new live optical evidence or printed-paper validation**. A saved-camera replay video compares the same20 article images174→198/200 at artificial1second/frame, explicitly labeled as replay.

Final integrated60 RAW ×4-policy parity passed. The conservative independent-strip policy on these same20 article frames yields only11→14/200 IDs with ROI, not198/200; its false-read protection has a substantial recall cost. Blank/damage controls remain unchanged.43 scoped Node regression tests,5 actual-CV/mock-lifecycle UI checks and3411 default-reader boundary/API/reentrancy comparisons passed.

An exact once-mass implementation preserves numeric pixel accumulation order and computes original immutable-crop mass only once across threshold retries.140 actual-CV RAW images matched original observations and decoded results. Desktop randomized timings were mixed and mostly lower; no Quest CPU speedup is claimed.

## Recording interruption and recovery

At approximately13:17 UTC the physical Quest USB/ADB bridge disappeared while the Mac and monitor browser remained reachable. Cycle169 includes a changed non-target scene and is excluded from algorithm comparisons and media delivery. USB later returned after a device reboot, with a Guardian tracking modal blocking browser access and no Browser DevTools socket. The experiment worker did not initiate that reboot or disable Guardian persistently. Remaining time continues offline regression/negative/holdout QA; stop/restore cleanup is scheduled for14:50 UTC and will report actual device access and restoration results.

## Reproducibility

Source: this repository, `docs/thin-line-id/` and `docs/golay-line-id/`.

Large RAW frames, continuous-state JSON, configuration receipts and source hashes: `/Users/ryosuzuki/Storage/outputs/image-tracking/ten-hour-2026-10-09/`.

Verified MP4s and flat task receipts: `/Users/ryosuzuki/.openclaw/workspace/stuff/2026/2026-10-09/` and `/Users/ryosuzuki/.openclaw/workspace/stuff/2026/2026-10-10/`.

No private camera scenes, Slack content, credentials or raw session transcripts are published in this report.

## Integration record

Terminal integration target: origin/main. Completion owner: ten_hour_id_improvement native worker (parent owns user delivery). Source default behavior preserved; calibration feature is explicit opt-in. Validated integrated source:84 scoped Node tests (32 color/49 black-Golay/3 calibration), integrated actual-CV and mock camera UI checks,140×2 saved-RAW calibration parity,350 saved-RAW Golay fallback holdout. Existing unrelated untracked hex64 and geometry-display-smoother files remain untouched. Final camera/proximity cleanup remains pending; a deadline cleanup receipt will record actual result. This is an interim source checkpoint, not closure of the authorized ten-hour work.
